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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC1155Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol';

struct CallbackParams {
  uint256 endDate;
  uint256 penaltyRate;
  uint256 interestRate;
  uint256 exchangeRate;
}

/**
 * @title Interface for a `BondNFT.sol`;
 */
interface IBondNFT is IERC1155Upgradeable {
  /// @notice Creating a new NFT contract and setting inside parameters;
  function __init(address _poolMasterAddress, string memory _uri) external returns (bool);

  /// @notice Minting tokens;
  function mint(
    address _account,
    uint256 _id,
    uint256 _amount,
    bytes memory _data,
    CallbackParams calldata _callBackParams
  ) external;

  /// @notice Burning tokens;
  function burn(address _account, uint256 _id, uint256 _amount) external;

  /// @notice Return balance of `msg.sender`;
  function balanceOf(address account, uint256 id) external view returns (uint256);

  /// @notice Return id information params;
  function tokenData(uint256 id) external view returns (CallbackParams memory);


  function setExchangeRate(uint256 id, uint256 exchangeRate) external;

  /// @notice Minting batch tokens;
  function mintBatch(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) external;

  /// @notice Burning batch tokens;
  function burnBatch(address _account, uint256[] memory _ids, uint256[] memory _amounts) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {RewardAsset} from '../libraries/RewardAsset.sol';

/**
 * @title Interface for a `PoolFactory.sol`;
 */

interface IPoolFactory {
  function checkKycStatus(address _account) external;

  function checkBorrowerStatus(address _borrower) external;

  function owner() external view returns (address);

  function getPoolConfigVars()
    external
    view
    returns (uint256, uint256, uint256, uint256, RewardAsset.RewardAssetData[] memory);

  function treasury() external view returns (address);

  function auction() external view returns (address);

  function isPool(address pool) external view returns (bool);

  function processPoolAuctionStart(address pool) external;

  function processPoolAuctionEnd(address pool, uint256 claimedAmount) external;
}

interface IPoolFactoryLite {
  function whitelistLender(address _lender) external;

  function whitelistBorrower(address _borrower) external;

  function blacklistLender(address _lender) external;

  function blacklistBorrower(address _borrower) external;

  function whitelistedLenders(address _account) external view returns (bool);

  function whitelistedBorrowers(address _account) external view returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

struct InitParams {
  uint256 depositCap;
  uint256 repaymentFrequency;
  uint256 minimumNoticePeriod;
  uint256 minDeposit;
  uint256 lendAPR;
  address borrower;
  address asset;
  address bondNFT;
  string name;
  string borrowerSymbol;
}

///@dev Defining a Status Enumeration;
enum PoolStatus {
  Active,
  Overdue,
  Default,
  Closed
}

/**
 * @title Interface for a `PoolMaster.sol`;
 */
interface IPoolMaster {
  /// @notice creating a new pool and setting inside parameters;
  function __init(InitParams calldata params, bool kycRequired) external returns (bool);

  /// @notice returning the `deposit cap`;
  function depositCap() external view returns (uint256);

  /// @notice returning the `repayment frequency`;
  function repaymentFrequency() external view returns (uint256);

  /// @notice returning the `minimum notice period`;
  function minimumNoticePeriod() external view returns (uint256);

  /// @notice returning the `lend APR`;
  function lendAPR() external view returns (uint256);

  /// @notice returning the `asset`;
  function asset() external view returns (address);

  /// @notice returning the `symbol`;
  function symbol() external view returns (string memory);

  /// @notice returning the `borrower`;
  function borrower() external view returns (address);

  function checkKycStatus(address _account) external;

  function status() external view returns (PoolStatus);

  function decimals() external view returns (uint8);

  function poolSize() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function withdrawReward(address _asset, address account) external returns (uint256);

  function supply(uint256 _amount) external;

  function repay() external;

  function repayAll() external;

  function redeem(uint256 _amount) external;

  function redeemBond(uint256 bondId) external;

  function processAuctionStart() external;

  function processDebtClaim(uint256 _payedAmount) external;

  function changeBorrower(address _borrower) external;

  function cancelAuction() external;

  function applyBondRewardCorections(
    uint256 roundDate,
    uint256 bondId,
    address from,
    address to,
    uint256 amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Decimal {
  /// @notice Number one as 18-digit decimal
  uint256 internal constant MULTIPLIER = 1e18;

  /**
   * @notice Internal function for 10-digits decimal division
   * @param number Integer number
   * @param decimal Decimal number
   * @return Returns multiplied numbers
   */
  function mulDecimal(uint256 number, uint256 decimal) internal pure returns (uint256) {
    return (number * decimal) / MULTIPLIER;
  }

  /**
   * @notice Internal function for 10-digits decimal multiplication
   * @param number Integer number
   * @param decimal Decimal number
   * @return Returns integer number divided by second
   */
  function divDecimal(uint256 number, uint256 decimal) internal pure returns (uint256) {
    return (number * MULTIPLIER) / decimal;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {SafeCastUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol';

library RewardAsset {
  using SafeCastUpgradeable for uint256;
  using SafeCastUpgradeable for int256;

  struct RewardAssetData {
    address asset; // the addess of the reward asset
    uint256 rate; // the reward rate of the asset
  }

  struct Data {
    mapping(address => bool) flags; // tracks whether the reward has already been added or not.
    mapping(address => uint256) addressIndex; // saves the index of each reward asset
    mapping(address => uint256) magnifiedRewardPerShare; // rewardAsset -> magnifiedRewardPerShare
    mapping(uint256 => uint256) roundLastDistribution; //Timestamp when last round staking reward distribution occurred
    mapping(address => mapping(address => int256)) magnifiedRewardCorrections; // rewardAsset -> account -> magnifiedReward correction
    mapping(address => mapping(address => uint256)) rewardWithdrawals; // rewardAsset -> lender -> amount
    mapping(uint256 => mapping(address => uint256)) magnifiedRoundRewardPerShare; // round bond ID -> rewardAsset -> magnifiedRewardPerShare
    RewardAssetData[] rewardAssetData; // the array of the rewardAssetData
    uint256 id; //a number that increments when a new reward asset is added
    uint256 lastRewardDistribution; //Timestamp when last staking reward distribution occurred
  }

  /**
   * @notice used to insert new reward asset with rate
   * @param self see {Data}
   * @param asset the address of the reward asset 
   * @param rate  the reward rate of the asset
   */
  function insert(Data storage self, address asset, uint256 rate) internal returns (bool) {
    if (self.flags[asset]) {
      uint256 index = self.addressIndex[asset];

      if (self.rewardAssetData[index].rate == rate) {
        return false;
      }
      self.rewardAssetData[index].rate = rate;
      return true;
    }

    self.flags[asset] = true;
    self.rewardAssetData.push(RewardAssetData(asset, rate));
    self.addressIndex[asset] = self.id;
    self.id++;
    return true;
  }
  /**
   * see {decreaseRewardCorrection}
   */
  function decreaseRewardCorrection(
    Data storage self,
    address asset,
    address account,
    uint256 amount
  ) internal {
    return
      decreaseRewardCorrection(self, asset, account, amount, self.magnifiedRewardPerShare[asset]);
  }

   /**
    * @notice decreases the reward of the specified asset for the given account
    * @param self see {Data}
    * @param asset the address of the reward asset
    * @param account the address of the lender
    * @param amount the number of reward per share
    * @param share the number of shares held by the lender
    */
  function decreaseRewardCorrection(
    Data storage self,
    address asset,
    address account,
    uint256 amount,
    uint256 share
  ) internal {
    self.magnifiedRewardCorrections[asset][account] -= (share * amount).toInt256();
  }

  /**
   * see {increaseRewardCorrection}
   */
  function increaseRewardCorrection(
    Data storage self,
    address asset,
    address account,
    uint256 amount
  ) internal {
    return
      increaseRewardCorrection(self, asset, account, amount, self.magnifiedRewardPerShare[asset]);
  }

   /**
    * @notice increases the reward of the specified asset for the given account
    * @param self see {Data}
    * @param asset the address of the reward asset
    * @param account the address of the lender
    * @param amount the number of reward per share
    * @param share the number of shares held by the lender
    */ 
  function increaseRewardCorrection(
    Data storage self,
    address asset,
    address account,
    uint256 amount,
    uint256 share
  ) internal {
    self.magnifiedRewardCorrections[asset][account] += (share * amount).toInt256();
  }

  /**
   * @notice used to calculate and save the reward per share
   * @param self see {Data}
   * @param asset the address of the asset
   * @param period the duration of time between now and the last reward distribution date
   * @param rate the number of the reward rate
   * @param rewardMagnitude value by which all rewards are magnified for calculation
   * @param totalSupply the total supply of pool tokens
   */
  function updateMagnifiedRewardPerShare(
    Data storage self,
    address asset,
    uint256 period,
    uint256 rate,
    uint256 rewardMagnitude,
    uint256 totalSupply
  ) internal {
    uint256 _rewardPerShare = ((rewardMagnitude * period * rate)) / totalSupply;
    self.magnifiedRewardPerShare[asset] += _rewardPerShare;
  }

   /**
   * @notice used to calculate and save the reward per share for the given round
   * @param self see {Data}
   * @param asset the address of the asset
   * @param roundBondId the round bond Id
   * @param period the duration of time between now and the last reward distribution date
   * @param rate the number of the reward rate
   * @param rewardMagnitude value by which all rewards are magnified for calculation
   * @param totalSupply the total supply of pool tokens
   */
  function updateMagnifiedRoundRewardPerShare(
    Data storage self,
    address asset,
    uint256 roundBondId,
    uint256 period,
    uint256 rate,
    uint256 rewardMagnitude,
    uint256 totalSupply
  ) internal {
    uint256 _rewardPerShare = ((rewardMagnitude * period * rate)) / totalSupply;
    self.magnifiedRoundRewardPerShare[roundBondId][asset] += _rewardPerShare;
  }

  /**
   * @notice used to update the reward withdrawn by the lender for the specified asset
   * @param self see {Data}
   * @param asset the address of the asset
   * @param account the address of the lender
   * @param amount the amount of reward withdrawn
   */
  function updateRewardWithdrawals(
    Data storage self,
    address asset,
    address account,
    uint256 amount
  ) internal {
    self.rewardWithdrawals[asset][account] += amount;
  }

  /**
   * @notice used to retrieve the list of available reward assets
   * @param self see {Data}
   * @return returns the array of the reward assets
   */
  function getList(Data storage self) internal view returns (RewardAssetData[] memory) {
    return self.rewardAssetData;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20Upgradeable, IERC20MetadataUpgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import {SafeERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import {ReentrancyGuardUpgradeable} from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {SafeCastUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol';

import {IBondNFT, CallbackParams} from './interfaces/IBondNFT.sol';
import {IPoolFactory} from './interfaces/IPoolFactory.sol';
import {InitParams, PoolStatus} from './interfaces/IPoolMaster.sol';

import {UtilsGuard} from './utils/Utils.sol';
import {Decimal} from './libraries/Decimal.sol';
import {RewardAsset} from './libraries/RewardAsset.sol';

/**
 * @title A smart contract storage the open pool;
 * @notice Credit Vaults Pool is a very flexible lending product that has higher lender APR,
 *  potentially high flexibility for lenders, and can be customized and used by any borrower type;
 */
contract PoolMaster is Initializable, ERC20Upgradeable, ReentrancyGuardUpgradeable, UtilsGuard {
  using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
  using Decimal for uint256;
  using RewardAsset for RewardAsset.Data;
  using SafeCastUpgradeable for uint256;
  using SafeCastUpgradeable for int256;

  /**
   * All events:
   *  {Supplied} - returning info about supplied of liquidity;
   *  {WithdrawalRequested} - returning info about requested amount;
   *  {Redeemed} - returning info about redeemed liquidity;
   *  {DepositCapChanged} - returning info about the changed deposit capacity;
   *  {MinDepositChanged} - returning info about the changed minimum deposit;
   *  {NoticePeriodChanged} - returning info about the changed notice period;
   *  {RepaymentFrequencyChanged} - returning info about the changed repayment frequency;
   *  {BondRedeemed} - durning info about the redeemed bond NFT;
   *  {RepaymentRequested} - returning info about the requested repayment;
   *  {APRChanged} - returning info about the changed APR;
   *  {APRChangeRequested} - returning info about the requested APR change;
   *  {BorrowerChanged} - returning info about the changed borrower;
   *  {PoolProtocolFeeChanged} - returning info about the changed pool protocol fee;
   *  {RewardAssetInfoSet} - returning info about the set reward asset info;
   *  {FullRepayment} - returning info about the full repayment;
   *  {Repayment} - returning info about the repayment;
   *  {RewardWithdrawn} - returning info about the withdrawn reward;
   *  {Closed} - returning if the pool is closed;
   *  {Defaulted} - returning if the pool is defaulted;
   */
  event Supplied(address indexed lender, uint256 amount, uint256 tokensAmount);
  event WithdrawalRequested(
    address indexed lender,
    uint256 repaymentDate,
    uint256 amount,
    uint256 bondNFTIdCounter
  );
  event Redeemed(address indexed lender, uint256 amount, uint256 tokensAmount);
  event DepositCapChanged(uint256 newDepositCap);
  event MinDepositChanged(uint256 newMinDeposit);
  event NoticePeriodChanged(uint256 newValue);
  event RepaymentFrequencyChanged(uint256 newRepaymentFrequency);
  event BondRedeemed(
    address indexed lender,
    uint256 indexed bondId,
    uint256 amount,
    uint256 receivedAmount
  );
  event RepaymentRequested(uint256 repaymentDate);
  event APRChanged(uint256 newAPR);
  event APRChangeRequested(uint256 newAPR, uint256 applyDate);
  event BorrowerChanged(address newBorrower);

  event RewardAssetInfoSet(address asset, uint256 rate);
  event FullRepayment(uint256 amount, uint256 penaltyAmount, uint256 feesAmount);
  event Repayment(uint256 amount, uint256 penaltyAmount, uint256 feesAmount);
  event RewardWithdrawn(address asset, uint256 amount);
  event Closed();
  event Defaulted();

  /**
   *  All Errors:
   */
  error WrongNumber();
  error OnlyFactory();
  error OnlyBorrower();
  error OnlyGovernor();
  error PoolInactive();
  error PoolHasLiquidity();
  error InsufficientFunds();
  error NoDebtFound();
  error RepaymentMissing();

  /**
   * @notice Deposit Cap - amount beyond which Lenders can't execute deposit transaction
   */
  uint256 public depositCap;

  /**
   * @notice repayments are being made (every X days)
   */
  uint256 public repaymentFrequency;

  /**
   * @notice notice period for withdrawals
   */
  uint256 public minimumNoticePeriod;

  /**
   * @notice minimum deposit amount
   */
  uint256 public minDeposit;

  /**
   * @notice Lending APR
   */
  uint256 public lendAPR;

  uint256 public penaltyRate;
  uint256 public gracePeriod;
  uint256 public protocolFee;
  uint256 public periodToStartAuction;

  bool public isKycRequired;

  address public borrower;
  IERC20MetadataUpgradeable public asset;
  IPoolFactory public poolFactory;
  IBondNFT public bondNFT;

  uint8 private _decimals;
  uint256 private _bondNFTIdCounter;
  uint256 private _fullRepaymentDate;

  bool internal isAuctionStarted;
  uint256 internal _currentRepaymentDate;
  uint256 internal _lastRequestIndex;

  uint public constant MINIMUM_LIQUIDITY = 10 ** 3;

  struct RepaymentRoundInfo {
    uint256 debtAmount;
    uint256 bondTokenId;
    uint256 paidAt;
    uint256 exchangeRate;
  }

  /**
   * @dev Record the debt info for a specific repayment period.
   * @notice `Repayment` date -> `Repayment round` info;
   */
  mapping(uint256 => RepaymentRoundInfo) public repaymentRoundInfo;

  struct BorrowInfo {
    uint256 borrows;
    uint256 feesAmount;
    uint256 penaltyAmount;
    uint256 exchangeRate;
    uint256 lastAccrual;
    uint256 overdueEntrance;
    PoolStatus status;
  }

  BorrowInfo internal _info;
  RewardAsset.Data internal rewardAssetInfo;

  mapping(uint256 => uint256) internal _aprChanges;

  /// @notice Number of unpaid repayment rounds, used to block withdrawals if there are 2 active rounds
  uint8 private _unpaidRounds;

  /**
   * @dev Modifier that allows only PoolsFactory to call the function;
   */
  modifier onlyPoolFactory() {
    if (msg.sender != address(poolFactory)) revert OnlyFactory();
    _;
  }

  /**
   * @dev Modifier that allows only `borrower`;
   */
  modifier onlyBorrower() {
    if (msg.sender != borrower) revert OnlyBorrower();
    _;
  }

  /**
   * @dev Modifier that pool was closed;
   */
  modifier onlyActive() {
    accrueInterest();
    PoolStatus poolStatus = _status(_info);
    if (poolStatus != PoolStatus.Active && poolStatus != PoolStatus.Overdue) revert PoolInactive();
    _;
  }

  modifier onlyEligible(address _account) {
    /// Exclude ongoing pool transfers;
    if (_account != address(this) && _account != address(0)) {
      checkKycStatus(_account);
    }
    _;
  }

  modifier onlyGovernor() {
    if (msg.sender != poolFactory.owner()) revert OnlyGovernor();
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @dev Initializing parameters of the term pool contract;
   * @notice Initializing pool with input parameters,
   *  returning `true` if all `success`;
   */
  function __init(
    InitParams calldata params,
    bool kycRequired
  ) public virtual initializer returns (bool) {
    __ReentrancyGuard_init();

    asset = IERC20MetadataUpgradeable(params.asset);

    string memory currencySymbol = asset.symbol();
    __ERC20_init(
      params.name,
      string(
        bytes.concat(bytes('cp'), bytes(params.borrowerSymbol), bytes('-'), bytes(currencySymbol))
      )
    );
    _decimals = asset.decimals();

    /// Setting address of the `BondNFT`;
    bondNFT = IBondNFT(params.bondNFT);
    /// Setting address of the `PoolFactory.sol`;
    poolFactory = IPoolFactory(msg.sender);

    /// Initializing a new `nft contract` with parameters;
    bool success = bondNFT.__init(address(this), '');
    /// For some reason, the pool was not created;
    if (success == false) return false;

    /// Setting `protocol rates and fees`;
    RewardAsset.RewardAssetData[] memory _rewardAssetInfo;
    (penaltyRate, gracePeriod, protocolFee, periodToStartAuction, _rewardAssetInfo) = poolFactory
      .getPoolConfigVars();

    // Copy rewardAsset info from pool factory;
    // Sets the index of each asset and saves asset info;
    for (uint256 i; i < _rewardAssetInfo.length; i++) {
      rewardAssetInfo.insert(_rewardAssetInfo[i].asset, _rewardAssetInfo[i].rate);
    }
    /// We initialize its data;
    minDeposit = params.minDeposit;
    depositCap = params.depositCap;
    repaymentFrequency = params.repaymentFrequency;
    minimumNoticePeriod = params.minimumNoticePeriod;
    lendAPR = params.lendAPR;
    borrower = params.borrower;
    isKycRequired = kycRequired;

    _info.lastAccrual = block.timestamp;
    _info.exchangeRate = Decimal.MULTIPLIER;

    return true;
  }

  /**
   * @dev Supply of liquidity for open pool;
   * @notice `Lender` provides the borrower pool with the required amount of `asset`;
   *  {tokensAmount} - amount after you deposit USDC;
   */
  function supply(uint256 _amount) external nonReentrant onlyActive {
    if (msg.sender == borrower || _fullRepaymentDate != 0) revert ActionNotAllowed();

    // Check lender kyc status
    checkKycStatus(msg.sender);

    /// @dev If borrower is blacklisted, deposits are blocked
    poolFactory.checkBorrowerStatus(borrower);

    uint256 currentSize = poolSize();
    bool depositCapEnabled = depositCap != 0;

    if (_amount == type(uint256).max) {
      _amount = asset.balanceOf(msg.sender);

      if (depositCapEnabled) {
        if (currentSize >= depositCap) revert WrongNumber();
        uint256 allowedAmount = depositCap - currentSize;
        _amount = _amount > allowedAmount ? allowedAmount : _amount;
      }
    }

    if (
      _amount == 0 ||
      minDeposit > _amount ||
      (depositCapEnabled && _amount + currentSize > depositCap)
    ) revert WrongNumber();

    // swap the supplied amount
    uint256 tokensAmount = _amount.divDecimal(_info.exchangeRate);

    if (_currentRepaymentDate == 0) {
      /// Set currentRepayment date on initial supply;
      _currentRepaymentDate = block.timestamp + repaymentFrequency;

      if (tokensAmount < MINIMUM_LIQUIDITY) revert WrongNumber();
      tokensAmount -= MINIMUM_LIQUIDITY;
      _mint(address(this), MINIMUM_LIQUIDITY);
    }

    _info.borrows += _amount;

    _mint(msg.sender, tokensAmount);
    asset.safeTransferFrom(msg.sender, borrower, _amount);

    emit Supplied(msg.sender, _amount, tokensAmount);
  }

  /**
   * @notice Used to request a withdrawal;
   * @param _amount - number of asset user wants to withdraw;
   *  {calculatedAmount} - calculated amount of the `bondNFT`;
   */
  function requestWithdrawal(uint256 _amount) external onlyActive {
    if (_fullRepaymentDate != 0) revert ActionNotAllowed();
    if (_amount == type(uint256).max) {
      _amount = balanceOf(msg.sender);
    }
    if (_amount == 0 || _amount > balanceOf(msg.sender)) revert InsufficientFunds();

    // get current repayment date
    uint256 currentRepDate = currentRepaymentDate();

    // Get the next repayment date allowed for withdrawal
    uint256 repDate = getNextRepaymentDate();

    // store current repayment date in case it was virtually calculated
    if (repaymentRoundInfo[currentRepDate].debtAmount == 0 && currentRepDate != repDate) {
      _currentRepaymentDate = repDate;
    } else {
      _currentRepaymentDate = currentRepDate;
    }

    RepaymentRoundInfo storage info = repaymentRoundInfo[repDate];
    if (info.bondTokenId == 0) {
      /// Increasing `_bondNFTIdCounter` only if the repayment round is different;
      _bondNFTIdCounter += 1;
      info.bondTokenId = _bondNFTIdCounter;

      // Block withdrawals in case there are already 2 active repayment rounds
      if (_unpaidRounds == 2) revert ActionNotAllowed();
      ++_unpaidRounds;
    } else if (info.paidAt != 0 && _unpaidRounds == 0) {
      // the current round was paid already, but still may store withdrawals

      /// Increasing `_bondNFTIdCounter` so the new withdrawals can have different exchange rate;
      _bondNFTIdCounter += 1;
      info.bondTokenId = _bondNFTIdCounter;

      /// @dev use-case when there are multiple payment for the same round
      ++_unpaidRounds;
    }

    /// Lock `_amount` tokens in the smart contract;
    _transfer(msg.sender, address(this), _amount);

    // start accruing round reward per share
    RewardAsset.RewardAssetData[] memory _rewardAsset = getRewardAssetInfo();
    _accrueRoundReward(repDate);
    for (uint256 i; i < _rewardAsset.length; i++) {
      address rewardAssetAddr = _rewardAsset[i].asset;
      rewardAssetInfo.decreaseRewardCorrection(
        rewardAssetAddr,
        msg.sender,
        _amount,
        rewardAssetInfo.magnifiedRoundRewardPerShare[info.bondTokenId][rewardAssetAddr]
      );
    }
    rewardAssetInfo.roundLastDistribution[info.bondTokenId] = block.timestamp;
    info.debtAmount += _amount;

    /// Store withdrawal info snapshot as token metadata;
    /// Mint ERC1155 tokens to `lender`;
    bondNFT.mint(
      msg.sender,
      _bondNFTIdCounter,
      _amount,
      '',
      CallbackParams({
        endDate: repDate,
        penaltyRate: penaltyRate,
        interestRate: lendAPR,
        exchangeRate: 0
      })
    );
    emit WithdrawalRequested(msg.sender, repDate, _amount, _bondNFTIdCounter);
  }

  /**
   * @notice Used to request a repayment by the governor;
   * @dev only called by governor;
   * @param _repaymentDate The repayment date when borrower should repay;
   */
  function requestFullRepayment(uint256 _repaymentDate) external onlyGovernor onlyActive {
    if (_fullRepaymentDate != 0 || _currentRepaymentDate == 0) revert ActionNotAllowed();

    /// Disallow repayment date in past;
    uint256 currentRepDate = currentRepaymentDate();
    if (block.timestamp > _repaymentDate) revert InvalidArgument();

    /// Repayment date is either future date, or the current unpaid round date;
    _currentRepaymentDate = currentRepDate;
    _fullRepaymentDate = _repaymentDate;
    emit RepaymentRequested(_repaymentDate);
  }

  /**
   * @notice Used by borrower to repay full amount;
   */
  function repayAll() external nonReentrant onlyBorrower onlyActive {
    uint256 repayAmount;
    uint256 penaltyAmount;
    uint256 feesAmount;
    uint256 nextRepDate;

    // In case the full repayment was request, repay interest up to the current timestamp
    if (_fullRepaymentDate != 0) {
      // The existing accrual info should be used to repay full amount
      repayAmount = _info.borrows;
      penaltyAmount = _info.penaltyAmount;
      feesAmount = _info.feesAmount;
      _fullRepaymentDate = 0;

      if (repaymentRoundInfo[_currentRepaymentDate].debtAmount > 0) {
        // Accrue rewards interest for the current round
        _accrueRoundReward(_currentRepaymentDate);

        // Mark future repayments as paid in case the are any
        repaymentRoundInfo[_currentRepaymentDate].debtAmount = 0;
        repaymentRoundInfo[_currentRepaymentDate].paidAt = block.timestamp;
        repaymentRoundInfo[_currentRepaymentDate].exchangeRate = _info.exchangeRate;
      }

      nextRepDate = _getNextUnpaidRound(true);
      if (repaymentRoundInfo[nextRepDate].debtAmount > 0) {
        // Mark future repayments as paid in case the are any
        repaymentRoundInfo[nextRepDate].paidAt = block.timestamp;
        repaymentRoundInfo[nextRepDate].exchangeRate = _info.exchangeRate;
      }
    } else {
      uint256 currentRepDate = currentRepaymentDate();
      RepaymentRoundInfo storage roundInfo = repaymentRoundInfo[currentRepDate];
      BorrowInfo memory bInfo;
      if (roundInfo.debtAmount != 0) {
        // get precalculated amounts for the current repayment date
        uint256 roundSupply = roundInfo.debtAmount;
        (repayAmount, penaltyAmount, feesAmount) = _handleRoundRepay(currentRepDate);

        // burn locked tokens obtained during the withdrawal requests in the current round
        _burn(address(this), roundSupply);

        if (block.timestamp > currentRepDate) {
          // in case the timestamp is above repayment date apply pre-calculated interest for remaining liquidity up to nearest repayment date (in future)
          bInfo = _accrueInterestVirtual(currentRepDate + repaymentFrequency);
          repayAmount += bInfo.borrows;
          feesAmount += bInfo.feesAmount;
          penaltyAmount += bInfo.penaltyAmount;

          /// Store the ex rate for redeeming conversion;
          _info.exchangeRate = bInfo.exchangeRate;

          // get new current repayment date after repaying the overdue one
          nextRepDate = _getNextUnpaidRound(true);
          if (repaymentRoundInfo[nextRepDate].debtAmount > 0) {
            // Mark future repayments as paid in case the are any
            repaymentRoundInfo[nextRepDate].exchangeRate = bInfo.exchangeRate;
            repaymentRoundInfo[nextRepDate].paidAt = bInfo.lastAccrual;
          }
        } else {
          // in case the timestamp is prior to the exchange rate, pre-calculate interest for the remaining liquidity up to the repayment date
          bInfo = _accrueInterestVirtual(currentRepDate);
          repayAmount += bInfo.borrows;
          feesAmount += bInfo.feesAmount;
          penaltyAmount += bInfo.penaltyAmount;

          /// Store the round ex rate for redeeming conversion;
          _info.exchangeRate = roundInfo.exchangeRate;

          nextRepDate = _getNextUnpaidRound(true);
          if (repaymentRoundInfo[nextRepDate].debtAmount > 0) {
            // Mark future repayments as paid in case the are any
            repaymentRoundInfo[nextRepDate].exchangeRate = roundInfo.exchangeRate;
            repaymentRoundInfo[nextRepDate].paidAt = roundInfo.paidAt;
          }
        }
      } else {
        // in case there is no repayment rounds (no withdrawals requested), apply the pre-calculated interest up to repayment date as total interest
        bInfo = _accrueInterestVirtual(currentRepDate);
        repayAmount = bInfo.borrows;
        feesAmount = bInfo.feesAmount;
        penaltyAmount = bInfo.penaltyAmount;

        /// Store the accrued ex rate for redeeming conversion;
        _info.exchangeRate = bInfo.exchangeRate;
      }
    }
    // Reset borrows info
    _info.feesAmount = 0;
    _info.borrows = 0;
    _info.penaltyAmount = 0;
    _info.overdueEntrance = 0;

    // Decrease unpaid rounds;
    _unpaidRounds = 0;

    // Accrue rewards interest for the next round
    _accrueRoundReward(nextRepDate);

    /// Burn all locked tokens obtained during withdrawals requests;
    _burn(address(this), balanceOf(address(this)));

    _transferRepayment(repayAmount, penaltyAmount, feesAmount);
    emit FullRepayment(repayAmount, penaltyAmount, feesAmount);
    _closePool();
  }

  /**
   * @notice used to repay current period debt
   */
  function repay() external nonReentrant onlyBorrower onlyActive {
    uint256 currentRepDate = currentRepaymentDate();
    RepaymentRoundInfo storage roundInfo = repaymentRoundInfo[currentRepDate];
    if (roundInfo.debtAmount == 0) revert NoDebtFound();

    // get precalculated amounts for the current repayment date
    uint256 roundAmount = roundInfo.debtAmount;
    (uint256 amount, uint256 penaltyAmount, uint256 feesAmount) = _handleRoundRepay(currentRepDate);

    // Decrease unpaid rounds;
    _unpaidRounds -= 1;

    // update storage variable // set next repayment date in case in the current one no more withdrawals allowed
    if (minimumNoticePeriod == 0) {
      _currentRepaymentDate = currentRepaymentDate();
    } else {
      _currentRepaymentDate = _getNextUnpaidRound(true);
    }

    // burn locked tokens obtained during the withdrawal requests
    _burn(address(this), roundAmount);

    _transferRepayment(amount, penaltyAmount, feesAmount);
    emit Repayment(amount, penaltyAmount, feesAmount);
  }

  function _handleRoundRepay(
    uint256 currentRepDate
  ) internal returns (uint256 amount, uint256 penaltyAmount, uint256 feesAmount) {
    RepaymentRoundInfo storage roundInfo = repaymentRoundInfo[currentRepDate];

    // calculate the repayment amounts for the current repayment date
    (amount, penaltyAmount, feesAmount) = _dueOf(_info, roundInfo, block.timestamp, currentRepDate);

    if (block.timestamp > currentRepDate) {
      // in case the repayment is happen during overdue period, store payment date and exchange rate for redeeming swap
      roundInfo.paidAt = block.timestamp;
      roundInfo.exchangeRate = _info.exchangeRate;

      // Substract the accrued fees, interest and penalty for lenders requested repayment
      _info.feesAmount -= feesAmount;
      _info.borrows -= amount;
      _info.penaltyAmount -= penaltyAmount;
      _info.overdueEntrance = 0;
    } else {
      roundInfo.paidAt = currentRepDate;

      // apply the exchange rate for redeeming
      roundInfo.exchangeRate = _accrueInterestVirtual(currentRepDate).exchangeRate;

      // apply the exchange rate to the bond
      bondNFT.setExchangeRate(roundInfo.bondTokenId, roundInfo.exchangeRate);

      // calculate interest accrued for lenders that requested repayment up to current ts
      uint256 _borrows = roundInfo.debtAmount.mulDecimal(_info.exchangeRate);

      // extract penalty from _borrows
      _borrows -= penaltyAmount;

      // Substract the accrued fees and interest for lenders requested repayment
      _info.feesAmount -= calcRateAmount(_borrows, _info.borrows, _info.feesAmount);
      _info.borrows -= _borrows;
      _info.penaltyAmount -= penaltyAmount;
    }

    // update rounds reward per share accumulated since first request
    _accrueRoundReward(currentRepDate);
    _accrueRoundReward(_getNextUnpaidRound(false));

    /// @dev After repayment is made the remaining interest and fees are for the available liquidity
    roundInfo.debtAmount = 0;

    return (amount, penaltyAmount, feesAmount);
  }

  function _transferRepayment(uint256 amount, uint256 penaltyAmount, uint256 feesAmount) internal {
    if (feesAmount > 0) {
      // transfer the fees amount to the treasury
      asset.safeTransferFrom(msg.sender, poolFactory.treasury(), feesAmount);
    }
    asset.safeTransferFrom(msg.sender, address(this), amount + penaltyAmount);
  }

  /**
   * @notice Used to redeem liquidity from the pool
   * @param _amount Amount to be redeemed
   */
  function redeem(uint256 _amount) external nonReentrant {
    accrueInterest();
    uint256 tokensBalance = balanceOf(msg.sender);

    // Allow redeeming only if the pool is closed
    if (_info.status != PoolStatus.Closed) revert RepaymentMissing();
    if (_amount == type(uint256).max) _amount = tokensBalance;
    // Disallow redeeming if the amount exceeds balance
    if (_amount == 0 || tokensBalance == 0 || _amount > tokensBalance) revert InsufficientFunds();

    /// Exchange cpTokens for currency tokens
    uint256 receivedAmount = _amount.mulDecimal(_info.exchangeRate);

    /// Burn cpTokens;
    _burn(msg.sender, _amount);

    /// Transfer the currency tokens;
    asset.safeTransfer(msg.sender, receivedAmount);

    emit Redeemed(msg.sender, receivedAmount, _amount);
  }

  /**
   * @dev Swap the bond NFT with the asset amount;
   * @notice Redeeming `_amount` of the NFT to amount `asset`;
   *  {lenderBondAmount} - bond balance of the `lender`;
   */
  function redeemBond(uint256 _id) external nonReentrant {
    accrueInterest();

    /// Get Bond balance of the `lender`;
    uint256 lenderBondAmount = bondNFT.balanceOf(msg.sender, _id);
    if (lenderBondAmount == 0) revert NonZeroValue();

    // get bond token metadata
    CallbackParams memory bondParams = bondNFT.tokenData(_id);
    RepaymentRoundInfo storage roundInfo = repaymentRoundInfo[bondParams.endDate];
    if (roundInfo.paidAt == 0 || roundInfo.paidAt > block.timestamp) revert RepaymentMissing();

    // apply the bond rewards accrued during tokens lock, up to repayment date
    RewardAsset.RewardAssetData[] memory _rewardAsset = getRewardAssetInfo();
    for (uint256 i; i < _rewardAsset.length; i++) {
      address rewardAssetAddr = _rewardAsset[i].asset;
      rewardAssetInfo.increaseRewardCorrection(
        rewardAssetAddr,
        msg.sender,
        lenderBondAmount,
        rewardAssetInfo.magnifiedRoundRewardPerShare[_id][rewardAssetAddr]
      );
    }

    /// burn bond tokens;
    bondNFT.burn(msg.sender, _id, lenderBondAmount);

    // Exchange bond tokens for currency tokens
    uint256 receivedAmount = lenderBondAmount.mulDecimal(roundInfo.exchangeRate);

    // If the bond has the exchange rate stored, use it for conversion
    if (bondParams.exchangeRate != 0) {
      receivedAmount = lenderBondAmount.mulDecimal(bondParams.exchangeRate);
    }

    asset.safeTransfer(msg.sender, receivedAmount);
    emit BondRedeemed(msg.sender, _id, lenderBondAmount, receivedAmount);
  }

  /*
   * @dev Close this pool;
   * @notice `borrower` call this function for closing;
   */
  function closePool() external onlyBorrower {
    // Pool can be closed only if there is no liquidity provided
    if (_currentRepaymentDate != 0) revert PoolHasLiquidity();
    _closePool();
  }

  // this should close even if pool is in default state
  function _closePool() internal {
    if (_info.status == PoolStatus.Closed) revert PoolInactive();
    _info.status = PoolStatus.Closed;
    _currentRepaymentDate = 0;
    emit Closed();
  }

  /**
   * @notice Calculate total due amounts
   * @return Returns the total due amounts;
   */
  function totalDue() external view returns (uint256, uint256, uint256) {
    if (_info.borrows == 0) return (0, 0, 0);
    return _totalDue();
  }

  /**
   * @notice Calculate due amounts
   * @param repDate Repayment round timestamp
   * @return Returns the due for the `round`;
   */
  function dueOf(uint256 repDate) external view returns (uint256, uint256, uint256) {
    RepaymentRoundInfo storage roundInfo = repaymentRoundInfo[repDate];

    if (roundInfo.debtAmount == 0) return (0, 0, 0);
    return _dueOf(_accrueInterestVirtual(block.timestamp), roundInfo, block.timestamp, repDate);
  }

  function _totalDue()
    internal
    view
    returns (uint256 amount, uint256 penaltyAmount, uint256 feesAmount)
  {
    BorrowInfo memory bInfo = _accrueInterestVirtual(block.timestamp);
    if (_fullRepaymentDate != 0 || bInfo.status == PoolStatus.Default) {
      // If the full repayment was requested calculate due values based on round stored amount up to the current timestamp
      return (bInfo.borrows, bInfo.penaltyAmount, bInfo.feesAmount);
    }

    uint256 currentRepDate = currentRepaymentDate();
    RepaymentRoundInfo storage roundInfo = repaymentRoundInfo[currentRepDate];
    if (roundInfo.debtAmount != 0) {
      (amount, penaltyAmount, feesAmount) = _dueOf(
        bInfo,
        roundInfo,
        block.timestamp,
        currentRepDate
      );

      if (block.timestamp > currentRepDate) {
        // Substract the accrued fees, interest and penalty for lenders requested repayment
        bInfo.feesAmount -= feesAmount;
        bInfo.borrows -= amount;

        (uint256 _amount, , uint256 _fees) = _accrueToRepaymentDate(
          bInfo,
          currentRepDate + repaymentFrequency
        );
        amount += _amount;
        feesAmount += _fees;
      } else {
        // calculate amount for remaining funds
        uint256 _borrows = roundInfo.debtAmount.mulDecimal(bInfo.exchangeRate);

        // extract penalty from _borrows
        _borrows -= penaltyAmount;

        bInfo.feesAmount -= calcRateAmount(_borrows, bInfo.borrows, bInfo.feesAmount);
        bInfo.borrows -= _borrows;

        /// @dev The virtual interest amount contains accrual for the remaining funds until current repayment date

        (uint256 _amount, , uint256 _fees) = _accrueToRepaymentDate(bInfo, currentRepDate);

        amount += _amount;
        feesAmount += _fees;
      }
      return (amount, bInfo.penaltyAmount, feesAmount);
    }

    // if no withdrawals calculate due up to nearest repayment date (in future)
    return _accrueToRepaymentDate(bInfo, currentRepDate);
  }

  function _accrueToRepaymentDate(
    BorrowInfo memory bInfo,
    uint256 repDate
  ) internal view returns (uint256, uint256, uint256) {
    // get period
    uint256 deltaPeriod = 0;
    if (repDate > block.timestamp) {
      deltaPeriod = repDate - block.timestamp;
    }
    // calculate due up to nearest repayment date (in future)
    bInfo.feesAmount += bInfo.borrows.mulDecimal(calcDeltaRate(deltaPeriod, protocolFee));
    bInfo.borrows += bInfo.borrows.mulDecimal(calcDeltaRate(deltaPeriod, lendAPR));

    return (bInfo.borrows, bInfo.penaltyAmount, bInfo.feesAmount);
  }

  function _dueOf(
    BorrowInfo memory bInfo,
    RepaymentRoundInfo memory info,
    uint256 timestamp,
    uint256 repaymentDate
  ) internal view returns (uint256 amount, uint256 penaltyAmount, uint256 feesAmount) {
    if (timestamp > repaymentDate) {
      // calculate total interest that contains penalty interest + additional interest;
      amount = info.debtAmount.mulDecimal(bInfo.exchangeRate);

      // calculate amount penalty in case the timestamp is above repayment date
      penaltyAmount =
        amount -
        calcRateAmount(amount, bInfo.borrows + bInfo.penaltyAmount, bInfo.borrows);

      // substract the penalty interest from the calculated amount
      amount -= penaltyAmount;
      feesAmount = calcRateAmount(amount, bInfo.borrows, bInfo.feesAmount);
    } else {
      // calculate accrued fees for the specific amount up to current repayment date
      (amount, penaltyAmount, feesAmount) = accrueAmounts(
        bInfo.borrows,
        bInfo.feesAmount,
        bInfo.penaltyAmount,
        info.debtAmount,
        totalSupply(),
        calcDeltaRate(repaymentDate - timestamp, lendAPR),
        calcDeltaRate(repaymentDate - timestamp, protocolFee)
      );
    }
    return (amount, penaltyAmount, feesAmount);
  }

  /**
   * @notice Used to check if the account is passed KYC
   * @param _account The wallet address of the account
   */
  function checkKycStatus(address _account) public {
    if (isKycRequired) {
      poolFactory.checkKycStatus(_account);
    }
  }

  /**
   * @notice Function is called through Factory to withdraw reward for some user
   * @param _asset The address of reward asset
   * @param account Account to withdraw reward for
   * @return withdrawable amount
   */
  function withdrawReward(
    address _asset,
    address account
  ) external onlyPoolFactory onlyEligible(account) returns (uint256) {
    accrueInterest();
    _accrueReward();
    (, uint256 _withdrawable) = accumulativeRewardOf(_asset, account);
    if (_withdrawable > 0) {
      rewardAssetInfo.updateRewardWithdrawals(_asset, account, _withdrawable);
      emit RewardWithdrawn(_asset, _withdrawable);
    }

    return _withdrawable;
  }

  /**
   * @notice Returns the accumulated reward of specific reward asset for the given account
   * @dev Returns the accumulated reward in 18 decimal places
   * @param _rewardAsset The address of reward asset
   * @param account The address of the user
   * @return accumulated accumulated rewards of the specific reward asset for the given account
   * @return withdrawable withdrawble part of the reward for the given account
   */
  function accumulativeRewardOf(
    address _rewardAsset,
    address account
  ) public view returns (uint256 accumulated, uint256 withdrawable) {
    accumulated = _accumulativeRewardOf(_rewardAsset, account);
    withdrawable = accumulated - rewardAssetInfo.rewardWithdrawals[_rewardAsset][account];
  }

  function _accumulativeRewardOf(
    address _rewardAsset,
    address account
  ) internal view returns (uint256) {
    uint256 currentTime = _accrueInterestVirtual(block.timestamp).lastAccrual;
    uint256 currentRewardPerShare = rewardAssetInfo.magnifiedRewardPerShare[_rewardAsset];
    uint256 index = rewardAssetInfo.addressIndex[_rewardAsset];
    uint256 rate = rewardAssetInfo.rewardAssetData[index].rate;
    if (
      totalSupply() != 0 &&
      rewardAssetInfo.lastRewardDistribution != 0 &&
      currentTime > rewardAssetInfo.lastRewardDistribution &&
      rate != 0
    ) {
      uint256 period = currentTime - rewardAssetInfo.lastRewardDistribution;
      currentRewardPerShare += (REWARD_MAGNITUDE * period * rate) / totalSupply();
    }
    return
      ((balanceOf(account) * currentRewardPerShare).toInt256() +
        rewardAssetInfo.magnifiedRewardCorrections[_rewardAsset][account]).toUint256() /
      REWARD_MAGNITUDE;
  }

  /**
   * @notice accrue reward
   */
  function _accrueReward() internal {
    // get reward assets array
    uint256 currentTime = _info.lastAccrual;
    if (
      totalSupply() != 0 &&
      rewardAssetInfo.lastRewardDistribution != 0 &&
      currentTime > rewardAssetInfo.lastRewardDistribution
    ) {
      RewardAsset.RewardAssetData[] memory _rewardAsset = getRewardAssetInfo();
      for (uint256 i; i < _rewardAsset.length; i++) {
        if (_rewardAsset[i].rate != 0) {
          rewardAssetInfo.updateMagnifiedRewardPerShare(
            _rewardAsset[i].asset,
            currentTime - rewardAssetInfo.lastRewardDistribution,
            _rewardAsset[i].rate,
            REWARD_MAGNITUDE,
            totalSupply()
          );
        }
      }
    }
    rewardAssetInfo.lastRewardDistribution = currentTime;
  }

  /**
   * @notice accrue round bond reward
   * @dev A round can incorporate multiple bonds
   */
  function _accrueRoundReward(uint256 roundDate) internal {
    RepaymentRoundInfo storage roundInfo = repaymentRoundInfo[roundDate];

    uint256 bondId = roundInfo.bondTokenId;
    uint256 lastDistribution = rewardAssetInfo.roundLastDistribution[bondId];
    if (totalSupply() != 0 && block.timestamp > lastDistribution && roundInfo.debtAmount > 0) {
      RewardAsset.RewardAssetData[] memory _rewardAsset = getRewardAssetInfo();
      // update round reward per share accumulated since first request
      for (uint256 i; i < _rewardAsset.length; i++) {
        rewardAssetInfo.updateMagnifiedRoundRewardPerShare(
          _rewardAsset[i].asset,
          bondId,
          block.timestamp - lastDistribution,
          _rewardAsset[i].rate,
          REWARD_MAGNITUDE,
          totalSupply()
        );
      }
      rewardAssetInfo.roundLastDistribution[bondId] = block.timestamp;
    }
  }

  /**
   * @notice Used to change repayment frequency;
   * @dev The minimal repayment frequency is one day.
   * @param _newRepaymentFrequency The new repayment frequency to be set;
   */
  function changeRepaymentFrequency(
    uint256 _newRepaymentFrequency
  ) external onlyBorrower onlyActive {
    if (_newRepaymentFrequency < 1 days || _unpaidRounds == 2) revert ActionNotAllowed();
    // Unable to increase repayment frequency if pool is active;
    if (_newRepaymentFrequency > repaymentFrequency && _currentRepaymentDate != 0)
      revert PoolHasLiquidity();
    repaymentFrequency = _newRepaymentFrequency;
    emit RepaymentFrequencyChanged(_newRepaymentFrequency);
  }

  /**
   * @notice Is used to either decrease or increase deposit capacity;
   * @param _newDepositCap  the deposit capacity to be set;
   */
  function changeDepositCapacity(uint256 _newDepositCap) external onlyBorrower onlyActive {
    depositCap = _newDepositCap;
    emit DepositCapChanged(_newDepositCap);
  }

  /**
   * @notice Is used to change minimum deposit amount;
   * @param _newMinDeposit the min deposit about to be set;
   */
  function changeMinDeposit(uint256 _newMinDeposit) external onlyBorrower onlyActive {
    // Disallow values higher then current deposit cap in case there is
    if (depositCap > 0 && _newMinDeposit > depositCap) revert MinDepositExceedCap();
    minDeposit = _newMinDeposit;
    emit MinDepositChanged(_newMinDeposit);
  }

  /**
   * @notice Setting less period of the pool, the period can be 0;
   * @dev Change `minimumNoticePeriod` in this pool;
   */
  function changeNoticePeriod(uint256 _newNoticePeriod) external onlyBorrower onlyActive {
    // After the pool is created the notice period cannot be increased
    if (_newNoticePeriod > minimumNoticePeriod || _unpaidRounds == 2) revert ActionNotAllowed();

    minimumNoticePeriod = _newNoticePeriod;
    emit NoticePeriodChanged(_newNoticePeriod);
  }

  /**
   * @notice Used to change pool protocol fee
   * @dev Only called by governor
   * @param _newProtocolFee New Protocol fee to be set
   */
  function changePoolProtocolFee(uint256 _newProtocolFee) external onlyGovernor onlyActive {
    if (_newProtocolFee == 0 || _newProtocolFee > 1e18) revert WrongNumber();

    protocolFee = _newProtocolFee;
  }

  /**
   * @notice used to set a period to start auction
   * @param period the new start auction period
   */
  function setPeriodToStartAuction(uint256 period) external onlyGovernor {
    if (period == 0) revert WrongNumber();

    periodToStartAuction = period;
  }

  /**
   * @notice Used to change pool borrower address
   * @dev Only called by pool factory
   * @param _newBorrower The address of the new borrower
   */
  function changeBorrower(address _newBorrower) external onlyPoolFactory {
    borrower = _newBorrower;
    emit BorrowerChanged(_newBorrower);
  }

  /**
   * @notice Used to set the reward asset and rating
   * @dev Only called by owner(governor)
   * @param _asset The address of reward asset to be set
   * @param _rate The reward rate per sec to be set;
   */
  function setRewardAssetInfo(
    address _asset,
    uint256 _rate
  ) external onlyGovernor nonZeroAddress(_asset) {
    accrueInterest();
    _accrueReward();

    _accrueRoundReward(currentRepaymentDate());
    _accrueRoundReward(_getNextUnpaidRound(false));

    bool success = rewardAssetInfo.insert(_asset, _rate);
    if (!success) revert RequestFailed();
    emit RewardAssetInfoSet(_asset, _rate);
  }

  /**
   * @notice Change lending APR percentage
   * @dev Function can change lending APR;
   */
  function changeAPR(
    uint256 _newAPR
  ) external onlyActive onlyBorrower nonSameValue(_newAPR, lendAPR) {
    if (_newAPR == 0) revert WrongNumber();

    // if current repayment date is zero or no supplies yet the decrease apr request is applied immediately
    uint256 applyDate = currentRepaymentDate();
    if (_newAPR > lendAPR || applyDate == 0) {
      // in case an increase request is submitted, the change is applied immediately.
      lendAPR = _newAPR;

      // remove the old request
      _aprChanges[_lastRequestIndex] = 0;
      emit APRChanged(_newAPR);
    } else {
      if (minimumNoticePeriod == 0) applyDate += repaymentFrequency;
      // APR decrease change is applied in the upcoming repayment after 2 notice periods
      while (block.timestamp + 2 * minimumNoticePeriod > applyDate) {
        applyDate += repaymentFrequency;
      }
      _aprChanges[applyDate] = _newAPR;
      _lastRequestIndex = applyDate;
      emit APRChangeRequested(_newAPR, applyDate);
    }
  }

  /**
   * @notice Used to set the pool status to `Default`;
   * @dev Only called by the governor;
   */
  function forceDefault() external onlyGovernor onlyActive {
    _info.status = PoolStatus.Default;
    emit Defaulted();
  }

  /**
   * @notice Function is called by Auction contract when auction is started
   */
  function processAuctionStart() external onlyPoolFactory {
    accrueInterest();
    isAuctionStarted = true;
  }

  /**
   * @notice used to cancel unstarted auction
   */
  function cancelAuction() external {
    accrueInterest();

    bool periodToStartPassed = block.timestamp >= _info.lastAccrual + periodToStartAuction;
    if (_info.status == PoolStatus.Default && !isAuctionStarted && periodToStartPassed) {
      _processAuctionResolution(0);
    } else {
      revert ActionNotAllowed();
    }
  }

  /**
   * @notice Function is called by Auction contract to process pool debt claim
   * @param _payedAmount The total amount obtained after auction resolution
   * @dev Closes pool after auction ends, regardless of auction result
   */
  function processDebtClaim(uint256 _payedAmount) external onlyPoolFactory {
    return _processAuctionResolution(_payedAmount);
  }

  /**
   * @dev Return the `decimals` of this ERC20 standard;
   */
  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Function to get current pool `status`;
   * @return Pool `status` as state `enumerable`;
   */
  function status() external view returns (PoolStatus) {
    return _status(_accrueInterestVirtual(block.timestamp));
  }

  function cash() public view returns (uint256) {
    return asset.balanceOf(address(this));
  }

  /**
   * @notice Pool Size == Total Borrows == Borrower Balance;
   * @return Returns total borrowed amount for all `lenders`;
   */
  function poolSize() public view returns (uint256) {
    BorrowInfo memory bInfo = _accrueInterestVirtual(block.timestamp);
    return bInfo.borrows + bInfo.penaltyAmount;
  }

  /**
   * @notice Returns the array of reward asset info;
   */
  function getRewardAssetInfo() public view returns (RewardAsset.RewardAssetData[] memory) {
    return rewardAssetInfo.getList();
  }

  /**
   * @dev Used to calculate the exchange rate;
   * @return Returns the current exchange rate;
   */
  function exchangeRate() external view returns (uint256) {
    return _accrueInterestVirtual(block.timestamp).exchangeRate;
  }

  /**
   * @dev Used to calculate the current unpaid repayment date;
   * @return newRepaymentDate Returns the current unpaid repayment date;
   */
  function currentRepaymentDate() public view returns (uint256 newRepaymentDate) {
    newRepaymentDate = _currentRepaymentDate;

    if (newRepaymentDate == 0) return 0;

    // in case the full repayment is requested return it
    if (_fullRepaymentDate != 0 && (_fullRepaymentDate < newRepaymentDate || _unpaidRounds == 0))
      return _fullRepaymentDate;

    // in case the stored repayment date is unpaid return it
    if (repaymentRoundInfo[newRepaymentDate].debtAmount > 0) {
      return newRepaymentDate;
    }

    // get the new repayment date, by iterate over repayment frequency periods
    while (block.timestamp > newRepaymentDate) {
      newRepaymentDate += repaymentFrequency;
      if (repaymentRoundInfo[newRepaymentDate].debtAmount > 0) break;
    }
  }

  /**
   * @dev Used to calculate the next repayment date used for request withdrawals;
   * @return nextRepDate the next repayment date;
   */
  function getNextRepaymentDate() public view returns (uint256 nextRepDate) {
    nextRepDate = currentRepaymentDate();
    if (nextRepDate == 0) return 0;

    // In case the notice period is zero or less than the remaining time until repayment date, assign new repayment round date
    if (minimumNoticePeriod == 0 || (block.timestamp + minimumNoticePeriod > nextRepDate)) {
      while (block.timestamp + minimumNoticePeriod > nextRepDate) {
        nextRepDate += repaymentFrequency;
      }
    }
  }

  // ------- Internal functions -------------- //

  function _getNextUnpaidRound(bool checkCurrentRound) internal view returns (uint256 nextRepDate) {
    nextRepDate = currentRepaymentDate();

    if (checkCurrentRound && repaymentRoundInfo[nextRepDate].debtAmount > 0) {
      return nextRepDate;
    }

    while (block.timestamp + minimumNoticePeriod > nextRepDate) {
      nextRepDate += repaymentFrequency;
      if (repaymentRoundInfo[nextRepDate].debtAmount > 0) break;
    }
  }

  /**
   * @dev Function to get current pool `status`;
   * @notice Compare variables for set `status`;
   *  {debt} - amount of the debt;
   *  {overdue} - time of the overdue;
   * @return Pool `status` as state `enumerable`;
   *  {PoolStatus.Overdue} - if there are overdue repayments;
   *  {PoolStatus.Default} - if the pool is in default state;
   *  {PoolStatus.Closed} - if the pool is closed;
   */
  function _status(BorrowInfo memory info) internal view returns (PoolStatus) {
    if (info.status == PoolStatus.Closed || info.status == PoolStatus.Default) {
      return info.status;
    }

    uint256 currentRepDate = currentRepaymentDate();
    if (
      block.timestamp > currentRepDate &&
      block.timestamp < currentRepDate + gracePeriod &&
      (repaymentRoundInfo[currentRepDate].debtAmount > 0 || _fullRepaymentDate != 0)
    ) {
      return PoolStatus.Overdue;
    }
    return info.status;
  }

  function accrueInterest() public {
    // apply new APR in case it is requested
    if (_aprChanges[_lastRequestIndex] != 0 && block.timestamp > _lastRequestIndex) {
      // calculate exchange rate with the old apr until prev repayment date
      _info = _accrueInterestVirtual(_lastRequestIndex);

      uint256 newAPR = _aprChanges[_lastRequestIndex];
      _aprChanges[_lastRequestIndex] = 0;
      lendAPR = newAPR;
      emit APRChanged(newAPR);
    }
    // accrue interest up to current timestamp
    _info = _accrueInterestVirtual(block.timestamp);
  }

  function _accrueInterestVirtual(
    uint256 timestamp
  ) internal view returns (BorrowInfo memory newInfo) {
    /// @dev Read info from storage to memory
    newInfo = _info;

    /// @dev If last accrual was at current block or pool is closed or in default, return info as is
    if (
      timestamp < newInfo.lastAccrual ||
      newInfo.status == PoolStatus.Default ||
      newInfo.status == PoolStatus.Closed
    ) {
      return newInfo;
    }
    newInfo.overdueEntrance = _overdueEntrance();
    uint256 lastAccrual = timestamp;
    // in case current timestamp is in overdue period, calculate the interest until the pool entered in overdue period
    if (newInfo.overdueEntrance != 0 && newInfo.overdueEntrance < lastAccrual) {
      newInfo = _accrueInterestVirtual(newInfo.overdueEntrance);
    }

    if (totalSupply() != 0) {
      uint256 penaltyPeriod = 0;

      // if the pool is in overdue period calculate penalty period
      if (newInfo.overdueEntrance != 0 && newInfo.overdueEntrance < lastAccrual) {
        penaltyPeriod = lastAccrual - newInfo.lastAccrual;
      }

      // check for default state
      if (newInfo.overdueEntrance != 0 && timestamp > newInfo.overdueEntrance + gracePeriod) {
        lastAccrual = newInfo.overdueEntrance + gracePeriod;
        penaltyPeriod = lastAccrual - newInfo.lastAccrual;
        newInfo.status = PoolStatus.Default;
      }

      uint256 timeDelta = lastAccrual - newInfo.lastAccrual;

      // calculate interest and penalty for the time period
      uint256 borrowsDelta = calcDeltaRate(timeDelta, lendAPR);
      uint256 feesDelta = calcDeltaRate(timeDelta, protocolFee);
      uint256 penaltyDelta = calcDeltaRate(penaltyPeriod, penaltyRate);

      // calc borrows, penalty and fees for borrows amount (compounding)
      newInfo.penaltyAmount += newInfo.borrows.mulDecimal(penaltyDelta);
      newInfo.feesAmount += newInfo.borrows.mulDecimal(feesDelta);
      newInfo.borrows += newInfo.borrows.mulDecimal(borrowsDelta);

      // Calculate new exchange rate  borrows + penalty + cash / totalSupply
      newInfo.exchangeRate = (newInfo.borrows + newInfo.penaltyAmount).divDecimal(totalSupply());
    }
    newInfo.lastAccrual = lastAccrual;
  }

  function _overdueEntrance() internal view returns (uint256) {
    // if the pool is already in overdue period return the entering date
    if (_info.overdueEntrance != 0) {
      return _info.overdueEntrance;
    }

    uint256 repDate = currentRepaymentDate();
    // if the current timestamp pass the repayment date return the entering date
    if (
      block.timestamp > repDate &&
      (repaymentRoundInfo[repDate].debtAmount > 0 || _fullRepaymentDate != 0)
    ) {
      return repDate;
    }
    return 0;
  }

  function _processAuctionResolution(uint256 _payedAmount) internal {
    /// @dev Calculate new exchange rate based on the amount obtained for the auction
    _info.exchangeRate = _payedAmount.divDecimal(
      (_info.borrows + _info.penaltyAmount).divDecimal(_info.exchangeRate)
    );
    _info.borrows = 0;
    _info.penaltyAmount = 0;
    _fullRepaymentDate = 0;

    uint256 currentRepDate = currentRepaymentDate();

    // Mark the current repayment date as paid (the period that causes default -> Auction)
    if (repaymentRoundInfo[currentRepDate].debtAmount > 0) {
      // Accrue rewards interest for the current round
      _accrueRoundReward(currentRepDate);

      repaymentRoundInfo[currentRepDate].debtAmount = 0;
      repaymentRoundInfo[currentRepDate].paidAt = _info.lastAccrual;
      repaymentRoundInfo[currentRepDate].exchangeRate = _info.exchangeRate;
    }

    uint256 nextRepDate = _getNextUnpaidRound(true);
    // Mark the future repayment date as paid (in case exists)
    if (repaymentRoundInfo[nextRepDate].debtAmount > 0) {
      // Accrue rewards interest for the next round
      _accrueRoundReward(nextRepDate);

      repaymentRoundInfo[nextRepDate].paidAt = _info.lastAccrual;
      repaymentRoundInfo[nextRepDate].exchangeRate = _info.exchangeRate;
    }

    // burn all locked tokens obtained during withdrawal requests
    _burn(address(this), balanceOf(address(this)));

    _closePool();
  }

  /*
   * @dev {see ERC20 _beforeTokenTransfer}
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override onlyEligible(to) {
    super._beforeTokenTransfer(from, to, amount);
  }

  /**
   * @notice Override of mint function with rewards corrections
   * @param account Account to mint for
   * @param amount Amount to mint
   */
  function _mint(address account, uint256 amount) internal override {
    _accrueReward();
    _accrueRoundReward(currentRepaymentDate());
    _accrueRoundReward(_getNextUnpaidRound(false));

    RewardAsset.RewardAssetData[] memory _rewardAsset = getRewardAssetInfo();
    for (uint256 i; i < _rewardAsset.length; i++) {
      rewardAssetInfo.decreaseRewardCorrection(_rewardAsset[i].asset, account, amount);
    }
    super._mint(account, amount);
  }

  /**
   * @notice Override of burn function with rewards corrections
   * @param account Account to burn from
   * @param amount Amount to burn
   */
  function _burn(address account, uint256 amount) internal override {
    _accrueReward();

    RewardAsset.RewardAssetData[] memory _rewardAsset = getRewardAssetInfo();
    for (uint256 i; i < _rewardAsset.length; i++) {
      rewardAssetInfo.increaseRewardCorrection(_rewardAsset[i].asset, account, amount);
    }
    super._burn(account, amount);
  }

  /**
   * @notice Override of transfer function with rewards corrections
   * @param from Account to transfer from
   * @param to Account to transfer to
   * @param amount Amount to transfer
   */
  function _transfer(address from, address to, uint256 amount) internal override {
    accrueInterest();
    _accrueReward();

    RewardAsset.RewardAssetData[] memory _rewardAsset = getRewardAssetInfo();
    for (uint256 i; i < _rewardAsset.length; i++) {
      address rewardAssetAddr = _rewardAsset[i].asset;
      rewardAssetInfo.increaseRewardCorrection(rewardAssetAddr, from, amount);
      rewardAssetInfo.decreaseRewardCorrection(rewardAssetAddr, to, amount);
    }
    super._transfer(from, to, amount);
  }

  /**
   * @notice Override of bond transfer function with rewards corrections
   * @param roundDate round date
   * @param bondId bond id
   * @param from Account to transfer from
   * @param to Account to transfer to
   * @param amount Amount to transfer
   */
  function applyBondRewardCorections(
    uint256 roundDate,
    uint256 bondId,
    address from,
    address to,
    uint256 amount
  ) external {
    if (msg.sender != address(bondNFT)) revert ActionNotAllowed();

    _accrueRoundReward(roundDate);
    RewardAsset.RewardAssetData[] memory _rewardAsset = getRewardAssetInfo();
    for (uint256 i; i < _rewardAsset.length; i++) {
      address rewardAssetAddr = _rewardAsset[i].asset;
      rewardAssetInfo.increaseRewardCorrection(
        rewardAssetAddr,
        from,
        amount,
        rewardAssetInfo.magnifiedRoundRewardPerShare[bondId][rewardAssetAddr]
      );
      rewardAssetInfo.decreaseRewardCorrection(
        rewardAssetAddr,
        to,
        amount,
        rewardAssetInfo.magnifiedRoundRewardPerShare[bondId][rewardAssetAddr]
      );
    }
  }

  /**
   * @dev Return calculated rate for a specific time period
   */
  function calcDeltaRate(uint256 timeDelta, uint256 rate) private pure returns (uint256) {
    return (rate * timeDelta) / YEAR;
  }

  /**
   * @dev Return rated fees amount for a specific value based on full amount and fees
   */
  function calcRateAmount(
    uint256 amount,
    uint256 fullAmount,
    uint256 feesAmount
  ) private pure returns (uint256) {
    return (amount * feesAmount) / fullAmount;
  }

  /**
   * @dev Return pre-calculated amounts for a specific period
   */
  function accrueAmounts(
    uint256 _borrows,
    uint256 _feesAmount,
    uint256 _penaltyAmount,
    uint256 _amount,
    uint256 _supply,
    uint256 interestDelta,
    uint256 feesDelta
  ) private pure returns (uint256, uint256, uint256) {
    _feesAmount += _borrows.mulDecimal(feesDelta);
    _borrows += _borrows.mulDecimal(interestDelta);

    // New amount + penalty = tokensAmount * exchangeRate (borrows + penalty / totalSupply)
    _amount = _amount.mulDecimal((_borrows + _penaltyAmount).divDecimal(_supply));
    _penaltyAmount = _amount - calcRateAmount(_amount, _borrows + _penaltyAmount, _borrows);

    // substract the penalty interest from the calculated amount
    _amount -= _penaltyAmount;

    return (_amount, _penaltyAmount, calcRateAmount(_amount, _borrows, _feesAmount));
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract UtilsGuard {
  error NonZeroAddress();
  error NonZeroValue();
  error NotSameValue();
  error NotSameAddress();
  error RequestFailed();
  error ActionNotAllowed();
  error InvalidArgument();
  error MinDepositExceedCap();

  uint256 internal constant YEAR = 365 days;

  /// @notice Value by which all rewards are magnified for calculation
  uint256 internal constant REWARD_MAGNITUDE = 2 ** 128;

  modifier nonZeroAddress(address _addr) {
    if (_addr == address(0)) revert NonZeroAddress();
    _;
  }
  modifier nonZeroValue(uint256 _val) {
    if (_val == 0) revert NonZeroValue();
    _;
  }
  modifier nonSameValue(uint256 _val1, uint256 _val2) {
    if (_val1 == _val2) revert NotSameValue();
    _;
  }

  modifier nonSameAddress(address _addr1, address _addr2) {
    if (_addr1 == _addr2) revert NotSameAddress();
    _;
  }

  function toWei(uint256 amount_, uint256 decimals) internal pure returns (uint256) {
    return amount_ * 10 ** (18 - decimals);
  }

  function fromWei(uint256 amount_, uint256 decimals) internal pure returns (uint256) {
    return amount_ / 10 ** (18 - decimals);
  }
}