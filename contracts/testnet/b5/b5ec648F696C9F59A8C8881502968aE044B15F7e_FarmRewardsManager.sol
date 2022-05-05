/**
 *Submitted for verification at Arbiscan on 2022-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
        _checkRole(role, _msgSender());
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

interface IGaugeController {
    struct Point {
        uint256 bias;
        uint256 slope;
    }

    struct VotedSlope {
        uint256 slope;
        uint256 power;
        uint256 end;
    }
    
    /**
     * @notice Voting escrow contract
     */
    function voting_escrow() external view returns (address);

    /**
     * @notice Number of gauge types
     */
    function n_gauge_types() external view returns (int128);

    /**
     * @notice Number of gauges
     */
    function n_gauges() external view returns(int128);

    /**
     * @notice Gauge type id => name
     */
    function gauge_type_names(int128 _gauge_type_id) external view returns (string memory);

    /**
     * @notice Gauge number => Pool id
     */
    function gauges(int128 _gauge_number) external view returns (uint256);

    /**
     * @notice user => pool id => VotedSlope
     */
    function vote_user_slopes(address _user, uint256 _pool_id) external view returns (VotedSlope memory);

    /**
     * @notice Total vote power used by user
     */
    function vote_user_power(address _user) external view returns (uint256);

    /**
     * Last user vote's timestamp for each pool id
     */
    function last_user_vote(address _user, uint256 _pool_id) external view returns (uint256);

    /**
     * @notice pool id => time => Point
     */
    function points_weight(uint256 _pool_id, uint256 _timestamp) external view returns (Point memory);

    /**
     * @notice pool id => time => slope
     */
    function changes_weight(uint256 _pool_id, uint256 _timestamp) external view returns (uint256);

    /**
     * @notice pool id => last scheduled time (next week)
     */
    function time_weight(uint256 _pool_id) external view returns (uint256);

    /**
     * @notice type_id => time => Point
     */
    function points_sum(int128 _type_id, uint256 _timestamp) external view returns (Point memory);

    /**
     * @notice type_id => time => slope
     */
    function changes_sum(int128 _type_id, uint256 _timestamp) external view returns (uint256);

    /**
     * @notice type_id => last scheduled time (next week)
     */
    function time_sum(int128 _type_id) external view returns (uint256);

    /**
     * @notice time => total weight
     */
    function points_total(uint256 _timestamp) external view returns(uint256);

    /**
     * @notice last scheduled time
     */
    function time_total() external view returns (uint256);

    /**
     * @notice type_id => time => type weight
     */
    function points_type_weight(int128 _type_id, uint256 _timestamp) external view returns (uint256);

    /**
     * @notice type_id => last scheduled time (next week)
     */
    function time_type_weight(int128 _type_id) external view returns(uint256);

    /**
     * @notice Add gauge type with name `_name` and weight `_weight`
     * @param _name Name of gauge type
     * @param _weight Weight of gauge type
     */
    function add_type(string memory _name, uint256 _weight) external;

    /**
     * @notice Add gauge type with name `_name` and weight `0`
     * @param _name Name of gauge type
     */
    function add_type(string memory _name) external;

    /**
     * @notice Add gauge `_pool_id` of type `_gauge_type` with weight `_weight`
     * @param _pool_id Gauge address
     * @param _gauge_type Gauge type
     * @param _weight Gauge weight
     */
    function add_gauge(uint256 _pool_id, int128 _gauge_type, uint256 _weight) external;

    /**
     * @notice Add gauge `_pool_id` of type `_gauge_type` with weight `0`
     * @param _pool_id Gauge address
     * @param _gauge_type Gauge type
     */
    function add_gauge(uint256 _pool_id, int128 _gauge_type) external;

    /**
     * @notice Get gauge type for address
     * @param _pool_id Gauge address
     * @return Gauge type id
     */
    function gauge_types(uint256 _pool_id) external view returns (int128);

    /**
     * @notice Checkpoint to fill data common for all gauges
     */
    function checkpoint() external;

    /**
     * @notice Checkpoint to fill data for both a specific gauge and common for all gauges
     * @param _pool_id Gauge address
     */
    function checkpoint(uint256 _pool_id) external;

    /**
     * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
               (e.g. 1.0 == 1e18). Inflation which will be received by it is
               inflation_rate * relative_weight / 1e18
     * @param _pool_id Gauge address
     * @param _time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gauge_relative_weight(uint256 _pool_id, uint256 _time) external view returns (uint256);

    /**
     * @notice Get Gauge relative weight (not more than 1.0) at `_time = block.timestamp` normalized to 1e18
               (e.g. 1.0 == 1e18). Inflation which will be received by it is
               inflation_rate * relative_weight / 1e18
     * @param _pool_id Gauge address
     * @return Value of relative weight normalized to 1e18
     */
    function gauge_relative_weight(uint256 _pool_id) external view returns (uint256);

    /**
     * @notice Get gauge weight normalized to 1e18 and also fill all the unfilled
               values for type and gauge records
     * @dev Any address can call, however nothing is recorded if the values are filled already
     * @param _pool_id Gauge address
     * @param _time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gauge_relative_weight_write(uint256 _pool_id, uint256 _time) external returns (uint256);

    /**
     * @notice Get gauge weight normalized to 1e18 and also fill all the unfilled
               values for type and gauge records at `_time = block.timestamp`
     * @dev Any address can call, however nothing is recorded if the values are filled already
     * @param _pool_id Gauge address
     * @return Value of relative weight normalized to 1e18
     */
    function gauge_relative_weight_write(uint256 _pool_id) external returns (uint256);

    /**
     * @notice Change gauge type `_type_id` weight to `_weight`
     * @param _type_id Gauge type id
     * @param _weight New Gauge weight
     */
    function change_type_weight(int128 _type_id, uint256 _weight) external;

    /**
     * @notice Change weight of gauge `addr` to `weight`
     * @param _pool_id `GaugeController` contract address
     * @param _weight New Gauge weight
     */
    function change_gauge_weight(uint256 _pool_id, uint256 _weight) external;

    /**
     * @notice Allocate voting power for changing pool weights
     * @param _pool_id Gauge which `msg.sender` votes for
     * @param _user_weight Weight for a gauge in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0
     */
    function vote_for_gauge_weights(uint256 _pool_id, uint256 _user_weight) external;

    /**
     * @notice Get current gauge weight
     * @param _pool_id Gauge address
     * @return Gauge weight
     */
    function get_gauge_weight(uint256 _pool_id) external view returns (uint256);

    /**
     * @notice Get current type weight
     * @param _type_id Type id
     * @return Type weight
     */
    function get_type_weight(int128 _type_id) external view returns (uint256);

    /**
     * @notice Get current total (type-weighted) weight
     * @return Total weight
     */
    function get_total_weight() external view returns (uint256);

    /**
     * @notice Get sum of gauge weights per type
     * @param _type_id Type id
     * @return Sum of gauge weights
     */
    function get_weights_sum_per_type(int128 _type_id) external view returns (uint256);

    event AddType(
        string name,
        int128 type_id
    );

    event NewTypeWeight(
        int128 type_id,
        uint256 time,
        uint256 weight,
        uint256 total_weight
    );

    event NewGaugeWeight(
        uint256 pool_id,
        uint256 time,
        uint256 weight,
        uint256 total_weight
    );

    event VoteForGauge(
        uint256 time,
        address user,
        uint256 pool_id,
        uint256 weight
    );

    event NewGauge(
        uint256 addr,
        int128 gauge_type,
        uint256 weight
    );

    event KilledGauge(
        uint256 addr
    );

    error InvalidGaugeType();
    error DuplicatedGauge();
    error LockExpiresBeforeNextEpoch();
    error NoVotingPowerLeft();
    error VoteTooSoon();
    error GaugeNotFound();
    error UsedTooMuchPower();
}

interface IFarm {
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external;
}

contract FarmRewardsManager is AccessControl {
    // Roles
    bytes32 constant GOVERNOR = bytes32("GOVERNOR");
    bytes32 constant KEEPER = bytes32("KEEPER");

    // A week in seconds
    uint256 constant WEEK = 7 * 24 * 60 * 60;

    // The farm contract address
    address public farm;
    // The gauge controller contract address
    address public gaugeController;

    // poolId => `true` if initialized
    mapping(uint256 => bool) initialized;
    // poolId => timestamp => `true` if already distributed
    mapping(uint256 => mapping(uint256 => bool)) distributed;

    /**
     * @param _farm The farm contract address
     * @param _gaugeController The gauge controller contract address
     * @param _governor The governor address
     */
    constructor(address _farm, address _gaugeController, address _governor) {
        farm = _farm;
        gaugeController = _gaugeController;

        _grantRole(GOVERNOR, _governor);
    }

    modifier onlyGovernor() {
        if (!hasRole(GOVERNOR, msg.sender)) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyKeeper() {
        if(!hasRole(KEEPER, msg.sender)) {
            revert Unauthorized();
        }
        _;
    }

    function updateFarm(address _farm) external onlyGovernor {
        emit FarmUpdated(farm, _farm, msg.sender);

        farm = _farm;
    }

    function updateGaugeController(address _gaugeController) external onlyGovernor {
        emit GaugeControllerUpdated(gaugeController, _gaugeController, msg.sender);

        gaugeController = _gaugeController;
    }

    function transferGovernorRole(address _governor) external onlyGovernor {
        emit GovernorRoleTransferred(msg.sender, _governor);

        _revokeRole(GOVERNOR, msg.sender);
        _grantRole(GOVERNOR, _governor);
    }

    function grantKeeperRole(address _keeper) external onlyGovernor {
        emit KeeperRoleGranted(_keeper, msg.sender);

        _grantRole(KEEPER, _keeper);
    }

    function revokeKeeperRole(address _keeper) external onlyGovernor {
        emit KeeperRoleRevoked(_keeper, msg.sender);

        _revokeRole(KEEPER, _keeper);
    }

    function initializePool(uint256 _poolId, uint256 _weight) external onlyGovernor {
        if (initialized[_poolId]) {
            revert PoolAlreadyInitialized(_poolId);
        }

        // Round down to the closest week
        uint256 week = (block.timestamp / WEEK) * WEEK;

        initialized[_poolId] = true;

        uint256 weight = _updateReward(_poolId, week, _weight);

        emit PoolInitialized(farm, _poolId, week, weight, msg.sender);
    }

    function updateReward(uint256 _poolId) external onlyKeeper returns (uint256) {
        if (!initialized[_poolId]) {
            revert PoolNotInitialized(_poolId);
        }
        // Round down to the closest week
        uint256 week = (block.timestamp / WEEK) * WEEK;

        if (distributed[_poolId][week]) {
            revert AlreadyDistributed(_poolId, week);
        }
        
        uint256 weight = _updateReward(_poolId, week);

        emit UpdateRewards(farm, _poolId, week, weight, msg.sender);

        return weight;
    }

    function updateMultipleRewards(uint256[] memory _poolIds) external onlyKeeper {
        // Round down to the closest week
        uint256 week = (block.timestamp / WEEK) * WEEK;

        for (uint256 i; i < _poolIds.length; ++i) {
            uint256 poolId = _poolIds[i];

            if (!initialized[poolId]) {
                continue;
            }

            if (distributed[poolId][week]) {
                continue;
            }

            uint256 weight = _updateReward(poolId, week);

            emit UpdateRewards(farm, poolId, week, weight, msg.sender);
        }
    }

    function _updateReward(uint256 _poolId, uint256 _week) internal returns (uint256) {
        distributed[_poolId][_week] = true;

        uint256 relativeWeight = IGaugeController(gaugeController).gauge_relative_weight_write(_poolId, _week);

        IFarm(farm).set(_poolId, relativeWeight, true);

        return relativeWeight;
    }

    function _updateReward(uint256 _poolId, uint256 _week, uint256 _weight) internal returns (uint256) {
        distributed[_poolId][_week] = true;

        IFarm(farm).set(_poolId, _weight, true);

        return _weight;
    }

    event UpdateRewards(
        address indexed farm,
        uint256 indexed poolId,
        uint256 indexed week,
        uint256 weight,
        address keeper
    );

    event PoolInitialized(
        address indexed farm,
        uint256 indexed poolId,
        uint256 indexed week,
        uint256 weight,
        address governor
    );

    event FarmUpdated(
        address indexed oldFarm,
        address indexed newFarm,
        address indexed governor
    );

    event GaugeControllerUpdated(
        address indexed oldGaugeController,
        address indexed newGaugeController,
        address indexed governor
    );

    event KeeperRoleGranted(
        address indexed keeper,
        address indexed governor
    );

    event KeeperRoleRevoked(
        address indexed keeper,
        address indexed governor
    );

    event GovernorRoleTransferred(
        address indexed oldGovernor,
        address indexed newGovernor
    );

    error Unauthorized();
    error AlreadyDistributed(uint256 _poolId, uint256 _timestamp);
    error PoolAlreadyInitialized(uint256 _poolId);
    error PoolNotInitialized(uint256 _poolId);
}