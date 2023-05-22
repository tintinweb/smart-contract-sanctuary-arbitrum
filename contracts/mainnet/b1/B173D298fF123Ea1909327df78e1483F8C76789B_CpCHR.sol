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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./CpCHRSolidStaker.sol";
import "../interfaces/ISolidlyRouter.sol";

contract CpCHR is CpCHRSolidStaker {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Needed addresses
    address[] public mainActiveVoteLps;
    address[] public reserveActiveVoteLps;
    ISolidlyRouter.Routes[] public wantToNativeRoute;

    // Events
    event ClaimVeEmissions(address indexed user, uint256 amount);
    event SetRouter(address oldRouter, address newRouter);
    event RewardsHarvested(uint256 rewardTHE, uint256 rewardCpCHR);
    event Voted(uint256 tokenId, address[] votes, uint256[] weights);
    event ChargedFees(uint256 callFees, uint256 coFees, uint256 strategistFees);

    function initialize(
        string memory _name,
        string memory _symbol,
        address _proxy,
        address[] calldata _manager,
        address _configurator,
        ISolidlyRouter.Routes[] calldata _wantToNativeRoute
    ) public initializer {
        CpCHRSolidStaker.init(
            _name,
            _symbol,
            _proxy,
            _manager[0],
            _manager[1],
            _manager[2],
            _manager[3],
            _configurator
        );

        for (uint i; i < _wantToNativeRoute.length; i++) {
            wantToNativeRoute.push(_wantToNativeRoute[i]);
        }
    }

    function voteInfo(uint256 _tokenId) external view
        returns (
            address[] memory lpsVoted,
            uint256[] memory votes,
            uint256 lastVoted
        ) {
        uint256 mainTokenId = proxy.mainTokenId();
        uint256 reserveTokenId = proxy.reserveTokenId();
        
        uint256 len = mainActiveVoteLps.length;
        uint256 tokenId = mainTokenId;
        if (_tokenId == reserveTokenId) {
            tokenId = reserveTokenId;
            len = reserveActiveVoteLps.length;
        }

        lpsVoted = new address[](len);
        votes = new uint256[](len);
        for (uint i; i < len; i++) {
            lpsVoted[i] = solidVoter.poolVote(tokenId, i);
            votes[i] = solidVoter.votes(tokenId, lpsVoted[i]);
        }

        lastVoted = solidVoter.lastVoted(tokenId);
    }

    // function claimVeEmissions() public {
    //     uint256 _amount = proxy.claimVeEmissions();
    //     uint256 gap = totalWant() - totalSupply();
    //     if (gap > 0) {
    //         uint256 feePercent = configurator.getFee();
    //         address coFeeRecipient = configurator.coFeeRecipient();
    //         uint256 feeBal = (gap * feePercent) / MAX_RATE;
            
    //         if (feeBal > 0) _mint(address(coFeeRecipient), feeBal);
    //         _mint(address(daoWallet), gap - feeBal);
    //     }

    //     emit ClaimVeEmissions(msg.sender, _amount);
    // }

    function vote(
        uint256 _tokenId,
        address[] calldata _tokenVote,
        uint256[] calldata _weights,
        bool _withHarvest
    ) external onlyVoter {
        // Check to make sure we set up our rewards
        for (uint i; i < _tokenVote.length; i++) {
            require(proxy.lpInitialized(_tokenVote[i]), "Staker: TOKEN_VOTE_INVALID");
        }

        uint256 reserveTokenId = proxy.reserveTokenId();
        bool isReserve = _tokenId == reserveTokenId;
        if (_withHarvest) {
            harvestVe(isReserve);
        }
        
        if (isReserve) {
            reserveActiveVoteLps = _tokenVote;
        } else {
            mainActiveVoteLps = _tokenVote;
        }

        // We claim first to maximize our voting power.
        // claimVeEmissions();
        proxy.vote(_tokenId, _tokenVote, _weights);
        emit Voted(_tokenId, _tokenVote, _weights);
    }

    /**
     * @param _type (bool): true - harvestVeReserve, false - harvestVeMain.
    */
    function harvestVe(bool _type) public {
        uint256 mainTokenId = proxy.mainTokenId();
        uint256 reserveTokenId = proxy.reserveTokenId();
        
        uint256 tokenId = mainTokenId;
        address[] memory activeVoteLps = mainActiveVoteLps;
        if(_type) {
            tokenId = reserveTokenId;
            activeVoteLps = reserveActiveVoteLps;
        }

        for (uint i; i < activeVoteLps.length; i++) {
            proxy.getBribeReward(tokenId, activeVoteLps[i]);
            proxy.getTradingFeeReward(tokenId, activeVoteLps[i]);
        }

        _chargeFees();
    }

    function _chargeFees() internal {
        uint256 rewardTHEBal = IERC20Upgradeable(want).balanceOf(address(this));
        uint256 rewardCpCHRBal = balanceOf(address(this));
        uint256 feePercent = configurator.getFee();
        address coFeeRecipient = configurator.coFeeRecipient();

        if (rewardTHEBal > 0) {
            uint256 feeBal = (rewardTHEBal * feePercent) / MAX_RATE;
            if (feeBal > 0) {
                IERC20Upgradeable(want).safeApprove(address(router), feeBal);
                router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    feeBal,
                    0,
                    wantToNativeRoute,
                    address(coFeeRecipient),
                    block.timestamp
                );
                IERC20Upgradeable(want).safeApprove(address(router), 0);
                emit ChargedFees(0, feeBal, 0);
            }

            IERC20Upgradeable(want).safeTransfer(daoWallet, rewardTHEBal - feeBal);
        }

        if (rewardCpCHRBal > 0) {
            uint256 feeBal = (rewardCpCHRBal * feePercent) / MAX_RATE;
            if (feeBal > 0) {
                IERC20Upgradeable(address(this)).safeTransfer(address(coFeeRecipient), feeBal);
                emit ChargedFees(0, feeBal, 0);
            }

            IERC20Upgradeable(address(this)).safeTransfer(daoWallet, rewardCpCHRBal - feeBal);
        }

        emit RewardsHarvested(rewardTHEBal, rewardCpCHRBal);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        require(polWallet != address(0),"require to set polWallet address");
        address sender = _msgSender();
        uint256 taxAmount = _chargeTaxTransfer(sender, to, amount);
        _transfer(sender, to, amount - taxAmount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(polWallet != address(0),"require to set polWallet address");
        
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        uint256 taxAmount = _chargeTaxTransfer(from, to, amount);
        _transfer(from, to, amount - taxAmount);
        return true;
    }

    function _chargeTaxTransfer(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 taxSellingPercent = configurator.hasSellingTax(from, to);
        uint256 taxBuyingPercent = configurator.hasBuyingTax(from, to);
        uint256 taxPercent = taxSellingPercent > taxBuyingPercent ? taxSellingPercent: taxBuyingPercent;
		if(taxPercent > 0) {
            uint256 taxAmount = amount * taxPercent / MAX;
            uint256 amountToDead = taxAmount / 2;
            _transfer(from, configurator.deadWallet(), amountToDead);
            _transfer(from, polWallet, taxAmount - amountToDead);
            return taxAmount;
		}

        return 0;
    }

    // Set our router to exchange our rewards, also update new wantToNative route.
    function setRouterAndRoute(address _router, ISolidlyRouter.Routes[] calldata _route) external onlyManager {
        emit SetRouter(address(router), _router);
        delete wantToNativeRoute;
        for (uint i; i < _route.length; i++) wantToNativeRoute.push(_route[i]);
        router = ISolidlyRouter(_router);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IVoter.sol";
import "../interfaces/IVeToken.sol";
import "../interfaces/IPairFactory.sol";
import "../interfaces/ISolidlyFactory.sol";
import "../interfaces/ICpCHRConfigurator.sol";
import "../interfaces/ISolidlyRouter.sol";
import "../interfaces/ICpCHRProxy.sol";

contract CpCHRSolidStaker is ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Addresses used
    ICpCHRProxy public proxy;
    ICpCHRConfigurator public configurator;
    IERC20Upgradeable public want;
    IERC20Upgradeable public native;
    IVeToken public ve;
    IVoter public solidVoter;
    ISolidlyRouter public router;

    // Max Lock time, Max variable used for reserve split and the reserve rate.
    uint16 public constant MAX = 10000;
    uint256 public constant MAX_RATE = 1e18;

    address public keeper;
    address public voter;
    address public polWallet;
    address public daoWallet;

    // Our on chain events.
    event CreateLock(address indexed user, uint256 veTokenId, uint256 amount, uint256 unlockTime);
    event NewManager(address _keeper, address _voter, address _polWallet, address _daoWallet);
    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);
    event MergeNFT(uint256 from, uint256 to);

    // Checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(
            msg.sender == owner() || msg.sender == keeper,
            "CpCHRSolidStaker: MANAGER_ONLY"
        );
        _;
    }

    // Checks that caller is either owner or keeper.
    modifier onlyVoter() {
        require(msg.sender == voter, "CpCHRSolidStaker: VOTER_ONLY");
        _;
    }

    function init(
        string memory _name,
        string memory _symbol,
        address _proxy,
        address _keeper,
        address _voter,
        address _polWallet,
        address _daoWallet,
        address _configurator
    ) public initializer {
        __Ownable_init();
        __ERC20_init(_name, _symbol);
        
        configurator = ICpCHRConfigurator(_configurator);
        proxy = ICpCHRProxy(_proxy);
        
        solidVoter = IVoter(proxy.solidVoter());
        ve = IVeToken(solidVoter._ve());
        want = IERC20Upgradeable(ve.token());

        router = ISolidlyRouter(proxy.router());
        native = IERC20Upgradeable(router.wETH());

        keeper = _keeper;
        voter = _voter;
        polWallet = _polWallet;
        daoWallet = _daoWallet;
    }

    function depositVe(uint256 _tokenId) external nonReentrant whenNotPaused {
        require(!configurator.isPausedDepositVe(), "CpCHR: PAUSED");
        uint256 mainTokenId = proxy.mainTokenId();
        uint256 reserveTokenId = proxy.reserveTokenId();
        require(mainTokenId > 0 && reserveTokenId > 0, "CpCHR: NOT_ASSIGNED");
        uint256 currentPeg = getCurrentPeg();
        require(currentPeg >= configurator.maxPeg(), "CpCHR: NOT_MINT_WITH_UNDER_PEG");
        lock();
        (uint256 _lockedAmount, ) = ve.locked(_tokenId);
        if (_lockedAmount > 0) {
            ve.transferFrom(msg.sender, address(proxy), _tokenId);
            if (balanceOfWantInReserveVe() > requiredReserve()) {
                proxy.merge(_tokenId, mainTokenId);
            } else {
                proxy.merge(_tokenId, reserveTokenId);
            }
            
            _mint(msg.sender, _lockedAmount);
            emit Deposit(_lockedAmount);
        }
    }

    function deposit(uint256 _amount) external nonReentrant whenNotPaused {
        require(!configurator.isPausedDeposit(), "CpCHR: PAUSED");
        uint256 mainTokenId = proxy.mainTokenId();
        uint256 reserveTokenId = proxy.reserveTokenId();
        require(mainTokenId > 0 && reserveTokenId > 0, "CpCHR: NOT_ASSIGNED");
        lock();
        ISolidlyRouter.Routes[] memory routes = new ISolidlyRouter.Routes[](2);
        routes[0] = ISolidlyRouter.Routes({
            from: address(want),
            to: address(native),
            stable: false
        });
        
        routes[1] = ISolidlyRouter.Routes({
            from: address(native),
            to: address(this),
            stable: false
        });

        address pairAddress = ISolidlyFactory(solidVoter.factory()).getPair(address(native), address(this), false);
        require(pairAddress != address(0), "CpCHR: LP_INVALID");
        uint256 amountOut = router.getAmountsOut(_amount, routes)[routes.length];
        uint256 taxBuyingPercent = configurator.hasBuyingTax(address(this), pairAddress);
        amountOut = amountOut - amountOut * taxBuyingPercent / MAX;

        if (amountOut > _amount) {
            want.safeTransferFrom(msg.sender, address(this), _amount);
            IERC20Upgradeable(want).safeApprove(address(router), _amount);
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amount,
                0,
                routes,
                msg.sender,
                block.timestamp
            );
            IERC20Upgradeable(want).safeApprove(address(router), 0);
        } else {
            uint256 _balanceBefore = balanceOfWant();
            want.safeTransferFrom(msg.sender, address(this), _amount);
            _amount = balanceOfWant() - _balanceBefore;

            if (_amount > 0) {
                _mint(msg.sender, _amount);
                uint256 wantAmount = balanceOfWant();
                want.safeTransfer(address(proxy), wantAmount);
                if (balanceOfWantInReserveVe() > requiredReserve()) {
                    proxy.increaseAmount(mainTokenId, wantAmount);
                } else {
                    proxy.increaseAmount(reserveTokenId, wantAmount);
                }
            }
        }

        emit Deposit(totalWant());
    }

    function lock() public { 
        if (configurator.isAutoIncreaseLock()) {
            proxy.increaseUnlockTime();
        }
    }

    function merge(uint256 from, uint256 to) external nonReentrant {
        uint256 mainTokenId = proxy.mainTokenId();
        uint256 reserveTokenId = proxy.reserveTokenId();
        require(to == mainTokenId || to == reserveTokenId, "CpCHR: TO_INVALID");
        require(from != mainTokenId && from != reserveTokenId, "CpCHR: FROM_INVALID");
        ve.transferFrom(address(this), address(proxy), from);
        proxy.merge(from, to);
        emit MergeNFT(from, to); 
    }

    function withdraw(uint256 _amount) external nonReentrant {
        uint256 redeemTokenId = proxy.redeemTokenId();
        require(redeemTokenId > 0, "CpCHR: NOT_ASSIGNED");
        uint256 lastVoted = solidVoter.lastVoted(redeemTokenId);
        require(block.timestamp > lastVoted + configurator.minDuringTimeWithdraw(), "CpCHR: PAUSED_AFTER_VOTE");

        uint256 withdrawableAmount = withdrawableBalance();
        require(withdrawableAmount > MAX_RATE && _amount < withdrawableAmount - MAX_RATE, "CpCHR: INSUFFICIENCY_AMOUNT_OUT");
        _burn(msg.sender, _amount);
        uint256 redeemFeePercent = configurator.redeemFeePercent();
        if (redeemFeePercent > 0) {
            uint256 redeemFeeAmount = (_amount * redeemFeePercent) / MAX;
            if (redeemFeeAmount > 0) {
                _amount = _amount - redeemFeeAmount;
                // mint fee
                _mint(polWallet, redeemFeeAmount);
            }
        }

        if (ve.voted(redeemTokenId)) {
            proxy.resetVote(redeemTokenId);
        }

        uint256 tokenIdForUser = proxy.splitWithdraw(_amount);
        ve.transferFrom(address(this), msg.sender, tokenIdForUser);
        emit Withdraw(_amount);
    }

    function totalWant() public view returns (uint256) {
        return balanceOfWantInMainVe() + balanceOfWantInReserveVe() + balanceOfWant();
    }

    function lockInfo(uint256 _tokenId)
        public
        view
        returns (
            uint256 endTime,
            uint256 secondsRemaining
        )
    {
        (, endTime) = ve.locked(_tokenId);
        secondsRemaining = endTime > block.timestamp
            ? endTime - block.timestamp
            : 0;
    }

    function requiredReserve() public view returns (uint256 reqReserve) {
        reqReserve = balanceOfWantInMainVe() * configurator.reserveRate() / MAX;
    }

    function withdrawableBalance() public view returns (uint256) {
        return proxy.withdrawableBalance();
    }

    function balanceOfWantInMainVe() public view returns (uint256 wants) {
        return proxy.balanceOfWantInMainVe();
    }

    function balanceOfWantInReserveVe() public view returns (uint256 wants) {
        return proxy.balanceOfWantInReserveVe();
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function resetVote(uint256 _tokenId) external onlyVoter {
        proxy.resetVote(_tokenId);
    }

    function createReserveLock(
        uint256 _amount,
        uint256 _lock_duration
    ) external onlyManager {
        require(_amount > 0, "CpCHR: ZERO_AMOUNT");
        want.safeTransferFrom(address(msg.sender), address(proxy), _amount);
        proxy.createReserveLock(_amount, _lock_duration);
        _mint(msg.sender, _amount);

        emit CreateLock(msg.sender, proxy.reserveTokenId(), _amount, _lock_duration);
    }

    function createMainLock(
        uint256 _amount,
        uint256 _lock_duration
    ) external onlyManager {
        require(_amount > 0, "CpCHR: ZERO_AMOUNT");
        want.safeTransferFrom(address(msg.sender), address(proxy), _amount);
        proxy.createMainLock(_amount, _lock_duration);
        _mint(msg.sender, _amount);

        emit CreateLock(msg.sender, proxy.mainTokenId(), _amount, _lock_duration);
    }

    // Pause deposits
    function pause() public onlyManager {
        _pause();
    }

    // Unpause deposits
    function unpause() external onlyManager {
        _unpause();
    }

    function getCurrentPeg() public view returns (uint256) {
        ISolidlyFactory factory = ISolidlyFactory(solidVoter.factory());
        address pairAddress = factory.getPair(address(native), address(this), false);
        require(pairAddress != address(0), "CpCHR: LP_INVALID");
        IPairFactory pair = IPairFactory(pairAddress);
        address token0 = pair.token0();
        (uint256 _reserve0, uint256 _reserve1, ) = pair.getReserves();

        uint256 peg1 = 0;
        if (token0 == address(this)) {
            peg1 = _reserve1 * MAX_RATE / _reserve0;
        } else {
            peg1 = _reserve0 * MAX_RATE / _reserve1;
        }

        address pair2Address = factory.getPair(address(native), address(want), false);
        IPairFactory pair2 = IPairFactory(pair2Address);
        (_reserve0, _reserve1, ) = pair2.getReserves();
        token0 = pair2.token0();
        if (token0 == address(native)) {
            return peg1 * _reserve1 / _reserve0;
        } else {
            return peg1 * _reserve0 / _reserve1;
        }
    }

    function setManager(
        address _keeper,
        address _voter,
        address _polWallet,
        address _daoWallet
    ) external onlyManager {
        keeper = _keeper;
        voter = _voter;
        polWallet = _polWallet;
        daoWallet = _daoWallet;
        emit NewManager(_keeper, _voter, _polWallet, _daoWallet);
    }

    function setSolidVoter(address _solidVoter) external onlyManager {
        proxy.setSolidVoter(_solidVoter);
        solidVoter = IVoter(_solidVoter);
    }

    // function setVeDist(address _veDist) external onlyManager {
    //     proxy.setVeDist(_veDist);
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ICpCHRConfigurator {
    function redeemFeePercent() external view returns (uint256);
    function minDuringTimeWithdraw() external view returns (uint256);
    function isAutoIncreaseLock() external view returns (bool);
    function maxPeg() external view returns (uint256);
    function reserveRate() external view returns (uint256);

    function isPausedDeposit() external view returns (bool);
    function isPausedDepositVe() external view returns (bool);

    function hasSellingTax(address _from, address _to) external view returns (uint256);
    function hasBuyingTax(address _from, address _to) external view returns (uint256);
    function deadWallet() external view returns (address);
    function getFee() external view returns (uint256);
    function coFeeRecipient() external view returns (address); 
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ICpCHRProxy {
    function mainTokenId() external view returns (uint256);
    function reserveTokenId() external view returns (uint256);
    function redeemTokenId() external view returns (uint256); 
    function CHR() external view returns (address);
    function solidVoter() external view returns (address);
    function router() external view returns (address);
    function lpInitialized(address _lp) external view returns (bool);

    function withdrawableBalance() external view returns (uint256 wants);
    function balanceOfWantInMainVe() external view returns (uint256 wants);
    function balanceOfWantInReserveVe() external view returns (uint256 wants);

    function createMainLock(uint256 _amount, uint256 _lock_duration) external;
    function createReserveLock(uint256 _amount, uint256 _lock_duration) external;
    function vote(
        uint256 _tokenId,
        address[] calldata _tokenVote,
        uint256[] calldata _weights
    ) external;
    
    function merge(uint256 _from, uint256 _to) external;
    function increaseAmount(uint256 _tokenId, uint256 _amount) external;
    function increaseUnlockTime() external;
    function resetVote(uint256 _tokenId) external;
    function splitWithdraw(uint256 _amount) external returns (uint256);
    function claimVeEmissions() external returns (uint256);

    function setSolidVoter(address _solidVoter) external;
    function setVeDist(address _veDist) external;

    function getBribeReward(uint256 _tokenId, address _lp) external;
    function getTradingFeeReward(uint256 _tokenId, address _lp) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IPairFactory {
    function balanceOf(address account) external view returns (uint);
    function isPair(address pair) external view returns (bool);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
    function claimFees() external returns (uint, uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (
        uint112 _reserve0,
        uint112 _reserve1,
        uint32 _blockTimestampLast
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISolidlyFactory {
    function allPairsLength() external view returns (uint);
    function isPair(address pair) external view returns (bool);
    function allPairs(uint index) external view returns (address);
    function pairCodeHash() external pure returns (bytes32);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISolidlyRouter {
    // Routes
    struct Routes {
        address from;
        address to;
        bool stable;
    }

    function wETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        bool stable, 
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable, 
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokensSimple(
        uint amountIn, 
        uint amountOutMin, 
        address tokenFrom, 
        address tokenTo,
        bool stable, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        Routes[] memory route, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount, bool stable);

    function getAmountsOut(uint amountIn, Routes[] memory routes) external view returns (uint[] memory amounts);

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired
    ) external view returns (uint amountA, uint amountB, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        Routes[] calldata routes,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IVeToken {
    function create_lock(uint256 _value, uint256 _lockDuration) external returns (uint256 _tokenId);
    function increase_amount(uint256 tokenId, uint256 value) external;
    function increase_unlock_time(uint256 tokenId, uint256 duration) external;
    function withdraw(uint256 tokenId) external;
    function balanceOfNFT(uint256 tokenId) external view returns (uint256 balance);
    function locked(uint256 tokenId) external view returns (uint256 amount, uint256 endTime);
    function token() external view returns (address);
    function merge(uint _from, uint _to) external;
    function transferFrom(address _from, address _to, uint _tokenId) external;
    function balanceOf(address _owner) external view returns (uint);
    function split(uint[] memory amounts, uint _tokenId) external;
    function tokenOfOwnerByIndex(address _owner, uint _tokenIndex) external view returns (uint);
    function approve(address _approved, uint _tokenId) external;
    function voted(uint _tokenId) external view returns (bool);
    function ownerOf(uint256 _tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IVoter {
    function vote(uint256 tokenId, address[] calldata poolVote, uint256[] calldata weights) external;
    function whitelist(address token, uint256 tokenId) external;
    function reset(uint256 tokenId) external;
    function gauges(address lp) external view returns (address);
    function _ve() external view returns (address);
    function minter() external view returns (address);
    function external_bribes(address _lp) external view returns (address);
    function internal_bribes(address _lp) external view returns (address);
    function votes(uint256 id, address lp) external view returns (uint256);
    function poolVote(uint256 id, uint256 index) external view returns (address);
    function lastVoted(uint256 id) external view returns (uint256);
    function weights(address lp) external view returns (uint256);
    function factory() external view returns (address);
}