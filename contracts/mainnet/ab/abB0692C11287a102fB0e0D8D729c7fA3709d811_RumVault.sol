// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ICalculator {
    function getAUME30(bool _isMaxPrice) external view returns (uint256);

    function getHLPPrice(uint256 _aum, uint256 _hlpSupply) external pure returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface ICompounder {
    function claimAll(
        address[] memory pools,
        address[][] memory rewarders,
        uint256 startEpochTimestamp,
        uint256 noOfEpochs,
        uint256[] calldata tokenIds
    ) external;

    // _claimAll(pools, rewarders, startEpochTimestamp, noOfEpochs);
    // _claimUniV3(tokenIds);
    // _compoundOrTransfer(false);

    function compound(
        address[] memory pools,
        address[][] memory rewarders,
        uint256 startEpochTimestamp,
        uint256 noOfEpochs,
        uint256[] calldata tokenIds
    ) external;

    // _claimAll(pools, rewarders, startEpochTimestamp, noOfEpochs);
    // _claimUniV3(tokenIds);
    // _compoundOrTransfer(true);

    //     function _compoundOrTransfer(bool isCompound) internal {
    //         uint256 length = tokens.length;
    //         for (uint256 i = 0; i < length; ) {
    //             uint256 amount = IERC20Upgradeable(tokens[i]).balanceOf(address(this));
    //             if (amount > 0) {
    //                 // always compound dragon point
    //                 if (tokens[i] == dp || (isCompound && isCompoundableTokens[tokens[i]])) {
    //                     IERC20Upgradeable(tokens[i]).approve(destinationCompoundPool, type(uint256).max);
    //                     IStaking(destinationCompoundPool).deposit(msg.sender, tokens[i], amount);
    //                     IERC20Upgradeable(tokens[i]).approve(destinationCompoundPool, 0);
    //                 } else {
    //                     IERC20Upgradeable(tokens[i]).safeTransfer(msg.sender, amount);
    //                 }
    //             }
    //
    //             unchecked {
    //                 ++i;
    //             }
    //         }
    //     }
    //
    //     function _claimAll(address[] memory pools, address[][] memory rewarders, uint256 startEpochTimestamp, uint256 noOfEpochs) internal {
    //         uint256 length = pools.length;
    //         for (uint256 i = 0; i < length; ) {
    //             if (tlcStaking == pools[i]) {
    //                 TLCStaking(pools[i]).harvestToCompounder(msg.sender, startEpochTimestamp, noOfEpochs, rewarders[i]);
    //             } else {
    //                 IStaking(pools[i]).harvestToCompounder(msg.sender, rewarders[i]);
    //             }
    //
    //             unchecked {
    //                 ++i;
    //             }
    //         }
    //     }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IHLPStaking {
    function withdraw(uint256 amount) external;

    function deposit(address to, uint256 amount) external;

    function userTokenAmount(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ILiquidityHandler {
    /**
     * Errors
     */
    error ILiquidityHandler_InvalidSender();
    error ILiquidityHandler_InsufficientExecutionFee();
    error ILiquidityHandler_InCorrectValueTransfer();
    error ILiquidityHandler_InsufficientRefund();
    error ILiquidityHandler_NotWhitelisted();
    error ILiquidityHandler_InvalidAddress();
    error ILiquidityHandler_NotExecutionState();
    error ILiquidityHandler_NoOrder();
    error ILiquidityHandler_NotOrderOwner();
    error ILiquidityHandler_NotWNativeToken();
    error ILiquidityHandler_Unauthorized();

    /**
     * Structs
     */
    enum LiquidityOrderStatus {
        PENDING,
        SUCCESS,
        FAIL
    }

    struct LiquidityOrder {
        uint256 orderId;
        uint256 amount;
        uint256 minOut;
        uint256 actualAmountOut;
        uint256 executionFee;
        address payable account;
        uint48 createdTimestamp;
        uint48 executedTimestamp;
        address token;
        bool isAdd;
        bool isNativeOut; // token Out for remove liquidity(!unwrap) and refund addLiquidity (shouldWrap) flag
        LiquidityOrderStatus status;
    }

    /**
     * States
     */
    function nextExecutionOrderIndex() external view returns (uint256);

    /**
     * Functions
     */
    function createAddLiquidityOrder(
        address _tokenBuy,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _executionFee,
        bool _shouldUnwrap,
        bool _isSurge
    ) external payable returns (uint256);

    function createRemoveLiquidityOrder(
        address _tokenSell,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _executionFee,
        bool _shouldUnwrap
    ) external payable returns (uint256);

    function executeOrder(
        uint256 _endIndex,
        address payable _feeReceiver,
        bytes32[] calldata _priceData,
        bytes32[] calldata _publishTimeData,
        uint256 _minPublishTime,
        bytes32 _encodedVaas
    ) external;

    function cancelLiquidityOrder(uint256 _orderIndex) external;

    function getLiquidityOrders() external view returns (LiquidityOrder[] memory);

    function getLiquidityOrderLength() external view returns (uint256);

    function setOrderExecutor(address _executor, bool _isOk) external;

    function executeLiquidity(LiquidityOrder calldata _order) external returns (uint256);

    function getActiveLiquidityOrders(uint256 _limit, uint256 _offset) external view returns (LiquidityOrder[] memory _liquidityOrders);

    function getExecutedLiquidityOrders(
        address _account,
        uint256 _limit,
        uint256 _offset
    ) external view returns (LiquidityOrder[] memory _liquidityOrders);

    event LogCreateAddLiquidityOrder(
        address indexed account,
        uint256 indexed orderId,
        address indexed tokenIn,
        uint256 amountIn,
        uint256 minOut,
        uint256 executionFee,
        uint48 createdTimestamp
    );

    event LogExecuteLiquidityOrder(
        address indexed account,
        uint256 indexed orderId,
        address indexed token,
        uint256 amount,
        uint256 minOut,
        bool isAdd,
        uint256 actualOut
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IHlpRewardHandler {
    // function notifyRewardAmount(uint256 reward) external;

    // function getReward(address account) external;

    function getRumSplit(uint256 _amount) external view returns (uint256, uint256, uint256);

    function claimUSDCRewards(address account) external;

    function getPendingUSDCRewards() external view returns (uint256);

    function setDebtRecordUSDC(address _account) external;

    function compoundRewards() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function unstakeAndLiquidate(uint256 _pid, address user, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IRumVault {
    function getUtilizationRate() external view returns (uint256);

    function burn(uint256 amount) external;

    function getAggregatePosition(address user) external view returns (uint256);

    function handleAndCompoundRewards(address[] calldata pools, address[][] calldata rewarder) external returns (uint256);

    struct PositionInfo {
        uint256 deposit; // total amount of deposit
        uint256 position; // position size
        uint256 buyInPrice; // hlp buy in price
        uint256 leverageAmount;
        uint256 debtAdjustmentValue;
        address liquidator; //address of the liquidator
        address user; // user that created the position
        uint32 positionId;
        uint16 leverageMultiplier; // leverage used
        bool isLiquidated; // true if position was liquidated
        bool isClosed;
    }

    struct DepositRecord {
        address user;
        uint256 depositedAmount;
        uint256 leverageAmount;
        uint256 receivedHLP;
        // uint256 feesPaid;
        uint16 leverageMultiplier;
        bool isOrderCompleted;
        uint256 minOut;
    }

    struct WithdrawRecord {
        uint256 positionID;
        address user;
        bool isOrderCompleted;
        bool isLiquidation;
        uint256 minOut;
        uint256 fullDebtValue;
        uint256 returnedUSDC;
        address liquidator;
    }

    struct FeeConfiguration {
        address feeReceiver;
        uint256 withdrawalFee;
        address waterFeeReceiver;
        uint256 liquidatorsRewardPercentage;
        uint256 fixedFeeSplit;
        uint256 slippageTolerance;
        uint256 hlpFee;
    }

    struct StrategyAddresses {
        address USDC;
        address WETH;
        address hmxCalculator;
        address hlp;
        address hlpLiquidityHandler;
        address hlpStaking; // 0x6eE7520a92a703C4Fda875B45Cccb2c273C65a35
        address hlpCompounder; // 0x8E5D083BA7A46f13afccC27BFB7da372E9dFEF22
        //contract deployed by us:
        address water;
        address MasterChef;
        address hlpRewardHandler;
    }

    struct KeeperInfo {
        address keeper;
        uint256 keeperFee;
    }

    struct DebtToValueRatioInfo {
        uint256 valueInUSDC;
        uint256 debtAndProfitToWater;
    }

    struct DebtAdjustmentValues {
        uint256 debtAdjustment;
        uint256 time;
        uint256 debtValueRatio;
    }

    struct ExtraData {
        uint256 debtAndProfittoWater;
        uint256 toLeverageUser;
        uint256 waterProfit;
        uint256 leverageUserProfit;
        uint256 positionPreviousValue;
        uint256 profits;
        uint256 returnedValue;
        uint256 orderId;
    }

    /** --------------------- Event --------------------- */
    event StrategyContractsChanged(
        address USDC,
        address hmxCalculator,
        address hlpLiquidityHandler,
        address hlpStaking,
        address hlpCompounder,
        address water,
        address MasterChef,
        address WETH,
        address hlp,
        address hlpRewardHandler,
        address keeper
    );
    event DTVLimitSet(uint256 DTVLimit, uint256 DTVSlippage);
    event RequestedOpenPosition(address indexed user, uint256 amount, uint256 time, uint256 orderId);

    event FulfilledOpenPosition(
        address indexed user,
        uint256 depositAmount,
        uint256 hlpAmount,
        uint256 time,
        uint32 positionId,
        uint256 hlpPrice,
        uint256 orderId
    );
    event RequestedClosePosition(address indexed user, uint256 amount, uint256 time, uint256 orderId, uint32 positionId);

    event FulfilledClosePosition(
        address indexed user,
        uint256 amount,
        uint256 time,
        uint256 hlpAmount,
        uint256 profits,
        uint256 hlpPrice,
        uint256 positionId,
        uint256 orderId
    );

    event ProtocolFeeChanged(
        address newFeeReceiver,
        uint256 newWithdrawalFee,
        address newWaterFeeReceiver,
        uint256 liquidatorsRewardPercentage,
        uint256 fixedFeeSplit,
        uint256 keeperFee
    );

    event SetAllowedClosers(address indexed closer, bool allowed);
    event SetAllowedSenders(address indexed sender, bool allowed);
    event SetBurner(address indexed burner, bool allowed);
    event UpdateMaxAndMinLeverage(uint256 maxLeverage, uint256 minLeverage);
    event Liquidated(address indexed user, uint256 indexed positionId, address liquidator, uint256 amount, uint256 reward);
    event USDCHarvested(uint256 amount);
    event OpenPositionCancelled(address indexed user, uint256 amount, uint256 time, uint256 orderId);
    event ClosePositionCancelled(address indexed user, uint256 amount, uint256 time, uint256 orderId, uint256 positionId);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/**
 * @author Chef Photons, Vaultka Team serving high quality drinks; drink responsibly.
 * Responsible for our customers not getting intoxicated
 * @notice provided interface for `Water.sol`
 */
interface IWater {
    function lend(uint256 _amount) external returns (bool);

    function repayDebt(uint256 leverage, uint256 debtValue) external returns (bool);

    function getTotalDebt() external view returns (uint256);

    function updateTotalDebt(uint256 profit) external returns (uint256);

    function totalAssets() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function balanceOfUSDC() external view returns (uint256);

    function increaseTotalUSDC(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SafeERC20Upgradeable, IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ERC20BurnableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IMasterChef } from "./interfaces/IMasterChef.sol";
import { ICalculator } from "./interfaces/HMX/ICalculator.sol";
import { ILiquidityHandler } from "./interfaces/HMX/ILiquidityHandler.sol";
import { IHLPStaking } from "./interfaces/HMX/IHLPStaking.sol";
import { IWater } from "./interfaces/water/IWater.sol";
import { ICompounder } from "./interfaces/HMX/ICompounder.sol";
import { IHlpRewardHandler } from "./interfaces/IHlpRewardHandler.sol";
import { IRumVault } from "./interfaces/IRumVault.sol";

contract RumVault is IRumVault, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, ERC20BurnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUpgradeable for uint256;
    using MathUpgradeable for uint128;

    FeeConfiguration public feeConfiguration;
    StrategyAddresses public strategyAddresses;
    DebtAdjustmentValues public debtAdjustmentValues;

    address[] public allUsers;
    uint256[] public tokenIds;

    uint256 public MCPID;
    uint256 public MAX_BPS;
    uint256 public MAX_LEVERAGE;
    uint256 public MIN_LEVERAGE;
    uint256 public DTVLimit;
    uint256 public DTVSlippage;
    uint256 public timeAdjustment;

    uint256 public DENOMINATOR;
    uint256 public DECIMAL;
    address public keeper;

    mapping(address => PositionInfo[]) public positionInfo;
    mapping(address => bool) public allowedSenders;
    mapping(address => bool) public burner;
    mapping(address => bool) private isUser;
    mapping(uint256 => DepositRecord) public depositRecord;
    mapping(uint256 => WithdrawRecord) public withdrawRecord;
    mapping(address => mapping(uint256 => bool)) public inCloseProcess;
    mapping(address => uint256[]) public openOrderIds;
    mapping(address => uint256[]) public closeOrderIds;
    KeeperInfo public keeperInfo;
    uint256[50] private __gaps;

    modifier InvalidID(uint256 positionId, address user) {
        require(positionId < positionInfo[user].length, "RUM: positionID is not valid");
        _;
    }

    modifier zeroAddress(address addr) {
        require(addr != address(0), "Zero address");
        _;
    }

    modifier onlyBurner() {
        require(burner[msg.sender], "Not allowed to burn");
        _;
    }

    modifier onlyKeeper() {
        require(msg.sender == keeperInfo.keeper, "Not keeper");
        _;
    }
    //only hlpRewardHandler
    modifier onlyhlpRewardHandler() {
        require(msg.sender == strategyAddresses.hlpRewardHandler, "Only hlp reward handler");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        //@todo add require statement
        MAX_BPS = 10_000;
        MAX_LEVERAGE = 10_000;
        MIN_LEVERAGE = 3_000;
        DENOMINATOR = 1_000;
        DECIMAL = 1e18;
        feeConfiguration.fixedFeeSplit = 50;
        feeConfiguration.slippageTolerance = 500;
        debtAdjustmentValues.debtAdjustment = 1e18;
        debtAdjustmentValues.time = block.timestamp;

        __Ownable_init();
        __Pausable_init();
        __ERC20_init("RUM-POD", "RUM-POD");
    }

    /** ----------- Change onlyOwner functions ------------- */

    function setAllowed(address _sender, bool _allowed) public onlyOwner zeroAddress(_sender) {
        allowedSenders[_sender] = _allowed;
        emit SetAllowedSenders(_sender, _allowed);
    }

    function setBurner(address _burner, bool _allowed) public onlyOwner zeroAddress(_burner) {
        burner[_burner] = _allowed;
        emit SetBurner(_burner, _allowed);
    }

    function setMaxAndMinLeverage(uint256 _maxLeverage, uint256 _minLeverage) public onlyOwner {
        require(_maxLeverage >= _minLeverage, "Max leverage must be greater than min leverage");
        MAX_LEVERAGE = _maxLeverage;
        MIN_LEVERAGE = _minLeverage;
        emit UpdateMaxAndMinLeverage(_maxLeverage, _minLeverage);
    }

    function setProtocolFee(
        address _feeReceiver,
        uint256 _withdrawalFee,
        address _waterFeeReceiver,
        uint256 _liquidatorsRewardPercentage,
        uint256 _fixedFeeSplit,
        uint256 _hlpFee,
        uint256 _keeperFee
    ) external onlyOwner {
        feeConfiguration.feeReceiver = _feeReceiver;
        feeConfiguration.withdrawalFee = _withdrawalFee;
        feeConfiguration.waterFeeReceiver = _waterFeeReceiver;
        feeConfiguration.liquidatorsRewardPercentage = _liquidatorsRewardPercentage;
        feeConfiguration.fixedFeeSplit = _fixedFeeSplit;
        feeConfiguration.hlpFee = _hlpFee;
        keeperInfo.keeperFee = _keeperFee;

        emit ProtocolFeeChanged(_feeReceiver, _withdrawalFee, _waterFeeReceiver, _liquidatorsRewardPercentage, _fixedFeeSplit, _keeperFee);
    }

    function setStrategyAddresses(
        address _USDC,
        address _hmxCalculator,
        address _hlpLiquidityHandler,
        address _hlpStaking,
        address _hlpCompounder,
        address _water,
        address _MasterChef,
        address _WETH,
        address _hlp,
        address _hlpRewardHandler,
        address _keeper
    ) external onlyOwner {
        //check for zero address
        strategyAddresses.USDC = _USDC;
        strategyAddresses.hmxCalculator = _hmxCalculator;
        strategyAddresses.hlpLiquidityHandler = _hlpLiquidityHandler;
        strategyAddresses.hlpStaking = _hlpStaking;
        strategyAddresses.hlpCompounder = _hlpCompounder;
        strategyAddresses.water = _water;
        strategyAddresses.MasterChef = _MasterChef;
        strategyAddresses.WETH = _WETH;
        strategyAddresses.hlp = _hlp;
        strategyAddresses.hlpRewardHandler = _hlpRewardHandler;
        keeperInfo.keeper = _keeper;

        emit StrategyContractsChanged(
            _USDC,
            _hmxCalculator,
            _hlpLiquidityHandler,
            _hlpStaking,
            _hlpCompounder,
            _water,
            _MasterChef,
            _WETH,
            _hlp,
            _hlpRewardHandler,
            _keeper
        );
    }

    function setDTVLimit(uint256 _DTVLimit, uint256 _DTVSlippage) public onlyOwner {
        require(_DTVSlippage <= 1000, "DTVSlippage must be less than 1000");
        DTVLimit = _DTVLimit;
        DTVSlippage = _DTVSlippage;
        emit DTVLimitSet(_DTVLimit, DTVSlippage);
    }

    //params Ratio: incrase % for each call of updateDebtAdjustment
    //timeAdjustment:
    function setDebtAdjustmentParams(uint256 _debtValueRatio, uint256 _timeAdjustment) external onlyOwner {
        require(_debtValueRatio <= 1e18, "Debt value ratio must be less than 1");
        debtAdjustmentValues.debtValueRatio = _debtValueRatio;
        timeAdjustment = _timeAdjustment;
    }

    function updateDebtAdjustment() external onlyOwner {
        // require(getUtilizationRate() > (DTVLimit), "Utilization rate is not greater than DTVLimit");
        // require(block.timestamp - debtAdjustmentValues.time > timeAdjustment, "Time difference is not greater than 72 hours");

        debtAdjustmentValues.debtAdjustment =
            debtAdjustmentValues.debtAdjustment +
            (debtAdjustmentValues.debtAdjustment * debtAdjustmentValues.debtValueRatio) /
            1e18;
        debtAdjustmentValues.time = block.timestamp;
    }

    //     function pause() external onlyOwner {
    //         _pause();
    //     }
    //
    //     function unpause() external onlyOwner {
    //         _unpause();
    //     }

    //@todo handle esToken
    //
    //     function transferEsGMX(address _destination) public onlyOwner {
    //         IRewardRouterV2(strategyAddresses.rewardVault).signalTransfer(_destination);
    //     }
    /** ----------- View functions ------------- */

    function getCurrentLeverageAmount(uint256 _positionID, address _user) public view returns (uint256) {
        PositionInfo memory _positionInfo = positionInfo[_user][_positionID];
        uint256 previousDA = _positionInfo.debtAdjustmentValue;
        uint256 userLeverageAmount = _positionInfo.leverageAmount;
        if (debtAdjustmentValues.debtAdjustment > previousDA) {
            userLeverageAmount = userLeverageAmount.mulDiv(debtAdjustmentValues.debtAdjustment, previousDA);
        }
        return (userLeverageAmount);
    }

    function getHLPPrice(bool _maximise) public view returns (uint256) {
        uint256 aum = ICalculator(strategyAddresses.hmxCalculator).getAUME30(_maximise);
        uint256 totalSupply = IERC20Upgradeable(strategyAddresses.hlp).totalSupply();

        return ICalculator(strategyAddresses.hmxCalculator).getHLPPrice(aum, totalSupply);
        //HLP Price in e12
    }

    //get this contract balance of hlp token(1e18)
    function getStakedHLPBalance() public view returns (uint256) {
        return IHLPStaking(strategyAddresses.hlpStaking).userTokenAmount(address(this));
    }

    function getAllUsers() external view returns (address[] memory) {
        return allUsers;
    }

    function getNumbersOfPosition(address _user) external view returns (uint256) {
        return positionInfo[_user].length;
    }

    function getUtilizationRate() external view returns (uint256) {
        uint256 totalWaterDebt = IWater(strategyAddresses.water).totalDebt();
        uint256 totalWaterAssets = IWater(strategyAddresses.water).balanceOfUSDC();
        return totalWaterDebt == 0 ? 0 : totalWaterDebt.mulDiv(DECIMAL, totalWaterAssets + totalWaterDebt);
    }

    function getAggregatePosition(address _user) external view returns (uint256) {
        uint256 aggregatePosition;
        for (uint256 i = 0; i < positionInfo[_user].length; i++) {
            PositionInfo memory _userInfo = positionInfo[_user][i];
            if (!_userInfo.isLiquidated && !_userInfo.isClosed) {
                aggregatePosition += positionInfo[_user][i].position;
            }
        }
        return aggregatePosition;
    }

    function getPosition(uint256 _positionID, address _user) public view returns (uint256, uint256, uint256, uint256, uint256) {
        PositionInfo memory _positionInfo = positionInfo[_user][_positionID];
        if (_positionInfo.isClosed || _positionInfo.isLiquidated) return (0, 0, 0, 0, 0);

        uint256 currentPositionValue = _convertHLPToUSDC(_positionInfo.position, getHLPPrice(true));

        uint256 OriginalLeverageAmount = _positionInfo.leverageAmount;

        uint256 currentDTV = OriginalLeverageAmount.mulDiv(DECIMAL, currentPositionValue);

        uint256 leveageAmountWithDA = getCurrentLeverageAmount(_positionID, _user);

        uint256 currentDTVWithDA = leveageAmountWithDA.mulDiv(DECIMAL, currentPositionValue);

        return (currentDTV, OriginalLeverageAmount, currentPositionValue, currentDTVWithDA, leveageAmountWithDA);
    }

    /** ----------- User functions ------------- */
    //@todo add logic to handle rewards from HMX
    function handleAndCompoundRewards(
        address[] calldata pools,
        address[][] calldata rewarder
    ) external onlyhlpRewardHandler returns (uint256 amount) {
        uint256 balanceBefore = IERC20Upgradeable(strategyAddresses.USDC).balanceOf(address(this));

        ICompounder(strategyAddresses.hlpCompounder).compound(pools, rewarder, 0, 0, tokenIds);

        uint256 balanceAfter = IERC20Upgradeable(strategyAddresses.USDC).balanceOf(address(this));

        uint256 usdcRewards = balanceAfter - balanceBefore;

        IERC20Upgradeable(strategyAddresses.USDC).transfer(strategyAddresses.hlpRewardHandler, usdcRewards);

        emit USDCHarvested(usdcRewards);

        return (usdcRewards);
    }

    function requestOpenPosition(uint256 _amount, uint16 _leverage) external payable whenNotPaused returns (uint256) {
        require(_leverage >= MIN_LEVERAGE && _leverage <= MAX_LEVERAGE, "RUM: Invalid leverage");
        require(_amount > 0, "RUM: amount must be greater than zero");
        require(msg.value >= keeperInfo.keeperFee + feeConfiguration.hlpFee, "RUM: fee not enough");

        IERC20Upgradeable(strategyAddresses.USDC).safeTransferFrom(msg.sender, address(this), _amount);
        // get leverage amount
        uint256 leveragedAmount = _amount.mulDiv(_leverage, DENOMINATOR) - _amount;
        bool status = IWater(strategyAddresses.water).lend(leveragedAmount);
        require(status, "Water: Lend failed");
        // add leverage amount to amount
        uint256 totalPositionValue = _amount + leveragedAmount;

        IERC20Upgradeable(strategyAddresses.USDC).safeIncreaseAllowance(strategyAddresses.hlpLiquidityHandler, totalPositionValue);

        //minOut is totalPositionValue * hlpPrice * sliipage
        uint256 minOut = ((totalPositionValue * 1e24) / getHLPPrice(true)).mulDiv((MAX_BPS - feeConfiguration.slippageTolerance), MAX_BPS);

        uint256 orderId = ILiquidityHandler(strategyAddresses.hlpLiquidityHandler).createAddLiquidityOrder{
            value: feeConfiguration.hlpFee
        }(
            strategyAddresses.USDC,
            totalPositionValue,
            minOut, //minOut
            msg.value,
            false,
            false
        );

        DepositRecord storage dr = depositRecord[orderId];
        dr.leverageAmount = leveragedAmount;
        dr.depositedAmount = _amount;
        // dr.feesPaid = msg.value;
        dr.minOut = minOut;
        dr.user = msg.sender;
        dr.leverageMultiplier = _leverage;
        openOrderIds[msg.sender].push(orderId);

        payable(keeperInfo.keeper).transfer(keeperInfo.keeperFee);

        emit RequestedOpenPosition(msg.sender, _amount, block.timestamp, orderId);

        return (orderId);
        //emit an event called
    }

    //@dev backend listen to the event of LogRefund and call this function
    function fulfillOpenCancellation(uint256 orderId) public onlyKeeper returns (bool) {
        DepositRecord storage dr = depositRecord[orderId];
        //refund the amount to user
        IERC20Upgradeable(strategyAddresses.USDC).safeTransfer(dr.user, dr.depositedAmount);
        //refund the leverage to water
        IERC20Upgradeable(strategyAddresses.USDC).safeIncreaseAllowance(strategyAddresses.water, dr.leverageAmount);
        IWater(strategyAddresses.water).repayDebt(dr.leverageAmount, dr.leverageAmount);
        //refund the fee to user
        dr.isOrderCompleted = true;
        //@add an item in the DepositRecord to show that the event is cancelled.
        emit OpenPositionCancelled(dr.user, dr.depositedAmount, block.timestamp, orderId);

        return true;
    }

    //@dev backend listen to the event of LogExecuteLiquidityOrder and call this function
    function fulfillOpenPosition(uint256 orderId, uint256 _actualOut) public onlyKeeper returns (bool) {
        //require that orderId doesnt not exist
        DepositRecord storage dr = depositRecord[orderId];
        require(dr.isOrderCompleted == false, "RUM: order already fulfilled");

        uint256 expectedOut = _convertUSDCToHLP(dr.depositedAmount + dr.leverageAmount, getHLPPrice(true));

        require(
            isWithinSlippage(_actualOut, expectedOut, feeConfiguration.slippageTolerance),
            "RUM:  _actualOut not within slippage tolerance"
        );

        dr.receivedHLP = _actualOut;
        address user = dr.user;

        IHlpRewardHandler(strategyAddresses.hlpRewardHandler).claimUSDCRewards(user);

        PositionInfo memory _positionInfo = PositionInfo({
            deposit: dr.depositedAmount,
            position: dr.receivedHLP,
            buyInPrice: getHLPPrice(true),
            leverageAmount: dr.leverageAmount,
            liquidator: address(0),
            user: dr.user,
            positionId: uint32(positionInfo[user].length),
            leverageMultiplier: dr.leverageMultiplier,
            isLiquidated: false,
            isClosed: false,
            debtAdjustmentValue: debtAdjustmentValues.debtAdjustment
        });
        //frontend helper to fetch all users and then their userInfo
        if (isUser[user] == false) {
            isUser[user] = true;
            allUsers.push(user);
        }
        positionInfo[user].push(_positionInfo);
        // mint gmx shares to user
        _mint(user, dr.receivedHLP);

        dr.isOrderCompleted = true;

        IHlpRewardHandler(strategyAddresses.hlpRewardHandler).setDebtRecordUSDC(dr.user);

        emit FulfilledOpenPosition(
            user,
            _positionInfo.deposit,
            dr.receivedHLP,
            block.timestamp,
            _positionInfo.positionId,
            getHLPPrice(true),
            orderId
        );

        return true;
    }

    function requestClosePosition(uint32 _positionID) external payable InvalidID(_positionID, msg.sender) nonReentrant {
        PositionInfo storage _positionInfo = positionInfo[msg.sender][_positionID];
        require(!_positionInfo.isLiquidated, "RUM: position is liquidated");
        require(msg.sender == _positionInfo.user, "RUM: not allowed to close position");
        require(!inCloseProcess[msg.sender][_positionID], "RUM: close position request already ongoing");
        require(msg.value >= keeperInfo.keeperFee + feeConfiguration.hlpFee, "RUM: fee not enough");

        (, , , uint256 currentDTVWithDA, ) = getPosition(_positionID, msg.sender);

        if (currentDTVWithDA >= (DTVLimit * DTVSlippage) / 1000) {
            revert("Wait for liquidation");
        }

        // _positionInfo.leverageAmount = LeverageAmountWihtDA;
        //unstake, approve, create withdraw order
        uint256 withdrawAsssetAmount;
        uint256 orderId;

        withdrawAsssetAmount = _positionInfo.position;

        IHLPStaking(strategyAddresses.hlpStaking).withdraw(_positionInfo.position);

        IERC20Upgradeable(strategyAddresses.hlp).safeIncreaseAllowance(strategyAddresses.hlpLiquidityHandler, _positionInfo.position);

        uint256 minOut = (withdrawAsssetAmount * getHLPPrice(true)).mulDiv((MAX_BPS - feeConfiguration.slippageTolerance), MAX_BPS) / 1e24;

        orderId = ILiquidityHandler(strategyAddresses.hlpLiquidityHandler).createRemoveLiquidityOrder{ value: feeConfiguration.hlpFee }(
            strategyAddresses.USDC,
            withdrawAsssetAmount,
            minOut, //minOut
            msg.value,
            false
        );

        WithdrawRecord storage wr = withdrawRecord[orderId];

        wr.user = msg.sender;
        wr.positionID = _positionID;
        wr.minOut = minOut;
        inCloseProcess[msg.sender][_positionID] = true;
        closeOrderIds[msg.sender].push(orderId);
        payable(keeperInfo.keeper).transfer(keeperInfo.keeperFee);

        emit RequestedClosePosition(msg.sender, withdrawAsssetAmount, block.timestamp, orderId, _positionID);
    }

    function fulfillCloseCancellation(uint256 orderId) public onlyKeeper returns (bool) {
        WithdrawRecord storage wr = withdrawRecord[orderId];
        PositionInfo storage _positionInfo = positionInfo[wr.user][wr.positionID];

        uint256 reDepositAmount = _positionInfo.position;
        //redeposit the position to hlp staking
        IERC20Upgradeable(strategyAddresses.hlp).approve(strategyAddresses.hlpStaking, reDepositAmount);
        IHLPStaking(strategyAddresses.hlpStaking).deposit(address(this), reDepositAmount);

        inCloseProcess[wr.user][wr.positionID] = false;
        wr.isOrderCompleted = true;

        emit ClosePositionCancelled(wr.user, _positionInfo.position, block.timestamp, orderId, wr.positionID);

        return true;
        //@add an item in the WithdrawtRecord to show that the event is cancelled.
    }

    function fulfillClosePosition(uint256 _orderId, uint256 _returnedUSDC) public onlyKeeper returns (bool) {
        WithdrawRecord storage wr = withdrawRecord[_orderId];
        PositionInfo storage _positionInfo = positionInfo[wr.user][wr.positionID];

        require(
            isWithinSlippage(
                _returnedUSDC,
                _convertHLPToUSDC(_positionInfo.position, getHLPPrice(false)),
                feeConfiguration.slippageTolerance
            ),
            "RUM: returnedUSDC not within slippage tolerance"
        );

        ExtraData memory extraData;
        require(inCloseProcess[wr.user][wr.positionID], "Rum: close position request not ongoing");

        IHlpRewardHandler(strategyAddresses.hlpRewardHandler).claimUSDCRewards(wr.user);

        _burn(wr.user, _positionInfo.position);

        (, , , , uint256 leverageAmountWihtDA) = getPosition(wr.positionID, wr.user);

        wr.fullDebtValue = leverageAmountWihtDA;
        wr.returnedUSDC = _returnedUSDC;

        extraData.positionPreviousValue = _convertHLPToUSDC(_positionInfo.position, _positionInfo.buyInPrice);
        extraData.returnedValue = _returnedUSDC;
        extraData.orderId = _orderId;

        if (_returnedUSDC > extraData.positionPreviousValue) {
            extraData.profits = _returnedUSDC - extraData.positionPreviousValue;
        }

        uint256 waterRepayment;
        (uint256 waterProfits, uint256 leverageUserProfits) = _getProfitSplit(extraData.profits, _positionInfo.leverageMultiplier);

        if (extraData.returnedValue < (wr.fullDebtValue + waterProfits)) {
            _positionInfo.liquidator = msg.sender;
            _positionInfo.isLiquidated = true;
            waterRepayment = extraData.returnedValue;
        } else {
            extraData.toLeverageUser = (extraData.returnedValue - wr.fullDebtValue - extraData.profits) + leverageUserProfits;
            waterRepayment = extraData.returnedValue - extraData.toLeverageUser - waterProfits;

            _positionInfo.isClosed = true;
            _positionInfo.position = 0;
            _positionInfo.leverageAmount = 0;
        }

        if (waterProfits > 0) {
            IERC20Upgradeable(strategyAddresses.USDC).safeTransfer(feeConfiguration.waterFeeReceiver, waterProfits);
        }

        IERC20Upgradeable(strategyAddresses.USDC).safeIncreaseAllowance(strategyAddresses.water, wr.fullDebtValue);
        IWater(strategyAddresses.water).repayDebt(wr.fullDebtValue, waterRepayment);

        if (_positionInfo.isLiquidated) {
            return (false);
        }

        uint256 amountAfterFee;
        if (feeConfiguration.withdrawalFee > 0) {
            uint256 fee = extraData.toLeverageUser.mulDiv(feeConfiguration.withdrawalFee, MAX_BPS);
            IERC20Upgradeable(strategyAddresses.USDC).safeTransfer(feeConfiguration.feeReceiver, fee);
            amountAfterFee = extraData.toLeverageUser - fee;
        } else {
            amountAfterFee = extraData.toLeverageUser;
        }

        IERC20Upgradeable(strategyAddresses.USDC).safeTransfer(wr.user, amountAfterFee);

        IHlpRewardHandler(strategyAddresses.hlpRewardHandler).setDebtRecordUSDC(wr.user);

        emit FulfilledClosePosition(
            wr.user,
            extraData.toLeverageUser,
            block.timestamp,
            _positionInfo.position,
            leverageUserProfits,
            getHLPPrice(true),
            wr.positionID,
            extraData.orderId
        );

        return true;
    }

    function requestLiquidatePosition(address _user, uint256 _positionID) external payable nonReentrant {
        PositionInfo storage _positionInfo = positionInfo[_user][_positionID];

        //update leverage Amount with DA
        require(!_positionInfo.isLiquidated, "RUM: Already liquidated");
        require(_positionInfo.user != address(0), "RUM: liquidation request does not exist");
        require(!inCloseProcess[_user][_positionID], "RUM: close position request already ongoing");
        require(msg.value >= keeperInfo.keeperFee + feeConfiguration.hlpFee, "RUM: fee not enough");

        (, , , uint256 currentDTVWithDA, ) = getPosition(_positionID, _user);

        require(currentDTVWithDA >= (DTVLimit * DTVSlippage) / 1000, "Liquidation threshold not reached yet");

        // _positionInfo.leverageAmount = LeverageAmountWihtDA;

        IHLPStaking(strategyAddresses.hlpStaking).withdraw(_positionInfo.position);
        IERC20Upgradeable(strategyAddresses.hlp).approve(strategyAddresses.hlpLiquidityHandler, _positionInfo.position);

        uint256 minOut = (_positionInfo.position * getHLPPrice(true)).mulDiv((MAX_BPS - feeConfiguration.slippageTolerance), MAX_BPS) /
            1e24;
        uint256 orderId = ILiquidityHandler(strategyAddresses.hlpLiquidityHandler).createRemoveLiquidityOrder{
            value: feeConfiguration.hlpFee
        }(
            strategyAddresses.USDC,
            _positionInfo.position,
            minOut, //minOut
            msg.value,
            false
        );

        WithdrawRecord storage wr = withdrawRecord[orderId];

        inCloseProcess[_user][_positionID] = true;
        wr.user = _user;
        wr.positionID = _positionID;
        wr.isLiquidation = true;
        wr.liquidator = msg.sender;

        payable(keeperInfo.keeper).transfer(keeperInfo.keeperFee);
    }

    function fulfillLiquidation(uint256 _orderId, uint256 _returnedUSDC) external nonReentrant onlyKeeper {
        WithdrawRecord storage wr = withdrawRecord[_orderId];
        PositionInfo storage _positionInfo = positionInfo[wr.user][wr.positionID];
        require(!_positionInfo.isLiquidated, "RUM: Already liquidated");

        // (uint256 DebtToValueRatio, , , ) = getPosition(wr.positionID, wr.user);
        // require(DebtToValueRatio >= (DTVLimit * DTVSlippage) / 1000, "Liquidation Threshold Has Not Reached");

        IHlpRewardHandler(strategyAddresses.hlpRewardHandler).claimUSDCRewards(wr.user);

        (, , , , uint256 leverageAmountWihtDA) = getPosition(wr.positionID, wr.user);

        uint256 position = _positionInfo.position;
        wr.returnedUSDC = _returnedUSDC;

        uint256 userAmountStaked;
        if (strategyAddresses.MasterChef != address(0)) {
            (userAmountStaked, ) = IMasterChef(strategyAddresses.MasterChef).userInfo(MCPID, wr.user);
            if (userAmountStaked > 0) {
                uint256 amountToBurnFromUser;
                if (userAmountStaked > position) {
                    amountToBurnFromUser = position;
                } else {
                    amountToBurnFromUser = userAmountStaked;
                    uint256 _position = position - userAmountStaked;
                    _burn(wr.user, _position);
                }
                IMasterChef(strategyAddresses.MasterChef).unstakeAndLiquidate(MCPID, wr.user, amountToBurnFromUser);
            }
        } else {
            _burn(wr.user, position);
        }

        uint256 liquidatorReward;
        if (wr.returnedUSDC >= leverageAmountWihtDA) {
            wr.returnedUSDC -= leverageAmountWihtDA;

            liquidatorReward = wr.returnedUSDC.mulDiv(feeConfiguration.liquidatorsRewardPercentage, MAX_BPS);
            IERC20Upgradeable(strategyAddresses.USDC).safeTransfer(wr.liquidator, liquidatorReward);

            uint256 leftovers = wr.returnedUSDC - liquidatorReward;

            IERC20Upgradeable(strategyAddresses.USDC).safeIncreaseAllowance(strategyAddresses.water, leftovers + leverageAmountWihtDA);
            IWater(strategyAddresses.water).repayDebt(leverageAmountWihtDA, leftovers + leverageAmountWihtDA);
        } else {
            IERC20Upgradeable(strategyAddresses.USDC).safeIncreaseAllowance(strategyAddresses.water, wr.returnedUSDC);
            IWater(strategyAddresses.water).repayDebt(leverageAmountWihtDA, wr.returnedUSDC);
        }

        uint256 outputAmount = 0;

        _positionInfo.liquidator = msg.sender;
        _positionInfo.isLiquidated = true;
        _positionInfo.position = 0;

        IHlpRewardHandler(strategyAddresses.hlpRewardHandler).setDebtRecordUSDC(wr.user);

        emit Liquidated(wr.user, wr.positionID, msg.sender, outputAmount, liquidatorReward);
    }

    /** ----------- Token functions ------------- */

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        address spender = _msgSender();
        require(allowedSenders[from] || allowedSenders[to] || allowedSenders[spender], "ERC20: transfer not allowed");
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address ownerOf = _msgSender();
        require(allowedSenders[ownerOf] || allowedSenders[to], "ERC20: transfer not allowed");
        _transfer(ownerOf, to, amount);
        return true;
    }

    function burn(uint256 amount) public override(ERC20BurnableUpgradeable, IRumVault) onlyBurner {
        _burn(_msgSender(), amount);
    }

    /** ----------- Internal functions ------------- */
    function _getProfitSplit(uint256 _profit, uint256 _leverage) internal view returns (uint256, uint256) {
        if (_profit == 0) {
            return (0, 0);
        }
        uint256 split = (feeConfiguration.fixedFeeSplit * _leverage + (feeConfiguration.fixedFeeSplit * MAX_BPS)) / 100;
        uint256 toWater = (_profit * split) / MAX_BPS;
        uint256 toRumUser = _profit - toWater;
        return (toWater, toRumUser);
    }

    function _convertHLPToUSDC(uint256 _amount, uint256 _hlpPrice) internal pure returns (uint256) {
        return _amount.mulDiv(_hlpPrice, 10 ** 24);
    }

    function _convertUSDCToHLP(uint256 _amount, uint256 _hlpPrice) internal pure returns (uint256) {
        return _amount.mulDiv(10 ** 24, _hlpPrice);
    }

    function takeAll(address _inputSsset, uint256 _amount) public onlyOwner {
        IERC20Upgradeable(_inputSsset).transfer(msg.sender, _amount);
    }

    //
    //function for owner to transfer all eth in the contract out
    function takeAllETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    //deposit HLP token
    // function depositHLP() external onlyOwner {
    //     //check contract hlp balance
    //     uint256 balanceOfHLP = IERC20Upgradeable(strategyAddresses.hlp).balanceOf(address(this));
    //     //approve hlp staking contract
    //     IERC20Upgradeable(strategyAddresses.hlp).approve(strategyAddresses.hlpStaking, balanceOfHLP);
    //     IHLPStaking(strategyAddresses.hlpStaking).deposit(address(this), balanceOfHLP);
    // }

    function isWithinSlippage(uint256 _a, uint256 _b, uint256 _slippageBps) public view returns (bool) {
        uint256 _slippage = (_a * _slippageBps) / MAX_BPS;
        if (_a > _b) {
            return (_a - _b) <= _slippage;
        } else {
            return (_b - _a) <= _slippage;
        }
    }

    //add a function to set keeper
    function setKeeperInfo(address _keeper, uint256 _keeperFee) external onlyOwner {
        keeperInfo.keeper = _keeper;
        keeper = _keeper;
        keeperInfo.keeperFee = _keeperFee;
    }

    //approve USDC to water
    function approveUSDC() external onlyOwner {
        IERC20Upgradeable(strategyAddresses.USDC).approve(strategyAddresses.water, type(uint256).max);
    }

    receive() external payable {}
}