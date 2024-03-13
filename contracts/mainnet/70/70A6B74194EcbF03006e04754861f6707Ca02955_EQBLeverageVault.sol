// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

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
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
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
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
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
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ContextUpgradeable} from "../../utils/ContextUpgradeable.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
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
 */
abstract contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20, IERC20Metadata, IERC20Errors {
    /// @custom:storage-location erc7201:openzeppelin.storage.ERC20
    struct ERC20Storage {
        mapping(address account => uint256) _balances;

        mapping(address account => mapping(address spender => uint256)) _allowances;

        uint256 _totalSupply;

        string _name;
        string _symbol;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ERC20")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC20StorageLocation = 0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00;

    function _getERC20Storage() private pure returns (ERC20Storage storage $) {
        assembly {
            $.slot := ERC20StorageLocation
        }
    }

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
        ERC20Storage storage $ = _getERC20Storage();
        $._name = name_;
        $._symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._symbol;
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
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
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
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        ERC20Storage storage $ = _getERC20Storage();
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            $._totalSupply += value;
        } else {
            uint256 fromBalance = $._balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                $._balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                $._totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                $._balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
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
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        ERC20Storage storage $ = _getERC20Storage();
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        $._allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.20;

import {ERC20Upgradeable} from "../ERC20Upgradeable.sol";
import {ContextUpgradeable} from "../../../utils/ContextUpgradeable.sol";
import {Initializable} from "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys a `value` amount of tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 value) public virtual {
        _burn(_msgSender(), value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, deducting from
     * the caller's allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `value`.
     */
    function burnFrom(address account, uint256 value) public virtual {
        _spendAllowance(account, _msgSender(), value);
        _burn(account, value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

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
    /// @custom:storage-location erc7201:openzeppelin.storage.Pausable
    struct PausableStorage {
        bool _paused;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Pausable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PausableStorageLocation = 0xcd5ed15c6e187e77e9aee88184c21f4f2182ab5827cb3b7e07fbedcd63f03300;

    function _getPausableStorage() private pure returns (PausableStorage storage $) {
        assembly {
            $.slot := PausableStorageLocation
        }
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
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
        PausableStorage storage $ = _getPausableStorage();
        return $._paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = true;
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
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    /// @custom:storage-location erc7201:openzeppelin.storage.ReentrancyGuard
    struct ReentrancyGuardStorage {
        uint256 _status;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ReentrancyGuardStorageLocation = 0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    function _getReentrancyGuardStorage() private pure returns (ReentrancyGuardStorage storage $) {
        assembly {
            $.slot := ReentrancyGuardStorageLocation
        }
    }

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        $._status = NOT_ENTERED;
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
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if ($._status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        $._status = ENTERED;
    }

    function _nonReentrantAfter() private {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        $._status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        return $._status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
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
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
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
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interface/IEQBLeverageVault.sol";
import "./interface/IWater.sol";
import "./interface/EQBVault/IPositionRouter.sol";
import "./interface/EQBVault/IPluginManager.sol";
import "./interface/IMasterChef.sol";
import "./interface/EQBVault/IMarketPosition.sol";
// import {console} from "forge-std/Test.sol";


contract EQBLeverageVault is
    IEQBLeverageVault,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ERC20BurnableUpgradeable
{
    using Math for uint256;
    using Math for uint128;

    StrategyAddresses public strategyAddresses;
    FeeConfiguration public feeConfiguration;
    StrategyValues public strategyValues;
    LeverageParams public leverageParams;
    DebtAdjustmentValues public debtAdjustmentValues;

    mapping(address => MarketInfo) public marketInfo;
    mapping(address => UserInfo[]) public userInfo;
    // prettier-ignore
    mapping(address => PositionEntryGrowthMixX96X64[]) public userPositionEntryGrowthMixX96X64;
    mapping(address => mapping(uint128 => bool)) public inCloseProcess;
    mapping(uint128 => DepositRecord) public depositRecords;
    mapping(uint128 => WithdrawRecord) public withdrawRecords;

    mapping(address => bool) public isUser;
    mapping(address => bool) public allowedSenders;
    mapping(address => bool) public burner;
    mapping(address => bool) public executors;

    address public water;
    address public USDT;
    uint96 private DECIMAL;
    address public mFeeReceiver;
    uint96 private DENOMINATOR;
    uint256 public Q64;

    address[] public allUsers;
    uint256[50] private __gaps;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier zeroAddress(address addr) {
        require(addr != address(0), "address 0");
        _;
    }

    modifier onlyBurner() {
        require(burner[msg.sender], "EQBVault: !burner");
        _;
    }

    modifier onlyExecutors() {
        require(executors[msg.sender], "EQBVault: !executor");
        _;
    }

    function initialize(address _water, address _USDT) external initializer {
        water = _water;
        USDT = _USDT;
        DENOMINATOR = 1_000;
        DECIMAL = 1e18;
        strategyValues.MAX_BPS = 100_000;
        strategyValues.MAX_LEVERAGE = 10_000;
        strategyValues.MIN_LEVERAGE = 2_000;
        strategyValues.defaulLiquiditySize = 1_000e6;
        debtAdjustmentValues.time = uint128(block.timestamp);
        debtAdjustmentValues.defaultDebtAdjustmentValue = 1e18;
        debtAdjustmentValues.debtAdjustment = 1e18; // initialized to 1e18
        Q64 = 1 << 64;
        __Ownable_init(msg.sender);
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC20_init("EQBPOD", "EQBPOD");
    }

    // function setStrategyAddresses(
    //     address _router,
    //     address _positionRouter,
    //     address _marketManager
    // ) external onlyOwner {
    //     strategyAddresses.Router = _router;
    //     strategyAddresses.PositionRouter = _positionRouter;
    //     strategyAddresses.MarketManager = _marketManager;
    // }

    // function setLeverageParams(
    //     uint128 _DTVLimit,
    //     uint128 _DTVSlippage,
    //     address _keeper
    // ) external onlyOwner {
    //     leverageParams.DTVLimit = _DTVLimit;
    //     leverageParams.DTVSlippage = _DTVSlippage;
    //     leverageParams.keeper = _keeper;
    // }

    // function setDebtRatioAndTimeInterval(
    //     uint128 _debtValueRatio,
    //     uint128 _timeInterval
    // ) external onlyOwner {
    //     debtAdjustmentValues.debtValueRatio = _debtValueRatio;
    //     debtAdjustmentValues.debtAdjustmentInterval = _timeInterval;
    // }

    // function setPoolEnabled(
    //     address _asset,
    //     address _pool,
    //     bool _enabled
    // ) external onlyOwner {
    //     marketInfo[_asset] = MarketInfo(_pool, _enabled);
    // }

    // function setDefaultLiquiditySize(uint128 _size) external onlyOwner {
    //     strategyValues.defaulLiquiditySize = _size;
    // }

    // function setBurner(
    //     address _burner,
    //     bool _allowed
    // ) public onlyOwner zeroAddress(_burner) {
    //     burner[_burner] = _allowed;
    // }

    // function setExecutor(
    //     address _executor,
    //     bool _allowed
    // ) public onlyOwner zeroAddress(_executor) {
    //     executors[_executor] = _allowed;
    // }

    function setAllowed(
        address _sender,
        bool _allowed
    ) public onlyOwner zeroAddress(_sender) {
        allowedSenders[_sender] = _allowed;
    }

    function grantApproveManagerPlugin() external onlyOwner {
        IPluginManager(strategyAddresses.Router).approvePlugin(
            strategyAddresses.PositionRouter
        );
    }

    function setProtocolFees(
        address _feeReceiver,
        uint256 _withdrawalFee,
        address _waterFeeReceiver,
        uint256 _liquidatorsRewardPercentage,
        uint256 _fixedFeeSplit,
        uint128 _mFeePercent,
        address _mFeeReceiver,
        uint256 _executionFee
    )
        external
        onlyOwner
        zeroAddress(_feeReceiver)
        zeroAddress(_waterFeeReceiver)
    {
        require(
            _withdrawalFee <= strategyValues.MAX_BPS && _fixedFeeSplit < 100,
            "Invalid fees"
        );
        require(_mFeePercent <= 10000, "! valid");

        feeConfiguration.feeReceiver = _feeReceiver;
        feeConfiguration.withdrawalFee = _withdrawalFee;
        feeConfiguration.waterFeeReceiver = _waterFeeReceiver;
        feeConfiguration
            .liquidatorsRewardPercentage = _liquidatorsRewardPercentage;
        feeConfiguration.fixedFeeSplit = _fixedFeeSplit;
        mFeeReceiver = _mFeeReceiver;
        strategyValues.mFeePercent = _mFeePercent;
        feeConfiguration.executionFee = _executionFee;
    }

    function setMC(
        address _MasterChef,
        uint128 _MCPID
    ) public onlyOwner zeroAddress(_MasterChef) {
        strategyAddresses.MasterChef = _MasterChef;
        strategyValues.MCPID = _MCPID;
    }

    function updateDebtAdjustment() external {
        require(msg.sender == leverageParams.keeper, "EQBVault: !keeper");
        require(IWater(water).getUtilizationRate() > (leverageParams.DTVLimit), "UR > DTV");
        require(
            block.timestamp - debtAdjustmentValues.time > debtAdjustmentValues.debtAdjustmentInterval,
            "Invalid time"
        );

        debtAdjustmentValues.debtAdjustment =
            debtAdjustmentValues.debtAdjustment +
            (debtAdjustmentValues.debtAdjustment * debtAdjustmentValues.debtValueRatio) /
            1e18;
        debtAdjustmentValues.time = uint128(block.timestamp);
    }

    function getUpdatedDebt(
        uint256 _positionID,
        address _user
    )
        public
        view
        returns (
            uint256 currentDTV,
            uint256 currentDTVWithDA,
            uint256 currentPosition,
            uint256 currentDebt,
            uint256 currentLeverageWithDA
        )
    {
        UserInfo memory _userInfo = userInfo[_user][_positionID];
        if (_userInfo.closed || _userInfo.liquidated) return (0, 0, 0, 0, 0);

        uint256 previousValueInUSDC;
        // Get the current position and previous value in USDC using the `getCurrentPosition` function
        (currentPosition, previousValueInUSDC) = getCurrentPosition(
            _positionID,
            _user
        );
        uint256 leverage = _userInfo.leverageAmount;

        // Calculate the current DTV by dividing the amount owed to water by the current position
        currentDTV = leverage.mulDiv(DECIMAL, currentPosition);
        // get current user leverage amount with debt adjustment
        currentLeverageWithDA = getCurrentLeverageAmount(_positionID, _user);
        currentDTVWithDA = currentLeverageWithDA.mulDiv(DECIMAL, currentPosition);
        // Return the current DTV, current position, and amount owed to water
        return (currentDTV, currentDTVWithDA, currentPosition, leverage, currentLeverageWithDA);
    }

    function getCurrentPosition(
        uint256 _positionID,
        address _user
    )
        public
        view
        returns (uint256 currentPosition, uint256 previousValueInUSDC)
    {
        PositionEntryGrowthMixX96X64
            memory _userEntryGrowth = userPositionEntryGrowthMixX96X64[_user][
                _positionID
            ];
        // prettier-ignore
        int256 _entryUnrealizedPnLGrowthX64 = IMarketPosition(
            strategyAddresses.MarketManager
        ).globalLiquidityPositions(_userEntryGrowth.market).unrealizedPnLGrowthX64;

        int256 currentPnLValue = _determinePnLOfAPosWithGLP(
                _userEntryGrowth.entryFundingRateGrowthX96,
                _entryUnrealizedPnLGrowthX64
            );

        // current value in usdc can be seen to always return either + or - value of position at open to determine PnL
        currentPosition = uint256(
            int256(uint256(userInfo[_user][_positionID].deposit + userInfo[_user][_positionID].leverageAmount)) + currentPnLValue);

        // previous value in usdc can be seen to always return the value of the position at open
        previousValueInUSDC = uint256(userInfo[_user][_positionID].deposit + userInfo[_user][_positionID].leverageAmount);
    }

    function getCurrentLeverageAmount(uint256 _positionID, address _user) public view returns (uint256) {
        UserInfo memory _userInfo = userInfo[_user][_positionID];
        uint256 previousDA = _userInfo.userDebtAdjustmentValue;
        uint256 userLeverageAmount = _userInfo.leverageAmount;
        if (debtAdjustmentValues.debtAdjustment > _userInfo.userDebtAdjustmentValue) {
            userLeverageAmount = userLeverageAmount.mulDiv(debtAdjustmentValues.debtAdjustment, previousDA);
        }
        return (userLeverageAmount);
    }

    function getVaultGlobalPosition(
        address _asset
    ) public view returns (IMarketPosition.LiquidityPosition memory _LPposition) {
        MarketInfo memory _marketInfo = marketInfo[_asset];
        _LPposition = IMarketPosition(strategyAddresses.MarketManager).liquidityPositions(
            _marketInfo.market,
            address(this)
        );
    }


    function getGlobalLiquidityPosition(
        address _asset
    )
        public
        view
        returns (IMarketPosition.GlobalLiquidityPosition memory _lPosition)
    {
        MarketInfo memory _marketInfo = marketInfo[_asset];
        _lPosition = IMarketPosition(strategyAddresses.MarketManager)
            .globalLiquidityPositions(_marketInfo.market);
    }

    function requestOpenLiquidityPosition(
        uint128 _amount,
        uint128 _leverage,
        address _asset
    ) external payable nonReentrant whenNotPaused returns(uint128 index) {
        require(
            _leverage >= strategyValues.MIN_LEVERAGE &&
                _leverage <= strategyValues.MAX_LEVERAGE,
            "EQBVault: !leverage"
        );
        require(_amount > 0, "EQBVault: amount is 0");
        uint256 ipRouterFee = IPositionRouter(strategyAddresses.PositionRouter).minExecutionFee();
        require(
            msg.value >= ipRouterFee + feeConfiguration.executionFee,
            "EQBVault: !fee"
        );
        IERC20(USDT).transferFrom(msg.sender, address(this), _amount);

        MarketInfo memory _marketInfo = marketInfo[_asset];
        require(_marketInfo.isEnabled, "EQBVault: !enabled");

        // get leverage amount
        uint256 _leveragedAmount = _amount.mulDiv(_leverage, DENOMINATOR) -
            _amount;
        IWater(water).lend(_leveragedAmount, address(this));

        uint128 sumAmount = _amount + uint128(_leveragedAmount);

        IERC20(USDT).approve(strategyAddresses.Router, sumAmount);

        index = IPositionRouter(strategyAddresses.PositionRouter)
            .createIncreaseLiquidityPosition{value: ipRouterFee}(
            _marketInfo.market,
            sumAmount,
            strategyValues.defaulLiquiditySize,
            0
        ); // @todo remember to update _acceptableMinMargin from 0 to at least -2% of the position
        
        DepositRecord storage _depositRecord = depositRecords[index];
        _depositRecord.user = msg.sender;
        _depositRecord.depositedAmount = _amount;
        _depositRecord.leverageAmount = uint128(_leveragedAmount);
        _depositRecord.leverageMultiplier = uint16(_leverage);
        _depositRecord.market = _marketInfo.market;
        
        emit RequestedOpenPosition(msg.sender, _amount, block.timestamp, index);

        return index;
    }

    function requestCloseLiquidityPosition(
        uint128 _userPositionId,
        uint128 _acceptableMinMargin
    ) external payable nonReentrant whenNotPaused returns(uint128 index, uint128 marginDelta) {
        uint256 ipRouterFee = IPositionRouter(strategyAddresses.PositionRouter).minExecutionFee();
        require(
            msg.value >= ipRouterFee + feeConfiguration.executionFee,
            "EQBVault: !fee"
        );
        require(!inCloseProcess[msg.sender][_userPositionId], "EQBVault: in process");
        UserInfo storage _userInfo = userInfo[msg.sender][_userPositionId];
        // prettier-ignore
        PositionEntryGrowthMixX96X64 memory _userEntryGrowth = userPositionEntryGrowthMixX96X64[msg.sender][_userPositionId];
        require(!_userInfo.closed, "EQBVault: is closed");
        require(!_userInfo.liquidated, "EQBVault: liquidated");
        require(_userInfo.user == msg.sender,"EQBVault: not owned by user");
        require(_userInfo.position > 0, "EQBVault: is 0");
        (, uint256 currentDTVWithDA, , , ) = getUpdatedDebt(
            _userPositionId,
            msg.sender
        );

        if (currentDTVWithDA >= (leverageParams.DTVLimit * leverageParams.DTVSlippage) / 1000) {
            revert("Wait for liquidation");
        }

        (uint256 currentPosition, ) = getCurrentPosition(_userPositionId, msg.sender);
        marginDelta = uint128(currentPosition);

        index = IPositionRouter(strategyAddresses.PositionRouter)
            .createDecreaseLiquidityPosition{value: ipRouterFee}(
            _userEntryGrowth.market,
            _acceptableMinMargin == 0 ? marginDelta : _acceptableMinMargin,
            strategyValues.defaulLiquiditySize,
            0, // @todo determine the acceptableMinMargin
            address(this)
        );
        
        WithdrawRecord storage _withdrawRecord = withdrawRecords[index];
        _withdrawRecord.positionID = _userPositionId;
        _withdrawRecord.user = msg.sender;
        _withdrawRecord.closedMarginDelta = uint256(marginDelta);
        inCloseProcess[msg.sender][_userPositionId] = true;
        emit RequestedClosePosition(msg.sender, uint256(marginDelta), block.timestamp, index, uint32(_userPositionId));
    }

    function requestLiquidatePosition(address _user, uint128 _userPositionId) external payable nonReentrant returns(uint128 index, uint128 marginDelta) {
        uint256 ipRouterFee = IPositionRouter(strategyAddresses.PositionRouter).minExecutionFee();
        require(
            msg.value == ipRouterFee + feeConfiguration.executionFee,
            "EQBVault: fee is !correct"
        );
        require(!inCloseProcess[_user][_userPositionId], "EQBVault: in process");
        UserInfo storage _userInfo = userInfo[_user][_userPositionId];
        // prettier-ignore
        PositionEntryGrowthMixX96X64 memory _userEntryGrowth = userPositionEntryGrowthMixX96X64[_user][_userPositionId];
        require(!_userInfo.closed, "EQBVault: closed");
        require(!_userInfo.liquidated, "EQBVault: liquidated");
        require(_userInfo.position > 0, "EQBVault: is 0");
        (, uint256 currentDTVWithDA, , , ) = getUpdatedDebt(
            _userPositionId,
            msg.sender
        );

        require(currentDTVWithDA >= (leverageParams.DTVLimit * leverageParams.DTVSlippage) / 1000, "Liquidation threshold !yet");

        (uint256 currentPosition, ) = getCurrentPosition(_userPositionId, msg.sender);

        marginDelta = uint128(currentPosition);

        index = IPositionRouter(strategyAddresses.PositionRouter)
            .createDecreaseLiquidityPosition{value: ipRouterFee}(
            _userEntryGrowth.market,
            marginDelta,
            strategyValues.defaulLiquiditySize,
            0, // @todo determine the acceptableMinMargin
            address(this)
        );

        WithdrawRecord storage _withdrawRecord = withdrawRecords[index];
        _withdrawRecord.positionID = _userPositionId;
        _withdrawRecord.user = _user;
        _withdrawRecord.isLiquidation = true;
        _withdrawRecord.liquidator = msg.sender;
        inCloseProcess[msg.sender][_userPositionId] = true;

        emit RequestedClosePosition(msg.sender, uint256(marginDelta), block.timestamp, index, uint32(_userPositionId));        
    }

    function fulfillOpenCancellation(uint128 index) public onlyExecutors returns (bool) {
        DepositRecord storage _depositRecord = depositRecords[index];
        require(!_depositRecord.isOrderCompleted, "EQBVault: already fulfilled");
        //refund the leverage to water
        IERC20(USDT).approve(water, _depositRecord.leverageAmount);
        IWater(water).repayDebt(_depositRecord.leverageAmount, _depositRecord.leverageAmount);
        //refund the fee to user
        IERC20(USDT).transfer(_depositRecord.user, _depositRecord.depositedAmount);
        _depositRecord.isOrderCompleted = true;
        payable(msg.sender).transfer(feeConfiguration.executionFee);
        emit OpenPositionCancelled(_depositRecord.user, _depositRecord.depositedAmount, block.timestamp, index);

        return true;
    }

    function fulfillOpenPositionRequest(uint128 index) external onlyExecutors {
        DepositRecord storage _depositRecord = depositRecords[index];
        require(!_depositRecord.isOrderCompleted, "EQBVault: already fulfilled");
        require(_depositRecord.user != address(0), "EQBVault: is 0");

        int256 entryUnrealizedPnLGrowthX64 = IMarketPosition(strategyAddresses.MarketManager).liquidityPositions(
            _depositRecord.market,
            address(this)
        ).entryUnrealizedPnLGrowthX64;

        int256 _entryUnrealizedPnLGrowthX64 = IMarketPosition(
            strategyAddresses.MarketManager
        ).globalLiquidityPositions(_depositRecord.market).unrealizedPnLGrowthX64;

        uint128 _userPosition = (_depositRecord.depositedAmount + _depositRecord.leverageAmount) * 1e12;

        UserInfo memory _userInfo = UserInfo({
            user: _depositRecord.user,
            deposit: _depositRecord.depositedAmount,
            leverage: _depositRecord.leverageMultiplier,
            position: _userPosition,
            userDebtAdjustmentValue: uint128(debtAdjustmentValues.debtAdjustment),
            closedPositionValue: 0,
            closePNL: 0,
            leverageAmount: uint128(_depositRecord.leverageAmount),
            positionId: uint96(userInfo[_depositRecord.user].length),
            liquidator: address(0),
            liquidated: false,
            closed: false
        });

        //frontend helper to fetch all users and then their userInfo
        if (isUser[_depositRecord.user] == false) {
            isUser[_depositRecord.user] = true;
            allUsers.push(_depositRecord.user);
        }
        userPositionEntryGrowthMixX96X64[_depositRecord.user].push(
            PositionEntryGrowthMixX96X64({
                entryFundingRateGrowthX96: entryUnrealizedPnLGrowthX64 ==
                    int192(0)
                    ? int192(_entryUnrealizedPnLGrowthX64)
                    : int192(entryUnrealizedPnLGrowthX64), // endeavour to changer the layout to int256
                entryUnrealizedPnLGrowthX64: _entryUnrealizedPnLGrowthX64,
                market: _depositRecord.market
            })
        );
        _depositRecord.isOrderCompleted = true;
        payable(msg.sender).transfer(feeConfiguration.executionFee);
        userInfo[_depositRecord.user].push(_userInfo);

        _mint(_depositRecord.user, _userPosition);
        emit FulfillOpenPosition(
            _depositRecord.user,
            _depositRecord.market,
            _depositRecord.depositedAmount,
            block.timestamp,
            _depositRecord.leverageAmount,
            _userInfo.positionId
        );
    }

    function fulfillCloseCancellation(uint128 index) public onlyExecutors returns (bool) {
        WithdrawRecord storage _withdrawRecords = withdrawRecords[index];
        UserInfo storage _userInfo = userInfo[_withdrawRecords.user][_withdrawRecords.positionID];
        require(!_withdrawRecords.isOrderCompleted, "EQBVault: fulfilled");

        inCloseProcess[_withdrawRecords.user][uint128(_withdrawRecords.positionID)] = false;
        _withdrawRecords.isOrderCompleted = false;
        payable(msg.sender).transfer(feeConfiguration.executionFee);

        emit ClosePositionCancelled(_withdrawRecords.user, _userInfo.position, block.timestamp, index, _withdrawRecords.positionID);

        return true;
    }

    function fulfillClosePositionRequest(uint128 index, uint256 _returnedAmount) external onlyExecutors {
        WithdrawRecord storage _withdrawRecords = withdrawRecords[index];
        UserInfo storage _userInfo = userInfo[_withdrawRecords.user][_withdrawRecords.positionID];
        PositionEntryGrowthMixX96X64 memory _userEntryGrowth = userPositionEntryGrowthMixX96X64[_withdrawRecords.user][_withdrawRecords.positionID];
        require(!_withdrawRecords.isOrderCompleted, "EQBVault: fulfilled");
        require(inCloseProcess[_withdrawRecords.user][uint128(_withdrawRecords.positionID)], "EQBVault: close");
        require(_returnedAmount >= _withdrawRecords.closedMarginDelta, "EQBVault: !acceptable");
        CloseData memory closeData;
        _handlePODToken(_userInfo.user, _userInfo.position);

        _withdrawRecords.returnedAmount = _returnedAmount;
        
        closeData.totalPositionValue = uint128(_userInfo.position);

        if (_returnedAmount > uint256(closeData.totalPositionValue)) {
            closeData.profits = uint128(
                _returnedAmount - uint256(closeData.totalPositionValue)
            );
        }

        uint128 waterRepayment;
        (, , , , uint256 currentDebtWithDA) = getUpdatedDebt(
            _withdrawRecords.positionID,
            _withdrawRecords.user
        );

        if (_returnedAmount <= _userInfo.leverageAmount) {
            _userInfo.liquidator = msg.sender;
            _userInfo.liquidated = true;
            waterRepayment = uint128(_returnedAmount);
        } else {
            if (closeData.profits > 0) {
                (
                    closeData.waterProfits,
                    closeData.mFee,
                    closeData.userShares
                ) = _getProfitSplit(closeData.profits, _userInfo.leverage);
            }

            waterRepayment = uint128(currentDebtWithDA);
            closeData.toLeverageUser =
                (uint128(_returnedAmount) - waterRepayment) -
                closeData.waterProfits -
                closeData.mFee;
        }

        IERC20(USDT).approve(water, waterRepayment);
        // prettier-ignore
        bool success = IWater(water).repayDebt(uint256(_userInfo.leverageAmount), waterRepayment);
        require(success, "Water: failed");
        _userInfo.position = 0;
        _userInfo.leverageAmount = 0;
        _userInfo.closed = true;

        if (_userInfo.liquidated) {
            return;
        }

        if (closeData.waterProfits > 0) {
            // prettier-ignore
            IERC20(USDT).transfer(feeConfiguration.waterFeeReceiver, closeData.waterProfits);
        }

        if (closeData.mFee > 0) {
            IERC20(USDT).transfer(mFeeReceiver, closeData.mFee);
        }

        _withdrawRecords.isOrderCompleted = true;

        // take protocol fee
        uint256 amountAfterFee;
        if (feeConfiguration.withdrawalFee > 0) {
            // prettier-ignore
            uint256 fee = closeData.toLeverageUser.mulDiv( feeConfiguration.withdrawalFee, strategyValues.MAX_BPS);
            IERC20(USDT).transfer(feeConfiguration.feeReceiver, fee);
            amountAfterFee = closeData.toLeverageUser - fee;
        } else {
            amountAfterFee = closeData.toLeverageUser;
        }

        IERC20(USDT).transfer(_userInfo.user, amountAfterFee);

        _userInfo.closedPositionValue = uint128(closeData.totalPositionValue);
        _userInfo.closePNL = uint128(closeData.profits);
        emit FulfillClosePosition(
            _userInfo.user,
            _userInfo.deposit,
            block.timestamp,
            closeData.totalPositionValue,
            closeData.waterProfits,
            closeData.toLeverageUser,
            _userEntryGrowth.entryUnrealizedPnLGrowthX64,
            _userInfo.positionId
        );
    }

    function fulfillLiquidation(uint128 index, uint256 _returnedAmount) external nonReentrant onlyExecutors {
        WithdrawRecord storage _withdrawRecords = withdrawRecords[index];
        UserInfo storage _userInfo = userInfo[_withdrawRecords.user][_withdrawRecords.positionID];
        require(!_withdrawRecords.isOrderCompleted, "EQBVault: fulfilled");
        require(inCloseProcess[_withdrawRecords.user][uint128(_withdrawRecords.positionID)], "EQBVault: !in close process");
        CloseData memory closeData;
        _handlePODToken(_userInfo.user, _userInfo.position);

        _withdrawRecords.returnedAmount = _returnedAmount;
        
        closeData.totalPositionValue = uint128(_userInfo.position);

        _withdrawRecords.returnedAmount = _returnedAmount;

        uint256 liquidatorReward;
        if (_returnedAmount >= _userInfo.leverageAmount) {
            _returnedAmount -= _userInfo.leverageAmount;

            liquidatorReward = _returnedAmount.mulDiv(feeConfiguration.liquidatorsRewardPercentage, strategyValues.MAX_BPS);
            IERC20(USDT).transfer(_withdrawRecords.liquidator, liquidatorReward);

            uint256 leftovers = _returnedAmount - liquidatorReward;

            IERC20(USDT).approve(water, leftovers + _userInfo.leverageAmount);
            IWater(water).repayDebt(_userInfo.leverageAmount, leftovers + _userInfo.leverageAmount);
        } else {
            IERC20(USDT).approve(water, _returnedAmount);
            IWater(water).repayDebt(_userInfo.leverageAmount, _returnedAmount);
        }

        _userInfo.liquidator = _withdrawRecords.liquidator;
        _userInfo.liquidated = true;
        _userInfo.position = 0;

        emit FulfillLiquidation(
            _userInfo.user,
            _userInfo.positionId,
            _withdrawRecords.liquidator,
            _withdrawRecords.returnedAmount,
            liquidatorReward
        );
    }
    
    /** ----------- Token functions ------------- */

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        require(
            allowedSenders[from] ||
                allowedSenders[to] ||
                allowedSenders[spender],
            "ERC20: transfer not allowed"
        );
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address ownerOf = _msgSender();
        require(
            allowedSenders[ownerOf] || allowedSenders[to],
            "ERC20: transfer not allowed"
        );
        _transfer(ownerOf, to, amount);
        return true;
    }

    function burn(uint256 amount) public virtual override onlyBurner {
        _burn(_msgSender(), amount);
    }

    function _determinePnLOfAPosWithGLP(
        int192 _userVaultEntryRate,
        int256 _globalPnL
    ) internal view returns (int256 realizedPnL) {
        realizedPnL = _calculateRealizedPnL(
            _userVaultEntryRate,
            _globalPnL
        );
    }

    function _calculateRealizedPnL(
        int192 _userVaultEntryRate,
        int256 _globalPnL
    ) internal view returns (int256 realizedPnL) {
        int256 _unrealizedPnL = _globalPnL - _userVaultEntryRate;
        // @todo decide if strategyValues.defaulLiquiditySize should be resetable by the owner
        // cause if a pos is opened with 1e6 and owner reset it to 2e6, the unrealizedPnL for the pos will be wrong
        realizedPnL = _unrealizedPnL >= 0
            ? int256(
                Math.mulDiv(
                    uint256(_unrealizedPnL),
                    strategyValues.defaulLiquiditySize,
                    Q64
                )
            ) // if it is greater than 0 then the output will be positive
            : -int256(
                Math.mulDiv(
                    uint256(-_unrealizedPnL),
                    strategyValues.defaulLiquiditySize,
                    Q64
                )
            );

        return realizedPnL;
    }

    function _getProfitSplit(
        uint128 _profit,
        uint128 _leverage
    ) internal view returns (uint128, uint128, uint128) {
        uint256 split = (feeConfiguration.fixedFeeSplit *
            _leverage +
            (feeConfiguration.fixedFeeSplit * 10000)) / 100;
        uint128 toWater = (_profit * uint128(split)) / 10000;
        uint128 mFee = (_profit * strategyValues.mFeePercent) / 10000;
        uint128 toSakeUser = _profit - (toWater + mFee);

        return (toWater, mFee, toSakeUser);
    }

    function _handlePODToken(address _user, uint256 position) internal {
        if (strategyAddresses.MasterChef != address(0)) {
            uint256 userBalance = balanceOf(_user);
            if (userBalance >= position) {
                _burn(_user, position);
            } else {
                _burn(_user, userBalance);
                uint256 remainingPosition = position - userBalance;
                (uint256 amountDeposited, ) = IMasterChef(
                    strategyAddresses.MasterChef
                ).userInfo(strategyValues.MCPID, _user);
                if (amountDeposited > 0)
                    IMasterChef(strategyAddresses.MasterChef)
                        .unstakeAndLiquidate(
                            strategyValues.MCPID,
                            _user,
                            remainingPosition
                        );
            }
        } else {
            _burn(_user, position);
        }
    }

    // should be able to receive ETH
    receive() external payable {}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.21;


/// @notice Interface for managing market positions.
/// @dev The market position is the core component of the protocol, which stores the information of
/// all trader's positions and the funding rate.
interface IMarketPosition {
    struct GlobalPosition {
        /// @notice The sum of long position sizes
        uint128 longSize;
        /// @notice The sum of short position sizes
        uint128 shortSize;
        /// @notice The maximum available size of all positions
        uint128 maxSize;
        /// @notice The maximum available size of per position
        uint128 maxSizePerPosition;
        /// @notice The funding rate growth per unit of long position sizes, as a Q96.96
        int192 longFundingRateGrowthX96;
        /// @notice The funding rate growth per unit of short position sizes, as a Q96.96
        int192 shortFundingRateGrowthX96;
    }

    struct PreviousGlobalFundingRate {
        /// @notice The funding rate growth per unit of long position sizes, as a Q96.96
        int192 longFundingRateGrowthX96;
        /// @notice The funding rate growth per unit of short position sizes, as a Q96.96
        int192 shortFundingRateGrowthX96;
    }

    struct GlobalFundingRateSample {
        /// @notice The timestamp of the last funding rate adjustment
        uint64 lastAdjustFundingRateTime;
        /// @notice The number of samples taken since the last funding rate adjustment
        uint16 sampleCount;
        /// @notice The cumulative premium rate of the samples taken
        /// since the last funding rate adjustment, as a Q80.96
        int176 cumulativePremiumRateX96;
    }
    

    struct Position {
        /// @notice The margin of the position
        uint128 margin;
        /// @notice The size of the position
        uint128 size;
        /// @notice The entry price of the position, as a Q64.96
        uint160 entryPriceX96;
        /// @notice The snapshot of the funding rate growth at the time the position was opened.
        /// For long positions it is `GlobalPosition.longFundingRateGrowthX96`,
        /// and for short positions it is `GlobalPosition.shortFundingRateGrowthX96`
        int192 entryFundingRateGrowthX96;
    }

    struct GlobalLiquidityPosition {
        /// @notice The size of the net position held by all LPs
        uint128 netSize;
        /// @notice The size of the net position held by all LPs in the liquidation buffer
        uint128 liquidationBufferNetSize;
        /// @notice The Previous Settlement Point Price, as a Q64.96
        uint160 previousSPPriceX96;
        /// @notice The side of the position (Long or Short)
        uint8 side;
        /// @notice The total liquidity of all LPs
        uint128 liquidity;
        /// @notice The accumulated unrealized Profit and Loss (PnL) growth per liquidity unit, as a Q192.64.
        /// The value is updated when the following actions are performed:
        ///     1. Settlement Point is reached
        ///     2. Trading fee is added
        ///     3. Funding fee is added
        ///     4. Liquidation loss is added
        int256 unrealizedPnLGrowthX64;
    }

    struct LiquidityPosition {
        /// @notice The margin of the position
        uint128 margin;
        /// @notice The liquidity (value) of the position
        uint128 liquidity;
        /// @notice The snapshot of `GlobalLiquidityPosition.realizedProfitGrowthX64`
        /// at the time of the position was opened.
        int256 entryUnrealizedPnLGrowthX64;
    }
    
    /// @notice Get the global position of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function globalPositions(address market) external view returns (GlobalPosition memory);

    /// @notice Get the previous global funding rate growth of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function previousGlobalFundingRates(
        address market
    ) external view returns (PreviousGlobalFundingRate memory);

    /// @notice Get the global funding rate sample of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function globalFundingRateSamples(address market) external view returns (GlobalFundingRateSample memory);

    /// @notice Get the information of a position
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    function positions(address market, address account, uint8 side) external view returns (Position memory);

    /// @notice Get the global liquidity position of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function globalLiquidityPositions(address market) external view returns (GlobalLiquidityPosition memory);

    /// @notice Get the information of a liquidity position
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    function liquidityPositions(
        address market,
        address account
    ) external view returns (LiquidityPosition memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

/// @title Plugin Manager Interface
/// @notice The interface defines the functions to manage plugins
interface IPluginManager {
    /// @notice Approve a plugin
    /// @dev The call will fail if the plugin is not registered or already approved
    /// @param plugin The plugin to approve
    function approvePlugin(address plugin) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IPositionRouter {
    /// @notice The minimum fee to execute a request
    function minExecutionFee() external view returns (uint256);

    /// @notice Create open liquidity position request
    /// @param pool The address of the pool to open liquidity position
    /// @param _marginDelta Margin of the position
    /// @param _liquidityDelta Liquidity of the position
    /// @param _acceptableMinMargin Acceptable minimum margin
    /// @return index Index of the request
    function createIncreaseLiquidityPosition(
        address pool,
        uint128 _marginDelta,
        uint128 _liquidityDelta,
        uint128 _acceptableMinMargin
    ) external payable returns (uint128 index);

    /// @notice Execute open liquidity position request
    /// @param index Index of request to execute
    /// @param executionFeeReceiver Receiver of the request execution fee
    /// @return executed True if the execution succeeds or request not exists
    function executeIncreaseLiquidityPosition(
        uint128 index,
        address payable executionFeeReceiver
    ) external returns (bool executed);

    /// @notice Create decrease liquidity position request
    /// @param market The market in which to decrease liquidity position
    /// @param marginDelta The decrease in liquidity position margin
    /// @param liquidityDelta The decrease in liquidity position liquidity
    /// @param acceptableMinMargin The min acceptable margin of the request
    /// @param receiver Address of the margin receiver
    /// @return index The request index
    function createDecreaseLiquidityPosition(
        address market,
        uint128 marginDelta,
        uint128 liquidityDelta,
        uint128 acceptableMinMargin,
        address receiver
    ) external payable returns (uint128 index);

    /// @notice Execute close liquidity position request
    /// @param index Index of the request to execute
    /// @param executionFeeReceiver Receiver of the request execution fee
    /// @return executed True if the execution succeeds or request not exists
    function executeCloseLiquidityPosition(
        uint128 index,
        address payable executionFeeReceiver
    ) external returns (bool executed);

    /// @notice Execute multiple decrease liquidity position requests
    /// @param endIndex The maximum request index to execute, excluded
    /// @param executionFeeReceiver Receiver of the request execution fee
    function executeDecreaseLiquidityPositions(uint128 endIndex, address payable executionFeeReceiver) external;

    function increasePositionRequests(uint128 index) external view returns (IncreasePositionRequest memory);

    struct IncreasePositionRequest {
        address account;
        address market;
        uint8 side;
        uint128 marginDelta;
        uint128 sizeDelta;
        uint160 acceptableTradePriceX96;
        uint256 executionFee;
        uint96 blockNumber;
        uint64 blockTime;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IEQBLeverageVault {
    /// @notice Emitted when strategy addresses are updated
    /// @param rewardFarm New reward farm address
    /// @param router New router address
    event SetStrategyAddress(address indexed rewardFarm, address indexed router);

    /// @notice Emitted when pool is enabled/disabled
    /// @param pool Pool address
    /// @param enabled Enabled or disabled
    event SetPoolEnabled(address asset, address indexed pool, bool enabled);

    /// notice Emitted when user allowed sender is updated
    /// @param executor New sender address
    /// @param status Status of the sender
    event SetExecutor(address executor, bool status);

    /// @notice Emitted when default liquidity size is updated
    /// @param _size New default liquidity size
    event SetDefaultLiquiditySize(uint256 _size);

    /// @notice Emitted when user request to open a position
    /// @param user User address
    /// @param amount amount user deposited
    /// @param time Time of the transaction
    /// @param index Index of the request
    event RequestedOpenPosition(address indexed user, uint256 amount, uint256 time, uint256 index);

    /// @notice Emitted when user open a position
    /// @param user User address
    /// @param pool Pool address
    /// @param amount amount user deposited
    /// @param time Time of the transaction
    /// @param leverage Leverage of the position
    /// @param positionId Position id
    event FulfillOpenPosition(address indexed user, address indexed pool, uint256 amount, uint256 time, uint256 leverage, uint256 positionId);

    /// @notice Emitted when user cancel a position
    /// @param user User address
    /// @param amount amount user deposited
    /// @param time Time of the transaction
    /// @param index Order id
    event OpenPositionCancelled(address indexed user, uint256 amount, uint256 time, uint256 index);

    /// @notice Emitted when user request to close a position
    /// @param user User address
    /// @param amount amount scheduled to withdraw from eqb
    /// @param time Time of the transaction
    /// @param index index of the position from eqb
    /// @param positionId Position id
    event RequestedClosePosition(address indexed user, uint256 amount, uint256 time, uint256 index, uint32 positionId);

    /// @notice Emitted when user close a position
    /// @param user User address
    /// @param amount amount user deposited
    /// @param time Time of the transaction
    /// @param returnedUSDC Amount of USDC returned to user
    /// @param waterProfit Water profit
    /// @param leverageUserProfit Leverage user profit
    /// @param unrealisedPnL pnl at the time of closing
    /// @param positionID Position id
    event FulfillClosePosition(
        address indexed user,
        uint256 amount,
        uint256 time,
        uint256 returnedUSDC,
        uint256 waterProfit,
        uint256 leverageUserProfit,
        int256 unrealisedPnL,
        uint256 positionID
    );

    // @notice Emitted when user cancel a position
    /// @param user User address
    /// @param amount amount user deposited
    /// @param time Time of the transaction
    /// @param index index id
    /// @param positionId Position id
    event ClosePositionCancelled(address indexed user, uint256 amount, uint256 time, uint256 index, uint256 positionId);

    /// @notice Emitted when user liquidate a position
    /// @param user User address
    /// @param positionID Position id
    /// @param liquidator Liquidator address
    /// @param closePositionValue Close position value
    /// @param liquidatorReward Liquidator reward
    event FulfillLiquidation(
        address indexed user,
        uint256 positionID,
        address liquidator,
        uint256 closePositionValue,
        uint256 liquidatorReward
    );

    /// @notice Emitted when protocol fees changes
    /// @param newFeeReceiver New fee receiver address
    /// @param newWithdrawalFee New withdrawal fee
    /// @param newWaterFeeReceiver New water fee receiver address
    /// @param liquidatorsRewardPercentage Liquidators reward percentage
    /// @param fixedFeeSplit Fixed fee split
    event ProtocolFeeChanged(
        address newFeeReceiver,
        uint256 newWithdrawalFee,
        address newWaterFeeReceiver,
        uint256 liquidatorsRewardPercentage,
        uint256 fixedFeeSplit
    );

    /// @notice Emitted when masterchef and pid is updated
    /// @param newMC New masterchef address
    /// @param mcpPid New mcp pid
    event UpdateMCAndPID(address indexed newMC, uint256 mcpPid);

    /// @notice Emitted when user burner address is updated
    /// @param newBurner New burner address
    /// @param status Status of the burner
    event SetBurner(address indexed newBurner, bool status);

    /// @notice Emitted when user allowed sender is updated
    /// @param sender New sender address
    /// @param status Status of the sender
    event SetAllowedSender(address indexed sender, bool status);

    /// @notice Emitted when leverage params are updated
    /// @param DTVLimit New DTV limit
    /// @param DTVSlippage New DTV slippage
    event SetLeverageParams(uint128 DTVLimit, uint128 DTVSlippage);

    /// @notice Emitted when debt ratio and time interval are updated
    /// @param debtValueRatio New debt value ratio
    /// @param debtAdjustmentInterval New debt adjustment interval
    event SetDebtRatioAndTimeInterval(uint256 debtValueRatio, uint256 debtAdjustmentInterval);

    struct CloseData {
        uint128 totalPositionValue;
        uint128 profits;
        uint128 waterProfits;
        uint128 mFee;
        uint128 userShares;
        uint128 toLeverageUser;
    }

    struct StrategyAddresses{
        address Router; // Router address
        address PositionRouter; // Position router address, serves as the main entry contract for opening/closing liquidity positions
        address MarketManager; // Market manager address
        address MasterChef; // MasterChef address
    }

    struct MarketInfo {
        address market;  // Address of the market
        bool isEnabled; // Is market enabled
    }

    struct FeeConfiguration {
        /// @custom:oz-renamed-from eqbOpenCloseFees
        uint256 executionFee; // Execution fee
        address feeReceiver;
        uint256 withdrawalFee;
        address waterFeeReceiver;
        uint256 liquidatorsRewardPercentage;
        uint256 fixedFeeSplit;
    }

    struct LeverageParams {
        uint128 DTVLimit; // Default liquidity size
        uint128 DTVSlippage; // Default liquidity slippage
        address keeper;
    }

    struct UserInfo {
        address user;
        uint128 deposit; 
        uint128 leverage;
        uint128 position;
        uint128 userDebtAdjustmentValue;
        uint128 closedPositionValue;
        uint128 closePNL;
        uint128 leverageAmount;
        uint96 positionId;
        address liquidator;
        bool liquidated; 
        bool closed;
    }

    struct DepositRecord {
        address user;
        uint128 depositedAmount;
        uint128 leverageAmount;
        int192 entryFundingRateGrowthX96;
        uint16 leverageMultiplier;
        bool isOrderCompleted;
        int256 entryUnrealizedPnLGrowthX64;
        address market;
    }

    struct WithdrawRecord {
        uint256 positionID;
        address user;
        bool isOrderCompleted;
        bool isLiquidation;
        uint256 fullDebtValue;
        uint256 returnedAmount;
        address liquidator;
        uint256 closedMarginDelta;
    }

    struct PositionEntryGrowthMixX96X64 {
        int192 entryFundingRateGrowthX96; // entryUnrealizedPnLGrowthX64 kindly use int256
        int256 entryUnrealizedPnLGrowthX64; // the global unrealized PnL growth of the position
        address market;
    }

    struct StrategyValues {
        uint128  defaulLiquiditySize;
        uint128  MAX_BPS;
        uint128  MAX_LEVERAGE;
        uint128  MIN_LEVERAGE;
        uint128  mFeePercent;
        uint128  MCPID;
    }

    struct DebtAdjustmentValues {
        uint256 defaultDebtAdjustmentValue;
        uint128 debtAdjustment;
        uint128 time;
        uint128 debtValueRatio;
        uint128 debtAdjustmentInterval;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IMasterChef {
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function unstakeAndLiquidate(uint256 _pid, address user, uint256 amount) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

interface IWater {
    function lend(uint256 _amount, address _receiver) external returns (bool);

    function repayDebt(uint256 leverage, uint256 debtValue) external returns (bool);

    function getTotalDebt() external view returns (uint256);

    function getUtilizationRate() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function balanceOfUSDC() external view returns (uint256);
}