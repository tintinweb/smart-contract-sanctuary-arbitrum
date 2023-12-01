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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
        address owner = _ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
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
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
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
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
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

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
        // segment
        uint16 requestConfirmations;
        uint16 reserved;
        /// Share of jackpot send to winner.
        Probability jackpotShare;
        Probability jackpotPriceShare;
        address signer;
        // TODO: 32 left
        // segment
        bytes32 keyHash;
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
        uint64 maxSupply;
        uint8 alwaysBurn;
        uint120 reserved;
    }

    struct Counters {
        // holds the next token id
        IdType nextBoxId;
        // how many unsatisfied request are
        uint16 claimRequestCounter;
        // empty (jackpot) loot boxes global counter
        uint32 emptyCounter;
        // boost adding to supply, e.g: 5 lbs x 3 boost = 5 max supply, but 15 total income
        // 15-5 = 10 - is the boost adding
        uint32 boostAdding;
        uint112 reserved2;
        // if it requires to add more rarities, use reserved space (up to 16 rarities)
        bytes32[2] reserved3;
    }

    function _nextTokenId() internal virtual returns (IdType) {
        return _nextTokenId(1);
    }

    function _nextTokenId(uint count) internal virtual returns (IdType);

    function _totalSupplyWithBoost() internal virtual view returns (uint64);

    function _scope() internal view virtual returns (Scope storage);

    function _scope(Scope memory scope) internal virtual;

    function _counters() internal view virtual returns (Counters memory);

    function _addEmptyCounter(int32 amount) internal virtual;

    function _increaseClaimRequestCounter(uint16 amount) internal virtual;

    function _decreaseClaimRequestCounter(uint16 amount) internal virtual;

    function _addBoostAdding(uint32 amount) internal virtual;
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

import "../IdType.sol";
import "../StateType.sol";

abstract contract INftStorage {
    using StateTypeLib for StateType;

    uint8 public constant NFT_FLAG_LOCKED = 1; // flag

    uint16 public constant MAX_NFT_BOOST = 10; // mustn't be grater than uint16
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
    uint32 internal constant MIN_PRIZE_INDEX = 1;
    uint32 internal constant RARITY_PRIZE_CAPACITY = 500_000;

    function _rarity(uint level) internal view virtual returns (RarityDef storage);
    function _rarity(uint level, Probability probability) internal virtual;

    function _prizes(uint32 id) internal view virtual returns (PrizeDef storage);
    function _delPrize(uint32 id) internal virtual;

    function _getPrizeIdByNft(address collection, uint tokenId) internal view virtual returns (uint32);
    function _addPrizeIdByNft(address collection, uint tokenId, uint32 id) internal virtual;
    function _removePrizeIdByNft(address collection, uint tokenId) internal virtual;

    uint32 public constant PRIZE_NFT = 2;

    struct RarityDef {
        Probability probability;
        uint32 lbCounter;
        uint32 head;
        uint32 tail;
        uint32 count;
        uint16 reserved1;
        uint32 reserved2;
        uint96 reserved3;
    }

    struct PrizeDef {
        address token;
        uint32 flags;
        uint32 left;
        uint32 right;
        uint value;

        Probability probability;
        uint32 chainId;
        uint96 reserved;
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

import "./data-access/INftStorage.sol";
import "./IdType.sol";

abstract contract IBalance {
    function _insertNft(address owner, IdType id, INftStorage.NFTDef storage) internal virtual;

    function _removeNft(address owner, INftStorage.NFTDef storage) internal virtual;

    /**
     * @dev Gets id of the first NFT with the specified state.
     * @notice Reverts if there is no such NFT.
     */
    function _getHeadId(address owner, StateType nftState) internal virtual view returns (IdType);

    function _getTotalNftCount(address owner) internal virtual view returns (uint);
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

import "../IBalance.sol";
import "../data-access/IBalanceStorage.sol";

abstract contract Balance is IBalance, INftStorage, IBalanceStorage {
    using StateTypeLib for StateType;
    using IdTypeLib for IdType;
    /**
     * @dev The specified nft state is not supported by the code.
     */
    error UnsupportedState(StateType nftState);
    /**
     * @dev User doesn't have required amount of NFTs of the specified kind on the balance.
     */
    error NotEnoughEmptyNfts(address user);
    error NotEnoughMysteryNfts(address user, uint32 expected, uint32 butGot);
    error NotEnoughRareNfts(address user, uint rarity, uint32 expected, uint32 butGot);

    function _insertNft(address owner, IdType id, NFTDef storage nft) internal override {
        // getting user structs
        NFTCounter storage userBalances = _balances(owner);

        // getting head
        IdType headId = _getHeadId(nft.state, userBalances);

        // inserting a new element to global list
        if (headId != EMPTY_ID) {
            NFTDef storage nftHead = _nft(headId);
            nftHead.left = id;
        }

        nft.left = EMPTY_ID;
        nft.right = headId;

        // setting new head in user struct
        _setHead(id, nft, userBalances);

        // increase counter
        _increaseUserRarityCounter(userBalances, nft);
    }

    function _removeNft(address owner, NFTDef storage nft) internal override {
        // getting user structs
        NFTCounter storage userBalances = _balances(owner);

        // reduce and check counter
        _decreaseUserRarityCounter(owner, userBalances, nft);

        // getting left and right nft ids
        IdType leftId = nft.left;
        IdType rightId = nft.right;

        // linking the right and left elements
        if (leftId != EMPTY_ID) {
            NFTDef storage nftLeft = _nft(leftId);
            nftLeft.right = rightId;
        }
        else {
            // update head if removed NFT hasn't left NFT
            _setHead(rightId, nft, userBalances);
        }

        if (rightId != EMPTY_ID) {
            NFTDef storage nftRight = _nft(rightId);
            nftRight.left = leftId;
        }
    }

    function _getHeadId(address owner, StateType nftState) internal override view returns (IdType) {
        NFTCounter storage userBalances = _balances(owner);
        IdType id = _getHeadId(nftState, userBalances);

        if (id.isEmpty()) {
            _throwError(owner, userBalances, nftState, 1);
        }

        return id;
    }


    /**
     * @notice This method only PRIVATE, because it doesn't check anything.
     */
    function _getHeadId(StateType nftState, NFTCounter storage counters) private view returns (IdType) {
        if (nftState.isMystery()) {
            return counters.mysteryHead;
        }
        else if (nftState.isEmpty()) {
            return counters.emptyHead;
        }
        else if (nftState.isRare()) {
            return counters.rarityIdToHead[nftState.toRarity()];
        }
        else {
            revert UnsupportedState(nftState);
        }
    }

    function _getTotalNftCount(address owner) internal override view returns (uint) {
        NFTCounter storage balances = _balances(owner);
        uint total = balances.emptyCount + balances.mysteryCount;

        for(uint i = 0; i < balances.rarityIdToCount.length; ++i) {
            total += balances.rarityIdToCount[i];
        }

        return total;
    }

    function _setHead(IdType id, NFTDef storage nft, NFTCounter storage counters) private {
        StateType nftState = nft.state;
        if (nftState.isMystery()) {
            counters.mysteryHead = id;
        }
        else if (nftState.isEmpty()) {
            counters.emptyHead = id;
        }
        else if (nftState.isRare()) {
            counters.rarityIdToHead[nftState.toRarity()] = id;
        }
        else {
            revert UnsupportedState(nftState);
        }
    }

    function _increaseUserRarityCounter(NFTCounter storage counters, NFTDef storage nft) private {
        StateType nftState = nft.state;
        if (nftState.isMystery()) {
            counters.mysteryCount++;
        }
        else if (nftState.isEmpty()) {
            counters.emptyCount++;
        }
        else if (nftState.isRare()) {
            counters.rarityIdToCount[nftState.toRarity()]++;
        }
        else {
            revert UnsupportedState(nftState);
        }
    }

    function _decreaseUserRarityCounter(address owner, NFTCounter storage userCounters, NFTDef storage nft) private {
        _decreaseUserRarityCounter(owner, userCounters, nft.state, 1);
    }


    function _decreaseUserRarityCounter(address owner, NFTCounter storage counters, StateType nftState, uint32 count) private {
        if (nftState.isMystery()) {
            if (counters.mysteryCount < count) {
                revert NotEnoughMysteryNfts(owner, count, counters.mysteryCount);
            }
            unchecked {
                counters.mysteryCount -= count;
            }
        }
        else if (nftState.isEmpty()) {
            if (counters.emptyCount < count) {
                revert NotEnoughEmptyNfts(owner);
            }
            unchecked {
                counters.emptyCount -= count;
            }
        }
        else if (nftState.isRare()) {
            uint rarity = nftState.toRarity();
            if (counters.rarityIdToCount[rarity] < count) {
                revert NotEnoughRareNfts(owner, rarity, count, counters.rarityIdToCount[rarity]);
            }
            unchecked {
                counters.rarityIdToCount[rarity] -= count;
            }
        }
        else {
            revert UnsupportedState(nftState);
        }
    }

    function _throwError(address owner, NFTCounter storage counters, StateType nftState, uint32 count) private view {
        if (nftState.isMystery()) {
            revert NotEnoughMysteryNfts(owner, count, counters.mysteryCount);
        }
        else if (nftState.isEmpty()) {
            revert NotEnoughEmptyNfts(owner);
        }
        else if (nftState.isRare()) {
            revert NotEnoughRareNfts(owner, nftState.toRarity(), count, counters.rarityIdToCount[nftState.toRarity()]);
        }
        else {
            revert UnsupportedState(nftState);
        }
    }
}

// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.19;

import "../data-access/IJackpotStorage.sol";
import "../Utils.sol";

abstract contract Jackpot is IJackpotStorage {
    using TransferUtil for address;
    using ProbabilityLib for Probability;

    /**
     * @dev Jackpot was claimed.
     * @param winner An account who claimed the jackpot.
     * @param tokens The jackpot prize tokens.
     * @param amounts The jackpot prize amounts.
     */
    event JackpotClaim(address winner, address[] tokens, uint[] amounts);

    function _claimJackpot(address pool, address target) internal {
        address[] memory tokens = _listJackpots();
        uint[] memory amounts = new uint[](tokens.length);

        for (uint i = 0; i < tokens.length; i ++) {
            address token = tokens[i];
            uint jackpot = _jackpot(token);
            uint share = _jackpotShare().mul(jackpot);
            if (share >= jackpot) {
                continue;
            }
            _addJackpot(token, -int(share));
            amounts[i] = share;
            token.erc20TransferFrom(pool, target, share);
        }

        emit JackpotClaim(target, tokens, amounts);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../data-access/INftStorage.sol";
import "../IBalance.sol";

/**
 * @dev Storageless ERC721 implementation based on @openzeppelin/contracts/token/ERC721/ERC721.sol
 */
abstract contract Nft is Context, IBalance, INftStorage, ERC165, IERC721, IERC721Metadata {
    /**
     * @dev Wrong NFT state.
     */
    error WrongNftState(uint tokenId, StateType expected, StateType got);
    /**
     * @dev NFT wasn't properly locked.
     */
    error NftMustBeLocked(uint tokenId);

    /**
     * @dev The NFT is locked, and no operations can be performed with it in this state.
     */
    error NftIsLocked(uint tokenId);

    using StateTypeLib for uint256;
    using StateTypeLib for StateType;
    using Strings for uint256;
    using IdTypeLib for uint256;
    using IdTypeLib for IdType;
    using Address for address;

    event Locked(uint tokenId);
    event Unlocked(uint tokenId);
    event MetadataUpdate(uint tokenId);

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _getTotalNftCount(owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _nft(tokenId.toId()).owner;
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name();
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol();
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        IdType id = tokenId.toId();
        NFTDef storage nft = _nft(id);
        require(nft.owner != address(0), "ERC721: invalid token ID");
        bool isLocked = nft.flags & NFT_FLAG_LOCKED != 0;

        string memory baseURI = _baseURI();
        StateType nftState = nft.state;
        if (nftState.isMystery()) {
            return string(abi.encodePacked(baseURI, "mystic.json"));
        }
        else if (nftState.isEmpty()) {
            return string(abi.encodePacked(baseURI, "empty", isLocked ? "_locked.json" : ".json"));
        }
        else if (nftState.isRare()) {
            uint rarity = nftState.toRarity();
            return string(abi.encodePacked(baseURI, "rarity", rarity.toString(), isLocked ? "_locked.json" : ".json"));
        }

        revert("ERC721: invalid token state");
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = Nft.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _nft(tokenId.toId()).approval;
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
        return _operatorApprovals(owner, operator);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _nft(tokenId.toId()).owner;
    }

    /**
     * @dev Returns the owner of the `id`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(IdType id) internal view virtual returns (address) {
        return _nft(id).owner;
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
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether a token with the specified `id` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(IdType id) internal view virtual returns (bool) {
        return _ownerOf(id) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = Nft.ownerOf(tokenId);
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
    function _safeMint(address to, IdType id, uint16 boost) internal virtual {
        _safeMint(to, id, boost, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, IdType id, uint16 boost, bytes memory data) internal virtual {
        _mint(to, id, boost);
        require(
            _checkOnERC721Received(address(0), to, id.toTokenId(), data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     * Emits {Transfer} and {Locked} events.
     */
    function _mint(address to, IdType id, uint16 boost) internal virtual {
        NFTDef storage nft = _nft(id);

        nft.owner = to;
        nft.state = MYSTERY_STATE;
        nft.flags = NFT_FLAG_LOCKED;
        nft.boost = boost;

        _insertNft(to, id, nft);

        uint tokenId = id.toTokenId();
        emit Transfer(address(0), to, tokenId);
        emit Locked(tokenId);
    }

    /**
     * @dev Updates status to Empty for the specified token.
     * Emits a {Unlocked} event.
     */
    function _markAsEmpty(IdType id, uint32 random) internal {
        NFTDef storage nft = _nft(id);
        if (nft.state.isNotMystery()) {
            revert WrongNftState(id.toTokenId(), nft.state, MYSTERY_STATE);
        }

        // remove mystery nft
        _removeNft(nft.owner, nft);

        // change nft type
        nft.state = EMPTY_STATE;
        nft.entropy = random;

        _unlockAndReturn(id, nft);
    }

    /**
     * @dev Updates rarity and entropy of the specified token.
     * Emits a {Unlocked} event.
     */
    function _markAsRare(IdType id, uint rarityLevel, uint32 random) internal {
        NFTDef storage nft = _nft(id);
        if (nft.state.isNotMystery()) {
            revert WrongNftState(id.toTokenId(), nft.state, MYSTERY_STATE);
        }

        // remove mystery nft from the user
        _removeNft(nft.owner, nft);

        // change nft state
        nft.state = rarityLevel.toState();
        nft.entropy = random;

        _unlockAndReturn(id, nft);
    }

    /**
     * @dev Destroys first token by `rarity`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `nftState` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burnByRarity(address owner, uint rarity) internal virtual returns (IdType) {
        IdType id = _getHeadId(owner, rarity.toState());
        NFTDef storage nft = _nft(id);
        // remove an NFT from the user balance
        _removeNft(owner, nft);
        // delete an NFT definition completely
        _deleteNft(id);

        emit Transfer(owner, address(0), id.toTokenId());

        return id;
    }

    function _burnByRarityMultiple(address owner, uint rarity, uint32 count) internal virtual {
        for (uint i = 0; i < count; i ++) {
            _burnByRarity(owner, rarity);
        }
    }

    function _burnEmpty(address owner) private {
        IdType id = _getHeadId(owner, EMPTY_STATE);
        NFTDef storage nft = _nft(id);
        // remove an NFT from the user balance
        _removeNft(owner, nft);
        // delete an NFT definition completely
        _deleteNft(id);

        emit Transfer(owner, address(0), id.toTokenId());
    }

    function _burnEmptyMultiple(address owner, uint32 count) internal virtual {
        for (uint i = 0; i < count; i ++) {
            _burnEmpty(owner);
        }
    }

    function _lockFirst(address owner, uint rarity) internal virtual returns (IdType) {
        // check owner balance
        StateType nftState = rarity.toState();
        IdType id = _getHeadId(owner, nftState);
        NFTDef storage nft = _nft(id);
        _removeNft(owner, nft);
        nft.flags |= NFT_FLAG_LOCKED;

        emit Locked(id.toTokenId());

        return id;
    }

    function _unlockAndReturn(IdType id, NFTDef storage nft) internal virtual {
        if ((nft.flags & NFT_FLAG_LOCKED) == 0) {
            revert NftMustBeLocked(id.toTokenId());
        }
        // return a NFT on to the user balance
        _insertNft(nft.owner, id, nft);
        // and unlock it
        nft.flags &= ~NFT_FLAG_LOCKED;
        emit Unlocked(id.toTokenId());
        emit MetadataUpdate(id.toTokenId());
    }

    function _burnLocked(address owner, IdType id, NFTDef storage nft) internal virtual {
        if ((nft.flags & NFT_FLAG_LOCKED) == 0) {
            revert NftMustBeLocked(id.toTokenId());
        }

        _deleteNft(id);
        emit Transfer(owner, address(0), id.toTokenId());
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(Nft.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        IdType id = tokenId.toId();
        NFTDef storage nft = _nft(id);

        // check if nft is locked
        if (nft.flags & NFT_FLAG_LOCKED != 0) {
            revert NftIsLocked(tokenId);
        }

        _removeNft(from, nft);
        nft.owner = to;
        // Clear approvals from the previous owner
        nft.approval = address(0);
        _insertNft(to, id, nft);

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, id, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _nft(tokenId.toId()).approval = to;
        emit Approval(Nft.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals(owner, operator, approved);
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
        if (!to.isContract()) {
            return true;
        }

        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        }
        catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, IdType firstTokenId, uint256 batchSize) internal virtual {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
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
    error WrongTotalRaritiesProbability(Probability current, Probability expected);

    error NftNotAccessible(address collection, uint tokenId, address pool, address owner);
    error TooSmallBalance(address token, uint expected, uint actual);
    error NftAlreadyUsed(address collection, uint tokenId);
    error NftPrizeNotFound(address collection, uint tokenId);
    error NftPrizeNotAvailable(uint rarirty);
    error NoNftPrizeAvailable(uint rarity);
    error NoErc20PrizeAvailable(uint rarirty);
    error RarityByProbabilityNotFound(uint chance);
    error ArrayLengthOutOfRange(uint specified, uint min, uint max);

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

    function _checkNftAccessible(address pool, address collection, uint tokenId) internal view {
        address owner = IERC721(collection).ownerOf(tokenId);
        if (IERC721(collection).isApprovedForAll(owner, address(this))) {
            return;
        }
        if (IERC721(collection).ownerOf(tokenId) == address(this)) {
            return;
        }
        if (IERC721(collection).getApproved(tokenId) == address(this)) {
            return;
        }
        revert NftNotAccessible(collection, tokenId, pool, owner);
    }

    function _checkNftNotUsed(address collection, uint tokenId) internal view {
        if (_getPrizeIdByNft(collection, tokenId) > 0) {
            revert NftAlreadyUsed(collection, tokenId);
        }
    }

//    function _checkErc20(address pool, address token, uint amount) internal view {
//        if (IERC20(token).balanceOf(pool) <= amount) {
//            revert TooSmallBalance(token, amount, IERC20(token).balanceOf(pool));
//        }
//    }

    function _setErc20Prize(uint rarity, address token, uint amount, uint32 chainId) internal returns(uint32) {
        uint32 ercPrizeId = _getPrizeIdOffset(uint8(rarity));

        PrizeDef storage prizeDef = _prizes(ercPrizeId);
        prizeDef.token = token;
        prizeDef.value = amount;
        prizeDef.chainId = chainId;

        return ercPrizeId;
    }

    function _addNftPrizes(uint rarity, NftInfo[] memory nfts, address pool) internal {
        // TODO: add pool size check
        uint count = nfts.length;
        if (count == 0 || count > type(uint16).max) {
            revert ArrayLengthOutOfRange(count, 1, type(uint16).max);
        }
        RarityDef storage rarityDef = _rarity(rarity);

        // get first id
        uint32 firstId = rarityDef.count;
        if (firstId < MIN_PRIZE_INDEX) {
            firstId = MIN_PRIZE_INDEX;
        }
        firstId = _getPrizeIdOffset(uint8(rarity)) + firstId;

        // we move from left to right
        uint32 left = rarityDef.tail;

        for (uint32 i = 0; i < count; i ++) {
            uint32 id = firstId + i;

            // check if already used
            uint32 existingId = _getPrizeIdByNft(nfts[i].collection, nfts[i].tokenId);
            if (existingId != 0) {
                revert NftAlreadyUsed(nfts[i].collection, nfts[i].tokenId);
            }
            // mark as used
            _addPrizeIdByNft(nfts[i].collection, nfts[i].tokenId, id);

            // save payload
            PrizeDef storage prizeDef = _prizes(id);
            prizeDef.token = nfts[i].collection;
            prizeDef.value = nfts[i].tokenId;
            prizeDef.probability = nfts[i].probability;
            prizeDef.flags = PRIZE_NFT;
            prizeDef.chainId = nfts[i].chainId;

            // save list
            prizeDef.left = left;
            // next element or zero
            prizeDef.right = (i == count - 1 ? 0 : id + 1);
            left = id;
        }

        // connect to the existing list
        if (rarityDef.tail != 0) {
            PrizeDef storage prevPrize = _prizes(rarityDef.tail);
            prevPrize.right = firstId;
        }

        // update rarity def
        rarityDef.tail = left;
        rarityDef.count += uint32(count);
        if (rarityDef.head == 0) {
            rarityDef.head = firstId;
        }
    }

    function _removeNftPrize(uint rarity, address collection, uint tokenId) internal {
        uint32 id = _getPrizeIdByNft(collection, tokenId);
        if (id == 0) {
            revert NftPrizeNotFound(collection, tokenId);
        }

        RarityDef storage rarityDef = _rarity(rarity);
        PrizeDef storage prizeDef = _prizes(id);

        uint32 lastId = _getPrizeIdOffset(uint8(rarity)) + rarityDef.count;

        _removePrizeIdByNft(prizeDef.token, prizeDef.value);

        if (lastId > id) {
            PrizeDef storage lastPrizeDef = _prizes(lastId);
            _cloneParams(lastPrizeDef, prizeDef);
            _addPrizeIdByNft(lastPrizeDef.token, lastPrizeDef.value, id);
        }

        _delPrize(lastId);
        rarityDef.count --;
    }

    function _tryPlayNftPrize(
            uint rarity,
            address target,
            Random.Seed memory random,
            uint32 chainId) internal returns (bool, uint, address, uint32) {
        // get random prize
        uint32 poolSize = _rarity(rarity).count;
        uint32 prizeIndex = (random.get32() % poolSize) + MIN_PRIZE_INDEX;
        uint32 prizeId = _getPrizeIdOffset(rarity) + prizeIndex;
        PrizeDef storage prizeDef = _prizes(prizeId);

        // check if prize is played out
        if (!prizeDef.probability.isPlayedOut(random.get16(), 1)) {
            return (false, 0, address(0), 0);
        }

        // transfer prize
        address collection = prizeDef.token;
        uint tokenId = prizeDef.value;
        uint32 prizeChainId = prizeDef.chainId;

        _removeNftPrize(rarity, collection, tokenId);

        if (prizeChainId == chainId) {
            collection.erc721Transfer(target, tokenId);
        }

        return (true,  tokenId, collection, prizeChainId);
    }

    function _tryClaimErc20Prize(
            address pool,
            uint rarity,
            address target,
            uint32 chainId) internal returns (bool, uint, address, uint32) {
        uint32 id = _getPrizeIdOffset(rarity);

        PrizeDef storage prizeDef = _prizes(id);
        address token = prizeDef.token;
        uint amount = prizeDef.value;

        if (amount == 0) {
            revert NoErc20PrizeAvailable(rarity);
        }

        if (prizeDef.chainId == chainId) {
            uint balance = token.erc20BalanceOf(pool);
            if (balance < amount) {
                return (false, amount, token, 0);
            }

            token.erc20TransferFrom(pool, target, amount);
        }

        return (true, amount, token, prizeDef.chainId);
    }

    function _addLootBoxCount(uint rarity, uint32 count) internal {
        RarityDef storage rarityDef = _rarity(rarity);
        rarityDef.lbCounter += count;
    }

    function _decLootBoxCount(uint rarity) internal {
        RarityDef storage rarityDef = _rarity(rarity);
        rarityDef.lbCounter --;
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

    function _cloneParams(PrizeDef storage fromPrize, PrizeDef storage toPrize) private {
        toPrize.token = fromPrize.token;
        toPrize.flags = fromPrize.flags;
        toPrize.right = fromPrize.right;
        toPrize.left = fromPrize.left;
        toPrize.value = fromPrize.value;
        toPrize.probability = fromPrize.probability;
    }

    function _getPrizeIdOffset(uint rarity) internal pure returns (uint32) {
        return uint32(rarity * RARITY_PRIZE_CAPACITY);
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

import "../data-access/ISignedNftStorage.sol";

abstract contract Sign is ISignedNftStorage {
    error UnconfirmedSignature();
    error ExternalIdAlreadyUsed(uint64 externalId);
    error ExpiredSignature(uint64 expiredAt, uint64 currentTimestamp);

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function _verifySignature(
            address lootBoxAddress,
            address userAddress,
            uint64 externalId,
            uint64 expiredAt,
            Signature calldata signature) internal view {
        // check if signature expired
        uint64 currentTimestamp = uint64(block.timestamp);
        if (currentTimestamp > expiredAt) {
            revert ExpiredSignature(expiredAt, currentTimestamp);
        }

        bytes memory encoded = abi.encodePacked(lootBoxAddress, userAddress, externalId, expiredAt);
        bytes32 hash = sha256(encoded);

        address recoveredSigner = ecrecover(hash, signature.v, signature.r, signature.s);

        if (_signer() != recoveredSigner) {
            revert UnconfirmedSignature();
        }
    }

    function _verifySignature(address lootBoxAddress, address userAddress, uint64 expiredAt, Signature calldata signature) internal view {
        // check if signature expired
        uint64 currentTimestamp = uint64(block.timestamp);
        if (currentTimestamp > expiredAt) {
            revert ExpiredSignature(expiredAt, currentTimestamp);
        }

        bytes memory encoded = abi.encodePacked(lootBoxAddress, userAddress, expiredAt);
        bytes32 hash = sha256(encoded);

        address recoveredSigner = ecrecover(hash, signature.v, signature.r, signature.s);

        if (_signer() != recoveredSigner) {
            revert UnconfirmedSignature();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./VRF.sol";
import "./AccessControl.sol";
import "./Storage.sol";
import "./logic/Balance.sol";
import "./data-access/ILootBoxStorage.sol";
import "./logic/Prize.sol";
import "./logic/Price.sol";
import "./logic/Nft.sol";
import "./logic/Jackpot.sol";
import "./logic/Sign.sol";
import "./LootBox.sol";

contract LootBox is ILootBoxStorage, Storage, AccessControl, Nft, Prize, Price, Sign, VRF, Jackpot, IERC721Receiver, Balance {
    /**
     * @dev There is not fund to claim.
     */
    error NoFundsAvailable(address token, address pool);

    /**
     * @dev Contract wasn't properly initialized.
     * @param version required storage version.
     */
    error NotInitialized(uint8 version);

    /**
     * @dev Out of range.
     */
    error OutOfRange(string name, uint got, uint min, uint max);

    /**
     * @dev Wrong owner.
     */
    error WrongOwner(uint tokenId, address got, address owner);

    /**
     * @dev The action is called out of scope.
     */
    error OutOfScope(bool tooEarly, bool tooLate, bool maxSupplyReached);

    error NotEnoughErc20(address token, uint amount, address pool);

    /**
     * @dev Loot boxes are revealed.
     */
    event LootBoxRevealed(address indexed buyer, uint emptyCount, uint[] rarityCounts);
    /**
     * @dev NFT prize was won by the user.
     */
    event NftPrizeClaimed(uint indexed lootBoxId, uint indexed tokenId, address collection, address user, uint chainId);
    /**
     * @dev ERC20 prize was claimed by the user.
     */
    event Erc20PrizeClaimed(uint indexed lootBoxId, uint amount, address tokenContract, address user, uint chainId);

    uint8 constant public STORAGE_VERSION = 1;

    using TransferUtil for address;
    using ProbabilityLib for Probability;
    using IdTypeLib for IdType;
    using IdTypeLib for uint;
    using Random for Random.Seed;
    using StateTypeLib for StateType;
    using StateTypeLib for uint;

    modifier onlyInitialized() {
        if (_getInitializedVersion() != STORAGE_VERSION) {
            revert NotInitialized(STORAGE_VERSION);
        }
        _;
    }

    modifier onlyInScope(uint addingCount) {
        Scope storage scope = _scope();
        uint64 supply = _totalSupplyWithBoost() + uint64(addingCount);
        if (block.timestamp < scope.begin
            || block.timestamp >= scope.end
            || supply > scope.maxSupply) {
            revert OutOfScope(block.timestamp < scope.begin, block.timestamp >= scope.end, supply > scope.maxSupply);
        }
        _;
    }

    modifier onlyOutOfScope() {
        Scope storage scope = _scope();
        uint64 supply = _totalSupplyWithBoost();
        if (scope.alwaysBurn == 0 && block.timestamp < scope.end && supply < scope.maxSupply) {
            revert OutOfScope(block.timestamp < scope.end, false, supply < scope.maxSupply);
        }
        _;
    }

    function init(string memory name_, string memory symbol_, string memory baseUri_, uint64 maxSupply, uint32 begin, uint32 end, address signer) initializer public virtual override(Storage) {
        // in this case tx.origin is account who has access to proxy admin contract.
        _setupRole(ADMIN_ROLE, tx.origin);
        _setRoleAdmin(PRIZE_MANAGER_ROLE, ADMIN_ROLE);
        _grantRole(PRIZE_MANAGER_ROLE, tx.origin);
        if (maxSupply == 0) {
            maxSupply = type(uint64).max;
        }
        if (end == 0) {
            end = type(uint32).max;
        }
        if (begin >= end) {
            revert OutOfRange("begin", begin, 0, end);
        }
        Storage.init(name_, symbol_, baseUri_, maxSupply, begin, end, signer);
    }

    /**
     * @dev By a specified amount of LootBoxes for the specified tokens.
     */
    function buy(address token, uint count, uint16 boost) public {
        // @notice there is no modifiers only because they exists in the underlying method
        //          if you change the underlying method you have to add modifiers
        buyFor(_msgSender(), token, count, boost);
    }

    /**
     * @dev By a specified amount of LootBoxes for the specified tokens.
     */
    function buyFor(address user, address token, uint count, uint boost) public onlyInitialized onlyInScope(count * boost) {
        if (boost < MIN_NFT_BOOST || boost > MAX_NFT_BOOST) {
            revert OutOfRange("boost", boost, MIN_NFT_BOOST, MAX_NFT_BOOST);
        }
        if (count < MIN_BUY_COUNT || count > MAX_BUY_COUNT) {
            revert OutOfRange("count", count, MIN_BUY_COUNT, MAX_BUY_COUNT);
        }

        address payer = _msgSender();
        uint totalValue = _debit(token, payer, address(this), count * boost);
        if (boost > 1) {
            _addBoostAdding(uint32(count * boost - count));
        }

        uint jackpotAdd = _config().jackpotPriceShare.mul(totalValue);
        _addJackpot(token, int(jackpotAdd));

        IdType id = _nextTokenId(count);
        mintFor(user, count, uint16(boost), id);

        _requestBuyRandom(id, uint16(count));
    }

    function checkSignature(
        address user,
        uint64 externalId,
        uint64 expiredAt,
        Signature calldata signature) public view onlyInitialized returns (bool) {
        if (_getUsed(externalId)) {
            revert ExternalIdAlreadyUsed(externalId);
        }

        _verifySignature(address(this), user, externalId, expiredAt, signature);
        return true;
    }

    function acquireFree(
        address user,
        uint64 externalId,
        uint64 expiredAt,
        Signature calldata signature
    ) public onlyInScope(1) onlyInitialized {

        // check if this external id was used and mark it as used
        if (_getUsedAndSet(externalId)) {
            revert ExternalIdAlreadyUsed(externalId);
        }

        // verify signature
        _verifySignature(address(this), _msgSender(), externalId, expiredAt, signature);

        // mint new NFT
        uint16 count = 1;
        IdType id = _nextTokenId(count);
        mintFor(user, count, MIN_NFT_BOOST, id);

        // request random
        _requestBuyRandom(id, count);
    }

    /**
     * @dev Burn a token in exchange for a prize is chosen by random.
     */
    function burnForRandomPrize(uint rarity) public onlyInitialized onlyOutOfScope {
        if (rarity >= RARITIES) {
            revert OutOfRange("rarity", rarity, 0, RARITIES - 1);
        }

        // check claim counter
//        uint32 claimRequestsCount = _counters().claimRequestCounter;
        uint32 prizesCount = _rarity(rarity).count;
        if (prizesCount == 0) {
            burnForErc20Prize(rarity);
            return;
        }

        // lock box
        IdType lockedId = _lockFirst(_msgSender(), rarity);

//        _increaseClaimRequestCounter(1);
        _requestClaimRandom(lockedId);
    }

    /**
     * @dev Burn a token in exchange for a ERC20 prize.
     */
    function burnForErc20Prize(uint rarity) public onlyInitialized onlyOutOfScope {
        if (rarity >= RARITIES) {
            revert OutOfRange("rarity", rarity, 0, RARITIES - 1);
        }

        IdType id = _burnByRarity(_msgSender(), rarity);
        _decLootBoxCount(rarity);
        (bool result, uint amount, address token, uint32 chainId) =
                        _tryClaimErc20Prize(address(this), rarity, _msgSender(), uint32(block.chainid));

        if (!result) {
            revert NotEnoughErc20(token, amount, address(this));
        }
        else {
            emit Erc20PrizeClaimed(id.toTokenId(), amount, token, _msgSender(), chainId);
        }
    }

    /**
     * @dev Burn empty tokens in exchange for a jackpot.
     */
    function burnForJackpot() public onlyInitialized {
        _burnEmptyMultiple(_msgSender(), 3);
        _addEmptyCounter(-3);
        _claimJackpot(address(this), _msgSender());
    }

    //********* Utilities

    function _randomBuyResponseHandler(IdType firstId, uint16 count, Random.Seed memory random) internal override {
        uint emptyCount = 0;
        uint[] memory rarityCounts = new uint[](RARITIES);

        // get first owner to be sure that the rest are the same!
        // to avoid overriding nfts belonging to other
        address owner = _nft(firstId).owner;
        for (uint i = 0; i < count; i ++) {
            IdType id = firstId.next(i);
            NFTDef storage nft = _nft(id);
            uint16 boost = nft.boost;
            if (owner != nft.owner) {
                revert WrongOwner(id.toTokenId(), owner, nft.owner);
            }
            // determine rarity
            (bool rare, uint rarity) = _lookupRarity(random.get16(), boost);
            if (rare) {
                rarityCounts[rarity] ++;
                _markAsRare(id, rarity, random.get32());
            }
            else {
                _markAsEmpty(id, random.get32());
                emptyCount ++;
            }

        }

        for (uint i = 0; i < RARITIES; i ++) {
            uint32 counter = uint32(rarityCounts[i]);
            if (counter == 0) {
                continue;
            }

            _addLootBoxCount(i, counter);
        }

        _addEmptyCounter(int32(uint32(emptyCount)));

        emit LootBoxRevealed(owner, emptyCount, rarityCounts);
    }

    function _randomClaimResponseHandler(IdType id, Random.Seed memory random) internal override {
//        _decreaseClaimRequestCounter(1);
        uint32 thisChainId = uint32(block.chainid);
        NFTDef storage nft = _nft(id);
        if (!nft.state.isRare()) {
            revert WrongNftState(id.toTokenId(), uint(0).toState(), nft.state);
        }

        uint rarity = nft.state.toRarity();
        // check rarity pool size
        RarityDef storage rarityDef = _rarity(rarity);
        uint32 poolSize = rarityDef.count;
        bool winNft = false;

        // case 1: we have prizes
        if (poolSize > 0) {
            (bool nftResult, uint prizeTokenId, address collection, uint32 nftChainId) =
                            _tryPlayNftPrize(rarity, nft.owner, random, thisChainId);
            if (nftResult) {
                winNft = true;
                emit NftPrizeClaimed(id.toTokenId(), prizeTokenId, collection, nft.owner, nftChainId);
            }
        }

        // case 2: we do not have prizes or the chance is weak
        if (poolSize == 0 || !winNft) {
            (bool erc20result, uint prizeAmount, address token, uint32 erc20chainId) =
                            _tryClaimErc20Prize(address(this), rarity, nft.owner, thisChainId);

            // special case: no ERC20 tokens
            if (!erc20result) {
                _unlockAndReturn(id, nft);
                return;
            }
            emit Erc20PrizeClaimed(id.toTokenId(), prizeAmount, token, nft.owner, erc20chainId);
        }

        _burnLocked(nft.owner, id, nft);
        _decLootBoxCount(rarity);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, Nft) returns (bool) {
        return AccessControl.supportsInterface(interfaceId) || Nft.supportsInterface(interfaceId);
    }

    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 /* tokenId */,
        bytes calldata /* data */
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }


    //*************** Public view functions

    function mintFor(address to, uint toMintCount, uint16 boost, IdType firstId) private {
        for (uint i = 0; i < toMintCount; i ++) {
            IdType nextId = firstId.next(i);
            _safeMint(to, nextId, boost);
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

function eProbability(Probability a, Probability b) pure returns (bool) {
    return Probability.unwrap(a) == Probability.unwrap(b);
}

function neProbability(Probability a, Probability b) pure returns (bool) {
    return !eProbability(a, b);
}

using {
      gtProbability as >
    , ltProbability as <
    , gteProbability as >=
    , lteProbability as <=
    , eProbability as ==
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
    // TODO: make it private, public only for debug
    mapping(uint => RarityDef) public rarities;
    // TODO: make it private, public only for debug
    mapping(uint32 => PrizeDef) public prizes;
    mapping(bytes32 => uint32) private uniquePrize;

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

    function init(string memory name_, string memory symbol_, string memory baseUri_, uint64 maxSupply, uint32 begin, uint32 end, address signer) initializer public virtual {
        counters.nextBoxId = FIRST_ID; // starts from 1
        name = name_;
        symbol = symbol_;
        baseUri = baseUri_;
        scope.maxSupply = maxSupply;
        scope.begin = begin;
        scope.end = end;
        scope.alwaysBurn = 1;
        config.signer = signer;
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

    function _getPrizeIdByNft(address collection, uint tokenId) internal view override returns (uint32) {
        return uniquePrize[keccak256(abi.encodePacked(collection, tokenId))];
    }

    function _addPrizeIdByNft(address collection, uint tokenId, uint32 id) internal override {
        uniquePrize[keccak256(abi.encodePacked(collection, tokenId))] = id;
    }

    function _removePrizeIdByNft(address collection, uint tokenId) internal override {
        delete uniquePrize[keccak256(abi.encodePacked(collection, tokenId))];
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

    function _totalSupplyWithBoost() internal override view returns (uint64) {
        return counters.nextBoxId.unwrap() - 1 + counters.boostAdding;
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

    function _addBoostAdding(uint32 amount) internal override {
        counters.boostAdding += amount;
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

    function erc721Transfer(address token, address to, uint tokenId) internal {
        address owner = IERC721(token).ownerOf(tokenId);
        IERC721(token).safeTransferFrom(owner, to, tokenId);
    }

    function erc20BalanceOf(address token, address account) internal view returns (uint) {
        return IERC20(token).balanceOf(account);
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