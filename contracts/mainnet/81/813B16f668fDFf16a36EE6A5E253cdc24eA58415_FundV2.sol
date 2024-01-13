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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

pragma solidity ^0.8.0;
// SPDX-License-Identifier: GPL-3.0-or-later

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Interface/ILockedStake.sol";
import "./Library/xWinLib.sol";
import "./Interface/IxWinPriceMaster.sol";
import "./Interface/IxWinSwap.sol";
import "./xWinStrategy.sol";
import "./Interface/IWETH.sol";

contract FundV2 is xWinStrategy {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct userAvgPrice {
        uint256 shares;
        uint256 avgPrice;
    }

    mapping(address => bool) public validInvestors; // stores authourised addresses that can use the private fund
    mapping(address => userAvgPrice) public performanceMap; // mapping to store performance fee
    mapping (address => bool) public waivedPerformanceFees; // stores authourised addresses with fee waived
    mapping(address => uint256) public TargetWeight; // stores the weight of the target asset
    address[] public targetAddr; // list of target assets
    IxWinPriceMaster public priceMaster; // contract address of price Oracle
    IxWinSwap public xWinSwap; // contract address for swapping tokens
    address public lockingAddress;
    address public managerAddr;
    address public managerRebAddr;
    address public platformWallet;

    uint256 public lastFeeCollection;
    uint256 public nextRebalance;
    uint256 public pendingMFee;
    uint256 public pendingPFee;
    uint256 private baseTokenAmt;
    uint256 public managerFee;
    uint256 public platformFee;
    uint256 public smallRatio;
    uint256 private rebalanceCycle;
    uint256 public performFee;
    uint256 private blocksPerDay;
    uint256 public UPMultiplier;    
    bool public openForPublic;

    
    event Received(address, uint256);
    event ManagerFeeUpdate(uint256 fromFee, uint256 toFee, uint256 txnTime);
    event ManagerOwnerUpdate(address fromAddress, address toAddress, uint256 txnTime);

    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _baseToken,
        address _USDAddr,
        address _manageraddr,
        address _managerRebaddr,
        address _platformWallet,
        address _lockedStaking
    ) initializer external {
        require(_baseToken != address(0) , "_baseToken Input 0");
        require(_USDAddr != address(0), "_USDAddr Input 0");
        require(_manageraddr != address(0), "_manageraddr Input 0");
        require(_managerRebaddr != address(0), "_managerRebaddr Input 0");
        require(_platformWallet != address(0), "_platformWallet Input 0");
        // require(_lockedStaking != address(0), "_lockedStaking Input 0");
        
        __xWinStrategy_init(_name, _symbol, _baseToken, _USDAddr);
        managerAddr = _manageraddr;
        managerRebAddr = _managerRebaddr;
        platformWallet = _platformWallet;
        lockingAddress = _lockedStaking;
        _pause();
    }
    
    function init(
        uint256 _managerFee, 
        uint256 _performFee,
        uint256 _platformFee,
        bool _openForPublic,
        uint256 _UPMultiplier,
        uint256 _rebalancePeriod,
        uint256 _blocksPerDay,
        uint256 _smallRatio
    ) external onlyOwner whenPaused {
        require(_managerFee <= 300, "Manager Fee cap at 3%");
        require(_performFee <= 2000, "Performance Fee cap at 20%");
        require(_platformFee <= 100, "Platform Fee cap at 1%");

        _calcFundFee();
        openForPublic = _openForPublic;
        managerFee = _managerFee;   
        UPMultiplier = _UPMultiplier;
        performFee = _performFee;
        platformFee = _platformFee;
        nextRebalance = block.number + _rebalancePeriod;
        lastFeeCollection = block.number;
        rebalanceCycle = _rebalancePeriod;
        blocksPerDay = _blocksPerDay;
        smallRatio = _smallRatio;
        _unpause();
    }
    
    function collectFundFee() external {
        _calcFundFee();
        uint256 toAward = pendingMFee;
        pendingMFee = 0;
        _mint(managerAddr, toAward);
        emitEvent.FeeEvent("managefee", address(this), toAward);
    }

    function collectPlatformFee() external {
        _calcFundFee();
        uint256 toAward = pendingPFee;
        pendingPFee = 0;
        _mint(platformWallet, toAward);
        emitEvent.FeeEvent("platformfee", address(this), toAward);
    }

    function _calcFundFee() internal {
        uint256 totalblock = block.number - lastFeeCollection;
        lastFeeCollection = block.number;
        uint256 supply = getFundTotalSupply();

        if(supply == 0) return;

        // calculate number of shares to create per block
        uint256 uPerBlock = supply * 10000 / (10000 - managerFee);
        uPerBlock = uPerBlock - supply; // total new blocks generated in a year

        // calculate number of shares to create per block for platform
        uint256 uPerBlockPlatform = supply * 10000 / (10000 - platformFee);
        uPerBlockPlatform = uPerBlockPlatform - supply; // total new blocks generated in a year

        // award the shares
        pendingMFee += (totalblock * uPerBlock) / (blocksPerDay * 365);
        pendingPFee += (totalblock * uPerBlockPlatform) / (blocksPerDay * 365);
    }
 
    /// @dev return number of target names
    function createTargetNames(address[] calldata _toAddr,  uint256[] calldata _targets) public onlyRebManager {
        require(_toAddr.length > 0, "At least one target is required");
        require(_toAddr.length == _targets.length, "in array lengths mismatch");
        require(!findDup(_toAddr), "Duplicate found in targetArray");
        uint256 sum = sumArray(_targets);
        require(sum == 10000, "xWinFundV2: Sum must equal 100%");
        if (targetAddr.length > 0) {
            for (uint256 i = 0; i < targetAddr.length; i++) {
                TargetWeight[targetAddr[i]] = 0;
            }
            delete targetAddr;
        }
        
        for (uint256 i = 0; i < _toAddr.length; i++) {
            _getLatestPrice(_toAddr[i]); // ensures that the address provided is supported
            TargetWeight[_toAddr[i]] = _targets[i];
            targetAddr.push(_toAddr[i]);
        }
    }
    
    /// @dev perform rebalance with new weight and reset next rebalance period
    function Rebalance(
        address[] calldata _toAddr, 
        uint256[] calldata _targets,
        uint32 _slippage
    ) public onlyRebManager {
        
        xWinLib.DeletedNames[] memory deletedNames = _getDeleteNames(_toAddr);
        for (uint256 x = 0; x < deletedNames.length; x++){
            if(deletedNames[x].token != address(0)){
                  _moveNonIndex(deletedNames[x].token, _slippage);
            }
            if (deletedNames[x].token == baseToken) {
                baseTokenAmt = 0;
            }
        }
        createTargetNames(_toAddr, _targets);        
        _rebalance(_slippage);
    }

    function Rebalance(
        address[] calldata _toAddr, 
        uint256[] calldata _targets
    ) external onlyRebManager {
        Rebalance(_toAddr, _targets, 0);
    }
    
    /// @dev perform subscription based on ratio setup
    function deposit(uint256 amount, uint32 _slippage) public override nonReentrant whenNotPaused returns (uint256) {
        return _deposit(amount, _slippage);
    }

    function deposit(uint256 amount) external override nonReentrant whenNotPaused returns (uint256) {
        return _deposit(amount, 0);
    }

    function _deposit(uint256 amount, uint32 _slippage) internal returns (uint256) {

        require(targetAddr.length > 0, "xWinFundV2: This fund is empty");
        
        if(!openForPublic){
            require(validInvestors[msg.sender], "not valid wallet to deposit");
        }
        // manager fee calculation
        _calcFundFee();
        uint256 unitPrice = _getUnitPrice();
        
        // collect deposit and swap into asset
        IERC20Upgradeable(baseToken).safeTransferFrom(msg.sender, address(this), amount);


        if(nextRebalance < block.number){
            _rebalance(_slippage);
        }else{            
            uint256 total = getBalance(baseToken);
            total -= baseTokenAmt; // subtract baseTokenAmt
            for (uint256 i = 0; i < targetAddr.length; i++) {
                uint256 proposalQty = getTargetWeightQty(targetAddr[i], total);
                if(proposalQty > 0){
                    IERC20Upgradeable(baseToken).safeIncreaseAllowance(address(xWinSwap), proposalQty);
                    xWinSwap.swapTokenToToken(proposalQty, baseToken, targetAddr[i], _slippage);
                }
                if (targetAddr[i] == baseToken) {
                    baseTokenAmt += proposalQty;
                }
            }
        }

        // mint and log user data
        uint256 mintQty = _getMintQty(unitPrice);
        _mint(msg.sender, mintQty);
        setPerformDeposit(mintQty, unitPrice);

        emitEvent.FundEvent("deposit", address(this), msg.sender, _convertTo18(unitPrice, baseToken), amount, mintQty);
        return mintQty;
    }
    
    /// @dev perform redemption based on unit redeem
    function withdraw(uint256 amount, uint32 _slippage) public override nonReentrant whenNotPaused returns (uint256){
        return _withdraw(amount, _slippage);
    }

    function withdraw(uint256 amount) external override nonReentrant whenNotPaused returns (uint256){
        return _withdraw(amount, 0);
    }

    function _withdraw(uint256 amount, uint32 _slippage) internal returns (uint256){

        require(IERC20Upgradeable(address(this)).balanceOf(msg.sender) >= amount, "no balance to withdraw");

        _calcFundFee();
        uint256 unitP = _getUnitPrice();
        uint256 redeemratio = amount * 1e18 / getFundTotalSupply();
        _burn(msg.sender, amount);
        
	    uint256 totalBase = getBalance(baseToken) - baseTokenAmt;
        uint256 entitled = redeemratio * totalBase / 1e18;
        uint256 remained = totalBase - entitled;
        
        for (uint256 i = 0; i < targetAddr.length; i++) {
            xWinLib.transferData memory _transferData = _getTransferAmt(targetAddr[i], redeemratio);
            if(_transferData.totalTrfAmt > 0) {
                IERC20Upgradeable(targetAddr[i]).safeIncreaseAllowance(address(xWinSwap), _transferData.totalTrfAmt);
                xWinSwap.swapTokenToToken(_transferData.totalTrfAmt, targetAddr[i], baseToken, _slippage);
            }
            if (targetAddr[i] == baseToken) {
                baseTokenAmt -= _transferData.totalTrfAmt;
            }
        }

        uint256 totalOutput = getBalance(baseToken) - baseTokenAmt - remained;
        uint256 finalOutput = setPerformWithdraw(totalOutput, amount, msg.sender, managerAddr);
        IERC20Upgradeable(baseToken).safeTransfer(msg.sender, finalOutput);
        emitEvent.FundEvent("withdraw", address(this), msg.sender, _convertTo18(unitP, baseToken), finalOutput, amount);

        return finalOutput;
    }

    
    /// @dev fund owner move any name back to BNB
    function MoveNonIndexNameToBase(address _token, uint32 _slippage) external onlyOwner 
        returns (uint256 balanceToken, uint256 swapOutput) {
            
            (balanceToken, swapOutput) = _moveNonIndex(_token, _slippage);
            return (balanceToken, swapOutput);
    }
        
        
    /// @dev get the proportional token without swapping it in emergency case
    function emergencyRedeem(uint256 redeemUnit) external whenPaused {
        uint256 redeemratio = redeemUnit * 1e18 / getFundTotalSupply();
        require(redeemratio > 0, "redeem ratio is zero");
        _burn(msg.sender, redeemUnit);
        uint256 totalOutput = redeemratio * (getBalance(baseToken) - baseTokenAmt) / 1e18;
        IERC20Upgradeable(baseToken).safeTransfer(msg.sender, totalOutput);
        
        for (uint256 i = 0; i < targetAddr.length; i++) {
            xWinLib.transferData memory _transferData = _getTransferAmt(targetAddr[i], redeemratio);
            if(_transferData.totalTrfAmt > 0){
                if (targetAddr[i] == baseToken) {
                    baseTokenAmt -= _transferData.totalTrfAmt;
                }
                IERC20Upgradeable(targetAddr[i]).safeTransfer(msg.sender, _transferData.totalTrfAmt);
            }
        }
    }
        
    /// @dev Calc return balance during redemption
    function _getTransferAmt(address underying, uint256 redeemratio) 
        internal view returns (xWinLib.transferData memory transData) {
       
        xWinLib.transferData memory _transferData;
        if (underying == baseToken) {
            _transferData.totalUnderlying = baseTokenAmt;
        } else {
            _transferData.totalUnderlying = getBalance(underying); 
        }
        uint256 qtyToTrf = redeemratio * _transferData.totalUnderlying / 1e18;
        _transferData.totalTrfAmt = qtyToTrf;
        return _transferData;
    }
    
    /// @dev Calc qty to issue during subscription 
    function _getMintQty(uint256 _unitPrice) internal view returns (uint256 mintQty)  {
        
        uint256 vaultValue = _getVaultValues();
        uint256 totalSupply = getFundTotalSupply();
        if(totalSupply == 0) return _convertTo18(vaultValue / UPMultiplier, baseToken); 
        uint256 newTotalSupply = vaultValue * 1e18 / _unitPrice;
        mintQty = newTotalSupply - totalSupply;
        return mintQty;
    }
    
    function _getActiveOverWeight(address destAddr, uint256 totalvalue) 
        internal view returns (uint256 destRebQty, uint256 destActiveWeight, bool overweight) {
        
        destRebQty = 0;
        uint256 destTargetWeight = TargetWeight[destAddr];
        uint256 destValue = _getTokenValues(destAddr);
        if (destAddr == baseToken) {
            destValue = baseTokenAmt;
        }
        uint256 fundWeight = destValue * 10000 / totalvalue;
        overweight = fundWeight > destTargetWeight;
        destActiveWeight = overweight ? fundWeight - destTargetWeight: destTargetWeight - fundWeight;
        if(overweight){
            uint256 price = _getLatestPrice(destAddr);
            destRebQty = ((destActiveWeight * totalvalue *  getDecimals(destAddr)) / price) / 10000;
        }
        return (destRebQty, destActiveWeight, overweight);
    }
    
    function _rebalance(uint32 _slippage) internal {
        
        (xWinLib.UnderWeightData[] memory underwgts, uint256 totalunderwgt) = _sellOverWeightNames(_slippage);
        _buyUnderWeightNames(underwgts, totalunderwgt, _slippage); 
        nextRebalance = block.number + rebalanceCycle;
    }
    
    function _sellOverWeightNames (uint32 _slippage) 
        internal returns (xWinLib.UnderWeightData[] memory underwgts, uint256 totalunderwgt) {
        
        uint256 totalbefore = _getVaultValues();
        underwgts = new xWinLib.UnderWeightData[](targetAddr.length);

        for (uint256 i = 0; i < targetAddr.length; i++) {
            (uint256 rebalQty, uint256 destMisWgt, bool overweight) = _getActiveOverWeight(targetAddr[i], totalbefore);
            if(overweight) //sell token to base
            {
                IERC20Upgradeable(targetAddr[i]).safeIncreaseAllowance(address(xWinSwap), rebalQty);
                xWinSwap.swapTokenToToken(rebalQty, targetAddr[i], baseToken, _slippage);
                if (targetAddr[i] == baseToken) {
                    baseTokenAmt -= rebalQty;
                }
            }else if(destMisWgt > 0)
            {
                xWinLib.UnderWeightData memory _underWgt;
                _underWgt.token = targetAddr[i];
                _underWgt.activeWeight = destMisWgt;
                underwgts[i] = _underWgt;
                totalunderwgt = totalunderwgt + destMisWgt;
            }
        }
        return (underwgts, totalunderwgt);
    }
    
    function _buyUnderWeightNames (xWinLib.UnderWeightData[] memory underweights, uint256 totalunderwgt, uint32 _slippage) 
        internal {
        uint baseccyBal = getBalance(baseToken) - baseTokenAmt;
        for (uint256 i = 0; i < underweights.length; i++) {
            
            if(underweights[i].token != address(0)){
                uint256 rebBuyQty = underweights[i].activeWeight * baseccyBal / totalunderwgt;
                if(rebBuyQty > 0 && rebBuyQty <= baseccyBal){
                    IERC20Upgradeable(baseToken).safeIncreaseAllowance(address(xWinSwap), rebBuyQty);
                    xWinSwap.swapTokenToToken(rebBuyQty, baseToken, underweights[i].token, _slippage);
                    if(underweights[i].token == baseToken) {
                        baseTokenAmt += rebBuyQty;
                    }
                }
            }
        }
    }
    
    function _moveNonIndex(
        address _token,
        uint32 _slippage
    ) internal returns (uint256 balanceToken, uint256 swapOutput) {
            
            balanceToken = getBalance(_token);
            IERC20Upgradeable(_token).safeIncreaseAllowance(address(xWinSwap), balanceToken);
            swapOutput = xWinSwap.swapTokenToToken(balanceToken, _token, baseToken, _slippage);
            return (balanceToken, swapOutput);
    }
    
    
    function _getDeleteNames(address[] calldata _toAddr) 
        internal 
        view 
        returns (xWinLib.DeletedNames[] memory delNames) 
    {
        
        delNames = new xWinLib.DeletedNames[](targetAddr.length);

        for (uint256 i = 0; i < targetAddr.length; i++) {
            uint256 matchtotal = 1;
            for (uint256 x = 0; x < _toAddr.length; x++){
                if(targetAddr[i] == _toAddr[x]){
                    break;
                }else if(targetAddr[i] != _toAddr[x] && _toAddr.length == matchtotal){
                    delNames[i].token = targetAddr[i]; 
                }
                matchtotal++;
            }
        }
        return delNames;
    }
    
    function _convertTo18(uint256 value, address token) internal view returns (uint){
        uint256 diffDecimal = 18 - ERC20Upgradeable(token).decimals();
        return diffDecimal > 0 ? (value * (10**diffDecimal)) : value; 
    }

    /// @dev display estimate shares if deposit 
    function getEstimateShares(uint256 _amt) external view returns (uint256 mintQty)  {
        
        uint _unitPrice = _getUnitPrice();
        uint256 vaultValue = _getVaultValues() + _amt;
        uint256 totalSupply = getFundTotalSupply();
        uint256 newTotalSupply = vaultValue * 1e18 / _unitPrice;
        mintQty = newTotalSupply - totalSupply;
    }
    
    /// @dev return unit price
    function getUnitPrice() override external view returns(uint256){
        return _getUP();
    }

    function _getUnitPrice(uint256 fundvalue) internal view returns(uint256){
        return getFundTotalSupply() == 0 ? UPMultiplier * getDecimals(baseToken) : _convertTo18(fundvalue *  1e18 / getFundTotalSupply(), baseToken);
    }

    /// @dev return unit price in USd
    function getUnitPriceInUSD() override external view returns(uint256){
        return _getUPInUSD();
    }
    
    function getLatestPrice(address _targetAdd) external view returns (uint256) {
        return _getLatestPrice(_targetAdd);
    }

    function getVaultValues() external override view returns (uint) {
        return _convertTo18(_getVaultValues(), baseToken);
    }

    function getVaultValuesInUSD() external override view returns (uint) {
        return _convertTo18(_getVaultValuesInUSD(), stablecoinUSDAddr);
    }  

    /// @dev return token value in the vault in BNB
    function getTokenValues(address tokenaddress) external view returns (uint256){
        return _convertTo18(_getTokenValues(tokenaddress), baseToken);
    }

    // get fund total supply including fees
    function getFundTotalSupply() public view returns(uint256) {
        return totalSupply() + pendingMFee + pendingPFee;
    }


    function _getLatestPrice(address _targetAdd) internal view returns (uint256) {
        if(_targetAdd == baseToken) return getDecimals(baseToken);
        uint256 rate = priceMaster.getPrice(_targetAdd, baseToken);
        return rate;
    }

    function _getLatestPriceInUSD(address _targetAdd) internal view returns (uint256) {
        if(_targetAdd == stablecoinUSDAddr) return getDecimals(stablecoinUSDAddr);
        uint256 rate = priceMaster.getPrice(_targetAdd, stablecoinUSDAddr);
        return rate;
    }
    
    function _getVaultValues() internal override view returns (uint256){
        
        uint256 totalValue = _getTokenValues(baseToken);
        for (uint256 i = 0; i < targetAddr.length; i++) {
            if(targetAddr[i] == baseToken) {
                continue;
            }
            totalValue = totalValue + _getTokenValues(targetAddr[i]);
        }
        return totalValue; 
    }

    function _getVaultValuesInUSD() internal view returns (uint256){
        
        uint256 totalValue = _getTokenValuesInUSD(baseToken);
        for (uint256 i = 0; i < targetAddr.length; i++) {
            if(targetAddr[i] == baseToken) {
                continue;
            }
            totalValue = totalValue + _getTokenValuesInUSD(targetAddr[i]);
        }
        return totalValue; 
    }

    function _getUP() internal view returns(uint256){
        return getFundTotalSupply() == 0 ? UPMultiplier * 1e18 : _convertTo18(_getVaultValues() *  1e18 / getFundTotalSupply(), baseToken);
    }

    function _getUnitPrice() internal override view returns(uint256){
        return getFundTotalSupply() == 0 ? UPMultiplier * getDecimals(baseToken) : _getVaultValues() *  1e18 / getFundTotalSupply();
    }

    function _getUPInUSD() internal view returns(uint256){
        return getFundTotalSupply() == 0 ? UPMultiplier * 1e18 : _convertTo18(_getVaultValuesInUSD() * 1e18 / getFundTotalSupply(), stablecoinUSDAddr);
    }

    function _getTokenValues(address token) internal view returns (uint256){
        uint256 tokenBalance = getBalance(token);
        uint256 price = _getLatestPrice(token);
        return tokenBalance * uint256(price) / getDecimals(token); 
    }

    function _getTokenValuesInUSD(address token) internal view returns (uint256){
        
        uint256 tokenBalance = getBalance(token);
        uint256 price = _getLatestPriceInUSD(token);
        return tokenBalance * uint256(price) / getDecimals(token);
    }

    function getBalance(address fromAdd) public view returns (uint256){
        return IERC20Upgradeable(fromAdd).balanceOf(address(this));
    }

    function getTargetNamesAddress() external view returns (address[] memory _targetNamesAddress){
        return targetAddr;
    }

    /// @dev return target amount based on weight of each token in the fund
    function getTargetWeightQty(address targetAdd, uint256 srcQty) internal view returns (uint256){
        return TargetWeight[targetAdd] * srcQty / 10000;
    }
    
    /// Get All the fund data needed for client
    function GetFundExtra() external view returns (
          uint256 managementFee,
          uint256 performanceFee,
          uint256 platFee,
          address mAddr,          
          address mRebAddr,   
          address pWallet       
        ){
            return (
                managerFee,
                performFee,
                platformFee,
                managerAddr, 
                managerRebAddr,
                platformWallet
            );
    }

    function getDecimals(address _token) private view returns (uint) {
        return (10 ** ERC20Upgradeable(_token).decimals());
    }

    /// Get All the fund data needed for client
    function GetFundDataAll() external view returns (
          IERC20Upgradeable baseCcy,
          address[] memory targetAddress,
          uint256 totalUnitB4,
          uint256 baseBalance,
          uint256 unitprice,
          uint256 fundvalue,
          uint256 unitpriceUSD,
          uint256 fundvalueUSD,
          string memory fundName,
          string memory symbolName 
        ){
            return (
                IERC20Upgradeable(baseToken), 
                targetAddr, 
                getFundTotalSupply(), 
                getBalance(baseToken),
                _getUP(), 
                _convertTo18(_getVaultValues(), baseToken),
                _getUPInUSD(), 
                _convertTo18(_getVaultValuesInUSD(), stablecoinUSDAddr),
                name(),
                symbol()
            );
    }

    function setValidInvestor(address _wallet, bool _allow) external onlyRebManager {
        validInvestors[_wallet] = _allow;
    }

    function setOpenForPublic(bool _allow) external onlyOwner {
        openForPublic = _allow;
    }

    function updateOtherProperties(uint256 newCycle, uint256 _ratio, uint256 _UPMultiplier) external onlyOwner  {
        rebalanceCycle = newCycle;
        smallRatio = _ratio;
        UPMultiplier = _UPMultiplier;
    }

    /// @dev update average blocks per day value
    function updateBlockPerday(uint256 _blocksPerDay) external onlyOwner  {        
        blocksPerDay = _blocksPerDay;
    }

    /// @dev update platform fee and wallet
    function updatePlatformProperty(address _newAddr, uint256 _newFee) external onlyOwner {
        require(_newAddr != address(0), "_newAddr Input 0");
        require(_newFee <= 100, "Platform Fee cap at 1%");
        _calcFundFee();
        platformWallet = _newAddr;
        platformFee = _newFee;
    }

    function setPerformanceFee(uint256 _performFee) external onlyOwner {
        require(_performFee <= 2000, "Performance Fee cap at 20%");
        performFee = _performFee;
    }
    
    /// @dev update manager fee and wallet
    function updateManagerProperty(address newRebManager, address newManager, uint256 newFeebps) external onlyOwner  {
        require(newRebManager != address(0), "newRebManager Input 0");
        require(newManager != address(0), "newManager Input 0");
        require(newFeebps <= 300, "Manager Fee cap at 3%");
        _calcFundFee();
        managerFee = newFeebps;
        managerAddr = newManager;
        managerRebAddr = newRebManager;
    }
    
    /// @dev update xwin master contract
    function updatexWinEngines(address _priceMaster, address _xwinSwap) external onlyOwner {
        require(_priceMaster != address(0), "_priceMaster Input 0");
        require(_xwinSwap != address(0), "_xwinSwap Input 0");
        priceMaster = IxWinPriceMaster(_priceMaster);
        xWinSwap = IxWinSwap(_xwinSwap);
    }

    function updateLockedStakingAddress(address _lockedStaking) external onlyOwner {
        lockingAddress = _lockedStaking;
    }

    function setPerformDeposit(uint256 mintShares, uint256 latestUP) internal {
        uint256 newTotalShares = performanceMap[msg.sender].shares + mintShares;
        performanceMap[msg.sender].avgPrice = ((performanceMap[msg.sender].shares * performanceMap[msg.sender].avgPrice) + (mintShares * latestUP)) / newTotalShares;
        performanceMap[msg.sender].shares = newTotalShares;
    }

    function setPerformWithdraw(
        uint256 swapOutput, 
        uint256 _shares,
        address _investorAddress, 
        address _managerAddress
    ) internal returns (uint256) {

        uint256 realUnitprice = swapOutput * 1e18 /_shares;
        uint256 performanceUnit;
        uint256 notRecognizedShare;

        userAvgPrice memory pM = performanceMap[_investorAddress];

        if (_shares > pM.shares) {
            notRecognizedShare = _shares - pM.shares;
        }
        uint256 recognizedShare = _shares - notRecognizedShare;
        uint256 notRecognisedRatio = notRecognizedShare * 10000 / _shares;

        // if no shares recorded, then charge for performance fee on entire swap output of unrecognized tokens
        if(notRecognizedShare > 0) {
            uint256 notRecognizedWithdraw = notRecognisedRatio * swapOutput / 10000;
            performanceUnit = notRecognizedWithdraw * performFee / 10000;
        }

        uint256 profitPerUnit = realUnitprice > pM.avgPrice ? realUnitprice - pM.avgPrice : 0; 
        if(notRecognizedShare == 0 && (performFee == 0 || waivedPerformanceFees[msg.sender] || profitPerUnit == 0)){
            uint remain = pM.shares - _shares;
            performanceMap[_investorAddress].shares = remain;
            if(remain == 0 ){
                performanceMap[_investorAddress].avgPrice = 0;
            } 
            return swapOutput;
        }

        if(recognizedShare > 0) {
            uint256 actualPerformFee = getDiscountedPerformFee(msg.sender);
            performanceMap[_investorAddress].shares = pM.shares - recognizedShare;
            uint256 anotherProfit = (10000 - notRecognisedRatio) * profitPerUnit * swapOutput / realUnitprice / 10000;
            performanceUnit = performanceUnit + (anotherProfit * actualPerformFee / 10000);
        }

        if(performanceUnit > 0) IERC20Upgradeable(baseToken).safeTransfer(_managerAddress, performanceUnit);
        return swapOutput - performanceUnit;
    }


    function getUserAveragePrice(address _user) external view returns (uint256 shares, uint256 avgPrice){        
        return (performanceMap[_user].shares, performanceMap[_user].avgPrice);
    }

    function getDiscountedPerformFee(address _user) public view returns (uint256 newPerformanceFee) {
        if (lockingAddress == address(0)) {
            return performFee;
        }
        uint256 discount = ILockedStake(lockingAddress).getFavor(_user);
        return performFee - ((performFee * discount) / 10000);
    }

    function addContractWaiveFee(address _contract) external onlyOwner {
        waivedPerformanceFees[_contract] = true; 
    }

    function removeContractWaiveFee(address _contract) external onlyOwner {
        waivedPerformanceFees[_contract] = false;
    }

    function sumArray(uint256[] calldata arr) private pure returns(uint256) {
        uint256 i;
        uint256 sum = 0;
            
        for(i = 0; i < arr.length; i++)
            sum = sum + arr[i];
        return sum;
    }

    function findDup(address[] calldata a) private pure returns(bool) {
        for(uint i = 0; i < a.length - 1; i++) {
            for(uint j = i + 1; j < a.length; j++) {
                if (a[i] == a[j]) return true;
            }
        }
        return false;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    modifier onlyRebManager {
        require(
            msg.sender == managerRebAddr,
            "Only for Reb Manager"
        );
        _;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;


interface ILockedStake  {
    function getFavor(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IxWinEmitEvent {

    function feeTransfered(
        address _token,
        uint _amount,
        address _contractAddress

    ) external;


    function FeeEvent(string memory _eventtype, address _contractaddress, uint256 _fee) external;
    function FundEvent(
        string memory _type,
        address _contractaddress, 
        address _useraddress, 
        uint _rate, 
        uint _amount, 
        uint _shares
    ) external;

    function setExecutor(address _address, bool _allow) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IxWinPriceMaster {
    function getPrice(address _from, address _to) external view returns (uint rate);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IxWinSwap {
    function swapTokenToToken(uint _amount, address _fromToken, address _toToken) external payable returns (uint);
    function swapTokenToToken(uint _amount, address _fromToken, address _toToken, uint32 _slippage) external payable returns (uint);
    function swapTokenToExactToken(uint _amount, uint _exactAmount, address _fromToken, address _toToken) external payable returns (uint);

    function addTokenPath(
            address _router, 
            address _fromtoken, 
            address _totoken, 
            address[] memory path,
            uint256 _slippage
        ) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library xWinLib {
   
    
    struct transferData {      
      uint256 totalTrfAmt;
      uint256 totalUnderlying;
    }
    
    struct UnderWeightData {
      uint256 activeWeight;
      address token;
    }
    
    struct DeletedNames {
      address token;
      uint256 targetWeight;
    }

}

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./Interface/IxWinEmitEvent.sol";


abstract contract xWinStrategy is ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public stablecoinUSDAddr;
    address public baseToken; // DEPOSIT/WITHDRAW TOKEN
    IxWinEmitEvent public emitEvent;
    uint256[10] private __gap;

    function __xWinStrategy_init(
        string memory name,
        string memory symbol,
        address _baseToken,
        address _USDTokenAddr
     ) onlyInitializing internal {
        require(_baseToken != address(0), "_baseToken input 0");
        require(_USDTokenAddr != address(0), "_USDTokenAddr input 0");
        __Ownable_init();
        __ERC20_init(name, symbol);
        __ReentrancyGuard_init();
        __Pausable_init();
        baseToken = _baseToken;
        stablecoinUSDAddr = _USDTokenAddr;
    }

    event _Deposit(uint256 datetime, address contractaddress, uint256 rate, uint256 depositAmount, uint256 shares);
    event _Withdraw(uint256 datetime, address contractaddress, uint256 rate, uint256 avrCost, uint256 withdrawAmount, uint256 shares);


    function getVaultValues() external virtual view returns (uint256);
    function _getVaultValues() internal virtual view returns (uint256);
    function getUnitPrice()  external virtual view returns (uint256);
    function _getUnitPrice() internal virtual view returns (uint256);   
    function getVaultValuesInUSD() external virtual view returns (uint256);        
    function getUnitPriceInUSD()  external virtual view returns (uint256);
    function deposit(uint256 amount) external virtual returns (uint256);
    function withdraw(uint256 amount) external virtual returns (uint256);
        function deposit(uint256 amount, uint32 slippage) external virtual returns (uint256);
    function withdraw(uint256 amount, uint32 slippage) external virtual returns (uint256);

    function setEmitEvent(address _addr) external onlyOwner {
        require(_addr != address(0), "_addr input is 0");
         emitEvent = IxWinEmitEvent(_addr);
    }

    function updateUSDAddr(address _newUSDAddr) external onlyOwner {
        require(_newUSDAddr != address(0), "_newUSDAddr input is 0");
        stablecoinUSDAddr = _newUSDAddr;
    }

    function setPause() external onlyOwner {
        _pause();
    }

    function setUnPause() external onlyOwner {
        _unpause();
    }


}