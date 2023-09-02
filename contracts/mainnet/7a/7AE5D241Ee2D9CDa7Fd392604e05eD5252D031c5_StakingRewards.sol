// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}

interface ICERC20 is IERC20 {
    // CToken
    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Returns the current per-block borrow interest rate for this cToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view returns (uint256);

    /**
     * @notice Returns the current per-block supply interest rate for this cToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view returns (uint256);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    // Cerc20
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function underlying() external view returns (address);

    function liquidateBorrow(address borrower, uint256 repayAmount, address cTokenCollateral) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalReserves() external returns (uint);

    function _reduceReserves(uint reduceAmount) external returns (uint);
}

interface SushiRouterInterface {
    function WETH() external returns (address);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        fixed swapAmountETH,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;
}

interface CurveInterface {
    function exchange_multiple(address[9] memory, uint256[3][4] memory, uint256, uint256, address[4] memory) external;
}

interface PriceOracleProxyETHInterface {
    function getUnderlyingPrice(address lToken) external returns (uint256);

    struct AggregatorInfo {
        address source;
        uint8 base;
    }

    function aggregators(address lToken) external returns (AggregatorInfo memory);
}

interface IPlutusDepositor {
    function redeem(uint256 amount) external;

    function redeemAll() external;
}

interface IGLPRouter {
    function unstakeAndRedeemGlpETH(
        uint256 _glpAmount,
        uint256 _minOut,
        address payable _receiver
    ) external returns (uint256);

    function unstakeAndRedeemGlp(
        address tokenOut,
        uint256 glpAmount,
        uint256 minOut,
        address receiver
    ) external returns (uint256);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

interface ICETH is ICERC20 {
    function liquidateBorrow(address borrower, ICERC20 cTokenCollateral) external payable;
}

interface StakingRewardsInterface {
    function updateWeeklyRewards(uint256 newRewards) external;
}

interface IVotingPower {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function getVotes(address user) external returns (uint256);

    function getRawVotingPower(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.18;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "./Utils/StakingConstants.sol";
import "solmate/src/utils/FixedPointMathLib.sol";

/**
 * @title Lodestar Finance Staking Contract
 * @author Lodestar Finance
 */

contract StakingRewards is
    StakingConstants,
    Initializable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    Ownable2StepUpgradeable,
    ERC20Upgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using FixedPointMathLib for uint256;

    /**
     * @notice initializer function
     * @param _LODE LODE token address
     * @param _WETH WETH address
     * @param _esLODE esLODE address
     * @param _routerContract Router address
     * @dev can only be called once
     */
    function initialize(address _LODE, address _WETH, address _esLODE, address _routerContract) public initializer {
        __Context_init();
        __Ownable2Step_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC20_init("Staking LODE", "stLODE");

        LODE = IERC20Upgradeable(_LODE);
        WETH = IERC20Upgradeable(_WETH);
        esLODE = IERC20Upgradeable(_esLODE);
        routerContract = _routerContract;

        stLODE3M = 1400000000000000000;
        stLODE6M = 2000000000000000000;
        relockStLODE3M = 50000000000000000;
        relockStLODE6M = 100000000000000000;

        lastRewardSecond = uint32(block.timestamp);
    }

    /**
     * @notice Stake LODE with or without a lock time to earn rewards
     * @param amount the amount the user wishes to stake (denom. in wei)
     * @param lockTime the desired lock time. Must be 10 seconds, 90 days (in seconds) or 180 days (in seconds)
     */
    function stakeLODE(uint256 amount, uint256 lockTime) external whenNotPaused nonReentrant {
        require(amount != 0, "StakingRewards: Invalid stake amount");
        require(
            lockTime == 10 seconds || lockTime == 90 days || lockTime == 180 days,
            "StakingRewards: Invalid lock time"
        );
        uint256 currentLockTime = stakers[msg.sender].lockTime;
        uint256 startTime = stakers[msg.sender].startTime;
        uint256 cutoffTime = startTime + ((currentLockTime * 80) / 100);

        if (currentLockTime != 0) {
            require(lockTime == currentLockTime, "StakingRewards: Cannot add stake with different lock time");
        }

        if (currentLockTime != 10 seconds && currentLockTime != 0) {
            require(block.timestamp < cutoffTime, "StakingRewards: Staking period expired");
        }

        stakeLODEInternal(amount, lockTime);
    }

    function stakeLODEInternal(uint256 amount, uint256 lockTime) internal {
        require(LODE.transferFrom(msg.sender, address(this), amount), "StakingRewards: Transfer failed");

        uint256 mintAmount = amount;
        uint256 relockAdjustment;
        uint256 threeMonthProduct;
        uint256 sixMonthProduct;
        uint256 preDivisionValue;
        uint256 threeMonthCount = stakers[msg.sender].threeMonthRelockCount;
        uint256 sixMonthCount = stakers[msg.sender].sixMonthRelockCount;

        if (lockTime == 10 seconds) {
            stakers[msg.sender].startTime = block.timestamp;
        }
        if (lockTime == 90 days) {
            mintAmount = FixedPointMathLib.mulDivDown(amount, stLODE3M, FixedPointMathLib.WAD);

            threeMonthProduct = FixedPointMathLib.mulDivDown(threeMonthCount, relockStLODE3M, FixedPointMathLib.WAD);
            sixMonthProduct = FixedPointMathLib.mulDivDown(sixMonthCount, relockStLODE6M, FixedPointMathLib.WAD);
            preDivisionValue = FixedPointMathLib.mulDivDown(
                amount,
                (threeMonthProduct + sixMonthProduct),
                FixedPointMathLib.WAD
            );
            relockAdjustment = FixedPointMathLib.mulDivDown(preDivisionValue, FixedPointMathLib.WAD, BASE);

            mintAmount += relockAdjustment;
            stakers[msg.sender].relockStLODEAmount += relockAdjustment;
            totalRelockStLODE += relockAdjustment;
        } else if (lockTime == 180 days) {
            mintAmount = FixedPointMathLib.mulDivDown(amount, stLODE6M, FixedPointMathLib.WAD);

            threeMonthProduct = FixedPointMathLib.mulDivDown(threeMonthCount, relockStLODE3M, FixedPointMathLib.WAD);
            sixMonthProduct = FixedPointMathLib.mulDivDown(sixMonthCount, relockStLODE6M, FixedPointMathLib.WAD);
            preDivisionValue = FixedPointMathLib.mulDivDown(
                amount,
                (threeMonthProduct + sixMonthProduct),
                FixedPointMathLib.WAD
            );
            relockAdjustment = FixedPointMathLib.mulDivDown(preDivisionValue, FixedPointMathLib.WAD, BASE);

            mintAmount += relockAdjustment;
            stakers[msg.sender].relockStLODEAmount += relockAdjustment;
            totalRelockStLODE += relockAdjustment; // Scale the mint amount for 6 months lock time
        }

        if (stakers[msg.sender].lodeAmount == 0) {
            stakers[msg.sender].startTime = block.timestamp;
            stakers[msg.sender].lockTime = lockTime;
        }

        stakers[msg.sender].lodeAmount += amount; // Update LODE staked amount
        stakers[msg.sender].stLODEAmount += mintAmount; // Update stLODE minted amount
        totalStaked += amount;

        UserInfo storage user = userInfo[msg.sender];

        uint256 _prev = totalSupply();

        updateShares();

        unchecked {
            user.amount += uint96(mintAmount);
            shares += uint96(mintAmount);
        }

        user.wethRewardsDebt =
            user.wethRewardsDebt +
            int128(uint128(_calculateRewardDebt(accWethPerShare, uint96(mintAmount))));

        _mint(address(this), mintAmount);

        unchecked {
            if (_prev + mintAmount != totalSupply()) revert DEPOSIT_ERROR();
        }

        // Adjust voting power
        if (lockTime != 10 seconds) {
            votingContract.mint(msg.sender, mintAmount);
        }

        emit StakedLODE(msg.sender, amount, lockTime);
    }

    /**
     * @notice Stake esLODE tokens to earn rewards
     * @param amount the amount the user wishes to stake (denom. in wei)
     */
    function stakeEsLODE(uint256 amount) external whenNotPaused nonReentrant {
        require(esLODE.balanceOf(msg.sender) >= amount, "StakingRewards: Insufficient balance");
        require(amount > 0, "StakingRewards: Invalid amount");
        EsLODEStake[] memory userStakes = esLODEStakes[msg.sender];
        require(userStakes.length <= 10, "StakingRewards: Max Number of esLODE Stakes reached");
        stakeEsLODEInternal(amount);
    }

    function stakeEsLODEInternal(uint256 amount) internal {
        require(esLODE.transferFrom(msg.sender, address(this), amount), "StakingRewards: Transfer failed");
        stakers[msg.sender].nextStakeId += 1;

        esLODEStakes[msg.sender].push(
            EsLODEStake({baseAmount: amount, amount: amount, startTimestamp: block.timestamp, alreadyConverted: 0})
        );

        stakers[msg.sender].totalEsLODEStakedByUser += amount; // Update total EsLODE staked by user
        stakers[msg.sender].stLODEAmount += amount;

        totalEsLODEStaked += amount;
        totalStaked += amount;

        UserInfo storage user = userInfo[msg.sender];

        uint256 _prev = totalSupply();

        updateShares();

        unchecked {
            user.amount += uint96(amount);
            shares += uint96(amount);
        }

        user.wethRewardsDebt =
            user.wethRewardsDebt +
            int128(uint128(_calculateRewardDebt(accWethPerShare, uint96(amount))));

        _mint(address(this), amount);

        unchecked {
            if (_prev + amount != totalSupply()) revert DEPOSIT_ERROR();
        }

        //Adjust voting power
        votingContract.mint(msg.sender, amount);

        emit StakedEsLODE(msg.sender, amount);
    }

    /**
     * @notice Unstake LODE
     * @param amount The amount the user wishes to unstake
     */
    function unstakeLODE(uint256 amount) external nonReentrant {
        require(stakers[msg.sender].lodeAmount >= amount && amount != 0, "StakingRewards: Invalid unstake amount");
        require(
            stakers[msg.sender].startTime + stakers[msg.sender].lockTime <= block.timestamp,
            "StakingRewards: Tokens are still locked"
        );
        unstakeLODEInternal(amount);
    }

    function unstakeLODEInternal(uint256 amount) internal {
        updateShares();
        uint256 convertedAmount = _harvest();
        uint256 totalUnstake = amount + convertedAmount;

        uint256 stakedBalance = stakers[msg.sender].lodeAmount;
        uint256 stLODEBalance = stakers[msg.sender].stLODEAmount;
        uint256 relockStLODEBalance = stakers[msg.sender].relockStLODEAmount;
        uint256 esLODEBalance = stakers[msg.sender].totalEsLODEStakedByUser;
        uint256 stLODEReduction;
        uint256 lockTimePriorToUpdate = stakers[msg.sender].lockTime;

        stakers[msg.sender].stLODEAmount -= relockStLODEBalance;
        totalRelockStLODE -= relockStLODEBalance;

        //if user is withdrawing their entire staked balance, otherwise calculate appropriate stLODE reduction
        //and reset user's staking info such that their remaining balance is seen as being unlocked now
        if (totalUnstake == stakedBalance && esLODEBalance == 0) {
            //if user is unstaking entire balance and has no esLODE staked
            stakers[msg.sender].lockTime = 0;
            stakers[msg.sender].startTime = 0;
            stLODEReduction = stLODEBalance;
            stakers[msg.sender].stLODEAmount = 0;
            stakers[msg.sender].threeMonthRelockCount = 0;
            stakers[msg.sender].sixMonthRelockCount = 0;
            stakers[msg.sender].relockStLODEAmount = 0;
        } else {
            uint256 newStakedBalance = stakedBalance - totalUnstake;
            uint256 newStLODEBalance = newStakedBalance + esLODEBalance;
            stLODEReduction = stLODEBalance - newStLODEBalance;
            require(stLODEReduction <= stLODEBalance, "StakingRewards: Invalid unstake amount");
            stakers[msg.sender].stLODEAmount = newStLODEBalance;
            stakers[msg.sender].lockTime = 10 seconds;
            stakers[msg.sender].startTime = block.timestamp;
            stakers[msg.sender].threeMonthRelockCount = 0;
            stakers[msg.sender].sixMonthRelockCount = 0;
            stakers[msg.sender].relockStLODEAmount = 0;
        }

        stakers[msg.sender].lodeAmount -= totalUnstake;
        totalStaked -= totalUnstake;

        UserInfo storage user = userInfo[msg.sender];

        uint256 rewardsAdjustment;
        if (user.amount < stLODEReduction && stakers[msg.sender].totalEsLODEStakedByUser == 0) {
            rewardsAdjustment = user.amount;
        } else if (user.amount < stLODEReduction && stakers[msg.sender].totalEsLODEStakedByUser != 0) {
            rewardsAdjustment = user.amount - stakers[msg.sender].totalEsLODEStakedByUser;
        } else {
            rewardsAdjustment = stLODEReduction;
        }
        if (user.amount < rewardsAdjustment || rewardsAdjustment == 0) revert WITHDRAW_ERROR();

        unchecked {
            user.amount -= uint96(rewardsAdjustment);
            shares -= uint96(rewardsAdjustment);
        }

        user.wethRewardsDebt =
            user.wethRewardsDebt -
            int128(uint128(_calculateRewardDebt(accWethPerShare, uint96(rewardsAdjustment))));

        _burn(address(this), rewardsAdjustment);

        //Adjust voting power
        //normalize to total esLODE staked if user has any, otherwise burn to 0
        uint256 currentVotingPower = votingContract.getRawVotingPower(msg.sender);
        if (
            (lockTimePriorToUpdate != 0 && currentVotingPower != 0) ||
            (lockTimePriorToUpdate != 10 seconds && currentVotingPower != 0)
        ) {
            if (stakers[msg.sender].totalEsLODEStakedByUser != 0 && currentVotingPower != 0) {
                if (currentVotingPower > stakers[msg.sender].totalEsLODEStakedByUser) {
                    uint256 burnAmount = currentVotingPower - stakers[msg.sender].totalEsLODEStakedByUser;
                    votingContract.burn(msg.sender, burnAmount);
                } else {
                    //this shouldn't ever happen, but allow for it just in case
                    uint256 mintAmount = stakers[msg.sender].totalEsLODEStakedByUser - currentVotingPower;
                    if (mintAmount != 0) {
                        votingContract.mint(msg.sender, mintAmount);
                    }
                }
            } else if (stakers[msg.sender].totalEsLODEStakedByUser == 0 && currentVotingPower != 0) {
                votingContract.burn(msg.sender, currentVotingPower);
            }
        }

        LODE.transfer(msg.sender, totalUnstake);

        emit UnstakedLODE(msg.sender, totalUnstake);
    }

    /**
     * @notice Converts vested esLODE to LODE and updates user reward shares accordingly accounting for current lock time and relocks
     */
    function convertEsLODEToLODE() public returns (uint256) {
        //since this is also called on unstake and harvesting, we exit out of this function if user has no esLODE staked.
        if (stakers[msg.sender].totalEsLODEStakedByUser == 0) {
            return 0;
        }

        uint256 lockTime = stakers[msg.sender].lockTime;
        uint256 threeMonthCount = stakers[msg.sender].threeMonthRelockCount;
        uint256 sixMonthCount = stakers[msg.sender].sixMonthRelockCount;
        uint256 totalDays = 365 days;
        uint256 amountToTransfer;
        uint256 stLODEAdjustment;
        uint256 conversionAmount;
        uint256 innerOperation;
        uint256 result;

        EsLODEStake[] memory userStakes = esLODEStakes[msg.sender];

        for (uint256 i = 0; i < userStakes.length; i++) {
            uint256 timeDiff = (block.timestamp - userStakes[i].startTimestamp);
            uint256 alreadyConverted = userStakes[i].alreadyConverted;

            if (timeDiff >= totalDays) {
                conversionAmount = userStakes[i].amount;
                amountToTransfer += conversionAmount;
                esLODEStakes[msg.sender][i].alreadyConverted += conversionAmount;
                esLODEStakes[msg.sender][i].amount = 0;

                if (lockTime == 90 days) {
                    innerOperation =
                        (stLODE3M - 1e18) +
                        FixedPointMathLib.mulDivDown(threeMonthCount, relockStLODE3M, FixedPointMathLib.WAD) +
                        FixedPointMathLib.mulDivDown(sixMonthCount, relockStLODE6M, FixedPointMathLib.WAD);

                    result = FixedPointMathLib.mulDivDown(conversionAmount, innerOperation, BASE);
                    stLODEAdjustment += result;
                } else if (lockTime == 180 days) {
                    innerOperation =
                        (stLODE6M - 1e18) +
                        FixedPointMathLib.mulDivDown(threeMonthCount, relockStLODE3M, FixedPointMathLib.WAD) +
                        FixedPointMathLib.mulDivDown(sixMonthCount, relockStLODE6M, FixedPointMathLib.WAD);

                    stLODEAdjustment += FixedPointMathLib.mulDivDown(conversionAmount, innerOperation, BASE);
                }
            } else if (timeDiff < totalDays) {
                uint256 conversionRatioMantissa = FixedPointMathLib.mulDivDown(timeDiff, BASE, totalDays);
                conversionAmount = (FixedPointMathLib.mulDivDown(
                    userStakes[i].baseAmount,
                    conversionRatioMantissa,
                    BASE
                ) - alreadyConverted);
                amountToTransfer += conversionAmount;
                esLODEStakes[msg.sender][i].alreadyConverted += conversionAmount;
                esLODEStakes[msg.sender][i].amount -= conversionAmount;

                if (lockTime == 90 days) {
                    innerOperation =
                        (stLODE3M - 1e18) +
                        FixedPointMathLib.mulDivDown(threeMonthCount, relockStLODE3M, FixedPointMathLib.WAD) +
                        FixedPointMathLib.mulDivDown(sixMonthCount, relockStLODE6M, FixedPointMathLib.WAD);

                    stLODEAdjustment += FixedPointMathLib.mulDivDown(conversionAmount, innerOperation, BASE);
                } else if (lockTime == 180 days) {
                    innerOperation =
                        (stLODE6M - 1e18) +
                        FixedPointMathLib.mulDivDown(threeMonthCount, relockStLODE3M, FixedPointMathLib.WAD) +
                        FixedPointMathLib.mulDivDown(sixMonthCount, relockStLODE6M, FixedPointMathLib.WAD);

                    stLODEAdjustment += FixedPointMathLib.mulDivDown(conversionAmount, innerOperation, BASE);
                }
            }
        }

        //if the user has never staked LODE we need to update their state accordingly prior to any further actions
        if (stakers[msg.sender].lodeAmount == 0 && stakers[msg.sender].lockTime == 0) {
            stakers[msg.sender].lockTime = 10 seconds;
            stakers[msg.sender].startTime = block.timestamp;
        }

        stakers[msg.sender].lodeAmount += amountToTransfer;
        stakers[msg.sender].totalEsLODEStakedByUser -= amountToTransfer;

        totalEsLODEStaked -= amountToTransfer;

        if (stLODEAdjustment != 0) {
            stakers[msg.sender].stLODEAmount += stLODEAdjustment;
            UserInfo storage userRewards = userInfo[msg.sender];

            uint256 _prev = totalSupply();

            updateShares();

            unchecked {
                userRewards.amount += uint96(stLODEAdjustment);
                shares += uint96(stLODEAdjustment);
            }

            userRewards.wethRewardsDebt =
                userRewards.wethRewardsDebt +
                int128(uint128(_calculateRewardDebt(accWethPerShare, uint96(stLODEAdjustment))));

            _mint(address(this), stLODEAdjustment);

            unchecked {
                if (_prev + stLODEAdjustment != totalSupply()) revert DEPOSIT_ERROR();
            }
        }

        //Adjust voting power if user is locking LODE
        if (stakers[msg.sender].lockTime == 10 seconds || stakers[msg.sender].lockTime == 0) {
            //if user is unlocked, we need to burn their converted amount of voting power
            votingContract.burn(msg.sender, conversionAmount);
        } else {
            uint256 currentVotingPower = votingContract.getRawVotingPower(msg.sender);
            if (stakers[msg.sender].stLODEAmount > currentVotingPower) {
                uint256 votingAdjustment = stakers[msg.sender].stLODEAmount - currentVotingPower;
                votingContract.mint(msg.sender, votingAdjustment);
            } else if (stakers[msg.sender].stLODEAmount < currentVotingPower) {
                uint256 votingAdjustment = currentVotingPower - stakers[msg.sender].stLODEAmount;
                votingContract.burn(msg.sender, votingAdjustment);
            }
        }

        esLODE.transfer(address(0), amountToTransfer);

        emit esLODEConverted(msg.sender, conversionAmount);

        return conversionAmount;
    }

    /**
     * @notice Withdraw esLODE in an emergency without converting or claiming rewards
     * @dev can only be called by the end user as part of an emergency withdrawal when locks are lifted
     */
    function withdrawEsLODE() internal {
        require(locksLifted, "StakingRewards: esLODE Withdrawals Not Permitted");

        StakingInfo storage account = stakers[msg.sender];

        uint256 totalEsLODE = account.totalEsLODEStakedByUser;
        totalStaked -= totalEsLODE;
        totalEsLODEStaked -= totalEsLODE;
        stakers[msg.sender].totalEsLODEStakedByUser = 0;
        stakers[msg.sender].stLODEAmount -= totalEsLODE;

        require(
            esLODE.balanceOf(address(this)) >= totalEsLODE,
            "StakingRewards: WithdrawEsLODE: Withdraw amount exceeds contract balance"
        );

        uint256 rewardsAdjustment = totalEsLODE;

        UserInfo storage user = userInfo[msg.sender];
        if (user.amount < rewardsAdjustment || rewardsAdjustment == 0) revert WITHDRAW_ERROR();

        unchecked {
            user.amount -= uint96(rewardsAdjustment);
            shares -= uint96(rewardsAdjustment);
        }

        user.wethRewardsDebt =
            user.wethRewardsDebt -
            int128(uint128(_calculateRewardDebt(accWethPerShare, uint96(rewardsAdjustment))));

        _burn(address(this), totalEsLODE);

        //Adjust voting power
        votingContract.burn(msg.sender, totalEsLODE);

        esLODE.safeTransfer(msg.sender, totalEsLODE);
        emit UnstakedEsLODE(msg.sender, totalEsLODE);
    }

    /**
     * @notice Withdraw staked esLODE (if applicable) and LODE in an emergency without claiming rewards or converting
     * @dev can only be called by the end user when the locks are lifted
     */
    function emergencyStakerWithdrawal() external nonReentrant {
        require(locksLifted, "StakingRewards: Locks not lifted");
        updateShares();

        if (stakers[msg.sender].totalEsLODEStakedByUser != 0) {
            withdrawEsLODE();
        }

        if (stakers[msg.sender].lodeAmount == 0) {
            return;
        }

        StakingInfo storage info = stakers[msg.sender];
        UserInfo storage user = userInfo[msg.sender];

        uint256 transferAmount = info.lodeAmount;
        uint256 burnAmount = info.stLODEAmount;
        uint256 relockStLODE = info.relockStLODEAmount;

        require(
            LODE.balanceOf(address(this)) >= transferAmount,
            "StakingRewards: Transfer amount exceeds contract balance."
        );

        //update staking state
        stakers[msg.sender].lodeAmount = 0;
        stakers[msg.sender].stLODEAmount = 0;
        stakers[msg.sender].startTime = 0;
        stakers[msg.sender].lockTime = 0;
        stakers[msg.sender].relockStLODEAmount = 0;
        stakers[msg.sender].threeMonthRelockCount = 0;
        stakers[msg.sender].sixMonthRelockCount = 0;

        totalStaked -= transferAmount;
        totalRelockStLODE -= relockStLODE;

        //update rewards state
        //user should have no esLODE staked at this point so we clear out the user's rewards here
        uint256 rewardsAdjustment = user.amount;

        if (user.amount < rewardsAdjustment || rewardsAdjustment == 0) revert WITHDRAW_ERROR();

        unchecked {
            user.amount -= uint96(rewardsAdjustment);
            shares -= uint96(rewardsAdjustment);
        }

        user.wethRewardsDebt =
            user.wethRewardsDebt -
            int128(uint128(_calculateRewardDebt(accWethPerShare, uint96(rewardsAdjustment))));

        //update stLODE
        _burn(address(this), burnAmount);

        //update voting state, should have no esLODE staked here so we burn any remaining voting power
        uint256 currentVotingPower = votingContract.getRawVotingPower(msg.sender);
        votingContract.burn(msg.sender, currentVotingPower);

        //transfer user's staked LODE balance to them
        LODE.transfer(msg.sender, transferAmount);

        emit UnstakedLODE(msg.sender, transferAmount);
    }

    /**
     * @notice Relock tokens for boosted rewards
     * @param lockTime the lock time to relock the staked position for, same input options as staking function
     */
    function relock(uint256 lockTime) external whenNotPaused nonReentrant {
        require(lockTime == 90 days || lockTime == 180 days, "StakingRewards: Invalid lock time");

        //make sure user state is fresh
        convertEsLODEToLODE();
        updateShares();

        StakingInfo storage info = stakers[msg.sender];

        require(info.lockTime != 10 seconds, "StakingRewards: Cannot relock if unlocked");

        //remove current relock stLODE from total (to be re-adjusted below)
        uint256 currentRelockStLODE = info.relockStLODEAmount;
        totalRelockStLODE -= currentRelockStLODE;

        //sanity checks
        require(info.lodeAmount > 0, "StakingRewards: No stake found");
        require(
            info.startTime + FixedPointMathLib.mulDivDown(info.lockTime, 80, 100) <= block.timestamp,
            "StakingRewards: Lock time not expired"
        );

        uint256 relockStLODEAmount;
        uint256 stLODEAdjustment;
        uint256 rewardsAdjustment;
        uint256 totalEsLODEStakedByUser = info.totalEsLODEStakedByUser;

        //we need to account for changes in lock time to make sure the user is receiving the correct boost
        if (info.lockTime != lockTime) {
            //this means the user must currently be locked for 3 months and is increasing to 6 months.
            //this means their boost on their staked LODE balance increases from 140% to 200%
            if (lockTime == 180 days) {
                //calculate new relock information and stLODE balances
                stakers[msg.sender].sixMonthRelockCount += 1;
                uint256 threeMonthCount = stakers[msg.sender].threeMonthRelockCount;
                uint256 sixMonthCount = stakers[msg.sender].sixMonthRelockCount;

                uint256 relockMultiplier = 1e18 +
                    FixedPointMathLib.mulDivDown(threeMonthCount, relockStLODE3M, 1) +
                    FixedPointMathLib.mulDivDown(sixMonthCount, relockStLODE6M, 1);
                relockStLODEAmount =
                    FixedPointMathLib.mulDivDown(info.lodeAmount, relockMultiplier, BASE) -
                    info.lodeAmount;
                uint256 newStLODEBalance = FixedPointMathLib.mulDivDown(info.lodeAmount, stLODE6M, 1e18);
                newStLODEBalance += relockStLODEAmount + stakers[msg.sender].totalEsLODEStakedByUser;
                stLODEAdjustment = newStLODEBalance - info.stLODEAmount;

                //update user's state

                stakers[msg.sender].lockTime = lockTime;
                stakers[msg.sender].startTime = block.timestamp;
                stakers[msg.sender].stLODEAmount = newStLODEBalance;
                stakers[msg.sender].relockStLODEAmount = relockStLODEAmount;
                totalRelockStLODE += relockStLODEAmount;

                UserInfo storage user = userInfo[msg.sender];

                rewardsAdjustment = stakers[msg.sender].stLODEAmount - user.amount;

                uint256 _prev = totalSupply();

                unchecked {
                    user.amount += uint96(rewardsAdjustment);
                    shares += uint96(rewardsAdjustment);
                }

                user.wethRewardsDebt =
                    user.wethRewardsDebt +
                    int128(uint128(_calculateRewardDebt(accWethPerShare, uint96(rewardsAdjustment))));

                _mint(address(this), rewardsAdjustment);

                //Adjust voting power
                uint256 currentVotingPower = votingContract.getRawVotingPower(msg.sender);
                votingContract.burn(msg.sender, currentVotingPower);
                votingContract.mint(msg.sender, stakers[msg.sender].stLODEAmount);

                unchecked {
                    if (_prev + rewardsAdjustment != totalSupply()) revert DEPOSIT_ERROR();
                }
            } else {
                //the lock time must be going from 6 months to 3 months,
                //which means we need to decrease their boost to 140% from 200%
                //calculate new relock multiplier and stLODE balances
                stakers[msg.sender].threeMonthRelockCount += 1;
                uint256 threeMonthCount = stakers[msg.sender].threeMonthRelockCount;
                uint256 sixMonthCount = stakers[msg.sender].sixMonthRelockCount;
                uint256 relockMultiplier = 1e18 +
                    FixedPointMathLib.mulDivDown(threeMonthCount, relockStLODE3M, 1) +
                    FixedPointMathLib.mulDivDown(sixMonthCount, relockStLODE6M, 1);
                relockStLODEAmount =
                    FixedPointMathLib.mulDivDown(info.lodeAmount, relockMultiplier, BASE) -
                    info.lodeAmount;
                uint256 newStLODEBalance = FixedPointMathLib.mulDivDown(info.lodeAmount, stLODE3M, 1e18);
                newStLODEBalance += relockStLODEAmount + stakers[msg.sender].totalEsLODEStakedByUser;
                stLODEAdjustment = info.stLODEAmount - newStLODEBalance;

                //update user's state
                stakers[msg.sender].lockTime = lockTime;
                stakers[msg.sender].startTime = block.timestamp;
                stakers[msg.sender].stLODEAmount = newStLODEBalance;
                stakers[msg.sender].relockStLODEAmount = relockStLODEAmount;
                totalRelockStLODE += relockStLODEAmount;

                UserInfo storage user = userInfo[msg.sender];

                rewardsAdjustment = user.amount - stakers[msg.sender].stLODEAmount;

                if (user.amount < rewardsAdjustment || rewardsAdjustment == 0) revert WITHDRAW_ERROR();

                unchecked {
                    user.amount -= uint96(rewardsAdjustment);
                    shares -= uint96(rewardsAdjustment);
                }

                user.wethRewardsDebt =
                    user.wethRewardsDebt -
                    int128(uint128(_calculateRewardDebt(accWethPerShare, uint96(rewardsAdjustment))));

                //Adjust voting power
                uint256 currentVotingPower = votingContract.getRawVotingPower(msg.sender);
                votingContract.burn(msg.sender, currentVotingPower);
                votingContract.mint(msg.sender, stakers[msg.sender].stLODEAmount);

                _burn(address(this), rewardsAdjustment);
            }
        } else {
            //if lock time is the same as previous lock, we do similar calculations
            if (lockTime == 180 days) {
                //calculate new relock multiplier and stLODE balances
                //we only need to add the new relock stLODE to state and rewards as base stLODE stays the same
                stakers[msg.sender].sixMonthRelockCount += 1;
                uint256 threeMonthCount = stakers[msg.sender].threeMonthRelockCount;
                uint256 sixMonthCount = stakers[msg.sender].sixMonthRelockCount;
                uint256 innerCalculation = 1e18 +
                    FixedPointMathLib.mulDivDown(threeMonthCount, relockStLODE3M, 1) +
                    FixedPointMathLib.mulDivDown(sixMonthCount, relockStLODE6M, 1);
                relockStLODEAmount =
                    FixedPointMathLib.mulDivDown(info.lodeAmount, innerCalculation, BASE) -
                    info.lodeAmount;
                uint256 newStLODEBalance = FixedPointMathLib.mulDivDown(info.lodeAmount, stLODE6M, 1e18);
                newStLODEBalance += relockStLODEAmount;

                //update user's state
                stakers[msg.sender].lockTime = lockTime;
                stakers[msg.sender].startTime = block.timestamp;
                stakers[msg.sender].stLODEAmount = newStLODEBalance + totalEsLODEStakedByUser;
                stakers[msg.sender].relockStLODEAmount = relockStLODEAmount;
                totalRelockStLODE += relockStLODEAmount;

                UserInfo storage user = userInfo[msg.sender];

                rewardsAdjustment = stakers[msg.sender].stLODEAmount - user.amount;

                uint256 _prev = totalSupply();

                unchecked {
                    user.amount += uint96(rewardsAdjustment);
                    shares += uint96(rewardsAdjustment);
                }

                user.wethRewardsDebt =
                    user.wethRewardsDebt +
                    int128(uint128(_calculateRewardDebt(accWethPerShare, uint96(rewardsAdjustment))));

                //Adjust voting power
                uint256 currentVotingPower = votingContract.getRawVotingPower(msg.sender);
                votingContract.burn(msg.sender, currentVotingPower);
                votingContract.mint(msg.sender, stakers[msg.sender].stLODEAmount);

                _mint(address(this), rewardsAdjustment);

                unchecked {
                    if (_prev + rewardsAdjustment != totalSupply()) revert DEPOSIT_ERROR();
                }
            } else {
                //calculate new relock multiplier and stLODE balances
                //we only need to add the new relock stLODE to state and rewards as base stLODE stays the same
                stakers[msg.sender].threeMonthRelockCount += 1;
                uint256 threeMonthCount = stakers[msg.sender].threeMonthRelockCount;
                uint256 sixMonthCount = stakers[msg.sender].sixMonthRelockCount;
                uint256 innerCalculation = 1e18 +
                    FixedPointMathLib.mulDivDown(threeMonthCount, relockStLODE3M, 1) +
                    FixedPointMathLib.mulDivDown(sixMonthCount, relockStLODE6M, 1);
                relockStLODEAmount =
                    FixedPointMathLib.mulDivDown(info.lodeAmount, innerCalculation, BASE) -
                    info.lodeAmount;
                uint256 newStLODEBalance = FixedPointMathLib.mulDivDown(info.lodeAmount, stLODE3M, 1e18);
                newStLODEBalance += relockStLODEAmount;

                //update user's state
                stakers[msg.sender].lockTime = lockTime;
                stakers[msg.sender].startTime = block.timestamp;
                stakers[msg.sender].stLODEAmount = newStLODEBalance + totalEsLODEStakedByUser;
                stakers[msg.sender].relockStLODEAmount = relockStLODEAmount;
                totalRelockStLODE += relockStLODEAmount;

                UserInfo storage user = userInfo[msg.sender];

                rewardsAdjustment = stakers[msg.sender].stLODEAmount - user.amount;

                uint256 _prev = totalSupply();

                unchecked {
                    user.amount += uint96(rewardsAdjustment);
                    shares += uint96(rewardsAdjustment);
                }

                user.wethRewardsDebt =
                    user.wethRewardsDebt +
                    int128(uint128(_calculateRewardDebt(accWethPerShare, uint96(rewardsAdjustment))));

                //Adjust voting power
                uint256 currentVotingPower = votingContract.getRawVotingPower(msg.sender);
                votingContract.burn(msg.sender, currentVotingPower);
                votingContract.mint(msg.sender, stakers[msg.sender].stLODEAmount);

                _mint(address(this), rewardsAdjustment);

                unchecked {
                    if (_prev + rewardsAdjustment != totalSupply()) revert DEPOSIT_ERROR();
                }
            }
        }
        emit Relocked(msg.sender, lockTime);
    }

    /**
     * @notice Update the staking rewards information to be current
     * @dev Called before all reward state changing functions
     */
    function updateShares() public {
        // if block.timestamp <= lastRewardSecond, already updated.
        if (block.timestamp <= lastRewardSecond) {
            return;
        }

        // if pool has no supply
        if (shares == 0) {
            lastRewardSecond = uint32(block.timestamp);
            return;
        }

        unchecked {
            accWethPerShare += rewardPerShare(wethPerSecond);
        }

        lastRewardSecond = uint32(block.timestamp);
    }

    /**
     * @notice Function for a user to claim their pending rewards
     * @dev Reverts on transfer failure via SafeERC20
     */
    function claimRewards() external nonReentrant {
        uint256 stakedLODE = stakers[msg.sender].lodeAmount;
        uint256 stakedEsLODE = stakers[msg.sender].totalEsLODEStakedByUser;
        if (stakedLODE == 0 && stakedEsLODE == 0) {
            revert("StakingRewards: No staked balance");
        }
        _harvest();
    }

    function _harvest() private returns (uint256) {
        updateShares();
        uint256 convertedAmount = convertEsLODEToLODE();
        UserInfo storage user = userInfo[msg.sender];

        uint256 wethPending = _calculatePending(user.wethRewardsDebt, accWethPerShare, user.amount);

        user.wethRewardsDebt = int128(uint128(_calculateRewardDebt(accWethPerShare, user.amount)));

        WETH.safeTransfer(msg.sender, wethPending);

        emit RewardsClaimed(msg.sender, wethPending);

        return convertedAmount;
    }

    /**
     * @notice Function to calculate a user's rewards per share
     * @param _rewardRatePerSecond The current reward rate determined by the updateWeeklyRewards function
     */
    function rewardPerShare(uint256 _rewardRatePerSecond) public view returns (uint128) {
        unchecked {
            return
                uint128(
                    FixedPointMathLib.mulDivDown(
                        FixedPointMathLib.mulDivDown((block.timestamp - lastRewardSecond), _rewardRatePerSecond, 1),
                        MUL_CONSTANT,
                        shares
                    )
                );
        }
    }

    /**
     * @notice Function to calculate a user's pending rewards to be ingested by FE
     * @param _user The staker's address
     */
    function pendingRewards(address _user) external view returns (uint256 _pendingweth) {
        uint256 _wethPS = accWethPerShare;

        if (block.timestamp > lastRewardSecond && shares != 0) {
            _wethPS += rewardPerShare(wethPerSecond);
        }

        UserInfo memory user = userInfo[_user];

        _pendingweth = _calculatePending(user.wethRewardsDebt, _wethPS, user.amount);
    }

    function _calculatePending(
        int128 _rewardDebt,
        uint256 _accPerShare, // Stay 256;
        uint96 _amount
    ) internal pure returns (uint128) {
        if (_rewardDebt < 0) {
            return uint128(_calculateRewardDebt(_accPerShare, _amount)) + uint128(-_rewardDebt);
        } else {
            if (int128(uint128(_calculateRewardDebt(_accPerShare, _amount))) < _rewardDebt) {
                return 0;
            }
            return uint128(_calculateRewardDebt(_accPerShare, _amount)) - uint128(_rewardDebt);
        }
    }

    function _calculateRewardDebt(uint256 _accWethPerShare, uint96 _amount) internal pure returns (uint256) {
        unchecked {
            return FixedPointMathLib.mulDivDown(_amount, _accWethPerShare, MUL_CONSTANT);
        }
    }

    function setStartTime(uint32 _startTime) internal {
        lastRewardSecond = _startTime;
    }

    function setEmission(uint256 _wethPerSecond) internal {
        wethPerSecond = _wethPerSecond;
    }

    /**
     * @notice Function to calculate the current WETH/second rewards rate
     * @param rewardsAmount The current weekly rewards amount (denom. in wei)
     */
    function calculateWethPerSecond(uint256 rewardsAmount) public pure returns (uint256 _wethPerSecond) {
        uint256 periodDuration = 7 days;
        _wethPerSecond = rewardsAmount / periodDuration;
    }

    /**
     * @notice Permissioned function to update weekly rewards
     * @param _weeklyRewards The amount of incoming weekly rewards
     * @dev Can only be called by the router contract
     */
    function updateWeeklyRewards(uint256 _weeklyRewards) external {
        require(msg.sender == routerContract, "StakingRewards: Unauthorized");
        updateShares();
        weeklyRewards = _weeklyRewards;
        lastUpdateTimestamp = block.timestamp;
        setStartTime(uint32(block.timestamp));
        uint256 _wethPerSecond = calculateWethPerSecond(_weeklyRewards);
        setEmission(_wethPerSecond);
        emit WeeklyRewardsUpdated(_weeklyRewards);
    }

    /**
     * @notice Function used to return current user's staked LODE amount
     * @param _address The staker's address
     * @return Returns the user's currently staked LODE amount
     */
    function getStLODEAmount(address _address) public view returns (uint256) {
        return stakers[_address].stLODEAmount;
    }

    /**
     * @notice Function used to return curren user's staked LODE lockTime
     * @param _address The staker's address
     * @return Returns the user's currently staked LODE lockTime
     */
    function getStLodeLockTime(address _address) public view returns (uint256) {
        return stakers[_address].lockTime;
    }

    /**
     * @notice Function used to return current user's total esLODE staked
     * @param _address The staker's address
     * @return Returns the user's currently staked LODE lockTime
     */
    function getEsLODEStaked(address _address) public view returns (uint256) {
        return stakers[_address].totalEsLODEStakedByUser;
    }

    /**
     * @notice Function used to return current user's total LODE and esLODE staked (for use by snapshot strategy)
     * @param _address The staker's address
     * @return Returns the user's total staked LODE balance including esLODE
     */
    function getTotalLODEStaked(address _address) public view returns (uint256) {
        uint256 lodeAmount = stakers[_address].lodeAmount;
        uint256 esLODEAmount = stakers[_address].totalEsLODEStakedByUser;
        return lodeAmount + esLODEAmount;
    }

    /* **ADMIN FUNCTIONS** */

    /**
     * @notice Pause function for staking operations
     * @dev Can only be called by contract owner
     */
    function _pauseStaking() external onlyOwner {
        _pause();
        emit StakingPaused();
    }

    /**
     * @notice Unause function for staking operations
     * @dev Can only be called by contract owner
     */
    function _unpauseStaking() external onlyOwner {
        _unpause();
        emit StakingUnpaused();
    }

    /**
     * @notice Admin function to update the router contract
     * @dev Can only be called by contract owner
     */
    function _updateRouterContract(address _routerContract) external onlyOwner {
        require(_routerContract != address(0), "StakingRewards: Invalid Router Contract");
        routerContract = _routerContract;
        emit RouterContractUpdated(_routerContract);
    }

    /**
     * @notice Admin function to update the voting power contract
     * @dev Can only be called by contract owner
     */
    function _updateVotingContract(address _votingContract) external onlyOwner {
        require(_votingContract != address(0), "StakingRewards: Invalid Voting Contract");
        votingContract = IVotingPower(_votingContract);
        emit VotingContractUpdated(address(votingContract));
    }

    /**
     * @notice Admin function to withdraw esLODE backing LODE in an emergency scenario
     * @dev Can only be called by contract owner, and can only withdraw LODE that is not staked by users.
     */
    function _emergencyWithdraw() external onlyOwner {
        uint256 contractLODEBalance = LODE.balanceOf(address(this));
        uint256 LODEDelta = contractLODEBalance - (totalStaked - totalEsLODEStaked);
        LODE.transfer(owner(), LODEDelta);
        emit EmergencyWithdrawal(LODEDelta);
    }

    /**
     * @notice Admin function to allow stakers to unstake their tokens immediately
     * @param state true = locks are lifted. defaults to false (locks are not lifted)
     * @dev Can only be called by contract owner.
     */
    function _liftLocks(bool state) external onlyOwner {
        locksLifted = state;
        emit LocksLifted(locksLifted, block.timestamp);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.18;

import {IERC20Extended, IWETH, IVotingPower} from "../Interfaces/Interfaces.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract StakingConstants {
    struct EsLODEStake {
        uint256 baseAmount;
        uint256 amount;
        uint256 startTimestamp;
        uint256 alreadyConverted;
    }

    struct StakingInfo {
        uint256 lodeAmount;
        uint256 stLODEAmount;
        uint256 startTime;
        uint256 lockTime;
        uint256 relockStLODEAmount;
        uint256 nextStakeId;
        uint256 totalEsLODEStakedByUser;
        uint256 threeMonthRelockCount;
        uint256 sixMonthRelockCount;
    }

    mapping(address => EsLODEStake[]) public esLODEStakes;

    mapping(address => StakingInfo) public stakers;

    IERC20Upgradeable public LODE;
    IERC20Upgradeable public WETH;
    IERC20Upgradeable public esLODE;

    uint256 public weeklyRewards;
    uint256 public lastUpdateTimestamp;

    uint256 public totalStaked;
    uint256 public totalEsLODEStaked;
    uint256 public totalRelockStLODE;

    uint256 public stLODE3M;
    uint256 public stLODE6M;
    uint256 public relockStLODE3M;
    uint256 public relockStLODE6M;

    address public routerContract;
    IVotingPower public votingContract;

    uint256 public constant BASE = 1e18;
    uint256 public constant MUL_CONSTANT = 1e14;

    bool public withdrawEsLODEAllowed;
    bool public locksLifted;

    struct UserInfo {
        uint96 amount; // Staking tokens the user has provided
        int128 wethRewardsDebt;
    }

    uint256 public wethPerSecond;
    uint128 public accWethPerShare;
    uint96 public shares; // total staked,TODO:WAS PRIVATE PRIOR TO TESTING
    uint32 public lastRewardSecond;

    mapping(address => UserInfo) public userInfo;

    error DEPOSIT_ERROR();
    error WITHDRAW_ERROR();
    error UNAUTHORIZED();

    event StakedLODE(address indexed user, uint256 amount, uint256 lockTime);
    event StakedEsLODE(address indexed user, uint256 amount);
    event UnstakedLODE(address indexed user, uint256 amount);
    event UnstakedEsLODE(address indexed user, uint256 amount);
    event esLODEConverted(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 reward);
    event StakingLockedCanceled();
    event WeeklyRewardsUpdated(uint256 newRewards);
    event StakingRatesUpdated(uint256 stLODE3M, uint256 stLODE6M, uint256 vstLODE3M, uint256 vstLODE6M);
    event StakingPaused();
    event StakingUnpaused();
    event RouterContractUpdated(address newRouterContract);
    event VotingContractUpdated(address newVotingContract);
    event esLODEUnlocked(bool state, uint256 timestamp);
    event Relocked(address user, uint256 lockTime);
    event EmergencyWithdrawal(uint256 amount);
    event LocksLifted(bool state, uint256 timestamp);
}

//following initial deployment begin new storage contracts below starting with V1

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}