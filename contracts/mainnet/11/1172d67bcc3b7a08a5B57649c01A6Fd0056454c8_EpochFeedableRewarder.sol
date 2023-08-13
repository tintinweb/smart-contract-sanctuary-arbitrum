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

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.

pragma solidity 0.8.18;

import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { SafeERC20Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ERC20Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import { TLCStaking } from "./TLCStaking.sol";
import { IRewarder } from "./interfaces/IRewarder.sol";
import { IEpochRewarder } from "./interfaces/IEpochRewarder.sol";

contract EpochFeedableRewarder is OwnableUpgradeable {
  using SafeERC20Upgradeable for ERC20Upgradeable;

  string public name;
  address public rewardToken;
  address public staking;
  address public feeder;
  uint256 public epochLength;

  mapping(uint256 => uint256) public accRewardPerShareByEpochTimestamp;
  mapping(uint256 => uint256) rewardBalanceMapByEpochTimestamp;
  mapping(uint256 => mapping(address => bool)) isClaimed;
  uint256 private constant ACC_REWARD_PRECISION = 1e30;

  // Events
  event LogOnDeposit(uint256 epochTimestamp, address indexed user, uint256 shareAmount);
  event LogOnWithdraw(uint256 epochTimestamp, address indexed user, uint256 shareAmount);
  event LogHarvest(uint256 epochTimestamp, address indexed user, uint256 pendingRewardAmount);
  event LogFeed(uint256 epochTimestamp, uint256 feedAmount, uint256 totalEpochReward);
  event LogSetFeeder(address oldFeeder, address newFeeder);

  // Error
  error EpochFeedableRewarderError_FeedAmountDecayed();
  error EpochFeedableRewarderError_NotStakingContract();
  error EpochFeedableRewarderError_NotFeeder();
  error EpochFeedableRewarderError_BadDuration();
  error EpochFeedableRewarderError_WithdrawalNotAllowed();
  error EpochFeedableRewarderError_EpochNotEnded();
  error EpochFeedableRewarderError_AlreadyFeed();

  modifier onlyStakingContract() {
    if (msg.sender != staking) revert EpochFeedableRewarderError_NotStakingContract();
    _;
  }

  modifier onlyFeeder() {
    if (msg.sender != feeder) revert EpochFeedableRewarderError_NotFeeder();
    _;
  }

  function initialize(
    string memory name_,
    address rewardToken_,
    address staking_
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    name = name_;
    rewardToken = rewardToken_;
    staking = staking_;

    // At initialization, assume the feeder to be the contract owner
    feeder = owner();

    epochLength = 1 weeks;

    // Sanity check
    ERC20Upgradeable(rewardToken_).totalSupply();
    TLCStaking(staking_).isRewarder(address(this));
  }

  function onDeposit(
    uint256 epochTimestamp,
    address user,
    uint256 shareAmount
  ) external onlyStakingContract {
    // Floor down the timestamp, in case it is incorrectly formatted
    epochTimestamp = (epochTimestamp / epochLength) * epochLength;

    _updateRewardCalculationParams(epochTimestamp);

    emit LogOnDeposit(epochTimestamp, user, shareAmount);
  }

  function onWithdraw(
    uint256 epochTimestamp,
    address user,
    uint256 shareAmount
  ) external onlyStakingContract {
    // Floor down the timestamp, in case it is incorrectly formatted
    epochTimestamp = (epochTimestamp / epochLength) * epochLength;

    // Withdrawal will not be allowed is the epoch has ended.
    if (getCurrentEpochTimestamp() + epochLength > epochTimestamp)
      revert EpochFeedableRewarderError_WithdrawalNotAllowed();
    _updateRewardCalculationParams(epochTimestamp);

    emit LogOnWithdraw(epochTimestamp, user, shareAmount);
  }

  function onHarvest(
    uint256 epochTimestamp,
    address user,
    address receiver
  ) external onlyStakingContract {
    // Floor down the timestamp, in case it is incorrectly formatted
    epochTimestamp = (epochTimestamp / epochLength) * epochLength;

    if (!isClaimed[epochTimestamp][user]) {
      _updateRewardCalculationParams(epochTimestamp);

      uint256 accumulatedRewards = (_userShare(epochTimestamp, user) *
        accRewardPerShareByEpochTimestamp[epochTimestamp]) / ACC_REWARD_PRECISION;

      if (accumulatedRewards != 0) {
        isClaimed[epochTimestamp][user] = true;
        _harvestToken(receiver, accumulatedRewards);
      }

      emit LogHarvest(epochTimestamp, user, accumulatedRewards);
    }
  }

  function pendingReward(
    uint256 startEpochTimestamp,
    uint256 noOfEpochs,
    address userAddress
  ) external view returns (uint256) {
    uint256 userShare;
    uint256 accumRewardPerShare;
    uint256 pendingRewardAmount;
    uint256 totalRewardAmount;
    uint256 epochTimestamp = (startEpochTimestamp / epochLength) * epochLength;
    for (uint256 i = 0; i < noOfEpochs; ) {
      // If the epoch is in the future, then break the loop
      if (epochTimestamp + epochLength > block.timestamp) break;

      // Get user balance of the epoch
      userShare = TLCStaking(staking).calculateShare(epochTimestamp, userAddress);
      // Get accum reward per share of the epoch
      accumRewardPerShare = accRewardPerShareByEpochTimestamp[epochTimestamp];

      // If userShare is zero, then the user will not be eligible for reward in that epoch.
      // If accumRewardPerShare is zero, then the reward might not be distributed for that epoch yet. We will skip without burning user share.
      if (!isClaimed[epochTimestamp][userAddress] && userShare > 0 && accumRewardPerShare > 0) {
        // Calculate pending reward
        pendingRewardAmount = (userShare * accumRewardPerShare) / ACC_REWARD_PRECISION;
        totalRewardAmount += pendingRewardAmount;
      }

      // Increment epoch timestamp
      epochTimestamp += epochLength;

      unchecked {
        ++i;
      }
    }
    return totalRewardAmount;
  }

  function feed(uint256 epochTimestamp, uint256 feedAmount) external onlyFeeder {
    _feed(epochTimestamp, feedAmount);
  }

  function setFeeder(address feeder_) external onlyOwner {
    emit LogSetFeeder(feeder, feeder_);
    feeder = feeder_;
  }

  function _feed(uint256 epochTimestamp, uint256 feedAmount) internal {
    // Floor down the timestamp, in case it is incorrectly formatted
    epochTimestamp = (epochTimestamp / epochLength) * epochLength;

    if (epochTimestamp + epochLength > block.timestamp)
      revert EpochFeedableRewarderError_EpochNotEnded();
    if (rewardBalanceMapByEpochTimestamp[epochTimestamp] > 0)
      revert EpochFeedableRewarderError_AlreadyFeed();

    {
      // Transfer token, with decay check
      uint256 balanceBefore = ERC20Upgradeable(rewardToken).balanceOf(address(this));
      ERC20Upgradeable(rewardToken).safeTransferFrom(msg.sender, address(this), feedAmount);

      if (ERC20Upgradeable(rewardToken).balanceOf(address(this)) - balanceBefore != feedAmount)
        revert EpochFeedableRewarderError_FeedAmountDecayed();
    }

    rewardBalanceMapByEpochTimestamp[epochTimestamp] += feedAmount;

    _updateRewardCalculationParams(epochTimestamp);

    emit LogFeed(epochTimestamp, feedAmount, rewardBalanceMapByEpochTimestamp[epochTimestamp]);
  }

  function _updateRewardCalculationParams(uint256 epochTimestamp) internal {
    // Floor down the timestamp, in case it is incorrectly formatted
    epochTimestamp = (epochTimestamp / epochLength) * epochLength;

    uint256 totalShare = _totalShare(epochTimestamp);
    if (totalShare > 0) {
      accRewardPerShareByEpochTimestamp[epochTimestamp] =
        (rewardBalanceMapByEpochTimestamp[epochTimestamp] * ACC_REWARD_PRECISION) /
        totalShare;
    }
  }

  function _totalShare(uint256 epochTimestamp) private view returns (uint256) {
    // Floor down the timestamp, in case it is incorrectly formatted
    epochTimestamp = (epochTimestamp / epochLength) * epochLength;

    return TLCStaking(staking).calculateTotalShare(epochTimestamp);
  }

  function _userShare(uint256 epochTimestamp, address user) private view returns (uint256) {
    // Floor down the timestamp, in case it is incorrectly formatted
    epochTimestamp = (epochTimestamp / epochLength) * epochLength;

    return TLCStaking(staking).calculateShare(epochTimestamp, user);
  }

  function _harvestToken(address receiver, uint256 pendingRewardAmount) internal virtual {
    ERC20Upgradeable(rewardToken).safeTransfer(receiver, pendingRewardAmount);
  }

  function getCurrentEpochTimestamp() public view returns (uint256 epochTimestamp) {
    return (block.timestamp / epochLength) * epochLength;
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

interface IEpochRewarder {
  function name() external view returns (string memory);

  function onDeposit(uint256 epochTimestamp, address user, uint256 shareAmount) external;

  function onWithdraw(uint256 epochTimestamp, address user, uint256 shareAmount) external;

  function onHarvest(uint256 epochTimestamp, address user, address receiver) external;

  function pendingReward(
    uint256 startEpochTimestamp,
    uint256 noOfEpochs,
    address userAddress
  ) external view returns (uint256);

  function feed(uint256 epochTimestamp, uint256 feedAmount) external;

  function setFeeder(address feeder_) external;

  function getCurrentEpochTimestamp() external view returns (uint256 epochTimestamp);
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.

pragma solidity 0.8.18;

interface IRewarder {
  function name() external view returns (string memory);

  function rewardToken() external view returns (address);

  function rewardRate() external view returns (uint256);

  function onDeposit(address user, uint256 shareAmount) external;

  function onWithdraw(address user, uint256 shareAmount) external;

  function onHarvest(address user, address receiver) external;

  function pendingReward(address user) external view returns (uint256);

  function feed(uint256 feedAmount, uint256 duration) external;

  function feedWithExpiredAt(uint256 feedAmount, uint256 expiredAt) external;

  function accRewardPerShare() external view returns (uint128);

  function userRewardDebts(address user) external view returns (int256);

  function lastRewardTime() external view returns (uint64);

  function setFeeder(address feeder_) external;
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.

pragma solidity 0.8.18;

interface ITLCStaking {
  function deposit(address to, uint256 amount) external;

  function withdraw(address to, uint256 amount) external;

  function getUserTokenAmount(
    uint256 epochTimestamp,
    address sender
  ) external view returns (uint256);

  function harvest(
    uint256 startEpochTimestamp,
    uint256 noOfEpochs,
    address[] memory _rewarders
  ) external;

  function harvestToCompounder(
    address user,
    uint256 startEpochTimestamp,
    uint256 noOfEpochs,
    address[] memory _rewarders
  ) external;

  function calculateTotalShare(uint256 epochTimestamp) external view returns (uint256);

  function calculateShare(uint256 epochTimestamp, address user) external view returns (uint256);

  function isRewarder(address rewarder) external view returns (bool);

  function addRewarder(address newRewarder) external;

  function setWhitelistedCaller(address _whitelistedCaller) external;

  function removeRewarder(uint256 _removeRewarderIndex) external;
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.

pragma solidity 0.8.18;

import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { IERC20Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import { ERC20Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { TraderLoyaltyCredit } from "src/tokens/TraderLoyaltyCredit.sol";

import { EpochFeedableRewarder } from "./EpochFeedableRewarder.sol";

import { ITLCStaking } from "./interfaces/ITLCStaking.sol";

contract TLCStaking is OwnableUpgradeable, ITLCStaking {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  error TLCStaking_UnknownStakingToken();
  error TLCStaking_InsufficientTokenAmount();
  error TLCStaking_NotRewarder();
  error TLCStaking_NotCompounder();
  error TLCStaking_BadDecimals();
  error TLCStaking_DuplicateStakingToken();
  error TLCStaking_Forbidden();

  mapping(uint256 => mapping(address => uint256)) public userTokenAmount;
  mapping(uint256 => uint256) public totalTokenAmount;
  mapping(address => bool) public isRewarder;
  address public stakingToken;
  address[] public rewarders;
  address public compounder;
  uint256 public epochLength;
  address public whitelistedCaller;

  event LogDeposit(
    uint256 indexed epochTimestamp,
    address indexed caller,
    address indexed user,
    uint256 amount
  );
  event LogWithdraw(uint256 indexed epochTimestamp, address indexed caller, uint256 amount);
  event LogAddRewarder(address newRewarder);
  event LogSetCompounder(address oldCompounder, address newCompounder);
  event LogSetWhitelistedCaller(address oldAddress, address newAddress);

  function initialize(address _stakingToken) external initializer {
    OwnableUpgradeable.__Ownable_init();

    stakingToken = _stakingToken;
    epochLength = 1 weeks;

    // Sanity Checks
    IERC20Upgradeable(stakingToken).totalSupply();
  }

  /**
   * Modifiers
   */
  modifier onlyWhitelistedCaller() {
    if (msg.sender != whitelistedCaller) revert TLCStaking_Forbidden();
    _;
  }

  function addRewarder(address newRewarder) external onlyOwner {
    _updatePool(newRewarder);

    emit LogAddRewarder(newRewarder);
  }

  function removeRewarder(uint256 removeRewarderIndex) external onlyOwner {
    address removedRewarder = rewarders[removeRewarderIndex];
    rewarders[removeRewarderIndex] = rewarders[rewarders.length - 1];
    rewarders[rewarders.length - 1] = removedRewarder;
    rewarders.pop();
    isRewarder[removedRewarder] = false;
  }

  function _updatePool(address newRewarder) internal {
    if (!isDuplicatedRewarder(newRewarder)) rewarders.push(newRewarder);

    if (!isRewarder[newRewarder]) {
      isRewarder[newRewarder] = true;
    }
  }

  function isDuplicatedRewarder(address rewarder) internal view returns (bool) {
    uint256 length = rewarders.length;
    for (uint256 i = 0; i < length; ) {
      if (rewarders[i] == rewarder) {
        return true;
      }
      unchecked {
        ++i;
      }
    }
    return false;
  }

  function setCompounder(address compounder_) external onlyOwner {
    emit LogSetCompounder(compounder, compounder_);
    compounder = compounder_;
  }

  function deposit(address to, uint256 amount) external onlyWhitelistedCaller {
    uint256 epochTimestamp = getCurrentEpochTimestamp();
    userTokenAmount[epochTimestamp][to] += amount;
    totalTokenAmount[epochTimestamp] += amount;

    uint256 length = rewarders.length;
    for (uint256 i = 0; i < length; ) {
      address rewarder = rewarders[i];

      EpochFeedableRewarder(rewarder).onDeposit(getCurrentEpochTimestamp(), to, amount);

      unchecked {
        ++i;
      }
    }

    IERC20Upgradeable(stakingToken).safeTransferFrom(msg.sender, address(this), amount);

    emit LogDeposit(epochTimestamp, msg.sender, to, amount);
  }

  function getUserTokenAmount(
    uint256 epochTimestamp,
    address sender
  ) external view returns (uint256) {
    // Floor down the timestamp, in case it is incorrectly formatted
    epochTimestamp = (epochTimestamp / epochLength) * epochLength;

    return userTokenAmount[epochTimestamp][sender];
  }

  function withdraw(address to, uint256 amount) external onlyWhitelistedCaller {
    _withdraw(to, amount);
    emit LogWithdraw(getCurrentEpochTimestamp(), msg.sender, amount);
  }

  function _withdraw(address to, uint256 amount) internal {
    uint256 epochTimestamp = getCurrentEpochTimestamp();
    if (userTokenAmount[getCurrentEpochTimestamp()][to] < amount)
      revert TLCStaking_InsufficientTokenAmount();

    userTokenAmount[epochTimestamp][to] -= amount;
    totalTokenAmount[epochTimestamp] -= amount;

    uint256 length = rewarders.length;
    for (uint256 i = 0; i < length; ) {
      address rewarder = rewarders[i];

      EpochFeedableRewarder(rewarder).onWithdraw(getCurrentEpochTimestamp(), to, amount);

      unchecked {
        ++i;
      }
    }

    IERC20Upgradeable(stakingToken).safeTransfer(to, amount);

    emit LogWithdraw(epochTimestamp, to, amount);
  }

  function harvest(
    uint256 startEpochTimestamp,
    uint256 noOfEpochs,
    address[] memory _rewarders
  ) external {
    uint256 epochTimestamp = (startEpochTimestamp / epochLength) * epochLength;
    for (uint256 i = 0; i < noOfEpochs; ) {
      // If the epoch is in the future, then break the loop
      if (epochTimestamp + epochLength > block.timestamp) break;

      _harvestFor(epochTimestamp, msg.sender, msg.sender, _rewarders);

      // Increment epoch timestamp
      epochTimestamp += epochLength;

      unchecked {
        ++i;
      }
    }
  }

  function harvestToCompounder(
    address user,
    uint256 startEpochTimestamp,
    uint256 noOfEpochs,
    address[] memory _rewarders
  ) external {
    if (compounder != msg.sender) revert TLCStaking_NotCompounder();
    uint256 epochTimestamp = (startEpochTimestamp / epochLength) * epochLength;
    for (uint256 i = 0; i < noOfEpochs; ) {
      // If the epoch is in the future, then break the loop
      if (epochTimestamp + epochLength > block.timestamp) break;

      _harvestFor(epochTimestamp, user, compounder, _rewarders);

      // Increment epoch timestamp
      epochTimestamp += epochLength;

      unchecked {
        ++i;
      }
    }
  }

  function _harvestFor(
    uint256 epochTimestamp,
    address user,
    address receiver,
    address[] memory _rewarders
  ) internal {
    // Floor down the timestamp, in case it is incorrectly formatted
    epochTimestamp = (epochTimestamp / epochLength) * epochLength;

    uint256 length = _rewarders.length;
    for (uint256 i = 0; i < length; ) {
      if (!isRewarder[_rewarders[i]]) {
        revert TLCStaking_NotRewarder();
      }

      EpochFeedableRewarder(_rewarders[i]).onHarvest(epochTimestamp, user, receiver);

      unchecked {
        ++i;
      }
    }
  }

  function calculateShare(uint256 epochTimestamp, address user) external view returns (uint256) {
    return userTokenAmount[epochTimestamp][user];
  }

  function calculateTotalShare(uint256 epochTimestamp) external view returns (uint256) {
    return totalTokenAmount[epochTimestamp];
  }

  function getCurrentEpochTimestamp() public view returns (uint256 epochTimestamp) {
    return (block.timestamp / epochLength) * epochLength;
  }

  function getRewarders() external view returns (address[] memory) {
    return rewarders;
  }

  /// @dev Set the address of an account authorized to modify balances in CrossMarginTrading.sol contract
  /// Emits a LogSetWhitelistedCaller event.
  /// @param _whitelistedCaller The new address allowed to perform whitelisted calls.
  function setWhitelistedCaller(address _whitelistedCaller) external onlyOwner {
    emit LogSetWhitelistedCaller(whitelistedCaller, _whitelistedCaller);
    whitelistedCaller = _whitelistedCaller;
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

interface ITraderLoyaltyCredit {
  error TLC_NotMinter();
  error TLC_AllowanceBelowZero();
  error TLC_TransferFromZeroAddress();
  error TLC_TransferToZeroAddress();
  error TLC_TransferAmountExceedsBalance();
  error TLC_MintToZeroAddress();
  error TLC_BurnFromZeroAddress();
  error TLC_BurnAmountExceedsBalance();
  error TLC_ApproveFromZeroAddress();
  error TLC_ApproveToZeroAddress();
  error TLC_InsufficientAllowance();

  function mint(address account, uint256 amount) external;

  function getCurrentEpochTimestamp() external view returns (uint256 epochTimestamp);

  function setMinter(address _minter, bool _mintable) external;

  function balanceOf(uint256 epochTimestamp, address account) external view returns (uint256);

  function totalSupplyByEpoch(uint256 epochTimestamp) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.

pragma solidity 0.8.18;

import { IERC20Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import { ITraderLoyaltyCredit } from "src/tokens/interfaces/ITraderLoyaltyCredit.sol";
import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { SafeERC20Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract TraderLoyaltyCredit is OwnableUpgradeable, ITraderLoyaltyCredit, IERC20Upgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event SetMinter(address indexed minter, bool mintable);

  mapping(uint256 => mapping(address => uint256)) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;
  mapping(uint256 => uint256) public totalSupplyByEpoch;

  string private constant _name = "Trader Loyalty Credit";
  string private constant _symbol = "TLC";
  uint256 public constant epochLength = 1 weeks;

  mapping(address => bool) public minter;

  modifier onlyMinter() {
    if (!minter[msg.sender]) revert TLC_NotMinter();
    _;
  }

  function initialize() external initializer {
    OwnableUpgradeable.__Ownable_init();
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() external pure returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() external pure returns (string memory) {
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
  function decimals() external pure returns (uint8) {
    return 18;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) external view returns (uint256) {
    return _balances[getCurrentEpochTimestamp()][account];
  }

  function balanceOf(uint256 epochTimestamp, address account) external view returns (uint256) {
    return _balances[epochTimestamp][account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address to, uint256 amount) public returns (bool) {
    address user = msg.sender;
    _transfer(getCurrentEpochTimestamp(), user, to, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address user, address spender) public view returns (uint256) {
    return _allowances[user][spender];
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
  function approve(address spender, uint256 amount) public returns (bool) {
    address user = msg.sender;
    _approve(user, spender, amount);
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
  function transferFrom(address from, address to, uint256 amount) public returns (bool) {
    address spender = msg.sender;
    _spendAllowance(from, spender, amount);
    _transfer(getCurrentEpochTimestamp(), from, to, amount);
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
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    address user = msg.sender;
    _approve(user, spender, allowance(user, spender) + addedValue);
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
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    address user = msg.sender;
    uint256 currentAllowance = allowance(user, spender);
    if (currentAllowance < subtractedValue) revert TLC_AllowanceBelowZero();
    unchecked {
      _approve(user, spender, currentAllowance - subtractedValue);
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
  function _transfer(uint256 epochTimestamp, address from, address to, uint256 amount) internal {
    if (from == address(0)) revert TLC_TransferFromZeroAddress();
    if (to == address(0)) revert TLC_TransferToZeroAddress();

    _beforeTokenTransfer(from, to, amount);

    uint256 fromBalance = _balances[epochTimestamp][from];
    if (fromBalance < amount) revert TLC_TransferAmountExceedsBalance();
    unchecked {
      _balances[epochTimestamp][from] = fromBalance - amount;
      // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
      // decrementing then incrementing.
      _balances[epochTimestamp][to] += amount;
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
  function mint(address account, uint256 amount) external onlyMinter {
    if (account == address(0)) revert TLC_MintToZeroAddress();

    _beforeTokenTransfer(address(0), account, amount);

    uint256 thisEpochTimestamp = getCurrentEpochTimestamp();

    _totalSupply += amount;
    totalSupplyByEpoch[thisEpochTimestamp] += amount;

    unchecked {
      // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
      _balances[getCurrentEpochTimestamp()][account] += amount;
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
  function _burn(uint256 epochTimestamp, address account, uint256 amount) internal virtual {
    if (account == address(0)) revert TLC_BurnFromZeroAddress();

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[epochTimestamp][account];
    if (accountBalance < amount) revert TLC_BurnAmountExceedsBalance();
    unchecked {
      _balances[epochTimestamp][account] = accountBalance - amount;
      // Overflow not possible: amount <= accountBalance <= totalSupply.
      _totalSupply -= amount;
      totalSupplyByEpoch[epochTimestamp] -= amount;
    }

    emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `user` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `user` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address user, address spender, uint256 amount) internal {
    if (user == address(0)) revert TLC_ApproveFromZeroAddress();
    if (spender == address(0)) revert TLC_ApproveToZeroAddress();

    _allowances[user][spender] = amount;
    emit Approval(user, spender, amount);
  }

  /**
   * @dev Updates `user` s allowance for `spender` based on spent `amount`.
   *
   * Does not update the allowance amount in case of infinite allowance.
   * Revert if not enough allowance is available.
   *
   * Might emit an {Approval} event.
   */
  function _spendAllowance(address user, address spender, uint256 amount) internal {
    uint256 currentAllowance = allowance(user, spender);
    if (currentAllowance != type(uint256).max) {
      if (currentAllowance < amount) revert TLC_InsufficientAllowance();
      unchecked {
        _approve(user, spender, currentAllowance - amount);
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
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal {}

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
  function _afterTokenTransfer(address from, address to, uint256 amount) internal {}

  function getCurrentEpochTimestamp() public view returns (uint256 epochTimestamp) {
    return (block.timestamp / epochLength) * epochLength;
  }

  function setMinter(address _minter, bool _mintable) external onlyOwner {
    minter[_minter] = _mintable;

    emit SetMinter(_minter, _mintable);
  }

  function isMinter(address _minter) external view returns (bool) {
    return minter[_minter];
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}