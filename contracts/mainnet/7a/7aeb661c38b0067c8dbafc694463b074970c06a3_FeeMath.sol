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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
interface IERC165 {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "./utils/DexFiInitializable.sol";
import "./../interfaces/IDexFiFarm.sol";

/**
 * @title DexFiFarm
 * @dev Abstract contract for DexFi farms.
 */
abstract contract DexFiFarm is DexFiInitializable, IDexFiFarm {
    uint256 public constant MIN_AMOUNT_OUT = 0;

    address public vault;

    /**
     * @dev Get the native token address.
     * @return The native token address.
     */
    function native() external view virtual returns (address);

    /**
     * @dev Get the staking token address.
     * @return The staking token address.
     */
    function stakingToken() external view virtual returns (address);

    /**
     * @dev Get the reward token address at a specific index.
     * @param index The index of the reward token.
     * @return The reward token address.
     */
    function rewardTokens(uint256 index) external view virtual returns (address);

    /**
     * @dev Get the count of reward tokens.
     * @return The count of reward tokens.
     */
    function rewardTokensCount() external view virtual returns (uint256);

    /**
     * @dev Get the farm contract address.
     * @return The farm contract address.
     */
    function farm() external view virtual returns (address);

    /**
     * @dev Get the liquidity of a user.
     * @param user The user address.
     * @return The liquidity of the user.
     */
    function liquidity(address user) external view virtual returns (uint256);

    /**
     * @dev Get the type of staking token.
     * @return The type of staking token.
     */
    function stakingTokenType() external view virtual returns (string memory);

    /**
     * @dev Get the type of reward token.
     * @param token The reward token address.
     * @return The type of reward token.
     */
    function rewardTokenType(address token) external view virtual returns (string memory);

    /**
     * @dev Get the version of the DEX.
     * @return The version of the DEX.
     */
    function dexVersion() external view virtual returns (uint256);

    /**
     * @dev Get the staking token liquidity for a given amount.
     * @param amount The amount of staking tokens.
     * @return The staking token liquidity.
     */
    function stakingTokenLiquidity(uint256 amount) external virtual returns (uint256);

    /**
     * @dev Get the approval data for staking token transfer.
     * @param to The recipient address.
     * @param amount The amount of staking tokens to be transferred.
     * @return data The approval data.
     */
    function stakingTokenApproveData(address to, uint256 amount) external view virtual returns (bytes memory data);

    /**
     * @dev Get the transfer data for staking token.
     * @param from The sender address.
     * @param to The recipient address.
     * @param amount The amount of staking tokens to be transferred.
     * @return data The transfer data.
     */
    function stakingTokenTransferFromData(
        address from,
        address to,
        uint256 amount
    ) external view virtual returns (bytes memory data);

    /**
     * @dev Get the time unit for reward calculations.
     * @return The time unit.
     */
    function timeUnit() external pure virtual returns (TimeUnit);

    /**
     * @dev Get the reward tokens distributed per time unit.
     * @param rewardToken The reward token address.
     * @return The amount of reward tokens per time unit.
     */
    function sharePerTimeUnit(address rewardToken) external view virtual returns (uint256);

    /**
     * @dev Get the pending rewards for a user and token.
     * @param token The reward token address.
     * @param user The user address.
     * @return The pending rewards.
     */
    function pendingRewards(address token, address user) external view virtual returns (uint256);

    /**
     * @dev Decode and validate reinitialization parameters.
     * @param params The initialization parameters.
     * @return Whether the decoding and validation was successful.
     */
    function decodeAndValidateReinitialize(bytes memory params) external view virtual returns (bool);

    /**
     * @dev Get the initialization version of the farm.
     * @return The initialization version.
     */
    function initializationVersion() public view returns (uint8) {
        return _getInitializedVersion();
    }

    /**
     * @dev Get the amount of native tokens required to obtain a specific amount of staking tokens.
     * @param amountIn The amount of staking tokens.
     * @return nativeAmount The amount of native tokens.
     */
    function getAmountOutStakingTokenToNative(
        uint256 amountIn
    ) external onlyInitialized returns (uint256 nativeAmount) {
        nativeAmount = _getAmountOutStakingTokenToNative(amountIn);
    }

    /**
     * @dev Get the amount of native tokens obtained from a specific amount of reward tokens.
     * @param token The reward token address.
     * @param amountIn The amount of reward tokens.
     * @return nativeAmount The amount of native tokens.
     */
    function getAmountOutRewardTokenToNative(
        address token,
        uint256 amountIn
    ) external onlyInitialized returns (uint256 nativeAmount) {
        nativeAmount = _getAmountOutRewardTokenToNative(token, amountIn);
    }

    /**
     * @dev Initialize the farm contract.
     * @param params The initialization parameters.
     * @return Whether the initialization was successful.
     */
    function initialize(bytes memory params) external initializer returns (bool) {
        vault = msg.sender;
        _reinitialize(params);
        return true;
    }

    /**
     * @dev Reinitialize the farm contract.
     * @param params The reinitialization parameters.
     * @return Whether the reinitialization was successful.
     */
    function reinitialize(
        bytes memory params
    ) public onlyVault reinitializer(initializationVersion() + 1) returns (bool) {
        _reinitialize(params);
        return true;
    }

    /**
     * @dev Deposit native tokens and receive staking tokens.
     * @param nativeAmount The amount of native tokens to deposit.
     * @return stakingAmount The amount of staking tokens received.
     */
    function deposit(uint256 nativeAmount) external onlyInitialized onlyVault returns (uint256 stakingAmount) {
        stakingAmount = _deposit(nativeAmount);
    }

    /**
     * @dev Deposit staking tokens without conversion.
     * @param stakingAmount The amount of staking tokens to deposit.
     * @param depositLiquidityAmount The amount of liquidity tokens to receive.
     * @param feeLiquidityAmount The amount of liquidity tokens for fees.
     * @param feeRecipient The recipient of fees.
     * @param residualsRecipient The recipient of residuals.
     */
    function depositConvertless(
        uint256 stakingAmount,
        uint256 depositLiquidityAmount,
        uint256 feeLiquidityAmount,
        address feeRecipient,
        address residualsRecipient
    ) external onlyInitialized onlyVault {
        _depositConvertless(
            stakingAmount,
            depositLiquidityAmount,
            feeLiquidityAmount,
            feeRecipient,
            residualsRecipient
        );
    }

    /**
     * @dev Harvest rewards.
     * @return nativeAmount The amount of native tokens harvested.
     */
    function harvest() external onlyInitialized onlyVault returns (uint256 nativeAmount) {
        nativeAmount = _harvest();
    }

    /**
     * @dev Withdraw staking tokens and receive native tokens.
     * @param stakingAmount The amount of staking tokens to withdraw.
     * @return nativeAmount The amount of native tokens received.
     */
    function withdraw(uint256 stakingAmount) external onlyInitialized onlyVault returns (uint256 nativeAmount) {
        nativeAmount = _withdraw(stakingAmount);
    }

    /**
     * @dev Withdraw staking tokens without conversion.
     * @param stakingAmount The amount of staking tokens to withdraw.
     * @param recipient The recipient of the withdrawn staking tokens.
     */
    function withdrawConvertless(uint256 stakingAmount, address recipient) external onlyInitialized onlyVault {
        _withdrawConvertless(stakingAmount, recipient);
    }

    /**
     * @dev Emergency withdraw staking tokens without conversion.
     * @param stakingAmount The amount of staking tokens to emergency withdraw.
     * @param recipient The recipient of the withdrawn staking tokens.
     */
    function emergencyWithdraw(uint256 stakingAmount, address recipient) external onlyInitialized onlyVault {
        _emergencyWithdraw(stakingAmount, recipient);
    }

    /**
     * @dev Get the amount of native tokens required to obtain a specific amount of staking tokens.
     * @param amountIn The amount of staking tokens.
     * @return nativeAmount The amount of native tokens.
     */
    function _getAmountOutStakingTokenToNative(uint256 amountIn) internal virtual returns (uint256 nativeAmount);

    /**
     * @dev Get the amount of native tokens obtained from a specific amount of reward tokens.
     * @param token The reward token address.
     * @param amountIn The amount of reward tokens.
     * @return nativeAmount The amount of native tokens.
     */
    function _getAmountOutRewardTokenToNative(
        address token,
        uint256 amountIn
    ) internal virtual returns (uint256 nativeAmount);

    /**
     * @dev Reinitialize the farm contract.
     * @param params The reinitialization parameters.
     */
    function _reinitialize(bytes memory params) internal virtual;

    /**
     * @dev Deposit native tokens and receive staking tokens.
     * @param nativeAmount The amount of native tokens to deposit.
     * @return stakingAmount The amount of staking tokens received.
     */
    function _deposit(uint256 nativeAmount) internal virtual returns (uint256 stakingAmount);

    /**
     * @dev Deposit staking tokens without conversion.
     * @param stakingAmount The amount of staking tokens to deposit.
     * @param depositLiquidityAmount The amount of liquidity tokens to receive.
     * @param feeLiquidityAmount The amount of liquidity tokens for fees.
     * @param feeRecipient The recipient of fees.
     * @param residualsRecipient The recipient of residuals.
     */
    function _depositConvertless(
        uint256 stakingAmount,
        uint256 depositLiquidityAmount,
        uint256 feeLiquidityAmount,
        address feeRecipient,
        address residualsRecipient
    ) internal virtual;

    /**
     * @dev Harvest rewards.
     * @return nativeAmount The amount of native tokens harvested.
     */
    function _harvest() internal virtual returns (uint256 nativeAmount);

    /**
     * @dev Withdraw staking tokens and receive native tokens.
     * @param stakingAmount The amount of staking tokens to withdraw.
     * @return nativeAmount The amount of native tokens received.
     */
    function _withdraw(uint256 stakingAmount) internal virtual returns (uint256 nativeAmount);

    /**
     * @dev Withdraw staking tokens without conversion.
     * @param stakingAmount The amount of staking tokens to withdraw.
     * @param recipient The recipient of the withdrawn staking tokens.
     */
    function _withdrawConvertless(uint256 stakingAmount, address recipient) internal virtual;

    /**
     * @dev Emergency withdraw staking tokens without conversion.
     * @param stakingAmount The amount of staking tokens to emergency withdraw.
     * @param recipient The recipient of the withdrawn staking tokens.
     */
    function _emergencyWithdraw(uint256 stakingAmount, address recipient) internal virtual;

    /**
     * @dev Ensure that the caller is the vault.
     */
    modifier onlyVault() {
        if (msg.sender != vault) revert CallerIsNotVault(msg.sender, vault);
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title DexFiInitializable
 * @dev Abstract contract for initializing contracts with OpenZeppelin's Initializable logic.
 */
abstract contract DexFiInitializable is Initializable {
    // Custom error for indicating that the contract is not initialized.
    error ContractNotInitialized();

    /**
     * @dev Modifier to check if the contract is initialized.
     * Throws a `ContractNotInitialized` error if not initialized.
     */
    modifier onlyInitialized() {
        if (_getInitializedVersion() == 0) revert ContractNotInitialized();
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface IDexFiFarm {
    enum TimeUnit {
        BLOCK,
        SECOND
    }

    function MIN_AMOUNT_OUT() external pure returns (uint256);

    function vault() external view returns (address);

    function native() external view returns (address);

    function stakingToken() external view returns (address);

    function rewardTokens(uint256 index) external view returns (address);

    function rewardTokensCount() external view returns (uint256);

    function farm() external view returns (address);

    function liquidity(address user) external view returns (uint256);

    function stakingTokenType() external view returns (string memory);

    function rewardTokenType(address token) external view returns (string memory);

    function dexVersion() external view returns (uint256);

    function stakingTokenLiquidity(uint256 amount) external returns (uint256);

    function stakingTokenApproveData(address to, uint256 amount) external view returns (bytes memory data);

    function stakingTokenTransferFromData(
        address from,
        address to,
        uint256 amount
    ) external view returns (bytes memory data);

    function timeUnit() external pure returns (TimeUnit);

    function sharePerTimeUnit(address rewardToken) external view returns (uint256);

    function pendingRewards(address token, address user) external view returns (uint256);

    function decodeAndValidateReinitialize(bytes memory params) external view returns (bool);

    function initializationVersion() external view returns (uint8);

    error CallerIsNotVault(address caller, address vault);

    function getAmountOutStakingTokenToNative(uint256 amountIn) external returns (uint256 nativeAmount);

    function getAmountOutRewardTokenToNative(address token, uint256 amountIn) external returns (uint256 nativeAmount);

    function initialize(bytes memory params) external returns (bool);

    function reinitialize(bytes memory params) external returns (bool);

    function deposit(uint256 nativeAmount) external returns (uint256 stakingAmount);

    function depositConvertless(
        uint256 stakingAmount,
        uint256 depositLiquidityAmount,
        uint256 feeLiquidityAmount,
        address feeRecipient,
        address residualsRecipient
    ) external;

    function harvest() external returns (uint256 amount);

    function withdraw(uint256 stakingAmount) external returns (uint256 nativeAmount);

    function withdrawConvertless(uint256 stakingAmount, address recipient) external;

    function emergencyWithdraw(uint256 stakingAmount, address recipient) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface IDexFiProfit {
    function MIN_AMOUNT_OUT() external pure returns (uint256);

    function initializationVersion() external view returns (uint8);

    function factory() external view returns (address);

    function native() external view returns (address);

    function underlying() external view returns (address);

    function underlyingType() external view returns (string memory);

    function decodeAndValidateReinitialize(bytes memory params) external view returns (bool);

    error ReinitalizeCallerNotFactory(address caller, address factory);

    function getAmountOutUnderlyingToNative(uint256 underlyingAmount) external returns (uint256 nativeAmount);

    function initialize(bytes memory params) external returns (bool);

    function reinitialize(bytes memory params) external returns (bool);

    function swapNativeToProfit(uint256 nativeAmount) external returns (uint256 profitAmount, uint256 usedNativeAmount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IDexFiVaultFactory.sol";
import "./IDexFiVaultProfitStorage.sol";
import "./IDexFiFarm.sol";

interface IDexFiVault {
    struct Farm {
        address beacon;
        uint256 percent;
        bytes data;
    }

    struct PublishData {
        bool published;
        address publisher;
    }

    function divider() external view returns (uint256);

    function lastHarvestTimestamp() external view returns (uint256);

    function factory() external view returns (IDexFiVaultFactory);

    function harvesterDebt() external view returns (uint256);

    function profit() external view returns (uint256);

    function profitStorage() external view returns (address);

    function native() external view returns (IERC20Upgradeable);

    function farmConnector(address) external view returns (IDexFiFarm);

    function publishData() external view returns (PublishData memory);

    function farms(uint256 index) external view returns (Farm memory);

    function farmsCount() external view returns (uint256);

    function convertlessDepositRatio() external view returns (uint256[] memory output);

    event Published(address publisher);
    event ProfitUpdated(uint256 profit);
    event HarvesterDebtIncreased(uint256 amount, uint256 remainingDebtAmount);
    event FarmsUpdated(Farm[] farms);
    event Deposited(
        address indexed user,
        address indexed to,
        uint256 nativeAmount,
        uint256 syntheticAmount,
        uint256 feeAmount
    );
    event ConvertlessDeposited(
        address indexed user,
        uint256 syntheticAmount,
        uint256[] stakingAmounts,
        uint256[] depositLiquidityAmounts,
        uint256[] feeLiquidityAmounts
    );
    event Harvested(
        address indexed user,
        uint256 reinvestAmount,
        uint256 feeAmount,
        uint256 profitAmount,
        uint256 paidDebtAmount,
        uint256 remainingDebtAmount
    );
    event Withdrawn(
        address indexed user,
        address indexed from,
        uint256 syntheticAmount,
        uint256 nativeAmount,
        uint256 feeAmount
    );
    event EmergencyWithdrawn(address indexed user, uint256 syntheticAmount, uint256[] outputAmounts);
    event ConvertlessWithdrawn(
        address indexed user,
        uint256 syntheticAmount,
        uint256[] outputAmounts,
        uint256[] feeAmounts,
        uint256 outputNativeAmount,
        uint256 feeNativeAmount
    );

    error IncreaseHarvesterDebtCallerNotHarvester(address caller, address harvester);
    error DepositAmountZero();
    error DepositUsersCountOverflow();
    error DepositMintAmountUnderflow(uint256 mintAmount, uint256 minMintAmount);
    error DepositConvertlessSupplyZero();
    error DepositConvertlessAmountsLengthDiffers(uint256 amountsLength, uint256 target);
    error DepositConvertlessMintAmountUnderflow(uint256 mintAmount, uint256 minMintAmount);
    error UpdateFarmsLengthZero();
    error WithdrawAmountZero();
    error WithdrawNativeAmountUnderflow(uint256 nativeAmount, uint256 minNativeAmount);
    error EmergencyWithdrawUserBalanceZero();
    error WithdrawConvertlessAmountZero();
    error UpdateFarmsNotWhitelisted(address farm);
    error UpdateFarmsInitializationFailed(address farm, bytes data);
    error UpdateFarmsReinitializationFailed(address farm, bytes data);
    error UpdateFarmsInvalidPercentsSum(uint256 percentSum, uint256 targetSum);
    error UpdateProfitUnderflow(uint256 profit, uint256 min);
    error UpdateProfitOverflow(uint256 profit, uint256 max);
    error TransferNotAllowed(
        address from,
        address to,
        uint256 amount,
        uint256 fromBalanceAfterTokenTransfer,
        uint256 minSyntheticTransferAmount
    );
    error ActualizeFarmStatusReinitializationFailed(Farm farm);
    error ProtocolPaused();
    error ContractNotInitialized();
    error RestakingAmountUnderflow(uint256 restakingAmount, uint256 minRestakingAmount);

    function increaseHarvesterDebt(uint256 amount) external returns (bool);

    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        uint256 profit_,
        address profitToken_,
        Farm[] memory farms_
    ) external returns (bool);

    function deposit(uint256 amount, address to, uint256 minMintAmount) external returns (uint256 mintAmount);

    function harvest(
        uint256 minRestakingAmount_
    )
        external
        returns (
            uint256 reinvestAmount,
            uint256 harvestFeeAmount,
            uint256 profitAmount,
            uint256 paidDebtAmount,
            uint256 remainingDebtAmount,
            uint256 restakingAmount
        );

    function updateFarms(Farm[] memory farms_, uint256 minRestakingAmount_) external returns (uint256 restakingAmount);

    function withdraw(uint256 amount, address from, uint256 minNativeAmount) external returns (uint256 nativeAmount);

    function emergencyWithdraw() external returns (uint256[] memory outputAmounts);

    function publish(uint256 minRestakingAmount_) external returns (uint256 restakingAmount);

    function updateProfit(uint256 profit_) external returns (bool);

    function updateProfitToken(address profitToken_) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "./IDexFiVault.sol";
import "./IDexFiVaultProfitStorage.sol";
import "./IDexFiProfit.sol";
import "./IDexFiFarm.sol";

interface IDexFiVaultFactory {
    struct FeeConfig {
        uint256 depositFee;
        uint256 harvestFee;
        uint256 withdrawFee;
        uint256 migrateFee;
    }

    struct ProfitConfig {
        uint256 minProfit;
        uint256 maxProfit;
        address profitStorageImplementation;
        uint256 vaultOwnerProfit;
    }

    struct VaultConfig {
        address vaultImplementation;
        uint256 maxDepositorsCount;
        uint256 initialPriceNativeAmount;
        uint256 minSyntheticTransferAmount;
        uint256 minNativeReinvestAmount;
    }

    struct IntegrationConfig {
        address keeper;
        address harvester;
        address migrator;
        address treasury;
        address profitClaimer;
        address zapper;
    }

    struct InitializableConfig {
        address source;
        bytes defaultInitializeData;
    }

    struct Beaconed {
        address beacon;
        address source;
        bytes defaultInitializeData;
    }

    function DIVIDER() external view returns (uint256);

    function MAX_DEPOSIT_FEE() external view returns (uint256);

    function MAX_HARVEST_FEE() external view returns (uint256);

    function MAX_WITHDRAW_FEE() external view returns (uint256);

    function MAX_MIGRATE_FEE() external view returns (uint256);

    function MIN_VAULT_MANAGEMENT_AMOUNT() external view returns (uint256);

    function MAX_VAULT_OWNER_PROFIT() external view returns (uint256);

    function MIN_DEPOSITORS_COUNT() external view returns (uint256);

    function MAX_DEPOSITORS_COUNT() external view returns (uint256);

    function native() external view returns (address);

    function defaultFarmsInitializeData(address) external view returns (bytes memory);

    function defaultFarmsInitializeDataTimestamp(address) external view returns (uint256);

    function profitTokenConnector(address) external view returns (IDexFiProfit);

    function farmCalculationConnector(address) external view returns (IDexFiFarm);

    function feeConfig() external view returns (FeeConfig memory);

    function profitConfig() external view returns (ProfitConfig memory);

    function vaultConfig() external view returns (VaultConfig memory);

    function integrationConfig() external view returns (IntegrationConfig memory);

    function farmsWhitelist(uint256 index) external view returns (address);

    function farmsWhitelistCount() external view returns (uint256);

    function farmsWhitelistContains(address farm) external view returns (bool);

    function profitTokensWhitelist(uint256 index) external view returns (address);

    function profitTokensWhitelistCount() external view returns (uint256);

    function profitTokensWhitelistContains(address profitToken) external view returns (bool);

    function vaults(uint256 index) external view returns (address);

    function vaultsCount() external view returns (uint256);

    function vaultsContains(address vault) external view returns (bool);

    function harvesterBlacklist(uint256 index) external view returns (address);

    function harvesterBlacklistCount() external view returns (uint256);

    function harvesterBlacklistContains(address vault) external view returns (bool);

    error NativeZero();
    error CallerNotOwnerOrKeeper(address caller, address owner, address keeper);

    error CreateVaultProfitTokenUnsupported(address profitToken);
    error CreateVaultInitializationFailed();

    error UpdateFarmsWhitelistBeaconNotWhitelisted(address beacon);
    error UpdateFarmsWhitelistBeaconSourceZero(address beacon);
    error UpdateFarmsWhitelistReinitializationFailed(Beaconed data);

    error UpdateProfitTokensWhitelistBeaconNotWhitelisted(address beacon);
    error UpdateProfitTokensWhitelistBeaconSourceZero(address beacon);
    error UpdateProfitTokensWhitelistReinitializationFailed(Beaconed data);

    error UpdateFeeConfigDepositFeeOverflow(uint256 depositFee, uint256 limit);
    error UpdateFeeConfigHarvestFeeOverflow(uint256 harvestFee, uint256 limit);
    error UpdateFeeConfigWithdrawFeeOverflow(uint256 withdrawFee, uint256 limit);
    error UpdateFeeConfigMigrateFeeOverflow(uint256 migrateFee, uint256 limit);

    error UpdateVaultConfigVaultImplementationZero();
    error UpdateVaultConfigInvalidMaxDepositors(uint256 maxDepositors, uint256 min, uint256 max);
    error UpdateVaultConfigVaultInitialPriceNativeAmountUnderflow(uint256 initialPriceNativeAmount, uint256 min);
    error UpdateVaultConfigMinSyntheticTransferAmountUnderflow(uint256 minSyntheticTransferAmount, uint256 min);
    error UpdateVaultConfigMinReinvestAmountZero();
    error UpdateProfitConfigMaxProfitOverflow(uint256 maxProfit, uint256 max);
    error UpdateProfitConfigMinProfitOverflow(uint256 minProfit, uint256 maxProfit);
    error UpdateProfitConfigProfitStorageImplementationZero();
    error UpdateProfitConfigVaultOwnerProfitOverflow(uint256 vaultOwnerProfit, uint256 max);

    error UpdateIntegrationConfigKeeperZero();
    error UpdateIntegrationConfigHarvesterZero();
    error UpdateIntegrationConfigMigratorZero();
    error UpdateIntegrationConfigTreasuryZero();
    error UpdateIntegrationConfigProfitClaimerZero();
    error UpdateIntegrationConfigZapperZero();

    error ToggleVaultAutoHarvestCallerNotVaultOwner(address caller, address vault, address owner);

    error AddProfitTokensWhitelistProfitTokenZero();
    error AddProfitTokensWhitelistInitializationFailed(Beaconed data);

    error AddFarmsWhitelistFarmZero();
    error AddFarmsWhitelistInitializationFailed(Beaconed data);

    event VaultCreated(
        address indexed owner,
        address vault,
        uint256 profit,
        address profitToken,
        IDexFiVault.Farm[] farms
    );
    event FeeConfigUpdated(FeeConfig config);
    event VaultConfigUpdated(VaultConfig config);
    event ProfitConfigUpdated(ProfitConfig config);
    event IntegrationConfigUpdated(IntegrationConfig config);
    event VaultAutoHarvestToggled(address vault, bool blacklisted);
    event ProfitTokensWhitelistAdded(Beaconed[] profitTokens);
    event ProfitTokensWhitelistUpdated(Beaconed[] profitTokens);
    event ProfitTokensWhitelistRemoved(address[] profitTokens);
    event FarmsWhitelistAdded(Beaconed[] farms);
    event FarmsWhitelistUpdated(Beaconed[] farms);
    event FarmsWhitelistRemoved(address[] farms);

    function createVault(
        string memory name_,
        string memory symbol_,
        uint256 profit_,
        address profitToken_,
        IDexFiVault.Farm[] memory farms_
    ) external returns (address vault);

    function pause() external returns (bool);

    function unpause() external returns (bool);

    function addFarmsWhitelist(InitializableConfig[] memory farms_) external returns (Beaconed[] memory output);

    function updateFarmsWhitelist(Beaconed[] memory farms_) external returns (bool);

    function removeFarmsWhitelist(address[] memory beacons_) external returns (bool);

    function addProfitTokensWhitelist(
        InitializableConfig[] memory profitTokens_
    ) external returns (Beaconed[] memory output);

    function updateProfitTokensWhitelist(Beaconed[] memory profitTokens_) external returns (bool);

    function removeProfitTokensWhitelist(address[] memory beacons_) external returns (bool);

    function updateFeeConfig(FeeConfig memory config) external returns (bool);

    function updateVaultConfig(VaultConfig memory config) external returns (bool);

    function updateProfitConfig(ProfitConfig memory config) external returns (bool);

    function updateIntegrationConfig(IntegrationConfig memory config) external returns (bool);

    function toggleVaultAutoHarvest(address vault) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDexFiVaultFactory.sol";
import "./IDexFiVault.sol";
import "./IDexFiProfit.sol";

interface IDexFiVaultProfitStorage {
    struct UserSyntheticAmount {
        address user;
        uint256 amount;
    }

    struct UserSharesInfo {
        uint256 accShares;
        uint256 lastRewardBlock;
        uint256 lastSyntheticBalance;
    }

    function divider() external view returns (uint256);

    function factory() external view returns (IDexFiVaultFactory);

    function vault() external view returns (address);

    function profitToken() external view returns (address);

    function profitTokenConnector() external view returns (IDexFiProfit);

    function usersSharesInfo(address user) external view returns (UserSharesInfo memory);

    function availableToClaim(address) external view returns (uint256);

    function fund() external view returns (uint256);

    function native() external view returns (IERC20);

    function users(uint256 index) external view returns (address);

    function usersCount() external view returns (uint256);

    function usersContains(address user) external view returns (bool);

    event ProfitFundsAdded(uint256 amount);
    event ProfitTokenUpdated(address profitToken);
    event Claimed(address indexed user, address indexed token, uint256 amount);
    event UserAdded(address indexed user);
    event UserRemoved(address indexed user);

    error CallerNotVault(address caller, address vault);
    error AddProfitFundsAmountZero();
    error UpdateProfitTokenVaultPublished();
    error ClaimAmountOverflow(uint256 amount, uint256 max);
    error UpdateProfitTokenUnsupported(address token);

    function initialize(IDexFiVaultFactory factory_, address profitToken_) external returns (bool);

    function updateUsersSharesBalance(UserSyntheticAmount[] memory usersSyntheticAmount) external returns (bool);

    function allocate() external returns (bool);

    function addProfitFunds(uint256 amount) external returns (bool);

    function claim(uint256 amount, address from) external returns (bool);

    function updateProfitToken(address profitToken_) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DexFiFarm} from "../../../../core/abstracts/DexFiFarm.sol";
import {IDexFiVault} from "../../../../core/interfaces/IDexFiVault.sol";
import {IUniswapV3Pool} from "../../../utils/Uniswap/interfaces/IUniswapV3Pool.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV3Factory} from "../../../utils/Uniswap/interfaces/IUniswapV3Factory.sol";
import {IV3PriceOracleValidator} from "../../../utils/V3Utilities/interfaces/IV3PriceOracleValidator.sol";
import {IV3LiquidityHelper} from "../../../utils/V3Utilities/interfaces/IV3LiquidityHelper.sol";
import {INonfungiblePositionManager} from "../../../utils/Uniswap/interfaces/INonfungiblePositionManager.sol";
import {Swap} from "../../../utils/Uniswap/libraries/custom/Swap.sol";
import {Oracle} from "../../../utils/Uniswap/libraries/custom/Oracle.sol";
import {Utility} from "../../../utils/Uniswap/libraries/custom/Utility.sol";
import {TickMath} from "../../../utils/Uniswap/libraries/TickMath.sol";
import {PriceManagement} from "../../../utils/Uniswap/libraries/custom/PriceManagement.sol";
import {LiquidityManagement} from "../../../utils/Uniswap/libraries/custom/LiquidityManagement.sol";
import {IDexFiUniversalRouterBytes} from "../../../common/interfaces/IDexFiUniversalRouterBytes.sol";
import {LiquidityAmounts} from "../../../utils/Uniswap/libraries/LiquidityAmounts.sol";

contract UniswapFarm is DexFiFarm, IERC721Receiver {
    using PriceManagement for PriceManagement.PriceRangesData;
    using LiquidityManagement for INonfungiblePositionManager;
    using Oracle for Oracle.OracleData;
    using LiquidityAmounts for uint160;
    using Swap for Swap.SwapPair[];
    using SafeERC20 for IERC20;

    struct StakingTokenData {
        string stakingTokenType;
        IUniswapV3Pool pool;
        address token0;
        address token1;
        uint24 fee;
        Swap.SwapPair[] swapsToken0ToNative;
        Swap.SwapPair[] swapsToken1ToNative;
        Swap.SwapPair[] swapsNativeToToken0;
        Swap.SwapPair[] swapsNativeToToken1;
        Swap.SwapPair[] swapsToken0ToToken1;
        Swap.SwapPair[] swapsToken1ToToken0;
    }

    struct StakingTokenInitData {
        string stakingTokenType;
        uint24 fee;
        uint256 approxToRangeLimitPercent;
        uint256 defaultDeviationPercentLow;
        uint256 defaultDeviationPercentUp;
        Swap.SwapPair[] swapsToken0ToNative;
        Swap.SwapPair[] swapsToken1ToNative;
        Swap.SwapPair[] swapsToken0ToToken1;
    }

    struct ReinitializationData {
        address universalRouter;
        address nonfungiblePositionManager;
        address liquidityHelper;
        StakingTokenInitData stakingToken;
        Oracle.OracleData oracleData;
    }

    struct HarvestDebt {
        uint256 debt0;
        uint256 debt1;
    }

    bool public globalUpdate;
    uint256 public tokenId;
    IDexFiUniversalRouterBytes public universalRouter;
    IV3LiquidityHelper public liquidityHelper;

    IERC20 private _native;
    INonfungiblePositionManager private _stakingToken;
    StakingTokenData private _stakingTokenData;
    PriceManagement.PriceRangesData private _priceRangesData;
    Oracle.OracleData private _oracleData;
    HarvestDebt private _harvestDebt;

    function native() external view override returns (address) {
        return address(_native);
    }

    function stakingToken() external view override returns (address) {
        return address(_stakingToken);
    }

    function stakingTokenData() external view returns (StakingTokenData memory) {
        return _stakingTokenData;
    }

    function priceRangesData() external view returns (PriceManagement.PriceRangesData memory) {
        return _priceRangesData;
    }

    function rewardTokens(uint256) external view override returns (address token_) {}

    function rewardTokensCount() external pure override returns (uint256 count_) {}

    function harvestDebt() external view returns (HarvestDebt memory) {
        return _harvestDebt;
    }

    function oracleData() external view returns (Oracle.OracleData memory) {
        return _oracleData;
    }

    function farm() external view override returns (address farm_) {}

    function liquidity(address) external view override returns (uint256 liquidity_) {
        if (tokenId > 0) (, , , , , , , liquidity_, , , , ) = _stakingToken.positions(tokenId);
    }

    function stakingTokenType() external view override returns (string memory) {
        return _stakingTokenData.stakingTokenType;
    }

    function rewardTokenType(address) external view override returns (string memory type_) {}

    function stakingTokenApproveData(address to, uint256 tokenId_) external view override returns (bytes memory data) {
        data = abi.encodeWithSelector(_stakingToken.approve.selector, to, tokenId_);
    }

    function stakingTokenTransferFromData(
        address from,
        address to,
        uint256 tokenId_
    ) external view override returns (bytes memory data) {
        data = abi.encodeWithSelector(_stakingToken.transferFrom.selector, from, to, tokenId_);
    }

    function timeUnit() external pure override returns (TimeUnit) {
        return TimeUnit.SECOND;
    }

    function sharePerTimeUnit(address) external view override returns (uint256 share_) {}

    function pendingRewards(address, address) external view override returns (uint256 rewards_) {}

    function decodeAndValidateReinitialize(bytes memory params) external pure override returns (bool) {
        _decodeAndValidateReinitialize(params);
        return true;
    }

    function dexVersion() external pure override returns (uint256) {
        return 4;
    }

    function stakingTokenLiquidity(uint256 inputTokenId) external override returns (uint256 liquidity_) {
        if (tokenId > 0 && inputTokenId > 0) {
            if (inputTokenId == tokenId) {
                (, , , , , , , liquidity_, , , , ) = _stakingToken.positions(inputTokenId);
            } else {
                StakingTokenData storage stakingTokenData_ = _stakingTokenData;
                liquidity_ = liquidityHelper.calculateNewLiquidityFromOldPosition(
                    universalRouter,
                    _stakingToken,
                    inputTokenId,
                    tokenId,
                    stakingTokenData_.swapsToken0ToNative,
                    stakingTokenData_.swapsToken1ToNative
                );
            }
        }
    }

    function _getAmountOutStakingTokenToNative(uint256 amountIn) internal override returns (uint256 nativeAmount) {
        if (type(uint128).max < amountIn) revert GetAmountOutStakingTokenToNativeOverflowAmountIn(amountIn);
        StakingTokenData storage stakingTokenData_ = _stakingTokenData;
        (uint160 sqrtPriceX96, , , , , , ) = stakingTokenData_.pool.slot0();
        (uint256 amount0, uint256 amount1) = sqrtPriceX96.getAmountsForLiquidity(
            uint160(_priceRangesData.sqrtPriceX96Low),
            uint160(_priceRangesData.sqrtPriceX96Up),
            uint128(amountIn)
        );
        nativeAmount += stakingTokenData_.swapsToken0ToNative.getAmountOut(universalRouter, amount0);
        nativeAmount += stakingTokenData_.swapsToken1ToNative.getAmountOut(universalRouter, amount1);
    }

    function _getAmountOutRewardTokenToNative(address, uint256) internal override returns (uint256 nativeAmount) {}

    event SqrtPriceX96ShiftPercentUpdated(uint256 low, uint256 up);

    error DecodeReinitializeDataUniversalRouterZero();
    error DecodeReinitializeDataNonfungiblePositionManagerZero();
    error DecodeReinitializeDataLiquidityHelperZero();
    error DepositConvertlessPoolIsInvalid();
    error ReinitializeOracleZero();
    error ReinitializeDeviationGTPrecision();
    error ReinitializePoolZero();
    error ReinitializeDefaultDeviationPercentUpZero();
    error ReinitializeDeviationPercentLowZero();
    error ReinitializeApproxToRangeLimitPercentPercentZero();
    error ReinitializeLowPercentGtPrecision(uint256 percent);
    error GetAmountOutStakingTokenToNativeOverflowAmountIn(uint256 amountIn);
    error UpdateSqrtPriceX96ShiftPercentCallerNotVaultOwner(address caller, address owner);
    error UpdateSqrtPriceX96ShiftPercentLowPercentGtPrecision(uint256 percent);
    error DepositConvertlessCalculatedLiquidityGtAdded(uint256 calculatedLiquidity, uint256 liquidity);

    function updatePriceRangesShiftPercent(uint256 lowPercent, uint256 upPercent) external returns (bool) {
        address vaultOwner = Ownable(vault).owner();
        if (msg.sender != vaultOwner) revert UpdateSqrtPriceX96ShiftPercentCallerNotVaultOwner(msg.sender, vaultOwner);
        if (lowPercent > Utility.PRECISION) revert UpdateSqrtPriceX96ShiftPercentLowPercentGtPrecision(lowPercent);
        _priceRangesData.deviationPercentLow = lowPercent;
        _priceRangesData.deviationPercentUp = upPercent;
        _checkOrReassemblyPosition(_stakingTokenData, true);
        emit SqrtPriceX96ShiftPercentUpdated(lowPercent, upPercent);
        return true;
    }

    function _reinitialize(bytes memory params) internal override {
        uint256 precision_ = Utility.PRECISION;
        address native_ = address(IDexFiVault(msg.sender).native());
        _native = IERC20(native_);
        ReinitializationData memory data = _decodeAndValidateReinitialize(params);
        StakingTokenInitData memory stakingTokenInitData = data.stakingToken;
        if (address(data.oracleData.oracle) == address(0)) revert ReinitializeOracleZero();
        if (data.oracleData.deviation > precision_) revert ReinitializeDeviationGTPrecision();
        _oracleData = data.oracleData;
        address token0 = stakingTokenInitData.swapsToken0ToNative[0].tokenIn;
        address token1 = stakingTokenInitData.swapsToken1ToNative[0].tokenIn;
        stakingTokenInitData.swapsToken0ToNative.validateSwapPath(token0, native_);
        stakingTokenInitData.swapsToken1ToNative.validateSwapPath(token1, native_);
        stakingTokenInitData.swapsToken0ToToken1.validateSwapPath(token0, token1);
        universalRouter = IDexFiUniversalRouterBytes(data.universalRouter);
        liquidityHelper = IV3LiquidityHelper(data.liquidityHelper);
        _stakingToken = INonfungiblePositionManager(data.nonfungiblePositionManager);
        if (stakingTokenInitData.approxToRangeLimitPercent > precision_)
            revert ReinitializeApproxToRangeLimitPercentPercentZero();
        if (stakingTokenInitData.defaultDeviationPercentLow == 0) revert ReinitializeDeviationPercentLowZero();
        if (stakingTokenInitData.defaultDeviationPercentLow > precision_)
            revert ReinitializeLowPercentGtPrecision(stakingTokenInitData.defaultDeviationPercentLow);
        if (stakingTokenInitData.defaultDeviationPercentUp == 0) revert ReinitializeDefaultDeviationPercentUpZero();
        address pool_ = IUniswapV3Factory(_stakingToken.factory()).getPool(
            stakingTokenInitData.swapsToken0ToNative[0].tokenIn,
            stakingTokenInitData.swapsToken1ToNative[0].tokenIn,
            stakingTokenInitData.fee
        );
        if (pool_ == address(0)) revert ReinitializePoolZero();
        StakingTokenData storage stakingTokenData_ = _stakingTokenData;
        stakingTokenData_.stakingTokenType = stakingTokenInitData.stakingTokenType;
        stakingTokenData_.pool = IUniswapV3Pool(pool_);
        stakingTokenData_.token0 = token0;
        stakingTokenData_.token1 = token1;
        stakingTokenData_.fee = stakingTokenInitData.fee;
        stakingTokenData_.swapsToken0ToNative = stakingTokenInitData.swapsToken0ToNative;
        stakingTokenData_.swapsToken1ToNative = stakingTokenInitData.swapsToken1ToNative;
        stakingTokenData_.swapsToken0ToToken1 = stakingTokenInitData.swapsToken0ToToken1;
        stakingTokenData_.swapsNativeToToken0 = stakingTokenInitData.swapsToken0ToNative.reverseSwapPath();
        stakingTokenData_.swapsNativeToToken1 = stakingTokenInitData.swapsToken1ToNative.reverseSwapPath();
        stakingTokenData_.swapsToken1ToToken0 = stakingTokenInitData.swapsToken0ToToken1.reverseSwapPath();
        PriceManagement.PriceRangesData storage priceRangesData_ = _priceRangesData;
        priceRangesData_.approxToRangeLimitPercent = stakingTokenInitData.approxToRangeLimitPercent;
        priceRangesData_.deviationPercentLow = _priceRangesData.deviationPercentLow;
        priceRangesData_.deviationPercentUp = _priceRangesData.deviationPercentUp;
        priceRangesData_.defaultDeviationPercentLow = stakingTokenInitData.defaultDeviationPercentLow;
        priceRangesData_.defaultDeviationPercentUp = stakingTokenInitData.defaultDeviationPercentUp;
        globalUpdate = true;
    }

    function _deposit(uint256 nativeAmount) internal override returns (uint256 stakingAmount) {
        _processRewards();
        _native.safeTransferFrom(msg.sender, address(this), nativeAmount);
        uint256 liquidity_;
        if (tokenId > 0) (, , , , , , , liquidity_, , , , ) = _stakingToken.positions(tokenId);
        if (liquidity_ == 0) {
            _priceRangesData.updatePriceRanges(_stakingTokenData.pool);
            stakingAmount = _updateLiquidity(address(_native), nativeAmount, false);
        } else {
            stakingAmount = _updateLiquidity(address(_native), nativeAmount, true);
        }
    }

    function _depositConvertless(
        uint256 tokenIdConvertless,
        uint256 depositLiquidityAmount,
        uint256 feeLiquidityAmount,
        address feeRecipient,
        address
    ) internal override {
        StakingTokenData storage stakingTokenData_ = _stakingTokenData;
        (, , address token0, address token1, uint24 fee, , , uint256 liquidity_, , , , ) = _stakingToken.positions(
            tokenIdConvertless
        );
        if (token0 != stakingTokenData_.token0 || token1 != stakingTokenData_.token1 || fee != stakingTokenData_.fee)
            revert DepositConvertlessPoolIsInvalid();
        _stakingToken.safeTransferFrom(msg.sender, address(this), tokenIdConvertless);
        (address token, uint256 amount, Swap.SwapPair[] memory path) = _decreaseAndSwapCalculatedMainToken(
            tokenIdConvertless,
            liquidity_,
            stakingTokenData_
        );
        uint256 calculatedLiquidity = depositLiquidityAmount + feeLiquidityAmount;
        uint256 feeRate = (feeLiquidityAmount * Utility.PRECISION) / calculatedLiquidity;
        uint256 feeAmount = (amount * feeRate) / Utility.PRECISION;
        if (tokenId > 0) (, , , , , , , liquidity_, , , , ) = _stakingToken.positions(tokenId);
        if (liquidity_ == 0) {
            _priceRangesData.updatePriceRanges(stakingTokenData_.pool);
            liquidity_ = _updateLiquidity(token, amount - feeAmount, false);
        } else {
            liquidity_ = _updateLiquidity(token, amount - feeAmount, true);
        }
        if (calculatedLiquidity > liquidity_)
            revert DepositConvertlessCalculatedLiquidityGtAdded(calculatedLiquidity, liquidity_);
        if (feeAmount > 0) path.swap(universalRouter, feeAmount, feeRecipient);
    }

    function _harvest() internal override returns (uint256 nativeAmount) {
        nativeAmount = _processRewards();
        _checkOrReassemblyPosition(_stakingTokenData, false);
    }

    function _withdraw(uint256 stakingAmount) internal override returns (uint256 nativeAmount) {
        uint256 balanceBefore = _native.balanceOf(msg.sender);
        StakingTokenData storage stakingTokenData_ = _stakingTokenData;
        (uint256 amountOut0, uint256 amountOut1) = _stakingToken.decreaseLiquidity(
            tokenId,
            address(this),
            stakingAmount,
            false
        );
        stakingTokenData_.swapsToken0ToNative.swap(universalRouter, amountOut0, msg.sender);
        stakingTokenData_.swapsToken1ToNative.swap(universalRouter, amountOut1, msg.sender);
        nativeAmount = (_native.balanceOf(msg.sender) - balanceBefore);
    }

    function _withdrawConvertless(uint256 stakingAmount, address recipient) internal override {
        _stakingToken.decreaseLiquidity(tokenId, recipient, stakingAmount, false);
    }

    function _emergencyWithdraw(uint256 stakingAmount, address recipient) internal override {
        _withdrawConvertless(stakingAmount, recipient);
    }

    function _decodeAndValidateReinitialize(
        bytes memory params
    ) private pure returns (ReinitializationData memory data) {
        data = abi.decode(params, (ReinitializationData));
        if (data.universalRouter == address(0)) revert DecodeReinitializeDataUniversalRouterZero();
        if (data.nonfungiblePositionManager == address(0))
            revert DecodeReinitializeDataNonfungiblePositionManagerZero();
        if (data.liquidityHelper == address(0)) revert DecodeReinitializeDataLiquidityHelperZero();
    }

    function _processRewards() private returns (uint256 nativeAmount) {
        if (tokenId > 0) {
            (uint256 reward0, uint256 reward1) = _stakingToken.collect(
                INonfungiblePositionManager.CollectParams(tokenId, address(this), type(uint128).max, type(uint128).max)
            );
            HarvestDebt storage harvestDebt_ = _harvestDebt;
            StakingTokenData storage stakingTokenData_ = _stakingTokenData;
            harvestDebt_.debt0 += reward0;
            harvestDebt_.debt1 += reward1;
            uint256 balanceToken0 = IERC20(stakingTokenData_.token0).balanceOf(address(this));
            uint256 balanceToken1 = IERC20(stakingTokenData_.token1).balanceOf(address(this));
            if (harvestDebt_.debt0 > balanceToken0) harvestDebt_.debt0 = balanceToken0;
            if (harvestDebt_.debt1 > balanceToken1) harvestDebt_.debt1 = balanceToken1;
            if (harvestDebt_.debt0 >= Utility.MIN_SWAP_AMOUNT) {
                nativeAmount += stakingTokenData_.swapsToken0ToNative.swap(
                    universalRouter,
                    harvestDebt_.debt0,
                    msg.sender
                );
                harvestDebt_.debt0 = 0;
            }
            if (harvestDebt_.debt1 >= Utility.MIN_SWAP_AMOUNT) {
                nativeAmount += stakingTokenData_.swapsToken1ToNative.swap(
                    universalRouter,
                    harvestDebt_.debt1,
                    msg.sender
                );
                harvestDebt_.debt1 = 0;
            }
        }
    }

    function _checkOrReassemblyPosition(StakingTokenData storage stakingTokenData_, bool forcedUpdate) private {
        if (globalUpdate) {
            forcedUpdate = true;
            globalUpdate = false;
        }
        if (tokenId > 0) {
            (uint160 sqrtPriceX96, , , , , , ) = stakingTokenData_.pool.slot0();
            (, , , , , , , uint256 liquidity_, , , , ) = _stakingToken.positions(tokenId);
            if (
                (sqrtPriceX96 <= _priceRangesData.sqrtPriceX96LowLimit ||
                    sqrtPriceX96 >= _priceRangesData.sqrtPriceX96UpLimit ||
                    forcedUpdate) && liquidity_ > 0
            ) {
                _processRewards();
                (address token, uint256 amount, ) = _decreaseAndSwapCalculatedMainToken(
                    tokenId,
                    liquidity_,
                    stakingTokenData_
                );
                if (amount >= Utility.MIN_SWAP_AMOUNT) {
                    _priceRangesData.updatePriceRanges(stakingTokenData_.pool);
                    _updateLiquidity(token, amount, false);
                }
            }
        }
    }

    function _updateLiquidity(address token, uint256 amount, bool increase) private returns (uint256 liquidity_) {
        HarvestDebt storage harvestDebt_ = _harvestDebt;
        StakingTokenData storage stakingTokenData_ = _stakingTokenData;
        PriceManagement.PriceRangesData storage priceRangesData_ = _priceRangesData;
        (uint160 sqrtPriceX96, , , , , , ) = stakingTokenData_.pool.slot0();
        _oracleData.validatePrice(sqrtPriceX96, address(stakingTokenData_.pool));
        uint256 token1Rate = PriceManagement.calculateRateToken1ForAddLiquidity(
            sqrtPriceX96,
            priceRangesData_.sqrtPriceX96Low,
            priceRangesData_.sqrtPriceX96Up
        );
        uint256 amount1Swap = (amount * token1Rate) / Utility.PRECISION;
        uint256 amount0;
        uint256 amount1;
        if (token == address(_native)) {
            amount1 = stakingTokenData_.swapsNativeToToken1.swap(universalRouter, amount1Swap, address(this));
            amount0 = stakingTokenData_.swapsNativeToToken0.swap(universalRouter, amount - amount1Swap, address(this));
        } else {
            if (token == stakingTokenData_.token0) {
                amount1 = stakingTokenData_.swapsToken0ToToken1.swap(universalRouter, amount1Swap, address(this));
                amount0 = amount - amount1;
            } else {
                amount1 = amount1Swap;
                amount0 = stakingTokenData_.swapsToken1ToToken0.swap(
                    universalRouter,
                    amount - amount1Swap,
                    address(this)
                );
            }
        }
        if (increase) {
            liquidity_ = _stakingToken.increaseLiquidity(
                tokenId,
                stakingTokenData_.token0,
                stakingTokenData_.token1,
                amount0,
                amount1
            );
        } else {
            (tokenId, liquidity_) = _stakingToken.addLiquidity(
                stakingTokenData_.token0,
                stakingTokenData_.token1,
                stakingTokenData_.fee,
                priceRangesData_.tickLower,
                priceRangesData_.tickUpper,
                amount0,
                amount1
            );
        }
        stakingTokenData_.swapsToken0ToNative.swap(
            universalRouter,
            IERC20(stakingTokenData_.token0).balanceOf(address(this)) - harvestDebt_.debt0,
            msg.sender
        );
        stakingTokenData_.swapsToken1ToNative.swap(
            universalRouter,
            IERC20(stakingTokenData_.token1).balanceOf(address(this)) - harvestDebt_.debt1,
            msg.sender
        );
    }

    function _decreaseAndSwapCalculatedMainToken(
        uint256 tokenId_,
        uint256 liquidity_,
        StakingTokenData storage stakingTokenData_
    ) internal returns (address token, uint256 amount, Swap.SwapPair[] memory pathToNative) {
        (uint256 amountOut0, uint256 amountOut1) = _stakingToken.decreaseLiquidity(
            tokenId_,
            address(this),
            liquidity_,
            true
        );
        IDexFiUniversalRouterBytes universalRouter_ = universalRouter;
        uint256 getAmountOut0 = stakingTokenData_.swapsToken0ToNative.getAmountOut(universalRouter_, amountOut0);
        uint256 getAmountOut1 = stakingTokenData_.swapsToken1ToNative.getAmountOut(universalRouter_, amountOut1);
        if (getAmountOut0 < getAmountOut1) {
            token = stakingTokenData_.token1;
            pathToNative = stakingTokenData_.swapsToken1ToNative;
            amount += getAmountOut1;
            amount += stakingTokenData_.swapsToken0ToToken1.swap(universalRouter_, amountOut0, address(this));
        } else {
            token = stakingTokenData_.token0;
            pathToNative = stakingTokenData_.swapsToken0ToNative;
            amount += getAmountOut0;
            amount += stakingTokenData_.swapsToken1ToToken0.swap(universalRouter_, amountOut1, address(this));
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IDexFiUniversalRouterBytes {
    struct DatasetItem {
        uint256 position;
        bytes data;
    }

    struct DataConfiguration {
        address tokenIn;
        address tokenOut;
        DatasetItem[] swapDataset;
        DatasetItem[] getAmountInDataset;
        DatasetItem[] getAmountOutDataset;
    }

    struct GetConfiguration {
        bytes4 signature;
        uint256 amountPosition;
        uint256 addressSenderPosition;
        uint256 dataWordsLength;
        uint256 responseNum;
    }

    struct FeeConfiguration {
        uint256 swapFee;
        uint256 divider;
    }

    struct PairConfiguration {
        address router;
        bytes4 signatureSwap;
        uint256 amountInPositionSwap;
        uint256 amountOutMinPositionSwap;
        uint256 receiverPositionSwap;
        uint256 deadlinePositionSwap;
        uint256 dataWordsLengthSwap;
        address quoter;
        GetConfiguration getAmountInConfiguration;
        GetConfiguration getAmountOutConfiguration;
        FeeConfiguration feeConfiguration;
    }

    struct Configuration {
        address tokenIn;
        address tokenOut;
        PairConfiguration pairConfiguration;
    }

    function pairConfiguration(
        address tokenIn,
        address tokenOut
    ) external view returns (PairConfiguration memory result);

    function swapConfigurationData(address, address, uint256) external view returns (bytes memory);

    function getAmountInConfigurationData(address, address, uint256) external view returns (bytes memory);

    function getAmountOutConfigurationData(address, address, uint256) external view returns (bytes memory);

    event ConfigurationUpdated(address indexed tokenIn, address indexed tokenOut, PairConfiguration config);
    event ConfigurationSwapDataUpdated(address indexed tokenIn, address indexed tokenOut, DatasetItem[] dataset);
    event ConfigurationGetAmountInDataUpdated(address indexed tokenIn, address indexed tokenOut, DatasetItem[] dataset);
    event ConfigurationGetAmountOutDataUpdated(
        address indexed tokenIn,
        address indexed tokenOut,
        DatasetItem[] dataset
    );

    error UniversalRouterWrongParameters();
    error UniversalRouterSwapTokensNotSupported();

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _receiver
    ) external returns (bool);

    function getAmountOut(uint256 _amountIn, address _tokenIn, address _tokenOut) external returns (uint256 amountOut);

    function getAmountIn(uint256 _amountOut, address _tokenIn, address _tokenOut) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @notice Thrown when the tick passed to #getSqrtRatioAtTick is not between MIN_TICK and MAX_TICK
    error InvalidTick();
    /// @notice Thrown when the ratio passed to #getTickAtSqrtRatio does not correspond to a price between MIN_TICK and MAX_TICK
    error InvalidSqrtRatio();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum tick spacing value drawn from the range of type int16 that is greater than 0, i.e. min from the range [1, 32767]
    int24 internal constant MIN_TICK_SPACING = 1;
    /// @dev The maximum tick spacing value drawn from the range of type int16, i.e. max from the range [1, 32767]
    int24 internal constant MAX_TICK_SPACING = type(int16).max;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Given a tickSpacing, compute the maximum usable tick
    function maxUsableTick(int24 tickSpacing) internal pure returns (int24) {
        unchecked {
            return (MAX_TICK / tickSpacing) * tickSpacing;
        }
    }

    /// @notice Given a tickSpacing, compute the minimum usable tick
    function minUsableTick(int24 tickSpacing) internal pure returns (int24) {
        unchecked {
            return (MIN_TICK / tickSpacing) * tickSpacing;
        }
    }

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (currency1/currency0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert InvalidTick();

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
            if (sqrtPriceX96 < MIN_SQRT_RATIO || sqrtPriceX96 >= MAX_SQRT_RATIO) revert InvalidSqrtRatio();
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(address spender, uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "./IPoolInitializer.sol";
import "./IERC721Permit.sol";
import "./IPeripheryPayments.sol";
import "./IPeripheryImmutableState.sol";

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(
        MintParams calldata params
    ) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(address token, uint256 amountMinimum, address recipient) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

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
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "./pool/IUniswapV3PoolImmutables.sol";
import "./pool/IUniswapV3PoolState.sol";
import "./pool/IUniswapV3PoolDerivedState.sol";
import "./pool/IUniswapV3PoolActions.sol";
import "./pool/IUniswapV3PoolOwnerActions.sol";
import "./pool/IUniswapV3PoolEvents.sol";

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
    IUniswapV3PoolEvents
{
    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
        uint16 observationIndex;
        uint16 observationCardinality;
        uint16 observationCardinalityNext;
        uint32 feeProtocol;
        bool unlocked;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

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
    function burn(int24 tickLower, int24 tickUpper, uint128 amount) external returns (uint256 amount0, uint256 amount1);

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
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

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
    function observe(
        uint32[] calldata secondsAgos
    ) external view returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(
        int24 tickLower,
        int24 tickUpper
    ) external view returns (int56 tickCumulativeInside, uint160 secondsPerLiquidityInsideX128, uint32 secondsInside);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
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
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(
        int24 tick
    )
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
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(
        bytes32 key
    )
        external
        view
        returns (
            uint128 _liquidity,
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
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(
        uint256 index
    )
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {INonfungiblePositionManager} from "../../../../utils/Uniswap/interfaces/INonfungiblePositionManager.sol";
import {IUniswapV3Pool} from "../../../../utils/Uniswap/interfaces/IUniswapV3Pool.sol";
import {FixedPoint128} from "../../../../utils/Uniswap/libraries/FixedPoint128.sol";
import {FullMath} from "../../../../utils/Uniswap/libraries/LiquidityAmounts.sol";

library FeeMath {
    using FullMath for uint256;

    function calculateUnclaimedFeeByPositionId(
        uint256 positionId,
        IUniswapV3Pool pool,
        INonfungiblePositionManager positionManager,
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128
    ) external view returns (uint128 amount0, uint128 amount1) {
        (, , uint256 feeGrowthOutside0X128Lower, uint256 feeGrowthOutside1X128Lower, , , , ) = pool.ticks(tickLower);
        (, , uint256 feeGrowthOutside0X128Upper, uint256 feeGrowthOutside1X128Upper, , , , ) = pool.ticks(tickUpper);
        uint256 feeGrowthBelow0X128;
        uint256 feeGrowthBelow1X128;
        if (tickCurrent >= tickLower) {
            feeGrowthBelow0X128 = feeGrowthOutside0X128Lower;
            feeGrowthBelow1X128 = feeGrowthOutside1X128Lower;
        } else {
            feeGrowthBelow0X128 = feeGrowthGlobal0X128 - feeGrowthOutside0X128Lower;
            feeGrowthBelow1X128 = feeGrowthGlobal1X128 - feeGrowthOutside1X128Lower;
        }
        uint256 feeGrowthAbove0X128;
        uint256 feeGrowthAbove1X128;
        if (tickCurrent < tickUpper) {
            feeGrowthAbove0X128 = feeGrowthOutside0X128Upper;
            feeGrowthAbove1X128 = feeGrowthOutside1X128Upper;
        } else {
            feeGrowthAbove0X128 = feeGrowthGlobal0X128 - feeGrowthOutside0X128Upper;
            feeGrowthAbove1X128 = feeGrowthGlobal1X128 - feeGrowthOutside1X128Upper;
        }
        uint256 feeGrowthInside0LastX128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
        uint256 feeGrowthInside1LastX128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128Manager,
            uint256 feeGrowthInside1LastX128Manager,
            uint128 owed0,
            uint128 owed1
        ) = positionManager.positions(positionId);
        amount0 =
            owed0 +
            uint128((feeGrowthInside0LastX128 - feeGrowthInside0LastX128Manager).mulDiv(liquidity, FixedPoint128.Q128));
        amount1 =
            owed1 +
            uint128((feeGrowthInside1LastX128 - feeGrowthInside1LastX128Manager).mulDiv(liquidity, FixedPoint128.Q128));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {INonfungiblePositionManager} from "../../../../utils/Uniswap/interfaces/INonfungiblePositionManager.sol";
import {Utility} from "./Utility.sol";

library LiquidityManagement {
    using SafeERC20 for IERC20;

    error DecreaseLiquidityAmountGtLiquidity(uint256 amountIn, uint256 liquidityPosition);

    function addLiquidity(
        INonfungiblePositionManager positionManager,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) external returns (uint256 positionId, uint256 liquidity) {
        IERC20(token0).forceApprove(address(positionManager), amount0);
        IERC20(token1).forceApprove(address(positionManager), amount1);
        (positionId, liquidity, , ) = positionManager.mint(
            INonfungiblePositionManager.MintParams(
                token0,
                token1,
                fee,
                tickLower,
                tickUpper,
                amount0,
                amount1,
                Utility.MIN_SWAP_AMOUNT,
                Utility.MIN_SWAP_AMOUNT,
                address(this),
                block.timestamp
            )
        );
    }

    function increaseLiquidity(
        INonfungiblePositionManager positionManager,
        uint256 positionId,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) external returns (uint256 liquidity) {
        IERC20(token0).forceApprove(address(positionManager), amount0);
        IERC20(token1).forceApprove(address(positionManager), amount1);
        (liquidity, , ) = positionManager.increaseLiquidity(
            INonfungiblePositionManager.IncreaseLiquidityParams(
                positionId,
                amount0,
                amount1,
                Utility.MIN_SWAP_AMOUNT,
                Utility.MIN_SWAP_AMOUNT,
                block.timestamp
            )
        );
    }

    function decreaseLiquidity(
        INonfungiblePositionManager positionManager,
        uint256 positionId,
        address recipient,
        uint256 amountIn,
        bool collectAll
    ) external returns (uint256 amountOutReal0, uint256 amountOutReal1) {
        (, , , , , , , uint256 liquidity_, , , , ) = positionManager.positions(positionId);
        if (amountIn > liquidity_) revert DecreaseLiquidityAmountGtLiquidity(amountIn, liquidity_);
        (uint256 amountOut0, uint256 amountOut1) = positionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams(
                positionId,
                uint128(amountIn),
                Utility.MIN_SWAP_AMOUNT,
                Utility.MIN_SWAP_AMOUNT,
                block.timestamp
            )
        );
        if (collectAll) {
            amountOut0 = type(uint128).max;
            amountOut1 = type(uint128).max;
        }
        (amountOutReal0, amountOutReal1) = positionManager.collect(
            INonfungiblePositionManager.CollectParams(positionId, recipient, uint128(amountOut0), uint128(amountOut1))
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {IV3PriceOracleValidator} from "../../../../utils/V3Utilities/interfaces/IV3PriceOracleValidator.sol";

library Oracle {
    struct OracleData {
        IV3PriceOracleValidator oracle;
        uint256 deviation;
        uint256 lastValidatePriceTimestamp;
    }

    error DeviationRateLimitLtLiveDeviation(uint256 deviationLimit, uint256 liveDeviation);

    function validatePrice(OracleData storage self, uint256 sqrtPriceX96, address pool) external {
        if (self.lastValidatePriceTimestamp < block.timestamp) {
            (bool valid, uint256 livePriceToken0ToToken1, uint256 meanPriceToken0ToToken1) = self.oracle.validatePrice(
                sqrtPriceX96,
                self.deviation,
                pool
            );
            if (!valid) revert DeviationRateLimitLtLiveDeviation(livePriceToken0ToToken1, meanPriceToken0ToToken1);
            self.lastValidatePriceTimestamp = block.timestamp;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {LiquidityAmounts, FullMath} from "../../../../utils/Uniswap/libraries/LiquidityAmounts.sol";
import {IUniswapV3Pool} from "../../../../utils/Uniswap/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "../../../../utils/Uniswap/libraries/TickMath.sol";
import {Utility} from "./Utility.sol";

library PriceManagement {
    using FullMath for uint256;
    using LiquidityAmounts for uint160;

    struct PriceRangesData {
        int24 tickLower;
        int24 tickUpper;
        uint256 sqrtPriceX96Low;
        uint256 sqrtPriceX96Up;
        uint256 sqrtPriceX96LowLimit;
        uint256 sqrtPriceX96UpLimit;
        uint256 approxToRangeLimitPercent;
        uint256 deviationPercentLow;
        uint256 deviationPercentUp;
        uint256 defaultDeviationPercentLow;
        uint256 defaultDeviationPercentUp;
    }

    function updatePriceRanges(PriceRangesData storage self, IUniswapV3Pool pool) external {
        uint256 precision = Utility.PRECISION;
        uint256 lowShift = self.defaultDeviationPercentLow;
        uint256 upShift = self.defaultDeviationPercentUp;
        if (self.deviationPercentLow > 0 && self.deviationPercentUp > 0) {
            lowShift = self.deviationPercentLow;
            upShift = self.deviationPercentUp;
        }
        (uint256 sqrtPriceX96, int24 currentTick, , , , , ) = pool.slot0();
        int24 tickSpacing = pool.tickSpacing();
        uint256 amountToken1PerToken0 = calculateRatioToken0ToToken1(precision, uint256(sqrtPriceX96));
        uint256 rateShiftLow = (amountToken1PerToken0 * lowShift) / precision;
        uint256 rateShiftUp = (amountToken1PerToken0 * upShift) / precision;
        self.sqrtPriceX96Low = calculateSqrtPriceX96FromPrice(amountToken1PerToken0 - rateShiftLow);
        if (self.sqrtPriceX96Low < TickMath.MIN_SQRT_RATIO) self.sqrtPriceX96Low = TickMath.MIN_SQRT_RATIO;
        self.sqrtPriceX96Up = calculateSqrtPriceX96FromPrice(amountToken1PerToken0 + rateShiftUp);
        if (self.sqrtPriceX96Up >= TickMath.MAX_SQRT_RATIO) self.sqrtPriceX96Up = TickMath.MAX_SQRT_RATIO - 1;
        self.tickLower = (TickMath.getTickAtSqrtRatio(uint160(self.sqrtPriceX96Low)) / tickSpacing) * tickSpacing;
        self.tickUpper = (TickMath.getTickAtSqrtRatio(uint160(self.sqrtPriceX96Up)) / tickSpacing) * tickSpacing;
        self.sqrtPriceX96Low = TickMath.getSqrtRatioAtTick(self.tickLower);
        self.sqrtPriceX96Up = TickMath.getSqrtRatioAtTick(self.tickUpper);
        if (self.tickLower > currentTick) self.tickLower -= tickSpacing;
        if (self.tickUpper < currentTick) self.tickUpper += tickSpacing;
        self.sqrtPriceX96LowLimit = calculateSqrtPriceX96FromPrice(
            amountToken1PerToken0 - rateShiftLow + (rateShiftLow * self.approxToRangeLimitPercent) / precision
        );
        self.sqrtPriceX96UpLimit = calculateSqrtPriceX96FromPrice(
            amountToken1PerToken0 + rateShiftUp - (rateShiftUp * self.approxToRangeLimitPercent) / precision
        );
    }

    function calculateRatioToken1ToToken0(uint256 amount, uint256 sqrtPriceX96) external pure returns (uint256) {
        return amount.mulDiv(1 << 192, uint256(sqrtPriceX96) ** 2);
    }

    function calculateRateToken1ForAddLiquidity(
        uint160 sqrtPriceX96,
        uint256 sqrtPriceX96Low,
        uint256 sqrtPriceX96Up
    ) external pure returns (uint256 token1Rate) {
        (uint256 amount0, uint256 amount1) = sqrtPriceX96.getAmountsForLiquidity(
            uint160(sqrtPriceX96Low),
            uint160(sqrtPriceX96Up),
            uint128(Utility.PRECISION)
        );
        token1Rate =
            (amount1 * Utility.PRECISION) /
            (calculateRatioToken0ToToken1(amount0, uint256(sqrtPriceX96)) + amount1);
    }

    function calculateRateTokensPerLiquidity(
        uint160 sqrtPriceX96,
        uint256 sqrtPriceX96Low,
        uint256 sqrtPriceX96Up
    ) external pure returns (uint256 token1Rate) {
        (uint256 amount0, uint256 amount1) = sqrtPriceX96.getAmountsForLiquidity(
            uint160(sqrtPriceX96Low),
            uint160(sqrtPriceX96Up),
            uint128(Utility.PRECISION)
        );
        token1Rate =
            (amount1 * Utility.PRECISION) /
            (calculateRatioToken0ToToken1(amount0, uint256(sqrtPriceX96)) + amount1);
    }

    function calculateSqrtPriceX96FromPrice(uint256 price) public pure returns (uint256) {
        return price.mulDiv(1 << 192, Utility.PRECISION).sqrt();
    }

    function calculateRatioToken0ToToken1(uint256 amount, uint256 sqrtPriceX96) public pure returns (uint256) {
        return amount.mulDiv(uint256(sqrtPriceX96) ** 2, 1 << 192);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {Utility} from "./Utility.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IDexFiUniversalRouterBytes} from "../../../../common/interfaces/IDexFiUniversalRouterBytes.sol";

library Swap {
    using SafeERC20 for IERC20;

    error ValidateSwapPathPathDisjoined(SwapPair[]);
    error ValidateSwapPathPathTokenInNotEqRequiredTokenIn(address pathTokenIn, address tokenIn);
    error ValidateSwapPathPathTokenOutNotEqRequiredTokenOut(address pathTokenOut, address tokenOut);

    struct SwapPair {
        address tokenIn;
        address tokenOut;
    }

    function swap(
        SwapPair[] memory path,
        IDexFiUniversalRouterBytes router,
        uint256 amountIn,
        address recipient
    ) internal returns (uint256 amountOut) {
        uint256 swapsLength = path.length;
        amountOut = amountIn;
        if (path[0].tokenIn == path[swapsLength - 1].tokenOut && amountIn > 0) {
            if (recipient != address(this)) IERC20(path[0].tokenIn).safeTransfer(recipient, amountOut);
        } else if (amountIn >= Utility.MIN_SWAP_AMOUNT) {
            for (uint256 i = 0; i < swapsLength; i++) {
                address middleRecipient = i == swapsLength - 1 ? recipient : address(this);
                SwapPair memory pair = path[i];
                IERC20 tokenOut = IERC20(pair.tokenOut);
                uint256 tokenOutBalanceBefore = tokenOut.balanceOf(middleRecipient);
                IERC20(pair.tokenIn).forceApprove(address(router), amountOut);
                router.swap(pair.tokenIn, pair.tokenOut, amountOut, Utility.MIN_AMOUNT_OUT, middleRecipient);
                amountOut = tokenOut.balanceOf(middleRecipient) - tokenOutBalanceBefore;
            }
        }
    }

    function getAmountOut(
        SwapPair[] memory path,
        IDexFiUniversalRouterBytes router,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        uint256 swapsLength = path.length;
        amountOut = amountIn;
        if (path[0].tokenIn != path[swapsLength - 1].tokenOut && amountIn > 0) {
            for (uint256 i = 0; i < swapsLength; i++) {
                SwapPair memory pair = path[i];
                if (amountOut < Utility.MIN_SWAP_AMOUNT) {
                    amountOut = 0;
                    break;
                }
                amountOut = router.getAmountOut(amountOut, pair.tokenIn, pair.tokenOut);
            }
        }
    }

    function validateSwapPath(SwapPair[] memory path, address tokenIn, address tokenOut) internal pure {
        uint256 swapsCount = path.length - 1;
        if (path[0].tokenIn != tokenIn)
            revert ValidateSwapPathPathTokenInNotEqRequiredTokenIn(path[0].tokenIn, tokenIn);
        if (path[swapsCount].tokenOut != tokenOut)
            revert ValidateSwapPathPathTokenOutNotEqRequiredTokenOut(path[swapsCount].tokenOut, tokenOut);
        for (uint256 i = 0; i < swapsCount; i++) {
            if (path[i].tokenOut != path[i + 1].tokenIn) revert ValidateSwapPathPathDisjoined(path);
        }
    }

    function reverseSwapPath(SwapPair[] memory path) internal pure returns (SwapPair[] memory output) {
        uint256 swapsLength = path.length;
        output = new SwapPair[](swapsLength);
        for (uint256 i = 0; i < swapsLength; i++) {
            SwapPair memory pair = path[swapsLength - 1 - i];
            output[i] = SwapPair({tokenIn: pair.tokenOut, tokenOut: pair.tokenIn});
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

library Utility {
    uint256 public constant PRECISION = 1e18;
    uint256 public constant MIN_SWAP_AMOUNT = 1e4;
    uint256 public constant MIN_AMOUNT_OUT = 0;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

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
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0 = a * b; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

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
            // correct result modulo 2**256. Since the preconditions guarantee
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
    function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) {
            return 0;
        }
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "./FullMath.sol";
import "./FixedPoint96.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @notice Thrown when the tick passed to #getSqrtRatioAtTick is not between MIN_TICK and MAX_TICK
    error InvalidTick();
    /// @notice Thrown when the ratio passed to #getTickAtSqrtRatio does not correspond to a price between MIN_TICK and MAX_TICK
    error InvalidSqrtRatio();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum tick spacing value drawn from the range of type int16 that is greater than 0, i.e. min from the range [1, 32767]
    int24 internal constant MIN_TICK_SPACING = 1;
    /// @dev The maximum tick spacing value drawn from the range of type int16, i.e. max from the range [1, 32767]
    int24 internal constant MAX_TICK_SPACING = type(int16).max;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Given a tickSpacing, compute the maximum usable tick
    function maxUsableTick(int24 tickSpacing) internal pure returns (int24) {
        unchecked {
            return (MAX_TICK / tickSpacing) * tickSpacing;
        }
    }

    /// @notice Given a tickSpacing, compute the minimum usable tick
    function minUsableTick(int24 tickSpacing) internal pure returns (int24) {
        unchecked {
            return (MIN_TICK / tickSpacing) * tickSpacing;
        }
    }

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (currency1/currency0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert InvalidTick();

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
            if (sqrtPriceX96 < MIN_SQRT_RATIO || sqrtPriceX96 >= MAX_SQRT_RATIO) revert InvalidSqrtRatio();
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {INonfungiblePositionManager} from "../../Uniswap/interfaces/INonfungiblePositionManager.sol";
import {IDexFiUniversalRouterBytes} from "../../../common/interfaces/IDexFiUniversalRouterBytes.sol";
import {Swap} from "../../Uniswap/libraries/custom/Swap.sol";

interface IV3LiquidityHelper {
    struct PositionInfo {
        address token0;
        address token1;
        uint24 fee;
        address pool;
        address owner;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0;
        uint256 amount1;
        uint256 lowPrice;
        uint256 upPrice;
        bool tickIn;
    }

    struct PositionManagerInput {
        address positionManager;
        uint256 tokenId;
    }

    struct PositionPoolInput {
        address pool;
        address owner;
        int24 tickLower;
        int24 tickUpper;
    }

    function positionManagerInfo(
        PositionManagerInput[] memory input
    ) external view returns (PositionInfo[] memory output);

    function positionPoolInfo(PositionPoolInput[] memory input) external view returns (PositionInfo[] memory output);

    error FromPoolIsInvalid(address fromPool, address toPool);

    function calculateNewLiquidityFromOldPosition(
        IDexFiUniversalRouterBytes universalRouter,
        INonfungiblePositionManager positionManager,
        uint256 fromTokenId,
        uint256 toTokenId,
        Swap.SwapPair[] memory swapsToken0ToCommonToken,
        Swap.SwapPair[] memory swapsToken1ToCommonToken
    ) external returns (uint256 liquidity);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface IV3PriceOracleValidator {
    function validatePrice(
        uint256 liveSqrtPriceX96,
        uint256 deviation,
        address pool
    ) external view returns (bool valid, uint256 livePriceToken0ToToken1, uint256 meanPriceToken0ToToken1);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IV3LiquidityHelper} from "./interfaces/IV3LiquidityHelper.sol";
import {Swap} from "../Uniswap/libraries/custom/Swap.sol";
import {FeeMath} from "../Uniswap/libraries/custom/FeeMath.sol";
import {TickMath} from "../PancakeSwap/libraries/TickMath.sol";
import {IUniswapV3Pool} from "../Uniswap/interfaces/IUniswapV3Pool.sol";
import {PriceManagement} from "../Uniswap/libraries/custom/PriceManagement.sol";
import {IUniswapV3Factory} from "../Uniswap/interfaces/IUniswapV3Factory.sol";
import {IDexFiUniversalRouterBytes} from "../../common/interfaces/IDexFiUniversalRouterBytes.sol";
import {LiquidityAmounts, FullMath} from "../../utils/Uniswap/libraries/LiquidityAmounts.sol";
import {INonfungiblePositionManager} from "../../utils/Uniswap/interfaces/INonfungiblePositionManager.sol";

contract V3LiquidityHelper is IV3LiquidityHelper {
    using LiquidityAmounts for uint160;
    using FullMath for uint256;
    using FeeMath for uint256;
    using Swap for Swap.SwapPair[];

    uint256 public constant PRECISION = 1e18;

    function positionManagerInfo(
        PositionManagerInput[] memory input
    ) external view returns (PositionInfo[] memory output) {
        uint256 len = input.length;
        output = new PositionInfo[](len);
        for (uint256 i = 0; i < len; i++) {
            PositionManagerInput memory param_ = input[i];
            INonfungiblePositionManager positionManager = INonfungiblePositionManager(param_.positionManager);
            if (param_.tokenId == 0) continue;
            try positionManager.ownerOf(param_.tokenId) returns (address owner) {
                if (owner == address(0)) continue;
                output[i].owner = owner;
            } catch {
                continue;
            }
            uint128 liquidity;
            (
                ,
                ,
                output[i].token0,
                output[i].token1,
                output[i].fee,
                output[i].tickLower,
                output[i].tickUpper,
                liquidity,
                ,
                ,
                ,

            ) = positionManager.positions(param_.tokenId);
            IUniswapV3Pool pool = IUniswapV3Pool(
                IUniswapV3Factory(positionManager.factory()).getPool(output[i].token0, output[i].token1, output[i].fee)
            );
            output[i].pool = address(pool);
            if (liquidity == 0) continue;
            (
                output[i].tickIn,
                output[i].amount0,
                output[i].amount1,
                output[i].lowPrice,
                output[i].upPrice
            ) = _generalCalculation(pool, liquidity, output[i].token0, output[i].tickLower, output[i].tickUpper);
        }
    }

    function positionPoolInfo(PositionPoolInput[] memory input) external view returns (PositionInfo[] memory output) {
        uint256 len = input.length;
        output = new PositionInfo[](len);
        for (uint256 i = 0; i < len; i++) {
            PositionPoolInput memory param_ = input[i];
            IUniswapV3Pool pool = IUniswapV3Pool(param_.pool);
            (uint128 liquidity, , , , ) = pool.positions(
                keccak256(abi.encodePacked(param_.owner, param_.tickLower, param_.tickUpper))
            );
            output[i].token0 = pool.token0();
            output[i].token1 = pool.token1();
            output[i].fee = pool.fee();
            output[i].pool = param_.pool;
            output[i].owner = param_.owner;
            output[i].tickLower = param_.tickLower;
            output[i].tickUpper = param_.tickUpper;
            if (liquidity == 0) continue;
            (
                output[i].tickIn,
                output[i].amount0,
                output[i].amount1,
                output[i].lowPrice,
                output[i].upPrice
            ) = _generalCalculation(pool, liquidity, output[i].token0, output[i].tickLower, output[i].tickUpper);
        }
    }

    function calculateNewLiquidityFromOldPosition(
        IDexFiUniversalRouterBytes universalRouter,
        INonfungiblePositionManager positionManager,
        uint256 fromTokenId,
        uint256 toTokenId,
        Swap.SwapPair[] memory swapsToken0ToCommonToken,
        Swap.SwapPair[] memory swapsToken1ToCommonToken
    ) external returns (uint256 liquidity) {
        (
            ,
            ,
            address fromToken0,
            address fromToken1,
            uint24 fromFee,
            int24 fromTickLower,
            int24 fromTickUpper,
            uint256 fromLiquidity,
            ,
            ,
            ,

        ) = positionManager.positions(fromTokenId);
        IUniswapV3Pool fromPool = IUniswapV3Pool(
            IUniswapV3Factory(positionManager.factory()).getPool(fromToken0, fromToken1, fromFee)
        );
        (
            ,
            ,
            address toToken0,
            address toToken1,
            uint24 toFee,
            int24 toTickLower,
            int24 toTickUpper,
            ,
            ,
            ,
            ,

        ) = positionManager.positions(toTokenId);
        IUniswapV3Pool toPool = IUniswapV3Pool(
            IUniswapV3Factory(positionManager.factory()).getPool(toToken0, toToken1, toFee)
        );
        if (fromPool != toPool) revert FromPoolIsInvalid(address(fromPool), address(toPool));
        uint256 precision_ = PRECISION;
        (uint160 sqrtPriceX96, int24 currentTick, , , , , ) = toPool.slot0();
        uint160 toSqrtPriceX96Low = uint160(TickMath.getSqrtRatioAtTick(toTickLower));
        uint160 toSqrtPriceX96Up = uint160(TickMath.getSqrtRatioAtTick(toTickUpper));
        (uint256 amount0, uint256 amount1) = sqrtPriceX96.getAmountsForLiquidity(
            toSqrtPriceX96Low,
            toSqrtPriceX96Up,
            uint128(precision_)
        );
        uint256 token1Rate = (amount1 * precision_) /
            (PriceManagement.calculateRatioToken0ToToken1(amount0, uint256(sqrtPriceX96)) + amount1);
        (amount0, amount1) = sqrtPriceX96.getAmountsForLiquidity(
            uint160(TickMath.getSqrtRatioAtTick(fromTickLower)),
            uint160(TickMath.getSqrtRatioAtTick(fromTickUpper)),
            uint128(fromLiquidity)
        );
        (uint256 amount0Fee, uint256 amount1Fee) = fromTokenId.calculateUnclaimedFeeByPositionId(
            toPool,
            positionManager,
            fromTickLower,
            fromTickUpper,
            currentTick,
            toPool.feeGrowthGlobal0X128(),
            toPool.feeGrowthGlobal1X128()
        );
        uint256 totalCommonAmount = swapsToken0ToCommonToken.getAmountOut(universalRouter, amount0 + amount0Fee);
        totalCommonAmount += swapsToken1ToCommonToken.getAmountOut(universalRouter, amount1 + amount1Fee);
        uint256 amount1Rate = (totalCommonAmount * token1Rate) / precision_;
        amount0 = swapsToken0ToCommonToken.getAmountOut(universalRouter, totalCommonAmount - amount1Rate);
        amount1 = swapsToken1ToCommonToken.getAmountOut(universalRouter, amount1Rate);
        liquidity = sqrtPriceX96.getLiquidityForAmounts(toSqrtPriceX96Low, toSqrtPriceX96Up, amount0, amount1);
    }

    function _generalCalculation(
        IUniswapV3Pool pool,
        uint128 liquidity,
        address token0,
        int24 tickLower,
        int24 tickUpper
    ) private view returns (bool tickIn, uint256 amount0, uint256 amount1, uint256 lowPrice, uint256 upPrice) {
        (uint160 sqrtPriceX96, int24 currentTick, , , , , ) = pool.slot0();
        if (tickLower < currentTick && tickUpper > currentTick) tickIn = true;
        uint160 sqrtPriceX96Low = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtPriceX96Up = TickMath.getSqrtRatioAtTick(tickUpper);
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            sqrtPriceX96Low,
            sqrtPriceX96Up,
            liquidity
        );
        uint256 oneToken0 = 10 ** IERC20Metadata(token0).decimals();
        lowPrice = PriceManagement.calculateRatioToken0ToToken1(oneToken0, sqrtPriceX96Low);
        upPrice = PriceManagement.calculateRatioToken0ToToken1(oneToken0, sqrtPriceX96Up);
    }
}