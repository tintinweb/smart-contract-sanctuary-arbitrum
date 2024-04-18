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
pragma solidity 0.8.23;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../interfaces/IGNSAddressStore.sol";

/**
 * @custom:version 8
 * @dev Proxy base for the diamond and its facet contracts to store addresses and manage access control
 */
abstract contract GNSAddressStore is Initializable, IGNSAddressStore {
    AddressStore private addressStore;

    /// @inheritdoc IGNSAddressStore
    function initialize(address _rolesManager) external initializer {
        if (_rolesManager == address(0)) {
            revert IGeneralErrors.InitError();
        }

        _setRole(_rolesManager, Role.ROLES_MANAGER, true);
    }

    // Addresses

    /// @inheritdoc IGNSAddressStore
    function getAddresses() external view returns (Addresses memory) {
        return addressStore.globalAddresses;
    }

    // Roles

    /// @inheritdoc IGNSAddressStore
    function hasRole(address _account, Role _role) public view returns (bool) {
        return addressStore.accessControl[_account][_role];
    }

    /**
     * @dev Update role for account
     * @param _account account to update
     * @param _role role to set
     * @param _value true if allowed, false if not
     */
    function _setRole(address _account, Role _role, bool _value) internal {
        addressStore.accessControl[_account][_role] = _value;
        emit AccessControlUpdated(_account, _role, _value);
    }

    /// @inheritdoc IGNSAddressStore
    function setRoles(
        address[] calldata _accounts,
        Role[] calldata _roles,
        bool[] calldata _values
    ) external onlyRole(Role.ROLES_MANAGER) {
        if (_accounts.length != _roles.length || _accounts.length != _values.length) {
            revert IGeneralErrors.InvalidInputLength();
        }

        for (uint256 i = 0; i < _accounts.length; ++i) {
            if (_roles[i] == Role.ROLES_MANAGER && _accounts[i] == msg.sender) {
                revert NotAllowed();
            }

            _setRole(_accounts[i], _roles[i], _values[i]);
        }
    }

    /**
     * @dev Reverts if caller does not have role
     * @param _role role to enforce
     */
    function _enforceRole(Role _role) internal view {
        if (!hasRole(msg.sender, _role)) {
            revert WrongAccess();
        }
    }

    /**
     * @dev Reverts if caller does not have role
     */
    modifier onlyRole(Role _role) {
        _enforceRole(_role);
        _;
    }

    /**
     * @dev Reverts if caller isn't this same contract (facets calling other facets)
     */
    modifier onlySelf() {
        if (msg.sender != address(this)) {
            revert WrongAccess();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../abstract/GNSAddressStore.sol";

import "../../interfaces/libraries/IFeeTiersUtils.sol";

import "../../libraries/FeeTiersUtils.sol";
import "../../libraries/PairsStorageUtils.sol";

/**
 * @custom:version 8
 * @dev Facet #3: Fee tiers
 */
contract GNSFeeTiers is GNSAddressStore, IFeeTiersUtils {
    // Initialization

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @inheritdoc IFeeTiersUtils
    function initializeFeeTiers(
        uint256[] calldata _groupIndices,
        uint256[] calldata _groupVolumeMultipliers,
        uint256[] calldata _feeTiersIndices,
        IFeeTiersUtils.FeeTier[] calldata _feeTiers
    ) external reinitializer(4) {
        FeeTiersUtils.initializeFeeTiers(_groupIndices, _groupVolumeMultipliers, _feeTiersIndices, _feeTiers);
    }

    // Management Setters

    /// @inheritdoc IFeeTiersUtils
    function setGroupVolumeMultipliers(
        uint256[] calldata _groupIndices,
        uint256[] calldata _groupVolumeMultipliers
    ) external onlyRole(Role.GOV) {
        FeeTiersUtils.setGroupVolumeMultipliers(_groupIndices, _groupVolumeMultipliers);
    }

    /// @inheritdoc IFeeTiersUtils
    function setFeeTiers(
        uint256[] calldata _feeTiersIndices,
        IFeeTiersUtils.FeeTier[] calldata _feeTiers
    ) external onlyRole(Role.GOV) {
        FeeTiersUtils.setFeeTiers(_feeTiersIndices, _feeTiers);
    }

    // Interactions

    /// @inheritdoc IFeeTiersUtils
    function updateTraderPoints(address _trader, uint256 _volumeUsd, uint256 _pairIndex) external virtual onlySelf {
        FeeTiersUtils.updateTraderPoints(_trader, _volumeUsd, PairsStorageUtils.pairFeeIndex(_pairIndex));
    }

    // Getters

    /// @inheritdoc IFeeTiersUtils
    function calculateFeeAmount(address _trader, uint256 _normalFeeAmountCollateral) external view returns (uint256) {
        return FeeTiersUtils.calculateFeeAmount(_trader, _normalFeeAmountCollateral);
    }

    /// @inheritdoc IFeeTiersUtils
    function getFeeTiersCount() external view returns (uint256) {
        return FeeTiersUtils.getFeeTiersCount();
    }

    /// @inheritdoc IFeeTiersUtils
    function getFeeTier(uint256 _feeTierIndex) external view returns (IFeeTiersUtils.FeeTier memory) {
        return FeeTiersUtils.getFeeTier(_feeTierIndex);
    }

    /// @inheritdoc IFeeTiersUtils
    function getGroupVolumeMultiplier(uint256 _groupIndex) external view returns (uint256) {
        return FeeTiersUtils.getGroupVolumeMultiplier(_groupIndex);
    }

    /// @inheritdoc IFeeTiersUtils
    function getFeeTiersTraderInfo(address _trader) external view returns (IFeeTiersUtils.TraderInfo memory) {
        return FeeTiersUtils.getFeeTiersTraderInfo(_trader);
    }

    /// @inheritdoc IFeeTiersUtils
    function getFeeTiersTraderDailyInfo(
        address _trader,
        uint32 _day
    ) external view returns (IFeeTiersUtils.TraderDailyInfo memory) {
        return FeeTiersUtils.getFeeTiersTraderDailyInfo(_trader, _day);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @custom:version 8
 * @dev Interface for errors potentially used in all libraries (general names)
 */
interface IGeneralErrors {
    error InitError();
    error InvalidAddresses();
    error InvalidInputLength();
    error InvalidCollateralIndex();
    error WrongParams();
    error WrongLength();
    error WrongOrder();
    error WrongIndex();
    error BlockOrder();
    error Overflow();
    error ZeroAddress();
    error ZeroValue();
    error AlreadyExists();
    error DoesntExist();
    error Paused();
    error BelowMin();
    error AboveMax();
    error NotAuthorized();
    error WrongTradeType();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./types/IAddressStore.sol";
import "./IGeneralErrors.sol";

/**
 * @custom:version 8
 * @dev Interface for AddressStoreUtils library
 */
interface IGNSAddressStore is IAddressStore, IGeneralErrors {
    /**
     * @dev Initializes address store facet
     * @param _rolesManager roles manager address
     */
    function initialize(address _rolesManager) external;

    /**
     * @dev Returns addresses current values
     */
    function getAddresses() external view returns (Addresses memory);

    /**
     * @dev Returns whether an account has been granted a particular role
     * @param _account account address to check
     * @param _role role to check
     */
    function hasRole(address _account, Role _role) external view returns (bool);

    /**
     * @dev Updates access control for a list of accounts
     * @param _accounts accounts addresses to update
     * @param _roles corresponding roles to update
     * @param _values corresponding new values to set
     */
    function setRoles(address[] calldata _accounts, Role[] calldata _roles, bool[] calldata _values) external;

    /**
     * @dev Emitted when addresses are updated
     * @param addresses new addresses values
     */
    event AddressesUpdated(Addresses addresses);

    /**
     * @dev Emitted when access control is updated for an account
     * @param target account address to update
     * @param role role to update
     * @param access whether role is granted or revoked
     */
    event AccessControlUpdated(address target, Role role, bool access);

    error NotAllowed();
    error WrongAccess();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../types/IFeeTiers.sol";

/**
 * @custom:version 8
 * @dev Interface for GNSFeeTiers facet (inherits types and also contains functions, events, and custom errors)
 */
interface IFeeTiersUtils is IFeeTiers {
    /**
     *
     * @param _groupIndices group indices (pairs storage fee index) to initialize
     * @param _groupVolumeMultipliers corresponding group volume multipliers (1e3)
     * @param _feeTiersIndices fee tiers indices to initialize
     * @param _feeTiers fee tiers values to initialize (feeMultiplier, pointsThreshold)
     */
    function initializeFeeTiers(
        uint256[] calldata _groupIndices,
        uint256[] calldata _groupVolumeMultipliers,
        uint256[] calldata _feeTiersIndices,
        IFeeTiersUtils.FeeTier[] calldata _feeTiers
    ) external;

    /**
     * @dev Updates groups volume multipliers
     * @param _groupIndices indices of groups to update
     * @param _groupVolumeMultipliers corresponding new volume multipliers (1e3)
     */
    function setGroupVolumeMultipliers(
        uint256[] calldata _groupIndices,
        uint256[] calldata _groupVolumeMultipliers
    ) external;

    /**
     * @dev Updates fee tiers
     * @param _feeTiersIndices indices of fee tiers to update
     * @param _feeTiers new fee tiers values (feeMultiplier, pointsThreshold)
     */
    function setFeeTiers(uint256[] calldata _feeTiersIndices, IFeeTiersUtils.FeeTier[] calldata _feeTiers) external;

    /**
     * @dev Increases daily points from a new trade, re-calculate trailing points, and cache daily fee tier for a trader.
     * @param _trader trader address
     * @param _volumeUsd trading volume in USD (1e18)
     * @param _pairIndex pair index
     */
    function updateTraderPoints(address _trader, uint256 _volumeUsd, uint256 _pairIndex) external;

    /**
     * @dev Returns fee amount after applying the trader's active fee tier multiplier
     * @param _trader address of trader
     * @param _normalFeeAmountCollateral base fee amount (collateral precision)
     */
    function calculateFeeAmount(address _trader, uint256 _normalFeeAmountCollateral) external view returns (uint256);

    /**
     * Returns the current number of active fee tiers
     */
    function getFeeTiersCount() external view returns (uint256);

    /**
     * @dev Returns a fee tier's details (feeMultiplier, pointsThreshold)
     * @param _feeTierIndex fee tier index
     */
    function getFeeTier(uint256 _feeTierIndex) external view returns (IFeeTiersUtils.FeeTier memory);

    /**
     * @dev Returns a group's volume multiplier
     * @param _groupIndex group index (pairs storage fee index)
     */
    function getGroupVolumeMultiplier(uint256 _groupIndex) external view returns (uint256);

    /**
     * @dev Returns a trader's info (lastDayUpdated, trailingPoints)
     * @param _trader trader address
     */
    function getFeeTiersTraderInfo(address _trader) external view returns (IFeeTiersUtils.TraderInfo memory);

    /**
     * @dev Returns a trader's daily fee tier info (feeMultiplierCache, points)
     * @param _trader trader address
     * @param _day day
     */
    function getFeeTiersTraderDailyInfo(
        address _trader,
        uint32 _day
    ) external view returns (IFeeTiersUtils.TraderDailyInfo memory);

    /**
     * @dev Emitted when group volume multipliers are updated
     * @param groupIndices indices of updated groups
     * @param groupVolumeMultipliers new corresponding volume multipliers (1e3)
     */
    event GroupVolumeMultipliersUpdated(uint256[] groupIndices, uint256[] groupVolumeMultipliers);

    /**
     * @dev Emitted when fee tiers are updated
     * @param feeTiersIndices indices of updated fee tiers
     * @param feeTiers new corresponding fee tiers values (feeMultiplier, pointsThreshold)
     */
    event FeeTiersUpdated(uint256[] feeTiersIndices, IFeeTiersUtils.FeeTier[] feeTiers);

    /**
     * @dev Emitted when a trader's daily points are updated
     * @param trader trader address
     * @param day day
     * @param points points added (1e18 precision)
     */
    event TraderDailyPointsIncreased(address indexed trader, uint32 indexed day, uint224 points);

    /**
     * @dev Emitted when a trader info is updated for the first time
     * @param trader address of trader
     * @param day day
     */
    event TraderInfoFirstUpdate(address indexed trader, uint32 day);

    /**
     * @dev Emitted when a trader's trailing points are updated
     * @param trader trader address
     * @param fromDay from day
     * @param toDay to day
     * @param expiredPoints expired points amount (1e18 precision)
     */
    event TraderTrailingPointsExpired(address indexed trader, uint32 fromDay, uint32 toDay, uint224 expiredPoints);

    /**
     * @dev Emitted when a trader's info is updated
     * @param trader address of trader
     * @param traderInfo new trader info value (lastDayUpdated, trailingPoints)
     */
    event TraderInfoUpdated(address indexed trader, IFeeTiersUtils.TraderInfo traderInfo);

    /**
     * @dev Emitted when a trader's cached fee multiplier is updated (this is the one used in fee calculations)
     * @param trader address of trader
     * @param day day
     * @param feeMultiplier new fee multiplier (1e3 precision)
     */
    event TraderFeeMultiplierCached(address indexed trader, uint32 indexed day, uint32 feeMultiplier);

    error WrongFeeTier();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../types/IPairsStorage.sol";

/**
 * @custom:version 8
 * @dev Interface for GNSPairsStorage facet (inherits types and also contains functions, events, and custom errors)
 */
interface IPairsStorageUtils is IPairsStorage {
    /**
     * @dev Adds new trading pairs
     * @param _pairs pairs to add
     */
    function addPairs(Pair[] calldata _pairs) external;

    /**
     * @dev Updates trading pairs
     * @param _pairIndices indices of pairs
     * @param _pairs new pairs values
     */
    function updatePairs(uint256[] calldata _pairIndices, Pair[] calldata _pairs) external;

    /**
     * @dev Adds new pair groups
     * @param _groups groups to add
     */
    function addGroups(Group[] calldata _groups) external;

    /**
     * @dev Updates pair groups
     * @param _ids indices of groups
     * @param _groups new groups values
     */
    function updateGroups(uint256[] calldata _ids, Group[] calldata _groups) external;

    /**
     * @dev Adds new pair fees groups
     * @param _fees fees to add
     */
    function addFees(Fee[] calldata _fees) external;

    /**
     * @dev Updates pair fees groups
     * @param _ids indices of fees
     * @param _fees new fees values
     */
    function updateFees(uint256[] calldata _ids, Fee[] calldata _fees) external;

    /**
     * @dev Updates pair custom max leverages (if unset group default is used)
     * @param _indices indices of pairs
     * @param _values new custom max leverages
     */
    function setPairCustomMaxLeverages(uint256[] calldata _indices, uint256[] calldata _values) external;

    /**
     * @dev Returns data needed by price aggregator when doing a new price request
     * @param _pairIndex index of pair
     * @return from pair from (eg. BTC)
     * @return to pair to (eg. USD)
     */
    function pairJob(uint256 _pairIndex) external view returns (string memory from, string memory to);

    /**
     * @dev Returns whether a pair is listed
     * @param _from pair from (eg. BTC)
     * @param _to pair to (eg. USD)
     */
    function isPairListed(string calldata _from, string calldata _to) external view returns (bool);

    /**
     * @dev Returns whether a pair index is listed
     * @param _pairIndex index of pair to check
     */
    function isPairIndexListed(uint256 _pairIndex) external view returns (bool);

    /**
     * @dev Returns a pair's details
     * @param _index index of pair
     */
    function pairs(uint256 _index) external view returns (Pair memory);

    /**
     * @dev Returns number of listed pairs
     */
    function pairsCount() external view returns (uint256);

    /**
     * @dev Returns a pair's spread % (1e10 precision)
     * @param _pairIndex index of pair
     */
    function pairSpreadP(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns a pair's min leverage
     * @param _pairIndex index of pair
     */
    function pairMinLeverage(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns a pair's open fee % (1e10 precision)
     * @param _pairIndex index of pair
     */
    function pairOpenFeeP(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns a pair's close fee % (1e10 precision)
     * @param _pairIndex index of pair
     */
    function pairCloseFeeP(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns a pair's oracle fee % (1e10 precision)
     * @param _pairIndex index of pair
     */
    function pairOracleFeeP(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns a pair's trigger order fee % (1e10 precision)
     * @param _pairIndex index of pair
     */
    function pairTriggerOrderFeeP(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns a pair's min leverage position in USD (1e18 precision)
     * @param _pairIndex index of pair
     */
    function pairMinPositionSizeUsd(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns a group details
     * @param _index index of group
     */
    function groups(uint256 _index) external view returns (Group memory);

    /**
     * @dev Returns number of listed groups
     */
    function groupsCount() external view returns (uint256);

    /**
     * @dev Returns a fee group details
     * @param _index index of fee group
     */
    function fees(uint256 _index) external view returns (Fee memory);

    /**
     * @dev Returns number of listed fee groups
     */
    function feesCount() external view returns (uint256);

    /**
     * @dev Returns a pair's details, group and fee group
     * @param _index index of pair
     */
    function pairsBackend(uint256 _index) external view returns (Pair memory, Group memory, Fee memory);

    /**
     * @dev Returns a pair's active max leverage (custom if set, otherwise group default)
     * @param _pairIndex index of pair
     */
    function pairMaxLeverage(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns a pair's custom max leverage (0 if not set)
     * @param _pairIndex index of pair
     */
    function pairCustomMaxLeverage(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns all listed pairs custom max leverages
     */
    function getAllPairsRestrictedMaxLeverage() external view returns (uint256[] memory);

    /**
     * @dev Emitted when a new pair is listed
     * @param index index of pair
     * @param from pair from (eg. BTC)
     * @param to pair to (eg. USD)
     */
    event PairAdded(uint256 index, string from, string to);

    /**
     * @dev Emitted when a pair is updated
     * @param index index of pair
     */
    event PairUpdated(uint256 index);

    /**
     * @dev Emitted when a pair's custom max leverage is updated
     * @param index index of pair
     * @param maxLeverage new max leverage
     */
    event PairCustomMaxLeverageUpdated(uint256 indexed index, uint256 maxLeverage);

    /**
     * @dev Emitted when a new group is added
     * @param index index of group
     * @param name name of group
     */
    event GroupAdded(uint256 index, string name);

    /**
     * @dev Emitted when a group is updated
     * @param index index of group
     */
    event GroupUpdated(uint256 index);

    /**
     * @dev Emitted when a new fee group is added
     * @param index index of fee group
     * @param name name of fee group
     */
    event FeeAdded(uint256 index, string name);

    /**
     * @dev Emitted when a fee group is updated
     * @param index index of fee group
     */
    event FeeUpdated(uint256 index);

    error PairNotListed();
    error GroupNotListed();
    error FeeNotListed();
    error WrongLeverages();
    error WrongFees();
    error PairAlreadyListed();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @custom:version 8
 * @dev Contains the types for the GNSAddressStore facet
 */
interface IAddressStore {
    enum Role {
        ROLES_MANAGER, // timelock
        GOV,
        MANAGER
    }

    struct Addresses {
        address gns;
        address gnsStaking;
    }

    struct AddressStore {
        uint256 __deprecated; // previously globalAddresses (gns token only, 1 slot)
        mapping(address => mapping(Role => bool)) accessControl;
        Addresses globalAddresses;
        uint256[8] __gap1; // gap for global addresses
        // insert new storage here
        uint256[38] __gap2; // gap for rest of diamond storage
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @custom:version 8
 * @dev Contains the types for the GNSFeeTiers facet
 */
interface IFeeTiers {
    struct FeeTiersStorage {
        FeeTier[8] feeTiers;
        mapping(uint256 => uint256) groupVolumeMultipliers; // groupIndex (pairs storage) => multiplier (1e3)
        mapping(address => TraderInfo) traderInfos; // trader => TraderInfo
        mapping(address => mapping(uint32 => TraderDailyInfo)) traderDailyInfos; // trader => day => TraderDailyInfo
        uint256[39] __gap;
    }

    struct FeeTier {
        uint32 feeMultiplier; // 1e3
        uint32 pointsThreshold;
    }

    struct TraderInfo {
        uint32 lastDayUpdated;
        uint224 trailingPoints; // 1e18
    }

    struct TraderDailyInfo {
        uint32 feeMultiplierCache; // 1e3
        uint224 points; // 1e18
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @custom:version 8
 * @dev Contains the types for the GNSPairsStorage facet
 */
interface IPairsStorage {
    struct PairsStorage {
        mapping(uint256 => Pair) pairs;
        mapping(uint256 => Group) groups;
        mapping(uint256 => Fee) fees;
        mapping(string => mapping(string => bool)) isPairListed;
        mapping(uint256 => uint256) pairCustomMaxLeverage; // 0 decimal precision
        uint256 currentOrderId; /// @custom:deprecated
        uint256 pairsCount;
        uint256 groupsCount;
        uint256 feesCount;
        uint256[41] __gap;
    }

    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    } /// @custom:deprecated
    struct Feed {
        address feed1;
        address feed2;
        FeedCalculation feedCalculation;
        uint256 maxDeviationP;
    } /// @custom:deprecated

    struct Pair {
        string from;
        string to;
        Feed feed; /// @custom:deprecated
        uint256 spreadP; // PRECISION
        uint256 groupIndex;
        uint256 feeIndex;
    }

    struct Group {
        string name;
        bytes32 job;
        uint256 minLeverage; // 0 decimal precision
        uint256 maxLeverage; // 0 decimal precision
    }
    struct Fee {
        string name;
        uint256 openFeeP; // PRECISION (% of position size)
        uint256 closeFeeP; // PRECISION (% of position size)
        uint256 oracleFeeP; // PRECISION (% of position size)
        uint256 triggerOrderFeeP; // PRECISION (% of position size)
        uint256 minPositionSizeUsd; // 1e18 (collateral x leverage, useful for min fee)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../interfaces/libraries/IFeeTiersUtils.sol";
import "../interfaces/IGeneralErrors.sol";

import "../interfaces/types/IFeeTiers.sol";

import "./StorageUtils.sol";

/**
 * @custom:version 8
 * @dev GNSFeeTiers facet internal library
 *
 * This is a library to apply fee tiers to trading fees based on a trailing point system.
 */
library FeeTiersUtils {
    uint256 private constant MAX_FEE_TIERS = 8;
    uint32 private constant TRAILING_PERIOD_DAYS = 30;
    uint32 private constant FEE_MULTIPLIER_SCALE = 1e3;
    uint224 private constant POINTS_THRESHOLD_SCALE = 1e18;
    uint256 private constant GROUP_VOLUME_MULTIPLIER_SCALE = 1e3;

    /**
     * @dev Check IFeeTiersUtils interface for documentation
     */
    function initializeFeeTiers(
        uint256[] calldata _groupIndices,
        uint256[] calldata _groupVolumeMultipliers,
        uint256[] calldata _feeTiersIndices,
        IFeeTiers.FeeTier[] calldata _feeTiers
    ) internal {
        setGroupVolumeMultipliers(_groupIndices, _groupVolumeMultipliers);
        setFeeTiers(_feeTiersIndices, _feeTiers);
    }

    /**
     * @dev Check IFeeTiersUtils interface for documentation
     */
    function setGroupVolumeMultipliers(
        uint256[] calldata _groupIndices,
        uint256[] calldata _groupVolumeMultipliers
    ) internal {
        if (_groupIndices.length != _groupVolumeMultipliers.length) {
            revert IGeneralErrors.WrongLength();
        }

        mapping(uint256 => uint256) storage groupVolumeMultipliers = _getStorage().groupVolumeMultipliers;

        for (uint256 i; i < _groupIndices.length; ++i) {
            groupVolumeMultipliers[_groupIndices[i]] = _groupVolumeMultipliers[i];
        }

        emit IFeeTiersUtils.GroupVolumeMultipliersUpdated(_groupIndices, _groupVolumeMultipliers);
    }

    /**
     * @dev Check IFeeTiersUtils interface for documentation
     */
    function setFeeTiers(uint256[] calldata _feeTiersIndices, IFeeTiers.FeeTier[] calldata _feeTiers) internal {
        if (_feeTiersIndices.length != _feeTiers.length) {
            revert IGeneralErrors.WrongLength();
        }

        IFeeTiers.FeeTier[8] storage feeTiersStorage = _getStorage().feeTiers;

        // First do all updates
        for (uint256 i; i < _feeTiersIndices.length; ++i) {
            feeTiersStorage[_feeTiersIndices[i]] = _feeTiers[i];
        }

        // Then check updates are valid
        for (uint256 i; i < _feeTiersIndices.length; ++i) {
            _checkFeeTierUpdateValid(_feeTiersIndices[i], _feeTiers[i], feeTiersStorage);
        }

        emit IFeeTiersUtils.FeeTiersUpdated(_feeTiersIndices, _feeTiers);
    }

    /**
     * @dev Check IFeeTiersUtils interface for documentation
     */
    function updateTraderPoints(address _trader, uint256 _volumeUsd, uint256 _groupIndex) internal {
        IFeeTiers.FeeTiersStorage storage s = _getStorage();

        // Scale amount by group multiplier
        uint224 points = uint224((_volumeUsd * s.groupVolumeMultipliers[_groupIndex]) / GROUP_VOLUME_MULTIPLIER_SCALE);

        mapping(uint32 => IFeeTiers.TraderDailyInfo) storage traderDailyInfo = s.traderDailyInfos[_trader];
        uint32 currentDay = _getCurrentDay();
        IFeeTiers.TraderDailyInfo storage traderCurrentDayInfo = traderDailyInfo[currentDay];

        // Increase points for current day
        if (points > 0) {
            traderCurrentDayInfo.points += points;
            emit IFeeTiersUtils.TraderDailyPointsIncreased(_trader, currentDay, points);
        }

        IFeeTiers.TraderInfo storage traderInfo = s.traderInfos[_trader];

        // Return early if first update ever for trader since trailing points would be 0 anyway
        if (traderInfo.lastDayUpdated == 0) {
            traderInfo.lastDayUpdated = currentDay;
            emit IFeeTiersUtils.TraderInfoFirstUpdate(_trader, currentDay);

            return;
        }

        // Update trailing points & re-calculate cached fee tier.
        // Only run if at least 1 day elapsed since last update
        if (currentDay > traderInfo.lastDayUpdated) {
            // Trailing points = sum of all daily points accumulated for last TRAILING_PERIOD_DAYS.
            // It determines which fee tier to apply (pointsThreshold)
            uint224 curTrailingPoints;

            // Calculate trailing points if less than or exactly TRAILING_PERIOD_DAYS have elapsed since update.
            // Otherwise, trailing points is 0 anyway.
            uint32 earliestActiveDay = currentDay - TRAILING_PERIOD_DAYS;

            if (traderInfo.lastDayUpdated >= earliestActiveDay) {
                // Load current trailing points and add last day updated points since they are now finalized
                curTrailingPoints = traderInfo.trailingPoints + traderDailyInfo[traderInfo.lastDayUpdated].points;

                // Expire outdated trailing points
                uint32 earliestOutdatedDay = traderInfo.lastDayUpdated - TRAILING_PERIOD_DAYS;
                uint32 lastOutdatedDay = earliestActiveDay - 1;

                uint224 expiredTrailingPoints;
                for (uint32 i = earliestOutdatedDay; i <= lastOutdatedDay; ++i) {
                    expiredTrailingPoints += traderDailyInfo[i].points;
                }

                curTrailingPoints -= expiredTrailingPoints;

                emit IFeeTiersUtils.TraderTrailingPointsExpired(
                    _trader,
                    earliestOutdatedDay,
                    lastOutdatedDay,
                    expiredTrailingPoints
                );
            }

            // Store last updated day and new trailing points
            traderInfo.lastDayUpdated = currentDay;
            traderInfo.trailingPoints = curTrailingPoints;

            emit IFeeTiersUtils.TraderInfoUpdated(_trader, traderInfo);

            // Re-calculate current fee tier for trader
            uint32 newFeeMultiplier = FEE_MULTIPLIER_SCALE; // use 1 by default (if no fee tier corresponds)

            for (uint256 i = getFeeTiersCount(); i > 0; --i) {
                IFeeTiers.FeeTier memory feeTier = s.feeTiers[i - 1];

                if (curTrailingPoints >= uint224(feeTier.pointsThreshold) * POINTS_THRESHOLD_SCALE) {
                    newFeeMultiplier = feeTier.feeMultiplier;
                    break;
                }
            }

            // Update trader cached fee multiplier
            traderCurrentDayInfo.feeMultiplierCache = newFeeMultiplier;
            emit IFeeTiersUtils.TraderFeeMultiplierCached(_trader, currentDay, newFeeMultiplier);
        }
    }

    /**
     * @dev Check IFeeTiersUtils interface for documentation
     */
    function calculateFeeAmount(address _trader, uint256 _normalFeeAmountCollateral) internal view returns (uint256) {
        uint32 feeMultiplier = _getStorage().traderDailyInfos[_trader][_getCurrentDay()].feeMultiplierCache;
        return
            feeMultiplier == 0
                ? _normalFeeAmountCollateral
                : (uint256(feeMultiplier) * _normalFeeAmountCollateral) / uint256(FEE_MULTIPLIER_SCALE);
    }

    /**
     * @dev Check IFeeTiersUtils interface for documentation
     */
    function getFeeTiersCount() internal view returns (uint256) {
        IFeeTiers.FeeTier[8] storage _feeTiers = _getStorage().feeTiers;

        for (uint256 i = MAX_FEE_TIERS; i > 0; --i) {
            if (_feeTiers[i - 1].feeMultiplier > 0) {
                return i;
            }
        }

        return 0;
    }

    /**
     * @dev Check IFeeTiersUtils interface for documentation
     */
    function getFeeTier(uint256 _feeTierIndex) internal view returns (IFeeTiers.FeeTier memory) {
        return _getStorage().feeTiers[_feeTierIndex];
    }

    /**
     * @dev Check IFeeTiersUtils interface for documentation
     */
    function getGroupVolumeMultiplier(uint256 _groupIndex) internal view returns (uint256) {
        return _getStorage().groupVolumeMultipliers[_groupIndex];
    }

    /**
     * @dev Check IFeeTiersUtils interface for documentation
     */
    function getFeeTiersTraderInfo(address _trader) internal view returns (IFeeTiers.TraderInfo memory) {
        return _getStorage().traderInfos[_trader];
    }

    /**
     * @dev Check IFeeTiersUtils interface for documentation
     */
    function getFeeTiersTraderDailyInfo(
        address _trader,
        uint32 _day
    ) internal view returns (IFeeTiers.TraderDailyInfo memory) {
        return _getStorage().traderDailyInfos[_trader][_day];
    }

    /**
     * @dev Returns storage slot to use when fetching storage relevant to library
     */
    function _getSlot() internal pure returns (uint256) {
        return StorageUtils.GLOBAL_FEE_TIERS_SLOT;
    }

    /**
     * @dev Returns storage pointer for storage struct in diamond contract, at defined slot
     */
    function _getStorage() internal pure returns (IFeeTiers.FeeTiersStorage storage s) {
        uint256 storageSlot = _getSlot();
        assembly {
            s.slot := storageSlot
        }
    }

    /**
     * @dev Checks validity of a single fee tier update (feeMultiplier: descending, pointsThreshold: ascending, no gap)
     * @param _index index of the fee tier that was updated
     * @param _feeTier fee tier new value
     * @param _feeTiers all fee tiers
     */
    function _checkFeeTierUpdateValid(
        uint256 _index,
        IFeeTiers.FeeTier calldata _feeTier,
        IFeeTiers.FeeTier[8] storage _feeTiers
    ) internal view {
        bool isDisabled = _feeTier.feeMultiplier == 0 && _feeTier.pointsThreshold == 0;

        // Either both feeMultiplier and pointsThreshold are 0 or none
        // And make sure feeMultiplier < 1 otherwise useless
        if (
            !isDisabled &&
            (_feeTier.feeMultiplier >= FEE_MULTIPLIER_SCALE ||
                _feeTier.feeMultiplier == 0 ||
                _feeTier.pointsThreshold == 0)
        ) {
            revert IFeeTiersUtils.WrongFeeTier();
        }

        bool hasNextValue = _index < MAX_FEE_TIERS - 1;

        // If disabled, only need to check the next fee tier is disabled as well to create no gaps in active tiers
        if (isDisabled) {
            if (hasNextValue && _feeTiers[_index + 1].feeMultiplier > 0) {
                revert IGeneralErrors.WrongOrder();
            }
        } else {
            // Check next value order
            if (hasNextValue) {
                IFeeTiers.FeeTier memory feeTier = _feeTiers[_index + 1];
                if (
                    feeTier.feeMultiplier != 0 &&
                    (feeTier.feeMultiplier >= _feeTier.feeMultiplier ||
                        feeTier.pointsThreshold <= _feeTier.pointsThreshold)
                ) {
                    revert IGeneralErrors.WrongOrder();
                }
            }

            // Check previous value order
            if (_index > 0) {
                IFeeTiers.FeeTier memory feeTier = _feeTiers[_index - 1];
                if (
                    feeTier.feeMultiplier <= _feeTier.feeMultiplier ||
                    feeTier.pointsThreshold >= _feeTier.pointsThreshold
                ) {
                    revert IGeneralErrors.WrongOrder();
                }
            }
        }
    }

    /**
     * @dev Get current day (index of mapping traderDailyInfo)
     */
    function _getCurrentDay() internal view returns (uint32) {
        return uint32(block.timestamp / 1 days);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../interfaces/libraries/IPairsStorageUtils.sol";
import "../interfaces/types/IPairsStorage.sol";
import "../interfaces/IGeneralErrors.sol";

import "./StorageUtils.sol";

/**
 * @custom:version 8
 * @dev GNSPairsStorage facet internal library
 */
library PairsStorageUtils {
    uint256 private constant MIN_LEVERAGE = 2;
    uint256 private constant MAX_LEVERAGE = 1000;

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function addPairs(IPairsStorage.Pair[] calldata _pairs) internal {
        for (uint256 i = 0; i < _pairs.length; ++i) {
            _addPair(_pairs[i]);
        }
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function updatePairs(uint256[] calldata _pairIndices, IPairsStorage.Pair[] calldata _pairs) internal {
        if (_pairIndices.length != _pairs.length) revert IGeneralErrors.WrongLength();

        for (uint256 i = 0; i < _pairs.length; ++i) {
            _updatePair(_pairIndices[i], _pairs[i]);
        }
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function addGroups(IPairsStorage.Group[] calldata _groups) internal {
        for (uint256 i = 0; i < _groups.length; ++i) {
            _addGroup(_groups[i]);
        }
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function updateGroups(uint256[] calldata _ids, IPairsStorage.Group[] calldata _groups) internal {
        if (_ids.length != _groups.length) revert IGeneralErrors.WrongLength();

        for (uint256 i = 0; i < _groups.length; ++i) {
            _updateGroup(_ids[i], _groups[i]);
        }
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function addFees(IPairsStorage.Fee[] calldata _fees) internal {
        for (uint256 i = 0; i < _fees.length; ++i) {
            _addFee(_fees[i]);
        }
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function updateFees(uint256[] calldata _ids, IPairsStorage.Fee[] calldata _fees) internal {
        if (_ids.length != _fees.length) revert IGeneralErrors.WrongLength();

        for (uint256 i = 0; i < _fees.length; ++i) {
            _updateFee(_ids[i], _fees[i]);
        }
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function setPairCustomMaxLeverages(uint256[] calldata _indices, uint256[] calldata _values) internal {
        if (_indices.length != _values.length) revert IGeneralErrors.WrongLength();

        IPairsStorage.PairsStorage storage s = _getStorage();

        for (uint256 i; i < _indices.length; ++i) {
            s.pairCustomMaxLeverage[_indices[i]] = _values[i];

            emit IPairsStorageUtils.PairCustomMaxLeverageUpdated(_indices[i], _values[i]);
        }
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function pairJob(uint256 _pairIndex) internal view returns (string memory, string memory) {
        IPairsStorage.PairsStorage storage s = _getStorage();

        IPairsStorage.Pair memory p = s.pairs[_pairIndex];
        if (!s.isPairListed[p.from][p.to]) revert IPairsStorageUtils.PairNotListed();

        return (p.from, p.to);
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function isPairListed(string calldata _from, string calldata _to) internal view returns (bool) {
        return _getStorage().isPairListed[_from][_to];
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function isPairIndexListed(uint256 _pairIndex) internal view returns (bool) {
        return _pairIndex < _getStorage().pairsCount;
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function pairs(uint256 _index) internal view returns (IPairsStorage.Pair memory) {
        return _getStorage().pairs[_index];
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function pairsCount() internal view returns (uint256) {
        return _getStorage().pairsCount;
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function pairSpreadP(uint256 _pairIndex) internal view returns (uint256) {
        return pairs(_pairIndex).spreadP;
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function pairMinLeverage(uint256 _pairIndex) internal view returns (uint256) {
        return groups(pairs(_pairIndex).groupIndex).minLeverage;
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function pairOpenFeeP(uint256 _pairIndex) internal view returns (uint256) {
        return fees(pairs(_pairIndex).feeIndex).openFeeP;
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function pairCloseFeeP(uint256 _pairIndex) internal view returns (uint256) {
        return fees(pairs(_pairIndex).feeIndex).closeFeeP;
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function pairOracleFeeP(uint256 _pairIndex) internal view returns (uint256) {
        return fees(pairs(_pairIndex).feeIndex).oracleFeeP;
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function pairTriggerOrderFeeP(uint256 _pairIndex) internal view returns (uint256) {
        return fees(pairs(_pairIndex).feeIndex).triggerOrderFeeP;
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function pairMinPositionSizeUsd(uint256 _pairIndex) internal view returns (uint256) {
        return fees(pairs(_pairIndex).feeIndex).minPositionSizeUsd;
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function pairFeeIndex(uint256 _pairIndex) internal view returns (uint256) {
        return _getStorage().pairs[_pairIndex].feeIndex;
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function groups(uint256 _index) internal view returns (IPairsStorage.Group memory) {
        return _getStorage().groups[_index];
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function groupsCount() internal view returns (uint256) {
        return _getStorage().groupsCount;
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function fees(uint256 _index) internal view returns (IPairsStorage.Fee memory) {
        return _getStorage().fees[_index];
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function feesCount() internal view returns (uint256) {
        return _getStorage().feesCount;
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function pairsBackend(
        uint256 _index
    ) internal view returns (IPairsStorage.Pair memory, IPairsStorage.Group memory, IPairsStorage.Fee memory) {
        IPairsStorage.Pair memory p = pairs(_index);
        return (p, PairsStorageUtils.groups(p.groupIndex), PairsStorageUtils.fees(p.feeIndex));
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function pairMaxLeverage(uint256 _pairIndex) internal view returns (uint256) {
        IPairsStorage.PairsStorage storage s = _getStorage();

        uint256 maxLeverage = s.pairCustomMaxLeverage[_pairIndex];
        return maxLeverage > 0 ? maxLeverage : s.groups[s.pairs[_pairIndex].groupIndex].maxLeverage;
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function pairCustomMaxLeverage(uint256 _pairIndex) internal view returns (uint256) {
        return _getStorage().pairCustomMaxLeverage[_pairIndex];
    }

    /**
     * @dev Check IPairsStorageUtils interface for documentation
     */
    function getAllPairsRestrictedMaxLeverage() internal view returns (uint256[] memory) {
        uint256[] memory lev = new uint256[](pairsCount());

        for (uint256 i; i < lev.length; ++i) {
            lev[i] = pairCustomMaxLeverage(i);
        }

        return lev;
    }

    /**
     * @dev Returns storage slot to use when fetching storage relevant to library
     */
    function _getSlot() internal pure returns (uint256) {
        return StorageUtils.GLOBAL_PAIRS_STORAGE_SLOT;
    }

    /**
     * @dev Returns storage pointer for storage struct in diamond contract, at defined slot
     */
    function _getStorage() internal pure returns (IPairsStorage.PairsStorage storage s) {
        uint256 storageSlot = _getSlot();
        assembly {
            s.slot := storageSlot
        }
    }

    /**
     * Reverts if group is not listed
     * @param _groupIndex group index to check
     */
    modifier groupListed(uint256 _groupIndex) {
        if (_getStorage().groups[_groupIndex].minLeverage == 0) revert IPairsStorageUtils.GroupNotListed();
        _;
    }

    /**
     * Reverts if fee is not listed
     * @param _feeIndex fee index to check
     */
    modifier feeListed(uint256 _feeIndex) {
        if (_getStorage().fees[_feeIndex].openFeeP == 0) revert IPairsStorageUtils.FeeNotListed();
        _;
    }

    /**
     * Reverts if group is not valid
     * @param _group group to check
     */
    modifier groupOk(IPairsStorage.Group calldata _group) {
        if (
            _group.minLeverage < MIN_LEVERAGE ||
            _group.maxLeverage > MAX_LEVERAGE ||
            _group.minLeverage >= _group.maxLeverage
        ) revert IPairsStorageUtils.WrongLeverages();
        _;
    }

    /**
     * @dev Reverts if fee is not valid
     * @param _fee fee to check
     */
    modifier feeOk(IPairsStorage.Fee calldata _fee) {
        if (
            _fee.openFeeP == 0 ||
            _fee.closeFeeP == 0 ||
            _fee.oracleFeeP == 0 ||
            _fee.triggerOrderFeeP == 0 ||
            _fee.minPositionSizeUsd == 0
        ) revert IPairsStorageUtils.WrongFees();
        _;
    }

    /**
     * @dev Adds a new trading pair
     * @param _pair pair to add
     */
    function _addPair(
        IPairsStorage.Pair calldata _pair
    ) internal groupListed(_pair.groupIndex) feeListed(_pair.feeIndex) {
        IPairsStorage.PairsStorage storage s = _getStorage();
        if (s.isPairListed[_pair.from][_pair.to]) revert IPairsStorageUtils.PairAlreadyListed();

        s.pairs[s.pairsCount] = _pair;
        s.isPairListed[_pair.from][_pair.to] = true;

        emit IPairsStorageUtils.PairAdded(s.pairsCount++, _pair.from, _pair.to);
    }

    /**
     * @dev Updates an existing trading pair
     * @param _pairIndex index of pair to update
     * @param _pair new pair value
     */
    function _updatePair(
        uint256 _pairIndex,
        IPairsStorage.Pair calldata _pair
    ) internal groupListed(_pair.groupIndex) feeListed(_pair.feeIndex) {
        IPairsStorage.PairsStorage storage s = _getStorage();

        IPairsStorage.Pair storage p = s.pairs[_pairIndex];
        if (!s.isPairListed[p.from][p.to]) revert IPairsStorageUtils.PairNotListed();

        p.feed = _pair.feed;
        p.spreadP = _pair.spreadP;
        p.groupIndex = _pair.groupIndex;
        p.feeIndex = _pair.feeIndex;

        emit IPairsStorageUtils.PairUpdated(_pairIndex);
    }

    /**
     * @dev Adds a new pair group
     * @param _group group to add
     */
    function _addGroup(IPairsStorage.Group calldata _group) internal groupOk(_group) {
        IPairsStorage.PairsStorage storage s = _getStorage();
        s.groups[s.groupsCount] = _group;

        emit IPairsStorageUtils.GroupAdded(s.groupsCount++, _group.name);
    }

    /**
     * @dev Updates an existing pair group
     * @param _id index of group to update
     * @param _group new group value
     */
    function _updateGroup(uint256 _id, IPairsStorage.Group calldata _group) internal groupListed(_id) groupOk(_group) {
        _getStorage().groups[_id] = _group;

        emit IPairsStorageUtils.GroupUpdated(_id);
    }

    /**
     * @dev Adds a new pair fee group
     * @param _fee fee to add
     */
    function _addFee(IPairsStorage.Fee calldata _fee) internal feeOk(_fee) {
        IPairsStorage.PairsStorage storage s = _getStorage();
        s.fees[s.feesCount] = _fee;

        emit IPairsStorageUtils.FeeAdded(s.feesCount++, _fee.name);
    }

    /**
     * @dev Updates an existing pair fee group
     * @param _id index of fee to update
     * @param _fee new fee value
     */
    function _updateFee(uint256 _id, IPairsStorage.Fee calldata _fee) internal feeListed(_id) feeOk(_fee) {
        _getStorage().fees[_id] = _fee;

        emit IPairsStorageUtils.FeeUpdated(_id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @custom:version 8
 *
 * @dev Internal library to manage storage slots of GNSMultiCollatDiamond contract diamond storage structs.
 *
 * BE EXTREMELY CAREFUL, DO NOT EDIT THIS WITHOUT A GOOD REASON
 *
 */
library StorageUtils {
    uint256 internal constant GLOBAL_ADDRESSES_SLOT = 3;
    uint256 internal constant GLOBAL_PAIRS_STORAGE_SLOT = 51;
    uint256 internal constant GLOBAL_REFERRALS_SLOT = 101;
    uint256 internal constant GLOBAL_FEE_TIERS_SLOT = 151;
    uint256 internal constant GLOBAL_PRICE_IMPACT_SLOT = 201;
    uint256 internal constant GLOBAL_DIAMOND_SLOT = 251;
    uint256 internal constant GLOBAL_TRADING_STORAGE_SLOT = 301;
    uint256 internal constant GLOBAL_TRIGGER_REWARDS_SLOT = 351;
    uint256 internal constant GLOBAL_TRADING_SLOT = 401;
    uint256 internal constant GLOBAL_TRADING_CALLBACKS_SLOT = 451;
    uint256 internal constant GLOBAL_BORROWING_FEES_SLOT = 501;
    uint256 internal constant GLOBAL_PRICE_AGGREGATOR_SLOT = 551;
}