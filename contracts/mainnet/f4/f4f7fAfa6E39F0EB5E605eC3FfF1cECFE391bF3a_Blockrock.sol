// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/**
SPDX-License-Identifier: Unlicensed
*/
pragma solidity ^0.8.15;


interface ISwapBack {
  function updateTokenFeeBalance(uint256 withHeld) external;
  function addLP(uint256 usdTokenAmount, uint256 mainTokenAmount) external;
  function getMainTokenPrice() external view returns(uint256, uint256, uint256);
  function handleFees() external;
}

interface IMainToken {
    function taxesEnabled() external returns(bool);
    function setSwapEnabled(bool enabled) external;
    function swapEnabled() external view returns(bool);
    function setTaxesEnabled(bool enabled) external;
    function totalSupply() external view returns(uint256);
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;
    function balanceOf(address guy) external view returns(uint256);
    function approve(address guy, uint256 wad) external;
    function safeTransfer(address guy, uint256 wad) external;
    function safeTransferFrom(address from, address to, uint256 amount) external;    
}

interface IDividendDistributor {  
    function deposit() external;
    function addShares(uint256 amount, address tokenOwner) external;
    function removeShares(uint256 amount, address tokenOwner) external;
    function compoundClaim(address shareholder) external returns(uint256);
    function getUnpaidEarnings(address shareholder) external view returns(uint256);
    function getSharesByAddress(address shareHolder)
        external
        view
        returns (uint256);
}

/**
SPDX-License-Identifier: Unlicensed
*/

//  ____  _            _                   _    
// |  _ \| |          | |                 | |  
// | |_) | | ___   ___| | ___ __ ___   ___| | _
// |  _ <| |/ _ \ / __| |/ / '__/ _ \ / __| |/ /
// | |_) | | (_) | (__|   <| | | (_) | (__|   <|
// |____/|_|\___/ \___|_|\_\_|  \___/ \___|_|\_\

//      __    ____  __    __ __    ____        ________            _   __            
//    _/ /   / __ )/ /   / //_/   /  _/____   /_  __/ /_  ___     / | / /__ _      __
//   / __/  / __  / /   / ,<      / // ___/    / / / __ \/ _ \   /  |/ / _ \ | /| / /
//  (_  )  / /_/ / /___/ /| |   _/ /(__  )    / / / / / /  __/  / /|  /  __/ |/ |/ / 
// /  _/  /_____/_____/_/ |_|  /___/____/    /_/ /_/ /_/\___/  /_/ |_/\___/|__/|__/  
// /_/  

//   _ \                             
//  |   |  __| _` | __ \   _` |  _ \ 
//  |   | |   (   | |   | (   |  __/ 
// \___/ _|  \__,_|_|  _|\__, |\___| 
//                       |___/    

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "./BlockrockBTCBDistributor.sol";

import "../interfaces/IToken.sol";


contract Blockrock is ReentrancyGuard, Pausable, Ownable, IERC20 {
  using SafeERC20 for IERC20;
  
  struct InitialParameters {
    string tokenName;
    string tokenSymbol;
    address teamAddress1;
    address teamAddress2;
    address teamAddress3;
    address teamAddress4;
    address router;
    address pairFactory;
    address rewardToken; 
    address treasury;       
  }  

  string private _name;
  string private _symbol;

  IUniswapV2Router02 public router;
  IUniswapV2Pair public pair;
  IUniswapV2Factory public pairFactory;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  ISwapBack private swapper;

  IDividendDistributor public distributor;  
  
  bool private distributorInitialized;
  
  IERC20 immutable public WETH;

  uint256 public maxSupply = 21000000 ether;
  uint256 treasurySupply = 11800000 ether;
  uint256 liquiditySupply = 5000000 ether;
  uint256 teamSupply = 1050000 ether;

  uint256 private _totalSupply;

  // anti-whale protections
  bool private maxWalletLimits = true;
  bool private transactionLimitsEnabled = true;
  uint256 public transactionLimit  = maxSupply / 100;
  uint256 public maxWallet = maxSupply * 25 / 100; // starting at 2.5% of total supply

  // taxes config
  uint256 public DENOMINATOR = 1000;
  uint256 public BUY_TAX = 50;
  uint256 public SELL_TAX = 50;
  bool public taxesEnabled = true;
  
  mapping(address => bool) private blacklist;
  mapping(address => bool) private tradeBlacklist;
  mapping(address => bool) private txLimitExempt;

  mapping(address => bool) private authorizations;

  mapping(address => bool) private dividendExempt;
  mapping(address => bool) private taxExempt;
  mapping(address => bool) private maxWalletExempt;

  bool private buyTaxEnabled = true;
  bool private sellTaxEnabled = true;

  uint256 public swapTimeLock = 10 minutes;
  bool public inSwap = false;
  bool public swapEnabled = true;

  uint256 public lastSwapTime;

  bool public isLaunched = false;

  event SetTXLimit(uint256 amount);
  event SetTXLimitExempt(address guy, bool exempt);
  event SetDividendExempt(address guy, bool exempt);
  event SetMaxWalletExempt(address guy, bool exempt);
  event Blacklisted(address guy, bool blacklisted);
  event SetSwapper(address swapperAddress);
  event SetRouter(address routerAddress);
  event SetPair(address pairAddress);
  event SetDistributor(address distributorAddress);
  event UpdateFees(uint256 _buyTax, uint256 _sellTax, uint256 _denominator);

  constructor(
    InitialParameters memory _initialParameters
    ) {
    require(_initialParameters.router != address(0), "Zero address.");

    _name = _initialParameters.tokenName;
    _symbol = _initialParameters.tokenSymbol;

    authorizations[_msgSender()] = true;

    // configuring router
    router = IUniswapV2Router02(_initialParameters.router);
    // setting router as exempt from fees and dividends
    dividendExempt[address(router)] = true;
    txLimitExempt[address(router)] = true;
    maxWalletExempt[address(router)] = true;
    
    pairFactory = IUniswapV2Factory(_initialParameters.pairFactory);
    
    WETH = IERC20(router.WETH());

    // configuring pair
    pair = IUniswapV2Pair(pairFactory.createPair(address(this), address(WETH)));
    // setting pair as exempt from fees and dividends
    dividendExempt[address(pair)] = true;
    txLimitExempt[address(pair)] = true;
    maxWalletExempt[address(pair)] = true;

    txLimitExempt[_msgSender()] = true;
    taxExempt[_msgSender()] = true;    
    maxWalletExempt[_msgSender()] = true;
    dividendExempt[_msgSender()] = true;
    
    // setting treasury to be dividend exempt
    dividendExempt[_initialParameters.treasury] = true;
    txLimitExempt[_initialParameters.treasury] = true;
    maxWalletExempt[_initialParameters.treasury] = true;

    lastSwapTime = block.timestamp;
    
    // setting up team address identifier to prevent team from selling
    tradeBlacklist[_initialParameters.teamAddress1] = true;
    tradeBlacklist[_initialParameters.teamAddress2] = true;
    tradeBlacklist[_initialParameters.teamAddress3] = true;
    tradeBlacklist[_initialParameters.teamAddress4] = true;

    distributor = new DividendDistributor(address(this), _initialParameters.rewardToken, msg.sender);
    distributorInitialized = true;
    
    // setting up supply
    _mint(msg.sender, liquiditySupply); // going to liquidity

    // team tokens - unsellable, untradeable - team wallets are blocked from sending tokens
    _mint(_initialParameters.teamAddress1, teamSupply);
    _mint(_initialParameters.teamAddress2, teamSupply);
    _mint(_initialParameters.teamAddress3, teamSupply);
    _mint(_initialParameters.teamAddress4, teamSupply);

    // treasury tokens - sent to a multisig wallet
    _mint(_initialParameters.treasury, treasurySupply);

  }

  function distributorAddress() external view returns(address) {
    return address(distributor);
  }  

  function launchProject() external onlyOwner {
    isLaunched = true;
  }

  function transfer(address to, uint256 amount) public virtual returns(bool) {
    address owner = _msgSender();
    _transfer(owner, to, amount);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual returns (bool) {
    address spender = _msgSender();
    _spendAllowance(from, spender, amount);    
    _transfer(from, to, amount);      
    return true;
  }

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

  function _transfer(address from, address to, uint256 amount) internal {
    if (!isLaunched) {
      require(from == owner() || to == owner(), "Not launched.");
    }
    
    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

    _beforeTokenTransfer(from, to, amount);
    
    unchecked {
      _balances[from] = fromBalance - amount;
    }

    if (isLaunched && taxesEnabled && (!taxExempt[to] || !taxExempt[from])) {
      amount = takeFees(from, to, amount);
    }
    
    _balances[to] += amount;

    if (!dividendExempt[from]) { 
      // getting staked shares from trading distributor
      uint256 stakedShares = distributor.getSharesByAddress(from);

      // removing all
      distributor.removeShares(stakedShares, from);

      // adding back from the internal balances mapping      
      distributor.addShares(_balances[from], from);      
    }

    emit Transfer(from, to, amount);

    _afterTokenTransfer(from, to, amount);    
  }

  function takeFees(address from, address to, uint256 amount) internal returns(uint256) {
    uint256 withHeld = 0;
    bool _taxesEnabled = taxesEnabled;

    if (from == address(0)) {
      return amount;
    }

    if (from == address(swapper)) {
      return amount;
    }   

    if (to == address(swapper)) {
      return amount;
    }

    // swap back on sells only
    if (to == address(pair) && shouldSwapBack()) {
      taxesEnabled = false;      
      lastSwapTime = block.timestamp;
      inSwap = true;
      swapper.handleFees();
      inSwap = false;
      taxesEnabled = _taxesEnabled;
    } 

    // if to is pair or router, we have a sell
    if ((to == address(pair) || to == address(router)) && sellTaxEnabled) {
      withHeld = amount * SELL_TAX / DENOMINATOR;
      _balances[address(swapper)] += withHeld;
      emit Transfer(from, address(swapper), withHeld);
      return amount - withHeld;
    }
    // if from is pair or router, we have a buy
    if ((from == address(pair) || from == address(router)) && buyTaxEnabled) {
      withHeld = amount * BUY_TAX / DENOMINATOR;
      _balances[address(swapper)] += withHeld;
      emit Transfer(from, address(swapper), withHeld);

      unchecked { 
        amount = amount - withHeld;
      }
      return amount;
    }
    return amount;
  } 

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual whenNotPaused {
    require(!tradeBlacklist[from], "can not transfer tokens");

    if (from == address(0)) {
      return;
    }    

    if (to == address(swapper) || from == address(swapper)) {
      return;
    }

    if (maxWalletLimits) {
      if (!maxWalletExempt[to] && ((_balances[to] + amount) >= maxWallet)) {    
        revert("Max wallet triggered.");
      }
    }
    
    require(!blacklist[to], "Trying to send to blacklisted address.");
    require(!blacklist[from], "Blacklisted.");

    bool transactionLimitExempt = (txLimitExempt[to] && txLimitExempt[from]);

    if (amount > transactionLimit && transactionLimitsEnabled) {
      if (!transactionLimitExempt) {
        revert("Transaction limit hit.");
      }
    }   
  }

  function setSwapEnabled(bool _enabled) external authorized {
    swapEnabled = _enabled;
  }

  function setSwapBackTimeLockInMinutes(uint256 time) external authorized {
    require(time >= 1, "must be greater than or equal to one minute");
    swapTimeLock = time * 1 minutes;
  }

  function shouldSwapBack() internal view returns (bool) {
    return
        msg.sender != address(pair) &&
        swapEnabled &&
        !inSwap &&
        block.timestamp > lastSwapTime + swapTimeLock;
  }

  function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {
    if (!dividendExempt[to]) {      
      distributor.addShares(amount, to);
    }  
  }

  function addToBlackList(address guy) external onlyOwner {
    require(guy != address(this), "Self");
    blacklist[guy] = true;
    dividendExempt[guy] = true;

    distributor.removeShares(_balances[guy], guy);

    emit Blacklisted(guy, true);
  }

  function removeFromBlacklist(address guy) external onlyOwner {
    blacklist[guy] = false;

    dividendExempt[guy] = false;
    
    distributor.addShares(_balances[guy], guy);

    emit Blacklisted(guy, false);
  }

  function addToTradeBlacklist(address guy) external authorized {
    require(guy != address(this), "Self");
    tradeBlacklist[guy] = true;    
  }

  function removeFromTradeBlacklist(address guy) external authorized {
    tradeBlacklist[guy] = false;
  }

  function isBlacklisted(address guy) public view returns(bool) {
    return blacklist[guy];
  }

  function isTradeBlacklisted(address guy) public view returns(bool) {
    return tradeBlacklist[guy];
  }

  function setTransactionLimit(uint256 size) external onlyOwner {
    require(size >= totalSupply() / 2000, "Transaction limit too small.");
    transactionLimit = size;

    emit SetTXLimit(size);
  }

  function setMaxWallet(uint256 size) external authorized {
    require(size > 0, "Max wallet must be greater than zero.");
    maxWallet = size;
  }

  function setDividendExempt(address guy, bool exempt) external onlyOwner {
    dividendExempt[guy] = exempt;

    emit SetDividendExempt(guy, exempt);
  }

  function isDividendExempt(address guy) external view returns(bool) {
    return dividendExempt[guy];
  }

  function setTransactionLimitExempt(address guy, bool exempt) external onlyOwner {
    txLimitExempt[guy] = exempt;

    emit SetTXLimitExempt(guy, exempt);
  }

  function setMaxWalletExempt(address guy, bool exempt) external onlyOwner {
    maxWalletExempt[guy] = exempt;

    emit SetMaxWalletExempt(guy, exempt);
  }

  function isTXLimitExempt(address guy) external view onlyOwner returns(bool) {
    return txLimitExempt[guy];
  }

  function isMaxWalletExempt(address guy) external view onlyOwner returns(bool) {
    return maxWalletExempt[guy];
  }

  function setSwapper(address swapperAddress) external onlyOwner {
    require(swapperAddress != address(0), "Zero address");
    swapper = ISwapBack(swapperAddress);
    
    dividendExempt[swapperAddress] = true;
    txLimitExempt[swapperAddress] = true;
    maxWalletExempt[swapperAddress] = true;
    authorizations[swapperAddress] = true;
    
    emit SetSwapper(swapperAddress);
  }

  function updateFees(uint256 _buyTax, uint256 _sellTax, uint256 _denominator) external authorized {
    require(_denominator > 0);
    require(_sellTax <= _denominator / 4);
    require(_buyTax <= _denominator / 5);

    BUY_TAX = _buyTax;
    SELL_TAX = _sellTax;
    DENOMINATOR = _denominator;    
  }

  function _setTaxesEnabled(bool enabled) internal {
    taxesEnabled = enabled;
  }

  function setTaxesEnabled(bool enabled) external authorized {
    _setTaxesEnabled(enabled);
  }

  function setBuyTaxEnabled(bool enabled) external authorized {
    buyTaxEnabled = enabled;
  }

  function setSellTaxEnabled(bool enabled) external authorized {
    sellTaxEnabled = enabled;
  }

  function setTaxExempt(address guy, bool exempt) external onlyOwner {
    taxExempt[guy] = exempt;
  }
  
  function setMaxWalletLimitsEnabled(bool _enabled) external authorized {
    maxWalletLimits = _enabled;
  }

  function setTransactionLimitsEnabled(bool _enabled) external authorized {
    transactionLimitsEnabled = _enabled;
  }
  
  function name() public view virtual returns (string memory) {
      return _name;
  }

  /**
    * @dev Returns the symbol of the token, usually a shorter version of the
    * name.
    */
  function symbol() public view virtual returns (string memory) {
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
  function decimals() public view virtual returns (uint8) {
      return 18;
  }

  /**
    * @dev See {IERC20-totalSupply}.
    */
  function totalSupply() public view virtual returns (uint256) {
      return _totalSupply;
  }
  
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");
    
    _totalSupply += amount;
    
    _balances[account] += amount;

    if (!dividendExempt[account] && distributorInitialized) {
      distributor.addShares(amount, account);
    }
    
    emit Transfer(address(0), account, amount);
  }  

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
      address owner = _msgSender();
      _approve(owner, spender, allowance(owner, spender) + addedValue);
      return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
      address owner = _msgSender();
      uint256 currentAllowance = allowance(owner, spender);
      require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
      unchecked {
          _approve(owner, spender, currentAllowance - subtractedValue);
      }

      return true;
  }

  function approve(address spender, uint256 amount) public virtual returns (bool) {
    address owner = _msgSender();
    _approve(owner, spender, amount);
    return true;
  }

  function allowance(address owner, address spender) public view virtual returns (uint256) {
    return _allowances[owner][spender];
  }
 
  /**
    * @dev See {IERC20-balanceOf}.
    */
  function balanceOf(address account) public view virtual returns (uint256) {
      return _balances[account];
  }  

  function setAuthorized(address guy, bool auth) external authorized {
    authorizations[guy] = auth;
  }

  function isAuthorized(address guy) external view returns(bool) {
    return authorizations[guy];
  }

  // Contingencies to prevent loss of funds
  receive() external payable {}

  /**
    * @dev Transfer payment safely between users
    */
  function _safeTransferNative(address to, uint256 value) internal {
      // update to be transfer from
      (bool success, ) = to.call{value: value}("");
      require(success, "TransferHelper: TRANSFER_FAILED");
  }

  /**
    *   @dev in case gas tokens are accidentally sent to contract, they will not be lost
  * */
  function withdrawNative()
      external
      onlyOwner        
  {
      uint256 balance = address(this).balance;
      _safeTransferNative(_msgSender(), balance);
  }

  /**
  *  @dev in case tokens are accidentally sent to contract, they will not be lost
   */
  function withdrawTokens(address tokenAddress) external onlyOwner {
    IERC20 token = IERC20(tokenAddress);
    token.safeTransfer(msg.sender, token.balanceOf(address(this)));
  }

  modifier authorized() {
    require(authorizations[_msgSender()] == true, "!Authorized");
    _;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IToken.sol";


contract DividendDistributor is IDividendDistributor, ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;
    
    IERC20 public SHARE_TOKEN;
    IERC20 public REWARD_TOKEN;

    address private swapper;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalDistributed;
    }

    mapping(address => uint256) public stakerDeposits;
    mapping(address => bool) stakerHasDeposit;
    mapping(address => uint256) public totalRewardsByAddress;
    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor;
    
    mapping(address => bool) private authorizations;

    event Deposit(uint256 amount);
    event EmergencyWithdrawNative(uint256 amount); 
    event EmergencyWithdrawRewardToken(uint256 amount);   
    event SetRewardToken(address rewardToken);  
    event ClaimDividend(address indexed user);
    event SetPaused(bool pause);

    constructor(
      address _SHARE_TOKEN,
      address _REWARD_TOKEN,
      address _owner
    ) {
      require(_SHARE_TOKEN != address(0), "Cannot be 0");
      require(_REWARD_TOKEN != address(0), "Cannot be 0");

      dividendsPerShareAccuracyFactor = 10**18;

      REWARD_TOKEN = IERC20(_REWARD_TOKEN);
      SHARE_TOKEN = IERC20(_SHARE_TOKEN);

      authorizations[_SHARE_TOKEN] = true;
      authorizations[_owner] = true;  
     
    }

    /**
     *   @dev deposit - Reward token is deposited here
     *
     *   deposits of Reward tokens are allocated for rewards distribution
     *
     * */
    function deposit() external authorized {
        uint256 amount = REWARD_TOKEN.balanceOf(_msgSender());
        REWARD_TOKEN.safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );

        totalDividends = totalDividends + amount;

        uint256 total = totalShares > 0 ? totalShares : 1;

        dividendsPerShare =
            dividendsPerShare +
            ((dividendsPerShareAccuracyFactor * amount) / total);

        emit Deposit(amount);
    }

    /**
     * @dev Transfer payment safely between users
     */
    function _safeTransferNative(address to, uint256 value) internal {
        // update to be transfer from
        (bool success, ) = to.call{value: value}("");
        require(success, "TransferHelper: TRANSFER_FAILED");
    }

    /**
     *   @dev emergencyWithdrawRewardToken - only use if necessary
     * */
    function emergencyWithdrawRewardToken()
        external
        onlyOwner
        whenPaused
    {
        uint256 balance = REWARD_TOKEN.balanceOf(address(this));
        REWARD_TOKEN.safeTransfer(_msgSender(), balance);

        emit EmergencyWithdrawRewardToken(balance);
    }

    /**
     *   @dev emergencyWithdrawNative - only use if necessary
     * */
    function emergencyWithdrawNative()
        external
        onlyOwner
        whenPaused
    {
        uint256 balance = address(this).balance;
        _safeTransferNative(_msgSender(), balance);

        emit EmergencyWithdrawNative(balance);
    }

    function withdrawAmount(uint256 amount) external authorized {
        REWARD_TOKEN.safeTransfer(_msgSender(), amount);
    }

    /**
     *   @dev stakeTokens - tokens are transferred to user
     *
     *   @param amount - number of tokens
     *
     */
    function addShares(uint256 amount, address tokenOwner)
        external
        whenNotPaused
        authorized
    {
        stakerDeposits[tokenOwner] += amount;

        if (!stakerHasDeposit[tokenOwner]) {
            stakerHasDeposit[tokenOwner] = true;
        }

        setShare(tokenOwner, stakerDeposits[tokenOwner]);
    }

    /**
     *   @dev removeShares - called when tokens are transferred from an owner
     *
     *   @param amount - number of shares to remove from a particular wallet's allotment
     *
     *   @dev reverts if tokenOwner does not have a tokens
     *   @dev reverts if tokenOwner is trying to move more than is owned
     *
     */
    function removeShares(uint256 amount, address tokenOwner)
        external
        whenNotPaused
        authorized
    {
        if (!stakerHasDeposit[tokenOwner]) {
            return;
        }
        
        uint256 totalStakedByAddress = stakerDeposits[tokenOwner];
        require(
            amount <= totalStakedByAddress,
            "Incorrect math."
        );

        if (totalStakedByAddress > amount) {
            stakerDeposits[tokenOwner] -= amount;
            setShare(tokenOwner, stakerDeposits[tokenOwner]);
        } else {
            stakerDeposits[tokenOwner] = 0;
            stakerHasDeposit[tokenOwner] = false;
            setShare(tokenOwner, 0);
        }
    }

    /**
     *   @dev setShare - internal - sets the amount of tokens a holder currently has staked
     *   used to determining the total weight of an address' staked position for rewards distribution
     *
     * */
    function setShare(address shareholder, uint256 amount) internal {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        totalShares = totalShares - shares[shareholder].amount + amount;

        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(amount);
    }

    function distributeDividend(address shareholder) internal {
        // short circuit
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);

        if (amount > 0 && REWARD_TOKEN.balanceOf(address(this)) >= amount) {
            totalDistributed = totalDistributed + amount;
            
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );

            shares[shareholder].totalDistributed += amount;
            
            REWARD_TOKEN.safeTransfer(shareholder, amount);
                       
        }
    }

    function compoundDistribute(address shareholder) internal returns(uint256) {
        // short circuit
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 amount = getUnpaidEarnings(shareholder);

        if (amount > 0 && REWARD_TOKEN.balanceOf(address(this)) >= amount) {
            totalDistributed = totalDistributed + amount;
            
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );

            shares[shareholder].totalDistributed += amount;
            
            REWARD_TOKEN.safeTransfer(swapper, amount);
                       
        }

        return amount;
    }

    function compoundClaim(address shareholder) external authorized returns(uint256) {
        emit ClaimDividend(shareholder);
        return compoundDistribute(shareholder);
    }    

    function claimDividend() external nonReentrant {
        distributeDividend(_msgSender());        
                 
        emit ClaimDividend(_msgSender());
    }    

    function getCumulativeDividends(uint256 share)
        internal
        view
        returns (uint256)
    {
        return (share * dividendsPerShare) / dividendsPerShareAccuracyFactor;
    }

    /** Public getUnpaidEarnings, used to display on the UI */
    function getUnpaidEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
        // if shareholder has no shares, return 0
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getSharesByAddress(address shareHolder)
        external
        view
        returns (uint256)
    {
        return shares[shareHolder].amount;
    }

    function getShareByAddress(address holder)
        external
        view
        returns(Share memory)
    {
        return shares[holder];    
    }

    function getTotalRewardsByAddress(address shareholder) external view returns(uint256) {
        return shares[shareholder].totalDistributed;
    }

    function pause() onlyOwner external {
      _pause();
    }

    function unPause() onlyOwner external {
      _unpause();
    }

    function setRewardToken(IERC20 rewardToken)
        external
        onlyOwner
        notZeroAddress(address(rewardToken))
    {
        REWARD_TOKEN = rewardToken;

        emit SetRewardToken(address(rewardToken));
    }

    function setShareToken(IERC20 shareToken)
        external
        onlyOwner
        notZeroAddress(address(shareToken))
    {
        SHARE_TOKEN = shareToken;
    }

    function setSwapper(address _swapper) external authorized {
        swapper = _swapper;
        authorizations[_swapper] = true;
    }

    function setAuthorized(address guy, bool auth) external authorized {
      authorizations[guy] = auth;
    }

    function isAuthorized(address guy) external view returns(bool) {
      return authorizations[guy];
    }

    modifier authorized() {
      require(authorizations[_msgSender()] == true, "!Authorized");
      _;
    }

    modifier notZeroAddress(address newAddress) {
        require(
            newAddress != address(0),
            "New address must not be zero address"
        );
        _;
    }
}