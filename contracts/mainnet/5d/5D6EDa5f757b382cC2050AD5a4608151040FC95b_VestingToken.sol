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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
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

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
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
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: None
// Unvest Contracts (last updated v3.0.0) (VestingToken.sol)
pragma solidity ^0.8.24;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import { Errors } from "./libraries/Errors.sol";
import { Arrays } from "./libraries/Arrays.sol";
import { IFeeManager } from "./interfaces/IFeeManager.sol";
import { IVestingToken } from "./interfaces/IVestingToken.sol";

/*

 _   _  _   _ __     __ _____  ____  _____ 
| | | || \ | |\ \   / /| ____|/ ___||_   _|
| | | ||  \| | \ \ / / |  _|  \___ \  | |  
| |_| || |\  |  \ V /  | |___  ___) | | |  
 \___/ |_| \_|   \_/   |_____||____/  |_|  
                                           
 */

/// @title VestingToken
/// @notice VestingToken locks ERC20 and contains the logic for tokens to be partially unlocked based on milestones.
/// @author JA (@ubinatus) v3
/// @author Klaus Hott (@Janther) v2
contract VestingToken is ERC20Upgradeable, ReentrancyGuardUpgradeable, IVestingToken {
    using SafeERC20 for ERC20Upgradeable;

    /// @dev `claimedAmountAfterTransfer` is used to calculate the `_claimableAmount` of an account. It's value is
    /// updated on every `transfer`, `transferFrom`, and `claim` calls.
    /// @dev While `claimedAmountAfterTransfer` contains a fraction of the `claimedAmountAfterTransfer`s of every token
    /// transfer the owner of account receives, `claimedBalance` works as a counter for tokens claimed by this account.
    struct Metadata {
        uint256 claimedAmountAfterTransfer;
        uint256 claimedBalance;
    }

    /// @param account Address that will receive the `amount` of `underlyingToken`.
    /// @param amount  Amount of tokens that will be sent to the `account`.
    event Claim(address indexed account, uint256 amount);

    /// @param account Address that will burn the `amount` of `underlyingToken`.
    /// @param amount  Amount of tokens that will be sent to the dead address.
    event Burn(address indexed account, uint256 amount);

    /// @param milestoneIndex Index of the Milestone reached.
    event MilestoneReached(uint256 indexed milestoneIndex);

    /// @dev Percentages and fees are calculated using 18 decimals where 1 ether is 100%.
    uint256 internal constant ONE = 1 ether;

    /// @notice The ERC20 token that this contract will be vesting.
    ERC20Upgradeable public underlyingToken;

    /// @notice The manager that deployed this contract which controls the values for `fee` and `feeCollector`.
    IFeeManager public manager;

    /// @dev The `decimals` value that is fetched from `underlyingToken`.
    uint8 internal _decimals;

    /// @dev The initial supply used for calculating the `claimableSupply`, `claimedSupply`, and `lockedSupply`.
    uint256 internal _startingSupply;

    /// @dev The imported claimed supply is necessary for an accurate `claimableSupply` but leads to an improper offset
    /// in `claimedSupply`, so we keep track of this to account for it.
    uint256 internal _importedClaimedSupply;

    /// @notice An array of Milestones describing the times and behaviour of the rules to release the vested tokens.
    Milestone[] internal _milestones;

    /// @notice Keep track of the last reached Milestone to minimize the iterations over the milestones and save gas.
    uint256 internal _lastReachedMilestone;

    /// @dev Maps a an address to the metadata needed to calculate `claimableBalance` and `lockedBalanceOf`.
    mapping(address => Metadata) internal _metadata;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract by setting up the ERC20 variables, the `underlyingToken`, and the
     * `milestonesArray` information.
     *
     * @dev The Ramp of the first Milestone in the `milestonesArray` will always act as a Cliff since it doesn't have
     * a previous milestone.
     *
     * Requirements:
     *
     * - `underlyingTokenAddress` cannot be the zero address.
     * - `timestamps` must be given in ascending order.
     * - `percentages` must be given in ascending order and the last one must always be 1 eth, where 1 eth equals to
     * 100%.
     * - 2 `percentages` may have the same value as long as they are followed by a `Ramp.Linear` Milestone.
     *
     * @param name                   This ERC20 token name.
     * @param symbol                 This ERC20 token symbol.
     * @param underlyingTokenAddress The ERC20 token that will be held by this contract.
     * @param milestonesArray        Array of all `Milestone`s for this contract's lifetime.
     */
    function initialize(
        string calldata name,
        string calldata symbol,
        address underlyingTokenAddress,
        Milestone[] calldata milestonesArray
    )
        external
        override
        initializer
    {
        __ERC20_init(name, symbol);
        __ReentrancyGuard_init();

        manager = IFeeManager(msg.sender);

        _setupMilestones(milestonesArray);

        underlyingToken = ERC20Upgradeable(underlyingTokenAddress);
        _decimals = _tryFetchDecimals();
    }

    /// @dev Returns the number of decimals used to get its user representation. For example, if `decimals` equals `2`,
    /// a balance of `505` tokens should be displayed to a user as `5.05` (`505 / 10 ** 2`).
    ///
    /// Tokens usually opt for a value of 18, imitating the relationship between Ether and Wei. Since we can't predict
    /// the decimals the `underlyingToken` will have, we need to provide our own implementation which is setup at
    /// initialization.
    ///
    /// NOTE: This information is only used for _display_ purposes: it in no way affects any of the arithmetic of the
    /// contract.
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /// @notice Vests an `amount` of `underlyingToken` and mints LVTs for a `recipient`.
    ///
    /// Requirements:
    ///
    /// - `msg.sender` must have approved this contract an amount of `underlyingToken` greater or equal than `amount`.
    ///
    /// @param recipient The address that will receive the newly minted LVT.
    /// @param amount    The amount of `underlyingToken` to be vested.
    function addRecipient(address recipient, uint256 amount) external nonReentrant {
        uint256 currentBalance = _getBalanceOfThis();

        underlyingToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 transferredAmount = _getBalanceOfThis() - currentBalance;

        _startingSupply = _startingSupply + transferredAmount;
        _mint(recipient, transferredAmount);
    }

    /// @notice Vests multiple `amounts` of `underlyingToken` and mints LVTs for multiple `recipients`.
    ///
    /// Requirements:
    ///
    /// - `recipients` and `amounts` must have the same length.
    /// - `msg.sender` must have approved this contract an amount of `underlyingToken` greater or equal than the sum of
    /// all of the `amounts`.
    ///
    /// @param recipients Array of addresses that will receive the newly minted LVTs.
    /// @param amounts    Array of amounts of `underlyingToken` to be vested.
    function addRecipients(
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256 totalAmount
    )
        external
        nonReentrant
    {
        if (recipients.length != amounts.length) revert Errors.InputArraysMustHaveSameLength();
        uint256 currentBalance = _getBalanceOfThis();

        underlyingToken.safeTransferFrom(msg.sender, address(this), totalAmount);
        uint256 transferredAmount = _getBalanceOfThis() - currentBalance;

        _startingSupply = _startingSupply + transferredAmount;

        uint256 _totalAmount;
        uint256 recipientsLen = recipients.length;
        for (uint256 i = recipientsLen; i != 0;) {
            unchecked {
                --i;
            }

            address recipient = Arrays.unsafeMemoryAccess(recipients, i);
            uint256 curAmount = Arrays.unsafeMemoryAccess(amounts, i);
            _totalAmount += Arrays.unsafeMemoryAccess(amounts, i);
            uint256 amount =
                transferredAmount == totalAmount ? curAmount : (curAmount * transferredAmount) / totalAmount;
            _mint(recipient, amount);
        }

        if (_totalAmount != totalAmount) revert Errors.InvalidTotalAmount();
    }

    /**
     * @notice Behaves as `addRecipient` but provides the ability to set the initial state of the recipient's metadata.
     * @notice This functionality is included in order to allow users to restart an allocation on a different chain and
     * keeping the inner state as close as possible to the original.
     *
     * @dev The `Metadata.claimedAmountAfterTransfer` for the recipient is inferred from the parameters.
     * @dev The `Metadata.claimedBalance` is lost in the transfer, the closest value will be
     * `claimedAmountAfterTransfer`.
     * @dev In the rare case where the contract and it's users are migrated after the last milestone has been reached,
     * the `claimedAmountAfterTransfer` can't be inferred and the `claimedSupply` value for the whole contract is lost
     * in the transfer.
     * @dev The decision to do this is to minimize the altering of metadata to the amount that is being transferred and
     * protect an attack that would render the contract unusable.
     *
     * Requirements:
     *
     * - `unlocked` must be less than or equal to this contracts `unlockedPercentage`.
     * - `claimableAmountOfImport` must be less than or equal than the amount that would be claimable given the values
     *  of `amount` and `percentage`.
     * - `msg.sender` must have approved this contract an amount of `underlyingToken` greater or equal than `amount`.
     *
     * @param recipient               The address that will receive the newly minted LVT.
     * @param amount                  The amount of `underlyingToken` to be vested.
     * @param claimableAmountOfImport The amount of `underlyingToken` from this transaction that should be considered
     *                                claimable.
     * @param unlocked                The unlocked percentage value at the time of the export of this transaction.
     */
    function importRecipient(
        address recipient,
        uint256 amount,
        uint256 claimableAmountOfImport,
        uint256 unlocked
    )
        external
        nonReentrant
    {
        if (unlocked > unlockedPercentage()) revert Errors.UnlockedIsGreaterThanExpected();
        uint256 currentBalance = _getBalanceOfThis();

        underlyingToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 transferredAmount = _getBalanceOfThis() - currentBalance;

        uint256 claimedAmount = _claimedAmount(transferredAmount, claimableAmountOfImport, unlocked);

        _metadata[recipient].claimedAmountAfterTransfer =
            _metadata[recipient].claimedAmountAfterTransfer + claimedAmount;

        _importedClaimedSupply = _importedClaimedSupply + claimedAmount;
        _startingSupply = _startingSupply + transferredAmount + claimedAmount;
        _mint(recipient, transferredAmount);
    }

    /**
     *  @notice Behaves as `addRecipients` but provides the ability to set the initial state of the recipient's
     *  metadata.
     *  @notice This functionality is included in order to allow users to restart an allocation on a different chain and
     *  keeping the inner state as close as possible to the original.
     *
     *  @dev The `Metadata.claimedAmountAfterTransfer` for each recipient is inferred from the parameters.
     *  @dev The `Metadata.claimedBalance` is lost in the transfer, the closest value will be
     *  `claimedAmountAfterTransfer`.
     *  @dev In the rare case where the contract and it's users are migrated after the last milestone has been reached,
     *  the `claimedAmountAfterTransfer` can't be inferred and the `claimedSupply` value for the whole contract is lost
     *  in the transfer.
     *  @dev The decision to do this to minimize the altering of metadata to the amount that is being transferred and
     *  protect an attack that would render the contract unusable.
     *
     *  @dev The Metadata for the recipient is inferred from the parameters. The decision to do this to minimize the
     *  altering of metadata to the amount that is being transferred.
     *
     *  Requirements:
     *
     *  - `recipients`, `amounts`, and `claimableAmountsOfImport` must have the same length.
     *  - `unlocked` must be less than or equal to this contracts `unlockedPercentage`.
     *  - each value in `claimableAmountsOfImport` must be less than or equal than the amount that would be claimable
     *  given the values in `amounts` and `percentages`.
     *  - `msg.sender` must have approved this contract an amount of `underlyingToken` greater or equal than the sum of
     *  all of the `amounts`.
     *
     *  @param recipients               Array of addresses that will receive the newly minted LVTs.
     *  @param amounts                  Array of amounts of `underlyingToken` to be vested.
     *  @param claimableAmountsOfImport Array of amounts of `underlyingToken` from this transaction that should be
     * considered claimable.
     *  @param unlocked                 The unlocked percentage value at the time of the export of this transaction.
     */
    function importRecipients(
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256[] calldata claimableAmountsOfImport,
        uint256 totalAmount,
        uint256 unlocked
    )
        external
        nonReentrant
    {
        if (unlocked > unlockedPercentage()) revert Errors.UnlockedIsGreaterThanExpected();

        uint256 recipientsLen = recipients.length;
        if (recipientsLen != amounts.length || claimableAmountsOfImport.length != amounts.length) {
            revert Errors.InputArraysMustHaveSameLength();
        }

        uint256 currentBalance = _getBalanceOfThis();
        underlyingToken.safeTransferFrom(msg.sender, address(this), totalAmount);
        uint256 transferredAmount = _getBalanceOfThis() - currentBalance;

        uint256 totalClaimed;

        uint256 _totalAmount;
        for (uint256 i = recipientsLen; i != 0;) {
            unchecked {
                --i;
            }

            uint256 curAmount = Arrays.unsafeMemoryAccess(amounts, i);

            _totalAmount += curAmount;

            address recipient = recipients[i];
            uint256 amount =
                transferredAmount == totalAmount ? curAmount : (curAmount * transferredAmount) / totalAmount;

            uint256 claimableAmountOfImport = Arrays.unsafeMemoryAccess(claimableAmountsOfImport, i);

            uint256 claimedAmount = _claimedAmount(amount, claimableAmountOfImport, unlocked);
            _mint(recipient, amount);

            _metadata[recipient].claimedAmountAfterTransfer =
                _metadata[recipient].claimedAmountAfterTransfer + claimedAmount;

            totalClaimed += claimedAmount;
        }

        if (_totalAmount != totalAmount) revert Errors.InvalidTotalAmount();

        _importedClaimedSupply = _importedClaimedSupply + totalClaimed;
        _startingSupply = _startingSupply + transferredAmount + totalClaimed;
    }

    /// @param recipient The address that will be exported.
    ///
    /// @return The arguments to use in a call `importRecipient` on a different contract to migrate the `recipient`'s
    /// metadata.
    function exportRecipient(address recipient) external view returns (address, uint256, uint256, uint256) {
        return (recipient, balanceOf(recipient), claimableBalanceOf(recipient), unlockedPercentage());
    }

    /// @param recipients Array of addresses that will be exported.
    ///
    /// @return The arguments to use in a call `importRecipients` on a different contract to migrate the `recipients`'
    /// metadata.
    function exportRecipients(address[] calldata recipients)
        external
        view
        returns (address[] calldata, uint256[] memory, uint256[] memory, uint256)
    {
        uint256 recipientsLen = recipients.length;
        uint256[] memory balances = new uint256[](recipientsLen);
        uint256[] memory claimableBalances = new uint256[](recipientsLen);

        for (uint256 i = recipientsLen; i != 0;) {
            unchecked {
                --i;
            }

            address recipient = Arrays.unsafeMemoryAccess(recipients, i);
            balances[i] = balanceOf(recipient);
            claimableBalances[i] = claimableBalanceOf(recipient);
        }

        return (recipients, balances, claimableBalances, unlockedPercentage());
    }

    /// @notice This function will check and update the `_lastReachedMilestone` so the gas usage will be minimal in
    /// calls to `unlockedPercentage`.
    ///
    /// @dev This function is called by claim with a value of `startIndex` equal to the previous value of
    /// `_lastReachedMilestone`, but can be called externally with a more accurate value in case multiple Milestones
    /// have been reached without anyone claiming.
    ///
    /// @param startIndex Index of the Milestone we want the loop to start checking.
    function updateLastReachedMilestone(uint256 startIndex) public {
        if (_milestones[startIndex].timestamp > block.timestamp) return;

        uint256 lastReachedMilestone = _lastReachedMilestone;
        uint256 len = _milestones.length;
        Milestone storage previous = _milestones[startIndex];

        for (uint256 i = startIndex; i < len;) {
            Milestone storage current = _milestones[i];
            if (current.timestamp <= block.timestamp) {
                previous = current;

                unchecked {
                    ++i;
                }

                continue;
            }

            if (i > lastReachedMilestone + 1) {
                unchecked {
                    lastReachedMilestone = i - 1;
                }
                emit MilestoneReached(lastReachedMilestone);
            }
            return;
        }

        if (lastReachedMilestone < len - 1) {
            unchecked {
                lastReachedMilestone = len - 1;
            }
            emit MilestoneReached(lastReachedMilestone);
        }

        if (lastReachedMilestone != _lastReachedMilestone) {
            unchecked {
                _lastReachedMilestone = lastReachedMilestone;
            }
        }
    }

    /// @return The percentage of `underlyingToken` that users could claim.
    function unlockedPercentage() public view returns (uint256) {
        Milestone storage previous = _milestones[_lastReachedMilestone];
        // If the first Milestone is still pending, the contract hasn't started unlocking tokens
        if (previous.timestamp > block.timestamp) return 0;

        uint256 percentage = previous.percentage;
        uint256 milestonesLen = _milestones.length;
        for (uint256 i = _lastReachedMilestone + 1; i < milestonesLen;) {
            Milestone storage current = _milestones[i];
            // If `current` Milestone has expired, `percentage` is at least `current` Milestone's percentage
            if (current.timestamp <= block.timestamp) {
                percentage = current.percentage;
                previous = current;

                unchecked {
                    ++i;
                }

                continue;
            }
            // If `current` Milestone has a `Linear` ramp, `percentage` is between `previous` and `current`
            // Milestone's percentage
            if (current.ramp == Ramp.Linear) {
                percentage += ((block.timestamp - previous.timestamp) * (current.percentage - previous.percentage))
                    / (current.timestamp - previous.timestamp);
            }
            // `percentage` won't change after this
            break;
        }
        return percentage;
    }

    /// @return The amount of `underlyingToken` that were held in this contract and have been claimed.
    function claimedSupply() external view returns (uint256) {
        return _startingSupply - totalSupply() - _importedClaimedSupply;
    }

    /// @return The amount of `underlyingToken` being held in this contract and that can be claimed.
    function claimableSupply() public view returns (uint256) {
        return _claimableAmount(_startingSupply, _startingSupply - totalSupply());
    }

    /// @return The amount of `underlyingToken` being held in this contract that can't be claimed yet.
    function lockedSupply() external view returns (uint256) {
        return totalSupply() - claimableSupply();
    }

    /// @param account The address whose tokens are being queried.
    /// @return The amount of `underlyingToken` that were held in this contract and this `account` already claimed.
    function claimedBalanceOf(address account) external view returns (uint256) {
        return _metadata[account].claimedBalance;
    }

    /// @param account The address whose tokens are being queried.
    /// @return The amount of `underlyingToken` that this `account` owns and can claim.
    function claimableBalanceOf(address account) public view returns (uint256) {
        uint256 claimedAmountAfterTransfer = _metadata[account].claimedAmountAfterTransfer;
        return _claimableAmount(claimedAmountAfterTransfer + balanceOf(account), claimedAmountAfterTransfer);
    }

    /// @param account The address whose tokens are being queried.
    /// @return The amount of `underlyingToken` that this `account` owns but can't claim yet.
    function lockedBalanceOf(address account) external view returns (uint256) {
        return balanceOf(account) - claimableBalanceOf(account);
    }

    /// @notice Claims available unlocked `underlyingToken` for the caller.
    /// @dev Transfers claimable amount to `msg.sender` and requires a claim fee (`msg.value`).
    /// Reverts if there's no claimable amount. Protected against re-entrancy.
    function claim() external payable nonReentrant {
        address account = msg.sender;
        Metadata storage accountMetadata = _metadata[account];

        updateLastReachedMilestone(_lastReachedMilestone);

        uint256 claimableAmount = _claimableAmount(
            accountMetadata.claimedAmountAfterTransfer + balanceOf(account), accountMetadata.claimedAmountAfterTransfer
        );

        if (claimableAmount == 0) {
            revert Errors.NoClaimableAmount();
        }

        _burn(account, claimableAmount);

        accountMetadata.claimedAmountAfterTransfer = accountMetadata.claimedAmountAfterTransfer + claimableAmount;
        accountMetadata.claimedBalance = accountMetadata.claimedBalance + claimableAmount;

        emit Claim(account, claimableAmount);
        underlyingToken.safeTransfer(account, claimableAmount);

        _processClaimFee();
    }

    /// @notice Allows an investor to burn their vested and underlying tokens.
    /// @dev First attempts to burn the underlying tokens. If unsuccessful, these are sent to address '0xdead'. This
    /// operation is followed by the burning of the equivalent vested tokens.
    /// Assumes the underlying token has a burn function with the selector '0x42966c68'.
    /// @param amount Amount of tokens to be burnt. The investor's locked balance must be greater or equal than this
    /// amount.
    function burn(uint256 amount) public payable {
        uint256 currentBalance = _getBalanceOfThis();

        address account = msg.sender;
        address underlyingAddress = address(underlyingToken);

        emit Burn(account, amount);

        // Selector for "burn(uint256)"
        bytes4 burnSelector = 0x42966c68;

        // Encoding calldata for burn function
        (bool burnSuccess,) = underlyingAddress.call(abi.encodeWithSelector(burnSelector, amount));
        if (!burnSuccess) {
            underlyingToken.safeTransfer(address(0xdead), amount);
        }

        uint256 transferredAmount = currentBalance - _getBalanceOfThis();

        _startingSupply = _startingSupply - transferredAmount;

        _burn(account, amount);
    }

    /// @notice Calculates and transfers the fee before executing a normal ERC20 transfer.
    ///
    /// @dev This method also updates the metadata in `msg.sender`, `to`, and `feeCollector`.
    ///
    /// @param to     Address of recipient.
    /// @param amount Amount of tokens.
    function transfer(address to, uint256 amount) public override returns (bool) {
        _updateMetadataAndTransfer(msg.sender, to, amount, true);
        return true;
    }

    /// @notice Calculates and transfers the fee before executing a normal ERC20 transferFrom.
    ///
    /// @dev This method also updates the metadata in `from`, `to`, and `feeCollector`.
    ///
    /// @param from   Address of sender.
    /// @param to     Address of recipient.
    /// @param amount Amount of tokens.
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _updateMetadataAndTransfer(from, to, amount, false);
        return true;
    }

    /// @notice Exposes the whole array of `_milestones`.
    function milestones() external view returns (Milestone[] memory) {
        return _milestones;
    }

    /// @notice Exposes the inner metadata for a given account.
    /// @param account The address whose tokens are being queried.
    function metadataOf(address account) external view returns (Metadata memory metadata) {
        metadata = _metadata[account];
    }

    /// @notice Returns the current transfer fee associated to this `VestingToken`.
    function transferFeeData() external view returns (address, uint64) {
        return manager.transferFeeData(address(underlyingToken));
    }

    /// @notice Returns the current claim fee associated to this `VestingToken`.
    function claimFeeData() external view returns (address, uint64) {
        return manager.claimFeeData(address(underlyingToken));
    }

    /**
     * @dev This function updates the metadata on the `sender`, the `receiver`, and the `feeCollector` if there's any
     * fee involved. The changes on the metadata are on the value `claimedAmountAfterTransfer` which is used to
     * calculate `_claimableAmount`.
     *
     * @dev The math behind these changes can be explained by the following logic:
     *
     *     1) claimableAmount = (unlockedPercentage * startingAmount) / ONE - claimedAmount
     *
     * When there's a transfer of an amount, we transfer both locked and unlocked tokens so the
     * `claimableAmountAfterTransfer` will look like:
     *
     *     2) claimableAmountAfterTransfer = claimableAmount ± claimableAmountOfTransfer
     *
     * Notice the ± symbol is because the `sender`'s `claimableAmount` is reduced while the `receiver`'s
     * `claimableAmount` is increased.
     *
     *     3) claimableAmountOfTransfer = claimableAmountOfSender * amountOfTransfer / balanceOfSender
     *
     * We can expand 3) into:
     *
     *     4) claimableAmountOfTransfer =
     *            (unlockedPercentage * ((startingAmountOfSender * amountOfTransfer) / balanceOfSender)) / ONE) -
     *            ((claimedAmountOfSender * amountOfTransfer) / balanceOfSender)
     *
     * Notice how the structure of the equation is the same as 1) and 2 new variables can be created to calculate
     * `claimableAmountOfTransfer`
     *
     *     a) startingAmountOfTransfer = (startingAmountOfSender * amountOfTransfer) / balanceOfSender
     *     b) claimedAmountOfTransfer = (claimedAmountOfSender * amountOfTransfer) / balanceOfSender
     *
     * Replacing `claimableAmountOfTransfer` in equation 2) and expanding it, we get:
     *
     *     5) claimableAmountAfterTransfer =
     *            ((unlockedPercentage * startingAmount) / ONE - claimedAmount) ±
     *            ((unlockedPercentage * startingAmountOfTransfer) / ONE - claimedAmountOfTransfer)
     *
     * We can group similar variables like this:
     *
     *     6) claimableAmountAfterTransfer =
     *            (unlockedPercentage * (startingAmount - startingAmountOfTransfer)) / ONE -
     *            (claimedAmount - claimedAmountOfTransfer)
     *
     * This shows that the new values to calculate `claimableAmountAfterTransfer` if we want to continue using the
     * equation 1) are:
     *
     *     c) startingAmountAfterTransfer =
     *            startingAmount ±
     *            (startingAmountOfSender * amountOfTransfer) / balanceOfSender
     *     d) claimedAmountAfterTransfer =
     *            claimedAmount ±
     *            (claimedAmountOfSender * amountOfTransfer) / balanceOfSender
     *
     * Since these values depend linearly on the value of `amountOfTransfer`, and the fee is a fraction of the amount,
     * we can just factor in the `transferFeePercentage` to get the values for the transfer to the `feeCollector`.
     *
     *     e) startingAmountOfFee = (startingAmountOfTransfer * transferFeePercentage) / ONE;
     *     f) claimedAmountOfFee = (claimedAmountOfTransfer * transferFeePercentage) / ONE;
     *
     * If we look at equation 1) and set `unlockedPercentage` to ONE, then `claimableAmount` must equal to the
     * `balance`. Therefore the relation between `startingAmount`, `claimedAmount`, and `balance` should be:
     *
     *     g) startingAmount = claimedAmount + balance
     *
     * Since we want to minimize independent rounding in all of the `startingAmount`s, and `claimedAmount`s we will
     * calculate the `claimedAmount` using multiplication and division as shown in b) and f), and the `startingAmount`
     * can be derived using a simple subtraction.
     * With this we ensure that if there's a rounding down in the divisions, we won't be leaving any token locked.
     *
     * @param from       Address of sender.
     * @param to         Address of recipient.
     * @param amount     Amount of tokens.
     * @param isTransfer If a fee is charged, this will let the function know whether to use `transfer` or
     *                   `transferFrom` to collect the fee.
     */
    function _updateMetadataAndTransfer(address from, address to, uint256 amount, bool isTransfer) internal {
        Metadata storage accountMetadata = _metadata[from];

        // Calculate `claimedAmountOfTransfer` as described on equation b)
        // uint256 can handle 78 digits well. Normally token transactions have 18 decimals that gives us 43 digits of
        // wiggle room in the multiplication `(accountMetadata.claimedAmountAfterTransfer * amount)` without
        // overflowing.
        uint256 claimedAmountOfTransfer = (accountMetadata.claimedAmountAfterTransfer * amount) / balanceOf(from);

        // Modify `claimedAmountAfterTransfer` of the sender following equation d)
        // Notice in this case we are reducing the value
        accountMetadata.claimedAmountAfterTransfer =
            accountMetadata.claimedAmountAfterTransfer - claimedAmountOfTransfer;

        if (to != from) {
            (address feeCollector, uint64 transferFeePercentage) = manager.transferFeeData(address(underlyingToken));

            if (transferFeePercentage != 0) {
                // The values of `fee` and `claimedAmountOfFee` are calculated using the `transferFeePercentage` shown
                // in equation f)
                uint256 fee = (amount * transferFeePercentage);
                unchecked {
                    fee /= ONE;
                }

                uint256 claimedAmountOfFee = (claimedAmountOfTransfer * transferFeePercentage);
                unchecked {
                    claimedAmountOfFee /= ONE;
                }

                // The values for the receiver need to be updated accordingly
                amount -= fee;
                claimedAmountOfTransfer -= claimedAmountOfFee;

                // Modify `claimedAmountAfterTransfer` of the feeCollector following equation d)
                // Notice in this case we are increasing the value
                _metadata[feeCollector].claimedAmountAfterTransfer =
                    _metadata[feeCollector].claimedAmountAfterTransfer + claimedAmountOfFee;

                if (isTransfer) {
                    super.transfer(feeCollector, fee);
                } else {
                    super.transferFrom(from, feeCollector, fee);
                }
            }
        }

        // Modify `claimedAmountAfterTransfer` of the receiver following equation d)
        // Notice in this case we are increasing the value
        // The next line triggers the linter because it's not aware that super.transfer does not call an external
        // contract, nor does trigger a fallback function.
        // solhint-disable-next-line reentrancy
        _metadata[to].claimedAmountAfterTransfer = _metadata[to].claimedAmountAfterTransfer + claimedAmountOfTransfer;

        if (isTransfer) {
            super.transfer(to, amount);
        } else {
            super.transferFrom(from, to, amount);
        }
    }

    /// @notice Validates and initializes the VestingToken milestones.
    /// @dev It will perform validations on the calldata:
    /// @dev - Milestones have percentages and timestamps sorted in ascending order.
    /// @dev - No more than 2 consecutive Milestones can have the same percentage.
    /// @dev - 2 Milestones may have the same percentage as long as they are followed by a Milestone with a
    /// `Ramp.Linear`.
    /// @dev - Only the last Milestone should have 100% percentage.
    function _setupMilestones(Milestone[] calldata milestonesArray) internal {
        if (milestonesArray.length == 0) revert Errors.MinMilestonesNotReached();
        if (milestonesArray.length > 826) revert Errors.MaxAllowedMilestonesHit();

        Milestone calldata current = milestonesArray[0];
        bool twoInARow;
        uint256 milestonesLen = milestonesArray.length;
        for (uint256 i; i < milestonesLen;) {
            if (i != 0) {
                Milestone calldata previous = current;
                current = milestonesArray[i];

                if (previous.timestamp >= current.timestamp) revert Errors.MilestoneTimestampsNotSorted();
                if (previous.percentage > current.percentage) revert Errors.MilestonePercentagesNotSorted();

                if (twoInARow) {
                    if (previous.percentage == current.percentage) revert Errors.MoreThanTwoEqualPercentages();
                    if (current.ramp != Ramp.Linear) revert Errors.EqualPercentagesOnlyAllowedBeforeLinear();
                }

                twoInARow = previous.percentage == current.percentage;
            }

            if (i == milestonesLen - 1) {
                if (current.percentage != ONE) revert Errors.LastPercentageMustBe100();
            } else {
                if (current.percentage == ONE) revert Errors.OnlyLastPercentageCanBe100();
            }

            _milestones.push(current);

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Perform a staticcall to attempt to fetch `underlyingToken`'s decimals. In case of an error, we default to
    /// 18.
    function _tryFetchDecimals() internal view returns (uint8) {
        (bool success, bytes memory encodedDecimals) =
            address(underlyingToken).staticcall(abi.encodeWithSelector(ERC20Upgradeable.decimals.selector));

        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals;
            assembly {
                // Since `encodedDecimals` is a dynamic array, its first 32 bytes store the data's length
                returnedDecimals := mload(add(encodedDecimals, 32))
            }

            // type(uint8).max => 255
            if (returnedDecimals <= 255) {
                return uint8(returnedDecimals);
            }
        }

        return 18;
    }

    /// @dev Perform a staticcall to attempt to fetch `underlyingToken`'s balance of this contract. In case of an error,
    /// reverts with custom `UnsuccessfulFetchOfTokenBalance` error.
    function _getBalanceOfThis() internal view returns (uint256 returnedBalance) {
        (bool success, bytes memory encodedBalance) = address(underlyingToken).staticcall(
            abi.encodeWithSelector(ERC20Upgradeable.balanceOf.selector, address(this))
        );

        if (success && encodedBalance.length >= 32) {
            assembly {
                // Since `encodedBalance` is a dynamic array, its first 32 bytes store the data's length
                returnedBalance := mload(add(encodedBalance, 32))
            }
            return returnedBalance;
        }

        revert Errors.UnsuccessfulFetchOfTokenBalance();
    }

    /// @notice This method is used to infer the value of claimed amounts.
    ///
    /// @dev If the unlocked percentage has already reached 100%, there's no way to infer the claimed amount.
    ///
    /// @param amount                  Amount of `underlyingToken` in the transaction.
    /// @param claimableAmountOfImport Amount of `underlyingToken` from this transaction that should be considered
    /// claimable.
    /// @param unlocked                The unlocked percentage value at the time of the export of this transaction.
    ///
    /// @return Amount of `underlyingToken` that has been claimed based on the arguments given.
    function _claimedAmount(
        uint256 amount,
        uint256 claimableAmountOfImport,
        uint256 unlocked
    )
        internal
        pure
        returns (uint256)
    {
        if (unlocked == ONE) return 0;

        uint256 a = unlocked * amount;
        uint256 b = ONE * claimableAmountOfImport;
        // If `a - b` underflows, we display a better error message.
        if (b > a) revert Errors.ClaimableAmountOfImportIsGreaterThanExpected();
        return (a - b) / (ONE - unlocked);
    }

    /// @param startingAmount Amount of `underlyingToken` originally held.
    /// @param claimedAmount  Amount of `underlyingToken` already claimed.
    ///
    /// @return Amount of `underlyingToken` that can be claimed based on the milestones reached and initial amounts
    /// given.
    function _claimableAmount(uint256 startingAmount, uint256 claimedAmount) internal view returns (uint256) {
        uint256 unlocked = (unlockedPercentage() * startingAmount);
        unchecked {
            unlocked /= ONE;
        }

        return unlocked < claimedAmount ? 0 : unlocked - claimedAmount;
    }

    /// @notice Processes the claim fee for a transaction.
    /// @dev This function retrieves the claim fee data from the manager contract and, if the claim fee is greater than
    /// zero, sends the `msg.value` to the fee collector address. Reverts if the transferred value is less than the
    /// required claim fee or if the transfer fails.
    function _processClaimFee() private {
        (address feeCollector, uint64 claimFeeValue) = manager.claimFeeData(address(underlyingToken));

        if (claimFeeValue != 0) {
            if (msg.value != claimFeeValue) revert Errors.IncorrectClaimFee();

            bytes4 unsuccessfulClaimFeeTransfer = Errors.UnsuccessfulClaimFeeTransfer.selector;

            assembly {
                let ptr := mload(0x40)
                let sendSuccess := call(gas(), feeCollector, callvalue(), 0x00, 0x00, 0x00, 0x00)
                if iszero(sendSuccess) {
                    mstore(ptr, unsuccessfulClaimFeeTransfer)
                    revert(ptr, 0x04)
                }
            }
        }
    }
}

// SPDX-License-Identifier: None
// Unvest Contracts (last updated v3.0.0) (interfaces/IFeeManager.sol)
pragma solidity ^0.8.24;

/// @title IFeeManager
/// @dev Interface that describes the struct and accessor function for the data related to the collection of fees.
interface IFeeManager {
    /// @dev The `FeeData` struct is used to store fee configurations such as the collection address and fee amounts for
    /// various transaction types in the contract.
    struct FeeData {
        /// @notice The address designated to collect fees.
        /// @dev This address is responsible for receiving fees generated from various sources.
        address feeCollector;
        /// @notice The fixed fee amount required to be sent as value with each `createVestingToken` operation.
        /// @dev `creationFee` is denominated in the smallest unit of the token. It must be sent as the transaction
        /// value during the execution of the payable `createVestingToken` function.
        uint64 creationFee;
        /// @notice The transfer fee expressed in ether, where 0.01 ether corresponds to a 1% fee.
        /// @dev `transferFeePercentage` is not in basis points but in ether units, with each ether unit representing a
        /// percentage of the transaction value to be collected as a fee. This structure allows for flexible and easily
        /// understandable fee calculations for `transfer` and `transferFrom` operations.
        uint64 transferFeePercentage;
        /// @notice The fixed fee amount required to be sent as value with each `claim` operation.
        /// @dev `claimFee` is denominated in the smallest unit of the token. It must be sent as the transaction value
        /// during the execution of the payable `claim` function.
        uint64 claimFee;
    }

    /// @dev Stores global fee data upcoming change and timestamp for that change.
    struct UpcomingFeeData {
        /// @notice The new fee value in wei to be applied at `valueChangeAt`.
        uint64 nextValue;
        /// @notice Timestamp at which a new fee value becomes effective.
        uint64 valueChangeAt;
    }

    /// @dev Stores custom fee data, including its current state, upcoming changes, and the timestamps for those
    /// changes.
    struct CustomFeeData {
        /// @notice Indicates if the custom fee is currently enabled.
        bool isEnabled;
        /// @notice The current fee value in wei.
        uint64 value;
        /// @notice The new fee value in wei to be applied at `valueChangeAt`.
        uint64 nextValue;
        /// @notice Timestamp at which a new fee value becomes effective.
        uint64 valueChangeAt;
        /// @notice Indicates the future state of `isEnabled` after `statusChangeAt`.
        bool nextEnableState;
        /// @notice Timestamp at which the change to `isEnabled` becomes effective.
        uint64 statusChangeAt;
    }

    /// @notice Exposes the creation fee for new `VestingToken`s deployments.
    /// @param underlyingToken Address of the `underlyingToken`.
    /// @dev Enabled custom fees overrides the global creation fee.
    function creationFeeData(address underlyingToken)
        external
        view
        returns (address feeCollector, uint64 creationFeeValue);

    /// @notice Exposes the transfer fee for `VestingToken`s to consume.
    /// @param underlyingToken Address of the `underlyingToken`.
    /// @dev Enabled custom fees overrides the global transfer fee.
    function transferFeeData(address underlyingToken)
        external
        view
        returns (address feeCollector, uint64 transferFeePercentage);

    /// @notice Exposes the claim fee for `VestingToken`s to consume.
    /// @param underlyingToken Address of the `underlyingToken`.
    /// @dev Enabled custom fees overrides the global claim fee.
    function claimFeeData(address underlyingToken) external view returns (address feeCollector, uint64 claimFeeValue);
}

// SPDX-License-Identifier: None
// Unvest Contracts (last updated v3.0.0) (interfaces/IVestingToken.sol)
pragma solidity ^0.8.24;

/// @title IVestingToken
/// @dev Interface that describes the Milestone struct and initialize function so the `VestingTokenFactory` knows how to
/// initialize the `VestingToken`.
interface IVestingToken {
    /// @dev Ramps describes how the periods between release tokens.
    ///     - Cliff releases nothing until the end of the period.
    ///     - Linear releases tokens every second according to a linear slope.
    ///
    /// (0) Cliff             (1) Linear
    ///  |                     |
    ///  |        _____        |        _____
    ///  |       |             |       /
    ///  |       |             |      /
    ///  |_______|_____        |_____/_______
    ///      T0   T1               T0   T1
    ///
    enum Ramp {
        Cliff,
        Linear
    }

    /// @dev `timestamp` represents a moment in time when this Milestone is considered expired.
    /// @dev `ramp` defines the behaviour of the release of tokens in period between the previous Milestone and the
    /// current one.
    /// @dev `percentage` is the percentage of tokens that should be released once this Milestone has expired.
    struct Milestone {
        uint64 timestamp;
        Ramp ramp;
        uint64 percentage;
    }

    /// @notice Initializes the contract by setting up the ERC20 variables, the `underlyingToken`, and the
    /// `milestonesArray` information.
    ///
    /// @param name                   The token collection name.
    /// @param symbol                 The token collection symbol.
    /// @param underlyingTokenAddress The ERC20 token that will be held by this contract.
    /// @param milestonesArray        Array of all Milestones for this Contract's lifetime.
    function initialize(
        string memory name,
        string memory symbol,
        address underlyingTokenAddress,
        Milestone[] calldata milestonesArray
    )
        external;
}

// SPDX-License-Identifier: None
// Unvest Contracts (last updated v3.0.0) (libraries/Arrays.sol)
pragma solidity ^0.8.24;

/**
 * @dev Collection of functions related to array types.
 * @dev This is an extract from OpenZeppelin Arrays util contract.
 */
library Arrays {
    struct AddressSlot {
        address value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /// @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
    function unsafeMemoryAccess(address[] memory arr, uint256 pos) internal pure returns (address res) {
        assembly {
            res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
        }
    }

    /// @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
    function unsafeMemoryAccess(bytes32[] memory arr, uint256 pos) internal pure returns (bytes32 res) {
        assembly {
            res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
        }
    }

    /// @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
    function unsafeMemoryAccess(uint256[] memory arr, uint256 pos) internal pure returns (uint256 res) {
        assembly {
            res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
        }
    }
}

// SPDX-License-Identifier: None
// Unvest Contracts (last updated v3.0.0) (libraries/Errors.sol)
pragma solidity ^0.8.24;

/// @title Errors Library
/// @notice Provides custom errors for VestingTokenFactory and VestingToken contracts.
library Errors {
    /*//////////////////////////////////////////////////////
                      VestingTokenFactory
    //////////////////////////////////////////////////////*/

    /// @notice Error to indicate that an address cannot be the zero address.
    error AddressCanNotBeZero();

    /// @notice Error to indicate that deployment of a contract failed.
    error FailedToDeploy();

    /// @notice Error to indicate that a fee is out of the accepted range.
    error FeeOutOfRange();

    /// @notice Error to indicate that the creation fee is insufficient.
    error InsufficientCreationFee();

    /// @notice Error to indicate an unsuccessful transfer of the creation fee.
    error UnsuccessfulCreationFeeTransfer();

    /*//////////////////////////////////////////////////////
                      VestingToken
    //////////////////////////////////////////////////////*/

    /// @notice Error to indicate that the minimum number of milestones has not been reached.
    error MinMilestonesNotReached();

    /// @notice Error to indicate that the maximum number of milestones has been exceeded.
    error MaxAllowedMilestonesHit();

    /// @notice Error to indicate that the claimable amount of an import is greater than expected.
    error ClaimableAmountOfImportIsGreaterThanExpected();

    /// @notice Error to indicate that equal percentages are only allowed before setting up linear milestones.
    error EqualPercentagesOnlyAllowedBeforeLinear();

    /// @notice Error to indicate that the sum of all individual amounts is not equal to the `totalAmount`.
    error InvalidTotalAmount();

    /// @notice Error to indicate that input arrays must have the same length.
    error InputArraysMustHaveSameLength();

    /// @notice Error to indicate that the last percentage in a milestone must be 100.
    error LastPercentageMustBe100();

    /// @notice Error to indicate that milestone percentages are not sorted in ascending order.
    error MilestonePercentagesNotSorted();

    /// @notice Error to indicate that milestone timestamps are not sorted in ascending chronological order.
    error MilestoneTimestampsNotSorted();

    /// @notice Error to indicate that there are more than two equal percentages, which is not allowed.
    error MoreThanTwoEqualPercentages();

    /// @notice Error to indicate that only the last percentage in a series can be 100.
    error OnlyLastPercentageCanBe100();

    /// @notice Error to indicate that the amount unlocked is greater than expected.
    error UnlockedIsGreaterThanExpected();

    /// @notice Error to indicate an unsuccessful fetch of token balance.
    error UnsuccessfulFetchOfTokenBalance();

    /// @notice Error to indicate that the claim fee provided does not match the expected claim fee.
    error IncorrectClaimFee();

    /// @notice Error to indicate an unsuccessful transfer of the claim fee.
    error UnsuccessfulClaimFeeTransfer();

    /// @notice Error to indicate that there is no balance available to claim.
    error NoClaimableAmount();
}