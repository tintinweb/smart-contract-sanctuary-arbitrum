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

// SPDX-License-Identifier: None

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IOtoken, IOracle, GammaTypes, IController, IOtokenFactory, IMarginCalculator} from "../interfaces/IGamma.sol";
import "./HedgedPoolStorage.sol";
import "../interfaces/ILpManager.sol";
import "../libs/Math.sol";
import "../libs/Dates.sol";
import "../libs/OpynLib.sol";
import "../interfaces/IOrderUtil.sol";
import "../interfaces/IFeeCollector.sol";
import "../interfaces/CustomErrors.sol";

contract HedgedPool is
    Initializable,
    OwnableUpgradeable,
    ERC20Upgradeable,
    ReentrancyGuardUpgradeable,
    HedgedPoolStorageV1
{
    /// @notice Pool is initialized
    event HedgedPoolInitialized(
        address strikeToken,
        address collateralToken,
        string tokenName,
        string tokenSymbol
    );

    /// @notice All series for a given expiry settled
    event ExpirySettled(uint256 expiryTimestamp);

    struct TradeLeg {
        int256 amount;
        int256 premium;
        uint256 fee;
        address oToken;
    }

    event Trade(
        address referrer,
        uint256 totalPremium,
        uint256 totalFee,
        uint256 totalNotional,
        TradeLeg[] legs
    );

    /// @dev NOTE: No local variables should be added here.  Instead see HedgedPoolStorage.sol

    /// Use safe ERC20 functions for any token transfers since people don't follow the ERC20 standard */
    using SafeERC20 for IERC20;

    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Emitted when hedger address is set
    event HedgerSet(address underlying, address hedger);

    event VaultMarginUpdated(uint256 vaultId, int256 collateralChange);

    event UnderlyingConfigured(
        address _underlying,
        bool _enabled,
        uint256 _minPercent,
        uint256 _maxPercent,
        uint256 _increment
    );

    modifier onlyKeeper() {
        if (!keepers[msg.sender]) {
            revert CustomErrors.Unauthorized();
        }
        _;
    }

    /// Initialize the contract, and create an lpToken to track ownership
    function __HedgedPool_init(
        address _addresBookAddress,
        address _strikeToken,
        address _collateralToken,
        string calldata _tokenName,
        string calldata _tokenSymbol
    ) public initializer {
        addressBook = IAddressBook(_addresBookAddress);

        strikeToken = IERC20(_strikeToken);
        collateralToken = IERC20(_collateralToken);

        // Initizlie ERC20 LP token
        __ERC20_init(_tokenName, _tokenSymbol);
        numDecimals = IERC20MetadataUpgradeable(address(collateralToken))
            .decimals();

        // Set first rounds end date
        lastSettledExpiry = Dates.get8amAligned(block.timestamp, 1 weeks);
        withdrawalRoundEnd = lastSettledExpiry + 1 weeks;
        depositRoundEnd = Dates.get8amAligned(block.timestamp, 1 days) + 1 days;

        __Ownable_init();
        __ReentrancyGuard_init();

        // Set default values
        hedgeReservePercent = 50;
        pricePerShareCached = 1e8;
        seriesPerExpirationLimit = 20;

        _refreshConfigInternal();

        emit HedgedPoolInitialized(
            _strikeToken,
            _collateralToken,
            _tokenName,
            _tokenSymbol
        );
    }

    /// @notice Get total value of the pool shares
    /// @param pricePerShare price per share * 1e8
    function getTotalPoolValue(
        uint256 pricePerShare
    ) public view returns (uint256) {
        return (totalSupply() * pricePerShare) / 1e8;
    }

    /// @notice Get total pool value based on the latest cached share price
    function getTotalPoolValueCached() public view returns (uint256) {
        return getTotalPoolValue(pricePerShareCached);
    }

    /**
     * @notice Close the existing short otoken position. Currently this implementation is simple.
     * It closes the most recent vault opened by the contract. This assumes that the contract will
     * only have a single vault open at any given time. Since calling `_closeShort` deletes vaults by
     calling SettleVault action, this assumption should hold.
     * @return amount of collateral redeemed from the vault
     */
    function settleAll() public returns (uint256) {
        // Save pre-settlement collateral balance
        uint256 startCollateralBalance = collateralToken.balanceOf(
            address(this)
        );

        uint256 expiry = lastSettledExpiry + 1 weeks;

        while (expiry <= block.timestamp) {
            for (uint iu = 0; iu < underlyingTokens.length(); iu++) {
                address underlying = underlyingTokens.at(iu);

                for (
                    uint256 ie;
                    ie < oTokensByExpiry[underlying][expiry].length;
                    ie++
                ) {
                    settleSingle(oTokensByExpiry[underlying][expiry][ie]);
                }
            }

            lastSettledExpiry = expiry;

            emit ExpirySettled(expiry);

            expiry += 1 weeks;
        }

        uint256 endCollateralBalance = collateralToken.balanceOf(address(this));

        processWithdrawals();

        return endCollateralBalance - startCollateralBalance;
    }

    /// @notice settle single series
    function settleSingle(address oToken) public {
        if (!activeOTokens.contains(oToken)) return;

        // check whether we have a long oToken
        uint256 amount = IERC20(oToken).balanceOf(address(this));

        if (amount > 0) {
            // long found, redeem
            OpynLib.redeem(controller, oToken, amount);
        } else {
            // no long, check short
            uint256 vaultId = marginVaults[oToken];
            if (vaultId > 0) {
                OpynLib.settle(controller, vaultId);
            }
        }

        // remove oToken from active series
        activeOTokens.remove(oToken);
    }

    /*****************
    Keeper methods
    ******************/

    /// @notice Close current deposit and withdrawal rounds at specified share price
    /// @param pricePerShare price per share * 1e8
    function closeRound(uint256 pricePerShare) external onlyKeeper {
        // cannot close a round when there's unsettled expiry
        if (lastSettledExpiry + 1 weeks < block.timestamp) {
            revert CustomErrors.NotSettled();
        }

        // TODO: add price per share guardrails

        // advance to the next round if necessary
        int256 sharesDiff;
        // close withdrawal round
        if (withdrawalRoundEnd <= block.timestamp) {
            sharesDiff -= int256(
                ILpManager(lpManager).closeWithdrawalRound(pricePerShare)
            );

            withdrawalRoundEnd += 1 weeks;

            pricePerShareCached = pricePerShare;
        }

        if (depositRoundEnd <= block.timestamp) {
            sharesDiff += int256(
                ILpManager(lpManager).closeDepositRound(pricePerShare)
            );

            depositRoundEnd += 1 days;

            pricePerShareCached = pricePerShare;
        }

        // mint or burn LP tokens
        if (sharesDiff < 0) {
            // burn lp tokens corresponding to filled withdrawal shares
            _burn(address(this), uint256(-sharesDiff));
        } else if (sharesDiff > 0) {
            // mint lp tokens corresponding to new deposits
            _mint(address(this), uint256(sharesDiff));
        }
    }

    /*****************
    LP Manager methods
    ******************/

    /// @dev process pending withdrawals
    function processWithdrawals() internal {
        uint256 freeCollateral = collateralToken.balanceOf(address(this)) -
            ILpManager(lpManager).getCashLocked(address(this), true);

        // exit early if nothing to withdraw
        if (freeCollateral == 0) return;

        uint256 unfilledShares = ILpManager(lpManager).getUnfilledShares(
            address(this)
        );
        // lock amount using the last cached price per share + 10%
        // any excess will be refunded after round close
        uint256 requiredAmount = (unfilledShares * pricePerShareCached * 11) /
            1e9;
        uint256 withdrawAmount = Math.min(requiredAmount, freeCollateral);
        if (withdrawAmount > 0) {
            ILpManager(lpManager).addPendingCash(withdrawAmount);
        }
    }

    /// @notice Redeem shares from processed deposits
    function redeemShares() external nonReentrant {
        _redeemShares(msg.sender);
    }

    function _redeemShares(address lpAddress) private {
        uint256 sharesAmount = ILpManager(lpManager).redeemShares(lpAddress);

        if (sharesAmount > 0) {
            this.transfer(lpAddress, sharesAmount);
        }
    }

    /// @notice Request withdrawal
    function requestWithdrawal(uint256 sharesAmount) external nonReentrant {
        address lpAddress = msg.sender;

        // redeem unredeemed shares first
        _redeemShares(msg.sender);

        if (balanceOf(lpAddress) < sharesAmount) {
            revert CustomErrors.InsufficientBalance();
        }

        ILpManager(lpManager).requestWithdrawal(lpAddress, sharesAmount);

        // Burn the lp tokens
        _burn(msg.sender, sharesAmount);
        // mint LP tokens to self for accounting
        _mint(address(this), sharesAmount);
    }

    /// @notice Withdraw available cash
    function withdrawCash() external nonReentrant {
        (uint256 cashAmount, ) = ILpManager(lpManager).withdrawCash(msg.sender);

        if (cashAmount > 0) {
            IERC20(collateralToken).safeTransfer(msg.sender, cashAmount);
        }
    }

    /// @notice Request deposit
    function requestDeposit(uint256 amount) external nonReentrant {
        if (amount == 0) {
            revert CustomErrors.ZeroValue();
        }

        address lpAddress = msg.sender;

        ILpManager(lpManager).requestDeposit(lpAddress, amount);

        IERC20(collateralToken).safeTransferFrom(
            lpAddress,
            address(this),
            amount
        );
    }

    /// @notice Cancel pending unprocessed deposit
    function cancelPendingDeposit(uint256 amount) external nonReentrant {
        ILpManager(lpManager).cancelPendingDeposit(msg.sender, amount);

        IERC20(collateralToken).safeTransfer(msg.sender, amount);
    }

    /// @notice Available liquidity in the pool (excludes pending deposits and withdrawals)
    function getCollateralBalance() public view override returns (uint256) {
        return
            collateralToken.balanceOf(address(this)) -
            ILpManager(lpManager).getCashLocked(address(this), true);
    }

    /*****************
    ERC20 methods
    ******************/

    function decimals() public view override(ERC20Upgradeable) returns (uint8) {
        return numDecimals;
    }

    /***********************
    Trading methods
    ***********************/

    /// @notice execute a signed buy or sell order
    function trade(IOrderUtil.Order calldata order) public nonReentrant {
        // validate that the order signer has QUOTE_PROVIDER role. The signing contract has to return the recovered signer.
        processOrder(order);

        // For now we allow only one leg
        if (order.legs.length != 1) {
            revert CustomErrors.OrderNotSupported();
        }

        IOrderUtil.OptionLeg memory leg = order.legs[0];

        // credit = trader receives premium, debit = trader pays premium
        bool isCredit = leg.premium < 0;

        // credit(sell) order requires oToken to exist
        address oToken = getOToken(
            order.underlying,
            leg.strike,
            leg.expiration,
            leg.isPut,
            isCredit
        );

        uint256 collateralBefore = getCollateralBalance();

        if (!isCredit) {
            // debit order = buy

            if (leg.amount <= 0) {
                revert CustomErrors.InvalidOrder();
            }

            // transfer premium from buyer into pool
            collateralToken.safeTransferFrom(
                msg.sender,
                address(this),
                uint256(leg.premium) + leg.fee
            );

            // If long oToken exists on the balance we sell it, otherwise create MarginVault if required
            uint256 oTokenBalance = IERC20(oToken).balanceOf(address(this));
            if (oTokenBalance < uint256(leg.amount)) {
                uint256 mintAmount = uint256(leg.amount) - oTokenBalance;
                createShort(
                    order.underlying,
                    mintAmount,
                    oToken,
                    leg.strike,
                    leg.expiration,
                    leg.isPut
                );
            }

            // send oToken to the buyer
            IERC20(oToken).safeTransfer(msg.sender, uint256(leg.amount));
        } else {
            // credit order = sell

            if (leg.amount >= 0) {
                revert CustomErrors.InvalidOrder();
            }

            // transfer oToken into pool
            IERC20(oToken).safeTransferFrom(
                msg.sender,
                address(this),
                uint256(-leg.amount)
            );

            reduceShort(
                order.underlying,
                uint256(-leg.amount),
                oToken,
                leg.strike,
                leg.expiration,
                leg.isPut
            );

            // transfer premium to seller

            collateralToken.safeTransfer(
                msg.sender,
                uint256(-leg.premium) - leg.fee
            );
        }
        // charge fee
        if (leg.fee > 0) {
            IFeeCollector(feeCollector).collectFee(
                address(collateralToken),
                leg.fee,
                order.referrer
            );
        }

        uint256 collateralAfter = getCollateralBalance();

        // check that the trade doesn't consume more liquidity than allowed
        // TODO: reenable this after hedger is implemented
        if (false && collateralAfter < collateralBefore) {
            // get approximate hedging reserve using last share price
            uint256 hedgeReserve = (getTotalPoolValue(pricePerShareCached) *
                hedgeReservePercent) / 100;
            uint256 hedgeMaintenance = IHedger(hedgers[order.underlying])
                .getCollateralValue();
            // available liquidity is free collateral balance minus portion reserved for hedging
            uint256 liquidityAvailable = collateralBefore +
                hedgeMaintenance -
                hedgeReserve;
            uint256 liquidityConsumed = collateralBefore - collateralAfter;
            if (liquidityAvailable < liquidityConsumed) {
                revert CustomErrors.NotEnoughLiquidity(
                    liquidityAvailable,
                    liquidityConsumed
                );
            }
        }

        TradeLeg[] memory tradeLegs = new TradeLeg[](1);
        tradeLegs[0] = TradeLeg({
            oToken: oToken,
            amount: leg.amount,
            premium: leg.premium,
            fee: leg.fee
        });

        emit Trade(
            order.referrer,
            Math.abs(leg.premium),
            leg.fee,
            Math.abs(leg.amount),
            tradeLegs
        );
    }

    /// @notice Process a pool order
    /// @param order is the id of the vault to be settled
    function processOrder(IOrderUtil.Order calldata order) internal {
        if (!underlyingTokens.contains(order.underlying)) {
            revert CustomErrors.InvalidUnderlying();
        }

        // Validate each leg
        for (uint i = 0; i < order.legs.length; i++) {
            IOrderUtil.OptionLeg memory leg = order.legs[i];
            if (leg.expiration <= block.timestamp) {
                revert CustomErrors.SeriesExpired();
            }
            if (
                leg.amount == 0 ||
                leg.premium == 0 ||
                (leg.amount > 0 && leg.premium < 0) ||
                (leg.amount < 0 && leg.premium > 0)
            ) {
                revert CustomErrors.InvalidOrder();
            }
        }

        // Check that the pool address
        if (order.poolAddress != address(this)) {
            revert CustomErrors.InvalidPoolAddress();
        }

        // Get order signers
        (address signer, address[] memory coSigners) = IOrderUtil(orderUtil)
            .processOrder(order);

        // TODO: check n-of-m co-signers
        // Check that the signatory has the Role Quote provider
        if (!quoteProviders[signer]) {
            revert CustomErrors.Unauthorized();
        }
    }

    /// @notice Calculate collateral required for an option to be minted

    /// @return collateral amount
    function getMarginRequired(
        address underlying,
        uint256 strike,
        uint256 expiration,
        bool isPut,
        uint256 amount
    ) internal view returns (uint256) {
        uint256 collateralAmount = IMarginCalculator(calculator)
            .getNakedMarginRequired(
                underlying,
                address(strikeToken),
                address(collateralToken),
                amount,
                strike,
                IOracle(oracle).getPrice(underlying),
                expiration,
                numDecimals,
                isPut
            );

        // assumes in collateral decimals
        return collateralAmount;
    }

    /// @notice Creates the actual Opyn short position by depositing collateral and minting otokens
    /// @param oTokenAddress is the address of the otoken to mint
    /// @param amount is the mint amount in 1e18 format
    function createShort(
        address underlying,
        uint256 amount,
        address oTokenAddress,
        uint256 strike,
        uint256 expiration,
        bool isPut
    ) internal {
        uint256 depositAmount = getMarginRequired(
            underlying,
            strike,
            expiration,
            isPut,
            amount
        );

        uint256 collateralBalance = getCollateralBalance();
        if (depositAmount > collateralBalance) {
            revert CustomErrors.NotEnoughCollateral(
                collateralBalance,
                depositAmount
            );
        }

        uint256 vaultId = marginVaults[oTokenAddress];
        if (vaultId == 0) {
            vaultId = OpynLib.openVault(controller, 1);
            marginVaults[oTokenAddress] = vaultId;
        }

        OpynLib.createShort(
            controller,
            vaultId,
            oTokenAddress,
            address(collateralToken),
            amount,
            depositAmount
        );
    }

    /// @notice reduce short position if there's a long oToken in the pool
    function reduceShort(
        address underlying,
        uint256 amount,
        address oTokenAddress,
        uint256 strike,
        uint256 expiration,
        bool isPut
    ) internal {
        uint256 vaultId = marginVaults[oTokenAddress];
        if (vaultId == 0) {
            // We do not have the vault in our system but we are going to trade the otoken and hold in the pool balance
            return;
        }

        uint256 burnAmount;
        uint256 withdrawalAmount;
        // avoid stack too deep
        {
            // get amount of short in the vault
            GammaTypes.Vault memory vault = IController(controller).getVault(
                address(this),
                vaultId
            );

            uint256 oTokenBalance = vault.shortAmounts[0];

            // calculate burnAmount = min(order.amount, vault.shortAmount)
            burnAmount = Math.min(amount, oTokenBalance);

            // calculate remaining short = vault.shortAmount - burnAmount
            uint256 reamainingShort = oTokenBalance - burnAmount;

            // calculate deposit required for remainig short using getCollateral
            uint256 depositAmount = getMarginRequired(
                underlying,
                strike,
                expiration,
                isPut,
                reamainingShort
            );

            uint256 vaultCollateral = vault.collateralAmounts[0];
            if (vaultCollateral > depositAmount)
                withdrawalAmount = vaultCollateral - depositAmount;
        }

        if (burnAmount > 0) {
            OpynLib.reduceShort(
                address(controller),
                vaultId,
                oTokenAddress,
                address(collateralToken),
                burnAmount,
                withdrawalAmount
            );
        }
    }

    /// @notice Get active oToken by index
    /// @param index is the index of the active oToken
    /// @return oToken address
    function getActiveOToken(uint256 index) public view returns (address) {
        return activeOTokens.at(index);
    }

    /// @notice Get all active oTokens
    function getActiveOTokens() public view returns (address[] memory) {
        address[] memory series = new address[](activeOTokens.length());
        for (uint256 i = 0; i < activeOTokens.length(); i++) {
            series[i] = activeOTokens.at(i);
        }
        return series;
    }

    /*******************
    Series management
    ********************/

    //  Guard Rails around price, price of a call should never exceed of the underlying

    /// @dev Update limit of series per expiration date
    function updateSeriesPerExpirationLimit(
        uint256 _seriesPerExpirationLimit
    ) public onlyOwner {
        seriesPerExpirationLimit = _seriesPerExpirationLimit;
    }

    /// @notice Gets oToken and adds it to the pool mappings for tracking
    function getOToken(
        address underlying,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut,
        bool mustExist
    ) internal returns (address) {
        address oToken = OpynLib.findOrCreateOToken(
            oTokenFactory,
            underlying,
            address(strikeToken),
            address(collateralToken),
            strikePrice,
            expiry,
            isPut,
            mustExist
        );

        // If otoken exists in our amm we can return otoken Address
        if (activeOTokens.contains(oToken)) {
            return oToken;
        }

        // Validate expiration
        if (
            !Dates.isValidExpiry(
                block.timestamp,
                expiry,
                allowedExpirations.numMonths,
                allowedExpirations.numQuarters
            )
        ) {
            revert CustomErrors.ExpiryNotSupported();
        }

        // We should always be less than the series per epxiraiotn since we are adding one onto the list
        if (
            oTokensByExpiry[underlying][expiry].length >=
            seriesPerExpirationLimit
        ) {
            revert CustomErrors.SeriesPerExpiryLimitExceeded();
        }

        {
            // TODO: wrap this into `getUnderlyingPrice` public function

            uint256 underlyingPrice = IOracle(oracle).getPrice(underlying);

            // Validate strike has been added by the owner - get the strike range info and ensure it is within params
            TokenStrikeRange memory existingRange = allowedStrikeRanges[
                underlying
            ];
            uint256 minStrike = (underlyingPrice * existingRange.minPercent) /
                100;
            if (strikePrice < minStrike) {
                revert CustomErrors.StrikeTooLow(minStrike);
            }

            uint256 maxStrike = (underlyingPrice * existingRange.maxPercent) /
                100;
            if (strikePrice > maxStrike) {
                revert CustomErrors.StrikeTooHigh(maxStrike);
            }

            if (strikePrice % existingRange.increment != 0) {
                revert CustomErrors.StrikeInvalidIncrement();
            }
        }

        // Finally add to our active oTokens in our pool
        activeOTokens.add(oToken);
        oTokensByExpiry[underlying][expiry].push(oToken);

        return oToken;
    }

    /*******************
    Hedging
    ********************/

    /// @notice Set hedger address for an underlying
    function setHedger(address underlying, address hedger) external onlyOwner {
        // remove approval from the old hedger
        if (address(hedgers[underlying]) != address(0)) {
            collateralToken.approve(address(hedgers[underlying]), 0);
        }

        hedgers[underlying] = hedger;
        collateralToken.approve(hedger, type(uint256).max);

        emit HedgerSet(underlying, hedger);
    }

    /// @notice Keeper can update vault margin if needed
    function syncVaultMargin(uint256 vaultId) external onlyKeeper {
        int256 collateralChange = _syncVaultMargin(
            controller,
            calculator,
            vaultId,
            MARGIN_UPDATE_TYPE.ALL
        );

        emit VaultMarginUpdated(vaultId, collateralChange);
    }

    /// @notice Keeper can update margin for all vaults and the hedge
    function syncMargin(address[] calldata underlying) external onlyKeeper {
        // withdraw excess collateral from vaults
        _syncActiveVaultsMargin(MARGIN_UPDATE_TYPE.EXCESS);

        // move collateral
        for (uint256 i = 0; i < underlying.length; i++) {
            IHedger(hedgers[underlying[i]]).sync();
        }

        // deposit shortfall into vaults
        _syncActiveVaultsMargin(MARGIN_UPDATE_TYPE.SHORTFALL);
    }

    enum MARGIN_UPDATE_TYPE {
        EXCESS,
        SHORTFALL,
        ALL
    }

    /// @notice Withdraw excess or deposit shortfall margin into a vault
    function _syncVaultMargin(
        address controller,
        address marginCalculator,
        uint256 vaultId,
        MARGIN_UPDATE_TYPE updateType
    ) internal returns (int256 collateralChange) {
        // if already updated in this block, skip
        if (lastMarginUpdate[vaultId] == block.timestamp) return 0;

        (GammaTypes.Vault memory vault, uint256 vaultType, ) = IController(
            controller
        ).getVaultWithDetails(address(this), vaultId);

        if (vault.shortAmounts[0] == 0) return 0;

        (uint256 netValue, bool isExcess) = IMarginCalculator(marginCalculator)
            .getExcessCollateral(vault, vaultType);

        // TODO: make dust value dynamic
        if (isExcess && netValue > 100 * (10 ** numDecimals)) {
            // excess, withdraw collateral
            if (
                updateType == MARGIN_UPDATE_TYPE.EXCESS ||
                updateType == MARGIN_UPDATE_TYPE.ALL
            ) {
                OpynLib.withdrawCollateral(
                    controller,
                    vaultId,
                    address(collateralToken),
                    netValue
                );
                collateralChange += int256(netValue);
            }
        } else if (netValue > 0) {
            // shortfall, deposit collateral
            if (
                updateType == MARGIN_UPDATE_TYPE.SHORTFALL ||
                updateType == MARGIN_UPDATE_TYPE.ALL
            ) {
                OpynLib.depositCollateral(
                    controller,
                    vaultId,
                    address(collateralToken),
                    netValue
                );
                collateralChange -= int256(netValue);
            }
        }

        if (collateralChange != 0) {
            lastMarginUpdate[vaultId] = block.timestamp;
        }

        return collateralChange;
    }

    /// @notice Update margin collateral for all active vaults
    function _syncActiveVaultsMargin(
        MARGIN_UPDATE_TYPE updateType
    ) internal returns (int256 collateralChange) {
        for (uint256 i = 0; i < activeOTokens.length(); i++) {
            uint256 vaultId = marginVaults[activeOTokens.at(i)];
            if (vaultId == 0) continue;

            collateralChange += _syncVaultMargin(
                controller,
                calculator,
                vaultId,
                updateType
            );
        }

        return collateralChange;
    }

    /// @notice Hedge vault delta
    /// @param delta pool delta to hedge in units of underlying
    function hedge(
        address[] calldata underlying,
        int256[] calldata delta
    ) external onlyKeeper {
        require(underlying.length == delta.length);

        // We have 2 options: pass new delta directly or pass array of deltas for each series and calculate net delta dynamically
        // option1 is more straightforward to implement and is cheaper on gas, but the drawback is that the hedge can become out-of-sync
        // with the pool delta if there's a large option trade
        // option2 requires more on-chain compute, but it makes the hedge more in sync with the pool
        // in reality unless hedging is updated at the same time as the trade it can always be out-of-sync
        // in either case the bot will have to monitor large trades and backrun them to update the hedge
        // and the only scenario in which a significant discrepancy in notional amount can happen is when there is a large
        // trade between the hedging transaction generated and included.
        // therefore it seems like submitting a delta value seems to be a viable solution

        // withdraw excess collateral from vaults
        _syncActiveVaultsMargin(MARGIN_UPDATE_TYPE.EXCESS);

        // hedge, this also rebalances the hedge collateral
        for (uint i = 0; i < underlying.length; i++) {
            IHedger(hedgers[underlying[i]]).hedge(delta[i]);
        }

        // deposit shortfall into vaults
        _syncActiveVaultsMargin(MARGIN_UPDATE_TYPE.SHORTFALL);
    }

    /*******************
    Pool config
    ********************/

    /// @notice This function allows the owner address to update allowed strikes for the auto series creation feature
    /// @param _underlying underlying token address
    /// @param _enabled whether the underlying is enabled or not
    /// @param _minPercent minimum strike allowed as percent of underlying price
    /// @param _maxPercent maximum strike allowed as percent of underlying price
    /// @param _increment price increment allowed - e.g. if increment is 10, then 100 would be valid and 101 would not be (strike % increment == 0)
    /// @dev Only the owner address should be allowed to call this
    function configUnderlying(
        address _underlying,
        bool _enabled,
        uint256 _minPercent,
        uint256 _maxPercent,
        uint256 _increment
    ) public onlyOwner {
        require(_underlying != address(0));

        if (_enabled) {
            // enable underlying
            underlyingTokens.add(_underlying);

            if (_minPercent > _maxPercent)
                revert CustomErrors.InvalidArgument();
            if (_increment == 0) revert CustomErrors.InvalidArgument();

            allowedStrikeRanges[_underlying] = TokenStrikeRange(
                _minPercent,
                _maxPercent,
                _increment
            );
        } else {
            // disable underlying
            underlyingTokens.remove(_underlying);
        }

        emit UnderlyingConfigured(
            _underlying,
            _enabled,
            _minPercent,
            _maxPercent,
            _increment
        );
    }

    function getAllUnderlyings() external view returns (address[] memory) {
        address[] memory underlyings = new address[](underlyingTokens.length());
        for (uint256 i = 0; i < underlyingTokens.length(); i++) {
            underlyings[i] = underlyingTokens.at(i);
        }
        return underlyings;
    }

    /// @notice Configure expirations allowed in the pool
    /// @param numMonths include last Friday of up to _numMonths in the future (0 - no montlys, 1 includes end of the current months)
    /// @param numQuarters include last Friday of up to _numQuarters in the future (0 - no quarterlys, 1 includes the next quarter)
    function setAllowedExpirations(
        uint8 numMonths,
        uint8 numQuarters
    ) external onlyOwner {
        if (numMonths > 12 || numQuarters > 6) {
            revert CustomErrors.InvalidArgument();
        }

        ExpiryConfig storage exp = allowedExpirations;
        exp.numMonths = numMonths;
        exp.numQuarters = numQuarters;
    }

    /// @notice Allow/disallow an address to perform keeper tasks
    function setKeeper(
        address keeperAddress,
        bool isPermitted
    ) external onlyOwner {
        keepers[keeperAddress] = isPermitted;
    }

    /// @notice Add/remove an address from allowed quote providers
    function setQuoteProvider(
        address quoteProviderAddress,
        bool isPermitted
    ) external onlyOwner {
        quoteProviders[quoteProviderAddress] = isPermitted;
    }

    /// @notice Refresh frequently used addresses
    function refreshConfiguration() external onlyOwner {
        _refreshConfigInternal();
    }

    /// @notice Store frequently used addresses
    function _refreshConfigInternal() internal {
        // remove old approvals
        if (marginPool != address(0)) {
            collateralToken.approve(marginPool, 0);
        }
        if (feeCollector != address(0)) {
            collateralToken.approve(feeCollector, 0);
        }

        controller = addressBook.getController();
        calculator = addressBook.getMarginCalculator();
        oracle = addressBook.getOracle();
        marginPool = addressBook.getMarginPool();
        oTokenFactory = addressBook.getOtokenFactory();
        orderUtil = addressBook.getOrderUtil();
        lpManager = addressBook.getLpManager();
        feeCollector = addressBook.getFeeCollector();

        // give approvals
        collateralToken.approve(marginPool, type(uint256).max);
        collateralToken.approve(feeCollector, type(uint256).max);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

import "../interfaces/IHedgedPool.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IAddressBook} from "../interfaces/IAddressBook.sol";
import "../interfaces/IHedger.sol";

/// This contract stores all new local variables for the MinterAmm.sol contract.
/// This allows us to upgrade the contract and add new variables without worrying about
///   memory layout when we add new variables.
/// Each time a new version is created with new variables, the version "V1, V2, etc" should
//    be bumped and inherit from the previous version, and the MinterAmm should inherit from
///   the newest version.
abstract contract HedgedPoolStorageV1 is IHedgedPool {
    /// @notice The ERC20 tokens used by all the Series associated with this AMM
    IERC20 public strikeToken;
    IERC20 public collateralToken;

    // @notice Allowed underlying assets for the pool
    EnumerableSet.AddressSet underlyingTokens;

    IAddressBook public addressBook;

    /// @notice Hedgers for each underlying
    mapping(address => address) public hedgers;

    /// @notice percent of the pool collateral reserved for hedging
    uint256 public hedgeReservePercent;

    // LP Token Roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant QUOTE_PROVIDER_ROLE =
        keccak256("QUOTE_PROVIDER_ROLE");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    /// @dev the number of decimals for this ERC20's human readable numeric
    uint8 internal numDecimals;

    /// @notice current withdrawal round end timestamp
    uint256 public withdrawalRoundEnd;

    /// @notice current deposit round end timestamp
    uint256 public depositRoundEnd;

    /// @notice last settled expiration timestamp for each underlying
    uint256 public lastSettledExpiry;

    /// @notice last recorded pool share price
    uint256 pricePerShareCached;

    // underlying => expiry => oToken
    mapping(address => mapping(uint256 => address[])) oTokensByExpiry;
    // oToken => MarginVault id
    mapping(address => uint256) public marginVaults;

    // vault id => block number
    mapping(uint256 => uint256) lastMarginUpdate;

    // stores all non-expired oTokens that the pool has ever traded
    EnumerableSet.AddressSet activeOTokens;

    /// @dev For a token, store the range for a strike price for the auto series creation feature
    struct TokenStrikeRange {
        uint256 minPercent;
        uint256 maxPercent;
        uint256 increment;
    }

    /// @dev Strike ranges for each underlying
    mapping(address => TokenStrikeRange) public allowedStrikeRanges;

    /// @dev Max series for each expiration date
    uint256 public seriesPerExpirationLimit;

    /// @dev Config for dynamic expirations
    struct ExpiryConfig {
        uint8 numMonths;
        uint8 numQuarters;
    }

    /// @dev Expirations allowed for trading in the pool
    ExpiryConfig public allowedExpirations;

    /// @dev List of permitted keeper addresses
    mapping(address => bool) public keepers;

    /// @dev List of permitted quote providers
    mapping(address => bool) public quoteProviders;

    /// @dev Frequently used contracts
    address internal controller;
    address internal calculator;
    address internal oTokenFactory;
    address internal oracle;
    address internal orderUtil;
    address internal marginPool;
    address internal lpManager;
    address internal feeCollector;
}

// Next version example:
/// contract HedgedPoolStorageV1 is HedgedPoolStorageV2 {
///   address public myAddress;
/// }
/// Then... HedgedPool should inherit from HedgedPoolStorageV1

pragma solidity 0.8.18;

interface CustomErrors {
    error AlreadyInitialized();
    error NotSettled();
    error InsufficientBalance();
    error ZeroValue();
    error NotEnoughLiquidity(
        uint256 liquidityAvailable,
        uint256 liquidityNeeded
    );
    error NotEnoughCollateral(
        uint256 collateralAvailable,
        uint256 collateralNeeded
    );
    error SeriesExpired();
    error InvalidPoolAddress();
    error InvalidFee();
    error Unauthorized();
    error InvalidArgument();
    error ExpiryNotSupported();
    error SeriesPerExpiryLimitExceeded();
    error StrikeTooHigh(uint256 maxStrike);
    error StrikeTooLow(uint256 minStrike);
    error StrikeInvalidIncrement();
    error InvalidUnderlying();
    error OrderNotSupported();
    error InvalidOrder();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IAddressBookGamma} from "./IGamma.sol";

interface IAddressBook is IAddressBookGamma {
    event OpynAddressBookUpdated(address indexed newAddress);
    event LpManagerUpdated(address indexed newAddress);
    event OrderUtilUpdated(address indexed newAddress);
    event FeeCollectorUpdated(address indexed newAddress);
    event LensUpdated(address indexed newAddress);
    event PerennialMultiInvokerUpdated(address indexed newAddress);
    event PerennialLensUpdated(address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function setAddress(bytes32 id, address newAddress) external;

    function getAddress(bytes32 id) external view returns (address);

    function setOpynAddressBook(address opynAddressBookAddress) external;

    function setLpManager(address lpManagerlAddress) external;

    function setOrderUtil(address orderUtilAddress) external;

    function getOpynAddressBook() external view returns (address);

    function getLpManager() external view returns (address);

    function getOrderUtil() external view returns (address);

    function getFeeCollector() external view returns (address);

    function getLens() external view returns (address);

    function getPerennialMultiInvoker() external view returns (address);

    function getPerennialLens() external view returns (address);
}

pragma solidity 0.8.18;

interface IFeeCollector {
    function collectFee(
        address feeAsset,
        uint256 feeAmount,
        address referrer
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

library GammaTypes {
    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        // addresses of oTokens a user has shorted (i.e. written) against this vault
        address[] shortOtokens;
        // addresses of oTokens a user has bought and deposited in this vault
        // user can be long oTokens without opening a vault (e.g. by buying on a DEX)
        // generally, long oTokens will be 'deposited' in vaults to act as collateral
        // in order to write oTokens against (i.e. in spreads)
        address[] longOtokens;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of oTokens minted/written for each oToken address in shortOtokens
        uint256[] shortAmounts;
        // quantity of oTokens owned and held in the vault for each oToken address in longOtokens
        uint256[] longAmounts;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
    }
}

interface IAddressBookGamma {
    /* Getters */

    function getOtokenImpl() external view returns (address);

    function getOtokenFactory() external view returns (address);

    function getWhitelist() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);

    function getMarginPool() external view returns (address);

    function getMarginCalculator() external view returns (address);

    function getLiquidationManager() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);
}

interface IOtoken {
    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);
}

interface IOtokenFactory {
    function getOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    function createOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external returns (address);

    function getTargetOtokenAddress(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    event OtokenCreated(
        address tokenAddress,
        address creator,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    );
}

interface IController {
    // possible actions that can be performed
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call,
        Liquidate
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // each vault can hold multiple short / long / collateral assets
        // but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    struct RedeemArgs {
        // address to which we pay out the oToken proceeds
        address receiver;
        // oToken that is to be redeemed
        address otoken;
        // amount of oTokens that is to be redeemed
        uint256 amount;
    }

    function getPayout(
        address _otoken,
        uint256 _amount
    ) external view returns (uint256);

    function operate(ActionArgs[] calldata _actions) external;

    function getAccountVaultCounter(
        address owner
    ) external view returns (uint256);

    function oracle() external view returns (address);

    function getVault(
        address _owner,
        uint256 _vaultId
    ) external view returns (GammaTypes.Vault memory);

    function getVaultWithDetails(
        address _owner,
        uint256 _vaultId
    ) external view returns (GammaTypes.Vault memory, uint256, uint256);

    function getProceed(
        address _owner,
        uint256 _vaultId
    ) external view returns (uint256);

    function isSettlementAllowed(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _expiry
    ) external view returns (bool);

    function hasExpired(address _otoken) external view returns (bool);
}

interface IMarginCalculator {
    function getNakedMarginRequired(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _shortAmount,
        uint256 _strikePrice,
        uint256 _underlyingPrice,
        uint256 _shortExpiryTimestamp,
        uint256 _collateralDecimals,
        bool _isPut
    ) external view returns (uint256);

    function getExcessCollateral(
        GammaTypes.Vault calldata _vault,
        uint256 _vaultType
    ) external view returns (uint256 netValue, bool isExcess);
}

interface IOracle {
    function isLockingPeriodOver(
        address _asset,
        uint256 _expiryTimestamp
    ) external view returns (bool);

    function isDisputePeriodOver(
        address _asset,
        uint256 _expiryTimestamp
    ) external view returns (bool);

    function getExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp
    ) external view returns (uint256, bool);

    function getDisputer() external view returns (address);

    function getPricer(address _asset) external view returns (address);

    function getPrice(address _asset) external view returns (uint256);

    function getPricerLockingPeriod(
        address _pricer
    ) external view returns (uint256);

    function getPricerDisputePeriod(
        address _pricer
    ) external view returns (uint256);

    function getChainlinkRoundData(
        address _asset,
        uint80 _roundId
    ) external view returns (uint256, uint256);

    // Non-view function

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;
}

interface OpynPricerInterface {
    function getPrice() external view returns (uint256);

    function getHistoricalPrice(
        uint80 _roundId
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOrderUtil.sol";
import {IAddressBook} from "./IAddressBook.sol";

interface IHedgedPool {
    function addressBook() external view returns (IAddressBook);

    function getCollateralBalance() external view returns (uint256);

    function strikeToken() external view returns (IERC20);

    function collateralToken() external view returns (IERC20);

    function getAllUnderlyings() external view returns (address[] memory);

    function getActiveOTokens() external view returns (address[] memory);

    function hedgers(address underlying) external view returns (address);

    function marginVaults(address oToken) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

interface IHedger {
    function hedge(int256 delta) external returns (int256 deltaDiff);

    function sync() external returns (int256 collateralDiff);

    function getDelta() external view returns (int256);

    function getCollateralValue() external returns (uint256);

    function getRequiredCollateral() external returns (int256);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

interface ILpManager {
    function depositRoundId(
        address poolAddress
    ) external view returns (uint256);

    function withdrawalRoundId(
        address poolAddress
    ) external view returns (uint256);

    function getCashLocked(
        address poolAddress,
        bool includePendingWithdrawals
    ) external view returns (uint256);

    function getUnfilledShares(
        address poolAddress
    ) external view returns (uint256);

    function getWithdrawalStatus(
        address poolAddress,
        address lpAddress
    )
        external
        view
        returns (
            uint256 sharesRedeemable,
            uint256 sharesOutstanding,
            uint256 cashRedeemable
        );

    function getDepositStatus(
        address poolAddress,
        address lpAddress
    ) external view returns (uint256 cashPending, uint256 sharesRedeemable);

    function closeWithdrawalRound(
        uint256 pricePerShare
    ) external returns (uint256 sharesRemoved);

    function closeDepositRound(
        uint256 pricePerShare
    ) external returns (uint256 sharesAdded);

    function addPendingCash(uint256 cashAmount) external;

    function addPricedCash(uint256 cashAmount, uint256 shareAmount) external;

    function requestWithdrawal(
        address lpAddress,
        uint256 sharesAmount
    ) external;

    function requestDeposit(address lpAddress, uint256 cashAmount) external;

    function redeemShares(address lpAddress) external returns (uint256);

    function withdrawCash(
        address lpAddress
    ) external returns (uint256, uint256);

    function cancelPendingDeposit(address lpAddress, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IOrderUtil {
    struct Order {
        address poolAddress;
        address underlying;
        address referrer;
        uint256 validUntil;
        uint256 nonce;
        OptionLeg[] legs;
        Signature signature;
        Signature[] coSignatures;
    }

    struct OptionLeg {
        uint256 strike;
        uint256 expiration;
        bool isPut;
        int256 amount;
        int256 premium;
        uint256 fee;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event Cancel(uint256 indexed nonce, address indexed signerWallet);

    event CancelUpTo(uint256 indexed nonce, address indexed signerWallet);

    error InvalidAdapters();
    error OrderExpired();
    error NonceTooLow();
    error NonceAlreadyUsed(uint256);
    error SenderInvalid();
    error SignatureInvalid();
    error SignerInvalid();
    error TokenKindUnknown();
    error Unauthorized();

    /**
     * @notice Validates order and returns its signatory
     * @param order Order
     */
    function processOrder(
        Order calldata order
    ) external returns (address signer, address[] memory coSigners);

    /**
     * @notice Cancel one or more open orders by nonce
     * @param nonces uint256[]
     */
    function cancel(uint256[] calldata nonces) external;

    /**
     * @notice Cancels all orders below a nonce value
     * @dev These orders can be made active by reducing the minimum nonce
     * @param minimumNonce uint256
     */
    function cancelUpTo(uint256 minimumNonce) external;

    function nonceUsed(address, uint256) external view returns (bool);

    function getSigners(
        Order calldata order
    ) external returns (address signer, address[] memory coSigners);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "./Math.sol";

// a library for performing various date operations
library Dates {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    int constant OFFSET19700101 = 2440588;

    // Credit: https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol
    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(
        uint _days
    ) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int _month = (80 * L) / 2447;
        int _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    /// @notice Returns the given timestamp date, but aligned to the prior 8am UTC dateOffset in the past
    /// unless the timestamp is exactly 8am UTC, in which case it will return the same
    /// value as the timestamp. If _dateOffset is 1 day then this function
    /// will align on every day at 8am, and if its 1 week it will align on every Friday 8am UTC
    /// @param _timestamp a block time (seconds past epoch)
    /// @return the block time of the prior (or current) 8am UTC date, dateOffset in the past
    function get8amAligned(
        uint256 _timestamp,
        uint256 _dateOffset
    ) internal pure returns (uint256) {
        require(
            _dateOffset == 1 weeks || _dateOffset == 1 days,
            "Invalid dateOffset"
        );

        uint256 numOffsetsSinceEpochStart = _timestamp / _dateOffset;

        // this will get us the timestamp of the Thursday midnight date prior to _timestamp if
        // dateOffset equals 1 week, or it will get us the timestamp of midnight of the previous
        // day if dateOffset equals 1 day. We rely on Solidity's integral rounding in the line above
        uint256 timestampRoundedDown = numOffsetsSinceEpochStart * _dateOffset;

        if (_dateOffset == 1 days) {
            uint256 eightHoursAligned = timestampRoundedDown + 8 hours;
            if (eightHoursAligned > _timestamp) {
                return eightHoursAligned - 1 days;
            } else {
                return eightHoursAligned;
            }
        } else {
            uint256 fridayEightHoursAligned = timestampRoundedDown +
                (1 days + 8 hours);
            if (fridayEightHoursAligned > _timestamp) {
                return fridayEightHoursAligned - 1 weeks;
            } else {
                return fridayEightHoursAligned;
            }
        }
    }

    /// @notice Check whether an expiration date is within the weekly, monthly and quarterly allowed expirations
    /// @param _now current timestamp
    /// @param _expiry date being validated
    /// @param _numMonths include last Friday of up to _numMonths in the future (1 includes end of the current months)
    /// @param _numQuarters include last Friday of up to _numQuarters in the future (0 - no quarterly, 1 includes the current quarter)
    function isValidExpiry(
        uint256 _now,
        uint256 _expiry,
        uint8 _numMonths,
        uint8 _numQuarters
    ) internal pure returns (bool) {
        // check the date is in the future
        if (_expiry < _now) return false;

        // check the date is Friday 8am UTC
        if (_expiry != get8amAligned(_expiry, 1 weeks)) return false;

        // check 2 weeklys
        if (_expiry - _now <= 1209600) return true;

        // check last friday of month
        (uint timestampYear, uint timestampMonth, ) = _daysToDate(
            _expiry / SECONDS_PER_DAY
        );
        (, uint nextWeekMonth, ) = _daysToDate(
            (_expiry + 1 weeks) / SECONDS_PER_DAY
        );

        // not last friday
        if (timestampMonth == nextWeekMonth) return false;

        (uint currentYear, uint currentMonth, ) = _daysToDate(
            _now / SECONDS_PER_DAY
        );

        // check quarterlys (jan, apr, jul, oct)
        if (
            ((timestampMonth - 1) % 3 == 0) &&
            ((timestampYear - currentYear) *
                4 +
                (timestampMonth - currentMonth) /
                3 +
                1 <=
                _numQuarters)
        ) return true;

        // check monthlys
        if (
            (timestampYear - currentYear) *
                12 +
                timestampMonth -
                currentMonth +
                1 <=
            _numMonths
        ) return true;

        return false;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

// a library for performing various math operations

library Math {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) return a;
        return b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) return a;
        return b;
    }

    function abs(int256 x) internal pure returns (uint256) {
        return x >= 0 ? uint256(x) : uint256(-x);
    }
}

// SPDX-License-Identifier: None

pragma solidity >=0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IOtoken, IOracle, GammaTypes, IController, IOtokenFactory, IMarginCalculator} from "../interfaces/IGamma.sol";

library OpynLib {
    /// Use safe ERC20 functions for any token transfers since people don't follow the ERC20 standard */
    using SafeERC20 for IERC20;

    /// @notice Settle Vault post-expiration
    function settle(address controller, uint256 vaultId) external {
        IController.ActionArgs[] memory actions = new IController.ActionArgs[](
            1
        );

        actions[0] = IController.ActionArgs(
            IController.ActionType.SettleVault,
            address(this), // owner
            address(this), // address to transfer to
            address(0), // not used
            vaultId, // vaultId
            0, // not used
            0, // not used
            "" // not used
        );

        IController(controller).operate(actions);
    }

    /// @notice Redeem expired long option
    function redeem(
        address controller,
        address oToken,
        uint256 amount
    ) external {
        IController.ActionArgs[] memory actions = new IController.ActionArgs[](
            1
        );

        actions[0] = IController.ActionArgs(
            IController.ActionType.Redeem,
            address(0), // not used
            address(this), // address to send profits to
            oToken, // address of otoken
            0, // not used
            amount, // otoken balance
            0, // not used
            "" // not used
        );
        IController(controller).operate(actions);
    }

    /// @notice open margin vault
    function openVault(
        address controller,
        uint256 vaultType
    ) external returns (uint256 vaultId) {
        IController.ActionArgs[] memory actions = new IController.ActionArgs[](
            1
        );

        vaultId =
            (IController(controller).getAccountVaultCounter(address(this))) +
            1;

        actions[0] = IController.ActionArgs(
            IController.ActionType.OpenVault,
            address(this), // owner
            address(this), // receiver
            address(0), // asset, otoken
            vaultId, // vaultId
            0, // amount
            0, //index
            abi.encode(vaultType) //data
        );

        IController(controller).operate(actions);

        return vaultId;
    }

    /// @notice add short position to a vault
    function createShort(
        address controller,
        uint256 vaultId,
        address oToken,
        address collateralAsset,
        uint256 amount,
        uint256 depositAmount
    ) external {
        IController.ActionArgs[] memory actions = new IController.ActionArgs[](
            2
        );

        actions[0] = IController.ActionArgs(
            IController.ActionType.DepositCollateral,
            address(this), // owner
            address(this), // address to transfer from
            collateralAsset, // deposited asset
            vaultId, // vaultId
            depositAmount, // amount
            0, //index
            "" //data
        );

        actions[1] = IController.ActionArgs(
            IController.ActionType.MintShortOption,
            address(this), // owner
            address(this), // address to transfer to
            oToken, // option address
            vaultId, // vaultId
            amount, // amount
            0, //index
            "" //data
        );

        IController(controller).operate(actions);
    }

    /// @notice reduce short amount and withdraw excess collateral
    function reduceShort(
        address controller,
        uint256 vaultId,
        address oToken,
        address collateralAsset,
        uint256 amount,
        uint256 withdrawalAmount
    ) external {
        IController.ActionArgs[] memory actions = new IController.ActionArgs[](
            2
        );

        actions[0] = IController.ActionArgs(
            IController.ActionType.BurnShortOption,
            address(this), // owner
            address(this), // address to transfer from
            oToken, // oToken address
            vaultId, // vaultId
            amount, // amount to burn
            0, //index
            "" //data
        );

        actions[1] = IController.ActionArgs(
            IController.ActionType.WithdrawCollateral,
            address(this), // owner
            address(this), // address to transfer to
            collateralAsset, // withdrawn asset
            vaultId, // vaultId
            withdrawalAmount, // amount
            0, //index
            "" //data
        );

        IController(controller).operate(actions);
    }

    /// @notice Withdraw collateral from vault
    function withdrawCollateral(
        address controller,
        uint256 vaultId,
        address collateralAsset,
        uint256 withdrawalAmount
    ) external {
        IController.ActionArgs[] memory actions = new IController.ActionArgs[](
            1
        );

        actions[0] = IController.ActionArgs(
            IController.ActionType.WithdrawCollateral,
            address(this), // owner
            address(this), // address to transfer to
            collateralAsset, // withdrawn asset
            vaultId, // vaultId
            withdrawalAmount, // amount
            0, //index
            "" //data
        );

        IController(controller).operate(actions);
    }

    /// @notice Deposit collateral into vault
    function depositCollateral(
        address controller,
        uint256 vaultId,
        address collateralAsset,
        uint256 depositAmount
    ) external {
        IController.ActionArgs[] memory actions = new IController.ActionArgs[](
            1
        );

        actions[0] = IController.ActionArgs(
            IController.ActionType.DepositCollateral,
            address(this), // owner
            address(this), // address to transfer from
            collateralAsset, // deposited asset
            vaultId, // vaultId
            depositAmount, // amount
            0, //index
            "" //data
        );

        IController(controller).operate(actions);
    }

    /// @notice find oToken or create it if doesn't exist
    function findOrCreateOToken(
        address factory,
        address underlyingAsset,
        address strikeAsset,
        address collateralAsset,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut,
        bool mustExist
    ) external returns (address oToken) {
        oToken = IOtokenFactory(factory).getOtoken(
            underlyingAsset,
            strikeAsset,
            collateralAsset,
            strikePrice,
            expiry,
            isPut
        );

        if (oToken == address(0)) {
            require(!mustExist, "oToken doesn't exist");

            oToken = IOtokenFactory(factory).createOtoken(
                underlyingAsset,
                strikeAsset,
                collateralAsset,
                strikePrice,
                expiry,
                isPut
            );
        }

        return oToken;
    }
}