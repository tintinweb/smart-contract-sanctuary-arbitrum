// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

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

pragma solidity 0.8.10;

/// @title ISuperAdmin
/// @dev Interface for managing the super admin role.
interface ISuperAdmin {
    /// @dev Emitted when the super admin role is transferred.
    /// @param oldAdmin The address of the old super admin.
    /// @param newAdmin The address of the new super admin.
    event SuperAdminTransfer(address oldAdmin, address newAdmin);

    /// @notice Returns the address of the super admin.
    /// @return The address of the super admin.
    function superAdmin() external view returns (address);

    /// @notice Checks if the caller is a valid super admin.
    /// @param caller The address to check.
    function isValidSuperAdmin(address caller) external view;

    /// @notice Transfers the super admin role to a new address.
    /// @param _superAdmin The address of the new super admin.
    function transferSuperAdmin(address _superAdmin) external;
}

/// @title IAdminStructure
/// @dev Interface for managing admin roles.
interface IAdminStructure is ISuperAdmin {
    /// @dev Emitted when an admin is added.
    /// @param admin The address of the added admin.
    event AddedAdmin(address admin);

    /// @dev Emitted when an admin is removed.
    /// @param admin The address of the removed admin.
    event RemovedAdmin(address admin);

    /// @notice Checks if the caller is a valid admin.
    /// @param caller The address to check.
    function isValidAdmin(address caller) external view;

    /// @notice Checks if an account is an admin.
    /// @param account The address to check.
    /// @return A boolean indicating if the account is an admin.
    function isAdmin(address account) external view returns (bool);

    /// @notice Adds multiple addresses as admins.
    /// @param _admins The addresses to add as admins.
    function addAdmins(address[] memory _admins) external;

    /// @notice Removes multiple addresses from admins.
    /// @param _admins The addresses to remove from admins.
    function removeAdmins(address[] memory _admins) external;

    /// @notice Returns all the admin addresses.
    /// @return An array of admin addresses.
    function getAllAdmins() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title IStrategyCalculations
/// @notice Interface for the Strategy Calculations contract
/// @dev This interface provides functions for performing various calculations related to the strategy.
interface IStrategyCalculations {
    /// @return The address of the Admin Structure contract
    function adminStructure() external view returns (address);

    /// @return The address of the Strategy contract
    function strategy() external view returns (address);

    /// @return The address of the Quoter contract
    function quoter() external view returns (address);

    /// @dev Constant for representing 100 (100%)
    /// @return The value of 100
    function ONE_HUNDRED() external pure returns (uint256);

    /// @notice Calculates the minimum amount of tokens to receive from Curve for a specific token and maximum amount
    /// @param _token The address of the token to withdraw
    /// @param _maxAmount The maximum amount of tokens to withdraw
    /// @param _slippage The allowed slippage percentage
    /// @return The minimum amount of tokens to receive from Curve
    function calculateCurveMinWithdrawal(
        address _token,
        uint256 _maxAmount,
        uint256 _slippage
    ) external view returns (uint256);

    /// @notice Calculates the amount of LP tokens to get on curve deposit
    /// @param _token The token to estimate the deposit
    /// @param _amount The amount of tokens to deposit
    /// @param _slippage The allowed slippage percentage
    /// @return The amount of LP tokens to get
    function calculateCurveDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256);

    /// @notice Estimates the amount of tokens to swap from one token to another
    /// @param _from The address of the token to swap from
    /// @param _to The address of the token to swap to
    /// @param _amount The amount of tokens to swap
    /// @param _slippage The allowed slippage percentage
    /// @return estimate The estimated amount of tokens to receive after the swap
    function estimateSwap(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256 estimate);

    /// @notice Estimates the deposit details for a specific token and amount
    /// @param _token The address of the token to deposit
    /// @param _amount The amount of tokens to deposit
    /// @param _slippage The allowed slippage percentage
    /// @return amountWant The minimum amount of tokens to get on the curve deposit
    function estimateDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256 amountWant);

    /// @notice Estimates the withdrawal details for a specific user, token, maximum amount, and slippage
    /// @param _user The address of the user
    /// @param _token The address of the token to withdraw
    /// @param _maxAmount The maximum amount of tokens to withdraw
    /// @param _slippage The allowed slippage percentage
    /// @return minCurveOutput The minimum amount of tokens to get from the curve withdrawal
    /// @return withdrawable The minimum amount of tokens to get after the withdrawal
    function estimateWithdrawal(
        address _user,
        address _token,
        uint256 _maxAmount,
        uint256 _slippage
    ) external returns (uint256 minCurveOutput, uint256 withdrawable);

    /// @notice Estimates the rewards details for a specific user, token, amount, and slippage
    /// @param _user The address of the user
    /// @param _token The address of the token to calculate rewards for
    /// @param _amount The amount of tokens
    /// @param _slippage The allowed slippage percentage
    /// @return minCurveOutput The minimum amount of tokens to get from the curve withdrawal
    /// @return claimable The minimum amount of tokens to get after the claim of rewards
    function estimateRewards(
        address _user,
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256 minCurveOutput, uint256 claimable);

    /// @notice Estimates the total claimable rewards for all users using a specific token and slippage
    /// @param _token The address of the token to calculate rewards for
    /// @param _amount The amount of tokens
    /// @param _slippage The allowed slippage percentage
    /// @return claimable The total claimable amount of tokens
    function estimateAllUsersRewards(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256 claimable);

    /// @dev Returns the amount of tokens deposited by a specific user in the indicated token
    /// @param _user The address of the user.
    /// @param _token The address of the token.
    /// @return The amount of tokens deposited by the user.
    function userDeposit(address _user, address _token) external view returns (uint256);

    /// @dev Returns the total amount of tokens deposited in the strategy in the indicated token
    /// @param _token The address of the token.
    /// @return The total amount of tokens deposited.
    function totalDeposits(address _token) external view returns (uint256);

    /// @notice Retrieves the minimum amount of tokens to swap from a specific fromToken to toToken
    /// @param _fromToken The address of the token to swap from
    /// @param _toToken The address of the token to swap to
    /// @return The minimum amount of tokens to swap
    function getAutomaticSwapMin(address _fromToken, address _toToken) external returns (uint256);

    /// @notice Retrieves the minimum amount of LP tokens to obtained from a curve deposit
    /// @param _depositAmount The amount to deposit
    /// @return The minimum amount of LP tokens to obtained from the deposit on curve
    function getAutomaticCurveMinLp(uint256 _depositAmount) external returns (uint256);

    /// @notice Retrieves the balance of a specific token held by the Strategy
    /// @param _token The address of the token
    /// @return The token balance
    function _getTokenBalance(address _token) external view returns (uint256);

    /// @notice Retrieves the minimum value between a specific amount and a slippage percentage
    /// @param _amount The amount
    /// @param _slippage The allowed slippage percentage
    /// @return The minimum value
    function _getMinimum(uint256 _amount, uint256 _slippage) external pure returns (uint256);

    /// @notice Formats the array input for curve
    /// @param _depositToken The address of the deposit token
    /// @param _amount The amount to deposit
    /// @return amounts An array of token amounts to use in curve
    function getCurveAmounts(
        address _depositToken,
        uint256 _amount
    ) external view returns (uint256[2] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "./IStrategyCalculations.sol";

/// @title IStrategyConvexL2
/// @notice Interface for the Convex L2 Strategy contract
interface IStrategyConvexL2 {
    /// @dev Struct representing a pool token
    struct PoolToken {
        bool isAllowed; /// Flag indicating if the token is allowed
        uint8 index; /// Index of the token
    }

    /// @dev Struct representing an oracle
    struct Oracle {
        address token; /// Token address
        address oracle; /// Oracle address
    }

    /// @dev Struct representing default slippages
    struct DefaultSlippages {
        uint256 curve; /// Default slippage for Curve swaps
        uint256 uniswap; /// Default slippage for Uniswap swaps
    }

    /// @dev Struct representing reward information
    struct RewardInfo {
        address[] tokens; /// Array of reward tokens
        uint256[] minAmount; /// Array of minimum reward amounts
    }

    /// @dev Enum representing fee types
    enum FeeType {
        MANAGEMENT, /// Management fee
        PERFORMANCE /// Performance fee
    }

    /// @dev Event emitted when a harvest is executed
    /// @param harvester The address of the harvester
    /// @param amount The amount harvested
    /// @param wantBal The balance of the want token after the harvest
    event Harvested(address indexed harvester, uint256 amount, uint256 wantBal);

    /// @dev Event emitted when a deposit is made
    /// @param user The address of the user
    /// @param token The address of the token deposited
    /// @param wantBal The balance of the want token generated with the deposit
    event Deposit(address user, address token, uint256 wantBal);

    /// @dev Event emitted when a withdrawal is made
    /// @param user The address of the user
    /// @param token The address of the token being withdrawn
    /// @param amount The amount withdrawn
    /// @param wantBal The balance of the want token after the withdrawal
    event Withdraw(address user, address token, uint256 amount, uint256 wantBal);

    /// @dev Event emitted when rewards are claimed
    /// @param user The address of the user
    /// @param token The address of the reward token
    /// @param amount The amount of rewards claimed
    /// @param wantBal The balance of the want token after claiming rewards
    event ClaimedRewards(address user, address token, uint256 amount, uint256 wantBal);

    /// @dev Event emitted when fees are charged
    /// @param feeType The type of fee (Management or Performance)
    /// @param amount The amount of fees charged
    /// @param feeRecipient The address of the fee recipient
    event ChargedFees(FeeType indexed feeType, uint256 amount, address feeRecipient);

    /// @dev Event emitted when allowed tokens are edited
    /// @param token The address of the token
    /// @param status The new status (true or false)
    event EditedAllowedTokens(address token, bool status);

    /// @dev Event emitted when the pause status is changed
    /// @param status The new pause status (true or false)
    event PauseStatusChanged(bool status);

    /// @dev Event emitted when a swap path is set
    /// @param from The address of the token to swap from
    /// @param to The address of the token to swap to
    /// @param path The swap path
    event SetPath(address from, address to, bytes path);

    /// @dev Event emitted when a swap route is set
    /// @param from The address of the token to swap from
    /// @param to The address of the token to swap to
    /// @param route The swap route
    event SetRoute(address from, address to, address[] route);

    /// @dev Event emitted when an oracle is set
    /// @param token The address of the token
    /// @param oracle The address of the oracle
    event SetOracle(address token, address oracle);

    /// @dev Event emitted when the slippage value is set
    /// @param oldValue The old slippage value
    /// @param newValue The new slippage value
    /// @param kind The kind of slippage (Curve or Uniswap)
    event SetSlippage(uint256 oldValue, uint256 newValue, string kind);

    /// @dev Event emitted when the minimum amount to harvest is changed
    /// @param token The address of the token
    /// @param minimum The new minimum amount to harvest
    event MinimumToHarvestChanged(address token, uint256 minimum);

    /// @dev Event emitted when a reward token is added
    /// @param token The address of the reward token
    /// @param minimum The minimum amount of the reward token
    event AddedRewardToken(address token, uint256 minimum);

    /// @dev Event emitted when a panic is executed
    event PanicExecuted();
}

/// @title IStrategyConvexL2Extended
/// @notice Extended interface for the Convex L2 Strategy contract
interface IStrategyConvexL2Extended is IStrategyConvexL2 {
    /// @dev Returns the address of the pool contract
    /// @return The address of the pool contract
    function pool() external view returns (address);

    /// @dev Returns the address of the calculations contract
    /// @return The address of the calculations contract
    function calculations() external view returns (IStrategyCalculations);

    /// @dev Returns the address of the admin structure contract
    /// @return The address of the admin structure contract
    function adminStructure() external view returns (address);

    /// @dev Deposits tokens into the strategy
    /// @param _token The address of the token to deposit
    /// @param _user The address of the user
    /// @param _minWant The minimum amount of want tokens to get from curve
    function deposit(address _token, address _user, uint256 _minWant) external;

    /// @dev Executes the harvest operation, it is also the function compound, reinvests rewards
    function harvest() external;

    /// @dev Executes a panic operation, withdraws all the rewards from convex
    function panic() external;

    /// @dev Pauses the strategy, pauses deposits
    function pause() external;

    /// @dev Unpauses the strategy
    function unpause() external;

    /// @dev Withdraws tokens from the strategy
    /// @param _user The address of the user
    /// @param _amount The amount of tokens to withdraw
    /// @param _token The address of the token to withdraw
    /// @param _minCurveOutput The minimum LP output from Curve
    function withdraw(
        address _user,
        uint256 _amount,
        address _token,
        uint256 _minCurveOutput
    ) external;

    /// @dev Claims rewards for the user
    /// @param _user The address of the user
    /// @param _token The address of the reward token
    /// @param _amount The amount of rewards to claim
    /// @param _minCurveOutput The minimum LP token output from Curve swap
    function claimRewards(
        address _user,
        address _token,
        uint256 _amount,
        uint256 _minCurveOutput
    ) external;

    /// @dev Returns the address of the reward pool contract
    /// @return The address of the reward pool contract
    function rewardPool() external view returns (address);

    /// @dev Returns the address of the deposit token
    /// @return The address of the deposit token
    function depositToken() external view returns (address);

    /// @dev Checks if a token is allowed for deposit
    /// @param token The address of the token
    /// @return isAllowed True if the token is allowed, false otherwise
    /// @return index The index of the token
    function allowedDepositTokens(address token) external view returns (bool, uint8);

    /// @dev Returns the swap path for a token pair
    /// @param _from The address of the token to swap from
    /// @param _to The address of the token to swap to
    /// @return The swap path
    function paths(address _from, address _to) external view returns (bytes memory);

    /// @dev Returns the want deposit amount of a user in the deposit token
    /// @param _user The address of the user
    /// @return The deposit amount for the user
    function userWantDeposit(address _user) external view returns (uint256);

    /// @dev Returns the total want deposits in the strategy
    /// @return The total deposits in the strategy
    function totalWantDeposits() external view returns (uint256);

    /// @dev Returns the oracle address for a token
    /// @param _token The address of the token
    /// @return The oracle address
    function oracle(address _token) external view returns (address);

    /// @dev Returns the default slippage for Curve swaps used in harvest
    /// @return The default slippage for Curve swaps
    function defaultSlippageCurve() external view returns (uint256);

    /// @dev Returns the default slippage for Uniswap swaps used in harvest
    /// @return The default slippage for Uniswap swaps
    function defaultSlippageUniswap() external view returns (uint256);

    /// @dev Returns the want token
    /// @return The want token
    function want() external view returns (IERC20Upgradeable);

    /// @dev Returns the balance of the strategy held in the strategy
    /// @return The balance of the strategy
    function balanceOf() external view returns (uint256);

    /// @dev Returns the balance of the want token held in the strategy
    /// @return The balance of the want token
    function balanceOfWant() external view returns (uint256);

    /// @dev Returns the balance of want in the strategy
    /// @return The balance of the pool
    function balanceOfPool() external view returns (uint256);

    /// @dev Returns the pause status of the strategy
    /// @return True if the strategy is paused, false otherwise
    function paused() external view returns (bool);

    /// @dev Returns the address of the Uniswap router
    /// @return The address of the Uniswap router
    function unirouter() external view returns (address);

    /// @dev Returns the address of the vault contract
    /// @return The address of the vault contract
    function vault() external view returns (address);

    /// @dev Returns the address of Uniswap V2 router
    /// @return The address of Uniswap V2 router
    function unirouterV2() external view returns (address);

    /// @dev Returns the address of Uniswap V3 router
    /// @return The address of Uniswap V3 router
    function unirouterV3() external view returns (address);

    /// @dev Returns the performance fee
    /// @return The performance fee
    function performanceFee() external view returns (uint256);

    /// @dev Returns the management fee
    /// @return The management fee
    function managementFee() external view returns (uint256);

    /// @dev Returns the performance fee recipient
    /// @return The performance fee recipient
    function performanceFeeRecipient() external view returns (address);

    /// @dev Returns the management fee recipient
    /// @return The management fee recipient
    function managementFeeRecipient() external view returns (address);

    /// @dev Returns the fee cap
    /// @return The fee cap
    function FEE_CAP() external view returns (uint256);

    /// @dev Returns the constant value of 100
    /// @return The constant value of 100
    function ONE_HUNDRED() external view returns (uint256);

    /// @dev Sets the performance fee
    /// @param _fee The new performance fee
    function setPerformanceFee(uint256 _fee) external;

    /// @dev Sets the management fee
    /// @param _fee The new management fee
    function setManagementFee(uint256 _fee) external;

    /// @dev Sets the performance fee recipient
    /// @param recipient The new performance fee recipient
    function setPerformanceFeeRecipient(address recipient) external;

    /// @dev Sets the management fee recipient
    /// @param recipient The new management fee recipient
    function setManagementFeeRecipient(address recipient) external;

    /// @dev Sets the vault contract
    /// @param _vault The address of the vault contract
    function setVault(address _vault) external;

    /// @dev Sets the Uniswap V2 router address
    /// @param _unirouterV2 The address of the Uniswap V2 router
    function setUnirouterV2(address _unirouterV2) external;

    /// @dev Sets the Uniswap V3 router address
    /// @param _unirouterV3 The address of the Uniswap V3 router
    function setUnirouterV3(address _unirouterV3) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/dollet/IAdminStructure.sol";
import { IStrategyConvexL2Extended as IStrategyConvex } from "../interfaces/dollet/IStrategyConvexL2.sol";

/**
 * @dev Implementation of a vault to deposit funds for yield optimizing.
 * @notice This is the contract that receives funds and that users interface with.
 * @notice The yield optimizing strategy itself is implemented in a separate 'Strategy.sol' contract.
 */
contract DolletVault is ERC20Upgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev The strategy currently in use by the vault.
     */
    IStrategyConvex public strategy;
    /**
     * @dev Contract that stores the information of the admins.
     */
    IAdminStructure public adminStructure;

    /**
     * @dev Stores the deposit limit amounts for a token
     */
    mapping(address => DepositLimit) public tokenDepositLimit;

    /**
     * @notice Structure of the values stored in the token deposit limits
     */
    struct DepositLimit {
        address token; // Address of the token
        uint256 minAmount; // Minimum amount allowed for deposits
        uint256 maxAmount; // Maximum amount allowed for deposits
    }
    /**
     * @notice Logs when the deposit limit of a token has been changed
     * @param limitBefore Structure of the deposit limit before
     * @param limitAfter Structure of the deposit limit after
     */
    event EditedDepositLimits(DepositLimit limitBefore, DepositLimit limitAfter);

    /**
     * @notice Logs when stucked tokens have been withdrawn
     * @param caller Address of the caller of the transaction
     * @param token Address of the token withdrawn
     * @param amount Withdrawn amount
     */
    event WithdrawStuckTokens(address caller, address token, uint256 amount);

    /**
     * @dev Initializes the vault values like the admin stucture contract, strategy, name
     * @dev Symbol, and the deposit limits.
     * @param _adminStructure The address of the admin stucture contract.
     * @param _strategy The address of the strategy contract.
     * @param _name The name of the vault token.
     * @param _symbol The symbol of the vault token.
     * @param _depositLimits Array indicating the deposit limits
     */
    function initialize(
        IAdminStructure _adminStructure,
        IStrategyConvex _strategy,
        string memory _name,
        string memory _symbol,
        DepositLimit[] memory _depositLimits
    ) external initializer {
        __ERC20_init(_name, _symbol);
        __ReentrancyGuard_init();
        strategy = _strategy;
        require(address(_adminStructure) != address(0), "ZeroAdminStructure");
        adminStructure = _adminStructure;
        for (uint256 i = 0; i < _depositLimits.length; i++) {
            tokenDepositLimit[_depositLimits[i].token] = _depositLimits[i];
        }
    }

    /**
     * @dev The entrypoint of funds into the system. People deposit with this function
     * into the vault. The vault is then in charge of sending funds into the strategy.
     * @param _amount Amount to be deposited
     * @param _token Address of token to be deposited
     * @param _minWant Minimum amount obtained fromt he deposit on curve
     */
    function deposit(
        uint256 _amount,
        IERC20Upgradeable _token,
        uint256 _minWant
    ) external nonReentrant {
        _validateDepositLimit(_token, _amount);
        strategy.harvest();

        uint256 _before = balance();
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        earn(_token, _minWant);
        uint256 _after = balance();
        _amount = _after - _before;
        uint256 _shares = 0;
        if (totalSupply() == 0) {
            _shares = _amount;
        } else {
            _shares = (_amount * totalSupply()) / _before;
        }
        _mint(msg.sender, _shares);
    }

    /**
     * @dev Function to exit the system. The vault will withdraw the required tokens
     * from the strategy and pay up the token holder. A proportional number of dollet vault
     * tokens are burned in the process.
     * @param _token The token to be received in the withdrawal
     * @param _minCurveOutput Minimum amount tokens obtained from curve
     */
    function withdrawAll(address _token, uint256 _minCurveOutput) external nonReentrant {
        uint256 _shares = balanceOf(msg.sender);
        require(_shares > 0, "UserHasZeroLP");
        uint256 _amount = (balance() * _shares) / totalSupply();
        _burn(msg.sender, _shares);
        strategy.withdraw(msg.sender, _amount, _token, _minCurveOutput);
        uint256 _tokenBal = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).safeTransfer(msg.sender, _tokenBal);
    }

    /**
     * @dev Claims rewards from the Vault for a specific token.
     * @param _token The address of the token to claim rewards for.
     * @param _minCurveOutput The minimum amount of tokens to receive from Curve.
     */
    function claimRewards(address _token, uint256 _minCurveOutput) external nonReentrant {
        uint256 _before = balance();
        uint256 _shares = balanceOf(msg.sender);
        require(_shares > 0, "UserHasZeroLP");
        uint256 _amount = (_before * _shares) / totalSupply();
        strategy.claimRewards(msg.sender, _token, _amount, _minCurveOutput);
        uint256 _after = balance();
        uint256 _wantSpent = _before - _after;
        uint256 _amountLP = (_wantSpent * totalSupply()) / _before;
        _burn(msg.sender, _amountLP);
        uint256 _tokenBal = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).safeTransfer(msg.sender, _tokenBal);
    }

    /**
     * @dev Estimates the deposit details for a specific token and amount.
     * @param _token The address of the token to deposit.
     * @param _amount The amount of tokens to deposit.
     * @param _slippage The allowed slippage percentage.
     * @return amountLP The amount of LP tokens to receive from the vault
     * @return amountWant The minimum amount of LP tokens to get from curve deposit
     */
    function estimateDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256 amountLP, uint256 amountWant) {
        uint256 _before = balance();
        amountWant = strategy.calculations().estimateDeposit(_token, _amount, _slippage);
        if (totalSupply() == 0) {
            amountLP = amountWant;
        } else {
            amountLP = (amountWant * totalSupply()) / _before;
        }
    }

    /**
     * @dev Estimates the withdrawal details for a specific user and token.
     * @param _user The address of the user.
     * @param _token The address of the token to withdraw.
     * @param _slippage The allowed slippage percentage.
     * @return minCurveOutput The minimum amount of tokens to receive from Curve.
     * @return withdrawable The amount of tokens available that will be accepted from the withdrawal.
     */
    function estimateWithdrawal(
        address _user,
        address _token,
        uint256 _slippage
    ) external returns (uint256 minCurveOutput, uint256 withdrawable) {
        uint256 _balanceUser = balanceOf(_user);
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0 || _balanceUser == 0) return (0, 0);
        uint256 _amount = (balance() * _balanceUser) / _totalSupply;
        return strategy.calculations().estimateWithdrawal(_user, _token, _amount, _slippage);
    }

    /**
     * @dev Estimates the rewards details for a specific user and token.
     * @param _user The address of the user.
     * @param _token The address of the token to check rewards for.
     * @param _slippage The allowed slippage percentage.
     * @return minCurveOutput The minimum amount of tokens to receive from Curve.
     * @return claimable The amount of tokens claimable as rewards.
     */
    function estimateRewards(
        address _user,
        address _token,
        uint256 _slippage
    ) external returns (uint256 minCurveOutput, uint256 claimable) {
        uint256 _balanceUser = balanceOf(_user);
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0 || _balanceUser == 0) return (0, 0);
        uint256 amount = (balance() * _balanceUser) / _totalSupply;
        (minCurveOutput, claimable) = strategy.calculations().estimateRewards(
            _user,
            _token,
            amount,
            _slippage
        );
    }

    /**
     * @dev Estimates the total rewards claimable for all users for a specific token.
     * @param _token The address of the token to check rewards for.
     * @param _slippage The allowed slippage percentage.
     * @return claimable The total amount of tokens claimable as rewards.
     */
    function estimateAllUsersRewards(
        address _token,
        uint256 _slippage
    ) external returns (uint256 claimable) {
        claimable = strategy.calculations().estimateAllUsersRewards(_token, balance(), _slippage);
    }

    /**
     * @dev Allows the super admin to set the strategy
     * @param _strategy The address of the strategy
     */
    function setStrategy(IStrategyConvex _strategy) external {
        adminStructure.isValidSuperAdmin(msg.sender);
        require(address(_strategy) != address(0), "ZeroStrategy");
        strategy = _strategy;
    }

    /**
     * @dev Handles the case where tokens get stuck in the Vault. Allows the admin to send the tokens to the super admin
     * @param _token The address of the stuck token.
     */
    function inCaseTokensGetStuck(address _token) external {
        adminStructure.isValidAdmin(msg.sender);
        require(_token != address(want()), "ZeroToken");

        uint256 _amount = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).safeTransfer(adminStructure.superAdmin(), _amount);
        emit WithdrawStuckTokens(msg.sender, _token, _amount);
    }

    /**
     * @dev Edits the deposit limits for specific tokens.
     * @param _depositLimits The array of DepositLimit structs representing the new deposit limits.
     */
    function editDepositLimits(DepositLimit[] memory _depositLimits) external {
        adminStructure.isValidAdmin(msg.sender);
        for (uint256 i = 0; i < _depositLimits.length; i++) {
            emit EditedDepositLimits(tokenDepositLimit[_depositLimits[i].token], _depositLimits[i]);
            tokenDepositLimit[_depositLimits[i].token] = _depositLimits[i];
        }
    }

    /**
     * @notice Estimates the amount of tokens to swap from one token to another
     * @param _from The address of the token to swap from
     * @param _to The address of the token to swap to
     * @param _amount The amount of tokens to swap
     * @param _slippage The allowed slippage percentage
     * @return estimate The estimated amount of tokens to receive after the swap
     */
    function estimateSwap(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256 estimate) {
        return strategy.calculations().estimateSwap(_from, _to, _amount, _slippage);
    }

    /**
     * @dev Calculates the minimum amount of tokens to receive from Curve for a specific token and maximum amount.
     * @param _token The address of the token to withdraw.
     * @param _amount The amount of LP tokens to withdraw from curve.
     * @param _slippage The allowed slippage percentage.
     * @return The minimum amount of tokens to receive from Curve.
     */
    function calculateCurveMinWithdrawal(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256) {
        return strategy.calculations().calculateCurveMinWithdrawal(_token, _amount, _slippage);
    }

    /**
     * @notice Calculates the amount of LP tokens to get on curve deposit
     * @param _amount The amount of tokens to deposit
     * @param _slippage The allowed slippage percentage
     * @return The amount of LP tokens to get
     */
    function calculateCurveDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256) {
        return strategy.calculations().calculateCurveDeposit(_token, _amount, _slippage);
    }

    /**
     * @dev Returns the amount of tokens deposited by a specific user in the indicated token
     * @param _user The address of the user.
     * @param _token The address of the token.
     * @return The amount of tokens deposited by the user.
     */
    function userDeposit(address _user, address _token) external view returns (uint256) {
        return strategy.calculations().userDeposit(_user, _token);
    }

    /**
     * @dev Returns the total amount of tokens deposited in the strategy in the indicated token
     * @param _token The address of the token.
     * @return The total amount of tokens deposited.
     */
    function totalDeposits(address _token) external view returns (uint256) {
        return strategy.calculations().totalDeposits(_token);
    }

    /**
     * @dev Returns the address of the token that the Vault holds.
     * @return The address of the want token
     */
    function want() public view returns (IERC20Upgradeable) {
        return IERC20Upgradeable(strategy.want());
    }

    /**
     * @dev Calculated the total balance of the want token
     * It takes into account the vault contract balance, the strategy contract balance
     * and the balance deployed in other contracts as part of the strategy.
     * @return The total balance of the want token
     */
    function balance() public view returns (uint256) {
        return want().balanceOf(address(this)) + IStrategyConvex(strategy).balanceOf();
    }

    /**
     * @dev Function to send funds into the strategy and put them to work.
     * @dev It's primarily called by the vault's deposit() function.
     * @param _token The token used in the deposit
     */
    function earn(IERC20Upgradeable _token, uint256 _minWant) internal {
        uint256 _tokenBal = _token.balanceOf(address(this));
        _token.safeTransfer(address(strategy), _tokenBal);
        strategy.deposit(address(_token), msg.sender, _minWant);
    }

    /**
     * @dev Override of the internal function of ERC20 token transfer.
     * @dev Implemented to disable transfers on the Dollet LP token.
     */
    function _transfer(address, address, uint256) internal pure override {
        revert("DisabledTransfers");
    }

    /**
     * @dev Validated the deposit limits for specific tokens.
     * @param _token Address of the token to validate.
     * @param _amount Amount to validate.
     */
    function _validateDepositLimit(IERC20Upgradeable _token, uint256 _amount) private view {
        DepositLimit memory depositLimits = tokenDepositLimit[address(_token)];
        require(
            _amount >= depositLimits.minAmount && _amount <= depositLimits.maxAmount,
            "InvalidDepositAmount"
        );
    }
}