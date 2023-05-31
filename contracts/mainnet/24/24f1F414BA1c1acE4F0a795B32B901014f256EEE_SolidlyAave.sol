// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
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
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
        return _roles[role].members[account];
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
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
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
        _roles[role].adminRole = adminRole;
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
            _roles[role].members[account] = true;
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
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

struct AuthConfig {
	address owner;
	address guardian;
	address manager;
}

contract Auth is AccessControl {
	event OwnershipTransferInitiated(address owner, address pendingOwner);
	event OwnershipTransferred(address oldOwner, address newOwner);

	////////// CONSTANTS //////////

	/// Update vault params, perform time-sensitive operations, set manager
	bytes32 public constant GUARDIAN = keccak256("GUARDIAN");

	/// Hot-wallet bots that route funds between vaults, rebalance and harvest strategies
	bytes32 public constant MANAGER = keccak256("MANAGER");

	/// Add and remove vaults and strategies and other critical operations behind timelock
	/// Default admin role
	/// There should only be one owner, so it is not a role
	address public owner;
	address public pendingOwner;

	modifier onlyOwner() {
		require(msg.sender == owner, "ONLY_OWNER");
		_;
	}

	constructor(AuthConfig memory authConfig) {
		/// Set up the roles
		// owner can manage all roles
		owner = authConfig.owner;
		emit OwnershipTransferred(address(0), authConfig.owner);

		// TODO do we want cascading roles like this?
		_grantRole(DEFAULT_ADMIN_ROLE, authConfig.owner);
		_grantRole(GUARDIAN, authConfig.owner);
		_grantRole(GUARDIAN, authConfig.guardian);
		_grantRole(MANAGER, authConfig.owner);
		_grantRole(MANAGER, authConfig.guardian);
		_grantRole(MANAGER, authConfig.manager);

		/// Allow the guardian role to manage manager
		_setRoleAdmin(MANAGER, GUARDIAN);
	}

	// ----------- Ownership -----------

	/// @dev Init transfer of ownership of the contract to a new account (`_pendingOwner`).
	/// @param _pendingOwner pending owner of contract
	/// Can only be called by the current owner.
	function transferOwnership(address _pendingOwner) external onlyOwner {
		pendingOwner = _pendingOwner;
		emit OwnershipTransferInitiated(owner, _pendingOwner);
	}

	/// @dev Accept transfer of ownership of the contract.
	/// Can only be called by the pendingOwner.
	function acceptOwnership() external {
		address newOwner = pendingOwner;
		require(msg.sender == newOwner, "ONLY_PENDING_OWNER");
		address oldOwner = owner;
		owner = newOwner;

		// revoke the DEFAULT ADMIN ROLE from prev owner
		_revokeRole(DEFAULT_ADMIN_ROLE, oldOwner);
		_revokeRole(GUARDIAN, oldOwner);
		_revokeRole(MANAGER, oldOwner);

		_grantRole(DEFAULT_ADMIN_ROLE, newOwner);
		_grantRole(GUARDIAN, newOwner);
		_grantRole(MANAGER, newOwner);

		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Auth } from "./Auth.sol";
import { EAction } from "../interfaces/Structs.sol";
import { SectorErrors } from "../interfaces/SectorErrors.sol";

// import "hardhat/console.sol";

abstract contract StratAuth is Auth, SectorErrors {
	address public vault;

	modifier onlyVault() {
		if (msg.sender != vault) revert OnlyVault();
		_;
	}

	event EmergencyAction(address indexed target, bytes data);

	/// @notice calls arbitrary function on target contract in case of emergency
	function emergencyAction(EAction[] calldata actions) public payable onlyOwner {
		uint256 l = actions.length;
		for (uint256 i; i < l; ++i) {
			address target = actions[i].target;
			bytes memory data = actions[i].data;
			(bool success, ) = target.call{ value: actions[i].value }(data);
			require(success, "emergencyAction failed");
			emit EmergencyAction(target, data);
		}
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { HarvestSwapParams } from "../../interfaces/Structs.sol";
import { SectorErrors } from "../../interfaces/SectorErrors.sol";

interface ISCYStrategy {
	function underlying() external view returns (IERC20);

	function deposit(uint256 amount) external returns (uint256);

	function redeem(address to, uint256 amount) external returns (uint256 amntOut);

	function closePosition(uint256 slippageParam) external returns (uint256);

	function getAndUpdateTvl() external returns (uint256);

	function getTvl() external view returns (uint256);

	function getMaxTvl() external view returns (uint256);

	function collateralToUnderlying() external view returns (uint256);

	function harvest(
		HarvestSwapParams[] calldata farm1Params,
		HarvestSwapParams[] calldata farm2Parms
	) external returns (uint256[] memory harvest1, uint256[] memory harvest2);

	function getWithdrawAmnt(uint256 lpTokens) external view returns (uint256);

	function getDepositAmnt(uint256 uAmnt) external view returns (uint256);

	function getLpBalance() external view returns (uint256);

	function getLpToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { HarvestSwapParams } from "../Structs.sol";
import { ISCYStrategy } from "./ISCYStrategy.sol";

struct SCYVaultConfig {
	string symbol;
	string name;
	address addr;
	uint16 strategyId; // this is strategy specific token if 1155
	bool acceptsNativeToken;
	address yieldToken;
	IERC20 underlying;
	uint128 maxTvl; // pack all params and balances
	uint128 balance; // strategy balance in underlying
	uint128 uBalance; // underlying balance
	uint128 yBalance; // yield token balance
}

interface ISCYVault {
	// scy deposit
	function deposit(
		address receiver,
		address tokenIn,
		uint256 amountTokenToPull,
		uint256 minSharesOut
	) external payable returns (uint256 amountSharesOut);

	function redeem(
		address receiver,
		uint256 amountSharesToPull,
		address tokenOut,
		uint256 minTokenOut
	) external returns (uint256 amountTokenOut);

	function pause() external;

	function unpause() external;

	function getAndUpdateTvl() external returns (uint256 tvl);

	function getTvl() external view returns (uint256 tvl);

	function MIN_LIQUIDITY() external view returns (uint256);

	function underlying() external view returns (IERC20);

	function yieldToken() external view returns (address);

	function sendERC20ToStrategy() external view returns (bool);

	function strategy() external view returns (ISCYStrategy);

	function underlyingBalance(address) external view returns (uint256);

	function underlyingToShares(uint256 amnt) external view returns (uint256);

	function exchangeRateUnderlying() external view returns (uint256);

	function sharesToUnderlying(uint256 shares) external view returns (uint256);

	function getUpdatedUnderlyingBalance(address) external returns (uint256);

	function getFloatingAmount(address) external view returns (uint256);

	function getStrategyTvl() external view returns (uint256);

	function acceptsNativeToken() external view returns (bool);

	function underlyingDecimals() external view returns (uint8);

	function getMaxTvl() external view returns (uint256);

	function closePosition(uint256 minAmountOut, uint256 slippageParam) external;

	function initStrategy(address) external;

	function harvest(
		uint256 expectedTvl,
		uint256 maxDelta,
		HarvestSwapParams[] calldata swap1,
		HarvestSwapParams[] calldata swap2
	) external returns (uint256[] memory harvest1, uint256[] memory harvest2);

	function withdrawFromStrategy(uint256 shares, uint256 minAmountOut) external;

	function depositIntoStrategy(uint256 amount, uint256 minSharesOut) external;

	function uBalance() external view returns (uint256);

	function setMaxTvl(uint256) external;

	function getDepositAmnt(uint256 amount) external view returns (uint256);

	function getWithdrawAmnt(uint256 amount) external view returns (uint256);

	// function totalAssets() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

interface SectorErrors {
	error NotImplemented();
	error MaxTvlReached();
	error StrategyHasBalance();
	error MinLiquidity();
	error OnlyVault();
	error ZeroAmount();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

enum CallType {
	ADD_LIQUIDITY_AND_MINT,
	BORROWB,
	REMOVE_LIQ_AND_REPAY
}

enum VaultType {
	Strategy,
	Aggregator
}

enum EpochType {
	None,
	Withdraw,
	Full
}

enum NativeToken {
	None,
	Underlying,
	Short
}

struct CalleeData {
	CallType callType;
	bytes data;
}
struct AddLiquidityAndMintCalldata {
	uint256 uAmnt;
	uint256 sAmnt;
}
struct BorrowBCalldata {
	uint256 borrowAmount;
	bytes data;
}
struct RemoveLiqAndRepayCalldata {
	uint256 removeLpAmnt;
	uint256 repayUnderlying;
	uint256 repayShort;
	uint256 borrowUnderlying;
	// uint256 amountAMin;
	// uint256 amountBMin;
}

struct HarvestSwapParams {
	address[] path; //path that the token takes
	uint256 min; // min price of in token * 1e18 (computed externally based on spot * slippage + fees)
	uint256 deadline;
	bytes pathData; // uniswap3 path data
}

struct IMXConfig {
	address vault;
	address underlying;
	address short;
	address uniPair;
	address poolToken;
	address farmToken;
	address farmRouter;
}

struct HLPConfig {
	string symbol;
	string name;
	address underlying;
	address short;
	address cTokenLend;
	address cTokenBorrow;
	address uniPair;
	address uniFarm;
	address farmToken;
	uint256 farmId;
	address farmRouter;
	address comptroller;
	address lendRewardRouter;
	address lendRewardToken;
	address vault;
	NativeToken nativeToken;
}

struct EAction {
	address target;
	uint256 value;
	bytes data;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IUniswapV2Factory {
	event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

	function feeTo() external view returns (address);

	function feeToSetter() external view returns (address);

	function getPair(address tokenA, address tokenB) external view returns (address pair);

	function allPairs(uint256) external view returns (address pair);

	function allPairsLength() external view returns (uint256);

	function createPair(address tokenA, address tokenB) external returns (address pair);

	function setFeeTo(address) external;

	function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IUniswapV2Pair {
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function name() external pure returns (string memory);

	function symbol() external pure returns (string memory);

	function decimals() external pure returns (uint8);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function PERMIT_TYPEHASH() external pure returns (bytes32);

	function nonces(address owner) external view returns (uint256);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	event Mint(address indexed sender, uint256 amount0, uint256 amount1);
	event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
	event Swap(
		address indexed sender,
		uint256 amount0In,
		uint256 amount1In,
		uint256 amount0Out,
		uint256 amount1Out,
		address indexed to
	);
	event Sync(uint112 reserve0, uint112 reserve1);

	function MINIMUM_LIQUIDITY() external pure returns (uint256);

	function factory() external view returns (address);

	function token0() external view returns (address);

	function token1() external view returns (address);

	function getReserves()
		external
		view
		returns (
			uint112 reserve0,
			uint112 reserve1,
			uint32 blockTimestampLast
		);

	function price0CumulativeLast() external view returns (uint256);

	function price1CumulativeLast() external view returns (uint256);

	function kLast() external view returns (uint256);

	function mint(address to) external returns (uint256 liquidity);

	function burn(address to) external returns (uint256 amount0, uint256 amount1);

	function swap(
		uint256 amount0Out,
		uint256 amount1Out,
		address to,
		bytes calldata data
	) external;

	function skim(address to) external;

	function sync() external;

	function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IUniswapV2Router01 {
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

	function getAmountsOut(uint256 amountIn, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function getAmountsIn(uint256 amountOut, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IWETH {
	function deposit() external payable;

	function transfer(address to, uint256 value) external returns (bool);

	function withdraw(uint256) external;

	function balanceOf(address) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
	/*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

	uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

	function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
		return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
	}

	function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
		return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
	}

	function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
		return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
	}

	function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
		return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
	}

	/*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

	function mulDivDown(
		uint256 x,
		uint256 y,
		uint256 denominator
	) internal pure returns (uint256 z) {
		assembly {
			// Store x * y in z for now.
			z := mul(x, y)

			// Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
			if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
				revert(0, 0)
			}

			// Divide z by the denominator.
			z := div(z, denominator)
		}
	}

	function mulDivUp(
		uint256 x,
		uint256 y,
		uint256 denominator
	) internal pure returns (uint256 z) {
		assembly {
			// Store x * y in z for now.
			z := mul(x, y)

			// Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
			if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
				revert(0, 0)
			}

			// First, divide z - 1 by the denominator and add 1.
			// We allow z - 1 to underflow if z is 0, because we multiply the
			// end result by 0 if z is zero, ensuring we return 0 if z is zero.
			z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
		}
	}

	function rpow(
		uint256 x,
		uint256 n,
		uint256 scalar
	) internal pure returns (uint256 z) {
		assembly {
			switch x
			case 0 {
				switch n
				case 0 {
					// 0 ** 0 = 1
					z := scalar
				}
				default {
					// 0 ** n = 0
					z := 0
				}
			}
			default {
				switch mod(n, 2)
				case 0 {
					// If n is even, store scalar in z for now.
					z := scalar
				}
				default {
					// If n is odd, store x in z for now.
					z := x
				}

				// Shifting right by 1 is like dividing by 2.
				let half := shr(1, scalar)

				for {
					// Shift n right by 1 before looping to halve it.
					n := shr(1, n)
				} n {
					// Shift n right by 1 each iteration to halve it.
					n := shr(1, n)
				} {
					// Revert immediately if x ** 2 would overflow.
					// Equivalent to iszero(eq(div(xx, x), x)) here.
					if shr(128, x) {
						revert(0, 0)
					}

					// Store x squared.
					let xx := mul(x, x)

					// Round to the nearest number.
					let xxRound := add(xx, half)

					// Revert if xx + half overflowed.
					if lt(xxRound, xx) {
						revert(0, 0)
					}

					// Set x to scaled xxRound.
					x := div(xxRound, scalar)

					// If n is even:
					if mod(n, 2) {
						// Compute z * x.
						let zx := mul(z, x)

						// If z * x overflowed:
						if iszero(eq(div(zx, x), z)) {
							// Revert if x is non-zero.
							if iszero(iszero(x)) {
								revert(0, 0)
							}
						}

						// Round to the nearest number.
						let zxRound := add(zx, half)

						// Revert if zx + half overflowed.
						if lt(zxRound, zx) {
							revert(0, 0)
						}

						// Return properly scaled zxRound.
						z := div(zxRound, scalar)
					}
				}
			}
		}
	}

	/*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

	function sqrt(uint256 x) internal pure returns (uint256 z) {
		assembly {
			// Start off with z at 1.
			z := 1

			// Used below to help find a nearby power of 2.
			let y := x

			// Find the lowest power of 2 that is at least sqrt(x).
			if iszero(lt(y, 0x100000000000000000000000000000000)) {
				y := shr(128, y) // Like dividing by 2 ** 128.
				z := shl(64, z) // Like multiplying by 2 ** 64.
			}
			if iszero(lt(y, 0x10000000000000000)) {
				y := shr(64, y) // Like dividing by 2 ** 64.
				z := shl(32, z) // Like multiplying by 2 ** 32.
			}
			if iszero(lt(y, 0x100000000)) {
				y := shr(32, y) // Like dividing by 2 ** 32.
				z := shl(16, z) // Like multiplying by 2 ** 16.
			}
			if iszero(lt(y, 0x10000)) {
				y := shr(16, y) // Like dividing by 2 ** 16.
				z := shl(8, z) // Like multiplying by 2 ** 8.
			}
			if iszero(lt(y, 0x100)) {
				y := shr(8, y) // Like dividing by 2 ** 8.
				z := shl(4, z) // Like multiplying by 2 ** 4.
			}
			if iszero(lt(y, 0x10)) {
				y := shr(4, y) // Like dividing by 2 ** 4.
				z := shl(2, z) // Like multiplying by 2 ** 2.
			}
			if iszero(lt(y, 0x8)) {
				// Equivalent to 2 ** z.
				z := shl(1, z)
			}

			// Shifting right by 1 is like dividing by 2.
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))

			// Compute a rounded down version of z.
			let zRoundDown := div(x, z)

			// If zRoundDown is smaller, use it.
			if lt(zRoundDown, z) {
				z := zRoundDown
			}
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "../interfaces/uniswap/IUniswapV2Pair.sol";
import "../interfaces/uniswap/IUniswapV2Router01.sol";
import "../interfaces/uniswap/IUniswapV2Factory.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library UniUtils {
	using SafeERC20 for IERC20;

	function _getPairTokens(IUniswapV2Pair pair) internal view returns (address, address) {
		return (pair.token0(), pair.token1());
	}

	function _getPairReserves(
		IUniswapV2Pair pair,
		address tokenA,
		address tokenB
	) internal view returns (uint256 reserveA, uint256 reserveB) {
		(address token0, ) = _sortTokens(tokenA, tokenB);
		(uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
		(reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
	}

	// given some amount of an asset and lp reserves, returns an equivalent amount of the other asset
	function _quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) internal pure returns (uint256 amountB) {
		require(amountA > 0, "UniUtils: INSUFFICIENT_AMOUNT");
		require(reserveA > 0 && reserveB > 0, "UniUtils: INSUFFICIENT_LIQUIDITY");
		amountB = (amountA * reserveB) / reserveA;
	}

	function _sortTokens(address tokenA, address tokenB)
		internal
		pure
		returns (address token0, address token1)
	{
		require(tokenA != tokenB, "UniUtils: IDENTICAL_ADDRESSES");
		(token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
		require(token0 != address(0), "UniUtils: ZERO_ADDRESS");
	}

	function _getAmountOut(
		IUniswapV2Pair pair,
		uint256 amountIn,
		address inToken,
		address outToken
	) internal view returns (uint256 amountOut) {
		require(amountIn > 0, "UniUtils: INSUFFICIENT_INPUT_AMOUNT");
		(uint256 reserveIn, uint256 reserveOut) = _getPairReserves(pair, inToken, outToken);
		uint256 amountInWithFee = amountIn * 997;
		uint256 numerator = amountInWithFee * reserveOut;
		uint256 denominator = reserveIn * 1000 + amountInWithFee;
		amountOut = numerator / denominator;
	}

	function _getAmountIn(
		IUniswapV2Pair pair,
		uint256 amountOut,
		address inToken,
		address outToken
	) internal view returns (uint256 amountIn) {
		require(amountOut > 0, "UniUtils: INSUFFICIENT_OUTPUT_AMOUNT");
		(uint256 reserveIn, uint256 reserveOut) = _getPairReserves(pair, inToken, outToken);
		uint256 numerator = reserveIn * amountOut * 1000;
		uint256 denominator = (reserveOut - amountOut) * 997;
		amountIn = (numerator / denominator) + 1;
	}

	function _swapExactTokensForTokens(
		IUniswapV2Pair pair,
		uint256 amountIn,
		address inToken,
		address outToken
	) internal returns (uint256) {
		uint256 amountOut = _getAmountOut(pair, amountIn, inToken, outToken);
		if (amountOut == 0) return 0;
		_swap(pair, amountIn, amountOut, inToken, outToken);
		return amountOut;
	}

	function _swapTokensForExactTokens(
		IUniswapV2Pair pair,
		uint256 amountOut,
		address inToken,
		address outToken
	) internal returns (uint256) {
		uint256 amountIn = _getAmountIn(pair, amountOut, inToken, outToken);
		_swap(pair, amountIn, amountOut, inToken, outToken);
		return amountIn;
	}

	function _swap(
		IUniswapV2Pair pair,
		uint256 amountIn,
		uint256 amountOut,
		address inToken,
		address outToken
	) internal {
		(address token0, ) = _sortTokens(outToken, inToken);
		(uint256 amount0Out, uint256 amount1Out) = inToken == token0
			? (uint256(0), amountOut)
			: (amountOut, uint256(0));
		IERC20(inToken).safeTransfer(address(pair), amountIn);
		pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { IBase, HarvestSwapParams } from "../mixins/IBase.sol";
import { ILending } from "../mixins/ILending.sol";
import { IUniFarm, SafeERC20, IERC20 } from "../mixins/IUniFarm.sol";
import { IWETH } from "../../interfaces/uniswap/IWETH.sol";
import { UniUtils, IUniswapV2Pair } from "../../libraries/UniUtils.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Auth } from "../../common/Auth.sol";
import { FixedPointMathLib } from "../../libraries/FixedPointMathLib.sol";
import { StratAuth } from "../../common/StratAuth.sol";
import { ISCYVault } from "../../interfaces/ERC5115/ISCYVault.sol";
import { ISCYStrategy } from "../../interfaces/ERC5115/ISCYStrategy.sol";
import { SectorErrors } from "../../interfaces/SectorErrors.sol";
import { AutomationCompatibleInterface } from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

// import "hardhat/console.sol";

// @custom: alphabetize dependencies to avoid linearization conflicts
abstract contract HLPCore is
	SectorErrors,
	StratAuth,
	ReentrancyGuard,
	IBase,
	ILending,
	IUniFarm,
	ISCYStrategy,
	AutomationCompatibleInterface
{
	using UniUtils for IUniswapV2Pair;
	using SafeERC20 for IERC20;
	using FixedPointMathLib for uint256;

	event Deposit(address sender, uint256 amount);
	event Redeem(address sender, uint256 amount);
	event Harvest(uint256 harvested); // this is actual the tvl before harvest
	event Rebalance(uint256 shortPrice, uint256 tvlBeforeRebalance, uint256 positionOffset);
	event EmergencyWithdraw(address indexed recipient, IERC20[] tokens);
	event UpdatePosition();

	event RebalanceLoan(address indexed sender, uint256 startLoanHealth, uint256 updatedLoanHealth);
	event setMinLoanHealth(uint256 loanHealth);
	event SetMaxDefaultPriceMismatch(uint256 maxDefaultPriceMismatch);
	event SetRebalanceThreshold(uint256 rebalanceThreshold);
	event SetMaxTvl(uint256 maxTvl);
	event SetSafeCollateralRaio(uint256 collateralRatio);

	uint8 public constant REBALANCE_LOAN = 1;
	uint8 public constant REBALANCE = 2;

	uint256 constant MIN_LIQUIDITY = 1000;
	uint256 public constant maxPriceOffset = 2000; // maximum offset for rebalanceLoan & manager  methods 20%
	uint256 constant BPS_ADJUST = 10000;

	uint256 public lastHarvest; // block.timestamp;

	IERC20 private _underlying;
	IERC20 private _short;

	uint256 public maxDefaultPriceMismatch = 100; // 1%
	uint256 public constant maxAllowedMismatch = 300; // manager cannot set user-price mismatch to more than 3%
	uint256 public minLoanHealth = 1.15e18; // how close to liquidation we get

	uint16 public rebalanceThreshold = 400; // 4% of lp

	uint256 private _safeCollateralRatio = 8000; // 80%

	uint256 public constant version = 1;

	bool public harvestIsEnabled = true;

	// checks if deposits are paused on the parent SCYVault
	modifier isPaused() {
		if (ISCYVault(vault).getMaxTvl() != 0) revert NotPaused();
		_;
	}

	/// @notice check current dex price against oracle price and ensure that its within maxSlippage
	/// @dev this may prevent keeper bots from executing the tx in the case of
	/// a sudden price spike on a CEX
	modifier checkPrice(uint256 maxSlippage) {
		if (maxSlippage == 0) maxSlippage = maxDefaultPriceMismatch;
		else if (hasRole(GUARDIAN, msg.sender) || msg.sender == vault) {
			// guradian and vault don't have limits for maxSlippage
		} else if (hasRole(MANAGER, msg.sender)) {
			// manager accounts cannot set maxSlippage bigger than maxPriceOffset
			require(maxSlippage <= maxPriceOffset, "HLP: MAX_MISMATCH");
		}
		// all other users can set maxSlippage up to maxAllowedMismatch
		else maxSlippage = maxDefaultPriceMismatch;
		require(getPriceOffset() <= maxSlippage, "HLP: PRICE_MISMATCH");
		_;
	}

	constructor(
		address underlying_,
		address short_,
		address _vault
	) {
		_underlying = IERC20(underlying_);
		_short = IERC20(short_);

		vault = _vault;

		_underlying.safeIncreaseAllowance(address(this), type(uint256).max);

		// emit default settings events
		emit setMinLoanHealth(minLoanHealth);
		emit SetMaxDefaultPriceMismatch(maxDefaultPriceMismatch);
		emit SetRebalanceThreshold(rebalanceThreshold);
		emit SetSafeCollateralRaio(_safeCollateralRatio);
	}

	function safeCollateralRatio() public view override returns (uint256) {
		return _safeCollateralRatio;
	}

	function setSafeCollateralRatio(uint256 safeCollateralRatio_) public onlyOwner {
		require(safeCollateralRatio_ >= 1000 && safeCollateralRatio_ <= 8500, "STRAT: BAD_INPUT");
		_safeCollateralRatio = safeCollateralRatio_;
		emit SetSafeCollateralRaio(safeCollateralRatio_);
	}

	function decimals() public view returns (uint8) {
		return IERC20Metadata(address(_underlying)).decimals();
	}

	// OWNER CONFIG
	function setMinLoanHeath(uint256 minLoanHealth_) public onlyOwner {
		require(minLoanHealth_ > 1e18, "STRAT: BAD_INPUT");
		minLoanHealth = minLoanHealth_;
		emit setMinLoanHealth(minLoanHealth_);
	}

	// guardian can adjust max default price mismatch if needed
	function setMaxDefaultPriceMismatch(uint256 maxDefaultPriceMismatch_)
		public
		onlyRole(GUARDIAN)
	{
		require(maxDefaultPriceMismatch_ >= 25, "STRAT: BAD_INPUT"); // no less than .25%
		require(
			msg.sender == owner || maxAllowedMismatch >= maxDefaultPriceMismatch_,
			"STRAT: BAD_INPUT"
		);
		maxDefaultPriceMismatch = maxDefaultPriceMismatch_;
		emit SetMaxDefaultPriceMismatch(maxDefaultPriceMismatch_);
	}

	function setRebalanceThreshold(uint16 rebalanceThreshold_) public onlyOwner {
		// rebalance threshold should not be lower than 1% (2% price move)
		require(rebalanceThreshold_ >= 100, "STRAT: BAD_INPUT");
		rebalanceThreshold = rebalanceThreshold_;
		emit SetRebalanceThreshold(rebalanceThreshold_);
	}

	// PUBLIC METHODS

	function short() public view override returns (IERC20) {
		return _short;
	}

	function underlying() public view virtual override(IBase, ISCYStrategy) returns (IERC20) {
		return _underlying;
	}

	/// @notice public method that anyone can call if loan health falls below minLoanHealth
	/// @dev this method will succeed only when loanHealth is below minimum
	/// if price difference between dex and oracle is too large, this method will revert
	function rebalanceLoan() public nonReentrant {
		// limit offset to maxPriceOffset manager to prevent misuse
		if (hasRole(GUARDIAN, msg.sender)) {} else if (hasRole(MANAGER, msg.sender))
			require(getPriceOffset() <= maxPriceOffset, "HLP: PRICE_MISMATCH");
			// public methods need more protection agains griefing
			// NOTE: this may prevent gelato bots from executing the tx in the case of
			// a sudden price spike on a CEX
		else require(getPriceOffset() <= maxDefaultPriceMismatch, "HLP: PRICE_MISMATCH");

		uint256 _loanHealth = loanHealth();
		require(_loanHealth <= minLoanHealth, "HLP: SAFE");
		_rebalanceLoan(_loanHealth);
	}

	function _rebalanceLoan(uint256 _loanHealth) internal {
		(uint256 underlyingLp, ) = _getLPBalances();
		uint256 collateral = _getCollateralBalance();

		// get back to our target _safeCollateralRatio
		uint256 targetHealth = (10000 * 1e18) / _safeCollateralRatio;
		uint256 addCollateral = (1e18 * ((collateral * targetHealth) / _loanHealth - collateral)) /
			((targetHealth * 1e18) / _getCollateralFactor() + 1e18);

		// remove lp
		(uint256 underlyingBalance, uint256 shortBalance) = _decreaseULpTo(
			underlyingLp - addCollateral
		);

		_repay(shortBalance);
		_lend(underlyingBalance);
		emit RebalanceLoan(msg.sender, _loanHealth, loanHealth());
	}

	// deposit underlying and recieve lp tokens
	function deposit(uint256 underlyingAmnt) external onlyVault nonReentrant returns (uint256) {
		if (underlyingAmnt == 0) return 0; // cannot deposit 0

		// TODO this can cause DOS attack
		if (underlyingAmnt < _underlying.balanceOf(address(this))) revert NonZeroFloat();

		// deposit is already included in tvl
		require(underlyingAmnt <= getMaxDeposit(), "STRAT: OVER_MAX_TVL");

		uint256 startBalance = _getLiquidity();
		// this method should not change % allocation to lp vs collateral
		_increasePosition(underlyingAmnt);
		uint256 endBalance = _getLiquidity();
		return endBalance - startBalance;
	}

	/// @notice decreases position based to desired LP amount
	/// @dev ** does not rebalance remaining portfolio
	/// @param removeLp amount of lp amount to remove
	function redeem(address recipient, uint256 removeLp)
		public
		onlyVault
		returns (uint256 amountTokenOut)
	{
		if (removeLp < MIN_LIQUIDITY) return 0;
		// this is the full amount of LP tokens totalSupply of shares is entitled to
		_decreasePosition(removeLp);

		// TODO make sure we never have any extra underlying dust sitting around
		// all 'extra' underlying should allways be transferred back to the vault

		unchecked {
			amountTokenOut = _underlying.balanceOf(address(this));
		}
		_underlying.safeTransfer(recipient, amountTokenOut);
		emit Redeem(msg.sender, amountTokenOut);
	}

	/// @notice decreases position based on current ratio
	/// @dev ** does not rebalance any part of portfolio
	function _decreasePosition(uint256 removeLp) internal {
		uint256 collateralBalance = _updateAndGetCollateralBalance();
		uint256 shortPosition = _updateAndGetBorrowBalance();

		uint256 totalLp = _getLiquidity();
		/// rounding issues can occur if we leave dust
		if (removeLp + MIN_LIQUIDITY >= totalLp) removeLp = totalLp;

		uint256 redeemAmnt = collateralBalance.mulDivDown(removeLp, totalLp);
		uint256 repayAmnt = shortPosition.mulDivUp(removeLp, totalLp);

		// remove lp
		(, uint256 sLp) = _removeLp(removeLp);
		_tradeExact(repayAmnt, sLp, address(_short), address(_underlying));
		_repay(repayAmnt);
		_redeem(redeemAmnt);
	}

	function _tradeExact(
		uint256 target,
		uint256 balance,
		address exactToken,
		address token
	) internal returns (uint256 addToken, uint256 subtractToken) {
		if (target > balance)
			subtractToken = pair()._swapTokensForExactTokens(target - balance, token, exactToken);
		else if (balance > target)
			addToken = pair()._swapExactTokensForTokens(balance - target, exactToken, token);
	}

	/// @notice decreases position proportionally based on current position ratio
	// ** does not rebalance remaining portfolio
	function _increasePosition(uint256 underlyingAmnt) internal {
		if (underlyingAmnt < MIN_LIQUIDITY) revert MinLiquidity(); // avoid imprecision
		uint256 tvl = getAndUpdateTvl() - underlyingAmnt;

		uint256 collateralBalance = _updateAndGetCollateralBalance();
		uint256 shortPosition = _updateAndGetBorrowBalance();

		// else we use whatever the current ratio is
		(uint256 uLp, uint256 sLp) = _getLPBalances();

		// if this is the first deposit, or amounts are too small to do accounting
		// we use our desired ratio
		if (
			tvl < MIN_LIQUIDITY ||
			uLp < MIN_LIQUIDITY ||
			sLp < MIN_LIQUIDITY ||
			shortPosition < MIN_LIQUIDITY ||
			collateralBalance < MIN_LIQUIDITY
		) {
			uint256 addULp = _totalToLp(underlyingAmnt);
			uint256 borrowAmnt = _underlyingToShort(addULp);
			uint256 collateralAmnt = underlyingAmnt - addULp;
			_lend(collateralAmnt);
			_borrow(borrowAmnt);
			uint256 liquidity = _addLiquidity(addULp, borrowAmnt);
			_depositIntoFarm(liquidity);
			return;
		}

		{
			uint256 addSLp = (underlyingAmnt * sLp) / tvl;
			uint256 collateralAmnt = (collateralBalance * underlyingAmnt) / tvl;
			uint256 borrowAmnt = (shortPosition * underlyingAmnt) / tvl;

			_lend(collateralAmnt);
			_borrow(borrowAmnt);

			_increaseLpPosition(addSLp + sLp);
		}
	}

	// use the return of the function to estimate pending harvest via staticCall
	function harvest(
		HarvestSwapParams[] calldata uniParams,
		HarvestSwapParams[] calldata lendingParams
	)
		external
		onlyVault
		checkPrice(0)
		nonReentrant
		returns (uint256[] memory farmHarvest, uint256[] memory lendHarvest)
	{
		(uint256 startTvl, , , , , ) = getTVL();
		if (uniParams.length != 0) farmHarvest = _harvestFarm(uniParams);
		if (lendingParams.length != 0) lendHarvest = _harvestLending(lendingParams);

		// compound our lp position
		_increasePosition(underlying().balanceOf(address(this)));
		emit Harvest(startTvl);
	}

	function checkUpkeep(
		bytes calldata /* checkData */
	) external view override returns (bool upkeepNeeded, bytes memory performData) {
		if (getPositionOffset() >= rebalanceThreshold) {
			// using getPriceOffset here allows us to add the chainlink keeper as Manager
			performData = abi.encode(REBALANCE, getPriceOffset());
			upkeepNeeded = true;
		} else if (loanHealth() <= minLoanHealth) {
			performData = abi.encode(REBALANCE_LOAN, 0);
			upkeepNeeded = true;
		}
	}

	function performUpkeep(bytes calldata performData) external override {
		(uint8 action, uint256 priceOffset) = abi.decode(performData, (uint8, uint256));
		if (action == REBALANCE) rebalance(priceOffset);
		else if (action == REBALANCE_LOAN) rebalanceLoan();
	}

	/// @notice public keeper rebalance method
	/// @dev this
	/// if price difference between dex and oracle is too large, this method will revert
	/// if called by a keeper or non manager or non-guardian account
	function rebalance(uint256 maxSlippage) public checkPrice(maxSlippage) nonReentrant {
		// call this first to ensure we use an updated borrowBalance when computing offset
		uint256 tvl = getAndUpdateTvl();
		uint256 positionOffset = getPositionOffset();

		if (positionOffset < rebalanceThreshold) revert RebalanceThreshold();

		if (tvl == 0) return;
		uint256 targetUnderlyingLP = _totalToLp(tvl);

		// add .1% room for fees
		_rebalancePosition((targetUnderlyingLP * 999) / 1000, tvl - targetUnderlyingLP);
		emit Rebalance(_shortToUnderlying(1e18), positionOffset, tvl);
	}

	// note: one should call harvest before closing position
	function closePosition(uint256 maxSlippage)
		public
		checkPrice(maxSlippage)
		onlyVault
		returns (uint256 balance)
	{
		_closePosition();
		balance = _underlying.balanceOf(address(this));
		_underlying.safeTransfer(vault, balance);
		emit UpdatePosition();
	}

	// in case of emergency - remove LP
	// deposits should be paused because contracty may have underlying balance
	function removeLiquidity(uint256 removeLp, uint256 maxSlippage)
		public
		checkPrice(maxSlippage)
		onlyRole(GUARDIAN)
		isPaused
	{
		_removeLiquidity(removeLp);
		emit UpdatePosition();
	}

	// in case of emergency - withdraw lp tokens from farm
	// deposits should be paused because contracty may have underlying balance
	function withdrawFromFarm() public isPaused onlyRole(GUARDIAN) {
		_withdrawFromFarm(_getFarmLp());
		emit UpdatePosition();
	}

	// in case of emergency - withdraw stuck collateral
	// deposits should be paused because contracty may have underlying balance
	function redeemCollateral(uint256 repayAmnt, uint256 withdrawAmnt)
		public
		isPaused
		onlyRole(GUARDIAN)
	{
		_repay(repayAmnt);
		_redeem(withdrawAmnt);
		emit UpdatePosition();
	}

	function _closePosition() internal {
		_decreaseULpTo(0);
		uint256 shortPosition = _updateAndGetBorrowBalance();
		uint256 shortBalance = _short.balanceOf(address(this));
		if (shortPosition > shortBalance) {
			pair()._swapTokensForExactTokens(
				shortPosition - shortBalance,
				address(_underlying),
				address(_short)
			);
		} else if (shortBalance > shortPosition) {
			pair()._swapExactTokensForTokens(
				shortBalance - shortPosition,
				address(_short),
				address(_underlying)
			);
		}
		_repay(shortPosition);
		uint256 collateralBalance = _updateAndGetCollateralBalance();
		_redeem(collateralBalance);
	}

	function _decreaseULpTo(uint256 targetUnderlyingLP)
		internal
		returns (uint256 underlyingRemove, uint256 shortRemove)
	{
		(uint256 underlyingLp, ) = _getLPBalances();
		if (targetUnderlyingLP >= underlyingLp) return (0, 0); // nothing to withdraw
		uint256 liquidity = _getLiquidity();
		uint256 targetLiquidity = (liquidity * targetUnderlyingLP) / underlyingLp;
		uint256 removeLp = liquidity - targetLiquidity;
		uint256 liquidityBalance = pair().balanceOf(address(this));
		if (removeLp > liquidityBalance) _withdrawFromFarm(removeLp - liquidityBalance);
		return removeLp == 0 ? (0, 0) : _removeLiquidity(removeLp);
	}

	function _removeLp(uint256 removeLp)
		internal
		returns (uint256 underlyingRemove, uint256 shortRemove)
	{
		// TODO ensure that we never have LP not in farm
		_withdrawFromFarm(removeLp);
		return _removeLiquidity(removeLp);
	}

	function _rebalancePosition(uint256 targetUnderlyingLP, uint256 targetCollateral) internal {
		uint256 targetBorrow = _underlyingToShort(targetUnderlyingLP);
		// we already updated tvl
		uint256 currentBorrow = _getBorrowBalance();

		// borrow funds or repay loan
		if (targetBorrow > currentBorrow) {
			// if we have loose short balance we need to trade it for underlying
			uint256 shortBal = short().balanceOf(address(this));
			if (shortBal > 0) _tradeExact(0, shortBal, address(_short), address(_underlying));

			// remove extra lp (we may need to remove more in order to add more collateral)
			_decreaseULpTo(
				_needUnderlying(targetUnderlyingLP, targetCollateral) > 0 ? 0 : targetUnderlyingLP
			);
			// add collateral
			_adjustCollateral(targetCollateral);
			_borrow(targetBorrow - currentBorrow);
		} else if (targetBorrow < currentBorrow) {
			// remove all of lp so we can repay loan
			_decreaseULpTo(0);
			uint256 repayAmnt = min(_short.balanceOf(address(this)), currentBorrow - targetBorrow);
			if (repayAmnt > 0) _repay(repayAmnt);
			// remove extra collateral
			_adjustCollateral(targetCollateral);
		}
		_increaseLpPosition(targetBorrow);
	}

	///////////////////////////
	//// INCREASE LP POSITION
	///////////////////////
	function _increaseLpPosition(uint256 targetShortLp) internal {
		uint256 uBalance = _underlying.balanceOf(address(this));
		uint256 sBalance = _short.balanceOf(address(this));

		// here we make sure we don't add extra lp
		(, uint256 shortLP) = _getLPBalances();
		if (targetShortLp <= shortLP) return;

		uint256 addShort = targetShortLp - shortLP;

		(uint256 addU, uint256 subtractU) = _tradeExact(
			addShort,
			sBalance,
			address(_short),
			address(_underlying)
		);

		uBalance = uBalance + addU - subtractU;

		// we compute amount of undelrying we need after we have the final shortAmnt
		// this accounts for the potential trade above
		uint256 addUnderlying = _shortToUnderlying(addShort);

		// we know that now our short balance is exact sBalance = sAmnt
		// if we don't have enough underlying, we need to decrase sAmnt slighlty
		// TODO have trades account for slippage
		if (uBalance < addUnderlying) {
			addUnderlying = uBalance;
			// uint256 updatedAddShort = _underlyingToShort(uBalance);
			// addShort = addShort > updatedAddShort ? updatedAddShort : addShort;
			addShort = _underlyingToShort(uBalance);

			// if we have short dust, we can leave it for next rebalance
		} else if (uBalance > addUnderlying) {
			// if we have extra underlying, lend it back to avoid extra float
			_lend(uBalance - addUnderlying);
		}

		if (addUnderlying == 0) return;

		// add liquidity
		// don't need to use min with underlying and short because we did oracle check
		// amounts are exact because we used swap price above
		uint256 liquidity = _addLiquidity(addUnderlying, addShort);
		_depositIntoFarm(liquidity);
	}

	function _needUnderlying(uint256 tragetUnderlying, uint256 targetCollateral)
		internal
		view
		returns (uint256)
	{
		uint256 collateralBalance = _getCollateralBalance();
		if (targetCollateral < collateralBalance) return 0;
		(uint256 underlyingLp, ) = _getLPBalances();
		uint256 uBalance = tragetUnderlying > underlyingLp ? tragetUnderlying - underlyingLp : 0;
		uint256 addCollateral = targetCollateral - collateralBalance;
		if (uBalance >= addCollateral) return 0;
		return addCollateral - uBalance;
	}

	// TVL

	function getMaxTvl() public view returns (uint256) {
		// we don't want to get precise max borrow amaount available,
		// we want to stay at least a getCollateralRatio away from max borrow
		return _oraclePriceOfShort(_maxBorrow() + _getBorrowBalance());
	}

	function getMaxDeposit() public view returns (uint256) {
		// we don't want to get precise max borrow amaount available,
		// we want to stay at least a getCollateralRatio away from max borrow
		return _oraclePriceOfShort(_maxBorrow());
	}

	function getAndUpdateTvl() public returns (uint256 tvl) {
		uint256 collateralBalance = _updateAndGetCollateralBalance();
		uint256 shortPosition = _updateAndGetBorrowBalance();
		uint256 borrowBalance = _shortToUnderlying(shortPosition);
		uint256 shortP = _short.balanceOf(address(this));
		uint256 shortBalance = shortP == 0 ? 0 : _shortToUnderlying(shortP);
		(uint256 underlyingLp, ) = _getLPBalances();
		uint256 underlyingBalance = _underlying.balanceOf(address(this));
		uint256 assets = collateralBalance + underlyingLp * 2 + underlyingBalance + shortBalance;
		tvl = assets > borrowBalance ? assets - borrowBalance : 0;
	}

	// We can include a checkPrice(0) here for extra security
	// but it's not necessary with latestvault updates
	function balanceOfUnderlying() public view returns (uint256 assets) {
		(assets, , , , , ) = getTVL();
	}

	function getTvl() public view returns (uint256 tvl) {
		(tvl, , , , , ) = getTVL();
	}

	function getTotalTVL() public view returns (uint256 tvl) {
		(tvl, , , , , ) = getTVL();
	}

	function getTVL()
		public
		view
		returns (
			uint256 tvl,
			uint256 collateralBalance,
			uint256 borrowPosition,
			uint256 borrowBalance,
			uint256 lpBalance,
			uint256 underlyingBalance
		)
	{
		collateralBalance = _getCollateralBalance();
		borrowPosition = _getBorrowBalance();
		borrowBalance = _shortToUnderlying(borrowPosition);

		uint256 shortPosition = _short.balanceOf(address(this));
		uint256 shortBalance = shortPosition == 0 ? 0 : _shortToUnderlying(shortPosition);

		(uint256 underlyingLp, uint256 shortLp) = _getLPBalances();
		lpBalance = underlyingLp + _shortToUnderlying(shortLp);

		underlyingBalance = _underlying.balanceOf(address(this));

		uint256 assets = collateralBalance + lpBalance + underlyingBalance + shortBalance;
		tvl = assets > borrowBalance ? assets - borrowBalance : 0;
	}

	function getLPBalances() public view returns (uint256 underlyingLp, uint256 shortLp) {
		return _getLPBalances();
	}

	function getPositionOffset() public view returns (uint256 positionOffset) {
		(, uint256 shortLp) = _getLPBalances();
		uint256 borrowBalance = _getBorrowBalance();
		uint256 shortBalance = shortLp + _short.balanceOf(address(this));

		if (shortBalance == borrowBalance) return 0;
		// if short lp > 0 and borrowBalance is 0 we are off by inf, returning 100% should be enough
		if (borrowBalance == 0) return 10000;

		// this is the % by which our position has moved from beeing balanced
		positionOffset = shortBalance > borrowBalance
			? ((shortBalance - borrowBalance) * BPS_ADJUST) / borrowBalance
			: ((borrowBalance - shortBalance) * BPS_ADJUST) / borrowBalance;
	}

	function getPriceOffset() public view returns (uint256 offset) {
		uint256 minPrice = _shortToUnderlying(1e18);
		uint256 maxPrice = _oraclePriceOfShort(1e18);
		(minPrice, maxPrice) = maxPrice > minPrice ? (minPrice, maxPrice) : (maxPrice, minPrice);
		offset = ((maxPrice - minPrice) * BPS_ADJUST) / maxPrice;
	}

	// used to estimate the expected return of lp tokens for first deposit
	function collateralToUnderlying() public view returns (uint256) {
		uint256 currentLp = _getLiquidity();
		if (currentLp > MIN_LIQUIDITY) return (1e18 * getTvl()) / currentLp;
		(uint256 uR, uint256 sR, ) = pair().getReserves();
		(uR, sR) = address(_underlying) == pair().token0() ? (uR, sR) : (sR, uR);
		uint256 totalLp = pair().totalSupply();
		return (uR * 1e18 * 1e18) / totalLp / _totalToLp(1e18);
	}

	function getLpToken() public view returns (address) {
		return address(pair());
	}

	function getLpBalance() public view returns (uint256) {
		return _getLiquidity();
	}

	function getWithdrawAmnt(uint256 lpTokens) public view returns (uint256) {
		return (lpTokens * collateralToUnderlying()) / 1e18;
	}

	function getDepositAmnt(uint256 uAmnt) public view returns (uint256) {
		return (uAmnt * 1e18) / collateralToUnderlying();
	}

	// UTILS

	function _totalToLp(uint256 total) internal view returns (uint256) {
		uint256 cRatio = getCollateralRatio();
		return (total * cRatio) / (BPS_ADJUST + cRatio);
	}

	/**
	 * @dev Returns the smallest of two numbers.
	 */
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	receive() external payable {}

	error NotPaused();
	error RebalanceThreshold();
	error NonZeroFloat();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { HLPConfig } from "../../interfaces/Structs.sol";
import { HLPCore, IBase, IERC20 } from "./HLPCore.sol";
import { AaveModule } from "../modules/aave/AaveModule.sol";
import { AaveFarm } from "../modules/aave/AaveFarm.sol";
import { SolidlyFarm } from "../modules/solidly/SolidlyFarm.sol";
import { Auth, AuthConfig } from "../../common/Auth.sol";

// import "hardhat/console.sol";

/// @title SolidlyAave
/// @notice HLP Strategy using Solidly exchange and Aaave money market
contract SolidlyAave is HLPCore, AaveModule, AaveFarm, SolidlyFarm {
	// HLPCore should  be intialized last
	constructor(AuthConfig memory authConfig, HLPConfig memory config)
		Auth(authConfig)
		SolidlyFarm(
			config.uniPair,
			config.uniFarm,
			config.farmRouter,
			config.farmToken,
			config.farmId
		)
		AaveModule(config.comptroller, config.cTokenLend, config.cTokenBorrow)
		AaveFarm(config.lendRewardRouter, config.lendRewardToken)
		HLPCore(config.underlying, config.short, config.vault)
	{}

	function underlying() public view override(IBase, HLPCore) returns (IERC20) {
		return super.underlying();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { HarvestSwapParams } from "../../interfaces/Structs.sol";

// all interfaces need to inherit from base
abstract contract IBase {
	function short() public view virtual returns (IERC20);

	function underlying() public view virtual returns (IERC20);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IBase, HarvestSwapParams } from "./IBase.sol";

abstract contract IFarmable is IBase {
	event HarvestedToken(address indexed token, uint256 amount);

	function _validatePath(address farmToken, address[] memory path) internal view {
		address out = path[path.length - 1];
		// ensure malicious harvester is not trading with wrong tokens
		// TODO should we add more validation to prevent malicious path?
		require(
			((path[0] == address(farmToken) && (out == address(short()))) ||
				out == address(underlying())),
			"BAD_PATH"
		);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IBase, HarvestSwapParams } from "./IBase.sol";

// import "hardhat/console.sol";

abstract contract ILending is IBase {
	function _addLendingApprovals() internal virtual;

	function _getCollateralBalance() internal view virtual returns (uint256);

	function _getBorrowBalance() internal view virtual returns (uint256);

	function _updateAndGetCollateralBalance() internal virtual returns (uint256);

	function _updateAndGetBorrowBalance() internal virtual returns (uint256);

	function _getCollateralFactor() internal view virtual returns (uint256);

	function safeCollateralRatio() public view virtual returns (uint256);

	function _oraclePriceOfShort(uint256 amount) internal view virtual returns (uint256);

	function _oraclePriceOfUnderlying(uint256 amount) internal view virtual returns (uint256);

	function _lend(uint256 amount) internal virtual;

	function _redeem(uint256 amount) internal virtual;

	function _borrow(uint256 amount) internal virtual;

	function _repay(uint256 amount) internal virtual;

	function _harvestLending(HarvestSwapParams[] calldata swapParams)
		internal
		virtual
		returns (uint256[] memory);

	function lendFarmRouter() public view virtual returns (address);

	function getCollateralRatio() public view virtual returns (uint256) {
		return (_getCollateralFactor() * safeCollateralRatio()) / 1e18;
	}

	// returns loan health value which is collateralBalance / minCollateral
	function loanHealth() public view returns (uint256) {
		uint256 borrowValue = _oraclePriceOfShort(_getBorrowBalance());
		if (borrowValue == 0) return 100e18;
		uint256 collateralBalance = _getCollateralBalance();
		uint256 minCollateral = (borrowValue * 1e18) / _getCollateralFactor();
		return (1e18 * collateralBalance) / minCollateral;
	}

	function _adjustCollateral(uint256 targetCollateral)
		internal
		returns (uint256 added, uint256 removed)
	{
		uint256 collateralBalance = _getCollateralBalance();
		if (collateralBalance == targetCollateral) return (0, 0);
		(added, removed) = collateralBalance > targetCollateral
			? (uint256(0), _removeCollateral(collateralBalance - targetCollateral))
			: (_addCollateral(targetCollateral - collateralBalance), uint256(0));
	}

	function _removeCollateral(uint256 amountToRemove) internal returns (uint256 removed) {
		uint256 maxRemove = _freeCollateral();
		removed = maxRemove > amountToRemove ? amountToRemove : maxRemove;
		if (removed > 0) _redeem(removed);
	}

	function _freeCollateral() internal view returns (uint256) {
		uint256 collateral = _getCollateralBalance();
		uint256 borrowValue = _oraclePriceOfShort(_getBorrowBalance());
		// stay within 1% of the liquidation threshold (this is allways temporary)
		uint256 minCollateral = (100 * (borrowValue * 1e18)) / _getCollateralFactor() / 99;
		if (minCollateral > collateral) return 0;
		return collateral - minCollateral;
	}

	function _addCollateral(uint256 amountToAdd) internal returns (uint256 added) {
		uint256 underlyingBalance = underlying().balanceOf(address(this));
		added = underlyingBalance > amountToAdd ? amountToAdd : underlyingBalance;
		if (added != 0) _lend(added);
	}

	function _maxBorrow() internal view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

abstract contract ILp {
	function _quote(
		uint256 amount,
		address token0,
		address token1
	) internal view virtual returns (uint256 price);

	function _getLiquidity() internal view virtual returns (uint256);

	function _getLiquidity(uint256) internal view virtual returns (uint256);

	function _addLiquidity(uint256 amountToken0, uint256 amountToken1)
		internal
		virtual
		returns (uint256 liquidity);

	function _removeLiquidity(uint256 liquidity) internal virtual returns (uint256, uint256);

	function _getLPBalances()
		internal
		view
		virtual
		returns (uint256 underlyingBalance, uint256 shortBalance);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IBase, HarvestSwapParams } from "./IBase.sol";
import { IUniLp, SafeERC20, IERC20 } from "./IUniLp.sol";
import { IFarmable } from "./IFarmable.sol";

// import "hardhat/console.sol";

abstract contract IUniFarm is IBase, IUniLp, IFarmable {
	function _depositIntoFarm(uint256 amount) internal virtual;

	function _withdrawFromFarm(uint256 amount) internal virtual;

	function _harvestFarm(HarvestSwapParams[] calldata swapParams)
		internal
		virtual
		returns (uint256[] memory);

	function _getFarmLp() internal view virtual returns (uint256);

	function _addFarmApprovals() internal virtual;

	function farmRouter() public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IUniswapV2Pair } from "../../interfaces/uniswap/IUniswapV2Pair.sol";
import { UniUtils } from "../../libraries/UniUtils.sol";

import { IBase } from "./IBase.sol";
import { ILp } from "./ILp.sol";

// import "hardhat/console.sol";

abstract contract IUniLp is IBase, ILp {
	using SafeERC20 for IERC20;
	using UniUtils for IUniswapV2Pair;

	function pair() public view virtual returns (IUniswapV2Pair);

	// should only be called after oracle or user-input swap price check
	function _addLiquidity(uint256 amountToken0, uint256 amountToken1)
		internal
		virtual
		override
		returns (uint256 liquidity)
	{
		underlying().safeTransfer(address(pair()), amountToken0);
		short().safeTransfer(address(pair()), amountToken1);
		liquidity = pair().mint(address(this));
	}

	function _removeLiquidity(uint256 liquidity)
		internal
		virtual
		override
		returns (uint256, uint256)
	{
		IERC20(address(pair())).safeTransfer(address(pair()), liquidity);
		(address tokenA, ) = UniUtils._sortTokens(address(underlying()), address(short()));
		(uint256 amountToken0, uint256 amountToken1) = pair().burn(address(this));
		return
			tokenA == address(underlying())
				? (amountToken0, amountToken1)
				: (amountToken1, amountToken0);
	}

	function _quote(
		uint256 amount,
		address token0,
		address token1
	) internal view virtual override returns (uint256 price) {
		if (amount == 0) return 0;
		(uint256 reserve0, uint256 reserve1) = pair()._getPairReserves(token0, token1);
		price = UniUtils._quote(amount, reserve0, reserve1);
	}

	// fetches and sorts the reserves for a uniswap pair
	function getUnderlyingShortReserves() public view returns (uint256 reserveA, uint256 reserveB) {
		(reserveA, reserveB) = pair()._getPairReserves(address(underlying()), address(short()));
	}

	function _getLPBalances()
		internal
		view
		override
		returns (uint256 underlyingBalance, uint256 shortBalance)
	{
		uint256 totalLp = _getLiquidity();
		(uint256 totalUnderlyingBalance, uint256 totalShortBalance) = getUnderlyingShortReserves();
		uint256 total = pair().totalSupply();
		underlyingBalance = (totalUnderlyingBalance * totalLp) / total;
		shortBalance = (totalShortBalance * totalLp) / total;
	}

	// this is the current uniswap price
	function _shortToUnderlying(uint256 amount) internal view virtual returns (uint256) {
		return amount == 0 ? 0 : _quote(amount, address(short()), address(underlying()));
	}

	// this is the current uniswap price
	function _underlyingToShort(uint256 amount) internal view virtual returns (uint256) {
		return amount == 0 ? 0 : _quote(amount, address(underlying()), address(short()));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IUniswapV2Pair } from "../../../interfaces/uniswap/IUniswapV2Pair.sol";
import { IFarmable, HarvestSwapParams } from "../../mixins/IFarmable.sol";
import { ILending } from "../../mixins/ILending.sol";

// import "hardhat/console.sol";

abstract contract AaveFarm is ILending, IFarmable {
	using SafeERC20 for IERC20;

	constructor(address router_, address token_) {}

	function lendFarmRouter() public pure override returns (address) {
		return address(0);
	}

	function _harvestLending(HarvestSwapParams[] calldata swapParams)
		internal
		virtual
		override
		returns (uint256[] memory harvested)
	{}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IPool } from "./interfaces/IPool.sol";

import { IWETH } from "../../../interfaces/uniswap/IWETH.sol";

import { ILending } from "../../mixins/ILending.sol";
import { IBase } from "../../mixins/IBase.sol";

import { IAToken } from "./interfaces/IAToken.sol";
import { IAaveOracle } from "./interfaces/IAaveOracle.sol";
import { IPoolAddressesProvider } from "./interfaces/IPoolAddressesProvider.sol";

import { DataTypes, ReserveConfiguration } from "./libraries/ReserveConfiguration.sol";

// import "hardhat/console.sol";

abstract contract AaveModule is ILending {
	using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
	using SafeERC20 for IERC20;

	uint256 public constant INTEREST_RATE_MODE_VARIABLE = 2;

	using SafeERC20 for IERC20;

	/// @dev aToken
	IAToken private _cTokenLend;
	/// @dev aave DEBT token
	IAToken private _cTokenBorrow;
	IAToken private _debtToken;

	/// @dev aave pool
	IPool private _comptroller;
	IAaveOracle private _oracle;

	uint8 public uDec;
	uint8 public sDec;

	constructor(
		address comptroller_,
		address cTokenLend_,
		address cTokenBorrow_
	) {
		_cTokenLend = IAToken(cTokenLend_);
		_cTokenBorrow = IAToken(cTokenBorrow_);
		_comptroller = IPool(comptroller_);
		IPoolAddressesProvider addrsProv = IPoolAddressesProvider(
			_comptroller.ADDRESSES_PROVIDER()
		);
		_oracle = IAaveOracle(addrsProv.getPriceOracle());

		DataTypes.ReserveData memory reserveData = _comptroller.getReserveData(address(short()));
		_debtToken = IAToken(reserveData.variableDebtTokenAddress);
		_addLendingApprovals();

		uDec = IERC20Metadata(address(underlying())).decimals();
		sDec = IERC20Metadata(address(short())).decimals();
	}

	function _addLendingApprovals() internal override {
		// ensure USDC approval - assume we trust USDC
		underlying().safeIncreaseAllowance(address(_comptroller), type(uint256).max);
		short().safeIncreaseAllowance(address(_comptroller), type(uint256).max);
	}

	/// @dev aToken
	function cTokenLend() public view returns (IAToken) {
		return _cTokenLend;
	}

	/// @dev aave DEBT token
	function cTokenBorrow() public view returns (IAToken) {
		return _cTokenBorrow;
	}

	function oracle() public view returns (IAaveOracle) {
		return _oracle;
	}

	/// @dev technically pool
	function comptroller() public view returns (IPool) {
		return _comptroller;
	}

	function _redeem(uint256 amount) internal override {
		// TODO handle native underlying?
		comptroller().withdraw(address(underlying()), amount, address(this));
	}

	function _borrow(uint256 amount) internal override {
		comptroller().borrow(
			address(short()),
			amount,
			INTEREST_RATE_MODE_VARIABLE, // TODO should we use stable ever?
			0,
			address(this)
		);
	}

	function _lend(uint256 amount) internal override {
		// TODO handle native underlying?
		comptroller().supply(address(underlying()), amount, address(this), 0);
		comptroller().setUserUseReserveAsCollateral(address(underlying()), true);
	}

	function _repay(uint256 amount) internal override {
		comptroller().repay(address(short()), amount, INTEREST_RATE_MODE_VARIABLE, address(this));
	}

	/// TODO do we need to call update?
	function _updateAndGetCollateralBalance() internal override returns (uint256) {
		return _cTokenLend.balanceOf(address(this));
	}

	function _getCollateralBalance() internal view override returns (uint256) {
		return _cTokenLend.balanceOf(address(this));
	}

	function _updateAndGetBorrowBalance() internal override returns (uint256) {
		return _debtToken.balanceOf(address(this));
	}

	function _getBorrowBalance() internal view override returns (uint256 shortBorrow) {
		return _debtToken.balanceOf(address(this));
	}

	function _getCollateralFactor() internal view override returns (uint256) {
		uint256 ltv = comptroller().getConfiguration(address(underlying())).getLtv();
		return (ltv * 1e18) / 10000;
	}

	function _oraclePriceOfShort(uint256 amount) internal view override returns (uint256) {
		return
			((amount * oracle().getAssetPrice(address(short()))) * (10**uDec)) /
			oracle().getAssetPrice(address(underlying())) /
			(10**sDec);
	}

	function _oraclePriceOfUnderlying(uint256 amount) internal view override returns (uint256) {
		return
			((amount * oracle().getAssetPrice(address(underlying()))) * (10**sDec)) /
			oracle().getAssetPrice(address(short())) /
			(10**uDec);
	}

	function _maxBorrow() internal view virtual override returns (uint256) {
		uint256 maxBorrow = short().balanceOf(address(cTokenBorrow()));
		(uint256 borrowCap, ) = comptroller().getConfiguration(address(short())).getCaps();
		borrowCap = borrowCap * (10**sDec);
		uint256 borrowBalance = _debtToken.totalSupply();
		uint256 maxBorrowCap = borrowCap - borrowBalance;
		return maxBorrow > maxBorrowCap ? maxBorrowCap : maxBorrow;
	}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IAToken
 * @author Aave
 * @notice Defines the basic interface for an AToken.
 */
interface IAToken is IERC20 {
	/**
	 * @notice Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
	 * @return The address of the underlying asset
	 */
	function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.16;

/**
 * @title IPriceOracleGetter
 * @author Aave
 * @notice Interface for the Aave price oracle.
 */
interface IAaveOracle {
	/**
	 * @notice Returns the base currency address
	 * @dev Address 0x0 is reserved for USD as base currency.
	 * @return Returns the base currency address.
	 */
	function BASE_CURRENCY() external view returns (address);

	/**
	 * @notice Returns the base currency unit
	 * @dev 1 ether for ETH, 1e8 for USD.
	 * @return Returns the base currency unit.
	 */
	function BASE_CURRENCY_UNIT() external view returns (uint256);

	/**
	 * @notice Returns the asset price in the base currency
	 * @param asset The address of the asset
	 * @return The price of the asset
	 */
	function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.16;

import { DataTypes } from "../libraries/DataTypes.sol";

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 */
interface IPool {
	/// @dev address provider
	function ADDRESSES_PROVIDER() external view returns (address);

	/**
	 * @notice Mints an `amount` of aTokens to the `onBehalfOf`
	 * @param asset The address of the underlying asset to mint
	 * @param amount The amount to mint
	 * @param onBehalfOf The address that will receive the aTokens
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 */
	function mintUnbacked(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode
	) external;

	/**
	 * @notice Back the current unbacked underlying with `amount` and pay `fee`.
	 * @param asset The address of the underlying asset to back
	 * @param amount The amount to back
	 * @param fee The amount paid in fees
	 * @return The backed amount
	 */
	function backUnbacked(
		address asset,
		uint256 amount,
		uint256 fee
	) external returns (uint256);

	/**
	 * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
	 * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
	 * @param asset The address of the underlying asset to supply
	 * @param amount The amount to be supplied
	 * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
	 *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
	 *   is a different wallet
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 */
	function supply(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode
	) external;

	/**
	 * @notice Supply with transfer approval of asset to be supplied done via permit function
	 * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
	 * @param asset The address of the underlying asset to supply
	 * @param amount The amount to be supplied
	 * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
	 *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
	 *   is a different wallet
	 * @param deadline The deadline timestamp that the permit is valid
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 * @param permitV The V parameter of ERC712 permit sig
	 * @param permitR The R parameter of ERC712 permit sig
	 * @param permitS The S parameter of ERC712 permit sig
	 */
	function supplyWithPermit(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode,
		uint256 deadline,
		uint8 permitV,
		bytes32 permitR,
		bytes32 permitS
	) external;

	/**
	 * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
	 * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
	 * @param asset The address of the underlying asset to withdraw
	 * @param amount The underlying amount to be withdrawn
	 *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
	 * @param to The address that will receive the underlying, same as msg.sender if the user
	 *   wants to receive it on his own wallet, or a different address if the beneficiary is a
	 *   different wallet
	 * @return The final amount withdrawn
	 */
	function withdraw(
		address asset,
		uint256 amount,
		address to
	) external returns (uint256);

	/**
	 * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
	 * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
	 * corresponding debt token (StableDebtToken or VariableDebtToken)
	 * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
	 *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
	 * @param asset The address of the underlying asset to borrow
	 * @param amount The amount to be borrowed
	 * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
	 * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
	 * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
	 * if he has been given credit delegation allowance
	 */
	function borrow(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		uint16 referralCode,
		address onBehalfOf
	) external;

	/**
	 * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
	 * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
	 * @param asset The address of the borrowed underlying asset previously borrowed
	 * @param amount The amount to repay
	 * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
	 * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
	 * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
	 * user calling the function if he wants to reduce/remove his own debt, or the address of any other
	 * other borrower whose debt should be removed
	 * @return The final amount repaid
	 */
	function repay(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		address onBehalfOf
	) external returns (uint256);

	/**
	 * @notice Repay with transfer approval of asset to be repaid done via permit function
	 * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
	 * @param asset The address of the borrowed underlying asset previously borrowed
	 * @param amount The amount to repay
	 * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
	 * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
	 * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
	 * user calling the function if he wants to reduce/remove his own debt, or the address of any other
	 * other borrower whose debt should be removed
	 * @param deadline The deadline timestamp that the permit is valid
	 * @param permitV The V parameter of ERC712 permit sig
	 * @param permitR The R parameter of ERC712 permit sig
	 * @param permitS The S parameter of ERC712 permit sig
	 * @return The final amount repaid
	 */
	function repayWithPermit(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		address onBehalfOf,
		uint256 deadline,
		uint8 permitV,
		bytes32 permitR,
		bytes32 permitS
	) external returns (uint256);

	/**
	 * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
	 * equivalent debt tokens
	 * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
	 * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
	 * balance is not enough to cover the whole debt
	 * @param asset The address of the borrowed underlying asset previously borrowed
	 * @param amount The amount to repay
	 * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
	 * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
	 * @return The final amount repaid
	 */
	function repayWithATokens(
		address asset,
		uint256 amount,
		uint256 interestRateMode
	) external returns (uint256);

	/**
	 * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
	 * @param asset The address of the underlying asset borrowed
	 * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
	 */
	function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

	/**
	 * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
	 * - Users can be rebalanced if the following conditions are satisfied:
	 *     1. Usage ratio is above 95%
	 *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
	 *        much has been borrowed at a stable rate and suppliers are not earning enough
	 * @param asset The address of the underlying asset borrowed
	 * @param user The address of the user to be rebalanced
	 */
	function rebalanceStableBorrowRate(address asset, address user) external;

	/**
	 * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
	 * @param asset The address of the underlying asset supplied
	 * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
	 */
	function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

	/**
	 * @notice Returns the user account data across all the reserves
	 * @param user The address of the user
	 * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
	 * @return totalDebtBase The total debt of the user in the base currency used by the price feed
	 * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
	 * @return currentLiquidationThreshold The liquidation threshold of the user
	 * @return ltv The loan to value of The user
	 * @return healthFactor The current health factor of the user
	 */
	function getUserAccountData(address user)
		external
		view
		returns (
			uint256 totalCollateralBase,
			uint256 totalDebtBase,
			uint256 availableBorrowsBase,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		);

	/**
	 * @notice Returns the configuration of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The configuration of the reserve
	 */
	function getConfiguration(address asset)
		external
		view
		returns (DataTypes.ReserveConfigurationMap memory);

	/**
	 * @notice Returns the state and configuration of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The state and configuration data of the reserve
	 */
	function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.16;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 */
interface IPoolAddressesProvider {
	/**
	 * @notice Returns the address of the price oracle.
	 * @return The address of the PriceOracle
	 */
	function getPriceOracle() external view returns (address);

	/**
	 * @notice Returns the address of the price oracle sentinel.
	 * @return The address of the PriceOracleSentinel
	 */
	function getPriceOracleSentinel() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

library DataTypes {
	struct ReserveConfigurationMap {
		//bit 0-15: LTV
		//bit 16-31: Liq. threshold
		//bit 32-47: Liq. bonus
		//bit 48-55: Decimals
		//bit 56: reserve is active
		//bit 57: reserve is frozen
		//bit 58: borrowing is enabled
		//bit 59: stable rate borrowing enabled
		//bit 60: asset is paused
		//bit 61: borrowing in isolation mode is enabled
		//bit 62-63: reserved
		//bit 64-79: reserve factor
		//bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
		//bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
		//bit 152-167 liquidation protocol fee
		//bit 168-175 eMode category
		//bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
		//bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
		//bit 252-255 unused

		uint256 data;
	}

	struct ReserveData {
		//stores the reserve configuration
		ReserveConfigurationMap configuration;
		//the liquidity index. Expressed in ray
		uint128 liquidityIndex;
		//the current supply rate. Expressed in ray
		uint128 currentLiquidityRate;
		//variable borrow index. Expressed in ray
		uint128 variableBorrowIndex;
		//the current variable borrow rate. Expressed in ray
		uint128 currentVariableBorrowRate;
		//the current stable borrow rate. Expressed in ray
		uint128 currentStableBorrowRate;
		//timestamp of last update
		uint40 lastUpdateTimestamp;
		//the id of the reserve. Represents the position in the list of the active reserves
		uint16 id;
		//aToken address
		address aTokenAddress;
		//stableDebtToken address
		address stableDebtTokenAddress;
		//variableDebtToken address
		address variableDebtTokenAddress;
		//address of the interest rate strategy
		address interestRateStrategyAddress;
		//the current treasury balance, scaled
		uint128 accruedToTreasury;
		//the outstanding unbacked aTokens minted through the bridging feature
		uint128 unbacked;
		//the outstanding debt borrowed against this asset in isolation mode
		uint128 isolationModeTotalDebt;
	}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import { DataTypes } from "./DataTypes.sol";

/**
 * @title ReserveConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
	uint256 internal constant LTV_MASK =                       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
	uint256 internal constant LIQUIDATION_THRESHOLD_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
	uint256 internal constant LIQUIDATION_BONUS_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
	uint256 internal constant DECIMALS_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant ACTIVE_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant FROZEN_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant BORROWING_MASK =                 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant STABLE_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant PAUSED_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant SILOED_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant FLASHLOAN_ENABLED_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant RESERVE_FACTOR_MASK =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant BORROW_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant SUPPLY_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =  0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant EMODE_CATEGORY_MASK =            0xFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant UNBACKED_MINT_CAP_MASK =         0xFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant DEBT_CEILING_MASK =              0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

	/// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
	uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
	uint256 internal constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
	uint256 internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
	uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
	uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
	uint256 internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
	uint256 internal constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
	uint256 internal constant IS_PAUSED_START_BIT_POSITION = 60;
	uint256 internal constant BORROWABLE_IN_ISOLATION_START_BIT_POSITION = 61;
	uint256 internal constant SILOED_BORROWING_START_BIT_POSITION = 62;
	uint256 internal constant FLASHLOAN_ENABLED_START_BIT_POSITION = 63;
	uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;
	uint256 internal constant BORROW_CAP_START_BIT_POSITION = 80;
	uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;
	uint256 internal constant LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION = 152;
	uint256 internal constant EMODE_CATEGORY_START_BIT_POSITION = 168;
	uint256 internal constant UNBACKED_MINT_CAP_START_BIT_POSITION = 176;
	uint256 internal constant DEBT_CEILING_START_BIT_POSITION = 212;

	uint256 internal constant MAX_VALID_LTV = 65535;
	uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
	uint256 internal constant MAX_VALID_LIQUIDATION_BONUS = 65535;
	uint256 internal constant MAX_VALID_DECIMALS = 255;
	uint256 internal constant MAX_VALID_RESERVE_FACTOR = 65535;
	uint256 internal constant MAX_VALID_BORROW_CAP = 68719476735;
	uint256 internal constant MAX_VALID_SUPPLY_CAP = 68719476735;
	uint256 internal constant MAX_VALID_LIQUIDATION_PROTOCOL_FEE = 65535;
	uint256 internal constant MAX_VALID_EMODE_CATEGORY = 255;
	uint256 internal constant MAX_VALID_UNBACKED_MINT_CAP = 68719476735;
	uint256 internal constant MAX_VALID_DEBT_CEILING = 1099511627775;

	uint256 public constant DEBT_CEILING_DECIMALS = 2;
	uint16 public constant MAX_RESERVES_COUNT = 128;

	/**
	 * @notice Gets the Loan to Value of the reserve
	 * @param self The reserve configuration
	 * @return The loan to value
	 */
	function getLtv(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
		return self.data & ~LTV_MASK;
	}

	/**
	 * @notice Gets the liquidation threshold of the reserve
	 * @param self The reserve configuration
	 * @return The liquidation threshold
	 */
	function getLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self)
		internal
		pure
		returns (uint256)
	{
		return
			(self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
	}

	/**
	 * @notice Gets the liquidation bonus of the reserve
	 * @param self The reserve configuration
	 * @return The liquidation bonus
	 */
	function getLiquidationBonus(DataTypes.ReserveConfigurationMap memory self)
		internal
		pure
		returns (uint256)
	{
		return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
	}

	/**
	 * @notice Gets the decimals of the underlying asset of the reserve
	 * @param self The reserve configuration
	 * @return The decimals of the asset
	 */
	function getDecimals(DataTypes.ReserveConfigurationMap memory self)
		internal
		pure
		returns (uint256)
	{
		return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
	}

	/**
	 * @notice Gets the active state of the reserve
	 * @param self The reserve configuration
	 * @return The active state
	 */
	function getActive(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
		return (self.data & ~ACTIVE_MASK) != 0;
	}

	/**
	 * @notice Gets the frozen state of the reserve
	 * @param self The reserve configuration
	 * @return The frozen state
	 */
	function getFrozen(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
		return (self.data & ~FROZEN_MASK) != 0;
	}

	/**
	 * @notice Gets the paused state of the reserve
	 * @param self The reserve configuration
	 * @return The paused state
	 */
	function getPaused(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
		return (self.data & ~PAUSED_MASK) != 0;
	}

	/**
	 * @notice Gets the borrowable in isolation flag for the reserve.
	 * @dev If the returned flag is true, the asset is borrowable against isolated collateral. Assets borrowed with
	 * isolated collateral is accounted for in the isolated collateral's total debt exposure.
	 * @dev Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep
	 * consistency in the debt ceiling calculations.
	 * @param self The reserve configuration
	 * @return The borrowable in isolation flag
	 */
	function getBorrowableInIsolation(DataTypes.ReserveConfigurationMap memory self)
		internal
		pure
		returns (bool)
	{
		return (self.data & ~BORROWABLE_IN_ISOLATION_MASK) != 0;
	}

	/**
	 * @notice Gets the siloed borrowing flag for the reserve.
	 * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
	 * @param self The reserve configuration
	 * @return The siloed borrowing flag
	 */
	function getSiloedBorrowing(DataTypes.ReserveConfigurationMap memory self)
		internal
		pure
		returns (bool)
	{
		return (self.data & ~SILOED_BORROWING_MASK) != 0;
	}

	/**
	 * @notice Gets the borrowing state of the reserve
	 * @param self The reserve configuration
	 * @return The borrowing state
	 */
	function getBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self)
		internal
		pure
		returns (bool)
	{
		return (self.data & ~BORROWING_MASK) != 0;
	}

	/**
	 * @notice Gets the stable rate borrowing state of the reserve
	 * @param self The reserve configuration
	 * @return The stable rate borrowing state
	 */
	function getStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self)
		internal
		pure
		returns (bool)
	{
		return (self.data & ~STABLE_BORROWING_MASK) != 0;
	}

	/**
	 * @notice Gets the reserve factor of the reserve
	 * @param self The reserve configuration
	 * @return The reserve factor
	 */
	function getReserveFactor(DataTypes.ReserveConfigurationMap memory self)
		internal
		pure
		returns (uint256)
	{
		return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
	}

	/**
	 * @notice Gets the borrow cap of the reserve
	 * @param self The reserve configuration
	 * @return The borrow cap
	 */
	function getBorrowCap(DataTypes.ReserveConfigurationMap memory self)
		internal
		pure
		returns (uint256)
	{
		return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
	}

	/**
	 * @notice Gets the supply cap of the reserve
	 * @param self The reserve configuration
	 * @return The supply cap
	 */
	function getSupplyCap(DataTypes.ReserveConfigurationMap memory self)
		internal
		pure
		returns (uint256)
	{
		return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
	}

	/**
	 * @notice Gets the debt ceiling for the asset if the asset is in isolation mode
	 * @param self The reserve configuration
	 * @return The debt ceiling (0 = isolation mode disabled)
	 */
	function getDebtCeiling(DataTypes.ReserveConfigurationMap memory self)
		internal
		pure
		returns (uint256)
	{
		return (self.data & ~DEBT_CEILING_MASK) >> DEBT_CEILING_START_BIT_POSITION;
	}

	/**
	 * @dev Gets the liquidation protocol fee
	 * @param self The reserve configuration
	 * @return The liquidation protocol fee
	 */
	function getLiquidationProtocolFee(DataTypes.ReserveConfigurationMap memory self)
		internal
		pure
		returns (uint256)
	{
		return
			(self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) >>
			LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
	}

	/**
	 * @dev Gets the unbacked mint cap of the reserve
	 * @param self The reserve configuration
	 * @return The unbacked mint cap
	 */
	function getUnbackedMintCap(DataTypes.ReserveConfigurationMap memory self)
		internal
		pure
		returns (uint256)
	{
		return (self.data & ~UNBACKED_MINT_CAP_MASK) >> UNBACKED_MINT_CAP_START_BIT_POSITION;
	}

	/**
	 * @dev Gets the eMode asset category
	 * @param self The reserve configuration
	 * @return The eMode category for the asset
	 */
	function getEModeCategory(DataTypes.ReserveConfigurationMap memory self)
		internal
		pure
		returns (uint256)
	{
		return (self.data & ~EMODE_CATEGORY_MASK) >> EMODE_CATEGORY_START_BIT_POSITION;
	}

	/**
	 * @notice Gets the flashloanable flag for the reserve
	 * @param self The reserve configuration
	 * @return The flashloanable flag
	 */
	function getFlashLoanEnabled(DataTypes.ReserveConfigurationMap memory self)
		internal
		pure
		returns (bool)
	{
		return (self.data & ~FLASHLOAN_ENABLED_MASK) != 0;
	}

	/**
	 * @notice Gets the configuration flags of the reserve
	 * @param self The reserve configuration
	 * @return The state flag representing active
	 * @return The state flag representing frozen
	 * @return The state flag representing borrowing enabled
	 * @return The state flag representing stableRateBorrowing enabled
	 * @return The state flag representing paused
	 */
	function getFlags(DataTypes.ReserveConfigurationMap memory self)
		internal
		pure
		returns (
			bool,
			bool,
			bool,
			bool,
			bool
		)
	{
		uint256 dataLocal = self.data;

		return (
			(dataLocal & ~ACTIVE_MASK) != 0,
			(dataLocal & ~FROZEN_MASK) != 0,
			(dataLocal & ~BORROWING_MASK) != 0,
			(dataLocal & ~STABLE_BORROWING_MASK) != 0,
			(dataLocal & ~PAUSED_MASK) != 0
		);
	}

	/**
	 * @notice Gets the configuration parameters of the reserve from storage
	 * @param self The reserve configuration
	 * @return The state param representing ltv
	 * @return The state param representing liquidation threshold
	 * @return The state param representing liquidation bonus
	 * @return The state param representing reserve decimals
	 * @return The state param representing reserve factor
	 * @return The state param representing eMode category
	 */
	function getParams(DataTypes.ReserveConfigurationMap memory self)
		internal
		pure
		returns (
			uint256,
			uint256,
			uint256,
			uint256,
			uint256,
			uint256
		)
	{
		uint256 dataLocal = self.data;

		return (
			dataLocal & ~LTV_MASK,
			(dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
			(dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
			(dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
			(dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION,
			(dataLocal & ~EMODE_CATEGORY_MASK) >> EMODE_CATEGORY_START_BIT_POSITION
		);
	}

	/**
	 * @notice Gets the caps parameters of the reserve from storage
	 * @param self The reserve configuration
	 * @return The state param representing borrow cap
	 * @return The state param representing supply cap.
	 */
	function getCaps(DataTypes.ReserveConfigurationMap memory self)
		internal
		pure
		returns (uint256, uint256)
	{
		uint256 dataLocal = self.data;

		return (
			(dataLocal & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
			(dataLocal & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
		);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ISolidlyGauge } from "./interfaces/ISolidlyGauge.sol";
import { ISolidlyRouter } from "./interfaces/ISolidlyRouter.sol";

import { IUniswapV2Pair } from "../../../interfaces/uniswap/IUniswapV2Pair.sol";

import { IUniFarm, HarvestSwapParams } from "../../mixins/IUniFarm.sol";
import { IWETH } from "../../../interfaces/uniswap/IWETH.sol";

// import "hardhat/console.sol";

abstract contract SolidlyFarm is IUniFarm {
	using SafeERC20 for IERC20;

	ISolidlyGauge private _farm;
	ISolidlyRouter private _router;
	IERC20 private _farmToken;
	IUniswapV2Pair private _pair;
	uint256 private _farmId;

	constructor(
		address pair_,
		address farm_,
		address router_,
		address farmToken_,
		uint256 farmPid_
	) {
		_farm = ISolidlyGauge(farm_);
		_router = ISolidlyRouter(router_);
		_farmToken = IERC20(farmToken_);
		_pair = IUniswapV2Pair(pair_);
		_farmId = farmPid_;
		_addFarmApprovals();
	}

	// assumption that _router and _farm are trusted
	function _addFarmApprovals() internal override {
		IERC20(address(_pair)).safeIncreaseAllowance(address(_farm), type(uint256).max);
		if (_farmToken.allowance(address(this), address(_router)) == 0)
			_farmToken.safeIncreaseAllowance(address(_router), type(uint256).max);
	}

	function farmRouter() public view override returns (address) {
		return address(_router);
	}

	function pair() public view override returns (IUniswapV2Pair) {
		return _pair;
	}

	function _withdrawFromFarm(uint256 amount) internal override {
		_farm.withdraw(amount);
	}

	function _depositIntoFarm(uint256 amount) internal override {
		_farm.deposit(amount, 0);
	}

	function _harvestFarm(HarvestSwapParams[] calldata swapParams)
		internal
		override
		returns (uint256[] memory harvested)
	{
		address[] memory tokens = new address[](1);
		tokens[0] = address(_farmToken);
		_farm.getReward(address(this), tokens);
		uint256 farmHarvest = _farmToken.balanceOf(address(this));
		if (farmHarvest == 0) return harvested;

		_validatePath(address(_farmToken), swapParams[0].path);

		HarvestSwapParams memory swapParam = swapParams[0];
		uint256 l = swapParam.path.length;
		ISolidlyRouter.route[] memory routes = new ISolidlyRouter.route[](l - 1);
		for (uint256 i = 0; i < l - 1; i++) {
			routes[i] = (ISolidlyRouter.route(swapParam.path[i], swapParam.path[i + 1], false));
		}

		uint256[] memory amounts = _router.swapExactTokensForTokens(
			farmHarvest,
			swapParam.min,
			routes,
			address(this),
			block.timestamp
		);

		harvested = new uint256[](1);
		harvested[0] = amounts[amounts.length - 1];
		emit HarvestedToken(address(_farmToken), harvested[0]);
	}

	function _getFarmLp() internal view override returns (uint256) {
		uint256 lp = _farm.balanceOf(address(this));
		return lp;
	}

	function _getLiquidity(uint256 lpTokenBalance) internal view override returns (uint256) {
		uint256 farmLp = _getFarmLp();
		return farmLp + lpTokenBalance;
	}

	function _getLiquidity() internal view override returns (uint256) {
		uint256 farmLp = _getFarmLp();
		uint256 poolLp = _pair.balanceOf(address(this));
		return farmLp + poolLp;
	}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.16;

interface ISolidlyGauge {
	function notifyRewardAmount(address token, uint256 amount) external;

	function getReward(address account, address[] calldata tokens) external;

	function claimFees() external returns (uint256 claimed0, uint256 claimed1);

	function left(address token) external view returns (uint256);

	function isForPair() external view returns (bool);

	function earned(address token, address account) external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function deposit(uint256 amount, uint256 tokenId) external;

	function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.16;

interface ISolidlyRouter {
	struct route {
		address from;
		address to;
		bool stable;
	}

	function weth() external pure returns (address);

	function addLiquidity(
		address tokenA,
		address tokenB,
		bool stable,
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

	function swapExactTokensForTokensSimple(
		uint256 amountIn,
		uint256 amountOutMin,
		address tokenFrom,
		address tokenTo,
		bool stable,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		route[] calldata routes,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);
}