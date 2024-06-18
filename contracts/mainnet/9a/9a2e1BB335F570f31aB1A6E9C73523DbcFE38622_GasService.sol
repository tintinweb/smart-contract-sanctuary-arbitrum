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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IPerpStorage } from "src/storages/interfaces/IPerpStorage.sol";
import { ConfigStorage } from "src/storages/ConfigStorage.sol";

interface ICalculator {
  /**
   * Errors
   */
  error ICalculator_InvalidAddress();
  error ICalculator_InvalidArray();
  error ICalculator_InvalidAveragePrice();
  error ICalculator_InvalidPrice();
  error ICalculator_PoolImbalance();
  error ICalculator_InvalidBorrowingFee();

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
  function oracle() external view returns (address _address);

  function vaultStorage() external view returns (address _address);

  function configStorage() external view returns (address _address);

  function perpStorage() external view returns (address _address);

  /**
   * Functions
   */

  function getAUME30(bool isMaxPrice) external view returns (uint256);

  function getGlobalPNLE30() external view returns (int256);

  function getHLPValueE30(bool isMaxPrice) external view returns (uint256);

  function getFreeCollateral(
    address _subAccount,
    uint256 _price,
    bytes32 _assetId
  ) external view returns (int256 _freeCollateral);

  function getHLPPrice(uint256 aum, uint256 supply) external view returns (uint256);

  function getMintAmount(uint256 _aum, uint256 _totalSupply, uint256 _amount) external view returns (uint256);

  function getAddLiquidityFeeBPS(
    address _token,
    uint256 _tokenValue,
    ConfigStorage _configStorage
  ) external view returns (uint32);

  function getRemoveLiquidityFeeBPS(
    address _token,
    uint256 _tokenValueE30,
    ConfigStorage _configStorage
  ) external view returns (uint32);

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

  function getSettlementFeeRate(address _token, uint256 _liquidityUsdDelta) external view returns (uint256);

  function getCollateralValue(
    address _subAccount,
    uint256 _limitPrice,
    bytes32 _assetId
  ) external view returns (uint256 _collateralValueE30);

  function getFundingRateVelocity(uint256 _marketIndex) external view returns (int256);

  function getDelta(IPerpStorage.Position memory position, uint256 _markPrice) external view returns (bool, uint256);

  function getDelta(
    uint256 _size,
    bool _isLong,
    uint256 _markPrice,
    uint256 _averagePrice,
    uint256 _lastIncreaseTimestamp,
    uint256 _marketIndex
  ) external view returns (bool, uint256);

  function getDelta(
    address _subAccount,
    uint256 _size,
    bool _isLong,
    uint256 _markPrice,
    uint256 _averagePrice,
    uint256 _lastIncreaseTimestamp,
    uint256 _marketIndex
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

  function setTradeHelper(address _address) external;

  function proportionalElapsedInDay(uint256 _marketIndex) external view returns (uint256 elapsed);

  function getNextBorrowingRate(
    uint8 _assetClassIndex,
    uint256 _hlpTVL
  ) external view returns (uint256 _nextBorrowingRate);

  function getFundingFee(
    int256 _size,
    int256 _currentFundingAccrued,
    int256 _lastFundingAccrued
  ) external view returns (int256 fundingFee);

  function getBorrowingFee(
    uint8 _assetClassIndex,
    uint256 _reservedValue,
    uint256 _entryBorrowingRate
  ) external view returns (uint256 borrowingFee);
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.

pragma solidity 0.8.18;

library HMXLib {
  function getSubAccount(address _primary, uint8 _subAccountId) internal pure returns (address _subAccount) {
    return address(uint160(_primary) ^ uint160(_subAccountId));
  }

  // Code below taken from https://github.com/Vectorized/solady/blob/1371af4f6ba483bc547723b2c2a887c2f941ace1/src/utils/FixedPointMathLib.sol
  /// @dev Returns the maximum of `x` and `y`.
  function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := xor(x, mul(xor(x, y), gt(y, x)))
    }
  }

  /// @dev Returns the maximum of `x` and `y`.
  function max(int256 x, int256 y) internal pure returns (int256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := xor(x, mul(xor(x, y), sgt(y, x)))
    }
  }

  /// @dev Returns the minimum of `x` and `y`.
  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := xor(x, mul(xor(x, y), lt(y, x)))
    }
  }

  /// @dev Returns the minimum of `x` and `y`.
  function min(int256 x, int256 y) internal pure returns (int256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := xor(x, mul(xor(x, y), slt(y, x)))
    }
  }

  /// @dev Returns the absolute value of `x`.
  function abs(int256 x) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      let mask := sub(0, shr(255, x))
      z := xor(mask, add(mask, x))
    }
  }

  /// @notice Derive positionId from sub-account and market index
  function getPositionId(address _subAccount, uint256 _marketIndex) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_subAccount, _marketIndex));
  }

  function minInt128(int128 a, int128 b) internal pure returns (int128) {
    return a < b ? a : b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IOracleAdapter {
  function getLatestPrice(
    bytes32 _assetId,
    bool _isMax,
    uint32 _confidenceThreshold
  ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
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
pragma solidity 0.8.18;

import { IPyth, PythStructs, IPythEvents } from "lib/pyth-sdk-solidity/IPyth.sol";

interface IReadablePyth {
  function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.

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

pragma solidity 0.8.18;

// bases
import { ReentrancyGuardUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { HMXLib } from "src/libraries/HMXLib.sol";

// contracts
import { VaultStorage } from "src/storages/VaultStorage.sol";
import { OracleMiddleware } from "src/oracles/OracleMiddleware.sol";
import { ConfigStorage } from "src/storages/ConfigStorage.sol";

// interfaces
import { IGasService } from "src/services/interfaces/IGasService.sol";

contract GasService is ReentrancyGuardUpgradeable, OwnableUpgradeable, IGasService {
  VaultStorage public vaultStorage;
  ConfigStorage public configStorage;
  uint256 public executionFeeInUsd;
  address public executionFeeTreasury;
  uint256 public subsidizedExecutionFeeValue; // The total value of gas fee that is subsidized by the platform in E30
  uint256 public waviedExecutionFeeMinTradeSize; // The minimum trade size (E30) that we will waive exeuction fee
  bytes32 public gasTokenAssetId;

  function initialize(
    address _vaultStorage,
    address _configStorage,
    uint256 _executionFeeInUsd,
    address _executionFeeTreasury,
    bytes32 _gasTokenAssetId
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    vaultStorage = VaultStorage(_vaultStorage);
    configStorage = ConfigStorage(_configStorage);
    executionFeeInUsd = _executionFeeInUsd;
    executionFeeTreasury = _executionFeeTreasury;
    gasTokenAssetId = _gasTokenAssetId;
  }

  /**
   * Modifiers
   */
  modifier onlyWhitelistedExecutor() {
    ConfigStorage(configStorage).validateServiceExecutor(address(this), msg.sender);
    _;
  }

  /**
   * Functions
   */
  struct VarsCollectExecutionFeeFromCollateral {
    address subAccount;
    address[] traderTokens;
    uint256 len;
    OracleMiddleware oracle;
    uint256 executionFeeToBePaidInUsd;
    bytes32 assetId;
    ConfigStorage.AssetConfig assetConfig;
    address token;
    uint256 userBalance;
    uint256 tokenPrice;
    uint8 tokenDecimal;
    uint256 payAmount;
    uint256 payValue;
  }

  function collectExecutionFeeFromCollateral(
    address _primaryAccount,
    uint8 _subAccountId,
    uint256 _marketIndex,
    uint256 _absSizeDelta,
    uint256 _gasBefore
  ) external onlyWhitelistedExecutor {
    VarsCollectExecutionFeeFromCollateral memory vars;

    vars.subAccount = HMXLib.getSubAccount(_primaryAccount, _subAccountId);
    vars.traderTokens = vaultStorage.getTraderTokens(vars.subAccount);
    vars.len = vars.traderTokens.length;
    vars.oracle = OracleMiddleware(configStorage.oracle());

    uint256 gasConsumed = _gasBefore - gasleft();
    (vars.tokenPrice, ) = vars.oracle.getLatestPrice(gasTokenAssetId, false);
    uint256 gasConsumedInUsd = (gasConsumed * tx.gasprice * vars.tokenPrice) / 1e18;
    gasConsumedInUsd = HMXLib.max(gasConsumedInUsd, executionFeeInUsd); // max between these two value to at least collect some execution fee

    if (_absSizeDelta >= waviedExecutionFeeMinTradeSize) {
      emit LogSubsidizeExecutionFee(vars.subAccount, _marketIndex, gasConsumedInUsd);
      subsidizedExecutionFeeValue += gasConsumedInUsd;
    } else {
      emit LogCollectExecutionFeeValue(vars.subAccount, _marketIndex, gasConsumedInUsd);
      vars.executionFeeToBePaidInUsd = gasConsumedInUsd;
      for (uint256 _i; _i < vars.len; ) {
        vars.assetId = configStorage.tokenAssetIds(vars.traderTokens[_i]);
        vars.assetConfig = configStorage.getAssetConfig(vars.assetId);
        vars.token = vars.assetConfig.tokenAddress;
        vars.userBalance = vaultStorage.traderBalances(vars.subAccount, vars.token);

        if (vars.userBalance > 0) {
          (vars.tokenPrice, ) = vars.oracle.getLatestPrice(vars.assetConfig.assetId, false);
          vars.tokenDecimal = vars.assetConfig.decimals;

          (vars.payAmount, vars.payValue) = _getPayAmount(
            vars.userBalance,
            vars.executionFeeToBePaidInUsd,
            vars.tokenPrice,
            vars.tokenDecimal
          );
          emit LogCollectExecutionFeeAmount(vars.subAccount, _marketIndex, vars.token, vars.payAmount);

          vaultStorage.decreaseTraderBalance(vars.subAccount, vars.token, vars.payAmount);
          vaultStorage.increaseTraderBalance(executionFeeTreasury, vars.token, vars.payAmount);

          vars.executionFeeToBePaidInUsd -= vars.payValue;

          if (vars.executionFeeToBePaidInUsd == 0) {
            break;
          }
        }

        unchecked {
          ++_i;
        }
      }

      if (vars.executionFeeToBePaidInUsd > 0) {
        vaultStorage.addTradingFeeDebt(vars.subAccount, vars.executionFeeToBePaidInUsd);
      }
    }
  }

  function adjustSubsidizedExecutionFeeValue(int256 deltaValueE30) external onlyWhitelistedExecutor {
    uint256 previousValue = subsidizedExecutionFeeValue;
    if (deltaValueE30 >= 0) {
      subsidizedExecutionFeeValue += uint256(deltaValueE30);
    } else {
      subsidizedExecutionFeeValue -= uint256(-deltaValueE30);
    }
    emit LogAdjustSubsidizedExecutionFeeValue(previousValue, subsidizedExecutionFeeValue, deltaValueE30);
  }

  function _getPayAmount(
    uint256 _payerBalance,
    uint256 _valueE30,
    uint256 _tokenPrice,
    uint8 _tokenDecimal
  ) internal pure returns (uint256 _payAmount, uint256 _payValueE30) {
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

  function setParams(uint256 _executionFeeInUsd, address _executionFeeTreasury) external onlyOwner {
    executionFeeInUsd = _executionFeeInUsd;
    executionFeeTreasury = _executionFeeTreasury;

    emit LogSetParams(_executionFeeInUsd, _executionFeeTreasury);
  }

  function setGasTokenAssetId(bytes32 _gasTokenAssetId) external onlyOwner {
    gasTokenAssetId = _gasTokenAssetId;

    emit LogSetGasTokenAssetId(gasTokenAssetId);
  }

  function setWaviedExecutionFeeMinTradeSize(uint256 _waviedExecutionFeeMinTradeSize) external onlyOwner {
    waviedExecutionFeeMinTradeSize = _waviedExecutionFeeMinTradeSize;

    emit LogSetWaviedExecutionFeeMinTradeSize(waviedExecutionFeeMinTradeSize);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IGasService {
  error GasService_NotEnoughCollateral();

  event LogSetParams(uint256 executionFeeInUsd, address executionFeeTreasury);
  event LogCollectExecutionFeeValue(address subAccount, uint256 marketIndex, uint256 executionFeeUsd);
  event LogCollectExecutionFeeAmount(
    address subAccount,
    uint256 marketIndex,
    address token,
    uint256 executionFeeAmount
  );
  event LogSetWaviedExecutionFeeMinTradeSize(uint256 waivedExecutionFeeTradeSize);
  event LogSubsidizeExecutionFee(address subAccount, uint256 marketIndex, uint256 executionFeeUsd);
  event LogAdjustSubsidizedExecutionFeeValue(uint256 previousValue, uint256 newValue, int256 delta);
  event LogSetGasTokenAssetId(bytes32 gasTokenAssetId);

  function collectExecutionFeeFromCollateral(
    address _primaryAccount,
    uint8 _subAccountId,
    uint256 _marketIndex,
    uint256 _absSizeDelta,
    uint256 _gasBefore
  ) external;

  function setWaviedExecutionFeeMinTradeSize(uint256 _waviedExecutionFeeMinTradeSize) external;

  function adjustSubsidizedExecutionFeeValue(int256 deltaValueE30) external;

  function subsidizedExecutionFeeValue() external view returns (uint256);

  function waviedExecutionFeeMinTradeSize() external view returns (uint256);

  function setGasTokenAssetId(bytes32 _gasTokenAssetId) external;
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.

pragma solidity 0.8.18;

// Base
import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { ERC20Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import { AddressUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/utils/AddressUpgradeable.sol";

// Interfaces
import { IConfigStorage } from "src/storages/interfaces/IConfigStorage.sol";
import { ICalculator } from "src/contracts/interfaces/ICalculator.sol";
import { IOracleMiddleware } from "src/oracles/interfaces/IOracleMiddleware.sol";

/// @title ConfigStorage
/// @notice storage contract to keep configs
contract ConfigStorage is IConfigStorage, OwnableUpgradeable {
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
  event LogSetSwitchCollateralRouter(address prevRouter, address newRouter);
  event LogMinProfitDuration(uint256 indexed marketIndex, uint256 minProfitDuration);
  event LogSetStepMinProfitDuration(uint256 index, StepMinProfitDuration _stepMinProfitDuration);
  event LogSetMakerTakerFee(uint256 marketIndex, uint256 makerFee, uint256 takerFee);
  event LogSetMarketMaxOI(uint256 marketIndex, uint256 maxLongPositionSize, uint256 maxShortPositionSize);
  event LogSetMarketIMF(uint256 marketIndex, uint32 imf);
  event LogSetMarketIMFAndMaxProfit(uint256 marketIndex, uint32 imf, uint32 maxProfitRateBPS);

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
  // Executors
  mapping(address => bool) public configExecutors;
  // SwithCollateralRouter
  address public switchCollateralRouter;
  // Min Profit Duration by Market
  mapping(uint256 marketIndex => uint256 minProfitDuration) public minProfitDurations;
  // If enabled, this market will used Adaptive Fee based on CEX orderbook liquidity depth
  mapping(uint256 marketIndex => bool isEnabled) public isAdaptiveFeeEnabledByMarketIndex;
  // Min profit duration in steps based on trade size
  StepMinProfitDuration[] public stepMinProfitDurations;
  mapping(uint256 marketIndex => bool isStepMinProfitEnabled) public isStepMinProfitEnabledByMarketIndex;

  // Cannot put these inside MarketConfig due to backward incompatibility
  mapping(uint256 marketIndex => uint256 takerFeeE8) public takerFeeE8ByMarketIndex;
  mapping(uint256 marketIndex => uint256 makerFeeE8) public makerFeeE8ByMarketIndex;

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
      _contractAddresses.length != _executorAddresses.length || _executorAddresses.length != _isServiceExecutors.length
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
    MarketConfig calldata _newConfig,
    bool _isAdaptiveFeeEnabled
  ) external onlyOwner returns (MarketConfig memory _marketConfig) {
    if (_newConfig.increasePositionFeeRateBPS > MAX_FEE_BPS || _newConfig.decreasePositionFeeRateBPS > MAX_FEE_BPS)
      revert IConfigStorage_MaxFeeBps();
    if (_newConfig.assetClass > assetClassConfigs.length - 1) revert IConfigStorage_InvalidAssetClass();
    if (_newConfig.initialMarginFractionBPS < _newConfig.maintenanceMarginFractionBPS)
      revert IConfigStorage_InvalidValue();

    emit LogSetMarketConfig(_marketIndex, marketConfigs[_marketIndex], _newConfig);
    marketConfigs[_marketIndex] = _newConfig;
    isAdaptiveFeeEnabledByMarketIndex[_marketIndex] = _isAdaptiveFeeEnabled;
    return _newConfig;
  }

  function setMarketMaxOI(
    uint256[] memory _marketIndexes,
    uint256[] memory _maxLongPositionSizes,
    uint256[] memory _maxShortPositionSizes
  ) external onlyWhitelistedExecutor {
    if (
      _marketIndexes.length != _maxLongPositionSizes.length ||
      _maxLongPositionSizes.length != _maxShortPositionSizes.length
    ) revert IConfigStorage_BadLen();
    uint256 length = _marketIndexes.length;
    for (uint256 i; i < length; ) {
      marketConfigs[_marketIndexes[i]].maxLongPositionSize = _maxLongPositionSizes[i];
      marketConfigs[_marketIndexes[i]].maxShortPositionSize = _maxShortPositionSizes[i];

      emit LogSetMarketMaxOI(_marketIndexes[i], _maxLongPositionSizes[i], _maxShortPositionSizes[i]);

      unchecked {
        ++i;
      }
    }
  }

  function setMarketIMFAndMaxProfit(
    uint256[] memory _marketIndexes,
    uint32[] memory _imfs,
    uint32[] memory _maxProfitRateBPSs
  ) external onlyWhitelistedExecutor {
    if (_marketIndexes.length != _imfs.length) revert IConfigStorage_BadLen();
    uint256 length = _marketIndexes.length;
    for (uint256 i; i < length; ) {
      marketConfigs[_marketIndexes[i]].initialMarginFractionBPS = _imfs[i];
      marketConfigs[_marketIndexes[i]].maxProfitRateBPS = _maxProfitRateBPSs[i];

      emit LogSetMarketIMFAndMaxProfit(_marketIndexes[i], _imfs[i], _maxProfitRateBPSs[i]);

      unchecked {
        ++i;
      }
    }
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

  /// @notice Set switch collateral router.
  /// @param _newSwitchCollateralRouter The new switch collateral router.
  function setSwitchCollateralRouter(address _newSwitchCollateralRouter) external onlyOwner {
    emit LogSetSwitchCollateralRouter(switchCollateralRouter, _newSwitchCollateralRouter);
    switchCollateralRouter = _newSwitchCollateralRouter;
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

  function addMarketConfig(
    MarketConfig calldata _newConfig,
    bool _isAdaptiveFeeEnabled
  ) external onlyOwner returns (uint256 _newMarketIndex) {
    // pre-validate
    if (_newConfig.increasePositionFeeRateBPS > MAX_FEE_BPS || _newConfig.decreasePositionFeeRateBPS > MAX_FEE_BPS)
      revert IConfigStorage_MaxFeeBps();
    if (_newConfig.assetClass > assetClassConfigs.length - 1) revert IConfigStorage_InvalidAssetClass();
    if (_newConfig.initialMarginFractionBPS < _newConfig.maintenanceMarginFractionBPS)
      revert IConfigStorage_InvalidValue();

    _newMarketIndex = marketConfigs.length;
    marketConfigs.push(_newConfig);
    isAdaptiveFeeEnabledByMarketIndex[_newMarketIndex] = _isAdaptiveFeeEnabled;
    emit LogAddMarketConfig(_newMarketIndex, _newConfig);
    return _newMarketIndex;
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

  function setMinProfitDurations(
    uint256[] calldata _marketIndexs,
    uint256[] calldata _minProfitDurations
  ) external onlyOwner {
    if (_marketIndexs.length != _minProfitDurations.length) revert IConfigStorage_BadArgs();

    uint256 MAX_DURATION = 30 minutes;

    for (uint256 i; i < _marketIndexs.length; ) {
      if (_minProfitDurations[i] > MAX_DURATION) revert IConfigStorage_MaxDurationForMinProfit();

      minProfitDurations[_marketIndexs[i]] = _minProfitDurations[i];

      emit LogMinProfitDuration(_marketIndexs[i], _minProfitDurations[i]);

      unchecked {
        ++i;
      }
    }
  }

  function addStepMinProfitDuration(StepMinProfitDuration[] memory _stepMinProfitDurations) external onlyOwner {
    uint256 length = _stepMinProfitDurations.length;
    for (uint256 i; i < length; ) {
      if (_stepMinProfitDurations[i].fromSize >= _stepMinProfitDurations[i].toSize) revert IConfigStorage_BadArgs();
      stepMinProfitDurations.push(_stepMinProfitDurations[i]);
      emit LogSetStepMinProfitDuration(stepMinProfitDurations.length - 1, _stepMinProfitDurations[i]);
      unchecked {
        ++i;
      }
    }
  }

  function setStepMinProfitDuration(
    uint256[] memory indexes,
    StepMinProfitDuration[] memory _stepMinProfitDurations
  ) external onlyOwner {
    if (indexes.length != _stepMinProfitDurations.length) revert IConfigStorage_BadLen();
    uint256 length = _stepMinProfitDurations.length;
    for (uint256 i; i < length; ) {
      if (_stepMinProfitDurations[i].fromSize >= _stepMinProfitDurations[i].toSize) revert IConfigStorage_BadArgs();
      stepMinProfitDurations[indexes[i]] = _stepMinProfitDurations[i];
      emit LogSetStepMinProfitDuration(indexes[i], _stepMinProfitDurations[i]);
      unchecked {
        ++i;
      }
    }
  }

  function removeLastStepMinProfitDuration() external onlyOwner {
    emit LogSetStepMinProfitDuration(
      stepMinProfitDurations.length - 1,
      IConfigStorage.StepMinProfitDuration({ fromSize: 0, toSize: 0, minProfitDuration: 0 })
    );
    stepMinProfitDurations.pop();
  }

  function getStepMinProfitDuration(uint256 marketIndex, uint256 sizeDelta) external view returns (uint256) {
    uint256 length = stepMinProfitDurations.length;
    if (length == 0 || !isStepMinProfitEnabledByMarketIndex[marketIndex]) {
      return minProfitDurations[marketIndex];
    }
    for (uint256 i; i < length; ) {
      if (sizeDelta >= stepMinProfitDurations[i].fromSize && sizeDelta < stepMinProfitDurations[i].toSize) {
        // In-range
        return stepMinProfitDurations[i].minProfitDuration;
      }
      unchecked {
        ++i;
      }
    }
    return minProfitDurations[marketIndex];
  }

  function getStepMinProfitDurations() external view returns (StepMinProfitDuration[] memory) {
    return stepMinProfitDurations;
  }

  function setIsStepMinProfitEnabledByMarketIndex(
    uint256[] memory marketIndexes,
    bool[] memory isEnableds
  ) external onlyOwner {
    if (marketIndexes.length != isEnableds.length) revert IConfigStorage_BadLen();
    uint256 length = marketIndexes.length;
    for (uint256 i; i < length; ) {
      isStepMinProfitEnabledByMarketIndex[marketIndexes[i]] = isEnableds[i];

      unchecked {
        ++i;
      }
    }
  }

  function setMakerTakerFeeByMarketIndexes(
    uint256[] memory marketIndexes,
    uint256[] memory makerFees,
    uint256[] memory takerFees
  ) external onlyOwner {
    if (marketIndexes.length != makerFees.length || makerFees.length != takerFees.length)
      revert IConfigStorage_BadLen();
    uint256 length = marketIndexes.length;
    for (uint256 i; i < length; ) {
      makerFeeE8ByMarketIndex[marketIndexes[i]] = makerFees[i];
      takerFeeE8ByMarketIndex[marketIndexes[i]] = takerFees[i];

      emit LogSetMakerTakerFee(marketIndexes[i], makerFees[i], takerFees[i]);

      unchecked {
        ++i;
      }
    }
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}

// SPDX-License-Identifier: MIT
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
  error IConfigStorage_MaxDurationForMinProfit();

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
    uint256 maxFundingRate; // The maximum rate per day that the funding rate would change
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

  struct StepMinProfitDuration {
    uint256 fromSize;
    uint256 toSize;
    uint256 minProfitDuration;
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

  function switchCollateralRouter() external view returns (address);

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

  function setTradingConfig(TradingConfig calldata _newConfig) external;

  function setLiquidationConfig(LiquidationConfig calldata _newConfig) external;

  function setMarketConfig(
    uint256 _marketIndex,
    MarketConfig calldata _newConfig,
    bool isAdaptiveFeeEnabled
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

  function addOrUpdateAcceptedToken(address[] calldata _tokens, HLPTokenConfig[] calldata _configs) external;

  function addAssetClassConfig(AssetClassConfig calldata _newConfig) external returns (uint256 _index);

  function setAssetClassConfigByIndex(uint256 _index, AssetClassConfig calldata _newConfig) external;

  function setTradeServiceHooks(address[] calldata _newHooks) external;

  function addMarketConfig(
    MarketConfig calldata _newConfig,
    bool isAdaptiveFeeEnabled
  ) external returns (uint256 _index);

  function removeAcceptedToken(address _token) external;

  function minProfitDurations(uint256 marketIndex) external view returns (uint256 minProfitDuration);

  function setMinProfitDurations(uint256[] calldata _marketIndexs, uint256[] calldata _minProfitDurations) external;

  function minimumPositionSize() external view returns (uint256);

  function getAssetClassConfigsLength() external view returns (uint256);

  function isAdaptiveFeeEnabledByMarketIndex(uint256 marketIndex) external view returns (bool);

  function addStepMinProfitDuration(StepMinProfitDuration[] memory _stepMinProfitDurations) external;

  function setStepMinProfitDuration(
    uint256[] memory indexes,
    StepMinProfitDuration[] memory _stepMinProfitDurations
  ) external;

  function removeLastStepMinProfitDuration() external;

  function getStepMinProfitDuration(uint256 marketIndex, uint256 sizeDelta) external view returns (uint256);

  function setIsStepMinProfitEnabledByMarketIndex(uint256[] memory marketIndexes, bool[] memory isEnableds) external;

  function setMakerTakerFeeByMarketIndexes(
    uint256[] memory marketIndexes,
    uint256[] memory makerFees,
    uint256[] memory takerFees
  ) external;

  function setMarketMaxOI(
    uint256[] memory _marketIndexes,
    uint256[] memory _maxLongPositionSizes,
    uint256[] memory _maxShortPositionSizes
  ) external;

  function setMarketIMFAndMaxProfit(
    uint256[] memory _marketIndexes,
    uint32[] memory _imfs,
    uint32[] memory _maxProfitRateBPSs
  ) external;
}

// SPDX-License-Identifier: MIT
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
    uint256 lastIncreaseSize;
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

  function getActivePositionIds(uint256 _limit, uint256 _offset) external view returns (bytes32[] memory _ids);

  function getActivePositions(uint256 _limit, uint256 _offset) external view returns (Position[] memory _positions);

  function getActiveSubAccounts(uint256 _limit, uint256 _offset) external view returns (address[] memory _subAccounts);

  function setMovingWindowConfig(uint256 length, uint256 interval) external;

  function increaseEpochVolume(bool isBuy, uint256 marketIndex, uint256 absSizeDelta) external;

  function getEpochVolume(bool isBuy, uint256 marketIndex) external view returns (uint256 epochVolume);
}

// SPDX-License-Identifier: MIT
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
  error IVaultStorage_InvalidAccounting();

  /**
   * Functions
   */
  function totalAmount(address _token) external returns (uint256);

  function lossDebt(address) external view returns (uint256);

  function tradingFeeDebt(address) external view returns (uint256);

  function borrowingFeeDebt(address) external view returns (uint256);

  function fundingFeeDebt(address) external view returns (uint256);

  function subTradingFeeDebt(address _trader, uint256 _tradingFeeDebt) external;

  function subBorrowingFeeDebt(address _trader, uint256 _borrowingFeeDebt) external;

  function subFundingFeeDebt(address _trader, uint256 _fundingFeeDebt) external;

  function subLossDebt(address _trader, uint256 _lossDebt) external;

  function convertFundingFeeReserveWithHLP(
    address _convertToken,
    address _targetToken,
    uint256 _convertAmount,
    uint256 _targetAmount
  ) external;

  function hlpLiquidityDebtUSDE30() external view returns (uint256);

  function traderBalances(address _trader, address _token) external view returns (uint256 amount);

  function getTraderTokens(address _trader) external view returns (address[] memory);

  function protocolFees(address _token) external view returns (uint256);

  function fundingFeeReserve(address _token) external view returns (uint256);

  function devFees(address _token) external view returns (uint256);

  function hlpLiquidity(address _token) external view returns (uint256);

  function pullToken(address _token) external returns (uint256);

  function clearOnHold(address _token, uint256 _amount) external;

  function addFee(address _token, uint256 _amount) external;

  function addHLPLiquidity(address _token, uint256 _amount) external;

  function withdrawFee(address _token, uint256 _amount, address _receiver) external;

  function withdrawSurplusFromFundingFeeReserveToHLP(address _token, uint256 _fundingFeeAmount) external;

  function removeHLPLiquidity(address _token, uint256 _amount) external;

  function removeHLPLiquidityOnHold(address _token, uint256 _amount) external;

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

  function globalBorrowingFeeDebt() external view returns (uint256);

  function globalLossDebt() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.

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
  event LogAddDevFee(address indexed token, uint256 devFeeAmount);
  event LogClearOnHold(
    address indexed token,
    uint256 clearAmount,
    uint256 prevTotalAmount,
    uint256 nextTotalAmount,
    uint256 prevOnHoldAmount,
    uint256 nextOnHoldAmount
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
  // mapping(token => strategy => target => isAllow?)
  mapping(address token => mapping(address strategy => bytes4 functionSig)) public strategyFunctionSigAllowances;
  // this mapping keeps track of hlpLiquidity that is on hold while being under rebalancing operation
  mapping(address token => uint256 amount) public hlpLiquidityOnHold;

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
    uint256 nextBalance = IERC20Upgradeable(_token).balanceOf(address(this)) + hlpLiquidityOnHold[_token];

    totalAmount[_token] = nextBalance;

    return nextBalance - prevBalance;
  }

  /// @notice Clear on hold amount
  /// @param _token The token to clear on hold amount
  /// @param _amount The amount to clear on hold amount
  function clearOnHold(address _token, uint256 _amount) external nonReentrant onlyWhitelistedExecutor {
    emit LogClearOnHold(
      _token,
      _amount,
      totalAmount[_token],
      totalAmount[_token] -= _amount,
      hlpLiquidityOnHold[_token],
      hlpLiquidityOnHold[_token] -= _amount
    );
  }

  function pushToken(address _token, address _to, uint256 _amount) external nonReentrant onlyWhitelistedExecutor {
    _pushToken(_token, _to, _amount);
  }

  function _pushToken(address _token, address _to, uint256 _amount) internal {
    IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    totalAmount[_token] = IERC20Upgradeable(_token).balanceOf(address(this)) + hlpLiquidityOnHold[_token];
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

  function addDevFee(address _token, uint256 _amount) external onlyWhitelistedExecutor {
    devFees[_token] += _amount;
    emit LogAddDevFee(_token, _amount);
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

  function removeHLPLiquidityOnHold(address _token, uint256 _amount) external onlyWhitelistedExecutor {
    if (hlpLiquidity[_token] < _amount) revert IVaultStorage_HLPBalanceRemaining();
    hlpLiquidityOnHold[_token] += _amount;
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