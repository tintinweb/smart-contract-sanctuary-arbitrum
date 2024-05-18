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
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/Clones.sol)

pragma solidity ^0.8.20;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 */
library Clones {
    /**
     * @dev A clone instance deployment failed.
     */
    error ERC1167FailedCreateClone();

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
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
pragma solidity ^0.8.24;

interface IOrder {
    enum OrderType {
        Loan,
        Borrow
    }

    enum OrderStatus {
        Open,
        Active,
        Repaid,
        Canceled,
        Liquidated
    }

    enum LiquidationType {
        ReturnAsIs,
        ConvertToLoanToken
    }

    function orderId() external view returns (uint256);

    function creator() external view returns (address);

    function duration() external view returns (uint256);

    function expireDate() external view returns (uint256);

    function activationTime() external view returns (uint256);

    function interestRate() external view returns (uint256);

    function threshold() external view returns (uint256);

    function borrower() external view returns (address);

    function lender() external view returns (address);

    function collateralToken() external view returns (address);

    function loanToken() external view returns (address);

    function collateralTokenAmount() external view returns (uint256);

    function loanTokenAmount() external view returns (uint256);

    function orderType() external view returns (OrderType);

    function status() external view returns (OrderStatus);

    function liquidationType() external view returns (LiquidationType);

    function protocolManager() external view returns (address);

    function uniswapV2Factory() external view returns (address);

    function initialize(
        uint256 orderId,
        address creator,
        uint256 duration,
        uint256 interestRate,
        uint256 threshold,
        address loanToken,
        address collateralToken,
        uint256 loanTokenAmount,
        uint256 collateralTokenAmount,
        OrderType orderType,
        LiquidationType liquidationType,
        address protocolManager,
        address uniswapV2Factory
    ) external;

    function acceptOrder(address asker, LiquidationType liquidationType) external;

    function cancelOrder(address creator) external;

    function repayOrder(
        address payer,
        address protocolRewardAddress,
        uint256 protocolReward
    ) external returns (uint256);

    function liquidateOrder(uint256 protocolRewardRate, address uniswapV2Router) external;

    function sendTokens(
        address token,
        address recipient,
        uint256 amount
    ) external;

    function checkLiquidation(
        address loanToken,
        address collateralToken,
        uint256 loanTokenAmount,
        uint256 collateralTokenAmount,
        address uniswapV2Factory,
        uint256 threshold
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./IOrder.sol";

interface IProtocolManager {

    struct OrderStruct {
        address orderAddress;
        uint256 lenderOrdersByStatusIndex;
        uint256 borrowerOrdersByStatusIndex;
        uint256 openOrdersId;
        uint256 activeOrdersId;
    }

    struct OrderTokensInfo{
        address loanToken;
        address collateralToken;
        uint256 loanTokenAmount;
        uint256 collateralTokenAmount;
    }

    struct OrderInfo {
        uint256 orderId;
        address orderAddress;
        address creator;
        uint256 duration;
        uint256 expireDate;
        uint256 activationTime;
        uint256 interestRate;
        uint256 threshold;
        address borrower;
        address lender;
        OrderTokensInfo tokensInfo;
        IOrder.OrderType orderType;
        IOrder.OrderStatus status;
        IOrder.LiquidationType liquidationType;
    }

    function orderTemplate() external view returns (address);

    function uniswapV2Factory() external view returns (address);

    function uniswapV2Router() external view returns (address);

    function ordersCount() external view returns (uint256);

    function lendOrdersCount() external view returns (uint256);

    function borrowOrdersCount() external view returns (uint256);

    function protocolRewardRate() external view returns (uint256);

    function openOrdersId(IOrder.OrderType orderType, uint256 index) external view returns (uint256);

    function userOrdersByStatusCount(address user, IOrder.OrderStatus status) external view returns (uint256);

    function userOrdersByStatus(address user, IOrder.OrderStatus status, uint256 index) external view returns (uint256);

    function createOrder(
        uint256 expireDate,
        uint256 interestRate,
        uint256 threshold,
        address loanToken,
        address collateralToken,
        uint256 loanTokenAmount,
        uint256 collateralTokenAmount,
        IOrder.OrderType isLendOrder,
        IOrder.LiquidationType liquidationType
    ) external;

    function cancelOrder(uint256 orderId) external;

    function acceptOrder(uint256 orderId, IOrder.LiquidationType liquidationType) external;

    function repayOrder(uint256 orderId) external;

    function withdraw(
        address token,
        address to,
        uint256 amount
    ) external;

    function liquidateOrder(uint256 orderId) external;

    function getOrdersByUserStatus(
        address user,
        IOrder.OrderStatus status,
        uint256 startIndex,
        uint256 amount
    )
        external
        view
        returns (OrderInfo[] memory);

    function getOpenOrders(IOrder.OrderType orderType, uint256 startIndex, uint256 amount) external view returns (OrderInfo[] memory);

    function getLiquidatableOrders(uint256 startIndex, uint256 amount) external view returns (uint[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IOrder.sol";
import "./interfaces/IProtocolManager.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ProtocolManager is IProtocolManager, AccessControl {
    /// @notice Address of the order template contract
    address public immutable orderTemplate;
    /// @notice Address of the Uniswap V2 Factory
    address public immutable uniswapV2Factory;
    /// @notice Address of the Uniswap V2 Router
    address public immutable uniswapV2Router;
    /// @notice Address of the current liquidator
    address public liquidator;

    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

    /// @notice Total number of orders created in the protocol
    uint256 public ordersCount;
    /// @notice Count of lend (loan offer) orders
    uint256 public lendOrdersCount;
    /// @notice Count of borrow orders
    uint256 public borrowOrdersCount;
    /// @notice Count of currently active orders
    uint256 public activeOrdersCount;

    /// @dev Stores count of orders by user and status
    mapping(address => mapping(IOrder.OrderStatus => uint256)) public userOrdersByStatusCount;
    /// @dev Maps user and order status to order indices
    mapping(address => mapping(IOrder.OrderStatus => mapping(uint256 => uint256))) public userOrdersByStatus;
    /// @dev Mapping of all orders
    mapping(uint256 => OrderStruct) public orders;
    /// @dev Stores open order IDs by order type
    mapping(IOrder.OrderType => mapping(uint256 => uint256)) public openOrdersId;
    /// @dev Stores IDs of active orders
    mapping(uint256 => uint256) public activeOrdersId;

    /// @notice Current reward rate of the protocol
    uint256 public protocolRewardRate = 0;

    event OrderCreated(address indexed orderAddress, uint256 indexed orderId);
    event OrderAccepted(address indexed orderAddress, uint256 indexed orderId, address indexed asker);
    event OrderCanceled(address indexed orderAddress, uint256 indexed orderId);
    event OrderRepaid(address indexed orderAddress, uint256 indexed orderId, address borrower, uint256 repayAmount);
    event OrderLiquidated(address indexed orderAddress, uint256 indexed orderId);

    /// @dev Initializes the contract by setting the order template, Uniswap factory, Uniswap router addresses, and the initial contract owner
    /// @param template The contract address used as a template for creating orders
    /// @param uniswapV2Factory_ The Uniswap V2 Factory address, used for liquidity management
    /// @param uniswapV2Router_ The Uniswap V2 Router address, used for executing swaps
    /// @param initialOwner Address of the initial owner of the contract
    constructor(
        address template,
        address uniswapV2Factory_,
        address uniswapV2Router_,
        address initialOwner,
        address liquidator_
    ) {
        orderTemplate = template;
        uniswapV2Factory = uniswapV2Factory_;
        uniswapV2Router = uniswapV2Router_;
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(LIQUIDATOR_ROLE, liquidator_);

        liquidator = liquidator_;
    }

    /// @notice Creates a new order
    /// @dev Clones an order template to create a new order
    /// @param duration Duration in seconds from now until the order can no longer be accepted
    /// @param interestRate The interest rate for the loan
    /// @param threshold The threshold for liquidation
    /// @param loanToken The address of the loan token
    /// @param collateralToken The address of the collateral token
    /// @param loanTokenAmount The amount of loan tokens
    /// @param collateralTokenAmount The amount of collateral tokens
    /// @param orderType The type of the order (Loan or Borrow)
    /// @param liquidationType The liquidation type (ReturnAsIs or  ConvertToLoanToken)
    function createOrder(
        uint256 duration,
        uint256 interestRate,
        uint256 threshold,
        address loanToken,
        address collateralToken,
        uint256 loanTokenAmount,
        uint256 collateralTokenAmount,
        IOrder.OrderType orderType,
        IOrder.LiquidationType liquidationType
    )
    external
    {
        require(duration > 0, "Duration should be greater than 0");
        require(loanTokenAmount > 0 && collateralTokenAmount > 0,
            "Amount of loan and collateral tokens should be greater than 0");

        address newOrder = Clones.clone(orderTemplate);
        IOrder(newOrder).initialize(
            ordersCount,
            msg.sender,
            duration,
            interestRate,
            threshold,
            loanToken,
            collateralToken,
            loanTokenAmount,
            collateralTokenAmount,
            orderType,
            liquidationType,
            address(this),
            uniswapV2Factory
        );

        if (orderType == IOrder.OrderType.Loan) {
            transferTokens(loanToken, msg.sender, newOrder, loanTokenAmount);
        } else {
            transferTokens(collateralToken, msg.sender, newOrder, collateralTokenAmount);
        }

        // ordersCount = orderId
        orders[ordersCount] = OrderStruct({
            orderAddress: newOrder,
            lenderOrdersByStatusIndex: orderType == IOrder.OrderType.Loan ?
            userOrdersByStatusCount[msg.sender][IOrder.OrderStatus.Open] : 0,
            borrowerOrdersByStatusIndex: orderType == IOrder.OrderType.Borrow ?
            userOrdersByStatusCount[msg.sender][IOrder.OrderStatus.Open] : 0,
            openOrdersId: 0,
            activeOrdersId: 0
        });

        if (orderType == IOrder.OrderType.Loan) {
            openOrdersId[IOrder.OrderType.Loan][lendOrdersCount] = ordersCount;
            orders[ordersCount].openOrdersId = lendOrdersCount++;
        } else {
            openOrdersId[IOrder.OrderType.Borrow][borrowOrdersCount] = ordersCount;
            orders[ordersCount].openOrdersId = borrowOrdersCount++;
        }

        userOrdersByStatus[msg.sender][IOrder.OrderStatus.Open][userOrdersByStatusCount[msg.sender][IOrder.OrderStatus.Open]] = ordersCount;

        ordersCount++;
        userOrdersByStatusCount[msg.sender][IOrder.OrderStatus.Open]++;

        emit OrderCreated(newOrder, ordersCount - 1);
    }

    /// @notice Cancels an open order
    /// @dev Only the creator of the order or the contract owner can cancel an order. It also handles token returns based on the order type
    /// @param orderId The ID of the order to be canceled
    function cancelOrder(uint256 orderId) external {
        OrderStruct storage orderStruct = orders[orderId];
        require(orderStruct.orderAddress != address(0), "Order does not exist");

        IOrder order = IOrder(orderStruct.orderAddress);
        require(order.status() == IOrder.OrderStatus.Open, "Order cannot be canceled");

        removeFromOpenOrders(order.orderType(), orderStruct);

        changeUserOrderStatus(order.creator(), IOrder.OrderStatus.Canceled, orderStruct);

        order.cancelOrder(msg.sender);

        if (order.orderType() == IOrder.OrderType.Loan) {
            order.sendTokens(order.loanToken(), order.lender(), order.loanTokenAmount());
        } else {
            order.sendTokens(order.collateralToken(), order.borrower(), order.collateralTokenAmount());
        }

        emit OrderCanceled(orderStruct.orderAddress, orderId);
    }

    /// @notice Accepts an open order
    /// @dev The function takes care of transferring necessary tokens and updating internal states to reflect the acceptance
    /// @param orderId The ID of the order to accept
    /// @param liquidationType The chosen liquidation type for the order
    function acceptOrder(uint256 orderId, IOrder.LiquidationType liquidationType) external {
        OrderStruct storage orderStruct = orders[orderId];
        require(orderStruct.orderAddress != address(0), "Order does not exist");

        IOrder order = IOrder(orderStruct.orderAddress);
        require(order.status() == IOrder.OrderStatus.Open, "Order cannot be accepted");

        changeUserOrderStatus(order.creator(), IOrder.OrderStatus.Active, orderStruct);

        order.acceptOrder(msg.sender, liquidationType);

        if (order.orderType() == IOrder.OrderType.Loan) {
            transferTokens(order.collateralToken(), msg.sender, orderStruct.orderAddress, order.collateralTokenAmount());
            order.sendTokens(order.loanToken(), msg.sender, order.loanTokenAmount());
            orderStruct.borrowerOrdersByStatusIndex = userOrdersByStatusCount[msg.sender][IOrder.OrderStatus.Active];
        } else {
            transferTokens(order.loanToken(), msg.sender, order.borrower(), order.loanTokenAmount());
            orderStruct.lenderOrdersByStatusIndex = userOrdersByStatusCount[msg.sender][IOrder.OrderStatus.Active];
        }

        removeFromOpenOrders(order.orderType(), orderStruct);

        activeOrdersId[activeOrdersCount] = order.orderId();
        orderStruct.activeOrdersId = activeOrdersCount;

        userOrdersByStatus[msg.sender][IOrder.OrderStatus.Active][userOrdersByStatusCount[msg.sender][IOrder.OrderStatus.Active]] = orderId;
        userOrdersByStatusCount[msg.sender][IOrder.OrderStatus.Active]++;
        activeOrdersCount++;

        emit OrderAccepted(orderStruct.orderAddress, orderId, msg.sender);
    }

    /// @notice Repays an active loan order
    /// @dev Calculates the repayment amount with interest and performs the token transfer. Also handles protocol rewards
    /// @param orderId The ID of the order to repay
    function repayOrder(uint256 orderId) external {
        OrderStruct storage orderStruct = orders[orderId];
        require(orderStruct.orderAddress != address(0), "Order does not exist");

        IOrder order = IOrder(orderStruct.orderAddress);
        require(order.status() == IOrder.OrderStatus.Active, "Order is not active");

        changeUserOrderStatus(order.borrower(), IOrder.OrderStatus.Repaid, orderStruct);
        changeUserOrderStatus(order.lender(), IOrder.OrderStatus.Repaid, orderStruct);

        uint256 repayAmount = order.repayOrder(msg.sender, address(this), protocolRewardRate);
        removeFromActiveOrders(orderStruct.activeOrdersId);

        emit OrderRepaid(orderStruct.orderAddress, orderId, msg.sender, repayAmount);
    }

    /// @notice Allows the owner to withdraw tokens from the contract
    /// @dev Only callable by the protocol owner. Used for withdrawing contract earnings
    /// @param token The token address to withdraw
    /// @param to The address to send tokens to
    /// @param amount The amount of tokens to withdraw
    function withdraw(address token, address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(token).transfer(to, amount);
    }

    /// @notice Allows the owner to reassign the liquidator role to a new address
    /// @dev Only callable by the protocol owner. Used for managing the liquidator role
    /// @param newLiquidator The address to be assigned the liquidator role
    function setLiquidator(address newLiquidator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(LIQUIDATOR_ROLE, liquidator);
        _grantRole(LIQUIDATOR_ROLE, newLiquidator);

        liquidator = newLiquidator;
    }

    /// @notice Executes the liquidation process for an active order that has breached its liquidation threshold
    /// @dev Only callable by the liquidator
    /// @param orderId The ID of the order to liquidate
    function liquidateOrder(uint256 orderId) external onlyRole(LIQUIDATOR_ROLE) {
        OrderStruct storage orderStruct = orders[orderId];
        require(orderStruct.orderAddress != address(0), "Order does not exist");

        IOrder order = IOrder(orderStruct.orderAddress);
        require(order.status() == IOrder.OrderStatus.Active, "Order is not active");

        changeUserOrderStatus(order.borrower(), IOrder.OrderStatus.Liquidated, orderStruct);
        changeUserOrderStatus(order.lender(), IOrder.OrderStatus.Liquidated, orderStruct);

        order.liquidateOrder(protocolRewardRate, uniswapV2Router);

        removeFromActiveOrders(orderStruct.activeOrdersId);

        emit OrderLiquidated(orderStruct.orderAddress, orderId);
    }

    /// @notice Retrieves orders for a specific user and status
    /// @dev Displaying user-specific order information in the UI, supporting pagination for UI implementation
    /// @param user The address of the user whose orders to retrieve
    /// @param status The status of the orders to filter by
    /// @param startIndex The index to start retrieving orders from
    /// @param amount The number of orders to retrieve
    /// @return paginatedOrders An array of orders that match the criteria
    function getOrdersByUserStatus(address user, IOrder.OrderStatus status, uint256 startIndex, uint256 amount)
    public
    view
    returns (OrderInfo[] memory)
    {
        uint256 totalOrders = userOrdersByStatusCount[user][status];

        if (startIndex >= totalOrders) {
            return new OrderInfo[](0);
        }

        uint256 remaining = totalOrders - startIndex;
        uint256 resultCount = remaining < amount ? remaining : amount;

        OrderInfo[] memory paginatedOrders = new OrderInfo[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            uint256 orderId = userOrdersByStatus[user][status][startIndex + i];
            IOrder order = IOrder(orders[orderId].orderAddress);
            paginatedOrders[i] = OrderInfo({
                orderId: orderId,
                orderAddress: orders[orderId].orderAddress,
                creator: order.creator(),
                duration: order.duration(),
                expireDate: order.expireDate(),
                activationTime: order.activationTime(),
                interestRate: order.interestRate(),
                threshold: order.threshold(),
                borrower: order.borrower(),
                lender: order.lender(),
                tokensInfo: OrderTokensInfo({
                    loanToken: order.loanToken(),
                    collateralToken: order.collateralToken(),
                    loanTokenAmount: order.loanTokenAmount(),
                    collateralTokenAmount: order.collateralTokenAmount()
                }),
                orderType: order.orderType(),
                status: order.status(),
                liquidationType: order.liquidationType()
            });
        }

        return paginatedOrders;
    }

    /// @notice Retrieves open orders of a specific type
    /// @dev Displaying open orders by order type, supporting pagination for UI implementation
    /// @param orderType The type of orders to retrieve (Loan or Borrow)
    /// @param startIndex The index to start retrieving orders from
    /// @param amount The number of orders to retrieve
    /// @return paginatedOrders An array of open orders of the specified type
    function getOpenOrders(IOrder.OrderType orderType, uint256 startIndex, uint256 amount)
    public
    view
    returns (OrderInfo[] memory)
    {
        uint256 totalOrders = orderType == IOrder.OrderType.Loan ? lendOrdersCount : borrowOrdersCount;

        if (startIndex >= totalOrders) {
            return new OrderInfo[](0);
        }

        uint256 remaining = totalOrders - startIndex;
        uint256 resultCount = remaining < amount ? remaining : amount;

        OrderInfo[] memory paginatedOrders = new OrderInfo[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            uint256 orderId = openOrdersId[orderType][startIndex + i];
            IOrder order = IOrder(orders[orderId].orderAddress);
            paginatedOrders[i] = OrderInfo({
                orderId: orderId,
                orderAddress: orders[orderId].orderAddress,
                creator: order.creator(),
                expireDate: order.expireDate(),
                duration: order.duration(),
                activationTime: order.activationTime(),
                interestRate: order.interestRate(),
                threshold: order.threshold(),
                borrower: order.borrower(),
                lender: order.lender(),
                tokensInfo: OrderTokensInfo({
                    loanToken: order.loanToken(),
                    collateralToken: order.collateralToken(),
                    loanTokenAmount: order.loanTokenAmount(),
                    collateralTokenAmount: order.collateralTokenAmount()
                }),
                orderType: order.orderType(),
                status: order.status(),
                liquidationType: order.liquidationType()
            });
        }

        return paginatedOrders;
    }

    /// @notice Retrieves active orders
    /// @dev Allows viewing of active orders, supporting pagination for UI implementation
    /// @param startIndex The index to start retrieving orders from
    /// @param amount The maximum number of orders to return
    /// @return paginatedOrders An array of active orders starting from the specified index
    function getActiveOrders(uint256 startIndex, uint256 amount)
    public
    view
    returns (OrderInfo[] memory)
    {
        if (startIndex >= activeOrdersCount) {
            return new OrderInfo[](0);
        }

        uint256 remaining = activeOrdersCount - startIndex;
        uint256 resultCount = remaining < amount ? remaining : amount;

        OrderInfo[] memory paginatedOrders = new OrderInfo[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            uint256 orderId = activeOrdersId[startIndex + i];
            IOrder order = IOrder(orders[orderId].orderAddress);
            paginatedOrders[i] = OrderInfo({
                orderId: orderId,
                orderAddress: orders[orderId].orderAddress,
                creator: order.creator(),
                duration: order.duration(),
                expireDate: order.expireDate(),
                activationTime: order.activationTime(),
                interestRate: order.interestRate(),
                threshold: order.threshold(),
                borrower: order.borrower(),
                lender: order.lender(),
                tokensInfo: OrderTokensInfo({
                    loanToken: order.loanToken(),
                    collateralToken: order.collateralToken(),
                    loanTokenAmount: order.loanTokenAmount(),
                    collateralTokenAmount: order.collateralTokenAmount()
                }),
                orderType: order.orderType(),
                status: order.status(),
                liquidationType: order.liquidationType()
            });
        }

        return paginatedOrders;
    }

    /// @notice Identifies orders eligible for liquidation
    /// @dev Scans through active orders to find those meeting the criteria for liquidation
    /// @param startIndex The index to start scanning from
    /// @param amount The number of orders to check for liquidation eligibility
    /// @return ordersToLiquidate An array of order IDs eligible for liquidation
    function getLiquidatableOrders(uint256 startIndex, uint256 amount) public view returns (uint256[] memory) {
        if (startIndex >= activeOrdersCount) {
            return new uint256[](0);
        }

        uint256 remaining = activeOrdersCount - startIndex;
        uint256 resultCount = remaining < amount ? remaining : amount;

        uint256[] memory ordersToLiquidate = new uint256[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            uint256 orderId = activeOrdersId[i];
            IOrder order = IOrder(orders[orderId].orderAddress);

            if (order.checkLiquidation(
                order.loanToken(),
                order.collateralToken(),
                order.loanTokenAmount(),
                order.collateralTokenAmount(),
                order.uniswapV2Factory(),
                order.threshold()
            ) || block.timestamp > order.expireDate()) {
                ordersToLiquidate[i] = orderId;
            }
        }

        return ordersToLiquidate;
    }

    /// @dev Helper function to transfer tokens
    /// @param token The ERC20 token address to transfer
    /// @param from The address from which tokens are transferred
    /// @param to The address to which tokens are transferred
    /// @param amount The amount of tokens to transfer
    function transferTokens(address token, address from, address to, uint256 amount) internal {
        uint256 allowanceAmount = IERC20(token).allowance(from, address(this));
        require(allowanceAmount >= amount, "Allowance is less than token amount");
        require(IERC20(token).transferFrom(from, to, amount), "Transfer failed");
    }

    /// @dev Removes an order from the mapping of open orders
    /// @param orderType The type of the order being removed (Loan or Borrow)
    /// @param orderStruct The struct representing the order to be removed
    function removeFromOpenOrders(IOrder.OrderType orderType, OrderStruct memory orderStruct) internal {
        if (orderType == IOrder.OrderType.Loan) {
            openOrdersId[orderType][orderStruct.openOrdersId] = openOrdersId[orderType][--lendOrdersCount];
        } else {
            openOrdersId[orderType][orderStruct.openOrdersId] = openOrdersId[orderType][--borrowOrdersCount];
        }
    }

    /// @dev Removes an order from the active orders
    /// @param activeOrderId The ID of the active order to remove, corresponding to its position in the active orders array.
    function removeFromActiveOrders(uint256 activeOrderId) internal {
        activeOrdersId[activeOrderId] = activeOrdersId[--activeOrdersCount];
    }

    /// @dev Changes the status of an order for a specific user, moving it from one status category to another within the user's personal order tracking mappings.
    /// @param user The address of the user whose order status is being changed.
    /// @param newStatus The new status to assign to the order.
    /// @param orderStruct The struct representing the order whose status is being changed
    function changeUserOrderStatus(address user, IOrder.OrderStatus newStatus, OrderStruct storage orderStruct) internal {
        IOrder order = IOrder(orderStruct.orderAddress);
        IOrder.OrderStatus currentStatus = order.status();

        if (user == order.lender()) {
            userOrdersByStatus[user][currentStatus][orderStruct.lenderOrdersByStatusIndex] =
                                    userOrdersByStatus[user][currentStatus]
                    [--userOrdersByStatusCount[user][currentStatus]];

            orderStruct.lenderOrdersByStatusIndex = userOrdersByStatusCount[user][newStatus];

        }
        else {
            userOrdersByStatus[user][currentStatus][orderStruct.borrowerOrdersByStatusIndex] =
                                    userOrdersByStatus[user][currentStatus]
                    [--userOrdersByStatusCount[user][currentStatus]];

            orderStruct.borrowerOrdersByStatusIndex = userOrdersByStatusCount[user][newStatus];

        }

        userOrdersByStatus[user][newStatus][userOrdersByStatusCount[user][newStatus]] = order.orderId();
        userOrdersByStatusCount[user][newStatus]++;
    }
}