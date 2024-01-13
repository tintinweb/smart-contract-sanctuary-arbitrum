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
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/ERC4626.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../utils/SafeERC20.sol";
import "../../../interfaces/IERC4626.sol";
import "../../../utils/math/Math.sol";

/**
 * @dev Implementation of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the ERC20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the ERC20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * [CAUTION]
 * ====
 * In empty (or nearly empty) ERC-4626 vaults, deposits are at high risk of being stolen through frontrunning
 * with a "donation" to the vault that inflates the price of a share. This is variously known as a donation or inflation
 * attack and is essentially a problem of slippage. Vault deployers can protect against this attack by making an initial
 * deposit of a non-trivial amount of the asset, such that price manipulation becomes infeasible. Withdrawals may
 * similarly be affected by slippage. Users can protect against this attack as well as unexpected slippage in general by
 * verifying the amount received is as expected, using a wrapper that performs these checks such as
 * https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
 *
 * Since v4.9, this implementation uses virtual assets and shares to mitigate that risk. The `_decimalsOffset()`
 * corresponds to an offset in the decimal representation between the underlying asset's decimals and the vault
 * decimals. This offset also determines the rate of virtual shares to virtual assets in the vault, which itself
 * determines the initial exchange rate. While not fully preventing the attack, analysis shows that the default offset
 * (0) makes it non-profitable, as a result of the value being captured by the virtual shares (out of the attacker's
 * donation) matching the attacker's expected gains. With a larger offset, the attack becomes orders of magnitude more
 * expensive than it is profitable. More details about the underlying math can be found
 * xref:erc4626.adoc#inflation-attack[here].
 *
 * The drawback of this approach is that the virtual shares do capture (a very small) part of the value being accrued
 * to the vault. Also, if the vault experiences losses, the users try to exit the vault, the virtual shares and assets
 * will cause the first user to exit to experience reduced losses in detriment to the last users that will experience
 * bigger losses. Developers willing to revert back to the pre-v4.9 behavior just need to override the
 * `_convertToShares` and `_convertToAssets` functions.
 *
 * To learn more, check out our xref:ROOT:erc4626.adoc[ERC-4626 guide].
 * ====
 *
 * _Available since v4.7._
 */
abstract contract ERC4626 is ERC20, IERC4626 {
    using Math for uint256;

    IERC20 private immutable _asset;
    uint8 private immutable _underlyingDecimals;

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    constructor(IERC20 asset_) {
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        _underlyingDecimals = success ? assetDecimals : 18;
        _asset = asset_;
    }

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(IERC20 asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /**
     * @dev Decimals are computed by adding the decimal offset on top of the underlying asset's decimals. This
     * "original" value is cached during construction of the vault contract. If this read operation fails (e.g., the
     * asset has not been created yet), a default of 18 is used to represent the underlying asset's decimals.
     *
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return _underlyingDecimals + _decimalsOffset();
    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return _convertToAssets(balanceOf(owner), Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(uint256 assets, address receiver, address owner) public virtual override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(uint256 shares, address receiver, address owner) public virtual override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual returns (uint256) {
        return assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual returns (uint256) {
        return shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding);
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual {
        // If _asset is ERC777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _decimalsOffset() internal view virtual returns (uint8) {
        return 0;
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
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

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
library SafeMath {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.9.0;

import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param pool Address of the pool that we want to observe
    /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
    /// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
    /// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
    function consult(address pool, uint32 secondsAgo)
        internal
        view
        returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity)
    {
        require(secondsAgo != 0, 'BP');

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) = IUniswapV3Pool(pool)
            .observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        uint160 secondsPerLiquidityCumulativesDelta = secondsPerLiquidityCumulativeX128s[1] -
            secondsPerLiquidityCumulativeX128s[0];

        arithmeticMeanTick = int24(tickCumulativesDelta / int56(uint56(secondsAgo)));
        // Always round to negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(secondsAgo)) != 0)) arithmeticMeanTick--;

        // We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
        uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
        harmonicMeanLiquidity = uint128(secondsAgoX160 / (uint192(secondsPerLiquidityCumulativesDelta) << 32));
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }

    /// @notice Given a pool, it returns the number of seconds ago of the oldest stored observation
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @return secondsAgo The number of seconds ago of the oldest observation stored for the pool
    function getOldestObservationSecondsAgo(address pool) internal view returns (uint32 secondsAgo) {
        (, , uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();
        require(observationCardinality > 0, 'NI');

        (uint32 observationTimestamp, , , bool initialized) = IUniswapV3Pool(pool).observations(
            (observationIndex + 1) % observationCardinality
        );

        // The next index might not be initialized if the cardinality is in the process of increasing
        // In this case the oldest observation is always in index 0
        if (!initialized) {
            (observationTimestamp, , , ) = IUniswapV3Pool(pool).observations(0);
        }

        unchecked {
            secondsAgo = uint32(block.timestamp) - observationTimestamp;
        }
    }

    /// @notice Given a pool, it returns the tick value as of the start of the current block
    /// @param pool Address of Uniswap V3 pool
    /// @return The tick that the pool was in at the start of the current block
    function getBlockStartingTickAndLiquidity(address pool) internal view returns (int24, uint128) {
        (, int24 tick, uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();

        // 2 observations are needed to reliably calculate the block starting tick
        require(observationCardinality > 1, 'NEO');

        // If the latest observation occurred in the past, then no tick-changing trades have happened in this block
        // therefore the tick in `slot0` is the same as at the beginning of the current block.
        // We don't need to check if this observation is initialized - it is guaranteed to be.
        (
            uint32 observationTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,

        ) = IUniswapV3Pool(pool).observations(observationIndex);
        if (observationTimestamp != uint32(block.timestamp)) {
            return (tick, IUniswapV3Pool(pool).liquidity());
        }

        uint256 prevIndex = (uint256(observationIndex) + observationCardinality - 1) % observationCardinality;
        (
            uint32 prevObservationTimestamp,
            int56 prevTickCumulative,
            uint160 prevSecondsPerLiquidityCumulativeX128,
            bool prevInitialized
        ) = IUniswapV3Pool(pool).observations(prevIndex);

        require(prevInitialized, 'ONI');

        uint32 delta = observationTimestamp - prevObservationTimestamp;
        tick = int24((tickCumulative - int56(uint56(prevTickCumulative))) / int56(uint56(delta)));
        uint128 liquidity = uint128(
            (uint192(delta) * type(uint160).max) /
                (uint192(secondsPerLiquidityCumulativeX128 - prevSecondsPerLiquidityCumulativeX128) << 32)
        );
        return (tick, liquidity);
    }

    /// @notice Information for calculating a weighted arithmetic mean tick
    struct WeightedTickData {
        int24 tick;
        uint128 weight;
    }

    /// @notice Given an array of ticks and weights, calculates the weighted arithmetic mean tick
    /// @param weightedTickData An array of ticks and weights
    /// @return weightedArithmeticMeanTick The weighted arithmetic mean tick
    /// @dev Each entry of `weightedTickData` should represents ticks from pools with the same underlying pool tokens. If they do not,
    /// extreme care must be taken to ensure that ticks are comparable (including decimal differences).
    /// @dev Note that the weighted arithmetic mean tick corresponds to the weighted geometric mean price.
    function getWeightedArithmeticMeanTick(WeightedTickData[] memory weightedTickData)
        internal
        pure
        returns (int24 weightedArithmeticMeanTick)
    {
        // Accumulates the sum of products between each tick and its weight
        int256 numerator;

        // Accumulates the sum of the weights
        uint256 denominator;

        // Products fit in 152 bits, so it would take an array of length ~2**104 to overflow this logic
        for (uint256 i; i < weightedTickData.length; i++) {
            numerator += weightedTickData[i].tick * int256(uint256(weightedTickData[i].weight));
            denominator += weightedTickData[i].weight;
        }

        weightedArithmeticMeanTick = int24(numerator / int256(denominator));
        // Always round to negative infinity
        if (numerator < 0 && (numerator % int256(denominator) != 0)) weightedArithmeticMeanTick--;
    }

    /// @notice Returns the "synthetic" tick which represents the price of the first entry in `tokens` in terms of the last
    /// @dev Useful for calculating relative prices along routes.
    /// @dev There must be one tick for each pairwise set of tokens.
    /// @param tokens The token contract addresses
    /// @param ticks The ticks, representing the price of each token pair in `tokens`
    /// @return syntheticTick The synthetic tick, representing the relative price of the outermost tokens in `tokens`
    function getChainedPrice(address[] memory tokens, int24[] memory ticks)
        internal
        pure
        returns (int256 syntheticTick)
    {
        require(tokens.length - 1 == ticks.length, 'DL');
        for (uint256 i = 1; i <= ticks.length; i++) {
            // check the tokens for address sort order, then accumulate the
            // ticks into the running synthetic tick, ensuring that intermediate tokens "cancel out"
            tokens[i - 1] < tokens[i] ? syntheticTick += ticks[i - 1] : syntheticTick -= ticks[i - 1];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Dropper is Ownable {
    IERC20 public vault;
    address public treasury;

    constructor(address _vault, address _treasury) {
        vault = IERC20(_vault);
        treasury = _treasury;
        vault.approve(treasury, type(uint256).max);
    }

    function setVault(address _vault) external onlyOwner {
        vault = IERC20(_vault);
        vault.approve(address(vault), type(uint256).max);
    }

    function drop(
        address[] memory _newUsers,
        uint256[] memory _balances
    ) external onlyOwner {
        require(_newUsers.length == _balances.length, "length not equal");
        for (uint256 i = 0; i < _newUsers.length; i++) {
            vault.transfer(_newUsers[i], _balances[i]);
        }
    }

    function emergencyExit() external onlyOwner {
        vault.transfer(treasury, vault.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IAcrossHub {

    struct PooledToken {
        // LP token given to LPs of a specific L1 token.
        address lpToken;
        // True if accepting new LP's.
        bool isEnabled;
        // Timestamp of last LP fee update.
        uint32 lastLpFeeUpdate;
        // Number of LP funds sent via pool rebalances to SpokePools and are expected to be sent
        // back later.
        int256 utilizedReserves;
        // Number of LP funds held in contract less utilized reserves.
        uint256 liquidReserves;
        // Number of LP funds reserved to pay out to LPs as fees.
        uint256 undistributedLpFees;
    }

    function pooledTokens(address l1Token) external view returns(PooledToken memory);
    function addLiquidity(address l1Token, uint256 l1TokenAmount) external payable;
    function removeLiquidity(
        address l1Token,
        uint256 lpTokenAmount,
        bool sendEth
    ) external;

    function exchangeRateCurrent(address l1Token) external returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

struct UserDeposit {
    uint256 cumulativeBalance;
    uint256 averageDepositTime;
    uint256 rewardsAccumulatedPerToken;
    uint256 rewardsOutstanding;
}

interface IAcrossStaker {
    function getUserStake(
        address stakedToken,
        address account
    ) external view returns (UserDeposit memory);

    function getOutstandingRewards(
        address stakedToken,
        address account
    ) external view returns (uint256);

    function unstake(address stakedToken, uint256 amount) external;

    function withdrawReward(address stakedToken) external;

    function stake(address stakedToken, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IBalDepositWrapper {
    function deposit(
        uint256 _amount,
        uint256 _minOut,
        bool _lock,
        address _stakeAddress
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IAuraMinter {
    function inflationProtectionTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IAuraToken {
    function minter() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface ICvx {
    function reductionPerCliff() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalCliffs() external view returns (uint256);

    function INIT_MINT_AMOUNT() external view returns (uint256);

    function EMISSIONS_MAX_SUPPLY() external view returns (uint256);

    function maxSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBalancerPool is IERC20 {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SwapRequest {
        SwapKind kind;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }

    // virtual price of bpt
    function getRate() external view returns (uint);

    function getTokenRate(address token) external view returns (uint);

    function getInvariant() external view returns (uint);

    function getPoolId() external view returns (bytes32 poolId);

    function symbol() external view returns (string memory s);

    function onSwap(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) external view returns (uint256 amount);

    function swapExactAmountIn(
        address,
        uint,
        address,
        uint,
        uint
    ) external returns (uint, uint);

    function swapExactAmountOut(
        address,
        uint,
        address,
        uint,
        uint
    ) external returns (uint, uint);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.18;

/**
 * @dev Interface for querying historical data from a Pool that can be used as a Price Oracle.
 *
 * This lets third parties retrieve average prices of tokens held by a Pool over a given period of time, as well as the
 * price of the Pool share token (BPT) and invariant. Since the invariant is a sensible measure of Pool liquidity, it
 * can be used to compare two different price sources, and choose the most liquid one.
 *
 * Once the oracle is fully initialized, all queries are guaranteed to succeed as long as they require no data that
 * is not older than the largest safe query window.
 */
interface IBalancerPriceOracle {
    // The three values that can be queried:
    //
    // - PAIR_PRICE: the price of the tokens in the Pool, expressed as the price of the second token in units of the
    //   first token. For example, if token A is worth $2, and token B is worth $4, the pair price will be 2.0.
    //   Note that the price is computed *including* the tokens decimals. This means that the pair price of a Pool with
    //   DAI and USDC will be close to 1.0, despite DAI having 18 decimals and USDC 6.
    //
    // - BPT_PRICE: the price of the Pool share token (BPT), in units of the first token.
    //   Note that the price is computed *including* the tokens decimals. This means that the BPT price of a Pool with
    //   USDC in which BPT is worth $5 will be 5.0, despite the BPT having 18 decimals and USDC 6.
    //
    // - INVARIANT: the value of the Pool's invariant, which serves as a measure of its liquidity.
    enum Variable {
        PAIR_PRICE,
        BPT_PRICE,
        INVARIANT
    }

    /**
     * @dev Returns the time average weighted price corresponding to each of `queries`. Prices are represented as 18
     * decimal fixed point values.
     */
    function getTimeWeightedAverage(
        OracleAverageQuery[] memory queries
    ) external view returns (uint256[] memory results);

    /**
     * @dev Returns latest sample of `variable`. Prices are represented as 18 decimal fixed point values.
     */
    function getLatest(Variable variable) external view returns (uint256);

    /**
     * @dev Information for a Time Weighted Average query.
     *
     * Each query computes the average over a window of duration `secs` seconds that ended `ago` seconds ago. For
     * example, the average over the past 30 minutes is computed by settings secs to 1800 and ago to 0. If secs is 1800
     * and ago is 1800 as well, the average between 60 and 30 minutes ago is computed instead.
     */
    struct OracleAverageQuery {
        Variable variable;
        uint256 secs;
        uint256 ago;
    }

    /**
     * @dev Returns largest time window that can be safely queried, where 'safely' means the Oracle is guaranteed to be
     * able to produce a result and not revert.
     *
     * If a query has a non-zero `ago` value, then `secs + ago` (the oldest point in time) must be smaller than this
     * value for 'safe' queries.
     */
    function getLargestSafeQueryWindow() external view returns (uint256);

    /**
     * @dev Returns the accumulators corresponding to each of `queries`.
     */
    function getPastAccumulators(
        OracleAccumulatorQuery[] memory queries
    ) external view returns (int256[] memory results);

    /**
     * @dev Information for an Accumulator query.
     *
     * Each query estimates the accumulator at a time `ago` seconds ago.
     */
    struct OracleAccumulatorQuery {
        Variable variable;
        uint256 ago;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IAsset {}

interface IBalancerV2Vault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
    }

    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT
    }

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    enum UserBalanceOpKind {
        DEPOSIT_INTERNAL,
        WITHDRAW_INTERNAL,
        TRANSFER_INTERNAL,
        TRANSFER_EXTERNAL
    }

    struct UserBalanceOp {
        UserBalanceOpKind kind;
        address asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    function getPool(bytes32 poolId) external view returns (address pool);

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256 amountCalculated);

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    function getPoolTokens(
        bytes32 poolId
    )
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    // CAVEAT!! Do not call this after a batchSwap in the same txn
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    function manageUserBalance(UserBalanceOp[] memory ops) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IConvexDeposit {
    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IConvexRewards {
    // strategy's staked balance in the synthetix staking contract
    function balanceOf(address account) external view returns (uint256);

    // read how much claimable CRV a strategy has
    function earned(address account) external view returns (uint256);

    // burn a tokenized deposit (Convex deposit tokens) to receive curve lp tokens back
    function withdraw(uint256 _amount, bool _claim) external returns (bool);

    // withdraw directly to curve LP token, this is what we primarily use
    function withdrawAndUnwrap(
        uint256 _amount,
        bool _claim
    ) external returns (bool);

    // claim rewards, with an option to claim extra rewards or not
    function getReward(
        address _account,
        bool _claimExtras
    ) external returns (bool);

    // check if we have rewards on a pool
    function extraRewardsLength() external view returns (uint256);

    // if we have rewards, see what the address is
    function extraRewards(uint256 _reward) external view returns (address);

    // read our rewards token
    function rewardToken() external view returns (address);

    // check our reward period finish
    function periodFinish() external view returns (uint256);

    function stakeAll() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface ICurve {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dx_underlying(
        int128 i,
        int128 j,
        uint256 dy
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dx(
        int128 i,
        int128 j,
        uint256 dy
    ) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function last_price() external view returns (uint256);

    function price_oracle() external view returns (uint256);

    function price_oracle(uint256 k) external view returns (uint256);

    function calc_withdraw_one_coin(
        uint256 token_amount,
        uint256 i
    ) external view returns (uint256);

    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        bool use_eth
    ) external payable returns (uint256);

    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        address receiver
    ) external payable returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 min_amount,
        bool use_eth
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount,
        address receiver
    ) external returns (uint256);

    function lp_price() external view returns (uint256);
}

interface ICurveSwapRouter {
    function exchange_multiple(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _amount,
        uint256 _expected
    ) external payable returns (uint256);

    function exchange_multiple(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _amount,
        uint256 _expected,
        address[4] memory _pools
    ) external payable returns (uint256);
}

interface ICurve2 {
    function calc_withdraw_one_coin(
        uint256 token_amount,
        int128 i
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IFraxMinter {
    function submitAndDeposit(address recipient) external payable;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

interface IUniswapV2Router01V5 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISfrxEth is IERC20 {
    function previewRedeem(uint256 shares) external view returns (uint256);

    function previewWithdraw(uint256 assets) external view returns (uint256);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256);

    function syncRewards() external;

    function rewardsCycleEnd() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function pricePerShare() external view returns (uint256);
}

pragma solidity ^0.8.18;

interface IGNSVault {
    struct Staker {
        uint128 stakedGns; // 1e18
        uint128 debtDai; // 1e18
    }

    function harvestDai() external;

    function stakeGns(uint128 amount) external;

    function unstakeGns(uint128 _amountAmount) external;

    function stakers(address staker) external view returns (Staker memory);

    function pendingRewardDai(address staker) external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

interface IGMDStaking {
    function userInfo(
        uint256 _pid,
        address user
    ) external view returns (uint256, uint256, uint256, uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingWETH(
        uint256 _pid,
        address _user
    ) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

interface IRewardRouterV2 {
    function stakeGmx(uint256 _amount) external;

    function stakeEsGmx(uint256 _amount) external;

    function unstakeGmx(uint256 _amount) external;

    function unstakeEsGmx(uint256 _amount) external;

    function compound() external;

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function signalTransfer(address _receiver) external;

    function acceptTransfer(address _sender) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

interface IRewardTracker {
    function depositBalances(
        address _account,
        address _depositToken
    ) external view returns (uint256);

    function stakedAmounts(address _account) external view returns (uint256);

    function updateRewards() external;

    function stake(address _depositToken, uint256 _amount) external;

    function stakeForAccount(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) external;

    function unstake(address _depositToken, uint256 _amount) external;

    function unstakeForAccount(
        address _account,
        address _depositToken,
        uint256 _amount,
        address _receiver
    ) external;

    function tokensPerInterval() external view returns (uint256);

    function claim(address _receiver) external returns (uint256);

    function claimForAccount(
        address _account,
        address _receiver
    ) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function averageStakedAmounts(
        address _account
    ) external view returns (uint256);

    function cumulativeRewards(
        address _account
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IRouter {
    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function calculateTokenAmount(
        address account,
        uint256[] calldata amounts,
        bool deposit
    ) external view returns (uint256);

    function calculateRemoveLiquidity(
        address account,
        uint256 amount
    ) external view returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(
        address account,
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IStakingRewards {
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function earned(address account) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ILBRouter {
    enum Version {
        V1,
        V2,
        V2_1
    }

    struct Path {
        uint256[] pairBinSteps;
        Version[] versions;
        IERC20[] tokenPath;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IStableJoeStaking {
    function deposit(uint256 _amount) external;

    function getUserInfo(
        address _user,
        address _rewardToken
    ) external view returns (uint256, uint256);

    function pendingReward(
        address _user,
        address _token
    ) external view returns (uint256);

    function withdraw(uint256 _amount) external;

    function feeCollector() external view returns (address);

    function updateReward(address token) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWSTEth is IERC20 {
    function wrap(uint256 _stETHAmount) external returns (uint256);

    function unwrap(uint256 _wstETHAmount) external returns (uint256);

    function getStETHByWstETH(
        uint256 _wstETHAmount
    ) external view returns (uint256);

    function getWstETHByStETH(
        uint256 _stETHAmount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.18;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

// optimism implementation : https://optimistic.etherscan.io/address/0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45#code
/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IVeloGauge {
    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward(address account) external;

    function earned(address account) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IVeloRouter {
    struct Route {
        address from;
        address to;
        bool stable;
        address factory;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint256 liquidity
    ) external view returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(
        uint256 amountIn,
        Route[] memory routes
    ) external view returns (uint256[] memory amounts);

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint256 amountADesired,
        uint256 amountBDesired
    )
        external
        view
        returns (uint256 amountA, uint256 amountB, uint256 liquidity);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IBaseStrategy {
    function adjustPosition(uint256 _debtOutstanding) external;

    function migrate(address _newStrategy) external;

    function withdraw(uint256 amount) external returns (uint256);

    function estimatedTotalAssets() external view returns (uint256);

    function delegatedAssets() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBaseVault {
    function token() external view returns (IERC20);

    function withdraw() external returns (uint256);

    function deposit(
        uint256 _amount,
        address _recipient
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface IOnChainVault {
    error Vault__OnlyAuthorized(address); //0x1748142d
    error Vault__V2(); //0xd30204e1
    error Vault__V3(); //0xb22f5305
    error Vault__V4(); //0x5f0c12c8
    error Vault__NotEnoughShares(); //0x309d83b1
    error Vault__ZeroToWithdraw(); //0xd498103e
    error Vault__UnacceptableLoss(); //0x03fe7f1c
    error Vault__InactiveStrategy(); //0x7ce4e353
    error Vault__V6(); //0x6818be95
    error Vault__V7(); //0x33378859
    error Vault__V8(); //0x33d7203e
    error Vault__V9(); //0x56c54560
    error Vault__V13(); //0x908776f1
    error Vault__V14(); //0xcc588483
    error Vault__V15(); //0x429bf29b
    error Vault__V17(); //0x0fc96878
    error Vault__DepositLimit(); //
    error Vault__UnAcceptableFee();
    error Vault__MinMaxDebtError();
    error Vault__AmountIsIncorrect(uint256 amount);

    event StrategyWithdrawnSome(
        address indexed strategy,
        uint256 amount,
        uint256 loss
    );
    event StrategyReported(
        address strategy,
        uint256 gain,
        uint256 loss,
        uint256 debtPaid,
        uint256 totalGain,
        uint256 totalLoss,
        uint256 totalDebt,
        uint256 debtAdded,
        uint256 debtRatio
    );

    event Withdraw(
        address indexed recipient,
        uint256 indexed shares,
        uint256 indexed value
    );

    function initialize(
        IERC20 _token,
        address _governance,
        address treasury,
        string calldata name,
        string calldata symbol
    ) external;

    function token() external view returns (IERC20);

    function revokeFunds() external;

    function totalAssets() external view returns (uint256);

    function deposit(
        uint256 _amount,
        address _recipient
    ) external returns (uint256);

    function withdraw(
        uint256 _maxShares,
        address _recipient,
        uint256 _maxLoss
    ) external;

    function addStrategy(
        address _strategy,
        uint256 _debtRatio,
        uint256 _performanceFee,
        uint256 _minDebtPerHarvest,
        uint256 _maxDebtPerHarvest
    ) external;

    function pricePerShare() external view returns (uint256);

    function revokeStrategy(address _strategy) external;

    function updateStrategyDebtRatio(
        address _strategy,
        uint256 _debtRatio
    ) external;

    function governance() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../contracts/interfaces/IBaseVault.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Migration is Ownable, ReentrancyGuard {
    IBaseVault public vaultV1;
    IBaseVault public vaultV2;

    address public treasury;

    address[] public users;

    IERC20 public token;

    mapping(address user => uint256 balance) public userToBalance;

    address[] public notWithdrawnUsers;

    constructor(address _vaultV1, address[] memory _users, address _treasury) {
        vaultV1 = IBaseVault(_vaultV1);
        users = _users;
        treasury = _treasury;
        token = vaultV1.token();
        vaultV1.token().approve(treasury, type(uint256).max);
    }

    function setVaultV2(address _vaultV2) external onlyOwner {
        vaultV2 = IBaseVault(_vaultV2);
        vaultV1.token().approve(address(vaultV2), type(uint256).max);
    }

    function addUsers(address[] memory _newUsers) external onlyOwner {
        for (uint256 i = 0; i < _newUsers.length; i++) {
            users.push(_newUsers[i]);
        }
    }

    function withdraw() external nonReentrant {
        for (uint256 i = 0; i < users.length; i++) {
            uint256 userBalance = IERC20(address(vaultV1)).balanceOf(users[i]);
            if (userBalance == 0) {
                continue;
            }
            if (
                IERC20(address(vaultV1)).allowance(users[i], address(this)) <
                userBalance
            ) {
                if (!checkUserExistence(users[i])) {
                    notWithdrawnUsers.push(users[i]);
                }
                continue;
            }
            IERC20(address(vaultV1)).transferFrom(
                users[i],
                address(this),
                userBalance
            );

            userToBalance[users[i]] += userBalance;
        }
        if (IERC20(address(vaultV1)).balanceOf(address(this)) > 0) {
            vaultV1.withdraw();
        }
    }

    function withdrawUsersWithDetectedError() external nonReentrant {
        for (uint256 i = 0; i < notWithdrawnUsers.length; i++) {
            if (notWithdrawnUsers[i] == address(0)) {
                continue;
            }
            uint256 userBalance = IERC20(address(vaultV1)).balanceOf(
                notWithdrawnUsers[i]
            );
            if (
                userBalance == 0 ||
                IERC20(address(vaultV1)).allowance(
                    notWithdrawnUsers[i],
                    address(this)
                ) <
                userBalance
            ) {
                continue;
            }
            IERC20(address(vaultV1)).transferFrom(
                notWithdrawnUsers[i],
                address(this),
                userBalance
            );

            userToBalance[notWithdrawnUsers[i]] += userBalance;

            notWithdrawnUsers[i] = address(0);
        }
        vaultV1.withdraw();
    }

    function deposit() external nonReentrant {
        vaultV2.deposit(token.balanceOf(address(this)), address(this));
    }

    function emergencyExit() external onlyOwner {
        vaultV1.token().transfer(treasury, token.balanceOf(address(this)));
        IERC20(address(vaultV2)).transfer(
            treasury,
            IERC20(address(vaultV2)).balanceOf(address(this))
        );
        IERC20(address(vaultV1)).transfer(
            treasury,
            IERC20(address(vaultV1)).balanceOf(address(this))
        );
    }

    function checkUserExistence(address _user) internal view returns (bool) {
        for (uint256 i = 0; i < notWithdrawnUsers.length; i++) {
            if (notWithdrawnUsers[i] == _user) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {GMXStrategy, ERC20} from "../../strategies/arbitrum/GMXStrategy.sol";

contract MockGMXStrategy is GMXStrategy {
    bool internal _isWantToGmxOverriden;
    uint256 internal _wantToGmx;

    bool internal _isTotalAssetsOverridden;
    uint256 internal _estimatedTotalAssets;

    constructor(address vault) GMXStrategy(vault) {}

    function overrideWantToGmx(uint256 target) external {
        _isWantToGmxOverriden = true;
        _wantToGmx = target;
    }

    function overrideEstimatedTotalAssets(uint256 targetValue) external {
        _isTotalAssetsOverridden = true;
        _estimatedTotalAssets = targetValue;
    }

    function estimatedTotalAssets()
        public
        view
        override
        returns (uint256 _wants)
    {
        if (_isTotalAssetsOverridden) return _estimatedTotalAssets;
        return super.estimatedTotalAssets();
    }

    function wantToGmx(uint256 _want) public view override returns (uint256) {
        if (_isWantToGmxOverriden) return _wantToGmx;
        return super.wantToGmx(_want);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {JOEStrategy, ERC20} from "../../strategies/arbitrum/JOEStrategy.sol";

contract MockJOEStrategy is JOEStrategy {
    bool internal _isWantToJoeOverriden;
    uint256 internal _wantToJoe;

    bool internal _isTotalAssetsOverridden;
    uint256 internal _estimatedTotalAssets;

    bool internal _isBalanceOfRewardsOverriden;
    uint256 internal _balanceOfRewards;

    constructor(address vault) JOEStrategy(vault) {}

    function overrideWantToJoe(uint256 target) external {
        _isWantToJoeOverriden = true;
        _wantToJoe = target;
    }

    function overrideBalanceOfRewards(uint256 target) external {
        _isBalanceOfRewardsOverriden = true;
        _balanceOfRewards = target;
    }

    function overrideEstimatedTotalAssets(uint256 targetValue) external {
        _isTotalAssetsOverridden = true;
        _estimatedTotalAssets = targetValue;
    }

    function estimatedTotalAssets()
        public
        view
        override
        returns (uint256 _wants)
    {
        if (_isTotalAssetsOverridden) return _estimatedTotalAssets;
        return super.estimatedTotalAssets();
    }

    function wantToJoe(uint256 _want) public view override returns (uint256) {
        if (_isWantToJoeOverriden) return _wantToJoe;
        return super.wantToJoe(_want);
    }

    function balanceOfRewards() public view override returns (uint256) {
        if (_isBalanceOfRewardsOverriden) return _balanceOfRewards;
        return super.balanceOfRewards();
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {AuraBALStrategy, ERC20} from "../strategies/AuraBALStrategy.sol";

contract MockAuraBALStrategy is AuraBALStrategy {
    bool internal _isWantToAuraBalOverriden;
    uint256 internal _wantToAuraBal;

    bool internal _isTotalAssetsOverridden;
    uint256 internal _estimatedTotalAssets;

    constructor(address vault) AuraBALStrategy(vault) {}

    function overrideWantToAuraBal(uint256 target) external {
        _isWantToAuraBalOverriden = true;
        _wantToAuraBal = target;
    }

    function overrideEstimatedTotalAssets(uint256 targetValue) external {
        _isTotalAssetsOverridden = true;
        _estimatedTotalAssets = targetValue;
    }

    function estimatedTotalAssets()
        public
        view
        override
        returns (uint256 _wants)
    {
        if (_isTotalAssetsOverridden) return _estimatedTotalAssets;
        return super.estimatedTotalAssets();
    }

    function wantToAuraBal(
        uint256 _want
    ) public view override returns (uint256) {
        if (_isWantToAuraBalOverriden) return _wantToAuraBal;
        return super.wantToAuraBal(_want);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {AuraWETHStrategy, ERC20} from "../strategies/AuraWETHStrategy.sol";

contract MockAuraWETHStrategy is AuraWETHStrategy {
    bool internal _isWantToBptOverriden;
    uint256 internal _wantToBpt;

    bool internal _isTotalAssetsOverridden;
    uint256 internal _estimatedTotalAssets;

    constructor(address vault) AuraWETHStrategy(vault) {}

    function overrideWantToBpt(uint256 target) external {
        _isWantToBptOverriden = true;
        _wantToBpt = target;
    }

    function overrideEstimatedTotalAssets(uint256 targetValue) external {
        _isTotalAssetsOverridden = true;
        _estimatedTotalAssets = targetValue;
    }

    function estimatedTotalAssets()
        public
        view
        override
        returns (uint256 _wants)
    {
        if (_isTotalAssetsOverridden) return _estimatedTotalAssets;
        return super.estimatedTotalAssets();
    }

    function wantToBpt(uint256 _want) public view override returns (uint256) {
        if (_isWantToBptOverriden) return _wantToBpt;
        return super.wantToBpt(_want);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {CVXStrategy, ERC20} from "../strategies/CVXStrategy.sol";

contract MockCVXStrategy is CVXStrategy {
    bool internal _isWantToCurveLPOverriden;
    uint256 internal _wantToCurveLP;

    bool internal _isTotalAssetsOverridden;
    uint256 internal _estimatedTotalAssets;

    constructor(address vault) CVXStrategy(vault) {}

    function overrideWantToCurveLP(uint256 target) external {
        _isWantToCurveLPOverriden = true;
        _wantToCurveLP = target;
    }

    function overrideEstimatedTotalAssets(uint256 targetValue) external {
        _isTotalAssetsOverridden = true;
        _estimatedTotalAssets = targetValue;
    }

    function estimatedTotalAssets()
        public
        view
        override
        returns (uint256 _wants)
    {
        if (_isTotalAssetsOverridden) return _estimatedTotalAssets;
        return super.estimatedTotalAssets();
    }

    function wantToCurveLP(
        uint256 _want
    ) public view override returns (uint256) {
        if (_isWantToCurveLPOverriden) return _wantToCurveLP;
        return super.wantToCurveLP(_want);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {FXSStrategy, ERC20} from "../strategies/FXSStrategy.sol";

contract MockFXSStrategy is FXSStrategy {
    bool internal _isWantToCurveLPOverriden;
    uint256 internal _wantToCurveLP;

    bool internal _isTotalAssetsOverridden;
    uint256 internal _estimatedTotalAssets;

    constructor(address vault) FXSStrategy(vault) {}

    function overrideWantToCurveLP(uint256 target) external {
        _isWantToCurveLPOverriden = true;
        _wantToCurveLP = target;
    }

    function overrideEstimatedTotalAssets(uint256 targetValue) external {
        _isTotalAssetsOverridden = true;
        _estimatedTotalAssets = targetValue;
    }

    function estimatedTotalAssets()
        public
        view
        override
        returns (uint256 _wants)
    {
        if (_isTotalAssetsOverridden) return _estimatedTotalAssets;
        return super.estimatedTotalAssets();
    }

    function wantToCurveLP(
        uint256 _want
    ) public view override returns (uint256) {
        if (_isWantToCurveLPOverriden) return _wantToCurveLP;
        return super.wantToCurveLP(_want);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {YCRVStrategy, ERC20} from "../strategies/YCRVStrategy.sol";

contract MockYCRVStrategy is YCRVStrategy {
    bool internal _isTotalAssetsOverridden;
    uint256 internal _estimatedTotalAssets;

    bool internal _isWantToStYCRVOverriden;
    uint256 internal _wantToStYCRV;

    constructor(address vault) YCRVStrategy(vault) {}

    function overrideEstimatedTotalAssets(uint256 targetValue) external {
        _isTotalAssetsOverridden = true;
        _estimatedTotalAssets = targetValue;
    }

    function overrideWantToStYCRV(uint256 targetValue) external {
        _isWantToStYCRVOverriden = true;
        _wantToStYCRV = targetValue;
    }

    function wantToStYCrv(
        uint256 value
    ) public view override returns (uint256) {
        if (_isWantToStYCRVOverriden) {
            return _wantToStYCRV;
        }
        return super.wantToStYCrv(value);
    }

    function estimatedTotalAssets()
        public
        view
        override
        returns (uint256 _wants)
    {
        if (_isTotalAssetsOverridden) return _estimatedTotalAssets;
        return super.estimatedTotalAssets();
    }

    function scaleDecimals(
        uint _amount,
        ERC20 _fromToken,
        ERC20 _toToken
    ) public view returns (uint _scaled) {
        return _scaleDecimals(_amount, _fromToken, _toToken);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import "../utils/AuraMath.sol";

contract TestAuraMath {
    function convertCrvToCvx(uint256 _amount) public view returns (uint256) {
        return AuraRewardsMath.convertCrvToCvx(_amount);
    }
}

import "../strategies/RocketAuraStrategy.sol";
import "../utils/AuraMath.sol";

contract TestScaler is RocketAuraStrategy {
    constructor(address _vault) RocketAuraStrategy(_vault) {}

    function scaleDecimals(
        uint _amount,
        ERC20 _fromToken,
        ERC20 _toToken
    ) public view returns (uint _scaled) {
        return Utils.scaleDecimals(_amount, _fromToken, _toToken);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseStrategyInitializable, StrategyParams, VaultAPI} from "@yearn-protocol/contracts/BaseStrategy.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*
 * This Strategy serves as both a mock Strategy for testing, and an example
 * for integrators on how to use BaseStrategy
 */

contract TestStrategy is BaseStrategyInitializable {
    bool public doReentrancy;
    bool public delegateEverything;

    // Some token that needs to be protected for some reason
    // Initialize this to some fake address, because we're just using it
    // to test `BaseStrategy.protectedTokens()`
    address public constant protectedToken = address(0xbad);

    constructor(address _vault) BaseStrategyInitializable(_vault) {}

    function name() external view override returns (string memory) {
        return string(abi.encodePacked("TestStrategy ", apiVersion()));
    }

    // NOTE: This is a test-only function to simulate delegation
    function _toggleDelegation() public onlyStrategist {
        delegateEverything = !delegateEverything;
    }

    function delegatedAssets() external view override returns (uint256) {
        if (delegateEverything) {
            return vault.strategies(address(this)).totalDebt;
        } else {
            return 0;
        }
    }

    // NOTE: This is a test-only function to simulate losses
    function _takeFunds(uint256 amount) public onlyStrategist {
        SafeERC20.safeTransfer(want, msg.sender, amount);
    }

    // NOTE: This is a test-only function to enable reentrancy on withdraw
    function _toggleReentrancyExploit() public onlyStrategist {
        doReentrancy = !doReentrancy;
    }

    // NOTE: This is a test-only function to simulate a wrong want token
    function _setWant(IERC20 _want) public onlyStrategist {
        want = _want;
    }

    function ethToWant(
        uint256 amtInWei
    ) public view override returns (uint256) {
        return amtInWei; // 1:1 conversion for testing
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        // For mock, this is just everything we have
        return want.balanceOf(address(this));
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        // During testing, send this contract some tokens to simulate "Rewards"
        uint256 totalAssets = want.balanceOf(address(this));
        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        if (totalAssets > _debtOutstanding) {
            _debtPayment = _debtOutstanding;
            totalAssets = totalAssets - _debtOutstanding;
        } else {
            _debtPayment = totalAssets;
            totalAssets = 0;
        }
        totalDebt = totalDebt - _debtPayment;

        if (totalAssets > totalDebt) {
            _profit = totalAssets - totalDebt;
        } else {
            _loss = totalDebt - totalAssets;
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        // Whatever we have "free", consider it "invested" now
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        if (doReentrancy) {
            // simulate a malicious protocol or reentrancy situation triggered by strategy withdraw interactions
            uint256 stratBalance = VaultAPI(address(vault)).balanceOf(
                address(this)
            );
            VaultAPI(address(vault)).withdraw(stratBalance, address(this));
        }

        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        uint256 totalAssets = want.balanceOf(address(this));
        if (_amountNeeded > totalAssets) {
            _liquidatedAmount = totalAssets;
            _loss = _amountNeeded - totalAssets;
        } else {
            // NOTE: Just in case something was stolen from this contract
            if (totalDebt > totalAssets) {
                _loss = totalDebt - totalAssets;
                if (_loss > _amountNeeded) _loss = _amountNeeded;
            }
            _liquidatedAmount = _amountNeeded;
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        // Nothing needed here because no additional tokens/tokenized positions for mock
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](1);
        protected[0] = protectedToken;
        return protected;
    }

    function liquidateAllPositions()
        internal
        override
        returns (uint256 amountFreed)
    {
        uint256 totalAssets = want.balanceOf(address(this));
        amountFreed = totalAssets;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("TOKEN", "TKN") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {StrategyParams, IOnChainVault} from "./interfaces/IOnChainVault.sol";
import {IBaseStrategy} from "./interfaces/IBaseStrategy.sol";

contract OnChainVault is
    Initializable,
    ERC20Upgradeable,
    IOnChainVault,
    OwnableUpgradeable
{
    uint256 public constant SECS_PER_YEAR = 31_556_952;
    uint256 public constant MAX_BPS = 10_000;
    uint256 public constant DEGRADATION_COEFFICIENT = 10 ** 18;
    uint256 public constant lockedProfitDegradation =
        (DEGRADATION_COEFFICIENT * 46) / 10 ** 6;
    uint256 public lockedProfit;
    uint256 public lastReport;
    address public override governance;
    address public treasury;
    IERC20 public override token;
    uint256 public depositLimit;
    uint256 public totalDebtRatio;
    uint256 public totalDebt;
    uint256 public managementFee;
    uint256 public performanceFee;
    address public management;
    bool public emergencyShutdown;

    bool public isInjectedOnce;
    uint256 public injectedTotalSupply;
    uint256 public injectedFreeFunds;

    mapping(address => StrategyParams) public strategies;
    mapping(address strategy => uint256 position)
        public strategyPositionInArray;

    address[] public OnChainStrategies;

    using SafeERC20 for IERC20;
    using SafeERC20 for ERC20;

    function initialize(
        IERC20 _token,
        address _governance,
        address _treasury,
        string calldata name,
        string calldata symbol
    ) external initializer {
        __Ownable_init();
        __ERC20_init(name, symbol);

        governance = _governance;
        token = _token;
        treasury = _treasury;
        approve(treasury, type(uint256).max);
    }

    modifier onlyAuthorized() {
        if (
            msg.sender != governance &&
            msg.sender != owner() &&
            msg.sender != management
        ) revert Vault__OnlyAuthorized(msg.sender);
        _;
    }

    function injectForMigration(
        uint256 _injectedTotalSupply,
        uint256 _injectedFreeFunds
    ) external onlyAuthorized {
        if (!isInjectedOnce) {
            injectedTotalSupply = _injectedTotalSupply;
            injectedFreeFunds = _injectedFreeFunds;
            isInjectedOnce = true;
        } else {
            revert("Cannot inject twice.");
        }
    }

    function totalSupply() public view override returns (uint256) {
        if (injectedTotalSupply > 0) {
            return injectedTotalSupply;
        }
        return super.totalSupply();
    }

    modifier checkAmountOnDeposit(uint256 amount) {
        if (amount + totalAssets() > depositLimit || amount == 0) {
            revert Vault__AmountIsIncorrect(amount);
        }
        _;
    }

    function decimals() public view virtual override returns (uint8) {
        return ERC20(address(token)).decimals();
    }

    function revokeFunds() external onlyAuthorized {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setEmergencyShutdown(
        bool _emergencyShutdown
    ) external onlyAuthorized {
        emergencyShutdown = _emergencyShutdown;
    }

    function setTreasury(address _newTreasuryAddress) external onlyAuthorized {
        treasury = _newTreasuryAddress;
    }

    function setDepositLimit(uint256 _limit) external onlyAuthorized {
        depositLimit = _limit;
    }

    //!Tests are not working with this implementation of PPS
    function totalAssets() public view returns (uint256 _assets) {
        for (uint256 i = 0; i < OnChainStrategies.length; i++) {
            _assets += IBaseStrategy(OnChainStrategies[i])
                .estimatedTotalAssets();
        }
        _assets += totalIdle();
        // _assets += totalIdle() + totalDebt;
    }

    function setPerformanceFee(uint256 fee) external onlyAuthorized {
        if (fee > MAX_BPS / 2) revert Vault__UnAcceptableFee();
        performanceFee = fee;
    }

    function setManagementFee(uint256 fee) external onlyAuthorized {
        if (fee > MAX_BPS) revert Vault__UnAcceptableFee();
        managementFee = fee;
    }

    function setManagement(address _management) external onlyAuthorized {
        management = _management;
    }

    function totalIdle() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function updateStrategyMinDebtPerHarvest(
        address strategy,
        uint256 _minDebtPerHarvest
    ) external onlyAuthorized {
        if (strategies[strategy].activation == 0)
            revert Vault__InactiveStrategy();
        if (strategies[strategy].maxDebtPerHarvest <= _minDebtPerHarvest)
            revert Vault__MinMaxDebtError();
        strategies[strategy].minDebtPerHarvest = _minDebtPerHarvest;
    }

    function updateStrategyMaxDebtPerHarvest(
        address strategy,
        uint256 _maxDebtPerHarvest
    ) external onlyAuthorized {
        if (strategies[strategy].activation == 0)
            revert Vault__InactiveStrategy();
        if (strategies[strategy].minDebtPerHarvest >= _maxDebtPerHarvest)
            revert Vault__MinMaxDebtError();
        strategies[strategy].maxDebtPerHarvest = _maxDebtPerHarvest;
    }

    function deposit(
        uint256 _amount,
        address _recipient
    ) external checkAmountOnDeposit(_amount) returns (uint256) {
        return _deposit(_amount, _recipient);
    }

    function deposit(
        uint256 _amount
    ) external checkAmountOnDeposit(_amount) returns (uint256) {
        return _deposit(_amount, msg.sender);
    }

    function withdraw(
        uint256 _maxShares,
        address _recipient,
        uint256 _maxLoss
    ) external {
        _initiateWithdraw(_maxShares, _recipient, _maxLoss);
    }

    function addStrategy(
        address _strategy,
        uint256 _debtRatio,
        uint256 _performanceFee,
        uint256 _minDebtPerHarvest,
        uint256 _maxDebtPerHarvest
    ) external onlyAuthorized {
        if (strategies[_strategy].activation != 0) revert Vault__V2();
        if (totalDebtRatio + _debtRatio > MAX_BPS) revert Vault__V3();
        if (_performanceFee > MAX_BPS / 2) revert Vault__UnAcceptableFee();
        if (_minDebtPerHarvest > _maxDebtPerHarvest)
            revert Vault__MinMaxDebtError();
        strategies[_strategy] = StrategyParams({
            performanceFee: _performanceFee,
            activation: block.timestamp,
            debtRatio: _debtRatio,
            minDebtPerHarvest: _minDebtPerHarvest,
            maxDebtPerHarvest: _maxDebtPerHarvest,
            lastReport: 0,
            totalDebt: 0,
            totalGain: 0,
            totalLoss: 0
        });

        totalDebtRatio += _debtRatio;
        strategyPositionInArray[_strategy] = OnChainStrategies.length;
        OnChainStrategies.push(_strategy);
    }

    function debtOutstanding(
        address _strategy
    ) external view returns (uint256) {
        return _debtOutstanding(_strategy);
    }

    function debtOutstanding() external view returns (uint256) {
        return _debtOutstanding(msg.sender);
    }

    function creditAvailable(
        address _strategy
    ) external view returns (uint256) {
        return _creditAvailable(_strategy);
    }

    function _initiateWithdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) internal returns (uint256) {
        uint256 shares = maxShares;
        if (maxLoss > MAX_BPS) revert Vault__V4();
        if (shares == type(uint256).max) {
            shares = balanceOf(msg.sender);
        }
        if (shares > balanceOf(msg.sender)) revert Vault__NotEnoughShares();
        if (shares == 0) revert Vault__ZeroToWithdraw();

        uint256 value = _shareValue(shares);
        uint256 vaultBalance = totalIdle();
        if (value > vaultBalance) {
            uint256 totalLoss;
            for (uint256 i = 0; i < OnChainStrategies.length; i++) {
                if (value <= vaultBalance) {
                    break;
                }
                uint256 amountNeeded = value - vaultBalance;
                amountNeeded = Math.min(
                    amountNeeded,
                    // IBaseStrategy(OnChainStrategies[i]).estimatedTotalAssets()
                    strategies[OnChainStrategies[i]].totalDebt
                );
                if (amountNeeded == 0) {
                    continue;
                }
                uint256 balanceBefore = token.balanceOf(address(this));
                uint256 loss = IBaseStrategy(OnChainStrategies[i]).withdraw(
                    amountNeeded
                );
                uint256 withdrawn = token.balanceOf(address(this)) -
                    balanceBefore;
                vaultBalance += withdrawn;
                if (loss > 0) {
                    value -= loss;
                    totalLoss += loss;
                    _reportLoss(OnChainStrategies[i], loss);
                }
                strategies[OnChainStrategies[i]].totalDebt -= withdrawn;
                totalDebt -= withdrawn;
                emit StrategyWithdrawnSome(
                    OnChainStrategies[i],
                    strategies[OnChainStrategies[i]].totalDebt,
                    loss
                );
            }
            if (value > vaultBalance) {
                value = vaultBalance;
                shares = _sharesForAmount(value + totalLoss);
                require(
                    shares < balanceOf(msg.sender),
                    "shares amount to burn grater than balance of user"
                );
            }
            if (totalLoss > (maxLoss * (value + totalLoss)) / MAX_BPS)
                revert Vault__UnacceptableLoss();
        }

        _burn(msg.sender, shares);
        token.safeTransfer(recipient, value);
        emit Withdraw(recipient, shares, value);
        return value;
    }

    function pricePerShare() external view returns (uint256) {
        return _shareValue(10 ** decimals());
    }

    function revokeStrategy(address _strategy) external onlyAuthorized {
        _revokeStrategy(_strategy);
    }

    function revokeStrategy() external {
        require(
            msg.sender == governance ||
                msg.sender == owner() ||
                msg.sender ==
                OnChainStrategies[strategyPositionInArray[msg.sender]],
            "notAuthorized"
        );
        _revokeStrategy(msg.sender);
    }

    function updateStrategyDebtRatio(
        address _strategy,
        uint256 _debtRatio
    ) external onlyAuthorized {
        if (strategies[_strategy].activation == 0)
            revert Vault__InactiveStrategy();

        totalDebtRatio -= strategies[_strategy].debtRatio;
        strategies[_strategy].debtRatio = _debtRatio;
        if (totalDebtRatio + _debtRatio > MAX_BPS) revert Vault__V6();
        totalDebtRatio += _debtRatio;
    }

    function migrateStrategy(
        address _oldStrategy,
        address _newStrategy
    ) external onlyAuthorized {
        if (_newStrategy == address(0)) revert Vault__V7();
        if (strategies[_oldStrategy].activation == 0) revert Vault__V8();
        if (strategies[_newStrategy].activation > 0) revert Vault__V9();
        StrategyParams memory params = strategies[_oldStrategy];
        _revokeStrategy(_oldStrategy);
        totalDebtRatio += params.debtRatio;

        strategies[_newStrategy] = StrategyParams({
            performanceFee: params.performanceFee,
            activation: params.lastReport,
            debtRatio: params.debtRatio,
            minDebtPerHarvest: params.minDebtPerHarvest,
            maxDebtPerHarvest: params.maxDebtPerHarvest,
            lastReport: params.lastReport,
            totalDebt: params.totalDebt,
            totalGain: 0,
            totalLoss: 0
        });
        strategies[_oldStrategy].totalDebt = 0;

        IBaseStrategy(_oldStrategy).migrate(_newStrategy);
        OnChainStrategies[strategyPositionInArray[_oldStrategy]] = _newStrategy;
        strategyPositionInArray[_newStrategy] = strategyPositionInArray[
            _oldStrategy
        ];
        strategyPositionInArray[_oldStrategy] = 0;
    }

    function _deposit(
        uint256 _amount,
        address _recipient
    ) internal returns (uint256) {
        if (emergencyShutdown) revert Vault__V13();
        uint256 shares = _issueSharesForAmount(_recipient, _amount);
        token.safeTransferFrom(msg.sender, address(this), _amount);
        return shares;
    }

    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256) {
        if (strategies[msg.sender].activation == 0) revert Vault__V14();

        if (_loss > 0) {
            _reportLoss(msg.sender, _loss);
        }
        uint256 totalFees = _assessFees(msg.sender, _gain);
        strategies[msg.sender].totalGain += _gain;
        uint256 credit = _creditAvailable(msg.sender);

        uint256 debt = _debtOutstanding(msg.sender);
        uint256 debtPayment = Math.min(debt, _debtPayment);

        if (debtPayment > 0) {
            strategies[msg.sender].totalDebt -= debtPayment;
            totalDebt -= debtPayment;
            debt -= debtPayment;
        }

        if (credit > 0) {
            strategies[msg.sender].totalDebt += credit;
            totalDebt += credit;
        }

        uint256 totalAvail = _gain + debtPayment;
        if (totalAvail < credit) {
            token.safeTransfer(msg.sender, credit - totalAvail);
        } else if (totalAvail > credit) {
            token.safeTransferFrom(
                msg.sender,
                address(this),
                totalAvail - credit
            );
        }

        uint256 lockedProfitBeforeLoss = _calculateLockedProfit() +
            _gain -
            totalFees;
        if (lockedProfitBeforeLoss > _loss) {
            lockedProfit = lockedProfitBeforeLoss - _loss;
        } else {
            lockedProfit = 0;
        }

        strategies[msg.sender].lastReport = block.timestamp;
        lastReport = block.timestamp;

        StrategyParams memory params = strategies[msg.sender];
        emit StrategyReported(
            msg.sender,
            _gain,
            _loss,
            _debtPayment,
            params.totalGain,
            params.totalLoss,
            params.totalDebt,
            credit,
            params.debtRatio
        );
        if (strategies[msg.sender].debtRatio == 0 || emergencyShutdown) {
            return IBaseStrategy(msg.sender).estimatedTotalAssets();
        } else {
            return debt;
        }
    }

    function _calculateLockedProfit() internal view returns (uint256) {
        uint256 lockedFundsRatio = (block.timestamp - lastReport) *
            lockedProfitDegradation;
        if (lockedFundsRatio < DEGRADATION_COEFFICIENT) {
            uint256 _lockedProfit = lockedProfit;
            return
                _lockedProfit -
                ((lockedFundsRatio * _lockedProfit) / DEGRADATION_COEFFICIENT);
        } else {
            return 0;
        }
    }

    function _reportLoss(address _strategy, uint256 _loss) internal {
        if (strategies[_strategy].totalDebt < _loss) revert Vault__V15();

        if (totalDebtRatio != 0) {
            uint256 ratioChange = Math.min(
                (_loss * totalDebtRatio) / totalDebt,
                strategies[_strategy].debtRatio
            );
            strategies[_strategy].debtRatio -= ratioChange;
            totalDebtRatio -= ratioChange;
        }
        strategies[_strategy].totalLoss += _loss;
        strategies[_strategy].totalDebt -= _loss;
        totalDebt -= _loss;
    }

    function _freeFunds() internal view returns (uint256) {
        if (injectedFreeFunds > 0) {
            return injectedFreeFunds;
        }
        return totalAssets() - _calculateLockedProfit();
    }

    function _shareValue(uint256 _shares) internal view returns (uint256) {
        if (totalSupply() == 0) {
            return _shares;
        }
        return (_shares * _freeFunds()) / totalSupply();
    }

    function _sharesForAmount(uint256 amount) internal view returns (uint256) {
        uint256 _freeFund = _freeFunds();
        if (_freeFund > 0) {
            return ((amount * totalSupply()) / _freeFund);
        } else {
            return 0;
        }
    }

    function maxAvailableShares() external view returns (uint256) {
        uint256 shares = _sharesForAmount(totalIdle());
        for (uint256 i = 0; i < OnChainStrategies.length; i++) {
            shares += _sharesForAmount(
                strategies[OnChainStrategies[i]].totalDebt
            );
        }
        return shares;
    }

    function _issueSharesForAmount(
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 shares = 0;
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * _totalSupply) / _freeFunds();
            if (injectedTotalSupply > 0) {
                injectedTotalSupply = 0;
            }
            if (injectedFreeFunds > 0) {
                injectedFreeFunds = 0;
            }
        }
        if (shares == 0) revert Vault__V17();
        _mint(_to, shares);
        return shares;
    }

    function _revokeStrategy(address _strategy) internal {
        totalDebtRatio -= strategies[_strategy].debtRatio;
        strategies[_strategy].debtRatio = 0;
    }

    function _creditAvailable(
        address _strategy
    ) internal view returns (uint256) {
        if (emergencyShutdown) {
            return 0;
        }
        uint256 strategyDebtLimit = (strategies[_strategy].debtRatio *
            totalAssets()) / MAX_BPS;
        uint256 strategyTotalDebt = strategies[_strategy].totalDebt;

        uint256 vaultDebtLimit = (totalDebtRatio * totalAssets()) / MAX_BPS;
        uint256 vaultTotalDebt = totalDebt;

        if (
            strategyDebtLimit <= strategyTotalDebt ||
            vaultDebtLimit <= totalDebt
        ) {
            return 0;
        }
        uint256 available = strategyDebtLimit - strategyTotalDebt;
        available = Math.min(available, vaultDebtLimit - vaultTotalDebt);
        return Math.min(totalIdle(), available);
    }

    function _debtOutstanding(
        address _strategy
    ) internal view returns (uint256) {
        if (totalDebtRatio == 0) {
            return strategies[_strategy].totalDebt;
        }
        uint256 strategyDebtLimit = (strategies[_strategy].debtRatio *
            totalAssets()) / MAX_BPS;
        uint256 strategyTotalDebt = strategies[_strategy].totalDebt;

        if (emergencyShutdown) {
            return strategyTotalDebt;
        } else if (strategyTotalDebt <= strategyDebtLimit) {
            return 0;
        } else {
            return strategyTotalDebt - strategyDebtLimit;
        }
    }

    function _assessFees(
        address strategy,
        uint256 gain
    ) internal returns (uint256) {
        if (strategies[strategy].activation == block.timestamp) {
            return 0;
        }

        uint256 duration = block.timestamp - strategies[strategy].lastReport;

        require(duration != 0, "can't assessFees twice within the same block");

        if (gain == 0) {
            return 0;
        }

        uint256 _managementFee = ((strategies[strategy].totalDebt -
            IBaseStrategy(strategy).delegatedAssets()) *
            duration *
            managementFee) /
            MAX_BPS /
            SECS_PER_YEAR;
        uint256 _strategistFee = (gain * strategies[strategy].performanceFee) /
            MAX_BPS;
        uint256 _performanceFee = (gain * performanceFee) / MAX_BPS;
        uint256 totalFee = _managementFee + _strategistFee + _performanceFee;
        if (totalFee > gain) {
            totalFee = gain;
        }
        if (totalFee > 0) {
            uint256 reward = _issueSharesForAmount(address(this), totalFee);
            if (_strategistFee > 0) {
                uint256 strategistReward = (_strategistFee * reward) / totalFee;
                _transfer(address(this), treasury, strategistReward);
            }
            if (balanceOf(address(this)) > 0) {
                _transfer(address(this), treasury, balanceOf(address(this)));
            }
        }
        return totalFee;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {BaseStrategy, StrategyParams, VaultAPI} from "@yearn-protocol/contracts/BaseStrategy.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "../utils/Utils.sol";
import "../integrations/across/IAcrossHub.sol";
import "../integrations/across/IAcrossStaker.sol";

contract AcrossStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    address public constant ACROSS_HUB = 0xc186fA914353c44b2E33eBE05f21846F1048bEda;
    address public constant ACROSS_STAKER = 0x9040e41eF5E8b281535a96D9a48aCb8cfaBD9a48;
    address public constant LP_TOKEN = 0x28F77208728B0A45cAb24c4868334581Fe86F95B;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant REWARD_TOKEN = 0x44108f0223A3C3028F5Fe7AEC7f9bb2E66beF82F;
    address public constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant ACX_WETH_UNI_POOL = 0x508acdC358be2ed126B1441F0Cff853dEc49d40F;

    uint32 internal constant TWAP_RANGE_SECS = 1800;
    uint256 public slippage;

    uint256 private WANT_DECIMALS;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(address _vault, address _strategist) external {
        _initialize(_vault, _strategist, _strategist, _strategist);

        want.safeApprove(ACROSS_HUB, type(uint256).max);
        IERC20(LP_TOKEN).safeApprove(ACROSS_STAKER, type(uint256).max);
        IERC20(LP_TOKEN).safeApprove(ACROSS_HUB, type(uint256).max);
        WANT_DECIMALS = ERC20(address(want)).decimals();
        IERC20(REWARD_TOKEN).safeApprove(UNISWAP_V3_ROUTER, type(uint256).max);
        slippage = 9800; // 2%
    }

    function ethToWant(uint256 _amtInWei) public view virtual override returns (uint256){
        return 0;
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    function name() external pure override returns (string memory) {
        return "AcrossStrategy WETH";
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfLPUnstaked() public view returns (uint256) {
        return ERC20(LP_TOKEN).balanceOf(address(this));
    }

    function balanceOfLPStaked() public view returns (uint256) {
        return
            IAcrossStaker(ACROSS_STAKER).getUserStake(LP_TOKEN, address(this)).cumulativeBalance;
    }

    function getRewards() public view virtual returns (uint256) {
        return IAcrossStaker(ACROSS_STAKER).getOutstandingRewards(LP_TOKEN, address(this));
    }

    function LPToWant(uint256 _lpTokens) public view returns (uint256) {
        return _lpTokens * _exchangeRate() / 1e18;
    }

    function wantToLp(uint256 _wantAmount) public view returns(uint256){
       return (_wantAmount * 1e18) / _exchangeRate();
    }

    function _withdrawSome(uint256 _amountNeeded) internal {
        if (_amountNeeded == 0) {
            return;
        }
        
            uint256 lpTokensToWithdraw = Math.min(
                wantToLp(_amountNeeded),
                balanceOfLPStaked()
            );
            _exitPosition(lpTokensToWithdraw);
        
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256 _wants)
    {
        _wants += want.balanceOf(address(this));
        _wants += LPToWant(IAcrossStaker(ACROSS_STAKER).getUserStake(LP_TOKEN, address(this)).cumulativeBalance);
        _wants += AcxToWant(IAcrossStaker(ACROSS_STAKER).getOutstandingRewards(WETH, address(this)));
        _wants += LPToWant(IERC20(LP_TOKEN).balanceOf(address(this)));
        // console.log(want.balanceOf(address(this)));
        // console.log(IAcrossStaker(ACROSS_STAKER).getUserStake(WETH, address(this)).cumulativeBalance);
        // console.log(IAcrossStaker(ACROSS_STAKER).getOutstandingRewards(WETH, address(this)));
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;

        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }
        uint256 _liquidWant = balanceOfWant();
        uint256 _amountNeeded = _debtOutstanding + _profit;
        if (_liquidWant <= _amountNeeded) {
            _withdrawSome(_amountNeeded - _liquidWant);
            _liquidWant = balanceOfWant();
        }
        // enough to pay profit (partial or full) only
        if (_liquidWant <= _profit) {
            _profit = _liquidWant;
            _debtPayment = 0;
            // enough to pay for all profit and _debtOutstanding (partial or full)
        } else {
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function _exchangeRate() internal view returns(uint256){
        IAcrossHub.PooledToken memory pooledToken = IAcrossHub(ACROSS_HUB).pooledTokens(WETH); // Note this is storage so the state can be modified.
        uint256 lpTokenTotalSupply = IERC20(pooledToken.lpToken).totalSupply();
        int256 numerator = int256(pooledToken.liquidReserves) +
            pooledToken.utilizedReserves -
            int256(pooledToken.undistributedLpFees);
        return (uint256(numerator) * 1e18) / lpTokenTotalSupply;
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }

        uint256 _wantBal = balanceOfWant();
        uint256 _excessWant = 0;
        if (_wantBal > _debtOutstanding) {
            _excessWant = _wantBal - _debtOutstanding;
        }

        if (_excessWant > 0) {
            IAcrossHub(ACROSS_HUB).addLiquidity(WETH, _excessWant);

        }
        if (balanceOfLPUnstaked() > 0) {
            IAcrossStaker(ACROSS_STAKER).stake(LP_TOKEN, IERC20(LP_TOKEN).balanceOf(address(this)));
        }
    }

    function smthToSmth(
        address pool,
        address tokenFrom,
        address tokenTo,
        uint256 amount
    ) internal view returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(pool, TWAP_RANGE_SECS);
        return
            OracleLibrary.getQuoteAtTick(
                meanTick,
                uint128(amount),
                tokenFrom,
                tokenTo
            );
    }

    function AcxToWant(
        uint256 amountIn
    ) internal view returns (uint256 amountOut) {
        if (amountIn == 0) {
            return 0;
        }
        amountOut = smthToSmth(
            ACX_WETH_UNI_POOL,
            REWARD_TOKEN,
            WETH,
            amountIn
        );
    }

    function claimAndSell() external onlyStrategist{
        IAcrossStaker(ACROSS_STAKER).withdrawReward(LP_TOKEN);
        ISwapRouter.ExactInputSingleParams memory params;
        params.tokenIn = REWARD_TOKEN;
        params.tokenOut = WETH;
        params.fee = 10000;
        params.recipient = address(this);
        params.deadline = block.timestamp;
        params.amountIn = IERC20(REWARD_TOKEN).balanceOf(address(this));
        params.amountOutMinimum = AcxToWant(IERC20(REWARD_TOKEN).balanceOf(address(this))) * slippage / 10000;
        params.sqrtPriceLimitX96 = 0;
        ISwapRouter(UNISWAP_V3_ROUTER).exactInputSingle(params);
    }

    function _exitPosition(uint256 _stakedLpTokens) internal {
        IAcrossStaker(ACROSS_STAKER).unstake(
            LP_TOKEN,
            _stakedLpTokens
        );

        uint256 lpTokens = ERC20(LP_TOKEN).balanceOf(address(this));
        // uint256 withdrawAmount = IAcrossHub(ACROSS_HUB).exchangeRateCurrent(WETH) * balanceOfLPUnstaked() / 1e18;

        IAcrossHub(ACROSS_HUB).removeLiquidity(WETH, _stakedLpTokens, false);
        
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(balanceOfLPStaked());
        return want.balanceOf(address(this));
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal >= _amountNeeded) {
            return (_amountNeeded, 0);
        }

        _withdrawSome(_amountNeeded - _wantBal);
        _wantBal = want.balanceOf(address(this));

        if (_amountNeeded > _wantBal) {
            _liquidatedAmount = _wantBal;
            _loss = _amountNeeded - _wantBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        IAcrossStaker(ACROSS_STAKER).unstake(
            LP_TOKEN,
            balanceOfLPStaked()
        );
        IERC20(LP_TOKEN).safeTransfer(
            _newStrategy,
            IERC20(LP_TOKEN).balanceOf(address(this))
        );
    }

    function protectedTokens()
        internal
        pure
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](3);
        protected[0] = LP_TOKEN;
        protected[1] = WETH;
        return protected;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {BaseStrategy, StrategyParams, VaultAPI} from "@yearn-protocol/contracts/BaseStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../integrations/velo/IVeloRouter.sol";
import "../integrations/velo/IVeloGauge.sol";

contract AeroStrategy is BaseStrategy, Initializable {
    using SafeERC20 for IERC20;

    address internal constant AERO_ROUTER =
        0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43;
    address internal constant AERO_GAUGE =
        0xCF1D5Aa63083fda05c7f8871a9fDbfed7bA49060;
    address internal constant USDbC =
        0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA;
    address internal constant DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
    address internal constant LP = 0x6EAB8c1B93f5799daDf2C687a30230a540DbD636;
    address internal constant AERO = 0x940181a94A35A4569E4529A3CDfB74e38FD98631;

    address internal constant WETH = 0x4200000000000000000000000000000000000006;

    address internal constant POOL_FACTORY =
        0x420DD381b31aEf6683db6B902084cB0FFECe40Da;

    uint256 internal constant slippage = 9000;
    uint256 internal constant USDbC_PROTOCOL_FEE = 100;
    address internal constant UNISWAP_V3_ROUTER =
        0x2626664c2603336E57B271c5C0b26F421741e481;

    function ethToWant(
        uint256 ethAmount
    ) public view override returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            0x3B8000CD10625ABdC7370fb47eD4D4a9C6311fD5,
            1800
        );
        return
            OracleLibrary.getQuoteAtTick(
                meanTick,
                uint128(ethAmount),
                WETH,
                address(want)
            );
    }

    constructor(address _vault) BaseStrategy(_vault) {}

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;
        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }

        uint256 _liquidWant = want.balanceOf(address(this));
        uint256 _amountNeeded = _debtOutstanding + _profit;
        if (_liquidWant <= _amountNeeded) {
            _withdrawSome(_amountNeeded - _liquidWant);
            _liquidWant = want.balanceOf(address(this));
        }

        if (_liquidWant <= _profit) {
            // enough to pay profit (partial or full) only
            _profit = _liquidWant;
            _debtPayment = 0;
        } else {
            // enough to pay for all profit and _debtOutstanding (partial or full)
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function protectedTokens()
        internal
        pure
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](3);
        // protected[0] = GNS;
        // protected[1] = DAI;
        // protected[2] = WETH;
        return protected;
    }

    function initialize(
        address _vault,
        address _strategist
    ) public initializer {
        _initialize(_vault, _strategist, _strategist, _strategist);
        IERC20(USDbC).safeApprove(AERO_ROUTER, type(uint256).max);
        IERC20(LP).safeApprove(AERO_GAUGE, type(uint256).max);
        IERC20(LP).safeApprove(AERO_ROUTER, type(uint256).max);
        IERC20(AERO).safeApprove(AERO_ROUTER, type(uint256).max);
        IERC20(DAI).safeApprove(AERO_ROUTER, type(uint256).max);
        IERC20(USDbC).safeApprove(UNISWAP_V3_ROUTER, type(uint256).max);
    }

    function name() external pure override returns (string memory) {
        return "Aerodrome USDbC/DAI Strategy";
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(USDbC).balanceOf(address(this));
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        return
            LpToWant(balanceOfStaked()) +
            balanceOfWant() +
            AeroToWant(getRewards());
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }
        _claimAndSellRewards();
        uint256 unstakedBalance = balanceOfWant();

        uint256 excessWant;
        if (unstakedBalance > _debtOutstanding) {
            excessWant = unstakedBalance - _debtOutstanding;
        }
        if (excessWant > 0) {
            IVeloRouter.Route memory route;
            route.from = USDbC;
            route.to = DAI;
            route.stable = true;
            route.factory = POOL_FACTORY;
            (uint256 usdcAmount, uint256 daiAmount) = _calculateTokenAmounts(
                excessWant
            );
            _swapWantToDai(daiAmount);
            uint256 minAmountA = (usdcAmount * slippage) / 10000;
            uint256 minAmountB = ((daiAmount) * slippage) / 10000;
            IVeloRouter(AERO_ROUTER).addLiquidity(
                USDbC,
                DAI,
                true,
                usdcAmount,
                IERC20(DAI).balanceOf(address(this)),
                minAmountA,
                minAmountB,
                address(this),
                block.timestamp
            );
            uint256 lpBalance = IERC20(LP).balanceOf(address(this));
            IVeloGauge(AERO_GAUGE).deposit(lpBalance);
        }
    }

    function _calculateTokenAmounts(
        uint256 excessWant
    ) internal view returns (uint256 amountA, uint256 amountB) {
        (uint256 desiredA, uint256 desiredB, ) = IVeloRouter(AERO_ROUTER)
            .quoteAddLiquidity(
                USDbC,
                DAI,
                true,
                POOL_FACTORY,
                excessWant / 2,
                (excessWant * 10 ** 12) / 2
            );
        desiredB = desiredB / 10 ** 12;
        uint256 sum = desiredB + desiredA;
        amountA = (excessWant * desiredA) / sum;
        amountB = excessWant - amountA;
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal >= _amountNeeded) {
            return (_amountNeeded, 0);
        }
        _withdrawSome(_amountNeeded - _wantBal);
        _wantBal = want.balanceOf(address(this));

        if (_amountNeeded > _wantBal) {
            _liquidatedAmount = _wantBal;
            _loss = _amountNeeded - _wantBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function _quoteMinAmountsRemove(
        uint256 amountLp
    ) internal view returns (uint256 minAmountA, uint256 minAmountB) {
        (minAmountA, minAmountB) = IVeloRouter(AERO_ROUTER)
            .quoteRemoveLiquidity(USDbC, DAI, true, POOL_FACTORY, amountLp);
        minAmountA = (minAmountA * slippage) / 10000;
        minAmountB = (minAmountB * slippage) / 10000;
    }

    function liquidateAllPositions()
        internal
        override
        returns (uint256 _amountFreed)
    {
        _claimAndSellRewards();

        uint256 stakedAmount = balanceOfStaked();
        IVeloGauge(AERO_GAUGE).withdraw(stakedAmount);
        (uint256 minAmountA, uint256 minAmountB) = _quoteMinAmountsRemove(
            stakedAmount
        );
        IVeloRouter(AERO_ROUTER).removeLiquidity(
            USDbC,
            DAI,
            true,
            stakedAmount,
            minAmountA,
            minAmountB,
            address(this),
            block.timestamp
        );
        _swapDaiToWant(IERC20(DAI).balanceOf(address(this)));
        _amountFreed = want.balanceOf(address(this));
    }

    function prepareMigration(address _newStrategy) internal override {
        uint256 assets = liquidateAllPositions();
        want.safeTransfer(_newStrategy, assets);
    }

    function balanceOfStaked() public view returns (uint256 amount) {
        amount = IVeloGauge(AERO_GAUGE).balanceOf(address(this));
    }

    function getRewards() public view returns (uint256 amount) {
        amount = IVeloGauge(AERO_GAUGE).earned(address(this));
    }

    function LpToWant(
        uint256 amountIn
    ) public view returns (uint256 amountOut) {
        if (amountIn == 0) {
            return 0;
        }
        (uint256 amountOutA, uint256 AmountOutB) = IVeloRouter(AERO_ROUTER)
            .quoteRemoveLiquidity(USDbC, DAI, true, POOL_FACTORY, amountIn);
        amountOut = amountOutA + AmountOutB / 10 ** 12;
    }

    function AeroToWant(
        uint256 amountIn
    ) public view returns (uint256 amountOut) {
        IVeloRouter.Route[] memory route = new IVeloRouter.Route[](1);
        route[0].from = AERO;
        route[0].to = USDbC;
        route[0].stable = false;
        route[0].factory = POOL_FACTORY;
        amountOut = IVeloRouter(AERO_ROUTER).getAmountsOut(amountIn, route)[1];
    }

    function _swapWantToDai(uint256 amountToSell) internal {
        IVeloRouter.Route[] memory routes = new IVeloRouter.Route[](1);
        routes[0].from = USDbC;
        routes[0].to = DAI;
        routes[0].stable = true;
        routes[0].factory = POOL_FACTORY;
        uint256 amountOutMinimum = ((amountToSell * slippage) / 10000) *
            10 ** 12;
        (
            IVeloRouter(AERO_ROUTER).swapExactTokensForTokens(
                amountToSell,
                amountOutMinimum,
                routes,
                address(this),
                block.timestamp
            )
        );
    }

    function _swapDaiToWant(uint256 amountToSell) internal {
        IVeloRouter.Route[] memory routes = new IVeloRouter.Route[](1);
        routes[0].from = DAI;
        routes[0].to = USDbC;
        routes[0].stable = true;
        routes[0].factory = POOL_FACTORY;
        uint256 amountOutMinimum = (amountToSell * slippage) / 10000 / 10 ** 12;
        (
            IVeloRouter(AERO_ROUTER).swapExactTokensForTokens(
                amountToSell,
                amountOutMinimum,
                routes,
                address(this),
                block.timestamp
            )
        );
    }

    function _withdrawSome(uint256 _amountNeeded) internal {
        if (_amountNeeded == 0) {
            return;
        }
        if (AeroToWant(getRewards()) >= _amountNeeded) {
            _claimAndSellRewards();
        } else {
            uint256 _usdcToUnstake = Math.min(
                LpToWant(balanceOfStaked()),
                _amountNeeded - AeroToWant(getRewards())
            );
            _exitPosition(_usdcToUnstake);
        }
    }

    function _claimAndSellRewards() internal {
        IVeloGauge(AERO_GAUGE).getReward(address(this));
        _sellAeroForWant(IERC20(AERO).balanceOf(address(this)));
    }

    function _exitPosition(uint256 _stakedAmount) internal {
        _claimAndSellRewards();
        (uint256 usdcAmount, ) = _calculateTokenAmounts(_stakedAmount);
        uint256 amountLpToWithdraw = (usdcAmount * IERC20(LP).totalSupply()) /
            IERC20(USDbC).balanceOf(LP);
        if (amountLpToWithdraw > balanceOfStaked()) {
            amountLpToWithdraw = balanceOfStaked();
        }
        IVeloGauge(AERO_GAUGE).withdraw(amountLpToWithdraw);
        (uint256 minAmountA, uint256 minAmountB) = _quoteMinAmountsRemove(
            amountLpToWithdraw
        );
        IVeloRouter(AERO_ROUTER).removeLiquidity(
            USDbC,
            DAI,
            true,
            amountLpToWithdraw,
            minAmountA,
            minAmountB,
            address(this),
            block.timestamp
        );
        _swapDaiToWant(IERC20(DAI).balanceOf(address(this)));
    }

    function _sellAeroForWant(uint256 amountToSell) internal {
        if (amountToSell == 0) {
            return;
        }
        IVeloRouter.Route[] memory route = new IVeloRouter.Route[](1);
        route[0].from = AERO;
        route[0].to = USDbC;
        route[0].stable = false;
        route[0].factory = POOL_FACTORY;
        uint256 amountOutMinimum = (AeroToWant(amountToSell) * slippage) /
            10000;
        IVeloRouter(AERO_ROUTER).swapExactTokensForTokens(
            amountToSell,
            amountOutMinimum,
            route,
            address(this),
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.19;

import {BaseStrategy, StrategyParams, VaultAPI} from "@yearn-protocol/contracts/BaseStrategy.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import "../../integrations/uniswap/v3/IV3SwapRouter.sol";
import "../../integrations/gmd/IGMDStaking.sol";

import "../../utils/Utils.sol";

contract GMDStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    address internal constant GMD = 0x4945970EfeEc98D393b4b979b9bE265A3aE28A8B;
    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    uint256 internal constant GMD_PID = 0;
    address internal constant GMD_POOL =
        0x48C81451D1FDdecA84b47ff86F91708fa5c32e93;
    address internal constant UNISWAP_V3_ROUTER =
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    address internal constant ETH_USDC_UNI_V3_POOL =
        0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443;
    address internal constant GMD_ETH_UNI_V3_POOL =
        0x0632742C132413Cd47438691D8064Ff9214aC216;

    uint24 internal constant ETH_USDC_UNI_FEE = 500;
    uint24 internal constant GMD_ETH_UNI_FEE = 3000;

    uint32 internal constant TWAP_RANGE_SECS = 1800;

    uint256 public slippage;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(address _vault, address _strategist) external {
        _initialize(_vault, _strategist, _strategist, _strategist);
        want.safeApprove(UNISWAP_V3_ROUTER, type(uint256).max);
        IERC20(WETH).safeApprove(UNISWAP_V3_ROUTER, type(uint256).max);
        IERC20(GMD).safeApprove(UNISWAP_V3_ROUTER, type(uint256).max);
        IERC20(GMD).safeApprove(GMD_POOL, type(uint256).max);

        slippage = 9700; // 3%
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    function name() external pure override returns (string memory) {
        return "StrategyGMD";
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfWeth() public view returns (uint256) {
        return IERC20(WETH).balanceOf(address(this));
    }

    function balanceOfGmd() public view returns (uint256) {
        return IERC20(GMD).balanceOf(address(this));
    }

    function balanceOfStakedGmd() public view returns (uint256) {
        (, uint256 amount, , ) = IGMDStaking(GMD_POOL).userInfo(
            GMD_PID,
            address(this)
        );
        return amount;
    }

    function balanceOfRewards() public view returns (uint256) {
        return IGMDStaking(GMD_POOL).pendingWETH(GMD_PID, address(this));
    }

    function _withdrawSome(uint256 _amountNeeded) internal {
        if (_amountNeeded == 0) return;

        uint256 rewardsTotal = ethToWant(balanceOfRewards());
        if (rewardsTotal >= _amountNeeded) {
            _sellRewards();
            return;
        }

        uint256 gmdToUnstake = Math.min(
            balanceOfStakedGmd(),
            wantToGmd(_amountNeeded - rewardsTotal)
        );

        _exitPosition(gmdToUnstake);
    }

    function _sellRewards() internal {
        // the only way to get rewards from MasterChef is deposit or withdraw
        IGMDStaking(GMD_POOL).deposit(GMD_PID, 0);

        uint256 balWeth = IERC20(WETH).balanceOf(address(this));
        if (balWeth > 0) {
            uint256 minAmountOut = (ethToWant(balWeth) * slippage) / 10000;
            IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter
                .ExactInputSingleParams({
                    tokenIn: WETH,
                    tokenOut: address(want),
                    fee: ETH_USDC_UNI_FEE,
                    recipient: address(this),
                    amountIn: balWeth,
                    amountOutMinimum: minAmountOut,
                    sqrtPriceLimitX96: 0
                });
            IV3SwapRouter(UNISWAP_V3_ROUTER).exactInputSingle(params);
        }
    }

    function _exitPosition(uint256 gmdAmount) internal {
        _sellRewards();

        if (gmdAmount == 0) {
            return;
        }

        IGMDStaking(GMD_POOL).withdraw(GMD_PID, gmdAmount);

        uint256 minAmountOut = (gmdToWant(gmdAmount) * slippage) / 10000;
        IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter
            .ExactInputParams({
                path: abi.encodePacked(
                    GMD,
                    GMD_ETH_UNI_FEE,
                    WETH,
                    ETH_USDC_UNI_FEE,
                    address(want)
                ),
                recipient: address(this),
                amountIn: gmdAmount,
                amountOutMinimum: minAmountOut
            });
        IV3SwapRouter(UNISWAP_V3_ROUTER).exactInput(params);
    }

    function ethToWant(
        uint256 ethAmount
    ) public view override returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            ETH_USDC_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            OracleLibrary.getQuoteAtTick(
                meanTick,
                uint128(ethAmount),
                WETH,
                address(want)
            );
    }

    function wantToEth(uint256 wantAmount) public view returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            ETH_USDC_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            OracleLibrary.getQuoteAtTick(
                meanTick,
                uint128(wantAmount),
                address(want),
                WETH
            );
    }

    function gmdToWant(uint256 gmdAmount) public view returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            GMD_ETH_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            ethToWant(
                OracleLibrary.getQuoteAtTick(
                    meanTick,
                    uint128(gmdAmount),
                    GMD,
                    address(WETH)
                )
            );
    }

    function wantToGmd(uint256 wantAmount) public view returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            GMD_ETH_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            OracleLibrary.getQuoteAtTick(
                meanTick,
                uint128(wantToEth(wantAmount)),
                address(WETH),
                GMD
            );
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();
        _wants += gmdToWant(balanceOfGmd());
        _wants += gmdToWant(balanceOfStakedGmd());
        _wants += ethToWant(balanceOfWeth());
        _wants += ethToWant(balanceOfRewards());
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;

        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }

        uint256 _liquidWant = balanceOfWant();
        uint256 _amountNeeded = _debtOutstanding + _profit;
        if (_liquidWant <= _amountNeeded) {
            _withdrawSome(_amountNeeded - _liquidWant);
            _liquidWant = balanceOfWant();
        }

        if (_liquidWant <= _profit) {
            // enough to pay profit (partial or full) only
            _profit = _liquidWant;
            _debtPayment = 0;
        } else {
            // enough to pay for all profit and _debtOutstanding (partial or full)
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }

        _sellRewards();

        uint256 _wantBal = balanceOfWant();
        if (_wantBal > _debtOutstanding) {
            uint256 _excessWant = _wantBal - _debtOutstanding;
            uint256 minAmountOut = (wantToGmd(_excessWant) * slippage) / 10000;
            IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter
                .ExactInputParams({
                    path: abi.encodePacked(
                        address(want),
                        ETH_USDC_UNI_FEE,
                        WETH,
                        GMD_ETH_UNI_FEE,
                        GMD
                    ),
                    recipient: address(this),
                    amountIn: _excessWant,
                    amountOutMinimum: minAmountOut
                });
            IV3SwapRouter(UNISWAP_V3_ROUTER).exactInput(params);
        }

        uint256 gmdBal = balanceOfGmd();
        if (gmdBal > 0) {
            IGMDStaking(GMD_POOL).deposit(GMD_PID, gmdBal);
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(balanceOfStakedGmd());
        return want.balanceOf(address(this));
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wantBal = want.balanceOf(address(this));

        if (_wantBal >= _amountNeeded) {
            return (_amountNeeded, 0);
        }

        _withdrawSome(_amountNeeded - _wantBal);
        _wantBal = want.balanceOf(address(this));

        if (_amountNeeded > _wantBal) {
            _liquidatedAmount = _wantBal;
            _loss = _amountNeeded - _wantBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        IGMDStaking(GMD_POOL).withdraw(GMD_PID, balanceOfStakedGmd());
        IERC20(GMD).safeTransfer(_newStrategy, balanceOfGmd());
        IERC20(WETH).safeTransfer(_newStrategy, balanceOfWeth());
    }

    function protectedTokens()
        internal
        pure
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](2);
        protected[0] = GMD;
        protected[1] = WETH;
        return protected;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.19;

import {BaseStrategy, StrategyParams, VaultAPI} from "@yearn-protocol/contracts/BaseStrategy.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import "../../utils/Utils.sol";
import "../../integrations/gmx/IRewardRouterV2.sol";
import "../../integrations/gmx/IRewardTracker.sol";
import "../../integrations/uniswap/v3/IV3SwapRouter.sol";

contract GMXStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    address internal constant STAKED_GMX_TRACKER =
        0x908C4D94D34924765f1eDc22A1DD098397c59dD4;
    address internal constant FEE_GMX_TRACKER =
        0xd2D1162512F927a7e282Ef43a362659E4F2a728F;

    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address internal constant GMX = 0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;
    address internal constant ES_GMX =
        0xf42Ae1D54fd613C9bb14810b0588FaAa09a426cA;

    address internal constant GMX_REWARD_ROUTER =
        0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1;

    address internal constant UNISWAP_V3_ROUTER =
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    address internal constant ETH_USDC_UNI_V3_POOL =
        0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443;
    uint24 internal constant ETH_USDC_UNI_V3_FEE = 500;

    address internal constant ETH_GMX_UNI_V3_POOL =
        0x80A9ae39310abf666A87C743d6ebBD0E8C42158E;
    uint24 internal constant ETH_GMX_UNI_V3_FEE = 10000;

    uint32 internal constant TWAP_RANGE_SECS = 1800;
    uint256 public slippage;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(address _vault, address _strategist) external {
        _initialize(_vault, _strategist, _strategist, _strategist);

        IERC20(GMX).safeApprove(STAKED_GMX_TRACKER, type(uint256).max);
        IERC20(ES_GMX).safeApprove(STAKED_GMX_TRACKER, type(uint256).max);
        IERC20(WETH).safeApprove(UNISWAP_V3_ROUTER, type(uint256).max);
        IERC20(GMX).safeApprove(UNISWAP_V3_ROUTER, type(uint256).max);

        want.safeApprove(UNISWAP_V3_ROUTER, type(uint256).max);
        slippage = 9500; // 5%
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    function name() external pure override returns (string memory) {
        return "StrategyGMX";
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfUnstakedGmx() public view returns (uint256) {
        return ERC20(GMX).balanceOf(address(this));
    }

    function balanceOfWethRewards() public view returns (uint256) {
        return IRewardTracker(FEE_GMX_TRACKER).claimable(address(this));
    }

    function balanceOfStakedGmx() public view returns (uint256) {
        return
            IRewardTracker(STAKED_GMX_TRACKER).depositBalances(
                address(this),
                GMX
            );
    }

    function balanceOfUnstakedEsGmx() public view returns (uint256) {
        return ERC20(ES_GMX).balanceOf(address(this));
    }

    function balanceOfStakedEsGmx() public view returns (uint256) {
        return
            IRewardTracker(STAKED_GMX_TRACKER).depositBalances(
                address(this),
                ES_GMX
            );
    }

    function _claimWethRewards() internal {
        IRewardRouterV2(GMX_REWARD_ROUTER).handleRewards(
            /* _shouldClaimGmx= */ false,
            /* _shouldStakeGmx= */ false,
            /* _shouldClaimEsGmx= */ false,
            /* _shouldStakeEsGmx= */ false,
            /* _shouldStakeMultiplierPoints= */ false,
            /* _shouldClaimWeth= */ true,
            /* _shouldConvertWethToEth= */ false
        );
    }

    function _withdrawSome(uint256 _amountNeeded) internal {
        if (_amountNeeded == 0) {
            return;
        }

        uint256 _wethBalance = balanceOfWethRewards() +
            ERC20(WETH).balanceOf(address(this));
        if (ethToWant(_wethBalance) >= _amountNeeded) {
            _claimWethRewards();
            _sellWethForWant();
        } else {
            uint256 _gmxToWithdraw = Math.min(
                wantToGmx(_amountNeeded - ethToWant(_wethBalance)),
                balanceOfStakedGmx()
            );
            _exitPosition(_gmxToWithdraw);
        }
    }

    function _sellWethForWant() internal {
        uint256 _wethBalance = ERC20(WETH).balanceOf(address(this));
        if (_wethBalance == 0) {
            return;
        }

        IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter
            .ExactInputParams({
                path: abi.encodePacked(
                    WETH,
                    ETH_USDC_UNI_V3_FEE,
                    address(want)
                ),
                recipient: address(this),
                amountIn: _wethBalance,
                amountOutMinimum: (ethToWant(_wethBalance) * slippage) / 10000
            });
        IV3SwapRouter(UNISWAP_V3_ROUTER).exactInput(params);
    }

    function _exitPosition(uint256 _stakedGmxAmount) internal {
        if (_stakedGmxAmount > 0) {
            _claimWethRewards();
            _sellWethForWant();

            IRewardRouterV2(GMX_REWARD_ROUTER).unstakeGmx(_stakedGmxAmount);
            uint256 _unstakedGmx = balanceOfUnstakedGmx();

            IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter
                .ExactInputParams({
                    path: abi.encodePacked(
                        GMX,
                        ETH_GMX_UNI_V3_FEE,
                        WETH,
                        ETH_USDC_UNI_V3_FEE,
                        address(want)
                    ),
                    recipient: address(this),
                    amountIn: _unstakedGmx,
                    amountOutMinimum: (gmxToWant(_unstakedGmx) * slippage) /
                        10000
                });
            IV3SwapRouter(UNISWAP_V3_ROUTER).exactInput(params);
        }
    }

    function ethToWant(
        uint256 _amtInWei
    ) public view override returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            ETH_USDC_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            OracleLibrary.getQuoteAtTick(
                meanTick,
                uint128(_amtInWei),
                WETH,
                address(want)
            );
    }

    function gmxToWant(uint256 _gmxAmount) public view returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            ETH_GMX_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            ethToWant(
                OracleLibrary.getQuoteAtTick(
                    meanTick,
                    uint128(_gmxAmount),
                    GMX,
                    WETH
                )
            );
    }

    function wantToGmx(
        uint256 _wantTokens
    ) public view virtual returns (uint256) {
        uint256 oneGmxPrice = gmxToWant(1 ether);
        uint256 gmxAmountUnscaled = (_wantTokens *
            10 ** ERC20(address(want)).decimals()) / oneGmxPrice;

        return
            Utils.scaleDecimals(
                gmxAmountUnscaled,
                ERC20(address(want)),
                ERC20(GMX)
            );
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();
        _wants += gmxToWant(balanceOfUnstakedGmx() + balanceOfStakedGmx());
        _wants += ethToWant(
            balanceOfWethRewards() + ERC20(WETH).balanceOf(address(this))
        );
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;

        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }

        uint256 _liquidWant = balanceOfWant();
        uint256 _amountNeeded = _debtOutstanding + _profit;
        if (_liquidWant <= _amountNeeded) {
            _withdrawSome(_amountNeeded - _liquidWant);
            _liquidWant = balanceOfWant();
        }

        // enough to pay profit (partial or full) only
        if (_liquidWant <= _profit) {
            _profit = _liquidWant;
            _debtPayment = 0;
            // enough to pay for all profit and _debtOutstanding (partial or full)
        } else {
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }

        IRewardRouterV2(GMX_REWARD_ROUTER).handleRewards(
            /* _shouldClaimGmx= */ false,
            /* _shouldStakeGmx= */ false,
            /* _shouldClaimEsGmx= */ true,
            /* _shouldStakeEsGmx= */ true,
            /* _shouldStakeMultiplierPoints= */ true,
            /* _shouldClaimWeth= */ true,
            /* _shouldConvertWethToEth= */ false
        );
        _sellWethForWant();

        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal > _debtOutstanding) {
            uint256 _excessWant = _wantBal - _debtOutstanding;

            IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter
                .ExactInputParams({
                    path: abi.encodePacked(
                        address(want),
                        ETH_USDC_UNI_V3_FEE,
                        WETH,
                        ETH_GMX_UNI_V3_FEE,
                        GMX
                    ),
                    recipient: address(this),
                    amountIn: _excessWant,
                    amountOutMinimum: (wantToGmx(_excessWant) * slippage) /
                        10000
                });
            IV3SwapRouter(UNISWAP_V3_ROUTER).exactInput(params);
        }

        // Currently, GMX does not reward users with esGMX and this condition will not be true until
        // they start distributing esGMX rewards.
        if (balanceOfUnstakedEsGmx() > 0) {
            IRewardRouterV2(GMX_REWARD_ROUTER).stakeEsGmx(
                balanceOfUnstakedEsGmx()
            );
        }

        if (balanceOfUnstakedGmx() > 0) {
            IRewardRouterV2(GMX_REWARD_ROUTER).stakeGmx(balanceOfUnstakedGmx());
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(balanceOfStakedGmx());
        return want.balanceOf(address(this));
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal >= _amountNeeded) {
            return (_amountNeeded, 0);
        }

        _withdrawSome(_amountNeeded - _wantBal);
        _wantBal = want.balanceOf(address(this));

        if (_amountNeeded > _wantBal) {
            _liquidatedAmount = _wantBal;
            _loss = _amountNeeded - _wantBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        IRewardRouterV2(GMX_REWARD_ROUTER).handleRewards(
            /* _shouldClaimGmx= */ false,
            /* _shouldStakeGmx= */ false,
            /* _shouldClaimEsGmx= */ true,
            /* _shouldStakeEsGmx= */ true,
            /* _shouldStakeMultiplierPoints= */ false,
            /* _shouldClaimWeth= */ true,
            /* _shouldConvertWethToEth= */ false
        );
        if (balanceOfStakedGmx() > 0) {
            IRewardRouterV2(GMX_REWARD_ROUTER).unstakeGmx(balanceOfStakedGmx());
        }

        IERC20(WETH).safeTransfer(
            _newStrategy,
            ERC20(WETH).balanceOf(address(this))
        );
        IERC20(GMX).safeTransfer(_newStrategy, balanceOfUnstakedGmx());

        // This is used to allow new strategy to transfer esGMX from old strategy.
        // esGMX is non-transferable by default and we need to signal transfer first.
        IRewardRouterV2(GMX_REWARD_ROUTER).signalTransfer(_newStrategy);
    }

    function acceptTransfer(address _oldStrategy) external onlyStrategist {
        IRewardRouterV2(GMX_REWARD_ROUTER).acceptTransfer(_oldStrategy);
    }

    function protectedTokens()
        internal
        pure
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](3);
        protected[0] = GMX;
        protected[1] = ES_GMX;
        protected[2] = WETH;
        return protected;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.19;

import {BaseStrategy, StrategyParams, VaultAPI} from "@yearn-protocol/contracts/BaseStrategy.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import "../../integrations/uniswap/v3/IV3SwapRouter.sol";
import "../../integrations/gains/IGNSVault.sol";

import "../../utils/Utils.sol";

contract GNSStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    address internal constant GNS = 0x18c11FD286C5EC11c3b683Caa813B77f5163A122;
    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address internal constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

    address internal constant GNS_VAULT =
        0x7edDE7e5900633F698EaB0Dbc97DE640fC5dC015;
    address internal constant UNISWAP_V3_ROUTER =
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    address internal constant ETH_USDC_UNI_V3_POOL =
        0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443;
    address internal constant GNS_ETH_UNI_V3_POOL =
        0xC91B7b39BBB2c733f0e7459348FD0c80259c8471;

    uint24 internal constant ETH_USDC_UNI_FEE = 500;
    uint24 internal constant GNS_ETH_UNI_FEE = 3000;
    uint24 internal constant DAI_USDC_UNI_FEE = 100;

    uint32 internal constant TWAP_RANGE_SECS = 1800;

    uint256 public slippage;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(address _vault, address _strategist) external {
        _initialize(_vault, _strategist, _strategist, _strategist);

        want.safeApprove(UNISWAP_V3_ROUTER, type(uint256).max);
        IERC20(DAI).safeApprove(UNISWAP_V3_ROUTER, type(uint256).max);
        IERC20(GNS).safeApprove(UNISWAP_V3_ROUTER, type(uint256).max);
        IERC20(GNS).safeApprove(GNS_VAULT, type(uint256).max);

        slippage = 9700; // 3%
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    function name() external pure override returns (string memory) {
        return "StrategyGNS";
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfDai() public view returns (uint256) {
        return IERC20(DAI).balanceOf(address(this));
    }

    function balanceOfWeth() public view returns (uint256) {
        return IERC20(WETH).balanceOf(address(this));
    }

    function balanceOfGns() public view returns (uint256) {
        return IERC20(GNS).balanceOf(address(this));
    }

    function balanceOfStakedGns() public view returns (uint256) {
        IGNSVault.Staker memory staker = IGNSVault(GNS_VAULT).stakers(
            address(this)
        );
        return staker.stakedGns;
    }

    function balanceOfRewards() public view returns (uint256) {
        return IGNSVault(GNS_VAULT).pendingRewardDai(address(this));
    }

    function _withdrawSome(uint256 _amountNeeded) internal {
        if (_amountNeeded == 0) return;

        uint256 rewardsTotal = daiToWant(balanceOfRewards());
        if (rewardsTotal >= _amountNeeded) {
            _sellRewards();
            return;
        }

        uint256 gnsToUnstake = Math.min(
            balanceOfStakedGns(),
            wantToGns(_amountNeeded - rewardsTotal)
        );

        _exitPosition(gnsToUnstake);
    }

    function _sellRewards() internal {
        IGNSVault(GNS_VAULT).harvestDai();
        uint256 balDai = IERC20(DAI).balanceOf(address(this));
        if (balDai > 0) {
            uint256 minAmountOut = (daiToWant(balDai) * slippage) / 10000;
            IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter
                .ExactInputSingleParams({
                    tokenIn: DAI,
                    tokenOut: address(want),
                    fee: DAI_USDC_UNI_FEE,
                    recipient: address(this),
                    amountIn: balDai,
                    amountOutMinimum: minAmountOut,
                    sqrtPriceLimitX96: 0
                });
            IV3SwapRouter(UNISWAP_V3_ROUTER).exactInputSingle(params);
        }
    }

    function _exitPosition(uint256 gnsAmount) internal {
        _sellRewards();

        if (gnsAmount == 0) {
            return;
        }

        IGNSVault(GNS_VAULT).unstakeGns(uint128(gnsAmount));

        uint256 minAmountOut = (gnsToWant(gnsAmount) * slippage) / 10000;
        IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter
            .ExactInputParams({
                path: abi.encodePacked(
                    GNS,
                    GNS_ETH_UNI_FEE,
                    WETH,
                    ETH_USDC_UNI_FEE,
                    address(want)
                ),
                recipient: address(this),
                amountIn: gnsAmount,
                amountOutMinimum: minAmountOut
            });
        IV3SwapRouter(UNISWAP_V3_ROUTER).exactInput(params);
    }

    function ethToWant(
        uint256 ethAmount
    ) public view override returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            ETH_USDC_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            OracleLibrary.getQuoteAtTick(
                meanTick,
                uint128(ethAmount),
                WETH,
                address(want)
            );
    }

    function wantToEth(uint256 wantAmount) public view returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            ETH_USDC_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            OracleLibrary.getQuoteAtTick(
                meanTick,
                uint128(wantAmount),
                address(want),
                WETH
            );
    }

    function gnsToWant(uint256 gnsAmount) public view returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            GNS_ETH_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            ethToWant(
                OracleLibrary.getQuoteAtTick(
                    meanTick,
                    uint128(gnsAmount),
                    GNS,
                    WETH
                )
            );
    }

    function wantToGns(uint256 wantAmount) public view returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            GNS_ETH_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            OracleLibrary.getQuoteAtTick(
                meanTick,
                uint128(wantToEth(wantAmount)),
                WETH,
                GNS
            );
    }

    function daiToWant(uint256 daiAmount) public view returns (uint256) {
        return Utils.scaleDecimals(daiAmount, ERC20(DAI), ERC20(address(want)));
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();
        _wants += gnsToWant(balanceOfGns());
        _wants += gnsToWant(balanceOfStakedGns());
        _wants += daiToWant(balanceOfRewards());
        _wants += daiToWant(balanceOfDai());
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;

        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }

        uint256 _liquidWant = balanceOfWant();
        uint256 _amountNeeded = _debtOutstanding + _profit;
        if (_liquidWant <= _amountNeeded) {
            _withdrawSome(_amountNeeded - _liquidWant);
            _liquidWant = balanceOfWant();
        }

        if (_liquidWant <= _profit) {
            // enough to pay profit (partial or full) only
            _profit = _liquidWant;
            _debtPayment = 0;
        } else {
            // enough to pay for all profit and _debtOutstanding (partial or full)
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }

        _sellRewards();

        uint256 _wantBal = balanceOfWant();
        if (_wantBal > _debtOutstanding) {
            uint256 _excessWant = _wantBal - _debtOutstanding;
            uint256 minAmountOut = (wantToGns(_excessWant) * slippage) / 10000;
            IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter
                .ExactInputParams({
                    path: abi.encodePacked(
                        address(want),
                        ETH_USDC_UNI_FEE,
                        WETH,
                        GNS_ETH_UNI_FEE,
                        GNS
                    ),
                    recipient: address(this),
                    amountIn: _excessWant,
                    amountOutMinimum: minAmountOut
                });
            IV3SwapRouter(UNISWAP_V3_ROUTER).exactInput(params);
        }

        uint256 gnsBal = balanceOfGns();
        if (gnsBal > 0) {
            IGNSVault(GNS_VAULT).stakeGns(uint128(gnsBal));
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(balanceOfStakedGns());
        return want.balanceOf(address(this));
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal >= _amountNeeded) {
            return (_amountNeeded, 0);
        }

        _withdrawSome(_amountNeeded - _wantBal);
        _wantBal = want.balanceOf(address(this));

        if (_amountNeeded > _wantBal) {
            _liquidatedAmount = _wantBal;
            _loss = _amountNeeded - _wantBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        IGNSVault(GNS_VAULT).unstakeGns(uint128(balanceOfStakedGns()));
        IGNSVault(GNS_VAULT).harvestDai();
        IERC20(GNS).safeTransfer(_newStrategy, balanceOfGns());
        IERC20(DAI).safeTransfer(_newStrategy, balanceOfDai());
        IERC20(WETH).safeTransfer(_newStrategy, balanceOfWeth());
    }

    function protectedTokens()
        internal
        pure
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](3);
        protected[0] = GNS;
        protected[1] = DAI;
        protected[2] = WETH;
        return protected;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {BaseStrategy, StrategyParams, VaultAPI} from "@yearn-protocol/contracts/BaseStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../integrations/hop/IStakingRewards.sol";
import "../../integrations/hop/IRouter.sol";

contract HopStrategy is BaseStrategy, Initializable {
    using SafeERC20 for IERC20;

    uint8 internal constant USDCindex = 0;
    uint8 internal constant USDCLPindex = 1;
    address internal constant HOP_ROUTER =
        0x10541b07d8Ad2647Dc6cD67abd4c03575dade261;
    address internal constant STAKING_REWARD =
        0xb0CabFE930642AD3E7DECdc741884d8C3F7EbC70;
    address internal constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address internal constant LP = 0xB67c014FA700E69681a673876eb8BAFAA36BFf71;
    address internal constant HOP = 0xc5102fE9359FD9a28f877a67E36B0F050d81a3CC;

    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address internal constant HOP_WETH_UNI_POOL =
        0x44ca2BE2Bd6a7203CCDBb63EED8382274f737A15;
    address internal constant WETH_USDC_UNI_POOL =
        0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443;
    uint256 internal constant HOP_WETH_POOL_FEE = 3000;
    uint256 internal constant USDC_WETH_POOL_FEE = 500;
    address internal constant UNISWAP_V3_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;

    uint32 internal constant TWAP_RANGE_SECS = 1800;

    uint256 internal constant slippage = 9500;
    address internal constant ETH_USDC_UNI_V3_POOL =
        0xC6962004f452bE9203591991D15f6b388e09E8D0;

    function ethToWant(
        uint256 ethAmount
    ) public view override returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            ETH_USDC_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            OracleLibrary.getQuoteAtTick(
                meanTick,
                uint128(ethAmount),
                WETH,
                address(want)
            );
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;
        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }

        uint256 _liquidWant = want.balanceOf(address(this));
        uint256 _amountNeeded = _debtOutstanding + _profit;
        if (_liquidWant <= _amountNeeded) {
            _withdrawSome(_amountNeeded - _liquidWant);
            _liquidWant = want.balanceOf(address(this));
        }

        if (_liquidWant <= _profit) {
            // enough to pay profit (partial or full) only
            _profit = _liquidWant;
            _debtPayment = 0;
        } else {
            // enough to pay for all profit and _debtOutstanding (partial or full)
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function protectedTokens()
        internal
        pure
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](3);
        // protected[0] = GNS;
        // protected[1] = DAI;
        // protected[2] = WETH;
        return protected;
    }

    function initialize(
        address _vault,
        address _strategist
    ) public initializer {
        _initialize(_vault, _strategist, _strategist, _strategist);

        IERC20(LP).safeApprove(STAKING_REWARD, type(uint256).max);
        IERC20(LP).safeApprove(HOP_ROUTER, type(uint256).max);
        IERC20(HOP).safeApprove(UNISWAP_V3_ROUTER, type(uint256).max);
        want.safeApprove(HOP_ROUTER, type(uint256).max);
    }

    constructor(address _vault) BaseStrategy(_vault) {}

    function name() external pure override returns (string memory) {
        return "HopStrategy";
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        return
            LpToWant(balanceOfStaked()) +
            balanceOfUnstaked() +
            HopToWant(rewardss());
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }
        _claimAndSellRewards();
        uint256 unstakedBalance = balanceOfUnstaked();

        uint256 excessWant;
        if (unstakedBalance > _debtOutstanding) {
            excessWant = unstakedBalance - _debtOutstanding;
        }
        if (excessWant > 0) {
            uint256[] memory liqAmounts = new uint256[](2);
            liqAmounts[0] = excessWant;
            liqAmounts[1] = 0;
            uint256 minAmount = (IRouter(HOP_ROUTER).calculateTokenAmount(
                address(this),
                liqAmounts,
                true
            ) * slippage) / 10000;

            IRouter(HOP_ROUTER).addLiquidity(
                liqAmounts,
                minAmount,
                block.timestamp
            );
            uint256 lpBalance = IERC20(LP).balanceOf(address(this));
            IStakingRewards(STAKING_REWARD).stake(lpBalance);
        }
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal >= _amountNeeded) {
            return (_amountNeeded, 0);
        }
        _withdrawSome(_amountNeeded - _wantBal);
        _wantBal = want.balanceOf(address(this));

        if (_amountNeeded > _wantBal) {
            _liquidatedAmount = _wantBal;
            _loss = _amountNeeded - _wantBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    //minAmount problem
    function liquidateAllPositions()
        internal
        override
        returns (uint256 _amountFreed)
    {
        _claimAndSellRewards();

        uint256 stakingAmount = balanceOfStaked();
        IStakingRewards(STAKING_REWARD).withdraw(stakingAmount);
        IRouter(HOP_ROUTER).removeLiquidityOneToken(
            stakingAmount,
            0,
            0,
            block.timestamp
        );
        _amountFreed = want.balanceOf(address(this));
    }

    function prepareMigration(address _newStrategy) internal override {
        uint256 assets = liquidateAllPositions();
        want.safeTransfer(_newStrategy, assets);
    }

    function balanceOfStaked() public view returns (uint256 amount) {
        amount = IStakingRewards(STAKING_REWARD).balanceOf(address(this));
    }

    function balanceOfUnstaked() public view returns (uint256 amount) {
        amount = want.balanceOf(address(this));
    }

    function rewardss() public view returns (uint256 amount) {
        amount = IStakingRewards(STAKING_REWARD).earned(address(this));
    }

    function smthToSmth(
        address pool,
        address tokenFrom,
        address tokenTo,
        uint256 amount
    ) internal view returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(pool, TWAP_RANGE_SECS);
        return
            OracleLibrary.getQuoteAtTick(
                meanTick,
                uint128(amount),
                tokenFrom,
                tokenTo
            );
    }

    function LpToWant(
        uint256 amountIn
    ) public view returns (uint256 amountOut) {
        if (amountIn == 0) {
            return 0;
        }
        amountOut = IRouter(HOP_ROUTER).calculateRemoveLiquidityOneToken(
            address(this),
            amountIn,
            0
        );
    }

    function HopToWant(
        uint256 amountIn
    ) public view returns (uint256 amountOut) {
        amountOut = smthToSmth(
            WETH_USDC_UNI_POOL,
            WETH,
            address(want),
            smthToSmth(HOP_WETH_UNI_POOL, HOP, WETH, amountIn)
        );
    }

    function _withdrawSome(uint256 _amountNeeded) internal {
        if (_amountNeeded == 0) {
            return;
        }
        if (HopToWant(rewardss()) >= _amountNeeded) {
            _claimAndSellRewards();
        } else {
            uint256 _usdcToUnstake = Math.min(
                balanceOfStaked(),
                _amountNeeded - HopToWant(rewardss())
            );
            _exitPosition(_usdcToUnstake);
        }
    }

    function _claimAndSellRewards() internal {
        IStakingRewards(STAKING_REWARD).getReward();
        _sellHopForWant(IERC20(HOP).balanceOf(address(this)));
    }

    function _exitPosition(uint256 _stakedAmount) internal {
        _claimAndSellRewards();
        uint256[] memory amountsToWithdraw = new uint256[](2);
        amountsToWithdraw[0] = _stakedAmount;
        amountsToWithdraw[1] = 0;

        uint256 amountLpToWithdraw = IRouter(HOP_ROUTER).calculateTokenAmount(
            address(this),
            amountsToWithdraw,
            false
        );
        if (amountLpToWithdraw > balanceOfStaked()) {
            amountLpToWithdraw = balanceOfStaked();
        }
        IStakingRewards(STAKING_REWARD).withdraw(amountLpToWithdraw);
        uint256 minAmount = (_stakedAmount * slippage) / 10000;
        IRouter(HOP_ROUTER).removeLiquidityOneToken(
            amountLpToWithdraw,
            0,
            minAmount,
            block.timestamp
        );
    }

    function _sellHopForWant(uint256 amountToSell) internal {
        if (amountToSell == 0) {
            return;
        }
        ISwapRouter.ExactInputParams memory params;
        bytes memory swapPath = abi.encodePacked(
            HOP,
            uint24(HOP_WETH_POOL_FEE),
            WETH,
            uint24(USDC_WETH_POOL_FEE),
            USDC
        );

        uint256 usdcExpected = HopToWant(amountToSell);
        params.path = swapPath;
        params.recipient = address(this);
        params.deadline = block.timestamp;
        params.amountIn = amountToSell;
        params.amountOutMinimum = (usdcExpected * slippage) / 10000;
        ISwapRouter(UNISWAP_V3_ROUTER).exactInput(params);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.19;

import {BaseStrategy, StrategyParams, VaultAPI} from "@yearn-protocol/contracts/BaseStrategy.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import "../../utils/Utils.sol";
import "../../integrations/chainlink/AggregatorV3Interface.sol";
import "../../integrations/joe/IStableJoeStaking.sol";
import "../../integrations/joe/ILBRouter.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract JOEStrategy is BaseStrategy, Initializable {
    using SafeERC20 for IERC20;

    address internal constant JOE = 0x371c7ec6D8039ff7933a2AA28EB827Ffe1F52f07;
    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    address internal constant ETH_USDC_UNI_V3_POOL =
        0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443;
    address internal constant JOE_USD_CHAINLINK_FEED =
        0x04180965a782E487d0632013ABa488A472243542;
    address internal constant JOE_LB_ROUTER =
        0xb4315e873dBcf96Ffd0acd8EA43f689D8c20fB30;
    address internal constant STABLE_JOE_STAKING =
        0x43646A8e839B2f2766392C1BF8f60F6e587B6960;

    address public JOE_REWARD_TOKEN;

    uint32 internal constant TWAP_RANGE_SECS = 1800;
    uint256 public slippage;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(
        address _vault,
        address _strategist
    ) public initializer {
        _initialize(_vault, _strategist, _strategist, _strategist);

        IERC20(JOE).safeApprove(STABLE_JOE_STAKING, type(uint256).max);
        IERC20(JOE).safeApprove(JOE_LB_ROUTER, type(uint256).max);

        want.safeApprove(JOE_LB_ROUTER, type(uint256).max);

        // As of moment of writing, this is the only reward token for staking JOE.
        // It is the same as the want token of this strategy (USDC).
        // We also support reward token to be JOE as this could happen in the future.
        // Strategist can set this to JOE if we want to claim JOE rewards.
        JOE_REWARD_TOKEN = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

        slippage = 9500; // 5%
    }

    function setRewardToken(address _rewardToken) external onlyStrategist {
        require(
            _rewardToken == JOE || _rewardToken == address(want),
            "!_rewardToken"
        );
        JOE_REWARD_TOKEN = _rewardToken;
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    function name() external pure override returns (string memory) {
        return "StrategyJOE";
    }

    function balanceOfUnstakedJoe() public view returns (uint256) {
        return ERC20(JOE).balanceOf(address(this));
    }

    function balanceOfStakedJoe() public view returns (uint256) {
        (uint256 amount, ) = IStableJoeStaking(STABLE_JOE_STAKING).getUserInfo(
            address(this),
            address(0)
        );
        return amount;
    }

    function balanceOfRewards() public view virtual returns (uint256) {
        uint256 rewards = IStableJoeStaking(STABLE_JOE_STAKING).pendingReward(
            address(this),
            JOE_REWARD_TOKEN
        );
        return rewards;
    }

    function rewardsToWant(uint256 rewards) public view returns (uint256) {
        if (JOE_REWARD_TOKEN == address(want)) {
            return rewards;
        } else {
            return joeToWant(rewards);
        }
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function _claimAndSellRewards() internal {
        uint256 rewards = balanceOfRewards();
        IStableJoeStaking(STABLE_JOE_STAKING).withdraw(0);

        if (JOE_REWARD_TOKEN == JOE) {
            _sellJoeForWant(rewards);
        }
    }

    function _withdrawSome(uint256 _amountNeeded) internal {
        if (_amountNeeded == 0) {
            return;
        }

        uint256 totalRewards = rewardsToWant(balanceOfRewards());

        if (totalRewards >= _amountNeeded) {
            _claimAndSellRewards();
        } else {
            uint256 _joeToUnstake = Math.min(
                balanceOfStakedJoe(),
                wantToJoe(_amountNeeded - totalRewards)
            );
            _exitPosition(_joeToUnstake);
        }
    }

    function _exitPosition(uint256 _stakedJoeAmount) internal {
        if (_stakedJoeAmount > 0) {
            IStableJoeStaking(STABLE_JOE_STAKING).withdraw(_stakedJoeAmount);
            _sellJoeForWant(balanceOfUnstakedJoe());
        }
    }

    function _sellJoeForWant(uint256 _joeAmount) internal {
        if (_joeAmount > 0) {
            uint256 wantExpected = joeToWant(_joeAmount);

            IERC20[] memory tokenPath = new IERC20[](3);
            tokenPath[0] = IERC20(JOE);
            tokenPath[1] = IERC20(WETH);
            tokenPath[2] = want;

            uint256[] memory pairBinSteps = new uint256[](2);
            pairBinSteps[0] = 20;
            pairBinSteps[1] = 15;

            ILBRouter.Version[] memory versions = new ILBRouter.Version[](2);
            versions[0] = ILBRouter.Version.V2_1;
            versions[1] = ILBRouter.Version.V2_1;

            ILBRouter.Path memory path;
            path.pairBinSteps = pairBinSteps;
            path.versions = versions;
            path.tokenPath = tokenPath;

            ILBRouter(JOE_LB_ROUTER).swapExactTokensForTokens(
                _joeAmount,
                (wantExpected * slippage) / 10000,
                path,
                address(this),
                block.timestamp
            );
        }
    }

    function ethToWant(
        uint256 _amtInWei
    ) public view override returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            ETH_USDC_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            OracleLibrary.getQuoteAtTick(
                meanTick,
                uint128(_amtInWei),
                WETH,
                address(want)
            );
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();
        _wants += joeToWant(balanceOfStakedJoe() + balanceOfUnstakedJoe());
        _wants += rewardsToWant(balanceOfRewards());
    }

    function joeToWant(uint256 _joeAmount) public view returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(JOE_USD_CHAINLINK_FEED)
            .latestRoundData();
        uint8 chainlinkDecimals = AggregatorV3Interface(JOE_USD_CHAINLINK_FEED)
            .decimals();
        uint256 priceScaled = uint256(price) * (10 ** (18 - chainlinkDecimals));

        return
            Utils.scaleDecimals(
                (priceScaled * _joeAmount) / 1 ether,
                ERC20(JOE),
                ERC20(address(want))
            );
    }

    function wantToJoe(
        uint256 _wantAmount
    ) public view virtual returns (uint256) {
        uint256 joeExpectedUnscaled = (_wantAmount *
            (10 ** ERC20(address(want)).decimals())) / joeToWant(1 ether);
        return
            Utils.scaleDecimals(
                joeExpectedUnscaled,
                ERC20(address(want)),
                ERC20(JOE)
            );
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;

        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }

        uint256 _liquidWant = balanceOfWant();
        uint256 _amountNeeded = _debtOutstanding + _profit;
        if (_liquidWant <= _amountNeeded) {
            _withdrawSome(_amountNeeded - _liquidWant);
            _liquidWant = balanceOfWant();
        }

        // enough to pay profit (partial or full) only
        if (_liquidWant <= _profit) {
            _profit = _liquidWant;
            _debtPayment = 0;
            // enough to pay for all profit and _debtOutstanding (partial or full)
        } else {
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }

        _claimAndSellRewards();

        uint256 _wantBal = want.balanceOf(address(this));

        if (_wantBal > _debtOutstanding) {
            uint256 _excessWant = _wantBal - _debtOutstanding;

            uint256 joeExpected = wantToJoe(_excessWant);

            IERC20[] memory tokenPath = new IERC20[](3);
            tokenPath[0] = want;
            tokenPath[1] = IERC20(WETH);
            tokenPath[2] = IERC20(JOE);

            uint256[] memory pairBinSteps = new uint256[](2);
            pairBinSteps[0] = 15;
            pairBinSteps[1] = 20;

            ILBRouter.Version[] memory versions = new ILBRouter.Version[](2);
            versions[0] = ILBRouter.Version.V2_1;
            versions[1] = ILBRouter.Version.V2_1;

            ILBRouter.Path memory path;
            path.pairBinSteps = pairBinSteps;
            path.versions = versions;
            path.tokenPath = tokenPath;

            ILBRouter(JOE_LB_ROUTER).swapExactTokensForTokens(
                _excessWant,
                (joeExpected * slippage) / 10000,
                path,
                address(this),
                block.timestamp
            );
        }

        if (balanceOfUnstakedJoe() > 0) {
            IStableJoeStaking(STABLE_JOE_STAKING).deposit(
                balanceOfUnstakedJoe()
            );
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(balanceOfStakedJoe());
        return want.balanceOf(address(this));
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal >= _amountNeeded) {
            return (_amountNeeded, 0);
        }

        _withdrawSome(_amountNeeded - _wantBal);
        _wantBal = want.balanceOf(address(this));

        if (_amountNeeded > _wantBal) {
            _liquidatedAmount = _wantBal;
            _loss = _amountNeeded - _wantBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        IStableJoeStaking(STABLE_JOE_STAKING).withdraw(balanceOfStakedJoe());
        IERC20(JOE).transfer(_newStrategy, balanceOfUnstakedJoe());
    }

    function protectedTokens()
        internal
        pure
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](1);
        protected[0] = JOE;
        return protected;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {BaseStrategy, StrategyParams} from "@yearn-protocol/contracts/BaseStrategy.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../integrations/balancer/IBalancerV2Vault.sol";
import "../integrations/balancer/IBalancerPool.sol";
import "../integrations/balancer/IBalancerPriceOracle.sol";
import "../integrations/aura/IAuraDeposit.sol";
import "../integrations/convex/IConvexRewards.sol";

import "../utils/AuraMath.sol";
import "../utils/Utils.sol";

contract AuraBALStrategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using AuraMath for uint256;

    IBalancerV2Vault internal constant balancerVault =
        IBalancerV2Vault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    address internal constant USDC_WETH_BALANCER_POOL =
        0x96646936b91d6B9D7D0c47C496AfBF3D6ec7B6f8;
    address internal constant STABLE_POOL_BALANCER_POOL =
        0x79c58f70905F734641735BC61e45c19dD9Ad60bC;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant AURA = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
    address internal constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address internal constant AURA_BAL =
        0x616e8BfA43F920657B3497DBf40D6b1A02D4608d;
    address internal constant WETH_BAL_BALANCER_POOL =
        0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
    address internal constant AURA_BAL_DEPOSIT_WRAPPER =
        0x68655AD9852a99C87C0934c7290BB62CFa5D4123;
    address internal constant AURA_BASE_REWARD =
        0x00A7BA8Ae7bca0B10A32Ea1f8e2a1Da980c6CAd2;
    address internal constant STAKED_AURA_BAL =
        0xfAA2eD111B4F580fCb85C48E6DC6782Dc5FCD7a6;

    bytes32 internal constant WETH_3POOL_BALANCER_POOL_ID =
        0x08775ccb6674d6bdceb0797c364c2653ed84f3840002000000000000000004f0;
    bytes32 internal constant STABLE_POOL_BALANCER_POOL_ID =
        0x79c58f70905f734641735bc61e45c19dd9ad60bc0000000000000000000004e7;
    bytes32 internal constant WETH_AURA_BALANCER_POOL_ID =
        0xcfca23ca9ca720b6e98e3eb9b6aa0ffc4a5c08b9000200000000000000000274;
    bytes32 internal constant WETH_BAL_BALANCER_POOL_ID =
        0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014;
    bytes32 internal constant AURA_BAL_BALANCER_POOL_ID =
        0x3dd0843a028c86e0b760b1a76929d1c5ef93a2dd000200000000000000000249;

    uint32 internal constant TWAP_RANGE_SECS = 1800;
    uint256 public slippage;

    uint256 private WANT_DECIMALS;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(address _vault, address _strategist) external {
        _initialize(_vault, _strategist, _strategist, _strategist);

        want.safeApprove(address(balancerVault), type(uint256).max);
        IERC20(BAL).safeApprove(address(balancerVault), type(uint256).max);
        IERC20(AURA).safeApprove(address(balancerVault), type(uint256).max);
        IERC20(WETH).safeApprove(address(balancerVault), type(uint256).max);
        IERC20(AURA_BAL).safeApprove(address(balancerVault), type(uint256).max);
        IERC20(AURA_BAL).safeApprove(AURA_BASE_REWARD, type(uint256).max);
        IERC20(BAL).safeApprove(AURA_BAL_DEPOSIT_WRAPPER, type(uint256).max);
        WANT_DECIMALS = ERC20(address(want)).decimals();

        slippage = 9700; // 3%
    }

    function name() external pure override returns (string memory) {
        return "StrategyAuraBAL";
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balRewards() public view returns (uint256) {
        return IConvexRewards(AURA_BASE_REWARD).earned(address(this));
    }

    function balanceOfStakedAuraBal() public view returns (uint256) {
        return IConvexRewards(AURA_BASE_REWARD).balanceOf(address(this));
    }

    function balanceOfUnstakedAuraBal() public view returns (uint256) {
        return IERC20(AURA_BAL).balanceOf(address(this));
    }

    function auraRewards(uint256 balTokens) public view returns (uint256) {
        return AuraRewardsMath.convertCrvToCvx(balTokens);
    }

    function balanceOfAura() public view returns (uint256) {
        return IERC20(AURA).balanceOf(address(this));
    }

    function balanceOfBal() public view returns (uint256) {
        return IERC20(BAL).balanceOf(address(this));
    }

    function auraToWant(uint256 auraTokens) public view returns (uint256) {
        uint256 scaledAmount = Utils.scaleDecimals(
            auraTokens,
            ERC20(AURA),
            ERC20(address(want))
        );
        return scaledAmount.mul(getAuraPrice()).div(10 ** WANT_DECIMALS);
    }

    function balToWant(uint256 balTokens) public view returns (uint256) {
        uint256 scaledAmount = Utils.scaleDecimals(
            balTokens,
            ERC20(AURA),
            ERC20(address(want))
        );
        return scaledAmount.mul(getBalPrice()).div(10 ** WANT_DECIMALS);
    }

    function auraBalToWant(
        uint256 auraBalTokens
    ) public view returns (uint256) {
        uint256 scaledAmount = Utils.scaleDecimals(
            auraBalTokens,
            ERC20(AURA_BAL),
            ERC20(address(want))
        );
        return scaledAmount.mul(getBalWethBptPrice()).div(10 ** WANT_DECIMALS);
    }

    function wantToAuraBal(
        uint256 _amountWant
    ) public view virtual returns (uint _amount) {
        uint256 oneAuraBalPrice = auraBalToWant(1 ether);
        uint256 auraBalAmountUnscaled = (_amountWant * (10 ** WANT_DECIMALS)) /
            oneAuraBalPrice;
        return
            Utils.scaleDecimals(
                auraBalAmountUnscaled,
                ERC20(address(want)),
                ERC20(AURA_BAL)
            );
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();

        uint256 auraBalTokens = balanceOfStakedAuraBal() +
            balanceOfUnstakedAuraBal();
        _wants += auraBalToWant(auraBalTokens);
        uint256 balRewardTokens = balRewards();
        uint256 balTokens = balRewardTokens + balanceOfBal();
        if (balTokens > 0) {
            _wants += balToWant(balTokens);
        }

        uint256 auraTokens = auraRewards(balRewardTokens) + balanceOfAura();
        if (auraTokens > 0) {
            _wants += auraToWant(auraTokens);
        }

        return _wants;
    }

    function getBalPrice() public view returns (uint256 price) {
        address priceOracle = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: TWAP_RANGE_SECS,
            ago: 0
        });
        uint256[] memory results = IBalancerPriceOracle(priceOracle)
            .getTimeWeightedAverage(queries);
        price = 1e36 / results[0];
        return ethToWant(price);
    }

    function getAuraPrice() public view returns (uint256 price) {
        address priceOracle = 0xc29562b045D80fD77c69Bec09541F5c16fe20d9d;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: TWAP_RANGE_SECS,
            ago: 0
        });
        uint256[] memory results;
        results = IBalancerPriceOracle(priceOracle).getTimeWeightedAverage(
            queries
        );
        price = results[0];
        return ethToWant(price);
    }

    function getBalWethBptPrice() public view returns (uint256 price) {
        address priceOracle = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.BPT_PRICE,
            secs: TWAP_RANGE_SECS,
            ago: 0
        });
        uint256[] memory results = IBalancerPriceOracle(priceOracle)
            .getTimeWeightedAverage(queries);
        price = results[0];
        return balToWant(price);
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;
        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }

        uint256 _liquidWant = balanceOfWant();
        uint256 _amountNeeded = _debtOutstanding + _profit;
        if (_liquidWant <= _amountNeeded) {
            withdrawSome(_amountNeeded - _liquidWant);
            _liquidWant = balanceOfWant();
        }

        // enough to pay profit (partial or full) only
        if (_liquidWant <= _profit) {
            _profit = _liquidWant;
            _debtPayment = 0;
            // enough to pay for all profit and _debtOutstanding (partial or full)
        } else {
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }

        if (balRewards() > 0) {
            IConvexRewards(AURA_BASE_REWARD).getReward(address(this), true);
        }
        _sellBalAndAura(0, IERC20(AURA).balanceOf(address(this)));

        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal > _debtOutstanding) {
            uint256 _excessWant = _wantBal - _debtOutstanding;

            IBalancerV2Vault.BatchSwapStep[]
                memory swaps = new IBalancerV2Vault.BatchSwapStep[](3);

            swaps[0] = IBalancerV2Vault.BatchSwapStep({
                poolId: STABLE_POOL_BALANCER_POOL_ID,
                assetInIndex: 0,
                assetOutIndex: 1,
                amount: _wantBal,
                userData: abi.encode(0)
            });

            swaps[1] = IBalancerV2Vault.BatchSwapStep({
                poolId: WETH_3POOL_BALANCER_POOL_ID,
                assetInIndex: 1,
                assetOutIndex: 2,
                amount: 0,
                userData: abi.encode(0)
            });

            swaps[2] = IBalancerV2Vault.BatchSwapStep({
                poolId: WETH_BAL_BALANCER_POOL_ID,
                assetInIndex: 2,
                assetOutIndex: 3,
                amount: 0,
                userData: abi.encode(0)
            });

            address[] memory assets = new address[](4);
            assets[0] = address(want);
            assets[1] = STABLE_POOL_BALANCER_POOL;
            assets[2] = WETH;
            assets[3] = BAL;

            uint256 balExpected = (_excessWant * 10 ** WANT_DECIMALS) /
                balToWant(1 ether);

            int[] memory limits = new int[](4);
            limits[0] = int(_excessWant);
            limits[1] = 0;
            limits[2] = 0;
            limits[3] = -1 * int((balExpected * slippage) / 10000);

            balancerVault.batchSwap(
                IBalancerV2Vault.SwapKind.GIVEN_IN,
                swaps,
                assets,
                getFundManagement(),
                limits,
                block.timestamp
            );
        }

        if (balanceOfBal() > 0) {
            uint256 auraBalExpected = (balToWant(balanceOfBal()) *
                (10 ** WANT_DECIMALS)) / auraBalToWant(1 ether);
            uint256 auraBalExpectedScaled = Utils.scaleDecimals(
                auraBalExpected,
                ERC20(address(want)),
                ERC20(AURA_BAL)
            );
            IBalDepositWrapper(AURA_BAL_DEPOSIT_WRAPPER).deposit(
                ERC20(BAL).balanceOf(address(this)),
                (auraBalExpectedScaled * slippage) / 10000,
                true,
                AURA_BASE_REWARD
            );
        }

        if (balanceOfUnstakedAuraBal() > 0) {
            IConvexRewards(AURA_BASE_REWARD).stakeAll();
        }
    }

    function _sellBalAndAura(uint256 _balAmount, uint256 _auraAmount) internal {
        if (_auraAmount > 0) {
            IBalancerV2Vault.BatchSwapStep[]
                memory swaps = new IBalancerV2Vault.BatchSwapStep[](3);

            swaps[0] = IBalancerV2Vault.BatchSwapStep({
                poolId: WETH_AURA_BALANCER_POOL_ID,
                assetInIndex: 0,
                assetOutIndex: 1,
                amount: _auraAmount,
                userData: abi.encode(0)
            });

            swaps[1] = IBalancerV2Vault.BatchSwapStep({
                poolId: WETH_3POOL_BALANCER_POOL_ID,
                assetInIndex: 1,
                assetOutIndex: 2,
                amount: 0,
                userData: abi.encode(0)
            });

            swaps[2] = IBalancerV2Vault.BatchSwapStep({
                poolId: STABLE_POOL_BALANCER_POOL_ID,
                assetInIndex: 2,
                assetOutIndex: 3,
                amount: 0,
                userData: abi.encode(0)
            });

            address[] memory assets = new address[](4);
            assets[0] = AURA;
            assets[1] = WETH;
            assets[2] = STABLE_POOL_BALANCER_POOL;
            assets[3] = address(want);

            int[] memory limits = new int[](4);
            limits[0] = int256(_auraAmount);
            limits[3] =
                (-1) *
                int((auraToWant(_auraAmount) * slippage) / 10000);

            balancerVault.batchSwap(
                IBalancerV2Vault.SwapKind.GIVEN_IN,
                swaps,
                assets,
                getFundManagement(),
                limits,
                block.timestamp
            );
        }

        if (_balAmount > 0) {
            IBalancerV2Vault.BatchSwapStep[]
                memory swaps = new IBalancerV2Vault.BatchSwapStep[](3);

            swaps[0] = IBalancerV2Vault.BatchSwapStep({
                poolId: WETH_BAL_BALANCER_POOL_ID,
                assetInIndex: 0,
                assetOutIndex: 1,
                amount: _balAmount,
                userData: abi.encode(0)
            });

            swaps[1] = IBalancerV2Vault.BatchSwapStep({
                poolId: WETH_3POOL_BALANCER_POOL_ID,
                assetInIndex: 1,
                assetOutIndex: 2,
                amount: 0,
                userData: abi.encode(0)
            });

            swaps[2] = IBalancerV2Vault.BatchSwapStep({
                poolId: STABLE_POOL_BALANCER_POOL_ID,
                assetInIndex: 2,
                assetOutIndex: 3,
                amount: 0,
                userData: abi.encode(0)
            });

            address[] memory assets = new address[](4);
            assets[0] = BAL;
            assets[1] = WETH;
            assets[2] = STABLE_POOL_BALANCER_POOL;
            assets[3] = address(want);

            int[] memory limits = new int[](4);
            limits[0] = int256(_balAmount);
            limits[3] = (-1) * int((balToWant(_balAmount) * slippage) / 10000);

            balancerVault.batchSwap(
                IBalancerV2Vault.SwapKind.GIVEN_IN,
                swaps,
                assets,
                getFundManagement(),
                limits,
                block.timestamp
            );
        }
    }

    function withdrawSome(uint256 _amountNeeded) internal {
        if (_amountNeeded == 0) {
            return;
        }

        uint256 balRewardTokens = balRewards();
        uint256 balTokens = balRewardTokens +
            ERC20(BAL).balanceOf(address(this));
        uint256 auraTokens = auraRewards(balRewardTokens) +
            ERC20(AURA).balanceOf(address(this));
        uint256 rewardsTotal = balToWant(balTokens) + auraToWant(auraTokens);

        if (rewardsTotal >= _amountNeeded) {
            IConvexRewards(AURA_BASE_REWARD).getReward(address(this), true);
            _sellBalAndAura(
                IERC20(BAL).balanceOf(address(this)),
                IERC20(AURA).balanceOf(address(this))
            );
        } else {
            uint256 auraBalToUnstake = Math.min(
                wantToAuraBal(_amountNeeded - rewardsTotal),
                balanceOfStakedAuraBal()
            );

            if (auraBalToUnstake > 0) {
                _exitPosition(auraBalToUnstake);
            }
        }
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal < _amountNeeded) {
            withdrawSome(_amountNeeded - _wantBal);
            _wantBal = balanceOfWant();
        }

        if (_amountNeeded > _wantBal) {
            _liquidatedAmount = _wantBal;
            _loss = _amountNeeded - _wantBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(balanceOfStakedAuraBal());
        return want.balanceOf(address(this));
    }

    function _exitPosition(uint256 auraBalAmount) internal {
        IConvexRewards(AURA_BASE_REWARD).withdraw(auraBalAmount, true);
        _sellBalAndAura(
            IERC20(BAL).balanceOf(address(this)),
            IERC20(AURA).balanceOf(address(this))
        );

        IBalancerV2Vault.BatchSwapStep[]
            memory swaps = new IBalancerV2Vault.BatchSwapStep[](1);

        swaps[0] = IBalancerV2Vault.BatchSwapStep({
            poolId: AURA_BAL_BALANCER_POOL_ID,
            assetInIndex: 0,
            assetOutIndex: 1,
            amount: auraBalAmount,
            userData: abi.encode(0)
        });

        address[] memory assets = new address[](2);
        assets[0] = AURA_BAL;
        assets[1] = WETH_BAL_BALANCER_POOL;

        int[] memory limits = new int[](2);
        limits[0] = int(auraBalAmount);
        limits[1] = (-1) * int256((auraBalAmount * slippage) / 10000);

        balancerVault.batchSwap(
            IBalancerV2Vault.SwapKind.GIVEN_IN,
            swaps,
            assets,
            getFundManagement(),
            limits,
            block.timestamp
        );

        uint256 wethBalAmount = IERC20(WETH_BAL_BALANCER_POOL).balanceOf(
            address(this)
        );
        uint256 wantExpected = auraBalToWant(wethBalAmount);
        uint256 wethExpected = (wantExpected * (10 ** WANT_DECIMALS)) /
            ethToWant(1 ether);
        uint256 wethScaled = Utils.scaleDecimals(
            wethExpected,
            ERC20(address(want)),
            ERC20(WETH)
        );

        address[] memory _assets = new address[](2);
        _assets[0] = BAL;
        _assets[1] = WETH;

        uint256[] memory _minAmountsOut = new uint256[](2);
        _minAmountsOut[0] = 0;
        _minAmountsOut[1] = (wethScaled * slippage) / 10000;

        bytes memory userData = abi.encode(
            IBalancerV2Vault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
            wethBalAmount,
            1 // exitTokenIndex
        );

        IBalancerV2Vault.ExitPoolRequest memory request;
        request = IBalancerV2Vault.ExitPoolRequest({
            assets: _assets,
            minAmountsOut: _minAmountsOut,
            userData: userData,
            toInternalBalance: false
        });

        balancerVault.exitPool({
            poolId: WETH_BAL_BALANCER_POOL_ID,
            sender: address(this),
            recipient: payable(address(this)),
            request: request
        });

        _sellWethForWant();
    }

    function _sellWethForWant() internal {
        uint256 wethBal = IERC20(WETH).balanceOf(address(this));

        if (wethBal > 0) {
            IBalancerV2Vault.BatchSwapStep[]
                memory swaps = new IBalancerV2Vault.BatchSwapStep[](2);

            swaps[0] = IBalancerV2Vault.BatchSwapStep({
                poolId: WETH_3POOL_BALANCER_POOL_ID,
                assetInIndex: 0,
                assetOutIndex: 1,
                amount: wethBal,
                userData: abi.encode(0)
            });

            swaps[1] = IBalancerV2Vault.BatchSwapStep({
                poolId: STABLE_POOL_BALANCER_POOL_ID,
                assetInIndex: 1,
                assetOutIndex: 2,
                amount: 0,
                userData: abi.encode(0)
            });

            address[] memory assets = new address[](3);
            assets[0] = WETH;
            assets[1] = STABLE_POOL_BALANCER_POOL;
            assets[2] = address(want);

            int[] memory limits = new int[](3);
            limits[0] = int256(wethBal);
            limits[2] = (-1) * int((ethToWant(wethBal) * slippage) / 10000);

            balancerVault.batchSwap(
                IBalancerV2Vault.SwapKind.GIVEN_IN,
                swaps,
                assets,
                getFundManagement(),
                limits,
                block.timestamp
            );
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        IConvexRewards(AURA_BASE_REWARD).withdraw(
            IConvexRewards(AURA_BASE_REWARD).balanceOf(address(this)),
            true
        );

        uint256 auraBal = IERC20(AURA).balanceOf(address(this));
        if (auraBal > 0) {
            IERC20(AURA).safeTransfer(_newStrategy, auraBal);
        }
        uint256 balancerBal = IERC20(BAL).balanceOf(address(this));
        if (balancerBal > 0) {
            IERC20(BAL).safeTransfer(_newStrategy, balancerBal);
        }
        uint256 auraBalBalance = IERC20(AURA_BAL).balanceOf(address(this));
        if (auraBalBalance > 0) {
            IERC20(AURA_BAL).safeTransfer(_newStrategy, auraBalBalance);
        }
    }

    function protectedTokens()
        internal
        pure
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](5);
        protected[0] = BAL;
        protected[1] = AURA;
        protected[2] = AURA_BAL;
        protected[3] = WETH;
        protected[4] = STAKED_AURA_BAL;
        return protected;
    }

    function ethToWant(
        uint256 _amtInWei
    ) public view override returns (uint256) {
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: TWAP_RANGE_SECS,
            ago: 0
        });

        uint256[] memory results;
        results = IBalancerPriceOracle(USDC_WETH_BALANCER_POOL)
            .getTimeWeightedAverage(queries);

        return
            Utils.scaleDecimals(
                (_amtInWei * results[0]) / 1 ether,
                ERC20(WETH),
                ERC20(address(want))
            );
    }

    function getFundManagement()
        internal
        view
        returns (IBalancerV2Vault.FundManagement memory fundManagement)
    {
        fundManagement = IBalancerV2Vault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {BaseStrategy, StrategyParams} from "@yearn-protocol/contracts/BaseStrategy.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../integrations/curve/ICurve.sol";
import "../integrations/balancer/IBalancerV2Vault.sol";
import "../integrations/balancer/IBalancerPool.sol";
import "../integrations/balancer/IBalancerPriceOracle.sol";
import "../integrations/convex/IConvexDeposit.sol";
import "../integrations/convex/IConvexRewards.sol";
import "../integrations/lido/IWSTEth.sol";

import "../utils/AuraMath.sol";
import "../utils/Utils.sol";

contract AuraTriPoolStrategy is BaseStrategy, Initializable {
    using SafeERC20 for IERC20;
    using Address for address;
    using AuraMath for uint256;

    IBalancerV2Vault internal constant balancerVault =
        IBalancerV2Vault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    address internal constant AURA = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
    address internal constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address internal constant AURA_BOOSTER =
        0xA57b8d98dAE62B26Ec3bcC4a365338157060B234;
    address internal constant CURVE_SWAP_ROUTER =
        0x99a58482BD75cbab83b27EC03CA68fF489b5788f;

    address internal constant STETH =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address internal constant WSTETH =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    address internal constant TRIPOOL_BALANCER_POOL =
        0x42ED016F826165C2e5976fe5bC3df540C5aD0Af7;
    bytes32 internal constant TRIPOOL_BALANCER_POOL_ID =
        0x42ed016f826165c2e5976fe5bc3df540c5ad0af700000000000000000000058b;

    bytes32 internal constant BAL_ETH_BALANCER_POOL_ID =
        bytes32(
            0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014
        );
    bytes32 internal constant AURA_ETH_BALANCER_POOL_ID =
        bytes32(
            0xc29562b045d80fd77c69bec09541f5c16fe20d9d000200000000000000000251
        );

    uint32 internal constant TWAP_RANGE_SECS = 1800;
    uint256 public slippage;
    uint256 public rewardsSlippage;

    uint256 public AURA_PID;
    address public AURA_TRIPOOL_REWARDS;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(
        address _vault,
        address _strategist
    ) public initializer {
        _initialize(_vault, _strategist, _strategist, _strategist);

        want.safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(STETH).safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(BAL).safeApprove(address(balancerVault), type(uint256).max);
        IERC20(AURA).safeApprove(address(balancerVault), type(uint256).max);
        IERC20(STETH).safeApprove(WSTETH, type(uint256).max);
        IERC20(WSTETH).safeApprove(address(balancerVault), type(uint256).max);
        IERC20(TRIPOOL_BALANCER_POOL).safeApprove(
            AURA_BOOSTER,
            type(uint256).max
        );

        slippage = 9850; // 1.5%
        rewardsSlippage = 9700; // 3%
        AURA_PID = 139;
        AURA_TRIPOOL_REWARDS = 0x032B676d5D55e8ECbAe88ebEE0AA10fB5f72F6CB;
    }

    function name() external pure override returns (string memory) {
        return "StrategyAuraTriPool";
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    function setRewardsSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        rewardsSlippage = _slippage;
    }

    function setAuraPid(uint256 _pid) external onlyStrategist {
        AURA_PID = _pid;
    }

    function setAuraTriPoolRewards(
        address _auraTriPoolRewards
    ) external onlyStrategist {
        AURA_TRIPOOL_REWARDS = _auraTriPoolRewards;
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfUnstakedBpt() public view returns (uint256) {
        return IERC20(TRIPOOL_BALANCER_POOL).balanceOf(address(this));
    }

    function balRewards() public view returns (uint256) {
        return IConvexRewards(AURA_TRIPOOL_REWARDS).earned(address(this));
    }

    function balanceOfAuraBpt() public view returns (uint256) {
        return IERC20(AURA_TRIPOOL_REWARDS).balanceOf(address(this));
    }

    function auraRewards(uint256 balTokens) public view returns (uint256) {
        return AuraRewardsMath.convertCrvToCvx(balTokens);
    }

    function auraToWant(uint256 auraTokens) public view returns (uint256) {
        uint unscaled = auraTokens.mul(getAuraPrice()).div(1e18);
        return Utils.scaleDecimals(unscaled, ERC20(AURA), ERC20(address(want)));
    }

    function balToWant(uint256 balTokens) public view returns (uint256) {
        uint unscaled = balTokens.mul(getBalPrice()).div(1e18);
        return Utils.scaleDecimals(unscaled, ERC20(BAL), ERC20(address(want)));
    }

    function wstethTokenRate()
        public
        view
        ensureNotInVaultContext
        returns (uint256)
    {
        uint256 rate = IBalancerPool(TRIPOOL_BALANCER_POOL).getRate();
        uint256 wstRate = IBalancerPool(TRIPOOL_BALANCER_POOL).getTokenRate(
            WSTETH
        );
        return (wstRate * 1e18) / rate;
    }

    function wstEthToBpt(uint256 wstEthTokens) public view returns (uint256) {
        uint256 tokenRate = bptToWstEth(1 ether);
        return (wstEthTokens * 1e18) / tokenRate;
    }

    function bptToWstEth(uint256 bptTokens) public view returns (uint256) {
        uint256 tokenRate = wstethTokenRate();
        return (bptTokens * 1e18) / tokenRate;
    }

    function wantToBpt(
        uint _amountWant
    ) public view virtual returns (uint _amount) {
        return wstEthToBpt(IWSTEth(WSTETH).getWstETHByStETH(_amountWant));
    }

    function bptToWant(uint bptTokens) public view returns (uint _amount) {
        return IWSTEth(WSTETH).getStETHByWstETH(bptToWstEth(bptTokens));
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();

        uint256 bptTokens = balanceOfUnstakedBpt() + balanceOfAuraBpt();
        _wants += bptToWant(bptTokens);
        uint256 balRewardTokens = balRewards();
        uint256 balTokens = balRewardTokens +
            ERC20(BAL).balanceOf(address(this));
        if (balTokens > 0) {
            _wants += balToWant(balTokens);
        }

        uint256 auraTokens = auraRewards(balRewardTokens) +
            ERC20(AURA).balanceOf(address(this));
        if (auraTokens > 0) {
            _wants += auraToWant(auraTokens);
        }

        return _wants;
    }

    function getBalPrice() public view returns (uint256 price) {
        address priceOracle = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: 1800,
            ago: 0
        });
        uint256[] memory results = IBalancerPriceOracle(priceOracle)
            .getTimeWeightedAverage(queries);
        price = 1e36 / results[0];
    }

    function getAuraPrice() public view returns (uint256 price) {
        address priceOracle = 0xc29562b045D80fD77c69Bec09541F5c16fe20d9d;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: 1800,
            ago: 0
        });
        uint256[] memory results;
        results = IBalancerPriceOracle(priceOracle).getTimeWeightedAverage(
            queries
        );
        price = results[0];
    }

    modifier ensureNotInVaultContext() {
        (, bytes memory revertData) = address(balancerVault).staticcall{
            gas: 10_000
        }(abi.encodeWithSelector(balancerVault.manageUserBalance.selector, 0));
        require(
            revertData.length == 0,
            "AuraWETHStrategy::ensureNotInVaultContext"
        );

        _;
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;

        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }

        uint256 _liquidWant = balanceOfWant();
        uint256 _amountNeeded = _debtOutstanding + _profit;
        if (_liquidWant <= _amountNeeded) {
            withdrawSome(_amountNeeded - _liquidWant);
            _liquidWant = balanceOfWant();
        }

        // enough to pay profit (partial or full) only
        if (_liquidWant <= _profit) {
            _profit = _liquidWant;
            _debtPayment = 0;
            // enough to pay for all profit and _debtOutstanding (partial or full)
        } else {
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }

        if (balRewards() > 0) {
            IConvexRewards(AURA_TRIPOOL_REWARDS).getReward(address(this), true);
        }
        _sellBalAndAura(
            IERC20(BAL).balanceOf(address(this)),
            IERC20(AURA).balanceOf(address(this))
        );

        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal > _debtOutstanding) {
            uint256 _excessWant = _wantBal - _debtOutstanding;

            address[9] memory _route = [
                address(want), // WETH
                address(want), // no pool for WETH -> ETH,
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // ETH
                0xDC24316b9AE028F1497c275EB9192a3Ea0f67022, // steth pool
                0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84, // stETH
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(0), uint256(0), uint256(15)],
                [uint256(0), uint256(1), uint256(1)], // WETH -> stETH, cryptoswap exchange
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];

            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                _excessWant,
                (_excessWant * slippage) / 10_000
            );
        }

        uint256 stethBalance = IERC20(STETH).balanceOf(address(this));
        if (stethBalance > 0) {
            IWSTEth(WSTETH).wrap(stethBalance);
        }

        uint256 wstethBalance = IERC20(WSTETH).balanceOf(address(this));
        if (wstethBalance > 0) {
            uint256[] memory _amountsIn = new uint256[](3);
            _amountsIn[0] = wstethBalance;
            _amountsIn[1] = 0;
            _amountsIn[2] = 0;

            address[] memory _assets = new address[](4);
            _assets[0] = TRIPOOL_BALANCER_POOL;
            _assets[1] = WSTETH;
            _assets[2] = 0xac3E018457B222d93114458476f3E3416Abbe38F; // sfrxETH
            _assets[3] = 0xae78736Cd615f374D3085123A210448E74Fc6393; // rETH

            uint256[] memory _maxAmountsIn = new uint256[](4);
            _maxAmountsIn[0] = 0;
            _maxAmountsIn[1] = wstethBalance;
            _maxAmountsIn[2] = 0;
            _maxAmountsIn[3] = 0;

            uint256 expected = (wstEthToBpt(wstethBalance) * slippage) / 10000;
            bytes memory _userData = abi.encode(
                IBalancerV2Vault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
                _amountsIn,
                expected
            );
            IBalancerV2Vault.JoinPoolRequest memory _request;
            _request = IBalancerV2Vault.JoinPoolRequest({
                assets: _assets,
                maxAmountsIn: _maxAmountsIn,
                userData: _userData,
                fromInternalBalance: false
            });

            balancerVault.joinPool({
                poolId: TRIPOOL_BALANCER_POOL_ID,
                sender: address(this),
                recipient: payable(address(this)),
                request: _request
            });
        }

        if (balanceOfUnstakedBpt() > 0) {
            bool auraSuccess = IConvexDeposit(AURA_BOOSTER).depositAll(
                AURA_PID, // PID
                true // stake
            );
            require(auraSuccess, "Aura deposit failed");
        }
    }

    function _sellBalAndAura(uint256 _balAmount, uint256 _auraAmount) internal {
        if (_balAmount == 0) return;

        IBalancerV2Vault.BatchSwapStep[] memory swaps;
        if (_auraAmount == 0) {
            swaps = new IBalancerV2Vault.BatchSwapStep[](1);
        } else {
            swaps = new IBalancerV2Vault.BatchSwapStep[](2);
            swaps[1] = IBalancerV2Vault.BatchSwapStep({
                poolId: AURA_ETH_BALANCER_POOL_ID,
                assetInIndex: 1,
                assetOutIndex: 2,
                amount: _auraAmount,
                userData: abi.encode(0)
            });
        }

        // bal to weth
        swaps[0] = IBalancerV2Vault.BatchSwapStep({
            poolId: BAL_ETH_BALANCER_POOL_ID,
            assetInIndex: 0,
            assetOutIndex: 2,
            amount: _balAmount,
            userData: abi.encode(0)
        });

        address[] memory assets = new address[](3);
        assets[0] = BAL;
        assets[1] = AURA;
        assets[2] = address(want);

        int estimatedRewards = int(
            balToWant(_balAmount) + auraToWant(_auraAmount)
        );
        int[] memory limits = new int[](3);
        limits[0] = int(_balAmount);
        limits[1] = int(_auraAmount);
        limits[2] = (-1) * ((estimatedRewards * int(rewardsSlippage)) / 10000);

        balancerVault.batchSwap(
            IBalancerV2Vault.SwapKind.GIVEN_IN,
            swaps,
            assets,
            getFundManagement(),
            limits,
            block.timestamp
        );
    }

    function withdrawSome(uint256 _amountNeeded) internal {
        if (_amountNeeded == 0) {
            return;
        }

        uint256 balRewardTokens = balRewards();
        uint256 balTokens = balRewardTokens +
            ERC20(BAL).balanceOf(address(this));
        uint256 auraTokens = auraRewards(balRewardTokens) +
            ERC20(AURA).balanceOf(address(this));
        uint256 rewardsTotal = balToWant(balTokens) + auraToWant(auraTokens);

        if (rewardsTotal >= _amountNeeded) {
            IConvexRewards(AURA_TRIPOOL_REWARDS).getReward(address(this), true);
            _sellBalAndAura(
                IERC20(BAL).balanceOf(address(this)),
                IERC20(AURA).balanceOf(address(this))
            );
        } else {
            uint256 bptToUnstake = Math.min(
                wantToBpt(_amountNeeded - rewardsTotal),
                balanceOfAuraBpt()
            );

            if (bptToUnstake > 0) {
                _exitPosition(bptToUnstake);
            }
        }
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal < _amountNeeded) {
            withdrawSome(_amountNeeded - _wantBal);
            _wantBal = balanceOfWant();
        }

        if (_amountNeeded > _wantBal) {
            _liquidatedAmount = _wantBal;
            _loss = _amountNeeded - _wantBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(IERC20(AURA_TRIPOOL_REWARDS).balanceOf(address(this)));
        return want.balanceOf(address(this));
    }

    function _exitPosition(uint256 bptAmount) internal {
        IConvexRewards(AURA_TRIPOOL_REWARDS).withdrawAndUnwrap(bptAmount, true);

        _sellBalAndAura(
            IERC20(BAL).balanceOf(address(this)),
            IERC20(AURA).balanceOf(address(this))
        );

        address[] memory _assets = new address[](4);
        _assets[0] = TRIPOOL_BALANCER_POOL;
        _assets[1] = WSTETH;
        _assets[2] = 0xac3E018457B222d93114458476f3E3416Abbe38F;
        _assets[3] = 0xae78736Cd615f374D3085123A210448E74Fc6393;

        uint256[] memory _minAmountsOut = new uint256[](4);
        _minAmountsOut[0] = 0;
        _minAmountsOut[1] = (bptToWstEth(bptAmount) * slippage) / 10_000;
        _minAmountsOut[2] = 0;
        _minAmountsOut[3] = 0;

        bytes memory userData = abi.encode(
            IBalancerV2Vault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
            bptAmount,
            0 // exitTokenIndex
        );

        IBalancerV2Vault.ExitPoolRequest memory request;
        request = IBalancerV2Vault.ExitPoolRequest({
            assets: _assets,
            minAmountsOut: _minAmountsOut,
            userData: userData,
            toInternalBalance: false
        });

        balancerVault.exitPool({
            poolId: TRIPOOL_BALANCER_POOL_ID,
            sender: address(this),
            recipient: payable(address(this)),
            request: request
        });

        uint256 wstethBalance = IERC20(WSTETH).balanceOf(address(this));
        if (wstethBalance > 0) {
            IWSTEth(WSTETH).unwrap(wstethBalance);
        }

        uint256 stethBalance = IERC20(STETH).balanceOf(address(this));
        if (stethBalance > 0) {
            address[9] memory _route = [
                STETH,
                0xDC24316b9AE028F1497c275EB9192a3Ea0f67022, // steth pool
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // ETH
                address(want), // no pool for WETH -> ETH,
                address(want), // WETH
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(1), uint256(0), uint256(1)], // stETH -> WETH, stable swap exchange
                [uint256(0), uint256(0), uint256(15)],
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];

            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                stethBalance,
                (stethBalance * slippage) / 10_000
            );
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        IConvexRewards auraPool = IConvexRewards(AURA_TRIPOOL_REWARDS);
        auraPool.withdrawAndUnwrap(auraPool.balanceOf(address(this)), true);

        uint256 auraBal = IERC20(AURA).balanceOf(address(this));
        if (auraBal > 0) {
            IERC20(AURA).safeTransfer(_newStrategy, auraBal);
        }
        uint256 balancerBal = IERC20(BAL).balanceOf(address(this));
        if (balancerBal > 0) {
            IERC20(BAL).safeTransfer(_newStrategy, balancerBal);
        }
        uint256 bptBal = IERC20(TRIPOOL_BALANCER_POOL).balanceOf(address(this));
        if (bptBal > 0) {
            IERC20(TRIPOOL_BALANCER_POOL).safeTransfer(_newStrategy, bptBal);
        }
    }

    function ethToWant(
        uint256 _amtInWei
    ) public pure override returns (uint256) {
        return _amtInWei;
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](4);
        protected[0] = AURA_TRIPOOL_REWARDS;
        protected[1] = TRIPOOL_BALANCER_POOL;
        protected[2] = BAL;
        protected[3] = AURA;
        return protected;
    }

    function getFundManagement()
        internal
        view
        returns (IBalancerV2Vault.FundManagement memory fundManagement)
    {
        fundManagement = IBalancerV2Vault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
    }

    receive() external payable {}

    uint256[50] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {BaseStrategy, StrategyParams} from "@yearn-protocol/contracts/BaseStrategy.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../integrations/balancer/IBalancerV2Vault.sol";
import "../integrations/balancer/IBalancerPool.sol";
import "../integrations/balancer/IBalancerPriceOracle.sol";
import "../integrations/convex/IConvexDeposit.sol";
import "../integrations/convex/IConvexRewards.sol";

import "../utils/AuraMath.sol";
import "../utils/Utils.sol";

contract AuraWETHStrategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using AuraMath for uint256;

    IBalancerV2Vault internal constant balancerVault =
        IBalancerV2Vault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    address internal constant USDC_WETH_BALANCER_POOL =
        0x96646936b91d6B9D7D0c47C496AfBF3D6ec7B6f8;
    address internal constant STABLE_POOL_BALANCER_POOL =
        0x79c58f70905F734641735BC61e45c19dD9Ad60bC;
    address internal constant WETH_AURA_BALANCER_POOL =
        0xCfCA23cA9CA720B6E98E3Eb9B6aa0fFC4a5C08B9;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant AURA = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
    address internal constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address internal constant AURA_BOOSTER =
        0xA57b8d98dAE62B26Ec3bcC4a365338157060B234;
    address internal constant WETH_BAL_BALANCER_POOL =
        0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;

    bytes32 internal constant WETH_3POOL_BALANCER_POOL_ID =
        0x08775ccb6674d6bdceb0797c364c2653ed84f3840002000000000000000004f0;
    bytes32 internal constant STABLE_POOL_BALANCER_POOL_ID =
        0x79c58f70905f734641735bc61e45c19dd9ad60bc0000000000000000000004e7;
    bytes32 internal constant WETH_AURA_BALANCER_POOL_ID =
        0xcfca23ca9ca720b6e98e3eb9b6aa0ffc4a5c08b9000200000000000000000274;
    bytes32 internal constant WETH_BAL_BALANCER_POOL_ID =
        0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014;

    uint32 internal constant TWAP_RANGE_SECS = 1800;
    uint256 public slippage;

    uint256 public AURA_PID;
    address public AURA_WETH_REWARDS;

    uint256 private WANT_DECIMALS;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(address _vault, address _strategist) external {
        _initialize(_vault, _strategist, _strategist, _strategist);

        want.safeApprove(address(balancerVault), type(uint256).max);
        IERC20(BAL).safeApprove(address(balancerVault), type(uint256).max);
        IERC20(AURA).safeApprove(address(balancerVault), type(uint256).max);
        IERC20(WETH).safeApprove(address(balancerVault), type(uint256).max);
        IERC20(WETH_AURA_BALANCER_POOL).safeApprove(
            address(balancerVault),
            type(uint256).max
        );
        IERC20(WETH_AURA_BALANCER_POOL).safeApprove(
            AURA_BOOSTER,
            type(uint256).max
        );
        WANT_DECIMALS = ERC20(address(want)).decimals();

        slippage = 9700; // 3%

        AURA_PID = 100;
        AURA_WETH_REWARDS = 0x1204f5060bE8b716F5A62b4Df4cE32acD01a69f5;
    }

    function name() external pure override returns (string memory) {
        return "StrategyAuraWETH";
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    function setAuraPid(uint256 _pid) external onlyStrategist {
        AURA_PID = _pid;
    }

    function setAuraWethRewards(
        address _auraWethRewards
    ) external onlyStrategist {
        AURA_WETH_REWARDS = _auraWethRewards;
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfUnstakedBpt() public view returns (uint256) {
        return IERC20(WETH_AURA_BALANCER_POOL).balanceOf(address(this));
    }

    function balRewards() public view returns (uint256) {
        return IConvexRewards(AURA_WETH_REWARDS).earned(address(this));
    }

    function balanceOfAuraBpt() public view returns (uint256) {
        return IERC20(AURA_WETH_REWARDS).balanceOf(address(this));
    }

    function auraRewards(uint256 balTokens) public view returns (uint256) {
        return AuraRewardsMath.convertCrvToCvx(balTokens);
    }

    function auraBptToBpt(uint _amountAuraBpt) public pure returns (uint256) {
        return _amountAuraBpt;
    }

    function auraToWant(uint256 auraTokens) public view returns (uint256) {
        uint256 scaledAmount = Utils.scaleDecimals(
            auraTokens,
            ERC20(AURA),
            ERC20(address(want))
        );
        return scaledAmount.mul(getAuraPrice()).div(10 ** WANT_DECIMALS);
    }

    function balToWant(uint256 balTokens) public view returns (uint256) {
        uint256 scaledAmount = Utils.scaleDecimals(
            balTokens,
            ERC20(AURA),
            ERC20(address(want))
        );
        return scaledAmount.mul(getBalPrice()).div(10 ** WANT_DECIMALS);
    }

    function wantToBpt(
        uint _amountWant
    ) public view virtual returns (uint _amount) {
        uint256 oneBptPrice = bptToWant(1 ether);
        uint256 bptAmountUnscaled = (_amountWant * 10 ** WANT_DECIMALS) /
            oneBptPrice;
        return
            Utils.scaleDecimals(
                bptAmountUnscaled,
                ERC20(address(want)),
                ERC20(WETH_AURA_BALANCER_POOL)
            );
    }

    function bptToWant(uint bptTokens) public view returns (uint _amount) {
        uint scaledAmount = Utils.scaleDecimals(
            bptTokens,
            ERC20(WETH_AURA_BALANCER_POOL),
            ERC20(address(want))
        );
        return scaledAmount.mul(getBptPrice()).div(10 ** WANT_DECIMALS);
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();

        uint256 bptTokens = balanceOfUnstakedBpt() +
            auraBptToBpt(balanceOfAuraBpt());
        _wants += bptToWant(bptTokens);
        uint256 balRewardTokens = balRewards();
        uint256 balTokens = balRewardTokens +
            ERC20(BAL).balanceOf(address(this));
        if (balTokens > 0) {
            _wants += balToWant(balTokens);
        }

        uint256 auraTokens = auraRewards(balRewardTokens) +
            ERC20(AURA).balanceOf(address(this));
        if (auraTokens > 0) {
            _wants += auraToWant(auraTokens);
        }

        return _wants;
    }

    function getBalPrice() public view returns (uint256 price) {
        address priceOracle = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: TWAP_RANGE_SECS,
            ago: 0
        });
        uint256[] memory results = IBalancerPriceOracle(priceOracle)
            .getTimeWeightedAverage(queries);
        price = 1e36 / results[0];
        return ethToWant(price);
    }

    function getAuraPrice() public view returns (uint256 price) {
        address priceOracle = 0xc29562b045D80fD77c69Bec09541F5c16fe20d9d;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: TWAP_RANGE_SECS,
            ago: 0
        });
        uint256[] memory results;
        results = IBalancerPriceOracle(priceOracle).getTimeWeightedAverage(
            queries
        );
        price = results[0];
        return ethToWant(price);
    }

    modifier ensureNotInVaultContext() {
        (, bytes memory revertData) = address(balancerVault).staticcall{
            gas: 10_000
        }(abi.encodeWithSelector(balancerVault.manageUserBalance.selector, 0));
        require(
            revertData.length == 0,
            "AuraWETHStrategy::ensureNotInVaultContext"
        );

        _;
    }

    /// @notice Safely returns price of LP WETH-50/AURA-50 BPT token in arbitrary want tokens.
    /// @dev This function is intended to be safe against flash loan attacks.
    /// @dev Inspired by formula from Balancer docs: https://docs.balancer.fi/concepts/advanced/valuing-bpt/valuing-bpt.html
    /// @dev Protected by Balancer's recommended way against read-only reentrancy from VaultReentrancyLib.
    /// @return price Price of LP BPT token in USDC want tokens.
    function getBptPrice()
        public
        view
        ensureNotInVaultContext
        returns (uint256 price)
    {
        uint256 invariant = IBalancerPool(WETH_AURA_BALANCER_POOL)
            .getInvariant();
        uint256 totalSupply = IERC20(WETH_AURA_BALANCER_POOL).totalSupply();
        uint256 ratio = (invariant * 1e18) / totalSupply;

        uint256 auraComponent = Math.sqrt(2 * getAuraPrice());
        uint256 wethComponent = Math.sqrt(2 * ethToWant(1 ether));

        return
            (Utils.scaleDecimals(ratio, ERC20(WETH), ERC20(address(want))) *
                auraComponent *
                wethComponent) / (10 ** WANT_DECIMALS);
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;

        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }

        uint256 _liquidWant = balanceOfWant();
        uint256 _amountNeeded = _debtOutstanding + _profit;
        if (_liquidWant <= _amountNeeded) {
            withdrawSome(_amountNeeded - _liquidWant);
            _liquidWant = balanceOfWant();
        }

        // enough to pay profit (partial or full) only
        if (_liquidWant <= _profit) {
            _profit = _liquidWant;
            _debtPayment = 0;
            // enough to pay for all profit and _debtOutstanding (partial or full)
        } else {
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }

        if (balRewards() > 0) {
            IConvexRewards(AURA_WETH_REWARDS).getReward(address(this), true);
        }
        _sellBalAndAura(IERC20(BAL).balanceOf(address(this)), 0);

        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal > _debtOutstanding) {
            uint256 _excessWant = _wantBal - _debtOutstanding;

            if (_excessWant > 0) {
                IBalancerV2Vault.BatchSwapStep[]
                    memory swaps = new IBalancerV2Vault.BatchSwapStep[](2);

                swaps[0] = IBalancerV2Vault.BatchSwapStep({
                    poolId: STABLE_POOL_BALANCER_POOL_ID,
                    assetInIndex: 0,
                    assetOutIndex: 1,
                    amount: _wantBal,
                    userData: abi.encode(0)
                });

                swaps[1] = IBalancerV2Vault.BatchSwapStep({
                    poolId: WETH_3POOL_BALANCER_POOL_ID,
                    assetInIndex: 1,
                    assetOutIndex: 2,
                    amount: 0,
                    userData: abi.encode(0)
                });

                address[] memory assets = new address[](3);
                assets[0] = address(want);
                assets[1] = STABLE_POOL_BALANCER_POOL;
                assets[2] = WETH;

                uint256 wethExpected = (_excessWant * 10 ** WANT_DECIMALS) /
                    ethToWant(1 ether);

                int[] memory limits = new int[](3);
                limits[0] = int(_excessWant);
                limits[1] = 0;
                limits[2] = -1 * int((wethExpected * slippage) / 10000);

                balancerVault.batchSwap(
                    IBalancerV2Vault.SwapKind.GIVEN_IN,
                    swaps,
                    assets,
                    getFundManagement(),
                    limits,
                    block.timestamp
                );
            }
        }

        uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
        uint256 auraBalance = IERC20(AURA).balanceOf(address(this));
        if (wethBalance > 0) {
            uint256[] memory _amountsIn = new uint256[](2);
            _amountsIn[0] = wethBalance;
            _amountsIn[1] = auraBalance;

            address[] memory _assets = new address[](2);
            _assets[0] = WETH;
            _assets[1] = AURA;

            uint256[] memory _maxAmountsIn = new uint256[](2);
            _maxAmountsIn[0] = wethBalance;
            _maxAmountsIn[1] = auraBalance;

            uint256 _bptExpected = (ethToWant(wethBalance) /
                bptToWant(1 ether)) * (10 ** WANT_DECIMALS);
            bytes memory _userData = abi.encode(
                IBalancerV2Vault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
                _amountsIn,
                (_bptExpected * slippage) / 10000
            );

            IBalancerV2Vault.JoinPoolRequest memory _request;
            _request = IBalancerV2Vault.JoinPoolRequest({
                assets: _assets,
                maxAmountsIn: _maxAmountsIn,
                userData: _userData,
                fromInternalBalance: false
            });

            balancerVault.joinPool({
                poolId: WETH_AURA_BALANCER_POOL_ID,
                sender: address(this),
                recipient: payable(address(this)),
                request: _request
            });
        }

        if (balanceOfUnstakedBpt() > 0) {
            bool auraSuccess = IConvexDeposit(AURA_BOOSTER).depositAll(
                AURA_PID, // PID
                true // stake
            );
            require(auraSuccess, "Aura deposit failed");
        }
    }

    function _sellBalAndAura(uint256 _balAmount, uint256 _auraAmount) internal {
        if (_auraAmount > 0) {
            IBalancerV2Vault.BatchSwapStep[]
                memory swaps = new IBalancerV2Vault.BatchSwapStep[](3);

            swaps[0] = IBalancerV2Vault.BatchSwapStep({
                poolId: WETH_AURA_BALANCER_POOL_ID,
                assetInIndex: 0,
                assetOutIndex: 1,
                amount: _auraAmount,
                userData: abi.encode(0)
            });

            swaps[1] = IBalancerV2Vault.BatchSwapStep({
                poolId: WETH_3POOL_BALANCER_POOL_ID,
                assetInIndex: 1,
                assetOutIndex: 2,
                amount: 0,
                userData: abi.encode(0)
            });

            swaps[2] = IBalancerV2Vault.BatchSwapStep({
                poolId: STABLE_POOL_BALANCER_POOL_ID,
                assetInIndex: 2,
                assetOutIndex: 3,
                amount: 0,
                userData: abi.encode(0)
            });

            address[] memory assets = new address[](4);
            assets[0] = AURA;
            assets[1] = WETH;
            assets[2] = STABLE_POOL_BALANCER_POOL;
            assets[3] = address(want);

            int[] memory limits = new int[](4);
            limits[0] = int256(_auraAmount);
            limits[3] =
                (-1) *
                int((auraToWant(_auraAmount) * slippage) / 10000);

            balancerVault.batchSwap(
                IBalancerV2Vault.SwapKind.GIVEN_IN,
                swaps,
                assets,
                getFundManagement(),
                limits,
                block.timestamp
            );
        }

        if (_balAmount > 0) {
            IBalancerV2Vault.BatchSwapStep[]
                memory swaps = new IBalancerV2Vault.BatchSwapStep[](3);

            swaps[0] = IBalancerV2Vault.BatchSwapStep({
                poolId: WETH_BAL_BALANCER_POOL_ID,
                assetInIndex: 0,
                assetOutIndex: 1,
                amount: _balAmount,
                userData: abi.encode(0)
            });

            swaps[1] = IBalancerV2Vault.BatchSwapStep({
                poolId: WETH_3POOL_BALANCER_POOL_ID,
                assetInIndex: 1,
                assetOutIndex: 2,
                amount: 0,
                userData: abi.encode(0)
            });

            swaps[2] = IBalancerV2Vault.BatchSwapStep({
                poolId: STABLE_POOL_BALANCER_POOL_ID,
                assetInIndex: 2,
                assetOutIndex: 3,
                amount: 0,
                userData: abi.encode(0)
            });

            address[] memory assets = new address[](4);
            assets[0] = BAL;
            assets[1] = WETH;
            assets[2] = STABLE_POOL_BALANCER_POOL;
            assets[3] = address(want);

            int[] memory limits = new int[](4);
            limits[0] = int256(_balAmount);
            limits[3] = (-1) * int((balToWant(_balAmount) * slippage) / 10000);

            balancerVault.batchSwap(
                IBalancerV2Vault.SwapKind.GIVEN_IN,
                swaps,
                assets,
                getFundManagement(),
                limits,
                block.timestamp
            );
        }
    }

    function withdrawSome(uint256 _amountNeeded) internal {
        if (_amountNeeded == 0) {
            return;
        }
        uint256 balRewardTokens = balRewards();
        uint256 balTokens = balRewardTokens +
            ERC20(BAL).balanceOf(address(this));
        uint256 auraTokens = auraRewards(balRewardTokens) +
            ERC20(AURA).balanceOf(address(this));
        uint256 rewardsTotal = balToWant(balTokens) + auraToWant(auraTokens);

        if (rewardsTotal >= _amountNeeded) {
            IConvexRewards(AURA_WETH_REWARDS).getReward(address(this), true);
            _sellBalAndAura(
                IERC20(BAL).balanceOf(address(this)),
                IERC20(AURA).balanceOf(address(this))
            );
        } else {
            uint256 bptToUnstake = Math.min(
                wantToBpt(_amountNeeded - rewardsTotal),
                balanceOfAuraBpt()
            );

            if (bptToUnstake > 0) {
                _exitPosition(bptToUnstake);
            }
        }
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal < _amountNeeded) {
            withdrawSome(_amountNeeded - _wantBal);
            _wantBal = balanceOfWant();
        }

        if (_amountNeeded > _wantBal) {
            _liquidatedAmount = _wantBal;
            _loss = _amountNeeded - _wantBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(IERC20(AURA_WETH_REWARDS).balanceOf(address(this)));
        return want.balanceOf(address(this));
    }

    function _sellWethForWant() internal {
        uint256 wethBal = IERC20(WETH).balanceOf(address(this));

        if (wethBal > 0) {
            IBalancerV2Vault.BatchSwapStep[]
                memory swaps = new IBalancerV2Vault.BatchSwapStep[](2);

            swaps[0] = IBalancerV2Vault.BatchSwapStep({
                poolId: WETH_3POOL_BALANCER_POOL_ID,
                assetInIndex: 0,
                assetOutIndex: 1,
                amount: wethBal,
                userData: abi.encode(0)
            });

            swaps[1] = IBalancerV2Vault.BatchSwapStep({
                poolId: STABLE_POOL_BALANCER_POOL_ID,
                assetInIndex: 1,
                assetOutIndex: 2,
                amount: 0,
                userData: abi.encode(0)
            });

            address[] memory assets = new address[](3);
            assets[0] = WETH;
            assets[1] = STABLE_POOL_BALANCER_POOL;
            assets[2] = address(want);

            int[] memory limits = new int[](3);
            limits[0] = int256(wethBal);
            limits[2] = (-1) * int((ethToWant(wethBal) * slippage) / 10000);

            balancerVault.batchSwap(
                IBalancerV2Vault.SwapKind.GIVEN_IN,
                swaps,
                assets,
                getFundManagement(),
                limits,
                block.timestamp
            );
        }
    }

    function _exitPosition(uint256 bptAmount) internal {
        IConvexRewards(AURA_WETH_REWARDS).withdrawAndUnwrap(bptAmount, true);

        _sellBalAndAura(
            IERC20(BAL).balanceOf(address(this)),
            IERC20(AURA).balanceOf(address(this))
        );

        uint256 wethAmount = (bptToWant(bptAmount) * 10 ** WANT_DECIMALS) /
            ethToWant(1 ether);
        uint256 wethScaled = Utils.scaleDecimals(
            wethAmount,
            ERC20(address(want)),
            ERC20(WETH)
        );

        address[] memory _assets = new address[](2);
        _assets[0] = WETH;
        _assets[1] = AURA;

        uint256[] memory _minAmountsOut = new uint256[](2);
        _minAmountsOut[0] = (wethScaled * slippage) / 10000;
        _minAmountsOut[1] = 0;

        bytes memory userData = abi.encode(
            IBalancerV2Vault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
            bptAmount,
            0 // exitTokenIndex
        );

        IBalancerV2Vault.ExitPoolRequest memory request;
        request = IBalancerV2Vault.ExitPoolRequest({
            assets: _assets,
            minAmountsOut: _minAmountsOut,
            userData: userData,
            toInternalBalance: false
        });

        balancerVault.exitPool({
            poolId: WETH_AURA_BALANCER_POOL_ID,
            sender: address(this),
            recipient: payable(address(this)),
            request: request
        });

        _sellWethForWant();
    }

    function prepareMigration(address _newStrategy) internal override {
        IConvexRewards auraPool = IConvexRewards(AURA_WETH_REWARDS);
        auraPool.withdrawAndUnwrap(auraPool.balanceOf(address(this)), true);

        uint256 auraBal = IERC20(AURA).balanceOf(address(this));
        if (auraBal > 0) {
            IERC20(AURA).safeTransfer(_newStrategy, auraBal);
        }
        uint256 balancerBal = IERC20(BAL).balanceOf(address(this));
        if (balancerBal > 0) {
            IERC20(BAL).safeTransfer(_newStrategy, balancerBal);
        }
        uint256 bptBal = IERC20(WETH_AURA_BALANCER_POOL).balanceOf(
            address(this)
        );
        if (bptBal > 0) {
            IERC20(WETH_AURA_BALANCER_POOL).safeTransfer(_newStrategy, bptBal);
        }
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](4);
        protected[0] = AURA_WETH_REWARDS;
        protected[1] = WETH_AURA_BALANCER_POOL;
        protected[2] = BAL;
        protected[3] = AURA;
        return protected;
    }

    function ethToWant(
        uint256 _amtInWei
    ) public view override returns (uint256) {
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: TWAP_RANGE_SECS,
            ago: 0
        });

        uint256[] memory results;
        results = IBalancerPriceOracle(USDC_WETH_BALANCER_POOL)
            .getTimeWeightedAverage(queries);

        return
            Utils.scaleDecimals(
                (_amtInWei * results[0]) / 1 ether,
                ERC20(WETH),
                ERC20(address(want))
            );
    }

    function getFundManagement()
        internal
        view
        returns (IBalancerV2Vault.FundManagement memory fundManagement)
    {
        fundManagement = IBalancerV2Vault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {BaseStrategy, StrategyParams, VaultAPI} from "@yearn-protocol/contracts/BaseStrategy.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import "../integrations/balancer/IBalancerPriceOracle.sol";
import "../integrations/curve/ICurve.sol";
import "../integrations/convex/IConvexRewards.sol";
import "../integrations/convex/IConvexDeposit.sol";

import "../utils/Utils.sol";
import "../utils/CVXRewards.sol";

contract CVXStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    address internal constant USDC_ETH_UNI_V3_POOL =
        0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;
    address internal constant CRV_USDC_UNI_V3_POOL =
        0x9445bd19767F73DCaE6f2De90e6cd31192F62589;
    address internal constant CVX_USDC_UNI_V3_POOL =
        0x575e96f61656b275CA1e0a67d9B68387ABC1d09C;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address internal constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

    address internal constant CURVE_SWAP_ROUTER =
        0x99a58482BD75cbab83b27EC03CA68fF489b5788f;
    address internal constant CURVE_CVX_ETH_POOL =
        0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4;
    address internal constant CURVE_CVX_ETH_LP =
        0x3A283D9c08E8b55966afb64C515f5143cf907611;
    address internal constant ETH_CVX_CONVEX_DEPOSIT =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address internal constant ETH_CVX_CONVEX_CRV_REWARDS =
        0xb1Fb0BA0676A1fFA83882c7F4805408bA232C1fA;
    address internal constant CONVEX_CVX_REWARD_POOL =
        0x834B9147Fd23bF131644aBC6e557Daf99C5cDa15;

    uint32 internal constant TWAP_RANGE_SECS = 1800;
    uint256 public slippage;

    uint256 private WANT_DECIMALS;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(address _vault, address _strategist) external {
        _initialize(_vault, _strategist, _strategist, _strategist);

        want.safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(CRV).safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(CVX).safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(CURVE_CVX_ETH_LP).safeApprove(
            ETH_CVX_CONVEX_DEPOSIT,
            type(uint256).max
        );
        IERC20(CURVE_CVX_ETH_LP).safeApprove(
            CURVE_CVX_ETH_POOL,
            type(uint256).max
        );
        WANT_DECIMALS = ERC20(address(want)).decimals();
        slippage = 9800; // 2%
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    function name() external pure override returns (string memory) {
        return "StrategyCVX";
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfCurveLPUnstaked() public view returns (uint256) {
        return ERC20(CURVE_CVX_ETH_LP).balanceOf(address(this));
    }

    function balanceOfCurveLPStaked() public view returns (uint256) {
        return
            IConvexRewards(ETH_CVX_CONVEX_CRV_REWARDS).balanceOf(address(this));
    }

    function balanceOfCrvRewards() public view virtual returns (uint256) {
        return IConvexRewards(ETH_CVX_CONVEX_CRV_REWARDS).earned(address(this));
    }

    function balanceOfCvxRewards(
        uint256 crvRewards
    ) public view virtual returns (uint256) {
        return
            IConvexRewards(CONVEX_CVX_REWARD_POOL).earned(address(this)) +
            CVXRewardsMath.convertCrvToCvx(crvRewards);
    }

    function curveLPToWant(uint256 _lpTokens) public view returns (uint256) {
        uint256 ethAmount = (
            _lpTokens > 0
                ? (ICurve(CURVE_CVX_ETH_POOL).lp_price() * _lpTokens) / 1e18
                : 0
        );
        return ethToWant(ethAmount);
    }

    function wantToCurveLP(
        uint256 _want
    ) public view virtual returns (uint256) {
        uint256 oneCurveLPPrice = curveLPToWant(1e18);
        return (_want * 1e18) / oneCurveLPPrice;
    }

    function _withdrawSome(uint256 _amountNeeded) internal {
        if (_amountNeeded == 0) {
            return;
        }
        uint256 earnedCrv = balanceOfCrvRewards();
        uint256 earnedCvx = balanceOfCvxRewards(earnedCrv);
        uint256 totalCrv = earnedCrv + ERC20(CRV).balanceOf(address(this));
        uint256 totalCvx = earnedCvx + ERC20(CVX).balanceOf(address(this));
        uint256 rewardsTotal = crvToWant(totalCrv) + cvxToWant(totalCvx);

        if (rewardsTotal >= _amountNeeded) {
            IConvexRewards(ETH_CVX_CONVEX_CRV_REWARDS).getReward(
                address(this),
                true
            );
            _sellCrvAndCvx(
                ERC20(CRV).balanceOf(address(this)),
                ERC20(CVX).balanceOf(address(this))
            );
        } else {
            uint256 lpTokensToWithdraw = Math.min(
                wantToCurveLP(_amountNeeded - rewardsTotal),
                balanceOfCurveLPStaked()
            );
            _exitPosition(lpTokensToWithdraw);
        }
    }

    function ethToWant(
        uint256 _amtInWei
    ) public view override returns (uint256) {
        uint256 scaledPrice = (ICurve(
            0x7F86Bf177Dd4F3494b841a37e810A34dD56c829B
        ).price_oracle(1) * _amtInWei) / 1e18;
        return
            Utils.scaleDecimals(scaledPrice, ERC20(WETH), ERC20(address(want)));
    }

    function crvToWant(uint256 crvTokens) public view returns (uint256) {
        uint256 scaledPrice = (ICurve(
            0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14
        ).price_oracle(1) * crvTokens) / 1e18;
        return
            Utils.scaleDecimals(scaledPrice, ERC20(CRV), ERC20(address(want)));
    }

    function cvxToWant(uint256 cvxTokens) public view returns (uint256) {
        uint256 scaledPrice = (ICurve(
            0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4
        ).price_oracle() * cvxTokens) / 1e18;
        return ethToWant(scaledPrice);
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();
        _wants += curveLPToWant(
            balanceOfCurveLPStaked() + balanceOfCurveLPUnstaked()
        );

        uint256 earnedCrv = balanceOfCrvRewards();
        uint256 earnedCvx = balanceOfCvxRewards(earnedCrv);
        uint256 totalCrv = earnedCrv + ERC20(CRV).balanceOf(address(this));
        uint256 totalCvx = earnedCvx + ERC20(CVX).balanceOf(address(this));

        _wants += crvToWant(totalCrv);
        _wants += cvxToWant(totalCvx);
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;

        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }
        uint256 _liquidWant = balanceOfWant();
        uint256 _amountNeeded = _debtOutstanding + _profit;
        if (_liquidWant <= _amountNeeded) {
            _withdrawSome(_amountNeeded - _liquidWant);
            _liquidWant = balanceOfWant();
        }
        // enough to pay profit (partial or full) only
        if (_liquidWant <= _profit) {
            _profit = _liquidWant;
            _debtPayment = 0;
            // enough to pay for all profit and _debtOutstanding (partial or full)
        } else {
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }
        IConvexRewards(ETH_CVX_CONVEX_CRV_REWARDS).getReward(
            address(this),
            true
        );
        _sellCrvAndCvx(
            ERC20(CRV).balanceOf(address(this)),
            ERC20(CVX).balanceOf(address(this))
        );

        uint256 _wantBal = balanceOfWant();
        if (_wantBal > _debtOutstanding) {
            uint256 _excessWant = _wantBal - _debtOutstanding;
            uint256 _ethExpected = (_excessWant * (10 ** WANT_DECIMALS)) /
                ethToWant(1 ether);
            uint256 _ethExpectedScaled = Utils.scaleDecimals(
                _ethExpected,
                ERC20(address(want)),
                ERC20(WETH)
            );

            address[9] memory _route = [
                address(want),
                0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7, // 3pool
                0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
                0xD51a44d3FaE010294C616388b506AcdA1bfAAE46, // tricrypto2 pool
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // ETH
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(1), uint256(2), uint256(1)], // USDC -> USDT, stable swap exchange
                [uint256(0), uint256(2), uint256(3)], // USDT -> ETH, cryptoswap exchange
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];
            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                _excessWant,
                (_ethExpectedScaled * slippage) / 10000
            );
        }

        if (address(this).balance > 0) {
            uint256 ethPrice = ethToWant(address(this).balance);
            uint256 lpPrice = curveLPToWant(1e18);
            uint256 lpTokensExpectedUnscaled = (ethPrice *
                (10 ** WANT_DECIMALS)) / lpPrice;
            uint256 lpTokensExpectedScaled = Utils.scaleDecimals(
                lpTokensExpectedUnscaled,
                ERC20(address(want)),
                ERC20(CURVE_CVX_ETH_LP)
            );

            uint256[2] memory amounts = [address(this).balance, uint256(0)];
            ICurve(CURVE_CVX_ETH_POOL).add_liquidity{
                value: address(this).balance
            }(amounts, (lpTokensExpectedScaled * slippage) / 10000, true);
        }
        if (balanceOfCurveLPUnstaked() > 0) {
            require(
                IConvexDeposit(ETH_CVX_CONVEX_DEPOSIT).depositAll(
                    uint256(64),
                    true
                ),
                "Convex staking failed"
            );
        }
    }

    function _cvxToCrv(uint256 cvxTokens) internal view returns (uint256) {
        uint256 wantAmount = cvxToWant(cvxTokens);
        uint256 oneCrv = crvToWant(1 ether);
        return (wantAmount * (10 ** WANT_DECIMALS)) / oneCrv;
    }

    function _sellCrvAndCvx(uint256 _crvAmount, uint256 _cvxAmount) internal {
        if (_cvxAmount > 0) {
            address[9] memory _route = [
                CVX, // CVX
                0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4, // cvxeth pool
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // ETH
                0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14, // TriCRV pool
                CRV, // CRV
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(1), uint256(0), uint256(3)], // CVX -> WETH, cryptoswap exchange
                [uint256(1), uint256(2), uint256(3)], // WETH -> CRV, cryptoswap exchange
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];
            uint256 _expected = (_cvxToCrv(_cvxAmount) * slippage) / 10000;

            _crvAmount += ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                _cvxAmount,
                _expected
            );
        }

        if (_crvAmount > 0) {
            address[9] memory _route = [
                0xD533a949740bb3306d119CC777fa900bA034cd52, // CRV
                0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14, // TriCRV pool
                0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E, // crvUSD
                0x4DEcE678ceceb27446b35C672dC7d61F30bAD69E, // crvUSD/USDC pool
                address(want),
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(2), uint256(0), uint256(3)], // CRV -> crvUSD, cryptoswap exchange
                [uint256(1), uint256(0), uint256(1)], // crvUSD -> USDC, stable swap exchange
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];
            uint256 _expected = (crvToWant(_crvAmount) * slippage) / 10000;

            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                _crvAmount,
                _expected
            );
        }
    }

    function _exitPosition(uint256 _stakedLpTokens) internal {
        IConvexRewards(ETH_CVX_CONVEX_CRV_REWARDS).withdrawAndUnwrap(
            _stakedLpTokens,
            true
        );

        _sellCrvAndCvx(
            ERC20(CRV).balanceOf(address(this)),
            ERC20(CVX).balanceOf(address(this))
        );

        uint256 lpTokens = ERC20(CURVE_CVX_ETH_LP).balanceOf(address(this));
        uint256 withdrawAmount = ICurve(CURVE_CVX_ETH_POOL)
            .calc_withdraw_one_coin(lpTokens, 0);
        ICurve(CURVE_CVX_ETH_POOL).remove_liquidity_one_coin(
            lpTokens,
            0,
            (withdrawAmount * slippage) / 10000,
            true
        );

        uint256 ethAmount = address(this).balance;
        if (ethAmount > 0) {
            address[9] memory _route = [
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // ETH
                0xD51a44d3FaE010294C616388b506AcdA1bfAAE46, // tricrypto2 pool
                0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
                0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7, // 3pool
                address(want), // USDC
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(2), uint256(0), uint256(3)], // ETH -> USDT, cryptoswap exchange
                [uint256(2), uint256(1), uint256(1)], // USDT -> USDC, stable swap exchange
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];
            uint256 _expected = (ethToWant(ethAmount) * slippage) / 10000;
            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple{
                value: ethAmount
            }(_route, _swap_params, ethAmount, _expected);
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(balanceOfCurveLPStaked());
        return want.balanceOf(address(this));
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal >= _amountNeeded) {
            return (_amountNeeded, 0);
        }

        _withdrawSome(_amountNeeded - _wantBal);
        _wantBal = want.balanceOf(address(this));

        if (_amountNeeded > _wantBal) {
            _liquidatedAmount = _wantBal;
            _loss = _amountNeeded - _wantBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        IConvexRewards(ETH_CVX_CONVEX_CRV_REWARDS).withdrawAndUnwrap(
            balanceOfCurveLPStaked(),
            true
        );
        IERC20(CRV).safeTransfer(
            _newStrategy,
            IERC20(CRV).balanceOf(address(this))
        );
        IERC20(CVX).safeTransfer(
            _newStrategy,
            IERC20(CVX).balanceOf(address(this))
        );
        IERC20(CURVE_CVX_ETH_LP).safeTransfer(
            _newStrategy,
            IERC20(CURVE_CVX_ETH_LP).balanceOf(address(this))
        );
        uint256 ethBal = address(this).balance;
        if (ethBal > 0) {
            payable(_newStrategy).transfer(ethBal);
        }
    }

    function protectedTokens()
        internal
        pure
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](3);
        protected[0] = CVX;
        protected[1] = CRV;
        protected[2] = CURVE_CVX_ETH_LP;
        return protected;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {BaseStrategy, StrategyParams} from "@yearn-protocol/contracts/BaseStrategy.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../integrations/weth/IWETH.sol";
import "../integrations/frax/IFraxMinter.sol";
import "../integrations/frax/ISfrxEth.sol";
import "../integrations/curve/ICurve.sol";

contract FraxStrategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;

    address internal constant fraxMinter =
        0xbAFA44EFE7901E04E39Dad13167D089C559c1138;
    address internal constant sfrxEth =
        0xac3E018457B222d93114458476f3E3416Abbe38F;
    address internal constant frxEth =
        0x5E8422345238F34275888049021821E8E08CAa1f;
    address internal constant frxEthCurvePool =
        0xa1F8A6807c402E4A15ef4EBa36528A3FED24E577;
    address internal constant curveSwapRouter =
        0x99a58482BD75cbab83b27EC03CA68fF489b5788f;

    uint256 public slippage;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(address _vault, address _strategist) external {
        _initialize(_vault, _strategist, _strategist, _strategist);

        IERC20(frxEth).safeApprove(curveSwapRouter, type(uint256).max);
        slippage = 9900; // 1%
    }

    function name() external view override returns (string memory) {
        return "StrategyFrax";
    }

    /// @notice Balance of want sitting in our strategy.
    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function estimatedTotalAssets()
        public
        view
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();
        _wants += sfrxToWant(IERC20(sfrxEth).balanceOf(address(this)));
        _wants += frxToWant(IERC20(frxEth).balanceOf(address(this)));
        return _wants;
    }

    function sfrxToWant(uint256 _amount) public view returns (uint256) {
        return frxToWant(ISfrxEth(sfrxEth).previewRedeem(_amount));
    }

    function wantToSfrx(uint256 _amount) public view returns (uint256) {
        return ISfrxEth(sfrxEth).previewWithdraw(wantToFrx(_amount));
    }

    function frxToWant(uint256 _amount) public view returns (uint256) {
        return (ICurve(frxEthCurvePool).price_oracle() * _amount) / 1e18;
    }

    function wantToFrx(uint256 _amount) public view returns (uint256) {
        return (_amount * 1e18) / ICurve(frxEthCurvePool).price_oracle();
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;

        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }

        uint256 _liquidWant = balanceOfWant();
        uint256 _amountNeeded = _debtOutstanding + _profit;
        if (_liquidWant <= _amountNeeded) {
            withdrawSome(_amountNeeded - _liquidWant);
            _liquidWant = balanceOfWant();
        }

        if (_liquidWant <= _profit) {
            // enough to pay profit (partial or full) only
            _profit = _liquidWant;
            _debtPayment = 0;
        } else {
            // enough to pay for all profit and _debtOutstanding (partial or full)
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }

        uint256 _wethBal = want.balanceOf(address(this));
        if (_wethBal > _debtOutstanding) {
            uint256 _excessWeth = _wethBal - _debtOutstanding;
            IWETH(address(want)).withdraw(_excessWeth);
        }
        if (address(this).balance > 0) {
            IFraxMinter(fraxMinter).submitAndDeposit{
                value: address(this).balance
            }(address(this));
        }
    }

    function withdrawSome(uint256 _amountNeeded) internal {
        uint256 sfrxToUnstake = Math.min(
            wantToSfrx(_amountNeeded),
            IERC20(sfrxEth).balanceOf(address(this))
        );
        if (sfrxToUnstake > 0) {
            _exitPosition(sfrxToUnstake);
        }
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wethBal = want.balanceOf(address(this));
        if (_wethBal < _amountNeeded) {
            withdrawSome(_amountNeeded - _wethBal);
            _wethBal = balanceOfWant();
        }

        if (_amountNeeded > _wethBal) {
            _liquidatedAmount = _wethBal;
            _loss = _amountNeeded - _wethBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(IERC20(sfrxEth).balanceOf(address(this)));
        return want.balanceOf(address(this));
    }

    function _exitPosition(uint256 _sfrxToUnstake) internal {
        ISfrxEth(sfrxEth).redeem(_sfrxToUnstake, address(this), address(this));
        _sellAllFrx();
    }

    function _sellAllFrx() internal {
        uint256 _frxAmount = IERC20(frxEth).balanceOf(address(this));
        uint256 _minAmountOut = (frxToWant(_frxAmount) * slippage) / 10000;
        address[9] memory _route = [
            frxEth, // FRX
            frxEthCurvePool, // frxeth pool
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // ETH
            address(want), // no pool for ETH->WETH
            address(want), // wETH
            address(0),
            address(0),
            address(0),
            address(0)
        ];
        uint256[3][4] memory _swap_params = [
            [uint256(1), uint256(0), uint256(1)], // FRX -> ETH, stableswap exchange
            [uint256(0), uint256(0), uint256(15)], // ETH -> WETH, special 15 op
            [uint256(0), uint256(0), uint256(0)],
            [uint256(0), uint256(0), uint256(0)]
        ];
        ICurveSwapRouter(curveSwapRouter).exchange_multiple(
            _route,
            _swap_params,
            _frxAmount,
            _minAmountOut
        );
    }

    function prepareMigration(address _newStrategy) internal override {
        uint256 sfrxBal = IERC20(sfrxEth).balanceOf(address(this));
        if (sfrxBal > 0) {
            IERC20(sfrxEth).safeTransfer(_newStrategy, sfrxBal);
        }
        uint256 frxBal = IERC20(frxEth).balanceOf(address(this));
        if (frxBal > 0) {
            IERC20(frxEth).safeTransfer(_newStrategy, frxBal);
        }
        uint256 ethBal = address(this).balance;
        if (ethBal > 0) {
            payable(_newStrategy).transfer(ethBal);
        }
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](2);
        protected[0] = sfrxEth;
        protected[1] = frxEth;
        return protected;
    }

    function ethToWant(
        uint256 _amtInWei
    ) public view virtual override returns (uint256) {
        return _amtInWei;
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {BaseStrategy, StrategyParams, VaultAPI} from "@yearn-protocol/contracts/BaseStrategy.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import "../integrations/balancer/IBalancerPriceOracle.sol";
import "../integrations/curve/ICurve.sol";
import "../integrations/convex/IConvexRewards.sol";
import "../integrations/convex/IConvexDeposit.sol";
import "../integrations/uniswap/v3/IV3SwapRouter.sol";
import "../integrations/frax/IFraxRouter.sol";

import "../utils/Utils.sol";
import "../utils/CVXRewards.sol";

contract FXSStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address internal constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address internal constant FXS = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
    address internal constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;

    address internal constant CURVE_SWAP_ROUTER =
        0x99a58482BD75cbab83b27EC03CA68fF489b5788f;
    address internal constant CONVEX_CVX_REWARD_POOL =
        0xf16Fc1571E9e26Abff127D7790931E99f75A276e;

    address internal constant FXS_FRAX_UNI_V3_POOL =
        0xb64508B9f7b81407549e13DB970DD5BB5C19107F;

    address internal constant CURVE_FXS_POOL =
        0x6a9014FB802dCC5efE3b97Fd40aAa632585636D0;

    address internal constant FXS_CONVEX_DEPOSIT =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address internal constant FXS_CONVEX_CRV_REWARDS =
        0x19F3C877eA278e61fE1304770dbE5D78521792D2;

    address internal constant FRAX_ROUTER_V2 =
        0xC14d550632db8592D1243Edc8B95b0Ad06703867;

    uint32 internal constant TWAP_RANGE_SECS = 1800;
    uint256 public slippage;

    uint256 private WANT_DECIMALS;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(address _vault, address _strategist) external {
        _initialize(_vault, _strategist, _strategist, _strategist);

        IERC20(CRV).safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(CVX).safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(CURVE_FXS_POOL).safeApprove(
            FXS_CONVEX_DEPOSIT,
            type(uint256).max
        );
        IERC20(FXS).safeApprove(CURVE_FXS_POOL, type(uint256).max);
        IERC20(FRAX).safeApprove(FRAX_ROUTER_V2, type(uint256).max);
        IERC20(FRAX).safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(FXS).safeApprove(FRAX_ROUTER_V2, type(uint256).max);

        want.safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        WANT_DECIMALS = ERC20(address(want)).decimals();
        slippage = 9800; // 2%
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    function name() external pure override returns (string memory) {
        return "StrategyFXS";
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfFrax() public view returns (uint256) {
        return IERC20(FRAX).balanceOf(address(this));
    }

    function balanceOfFxs() public view returns (uint256) {
        return IERC20(FXS).balanceOf(address(this));
    }

    function balanceOfCurveLPUnstaked() public view returns (uint256) {
        return ERC20(CURVE_FXS_POOL).balanceOf(address(this));
    }

    function balanceOfCurveLPStaked() public view returns (uint256) {
        return IConvexRewards(FXS_CONVEX_CRV_REWARDS).balanceOf(address(this));
    }

    function balanceOfCrvRewards() public view virtual returns (uint256) {
        return IConvexRewards(FXS_CONVEX_CRV_REWARDS).earned(address(this));
    }

    function balanceOfFxsRewards() public view returns (uint256) {
        return 0;
    }

    function balanceOfCvxRewards(
        uint256 crvRewards
    ) public view virtual returns (uint256) {
        return
            IConvexRewards(CONVEX_CVX_REWARD_POOL).earned(address(this)) +
            CVXRewardsMath.convertCrvToCvx(crvRewards);
    }

    function lpPriceOracle() public view returns (uint256) {
        uint256 virtualPrice = ICurve(CURVE_FXS_POOL).get_virtual_price();
        uint256 priceOracle = ICurve(CURVE_FXS_POOL).price_oracle();
        return (virtualPrice * _sqrtInt(priceOracle)) / 1e18;
    }

    function lpPrice() public view returns (uint256) {
        return ICurve2(CURVE_FXS_POOL).calc_withdraw_one_coin(1e18, int128(0));
    }

    function curveLPToWant(uint256 _lpTokens) public view returns (uint256) {
        uint256 fxsAmount = (
            _lpTokens > 0 ? (lpPrice() * _lpTokens) / 1e18 : 0
        );
        return fxsToWant(fxsAmount);
    }

    function wantToCurveLP(
        uint256 _want
    ) public view virtual returns (uint256) {
        uint256 oneCurveLPPrice = curveLPToWant(1e18);
        return (_want * 1e18) / oneCurveLPPrice;
    }

    function _sqrtInt(uint256 x) internal pure returns (uint256) {
        if (x == 0) {
            return 0;
        }

        uint256 z = (x + 1e18) / 2;
        uint256 y = x;

        for (uint256 i = 0; i < 256; i++) {
            if (z == y) return y;
            y = z;
            z = ((x * 1e18) / z + z) / 2;
        }

        return y;
    }

    function _withdrawSome(uint256 _amountNeeded) internal {
        if (_amountNeeded == 0) {
            return;
        }

        uint256 earnedCrv = balanceOfCrvRewards();
        uint256 earnedCvx = balanceOfCvxRewards(earnedCrv);
        uint256 earnedFxs = balanceOfFxsRewards();
        uint256 totalCrv = earnedCrv + ERC20(CRV).balanceOf(address(this));
        uint256 totalCvx = earnedCvx + ERC20(CVX).balanceOf(address(this));
        uint256 totalFxs = earnedFxs + ERC20(FXS).balanceOf(address(this));
        uint256 rewardsTotal = crvToWant(totalCrv) +
            cvxToWant(totalCvx) +
            fxsToWant(totalFxs);

        if (rewardsTotal >= _amountNeeded) {
            IConvexRewards(FXS_CONVEX_CRV_REWARDS).getReward(
                address(this),
                true
            );
            _sellCrvAndCvx(
                ERC20(CRV).balanceOf(address(this)),
                ERC20(CVX).balanceOf(address(this))
            );
            _sellFxs(ERC20(FXS).balanceOf(address(this)));
        } else {
            uint256 lpTokensToWithdraw = Math.min(
                wantToCurveLP(_amountNeeded - rewardsTotal),
                balanceOfCurveLPStaked()
            );
            _exitPosition(lpTokensToWithdraw);
        }
    }

    function ethToWant(
        uint256 _amtInWei
    ) public view override returns (uint256) {
        uint256 scaledPrice = (ICurve(
            0x7F86Bf177Dd4F3494b841a37e810A34dD56c829B
        ).price_oracle(1) * _amtInWei) / 1e18;
        return
            Utils.scaleDecimals(scaledPrice, ERC20(WETH), ERC20(address(want)));
    }

    function fraxToWant(uint256 fraxTokens) public view returns (uint256) {
        return
            Utils.scaleDecimals(fraxTokens, ERC20(FRAX), ERC20(address(want)));
    }

    function wantToFrax(uint256 wantTokens) public view returns (uint256) {
        return
            Utils.scaleDecimals(wantTokens, ERC20(address(want)), ERC20(FRAX));
    }

    function fraxToFxs(uint256 fraxTokens) public view returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            FXS_FRAX_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            OracleLibrary.getQuoteAtTick(
                meanTick,
                uint128(fraxTokens),
                FRAX,
                FXS
            );
    }

    function fxsToFrax(uint256 fxsTokens) public view returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            FXS_FRAX_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            OracleLibrary.getQuoteAtTick(
                meanTick,
                uint128(fxsTokens),
                FXS,
                FRAX
            );
    }

    function fxsToWant(uint256 fxsTokens) public view returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            FXS_FRAX_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            fraxToWant(
                OracleLibrary.getQuoteAtTick(
                    meanTick,
                    uint128(fxsTokens),
                    FXS,
                    FRAX
                )
            );
    }

    function crvToWant(uint256 crvTokens) public view returns (uint256) {
        uint256 scaledPrice = (ICurve(
            0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14
        ).price_oracle(1) * crvTokens) / 1e18;
        return
            Utils.scaleDecimals(scaledPrice, ERC20(CRV), ERC20(address(want)));
    }

    function cvxToWant(uint256 cvxTokens) public view returns (uint256) {
        uint256 scaledPrice = (ICurve(
            0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4
        ).price_oracle() * cvxTokens) / 1e18;
        return ethToWant(scaledPrice);
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();
        _wants += curveLPToWant(
            balanceOfCurveLPStaked() + balanceOfCurveLPUnstaked()
        );

        uint256 earnedCrv = balanceOfCrvRewards();
        uint256 earnedCvx = balanceOfCvxRewards(earnedCrv);
        uint256 earnedFxs = balanceOfFxsRewards();
        uint256 totalCrv = earnedCrv + ERC20(CRV).balanceOf(address(this));
        uint256 totalCvx = earnedCvx + ERC20(CVX).balanceOf(address(this));
        uint256 totalFxs = earnedFxs + ERC20(FXS).balanceOf(address(this));

        _wants += crvToWant(totalCrv);
        _wants += cvxToWant(totalCvx);
        _wants += fxsToWant(totalFxs);
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;

        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }

        uint256 _liquidWant = balanceOfWant();
        uint256 _amountNeeded = _debtOutstanding + _profit;
        if (_liquidWant <= _amountNeeded) {
            _withdrawSome(_amountNeeded - _liquidWant);
            _liquidWant = balanceOfWant();
        }

        // enough to pay profit (partial or full) only
        if (_liquidWant <= _profit) {
            _profit = _liquidWant;
            _debtPayment = 0;
            // enough to pay for all profit and _debtOutstanding (partial or full)
        } else {
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }

        IConvexRewards(FXS_CONVEX_CRV_REWARDS).getReward(address(this), true);
        _sellCrvAndCvx(
            ERC20(CRV).balanceOf(address(this)),
            ERC20(CVX).balanceOf(address(this))
        );

        uint256 _wantBal = balanceOfWant();

        if (_wantBal > _debtOutstanding) {
            uint256 _excessWant = _wantBal - _debtOutstanding;
            uint256 fraxExpected = (wantToFrax(_excessWant) * slippage) /
                10_000;

            address[9] memory _route = [
                address(want),
                0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2, // fraxusdc pool
                FRAX, // FRAX
                address(0),
                address(0),
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(1), uint256(0), uint256(1)], // USDC -> FRAX, stable swap exchange
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];
            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                _excessWant,
                fraxExpected
            );
        }

        if (balanceOfFrax() > 0) {
            uint256 fraxBalance = balanceOfFrax();
            uint256 fxsExpected = (fraxToFxs(fraxBalance) * slippage) / 10_000;
            address[] memory path = new address[](2);
            path[0] = FRAX;
            path[1] = FXS;

            IUniswapV2Router01V5(FRAX_ROUTER_V2).swapExactTokensForTokens(
                fraxBalance,
                fxsExpected,
                path,
                address(this),
                block.timestamp
            );
        }

        uint256 fxsBalance = ERC20(FXS).balanceOf(address(this));
        if (fxsBalance > 0) {
            uint256 lpExpected = (fxsBalance * 1e18) / lpPrice();
            uint256[2] memory amounts = [fxsBalance, uint256(0)];
            ICurve(CURVE_FXS_POOL).add_liquidity(
                amounts,
                (lpExpected * slippage) / 10000,
                address(this)
            );
        }

        if (balanceOfCurveLPUnstaked() > 0) {
            require(
                IConvexDeposit(FXS_CONVEX_DEPOSIT).depositAll(
                    uint256(203),
                    true
                ),
                "Convex staking failed"
            );
        }
    }

    function _cvxToCrv(uint256 cvxTokens) internal view returns (uint256) {
        uint256 wantAmount = cvxToWant(cvxTokens);
        uint256 oneCrv = crvToWant(1 ether);
        return (wantAmount * (10 ** WANT_DECIMALS)) / oneCrv;
    }

    function _sellCrvAndCvx(uint256 _crvAmount, uint256 _cvxAmount) internal {
        if (_cvxAmount > 0) {
            address[9] memory _route = [
                CVX, // CVX
                0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4, // cvxeth pool
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // ETH
                0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14, // TriCRV pool
                CRV, // CRV
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(1), uint256(0), uint256(3)], // CVX -> WETH, cryptoswap exchange
                [uint256(1), uint256(2), uint256(3)], // WETH -> CRV, cryptoswap exchange
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];
            uint256 _expected = (_cvxToCrv(_cvxAmount) * slippage) / 10000;

            _crvAmount += ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                _cvxAmount,
                _expected
            );
        }

        if (_crvAmount > 0) {
            address[9] memory _route = [
                0xD533a949740bb3306d119CC777fa900bA034cd52, // CRV
                0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14, // TriCRV pool
                0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E, // crvUSD
                0x4DEcE678ceceb27446b35C672dC7d61F30bAD69E, // crvUSD/USDC pool
                address(want),
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(2), uint256(0), uint256(3)], // CRV -> crvUSD, cryptoswap exchange
                [uint256(1), uint256(0), uint256(1)], // crvUSD -> USDC, stable swap exchange
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];
            uint256 _expected = (crvToWant(_crvAmount) * slippage) / 10000;

            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                _crvAmount,
                _expected
            );
        }
    }

    function _exitPosition(uint256 _stakedLpTokens) internal {
        IConvexRewards(FXS_CONVEX_CRV_REWARDS).withdrawAndUnwrap(
            _stakedLpTokens,
            true
        );

        _sellCrvAndCvx(
            ERC20(CRV).balanceOf(address(this)),
            ERC20(CVX).balanceOf(address(this))
        );

        uint256 lpTokens = balanceOfCurveLPUnstaked();
        uint256 withdrawAmount = ICurve2(CURVE_FXS_POOL).calc_withdraw_one_coin(
            lpTokens,
            int128(0)
        );
        ICurve(CURVE_FXS_POOL).remove_liquidity_one_coin(
            lpTokens,
            int128(0),
            (withdrawAmount * slippage) / 10000,
            address(this)
        );

        _sellFxs(ERC20(FXS).balanceOf(address(this)));
    }

    function _sellFxs(uint256 fxsAmount) internal {
        if (fxsAmount > 0) {
            uint256 fraxExpected = (fxsToFrax(fxsAmount) * slippage) / 10_000;
            address[] memory path = new address[](2);
            path[0] = FXS;
            path[1] = FRAX;

            IUniswapV2Router01V5(FRAX_ROUTER_V2).swapExactTokensForTokens(
                fxsAmount,
                fraxExpected,
                path,
                address(this),
                block.timestamp
            );
        }

        uint256 fraxBalance = balanceOfFrax();
        if (fraxBalance > 0) {
            uint256 wantExpected = (fraxToWant(fraxBalance) * slippage) /
                10_000;

            address[9] memory _route = [
                FRAX, // FRAX
                0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2, // fraxusdc pool
                address(want), // USDC
                address(0),
                address(0),
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(0), uint256(1), uint256(1)], // USDC -> FRAX, stable swap exchange
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];
            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                fraxBalance,
                wantExpected
            );
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(balanceOfCurveLPStaked());
        return want.balanceOf(address(this));
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal >= _amountNeeded) {
            return (_amountNeeded, 0);
        }

        _withdrawSome(_amountNeeded - _wantBal);
        _wantBal = want.balanceOf(address(this));

        if (_amountNeeded > _wantBal) {
            _liquidatedAmount = _wantBal;
            _loss = _amountNeeded - _wantBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        IConvexRewards(FXS_CONVEX_CRV_REWARDS).withdrawAndUnwrap(
            balanceOfCurveLPStaked(),
            true
        );
        IERC20(CRV).safeTransfer(
            _newStrategy,
            IERC20(CRV).balanceOf(address(this))
        );
        IERC20(FXS).safeTransfer(
            _newStrategy,
            IERC20(FXS).balanceOf(address(this))
        );
        IERC20(CVX).safeTransfer(
            _newStrategy,
            IERC20(CVX).balanceOf(address(this))
        );
        IERC20(CURVE_FXS_POOL).safeTransfer(
            _newStrategy,
            IERC20(CURVE_FXS_POOL).balanceOf(address(this))
        );
    }

    function protectedTokens()
        internal
        pure
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](4);
        protected[0] = CVX;
        protected[1] = CRV;
        protected[2] = FXS;
        protected[3] = CURVE_FXS_POOL;
        return protected;
    }
}

// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use

pragma solidity ^0.8.18;

import {BaseStrategy, StrategyParams} from "@yearn-protocol/contracts/BaseStrategy.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../integrations/balancer/IBalancerV2Vault.sol";
import "../integrations/balancer/IBalancerPool.sol";
import "../integrations/balancer/IBalancerPriceOracle.sol";
import "../integrations/aura/ICvx.sol";
import "../integrations/aura/IAuraToken.sol";
import "../integrations/aura/IAuraMinter.sol";
import "../integrations/convex/IConvexRewards.sol";
import "../integrations/convex/IConvexDeposit.sol";

import "../utils/AuraMath.sol";
import "../utils/Utils.sol";

contract LidoAuraStrategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using AuraMath for uint256;

    IBalancerV2Vault internal constant balancerVault =
        IBalancerV2Vault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    address internal constant bStethStable =
        0x32296969Ef14EB0c6d29669C550D4a0449130230;
    address internal constant auraToken =
        0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
    address internal constant balToken =
        0xba100000625a3754423978a60c9317c58a424e3D;
    address internal constant auraBooster =
        0xA57b8d98dAE62B26Ec3bcC4a365338157060B234;
    address internal constant wstETH =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    bytes32 internal constant stEthEthPoolId =
        bytes32(
            0x32296969ef14eb0c6d29669c550d4a0449130230000200000000000000000080
        );
    bytes32 internal constant balEthPoolId =
        bytes32(
            0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014
        );
    bytes32 internal constant auraEthPoolId =
        bytes32(
            0xc29562b045d80fd77c69bec09541f5c16fe20d9d000200000000000000000251
        );

    uint256 public bptSlippage;
    uint256 public rewardsSlippage;

    uint256 public AURA_PID;
    address public auraBStethStable;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(address _vault, address _strategist) external {
        _initialize(_vault, _strategist, _strategist, _strategist);

        want.safeApprove(address(balancerVault), type(uint256).max);
        IERC20(bStethStable).safeApprove(auraBooster, type(uint256).max);
        IERC20(auraToken).safeApprove(
            address(balancerVault),
            type(uint256).max
        );
        IERC20(balToken).safeApprove(address(balancerVault), type(uint256).max);

        bptSlippage = 9850; // 1.5%
        rewardsSlippage = 9700; // 3%

        AURA_PID = 115;
        auraBStethStable = 0x59D66C58E83A26d6a0E35114323f65c3945c89c1;
    }

    function name() external view override returns (string memory) {
        return "StrategyLidoAura";
    }

    function setAuraPid(uint256 _pid) external onlyStrategist {
        AURA_PID = _pid;
    }

    function setAuraBStethStable(
        address _auraBStethStable
    ) external onlyStrategist {
        auraBStethStable = _auraBStethStable;
    }

    /// @notice Balance of want sitting in our strategy.
    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfAuraBpt() public view returns (uint256) {
        return IERC20(auraBStethStable).balanceOf(address(this));
    }

    function balanceOfAura() public view returns (uint256) {
        return IERC20(auraToken).balanceOf(address(this));
    }

    function balanceOfBal() public view returns (uint256) {
        return IERC20(balToken).balanceOf(address(this));
    }

    function balanceOfUnstakedBpt() public view returns (uint256) {
        return IERC20(bStethStable).balanceOf(address(this));
    }

    function balRewards() public view returns (uint256) {
        return IConvexRewards(auraBStethStable).earned(address(this));
    }

    function auraRewards(uint256 balTokens) public view returns (uint256) {
        return AuraRewardsMath.convertCrvToCvx(balTokens);
    }

    function auraBptToBpt(uint _amountAuraBpt) public pure returns (uint256) {
        return _amountAuraBpt;
    }

    function estimatedTotalAssets()
        public
        view
        override
        returns (uint256 _wants)
    {
        // WETH + BPT (B-stETH-Stable) + auraBPT (auraB-stETH-Stable) + AURA (rewards) + BAL (rewards)
        // should be converted to WETH using balancer
        _wants = balanceOfWant();

        uint256 bptTokens = balanceOfUnstakedBpt() +
            auraBptToBpt(balanceOfAuraBpt());
        _wants += bptToWant(bptTokens);
        uint256 balTokens = balRewards();
        if (balTokens > 0) {
            _wants += balToWant(balTokens);
        }

        uint256 auraTokens = auraRewards(balTokens);
        if (auraTokens > 0) {
            _wants += auraToWant(auraTokens);
        }

        return _wants;
    }

    function wantToBpt(uint _amountWant) public view returns (uint _amount) {
        uint unscaled = _amountWant.mul(1e18).div(getBptPrice());
        return
            Utils.scaleDecimals(
                unscaled,
                ERC20(address(want)),
                ERC20(bStethStable)
            );
    }

    function bptToWant(uint _amountBpt) public view returns (uint _amount) {
        uint unscaled = _amountBpt.mul(getBptPrice()).div(1e18);
        return
            Utils.scaleDecimals(
                unscaled,
                ERC20(bStethStable),
                ERC20(address(want))
            );
    }

    function auraToWant(uint256 auraTokens) public view returns (uint256) {
        uint unscaled = auraTokens.mul(getAuraPrice()).div(1e18);
        return
            Utils.scaleDecimals(
                unscaled,
                ERC20(auraToken),
                ERC20(address(want))
            );
    }

    function balToWant(uint256 balTokens) public view returns (uint256) {
        uint unscaled = balTokens.mul(getBalPrice()).div(1e18);
        return
            Utils.scaleDecimals(
                unscaled,
                ERC20(balToken),
                ERC20(address(want))
            );
    }

    function getBalPrice() public view returns (uint256 price) {
        address priceOracle = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: 1800,
            ago: 0
        });
        uint256[] memory results = IBalancerPriceOracle(priceOracle)
            .getTimeWeightedAverage(queries);
        price = 1e36 / results[0];
    }

    function getAuraPrice() public view returns (uint256 price) {
        address priceOracle = 0xc29562b045D80fD77c69Bec09541F5c16fe20d9d;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: 1800,
            ago: 0
        });
        uint256[] memory results;
        results = IBalancerPriceOracle(priceOracle).getTimeWeightedAverage(
            queries
        );
        price = results[0];
    }

    function getBptPrice() public view returns (uint256 price) {
        address priceOracle = 0x32296969Ef14EB0c6d29669C550D4a0449130230;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.BPT_PRICE,
            secs: 1800,
            ago: 0
        });
        uint256[] memory results;
        results = IBalancerPriceOracle(priceOracle).getTimeWeightedAverage(
            queries
        );
        price = results[0];
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;

        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }

        uint256 _liquidWant = balanceOfWant();
        uint256 _amountNeeded = _debtOutstanding + _profit;
        if (_liquidWant <= _amountNeeded) {
            withdrawSome(_amountNeeded - _liquidWant);
            _liquidWant = balanceOfWant();
        }

        // enough to pay profit (partial or full) only
        if (_liquidWant <= _profit) {
            _profit = _liquidWant;
            _debtPayment = 0;
            // enough to pay for all profit and _debtOutstanding (partial or full)
        } else {
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }

        if (balRewards() > 0) {
            IConvexRewards(auraBStethStable).getReward(address(this), true);
        }
        _sellBalAndAura(
            IERC20(balToken).balanceOf(address(this)),
            IERC20(auraToken).balanceOf(address(this))
        );

        uint256 _wethBal = want.balanceOf(address(this));
        if (_wethBal > _debtOutstanding) {
            uint256 _excessWeth = _wethBal - _debtOutstanding;

            uint256[] memory _amountsIn = new uint256[](2);
            _amountsIn[0] = 0;
            _amountsIn[1] = _excessWeth;

            address[] memory _assets = new address[](2);
            _assets[0] = wstETH;
            _assets[1] = address(want);

            uint256[] memory _maxAmountsIn = new uint256[](2);
            _maxAmountsIn[0] = 0;
            _maxAmountsIn[1] = _excessWeth;

            uint256 _minimumBPT = (wantToBpt(_excessWeth) * bptSlippage) /
                10000;
            bytes memory _userData = abi.encode(
                IBalancerV2Vault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
                _amountsIn,
                _minimumBPT
            );

            IBalancerV2Vault.JoinPoolRequest memory _request;
            _request = IBalancerV2Vault.JoinPoolRequest({
                assets: _assets,
                maxAmountsIn: _maxAmountsIn,
                userData: _userData,
                fromInternalBalance: false
            });

            balancerVault.joinPool({
                poolId: stEthEthPoolId,
                sender: address(this),
                recipient: payable(address(this)),
                request: _request
            });
        }
        if (_wethBal > _debtOutstanding || balanceOfUnstakedBpt() > 0) {
            bool auraSuccess = IConvexDeposit(auraBooster).deposit(
                AURA_PID, // PID
                IBalancerPool(bStethStable).balanceOf(address(this)),
                true // stake
            );
            require(auraSuccess, "Aura deposit failed");
        }
    }

    function _sellBalAndAura(uint256 _balAmount, uint256 _auraAmount) internal {
        if (_balAmount == 0) return;

        IBalancerV2Vault.BatchSwapStep[] memory swaps;
        if (_auraAmount == 0) {
            swaps = new IBalancerV2Vault.BatchSwapStep[](1);
        } else {
            swaps = new IBalancerV2Vault.BatchSwapStep[](2);
            swaps[1] = IBalancerV2Vault.BatchSwapStep({
                poolId: auraEthPoolId,
                assetInIndex: 1,
                assetOutIndex: 2,
                amount: _auraAmount,
                userData: abi.encode(0)
            });
        }

        // bal to weth
        swaps[0] = IBalancerV2Vault.BatchSwapStep({
            poolId: balEthPoolId,
            assetInIndex: 0,
            assetOutIndex: 2,
            amount: _balAmount,
            userData: abi.encode(0)
        });

        address[] memory assets = new address[](3);
        assets[0] = balToken;
        assets[1] = auraToken;
        assets[2] = address(want);

        int estimatedRewards = int(
            balToWant(_balAmount) + auraToWant(_auraAmount)
        );
        int[] memory limits = new int[](3);
        limits[0] = int(_balAmount);
        limits[1] = int(_auraAmount);
        limits[2] = (-1) * ((estimatedRewards * int(rewardsSlippage)) / 10000);

        balancerVault.batchSwap(
            IBalancerV2Vault.SwapKind.GIVEN_IN,
            swaps,
            assets,
            getFundManagement(),
            limits,
            block.timestamp
        );
    }

    function withdrawSome(uint256 _amountNeeded) internal {
        uint256 balRewardsTokens = balRewards();
        uint256 balTokens = balRewardsTokens + balanceOfBal();
        uint256 auraTokens = auraRewards(balRewardsTokens) + balanceOfAura();
        uint256 rewardsTotal = balToWant(balTokens) + auraToWant(auraTokens);

        if (rewardsTotal >= _amountNeeded) {
            IConvexRewards(auraBStethStable).getReward(address(this), true);
            _sellBalAndAura(balanceOfBal(), balanceOfAura());
        } else {
            uint256 bptToUnstake = Math.min(
                wantToBpt(_amountNeeded - rewardsTotal),
                IERC20(auraBStethStable).balanceOf(address(this))
            );

            if (bptToUnstake > 0) {
                _exitPosition(bptToUnstake);
            }
        }
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wethBal = want.balanceOf(address(this));
        if (_wethBal < _amountNeeded) {
            withdrawSome(_amountNeeded - _wethBal);
            _wethBal = balanceOfWant();
        }

        if (_amountNeeded > _wethBal) {
            _liquidatedAmount = _wethBal;
            _loss = _amountNeeded - _wethBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(IERC20(auraBStethStable).balanceOf(address(this)));
        return want.balanceOf(address(this));
    }

    function _exitPosition(uint256 bptAmount) internal {
        IConvexRewards(auraBStethStable).withdrawAndUnwrap(bptAmount, true);
        _sellBalAndAura(
            IERC20(balToken).balanceOf(address(this)),
            IERC20(auraToken).balanceOf(address(this))
        );

        address[] memory _assets = new address[](2);
        _assets[0] = wstETH;
        _assets[1] = address(want);

        uint256[] memory _minAmountsOut = new uint256[](2);
        _minAmountsOut[0] = 0;
        _minAmountsOut[1] = (bptToWant(bptAmount) * bptSlippage) / 10000;

        bytes memory userData = abi.encode(
            IBalancerV2Vault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
            bptAmount,
            1 // exitTokenIndex
        );

        IBalancerV2Vault.ExitPoolRequest memory request;
        request = IBalancerV2Vault.ExitPoolRequest({
            assets: _assets,
            minAmountsOut: _minAmountsOut,
            userData: userData,
            toInternalBalance: false
        });

        balancerVault.exitPool({
            poolId: stEthEthPoolId,
            sender: address(this),
            recipient: payable(address(this)),
            request: request
        });
    }

    function prepareMigration(address _newStrategy) internal override {
        // auraBStethStable do not allow to transfer so we just unwrap it
        IConvexRewards auraPool = IConvexRewards(auraBStethStable);
        auraPool.withdrawAndUnwrap(auraPool.balanceOf(address(this)), true);

        uint256 auraBal = IERC20(auraToken).balanceOf(address(this));
        if (auraBal > 0) {
            IERC20(auraToken).safeTransfer(_newStrategy, auraBal);
        }
        uint256 balancerBal = IERC20(balToken).balanceOf(address(this));
        if (balancerBal > 0) {
            IERC20(balToken).safeTransfer(_newStrategy, balancerBal);
        }
        uint256 bptBal = IERC20(bStethStable).balanceOf(address(this));
        if (bptBal > 0) {
            IERC20(bStethStable).safeTransfer(_newStrategy, bptBal);
        }
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](4);
        protected[0] = bStethStable;
        protected[1] = auraBStethStable;
        protected[2] = balToken;
        protected[3] = auraToken;
        return protected;
    }

    function ethToWant(
        uint256 _amtInWei
    ) public view virtual override returns (uint256) {
        return _amtInWei;
    }

    function setBptSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        bptSlippage = _slippage;
    }

    function setRewardsSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        rewardsSlippage = _slippage;
    }

    function getFundManagement()
        internal
        view
        returns (IBalancerV2Vault.FundManagement memory fundManagement)
    {
        fundManagement = IBalancerV2Vault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
    }
}

// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use

pragma solidity ^0.8.18;

import {BaseStrategy, StrategyParams} from "@yearn-protocol/contracts/BaseStrategy.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../integrations/balancer/IBalancerV2Vault.sol";
import "../integrations/balancer/IBalancerPool.sol";
import "../integrations/balancer/IBalancerPriceOracle.sol";
import "../integrations/aura/ICvx.sol";
import "../integrations/aura/IAuraToken.sol";
import "../integrations/aura/IAuraMinter.sol";
import "../integrations/convex/IConvexRewards.sol";
import "../integrations/convex/IConvexDeposit.sol";

import "../utils/AuraMath.sol";
import "../utils/Utils.sol";

contract RocketAuraStrategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using AuraMath for uint256;

    IBalancerV2Vault internal constant balancerVault =
        IBalancerV2Vault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    address internal constant bRethStable =
        0x1E19CF2D73a72Ef1332C882F20534B6519Be0276;
    address internal constant auraToken =
        0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
    address internal constant balToken =
        0xba100000625a3754423978a60c9317c58a424e3D;
    address internal constant auraBooster =
        0xA57b8d98dAE62B26Ec3bcC4a365338157060B234;
    address internal constant rETH = 0xae78736Cd615f374D3085123A210448E74Fc6393;

    bytes32 internal constant rEthEthPoolId =
        bytes32(
            0x1e19cf2d73a72ef1332c882f20534b6519be0276000200000000000000000112
        );
    bytes32 internal constant balEthPoolId =
        bytes32(
            0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014
        );
    bytes32 internal constant auraEthPoolId =
        bytes32(
            0xc29562b045d80fd77c69bec09541f5c16fe20d9d000200000000000000000251
        );

    uint256 public bptSlippage;
    uint256 public rewardsSlippage;

    uint256 public AURA_PID;
    address public auraBRethStable;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(address _vault, address _strategist) external {
        _initialize(_vault, _strategist, _strategist, _strategist);

        want.safeApprove(address(balancerVault), type(uint256).max);
        IERC20(bRethStable).safeApprove(auraBooster, type(uint256).max);
        IERC20(auraToken).safeApprove(
            address(balancerVault),
            type(uint256).max
        );
        IERC20(balToken).safeApprove(address(balancerVault), type(uint256).max);

        bptSlippage = 9900; // 1%
        rewardsSlippage = 9700; // 3%

        AURA_PID = 109;
        auraBRethStable = 0xDd1fE5AD401D4777cE89959b7fa587e569Bf125D;
    }

    function name() external view override returns (string memory) {
        return "StrategyRocketAura";
    }

    function setAuraPid(uint256 _pid) external onlyStrategist {
        AURA_PID = _pid;
    }

    function setAuraBRethStable(
        address _auraBRethStable
    ) external onlyStrategist {
        auraBRethStable = _auraBRethStable;
    }

    /// @notice Balance of want sitting in our strategy.
    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfAuraBpt() public view returns (uint256) {
        return IERC20(auraBRethStable).balanceOf(address(this));
    }

    function balanceOfAura() public view returns (uint256) {
        return IERC20(auraToken).balanceOf(address(this));
    }

    function balanceOfBal() public view returns (uint256) {
        return IERC20(balToken).balanceOf(address(this));
    }

    function balanceOfUnstakedBpt() public view returns (uint256) {
        return IERC20(bRethStable).balanceOf(address(this));
    }

    function balRewards() public view returns (uint256) {
        return IConvexRewards(auraBRethStable).earned(address(this));
    }

    function auraRewards(uint256 balTokens) public view returns (uint256) {
        return AuraRewardsMath.convertCrvToCvx(balTokens);
    }

    function auraBptToBpt(uint _amountAuraBpt) public pure returns (uint256) {
        return _amountAuraBpt;
    }

    function estimatedTotalAssets()
        public
        view
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();

        uint256 bptTokens = balanceOfUnstakedBpt() +
            auraBptToBpt(balanceOfAuraBpt());
        _wants += bptToWant(bptTokens);
        uint256 balRewardTokens = balRewards();
        uint256 balTokens = balRewardTokens + balanceOfBal();
        if (balTokens > 0) {
            _wants += balToWant(balTokens);
        }

        uint256 auraTokens = auraRewards(balRewardTokens) + balanceOfAura();
        if (auraTokens > 0) {
            _wants += auraToWant(auraTokens);
        }

        return _wants;
    }

    function wantToBpt(uint _amountWant) public view returns (uint _amount) {
        uint unscaled = _amountWant.mul(1e18).div(
            IBalancerPool(bRethStable).getRate()
        );
        return
            Utils.scaleDecimals(
                unscaled,
                ERC20(address(want)),
                ERC20(bRethStable)
            );
    }

    function bptToWant(uint _amountBpt) public view returns (uint _amount) {
        uint unscaled = _amountBpt.mul(getBptPrice()).div(1e18);
        return
            Utils.scaleDecimals(
                unscaled,
                ERC20(bRethStable),
                ERC20(address(want))
            );
    }

    function auraToWant(uint256 auraTokens) public view returns (uint256) {
        uint unscaled = auraTokens.mul(getAuraPrice()).div(1e18);
        return
            Utils.scaleDecimals(
                unscaled,
                ERC20(auraToken),
                ERC20(address(want))
            );
    }

    function balToWant(uint256 balTokens) public view returns (uint256) {
        uint unscaled = balTokens.mul(getBalPrice()).div(1e18);
        return
            Utils.scaleDecimals(
                unscaled,
                ERC20(balToken),
                ERC20(address(want))
            );
    }

    function getBalPrice() public view returns (uint256 price) {
        address priceOracle = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: 1800,
            ago: 0
        });
        uint256[] memory results = IBalancerPriceOracle(priceOracle)
            .getTimeWeightedAverage(queries);
        price = 1e36 / results[0];
    }

    function getAuraPrice() public view returns (uint256 price) {
        address priceOracle = 0xc29562b045D80fD77c69Bec09541F5c16fe20d9d;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: 1800,
            ago: 0
        });
        uint256[] memory results;
        results = IBalancerPriceOracle(priceOracle).getTimeWeightedAverage(
            queries
        );
        price = results[0];
    }

    function getBptPrice() public view returns (uint256 price) {
        address priceOracle = 0x1E19CF2D73a72Ef1332C882F20534B6519Be0276;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.BPT_PRICE,
            secs: 1800,
            ago: 0
        });
        uint256[] memory results;
        results = IBalancerPriceOracle(priceOracle).getTimeWeightedAverage(
            queries
        );
        price = results[0];
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;

        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }

        uint256 _liquidWant = balanceOfWant();
        uint256 _amountNeeded = _debtOutstanding + _profit;
        if (_liquidWant <= _amountNeeded) {
            withdrawSome(_amountNeeded - _liquidWant);
            _liquidWant = balanceOfWant();
        }

        if (_liquidWant <= _profit) {
            // enough to pay profit (partial or full) only
            _profit = _liquidWant;
            _debtPayment = 0;
        } else {
            // enough to pay for all profit and _debtOutstanding (partial or full)
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }

        if (balRewards() > 0) {
            IConvexRewards(auraBRethStable).getReward(address(this), true);
        }
        _sellBalAndAura(
            IERC20(balToken).balanceOf(address(this)),
            IERC20(auraToken).balanceOf(address(this))
        );

        uint256 _wethBal = want.balanceOf(address(this));
        if (_wethBal > _debtOutstanding) {
            uint256 _excessWeth = _wethBal - _debtOutstanding;

            uint256[] memory _amountsIn = new uint256[](2);
            _amountsIn[0] = 0;
            _amountsIn[1] = _excessWeth;

            address[] memory _assets = new address[](2);
            _assets[0] = rETH;
            _assets[1] = address(want);

            uint256[] memory _maxAmountsIn = new uint256[](2);
            _maxAmountsIn[0] = 0;
            _maxAmountsIn[1] = _excessWeth;

            uint256 _minimumBPT = (wantToBpt(_excessWeth) * bptSlippage) /
                10000;

            bytes memory _userData = abi.encode(
                IBalancerV2Vault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
                _amountsIn,
                _minimumBPT
            );

            IBalancerV2Vault.JoinPoolRequest memory _request;
            _request = IBalancerV2Vault.JoinPoolRequest({
                assets: _assets,
                maxAmountsIn: _maxAmountsIn,
                userData: _userData,
                fromInternalBalance: false
            });

            balancerVault.joinPool({
                poolId: rEthEthPoolId,
                sender: address(this),
                recipient: payable(address(this)),
                request: _request
            });
        }
        if (_wethBal > _debtOutstanding || balanceOfUnstakedBpt() > 0) {
            bool auraSuccess = IConvexDeposit(auraBooster).deposit(
                AURA_PID, // PID
                IBalancerPool(bRethStable).balanceOf(address(this)),
                true // stake
            );
            require(auraSuccess, "Aura deposit failed");
        }
    }

    function _sellBalAndAura(uint256 _balAmount, uint256 _auraAmount) internal {
        if (_balAmount == 0 || _auraAmount == 0) return;

        IBalancerV2Vault.BatchSwapStep[]
            memory swaps = new IBalancerV2Vault.BatchSwapStep[](2);

        // bal to weth
        swaps[0] = IBalancerV2Vault.BatchSwapStep({
            poolId: balEthPoolId,
            assetInIndex: 0,
            assetOutIndex: 2,
            amount: _balAmount,
            userData: abi.encode(0)
        });

        // aura to Weth
        swaps[1] = IBalancerV2Vault.BatchSwapStep({
            poolId: auraEthPoolId,
            assetInIndex: 1,
            assetOutIndex: 2,
            amount: _auraAmount,
            userData: abi.encode(0)
        });

        address[] memory assets = new address[](3);
        assets[0] = balToken;
        assets[1] = auraToken;
        assets[2] = address(want);

        int estimatedRewards = int(
            balToWant(_balAmount) + auraToWant(_auraAmount)
        );
        int[] memory limits = new int[](3);
        limits[0] = int(_balAmount);
        limits[1] = int(_auraAmount);
        limits[2] = (-1) * ((estimatedRewards * int(rewardsSlippage)) / 10000);

        balancerVault.batchSwap(
            IBalancerV2Vault.SwapKind.GIVEN_IN,
            swaps,
            assets,
            getFundManagement(),
            limits,
            block.timestamp
        );
    }

    function withdrawSome(uint256 _amountNeeded) internal {
        uint256 balRewardTokens = balRewards();
        uint256 balTokens = balRewardTokens + balanceOfBal();
        uint256 auraTokens = auraRewards(balRewardTokens) + balanceOfAura();
        uint256 rewardsTotal = balToWant(balTokens) + auraToWant(auraTokens);

        if (rewardsTotal >= _amountNeeded) {
            IConvexRewards(auraBRethStable).getReward(address(this), true);
            _sellBalAndAura(balanceOfBal(), balanceOfAura());
        } else {
            uint256 bptToUnstake = Math.min(
                wantToBpt(_amountNeeded - rewardsTotal),
                IERC20(auraBRethStable).balanceOf(address(this))
            );

            if (bptToUnstake > 0) {
                _exitPosition(bptToUnstake);
            }
        }
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wethBal = want.balanceOf(address(this));
        if (_wethBal < _amountNeeded) {
            withdrawSome(_amountNeeded - _wethBal);
            _wethBal = balanceOfWant();
        }

        if (_amountNeeded > _wethBal) {
            _liquidatedAmount = _wethBal;
            _loss = _amountNeeded - _wethBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(IERC20(auraBRethStable).balanceOf(address(this)));
        return want.balanceOf(address(this));
    }

    function _exitPosition(uint256 bptAmount) internal {
        IConvexRewards(auraBRethStable).withdrawAndUnwrap(bptAmount, true);
        _sellBalAndAura(
            IERC20(balToken).balanceOf(address(this)),
            IERC20(auraToken).balanceOf(address(this))
        );

        address[] memory _assets = new address[](2);
        _assets[0] = rETH;
        _assets[1] = address(want);

        uint256[] memory _minAmountsOut = new uint256[](2);
        _minAmountsOut[0] = 0;
        _minAmountsOut[1] = (bptToWant(bptAmount) * bptSlippage) / 10000;

        bytes memory userData = abi.encode(
            IBalancerV2Vault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
            bptAmount,
            1 // exitTokenIndex
        );

        IBalancerV2Vault.ExitPoolRequest memory request;
        request = IBalancerV2Vault.ExitPoolRequest({
            assets: _assets,
            minAmountsOut: _minAmountsOut,
            userData: userData,
            toInternalBalance: false
        });

        balancerVault.exitPool({
            poolId: rEthEthPoolId,
            sender: address(this),
            recipient: payable(address(this)),
            request: request
        });
    }

    function prepareMigration(address _newStrategy) internal override {
        // auraBRethStable do not allow to transfer so we just unwrap it
        IConvexRewards auraPool = IConvexRewards(auraBRethStable);
        auraPool.withdrawAndUnwrap(auraPool.balanceOf(address(this)), true);

        uint256 auraBal = IERC20(auraToken).balanceOf(address(this));
        if (auraBal > 0) {
            IERC20(auraToken).safeTransfer(_newStrategy, auraBal);
        }
        uint256 balancerBal = IERC20(balToken).balanceOf(address(this));
        if (balancerBal > 0) {
            IERC20(balToken).safeTransfer(_newStrategy, balancerBal);
        }
        uint256 bptBal = IERC20(bRethStable).balanceOf(address(this));
        if (bptBal > 0) {
            IERC20(bRethStable).safeTransfer(_newStrategy, bptBal);
        }
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](4);
        protected[0] = bRethStable;
        protected[1] = auraBRethStable;
        protected[2] = balToken;
        protected[3] = auraToken;
        return protected;
    }

    function ethToWant(
        uint256 _amtInWei
    ) public view virtual override returns (uint256) {
        return _amtInWei;
    }

    function setBptSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        bptSlippage = _slippage;
    }

    function setRewardsSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        rewardsSlippage = _slippage;
    }

    function getFundManagement()
        internal
        view
        returns (IBalancerV2Vault.FundManagement memory fundManagement)
    {
        fundManagement = IBalancerV2Vault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {BaseStrategy, StrategyParams, VaultAPI} from "@yearn-protocol/contracts/BaseStrategy.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import "../utils/Utils.sol";
import "../integrations/balancer/IBalancerPriceOracle.sol";
import "../integrations/curve/ICurve.sol";

contract YCRVStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    address internal constant yCRVVault =
        0x27B5739e22ad9033bcBf192059122d163b60349D;
    address internal constant yCRV = 0xFCc5c47bE19d06BF83eB04298b026F81069ff65b;
    address internal constant USDC_WETH_BALANCER_POOL =
        0x96646936b91d6B9D7D0c47C496AfBF3D6ec7B6f8;
    address internal constant YCRV_CRV_CURVE_POOL =
        0x99f5aCc8EC2Da2BC0771c32814EFF52b712de1E5;
    address internal constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address internal constant CRV_USDC_UNI_V3_POOL =
        0x9445bd19767F73DCaE6f2De90e6cd31192F62589;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant CURVE_SWAP_ROUTER =
        0x99a58482BD75cbab83b27EC03CA68fF489b5788f;

    uint32 internal constant TWAP_RANGE_SECS = 1800;
    uint256 public slippage;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(address _vault, address _strategist) external {
        _initialize(_vault, _strategist, _strategist, _strategist);

        want.safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(yCRV).safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(yCRV).safeApprove(yCRVVault, type(uint256).max);
        slippage = 9800; // 2%
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    function name() external pure override returns (string memory) {
        return "StrategyYearn";
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfStakedYCrv() public view returns (uint256) {
        return IERC20(yCRVVault).balanceOf(address(this));
    }

    function balanceOfYCrv() public view returns (uint256) {
        return IERC20(yCRV).balanceOf(address(this));
    }

    function crvToWant(uint256 crvTokens) public view returns (uint256) {
        uint256 scaledPrice = (ICurve(
            0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14
        ).price_oracle(1) * crvTokens) / 1e18;
        return
            Utils.scaleDecimals(scaledPrice, ERC20(CRV), ERC20(address(want)));
    }

    function yCrvToWant(uint256 yCRVTokens) public view returns (uint256) {
        uint256 crvRatio = ICurve(YCRV_CRV_CURVE_POOL).price_oracle();
        uint256 crvTokens = (crvRatio * yCRVTokens) / 1e18;
        return crvToWant(crvTokens);
    }

    function stYCRVToWant(uint256 stTokens) public view returns (uint256) {
        uint256 yCRVTokens = (stTokens * VaultAPI(yCRVVault).pricePerShare()) /
            1e18;
        return yCrvToWant(yCRVTokens);
    }

    function wantToStYCrv(
        uint256 wantTokens
    ) public view virtual returns (uint256) {
        uint256 stYCrvRate = 1e36 / stYCRVToWant(1e18);
        return (wantTokens * stYCrvRate) / 1e18;
    }

    function wantToYCrv(uint256 wantTokens) public view returns (uint256) {
        uint256 yCrvRate = 1e36 / yCrvToWant(1e18);
        return (wantTokens * yCrvRate) / 1e18;
    }

    function _scaleDecimals(
        uint _amount,
        ERC20 _fromToken,
        ERC20 _toToken
    ) internal view returns (uint _scaled) {
        uint decFrom = _fromToken.decimals();
        uint decTo = _toToken.decimals();

        if (decTo > decFrom) {
            return _amount * (10 ** (decTo - decFrom));
        } else {
            return _amount / (10 ** (decFrom - decTo));
        }
    }

    function _withdrawSome(uint256 _amountNeeded) internal {
        uint256 yCrvToUnstake = Math.min(
            balanceOfStakedYCrv(),
            wantToStYCrv(_amountNeeded)
        );

        if (yCrvToUnstake > 0) {
            _exitPosition(yCrvToUnstake);
        }
    }

    function _exitPosition(uint256 stYCrvAmount) internal {
        VaultAPI(yCRVVault).withdraw(stYCrvAmount);
        uint256 yCrvBalance = balanceOfYCrv();

        address[9] memory _route = [
            yCRV, // yCRV
            0x99f5aCc8EC2Da2BC0771c32814EFF52b712de1E5, // yCRV pool
            0xD533a949740bb3306d119CC777fa900bA034cd52, // CRV
            0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14, // TriCRV pool
            0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E, // crvUSD
            0x4DEcE678ceceb27446b35C672dC7d61F30bAD69E, // crvUSD/USDC pool
            address(want), // USDC
            address(0),
            address(0)
        ];
        uint256[3][4] memory _swap_params = [
            [uint256(1), uint256(0), uint256(1)], // yCRV -> CRV, stable swap exchange
            [uint256(2), uint256(0), uint256(3)], // CRV -> crvUSD, cryptoswap exchange
            [uint256(1), uint256(0), uint256(1)], // crvUSD -> USDC, stable swap exchange
            [uint256(0), uint256(0), uint256(0)]
        ];
        uint256 _expected = (yCrvToWant(yCrvBalance) * slippage) / 10000;

        ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
            _route,
            _swap_params,
            yCrvBalance,
            _expected
        );
    }

    function ethToWant(
        uint256 _amtInWei
    ) public view override returns (uint256) {
        uint256 scaledPrice = (ICurve(
            0x7F86Bf177Dd4F3494b841a37e810A34dD56c829B
        ).price_oracle(1) * _amtInWei) / 1e18;
        return
            Utils.scaleDecimals(scaledPrice, ERC20(WETH), ERC20(address(want)));
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();
        _wants += yCrvToWant(balanceOfYCrv());
        _wants += stYCRVToWant(balanceOfStakedYCrv());
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;

        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }

        uint256 _liquidWant = balanceOfWant();
        uint256 _amountNeeded = _debtOutstanding + _profit;
        if (_liquidWant <= _amountNeeded) {
            _withdrawSome(_amountNeeded - _liquidWant);
            _liquidWant = balanceOfWant();
        }

        // enough to pay profit (partial or full) only
        if (_liquidWant <= _profit) {
            _profit = _liquidWant;
            _debtPayment = 0;
            // enough to pay for all profit and _debtOutstanding (partial or full)
        } else {
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }

        uint256 _wantBal = balanceOfWant();

        if (_wantBal > _debtOutstanding) {
            uint256 _excessWant = _wantBal - _debtOutstanding;

            address[9] memory _route = [
                address(want),
                0x4DEcE678ceceb27446b35C672dC7d61F30bAD69E, // crvUSD/USDC pool
                0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E, // crvUSD
                0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14, // TriCRV pool
                0xD533a949740bb3306d119CC777fa900bA034cd52, // CRV
                0x99f5aCc8EC2Da2BC0771c32814EFF52b712de1E5, // yCRV pool
                yCRV, // yCRV
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(0), uint256(1), uint256(1)], // USDC -> crvUSD, stable swap exchange
                [uint256(0), uint256(2), uint256(3)], // crvUSD -> CRV, cryptoswap exchange
                [uint256(0), uint256(1), uint256(1)], // CRV -> yCRV, stable swap exchange
                [uint256(0), uint256(0), uint256(0)]
            ];

            uint256 _expected = (wantToYCrv(_excessWant) * slippage) / 10000;
            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                _excessWant,
                _expected
            );
        }

        uint256 _yCrvBal = IERC20(yCRV).balanceOf(address(this));
        if (_yCrvBal > 0) {
            VaultAPI(yCRVVault).deposit(_yCrvBal, address(this));
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(balanceOfStakedYCrv());
        return want.balanceOf(address(this));
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal >= _amountNeeded) {
            return (_amountNeeded, 0);
        }

        _withdrawSome(_amountNeeded - _wantBal);
        _wantBal = want.balanceOf(address(this));

        if (_amountNeeded > _wantBal) {
            _liquidatedAmount = _wantBal;
            _loss = _amountNeeded - _wantBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        IERC20(yCRV).safeTransfer(
            _newStrategy,
            IERC20(yCRV).balanceOf(address(this))
        );
        IERC20(yCRVVault).safeTransfer(
            _newStrategy,
            IERC20(yCRVVault).balanceOf(address(this))
        );
    }

    function protectedTokens()
        internal
        pure
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](2);
        protected[0] = yCRV;
        protected[1] = yCRVVault;
        return protected;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../integrations/aura/ICvx.sol";
import "../integrations/aura/IAuraToken.sol";
import "../integrations/aura/IAuraMinter.sol";

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library AuraMath {
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

/// @notice Used for calculating rewards.
library AuraRewardsMath {
    address internal constant AURA = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;

    using AuraMath for uint256;

    function convertCrvToCvx(
        uint256 _amount
    ) internal view returns (uint256 amount) {
        address minter = IAuraToken(AURA).minter();
        uint256 inflationProtectionTime = IAuraMinter(minter)
            .inflationProtectionTime();

        if (block.timestamp > inflationProtectionTime) {
            // Inflation protected for now
            return 0;
        }

        uint256 supply = ICvx(AURA).totalSupply();
        uint256 totalCliffs = ICvx(AURA).totalCliffs();
        uint256 maxSupply = ICvx(AURA).EMISSIONS_MAX_SUPPLY();
        uint256 initMintAmount = ICvx(AURA).INIT_MINT_AMOUNT();

        // After AuraMinter.inflationProtectionTime has passed, this calculation might not be valid.
        // uint256 emissionsMinted = supply - initMintAmount - minterMinted;
        uint256 emissionsMinted = supply - initMintAmount;

        uint256 cliff = emissionsMinted.div(ICvx(AURA).reductionPerCliff());

        // e.g. 100 < 500
        if (cliff < totalCliffs) {
            // e.g. (new) reduction = (500 - 100) * 2.5 + 700 = 1700;
            // e.g. (new) reduction = (500 - 250) * 2.5 + 700 = 1325;
            // e.g. (new) reduction = (500 - 400) * 2.5 + 700 = 950;
            uint256 reduction = totalCliffs.sub(cliff).mul(5).div(2).add(700);
            // e.g. (new) amount = 1e19 * 1700 / 500 =  34e18;
            // e.g. (new) amount = 1e19 * 1325 / 500 =  26.5e18;
            // e.g. (new) amount = 1e19 * 950 / 500  =  19e17;
            amount = _amount.mul(reduction).div(totalCliffs);
            // e.g. amtTillMax = 5e25 - 1e25 = 4e25
            uint256 amtTillMax = maxSupply.sub(emissionsMinted);
            if (amount > amtTillMax) {
                amount = amtTillMax;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import "../integrations/aura/ICvx.sol";

/// @notice Used for calculating rewards.
/// @dev This implementation is taken from CVX's contract (https://etherscan.io/address/0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B#code).
library CVXRewardsMath {
    address internal constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address internal constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    using SafeMath for uint256;

    function convertCrvToCvx(uint256 _amount) internal view returns (uint256) {
        uint256 reductionPerCliff = ICvx(CVX).reductionPerCliff();
        uint256 supply = ICvx(CVX).totalSupply();
        uint256 totalCliffs = ICvx(CVX).totalCliffs();
        uint256 maxSupply = ICvx(CVX).maxSupply();

        uint256 cliff = supply.div(reductionPerCliff);
        if (cliff < totalCliffs) {
            uint256 reduction = totalCliffs.sub(cliff);
            _amount = _amount.mul(reduction).div(totalCliffs);

            uint256 amtTillMax = maxSupply.sub(supply);
            if (_amount > amtTillMax) {
                _amount = amtTillMax;
            }

            return _amount;
        }

        return 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library Utils {
    function scaleDecimals(
        uint _amount,
        ERC20 _fromToken,
        ERC20 _toToken
    ) internal view returns (uint _scaled) {
        uint decFrom = _fromToken.decimals();
        uint decTo = _toToken.decimals();

        if (decTo > decFrom) {
            return _amount * (10 ** (decTo - decFrom));
        } else {
            return _amount / (10 ** (decFrom - decTo));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.15;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface VaultAPI is IERC20 {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function apiVersion() external pure returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient) external returns (uint256);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function token() external view returns (address);

    function strategies(address _strategy) external view returns (StrategyParams memory);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);

    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);

    /**
     * View the guardian address of the Vault to assert privileged functions
     * can only be called by guardian. The Strategy serves the Vault, so it
     * is subject to guardian defined by the Vault.
     */
    function guardian() external view returns (address);
}

/**
 * This interface is here for the keeper bot to use.
 */
interface StrategyAPI {
    function name() external view returns (string memory);

    function vault() external view returns (address);

    function want() external view returns (address);

    function apiVersion() external pure returns (string memory);

    function keeper() external view returns (address);

    function isActive() external view returns (bool);

    function delegatedAssets() external view returns (uint256);

    function estimatedTotalAssets() external view returns (uint256);

    function tendTrigger(uint256 callCost) external view returns (bool);

    function tend() external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);
}

interface HealthCheck {
    function check(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding,
        uint256 totalDebt
    ) external view returns (bool);
}

interface IBaseFee {
    function isCurrentBaseFeeAcceptable() external view returns (bool);
}

/**
 * @title Yearn Base Strategy
 * @author yearn.finance
 * @notice
 *  BaseStrategy implements all of the required functionality to interoperate
 *  closely with the Vault contract. This contract should be inherited and the
 *  abstract methods implemented to adapt the Strategy to the particular needs
 *  it has to create a return.
 *
 *  Of special interest is the relationship between `harvest()` and
 *  `vault.report()'. `harvest()` may be called simply because enough time has
 *  elapsed since the last report, and not because any funds need to be moved
 *  or positions adjusted. This is critical so that the Vault may maintain an
 *  accurate picture of the Strategy's performance. See  `vault.report()`,
 *  `harvest()`, and `harvestTrigger()` for further details.
 */

abstract contract BaseStrategy {
    using SafeERC20 for IERC20;
    string public metadataURI;

    // health checks
    bool public doHealthCheck;
    address public healthCheck;

    /**
     * @notice
     *  Used to track which version of `StrategyAPI` this Strategy
     *  implements.
     * @dev The Strategy's version must match the Vault's `API_VERSION`.
     * @return A string which holds the current API version of this contract.
     */
    function apiVersion() public pure returns (string memory) {
        return "0.4.6";
    }

    /**
     * @notice This Strategy's name.
     * @dev
     *  You can use this field to manage the "version" of this Strategy, e.g.
     *  `StrategySomethingOrOtherV1`. However, "API Version" is managed by
     *  `apiVersion()` function above.
     * @return This Strategy's name.
     */
    function name() external view virtual returns (string memory);

    /**
     * @notice
     *  The amount (priced in want) of the total assets managed by this strategy should not count
     *  towards Yearn's TVL calculations.
     * @dev
     *  You can override this field to set it to a non-zero value if some of the assets of this
     *  Strategy is somehow delegated inside another part of of Yearn's ecosystem e.g. another Vault.
     *  Note that this value must be strictly less than or equal to the amount provided by
     *  `estimatedTotalAssets()` below, as the TVL calc will be total assets minus delegated assets.
     *  Also note that this value is used to determine the total assets under management by this
     *  strategy, for the purposes of computing the management fee in `Vault`
     * @return
     *  The amount of assets this strategy manages that should not be included in Yearn's Total Value
     *  Locked (TVL) calculation across it's ecosystem.
     */
    function delegatedAssets() external view virtual returns (uint256) {
        return 0;
    }

    VaultAPI public vault;
    address public strategist;
    address public rewards;
    address public keeper;

    IERC20 public want;

    // So indexers can keep track of this
    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);

    event UpdatedStrategist(address newStrategist);

    event UpdatedKeeper(address newKeeper);

    event UpdatedRewards(address rewards);

    event UpdatedMinReportDelay(uint256 delay);

    event UpdatedMaxReportDelay(uint256 delay);

    event UpdatedBaseFeeOracle(address baseFeeOracle);

    event UpdatedCreditThreshold(uint256 creditThreshold);

    event ForcedHarvestTrigger(bool triggerState);

    event EmergencyExitEnabled();

    event UpdatedMetadataURI(string metadataURI);

    event SetHealthCheck(address);
    event SetDoHealthCheck(bool);

    // The minimum number of seconds between harvest calls. See
    // `setMinReportDelay()` for more details.
    uint256 public minReportDelay;

    // The maximum number of seconds between harvest calls. See
    // `setMaxReportDelay()` for more details.
    uint256 public maxReportDelay;

    // See note on `setEmergencyExit()`.
    bool public emergencyExit;

    // See note on `isBaseFeeOracleAcceptable()`.
    address public baseFeeOracle;

    // See note on `setCreditThreshold()`
    uint256 public creditThreshold;

    // See note on `setForceHarvestTriggerOnce`
    bool public forceHarvestTriggerOnce;

    // modifiers
    modifier onlyAuthorized() {
        _onlyAuthorized();
        _;
    }

    modifier onlyEmergencyAuthorized() {
        _onlyEmergencyAuthorized();
        _;
    }

    modifier onlyStrategist() {
        _onlyStrategist();
        _;
    }

    modifier onlyGovernance() {
        _onlyGovernance();
        _;
    }

    modifier onlyRewarder() {
        _onlyRewarder();
        _;
    }

    modifier onlyKeepers() {
        _onlyKeepers();
        _;
    }

    modifier onlyVaultManagers() {
        _onlyVaultManagers();
        _;
    }

    function _onlyAuthorized() internal {
        require(msg.sender == strategist || msg.sender == governance());
    }

    function _onlyEmergencyAuthorized() internal {
        require(msg.sender == strategist || msg.sender == governance() || msg.sender == vault.guardian() || msg.sender == vault.management());
    }

    function _onlyStrategist() internal {
        require(msg.sender == strategist);
    }

    function _onlyGovernance() internal {
        require(msg.sender == governance());
    }

    function _onlyRewarder() internal {
        require(msg.sender == governance() || msg.sender == strategist);
    }

    function _onlyKeepers() internal {
        require(
            msg.sender == keeper ||
                msg.sender == strategist ||
                msg.sender == governance() ||
                msg.sender == vault.guardian() ||
                msg.sender == vault.management()
        );
    }

    function _onlyVaultManagers() internal {
        require(msg.sender == vault.management() || msg.sender == governance());
    }

    constructor(address _vault) {
        _initialize(_vault, msg.sender, msg.sender, msg.sender);
    }

    /**
     * @notice
     *  Initializes the Strategy, this is called only once, when the
     *  contract is deployed.
     * @dev `_vault` should implement `VaultAPI`.
     * @param _vault The address of the Vault responsible for this Strategy.
     * @param _strategist The address to assign as `strategist`.
     * The strategist is able to change the reward address
     * @param _rewards  The address to use for pulling rewards.
     * @param _keeper The adddress of the _keeper. _keeper
     * can harvest and tend a strategy.
     */
    function _initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) internal {
        require(address(want) == address(0), "Strategy already initialized");

        vault = VaultAPI(_vault);
        want = IERC20(vault.token());
        want.safeApprove(_vault, type(uint256).max); // Give Vault unlimited access (might save gas)
        strategist = _strategist;
        rewards = _rewards;
        keeper = _keeper;

        // initialize variables
        maxReportDelay = 30 days;
        creditThreshold = 1_000_000 * 10**vault.decimals(); // set this high by default so we don't get tons of false triggers if not changed

        vault.approve(rewards, type(uint256).max); // Allow rewards to be pulled
    }

    function setHealthCheck(address _healthCheck) external onlyVaultManagers {
        emit SetHealthCheck(_healthCheck);
        healthCheck = _healthCheck;
    }

    function setDoHealthCheck(bool _doHealthCheck) external onlyVaultManagers {
        emit SetDoHealthCheck(_doHealthCheck);
        doHealthCheck = _doHealthCheck;
    }

    /**
     * @notice
     *  Used to change `strategist`.
     *
     *  This may only be called by governance or the existing strategist.
     * @param _strategist The new address to assign as `strategist`.
     */
    function setStrategist(address _strategist) external onlyAuthorized {
        require(_strategist != address(0));
        strategist = _strategist;
        emit UpdatedStrategist(_strategist);
    }

    /**
     * @notice
     *  Used to change `keeper`.
     *
     *  `keeper` is the only address that may call `tend()` or `harvest()`,
     *  other than `governance()` or `strategist`. However, unlike
     *  `governance()` or `strategist`, `keeper` may *only* call `tend()`
     *  and `harvest()`, and no other authorized functions, following the
     *  principle of least privilege.
     *
     *  This may only be called by governance or the strategist.
     * @param _keeper The new address to assign as `keeper`.
     */
    function setKeeper(address _keeper) external onlyAuthorized {
        require(_keeper != address(0));
        keeper = _keeper;
        emit UpdatedKeeper(_keeper);
    }

    /**
     * @notice
     *  Used to change `rewards`. EOA or smart contract which has the permission
     *  to pull rewards from the vault.
     *
     *  This may only be called by the strategist.
     * @param _rewards The address to use for pulling rewards.
     */
    function setRewards(address _rewards) external onlyRewarder {
        require(_rewards != address(0));
        vault.approve(rewards, 0);
        rewards = _rewards;
        vault.approve(rewards, type(uint256).max);
        emit UpdatedRewards(_rewards);
    }

    /**
     * @notice
     *  Used to change `minReportDelay`. `minReportDelay` is the minimum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the minimum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _delay The minimum number of seconds to wait between harvests.
     */
    function setMinReportDelay(uint256 _delay) external onlyAuthorized {
        minReportDelay = _delay;
        emit UpdatedMinReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to change `maxReportDelay`. `maxReportDelay` is the maximum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the maximum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _delay The maximum number of seconds to wait between harvests.
     */
    function setMaxReportDelay(uint256 _delay) external onlyAuthorized {
        maxReportDelay = _delay;
        emit UpdatedMaxReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to ensure that any significant credit a strategy has from the
     *  vault will be automatically harvested.
     *
     *  This may only be called by governance or management.
     * @param _creditThreshold The number of want tokens that will
     *  automatically trigger a harvest.
     */
    function setCreditThreshold(uint256 _creditThreshold) external onlyVaultManagers {
        creditThreshold = _creditThreshold;
        emit UpdatedCreditThreshold(_creditThreshold);
    }

    /**
     * @notice
     *  Used to automatically trigger a harvest by our keepers. Can be
     *  useful if gas prices are too high now, and we want to harvest
     *  later once prices have lowered.
     *
     *  This may only be called by governance or management.
     * @param _forceHarvestTriggerOnce Value of true tells keepers to harvest
     *  our strategy
     */
    function setForceHarvestTriggerOnce(bool _forceHarvestTriggerOnce) external onlyVaultManagers {
        forceHarvestTriggerOnce = _forceHarvestTriggerOnce;
        emit ForcedHarvestTrigger(_forceHarvestTriggerOnce);
    }

    /**
     * @notice
     *  Used to set our baseFeeOracle, which checks the network's current base
     *  fee price to determine whether it is an optimal time to harvest or tend.
     *
     *  This may only be called by governance or management.
     * @param _baseFeeOracle Address of our baseFeeOracle
     */
    function setBaseFeeOracle(address _baseFeeOracle) external onlyVaultManagers {
        baseFeeOracle = _baseFeeOracle;
        emit UpdatedBaseFeeOracle(_baseFeeOracle);
    }

    /**
     * @notice
     *  Used to change `metadataURI`. `metadataURI` is used to store the URI
     * of the file describing the strategy.
     *
     *  This may only be called by governance or the strategist.
     * @param _metadataURI The URI that describe the strategy.
     */
    function setMetadataURI(string calldata _metadataURI) external onlyAuthorized {
        metadataURI = _metadataURI;
        emit UpdatedMetadataURI(_metadataURI);
    }

    /**
     * Resolve governance address from Vault contract, used to make assertions
     * on protected functions in the Strategy.
     */
    function governance() internal view returns (address) {
        return vault.governance();
    }

    /**
     * @notice
     *  Provide an accurate conversion from `_amtInWei` (denominated in wei)
     *  to `want` (using the native decimal characteristics of `want`).
     * @dev
     *  Care must be taken when working with decimals to assure that the conversion
     *  is compatible. As an example:
     *
     *      given 1e17 wei (0.1 ETH) as input, and want is USDC (6 decimals),
     *      with USDC/ETH = 1800, this should give back 1800000000 (180 USDC)
     *
     * @param _amtInWei The amount (in wei/1e-18 ETH) to convert to `want`
     * @return The amount in `want` of `_amtInEth` converted to `want`
     **/
    function ethToWant(uint256 _amtInWei) public view virtual returns (uint256);

    /**
     * @notice
     *  Provide an accurate estimate for the total amount of assets
     *  (principle + return) that this Strategy is currently managing,
     *  denominated in terms of `want` tokens.
     *
     *  This total should be "realizable" e.g. the total value that could
     *  *actually* be obtained from this Strategy if it were to divest its
     *  entire position based on current on-chain conditions.
     * @dev
     *  Care must be taken in using this function, since it relies on external
     *  systems, which could be manipulated by the attacker to give an inflated
     *  (or reduced) value produced by this function, based on current on-chain
     *  conditions (e.g. this function is possible to influence through
     *  flashloan attacks, oracle manipulations, or other DeFi attack
     *  mechanisms).
     *
     *  It is up to governance to use this function to correctly order this
     *  Strategy relative to its peers in the withdrawal queue to minimize
     *  losses for the Vault based on sudden withdrawals. This value should be
     *  higher than the total debt of the Strategy and higher than its expected
     *  value to be "safe".
     * @return The estimated total assets in this Strategy.
     */
    function estimatedTotalAssets() public view virtual returns (uint256);

    /*
     * @notice
     *  Provide an indication of whether this strategy is currently "active"
     *  in that it is managing an active position, or will manage a position in
     *  the future. This should correlate to `harvest()` activity, so that Harvest
     *  events can be tracked externally by indexing agents.
     * @return True if the strategy is actively managing a position.
     */
    function isActive() public view returns (bool) {
        return vault.strategies(address(this)).debtRatio > 0 || estimatedTotalAssets() > 0;
    }

    /**
     * Perform any Strategy unwinding or other calls necessary to capture the
     * "free return" this Strategy has generated since the last time its core
     * position(s) were adjusted. Examples include unwrapping extra rewards.
     * This call is only used during "normal operation" of a Strategy, and
     * should be optimized to minimize losses as much as possible.
     *
     * This method returns any realized profits and/or realized losses
     * incurred, and should return the total amounts of profits/losses/debt
     * payments (in `want` tokens) for the Vault's accounting (e.g.
     * `want.balanceOf(this) >= _debtPayment + _profit`).
     *
     * `_debtOutstanding` will be 0 if the Strategy is not past the configured
     * debt limit, otherwise its value will be how far past the debt limit
     * the Strategy is. The Strategy's debt limit is configured in the Vault.
     *
     * NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`.
     *       It is okay for it to be less than `_debtOutstanding`, as that
     *       should only used as a guide for how much is left to pay back.
     *       Payments should be made to minimize loss from slippage, debt,
     *       withdrawal fees, etc.
     *
     * See `vault.debtOutstanding()`.
     */
    function prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        );

    /**
     * Perform any adjustments to the core position(s) of this Strategy given
     * what change the Vault made in the "investable capital" available to the
     * Strategy. Note that all "free capital" in the Strategy after the report
     * was made is available for reinvestment. Also note that this number
     * could be 0, and you should handle that scenario accordingly.
     *
     * See comments regarding `_debtOutstanding` on `prepareReturn()`.
     */
    function adjustPosition(uint256 _debtOutstanding) internal virtual;

    /**
     * Liquidate up to `_amountNeeded` of `want` of this strategy's positions,
     * irregardless of slippage. Any excess will be re-invested with `adjustPosition()`.
     * This function should return the amount of `want` tokens made available by the
     * liquidation. If there is a difference between them, `_loss` indicates whether the
     * difference is due to a realized loss, or if there is some other sitution at play
     * (e.g. locked funds) where the amount made available is less than what is needed.
     *
     * NOTE: The invariant `_liquidatedAmount + _loss <= _amountNeeded` should always be maintained
     */
    function liquidatePosition(uint256 _amountNeeded) internal virtual returns (uint256 _liquidatedAmount, uint256 _loss);

    /**
     * Liquidate everything and returns the amount that got freed.
     * This function is used during emergency exit instead of `prepareReturn()` to
     * liquidate all of the Strategy's positions back to the Vault.
     */

    function liquidateAllPositions() internal virtual returns (uint256 _amountFreed);

    /**
     * @notice
     *  Provide a signal to the keeper that `tend()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `tend()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `tend()` is not called
     *  shortly, then this can return `true` even if the keeper might be
     *  "at a loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `callCostInWei` must be priced in terms of `wei` (1e-18 ETH).
     *
     *  This call and `harvestTrigger()` should never return `true` at the same
     *  time.
     * @param callCostInWei The keeper's estimated gas cost to call `tend()` (in wei).
     * @return `true` if `tend()` should be called, `false` otherwise.
     */
    function tendTrigger(uint256 callCostInWei) public view virtual returns (bool) {
        // We usually don't need tend, but if there are positions that need
        // active maintainence, overriding this function is how you would
        // signal for that.
        // If your implementation uses the cost of the call in want, you can
        // use uint256 callCost = ethToWant(callCostInWei);
        // It is highly suggested to use the baseFeeOracle here as well.

        return false;
    }

    /**
     * @notice
     *  Adjust the Strategy's position. The purpose of tending isn't to
     *  realize gains, but to maximize yield by reinvesting any returns.
     *
     *  See comments on `adjustPosition()`.
     *
     *  This may only be called by governance, the strategist, or the keeper.
     */
    function tend() external onlyKeepers {
        // Don't take profits with this call, but adjust for better gains
        adjustPosition(vault.debtOutstanding());
    }

    /**
     * @notice
     *  Provide a signal to the keeper that `harvest()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `harvest()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `harvest()` is not called
     *  shortly, then this can return `true` even if the keeper might be "at a
     *  loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `callCostInWei` must be priced in terms of `wei` (1e-18 ETH).
     *
     *  This call and `tendTrigger` should never return `true` at the
     *  same time.
     *
     *  See `maxReportDelay`, `creditThreshold` to adjust the
     *  strategist-controlled parameters that will influence whether this call
     *  returns `true` or not. These parameters will be used in conjunction
     *  with the parameters reported to the Vault (see `params`) to determine
     *  if calling `harvest()` is merited.
     *
     *  This trigger also checks the network's base fee to avoid harvesting during
     *  times of high network congestion.
     *
     *  Consider use of super.harvestTrigger() in any override to build on top
     *  of this logic instead of replacing it. For example, if using `minReportDelay`.
     *
     *  It is expected that an external system will check `harvestTrigger()`.
     *  This could be a script run off a desktop or cloud bot (e.g.
     *  https://github.com/iearn-finance/yearn-vaults/blob/main/scripts/keep.py),
     *  or via an integration with the Keep3r network (e.g.
     *  https://github.com/Macarse/GenericKeep3rV2/blob/master/contracts/keep3r/GenericKeep3rV2.sol).
     * @param callCostInWei The keeper's estimated gas cost to call `harvest()` (in wei).
     * @return `true` if `harvest()` should be called, `false` otherwise.
     */
    function harvestTrigger(uint256 callCostInWei) public view virtual returns (bool) {
        // Should not trigger if strategy is not active (no assets or no debtRatio)
        if (!isActive()) return false;

        // check if the base fee gas price is higher than we allow. if it is, block harvests.
        if (!isBaseFeeAcceptable()) return false;

        // trigger if we want to manually harvest, but only if our gas price is acceptable
        if (forceHarvestTriggerOnce) return true;

        // Should trigger if hasn't been called in a while
        StrategyParams memory params = vault.strategies(address(this));
        if ((block.timestamp - params.lastReport) >= maxReportDelay) return true;

        // harvest our credit if it's above our threshold or return false
        return (vault.creditAvailable() > creditThreshold);
    }

    /**
     * @notice
     *  Check if the current network base fee is below our external target. If
     *  not, then harvestTrigger will return false.
     * @return `true` if `harvest()` should be allowed, `false` otherwise.
     */
    function isBaseFeeAcceptable() public view returns (bool) {
        if (baseFeeOracle == address(0)) return true;
        else return IBaseFee(baseFeeOracle).isCurrentBaseFeeAcceptable();
    }

    /**
     * @notice
     *  Harvests the Strategy, recognizing any profits or losses and adjusting
     *  the Strategy's position.
     *
     *  In the rare case the Strategy is in emergency shutdown, this will exit
     *  the Strategy's position.
     *
     *  This may only be called by governance, the strategist, or the keeper.
     * @dev
     *  When `harvest()` is called, the Strategy reports to the Vault (via
     *  `vault.report()`), so in some cases `harvest()` must be called in order
     *  to take in profits, to borrow newly available funds from the Vault, or
     *  otherwise adjust its position. In other cases `harvest()` must be
     *  called to report to the Vault on the Strategy's position, especially if
     *  any losses have occurred.
     */
    function harvest() external onlyKeepers {
        uint256 profit = 0;
        uint256 loss = 0;
        uint256 debtOutstanding = vault.debtOutstanding();
        uint256 debtPayment = 0;
        if (emergencyExit) {
            // Free up as much capital as possible
            uint256 amountFreed = liquidateAllPositions();
            if (amountFreed < debtOutstanding) {
                loss = debtOutstanding - amountFreed;
            } else if (amountFreed > debtOutstanding) {
                profit = amountFreed - debtOutstanding;
            }
            debtPayment = debtOutstanding - loss;
        } else {
            // Free up returns for Vault to pull
            (profit, loss, debtPayment) = prepareReturn(debtOutstanding);
        }

        // we're done harvesting, so reset our trigger if we used it
        forceHarvestTriggerOnce = false;
        emit ForcedHarvestTrigger(false);

        // Allow Vault to take up to the "harvested" balance of this contract,
        // which is the amount it has earned since the last time it reported to
        // the Vault.
        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        debtOutstanding = vault.report(profit, loss, debtPayment);

        // Check if free returns are left, and re-invest them
        adjustPosition(debtOutstanding);

        // call healthCheck contract
        if (doHealthCheck && healthCheck != address(0)) {
            require(HealthCheck(healthCheck).check(profit, loss, debtPayment, debtOutstanding, totalDebt), "!healthcheck");
        } else {
            emit SetDoHealthCheck(true);
            doHealthCheck = true;
        }

        emit Harvested(profit, loss, debtPayment, debtOutstanding);
    }

    /**
     * @notice
     *  Withdraws `_amountNeeded` to `vault`.
     *
     *  This may only be called by the Vault.
     * @param _amountNeeded How much `want` to withdraw.
     * @return _loss Any realized losses
     */
    function withdraw(uint256 _amountNeeded) external returns (uint256 _loss) {
        require(msg.sender == address(vault), "!vault");
        // Liquidate as much as possible to `want`, up to `_amountNeeded`
        uint256 amountFreed;
        (amountFreed, _loss) = liquidatePosition(_amountNeeded);
        // Send it directly back (NOTE: Using `msg.sender` saves some gas here)
        want.safeTransfer(msg.sender, amountFreed);
        // NOTE: Reinvest anything leftover on next `tend`/`harvest`
    }

    /**
     * Do anything necessary to prepare this Strategy for migration, such as
     * transferring any reserve or LP tokens, CDPs, or other tokens or stores of
     * value.
     */
    function prepareMigration(address _newStrategy) internal virtual;

    /**
     * @notice
     *  Transfers all `want` from this Strategy to `_newStrategy`.
     *
     *  This may only be called by the Vault.
     * @dev
     * The new Strategy's Vault must be the same as this Strategy's Vault.
     *  The migration process should be carefully performed to make sure all
     * the assets are migrated to the new address, which should have never
     * interacted with the vault before.
     * @param _newStrategy The Strategy to migrate to.
     */
    function migrate(address _newStrategy) external {
        require(msg.sender == address(vault));
        require(BaseStrategy(_newStrategy).vault() == vault);
        prepareMigration(_newStrategy);
        want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
    }

    /**
     * @notice
     *  Activates emergency exit. Once activated, the Strategy will exit its
     *  position upon the next harvest, depositing all funds into the Vault as
     *  quickly as is reasonable given on-chain conditions.
     *
     *  This may only be called by governance or the strategist.
     * @dev
     *  See `vault.setEmergencyShutdown()` and `harvest()` for further details.
     */
    function setEmergencyExit() external onlyEmergencyAuthorized {
        emergencyExit = true;
        if (vault.strategies(address(this)).debtRatio != 0) {
            vault.revokeStrategy();
        }

        emit EmergencyExitEnabled();
    }

    /**
     * Override this to add all tokens/tokenized positions this contract
     * manages on a *persistent* basis (e.g. not just for swapping back to
     * want ephemerally).
     *
     * NOTE: Do *not* include `want`, already included in `sweep` below.
     *
     * Example:
     * ```
     *    function protectedTokens() internal override view returns (address[] memory) {
     *      address[] memory protected = new address[](3);
     *      protected[0] = tokenA;
     *      protected[1] = tokenB;
     *      protected[2] = tokenC;
     *      return protected;
     *    }
     * ```
     */
    function protectedTokens() internal view virtual returns (address[] memory);

    /**
     * @notice
     *  Removes tokens from this Strategy that are not the type of tokens
     *  managed by this Strategy. This may be used in case of accidentally
     *  sending the wrong kind of token to this Strategy.
     *
     *  Tokens will be sent to `governance()`.
     *
     *  This will fail if an attempt is made to sweep `want`, or any tokens
     *  that are protected by this Strategy.
     *
     *  This may only be called by governance.
     * @dev
     *  Implement `protectedTokens()` to specify any additional tokens that
     *  should be protected from sweeping in addition to `want`.
     * @param _token The token to transfer out of this vault.
     */
    function sweep(address _token) external onlyGovernance {
        require(_token != address(want), "!want");
        require(_token != address(vault), "!shares");

        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++) require(_token != _protectedTokens[i], "!protected");

        IERC20(_token).safeTransfer(governance(), IERC20(_token).balanceOf(address(this)));
    }
}

abstract contract BaseStrategyInitializable is BaseStrategy {
    bool public isOriginal = true;
    event Cloned(address indexed clone);

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) external virtual {
        _initialize(_vault, _strategist, _rewards, _keeper);
    }

    function clone(address _vault) external returns (address) {
        return clone(_vault, msg.sender, msg.sender, msg.sender);
    }

    function clone(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) public returns (address newStrategy) {
        require(isOriginal, "!clone");
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newStrategy := create(0, clone_code, 0x37)
        }

        BaseStrategyInitializable(newStrategy).initialize(_vault, _strategist, _rewards, _keeper);

        emit Cloned(newStrategy);
    }
}