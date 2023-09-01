// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from '../interfaces/IAxelarGateway.sol';
import { IAxelarExecutable } from '../interfaces/IAxelarExecutable.sol';

contract AxelarExecutable is IAxelarExecutable {
    IAxelarGateway public immutable gateway;

    constructor(address gateway_) {
        if (gateway_ == address(0)) revert InvalidAddress();

        gateway = IAxelarGateway(gateway_);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        bytes32 payloadHash = keccak256(payload);

        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash))
            revert NotApprovedByGateway();

        _execute(sourceChain, sourceAddress, payload);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external {
        bytes32 payloadHash = keccak256(payload);

        if (
            !gateway.validateContractCallAndMint(
                commandId,
                sourceChain,
                sourceAddress,
                payloadHash,
                tokenSymbol,
                amount
            )
        ) revert NotApprovedByGateway();

        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from './IAxelarGateway.sol';

interface IAxelarExecutable {
    error InvalidAddress();
    error NotApprovedByGateway();

    function gateway() external view returns (IAxelarGateway);

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external;

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// This should be owned by the microservice that is paying for gas.
interface IAxelarGasService {
    error NothingReceived();
    error InvalidAddress();
    error NotCollector();
    error InvalidAmounts();

    event GasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForExpressCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForExpressCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

    event ExpressGasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeExpressGasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        uint256 gasFeeAmount,
        address refundAddress
    );

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    function addGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function addExpressGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeExpressGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function collectFees(
        address payable receiver,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external;

    function refund(
        address payable receiver,
        address token,
        uint256 amount
    ) external;

    function gasCollector() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(string memory symbol) external view returns (uint256);

    function tokenMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library StringToAddress {
    error InvalidAddressString();

    function toAddress(string memory addressString) internal pure returns (address) {
        bytes memory stringBytes = bytes(addressString);
        uint160 addressNumber = 0;
        uint8 stringByte;

        if (stringBytes.length != 42 || stringBytes[0] != '0' || stringBytes[1] != 'x') revert InvalidAddressString();

        for (uint256 i = 2; i < 42; ++i) {
            stringByte = uint8(stringBytes[i]);

            if ((stringByte >= 97) && (stringByte <= 102)) stringByte -= 87;
            else if ((stringByte >= 65) && (stringByte <= 70)) stringByte -= 55;
            else if ((stringByte >= 48) && (stringByte <= 57)) stringByte -= 48;
            else revert InvalidAddressString();

            addressNumber |= uint160(uint256(stringByte) << ((41 - i) << 2));
        }

        return address(addressNumber);
    }
}

library AddressToString {
    function toString(address address_) internal pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(address_);
        bytes memory characters = '0123456789abcdef';
        bytes memory stringBytes = new bytes(42);

        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        for (uint256 i; i < 20; ++i) {
            stringBytes[2 + i * 2] = characters[uint8(addressBytes[i] >> 4)];
            stringBytes[3 + i * 2] = characters[uint8(addressBytes[i] & 0x0f)];
        }

        return string(stringBytes);
    }
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
pragma solidity ^0.8.19;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { ICrossRouter } from "../interfaces/ICrossRouter.sol";
import { IBridgeAxelar } from "../interfaces/IBridgeAxelar.sol";

import { AxelarExecutable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import { StringToAddress } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressString.sol";
import { IAxelarGateway } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import { IAxelarGasService } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";

/**
 * @title Bridge
 * @dev A contract that serves as a bridge between different chains.
 */
contract BridgeAxelar is AxelarExecutable, AccessControl, IBridgeAxelar {
    using StringToAddress for string;
    /*//////////////////////////////////////////////////////////////
                           CONSTANTS
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant ROUTER_ROLE = keccak256("ROUTER_ROLE");

    uint16 public constant override VERSION = 1;

    /*//////////////////////////////////////////////////////////////
                           STORAGE
    //////////////////////////////////////////////////////////////*/
    IAxelarGasService public immutable gasService;

    ICrossRouter private _router;

    mapping(uint16 chainId => string bridgeAddress) public _bridgeLookup;
    mapping(uint16 chainId => string chainName) public _chainLookup;
    mapping(string chainName => uint16 chainId) public _chainLookupByName;

    mapping(uint16 chainId => mapping(MESSAGE_TYPE messageType => uint256 gas)) private _gasLookup;

    mapping(uint16 chainId => mapping(bytes bridgeAddress => mapping(uint64 nonce => bytes32 payload))) private
        _failedMessages;

    /// @notice received parameters per chain per action id for both swap or vouchers
    mapping(uint16 chainId => mapping(bytes32 swapId => ICrossRouter.SwapMessage message)) private _receivedSwapMessages;
    mapping(uint16 chainId => mapping(bytes32 swapId => ICrossRouter.LiquidityMessage message)) private
        _receivedLiquidityMessages;

    /*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address gateway_, address gasReceiver_, address router) AxelarExecutable(gateway_) {
        if (gateway_ == address(0)) revert InvalidRouter();
        if (gasReceiver_ == address(0)) revert InvalidRouter();
        if (router == address(0)) revert InvalidRouter();
        gasService = IAxelarGasService(gasReceiver_);
        _router = ICrossRouter(router);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ROUTER_ROLE, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                                ROUTER
    //////////////////////////////////////////////////////////////*/
    /**
     * @inheritdoc IBridgeAxelar
     */
    function dispatchMessage(
        uint16 chainId,
        MESSAGE_TYPE messageType,
        address payable refundAddress,
        bytes calldata payload
    )
        external
        payable
        override
        onlyRole(ROUTER_ROLE)
    {
        uint16 version = 1;

        gasService.payNativeGasForContractCall{ value: msg.value }(
            address(this), _chainLookup[chainId], _bridgeLookup[chainId], payload, refundAddress
        );
        IAxelarGateway(gateway).callContract(_chainLookup[chainId], _bridgeLookup[chainId], payload);
        emit MessageDispatched(chainId, messageType, refundAddress, payload);
    }

    // TODO do something with the nonce so it can be easily tracked by the backend
    // function lzReceive(
    //     uint16 srcChainId_,
    //     bytes calldata pathAddressBytes_,
    //     uint64 nonce_,
    //     bytes calldata payload_
    // ) external override {
    //     if (msg.sender != address(_layerZeroEndpoint)) revert NotLayerZero();
    //     try this.nonBlockingReceive(srcChainId_, pathAddressBytes_, payload_) {} catch {
    //         _failedMessages[srcChainId_][pathAddressBytes_][nonce_] = keccak256(payload_);
    //         emit MessageFailed(srcChainId_, pathAddressBytes_, nonce_, payload_);
    //     }
    // }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    )
        internal
        override
    {
        // this.nonBlockingReceive(srcChainId, pathAddressBytes, payload);
        uint16 chainId = _chainLookupByName[sourceChain];
        require(_bridgeLookup[chainId].toAddress() == sourceAddress.toAddress(), "Invalid src bridge address");
        _handleReceive(chainId, payload);
    }

    /*//////////////////////////////////////////////////////////////
                                GOVERNANCE
    //////////////////////////////////////////////////////////////*/
    // to-do: checks for setters
    /**
     * @inheritdoc IBridgeAxelar
     */
    function setBridge(uint16 chainId, string calldata bridgeAddress) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _bridgeLookup[chainId] = bridgeAddress;
    }

    function setChainName(uint16 chainId, string calldata chainName) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _chainLookup[chainId] = chainName;
        _chainLookupByName[chainName] = chainId;
    }

    /**
     * @inheritdoc IBridgeAxelar
     */
    function setRouter(ICrossRouter newRouter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _router = newRouter;
    }

    /**
     * @inheritdoc IBridgeAxelar
     */
    function setForwardedGas(
        uint16 chainId,
        MESSAGE_TYPE functionType,
        uint256 gasAmount
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _gasLookup[chainId][functionType] = gasAmount;
    }

    function addNativeGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    )
        external
        payable
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        gasService.addNativeGas{ value: msg.value }(txHash, logIndex, refundAddress);
    }

    /*//////////////////////////////////////////////////////////////
                           PUBLIC WRITE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // function nonBlockingReceive(uint16 srcChainId, bytes calldata pathAddressBytes, bytes calldata payload) public {
    //     // TODO remove this for testing
    //     // if (msg.sender != address(this) && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert InsufficientAccess();
    //     // if (keccak256(pathAddressBytes) != keccak256(_bridgeLookup[srcChainId])) {
    //     //     revert BridgeMismatch();
    //     // }
    //     _handleReceive(srcChainId, payload);
    // }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUCNTIONS
    //////////////////////////////////////////////////////////////*/
    function _handleReceive(uint16 srcChainId, bytes calldata payload) internal {
        uint8 functionType;
        assembly ("memory-safe") {
            // Only copy the first byte since it's the one containing the function type
            functionType := calldataload(payload.offset)
            // right shift it of 248 bits to put the function type at the start of the mem slot
            functionType := shr(248, functionType)
        }

        if (functionType == 1) {
            // Swap message function type
            (ICrossRouter.SwapMessage memory swapMessage, uint256 srcActualKbp) = _decodeSwapMessage(payload);
            swapMessage.srcChainId = srcChainId;
            _receivedSwapMessages[srcChainId][swapMessage.id] = swapMessage;

            _router.swapRemote(
                swapMessage.srcPoolId,
                swapMessage.dstPoolId,
                srcChainId,
                swapMessage.receiver,
                swapMessage.amount,
                swapMessage.fee,
                swapMessage.vouchers,
                swapMessage.optimalDstBandwidth,
                srcActualKbp
            );
            emit SwapMessageReceived(swapMessage);
        } else if (functionType == 2) {
            // Liquidity message function type
            (ICrossRouter.LiquidityMessage memory liquidityMessage, uint256 srcActualKbp) =
                _decodeLiquidityMessage(payload);
            _receivedLiquidityMessages[srcChainId][liquidityMessage.id] = liquidityMessage;
            _router.receiveVouchers(
                srcChainId,
                liquidityMessage.srcPoolId,
                liquidityMessage.dstPoolId,
                liquidityMessage.vouchers,
                liquidityMessage.optimalDstBandwidth,
                false,
                srcActualKbp
            );
            emit LiquidityMessageReceived(liquidityMessage);
        }
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _decodeSwapMessage(bytes calldata payload)
        private
        pure
        returns (ICrossRouter.SwapMessage memory swapMessage, uint256 srcActualKbp)
    {
        assembly ("memory-safe") {
            // Get our first payload chunk
            // We are prefering a dataload instead of copy here since it help us clean the upper bytes for each values
            let firstPayloadChunk := calldataload(payload.offset)

            // reserve a slot for the srcChainId
            mstore(swapMessage, 0x00)

            // src pool id -> 232 bytes offset (8 for function selector, then 16 since uint16)
            mstore(add(swapMessage, 0x20), and(shr(232, firstPayloadChunk), 0xffff))

            // dst pool id -> 216 bytes offset (232 - 16 since uint16)
            mstore(add(swapMessage, 0x40), and(shr(216, firstPayloadChunk), 0xffff))

            // receiver
            mstore(add(swapMessage, 0x60), and(shr(56, firstPayloadChunk), 0xffffffffffffffffffffffffffffffffffffffff))

            // Call all the other bytes -> offset a 0x19, since we have 8 bytes remaining avec the address, and since
            // packed it uses all the bytes available
            // Starting at amount slot (0x80) - amount, then Fee's, Vouchers, optimalDstBandwidth, id, so 5 bytes32 slot
            // to copy,
            // so 256
            calldatacopy(add(swapMessage, 0x80), add(payload.offset, 0x19), 0xa0)
        }

        swapMessage.payload = payload[185:payload.length - 32];

        bytes memory x = payload[payload.length - 32:payload.length];
        assembly {
            srcActualKbp := mload(add(0x20, x))
        }
    }

    function _decodeLiquidityMessage(bytes calldata callDataPayload)
        private
        pure
        returns (ICrossRouter.LiquidityMessage memory liquidityMessage, uint256 srcActualKbp)
    {
        assembly ("memory-safe") {
            let firstPayloadChunk := calldataload(callDataPayload.offset)
            // src pool id -> 232 bytes offset (8 for function selector, then 16 since uint16)
            mstore(liquidityMessage, and(shr(232, firstPayloadChunk), 0xffff))

            // dst pool id -> 216 bytes offset (232 - 16 since uint16)
            mstore(add(liquidityMessage, 0x20), and(shr(216, firstPayloadChunk), 0xffff))

            // vouchers, optimalDstBandwidth, id, 5 bytes offset cause of function selector, src pool and dst pool
            calldatacopy(add(liquidityMessage, 0x40), add(callDataPayload.offset, 5), 0x60)
        }

        bytes memory x = callDataPayload[callDataPayload.length - 32:callDataPayload.length];
        assembly {
            srcActualKbp := mload(add(0x20, x))
        }
    }

    /*//////////////////////////////////////////////////////////////
                           GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IBridgeAxelar
     */
    function getRouter() external view returns (ICrossRouter) {
        return _router;
    }

    /**
     * @inheritdoc IBridgeAxelar
     */
    function getBridgeLookup(uint16 chainId) external view override returns (string memory) {
        return _bridgeLookup[chainId];
    }

    function getChainName(uint16 chainId) external view returns (string memory) {
        return _chainLookup[chainId];
    }

    /**
     * @inheritdoc IBridgeAxelar
     */
    function getGasLookup(uint16 chainId, MESSAGE_TYPE messageType) external view returns (uint256) {
        return _gasLookup[chainId][messageType];
    }

    /**
     * @inheritdoc IBridgeAxelar
     */

    function getFailedMessages(
        uint16 chainId,
        bytes memory bridgeAddress,
        uint64 nonce
    )
        external
        view
        returns (bytes32)
    {
        return _failedMessages[chainId][bridgeAddress][nonce];
    }

    /**
     * @inheritdoc IBridgeAxelar
     */
    function getReceivedSwaps(
        uint16 srcChain,
        bytes32 id
    )
        external
        view
        override
        returns (ICrossRouter.SwapMessage memory)
    {
        return _receivedSwapMessages[srcChain][id];
    }

    /**
     * @inheritdoc IBridgeAxelar
     */
    function getReceivedLiquidity(
        uint16 srcChain,
        bytes32 id
    )
        external
        view
        override
        returns (ICrossRouter.LiquidityMessage memory)
    {
        return _receivedLiquidityMessages[srcChain][id];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IAsset {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function release(address to, uint256 amount) external;
    function token() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ILayerZeroReceiver } from "./ILayerZeroReceiver.sol";
import { ILayerZeroEndpoint } from "./ILayerZeroEndpoint.sol";
import { ILayerZeroUserApplicationConfig } from "./ILayerZeroUserApplicationConfig.sol";
import { ICrossRouter } from "./ICrossRouter.sol";
import { Shared } from "./../libraries/Shared.sol";

/**
 * @title IBridge
 * @notice Interface for the Bridge contract.
 */
interface IBridge is Shared, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    /*//////////////////////////////////////////////////////////////
                           Events And Errors
    //////////////////////////////////////////////////////////////*/
    event MessageDispatched(
        uint16 indexed chainId, MESSAGE_TYPE indexed messageType, address indexed refundAddress, bytes payload
    );

    event MessageFailed(uint16 srcChainId, bytes srcAddress, uint64 nonce, bytes payload);
    event SwapMessageReceived(ICrossRouter.SwapMessage message);
    event LiquidityMessageReceived(ICrossRouter.LiquidityMessage message);

    error InsuficientFee(uint256);
    error NotLayerZero();
    error InsufficientAccess();
    error BridgeMismatch();
    error SliceOverflow();
    error SliceBoundsError();
    error InvalidOp();
    error InvalidEndpoint();
    error InvalidRouter();

    /**
     * @notice This function returns the version of the Bridge contract.
     * @return The version of the Bridge contract.
     */
    function VERSION() external returns (uint16);

    /**
     * @notice This function receives a message from Layer Zero.
     * @param srcChainId ID of the source chain.
     * @param srcAddress Address of the source chain.
     * @param payload Payload of the message.
     */
    function lzReceive(uint16 srcChainId, bytes calldata srcAddress, uint64, bytes calldata payload) external;

    /**
     * @notice This function returns the next nonce for a destination chain.
     * @param dstChain ID of the destination chain.
     * @return nextNonce Next nonce value.
     */
    function nextNonce(uint16 dstChain) external view returns (uint256);

    /**
     * @notice This function returns the received swap message for a specific source chain and ID.
     * @param srcChainId Source chain ID.
     * @param id Swap message ID.
     * @return swapMessage The received swap message.
     */
    function getReceivedSwaps(uint16 srcChainId, bytes32 id) external view returns (ICrossRouter.SwapMessage memory);

    /**
     * @notice This function returns the received liquidity message for a specific source chain and ID.
     * @param srcChain Source chain ID.
     * @param id Liquidity message ID.
     * @return liquidityMessage The received liquidity message.
     */
    function getReceivedLiquidity(
        uint16 srcChain,
        bytes32 id
    )
        external
        view
        returns (ICrossRouter.LiquidityMessage memory);

    /**
     * @notice This function dispatches a message to a specific chain using the Layer Zero endpoint.
     * @param chainId ID of the target chain.
     * @param messageType Type of the message (Swap or Liquidity).
     * @param refundAddress Address to receive refunds (if any).
     * @param payload Payload of the message.
     */
    function dispatchMessage(
        uint16 chainId,
        MESSAGE_TYPE messageType,
        address payable refundAddress,
        bytes memory payload
    )
        external
        payable;

    /**
     * @notice This function returns the fee for sending a message on-chain.
     * @param chainId ID of the target chain.
     * @param messageType Type of the message (Swap or Liquidity).
     * @param payload Payload of the message.
     * @return estimatedFee Estimated fee for sending the message.
     * @return gasAmount Forwarded gas amount for the message.
     */
    function quoteLayerZeroFee(
        uint16 chainId,
        MESSAGE_TYPE messageType,
        bytes memory payload
    )
        external
        view
        returns (uint256, uint256);

    /**
     * @notice This function returns the router contract.
     * @return router The router contract.
     */
    function getRouter() external view returns (ICrossRouter);

    /**
     * @notice This function returns the bridge address for a specific chain.
     * @param chainId ID of the chain.
     * @return bridgeAddress The bridge address.
     */
    function getBridgeLookup(uint16 chainId) external view returns (bytes memory);

    /**
     * @notice This function returns the forwarded gas amount for a specific chain and message type.
     * @param chainId ID of the chain.
     * @param messageType Type of the message (Swap or Liquidity).
     * @return gasAmount The forwarded gas amount.
     */
    function getGasLookup(uint16 chainId, MESSAGE_TYPE messageType) external view returns (uint256);

    /**
     * @notice This function returns the failed message for a specific chain, bridge address, and nonce.
     * @param chainId ID of the chain.
     * @param bridgeAddress Bridge address in bytes format.
     * @param nonce Nonce of the message.
     * @return payload The payload of the failed message.
     */
    function getFailedMessages(
        uint16 chainId,
        bytes memory bridgeAddress,
        uint64 nonce
    )
        external
        view
        returns (bytes32);

    /**
     * @notice This function sets the bridge address for a specific chain.
     * @param chainId ID of the chain.
     * @param bridgeAddress Address of the bridge contract on the specified chain.
     */
    function setBridge(uint16 chainId, bytes calldata bridgeAddress) external;

    /**
     * @notice This function sets the router contract address.
     * @param newRouter Address of the new router contract.
     */
    function setRouter(ICrossRouter newRouter) external;

    /**
     * @notice This function sets the forwarded gas amount for a specific chain and message type.
     * @param chainId ID of the chain.
     * @param functionType Type of the message (Swap or Liquidity).
     * @param gasAmount Forwarded gas amount.
     */
    function setForwardedGas(uint16 chainId, MESSAGE_TYPE functionType, uint256 gasAmount) external;

    /**
     * @notice This function forces the resumption of message receiving on Layer Zero.
     * @param srcChainId ID of the source chain.
     * @param srcAddress Address of the source chain.
     */
    function forceResumeReceive(uint16 srcChainId, bytes calldata srcAddress) external;

    /**
     * @notice This function sets the configuration for a specific version, chain, and config type.
     * @param version Version of the configuration.
     * @param chainId ID of the chain.
     * @param configType Type of the configuration.
     * @param config Configuration data.
     */
    function setConfig(uint16 version, uint16 chainId, uint256 configType, bytes calldata config) external;

    /**
     * @notice This function sets the send version for Layer Zero.
     * @param version Version to set.
     */
    function setSendVersion(uint16 version) external;

    /**
     * @notice This function sets the receive version for Layer Zero.
     * @param version Version to set.
     */
    function setReceiveVersion(uint16 version) external;
    /**
     * @dev Returns the Layer Zero endpoint contract.
     * @notice This function returns the Layer Zero endpoint contract.
     * @return layerZeroEndpoint The Layer Zero endpoint contract.
     */
    function getLayerZeroEndpoint() external view returns (ILayerZeroEndpoint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ICrossRouter } from "./ICrossRouter.sol";
import { Shared } from "./../libraries/Shared.sol";

/**
 * @title IBridgeAxelar
 * @notice Interface for the Bridge contract.
 */
interface IBridgeAxelar is Shared {
    /*//////////////////////////////////////////////////////////////
                           Events And Errors
    //////////////////////////////////////////////////////////////*/
    event MessageDispatched(
        uint16 indexed chainId, MESSAGE_TYPE indexed messageType, address indexed refundAddress, bytes payload
    );

    event MessageFailed(uint16 srcChainId, bytes srcAddress, uint64 nonce, bytes payload);
    event SwapMessageReceived(ICrossRouter.SwapMessage message);
    event LiquidityMessageReceived(ICrossRouter.LiquidityMessage message);

    error InsuficientFee(uint256);
    error NotLayerZero();
    error InsufficientAccess();
    error BridgeMismatch();
    error SliceOverflow();
    error SliceBoundsError();
    error InvalidOp();
    error InvalidEndpoint();
    error InvalidRouter();

    /**
     * @notice This function returns the version of the Bridge contract.
     * @return The version of the Bridge contract.
     */
    function VERSION() external returns (uint16);

    /**
     * @notice This function returns the received swap message for a specific source chain and ID.
     * @param srcChainId Source chain ID.
     * @param id Swap message ID.
     * @return swapMessage The received swap message.
     */
    function getReceivedSwaps(uint16 srcChainId, bytes32 id) external view returns (ICrossRouter.SwapMessage memory);

    /**
     * @notice This function returns the received liquidity message for a specific source chain and ID.
     * @param srcChain Source chain ID.
     * @param id Liquidity message ID.
     * @return liquidityMessage The received liquidity message.
     */
    function getReceivedLiquidity(
        uint16 srcChain,
        bytes32 id
    )
        external
        view
        returns (ICrossRouter.LiquidityMessage memory);

    /**
     * @notice This function dispatches a message to a specific chain using the Layer Zero endpoint.
     * @param chainId ID of the target chain.
     * @param messageType Type of the message (Swap or Liquidity).
     * @param refundAddress Address to receive refunds (if any).
     * @param payload Payload of the message.
     */
    function dispatchMessage(
        uint16 chainId,
        MESSAGE_TYPE messageType,
        address payable refundAddress,
        bytes memory payload
    )
        external
        payable;

    /**
     * @notice This function returns the router contract.
     * @return router The router contract.
     */
    function getRouter() external view returns (ICrossRouter);

    /**
     * @notice This function returns the bridge address for a specific chain.
     * @param chainId ID of the chain.
     * @return bridgeAddress The bridge address.
     */
    function getBridgeLookup(uint16 chainId) external view returns (string memory);

    /**
     * @notice This function returns the failed message for a specific chain, bridge address, and nonce.
     * @param chainId ID of the chain.
     * @param bridgeAddress Bridge address in bytes format.
     * @param nonce Nonce of the message.
     * @return payload The payload of the failed message.
     */
    function getFailedMessages(
        uint16 chainId,
        bytes memory bridgeAddress,
        uint64 nonce
    )
        external
        view
        returns (bytes32);

    /**
     * @notice This function sets the bridge address for a specific chain.
     * @param chainId ID of the chain.
     * @param bridgeAddress Address of the bridge contract on the specified chain.
     */
    function setBridge(uint16 chainId, string calldata bridgeAddress) external;

    /**
     * @notice This function sets the router contract address.
     * @param newRouter Address of the new router contract.
     */
    function setRouter(ICrossRouter newRouter) external;

    /**
     * @notice This function sets the forwarded gas amount for a specific chain and message type.
     * @param chainId ID of the chain.
     * @param functionType Type of the message (Swap or Liquidity).
     * @param gasAmount Forwarded gas amount.
     */
    function setForwardedGas(uint16 chainId, MESSAGE_TYPE functionType, uint256 gasAmount) external;

    function getGasLookup(uint16 chainId, MESSAGE_TYPE messageType) external view returns (uint256);

    function addNativeGas(bytes32 txHash, uint256 logIndex, address refundAddress) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Shared } from "../libraries/Shared.sol";
import { IBridge } from "./IBridge.sol";
import { ReentrancyGuard } from "../libraries/ReentrancyGuard.sol";

import { IFeeHandler } from "./IFeeHandler.sol";
import { ICrossRouter } from "./ICrossRouter.sol";
import { IAsset } from "./IAsset.sol";
import { IFeeCollectorV2 } from "./IFeeCollectorV2.sol";

interface ICrossRouter is Shared {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct ChainPath {
        // Storage slot one
        bool active; // Mask: 0x0f
        uint16 srcPoolId; // Mask: 0xffff
        uint16 dstChainId; // Mask: 0xffff
        uint16 dstPoolId; // Mask: 0xffff
        uint16 weight; // Mask: 0xffff
        address poolAddress; // Mask: 0xffffffffffffffffffff Equivalent to uint160
        // Second storage slot
        uint256 bandwidth; // local bandwidth
        uint256 actualBandwidth; // local bandwidth
        uint256 kbp; // kbp = Known Bandwidth Proof dst bandwidth
        uint256 actualKbp; // kbp = Known Bandwidth Proof dst bandwidth
        uint256 vouchers;
        uint256 optimalDstBandwidth; // optimal dst bandwidth
    }

    struct SwapParams {
        uint16 srcPoolId; // Mask: 0xffff
        uint16 dstPoolId; // Mask: 0xffff
        uint16 dstChainId; // Mask: 0xffff  // Remain 208 bits
        address to;
        uint256 amount;
        uint256 minAmount;
        address payable refundAddress;
        bytes payload;
    }

    struct VoucherObject {
        uint256 vouchers;
        uint256 optimalDstBandwidth;
        bool swap;
    }

    struct PoolObject {
        uint16 poolId;
        address poolAddress;
        uint256 totalWeight;
        uint256 totalLiquidity;
        uint256 undistributedVouchers;
    }

    struct ChainData {
        uint16 srcPoolId;
        uint16 srcChainId;
        uint16 dstPoolId;
        uint16 dstChainId;
    }

    struct SwapMessage {
        uint16 srcChainId;
        uint16 srcPoolId;
        uint16 dstPoolId;
        address receiver;
        uint256 amount;
        uint256 fee;
        uint256 vouchers;
        uint256 optimalDstBandwidth;
        bytes32 id;
        bytes payload;
    }

    struct ReceiveSwapMessage {
        uint16 srcPoolId;
        uint16 dstPoolId;
        uint16 srcChainId;
        address receiver;
        uint256 amount;
        uint256 fee;
        uint256 vouchers;
        uint256 optimalDstBandwidth;
    }

    struct LiquidityMessage {
        uint16 srcPoolId;
        uint16 dstPoolId;
        uint256 vouchers;
        uint256 optimalDstBandwidth;
        bytes32 id;
    }

    /**
     * @notice Swaps crosschain assets
     * @dev Cashmere is leveraging fragmented liquidity pools to crossswap assets. The slippage takes into account the
     * src bandwidth and dst bandwidth to calculate how many assets it should send. Fees will be calculated on src but
     * taken out of the dst chain.
     * @param swapParams The swap parameters
     *                       struct SwapParams {
     *                         uint16 srcPoolId;                   <= source pool id
     *                         uint16 dstPoolId;                   <= destination pool id
     *                         uint16 dstChainId;                  <= destination chain
     *                         address to;                         <= where to release the liquidity on dst
     *                         uint256 amount;                     <= the amount preferred for swap
     *                         uint256 minAmount;                  <= the minimum amount accepted for swap
     *                         address payable refundAddress;      <= refund cross-swap fee
     *                         bytes payload;                      <= payload to send to the destination chain
     *                     }
     * @return swapId The swap id
     */
    function swap(SwapParams memory swapParams) external payable returns (bytes32 swapId);

    /**
     * @notice Deposits liquidity to a pool
     * @dev The amount deposited will be wrapped to the pool asset and the user will receive the same amount of assets -
     * fees
     * @param to The address to receive the assets
     * @param poolId The pool id
     * @param amount The amount to deposit
     */
    function deposit(address to, uint16 poolId, uint256 amount) external;

    /**
     * @notice Redeems liquidity from a pool
     * @dev The amount redeemed will be unwrapped from the pool asset
     * @param to The address to receive the assets
     * @param poolId The pool id
     * @param amount The amount to redeem
     */
    function redeemLocal(address to, uint16 poolId, uint256 amount) external;

    /**
     * @notice Syncs a pool with the current liquidity distribution
     * @dev We have this function in case it needs to be triggered manually
     * @param poolId The pool id
     */
    function sync(uint16 poolId) external;

    /**
     * @notice Sends vouchers to the destination chain
     * @dev This function is called by the bridge contract when a voucher message is received
     * @param srcPoolId The source pool id
     * @param dstChainId The destination chain id
     * @param dstPoolId The destination chain id
     * @param refundAddress The refund address for cross-swap fee
     */
    function sendVouchers(
        uint16 srcPoolId,
        uint16 dstChainId,
        uint16 dstPoolId,
        address payable refundAddress
    )
        external
        payable
        returns (bytes32 messageId);

    /**
     * @notice Called by the bridge when a swap message is received
     * @param srcPoolId The pool id of the source pool
     * @param dstPoolId The pool id of the destination pool
     * @param srcChainId The chain id of the source chain
     * @param to The address to receive the assets
     * @param amount The amount that needs to be received
     * @param fee The fee that it will be collected
     * @param vouchers The amount of vouchers that were sent from src and distributed to dst
     * @param optimalDstBandwidth The optimal bandwidth that should be received so we can sync it
     */
    function swapRemote(
        uint16 srcPoolId,
        uint16 dstPoolId,
        uint16 srcChainId,
        address to,
        uint256 amount,
        uint256 fee,
        uint256 vouchers,
        uint256 optimalDstBandwidth,
        uint256 srcActualKbp
    )
        external;

    /**
     * @notice Called by the bridge when vouchers are received
     * @param srcChainId The chain id of the source chain
     * @param srcPoolId The pool id of the source pool
     * @param dstPoolId The pool id of the destination pool
     * @param vouchers The amount of vouchers that were sent from src and distributed to dst
     * @param optimalDstBandwidth The optimal bandwidth that should be received so we can sync it
     * @param isSwap Whether or not the liquidity comes from a swap or not
     */
    function receiveVouchers(
        uint16 srcChainId,
        uint16 srcPoolId,
        uint16 dstPoolId,
        uint256 vouchers,
        uint256 optimalDstBandwidth,
        bool isSwap,
        uint256 srcActualKbp
    )
        external;

    /**
     * @notice Quotes a possible cross swap
     * @dev Check swap method for swapParams explanation
     * @param swapParams The swap parameters
     * @return amount The amount of tokens that would be received
     * @return fee The fee that would be paid
     */
    function quoteSwap(SwapParams calldata swapParams) external view returns (uint256 amount, uint256 fee);

    /**
     * @notice returns the effective path to move funds from A to B
     * @param dstChainId the destination chain id
     * @param amountToSimulate the amount to simulate to get the right path
     * @return effectivePath the effective path to move funds from A to B which represents poolId A and poolId B
     */
    function getEffectivePath(
        uint16 dstChainId,
        uint256 amountToSimulate
    )
        external
        view
        returns (uint16[2] memory effectivePath);

    function getChainPathPublic(
        uint16 srcPoolId,
        uint16 dstChainId,
        uint16 dstPoolId
    )
        external
        view
        returns (ChainPath memory path);

    function getPool(uint16 _poolId) external view returns (PoolObject memory);

    function poolIdsPerChain(uint16 chainId) external view returns (uint16[] memory);

    function getChainPathsLength(uint16 poolId) external view returns (uint256);

    function getPaths(uint16 _poolId) external view returns (ChainPath[] memory);

    function chainPathIndexLookup(bytes32 key) external view returns (uint256);

    function getFeeHandler() external view returns (IFeeHandler);

    function getFeeCollector() external view returns (IFeeCollectorV2);

    function getBridge() external view returns (IBridge);

    function getChainId() external view returns (uint16);

    function getBridgeVersion() external view returns (uint16);

    function getSyncDeviation() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                                EVENTS AND ERRORS
    //////////////////////////////////////////////////////////////*/
    event CrossChainSwapInitiated(
        address indexed sender,
        bytes32 id,
        uint16 srcPoolId,
        uint16 dstChainId,
        uint16 dstPoolId,
        uint256 expectedAmount,
        uint256 actualAmount,
        uint256 fee,
        uint256 vouchers,
        uint256 optimalDstBandwidth,
        bytes payload
    );
    event CrossChainSwapPerformed(
        uint16 srcPoolId, uint16 dstPoolId, uint16 srcChainId, address to, uint256 amount, uint256 fee
    );
    event CrossChainLiquidityInitiated(
        address indexed sender,
        bytes32 id,
        uint16 srcPoolId,
        uint16 dstChainId,
        uint16 dstPoolId,
        uint256 vouchers,
        uint256 optimalDstBandwidth
    );
    event CrossChainLiquidityPerformed(LiquidityMessage message);
    event SendVouchers(uint16 dstChainId, uint16 dstPoolId, uint256 vouchers, uint256 optimalDstBandwidth);
    event VouchersReceived(uint16 chainId, uint16 srcPoolId, uint256 amount, uint256 optimalDstBandwidth);
    event SwapRemote(address to, uint256 amount, uint256 fee);
    event ChainPathUpdate(uint16 srcPoolId, uint16 dstChainId, uint16 dstPoolId, uint256 weight);
    event ChainActivated(uint16 srcPoolId, uint16 dstChainId, uint16 dstPoolId);
    event FeeHandlerUpdated(address oldFeeHandler, address newFeeHandler);
    event SyncDeviationUpdated(uint256 oldDeviation, uint256 newDeviation);
    event FeeCollected(uint256 fee);
    event AssetDeposited(address indexed to, uint16 poolId, uint256 amount);
    event AssetRedeemed(address indexed from, uint16 poolId, uint256 amount);
    event PoolSynced(uint16 poolId, uint256 distributedVouchers);
    event BridgeUpdated(IBridge oldBridge, IBridge newBridge);

    error InactiveChainPath();
    error ActiveChainPath();
    error UnknownChainPath();
    error InsufficientLiquidity();
    error SlippageTooHigh();
    error SrcBandwidthTooLow();
    error DstBandwidthTooLow();
    error ChainPathExists();
    error FeeLibraryZero();
    error SyncDeviationTooHigh();
    error NotEnoughLiquidity();
    error AmountZero();
    error UnknownPool();
    error MathOverflow();
    error InsufficientSrcLiquidity();
    error InsufficientDstLiquidity();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IAsset } from "./IAsset.sol";

interface IFeeCollectorV2 {
    function collectFees(IAsset asset_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ICrossRouter } from "./ICrossRouter.sol";

interface IFeeHandler {
    /**
     * @notice Apply slippage algorithm to an amount using bandwidth and optimal bandwidth of both src and dst
     * @param amount Amount we apply the slippage for
     * @param bandwidthSrc Bandwidth of the source pool
     * @param optimalBandwithDst Optimal bandwidth of the destination pool
     * @param bandwithDst Bandwidth of the destination pool
     * @param optimalBandwithSrc Optimal bandwidth of the source pool
     * @return actualAmount The amount after applying slippage
     * @return fee The fee amount
     */
    function applySlippage(
        uint256 amount,
        uint256 bandwidthSrc,
        uint256 optimalBandwithDst,
        uint256 bandwithDst,
        uint256 optimalBandwithSrc
    )
        external
        view
        returns (uint256 actualAmount, uint256 fee);

    /**
     * @notice Compute the compensation ratio for a given bandwidth and optimal bandwidth
     * @param bandwidth Bandwidth of a pool
     * @param optimalBandwidth Optimal bandwidth of a pool
     * @return compensationRatio The compensation ratio
     */
    function getCompensatioRatio(
        uint256 bandwidth,
        uint256 optimalBandwidth
    )
        external
        pure
        returns (uint256 compensationRatio);

    function swapFee() external view returns (uint256);

    function mintFee() external view returns (uint256);

    function burnFee() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the
    // additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. ie: pay for a specified destination gasAmount, or
    // receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    )
        external
        payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    )
        external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    )
        external
        view
        returns (uint256 nativeFee, uint256 zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint256 _configType
    )
        external
        view
        returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    )
        external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint256 _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Reviewed reetrancy guard for better gas optimisation
 * @author @KONFeature
 * Based from solidity ReetrancyGuard :
 * https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/security/ReentrancyGuard.sol
 */
abstract contract ReentrancyGuard {
    /* -------------------------------------------------------------------------- */
    /*                                  Constants                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Not entered function status
    uint256 private constant _NOT_ENTERED = 1;
    /// @dev Entered function status
    uint256 private constant _ENTERED = 2;

    /* -------------------------------------------------------------------------- */
    /*                                   Error's                                  */
    /* -------------------------------------------------------------------------- */

    /// @dev Error if function is reentrant
    error ReetrantCall();

    /// @dev 'bytes4(keccak256("ReetrantCall()"))'
    uint256 private constant _REETRANT_CALL_SELECTOR = 0x920856a0;

    /* -------------------------------------------------------------------------- */
    /*                                   Storage                                  */
    /* -------------------------------------------------------------------------- */

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
        assembly ("memory-safe") {
            // Check if not re entrant
            if eq(sload(_status.slot), _ENTERED) {
                mstore(0x00, _REETRANT_CALL_SELECTOR)
                revert(0x1c, 0x04)
            }

            // Any calls to nonReentrant after this point will fail
            sstore(_status.slot, _ENTERED)
        }
        _;
        // Reset the reentrant slot
        assembly ("memory-safe") {
            sstore(_status.slot, _NOT_ENTERED)
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                           Internal view function                           */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface Shared {
    enum MESSAGE_TYPE {
        NONE,
        SWAP,
        ADD_LIQUIDITY
    }
}