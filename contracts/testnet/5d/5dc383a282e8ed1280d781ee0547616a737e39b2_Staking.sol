/**
 *Submitted for verification at Arbiscan on 2023-02-28
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/interfaces/IERC20.sol

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

// File: @openzeppelin/contracts/access/IAccessControl.sol

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/utils/Strings.sol

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/access/AccessControl.sol

// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;





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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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

// File: contracts/TransferHelper.sol


pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// File: contracts/Staking.sol


pragma solidity 0.8.15;





contract Staking is AccessControl, ReentrancyGuard {
    uint256 public constant PERCENT_BASE = 1e18;
    address public immutable clz;
    uint256 public lockedAmount;
    uint256 public numOfStakers;
    Pool[] public pools;
    mapping(address => DepositInfo[]) public addressToDepositInfo;
    mapping(address => UserInfo) public addressToUserInfo;

    uint256[6] public stakeToLevel;
    uint256[6] public levelToWeight;

    struct DepositInfo {
        uint256 amount;
        uint128 start;
        uint128 poolId;
        uint256 maxUnstakeReward;
        uint256 rewardCollected;
    }

    struct UserInfo {
        uint256 totalStakedAmount;
        uint256 level;
    }

    struct Pool {
        uint128 apr;
        uint128 timeLockUp;
        uint256 commission;
    }

    event Staked(
        address indexed user,
        uint256 amount,
        uint256 start,
        uint128 poolId,
        uint256 level,
        uint256 indexed totalStaked
    );

    event Withdraw(
        address indexed user,
        uint256 amount,
        uint128 poolId,
        bool earlyWithdraw,
        uint256 level,
        uint256 indexed totalStaked
    );

    event Harvest(address user, uint256 amount);
    event WithdrawExcess(address user, uint256 amount);

    /**
     * @param _owner address of admin
     * @param  _apr = 0.07/0.25/0.7 * 1e18 / 525600
     * @param _timeLockUp = 30/90/180 * 60 * 60 * 24
     * @param _stakeToLevel amount in cro for reaching level
     */
    constructor(
        address _owner,
        address _clz,
        uint128[3] memory _apr,
        uint128[3] memory _timeLockUp,
        uint256[6] memory _stakeToLevel,
        uint256[6] memory _levelToWeight
    ) {
        require(_owner != address(0), "Zero owner address");
        _setupRole(0x0, _owner);
        require(_clz != address(0), "Zero token address");
        clz = _clz;
        for (uint256 i; i < 3; i++) {
            pools.push(Pool(_apr[i], _timeLockUp[i], 25 * 1e16));
        }
        stakeToLevel = _stakeToLevel;
        levelToWeight = _levelToWeight;
    }

    /**
     * @param _poolId index of pool in pools
     * @param _commission new commission perсent of pool mul 10^18
     */
    function setCommission(uint128 _poolId, uint256 _commission)
        external
        onlyRole(0x0)
    {
        require(_poolId < pools.length, "Pool: wrong pool");
        require(_commission <= PERCENT_BASE, "comission > 100%");
        pools[_poolId].commission = _commission;
    }

    /**
     * @notice allow owners to add new pool
     * @param newPool - pool struct with params
     * apr - reward perсent of pool mul 10^18 div 525600
     * timeLockUp - time of pool in seconds
     * commission - commission perсent of pool mul 10^18
     */
    function addPool(Pool calldata newPool) external onlyRole(0x0) {
        require(newPool.commission <= PERCENT_BASE, "Commission > 100%");
        pools.push(newPool);
    }

    /**
     * @notice Create deposit for msg.sender with input params
     * tokens must be approved for contract before call this func
     * fires Staked event
     * @param amount initial stake clz token amount
     * @param _poolId - id of pool of deposit,
     * = 0 for 30 days, 1 for 90 days, 2 for 180 days, 3+ for new pools
     */
    function stake(uint128 _poolId, uint256 amount) external nonReentrant {
        require(amount > 0, "Token: zero amount");
        require(_poolId < pools.length, "Pool: wrong pool");
        Pool memory pool = pools[_poolId];
        uint256 _maxUnstakeReward = ((amount * pool.apr * pool.timeLockUp) /
            1 seconds) / PERCENT_BASE;
        lockedAmount += _maxUnstakeReward;
        require(
            lockedAmount <= IERC20(clz).balanceOf(address(this)),
            "Token: do not have enough reward"
        );
        lockedAmount += amount;
        if (addressToDepositInfo[_msgSender()].length == 0) {
            numOfStakers++;
        }
        addressToDepositInfo[_msgSender()].push(
            DepositInfo(
                amount,
                uint128(block.timestamp),
                _poolId,
                _maxUnstakeReward,
                0
            )
        );

        // check level change
        UserInfo storage _user = addressToUserInfo[_msgSender()];
        _user.totalStakedAmount += amount;
        while (_user.level != 6) {
            if (_user.totalStakedAmount >= stakeToLevel[_user.level]) {
                _user.level++;
            } else {
                break;
            }
        }

        TransferHelper.safeTransferFrom(
            clz,
            _msgSender(),
            address(this),
            amount
        );
        emit Staked(
            _msgSender(),
            amount,
            block.timestamp,
            _poolId,
            _user.level,
            _user.totalStakedAmount
        );
    }

    /**
     * @notice Withdraw deposit with _depositInfoId for caller,
     * allow early withdraw, fire Withdraw event
     * @param _depositInfoId - id of deposit of caller
     */
    function withdraw(uint256 _depositInfoId) external nonReentrant {
        require(
            addressToDepositInfo[_msgSender()].length > 0,
            "You dont have any deposits"
        );
        uint256 lastDepositId = addressToDepositInfo[_msgSender()].length - 1;
        require(_depositInfoId <= lastDepositId, "Deposit: wrong id");

        DepositInfo memory deposit = addressToDepositInfo[_msgSender()][
            _depositInfoId
        ];

        uint256 amount;
        bool earlyWithdraw;
        (amount, earlyWithdraw) = getRewardAmount(_msgSender(), _depositInfoId);
        amount += deposit.amount;
        // sub commission
        if (earlyWithdraw) {
            lockedAmount -=
                deposit.maxUnstakeReward +
                deposit.amount -
                deposit.rewardCollected;
            amount -=
                (deposit.amount * pools[deposit.poolId].commission) /
                PERCENT_BASE;
        } else {
            lockedAmount -= amount;
        }
        // check level change
        UserInfo storage _user = addressToUserInfo[_msgSender()];
        _user.totalStakedAmount -= deposit.amount;
        while (_user.level != 0) {
            if (_user.totalStakedAmount < stakeToLevel[_user.level - 1]) {
                _user.level--;
            } else {
                break;
            }
        }
        if (_depositInfoId != lastDepositId) {
            addressToDepositInfo[_msgSender()][
                _depositInfoId
            ] = addressToDepositInfo[_msgSender()][lastDepositId];
        }
        addressToDepositInfo[_msgSender()].pop();
        if (lastDepositId == 0) {
            numOfStakers--;
        }

        TransferHelper.safeTransfer(clz, _msgSender(), amount);

        emit Withdraw(
            _msgSender(),
            amount,
            deposit.poolId,
            earlyWithdraw,
            _user.level,
            _user.totalStakedAmount
        );
    }

    /**
     * @notice Withdraw only accumulated reward for caller,
     * fire Harvest event
     * @param _depositInfoId - id of deposit of caller
     */
    function harvest(uint256 _depositInfoId) external nonReentrant {
        require(
            _depositInfoId < addressToDepositInfo[_msgSender()].length,
            "Pool: wrong staking id"
        );

        uint256 reward;
        (reward, ) = getRewardAmount(_msgSender(), _depositInfoId);
        require(reward > 0, "Nothing to harvest");

        addressToDepositInfo[_msgSender()][_depositInfoId]
            .rewardCollected += reward;
        _harvest(reward);
    }

    /**
     * @notice Withdraw only accumulated reward for caller
     * from all his deposits, fire Harvest event, call with caution,
     * may cost a lot of gas
     */
    function harvestAll() external nonReentrant {
        uint256 length = addressToDepositInfo[_msgSender()].length;
        require(length > 0, "Nothing to harvest");
        uint256 reward;
        uint256 totalReward;
        for (uint256 i = 0; i < length; i++) {
            (reward, ) = getRewardAmount(_msgSender(), i);
            addressToDepositInfo[_msgSender()][i].rewardCollected += reward;
            totalReward += reward;
        }
        require(totalReward > 0, "Nothing to harvest");
        _harvest(totalReward);
    }

    /**
     * @notice Withdraw excess amount of CLZ from this contract,
     * can be called only by admin,
     * excess = CLZ balance of this - (all deposits amount + max rewards),
     * fire WithdrawExcess event
     * @param amount - how many CLZ withdraw
     */
    function withdrawExcess(uint256 amount)
        external
        onlyRole(0x0)
        nonReentrant
    {
        require(
            amount > 0 &&
                amount <= IERC20(clz).balanceOf(address(this)) - lockedAmount,
            "Token: not enough excess"
        );
        TransferHelper.safeTransfer(clz, _msgSender(), amount);
        emit WithdrawExcess(_msgSender(), amount);
    }

    /**
     * @param _users array of user addresses
     * @return weights for all _users in such order
     */
    function getWeightBatch(address[] calldata _users)
        external
        view
        returns (uint256[] memory)
    {
        uint256 length = _users.length;
        require(length > 0, "Zero length");
        uint256[] memory weigths = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            weigths[i] = getWeight(_users[i]);
        }
        return weigths;
    }

    /**
     * @param _users array of user addresses
     * @return totalStakedAmount for all _users in such order
     */
    function getTotalStakeBatch(address[] calldata _users)
        external
        view
        returns (uint256[] memory)
    {
        uint256 length = _users.length;
        require(length > 0, "Zero length");
        uint256[] memory totalStaked = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            totalStaked[i] = addressToUserInfo[_users[i]].totalStakedAmount;
        }
        return totalStaked;
    }

    /**
     * @return total num of pools
     */
    function getPoolsAmount() external view returns (uint256) {
        return pools.length;
    }

    /**
     * @notice return reward amount of deposit with input params
     * @param _user - address of deposit holder
     * @param _depositInfoId - id of deposit of _user
     * @return reward amount = initial balance + reward - collected reward
     * @return earlyWithdraw - if early unstake = true, else = false
     */
    function getRewardAmount(address _user, uint256 _depositInfoId)
        public
        view
        returns (uint256, bool)
    {
        DepositInfo memory deposit = addressToDepositInfo[_user][
            _depositInfoId
        ];
        Pool memory pool = pools[deposit.poolId];
        uint256 amount;
        bool earlyWithdraw;
        if (deposit.start + pool.timeLockUp >= block.timestamp) {
            earlyWithdraw = true;
        }
        if (earlyWithdraw) {
            amount =
                (((block.timestamp - deposit.start) / 1 seconds) *
                    deposit.amount *
                    pool.apr) /
                PERCENT_BASE -
                deposit.rewardCollected;
        } else {
            amount = deposit.maxUnstakeReward - deposit.rewardCollected;
        }
        return (amount, earlyWithdraw);
    }

    /**
     * @return array where [i] element has info about deposit[i]
     * [0] - staked amount, [1] - earned, [2] - poolId, 
     * [3] - commission percent * BASE, [4] - end lock timestamp
     */
    function getFront(address _user)
        external
        view
        returns (uint256[5][] memory)
    {
        uint256 length = addressToDepositInfo[_user].length;
        uint256[5][] memory res = new uint256[5][](length);
        for (uint256 i = 0; i < length; ) {
            uint256 poolId = uint256(addressToDepositInfo[_user][i].poolId);
            (uint256 earned, ) = getRewardAmount(_user, i);
            res[i] = [
                addressToDepositInfo[_user][i].amount,
                earned,
                poolId,
                pools[poolId].commission,
                uint256(
                    addressToDepositInfo[_user][i].start +
                        pools[poolId].timeLockUp
                )
            ];
            unchecked {
                ++i;
            }
        }
        return res;
    }

    /**
     * @param _user address of user
     * @return weight of user
     */
    function getWeight(address _user) public view returns (uint256) {
        uint256 level = addressToUserInfo[_user].level;
        if (level == 0) {
            return 0;
        } else {
            return levelToWeight[level - 1];
        }
    }

    /**
     * @notice called from harvest and harvestAll, fire Harvest event
     */
    function _harvest(uint256 reward) internal {
        lockedAmount -= reward;
        TransferHelper.safeTransfer(clz, _msgSender(), reward);
        emit Harvest(_msgSender(), reward);
    }
}