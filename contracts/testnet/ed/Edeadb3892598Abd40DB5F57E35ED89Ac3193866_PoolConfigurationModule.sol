pragma solidity >=0.8.19;
/**
 * @title Library for access related errors.
 */

library AccessError {
    /**
     * @dev Thrown when an address tries to perform an unauthorized action.
     * @param addr The address that attempts the action.
     */
    error Unauthorized(address addr);
}

pragma solidity >=0.8.19;
/**
 * @title Library for address related errors.
 */

library AddressError {
    /**
     * @dev Thrown when a zero address was passed as a function parameter (0x0000000000000000000000000000000000000000).
     */
    error ZeroAddress();

    /**
     * @dev Thrown when an address representing a contract is expected, but no code is found at the address.
     * @param contr The address that was expected to be a contract.
     */
    error NotAContract(address contr);
}

pragma solidity >=0.8.19;
/**
 * @title Library for change related errors.
 */

library ChangeError {
    /**
     * @dev Thrown when a change is expected but none is detected.
     */
    error NoChange();
}

pragma solidity >=0.8.19;

/**
 * Utilities that convert numeric types avoiding silent overflows.
 */

import "./safe-cast/SafeCastAddress.sol";
import "./safe-cast/SafeCastBytes32.sol";
import "./safe-cast/SafeCastU256.sol";
import "./safe-cast/SafeCastU128.sol";
import "./safe-cast/SafeCastI256.sol";

pragma solidity >=0.8.19;

import "./SafeCast.sol";

// todo: do we need all the below logic or can we trim it down, do we need to use sets or can use an alternative?
// todo: consider directly importing this dependency from syntehtix
library SetUtil {
    using SafeCastAddress for address;
    using SafeCastBytes32 for bytes32;
    using SafeCastU256 for uint256;

    // ----------------------------------------
    // Uint support
    // ----------------------------------------

    struct UintSet {
        Bytes32Set raw;
    }

    function add(UintSet storage set, uint256 value) internal {
        add(set.raw, value.toBytes32());
    }

    function remove(UintSet storage set, uint256 value) internal {
        remove(set.raw, value.toBytes32());
    }

    function replace(UintSet storage set, uint256 value, uint256 newValue) internal {
        replace(set.raw, value.toBytes32(), newValue.toBytes32());
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return contains(set.raw, value.toBytes32());
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return length(set.raw);
    }

    function valueAt(UintSet storage set, uint256 position) internal view returns (uint256) {
        return valueAt(set.raw, position).toUint();
    }

    function positionOf(UintSet storage set, uint256 value) internal view returns (uint256) {
        return positionOf(set.raw, value.toBytes32());
    }

    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = values(set.raw);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // ----------------------------------------
    // Address support
    // ----------------------------------------

    struct AddressSet {
        Bytes32Set raw;
    }

    function add(AddressSet storage set, address value) internal {
        add(set.raw, value.toBytes32());
    }

    function remove(AddressSet storage set, address value) internal {
        remove(set.raw, value.toBytes32());
    }

    function replace(AddressSet storage set, address value, address newValue) internal {
        replace(set.raw, value.toBytes32(), newValue.toBytes32());
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return contains(set.raw, value.toBytes32());
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return length(set.raw);
    }

    function valueAt(AddressSet storage set, uint256 position) internal view returns (address) {
        return valueAt(set.raw, position).toAddress();
    }

    function positionOf(AddressSet storage set, address value) internal view returns (uint256) {
        return positionOf(set.raw, value.toBytes32());
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = values(set.raw);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // ----------------------------------------
    // Core bytes32 support
    // ----------------------------------------

    error PositionOutOfBounds();
    error ValueNotInSet();
    error ValueAlreadyInSet();

    struct Bytes32Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _positions; // Position zero is never used.
    }

    function add(Bytes32Set storage set, bytes32 value) internal {
        if (contains(set, value)) {
            revert ValueAlreadyInSet();
        }

        set._values.push(value);
        set._positions[value] = set._values.length;
    }

    function remove(Bytes32Set storage set, bytes32 value) internal {
        uint256 position = set._positions[value];
        if (position == 0) {
            revert ValueNotInSet();
        }

        uint256 index = position - 1;
        uint256 lastIndex = set._values.length - 1;

        // If the element being deleted is not the last in the values,
        // move the last element to its position.
        if (index != lastIndex) {
            bytes32 lastValue = set._values[lastIndex];

            set._values[index] = lastValue;
            set._positions[lastValue] = position;
        }

        // Remove the last element in the values.
        set._values.pop();
        delete set._positions[value];
    }

    function replace(Bytes32Set storage set, bytes32 value, bytes32 newValue) internal {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        if (contains(set, newValue)) {
            revert ValueAlreadyInSet();
        }

        uint256 position = set._positions[value];
        delete set._positions[value];

        uint256 index = position - 1;

        set._values[index] = newValue;
        set._positions[newValue] = position;
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return set._positions[value] != 0;
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function valueAt(Bytes32Set storage set, uint256 position) internal view returns (bytes32) {
        if (position == 0 || position > set._values.length) {
            revert PositionOutOfBounds();
        }

        uint256 index = position - 1;

        return set._values[index];
    }

    function positionOf(Bytes32Set storage set, bytes32 value) internal view returns (uint256) {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        return set._positions[value];
    }

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return set._values;
    }
}

pragma solidity >=0.8.19;

/**
 * @title See SafeCast.sol.
 */
library SafeCastAddress {
    function toBytes32(address x) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(x)));
    }
}

pragma solidity >=0.8.19;

/**
 * @title See SafeCast.sol.
 */
library SafeCastBytes32 {
    function toAddress(bytes32 x) internal pure returns (address) {
        return address(uint160(uint256(x)));
    }

    function toUint(bytes32 x) internal pure returns (uint256) {
        return uint256(x);
    }
}

pragma solidity >=0.8.19;
/**
 * @title See SafeCast.sol.
 */

library SafeCastI256 {
    error OverflowInt256ToUint256();
    error OverflowInt256ToInt128();
    error OverflowInt256ToInt24();

    function to128(int256 x) internal pure returns (int128) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxx<==============o==============>xxxxxxxxxxxxx----
        if (x < int256(type(int128).min) || x > int256(type(int128).max)) {
            revert OverflowInt256ToInt128();
        }

        return int128(x);
    }

    function to24(int256 x) internal pure returns (int24) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxx<======o=======>xxxxxxxxxxxxxxxxxxxx----
        if (x < int256(type(int24).min) || x > int256(type(int24).max)) {
            revert OverflowInt256ToInt24();
        }

        return int24(x);
    }

    function toUint(int256 x) internal pure returns (uint256) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxxxxxxxxxo===============================>
        if (x < 0) {
            revert OverflowInt256ToUint256();
        }

        return uint256(x);
    }

    function zero() internal pure returns (int256) {
        return int256(0);
    }
}

pragma solidity >=0.8.19;
/**
 * @title See SafeCast.sol.
 */

library SafeCastU128 {
    error OverflowUint128ToInt128();

    function to256(uint128 x) internal pure returns (uint256) {
        return uint256(x);
    }

    function toInt(uint128 x) internal pure returns (int128) {
        // -------------------------------o===============>----------------
        // ----------------<==============o==============>x----------------
        if (x > uint128(type(int128).max)) {
            revert OverflowUint128ToInt128();
        }

        return int128(x);
    }

    function toBytes32(uint128 x) internal pure returns (bytes32) {
        return bytes32(uint256(x));
    }
}

pragma solidity >=0.8.19;
/**
 * @title See SafeCast.sol.
 */

library SafeCastU256 {
    error OverflowUint256ToUint128();
    error OverflowUint256ToInt256();
    error OverflowUint256ToUint64();
    error OverflowUint256ToUint32();
    error OverflowUint256ToUint160();

    function to128(uint256 x) internal pure returns (uint128) {
        // -------------------------------o===============================>
        // -------------------------------o===============>xxxxxxxxxxxxxxxx
        if (x > type(uint128).max) {
            revert OverflowUint256ToUint128();
        }

        return uint128(x);
    }

    function to64(uint256 x) internal pure returns (uint64) {
        // -------------------------------o===============================>
        // -------------------------------o======>xxxxxxxxxxxxxxxxxxxxxxxxx
        if (x > type(uint64).max) {
            revert OverflowUint256ToUint64();
        }

        return uint64(x);
    }

    function to32(uint256 x) internal pure returns (uint32) {
        // -------------------------------o===============================>
        // -------------------------------o===>xxxxxxxxxxxxxxxxxxxxxxxxxxxx
        if (x > type(uint32).max) {
            revert OverflowUint256ToUint32();
        }

        return uint32(x);
    }

    function to160(uint256 x) internal pure returns (uint160) {
        // -------------------------------o===============================>
        // -------------------------------o==================>xxxxxxxxxxxxx
        if (x > type(uint160).max) {
            revert OverflowUint256ToUint160();
        }

        return uint160(x);
    }

    function toBytes32(uint256 x) internal pure returns (bytes32) {
        return bytes32(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        // -------------------------------o===============================>
        // ----<==========================o===========================>xxxx
        if (x > uint256(type(int256).max)) {
            revert OverflowUint256ToInt256();
        }

        return int256(x);
    }
}

pragma solidity >=0.8.19;

/**
 * @title Contract for facilitating ownership by a single address.
 */

interface IOwnable {
    /**
     * @notice Thrown when an address tries to accept ownership but has not been nominated.
     * @param addr The address that is trying to accept ownership.
     */
    error NotNominated(address addr);

    /**
     * @notice Emitted when an address has been nominated.
     * @param newOwner The address that has been nominated.
     */
    event OwnerNominated(address newOwner);

    /**
     * @notice Emitted when the owner of the contract has changed.
     * @param oldOwner The previous owner of the contract.
     * @param newOwner The new owner of the contract.
     */
    event OwnerChanged(address oldOwner, address newOwner);

    /**
     * @notice Allows a nominated address to accept ownership of the contract.
     * @dev Reverts if the caller is not nominated.
     */
    function acceptOwnership() external;

    /**
     * @notice Allows the current owner to nominate a new owner.
     * @dev The nominated owner will have to call `acceptOwnership` in a separate transaction in order to finalize the action and
     * become the new contract owner.
     * @param newNominatedOwner The address that is to become nominated.
     */
    function nominateNewOwner(address newNominatedOwner) external;

    /**
     * @notice Allows a nominated owner to reject the nomination.
     */
    function renounceNomination() external;

    /**
     * @notice Returns the current owner of the contract.
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the current nominated owner of the contract.
     * @dev Only one address can be nominated at a time.
     */
    function nominatedOwner() external view returns (address);
}

pragma solidity >=0.8.19;

import "../storage/OwnableStorage.sol";
import "../interfaces/IOwnable.sol";
import "../errors/AddressError.sol";
import "../errors/ChangeError.sol";

/**
 * @title Contract for facilitating ownership by a single address.
 * See IOwnable.
 */
contract Ownable is IOwnable {
    constructor(address initialOwner) {
        OwnableStorage.load().owner = initialOwner;
    }

    /**
     * @inheritdoc IOwnable
     */
    function acceptOwnership() public override {
        OwnableStorage.Data storage store = OwnableStorage.load();

        address currentNominatedOwner = store.nominatedOwner;
        if (msg.sender != currentNominatedOwner) {
            revert NotNominated(msg.sender);
        }

        emit OwnerChanged(store.owner, currentNominatedOwner);
        store.owner = currentNominatedOwner;

        store.nominatedOwner = address(0);
    }

    /**
     * @inheritdoc IOwnable
     */
    function nominateNewOwner(address newNominatedOwner) public override onlyOwner {
        OwnableStorage.Data storage store = OwnableStorage.load();

        if (newNominatedOwner == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (newNominatedOwner == store.nominatedOwner) {
            revert ChangeError.NoChange();
        }

        store.nominatedOwner = newNominatedOwner;
        emit OwnerNominated(newNominatedOwner);
    }

    /**
     * @inheritdoc IOwnable
     */
    function renounceNomination() external override {
        OwnableStorage.Data storage store = OwnableStorage.load();

        if (store.nominatedOwner != msg.sender) {
            revert NotNominated(msg.sender);
        }

        store.nominatedOwner = address(0);
    }

    /**
     * @inheritdoc IOwnable
     */
    function owner() external view override returns (address) {
        return OwnableStorage.load().owner;
    }

    /**
     * @inheritdoc IOwnable
     */
    function nominatedOwner() external view override returns (address) {
        return OwnableStorage.load().nominatedOwner;
    }

    /**
     * @dev Reverts if the caller is not the owner.
     */
    modifier onlyOwner() {
        OwnableStorage.onlyOwner();

        _;
    }
}

pragma solidity >=0.8.19;

import "../errors/AccessError.sol";

library OwnableStorage {
    bytes32 private constant _SLOT_OWNABLE_STORAGE = keccak256(abi.encode("xyz.voltz.OwnableStorage"));

    struct Data {
        address owner;
        address nominatedOwner;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = _SLOT_OWNABLE_STORAGE;
        assembly {
            store.slot := s
        }
    }

    function onlyOwner() internal view {
        if (msg.sender != getOwner()) {
            revert AccessError.Unauthorized(msg.sender);
        }
    }

    function getOwner() internal view returns (address) {
        return OwnableStorage.load().owner;
    }
}

pragma solidity >=0.8.19;

/**
 * @title Module for granular enabling and disabling of system features and functions.
 *
 * Interface functions that are controlled by a feature flag simply need to add this line to their body:
 * `FeatureFlag.ensureAccessToFeature(FLAG_ID);`
 *
 * If such a line is not present in a function, then it is not controlled by a feature flag.
 *
 * If a feature flag is set and then removed forever, consider deleting the line mentioned above from the function's body.
 */
interface IFeatureFlagModule {
    /**
     * @notice Emitted when general access has been given or removed for a feature.
     * @param feature The bytes32 id of the feature.
     * @param allowAll True if the feature was allowed for everyone and false if it is only allowed for those
     * included in the allowlist.
     */
    event FeatureFlagAllowAllSet(bytes32 indexed feature, bool allowAll);

    /**
     * @notice Emitted when general access has been blocked for a feature.
     * @param feature The bytes32 id of the feature.
     * @param denyAll True if the feature was blocked for everyone and false if it is only allowed for those included in
     * the allowlist or if allowAll is set to true.
     */
    event FeatureFlagDenyAllSet(bytes32 indexed feature, bool denyAll);

    /**
     * @notice Emitted when an address was given access to a feature.
     * @param feature The bytes32 id of the feature.
     * @param account The address that was given access to the feature.
     */
    event FeatureFlagAllowlistAdded(bytes32 indexed feature, address account);

    /**
     * @notice Emitted when access to a feature has been removed from an address.
     * @param feature The bytes32 id of the feature.
     * @param account The address that no longer has access to the feature.
     */
    event FeatureFlagAllowlistRemoved(bytes32 indexed feature, address account);

    /**
     * @notice Emitted when the list of addresses which can block a feature has been updated
     * @param feature The bytes32 id of the feature.
     * @param deniers The list of addresses which are allowed to block a feature
     */
    event FeatureFlagDeniersReset(bytes32 indexed feature, address[] deniers);

    /**
     * @notice Enables or disables free access to a feature.
     * @param feature The bytes32 id of the feature.
     * @param allowAll True to allow anyone to use the feature, false to fallback to the allowlist.
     */
    function setFeatureFlagAllowAll(bytes32 feature, bool allowAll) external;

    /**
     * @notice Enables or disables free access to a feature.
     * @param feature The bytes32 id of the feature.
     * @param denyAll True to allow noone to use the feature, false to fallback to the allowlist.
     */
    function setFeatureFlagDenyAll(bytes32 feature, bool denyAll) external;

    /**
     * @notice Allows an address to use a feature.
     * @dev This function does nothing if the specified account is already on the allowlist.
     * @param feature The bytes32 id of the feature.
     * @param account The address that is allowed to use the feature.
     */
    function addToFeatureFlagAllowlist(bytes32 feature, address account) external;

    /**
     * @notice Disallows an address from using a feature.
     * @dev This function does nothing if the specified account is already on the allowlist.
     * @param feature The bytes32 id of the feature.
     * @param account The address that is disallowed from using the feature.
     */
    function removeFromFeatureFlagAllowlist(bytes32 feature, address account) external;

    /**
     * @notice Sets addresses which can disable a feature (but not enable it). Overwrites any preexisting data.
     * @param feature The bytes32 id of the feature.
     * @param deniers The addresses which should have the ability to unilaterally disable the feature
     */
    function setDeniers(bytes32 feature, address[] memory deniers) external;

    /**
     * @notice Gets the list of address which can block a feature
     * @param feature The bytes32 id of the feature.
     */
    function getDeniers(bytes32 feature) external returns (address[] memory);

    /**
     * @notice Determines if the given feature is freely allowed to all users.
     * @param feature The bytes32 id of the feature.
     * @return True if anyone is allowed to use the feature, false if per-user control is used.
     */
    function getFeatureFlagAllowAll(bytes32 feature) external view returns (bool);

    /**
     * @notice Determines if the given feature is denied to all users.
     * @param feature The bytes32 id of the feature.
     * @return True if noone is allowed to use the feature.
     */
    function getFeatureFlagDenyAll(bytes32 feature) external view returns (bool);

    /**
     * @notice Returns a list of addresses that are allowed to use the specified feature.
     * @param feature The bytes32 id of the feature.
     * @return The queried list of addresses.
     */
    function getFeatureFlagAllowlist(bytes32 feature) external view returns (address[] memory);

    /**
     * @notice Determines if an address can use the specified feature.
     * @param feature The bytes32 id of the feature.
     * @param account The address that is being queried for access to the feature.
     * @return A boolean with the response to the query.
     */
    function isFeatureAllowed(bytes32 feature, address account) external view returns (bool);
}

pragma solidity >=0.8.19;

import "@voltz-protocol/util-contracts/src/ownership/Ownable.sol";
import "../storage/FeatureFlag.sol";

import "../interfaces/IFeatureFlagModule.sol";

/**
 * @title Module for granular enabling and disabling of system features and functions.
 * See IFeatureFlagModule.
 */
contract FeatureFlagModule is IFeatureFlagModule {
    using SetUtil for SetUtil.AddressSet;
    using FeatureFlag for FeatureFlag.Data;

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function setFeatureFlagAllowAll(bytes32 feature, bool allowAll) external override {
        OwnableStorage.onlyOwner();
        FeatureFlag.load(feature).allowAll = allowAll;

        if (allowAll) {
            FeatureFlag.load(feature).denyAll = false;
        }

        emit FeatureFlagAllowAllSet(feature, allowAll);
    }

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function setFeatureFlagDenyAll(bytes32 feature, bool denyAll) external override {
        FeatureFlag.Data storage flag = FeatureFlag.load(feature);

        if (!denyAll || !flag.isDenier(msg.sender)) {
            OwnableStorage.onlyOwner();
        }

        flag.denyAll = denyAll;

        emit FeatureFlagDenyAllSet(feature, denyAll);
    }

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function addToFeatureFlagAllowlist(bytes32 feature, address account) external override {
        OwnableStorage.onlyOwner();

        SetUtil.AddressSet storage permissionedAddresses = FeatureFlag.load(feature).permissionedAddresses;

        if (!permissionedAddresses.contains(account)) {
            permissionedAddresses.add(account);
            emit FeatureFlagAllowlistAdded(feature, account);
        }
    }

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function removeFromFeatureFlagAllowlist(bytes32 feature, address account) external override {
        OwnableStorage.onlyOwner();

        SetUtil.AddressSet storage permissionedAddresses = FeatureFlag.load(feature).permissionedAddresses;

        if (permissionedAddresses.contains(account)) {
            FeatureFlag.load(feature).permissionedAddresses.remove(account);
            emit FeatureFlagAllowlistRemoved(feature, account);
        }
    }

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function setDeniers(bytes32 feature, address[] memory deniers) external override {
        OwnableStorage.onlyOwner();
        FeatureFlag.Data storage flag = FeatureFlag.load(feature);

        // resize array (its really dumb how you have to do this)
        uint256 storageLen = flag.deniers.length;
        for (uint256 i = storageLen; i > deniers.length; i--) {
            flag.deniers.pop();
        }

        for (uint256 i = 0; i < deniers.length; i++) {
            if (i >= storageLen) {
                flag.deniers.push(deniers[i]);
            } else {
                flag.deniers[i] = deniers[i];
            }
        }

        emit FeatureFlagDeniersReset(feature, deniers);
    }

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function getDeniers(bytes32 feature) external view override returns (address[] memory) {
        FeatureFlag.Data storage flag = FeatureFlag.load(feature);
        address[] memory addrs = new address[](flag.deniers.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            addrs[i] = flag.deniers[i];
        }

        return addrs;
    }

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function getFeatureFlagAllowAll(bytes32 feature) external view override returns (bool) {
        return FeatureFlag.load(feature).allowAll;
    }

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function getFeatureFlagDenyAll(bytes32 feature) external view override returns (bool) {
        return FeatureFlag.load(feature).denyAll;
    }

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function getFeatureFlagAllowlist(bytes32 feature) external view override returns (address[] memory) {
        return FeatureFlag.load(feature).permissionedAddresses.values();
    }

    /**
     * @inheritdoc IFeatureFlagModule
     */
    function isFeatureAllowed(bytes32 feature, address account) external view override returns (bool) {
        return FeatureFlag.hasAccess(feature, account);
    }
}

pragma solidity >=0.8.19;

import "@voltz-protocol/util-contracts/src/helpers/SetUtil.sol";

library FeatureFlag {
    using SetUtil for SetUtil.AddressSet;

    error FeatureUnavailable(bytes32 which);

    struct Data {
        bytes32 name;
        bool allowAll;
        bool denyAll;
        SetUtil.AddressSet permissionedAddresses;
        address[] deniers;
    }

    function load(bytes32 featureName) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("xyz.voltz.FeatureFlag", featureName));
        assembly {
            store.slot := s
        }
    }

    function ensureAccessToFeature(bytes32 feature) internal view {
        if (!hasAccess(feature, msg.sender)) {
            revert FeatureUnavailable(feature);
        }
    }

    function hasAccess(bytes32 feature, address value) internal view returns (bool) {
        Data storage store = FeatureFlag.load(feature);

        if (store.denyAll) {
            return false;
        }

        return store.allowAll || store.permissionedAddresses.contains(value);
    }

    function isDenier(Data storage self, address possibleDenier) internal view returns (bool) {
        for (uint256 i = 0; i < self.deniers.length; i++) {
            if (self.deniers[i] == possibleDenier) {
                return true;
            }
        }

        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface IPoolConfigurationModule {

  /// @notice Pausing or unpausing trading activity on the vamm
  /// @param paused True if the desire is to pause the vamm, and false inversely
  function setPauseState(bool paused) external;

  /// @notice Setting the product (instrument) address
  /// @param productAddress Address of the product proxy
  function setProductAddress(address productAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../interfaces/IPoolConfigurationModule.sol";

import "../storage/PoolConfiguration.sol";
import "@voltz-protocol/util-modules/src/modules/FeatureFlagModule.sol";
import "@voltz-protocol/util-contracts/src/storage/OwnableStorage.sol";

contract PoolConfigurationModule is IPoolConfigurationModule {
  using PoolConfiguration for PoolConfiguration.Data;

  bytes32 private constant _PAUSER_FEATURE_FLAG = "pauser";

  function setPauseState(bool paused) external override {
    FeatureFlag.ensureAccessToFeature(_PAUSER_FEATURE_FLAG);
    PoolConfiguration.load().setPauseState(paused);
  }

  function setProductAddress(address productAddress) external override {
    OwnableStorage.onlyOwner();
    PoolConfiguration.load().setProductAddress(productAddress);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/// @title Interface a Pool needs to adhere.
library PoolConfiguration {
    event PauseState(bool newPauseState, uint256 blockTimestamp);

    struct Data {
        bool paused;
        address productAddress;
    }

    function load() internal pure returns (Data storage self) {
        bytes32 s = keccak256(abi.encode("xyz.voltz.PoolConfiguration"));
        assembly {
            self.slot := s
        }
    }

    function setPauseState(Data storage self, bool state) internal {
        self.paused = state;
        emit PauseState(state, block.timestamp);
    }

    function setProductAddress(Data storage self, address _productAddress) internal {
        self.productAddress = _productAddress;
    }

    function whenNotPaused() internal view {
        require(!PoolConfiguration.load().paused, "Paused");
    }
}