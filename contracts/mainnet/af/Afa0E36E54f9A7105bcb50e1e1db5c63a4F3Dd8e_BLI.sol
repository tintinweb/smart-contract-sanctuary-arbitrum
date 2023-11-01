// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

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
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "./IAccessControl.sol";
import {Context} from "../utils/Context.sol";
import {ERC165} from "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    mapping(bytes32 role => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
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
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
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
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
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
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` to `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
        if (hasRole(role, account)) {
            _roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
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
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

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
    constructor(address initialOwner) {
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
        return _owner;
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
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

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
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
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
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
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
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT

/*

Twitter: https://twitter.com/Blight_Project
Discord: https://t.co/b7lSl05bQD

*/

pragma solidity >=0.5.0;

interface ICamelotFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function owner() external view returns (address);

    function feePercentOwner() external view returns (address);

    function setStableOwner() external view returns (address);

    function feeTo() external view returns (address);

    function ownerFeeShare() external view returns (uint256);

    function referrersFeeShare(address) external view returns (uint256);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function feeInfo()
        external
        view
        returns (uint _ownerFeeShare, address _feeTo);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);
}

interface ICamelotRouter is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;
}

pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
    error OnlyCoordinatorCanFulfill(address have, address want);
    address private immutable vrfCoordinator;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     */
    constructor(address _vrfCoordinator) {
        vrfCoordinator = _vrfCoordinator;
    }

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomWords the VRF output expanded to the requested number of words
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual;

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Vault.sol";

contract BLI is IERC20, Ownable, VRFConsumerBaseV2, AccessControl {
    string private _name = "Blight Project";
    string private _symbol = "BLI";
    uint8 constant _decimals = 18;
    uint256 private _totalSupply = 1_000_000_000 * 10 ** _decimals;
    uint256 internal _decimalHelper = 1e24;

    uint256 private _maxWalletSize = (_totalSupply * 10) / 1000; // 1%

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isWalletLimitExempt;

    // Buy fees
    uint256 private BaseFeeBuy = 600 * _decimalHelper;
    uint256 private unitFeeBuy = 200;

    // Sell fees
    uint256 private BaseFeeSell = 900 * _decimalHelper;
    uint256 private unitFeeSell = 300;

    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address public MarketingWallet = 0x669cfD3Fa549317F4B328DCd08e3289427431D74;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address private _vrfCoordinator =
        0x41034678D6C633D8a95c75e1138A360a28bA15d1;
    VRFCoordinatorV2Interface COORDINATOR =
        VRFCoordinatorV2Interface(_vrfCoordinator);

    // Subscription ID.
    uint64 s_subscriptionId = 119;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // mid key hash - to save gas
    bytes32 keyHash =
        0x72d2b016bb5b62912afea355ebf33b91319f828738b111b723b78696b9847b63;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) internal s_requests;

    ICamelotRouter public router;
    address public pair;

    bool public isTradingEnabled = false;
    bool public swapEnabled = false;
    uint256 private swapThreshold = (_totalSupply / 1000) * 3; // 0.3%

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    mapping(address => bool) public infected;
    mapping(address => address) public infecter;
    mapping(address => uint256) public totalRewards;
    mapping(address => uint256) public pendingRewards;
    mapping(address => uint256) public amountOfInfection;

    // Vault of Blight
    Vault public vault;

    // Epoch struct
    struct Epoch {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) isBuyer; // getter
        mapping(address => bool) hasUpgrade; // getter
        mapping(address => bool) hasOpenedCapsule; // getter
        mapping(uint256 => address) requestIdToAddy;
        mapping(address => uint256) addyToRequestId;
        mapping(address => bool) requestFullfilled; // getter
        address[] gotLuckyVaccine; // getter
    }

    // Probability max range
    uint256 internal _probabilityMaxRange = 100;

    // Store users vaccines through epochs
    mapping(address => uint256) public userCurrentVaccine;

    // Store list of users who bought a vaccine in any epoch
    mapping(address => bool) public userHasBoughtVaccine;
    address[] internal userVaccineList;

    // Epoch id
    uint256 public epochId = 0;

    // Epochs mapping
    mapping(uint256 => Epoch) public epochs;

    // Capsule sold count for current round (resets every epoch)
    uint256 public capsuleCurrentCount = 0;

    // Capsule sold count
    uint256 public capsuleCount = 0;

    // Capsule price
    uint256 public capsulePrice = 250_000 ether; // 0.025% of total supply

    // Vaccine count for current round (resets every epoch)
    uint256 private vaccineOneCurrentCount = 0;
    uint256 private vaccineTwoCurrentCount = 0;
    uint256 private vaccineThreeCurrentCount = 0;
    uint256 private vaccineFourCurrentCount = 0;

    // Vaccine sold count
    uint256 private vaccineOneCount = 0;
    uint256 private vaccineTwoCount = 0;
    uint256 private vaccineThreeCount = 0;
    uint256 private vaccineFourCount = 0;

    // Lucky vaccine supply
    uint256 public vaccineFourSupply = 10;

    // Vaccines reductions fees on buys
    uint256 internal vaccineOneProtectionDevBuy;
    uint256 internal vaccineTwoProtectionDevBuy;
    uint256 internal vaccineThreeProtectionDevBuy;

    // Vaccines reductions fees on sells
    uint256 internal vaccineOneProtectionDevSell;
    uint256 internal vaccineTwoProtectionDevSell;
    uint256 internal vaccineThreeProtectionDevSell;

    // Reduction rate for vaccines on buys
    uint256 internal vaccineOneReductionRateBuy = 229 * _decimalHelper; // Tier 1 vaccine aka the less effective
    uint256 internal vaccineTwoReductionRateBuy = 357 * _decimalHelper;
    uint256 internal vaccineThreeReductionRateBuy = 514 * _decimalHelper; // Tier 3 vaccine aka the most effective

    // Reduction rate for vaccines on sells
    uint256 internal vaccineOneReductionRateSell = 700 * _decimalHelper; // Tier 1 vaccine aka the less effective
    uint256 internal vaccineTwoReductionRateSell = 914 * _decimalHelper;
    uint256 internal vaccineThreeReductionRateSell = 1157 * _decimalHelper; // Tier 3 vaccine aka the most effective

    // Handle game start and end
    bool public isGameStarted = false;
    bool public isGameOver = false;

    uint256 currentPendingRewards;

    uint256 public totalAllRewards;
    uint256 public amountOfAllInfection;

    address[5] bestInfectors;

    uint256 launchTime;
    bool private initialized;

    event _claim(address indexed user, uint256 amount);
    event CapsuleBought(address indexed user, uint256 id);
    event CapsuleOpened(address indexed user, uint256 vaccine, bool vaccine4);
    event NewEpochStarted(uint256 epochId);
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    constructor(
        address initialOwner
    ) VRFConsumerBaseV2(_vrfCoordinator) Ownable(initialOwner) {
        router = ICamelotRouter(0xc873fEcbd354f5A56E00E710B90EF4201db2448d); // Camelot Arbitrum One

        _allowances[address(this)][address(router)] = type(uint256).max;

        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(ADMIN_ROLE, initialOwner);

        vault = new Vault(address(this), initialOwner);

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[MarketingWallet] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[MarketingWallet] = true;
        isWalletLimitExempt[DEAD] = true;
        isWalletLimitExempt[address(vault)] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[pair] = true;
        isWalletLimitExempt[0xc873fEcbd354f5A56E00E710B90EF4201db2448d] = true;

        infected[msg.sender] = true;
        infected[MarketingWallet] = true;
        infected[DEAD] = true;
        infected[address(this)] = true;
        infected[pair] = true;
        infected[0xc873fEcbd354f5A56E00E710B90EF4201db2448d] = true;

        _balances[msg.sender] += _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function initializePair() external onlyOwner {
        require(!initialized, "Already initialized");
        pair = ICamelotFactory(0x6EcCab422D763aC031210895C81787E87B43A652)
            .createPair(
                0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
                address(this)
            );
        initialized = true;
    }

    function _upgradeVaccineProtection() internal {
        // Upgrade buy fees
        vaccineOneProtectionDevBuy =
            (BaseFeeBuy -
                Math.sqrt(
                    vaccineOneReductionRateBuy * epochId * 100 * _decimalHelper
                )) /
            _decimalHelper;

        vaccineTwoProtectionDevBuy =
            (BaseFeeBuy -
                Math.sqrt(
                    vaccineTwoReductionRateBuy * epochId * 100 * _decimalHelper
                )) /
            _decimalHelper;

        vaccineThreeProtectionDevBuy =
            (BaseFeeBuy -
                Math.sqrt(
                    vaccineThreeReductionRateBuy *
                        epochId *
                        100 *
                        _decimalHelper
                )) /
            _decimalHelper;

        // Upgrade sell fees
        vaccineOneProtectionDevSell =
            (BaseFeeSell -
                Math.sqrt(
                    vaccineOneReductionRateSell * epochId * 100 * _decimalHelper
                )) /
            _decimalHelper;

        vaccineTwoProtectionDevSell =
            (BaseFeeSell -
                Math.sqrt(
                    vaccineTwoReductionRateSell * epochId * 100 * _decimalHelper
                )) /
            _decimalHelper;

        vaccineThreeProtectionDevSell =
            (BaseFeeSell -
                Math.sqrt(
                    vaccineThreeReductionRateSell *
                        epochId *
                        100 *
                        _decimalHelper
                )) /
            _decimalHelper;
    }

    function _startNewEpoch() internal {
        if (epochs[epochId].gotLuckyVaccine.length > 0) {
            vault.distributeShares(epochs[epochId].gotLuckyVaccine);
        }

        epochId++;
        epochs[epochId].id = epochId;
        epochs[epochId].startTime = block.timestamp;
        epochs[epochId].endTime = block.timestamp + 23 hours;

        vaccineOneCurrentCount = 0;
        vaccineTwoCurrentCount = 0;
        vaccineThreeCurrentCount = 0;
        vaccineFourCurrentCount = 0;

        capsuleCurrentCount = 0;

        // Auto downgrade
        for (uint256 i = 0; i < userVaccineList.length; i++) {
            if (userCurrentVaccine[userVaccineList[i]] > 0) {
                userCurrentVaccine[userVaccineList[i]] -= 1;
            }
        }

        if (!isGameStarted) {
            isGameStarted = true;
        }

        _upgradeVaccineProtection();
    }

    function startNewEpoch() external onlyRole(ADMIN_ROLE) {
        require(!isGameOver, "Game is over");
        _startNewEpoch();

        emit NewEpochStarted(epochId);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);

    receive() external payable {}

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (msg.sender == pair) {
            return _transferFrom(msg.sender, recipient, amount);
        } else {
            return _basicTransfer(msg.sender, recipient, amount);
        }
    }

    function setMaxWallet() external onlyOwner {
        _maxWalletSize = _totalSupply;
    }

    function setFeesWallet(address _MarketingWallet) external onlyOwner {
        MarketingWallet = _MarketingWallet;
        isFeeExempt[MarketingWallet] = true;

        isWalletLimitExempt[MarketingWallet] = true;
    }

    function setIsWalletLimitExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        isWalletLimitExempt[holder] = exempt; // Exempt from max wallet
    }

    function setKeyHash(bytes32 _keyHash) external onlyRole(ADMIN_ROLE) {
        keyHash = _keyHash;
    }

    /**
     * @dev Allows admins to set the quantity of vaccines available to sell.
     * @param _amount The amount of vaccines available.
     * @notice The quantity of vaccines available is used to set up a double special vaccine event
     */
    function setSpecialVaccineSupply(
        uint256 _amount
    ) external onlyRole(ADMIN_ROLE) {
        require(
            _amount >= vaccineFourCurrentCount,
            "Can't reduce vaccine supply during an epoch"
        );
        vaccineFourSupply = _amount;
    }

    /**
     * @dev Allows admins to set the probability max range.
     * @param _range The new probability max range.
     * @notice The probability max range is used to set up a double special vaccine event
     */
    function setProbabilityMaxRange(
        uint256 _range
    ) external onlyRole(ADMIN_ROLE) {
        _probabilityMaxRange = _range;
    }

    /**
     * @dev Allows admins to set the capsule price.
     * @param _price The new capsule price.
     */
    function setCapsulePrice(uint256 _price) external onlyRole(ADMIN_ROLE) {
        capsulePrice = _price;
    }

    /**
     * @dev Allows admins to end the game after 7 days.
     */
    function endGame() external onlyRole(ADMIN_ROLE) {
        require(block.timestamp >= launchTime + 7 days, "Can't end the game");
        require(!isGameOver, "Game is already over");

        isGameOver = true;

        if (epochs[epochId].gotLuckyVaccine.length > 0) {
            vault.distributeShares(epochs[epochId].gotLuckyVaccine);
        }
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require(
            _allowances[sender][_msgSender()] >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _transferFrom(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Allows any holder to infect another address.
     * @param _toInfect The address to infect.
     */
    function infect(address _toInfect) external {
        require(!infected[_toInfect], "Already infected");
        require(balanceOf(msg.sender) >= 1, "Not enough tokens to infect");
        require(infected[msg.sender] == true, "You're not infected");

        infecter[_toInfect] = msg.sender;
        infected[_toInfect] = true;
        amountOfInfection[msg.sender]++;
        amountOfAllInfection++;

        bool temp;

        temp = _basicTransfer(msg.sender, _toInfect, 1 ether);
    }

    /**
     * @dev Allows any holder to buy a capsule once per epoch.
     * @notice A capsule contains a vaccine.
     * @notice Impossible to buy a capsule if holder is not infected, doesn't have enough tokens,
     * if the epoch is over or if holder has already upgraded his vaccine.
     */
    function buyCapsule() external {
        uint256 _capsulePrice = capsulePrice;

        require(infected[msg.sender], "You are not infected");
        require(isGameStarted, "Game is not started yet");
        require(!isGameOver, "Game is over");
        require(
            balanceOf(msg.sender) >= _capsulePrice,
            "Not enough tokens to buy a capsule"
        );
        require(
            epochs[epochId].endTime > block.timestamp,
            "Epoch is over, wait for the next one"
        );
        require(
            !epochs[epochId].isBuyer[msg.sender],
            "You've already bought a capsule during this epoch"
        );
        require(
            epochs[epochId].hasUpgrade[msg.sender] == false,
            "You only have one action per epoch : buy or upgrade"
        );

        capsuleCount++;
        capsuleCurrentCount++;
        epochs[epochId].isBuyer[msg.sender] = true;

        uint256 _amountToBurn = (_capsulePrice * 200) / 1000; // 20% burn

        _totalSupply -= _amountToBurn;
        _basicTransfer(msg.sender, DEAD, _amountToBurn);

        bool temp;

        temp = _basicTransfer(
            msg.sender,
            address(vault),
            _capsulePrice - _amountToBurn
        );

        uint256 _requestId = requestRandomWords();
        epochs[epochId].requestIdToAddy[_requestId] = msg.sender;
        epochs[epochId].addyToRequestId[msg.sender] = _requestId;

        emit CapsuleBought(msg.sender, _requestId);
    }

    /**
     * @dev Allows any holder to open his capsule once per epoch.
     * @notice A capsule contains a vaccine.
     * @notice Impossible to open a capsule if holder is not infected,
     * if holder hasn't bought a capsule during this epoch or if holder has already opened his capsule.
     */
    function openCapsule(address user) external {
        require(user == msg.sender, "Not authorized");
        require(
            epochs[epochId].addyToRequestId[msg.sender] != 0,
            "You haven't bought a capsule during this epoch"
        );
        require(
            epochs[epochId].hasOpenedCapsule[msg.sender] == false,
            "You've already opened your capsule"
        );
        require(
            epochs[epochId].requestFullfilled[msg.sender] == true,
            "Your request hasn't been fullfilled yet"
        );
        uint256 randomResult = getRequestStatus(
            epochs[epochId].addyToRequestId[msg.sender]
        );
        if (randomResult >= 1 && randomResult <= 40) {
            vaccineOneCount++;
            vaccineOneCurrentCount++;
            getVaccine(user, 1, false);
        } else if (randomResult >= 41 && randomResult <= 75) {
            vaccineTwoCount++;
            vaccineTwoCurrentCount++;
            getVaccine(user, 2, false);
        } else if (randomResult >= 76 && randomResult <= 97) {
            vaccineThreeCount++;
            vaccineThreeCurrentCount++;
            getVaccine(user, 3, false);
        } else if (randomResult >= 98 && randomResult <= _probabilityMaxRange) {
            vaccineFourCount++;
            vaccineFourCurrentCount++;
            epochs[epochId].gotLuckyVaccine.push(user);
            getVaccine(user, 1, true); // Lucky vaccine gets Tier 1 vaccine perks
        }
    }

    function getVaccine(address user, uint256 vaccine, bool vaccine4) internal {
        if (!userHasBoughtVaccine[user]) {
            userVaccineList.push(user);
            userHasBoughtVaccine[user] = true;
        }
        userCurrentVaccine[user] = vaccine;
        epochs[epochId].hasOpenedCapsule[user] = true;

        emit CapsuleOpened(user, vaccine, vaccine4);
    }

    /**
     * @dev Allows any holder to upgrade his vaccine once per epoch.
     * @notice Impossible to upgrade a vaccine if holder is not infected, doesn't have a vaccine to upgrade,
     * if holder hasn't enough tokens, if the epoch is over, if holder has already upgraded his vaccine or
     * if holder has bought a capsule during this epoch.
     */
    function upgradeVaccine() external {
        uint256 _upgradePrice = (capsulePrice * 750) / 1000; // 75% of capsule price

        require(
            epochs[epochId].isBuyer[msg.sender] == false,
            "You have only one action per epoch : buy or upgrade"
        );
        require(
            epochs[epochId].hasUpgrade[msg.sender] == false,
            "You've already upgraded your vaccine during this epoch"
        );
        require(
            userCurrentVaccine[msg.sender] > 0 &&
                userCurrentVaccine[msg.sender] < 3,
            "You don't have a vaccine to upgrade"
        );
        require(
            balanceOf(msg.sender) >= _upgradePrice,
            "Not enough tokens to upgrade your vaccine"
        );
        require(
            epochs[epochId].endTime > block.timestamp,
            "Epoch is over, wait for the next one"
        );
        require(!isGameOver, "Game is over");

        epochs[epochId].hasUpgrade[msg.sender] = true;

        uint256 _amountForDev = (_upgradePrice * 50) / 1000; // 5% for dev

        bool temp;

        temp = _basicTransfer(
            msg.sender,
            address(vault),
            _upgradePrice - _amountForDev
        );

        _basicTransfer(msg.sender, address(this), _amountForDev);

        userCurrentVaccine[msg.sender]++;
    }

    function requestRandomWords() internal returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        epochs[epochId].requestFullfilled[
            epochs[epochId].requestIdToAddy[_requestId]
        ] = true; // Associate the request to the user addy, and write it as fullfilled - useful for the front
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) internal view returns (uint256 _randomNumber) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        if (vaccineFourCurrentCount >= vaccineFourSupply) {
            return (request.randomWords[0] % 97) + 1;
        } else {
            return (request.randomWords[0] % _probabilityMaxRange) + 1;
        }
    }

    /**
     * @dev Allows owner to infect a bunch of OG addys.
     * @param _toInfect The addresses to infect.
     * @notice Unusable once renounced.
     */
    function infectOG(address[] memory _toInfect) external onlyOwner {
        for (uint256 i; i < _toInfect.length; i++) {
            require(!infected[_toInfect[i]], "Already infected");
            require(balanceOf(msg.sender) >= 1, "not enough tokens to infect");
            require(infected[msg.sender] == true, "not infected");

            infecter[_toInfect[i]] = msg.sender;
            infected[_toInfect[i]] = true;
            amountOfInfection[msg.sender]++;
            amountOfAllInfection++;

            bool temp;
            temp = _basicTransfer(msg.sender, _toInfect[i], 1 ether);
        }
    }

    function checkBestInfector() internal {
        address user = msg.sender;
        uint256[5] memory rewards;
        address[5] memory sortedAddresses;
        uint256 index = 0;
        for (uint i = 0; i < bestInfectors.length; i++) {
            rewards[i] = totalRewards[bestInfectors[i]];
        }

        for (uint256 i = 0; i < bestInfectors.length; i++) {
            if (bestInfectors[i] == user) {
                index = i;
            }
        }

        if (
            rewards[0] < totalRewards[user] && index != bestInfectors.length - 1
        ) {
            if (index == 0) sortedAddresses[0] = user;
            for (uint256 i = index + 1; i < bestInfectors.length; i++) {
                if (rewards[i] < totalRewards[user]) {
                    sortedAddresses[i - 1] = bestInfectors[i];
                    sortedAddresses[i] = user;
                }
            }
            bestInfectors = sortedAddresses;
        }
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(
            isFeeExempt[sender] || isFeeExempt[recipient] || isTradingEnabled,
            "Not authorized to trade yet"
        );

        // Checks infection
        if (recipient != pair) {
            require(infected[recipient], "Not infected");
        }

        // Checks if game has ended, impossible to buy
        if (isGameOver && recipient != pair) {
            require(
                hasRole(ADMIN_ROLE, sender) || hasRole(ADMIN_ROLE, recipient),
                "Game is over, only admins can buy"
            );
        }

        // Checks max transaction limit
        if (sender != owner() && recipient != owner() && recipient != DEAD) {
            if (recipient != pair) {
                require(
                    isWalletLimitExempt[recipient] ||
                        (_balances[recipient] + amount <= _maxWalletSize),
                    "Transfer amount exceeds the MaxWallet size."
                );
            }
        }

        //shouldSwapBack
        if (shouldSwapBack() && recipient == pair) {
            swapBack();
        }

        _balances[sender] = _balances[sender] - amount;

        //Check if should Take Fee
        uint256 amountReceived = (!shouldTakeFee(sender) ||
            !shouldTakeFee(recipient))
            ? amount
            : takeFee(sender, recipient, amount);
        _balances[recipient] = _balances[recipient] + (amountReceived);

        emit Transfer(sender, recipient, amountReceived);

        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + (amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeTeam = 0;
        uint256 feeInfecter = 0;
        uint256 feePool = 0;
        uint256 feeAmount = 0;

        if (sender == pair && recipient != pair) {
            // <=> buy
            if (userCurrentVaccine[recipient] == 1) {
                feeTeam = ((amount * vaccineOneProtectionDevBuy) / 10000) / 3;
                feeInfecter = feeTeam;
                feePool = feeTeam;
                pendingRewards[infecter[recipient]] += feeInfecter;
                currentPendingRewards += feeInfecter;
            } else if (userCurrentVaccine[recipient] == 2) {
                feeTeam = ((amount * vaccineTwoProtectionDevBuy) / 10000) / 3;
                feeInfecter = feeTeam;
                feePool = feeTeam;
                pendingRewards[infecter[recipient]] += feeInfecter;
                currentPendingRewards += feeInfecter;
            } else if (userCurrentVaccine[recipient] == 3) {
                feeTeam = ((amount * vaccineThreeProtectionDevBuy) / 10000) / 3;
                feeInfecter = feeTeam;
                feePool = feeTeam;
                pendingRewards[infecter[recipient]] += feeInfecter;
                currentPendingRewards += feeInfecter;
            } else {
                feeTeam = (amount * unitFeeBuy) / 10000;
                feePool = feeTeam;
                feeInfecter = feeTeam;
                pendingRewards[infecter[recipient]] += feeInfecter;
                currentPendingRewards += feeInfecter;
            }
        } else if (sender != pair && recipient == pair) {
            // <=> sell
            if (isGameOver) {
                feeTeam = (amount * 10) / 10000;
            } else if (userCurrentVaccine[sender] == 1) {
                feeTeam = ((amount * vaccineOneProtectionDevSell) / 10000) / 3;
                feeInfecter = feeTeam;
                feePool = feeTeam;
                pendingRewards[infecter[sender]] += feeInfecter;
                currentPendingRewards += feeInfecter;
            } else if (userCurrentVaccine[sender] == 2) {
                feeTeam = ((amount * vaccineTwoProtectionDevSell) / 10000) / 3;
                feeInfecter = feeTeam;
                feePool = feeTeam;
                pendingRewards[infecter[sender]] += feeInfecter;
                currentPendingRewards += feeInfecter;
            } else if (userCurrentVaccine[sender] == 3) {
                feeTeam =
                    ((amount * vaccineThreeProtectionDevSell) / 10000) /
                    3;
                feeInfecter = feeTeam;
                feePool = feeTeam;
                pendingRewards[infecter[sender]] += feeInfecter;
                currentPendingRewards += feeInfecter;
            } else {
                feeTeam = (amount * unitFeeSell) / 10000;
                feeInfecter = feeTeam;
                feePool = feeTeam;
                pendingRewards[infecter[sender]] += feeInfecter;
                currentPendingRewards += feeInfecter;
            }
        }
        feeAmount = feeTeam + feeInfecter + feePool;

        if (feeAmount > 0) {
            _balances[address(this)] += feeAmount - feePool;
            _balances[address(vault)] += feePool;
            emit Transfer(sender, address(this), feeAmount - feePool);
            emit Transfer(sender, address(vault), feePool);
        }

        return amount - feeAmount;
    }

    /**
     * @dev Allows any infecters to claim rewards.
     */
    function claim() external {
        require(msg.sender == tx.origin, "error");
        require(pendingRewards[msg.sender] > 0, "no pending rewards");

        uint256 _pendingRewards = pendingRewards[msg.sender];
        uint256 _rewardsToVault = 0;
        pendingRewards[msg.sender] = 0;

        if (block.timestamp < epochs[1].endTime) {
            _rewardsToVault = (_pendingRewards * 25) / 100; // 25% of rewards go to the reward pool if claimed during the first epoch
            _pendingRewards = _pendingRewards - _rewardsToVault;
        }

        if (_rewardsToVault > 0) {
            _basicTransfer(address(this), address(vault), _rewardsToVault);
        }

        bool temp;
        temp = _basicTransfer(address(this), msg.sender, _pendingRewards);
        require(temp, "transfer failed");
        totalRewards[msg.sender] += _pendingRewards;
        totalAllRewards += _pendingRewards;
        currentPendingRewards -= _pendingRewards;

        checkBestInfector();
        emit _claim(msg.sender, _pendingRewards);
    }

    function getBestInfectors() external view returns (address[5] memory) {
        return bestInfectors;
    }

    function getIsBuyer(address user) external view returns (bool) {
        return epochs[epochId].isBuyer[user];
    }

    function getHasUpgrade(address user) external view returns (bool) {
        return epochs[epochId].hasUpgrade[user];
    }

    function getHasOpenedCapsule(address user) external view returns (bool) {
        return epochs[epochId].hasOpenedCapsule[user];
    }

    function getRequestFullfilled(address user) external view returns (bool) {
        return epochs[epochId].requestFullfilled[user];
    }

    function getGotLuckyVaccine() external view returns (address[] memory) {
        return epochs[epochId].gotLuckyVaccine;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            balanceOf(address(this)) - currentPendingRewards >= swapThreshold;
    }

    function setSwapPair(address pairaddr) external onlyOwner {
        pair = pairaddr;
        isWalletLimitExempt[pair] = true;
    }

    function setSwapBackSettings(
        bool _enabled,
        uint256 _amount
    ) external onlyOwner {
        require(_amount >= 1, "Can't set SwapThreshold to ZERO");
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setIsTradingEnabled() external onlyOwner {
        isTradingEnabled = true;
        swapEnabled = true;
        if (isTradingEnabled) launchTime = block.timestamp;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function swapBack() internal swapping {
        uint256 amountToSwap = balanceOf(address(this)) - currentPendingRewards;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            address(0),
            block.timestamp + 5 minutes
        );

        uint256 amountETHDev = address(this).balance;

        if (amountETHDev > 0) {
            bool tmpSuccess;
            (tmpSuccess, ) = payable(MarketingWallet).call{
                value: amountETHDev,
                gas: 30000
            }("");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is Ownable {
    IERC20 public token;
    address public tokenAddress;
    uint256 private _maxShares = (1_000_000_000 * 10**18 * 25) / 1000; // 2.5% of total supply
    uint256 public totalDistributed = 0;

    constructor(address _token, address initialOwner) Ownable(initialOwner){
        token = IERC20(_token);
        tokenAddress = _token;
    }

    function distributeShares(address[] memory holders) external {
        require(
            msg.sender == tokenAddress,
            "Only token contract can call this function"
        );
        uint256 balance = token.balanceOf(address(this)) > _maxShares
            ? _maxShares
            : token.balanceOf(address(this));
        totalDistributed += balance;
        if (balance != 0) {
            for (uint256 i = 0; i < holders.length; i++) {
                token.transfer(holders[i], balance / holders.length);
            }
        }
    }

    function withdrawAll() external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}