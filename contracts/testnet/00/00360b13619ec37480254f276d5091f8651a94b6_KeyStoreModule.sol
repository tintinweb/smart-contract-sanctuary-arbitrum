pragma solidity ^0.8.17;

import "../BaseModule.sol";
import "./IKeyStoreModule.sol";
import "./BlockVerifier.sol";
import "./MerklePatriciaVerifier.sol";
import "../../libraries/KeyStoreSlotLib.sol";
import "../../keystore/interfaces/IKeystoreProof.sol";

contract KeyStoreModule is IKeyStoreModule, BaseModule {
    bytes4 private constant _FUNC_RESET_OWNER = bytes4(keccak256("resetOwner(address)"));
    bytes4 private constant _FUNC_RESET_OWNERS = bytes4(keccak256("resetOwners(address[])"));

    IKeystoreProof public immutable keyStoreProof;

    mapping(address => bytes32) public l1Slot;
    mapping(address => address) public lastKeyStoreSyncSignKey;

    mapping(address => bool) walletInited;
    uint128 private __seed = 0;

    function _newSeed() private returns (uint128) {
        __seed++;
        return __seed;
    }

    constructor(address _keyStoreProof) {
        keyStoreProof = IKeystoreProof(_keyStoreProof);
    }
    // validate the l1 keystore signing key using merkel patricia proof

    function syncL1Keystore(address wallet) external override {
        bytes32 slotInfo = l1Slot[wallet];
        require(slotInfo != bytes32(0), "wallet slot not set");
        address keystoreSignKey = keyStoreProof.keystoreBySlot(slotInfo);
        require(keystoreSignKey != address(0), "keystore proof not sync");
        address lastSyncKeyStore = lastKeyStoreSyncSignKey[wallet];
        if (lastSyncKeyStore != address(0) && lastSyncKeyStore == keystoreSignKey) {
            revert("keystore already synced");
        }
        ISoulWallet soulwallet = ISoulWallet(payable(wallet));
        soulwallet.resetOwner(keystoreSignKey);
        lastKeyStoreSyncSignKey[wallet] = keystoreSignKey;
        emit KeyStoreSyncd(wallet, keystoreSignKey);
    }

    function requiredFunctions() external pure override returns (bytes4[] memory) {
        bytes4[] memory functions = new bytes4[](2);
        functions[0] = _FUNC_RESET_OWNER;
        functions[1] = _FUNC_RESET_OWNERS;
        return functions;
    }

    function inited(address wallet) internal view virtual override returns (bool) {
        return walletInited[wallet];
    }
    // when wallet add keystore module, it will call this function to set the l1keystore slot mapping

    function _init(bytes calldata _data) internal virtual override {
        address _sender = sender();
        (bytes32 initialKey, bytes32 initialGuardianHash, uint64 guardianSafePeriod) =
            abi.decode(_data, (bytes32, bytes32, uint64));
        bytes32 walletKeyStoreSlot = KeyStoreSlotLib.getSlot(initialKey, initialGuardianHash, guardianSafePeriod);
        require(walletKeyStoreSlot != bytes32(0), "wallet slot needs to set");
        l1Slot[_sender] = walletKeyStoreSlot;

        address keystoreSignKey = keyStoreProof.keystoreBySlot(walletKeyStoreSlot);
        // if keystore already sync, change to keystore signer
        if (keystoreSignKey != address(0)) {
            ISoulWallet soulwallet = ISoulWallet(payable(_sender));
            // sync keystore signing key
            soulwallet.resetOwner(keystoreSignKey);
            lastKeyStoreSyncSignKey[_sender] = keystoreSignKey;
            emit KeyStoreSyncd(_sender, keystoreSignKey);
        }
        walletInited[_sender] = true;
    }

    function _deInit() internal virtual override {
        address _sender = sender();
        delete l1Slot[_sender];
        delete lastKeyStoreSyncSignKey[_sender];
        walletInited[_sender] = false;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../interfaces/IModule.sol";
import "../interfaces/ISoulWallet.sol";
import "../interfaces/IModuleManager.sol";

abstract contract BaseModule is IModule {
    event ModuleInit(address indexed wallet);
    event ModuleDeInit(address indexed wallet);

    function inited(address wallet) internal view virtual returns (bool);

    function _init(bytes calldata data) internal virtual;

    function _deInit() internal virtual;

    function sender() internal view returns (address) {
        return msg.sender;
    }

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

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IModule).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IKeyStoreModule {
    event KeyStoreSyncd(address indexed _wallet, address indexed _newOwners);

    function syncL1Keystore(address wallet) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

library BlockVerifier {
    function extractStateRootAndTimestamp(bytes memory rlpBytes, bytes32 blockHash)
        internal
        view
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

pragma solidity ^0.8.17;

import {Rlp} from "./Rlp.sol";

// source: https://github.com/Keydonix/uniswap-oracle/blob/master/contracts/source/MerklePatriciaVerifier.sol
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
                pathPtr += _nibblesToTraverse(Rlp.toData(currentNodeList[0]), nibblePath, pathPtr);
                // leaf node
                if (pathPtr == nibblePath.length) {
                    return Rlp.toData(currentNodeList[1]);
                }
                //extension node
                require(
                    _nibblesToTraverse(Rlp.toData(currentNodeList[0]), nibblePath, pathPtr) != 0,
                    "invalid extension node"
                );

                nodeKey = Rlp.toBytes32(currentNodeList[1]);
            } else {
                require(false, "unexpected length array");
            }
        }
        require(false, "not enough proof nodes");
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
pragma solidity ^0.8.17;

library KeyStoreSlotLib {
    function getSlot(bytes32 initialKey, bytes32 initialGuardianHash, uint64 guardianSafePeriod)
        internal
        pure
        returns (bytes32 slot)
    {
        return keccak256(abi.encode(initialKey, initialGuardianHash, guardianSafePeriod));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IKeystoreProof {
    function keystoreBySlot(bytes32 l1Slot) external view returns (address signingKey);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "./IPluggable.sol";

interface IModule is IPluggable {
    function requiredFunctions() external pure returns (bytes4[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "./IExecutionManager.sol";
import "./IModuleManager.sol";
import "./IOwnerManager.sol";
import "./IPluginManager.sol";
import "./IFallbackManager.sol";
import "@account-abstraction/contracts/interfaces/IAccount.sol";
import "./IUpgradable.sol";

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
pragma solidity ^0.8.17;

import "./IModule.sol";

interface IModuleManager {
    event ModuleAdded(address indexed module);
    event ModuleRemoved(address indexed module);
    event ModuleRemovedWithError(address indexed module);

    function addModule(bytes calldata moduleAndData) external;

    function removeModule(address) external;

    function isAuthorizedModule(address module) external returns (bool);

    function listModule() external view returns (address[] memory modules, bytes4[][] memory selectors);

    function executeFromModule(address dest, uint256 value, bytes calldata func) external;
}

pragma solidity ^0.8.17;

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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IPluggable is IERC165 {
    function walletInit(bytes calldata data) external;
    function walletDeInit() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IExecutionManager {
    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(address dest, uint256 value, bytes calldata func) external;

    /**
     * execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest, bytes[] calldata func) external;

    /**
     * execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IOwnerManager {
    event OwnerCleared();
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);

    function isOwner(address addr) external view returns (bool);

    function resetOwner(address newOwner) external;

    function addOwner(address owner) external;

    function addOwners(address[] calldata owners) external;

    function resetOwners(address[] calldata newOwners) external;

    function removeOwner(address owner) external;

    function listOwner() external returns (address[] memory owners);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "./IPlugin.sol";

interface IPluginManager {
    event PluginAdded(address indexed plugin);
    event PluginRemoved(address indexed plugin);
    event PluginRemovedWithError(address indexed plugin);

    function addPlugin(bytes calldata pluginAndData) external;

    function removePlugin(address plugin) external;

    function isAuthorizedPlugin(address plugin) external returns (bool);

    function listPlugin(uint8 hookType) external view returns (address[] memory plugins);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IFallbackManager {
    event FallbackChanged(address indexed fallbackContract);

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
pragma solidity ^0.8.17;

interface IUpgradable {
    event Upgraded(address indexed oldImplementation, address indexed newImplementation);

    function upgradeTo(address newImplementation) external;
    function upgradeFrom(address oldImplementation) external;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@account-abstraction/contracts/interfaces/UserOperation.sol";
import "./IPluggable.sol";

interface IPlugin is IPluggable {
    /**
     * @dev
     * hookType structure:
     * GuardHook: 1<<0
     * PreHook:   1<<1
     * PostHook:  1<<2
     */
    function supportsHook() external pure returns (uint8 hookType);

    /**
     * @dev For flexibility, guardData does not participate in the userOp signature verification.
     *      Plugins must revert when they do not need guardData but guardData.length > 0(for security reasons)
     */
    function guardHook(UserOperation calldata userOp, bytes32 userOpHash, bytes calldata guardData) external;

    function preHook(address target, uint256 value, bytes calldata data) external;

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