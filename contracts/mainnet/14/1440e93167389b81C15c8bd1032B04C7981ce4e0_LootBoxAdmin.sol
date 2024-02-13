// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./data-access/IAccessControlStorage.sol";

/**
 * @dev Original implementation was taken from \@openzeppelin/contracts/access/AccessControl.sol
 *      Storageless implementation.
 * Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControlStorage, IAccessControl, ERC165 {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev The specified account has no required role to access.
     * @param account Account which violates the access.
     * @param role Required role.
     */
    error AccessDenied(address account, bytes32 role);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles(role).members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (hasRole(role, account)) {
            return;
        }
        revert AccessDenied(account, role);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles(role).adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles(role).adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles(role).members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles(role).members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

abstract contract IAccessControlStorage {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PRIZE_MANAGER_ROLE = keccak256("PRIZE_MANAGER_ROLE");

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    function _roles(bytes32 role) internal view virtual returns (RoleData storage);
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

import "../IdType.sol";


abstract contract IBalanceStorage {
    struct NFTCounter {
        uint32 mysteryCount;
        uint32 emptyCount;
        uint32[6] rarityIdToCount;

        IdType mysteryHead;
        IdType emptyHead;
        IdType[6] rarityIdToHead;
    }

    function _balances(address user) internal view virtual returns (NFTCounter storage);
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

import "../ProbabilityType.sol";

abstract contract IConfigStorage {
    struct Config {
        address vrfCoordinator;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        //:256
        uint16 requestConfirmations;
        uint16 maxBoost;
        /// Share of jackpot send to winner.
        Probability jackpotShare;
        Probability jackpotPriceShare;
        address signer;
        uint32 reserved;
        //:256
        bytes32 keyHash;
        //:256
        // stub (320 bytes)
        bytes32[10] _placeHolder;
    }

    function _config() internal virtual view returns (Config storage);
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

import "../ProbabilityType.sol";

abstract contract IJackpotStorage {
    function _jackpot(address token) internal virtual view returns (uint);
    function _addJackpot(address token, int amount) internal virtual;
    function _listJackpots() internal virtual view returns (address[] storage);
    function _jackpotShare() internal virtual view returns (Probability);
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

import "../IdType.sol";

abstract contract ILootBoxStorage {
    struct Scope {
        uint32 begin;
        uint32 end;
        uint64 reserved;
        uint8 alwaysBurn;

        uint256 maxIncome;
        uint256 totalIncome;

        // 136 + 512 + 120 = 256 * 3
        uint120 reserved2;
    }

    struct Counters {
        // holds the next token id
        IdType nextBoxId;
        // how many unsatisfied request are
        uint16 claimRequestCounter;
        // empty (jackpot) loot boxes global counter
        uint32 emptyCounter;

        // 112 + 16 + (32 * 4) = 256
        uint16 reserved;
        bytes32[4] reserved2;
    }

    function _nextTokenId() internal virtual returns (IdType) {
        return _nextTokenId(1);
    }

    function _nextTokenId(uint count) internal virtual returns (IdType);

    function _scope() internal view virtual returns (Scope storage);

    function _scope(Scope memory scope) internal virtual;

    function _counters() internal view virtual returns (Counters memory);

    function _addEmptyCounter(int32 amount) internal virtual;

    function _addTotalIncome(uint256 amount) internal virtual;

    function _increaseClaimRequestCounter(uint16 amount) internal virtual;

    function _decreaseClaimRequestCounter(uint16 amount) internal virtual;
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

import "../IdType.sol";
import "../StateType.sol";

abstract contract INftStorage {
    using StateTypeLib for StateType;

    uint8 public constant NFT_FLAG_LOCKED = 1; // flag

    uint16 public constant MIN_NFT_BOOST = 1;

    uint16 public constant MAX_BUY_COUNT = 20;
    uint16 public constant MIN_BUY_COUNT = 1;

    uint16 public constant LB_RARITIES = 3;

    // we might have max 2^64 - 1 NFTs
    struct NFTDef {
        address owner;
        IdType left;
        StateType state;
        uint8 flags;
        uint16 boost;
        // 256 segment
        address approval;
        IdType right;
        uint32 entropy;
    }

    function _name() internal view virtual returns (string storage);
    function _symbol() internal view virtual returns (string storage);
    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string storage);
    function _baseURI(string memory baseUri) internal virtual;

    function _nft(IdType tokenId, NFTDef memory definition) internal virtual;
    function _nft(IdType tokenId) internal view virtual returns (NFTDef storage);
    function _deleteNft(IdType tokenId) internal virtual;

    function _operatorApprovals(address owner, address operator) internal view virtual returns (bool);
    function _operatorApprovals(address owner, address operator, bool value) internal virtual;
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

abstract contract IPriceStorage {
    function _price(address token) internal virtual view returns (uint);
    function _price(address token, uint price) internal virtual;
    function _delPrice(address token) internal virtual;
    function _addTokenToPrice(address token) internal virtual;
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

import "../ProbabilityType.sol";

abstract contract IPrizeStorage {
    struct NftInfo {
        address collection;
        uint tokenId;
        Probability probability;
        uint32 chainId;
    }

    uint internal constant RARITIES = 3;
    uint internal constant RARITY_GRAND_PRIZE = 2;
    uint32 internal constant MIN_PRIZE_INDEX = 0;
    uint32 internal constant MIN_GROUP_INDEX = 0;
    // we split integer
    uint32 internal constant RARITY_PRIZE_CAPACITY = 500_000;
    uint32 internal constant PRIZE_GROUP_CAPACITY = 1_000;

    function _rarity(uint level) internal view virtual returns (RarityDef storage);
    function _rarity(uint level, Probability probability) internal virtual;

    function _groups(uint32 groupId) internal view virtual returns (GroupDef storage);

    function _prizes(uint32 id) internal view virtual returns (PrizeDef storage);
    function _delPrize(uint32 id) internal virtual;

    uint32 public constant PRIZE_ERC20 = 1;
    uint32 public constant PRIZE_ERC721 = 2;
    uint32 public constant PRIZE_ERC1155 = 3;

    struct RarityDef {
        Probability probability;
        uint32 boxCounter;
        uint32 groupCount;
        uint32 groupHead;
        uint64 totalPrizes; // might be uin32
        uint96 reserved;
        //:256
    }

    struct GroupDef {
        uint32 prizeCount;
        Probability probability;
        // groups are sorted by probability: the first is most rare (e.g: 1%, 5%, 96%)
        uint32 left;
        uint32 right;
        uint32 index;
        uint112 reserved;
        //:256
    }

    // be careful by adding params: important to update _cloneParams function
    struct PrizeDef {
        address token;
        uint32 flags;
        // @dev how many times this prize might be used
        uint64 count; // might be uint32
        //:256
        uint tokenId;
        //:256
        // @dev how many items should be transferred
        uint amount;
        //:256
        uint32 chainId;
        uint224 reserved;
        //:256
    }
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

abstract contract ISignedNftStorage {
    function _signer() internal virtual view returns (address);
    function _signer(address newSigner) internal virtual;

    function _getUsedAndSet(uint64 externalId) internal virtual returns (bool);
    function _getUsed(uint64 externalId) internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../IdType.sol";

abstract contract IVRFStorage {
    uint8 public constant BUY_REQUEST = 0;
    uint8 public constant CLAIM_REQUEST = 1;

    struct VRFRequest {
        IdType firstTokenId;
        uint16 count;

        uint8 requestType;
        uint8 rarity;
        uint160 reserved;
    }


    function _vrfCoordinator() internal virtual view returns (address);
    function _keyHash() internal virtual view returns (bytes32);
    function _subscriptionId() internal virtual view returns (uint64);
    function _requestConfirmations() internal virtual view returns (uint16);
    function _callbackGasLimit() internal virtual view returns (uint32);
    function _requestMap(uint requestId) internal virtual view returns (VRFRequest storage);
    function _requestMap(uint requestId, uint8 requestType, IdType id, uint16 count) internal virtual;
    function _delRequest(uint requestId) internal virtual;
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

type IdType is uint64;

uint constant MAX_TOKEN_INDEX = type(uint64).max - 1;
IdType constant EMPTY_ID = IdType.wrap(type(uint64).min);
IdType constant FIRST_ID = IdType.wrap(type(uint64).min + 1);

library IdTypeLib {
    function toId(uint tokenId) internal pure returns (IdType) {
        require(tokenId <= MAX_TOKEN_INDEX, "Too big token ID");
        return IdType.wrap(uint64(tokenId));
    }

    function toTokenId(IdType id) internal pure returns (uint) {
        return IdType.unwrap(id);
    }

    function next(IdType id, uint offset) internal pure returns (IdType) {
        if (offset == 0) {
            return id;
        }
        return toId(IdType.unwrap(id) + offset);
    }

    function isEmpty(IdType id) internal pure returns (bool) {
        return IdType.unwrap(id) == 0;
    }

    function unwrap(IdType id) internal pure returns (uint64) {
        return IdType.unwrap(id);
    }
}

function idTypeEquals(IdType a, IdType b) pure returns (bool) {
    return IdType.unwrap(a) == IdType.unwrap(b);
}

function idTypeNotEquals(IdType a, IdType b) pure returns (bool) {
    return IdType.unwrap(a) != IdType.unwrap(b);
}

using {
      idTypeEquals as ==
    , idTypeNotEquals as !=
} for IdType global;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVRFClient {
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
    /**
     * @notice Get configuration relevant for making requests
     * @return minimumRequestConfirmations global min for request confirmations
     * @return maxGasLimit global max for request gas limit
     * @return s_provingKeyHashes list of registered key hashes
     */
    function getRequestConfig() external view returns (uint16, uint32, bytes32[] memory);

    /**
     * @notice Request a set of random words.
     * @param keyHash - Corresponds to a particular oracle job which uses
     * that key for generating the VRF proof. Different keyHash's have different gas price
     * ceilings, so you can select a specific one to bound your maximum per request cost.
     * @param subId  - The ID of the VRF subscription. Must be funded
     * with the minimum subscription balance required for the selected keyHash.
     * @param minimumRequestConfirmations - How many blocks you'd like the
     * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
     * for why you may want to request more. The acceptable range is
     * [minimumRequestBlockConfirmations, 200].
     * @param callbackGasLimit - How much gas you'd like to receive in your
     * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
     * may be slightly less than this amount because of gas used calling the function
     * (argument decoding etc.), so you may need to request slightly more than you expect
     * to have inside fulfillRandomWords. The acceptable range is
     * [0, maxGasLimit]
     * @param numWords - The number of uint256 random values you'd like to receive
     * in your fulfillRandomWords callback. Note these numbers are expanded in a
     * secure way by the VRFCoordinator from a single random value supplied by the oracle.
     * @return requestId - A unique identifier of the request. Can be used to match
     * a request to a response in fulfillRandomWords.
     */
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);

    /**
     * @notice Create a VRF subscription.
     * @return subId - A unique subscription id.
     * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
     * @dev Note to fund the subscription, use transferAndCall. For example
     * @dev  LINKTOKEN.transferAndCall(
     * @dev    address(COORDINATOR),
     * @dev    amount,
     * @dev    abi.encode(subId));
     */
    function createSubscription() external returns (uint64 subId);

    /**
     * @notice Get a VRF subscription.
     * @param subId - ID of the subscription
     * @return balance - LINK balance of the subscription in juels.
     * @return reqCount - number of requests for this subscription, determines fee tier.
     * @return owner - owner of the subscription.
     * @return consumers - list of consumer address which are able to use this subscription.
     */
    function getSubscription(
        uint64 subId
    ) external view returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers);

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @param newOwner - proposed new owner of the subscription
     */
    function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @dev will revert if original owner of subId has
     * not requested that msg.sender become the new owner.
     */
    function acceptSubscriptionOwnerTransfer(uint64 subId) external;

    /**
     * @notice Add a consumer to a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - New consumer which can use the subscription
     */
    function addConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Remove a consumer from a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - Consumer to remove from the subscription
     */
    function removeConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Cancel a subscription
     * @param subId - ID of the subscription
     * @param to - Where to send the remaining LINK to
     */
    function cancelSubscription(uint64 subId, address to) external;

    /*
     * @notice Check to see if there exists a request commitment consumers
     * for all consumers and keyhashes for a given sub.
     * @param subId - ID of the subscription
     * @return true if there exists at least one unfulfilled request for the subscription, false
     * otherwise.
     */
    function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../data-access/IPriceStorage.sol";
import {TransferUtil} from "../Utils.sol";

    error TokenNotSupported(address token);

abstract contract Price is IPriceStorage {
    using SafeERC20 for IERC20;
    using TransferUtil for address;

    function _setPrice(address token, uint price) internal {
        // check token contract somehow
        token.erc20BalanceOf(address(this));

        uint previous = _price(token);

        _price(token, price);

        if (previous == 0) {
            _addTokenToPrice(token);
        }
    }

    function _removePrice(address token) internal {
        _delPrice(token);
        // do not remove token from the list, because it participates in the jackpot
    }

    function _debit(address token, address from, address target, uint multiplier) internal returns (uint) {
        require(multiplier != 0, "Price: multiplier must not be 0");
        uint price = _price(token);
        if (price == 0) {
            revert TokenNotSupported(token);
        }

        uint finalPrice = price * multiplier;
        IERC20(token).safeTransferFrom(from, target, finalPrice);
        return finalPrice;
    }
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../data-access/IPrizeStorage.sol";
import "../Utils.sol";
import "./Random.sol";


abstract contract Prize is IPrizeStorage {
    using ProbabilityLib for Probability;
    using ProbabilityLib for uint16;
    using TransferUtil for address;
    using Random for Random.Seed;
    using ProbabilityLib for Probability;

    error RarityLevelTooBig(uint level, uint maxLevel);
    error WrongRarityOrder(uint level, Probability current, Probability prev);

    error PrizeNotFound(uint rarity, Probability probability, address contractAddress, uint tokenId, uint amount, uint32 chainId);
    error UnsupportedPrizeType(uint prizeType);

    struct RarityInfo {
        uint rarity;
        Probability probability;
        GroupInfo[] groups;
        uint totalPrizes;
    }

    struct GroupInfo {
        uint index;
        Probability probability;
        PrizeInfo[] prizes;
    }

    struct PrizeInfo {
        uint prizeType;
        bool randomlySelected;
        Probability probability;
        uint availablePrizes;
        address contractAddress;
        uint tokenId;
        uint amount;
        uint chainId;
    }

    // @notice These errors replaced with events, cause they emitted during the VRF callback.
    /**
     * @dev There are no groups defined for the specified rarity. Configuration error.
     */
    event ErrorNoGroups(uint rarity);
    /**
     * @dev There are not prizes in the specified group.
     */
    event ErrorNoPrizesInGroup(uint rarity, uint groupId);
    /**
     * @dev There are not items in the specified prize.
     */
    event ErrorNoPrizes(uint rarity, uint groupId, uint prizeId);

    /**
     * @dev Sets the specified probability at the specified rarity level.
     *      It reverts in case of wrong argument but doesn't check the order.
     */
    function _setRarity(uint level, uint16 probability) internal {
        if (level >= RARITIES) {
            revert RarityLevelTooBig(level, RARITIES - 1);
        }

        _rarity(level, probability.toProbability());
    }

    /**
     * @dev Checks rarity order. Revert if the order is wrong.
     */
    function _checkRaritiesOrder() internal view {
        Probability total = PROBABILITY_ZERO;
        Probability previous = PROBABILITY_ZERO;
        for (uint i = 0; i < RARITIES; i ++) {
            Probability probability = _rarity(i).probability;
            if (probability < previous) {
                revert WrongRarityOrder(i, probability, previous);
            }
            previous = probability;
            total = total.add(probability);
        }
        // there is no more total correction, the rest probability is a chance to win jackpot
//        if (total != PROBABILITY_MAX) {
//            revert WrongTotalRaritiesProbability(total, PROBABILITY_MAX);
//        }
    }

    function _addPrize(uint rarity, PrizeInfo memory info) internal {
        // try to get prize group by rarity and probability
        RarityDef storage rarityDef = _rarity(rarity);
        uint64 availablePrizes = uint64(info.availablePrizes);
        Probability probability = info.probability;

        // special case if no groups
        if (rarityDef.groupCount == 0) {
            // create new group
            uint32 newGroupId = _getGroupId(rarity, MIN_GROUP_INDEX);
            GroupDef storage newGroup = _groups(newGroupId);
            rarityDef.groupCount = 1;
            rarityDef.totalPrizes = availablePrizes;
            rarityDef.groupHead = newGroupId;

            newGroup.prizeCount = 1;
            newGroup.probability = probability;
            newGroup.index = MIN_GROUP_INDEX;

            _createPrize(rarity, MIN_GROUP_INDEX, MIN_PRIZE_INDEX, info);
            return;
        }

        // insert a prize into a new or existing group
        uint32 groupId = rarityDef.groupHead;
        GroupDef storage group = _groups(groupId);

        for (; groupId != 0; group = _groups(groupId)) {
            // add prize to existing group if the probabilities match
            // and this prize is randomly selected, otherwise create new group at the end
            if (group.probability == probability && info.randomlySelected) {
                _createPrize(rarity, group.index, group.prizeCount + MIN_PRIZE_INDEX, info);

                rarityDef.totalPrizes += availablePrizes;
                group.prizeCount ++;
                break;
            }

            // left insert
            if (probability < group.probability) {
                // create new group
                uint32 groupIndex = rarityDef.groupCount + MIN_GROUP_INDEX;
                rarityDef.groupCount ++;

                rarityDef.totalPrizes += availablePrizes;

                uint32 leftGroupId = group.left;

                uint32 newGroupId = _getGroupId(rarity, groupIndex);
                GroupDef storage newGroup = _groups(newGroupId);
                newGroup.index = groupIndex;
                newGroup.right = groupId;
                newGroup.left = leftGroupId;
                newGroup.probability = probability;
                newGroup.prizeCount = 1;

                // link current group
                group.left = newGroupId;

                // link left group
                if (leftGroupId != 0) {
                    GroupDef storage leftGroup = _groups(leftGroupId);
                    leftGroup.right = newGroupId;
                }
                else {
                    rarityDef.groupHead = newGroupId;
                }

                _createPrize(rarity, groupIndex, MIN_PRIZE_INDEX, info);
                break;
            }

            // right insert (if the new group has the highest probability)
            if (group.right == 0) {
                // create new group
                uint32 groupIndex = rarityDef.groupCount + MIN_GROUP_INDEX;
                rarityDef.groupCount ++;

                rarityDef.totalPrizes += availablePrizes;

                uint32 newGroupId = _getGroupId(rarity, groupIndex);
                GroupDef storage newGroup = _groups(newGroupId);

                newGroup.index = groupIndex;
//                newGroup.right = 0;
                newGroup.left = groupId;
                newGroup.probability = probability;
                newGroup.prizeCount = 1;

                // link current group
                group.right = newGroupId;

                _createPrize(rarity, groupIndex, MIN_PRIZE_INDEX, info);
                break;
            }

            groupId = group.right;
        }
    }

    function _removePrize(uint rarity, Probability probability, address contractAddress, uint tokenId, uint amount, uint32 chainId) internal {
        RarityDef storage rarityDef = _rarity(rarity);

        uint32 groupId = rarityDef.groupHead;
        GroupDef storage group = _groups(groupId);

        for (; groupId != 0; group = _groups(groupId)) {
            if (group.probability != probability) {
                groupId = group.right;
                continue;
            }

            uint32 prizeCount = group.prizeCount;
            for (uint32 prizeIndex = 0; prizeIndex < prizeCount; prizeIndex ++) {
                uint32 prizeId = _getPrizeId(rarity, group.index, prizeIndex + MIN_PRIZE_INDEX);
                PrizeDef storage prize = _prizes(prizeId);

                if (prize.chainId != chainId
                    || prize.amount != amount
                    || prize.tokenId != tokenId
                    || prize.token != contractAddress) {
                    continue;
                }

                _removePrizeFromGroup(rarity, group, prizeId, prize);

                group.prizeCount --;
                rarityDef.totalPrizes -= prize.count;
                return;
            }

            groupId = group.right;
        }

        revert PrizeNotFound(rarity, probability, contractAddress, tokenId, amount, chainId);
    }

    function _removePrizeFromGroup(uint rarity, GroupDef storage group, uint32 prizeId, PrizeDef storage prize) private {
        uint32 lastPrizeId = _getPrizeId(rarity, group.index, group.prizeCount - 1);
        if (prizeId != lastPrizeId) {
            _cloneParams(_prizes(lastPrizeId), prize);
        }
        _delPrize(lastPrizeId);
    }

    function _getRaritiesInfo() internal view returns (RarityInfo[] memory result) {
        result = new RarityInfo[](RARITIES);
        for (uint i = 0; i < RARITIES; i ++) {
            RarityDef storage rarity = _rarity(i);
            result[i].rarity = i;
            result[i].probability = rarity.probability;
            result[i].groups = new GroupInfo[](rarity.groupCount);
            result[i].totalPrizes = rarity.totalPrizes;

            uint32 groupId = rarity.groupHead;
            GroupDef storage group = _groups(groupId);

            for (uint groupIndex = 0; groupId != 0; group = _groups(groupId)) {
                result[i].groups[groupIndex].index = group.index;
                result[i].groups[groupIndex].probability = group.probability;
                result[i].groups[groupIndex].prizes = new PrizeInfo[](group.prizeCount);

                for (uint32 prizeIndex = 0; prizeIndex < group.prizeCount; prizeIndex ++) {
                    uint32 prizeId = _getPrizeId(i, group.index, prizeIndex);
                    PrizeDef storage prize = _prizes(prizeId);

                    result[i].groups[groupIndex].prizes[prizeIndex].contractAddress = prize.token;
                    result[i].groups[groupIndex].prizes[prizeIndex].availablePrizes = prize.count;
                    result[i].groups[groupIndex].prizes[prizeIndex].tokenId = prize.tokenId;
                    result[i].groups[groupIndex].prizes[prizeIndex].amount = prize.amount;
                    result[i].groups[groupIndex].prizes[prizeIndex].chainId = prize.chainId;
                    result[i].groups[groupIndex].prizes[prizeIndex].prizeType = prize.flags;
                    result[i].groups[groupIndex].prizes[prizeIndex].randomlySelected = group.prizeCount > 1;
                    result[i].groups[groupIndex].prizes[prizeIndex].probability = group.probability;
                }

                groupId = group.right;
                groupIndex ++;
            }
        }
    }

    function _playPrize(uint rarity, Random.Seed memory random, address to, uint32 chainId) internal returns (bool, PrizeInfo memory info) {
        RarityDef storage rarityDef = _rarity(rarity);

        if (rarityDef.groupCount == 0) {
            emit ErrorNoGroups(rarity);
            return (false, info);
        }

        uint16 chance = uint16(random.get16() % PROBABILITY_DIVIDER);
        uint32 groupId = rarityDef.groupHead;
        GroupDef storage group = _groups(groupId);

        for (; groupId != 0; group = _groups(groupId)) {
            if (group.prizeCount != 0
                && group.probability.isPlayedOut(chance, 1)) {
                break;
            }

            chance = chance >= group.probability.unwrap()
                ? chance - group.probability.unwrap()
                : 0;
            groupId = group.right;
        }

        if (group.prizeCount == 0) {
            emit ErrorNoPrizesInGroup(rarity, groupId);
            return (false, info);
        }

        // special case, when prize only one in the group
        uint32 prizeId = _getPrizeId(rarity, group.index, 0);

        // if there is more than one prize, randomly select it
        if (group.prizeCount > 1) {
            uint32 offset = random.get32() % group.prizeCount;
            prizeId += offset;
        }

        PrizeDef storage prize = _prizes(prizeId);
        if (prize.count == 0) {
            emit ErrorNoPrizes(rarity, group.index, prizeId);
            return (false, info);
        }

        uint32 prizeType = prize.flags;

        // fill info before deleting the record
        info.prizeType = prizeType;
        info.amount = prize.amount;
        info.tokenId = prize.tokenId;
        info.contractAddress = prize.token;
        info.chainId = prize.chainId;

        if (prizeType == PRIZE_ERC20) {
            if (chainId == prize.chainId) {
                prize.token.erc20TransferFrom(address(this), to, prize.amount);
            }
        }
        else if (prizeType == PRIZE_ERC721) {
            if (chainId == prize.chainId) {
                prize.token.erc721Transfer(to, prize.tokenId);
            }
            // ERC721 might be sequentially defined
            prize.tokenId ++;
        }
        else if (prizeType == PRIZE_ERC1155) {
            if (chainId == prize.chainId) {
                prize.token.erc1155TransferFrom(address(this), to, prize.tokenId, prize.amount);
            }
        }

        rarityDef.totalPrizes --;

        // remove prize record if there is no more count
        if (prize.count == 1) {
            _removePrizeFromGroup(rarity, group, prizeId, prize);
            group.prizeCount --;
        }
            // otherwise just decrement count
        else {
            prize.count --;
        }

        return (true, info);
    }

    function _addLootBoxCount(uint rarity, uint32 count) internal {
        RarityDef storage rarityDef = _rarity(rarity);
        rarityDef.boxCounter += count;
    }

    function _decLootBoxCount(uint rarity) internal {
        RarityDef storage rarityDef = _rarity(rarity);
        rarityDef.boxCounter --;
    }

    function _lookupRarity(uint random, uint16 boost) internal view returns (bool, uint) {
        uint chance = random % PROBABILITY_DIVIDER;
        for (uint i = 0; i < RARITIES; i ++) {
            uint val = _rarity(i).probability.toUint16() * boost;
            if (chance < val) {
                return (true, i);
            }
            chance -= val;
        }
        return (false, 0);
    }


    function _createPrize(uint rarity, uint groupIndex, uint32 prizeOffset, PrizeInfo memory info) private {
        uint prizeType = info.prizeType;
        if (prizeType != PRIZE_ERC20
        && prizeType != PRIZE_ERC721
            && prizeType != PRIZE_ERC1155) {
            revert UnsupportedPrizeType(prizeType);
        }
        uint32 prizeId = _getPrizeId(rarity, groupIndex, prizeOffset);
        PrizeDef storage prize = _prizes(prizeId);
        prize.token = info.contractAddress;
        prize.tokenId = info.tokenId;
        prize.amount = info.amount;
        prize.count = uint64(info.availablePrizes);
        prize.chainId = uint32(info.chainId);
        prize.flags = uint16(prizeType);
    }

    function _cloneParams(PrizeDef storage fromPrize, PrizeDef storage toPrize) private {
        toPrize.token = fromPrize.token;
        toPrize.flags = fromPrize.flags;
        toPrize.count = fromPrize.count;
        toPrize.tokenId = fromPrize.tokenId;
        toPrize.amount = fromPrize.amount;
        toPrize.chainId = fromPrize.chainId;
    }

    function _getPrizeId(uint rarity, uint groupIndex, uint32 prizeOffset) private pure returns (uint32) {
        return uint32(rarity * RARITY_PRIZE_CAPACITY + groupIndex * PRIZE_GROUP_CAPACITY + 1) + prizeOffset;
    }

    function _getGroupId(uint rarity, uint groupIndex) private pure returns (uint32) {
        return uint32(rarity * RARITY_PRIZE_CAPACITY + groupIndex * PRIZE_GROUP_CAPACITY + 1);
    }
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

import "../data-access/IVRFStorage.sol";

library Random {
    error DeltaIsOutOfRange(uint8 got, uint8 max);
    uint8 internal constant BYTES_IN_WORD = 32;

    struct Seed {
        uint seed;
        uint8 pointer;
    }

    function _remain(Seed memory seed) private pure returns (uint8) {
        return BYTES_IN_WORD - seed.pointer;
    }

    function _upgradeSeed(Seed memory seed) private pure {
        seed.seed = uint(keccak256(abi.encode(seed.seed)));
        seed.pointer = 0;
    }

    function _mask(uint8 size) private pure returns (uint) {
        return type(uint).max >> (256 - (size << 3));
    }

    function _read(Seed memory seed, uint8 count, uint8 offset) private pure returns (uint) {
        // >> (8 * count), than result << (offset * 8)
        uint result = (seed.seed >> (seed.pointer << 3)) << (offset << 3);
        return result & _mask(count + offset);
    }

    function _get(Seed memory seed, uint8 delta) private pure returns (uint) {
        if (delta > BYTES_IN_WORD) {
            revert DeltaIsOutOfRange(delta, BYTES_IN_WORD);
        }

        uint result = 0;
        if (delta > _remain(seed)) {
            uint8 remain = _remain(seed);
            delta -= remain;

            result = _read(seed, remain, delta);
            _upgradeSeed(seed);
        }

        result |= _read(seed, delta, 0);
        seed.pointer += delta;

        return result;
    }

    function get8(Seed memory seed) internal pure returns (uint8) {
        return uint8(_get(seed, 1));
    }

    function get16(Seed memory seed) internal pure returns (uint16) {
        return uint16(_get(seed, 2));
    }

    function get32(Seed memory seed) internal pure returns (uint32) {
        return uint32(_get(seed, 4));
    }

    function get64(Seed memory seed) internal pure returns (uint64) {
        return uint64(_get(seed, 8));
    }
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./Storage.sol";
import "./Utils.sol";
import "./logic/Random.sol";
import "./logic/Prize.sol";
import "./AccessControl.sol";
import "./logic/Price.sol";
import "./VRF.sol";


contract LootBoxAdmin is Storage, AccessControl, Prize, Price, VRF {
    /**
     * @dev Rarities array has wrong length. It MUST be the same is RARITIES defined in the contract.
     */
    error WrongRaritiesLength(uint given, uint expected);

    /**
     * @dev There is not fund to claim.
     */
    error NoFundsAvailable(address token, address pool);

    /**
     * @dev Out of range.
     */
    error OutOfRange(string name, uint got, uint min, uint max);

    /**
     * @dev Method is not implemented in current implementation.
     */
    error NotImplemented();

    using TransferUtil for address;
    using ProbabilityLib for Probability;
    using IdTypeLib for IdType;
    using IdTypeLib for uint;
    using Random for Random.Seed;

    struct TokenInfo {
        address token;
        uint price;
        uint jackpot;
    }

    struct PrizeInfoOld {
        uint rarity;
        address erc20Token;
        uint erc20Amount;
        uint erc20Total;
        uint32 erc20ChainId;
        uint total;
        uint offset;
        NftInfo[] nfts;
    }

    struct State {
        uint expectedIncome;
        uint startTimestamp;
        uint endTimestamp;
        uint totalSupply;
        uint[] prizeCounts;
        uint emptyCounter;
        uint[] lbCounters;
    }

    struct BalanceInfo {
        address owner;
        uint emptyCounter;
        uint firstEmptyTokenId;
        uint mysteryCounter;
        uint[] rarityCounters;
        uint[] firstTokenIds;
    }

    function probabilities() public view returns (uint16[] memory) {
        uint16[] memory result = new uint16[](RARITIES);
        for (uint i = 0; i < RARITIES; i ++) {
            result[i] = _rarity(i).probability.toUint16();
        }
        return result;
    }

    //*************** Public view functions

    /*
     * @dev Returns token price and jackpot amount.
     * @notice 0x0 token address means native token.
     */
    function getTokenInfo() public view returns (TokenInfo[] memory result) {
        uint count = _listJackpots().length;
        result = new TokenInfo[](count);
        for (uint i = 0; i < count; i ++) {
            address token = _listJackpots()[i];
            result[i].token = token;
            result[i].price = _price(token);
            result[i].jackpot = _jackpot(token);
        }
    }

    function getBalanceInfo(address owner) public view returns (BalanceInfo memory) {
        NFTCounter storage counters = _balances(owner);

        uint[] memory rarityCounters = new uint[](RARITIES);
        uint[] memory tokenIds = new uint[](RARITIES);
        for (uint i  = 0; i < RARITIES; i ++) {
            rarityCounters[i] = counters.rarityIdToCount[i];
            tokenIds[i] = counters.rarityIdToHead[i].toTokenId();
        }

        return BalanceInfo(
            owner,
            counters.emptyCount,
            counters.emptyHead.toTokenId(),
            counters.mysteryCount,
            rarityCounters,
            tokenIds
        );
    }

    function getPrizes() public view returns (RarityInfo[] memory) {
        return _getRaritiesInfo();
    }

    function getState() public view returns (State memory) {
        uint[] memory rarityCounters = new uint[](RARITIES);
        uint[] memory lbCounts = new uint[](RARITIES);

        for (uint i = 0; i < RARITIES; i ++) {
            rarityCounters[i] = _rarity(i).totalPrizes;
            lbCounts[i] = _rarity(i).boxCounter;
        }

        return State(
            _scope().maxIncome,
            _scope().begin,
            _scope().end,
            _counters().nextBoxId.toTokenId() - 1,
            rarityCounters,
            _counters().emptyCounter,
            lbCounts
        );
    }

    function _randomBuyResponseHandler(IdType, uint16, Random.Seed memory) internal override {
        revert NotImplemented();
    }

    function _randomClaimResponseHandler(IdType, Random.Seed memory) internal override {
        revert NotImplemented();
    }

    //*************** Admin functions

    function claimFunds(address token, address to) public onlyRole(ADMIN_ROLE) {
        address pool = address(this);
        uint total = token.erc20BalanceOf(pool);
        if (total == 0) {
            revert NoFundsAvailable(token, pool);
        }
        total -= _jackpot(token);
        if (total == 0) {
            revert NoFundsAvailable(token, pool);
        }
        token.erc20TransferFrom(pool, to, total);
    }

    function withdrawNft(address collection, uint tokenId, address to) public onlyRole(ADMIN_ROLE) {
        collection.erc721Transfer(to, tokenId);
    }

    function withdrawErc20(address token, uint amount, address to) public onlyRole(ADMIN_ROLE) {
        token.erc20TransferFrom(address(this), to, amount);
    }

    function withdrawErc1055(address collection, uint tokenId, uint amount, address to) public onlyRole(ADMIN_ROLE) {
        collection.erc1155TransferFrom(address(this), to, tokenId, amount);
    }

    function setPrice(address token, uint price) public onlyRole(ADMIN_ROLE) {
        _setPrice(token, price);
    }

    function getPrice(address token) public view returns (uint) {
        return _price(token);
    }

//    function

    function addPrizes(uint rarity, PrizeInfo[] calldata prizes) public onlyRole(PRIZE_MANAGER_ROLE) {
        for (uint i = 0; i < prizes.length; i ++) {
            _checkRanger("prizes[].amount", prizes[i].amount, 1, type(uint).max);
            _checkRanger("prizes[].availablePrizes", prizes[i].availablePrizes, 1, type(uint64).max);
            _addPrize(rarity, prizes[i]);
        }
    }

    function addPrizeSameNft(uint rarity, PrizeInfo memory prize, uint[] calldata ids) public onlyRole(PRIZE_MANAGER_ROLE) {
        _checkRanger("prize.amount", prize.amount, 1, type(uint).max);
        _checkRanger("prize.availablePrizes", prize.availablePrizes, 1, type(uint64).max);
        for (uint i = 0; i < ids.length; i ++) {
            prize.tokenId = ids[i];
            _addPrize(rarity, prize);
        }
    }

    function removePrize(uint rarity, PrizeInfo calldata prize) public onlyRole(ADMIN_ROLE) {
        _removePrize(
            rarity,
            prize.probability,
            prize.contractAddress,
            prize.tokenId,
            prize.amount,
            uint32(prize.chainId)
        );
    }

    function removePrizeSameNft(uint rarity, PrizeInfo calldata prize, address to, uint[] calldata ids) public onlyRole(ADMIN_ROLE) {
        for (uint i = 0; i < ids.length; i ++) {
            _removePrize(
                rarity,
                prize.probability,
                prize.contractAddress,
                ids[i],
                prize.amount,
                uint32(prize.chainId)
            );

            prize.contractAddress.erc721Transfer(to, ids[i]);
        }
    }

    function setAllRarities(uint16[] calldata probabilities_) public onlyRole(PRIZE_MANAGER_ROLE) {
        if (probabilities_.length != RARITIES) {
            revert WrongRaritiesLength(probabilities_.length, RARITIES);
        }
        for (uint i = 0; i < RARITIES; i ++) {
            _setRarity(i, probabilities_[i]);
        }
        _checkRaritiesOrder();
    }

    function setJackpotParams(Probability jackpotShare, Probability jackpotPriceShare) public onlyRole(ADMIN_ROLE) {
        Config storage config = _config();
        config.jackpotPriceShare = jackpotPriceShare;
        config.jackpotShare = jackpotShare;
    }

    function setVRFParams(address vrfCoordinator, uint64 subscriptionId, uint32 callbackGasLimit, uint16 requestConfirmations, bytes32 keyHash) public onlyRole(ADMIN_ROLE) {
        Config storage config = _config();
        config.vrfCoordinator = vrfCoordinator;
        config.subscriptionId = subscriptionId;
        config.callbackGasLimit = callbackGasLimit;
        config.requestConfirmations = requestConfirmations;
        config.keyHash = keyHash;
    }

    function setSigner(address signerAddress) public onlyRole(ADMIN_ROLE) {
        _signer(signerAddress);
    }

    function setAlwaysBurn(bool alwaysBurn) public onlyRole(ADMIN_ROLE) {
        _scope().alwaysBurn = alwaysBurn ? 1 : 0;
    }

    function setMaxBoost(uint16 maxBoost) public onlyRole(ADMIN_ROLE) {
        _config().maxBoost = maxBoost;
    }

    function repeatRandomRequest(uint requestId) public onlyRole(ADMIN_ROLE) {
        _repeatRequest(requestId);
    }

    function requestRandomManually(uint tokenId, uint count, bool buy) public onlyRole(ADMIN_ROLE) {
        if (buy) {
            _requestBuyRandom(tokenId.toId(), uint16(count));
        }
        else {
            _requestClaimRandom(tokenId.toId());
        }
    }

    function debugNft(uint tokenId) public view returns (NFTDef memory) {
        return _nft(tokenId.toId());
    }

    function setStartEnd(uint begin, uint end) public onlyRole(ADMIN_ROLE) {
        Scope storage scope = _scope();
        scope.begin = uint32(begin);
        scope.end = uint32(end);
    }

    function setBaseUrl(string memory baseUri) public onlyRole(ADMIN_ROLE) {
        _baseURI(baseUri);
    }

    function setMaxIncome(uint maxIncome) public onlyRole(ADMIN_ROLE) {
        _scope().maxIncome = maxIncome;
    }

    function _checkRanger(string memory param, uint value, uint min, uint max) private pure {
        if (value < min || value > max) {
            revert OutOfRange(param, value, min, max);
        }
    }
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

type Probability is uint16;

uint constant PROBABILITY_MASK = type(uint16).max;
uint constant PROBABILITY_SHIFT = 16;
uint constant PROBABILITY_DIVIDER = 10000;
Probability constant PROBABILITY_ZERO = Probability.wrap(0);
Probability constant PROBABILITY_MAX = Probability.wrap(uint16(PROBABILITY_DIVIDER));

library ProbabilityLib {
    error ProbabilityTooBig(uint probability, uint maxProbability);

    function toProbability(uint16 value) internal pure returns (Probability) {
        if (value > PROBABILITY_DIVIDER) {
            revert ProbabilityTooBig(value, PROBABILITY_DIVIDER);
        }
        return Probability.wrap(value);
    }

    function toUint16(Probability probability) internal pure returns (uint16) {
        return Probability.unwrap(probability);
    }

    function mul(Probability probability, uint value) internal pure returns (uint) {
        uint prob = Probability.unwrap(probability);
        return value * prob / PROBABILITY_DIVIDER;
    }

    function mul(uint value, Probability probability) internal pure returns (uint) {
        uint prob = Probability.unwrap(probability);
        return value * prob / PROBABILITY_DIVIDER;
    }

    function isPlayedOut(Probability probability, uint value, uint boost) internal pure returns (bool) {
        return value % PROBABILITY_DIVIDER < Probability.unwrap(probability) * boost;
    }

    function add(Probability a, Probability b) internal pure returns (Probability) {
        return toProbability(Probability.unwrap(a) + Probability.unwrap(b));
    }

    function unwrap(Probability probability) internal pure returns (uint16) {
        return Probability.unwrap(probability);
    }
}

function gtProbability(Probability a, Probability b) pure returns (bool) {
    return Probability.unwrap(a) > Probability.unwrap(b);
}

function ltProbability(Probability a, Probability b) pure returns (bool) {
    return Probability.unwrap(a) < Probability.unwrap(b);
}

function gteProbability(Probability a, Probability b) pure returns (bool) {
    return Probability.unwrap(a) >= Probability.unwrap(b);
}

function lteProbability(Probability a, Probability b) pure returns (bool) {
    return Probability.unwrap(a) <= Probability.unwrap(b);
}

function eqProbability(Probability a, Probability b) pure returns (bool) {
    return Probability.unwrap(a) == Probability.unwrap(b);
}

function neProbability(Probability a, Probability b) pure returns (bool) {
    return !eqProbability(a, b);
}

using {
      gtProbability as >
    , ltProbability as <
    , gteProbability as >=
    , lteProbability as <=
    , eqProbability as ==
    , neProbability as !=
} for Probability global;

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

type StateType is uint8;

StateType constant MYSTERY_STATE = StateType.wrap(StateTypeLib.NFT_MYSTERY);
StateType constant EMPTY_STATE = StateType.wrap(StateTypeLib.NFT_EMPTY);

library StateTypeLib {
    uint8 internal constant NFT_MYSTERY = 0;
    uint8 internal constant NFT_EMPTY = 1;
    // 4..31 reserved for the future usage
    uint8 internal constant NFT_RARITY_0 = 32;

    function toRarity(StateType state) internal pure returns (uint) {
        uint8 val = StateType.unwrap(state);
        return val - NFT_RARITY_0;
    }

    function toState(uint rarity) internal pure returns (StateType) {
        return StateType.wrap(uint8(rarity) + NFT_RARITY_0);
    }

    function isRare(StateType state) internal pure returns (bool) {
        return StateType.unwrap(state) >= NFT_RARITY_0;
    }

    function isMystery(StateType state) internal pure returns (bool) {
        return StateType.unwrap(state) == NFT_MYSTERY;
    }

    function isNotMystery(StateType state) internal pure returns (bool) {
        return StateType.unwrap(state) != NFT_MYSTERY;
    }

    function isEmpty(StateType state) internal pure returns (bool) {
        return StateType.unwrap(state) == NFT_EMPTY;
    }
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./data-access/INftStorage.sol";
import "./data-access/IPrizeStorage.sol";
import "./data-access/IPriceStorage.sol";
import "./data-access/ILootBoxStorage.sol";
import "./data-access/IAccessControlStorage.sol";
import "./data-access/IConfigStorage.sol";
import "./data-access/IVRFStorage.sol";
import "./Uint16Maps.sol";
import "./data-access/IJackpotStorage.sol";
import "./data-access/ISignedNftStorage.sol";
import "./data-access/IBalanceStorage.sol";

contract Storage is Initializable, INftStorage, IPrizeStorage, IPriceStorage, IJackpotStorage, ILootBoxStorage, IAccessControlStorage, IConfigStorage, IVRFStorage, ISignedNftStorage, IBalanceStorage {
    using IdTypeLib for IdType;

    /// ERC721 storage
    // Token name
    string private name;

    // Token symbol
    string private symbol;

    string private baseUri;

    // Mapping from token ID to token definition
    mapping(IdType => NFTDef) private nfts;

    // Mapping owner address to rarities counts
    mapping(address => NFTCounter) private userToRaritiesCounters;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private operatorApprovals;

    /// IPrizeStorage
    mapping(uint => RarityDef) private rarities;
    mapping(uint32 => PrizeDef) private prizes;
    mapping(uint32 => GroupDef) private groups;

    /// IPriceStorage
    mapping(address => uint) private prices;
    address[] private priceTokens;

    /// IAccessControlStorage
    mapping(bytes32 => RoleData) private roles;

    /// IVRFStorage
    mapping(uint => VRFRequest) private requestMap;

    /// IJackpotStorage
    mapping(address => uint) private jackpots;

    /// IConfigStorage
    Config public config;

    Counters private counters;

    Scope private scope;

    /// ISignedNftStorage
    mapping(uint64 => uint) private usedExternalIds;

    constructor() {
        _disableInitializers();
    }

    function init(string memory name_, string memory symbol_, string memory baseUri_, uint256 maxIncome, uint32 begin, uint32 end, address signer) initializer public virtual {
        counters.nextBoxId = FIRST_ID; // starts from 1
        name = name_;
        symbol = symbol_;
        baseUri = baseUri_;
        scope.maxIncome = maxIncome;
        scope.begin = begin;
        scope.end = end;
        scope.alwaysBurn = 1;
        config.signer = signer;
        config.maxBoost = 1;
    }

    function _name() internal view override returns (string storage) {
        return name;
    }

    function _symbol() internal view override returns (string storage) {
        return symbol;
    }

    function _baseURI() internal view override returns (string storage) {
        return baseUri;
    }

    function _baseURI(string memory baseUri_) internal override {
        baseUri = baseUri_;
    }

    function _balances(address user) internal view override returns (NFTCounter storage) {
        return userToRaritiesCounters[user];
    }

    function _nft(IdType tokenId, NFTDef memory definition) internal override {
        nfts[tokenId] = definition;
    }

    function _nft(IdType key) internal view override returns (NFTDef storage) {
        return nfts[key];
    }

    function _deleteNft(IdType key) internal override {
        delete nfts[key];
    }

    function _operatorApprovals(address owner, address operator) internal view override returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function _operatorApprovals(address owner, address operator, bool value) internal override {
        if (!value) {
            delete operatorApprovals[owner][operator];
            return;
        }
        operatorApprovals[owner][operator] = true;
    }

    /// IPrizeStorage
    function _rarity(uint level) internal view override returns (RarityDef storage) {
        return rarities[level];
    }

    function _rarity(uint level, Probability probability) internal override {
        rarities[level].probability = probability;
    }

    function _prizes(uint32 id) internal view override returns (PrizeDef storage) {
        return prizes[id];
    }

    function _delPrize(uint32 id) internal override {
        delete prizes[id];
    }

    function _groups(uint32 id) internal view override returns (GroupDef storage) {
        return groups[id];
    }

    function _delGroup(uint32 id) internal {

    }

    /// IPriceStorage
    function _price(address token) internal override view returns (uint) {
        return prices[token];
    }

    function _price(address token, uint price) internal override {
        prices[token] = price;
    }

    function _delPrice(address token) internal override {
        delete prices[token];
    }

    function _addTokenToPrice(address token) internal override {
        priceTokens.push(token);
    }

    /// IAccessControlStorage
    function _roles(bytes32 role) internal view override returns (RoleData storage) {
        return roles[role];
    }

    /// IConfigStorage
    function _config() internal override view returns (Config storage) {
        return config;
    }

    /// IVRFStorage
    function _vrfCoordinator() internal override view returns (address) {
        return config.vrfCoordinator;
    }

    function _keyHash() internal override view returns (bytes32) {
        return config.keyHash;
    }

    function _subscriptionId() internal override view returns (uint64) {
        return config.subscriptionId;
    }

    function _requestConfirmations() internal override view returns (uint16) {
        return config.requestConfirmations;
    }

    function _callbackGasLimit() internal override view returns (uint32) {
        return config.callbackGasLimit;
    }

    function _requestMap(uint requestId) internal override view returns (VRFRequest storage) {
        return requestMap[requestId];
    }

    function _delRequest(uint requestId) internal override {
        delete requestMap[requestId];
    }

    function _requestMap(uint requestId, uint8 requestType, IdType id, uint16 count) internal override {
        VRFRequest storage request = requestMap[requestId];
        request.firstTokenId = id;
        request.count = count;
        request.requestType = requestType;
    }

    /// ILootBoxStorage
    function _nextTokenId(uint count) internal override returns (IdType) {
        if (count == 0) {
            return counters.nextBoxId;
        }
        IdType result = counters.nextBoxId;
        counters.nextBoxId = counters.nextBoxId.next(count);
        return result;
    }

    function _scope() internal view override returns (Scope storage) {
        return scope;
    }

    function _scope(Scope memory scope_) internal override {
        scope = scope_;
    }

    function _counters() internal view override returns (Counters memory) {
        return counters;
    }

    function _increaseClaimRequestCounter(uint16 amount) internal override {
        counters.claimRequestCounter += amount;
    }

    function _decreaseClaimRequestCounter(uint16 amount) internal override {
        counters.claimRequestCounter -= amount;
    }

    /// IJackpotStorage
    function _jackpot(address token) internal override view returns (uint) {
        return jackpots[token];
    }

    function _addJackpot(address token, int amount) internal override {
        if (amount < 0) {
            jackpots[token] -= uint(-amount);
        }
        else {
            jackpots[token] += uint(amount);
        }
    }

    function _listJackpots() internal override view returns (address[] storage) {
        return priceTokens;
    }

    function _jackpotShare() internal override view returns (Probability) {
        return config.jackpotShare;
    }

    function _addEmptyCounter(int32 amount) internal override {
        if (amount > 0) {
            counters.emptyCounter += uint32(amount);
        }
        else {
            counters.emptyCounter -= uint32(-amount);
        }
    }

    function _addTotalIncome(uint256 amount) internal override {
        scope.totalIncome += amount;
    }

    /// ISignedNftStorage
    function _signer() internal override view returns (address) {
        return config.signer;
    }

    function _signer(address newSigner) internal override {
        config.signer = newSigner;
    }

    function _getUsedAndSet(uint64 externalId) internal override returns (bool result) {
        result = usedExternalIds[externalId] != 0;
        usedExternalIds[externalId] = 1;
    }

    function _getUsed(uint64 externalId) internal view override returns (bool) {
        return usedExternalIds[externalId] != 0;
    }

}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to uint16 mapping in a compact and efficient way, providing the keys are sequential.
 * The code is based on OpenZeppelin BitMaps implementation https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/BitMaps.sol
 * It might be easily converted to any multiple uint* type by replacing uint16 with that type and correspondingly tuning the INT_* constants.
 * A multiple types should divide 256 without remaining, i.e 1 (BitMap),2,4,8,16,32,64 & 128
 * Technically it's possible to use this library for store not multiple int types, but it requires much more complicated logic.
 */
library Uint16Maps {
    /**
     * @dev Int type size in bits.
     * Modify it if you want to adopt this map to other uint* type
     */
    uint private constant INT_BITS = 16;
    uint private constant INT_TIMES = 256 / INT_BITS;
    /**
     * @dev How many bits required to present INT_TIMES in binary format.
     * Modify it if you want to adopt this map to other uint* type
     */
    uint private constant INT_BITS_SHIFT = 4;
    uint private constant INT_BITS_MASK = INT_TIMES - 1;

    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the uint16 at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (uint16) {
        // the same as index / INT_TIMES
        uint256 bucket = index >> INT_BITS_SHIFT;
        // the same as index % INT_TIMES * INT_BITS
        uint256 offset = (index & INT_BITS_MASK) * INT_BITS;
        uint256 mask = INT_BITS_MASK << offset;
        return uint16((bitmap._data[bucket] & mask) >> offset);
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(BitMap storage bitmap, uint256 index, uint16 value) internal {
        // the same as index / INT_TIMES
        uint256 bucket = index >> INT_BITS_SHIFT;
        // the same as index % INT_TIMES * INT_BITS
        uint256 offset = (index & INT_BITS_MASK) * INT_BITS;

        // ...111100..0011111... where zeroes are a place into which we will put the value.
        uint256 mask = INT_BITS_MASK << offset;
        uint256 oldValue = bitmap._data[bucket];
        // oldValue & ~mask - fills with zeroes slot for the value
        // | (uint256(value) << offset) - sets the value into the slot
        uint256 newValue = (oldValue & ~mask) | (uint256(value) << offset);

        bitmap._data[bucket] = newValue;
    }
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

library TransferUtil {
    using SafeERC20 for IERC20;
    function erc20TransferFrom(address token, address from, address to, uint amount) internal {
        if (from == address(this)) {
            IERC20(token).safeTransfer(to, amount);
        }
        else {
            IERC20(token).safeTransferFrom(from, to, amount);
        }
    }

    function erc721Transfer(address collection, address to, uint tokenId) internal {
        address owner = IERC721(collection).ownerOf(tokenId);
        IERC721(collection).safeTransferFrom(owner, to, tokenId);
    }

    function erc20BalanceOf(address token, address account) internal view returns (uint) {
        return IERC20(token).balanceOf(account);
    }

    function erc1155TransferFrom(address collection, address from, address to, uint tokenId, uint amount) internal {
        IERC1155(collection).safeTransferFrom(from, to, tokenId, amount, "");
    }
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

import "./data-access/IVRFStorage.sol";
import "./integration/VRFCoordinatorV2Interface.sol";
import "./integration/IVRFClient.sol";
import "./logic/Random.sol";

abstract contract VRF is IVRFStorage, IVRFClient {
    error OnlyCoordinatorCanFulfill(address have, address want);
    error UnknownRequestId(uint requestId);

    function _randomBuyResponseHandler(IdType firstId, uint16 count, Random.Seed memory random) internal virtual;
    function _randomClaimResponseHandler(IdType id, Random.Seed memory random) internal virtual;

    /**
     * @dev Request a random number for buy action.
     */
    function _requestBuyRandom(IdType id, uint16 count) internal {
        uint requestId = _createNewRequest();
        _requestMap(requestId, BUY_REQUEST, id, count);
    }

    /**
     * @dev Request a random number for claim action.
     */
    function _requestClaimRandom(IdType id) internal {
        uint requestId = _createNewRequest();
        _requestMap(requestId, CLAIM_REQUEST, id, 1);
    }

    /**
     * @dev Cancel existing request and do it again.
     * @notice VRF request is not canceled, but the corresponding record in the map is deleted
     *          it means response will not be handled.
     */
    function _repeatRequest(uint requestId) internal {
        VRFRequest storage request = _requestMap(requestId);
        if (request.count == 0) {
            revert UnknownRequestId(requestId);
        }
        uint newRequestId = _createNewRequest();
        VRFRequest storage newRequest = _requestMap(newRequestId);
        // copy the whole request
        newRequest.rarity = request.rarity;
        newRequest.count = request.count;
        newRequest.firstTokenId = request.firstTokenId;
        newRequest.requestType = request.requestType;

        _delRequest(requestId);
    }

    /**
     * @param requestId The Id initially returned by requestRandomness
     * @param randomWords the VRF output expanded to the requested number of words
     */
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        if (msg.sender != _vrfCoordinator()) {
            revert OnlyCoordinatorCanFulfill(msg.sender, _vrfCoordinator());
        }
        VRFRequest storage request = _requestMap(requestId);
        if (request.count == 0) {
            revert UnknownRequestId(requestId);
        }

        Random.Seed memory seed = Random.Seed(randomWords[0], 0);
        uint16 requestCount = request.count;

        if (request.requestType == BUY_REQUEST) {
            IdType firstTokenId = request.firstTokenId;
            _delRequest(requestId);
            _randomBuyResponseHandler(firstTokenId, requestCount, seed);
            return;
        }

        if (request.requestType == CLAIM_REQUEST) {
            IdType lockedId = request.firstTokenId;
            _delRequest(requestId);
            _randomClaimResponseHandler(lockedId, seed);
            return;
        }
    }

    function _createNewRequest() private returns(uint) {
        return VRFCoordinatorV2Interface(_vrfCoordinator())
            .requestRandomWords(
            _keyHash(),
            _subscriptionId(),
            _requestConfirmations(),
            _callbackGasLimit(),
            1
        );
    }
}