// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ICallProxy {

    /// @dev Chain from which the current submission is received
    function submissionChainIdFrom() external view returns (uint256);
    /// @dev Native sender of the current submission
    function submissionNativeSender() external view returns (bytes memory);

    /// @dev Used for calls where native asset transfer is involved.
    /// @param _reserveAddress Receiver of the tokens if the call to _receiver fails
    /// @param _receiver Contract to be called
    /// @param _data Call data
    /// @param _flags Flags to change certain behavior of this function, see Flags library for more details
    /// @param _nativeSender Native sender
    /// @param _chainIdFrom Id of a chain that originated the request
    function call(
        address _reserveAddress,
        address _receiver,
        bytes memory _data,
        uint256 _flags,
        bytes memory _nativeSender,
        uint256 _chainIdFrom
    ) external payable returns (bool);

    /// @dev Used for calls where ERC20 transfer is involved.
    /// @param _token Asset address
    /// @param _reserveAddress Receiver of the tokens if the call to _receiver fails
    /// @param _receiver Contract to be called
    /// @param _data Call data
    /// @param _flags Flags to change certain behavior of this function, see Flags library for more details
    /// @param _nativeSender Native sender
    /// @param _chainIdFrom Id of a chain that originated the request
    function callERC20(
        address _token,
        address _reserveAddress,
        address _receiver,
        bytes memory _data,
        uint256 _flags,
        bytes memory _nativeSender,
        uint256 _chainIdFrom
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDeBridgeGate {
    /* ========== STRUCTS ========== */

    struct TokenInfo {
        uint256 nativeChainId;
        bytes nativeAddress;
    }

    struct DebridgeInfo {
        uint256 chainId; // native chain id
        uint256 maxAmount; // maximum amount to transfer
        uint256 balance; // total locked assets
        uint256 lockedInStrategies; // total locked assets in strategy (AAVE, Compound, etc)
        address tokenAddress; // asset address on the current chain
        uint16 minReservesBps; // minimal hot reserves in basis points (1/10000)
        bool exist;
    }

    struct DebridgeFeeInfo {
        uint256 collectedFees; // total collected fees
        uint256 withdrawnFees; // fees that already withdrawn
        mapping(uint256 => uint256) getChainFee; // whether the chain for the asset is supported
    }

    struct ChainSupportInfo {
        uint256 fixedNativeFee; // transfer fixed fee
        bool isSupported; // whether the chain for the asset is supported
        uint16 transferFeeBps; // transfer fee rate nominated in basis points (1/10000) of transferred amount
    }

    struct DiscountInfo {
        uint16 discountFixBps; // fix discount in BPS
        uint16 discountTransferBps; // transfer % discount in BPS
    }

    /// @param executionFee Fee paid to the transaction executor.
    /// @param fallbackAddress Receiver of the tokens if the call fails.
    struct SubmissionAutoParamsTo {
        uint256 executionFee;
        uint256 flags;
        bytes fallbackAddress;
        bytes data;
    }

    /// @param executionFee Fee paid to the transaction executor.
    /// @param fallbackAddress Receiver of the tokens if the call fails.
    struct SubmissionAutoParamsFrom {
        uint256 executionFee;
        uint256 flags;
        address fallbackAddress;
        bytes data;
        bytes nativeSender;
    }

    struct FeeParams {
        uint256 receivedAmount;
        uint256 fixFee;
        uint256 transferFee;
        bool useAssetFee;
        bool isNativeToken;
    }

    /* ========== PUBLIC VARS GETTERS ========== */

    /// @dev Returns whether the transfer with the submissionId was claimed.
    /// submissionId is generated in getSubmissionIdFrom
    function isSubmissionUsed(bytes32 submissionId) view external returns (bool);

    /// @dev Returns native token info by wrapped token address
    function getNativeInfo(address token) view external returns (
        uint256 nativeChainId,
        bytes memory nativeAddress);

    /// @dev Returns address of the proxy to execute user's calls.
    function callProxy() external view returns (address);

    /// @dev Fallback fixed fee in native asset, used if a chain fixed fee is set to 0
    function globalFixedNativeFee() external view returns (uint256);

    /// @dev Fallback transfer fee in BPS, used if a chain transfer fee is set to 0
    function globalTransferFeeBps() external view returns (uint16);

    /* ========== FUNCTIONS ========== */

    /// @dev Submits the message to the deBridge infrastructure to be broadcasted to another supported blockchain (identified by _dstChainId)
    ///      with the instructions to call the _targetContractAddress contract using the given _targetContractCalldata
    /// @notice NO ASSETS ARE BROADCASTED ALONG WITH THIS MESSAGE
    /// @notice DeBridgeGate only accepts submissions with msg.value (native ether) covering a small protocol fee
    ///         (defined in the globalFixedNativeFee property). Any excess amount of ether passed to this function is
    ///         included in the message as the execution fee - the amount deBridgeGate would give as an incentive to
    ///         a third party in return for successful claim transaction execution on the destination chain.
    /// @notice DeBridgeGate accepts a set of flags that control the behaviour of the execution. This simple method
    ///         sets the default set of flags: REVERT_IF_EXTERNAL_FAIL, PROXY_WITH_SENDER
    /// @param _dstChainId ID of the destination chain.
    /// @param _targetContractAddress A contract address to be called on the destination chain
    /// @param _targetContractCalldata Calldata to execute against the target contract on the destination chain
    function sendMessage(
        uint256 _dstChainId,
        bytes memory _targetContractAddress,
        bytes memory _targetContractCalldata
    ) external payable returns (bytes32 submissionId);

    /// @dev Submits the message to the deBridge infrastructure to be broadcasted to another supported blockchain (identified by _dstChainId)
    ///      with the instructions to call the _targetContractAddress contract using the given _targetContractCalldata
    /// @notice NO ASSETS ARE BROADCASTED ALONG WITH THIS MESSAGE
    /// @notice DeBridgeGate only accepts submissions with msg.value (native ether) covering a small protocol fee
    ///         (defined in the globalFixedNativeFee property). Any excess amount of ether passed to this function is
    ///         included in the message as the execution fee - the amount deBridgeGate would give as an incentive to
    ///         a third party in return for successful claim transaction execution on the destination chain.
    /// @notice DeBridgeGate accepts a set of flags that control the behaviour of the execution. This simple method
    ///         sets the default set of flags: REVERT_IF_EXTERNAL_FAIL, PROXY_WITH_SENDER
    /// @param _dstChainId ID of the destination chain.
    /// @param _targetContractAddress A contract address to be called on the destination chain
    /// @param _targetContractCalldata Calldata to execute against the target contract on the destination chain
    /// @param _flags A bitmask of toggles listed in the Flags library
    /// @param _referralCode Referral code to identify this submission
    function sendMessage(
        uint256 _dstChainId,
        bytes memory _targetContractAddress,
        bytes memory _targetContractCalldata,
        uint256 _flags,
        uint32 _referralCode
    ) external payable returns (bytes32 submissionId);

    /// @dev This method is used for the transfer of assets [from the native chain](https://docs.debridge.finance/the-core-protocol/transfers#transfer-from-native-chain).
    /// It locks an asset in the smart contract in the native chain and enables minting of deAsset on the secondary chain.
    /// @param _tokenAddress Asset identifier.
    /// @param _amount Amount to be transferred (note: the fee can be applied).
    /// @param _chainIdTo Chain id of the target chain.
    /// @param _receiver Receiver address.
    /// @param _permitEnvelope Permit for approving the spender by signature. bytes (amount + deadline + signature)
    /// @param _useAssetFee use assets fee for pay protocol fix (work only for specials token)
    /// @param _referralCode Referral code
    /// @param _autoParams Auto params for external call in target network
    function send(
        address _tokenAddress,
        uint256 _amount,
        uint256 _chainIdTo,
        bytes memory _receiver,
        bytes memory _permitEnvelope,
        bool _useAssetFee,
        uint32 _referralCode,
        bytes calldata _autoParams
    ) external payable returns (bytes32 submissionId) ;

    /// @dev Is used for transfers [into the native chain](https://docs.debridge.finance/the-core-protocol/transfers#transfer-from-secondary-chain-to-native-chain)
    /// to unlock the designated amount of asset from collateral and transfer it to the receiver.
    /// @param _debridgeId Asset identifier.
    /// @param _amount Amount of the transferred asset (note: the fee can be applied).
    /// @param _chainIdFrom Chain where submission was sent
    /// @param _receiver Receiver address.
    /// @param _nonce Submission id.
    /// @param _signatures Validators signatures to confirm
    /// @param _autoParams Auto params for external call
    function claim(
        bytes32 _debridgeId,
        uint256 _amount,
        uint256 _chainIdFrom,
        address _receiver,
        uint256 _nonce,
        bytes calldata _signatures,
        bytes calldata _autoParams
    ) external;

    /// @dev Withdraw collected fees to feeProxy
    /// @param _debridgeId Asset identifier.
    function withdrawFee(bytes32 _debridgeId) external;

    /// @dev Returns asset fixed fee value for specified debridge and chainId.
    /// @param _debridgeId Asset identifier.
    /// @param _chainId Chain id.
    function getDebridgeChainAssetFixedFee(
        bytes32 _debridgeId,
        uint256 _chainId
    ) external view returns (uint256);

    /* ========== EVENTS ========== */

    /// @dev Emitted once the tokens are sent from the original(native) chain to the other chain; the transfer tokens
    /// are expected to be claimed by the users.
    event Sent(
        bytes32 submissionId,
        bytes32 indexed debridgeId,
        uint256 amount,
        bytes receiver,
        uint256 nonce,
        uint256 indexed chainIdTo,
        uint32 referralCode,
        FeeParams feeParams,
        bytes autoParams,
        address nativeSender
        // bool isNativeToken //added to feeParams
    );

    /// @dev Emitted once the tokens are transferred and withdrawn on a target chain
    event Claimed(
        bytes32 submissionId,
        bytes32 indexed debridgeId,
        uint256 amount,
        address indexed receiver,
        uint256 nonce,
        uint256 indexed chainIdFrom,
        bytes autoParams,
        bool isNativeToken
    );

    /// @dev Emitted when new asset support is added.
    event PairAdded(
        bytes32 debridgeId,
        address tokenAddress,
        bytes nativeAddress,
        uint256 indexed nativeChainId,
        uint256 maxAmount,
        uint16 minReservesBps
    );

    event MonitoringSendEvent(
        bytes32 submissionId,
        uint256 nonce,
        uint256 lockedOrMintedAmount,
        uint256 totalSupply
    );

    event MonitoringClaimEvent(
        bytes32 submissionId,
        uint256 lockedOrMintedAmount,
        uint256 totalSupply
    );

    /// @dev Emitted when the asset is allowed/disallowed to be transferred to the chain.
    event ChainSupportUpdated(uint256 chainId, bool isSupported, bool isChainFrom);
    /// @dev Emitted when the supported chains are updated.
    event ChainsSupportUpdated(
        uint256 chainIds,
        ChainSupportInfo chainSupportInfo,
        bool isChainFrom);

    /// @dev Emitted when the new call proxy is set.
    event CallProxyUpdated(address callProxy);
    /// @dev Emitted when the transfer request is executed.
    event AutoRequestExecuted(
        bytes32 submissionId,
        bool indexed success,
        address callProxy
    );

    /// @dev Emitted when a submission is blocked.
    event Blocked(bytes32 submissionId);
    /// @dev Emitted when a submission is unblocked.
    event Unblocked(bytes32 submissionId);

    /// @dev Emitted when fee is withdrawn.
    event WithdrawnFee(bytes32 debridgeId, uint256 fee);

    /// @dev Emitted when globalFixedNativeFee and globalTransferFeeBps are updated.
    event FixedNativeFeeUpdated(
        uint256 globalFixedNativeFee,
        uint256 globalTransferFeeBps);

    /// @dev Emitted when globalFixedNativeFee is updated by feeContractUpdater
    event FixedNativeFeeAutoUpdated(uint256 globalFixedNativeFee);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

library Flags {

    /* ========== FLAGS ========== */

    /// @dev Flag to unwrap ETH
    uint256 public constant UNWRAP_ETH = 0;
    /// @dev Flag to revert if external call fails
    uint256 public constant REVERT_IF_EXTERNAL_FAIL = 1;
    /// @dev Flag to call proxy with a sender contract
    uint256 public constant PROXY_WITH_SENDER = 2;
    /// @dev Data is hash in DeBridgeGate send method
    uint256 public constant SEND_HASHED_DATA = 3;
    /// @dev First 24 bytes from data is gas limit for external call
    uint256 public constant SEND_EXTERNAL_CALL_GAS_LIMIT = 4;
    /// @dev Support multi send for externall call
    uint256 public constant MULTI_SEND = 5;

    /// @dev Get flag
    /// @param _packedFlags Flags packed to uint256
    /// @param _flag Flag to check
    function getFlag(
        uint256 _packedFlags,
        uint256 _flag
    ) internal pure returns (bool) {
        uint256 flag = (_packedFlags >> _flag) & uint256(1);
        return flag == 1;
    }

    /// @dev Set flag
    /// @param _packedFlags Flags packed to uint256
    /// @param _flag Flag to set
    /// @param _value Is set or not set
     function setFlag(
         uint256 _packedFlags,
         uint256 _flag,
         bool _value
     ) internal pure returns (uint256) {
         if (_value)
             return _packedFlags | uint256(1) << _flag;
         else
             return _packedFlags & ~(uint256(1) << _flag);
     }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

library SignatureUtil {
    /* ========== ERRORS ========== */

    error WrongArgumentLength();
    error SignatureInvalidLength();
    error SignatureInvalidV();

    /// @dev Prepares raw msg that was signed by the oracle.
    /// @param _submissionId Submission identifier.
    function getUnsignedMsg(bytes32 _submissionId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _submissionId));
    }

    /// @dev Splits signature bytes to r,s,v components.
    /// @param _signature Signature bytes in format r+s+v.
    function splitSignature(bytes memory _signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        if (_signature.length != 65) revert SignatureInvalidLength();
        return parseSignature(_signature, 0);
    }

    function parseSignature(bytes memory _signatures, uint256 offset)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        assembly {
            r := mload(add(_signatures, add(32, offset)))
            s := mload(add(_signatures, add(64, offset)))
            v := and(mload(add(_signatures, add(65, offset))), 0xff)
        }

        if (v < 27) v += 27;
        if (v != 27 && v != 28) revert SignatureInvalidV();
    }

    function toUint256(bytes memory _bytes, uint256 _offset)
        internal
        pure
        returns (uint256 result)
    {
        if (_bytes.length < _offset + 32) revert WrongArgumentLength();

        assembly {
            result := mload(add(add(_bytes, 0x20), _offset))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
        if (_initialized < type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
import "../proxy/utils/Initializable.sol";

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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

import "./math/MathUpgradeable.sol";

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
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@debridge-finance/debridge-contracts-v1/contracts/interfaces/IDeBridgeGate.sol";
import "@debridge-finance/debridge-contracts-v1/contracts/libraries/SignatureUtil.sol";
import "../interfaces/IERC20Permit.sol";
import "../libraries/BytesLib.sol";
import "../libraries/DlnOrderLib.sol";

abstract contract DlnBase is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;
    using SignatureUtil for bytes;

    /* ========== CONSTANTS ========== */

    /// @dev Basis points or bps, set to 10 000 (equal to 1/10000). Used to express relative values (fees)
    uint256 public constant BPS_DENOMINATOR = 10000;

    /// @dev Role allowed to stop transfers
    bytes32 public constant GOVMONITORING_ROLE =
        keccak256("GOVMONITORING_ROLE");

    uint256 public constant MAX_ADDRESS_LENGTH = 255;
    uint256 public constant EVM_ADDRESS_LENGTH = 20;
    uint256 public constant SOLANA_ADDRESS_LENGTH = 32;

    /* ========== STATE VARIABLES ========== */

    // @dev Maps chainId => type of chain engine
    mapping(uint256 => DlnOrderLib.ChainEngine) public chainEngines;

    IDeBridgeGate public deBridgeGate;

    /* ========== ERRORS ========== */

    error AdminBadRole();
    error CallProxyBadRole();
    error GovMonitoringBadRole();
    error NativeSenderBadRole(bytes nativeSender, uint256 chainIdFrom);
    error MismatchedTransferAmount();
    error MismatchedOrderId();
    error WrongAddressLength();
    error ZeroAddress();
    error NotSupportedDstChain();
    error EthTransferFailed();
    error Unauthorized();
    error IncorrectOrderStatus();
    error WrongChain();
    error WrongArgument();
    error UnknownEngine();
    
    /* ========== EVENTS ========== */

    /* ========== MODIFIERS ========== */

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert AdminBadRole();
        _;
    }

    modifier onlyGovMonitoring() {
        if (!hasRole(GOVMONITORING_ROLE, msg.sender))
            revert GovMonitoringBadRole();
        _;
    }

    /* ========== CONSTRUCTOR  ========== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __DlnBase_init(IDeBridgeGate _deBridgeGate) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __DlnBase_init_unchained(_deBridgeGate);
    }

    function __DlnBase_init_unchained(IDeBridgeGate _deBridgeGate)
        internal
        initializer
    {
        deBridgeGate = _deBridgeGate;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /* ========== ADMIN METHODS ========== */

    /// @dev Stop all protocol.
    function pause() external onlyGovMonitoring {
        _pause();
    }

    /// @dev Unlock protocol.
    function unpause() external onlyAdmin {
        _unpause();
    }

    /* ========== INTERNAL ========== */

    function _executePermit(address _tokenAddress, bytes memory _permitEnvelope)
        internal
    {
        if (_permitEnvelope.length > 0) {
            uint256 permitAmount = BytesLib.toUint256(_permitEnvelope, 0);
            uint256 deadline = BytesLib.toUint256(_permitEnvelope, 32);
            (bytes32 r, bytes32 s, uint8 v) = _permitEnvelope.parseSignature(64);
            IERC20Permit(_tokenAddress).permit(
                msg.sender,
                address(this),
                permitAmount,
                deadline,
                v,
                r,
                s
            );
        }
    }

    /// @dev Safe transfer tokens and check that receiver will receive exact amount (check only if to != from)
    function _safeTransferFrom(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        IERC20Upgradeable token = IERC20Upgradeable(_tokenAddress);
        uint256 balanceBefore = token.balanceOf(_to);
        token.safeTransferFrom(_from, _to, _amount);
        // Received real amount
        uint256 receivedAmount = token.balanceOf(_to) - balanceBefore;
        if (_from != _to && _amount != receivedAmount) revert MismatchedTransferAmount();
    }

    /*
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (!success) revert EthTransferFailed();
    }

    /// @dev Transfer ETH or token
    /// @param tokenAddress address(0) to transfer ETH
    /// @param to  recipient of the transfer
    /// @param value the amount to send
    function _safeTransferEthOrToken(address tokenAddress, address to, uint256 value) internal {
        if (tokenAddress == address(0)) {
            _safeTransferETH(to, value);
        }
        else {
             IERC20Upgradeable(tokenAddress).safeTransfer(to, value);
        }
    }

    function _encodeOrder(DlnOrderLib.Order memory _order)
        internal
        pure
        returns (bytes memory encoded)
    {
        {
            if (
                _order.makerSrc.length > MAX_ADDRESS_LENGTH ||
                _order.giveTokenAddress.length > MAX_ADDRESS_LENGTH ||
                _order.takeTokenAddress.length > MAX_ADDRESS_LENGTH ||
                _order.receiverDst.length > MAX_ADDRESS_LENGTH ||
                _order.givePatchAuthoritySrc.length > MAX_ADDRESS_LENGTH ||
                _order.allowedTakerDst.length > MAX_ADDRESS_LENGTH ||
                _order.allowedCancelBeneficiarySrc.length > MAX_ADDRESS_LENGTH
            ) revert WrongAddressLength();
        }
        // | Bytes | Bits | Field                                                |
        // | ----- | ---- | ---------------------------------------------------- |
        // | 8     | 64   | Nonce
        // | 1     | 8    | Maker Src Address Size (!=0)                         |
        // | N     | 8*N  | Maker Src Address                                              |
        // | 32    | 256  | Give Chain Id                                        |
        // | 1     | 8    | Give Token Address Size (!=0)                        |
        // | N     | 8*N  | Give Token Address                                   |
        // | 32    | 256  | Give Amount                                          |
        // | 32    | 256  | Take Chain Id                                        |
        // | 1     | 8    | Take Token Address Size (!=0)                        |
        // | N     | 8*N  | Take Token Address                                   |
        // | 32    | 256  | Take Amount                                          |                         |
        // | 1     | 8    | Receiver Dst Address Size (!=0)                      |
        // | N     | 8*N  | Receiver Dst Address                                 |
        // | 1     | 8    | Give Patch Authority Address Size (!=0)              |
        // | N     | 8*N  | Give Patch Authority Address                         |
        // | 1     | 8    | Order Authority Address Dst Size (!=0)               |
        // | N     | 8*N  | Order Authority Address Dst                     |
        // | 1     | 8    | Allowed Taker Dst Address Size                       |
        // | N     | 8*N  | * Allowed Taker Address Dst                          |
        // | 1     | 8    | Allowed Cancel Beneficiary Src Address Size          |
        // | N     | 8*N  | * Allowed Cancel Beneficiary Address Src             |
        // | 1     | 8    | Is External Call Presented 0x0 - Not, != 0x0 - Yes   |
        // | 32    | 256  | * External Call Envelope Hash

        encoded = abi.encodePacked(
            _order.makerOrderNonce,
            (uint8)(_order.makerSrc.length),
            _order.makerSrc
        );
        {
            encoded = abi.encodePacked(
                encoded,
                _order.giveChainId,
                (uint8)(_order.giveTokenAddress.length),
                _order.giveTokenAddress,
                _order.giveAmount,
                _order.takeChainId
            );
        }
        //Avoid stack to deep
        {
            encoded = abi.encodePacked(
                encoded,
                (uint8)(_order.takeTokenAddress.length),
                _order.takeTokenAddress,
                _order.takeAmount,
                (uint8)(_order.receiverDst.length),
                _order.receiverDst
            );
        }
        {
            encoded = abi.encodePacked(
                encoded,
                (uint8)(_order.givePatchAuthoritySrc.length),
                _order.givePatchAuthoritySrc,
                (uint8)(_order.orderAuthorityAddressDst.length),
                _order.orderAuthorityAddressDst
            );
        }
        {
            encoded = abi.encodePacked(
                encoded,
                (uint8)(_order.allowedTakerDst.length),
                _order.allowedTakerDst,
                (uint8)(_order.allowedCancelBeneficiarySrc.length),
                _order.allowedCancelBeneficiarySrc,
                _order.externalCall.length > 0
            );
        }
        if (_order.externalCall.length > 0) {
            encoded = abi.encodePacked(
                encoded,
                keccak256(_order.externalCall)
            );
        }
        return encoded;
    }

    // ============ VIEWS ============

    function getOrderId(DlnOrderLib.Order memory _order) public pure returns (bytes32) {
        return keccak256(_encodeOrder(_order));
    }

    /// @dev Get current chain id
    function getChainId() public view virtual returns (uint256 cid) {
        assembly {
            cid := chainid()
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IERC20Permit.sol";
import "../interfaces/IExternalCallAdapter.sol";
import "../libraries/BytesLib.sol";
import "../libraries/EncodeSolanaDlnMessage.sol";
import "./DlnBase.sol";
import "./DlnSource.sol";
import "@debridge-finance/debridge-contracts-v1/contracts/libraries/Flags.sol";
import "../interfaces/IDlnDestination.sol";


contract DlnDestination is DlnBase, ReentrancyGuardUpgradeable, IDlnDestination {
    using BytesLib for bytes;
    
    /* ========== CONSTANTS ========== */

    /// @dev Amount divider to transfer native assets to the Solana network. (evm 18 decimals => solana 8 decimals)
    /// As Solana only supports u64, and doesn't support u256, amounts must be adjusted when a transfer from EVM chain to Sonana
    /// is being made, for that amount value must me "shifted" on k decimals to get max solana decimals = 8
    uint256 public constant NATIVE_AMOUNT_DIVIDER_FOR_TRANSFER_TO_SOLANA = 1e10;

    /* ========== STATE VARIABLES ========== */

    /// @dev Maps chainId to  address of dlnSource contract on that chain
    mapping(uint256 => bytes) public dlnSourceAddresses;

    // @dev Maps orderId (see getOrderId) => state of order.
    mapping(bytes32 => OrderTakeState) public takeOrders;

    /// Storage for take patches
    /// Values here is subtrahend from [`Order::take::amount`] in [`fulfill_order`] moment
    mapping(bytes32 => uint256) public takePatches;

    uint256 public maxOrderCountPerBatchEvmUnlock;
    uint256 public maxOrderCountPerBatchSolanaUnlock;
    address public externalCallAdapter;

    /* ========== ENUMS ========== */

    enum OrderTakeStatus {
        NotSet, //0
        /// Order full filled
        Fulfilled, // 1
        /// Order full filled and unlock command sent in give.chain_id by taker
        SentUnlock, // 2
        /// Order canceled
        SentCancel // 3
    }

    /* ========== STRUCTS ========== */

    struct OrderTakeState {
        OrderTakeStatus status;
        address takerAddress;
        uint256 giveChainId;
    }

    /* ========== EVENTS ========== */

    event FulfilledOrder(DlnOrderLib.Order order, bytes32 orderId, address sender, address unlockAuthority);

    event DecreasedTakeAmount(bytes32 orderId, uint256 orderTakeFinalAmount);

    event SentOrderCancel(DlnOrderLib.Order order, bytes32 orderId, bytes cancelBeneficiary, bytes32 submissionId);

    event SentOrderUnlock(bytes32 orderId, bytes beneficiary, bytes32 submissionId);

    event SetDlnSourceAddress(uint256 chainIdFrom, bytes dlnSourceAddress, DlnOrderLib.ChainEngine chainEngine);

    event ExternalCallAdapterUpdated(address oldAdapter, address newAdapter);

    event MaxOrderCountPerBatchEvmUnlockChanged(uint256 oldValue, uint256 newValue);
    event MaxOrderCountPerBatchSolanaUnlockChanged(uint256 oldValue, uint256 newValue);

    /* ========== ERRORS ========== */

    error MismatchTakerAmount();
    error MismatchNativeTakerAmount();
    error WrongToken();
    error AllowOnlyForBeneficiary(bytes expectedBeneficiary);
    error UnexpectedBatchSize();
    error MismatchGiveChainId();
    error TransferAmountNotCoverFees();

    /* ========== CONSTRUCTOR  ========== */

    /// @dev Constructor that initializes the most important configurations.

    function initialize(IDeBridgeGate _deBridgeGate) public initializer {
        __DlnBase_init(_deBridgeGate);
        __ReentrancyGuard_init();
    }

    /* ========== PUBLIC METHODS ========== */

    /**
     * @inheritdoc IDlnDestination
     */
    function fulfillOrder(
        DlnOrderLib.Order memory _order,
        uint256 _fulFillAmount,
        bytes32 _orderId,
        bytes calldata _permitEnvelope,
        address _unlockAuthority
    ) external payable nonReentrant whenNotPaused {
        _fulfillOrder(
            _permitEnvelope,
            _order,
            _fulFillAmount,
            _orderId,
            _unlockAuthority,
            address(0)
        );
    }

    function fulfillOrder(
        DlnOrderLib.Order memory _order,
        uint256 _fulFillAmount,
        bytes32 _orderId,
        bytes calldata _permitEnvelope,
        address _unlockAuthority,
        address _externalCallRewardBeneficiary
    ) external payable nonReentrant whenNotPaused {
        _fulfillOrder(
            _permitEnvelope,
            _order,
            _fulFillAmount,
            _orderId,
            _unlockAuthority,
            _externalCallRewardBeneficiary
        );
    }

    function _fulfillOrder(
        bytes memory _permitEnvelope,
        DlnOrderLib.Order memory _order,
        uint256 _fulFillAmount,
        bytes32 _orderId,
        address _unlockAuthority,
        address _externalCallRewardBeneficiary
    ) internal {
        if (_order.takeChainId != getChainId()) revert WrongChain();
        bytes32 orderId = getOrderId(_order);
        if (orderId != _orderId) revert MismatchedOrderId();
        OrderTakeState storage orderState = takeOrders[orderId];
        // in dst chain order will start from 0-NotSet
        if (orderState.status != OrderTakeStatus.NotSet) revert IncorrectOrderStatus();
        // Check that the given unlock authority equals allowedTakerDst if allowedTakerDst was set
        if (
            _order.allowedTakerDst.length > 0 &&
            BytesLib.toAddress(_order.allowedTakerDst, 0) != _unlockAuthority

        ) revert Unauthorized();
        // amount that taker need to pay to fulfill order
        uint256 takerAmount = takePatches[orderId] == 0
            ? _order.takeAmount
            : _order.takeAmount - takePatches[orderId];
        // extra check that taker paid correct amount;
        if (takerAmount != _fulFillAmount) revert MismatchTakerAmount();

        //Avoid Stack too deep
        {
            address takeTokenAddress = _order.takeTokenAddress.toAddress();
            // Need to send token to call adapter if exist external call
            address tokenReceiver = _order.externalCall.length > 0
                ? externalCallAdapter
                : _order.receiverDst.toAddress();

            if (takeTokenAddress == address(0)) {
                if (msg.value != takerAmount) revert MismatchNativeTakerAmount();
                _safeTransferETH(tokenReceiver, takerAmount);
            }
            else
            {
                _executePermit(takeTokenAddress, _permitEnvelope);
                _safeTransferFrom(
                    takeTokenAddress,
                    msg.sender,
                    tokenReceiver,
                    takerAmount
                );
            }
        }
        //change order state to FulFilled
        orderState.status = OrderTakeStatus.Fulfilled;
        orderState.takerAddress = _unlockAuthority;
        orderState.giveChainId = _order.giveChainId;

        if (_order.externalCall.length > 0) {
            IExternalCallAdapter(externalCallAdapter).receiveCall(
                orderId, 
                _order.orderAuthorityAddressDst.toAddress(),
                _order.takeTokenAddress.toAddress(), 
                takerAmount,
                _order.externalCall, 
                _externalCallRewardBeneficiary
                );
        }
        emit FulfilledOrder(_order, orderId, msg.sender, _unlockAuthority);
    }

    /// @dev Send unlock order in [`Order::give::chain_id`]
    ///
    /// If the order was filled and not unlocked yet, taker from [`TakeState::FulFilled { taker }`] can unlock it and get the give part in [`Order::give::chain_id`] chain
    /// In the receive chain, the [`dln::source::claim_unlock`] will be called
    ///
    /// @param _orderId Order id for unlock
    /// @param _beneficiary address that will receive give amount in give chain
    /// @param _executionFee execution fee for auto claim by keepers
    /// # Allowed
    /// By taker of order only
    function sendEvmUnlock(
        bytes32 _orderId,
        address _beneficiary,
        uint256 _executionFee
    ) external payable nonReentrant whenNotPaused {
        uint256 giveChainId = _prepareOrderStateForUnlock(_orderId, DlnOrderLib.ChainEngine.EVM);
        // encode function that will be called in target chain
        bytes memory claimUnlockMethod = _encodeClaimUnlock(_orderId, _beneficiary);
        //send crosschain message through deBridgeGate
        bytes32 submissionId = _sendCrossChainMessage(
            giveChainId, // _chainIdTo
            abi.encodePacked(_beneficiary),
            _executionFee,
            claimUnlockMethod
        );

        emit SentOrderUnlock(_orderId, abi.encodePacked(_beneficiary), submissionId);
    }


    /// @dev Send batch unlock order in [`Order::give::chain_id`]
    ///
    /// If the order was filled and not unlocked yet, taker from [`TakeState::FulFilled { taker }`] can unlock it and get the give part in [`Order::give::chain_id`] chain
    /// In the receive chain, the [`dln::source::claim_unlock`] will be called
    ///
    /// @param _orderIds Order ids for unlock. Orders must have the same giveChainId
    /// @param _beneficiary address that will receive give amount in give chain
    /// @param _executionFee execution fee for auto claim by keepers
    /// # Allowed
    /// By taker of order only
    function sendBatchEvmUnlock(
        bytes32[] memory _orderIds,
        address _beneficiary,
        uint256 _executionFee
    ) external payable nonReentrant whenNotPaused {
        if (_orderIds.length == 0) revert UnexpectedBatchSize();
        if (_orderIds.length > maxOrderCountPerBatchEvmUnlock) revert UnexpectedBatchSize();

        uint256 giveChainId;
        uint256 length = _orderIds.length;
        for (uint256 i; i < length; ++i) {
            uint256 currentGiveChainId = _prepareOrderStateForUnlock(_orderIds[i], DlnOrderLib.ChainEngine.EVM);
            if (i == 0) {
                giveChainId = currentGiveChainId;
            }
            else {
                // giveChainId must be the same for all orders
                if (giveChainId != currentGiveChainId) revert MismatchGiveChainId();
            }
        }
        // encode function that will be called in target chain
        bytes memory claimUnlockMethod = _encodeBatchClaimUnlock(_orderIds, _beneficiary);

        //send crosschain message through deBridgeGate
        bytes32 submissionId = _sendCrossChainMessage(
            giveChainId, // _chainIdTo
            abi.encodePacked(_beneficiary),
            _executionFee,
            claimUnlockMethod
        );

        for (uint256 i; i < length; ++i) {
            emit SentOrderUnlock(_orderIds[i], abi.encodePacked(_beneficiary), submissionId);
        }
    }

    /// @dev Send multiple claim_unlock instructions to unlock several orders in [`Order::give::chain_id`].
    /// @notice It is implied that all orders share the same giveChainId, giveTokenAddress and beneficiary, so that only one
    ///         init_wallet_if_needed instruction is used
    ///
    /// @param _orders Array of orders to unlock
    /// @param _beneficiary address that will receive give amount in give chain
    /// @param _executionFee execution fee for auto claim by keepers. This fee must cover a single _initWalletIfNeededInstructionReward
    ///                     and _claimUnlockInstructionReward * number of orders in this batch
    /// @param _initWalletIfNeededInstructionReward reward for executing init_wallet_if_needed instruction on Solana
    /// @param _claimUnlockInstructionReward reward for executing a single claim_unlock instruction on Solana. This method
    //                      sends as many claim_unlock instructions as the number of orders in this batch
    function sendBatchSolanaUnlock(
        DlnOrderLib.Order[] memory _orders,
        bytes32 _beneficiary,
        uint256 _executionFee,
        uint64 _initWalletIfNeededInstructionReward,
        uint64 _claimUnlockInstructionReward
    ) external payable nonReentrant whenNotPaused {
        if (_orders.length == 0) revert UnexpectedBatchSize();
        if (_orders.length > maxOrderCountPerBatchSolanaUnlock) revert UnexpectedBatchSize();
        // make sure execution fee covers rewards for single account initialisation instruction + claim_unlock for every order
        _validateSolanaRewards(msg.value, _executionFee, _initWalletIfNeededInstructionReward, uint64(_claimUnlockInstructionReward * _orders.length));

        uint256 giveChainId;
        bytes32 giveTokenAddress;
        bytes32 solanaSrcProgramId;
        bytes memory instructionsData;
        bytes32[] memory orderIds = new bytes32[](_orders.length);
        for (uint256 i; i < _orders.length; ++i) {
            DlnOrderLib.Order memory order = _orders[i];
            bytes32 orderId = getOrderId(order);
            orderIds[i] = orderId;
            _prepareOrderStateForUnlock(orderId, DlnOrderLib.ChainEngine.SOLANA);

            if (i == 0) {
                // pre-cache giveChainId of the first order in a batch to ensure all other orders have the same giveChainId
                giveChainId = order.giveChainId;

                // pre-cache giveTokenAddress of the first order in a batch to ensure all other orders have the same giveTokenAddress
                // also, this value is used heavily when encoding instructions
                giveTokenAddress = BytesLib.toBytes32(order.giveTokenAddress, 0);

                // pre-cache solanaSrcProgramId because this value is used when encoding instructions
                solanaSrcProgramId = BytesLib.toBytes32(dlnSourceAddresses[order.giveChainId], 0);

                // first instruction must be account initializer.
                // actually by design, we must initialize account for every giveTokenAddress+beneficiary pair,
                // but right for simplicity reasons we assume that batches may contain orders with the same giveTokenAddress,
                // so only a single initialization is required
                instructionsData = EncodeSolanaDlnMessage.encodeInitWalletIfNeededInstruction(
                    _beneficiary,
                    giveTokenAddress,
                    _initWalletIfNeededInstructionReward
                );
            }
            else {
                // ensure every order is from the same chain
                if (order.giveChainId != giveChainId) revert WrongChain();

                // ensure every order has the same giveTokenAddress (otherwise, we may need to ensure this account is initalized)
                if (BytesLib.toBytes32(order.giveTokenAddress, 0) != giveTokenAddress) revert WrongToken();
            }

            // finally, add claim_unlock instruction for this order
            instructionsData = abi.encodePacked(
                instructionsData,
                EncodeSolanaDlnMessage.encodeClaimUnlockInstruction(
                    getChainId(), //_takeChainId,
                    solanaSrcProgramId, //_srcProgramId,
                    _beneficiary, //_actionBeneficiary,
                    giveTokenAddress, //_orderGiveTokenAddress,
                    orderId,
                    _claimUnlockInstructionReward
                )
            );
        }

        // send crosschain message through deBridgeGate
        bytes32 submissionId = _sendCrossChainMessage(
            giveChainId, // _chainIdTo
            abi.encodePacked(_beneficiary),
            _executionFee,
            instructionsData
        );

        // emit event for every order
        for (uint256 i; i < _orders.length; ++i) {
            emit SentOrderUnlock(orderIds[i], abi.encodePacked(_beneficiary), submissionId);
        }
    }


    /// @dev Send unlock order in [`Order::give::chain_id`]
    ///
    /// If the order was filled and not unlocked yet, taker from [`TakeState::FulFilled { taker }`] can unlock it and get the give part in [`Order::give::chain_id`] chain
    /// In the receive chain, the [`dln::source::claim_unlock`] will be called
    ///
    /// @param _order Order for unlock
    /// @param _beneficiary address that will receive give amount in give chain
    /// @param _executionFee execution fee for auto claim by keepers
    /// @param _initWalletIfNeededInstructionReward reward for executing init_wallet_if_needed instruction on Solana
    /// @param _claimUnlockInstructionReward reward for executing a single claim_unlock instruction on Solana
    /// # Allowed
    /// By taker of order only
    function sendSolanaUnlock(
        DlnOrderLib.Order memory _order,
        bytes32 _beneficiary,
        uint256 _executionFee,
        uint64 _initWalletIfNeededInstructionReward,
        uint64 _claimUnlockInstructionReward
    ) external payable nonReentrant whenNotPaused {
        _validateSolanaRewards(msg.value, _executionFee, _initWalletIfNeededInstructionReward, _claimUnlockInstructionReward);
        bytes32 orderId = getOrderId(_order);
        uint256 giveChainId = _prepareOrderStateForUnlock(orderId, DlnOrderLib.ChainEngine.SOLANA);

        // encode function that will be called in target chain
        bytes32 giveTokenAddress = BytesLib.toBytes32(_order.giveTokenAddress, 0);
        bytes memory instructionsData = abi.encodePacked(
            EncodeSolanaDlnMessage.encodeInitWalletIfNeededInstruction(
                    _beneficiary,
                    giveTokenAddress,
                    _initWalletIfNeededInstructionReward
            ),
            EncodeSolanaDlnMessage.encodeClaimUnlockInstruction(
                getChainId(), //_takeChainId,
                BytesLib.toBytes32(dlnSourceAddresses[giveChainId], 0), //_srcProgramId,
                _beneficiary, //_actionBeneficiary,
                giveTokenAddress, //_orderGiveTokenAddress,
                orderId,
                _claimUnlockInstructionReward
            )
        );
        //send crosschain message through deBridgeGate
        bytes32 submissionId = _sendCrossChainMessage(
            giveChainId, // _chainIdTo
            abi.encodePacked(_beneficiary),
            _executionFee,
            instructionsData
        );

        emit SentOrderUnlock(orderId, abi.encodePacked(_beneficiary), submissionId);
    }


    /// @dev Send cancel order in [`Order::give::chain_id`]
    ///
    /// If the order was not filled or canceled earlier, [`Order::order_authority_address_dst`] can cancel it and get back the give part in [`Order::give::chain_id`] chain
    /// In the receive chain, the [`dln::source::claim_order_cancel`] will be called
    ///
    /// @param _order Full order for patch
    /// @param _cancelBeneficiary address that will receive refund in give chain chain
    ///     * If [`Order::allowed_cancel_beneficiary`] is None then any [`Address`]
    ///     * If [`Order::allowed_cancel_beneficiary`] is Some then only itself
    /// @param _executionFee execution fee for auto claim by keepers
    /// # Allowed
    /// By [`Order::order_authority_address_dst`] only
    function sendEvmOrderCancel(
        DlnOrderLib.Order memory _order,
        address _cancelBeneficiary,
        uint256 _executionFee
    ) external payable nonReentrant whenNotPaused {
        if (_order.takeChainId != getChainId()) revert WrongChain();
        if (chainEngines[_order.giveChainId]  != DlnOrderLib.ChainEngine.EVM) revert WrongChain();
        bytes32 orderId = getOrderId(_order);
        if (_order.orderAuthorityAddressDst.toAddress() != msg.sender)
            revert Unauthorized();

        if (_order.allowedCancelBeneficiarySrc.length > 0
            && _order.allowedCancelBeneficiarySrc.toAddress() != _cancelBeneficiary) {
            revert AllowOnlyForBeneficiary(_order.allowedCancelBeneficiarySrc);
        }

        OrderTakeState storage orderState = takeOrders[orderId];
        //In dst chain order will start from 0-NotSet
        if (orderState.status != OrderTakeStatus.NotSet) revert IncorrectOrderStatus();
        orderState.status = OrderTakeStatus.SentCancel;

        // encode function that will be called in target chain
        bytes memory claimCancelMethod = _encodeClaimCancel(orderId, _cancelBeneficiary);
        //send crosschain message through deBridgeGate
        bytes32 submissionId = _sendCrossChainMessage(
            _order.giveChainId, // _chainIdTo
            abi.encodePacked(_cancelBeneficiary),
            _executionFee,
            claimCancelMethod
        );
        emit SentOrderCancel(_order, orderId, abi.encodePacked(_cancelBeneficiary), submissionId);
    }

    /// @dev Send cancel order in [`Order::give::chain_id`]
    ///
    /// If the order was not filled or canceled earlier, [`Order::order_authority_address_dst`] can cancel it and get back the give part in [`Order::give::chain_id`] chain
    /// In the receive chain, the [`dln::source::claim_order_cancel`] will be called
    ///
    /// @param _order Full order for patch
    /// @param _cancelBeneficiary address that will receive refund in give chain chain
    ///     * If [`Order::allowed_cancel_beneficiary`] is None then any [`Address`]
    ///     * If [`Order::allowed_cancel_beneficiary`] is Some then only itself
    /// @param _executionFee execution fee for auto claim by keepers
    /// # Allowed
    /// By [`Order::order_authority_address_dst`] only
    function sendSolanaOrderCancel(
        DlnOrderLib.Order memory _order,
        bytes32 _cancelBeneficiary,
        uint256 _executionFee,
        uint64 _reward1,
        uint64 _reward2
    ) external payable nonReentrant whenNotPaused {
        _validateSolanaRewards(msg.value, _executionFee, _reward1, _reward2);

        if (chainEngines[_order.giveChainId]  != DlnOrderLib.ChainEngine.SOLANA) revert WrongChain();
        if (_order.takeChainId != getChainId()) revert WrongChain();
        bytes memory solanaSrcProgramId = dlnSourceAddresses[_order.giveChainId];
        if (solanaSrcProgramId.length != SOLANA_ADDRESS_LENGTH) revert WrongChain();

        bytes32 orderId = getOrderId(_order);
        if (_order.orderAuthorityAddressDst.toAddress() != msg.sender)
            revert Unauthorized();

        if (_order.allowedCancelBeneficiarySrc.length > 0
            && BytesLib.toBytes32(_order.allowedCancelBeneficiarySrc, 0) != _cancelBeneficiary) {
            revert AllowOnlyForBeneficiary(_order.allowedCancelBeneficiarySrc);
        }

        OrderTakeState storage orderState = takeOrders[orderId];
        //In dst chain order will start from 0-NotSet
        if (orderState.status != OrderTakeStatus.NotSet) revert IncorrectOrderStatus();
        orderState.status = OrderTakeStatus.SentCancel;

        // encode function that will be called in target chain
        bytes32 _orderGiveTokenAddress = BytesLib.toBytes32(_order.giveTokenAddress, 0);
        bytes memory claimCancelMethod = abi.encodePacked(
            EncodeSolanaDlnMessage.encodeInitWalletIfNeededInstruction(
                    _cancelBeneficiary,
                    _orderGiveTokenAddress,
                    _reward1
            ),
            EncodeSolanaDlnMessage.encodeClaimCancelInstruction(
                getChainId(), //_takeChainId,
                BytesLib.toBytes32(solanaSrcProgramId, 0), //_srcProgramId,
                _cancelBeneficiary, //_actionBeneficiary,
                _orderGiveTokenAddress, //_orderGiveTokenAddress,
                orderId,
                _reward2
            )
        );
        //send crosschain message through deBridgeGate
        bytes32 submissionId = _sendCrossChainMessage(
            _order.giveChainId, // _chainIdTo
            abi.encodePacked(_cancelBeneficiary),
            _executionFee,
            claimCancelMethod
        );

        emit SentOrderCancel(_order, orderId, abi.encodePacked(_cancelBeneficiary), submissionId);
    }

    /// @dev Patch take offer of order
    ///
    /// To increase the profitability of the order, subtraction amount from the take part
    /// If a patch was previously made, then the new patch can only increase the subtraction
    ///
    /// @param _order Full order for patch
    /// @param _newSubtrahend Amount to remove from [`Order::take::amount`] for use in [`fulfill_order`] methods
    /// # Allowed
    /// Only [`Order::order_authority_address_dst`]
    function patchOrderTake(DlnOrderLib.Order memory _order, uint256 _newSubtrahend)
        external
        nonReentrant
        whenNotPaused
    {
        if (_order.takeChainId != getChainId()) revert WrongChain();
        bytes32 orderId = getOrderId(_order);
        if (_order.orderAuthorityAddressDst.toAddress() != msg.sender)
            revert Unauthorized();
        if (takePatches[orderId] >= _newSubtrahend) revert WrongArgument();
        if (_order.takeAmount <= _newSubtrahend) revert WrongArgument();
        //In dst chain order will start from 0-NotSet
        if (takeOrders[orderId].status != OrderTakeStatus.NotSet) revert IncorrectOrderStatus();

        takePatches[orderId] = _newSubtrahend;
        emit DecreasedTakeAmount(orderId, _order.takeAmount - takePatches[orderId]);
    }

    /* ========== ADMIN METHODS ========== */

    function setDlnSourceAddress(uint256 _chainIdFrom, bytes memory _dlnSourceAddress, DlnOrderLib.ChainEngine _chainEngine)
        external
        onlyAdmin
    {
        if(_chainEngine == DlnOrderLib.ChainEngine.UNDEFINED) revert WrongArgument();
        dlnSourceAddresses[_chainIdFrom] = _dlnSourceAddress;
        chainEngines[_chainIdFrom] = _chainEngine;
        emit SetDlnSourceAddress(_chainIdFrom, _dlnSourceAddress, _chainEngine);
    }

    function setExternalCallAdapter(address _externalCallAdapter)
        external
        onlyAdmin
    {
        address oldAdapter = externalCallAdapter;
        externalCallAdapter = _externalCallAdapter;
        emit ExternalCallAdapterUpdated(oldAdapter, externalCallAdapter);
    }

    function setMaxOrderCountsPerBatch(uint256 _newEvmCount, uint256 _newSolanaCount) external onlyAdmin {
        // Setting and emitting for EVM count
        uint256 oldEvmValue = maxOrderCountPerBatchEvmUnlock;
        maxOrderCountPerBatchEvmUnlock = _newEvmCount;
        if(oldEvmValue != _newEvmCount) {
            emit MaxOrderCountPerBatchEvmUnlockChanged(oldEvmValue, _newEvmCount);
        }

        // Setting and emitting for Solana count
        uint256 oldSolanaValue = maxOrderCountPerBatchSolanaUnlock;
        maxOrderCountPerBatchSolanaUnlock = _newSolanaCount;
        if(oldSolanaValue != _newSolanaCount) {
            emit MaxOrderCountPerBatchSolanaUnlockChanged(oldSolanaValue, _newSolanaCount);
        }
    }
    
    /* ==========  Private methods ========== */

    /// @dev Change order status from Fulfilled to SentUnlock
    /// @notice Allowed by taker of order only
    /// @notice Works only for evm giveChainId
    /// @param _orderId orderId
    /// @return giveChainId
    function _prepareOrderStateForUnlock(bytes32 _orderId, DlnOrderLib.ChainEngine _chainEngine) internal
        returns (uint256) {
        OrderTakeState storage orderState = takeOrders[_orderId];
        if (orderState.status != OrderTakeStatus.Fulfilled) revert IncorrectOrderStatus();
        if (orderState.takerAddress != msg.sender) revert Unauthorized();
        if (chainEngines[orderState.giveChainId] != _chainEngine) revert WrongChain();
        orderState.status = OrderTakeStatus.SentUnlock;
        return orderState.giveChainId;
    }

    function _encodeClaimUnlock(bytes32 _orderId, address _beneficiary)
        internal
        pure
        returns (bytes memory)
    {
        //claimUnlock(bytes32 _orderId, address _beneficiary)
        return abi.encodeWithSelector(DlnSource.claimUnlock.selector, _orderId, _beneficiary);
    }

    function _encodeBatchClaimUnlock(bytes32[] memory _orderIds, address _beneficiary)
        internal
        pure
        returns (bytes memory)
    {
        //claimBatchUnlock(bytes32[] memory _orderIds, address _beneficiary)
        return abi.encodeWithSelector(DlnSource.claimBatchUnlock.selector, _orderIds, _beneficiary);
    }


    function _encodeClaimCancel(bytes32 _orderId, address _beneficiary)
        internal
        pure
        returns (bytes memory)
    {
        //claimCancel(bytes32 _orderId, address _beneficiary)
        return abi.encodeWithSelector(DlnSource.claimCancel.selector, _orderId, _beneficiary);
    }

    function _encodeAutoParamsTo(
        bytes memory _data,
        uint256 _executionFee,
        bytes memory _fallbackAddress
    ) internal pure returns (bytes memory) {
        IDeBridgeGate.SubmissionAutoParamsTo memory autoParams;
        autoParams.flags = Flags.setFlag(autoParams.flags, Flags.REVERT_IF_EXTERNAL_FAIL, true);
        autoParams.flags = Flags.setFlag(autoParams.flags, Flags.PROXY_WITH_SENDER, true);

        // fallbackAddress won't be used because of REVERT_IF_EXTERNAL_FAIL flag
        // also it make no sense to use it because it's only for ERC20 tokens
        // autoParams.fallbackAddress = abi.encodePacked(address(0));
        autoParams.fallbackAddress = _fallbackAddress;
        autoParams.data = _data;
        autoParams.executionFee = _executionFee;
        return abi.encode(autoParams);
    }

    /// @dev Validate that the amount will suffice to cover all execution rewards.
    /// @param _inputAmount Transferring an amount sufficient to cover the execution fee and all rewards.
    /// @param _executionFee execution fee for claim
    /// @param _solanaExternalCallReward1 Fee for executing external call 1
    /// @param _solanaExternalCallReward2 Fee for executing external call 2
    function _validateSolanaRewards (
        uint256 _inputAmount,
        uint256 _executionFee,
        uint64 _solanaExternalCallReward1,
        uint64 _solanaExternalCallReward2
    ) internal view {
        uint256 transferFeeBPS = deBridgeGate.globalTransferFeeBps();
        uint256 fixFee = deBridgeGate.globalFixedNativeFee();
        if (_inputAmount < fixFee) revert TransferAmountNotCoverFees();
        uint256 transferFee = transferFeeBPS * (_inputAmount - fixFee) / BPS_DENOMINATOR;
        if (_inputAmount / NATIVE_AMOUNT_DIVIDER_FOR_TRANSFER_TO_SOLANA < (fixFee + transferFee + _executionFee) / NATIVE_AMOUNT_DIVIDER_FOR_TRANSFER_TO_SOLANA
                                                        + _solanaExternalCallReward1 + _solanaExternalCallReward2) {
            revert TransferAmountNotCoverFees();
        }
    }

    function _sendCrossChainMessage(
        uint256 _chainIdTo,
        bytes memory _fallbackAddress,
        uint256 _executionFee,
        bytes memory _data
    ) internal returns (bytes32) {
        bytes memory srcAddress = dlnSourceAddresses[_chainIdTo];
        bytes memory autoParams = _encodeAutoParamsTo(_data, _executionFee, _fallbackAddress);
        {
            DlnOrderLib.ChainEngine _targetEngine = chainEngines[_chainIdTo];

            if (_targetEngine == DlnOrderLib.ChainEngine.EVM ) {
                if (srcAddress.length != EVM_ADDRESS_LENGTH) revert WrongAddressLength();
                if (_fallbackAddress.length != EVM_ADDRESS_LENGTH) revert WrongAddressLength();
            }
            else if (_targetEngine == DlnOrderLib.ChainEngine.SOLANA ) {
                if (srcAddress.length != SOLANA_ADDRESS_LENGTH) revert WrongAddressLength();
                if (_fallbackAddress.length != SOLANA_ADDRESS_LENGTH) revert WrongAddressLength();
            }
            else {
                revert UnknownEngine();
            }
        }

        return deBridgeGate.send{value: msg.value}(
            address(0), // _tokenAddress
            msg.value, // _amount
            _chainIdTo, // _chainIdTo
            srcAddress, // _receiver
            "", // _permit
            false, // _useAssetFee
            0, // _referralCode
            autoParams // _autoParams
        );
    }

    /* ========== Version Control ========== */

    /// @dev Get this contract's version
    function version() external pure returns (string memory) {
        return "1.3.0";
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@debridge-finance/debridge-contracts-v1/contracts/interfaces/ICallProxy.sol";
import "../libraries/SafeCast.sol";
import "./DlnBase.sol";
import "../interfaces/IDlnSource.sol";

contract DlnSource is DlnBase, ReentrancyGuardUpgradeable, IDlnSource {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using BytesLib for bytes;
    
    /* ========== STATE VARIABLES ========== */

    /// @dev Fixed fee in native asset
    uint88 public globalFixedNativeFee;
    /// @dev Transfer fee in BPS
    uint16 public globalTransferFeeBps;

    /// @dev Maps chainId to address of dlnDestination contract on that chain
    mapping(uint256 => bytes) public dlnDestinationAddresses;

    // @dev Maps orderId (see getOrderId) => state of order.
    /// Storage for information about orders
    /// Value is collected process fee for return it in order cancel case
    mapping(bytes32 => GiveOrderState) public giveOrders;

    /// Storage about give patches
    /// Values is `added` for order give amount in unlock | cancel moment
    mapping(bytes32 => uint256) public givePatches;

    /// Distributes a nonce for each order maker
    mapping(address => uint256) public masterNonce;

    // collected protocol fee
    mapping(address => uint256) public collectedFee;

    // mapping for wrong order. If claimed unlock and order in not correct status.
    // orderId => claim beneficiary
    mapping(bytes32 => address) public unexpectedOrderStatusForClaim;
    // mapping for wrong order. If claimed cancel and order in not correct status.
    // orderId => cancel beneficiary
    mapping(bytes32 => address) public unexpectedOrderStatusForCancel;

    // maps the amount of ETH per affiliate beneficiary (in case we failed to send ETH to him)
    // affiliateBeneficiary => amount
    mapping(address => uint256) public unclaimedAffiliateETHFees;

    /* ========== ENUMS ========== */

    enum OrderGiveStatus {
        /// Order not exist
        NotSet, //0
        /// Order created
        Created, // 1
        /// Order full filled and unlock command sent in give.chain_id by taker
        ClaimedUnlock, // 2
        /// Order canceled
        ClaimedCancel // 3
    }

    /* ========== STRUCTS ========== */


    struct GiveOrderState {
        OrderGiveStatus status;
        // stot optimisation
        uint160 giveTokenAddress;
        uint88 nativeFixFee;
        uint48 takeChainId;
        uint208 percentFee;
        uint256 giveAmount;
        address affiliateBeneficiary;
        uint256 affiliateAmount;
    }

    /* ========== EVENTS ========== */

    event CreatedOrder(
        DlnOrderLib.Order order,
        bytes32 orderId,
        bytes affiliateFee,
        uint256 nativeFixFee,
        uint256 percentFee,
        uint32 referralCode,
        bytes payload
    );

    event IncreasedGiveAmount(bytes32 orderId, uint256 orderGiveFinalAmount, uint256 finalPercentFee);

    event AffiliateFeePaid(
        bytes32 _orderId,
        address beneficiary,
        uint256 affiliateFee,
        address giveTokenAddress
    );

    event ClaimedUnlock(
        bytes32 orderId,
        address beneficiary,
        uint256 giveAmount,
        address giveTokenAddress
    );

    event UnexpectedOrderStatusForClaim(bytes32 orderId, OrderGiveStatus status, address beneficiary);

    event CriticalMismatchChainId(bytes32 orderId, address beneficiary, uint256 takeChainId,  uint256 submissionChainIdFrom);

    event ClaimedOrderCancel(
        bytes32 orderId,
        address beneficiary,
        uint256 paidAmount,
        address giveTokenAddress
    );

    event UnexpectedOrderStatusForCancel(bytes32 orderId, OrderGiveStatus status, address beneficiary);

    event SetDlnDestinationAddress(uint256 chainIdTo, bytes dlnDestinationAddress, DlnOrderLib.ChainEngine chainEngine);

    event WithdrawnFee(address tokenAddress, uint256 amount, address beneficiary);

    event GlobalFixedNativeFeeUpdated(uint88 oldGlobalFixedNativeFee, uint88 newGlobalFixedNativeFee);
    event GlobalTransferFeeBpsUpdated(uint16 oldGlobalTransferFeeBps, uint16 newGlobalTransferFeeBps);


    /* ========== ERRORS ========== */

    error WrongFixedFee(uint256 received, uint256 actual);
    error WrongAffiliateFeeLength();
    error MismatchNativeGiveAmount();
    error CriticalMismatchTakeChainId(bytes32 orderId, uint48 takeChainId, uint256 submissionsChainIdFrom);


    /* ========== CONSTRUCTOR  ========== */

    function initialize(
        IDeBridgeGate _deBridgeGate,
        uint88 _globalFixedNativeFee,
        uint16 _globalTransferFeeBps
    ) public initializer {
        _setFixedNativeFee(_globalFixedNativeFee);
        _setTransferFeeBps(_globalTransferFeeBps);

        __DlnBase_init(_deBridgeGate);
        __ReentrancyGuard_init();
    }

    /* ========== PUBLIC METHODS ========== */

    /**
     * @inheritdoc IDlnSource
     */
    function createOrder(
        DlnOrderLib.OrderCreation calldata _orderCreation,
        bytes calldata _affiliateFee,
        uint32 _referralCode,
        bytes calldata _permitEnvelope
    ) external payable nonReentrant whenNotPaused returns (bytes32) {
        return _createSaltedOrder(
            _orderCreation,
            uint64(masterNonce[tx.origin]++),
            _affiliateFee,
            _referralCode,
            _permitEnvelope,
            bytes("")
        );
    }

    /**
     * @inheritdoc IDlnSource
     */
    function createSaltedOrder(
        DlnOrderLib.OrderCreation calldata _orderCreation,
        uint64 _salt,
        bytes calldata _affiliateFee,
        uint32 _referralCode,
        bytes calldata _permitEnvelope,
        bytes memory _payload
    ) external payable nonReentrant whenNotPaused returns (bytes32) {
        return _createSaltedOrder(
            _orderCreation,
            _salt,
            _affiliateFee,
            _referralCode,
            _permitEnvelope,
            _payload
        );
    }

    function _createSaltedOrder(
        DlnOrderLib.OrderCreation calldata _orderCreation,
        uint64 _salt,
        bytes calldata _affiliateFee,
        uint32 _referralCode,
        bytes calldata _permitEnvelope,
        bytes memory _payload
    ) internal returns (bytes32) {

        uint256 affiliateAmount;
        if (_affiliateFee.length > 0) {
            if (_affiliateFee.length != 52) revert WrongAffiliateFeeLength();
            affiliateAmount = BytesLib.toUint256(_affiliateFee, 20);
        }

        DlnOrderLib.Order memory _order = validateCreationOrder(_orderCreation, tx.origin, _salt);

        // take tokens from the user's wallet
        _pullTokens(_orderCreation, _order, _permitEnvelope);

        // reduce giveAmount on (percentFee + affiliateFee)
        uint256 percentFee = (globalTransferFeeBps * _order.giveAmount) / BPS_DENOMINATOR;
        _order.giveAmount -= percentFee + affiliateAmount;

        bytes32 orderId = getOrderId(_order);
        {
            GiveOrderState storage orderState = giveOrders[orderId];
            if (orderState.status != OrderGiveStatus.NotSet) revert IncorrectOrderStatus();

            orderState.status = OrderGiveStatus.Created;
            orderState.giveTokenAddress =  uint160(_orderCreation.giveTokenAddress);
            orderState.nativeFixFee = globalFixedNativeFee;
            orderState.takeChainId = _order.takeChainId.toUint48();
            orderState.percentFee = percentFee.toUint208();
            orderState.giveAmount = _order.giveAmount;
            // save affiliate_fee to storage
            if (affiliateAmount > 0) {
                address affiliateBeneficiary = BytesLib.toAddress(_affiliateFee, 0);
                if (affiliateAmount > 0 && affiliateBeneficiary == address(0)) revert ZeroAddress();
                orderState.affiliateAmount = affiliateAmount;
                orderState.affiliateBeneficiary = affiliateBeneficiary;
            }
        }

        emit CreatedOrder(
            _order,
            orderId,
            _affiliateFee,
            globalFixedNativeFee,
            percentFee,
            _referralCode,
            _payload
        );

        return orderId;
    }

    /// @dev Claim batch unlock orders that was called from orders take chain
    /// @param _orderIds Array of order ids for unlock
    /// @param _beneficiary User that will receive rewards
    /// # Allowed
    /// Can be called only from debridge external call with validation native sender
    function claimBatchUnlock(bytes32[] memory _orderIds, address _beneficiary)
        external
        nonReentrant
        whenNotPaused
    {
        uint256 submissionChainIdFrom = _onlyDlnDestinationAddress();
        uint256 length = _orderIds.length;
        for (uint256 i; i < length; ++i) {
            _claimUnlock(_orderIds[i], _beneficiary, submissionChainIdFrom);
        }
    }

    /// @dev Claim unlock order that was called from take chain
    /// @param _orderId Order id for unlock
    /// @param _beneficiary User that will receive rewards
    /// # Allowed
    /// Can be called only from debridge external call with validation native sender
    function claimUnlock(bytes32 _orderId, address _beneficiary)
        external
        nonReentrant
        whenNotPaused
    {
        uint256 submissionChainIdFrom = _onlyDlnDestinationAddress();
        _claimUnlock(_orderId, _beneficiary, submissionChainIdFrom);
    }

    /// @dev Claim batch cancel orders that was called from take chain
    /// @param _orderIds Array of order ids for cancel
    /// @param _beneficiary User that will receive full refund
    /// # Allowed
    /// Can be called only from debridge external call with validation native sender
    function claimBatchCancel(bytes32[] memory _orderIds, address _beneficiary)
        external
        nonReentrant
        whenNotPaused
    {
        uint256 submissionChainIdFrom = _onlyDlnDestinationAddress();
        uint256 length = _orderIds.length;
        for (uint256 i; i < length; ++i) {
            _claimCancel(_orderIds[i], _beneficiary, submissionChainIdFrom);
        }
    }

    /// @dev Claim cancel order that was called from take chain
    /// @param _orderId  Order is for cancel
    /// @param _beneficiary User that will receive full refund
    /// # Allowed
    /// Can be called only from debridge external call with validation native sender
    function claimCancel(bytes32 _orderId, address _beneficiary)
        external
        nonReentrant
        whenNotPaused
    {
        uint256 submissionChainIdFrom = _onlyDlnDestinationAddress();
        _claimCancel(_orderId, _beneficiary, submissionChainIdFrom);
    }

    /// @dev Patch give offer of order
    /// To increase the profitability of the order, add amount to the give part
    /// This amount will be kept on the contract until [`claimUnlock`] or [`claimCancel`]
    /// If a patch was previously made, then the new patch can only increase patch amount
    /// @param _order Full order information
    /// @param _addGiveAmount Added to give amount for use in [`claimUnlock`] and [`claimCancel`] methods
    /// @param _permitEnvelope Permit for approving the spender by signature.bytes (amount + deadline + signature)
    /// # Allowed
    /// Can be called only by user with givePatchAuthoritySrc rights
    function patchOrderGive(
        DlnOrderLib.Order memory _order,
        uint256 _addGiveAmount,
        bytes calldata _permitEnvelope
    ) external payable nonReentrant whenNotPaused {
        bytes32 orderId = getOrderId(_order);
        if (_order.givePatchAuthoritySrc.toAddress() != msg.sender)
            revert Unauthorized();
        if (_addGiveAmount == 0) revert WrongArgument();
        GiveOrderState storage orderState = giveOrders[orderId];
        if (orderState.status != OrderGiveStatus.Created) revert IncorrectOrderStatus();

        address giveTokenAddress = _order.giveTokenAddress.toAddress();
        if (giveTokenAddress == address(0)) {
            if (msg.value != _addGiveAmount) revert MismatchNativeGiveAmount();
        }
        else
        {
            _executePermit(giveTokenAddress, _permitEnvelope);
            _safeTransferFrom(
                giveTokenAddress,
                msg.sender,
                address(this),
                _addGiveAmount
            );
        }

        uint256 percentFee = (globalTransferFeeBps * _addGiveAmount) / BPS_DENOMINATOR;
        orderState.percentFee += percentFee.toUint208();
        givePatches[orderId] += _addGiveAmount - percentFee;
        emit IncreasedGiveAmount(orderId, _order.giveAmount + givePatches[orderId], orderState.percentFee);
    }

    /* ========== ADMIN METHODS ========== */

    /// @dev Set DLN destination contract address in another chain
    /// @param _chainIdTo Chain id
    /// @param _dlnDestinationAddress Contract address in another chain
    function setDlnDestinationAddress(uint256 _chainIdTo, bytes memory _dlnDestinationAddress, DlnOrderLib.ChainEngine _chainEngine)
        external
        onlyAdmin
    {
        if(_chainEngine == DlnOrderLib.ChainEngine.UNDEFINED) revert WrongArgument();
        dlnDestinationAddresses[_chainIdTo] = _dlnDestinationAddress;
        chainEngines[_chainIdTo] = _chainEngine;
        emit SetDlnDestinationAddress(_chainIdTo, _dlnDestinationAddress, _chainEngine);
    }

    /// @dev Withdraw collected fee
    /// @param _tokens List of tokens
    /// @param _beneficiary address who will receive tokens
    function withdrawFee(address[] memory _tokens, address _beneficiary) external nonReentrant onlyAdmin {
        uint256 length = _tokens.length;
        for (uint256 i; i < length; ++i) {
            address token = _tokens[i];
            uint256 feeAmount = collectedFee[token];
            _safeTransferEthOrToken(token, _beneficiary, feeAmount);
            collectedFee[token] = 0;
            emit WithdrawnFee(token, feeAmount, _beneficiary);
        }
    }

    /// @dev Update fallbacks for fixed fee in native asset and transfer fee
    /// @param _globalFixedNativeFee Fallback fixed fee in native asset
    /// @param _globalTransferFeeBps Fallback transfer fee in BPS
    function updateGlobalFee(
        uint88 _globalFixedNativeFee,
        uint16 _globalTransferFeeBps
    ) external onlyAdmin {
        _setFixedNativeFee(_globalFixedNativeFee);
        _setTransferFeeBps(_globalTransferFeeBps);
    }

    /* ========== VIEW ========== */

    /**
     * @dev Validates the creation of an order. Throws an exception if incorrect parameters are passed.
     * @param _orderCreation Details of the order to be validated.
     * @param _signer EOA (Externally Owned Account) address that will sign the transaction.
     * @return order Returns the validated order details.
     */
    function validateCreationOrder(DlnOrderLib.OrderCreation memory _orderCreation, address _signer)
        public
        view
        returns (DlnOrderLib.Order memory order)
    {
        return validateCreationOrder(_orderCreation, _signer, uint64(masterNonce[_signer]));
    }

    function validateCreationOrder(DlnOrderLib.OrderCreation memory _orderCreation, address _signer, uint64 _salt)
        public
        view
        returns (DlnOrderLib.Order memory order)
    {
        uint256 dstAddressLength = dlnDestinationAddresses[_orderCreation.takeChainId].length;

        if (dstAddressLength == 0) revert NotSupportedDstChain();
        if (
            _orderCreation.takeTokenAddress.length != dstAddressLength ||
            _orderCreation.receiverDst.length != dstAddressLength ||
            _orderCreation.orderAuthorityAddressDst.length != dstAddressLength ||
            (_orderCreation.allowedTakerDst.length > 0 &&
                _orderCreation.allowedTakerDst.length != dstAddressLength) ||
            (_orderCreation.allowedCancelBeneficiarySrc.length > 0 &&
                _orderCreation.allowedCancelBeneficiarySrc.length != EVM_ADDRESS_LENGTH)
        ) revert WrongAddressLength();

        order.giveChainId = getChainId();
        order.makerOrderNonce = _salt;
        order.makerSrc = abi.encodePacked(_signer);
        order.giveTokenAddress = abi.encodePacked(_orderCreation.giveTokenAddress);
        order.giveAmount = _orderCreation.giveAmount;
        order.takeTokenAddress = _orderCreation.takeTokenAddress;
        order.takeAmount = _orderCreation.takeAmount;
        order.takeChainId = _orderCreation.takeChainId;
        order.receiverDst = _orderCreation.receiverDst;
        order.givePatchAuthoritySrc = abi.encodePacked(_orderCreation.givePatchAuthoritySrc);
        order.orderAuthorityAddressDst = _orderCreation.orderAuthorityAddressDst;
        order.allowedTakerDst = _orderCreation.allowedTakerDst;
        order.externalCall = _orderCreation.externalCall;
        order.allowedCancelBeneficiarySrc = _orderCreation.allowedCancelBeneficiarySrc;
    }


    /* ========== INTERNAL ========== */

    function _pullTokens(DlnOrderLib.OrderCreation calldata _orderCreation, DlnOrderLib.Order memory _order, bytes calldata _permitEnvelope) internal {

        if (_orderCreation.giveTokenAddress == address(0)) {
            if (msg.value != _order.giveAmount + globalFixedNativeFee) revert MismatchNativeGiveAmount();
        }
        else
        {
            if (msg.value != globalFixedNativeFee) revert WrongFixedFee(msg.value, globalFixedNativeFee);

            _executePermit(_orderCreation.giveTokenAddress, _permitEnvelope);
            _safeTransferFrom(
                _orderCreation.giveTokenAddress,
                msg.sender,
                address(this),
                _order.giveAmount
            );
        }
    }

    /// @dev Claim unlock order that was called from take chain
    /// @param _orderId Order id for unlock
    /// @param _beneficiary User that will receive rewards
    /// @param _submissionChainIdFrom submission's chainId that got from deBridgeCallProxy
    function _claimUnlock(bytes32 _orderId, address _beneficiary, uint256 _submissionChainIdFrom) internal {
        GiveOrderState storage orderState = giveOrders[_orderId];
        if (orderState.status != OrderGiveStatus.Created) {
            unexpectedOrderStatusForClaim[_orderId] = _beneficiary;
            emit UnexpectedOrderStatusForClaim(_orderId, orderState.status, _beneficiary);
            return;
        }

        // a circuit breaker in case DlnDestination has been compromised  and is sending claim_unlock commands on behalf
        // of another chain
        if (orderState.takeChainId != _submissionChainIdFrom) {
            emit CriticalMismatchChainId(_orderId, _beneficiary, orderState.takeChainId, _submissionChainIdFrom);
            return;
        }

        uint256 amountToPay = orderState.giveAmount + givePatches[_orderId];
        orderState.status = OrderGiveStatus.ClaimedUnlock;
        address giveTokenAddress =  address(orderState.giveTokenAddress);
        _safeTransferEthOrToken(giveTokenAddress, _beneficiary, amountToPay);
        // send affiliateFee to affiliateFee beneficiary
        if (orderState.affiliateAmount > 0) {
            bool success;

            if (giveTokenAddress == address(0)) {
                (success, ) = orderState.affiliateBeneficiary.call{value: orderState.affiliateAmount, gas: 2300}(new bytes(0));
                if (!success) {
                    unclaimedAffiliateETHFees[orderState.affiliateBeneficiary] += orderState.affiliateAmount;
                }
            }
            else {
                IERC20Upgradeable(giveTokenAddress).safeTransfer(
                    orderState.affiliateBeneficiary,
                    orderState.affiliateAmount
                );
                success = true;
            }

            if (success) {
                emit AffiliateFeePaid(
                    _orderId,
                    orderState.affiliateBeneficiary,
                    orderState.affiliateAmount,
                    giveTokenAddress
                );
            }
        }
        emit ClaimedUnlock(
            _orderId,
            _beneficiary,
            amountToPay,
            giveTokenAddress
        );
        // Collected fee
        collectedFee[giveTokenAddress] += orderState.percentFee;
        collectedFee[address(0)] += orderState.nativeFixFee;
    }

    /// @dev Claim cancel order that was called from take chain
    /// @param _orderId  Order is for cancel
    /// @param _beneficiary User that will receive full refund
    /// @param _submissionChainIdFrom submission's chainId that got from deBridgeCallProxy
    function _claimCancel(bytes32 _orderId, address _beneficiary, uint256 _submissionChainIdFrom) internal {
        GiveOrderState storage orderState = giveOrders[_orderId];
        if (orderState.takeChainId != _submissionChainIdFrom) {
            revert CriticalMismatchTakeChainId(_orderId, orderState.takeChainId, _submissionChainIdFrom);
        }
        uint256 amountToPay = orderState.giveAmount +
                orderState.percentFee +
                orderState.affiliateAmount +
                givePatches[_orderId];
        if (orderState.status == OrderGiveStatus.Created) {
            orderState.status = OrderGiveStatus.ClaimedCancel;
            address giveTokenAddress = address(orderState.giveTokenAddress);
            _safeTransferEthOrToken(giveTokenAddress, _beneficiary, amountToPay);
            _safeTransferETH(_beneficiary, orderState.nativeFixFee);
            emit ClaimedOrderCancel(
                _orderId,
                _beneficiary,
                amountToPay,
                giveTokenAddress
            );
        } else {
            unexpectedOrderStatusForCancel[_orderId] = _beneficiary;
            emit UnexpectedOrderStatusForCancel(_orderId, orderState.status, _beneficiary);
        }
    }

    function _setFixedNativeFee(uint88 _globalFixedNativeFee) internal {
        uint88 oldGlobalFixedNativeFee = globalFixedNativeFee;
        if (oldGlobalFixedNativeFee != _globalFixedNativeFee) {
            globalFixedNativeFee = _globalFixedNativeFee;
            emit GlobalFixedNativeFeeUpdated(oldGlobalFixedNativeFee, _globalFixedNativeFee);
        }
    }

    function _setTransferFeeBps(uint16 _globalTransferFeeBps) internal {
        uint16 oldGlobalTransferFeeBps = globalTransferFeeBps;
        if (oldGlobalTransferFeeBps != _globalTransferFeeBps) {
            globalTransferFeeBps = _globalTransferFeeBps;
            emit GlobalTransferFeeBpsUpdated(oldGlobalTransferFeeBps, _globalTransferFeeBps);
        }
    }

    /// @dev Check that method was called by correct dlnDestinationAddresses from the take chain
    function _onlyDlnDestinationAddress() internal view returns (uint256 submissionChainIdFrom) {
        ICallProxy callProxy = ICallProxy(deBridgeGate.callProxy());
        if (address(callProxy) != msg.sender) revert CallProxyBadRole();

        bytes memory nativeSender = callProxy.submissionNativeSender();
        submissionChainIdFrom = callProxy.submissionChainIdFrom();
        if (keccak256(dlnDestinationAddresses[submissionChainIdFrom]) != keccak256(nativeSender)) {
            revert NativeSenderBadRole(nativeSender, submissionChainIdFrom);
        }
        return submissionChainIdFrom;
    }

    /* ========== Version Control ========== */

    /// @dev Get this contract's version
    function version() external pure returns (string memory) {
        return "1.3.0";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "../libraries/DlnOrderLib.sol";

interface IDlnDestination {
    /**
     * @notice This function allows a taker to fulfill an order from another chain in the DLN protocol.
     *
     * @dev During the execution of this method:
     * - The `take` part of the order from the `taker` is sent to the `receiver` of the order.
     * - If a patch order was taken previously, the patch amount is deducted.
     * - After the above step, the `taker` can invoke `send_unlock` to receive the `give` part of the order on the specified chain.
     *
     * @param _order Full order to be fulfilled. This includes details about the order such as the `give` part, `take` part, and the `receiver`.
     * @param _fulFillAmount Amount the taker is expected to pay for this order. This is used for validation to ensure the taker pays the correct amount.
     * @param _orderId Unique identifier of the order to be fulfilled. This is used to verify that the taker is fulfilling the correct order.
     * @param _permitEnvelope Permit for approving the spender by signature. This parameter includes the amount, deadline, and signature.
     * @param _unlockAuthority Address authorized to unlock the order by calling send{Evm,Solana}Unlock after successful fulfillment of the order.
     *
     * @notice It checks if the taker is allowed based on the order's `allowedTakerDst` field.
     * - If `allowedTakerDst` is None, anyone with sufficient tokens can fulfill the order.
     * - If `allowedTakerDst` is Some, only the specified address can fulfill the order.
     */
    function fulfillOrder(
        DlnOrderLib.Order memory _order,
        uint256 _fulFillAmount,
        bytes32 _orderId,
        bytes calldata _permitEnvelope,
        address _unlockAuthority
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../libraries/DlnOrderLib.sol";

interface IDlnSource {
    /**
     * @notice This function returns the global fixed fee in the native asset of the protocol.
     * @dev This fee is denominated in the native asset (like Ether in Ethereum).
     * @return uint88 This return value represents the global fixed fee in the native asset.
     */
    function globalFixedNativeFee() external returns (uint88);

    /**
     * @notice This function provides the global transfer fee, expressed in Basis Points (BPS).
     * @dev It retrieves a global fee which is applied to order.giveAmount. The fee is represented in Basis Points (BPS), where 1 BPS equals 0.01%.
     * @return uint16 The return value represents the global transfer fee in BPS.
     */
    function globalTransferFeeBps() external returns (uint16);

    /**
     * @dev Places a new order with pseudo-random orderId onto the DLN
     * @notice deprecated
     * @param _orderCreation a structured parameter from the DlnOrderLib.OrderCreation library, containing all the necessary information required for creating a new order.
     * @param _affiliateFee a bytes parameter specifying the affiliate fee that will be rewarded to the beneficiary. It includes the beneficiary's details and the affiliate amount.
     * @param _referralCode a 32-bit unsigned integer containing the referral code. This code is traced back to the referral source or person that facilitated this order. This code is also emitted in an event for tracking purposes.
     * @param _permitEnvelope a bytes parameter that is used to approve the spender through a signature. It contains the amount, the deadline, and the signature.
     * @return bytes32 identifier (orderId) of a newly placed order
     */
    function createOrder(
        DlnOrderLib.OrderCreation calldata _orderCreation,
        bytes calldata _affiliateFee,
        uint32 _referralCode,
        bytes calldata _permitEnvelope
    ) external payable returns (bytes32);

    /**
     * @dev Places a new order with deterministic orderId onto the DLN
     * @param _orderCreation a structured parameter from the DlnOrderLib.OrderCreation library, containing all the necessary information required for creating a new order.
     * @param _salt an input source of randomness for getting a deterministic identifier of an order (orderId)
     * @param _affiliateFee a bytes parameter specifying the affiliate fee that will be rewarded to the beneficiary. It includes the beneficiary's details and the affiliate amount.
     * @param _referralCode a 32-bit unsigned integer containing the referral code. This code is traced back to the referral source or person that facilitated this order. This code is also emitted in an event for tracking purposes.
     * @param _permitEnvelope a bytes parameter that is used to approve the spender through a signature. It contains the amount, the deadline, and the signature.
     * @param _payload an arbitrary data to be tied together with the order for future off-chain analysis
     * @return bytes32 identifier (orderId) of a newly placed order
     */
    function createSaltedOrder(
        DlnOrderLib.OrderCreation calldata _orderCreation,
        uint64 _salt,
        bytes calldata _affiliateFee,
        uint32 _referralCode,
        bytes calldata _permitEnvelope,
        bytes calldata _payload
    ) external payable returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @title Interface for interactor which acts after `fullfill Order` transfers.
 * @notice DLN Destincation contract call receiver contract with information about order
*/
interface IExternalCallAdapter {
    /**
     * @notice Callback method that gets called after maker funds transfers
     * @param _orderId Hash of the order being processed
     * @param _callAuthority Address that can cancel external call and send tokens to fallback address
     * @param _tokenAddress  token that was transferred to adapter
     * @param _transferredAmount Actual amount that was transferred to adapter
     * @param _externalCall call data
     * @param _externalCallRewardBeneficiary Reward beneficiary address that will receiv execution fee. If address is 0 will not execute external call.
     */
    function receiveCall(
        bytes32 _orderId,
        address _callAuthority,
        address _tokenAddress,
        uint256 _transferredAmount,
        bytes calldata _externalCall,
        address _externalCallRewardBeneficiary
    ) external;
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toAddress(bytes memory _bytes) internal pure returns (address) {
        require(_bytes.length == 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), 0)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library DlnOrderLib {
    
    enum ChainEngine {
        UNDEFINED, //0
        EVM, // 1
        SOLANA // 2
    }

    struct OrderCreation {
        address giveTokenAddress;
        uint256 giveAmount;
        bytes takeTokenAddress;
        uint256 takeAmount;
        uint256 takeChainId;
        bytes receiverDst;
        address givePatchAuthoritySrc;
        /// If the field is `Some`, then only this address can receive cancel
        bytes orderAuthorityAddressDst;
        /// allowedTakerDst * optional
        bytes allowedTakerDst;
        /// externalCall * optional
        bytes externalCall;
        /// Address in source chain
        /// If the field is `Some`, then only this address can receive cancel
        /// * optional
        bytes allowedCancelBeneficiarySrc;
    }

    struct Order {
        /// Unique nonce number for each maker
        /// Together with the maker, it forms the uniqueness for the order,
        /// which is important for calculating the order id
        uint64 makerOrderNonce;
        /// Order maker address
        /// Address in source chain
        bytes makerSrc;
        uint256 giveChainId;
        bytes giveTokenAddress;
        uint256 giveAmount;
        uint256 takeChainId;
        bytes takeTokenAddress;
        uint256 takeAmount;
        bytes receiverDst;
        bytes givePatchAuthoritySrc;
        /// Address in destination chain
        /// Can `send_order_cancel`, `process_fallback` and `patch_order_take`
        bytes orderAuthorityAddressDst;
        /// allowedTakerDst * optional
        bytes allowedTakerDst;
        /// Address in source chain
        /// If the field is `Some`, then only this address can receive cancel
        /// * optional
        bytes allowedCancelBeneficiarySrc;
        /// externalCall * optional
        bytes externalCall;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

library EncodeSolanaDlnMessage {
    bytes8 public constant CLAIM_DESCRIMINATOR = 0x5951b44f8e9042fb;
    bytes8 public constant CANCEL_DESCRIMINATOR = 0x13617eeecc8d454c;

    function encodeInitWalletIfNeededInstruction(
        bytes32 _actionBeneficiary,
        bytes32 _orderGiveTokenAddress,
        uint64 _reward
    ) internal pure returns (bytes memory encodedData) {
        encodedData = abi.encodePacked(
            // Index 0: Field (8): Reward 1:
            // convert to Little Endian
            reverse(_reward),
            // Index 8: Const (86): "01f01d1f0000000000000000000101000000000000000100000000000000010000008c97258f4e2489f1bb3d1029148e0d830b5a1399daff1084048e7bd8dbe9f8590300000000000000000000002000000000000000"
            hex"01f01d1f0000000000000000000101000000000000000100000000000000010000008c97258f4e2489f1bb3d1029148e0d830b5a1399daff1084048e7bd8dbe9f8590300000000000000000000002000000000000000",
            // Index 94: Field (32): Action Beneficiary
            _actionBeneficiary,
            // Index 126: Const (56): "00000000200000000000000006ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a9000000002000000000000000"
            hex"00000000200000000000000006ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a9000000002000000000000000",
            // Index 182: Field (32): Give Token Address
            _orderGiveTokenAddress,
            // Index 214: Const (110): "00008c97258f4e2489f1bb3d1029148e0d830b5a1399daff1084048e7bd8dbe9f85906000000000000001968562fef0aab1b1d8f99d44306595cd4ba41d7cc899c007a774d23ad702ff601019f3d96f657370bf1dbb3313efba51ea7a08296ac33d77b949e1b62d538db37f20001"
            hex"00008c97258f4e2489f1bb3d1029148e0d830b5a1399daff1084048e7bd8dbe9f85906000000000000001968562fef0aab1b1d8f99d44306595cd4ba41d7cc899c007a774d23ad702ff601019f3d96f657370bf1dbb3313efba51ea7a08296ac33d77b949e1b62d538db37f20001",
            // Index 324: Field (32): Action Beneficiary
            _actionBeneficiary,
            // Index 356: Const (2): "0000"
            hex"0000",
            // Index 358: Field (32): Give Token Address
            _orderGiveTokenAddress,
            // Index 390: Const (79): "00000000000000000000000000000000000000000000000000000000000000000000000006ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a90000010000000000000001"
            hex"00000000000000000000000000000000000000000000000000000000000000000000000006ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a90000010000000000000001"
        );
    }

    function encodeClaimUnlockInstruction(
        uint256 _takeChainId,
        bytes32 _srcProgramId,
        bytes32 _actionBeneficiary,
        bytes32 _orderGiveTokenAddress,
        bytes32 _orderId,
        uint64 _reward2
    ) internal pure returns (bytes memory encodedClaimData) {
        return
            _encodeCall(
                _takeChainId,
                _srcProgramId,
                _actionBeneficiary,
                _orderGiveTokenAddress,
                _orderId,
                _reward2,
                CLAIM_DESCRIMINATOR
            );
    }

    function encodeClaimCancelInstruction(
        uint256 _takeChainId,
        bytes32 _srcProgramId,
        bytes32 _actionBeneficiary,
        bytes32 _orderGiveTokenAddress,
        bytes32 _orderId,
        uint64 _reward2
    ) internal pure returns (bytes memory encodedClaimData) {
        return
            _encodeCall(
                _takeChainId,
                _srcProgramId,
                _actionBeneficiary,
                _orderGiveTokenAddress,
                _orderId,
                _reward2,
                CANCEL_DESCRIMINATOR
            );
    }

    function _encodeCall(
        uint256 _takeChainId,
        bytes32 _srcProgramId,
        bytes32 _actionBeneficiary,
        bytes32 _orderGiveTokenAddress,
        bytes32 _orderId,
        uint64 _reward2,
        bytes8 _discriminator
    ) private pure returns (bytes memory encodedData) {
        {
            encodedData = abi.encodePacked(
                // Index 469: Field (8): Reward 2:
                // convert to Little Endian
                reverse(_reward2),
                // Index 477: Const (26): "0000000000010700000000000000020000000000000001000000"
                hex"0000000000010700000000000000020000000000000001000000",
                // Index 503: Field (32): Program Id
                _srcProgramId,
                // Index 535: Const (38): "0100000000000000000000000500000000000000535441544500030000000000000001000000"
                hex"0100000000000000000000000500000000000000535441544500030000000000000001000000",
                // Index 573: Field (32): Program Id
                _srcProgramId,
                // Index 605: Const (43): "0100000000000000000000000a00000000000000464545204c454447455200040000000000000001000000"
                hex"0100000000000000000000000a00000000000000464545204c454447455200040000000000000001000000",
                // Index 648: Field (32): Program Id
                _srcProgramId,
                // Index 680: Const (49): "02000000000000000000000011000000000000004645455f4c45444745525f57414c4c4554000000002000000000000000"
                hex"02000000000000000000000011000000000000004645455f4c45444745525f57414c4c4554000000002000000000000000",
                // Index 729: Field (32): Give Token Address
                _orderGiveTokenAddress,
                // Index 761: Const (13): "00060000000000000001000000"
                hex"00060000000000000001000000",
                // Index 774: Field (32): Program Id
                _srcProgramId,
                // Index 806: Const (48): "0200000000000000000000001000000000000000474956455f4f524445525f5354415445000000002000000000000000"
                hex"0200000000000000000000001000000000000000474956455f4f524445525f5354415445000000002000000000000000",
                // Index 854: Field (32): Order Id
                _orderId,
                // Index 886: Const (65): "000700000000000000010000008c97258f4e2489f1bb3d1029148e0d830b5a1399daff1084048e7bd8dbe9f8590300000000000000000000002000000000000000"
                hex"000700000000000000010000008c97258f4e2489f1bb3d1029148e0d830b5a1399daff1084048e7bd8dbe9f8590300000000000000000000002000000000000000",
                // Index 951: Field (32): Action Beneficiary
                _actionBeneficiary,
                // Index 983: Const (56): "00000000200000000000000006ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a9000000002000000000000000"
                hex"00000000200000000000000006ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a9000000002000000000000000",
                 // Index 1039: Field (32): Give Token Address
                _orderGiveTokenAddress,
                // Index 1071: Const (13): "00090000000000000001000000"
                hex"00090000000000000001000000",
                 // Index 1084: Field (32): Program Id
                _srcProgramId
            );
        }
        {
            encodedData = abi.encodePacked(
                encodedData,
                // Index 1116: Const (49): "0200000000000000000000001100000000000000474956455f4f524445525f57414c4c4554000000002000000000000000"
                hex"0200000000000000000000001100000000000000474956455f4f524445525f57414c4c4554000000002000000000000000",
                // Index 1165: Field (32): Order Id
                _orderId,
                // Index 1197: Const (13): "000b0000000000000001000000"
                hex"000b0000000000000001000000",
                // Index 1210: Field (32): Program Id
                _srcProgramId,
                // Index 1242: Const (56): "0200000000000000000000001800000000000000415554484f52495a45445f4e41544956455f53454e444552000000002000000000000000"
                hex"0200000000000000000000001800000000000000415554484f52495a45445f4e41544956455f53454e444552000000002000000000000000",
                // Index 1298: Field (32): Take Chain Id
                _takeChainId,
                // Index 1330: Const (2): "0000"
                hex"0000",
                // Index 1332: Field (32): Program Id
                _srcProgramId,
                // Index 1364: Const (280): "0d0000000000000062584959deb8a728a91cebdc187b545d920479265052145f31fb80c73fac5aea00001968562fef0aab1b1d8f99d44306595cd4ba41d7cc899c007a774d23ad702ff60101980176896e24d940ee6f0a89d0020e1cd53aa3d17be42270bb39223f6ed75c6300018c6ecc336484fb8f32871d3c1656d832cc86eb2465048fea348cde76ae57233100014026e8772b7640ce6fb9fd348473f43df344e3dcd89a43c93db81ee6efe08e67000106a7d517187bd16635dad40455fdc2c0c124c68f215675a5dbbacb5f080000000000107fe6a33e564217c5773c604a479581564c5e4c12465d65c9374ee2190f5ee400019f3d96f657370bf1dbb3313efba51ea7a08296ac33d77b949e1b62d538db37f20001"
                hex"0d0000000000000062584959deb8a728a91cebdc187b545d920479265052145f31fb80c73fac5aea00001968562fef0aab1b1d8f99d44306595cd4ba41d7cc899c007a774d23ad702ff60101980176896e24d940ee6f0a89d0020e1cd53aa3d17be42270bb39223f6ed75c6300018c6ecc336484fb8f32871d3c1656d832cc86eb2465048fea348cde76ae57233100014026e8772b7640ce6fb9fd348473f43df344e3dcd89a43c93db81ee6efe08e67000106a7d517187bd16635dad40455fdc2c0c124c68f215675a5dbbacb5f080000000000107fe6a33e564217c5773c604a479581564c5e4c12465d65c9374ee2190f5ee400019f3d96f657370bf1dbb3313efba51ea7a08296ac33d77b949e1b62d538db37f20001",
                // Index 1644: Field (32): Action Beneficiary
                _actionBeneficiary,
                // Index 1676: Const (36): "00011507b8f891ebbfc57577d4d2e6a2b52dc0a744eba2be503e686d0d07d19e6ec70001"
                hex"00011507b8f891ebbfc57577d4d2e6a2b52dc0a744eba2be503e686d0d07d19e6ec70001",
                // Index 1712: Field (32): Give Token Address
                _orderGiveTokenAddress,
                // Index 1744: Const (78): "0000efe9c4afa6dc798a27b0c18e3cf0b76ad3fe8cc93764f6cb3112f9397f2cd1c6000006ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a900002800000000000000"
                hex"0000efe9c4afa6dc798a27b0c18e3cf0b76ad3fe8cc93764f6cb3112f9397f2cd1c6000006ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a900002800000000000000",
                // Index 1822: Field (8): Discriminator
                _discriminator,
                // Index 1830: Field (32): Order Id
                _orderId
            );
        }
        return encodedData;
    }

    function reverse(uint64 input) private pure returns (uint64 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00) >> 8) | ((v & 0x00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000) >> 16) | ((v & 0x0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = (v >> 32) | (v << 32);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}