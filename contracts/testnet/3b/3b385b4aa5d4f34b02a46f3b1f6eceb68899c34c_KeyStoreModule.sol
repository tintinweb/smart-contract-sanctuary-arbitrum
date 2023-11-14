pragma solidity ^0.8.20;

import "../BaseModule.sol";
import "./IKeyStoreModule.sol";
import "./BlockVerifier.sol";
import "./MerklePatriciaVerifier.sol";
import "../../libraries/KeyStoreSlotLib.sol";
import "../../keystore/interfaces/IKeyStoreProof.sol";

/**
 * @title KeyStoreModule
 * @notice module for syncing a L1 keystore
 */
contract KeyStoreModule is IKeyStoreModule, BaseModule {
    bytes4 private constant _FUNC_RESET_OWNER = bytes4(keccak256("resetOwner(bytes32)"));
    bytes4 private constant _FUNC_RESET_OWNERS = bytes4(keccak256("resetOwners(bytes32[])"));

    IKeyStoreProof public immutable keyStoreProof;

    mapping(address => bytes32) public l1Slot;
    mapping(address => bytes32) public lastKeyStoreSyncSignKey;

    mapping(address => bool) walletInited;
    uint128 private __seed = 0;
    /**
     * @notice Internal function to increment and return seed.
     * @return New incremented seed value.
     */

    function _newSeed() private returns (uint128) {
        __seed++;
        return __seed;
    }
    /**
     * @param _keyStoreProof Address of the KeyStoreProof contract.
     */

    constructor(address _keyStoreProof) {
        keyStoreProof = IKeyStoreProof(_keyStoreProof);
    }
    /**
     * @notice Synchronize L1 keystore with the wallet.
     * @param wallet Address of the wallet.
     */

    function syncL1Keystore(address wallet) external override {
        bytes32 slotInfo = l1Slot[wallet];
        require(slotInfo != bytes32(0), "wallet slot not set");
        bytes32 keystoreSignKey = keyStoreProof.keystoreBySlot(slotInfo);
        require(keystoreSignKey != bytes32(0), "keystore proof not sync");
        bytes32 lastSyncKeyStore = lastKeyStoreSyncSignKey[wallet];
        if (lastSyncKeyStore != bytes32(0) && lastSyncKeyStore == keystoreSignKey) {
            revert("keystore already synced");
        }
        ISoulWallet soulwallet = ISoulWallet(payable(wallet));
        bytes memory rawOwners = keyStoreProof.rawOwnersBySlot(slotInfo);
        bytes32[] memory owners = abi.decode(rawOwners, (bytes32[]));
        soulwallet.resetOwners(owners);
        lastKeyStoreSyncSignKey[wallet] = keystoreSignKey;
        emit KeyStoreSyncd(wallet, keystoreSignKey);
    }
    /**
     * @notice Retrieve the list of required functions for the keystore module.
     * @return An array of function selectors.
     */

    function requiredFunctions() external pure override returns (bytes4[] memory) {
        bytes4[] memory functions = new bytes4[](2);
        functions[0] = _FUNC_RESET_OWNER;
        functions[1] = _FUNC_RESET_OWNERS;
        return functions;
    }
    /**
     * @notice Check if a wallet is initialized.
     * @param wallet Address of the wallet.
     * @return True if the wallet is initialized, false otherwise.
     */

    function inited(address wallet) internal view virtual override returns (bool) {
        return walletInited[wallet];
    }
    /**
     * @dev when wallet add keystore module, it will call this function to set the l1keystore slot mapping
     * @notice Internal function to initialize keystore for a wallet.
     * @param _data Initialization data containing initial key hash, guardian hash, and guardian safe period.
     */

    function _init(bytes calldata _data) internal virtual override {
        address _sender = sender();
        (bytes32 initialKeyHash, bytes32 initialGuardianHash, uint64 guardianSafePeriod) =
            abi.decode(_data, (bytes32, bytes32, uint64));
        bytes32 walletKeyStoreSlot = KeyStoreSlotLib.getSlot(initialKeyHash, initialGuardianHash, guardianSafePeriod);
        require(walletKeyStoreSlot != bytes32(0), "wallet slot needs to set");
        l1Slot[_sender] = walletKeyStoreSlot;

        bytes32 keystoreSignKey = keyStoreProof.keystoreBySlot(walletKeyStoreSlot);
        // if keystore already sync, change to keystore signer
        if (keystoreSignKey != bytes32(0)) {
            bytes memory rawOwners = keyStoreProof.rawOwnersBySlot(walletKeyStoreSlot);
            bytes32[] memory owners = abi.decode(rawOwners, (bytes32[]));
            ISoulWallet soulwallet = ISoulWallet(payable(_sender));
            // sync keystore signing key
            soulwallet.resetOwners(owners);
            lastKeyStoreSyncSignKey[_sender] = keystoreSignKey;
            emit KeyStoreSyncd(_sender, keystoreSignKey);
        }
        walletInited[_sender] = true;
        emit KeyStoreInited(_sender, initialKeyHash, initialGuardianHash, guardianSafePeriod);
    }
    /**
     * @notice Internal function to deinitialize keystore for a wallet.
     */

    function _deInit() internal virtual override {
        address _sender = sender();
        delete l1Slot[_sender];
        delete lastKeyStoreSyncSignKey[_sender];
        walletInited[_sender] = false;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../interfaces/IModule.sol";
import "../interfaces/ISoulWallet.sol";
import "../interfaces/IModuleManager.sol";

/**
 * @title BaseModule
 * @notice An abstract base contract that provides a foundation for other modules.
 * It ensures the initialization, de-initialization, and proper authorization of modules.
 */
abstract contract BaseModule is IModule {
    event ModuleInit(address indexed wallet);
    event ModuleDeInit(address indexed wallet);
    /**
     * @notice Checks if the module is initialized for a particular wallet.
     * @param wallet Address of the wallet.
     * @return True if the module is initialized, false otherwise.
     */

    function inited(address wallet) internal view virtual returns (bool);
    /**
     * @notice Initialization logic for the module.
     * @param data Initialization data for the module.
     */
    function _init(bytes calldata data) internal virtual;
    /**
     * @notice De-initialization logic for the module.
     */
    function _deInit() internal virtual;
    /**
     * @notice Helper function to get the sender of the transaction.
     * @return Address of the transaction sender.
     */

    function sender() internal view returns (address) {
        return msg.sender;
    }
    /**
     * @notice Initializes the module for a wallet.
     * @param data Initialization data for the module.
     */

    function walletInit(bytes calldata data) external {
        address _sender = sender();
        if (!inited(_sender)) {
            if (!ISoulWallet(_sender).isAuthorizedModule(address(this))) {
                revert("not authorized module");
            }
            _init(data);
            emit ModuleInit(_sender);
        }
    }
    /**
     * @notice De-initializes the module for a wallet.
     */

    function walletDeInit() external {
        address _sender = sender();
        if (inited(_sender)) {
            if (ISoulWallet(_sender).isAuthorizedModule(address(this))) {
                revert("authorized module");
            }
            _deInit();
            emit ModuleDeInit(_sender);
        }
    }
    /**
     * @notice Verifies if the module supports a specific interface.
     * @param interfaceId ID of the interface to be checked.
     * @return True if the module supports the given interface, false otherwise.
     */

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IModule).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title IKeyStoreModule
 * @notice Interface for the KeyStoreModule, responsible for managing and syncing keystores
 */
interface IKeyStoreModule {
    /**
     * @notice Emitted when the keystore for a specific wallet has been synchronized
     * @param _wallet The address of the wallet for which the keystore has been synced
     * @param _newOwners The new owners of the keystore represented as a bytes32 value
     */
    event KeyStoreSyncd(address indexed _wallet, bytes32 indexed _newOwners);
    /**
     * @notice Emitted when a keystore is initialized
     * @param _wallet The address of the wallet for which the keystore has been initialized
     * @param _initialKey The initial key set for the keystore represented as a bytes32 value
     * @param initialGuardianHash The initial hash value for the guardians
     * @param guardianSafePeriod The safe period for guardians
     */
    event KeyStoreInited(
        address indexed _wallet, bytes32 _initialKey, bytes32 initialGuardianHash, uint64 guardianSafePeriod
    );
    /**
     * @dev Synchronizes the keystore for a specific wallet
     * @param wallet The address of the wallet to be synchronized
     */

    function syncL1Keystore(address wallet) external;
}

// SPDX-License-Identifier: GPL-3.0
/*
This code is based on https://github.com/Keydonix/uniswap-oracle/blob/master/contracts/source/BlockVerifier.sol
Credit to the original authors and contributors.
*/

pragma solidity ^0.8.20;

library BlockVerifier {
    function extractStateRootAndTimestamp(bytes memory rlpBytes, bytes32 blockHash)
        internal
        pure
        returns (bytes32 stateRoot, uint256 blockTimestamp, uint256 blockNumber)
    {
        assembly {
            function revertWithReason(message, length) {
                // 4-byte function selector of `Error(string)` which is `0x08c379a0`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                // Offset of string return value
                mstore(4, 0x20)
                // Length of string return value (the revert reason)
                mstore(0x24, length)
                // actuall revert message
                mstore(0x44, message)
                revert(0, add(0x44, length))
            }

            function readDynamic(prefixPointer) -> dataPointer, dataLength {
                let value := byte(0, mload(prefixPointer))
                switch lt(value, 0x80)
                case 1 {
                    dataPointer := prefixPointer
                    dataLength := 1
                }
                case 0 {
                    dataPointer := add(prefixPointer, 1)
                    dataLength := sub(value, 0x80)
                }
            }

            // get the length of the data
            let rlpLength := mload(rlpBytes)
            // move pointer forward, ahead of length
            rlpBytes := add(rlpBytes, 0x20)

            // we know the length of the block will be between 483 bytes and 709 bytes, which means it will have 2 length bytes after the prefix byte, so we can skip 3 bytes in
            // CONSIDER: we could save a trivial amount of gas by compressing most of this into a single add instruction
            let parentHashPrefixPointer := add(rlpBytes, 3)
            let parentHashPointer := add(parentHashPrefixPointer, 1)
            let uncleHashPrefixPointer := add(parentHashPointer, 32)
            let uncleHashPointer := add(uncleHashPrefixPointer, 1)
            let minerAddressPrefixPointer := add(uncleHashPointer, 32)
            let minerAddressPointer := add(minerAddressPrefixPointer, 1)
            let stateRootPrefixPointer := add(minerAddressPointer, 20)
            let stateRootPointer := add(stateRootPrefixPointer, 1)
            let transactionRootPrefixPointer := add(stateRootPointer, 32)
            let transactionRootPointer := add(transactionRootPrefixPointer, 1)
            let receiptsRootPrefixPointer := add(transactionRootPointer, 32)
            let receiptsRootPointer := add(receiptsRootPrefixPointer, 1)
            let logsBloomPrefixPointer := add(receiptsRootPointer, 32)
            let logsBloomPointer := add(logsBloomPrefixPointer, 3)
            let difficultyPrefixPointer := add(logsBloomPointer, 256)
            let difficultyPointer, difficultyLength := readDynamic(difficultyPrefixPointer)
            let blockNumberPrefixPointer := add(difficultyPointer, difficultyLength)
            let blockNumberPointer, blockNumberLength := readDynamic(blockNumberPrefixPointer)
            let gasLimitPrefixPointer := add(blockNumberPointer, blockNumberLength)
            let gasLimitPointer, gasLimitLength := readDynamic(gasLimitPrefixPointer)
            let gasUsedPrefixPointer := add(gasLimitPointer, gasLimitLength)
            let gasUsedPointer, gasUsedLength := readDynamic(gasUsedPrefixPointer)
            let timestampPrefixPointer := add(gasUsedPointer, gasUsedLength)
            let timestampPointer, timestampLength := readDynamic(timestampPrefixPointer)

            blockNumber := shr(sub(256, mul(blockNumberLength, 8)), mload(blockNumberPointer))
            let rlpHash := keccak256(rlpBytes, rlpLength)
            if iszero(eq(blockHash, rlpHash)) { revertWithReason("blockHash != rlpHash", 20) }

            stateRoot := mload(stateRootPointer)
            blockTimestamp := shr(sub(256, mul(timestampLength, 8)), mload(timestampPointer))
        }
    }
}

pragma solidity ^0.8.20;

import {Rlp} from "./Rlp.sol";
/*
This code is based on https://github.com/Keydonix/uniswap-oracle/blob/master/contracts/source/MerklePatriciaVerifier.sol
Credit to the original authors and contributors.
*/

library MerklePatriciaVerifier {
    /*
    * @dev Extracts the value from a merkle proof
    * @param expectedRoot The expected hash of the root node of the trie.
    * @param path The path in the trie leading to value.
    * @param proofNodesRlp RLP encoded array of proof nodes.
    * @return The value proven to exist in the merkle patricia tree whose root is `expectedRoot` at the path `path`
    *
    * WARNING: Does not currently support validation of unset/0 values!
    */
    function getValueFromProof(bytes32 expectedRoot, bytes32 path, bytes memory proofNodesRlp)
        internal
        pure
        returns (bytes memory)
    {
        Rlp.Item memory rlpParentNodes = Rlp.toItem(proofNodesRlp);
        Rlp.Item[] memory parentNodes = Rlp.toList(rlpParentNodes);

        bytes memory currentNode;
        Rlp.Item[] memory currentNodeList;

        bytes32 nodeKey = expectedRoot;
        uint256 pathPtr = 0;

        // our input is a 32-byte path, but we have to prepend a single 0 byte to that and pass it along as a 33 byte memory array since that is what getNibbleArray wants
        bytes memory nibblePath = new bytes(33);
        assembly {
            mstore(add(nibblePath, 33), path)
        }
        nibblePath = _getNibbleArray(nibblePath);

        require(path.length != 0, "empty path provided");

        currentNode = Rlp.toBytes(parentNodes[0]);

        for (uint256 i = 0; i < parentNodes.length; i++) {
            require(pathPtr <= nibblePath.length, "Path overflow");

            currentNode = Rlp.toBytes(parentNodes[i]);
            require(nodeKey == keccak256(currentNode), "node doesn't match key");
            currentNodeList = Rlp.toList(parentNodes[i]);

            if (currentNodeList.length == 17) {
                if (pathPtr == nibblePath.length) {
                    return Rlp.toData(currentNodeList[16]);
                }

                uint8 nextPathNibble = uint8(nibblePath[pathPtr]);
                require(nextPathNibble <= 16, "nibble too long");
                nodeKey = Rlp.toBytes32(currentNodeList[nextPathNibble]);
                pathPtr += 1;
            } else if (currentNodeList.length == 2) {
                uint256 nibblesToTravers = _nibblesToTraverse(Rlp.toData(currentNodeList[0]), nibblePath, pathPtr);
                pathPtr += nibblesToTravers;
                // leaf node
                if (pathPtr == nibblePath.length) {
                    return Rlp.toData(currentNodeList[1]);
                }
                //extension node
                require(nibblesToTravers != 0, "invalid extension node");

                nodeKey = Rlp.toBytes32(currentNodeList[1]);
            } else {
                revert("unexpected length array");
            }
        }
        revert("not enough proof nodes");
    }

    function _nibblesToTraverse(bytes memory encodedPartialPath, bytes memory path, uint256 pathPtr)
        private
        pure
        returns (uint256)
    {
        uint256 len;
        // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
        // and slicedPath have elements that are each one hex character (1 nibble)
        bytes memory partialPath = _getNibbleArray(encodedPartialPath);
        bytes memory slicedPath = new bytes(partialPath.length);

        // pathPtr counts nibbles in path
        // partialPath.length is a number of nibbles
        for (uint256 i = pathPtr; i < pathPtr + partialPath.length; i++) {
            bytes1 pathNibble = path[i];
            slicedPath[i - pathPtr] = pathNibble;
        }

        if (keccak256(partialPath) == keccak256(slicedPath)) {
            len = partialPath.length;
        } else {
            len = 0;
        }
        return len;
    }

    // bytes byteArray must be hp encoded
    function _getNibbleArray(bytes memory byteArray) private pure returns (bytes memory) {
        bytes memory nibbleArray;
        if (byteArray.length == 0) return nibbleArray;

        uint8 offset;
        uint8 hpNibble = uint8(_getNthNibbleOfBytes(0, byteArray));
        if (hpNibble == 1 || hpNibble == 3) {
            nibbleArray = new bytes(byteArray.length*2-1);
            bytes1 oddNibble = _getNthNibbleOfBytes(1, byteArray);
            nibbleArray[0] = oddNibble;
            offset = 1;
        } else {
            nibbleArray = new bytes(byteArray.length*2-2);
            offset = 0;
        }

        for (uint256 i = offset; i < nibbleArray.length; i++) {
            nibbleArray[i] = _getNthNibbleOfBytes(i - offset + 2, byteArray);
        }
        return nibbleArray;
    }

    function _getNthNibbleOfBytes(uint256 n, bytes memory str) private pure returns (bytes1) {
        return bytes1(n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title KeyStoreSlotLib
 * @notice A library to compute a keystore slot based on input parameters
 */
library KeyStoreSlotLib {
    /**
     * @notice Calculates a slot using the initial key hash, initial guardian hash, and guardian safe period
     * @param initialKeyHash The initial key hash used for calculating the slot
     * @param initialGuardianHash The initial guardian hash used for calculating the slot
     * @param guardianSafePeriod The guardian safe period used for calculating the slot
     * @return slot The resulting keystore slot derived from the input parameters
     */
    function getSlot(bytes32 initialKeyHash, bytes32 initialGuardianHash, uint256 guardianSafePeriod)
        internal
        pure
        returns (bytes32 slot)
    {
        return keccak256(abi.encode(initialKeyHash, initialGuardianHash, guardianSafePeriod));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title Key Store Proof Interface
 * @dev This interface provides methods to retrieve the keystore signing key hash and raw owners based on a slot.
 */
interface IKeyStoreProof {
    /**
     * @dev Returns the signing key hash associated with a given L1 slot.
     * @param l1Slot The L1 slot
     * @return signingKeyHash The hash of the signing key associated with the L1 slot
     */
    function keystoreBySlot(bytes32 l1Slot) external view returns (bytes32 signingKeyHash);

    /**
     * @dev Returns the raw owners associated with a given L1 slot.
     * @param l1Slot The L1 slot
     * @return owners The raw owner data associated with the L1 slot
     */
    function rawOwnersBySlot(bytes32 l1Slot) external view returns (bytes memory owners);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./IPluggable.sol";

/**
 * @title Module Interface
 * @dev This interface defines the funcations that a module needed access in the smart contract wallet
 * Modules are key components that can be plugged into the main contract to enhance its functionalities
 * For security reasons, a module can only call functions in the smart contract that it has explicitly
 * listed via the `requiredFunctions` method
 */
interface IModule is IPluggable {
    /**
     * @notice Provides a list of function selectors that the module is allowed to call
     * within the smart contract. When a module is added to the smart contract, it's restricted
     * to only call these functions. This ensures that modules have explicit and limited permissions,
     * enhancing the security of the smart contract (e.g., a "Daily Limit" module shouldn't be able to
     * change the owner)
     *
     * @return An array of function selectors that this module is permitted to call
     */
    function requiredFunctions() external pure returns (bytes4[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./IExecutionManager.sol";
import "./IModuleManager.sol";
import "./IOwnerManager.sol";
import "./IPluginManager.sol";
import "./IFallbackManager.sol";
import "@account-abstraction/contracts/interfaces/IAccount.sol";
import "./IUpgradable.sol";

/**
 * @title SoulWallet Interface
 * @dev This interface aggregates multiple sub-interfaces to represent the functionalities of the SoulWallet
 * It encompasses account management, execution management, module management, owner management, plugin management,
 * fallback management, and upgradeability
 */
interface ISoulWallet is
    IAccount,
    IExecutionManager,
    IModuleManager,
    IOwnerManager,
    IPluginManager,
    IFallbackManager,
    IUpgradable
{}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./IModule.sol";

/**
 * @title Module Manager Interface
 * @dev This interface defines the management functionalities for handling modules
 * within the system. Modules are components that can be added to or removed from the
 * smart contract to extend its functionalities. The manager ensures that only authorized
 * modules can execute certain functionalities
 */
interface IModuleManager {
    /**
     * @notice Emitted when a new module is successfully added
     * @param module The address of the newly added module
     */
    event ModuleAdded(address indexed module);
    /**
     * @notice Emitted when a module is successfully removed
     * @param module The address of the removed module
     */
    event ModuleRemoved(address indexed module);
    /**
     * @notice Emitted when there's an error while removing a module
     * @param module The address of the module that was attempted to be removed
     */
    event ModuleRemovedWithError(address indexed module);

    /**
     * @notice Adds a new module to the system
     * @param moduleAndData The module to be added and its associated initialization data
     */
    function addModule(bytes calldata moduleAndData) external;
    /**
     * @notice Removes a module from the system
     * @param  module The address of the module to be removed
     */
    function removeModule(address module) external;

    /**
     * @notice Checks if a module is authorized within the system
     * @param module The address of the module to check
     * @return True if the module is authorized, false otherwise
     */
    function isAuthorizedModule(address module) external returns (bool);
    /**
     * @notice Provides a list of all added modules and their respective authorized function selectors
     * @return modules An array of the addresses of all added modules
     * @return selectors A 2D array where each inner array represents the function selectors
     * that the corresponding module in the 'modules' array is allowed to call
     */
    function listModule() external view returns (address[] memory modules, bytes4[][] memory selectors);
    /**
     * @notice Allows a module to execute a function within the system. This ensures that the
     * module can only call functions it is permitted to, based on its declared `requiredFunctions`
     * @param dest The address of the destination contract where the function will be executed
     * @param value The amount of ether (in wei) to be sent with the function call
     * @param func The function data to be executed
     */
    function executeFromModule(address dest, uint256 value, bytes calldata func) external;
}

pragma solidity ^0.8.20;

// source: https://github.com/Keydonix/uniswap-oracle/blob/master/contracts/source/Rlp.sol
library Rlp {
    uint256 constant DATA_SHORT_START = 0x80;
    uint256 constant DATA_LONG_START = 0xB8;
    uint256 constant LIST_SHORT_START = 0xC0;
    uint256 constant LIST_LONG_START = 0xF8;

    uint256 constant DATA_LONG_OFFSET = 0xB7;
    uint256 constant LIST_LONG_OFFSET = 0xF7;

    struct Item {
        uint256 _unsafe_memPtr; // Pointer to the RLP-encoded bytes.
        uint256 _unsafe_length; // Number of bytes. This is the full length of the string.
    }

    struct Iterator {
        Item _unsafe_item; // Item that's being iterated over.
        uint256 _unsafe_nextPtr; // Position of the next item in the list.
    }

    /* Iterator */

    function next(Iterator memory self) internal pure returns (Item memory subItem) {
        require(hasNext(self), "Rlp.sol:Rlp:next:1");
        uint256 ptr = self._unsafe_nextPtr;
        uint256 itemLength = _itemLength(ptr);
        subItem._unsafe_memPtr = ptr;
        subItem._unsafe_length = itemLength;
        self._unsafe_nextPtr = ptr + itemLength;
    }

    function next(Iterator memory self, bool strict) internal pure returns (Item memory subItem) {
        subItem = next(self);
        require(!strict || _validate(subItem), "Rlp.sol:Rlp:next:2");
    }

    function hasNext(Iterator memory self) internal pure returns (bool) {
        Rlp.Item memory item = self._unsafe_item;
        return self._unsafe_nextPtr < item._unsafe_memPtr + item._unsafe_length;
    }

    /* Item */

    /// @dev Creates an Item from an array of RLP encoded bytes.
    /// @param self The RLP encoded bytes.
    /// @return An Item
    function toItem(bytes memory self) internal pure returns (Item memory) {
        uint256 len = self.length;
        if (len == 0) {
            return Item(0, 0);
        }
        uint256 memPtr;
        assembly {
            memPtr := add(self, 0x20)
        }
        return Item(memPtr, len);
    }

    /// @dev Creates an Item from an array of RLP encoded bytes.
    /// @param self The RLP encoded bytes.
    /// @param strict Will throw if the data is not RLP encoded.
    /// @return An Item
    function toItem(bytes memory self, bool strict) internal pure returns (Item memory) {
        Rlp.Item memory item = toItem(self);
        if (strict) {
            uint256 len = self.length;
            require(_payloadOffset(item) <= len, "Rlp.sol:Rlp:toItem4");
            require(_itemLength(item._unsafe_memPtr) == len, "Rlp.sol:Rlp:toItem:5");
            require(_validate(item), "Rlp.sol:Rlp:toItem:6");
        }
        return item;
    }

    /// @dev Check if the Item is null.
    /// @param self The Item.
    /// @return 'true' if the item is null.
    function isNull(Item memory self) internal pure returns (bool) {
        return self._unsafe_length == 0;
    }

    /// @dev Check if the Item is a list.
    /// @param self The Item.
    /// @return 'true' if the item is a list.
    function isList(Item memory self) internal pure returns (bool) {
        if (self._unsafe_length == 0) {
            return false;
        }
        uint256 memPtr = self._unsafe_memPtr;
        bool result;
        assembly {
            result := iszero(lt(byte(0, mload(memPtr)), 0xC0))
        }
        return result;
    }

    /// @dev Check if the Item is data.
    /// @param self The Item.
    /// @return 'true' if the item is data.
    function isData(Item memory self) internal pure returns (bool) {
        if (self._unsafe_length == 0) {
            return false;
        }
        uint256 memPtr = self._unsafe_memPtr;
        bool result;
        assembly {
            result := lt(byte(0, mload(memPtr)), 0xC0)
        }
        return result;
    }

    /// @dev Check if the Item is empty (string or list).
    /// @param self The Item.
    /// @return result 'true' if the item is null.
    function isEmpty(Item memory self) internal pure returns (bool) {
        if (isNull(self)) {
            return false;
        }
        uint256 b0;
        uint256 memPtr = self._unsafe_memPtr;
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        return (b0 == DATA_SHORT_START || b0 == LIST_SHORT_START);
    }

    /// @dev Get the number of items in an RLP encoded list.
    /// @param self The Item.
    /// @return The number of items.
    function items(Item memory self) internal pure returns (uint256) {
        if (!isList(self)) {
            return 0;
        }
        uint256 b0;
        uint256 memPtr = self._unsafe_memPtr;
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        uint256 pos = memPtr + _payloadOffset(self);
        uint256 last = memPtr + self._unsafe_length - 1;
        uint256 itms;
        while (pos <= last) {
            pos += _itemLength(pos);
            itms++;
        }
        return itms;
    }

    /// @dev Create an iterator.
    /// @param self The Item.
    /// @return An 'Iterator' over the item.
    function iterator(Item memory self) internal pure returns (Iterator memory) {
        require(isList(self), "Rlp.sol:Rlp:iterator:1");
        uint256 ptr = self._unsafe_memPtr + _payloadOffset(self);
        Iterator memory it;
        it._unsafe_item = self;
        it._unsafe_nextPtr = ptr;
        return it;
    }

    /// @dev Return the RLP encoded bytes.
    /// @param self The Item.
    /// @return The bytes.
    function toBytes(Item memory self) internal pure returns (bytes memory) {
        uint256 len = self._unsafe_length;
        require(len != 0, "Rlp.sol:Rlp:toBytes:2");
        bytes memory bts;
        bts = new bytes(len);
        _copyToBytes(self._unsafe_memPtr, bts, len);
        return bts;
    }

    /// @dev Decode an Item into bytes. This will not work if the
    /// Item is a list.
    /// @param self The Item.
    /// @return The decoded string.
    function toData(Item memory self) internal pure returns (bytes memory) {
        require(isData(self));
        (uint256 rStartPos, uint256 len) = _decode(self);
        bytes memory bts;
        bts = new bytes(len);
        _copyToBytes(rStartPos, bts, len);
        return bts;
    }

    /// @dev Get the list of sub-items from an RLP encoded list.
    /// Warning: This is inefficient, as it requires that the list is read twice.
    /// @param self The Item.
    /// @return Array of Items.
    function toList(Item memory self) internal pure returns (Item[] memory) {
        require(isList(self), "Rlp.sol:Rlp:toList:1");
        uint256 numItems = items(self);
        Item[] memory list = new Item[](numItems);
        Rlp.Iterator memory it = iterator(self);
        uint256 idx;
        while (hasNext(it)) {
            list[idx] = next(it);
            idx++;
        }
        return list;
    }

    /// @dev Decode an Item into an ascii string. This will not work if the
    /// Item is a list.
    /// @param self The Item.
    /// @return The decoded string.
    function toAscii(Item memory self) internal pure returns (string memory) {
        require(isData(self), "Rlp.sol:Rlp:toAscii:1");
        (uint256 rStartPos, uint256 len) = _decode(self);
        bytes memory bts = new bytes(len);
        _copyToBytes(rStartPos, bts, len);
        string memory str = string(bts);
        return str;
    }

    /// @dev Decode an Item into a uint. This will not work if the
    /// Item is a list.
    /// @param self The Item.
    /// @return The decoded string.
    function toUint(Item memory self) internal pure returns (uint256) {
        require(isData(self), "Rlp.sol:Rlp:toUint:1");
        (uint256 rStartPos, uint256 len) = _decode(self);
        require(len <= 32, "Rlp.sol:Rlp:toUint:3");
        require(len != 0, "Rlp.sol:Rlp:toUint:4");
        uint256 data;
        assembly {
            data := div(mload(rStartPos), exp(256, sub(32, len)))
        }
        return data;
    }

    /// @dev Decode an Item into a boolean. This will not work if the
    /// Item is a list.
    /// @param self The Item.
    /// @return The decoded string.
    function toBool(Item memory self) internal pure returns (bool) {
        require(isData(self), "Rlp.sol:Rlp:toBool:1");
        (uint256 rStartPos, uint256 len) = _decode(self);
        require(len == 1, "Rlp.sol:Rlp:toBool:3");
        uint256 temp;
        assembly {
            temp := byte(0, mload(rStartPos))
        }
        require(temp <= 1, "Rlp.sol:Rlp:toBool:8");
        return temp == 1 ? true : false;
    }

    /// @dev Decode an Item into a byte. This will not work if the
    /// Item is a list.
    /// @param self The Item.
    /// @return The decoded string.
    function toByte(Item memory self) internal pure returns (bytes1) {
        require(isData(self), "Rlp.sol:Rlp:toByte:1");
        (uint256 rStartPos, uint256 len) = _decode(self);
        require(len == 1, "Rlp.sol:Rlp:toByte:3");
        bytes1 temp;
        assembly {
            temp := byte(0, mload(rStartPos))
        }
        return bytes1(temp);
    }

    /// @dev Decode an Item into an int. This will not work if the
    /// Item is a list.
    /// @param self The Item.
    /// @return The decoded string.
    function toInt(Item memory self) internal pure returns (int256) {
        return int256(toUint(self));
    }

    /// @dev Decode an Item into a bytes32. This will not work if the
    /// Item is a list.
    /// @param self The Item.
    /// @return The decoded string.
    function toBytes32(Item memory self) internal pure returns (bytes32) {
        return bytes32(toUint(self));
    }

    /// @dev Decode an Item into an address. This will not work if the
    /// Item is a list.
    /// @param self The Item.
    /// @return The decoded string.
    function toAddress(Item memory self) internal pure returns (address) {
        require(isData(self), "Rlp.sol:Rlp:toAddress:1");
        (uint256 rStartPos, uint256 len) = _decode(self);
        require(len == 20, "Rlp.sol:Rlp:toAddress:3");
        address data;
        assembly {
            data := div(mload(rStartPos), exp(256, 12))
        }
        return data;
    }

    // Get the payload offset.
    function _payloadOffset(Item memory self) private pure returns (uint256) {
        if (self._unsafe_length == 0) {
            return 0;
        }
        uint256 b0;
        uint256 memPtr = self._unsafe_memPtr;
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        if (b0 < DATA_SHORT_START) {
            return 0;
        }
        if (b0 < DATA_LONG_START || (b0 >= LIST_SHORT_START && b0 < LIST_LONG_START)) {
            return 1;
        }
        if (b0 < LIST_SHORT_START) {
            return b0 - DATA_LONG_OFFSET + 1;
        }
        return b0 - LIST_LONG_OFFSET + 1;
    }

    // Get the full length of an Item.
    function _itemLength(uint256 memPtr) private pure returns (uint256 len) {
        uint256 b0;
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        if (b0 < DATA_SHORT_START) {
            len = 1;
        } else if (b0 < DATA_LONG_START) {
            len = b0 - DATA_SHORT_START + 1;
        } else if (b0 < LIST_SHORT_START) {
            assembly {
                let bLen := sub(b0, 0xB7) // bytes length (DATA_LONG_OFFSET)
                let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen))) // data length
                len := add(1, add(bLen, dLen)) // total length
            }
        } else if (b0 < LIST_LONG_START) {
            len = b0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let bLen := sub(b0, 0xF7) // bytes length (LIST_LONG_OFFSET)
                let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen))) // data length
                len := add(1, add(bLen, dLen)) // total length
            }
        }
    }

    // Get start position and length of the data.
    function _decode(Item memory self) private pure returns (uint256 memPtr, uint256 len) {
        require(isData(self), "Rlp.sol:Rlp:_decode:1");
        uint256 b0;
        uint256 start = self._unsafe_memPtr;
        assembly {
            b0 := byte(0, mload(start))
        }
        if (b0 < DATA_SHORT_START) {
            memPtr = start;
            len = 1;
            return (memPtr, len);
        }
        if (b0 < DATA_LONG_START) {
            len = self._unsafe_length - 1;
            memPtr = start + 1;
        } else {
            uint256 bLen;
            assembly {
                bLen := sub(b0, 0xB7) // DATA_LONG_OFFSET
            }
            len = self._unsafe_length - 1 - bLen;
            memPtr = start + bLen + 1;
        }
        return (memPtr, len);
    }

    // Assumes that enough memory has been allocated to store in target.
    function _copyToBytes(uint256 sourceBytes, bytes memory destinationBytes, uint256 btsLen) internal pure {
        // Exploiting the fact that 'tgt' was the last thing to be allocated,
        // we can write entire words, and just overwrite any excess.
        assembly {
            let words := div(add(btsLen, 31), 32)
            let sourcePointer := sourceBytes
            let destinationPointer := add(destinationBytes, 32)
            for { let i := 0 } lt(i, words) { i := add(i, 1) } {
                let offset := mul(i, 32)
                mstore(add(destinationPointer, offset), mload(add(sourcePointer, offset)))
            }
            mstore(add(destinationBytes, add(32, mload(destinationBytes))), 0)
        }
    }

    // Check that an Item is valid.
    function _validate(Item memory self) private pure returns (bool ret) {
        // Check that RLP is well-formed.
        uint256 b0;
        uint256 b1;
        uint256 memPtr = self._unsafe_memPtr;
        assembly {
            b0 := byte(0, mload(memPtr))
            b1 := byte(1, mload(memPtr))
        }
        if (b0 == DATA_SHORT_START + 1 && b1 < DATA_SHORT_START) {
            return false;
        }
        return true;
    }

    function rlpBytesToUint256(bytes memory source) internal pure returns (uint256 result) {
        return Rlp.toUint(Rlp.toItem(source));
    }

    function rlpBytesToAddress(bytes memory source) internal pure returns (address result) {
        return Rlp.toAddress(Rlp.toItem(source));
    }

    function rlpBytesToBytes32(bytes memory source) internal pure returns (bytes32 result) {
        return Rlp.toBytes32(Rlp.toItem(source));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Pluggable Interface
 * @dev This interface provides functionalities for initializing and deinitializing wallet-related plugins or modules
 */
interface IPluggable is IERC165 {
    /**
     * @notice Initializes a specific module or plugin for the wallet with the provided data
     * @param data Initialization data required for the module or plugin
     */
    function walletInit(bytes calldata data) external;

    /**
     * @notice Deinitializes a specific module or plugin from the wallet
     */
    function walletDeInit() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title IExecutionManager
 * @dev Interface for executing transactions or batch of transactions
 * The execution can be a single transaction or multiple transactions in sequence
 */
interface IExecutionManager {
    /**
     * @notice Executes a single transaction
     * @dev This can be invoked directly by the owner or by an entry point
     *
     * @param dest The destination address for the transaction
     * @param value The amount of Ether (in wei) to transfer along with the transaction. Can be 0 for non-ETH transfers
     * @param func The function call data to be executed
     */
    function execute(address dest, uint256 value, bytes calldata func) external;

    /**
     * @notice Executes a sequence of transactions with the same Ether value for each
     * @dev All transactions in the batch will carry 0 Ether value
     * @param dest An array of destination addresses for each transaction in the batch
     * @param func An array of function call data for each transaction in the batch
     */
    function executeBatch(address[] calldata dest, bytes[] calldata func) external;

    /**
     * @notice Executes a sequence of transactions with specified Ether values for each
     * @dev The values for Ether transfer are specified for each transaction
     * @param dest An array of destination addresses for each transaction in the batch
     * @param value An array of amounts of Ether (in wei) to transfer for each transaction in the batch
     * @param func An array of function call data for each transaction in the batch
     */
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title Owner Manager Interface
 * @dev This interface defines the management functionalities for handling owners within the system.
 * Owners are identified by a unique bytes32 ID. This design allows for a flexible representation
 * of ownership – whether it be an Ethereum address, a hash of an off-chain public key, or any other
 * unique identifier.
 */
interface IOwnerManager {
    /**
     * @notice Emitted when a new owner is successfully added
     * @param owner The bytes32 ID of the newly added owner
     */
    event OwnerAdded(bytes32 indexed owner);

    /**
     * @notice Emitted when an owner is successfully removed
     * @param owner The bytes32 ID of the removed owner
     */
    event OwnerRemoved(bytes32 indexed owner);

    /**
     * @notice Emitted when all owners are cleared from the system
     */
    event OwnerCleared();

    /**
     * @notice Checks if a given bytes32 ID corresponds to an owner within the system
     * @param owner The bytes32 ID to check
     * @return True if the ID corresponds to an owner, false otherwise
     */
    function isOwner(bytes32 owner) external view returns (bool);

    /**
     * @notice Adds a new owner to the system
     * @param owner The bytes32 ID of the owner to be added
     */
    function addOwner(bytes32 owner) external;

    /**
     * @notice Removes an existing owner from the system
     * @param owner The bytes32 ID of the owner to be removed
     */
    function removeOwner(bytes32 owner) external;

    /**
     * @notice Resets the entire owner set, replacing it with a single new owner
     * @param newOwner The bytes32 ID of the new owner
     */
    function resetOwner(bytes32 newOwner) external;

    /**
     * @notice Adds multiple new owners to the system
     * @param owners An array of bytes32 IDs representing the owners to be added
     */
    function addOwners(bytes32[] calldata owners) external;

    /**
     * @notice Resets the entire owner set, replacing it with a new set of owners
     * @param newOwners An array of bytes32 IDs representing the new set of owners
     */
    function resetOwners(bytes32[] calldata newOwners) external;

    /**
     * @notice Provides a list of all added owners
     * @return owners An array of bytes32 IDs representing the owners
     */
    function listOwner() external view returns (bytes32[] memory owners);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./IPlugin.sol";

/**
 * @title Plugin Manager Interface
 * @dev This interface provides functionalities for adding, removing, and querying plugins
 */
interface IPluginManager {
    event PluginAdded(address indexed plugin);
    event PluginRemoved(address indexed plugin);
    event PluginRemovedWithError(address indexed plugin);

    /**
     * @notice Add a new plugin along with its initialization data
     * @param pluginAndData The plugin address concatenated with its initialization data
     */
    function addPlugin(bytes calldata pluginAndData) external;

    /**
     * @notice Remove a plugin from the system
     * @param plugin The address of the plugin to be removed
     */
    function removePlugin(address plugin) external;

    /**
     * @notice Checks if a plugin is authorized
     * @param plugin The address of the plugin to check
     * @return True if the plugin is authorized, otherwise false
     */
    function isAuthorizedPlugin(address plugin) external returns (bool);

    /**
     * @notice List all plugins of a specific hook type
     * @param hookType The type of the hook for which to list plugins
     * @return plugins An array of plugin addresses corresponding to the hookType
     */
    function listPlugin(uint8 hookType) external view returns (address[] memory plugins);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title IFallbackManager
 * @dev Interface for setting and managing the fallback contract.
 * The fallback contract is called when no other function matches the provided function signature.
 */
interface IFallbackManager {
    /**
     * @notice Emitted when the fallback contract is changed
     * @param fallbackContract The address of the newly set fallback contract
     */
    event FallbackChanged(address indexed fallbackContract);
    /**
     * @notice Set a new fallback contract
     * @dev This function allows setting a new address as the fallback contract. The fallback contract will receive
     * all calls made to this contract that do not match any other function
     * @param fallbackContract The address of the fallback contract to be set
     */

    function setFallbackHandler(address fallbackContract) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

interface IAccount {

    /**
     * Validate user's signature and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfully.
     * signature failure should be reported by returning SIG_VALIDATION_FAILED (1).
     * This allows making a "simulation call" without a valid signature
     * Other failures (e.g. nonce mismatch, or invalid signature format) should still revert to signal failure.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the signature and nonce
     * @param userOp the operation that is about to be executed.
     * @param userOpHash hash of the user's request data. can be used as the basis for signature.
     * @param missingAccountFunds missing funds on the account's deposit in the entrypoint.
     *      This is the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
     *      The excess is left as a deposit in the entrypoint, for future calls.
     *      can be withdrawn anytime using "entryPoint.withdrawTo()"
     *      In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
     * @return validationData packaged ValidationData structure. use `_packValidationData` and `_unpackValidationData` to encode and decode
     *      <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
     *         otherwise, an address of an "authorizer" contract.
     *      <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
     *      <6-byte> validAfter - first timestamp this operation is valid
     *      If an account doesn't use time-range, it is enough to return SIG_VALIDATION_FAILED value (1) for signature failure.
     *      Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
    external returns (uint256 validationData);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title Upgradable Interface
 * @dev This interface provides functionalities to upgrade the implementation of a contract
 * It emits an event when the implementation is changed, either to a new version or from an old version
 */
interface IUpgradable {
    event Upgraded(address indexed oldImplementation, address indexed newImplementation);

    /**
     * @dev Upgrade the current implementation to the provided new implementation address
     * @param newImplementation The address of the new contract implementation
     */
    function upgradeTo(address newImplementation) external;

    /**
     * @dev Upgrade from the current implementation, given the old implementation address
     * @param oldImplementation The address of the old contract implementation that is being replaced
     */
    function upgradeFrom(address oldImplementation) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@account-abstraction/contracts/interfaces/UserOperation.sol";
import "./IPluggable.sol";

/**
 * @title Plugin Interface
 * @dev This interface provides functionalities for hooks and interactions of plugins within a wallet or contract
 */
interface IPlugin is IPluggable {
    /**
     * @notice Specifies the types of hooks a plugin supports
     * @return hookType An 8-bit value where:
     *         - GuardHook is represented by 1<<0
     *         - PreHook is represented by 1<<1
     *         - PostHook is represented by 1<<2
     */
    function supportsHook() external pure returns (uint8 hookType);

    /**
     * @notice A hook that guards the user operation
     * @dev For security, plugins should revert when they do not need guardData but guardData.length > 0
     * @param userOp The user operation being performed
     * @param userOpHash The hash of the user operation
     * @param guardData Additional data for the guard
     */
    function guardHook(UserOperation calldata userOp, bytes32 userOpHash, bytes calldata guardData) external;

    /**
     * @notice A hook that's executed before the actual operation
     * @param target The target address of the operation
     * @param value The amount of ether (in wei) involved in the operation
     * @param data The calldata for the operation
     */
    function preHook(address target, uint256 value, bytes calldata data) external;

    /**
     * @notice A hook that's executed after the actual operation
     * @param target The target address of the operation
     * @param value The amount of ether (in wei) involved in the operation
     * @param data The calldata for the operation
     */
    function postHook(address target, uint256 value, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

import {calldataKeccak} from "../core/Helpers.sol";

/**
 * User Operation struct
 * @param sender the sender account of this request.
     * @param nonce unique value the sender uses to verify it is not a replay.
     * @param initCode if set, the account contract will be created by this constructor/
     * @param callData the method call to execute on this account.
     * @param callGasLimit the gas limit passed to the callData method call.
     * @param verificationGasLimit gas used for validateUserOp and validatePaymasterUserOp.
     * @param preVerificationGas gas not calculated by the handleOps method, but added to the gas paid. Covers batch overhead.
     * @param maxFeePerGas same as EIP-1559 gas parameter.
     * @param maxPriorityFeePerGas same as EIP-1559 gas parameter.
     * @param paymasterAndData if set, this field holds the paymaster address and paymaster-specific data. the paymaster will pay for the transaction instead of the sender.
     * @param signature sender-verified signature over the entire request, the EntryPoint address and the chain ID.
     */
    struct UserOperation {

        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes paymasterAndData;
        bytes signature;
    }

/**
 * Utility functions helpful when working with UserOperation structs.
 */
library UserOperationLib {

    function getSender(UserOperation calldata userOp) internal pure returns (address) {
        address data;
        //read sender from userOp, which is first userOp member (saves 800 gas...)
        assembly {data := calldataload(userOp)}
        return address(uint160(data));
    }

    //relayer/block builder might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(UserOperation calldata userOp) internal view returns (uint256) {
    unchecked {
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        if (maxFeePerGas == maxPriorityFeePerGas) {
            //legacy mode (for networks that don't support basefee opcode)
            return maxFeePerGas;
        }
        return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
    }
    }

    function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {
        address sender = getSender(userOp);
        uint256 nonce = userOp.nonce;
        bytes32 hashInitCode = calldataKeccak(userOp.initCode);
        bytes32 hashCallData = calldataKeccak(userOp.callData);
        uint256 callGasLimit = userOp.callGasLimit;
        uint256 verificationGasLimit = userOp.verificationGasLimit;
        uint256 preVerificationGas = userOp.preVerificationGas;
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        bytes32 hashPaymasterAndData = calldataKeccak(userOp.paymasterAndData);

        return abi.encode(
            sender, nonce,
            hashInitCode, hashCallData,
            callGasLimit, verificationGasLimit, preVerificationGas,
            maxFeePerGas, maxPriorityFeePerGas,
            hashPaymasterAndData
        );
    }

    function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

/**
 * returned data from validateUserOp.
 * validateUserOp returns a uint256, with is created by `_packedValidationData` and parsed by `_parseValidationData`
 * @param aggregator - address(0) - the account validated the signature by itself.
 *              address(1) - the account failed to validate the signature.
 *              otherwise - this is an address of a signature aggregator that must be used to validate the signature.
 * @param validAfter - this UserOp is valid only after this timestamp.
 * @param validaUntil - this UserOp is valid only up to this timestamp.
 */
    struct ValidationData {
        address aggregator;
        uint48 validAfter;
        uint48 validUntil;
    }

//extract sigFailed, validAfter, validUntil.
// also convert zero validUntil to type(uint48).max
    function _parseValidationData(uint validationData) pure returns (ValidationData memory data) {
        address aggregator = address(uint160(validationData));
        uint48 validUntil = uint48(validationData >> 160);
        if (validUntil == 0) {
            validUntil = type(uint48).max;
        }
        uint48 validAfter = uint48(validationData >> (48 + 160));
        return ValidationData(aggregator, validAfter, validUntil);
    }

// intersect account and paymaster ranges.
    function _intersectTimeRange(uint256 validationData, uint256 paymasterValidationData) pure returns (ValidationData memory) {
        ValidationData memory accountValidationData = _parseValidationData(validationData);
        ValidationData memory pmValidationData = _parseValidationData(paymasterValidationData);
        address aggregator = accountValidationData.aggregator;
        if (aggregator == address(0)) {
            aggregator = pmValidationData.aggregator;
        }
        uint48 validAfter = accountValidationData.validAfter;
        uint48 validUntil = accountValidationData.validUntil;
        uint48 pmValidAfter = pmValidationData.validAfter;
        uint48 pmValidUntil = pmValidationData.validUntil;

        if (validAfter < pmValidAfter) validAfter = pmValidAfter;
        if (validUntil > pmValidUntil) validUntil = pmValidUntil;
        return ValidationData(aggregator, validAfter, validUntil);
    }

/**
 * helper to pack the return value for validateUserOp
 * @param data - the ValidationData to pack
 */
    function _packValidationData(ValidationData memory data) pure returns (uint256) {
        return uint160(data.aggregator) | (uint256(data.validUntil) << 160) | (uint256(data.validAfter) << (160 + 48));
    }

/**
 * helper to pack the return value for validateUserOp, when not using an aggregator
 * @param sigFailed - true for signature failure, false for success
 * @param validUntil last timestamp this UserOperation is valid (or zero for infinite)
 * @param validAfter first timestamp this UserOperation is valid
 */
    function _packValidationData(bool sigFailed, uint48 validUntil, uint48 validAfter) pure returns (uint256) {
        return (sigFailed ? 1 : 0) | (uint256(validUntil) << 160) | (uint256(validAfter) << (160 + 48));
    }

/**
 * keccak function over calldata.
 * @dev copy calldata into memory, do keccak and drop allocated memory. Strangely, this is more efficient than letting solidity do it.
 */
    function calldataKeccak(bytes calldata data) pure returns (bytes32 ret) {
        assembly {
            let mem := mload(0x40)
            let len := data.length
            calldatacopy(mem, data.offset, len)
            ret := keccak256(mem, len)
        }
    }