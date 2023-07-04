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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

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
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
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
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
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
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
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
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
//

pragma solidity 0.8.18;

// base
import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { SafeCastUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/utils/math/SafeCastUpgradeable.sol";

// contracts
import { OracleMiddleware } from "src/oracles/OracleMiddleware.sol";
import { ConfigStorage } from "src/storages/ConfigStorage.sol";
import { VaultStorage } from "src/storages/VaultStorage.sol";
import { PerpStorage } from "src/storages/PerpStorage.sol";
import { FullMath } from "src/libraries/FullMath.sol";
import { HMXLib } from "src/libraries/HMXLib.sol";

// Interfaces
import { ICalculator } from "src/contracts/interfaces/ICalculator.sol";
import { IConfigStorage } from "src/storages/interfaces/IConfigStorage.sol";

contract Calculator is OwnableUpgradeable, ICalculator {
  using SafeCastUpgradeable for int256;
  using SafeCastUpgradeable for uint256;
  using FullMath for uint256;

  uint32 internal constant BPS = 1e4;
  uint64 internal constant ETH_PRECISION = 1e18;
  uint64 internal constant RATE_PRECISION = 1e18;

  /**
   * Events
   */
  event LogSetOracle(address indexed oldOracle, address indexed newOracle);
  event LogSetVaultStorage(address indexed oldVaultStorage, address indexed vaultStorage);
  event LogSetConfigStorage(address indexed oldConfigStorage, address indexed configStorage);
  event LogSetPerpStorage(address indexed oldPerpStorage, address indexed perpStorage);

  /**
   * States
   */
  address public oracle;
  address public vaultStorage;
  address public configStorage;
  address public perpStorage;

  function initialize(
    address _oracle,
    address _vaultStorage,
    address _perpStorage,
    address _configStorage
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    if (
      _oracle == address(0) || _vaultStorage == address(0) || _perpStorage == address(0) || _configStorage == address(0)
    ) revert ICalculator_InvalidAddress();

    // Sanity check
    PerpStorage(_perpStorage).getGlobalState();
    VaultStorage(_vaultStorage).hlpLiquidityDebtUSDE30();
    ConfigStorage(_configStorage).getLiquidityConfig();

    oracle = _oracle;
    vaultStorage = _vaultStorage;
    configStorage = _configStorage;
    perpStorage = _perpStorage;
  }

  /// @notice getAUME30
  /// @param _isMaxPrice Use Max or Min Price
  /// @return HLP Value in E30 format
  function getAUME30(bool _isMaxPrice) external view returns (uint256) {
    // SLOAD
    VaultStorage _vaultStorage = VaultStorage(vaultStorage);

    // hlpAUM = value of all asset + pnlShort + pnlLong + pendingBorrowingFee
    uint256 pendingBorrowingFeeE30 = _getPendingBorrowingFeeE30();
    uint256 borrowingFeeDebt = _vaultStorage.globalBorrowingFeeDebt();
    int256 pnlE30 = _getGlobalPNLE30();

    uint256 lossDebt = _vaultStorage.globalLossDebt();
    uint256 aum = _getHLPValueE30(_isMaxPrice) + pendingBorrowingFeeE30 + borrowingFeeDebt + lossDebt;

    if (pnlE30 < 0) {
      uint256 _pnl = uint256(-pnlE30);
      if (aum < _pnl) return 0;
      aum -= _pnl;
    } else {
      aum += uint256(pnlE30);
    }

    return aum;
  }

  function getGlobalPNLE30() external view returns (int256) {
    return _getGlobalPNLE30();
  }

  /// @notice getPendingBorrowingFeeE30 This function calculates the total pending borrowing fee from all asset classes.
  /// @return total pending borrowing fee in e30 format
  function getPendingBorrowingFeeE30() external view returns (uint256) {
    return _getPendingBorrowingFeeE30();
  }

  /// @notice _getPendingBorrowingFeeE30 This function calculates the total pending borrowing fee from all asset classes.
  /// @return total pending borrowing fee in e30 format
  function _getPendingBorrowingFeeE30() internal view returns (uint256) {
    // SLOAD
    PerpStorage _perpStorage = PerpStorage(perpStorage);
    uint256 _len = ConfigStorage(configStorage).getAssetClassConfigsLength();

    // Get the HLP TVL.
    uint256 _hlpTVL = _getHLPValueE30(false);
    uint256 _pendingBorrowingFee; // sum from each asset class
    for (uint256 i; i < _len; ) {
      PerpStorage.AssetClass memory _assetClassState = _perpStorage.getAssetClassByIndex(i);

      uint256 _borrowingFeeE30 = (_getNextBorrowingRate(uint8(i), _hlpTVL) * _assetClassState.reserveValueE30) /
        RATE_PRECISION;

      // Formula:
      // pendingBorrowingFee = (sumBorrowingFeeE30 - sumSettledBorrowingFeeE30) + latestBorrowingFee
      _pendingBorrowingFee +=
        (_assetClassState.sumBorrowingFeeE30 - _assetClassState.sumSettledBorrowingFeeE30) +
        _borrowingFeeE30;

      unchecked {
        ++i;
      }
    }

    return _pendingBorrowingFee;
  }

  /// @notice GetHLPValue in E30
  /// @param _isMaxPrice Use Max or Min Price
  /// @return HLP Value
  function getHLPValueE30(bool _isMaxPrice) external view returns (uint256) {
    return _getHLPValueE30(_isMaxPrice);
  }

  /// @notice GetHLPValue in E30
  /// @param _isMaxPrice Use Max or Min Price
  /// @return HLP Value
  function _getHLPValueE30(bool _isMaxPrice) internal view returns (uint256) {
    ConfigStorage _configStorage = ConfigStorage(configStorage);

    bytes32[] memory _hlpAssetIds = _configStorage.getHlpAssetIds();
    uint256 assetValue = 0;
    uint256 _len = _hlpAssetIds.length;

    for (uint256 i = 0; i < _len; ) {
      uint256 value = _getHLPUnderlyingAssetValueE30(_hlpAssetIds[i], _configStorage, _isMaxPrice);
      unchecked {
        assetValue += value;
        ++i;
      }
    }

    return assetValue;
  }

  /// @notice Get HLP underlying asset value in E30
  /// @param _underlyingAssetId the underlying asset id, the one we want to find the value
  /// @param _configStorage config storage
  /// @param _isMaxPrice Use Max or Min Price
  /// @return HLP Value
  function _getHLPUnderlyingAssetValueE30(
    bytes32 _underlyingAssetId,
    ConfigStorage _configStorage,
    bool _isMaxPrice
  ) internal view returns (uint256) {
    ConfigStorage.AssetConfig memory _assetConfig = _configStorage.getAssetConfig(_underlyingAssetId);

    (uint256 _priceE30, ) = OracleMiddleware(oracle).unsafeGetLatestPrice(_underlyingAssetId, _isMaxPrice);
    uint256 value = (VaultStorage(vaultStorage).hlpLiquidity(_assetConfig.tokenAddress) * _priceE30) /
      (10 ** _assetConfig.decimals);

    return value;
  }

  /// @notice getHLPPrice in e18 format
  /// @param _aum aum in HLP
  /// @param _hlpSupply Total Supply of HLP token
  /// @return HLP Price in e18
  function getHLPPrice(uint256 _aum, uint256 _hlpSupply) external pure returns (uint256) {
    if (_hlpSupply == 0) return 0;
    return _aum / _hlpSupply;
  }

  /// @dev Computes the global market PnL in E30 format by iterating through all the markets.
  /// @return The total PnL in E30 format, which is the sum of long and short positions' PnLs.
  function _getGlobalPNLE30() internal view returns (int256) {
    // SLOAD
    ConfigStorage _configStorage = ConfigStorage(configStorage);
    PerpStorage _perpStorage = PerpStorage(perpStorage);
    OracleMiddleware _oracle = OracleMiddleware(oracle);

    int256 totalPnlLong = 0;
    int256 totalPnlShort = 0;
    uint256 _len = _configStorage.getMarketConfigsLength();

    for (uint256 i = 0; i < _len; ) {
      ConfigStorage.MarketConfig memory _marketConfig = _configStorage.getMarketConfigByIndex(i);
      PerpStorage.Market memory _market = _perpStorage.getMarketByIndex(i);

      int256 _pnlLongE30 = 0;
      int256 _pnlShortE30 = 0;
      (uint256 priceE30, ) = _oracle.unsafeGetLatestPrice(_marketConfig.assetId, false);

      if (_market.longPositionSize > 0) {
        _pnlLongE30 = _getGlobalMarketPnl(
          priceE30,
          (int(_market.longPositionSize) - int(_market.shortPositionSize)),
          _marketConfig.fundingRate.maxSkewScaleUSD,
          int(_market.longAccumSE),
          _market.longAccumS2E,
          _market.longPositionSize,
          true
        );
      }
      if (_market.shortPositionSize > 0) {
        _pnlShortE30 = _getGlobalMarketPnl(
          priceE30,
          (int(_market.longPositionSize) - int(_market.shortPositionSize)),
          _marketConfig.fundingRate.maxSkewScaleUSD,
          int(_market.shortAccumSE),
          _market.shortAccumS2E,
          _market.shortPositionSize,
          false
        );
      }

      {
        unchecked {
          ++i;
          totalPnlLong += _pnlLongE30;
          totalPnlShort += _pnlShortE30;
        }
      }
    }

    return totalPnlLong + totalPnlShort;
  }

  /// @notice getMintAmount in e18 format
  /// @param _aumE30 aum in HLP E30
  /// @param _totalSupply HLP total supply
  /// @param _value value in USD e30
  /// @return mintAmount in e18 format
  function getMintAmount(uint256 _aumE30, uint256 _totalSupply, uint256 _value) external pure returns (uint256) {
    return _aumE30 == 0 ? _value / 1e12 : (_value * _totalSupply) / _aumE30;
  }

  function convertTokenDecimals(
    uint256 fromTokenDecimals,
    uint256 toTokenDecimals,
    uint256 amount
  ) external pure returns (uint256) {
    return (amount * 10 ** toTokenDecimals) / 10 ** fromTokenDecimals;
  }

  function getAddLiquidityFeeBPS(
    address _token,
    uint256 _tokenValueE30,
    ConfigStorage _configStorage
  ) external view returns (uint32) {
    if (!_configStorage.getLiquidityConfig().dynamicFeeEnabled) {
      return _configStorage.getLiquidityConfig().depositFeeRateBPS;
    }

    return
      _getFeeBPS(
        _tokenValueE30,
        _getHLPUnderlyingAssetValueE30(_configStorage.tokenAssetIds(_token), _configStorage, false),
        _getHLPValueE30(false),
        _configStorage.getLiquidityConfig(),
        _configStorage.getAssetHlpTokenConfigByToken(_token),
        LiquidityDirection.ADD
      );
  }

  function getRemoveLiquidityFeeBPS(
    address _token,
    uint256 _tokenValueE30,
    ConfigStorage _configStorage
  ) external view returns (uint32) {
    if (!_configStorage.getLiquidityConfig().dynamicFeeEnabled) {
      return _configStorage.getLiquidityConfig().withdrawFeeRateBPS;
    }

    return
      _getFeeBPS(
        _tokenValueE30,
        _getHLPUnderlyingAssetValueE30(_configStorage.tokenAssetIds(_token), _configStorage, true),
        _getHLPValueE30(true),
        _configStorage.getLiquidityConfig(),
        _configStorage.getAssetHlpTokenConfigByToken(_token),
        LiquidityDirection.REMOVE
      );
  }

  function _getFeeBPS(
    uint256 _value, //e30
    uint256 _liquidityUSD, //e30
    uint256 _totalLiquidityUSD, //e30
    ConfigStorage.LiquidityConfig memory _liquidityConfig,
    ConfigStorage.HLPTokenConfig memory _hlpTokenConfig,
    LiquidityDirection direction
  ) internal pure returns (uint32) {
    uint32 _feeBPS = direction == LiquidityDirection.ADD
      ? _liquidityConfig.depositFeeRateBPS
      : _liquidityConfig.withdrawFeeRateBPS;
    uint32 _taxBPS = _liquidityConfig.taxFeeRateBPS;
    uint256 _totalTokenWeight = _liquidityConfig.hlpTotalTokenWeight;

    uint256 startValue = _liquidityUSD;
    uint256 nextValue = startValue + _value;
    if (direction == LiquidityDirection.REMOVE) nextValue = _value > startValue ? 0 : startValue - _value;

    uint256 targetValue = _getTargetValue(_totalLiquidityUSD, _hlpTokenConfig.targetWeight, _totalTokenWeight);

    if (targetValue == 0) return _feeBPS;

    uint256 startTargetDiff = startValue > targetValue ? startValue - targetValue : targetValue - startValue;
    uint256 nextTargetDiff = nextValue > targetValue ? nextValue - targetValue : targetValue - nextValue;

    // nextValue moves closer to the targetValue -> positive case;
    // Should apply rebate.
    if (nextTargetDiff < startTargetDiff) {
      uint32 rebateBPS = uint32((_taxBPS * startTargetDiff) / targetValue);
      return rebateBPS > _feeBPS ? 0 : _feeBPS - rebateBPS;
    }

    // _nextWeight represented 18 precision
    uint256 _nextWeight = (nextValue * ETH_PRECISION) / (_totalLiquidityUSD + _value);
    uint256 withdrawalWeightDiff = _hlpTokenConfig.targetWeight > _hlpTokenConfig.maxWeightDiff
      ? _hlpTokenConfig.targetWeight - _hlpTokenConfig.maxWeightDiff
      : 0;
    if (
      _nextWeight > _hlpTokenConfig.targetWeight + _hlpTokenConfig.maxWeightDiff || _nextWeight < withdrawalWeightDiff
    ) {
      revert ICalculator_PoolImbalance();
    }

    // If not then -> negative impact to the pool.
    // Should apply tax.
    uint256 midDiff = (startTargetDiff + nextTargetDiff) / 2;
    if (midDiff > targetValue) {
      midDiff = targetValue;
    }
    _taxBPS = uint32((_taxBPS * midDiff) / targetValue);

    return uint32(_feeBPS + _taxBPS);
  }

  /// @notice get settlement fee rate
  /// @param _token - token
  /// @param _liquidityUsdDelta - withdrawal amount
  /// @return _settlementFeeRate in e18 format
  function getSettlementFeeRate(
    address _token,
    uint256 _liquidityUsdDelta
  ) external view returns (uint256 _settlementFeeRate) {
    // SLOAD
    ConfigStorage _configStorage = ConfigStorage(configStorage);

    // usd debt
    uint256 _tokenLiquidityUsd = _getHLPUnderlyingAssetValueE30(
      _configStorage.tokenAssetIds(_token),
      _configStorage,
      false
    );
    if (_tokenLiquidityUsd == 0) return 0;

    // total usd debt

    uint256 _totalLiquidityUsd = _getHLPValueE30(false);
    ConfigStorage.LiquidityConfig memory _liquidityConfig = _configStorage.getLiquidityConfig();

    // target value = total usd debt * target weight ratio (targe weigh / total weight);

    uint256 _targetUsd = (_totalLiquidityUsd * _configStorage.getAssetHlpTokenConfigByToken(_token).targetWeight) /
      _liquidityConfig.hlpTotalTokenWeight;

    if (_targetUsd == 0) return 0;

    // next value
    uint256 _nextUsd = _tokenLiquidityUsd - _liquidityUsdDelta;

    // current target diff
    uint256 _currentTargetDiff;
    uint256 _nextTargetDiff;
    unchecked {
      _currentTargetDiff = _tokenLiquidityUsd > _targetUsd
        ? _tokenLiquidityUsd - _targetUsd
        : _targetUsd - _tokenLiquidityUsd;
      // next target diff
      _nextTargetDiff = _nextUsd > _targetUsd ? _nextUsd - _targetUsd : _targetUsd - _nextUsd;
    }

    if (_nextTargetDiff < _currentTargetDiff) return 0;

    // settlement fee rate = (next target diff + current target diff / 2) * base tax fee / target usd
    return
      (((_nextTargetDiff + _currentTargetDiff) / 2) * _liquidityConfig.taxFeeRateBPS * ETH_PRECISION) /
      _targetUsd /
      BPS;
  }

  /// @notice Get target value of a token in HLP according to its target weight
  /// @param totalLiquidityUSD total liquidity USD of the whole HLP
  /// @param tokenWeight the token weight of this token
  /// @param totalTokenWeight the total token weight of HLP
  function _getTargetValue(
    uint256 totalLiquidityUSD, //e30
    uint256 tokenWeight, //e18
    uint256 totalTokenWeight // 1e18
  ) internal pure returns (uint256) {
    if (totalLiquidityUSD == 0) return 0;

    return (totalLiquidityUSD * tokenWeight) / totalTokenWeight;
  }

  /**
   * Setter functions
   */

  /// @notice Set new Oracle contract address.
  /// @param _oracle New Oracle contract address.
  function setOracle(address _oracle) external onlyOwner {
    if (_oracle == address(0)) revert ICalculator_InvalidAddress();
    OracleMiddleware(_oracle).isUpdater(address(this));
    emit LogSetOracle(oracle, _oracle);
    oracle = _oracle;
  }

  /// @notice Set new VaultStorage contract address.
  /// @param _vaultStorage New VaultStorage contract address.
  function setVaultStorage(address _vaultStorage) external onlyOwner {
    if (_vaultStorage == address(0)) revert ICalculator_InvalidAddress();
    VaultStorage(_vaultStorage).hlpLiquidityDebtUSDE30();
    emit LogSetVaultStorage(vaultStorage, _vaultStorage);
    vaultStorage = _vaultStorage;
  }

  /// @notice Set new ConfigStorage contract address.
  /// @param _configStorage New ConfigStorage contract address.
  function setConfigStorage(address _configStorage) external onlyOwner {
    if (_configStorage == address(0)) revert ICalculator_InvalidAddress();
    ConfigStorage(_configStorage).getLiquidityConfig();
    emit LogSetConfigStorage(configStorage, _configStorage);
    configStorage = _configStorage;
  }

  /// @notice Set new PerpStorage contract address.
  /// @param _perpStorage New PerpStorage contract address.
  function setPerpStorage(address _perpStorage) external onlyOwner {
    if (_perpStorage == address(0)) revert ICalculator_InvalidAddress();
    PerpStorage(_perpStorage).getGlobalState();
    emit LogSetPerpStorage(perpStorage, _perpStorage);
    perpStorage = _perpStorage;
  }

  /// @notice Calculate for value on trader's account including Equity, IMR and MMR.
  /// @dev Equity = Sum(collateral tokens' Values) + Sum(unrealized PnL) - Unrealized Borrowing Fee - Unrealized Funding Fee
  /// @param _subAccount Trader account's address.
  /// @param _limitPriceE30 Price to be overwritten to a specified asset
  /// @param _limitAssetId Asset to be overwritten by _limitPriceE30
  /// @return _equityValueE30 Total equity of trader's account.
  function getEquity(
    address _subAccount,
    uint256 _limitPriceE30,
    bytes32 _limitAssetId
  ) external view returns (int256 _equityValueE30) {
    return _getEquity(_subAccount, _limitPriceE30, _limitAssetId, new bytes32[](0), new uint256[](0));
  }

  /// @notice Calculate equity value of a given account. Same as above but allow injected price.
  /// @dev This function is supposed to be used in view function only.
  /// @param _subAccount Trader's account address
  /// @param _injectedAssetIds AssetIds to be used for price ref.
  /// @param _injectedPrices Prices to be used for calculate equity
  function getEquityWithInjectedPrices(
    address _subAccount,
    bytes32[] memory _injectedAssetIds,
    uint256[] memory _injectedPrices
  ) external view returns (int256 _equityValueE30) {
    if (_injectedAssetIds.length != _injectedPrices.length) revert ICalculator_InvalidArray();
    return _getEquity(_subAccount, 0, 0, _injectedAssetIds, _injectedPrices);
  }

  /// @notice Perform the actual equity calculation.
  /// @param _subAccount The trader's account addresss to be calculate.
  /// @param _limitPriceE30 Price to be overwritten for a specific assetId.
  /// @param _limitAssetId Asset Id that its price will need to be overwritten.
  /// @param _injectedAssetIds AssetIds to be used for price ref.
  /// @param _injectedPrices Prices to be used for calculate equity
  function _getEquity(
    address _subAccount,
    uint256 _limitPriceE30,
    bytes32 _limitAssetId,
    bytes32[] memory _injectedAssetIds,
    uint256[] memory _injectedPrices
  ) internal view returns (int256 _equityValueE30) {
    VaultStorage _vaultStorage = VaultStorage(vaultStorage);

    // Calculate collateral tokens' value on trader's sub account
    uint256 _collateralValueE30 = _getCollateralValue(
      _subAccount,
      _limitPriceE30,
      _limitAssetId,
      _injectedAssetIds,
      _injectedPrices
    );

    // Calculate unrealized PnL and unrealized fee
    (int256 _unrealizedPnlValueE30, int256 _unrealizedFeeValueE30) = _getUnrealizedPnlAndFee(
      _subAccount,
      _limitPriceE30,
      _limitAssetId,
      _injectedAssetIds,
      _injectedPrices
    );

    // Calculate equity
    _equityValueE30 += int256(_collateralValueE30);
    _equityValueE30 += _unrealizedPnlValueE30;
    _equityValueE30 -= _unrealizedFeeValueE30;

    _equityValueE30 -= int256(_vaultStorage.tradingFeeDebt(_subAccount));
    _equityValueE30 -= int256(_vaultStorage.borrowingFeeDebt(_subAccount));
    _equityValueE30 -= int256(_vaultStorage.fundingFeeDebt(_subAccount));
    _equityValueE30 -= int256(_vaultStorage.lossDebt(_subAccount));

    return _equityValueE30;
  }

  struct GetUnrealizedPnlAndFee {
    ConfigStorage configStorage;
    PerpStorage perpStorage;
    OracleMiddleware oracle;
    PerpStorage.Position position;
    uint256 absSize;
    bool isLong;
    uint256 priceE30;
    bool isProfit;
    uint256 delta;
  }

  struct GetCollateralValue {
    VaultStorage vaultStorage;
    ConfigStorage configStorage;
    OracleMiddleware oracle;
    uint256 decimals;
    uint256 amount;
    uint256 priceE30;
    bytes32 tokenAssetId;
    uint32 collateralFactorBPS;
    address[] traderTokens;
  }

  /// @notice Calculate unrealized PnL from trader's sub account.
  /// @dev This unrealized pnl deducted by collateral factor.
  /// @param _subAccount Trader's address that combined between Primary account and Sub account.
  /// @param _limitPriceE30 Price to be overwritten to a specified asset
  /// @param _limitAssetId Asset to be overwritten by _limitPriceE30
  /// @return _unrealizedPnlE30 PnL value after deducted by collateral factor.
  function getUnrealizedPnlAndFee(
    address _subAccount,
    uint256 _limitPriceE30,
    bytes32 _limitAssetId
  ) external view returns (int256 _unrealizedPnlE30, int256 _unrealizedFeeE30) {
    return _getUnrealizedPnlAndFee(_subAccount, _limitPriceE30, _limitAssetId, new bytes32[](0), new uint256[](0));
  }

  function _getUnrealizedPnlAndFee(
    address _subAccount,
    uint256 _limitPriceE30,
    bytes32 _limitAssetId,
    bytes32[] memory _injectedAssetIds,
    uint256[] memory _injectedPrices
  ) internal view returns (int256 _unrealizedPnlE30, int256 _unrealizedFeeE30) {
    GetUnrealizedPnlAndFee memory _var;
    // SLOADs
    _var.configStorage = ConfigStorage(configStorage);
    _var.perpStorage = PerpStorage(perpStorage);
    _var.oracle = OracleMiddleware(oracle);

    // Get all trader's opening positions
    PerpStorage.Position[] memory _positions = _var.perpStorage.getPositionBySubAccount(_subAccount);

    ConfigStorage.MarketConfig memory _marketConfig;
    PerpStorage.Market memory _market;
    uint256 pnlFactorBps = _var.configStorage.pnlFactorBPS();
    uint256 liquidationFee = _var.configStorage.getLiquidationConfig().liquidationFeeUSDE30;

    uint256 _len = _positions.length;
    // Loop through all trader's positions
    for (uint256 i; i < _len; ) {
      _var.position = _positions[i];
      _var.absSize = HMXLib.abs(_var.position.positionSizeE30);
      _var.isLong = _var.position.positionSizeE30 > 0;

      // Get market config according to opening position
      _marketConfig = _var.configStorage.getMarketConfigByIndex(_var.position.marketIndex);
      _market = _var.perpStorage.getMarketByIndex(_var.position.marketIndex);

      if (_injectedAssetIds.length > 0) {
        _var.priceE30 = _getPriceFromInjectedData(_marketConfig.assetId, _injectedAssetIds, _injectedPrices);
        (_var.priceE30, ) = _var.oracle.unsafeGetLatestAdaptivePrice(
          _marketConfig.assetId,
          !_var.isLong, // if current position is SHORT position, then we use max price
          (int(_market.longPositionSize) - int(_market.shortPositionSize)),
          -_var.position.positionSizeE30,
          _marketConfig.fundingRate.maxSkewScaleUSD,
          _var.priceE30
        );

        if (_var.priceE30 == 0) revert ICalculator_InvalidPrice();
      } else {
        // Check to overwrite price
        if (_limitAssetId == _marketConfig.assetId && _limitPriceE30 != 0) {
          _var.priceE30 = _limitPriceE30;
        } else {
          (_var.priceE30, ) = _var.oracle.getLatestAdaptivePrice(
            _marketConfig.assetId,
            !_var.isLong, // if current position is SHORT position, then we use max price
            (int(_market.longPositionSize) - int(_market.shortPositionSize)),
            -_var.position.positionSizeE30,
            _marketConfig.fundingRate.maxSkewScaleUSD,
            0
          );
        }
      }

      {
        // Calculate pnl
        (_var.isProfit, _var.delta) = _getDelta(
          _var.absSize,
          _var.isLong,
          _var.priceE30,
          _var.position.avgEntryPriceE30,
          _var.position.lastIncreaseTimestamp
        );

        if (_var.isProfit) {
          if (_var.delta >= _var.position.reserveValueE30) {
            _var.delta = _var.position.reserveValueE30;
          }
          _unrealizedPnlE30 += int256((pnlFactorBps * _var.delta) / BPS);
        } else {
          _unrealizedPnlE30 -= int256(_var.delta);
        }
      }

      {
        {
          // Calculate borrowing fee
          uint256 _hlpTVL = _getHLPValueE30(false);
          PerpStorage.AssetClass memory _assetClass = _var.perpStorage.getAssetClassByIndex(_marketConfig.assetClass);
          uint256 _nextBorrowingRate = _getNextBorrowingRate(_marketConfig.assetClass, _hlpTVL);
          _unrealizedFeeE30 += int256(
            _getBorrowingFee(
              _var.position.reserveValueE30,
              _assetClass.sumBorrowingRate + _nextBorrowingRate,
              _var.position.entryBorrowingRate
            )
          );
        }
        {
          // Calculate funding fee
          int256 _proportionalElapsedInDay = int256(proportionalElapsedInDay(_var.position.marketIndex));
          int256 nextFundingRate = _market.currentFundingRate +
            ((_getFundingRateVelocity(_var.position.marketIndex) * _proportionalElapsedInDay) / 1e18);
          int256 lastFundingAccrued = _market.fundingAccrued;
          int256 currentFundingAccrued = _market.fundingAccrued +
            ((_market.currentFundingRate + nextFundingRate) * _proportionalElapsedInDay) /
            2 /
            1e18;
          _unrealizedFeeE30 += getFundingFee(_var.position.positionSizeE30, currentFundingAccrued, lastFundingAccrued);
        }
        // Calculate trading fee
        _unrealizedFeeE30 += int256(_getTradingFee(_var.absSize, _marketConfig.decreasePositionFeeRateBPS));
      }

      unchecked {
        ++i;
      }
    }

    if (_len != 0) {
      // Calculate liquidation fee
      _unrealizedFeeE30 += int256(liquidationFee);
    }

    return (_unrealizedPnlE30, _unrealizedFeeE30);
  }

  /// @notice Calculate collateral tokens to value from trader's sub account.
  /// @param _subAccount Trader's address that combined between Primary account and Sub account.
  /// @param _limitPriceE30 Price to be overwritten to a specified asset
  /// @param _limitAssetId Asset to be overwritten by _limitPriceE30
  /// @return _collateralValueE30
  function getCollateralValue(
    address _subAccount,
    uint256 _limitPriceE30,
    bytes32 _limitAssetId
  ) external view returns (uint256 _collateralValueE30) {
    return _getCollateralValue(_subAccount, _limitPriceE30, _limitAssetId, new bytes32[](0), new uint256[](0));
  }

  function _getCollateralValue(
    address _subAccount,
    uint256 _limitPriceE30,
    bytes32 _limitAssetId,
    bytes32[] memory _injectedAssetIds,
    uint256[] memory _injectedPrices
  ) internal view returns (uint256 _collateralValueE30) {
    GetCollateralValue memory _var;

    // SLOADs
    _var.vaultStorage = VaultStorage(vaultStorage);
    _var.configStorage = ConfigStorage(configStorage);
    _var.oracle = OracleMiddleware(oracle);

    // Get list of current depositing tokens on trader's account
    _var.traderTokens = _var.vaultStorage.getTraderTokens(_subAccount);

    // Loop through list of current depositing tokens
    uint256 traderTokenLen = _var.traderTokens.length;
    for (uint256 i; i < traderTokenLen; ) {
      address _token = _var.traderTokens[i];
      ConfigStorage.CollateralTokenConfig memory _collateralTokenConfig = _var.configStorage.getCollateralTokenConfigs(
        _token
      );

      // Get token decimals from ConfigStorage
      _var.decimals = _var.configStorage.getAssetConfigByToken(_token).decimals;

      // Get collateralFactor from ConfigStorage
      _var.collateralFactorBPS = _collateralTokenConfig.collateralFactorBPS;

      // Get current collateral token balance of trader's account
      _var.amount = _var.vaultStorage.traderBalances(_subAccount, _token);

      // Get price from oracle
      _var.tokenAssetId = _var.configStorage.tokenAssetIds(_token);

      if (_injectedAssetIds.length > 0) {
        _var.priceE30 = _getPriceFromInjectedData(_var.tokenAssetId, _injectedAssetIds, _injectedPrices);
        if (_var.priceE30 == 0) revert ICalculator_InvalidPrice();
      } else {
        // Get token asset id from ConfigStorage
        if (_var.tokenAssetId == _limitAssetId && _limitPriceE30 != 0) {
          _var.priceE30 = _limitPriceE30;
        } else {
          (_var.priceE30, ) = _var.oracle.getLatestPrice(
            _var.tokenAssetId,
            false // @note Collateral value always use Min price
          );
        }
      }
      // Calculate accumulative value of collateral tokens
      // collateral value = (collateral amount * price) * collateralFactorBPS
      // collateralFactor 1e4 = 100%
      _collateralValueE30 += (_var.amount * _var.priceE30 * _var.collateralFactorBPS) / ((10 ** _var.decimals) * BPS);

      unchecked {
        ++i;
      }
    }

    return _collateralValueE30;
  }

  /// @notice Calculate Initial Margin Requirement from trader's sub account.
  /// @param _subAccount Trader's address that combined between Primary account and Sub account.
  /// @return _imrValueE30 Total imr of trader's account.
  function getIMR(address _subAccount) external view returns (uint256 _imrValueE30) {
    return _getIMR(_subAccount);
  }

  function _getIMR(address _subAccount) internal view returns (uint256 _imrValueE30) {
    // Get all trader's opening positions
    PerpStorage.Position[] memory _traderPositions = PerpStorage(perpStorage).getPositionBySubAccount(_subAccount);
    ConfigStorage _configStorage = ConfigStorage(configStorage);

    // Loop through all trader's positions
    uint256 len = _traderPositions.length;
    for (uint256 i; i < len; ) {
      PerpStorage.Position memory _position = _traderPositions[i];

      uint256 _size;
      if (_position.positionSizeE30 < 0) {
        _size = uint(_position.positionSizeE30 * -1);
      } else {
        _size = uint(_position.positionSizeE30);
      }

      // Calculate IMR on position
      _imrValueE30 += _calculatePositionIMR(_size, _position.marketIndex, _configStorage);

      unchecked {
        ++i;
      }
    }

    return _imrValueE30;
  }

  /// @notice Calculate Maintenance Margin Value from trader's sub account.
  /// @param _subAccount Trader's address that combined between Primary account and Sub account.
  /// @return _mmrValueE30 Total mmr of trader's account
  function getMMR(address _subAccount) external view returns (uint256 _mmrValueE30) {
    return _getMMR(_subAccount);
  }

  function _getMMR(address _subAccount) internal view returns (uint256 _mmrValueE30) {
    // Get all trader's opening positions
    PerpStorage.Position[] memory _traderPositions = PerpStorage(perpStorage).getPositionBySubAccount(_subAccount);
    ConfigStorage _configStorage = ConfigStorage(configStorage);

    // Loop through all trader's positions
    for (uint256 i; i < _traderPositions.length; ) {
      PerpStorage.Position memory _position = _traderPositions[i];

      uint256 _size;
      if (_position.positionSizeE30 < 0) {
        _size = uint(_position.positionSizeE30 * -1);
      } else {
        _size = uint(_position.positionSizeE30);
      }

      // Calculate MMR on position
      _mmrValueE30 += _calculatePositionMMR(_size, _position.marketIndex, _configStorage);

      unchecked {
        ++i;
      }
    }

    return _mmrValueE30;
  }

  /// @notice Calculate for Initial Margin Requirement from position size.
  /// @param _positionSizeE30 Size of position.
  /// @param _marketIndex Market Index from opening position.
  /// @return _imrE30 The IMR amount required on position size, 30 decimals.
  function calculatePositionIMR(
    uint256 _positionSizeE30,
    uint256 _marketIndex
  ) external view returns (uint256 _imrE30) {
    return _calculatePositionIMR(_positionSizeE30, _marketIndex, ConfigStorage(configStorage));
  }

  function _calculatePositionIMR(
    uint256 _positionSizeE30,
    uint256 _marketIndex,
    ConfigStorage _configStorage
  ) internal view returns (uint256 _imrE30) {
    // Get market config according to position
    ConfigStorage.MarketConfig memory _marketConfig = _configStorage.getMarketConfigByIndex(_marketIndex);
    _imrE30 = (_positionSizeE30 * _marketConfig.initialMarginFractionBPS) / BPS;
    return _imrE30;
  }

  /// @notice Calculate for Maintenance Margin Requirement from position size.
  /// @param _positionSizeE30 Size of position.
  /// @param _marketIndex Market Index from opening position.
  /// @return _mmrE30 The MMR amount required on position size, 30 decimals.
  function calculatePositionMMR(
    uint256 _positionSizeE30,
    uint256 _marketIndex
  ) external view returns (uint256 _mmrE30) {
    return _calculatePositionMMR(_positionSizeE30, _marketIndex, ConfigStorage(configStorage));
  }

  function _calculatePositionMMR(
    uint256 _positionSizeE30,
    uint256 _marketIndex,
    ConfigStorage _configStorage
  ) internal view returns (uint256 _mmrE30) {
    // Get market config according to position
    ConfigStorage.MarketConfig memory _marketConfig = _configStorage.getMarketConfigByIndex(_marketIndex);
    _mmrE30 = (_positionSizeE30 * _marketConfig.maintenanceMarginFractionBPS) / BPS;
    return _mmrE30;
  }

  /// @notice This function returns the amount of free collateral available to a given sub-account
  /// @param _subAccount The address of the sub-account
  /// @param _limitPriceE30 Price to be overwritten to a specified asset
  /// @param _limitAssetId Asset to be overwritten by _limitPriceE30
  /// @return _freeCollateral The amount of free collateral available to the sub-account
  function getFreeCollateral(
    address _subAccount,
    uint256 _limitPriceE30,
    bytes32 _limitAssetId
  ) external view returns (int256 _freeCollateral) {
    int256 equity = _getEquity(_subAccount, _limitPriceE30, _limitAssetId, new bytes32[](0), new uint256[](0));
    uint256 imr = _getIMR(_subAccount);
    _freeCollateral = equity - int256(imr);
    return _freeCollateral;
  }

  /// @notice Calculate next market average price
  /// @param _marketPositionSize - market's (long | short) position size
  /// @param _marketAveragePrice - market's average price
  /// @param _sizeDelta - position's size delta
  //                    - increase (long +, short -)
  //                    - decrease (long -, short +)
  /// @param _positionClosePrice - position's close price
  /// @param _positionNextClosePrice - position's close price after updated
  /// @param _positionRealizedPnl - position's realized PNL (profit +, loss -)
  function calculateMarketAveragePrice(
    int256 _marketPositionSize,
    uint256 _marketAveragePrice,
    int256 _sizeDelta,
    uint256 _positionClosePrice,
    uint256 _positionNextClosePrice,
    int256 _positionRealizedPnl
  ) external pure returns (uint256 _newAvaragePrice) {
    if (_marketAveragePrice == 0) return 0;
    // pnl calculation, LONG  -- position size * ((close price - average price) / average price)
    //                  SHORT -- position size * ((average price - close price) / average price)
    // example:
    // LONG  -- 1000 * ((105 - 100) / 100) = 50 (profit)
    //       -- 1000 * ((95 - 100) / 100) = -50 (loss)
    // SHORT -- -1000 * ((100 - 95) / 100) = -50 (profit)
    //       -- -1000 * ((100 - 105) / 100) = 50 (loss)
    bool isLong = _marketPositionSize > 0;
    int256 _marketPnl;
    if (isLong) {
      _marketPnl =
        (_marketPositionSize * (int256(_positionClosePrice) - int256(_marketAveragePrice))) /
        int256(_marketAveragePrice);
    } else {
      _marketPnl =
        (_marketPositionSize * (int256(_marketAveragePrice) - int256(_positionClosePrice))) /
        int256(_marketAveragePrice);
    }

    // unrealized pnl = market pnl - position realized pnl
    // example:
    // LONG  -- market pnl = 100,   realized position pnl = 50    then market unrealized pnl = 100 - 50     = 50  [profit]
    //       -- market pnl = -100,  realized position pnl = -50   then market unrealized pnl = -100 - (-50) = -50 [loss]

    // SHORT -- market pnl = -100,  realized position pnl = -50   then market unrealized pnl = -100 - (-50) = -50 [profit]
    //       -- market pnl = 100,   realized position pnl = 50    then market unrealized pnl = 100 - 50     = 50  [loss]
    int256 _unrealizedPnl = _marketPnl - _positionRealizedPnl;

    // | action         | market position | size delta |
    // | increase long  | +               | +          |
    // | decrease long  | +               | -          |
    // | increase short | -               | -          |
    // | decrease short | -               | +          |
    // then _marketPositionSize + _sizeDelta will work fine
    int256 _newMarketPositionSize = _marketPositionSize + _sizeDelta;
    int256 _divisor = isLong ? _newMarketPositionSize + _unrealizedPnl : _newMarketPositionSize - _unrealizedPnl;

    if (_newMarketPositionSize == 0) return 0;

    // for long, new market position size and divisor are positive number
    // and short, new market position size and divisor are negative number, then - / - would be +
    // note: abs unrealized pnl should not be greater then new position size, if calculation go wrong it's fine to revert
    return uint256((int256(_positionNextClosePrice) * _newMarketPositionSize) / _divisor);
  }

  function getFundingRateVelocity(uint256 _marketIndex) external view returns (int256 fundingRate) {
    return _getFundingRateVelocity(_marketIndex);
  }

  function proportionalElapsedInDay(uint256 _marketIndex) public view returns (uint256 elapsed) {
    PerpStorage.Market memory globalMarket = PerpStorage(perpStorage).getMarketByIndex(_marketIndex);
    return ((block.timestamp - globalMarket.lastFundingTime) * 1e18) / 1 days;
  }

  /// @notice Calculate the funding rate velocity
  /// @param _marketIndex Market Index.
  /// @return fundingRateVelocity which is the result of u = vt to get how fast the funding rate would change
  function _getFundingRateVelocity(uint256 _marketIndex) internal view returns (int256 fundingRateVelocity) {
    ConfigStorage _configStorage = ConfigStorage(configStorage);
    GetFundingRateVar memory vars;
    ConfigStorage.MarketConfig memory marketConfig = _configStorage.getMarketConfigByIndex(_marketIndex);
    PerpStorage.Market memory globalMarket = PerpStorage(perpStorage).getMarketByIndex(_marketIndex);
    if (marketConfig.fundingRate.maxFundingRate == 0 || marketConfig.fundingRate.maxSkewScaleUSD == 0) return 0;
    vars.marketSkewUSDE30 = int(globalMarket.longPositionSize) - int(globalMarket.shortPositionSize);

    // The result of this fundingRateVelocity Formula will be in the range of [-maxFundingRate, maxFundingRate]
    vars.ratio =
      (vars.marketSkewUSDE30 * int(marketConfig.fundingRate.maxFundingRate)) /
      int(marketConfig.fundingRate.maxSkewScaleUSD);
    return
      vars.ratio > 0
        ? HMXLib.min(vars.ratio, int(marketConfig.fundingRate.maxFundingRate))
        : HMXLib.max(vars.ratio, -int(marketConfig.fundingRate.maxFundingRate));
  }

  /**
   * Funding Rate
   */
  function getFundingFee(
    int256 _size,
    int256 _currentFundingAccrued,
    int256 _lastFundingAccrued
  ) public pure returns (int256 fundingFee) {
    int256 _fundingAccrued = _currentFundingAccrued - _lastFundingAccrued;
    // positive funding fee = trader pay funding fee
    // negative funding fee = trader receive funding fee
    return (_size * _fundingAccrued) / int64(RATE_PRECISION);
  }

  /// @notice Calculates the borrowing fee for a given asset class based on the reserved value, entry borrowing rate, and current sum borrowing rate of the asset class.
  /// @param _assetClassIndex The index of the asset class for which to calculate the borrowing fee.
  /// @param _reservedValue The reserved value of the asset class.
  /// @param _entryBorrowingRate The entry borrowing rate of the asset class.
  /// @return borrowingFee The calculated borrowing fee for the asset class.
  function getBorrowingFee(
    uint8 _assetClassIndex,
    uint256 _reservedValue,
    uint256 _entryBorrowingRate
  ) external view returns (uint256 borrowingFee) {
    // Get the global asset class.
    PerpStorage.AssetClass memory _assetClassState = PerpStorage(perpStorage).getAssetClassByIndex(_assetClassIndex);
    // // Calculate borrowing fee.
    return _getBorrowingFee(_reservedValue, _assetClassState.sumBorrowingRate, _entryBorrowingRate);
  }

  function _getBorrowingFee(
    uint256 _reservedValue,
    uint256 _sumBorrowingRate,
    uint256 _entryBorrowingRate
  ) internal pure returns (uint256 borrowingFee) {
    // Calculate borrowing rate.
    uint256 _borrowingRate = _sumBorrowingRate - _entryBorrowingRate;
    // Calculate the borrowing fee based on reserved value, borrowing rate.
    return (_reservedValue * _borrowingRate) / RATE_PRECISION;
  }

  function getNextBorrowingRate(
    uint8 _assetClassIndex,
    uint256 _hlpTVL
  ) external view returns (uint256 _nextBorrowingRate) {
    return _getNextBorrowingRate(_assetClassIndex, _hlpTVL);
  }

  /// @notice This function takes an asset class index as input and returns the next borrowing rate for that asset class.
  /// @param _assetClassIndex The index of the asset class.
  /// @param _hlpTVL value in hlp
  /// @return _nextBorrowingRate The next borrowing rate for the asset class.
  function _getNextBorrowingRate(
    uint8 _assetClassIndex,
    uint256 _hlpTVL
  ) internal view returns (uint256 _nextBorrowingRate) {
    ConfigStorage _configStorage = ConfigStorage(configStorage);

    // Get the trading config, asset class config, and global asset class for the given asset class index.
    ConfigStorage.TradingConfig memory _tradingConfig = _configStorage.getTradingConfig();
    ConfigStorage.AssetClassConfig memory _assetClassConfig = _configStorage.getAssetClassConfigByIndex(
      _assetClassIndex
    );
    PerpStorage.AssetClass memory _assetClassState = PerpStorage(perpStorage).getAssetClassByIndex(_assetClassIndex);
    // If block.timestamp not pass the next funding time, return 0.
    if (_assetClassState.lastBorrowingTime + _tradingConfig.fundingInterval > block.timestamp) return 0;

    // If HLP TVL is 0, return 0.
    if (_hlpTVL == 0) return 0;

    // Calculate the number of funding intervals that have passed since the last borrowing time.
    uint256 intervals = (block.timestamp - _assetClassState.lastBorrowingTime) / _tradingConfig.fundingInterval;

    // Calculate the next borrowing rate based on the asset class config, global asset class reserve value, and intervals.
    return (_assetClassConfig.baseBorrowingRate * _assetClassState.reserveValueE30 * intervals) / _hlpTVL;
  }

  function getTradingFee(uint256 _size, uint256 _baseFeeRateBPS) external pure returns (uint256 tradingFee) {
    return _getTradingFee(_size, _baseFeeRateBPS);
  }

  function _getTradingFee(uint256 _size, uint256 _baseFeeRateBPS) internal pure returns (uint256 tradingFee) {
    return (_size * _baseFeeRateBPS) / BPS;
  }

  function getDelta(
    uint256 _size,
    bool _isLong,
    uint256 _markPrice,
    uint256 _averagePrice,
    uint256 _lastIncreaseTimestamp
  ) external view returns (bool, uint256) {
    return _getDelta(_size, _isLong, _markPrice, _averagePrice, _lastIncreaseTimestamp);
  }

  /// @notice Calculates the delta between average price and mark price, based on the size of position and whether the position is profitable.
  /// @param _size The size of the position.
  /// @param _isLong position direction
  /// @param _markPrice current market price
  /// @param _averagePrice The average price of the position.
  /// @return isProfit A boolean value indicating whether the position is profitable or not.
  /// @return delta The Profit between the average price and the fixed price, adjusted for the size of the order.
  function _getDelta(
    uint256 _size,
    bool _isLong,
    uint256 _markPrice,
    uint256 _averagePrice,
    uint256 _lastIncreaseTimestamp
  ) internal view returns (bool, uint256) {
    // Check for invalid input: averagePrice cannot be zero.
    if (_averagePrice == 0) return (false, 0);

    // Calculate the difference between the average price and the fixed price.
    uint256 priceDelta;
    unchecked {
      priceDelta = _averagePrice > _markPrice ? _averagePrice - _markPrice : _markPrice - _averagePrice;
    }

    // Calculate the delta, adjusted for the size of the order.
    uint256 delta = (_size * priceDelta) / _averagePrice;

    // Determine if the position is profitable or not based on the averagePrice and the mark price.
    bool isProfit;
    if (_isLong) {
      isProfit = _markPrice > _averagePrice;
    } else {
      isProfit = _markPrice < _averagePrice;
    }

    // In case of profit, we need to check the current timestamp against minProfitDuration
    // in order to prevent front-run attack, or price manipulation.
    // Check `isProfit` first, to save SLOAD in loss case.
    if (isProfit) {
      IConfigStorage.TradingConfig memory _tradingConfig = ConfigStorage(configStorage).getTradingConfig();
      if (block.timestamp < _lastIncreaseTimestamp + _tradingConfig.minProfitDuration) {
        return (isProfit, 0);
      }
    }

    // Return the values of isProfit and delta.
    return (isProfit, delta);
  }

  function _getGlobalMarketPnl(
    uint256 price,
    int256 skew,
    uint256 maxSkew,
    int256 sumSE, // SUM(positionSize / entryPrice)
    uint256 sumS2E, // SUM(positionSize^2 / entryPrice)
    uint256 sumSize, // longSize or shortSize
    bool isLong
  ) internal pure returns (int256) {
    sumSE = isLong ? -sumSE : sumSE;
    int256 pnlFromPositions = (price.toInt256() * sumSE) / 1e30;
    int256 pnlFromSkew = ((((price.toInt256() * skew) / (maxSkew.toInt256())) * sumSE) / 1e30);
    uint256 pnlFromVolatility = price.mulDiv(sumS2E, 2 * maxSkew);
    int256 pnlFromDirection = isLong ? -(sumSize.toInt256()) : sumSize.toInt256();
    int256 result = pnlFromPositions + pnlFromSkew + pnlFromVolatility.toInt256() - pnlFromDirection;
    return result;
  }

  function _getPriceFromInjectedData(
    bytes32 _tokenAssetId,
    bytes32[] memory _injectedAssetIds,
    uint256[] memory _injectedPrices
  ) internal pure returns (uint256 _priceE30) {
    uint256 injectedAssetIdLen = _injectedAssetIds.length;
    for (uint256 i; i < injectedAssetIdLen; ) {
      if (_injectedAssetIds[i] == _tokenAssetId) {
        _priceE30 = _injectedPrices[i];
        // stop inside looping after found price
        break;
      }
      unchecked {
        ++i;
      }
    }
    return _priceE30;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}

// SPDX-License-Identifier: MIT
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
//

pragma solidity 0.8.18;

import { ConfigStorage } from "src/storages/ConfigStorage.sol";
import { VaultStorage } from "src/storages/VaultStorage.sol";

interface ICalculator {
  /**
   * Errors
   */
  error ICalculator_InvalidAddress();
  error ICalculator_InvalidArray();
  error ICalculator_InvalidAveragePrice();
  error ICalculator_InvalidPrice();
  error ICalculator_PoolImbalance();

  /**
   * Structs
   */
  struct GetFundingRateVar {
    uint256 fundingInterval;
    int256 marketSkewUSDE30;
    int256 ratio;
    int256 fundingRateVelocity;
    int256 elapsedIntervals;
  }

  enum LiquidityDirection {
    ADD,
    REMOVE
  }

  enum PositionExposure {
    LONG,
    SHORT
  }

  /**
   * States
   */
  function oracle() external returns (address _address);

  function vaultStorage() external returns (address _address);

  function configStorage() external returns (address _address);

  function perpStorage() external returns (address _address);

  /**
   * Functions
   */

  function getAUME30(bool isMaxPrice) external returns (uint256);

  function getGlobalPNLE30() external view returns (int256);

  function getHLPValueE30(bool isMaxPrice) external view returns (uint256);

  function getFreeCollateral(
    address _subAccount,
    uint256 _price,
    bytes32 _assetId
  ) external view returns (int256 _freeCollateral);

  function getHLPPrice(uint256 aum, uint256 supply) external returns (uint256);

  function getMintAmount(uint256 _aum, uint256 _totalSupply, uint256 _amount) external view returns (uint256);

  function getAddLiquidityFeeBPS(
    address _token,
    uint256 _tokenValue,
    ConfigStorage _configStorage
  ) external returns (uint32);

  function getRemoveLiquidityFeeBPS(
    address _token,
    uint256 _tokenValueE30,
    ConfigStorage _configStorage
  ) external returns (uint32);

  function getEquity(
    address _subAccount,
    uint256 _price,
    bytes32 _assetId
  ) external view returns (int256 _equityValueE30);

  function getEquityWithInjectedPrices(
    address _subAccount,
    bytes32[] memory _injectedAssetIds,
    uint256[] memory _injectedPrices
  ) external view returns (int256 _equityValueE30);

  function getUnrealizedPnlAndFee(
    address _subAccount,
    uint256 _limitPriceE30,
    bytes32 _limitAssetId
  ) external view returns (int256 _unrealizedPnlE30, int256 _unrealizedFeeE30);

  function getIMR(address _subAccount) external view returns (uint256 _imrValueE30);

  function getMMR(address _subAccount) external view returns (uint256 _mmrValueE30);

  function getSettlementFeeRate(address _token, uint256 _liquidityUsdDelta) external returns (uint256);

  function getCollateralValue(
    address _subAccount,
    uint256 _limitPrice,
    bytes32 _assetId
  ) external view returns (uint256 _collateralValueE30);

  function getFundingRateVelocity(uint256 _marketIndex) external view returns (int256);

  function getDelta(
    uint256 _size,
    bool _isLong,
    uint256 _markPrice,
    uint256 _averagePrice,
    uint256 _lastIncreaseTimestamp
  ) external view returns (bool, uint256);

  function getPendingBorrowingFeeE30() external view returns (uint256);

  function convertTokenDecimals(
    uint256 _fromTokenDecimals,
    uint256 _toTokenDecimals,
    uint256 _amount
  ) external pure returns (uint256);

  function calculatePositionIMR(uint256 _positionSizeE30, uint256 _marketIndex) external view returns (uint256 _imrE30);

  function calculatePositionMMR(uint256 _positionSizeE30, uint256 _marketIndex) external view returns (uint256 _mmrE30);

  function setOracle(address _oracle) external;

  function setVaultStorage(address _address) external;

  function setConfigStorage(address _address) external;

  function setPerpStorage(address _address) external;

  function proportionalElapsedInDay(uint256 _marketIndex) external view returns (uint256 elapsed);
}

// SPDX-License-Identifier: MIT
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
//

pragma solidity 0.8.18;

import { PerpStorage } from "src/storages/PerpStorage.sol";

interface ITradeHelper {
  /**
   * Errors
   */
  error ITradeHelper_TradingFeeCannotBeCovered();
  error ITradeHelper_BorrowingFeeCannotBeCovered();
  error ITradeHelper_FundingFeeCannotBeCovered();
  error ITradeHelper_UnrealizedPnlCannotBeCovered();
  error ITradeHelper_InvalidAddress();

  /**
   * Functions
   */
  function reloadConfig() external;

  function updateBorrowingRate(uint8 _assetClassIndex) external;

  function updateFundingRate(uint256 _marketIndex) external;

  function settleAllFees(
    bytes32 _positionId,
    PerpStorage.Position memory position,
    uint256 _absSizeDelta,
    uint32 _positionFeeBPS,
    uint8 _assetClassIndex
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
//

pragma solidity 0.8.18;

import { PerpStorage } from "src/storages/PerpStorage.sol";
import { VaultStorage } from "src/storages/VaultStorage.sol";
import { ConfigStorage } from "src/storages/ConfigStorage.sol";

import { Calculator } from "src/contracts/Calculator.sol";
import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import { SafeCastUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/utils/math/SafeCastUpgradeable.sol";

import { OracleMiddleware } from "src/oracles/OracleMiddleware.sol";
import { ITradeHelper } from "src/helpers/interfaces/ITradeHelper.sol";
import { HMXLib } from "src/libraries/HMXLib.sol";

contract TradeHelper is ITradeHelper, ReentrancyGuardUpgradeable, OwnableUpgradeable {
  using SafeCastUpgradeable for uint256;
  using SafeCastUpgradeable for int256;

  /**
   * Events
   */
  event LogSettleTradingFeeValue(bytes32 positionId, uint256 marketIndex, address subAccount, uint256 feeUsd);
  event LogSettleTradingFeeAmount(
    bytes32 positionId,
    uint256 marketIndex,
    address subAccount,
    address token,
    uint256 feeUsd,
    uint256 devFeeAmount,
    uint256 protocolFeeAmount
  );
  event LogSettleBorrowingFeeValue(bytes32 positionId, uint256 marketIndex, address subAccount, uint256 feeUsd);
  event LogSettleBorrowingFeeAmount(
    bytes32 positionId,
    uint256 marketIndex,
    address subAccount,
    address token,
    uint256 feeUsd,
    uint256 devFeeAmount,
    uint256 hlpFeeAmount
  );
  event LogSettleFundingFeeValue(bytes32 positionId, uint256 marketIndex, address subAccount, uint256 feeUsd);
  event LogSettleFundingFeeAmount(
    bytes32 positionId,
    uint256 marketIndex,
    address subAccount,
    address token,
    uint256 feeUsd,
    uint256 amount
  );

  event LogSettleUnRealizedPnlValue(bytes32 positionId, uint256 marketIndex, address subAccount, uint256 usd);
  event LogSettleUnRealizedPnlAmount(
    bytes32 positionId,
    uint256 marketIndex,
    address subAccount,
    address token,
    uint256 usd,
    uint256 amount
  );

  event LogSettleLiquidationFeeValue(bytes32 positionId, uint256 marketIndex, address subAccount, uint256 usd);
  event LogSettleLiquidationFeeAmount(
    bytes32 positionId,
    uint256 marketIndex,
    address subAccount,
    address token,
    uint256 usd,
    uint256 amount
  );

  event LogSettleSettlementFeeAmount(
    bytes32 positionId,
    uint256 marketIndex,
    address subAccount,
    address token,
    uint256 feeUsd,
    uint256 amount
  );

  event LogReceivedFundingFeeValue(bytes32 positionId, uint256 marketIndex, address subAccount, uint256 feeUsd);
  event LogReceivedFundingFeeAmount(
    bytes32 positionId,
    uint256 marketIndex,
    address subAccount,
    address token,
    uint256 feeUsd,
    uint256 amount
  );

  event LogReceivedUnRealizedPnlValue(bytes32 positionId, uint256 marketIndex, address subAccount, uint256 usd);
  event LogReceivedUnRealizedPnlAmount(
    bytes32 positionId,
    uint256 marketIndex,
    address subAccount,
    address token,
    uint256 usd,
    uint256 amount
  );

  event LogSetConfigStorage(address indexed oldConfigStorage, address newConfigStorage);
  event LogSetVaultStorage(address indexed oldVaultStorage, address newVaultStorage);
  event LogSetPerpStorage(address indexed oldPerpStorage, address newPerpStorage);
  event LogFundingRate(uint256 indexed marketIndex, int256 oldFundingRate, int256 newFundingRate);

  /**
   * Structs
   */
  struct IncreaseCollateralVars {
    bytes32 positionId;
    address token;
    address subAccount;
    uint8 tokenDecimal;
    uint256 unrealizedPnlToBeReceived;
    uint256 fundingFeeToBeReceived;
    uint256 payerBalance;
    uint256 tokenPrice;
    uint256 marketIndex;
    PerpStorage perpStorage;
    VaultStorage vaultStorage;
    ConfigStorage configStorage;
    OracleMiddleware oracle;
  }

  struct DecreaseCollateralVars {
    bytes32 positionId;
    address token;
    address subAccount;
    uint8 tokenDecimal;
    uint256 unrealizedPnlToBePaid;
    uint256 tradingFeeToBePaid;
    uint256 borrowingFeeToBePaid;
    uint256 fundingFeeToBePaid;
    uint256 liquidationFeeToBePaid;
    uint256 payerBalance;
    uint256 hlpDebt;
    uint256 tokenPrice;
    uint256 marketIndex;
    VaultStorage vaultStorage;
    ConfigStorage configStorage;
    OracleMiddleware oracle;
    ConfigStorage.TradingConfig tradingConfig;
  }

  struct SettleAllFeeVars {
    address subAccount;
    uint256 tradingFeeToBePaid;
    uint256 borrowingFeeToBePaid;
    int256 fundingFeeToBePaid;
  }

  /**
   * Constants
   */
  uint32 internal constant BPS = 1e4;
  uint64 internal constant RATE_PRECISION = 1e18;

  /**
   * States
   */
  address public perpStorage;
  address public vaultStorage;
  address public configStorage;
  Calculator public calculator; // cache this from configStorage

  /// @notice Initializes the contract by setting the addresses for PerpStorage, VaultStorage, and ConfigStorage.
  /// @dev This function must be called after the contract is deployed and before it can be used.
  /// @param _perpStorage The address of the PerpStorage contract.
  /// @param _vaultStorage The address of the VaultStorage contract.
  /// @param _configStorage The address of the ConfigStorage contract.
  /// @dev This function initializes the contract by performing a sanity check on the ConfigStorage calculator, setting the VaultStorage devFees to address(0), and getting the global state from the PerpStorage contract. It also sets the perpStorage, vaultStorage, configStorage, and calculator variables to the provided addresses.

  function initialize(address _perpStorage, address _vaultStorage, address _configStorage) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    // Sanity check
    ConfigStorage(_configStorage).calculator();
    VaultStorage(_vaultStorage).devFees(address(0));
    PerpStorage(_perpStorage).getGlobalState();

    perpStorage = _perpStorage;
    vaultStorage = _vaultStorage;
    configStorage = _configStorage;
    calculator = Calculator(ConfigStorage(_configStorage).calculator());
  }

  /**
   * Modifiers
   */
  // NOTE: Validate only whitelisted contract be able to call this function
  modifier onlyWhitelistedExecutor() {
    ConfigStorage(configStorage).validateServiceExecutor(address(this), msg.sender);
    _;
  }

  /**
   * Core Functions
   */
  /// @notice This function updates the borrowing rate for the given asset class index.
  /// @param _assetClassIndex The index of the asset class.
  function updateBorrowingRate(uint8 _assetClassIndex) external nonReentrant onlyWhitelistedExecutor {
    // SLOAD
    Calculator _calculator = calculator;
    PerpStorage _perpStorage = PerpStorage(perpStorage);

    // Get the funding interval, asset class config, and global asset class for the given asset class index.
    PerpStorage.AssetClass memory _assetClass = _perpStorage.getAssetClassByIndex(_assetClassIndex);
    uint256 _fundingInterval = ConfigStorage(configStorage).getTradingConfig().fundingInterval;
    uint256 _lastBorrowingTime = _assetClass.lastBorrowingTime;

    // If last borrowing time is 0, set it to the nearest funding interval time and return.
    if (_lastBorrowingTime == 0) {
      _assetClass.lastBorrowingTime = (block.timestamp / _fundingInterval) * _fundingInterval;
      _perpStorage.updateAssetClass(_assetClassIndex, _assetClass);
      return;
    }

    // If block.timestamp is not passed the next funding interval, skip updating
    if (_lastBorrowingTime + _fundingInterval <= block.timestamp) {
      uint256 _hlpTVL = _calculator.getHLPValueE30(false);

      // update borrowing rate
      uint256 borrowingRate = _calculator.getNextBorrowingRate(_assetClassIndex, _hlpTVL);
      _assetClass.sumBorrowingRate += borrowingRate;
      _assetClass.lastBorrowingTime = (block.timestamp / _fundingInterval) * _fundingInterval;

      uint256 borrowingFee = (_assetClass.reserveValueE30 * borrowingRate) / RATE_PRECISION;
      _assetClass.sumBorrowingFeeE30 += borrowingFee;

      _perpStorage.updateAssetClass(_assetClassIndex, _assetClass);
    }
  }

  /// @notice This function updates the funding rate for the given market index.
  /// @param _marketIndex The index of the market.
  function updateFundingRate(uint256 _marketIndex) external nonReentrant onlyWhitelistedExecutor {
    // SLOAD
    Calculator _calculator = calculator;
    PerpStorage _perpStorage = PerpStorage(perpStorage);

    // Get the funding interval, asset class config, and global asset class for the given asset class index.
    PerpStorage.Market memory _market = _perpStorage.getMarketByIndex(_marketIndex);

    uint256 _fundingInterval = ConfigStorage(configStorage).getTradingConfig().fundingInterval;
    uint256 _lastFundingTime = _market.lastFundingTime;

    // If last funding time is 0, set it to the nearest funding interval time and return.
    if (_lastFundingTime == 0) {
      _market.lastFundingTime = (block.timestamp / _fundingInterval) * _fundingInterval;
      _perpStorage.updateMarket(_marketIndex, _market);
      return;
    }

    // If block.timestamp is not passed the next funding interval, skip updating
    if (_lastFundingTime + _fundingInterval <= block.timestamp) {
      // update funding rate
      int256 proportionalElapsedInDay = int256(_calculator.proportionalElapsedInDay(_marketIndex));
      int256 nextFundingRate = _market.currentFundingRate +
        ((_calculator.getFundingRateVelocity(_marketIndex) * proportionalElapsedInDay) / 1e18);
      int256 lastFundingAccrued = _market.fundingAccrued;
      _market.fundingAccrued += ((_market.currentFundingRate + nextFundingRate) * proportionalElapsedInDay) / 2 / 1e18;

      if (_market.longPositionSize > 0) {
        int256 fundingFeeLongE30 = _calculator.getFundingFee(
          int256(_market.longPositionSize),
          _market.fundingAccrued,
          lastFundingAccrued
        );
        _market.accumFundingLong += fundingFeeLongE30;
      }

      if (_market.shortPositionSize > 0) {
        int256 fundingFeeShortE30 = _calculator.getFundingFee(
          -int256(_market.shortPositionSize),
          _market.fundingAccrued,
          lastFundingAccrued
        );
        _market.accumFundingShort += fundingFeeShortE30;
      }

      emit LogFundingRate(_marketIndex, _market.currentFundingRate, nextFundingRate);
      _market.currentFundingRate = nextFundingRate;
      _market.lastFundingTime = (block.timestamp / _fundingInterval) * _fundingInterval;
      _perpStorage.updateMarket(_marketIndex, _market);
    }
  }

  /// @notice Settles all fees for a given position and updates the fee states.
  /// @param _positionId The ID of the position to settle fees for.
  /// @param _position The Position object for the position to settle fees for.
  /// @param _absSizeDelta The absolute value of the size delta for the position.
  /// @param _positionFeeBPS The position fee basis points for the position.
  /// @param _assetClassIndex The index of the asset class for the position.
  function settleAllFees(
    bytes32 _positionId,
    PerpStorage.Position memory _position,
    uint256 _absSizeDelta,
    uint32 _positionFeeBPS,
    uint8 _assetClassIndex
  ) external nonReentrant onlyWhitelistedExecutor {
    SettleAllFeeVars memory _vars;
    _vars.subAccount = HMXLib.getSubAccount(_position.primaryAccount, _position.subAccountId);

    // update fee
    (_vars.tradingFeeToBePaid, _vars.borrowingFeeToBePaid, _vars.fundingFeeToBePaid) = _updateFeeStates(
      _positionId,
      _vars.subAccount,
      _position,
      _absSizeDelta,
      _positionFeeBPS,
      _assetClassIndex,
      _position.marketIndex
    );

    // increase collateral
    _increaseCollateral(_positionId, _vars.subAccount, 0, _vars.fundingFeeToBePaid, address(0), _position.marketIndex);

    // decrease collateral
    _decreaseCollateral(
      _positionId,
      _vars.subAccount,
      0,
      _vars.fundingFeeToBePaid,
      _vars.borrowingFeeToBePaid,
      _vars.tradingFeeToBePaid,
      0,
      address(0),
      _position.marketIndex
    );
  }

  function updateFeeStates(
    bytes32 _positionId,
    address _subAccount,
    PerpStorage.Position memory _position,
    uint256 _sizeDelta,
    uint32 _positionFeeBPS,
    uint8 _assetClassIndex,
    uint256 _marketIndex
  )
    external
    nonReentrant
    onlyWhitelistedExecutor
    returns (uint256 _tradingFee, uint256 _borrowingFee, int256 _fundingFee)
  {
    (_tradingFee, _borrowingFee, _fundingFee) = _updateFeeStates(
      _positionId,
      _subAccount,
      _position,
      _sizeDelta,
      _positionFeeBPS,
      _assetClassIndex,
      _marketIndex
    );
  }

  function accumSettledBorrowingFee(
    uint256 _assetClassIndex,
    uint256 _borrowingFeeToBeSettled
  ) external nonReentrant onlyWhitelistedExecutor {
    _accumSettledBorrowingFee(_assetClassIndex, _borrowingFeeToBeSettled);
  }

  function increaseCollateral(
    bytes32 _positionId,
    address _subAccount,
    int256 _unrealizedPnl,
    int256 _fundingFee,
    address _tpToken,
    uint256 _marketIndex
  ) external nonReentrant onlyWhitelistedExecutor {
    _increaseCollateral(_positionId, _subAccount, _unrealizedPnl, _fundingFee, _tpToken, _marketIndex);
  }

  function decreaseCollateral(
    bytes32 _positionId,
    address _subAccount,
    int256 _unrealizedPnl,
    int256 _fundingFee,
    uint256 _borrowingFee,
    uint256 _tradingFee,
    uint256 _liquidationFee,
    address _liquidator,
    uint256 _marketIndex
  ) external nonReentrant onlyWhitelistedExecutor {
    _decreaseCollateral(
      _positionId,
      _subAccount,
      _unrealizedPnl,
      _fundingFee,
      _borrowingFee,
      _tradingFee,
      _liquidationFee,
      _liquidator,
      _marketIndex
    );
  }

  function reloadConfig() external nonReentrant onlyOwner {
    calculator = Calculator(ConfigStorage(configStorage).calculator());
  }

  /**
   * Private Functions
   */

  function _updateFeeStates(
    bytes32 /*_positionId*/,
    address /*_subAccount*/,
    PerpStorage.Position memory _position,
    uint256 _sizeDelta,
    uint32 _positionFeeBPS,
    uint8 _assetClassIndex,
    uint256 _marketIndex
  ) internal returns (uint256 _tradingFee, uint256 _borrowingFee, int256 _fundingFee) {
    // SLOAD
    Calculator _calculator = calculator;

    // Calculate the trading fee
    _tradingFee = (_sizeDelta * _positionFeeBPS) / BPS;

    // Calculate the borrowing fee
    _borrowingFee = _calculator.getBorrowingFee(
      _assetClassIndex,
      _position.reserveValueE30,
      _position.entryBorrowingRate
    );
    // Update global state
    _accumSettledBorrowingFee(_assetClassIndex, _borrowingFee);

    // Calculate the funding fee
    // We are assuming that the market state has been updated with the latest funding rate
    bool _isLong = _position.positionSizeE30 > 0;
    _fundingFee = _calculator.getFundingFee(
      _position.positionSizeE30,
      PerpStorage(perpStorage).getMarketByIndex(_marketIndex).fundingAccrued,
      _position.lastFundingAccrued
    );

    // Update global state
    _isLong
      ? _updateAccumFundingLong(_marketIndex, -_fundingFee)
      : _updateAccumFundingShort(_marketIndex, -_fundingFee);

    return (_tradingFee, _borrowingFee, _fundingFee);
  }

  function _accumSettledBorrowingFee(uint256 _assetClassIndex, uint256 _borrowingFeeToBeSettled) internal {
    // SLOAD
    PerpStorage _perpStorage = PerpStorage(perpStorage);

    PerpStorage.AssetClass memory _assetClass = _perpStorage.getAssetClassByIndex(uint8(_assetClassIndex));
    _assetClass.sumSettledBorrowingFeeE30 += _borrowingFeeToBeSettled;
    _perpStorage.updateAssetClass(uint8(_assetClassIndex), _assetClass);
  }

  function _increaseCollateral(
    bytes32 _positionId,
    address _subAccount,
    int256 _unrealizedPnl,
    int256 _fundingFee,
    address _tpToken,
    uint256 _marketIndex
  ) internal {
    IncreaseCollateralVars memory _vars;
    // SLOAD
    _vars.vaultStorage = VaultStorage(vaultStorage);
    _vars.vaultStorage = VaultStorage(vaultStorage);
    _vars.configStorage = ConfigStorage(configStorage);
    _vars.oracle = OracleMiddleware(_vars.configStorage.oracle());

    _vars.positionId = _positionId;
    _vars.subAccount = _subAccount;
    _vars.marketIndex = _marketIndex;

    // check unrealized pnl
    if (_unrealizedPnl > 0) {
      _vars.unrealizedPnlToBeReceived = uint256(_unrealizedPnl);
      emit LogReceivedUnRealizedPnlValue(
        _vars.positionId,
        _vars.marketIndex,
        _vars.subAccount,
        _vars.unrealizedPnlToBeReceived
      );
    }
    // check funding fee
    if (_fundingFee < 0) {
      _vars.fundingFeeToBeReceived = uint256(-_fundingFee);
      emit LogReceivedFundingFeeValue(
        _vars.positionId,
        _vars.marketIndex,
        _vars.subAccount,
        _vars.fundingFeeToBeReceived
      );
    }

    // Pay trader with selected tp token
    {
      if (_tpToken != address(0)) {
        ConfigStorage.AssetConfig memory _assetConfig = _vars.configStorage.getAssetConfigByToken(_tpToken);
        _vars.tokenDecimal = _assetConfig.decimals;
        _vars.token = _assetConfig.tokenAddress;

        (_vars.tokenPrice, ) = _vars.oracle.getLatestPrice(_assetConfig.assetId, false);
        _vars.payerBalance = _vars.vaultStorage.hlpLiquidity(_assetConfig.tokenAddress);

        // get profit from hlp
        _increaseCollateralWithUnrealizedPnlFromHlp(_vars);
      }
    }

    bytes32[] memory _hlpAssetIds = _vars.configStorage.getHlpAssetIds();
    uint256 _len = _hlpAssetIds.length;
    {
      // loop for get fee from fee reserve
      for (uint256 i = 0; i < _len; ) {
        ConfigStorage.AssetConfig memory _assetConfig = _vars.configStorage.getAssetConfig(_hlpAssetIds[i]);
        _vars.tokenDecimal = _assetConfig.decimals;
        _vars.token = _assetConfig.tokenAddress;
        (_vars.tokenPrice, ) = _vars.oracle.getLatestPrice(_assetConfig.assetId, false);

        _vars.payerBalance = _vars.vaultStorage.fundingFeeReserve(_assetConfig.tokenAddress);

        // get fee from fee reserve
        _increaseCollateralWithFundingFeeFromFeeReserve(_vars);

        unchecked {
          ++i;
        }
      }
    }
    {
      // loop for get fee and profit from hlp
      for (uint256 i = 0; i < _len; ) {
        ConfigStorage.AssetConfig memory _assetConfig = _vars.configStorage.getAssetConfig(_hlpAssetIds[i]);
        _vars.tokenDecimal = _assetConfig.decimals;
        _vars.token = _assetConfig.tokenAddress;
        (_vars.tokenPrice, ) = _vars.oracle.getLatestPrice(_assetConfig.assetId, false);

        _vars.payerBalance = _vars.vaultStorage.hlpLiquidity(_assetConfig.tokenAddress);

        // get profit from hlp
        _increaseCollateralWithUnrealizedPnlFromHlp(_vars);
        // get fee from hlp
        _increaseCollateralWithFundingFeeFromHlp(_vars);

        unchecked {
          ++i;
        }
      }
    }
  }

  function _increaseCollateralWithUnrealizedPnlFromHlp(IncreaseCollateralVars memory _vars) internal {
    if (_vars.payerBalance > 0 && _vars.unrealizedPnlToBeReceived > 0) {
      // We are going to deduct funding fee balance,
      // so we need to check whether funding fee has this collateral token or not.
      // If not skip to next token
      (uint256 _repayAmount, uint256 _repayValue) = _getRepayAmount(
        _vars.payerBalance,
        _vars.unrealizedPnlToBeReceived,
        _vars.tokenPrice,
        _vars.tokenDecimal
      );

      // Calculate for settlement fee
      uint256 _settlementFeeRate = calculator.getSettlementFeeRate(_vars.token, _repayValue);
      uint256 _settlementFeeAmount = (_repayAmount * _settlementFeeRate) / 1e18;
      uint256 _settlementFeeValue = (_repayValue * _settlementFeeRate) / 1e18;

      // book the balances
      _vars.vaultStorage.payTraderProfit(_vars.subAccount, _vars.token, _repayAmount, _settlementFeeAmount);

      emit LogSettleSettlementFeeAmount(
        _vars.positionId,
        _vars.marketIndex,
        _vars.subAccount,
        _vars.token,
        _settlementFeeValue,
        _settlementFeeAmount
      );

      // deduct _vars.unrealizedPnlToBeReceived with _repayAmount, so that the next iteration could continue deducting the fee
      _vars.unrealizedPnlToBeReceived -= _repayValue;
      _vars.payerBalance -= _repayAmount;

      emit LogReceivedUnRealizedPnlAmount(
        _vars.positionId,
        _vars.marketIndex,
        _vars.subAccount,
        _vars.token,
        _repayValue,
        _repayAmount
      );
    }
  }

  function _increaseCollateralWithFundingFeeFromFeeReserve(IncreaseCollateralVars memory _vars) internal {
    if (_vars.payerBalance > 0 && _vars.fundingFeeToBeReceived > 0) {
      // We are going to deduct funding fee balance,
      // so we need to check whether funding fee has this collateral token or not.
      // If not skip to next token
      (uint256 _repayAmount, uint256 _repayValue) = _getRepayAmount(
        _vars.payerBalance,
        _vars.fundingFeeToBeReceived,
        _vars.tokenPrice,
        _vars.tokenDecimal
      );

      // book the balances
      _vars.vaultStorage.payFundingFeeFromFundingFeeReserveToTrader(_vars.subAccount, _vars.token, _repayAmount);

      // deduct _vars.absFundingFeeToBePaid with _repayAmount, so that the next iteration could continue deducting the fee
      _vars.fundingFeeToBeReceived -= _repayValue;

      emit LogReceivedFundingFeeAmount(
        _vars.positionId,
        _vars.marketIndex,
        _vars.subAccount,
        _vars.token,
        _repayValue,
        _repayAmount
      );
    }
  }

  function _increaseCollateralWithFundingFeeFromHlp(IncreaseCollateralVars memory _vars) internal {
    if (_vars.payerBalance > 0 && _vars.fundingFeeToBeReceived > 0) {
      // We are going to deduct hlp liquidity balance,
      // so we need to check whether hlp has this collateral token or not.
      // If not skip to next token
      (uint256 _repayAmount, uint256 _repayValue) = _getRepayAmount(
        _vars.payerBalance,
        _vars.fundingFeeToBeReceived,
        _vars.tokenPrice,
        _vars.tokenDecimal
      );
      // book the balances
      _vars.vaultStorage.borrowFundingFeeFromHlpToTrader(_vars.subAccount, _vars.token, _repayAmount, _repayValue);

      // deduct _vars.absFundingFeeToBePaid with _repayAmount, so that the next iteration could continue deducting the fee
      _vars.fundingFeeToBeReceived -= _repayValue;
      _vars.payerBalance -= _repayAmount;

      emit LogReceivedFundingFeeAmount(
        _vars.positionId,
        _vars.marketIndex,
        _vars.subAccount,
        _vars.token,
        _repayValue,
        _repayAmount
      );
    }
  }

  function _decreaseCollateral(
    bytes32 _positionId,
    address _subAccount,
    int256 _unrealizedPnl,
    int256 _fundingFee,
    uint256 _borrowingFee,
    uint256 _tradingFee,
    uint256 _liquidationFee,
    address _liquidator,
    uint256 _marketIndex
  ) internal {
    DecreaseCollateralVars memory _vars;

    _vars.vaultStorage = VaultStorage(vaultStorage);
    _vars.configStorage = ConfigStorage(configStorage);
    _vars.oracle = OracleMiddleware(_vars.configStorage.oracle());
    _vars.tradingConfig = _vars.configStorage.getTradingConfig();

    _vars.positionId = _positionId;
    _vars.subAccount = _subAccount;
    _vars.marketIndex = _marketIndex;

    bytes32[] memory _hlpAssetIds = _vars.configStorage.getHlpAssetIds();
    uint256 _len = _hlpAssetIds.length;

    // check loss
    if (_unrealizedPnl < 0) {
      emit LogSettleUnRealizedPnlValue(_vars.positionId, _vars.marketIndex, _vars.subAccount, uint256(-_unrealizedPnl));
      _vars.vaultStorage.addLossDebt(_subAccount, uint256(-_unrealizedPnl));
    }
    _vars.unrealizedPnlToBePaid = _vars.vaultStorage.lossDebt(_subAccount);

    // check trading fee
    _vars.vaultStorage.addTradingFeeDebt(_subAccount, _tradingFee);
    _vars.tradingFeeToBePaid = _vars.vaultStorage.tradingFeeDebt(_subAccount);

    // check borrowing fee
    _vars.vaultStorage.addBorrowingFeeDebt(_subAccount, _borrowingFee);
    _vars.borrowingFeeToBePaid = _vars.vaultStorage.borrowingFeeDebt(_subAccount);

    // check funding fee
    if (_fundingFee > 0) {
      emit LogSettleFundingFeeValue(_vars.positionId, _vars.marketIndex, _vars.subAccount, uint256(_fundingFee));
      _vars.vaultStorage.addFundingFeeDebt(_subAccount, uint256(_fundingFee));
    }
    _vars.fundingFeeToBePaid = _vars.vaultStorage.fundingFeeDebt(_subAccount);

    // check liquidation fee
    _vars.liquidationFeeToBePaid = _liquidationFee;

    emit LogSettleTradingFeeValue(_vars.positionId, _vars.marketIndex, _vars.subAccount, _tradingFee);
    emit LogSettleBorrowingFeeValue(_vars.positionId, _vars.marketIndex, _vars.subAccount, _borrowingFee);
    emit LogSettleLiquidationFeeValue(_vars.positionId, _vars.marketIndex, _vars.subAccount, _liquidationFee);

    // loop for settle
    for (uint256 i = 0; i < _len; ) {
      ConfigStorage.AssetConfig memory _assetConfig = _vars.configStorage.getAssetConfig(_hlpAssetIds[i]);
      _vars.tokenDecimal = _assetConfig.decimals;
      _vars.token = _assetConfig.tokenAddress;
      (_vars.tokenPrice, ) = _vars.oracle.getLatestPrice(_assetConfig.assetId, false);

      _vars.payerBalance = _vars.vaultStorage.traderBalances(_vars.subAccount, _vars.token);
      _vars.hlpDebt = _vars.vaultStorage.hlpLiquidityDebtUSDE30();
      // settle liquidation fee
      _decreaseCollateralWithLiquidationFee(_vars, _liquidator);
      // settle borrowing fee
      _decreaseCollateralWithBorrowingFeeToHlp(_vars);
      // settle trading fee
      _decreaseCollateralWithTradingFeeToProtocolFee(_vars);
      // settle funding fee to hlp
      _decreaseCollateralWithFundingFeeToHlp(_vars);
      // settle funding fee to fee reserve
      _decreaseCollateralWithFundingFeeToFeeReserve(_vars);
      // settle loss fee
      _decreaseCollateralWithUnrealizedPnlToHlp(_vars);

      unchecked {
        ++i;
      }
    }
  }

  function _decreaseCollateralWithUnrealizedPnlToHlp(DecreaseCollateralVars memory _vars) internal {
    if (_vars.payerBalance > 0 && _vars.unrealizedPnlToBePaid > 0) {
      (uint256 _repayAmount, uint256 _repayValue) = _getRepayAmount(
        _vars.payerBalance,
        _vars.unrealizedPnlToBePaid,
        _vars.tokenPrice,
        _vars.tokenDecimal
      );
      VaultStorage(_vars.vaultStorage).payHlp(_vars.subAccount, _vars.token, _repayAmount);

      _vars.unrealizedPnlToBePaid -= _repayValue;
      _vars.payerBalance -= _repayAmount;

      _vars.vaultStorage.subLossDebt(_vars.subAccount, _repayValue);

      emit LogSettleUnRealizedPnlAmount(
        _vars.positionId,
        _vars.marketIndex,
        _vars.subAccount,
        _vars.token,
        _repayValue,
        _repayAmount
      );
    }
  }

  function _decreaseCollateralWithFundingFeeToHlp(DecreaseCollateralVars memory _vars) internal {
    // If absFundingFeeToBePaid is less than borrowing debts from HLP, Then Trader repay with all current collateral amounts to HLP
    // Else Trader repay with just enough current collateral amounts to HLP
    if (_vars.payerBalance > 0 && _vars.fundingFeeToBePaid > 0 && _vars.hlpDebt > 0) {
      // Trader repay with just enough current collateral amounts to HLP
      (uint256 _repayAmount, uint256 _repayValue) = _getRepayAmount(
        _vars.payerBalance,
        _vars.fundingFeeToBePaid > _vars.hlpDebt ? _vars.hlpDebt : _vars.fundingFeeToBePaid,
        _vars.tokenPrice,
        _vars.tokenDecimal
      );
      // book the balances
      _vars.vaultStorage.repayFundingFeeDebtFromTraderToHlp(_vars.subAccount, _vars.token, _repayAmount, _repayValue);

      // deduct _vars.absFundingFeeToBePaid with _repayAmount, so that the next iteration could continue deducting the fee
      _vars.fundingFeeToBePaid -= _repayValue;
      _vars.payerBalance -= _repayAmount;

      _vars.vaultStorage.subFundingFeeDebt(_vars.subAccount, _repayValue);

      emit LogSettleFundingFeeAmount(
        _vars.positionId,
        _vars.marketIndex,
        _vars.subAccount,
        _vars.token,
        _repayValue,
        _repayAmount
      );
    }
  }

  function _decreaseCollateralWithFundingFeeToFeeReserve(DecreaseCollateralVars memory _vars) internal {
    if (_vars.payerBalance > 0 && _vars.fundingFeeToBePaid > 0) {
      // We are going to deduct trader balance,
      // so we need to check whether trader has this collateral token or not.
      // If not skip to next token
      (uint256 _repayAmount, uint256 _repayValue) = _getRepayAmount(
        _vars.payerBalance,
        _vars.fundingFeeToBePaid,
        _vars.tokenPrice,
        _vars.tokenDecimal
      );
      // book the balances
      _vars.vaultStorage.payFundingFeeFromTraderToFundingFeeReserve(_vars.subAccount, _vars.token, _repayAmount);

      // deduct _vars.absFundingFeeToBePaid with _repayAmount, so that the next iteration could continue deducting the fee
      _vars.fundingFeeToBePaid -= _repayValue;
      _vars.payerBalance -= _repayAmount;

      _vars.vaultStorage.subFundingFeeDebt(_vars.subAccount, _repayValue);

      emit LogSettleFundingFeeAmount(
        _vars.positionId,
        _vars.marketIndex,
        _vars.subAccount,
        _vars.token,
        _repayValue,
        _repayAmount
      );
    }
  }

  function _decreaseCollateralWithTradingFeeToProtocolFee(DecreaseCollateralVars memory _vars) internal {
    if (_vars.payerBalance > 0 && _vars.tradingFeeToBePaid > 0) {
      (uint256 _repayAmount, uint256 _repayValue) = _getRepayAmount(
        _vars.payerBalance,
        _vars.tradingFeeToBePaid,
        _vars.tokenPrice,
        _vars.tokenDecimal
      );
      // devFee = tradingFee * devFeeRate
      uint256 _devFeeAmount = (_repayAmount * _vars.tradingConfig.devFeeRateBPS) / BPS;
      // the rest after dev fee deduction belongs to protocol fee portion
      uint256 _protocolFeeAmount = _repayAmount - _devFeeAmount;

      // book those moving balances
      _vars.vaultStorage.payTradingFee(_vars.subAccount, _vars.token, _devFeeAmount, _protocolFeeAmount);

      // deduct _vars.tradingFeeToBePaid with _repayAmount, so that the next iteration could continue deducting the fee
      _vars.tradingFeeToBePaid -= _repayValue;
      _vars.payerBalance -= _repayAmount;

      _vars.vaultStorage.subTradingFeeDebt(_vars.subAccount, _repayValue);

      emit LogSettleTradingFeeAmount(
        _vars.positionId,
        _vars.marketIndex,
        _vars.subAccount,
        _vars.token,
        _repayValue,
        _devFeeAmount,
        _protocolFeeAmount
      );
    }
  }

  function _decreaseCollateralWithBorrowingFeeToHlp(DecreaseCollateralVars memory _vars) internal {
    if (_vars.payerBalance > 0 && _vars.borrowingFeeToBePaid > 0) {
      (uint256 _repayAmount, uint256 _repayValue) = _getRepayAmount(
        _vars.payerBalance,
        _vars.borrowingFeeToBePaid,
        _vars.tokenPrice,
        _vars.tokenDecimal
      );
      // devFee = tradingFee * devFeeRate
      uint256 _devFeeAmount = (_repayAmount * _vars.tradingConfig.devFeeRateBPS) / BPS;
      // the rest after dev fee deduction belongs to hlp liquidity
      uint256 _hlpFeeAmount = _repayAmount - _devFeeAmount;

      // book those moving balances
      _vars.vaultStorage.payBorrowingFee(_vars.subAccount, _vars.token, _devFeeAmount, _hlpFeeAmount);

      // deduct _vars.tradingFeeToBePaid with _repayAmount, so that the next iteration could continue deducting the fee
      _vars.borrowingFeeToBePaid -= _repayValue;
      _vars.payerBalance -= _repayAmount;

      _vars.vaultStorage.subBorrowingFeeDebt(_vars.subAccount, _repayValue);

      emit LogSettleBorrowingFeeAmount(
        _vars.positionId,
        _vars.marketIndex,
        _vars.subAccount,
        _vars.token,
        _repayValue,
        _devFeeAmount,
        _hlpFeeAmount
      );
    }
  }

  function _decreaseCollateralWithLiquidationFee(DecreaseCollateralVars memory _vars, address _liquidator) internal {
    if (_vars.payerBalance > 0 && _vars.liquidationFeeToBePaid > 0) {
      (uint256 _repayAmount, uint256 _repayValue) = _getRepayAmount(
        _vars.payerBalance,
        _vars.liquidationFeeToBePaid,
        _vars.tokenPrice,
        _vars.tokenDecimal
      );
      _vars.vaultStorage.transfer(_vars.token, _vars.subAccount, _liquidator, _repayAmount);

      _vars.liquidationFeeToBePaid -= _repayValue;
      _vars.payerBalance -= _repayAmount;

      emit LogSettleLiquidationFeeAmount(
        _vars.positionId,
        _vars.marketIndex,
        _vars.subAccount,
        _vars.token,
        _repayValue,
        _repayAmount
      );
    }
  }

  function _getRepayAmount(
    uint256 _payerBalance,
    uint256 _valueE30,
    uint256 _tokenPrice,
    uint8 _tokenDecimal
  ) internal pure returns (uint256 _repayAmount, uint256 _repayValueE30) {
    uint256 _feeAmount = (_valueE30 * (10 ** _tokenDecimal)) / _tokenPrice;

    if (_payerBalance > _feeAmount) {
      // _payerBalance can cover the rest of the fee
      return (_feeAmount, _valueE30);
    } else {
      // _payerBalance cannot cover the rest of the fee, just take the amount the trader have
      uint256 _payerBalanceValue = (_payerBalance * _tokenPrice) / (10 ** _tokenDecimal);
      return (_payerBalance, _payerBalanceValue);
    }
  }

  function _updateAccumFundingLong(uint256 _marketIndex, int256 fundingLong) internal {
    PerpStorage _perpStorage = PerpStorage(perpStorage);
    PerpStorage.Market memory _market = _perpStorage.getMarketByIndex(_marketIndex);

    _market.accumFundingLong += fundingLong;
    _perpStorage.updateMarket(_marketIndex, _market);
  }

  function _updateAccumFundingShort(uint256 _marketIndex, int256 fundingShort) internal {
    PerpStorage _perpStorage = PerpStorage(perpStorage);
    PerpStorage.Market memory _market = _perpStorage.getMarketByIndex(_marketIndex);

    _market.accumFundingShort += fundingShort;
    _perpStorage.updateMarket(_marketIndex, _market);
  }

  /**
   * Setter
   */
  /// @notice Set new ConfigStorage contract address.
  /// @param _configStorage New ConfigStorage contract address.
  function setConfigStorage(address _configStorage) external nonReentrant onlyOwner {
    if (_configStorage == address(0)) revert ITradeHelper_InvalidAddress();
    emit LogSetConfigStorage(configStorage, _configStorage);
    configStorage = _configStorage;

    // Sanity check
    ConfigStorage(_configStorage).calculator();
  }

  /// @notice Set new VaultStorage contract address.
  /// @param _vaultStorage New VaultStorage contract address.
  function setVaultStorage(address _vaultStorage) external nonReentrant onlyOwner {
    if (_vaultStorage == address(0)) revert ITradeHelper_InvalidAddress();

    emit LogSetVaultStorage(vaultStorage, _vaultStorage);
    vaultStorage = _vaultStorage;

    // Sanity check
    VaultStorage(_vaultStorage).devFees(address(0));
  }

  /// @notice Set new PerpStorage contract address.
  /// @param _perpStorage New PerpStorage contract address.
  function setPerpStorage(address _perpStorage) external nonReentrant onlyOwner {
    if (_perpStorage == address(0)) revert ITradeHelper_InvalidAddress();

    emit LogSetPerpStorage(perpStorage, _perpStorage);
    perpStorage = _perpStorage;

    // Sanity check
    PerpStorage(_perpStorage).getGlobalState();
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title Contains 512-bit math functions
 * @notice Facilitates multiplication and division
 *              that can have overflow of an intermediate value without any loss of precision
 * @dev Handles "phantom overflow" i.e.,
 *      allows multiplication and division where an intermediate value overflows 256 bits
 */

library FullMath {
  /**
   * @notice Calculates floor(x * y / denominator) with full precision.
   *           Throws if result overflows a uint256 or denominator == 0
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

      // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
      // Always >= 1.
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

      // Use the Newton-Raphson iteration to improve the precision.
      // Thanks to Hensel's lifting lemma, this also works
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
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
//

pragma solidity 0.8.18;

library HMXLib {
  error HMXLib_WrongSubAccountId();

  function getSubAccount(address _primary, uint8 _subAccountId) internal pure returns (address _subAccount) {
    if (_subAccountId > 255) revert HMXLib_WrongSubAccountId();
    return address(uint160(_primary) ^ uint160(_subAccountId));
  }

  function max(int256 a, int256 b) internal pure returns (int256) {
    return a > b ? a : b;
  }

  function min(int256 a, int256 b) internal pure returns (int256) {
    return a < b ? a : b;
  }

  function min(uint256 x, uint256 y) internal pure returns (uint256) {
    return x < y ? x : y;
  }

  function abs(int256 x) internal pure returns (uint256) {
    return uint256(x >= 0 ? x : -x);
  }

  /// @notice Derive positionId from sub-account and market index
  function getPositionId(address _subAccount, uint256 _marketIndex) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_subAccount, _marketIndex));
  }
}

// SPDX-License-Identifier: MIT
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
//

pragma solidity 0.8.18;

interface IOracleAdapter {
  function getLatestPrice(
    bytes32 _assetId,
    bool _isMax,
    uint32 _confidenceThreshold
  ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
//

pragma solidity 0.8.18;

interface IOracleMiddleware {
  // errors
  error IOracleMiddleware_PriceStale();
  error IOracleMiddleware_MarketStatusUndefined();
  error IOracleMiddleware_OnlyUpdater();
  error IOracleMiddleware_InvalidMarketStatus();
  error IOracleMiddleware_InvalidValue();

  function isUpdater(address _updater) external returns (bool);

  function assetPriceConfigs(bytes32 _assetId) external returns (uint32, uint32, address);

  function marketStatus(bytes32 _assetId) external returns (uint8);

  function getLatestPrice(bytes32 _assetId, bool _isMax) external view returns (uint256 _price, uint256 _lastUpdated);

  function getLatestPriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax
  ) external view returns (uint256 _price, uint256 _lastUpdated, uint8 _status);

  function getLatestAdaptivePrice(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD,
    uint256 _limitPriceE30
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate);

  function unsafeGetLatestAdaptivePrice(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD,
    uint256 _limitPriceE30
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate);

  function getLatestAdaptivePriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD,
    uint256 _limitPriceE30
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate, uint8 _status);

  function unsafeGetLatestAdaptivePriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD,
    uint256 _limitPriceE30
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate, uint8 _status);

  // =========================================
  // | ---------- Setter ------------------- |
  // =========================================

  function unsafeGetLatestPrice(
    bytes32 _assetId,
    bool _isMax
  ) external view returns (uint256 _price, uint256 _lastUpdated);

  function unsafeGetLatestPriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax
  ) external view returns (uint256 _price, uint256 _lastUpdated, uint8 _status);

  function setMarketStatus(bytes32 _assetId, uint8 _status) external;

  function setUpdater(address _updater, bool _isActive) external;

  function setAssetPriceConfig(
    bytes32 _assetId,
    uint32 _confidenceThresholdE6,
    uint32 _trustPriceAge,
    address _adapter
  ) external;

  function setMultipleMarketStatus(bytes32[] memory _assetIds, uint8[] memory _statuses) external;
}

// SPDX-License-Identifier: MIT
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
//

pragma solidity 0.8.18;

import { IReadablePyth } from "./IReadablePyth.sol";
import { IOracleAdapter } from "./IOracleAdapter.sol";

interface IPythAdapter is IOracleAdapter {
  struct PythPriceConfig {
    /// @dev Price id defined by Pyth.
    bytes32 pythPriceId;
    /// @dev If true, return final price as `1/price`. This config intend to support thr price pair like USD/JPY (invert USD quote).
    bool inverse;
  }

  function pyth() external returns (IReadablePyth);

  function setConfig(bytes32 _assetId, bytes32 _pythPriceId, bool _inverse) external;

  function configs(bytes32 _assetId) external view returns (bytes32 _pythPriceId, bool _inverse);

  function getConfigByAssetId(bytes32 _assetId) external view returns (PythPriceConfig memory);
}

// SPDX-License-Identifier: MIT
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
//

pragma solidity 0.8.18;

import { IPyth, PythStructs, IPythEvents } from "lib/pyth-sdk-solidity/IPyth.sol";

interface IReadablePyth {
  function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
//

pragma solidity 0.8.18;

import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { SafeCastUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/utils/math/SafeCastUpgradeable.sol";
import { IOracleMiddleware } from "./interfaces/IOracleMiddleware.sol";
import { IPythAdapter } from "./interfaces/IPythAdapter.sol";
import { IOracleAdapter } from "./interfaces/IOracleAdapter.sol";

contract OracleMiddleware is OwnableUpgradeable, IOracleMiddleware {
  using SafeCastUpgradeable for uint256;
  using SafeCastUpgradeable for int256;

  /**
   * Structs
   */
  struct AssetPriceConfig {
    /// @dev Acceptable price age in second.
    uint32 trustPriceAge;
    /// @dev The acceptable threshold confidence ratio. ex. _confidenceRatio = 0.01 ether means 1%
    uint32 confidenceThresholdE6;
    /// @dev asset oracle adapter (ex. StakedGLPOracleAdapter, PythAdapter)
    address adapter;
  }

  /**
   * Events
   */
  event LogSetMarketStatus(bytes32 indexed _assetId, uint8 _status);
  event LogSetUpdater(address indexed _account, bool _isActive);
  event LogSetAssetPriceConfig(
    bytes32 indexed _assetId,
    uint32 _oldConfidenceThresholdE6,
    uint32 _newConfidenceThresholdE6,
    uint256 _oldTrustPriceAge,
    uint256 _newTrustPriceAge,
    address _oldAdapter,
    address _newAdapter
  );
  event LogSetAdapter(address oldPythAdapter, address newPythAdapter);
  event LogSetMaxTrustPriceAge(uint256 oldValue, uint256 newValue);
  /**
   * States
   */

  // whitelist mapping of market status updater
  mapping(address => bool) public isUpdater;
  mapping(bytes32 => AssetPriceConfig) public assetPriceConfigs;

  // states
  // MarketStatus
  // Note from Pyth doc: Only prices with a value of status=trading should be used. If the status is not trading but is
  // Unknown, Halted or Auction the Pyth price can be an arbitrary value.
  // https://docs.pyth.network/design-overview/account-structure
  //
  // 0 = Undefined, default state since contract init
  // 1 = Inactive, equivalent to `unknown`, `halted`, `auction`, `ignored` from Pyth
  // 2 = Active, equivalent to `trading` from Pyth
  // assetId => marketStatus
  mapping(bytes32 => uint8) public marketStatus;
  uint256 maxTrustPriceAge;

  /**
   * Modifiers
   */

  modifier onlyUpdater() {
    if (!isUpdater[msg.sender]) {
      revert IOracleMiddleware_OnlyUpdater();
    }
    _;
  }

  function initialize(uint256 _maxTrustPriceAge) external initializer {
    OwnableUpgradeable.__Ownable_init();
    maxTrustPriceAge = _maxTrustPriceAge;
  }

  /// @notice Return the latest price and last update of the given asset id.
  /// @dev It is expected that the downstream contract should return the price in USD with 30 decimals.
  /// @dev The currency of the price that will be quoted with depends on asset id. For example, we can have two BTC price but quoted differently.
  ///      In that case, we can define two different asset ids as BTC/USD, BTC/EUR.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  function getLatestPrice(bytes32 _assetId, bool _isMax) external view returns (uint256 _price, uint256 _lastUpdate) {
    (_price, _lastUpdate) = _getLatestPrice(_assetId, _isMax);

    return (_price, _lastUpdate);
  }

  /// @notice Return the latest price and last update of the given asset id.
  /// @dev Same as getLatestPrice(), but unsafe function has no check price age
  /// @dev It is expected that the downstream contract should return the price in USD with 30 decimals.
  /// @dev The currency of the price that will be quoted with depends on asset id. For example, we can have two BTC price but quoted differently.
  ///      In that case, we can define two different asset ids as BTC/USD, BTC/EUR.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  function unsafeGetLatestPrice(
    bytes32 _assetId,
    bool _isMax
  ) external view returns (uint256 _price, uint256 _lastUpdate) {
    (_price, _lastUpdate) = _unsafeGetLatestPrice(_assetId, _isMax);

    return (_price, _lastUpdate);
  }

  /// @notice Return the latest price of asset, last update of the given asset id, along with market status.
  /// @dev Same as getLatestPrice(), but with market status. Revert if status is 0 (Undefined) which means we never utilize this assetId.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  function getLatestPriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax
  ) external view returns (uint256 _price, uint256 _lastUpdate, uint8 _status) {
    _status = marketStatus[_assetId];
    if (_status == 0) revert IOracleMiddleware_MarketStatusUndefined();

    (_price, _lastUpdate) = _getLatestPrice(_assetId, _isMax);

    return (_price, _lastUpdate, _status);
  }

  /// @notice Return the latest price of asset, last update of the given asset id, along with market status.
  /// @dev Same as unsafeGetLatestPrice(), but with market status. Revert if status is 0 (Undefined) which means we never utilize this assetId.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  function unsafeGetLatestPriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax
  ) external view returns (uint256 _price, uint256 _lastUpdate, uint8 _status) {
    _status = marketStatus[_assetId];
    if (_status == 0) revert IOracleMiddleware_MarketStatusUndefined();

    (_price, _lastUpdate) = _unsafeGetLatestPrice(_assetId, _isMax);

    return (_price, _lastUpdate, _status);
  }

  /// @notice Return the latest adaptive rice of asset, last update of the given asset id
  /// @dev Adaptive price is the price that is applied with premium or discount based on the market skew.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  /// @param _marketSkew market skew quoted in asset (NOT USD)
  /// @param _sizeDelta The size delta of this operation. It will determine the new market skew to be used for calculation.
  /// @param _maxSkewScaleUSD The config of maxSkewScaleUSD
  /// @param _limitPriceE30 The limit price to override the current Oracle Price [OBSOLETED]
  function getLatestAdaptivePrice(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD,
    uint256 _limitPriceE30
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate) {
    (_adaptivePrice, _lastUpdate) = _getLatestAdaptivePrice(
      _assetId,
      _isMax,
      _marketSkew,
      _sizeDelta,
      _maxSkewScaleUSD,
      true,
      _limitPriceE30
    );
    return (_adaptivePrice, _lastUpdate);
  }

  /// @notice Return the unsafe latest adaptive rice of asset, last update of the given asset id
  /// @dev Adaptive price is the price that is applied with premium or discount based on the market skew.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  /// @param _marketSkew market skew quoted in asset (NOT USD)
  /// @param _sizeDelta The size delta of this operation. It will determine the new market skew to be used for calculation.
  /// @param _maxSkewScaleUSD The config of maxSkewScaleUSD
  /// @param _limitPriceE30 The limit price to override the current Oracle Price [OBSOLETED]
  function unsafeGetLatestAdaptivePrice(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD,
    uint256 _limitPriceE30
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate) {
    (_adaptivePrice, _lastUpdate) = _getLatestAdaptivePrice(
      _assetId,
      _isMax,
      _marketSkew,
      _sizeDelta,
      _maxSkewScaleUSD,
      false,
      _limitPriceE30
    );
    return (_adaptivePrice, _lastUpdate);
  }

  /// @notice Return the latest adaptive rice of asset, last update of the given asset id, along with market status.
  /// @dev Adaptive price is the price that is applied with premium or discount based on the market skew.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  /// @param _marketSkew market skew quoted in asset (NOT USD)
  /// @param _sizeDelta The size delta of this operation. It will determine the new market skew to be used for calculation.
  /// @param _maxSkewScaleUSD The config of maxSkewScaleUSD
  /// @param _limitPriceE30 The limit price to override the current Oracle Price [OBSOLETED]
  function getLatestAdaptivePriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD,
    uint256 _limitPriceE30
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate, uint8 _status) {
    _status = marketStatus[_assetId];
    if (_status == 0) revert IOracleMiddleware_MarketStatusUndefined();

    (_adaptivePrice, _lastUpdate) = _getLatestAdaptivePrice(
      _assetId,
      _isMax,
      _marketSkew,
      _sizeDelta,
      _maxSkewScaleUSD,
      true,
      _limitPriceE30
    );
    return (_adaptivePrice, _lastUpdate, _status);
  }

  /// @notice Return the latest adaptive rice of asset, last update of the given asset id, along with market status.
  /// @dev Adaptive price is the price that is applied with premium or discount based on the market skew.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  /// @param _marketSkew market skew quoted in asset (NOT USD)
  /// @param _sizeDelta The size delta of this operation. It will determine the new market skew to be used for calculation.
  /// @param _maxSkewScaleUSD The config of maxSkewScaleUSD
  /// @param _limitPriceE30 The limit price to override the current Oracle Price [OBSOLETED]
  function unsafeGetLatestAdaptivePriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD,
    uint256 _limitPriceE30
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate, uint8 _status) {
    _status = marketStatus[_assetId];
    if (_status == 0) revert IOracleMiddleware_MarketStatusUndefined();

    (_adaptivePrice, _lastUpdate) = _getLatestAdaptivePrice(
      _assetId,
      _isMax,
      _marketSkew,
      _sizeDelta,
      _maxSkewScaleUSD,
      false,
      _limitPriceE30
    );
    return (_adaptivePrice, _lastUpdate, _status);
  }

  function _getLatestPrice(bytes32 _assetId, bool _isMax) private view returns (uint256 _price, uint256 _lastUpdate) {
    AssetPriceConfig memory _assetConfig = assetPriceConfigs[_assetId];

    // 1. get price from Pyth or chianlink depends on confidenceThresholdE6
    (_price, _lastUpdate) = IOracleAdapter(_assetConfig.adapter).getLatestPrice(
      _assetId,
      _isMax,
      _assetConfig.confidenceThresholdE6
    );

    // ignore check price age when market is closed
    if (marketStatus[_assetId] == 2 && block.timestamp - _lastUpdate > _assetConfig.trustPriceAge)
      revert IOracleMiddleware_PriceStale();

    // 2. Return the price and last update
    return (_price, _lastUpdate);
  }

  function _unsafeGetLatestPrice(
    bytes32 _assetId,
    bool _isMax
  ) private view returns (uint256 _price, uint256 _lastUpdate) {
    AssetPriceConfig memory _assetConfig = assetPriceConfigs[_assetId];

    // 1. get price from Pyth
    (_price, _lastUpdate) = IOracleAdapter(_assetConfig.adapter).getLatestPrice(
      _assetId,
      _isMax,
      _assetConfig.confidenceThresholdE6
    );

    // 2. Return the price and last update
    return (_price, _lastUpdate);
  }

  function _getLatestAdaptivePrice(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD,
    bool isSafe,
    uint256 _limitPriceE30
  ) private view returns (uint256 _adaptivePrice, uint256 _lastUpdate) {
    // Get price from Pyth
    uint256 _price;
    (_price, _lastUpdate) = isSafe ? _getLatestPrice(_assetId, _isMax) : _unsafeGetLatestPrice(_assetId, _isMax);

    if (_limitPriceE30 != 0) {
      _price = _limitPriceE30;
    }

    // Apply premium/discount
    _adaptivePrice = _calculateAdaptivePrice(_marketSkew, _sizeDelta, _price, _maxSkewScaleUSD);

    // Return the price and last update
    return (_adaptivePrice, _lastUpdate);
  }

  /// @notice Calculate adaptive base on Market skew by position size
  /// @param _marketSkew Long position size - Short position size
  /// @param _sizeDelta Position size delta
  /// @param _price Oracle price
  /// @param _maxSkewScaleUSD Config from Market config
  /// @return _adaptivePrice
  function _calculateAdaptivePrice(
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _price,
    uint256 _maxSkewScaleUSD
  ) internal pure returns (uint256 _adaptivePrice) {
    // couldn't calculate adaptive price because max skew scale config is used to calculate premium with market skew
    // then just return oracle price
    if (_maxSkewScaleUSD == 0) return _price;

    // Given
    //    Max skew scale = 300,000,000 USD
    //    Current Price  =       1,500 USD
    //    Given:
    //      Long Position size   = 1,000,000 USD
    //      Short Position size  =   700,000 USD
    //      then Market skew     = Long - Short = 300,000 USD
    //
    //    If Trader manipulate by Decrease Long position for 150,000 USD
    //    Then:
    //      Premium (before) = 300,000 / 300,000,000 = 0.001
    int256 _premium = (_marketSkew * 1e30) / int256(_maxSkewScaleUSD);

    //      Premium (after)  = (300,000 - 150,000) / 300,000,000 = 0.0005
    //      ** + When user increase Long position ot Decrease Short position
    //      ** - When user increase Short position ot Decrease Long position
    int256 _premiumAfter = ((_marketSkew + _sizeDelta) * 1e30) / int256(_maxSkewScaleUSD);

    //      Adaptive price = Price * (1 + Median of Before and After)
    //                     = 1,500 * (1 + (0.001 + 0.0005 / 2))
    //                     = 1,500 * (1 + 0.00125) = 1,501.875
    int256 _premiumMedian = (_premium + _premiumAfter) / 2;
    return (_price * uint256(1e30 + _premiumMedian)) / 1e30;
  }

  /// @notice Set asset price configs
  /// @param _assetId Asset's to set price config
  /// @param _confidenceThresholdE6 New price confidence threshold
  /// @param _trustPriceAge valid price age
  /// @param _adapter adapter of price Config (StakedGLPAdapter, PythAdapter)
  function setAssetPriceConfig(
    bytes32 _assetId,
    uint32 _confidenceThresholdE6,
    uint32 _trustPriceAge,
    address _adapter
  ) external onlyOwner {
    _setAssetPriceConfig(_assetId, _confidenceThresholdE6, _trustPriceAge, _adapter);
  }

  function setAssetPriceConfigs(
    bytes32[] calldata _assetIds,
    uint32[] calldata _confidenceThresholdE6s,
    uint32[] calldata _trustPriceAges,
    address[] calldata _adapters
  ) external onlyOwner {
    if (
      _assetIds.length != _confidenceThresholdE6s.length ||
      _assetIds.length != _trustPriceAges.length ||
      _assetIds.length != _adapters.length
    ) revert IOracleMiddleware_InvalidValue();

    for (uint256 i = 0; i < _assetIds.length; ) {
      _setAssetPriceConfig(_assetIds[i], _confidenceThresholdE6s[i], _trustPriceAges[i], _adapters[i]);
      unchecked {
        ++i;
      }
    }
  }

  function _setAssetPriceConfig(
    bytes32 _assetId,
    uint32 _confidenceThresholdE6,
    uint32 _trustPriceAge,
    address _adapter
  ) internal {
    if (_trustPriceAge > maxTrustPriceAge) revert IOracleMiddleware_InvalidValue();
    AssetPriceConfig memory _config = assetPriceConfigs[_assetId];
    emit LogSetAssetPriceConfig(
      _assetId,
      _config.confidenceThresholdE6,
      _confidenceThresholdE6,
      _config.trustPriceAge,
      _trustPriceAge,
      _config.adapter,
      _adapter
    );

    _config.confidenceThresholdE6 = _confidenceThresholdE6;
    _config.trustPriceAge = _trustPriceAge;
    _config.adapter = _adapter;

    assetPriceConfigs[_assetId] = _config;
  }

  /// @notice Set market status for the given asset.
  /// @param _assetId The asset address to set.
  /// @param _status Status enum, see `marketStatus` comment section.
  function setMarketStatus(bytes32 _assetId, uint8 _status) external onlyUpdater {
    _setMarketStatus(_assetId, _status);
  }

  /// @notice Set market status for the given asset.
  /// @param _assetId The asset address to set.
  /// @param _status Status enum, see `marketStatus` comment section.
  function _setMarketStatus(bytes32 _assetId, uint8 _status) internal {
    if (_status > 2) revert IOracleMiddleware_InvalidMarketStatus();

    marketStatus[_assetId] = _status;
    emit LogSetMarketStatus(_assetId, _status);
  }

  /// @notice Set market status for the given assets.
  /// @param _assetIds The asset addresses to set.
  /// @param _statuses Status enum, see `marketStatus` comment section.
  function setMultipleMarketStatus(bytes32[] memory _assetIds, uint8[] memory _statuses) external onlyUpdater {
    uint256 _len = _assetIds.length;
    for (uint256 _i = 0; _i < _len; ) {
      _setMarketStatus(_assetIds[_i], _statuses[_i]);
      unchecked {
        ++_i;
      }
    }
  }

  /// @notice A function for setting updater who is able to setMarketStatus
  function setUpdater(address _account, bool _isActive) external onlyOwner {
    isUpdater[_account] = _isActive;
    emit LogSetUpdater(_account, _isActive);
  }

  /// @notice setMaxTrustPriceAge
  /// @param _maxTrustPriceAge _maxTrustPriceAge in timestamp
  function setMaxTrustPriceAge(uint256 _maxTrustPriceAge) external onlyOwner {
    emit LogSetMaxTrustPriceAge(maxTrustPriceAge, _maxTrustPriceAge);
    maxTrustPriceAge = _maxTrustPriceAge;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
//

pragma solidity 0.8.18;

// Base
import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { ERC20Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { AddressUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/utils/AddressUpgradeable.sol";

// Interfaces
import { IConfigStorage } from "./interfaces/IConfigStorage.sol";
import { ICalculator } from "../contracts/interfaces/ICalculator.sol";
import { IOracleMiddleware } from "../oracles/interfaces/IOracleMiddleware.sol";

/// @title ConfigStorage
/// @notice storage contract to keep configs
contract ConfigStorage is IConfigStorage, OwnableUpgradeable {
  using SafeERC20Upgradeable for ERC20Upgradeable;
  using AddressUpgradeable for address;

  /**
   * Events
   */
  event LogSetServiceExecutor(address indexed contractAddress, address executorAddress, bool isServiceExecutor);
  event LogSetCalculator(address indexed oldCalculator, address newCalculator);
  event LogSetOracle(address indexed oldOracle, address newOracle);
  event LogSetHLP(address indexed oldHlp, address newHlp);
  event LogSetLiquidityConfig(LiquidityConfig indexed oldLiquidityConfig, LiquidityConfig newLiquidityConfig);
  event LogSetDynamicEnabled(bool enabled);
  event LogSetPnlFactor(uint32 oldPnlFactorBPS, uint32 newPnlFactorBPS);
  event LogSetSwapConfig(SwapConfig indexed oldConfig, SwapConfig newConfig);
  event LogSetTradingConfig(TradingConfig indexed oldConfig, TradingConfig newConfig);
  event LogSetLiquidationConfig(LiquidationConfig indexed oldConfig, LiquidationConfig newConfig);
  event LogSetMarketConfig(uint256 marketIndex, MarketConfig oldConfig, MarketConfig newConfig);
  event LogSetHlpTokenConfig(address token, HLPTokenConfig oldConfig, HLPTokenConfig newConfig);
  event LogSetCollateralTokenConfig(bytes32 assetId, CollateralTokenConfig oldConfig, CollateralTokenConfig newConfig);
  event LogSetAssetConfig(bytes32 assetId, AssetConfig oldConfig, AssetConfig newConfig);
  event LogSetToken(address indexed oldToken, address newToken);
  event LogSetAssetClassConfigByIndex(uint256 index, AssetClassConfig oldConfig, AssetClassConfig newConfig);
  event LogSetLiquidityEnabled(bool oldValue, bool newValue);
  event LogSetMinimumPositionSize(uint256 oldValue, uint256 newValue);
  event LogSetConfigExecutor(address indexed executorAddress, bool isServiceExecutor);
  event LogAddAssetClassConfig(uint256 index, AssetClassConfig newConfig);
  event LogAddMarketConfig(uint256 index, MarketConfig newConfig);
  event LogRemoveUnderlying(address token);
  event LogDelistMarket(uint256 marketIndex);
  event LogAddOrUpdateHLPTokenConfigs(address _token, HLPTokenConfig _config, HLPTokenConfig _newConfig);
  event LogSetTradeServiceHooks(address[] oldHooks, address[] newHooks);

  /**
   * Constants
   */
  uint256 public constant BPS = 1e4;
  uint256 public constant MAX_FEE_BPS = 0.3 * 1e4; // 30%

  /**
   * States
   */
  LiquidityConfig public liquidityConfig;
  SwapConfig public swapConfig;
  TradingConfig public tradingConfig;
  LiquidationConfig public liquidationConfig;

  mapping(address => bool) public allowedLiquidators; // allowed contract to execute liquidation service
  mapping(address => mapping(address => bool)) public serviceExecutors; // service => handler => isOK, to allowed executor for service layer

  address public calculator;
  address public oracle;
  address public hlp;
  address public treasury;
  uint32 public pnlFactorBPS; // factor that calculate unrealized PnL after collateral factor
  uint256 public minimumPositionSize;
  address public weth;
  address public sglp;

  // Token's address => Asset ID
  mapping(address => bytes32) public tokenAssetIds;
  // Asset ID => Configs
  mapping(bytes32 => AssetConfig) public assetConfigs;
  // HLP stuff
  bytes32[] public hlpAssetIds;
  mapping(bytes32 => HLPTokenConfig) public assetHlpTokenConfigs;
  // Cross margin
  bytes32[] public collateralAssetIds;
  mapping(bytes32 => CollateralTokenConfig) public assetCollateralTokenConfigs;
  // Trade
  MarketConfig[] public marketConfigs;
  AssetClassConfig[] public assetClassConfigs;
  address[] public tradeServiceHooks;

  mapping(address => bool) public configExecutors;

  /**
   * Modifiers
   */

  modifier onlyWhitelistedExecutor() {
    if (!configExecutors[msg.sender]) revert IConfigStorage_NotWhiteListed();
    _;
  }

  function initialize() external initializer {
    OwnableUpgradeable.__Ownable_init();
  }

  /**
   * Validations
   */
  /// @notice Validate only whitelisted executor contracts to be able to call Service contracts.
  /// @param _contractAddress Service contract address to be executed.
  /// @param _executorAddress Executor contract address to call service contract.
  function validateServiceExecutor(address _contractAddress, address _executorAddress) external view {
    if (!serviceExecutors[_contractAddress][_executorAddress]) revert IConfigStorage_NotWhiteListed();
  }

  function validateAcceptedLiquidityToken(address _token) external view {
    if (!assetHlpTokenConfigs[tokenAssetIds[_token]].accepted) revert IConfigStorage_NotAcceptedLiquidity();
  }

  /// @notice Validate only accepted token to be deposit/withdraw as collateral token.
  /// @param _token Token address to be deposit/withdraw.
  function validateAcceptedCollateral(address _token) external view {
    if (!assetCollateralTokenConfigs[tokenAssetIds[_token]].accepted) revert IConfigStorage_NotAcceptedCollateral();
  }

  /**
   * Getters
   */

  function getTradingConfig() external view returns (TradingConfig memory) {
    return tradingConfig;
  }

  function getMarketConfigByIndex(uint256 _index) external view returns (MarketConfig memory _marketConfig) {
    return marketConfigs[_index];
  }

  function getAssetClassConfigByIndex(
    uint256 _index
  ) external view returns (AssetClassConfig memory _assetClassConfig) {
    return assetClassConfigs[_index];
  }

  function getCollateralTokenConfigs(
    address _token
  ) external view returns (CollateralTokenConfig memory _collateralTokenConfig) {
    return assetCollateralTokenConfigs[tokenAssetIds[_token]];
  }

  function getAssetTokenDecimal(address _token) external view returns (uint8) {
    return assetConfigs[tokenAssetIds[_token]].decimals;
  }

  function getLiquidityConfig() external view returns (LiquidityConfig memory) {
    return liquidityConfig;
  }

  function getLiquidationConfig() external view returns (LiquidationConfig memory) {
    return liquidationConfig;
  }

  function getMarketConfigs() external view returns (MarketConfig[] memory) {
    return marketConfigs;
  }

  function getMarketConfigsLength() external view returns (uint256) {
    return marketConfigs.length;
  }

  function getAssetClassConfigsLength() external view returns (uint256) {
    return assetClassConfigs.length;
  }

  function getHlpTokens() external view returns (address[] memory) {
    address[] memory _result = new address[](hlpAssetIds.length);
    bytes32[] memory _hlpAssetIds = hlpAssetIds;

    uint256 len = _hlpAssetIds.length;
    for (uint256 _i = 0; _i < len; ) {
      _result[_i] = assetConfigs[_hlpAssetIds[_i]].tokenAddress;
      unchecked {
        ++_i;
      }
    }

    return _result;
  }

  function getAssetConfigByToken(address _token) external view returns (AssetConfig memory) {
    return assetConfigs[tokenAssetIds[_token]];
  }

  function getCollateralTokens() external view returns (address[] memory) {
    bytes32[] memory _collateralAssetIds = collateralAssetIds;
    mapping(bytes32 => AssetConfig) storage _assetConfigs = assetConfigs;

    uint256 _len = _collateralAssetIds.length;
    address[] memory tokenAddresses = new address[](_len);

    for (uint256 _i; _i < _len; ) {
      tokenAddresses[_i] = _assetConfigs[_collateralAssetIds[_i]].tokenAddress;

      unchecked {
        ++_i;
      }
    }
    return tokenAddresses;
  }

  function getAssetConfig(bytes32 _assetId) external view returns (AssetConfig memory) {
    return assetConfigs[_assetId];
  }

  function getAssetHlpTokenConfig(bytes32 _assetId) external view returns (HLPTokenConfig memory) {
    return assetHlpTokenConfigs[_assetId];
  }

  function getAssetHlpTokenConfigByToken(address _token) external view returns (HLPTokenConfig memory) {
    return assetHlpTokenConfigs[tokenAssetIds[_token]];
  }

  function getHlpAssetIds() external view returns (bytes32[] memory) {
    return hlpAssetIds;
  }

  function getTradeServiceHooks() external view returns (address[] memory) {
    return tradeServiceHooks;
  }

  /**
   * Setter
   */

  function setConfigExecutor(address _executorAddress, bool _isServiceExecutor) external onlyOwner {
    if (!_executorAddress.isContract()) revert IConfigStorage_InvalidAddress();
    configExecutors[_executorAddress] = _isServiceExecutor;
    emit LogSetConfigExecutor(_executorAddress, _isServiceExecutor);
  }

  function setMinimumPositionSize(uint256 _minimumPositionSize) external onlyOwner {
    emit LogSetMinimumPositionSize(minimumPositionSize, _minimumPositionSize);
    minimumPositionSize = _minimumPositionSize;
  }

  function setCalculator(address _calculator) external onlyOwner {
    emit LogSetCalculator(calculator, _calculator);
    calculator = _calculator;

    // Sanity check
    ICalculator(_calculator).getPendingBorrowingFeeE30();
  }

  function setOracle(address _oracle) external onlyOwner {
    emit LogSetOracle(oracle, _oracle);
    oracle = _oracle;

    // Sanity check
    IOracleMiddleware(_oracle).isUpdater(_oracle);
  }

  function setHLP(address _hlp) external onlyOwner {
    if (_hlp == address(0)) revert IConfigStorage_InvalidAddress();
    emit LogSetHLP(hlp, _hlp);

    hlp = _hlp;
  }

  function setLiquidityConfig(LiquidityConfig calldata _liquidityConfig) external onlyOwner {
    if (
      _liquidityConfig.taxFeeRateBPS > MAX_FEE_BPS ||
      _liquidityConfig.flashLoanFeeRateBPS > MAX_FEE_BPS ||
      _liquidityConfig.depositFeeRateBPS > MAX_FEE_BPS ||
      _liquidityConfig.withdrawFeeRateBPS > MAX_FEE_BPS
    ) revert IConfigStorage_MaxFeeBps();
    if (_liquidityConfig.maxHLPUtilizationBPS > BPS) revert IConfigStorage_ExceedLimitSetting();
    emit LogSetLiquidityConfig(liquidityConfig, _liquidityConfig);
    liquidityConfig = _liquidityConfig;

    uint256 hlpTotalTokenWeight = 0;
    for (uint256 i = 0; i < hlpAssetIds.length; ) {
      hlpTotalTokenWeight += assetHlpTokenConfigs[hlpAssetIds[i]].targetWeight;

      unchecked {
        ++i;
      }
    }

    liquidityConfig.hlpTotalTokenWeight = hlpTotalTokenWeight;
  }

  function setLiquidityEnabled(bool _enabled) external onlyWhitelistedExecutor {
    emit LogSetLiquidityEnabled(liquidityConfig.enabled, _enabled);
    liquidityConfig.enabled = _enabled;
  }

  function setDynamicEnabled(bool _enabled) external onlyOwner {
    liquidityConfig.dynamicFeeEnabled = _enabled;
    emit LogSetDynamicEnabled(_enabled);
  }

  function setServiceExecutor(
    address _contractAddress,
    address _executorAddress,
    bool _isServiceExecutor
  ) external onlyOwner {
    _setServiceExecutor(_contractAddress, _executorAddress, _isServiceExecutor);
  }

  function _setServiceExecutor(address _contractAddress, address _executorAddress, bool _isServiceExecutor) internal {
    if (
      _contractAddress == address(0) ||
      _executorAddress == address(0) ||
      !_contractAddress.isContract() ||
      !_executorAddress.isContract()
    ) revert IConfigStorage_InvalidAddress();
    serviceExecutors[_contractAddress][_executorAddress] = _isServiceExecutor;
    emit LogSetServiceExecutor(_contractAddress, _executorAddress, _isServiceExecutor);
  }

  function setServiceExecutors(
    address[] calldata _contractAddresses,
    address[] calldata _executorAddresses,
    bool[] calldata _isServiceExecutors
  ) external onlyOwner {
    if (
      _contractAddresses.length != _executorAddresses.length && _executorAddresses.length != _isServiceExecutors.length
    ) revert IConfigStorage_BadArgs();

    for (uint256 i = 0; i < _contractAddresses.length; ) {
      _setServiceExecutor(_contractAddresses[i], _executorAddresses[i], _isServiceExecutors[i]);
      unchecked {
        ++i;
      }
    }
  }

  function setPnlFactor(uint32 _pnlFactorBPS) external onlyOwner {
    emit LogSetPnlFactor(pnlFactorBPS, _pnlFactorBPS);
    pnlFactorBPS = _pnlFactorBPS;
  }

  function setSwapConfig(SwapConfig calldata _newConfig) external onlyOwner {
    emit LogSetSwapConfig(swapConfig, _newConfig);
    swapConfig = _newConfig;
  }

  function setTradingConfig(TradingConfig calldata _newConfig) external onlyOwner {
    if (_newConfig.fundingInterval == 0 || _newConfig.devFeeRateBPS > MAX_FEE_BPS)
      revert IConfigStorage_ExceedLimitSetting();
    emit LogSetTradingConfig(tradingConfig, _newConfig);
    tradingConfig = _newConfig;
  }

  function setLiquidationConfig(LiquidationConfig calldata _newConfig) external onlyOwner {
    emit LogSetLiquidationConfig(liquidationConfig, _newConfig);
    liquidationConfig = _newConfig;
  }

  function setMarketConfig(
    uint256 _marketIndex,
    MarketConfig calldata _newConfig
  ) external onlyOwner returns (MarketConfig memory _marketConfig) {
    if (_newConfig.increasePositionFeeRateBPS > MAX_FEE_BPS || _newConfig.decreasePositionFeeRateBPS > MAX_FEE_BPS)
      revert IConfigStorage_MaxFeeBps();
    if (_newConfig.assetClass > assetClassConfigs.length - 1) revert IConfigStorage_InvalidAssetClass();
    if (_newConfig.initialMarginFractionBPS < _newConfig.maintenanceMarginFractionBPS)
      revert IConfigStorage_InvalidValue();

    emit LogSetMarketConfig(_marketIndex, marketConfigs[_marketIndex], _newConfig);
    marketConfigs[_marketIndex] = _newConfig;
    return _newConfig;
  }

  function setHlpTokenConfig(
    address _token,
    HLPTokenConfig calldata _newConfig
  ) external onlyOwner returns (HLPTokenConfig memory _hlpTokenConfig) {
    emit LogSetHlpTokenConfig(_token, assetHlpTokenConfigs[tokenAssetIds[_token]], _newConfig);
    assetHlpTokenConfigs[tokenAssetIds[_token]] = _newConfig;

    uint256 hlpTotalTokenWeight = 0;
    for (uint256 i = 0; i < hlpAssetIds.length; ) {
      hlpTotalTokenWeight += assetHlpTokenConfigs[hlpAssetIds[i]].targetWeight;

      unchecked {
        ++i;
      }
    }

    liquidityConfig.hlpTotalTokenWeight = hlpTotalTokenWeight;

    return _newConfig;
  }

  function setCollateralTokenConfig(
    bytes32 _assetId,
    CollateralTokenConfig calldata _newConfig
  ) external onlyOwner returns (CollateralTokenConfig memory _collateralTokenConfig) {
    return _setCollateralTokenConfig(_assetId, _newConfig);
  }

  function setCollateralTokenConfigs(
    bytes32[] calldata _assetIds,
    CollateralTokenConfig[] calldata _newConfigs
  ) external onlyOwner {
    if (_assetIds.length != _newConfigs.length) revert IConfigStorage_BadLen();
    for (uint256 i = 0; i < _assetIds.length; ) {
      _setCollateralTokenConfig(_assetIds[i], _newConfigs[i]);

      unchecked {
        ++i;
      }
    }
  }

  function _setCollateralTokenConfig(
    bytes32 _assetId,
    CollateralTokenConfig calldata _newConfig
  ) internal returns (CollateralTokenConfig memory _collateralTokenConfig) {
    if (_newConfig.collateralFactorBPS == 0) revert IConfigStorage_ExceedLimitSetting();

    emit LogSetCollateralTokenConfig(_assetId, assetCollateralTokenConfigs[_assetId], _newConfig);
    // get current config, if new collateral's assetId then push to array
    CollateralTokenConfig memory _curCollateralTokenConfig = assetCollateralTokenConfigs[_assetId];
    if (
      _curCollateralTokenConfig.settleStrategy == address(0) &&
      _curCollateralTokenConfig.collateralFactorBPS == 0 &&
      _curCollateralTokenConfig.accepted == false
    ) {
      collateralAssetIds.push(_assetId);
    }
    assetCollateralTokenConfigs[_assetId] = _newConfig;
    return assetCollateralTokenConfigs[_assetId];
  }

  function setAssetConfig(
    bytes32 _assetId,
    AssetConfig calldata _newConfig
  ) external onlyOwner returns (AssetConfig memory _assetConfig) {
    return _setAssetConfig(_assetId, _newConfig);
  }

  function setAssetConfigs(bytes32[] calldata _assetIds, AssetConfig[] calldata _newConfigs) external onlyOwner {
    if (_assetIds.length != _newConfigs.length) revert IConfigStorage_BadLen();
    for (uint256 i = 0; i < _assetIds.length; ) {
      _setAssetConfig(_assetIds[i], _newConfigs[i]);

      unchecked {
        ++i;
      }
    }
  }

  function _setAssetConfig(
    bytes32 _assetId,
    AssetConfig calldata _newConfig
  ) internal returns (AssetConfig memory _assetConfig) {
    if (!_newConfig.tokenAddress.isContract()) revert IConfigStorage_BadArgs();

    emit LogSetAssetConfig(_assetId, assetConfigs[_assetId], _newConfig);
    assetConfigs[_assetId] = _newConfig;
    address _token = _newConfig.tokenAddress;

    if (_token != address(0)) {
      tokenAssetIds[_token] = _assetId;

      // sanity check
      ERC20Upgradeable(_token).decimals();
    }

    return assetConfigs[_assetId];
  }

  function setWeth(address _weth) external onlyOwner {
    if (!_weth.isContract()) revert IConfigStorage_BadArgs();

    emit LogSetToken(weth, _weth);
    weth = _weth;
  }

  function setSGlp(address _sglp) external onlyOwner {
    if (!_sglp.isContract()) revert IConfigStorage_BadArgs();

    emit LogSetToken(sglp, _sglp);
    sglp = _sglp;
  }

  /// @notice add or update accepted tokens of HLP
  /// @dev This function only allows to add new token or update existing token,
  /// any attempt to remove token will be reverted.
  /// @param _tokens The token addresses to set.
  /// @param _configs The token configs to set.
  function addOrUpdateAcceptedToken(address[] calldata _tokens, HLPTokenConfig[] calldata _configs) external onlyOwner {
    if (_tokens.length != _configs.length) {
      revert IConfigStorage_BadLen();
    }

    uint256 _tokenLen = _tokens.length;
    for (uint256 _i; _i < _tokenLen; ) {
      bytes32 _assetId = tokenAssetIds[_tokens[_i]];

      uint256 _assetIdLen = hlpAssetIds.length;

      bool _isSetHLPAssetId = true;

      // Search if this token is already added to the accepted token list
      for (uint256 _j; _j < _assetIdLen; ) {
        if (hlpAssetIds[_j] == _assetId) {
          _isSetHLPAssetId = false;
        }
        unchecked {
          ++_j;
        }
      }

      // Adjust hlpTotalToken Weight
      if (liquidityConfig.hlpTotalTokenWeight == 0) {
        liquidityConfig.hlpTotalTokenWeight = _configs[_i].targetWeight;
      } else {
        liquidityConfig.hlpTotalTokenWeight =
          (liquidityConfig.hlpTotalTokenWeight - assetHlpTokenConfigs[_assetId].targetWeight) +
          _configs[_i].targetWeight;
      }

      // If this is a new accepted token,
      // put asset ID after add totalWeight
      if (_isSetHLPAssetId) {
        hlpAssetIds.push(_assetId);
      }

      // Update config
      emit LogAddOrUpdateHLPTokenConfigs(_tokens[_i], assetHlpTokenConfigs[_assetId], _configs[_i]);
      assetHlpTokenConfigs[_assetId] = _configs[_i];

      unchecked {
        ++_i;
      }
    }
  }

  function addAssetClassConfig(AssetClassConfig calldata _newConfig) external onlyOwner returns (uint256 _index) {
    uint256 _newAssetClassIndex = assetClassConfigs.length;
    assetClassConfigs.push(_newConfig);
    emit LogAddAssetClassConfig(_newAssetClassIndex, _newConfig);
    return _newAssetClassIndex;
  }

  function setAssetClassConfigByIndex(uint256 _index, AssetClassConfig calldata _newConfig) external onlyOwner {
    emit LogSetAssetClassConfigByIndex(_index, assetClassConfigs[_index], _newConfig);
    assetClassConfigs[_index] = _newConfig;
  }

  function addMarketConfig(MarketConfig calldata _newConfig) external onlyOwner returns (uint256 _newMarketIndex) {
    // pre-validate
    if (_newConfig.increasePositionFeeRateBPS > MAX_FEE_BPS || _newConfig.decreasePositionFeeRateBPS > MAX_FEE_BPS)
      revert IConfigStorage_MaxFeeBps();
    if (_newConfig.assetClass > assetClassConfigs.length - 1) revert IConfigStorage_InvalidAssetClass();
    if (_newConfig.initialMarginFractionBPS < _newConfig.maintenanceMarginFractionBPS)
      revert IConfigStorage_InvalidValue();

    _newMarketIndex = marketConfigs.length;
    marketConfigs.push(_newConfig);
    emit LogAddMarketConfig(_newMarketIndex, _newConfig);
    return _newMarketIndex;
  }

  function delistMarket(uint256 _marketIndex) external onlyOwner {
    emit LogDelistMarket(_marketIndex);
    delete marketConfigs[_marketIndex].active;
  }

  /// @notice Remove underlying token.
  /// @param _token The token address to remove.
  function removeAcceptedToken(address _token) external onlyOwner {
    bytes32 _assetId = tokenAssetIds[_token];

    // Update totalTokenWeight
    liquidityConfig.hlpTotalTokenWeight -= assetHlpTokenConfigs[_assetId].targetWeight;

    // delete from hlpAssetIds
    uint256 _len = hlpAssetIds.length;
    for (uint256 _i = 0; _i < _len; ) {
      if (_assetId == hlpAssetIds[_i]) {
        hlpAssetIds[_i] = hlpAssetIds[_len - 1];
        hlpAssetIds.pop();
        break;
      }

      unchecked {
        ++_i;
      }
    }
    // Delete hlpTokenConfig
    delete assetHlpTokenConfigs[_assetId];

    emit LogRemoveUnderlying(_token);
  }

  function setTradeServiceHooks(address[] calldata _newHooks) external onlyOwner {
    for (uint256 i = 0; i < _newHooks.length; ) {
      if (_newHooks[i] == address(0)) revert IConfigStorage_InvalidAddress();

      unchecked {
        ++i;
      }
    }
    emit LogSetTradeServiceHooks(tradeServiceHooks, _newHooks);

    tradeServiceHooks = _newHooks;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}

// SPDX-License-Identifier: MIT
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
//

pragma solidity 0.8.18;

interface IConfigStorage {
  /**
   * Errors
   */
  error IConfigStorage_InvalidAddress();
  error IConfigStorage_InvalidValue();
  error IConfigStorage_NotWhiteListed();
  error IConfigStorage_ExceedLimitSetting();
  error IConfigStorage_BadLen();
  error IConfigStorage_BadArgs();
  error IConfigStorage_NotAcceptedCollateral();
  error IConfigStorage_NotAcceptedLiquidity();
  error IConfigStorage_MaxFeeBps();
  error IConfigStorage_InvalidAssetClass();

  /**
   * Structs
   */
  /// @notice Asset's config
  struct AssetConfig {
    address tokenAddress;
    bytes32 assetId;
    uint8 decimals;
    bool isStableCoin; // token is stablecoin
  }

  /// @notice perp liquidity provider token config
  struct HLPTokenConfig {
    uint256 targetWeight; // percentage of all accepted HLP tokens
    uint256 bufferLiquidity; // liquidity reserved for swapping, decimal is depends on token
    uint256 maxWeightDiff; // Maximum difference from the target weight in %
    bool accepted; // accepted to provide liquidity
  }

  /// @notice collateral token config
  struct CollateralTokenConfig {
    address settleStrategy; // determine token will be settled for NON HLP collateral, e.g. aUSDC redeemed as USDC
    uint32 collateralFactorBPS; // token reliability factor to calculate buying power, 1e4 = 100%
    bool accepted; // accepted to deposit as collateral
  }

  struct FundingRate {
    uint256 maxSkewScaleUSD; // maximum skew scale for using maxFundingRate
    uint256 maxFundingRate; // maximum funding rate
  }

  struct MarketConfig {
    bytes32 assetId; // pyth network asset id
    uint256 maxLongPositionSize; //
    uint256 maxShortPositionSize; //
    uint32 increasePositionFeeRateBPS; // fee rate to increase position
    uint32 decreasePositionFeeRateBPS; // fee rate to decrease position
    uint32 initialMarginFractionBPS; // IMF
    uint32 maintenanceMarginFractionBPS; // MMF
    uint32 maxProfitRateBPS; // maximum profit that trader could take per position
    uint8 assetClass; // Crypto = 1, Forex = 2, Stock = 3
    bool allowIncreasePosition; // allow trader to increase position
    bool active; // if active = false, means this market is delisted
    FundingRate fundingRate;
  }

  struct AssetClassConfig {
    uint256 baseBorrowingRate;
  }

  struct LiquidityConfig {
    uint256 hlpTotalTokenWeight; // % of token Weight (must be 1e18)
    uint32 hlpSafetyBufferBPS; // for HLP deleverage
    uint32 taxFeeRateBPS; // HLP deposit, withdraw, settle collect when pool weight is imbalances
    uint32 flashLoanFeeRateBPS;
    uint32 maxHLPUtilizationBPS; //% of max utilization
    uint32 depositFeeRateBPS; // HLP deposit fee rate
    uint32 withdrawFeeRateBPS; // HLP withdraw fee rate
    bool dynamicFeeEnabled; // if disabled, swap, add or remove liquidity will exclude tax fee
    bool enabled; // Circuit breaker on Liquidity
  }

  struct SwapConfig {
    uint32 stablecoinSwapFeeRateBPS;
    uint32 swapFeeRateBPS;
  }

  struct TradingConfig {
    uint256 fundingInterval; // funding interval unit in seconds
    uint256 minProfitDuration;
    uint32 devFeeRateBPS;
    uint8 maxPosition;
  }

  struct LiquidationConfig {
    uint256 liquidationFeeUSDE30; // liquidation fee in USD
  }

  /**
   * States
   */

  function calculator() external view returns (address);

  function oracle() external view returns (address);

  function hlp() external view returns (address);

  function treasury() external view returns (address);

  function pnlFactorBPS() external view returns (uint32);

  function weth() external view returns (address);

  function tokenAssetIds(address _token) external view returns (bytes32);

  /**
   * Functions
   */
  function validateServiceExecutor(address _contractAddress, address _executorAddress) external view;

  function validateAcceptedLiquidityToken(address _token) external view;

  function validateAcceptedCollateral(address _token) external view;

  function getTradingConfig() external view returns (TradingConfig memory);

  function getMarketConfigs() external view returns (MarketConfig[] memory);

  function getMarketConfigByIndex(uint256 _index) external view returns (MarketConfig memory _marketConfig);

  function getAssetClassConfigByIndex(uint256 _index) external view returns (AssetClassConfig memory _assetClassConfig);

  function getCollateralTokenConfigs(
    address _token
  ) external view returns (CollateralTokenConfig memory _collateralTokenConfig);

  function getAssetTokenDecimal(address _token) external view returns (uint8);

  function getLiquidityConfig() external view returns (LiquidityConfig memory);

  function getLiquidationConfig() external view returns (LiquidationConfig memory);

  function getMarketConfigsLength() external view returns (uint256);

  function getHlpTokens() external view returns (address[] memory);

  function getAssetConfigByToken(address _token) external view returns (AssetConfig memory);

  function getCollateralTokens() external view returns (address[] memory);

  function getAssetConfig(bytes32 _assetId) external view returns (AssetConfig memory);

  function getAssetHlpTokenConfig(bytes32 _assetId) external view returns (HLPTokenConfig memory);

  function getAssetHlpTokenConfigByToken(address _token) external view returns (HLPTokenConfig memory);

  function getHlpAssetIds() external view returns (bytes32[] memory);

  function getTradeServiceHooks() external view returns (address[] memory);

  function setMinimumPositionSize(uint256 _minimumPositionSize) external;

  function setLiquidityEnabled(bool _enabled) external;

  function setDynamicEnabled(bool _enabled) external;

  function setCalculator(address _calculator) external;

  function setOracle(address _oracle) external;

  function setHLP(address _hlp) external;

  function setLiquidityConfig(LiquidityConfig calldata _liquidityConfig) external;

  function setServiceExecutor(address _contractAddress, address _executorAddress, bool _isServiceExecutor) external;

  function setServiceExecutors(
    address[] calldata _contractAddresses,
    address[] calldata _executorAddresses,
    bool[] calldata _isServiceExecutors
  ) external;

  function setPnlFactor(uint32 _pnlFactor) external;

  function setSwapConfig(SwapConfig calldata _newConfig) external;

  function setTradingConfig(TradingConfig calldata _newConfig) external;

  function setLiquidationConfig(LiquidationConfig calldata _newConfig) external;

  function setMarketConfig(
    uint256 _marketIndex,
    MarketConfig calldata _newConfig
  ) external returns (MarketConfig memory _marketConfig);

  function setHlpTokenConfig(
    address _token,
    HLPTokenConfig calldata _newConfig
  ) external returns (HLPTokenConfig memory _hlpTokenConfig);

  function setCollateralTokenConfig(
    bytes32 _assetId,
    CollateralTokenConfig calldata _newConfig
  ) external returns (CollateralTokenConfig memory _collateralTokenConfig);

  function setAssetConfig(
    bytes32 assetId,
    AssetConfig calldata _newConfig
  ) external returns (AssetConfig memory _assetConfig);

  function setConfigExecutor(address _executorAddress, bool _isServiceExecutor) external;

  function setWeth(address _weth) external;

  function setSGlp(address _sglp) external;

  function addOrUpdateAcceptedToken(address[] calldata _tokens, HLPTokenConfig[] calldata _configs) external;

  function addAssetClassConfig(AssetClassConfig calldata _newConfig) external returns (uint256 _index);

  function setAssetClassConfigByIndex(uint256 _index, AssetClassConfig calldata _newConfig) external;

  function setTradeServiceHooks(address[] calldata _newHooks) external;

  function addMarketConfig(MarketConfig calldata _newConfig) external returns (uint256 _index);

  function delistMarket(uint256 _marketIndex) external;

  function removeAcceptedToken(address _token) external;
}

// SPDX-License-Identifier: MIT
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
//

pragma solidity 0.8.18;

interface IPerpStorage {
  /**
   * Errors
   */
  error IPerpStorage_NotWhiteListed();
  error IPerpStorage_BadLen();

  /**
   * Structs
   */
  struct GlobalState {
    uint256 reserveValueE30; // accumulative of reserve value from all opening positions
  }

  struct AssetClass {
    uint256 reserveValueE30; // accumulative of reserve value from all opening positions
    uint256 sumBorrowingRate;
    uint256 lastBorrowingTime;
    uint256 sumBorrowingFeeE30;
    uint256 sumSettledBorrowingFeeE30;
  }

  // mapping _marketIndex => globalPosition;
  struct Market {
    // LONG position
    uint256 longPositionSize;
    uint256 longAccumSE; // SUM(positionSize / entryPrice)
    uint256 longAccumS2E; // SUM(positionSize^2 / entryPrice)
    // SHORT position
    uint256 shortPositionSize;
    uint256 shortAccumSE; // SUM(positionSize / entryPrice)
    uint256 shortAccumS2E; // SUM(positionSize^2 / entryPrice)
    // funding rate
    int256 currentFundingRate;
    uint256 lastFundingTime;
    int256 accumFundingLong; // accumulative of funding fee value on LONG positions using for calculating surplus
    int256 accumFundingShort; // accumulative of funding fee value on SHORT positions using for calculating surplus
    int256 fundingAccrued; // the accrued funding rate which is the result of funding velocity. It is the accumulation of S in S = (U+V)/2 * t
  }

  // Trade position
  struct Position {
    address primaryAccount;
    uint256 marketIndex;
    uint256 avgEntryPriceE30;
    uint256 entryBorrowingRate;
    uint256 reserveValueE30; // Max Profit reserved in USD (9X of position collateral)
    uint256 lastIncreaseTimestamp; // To validate position lifetime
    int256 positionSizeE30; // LONG (+), SHORT(-) Position Size
    int256 realizedPnl;
    int256 lastFundingAccrued;
    uint8 subAccountId;
  }

  /**
   * Functions
   */
  function getPositionBySubAccount(address _trader) external view returns (Position[] memory traderPositions);

  function getPositionById(bytes32 _positionId) external view returns (Position memory);

  function getMarketByIndex(uint256 _marketIndex) external view returns (Market memory);

  function getAssetClassByIndex(uint256 _assetClassIndex) external view returns (AssetClass memory);

  function getGlobalState() external view returns (GlobalState memory);

  function getNumberOfSubAccountPosition(address _subAccount) external view returns (uint256);

  function updateGlobalLongMarketById(
    uint256 _marketIndex,
    uint256 _newPositionSize,
    uint256 _newAccumSE,
    uint256 _newAccumS2E
  ) external;

  function updateGlobalShortMarketById(
    uint256 _marketIndex,
    uint256 _newPositionSize,
    uint256 _newAccumSE,
    uint256 _newAccumS2E
  ) external;

  function updateGlobalState(GlobalState memory _newGlobalState) external;

  function savePosition(address _subAccount, bytes32 _positionId, Position calldata position) external;

  function removePositionFromSubAccount(address _subAccount, bytes32 _positionId) external;

  function updateAssetClass(uint8 _assetClassIndex, AssetClass memory _newAssetClass) external;

  function updateMarket(uint256 _marketIndex, Market memory _market) external;

  function getPositionIds(address _subAccount) external returns (bytes32[] memory _positionIds);

  function setServiceExecutors(address _executorAddress, bool _isServiceExecutor) external;

  function decreaseReserved(uint8 _assetClassIndex, uint256 _reserve) external;
}

// SPDX-License-Identifier: MIT
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
//

pragma solidity 0.8.18;

interface IVaultStorage {
  /**
   * Errors
   */
  error IVaultStorage_NotWhiteListed();
  error IVaultStorage_TraderTokenAlreadyExists();
  error IVaultStorage_TraderBalanceRemaining();
  error IVaultStorage_ZeroAddress();
  error IVaultStorage_HLPBalanceRemaining();
  error IVaultStorage_Forbidden();
  error IVaultStorage_TargetNotContract();
  error IVaultStorage_BadLen();
  error IVaultStorage_InvalidAddress();

  /**
   * Functions
   */
  function totalAmount(address _token) external returns (uint256);

  function hlpLiquidityDebtUSDE30() external view returns (uint256);

  function traderBalances(address _trader, address _token) external view returns (uint256 amount);

  function getTraderTokens(address _trader) external view returns (address[] memory);

  function protocolFees(address _token) external view returns (uint256);

  function fundingFeeReserve(address _token) external view returns (uint256);

  function devFees(address _token) external view returns (uint256);

  function hlpLiquidity(address _token) external view returns (uint256);

  function pullToken(address _token) external returns (uint256);

  function addFee(address _token, uint256 _amount) external;

  function addHLPLiquidity(address _token, uint256 _amount) external;

  function withdrawFee(address _token, uint256 _amount, address _receiver) external;

  function removeHLPLiquidity(address _token, uint256 _amount) external;

  function pushToken(address _token, address _to, uint256 _amount) external;

  function addFundingFee(address _token, uint256 _amount) external;

  function removeFundingFee(address _token, uint256 _amount) external;

  function addHlpLiquidityDebtUSDE30(uint256 _value) external;

  function removeHlpLiquidityDebtUSDE30(uint256 _value) external;

  function increaseTraderBalance(address _subAccount, address _token, uint256 _amount) external;

  function decreaseTraderBalance(address _subAccount, address _token, uint256 _amount) external;

  function payHlp(address _trader, address _token, uint256 _amount) external;

  function setServiceExecutors(address _executorAddress, bool _isServiceExecutor) external;

  function borrowFundingFeeFromHlpToTrader(
    address _trader,
    address _token,
    uint256 _fundingFeeAmount,
    uint256 _fundingFeeValue
  ) external;

  function repayFundingFeeDebtFromTraderToHlp(
    address _trader,
    address _token,
    uint256 _fundingFeeAmount,
    uint256 _fundingFeeValue
  ) external;

  function cook(address _token, address _target, bytes calldata _callData) external returns (bytes memory);

  function setStrategyAllowance(address _token, address _strategy, address _target) external;

  function setStrategyFunctionSigAllowance(address _token, address _strategy, bytes4 _target) external;

  function globalBorrowingFeeDebt() external returns (uint256);

  function globalLossDebt() external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
//

pragma solidity 0.8.18;

import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import { EnumerableSet } from "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

// interfaces
import { IPerpStorage } from "./interfaces/IPerpStorage.sol";

/// @title PerpStorage
/// @notice storage contract to keep core feature state
contract PerpStorage is OwnableUpgradeable, ReentrancyGuardUpgradeable, IPerpStorage {
  using EnumerableSet for EnumerableSet.Bytes32Set;
  using EnumerableSet for EnumerableSet.AddressSet;
  /**
   * Modifiers
   */
  modifier onlyWhitelistedExecutor() {
    if (!serviceExecutors[msg.sender]) revert IPerpStorage_NotWhiteListed();
    _;
  }

  /**
   * Events
   */
  event LogSetServiceExecutor(address indexed executorAddress, bool isServiceExecutor);

  /**
   * States
   */
  GlobalState public globalState; // global state that accumulative value from all markets

  mapping(bytes32 => Position) public positions;
  mapping(address => bytes32[]) public subAccountPositionIds;
  mapping(address => uint256) public subAccountBorrowingFee;
  mapping(uint256 => Market) public markets;
  mapping(uint256 => AssetClass) public assetClasses;
  mapping(address => bool) public serviceExecutors;

  EnumerableSet.Bytes32Set private activePositionIds;
  EnumerableSet.AddressSet private activeSubAccounts;

  function initialize() external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
  }

  /**
   * Getters
   */
  /// @notice Get all positions with a specific trader's sub-account
  /// @param _subAccount The address of the trader whose positions to retrieve
  /// @return _subAccountPositions An array of Position objects representing the trader's positions
  function getPositionBySubAccount(address _subAccount) external view returns (Position[] memory _subAccountPositions) {
    bytes32[] memory _positionIds = subAccountPositionIds[_subAccount];
    uint256 _len = _positionIds.length;

    if (_len == 0) return _subAccountPositions;

    _subAccountPositions = new Position[](_positionIds.length);

    for (uint256 _i; _i < _len; ) {
      _subAccountPositions[_i] = (positions[_positionIds[_i]]);

      unchecked {
        ++_i;
      }
    }

    return _subAccountPositions;
  }

  function getPositionIds(address _subAccount) external view returns (bytes32[] memory _positionIds) {
    return subAccountPositionIds[_subAccount];
  }

  function getPositionById(bytes32 _positionId) external view returns (Position memory) {
    return positions[_positionId];
  }

  function getNumberOfSubAccountPosition(address _subAccount) external view returns (uint256) {
    return subAccountPositionIds[_subAccount].length;
  }

  function getMarketByIndex(uint256 _marketIndex) external view returns (Market memory) {
    return markets[_marketIndex];
  }

  function getAssetClassByIndex(uint256 _assetClassIndex) external view returns (AssetClass memory) {
    return assetClasses[_assetClassIndex];
  }

  function getGlobalState() external view returns (GlobalState memory) {
    return globalState;
  }

  function getActivePositionIds(uint256 _limit, uint256 _offset) external view returns (bytes32[] memory _ids) {
    uint256 _len = activePositionIds.length();
    uint256 _startIndex = _offset;
    uint256 _endIndex = _offset + _limit;
    if (_startIndex > _len) return _ids;
    if (_endIndex > _len) {
      _endIndex = _len;
    }

    _ids = new bytes32[](_endIndex - _startIndex);

    for (uint256 i = _startIndex; i < _endIndex; ) {
      _ids[i - _offset] = activePositionIds.at(i);
      unchecked {
        ++i;
      }
    }

    return _ids;
  }

  function getActivePositions(uint256 _limit, uint256 _offset) external view returns (Position[] memory _positions) {
    uint256 _len = activePositionIds.length();
    uint256 _startIndex = _offset;
    uint256 _endIndex = _offset + _limit;
    if (_startIndex > _len) return _positions;
    if (_endIndex > _len) {
      _endIndex = _len;
    }

    _positions = new Position[](_endIndex - _startIndex);

    for (uint256 i = _startIndex; i < _endIndex; ) {
      _positions[i - _offset] = positions[activePositionIds.at(i)];
      unchecked {
        ++i;
      }
    }

    return _positions;
  }

  function getActiveSubAccounts(uint256 _limit, uint256 _offset) external view returns (address[] memory _subAccounts) {
    uint256 _len = activeSubAccounts.length();
    uint256 _startIndex = _offset;
    uint256 _endIndex = _offset + _limit;
    if (_startIndex > _len) return _subAccounts;
    if (_endIndex > _len) {
      _endIndex = _len;
    }

    _subAccounts = new address[](_endIndex - _startIndex);

    for (uint256 i = _startIndex; i < _endIndex; ) {
      _subAccounts[i - _offset] = activeSubAccounts.at(i);
      unchecked {
        ++i;
      }
    }

    return _subAccounts;
  }

  /**
   * Setters
   */
  function setServiceExecutors(address _executorAddress, bool _isServiceExecutor) external onlyOwner nonReentrant {
    _setServiceExecutor(_executorAddress, _isServiceExecutor);
  }

  function setServiceExecutorBatch(
    address[] calldata _executorAddresses,
    bool[] calldata _isServiceExecutors
  ) external onlyOwner nonReentrant {
    if (_executorAddresses.length != _isServiceExecutors.length) revert IPerpStorage_BadLen();
    for (uint256 i = 0; i < _executorAddresses.length; ) {
      _setServiceExecutor(_executorAddresses[i], _isServiceExecutors[i]);
      unchecked {
        ++i;
      }
    }
  }

  function _setServiceExecutor(address _executorAddress, bool _isServiceExecutor) internal {
    serviceExecutors[_executorAddress] = _isServiceExecutor;
    emit LogSetServiceExecutor(_executorAddress, _isServiceExecutor);
  }

  function savePosition(
    address _subAccount,
    bytes32 _positionId,
    Position calldata position
  ) external nonReentrant onlyWhitelistedExecutor {
    IPerpStorage.Position memory _position = positions[_positionId];
    // register new position for trader's sub-account
    if (_position.positionSizeE30 == 0) {
      subAccountPositionIds[_subAccount].push(_positionId);
      activePositionIds.add(_positionId);
      activeSubAccounts.add(_subAccount);
    }
    positions[_positionId] = position;
  }

  /// @notice Resets the position associated with the given position ID.
  /// @param _subAccount The sub account of the position.
  /// @param _positionId The ID of the position to be reset.
  function removePositionFromSubAccount(address _subAccount, bytes32 _positionId) external onlyWhitelistedExecutor {
    bytes32[] storage _positionIds = subAccountPositionIds[_subAccount];
    uint256 _len = _positionIds.length;
    for (uint256 _i; _i < _len; ) {
      if (_positionIds[_i] == _positionId) {
        _positionIds[_i] = _positionIds[_len - 1];
        _positionIds.pop();
        delete positions[_positionId];
        activePositionIds.remove(_positionId);

        break;
      }

      unchecked {
        ++_i;
      }
    }

    // Clear out active sub account if all position's gone
    if (_positionIds.length == 0) {
      activeSubAccounts.remove(_subAccount);
    }
  }

  function updateGlobalLongMarketById(
    uint256 _marketIndex,
    uint256 _newPositionSize,
    uint256 _newAccumSE,
    uint256 _newAccumS2E
  ) external onlyWhitelistedExecutor {
    markets[_marketIndex].longPositionSize = _newPositionSize;
    markets[_marketIndex].longAccumSE = _newAccumSE;
    markets[_marketIndex].longAccumS2E = _newAccumS2E;
  }

  function updateGlobalShortMarketById(
    uint256 _marketIndex,
    uint256 _newPositionSize,
    uint256 _newAccumSE,
    uint256 _newAccumS2E
  ) external onlyWhitelistedExecutor {
    markets[_marketIndex].shortPositionSize = _newPositionSize;
    markets[_marketIndex].shortAccumSE = _newAccumSE;
    markets[_marketIndex].shortAccumS2E = _newAccumS2E;
  }

  function updateGlobalState(GlobalState calldata _newGlobalState) external onlyWhitelistedExecutor {
    globalState = _newGlobalState;
  }

  function updateAssetClass(
    uint8 _assetClassIndex,
    AssetClass calldata _newAssetClass
  ) external onlyWhitelistedExecutor {
    assetClasses[_assetClassIndex] = _newAssetClass;
  }

  function updateMarket(uint256 _marketIndex, Market calldata _market) external onlyWhitelistedExecutor {
    markets[_marketIndex] = _market;
  }

  function decreaseReserved(uint8 _assetClassIndex, uint256 _reserve) external onlyWhitelistedExecutor {
    globalState.reserveValueE30 -= _reserve;
    assetClasses[_assetClassIndex].reserveValueE30 -= _reserve;
  }

  function increasePositionSize(uint256 _marketIndex, bool _isLong, uint256 _size) external onlyWhitelistedExecutor {
    if (_isLong) {
      markets[_marketIndex].longPositionSize += _size;
    } else {
      markets[_marketIndex].shortPositionSize += _size;
    }
  }

  function decreasePositionSize(uint256 _marketIndex, bool _isLong, uint256 _size) external onlyWhitelistedExecutor {
    if (_isLong) {
      markets[_marketIndex].longPositionSize -= _size;
    } else {
      markets[_marketIndex].shortPositionSize -= _size;
    }
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
//

pragma solidity 0.8.18;

import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import { IERC20Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";

// interfaces
import { SafeERC20Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { AddressUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/utils/AddressUpgradeable.sol";
import { IVaultStorage } from "./interfaces/IVaultStorage.sol";

/// @title VaultStorage
/// @notice storage contract to do accounting for token, and also hold physical tokens
contract VaultStorage is OwnableUpgradeable, ReentrancyGuardUpgradeable, IVaultStorage {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using AddressUpgradeable for address;

  /**
   * Events
   */
  event LogSetTraderBalance(address indexed trader, address token, uint balance);
  event LogSetServiceExecutor(address indexed executorAddress, bool isServiceExecutor);
  event LogSetStrategyAllowance(address indexed token, address strategy, address prevTarget, address newTarget);
  event LogSetStrategyFunctionSigAllowance(
    address indexed token,
    address strategy,
    bytes4 prevFunctionSig,
    bytes4 newFunctionSig
  );

  /**
   * States
   */
  mapping(address => uint256) public totalAmount; //token => tokenAmount
  mapping(address => uint256) public hlpLiquidity; // token => HLPTokenAmount
  mapping(address => uint256) public protocolFees; // protocol fee in token unit

  uint256 public hlpLiquidityDebtUSDE30; // USD debt accounting when fundingFee is not enough to repay to trader
  mapping(address => uint256) public fundingFeeReserve; // sum of realized funding fee amount

  mapping(address => uint256) public devFees;

  mapping(address => uint256) public tradingFeeDebt;
  mapping(address => uint256) public borrowingFeeDebt;
  mapping(address => uint256) public fundingFeeDebt;
  mapping(address => uint256) public lossDebt;

  uint256 public globalTradingFeeDebt;
  uint256 public globalBorrowingFeeDebt;
  uint256 public globalFundingFeeDebt;
  uint256 public globalLossDebt;

  // trader address (with sub-account) => token => amount
  mapping(address => mapping(address => uint256)) public traderBalances;
  // mapping(address => address[]) public traderTokens;
  mapping(address => address[]) public traderTokens;
  // mapping(token => strategy => target)
  mapping(address => mapping(address => address)) public strategyAllowances;
  // mapping(service executor address => allow)
  mapping(address => bool) public serviceExecutors;
  mapping(address token => mapping(address strategy => bytes4 functionSig)) public strategyFunctionSigAllowances;

  /**
   * Modifiers
   */
  modifier onlyWhitelistedExecutor() {
    if (!serviceExecutors[msg.sender]) revert IVaultStorage_NotWhiteListed();
    _;
  }

  function initialize() external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
  }

  /**
   * Core Functions
   */

  function validateAddTraderToken(address _trader, address _token) external view {
    _validateAddTraderToken(_trader, _token);
  }

  function validateRemoveTraderToken(address _trader, address _token) external view {
    _validateRemoveTraderToken(_trader, _token);
  }

  /**
   * Getters
   */

  function getTraderTokens(address _subAccount) external view returns (address[] memory) {
    return traderTokens[_subAccount];
  }

  /**
   * ERC20 interaction functions
   */

  function pullToken(address _token) external nonReentrant onlyWhitelistedExecutor returns (uint256) {
    return _pullToken(_token);
  }

  function _pullToken(address _token) internal returns (uint256) {
    uint256 prevBalance = totalAmount[_token];
    uint256 nextBalance = IERC20Upgradeable(_token).balanceOf(address(this));

    totalAmount[_token] = nextBalance;
    return nextBalance - prevBalance;
  }

  function pushToken(address _token, address _to, uint256 _amount) external nonReentrant onlyWhitelistedExecutor {
    _pushToken(_token, _to, _amount);
  }

  function _pushToken(address _token, address _to, uint256 _amount) internal {
    IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    totalAmount[_token] = IERC20Upgradeable(_token).balanceOf(address(this));
  }

  /**
   * Setters
   */

  function setServiceExecutors(address _executorAddress, bool _isServiceExecutor) external onlyOwner nonReentrant {
    _setServiceExecutor(_executorAddress, _isServiceExecutor);
  }

  function setServiceExecutorBatch(
    address[] calldata _executorAddresses,
    bool[] calldata _isServiceExecutors
  ) external onlyOwner nonReentrant {
    if (_executorAddresses.length != _isServiceExecutors.length) revert IVaultStorage_BadLen();
    for (uint256 i = 0; i < _executorAddresses.length; ) {
      _setServiceExecutor(_executorAddresses[i], _isServiceExecutors[i]);
      unchecked {
        ++i;
      }
    }
  }

  function _setServiceExecutor(address _executorAddress, bool _isServiceExecutor) internal {
    if (!_executorAddress.isContract()) revert IVaultStorage_InvalidAddress();
    serviceExecutors[_executorAddress] = _isServiceExecutor;
    emit LogSetServiceExecutor(_executorAddress, _isServiceExecutor);
  }

  function addFee(address _token, uint256 _amount) external onlyWhitelistedExecutor {
    protocolFees[_token] += _amount;
  }

  function addFundingFee(address _token, uint256 _amount) external onlyWhitelistedExecutor {
    fundingFeeReserve[_token] += _amount;
  }

  function removeFundingFee(address _token, uint256 _amount) external onlyWhitelistedExecutor {
    fundingFeeReserve[_token] -= _amount;
  }

  function addHlpLiquidityDebtUSDE30(uint256 _value) external onlyWhitelistedExecutor {
    hlpLiquidityDebtUSDE30 += _value;
  }

  function removeHlpLiquidityDebtUSDE30(uint256 _value) external onlyWhitelistedExecutor {
    hlpLiquidityDebtUSDE30 -= _value;
  }

  function addHLPLiquidity(address _token, uint256 _amount) external onlyWhitelistedExecutor {
    hlpLiquidity[_token] += _amount;
  }

  function withdrawFee(address _token, uint256 _amount, address _receiver) external onlyWhitelistedExecutor {
    if (_receiver == address(0)) revert IVaultStorage_ZeroAddress();
    protocolFees[_token] -= _amount;
    _pushToken(_token, _receiver, _amount);
  }

  function withdrawDevFee(address _token, uint256 _amount, address _receiver) external onlyOwner {
    if (_receiver == address(0)) revert IVaultStorage_ZeroAddress();
    devFees[_token] -= _amount;
    _pushToken(_token, _receiver, _amount);
  }

  function removeHLPLiquidity(address _token, uint256 _amount) external onlyWhitelistedExecutor {
    if (hlpLiquidity[_token] < _amount) revert IVaultStorage_HLPBalanceRemaining();
    hlpLiquidity[_token] -= _amount;
  }

  /// @notice increase sub-account collateral
  /// @param _subAccount - sub account
  /// @param _token - collateral token to increase
  /// @param _amount - amount to increase
  function increaseTraderBalance(
    address _subAccount,
    address _token,
    uint256 _amount
  ) external onlyWhitelistedExecutor {
    _increaseTraderBalance(_subAccount, _token, _amount);
  }

  /// @notice decrease sub-account collateral
  /// @param _subAccount - sub account
  /// @param _token - collateral token to increase
  /// @param _amount - amount to decrease
  function decreaseTraderBalance(
    address _subAccount,
    address _token,
    uint256 _amount
  ) external onlyWhitelistedExecutor {
    _deductTraderBalance(_subAccount, _token, _amount);
  }

  /// @notice Pays the HLP for providing liquidity with the specified token and amount.
  /// @param _trader The address of the trader paying the HLP.
  /// @param _token The address of the token being used to pay the HLP.
  /// @param _amount The amount of the token being used to pay the HLP.
  function payHlp(address _trader, address _token, uint256 _amount) external onlyWhitelistedExecutor {
    // Increase the HLP's liquidity for the specified token
    hlpLiquidity[_token] += _amount;

    // Decrease the trader's balance for the specified token
    _deductTraderBalance(_trader, _token, _amount);
  }

  function transfer(address _token, address _from, address _to, uint256 _amount) external onlyWhitelistedExecutor {
    _deductTraderBalance(_from, _token, _amount);
    _increaseTraderBalance(_to, _token, _amount);
  }

  function payTradingFee(
    address _trader,
    address _token,
    uint256 _devFeeAmount,
    uint256 _protocolFeeAmount
  ) external onlyWhitelistedExecutor {
    // Deduct amount from trader balance
    _deductTraderBalance(_trader, _token, _devFeeAmount + _protocolFeeAmount);

    // Increase the amount to devFees and protocolFees
    devFees[_token] += _devFeeAmount;
    protocolFees[_token] += _protocolFeeAmount;
  }

  function payBorrowingFee(
    address _trader,
    address _token,
    uint256 _devFeeAmount,
    uint256 _hlpFeeAmount
  ) external onlyWhitelistedExecutor {
    // Deduct amount from trader balance
    _deductTraderBalance(_trader, _token, _devFeeAmount + _hlpFeeAmount);

    // Increase the amount to devFees and hlpLiquidity
    devFees[_token] += _devFeeAmount;
    hlpLiquidity[_token] += _hlpFeeAmount;
  }

  function payFundingFeeFromTraderToHlp(
    address _trader,
    address _token,
    uint256 _fundingFeeAmount
  ) external onlyWhitelistedExecutor {
    // Deduct amount from trader balance
    _deductTraderBalance(_trader, _token, _fundingFeeAmount);

    // Increase the amount to hlpLiquidity
    hlpLiquidity[_token] += _fundingFeeAmount;
  }

  function payFundingFeeFromHlpToTrader(
    address _trader,
    address _token,
    uint256 _fundingFeeAmount
  ) external onlyWhitelistedExecutor {
    // Deduct amount from hlpLiquidity
    hlpLiquidity[_token] -= _fundingFeeAmount;

    // Increase the amount to trader
    _increaseTraderBalance(_trader, _token, _fundingFeeAmount);
  }

  function payTraderProfit(
    address _trader,
    address _token,
    uint256 _totalProfitAmount,
    uint256 _settlementFeeAmount
  ) external onlyWhitelistedExecutor {
    // Deduct amount from hlpLiquidity
    hlpLiquidity[_token] -= _totalProfitAmount;

    protocolFees[_token] += _settlementFeeAmount;
    _increaseTraderBalance(_trader, _token, _totalProfitAmount - _settlementFeeAmount);
  }

  function _increaseTraderBalance(address _trader, address _token, uint256 _amount) internal {
    if (_amount == 0) return;

    if (traderBalances[_trader][_token] == 0) {
      _addTraderToken(_trader, _token);
    }
    traderBalances[_trader][_token] += _amount;
  }

  function _deductTraderBalance(address _trader, address _token, uint256 _amount) internal {
    if (_amount == 0) return;
    traderBalances[_trader][_token] -= _amount;
    if (traderBalances[_trader][_token] == 0) {
      _removeTraderToken(_trader, _token);
    }
  }

  function convertFundingFeeReserveWithHLP(
    address _convertToken,
    address _targetToken,
    uint256 _convertAmount,
    uint256 _targetAmount
  ) external onlyWhitelistedExecutor {
    // Deduct convert token amount from funding fee reserve
    fundingFeeReserve[_convertToken] -= _convertAmount;

    // Increase convert token amount to HLP
    hlpLiquidity[_convertToken] += _convertAmount;

    // Deduct target token amount from HLP
    hlpLiquidity[_targetToken] -= _targetAmount;

    // Deduct convert token amount from funding fee reserve
    fundingFeeReserve[_targetToken] += _targetAmount;
  }

  function withdrawSurplusFromFundingFeeReserveToHLP(
    address _token,
    uint256 _fundingFeeAmount
  ) external onlyWhitelistedExecutor {
    // Deduct amount from funding fee reserve
    fundingFeeReserve[_token] -= _fundingFeeAmount;

    // Increase the amount to HLP
    hlpLiquidity[_token] += _fundingFeeAmount;
  }

  function payFundingFeeFromTraderToFundingFeeReserve(
    address _trader,
    address _token,
    uint256 _fundingFeeAmount
  ) external onlyWhitelistedExecutor {
    // Deduct amount from trader balance
    _deductTraderBalance(_trader, _token, _fundingFeeAmount);

    // Increase the amount to fundingFee
    fundingFeeReserve[_token] += _fundingFeeAmount;
  }

  function payFundingFeeFromFundingFeeReserveToTrader(
    address _trader,
    address _token,
    uint256 _fundingFeeAmount
  ) external onlyWhitelistedExecutor {
    // Deduct amount from fundingFee
    fundingFeeReserve[_token] -= _fundingFeeAmount;

    // Increase the amount to trader
    _increaseTraderBalance(_trader, _token, _fundingFeeAmount);
  }

  function repayFundingFeeDebtFromTraderToHlp(
    address _trader,
    address _token,
    uint256 _fundingFeeAmount,
    uint256 _fundingFeeValue
  ) external onlyWhitelistedExecutor {
    // Deduct amount from trader balance
    _deductTraderBalance(_trader, _token, _fundingFeeAmount);

    // Add token amounts that HLP received
    hlpLiquidity[_token] += _fundingFeeAmount;

    // Remove debt value on HLP as received
    hlpLiquidityDebtUSDE30 -= _fundingFeeValue;
  }

  function borrowFundingFeeFromHlpToTrader(
    address _trader,
    address _token,
    uint256 _fundingFeeAmount,
    uint256 _fundingFeeValue
  ) external onlyWhitelistedExecutor {
    // Deduct token amounts from HLP
    hlpLiquidity[_token] -= _fundingFeeAmount;

    // Increase the amount to trader
    _increaseTraderBalance(_trader, _token, _fundingFeeAmount);

    // Add debt value on HLP
    hlpLiquidityDebtUSDE30 += _fundingFeeValue;
  }

  function addTradingFeeDebt(address _trader, uint256 _tradingFeeDebt) external onlyWhitelistedExecutor {
    tradingFeeDebt[_trader] += _tradingFeeDebt;
    globalTradingFeeDebt += _tradingFeeDebt;
  }

  function addBorrowingFeeDebt(address _trader, uint256 _borrowingFeeDebt) external onlyWhitelistedExecutor {
    borrowingFeeDebt[_trader] += _borrowingFeeDebt;
    globalBorrowingFeeDebt += _borrowingFeeDebt;
  }

  function addFundingFeeDebt(address _trader, uint256 _fundingFeeDebt) external onlyWhitelistedExecutor {
    fundingFeeDebt[_trader] += _fundingFeeDebt;
    globalFundingFeeDebt += _fundingFeeDebt;
  }

  function addLossDebt(address _trader, uint256 _lossDebt) external onlyWhitelistedExecutor {
    lossDebt[_trader] += _lossDebt;
    globalLossDebt += _lossDebt;
  }

  function subTradingFeeDebt(address _trader, uint256 _tradingFeeDebt) external onlyWhitelistedExecutor {
    tradingFeeDebt[_trader] -= _tradingFeeDebt;
    globalTradingFeeDebt -= _tradingFeeDebt;
  }

  function subBorrowingFeeDebt(address _trader, uint256 _borrowingFeeDebt) external onlyWhitelistedExecutor {
    borrowingFeeDebt[_trader] -= _borrowingFeeDebt;
    globalBorrowingFeeDebt -= _borrowingFeeDebt;
  }

  function subFundingFeeDebt(address _trader, uint256 _fundingFeeDebt) external onlyWhitelistedExecutor {
    fundingFeeDebt[_trader] -= _fundingFeeDebt;
    globalFundingFeeDebt -= _fundingFeeDebt;
  }

  function subLossDebt(address _trader, uint256 _lossDebt) external onlyWhitelistedExecutor {
    lossDebt[_trader] -= _lossDebt;
    globalLossDebt -= _lossDebt;
  }

  /**
   * Strategy
   */

  /// @notice Set the strategy for a token
  /// @param _token The token to set the strategy for
  /// @param _strategy The strategy to set
  /// @param _target The target to set
  function setStrategyAllowance(address _token, address _strategy, address _target) external onlyOwner {
    // Target must be a contract. This to prevent strategy calling to EOA.
    if (!_target.isContract()) revert IVaultStorage_TargetNotContract();

    emit LogSetStrategyAllowance(_token, _strategy, strategyAllowances[_token][_strategy], _target);
    strategyAllowances[_token][_strategy] = _target;
  }

  /// @notice Set the allowed function sig of a strategy for a token
  /// @param _token The token to set the strategy for
  /// @param _strategy The strategy to set
  /// @param _target The target function sig to allow
  function setStrategyFunctionSigAllowance(address _token, address _strategy, bytes4 _target) external onlyOwner {
    emit LogSetStrategyFunctionSigAllowance(
      _token,
      _strategy,
      strategyFunctionSigAllowances[_token][_strategy],
      _target
    );
    strategyFunctionSigAllowances[_token][_strategy] = _target;
  }

  function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
    // If the _res length is less than 68, then the transaction failed silently (without a revert message)
    if (_returnData.length < 68) return "Transaction reverted silently";
    assembly {
      // Slice the sighash.
      _returnData := add(_returnData, 0x04)
    }
    return abi.decode(_returnData, (string)); // All that remains is the revert string
  }

  /// @notice invoking the target contract using call data.
  /// @param _token The token to cook
  /// @param _target target to execute callData
  /// @param _callData call data signature
  function cook(address _token, address _target, bytes calldata _callData) external returns (bytes memory) {
    // Check
    // 1. Only strategy for specific token can call this function
    if (strategyAllowances[_token][msg.sender] != _target) revert IVaultStorage_Forbidden();

    // Only whitelisted function sig can be performed by the strategy
    bytes4 functionSig = bytes4(_callData[:4]);
    if (strategyFunctionSigAllowances[_token][msg.sender] != functionSig) revert IVaultStorage_Forbidden();

    // 2. Execute the call as what the strategy wants
    (bool _success, bytes memory _returnData) = _target.call(_callData);
    // 3. Revert if not success
    require(_success, _getRevertMsg(_returnData));

    return _returnData;
  }

  /**
   * Private Functions
   */

  function _addTraderToken(address _trader, address _token) private {
    _validateAddTraderToken(_trader, _token);
    traderTokens[_trader].push(_token);
  }

  function _removeTraderToken(address _trader, address _token) private {
    _validateRemoveTraderToken(_trader, _token);

    address[] storage traderToken = traderTokens[_trader];
    uint256 tokenLen = traderToken.length;
    uint256 lastTokenIndex = tokenLen - 1;

    // find and deregister the token
    for (uint256 i; i < tokenLen; ) {
      if (traderToken[i] == _token) {
        // delete the token by replacing it with the last one and then pop it from there
        if (i != lastTokenIndex) {
          traderToken[i] = traderToken[lastTokenIndex];
        }
        traderToken.pop();
        break;
      }

      unchecked {
        i++;
      }
    }
  }

  function _validateRemoveTraderToken(address _trader, address _token) private view {
    if (traderBalances[_trader][_token] != 0) revert IVaultStorage_TraderBalanceRemaining();
  }

  function _validateAddTraderToken(address _trader, address _token) private view {
    address[] memory traderToken = traderTokens[_trader];

    uint256 len = traderToken.length;
    for (uint256 i; i < len; ) {
      if (traderToken[i] == _token) revert IVaultStorage_TraderTokenAlreadyExists();
      unchecked {
        i++;
      }
    }
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}