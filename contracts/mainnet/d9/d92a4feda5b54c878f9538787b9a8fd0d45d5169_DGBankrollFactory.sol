// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* Openzeppelin Contract */
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ClonesUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

/* DeGaming Contract */
import {Bankroll} from "src/Bankroll.sol";

/* DeGaming Libraries */
import {DGErrors} from "src/libraries/DGErrors.sol";

/**
 * @title  DGBankrollFactory
 * @author DeGaming Technical Team
 * @notice Contract responsible for deploying DeGaming Bankrolls
 *
 */
contract DGBankrollFactory is AccessControlUpgradeable {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev number of collection created by this factory
    uint256 public bankrollCount;

    /// @dev Array of all Bankrolls created by this factory
    address[] public bankrolls;

    /// @dev Standard DeGaming Bankroll contract implementation address
    address public bankrollImpl;

    /// @dev DeGaming Bankroll Manager Contract address
    address public dgBankrollManager;

    /// @dev DeGaming Escrow contract address
    address public escrow;

    /// @dev DeGaming admin account
    address public dgAdmin;

    /// @dev DeGaming address
    address public deGaming;

    /// @dev Storage gap used for future upgrades (30 * 32 bytes)
    uint256[30] __gap;

    //    ______                 __                  __
    //   / ____/___  ____  _____/ /________  _______/ /_____  _____
    //  / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    // / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    // \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    /**
     * @notice
     *  Contract Constructor
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice
     *  Contract Initializer
     *
     * @param _bankrollImpl address of DeGaming implementation of Bankroll contract
     * @param _dgBankrollManager DeGaming bankroll manager  contract address
     * @param _dgAdmin DeGaming admin account
     * @param _deGaming DeGaming wallet
     *
     */
    function initialize(
        address _bankrollImpl,
        address _dgBankrollManager,
        address _escrow,
        address _dgAdmin,
        address _deGaming
    ) external initializer {
        // Initialize global variables
        bankrollImpl = _bankrollImpl;
        dgBankrollManager = _dgBankrollManager;
        escrow = _escrow;
        dgAdmin = _dgAdmin;
        deGaming = _deGaming;

        // initialize access controll
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, dgAdmin);
    }


    /**
     * @notice
     *  Deploy a new Bankroll instance
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _token address of token asociated with bankroll
     * @param _maxRiskPercentage max risk percentage in numbers (denominator 10_000 = 100)
     * @param _salt bytes used for deterministic deployment
     *
     */
    function deployBankroll(
        address _token,
        uint256 _maxRiskPercentage,
        uint256 _escrowThreshold,
        bytes32 _salt 
    ) external  onlyRole(DEFAULT_ADMIN_ROLE) {
        // Make sure that token address is a contract
        if (!_isContract(_token)) revert DGErrors.ADDRESS_NOT_A_CONTRACT();

        // Make sure that maxrisk does not exceed 100%
        if (_maxRiskPercentage > 10_000) revert DGErrors.MAXRISK_TOO_HIGH();

        // Deploy new Bankroll contract
        Bankroll newBankroll = Bankroll(ClonesUpgradeable.cloneDeterministic(bankrollImpl, _salt));

        // Initialize Bankroll contract
        newBankroll.initialize(
            dgAdmin,
            _token,
            dgBankrollManager,
            escrow,
            deGaming,
            _maxRiskPercentage,
            _escrowThreshold
        );

        // Add address to list of bankrolls
        bankrolls.push(address(newBankroll));
        
        // Increment bankroll counter
        ++bankrollCount;
    }

    /**
     * @notice
     *  Set Bankroll implementation address
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _newImpl address of the new implementation contract
     *
     */
    function setBankrollImplementation(address _newImpl) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Make sure that new bankroll implementation is a contract
        if (!_isContract(_newImpl)) revert DGErrors.ADDRESS_NOT_A_CONTRACT();

        // set new bankroll implementation
        bankrollImpl = _newImpl;
    }

    /**
     * @notice
     *  Set DeGaming Bankroll Manager contract address
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _dgBankrollManager Bankroll Manager Contract address
     *
     */
    function setDgBankrollManager(address _dgBankrollManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Make sure that new bankroll manager is a contract
        if (!_isContract(_dgBankrollManager)) revert DGErrors.ADDRESS_NOT_A_CONTRACT();

        // Set new bankroll manager
        dgBankrollManager = _dgBankrollManager;
    }

    /**
     * @notice
     *  Set DeGaming Escrow contract address
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _escrow Escrow Contract address
     *
     */
    function setDgEscrow(address _escrow) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Make sure that new escrow address is a contract
        if (!_isContract(_escrow)) revert DGErrors.ADDRESS_NOT_A_CONTRACT();

        // Set new escrow address
        escrow = _escrow;
    }

    /**
     * @notice
     *  Set DeGaming admin account
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _dgAdmin DeGaming admin account
     *
     */
    function setDgAdmin(address _dgAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dgAdmin = _dgAdmin;
    }

    /**
     * @notice
     *  Set DeGaming wallet address 
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _deGaming DeGaming wallet
     *
     */
    function setDeGaming(address _deGaming) external onlyRole(DEFAULT_ADMIN_ROLE) {
        deGaming = _deGaming;
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Predict the new Bankroll contract address
     *
     * @param _salt salt used for the deterministic deployment
     *
     * @return _predicted predicted address for the given `_salt`
     *
     */
    function predictBankrollAddress(bytes32 _salt) external view returns (address _predicted) {
        _predicted = ClonesUpgradeable.predictDeterministicAddress(bankrollImpl, _salt, address(this));
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

        /**
     * @notice
     *  Allows contract to check if the Token address actually is a contract
     *
     * @param _address address we want to  check
     *
     * @return _isAddressContract returns true if token is a contract, otherwise returns false
     *
     */
    function _isContract(address _address) internal view returns (bool _isAddressContract) {
        uint256 size;

        assembly {
            size := extcodesize(_address)
        }

        _isAddressContract = size > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
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

    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

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
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
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
        require(instance != address(0), "ERC1167: create failed");
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
        require(instance != address(0), "ERC1167: create2 failed");
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
pragma solidity 0.8.19;

/* Openzeppelin Interfaces */
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/* Openzeppelin Contracts */
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/* DeGaming Interfaces */
import {IBankroll} from "src/interfaces/IBankroll.sol";
import {IDGBankrollManager} from "src/interfaces/IDGBankrollManager.sol";
import {IDGEscrow} from "src/interfaces/IDGEscrow.sol";

/* DeGaming Libraries */
import {DGErrors} from "src/libraries/DGErrors.sol";
import {DGDataTypes} from "src/libraries/DGDataTypes.sol";
import {DGEvents} from "src/libraries/DGEvents.sol";

/**
 * @title Bankroll V2
 * @author DeGaming Technical Team
 * @notice Operator and Game Bankroll Contract
 *
 */
contract Bankroll is IBankroll, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    /// @dev Using SafeERC20 for safer token interaction
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev the current aggregated profit of the bankroll balance
    int256 public GGR;

    /// @dev total amount of shares
    uint256 public totalSupply;

    /// @dev used to calculate percentages
    uint256 public constant DENOMINATOR = 10_000; 

    /// @dev Max percentage of liquidity risked
    uint256 public maxRiskPercentage;

    /// @dev Escrow threshold absolute value
    uint256 public escrowTreshold;

    /// @dev amount for minimum pool in case it exists
    uint256 public minimumLp;

    // @dev Withdrawal delay
    uint256 public withdrawalDelay;

    /// @dev WithdrawalWindow length
    uint256 public withdrawalWindowLength;

    /// @dev Minimum time between withdrawal step one
    uint256 public withdrawalEventPeriod;

    /// @dev Minimum time between deposit and withdrawal
    uint256 public minimumDepositionTime;

    /// @dev ADMIN role
    bytes32 public constant ADMIN = keccak256("ADMIN");

    /// @dev BANKROLL_MANAGER role
    bytes32 public constant BANKROLL_MANAGER = keccak256("BANKROLL_MANAGER");

    /// @dev The GGR of a certain operator
    mapping(address operator => int256 operatorGGR) public ggrOf;

    /// @dev Withdrawal window per lp
    mapping(address lp => DGDataTypes.WithdrawalInfo info) withdrawalInfoOf;

    /// @dev Withdrawal stage one limit
    mapping(address lp => uint256 timestamp) public withdrawalLimitOf;

    /// @dev amount of shares per lp
    mapping(address lp => uint256 shares) public sharesOf; 

    /// @dev allowed LP addresses
    mapping(address lp => bool authorized) public lpWhitelist;

    /// @dev timestamp when an LP can withdraw
    mapping(address lp => uint256 withdrawable) public withdrawableTimeOf;

    /// @dev bankroll liquidity token
    IERC20Upgradeable public token;

    /// @dev Bankroll manager instance
    IDGBankrollManager dgBankrollManager; 

    /// @dev Escrow instance
    IDGEscrow escrow;

    /// @dev set status regarding if LP is open or whitelisted
    DGDataTypes.LpIs public lpIs = DGDataTypes.LpIs.OPEN;

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/
    /**
     * @notice
     *  Contract Constructor
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
        _mint(address(this), 1_000);
    }

    /**
     * @notice Bankroll constructor
     *
     * @param _admin Admin address
     * @param _token Bankroll liquidity token address
     * @param _bankrollManager address of bankroll manager
     * @param _escrow address of escrow contract
     * @param _owner address of contract owner
     * @param _maxRiskPercentage the max risk that the bankroll balance is risking for each game
     *
     */
    function initialize(
        address _admin,
        address _token,
        address _bankrollManager,
        address _escrow,
        address _owner,
        uint256 _maxRiskPercentage,
        uint256 _escrowThreshold
    ) external initializer {
        // Check so that both bankroll manager,token and escrow are contracts
        if (!_isContract(_bankrollManager) || !_isContract(_token) || !_isContract(_escrow)) revert DGErrors.ADDRESS_NOT_A_CONTRACT();

        // Check so that owner is not a contract
        if (_isContract(_owner)) revert DGErrors.ADDRESS_NOT_A_WALLET();

        // Check so that maxRiskPercentage isnt larger than denominator
        if (_maxRiskPercentage > DENOMINATOR) revert DGErrors.MAXRISK_TOO_HIGH();

        // Initialize OZ packages
        __AccessControl_init();
        __ReentrancyGuard_init();

        // Initializing erc20 token associated with bankroll
        token = IERC20Upgradeable(_token);

        // Set the max risk percentage
        maxRiskPercentage = _maxRiskPercentage;

        // Set escrow threshold
        escrowTreshold = _escrowThreshold;

        // Set default withdrawal delay in seconds
        withdrawalDelay = 30;

        // Set default withdrawal window
        withdrawalWindowLength = 5 minutes;

        // Set default staging period
        withdrawalEventPeriod = 1 hours;

        // Set minimum deposition time
        minimumDepositionTime = 1 weeks;

        // Setup bankroll manager
        dgBankrollManager = IDGBankrollManager(_bankrollManager);

        // Setup escrow
        escrow = IDGEscrow(_escrow);

        // grant owner default admin role
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);

        // grant Admin role to escrow contract
        _grantRole(ADMIN, _escrow);

        // Grant Admin role
        _grantRole(ADMIN, _admin);

        // Grant Bankroll manager role
        _grantRole(BANKROLL_MANAGER, _bankrollManager);
    }

    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice Deposit ERC20 tokens to the bankroll
     *  Called by Liquidity Providers
     *
     * @param _amount Amount of ERC20 tokens to deposit
     *
     */
    function depositFunds(uint256 _amount) external {
        // check if the user is allowed to deposit if the bankroll is not public
        if (
            lpIs == DGDataTypes.LpIs.WHITELISTED && 
            !lpWhitelist[msg.sender]
        ) revert DGErrors.LP_IS_NOT_WHITELISTED();

        // Check if the bankroll has a minimum lp and if so that the deposition exceeds it
        if (_amount < minimumLp) revert DGErrors.DEPOSITION_TO_LOW(); 

        // Set depositionLimit
        withdrawableTimeOf[msg.sender] = block.timestamp + minimumDepositionTime; 

        // store liquidity variable to calculate amounts of shares minted, since 
        // the liquidity() result will change before we have the amount variable
        uint256 liq = liquidity();

        // fetch balance before
        uint256 balanceBefore = token.balanceOf(address(this));

        // transfer ERC20 from the user to the vault
        token.safeTransferFrom(msg.sender, address(this), _amount);

        // fetch balance aftrer
        uint256 balanceAfter = token.balanceOf(address(this));

        // amount variable calculated from recieved balances
        uint256 amount = balanceAfter - balanceBefore;

        // // calculate the amount of shares to mint
        uint256 shares;
        if (totalSupply < 1 || totalSupply > 0 && liq == 0) {
            shares = amount;
        } else {
            shares = (amount * totalSupply) / liq;
        }

        // mint shares to the user
        _mint(msg.sender, shares);

        // Emit a funds deposited event 
        emit DGEvents.FundsDeposited(msg.sender, amount);
    }

    /**
     * @notice Stage one of withdrawal process
     *
     * @param _amount Amount of shares to withdraw
     *
     */
    function withdrawalStageOne(uint256 _amount) external {
        // Make sure that LPs don't try to withdraw more than they have
        if (_amount > sharesOf[msg.sender]) revert DGErrors.LP_REQUESTED_AMOUNT_OVERFLOW();

        // Make sure that withdrawals are allowed
        if (withdrawalWindowLength == 0) revert DGErrors.WITHDRAWALS_NOT_ALLOWED();

        // Make sure that minimum deposition time has passed
        if (block.timestamp < withdrawableTimeOf[msg.sender]) revert DGErrors.MINIMUM_DEPOSITION_TIME_NOT_PASSED();

        // Fetch withdrawal info
        DGDataTypes.WithdrawalInfo memory withdrawalInfo = withdrawalInfoOf[msg.sender];

        // Make sure that previous withdrawal is either fullfilled or window has passed
        if (
            withdrawalInfo.stage == DGDataTypes.WithdrawalIs.STAGED &&
            block.timestamp < withdrawalInfo.timestamp + withdrawalWindowLength
        ) revert DGErrors.WITHDRAWAL_PROCESS_IN_STAGING();

        // Check so that event period timestamp has passed
        if (block.timestamp < withdrawalLimitOf[msg.sender]) revert DGErrors.WITHDRAWAL_TIMESTAMP_HASNT_PASSED();
        
        // Update withdrawalInfo of LP
        withdrawalInfoOf[msg.sender] = DGDataTypes.WithdrawalInfo(
            block.timestamp,
            _amount,
            DGDataTypes.WithdrawalIs.STAGED
        );

        // Set new withdrawal Limit of LP
        withdrawalLimitOf[msg.sender] = block.timestamp + withdrawalEventPeriod;

        // Emit withdrawal staged event
        emit DGEvents.WithdrawalStaged(msg.sender, block.timestamp + withdrawalDelay, block.timestamp + withdrawalWindowLength);
    }

    /**
     * @notice Stage two of withdrawal process
     *
     */
    function withdrawalStageTwo() external nonReentrant {
        // Fetch withdrawal info of sender
        DGDataTypes.WithdrawalInfo memory withdrawalInfo = withdrawalInfoOf[msg.sender];

        // make sure that withdrawal is in staging
        if (withdrawalInfo.stage == DGDataTypes.WithdrawalIs.FULLFILLED) revert DGErrors.WITHDRAWAL_ALREADY_FULLFILLED();

        // Make sure it is within withdrawal window
        if (
            block.timestamp < withdrawalInfo.timestamp + withdrawalDelay ||
            block.timestamp > withdrawalInfo.timestamp + withdrawalWindowLength
        ) revert DGErrors.OUTSIDE_WITHDRAWAL_WINDOW();

        // Call internal withdrawal function
        _withdraw(withdrawalInfo.amountToClaim, msg.sender);

        // Set stage status ti FULLFILLED
        withdrawalInfoOf[msg.sender].stage = DGDataTypes.WithdrawalIs.FULLFILLED;
    }

    /**
     * @notice Pay player amount in ERC20 tokens from the bankroll
     *  Called by Admin
     *
     * @param _player Player wallet
     * @param _amount Prize money amount
     * @param _operator The operator from which the call comes from
     *
     */
    function debit(address _player, uint256 _amount, address _operator) public onlyRole(ADMIN) {
        // Check that operator is approved
        if (!dgBankrollManager.isApproved(_operator)) revert DGErrors.NOT_AN_OPERATOR();

        // Check so that operator is associated with this bankroll
        if (!dgBankrollManager.operatorOfBankroll(address(this), _operator)) revert DGErrors.OPERATOR_NOT_ASSOCIATED_WITH_BANKROLL();

        // pay what is left if amount is bigger than bankroll balance
        uint256 maxRisk = getMaxRisk();

        // Throw error if maxrisk is 0
        if (maxRisk == 0) revert DGErrors.MAX_RISK_ZERO();

        // Handle sweeping of bankroll
        if (_amount > maxRisk) {
            // Set maxRisk value to _amount variable
            _amount = maxRisk;

            // Emit event that the bankroll is sweppt
            emit DGEvents.BankrollSwept(_player, _amount);
        }

        // fetch balance before
        uint256 balanceBefore = token.balanceOf(address(this));

        // Create amount variable
        uint256 amount;

        // If amount is more then threshold, deposit into escrow...
        if (_amount > escrowTreshold) {
            escrow.depositFunds(_player, _operator, address(token), _amount);

            // fetch balance aftrer
            uint256 balanceAfter = token.balanceOf(address(this));

            // amount variable calculated from recieved balances
            amount = balanceBefore - balanceAfter;

        // ... Else go on with payout
        } else {

            // transfer ERC20 from the vault to the winner
            token.safeTransfer(_player, _amount);

            // fetch balance aftrer
            uint256 balanceAfter = token.balanceOf(address(this));

            // amount variable calculated from recieved balances
            amount = balanceBefore - balanceAfter;

            // Emit debit event
            emit DGEvents.Debit(msg.sender, _player, amount);
        }

        // substract from total GGR
        GGR -= int256(amount);
        
        // subtracting the amount from the specified operator GGR
        ggrOf[_operator] -= int256(amount);
    }

    /**
     * @notice Pay bankroll in ERC20 tokens from players loss
     *  Called by Admin
     *
     * @param _amount Player loss amount
     * @param _operator The operator from which the call comes from
     *
     */
    function credit(uint256 _amount, address _operator) public onlyRole(ADMIN) {
        // Check that operator is approved
        if (!dgBankrollManager.isApproved(_operator)) revert DGErrors.NOT_AN_OPERATOR();

        // Check so that operator is associated with this bankroll
        if (!dgBankrollManager.operatorOfBankroll(address(this), _operator)) revert DGErrors.OPERATOR_NOT_ASSOCIATED_WITH_BANKROLL();

        // fetch balance before
        uint256 balanceBefore = token.balanceOf(address(this));

        // transfer ERC20 from the manager to the vault
        token.safeTransferFrom(msg.sender, address(this), _amount);
        
        // fetch balance aftrer
        uint256 balanceAfter = token.balanceOf(address(this));

        // amount variable calculated from recieved balances
        uint256 amount = balanceAfter - balanceBefore;

        // Add to total GGR
        GGR += int256(amount);

        // add the amount to the specified operator GGR
        ggrOf[_operator] += int256(amount);

        // Emit credit event
        emit DGEvents.Credit(msg.sender, amount);
    }


    /**
     * @notice Function for calling both the creditAndDebit function in order
     *  Called by Admin
     *
     * @param _creditAmount amount argument for credit function
     * @param _debitAmount amount argument for debit function
     * @param _operator The operator from which the call comes from
     * @param _player The player that should recieve the final payout
     *
     */
    function creditAndDebit(uint256 _creditAmount, uint256 _debitAmount, address _operator, address _player) external onlyRole(ADMIN) {
        // Credit function call
        credit(_creditAmount, _operator);

        // Debit function call
        debit(_player, _debitAmount, _operator);
    }

    /**
     * @notice Change withdrawal delay for LPs
     *  Only callable by ADMIN
     *
     * @param _withdrawalDelay New withdrawal Delay in seconds
     *
     */
    function setWithdrawalDelay(uint256 _withdrawalDelay) external onlyRole(ADMIN) {
        if (_withdrawalDelay > withdrawalWindowLength) revert DGErrors.WITHDRAWAL_TIME_RANGE_NOT_ALLOWED();

        if (_withdrawalDelay < 30) revert DGErrors.WITHDRAWAL_DELAY_TO_SHORT();

        withdrawalDelay = _withdrawalDelay;
    }

    /**
     * @notice Change withdrawal window for LPs
     *  Only callable by ADMIN
     *
     * @param _withdrawalWindow New withdrawal window in seconds
     *
     */
    function setWithdrawalWindow(uint256 _withdrawalWindow) external onlyRole(ADMIN) {
        if (_withdrawalWindow < withdrawalDelay) revert DGErrors.WITHDRAWAL_TIME_RANGE_NOT_ALLOWED();

        if (_withdrawalWindow > withdrawalEventPeriod) revert DGErrors.WITHDRAWAL_TIME_RANGE_NOT_ALLOWED();

        withdrawalWindowLength = _withdrawalWindow;
    }

    /**
     * @notice Change withdrawal (stage one) event period for LPs
     *  Only callable by ADMIN
     *
     * @param _withdrawalEventPeriod New staging event period in seconds
     *
     */
    function setWithdrawalEventPeriod(uint256 _withdrawalEventPeriod) external onlyRole(ADMIN) {
        if (_withdrawalEventPeriod < withdrawalWindowLength) revert DGErrors.WITHDRAWAL_TIME_RANGE_NOT_ALLOWED();

        withdrawalEventPeriod = _withdrawalEventPeriod;
    }

    /**
     * @notice 
     *  Change the minumum time that has to pass between deposition and withdrawal
     *
     * @param _minimumDepositionTime new minimum deposition time in seconds
     *
     */
    function setMinimumDepositionTime(uint256 _minimumDepositionTime) external onlyRole(ADMIN) {
        minimumDepositionTime = _minimumDepositionTime;
    }


    /**
     * @notice
     *  Change an individual LPs withdrawable time for their deposition
     *
     * @param _timeStamp unix timestamp for when funds should get withdrawable
     * @param _LP Address of LP
     *
     */
    function setWithdrawableTimeOf(uint256 _timeStamp, address _LP) external onlyRole(ADMIN) {
        withdrawableTimeOf[_LP] = _timeStamp;
    }

    /**
     * @notice
     *  Allows admin to update bankroll manager contract
     *
     * @param _newBankrollManager address of the new bankroll manager
     *
     */
    function updateBankrollManager(address _newBankrollManager) external onlyRole(ADMIN) {
        // Make sure that the new bankroll manager is a contract
        if (!_isContract(_newBankrollManager)) revert DGErrors.ADDRESS_NOT_A_CONTRACT();

        // Revoke old bankroll manager role
        _revokeRole(BANKROLL_MANAGER, address(dgBankrollManager));

        // set the new bankroll manager
        dgBankrollManager = IDGBankrollManager(_newBankrollManager);

        // Grant new bankroll manager role
        _grantRole(BANKROLL_MANAGER, _newBankrollManager);
    }

    /**
     * @notice
     *  Setter for escrow contract
     *
     * @param _newEscrow address of new escrow
     *
     */
    function updateEscrow(address _newEscrow) external onlyRole(ADMIN) {
        // Make sure that new escrow address is a contract
        if (!_isContract(_newEscrow)) revert DGErrors.ADDRESS_NOT_A_CONTRACT();

        // Set new escrow contract 
        escrow = IDGEscrow(_newEscrow);
    }

    /**
     * @notice Remove or add authorized liquidity provider to the bankroll
     *  Called by Admin
     *
     * @param _lp Liquidity Provider address
     * @param _isAuthorized If false, LP will not be able to deposit
     *
     */
    function setInvestorWhitelist(address _lp, bool _isAuthorized) external {
        // Check if caller is either an approved operator or admin wallet
        if (
            !dgBankrollManager.isApproved(msg.sender) &&
            !hasRole(ADMIN, msg.sender)
        ) revert DGErrors.NO_LP_ACCESS_PERMISSION();

        // Add toggle LPs _isAuthorized status
        lpWhitelist[_lp] = _isAuthorized;
    }

    /**
     * @notice Make bankroll permissionless for LPs or not
     *  Called by Admin
     *
     * @param _lpIs Toggle enum betwen OPEN and WHITELISTED
     *
     */
    function setPublic(DGDataTypes.LpIs _lpIs) external onlyRole(ADMIN) {
        // Toggle lpIs status
        lpIs = _lpIs;
    }

    /**
     * @notice Set the minimum LP amount for bankroll
     *  Called by Admin
     *
     * @param _amount Set tthe minimum lp amount
     *
     */
    function setMinimumLp(uint256 _amount) external onlyRole(ADMIN) {
        // set minimum lp
        minimumLp = _amount;
    }

    /**
     *
     * @notice allows admins to change the max risk amount
     *
     * @param _newAmount new amount in percentage that should be potentially risked per session 
     *
     */
    function changeMaxRisk(uint256 _newAmount) external onlyRole(ADMIN) {
        // Check so that maxrisk doestn't exceed 100%
        if (_newAmount > DENOMINATOR) revert DGErrors.MAXRISK_TOO_HIGH();

        // Set new maxrisk
        maxRiskPercentage = _newAmount;
    }

    /**
     *
     * @notice allows admins to change the max risk amount
     *
     * @param _newAmount new amount in that should be potentially risked per session
     *
     */
    function changeEscrowThreshold(uint256 _newAmount) external onlyRole(ADMIN) {
        // Set new maxrisk
        escrowTreshold = _newAmount;
    }

    /**
     * @notice Remove the GGR of a specified operator from the total GGR, 
     *  then null out the operator GGR. Only callable by the bankroll manager
     *
     * @param _operator the address  of the operator we want to null out
     *
     */
    function nullGgrOf(address _operator) external onlyRole(BANKROLL_MANAGER){
        // Subtract the GGR of the operator from the total GGR
        GGR -= ggrOf[_operator];

        // Null out operator GGR
        ggrOf[_operator] =  0;
    }

    /**
     *
     * @notice Max out the approval for the connected DeGaming contracts to spend on behalf of the bankroll contract
     *
     */
    function maxContractsApprove() external onlyRole(ADMIN) {
        // Approve bankroll manager address as a spender
        token.forceApprove(
            address(dgBankrollManager),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );

        // Approve escrow contract address as a spender
        token.forceApprove(
            address(escrow),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
    } 

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Preview how much shares gets generated from _amount of tokens deposited
     *
     * @param _amount how many tokens should be checked
     *
     */
    function previewMint(uint256 _amount) public view returns(uint256 _shares) {
        // store liquidity variable to calculate amounts of shares minted, since 
        // the liquidity() result will change before we have the amount variable
        uint256 liq = liquidity();
        if (totalSupply < 1 || totalSupply > 0 && liq == 0) {
            _shares = _amount;
        } else {
            _shares = (_amount * totalSupply) / liq;
        }
    }

    /**
     * @notice
     *  Check the value of x amount of shares
     *
     * @param _shares amount of shares to be checked
     *
     */
    function previewRedeem(uint256 _shares) public view returns(uint256 _amount) {
        _amount = (_shares * liquidity()) / totalSupply;
    }

    /**
     * @notice Returns the amount of ERC20 tokens held by the bankroll that are available for playes to win and
     *  will not include funds that are reserved for GGR
     *
     * @return _balance available balance for LPs
     *
     */
    function liquidity() public view returns (uint256 _balance) {
        if (GGR <= 0) {
            _balance = token.balanceOf(address(this));
        } else if (GGR > 0) {
            _balance = token.balanceOf(address(this)) - uint(GGR);
        }
    }

    /**
     * @notice Returns the current value of the LPs investment (deposit + profit).
     *
     * @param _lp Liquidity Provider address
     *
     * @return _amount the value of the lps holdings
     *
     */
    function getLpValue(address _lp) external view returns (uint256 _amount) {
        if (sharesOf[_lp] > 0) {
            _amount = (liquidity() * sharesOf[_lp]) / totalSupply;
        } else {
            _amount = 0;
        }
    }

    /**
     * @notice Returns the current stake of the LPs investment in percentage
     *
     * @param _lp Liquidity Provider address
     *
     * @return _stake the stake amount of given LP address
     *
     */
    function getLpStake(address _lp) external view returns (uint256 _stake) {
        if (sharesOf[_lp] > 0) {
            _stake = (sharesOf[_lp] * DENOMINATOR) / totalSupply;
        } else {
            _stake = 0;
        }
    }

    /**
     * @notice returns the maximum amount that can be taken from the bankroll during debit() call
     *
     * @return _maxRisk the maximum amount that can be risked
     *
     */
    function getMaxRisk() public view returns (uint256 _maxRisk) {
        _maxRisk = (liquidity() * maxRiskPercentage) / DENOMINATOR;
    }

    /**
     * @notice calculate percentages for the avalable liquidity, can be used to set the escrowThreshold
     *
     * @param _percentage percentage amount that should be calculated
     *
     * @return _amount absolute value calculated from the percentage of liquidity
     *
     */
    function calculateLiquidityPercentageAmount(uint256 _percentage) public view returns (uint256 _amount) {
        _amount = (liquidity() * _percentage) / DENOMINATOR;
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice Mint shares to the caller
     *
     * @param _to Minted shares recipient
     * @param _shares Amount of shares to mint
     *
     */
    function _mint(address _to, uint256 _shares) internal {
        // Increment the total supply
        totalSupply += _shares;

        // Increment the share balance of the recipient
        sharesOf[_to] += _shares;
    }

    /**
     * @notice Burn shares from the caller
     *
     * @param _from Burner address
     * @param _shares Amount of shares to burn
     *
     */
    function _burn(address _from, uint256 _shares) internal {
        // Subtract from the total supply
        totalSupply -= _shares;

        // Subtract the share balance of the target
        sharesOf[_from] -= _shares;
    }

    /**
     * @notice Withdraw shares from the bankroll
     *
     * @param _shares Amount of shares to burn
     *
     */
    function _withdraw(uint256 _shares, address _reciever) internal {
        // Calculate the amount of ERC20 worth of shares
        uint256 amount = previewRedeem(_shares);

        // Burn the shares from the caller
        _burn(_reciever, _shares);

        // fetch balance before
        uint256 balanceBefore = token.balanceOf(address(this));

        // Transfer ERC20 to the caller
        token.safeTransfer(_reciever, amount);

        // fetch balance aftrer
        uint256 balanceAfter = token.balanceOf(address(this));

        // amount variable calculated from recieved balances
        uint256 realizedAmount = balanceBefore - balanceAfter;

        // Emit an event that funds are withdrawn
        emit DGEvents.FundsWithdrawn(_reciever, realizedAmount);
    }

    /**
     * @notice
     *  Allows contract to check if the Token address actually is a contract
     *
     * @param _address address we want to  check
     *
     * @return _isAddressContract returns true if token is a contract, otherwise returns false
     *
     */
    function _isContract(address _address) internal view returns (bool _isAddressContract) {
        uint256 size;

        assembly {
            size := extcodesize(_address)
        }

        _isAddressContract = size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title DGErrors
 * @author DeGaming Technical Team
 * @notice Library containing DeGaming contracts' custom errors
 */
library DGErrors {
    /// @dev Error thrown if LP is not on the whitelist
    error LP_IS_NOT_WHITELISTED();
    
    /// @dev Error thrown when someone tries to claim fees before the eventperiod is over
    error EVENT_PERIOD_NOT_PASSED();

    /// @dev Error thrown if bankroll is not an approved DeGaming bankroll
    error BANKROLL_NOT_APPROVED();

    /// @dev Error thrown if GGR < 1 or even negative
    error NOTHING_TO_CLAIM();

    /// @dev Error thrown when address sent to credit/debit is not a valid operator
    error NOT_AN_OPERATOR();

    /// @dev Error thrown when lp has no access
    error NO_LP_ACCESS_PERMISSION();

    /// @dev Error thrown when bankroll with a > 100% fee is being requested to be added  
    error TO_HIGH_FEE();

    /// @dev Error thrown if operator is not associated with this specific bankroll
    error OPERATOR_NOT_ASSOCIATED_WITH_BANKROLL();

    /// @dev Error thrown when trying to redundantly add operators to bankrolls
    error OPERATOR_ALREADY_ADDED_TO_BANKROLL();

    /// @dev Error thrown when LP is trying to withdraw more than they have
    error LP_REQUESTED_AMOUNT_OVERFLOW();

    /// @dev Error thrown when a bankroll has a minimum lp amount which the depositor does not satisfy
    error DEPOSITION_TO_LOW();

    /// @dev Error thrown when desired bankroll is not a contract
    error ADDRESS_NOT_A_CONTRACT();

    /// @dev Error thrown when desired operator is not a wallet
    error ADDRESS_NOT_A_WALLET();

    /// @dev Error thrown when max risk is too high
    error MAXRISK_TOO_HIGH();

    /// @dev Error thrown when withdrawal timestamp hasnt passed
    error WITHDRAWAL_TIMESTAMP_HASNT_PASSED();

    /// @dev Error thrown when withdrawal is in staging mode
    error WITHDRAWAL_PROCESS_IN_STAGING();

    /// @dev Error thrown when trying to fullfill an already fullfilled withdrawal
    error WITHDRAWAL_ALREADY_FULLFILLED();

    /// @dev Error thrown when LPs are trying to withdraw outside of their withdrawal window
    error OUTSIDE_WITHDRAWAL_WINDOW();

    /// @dev Error thrown when someone unauthorized is trying to claim
    error UNAUTHORIZED_CLAIM();

    /// @dev Error thrown if maxrisk = 0
    error MAX_RISK_ZERO();

    /// @dev Error thrown if checks regarding setting withdrawal mechanisms params fail
    error WITHDRAWAL_TIME_RANGE_NOT_ALLOWED();

    /// @dev Error thrown if a lp is tryingto withdraw when withdrawals are stopped
    error WITHDRAWALS_NOT_ALLOWED();

    /// @dev Error thrown when withdrawal delay is under 30 seconds
    error WITHDRAWAL_DELAY_TO_SHORT();

    /// @dev Error thrown when escrow is locked
    error ESCROW_LOCKED();

    /// @dev Error thrown when minimum deposition time of LP hasn't passed
    error MINIMUM_DEPOSITION_TIME_NOT_PASSED();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;
import {Initializable} from "../proxy/utils/Initializable.sol";

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";
import "./math/SignedMathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMathUpgradeable.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {DGDataTypes} from "src/libraries/DGDataTypes.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title IBankroll V2
 * @author DeGaming Technical Team
 * @notice Interface for Bankroll contract
 *
 */
interface IBankroll { 
    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice Deposit ERC20 tokens to the bankroll
     *  Called by Liquidity Providers
     *
     * @param _amount Amount of ERC20 tokens to deposit
     *
     */
    function depositFunds(uint256 _amount) external;

    /**
     * @notice Stage one of withdrawal process
     *
     * @param _amount Amount of shares to withdraw
     *
     */
    function withdrawalStageOne(uint256 _amount) external;

    /**
     * @notice Stage two of withdrawal process
     *
     */
    function withdrawalStageTwo() external;

    /**
     * @notice Change withdrawal delay for LPs
     *  Only callable by ADMIN
     *
     * @param _withdrawalDelay New withdrawal Delay in seconds
     *
     */
    function setWithdrawalDelay(uint256 _withdrawalDelay) external;

    /**
     * @notice Change withdrawal window for LPs
     *  Only callable by ADMIN
     *
     * @param _withdrawalWindow New withdrawal window in seconds
     *
     */
    function setWithdrawalWindow(uint256 _withdrawalWindow) external;

    /**
     * @notice 
     *  Change the minumum time that has to pass between deposition and withdrawal
     *
     * @param _minimumDepositionTime new minimum deposition time in seconds
     *
     */
    function setMinimumDepositionTime(uint256 _minimumDepositionTime) external;

    /**
     * @notice
     *  Change an individual LPs withdrawable time for their deposition
     *
     * @param _timeStamp unix timestamp for when funds should get withdrawable
     * @param _LP Address of LP
     *
     */
    function setWithdrawableTimeOf(uint256 _timeStamp, address _LP) external;

    /**
     * @notice
     *  Allows admin to update bankroll manager contract
     *
     * @param _newBankrollManager address of the new bankroll manager
     *
     */
    function updateBankrollManager(address _newBankrollManager) external;

    /**
     * @notice Change staging event period for LPs
     *  Only callable by ADMIN
     *
     * @param _withdrawalEventPeriod New staging event period in seconds
     *
     */
    function setWithdrawalEventPeriod(uint256 _withdrawalEventPeriod) external;

    /**
     * @notice Pay player amount in ERC20 tokens from the bankroll
     *  Called by Admin
     *
     * @param _player Player wallet
     * @param _amount Prize money amount
     * @param _operator The operator from which the call comes from
     *
     */
    function debit(address _player, uint256 _amount, address _operator) external;

    /**
     * @notice Pay bankroll in ERC20 tokens from players loss
     *  Called by Admin
     *
     * @param _amount Player loss amount
     * @param _operator The operator from which the call comes from
     *
     */
    function credit(uint256 _amount, address _operator) external;

    /**
     * @notice Function for calling both the creditAndDebit function in order
     *  Called by Admin
     *
     * @param _creditAmount amount argument for credit function
     * @param _debitAmount amount argument for debit function
     * @param _operator The operator from which the call comes from
     * @param _player The player that should recieve the final payout
     *
     */
    function creditAndDebit(uint256 _creditAmount, uint256 _debitAmount, address _operator, address _player) external;

    /**
     * @notice
     *  Setter for escrow contract
     *
     * @param _newEscrow address of new escrow
     *
     */
    function updateEscrow(address _newEscrow) external;

    /**
     * @notice Remove or add authorized liquidity provider to the bankroll
     *  Called by Admin
     *
     * @param _lp Liquidity Provider address
     * @param _isAuthorized If false, LP will not be able to deposit
     *
     */
    function setInvestorWhitelist(address _lp, bool _isAuthorized) external;

    /**
     * @notice Make bankroll permissionless for LPs or not
     *  Called by Admin
     *
     * @param _lpIs Toggle enum betwen OPEN and WHITELISTED
     *
     */
    function setPublic(DGDataTypes.LpIs _lpIs) external;

    /**
     * @notice Remove the GGR of a specified operator from the total GGR, 
     *  then null out the operator GGR. Only callable by the bankroll manager
     *
     * @param _operator the address  of the operator we want to null out
     *
     */
    function nullGgrOf(address _operator) external;

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Preview how much shares gets generated from _amount of tokens deposited
     *
     * @param _amount how many tokens should be checked
     *
     */
    function previewMint(uint256 _amount) external view returns(uint256 _shares);

    /**
     * @notice
     *  Check the value of x amount of shares
     *
     * @param _shares amount of shares to be checked
     *
     */
    function previewRedeem(uint256 _shares) external view returns(uint256 _amount);

    function token() external view returns (IERC20Upgradeable token);

    /**
     * @notice Returns the amount of ERC20 tokens held by the bankroll that are available for playes to win and
     *  will not include funds that are reserved for GGR
     *
     * @return _balance available balance for LPs
     *
     */
    function liquidity() external view returns (uint256 _balance);

    /**
     * @notice Returns the current value of the LPs investment (deposit + profit).
     *
     * @param _lp Liquidity Provider address
     *
     * @return _amount the value of the lps holdings
     *
     */
    function getLpValue(address _lp) external view returns (uint256 _amount);

    /**
     * @notice Returns the current stake of the LPs investment in percentage
     *
     * @param _lp Liquidity Provider address
     *
     * @return _stake the stake amount of given LP address
     *
     */
    function getLpStake(address _lp) external view returns (uint256 _stake);

    /**
     * @notice returns the maximum amount that can be taken from the bankroll during debit() call
     *
     * @return _maxRisk the maximum amount that can be risked
     *
     */
    function getMaxRisk() external view returns (uint256 _maxRisk);

    /**
     * @notice Getter function for GGR variable
     *
     */
    function GGR() external view returns(int256);

    /**
     * @notice getter function for ggrOf mapping
     *
     * @param operator address of operator
     *
     * @return operatorGGR the GGR of specified operator
     *
     */
    function ggrOf(address operator) external view returns(int256 operatorGGR);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {DGDataTypes} from "src/libraries/DGDataTypes.sol";

/**
 * @title IDGBankrollManager V1
 * @author DeGaming Technical Team
 * @notice Interface for DGBankrollManager contract
 *
 */
interface IDGBankrollManager {
    /**
     * @notice
     *  Approve a bankroll to use the DeGaming Bankroll Manager
     *  Only the contract owner can execute this operation
     *
     * @param _bankroll bankroll contract address to be approved
     *
     */
    function approveBankroll(address _bankroll, uint256 _fee) external;

    /**
     * @notice
     *  Prevent a bankroll from using the DeGaming Bankroll Manager
     *  Only the contract owner can execute this operation
     *
     * @param _bankroll bankroll contract address to be blocked
     *
     */
    function blockBankroll(address _bankroll) external;

    /**
     * @notice
     *  Update existing bankrolls fee
     *
     * @param _bankroll bankroll contract address to be blocked
     * @param _newFee bankroll contract address to be blocked
     *
     */
    function updateLpFee(address _bankroll, uint256 _newFee) external;

    /**
     * @notice 
     *  Adding list of operator to list of operators associated with a bankroll
     *  Only calleable by owner
     *
     * @param _bankroll the bankroll contract address
     * @param _operator address of the operator we want to add to the list of associated operators
     *
     */
    function setOperatorToBankroll(address _bankroll, address _operator) external;

    function removeOperatorFromBankroll(address _operator, address _bankroll) external;

    function blockOperator(address _operator) external;

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice Claim profit from the bankroll
     * 
     * @param _bankroll address of bankroll 
     *
     */
    function claimProfit(address _bankroll) external;

    function isApproved(address operator) external view returns(bool approved); 

    function operatorOfBankroll(address _bankroll, address _operator) external view returns (bool _isRelated);

    function bankrollStatus(address bankroll) external view returns(bool isApproved);
}

// SPDX_License_Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title DGEscrow
 * @author DeGaming Technical Team
 * @notice Escrow Contract for DeGaming's Bankroll poducts
 *
 */
interface IDGEscrow {

    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Function called by the bankroll to send funds to the escrow
     *
     * @param _player address of the player 
     * @param _operator address of the operator
     * @param _token address of the token
     * @param _winnings amount of tokens sent to escrow
     *
     */
    function depositFunds(address _player, address _operator, address _token, uint256 _winnings) external; 

    /**
     * @notice
     *  Allows DeGaming to release escrowed funds to the player wallet
     *
     * @param _id id in bytes format
     *
     */
    function releaseFunds(bytes memory _id) external;

    /**
     * @notice
     *  Allows DeGaming to revert escrowed funds back into the bankroll in case of fraud
     *
     * @param _id id in bytes format
     *
     */
    function revertFunds(bytes memory _id) external;

    /**
     * @notice
     *  Allows admin to set the lock status of escrowed funds
     *
     * @param _id id of escrowed funds
     * @param _status boolean status if the funds should be locked or not
     *
     */
    function toggleLockEscrow(bytes memory _id, bool _status) external;

    /**
     * @notice
     *  Allows players to claim their escrowed amount after a certain period has passed
     *  id escrow is left unaddressed by DeGaming
     *
     * @param _id id in bytes format
     *
     */
    function claimUnaddressed(bytes memory _id) external;

    /**
     * @notice 
     *  Allows admin to set new event period time
     *
     * @param _newEventPeriod New event period time in seconds
     *
     */
    function setEventPeriod(uint256 _newEventPeriod) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title DGDataTypes
 * @author DeGaming Technical Team
 * @notice Library containing DeGaming contracts' custom data types
 */
library DGDataTypes {
    /// @dev Enum for holding LP status
    enum LpIs {
        OPEN,
        WHITELISTED
    }

    /// @dev Enum for holding withdrawal stage
    enum WithdrawalIs {
        FULLFILLED,
        STAGED
    }

    /// @dev Withdrawal window timestamps
    struct WithdrawalInfo {
        uint256 timestamp;
        uint256 amountToClaim;
        WithdrawalIs stage;
    }

    /// @dev Escrow entry 
    struct EscrowEntry {
        address bankroll;
        address operator;
        address player;
        address token;
        uint256 timestamp;
        uint256 nonce;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title DGEvents
 * @author DeGaming Technical Team
 * @notice Library containing DeGaming contracts' custom events
 */
library DGEvents {
    /// @dev Event emitted when LPs have deposited funds
    event FundsDeposited(address lp, uint256 amount);

    /// @dev Event emitted when LPs have withdrawn funds
    event FundsWithdrawn(address lp, uint256 amount);

    /// @dev Event emitted when LP withdrawal is staged;
    event WithdrawalStaged(address lp, uint256 timestampMin, uint256 timestampMax);
    
    /// @dev Event emitted when debit function is called
    event Debit(address manager, address player, uint256 amount);
    
    /// @dev Event emitted when Credit function is called
    event Credit(address manager, uint256 amount);
    
    /// @dev Event emitted when the bankroll is emptied or reached max risk
    event BankrollSwept(address player, uint256 amount);

    /// @dev Event emitted when profits are claimed
    event ProfitsClaimed(address bankroll, uint256 ggrTotal, uint256 sentToDeGaming);

    /// @dev Event emitted when funds are escrowed
    event WinningsEscrowed(address bankroll, address operator, address player, address token, bytes id);

    /// @dev Event emitted when escrow is payed out
    event EscrowPayed(address recipient, bytes id, uint256 amount);
    
    /// @dev Event emitted when escrow is payed out
    event EscrowReverted(address bankroll, bytes id, uint256 amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
library SignedMathUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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