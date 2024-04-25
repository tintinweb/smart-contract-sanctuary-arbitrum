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
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../libraries/PausabilityLib.sol";
import "../libraries/InitializerLib.sol";
import "../libraries/RolesManagementLib.sol";

abstract contract BaseFacet is Initializable {
    error DelegatedCallsOnly();
    
    /// @dev An address of the actual contract instance. The original address as part of the context.
    address internal immutable __self = address(this);

    function enforceDelegatedOnly() internal view {
        if (address(this) == __self || !InitializerLib.get().initialized) {
            revert DelegatedCallsOnly();
        }
    }

    /// @dev The body of the modifier is copied into a faucet sources, so to make a small gas
    /// optimization - the modifier uses an internal function call.
    modifier delegatedOnly {
        enforceDelegatedOnly();
        _;
    }

    modifier internalOnly {
        RolesManagementLib.enforceSenderRole(RolesManagementLib.INTERNAL_ROLE);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../libraries/RolesManagementLib.sol";
import "../interfaces/IRolesManagement.sol";
import "./BaseFacet.sol";

contract RolesManagementFacet is IRolesManagement, BaseFacet {
    error UnequalLengths(uint256 length1, uint256 length2);

    function grantRoles(address[] calldata people, bytes32[] calldata roles) 
        external 
        override 
        delegatedOnly
    {
        RolesManagementLib.enforceSenderRole(RolesManagementLib.OWNER_ROLE);
        if (people.length != roles.length) {
            revert UnequalLengths(people.length, roles.length);
        }
        for (uint256 i = 0; i < people.length; i++) {
            RolesManagementLib.grantRole(people[i], roles[i]);
        }
    }

    function revokeRoles(address[] calldata people, bytes32[] calldata roles) 
        external 
        override 
        delegatedOnly
    {
        RolesManagementLib.enforceSenderRole(RolesManagementLib.OWNER_ROLE);
        if (people.length != roles.length) {
            revert UnequalLengths(people.length, roles.length);
        }
        for (uint256 i = 0; i < people.length; i++) {
            RolesManagementLib.revokeRole(people[i], roles[i]);
        }
    }
    
    function grantRole(address who, bytes32 role) public override delegatedOnly {
        RolesManagementLib.enforceSenderRole(RolesManagementLib.OWNER_ROLE);
        RolesManagementLib.grantRole(who, role);
    }

    function revokeRole(address who, bytes32 role) public override delegatedOnly {
        RolesManagementLib.enforceSenderRole(RolesManagementLib.OWNER_ROLE);
        RolesManagementLib.revokeRole(who, role);
    }

    function hasRole(address who, bytes32 role) external view override delegatedOnly returns(bool) {
        return RolesManagementLib.get().roles[role][who];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IRolesManagement {
    function revokeRoles(address[] calldata entities, bytes32[] calldata roles) external;
    function grantRoles(address[] calldata entities, bytes32[] calldata roles) external;
    function grantRole(address who, bytes32 role) external;
    function revokeRole(address who, bytes32 role) external;
    function hasRole(address who, bytes32 role) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library InitializerLib {
    error AlreadyInitialized();
    error NotImplemented();

    bytes32 constant INITIALIZER_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage.locus.initializer");

    struct Storage {
        bool initialized;
    }

    function get() internal pure returns (Storage storage s) {
        bytes32 position = INITIALIZER_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function reset() internal {
        get().initialized = false;
    }

    function initialize() internal {
        if (get().initialized) {
            revert AlreadyInitialized();
        } else {
            get().initialized = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library PausabilityLib {
    error OnlyWhenNotPaused();
    
    bytes32 constant PAUSABILITY_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage.locus.pausability");

    struct Storage {
        bool paused;
    }

    function get() internal pure returns (Storage storage s) {
        bytes32 position = PAUSABILITY_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library RolesManagementLib {
    event RoleSet(address who, bytes32 role, bool isGrantedOrRevoked);

    error HasNoRole(address who, bytes32 role);
    error HasNoRoles(address who, bytes32[] roles);

    bytes32 constant ROLES_MANAGEMENT_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage.locus.roles");

    // roles to check with EOA
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
    bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');

    // A special role - must not be removed.
    bytes32 public constant INTERNAL_ROLE = keccak256('INTERNAL_ROLE');

    // roles to check with smart-contracts
    bytes32 public constant ALLOWED_TOKEN_ROLE = keccak256('ALLOWED_TOKEN_ROLE');

    struct Storage {
        mapping(bytes32 => mapping(address => bool)) roles;
    }

    function get() internal pure returns (Storage storage s) {
        bytes32 position = ROLES_MANAGEMENT_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function enforceRole(address who, bytes32 role) internal view {
        if (role == INTERNAL_ROLE) {
            if (who != address(this)) {
                revert HasNoRole(who, INTERNAL_ROLE);
            }
        } else if (!get().roles[role][who]) {
            revert HasNoRole(who, role);
        }
        
    }

    function hasRole(address who, bytes32 role) internal view returns(bool) {
        return get().roles[role][who];
    }

    function enforceSenderRole(bytes32 role) internal view {
        enforceRole(msg.sender, role);
    }

    function grantRole(address who, bytes32 role) internal {
        get().roles[role][who] = true; 
        emit RoleSet(who, role, true);
    }

    function revokeRole(address who, bytes32 role) internal {
        get().roles[role][who] = false; 
        emit RoleSet(who, role, false);
    }

    function enforceEitherOfRoles(address who, bytes32[] memory roles) internal view {
        bool result;
        for (uint256 i = 0; i < roles.length; i++) {
            if (roles[i] == INTERNAL_ROLE) {
                result = result || who == address(this);
            } else {
                result = result || get().roles[roles[i]][who];
            }
        }
        if (!result) {
            revert HasNoRoles(who, roles);
        }
    }

    function enforceSenderEitherOfRoles(bytes32[] memory roles) internal view {
        enforceEitherOfRoles(msg.sender, roles);
    }
}