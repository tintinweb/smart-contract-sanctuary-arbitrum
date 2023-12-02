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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721ReceiverUpgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

/************
@title INFTOracleGetter interface
@notice Interface for getting NFT price oracle.*/
interface INFTOracleGetter {
  /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
  /***********
    @dev returns the asset price in ETH
     */
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721MetadataUpgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721ReceiverUpgradeable.sol";
import {IERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721EnumerableUpgradeable.sol";

interface ICertiNft is
    IERC721MetadataUpgradeable,
    IERC721ReceiverUpgradeable,
    IERC721EnumerableUpgradeable
{
    function mint(address to, uint256 tokenId, uint256 ltv) external;

    function burn(uint256 tokenId) external;

    function underlyingAsset() external view returns (address);

    function tokenLtv(uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface INToken {
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _vault,
        address _underlyingAsset
    ) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface IVault {
    event DirectPoolDeposit(address token, uint256 amount);

    struct NftInfo {
        address nftToken; // erc20 token,collateral token for long position!
        address certiNft; // an NFT certificate proof-of-ownership, which can only be used to redeem their deposited NFT!
        uint256 nftLtv;
    }

    function isSwapEnabled() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function setNftInfos(
        address[] memory _nfts,
        address[] memory _amount,
        uint256[] memory _nftLtv
    ) external;

    function router() external view returns (address);

    function ethg() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);

    function maxLeverage() external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function inManagerMode() external view returns (bool);

    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(
        address _account,
        address _router
    ) external view returns (bool);

    function isLiquidator(address _account) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(
        address _token
    ) external view returns (uint256);

    function tokenBalances(address _token) external view returns (uint256);

    function lastBorrowingTimes(address _token) external view returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;

    function setInManagerMode(bool _inManagerMode) external;

    function setManager(address _manager, bool _isManager) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setEthgAmount(address _token, uint256 _amount) external;

    function setBufferAmount(address _token, uint256 _amount) external;

    function setMaxGlobalShortSize(address _token, uint256 _amount) external;

    function setInPrivateLiquidationMode(
        bool _inPrivateLiquidationMode
    ) external;

    function setLiquidator(address _liquidator, bool _isActive) external;

    function setBorrowingRate(DataTypes.BorrowingRate memory) external;

    function setFees(DataTypes.Fees memory params) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxEthgAmount,
        bool _isStable,
        bool _isShortable,
        bool _isNft
    ) external;

    function setPriceFeed(address _priceFeed) external;

    function withdrawFees(
        address _token,
        address _receiver
    ) external returns (uint256);

    function directPoolDeposit(address _token) external;

    function buyETHG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function sellETHG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function priceFeed() external view returns (address);

    function cumulativeBorrowingRates(
        address _token
    ) external view returns (uint256);

    function getFees() external view returns (DataTypes.Fees memory);

    function getBorrowingRate()
        external
        view
        returns (DataTypes.BorrowingRate memory);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function whitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function nftTokens(address _token) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function getNftInfo(address _token) external view returns (NftInfo memory);

    function globalShortAveragePrices(
        address _token
    ) external view returns (uint256);

    function maxGlobalShortSizes(
        address _token
    ) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function poolAmounts(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function ethgAmounts(address _token) external view returns (uint256);

    function maxEthgAmounts(address _token) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );

    function getRedemptionAmount(
        address _token,
        uint256 _ethgAmount
    ) external view returns (uint256);

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function mintCNft(
        address _cNft,
        address _to,
        uint256 _tokenId,
        uint256 _ltv
    ) external;

    function mintNToken(address _nToken, uint256 _amount) external;

    function burnCNft(address _cNft, uint256 _tokenId) external;

    function burnNToken(address _nToken, uint256 _amount) external;

    function getBendDAOAssetPrice(address _nft) external view returns (uint256);

    function addNftToUser(
        address _user,
        address _nft,
        uint256 _tokenId
    ) external;

    function removeNftFromUser(
        address _user,
        address _nft,
        uint256 _tokenId
    ) external;

    function isNftDepsoitedForUser(
        address _user,
        address _nft,
        uint256 _tokenId
    ) external view returns (bool);

    function getFeeWhenRedeemNft(
        address _token,
        uint256 _ethgAmount
    ) external view returns (uint256);

    function nftUsers(uint256) external view returns (address);

    function nftUsersLength() external view returns (uint256);

    function getUserTokenIds(
        address _user,
        address _nft
    ) external view returns (DataTypes.DepositedNft[] memory);

    function updateNftRefinanceStatus(
        address _user,
        address _nft,
        uint256 _tokenId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IVaultPriceFeed {
    function adjustmentBasisPoints(address _token) external view returns (uint256);
    function isAdjustmentAdditive(address _token) external view returns (bool);
    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external;
    function setUseV2Pricing(bool _useV2Pricing) external;
    function setIsSecondaryPriceEnabled(bool _isEnabled) external;
    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;
    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external;
    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;
    function setPriceSampleSpace(uint256 _priceSampleSpace) external;
    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external;
    function getPrice(address _token, bool _maximise) external view returns (uint256);
    function getLatestPrimaryPrice(address _token) external view returns (uint256);
    function getPrimaryPrice(address _token, bool _maximise) external view returns (uint256);
    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library VaultErrors {

string public constant VAULT_INVALID_MAXLEVERAGE = "0";
string public constant VAULT_INVALID_TAX_BASIS_POINTS = "1";
string public constant VAULT_INVALID_STABLE_TAX_BASIS_POINTS = "2";
string public constant VAULT_INVALID_MINT_BURN_FEE_BASIS_POINTS = "3";
string public constant VAULT_INVALID_SWAP_FEE_BASIS_POINTS = "4";
string public constant VAULT_INVALID_STABLE_SWAP_FEE_BASIS_POINTS = "5";
string public constant VAULT_INVALID_MARGIN_FEE_BASIS_POINTS = "6";
string public constant VAULT_INVALID_LIQUIDATION_FEE_USD = "7";
string public constant VAULT_INVALID_BORROWING_INTERVALE = "8";
string public constant VAULT_INVALID_BORROWING_RATE_FACTOR = "9";
string public constant VAULT_INVALID_STABLE_BORROWING_RATE_FACTOR = "10";
string public constant VAULT_TOKEN_NOT_WHITELISTED = "11";
string public constant VAULT_INVALID_TOKEN_AMOUNT = "12";
string public constant VAULT_INVALID_ETHG_AMOUNT = "13";
string public constant VAULT_INVALID_REDEMPTION_AMOUNT = "14";
string public constant VAULT_INVALID_AMOUNT_OUT = "15";
string public constant VAULT_SWAPS_NOT_ENABLED = "16";
string public constant VAULT_TOKEN_IN_NOT_WHITELISTED = "17";
string public constant VAULT_TOKEN_OUT_NOT_WHITELISTED = "18";
string public constant VAULT_INVALID_TOKENS = "19";
string public constant VAULT_INVALID_AMOUNT_IN = "20";
string public constant VAULT_LEVERAGE_NOT_ENABLED = "21";
string public constant VAULT_INSUFFICIENT_COLLATERAL_FOR_FEES = "22";
string public constant VAULT_INVALID_POSITION_SIZE = "23";
string public constant VAULT_EMPTY_POSITION = "24";
string public constant VAULT_POSITION_SIZE_EXCEEDED = "25";
string public constant VAULT_POSITION_COLLATERAL_EXCEEDED = "26";
string public constant VAULT_INVALID_LIQUIDATOR = "27";
string public constant VAULT_POSITION_CAN_NOT_BE_LIQUIDATED = "28";
string public constant VAULT_INVALID_POSITION = "29";
string public constant VAULT_INVALID_AVERAGE_PRICE = "30";
string public constant VAULT_COLLATERAL_SHOULD_BE_WITHDRAWN = "31";
string public constant VAULT_SIZE_MUST_BE_MORE_THAN_COLLATERAL = "32";
string public constant VAULT_INVALID_MSG_SENDER = "33";
string public constant VAULT_MISMATCHED_TOKENS = "34";
string public constant VAULT_COLLATERAL_TOKEN_NOT_WHITELISTED = "35";
string public constant VAULT_COLLATERAL_TOKEN_MUST_NOT_BE_A_STABLE_TOKEN = "36";
string public constant VAULT_COLLATERAL_TOKEN_MUST_BE_STABLE_TOKEN = "37";
string public constant VAULT_INDEX_TOKEN_MUST_NOT_BE_STABLE_TOKEN = "38";
string public constant VAULT_INDEX_TOKEN_NOT_SHORTABLE = "39";
string public constant VAULT_INVALID_INCREASE = "40";
string public constant VAULT_RESERVE_EXCEEDS_POOL = "41";
string public constant VAULT_MAX_ETHG_EXCEEDED = "42";
string public constant VAULT_FORBIDDEN = "43";
string public constant VAULT_MAX_GAS_PRICE_EXCEEDED = "44";
string public constant VAULT_POOL_AMOUNT_LESS_THAN_BUFFER_AMOUNT = "45";
string public constant VAULT_POOL_AMOUNT_EXCEEDED = "46";
string public constant VAULT_MAX_SHORTS_EXCEEDED = "47"; 
string public constant VAULT_INSUFFICIENT_RESERVE = "48";
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {DataTypes} from "../types/DataTypes.sol";

library BorrowingFeeLogic {
    event UpdateBorrowingRate(address token, uint256 borrowngRate);

    function updateCumulativeBorrowingRate(
        DataTypes.UpdateCumulativeBorrowingRateParams memory params,
        mapping(address => uint256) storage cumulativeBorrowingRates,
        mapping(address => uint256) storage lastBorrowingTimes
    ) external {
        bool shouldUpdate = _updateCumulativeBorrowingRate(
            params.collateralToken,
            params.indexToken
        );
        if (!shouldUpdate) {
            return;
        }

        if (lastBorrowingTimes[params.collateralToken] == 0) {
            lastBorrowingTimes[params.collateralToken] =
                (block.timestamp / params.borrowingInterval) *
                params.borrowingInterval;
            return;
        }

        if (
            lastBorrowingTimes[params.collateralToken] +
                params.borrowingInterval >
            block.timestamp
        ) {
            return;
        }

        uint256 borrowingRate = _getNextBorrowingRate(
            params.borrowingInterval,
            params.collateralTokenPoolAmount,
            params.collateralTokenReservedAmount,
            params.borrowingRateFactor,
            lastBorrowingTimes[params.collateralToken]
        );
        cumulativeBorrowingRates[params.collateralToken] =
            cumulativeBorrowingRates[params.collateralToken] +
            borrowingRate;
        lastBorrowingTimes[params.collateralToken] =
            (block.timestamp / params.borrowingInterval) *
            params.borrowingInterval;

        emit UpdateBorrowingRate(
            params.collateralToken,
            cumulativeBorrowingRates[params.collateralToken]
        );
    }

    function _getNextBorrowingRate(
        uint256 _borrowingInterval,
        uint256 _poolAmount,
        uint256 _reservedAmount,
        uint256 _borrowingRateFactor,
        uint256 _lastBorrowingTime
    ) internal view returns (uint256) {
        if (_lastBorrowingTime + _borrowingInterval > block.timestamp) {
            return 0;
        }

        uint256 intervals = block.timestamp -
            _lastBorrowingTime /
            _borrowingInterval;

        if (_poolAmount == 0) {
            return 0;
        }

        return
            (_borrowingRateFactor * _reservedAmount * intervals) / _poolAmount;
    }

    function _updateCumulativeBorrowingRate(
        address /* _collateralToken */,
        address /* _indexToken */
    ) internal pure returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import {ValidationLogic} from "./ValidationLogic.sol";
import {VaultErrors} from "../helpers/VaultErrors.sol";
import {DataTypes} from "../types/DataTypes.sol";

import {IVaultPriceFeed} from "../../interfaces/IVaultPriceFeed.sol";

library GenericLogic {
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event CollectSwapFees(address token, uint256 feeUsd, uint256 feeTokens);
    event IncreasePoolAmount(address token, uint256 amount);
    event DecreasePoolAmount(address token, uint256 amount);
    event IncreaseEthgAmount(address token, uint256 amount);
    event DecreaseEthgAmount(address token, uint256 amount);
    event IncreaseReservedAmount(address token, uint256 amount);
    event DecreaseReservedAmount(address token, uint256 amount);
    event IncreaseGuaranteedUsd(address token, uint256 amount);
    event DecreaseGuaranteedUsd(address token, uint256 amount);

    struct FeeBasisPointsParams {
        address token;
        uint256 ethgDelta;
        uint256 feeBasisPoints;
        uint256 taxBasisPoints;
        bool increment;
        bool hasDynamicFees;
        uint256 ethgAmount;
        uint256 targetEthgAmount;
    }

    struct CollectSwapFeesParams {
        address token;
        uint256 amount;
        uint256 feeBasisPoints;
        uint256 basisPointsDivisor;
        uint256 tokenDecimals;
        address priceFeed;
    }

    function collectSwapFees(
        CollectSwapFeesParams memory collectSwapFeesParams,
        mapping(address => uint256) storage feeReserves
    ) internal returns (uint256) {
        uint256 afterFeeAmount = (collectSwapFeesParams.amount *
            (collectSwapFeesParams.basisPointsDivisor -
                collectSwapFeesParams.feeBasisPoints)) /
            collectSwapFeesParams.basisPointsDivisor;
        uint256 feeAmount = collectSwapFeesParams.amount - afterFeeAmount;
        feeReserves[collectSwapFeesParams.token] =
            feeReserves[collectSwapFeesParams.token] +
            feeAmount;
        emit CollectSwapFees(
            collectSwapFeesParams.token,
            GenericLogic.tokenToUsdMin(
                collectSwapFeesParams.token,
                feeAmount,
                collectSwapFeesParams.tokenDecimals,
                collectSwapFeesParams.priceFeed
            ),
            feeAmount
        );
        return afterFeeAmount;
    }

    // cases to consider
    // 1. initialAmount is far from targetAmount, action increases balance slightly => high rebate
    // 2. initialAmount is far from targetAmount, action increases balance largely => high rebate
    // 3. initialAmount is close to targetAmount, action increases balance slightly => low rebate
    // 4. initialAmount is far from targetAmount, action reduces balance slightly => high tax
    // 5. initialAmount is far from targetAmount, action reduces balance largely => high tax
    // 6. initialAmount is close to targetAmount, action reduces balance largely => low tax
    // 7. initialAmount is above targetAmount, nextAmount is below targetAmount and vice versa
    // 8. a large swap should have similar fees as the same trade split into multiple smaller swaps
    function getFeeBasisPoints(
        FeeBasisPointsParams memory params
    ) internal pure returns (uint256) {
        if (params.hasDynamicFees) {
            return params.feeBasisPoints;
        }

        uint256 initialAmount = params.ethgAmount;
        uint256 nextAmount = initialAmount + params.ethgDelta;
        if (!params.increment) {
            nextAmount = params.ethgDelta > initialAmount
                ? 0
                : initialAmount - params.ethgDelta;
        }

        uint256 targetAmount = params.targetEthgAmount;
        if (targetAmount == 0) {
            return params.feeBasisPoints;
        }

        uint256 initialDiff = initialAmount > targetAmount
            ? initialAmount - targetAmount
            : targetAmount - initialAmount;
        uint256 nextDiff = nextAmount > targetAmount
            ? nextAmount - targetAmount
            : targetAmount - nextAmount;

        // action improves relative asset balance
        if (nextDiff < initialDiff) {
            uint256 rebateBps = (params.taxBasisPoints * initialDiff) /
                targetAmount;
            return
                rebateBps > params.feeBasisPoints
                    ? 0
                    : params.feeBasisPoints - rebateBps;
        }

        uint256 averageDiff = initialDiff + nextDiff / 2;
        if (averageDiff > targetAmount) {
            averageDiff = targetAmount;
        }
        uint256 taxBps = (params.taxBasisPoints * averageDiff) / targetAmount;
        return params.feeBasisPoints + taxBps;
    }

    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul,
        address _ethg,
        uint256 _ethgDecimals,
        mapping(address => uint256) storage tokenDecimals
    ) internal view returns (uint256) {
        uint256 decimalsDiv = _tokenDiv == _ethg
            ? _ethgDecimals
            : tokenDecimals[_tokenDiv];
        uint256 decimalsMul = _tokenMul == _ethg
            ? _ethgDecimals
            : tokenDecimals[_tokenMul];
        return (_amount * 10 ** decimalsMul) / 10 ** decimalsDiv;
    }

    function getMaxPrice(
        address _token,
        address _priceFeed
    ) internal view returns (uint256) {
        return IVaultPriceFeed(_priceFeed).getPrice(_token, true);
    }

    function getMinPrice(
        address _token,
        address _priceFeed
    ) internal view returns (uint256) {
        return IVaultPriceFeed(_priceFeed).getPrice(_token, false);
    }

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount,
        uint256 _decimals,
        address _priceFeed
    ) internal view returns (uint256) {
        if (_tokenAmount == 0) {
            return 0;
        }
        uint256 price = getMinPrice(_token, _priceFeed);
        // uint256 decimals = tokenDecimals[_token];
        return (_tokenAmount * price) / 10 ** _decimals;
    }

    function usdToTokenMax(
        address _token,
        uint256 _usdAmount,
        uint256 _decimals,
        address _priceFeed
    ) internal view returns (uint256) {
        if (_usdAmount == 0) {
            return 0;
        }
        return
            usdToToken(_usdAmount, getMinPrice(_token, _priceFeed), _decimals);
    }

    function usdToTokenMin(
        address _token,
        uint256 _usdAmount,
        uint256 _decimals,
        address _priceFeed
    ) internal view returns (uint256) {
        if (_usdAmount == 0) {
            return 0;
        }
        return
            usdToToken(_usdAmount, getMaxPrice(_token, _priceFeed), _decimals);
    }

    function usdToToken(
        uint256 _usdAmount,
        uint256 _price,
        uint256 _decimals
    ) internal pure returns (uint256) {
        if (_usdAmount == 0) {
            return 0;
        }
        // uint256 decimals = tokenDecimals[_token];
        return (_usdAmount * 10 ** _decimals) / _price;
    }

    function getTargetEthgAmount(
        address _ethg,
        uint256 _tokenWeight,
        uint256 _totalTokenWeights
    ) internal view returns (uint256) {
        uint256 supply = IERC20Upgradeable(_ethg).totalSupply();
        if (supply == 0) {
            return 0;
        }
        return (_tokenWeight * supply) / _totalTokenWeights;
    }

    function transferIn(
        address _token,
        mapping(address => uint256) storage tokenBalances
    ) internal returns (uint256) {
        uint256 prevBalance = tokenBalances[_token];
        uint256 nextBalance = IERC20Upgradeable(_token).balanceOf(
            address(this)
        );
        tokenBalances[_token] = nextBalance;

        return nextBalance - prevBalance;
    }

    function transferOut(
        address _token,
        uint256 _amount,
        address _receiver,
        mapping(address => uint256) storage tokenBalances
    ) internal {
        IERC20Upgradeable(_token).safeTransfer(_receiver, _amount);
        tokenBalances[_token] = IERC20Upgradeable(_token).balanceOf(
            address(this)
        );
    }

    function getRedemptionAmount(
        address _token,
        uint256 _ethgAmount,
        address _priceFeed,
        uint256 _pricePrecision,
        address _ethg,
        uint256 _ethgDecimals,
        mapping(address => uint256) storage tokenDecimals
    ) internal view returns (uint256) {
        uint256 price = getMaxPrice(_token, _priceFeed);
        uint256 redemptionAmount = (_ethgAmount * _pricePrecision) / price;

        return
            adjustForDecimals(
                redemptionAmount,
                _ethg,
                _token,
                _ethg,
                _ethgDecimals,
                tokenDecimals
            );
    }

    function increasePoolAmount(
        address _token,
        uint256 _amount,
        mapping(address => uint256) storage poolAmounts
    ) internal {
        poolAmounts[_token] += _amount;
        uint256 balance = IERC20Upgradeable(_token).balanceOf(address(this));
        ValidationLogic.validate(
            poolAmounts[_token] <= balance,
            VaultErrors.VAULT_POOL_AMOUNT_EXCEEDED
        );
        emit IncreasePoolAmount(_token, _amount);
    }

    function decreasePoolAmount(
        address _token,
        uint256 _amount,
        uint256 _tokenReservedAmount,
        mapping(address => uint256) storage poolAmounts
    ) internal {
        ValidationLogic.validate(
            poolAmounts[_token] - _amount >= 0,
            VaultErrors.VAULT_POOL_AMOUNT_EXCEEDED
        );
        poolAmounts[_token] -= _amount;
        ValidationLogic.validate(
            _tokenReservedAmount <= poolAmounts[_token],
            VaultErrors.VAULT_RESERVE_EXCEEDS_POOL
        );
        emit DecreasePoolAmount(_token, _amount);
    }

    function increaseEthgAmount(
        address _token,
        uint256 _amount,
        uint256 _maxEthgAmount,
        mapping(address => uint256) storage ethgAmounts
    ) internal {
        ethgAmounts[_token] = ethgAmounts[_token] + _amount;
        if (_maxEthgAmount != 0) {
            ValidationLogic.validate(
                ethgAmounts[_token] <= _maxEthgAmount,
                VaultErrors.VAULT_MAX_ETHG_EXCEEDED
            );
        }
        emit IncreaseEthgAmount(_token, _amount);
    }

    function decreaseEthgAmount(
        address _token,
        uint256 _amount,
        mapping(address => uint256) storage ethgAmounts
    ) internal {
        uint256 value = ethgAmounts[_token];
        // since ETHG can be minted using multiple assets
        // it is possible for the ETHG debt for a single asset to be less than zero
        // the ETHG debt is capped to zero for this case
        if (value <= _amount) {
            ethgAmounts[_token] = 0;
            emit DecreaseEthgAmount(_token, value);
            return;
        }
        ethgAmounts[_token] = value - _amount;
        emit DecreaseEthgAmount(_token, _amount);
    }

    function increaseReservedAmount(
        address _token,
        uint256 _amount,
        uint256 _tokenPoolAmount,
        mapping(address => uint256) storage reservedAmounts
    ) internal {
        reservedAmounts[_token] = reservedAmounts[_token] + _amount;
        ValidationLogic.validate(
            reservedAmounts[_token] <= _tokenPoolAmount,
            VaultErrors.VAULT_RESERVE_EXCEEDS_POOL
        );
        emit IncreaseReservedAmount(_token, _amount);
    }

    function decreaseReservedAmount(
        address _token,
        uint256 _amount,
        mapping(address => uint256) storage reservedAmounts
    ) internal {
        ValidationLogic.validate(
            reservedAmounts[_token] - _amount >= 0,
            VaultErrors.VAULT_INSUFFICIENT_RESERVE
        );

        reservedAmounts[_token] -= _amount;
        emit DecreaseReservedAmount(_token, _amount);
    }

    function increaseGuaranteedUsd(
        address _token,
        uint256 _usdAmount,
        mapping(address => uint256) storage guaranteedUsd
    ) internal {
        guaranteedUsd[_token] = guaranteedUsd[_token] + _usdAmount;
        emit IncreaseGuaranteedUsd(_token, _usdAmount);
    }

    function decreaseGuaranteedUsd(
        address _token,
        uint256 _usdAmount,
        mapping(address => uint256) storage guaranteedUsd
    ) internal {
        guaranteedUsd[_token] = guaranteedUsd[_token] - _usdAmount;
        emit DecreaseGuaranteedUsd(_token, _usdAmount);
    }

    function increaseGlobalShortSize(
        address _token,
        uint256 _amount,
        uint256 _tokenMaxGlobalShortSizes,
        mapping(address => uint256) storage globalShortSizes
    ) internal {
        globalShortSizes[_token] = globalShortSizes[_token] + _amount;
        if (_tokenMaxGlobalShortSizes != 0) {
            ValidationLogic.validate(
                globalShortSizes[_token] <= _tokenMaxGlobalShortSizes,
                VaultErrors.VAULT_MAX_SHORTS_EXCEEDED
            );
        }
    }

    function decreaseGlobalShortSize(
        address _token,
        uint256 _amount,
        mapping(address => uint256) storage globalShortSizes
    ) internal {
        uint256 size = globalShortSizes[_token];
        if (_amount > size) {
            globalShortSizes[_token] = 0;
            return;
        }

        globalShortSizes[_token] = size - _amount;
    }

    function updateTokenBalance(
        address _token,
        mapping(address => uint256) storage tokenBalances
    ) internal {
        uint256 nextBalance = IERC20Upgradeable(_token).balanceOf(
            address(this)
        );
        tokenBalances[_token] = nextBalance;
    }

    function getFeeWhenRedeemNft(
        address _token,
        uint256 _ethgAmount,
        address _priceFeed,
        uint256 _pricePrecision,
        address _ethg,
        uint256 _ethgDecimals,
        uint256 _tokenWeight,
        uint256 _totalTokenWeights,
        uint256 _tokenEthgAmount,
        uint256 _basisPointsDivisor,
        DataTypes.Fees memory fees,
        mapping(address => uint256) storage tokenDecimals
    ) internal view returns (uint256) {
        uint256 redemptionAmount = getRedemptionAmount(
            _token,
            _ethgAmount,
            _priceFeed,
            _pricePrecision,
            _ethg,
            _ethgDecimals,
            tokenDecimals
        );
        ValidationLogic.validate(
            redemptionAmount > 0,
            VaultErrors.VAULT_INVALID_REDEMPTION_AMOUNT
        );

        uint256 targetEthgAmountToken = getTargetEthgAmount(
            _ethg,
            _tokenWeight,
            _totalTokenWeights
        );

        uint256 feeBasisPoints = getSellEthgFeeBasisPoints(
            _token,
            _ethgAmount,
            _tokenEthgAmount,
            targetEthgAmountToken,
            fees
        );

        uint256 afterFeeAmount = (redemptionAmount *
            (_basisPointsDivisor - feeBasisPoints)) / _basisPointsDivisor;
        uint256 feeAmount = redemptionAmount - afterFeeAmount;

        return feeAmount;
    }

    function getBuyEthgFeeBasisPoints(
        address _token,
        uint256 _ethgDelta,
        uint256 _ethgAmount,
        uint256 _targetEthgAmount,
        DataTypes.Fees memory _fees
    ) internal pure returns (uint256) {
        return
            getFeeBasisPoints(
                FeeBasisPointsParams({
                    token: _token,
                    ethgDelta: _ethgDelta,
                    feeBasisPoints: _fees.mintBurnFeeBasisPoints,
                    taxBasisPoints: _fees.taxBasisPoints,
                    increment: true,
                    hasDynamicFees: _fees.hasDynamicFees,
                    ethgAmount: _ethgAmount,
                    targetEthgAmount: _targetEthgAmount
                })
            );
    }

    function getSellEthgFeeBasisPoints(
        address _token,
        uint256 _ethgDelta,
        uint256 _ethgAmount,
        uint256 _targetEthgAmount,
        DataTypes.Fees memory _fees
    ) internal pure returns (uint256) {
        return
            getFeeBasisPoints(
                FeeBasisPointsParams({
                    token: _token,
                    ethgDelta: _ethgDelta,
                    feeBasisPoints: _fees.mintBurnFeeBasisPoints,
                    taxBasisPoints: _fees.taxBasisPoints,
                    increment: false,
                    hasDynamicFees: _fees.hasDynamicFees,
                    ethgAmount: _ethgAmount,
                    targetEthgAmount: _targetEthgAmount
                })
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {ValidationLogic} from "./ValidationLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {BorrowingFeeLogic} from "./BorrowingFeeLogic.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {VaultErrors} from "../helpers/VaultErrors.sol";

library PositionLogic {
    event CollectMarginFees(address token, uint256 feeUsd, uint256 feeTokens);
    event UpdatePnl(bytes32 key, bool hasProfit, uint256 delta);
    event IncreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee
    );
    event DecreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee
    );
    event LiquidatePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 size,
        uint256 collateral,
        uint256 reserveAmount,
        int256 realisedPnl,
        uint256 markPrice
    );
    event UpdatePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 entryBorrowingRate,
        uint256 reserveAmount,
        int256 realisedPnl,
        uint256 markPrice
    );
    event ClosePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 entryBorrowingRate,
        uint256 reserveAmount,
        int256 realisedPnl
    );

    function increasePosition(
        DataTypes.IncreasePositionParams memory params,
        DataTypes.Fees memory fees,
        DataTypes.BorrowingRate memory borrowingRate,
        mapping(address => uint256) storage minProfitBasisPoints,
        mapping(address => mapping(address => bool)) storage approvedRouters,
        mapping(address => bool) storage whitelistedTokens,
        mapping(address => bool) storage stableTokens,
        mapping(address => bool) storage shortableTokens,
        mapping(bytes32 => DataTypes.Position) storage positions,
        mapping(address => uint256) storage cumulativeBorrowingRates,
        mapping(address => uint256) storage lastBorrowingTimes,
        mapping(address => uint256) storage poolAmounts,
        mapping(address => uint256) storage reservedAmounts,
        mapping(address => uint256) storage tokenBalances,
        mapping(address => uint256) storage tokenDecimals,
        mapping(address => uint256) storage guaranteedUsd,
        mapping(address => uint256) storage globalShortSizes,
        mapping(address => uint256) storage globalShortAveragePrices,
        mapping(address => uint256) storage maxGlobalShortSizes,
        mapping(address => uint256) storage feeReserves
    ) external {
        ValidationLogic.validateIncreasePositionParams(
            params,
            approvedRouters,
            whitelistedTokens,
            stableTokens,
            shortableTokens
        );
        uint256 price = params.isLong
            ? GenericLogic.getMaxPrice(params.indexToken, params.priceFeed)
            : GenericLogic.getMinPrice(params.indexToken, params.priceFeed);

        BorrowingFeeLogic.updateCumulativeBorrowingRate(
            DataTypes.UpdateCumulativeBorrowingRateParams({
                collateralToken: params.collateralToken,
                indexToken: params.indexToken,
                borrowingInterval: borrowingRate.borrowingInterval,
                borrowingRateFactor: borrowingRate.borrowingRateFactor,
                collateralTokenPoolAmount: poolAmounts[params.collateralToken],
                collateralTokenReservedAmount: reservedAmounts[
                    params.collateralToken
                ]
            }),
            cumulativeBorrowingRates,
            lastBorrowingTimes
        );

        bytes32 key = getPositionKey(
            params.account,
            params.collateralToken,
            params.indexToken,
            params.isLong
        );
        DataTypes.Position storage position = positions[key];

        if (position.size == 0) {
            position.averagePrice = price;
        }

        if (position.size > 0 && params.sizeDelta > 0) {
            position.averagePrice = getNextAveragePrice(
                params.indexToken,
                position.size,
                position.averagePrice,
                params.isLong,
                price,
                params.sizeDelta,
                position.lastIncreasedTime,
                fees.minProfitTime,
                params.priceFeed,
                params.basisPointsDivisor,
                minProfitBasisPoints
            );
        }
        uint256 fee = collectMarginFees(
            params.collateralToken,
            params.sizeDelta,
            position.size,
            position.entryBorrowingRate,
            params.basisPointsDivisor,
            fees.marginFeeBasisPoints,
            params.borrowingRatePrecision,
            tokenDecimals[params.collateralToken],
            params.priceFeed,
            cumulativeBorrowingRates[params.collateralToken],
            feeReserves
        );
        uint256 collateralDelta = GenericLogic.transferIn(
            params.collateralToken,
            tokenBalances
        );
        uint256 collateralDeltaUsd = GenericLogic.tokenToUsdMin(
            params.collateralToken,
            collateralDelta,
            tokenDecimals[params.collateralToken],
            params.priceFeed
        );

        position.collateral = position.collateral + collateralDeltaUsd;
        ValidationLogic.validate(
            position.collateral >= fee,
            VaultErrors.VAULT_INSUFFICIENT_COLLATERAL_FOR_FEES
        );

        position.collateral = position.collateral - fee;
        position.entryBorrowingRate = cumulativeBorrowingRates[
            params.collateralToken
        ];
        position.size = position.size + params.sizeDelta;
        position.lastIncreasedTime = block.timestamp;

        ValidationLogic.validate(
            position.size > 0,
            VaultErrors.VAULT_INVALID_POSITION_SIZE
        );
        ValidationLogic.validatePosition(position.size, position.collateral);
        validateLiquidation(
            params.indexToken,
            params.isLong,
            true,
            params.priceFeed,
            minProfitBasisPoints[params.collateralToken],
            params.borrowingRatePrecision,
            params.basisPointsDivisor,
            params.maxLeverage,
            cumulativeBorrowingRates[params.collateralToken],
            fees,
            position
        );

        // reserve tokens to pay profits on the position
        uint256 reserveDelta = GenericLogic.usdToTokenMax(
            params.collateralToken,
            params.sizeDelta,
            tokenDecimals[params.collateralToken],
            params.priceFeed
        );
        GenericLogic.increaseReservedAmount(
            params.collateralToken,
            reserveDelta,
            poolAmounts[params.collateralToken],
            reservedAmounts
        );

        if (params.isLong) {
            // guaranteedUsd stores the sum of (position.size - position.collateral) for all positions
            // if a fee is charged on the collateral then guaranteedUsd should be increased by that fee amount
            // since (position.size - position.collateral) would have increased by `fee`
            GenericLogic.increaseGuaranteedUsd(
                params.collateralToken,
                params.sizeDelta + fee,
                guaranteedUsd
            );
            GenericLogic.decreaseGuaranteedUsd(
                params.collateralToken,
                collateralDeltaUsd,
                guaranteedUsd
            );
            // treat the deposited collateral as part of the pool
            GenericLogic.increasePoolAmount(
                params.collateralToken,
                collateralDelta,
                poolAmounts
            );
            // fees need to be deducted from the pool since fees are deducted from position.collateral
            // and collateral is treated as part of the pool
            GenericLogic.decreasePoolAmount(
                params.collateralToken,
                GenericLogic.usdToTokenMin(
                    params.collateralToken,
                    fee,
                    tokenDecimals[params.collateralToken],
                    params.priceFeed
                ),
                reservedAmounts[params.collateralToken],
                poolAmounts
            );
        } else {
            if (globalShortSizes[params.indexToken] == 0) {
                globalShortAveragePrices[params.indexToken] = price;
            } else {
                globalShortAveragePrices[
                    params.indexToken
                ] = getNextGlobalShortAveragePrice(
                    price,
                    params.sizeDelta,
                    globalShortSizes[params.indexToken],
                    globalShortAveragePrices[params.indexToken]
                );
            }

            GenericLogic.increaseGlobalShortSize(
                params.indexToken,
                params.sizeDelta,
                maxGlobalShortSizes[params.indexToken],
                globalShortSizes
            );
        }

        emit IncreasePosition(
            key,
            params.account,
            params.collateralToken,
            params.indexToken,
            collateralDeltaUsd,
            params.sizeDelta,
            params.isLong,
            price,
            fee
        );
        emit UpdatePosition(
            key,
            position.size,
            position.collateral,
            position.averagePrice,
            position.entryBorrowingRate,
            position.reserveAmount,
            position.realisedPnl,
            price
        );
    }

    function decreasePosition(
        DataTypes.DecreasePositionParams memory params,
        DataTypes.Fees memory fees,
        DataTypes.BorrowingRate memory borrowingRate,
        mapping(address => mapping(address => bool)) storage approvedRouters,
        mapping(address => uint256) storage cumulativeBorrowingRates,
        mapping(address => uint256) storage lastBorrowingTimes,
        mapping(address => uint256) storage poolAmounts,
        mapping(address => uint256) storage reservedAmounts,
        mapping(bytes32 => DataTypes.Position) storage positions,
        mapping(address => uint256) storage feeReserves,
        mapping(address => uint256) storage minProfitBasisPoints,
        mapping(address => uint256) storage tokenDecimals,
        mapping(address => uint256) storage guaranteedUsd,
        mapping(address => uint256) storage globalShortSizes,
        mapping(address => uint256) storage tokenBalances
    ) external returns (uint256) {
        return
            _decreasePosition(
                params,
                fees,
                borrowingRate,
                approvedRouters,
                cumulativeBorrowingRates,
                lastBorrowingTimes,
                poolAmounts,
                reservedAmounts,
                positions,
                feeReserves,
                minProfitBasisPoints,
                tokenDecimals,
                guaranteedUsd,
                globalShortSizes,
                tokenBalances
            );
    }

    function _decreasePosition(
        DataTypes.DecreasePositionParams memory params,
        DataTypes.Fees memory fees,
        DataTypes.BorrowingRate memory borrowingRate,
        mapping(address => mapping(address => bool)) storage approvedRouters,
        mapping(address => uint256) storage cumulativeBorrowingRates,
        mapping(address => uint256) storage lastBorrowingTimes,
        mapping(address => uint256) storage poolAmounts,
        mapping(address => uint256) storage reservedAmounts,
        mapping(bytes32 => DataTypes.Position) storage positions,
        mapping(address => uint256) storage feeReserves,
        mapping(address => uint256) storage minProfitBasisPoints,
        mapping(address => uint256) storage tokenDecimals,
        mapping(address => uint256) storage guaranteedUsd,
        mapping(address => uint256) storage globalShortSizes,
        mapping(address => uint256) storage tokenBalances
    ) internal returns (uint256) {
        ValidationLogic.validateDecreasePositionParams(params, approvedRouters);
        uint256 price = params.isLong
            ? GenericLogic.getMinPrice(params.indexToken, params.priceFeed)
            : GenericLogic.getMaxPrice(params.indexToken, params.priceFeed);

        BorrowingFeeLogic.updateCumulativeBorrowingRate(
            DataTypes.UpdateCumulativeBorrowingRateParams({
                collateralToken: params.collateralToken,
                indexToken: params.indexToken,
                borrowingInterval: borrowingRate.borrowingInterval,
                borrowingRateFactor: borrowingRate.borrowingRateFactor,
                collateralTokenPoolAmount: poolAmounts[params.collateralToken],
                collateralTokenReservedAmount: reservedAmounts[
                    params.collateralToken
                ]
            }),
            cumulativeBorrowingRates,
            lastBorrowingTimes
        );

        bytes32 key = getPositionKey(
            params.account,
            params.collateralToken,
            params.indexToken,
            params.isLong
        );
        DataTypes.Position storage position = positions[key];

        ValidationLogic.validate(
            position.size > 0,
            VaultErrors.VAULT_EMPTY_POSITION
        );
        ValidationLogic.validate(
            position.size >= params.sizeDelta,
            VaultErrors.VAULT_POSITION_SIZE_EXCEEDED
        );
        ValidationLogic.validate(
            position.collateral >= params.collateralDelta,
            VaultErrors.VAULT_POSITION_COLLATERAL_EXCEEDED
        );

        uint256 collateral = position.collateral;
        // scrop variables to avoid stack too deep errors
        {
            uint256 reserveDelta = (position.reserveAmount *
                (params.sizeDelta)) / position.size;
            position.reserveAmount = position.reserveAmount - reserveDelta;
            GenericLogic.decreaseReservedAmount(
                params.collateralToken,
                reserveDelta,
                reservedAmounts
            );
        }

        (uint256 usdOut, uint256 usdOutAfterFee) = reduceCollateral(
            params.collateralToken,
            params.indexToken,
            params.collateralDelta,
            params.sizeDelta,
            params.isLong,
            params.basisPointsDivisor,
            params.borrowingRatePrecision,
            tokenDecimals[params.collateralToken],
            cumulativeBorrowingRates[params.collateralToken],
            params.priceFeed,
            minProfitBasisPoints[params.collateralToken],
            reservedAmounts[params.collateralToken],
            key,
            fees,
            position,
            poolAmounts,
            feeReserves
        );

        if (position.size != params.sizeDelta) {
            position.entryBorrowingRate = cumulativeBorrowingRates[
                params.collateralToken
            ];

            position.size = position.size - params.sizeDelta;

            ValidationLogic.validatePosition(
                position.size,
                position.collateral
            );

            validateLiquidation(
                params.indexToken,
                params.isLong,
                true,
                params.priceFeed,
                minProfitBasisPoints[params.collateralToken],
                params.borrowingRatePrecision,
                params.basisPointsDivisor,
                params.maxLeverage,
                cumulativeBorrowingRates[params.collateralToken],
                fees,
                position
            );

            if (params.isLong) {
                GenericLogic.increaseGuaranteedUsd(
                    params.collateralToken,
                    collateral - position.collateral,
                    guaranteedUsd
                );
                GenericLogic.decreaseGuaranteedUsd(
                    params.collateralToken,
                    params.sizeDelta,
                    guaranteedUsd
                );
            }

            emit DecreasePosition(
                key,
                params.account,
                params.collateralToken,
                params.indexToken,
                params.collateralDelta,
                params.sizeDelta,
                params.isLong,
                price,
                usdOut - usdOutAfterFee
            );
            emit UpdatePosition(
                key,
                position.size,
                position.collateral,
                position.averagePrice,
                position.entryBorrowingRate,
                position.reserveAmount,
                position.realisedPnl,
                price
            );
        } else {
            if (params.isLong) {
                GenericLogic.increaseGuaranteedUsd(
                    params.collateralToken,
                    collateral,
                    guaranteedUsd
                );
                GenericLogic.decreaseGuaranteedUsd(
                    params.collateralToken,
                    params.sizeDelta,
                    guaranteedUsd
                );
            }

            emit DecreasePosition(
                key,
                params.account,
                params.collateralToken,
                params.indexToken,
                params.collateralDelta,
                params.sizeDelta,
                params.isLong,
                price,
                usdOut - usdOutAfterFee
            );
            emit ClosePosition(
                key,
                position.size,
                position.collateral,
                position.averagePrice,
                position.entryBorrowingRate,
                position.reserveAmount,
                position.realisedPnl
            );

            delete positions[key];
        }

        if (!params.isLong) {
            GenericLogic.decreaseGlobalShortSize(
                params.indexToken,
                params.sizeDelta,
                globalShortSizes
            );
        }

        if (usdOut > 0) {
            if (params.isLong) {
                GenericLogic.decreasePoolAmount(
                    params.collateralToken,
                    GenericLogic.usdToTokenMin(
                        params.collateralToken,
                        usdOut,
                        tokenDecimals[params.collateralToken],
                        params.priceFeed
                    ),
                    reservedAmounts[params.collateralToken],
                    poolAmounts
                );
            }
            uint256 amountOutAfterFees = GenericLogic.usdToTokenMin(
                params.collateralToken,
                usdOutAfterFee,
                tokenDecimals[params.collateralToken],
                params.priceFeed
            );
            GenericLogic.transferOut(
                params.collateralToken,
                amountOutAfterFees,
                params.receiver,
                tokenBalances
            );
            return amountOutAfterFees;
        }

        return 0;
    }

    function liquidatePosition(
        DataTypes.LiquidatePositionParams memory params,
        DataTypes.Fees memory fees,
        DataTypes.BorrowingRate memory borrowingRate,
        mapping(address => mapping(address => bool)) storage approvedRouters,
        mapping(address => uint256) storage cumulativeBorrowingRates,
        mapping(address => uint256) storage lastBorrowingTimes,
        mapping(address => uint256) storage poolAmounts,
        mapping(address => uint256) storage reservedAmounts,
        mapping(bytes32 => DataTypes.Position) storage positions,
        mapping(address => uint256) storage feeReserves,
        mapping(address => uint256) storage minProfitBasisPoints,
        mapping(address => uint256) storage tokenDecimals,
        mapping(address => uint256) storage guaranteedUsd,
        mapping(address => uint256) storage globalShortSizes,
        mapping(address => uint256) storage tokenBalances,
        mapping(address => bool) storage isLiquidator
    ) external {
        if (params.inPrivateLiquidationMode) {
            ValidationLogic.validate(
                isLiquidator[msg.sender],
                VaultErrors.VAULT_INVALID_LIQUIDATOR
            );
        }

        uint256 markPrice = params.isLong
            ? GenericLogic.getMinPrice(params.indexToken, params.priceFeed)
            : GenericLogic.getMaxPrice(params.indexToken, params.priceFeed);

        BorrowingFeeLogic.updateCumulativeBorrowingRate(
            DataTypes.UpdateCumulativeBorrowingRateParams({
                collateralToken: params.collateralToken,
                indexToken: params.indexToken,
                borrowingInterval: borrowingRate.borrowingInterval,
                borrowingRateFactor: borrowingRate.borrowingRateFactor,
                collateralTokenPoolAmount: poolAmounts[params.collateralToken],
                collateralTokenReservedAmount: reservedAmounts[
                    params.collateralToken
                ]
            }),
            cumulativeBorrowingRates,
            lastBorrowingTimes
        );

        bytes32 key = getPositionKey(
            params.account,
            params.collateralToken,
            params.indexToken,
            params.isLong
        );
        DataTypes.Position memory position = positions[key];
        ValidationLogic.validate(
            position.size > 0,
            VaultErrors.VAULT_EMPTY_POSITION
        );

        (uint256 liquidationState, uint256 marginFees) = validateLiquidation(
            params.indexToken,
            params.isLong,
            false,
            params.priceFeed,
            minProfitBasisPoints[params.collateralToken],
            params.borrowingRatePrecision,
            params.basisPointsDivisor,
            params.maxLeverage,
            cumulativeBorrowingRates[params.collateralToken],
            fees,
            position
        );
        ValidationLogic.validate(
            liquidationState != 0,
            VaultErrors.VAULT_POSITION_CAN_NOT_BE_LIQUIDATED
        );
        if (liquidationState == 2) {
            // max leverage exceeded but there is collateral remaining after deducting losses so decreasePosition instead
            _decreasePosition(
                DataTypes.DecreasePositionParams({
                    account: params.account,
                    collateralToken: params.collateralToken,
                    indexToken: params.indexToken,
                    collateralDelta: 0,
                    sizeDelta: position.size,
                    isLong: params.isLong,
                    receiver: params.account,
                    priceFeed: params.priceFeed,
                    maxGasPrice: params.maxGasPrice,
                    router: params.router,
                    basisPointsDivisor: params.basisPointsDivisor,
                    borrowingRatePrecision: params.borrowingRatePrecision,
                    maxLeverage: params.maxLeverage
                }),
                fees,
                borrowingRate,
                approvedRouters,
                cumulativeBorrowingRates,
                lastBorrowingTimes,
                poolAmounts,
                reservedAmounts,
                positions,
                feeReserves,
                minProfitBasisPoints,
                tokenDecimals,
                guaranteedUsd,
                globalShortSizes,
                tokenBalances
            );
            return;
        }

        uint256 feeTokens = GenericLogic.usdToTokenMin(
            params.collateralToken,
            marginFees,
            tokenDecimals[params.collateralToken],
            params.priceFeed
        );
        feeReserves[params.collateralToken] =
            feeReserves[params.collateralToken] +
            feeTokens;
        emit CollectMarginFees(params.collateralToken, marginFees, feeTokens);

        GenericLogic.decreaseReservedAmount(
            params.collateralToken,
            position.reserveAmount,
            reservedAmounts
        );
        if (params.isLong) {
            GenericLogic.decreaseGuaranteedUsd(
                params.collateralToken,
                position.size - position.collateral,
                guaranteedUsd
            );
            GenericLogic.decreasePoolAmount(
                params.collateralToken,
                GenericLogic.usdToTokenMin(
                    params.collateralToken,
                    marginFees,
                    tokenDecimals[params.collateralToken],
                    params.priceFeed
                ),
                reservedAmounts[params.collateralToken],
                poolAmounts
            );
        }

        emit LiquidatePosition(
            key,
            params.account,
            params.collateralToken,
            params.indexToken,
            params.isLong,
            position.size,
            position.collateral,
            position.reserveAmount,
            position.realisedPnl,
            markPrice
        );

        if (!params.isLong && marginFees < position.collateral) {
            uint256 remainingCollateral = position.collateral - marginFees;
            GenericLogic.increasePoolAmount(
                params.collateralToken,
                GenericLogic.usdToTokenMin(
                    params.collateralToken,
                    remainingCollateral,
                    tokenDecimals[params.collateralToken],
                    params.priceFeed
                ),
                poolAmounts
            );
        }

        if (!params.isLong) {
            GenericLogic.decreaseGlobalShortSize(
                params.indexToken,
                position.size,
                globalShortSizes
            );
        }

        delete positions[key];

        // pay the fee receiver using the pool, we assume that in general the liquidated amount should be sufficient to cover
        // the liquidation fees
        GenericLogic.decreasePoolAmount(
            params.collateralToken,
            GenericLogic.usdToTokenMin(
                params.collateralToken,
                fees.liquidationFeeUsd,
                tokenDecimals[params.collateralToken],
                params.priceFeed
            ),
            reservedAmounts[params.collateralToken],
            poolAmounts
        );
        GenericLogic.transferOut(
            params.collateralToken,
            GenericLogic.usdToTokenMin(
                params.collateralToken,
                fees.liquidationFeeUsd,
                tokenDecimals[params.collateralToken],
                params.priceFeed
            ),
            params.feeReceiver,
            tokenBalances
        );
    }

    function getPositionKey(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _account,
                    _collateralToken,
                    _indexToken,
                    _isLong
                )
            );
    }

    // for longs: nextAveragePrice = (nextPrice * nextSize)/ (nextSize + delta)
    // for shorts: nextAveragePrice = (nextPrice * nextSize) / (nextSize - delta)
    function getNextAveragePrice(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _nextPrice,
        uint256 _sizeDelta,
        uint256 _lastIncreasedTime,
        uint256 _minProfitTime,
        address _priceFeed,
        uint256 _basisPointsDivisor,
        mapping(address => uint256) storage minProfitBasisPoints
    ) internal view returns (uint256) {
        (bool hasProfit, uint256 delta) = getDelta(
            _indexToken,
            _size,
            _averagePrice,
            _isLong,
            _lastIncreasedTime,
            _minProfitTime,
            _priceFeed,
            _basisPointsDivisor,
            minProfitBasisPoints[_indexToken]
        );
        uint256 nextSize = _size + _sizeDelta;
        uint256 divisor;
        if (_isLong) {
            divisor = hasProfit ? nextSize + delta : nextSize - delta;
        } else {
            divisor = hasProfit ? nextSize - delta : nextSize + delta;
        }
        return (_nextPrice * nextSize) / divisor;
    }

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime,
        uint256 _minProfitTime,
        address _priceFeed,
        uint256 _basisPointsDivisor,
        uint256 _tokenMinProfitBasisPoints
    ) internal view returns (bool, uint256) {
        ValidationLogic.validate(
            _averagePrice > 0,
            VaultErrors.VAULT_INVALID_AVERAGE_PRICE
        );
        uint256 price = _isLong
            ? GenericLogic.getMinPrice(_indexToken, _priceFeed)
            : GenericLogic.getMaxPrice(_indexToken, _priceFeed);
        uint256 priceDelta = _averagePrice > price
            ? _averagePrice - price
            : price - _averagePrice;
        uint256 delta = (_size * priceDelta) / _averagePrice;

        bool hasProfit;

        if (_isLong) {
            hasProfit = price > _averagePrice;
        } else {
            hasProfit = _averagePrice > price;
        }

        // if the minProfitTime has passed then there will be no min profit threshold
        // the min profit threshold helps to prevent front-running issues
        uint256 minBps = block.timestamp > _lastIncreasedTime + _minProfitTime
            ? 0
            : _tokenMinProfitBasisPoints;
        if (hasProfit && delta * _basisPointsDivisor <= _size * minBps) {
            delta = 0;
        }

        return (hasProfit, delta);
    }

    function collectMarginFees(
        address _collateralToken,
        uint256 _sizeDelta,
        uint256 _size,
        uint256 _entryBorrowingRate,
        uint256 _basisPointsDivisor,
        uint256 _marginFeeBasisPoints,
        uint256 _borrowingRatePrecision,
        uint256 _decimals,
        address _priceFeed,
        uint256 _collateralTokenCumulativeBorrowingRates,
        mapping(address => uint256) storage feeReserves
    ) internal returns (uint256) {
        uint256 feeUsd = getPositionFee(
            _sizeDelta,
            _basisPointsDivisor,
            _marginFeeBasisPoints
        );

        uint256 borrowingFee = getBorrowingFee(
            _size,
            _entryBorrowingRate,
            _borrowingRatePrecision,
            _collateralTokenCumulativeBorrowingRates
        );

        feeUsd = feeUsd + borrowingFee;

        uint256 feeTokens = GenericLogic.usdToTokenMin(
            _collateralToken,
            feeUsd,
            _decimals,
            _priceFeed
        );
        feeReserves[_collateralToken] =
            feeReserves[_collateralToken] +
            feeTokens;

        emit CollectMarginFees(_collateralToken, feeUsd, feeTokens);
        return feeUsd;
    }

    function getPositionFee(
        uint256 _sizeDelta,
        uint256 _basisPointsDivisor,
        uint256 _marginFeeBasisPoints
    ) internal pure returns (uint256) {
        if (_sizeDelta == 0) {
            return 0;
        }
        uint256 afterFeeUsd = (_sizeDelta *
            (_basisPointsDivisor - _marginFeeBasisPoints)) /
            _basisPointsDivisor;
        return _sizeDelta - afterFeeUsd;
    }

    function getBorrowingFee(
        uint256 _size,
        uint256 _entryBorrowingRate,
        uint256 _borrowingRatePrecision,
        uint256 _tokenCumulativeBorrowingRates
    ) internal pure returns (uint256) {
        if (_size == 0) {
            return 0;
        }

        uint256 borrowingRate = _tokenCumulativeBorrowingRates -
            _entryBorrowingRate;
        if (borrowingRate == 0) {
            return 0;
        }

        return (_size * borrowingRate) / _borrowingRatePrecision;
    }

    // validateLiquidation returns (state, fees)
    function validateLiquidation(
        address _indexToken,
        bool _isLong,
        bool _raise,
        address _priceFeed,
        uint256 _minProfitBasisPoints,
        uint256 _borrowingRatePrecision,
        uint256 _basisPointsDivisor,
        uint256 _maxLeverage,
        uint256 _collateralTokenCumulativeBorrowingRates,
        DataTypes.Fees memory fees,
        DataTypes.Position memory position
    ) internal view returns (uint256, uint256) {
        (bool hasProfit, uint256 delta) = getDelta(
            _indexToken,
            position.size,
            position.averagePrice,
            _isLong,
            position.lastIncreasedTime,
            fees.minProfitTime,
            _priceFeed,
            _basisPointsDivisor,
            _minProfitBasisPoints
        );
        uint256 marginFees = getBorrowingFee(
            position.size,
            position.entryBorrowingRate,
            _borrowingRatePrecision,
            _collateralTokenCumulativeBorrowingRates
        );
        marginFees =
            marginFees +
            (
                getPositionFee(
                    position.size,
                    _basisPointsDivisor,
                    fees.marginFeeBasisPoints
                )
            );

        if (!hasProfit && position.collateral < delta) {
            if (_raise) {
                revert("Vault: losses exceed collateral");
            }
            return (1, marginFees);
        }

        uint256 remainingCollateral = position.collateral;
        if (!hasProfit) {
            remainingCollateral = position.collateral - delta;
        }

        if (remainingCollateral < marginFees) {
            if (_raise) {
                revert("Vault: fees exceed collateral");
            }
            // cap the fees to the remainingCollateral
            return (1, remainingCollateral);
        }

        if (remainingCollateral < marginFees + fees.liquidationFeeUsd) {
            if (_raise) {
                revert("Vault: liquidation fees exceed collateral");
            }
            return (1, marginFees);
        }

        if (
            remainingCollateral * _maxLeverage <
            position.size * _basisPointsDivisor
        ) {
            if (_raise) {
                revert("Vault: maxLeverage exceeded");
            }
            return (2, marginFees);
        }

        return (0, marginFees);
    }

    // for longs: nextAveragePrice = (nextPrice * nextSize)/ (nextSize + delta)
    // for shorts: nextAveragePrice = (nextPrice * nextSize) / (nextSize - delta)
    function getNextGlobalShortAveragePrice(
        uint256 _nextPrice,
        uint256 _sizeDelta,
        uint256 _tokenGlobalShortSize,
        uint256 _tokenGlobalShortAveragePrice
    ) internal pure returns (uint256) {
        uint256 priceDelta = _tokenGlobalShortAveragePrice > _nextPrice
            ? _tokenGlobalShortAveragePrice - _nextPrice
            : _nextPrice - _tokenGlobalShortAveragePrice;
        uint256 delta = (_tokenGlobalShortSize * priceDelta) /
            _tokenGlobalShortAveragePrice;
        bool hasProfit = _tokenGlobalShortAveragePrice > _nextPrice;

        uint256 nextSize = _tokenGlobalShortSize + _sizeDelta;
        uint256 divisor = hasProfit ? nextSize - delta : nextSize + delta;

        return (_nextPrice * nextSize) / divisor;
    }

    function reduceCollateral(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _basisPointsDivisor,
        uint256 _borrowingRatePrecision,
        uint256 _decimals,
        uint256 _collateralTokenCumulativeBorrowingRates,
        address _priceFeed,
        uint256 _tokenMinProfitBasisPoints,
        uint256 _tokenReservedAmount,
        bytes32 _positionKey,
        DataTypes.Fees memory fees,
        DataTypes.Position storage position,
        mapping(address => uint256) storage poolAmounts,
        mapping(address => uint256) storage feeReserves
    ) internal returns (uint256, uint256) {
        uint256 fee = collectMarginFees(
            _collateralToken,
            _sizeDelta,
            position.size,
            position.entryBorrowingRate,
            _basisPointsDivisor,
            fees.marginFeeBasisPoints,
            _borrowingRatePrecision,
            _decimals,
            _priceFeed,
            _collateralTokenCumulativeBorrowingRates,
            feeReserves
        );
        bool hasProfit;
        uint256 adjustedDelta;

        // scope variables to avoid stack too deep errors
        {
            (bool _hasProfit, uint256 delta) = getDelta(
                _indexToken,
                position.size,
                position.averagePrice,
                _isLong,
                position.lastIncreasedTime,
                fees.minProfitTime,
                _priceFeed,
                _basisPointsDivisor,
                _tokenMinProfitBasisPoints
            );
            hasProfit = _hasProfit;
            // get the proportional change in pnl
            adjustedDelta = (_sizeDelta * delta) / position.size;
        }

        uint256 usdOut;
        // transfer profits out
        if (hasProfit && adjustedDelta > 0) {
            usdOut = adjustedDelta;
            position.realisedPnl = position.realisedPnl + int256(adjustedDelta);

            // pay out realised profits from the pool amount for short positions
            if (!_isLong) {
                uint256 tokenAmount = GenericLogic.usdToTokenMin(
                    _collateralToken,
                    adjustedDelta,
                    _decimals,
                    _priceFeed
                );
                GenericLogic.decreasePoolAmount(
                    _collateralToken,
                    tokenAmount,
                    _tokenReservedAmount,
                    poolAmounts
                );
            }
        }

        if (!hasProfit && adjustedDelta > 0) {
            position.collateral = position.collateral - adjustedDelta;

            // transfer realised losses to the pool for short positions
            // realised losses for long positions are not transferred here as
            // _increasePoolAmount was already called in increasePosition for longs
            if (!_isLong) {
                uint256 tokenAmount = GenericLogic.usdToTokenMin(
                    _collateralToken,
                    adjustedDelta,
                    _decimals,
                    _priceFeed
                );
                GenericLogic.increasePoolAmount(
                    _collateralToken,
                    tokenAmount,
                    poolAmounts
                );
            }

            position.realisedPnl = position.realisedPnl - int256(adjustedDelta);
        }

        // reduce the position's collateral by _collateralDelta
        // transfer _collateralDelta out
        if (_collateralDelta > 0) {
            usdOut = usdOut * _collateralDelta;
            position.collateral = position.collateral - _collateralDelta;
        }

        // if the position will be closed, then transfer the remaining collateral out
        if (position.size == _sizeDelta) {
            usdOut = usdOut + position.collateral;
            position.collateral = 0;
        }

        // if the usdOut is more than the fee then deduct the fee from the usdOut directly
        // else deduct the fee from the position's collateral
        uint256 usdOutAfterFee = usdOut;
        if (usdOut > fee) {
            usdOutAfterFee = usdOut - fee;
        } else {
            position.collateral = position.collateral - fee;
            if (_isLong) {
                uint256 feeTokens = GenericLogic.usdToTokenMin(
                    _collateralToken,
                    fee,
                    _decimals,
                    _priceFeed
                );
                GenericLogic.decreasePoolAmount(
                    _collateralToken,
                    feeTokens,
                    _tokenReservedAmount,
                    poolAmounts
                );
            }
        }

        emit UpdatePnl(_positionKey, hasProfit, adjustedDelta);

        return (usdOut, usdOutAfterFee);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import {ValidationLogic} from "./ValidationLogic.sol";
import {VaultErrors} from "../helpers/VaultErrors.sol";
import {IVaultPriceFeed} from "../../interfaces/IVaultPriceFeed.sol";

import {DataTypes} from "../types/DataTypes.sol";

library SetParametersLogic {
    function setBorrowingRate(
        uint256 minBorrowingRateInterval,
        uint256 maxBorrowingRateFactor,
        DataTypes.BorrowingRate memory params,
        DataTypes.BorrowingRate storage borrowingRate
    ) internal {
        ValidationLogic.validate(
            params.borrowingInterval >= minBorrowingRateInterval,
            VaultErrors.VAULT_INVALID_BORROWING_INTERVALE
        );
        ValidationLogic.validate(
            params.borrowingRateFactor <= maxBorrowingRateFactor,
            VaultErrors.VAULT_INVALID_BORROWING_RATE_FACTOR
        );
        ValidationLogic.validate(
            params.stableBorrowingRateFactor <= maxBorrowingRateFactor,
            VaultErrors.VAULT_INVALID_STABLE_BORROWING_RATE_FACTOR
        );
        borrowingRate.borrowingInterval = params.borrowingInterval;
        borrowingRate.borrowingRateFactor = params.borrowingRateFactor;
        borrowingRate.stableBorrowingRateFactor = params
            .stableBorrowingRateFactor;
    }

    function setFees(
        uint256 maxFeeBasisPoints,
        uint256 maxLiquidationFeeUsd,
        DataTypes.Fees memory params,
        DataTypes.Fees storage fees
    ) internal {
        ValidationLogic.validate(
            params.taxBasisPoints <= maxFeeBasisPoints,
            VaultErrors.VAULT_INVALID_TAX_BASIS_POINTS
        );
        ValidationLogic.validate(
            params.stableTaxBasisPoints <= maxFeeBasisPoints,
            VaultErrors.VAULT_INVALID_STABLE_TAX_BASIS_POINTS
        );
        ValidationLogic.validate(
            params.mintBurnFeeBasisPoints <= maxFeeBasisPoints,
            VaultErrors.VAULT_INVALID_MINT_BURN_FEE_BASIS_POINTS
        );
        ValidationLogic.validate(
            params.swapFeeBasisPoints <= maxFeeBasisPoints,
            VaultErrors.VAULT_INVALID_SWAP_FEE_BASIS_POINTS
        );
        ValidationLogic.validate(
            params.stableSwapFeeBasisPoints <= maxFeeBasisPoints,
            VaultErrors.VAULT_INVALID_STABLE_SWAP_FEE_BASIS_POINTS
        );
        ValidationLogic.validate(
            params.marginFeeBasisPoints <= maxFeeBasisPoints,
            VaultErrors.VAULT_INVALID_MARGIN_FEE_BASIS_POINTS
        );
        ValidationLogic.validate(
            params.liquidationFeeUsd <= maxLiquidationFeeUsd,
            VaultErrors.VAULT_INVALID_LIQUIDATION_FEE_USD
        );
        fees.taxBasisPoints = params.taxBasisPoints;
        fees.stableTaxBasisPoints = params.stableTaxBasisPoints;
        fees.mintBurnFeeBasisPoints = params.mintBurnFeeBasisPoints;
        fees.swapFeeBasisPoints = params.swapFeeBasisPoints;
        fees.stableSwapFeeBasisPoints = params.stableSwapFeeBasisPoints;
        fees.marginFeeBasisPoints = params.marginFeeBasisPoints;
        fees.liquidationFeeUsd = params.liquidationFeeUsd;
        fees.minProfitTime = params.minProfitTime;
        fees.hasDynamicFees = params.hasDynamicFees;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {ValidationLogic} from "./ValidationLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {BorrowingFeeLogic} from "./BorrowingFeeLogic.sol";
import {VaultErrors} from "../helpers/VaultErrors.sol";
import {DataTypes} from "../types/DataTypes.sol";

import {IETHG} from "../../../tokens/interfaces/IETHG.sol";
import {INFTOracleGetter} from "../../BendDAO/interfaces/INFTOracleGetter.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {INToken} from "../../interfaces/INToken.sol";

library SupplyLogic {
    event BuyETHG(
        address account,
        address token,
        uint256 tokenAmount,
        uint256 ethgAmount,
        uint256 feeBasisPoints
    );
    event SellETHG(
        address account,
        address token,
        uint256 ethgAmount,
        uint256 tokenAmount,
        uint256 feeBasisPoints
    );

    function ExecuteBuyETHG(
        address _token,
        address _receiver,
        bool _inManagerMode,
        address _bendOracle,
        address _priceFeed,
        uint256 _pricePrecision,
        address _ethg,
        uint256 _ethgDecimals,
        uint256 _totalTokenWeights,
        uint256 _basisPointsDivisor,
        DataTypes.Fees memory fees,
        DataTypes.BorrowingRate memory borrowingRate,
        mapping(address => bool) storage isManager,
        mapping(address => bool) storage whitelistedTokens,
        mapping(address => bool) storage nftTokens,
        mapping(address => uint256) storage tokenBalances,
        mapping(address => IVault.NftInfo) storage nftInfos,
        mapping(address => uint256) storage cumulativeBorrowingRates,
        mapping(address => uint256) storage lastBorrowingTimes,
        mapping(address => uint256) storage poolAmounts,
        mapping(address => uint256) storage reservedAmounts,
        mapping(address => uint256) storage tokenDecimals,
        mapping(address => uint256) storage maxEthgAmounts,
        mapping(address => uint256) storage ethgAmounts,
        mapping(address => uint256) storage tokenWeights,
        mapping(address => uint256) storage feeReserves
    ) external returns (uint256) {
        ValidationLogic.validateManager(_inManagerMode, isManager);
        ValidationLogic.validateWhitelistedToken(_token, whitelistedTokens);

        uint256 tokenAmount;
        if (nftTokens[_token]) {
            IVault.NftInfo memory nftInfo = nftInfos[_token];
            tokenAmount = GenericLogic.transferIn(
                nftInfo.nftToken,
                tokenBalances
            );
        } else {
            tokenAmount = GenericLogic.transferIn(_token, tokenBalances);
        }

        ValidationLogic.validate(
            tokenAmount > 0,
            VaultErrors.VAULT_INVALID_TOKEN_AMOUNT
        );

        BorrowingFeeLogic.updateCumulativeBorrowingRate(
            DataTypes.UpdateCumulativeBorrowingRateParams({
                collateralToken: _token,
                indexToken: _token,
                borrowingInterval: borrowingRate.borrowingInterval,
                borrowingRateFactor: borrowingRate.borrowingRateFactor,
                collateralTokenPoolAmount: poolAmounts[_token],
                collateralTokenReservedAmount: reservedAmounts[_token]
            }),
            cumulativeBorrowingRates,
            lastBorrowingTimes
        );

        uint256 price = GenericLogic.getMinPrice(_token, _priceFeed);
        if (nftTokens[_token]) {
            uint256 priceBend = INFTOracleGetter(_bendOracle).getAssetPrice(
                _token
            );
            price = price < priceBend ? price : priceBend;
        }

        uint256 ethgAmount = (tokenAmount * price) / _pricePrecision;

        ethgAmount = GenericLogic.adjustForDecimals(
            ethgAmount,
            _token,
            _ethg,
            _ethg,
            _ethgDecimals,
            tokenDecimals
        );
        ValidationLogic.validate(
            ethgAmount > 0,
            VaultErrors.VAULT_INVALID_ETHG_AMOUNT
        );

        uint256 targetEthgAmountToken = GenericLogic.getTargetEthgAmount(
            _ethg,
            tokenWeights[_token],
            _totalTokenWeights
        );

        uint256 feeBasisPoints = GenericLogic.getBuyEthgFeeBasisPoints(
            _token,
            ethgAmount,
            ethgAmounts[_token],
            targetEthgAmountToken,
            fees
        );

        uint256 amountAfterFees = GenericLogic.collectSwapFees(
            GenericLogic.CollectSwapFeesParams({
                token: _token,
                amount: tokenAmount,
                feeBasisPoints: feeBasisPoints,
                basisPointsDivisor: _basisPointsDivisor,
                tokenDecimals: tokenDecimals[_token],
                priceFeed: _priceFeed
            }),
            feeReserves
        );
        uint256 mintAmount = (amountAfterFees * price) / _pricePrecision;
        mintAmount = GenericLogic.adjustForDecimals(
            mintAmount,
            _token,
            _ethg,
            _ethg,
            _ethgDecimals,
            tokenDecimals
        );

        GenericLogic.increaseEthgAmount(
            _token,
            mintAmount,
            maxEthgAmounts[_token],
            ethgAmounts
        );
        GenericLogic.increasePoolAmount(_token, amountAfterFees, poolAmounts);

        IETHG(_ethg).mint(_receiver, mintAmount);

        emit BuyETHG(
            _receiver,
            _token,
            tokenAmount,
            mintAmount,
            feeBasisPoints
        );

        return mintAmount;
    }

    function ExecuteSellETHG(
        address _token,
        address _receiver,
        address _priceFeed,
        uint256 _pricePrecision,
        address _ethg,
        uint256 _ethgDecimals,
        uint256 _totalTokenWeights,
        uint256 _basisPointsDivisor,
        bool _inManagerMode,
        DataTypes.Fees memory fees,
        DataTypes.BorrowingRate memory borrowingRate,
        mapping(address => bool) storage isManager,
        mapping(address => uint256) storage tokenBalances,
        mapping(address => bool) storage whitelistedTokens,
        mapping(address => uint256) storage cumulativeBorrowingRates,
        mapping(address => uint256) storage lastBorrowingTimes,
        mapping(address => uint256) storage poolAmounts,
        mapping(address => uint256) storage reservedAmounts,
        mapping(address => uint256) storage ethgAmounts,
        mapping(address => uint256) storage tokenWeights,
        mapping(address => uint256) storage tokenDecimals,
        mapping(address => uint256) storage feeReserves,
        mapping(address => bool) storage nftTokens,
        mapping(address => IVault.NftInfo) storage nftInfos
    ) external returns (uint256) {
        ValidationLogic.validateManager(_inManagerMode, isManager);
        ValidationLogic.validateWhitelistedToken(_token, whitelistedTokens);

        uint256 ethgAmount = GenericLogic.transferIn(_ethg, tokenBalances);
        ValidationLogic.validate(
            ethgAmount > 0,
            VaultErrors.VAULT_INVALID_ETHG_AMOUNT
        );

        BorrowingFeeLogic.updateCumulativeBorrowingRate(
            DataTypes.UpdateCumulativeBorrowingRateParams({
                collateralToken: _token,
                indexToken: _token,
                borrowingInterval: borrowingRate.borrowingInterval,
                borrowingRateFactor: borrowingRate.borrowingRateFactor,
                collateralTokenPoolAmount: poolAmounts[_token],
                collateralTokenReservedAmount: reservedAmounts[_token]
            }),
            cumulativeBorrowingRates,
            lastBorrowingTimes
        );

        uint256 redemptionAmount = GenericLogic.getRedemptionAmount(
            _token,
            ethgAmount,
            _priceFeed,
            _pricePrecision,
            _ethg,
            _ethgDecimals,
            tokenDecimals
        );
        ValidationLogic.validate(
            redemptionAmount > 0,
            VaultErrors.VAULT_INVALID_REDEMPTION_AMOUNT
        );

        GenericLogic.decreaseEthgAmount(_token, ethgAmount, ethgAmounts);
        GenericLogic.decreasePoolAmount(
            _token,
            redemptionAmount,
            reservedAmounts[_token],
            poolAmounts
        );

        IETHG(_ethg).burn(address(this), ethgAmount);

        // the _transferIn call increased the value of tokenBalances[ethg]
        // usually decreases in token balances are synced by calling _transferOut
        // however, for ethg, the tokens are burnt, so _updateTokenBalance should
        // be manually called to record the decrease in tokens
        GenericLogic.updateTokenBalance(_ethg, tokenBalances);

        uint256 targetEthgAmountToken = GenericLogic.getTargetEthgAmount(
            _ethg,
            tokenWeights[_token],
            _totalTokenWeights
        );

        uint256 feeBasisPoints = GenericLogic.getSellEthgFeeBasisPoints(
            _token,
            ethgAmount,
            ethgAmounts[_token],
            targetEthgAmountToken,
            fees
        );

        uint256 amountOut = GenericLogic.collectSwapFees(
            GenericLogic.CollectSwapFeesParams({
                token: _token,
                amount: redemptionAmount,
                feeBasisPoints: feeBasisPoints,
                basisPointsDivisor: _basisPointsDivisor,
                tokenDecimals: tokenDecimals[_token],
                priceFeed: _priceFeed
            }),
            feeReserves
        );

        ValidationLogic.validate(
            amountOut > 0,
            VaultErrors.VAULT_INVALID_AMOUNT_OUT
        );

        if (nftTokens[_token]) {
            IVault.NftInfo memory nftInfo = nftInfos[_token];
            INToken(nftInfo.nftToken).burn(address(this), amountOut);
        } else {
            GenericLogic.transferOut(
                _token,
                amountOut,
                _receiver,
                tokenBalances
            );
        }

        emit SellETHG(_receiver, _token, ethgAmount, amountOut, feeBasisPoints);

        return amountOut;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {BorrowingFeeLogic} from "./BorrowingFeeLogic.sol";
import {ValidationLogic} from "./ValidationLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {DataTypes} from "../types/DataTypes.sol";

library SwapLogic {
    event Swap(
        address indexed account,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 amountOutAfterFees,
        uint256 feeBasisPoints
    );

    struct ExecuteSwapParams {
        bool isSwapEnabled;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        address receiver;
    }

    function ExecuteSwap(
        DataTypes.SwapParams memory params,
        DataTypes.Fees memory fees,
        DataTypes.BorrowingRate memory borrowingRate,
        mapping(address => uint256) storage cumulativeBorrowingRates,
        mapping(address => uint256) storage lastBorrowingTimes,
        mapping(address => bool) storage whitelistedTokens,
        mapping(address => uint256) storage ethgAmounts,
        mapping(address => uint256) storage poolAmounts,
        mapping(address => uint256) storage reservedAmounts,
        mapping(address => uint256) storage tokenDecimals,
        mapping(address => uint256) storage bufferAmounts,
        mapping(address => uint256) storage feeReserves,
        mapping(address => uint256) storage maxEthgAmounts,
        mapping(address => uint256) storage tokenBalances,
        mapping(address => uint256) storage tokenWeights
    ) external returns (uint256) {
        uint256 amountIn = GenericLogic.transferIn(
            params.tokenIn,
            tokenBalances
        );
        ValidationLogic.validateSwapParams(
            params.isSwapEnabled,
            params.tokenIn,
            params.tokenOut,
            amountIn,
            whitelistedTokens
        );

        BorrowingFeeLogic.updateCumulativeBorrowingRate(
            DataTypes.UpdateCumulativeBorrowingRateParams({
                collateralToken: params.tokenIn,
                indexToken: params.tokenIn,
                borrowingInterval: borrowingRate.borrowingInterval,
                borrowingRateFactor: borrowingRate.borrowingRateFactor,
                collateralTokenPoolAmount: poolAmounts[params.tokenIn],
                collateralTokenReservedAmount: reservedAmounts[params.tokenIn]
            }),
            cumulativeBorrowingRates,
            lastBorrowingTimes
        );
        BorrowingFeeLogic.updateCumulativeBorrowingRate(
            DataTypes.UpdateCumulativeBorrowingRateParams({
                collateralToken: params.tokenOut,
                indexToken: params.tokenOut,
                borrowingInterval: borrowingRate.borrowingInterval,
                borrowingRateFactor: borrowingRate.borrowingRateFactor,
                collateralTokenPoolAmount: poolAmounts[params.tokenOut],
                collateralTokenReservedAmount: reservedAmounts[params.tokenOut]
            }),
            cumulativeBorrowingRates,
            lastBorrowingTimes
        );

        uint256 priceIn = GenericLogic.getMinPrice(
            params.tokenIn,
            params.priceFeed
        );
        uint256 priceOut = GenericLogic.getMaxPrice(
            params.tokenOut,
            params.priceFeed
        );

        uint256 amountOut = (amountIn * priceIn) / priceOut;

        amountOut = GenericLogic.adjustForDecimals(
            amountOut,
            params.tokenIn,
            params.tokenOut,
            params.ethg,
            params.ethgDecimals,
            tokenDecimals
        );

        // adjust ethgAmounts by the same ethgAmount as debt is shifted between the assets
        uint256 ethgAmount = (amountIn * priceIn) / params.pricePrecision;
        ethgAmount = GenericLogic.adjustForDecimals(
            ethgAmount,
            params.tokenIn,
            params.ethg,
            params.ethg,
            params.ethgDecimals,
            tokenDecimals
        );
        uint256 feeBasisPoints = getSwapFeeBasisPoints(
            ethgAmount,
            params.totalTokenWeights,
            params.ethg,
            params.isStableSwap,
            params.tokenIn,
            params.tokenOut,
            fees,
            tokenWeights,
            ethgAmounts
        );
        uint256 amountOutAfterFees = GenericLogic.collectSwapFees(
            GenericLogic.CollectSwapFeesParams({
                token: params.tokenOut,
                amount: amountOut,
                feeBasisPoints: feeBasisPoints,
                basisPointsDivisor: params.basisPointsDivisor,
                tokenDecimals: tokenDecimals[params.tokenOut],
                priceFeed: params.priceFeed
            }),
            feeReserves
        );

        GenericLogic.increaseEthgAmount(
            params.tokenIn,
            ethgAmount,
            maxEthgAmounts[params.tokenIn],
            ethgAmounts
        );
        GenericLogic.decreaseEthgAmount(
            params.tokenOut,
            ethgAmount,
            ethgAmounts
        );

        GenericLogic.increasePoolAmount(params.tokenIn, amountIn, poolAmounts);
        GenericLogic.decreasePoolAmount(
            params.tokenOut,
            amountOut,
            reservedAmounts[params.tokenOut],
            poolAmounts
        );

        ValidationLogic.validateBufferAmount(
            poolAmounts[params.tokenOut],
            bufferAmounts[params.tokenOut]
        );

        GenericLogic.transferOut(
            params.tokenOut,
            amountOutAfterFees,
            params.receiver,
            tokenBalances
        );

        emit Swap(
            params.receiver,
            params.tokenIn,
            params.tokenOut,
            amountIn,
            amountOut,
            amountOutAfterFees,
            feeBasisPoints
        );

        return amountOutAfterFees;
    }

    function getSwapFeeBasisPoints(
        uint256 _ethgDelta,
        uint256 _totalTokenWeights,
        address _ethg,
        bool _isStableSwap,
        address _tokenIn,
        address _tokenOut,
        DataTypes.Fees memory fees,
        mapping(address => uint256) storage tokenWeights,
        mapping(address => uint256) storage ethgAmounts
    ) internal view returns (uint256) {
        uint256 baseBps = _isStableSwap
            ? fees.stableSwapFeeBasisPoints
            : fees.swapFeeBasisPoints;
        uint256 taxBps = _isStableSwap
            ? fees.stableTaxBasisPoints
            : fees.taxBasisPoints;

        uint256 targetEthgAmountTokenIn = GenericLogic.getTargetEthgAmount(
            _ethg,
            tokenWeights[_tokenIn],
            _totalTokenWeights
        );
        uint256 feesBasisPoints0 = GenericLogic.getFeeBasisPoints(
            GenericLogic.FeeBasisPointsParams({
                token: _tokenIn,
                ethgDelta: _ethgDelta,
                feeBasisPoints: baseBps,
                taxBasisPoints: taxBps,
                increment: true,
                hasDynamicFees: fees.hasDynamicFees,
                ethgAmount: ethgAmounts[_tokenIn],
                targetEthgAmount: targetEthgAmountTokenIn
            })
        );
        uint256 targetEthgAmountTokenout = GenericLogic.getTargetEthgAmount(
            _ethg,
            tokenWeights[_tokenOut],
            _totalTokenWeights
        );
        uint256 feesBasisPoints1 = GenericLogic.getFeeBasisPoints(
            GenericLogic.FeeBasisPointsParams({
                token: _tokenOut,
                ethgDelta: _ethgDelta,
                feeBasisPoints: baseBps,
                taxBasisPoints: taxBps,
                increment: false,
                hasDynamicFees: fees.hasDynamicFees,
                ethgAmount: ethgAmounts[_tokenOut],
                targetEthgAmount: targetEthgAmountTokenout
            })
        );
        // use the higher of the two fee basis points
        return
            feesBasisPoints0 > feesBasisPoints1
                ? feesBasisPoints0
                : feesBasisPoints1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {VaultErrors} from "../helpers/VaultErrors.sol";
import {SwapLogic} from "./SwapLogic.sol";

import {DataTypes} from "../types/DataTypes.sol";

library ValidationLogic {
    function validateSwapParams(
        bool _isSwapEnabled,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        mapping(address => bool) storage whitelistedTokens
    ) internal view {
        validate(_amountIn > 0, VaultErrors.VAULT_INVALID_AMOUNT_IN);
        validate(_isSwapEnabled, VaultErrors.VAULT_SWAPS_NOT_ENABLED);
        validate(
            whitelistedTokens[_tokenIn],
            VaultErrors.VAULT_TOKEN_IN_NOT_WHITELISTED
        );
        validate(
            whitelistedTokens[_tokenOut],
            VaultErrors.VAULT_TOKEN_OUT_NOT_WHITELISTED
        );
        validate(_tokenIn != _tokenOut, VaultErrors.VAULT_INVALID_TOKENS);
    }

    function validateIncreasePositionParams(
        DataTypes.IncreasePositionParams memory params,
        mapping(address => mapping(address => bool)) storage approvedRouters,
        mapping(address => bool) storage whitelistedTokens,
        mapping(address => bool) storage stableTokens,
        mapping(address => bool) storage shortableTokens
    ) internal view {
        validateLeverage(params.isLeverageEnabled);
        validateGasPrice(params.maxGasPrice);
        validateRouter(params.account, params.router, approvedRouters);
        validateTokens(
            params.collateralToken,
            params.indexToken,
            params.isLong,
            whitelistedTokens,
            stableTokens,
            shortableTokens
        );

        validateIncreasePosition(
            params.account,
            params.collateralToken,
            params.indexToken,
            params.sizeDelta,
            params.isLong
        );
    }

    function validateDecreasePositionParams(
        DataTypes.DecreasePositionParams memory params,
        mapping(address => mapping(address => bool)) storage approvedRouters
    ) internal view {
        validateGasPrice(params.maxGasPrice);
        validateRouter(params.account, params.router, approvedRouters);
        validateDecreasePosition(
            params.account,
            params.collateralToken,
            params.indexToken,
            params.collateralDelta,
            params.sizeDelta,
            params.isLong,
            params.receiver
        );
    }

    function validateGasPrice(uint256 _maxGasPrice) internal view {
        if (_maxGasPrice == 0) {
            return;
        }
        validate(
            tx.gasprice <= _maxGasPrice,
            VaultErrors.VAULT_MAX_GAS_PRICE_EXCEEDED
        );
    }

    function validateWhitelistedToken(
        address _token,
        mapping(address => bool) storage whitelistedTokens
    ) internal view {
        validate(
            whitelistedTokens[_token],
            VaultErrors.VAULT_TOKEN_IN_NOT_WHITELISTED
        );
    }

    function validateBufferAmount(
        uint256 _poolAmount,
        uint256 _bufferAmount
    ) internal pure {
        validate(
            _poolAmount >= _bufferAmount,
            VaultErrors.VAULT_POOL_AMOUNT_LESS_THAN_BUFFER_AMOUNT
        );
    }

    function validateManager(
        bool _inManagerMode,
        mapping(address => bool) storage isManager
    ) internal view {
        if (_inManagerMode) {
            validate(isManager[msg.sender], VaultErrors.VAULT_FORBIDDEN);
        }
    }

    function validateTokens(
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        mapping(address => bool) storage whitelistedTokens,
        mapping(address => bool) storage stableTokens,
        mapping(address => bool) storage shortableTokens
    ) internal view {
        if (_isLong) {
            validate(
                _collateralToken == _indexToken,
                VaultErrors.VAULT_MISMATCHED_TOKENS
            );
            validate(
                whitelistedTokens[_collateralToken],
                VaultErrors.VAULT_COLLATERAL_TOKEN_NOT_WHITELISTED
            );
            validate(
                !stableTokens[_collateralToken],
                VaultErrors.VAULT_COLLATERAL_TOKEN_MUST_BE_STABLE_TOKEN
            );
            return;
        }

        validate(
            whitelistedTokens[_collateralToken],
            VaultErrors.VAULT_COLLATERAL_TOKEN_NOT_WHITELISTED
        );
        validate(
            stableTokens[_collateralToken],
            VaultErrors.VAULT_COLLATERAL_TOKEN_MUST_BE_STABLE_TOKEN
        );
        validate(
            !stableTokens[_indexToken],
            VaultErrors.VAULT_INDEX_TOKEN_MUST_NOT_BE_STABLE_TOKEN
        );
        validate(
            shortableTokens[_indexToken],
            VaultErrors.VAULT_INDEX_TOKEN_NOT_SHORTABLE
        );
    }

    function validatePosition(
        uint256 _size,
        uint256 _collateral
    ) internal pure {
        if (_size == 0) {
            validate(
                _collateral == 0,
                VaultErrors.VAULT_COLLATERAL_SHOULD_BE_WITHDRAWN
            );
            return;
        }
        validate(
            _size >= _collateral,
            VaultErrors.VAULT_SIZE_MUST_BE_MORE_THAN_COLLATERAL
        );
    }

    function validateRouter(
        address _account,
        address _router,
        mapping(address => mapping(address => bool)) storage approvedRouters
    ) internal view {
        if (msg.sender == _account) {
            return;
        }
        if (msg.sender == _router) {
            return;
        }
        validate(
            approvedRouters[_account][msg.sender],
            VaultErrors.VAULT_INVALID_MSG_SENDER
        );
    }

    function validateLeverage(bool _isLeverageEnabled) internal pure {
        validate(_isLeverageEnabled, VaultErrors.VAULT_LEVERAGE_NOT_ENABLED);
    }

    function validateIncreasePosition(
        address /* _account */,
        address /* _collateralToken */,
        address /* _indexToken */,
        uint256 /* _sizeDelta */,
        bool /* _isLong */
    ) internal pure {
        // no additional validations
    }

    function validateDecreasePosition(
        address /* _account */,
        address /* _collateralToken */,
        address /* _indexToken */,
        uint256 /* _collateralDelta */,
        uint256 /* _sizeDelta */,
        bool /* _isLong */,
        address /* _receiver */
    ) internal pure {
        // no additional validations
    }

    function validate(bool _condition, string memory _errorCode) internal pure {
        require(_condition, _errorCode);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library DataTypes {
    struct Position {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryBorrowingRate;
        uint256 fundingFeeAmountPerSize;
        uint256 reserveAmount;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }

    struct Fees {
        uint256 taxBasisPoints;
        uint256 stableTaxBasisPoints;
        uint256 mintBurnFeeBasisPoints;
        uint256 swapFeeBasisPoints;
        uint256 stableSwapFeeBasisPoints;
        uint256 marginFeeBasisPoints;
        uint256 liquidationFeeUsd;
        uint256 minProfitTime;
        bool hasDynamicFees;
    }

    struct UpdateCumulativeBorrowingRateParams {
        address collateralToken;
        address indexToken;
        uint256 borrowingInterval;
        uint256 borrowingRateFactor;
        uint256 collateralTokenPoolAmount;
        uint256 collateralTokenReservedAmount;
    }

    struct SwapParams {
        bool isSwapEnabled;
        address tokenIn;
        address tokenOut;
        address receiver;
        bool isStableSwap;
        address ethg;
        uint256 ethgDecimals;
        uint256 pricePrecision;
        address priceFeed;
        uint256 basisPointsDivisor;
        uint256 totalTokenWeights;
    }

    struct IncreasePositionParams {
        address account;
        address collateralToken;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        address priceFeed;
        bool isLeverageEnabled;
        uint256 maxGasPrice;
        address router;
        uint256 basisPointsDivisor;
        uint256 borrowingRatePrecision;
        uint256 maxLeverage;
    }

    struct DecreasePositionParams {
        address account;
        address collateralToken;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        address receiver;
        address priceFeed;
        uint256 maxGasPrice;
        address router;
        uint256 basisPointsDivisor;
        uint256 borrowingRatePrecision;
        uint256 maxLeverage;
    }

    struct LiquidatePositionParams {
        address account;
        address collateralToken;
        address indexToken;
        bool isLong;
        address feeReceiver;
        bool inPrivateLiquidationMode;
        address priceFeed;
        uint256 maxGasPrice;
        address router;
        uint256 basisPointsDivisor;
        uint256 borrowingRatePrecision;
        uint256 maxLeverage;
    }

    struct BorrowingRate {
        uint256 borrowingInterval;
        uint256 borrowingRateFactor;
        uint256 stableBorrowingRateFactor;
    }

    struct DepositedNft {
        uint256 tokenId;
        bool isRefinanced;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IVault} from "./interfaces/IVault.sol";

import {ICertiNft} from "./interfaces/ICertiNft.sol";
import {INToken} from "./interfaces/INToken.sol";
import {INFTOracleGetter} from "./BendDAO/interfaces/INFTOracleGetter.sol";

import {SwapLogic} from "./libraries/logic/SwapLogic.sol";
import {SupplyLogic} from "./libraries/logic/SupplyLogic.sol";
import {PositionLogic} from "./libraries/logic/PositionLogic.sol";
import {GenericLogic} from "./libraries/logic/GenericLogic.sol";
import {ValidationLogic} from "./libraries/logic/ValidationLogic.sol";
import {SetParametersLogic} from "./libraries/logic/SetParametersLogic.sol";

import {VaultErrors} from "./libraries/helpers/VaultErrors.sol";

import {DataTypes} from "./libraries/types/DataTypes.sol";

contract Vault is OwnableUpgradeable, ReentrancyGuardUpgradeable, IVault {
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant BORROWING_RATE_PRECISION = 1000000;
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant MIN_LEVERAGE = 10000; // 1x
    uint256 public constant ETHG_DECIMALS = 18;
    uint256 public constant MAX_FEE_BASIS_POINTS = 500; // 5%
    uint256 public constant MAX_LIQUIDATION_FEE_USD = 100 * PRICE_PRECISION; // 100 USD
    uint256 public constant MIN_BORROWING_RATE_INTERVAL = 1 hours;
    uint256 public constant MAX_BORROWING_RATE_FACTOR = 10000; // 1%

    bool public override isSwapEnabled = true;
    bool public override isLeverageEnabled = true;

    address public override router;
    address public override priceFeed;

    address public override ethg;
    INFTOracleGetter public bendOracle; // BendDAO oracle

    uint256 public override whitelistedTokenCount;

    uint256 public override maxLeverage = 50 * 10000; // 50x

    DataTypes.Fees public fees;

    DataTypes.BorrowingRate public borrowingRate;

    uint256 public override totalTokenWeights;

    bool public override inManagerMode = false;
    bool public override inPrivateLiquidationMode = false;

    uint256 public override maxGasPrice;

    mapping(address => mapping(address => bool))
        public
        override approvedRouters;
    mapping(address => bool) public override isLiquidator;
    mapping(address => bool) public override isManager;

    address[] public override allWhitelistedTokens;

    mapping(address => bool) public override whitelistedTokens;
    mapping(address => uint256) public override tokenDecimals;
    mapping(address => uint256) public override minProfitBasisPoints;
    mapping(address => bool) public override stableTokens;
    mapping(address => bool) public override shortableTokens;
    mapping(address => bool) public override nftTokens;

    // tokenBalances is used only to determine _transferIn values
    mapping(address => uint256) public override tokenBalances;

    // tokenWeights allows customisation of index composition
    mapping(address => uint256) public override tokenWeights;

    // ethgAmounts tracks the amount of ETHG debt for each whitelisted token
    mapping(address => uint256) public override ethgAmounts;

    // maxEthgAmounts allows setting a max amount of ETHG debt for a token
    mapping(address => uint256) public override maxEthgAmounts;

    // poolAmounts tracks the number of received tokens that can be used for leverage
    // this is tracked separately from tokenBalances to exclude funds that are deposited as margin collateral
    mapping(address => uint256) public override poolAmounts;

    // reservedAmounts tracks the number of tokens reserved for open leverage positions
    mapping(address => uint256) public override reservedAmounts;

    // bufferAmounts allows specification of an amount to exclude from swaps
    // this can be used to ensure a certain amount of liquidity is available for leverage positions
    mapping(address => uint256) public override bufferAmounts;

    // guaranteedUsd tracks the amount of USD that is "guaranteed" by opened leverage positions
    // this value is used to calculate the redemption values for selling of ETHG
    // this is an estimated amount, it is possible for the actual guaranteed value to be lower
    // in the case of sudden price decreases, the guaranteed value should be corrected
    // after liquidations are carried out
    mapping(address => uint256) public override guaranteedUsd;

    // cumulativeBorrowingRates tracks the borrowing rates based on utilization
    mapping(address => uint256) public override cumulativeBorrowingRates;
    // lastBorrowingTimes tracks the last time borrowing was updated for a token
    mapping(address => uint256) public override lastBorrowingTimes;

    // positions tracks all open positions
    mapping(bytes32 => DataTypes.Position) public positions;

    // feeReserves tracks the amount of fees per token
    mapping(address => uint256) public override feeReserves;

    mapping(address => uint256) public override globalShortSizes;
    mapping(address => uint256) public override globalShortAveragePrices;
    mapping(address => uint256) public override maxGlobalShortSizes;

    mapping(address => NftInfo) public nftInfos;

    mapping(address => mapping(address => DataTypes.DepositedNft[]))
        public userDepositedNfts;
    address[] public override nftUsers;
    address public refinance;
    address public positionRouter;

    modifier onlyRefinance() {
        require(msg.sender == refinance, "refinance: forbidden");
        _;
    }

    modifier onlyPositionRouter() {
        require(msg.sender == positionRouter, "swap: forbidden");
        _;
    }

    function initialize(
        address _router,
        address _ethg,
        address _priceFeed,
        address _bendOracle,
        address _refinance
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        router = _router;
        ethg = _ethg;
        priceFeed = _priceFeed;
        bendOracle = INFTOracleGetter(_bendOracle);
        refinance = _refinance;
    }

    function allWhitelistedTokensLength()
        external
        view
        override
        returns (uint256)
    {
        return allWhitelistedTokens.length;
    }

    function setInManagerMode(bool _inManagerMode) external override onlyOwner {
        inManagerMode = _inManagerMode;
    }

    function setManager(
        address _manager,
        bool _isManager
    ) external override onlyOwner {
        isManager[_manager] = _isManager;
    }

    function setInPrivateLiquidationMode(
        bool _inPrivateLiquidationMode
    ) external override onlyOwner {
        inPrivateLiquidationMode = _inPrivateLiquidationMode;
    }

    function setLiquidator(
        address _liquidator,
        bool _isActive
    ) external override onlyOwner {
        isLiquidator[_liquidator] = _isActive;
    }

    function setIsSwapEnabled(bool _isSwapEnabled) external override onlyOwner {
        isSwapEnabled = _isSwapEnabled;
    }

    function setIsLeverageEnabled(
        bool _isLeverageEnabled
    ) external override onlyOwner {
        isLeverageEnabled = _isLeverageEnabled;
    }

    function setMaxGasPrice(uint256 _maxGasPrice) external override onlyOwner {
        maxGasPrice = _maxGasPrice;
    }

    function setPriceFeed(address _priceFeed) external override onlyOwner {
        priceFeed = _priceFeed;
    }

    function setMaxLeverage(uint256 _maxLeverage) external override onlyOwner {
        ValidationLogic.validate(
            _maxLeverage > MIN_LEVERAGE,
            VaultErrors.VAULT_INVALID_MAXLEVERAGE
        );
        maxLeverage = _maxLeverage;
    }

    function setBufferAmount(
        address _token,
        uint256 _amount
    ) external override onlyOwner {
        bufferAmounts[_token] = _amount;
    }

    function setMaxGlobalShortSize(
        address _token,
        uint256 _amount
    ) external override onlyOwner {
        maxGlobalShortSizes[_token] = _amount;
    }

    function setFees(DataTypes.Fees memory params) external override onlyOwner {
        SetParametersLogic.setFees(
            MAX_FEE_BASIS_POINTS,
            MAX_LIQUIDATION_FEE_USD,
            params,
            fees
        );
    }

    function getFees() external view returns (DataTypes.Fees memory) {
        return fees;
    }

    function setBorrowingRate(
        DataTypes.BorrowingRate memory params
    ) external override onlyOwner {
        SetParametersLogic.setBorrowingRate(
            MIN_BORROWING_RATE_INTERVAL,
            MAX_BORROWING_RATE_FACTOR,
            params,
            borrowingRate
        );
    }

    function getBorrowingRate()
        external
        view
        returns (DataTypes.BorrowingRate memory)
    {
        return borrowingRate;
    }

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxEthgAmount,
        bool _isStable,
        bool _isShortable,
        bool _isNft
    ) external override onlyOwner {
        // increment token count for the first time
        if (!whitelistedTokens[_token]) {
            whitelistedTokenCount = whitelistedTokenCount + 1;
            allWhitelistedTokens.push(_token);
        }
        uint256 _totalTokenWeights = totalTokenWeights;
        _totalTokenWeights = _totalTokenWeights - tokenWeights[_token];
        whitelistedTokens[_token] = true;
        tokenDecimals[_token] = _tokenDecimals;
        tokenWeights[_token] = _tokenWeight;
        minProfitBasisPoints[_token] = _minProfitBps;
        maxEthgAmounts[_token] = _maxEthgAmount;
        stableTokens[_token] = _isStable;
        shortableTokens[_token] = _isShortable;
        nftTokens[_token] = _isNft;
        totalTokenWeights = _totalTokenWeights + _tokenWeight;
        // validate price feed
        getMaxPrice(_token);
    }

    function clearTokenConfig(address _token) external onlyOwner {
        ValidationLogic.validate(
            whitelistedTokens[_token],
            VaultErrors.VAULT_TOKEN_NOT_WHITELISTED
        );
        totalTokenWeights = totalTokenWeights - tokenWeights[_token];
        delete whitelistedTokens[_token];
        delete tokenDecimals[_token];
        delete tokenWeights[_token];
        delete minProfitBasisPoints[_token];
        delete maxEthgAmounts[_token];
        delete stableTokens[_token];
        delete shortableTokens[_token];
        delete nftTokens[_token];
        whitelistedTokenCount = whitelistedTokenCount - 1;
    }

    function withdrawFees(
        address _token,
        address _receiver
    ) external override onlyOwner returns (uint256) {
        uint256 amount = feeReserves[_token];
        if (amount == 0) {
            return 0;
        }
        feeReserves[_token] = 0;
        GenericLogic.transferOut(_token, amount, _receiver, tokenBalances);
        return amount;
    }

    function addRouter(address _router) external {
        approvedRouters[msg.sender][_router] = true;
    }

    function removeRouter(address _router) external {
        approvedRouters[msg.sender][_router] = false;
    }

    function setEthgAmount(
        address _token,
        uint256 _amount
    ) external override onlyOwner {
        uint256 ethgAmount = ethgAmounts[_token];
        if (_amount > ethgAmount) {
            GenericLogic.increaseEthgAmount(
                _token,
                _amount - ethgAmount,
                maxEthgAmounts[_token],
                ethgAmounts
            );
            return;
        }
        GenericLogic.decreaseEthgAmount(
            _token,
            ethgAmount - _amount,
            ethgAmounts
        );
    }

    function setNftInfos(
        address[] memory _nfts,
        address[] memory _certiNfts,
        uint256[] memory _nftLtvs
    ) external override onlyOwner {
        require(
            _nfts.length == _certiNfts.length &&
                _nfts.length == _nftLtvs.length,
            "inconsistent length"
        );
        for (uint256 i = 0; i < _nfts.length; i++) {
            NftInfo memory nftInfo = NftInfo(
                _nfts[i],
                _certiNfts[i],
                _nftLtvs[i]
            );
            nftInfos[_nfts[i]] = nftInfo;
        }
    }

    // the governance controlling this function should have a timelock
    function upgradeVault(
        address _newVault,
        address _token,
        uint256 _amount
    ) external onlyOwner {
        IERC20Upgradeable(_token).safeTransfer(_newVault, _amount);
    }

    // deposit into the pool without minting ETHG tokens
    // useful in allowing the pool to become over-collaterised
    function directPoolDeposit(address _token) external override nonReentrant {
        ValidationLogic.validate(
            whitelistedTokens[_token],
            VaultErrors.VAULT_TOKEN_NOT_WHITELISTED
        );
        uint256 tokenAmount = GenericLogic.transferIn(_token, tokenBalances);
        ValidationLogic.validate(
            tokenAmount > 0,
            VaultErrors.VAULT_INVALID_TOKEN_AMOUNT
        );
        GenericLogic.increasePoolAmount(_token, tokenAmount, poolAmounts);
        emit DirectPoolDeposit(_token, tokenAmount);
    }

    function buyETHG(
        address _token,
        address _receiver
    ) external override nonReentrant returns (uint256) {
        return
            SupplyLogic.ExecuteBuyETHG(
                _token,
                _receiver,
                inManagerMode,
                address(bendOracle),
                priceFeed,
                PRICE_PRECISION,
                ethg,
                ETHG_DECIMALS,
                totalTokenWeights,
                BASIS_POINTS_DIVISOR,
                fees,
                borrowingRate,
                isManager,
                whitelistedTokens,
                nftTokens,
                tokenBalances,
                nftInfos,
                cumulativeBorrowingRates,
                lastBorrowingTimes,
                poolAmounts,
                reservedAmounts,
                tokenDecimals,
                maxEthgAmounts,
                ethgAmounts,
                tokenWeights,
                feeReserves
            );
    }

    function sellETHG(
        address _token,
        address _receiver
    ) external override nonReentrant returns (uint256) {
        return
            SupplyLogic.ExecuteSellETHG(
                _token,
                _receiver,
                priceFeed,
                PRICE_PRECISION,
                ethg,
                ETHG_DECIMALS,
                totalTokenWeights,
                BASIS_POINTS_DIVISOR,
                inManagerMode,
                fees,
                borrowingRate,
                isManager,
                tokenBalances,
                whitelistedTokens,
                cumulativeBorrowingRates,
                lastBorrowingTimes,
                poolAmounts,
                reservedAmounts,
                ethgAmounts,
                tokenWeights,
                tokenDecimals,
                feeReserves,
                nftTokens,
                nftInfos
            );
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external override onlyPositionRouter nonReentrant returns (uint256) {
        bool isStableSwap = stableTokens[_tokenIn] && stableTokens[_tokenOut];
        return
            SwapLogic.ExecuteSwap(
                DataTypes.SwapParams({
                    isSwapEnabled: isSwapEnabled,
                    tokenIn: _tokenIn,
                    tokenOut: _tokenOut,
                    receiver: _receiver,
                    isStableSwap: isStableSwap,
                    ethg: ethg,
                    ethgDecimals: ETHG_DECIMALS,
                    pricePrecision: PRICE_PRECISION,
                    priceFeed: priceFeed,
                    basisPointsDivisor: BASIS_POINTS_DIVISOR,
                    totalTokenWeights: totalTokenWeights
                }),
                fees,
                borrowingRate,
                cumulativeBorrowingRates,
                lastBorrowingTimes,
                whitelistedTokens,
                ethgAmounts,
                poolAmounts,
                reservedAmounts,
                tokenDecimals,
                bufferAmounts,
                feeReserves,
                maxEthgAmounts,
                tokenBalances,
                tokenWeights
            );
    }

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external override nonReentrant {
        PositionLogic.increasePosition(
            DataTypes.IncreasePositionParams({
                account: _account,
                collateralToken: _collateralToken,
                indexToken: _indexToken,
                sizeDelta: _sizeDelta,
                isLong: _isLong,
                priceFeed: priceFeed,
                isLeverageEnabled: isLeverageEnabled,
                maxGasPrice: maxGasPrice,
                router: router,
                basisPointsDivisor: BASIS_POINTS_DIVISOR,
                borrowingRatePrecision: BORROWING_RATE_PRECISION,
                maxLeverage: maxLeverage
            }),
            fees,
            borrowingRate,
            minProfitBasisPoints,
            approvedRouters,
            whitelistedTokens,
            stableTokens,
            shortableTokens,
            positions,
            cumulativeBorrowingRates,
            lastBorrowingTimes,
            poolAmounts,
            reservedAmounts,
            tokenBalances,
            tokenDecimals,
            guaranteedUsd,
            globalShortSizes,
            globalShortAveragePrices,
            maxGlobalShortSizes,
            feeReserves
        );
    }

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external override nonReentrant returns (uint256) {
        return
            PositionLogic.decreasePosition(
                DataTypes.DecreasePositionParams({
                    account: _account,
                    collateralToken: _collateralToken,
                    indexToken: _indexToken,
                    collateralDelta: _collateralDelta,
                    sizeDelta: _sizeDelta,
                    isLong: _isLong,
                    receiver: _receiver,
                    priceFeed: priceFeed,
                    maxGasPrice: maxGasPrice,
                    router: router,
                    basisPointsDivisor: BASIS_POINTS_DIVISOR,
                    borrowingRatePrecision: BORROWING_RATE_PRECISION,
                    maxLeverage: maxLeverage
                }),
                fees,
                borrowingRate,
                approvedRouters,
                cumulativeBorrowingRates,
                lastBorrowingTimes,
                poolAmounts,
                reservedAmounts,
                positions,
                feeReserves,
                minProfitBasisPoints,
                tokenDecimals,
                guaranteedUsd,
                globalShortSizes,
                tokenBalances
            );
    }

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external override nonReentrant {
        PositionLogic.liquidatePosition(
            DataTypes.LiquidatePositionParams({
                account: _account,
                collateralToken: _collateralToken,
                indexToken: _indexToken,
                isLong: _isLong,
                feeReceiver: _feeReceiver,
                inPrivateLiquidationMode: inPrivateLiquidationMode,
                priceFeed: priceFeed,
                maxGasPrice: maxGasPrice,
                router: router,
                basisPointsDivisor: BASIS_POINTS_DIVISOR,
                borrowingRatePrecision: BORROWING_RATE_PRECISION,
                maxLeverage: maxLeverage
            }),
            fees,
            borrowingRate,
            approvedRouters,
            cumulativeBorrowingRates,
            lastBorrowingTimes,
            poolAmounts,
            reservedAmounts,
            positions,
            feeReserves,
            minProfitBasisPoints,
            tokenDecimals,
            guaranteedUsd,
            globalShortSizes,
            tokenBalances,
            isLiquidator
        );
    }

    function getMaxPrice(
        address _token
    ) public view override returns (uint256) {
        return GenericLogic.getMaxPrice(_token, priceFeed);
    }

    function getMinPrice(
        address _token
    ) external view override returns (uint256) {
        return GenericLogic.getMinPrice(_token, priceFeed);
    }

    function getRedemptionCollateral(
        address _token
    ) public view returns (uint256) {
        if (stableTokens[_token]) {
            return poolAmounts[_token];
        }
        uint256 collateral = GenericLogic.usdToTokenMin(
            _token,
            guaranteedUsd[_token],
            tokenDecimals[_token],
            priceFeed
        );
        return collateral + poolAmounts[_token] - reservedAmounts[_token];
    }

    function getRedemptionCollateralUsd(
        address _token
    ) public view returns (uint256) {
        return
            GenericLogic.tokenToUsdMin(
                _token,
                getRedemptionCollateral(_token),
                tokenDecimals[_token],
                priceFeed
            );
    }

    function getUtilisation(address _token) public view returns (uint256) {
        uint256 poolAmount = poolAmounts[_token];
        if (poolAmount == 0) {
            return 0;
        }
        return
            (reservedAmounts[_token] * BORROWING_RATE_PRECISION) / poolAmount;
    }

    function getPositionLeverage(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) public view returns (uint256) {
        bytes32 key = PositionLogic.getPositionKey(
            _account,
            _collateralToken,
            _indexToken,
            _isLong
        );
        DataTypes.Position memory position = positions[key];
        ValidationLogic.validate(
            position.collateral > 0,
            VaultErrors.VAULT_INVALID_POSITION
        );
        return (position.size * BASIS_POINTS_DIVISOR) / position.collateral;
    }

    function getGlobalShortDelta(
        address _token
    ) public view returns (bool, uint256) {
        uint256 size = globalShortSizes[_token];
        if (size == 0) {
            return (false, 0);
        }
        uint256 nextPrice = getMaxPrice(_token);
        uint256 averagePrice = globalShortAveragePrices[_token];
        uint256 priceDelta = averagePrice > nextPrice
            ? averagePrice - nextPrice
            : nextPrice - averagePrice;
        uint256 delta = (size * priceDelta) / averagePrice;
        bool hasProfit = averagePrice > nextPrice;
        return (hasProfit, delta);
    }

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256) {
        bytes32 key = PositionLogic.getPositionKey(
            _account,
            _collateralToken,
            _indexToken,
            _isLong
        );
        DataTypes.Position memory position = positions[key];
        return
            getDelta(
                _indexToken,
                position.size,
                position.averagePrice,
                _isLong,
                position.lastIncreasedTime
            );
    }

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) public view override returns (bool, uint256) {
        return
            PositionLogic.getDelta(
                _indexToken,
                _size,
                _averagePrice,
                _isLong,
                _lastIncreasedTime,
                fees.minProfitTime,
                priceFeed,
                BASIS_POINTS_DIVISOR,
                minProfitBasisPoints[_indexToken]
            );
    }

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        )
    {
        bytes32 key = PositionLogic.getPositionKey(
            _account,
            _collateralToken,
            _indexToken,
            _isLong
        );
        DataTypes.Position memory position = positions[key];
        uint256 realisedPnl = position.realisedPnl > 0
            ? uint256(position.realisedPnl)
            : uint256(-position.realisedPnl);
        return (
            position.size, // 0
            position.collateral, // 1
            position.averagePrice, // 2
            position.entryBorrowingRate, // 3
            position.reserveAmount, // 4
            realisedPnl, // 5
            position.realisedPnl >= 0, // 6
            position.lastIncreasedTime // 7
        );
    }

    function getRedemptionAmount(
        address _token,
        uint256 _ethgAmount
    ) external view override returns (uint256) {
        return
            GenericLogic.getRedemptionAmount(
                _token,
                _ethgAmount,
                priceFeed,
                PRICE_PRECISION,
                ethg,
                ETHG_DECIMALS,
                tokenDecimals
            );
    }

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) public view override returns (uint256) {
        return
            GenericLogic.tokenToUsdMin(
                _token,
                _tokenAmount,
                tokenDecimals[_token],
                priceFeed
            );
    }

    function mintCNft(
        address _cNft,
        address _to,
        uint256 _tokenId,
        uint256 _ltv
    ) external {
        ValidationLogic.validateManager(inManagerMode, isManager);
        ICertiNft(_cNft).mint(_to, _tokenId, _ltv);
    }

    function burnCNft(address _cNft, uint256 _tokenId) external override {
        ValidationLogic.validateManager(inManagerMode, isManager);
        ICertiNft(_cNft).burn(_tokenId);
    }

    function mintNToken(address _nToken, uint256 _amount) external override {
        ValidationLogic.validateManager(inManagerMode, isManager);
        INToken(_nToken).mint(address(this), _amount);
    }

    function burnNToken(address _nToken, uint256 _amount) external override {
        ValidationLogic.validateManager(inManagerMode, isManager);
        INToken(_nToken).burn(address(this), _amount);
    }

    function getBendDAOAssetPrice(
        address _nft
    ) external view returns (uint256) {
        uint256 price = INFTOracleGetter(bendOracle).getAssetPrice(_nft);
        return price;
    }

    function addNftToUser(
        address _user,
        address _nft,
        uint256 _tokenId
    ) external {
        ValidationLogic.validateManager(inManagerMode, isManager);
        _addNftToUser(_user, _nft, _tokenId);
    }

    function _addNftToUser(
        address _user,
        address _nft,
        uint256 _tokenId
    ) internal {
        uint256 length = nftUsers.length;
        bool userExit;
        for (uint256 i = 0; i < length; i++) {
            if (nftUsers[i] == _user) {
                userExit = true;
                break;
            }
        }
        if (!userExit) {
            nftUsers.push(_user);
        }
        bool tokenExit;
        DataTypes.DepositedNft[] storage tokenIds = userDepositedNfts[_user][
            _nft
        ];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i].tokenId == _tokenId) {
                tokenExit = true;
                break;
            }
        }
        if (!tokenExit) {
            DataTypes.DepositedNft memory depositedNft = DataTypes
                .DepositedNft({isRefinanced: false, tokenId: _tokenId});
            tokenIds.push(depositedNft);
            userDepositedNfts[_user][_nft] = tokenIds;
        }
    }

    function removeNftFromUser(
        address _user,
        address _nft,
        uint256 _tokenId
    ) external {
        ValidationLogic.validateManager(inManagerMode, isManager);
        _removeNftFromUser(_user, _nft, _tokenId);
    }

    function _removeNftFromUser(
        address _user,
        address _nft,
        uint256 _tokenId
    ) internal {
        uint256 length = nftUsers.length;
        bool userExit;
        for (uint256 i = 0; i < length; i++) {
            if (nftUsers[i] == _user) {
                userExit = true;
                break;
            }
        }
        require(userExit, "Vault: user not exit");
        bool tokenExit;
        DataTypes.DepositedNft[] storage tokenIds = userDepositedNfts[_user][
            _nft
        ];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i].tokenId == _tokenId) {
                userExit = true;
                tokenIds[i] = tokenIds[length - 1];
                tokenIds.pop();
                userDepositedNfts[_user][_nft] = tokenIds;
                break;
            }
        }
        require(tokenExit, "Vault: nft not exit");
    }

    function isNftDepsoitedForUser(
        address _user,
        address _nft,
        uint256 _tokenId
    ) external view override returns (bool) {
        DataTypes.DepositedNft[] memory userDepositedNft = userDepositedNfts[
            _user
        ][_nft];
        for (uint256 i = 0; i < userDepositedNft.length; i++) {
            if (userDepositedNft[i].tokenId == _tokenId) {
                if (!userDepositedNft[i].isRefinanced) {
                    return true;
                }
            }
        }
        return false;
    }

    function getFeeWhenRedeemNft(
        address _token,
        uint256 _ethgAmount
    ) external view override returns (uint256) {
        return
            GenericLogic.getFeeWhenRedeemNft(
                _token,
                _ethgAmount,
                priceFeed,
                PRICE_PRECISION,
                ethg,
                ETHG_DECIMALS,
                tokenWeights[_token],
                totalTokenWeights,
                ethgAmounts[_token],
                BASIS_POINTS_DIVISOR,
                fees,
                tokenDecimals
            );
    }

    function updateNftRefinanceStatus(
        address _user,
        address _nft,
        uint256 _tokenId
    ) external view onlyRefinance {
        DataTypes.DepositedNft[] memory depositedNfts = userDepositedNfts[
            _user
        ][_nft];
        for (uint256 i = 0; i < depositedNfts.length; i++) {
            if (depositedNfts[i].tokenId == _tokenId) {
                depositedNfts[i].isRefinanced = true;
            }
        }
    }

    function nftUsersLength() external view override returns (uint256) {
        return nftUsers.length;
    }

    function getUserTokenIds(
        address _user,
        address _nft
    ) external view override returns (DataTypes.DepositedNft[] memory) {
        return userDepositedNfts[_user][_nft];
    }

    function getNftInfo(
        address _nft
    ) external view override returns (NftInfo memory) {
        return nftInfos[_nft];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IETHG {
    function addVault(address _vault) external;
    function removeVault(address _vault) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}