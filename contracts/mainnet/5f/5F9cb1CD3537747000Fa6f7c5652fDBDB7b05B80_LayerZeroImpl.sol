// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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
pragma solidity ^0.8.7;

import "./interfaces/IFactory.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IERC20Extended {
    function decimals() external view returns (uint8);
}

interface Safe {
    function isOwner(address owner) external view returns (bool);
}

contract Helper {
    ///@dev Admin role
    bytes32 constant ADMIN = keccak256("ADMIN");

    uint8 constant UNIFORM_DECIMALS = 18;

    bytes32 constant operationNameAND = keccak256(abi.encodePacked(("AND")));
    bytes32 constant operationNameOR = keccak256(abi.encodePacked(("OR")));

    uint256 constant EIGHTEEN_DECIMALS = 1e18;

    uint256 constant FLOAT_HANDLER_TEN_4 = 10000;

    struct DAODetails {
        uint256 pricePerToken;
        uint256 distributionAmount;
        uint256 minDepositPerUser;
        uint256 maxDepositPerUser;
        uint256 ownerFeePerDepositPercent;
        uint256 depositCloseTime;
        address depositTokenAddress;
        address gnosisAddress;
        bytes32 merkleRoot;
        bool isDeployedByFactory;
        bool isTokenGatingApplied;
        bool assetsStoredOnGnosis;
    }

    struct CrossChainDetails {
        uint16 commLayerId;
        uint256[] depositChainIds;
        bool isDefaultChain;
        address ownerAddress;
        bool onlyAllowWhitelist;
    }

    struct ERC20DAOdetails {
        string DaoName;
        string DaoSymbol;
        uint256 quorum;
        uint256 threshold;
        bool isGovernanceActive;
        bool isTransferable;
        bool onlyAllowWhitelist;
        address ownerAddress;
    }

    struct ERC721DAOdetails {
        string DaoName;
        string DaoSymbol;
        uint256 quorum;
        uint256 threshold;
        uint256 maxTokensPerUser;
        bool isTransferable;
        bool isNftTotalSupplyUnlimited;
        bool isGovernanceActive;
        bool onlyAllowWhitelist;
        address ownerAddress;
    }

    enum Operator {
        AND,
        OR
    }
    enum Comparator {
        GREATER,
        BELOW,
        EQUAL
    }

    struct TokenGatingCondition {
        address[] tokens;
        Operator operator;
        uint256[] value;
    }

    //implementation contract errors
    error AmountInvalid(string _param, uint256 _amount);
    error NotERC20Template();
    error DepositAmountInvalid(
        uint256 _maxDepositPerUser,
        uint256 _minDepositPerUser
    );
    error DepositClosed();
    error DepositStarted();
    error Max4TokensAllowed(uint256 _length);
    error ArrayLengthMismatch(uint256 _length1, uint256 _length2);
    error AddressInvalid(string _param, address _address);
    error InsufficientFunds();
    error InvalidData();
    error InsufficientAllowance(uint256 required, uint256 current);
    error SafeProxyCreationFailed(string _reason);

    //nft contract errors
    error NotWhitelisted();
    error MaxTokensMinted();
    error NoAccess(address _user);
    error MintingNotOpen();
    error MaxTokensMintedForUser(address _user);

    error RaiseAmountInvalid(
        uint256 _totalRaiseAmount,
        uint256 _maxDepositPerUser
    );

    error InsufficientBalance();
    error InsufficientFees();

    error NotDefaultChain();
    error IncorrectProof();

    /// @dev onlyOwner modifier to allow only Owner access to functions
    modifier onlyGnosis(address _factory, address _daoAddress) {
        require(
            IFactory(_factory).getDAOdetails(_daoAddress).gnosisAddress ==
                msg.sender,
            "Only Gnosis"
        );
        _;
    }

    modifier onlyGnosisOrDao(address _factory, address _daoAddress) {
        require(
            IFactory(_factory).getDAOdetails(_daoAddress).gnosisAddress ==
                msg.sender ||
                _daoAddress == msg.sender,
            "Only Gnosis or Dao"
        );
        _;
    }

    modifier onlyFactory(address _factory) {
        require(msg.sender == _factory);
        _;
    }

    modifier onlyFactoryDeployed(address _factory) {
        require(
            IFactory(_factory).getDAOdetails(address(this)).isDeployedByFactory
        );
        _;
    }

    modifier onlyCurrentContract() {
        require(msg.sender == address(this));
        _;
    }

    modifier onlyAdmins(address _safe) {
        require(Safe(_safe).isOwner(msg.sender), "Only owner access");
        _;
    }

    function amountToSD(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        uint8 decimals;
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            decimals = 18;
        } else {
            decimals = IERC20Extended(token).decimals();
        }
        if (decimals == 18) {
            return amount;
        } else {
            uint256 convertRate = 10 ** (18 - decimals);
            return amount * convertRate;
        }
    }

    function amountToLD(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        uint8 decimals;
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            decimals = 18;
        } else {
            decimals = IERC20Extended(token).decimals();
        }
        if (decimals == 18) {
            return amount;
        } else {
            uint256 convertRate = 10 ** (18 - decimals);
            return amount / convertRate;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ICommLayer {
    function sendMsg(address, bytes memory, bytes memory) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../helper.sol";

interface IFactory {
    function getDAOdetails(address) external returns (Helper.DAODetails memory);

    function crossChainMint(
        address,
        address,
        uint256,
        string calldata,
        bytes32[] calldata
    ) external;

    function createCrossChainERC20DAO(
        uint16,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256[] calldata,
        address,
        address,
        address[] memory,
        bool,
        bytes32
    ) external;

    function createCrossChainERC721DAO(
        uint16,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256[] memory,
        address,
        address,
        address[] memory,
        uint256,
        uint256,
        uint256,
        bool,
        bytes32
    ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint constant LOW_28_MASK =
        0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                0, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
                _gas, // gas
                _target, // recipient
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(
        bytes4 _newSelector,
        bytes memory _buf
    ) internal pure {
        require(_buf.length >= 4);
        uint _mask = LOW_28_MASK;
        assembly {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

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
    ) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(
        uint16 _srcChainId,
        bytes calldata _srcAddress
    ) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(
        uint16 _dstChainId,
        address _srcAddress
    ) external view returns (uint64);

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
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress
    ) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(
        address _userApplication
    ) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(
        address _userApplication
    ) external view returns (address);

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
    ) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(
        address _userApplication
    ) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(
        address _userApplication
    ) external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

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
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint _configType,
        bytes calldata _config
    ) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress
    ) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

import "../interfaces/IFactory.sol";
import "../interfaces/ICommLayer.sol";
import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";
import "./ExcessivelySafeCall.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LayerZeroImpl is ICommLayer, ILayerZeroReceiver, Initializable {
    using ExcessivelySafeCall for address;

    /// @notice LayerZero endoint address
    ILayerZeroEndpoint public endpoint;

    IFactory public factory;

    address private owner;

    /// @notice mapping to keep track of failed messages
    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32)))
        public failedMessages;

    mapping(uint16 => address) private dstCommLayer;

    /// @notice Extra LayerZero fees customization parameters
    struct lzAdapterParams {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    event msgSent(
        uint16 _dstChainId,
        bytes _destination,
        bytes _payload,
        uint256 nonce
    );
    event ReceiveMsg(
        uint16 _srcChainId,
        address _from,
        bytes _payload,
        uint256 nonce
    );
    event RetriedPayload(uint16 _srcChainId, bytes _srcAddress, bytes _payload);
    event ForceResumed(uint16 _srcChainId, bytes _srcAddress, bytes _payload);
    event MessageFailed(
        uint16 _srcChainId,
        bytes _srcAddress,
        uint64 _nonce,
        bytes _payload,
        bytes _reason
    );

    function initialize(
        address _endpoint,
        address _factory
    ) external initializer {
        endpoint = ILayerZeroEndpoint(_endpoint);
        factory = IFactory(_factory);
        owner = msg.sender;
    }

    modifier onlyFactory() {
        require(msg.sender == address(factory), "Only Factory");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /// @notice This function is responsible for setting source LayerZeroImpl addresses
    /// @dev onlyOwner is allowed to call this function
    /// @param _factory factory address
    function changeFactory(address _factory) external onlyOwner {
        factory = IFactory(_factory);
    }

    /// @notice This function is responsible to estimate fees required for sending message
    /// @param _dstChainId Destination Chain Id
    /// @param _userApplication Destination contract address
    /// @param _payload Encoded data to send on destination chain
    /// @param _adapterParameters Extra fees customization parameters
    /// @return nativeFee Fees required in native token
    /// @return zroFee Fees required in zro token
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bytes calldata _adapterParameters
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        return
            endpoint.estimateFees(
                _dstChainId,
                _userApplication,
                _payload,
                false,
                _adapterParameters
            );
    }

    /// @notice This function is responsible for setting source LayerZeroImpl addresses
    /// @dev onlyOwner is allowed to call this function
    /// @param _endpoint Source chain LayerZeroImpl address
    function changeEndpoint(address _endpoint) external onlyOwner {
        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    /// @notice This function is responsible for sending messages to another chain using LayerZero
    /// @dev It makes call to LayerZero endpoint contract
    /// @dev This function can only be called from CommLayerAggregator
    /// @param _destination Address of destination contract to send message on
    /// @param _payload Encoded data to send on destination chain
    function sendMsg(
        address _destination,
        bytes calldata _payload,
        bytes memory extraParams
    ) public payable onlyFactory {
        (uint16 _dstChainId, address refundAd) = abi.decode(
            extraParams,
            (uint16, address)
        );

        uint64 nextNonce = endpoint.getOutboundNonce(
            _dstChainId,
            address(this)
        ) + 1;

        endpoint.send{value: msg.value}(
            _dstChainId,
            abi.encodePacked(dstCommLayer[uint16(_dstChainId)], address(this)),
            _payload,
            payable(refundAd),
            address(0x0),
            abi.encodePacked(uint16(1), uint256(600000))
        );
        emit msgSent(
            _dstChainId,
            abi.encodePacked(dstCommLayer[uint16(_dstChainId)]),
            _payload,
            nextNonce
        );
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public virtual override {
        require(
            msg.sender == address(endpoint),
            "LzApp: invalid endpoint caller"
        );
        bytes memory trustedRemote = abi.encodePacked(
            dstCommLayer[_srcChainId],
            address(this)
        );
        require(
            _srcAddress.length == trustedRemote.length &&
                trustedRemote.length > 0 &&
                keccak256(_srcAddress) == keccak256(trustedRemote),
            "LzApp: invalid source sending contract"
        );
        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(
            gasleft(),
            150,
            abi.encodeWithSelector(
                this.nonblockingLzReceive.selector,
                _srcChainId,
                _srcAddress,
                _nonce,
                _payload
            )
        );

        if (!success) {
            _storeFailedMessage(
                _srcChainId,
                _srcAddress,
                _nonce,
                _payload,
                reason
            );
        }
    }

    function _storeFailedMessage(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload,
        bytes memory _reason
    ) internal virtual {
        failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
        emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload, _reason);
    }

    function nonblockingLzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public virtual {
        require(
            msg.sender == address(this),
            "NonblockingLzApp: caller must be LzApp"
        );
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _from,
        uint64 _nonce,
        bytes memory _payload
    ) internal {
        address from;
        assembly {
            from := mload(add(_from, 20))
        }
        require(msg.sender == address(endpoint));
        require(from == dstCommLayer[_srcChainId]);
        if (
            keccak256(abi.encodePacked((_payload))) ==
            keccak256(abi.encodePacked((bytes10("ff"))))
        ) {
            endpoint.receivePayload(
                1,
                bytes(""),
                address(0x0),
                1,
                1,
                bytes("")
            );
        }
        (
            address _daoAddress,
            address _receiver,
            uint256 _amount,
            string memory _tokenURI,
            bytes32[] memory _merkleProof
        ) = abi.decode(
                _payload,
                (address, address, uint256, string, bytes32[])
            );

        IFactory(factory).crossChainMint(
            _receiver,
            _daoAddress,
            _amount,
            _tokenURI,
            _merkleProof
        );

        emit ReceiveMsg(_srcChainId, from, _payload, _nonce);
    }

    function forceResume(
        uint16 _srcChainId,
        bytes memory _from
    ) external onlyOwner {
        endpoint.forceResumeReceive(_srcChainId, _from);
    }

    function setDestination(
        uint16 _chainId,
        address _dstCommLayer
    ) external onlyOwner {
        dstCommLayer[_chainId] = _dstCommLayer;
    }

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external onlyOwner {
        endpoint.setSendVersion(_version);
    }

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external onlyOwner {
        endpoint.setReceiveVersion(_version);
    }
}