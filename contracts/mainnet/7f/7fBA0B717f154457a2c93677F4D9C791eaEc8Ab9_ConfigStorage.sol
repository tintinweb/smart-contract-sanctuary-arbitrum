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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IDexter {
  function run(address _tokenIn, address _tokenOut, uint256 _amountIn) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IDexter } from "src/extensions/dexters/interfaces/IDexter.sol";

interface ISwitchCollateralRouter {
  function execute(uint256 _amount, address[] calldata _path) external returns (uint256);
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
import { ISwitchCollateralRouter } from "src/extensions/switch-collateral/interfaces/ISwitchCollateralRouter.sol";

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

  function setSwapConfig(SwapConfig calldata _newConfig) external;

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

  function setSGlp(address _sglp) external;

  function addOrUpdateAcceptedToken(address[] calldata _tokens, HLPTokenConfig[] calldata _configs) external;

  function addAssetClassConfig(AssetClassConfig calldata _newConfig) external returns (uint256 _index);

  function setAssetClassConfigByIndex(uint256 _index, AssetClassConfig calldata _newConfig) external;

  function setTradeServiceHooks(address[] calldata _newHooks) external;

  function addMarketConfig(
    MarketConfig calldata _newConfig,
    bool isAdaptiveFeeEnabled
  ) external returns (uint256 _index);

  function delistMarket(uint256 _marketIndex) external;

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