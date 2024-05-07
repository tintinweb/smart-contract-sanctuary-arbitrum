// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

uint256 constant MAX_SMT_DEPTH = 64;

interface IState {
    /**
     * @dev Struct for public interfaces to represent a state information.
     * @param id An identity.
     * @param state A state.
     * @param replacedByState A state, which replaced this state for the identity.
     * @param createdAtTimestamp A time when the state was created.
     * @param replacedAtTimestamp A time when the state was replaced by the next identity state.
     * @param createdAtBlock A block number when the state was created.
     * @param replacedAtBlock A block number when the state was replaced by the next identity state.
     */
    struct StateInfo {
        uint256 id;
        uint256 state;
        uint256 replacedByState;
        uint256 createdAtTimestamp;
        uint256 replacedAtTimestamp;
        uint256 createdAtBlock;
        uint256 replacedAtBlock;
    }

    /**
     * @dev Struct for public interfaces to represent GIST root information.
     * @param root This GIST root.
     * @param replacedByRoot A root, which replaced this root.
     * @param createdAtTimestamp A time, when the root was saved to blockchain.
     * @param replacedAtTimestamp A time, when the root was replaced by the next root in blockchain.
     * @param createdAtBlock A number of block, when the root was saved to blockchain.
     * @param replacedAtBlock A number of block, when the root was replaced by the next root in blockchain.
     */
    struct GistRootInfo {
        uint256 root;
        uint256 replacedByRoot;
        uint256 createdAtTimestamp;
        uint256 replacedAtTimestamp;
        uint256 createdAtBlock;
        uint256 replacedAtBlock;
    }

    /**
     * @dev Struct for public interfaces to represent GIST proof information.
     * @param root This GIST root.
     * @param existence A flag, which shows if the leaf index exists in the GIST.
     * @param siblings An array of GIST sibling node hashes.
     * @param index An index of the leaf in the GIST.
     * @param value A value of the leaf in the GIST.
     * @param auxExistence A flag, which shows if the auxiliary leaf exists in the GIST.
     * @param auxIndex An index of the auxiliary leaf in the GIST.
     * @param auxValue An value of the auxiliary leaf in the GIST.
     */
    struct GistProof {
        uint256 root;
        bool existence;
        uint256[MAX_SMT_DEPTH] siblings;
        uint256 index;
        uint256 value;
        bool auxExistence;
        uint256 auxIndex;
        uint256 auxValue;
    }

    /**
     * @dev Retrieve last state information of specific id.
     * @param id An identity.
     * @return The state info.
     */
    function getStateInfoById(uint256 id) external view returns (StateInfo memory);

    /**
     * @dev Retrieve state information by id and state.
     * @param id An identity.
     * @param state A state.
     * @return The state info.
     */
    function getStateInfoByIdAndState(
        uint256 id,
        uint256 state
    ) external view returns (StateInfo memory);

    /**
     * @dev Retrieve the specific GIST root information.
     * @param root GIST root.
     * @return The GIST root info.
     */
    function getGISTRootInfo(uint256 root) external view returns (GistRootInfo memory);

    /**
     * @dev Get defaultIdType
     * @return defaultIdType
     */
    function getDefaultIdType() external view returns (bytes2);

    /**
     * @dev Performs state transition
     * @param id Identifier of the identity
     * @param oldState Previous state of the identity
     * @param newState New state of the identity
     * @param isOldStateGenesis Flag if previous identity state is genesis
     * @param a Proof.A
     * @param b Proof.B
     * @param c Proof.C
     */
    function transitState(
        uint256 id,
        uint256 oldState,
        uint256 newState,
        bool isOldStateGenesis,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c
    ) external;

    /**
     * @dev Performs state transition
     * @param id Identity
     * @param oldState Previous identity state
     * @param newState New identity state
     * @param isOldStateGenesis Is the previous state genesis?
     * @param methodId State transition method id
     * @param methodParams State transition method-specific params
     */
    function transitStateGeneric(
        uint256 id,
        uint256 oldState,
        uint256 newState,
        bool isOldStateGenesis,
        uint256 methodId,
        bytes calldata methodParams
    ) external;

    /**
     * @dev Check if identity exists.
     * @param id Identity
     * @return True if the identity exists
     */
    function idExists(uint256 id) external view returns (bool);

    /**
     * @dev Check if state exists.
     * @param id Identity
     * @param state State
     * @return True if the state exists
     */
    function stateExists(uint256 id, uint256 state) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import {PrimitiveTypeUtils} from "./PrimitiveTypeUtils.sol";

library GenesisUtils {
    /**
     *   @dev sum
     */
    function sum(bytes memory array) internal pure returns (uint16 s) {
        require(array.length == 29, "Checksum requires 29 length array");

        for (uint256 i = 0; i < array.length; ++i) {
            s += uint16(uint8(array[i]));
        }
    }

    /**
     * @dev isGenesisState
     */
    function isGenesisState(uint256 id, uint256 idState) internal pure returns (bool) {
        bytes2 idType = bytes2(
            PrimitiveTypeUtils.uint256ToBytes(PrimitiveTypeUtils.reverseUint256(id))
        );
        uint256 computedId = calcIdFromGenesisState(idType, idState);
        return id == computedId;
    }

    /**
     * @dev calcIdFromGenesisState
     */
    function calcIdFromGenesisState(
        bytes2 idType,
        uint256 idState
    ) internal pure returns (uint256) {
        bytes memory userStateB1 = PrimitiveTypeUtils.uint256ToBytes(
            PrimitiveTypeUtils.reverseUint256(idState)
        );

        bytes memory cutState = PrimitiveTypeUtils.slice(userStateB1, userStateB1.length - 27, 27);

        bytes memory beforeChecksum = PrimitiveTypeUtils.concat(abi.encodePacked(idType), cutState);
        require(beforeChecksum.length == 29, "Checksum requires 29 length array");

        uint16 checksum = PrimitiveTypeUtils.reverseUint16(sum(beforeChecksum));

        bytes memory checkSumBytes = abi.encodePacked(checksum);

        bytes memory idBytes = PrimitiveTypeUtils.concat(beforeChecksum, checkSumBytes);
        require(idBytes.length == 31, "idBytes requires 31 length array");

        return PrimitiveTypeUtils.reverseUint256(PrimitiveTypeUtils.toUint256(idBytes));
    }

    /**
     * @dev calcIdFromEthAddress
     */
    function calcIdFromEthAddress(bytes2 idType, address caller) internal pure returns (uint256) {
        uint256 addr = PrimitiveTypeUtils.addressToUint256(caller);

        return calcIdFromGenesisState(idType, PrimitiveTypeUtils.reverseUint256(addr));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

library PoseidonUnit1L {
    function poseidon(uint256[1] calldata) public pure returns (uint256) {}
}

library PoseidonUnit2L {
    function poseidon(uint256[2] calldata) public pure returns (uint256) {}
}

library PoseidonUnit3L {
    function poseidon(uint256[3] calldata) public pure returns (uint256) {}
}

library PoseidonUnit4L {
    function poseidon(uint256[4] calldata) public pure returns (uint256) {}
}

library PoseidonUnit5L {
    function poseidon(uint256[5] calldata) public pure returns (uint256) {}
}

library PoseidonUnit6L {
    function poseidon(uint256[6] calldata) public pure returns (uint256) {}
}

library SpongePoseidon {
    uint32 internal constant BATCH_SIZE = 6;

    function hash(uint256[] calldata values) public pure returns (uint256) {
        uint256[BATCH_SIZE] memory frame = [uint256(0), 0, 0, 0, 0, 0];
        bool dirty = false;
        uint256 fullHash = 0;
        uint32 k = 0;
        for (uint32 i = 0; i < values.length; i++) {
            dirty = true;
            frame[k] = values[i];
            if (k == BATCH_SIZE - 1) {
                fullHash = PoseidonUnit6L.poseidon(frame);
                dirty = false;
                frame = [uint256(0), 0, 0, 0, 0, 0];
                frame[0] = fullHash;
                k = 1;
            } else {
                k++;
            }
        }
        if (dirty) {
            // we haven't hashed something in the main sponge loop and need to do hash here
            fullHash = PoseidonUnit6L.poseidon(frame);
        }
        return fullHash;
    }
}

library PoseidonFacade {
    function poseidon1(uint256[1] calldata el) public pure returns (uint256) {
        return PoseidonUnit1L.poseidon(el);
    }

    function poseidon2(uint256[2] calldata el) public pure returns (uint256) {
        return PoseidonUnit2L.poseidon(el);
    }

    function poseidon3(uint256[3] calldata el) public pure returns (uint256) {
        return PoseidonUnit3L.poseidon(el);
    }

    function poseidon4(uint256[4] calldata el) public pure returns (uint256) {
        return PoseidonUnit4L.poseidon(el);
    }

    function poseidon5(uint256[5] calldata el) public pure returns (uint256) {
        return PoseidonUnit5L.poseidon(el);
    }

    function poseidon6(uint256[6] calldata el) public pure returns (uint256) {
        return PoseidonUnit6L.poseidon(el);
    }

    function poseidonSponge(uint256[] calldata el) public pure returns (uint256) {
        return SpongePoseidon.hash(el);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";

library PrimitiveTypeUtils {
    /**
     * @dev uint256ToBytes
     */
    function uint256ToBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }

    /**
     * @dev reverse uint256
     */
    function reverseUint256(uint256 input) internal pure returns (uint256 v) {
        v = input;

        // swap bytes
        v =
            ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v =
            ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v =
            ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v =
            ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64) |
            ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    /**
     * @dev reverse uint16
     */
    function reverseUint16(uint16 input) internal pure returns (uint16 v) {
        v = input;

        // swap bytes
        v = (v >> 8) | (v << 8);
    }

    /**
     * @dev reverse uint32
     */
    function reverseUint32(uint32 input) internal pure returns (uint32 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00) >> 8) | ((v & 0x00FF00FF) << 8);

        // swap 2-byte long pairs
        v = (v >> 16) | (v << 16);
    }

    /**
     * @dev compareStrings
     */
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        }
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    /**
     * @dev toUint256
     */
    function toUint256(bytes memory bys) internal pure returns (uint256 value) {
        assembly {
            value := mload(add(bys, 0x20))
        }
    }

    /**
     * @dev bytesToAddress
     */
    function bytesToAddress(bytes memory bys) internal pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    /**
     * @dev int256ToAddress
     */
    function int256ToAddress(uint256 input) internal pure returns (address) {
        return bytesToAddress(uint256ToBytes(reverseUint256(input)));
    }

    /**
     * @dev concat
     */
    function concat(
        bytes memory preBytes,
        bytes memory postBytes
    ) internal pure returns (bytes memory) {
        return BytesLib.concat(preBytes, postBytes);
    }

    /**
     * @dev slice
     */
    function slice(
        bytes memory bys,
        uint256 start,
        uint256 length
    ) internal pure returns (bytes memory) {
        return BytesLib.slice(bys, start, length);
    }

    /**
     * @dev addressToUint256
     */
    function addressToUint256(address _addr) internal pure returns (uint256) {
        return uint256(uint160(_addr));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import {Initializable} from "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import {Initializable} from "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {StringSet} from "../data-structures/StringSet.sol";

/**
 * @notice Library for pagination.
 *
 * Supports the following data types `uin256[]`, `address[]`, `bytes32[]`, `UintSet`,
 * `AddressSet`, `BytesSet`, `StringSet`.
 */
library Paginator {
    using EnumerableSet for *;
    using StringSet for StringSet.Set;

    /**
     * @notice Returns part of a uint256 array
     *
     * Examples:
     * - part([4, 5, 6, 7], 0, 4) will return [4, 5, 6, 7]
     * - part([4, 5, 6, 7], 2, 4) will return [6, 7]
     * - part([4, 5, 6, 7], 2, 1) will return [6]
     *
     * @param arr the storage array
     * @param offset_ the starting index in the array
     * @param limit_ the number of elements after the `offset_`
     */
    function part(
        uint256[] storage arr,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (uint256[] memory list_) {
        uint256 to_ = getTo(arr.length, offset_, limit_);

        list_ = new uint256[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = arr[i];
        }
    }

    /**
     * @notice Returns part of an address array
     */
    function part(
        address[] storage arr,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (address[] memory list_) {
        uint256 to_ = getTo(arr.length, offset_, limit_);

        list_ = new address[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = arr[i];
        }
    }

    /**
     * @notice Returns part of a bytes32 array
     */
    function part(
        bytes32[] storage arr,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (bytes32[] memory list_) {
        uint256 to_ = getTo(arr.length, offset_, limit_);

        list_ = new bytes32[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = arr[i];
        }
    }

    /**
     * @notice Returns part of a uint256 set
     * @param set the storage set
     * @param offset_ the starting index in the set
     * @param limit_ the number of elements after the `offset`
     */
    function part(
        EnumerableSet.UintSet storage set,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (uint256[] memory list_) {
        uint256 to_ = getTo(set.length(), offset_, limit_);

        list_ = new uint256[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = set.at(i);
        }
    }

    /**
     * @notice Returns part of an address set
     */
    function part(
        EnumerableSet.AddressSet storage set,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (address[] memory list_) {
        uint256 to_ = getTo(set.length(), offset_, limit_);

        list_ = new address[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = set.at(i);
        }
    }

    /**
     * @notice Returns part of a bytes32 set
     */
    function part(
        EnumerableSet.Bytes32Set storage set,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (bytes32[] memory list_) {
        uint256 to_ = getTo(set.length(), offset_, limit_);

        list_ = new bytes32[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = set.at(i);
        }
    }

    /**
     * @notice Returns part of a string set
     */
    function part(
        StringSet.Set storage set,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (string[] memory list_) {
        uint256 to_ = getTo(set.length(), offset_, limit_);

        list_ = new string[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = set.at(i);
        }
    }

    /**
     * @notice Returns the exclusive index of the element to iterate to
     * @param length_ the length of the array
     * @param offset_ the starting index
     * @param limit_ the number of elements
     */
    function getTo(
        uint256 length_,
        uint256 offset_,
        uint256 limit_
    ) internal pure returns (uint256 to_) {
        to_ = offset_ + limit_;

        if (to_ > length_) {
            to_ = length_;
        }

        if (offset_ > to_) {
            to_ = offset_;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {StringSet} from "../data-structures/StringSet.sol";

/**
 * @notice A simple library to work with Openzeppelin sets
 */
library SetHelper {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using StringSet for StringSet.Set;

    /**
     * @notice The function to insert an array of elements into the address set
     * @param set the set to insert the elements into
     * @param array_ the elements to be inserted
     */
    function add(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     * @notice The function to insert an array of elements into the uint256 set
     */
    function add(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     * @notice The function to insert an array of elements into the bytes32 set
     */
    function add(EnumerableSet.Bytes32Set storage set, bytes32[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     * @notice The function to insert an array of elements into the string set
     */
    function add(StringSet.Set storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     * @notice The function for the strict insertion of an array of elements into the address set
     * @param set the set to insert the elements into
     * @param array_ the elements to be inserted
     */
    function strictAdd(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            require(set.add(array_[i]), "SetHelper: element already exists");
        }
    }

    /**
     * @notice The function for the strict insertion of an array of elements into the uint256 set
     */
    function strictAdd(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            require(set.add(array_[i]), "SetHelper: element already exists");
        }
    }

    /**
     * @notice The function for the strict insertion of an array of elements into the bytes32 set
     */
    function strictAdd(EnumerableSet.Bytes32Set storage set, bytes32[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            require(set.add(array_[i]), "SetHelper: element already exists");
        }
    }

    /**
     * @notice The function for the strict insertion of an array of elements into the string set
     */
    function strictAdd(StringSet.Set storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            require(set.add(array_[i]), "SetHelper: element already exists");
        }
    }

    /**
     * @notice The function to remove an array of elements from the address set
     * @param set the set to remove the elements from
     * @param array_ the elements to be removed
     */
    function remove(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    /**
     * @notice The function to remove an array of elements from the uint256 set
     */
    function remove(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    /**
     * @notice The function to remove an array of elements from the bytes32 set
     */
    function remove(EnumerableSet.Bytes32Set storage set, bytes32[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    /**
     * @notice The function to remove an array of elements from the string set
     */
    function remove(StringSet.Set storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    /**
     * @notice The function for the strict removal of an array of elements from the address set
     * @param set the set to remove the elements from
     * @param array_ the elements to be removed
     */
    function strictRemove(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            require(set.remove(array_[i]), "SetHelper: no such element");
        }
    }

    /**
     * @notice The function for the strict removal of an array of elements from the uint256 set
     */
    function strictRemove(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            require(set.remove(array_[i]), "SetHelper: no such element");
        }
    }

    /**
     * @notice The function for the strict removal of an array of elements from the bytes32 set
     */
    function strictRemove(EnumerableSet.Bytes32Set storage set, bytes32[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            require(set.remove(array_[i]), "SetHelper: no such element");
        }
    }

    /**
     * @notice The function for the strict removal of an array of elements from the string set
     */
    function strictRemove(StringSet.Set storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            require(set.remove(array_[i]), "SetHelper: no such element");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {TypeCaster} from "../../utils/TypeCaster.sol";

/**
 * @notice The memory data structures module
 *
 * This library is inspired by C++ STD vector to enable push() and pop() operations for memory arrays.
 *
 * Currently Solidity allows resizing only storage arrays, which may be a roadblock if you need to
 * filter the elements by a specific property or add new ones without writing bulky code. The Vector library
 * is meant to help with that.
 *
 * It is very important to create Vectors via constructors (newUint, newBytes32, newAddress) as they allocate and clean
 * the memory for the data structure.
 *
 * The Vector works by knowing how much memory it uses (allocation) and keeping the reference to the underlying
 * low-level Solidity array. When a new element gets pushed, the Vector tries to store it in the underlying array. If the
 * number of elements exceed the allocation, the Vector will reallocate the array to a bigger memory chunk and store the
 * new element there.
 *
 * ## Usage example:
 * ```
 * using Vector for Vector.UintVector;
 *
 * Vector.UintVector memory vector = Vector.newUint();
 *
 * vector.push(123);
 * ```
 */
library Vector {
    using TypeCaster for *;

    /**
     ************************
     *      UintVector      *
     ************************
     */

    struct UintVector {
        Vector _vector;
    }

    /**
     * @notice The UintVector constructor, creates an empty vector instance, O(1) complex
     * @return vector the newly created instance
     */
    function newUint() internal pure returns (UintVector memory vector) {
        vector._vector = _new();
    }

    /**
     * @notice The UintVector constructor, creates a vector instance with defined length, O(n) complex
     * @dev The length_ number of default value elements will be added to the vector
     * @param length_ the initial number of elements
     * @return vector the newly created instance
     */
    function newUint(uint256 length_) internal pure returns (UintVector memory vector) {
        vector._vector = _new(length_);
    }

    /**
     * @notice The UintVector constructor, creates a vector instance from the array, O(1) complex
     * @param array_ the initial array
     * @return vector the newly created instance
     */
    function newUint(uint256[] memory array_) internal pure returns (UintVector memory vector) {
        vector._vector = _new(array_.asBytes32Array());
    }

    /**
     * @notice The function to push new elements (as an array) to the uint256 vector, amortized O(n)
     * @param vector self
     * @param values_ the new elements to add
     */
    function push(UintVector memory vector, uint256[] memory values_) internal pure {
        _push(vector._vector, values_.asBytes32Array());
    }

    /**
     * @notice The function to push a new element to the uint256 vector, amortized O(1)
     * @param vector self
     * @param value_ the new element to add
     */
    function push(UintVector memory vector, uint256 value_) internal pure {
        _push(vector._vector, bytes32(value_));
    }

    /**
     * @notice The function to pop the last element from the uint256 vector, O(1)
     * @param vector self
     */
    function pop(UintVector memory vector) internal pure {
        _pop(vector._vector);
    }

    /**
     * @notice The function to assign the value to a uint256 vector element
     * @param vector self
     * @param index_ the index of the element to be assigned
     * @param value_ the value to assign
     */
    function set(UintVector memory vector, uint256 index_, uint256 value_) internal pure {
        _set(vector._vector, index_, bytes32(value_));
    }

    /**
     * @notice The function to read the element of the uint256 vector
     * @param vector self
     * @param index_ the index of the element to read
     * @return the vector element
     */
    function at(UintVector memory vector, uint256 index_) internal pure returns (uint256) {
        return uint256(_at(vector._vector, index_));
    }

    /**
     * @notice The function to get the number of uint256 vector elements
     * @param vector self
     * @return the number of vector elements
     */
    function length(UintVector memory vector) internal pure returns (uint256) {
        return _length(vector._vector);
    }

    /**
     * @notice The function to cast the uint256 vector to an array
     * @dev The function returns the *reference* to the underlying array. Modifying the reference
     * will also modify the vector itself. However, this might not always be the case as the vector
     * resizes
     * @param vector self
     * @return the reference to the solidity array of elements
     */
    function toArray(UintVector memory vector) internal pure returns (uint256[] memory) {
        return _toArray(vector._vector).asUint256Array();
    }

    /**
     ************************
     *     Bytes32Vector    *
     ************************
     */

    struct Bytes32Vector {
        Vector _vector;
    }

    /**
     * @notice The Bytes32Vector constructor, creates an empty vector instance, O(1) complex
     */
    function newBytes32() internal pure returns (Bytes32Vector memory vector) {
        vector._vector = _new();
    }

    /**
     * @notice The Bytes32Vector constructor, creates a vector instance with defined length, O(n) complex
     */
    function newBytes32(uint256 length_) internal pure returns (Bytes32Vector memory vector) {
        vector._vector = _new(length_);
    }

    /**
     * @notice The Bytes32Vector constructor, creates a vector instance from the array, O(1) complex
     */
    function newBytes32(
        bytes32[] memory array_
    ) internal pure returns (Bytes32Vector memory vector) {
        vector._vector = _new(array_);
    }

    /**
     * @notice The function to push new elements (as an array) to the bytes32 vector, amortized O(n)
     */
    function push(Bytes32Vector memory vector, bytes32[] memory values_) internal pure {
        _push(vector._vector, values_);
    }

    /**
     * @notice The function to push a new element to the bytes32 vector, amortized O(1)
     */
    function push(Bytes32Vector memory vector, bytes32 value_) internal pure {
        _push(vector._vector, value_);
    }

    /**
     * @notice The function to pop the last element from the bytes32 vector, O(1)
     */
    function pop(Bytes32Vector memory vector) internal pure {
        _pop(vector._vector);
    }

    /**
     * @notice The function to assign the value to a bytes32 vector element
     */
    function set(Bytes32Vector memory vector, uint256 index_, bytes32 value_) internal pure {
        _set(vector._vector, index_, value_);
    }

    /**
     * @notice The function to read the element of the bytes32 vector
     */
    function at(Bytes32Vector memory vector, uint256 index_) internal pure returns (bytes32) {
        return _at(vector._vector, index_);
    }

    /**
     * @notice The function to get the number of bytes32 vector elements
     */
    function length(Bytes32Vector memory vector) internal pure returns (uint256) {
        return _length(vector._vector);
    }

    /**
     * @notice The function to cast the bytes32 vector to an array
     */
    function toArray(Bytes32Vector memory vector) internal pure returns (bytes32[] memory) {
        return _toArray(vector._vector);
    }

    /**
     ************************
     *     AddressVector    *
     ************************
     */

    struct AddressVector {
        Vector _vector;
    }

    /**
     * @notice The AddressVector constructor, creates an empty vector instance, O(1) complex
     */
    function newAddress() internal pure returns (AddressVector memory vector) {
        vector._vector = _new();
    }

    /**
     * @notice The AddressVector constructor, creates a vector instance with defined length, O(n) complex
     */
    function newAddress(uint256 length_) internal pure returns (AddressVector memory vector) {
        vector._vector = _new(length_);
    }

    /**
     * @notice The AddressVector constructor, creates a vector instance from the array, O(1) complex
     */
    function newAddress(
        address[] memory array_
    ) internal pure returns (AddressVector memory vector) {
        vector._vector = _new(array_.asBytes32Array());
    }

    /**
     * @notice The function to push new elements (as an array) to the address vector, amortized O(n)
     */
    function push(AddressVector memory vector, address[] memory values_) internal pure {
        _push(vector._vector, values_.asBytes32Array());
    }

    /**
     * @notice The function to push a new element to the address vector, amortized O(1)
     */
    function push(AddressVector memory vector, address value_) internal pure {
        _push(vector._vector, bytes32(uint256(uint160(value_))));
    }

    /**
     * @notice The function to pop the last element from the address vector, O(1)
     */
    function pop(AddressVector memory vector) internal pure {
        _pop(vector._vector);
    }

    /**
     * @notice The function to assign the value to an address vector element
     */
    function set(AddressVector memory vector, uint256 index_, address value_) internal pure {
        _set(vector._vector, index_, bytes32(uint256(uint160(value_))));
    }

    /**
     * @notice The function to read the element of the address vector
     */
    function at(AddressVector memory vector, uint256 index_) internal pure returns (address) {
        return address(uint160(uint256(_at(vector._vector, index_))));
    }

    /**
     * @notice The function to get the number of address vector elements
     */
    function length(AddressVector memory vector) internal pure returns (uint256) {
        return _length(vector._vector);
    }

    /**
     * @notice The function to cast the address vector to an array
     */
    function toArray(AddressVector memory vector) internal pure returns (address[] memory) {
        return _toArray(vector._vector).asAddressArray();
    }

    /**
     ************************
     *      InnerVector     *
     ************************
     */

    struct Vector {
        uint256 _allocation;
        uint256 _dataPointer;
    }

    function _new() private pure returns (Vector memory vector) {
        uint256 dataPointer_ = _allocate(5);

        _clean(dataPointer_, 1);

        vector._allocation = 5;
        vector._dataPointer = dataPointer_;
    }

    function _new(uint256 length_) private pure returns (Vector memory vector) {
        uint256 allocation_ = length_ + 1;
        uint256 dataPointer_ = _allocate(allocation_);

        _clean(dataPointer_, allocation_);

        vector._allocation = allocation_;
        vector._dataPointer = dataPointer_;

        assembly {
            mstore(dataPointer_, length_)
        }
    }

    function _new(bytes32[] memory array_) private pure returns (Vector memory vector) {
        assembly {
            mstore(vector, add(mload(array_), 0x1))
            mstore(add(vector, 0x20), array_)
        }
    }

    function _push(Vector memory vector, bytes32[] memory values_) private pure {
        uint256 length_ = values_.length;

        for (uint256 i = 0; i < length_; ++i) {
            _push(vector, values_[i]);
        }
    }

    function _push(Vector memory vector, bytes32 value_) private pure {
        uint256 length_ = _length(vector);

        if (length_ + 1 == vector._allocation) {
            _resize(vector, vector._allocation * 2);
        }

        assembly {
            let dataPointer_ := mload(add(vector, 0x20))

            mstore(dataPointer_, add(length_, 0x1))
            mstore(add(dataPointer_, add(mul(length_, 0x20), 0x20)), value_)
        }
    }

    function _pop(Vector memory vector) private pure {
        uint256 length_ = _length(vector);

        require(length_ > 0, "Vector: empty vector");

        assembly {
            mstore(mload(add(vector, 0x20)), sub(length_, 0x1))
        }
    }

    function _set(Vector memory vector, uint256 index_, bytes32 value_) private pure {
        _requireInBounds(vector, index_);

        assembly {
            mstore(add(mload(add(vector, 0x20)), add(mul(index_, 0x20), 0x20)), value_)
        }
    }

    function _at(Vector memory vector, uint256 index_) private pure returns (bytes32 value_) {
        _requireInBounds(vector, index_);

        assembly {
            value_ := mload(add(mload(add(vector, 0x20)), add(mul(index_, 0x20), 0x20)))
        }
    }

    function _length(Vector memory vector) private pure returns (uint256 length_) {
        assembly {
            length_ := mload(mload(add(vector, 0x20)))
        }
    }

    function _toArray(Vector memory vector) private pure returns (bytes32[] memory array_) {
        assembly {
            array_ := mload(add(vector, 0x20))
        }
    }

    function _resize(Vector memory vector, uint256 newAllocation_) private pure {
        uint256 newDataPointer_ = _allocate(newAllocation_);

        assembly {
            let oldDataPointer_ := mload(add(vector, 0x20))
            let length_ := mload(oldDataPointer_)

            for {
                let i := 0
            } lt(i, add(mul(length_, 0x20), 0x20)) {
                i := add(i, 0x20)
            } {
                mstore(add(newDataPointer_, i), mload(add(oldDataPointer_, i)))
            }

            mstore(vector, newAllocation_)
            mstore(add(vector, 0x20), newDataPointer_)
        }
    }

    function _requireInBounds(Vector memory vector, uint256 index_) private pure {
        require(index_ < _length(vector), "Vector: out of bounds");
    }

    function _clean(uint256 dataPointer_, uint256 slots_) private pure {
        assembly {
            for {
                let i := 0
            } lt(i, mul(slots_, 0x20)) {
                i := add(i, 0x20)
            } {
                mstore(add(dataPointer_, i), 0x0)
            }
        }
    }

    function _allocate(uint256 allocation_) private pure returns (uint256 pointer_) {
        assembly {
            pointer_ := mload(0x40)
            mstore(0x40, add(pointer_, mul(allocation_, 0x20)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice The string extension to Openzeppelin sets
 *
 * ## Usage example:
 *
 * ```
 * using StringSet for StringSet.Set;
 *
 * StringSet.Set internal set;
 * ```
 */
library StringSet {
    struct Set {
        string[] _values;
        mapping(string => uint256) _indexes;
    }

    /**
     * @notice The function add value to set
     * @param set the set object
     * @param value_ the value to add
     */
    function add(Set storage set, string memory value_) internal returns (bool) {
        if (!contains(set, value_)) {
            set._values.push(value_);
            set._indexes[value_] = set._values.length;

            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice The function remove value to set
     * @param set the set object
     * @param value_ the value to remove
     */
    function remove(Set storage set, string memory value_) internal returns (bool) {
        uint256 valueIndex_ = set._indexes[value_];

        if (valueIndex_ != 0) {
            uint256 toDeleteIndex_ = valueIndex_ - 1;
            uint256 lastIndex_ = set._values.length - 1;

            if (lastIndex_ != toDeleteIndex_) {
                string memory lastValue_ = set._values[lastIndex_];

                set._values[toDeleteIndex_] = lastValue_;
                set._indexes[lastValue_] = valueIndex_;
            }

            set._values.pop();

            delete set._indexes[value_];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice The function returns true if value in the set
     * @param set the set object
     * @param value_ the value to search in set
     * @return true if value is in the set, false otherwise
     */
    function contains(Set storage set, string memory value_) internal view returns (bool) {
        return set._indexes[value_] != 0;
    }

    /**
     * @notice The function returns length of set
     * @param set the set object
     * @return the the number of elements in the set
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     * @notice The function returns value from set by index
     * @param set the set object
     * @param index_ the index of slot in set
     * @return the value at index
     */
    function at(Set storage set, uint256 index_) internal view returns (string memory) {
        return set._values[index_];
    }

    /**
     * @notice The function that returns values the set stores, can be very expensive to call
     * @param set the set object
     * @return the memory array of values
     */
    function values(Set storage set) internal view returns (string[] memory) {
        return set._values;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice This library simplifies non-obvious type castings.
 *
 * Conversions from static to dynamic arrays, singleton arrays, and arrays of different types are supported.
 */
library TypeCaster {
    /**
     * @notice The function that casts the bytes32 array to the uint256 array
     * @param from_ the bytes32 array
     * @return array_ the uint256 array
     */
    function asUint256Array(
        bytes32[] memory from_
    ) internal pure returns (uint256[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the address array to the uint256 array
     */
    function asUint256Array(
        address[] memory from_
    ) internal pure returns (uint256[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the bytes32 array to the address array
     * @param from_ the bytes32 array
     * @return array_ the list of addresses
     */
    function asAddressArray(
        bytes32[] memory from_
    ) internal pure returns (address[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the uint256 array to the address array
     */
    function asAddressArray(
        uint256[] memory from_
    ) internal pure returns (address[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the uint256 array to the bytes32 array
     * @param from_ the bytes32 array
     * @return array_ the list of addresses
     */
    function asBytes32Array(
        uint256[] memory from_
    ) internal pure returns (bytes32[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the address array to the bytes32 array
     */
    function asBytes32Array(
        address[] memory from_
    ) internal pure returns (bytes32[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function to transform a uint256 element into an array
     * @param from_ the element
     * @return array_ the element as an array
     */
    function asSingletonArray(uint256 from_) internal pure returns (uint256[] memory array_) {
        array_ = new uint256[](1);
        array_[0] = from_;
    }

    /**
     * @notice The function to transform an address element into an array
     */
    function asSingletonArray(address from_) internal pure returns (address[] memory array_) {
        array_ = new address[](1);
        array_[0] = from_;
    }

    /**
     * @notice The function to transform a bool element into an array
     */
    function asSingletonArray(bool from_) internal pure returns (bool[] memory array_) {
        array_ = new bool[](1);
        array_[0] = from_;
    }

    /**
     * @notice The function to transform a string element into an array
     */
    function asSingletonArray(string memory from_) internal pure returns (string[] memory array_) {
        array_ = new string[](1);
        array_[0] = from_;
    }

    /**
     * @notice The function to transform a bytes32 element into an array
     */
    function asSingletonArray(bytes32 from_) internal pure returns (bytes32[] memory array_) {
        array_ = new bytes32[](1);
        array_[0] = from_;
    }

    /**
     * @notice The function to convert static uint256[1] array to dynamic
     * @param static_ the static array to convert
     * @return dynamic_ the converted dynamic array
     */
    function asDynamic(
        uint256[1] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    /**
     * @notice The function to convert static uint256[2] array to dynamic
     */
    function asDynamic(
        uint256[2] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    /**
     * @notice The function to convert static uint256[3] array to dynamic
     */
    function asDynamic(
        uint256[3] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    /**
     * @notice The function to convert static uint256[4] array to dynamic
     */
    function asDynamic(
        uint256[4] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    /**
     * @notice The function to convert static uint256[5] array to dynamic
     */
    function asDynamic(
        uint256[5] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    /**
     * @notice The function to convert static address[1] array to dynamic
     */
    function asDynamic(
        address[1] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    /**
     * @notice The function to convert static address[2] array to dynamic
     */
    function asDynamic(
        address[2] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    /**
     * @notice The function to convert static address[3] array to dynamic
     */
    function asDynamic(
        address[3] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    /**
     * @notice The function to convert static address[4] array to dynamic
     */
    function asDynamic(
        address[4] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    /**
     * @notice The function to convert static address[5] array to dynamic
     */
    function asDynamic(
        address[5] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    /**
     * @notice The function to convert static bool[1] array to dynamic
     */
    function asDynamic(bool[1] memory static_) internal pure returns (bool[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    /**
     * @notice The function to convert static bool[2] array to dynamic
     */
    function asDynamic(bool[2] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    /**
     * @notice The function to convert static bool[3] array to dynamic
     */
    function asDynamic(bool[3] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    /**
     * @notice The function to convert static bool[4] array to dynamic
     */
    function asDynamic(bool[4] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    /**
     * @notice The function to convert static bool[5] array to dynamic
     */
    function asDynamic(bool[5] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    /**
     * @notice The function to convert static string[1] array to dynamic
     */
    function asDynamic(string[1] memory static_) internal pure returns (string[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    /**
     * @notice The function to convert static string[2] array to dynamic
     */
    function asDynamic(string[2] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    /**
     * @notice The function to convert static string[3] array to dynamic
     */
    function asDynamic(string[3] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    /**
     * @notice The function to convert static string[4] array to dynamic
     */
    function asDynamic(string[4] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    /**
     * @notice The function to convert static string[5] array to dynamic
     */
    function asDynamic(string[5] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    /**
     * @notice The function to convert static bytes32[1] array to dynamic
     */
    function asDynamic(
        bytes32[1] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    /**
     * @notice The function to convert static bytes32[2] array to dynamic
     */
    function asDynamic(
        bytes32[2] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    /**
     * @notice The function to convert static bytes32[3] array to dynamic
     */
    function asDynamic(
        bytes32[3] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    /**
     * @notice The function to convert static bytes32[4] array to dynamic
     */
    function asDynamic(
        bytes32[4] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    /**
     * @notice The function to convert static bytes32[5] array to dynamic
     */
    function asDynamic(
        bytes32[5] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    /**
     * @notice private function to copy memory
     */
    function _copy(uint256 locationS_, uint256 locationD_, uint256 length_) private pure {
        assembly {
            for {
                let i := 0
            } lt(i, length_) {
                i := add(i, 1)
            } {
                locationD_ := add(locationD_, 0x20)

                mstore(locationD_, mload(locationS_))

                locationS_ := add(locationS_, 0x20)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {SetHelper} from "@solarity/solidity-lib/libs/arrays/SetHelper.sol";

import {GenesisUtils} from "@iden3/contracts/lib/GenesisUtils.sol";

import {IBaseVerifier} from "../../interfaces/iden3/verifiers/IBaseVerifier.sol";
import {IZKPQueriesStorage} from "../../interfaces/iden3/IZKPQueriesStorage.sol";
import {ILightweightState} from "../../interfaces/iden3/ILightweightState.sol";
import {IQueryValidator} from "../../interfaces/iden3/validators/IQueryValidator.sol";

/**
 * @dev This contract is a copy of the BaseVerifier contract from Rarimo [identity-contracts repository](https://github.com/rarimo/identity-contracts/tree/aeb929ccc3fa8ab508fd7576f9fa853a081e5010).
 */
abstract contract BaseVerifier is IBaseVerifier, OwnableUpgradeable, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;
    using SetHelper for EnumerableSet.UintSet;

    IZKPQueriesStorage public zkpQueriesStorage;

    // schema => allowed issuers
    mapping(uint256 => EnumerableSet.UintSet) internal _allowedIssuers;

    constructor() {
        _disableInitializers();
    }

    function __BaseVerifier_init(IZKPQueriesStorage zkpQueriesStorage_) internal onlyInitializing {
        __Ownable_init();

        _setZKPQueriesStorage(zkpQueriesStorage_);
    }

    function setZKPQueriesStorage(
        IZKPQueriesStorage newZKPQueriesStorage_
    ) external override onlyOwner {
        _setZKPQueriesStorage(newZKPQueriesStorage_);
    }

    function updateAllowedIssuers(
        uint256 schema_,
        uint256[] calldata issuerIds_,
        bool isAdding_
    ) external override onlyOwner {
        _updateAllowedIssuers(schema_, issuerIds_, isAdding_);
    }

    function getAllowedIssuers(uint256 schema_) public view override returns (uint256[] memory) {
        return _allowedIssuers[schema_].values();
    }

    function isAllowedIssuer(
        uint256 schema_,
        uint256 issuerId_
    ) public view virtual override returns (bool) {
        return _allowedIssuers[schema_].contains(issuerId_);
    }

    function _setZKPQueriesStorage(IZKPQueriesStorage newZKPQueriesStorage_) internal {
        zkpQueriesStorage = newZKPQueriesStorage_;
    }

    function _updateAllowedIssuers(
        uint256 schema_,
        uint256[] calldata issuerIds_,
        bool isAdding_
    ) internal {
        if (isAdding_) {
            _allowedIssuers[schema_].add(issuerIds_);
        } else {
            _allowedIssuers[schema_].remove(issuerIds_);
        }
    }

    function _transitState(TransitStateParams memory transitStateParams_) internal {
        ILightweightState lightweightState_ = zkpQueriesStorage.lightweightState();

        if (
            !lightweightState_.isIdentitiesStatesRootExists(
                transitStateParams_.newIdentitiesStatesRoot
            )
        ) {
            lightweightState_.signedTransitState(
                transitStateParams_.newIdentitiesStatesRoot,
                transitStateParams_.gistData,
                transitStateParams_.proof
            );
        }
    }

    function _checkAllowedIssuer(string memory queryId_, uint256 issuerId_) internal view virtual {
        require(
            isAllowedIssuer(zkpQueriesStorage.getStoredSchema(queryId_), issuerId_),
            "BaseVerifier: Issuer is not on the list of allowed issuers."
        );
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {SetHelper} from "@solarity/solidity-lib/libs/arrays/SetHelper.sol";
import {Paginator} from "@solarity/solidity-lib/libs/arrays/Paginator.sol";
import {Vector} from "@solarity/solidity-lib/libs/data-structures/memory/Vector.sol";

import {PoseidonUnit3L} from "@iden3/contracts/lib/Poseidon.sol";

import {IRegisterVerifier} from "../../interfaces/iden3/verifiers/IRegisterVerifier.sol";
import {IZKPQueriesStorage} from "../../interfaces/iden3/IZKPQueriesStorage.sol";
import {ILightweightState} from "../../interfaces/iden3/ILightweightState.sol";
import {IQueryMTPValidator} from "../../interfaces/iden3/validators/IQueryMTPValidator.sol";

import {BaseVerifier} from "./BaseVerifier.sol";

/**
 * @title RegisterVerifier contract
 */
contract RegisterVerifier is IRegisterVerifier, BaseVerifier {
    using Vector for Vector.UintVector;

    using SetHelper for EnumerableSet.UintSet;
    using Paginator for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.UintSet;

    string public constant REGISTER_PROOF_QUERY_ID = "REGISTER_PROOF";

    EnumerableSet.UintSet internal _issuingAuthorityWhitelist;
    EnumerableSet.UintSet internal _issuingAuthorityBlacklist;

    // registrationContract => documentNullifier => RegisterProofInfo
    mapping(address => mapping(uint256 => RegisterProofInfo)) private _registrationProofInfo;

    modifier onlyRegistrationContract(RegisterProofInfo memory registerProofInfo_) {
        _onlyRegistrationContract(registerProofInfo_);
        _;
    }

    function __RegisterVerifier_init(
        IZKPQueriesStorage zkpQueriesStorage_,
        uint256[] memory issuingAuthorityWhitelist_,
        uint256[] memory issuingAuthorityBlacklist_
    ) external initializer {
        __BaseVerifier_init(zkpQueriesStorage_);

        _issuingAuthorityWhitelist.add(issuingAuthorityWhitelist_);
        _issuingAuthorityBlacklist.add(issuingAuthorityBlacklist_);
    }

    /**
     * @inheritdoc IRegisterVerifier
     */
    function proveRegistration(
        ProveIdentityParams memory proveIdentityParams_,
        RegisterProofInfo memory registerProofInfo_
    ) external onlyRegistrationContract(registerProofInfo_) {
        _proveRegistration(proveIdentityParams_, registerProofInfo_);
    }

    /**
     * @inheritdoc IRegisterVerifier
     */
    function transitStateAndProveRegistration(
        ProveIdentityParams memory proveIdentityParams_,
        RegisterProofInfo memory registerProofInfo_,
        TransitStateParams memory transitStateParams_
    ) external onlyRegistrationContract(registerProofInfo_) {
        _transitState(transitStateParams_);
        _proveRegistration(proveIdentityParams_, registerProofInfo_);
    }

    /**
     * @inheritdoc IRegisterVerifier
     */
    function getRegisterProofInfo(
        address registrationContract_,
        uint256 documentNullifier_
    ) external view returns (RegisterProofInfo memory) {
        return _registrationProofInfo[registrationContract_][documentNullifier_];
    }

    /**
     * @inheritdoc IRegisterVerifier
     */
    function isIdentityRegistered(
        address registrationContract_,
        uint256 documentNullifier_
    ) public view returns (bool) {
        return
            _registrationProofInfo[registrationContract_][documentNullifier_]
                .registerProofParams
                .commitment != 0;
    }

    /**
     * @inheritdoc IRegisterVerifier
     */
    function isIssuingAuthorityWhitelisted(uint256 issuingAuthority_) public view returns (bool) {
        return _issuingAuthorityWhitelist.contains(issuingAuthority_);
    }

    /**
     * @inheritdoc IRegisterVerifier
     */
    function isIssuingAuthorityBlacklisted(uint256 issuingAuthority_) public view returns (bool) {
        return _issuingAuthorityBlacklist.contains(issuingAuthority_);
    }

    /**
     * @inheritdoc IRegisterVerifier
     */
    function countIssuingAuthorityWhitelist() external view returns (uint256) {
        return _issuingAuthorityWhitelist.length();
    }

    /**
     * @inheritdoc IRegisterVerifier
     */
    function countIssuingAuthorityBlacklist() external view returns (uint256) {
        return _issuingAuthorityBlacklist.length();
    }

    /**
     * @inheritdoc IRegisterVerifier
     */
    function listIssuingAuthorityWhitelist(
        uint256 offset_,
        uint256 limit_
    ) external view returns (uint256[] memory) {
        return _issuingAuthorityWhitelist.part(offset_, limit_);
    }

    /**
     * @inheritdoc IRegisterVerifier
     */
    function listIssuingAuthorityBlacklist(
        uint256 offset_,
        uint256 limit_
    ) external view returns (uint256[] memory) {
        return _issuingAuthorityBlacklist.part(offset_, limit_);
    }

    function _proveRegistration(
        ProveIdentityParams memory proveIdentityParams_,
        RegisterProofInfo memory registerProofInfo_
    ) internal {
        _verify(REGISTER_PROOF_QUERY_ID, proveIdentityParams_, registerProofInfo_);

        address registrationContract_ = registerProofInfo_.registrationContractAddress;
        uint256 documentNullifier_ = registerProofInfo_.registerProofParams.documentNullifier;

        require(
            !isIdentityRegistered(registrationContract_, documentNullifier_),
            "RegisterVerifier: Identity is already registered."
        );

        _registrationProofInfo[registrationContract_][documentNullifier_] = registerProofInfo_;

        emit RegisterAccepted(documentNullifier_, registerProofInfo_);
    }

    function _verify(
        string memory queryId_,
        ProveIdentityParams memory proveIdentityParams_,
        RegisterProofInfo memory registerProofInfo_
    ) internal view {
        require(
            zkpQueriesStorage.isQueryExists(queryId_),
            "RegisterVerifier: ZKP Query does not exist for passed query id."
        );

        IQueryMTPValidator queryValidator_ = IQueryMTPValidator(
            zkpQueriesStorage.getQueryValidator(queryId_)
        );

        IZKPQueriesStorage.CircuitQuery memory circuitQuery_ = zkpQueriesStorage
            .getStoredCircuitQuery(queryId_);

        uint256[] memory values_ = new uint256[](1);
        values_[0] = PoseidonUnit3L.poseidon(
            [
                1, // Is Adult should be always 1
                registerProofInfo_.registerProofParams.issuingAuthority,
                registerProofInfo_.registerProofParams.documentNullifier
            ]
        );

        circuitQuery_.values = values_;

        uint256 queryHash_ = zkpQueriesStorage.getQueryHash(circuitQuery_);

        _validateRegistrationFields(
            queryValidator_,
            proveIdentityParams_.inputs,
            registerProofInfo_
        );

        queryValidator_.verify(
            proveIdentityParams_.statesMerkleData,
            proveIdentityParams_.inputs,
            proveIdentityParams_.a,
            proveIdentityParams_.b,
            proveIdentityParams_.c,
            queryHash_
        );

        _checkAllowedIssuer(queryId_, proveIdentityParams_.statesMerkleData.issuerId);
    }

    /**
     * @dev The registration address is one of the inputs of the ZKP; therefore, we ensure that
     * the caller is registered with the exact ID, which, by design, is the same as the registration contract address.
     */
    function _onlyRegistrationContract(RegisterProofInfo memory registerProofInfo_) private view {
        require(
            msg.sender == registerProofInfo_.registrationContractAddress,
            "RegisterVerifier: the caller is not the voting contract."
        );
    }

    function _validateRegistrationFields(
        IQueryMTPValidator queryValidator_,
        uint256[] memory inputs_,
        RegisterProofInfo memory registerProofInfo_
    ) private view {
        uint256 issuingAuthority_ = registerProofInfo_.registerProofParams.issuingAuthority;

        require(
            !isIssuingAuthorityBlacklisted(issuingAuthority_),
            "RegisterVerifier: Issuing authority is blacklisted."
        );

        require(
            _issuingAuthorityWhitelist.length() == 0 ||
                isIssuingAuthorityWhitelisted(issuingAuthority_),
            "RegisterVerifier: Issuing authority is not whitelisted."
        );

        uint256 commitmentIndex_ = queryValidator_.getCommitmentIndex();
        uint256 registrationAddressIndex_ = queryValidator_.getRegistrationAddressIndex();

        require(
            bytes32(inputs_[commitmentIndex_]) ==
                registerProofInfo_.registerProofParams.commitment,
            "RegisterVerifier: commitment does not match the requested one."
        );

        require(inputs_[commitmentIndex_] != 0, "RegisterVerifier: commitment should not be zero");

        require(
            inputs_[registrationAddressIndex_] ==
                uint256(uint160(registerProofInfo_.registrationContractAddress)),
            "RegisterVerifier: registration address does not match the requested one."
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IState} from "@iden3/contracts/interfaces/IState.sol";

/**
 * @dev This contract is a copy of the ILightweightState contract from Rarimo [identity-contracts repository](https://github.com/rarimo/identity-contracts/tree/aeb929ccc3fa8ab508fd7576f9fa853a081e5010).
 */
interface ILightweightState {
    enum MethodId {
        None,
        AuthorizeUpgrade,
        ChangeSourceStateContract
    }

    struct GistRootData {
        uint256 root;
        uint256 createdAtTimestamp;
    }

    struct IdentitiesStatesRootData {
        bytes32 root;
        uint256 setTimestamp;
    }

    struct StatesMerkleData {
        uint256 issuerId;
        uint256 issuerState;
        uint256 createdAtTimestamp;
        bytes32[] merkleProof;
    }

    event SignedStateTransited(uint256 newGistRoot, bytes32 newIdentitesStatesRoot);

    function changeSourceStateContract(
        address newSourceStateContract_,
        bytes calldata signature_
    ) external;

    function changeSigner(bytes calldata newSignerPubKey_, bytes calldata signature_) external;

    function signedTransitState(
        bytes32 newIdentitiesStatesRoot_,
        GistRootData calldata gistData_,
        bytes calldata proof_
    ) external;

    function sourceStateContract() external view returns (address);

    function sourceChainName() external view returns (string memory);

    function identitiesStatesRoot() external view returns (bytes32);

    function isIdentitiesStatesRootExists(bytes32 root_) external view returns (bool);

    function getIdentitiesStatesRootData(
        bytes32 root_
    ) external view returns (IdentitiesStatesRootData memory);

    function getGISTRoot() external view returns (uint256);

    function getCurrentGISTRootInfo() external view returns (GistRootData memory);

    function geGISTRootData(uint256 root_) external view returns (GistRootData memory);

    function verifyStatesMerkleData(
        StatesMerkleData calldata statesMerkleData_
    ) external view returns (bool, bytes32);
}

// This contract is a copy of the IZKPQueriesStorage contract from Rarimo
// [identity-contracts repository](https://github.com/rarimo/identity-contracts/tree/aeb929ccc3fa8ab508fd7576f9fa853a081e5010).

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ILightweightState} from "./ILightweightState.sol";

/**
 * @title IZKPQueriesStorage
 * @notice The IZKPQueriesStorage interface represents a contract that is responsible for storing and managing zero-knowledge proof (ZKP) queries.
 * It provides functions to set, retrieve, and remove ZKP queries from the storage.
 */
interface IZKPQueriesStorage {
    struct CircuitQuery {
        uint256 schema;
        uint8 slotIndex;
        uint8 operator;
        uint256 claimPathKey;
        uint256 claimPathNotExists;
        uint256[] values;
    }

    /**
     * @notice Contains the query information, including the circuit query and query validator
     * @param circuitQuery The circuit query
     * @param queryValidator The query validator
     * @param circuitId The circuit ID
     */
    struct QueryInfo {
        CircuitQuery circuitQuery;
        address queryValidator;
        string circuitId;
    }

    /**
     * @notice Event emitted when a ZKP query is set
     * @param queryId The ID of the query
     * @param queryValidator The address of the query validator
     * @param newCircuitQuery The new circuit query
     */
    event ZKPQuerySet(
        string indexed queryId,
        address queryValidator,
        CircuitQuery newCircuitQuery
    );

    /**
     * @notice Event emitted when a ZKP query is removed
     * @param queryId The ID of the query
     */
    event ZKPQueryRemoved(string indexed queryId);

    /**
     * @notice Function that set a ZKP query with the provided query ID and query information
     * @param queryId_ The query ID
     * @param queryInfo_ The query information
     */
    function setZKPQuery(string memory queryId_, QueryInfo memory queryInfo_) external;

    /**
     * @notice Function that remove a ZKP query with the specified query ID
     * @param queryId_ The query ID
     */
    function removeZKPQuery(string memory queryId_) external;

    function lightweightState() external view returns (ILightweightState);

    /**
     * @notice Function to get the supported query IDs
     * @return The array of supported query IDs
     */
    function getSupportedQueryIDs() external view returns (string[] memory);

    /**
     * @notice Function to get the query information for a given query ID
     * @param queryId_ The query ID
     * @return The QueryInfo structure with query information
     */
    function getQueryInfo(string memory queryId_) external view returns (QueryInfo memory);

    /**
     * @notice Function to get the query validator for a given query ID
     * @param queryId_ The query ID
     * @return The query validator contract address
     */
    function getQueryValidator(string memory queryId_) external view returns (address);

    /**
     * @notice Function to get the stored circuit query for a given query ID
     * @param queryId_ The query ID
     * @return The stored CircuitQuery structure
     */
    function getStoredCircuitQuery(
        string memory queryId_
    ) external view returns (CircuitQuery memory);

    /**
     * @notice Function to get the stored query hash for a given query ID
     * @param queryId_ The query ID
     * @return The stored query hash
     */
    function getStoredQueryHash(string memory queryId_) external view returns (uint256);

    /**
     * @notice Function to get the stored schema for a given query ID
     * @param queryId_ The query ID
     * @return The stored schema id
     */
    function getStoredSchema(string memory queryId_) external view returns (uint256);

    /**
     * @notice Function to check if a query exists for the given query ID
     * @param queryId_ The query ID
     * @return A boolean indicating whether the query exists
     */
    function isQueryExists(string memory queryId_) external view returns (bool);

    /**
     * @notice Function to get the query hash for the provided circuit query
     * @param circuitQuery_ The circuit query
     * @return The query hash
     */
    function getQueryHash(CircuitQuery memory circuitQuery_) external view returns (uint256);

    /**
     * @notice Function to get the query hash for the raw values
     * @param schema_ The schema id
     * @param slotIndex_ The slot index
     * @param operator_ The query operator
     * @param claimPathKey_ The claim path key
     * @param claimPathNotExists_ The claim path not exists
     * @param values_ The values array
     * @return The query hash
     */
    function getQueryHashRaw(
        uint256 schema_,
        uint256 slotIndex_,
        uint256 operator_,
        uint256 claimPathKey_,
        uint256 claimPathNotExists_,
        uint256[] memory values_
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IQueryValidator} from "./IQueryValidator.sol";

interface IQueryMTPValidator is IQueryValidator {
    function getRegistrationAddressIndex() external pure returns (uint256 index);

    function getCommitmentIndex() external pure returns (uint256 index);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ILightweightState} from "../ILightweightState.sol";

/**
 * @dev This contract is a copy of the IQueryValidator contract from Rarimo [identity-contracts repository](https://github.com/rarimo/identity-contracts/tree/aeb929ccc3fa8ab508fd7576f9fa853a081e5010).
 */
interface IQueryValidator {
    struct ValidationParams {
        uint256 queryHash;
        uint256 gistRoot;
        uint256 issuerId;
        uint256 issuerClaimAuthState;
        uint256 issuerClaimNonRevState;
    }

    function setVerifier(address newVerifier_) external;

    function setIdentitesStatesUpdateTime(uint256 newIdentitesStatesUpdateTime_) external;

    function verify(
        ILightweightState.StatesMerkleData memory statesMerkleData_,
        uint256[] memory inputs_,
        uint256[2] memory a_,
        uint256[2][2] memory b_,
        uint256[2] memory c_,
        uint256 queryHash_
    ) external view returns (bool);

    function lightweightState() external view returns (ILightweightState);

    function verifier() external view returns (address);

    function identitesStatesUpdateTime() external view returns (uint256);

    function getCircuitId() external pure returns (string memory);

    function getUserIdIndex() external pure returns (uint256);

    function getChallengeInputIndex() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IZKPQueriesStorage} from "../IZKPQueriesStorage.sol";

import {ILightweightState} from "../ILightweightState.sol";

/**
 * @dev This contract is a copy of the IBaseVerifier contract from Rarimo [identity-contracts repository](https://github.com/rarimo/identity-contracts/tree/aeb929ccc3fa8ab508fd7576f9fa853a081e5010).
 */
interface IBaseVerifier {
    struct ProveIdentityParams {
        ILightweightState.StatesMerkleData statesMerkleData;
        uint256[] inputs;
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    struct TransitStateParams {
        bytes32 newIdentitiesStatesRoot;
        ILightweightState.GistRootData gistData;
        bytes proof;
    }

    function setZKPQueriesStorage(IZKPQueriesStorage newZKPQueriesStorage_) external;

    function updateAllowedIssuers(
        uint256 schema_,
        uint256[] memory issuerIds_,
        bool isAdding_
    ) external;

    function zkpQueriesStorage() external view returns (IZKPQueriesStorage);

    function getAllowedIssuers(uint256 schema_) external view returns (uint256[] memory);

    function isAllowedIssuer(uint256 schema_, uint256 issuerId_) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IBaseVerifier} from "./IBaseVerifier.sol";
import {ILightweightState} from "../ILightweightState.sol";

/**
 * @title IRegisterVerifier
 * @notice Interface for the RegisterVerifier contract.
 */
interface IRegisterVerifier is IBaseVerifier {
    /**
     * @notice Struct to hold parameters for registration proof.
     * @param issuingAuthority The identifier for the issuing authority.
     * @param documentNullifier The unique nullifier for the document to prevent double registration.
     * @param commitment A commitment hash representing the registered identity.
     */
    struct RegisterProofParams {
        uint256 issuingAuthority;
        uint256 documentNullifier;
        bytes32 commitment;
    }

    /**
     * @notice Struct to encapsulate registration proof parameters along with the voting address.
     * @param registerProofParams The registration proof parameters.
     * @param registrationContractAddress The address of the registration contract.
     */
    struct RegisterProofInfo {
        RegisterProofParams registerProofParams;
        address registrationContractAddress;
    }

    /**
     * @notice Emitted when a registration is accepted.
     * @param documentNullifier The unique nullifier for the document.
     * @param registerProofInfo The information regarding the registration proof.
     */
    event RegisterAccepted(uint256 documentNullifier, RegisterProofInfo registerProofInfo);

    /**
     * @notice Proves registration with given parameters.
     * @param proveIdentityParams_ Parameters required for proving identity.
     * @param registerProofInfo_ The registration proof information.
     */
    function proveRegistration(
        ProveIdentityParams memory proveIdentityParams_,
        RegisterProofInfo memory registerProofInfo_
    ) external;

    /**
     * @notice Transitions state and proves registration with given parameters.
     * @param proveIdentityParams_ Parameters required for proving identity.
     * @param registerProofInfo_ The registration proof information.
     * @param transitStateParams_ Parameters required for state transition.
     */
    function transitStateAndProveRegistration(
        ProveIdentityParams memory proveIdentityParams_,
        RegisterProofInfo memory registerProofInfo_,
        TransitStateParams memory transitStateParams_
    ) external;

    /**
     * @notice Retrieves registration proof information for a given document nullifier.
     * @param registrationContract_ The address of the registration contract.
     * @param documentNullifier_ The unique nullifier for the document.
     * @return RegisterProofInfo The registration proof information.
     */
    function getRegisterProofInfo(
        address registrationContract_,
        uint256 documentNullifier_
    ) external view returns (RegisterProofInfo memory);

    /**
     * @notice Checks if an identity is registered.
     * @param registrationContract_ The address of the registration contract.
     * @param documentNullifier_ The unique nullifier for the document.
     * @return bool True if the identity is registered, false otherwise.
     */
    function isIdentityRegistered(
        address registrationContract_,
        uint256 documentNullifier_
    ) external view returns (bool);

    /**
     * @notice Checks if an issuing authority is whitelisted.
     * @param issuingAuthority_ The identifier for the issuing authority.
     * @return bool True if the issuing authority is whitelisted, false otherwise.
     */
    function isIssuingAuthorityWhitelisted(uint256 issuingAuthority_) external view returns (bool);

    /**
     * @notice Checks if an issuing authority is blacklisted.
     * @param issuingAuthority_ The identifier for the issuing authority.
     * @return bool True if the issuing authority is blacklisted, false otherwise.
     */
    function isIssuingAuthorityBlacklisted(uint256 issuingAuthority_) external view returns (bool);

    /**
     * @notice Returns the number of issuing authorities in the whitelist.
     */
    function countIssuingAuthorityWhitelist() external view returns (uint256);

    /**
     * @notice Returns the number of issuing authorities in the blacklist.
     */
    function countIssuingAuthorityBlacklist() external view returns (uint256);

    /**
     * @notice Returns a list of issuing authorities in the whitelist.
     * @param offset_ The offset from which to start fetching the list.
     * @param limit_ The maximum number of items to fetch.
     * @return uint256[] The list of issuing authorities in the whitelist.
     */
    function listIssuingAuthorityWhitelist(
        uint256 offset_,
        uint256 limit_
    ) external view returns (uint256[] memory);

    /**
     * @notice Returns a list of issuing authorities in the blacklist.
     * @param offset_ The offset from which to start fetching the list.
     * @param limit_ The maximum number of items to fetch.
     * @return uint256[] The list of issuing authorities in the blacklist.
     */
    function listIssuingAuthorityBlacklist(
        uint256 offset_,
        uint256 limit_
    ) external view returns (uint256[] memory);
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

    function equal_nonAligned(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
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

                let endMinusWord := add(_preBytes, length)
                let mc := add(_preBytes, 0x20)
                let cc := add(_postBytes, 0x20)

                for {
                // the next line is the loop condition:
                // while(uint256(mc < endWord) + cb == 2)
                } eq(add(lt(mc, endMinusWord), cb), 2) {
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

                // Only if still successful
                // For <1 word tail bytes
                if gt(success, 0) {
                    // Get the remainder of length/32
                    // length % 32 = AND(length, 32 - 1)
                    let numTailBytes := and(length, 0x1f)
                    let mcRem := mload(mc)
                    let ccRem := mload(cc)
                    for {
                        let i := 0
                    // the next line is the loop condition:
                    // while(uint256(i < numTailBytes) + cb == 2)
                    } eq(add(lt(i, numTailBytes), cb), 2) {
                        i := add(i, 1)
                    } {
                        if iszero(eq(byte(i, mcRem), byte(i, ccRem))) {
                            // unsuccess:
                            success := 0
                            cb := 0
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