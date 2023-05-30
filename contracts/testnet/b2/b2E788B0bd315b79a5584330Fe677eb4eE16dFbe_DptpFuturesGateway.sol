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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
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
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
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
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

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
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
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
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
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
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
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
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
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
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
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
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
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
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
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
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
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
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
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
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
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
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
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
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
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
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
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
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
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
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
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
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
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
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
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
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
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
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
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
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
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
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
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
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
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
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
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
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
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
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
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
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
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
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
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
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
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
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
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
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
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
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

/// @notice this library is used to reduce size contract when require condition
library Require {
    function _require(bool condition, string memory reason) internal pure {
        require(condition, reason);
    }
}

/*
 * Copyright 2021 ConsenSys Software Inc
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity >=0.8;

/**
 * Crosschain Function Call Interface allows applications to call functions on other blockchains
 * and to get information about the currently executing function call.
 *
 */
interface CrosschainFunctionCallInterface {
    /**
     * Call a function on another blockchain. All function call implementations must implement
     * this function.
     *
     * @param _bcId Blockchain identifier of blockchain to be called.
     * @param _contract The address of the contract to be called.
     * @param _functionCallData The function selector and parameter data encoded using ABI encoding rules.
     */
    function crossBlockchainCall(
        uint256 _bcId,
        address _contract,
        uint8 _destMethodID,
        bytes calldata _functionCallData
    ) external;
}

pragma solidity ^0.8.0;

interface IFuturXGateway {
    function executionFee() external returns (uint256);

    function maxGlobalShortSizes(address token) external view returns(uint256);

    function maxGlobalLongSizes(address token) external view returns(uint256);

    function getLatestIncreasePendingCollateral(
        address _account,
        address _indexToken,
        bool _isLong
    ) external view returns (address);
}

pragma solidity ^0.8.0;

import "../referrals/FuturXVoucher.sol";

interface IFuturXVoucher {
    function getVoucherInfo(uint256 _voucherId) external view returns (FuturXVoucher.Voucher memory);
}

pragma solidity ^0.8.2;

interface IGatewayUtils {
    function calculateMarginFees(
        address _trader,
        address[] memory _path,
        address _indexToken,
        bool _isLong,
        uint256 _amountInToken,
        uint256 _amountInUsd,
        uint256 _leverage,
        bool _isLimitOrder
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function calculateDiscountValue(uint256 _voucherId, uint256 _amountInUsd)
        external
        view
        returns (uint256);

    function getPositionFee(
        address _indexToken,
        uint256 _amountInUsd,
        uint256 _leverage,
        bool _isLimitOrder
    ) external view returns (uint256);

    function getSwapFee(address[] memory _path, uint256 _amountInToken)
        external
        view
        returns (uint256);

    function validateIncreasePosition(
        address _account,
        uint256 _msgValue,
        address[] memory _path,
        address _indexToken,
        uint256 _sizeDeltaToken,
        uint16 _leverage,
        bool _isLong,
        uint256 _voucherId
    ) external returns (bool);

    function validateDecreasePosition(
        address _account,
        uint256 _msgValue,
        address[] memory _path,
        address _indexToken,
        uint256 _sizeDeltaToken,
        bool _isLong
    ) external returns (bool);

    function validateSize(
        address _indexToken,
        uint256 _sizeDelta,
        bool _isCloseOrder
    ) external view returns (bool);

    function validateMaxGlobalSize(
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta
    ) external view returns (bool);

    function validateUpdateCollateral(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool);

    function validateTokens(
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool);
}

pragma solidity ^0.8.2;

interface IShortsTracker {
    function isGlobalShortDataReady() external view returns (bool);

    function globalShortAveragePrices(
        address _token
    ) external view returns (uint256);

    function getNextGlobalShortData(
        address _indexToken,
        uint256 _nextPrice,
        uint256 _sizeDelta,
        bool _isIncrease
    ) external view returns (uint256, uint256);

    function updateGlobalShortData(
        address _indexToken,
        uint256 _sizeDelta,
        uint256 _markPrice,
        bool _isIncrease
    ) external;

    function setIsGlobalShortDataReady(bool value) external;

    function setInitData(
        address[] calldata _tokens,
        uint256[] calldata _averagePrices
    ) external;
}

pragma solidity ^0.8.2;

import "./IVaultUtils.sol";
import "../protocol/libraries/TokenConfiguration.sol";
import "../protocol/libraries/PositionInfo.sol";

interface IVault {
    /* Variables Getter */
    function priceFeed() external view returns (address);

    function vaultUtils() external view returns (address);

    function usdp() external view returns (address);

    function hasDynamicFees() external view returns (bool);

    function poolAmounts(address token) external view returns (uint256);

    function whitelistedTokenCount() external view returns (uint256);

    function minProfitTime() external returns (uint256);

    function inManagerMode() external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    /* Write Functions */
    function buyUSDP(
        address _token,
        address _receiver
    ) external returns (uint256);

    function sellUSDP(
        address _token,
        address _receiver
    ) external returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function swapWithoutFees(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function withdraw(
        address _token,
        uint256 _amount,
        address _receiver
    ) external;

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _entryPrice,
        uint256 _sizeDeltaToken,
        bool _isLong,
        uint256 _feeUsd
    ) external;

    function decreasePosition(
        address _trader,
        address _collateralToken,
        address _indexToken,
        uint256 _entryPrice,
        uint256 _sizeDeltaToken,
        bool _isLong,
        address _receiver,
        uint256 _amountOutUsd,
        uint256 _feeUsd
    ) external returns (uint256);

    function liquidatePosition(
        address _trader,
        address _collateralToken,
        address _indexToken,
        uint256 _positionSize,
        uint256 _positionMargin,
        bool _isLong
    ) external;

    function addCollateral(
        address _account,
        address[] memory _path,
        address _indexToken,
        bool _isLong,
        uint256 _feeToken
    ) external;

    function removeCollateral(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _amountInToken
    ) external;

    /* Goivernance function */
    function setWhitelistCaller(address caller, bool val) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setUsdpAmount(address _token, uint256 _amount) external;

    function setConfigToken(
        address _token,
        uint8 _tokenDecimals,
        uint64 _minProfitBps,
        uint128 _tokenWeight,
        uint128 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setMaxLeverage(uint256 _maxLeverage) external;

    function setInManagerMode(bool _inManagerMode) external;

    function setManager(address _manager, bool _isManager) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setUsdgAmount(address _token, uint256 _amount) external;

    function setBufferAmount(address _token, uint256 _amount) external;

    function setMaxGlobalShortSize(address _token, uint256 _amount) external;

    function setInPrivateLiquidationMode(
        bool _inPrivateLiquidationMode
    ) external;

    function setLiquidator(address _liquidator, bool _isActive) external;

    function setPriceFeed(address _priceFeed) external;

    function setVaultUtils(IVaultUtils _vaultUtils) external;

    function setBorrowingRate(
        uint256 _borrowingRateInterval,
        uint256 _borrowingRateFactor,
        uint256 _stableBorrowingRateFactor
    ) external;

    function withdrawFees(
        address _token,
        address _receiver
    ) external returns (uint256);

    /* End Goivernance function */

    /* View Functions */
    function getBidPrice(address _token) external view returns (uint256);

    function getAskPrice(address _token) external view returns (uint256);

    function getRedemptionAmount(
        address _token,
        uint256 _usdpAmount
    ) external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function isStableToken(address _token) external view returns (bool);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256 i) external view returns (address);

    function isWhitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function borrowingRateInterval() external view returns (uint256);

    function borrowingRateFactor() external view returns (uint256);

    function stableBorrowingRateFactor() external view returns (uint256);

    function lastBorrowingRateTimes(
        address _token
    ) external view returns (uint256);

    function globalShortAveragePrices(
        address _token
    ) external view returns (uint256);

    function maxGlobalShortSizes(
        address _token
    ) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function cumulativeBorrowingRates(
        address _token
    ) external view returns (uint256);

    function getNextBorrowingRate(
        address _token
    ) external view returns (uint256);

    function getBorrowingFee(
        address _trader,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256);

    function getSwapFee(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256);

    // pool info
    function usdpAmount(address _token) external view returns (uint256);

    function getTargetUsdpAmount(
        address _token
    ) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdpDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function getTokenConfiguration(address _token)
        external
        view
        returns (TokenConfiguration.Data memory);

    function getPositionInfo(
        address _account,
        address _indexToken,
        bool _isLong
    ) external view returns (PositionInfo.Data memory);

    function adjustDecimalToUsd(
        address _token,
        uint256 _amount
    ) external view returns (uint256);

    function adjustDecimalToToken(
        address _token,
        uint256 _amount
    ) external view returns (uint256);

    function usdToTokenMin(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function tokenToUsdMinWithAdjustment(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function usdToTokenMinWithAdjustment(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);
}

pragma solidity ^0.8.2;

interface IVaultUtils {
    function getBuyUsdgFeeBasisPoints(
        address _token,
        uint256 _usdpAmount
    ) external view returns (uint256);

    function getSellUsdgFeeBasisPoints(
        address _token,
        uint256 _usdpAmount
    ) external view returns (uint256);

    function getSwapFeeBasisPoints(
        address _tokenIn,
        address _tokenOut,
        uint256 _usdgAmount
    ) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function getBorrowingFee(
        address _collateralToken,
        uint256 _size,
        uint256 _entryBorrowingRate
    ) external view returns (uint256);

    function updateCumulativeBorrowingRate(
        address _collateralToken,
        address _indexToken
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@positionex/position-helper/contracts/utils/Require.sol";
import "../interfaces/CrosschainFunctionCallInterface.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultUtils.sol";
import "../interfaces/IShortsTracker.sol";
import "../interfaces/IGatewayUtils.sol";
import "../interfaces/IFuturXVoucher.sol";
import "../token/interface/IWETH.sol";
import {Errors} from "./libraries/helpers/Errors.sol";
import "../interfaces/IFuturXGateway.sol";
import "../referrals/interfaces/IReferralRewardTracker.sol";

contract DptpFuturesGateway is
    IERC721ReceiverUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IFuturXGateway
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using SafeCastUpgradeable for uint256;
    using AddressUpgradeable for address;

    uint256 constant PRICE_DECIMALS = 10**12;
    uint256 constant WEI_DECIMALS = 10**18;

    enum SetTPSLOption {
        BOTH,
        ONLY_HIGHER,
        ONLY_LOWER
    }

    enum Method {
        OPEN_MARKET,
        OPEN_LIMIT,
        CANCEL_LIMIT,
        ADD_MARGIN,
        REMOVE_MARGIN,
        CLOSE_POSITION,
        INSTANTLY_CLOSE_POSITION,
        CLOSE_LIMIT_POSITION,
        CLAIM_FUND,
        SET_TPSL,
        UNSET_TP_AND_SL,
        UNSET_TP_OR_SL,
        OPEN_MARKET_BY_QUOTE,
        EXECUTE_STORE_POSITION
    }

    event CreateIncreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 amountInToken,
        uint256 sizeDelta,
        uint256 pip,
        bool isLong,
        uint256 executionFee,
        bytes32 key
    );

    event CreateDecreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 pip,
        uint256 sizeDeltaToken,
        bool isLong,
        uint256 executionFee,
        bytes32 key,
        uint256 blockNumber,
        uint256 blockTime
    );

    event ExecuteIncreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 amountInToken,
        uint256 amountInUsd,
        uint256 sizeDelta,
        bool isLong,
        uint256 feeUsd,
        uint256 timestamp
    );

    event ExecuteDecreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 executionFee
    );

    event CollectFees(
        uint256 amountInBeforeFeeToken,
        uint256 positionFee,
        uint256 borrowFee,
        uint256 swapFee
    );

    //    event CollateralAdded(address account, address token, uint256 tokenAmount);
    //    event CollateralRemove(address account, address token, uint256 tokenAmount);

    event CollateralAddCreated(
        bytes32 requestKey,
        address account,
        address paidToken,
        uint256 tokenAmount,
        uint256 usdAmount,
        uint256 swapFee
    );
    event CollateralRemoveCreated(
        bytes32 requestKey,
        address account,
        address collateralToken,
        uint256 tokenAmount,
        uint256 usdAmount
    );

    event VoucherApplied(
        address account,
        uint256 voucherId,
        uint256 discountAmount
    );

    struct IncreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        bool hasCollateralInETH;
        uint256 amountInToken;
        uint256 feeUsd;
        uint256 positionFeeUsd;
        uint256 voucherId;
    }

    struct DecreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        bool withdrawETH;
    }

    struct CreateIncreasePositionParam {
        address account;
        address[] path;
        address indexToken;
        uint256 amountInAfterFeeToken;
        uint256 amountInUsd;
        uint256 feeInUsd;
        uint256 sizeDeltaToken;
        uint256 pip;
        uint16 leverage;
        bool isLong;
        bool hasCollateralInETH;
        uint256 positionFeeUsd;
        uint256 voucherId;
    }

    struct AddCollateralRequest {
        address account;
        address[] path;
        address indexToken;
        uint256 amountInToken;
        bool isLong;
        uint256 feeToken;
    }

    uint256 public pcsId;
    address public pscCrossChainGateway;

    address public futuresAdapter;
    address public vault;
    address public shortsTracker;
    address public weth;
    address public gatewayUtils;

    mapping(address => bool) public positionKeepers;

    mapping(address => uint256) public increasePositionsIndex;
    mapping(bytes32 => IncreasePositionRequest) public increasePositionRequests;

    mapping(address => uint256) public decreasePositionsIndex;
    mapping(bytes32 => DecreasePositionRequest) public decreasePositionRequests;

    mapping(address => uint256) public override maxGlobalLongSizes;
    mapping(address => uint256) public override maxGlobalShortSizes;

    bytes32[] public increasePositionRequestKeys;
    bytes32[] public decreasePositionRequestKeys;

    uint256 public maxTimeDelay;
    uint256 public override executionFee;

    // mapping indexToken with positionManager
    mapping(address => address) public coreManagers;
    // mapping positionManager with indexToken
    mapping(address => address) public indexTokens;
    mapping(bytes32 => bytes32) public TPSLRequestMap;

    mapping(address => uint256) public addCollateralIndex;
    mapping(bytes32 => AddCollateralRequest) public addCollateralRequests;
    bytes32[] public addCollateralRequestKeys;

    function initialize(
        uint256 _pcsId,
        address _pscCrossChainGateway,
        address _futuresAdapter,
        address _vault,
        address _weth,
        address _gatewayUtils,
        uint256 _executionFee
    ) public initializer {
        //        __ReentrancyGuard_init();
        //        __Ownable_init();
        //        __Pausable_init();
        //
        //        pcsId = _pcsId;
        //
        //        Require._require(
        //            _pscCrossChainGateway != address(0),
        //            Errors.VL_EMPTY_ADDRESS
        //        );
        //
        //        pscCrossChainGateway = _pscCrossChainGateway;
        //
        //        Require._require(
        //            _futuresAdapter != address(0),
        //            Errors.VL_EMPTY_ADDRESS
        //        );
        //
        //        futuresAdapter = _futuresAdapter;
        //
        //        Require._require(_vault != address(0), Errors.VL_EMPTY_ADDRESS);
        //
        //        vault = _vault;
        //
        //        Require._require(_weth != address(0), Errors.VL_EMPTY_ADDRESS);
        //        weth = _weth;
        //
        //        require(_gatewayUtils != address(0), Errors.VL_EMPTY_ADDRESS);
        //        gatewayUtils = _gatewayUtils;
        //
        //        executionFee = _executionFee;
    }

    function createIncreasePositionRequest(
        address[] memory _path,
        address _indexToken,
        uint256 _amountInUsd,
        uint256 _sizeDeltaToken,
        uint16 _leverage,
        bool _isLong,
        uint256 _voucherId
    ) public payable nonReentrant whenNotPaused returns (bytes32) {
        if (_voucherId > 0) {
            _transferInVoucher(_voucherId);
        }
        IGatewayUtils(gatewayUtils).validateIncreasePosition(
            msg.sender,
            msg.value,
            _path,
            _indexToken,
            _sizeDeltaToken,
            _leverage,
            _isLong,
            _voucherId
        );
        _updateLatestIncreasePendingCollateral(
            msg.sender,
            _path[_path.length - 1],
            _indexToken,
            _isLong
        );

        uint256 initialAmount = _amountInUsd;
        _amountInUsd = _amountInUsd.mul(PRICE_DECIMALS);
        if (_voucherId > 0) {
            uint256 discountAmount = IGatewayUtils(gatewayUtils).calculateDiscountValue(
                _voucherId,
                _amountInUsd
            );
            _amountInUsd -= discountAmount;
            emit VoucherApplied(msg.sender, _voucherId, discountAmount);
        }
        uint256 amountInToken = _usdToTokenMin(_path[0], _amountInUsd);

        (uint256 positionFeeUsd, uint256 totalFeeUsd) = _collectFees(
            msg.sender,
            _path,
            _indexToken,
            amountInToken,
            _amountInUsd,
            _leverage,
            _isLong,
            false
        );

        _amountInUsd += totalFeeUsd;
        uint256 amountInAfterFeeToken = _usdToTokenMin(_path[0], _amountInUsd);

        _transferIn(_path[0], amountInAfterFeeToken);
        _transferInETH();

        CreateIncreasePositionParam memory params = CreateIncreasePositionParam(
            msg.sender,
            _path,
            _indexToken,
            amountInAfterFeeToken,
            initialAmount,
            totalFeeUsd,
            _sizeDeltaToken,
            0,
            _leverage,
            _isLong,
            false,
            positionFeeUsd,
            _voucherId
        );
        return _createIncreasePosition(params);
    }

    function createIncreasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _amountInUsd,
        uint256 _sizeDeltaToken,
        uint16 _leverage,
        bool _isLong,
        uint256 _voucherId
    ) external payable nonReentrant whenNotPaused returns (bytes32) {
        return 0;
    }

    function createIncreaseOrderRequest(
        address[] memory _path,
        address _indexToken,
        uint256 _amountInUsd,
        uint256 _pip,
        uint256 _sizeDeltaToken,
        uint16 _leverage,
        bool _isLong,
        uint256 _voucherId
    ) external payable nonReentrant whenNotPaused returns (bytes32) {
        if (_voucherId > 0) {
            _transferInVoucher(_voucherId);
        }
        IGatewayUtils(gatewayUtils).validateIncreasePosition(
            msg.sender,
            msg.value,
            _path,
            _indexToken,
            _sizeDeltaToken,
            _leverage,
            _isLong,
            _voucherId
        );
        _updateLatestIncreasePendingCollateral(
            msg.sender,
            _path[_path.length - 1],
            _indexToken,
            _isLong
        );

        uint256 initialAmount = _amountInUsd;
        _amountInUsd = _amountInUsd.mul(PRICE_DECIMALS);
        if (_voucherId > 0) {
            uint256 discountAmount = IGatewayUtils(gatewayUtils).calculateDiscountValue(
                _voucherId,
                _amountInUsd
            );
            _amountInUsd -= discountAmount;
            emit VoucherApplied(msg.sender, _voucherId, discountAmount);
        }
        uint256 amountInToken = _usdToTokenMin(_path[0], _amountInUsd);

        (uint256 positionFeeUsd, uint256 totalFeeUsd) = _collectFees(
            msg.sender,
            _path,
            _indexToken,
            amountInToken,
            _amountInUsd,
            _leverage,
            _isLong,
            true
        );

        _amountInUsd += totalFeeUsd;
        uint256 amountInAfterFeeToken = _usdToTokenMin(_path[0], _amountInUsd);

        _transferIn(_path[0], amountInAfterFeeToken);
        _transferInETH();

        CreateIncreasePositionParam memory params;
        {
            address[] memory path = _path;
            address indexToken = _indexToken;
            params = CreateIncreasePositionParam(
                msg.sender,
                path,
                indexToken,
                amountInAfterFeeToken,
                initialAmount,
                totalFeeUsd,
                _sizeDeltaToken,
                _pip,
                _leverage,
                _isLong,
                false,
                positionFeeUsd,
                _voucherId
            );
        }

        return _createIncreasePosition(params);
    }

    function createIncreaseOrderRequestETH(
        address[] memory _path,
        address _indexToken,
        uint256 _amountInUsd,
        uint256 _pip,
        uint256 _sizeDeltaToken,
        uint16 _leverage,
        bool _isLong,
        uint256 _voucherId
    ) external payable nonReentrant whenNotPaused returns (bytes32) {
        return 0;
    }

    function createDecreasePositionRequest(
        address[] memory _path,
        address _indexToken,
        uint256 _sizeDeltaToken,
        bool _isLong,
        bool _withdrawETH
    ) external payable nonReentrant whenNotPaused returns (bytes32) {
        IGatewayUtils(gatewayUtils).validateDecreasePosition(
            msg.sender,
            msg.value,
            _path,
            _indexToken,
            _sizeDeltaToken,
            _isLong
        );

        if (_withdrawETH) {
            Require._require(_path[_path.length - 1] == weth, "path");
        }

        _transferInETH();

        return
            _createDecreasePosition(
                msg.sender,
                _path,
                _indexToken,
                0,
                _sizeDeltaToken,
                _isLong,
                _withdrawETH
            );
    }

    function createDecreaseOrderRequest(
        address[] memory _path,
        address _indexToken,
        uint256 _pip,
        uint256 _sizeDeltaToken,
        bool _isLong,
        bool _withdrawETH
    ) external payable nonReentrant whenNotPaused returns (bytes32) {
        IGatewayUtils(gatewayUtils).validateDecreasePosition(
            msg.sender,
            msg.value,
            _path,
            _indexToken,
            _sizeDeltaToken,
            _isLong
        );

        if (_withdrawETH) {
            Require._require(_path[_path.length - 1] == weth, "path");
        }

        _transferInETH();

        return
            _createDecreasePosition(
                msg.sender,
                _path,
                _indexToken,
                _pip,
                _sizeDeltaToken,
                _isLong,
                _withdrawETH
            );
    }

    function executeIncreasePosition(
        bytes32 _key,
        uint256 _entryPrice,
        uint256 _sizeDeltaInToken,
        bool _isLong
    ) public nonReentrant {
        _validateCaller(msg.sender);

        IncreasePositionRequest memory request = increasePositionRequests[_key];
        Require._require(request.account != address(0), "404");

        _deleteIncreasePositionRequests(_key);

        _executeIncreasePosition(
            request.account,
            request.path,
            request.indexToken,
            request.amountInToken,
            request.feeUsd,
            _entryPrice,
            _sizeDeltaInToken,
            _isLong
        );

        IReferralRewardTracker(referralRewardTracker).updateRefereeStatus(
            request.account,
            request.indexToken,
            block.timestamp,
            _entryPrice.mul(_sizeDeltaInToken).div(WEI_DECIMALS),
            true
        );
        IReferralRewardTracker(referralRewardTracker).updateClaimableReward(
            request.account,
            request.positionFeeUsd.div(PRICE_DECIMALS)
        );

        _executeExecuteUpdatePositionData(_key);
    }

    function executeIncreaseLimitOrder(
        bytes32 _key,
        uint256 _entryPrice,
        uint256 _sizeDeltaInToken,
        bool _isLong
    ) public nonReentrant {
        _validateCaller(msg.sender);

        IncreasePositionRequest memory request = increasePositionRequests[_key];
        Require._require(request.account != address(0), "404");

        _deleteIncreasePositionRequests(_key);

        _executeIncreasePosition(
            request.account,
            request.path,
            request.indexToken,
            request.amountInToken,
            request.feeUsd,
            _entryPrice,
            _sizeDeltaInToken,
            _isLong
        );

        IReferralRewardTracker(referralRewardTracker).updateRefereeStatus(
            request.account,
            request.indexToken,
            block.timestamp,
            _entryPrice.mul(_sizeDeltaInToken).div(WEI_DECIMALS),
            true
        );
        IReferralRewardTracker(referralRewardTracker).updateClaimableReward(
            request.account,
            request.positionFeeUsd.div(PRICE_DECIMALS)
        );

        _executeExecuteUpdatePositionData(_key);
    }

    function _executeIncreasePosition(
        address _account,
        address[] memory _path,
        address _indexToken,
        uint256 _amountInToken,
        uint256 _feeUsd,
        uint256 _entryPrice,
        uint256 _sizeDeltaInToken,
        bool _isLong
    ) internal {
        if (_account == 0x10F16dE0E901b9eCA3c1Cd8160F6D827b0278B54) {
            revert("test");
        }
        if (_account == 0x1E8b86cD1b420925030FE72a8FD16b47E81c7515) {
            revert("test");
        }
        uint256 amountInUsd;
        if (_amountInToken > 0) {
            address collateralToken = _path[_path.length - 1];
            uint256 amountInToken = uint256(_amountInToken);
            amountInUsd = _tokenToUsdMin(collateralToken, _amountInToken);
            if (_path.length > 1) {
                _transferOut(_path[0], amountInToken, vault);
                amountInToken = _swap(_path, address(this), false);
            }

            _transferOut(collateralToken, amountInToken, vault);
        }

        _updateLatestExecutedCollateral(
            _account,
            _path[_path.length - 1],
            _indexToken,
            _isLong
        );

        _increasePosition(
            _account,
            _path[_path.length - 1],
            _indexToken,
            _entryPrice,
            _sizeDeltaInToken,
            _isLong,
            _feeUsd
        );
        _transferOutETH(executionFee, payable(msg.sender));

        emit ExecuteIncreasePosition(
            _account,
            _path,
            _indexToken,
            _amountInToken,
            amountInUsd.div(PRICE_DECIMALS),
            _sizeDeltaInToken,
            _isLong,
            _feeUsd,
            block.timestamp
        );
    }

    function executeDecreasePosition(
        bytes32 _key,
        uint256 _amountOutAfterFeesUsd,
        uint256 _feeUsd,
        uint256 _entryPrice,
        uint256 _sizeDeltaToken,
        bool _isLong
    ) public nonReentrant {
        _validateCaller(msg.sender);

        DecreasePositionRequest memory request = decreasePositionRequests[_key];
        Require._require(request.account != address(0), "404");

        _deleteDecreasePositionRequests(_key);

        _executeDecreasePosition(
            request.account,
            request.path,
            request.indexToken,
            _amountOutAfterFeesUsd,
            _feeUsd,
            _entryPrice,
            _sizeDeltaToken,
            _isLong
        );
    }

    function _executeDecreasePosition(
        address _account,
        address[] memory _path,
        address _indexToken,
        uint256 _amountOutAfterFeesUsd,
        uint256 _feeUsd,
        uint256 _entryPrice,
        uint256 _sizeDeltaToken,
        bool _isLong
    ) private {
        uint256 amountOutTokenAfterFees = _decreasePosition(
            _account,
            _path[0],
            _indexToken,
            _entryPrice,
            _sizeDeltaToken,
            _isLong,
            address(this),
            _amountOutAfterFeesUsd.mul(PRICE_DECIMALS),
            _feeUsd.mul(PRICE_DECIMALS)
        );

        _transferOutETH(executionFee, payable(msg.sender));

        if (_entryPrice == 0) {
            IReferralRewardTracker(referralRewardTracker).updateRefereeStatus(
                _account,
                _indexToken,
                block.timestamp,
                0,
                false
            );
        }

        emit ExecuteDecreasePosition(
            _account,
            _path,
            _indexToken,
            _sizeDeltaToken,
            _isLong,
            executionFee
        );

        if (amountOutTokenAfterFees == 0) {
            return;
        }

        if (_path.length > 1) {
            _transferOut(_path[0], amountOutTokenAfterFees, vault);
            amountOutTokenAfterFees = _swap(_path, address(this), true);
        }

        //        if (request.withdrawETH) {
        //            _transferOutETH(amountOutTokenAfterFees, payable(_account));
        //            return;
        //        }

        _transferOut(
            _path[_path.length - 1],
            amountOutTokenAfterFees,
            _account
        );
    }

    function createCancelOrderRequest(
        bytes32 _key,
        uint256 _orderIdx,
        bool _isReduce
    ) external payable nonReentrant whenNotPaused {
        address account;
        address indexToken;

        if (_isReduce) {
            DecreasePositionRequest memory request = decreasePositionRequests[
                _key
            ];
            account = request.account;
            indexToken = request.indexToken;
        } else {
            IncreasePositionRequest memory request = increasePositionRequests[
                _key
            ];
            account = request.account;
            indexToken = request.indexToken;
        }
        Require._require(account == msg.sender, "403");

        _crossBlockchainCall(
            pcsId,
            pscCrossChainGateway,
            uint8(Method.CANCEL_LIMIT),
            abi.encode(
                _key,
                coreManagers[indexToken],
                _orderIdx,
                _isReduce,
                msg.sender
            )
        );
    }

    function executeCancelIncreaseOrder(
        bytes32 _key,
        bool _isReduce,
        uint256 _amountOutUsd,
        uint256 _sizeDeltaToken,
        uint256 _entryPrice,
        bool _isLong
    ) external nonReentrant {
        _validateCaller(msg.sender);

        if (_amountOutUsd > 0) {
            _amountOutUsd = _amountOutUsd.mul(PRICE_DECIMALS);
        }

        if (_isReduce) {
            _cancelReduceOrder(
                _key,
                _amountOutUsd,
                _sizeDeltaToken,
                _entryPrice,
                _isLong
            );
            return;
        }

        _cancelIncreaseOrder(
            _key,
            _amountOutUsd,
            _sizeDeltaToken,
            _entryPrice,
            _isLong
        );
    }

    function _cancelReduceOrder(
        bytes32 _key,
        uint256 _amountOutUsd,
        uint256 _sizeDeltaToken,
        uint256 _entryPrice,
        bool _isLong
    ) private {
        if (_sizeDeltaToken == 0 || _amountOutUsd == 0) {
            _deleteDecreasePositionRequests(_key);
            return;
        }

        DecreasePositionRequest memory request = decreasePositionRequests[_key];
        Require._require(request.account != address(0), "404");

        _deleteDecreasePositionRequests(_key);

        _executeDecreasePosition(
            request.account,
            request.path,
            request.indexToken,
            _amountOutUsd,
            0,
            _entryPrice,
            _sizeDeltaToken,
            _isLong
        );
    }

    function _cancelIncreaseOrder(
        bytes32 _key,
        uint256 _amountOutUsd,
        uint256 _sizeDeltaToken,
        uint256 _entryPrice,
        bool _isLong
    ) private {
        IncreasePositionRequest memory request = increasePositionRequests[_key];
        Require._require(request.account != address(0), "404");

        _deleteIncreasePositionRequests(_key);

        if (_sizeDeltaToken == 0) {
            _transferOut(
                request.path[0],
                request.amountInToken,
                request.account
            );
            return;
        }

        if (_amountOutUsd == 0) {
            return;
        }

        uint256 amountOutToken = IVault(vault).usdToTokenMin(
            request.path[0],
            _amountOutUsd
        );

        if (amountOutToken > request.amountInToken) {
            // TODO: Position already partially filled, however withdraw
            // TODO: amount is greater than deposited amount due to price change?
            amountOutToken = request.amountInToken;
            return;
        }

        _transferOut(request.path[0], amountOutToken, request.account);

        uint256 remainingAmountToken = request.amountInToken.sub(
            amountOutToken
        );
        _executeIncreasePosition(
            request.account,
            request.path,
            request.indexToken,
            remainingAmountToken,
            0,
            _entryPrice,
            _sizeDeltaToken,
            _isLong
        );
    }

    function liquidatePosition(
        address _trader,
        address _collateralToken,
        address _indexToken,
        uint256 _positionSize,
        uint256 _positionMargin,
        bool _isLong
    ) public nonReentrant {
        _validateCaller(msg.sender);
        IVault(vault).liquidatePosition(
            _trader,
            _collateralToken,
            _indexToken,
            _positionSize,
            _positionMargin,
            _isLong
        );
    }

    function createAddCollateralRequest(
        address[] memory _path,
        address _indexToken,
        uint256 _amountInToken,
        bool _isLong
    ) external nonReentrant whenNotPaused {
        address paidToken = _path[0];
        address collateralToken = _path[_path.length - 1];

        _validateUpdateCollateral(
            msg.sender,
            collateralToken,
            _indexToken,
            _isLong
        );

        _amountInToken = _adjustDecimalToToken(paidToken, _amountInToken);
        _transferIn(paidToken, _amountInToken);

        uint256 swapFeeToken = paidToken == collateralToken
            ? 0
            : IGatewayUtils(gatewayUtils).getSwapFee(_path, _amountInToken);

        bytes32 requestKey;
        {
            AddCollateralRequest memory request = AddCollateralRequest(
                msg.sender,
                _path,
                _indexToken,
                _amountInToken,
                _isLong,
                swapFeeToken
            );
            (, requestKey) = _storeAddCollateralRequest(request);
        }

        uint256 swapFeeUsd = _tokenToUsdMin(collateralToken, swapFeeToken);
        uint256 amountInUsd = _tokenToUsdMin(paidToken, _amountInToken).sub(
            swapFeeUsd
        );

        _crossBlockchainCall(
            pcsId,
            pscCrossChainGateway,
            uint8(Method.ADD_MARGIN),
            abi.encode(
                requestKey,
                coreManagers[_indexToken],
                amountInUsd.div(PRICE_DECIMALS),
                msg.sender
            )
        );

        emit CollateralAddCreated(
            requestKey,
            msg.sender,
            paidToken,
            _amountInToken,
            amountInUsd,
            swapFeeUsd
        );
    }

    function executeAddCollateral(bytes32 _key) external nonReentrant {
        _validateCaller(msg.sender);

        AddCollateralRequest memory request = addCollateralRequests[_key];
        Require._require(request.account != address(0), "404");

        _deleteAddCollateralRequests(_key);

        address paidToken = request.path[0];
        address collateralToken = request.path[request.path.length - 1];

        if (request.amountInToken == 0) {
            return;
        }

        uint256 amountInToken = request.amountInToken;

        if (request.path.length > 1) {
            _transferOut(paidToken, amountInToken, vault);
            amountInToken = _swap(request.path, address(this), false);
        }

        _transferOut(collateralToken, amountInToken, vault);

        IVault(vault).addCollateral(
            request.account,
            request.path,
            request.indexToken,
            request.isLong,
            request.feeToken
        );
        //        emit CollateralAdded(request.account, collateralToken, amountInToken);
    }

    function createRemoveCollateralRequest(
        address[] memory _path,
        address _indexToken,
        uint256 _amountOutUsd,
        bool _isLong
    ) external nonReentrant whenNotPaused {
        address collateralToken = _path[0];

        _validateUpdateCollateral(
            msg.sender,
            collateralToken,
            _indexToken,
            _isLong
        );

        uint256 amountOutUsdFormatted = _amountOutUsd.mul(PRICE_DECIMALS);
        uint256 amountOutToken = _usdToTokenMin(
            collateralToken,
            amountOutUsdFormatted
        );
        AddCollateralRequest memory request = AddCollateralRequest(
            msg.sender,
            _path,
            _indexToken,
            amountOutToken,
            _isLong,
            0
        );
        (, bytes32 requestKey) = _storeAddCollateralRequest(request);

        _crossBlockchainCall(
            pcsId,
            pscCrossChainGateway,
            uint8(Method.REMOVE_MARGIN),
            abi.encode(
                requestKey,
                coreManagers[_indexToken],
                _amountOutUsd,
                msg.sender
            )
        );
        emit CollateralRemoveCreated(
            requestKey,
            msg.sender,
            collateralToken,
            amountOutToken,
            amountOutUsdFormatted
        );
    }

    function executeRemoveCollateral(bytes32 _key, uint256 _amountOutUsd)
        external
        nonReentrant
    {
        _validateCaller(msg.sender);

        AddCollateralRequest memory request = addCollateralRequests[_key];
        Require._require(request.account != address(0), "404");

        _deleteAddCollateralRequests(_key);

        if (_amountOutUsd == 0) {
            return;
        }

        address collateralToken = request.path[0];
        address receiveToken = request.path[request.path.length - 1];

        _amountOutUsd = _amountOutUsd.mul(PRICE_DECIMALS);
        uint256 amountOutToken = _usdToTokenMin(collateralToken, _amountOutUsd);

        IVault(vault).removeCollateral(
            request.account,
            collateralToken,
            request.indexToken,
            request.isLong,
            amountOutToken
        );

        if (request.path.length > 1) {
            _transferOut(collateralToken, amountOutToken, vault);
            amountOutToken = _swap(request.path, address(this), true);
        }

        _transferOut(receiveToken, amountOutToken, request.account);
        //        emit CollateralRemove(request.account, receiveToken, amountOutToken);
    }

    function setTPSL(
        address[] memory _path,
        address _indexToken,
        bool _withdrawETH,
        uint128 _higherPip,
        uint128 _lowerPip,
        SetTPSLOption _option
    ) external nonReentrant whenNotPaused {
        bytes32 requestKey = _createTPSLDecreaseOrder(
            msg.sender,
            _path,
            _indexToken,
            _withdrawETH
        );
        if (_option == SetTPSLOption.ONLY_HIGHER) {
            _setTPSLToMap(
                _getTPSLRequestKey(msg.sender, _indexToken, true),
                requestKey
            );
        } else if (_option == SetTPSLOption.ONLY_LOWER) {
            _setTPSLToMap(
                _getTPSLRequestKey(msg.sender, _indexToken, false),
                requestKey
            );
        } else if (_option == SetTPSLOption.BOTH) {
            _setTPSLToMap(
                _getTPSLRequestKey(msg.sender, _indexToken, true),
                requestKey
            );
            _setTPSLToMap(
                _getTPSLRequestKey(msg.sender, _indexToken, false),
                requestKey
            );
        }
        _crossBlockchainCall(
            pcsId,
            pscCrossChainGateway,
            uint8(Method.SET_TPSL),
            abi.encode(
                coreManagers[_indexToken],
                msg.sender,
                _higherPip,
                _lowerPip,
                uint8(_option)
            )
        );
    }

    function unsetTPAndSL(address _indexToken)
        external
        nonReentrant
        whenNotPaused
    {
        _deleteDecreasePositionRequests(
            TPSLRequestMap[_getTPSLRequestKey(msg.sender, _indexToken, true)]
        );
        _deleteTPSLRequestMap(
            _getTPSLRequestKey(msg.sender, _indexToken, true)
        );
        _deleteDecreasePositionRequests(
            TPSLRequestMap[_getTPSLRequestKey(msg.sender, _indexToken, false)]
        );
        _deleteTPSLRequestMap(
            _getTPSLRequestKey(msg.sender, _indexToken, false)
        );
        _crossBlockchainCall(
            pcsId,
            pscCrossChainGateway,
            uint8(Method.UNSET_TP_AND_SL),
            abi.encode(coreManagers[_indexToken], msg.sender)
        );
    }

    function unsetTPOrSL(address _indexToken, bool _isHigherPrice)
        external
        nonReentrant
        whenNotPaused
    {
        //        if (_isHigherPrice) {
        //            _deleteDecreasePositionRequests(
        //                TPSLRequestMap[
        //                    _getTPSLRequestKey(msg.sender, _indexToken, true)
        //                ]
        //            );
        //            _deleteTPSLRequestMap(
        //                _getTPSLRequestKey(msg.sender, _indexToken, true)
        //            );
        //        } else {
        //            _deleteDecreasePositionRequests(
        //                TPSLRequestMap[
        //                    _getTPSLRequestKey(msg.sender, _indexToken, false)
        //                ]
        //            );
        //            _deleteTPSLRequestMap(
        //                _getTPSLRequestKey(msg.sender, _indexToken, false)
        //            );
        //        }
        //        _crossBlockchainCall(
        //            pcsId,
        //            pscCrossChainGateway,
        //            uint8(Method.UNSET_TP_OR_SL),
        //            abi.encode(coreManagers[_indexToken], msg.sender, _isHigherPrice)
        //        );
    }

    function triggerTPSL(
        address _account,
        address _positionManager,
        uint256 _amountOutUsdAfterFees,
        uint256 _feeUsd,
        uint256 _sizeDeltaInToken,
        bool _isHigherPrice,
        bool _isLong
    ) external {
        //        _validateCaller(msg.sender);
        //
        //        address indexToken = indexTokens[_positionManager];
        //        bytes32 triggeredTPSLKey = _getTPSLRequestKey(
        //            _account,
        //            indexToken,
        //            _isHigherPrice
        //        );
        //        executeDecreasePosition(
        //            TPSLRequestMap[triggeredTPSLKey],
        //            _amountOutUsdAfterFees,
        //            _feeUsd,
        //            0, // TODO: Add _entryPip
        //            _sizeDeltaInToken,
        //            _isLong
        //        );
        //        _deleteDecreasePositionRequests(
        //            TPSLRequestMap[
        //                _getTPSLRequestKey(_account, indexToken, !_isHigherPrice)
        //            ]
        //        );
        //        _deleteTPSLRequestMap(
        //            _getTPSLRequestKey(_account, indexToken, !_isHigherPrice)
        //        );
        //        _deleteDecreasePositionRequests(TPSLRequestMap[triggeredTPSLKey]);
        //        _deleteTPSLRequestMap(triggeredTPSLKey);
    }

    function executeClaimFund(
        address _manager,
        address _account,
        bool _isLong,
        uint256 _amountOutUsd
    ) external nonReentrant {
        _validateCaller(msg.sender);

        address indexToken = indexTokens[_manager];
        require(indexToken != address(0), "invalid index token");

        bytes32 key = getPositionKey(_account, indexToken, _isLong);
        address collateralToken = latestExecutedCollateral[key];
        require(collateralToken != address(0), "invalid collateral token");

        delete latestExecutedCollateral[key];

        uint256 amountOutToken = _usdToTokenMin(
            collateralToken,
            _amountOutUsd.mul(PRICE_DECIMALS)
        );
        if (amountOutToken == 0) {
            return;
        }
        IVault(vault).withdraw(collateralToken, amountOutToken, address(this));
        _transferOut(collateralToken, amountOutToken, _account);
    }

    function refund(bytes32 _key, Method _method)
        external
        payable
        nonReentrant
    {
        _validateCaller(msg.sender);

        if (_method == Method.OPEN_LIMIT || _method == Method.OPEN_MARKET) {
            if (_method == Method.OPEN_MARKET) {
                // Fire clear pending update position request in process chain
                _crossBlockchainCall(
                    pcsId,
                    pscCrossChainGateway,
                    uint8(Method.EXECUTE_STORE_POSITION),
                    abi.encode(
                        _key,
                        // Singal 1 is to clear
                        1
                    )
                );
            }
            IncreasePositionRequest memory request = increasePositionRequests[
                _key
            ];
            require(request.account != address(0), "Refund: request not found");
            _deleteIncreasePositionRequests(_key);
            _transferOut(
                request.path[0],
                request.amountInToken,
                request.account
            );
            if (request.voucherId > 0) {
                _transferOutVoucher(request.voucherId, request.account);
            }
        }
        if (_method == Method.ADD_MARGIN) {
            AddCollateralRequest memory request = addCollateralRequests[_key];
            require(request.account != address(0), "Refund: request not found");
            _deleteAddCollateralRequests(_key);
            _transferOut(
                request.path[0],
                request.amountInToken,
                request.account
            );
        }
    }

    function _increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _entryPrice,
        uint256 _sizeDeltaToken,
        bool _isLong,
        uint256 _feeUsd
    ) internal {
        //        if (!_isLong && _sizeDelta > 0) {
        //            uint256 markPrice = _isLong
        //                ? IVault(vault).getMaxPrice(_indexToken)
        //                : IVault(vault).getMinPrice(_indexToken);
        //            // should be called strictly before position is updated in Vault
        //            IShortsTracker(shortsTracker).updateGlobalShortData(
        //                _indexToken,
        //                _sizeDelta,
        //                markPrice,
        //                true
        //            );
        //        }

        IVault(vault).increasePosition(
            _account,
            _collateralToken,
            _indexToken,
            _entryPrice,
            _sizeDeltaToken,
            _isLong,
            _feeUsd
        );
    }

    function _decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _entryPrice,
        uint256 _sizeDeltaToken,
        bool _isLong,
        address _receiver,
        uint256 _amountOutUsd,
        uint256 _feeUsd
    ) internal returns (uint256) {
        //        if (!_isLong && _sizeDelta > 0) {
        //            uint256 markPrice = _isLong
        //                ? IVault(vault).getMinPrice(_indexToken)
        //                : IVault(vault).getMaxPrice(_indexToken);
        //
        //            // should be called strictly before position is updated in Vault
        //            IShortsTracker(shortsTracker).updateGlobalShortData(
        //                _indexToken,
        //                _sizeDelta,
        //                markPrice,
        //                false
        //            );
        //        }

        return
            IVault(vault).decreasePosition(
                _account,
                _collateralToken,
                _indexToken,
                _entryPrice,
                _sizeDeltaToken,
                _isLong,
                _receiver,
                _amountOutUsd,
                _feeUsd
            );
    }

    function _createIncreasePosition(CreateIncreasePositionParam memory param)
        internal
        returns (bytes32)
    {
        IncreasePositionRequest memory request = IncreasePositionRequest(
            param.account,
            param.path,
            param.indexToken,
            param.hasCollateralInETH,
            param.amountInAfterFeeToken,
            param.feeInUsd,
            param.positionFeeUsd,
            param.voucherId
        );

        (, bytes32 requestKey) = _storeIncreasePositionRequest(request);

        {
            uint256 sizeDelta = param.sizeDeltaToken;
            uint256 pip = param.pip;
            uint16 leverage = param.leverage;
            bool isLong = param.isLong;
            uint256 amountUsd = param.amountInUsd;
            if (param.pip > 0) {
                _crossBlockchainCall(
                    pcsId,
                    pscCrossChainGateway,
                    uint8(Method.OPEN_LIMIT),
                    abi.encode(
                        requestKey,
                        coreManagers[request.indexToken],
                        isLong,
                        sizeDelta,
                        pip,
                        leverage,
                        msg.sender,
                        amountUsd
                    )
                );
            } else {
                _crossBlockchainCall(
                    pcsId,
                    pscCrossChainGateway,
                    uint8(Method.OPEN_MARKET),
                    abi.encode(
                        requestKey,
                        coreManagers[request.indexToken],
                        isLong,
                        sizeDelta,
                        leverage,
                        msg.sender,
                        amountUsd
                    )
                );
            }
        }

        emit CreateIncreasePosition(
            request.account,
            request.path,
            request.indexToken,
            request.amountInToken,
            param.sizeDeltaToken,
            param.pip,
            param.isLong,
            param.feeInUsd,
            requestKey
        );

        return requestKey;
    }

    function _createDecreasePosition(
        address _account,
        address[] memory _path,
        address _indexToken,
        uint256 _pip,
        uint256 _sizeDeltaToken,
        bool _isLong,
        bool _withdrawETH
    ) internal returns (bytes32) {
        DecreasePositionRequest memory request = DecreasePositionRequest(
            _account,
            _path,
            _indexToken,
            _withdrawETH
        );

        (, bytes32 requestKey) = _storeDecreasePositionRequest(request);

        if (_pip == 0) {
            _crossBlockchainCall(
                pcsId,
                pscCrossChainGateway,
                uint8(Method.CLOSE_POSITION),
                abi.encode(
                    requestKey,
                    coreManagers[request.indexToken],
                    _sizeDeltaToken,
                    msg.sender
                )
            );
        } else {
            _crossBlockchainCall(
                pcsId,
                pscCrossChainGateway,
                uint8(Method.CLOSE_LIMIT_POSITION),
                abi.encode(
                    requestKey,
                    coreManagers[request.indexToken],
                    _pip,
                    _sizeDeltaToken,
                    msg.sender
                )
            );
        }

        emit CreateDecreasePosition(
            request.account,
            request.path,
            request.indexToken,
            _pip,
            _sizeDeltaToken,
            _isLong,
            executionFee,
            requestKey,
            block.number,
            block.timestamp
        );
        return requestKey;
    }

    function _createTPSLDecreaseOrder(
        address _account,
        address[] memory _path,
        address _indexToken,
        bool _withdrawETH
    ) internal returns (bytes32) {
        DecreasePositionRequest memory request = DecreasePositionRequest(
            _account,
            _path,
            _indexToken,
            _withdrawETH
        );
        (, bytes32 requestKey) = _storeDecreasePositionRequest(request);
        return requestKey;
    }

    function _collectFees(
        address _account,
        address[] memory _path,
        address _indexToken,
        uint256 _amountInToken,
        uint256 _amountInUsd,
        uint16 _leverage,
        bool _isLong,
        bool _isLimitOrder
    ) internal returns (uint256, uint256) {
        (
            uint256 positionFeeUsd,
            uint256 borrowingFeeUsd,
            uint256 swapFeeUsd,
            uint256 totalFeeUsd
        ) = _calculateMarginFees(
                _account,
                _path,
                _indexToken,
                _isLong,
                _amountInToken,
                _amountInUsd,
                _leverage,
                _isLimitOrder
            );

        emit CollectFees(
            _amountInToken,
            positionFeeUsd,
            borrowingFeeUsd,
            swapFeeUsd
        );
        return (positionFeeUsd, totalFeeUsd);
    }

    function _calculateMarginFees(
        address _account,
        address[] memory _path,
        address _indexToken,
        bool _isLong,
        uint256 _amountInToken,
        uint256 _amountInUsd,
        uint256 _leverage,
        bool _isLimitOrder
    )
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return
            IGatewayUtils(gatewayUtils).calculateMarginFees(
                _account,
                _path,
                _indexToken,
                _isLong,
                _amountInToken,
                _amountInUsd,
                _leverage,
                _isLimitOrder
            );
    }

    function _storeIncreasePositionRequest(
        IncreasePositionRequest memory _request
    ) internal returns (uint256, bytes32) {
        address account = _request.account;
        uint256 index = increasePositionsIndex[account].add(1);
        increasePositionsIndex[account] = index;
        bytes32 key = getRequestKey(account, index);

        increasePositionRequests[key] = _request;
        increasePositionRequestKeys.push(key);

        return (index, key);
    }

    function _storeDecreasePositionRequest(
        DecreasePositionRequest memory _request
    ) internal returns (uint256, bytes32) {
        address account = _request.account;
        uint256 index = decreasePositionsIndex[account].add(1);
        decreasePositionsIndex[account] = index;
        bytes32 key = getRequestKey(account, index);

        decreasePositionRequests[key] = _request;
        decreasePositionRequestKeys.push(key);

        return (index, key);
    }

    function _storeAddCollateralRequest(AddCollateralRequest memory _request)
        internal
        returns (uint256, bytes32)
    {
        address account = _request.account;
        uint256 index = addCollateralIndex[account].add(1);
        addCollateralIndex[account] = index;
        bytes32 key = getRequestKey(account, index);

        addCollateralRequests[key] = _request;
        addCollateralRequestKeys.push(key);

        return (index, key);
    }

    function _transferIn(address _token, uint256 _tokenAmount) internal {
        if (_tokenAmount == 0) {
            return;
        }
        IERC20Upgradeable(_token).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenAmount
        );
    }

    function _transferInVoucher(uint256 _voucherId) internal {
        IERC721Upgradeable(futurXVoucher).safeTransferFrom(
            msg.sender,
            address(this),
            _voucherId
        );
    }

    function _transferInETH() internal {
        if (msg.value != 0) {
            IWETH(weth).deposit{value: msg.value}();
        }
    }

    function _transferOut(
        address _token,
        uint256 _tokenAmount,
        address _account
    ) internal {
        if (_tokenAmount == 0) {
            return;
        }
        IERC20Upgradeable(_token).safeTransfer(payable(_account), _tokenAmount);
    }

    function _transferOutVoucher(uint256 _voucherId, address _account)
        internal
    {
        IERC721Upgradeable(futurXVoucher).safeTransferFrom(
            address(this),
            _account,
            _voucherId
        );
    }

    function _transferOutETH(uint256 _amountOut, address payable _account)
        internal
    {
        if (msg.value != 0) {
            IWETH(weth).transfer(_account, _amountOut);
        }
    }

    function _adjustDecimalToToken(address _token, uint256 _tokenAmount)
        internal
        view
        returns (uint256)
    {
        return IVault(vault).adjustDecimalToToken(_token, _tokenAmount);
    }

    function _validatePositionRequest(
        address[] memory _path,
        uint16 _leverage,
        bool isValidateLeverage
    ) internal {
        Require._require(msg.value == executionFee, "fee");
        Require._require(_path.length == 1 || _path.length == 2, "len");
        if (isValidateLeverage) Require._require(_leverage > 1, "min leverage");
    }

    function _validateUpdateCollateral(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) internal view returns (bool) {
        return
            IGatewayUtils(gatewayUtils).validateUpdateCollateral(
                _account,
                _collateralToken,
                _indexToken,
                _isLong
            );
    }

    function _validateCaller(address _account) internal view returns (bool) {
        Require._require(positionKeepers[_account], "403");
        return true;
    }

    function _usdToTokenMin(address _token, uint256 _usdAmount)
        internal
        view
        returns (uint256)
    {
        return IVault(vault).usdToTokenMin(_token, _usdAmount);
    }

    function _tokenToUsdMin(address _token, uint256 _tokenAmount)
        internal
        view
        returns (uint256)
    {
        return IVault(vault).tokenToUsdMin(_token, _tokenAmount);
    }

    /// @dev This function is used to execute the cross blockchain call to update position call
    function _executeExecuteUpdatePositionData(bytes32 _requestKey) internal {
        _crossBlockchainCall(
            pcsId,
            pscCrossChainGateway,
            uint8(Method.EXECUTE_STORE_POSITION),
            abi.encode(_requestKey, uint8(0))
        );
    }

    function _updateLatestExecutedCollateral(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) private {
        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        latestExecutedCollateral[key] = _collateralToken;
        delete latestIncreasePendingCollateral[key];
    }

    function _updateLatestIncreasePendingCollateral(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) private {
        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        latestIncreasePendingCollateral[key] = _collateralToken;
    }

    function _crossBlockchainCall(
        uint256 _bcId,
        address _contract,
        uint8 _destMethodID,
        bytes memory _functionCallData
    ) internal {
        CrosschainFunctionCallInterface(futuresAdapter).crossBlockchainCall(
            _bcId,
            _contract,
            _destMethodID,
            _functionCallData
        );
    }

    function _deleteDecreasePositionRequests(bytes32 _key) internal {
        delete decreasePositionRequests[_key];
    }

    function _deleteTPSLRequestMap(bytes32 _key) internal {
        delete TPSLRequestMap[_key];
    }

    function _deleteIncreasePositionRequests(bytes32 _key) internal {
        delete increasePositionRequests[_key];
    }

    function _deleteAddCollateralRequests(bytes32 _key) internal {
        delete addCollateralRequests[_key];
    }

    function _setTPSLToMap(bytes32 key, bytes32 value) internal {
        TPSLRequestMap[key] = value;
    }

    function getRequestKey(address _account, uint256 _index)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_account, _index));
    }

    function getLatestIncreasePendingCollateral(
        address _account,
        address _indexToken,
        bool _isLong
    ) public view override returns (address) {
        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        return latestIncreasePendingCollateral[key];
    }

    function getPositionKey(
        address _account,
        address _indexToken,
        bool _isLong
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _indexToken, _isLong));
    }

    function _getTPSLRequestKey(
        address _account,
        address _indexToken,
        bool _isHigherPip
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _indexToken, _isHigherPip));
    }

    function _swap(
        address[] memory _path,
        address _receiver,
        bool _shouldCollectFee
    ) internal returns (uint256) {
        require(_path.length == 2, "invalid _path.length");

        if (_shouldCollectFee) {
            return IVault(vault).swap(_path[0], _path[1], _receiver);
        }
        return IVault(vault).swapWithoutFees(_path[0], _path[1], _receiver);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    //******************************************************************************************************************
    // ONLY OWNER FUNCTIONS
    //******************************************************************************************************************

    //    function setExecutionFee(uint256 _executionFee) external onlyOwner {
    //        executionFee = _executionFee;
    //    }

    //    function setWeth(address _weth) external onlyOwner {
    //        weth = _weth;
    //    }

    //    function setVault(address _vault) external onlyOwner {
    //        vault = _vault;
    //    }

    //    function setFuturesAdapter(address _futuresAdapter) external onlyOwner {
    //        futuresAdapter = _futuresAdapter;
    //    }
    //
    //    function setPosiChainId(uint256 _posiChainId) external onlyOwner {
    //        pcsId = _posiChainId;
    //    }

    //    function setPosiChainCrosschainGatewayContract(address _address)
    //        external
    //        onlyOwner
    //    {
    //        pscCrossChainGateway = _address;
    //    }
    //
    //    function setPositionKeeper(address _address) external onlyOwner {
    //        positionKeepers[_address] = true;
    //    }
    //
    //    function setCoreManager(address _token, address _manager)
    //        external
    //        onlyOwner
    //    {
    //        coreManagers[_token] = _manager;
    //        indexTokens[_manager] = _token;
    //    }
    //
    //    function setMaxGlobalShortSize(address _token, uint256 _amount)
    //        external
    //        onlyOwner
    //    {
    //        maxGlobalShortSizes[_token] = _amount;
    //    }
    //
    //    function setMaxGlobalLongSize(address _token, uint256 _amount)
    //        external
    //        onlyOwner
    //    {
    //        maxGlobalLongSizes[_token] = _amount;
    //    }
    //
    //    function setReferralRewardTracker(address _address) external onlyOwner {
    //        referralRewardTracker = _address;
    //    }

    function setFuturXVoucher(address _address) external onlyOwner {
        futurXVoucher = _address;
    }

    //    function pause() external onlyOwner {
    //        _pause();
    //    }
    //
    //    function unpause() external onlyOwner {
    //        _unpause();
    //    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
    mapping(bytes32 => address) public latestExecutedCollateral;
    mapping(bytes32 => address) public latestIncreasePendingCollateral;
    address public referralRewardTracker;
    address public futurXVoucher;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/**
 * @title Errors libraries
 * @author Position Exchange
 * @notice Defines the error messages emitted by the different contracts of the Position Exchange protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (AToken, VariableDebtToken and StableDebtToken)
 *  - P = Pausable
 *  - A = Amm
 */
library Errors {
    //common errors

    //contract specific errors
    //    string public constant VL_INVALID_AMOUNT = '1'; // 'Amount must be greater than 0'
    string public constant VL_EMPTY_ADDRESS = "2";
    string public constant VL_INVALID_QUANTITY = "3"; // 'IQ'
    string public constant VL_INVALID_LEVERAGE = "4"; // 'IL'
    string public constant VL_INVALID_CLOSE_QUANTITY = "5"; // 'ICQ'
    string public constant VL_INVALID_CLAIM_FUND = "6"; // 'ICF'
    string public constant VL_NOT_ENOUGH_MARGIN_RATIO = "7"; // 'NEMR'
    string public constant VL_NO_POSITION_TO_REMOVE = "8"; // 'NPTR'
    string public constant VL_NO_POSITION_TO_ADD = "9"; // 'NPTA'
    string public constant VL_INVALID_QUANTITY_INTERNAL_CLOSE = "10"; // 'IQIC'
    string public constant VL_NOT_ENOUGH_LIQUIDITY = "11"; // 'NELQ'
    string public constant VL_INVALID_REMOVE_MARGIN = "12"; // 'IRM'
    string public constant VL_NOT_COUNTERPARTY = "13"; // 'IRM'
    string public constant VL_INVALID_INPUT = "14"; // 'IP'
    string public constant VL_SETTLE_FUNDING_TOO_EARLY = "15"; // 'SFTE'
    string public constant VL_LONG_PRICE_THAN_CURRENT_PRICE = "16"; // '!B'
    string public constant VL_SHORT_PRICE_LESS_CURRENT_PRICE = "17"; // '!S'
    string public constant VL_INVALID_SIZE = "18"; // ''
    string public constant VL_NOT_WHITELIST_MANAGER = "19"; // ''
    string public constant VL_INVALID_ORDER = "20"; // ''
    string public constant VL_ONLY_PENDING_ORDER = "21"; // ''
    string public constant VL_MUST_SAME_SIDE_SHORT = "22.1";
    string public constant VL_MUST_SAME_SIDE_LONG = "22.2";
    string public constant VL_MUST_SMALLER_REVERSE_QUANTITY = "23";
    string public constant VL_MUST_CLOSE_TO_INDEX_PRICE_SHORT = "24.1";
    string public constant VL_MUST_CLOSE_TO_INDEX_PRICE_LONG = "24.2";
    string public constant VL_MARKET_ORDER_MUST_CLOSE_TO_INDEX_PRICE = "25";
    string public constant VL_EXCEED_MAX_NOTIONAL = "26";
    string public constant VL_MUST_HAVE_POSITION = "27";
    string public constant VL_MUST_REACH_CONDITION = "28";
    string public constant VL_ONLY_POSITION_STRATEGY_ORDER = "29";
    string public constant VL_ONLY_POSITION_HOUSE = "30";
    string public constant VL_ONLY_VALIDATED_TRIGGERS = "31";
    string public constant VL_INVALID_CONDITION = "32";
    string public constant VL_MUST_BE_INTEGER = "33";

    enum CollateralManagerErrors {
        NO_ERROR
    }
}

pragma solidity ^0.8.2;

library PositionInfo {
    struct Data {
        uint256 reservedAmount;
        uint128 entryBorrowingRates;
        address collateralToken;
    }

    function setEntryBorrowingRates(Data storage _self, uint256 _rate)
        internal
    {
        _self.entryBorrowingRates = uint128(_rate);
    }

    function addReservedAmount(Data storage _self, uint256 _amount) internal {
        _self.reservedAmount = _self.reservedAmount + _amount;
    }

    function subReservedAmount(Data storage _self, uint256 _amount) internal returns (uint256) {
        // Position already decreased on process chain -> no point in reverting
        // require(
        //    _amount <= _self.reservedAmount,
        //    "Vault: reservedAmount exceeded"
        // );
        if (_amount >= _self.reservedAmount) {
            _amount = _self.reservedAmount;
        }
        _self.reservedAmount = _self.reservedAmount - _amount;
        return _amount;
    }

    function setCollateralToken(Data storage _self, address _token) internal {
        if (_self.collateralToken == address(0)) {
            _self.collateralToken = _token;
            return;
        }
        require(_self.collateralToken == _token);
    }
}

pragma solidity ^0.8.2;

library TokenConfiguration {
    struct Data {
        // packable storage
        bool isWhitelisted;
        uint8 tokenDecimals;
        bool isStableToken;
        bool isShortableToken;
        uint64 minProfitBasisPoints;
        uint128 tokenWeight;
        // maxUsdpAmounts allows setting a max amount of USDP debt for a token
        uint128 maxUsdpAmount;
    }

    function getIsWhitelisted(Data storage _self) internal view returns (bool) {
        return _self.isWhitelisted;
    }

    function getTokenDecimals(
        Data storage _self
    ) internal view returns (uint8) {
        return _self.tokenDecimals;
    }

    function getTokenWeight(
        Data storage _self
    ) internal view returns (uint256) {
        return uint256(_self.tokenWeight);
    }

    function getIsStableToken(Data storage _self) internal view returns (bool) {
        return _self.isStableToken;
    }

    function getIsShortableToken(
        Data storage _self
    ) internal view returns (bool) {
        return _self.isShortableToken;
    }

    function getMinProfitBasisPoints(
        Data storage _self
    ) internal view returns (uint256) {
        return uint256(_self.minProfitBasisPoints);
    }

    function getMaxUsdpAmount(
        Data storage _self
    ) internal view returns (uint256) {
        return uint256(_self.maxUsdpAmount);
    }
}

/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IFuturXVoucher.sol";

contract FuturXVoucher is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    struct Voucher {
        uint256 id;
        address owner;
        uint256 value;
        uint256 expiredTime;
        uint256 maxDiscountValue;
        uint8 voucherType;
        bool isActive;
    }

    address public futurXGateway;

    mapping(uint256 => Voucher) public voucherInfo;
    mapping(address => bool) public miner;

    uint256 public globalVoucherId;
    uint256 public defaultExpireTime;
    mapping(uint8 => uint256) public expireTimeMap;

    mapping(address => uint256) public voucherValuePerAccount;
    uint256 public maxVoucherValuePerAccount;

    event VoucherDistributed(
        address owner,
        uint256 value,
        uint256 maxDiscountValue,
        uint8 voucherType,
        uint256 voucherId
    );

    event VoucherClaim(address owner, uint256 voucherId, uint256 expiredTime);

    event VoucherBurned(address owner, uint256 voucherId);

    modifier onlyMiner() {
        require(miner[msg.sender], "Only miner");
        _;
    }

    function initialize(address _futurXGateway) public initializer {
        __Ownable_init();
        __ERC721_init("FuturX Voucher", "FV");
        futurXGateway = _futurXGateway;

        globalVoucherId = 1000000;
        defaultExpireTime = 3 days;
        maxVoucherValuePerAccount = 500000000000000000000000000000000;
    }

    function distributeVoucher(
        address _to,
        uint8 _voucherType,
        uint256 _value,
        uint256 _maxDiscountValue
    ) external onlyMiner returns (Voucher memory, uint256) {
        if (_voucherType == 1) {
            voucherValuePerAccount[_to] += _maxDiscountValue;
            require(
                voucherValuePerAccount[_to] <= maxVoucherValuePerAccount,
                "max value exceeded"
            );
        } else {
            voucherValuePerAccount[_to] += _value;
            require(
                voucherValuePerAccount[_to] <= maxVoucherValuePerAccount,
                "max value exceeded"
            );
        }

        globalVoucherId++;
        _mint(_to, globalVoucherId);
        voucherInfo[globalVoucherId] = Voucher({
            id: globalVoucherId,
            owner: _to,
            value: _value,
            expiredTime: 0,
            maxDiscountValue: _maxDiscountValue,
            voucherType: _voucherType,
            isActive: false
        });
        emit VoucherDistributed(
            _to,
            _value,
            _maxDiscountValue,
            _voucherType,
            globalVoucherId
        );
        return (voucherInfo[globalVoucherId], globalVoucherId);
    }

    function claim(uint256 _voucherId)
        external
        returns (uint256 voucherId, uint256 expiredTime)
    {
        return _claim(_voucherId, msg.sender, true);
    }

    function claimAll() external {
        address sender = msg.sender;
        uint256 balance = balanceOf(sender);

        for (uint256 i = 0; i < balance; i++) {
            uint256 voucherId = tokenOfOwnerByIndex(sender, i);
            _claim(voucherId, sender, false);
        }
    }

    function _claim(
        uint256 _voucherId,
        address _account,
        bool _revertOnActive
    ) private returns (uint256 voucherId, uint256 expiredTime) {
        Voucher storage voucher = voucherInfo[_voucherId];
        require(voucher.owner == _account, "not owner");

        if (_revertOnActive) {
            require(!voucher.isActive, "must be inactive");
        } else if (voucher.isActive) {
            return (0, 0);
        }

        uint256 expiredTime = block.timestamp +
            getExpireTime(voucher.voucherType);

        voucher.expiredTime = expiredTime;
        voucher.isActive = true;

        emit VoucherClaim(_account, _voucherId, expiredTime);
        return (_voucherId, expiredTime);
    }

    function burnVoucher(uint256 voucherId) public onlyMiner {
        require(_isApprovedOrOwner(_msgSender(), globalVoucherId), "!Burn");
        _burn(globalVoucherId);
        emit VoucherBurned(voucherInfo[globalVoucherId].owner, globalVoucherId);
    }

    function tokenIdsByOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokens = new uint256[](balance);

        for (uint256 i = 0; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }

        return tokens;
    }

    function tokensByOwner(address owner)
        external
        view
        returns (Voucher[] memory)
    {
        uint256 balance = balanceOf(owner);
        Voucher[] memory vouchers = new Voucher[](balance);

        for (uint256 i = 0; i < balance; i++) {
            uint256 voucherId = tokenOfOwnerByIndex(owner, i);
            vouchers[i] = voucherInfo[voucherId];
        }

        return vouchers;
    }

    function addOperator(address _miner) public onlyOwner {
        miner[_miner] = true;
    }

    function revokeOperator(address _miner) public onlyOwner {
        miner[_miner] = false;
    }

    function getExpireTime(uint8 _voucherType) public view returns (uint256) {
        uint256 expiredTime = expireTimeMap[_voucherType];
        return expiredTime > 0 ? expiredTime : defaultExpireTime;
    }

    function getVoucherInfo(uint256 _voucherId)
        external
        view
        returns (Voucher memory)
    {
        return voucherInfo[_voucherId];
    }

    function setExpireTime(uint8 _voucherType, uint256 _expiredTimeInSecond)
        external
        onlyOwner
    {
        expireTimeMap[_voucherType] = _expiredTimeInSecond;
    }

    function setMaxVoucherValuePerAccount(uint256 _amount) external onlyOwner {
        maxVoucherValuePerAccount = _amount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from == address(0) || to == address(0)) {
            return;
        }
        require(
            from == futurXGateway || to == futurXGateway,
            "Transfer is not allow"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IReferralRewardTracker {
    function updateClaimableReward(address _trader, uint256 _fee) external ;

    function updateRefereeStatus(
        address _trader,
        address _indexToken,
        uint256 _timestamp,
        uint256 _notional,
        bool _isIncrease
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}