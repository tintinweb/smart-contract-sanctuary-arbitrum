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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./interfaces/IUser.sol";
import "./interfaces/ILYNKNFT.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IUser.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";


contract DBContract is OwnableUpgradeable {


    /**************************************************************************
     *****  Common fields  ****************************************************
     **************************************************************************/
    address immutable public USDT_TOKEN;

    address public LRT_TOKEN;
    address public AP_TOKEN;
    address public STAKING;
    address public USER_INFO;
    address public LYNKNFT;
    address public STAKING_LYNKNFT;
    address public LISTED_LYNKNFT;
    address public MARKET;
    address public TEAM_ADDR;
    address public operator;

    /**************************************************************************
     *****  AlynNFT fields  ***************************************************
     **************************************************************************/
    uint256[] public mintPrices;
    uint256 public maxMintPerDayPerAddress;
    string public baseTokenURI;
    uint256[][] public attributeLevelThreshold;
    // @Deprecated
    uint256 public maxVAAddPerDayPerToken;

    /**************************************************************************
     *****  Market fields  ****************************************************
     **************************************************************************/
    address[] public acceptTokens;
    uint256 public sellingLevelLimit;
    uint256 public tradingFee;

    /**************************************************************************
     *****  User fields  ******************************************************
     **************************************************************************/
    address public rootAddress;
    uint256[] public directRequirements;
    uint256[] public performanceRequirements;
    uint256[] public socialRewardRates;
    uint256 public contributionRewardThreshold;
    uint256[] public contributionRewardAmounts;
    uint256 public maxInvitationLevel;
    mapping(uint256 => uint256[]) public communityRewardRates;
    uint256 public achievementRewardLevelThreshold;
    uint256 public achievementRewardDurationThreshold;
    uint256[] public achievementRewardAmounts;

    /**************************************************************************
     *****  APToken fields  ***************************************************
     **************************************************************************/
    uint256[][] public sellingPackages;

    uint256 public duration;

    uint256[] public maxVAAddPerDayPerTokens;
    uint256 public performanceThreshold;

    // early bird plan, id range: [startId, endId)
    uint256 public earlyBirdInitCA;
    uint256 public earlyBirdMintStartId;
    uint256 public earlyBirdMintEndId;
    address public earlyBirdMintPayment;
    uint256 public earlyBirdMintPriceInPayment;
    bool public earlyBirdMintEnable;
    bool public commonMintEnable;

    uint256 public wlNum;
    mapping(address => bool) public earlyBirdMintWlOf;

    uint256 public lrtPriceInLYNK;


    address[] public revADDR;

    // v2 
    uint256[][] public mintNode;
    bool public nftMintEnable;

    /**
     * @dev Throws if called by any account other than the operator.
     */
    modifier onlyOperator() {
        require(operator == _msgSender(), "DBContract: caller is not the operator");
        _;
    }

    constructor(address _usdtToken) {
        USDT_TOKEN = _usdtToken;
    }

    function __DBContract_init(address[] calldata _addresses) public initializer {
        __DBContract_init_unchained(_addresses);
        __Ownable_init();
    }

    function __DBContract_init_unchained(address[] calldata _addresses) private {
        _setAddresses(_addresses);
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function setAddresses(address[] calldata _addresses) external onlyOperator {
        _setAddresses(_addresses);
    }


    /**************************************************************************
     *****  AlynNFT Manager  **************************************************
     **************************************************************************/
    function setMintPrices(uint256[] calldata _mintPrices) external onlyOperator {
        require(_mintPrices.length == 3, 'DBContract: length mismatch.');
        delete mintPrices;

        mintPrices = _mintPrices;
    }

    function setMaxMintPerDayPerAddress(uint256 _maxMintPerDayPerAddress) external onlyOperator {
        maxMintPerDayPerAddress = _maxMintPerDayPerAddress;
    }

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOperator {
        baseTokenURI = _baseTokenURI;
    }

    function setEarlyBirdInitCA(uint256 _earlyBirdInitCA) external onlyOperator {
        earlyBirdInitCA = _earlyBirdInitCA;
    }

    function setEarlyBirdMintIdRange(uint256 _earlyBirdMintStartId, uint256 _earlyBirdMintEndId) external onlyOperator {
        require(_earlyBirdMintEndId > _earlyBirdMintStartId, 'DBContract: invalid id range.');
        earlyBirdMintStartId = _earlyBirdMintStartId;
        earlyBirdMintEndId = _earlyBirdMintEndId;
    }

    function setEarlyBirdMintPrice(address _earlyBirdMintPayment, uint256 _earlyBirdMintPriceInPayment) external onlyOperator {
        require(_earlyBirdMintPayment != address(0), 'DBContract: payment cannot be 0.');
        earlyBirdMintPayment = _earlyBirdMintPayment;
        earlyBirdMintPriceInPayment = _earlyBirdMintPriceInPayment;
    }

    function setSwitch(bool _earlyBirdMintEnable, bool _commonMintEnable) external onlyOperator {
        earlyBirdMintEnable = _earlyBirdMintEnable;
        commonMintEnable = _commonMintEnable;
    }

    function setWlNum(uint256 _wlNum) external onlyOperator {
        // require(wlNum == 0);
        wlNum = _wlNum;
    }

    function setWls(address[] calldata _wls) external onlyOperator {
        for (uint i = 0; i < _wls.length; i++) {
            earlyBirdMintWlOf[_wls[i]] = true;
            if (!IUser(USER_INFO).isValidUser(_wls[i])) {
                IUser(USER_INFO).registerByEarlyPlan(_wls[i], rootAddress);
            }
        }
    }

    /**
     * CA: [100, 500, 1000 ... ]
     */
    function setAttributeLevelThreshold(ILYNKNFT.Attribute _attr, uint256[] calldata _thresholds) external onlyOperator {
        require(uint256(_attr) <= attributeLevelThreshold.length, 'DBContract: length mismatch.');

        for (uint256 index; index < _thresholds.length; index++) {
            if (index > 0) {
                require(_thresholds[index] >= _thresholds[index - 1], 'DBContract: invalid thresholds.');
            }
        }

        if (attributeLevelThreshold.length == uint256(_attr)) {
            attributeLevelThreshold.push(_thresholds);
        } else {
            delete attributeLevelThreshold[uint256(_attr)];
            attributeLevelThreshold[uint256(_attr)] = _thresholds;
        }
    }

    // @Deprecated
    function setMaxVAAddPerDayPerToken(uint256 _maxVAAddPerDayPerToken) external onlyOperator {
        maxVAAddPerDayPerToken = _maxVAAddPerDayPerToken;
    }

    function setMaxVAAddPerDayPerTokens(uint256[] calldata _maxVAAddPerDayPerTokens) external onlyOperator {
        delete maxVAAddPerDayPerTokens;
        maxVAAddPerDayPerTokens = _maxVAAddPerDayPerTokens;
    }

    /**************************************************************************
     *****  Market Manager  ***************************************************
     **************************************************************************/
    function setAcceptToken(address _acceptToken) external onlyOperator {
        uint256 wlLength = acceptTokens.length;
        for (uint256 index; index < wlLength; index++) {
            if (_acceptToken == acceptTokens[index]) return;
        }

        acceptTokens.push(_acceptToken);
    }

    function removeAcceptToken(uint256 _index) external onlyOperator {
        uint256 wlLength = acceptTokens.length;
        if (_index < acceptTokens.length - 1)
            acceptTokens[_index] = acceptTokens[wlLength - 1];
        acceptTokens.pop();
    }

    function setSellingLevelLimit(uint256 _sellingLevelLimit) external onlyOperator {
        sellingLevelLimit = _sellingLevelLimit;
    }

    // e.g. 100% = 1e18
    function setTradingFee(uint256 _tradingFee) external onlyOperator {
        require(_tradingFee <= 1e18, 'DBContract: too large.');
        tradingFee = _tradingFee;
    }

    /**************************************************************************
     *****  User Manager  *****************************************************
     **************************************************************************/
    function setRootAddress(address _rootAddress) external onlyOperator {
        require(_rootAddress != address(0), 'DBContract: root cannot be zero address.');

        rootAddress = _rootAddress;
    }

    function setDirectRequirements(uint256[] calldata _requirements) external onlyOperator {
        require(_requirements.length == uint256(type(IUser.Level).max), 'DBContract: length mismatch.');

        delete directRequirements;
        directRequirements = _requirements;
    }

    function setPerformanceRequirements(uint256[] calldata _requirements) external onlyOperator {
        require(_requirements.length == uint256(type(IUser.Level).max), 'DBContract: length mismatch.');

        delete performanceRequirements;
        performanceRequirements = _requirements;
    }

    function setPerformanceThreshold(uint256 _performanceThreshold) external onlyOperator {
        performanceThreshold = _performanceThreshold;
    }

    // e.g. 100% = 1e18
    function setSocialRewardRates(uint256[] calldata _rates) external onlyOperator {
        require(_rates.length == uint256(type(IUser.Level).max) + 1, 'DBContract: length mismatch.');

        delete socialRewardRates;
        for (uint256 index; index < _rates.length; index++) {
            require(_rates[index] <= 1e18, 'DBContract: too large.');
        }

        socialRewardRates = _rates;
    }

    function setContributionRewardThreshold(uint256 _contributionRewardThreshold) external onlyOperator {
        contributionRewardThreshold = _contributionRewardThreshold;
    }

    function setContributionRewardAmounts(uint256[] calldata _amounts) external onlyOperator {
        require(_amounts.length == uint256(type(IUser.Level).max) + 1, 'DBContract: length mismatch.');

        delete contributionRewardAmounts;
        contributionRewardAmounts = _amounts;
    }

    function setCommunityRewardRates(IUser.Level _level, uint256[] calldata _rates) external onlyOperator {
        uint256 levelUint = uint256(_level);

        delete communityRewardRates[levelUint];

        if (_rates.length > maxInvitationLevel) {
            maxInvitationLevel = _rates.length;
        }
        communityRewardRates[levelUint] = _rates;
    }

    function setAchievementRewardDurationThreshold(uint256 _achievementRewardDurationThreshold) external onlyOperator {
        achievementRewardDurationThreshold = _achievementRewardDurationThreshold;
    }

    function setAchievementRewardLevelThreshold(uint256 _achievementRewardLevelThreshold) external onlyOperator {
        achievementRewardLevelThreshold = _achievementRewardLevelThreshold;
    }

    function setAchievementRewardAmounts(uint256[] calldata _amounts) external onlyOperator {
        require(_amounts.length == uint256(type(IUser.Level).max) + 1, 'DBContract: length mismatch.');

        delete achievementRewardAmounts;
        achievementRewardAmounts = _amounts;
    }

    /**************************************************************************
     *****  APToken Manager  **************************************************
     **************************************************************************/
    function setSellingPackage(uint256[][] calldata _packages) external onlyOperator {
        delete sellingPackages;

        for (uint256 index; index < _packages.length; index++) {
            require(_packages[index].length == 3, 'DBContract: length mismatch.');

            sellingPackages.push(_packages[index]);
        }
    }

    function setDuration(uint256 _duration) external onlyOperator {
        duration = _duration;
    }

    function setLRTPriceInLYNK(uint256 _lrtPriceInLYNK) external onlyOperator {
        lrtPriceInLYNK = _lrtPriceInLYNK;
    }

    /**************************************************************************
     *****  public view  ******************************************************
     **************************************************************************/
    function calcTokenLevel(uint256 _tokenId) external view returns (uint256 level) {
        return _calcTokenLevel(_tokenId);
    }

    function calcLevel(ILYNKNFT.Attribute _attr, uint256 _point) external view returns (uint256 level, uint256 overflow) {
        return _calcLevel(_attr, _point);
    }

    function acceptTokenLength() external view returns (uint256) {
        return acceptTokens.length;
    }

    function isAcceptToken(address _token) external view returns (bool) {
        uint256 wlLength = acceptTokens.length;
        for (uint256 index; index < wlLength; index++) {
            if (_token == acceptTokens[index]) return true;
        }

        return false;
    }

    function packageLength() external view returns (uint256) {
        return sellingPackages.length;
    }

    function packageByIndex(uint256 _index) external view returns (uint256[] memory) {
        require(_index < sellingPackages.length, 'DBContract: index out of bounds.');

        return sellingPackages[_index];
    }

    function communityRewardRate(IUser.Level _level, uint256 _invitationLevel) external view returns (uint256) {
        if (communityRewardRates[uint256(_level)].length > _invitationLevel) {
            return communityRewardRates[uint256(_level)][_invitationLevel];
        }

        return 0;
    }

    function hasAchievementReward(uint256 _nftId) external view returns (bool) {
        return _calcTokenLevel(_nftId) >= achievementRewardLevelThreshold;
    }

    function _calcTokenLevel(uint256 _tokenId) private view returns (uint256 level) {
        require(ILYNKNFT(LYNKNFT).exists(_tokenId), 'DBContract: invalid token ID.');

        uint256[] memory _nftInfo = ILYNKNFT(LYNKNFT).nftInfoOf(_tokenId);
        for (uint256 index; index < uint256(type(ILYNKNFT.Attribute).max) + 1; index++) {
            (uint256 levelSingleAttr,) = _calcLevel(ILYNKNFT.Attribute(index), _nftInfo[index]);
            if (index == 0 || levelSingleAttr < level) {
                level = levelSingleAttr;
            }
        }

        return level;
    }

    function _calcLevel(ILYNKNFT.Attribute _attr, uint256 _point) private view returns (uint256 level, uint256 overflow) {
        level = 0;
        overflow = _point;
        uint256 thresholdLength = attributeLevelThreshold[uint256(_attr)].length;
        for (uint256 index; index < thresholdLength; index++) {
            if (_point >= attributeLevelThreshold[uint256(_attr)][index]) {
                level = index + 1;
                overflow = _point - attributeLevelThreshold[uint256(_attr)][index];
            } else {
                break;
            }
        }
        return (level, overflow);
    }

    function _setAddresses(address[] calldata _addresses) private {
        require(_addresses.length == 9, 'DBContract: addresses length mismatch.');

        LRT_TOKEN           = _addresses[0];
        AP_TOKEN            = _addresses[1];
        STAKING             = _addresses[2];
        LYNKNFT             = _addresses[3];
        STAKING_LYNKNFT     = _addresses[4];
        LISTED_LYNKNFT      = _addresses[5];
        MARKET              = _addresses[6];
        USER_INFO           = _addresses[7];
        TEAM_ADDR           = _addresses[8];
    }

    function mintPricesNum() external view returns (uint256) {
        return mintPrices.length;
    }

    function attributeLevelThresholdNum() external view returns (uint256) {
        return attributeLevelThreshold.length;
    }

    function attributeLevelThresholdNumByIndex(uint256 index) external view returns (uint256) {
        return attributeLevelThreshold.length > index ? attributeLevelThreshold[index].length : 0;
    }

    function directRequirementsNum() external view returns (uint256) {
        return directRequirements.length;
    }

    function performanceRequirementsNum() external view returns (uint256) {
        return performanceRequirements.length;
    }

    function socialRewardRatesNum() external view returns (uint256) {
        return socialRewardRates.length;
    }

    function contributionRewardAmountsNum() external view returns (uint256) {
        return contributionRewardAmounts.length;
    }

    function communityRewardRatesNumByLevel(IUser.Level _level) external view returns (uint256) {
        return communityRewardRates[uint256(_level)].length;
    }

    function achievementRewardAmountsNum() external view returns (uint256) {
        return achievementRewardAmounts.length;
    }

    function maxVAAddPerDayPerTokensNum() external view returns (uint256) {
        return maxVAAddPerDayPerTokens.length;
    }

    function maxVAAddPerDayByTokenId(uint256 _tokenId) external view returns (uint256) {
        uint256 tokenLevel = _calcTokenLevel(_tokenId);
        if (tokenLevel > maxVAAddPerDayPerTokens.length - 1) return 0;

        return maxVAAddPerDayPerTokens[tokenLevel];
    }

    function earlyBirdMintIdRange() external view returns (uint256, uint256) {
        return (earlyBirdMintStartId, earlyBirdMintEndId);
    }

    function earlyBirdMintPrice() external view returns (address, uint256) {
        return (earlyBirdMintPayment, earlyBirdMintPriceInPayment);
    }

    function revADDRNum() external view returns (uint256) {
        return revADDR.length;
    }

    function isRevAddr(address _adr) external view returns (bool) {
        for (uint i = 0; i < revADDR.length;i++) {
            if(revADDR[i] == _adr){
                return true;
            }
        }
        return false;
    }

    function setRevAddr(address[] calldata _addr_ls) external onlyOperator {

        delete revADDR;
        //uint max = uint256(type(IUser.REV_TYPE).max);
        require(_addr_ls.length ==  7 , 'RevAddr length mismatch.');
        for (uint i = 0; i < 7;i++) {
            revADDR.push(_addr_ls[i]);
        }
    }

    //v2
    function setMintNode(uint256[][] calldata _mintNode) external onlyOperator {
        delete mintNode;
        for (uint256 index; index < _mintNode.length; index++) {
            require(_mintNode[index].length == 4, 'DBContract: length mismatch.');
            mintNode.push(_mintNode[index]);
        }
    }
    function nodeByIndex(uint256 _index) external view returns (uint256[] memory) {
        require(_index < mintNode.length, 'DBContract: index out of bounds.');

        return mintNode[_index];
    }
    function setNFTMintEnable(bool _nftMintEnable) external onlyOperator {
        nftMintEnable = _nftMintEnable;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./baseContract.sol";
import "./interfaces/ILYNKNFT.sol";
import "./interfaces/IBNFT.sol";
import "./interfaces/IUser.sol";
import "./interfaces/IERC20Mintable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Staking is baseContract, IERC721ReceiverUpgradeable {
    mapping(address => MiningPower) public miningPowerOf;
    mapping(address => uint256) public rewardOf;
    mapping(address => uint256) public lastUpdateTimeOf;

    event Stake(address indexed account, uint256 tokenId);
    event UnStake(address indexed account, uint256 tokenId);
    event Claim(address indexed account, uint256 amount);

    struct MiningPower {
        uint256 charisma;
        uint256 dexterity;
    }

    //v2
    event StakeInfo(address indexed account,uint256 nftId,uint256 ca,uint256 va,uint256 ia,uint256 dx);
    event UnStakeInfo(address indexed account,uint256 nftId,uint256 ca,uint256 va,uint256 ia,uint256 dx);

    constructor(address dbAddress) baseContract(dbAddress){

    }

    function __Staking_init() public initializer {
        __baseContract_init();
        __Staking_init_unchained();
    }

    function __Staking_init_unchained() private {
    }

    modifier updateReward(address account) {
        uint256 lastUpdateTime = lastUpdateTimeOf[account];
        lastUpdateTimeOf[account] = block.timestamp;

        uint256 charisma = miningPowerOf[account].charisma;
        uint256 dexterity = miningPowerOf[account].dexterity;
        uint256 rewardRate = _rewardRate(charisma, dexterity);

        rewardOf[account] += rewardRate * (block.timestamp - lastUpdateTime);

        _;
    }

    function claimableOf(address account) external view returns (uint256) {
        uint256 charisma = miningPowerOf[account].charisma;
        uint256 dexterity = miningPowerOf[account].dexterity;
        uint256 rewardRate = _rewardRate(charisma, dexterity);

        return rewardOf[account] + rewardRate * (block.timestamp - lastUpdateTimeOf[account]);
    }

    function stake(uint256 nftId) external updateReward(_msgSender()) {
        require(
            IUser(DBContract(DB_CONTRACT).USER_INFO()).isValidUser(_msgSender()),
                'Staking: not a valid user.'
        );

        uint256 charisma = 0;
        uint256 dexterity = 0;
        address lynkNFTAddress = DBContract(DB_CONTRACT).LYNKNFT();
        address bLYNKNFTAddress = DBContract(DB_CONTRACT).STAKING_LYNKNFT();

        IERC721Upgradeable(lynkNFTAddress).safeTransferFrom(_msgSender(), address(this), nftId);
        IERC721Upgradeable(lynkNFTAddress).approve(bLYNKNFTAddress, nftId);
        IBNFT(bLYNKNFTAddress).mint(_msgSender(), nftId);

        emit Stake(_msgSender(), nftId);

        uint256[] memory nftInfo = ILYNKNFT(lynkNFTAddress).nftInfoOf(nftId);
        charisma += nftInfo[uint256(ILYNKNFT.Attribute.charisma)];
        dexterity += nftInfo[uint256(ILYNKNFT.Attribute.dexterity)];

        miningPowerOf[_msgSender()].charisma += charisma;
        miningPowerOf[_msgSender()].dexterity += dexterity;

        //v2
        uint256 vitality = 0;
        uint256 intellect = 0;
        vitality += nftInfo[uint256(ILYNKNFT.Attribute.vitality)];
        intellect += nftInfo[uint256(ILYNKNFT.Attribute.intellect)];
        emit StakeInfo(_msgSender(),nftId,charisma,vitality,intellect,dexterity);

        IUser(DBContract(DB_CONTRACT).USER_INFO()).hookByStake(nftId);
    }

    function unstake(uint256 nftId) external updateReward(_msgSender()) {
        address lynkNFTAddress = DBContract(DB_CONTRACT).LYNKNFT();
        address bLYNKNFTAddress = DBContract(DB_CONTRACT).STAKING_LYNKNFT();

        require(IERC721Upgradeable(bLYNKNFTAddress).ownerOf(nftId) == _msgSender(), 'Staking: not the owner.');

        IBNFT(bLYNKNFTAddress).burn(nftId);
        IERC721Upgradeable(lynkNFTAddress).safeTransferFrom(address(this), _msgSender(), nftId);

        emit UnStake(_msgSender(), nftId);

        uint256[] memory nftInfo = ILYNKNFT(lynkNFTAddress).nftInfoOf(nftId);
        uint256 charisma = nftInfo[uint256(ILYNKNFT.Attribute.charisma)];
        uint256 dexterity = nftInfo[uint256(ILYNKNFT.Attribute.dexterity)];

        //v2
        uint256 vitality = 0;
        uint256 intellect = 0;
        vitality += nftInfo[uint256(ILYNKNFT.Attribute.vitality)];
        intellect += nftInfo[uint256(ILYNKNFT.Attribute.intellect)];
        emit UnStakeInfo(_msgSender(),nftId,charisma,vitality,intellect,dexterity);

        miningPowerOf[_msgSender()].charisma -= charisma;
        miningPowerOf[_msgSender()].dexterity -= dexterity;

        IUser(DBContract(DB_CONTRACT).USER_INFO()).hookByUnStake(nftId);

        // claim reward if the last NFT is claiming.
        if (IERC721Upgradeable(bLYNKNFTAddress).balanceOf(_msgSender()) == 0 && rewardOf[_msgSender()] > 0) {
            _claimReward();
        }
    }

    function claimReward() external updateReward(_msgSender()) {
        _claimReward();
    }

    function onERC721Received(address, address, uint256, bytes calldata) external override pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _claimReward() private {
        uint256 claimable = rewardOf[_msgSender()];
        require(claimable > 0, 'Staking: cannot claim 0.');

        rewardOf[_msgSender()] = 0;
        IERC20Mintable(DBContract(DB_CONTRACT).LRT_TOKEN()).mint(_msgSender(), claimable);

        emit Claim(_msgSender(), claimable);

        IUser(DBContract(DB_CONTRACT).USER_INFO()).hookByClaimReward(_msgSender(), claimable);
    }

    function _rewardRate(uint256 charisma, uint256 dexterity) private pure returns (uint256) {
        uint256 rewardPerDay = ((0.007 ether) * charisma) + ((0.005 ether) * charisma * dexterity / 100);

        return rewardPerDay / 1 days;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./DBContract.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IUser.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

abstract contract baseContract is ContextUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address constant public BLACK_HOLE = address(0xdead);
    address immutable public DB_CONTRACT;

    constructor(address dbContract) {
        DB_CONTRACT = dbContract;
    }

    modifier onlyLYNKNFTOrDBContract() {
        require(
            DBContract(DB_CONTRACT).LYNKNFT() == _msgSender() ||
            DB_CONTRACT == _msgSender(),
                'baseContract: caller not the LYNK NFT contract.'
        );
        _;
    }

    modifier onlyLYNKNFTContract() {
        require(DBContract(DB_CONTRACT).LYNKNFT() == _msgSender(), 'baseContract: caller not the LYNK NFT contract.');
        _;
    }

    modifier onlyUserContract() {
        require(DBContract(DB_CONTRACT).USER_INFO() == _msgSender(), 'baseContract: caller not the User contract.');
        _;
    }

    modifier onlyStakingContract() {
        require(DBContract(DB_CONTRACT).STAKING() == _msgSender(), 'baseContract: caller not the Staking contract.');
        _;
    }

    modifier onlyUserOrStakingContract() {
        require(
            DBContract(DB_CONTRACT).USER_INFO() == _msgSender() ||
            DBContract(DB_CONTRACT).STAKING() == _msgSender(),
                'baseContract: caller not the User OR Staking contract.'
        );
        _;
    }

    function __baseContract_init() internal {
        __Context_init();
    }

    function _pay(address _payment, address _payer, uint256 _amount ,IUser.REV_TYPE _type) internal {
        address target = DBContract(DB_CONTRACT).revADDR(uint256(_type));
        if (address(0) == _payment) {
            require(msg.value == _amount, 'baseContract: invalid value.');
            AddressUpgradeable.sendValue(payable(target), _amount);
            return;
        }

        require(
            IERC20Upgradeable(_payment).allowance(_payer, address(this)) >= _amount,
            'baseContract: insufficient allowance'
        );

        IERC20Upgradeable(_payment).safeTransferFrom(_payer, target, _amount);

    }
    /**
     * @dev Throws if called by any account other than the operator.
     */
    modifier onlyOperator() {
        require( DBContract(DB_CONTRACT).operator() == _msgSender(), "baseContract: caller is not the operator");
        _;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import {IERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

interface IBNFT is IERC721MetadataUpgradeable, IERC721ReceiverUpgradeable, IERC721EnumerableUpgradeable {
  /**
   * @dev Emitted when an bNFT is initialized
   * @param underlyingAsset The address of the underlying asset
   **/
  event BNFTInitialized(address indexed underlyingAsset);

  /**
   * @dev Emitted on mint
   * @param user The address initiating the burn
   * @param nftAsset address of the underlying asset of NFT
   * @param nftTokenId token id of the underlying asset of NFT
   * @param owner The owner address receive the bNFT token
   **/
  event Mint(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);

  /**
   * @dev Emitted on burn
   * @param user The address initiating the burn
   * @param nftAsset address of the underlying asset of NFT
   * @param nftTokenId token id of the underlying asset of NFT
   * @param owner The owner address of the burned bNFT token
   **/
  event Burn(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);

  /**
   * @dev Emitted on flashLoan
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param nftAsset address of the underlying asset of NFT
   * @param tokenId The token id of the asset being flash borrowed
   **/
  event FlashLoan(address indexed target, address indexed initiator, address indexed nftAsset, uint256 tokenId);

  /**
   * @dev Initializes the bNFT
   * @param underlyingAsset The address of the underlying asset of this bNFT (E.g. PUNK for bPUNK)
   */
  function initialize(
    address underlyingAsset,
    string calldata bNftName,
    string calldata bNftSymbol
  ) external;

  /**
   * @dev Mints bNFT token to the user address
   *
   * Requirements:
   *  - The caller must be contract address.
   *  - `nftTokenId` must not exist.
   *
   * @param to The owner address receive the bNFT token
   * @param tokenId token id of the underlying asset of NFT
   **/
  function mint(address to, uint256 tokenId) external;

  /**
   * @dev Burns user bNFT token
   *
   * Requirements:
   *  - The caller must be contract address.
   *  - `tokenId` must exist.
   *
   * @param tokenId token id of the underlying asset of NFT
   **/
  function burn(uint256 tokenId) external;

//  /**
//   * @dev Allows smartcontracts to access the tokens within one transaction, as long as the tokens taken is returned.
//   *
//   * Requirements:
//   *  - `nftTokenIds` must exist.
//   *
//   * @param receiverAddress The address of the contract receiving the tokens, implementing the IFlashLoanReceiver interface
//   * @param nftTokenIds token ids of the underlying asset
//   * @param params Variadic packed params to pass to the receiver as extra information
//   */
//  function flashLoan(
//    address receiverAddress,
//    uint256[] calldata nftTokenIds,
//    bytes calldata params
//  ) external;

  /**
   * @dev Returns the owner of the `nftTokenId` token.
   *
   * Requirements:
   *  - `tokenId` must exist.
   *
   * @param tokenId token id of the underlying asset of NFT
   */
  function minterOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface IERC20Mintable {

    function mint(address account, uint256 amount) external;

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface ILYNKNFT {

    enum Attribute {
        charisma,
        vitality,
        intellect,
        dexterity
    }

    function nftInfoOf(uint256 tokenId)
        external
        view
        returns (uint256[] memory _nftInfo);

    function exists(uint256 tokenId) external view returns (bool);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface IUser {
    enum REV_TYPE { MINT_NFT_ADDR, LRT_ADDR, AP_ADDR,LYNK_ADDR,UP_CA_ADDR,MARKET_ADDR,USDT_ADDR }
    enum Level {
        elite,
        epic,
        master,
        legendary,
        mythic,
        divine
    }

    function isValidUser(address _userAddr) view external returns (bool);

    function hookByUpgrade(address _userAddr, uint256 _performance) external;
    function hookByClaimReward(address _userAddr, uint256 _rewardAmount) external;
    function hookByStake(uint256 nftId) external;
    function hookByUnStake(uint256 nftId) external;
    function registerByEarlyPlan(address _userAddr, address _refAddr) external;

}