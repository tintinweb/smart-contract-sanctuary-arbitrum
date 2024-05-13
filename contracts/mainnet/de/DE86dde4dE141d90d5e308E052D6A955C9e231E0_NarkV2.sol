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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {IERC20Errors} from "../../interfaces/draft-IERC6093.sol";

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
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
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
        return _allowances[owner][spender];
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
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
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
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IComputingPool {

    function depositComp(address userAddr, uint256 power) external;

    function recordsDailyLp(uint256 amount) external;

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface INarkCoin {

    function burn(uint256 amount) external;

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface INarkV2 {

    struct User {
        uint8 state;
        uint8 vipLevel;
        uint256 userDeposit;
    }

    struct VIPInfo {
        uint8 level;
        uint8 nextLevel;
        uint8 award;
        uint256 directPushNum;
        uint256 quantity;
        uint256 subQuantity;
    }

    function computedLP(uint256 liquidity) external view returns (uint256 platformAmount, uint256 transitAmount);

    function computedLPToU(uint256 liquidity) external view returns (uint256 platformAmount, uint256 transitAmount, uint256 depositAmount);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface IRelation {

    function inviter(address user) external view returns (address);

    function directPush(address user) external view returns (address[] memory);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.2;

interface ISushiSwapRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.2;

import "./ISushiSwapRouter01.sol";

interface ISushiSwapRouter02 is ISushiSwapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity ^0.8.19;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

library Constants {

    uint256 internal constant TENTHOUSAND = 10000;

    uint256 internal constant THOUSAND = 1000;

    uint256 internal constant DENOMINATOR = 100;

    uint256 internal constant HUNDRED = 100;

    uint256 internal constant HALF = 50;

    uint8 internal constant KEEP_VAULE = 1; 

    uint8 internal constant ONE = 1; 

    uint8 internal constant TWO = 2; 

    uint8 internal constant THREE = 3; 

    uint8 internal constant FIVE = 5; 

    uint8 internal constant SIX = 6; 

    uint8 internal constant TEN = 10;

    uint8 internal constant ELEVEN = 11;

    uint8 internal constant TWENTY = 20;

    uint8 internal constant THIRTY = 30;

    uint8 internal constant FLOAT_TEN = 90;

    uint8 internal constant FLOAT_FIVE = 95;

    uint8 internal constant COMMISSION_RECOMMEND = 2;
    uint8 internal constant COMMISSION_SEE = 3;
    uint8 internal constant COMMISSION_COM_POOL = 4;
    uint8 internal constant COMMISSION_LEVEL_DIFF = 5;
    uint8 internal constant COMMISSION_FOMO_POOL = 6;
    uint8 internal constant COMMISSION_NODE_POOL = 7;
    uint8 internal constant COMMISSION_NARK_POOL = 8;

    uint8 internal constant STATE_NORMAL = 0;
    uint8 internal constant STATE_TICKETS = 1;
    uint8 internal constant STATE_UPGRADE = 2;

    uint256 internal constant UPGRADE_PUSH_REWARD = 1500;
    uint256 internal constant UPGRADE_LEVEL_DIFF_REWARD = 2000;
    uint256 internal constant UPGRADE_VAULT_REWARD = 500;
    uint256 internal constant UPGRADE_NODE_POOL_LP = 1000;
    uint256 internal constant UPGRADE_COMP_POOL_LP = 5000;

    uint256 internal constant SUB_PUSH_REWARD = 1000;
    uint256 internal constant SUB_VAULT_REWARD = 500;
    uint256 internal constant SUB_USER = 8000;

    uint256 internal constant SELL_USER = 9500;
    uint256 internal constant SELL_DAO_REWARD = 300;
    uint256 internal constant SELL_NODE_POOL_LP = 200;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

    function mulDiv2(
        uint256 a,
        uint256 denominator,
        uint256 b
    ) internal pure returns (uint256 result) {
        return mulDiv(a, b, denominator);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import './BytesLib.sol';

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Returns the number of pools in the path
    /// @param path The encoded swap path
    /// @return The number of pools in the path
    function numPools(bytes memory path) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with BEP20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import './SushiSwapV2Adapter.sol';
import './interface/IComputingPool.sol';
import './interface/INarkV2.sol';
import './interface/IRelation.sol';
import './interface/INarkCoin.sol';
import './lib/SafeMath.sol';

contract NarkV2 is OwnableUpgradeable, SushiSwapV2Adapter, INarkV2 {

    using SafeMath for uint256;

    mapping(uint8 => VIPInfo) public vipInfo;
    mapping(address => User) public users;

    mapping(address => address[]) public upgradeDPush;
    mapping(address => uint) public upgradeDPushCount;

    uint8 public depositDecimal;
    uint8 public defiLPDecimal;
    uint8 public highestVIP;

    address public topUser;
    address public operator;
    address public depositCoin;
    address public depositCoinV1;
    address public transitCoin;
    address public platformCoin;
    address public nodePool;
    address public computingPool;
    address public vault;
    address public daoVault;

    uint256 public sellLpFee;
    uint256 public boatTicketsFee;
    uint256 public upgradeFee;

    IRelation public relation;

    bool public pausableV1;
    bool public pausableV2;

    event Invite(address inviter, address invitees);
    event Upgrade(address triggerAddress, uint256 useAmount, address useCoin, uint8 upgradeLevel);
    
    event LpBuy(address triggerAddress, uint256 useAmount, uint256 getAmount, address useCoin, address getCoin);
    event LpSell(
        address triggerAddress,
        uint256 useAmount,
        uint256 getAmount,
        uint256 feeAmount,
        address useCoin,
        address getCoin
    );

    event VipUpgrade(address triggerAddress, address upgradeAddress, uint8 vipLevel);

    event Commission(
        address triggerAddress,
        address awardAddress,
        address coinAddress,
        uint256 coinAmount,
        uint8 coinDecimal,
        uint8 fromType
    );

    function initialize(
        address _depositCoinV1,
        address _depositCoin,
        address _weth,
        address _platformCoin,
        address _transitCoin,
        address _defiRouter,
        address _defiLP,
        address _relation
    ) external initializer {
        __Ownable_init(msg.sender);
        pausableV1 = true;
        pausableV2 = true;
        depositCoin = _depositCoin;
        depositCoin = _depositCoinV1;
        weth = _weth;
        platformCoin = _platformCoin;
        transitCoin = _transitCoin;
        defiLP = _defiLP;
        defiRouter = _defiRouter;
        operator = msg.sender;
        liquiditySlippage = Constants.FLOAT_FIVE;
        swapSlippage = Constants.FLOAT_FIVE;
        relation = IRelation(_relation);
        depositDecimal = ERC20(_depositCoin).decimals();
        defiLPDecimal = ERC20(_defiLP).decimals();
    }

    modifier onlyOperatorOrOwner() {
        require(msg.sender == operator || msg.sender == owner(), 'narkV2: only operator or owner');
        _;
    }

    modifier checkInviter() {
        require(relation.inviter(msg.sender) != address(0), 'narkV2: must have recommender');
        _;
    }

    modifier checkPausableV2() {
        require(!pausableV2, "narkV2: v2 pausable");
        _;
    }

    function setOperate(address _operate) external onlyOwner {
        operator = _operate;
    }

    function setComputingPool(address _computingPool) external onlyOperatorOrOwner {
        computingPool = _computingPool;
    }

    function setNodePool(address _nodePool) external onlyOperatorOrOwner {
        nodePool = _nodePool;
    }

    function setSellLpFee(uint256 _fee) external onlyOperatorOrOwner {
        sellLpFee = _fee;
    }

    function setVault(address _vault) external onlyOperatorOrOwner {
        vault = _vault;
    }

    function setDaoVault(address _daoVault) external onlyOperatorOrOwner {
        daoVault = _daoVault;
    }

    function setLiquiditySlippage(uint256 _num) external onlyOperatorOrOwner {
        liquiditySlippage = _num;
    }

    function setSwapSlippage(uint256 _num) external onlyOperatorOrOwner {
        swapSlippage = _num;
    }

    function setTicketsFee(uint _boatTicketsFee, uint _upgradeFee) external onlyOperatorOrOwner {
        boatTicketsFee = _boatTicketsFee;
        upgradeFee = _upgradeFee;
    }

    function setPausableV1(bool _pausableV1) external onlyOperatorOrOwner {
        pausableV1 = _pausableV1;
    }

    function setPausableV2(bool _pausableV2) external onlyOperatorOrOwner {
        pausableV2 = _pausableV2;
    }

    function addVIPInfo(uint8 level, VIPInfo memory info) external onlyOperatorOrOwner {
        vipInfo[level] = info;
        if (level > highestVIP) {
            highestVIP = level;
        }
    }

    function boatTicketsV1() external checkInviter {

        require(!pausableV1, "narkV1: v1 pausable");

        User storage user = users[msg.sender];
        require(user.state == Constants.STATE_NORMAL, "narkV1: tickets purchased");

        TransferHelper.safeTransferFrom(depositCoinV1, msg.sender, address(this), boatTicketsFee);
        
        user.state = Constants.STATE_TICKETS;
        emit Upgrade(msg.sender, boatTicketsFee, depositCoin, Constants.STATE_TICKETS);
    }

    function upgradeTicketsV1() external checkInviter {

        require(!pausableV1, "narkV1: v1 pausable");

        User storage user = users[msg.sender];
        require(user.state == Constants.STATE_TICKETS, "narkV1: no ticket purchased or upgraded");

        TransferHelper.safeTransferFrom(depositCoinV1, msg.sender, address(this), upgradeFee);

        user.state = Constants.STATE_UPGRADE;
        address parents = relation.inviter(msg.sender);
        upgradeDPush[parents].push(msg.sender);
        
        _upgradeVIPLevel(msg.sender);
        _upgradeVIPAndRewardV1(msg.sender);

        emit Upgrade(msg.sender, upgradeFee, depositCoin, Constants.STATE_UPGRADE);


    }

    function boatTickets() external checkInviter checkPausableV2 {
        User storage user = users[msg.sender];
        require(user.state == Constants.STATE_NORMAL, "narkV2: tickets purchased");

        TransferHelper.safeTransferFrom(depositCoin, msg.sender, vault, boatTicketsFee);
        
        user.state = Constants.STATE_TICKETS;
        emit Upgrade(msg.sender, boatTicketsFee, depositCoin, Constants.STATE_TICKETS);
    }

    function upgradeTickets() external checkInviter checkPausableV2 {
        User storage user = users[msg.sender];
        require(user.state == Constants.STATE_TICKETS, "narkV2: no ticket purchased or upgraded");

        TransferHelper.safeTransferFrom(depositCoin, msg.sender, address(this), upgradeFee);

        user.state = Constants.STATE_UPGRADE;
        address parents = relation.inviter(msg.sender);
        upgradeDPush[parents].push(msg.sender);
        _upgradeVIPLevel(msg.sender);

        uint256 inviteReward = FullMath.mulDiv(upgradeFee, Constants.UPGRADE_PUSH_REWARD, Constants.TENTHOUSAND);
        if (users[parents].state == Constants.STATE_UPGRADE) {
            TransferHelper.safeTransfer(depositCoin, parents, inviteReward);
            emit Commission(msg.sender, msg.sender, depositCoin, inviteReward, depositDecimal, Constants.COMMISSION_RECOMMEND);
        } else {
            TransferHelper.safeTransfer(depositCoin, vault, inviteReward); 
        } 

        uint256 daoVaultRewad = FullMath.mulDiv(upgradeFee, Constants.UPGRADE_VAULT_REWARD, Constants.TENTHOUSAND);
        TransferHelper.safeTransfer(depositCoin, daoVault, daoVaultRewad); 

        uint256 levelDiffReward = FullMath.mulDiv(upgradeFee, Constants.UPGRADE_LEVEL_DIFF_REWARD, Constants.TENTHOUSAND);
        uint256 awardRemaining = _upgradeVIPAndReward(msg.sender, 0, users[msg.sender].vipLevel, levelDiffReward, levelDiffReward);
        if (awardRemaining > 0) {
            TransferHelper.safeTransfer(defiLP, vault, awardRemaining);
        }

        uint256 rewardPool = upgradeFee.sub(daoVaultRewad).sub(inviteReward).sub(levelDiffReward);

        uint256[] memory amountsPair1 = _wethSwap(depositCoin, transitCoin, rewardPool);

        uint256 useTransitCoin = FullMath.mulDiv(amountsPair1[Constants.TWO], Constants.HALF, Constants.DENOMINATOR);
        uint256[] memory amountsPair2 = _swap(transitCoin, platformCoin, useTransitCoin);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = _addLiquidity(
            platformCoin,
            transitCoin,
            amountsPair2[Constants.ONE],
            amountsPair1[Constants.TWO].sub(useTransitCoin),
            address(this)
        );

        _refund(amountsPair2[Constants.ONE].sub(amountA), amountsPair1[Constants.TWO].sub(useTransitCoin).sub(amountB), msg.sender);

        uint256 nodePoolReward = FullMath.mulDiv(liquidity, Constants.UPGRADE_NODE_POOL_LP, Constants.TENTHOUSAND);
        TransferHelper.safeTransfer(defiLP, nodePool, nodePoolReward);

        uint256 computingPoolReward = liquidity.sub(nodePoolReward);
        TransferHelper.safeApprove(defiLP, computingPool, computingPoolReward);
        IComputingPool(computingPool).depositComp(msg.sender, upgradeFee);
        IComputingPool(computingPool).recordsDailyLp(computingPoolReward);

        emit Upgrade(msg.sender, upgradeFee, depositCoin, Constants.STATE_UPGRADE);

    }

    function subscription(uint256 depositAmount) external checkInviter checkPausableV2 {
        require(depositAmount <= _remainingSub(msg.sender), 'narkV2: not enough');

        TransferHelper.safeTransferFrom(depositCoin, msg.sender, address(this), depositAmount);

        address parents = relation.inviter(msg.sender);
        uint256 inviteReward = FullMath.mulDiv(upgradeFee, Constants.SUB_PUSH_REWARD, Constants.TENTHOUSAND);
        if (users[parents].state == Constants.STATE_UPGRADE) {
            emit Commission(msg.sender, msg.sender, depositCoin, inviteReward, depositDecimal, Constants.COMMISSION_RECOMMEND);
            TransferHelper.safeTransfer(depositCoin, parents, inviteReward);
        } else {
            TransferHelper.safeTransfer(depositCoin, vault, inviteReward); 
        } 

        uint256 daoVaultRewad = FullMath.mulDiv(upgradeFee, Constants.SUB_VAULT_REWARD, Constants.TENTHOUSAND);
        TransferHelper.safeTransfer(depositCoin, daoVault, daoVaultRewad); 

        uint256 amountLP = depositAmount.sub(daoVaultRewad).sub(inviteReward);

        uint256[] memory amountsPair1 = _wethSwap(depositCoin, transitCoin, amountLP);
        uint256 transitCoinAmount = amountsPair1[2];

        uint256 useTransitCoin = FullMath.mulDiv(transitCoinAmount, Constants.HALF, Constants.DENOMINATOR);
        uint256[] memory amountsPair2 = _swap(transitCoin, platformCoin, useTransitCoin);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = _addLiquidity(
            platformCoin,
            transitCoin,
            amountsPair2[1],
            transitCoinAmount.sub(useTransitCoin),
            address(this)
        );
        _refund(amountsPair2[Constants.ONE].sub(amountA), amountsPair1[Constants.TWO].sub(useTransitCoin).sub(amountB), msg.sender);

        User storage user = users[msg.sender];
        user.userDeposit = user.userDeposit.add(depositAmount);

        uint256 userAmount = FullMath.mulDiv(liquidity, Constants.SUB_USER, Constants.TENTHOUSAND);
        TransferHelper.safeTransfer(defiLP, msg.sender, userAmount);

        TransferHelper.safeTransfer(defiLP, nodePool, liquidity.sub(userAmount));

        emit LpBuy(msg.sender, depositAmount, userAmount, depositCoin, defiLP);
        
    }

    function redemption(uint256 liquidity) external checkPausableV2 returns (uint256, uint256) {
        TransferHelper.safeTransferFrom(defiLP, msg.sender, address(this), liquidity);

        uint256 nodePoolReward = FullMath.mulDiv(liquidity, Constants.SELL_NODE_POOL_LP, Constants.TENTHOUSAND);
        TransferHelper.safeTransfer(defiLP, nodePool, nodePoolReward);

        (uint256 amountA, uint256 amountB) = _removeLiquidity(platformCoin, transitCoin, liquidity.sub(nodePoolReward), address(this));
        uint256 userAmount = FullMath.mulDiv(amountB, Constants.SELL_USER, Constants.TENTHOUSAND);
        TransferHelper.safeTransfer(transitCoin, msg.sender, userAmount);

        uint256 daoVaultReward = amountB.sub(userAmount);
        uint256[] memory amounts = _wethSwap(transitCoin, depositCoin, daoVaultReward);
        TransferHelper.safeTransfer(depositCoin, daoVault, amounts[2]);

        INarkCoin(platformCoin).burn(amountA);
        emit LpSell(msg.sender, liquidity, amountB, FullMath.mulDiv(liquidity, Constants.FIVE, Constants.DENOMINATOR), defiLP, transitCoin);

        return (amountA, amountB);
    }

    function computedLP(uint256 liquidity) external view returns (uint256 platformAmount, uint256 transitAmount) {
        (platformAmount, transitAmount) = _computedLP(liquidity, platformCoin, transitCoin);
    }

    function computedLPToU(
        uint256 liquidity
    ) external view returns (uint256 platformAmount, uint256 transitAmount, uint256 depositAmount) {
        if (liquidity == 0) {
            return (0, 0, 0);
        }
        (platformAmount, transitAmount) = _computedLP(liquidity, platformCoin, transitCoin);
        uint platformTotransitAmount = _getAmountsOut(platformAmount, platformCoin, transitCoin);
        depositAmount = _getWethAmountsOut(transitAmount.add(platformTotransitAmount), transitCoin, depositCoin);
    }

    function _upgradeVIPAndRewardV1(address user) internal {
        address sup = relation.inviter(user);
        if (sup == address(0)) {
            return;
        }
        upgradeDPushCount[sup]++;
        _upgradeVIPLevel(sup);
        _upgradeVIPAndRewardV1(sup);
    }

    function _upgradeVIPAndReward(address user, uint8 alreadProportion, uint8 vipLevel, uint256 levelDiffAmount, uint256 amount) internal returns(uint256) {
        address sup = relation.inviter(user);
        upgradeDPushCount[sup]++;
        _upgradeVIPLevel(sup);
        uint needLevelDiffAmount;
        if (sup == address(0)) {
            return levelDiffAmount;
        }
        User memory supUser = users[sup];
        if (supUser.vipLevel > vipLevel && vipLevel < highestVIP) {
            (alreadProportion, needLevelDiffAmount) = _computeLevelDiffRewards(
                amount,
                supUser,
                alreadProportion
            );
            if (levelDiffAmount <= needLevelDiffAmount) {
                needLevelDiffAmount = levelDiffAmount;
            }
            levelDiffAmount = levelDiffAmount.sub(needLevelDiffAmount);
            if (needLevelDiffAmount > 0) {
                TransferHelper.safeTransfer(defiLP, sup, needLevelDiffAmount);
            }
            emit Commission(
                msg.sender,
                sup,
                defiLP,
                needLevelDiffAmount,
                defiLPDecimal,
                Constants.COMMISSION_LEVEL_DIFF
            );
            vipLevel = supUser.vipLevel;
        }
        return _upgradeVIPAndReward(sup, alreadProportion, vipLevel, levelDiffAmount, amount);
    }

    function _upgradeVIPLevel(address user) internal {
        if (upgradeDPush[user].length < Constants.THREE) {
            return;
        }
        User storage curlUser = users[user];
        if (curlUser.vipLevel == highestVIP) {
            return;
        }
        bool isUpgrade;
        if (curlUser.vipLevel == 0) {
            VIPInfo memory baseInfo = vipInfo[Constants.ONE];
            if (upgradeDPushCount[user] < baseInfo.quantity) {
                return;
            }
            curlUser.vipLevel = baseInfo.level;
            isUpgrade = true;
        }
        VIPInfo memory curlInfo = vipInfo[curlUser.vipLevel];
        for (uint8 i = curlInfo.nextLevel; i <= highestVIP; i++) {
            VIPInfo memory nextInfo = vipInfo[i];
            bool flag = _checkVip(user, curlInfo.level, nextInfo.quantity);
            if (!flag) {
                break;
            }
            curlInfo = vipInfo[i];
            curlUser.vipLevel = curlInfo.level;
            isUpgrade = true;
        }
        if (isUpgrade) {
            emit VipUpgrade(msg.sender, user, curlInfo.level);
        }
    }

    function _computeLevelDiffRewards(
        uint256 levelDiffAmount,
        User memory user,
        uint8 alreadProportion
    ) internal view returns (uint8 proportion, uint256 needLevelDiffAmount) {
        VIPInfo memory supVipInfo = vipInfo[user.vipLevel];
        uint8 needProportion = supVipInfo.award - alreadProportion;
        proportion = supVipInfo.award;
        needLevelDiffAmount = FullMath.mulDiv(
            levelDiffAmount,
            needProportion,
            Constants.TWENTY
        );
    }

    function _checkVip(address _userAddress, uint8 level, uint256 quantity) internal view returns (bool){
        address[] memory direct = relation.directPush(_userAddress);
        bool flag = false;
        uint32 counter = 0;
        for (uint i = 0; i < direct.length; i++) {
            if(_checkVipLevel(direct[i], level)){
                counter++;
            }
            if(counter >= quantity){
                return true;
            }
        }
        return flag;
    }

    function _checkVipLevel(address _userAddress, uint8 level) internal view returns (bool){
        address[] memory direct = relation.directPush(_userAddress);
        bool flag = false;
        if (users[_userAddress].vipLevel >= level){
            return true;
        }
        for (uint i = 0; i < direct.length; i++) {
            if(users[direct[i]].vipLevel >= level){
                return true;
            }
            flag = _checkVipLevel(direct[i], level);
            if(flag){
                break;
            }
        }
        return flag;
    }
  
    function _remainingSub(address userAddr) internal view returns (uint) {
        User memory user = users[userAddr];

        uint256 num = upgradeDPush[userAddr].length;
        uint256 amount = num.mul(Constants.HUNDRED);

        return amount.sub(user.userDeposit);
    }

    function _refund(uint256 amountA, uint256 amountB, address user) internal  {
        if (amountA != 0) {
            TransferHelper.safeTransfer(platformCoin, user, amountA);
        }
        if (amountB != 0) {
            TransferHelper.safeTransfer(transitCoin, user, amountB);
        }
    }   

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interface/ISushiSwapRouter02.sol';
import './lib/Path.sol';
import './lib/FullMath.sol';
import './SushiSwapV2Swap.sol';
import './lib/TransferHelper.sol';

contract SushiSwapV2Adapter is SushiSwapV2Swap {
    address public defiLP;
    uint256 public liquiditySlippage;

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        address to
    ) internal returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        TransferHelper.safeApprove(tokenA, defiRouter, amountADesired);
        TransferHelper.safeApprove(tokenB, defiRouter, amountBDesired);

        return
            ISushiSwapRouter02(defiRouter).addLiquidity(
                tokenA,
                tokenB,
                amountADesired,
                amountBDesired,
                FullMath.mulDiv(amountADesired, liquiditySlippage, Constants.DENOMINATOR),
                0,
                to,
                block.timestamp + 5 minutes
            );
    }

    function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        address to
    ) internal returns (uint256, uint256) {
        TransferHelper.safeApprove(defiLP, defiRouter, liquidity);

        (uint256 tokenAAmount, uint256 tokenBAmount) = _computedLP(liquidity, tokenA, tokenB);

        (uint256 amountA, uint256 amountB) = ISushiSwapRouter02(defiRouter).removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            FullMath.mulDiv(tokenAAmount, liquiditySlippage, Constants.DENOMINATOR),
            FullMath.mulDiv(tokenBAmount, liquiditySlippage, Constants.DENOMINATOR),
            to,
            block.timestamp + 5 minutes
        );

        return (amountA, amountB);
    }

    function _computedLP(
        uint256 liquidity,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        uint256 total = IERC20(defiLP).totalSupply();
        uint256 tokenABalance = IERC20(tokenA).balanceOf(defiLP);
        uint256 tokenBBalance = IERC20(tokenB).balanceOf(defiLP);
        tokenAAmount = FullMath.mulDiv(liquidity, tokenABalance, total);
        tokenBAmount = FullMath.mulDiv(liquidity, tokenBBalance, total);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import './interface/ISushiSwapRouter02.sol';
import './lib/Constants.sol';
import './lib/Path.sol';
import './lib/FullMath.sol';
import './lib/TransferHelper.sol';

contract SushiSwapV2Swap {

    address public defiRouter;
    address public weth;
    uint256 public swapSlippage;

    function _swap(address tokenA, address tokenB, uint256 tokenAAmount) internal returns (uint256[] memory amounts) {
        TransferHelper.safeApprove(tokenA, defiRouter, tokenAAmount);

        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        uint256[] memory paramAmounts = getAmountsOut(tokenAAmount, path);

        amounts = ISushiSwapRouter02(defiRouter).swapExactTokensForTokens(
            tokenAAmount,
            FullMath.mulDiv(paramAmounts[1], swapSlippage, Constants.DENOMINATOR),
            path,
            address(this),
            block.timestamp + 5 minutes
        );
    }

    function _wethSwap(address tokenA, address tokenB, uint256 tokenAAmount) internal returns (uint256[] memory amounts) {
        TransferHelper.safeApprove(tokenA, defiRouter, tokenAAmount);

        address[] memory path = new address[](3);
        path[0] = tokenA;
        path[1] = weth;
        path[2] = tokenB;

        uint256[] memory paramAmounts = getAmountsOut(tokenAAmount, path);

        amounts = ISushiSwapRouter02(defiRouter).swapExactTokensForTokens(
            tokenAAmount,
            FullMath.mulDiv(paramAmounts[1], swapSlippage, Constants.DENOMINATOR),
            path,
            address(this),
            block.timestamp + 5 minutes
        );
    }

    function _pathToSwap(address tokenA, address[] memory path, uint256 tokenAAmount) internal returns (uint256[] memory amounts) {
        TransferHelper.safeApprove(tokenA, defiRouter, tokenAAmount);

        uint256[] memory paramAmounts = getAmountsOut(tokenAAmount, path);

        amounts = ISushiSwapRouter02(defiRouter).swapExactTokensForTokens(
            tokenAAmount,
            FullMath.mulDiv(paramAmounts[1], swapSlippage, Constants.DENOMINATOR),
            path,
            address(this),
            block.timestamp + 5 minutes
        );
    }

    function _getAmountsOut(uint256 amountIn, address tokenA, address tokenB) internal view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        uint256[] memory amounts = ISushiSwapRouter02(defiRouter).getAmountsOut(amountIn, path);
        return amounts[1];
    }

    function _getWethAmountsOut(uint256 amountIn, address tokenA, address tokenB) internal view returns (uint) {
        uint256 wethAmount = _getAmountsOut(amountIn, tokenA, weth);
        if (wethAmount == 0) {
            return 0;
        }
        address[] memory path = new address[](3);
        path[0] = tokenA;
        path[1] = weth;
        path[2] = tokenB;
        uint256[] memory amounts = ISushiSwapRouter02(defiRouter).getAmountsOut(amountIn, path);
        return amounts[2];
    }

    function getAmountsOut(uint256 amountIn, address[] memory path) internal view returns (uint256[] memory amounts) {
        amounts = ISushiSwapRouter02(defiRouter).getAmountsOut(amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path) internal view returns (uint256[] memory amounts) {
        amounts = ISushiSwapRouter02(defiRouter).getAmountsIn(amountOut, path);
    }
}