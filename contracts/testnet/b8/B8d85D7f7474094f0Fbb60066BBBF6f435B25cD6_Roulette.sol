// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
                        Strings.toHexString(uint160(account), 20),
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./LuckyStrikeRouter.sol";
import "../../interfaces/core/IVaultManager.sol";
import "../helpers/RandomizerConsumer.sol";
import "../helpers/Access.sol";
import "../helpers/Number.sol";

abstract contract Core is
  Pausable,
  Access,
  ReentrancyGuard,
  NumberHelper,
  RandomizerConsumer,
  LuckyStrikeRouter
{
  /*==================================================== Events ==========================================================*/

  event VaultManagerChange(address vaultManager);
  event LuckyStrikeMasterChange(address masterStrike);

  /*==================================================== Modifiers ==========================================================*/

  modifier isWagerAcceptable(address _token, uint256 _wager) {
    uint256 dollarValue_ = _computeDollarValue(_token, _wager);
    require(dollarValue_ >= vaultManager.getMinWager(address(this)), "GAME: Wager too low");
    require(dollarValue_ <= vaultManager.getMaxWager(), "GAME: Wager too high");
    _;
  }

  /// @notice used to calculate precise decimals
  uint256 public constant PRECISION = 1e18;
  /// @notice used to calculate Referral Rewards
  uint32 public constant BASIS_POINTS = 1e4;
  /// @notice Vault manager address
  IVaultManager public vaultManager;

  uint16 public constant ALPHA = 999; // 0.999

  int24 public constant SIGMA_1 = 100; // 0.1
  int24 public constant MEAN_1 = 600; // 0.6

  int24 public constant SIGMA_2 = 10000; // 10
  int24 public constant MEAN_2 = 100000; // 100

  mapping(address => uint256) private decimalsOfToken;

  constructor(IRandomizerRouter _router) RandomizerConsumer(_router) {}

  function setVaultManager(IVaultManager _vaultManager) external onlyGovernance {
    vaultManager = _vaultManager;

    emit VaultManagerChange(address(_vaultManager));
  }

  function setLuckyStrikeMaster(ILuckyStrikeMaster _masterStrike) external onlyGovernance {
    masterStrike = _masterStrike;

    emit LuckyStrikeMasterChange(address(_masterStrike));
  }

  function pause() external onlyTeam {
    _pause();
  }

  function unpause() external onlyTeam {
    _unpause();
  }

  /**
   * @notice internal function that checks in the player has won the lucky strike jackpot
   * @param _randomness random number from the randomizer / vrf
   * @param _player address of the player that has wagered
   * @param _token address of the token the player has wagered
   * @param _usedWager amount of the token the player has wagered
   */
  function _hasLuckyStrike(
    uint256 _randomness,
    address _player,
    address _token,
    uint256 _usedWager
  ) internal returns (bool hasWon_) {
    if (_hasLuckyStrikeCheck(_randomness, _computeDollarValue(_token, _usedWager))) {
      uint256 wonAmount_ = _processLuckyStrike(_player);
      emit LuckyStrike(_player, wonAmount_, true /** true */);
      return true;
    } else {
      emit LuckyStrike(_player, 0, false /** flase */);
      return false;
    }
  }

  /// @notice function to compute jackpot multiplier
  function _computeMultiplier(uint256 _random) internal pure returns (uint256) {
    int256 _sumOfRandoms = int256(_generateRandom(_random)) - 6000;
    _random = (_random % 1000) + 1;

    uint256 multiplier;
    unchecked {
      if (_random >= ALPHA) {
        multiplier = uint256((SIGMA_2 * _sumOfRandoms) / 1e3 + MEAN_2);
      } else {
        multiplier = uint256((SIGMA_1 * _sumOfRandoms) / 1e3 + MEAN_1);
      }
    }

    return _clamp(multiplier, 100, 100000);
  }

  function _clamp(uint256 value, uint256 min, uint256 max) internal pure returns (uint256) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// @param _random random number that comes from vrf
  /// @notice function to generate 12 random numbers and sum them up
  function _generateRandom(uint256 _random) internal pure returns (uint256 sumOfRandoms_) {
    unchecked {
      uint256 factor = 1;
      for (uint256 i = 0; i < 12; ++i) {
        sumOfRandoms_ += (_random / factor) % 1000;
        factor *= 1000;
      }
    }
    return sumOfRandoms_;
  }

  function _computeDollarValue(
    address _token,
    uint256 _wager
  ) internal returns (uint256 _wagerInDollar) {
    unchecked {
      _wagerInDollar = ((_wager * vaultManager.getPrice(_token))) / (10 ** _getDecimals(_token));
    }
  }

  function _getDecimals(address _token) internal returns (uint256) {
    uint256 decimals_ = decimalsOfToken[_token];
    if (decimals_ == 0) {
      decimalsOfToken[_token] = IERC20Metadata(_token).decimals();
      return decimalsOfToken[_token];
    } else {
      return decimals_;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../interfaces/core/ILuckyStrikeMaster.sol";

abstract contract LuckyStrikeRouter {
  event LuckyStrike(address indexed player, uint256 wonAmount, bool won);

  ILuckyStrikeMaster public masterStrike;

  function _hasLuckyStrikeCheck(
    uint256 _randomness,
    uint256 _usdWager
  ) internal view returns (bool hasWon_) {
    hasWon_ = masterStrike.hasLuckyStrike(_randomness, _usdWager);
  }

  function _processLuckyStrike(address _player) internal returns (uint256 wonAmount_) {
    wonAmount_ = masterStrike.processLuckyStrike(_player);
    // emit LuckyStrike(_player, wonAmount_, wonAmount_ > 0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract Access is AccessControl {
  /*==================================================== Modifiers ==========================================================*/

  modifier onlyGovernance() virtual {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ACC: Not governance");
    _;
  }

  modifier onlyTeam() virtual {
    require(hasRole(TEAM_ROLE, _msgSender()), "GAME: Not team");
    _;
  }

  /*==================================================== State Variables ====================================================*/

  bytes32 public constant TEAM_ROLE = bytes32(keccak256("TEAM"));

  /*==================================================== Functions ===========================================================*/

  constructor()  {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract NumberHelper {
  function modNumber(uint256 _number, uint32 _mod) internal pure returns (uint256) {
    return _mod > 0 ? _number % _mod : _number;
  }

  function modNumbers(uint256[] memory _numbers, uint32 _mod) internal pure returns (uint256[] memory) {
    uint256[] memory modNumbers_ = new uint[](_numbers.length);

    for (uint256 i = 0; i < _numbers.length; i++) {
      modNumbers_[i] = modNumber(_numbers[i], _mod);
    }

    return modNumbers_;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Access.sol";
import "../../interfaces/randomizer/providers/supra/ISupraRouter.sol";
import "../../interfaces/randomizer/IRandomizerRouter.sol";
import "../../interfaces/randomizer/IRandomizerConsumer.sol";
import "./Number.sol";

abstract contract RandomizerConsumer is Access, IRandomizerConsumer {
  /*==================================================== Modifiers ===========================================================*/

  modifier onlyRandomizer() {
    require(hasRole(RANDOMIZER_ROLE, _msgSender()), "RC: Not randomizer");
    _;
  }

  /*==================================================== State Variables ====================================================*/

  /// @notice minimum confirmation blocks
  uint256 public minConfirmations = 3;
  /// @notice router address
  IRandomizerRouter public randomizerRouter;
  /// @notice Randomizer ROLE as Bytes32
  bytes32 public constant RANDOMIZER_ROLE = bytes32(keccak256("RANDOMIZER"));

  /*==================================================== FUNCTIONS ===========================================================*/

  constructor(IRandomizerRouter _randomizerRouter) {
    changeRandomizerRouter(_randomizerRouter);
  }

  /*==================================================== Configuration Functions ====================================================*/

  function changeRandomizerRouter(IRandomizerRouter _randomizerRouter) public onlyGovernance {
    randomizerRouter = _randomizerRouter;
    grantRole(RANDOMIZER_ROLE, address(_randomizerRouter));
  }

  function setMinConfirmations(uint16 _minConfirmations) external onlyGovernance {
    minConfirmations = _minConfirmations;
  }

  /*==================================================== Randomizer Functions ====================================================*/

  function randomizerFulfill(uint256 _requestId, uint256[] calldata _rngList) internal virtual;

  function randomizerCallback(
    uint256 _requestId,
    uint256[] calldata _rngList
  ) external onlyRandomizer {
    randomizerFulfill(_requestId, _rngList);
  }

  function _requestRandom(uint8 _count) internal returns (uint256 requestId_) {
    requestId_ = randomizerRouter.request(_count, minConfirmations);
  }

  function _requestScheduledRandom(
    uint8 _count,
    uint256 targetTime
  ) internal returns (uint256 requestId_) {
    requestId_ = randomizerRouter.scheduledRequest(_count, targetTime);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../core/Core.sol";

contract Roulette is Core {
  /*==================================================== Events ==========================================================*/

  event UpdateHouseEdge(uint64 houseEdge);

  event ConfigurationUpdated(Configuration configuration);

  event Created(
    uint8[145] selections,
    uint8 count,
    address token,
    address indexed player,
    uint64 requestId,
    uint128 price
  );

  event Settled(
    address indexed player,
    uint64 requestId,
    uint256 wagerWithMultiplier,
    uint256 payout,
    uint256[] outcomes
  );

  /*==================================================== State Variables ====================================================*/

  struct Game {
    uint8[145] selections;
    uint8 count;
    address token;
    address player;
    uint64 startTime;
    uint128 totalWagerInToken;
    uint128 price;
  }

  struct Chunk {
    uint64 selector;
    uint64 multiplier;
  }

  struct Configuration {
    uint8 maxCount;
    uint64 minChip;
    uint64 maxChip;
  }

  /// @notice the number is used calculate singular selections
  uint8 public singleNumberMultiplier = 36;
  /// @notice chunk multipliers are used to get multiplier without making any calculation
  uint8[108] public chunkMultipliers;
  /// @notice chunk maps are used to easy access to selections which has included the number
  uint8[][37] public chunkMaps;
  /// @notice cooldown duration to refund
  uint32 public refundCooldown = 2 hours; // default value
  /// @notice house edge of game, used to calculate referrals share (200 = 2.00)
  uint64 public houseEdge = 200;
  /// @notice maxChip can be up to 256, even if the maxChip configured
  /// @notice the total wager also will be checked over max wager of the platform
  Configuration public configuration = Configuration(50, 1, 250);
  /// @notice stores all games
  mapping(uint64 => Game) public games;

  /*==================================================== Functions ===========================================================*/

  constructor(IRandomizerRouter _router) Core(_router) {
    // for 0,1,2
    chunkMultipliers[0] = 12;
    // for 0,2,3
    chunkMultipliers[1] = 12;
    // for 1,2,4,5
    chunkMultipliers[2] = 9;
    // for 2,3,5,6
    chunkMultipliers[3] = 9;
    // for 4,5,7,8
    chunkMultipliers[4] = 9;
    // for 5,6,8,9
    chunkMultipliers[5] = 9;
    // for 10,11,7,8
    chunkMultipliers[6] = 9;
    // for 11,12,8,9
    chunkMultipliers[7] = 9;
    // for 11,12,14,15
    chunkMultipliers[8] = 9;
    // for 10,11,13,14
    chunkMultipliers[9] = 9;
    // for 14,15,17,18
    chunkMultipliers[10] = 9;
    // for 13,14,16,17
    chunkMultipliers[11] = 9;
    // for 17,18,20,21
    chunkMultipliers[12] = 9;
    // for 16,17,19,20
    chunkMultipliers[13] = 9;
    // for 20,21,23,24
    chunkMultipliers[14] = 9;
    // for 19,20,22,23
    chunkMultipliers[15] = 9;
    // for 23,24,26,27
    chunkMultipliers[16] = 9;
    // for 22,23,25,26
    chunkMultipliers[17] = 9;
    // for 26,27,29,30
    chunkMultipliers[18] = 9;
    // for 25,26,28,29
    chunkMultipliers[19] = 9;
    // for 29,30,32,33
    chunkMultipliers[20] = 9;
    // for 28,29,31,32
    chunkMultipliers[21] = 9;
    // for 32,33,35,36
    chunkMultipliers[22] = 9;
    // for 31,32,34,35
    chunkMultipliers[23] = 9;
    // for 1,10,11,12,2,3,4,5,6,7,8,9
    chunkMultipliers[24] = 3;
    // for 13,14,15,16,17,18,19,20,21,22,23,24
    chunkMultipliers[25] = 3;
    // for 25,26,27,28,29,30,31,32,33,34,35,36
    chunkMultipliers[26] = 3;
    // for 1,10,11,12,13,14,15,16,17,18,2,3,4,5,6,7,8,9
    chunkMultipliers[27] = 2;
    // for 19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36
    chunkMultipliers[28] = 2;
    // for 10,12,14,16,18,2,20,22,24,26,28,30,32,34,36,4,6,8
    chunkMultipliers[29] = 2;
    // for 1,11,13,15,17,19,21,23,25,27,29,3,31,33,35,5,7,9
    chunkMultipliers[30] = 2;
    // for 1,12,14,16,18,19,21,23,25,27,3,30,32,34,36,5,7,9
    chunkMultipliers[31] = 2;
    // for 10,11,13,15,17,2,20,22,24,26,28,29,31,33,35,4,6,8
    chunkMultipliers[32] = 2;
    // for 12,15,18,21,24,27,3,30,33,36,6,9
    chunkMultipliers[33] = 3;
    // for 11,14,17,2,20,23,26,29,32,35,5,8
    chunkMultipliers[34] = 3;
    // for 1,10,13,16,19,22,25,28,31,34,4,7
    chunkMultipliers[35] = 3;
    // for 1,2,3
    chunkMultipliers[36] = 12;
    // for 4,5,6
    chunkMultipliers[37] = 12;
    // for 7,8,9
    chunkMultipliers[38] = 12;
    // for 10,11,12
    chunkMultipliers[39] = 12;
    // for 13,14,15
    chunkMultipliers[40] = 12;
    // for 16,17,18
    chunkMultipliers[41] = 12;
    // for 19,20,21
    chunkMultipliers[42] = 12;
    // for 22,23,24
    chunkMultipliers[43] = 12;
    // for 25,26,27
    chunkMultipliers[44] = 12;
    // for 28,29,30
    chunkMultipliers[45] = 12;
    // for 31,32,33
    chunkMultipliers[46] = 12;
    // for 34,35,36
    chunkMultipliers[47] = 12;
    // for 0,1
    chunkMultipliers[48] = 18;
    // for 0,2
    chunkMultipliers[49] = 18;
    // for 0,3
    chunkMultipliers[50] = 18;
    // for 1,2
    chunkMultipliers[51] = 18;
    // for 1,4
    chunkMultipliers[52] = 18;
    // for 2,3
    chunkMultipliers[53] = 18;
    // for 2,5
    chunkMultipliers[54] = 18;
    // for 3,6
    chunkMultipliers[55] = 18;
    // for 4,5
    chunkMultipliers[56] = 18;
    // for 4,7
    chunkMultipliers[57] = 18;
    // for 5,6
    chunkMultipliers[58] = 18;
    // for 5,8
    chunkMultipliers[59] = 18;
    // for 6,9
    chunkMultipliers[60] = 18;
    // for 7,8
    chunkMultipliers[61] = 18;
    // for 7,10
    chunkMultipliers[62] = 18;
    // for 8,9
    chunkMultipliers[63] = 18;
    // for 8,11
    chunkMultipliers[64] = 18;
    // for 9,12
    chunkMultipliers[65] = 18;
    // for 10,11
    chunkMultipliers[66] = 18;
    // for 10,13
    chunkMultipliers[67] = 18;
    // for 11,12
    chunkMultipliers[68] = 18;
    // for 11,14
    chunkMultipliers[69] = 18;
    // for 12,15
    chunkMultipliers[70] = 18;
    // for 13,14
    chunkMultipliers[71] = 18;
    // for 13,16
    chunkMultipliers[72] = 18;
    // for 14,15
    chunkMultipliers[73] = 18;
    // for 14,17
    chunkMultipliers[74] = 18;
    // for 15,18
    chunkMultipliers[75] = 18;
    // for 16,17
    chunkMultipliers[76] = 18;
    // for 16,19
    chunkMultipliers[77] = 18;
    // for 17,18
    chunkMultipliers[78] = 18;
    // for 17,20
    chunkMultipliers[79] = 18;
    // for 18,21
    chunkMultipliers[80] = 18;
    // for 19,20
    chunkMultipliers[81] = 18;
    // for 19,22
    chunkMultipliers[82] = 18;
    // for 20,21
    chunkMultipliers[83] = 18;
    // for 20,23
    chunkMultipliers[84] = 18;
    // for 21,24
    chunkMultipliers[85] = 18;
    // for 22,23
    chunkMultipliers[86] = 18;
    // for 22,25
    chunkMultipliers[87] = 18;
    // for 23,24
    chunkMultipliers[88] = 18;
    // for 23,26
    chunkMultipliers[89] = 18;
    // for 24,27
    chunkMultipliers[90] = 18;
    // for 25,26
    chunkMultipliers[91] = 18;
    // for 25,28
    chunkMultipliers[92] = 18;
    // for 26,27
    chunkMultipliers[93] = 18;
    // for 26,29
    chunkMultipliers[94] = 18;
    // for 27,30
    chunkMultipliers[95] = 18;
    // for 28,29
    chunkMultipliers[96] = 18;
    // for 28,31
    chunkMultipliers[97] = 18;
    // for 29,30
    chunkMultipliers[98] = 18;
    // for 29,32
    chunkMultipliers[99] = 18;
    // for 30,33
    chunkMultipliers[100] = 18;
    // for 31,32
    chunkMultipliers[101] = 18;
    // for 31,34
    chunkMultipliers[102] = 18;
    // for 32,33
    chunkMultipliers[103] = 18;
    // for 32,35
    chunkMultipliers[104] = 18;
    // for 33,36
    chunkMultipliers[105] = 18;
    // for 34,35
    chunkMultipliers[106] = 18;
    // for 35,36
    chunkMultipliers[107] = 18;
    // for 0
    chunkMaps[0] = [0, 1, 48, 49, 50];
    // for 1
    chunkMaps[1] = [0, 2, 24, 27, 30, 31, 35, 36, 48, 51, 52];
    // for 2
    chunkMaps[2] = [0, 1, 2, 3, 24, 27, 29, 32, 34, 36, 49, 51, 53, 54];
    // for 3
    chunkMaps[3] = [1, 3, 24, 27, 30, 31, 33, 36, 50, 53, 55];
    // for 4
    chunkMaps[4] = [2, 4, 24, 27, 29, 32, 35, 37, 52, 56, 57];
    // for 5
    chunkMaps[5] = [2, 3, 4, 5, 24, 27, 30, 31, 34, 37, 54, 56, 58, 59];
    // for 6
    chunkMaps[6] = [3, 5, 24, 27, 29, 32, 33, 37, 55, 58, 60];
    // for 7
    chunkMaps[7] = [4, 6, 24, 27, 30, 31, 35, 38, 57, 61, 62];
    // for 8
    chunkMaps[8] = [4, 5, 6, 7, 24, 27, 29, 32, 34, 38, 59, 61, 63, 64];
    // for 9
    chunkMaps[9] = [5, 7, 24, 27, 30, 31, 33, 38, 60, 63, 65];
    // for 10
    chunkMaps[10] = [6, 9, 24, 27, 29, 32, 35, 39, 62, 66, 67];
    // for 11
    chunkMaps[11] = [6, 7, 8, 9, 24, 27, 30, 32, 34, 39, 64, 66, 68, 69];
    // for 12
    chunkMaps[12] = [7, 8, 24, 27, 29, 31, 33, 39, 65, 68, 70];
    // for 13
    chunkMaps[13] = [9, 11, 25, 27, 30, 32, 35, 40, 67, 71, 72];
    // for 14
    chunkMaps[14] = [8, 9, 10, 11, 25, 27, 29, 31, 34, 40, 69, 71, 73, 74];
    // for 15
    chunkMaps[15] = [8, 10, 25, 27, 30, 32, 33, 40, 70, 73, 75];
    // for 16
    chunkMaps[16] = [11, 13, 25, 27, 29, 31, 35, 41, 72, 76, 77];
    // for 17
    chunkMaps[17] = [10, 11, 12, 13, 25, 27, 30, 32, 34, 41, 74, 76, 78, 79];
    // for 18
    chunkMaps[18] = [10, 12, 25, 27, 29, 31, 33, 41, 75, 78, 80];
    // for 19
    chunkMaps[19] = [13, 15, 25, 28, 30, 31, 35, 42, 77, 81, 82];
    // for 20
    chunkMaps[20] = [12, 13, 14, 15, 25, 28, 29, 32, 34, 42, 79, 81, 83, 84];
    // for 21
    chunkMaps[21] = [12, 14, 25, 28, 30, 31, 33, 42, 80, 83, 85];
    // for 22
    chunkMaps[22] = [15, 17, 25, 28, 29, 32, 35, 43, 82, 86, 87];
    // for 23
    chunkMaps[23] = [14, 15, 16, 17, 25, 28, 30, 31, 34, 43, 84, 86, 88, 89];
    // for 24
    chunkMaps[24] = [14, 16, 25, 28, 29, 32, 33, 43, 85, 88, 90];
    // for 25
    chunkMaps[25] = [17, 19, 26, 28, 30, 31, 35, 44, 87, 91, 92];
    // for 26
    chunkMaps[26] = [16, 17, 18, 19, 26, 28, 29, 32, 34, 44, 89, 91, 93, 94];
    // for 27
    chunkMaps[27] = [16, 18, 26, 28, 30, 31, 33, 44, 90, 93, 95];
    // for 28
    chunkMaps[28] = [19, 21, 26, 28, 29, 32, 35, 45, 92, 96, 97];
    // for 29
    chunkMaps[29] = [18, 19, 20, 21, 26, 28, 30, 32, 34, 45, 94, 96, 98, 99];
    // for 30
    chunkMaps[30] = [18, 20, 26, 28, 29, 31, 33, 45, 95, 98, 100];
    // for 31
    chunkMaps[31] = [21, 23, 26, 28, 30, 32, 35, 46, 97, 101, 102];
    // for 32
    chunkMaps[32] = [20, 21, 22, 23, 26, 28, 29, 31, 34, 46, 99, 101, 103, 104];
    // for 33
    chunkMaps[33] = [20, 22, 26, 28, 30, 32, 33, 46, 100, 103, 105];
    // for 34
    chunkMaps[34] = [23, 26, 28, 29, 31, 35, 47, 102, 106];
    // for 35
    chunkMaps[35] = [22, 23, 26, 28, 30, 32, 34, 47, 104, 106, 107];
    // for 36
    chunkMaps[36] = [22, 26, 28, 29, 31, 33, 47, 105, 107];
  }

  /// @notice the number is used to calculate referrals share
  /// @param _houseEdge winning multipliplier
  function updateHouseEdge(uint64 _houseEdge) external onlyGovernance {
    require(_houseEdge >= 0, "_houseEdge should be greater than or equal to 0");

    houseEdge = _houseEdge;

    emit UpdateHouseEdge(_houseEdge);
  }

  /// @notice updates configuration
  /// @param _configuration because the selections array uint8 max chip could be maximum 256
  function updateConfiguration(Configuration calldata _configuration) external onlyGovernance {
    require(_configuration.maxChip <= 2 ** 8, "maxChip can't be greater");
    require(_configuration.maxChip > 0, "maxChip can't be zero");
    require(_configuration.minChip > 0, "minChip can't be zero");
    require(_configuration.maxCount > 0, "maxCount can't be zero");

    configuration = _configuration;

    emit ConfigurationUpdated(_configuration);
  }

  /// @notice chunk maps are used to easy access to selections which has included the number
  /// @param _index chunk index
  /// @param _map the edges number array for 1 [0,2,24,27,30,31,35]
  function setChunkMaps(uint8 _index, uint8[] calldata _map) external onlyGovernance {
    chunkMaps[_index] = _map;
  }

  /// @notice gets chunk array
  /// @param _index winning multipliplier
  function getChunkMap(uint8 _index) external view returns (uint8[] memory) {
    return chunkMaps[_index];
  }

  /// @notice chunk multipliers are used to get multiplier without making any calculation
  /// @param _index chunk index
  /// @param _multiplier multiplier with no decimals
  function setChunkMultiplier(uint8 _index, uint8 _multiplier) external onlyGovernance {
    chunkMultipliers[_index] = _multiplier;
  }

  /// @notice function that calculation or return a constant of house edge
  /// @return edge_ calculated house edge of game
  function getHouseEdge() public view returns (uint64 edge_) {
    edge_ = houseEdge;
  }

  /// @notice function to update refund block count
  /// @param _refundCooldown duration to refund
  function updateRefundCooldown(uint32 _refundCooldown) external onlyRole(DEFAULT_ADMIN_ROLE) {
    refundCooldown = _refundCooldown;
  }

  /// @notice function to refund uncompleted game wagers
  function refundGame(uint64 _requestId) external nonReentrant {
    Game memory game_ = games[_requestId];
    require(game_.player == _msgSender(), "Only player");

    _refundGame(_requestId, game_);
  }

  /// @notice function to refund uncompleted game wagers by team role
  function refundGameByTeam(uint64 _requestId) external nonReentrant onlyTeam {
    Game memory game_ = games[_requestId];
    require(game_.player != address(0), "Game is not created");

    _refundGame(_requestId, game_);
  }

  function _refundGame(uint64 _requestId, Game memory _game) internal {
    require(_game.startTime + refundCooldown < block.timestamp, "Game is not refundable yet");

    vaultManager.refund(_game.token, _game.totalWagerInToken, 0, _game.player);

    delete games[_requestId];
  }

  /// @notice calculates the chips value in token with its decimals
  /// @param _chips amount of chips
  /// @param _token to get decimals
  /// @param _price tokens price which fetched at first tx
  function chip2Token(
    uint256 _chips,
    address _token,
    uint256 _price
  ) public view returns (uint256) {
    return ((_chips * (10 ** (30 + IERC20Metadata(_token).decimals())))) / _price;
  }

  /// @notice randomizer consumer triggers that function
  /// @notice manages the game variables and shares the escrowed amount
  /// @param _requestId generated request id by randomizer
  /// @param _randoms raw random numbers sent by randomizers
  function randomizerFulfill(
    uint256 _requestId,
    uint256[] calldata _randoms
  ) internal override nonReentrant {
    // uint64 requestId_ = uint64(_requestId);
    Game memory game_ = games[uint64(_requestId)];

    require(game_.player != address(0), "Game is not created");

    // uint8 multiplier_ = singleNumberMultiplier;
    uint8 chunkId_;
    uint8 outcome_;
    uint8 wager_;
    uint8[] memory chunkMaps_;
    uint8[108] memory chunkMultipliers_ = chunkMultipliers;
    uint32 payout_;

    unchecked {
      for (uint8 i = 0; i < game_.count; ++i) {
        // to get outcome modded 37 because the game has 37 numbers included 0
        outcome_ = uint8(_randoms[i] % 37);

        // if player directly wagered to the outcome gives the winning over it
        if (game_.selections[outcome_] > 0) {
          payout_ += uint32(game_.selections[outcome_]) * singleNumberMultiplier;
        }

        // than checks if the edges which includes the outcome has wagered
        chunkMaps_ = chunkMaps[outcome_];
        for (uint8 x = 0; x < chunkMaps_.length; ++x) {
          chunkId_ = chunkMaps_[x];
          wager_ = game_.selections[37 + chunkId_];

          // if has gives adds the winning to payout
          if (wager_ > 0) {
            payout_ += uint32(wager_) * chunkMultipliers_[chunkId_];
          }
        }
      }
    }

    uint256 totalPayoutInToken_;

    /// @notice sets referral reward if player has referee
    vaultManager.setReferralReward(
      game_.token,
      game_.player,
      game_.totalWagerInToken,
      getHouseEdge()
    );

    uint256 wagerWithMultiplier_ = (_computeMultiplier(_randoms[0]) * game_.totalWagerInToken) /
      1e3;
    vaultManager.mintVestedWINR(game_.token, wagerWithMultiplier_, game_.player);

    _hasLuckyStrike(_randoms[0], game_.player, game_.token, game_.totalWagerInToken);

    /// @notice calculates the loss of user if its not zero transfers to Vault
    if (payout_ == 0) {
      vaultManager.payin(game_.token, game_.totalWagerInToken);
    } else {
      totalPayoutInToken_ = chip2Token(payout_, game_.token, game_.price);
      vaultManager.payout(game_.token, game_.player, game_.totalWagerInToken, totalPayoutInToken_);
    }

    emit Settled(
      game_.player,
      uint64(_requestId),
      wagerWithMultiplier_,
      totalPayoutInToken_,
      _randoms
    );

    delete games[uint64(_requestId)];
  }

  /// @notice starts the game and triggers randomizer
  /// @param _selections player's selections array [3] => max 256 means for 3rd number 256 wager
  /// @param _count multiple game count
  /// @param _token input and output token
  function bet(
    uint8[145] calldata _selections,
    uint8 _count,
    address _token
  ) external whenNotPaused nonReentrant {
    Configuration memory configuration_ = configuration;

    require(_count > 0 && _count <= configuration_.maxCount, "GAME: Count is invalid!");

    uint8 wager_;
    uint16 totalWager_;
    address player_ = _msgSender();
    uint64 requestId_ = uint64(_requestRandom(_count));
    uint128 price_ = uint128(vaultManager.getPrice(_token)); // gets price and keep it in object to make calculation

    unchecked {
      for (uint8 i = 0; i < 145; ++i) {
        wager_ = _selections[i];

        if (wager_ > 0) {
          require(wager_ >= configuration_.minChip, "GAME: Wager too low");
          require(wager_ <= configuration_.maxChip, "GAME: Wager too high");

          totalWager_ += wager_;
        }
      }
    }

    require(totalWager_ > 0, "At least 1 number should be selected");
    // Total wager should not be greater than platform's max wager
    require(totalWager_ <= vaultManager.getMaxWager() / 10 ** 30, "GAME: Wager too high");

    uint256 value_ = _count * chip2Token(totalWager_, _token, price_);
    require(value_ <= type(uint128).max, "GAME: value is too high");

    uint128 totalWagerInToken_ = uint128(value_);

    /// @notice escrows total wager to Vault Manager
    vaultManager.escrow(_token, player_, totalWagerInToken_);

    // Creating game object
    games[requestId_] = Game(
      _selections,
      _count,
      _token,
      player_,
      uint64(block.timestamp),
      totalWagerInToken_,
      price_
    );

    emit Created(_selections, _count, _token, player_, requestId_, price_);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILuckyStrikeMaster {
  event LuckyStrikePayout(address indexed player, uint256 wonAmount);
  event DeleteTokenFromWhitelist(address indexed token);
  event TokenAddedToWhitelist(address indexed token);
  event SyncTokens();
  event GameRemoved(address indexed game);
  event GameAdded(address indexed game);
  event DeleteAllWhitelistedTokens();
  event LuckyStrike(address indexed player, uint256 wonAmount, bool won);
  event WithdrawByGovernance(address indexed token, uint256 amount);

  function withdrawTokenByGovernance(address _token, uint256 _amount) external;

  function hasLuckyStrike(
    uint256 _randomness,
    uint256 _wagerUSD
  ) external view returns (bool hasWon_);

  function valueOfLuckyStrikeJackpot() external view returns (uint256 valueTotal_);

  function processLuckyStrike(address _player) external returns (uint256 wonAmount_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "../../interfaces/vault/IFeeCollector.sol"; // unnecessary import
import "../../interfaces/vault/IVault.sol";

/// @dev This contract designed to easing token transfers broadcasting information between contracts
interface IVaultManager {
  function vault() external view returns (IVault);

  function wlp() external view returns (IERC20);
  function BASIS_POINTS() external view returns (uint32);

  // function feeCollector() external view returns (IFeeCollector); // unnecessary

  function getMaxWager() external view returns (uint256);

  function getMinWager(address _game) external view returns (uint256);

  function getWhitelistedTokens() external view returns (address[] memory whitelistedTokenList_);

  function refund(address _token, uint256 _amount, uint256 _vWINRAmount, address _player) external;

  /// @notice escrow tokens into the manager
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _sender holder of tokens
  /// @param _amount the amount of token
  function escrow(address _token, address _sender, uint256 _amount) external;

  /// @notice function that assign reward of referral
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _player holder of tokens
  /// @param _amount the amount of token
  /// @param _houseEdge edge percent of game eg. 1000 = 10.00
  function setReferralReward(
    address _token,
    address _player,
    uint256 _amount,
    uint64 _houseEdge
  ) external returns (uint256 referralReward_);

  /// @notice function that remove reward of referral
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _player holder of tokens
  /// @param _amount the amount of token
  function removeReferralReward(address _token, address _player, uint256 _amount, uint64 _houseEdge) external;

  /// @notice release some amount of escrowed tokens
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _recipient holder of tokens
  /// @param _amount the amount of token
  function payback(address _token, address _recipient, uint256 _amount) external;

  /// @notice lets vault get wager amount from escrowed tokens
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _amount the amount of token
  function getEscrowedTokens(address _token, uint256 _amount) external;

  /// @notice lets vault get wager amount from escrowed tokens
  function payout(
    address _token,
    address _recipient,
    uint256 _escrowAmount,
    uint256 _totalAmount
  ) external;

  /// @notice lets vault get wager amount from escrowed tokens
  function payin(address _token, uint256 _escrowAmount) external;

  /// @notice transfers any whitelisted token into here
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _sender holder of tokens
  /// @param _amount the amount of token
  function transferIn(address _token, address _sender, uint256 _amount) external;

  /// @notice transfers any whitelisted token to recipient
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _recipient of tokens
  /// @param _amount the amount of token
  function transferOut(address _token, address _recipient, uint256 _amount) external;

  /// @notice used to mint vWINR to recipient
  /// @param _input currency of payment
  /// @param _amount of wager
  /// @param _recipient recipient of vWINR
  function mintVestedWINR(
    address _input,
    uint256 _amount,
    address _recipient
  ) external returns (uint256 vWINRAmount_);

  /// @notice used to transfer player's token to WLP
  /// @param _input currency of payment
  /// @param _amount convert token amount
  /// @param _sender sender of token
  /// @param _recipient recipient of WLP
  function deposit(
    address _input,
    uint256 _amount,
    address _sender,
    address _recipient
  ) external returns (uint256);

  function getPrice(address _token) external view returns (uint256 _price);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRandomizerConsumer {
  function randomizerCallback(uint256 _requestId, uint256[] calldata _rngList) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRandomizerRouter {
  function request(uint32 count, uint256 _minConfirmations) external returns (uint256);
  function scheduledRequest(uint32 _count, uint256 targetTime) external returns (uint256);
  function response(uint256 _requestId, uint256[] calldata _rngList) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5 <0.9.0;

interface ISupraRouter { 
	function generateRequest(string memory _functionSig, uint8 _rngCount, uint256 _numConfirmations, address _clientWalletAddress) external returns(uint256);
    function generateRequest(string memory _functionSig, uint8 _rngCount, uint256 _numConfirmations, uint256 _clientSeed, address _clientWalletAddress) external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVault {
  function getReserve() external view returns (uint256);

  function getWlpValue() external view returns (uint256);

  function getMinPrice(address _token) external view returns (uint256);

  function payout(
    address _wagerAsset,
    address _escrowAddress,
    uint256 _escrowAmount,
    address _recipient,
    uint256 _totalAmount
  ) external;

  function payoutNoEscrow(address _wagerAsset, address _recipient, uint256 _totalAmount) external;

  function payin(address _inputToken, address _escrowAddress, uint256 _escrowAmount) external;

  function payinWagerFee(address _tokenIn) external;

  function deposit(address _token, address _receiver) external returns (uint256);

  function withdraw(address _token, address _receiver) external;

  function wagerFeeReserves(address _token) external view returns (uint256);

  function allWhitelistedTokensLength() external view returns (uint256);

  function allWhitelistedTokens(uint256) external view returns (address);

  function payinPoolProfits(address _tokenIn) external;

  function tokenToUsdMin(
    address _tokenToPrice,
    uint256 _tokenAmount
  ) external view returns (uint256);

  function setVaultManagerAddress(
		address _vaultManagerAddress,
		bool _setting
	) external;
}