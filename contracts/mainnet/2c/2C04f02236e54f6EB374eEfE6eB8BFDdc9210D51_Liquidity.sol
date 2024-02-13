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
library SafeMathUpgradeable {
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
library EnumerableSetUpgradeable {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IDistributor.sol";
import "./interfaces/IDegenPoolStorage.sol";
import "./libraries/LibPoolStorage.sol";
import "./libraries/LibReferenceOracle.sol";
import "./libraries/LibTypeCast.sol";
import "./Types.sol";
import "./third-party/Diamond.sol";

/**
 * @dev this contract just holds the storage. all functions are in the ./facets/*.sol.
 *      you are probably looking for ./interfaces/IDegenPool.sol.
 *
 *      note: do not write a public function here, because we do not deploy this contract.
 */
contract DegenPoolStorage is Initializable, ContextUpgradeable, ReentrancyGuardUpgradeable, IDegenPoolStorage {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using LibTypeCast for uint256;
    using LibPoolStorage for PoolStorage;
    using LibAsset for Asset;
    using LibReferenceOracle for PoolStorage;

    PoolStorage internal _storage;
    bytes32[20] __gaps;

    modifier updateSequence() {
        _;
        unchecked {
            _storage.sequence += 1;
        }
        emit UpdateSequence(_storage.sequence);
    }

    modifier updateBrokerTransactions() {
        _;
        unchecked {
            _storage.brokerTransactions += 1;
        }
    }

    modifier onlyDiamondOwner() {
        require(_diamondOwner() == _msgSender(), "OWN"); // not OWNer
        _;
    }

    modifier onlyOrderBook() {
        require(_msgSender() == _storage.orderBook(), "BOK");
        _;
    }

    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp);
    }

    // @dev set token.spotLiquidity -= wadAmount outside this function
    function _collectFee(uint8 tokenId, address trader, uint96 wadAmount) internal {
        emit CollectedFee(tokenId, wadAmount);
        Asset storage collateral = _storage.assets[tokenId];
        require(collateral.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        address tokenAddress = collateral.tokenAddress();
        uint256 rawAmount = collateral.toRaw(wadAmount);
        address distributor = _storage.feeDistributor();
        IERC20Upgradeable(tokenAddress).safeTransfer(distributor, rawAmount);
        IDistributor(distributor).updateRewards(tokenId, tokenAddress, trader, rawAmount.toUint96());
    }

    function _diamondOwner() internal view returns (address) {
        return LibDiamond.contractOwner();
    }

    function _checkAllMarkPrices(uint96[] memory markPrices) internal returns (uint96[] memory) {
        uint256 assetCount = _storage.assetsCount;
        require(markPrices.length == assetCount, "LEN"); // LENgth is different
        for (uint256 i = 0; i < assetCount; i++) {
            Asset storage asset = _storage.assets[i];
            markPrices[i] = _storage.checkPrice(asset, markPrices[i]);
        }
        return markPrices;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "../interfaces/ILiquidity.sol";

import "../libraries/LibAsset.sol";
import "../libraries/LibSubAccount.sol";
import "../libraries/LibMath.sol";
import "../libraries/LibReferenceOracle.sol";
import "../libraries/LibTypeCast.sol";

import "../DegenPoolStorage.sol";
import "../peripherals/MlpToken.sol";

contract Liquidity is DegenPoolStorage, ILiquidity {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using LibAsset for Asset;
    using LibMath for uint256;
    using LibTypeCast for uint256;
    using LibSubAccount for bytes32;
    using LibPoolStorage for PoolStorage;
    using LibReferenceOracle for PoolStorage;

    /**
     * @dev   Add liquidity.
     *
     * @param trader            liquidity provider address.
     * @param tokenId           asset.id that added.
     * @param rawAmount         asset token amount. decimals = erc20.decimals.
     * @param markPrices        markPrices prices of all supported assets.
     */
    function addLiquidity(
        address trader,
        uint8 tokenId,
        uint256 rawAmount, // NOTE: OrderBook SHOULD transfer rawAmount collateral to LiquidityPool
        uint96[] memory markPrices
    ) external onlyOrderBook updateSequence updateBrokerTransactions returns (uint96 mlpAmount) {
        require(trader != address(0), "T=0"); // Trader address is zero
        require(_storage.isValidAssetId(tokenId), "LST"); // the asset is not LiSTed
        require(rawAmount != 0, "A=0"); // Amount Is Zero
        markPrices = _checkAllMarkPrices(markPrices);
        uint256 totalLiquidityUsd = _storage.poolUsd(markPrices);
        uint96 mlpPrice = _storage.mlpTokenPrice(totalLiquidityUsd);
        Asset storage token = _storage.assets[tokenId];
        require(token.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(token.canAddRemoveLiquidity(), "TUL"); // the Token cannot be Used to add Liquidity
        require(token.isStable(), "FLG");
        uint96 tokenPrice = markPrices[tokenId];

        // token amount
        uint96 wadAmount = token.toWad(rawAmount);
        uint96 feeCollateral = uint256(wadAmount).rmul(_storage.liquidityFeeRate()).toUint96();
        wadAmount -= feeCollateral;
        token.spotLiquidity += wadAmount; // without fee
        _collectFee(tokenId, trader, feeCollateral);
        // mlp
        mlpAmount = ((uint256(wadAmount) * uint256(tokenPrice)) / uint256(mlpPrice)).toUint96();
        MlpToken(_storage.mlpToken()).mint(trader, mlpAmount);
        emit AddLiquidity(trader, tokenId, tokenPrice, mlpPrice, mlpAmount, feeCollateral);
        {
            uint96 liquidityCapUsd = _storage.liquidityCapUsd();
            uint96 tokenUsd = ((uint256(wadAmount) * markPrices[tokenId]) / 1e18).toUint96();
            require(tokenUsd + totalLiquidityUsd <= liquidityCapUsd, "LCP"); // Liquidity Cap is reached
        }
    }

    /**
     * @dev Add liquidity but ignore MLP
     */
    function donateLiquidity(
        address who,
        uint8 tokenId,
        uint256 rawAmount // NOTE: OrderBook SHOULD transfer rawAmount collateral to LiquidityPool
    ) external onlyOrderBook updateSequence {
        require(_storage.isValidAssetId(tokenId), "LST"); // the asset is not LiSTed
        require(rawAmount != 0, "A=0"); // Amount Is Zero
        Asset storage token = _storage.assets[tokenId];
        require(token.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(token.canAddRemoveLiquidity(), "TUL"); // the Token cannot be Used to add Liquidity
        require(token.isStable(), "FLG");

        // token amount
        uint96 wadAmount = token.toWad(rawAmount);
        token.spotLiquidity += wadAmount;
        emit DonateLiquidity(who, tokenId, wadAmount);
    }

    /**
     * @dev   Remove liquidity.
     *
     * @param trader            liquidity provider address.
     * @param mlpAmount         mlp amount.
     * @param tokenId           asset.id that removed to.
     * @param markPrices        asset prices of all supported assets.
     */
    function removeLiquidity(
        address trader,
        uint96 mlpAmount, // NOTE: OrderBook SHOULD transfer mlpAmount mlp to LiquidityPool
        uint8 tokenId,
        uint96[] memory markPrices
    ) external onlyOrderBook updateSequence updateBrokerTransactions returns (uint256 rawAmount) {
        require(trader != address(0), "T=0"); // Trader address is zero
        require(_storage.isValidAssetId(tokenId), "LST"); // the asset is not LiSTed
        require(mlpAmount != 0, "A=0"); // Amount Is Zero
        markPrices = _checkAllMarkPrices(markPrices);
        uint256 totalLiquidityUsd = _storage.poolUsd(markPrices);
        uint96 mlpPrice = _storage.mlpTokenPrice(totalLiquidityUsd);
        Asset storage token = _storage.assets[tokenId];
        require(token.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(token.canAddRemoveLiquidity(), "TUL"); // the Token cannot be Used to remove Liquidity
        require(token.isStable(), "FLG");
        uint96 tokenPrice = markPrices[tokenId];

        // amount
        uint96 wadAmount = ((uint256(mlpAmount) * mlpPrice) / uint256(tokenPrice)).toUint96();
        require(wadAmount <= token.spotLiquidity, "LIQ"); // insufficient LIQuidity
        token.spotLiquidity -= wadAmount; // include fee
        uint96 feeCollateral = uint256(wadAmount).rmul(_storage.liquidityFeeRate()).toUint96();
        wadAmount -= feeCollateral;
        // send token
        _collectFee(tokenId, trader, feeCollateral);
        rawAmount = token.toRaw(wadAmount);
        MlpToken(_storage.mlpToken()).burn(_storage.orderBook(), mlpAmount);
        token.transferOut(trader, rawAmount);
        // reserve
        {
            uint96 reservationUsd = _storage.totalReservationUsd();
            uint96 poolUsd = _storage.poolUsdWithoutPnl(markPrices);
            require(reservationUsd <= poolUsd, "RSV");
        }
        emit RemoveLiquidity(trader, tokenId, tokenPrice, mlpPrice, mlpAmount, feeCollateral);
    }

    /**
     * @notice Broker can update funding each [fundingInterval] seconds by specifying utilizations.
     *
     *         Check _updateFundingState in Liquidity.sol and _getBorrowing in Trade.sol
     *         on how to calculate funding and borrowing.
     */
    function updateFundingState() external updateSequence {
        uint32 nextFundingTime = (_blockTimestamp() / _storage.fundingInterval()) * _storage.fundingInterval();
        if (_storage.lastFundingTime == 0) {
            // init state. just update lastFundingTime
            _storage.lastFundingTime = nextFundingTime;
        } else if (_storage.lastFundingTime + _storage.fundingInterval() >= _blockTimestamp()) {
            // do nothing
        } else {
            uint32 timeSpan = nextFundingTime - _storage.lastFundingTime;
            _updateFundingState(timeSpan);
            _storage.lastFundingTime = nextFundingTime;
        }
    }

    /**
     * @dev Broker can withdraw brokerGasRebate.
     */
    function claimBrokerGasRebate(address receiver, uint8 assetId) external onlyOrderBook returns (uint256 rawAmount) {
        require(receiver != address(0), "RCV"); // bad ReCeiVer
        Asset storage asset = _storage.assets[assetId];
        require(asset.isStable(), "STB"); // the asset is not STaBle
        uint96 wad = (uint256(_storage.brokerGasRebateUsd()) * uint256(_storage.brokerTransactions)).toUint96();
        require(asset.spotLiquidity >= wad, "LIQ"); // insufficient LIQuidity
        asset.spotLiquidity -= wad;
        rawAmount = asset.toRaw(wad);
        emit ClaimBrokerGasRebate(receiver, _storage.brokerTransactions, assetId, rawAmount);
        _storage.brokerTransactions = 0;
        asset.transferOut(receiver, rawAmount);
        return rawAmount;
    }

    /**
     * @dev borrowing + funding design:
     *
     * 1. trader always pays borrowRateApy to LP. this is prevent trader from both long and short the same token.
     * 2. funding = min(1, abs($longs - $shorts）/ alpha) * betaApy.
     * 3. if longs > shorts，longs pay to LP. otherwise short pay to LP. trader never pays to trader.
     */
    function _updateFundingState(uint32 timeSpan) internal {
        uint8 tokenLen = uint8(_storage.assetsCount);
        for (uint8 tokenId = 0; tokenId < tokenLen; tokenId++) {
            Asset storage asset = _storage.assets[tokenId];
            if (asset.isStable()) {
                continue;
            }
            // funding
            uint96 longsUsd = uint256(asset.totalLongPosition).wmul(asset.averageLongPrice).toUint96();
            uint96 shortsUsd = uint256(asset.totalShortPosition).wmul(asset.averageShortPrice).toUint96();
            (
                bool isPositiveFundingRate,
                uint32 newFundingRateApy,
                uint128 longCumulativeFunding,
                uint128 shortCumulativeFunding
            ) = _getFundingRate(asset.fundingAlpha(), asset.fundingBetaApy(), longsUsd, shortsUsd, timeSpan);
            // borrowing
            (uint32 newBorrowingRateApy, uint128 cumulativeBorrowing) = _getBorrowingRate(
                _storage.borrowingRateApy(),
                timeSpan
            );
            asset.longCumulativeFunding += longCumulativeFunding + cumulativeBorrowing;
            asset.shortCumulativeFunding += shortCumulativeFunding + cumulativeBorrowing;
            emit UpdateFundingRate(
                tokenId,
                isPositiveFundingRate,
                newFundingRateApy,
                newBorrowingRateApy,
                asset.longCumulativeFunding,
                asset.shortCumulativeFunding
            );
        }
    }

    /**
     * @dev Funding rate formula.
     */
    function _getFundingRate(
        uint96 alpha, // 1e18, tokens
        uint32 betaApy, // 1e5
        uint96 longsUsd, // 1e18, tokens
        uint96 shortsUsd, // 1e18, tokens
        uint32 timeSpan // 1e0
    )
        internal
        pure
        returns (
            bool isPositiveFundingRate,
            uint32 newFundingRateApy, // 1e5
            uint128 longCumulativeFunding, // 1e18
            uint128 shortCumulativeFunding // 1e18
        )
    {
        require(alpha != 0, "A=0"); // Alpha Is Zero
        // min(1, abs(longs - shorts）/ alpha) * beta
        isPositiveFundingRate = longsUsd >= shortsUsd;
        uint256 x = isPositiveFundingRate ? longsUsd - shortsUsd : shortsUsd - longsUsd;
        if (x > alpha) {
            x = alpha;
        }
        newFundingRateApy = ((uint256(x) * uint256(betaApy)) / uint256(alpha)).toUint32(); // 18 + 5 - 18
        if (isPositiveFundingRate) {
            longCumulativeFunding = ((uint256(newFundingRateApy) * uint256(timeSpan) * 1e13) / APY_PERIOD).toUint128(); // 5 + 0 + 13 - 0
        } else {
            shortCumulativeFunding = ((uint256(newFundingRateApy) * uint256(timeSpan) * 1e13) / APY_PERIOD).toUint128(); // 5 + 0 + 13 - 0
        }
    }

    /**
     * @dev Borrowing rate formula.
     */
    function _getBorrowingRate(
        uint32 borrowingRateApy, // 1e5
        uint32 timeSpan // 1e0
    )
        internal
        pure
        returns (
            uint32 newBorrowingRateApy, // 1e5
            uint128 cumulativeBorrowing // 1e18
        )
    {
        newBorrowingRateApy = borrowingRateApy;
        cumulativeBorrowing = ((uint256(newBorrowingRateApy) * uint256(timeSpan) * 1e13) / APY_PERIOD).toUint128(); // 5 + 0 + 13 - 0
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

interface IDegenPoolStorage {
    event UpdateSequence(uint256 sequence);
    event CollectedFee(uint8 tokenId, uint96 wadFeeCollateral);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

interface IDistributor {
    function updateRewards(uint8 tokenId, address tokenAddress, address trader, uint96 rawAmount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

interface ILiquidity {
    event AddLiquidity(
        address indexed trader,
        uint8 indexed tokenId,
        uint96 tokenPrice,
        uint96 mlpPrice,
        uint96 mlpAmount,
        uint96 fee
    );

    event DonateLiquidity(address indexed who, uint8 indexed tokenId, uint96 wadAmount);

    event RemoveLiquidity(
        address indexed trader,
        uint8 indexed tokenId,
        uint96 tokenPrice,
        uint96 mlpPrice,
        uint96 mlpAmount,
        uint96 fee
    );

    event ClaimBrokerGasRebate(address indexed receiver, uint32 transactions, uint8 assetId, uint256 rawAmount);

    event UpdateFundingRate(
        uint8 indexed tokenId,
        bool isPositiveFundingRate,
        uint32 newFundingRateApy, // 1e5
        uint32 newBorrowingRateApy, // 1e5
        uint128 longCumulativeFunding, // 1e18
        uint128 shortCumulativeFunding // 1e18
    );

    /**
     * @dev   Add liquidity.
     *
     * @param trader            liquidity provider address.
     * @param tokenId           asset.id that added.
     * @param rawAmount         asset token amount. decimals = erc20.decimals.
     * @param markPrices        markPrices prices of all supported assets.
     */
    function addLiquidity(
        address trader,
        uint8 tokenId,
        uint256 rawAmount, // NOTE: OrderBook SHOULD transfer rawAmount collateral to LiquidityPool
        uint96[] memory markPrices
    ) external returns (uint96 mlpAmount);

    /**
     * @dev Add liquidity but ignore MLP
     */
    function donateLiquidity(
        address who,
        uint8 tokenId,
        uint256 rawAmount // NOTE: OrderBook SHOULD transfer rawAmount collateral to LiquidityPool
    ) external;

    /**
     * @dev   Remove liquidity.
     *
     * @param trader            liquidity provider address.
     * @param mlpAmount         mlp amount.
     * @param tokenId           asset.id that removed to.
     * @param markPrices        asset prices of all supported assets.
     */
    function removeLiquidity(
        address trader,
        uint96 mlpAmount,
        uint8 tokenId,
        uint96[] memory markPrices
    ) external returns (uint256 rawAmount);

    /**
     * @notice Broker can update funding each [fundingInterval] seconds by specifying utilizations.
     *
     *         Check _updateFundingState in Liquidity.sol and _getBorrowing in Trade.sol
     *         on how to calculate funding and borrowing.
     */
    function updateFundingState() external;

    /**
     * @dev Broker can withdraw brokerGasRebate.
     */
    function claimBrokerGasRebate(address receiver, uint8 assetId) external returns (uint256 rawAmount);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "../libraries/LibConfigKeys.sol";
import "../libraries/LibTypeCast.sol";
import "../libraries/LibMath.sol";
import "../Types.sol";
import "../libraries/LibAsset.sol";

library LibAsset {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using LibMath for uint256;
    using LibTypeCast for bytes32;
    using LibTypeCast for uint256;
    using LibConfigKeys for bytes32;

    function symbol(Asset storage asset) internal view returns (bytes32) {
        return asset.parameters[LibConfigKeys.SYMBOL];
    }

    function decimals(Asset storage asset) internal view returns (uint256) {
        return asset.parameters[LibConfigKeys.DECIMALS].toUint256();
    }

    function tokenAddress(Asset storage asset) internal view returns (address) {
        return asset.parameters[LibConfigKeys.TOKEN_ADDRESS].toAddress();
    }

    function initialMarginRate(Asset storage asset) internal view returns (uint32) {
        return asset.parameters[LibConfigKeys.INITIAL_MARGIN_RATE].toUint32();
    }

    function maintenanceMarginRate(Asset storage asset) internal view returns (uint32) {
        return asset.parameters[LibConfigKeys.MAINTENANCE_MARGIN_RATE].toUint32();
    }

    function minProfitRate(Asset storage asset) internal view returns (uint32) {
        return asset.parameters[LibConfigKeys.MIN_PROFIT_RATE].toUint32();
    }

    function minProfitTime(Asset storage asset) internal view returns (uint32) {
        return asset.parameters[LibConfigKeys.MIN_PROFIT_TIME].toUint32();
    }

    function positionFeeRate(Asset storage asset) internal view returns (uint32) {
        return asset.parameters[LibConfigKeys.POSITION_FEE_RATE].toUint32();
    }

    function liquidationFeeRate(Asset storage asset) internal view returns (uint32) {
        return asset.parameters[LibConfigKeys.LIQUIDATION_FEE_RATE].toUint32();
    }

    function referenceOracle(Asset storage asset) internal view returns (address) {
        return asset.parameters[LibConfigKeys.REFERENCE_ORACLE].toAddress();
    }

    function referenceDeviation(Asset storage asset) internal view returns (uint32) {
        return asset.parameters[LibConfigKeys.REFERENCE_DEVIATION].toUint32();
    }

    function referenceOracleType(Asset storage asset) internal view returns (uint32) {
        return asset.parameters[LibConfigKeys.REFERENCE_ORACLE_TYPE].toUint32();
    }

    function fundingAlpha(Asset storage asset) internal view returns (uint96) {
        return asset.parameters[LibConfigKeys.FUNDING_ALPHA].toUint96();
    }

    function fundingBetaApy(Asset storage asset) internal view returns (uint32) {
        return asset.parameters[LibConfigKeys.FUNDING_BETA_APY].toUint32();
    }

    function maxLongPositionSize(Asset storage asset) internal view returns (uint96) {
        return asset.parameters[LibConfigKeys.MAX_LONG_POSITION_SIZE].toUint96();
    }

    function maxShortPositionSize(Asset storage asset) internal view returns (uint96) {
        return asset.parameters[LibConfigKeys.MAX_SHORT_POSITION_SIZE].toUint96();
    }

    function adlReserveRate(Asset storage asset) internal view returns (uint32) {
        return asset.parameters[LibConfigKeys.ADL_RESERVE_RATE].toUint32();
    }

    function adlMaxPnlRate(Asset storage asset) internal view returns (uint32) {
        return asset.parameters[LibConfigKeys.ADL_MAX_PNL_RATE].toUint32();
    }

    function adlTriggerRate(Asset storage asset) internal view returns (uint32) {
        return asset.parameters[LibConfigKeys.ADL_TRIGGER_RATE].toUint32();
    }

    function toWad(Asset storage asset, uint256 rawAmount) internal view returns (uint96) {
        return (rawAmount * (10 ** (18 - decimals(asset)))).toUint96();
    }

    function toRaw(Asset storage asset, uint96 wadAmount) internal view returns (uint256) {
        return uint256(wadAmount) / 10 ** (18 - decimals(asset));
    }

    // is a usdt, usdc, ...
    function isStable(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_IS_STABLE) != 0;
    }

    // can call addLiquidity and removeLiquidity with this token
    function canAddRemoveLiquidity(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_CAN_ADD_REMOVE_LIQUIDITY) != 0;
    }

    // allowed to be assetId
    function isTradable(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_IS_TRADABLE) != 0;
    }

    // can open position
    function isOpenable(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_IS_OPENABLE) != 0;
    }

    // allow shorting this asset
    function isShortable(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_IS_SHORTABLE) != 0;
    }

    // allowed to be assetId and collateralId
    function isEnabled(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_IS_ENABLED) != 0;
    }

    // assetPrice is always 1 unless volatility exceeds strictStableDeviation
    function isStrictStable(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_IS_STRICT_STABLE) != 0;
    }

    // ex: lotSize = 0.1, positionOrderAmount should be 0.1, 0.2, 0.3, ...
    function lotSize(Asset storage asset) internal view returns (uint96) {
        return asset.parameters[LibConfigKeys.LOT_SIZE].toUint96();
    }

    function transferOut(Asset storage asset, address recipient, uint256 rawAmount) internal {
        // commented: if tokenAddress(asset) == weth
        IERC20Upgradeable(tokenAddress(asset)).safeTransfer(recipient, rawAmount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

library LibConfigKeys {
    // POOL
    bytes32 constant MLP_TOKEN = keccak256("MLP_TOKEN");
    bytes32 constant ORDER_BOOK = keccak256("ORDER_BOOK");
    bytes32 constant FEE_DISTRIBUTOR = keccak256("FEE_DISTRIBUTOR");

    bytes32 constant FUNDING_INTERVAL = keccak256("FUNDING_INTERVAL"); // 1e0
    bytes32 constant BORROWING_RATE_APY = keccak256("BORROWING_RATE_APY"); // 1e5

    bytes32 constant LIQUIDITY_FEE_RATE = keccak256("LIQUIDITY_FEE_RATE"); // 1e5

    bytes32 constant STRICT_STABLE_DEVIATION = keccak256("STRICT_STABLE_DEVIATION"); // 1e5
    bytes32 constant BROKER_GAS_REBATE_USD = keccak256("BROKER_GAS_REBATE_USD");

    // POOL - ASSET
    bytes32 constant SYMBOL = keccak256("SYMBOL");
    bytes32 constant DECIMALS = keccak256("DECIMALS");
    bytes32 constant TOKEN_ADDRESS = keccak256("TOKEN_ADDRESS");
    bytes32 constant LOT_SIZE = keccak256("LOT_SIZE");

    bytes32 constant INITIAL_MARGIN_RATE = keccak256("INITIAL_MARGIN_RATE"); // 1e5
    bytes32 constant MAINTENANCE_MARGIN_RATE = keccak256("MAINTENANCE_MARGIN_RATE"); // 1e5
    bytes32 constant MIN_PROFIT_RATE = keccak256("MIN_PROFIT_RATE"); // 1e5
    bytes32 constant MIN_PROFIT_TIME = keccak256("MIN_PROFIT_TIME"); // 1e0
    bytes32 constant POSITION_FEE_RATE = keccak256("POSITION_FEE_RATE"); // 1e5
    bytes32 constant LIQUIDATION_FEE_RATE = keccak256("LIQUIDATION_FEE_RATE"); // 1e5

    bytes32 constant REFERENCE_ORACLE = keccak256("REFERENCE_ORACLE");
    bytes32 constant REFERENCE_DEVIATION = keccak256("REFERENCE_DEVIATION"); // 1e5
    bytes32 constant REFERENCE_ORACLE_TYPE = keccak256("REFERENCE_ORACLE_TYPE");

    bytes32 constant MAX_LONG_POSITION_SIZE = keccak256("MAX_LONG_POSITION_SIZE");
    bytes32 constant MAX_SHORT_POSITION_SIZE = keccak256("MAX_SHORT_POSITION_SIZE");
    bytes32 constant FUNDING_ALPHA = keccak256("FUNDING_ALPHA");
    bytes32 constant FUNDING_BETA_APY = keccak256("FUNDING_BETA_APY"); // 1e5

    bytes32 constant LIQUIDITY_CAP_USD = keccak256("LIQUIDITY_CAP_USD");

    // ADL
    bytes32 constant ADL_RESERVE_RATE = keccak256("ADL_RESERVE_RATE"); // 1e5
    bytes32 constant ADL_MAX_PNL_RATE = keccak256("ADL_MAX_PNL_RATE"); // 1e5
    bytes32 constant ADL_TRIGGER_RATE = keccak256("ADL_TRIGGER_RATE"); // 1e5

    // ORDERBOOK
    bytes32 constant OB_LIQUIDITY_LOCK_PERIOD = keccak256("OB_LIQUIDITY_LOCK_PERIOD"); // 1e0
    bytes32 constant OB_REFERRAL_MANAGER = keccak256("OB_REFERRAL_MANAGER");
    bytes32 constant OB_MARKET_ORDER_TIMEOUT = keccak256("OB_MARKET_ORDER_TIMEOUT"); // 1e0
    bytes32 constant OB_LIMIT_ORDER_TIMEOUT = keccak256("OB_LIMIT_ORDER_TIMEOUT"); // 1e0
    bytes32 constant OB_CALLBACK_GAS_LIMIT = keccak256("OB_CALLBACK_GAS_LIMIT"); // 1e0
    bytes32 constant OB_CANCEL_COOL_DOWN = keccak256("OB_CANCEL_COOL_DOWN"); // 1e0
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

library LibMath {
    function min(uint96 a, uint96 b) internal pure returns (uint96) {
        return a <= b ? a : b;
    }

    function min32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a <= b ? a : b;
    }

    function max32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a >= b ? a : b;
    }

    function wmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / 1e18;
    }

    function rmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / 1e5;
    }

    function wdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * 1e18) / b;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../Types.sol";
import "./LibConfigKeys.sol";
import "./LibTypeCast.sol";
import "./LibAsset.sol";
import "./LibMath.sol";

library LibPoolStorage {
    using LibAsset for Asset;
    using LibTypeCast for bytes32;
    using LibTypeCast for uint256;
    using LibMath for uint256;

    function isValidAssetId(PoolStorage storage pool, uint256 assetId) internal view returns (bool) {
        return assetId < pool.assetsCount && pool.assets[assetId].id == assetId;
    }

    function poolUsdWithoutPnl(PoolStorage storage pool, uint96[] memory markPrices) internal view returns (uint96) {
        uint256 assetCount = pool.assetsCount;
        require(markPrices.length == assetCount, "LEN"); // LENgth is different
        uint256 sumUsd = 0;
        for (uint256 i = 0; i < assetCount; i++) {
            uint96 markPrice = markPrices[i];
            require(markPrice > 0, "P=0"); // Price Is Zero
            sumUsd += (uint256(pool.assets[i].spotLiquidity) * uint256(markPrice));
        }
        return (sumUsd / 1e18).toUint96();
    }

    function poolUsd(PoolStorage storage pool, uint96[] memory markPrices) internal view returns (uint96) {
        uint96 aum = poolUsdWithoutPnl(pool, markPrices);
        uint256 assetCount = pool.assetsCount;
        for (uint256 i = 0; i < assetCount; i++) {
            Asset storage asset = pool.assets[i];
            uint96 markPrice = markPrices[i];
            require(markPrice > 0, "P=0"); // Price Is Zero
            // long
            if (asset.totalLongPosition != 0) {
                if (markPrice >= asset.averageLongPrice) {
                    // long profit
                    uint256 pnlUsd = uint256(markPrice - asset.averageLongPrice).wmul(asset.totalLongPosition);
                    uint256 cappedPnlUsd = (uint256(asset.totalLongPosition) *
                        uint256(asset.averageLongPrice) *
                        uint256(asset.adlMaxPnlRate())) / 1e23; // 18 + 18 + 5 - 23
                    if (pnlUsd > cappedPnlUsd) {
                        pnlUsd = cappedPnlUsd;
                    }
                    aum -= pnlUsd.toUint96();
                } else {
                    // long loss
                    uint256 pnlUsd = uint256(asset.averageLongPrice - markPrice).wmul(asset.totalLongPosition);
                    aum += pnlUsd.toUint96();
                }
            }
            // short
            if (asset.totalShortPosition != 0) {
                if (markPrice <= asset.averageShortPrice) {
                    // short profit
                    uint256 pnlUsd = uint256(asset.averageShortPrice - markPrice).wmul(asset.totalShortPosition);
                    uint256 cappedPnlUsd = (uint256(asset.totalShortPosition) *
                        uint256(asset.averageShortPrice) *
                        uint256(asset.adlMaxPnlRate())) / 1e23; // 18 + 18 + 5 - 23
                    if (pnlUsd > cappedPnlUsd) {
                        pnlUsd = cappedPnlUsd;
                    }
                    aum -= pnlUsd.toUint96();
                } else {
                    // short loss
                    uint256 pnlUsd = uint256(markPrice - asset.averageShortPrice).wmul(asset.totalShortPosition);
                    aum += pnlUsd.toUint96();
                }
            }
        } // foreach asset
        return aum;
    }

    function mlpTokenPriceByMarkPrices(
        PoolStorage storage pool,
        uint96[] memory markPrices
    ) internal view returns (uint96) {
        uint256 liquidityUsd = poolUsd(pool, markPrices);
        return mlpTokenPrice(pool, liquidityUsd);
    }

    function mlpTokenPrice(PoolStorage storage pool, uint256 liquidityUsd) internal view returns (uint96) {
        uint256 totalSupply = IERC20Upgradeable(mlpToken(pool)).totalSupply();
        if (totalSupply == 0) {
            return 1e18;
        }
        return ((liquidityUsd * 1e18) / totalSupply).toUint96();
    }

    function totalReservationUsd(PoolStorage storage pool) internal view returns (uint96 reservationUsd) {
        uint256 assetCount = pool.assetsCount;
        uint256 usd = 0;
        for (uint256 i = 0; i < assetCount; i++) {
            Asset storage asset = pool.assets[i];
            uint32 rate = asset.adlReserveRate();
            usd += ((uint256(asset.totalShortPosition) * uint256(asset.averageShortPrice) * uint256(rate)) / 1e23); // 18 + 18 + 5 - 23
            usd += ((uint256(asset.totalLongPosition) * uint256(asset.averageLongPrice) * uint256(rate)) / 1e23); // 18 + 18 + 5 - 23
        }
        return usd.toUint96();
    }

    function mlpToken(PoolStorage storage pool) internal view returns (address) {
        return pool.parameters[LibConfigKeys.MLP_TOKEN].toAddress();
    }

    function orderBook(PoolStorage storage pool) internal view returns (address) {
        return pool.parameters[LibConfigKeys.ORDER_BOOK].toAddress();
    }

    function feeDistributor(PoolStorage storage pool) internal view returns (address) {
        return pool.parameters[LibConfigKeys.FEE_DISTRIBUTOR].toAddress();
    }

    function fundingInterval(PoolStorage storage pool) internal view returns (uint32) {
        return pool.parameters[LibConfigKeys.FUNDING_INTERVAL].toUint32();
    }

    function borrowingRateApy(PoolStorage storage pool) internal view returns (uint32) {
        return pool.parameters[LibConfigKeys.BORROWING_RATE_APY].toUint32();
    }

    function liquidityFeeRate(PoolStorage storage pool) internal view returns (uint32) {
        return pool.parameters[LibConfigKeys.LIQUIDITY_FEE_RATE].toUint32();
    }

    function strictStableDeviation(PoolStorage storage pool) internal view returns (uint32) {
        return pool.parameters[LibConfigKeys.STRICT_STABLE_DEVIATION].toUint32();
    }

    function liquidityCapUsd(PoolStorage storage pool) internal view returns (uint96) {
        return pool.parameters[LibConfigKeys.LIQUIDITY_CAP_USD].toUint96();
    }

    // 1e18
    function brokerGasRebateUsd(PoolStorage storage pool) internal view returns (uint256) {
        return pool.parameters[LibConfigKeys.BROKER_GAS_REBATE_USD].toUint256();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "../Types.sol";
import "./LibMath.sol";
import "./LibAsset.sol";
import "./LibPoolStorage.sol";
import "./LibTypeCast.sol";

interface IChainlink {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

interface IChainlinkV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

interface IChainlinkV2V3 is IChainlink, IChainlinkV3 {}

enum SpreadType {
    Ask,
    Bid
}

library LibReferenceOracle {
    using LibMath for uint256;
    using LibMath for uint96;
    using LibAsset for Asset;
    using LibPoolStorage for PoolStorage;
    using LibTypeCast for uint256;

    // indicate that the asset price is too far away from reference oracle
    event AssetPriceOutOfRange(uint8 assetId, uint96 price, uint96 referencePrice, uint32 deviation);

    /**
     * @dev Check oracle parameters before set.
     */
    function checkParameters(
        ReferenceOracleType referenceOracleType,
        address referenceOracle,
        uint32 referenceDeviation
    ) internal view {
        require(referenceDeviation <= 1e5, "D>1"); // %deviation > 100%
        if (referenceOracleType == ReferenceOracleType.Chainlink) {
            IChainlinkV2V3 o = IChainlinkV2V3(referenceOracle);
            require(o.decimals() == 8, "!D8"); // we only support decimals = 8
            require(o.latestAnswer() > 0, "P=0"); // oracle Price <= 0
        }
    }

    /**
     * @dev Truncate price if the error is too large.
     */
    function checkPrice(PoolStorage storage pool, Asset storage asset, uint96 price) internal returns (uint96) {
        require(price != 0, "P=0"); // broker price = 0

        // truncate price if the error is too large
        if (ReferenceOracleType(asset.referenceOracleType()) == ReferenceOracleType.Chainlink) {
            uint96 ref = _readChainlink(asset.referenceOracle());
            price = _truncatePrice(asset, price, ref);
        }

        // strict stable dampener
        if (asset.isStrictStable()) {
            uint256 delta = price > 1e18 ? price - 1e18 : 1e18 - price;
            uint256 dampener = uint256(pool.strictStableDeviation()) * 1e13; // 1e5 => 1e18
            if (delta <= dampener) {
                price = 1e18;
            }
        }

        return price;
    }

    function _readChainlink(address referenceOracle) internal view returns (uint96) {
        int256 ref = IChainlinkV2V3(referenceOracle).latestAnswer();
        require(ref > 0, "P=0"); // oracle Price <= 0
        ref *= 1e10; // decimals 8 => 18
        return uint256(ref).toUint96();
    }

    function _truncatePrice(Asset storage asset, uint96 price, uint96 ref) private returns (uint96) {
        if (asset.referenceDeviation() == 0) {
            return ref;
        }
        uint256 deviation = uint256(ref).rmul(asset.referenceDeviation());
        uint96 bound = (uint256(ref) - deviation).toUint96();
        if (price < bound) {
            emit AssetPriceOutOfRange(uint8(asset.id), price, ref, uint32(asset.referenceDeviation()));
            price = bound;
        }
        bound = (uint256(ref) + deviation).toUint96();
        if (price > bound) {
            emit AssetPriceOutOfRange(uint8(asset.id), price, ref, uint32(asset.referenceDeviation()));
            price = bound;
        }
        return price;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "../Types.sol";
/**
 * SubAccountId
 *         96             88        80       72        0
 * +---------+--------------+---------+--------+--------+
 * | Account | collateralId | assetId | isLong | unused |
 * +---------+--------------+---------+--------+--------+
 */

struct SubAccountId {
    address account;
    uint8 collateralId;
    uint8 assetId;
    bool isLong;
}

library LibSubAccount {
    bytes32 constant SUB_ACCOUNT_ID_FORBIDDEN_BITS = bytes32(uint256(0xffffffffffffffffff));

    function owner(bytes32 subAccountId) internal pure returns (address account) {
        account = address(uint160(uint256(subAccountId) >> 96));
    }

    function collateralId(bytes32 subAccountId) internal pure returns (uint8) {
        return uint8(uint256(subAccountId) >> 88);
    }

    function assetId(bytes32 subAccountId) internal pure returns (uint8) {
        return uint8(uint256(subAccountId) >> 80);
    }

    function isLong(bytes32 subAccountId) internal pure returns (bool) {
        return uint8((uint256(subAccountId) >> 72)) > 0;
    }

    function decode(bytes32 subAccountId) internal pure returns (SubAccountId memory decoded) {
        require((subAccountId & SUB_ACCOUNT_ID_FORBIDDEN_BITS) == 0, "AID"); // bad subAccount ID
        decoded.account = address(uint160(uint256(subAccountId) >> 96));
        decoded.collateralId = uint8(uint256(subAccountId) >> 88);
        decoded.assetId = uint8(uint256(subAccountId) >> 80);
        decoded.isLong = uint8((uint256(subAccountId) >> 72)) > 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

library LibTypeCast {
    bytes32 private constant ADDRESS_GUARD_MASK = 0xffffffffffffffffffffffff0000000000000000000000000000000000000000;

    function isAddress(bytes32 v) internal pure returns (bool) {
        return v & ADDRESS_GUARD_MASK == 0;
    }

    function toAddress(bytes32 v) internal pure returns (address) {
        require(v & ADDRESS_GUARD_MASK == 0, "ADR"); // invalid ADdRess
        return address(uint160(uint256(v)));
    }

    function toBytes32(address v) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(v)));
    }

    function toUint32(bytes32 v) internal pure returns (uint32) {
        return toUint32(uint256(v));
    }

    function toUint56(bytes32 v) internal pure returns (uint56) {
        return toUint56(uint256(v));
    }

    function toUint96(bytes32 v) internal pure returns (uint96) {
        return toUint96(uint256(v));
    }

    function toUint256(bytes32 v) internal pure returns (uint256) {
        return uint256(v);
    }

    function toBytes32(uint256 v) internal pure returns (bytes32) {
        return bytes32(v);
    }

    function toBoolean(bytes32 v) internal pure returns (bool) {
        uint256 n = toUint256(v);
        require(n == 0 || n == 1, "O1");
        return n == 1;
    }

    function toBytes32(bool v) internal pure returns (bytes32) {
        return toBytes32(v ? 1 : 0);
    }

    function toUint32(uint256 n) internal pure returns (uint32) {
        require(n <= type(uint32).max, "O32");
        return uint32(n);
    }

    function toUint56(uint256 n) internal pure returns (uint56) {
        require(n <= type(uint56).max, "O56");
        return uint56(n);
    }

    function toUint96(uint256 n) internal pure returns (uint96) {
        require(n <= type(uint96).max, "O96");
        return uint96(n);
    }

    function toUint128(uint256 n) internal pure returns (uint128) {
        require(n <= type(uint128).max, "O12");
        return uint128(n);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MlpToken is Initializable, ERC20Upgradeable {
    address public liquidityPool;

    function initialize(string memory name_, string memory symbol_, address liquidityPool_) external initializer {
        __ERC20_init(name_, symbol_);
        liquidityPool = liquidityPool_;
    }

    function mint(address to, uint256 amount) public {
        require(_msgSender() == liquidityPool, "MUXLP: role");
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) public {
        require(_msgSender() == liquidityPool, "MUXLP: role");
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: CC0-1.0
// from https://github.com/OpenZeppelin/EIPs/blob/master/assets/eip-2535/reference/Diamond.sol

pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]>, Twitter/Github: @mudgen
* EIP-2535 Diamonds
/******************************************************************************/

// NOTE:
// To see the various things in this file in their proper directory structure
// please download the zip archive version of this reference implementation.
// The zip archive also includes a deployment script and tests.

interface IDiamond {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

interface IDiamondCut is IDiamond {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}

///////////////////////////////////////////////
// LibDiamond
// LibDiamond defines the diamond storage that is used by this reference
// implementation.
// LibDiamond contains internal functions and no external functions.
// LibDiamond internal functions are used by DiamondCutFacet,
// DiamondLoupeFacet and the diamond proxy contract (the Diamond contract).

error NoSelectorsGivenToAdd();
error NotContractOwner(address _user, address _contractOwner);
error NoSelectorsProvidedForFacetForCut(address _facetAddress);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error NoBytecodeAtAddress(address _contractAddress, string _message);
error IncorrectFacetCutAction(uint8 _action);
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
error CannotReplaceImmutableFunction(bytes4 _selector);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(bytes4 _selector);
error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        if (msg.sender != diamondStorage().contractOwner) {
            revert NotContractOwner(msg.sender, diamondStorage().contractOwner);
        }
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;
            address facetAddress = _diamondCut[facetIndex].facetAddress;
            if (functionSelectors.length == 0) {
                revert NoSelectorsProvidedForFacetForCut(facetAddress);
            }
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamond.FacetCutAction.Add) {
                addFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Replace) {
                replaceFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Remove) {
                removeFunctions(facetAddress, functionSelectors);
            } else {
                revert IncorrectFacetCutAction(uint8(action));
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if (oldFacetAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(
                _facetAddress,
                selectorCount
            );
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        if (_facetAddress == address(0)) {
            revert CannotReplaceFunctionsFromFacetWithZeroAddress(_functionSelectors);
        }
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond in this case
            if (oldFacetAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if (oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(selector);
            }
            if (oldFacetAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if (_facetAddress != address(0)) {
            revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds
                .facetAddressAndSelectorPosition[selector];
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }

            // can't remove immutable functions -- functions defined directly in the diamond
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(this)) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition
                    .selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert NoBytecodeAtAddress(_contract, _errorMessage);
        }
    }
}

///////////////////////////////////////////////
// These facets are added to the diamond.
///////////////////////////////////////////////

contract DiamondCutFacet is IDiamondCut {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}

// The functions in DiamondLoupeFacet MUST be added to a diamond.
// The EIP-2535 Diamond standard requires these functions.

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.
    //
    // struct Facet {
    //     address facetAddress;
    //     bytes4[] functionSelectors;
    // }
    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        // create an array set to the maximum size possible
        facets_ = new Facet[](selectorCount);
        // create an array for counting the number of selectors for each facet
        uint16[] memory numFacetSelectors = new uint16[](selectorCount);
        // total number of facets
        uint256 numFacets;
        // loop through function selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            bool continueLoop = false;
            // find the functionSelectors array for selector and add selector to it
            for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                if (facets_[facetIndex].facetAddress == facetAddress_) {
                    facets_[facetIndex].functionSelectors[numFacetSelectors[facetIndex]] = selector;
                    numFacetSelectors[facetIndex]++;
                    continueLoop = true;
                    break;
                }
            }
            // if functionSelectors array exists for selector then continue loop
            if (continueLoop) {
                continueLoop = false;
                continue;
            }
            // create a new functionSelectors array for selector
            facets_[numFacets].facetAddress = facetAddress_;
            facets_[numFacets].functionSelectors = new bytes4[](selectorCount);
            facets_[numFacets].functionSelectors[0] = selector;
            numFacetSelectors[numFacets] = 1;
            numFacets++;
        }
        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }
        // setting the number of facets
        assembly {
            mstore(facets_, numFacets)
        }
    }

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return _facetFunctionSelectors The selectors associated with a facet address.
    function facetFunctionSelectors(
        address _facet
    ) external view override returns (bytes4[] memory _facetFunctionSelectors) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        uint256 numSelectors;
        _facetFunctionSelectors = new bytes4[](selectorCount);
        // loop through function selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if (_facet == facetAddress_) {
                _facetFunctionSelectors[numSelectors] = selector;
                numSelectors++;
            }
        }
        // Set the number of selectors in the array
        assembly {
            mstore(_facetFunctionSelectors, numSelectors)
        }
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        // create an array set to the maximum size possible
        facetAddresses_ = new address[](selectorCount);
        uint256 numFacets;
        // loop through function selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            bool continueLoop = false;
            // see if we have collected the address already and break out of loop if we have
            for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                if (facetAddress_ == facetAddresses_[facetIndex]) {
                    continueLoop = true;
                    break;
                }
            }
            // continue loop if we already have the address
            if (continueLoop) {
                continueLoop = false;
                continue;
            }
            // include address
            facetAddresses_[numFacets] = facetAddress_;
            numFacets++;
        }
        // Set the number of facet addresses in the array
        assembly {
            mstore(facetAddresses_, numFacets)
        }
    }

    /// @notice Gets the facet address that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds.facetAddressAndSelectorPosition[_functionSelector].facetAddress;
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}

///////////////////////////////////////////////

///////////////////////////////////////////////
// DiamondInit
// This contract and function are used to initialize state variables and/or do other actions
// when the `diamondCut` function is called.
// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.
// DiamondInit can be used during deployment or for upgrades.

// Adding parameters to the `init` or other functions you add here can make a single deployed
// DiamondInit contract reusable accross upgrades, and can be used for multiple diamonds.

contract DiamondInit {
    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init() external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        // add your own state variables
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info in the EIP2535 Diamonds standard.
    }
}

///////////////////////////////////////////////
// DiamondMultiInit
// This version of DiamondInit can be used to execute multiple initialization functions.
// It is expected that this contract is customized if you want to deploy or upgrade your diamond with it.

error AddressAndCalldataLengthDoNotMatch(uint256 _addressesLength, uint256 _calldataLength);

contract DiamondMultiInit {
    // This function is provided in the third parameter of the `diamondCut` function.
    // The `diamondCut` function executes this function to execute multiple initializer functions for a single upgrade.

    function multiInit(address[] calldata _addresses, bytes[] calldata _calldata) external {
        if (_addresses.length != _calldata.length) {
            revert AddressAndCalldataLengthDoNotMatch(_addresses.length, _calldata.length);
        }
        for (uint i; i < _addresses.length; i++) {
            LibDiamond.initializeDiamondCut(_addresses[i], _calldata[i]);
        }
    }
}

///////////////////////////////////////////////
// Diamond
// The diamond proxy contract.

// When no function exists for function called
error FunctionNotFound(bytes4 _functionSelector);

// This is used in diamond constructor
// more arguments are added to this struct
// this avoids stack too deep errors
struct DiamondArgs {
    address owner;
    address init;
    bytes initCalldata;
}

contract Diamond {
    // Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
    // The loupe functions are required by the EIP2535 Diamonds standard

    constructor(IDiamondCut.FacetCut[] memory _diamondCut, DiamondArgs memory _args) payable {
        LibDiamond.setContractOwner(_args.owner);
        LibDiamond.diamondCut(_diamondCut, _args.init, _args.initCalldata);

        // Code can be added here to perform actions and set state variables.
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.facetAddressAndSelectorPosition[msg.sig].facetAddress;
        if (facet == address(0)) {
            revert FunctionNotFound(msg.sig);
        }
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

// funding period
uint32 constant APY_PERIOD = 86400 * 365;

// flags
uint56 constant ASSET_IS_STABLE = 0x00000000000001; // is a usdt, usdc, ...
uint56 constant ASSET_CAN_ADD_REMOVE_LIQUIDITY = 0x00000000000002; // can call addLiquidity and removeLiquidity with this token
uint56 constant ASSET_IS_TRADABLE = 0x00000000000100; // allowed to be assetId
uint56 constant ASSET_IS_OPENABLE = 0x00000000010000; // can open position
uint56 constant ASSET_IS_SHORTABLE = 0x00000001000000; // allow shorting this asset
uint56 constant ASSET_IS_ENABLED = 0x00010000000000; // allowed to be assetId and collateralId
uint56 constant ASSET_IS_STRICT_STABLE = 0x01000000000000; // assetPrice is always 1 unless volatility exceeds strictStableDeviation

enum ReferenceOracleType {
    None,
    Chainlink
}

struct PoolStorage {
    // configs
    mapping(uint256 => Asset) assets;
    mapping(bytes32 => SubAccount) accounts;
    mapping(address => bool) maintainers;
    mapping(bytes32 => bytes32) parameters;
    // status
    mapping(address => EnumerableSetUpgradeable.Bytes32Set) userSubAccountIds;
    EnumerableSetUpgradeable.Bytes32Set isMaintenanceParameters;
    uint8 assetsCount;
    uint32 sequence;
    uint32 lastFundingTime;
    uint32 brokerTransactions;
    EnumerableSetUpgradeable.Bytes32Set subAccountIds;
    bytes32[20] __gaps;
}

struct Asset {
    // configs
    uint8 id;
    mapping(bytes32 => bytes32) parameters;
    EnumerableSetUpgradeable.Bytes32Set isMaintenanceParameters;
    // status
    uint56 flags;
    uint96 spotLiquidity;
    uint96 __deleted0;
    uint96 totalLongPosition;
    uint96 averageLongPrice;
    uint96 totalShortPosition;
    uint96 averageShortPrice;
    uint128 longCumulativeFunding; // Σ_t fundingRate_t + borrowingRate_t. 1e18. payment = (cumulative - entry) * positionSize * entryPrice
    uint128 shortCumulativeFunding; // Σ_t fundingRate_t + borrowingRate_t. 1e18. payment = (cumulative - entry) * positionSize * entryPrice
}

struct SubAccount {
    uint96 collateral;
    uint96 size;
    uint32 lastIncreasedTime;
    uint96 entryPrice;
    uint128 entryFunding; // entry longCumulativeFunding for long position. entry shortCumulativeFunding for short position
}