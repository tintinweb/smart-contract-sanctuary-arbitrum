pragma solidity ^0.8.17;

import "./IKnownStateRootWithHistory.sol";
import "./MerklePatriciaVerifier.sol";
import "../../keystore/interfaces/IKeystoreProof.sol";

contract KeystoreProof is IKeystoreProof {
    mapping(bytes32 => address) public l1SlotToSigningKey;
    mapping(bytes32 => uint256) public lastProofBlock;
    mapping(bytes32 => bytes32) public stateRootToKeystoreStorageRoot;

    address public immutable STATE_ROOT_HISTORY_ADDESS;
    address public immutable L1_KEYSTORE_ADDRESS;
    // the latest block number in l1 that proved
    uint256 public lastestProofL1BlockNumber;

    event KeyStoreStorageProved(bytes32 stateRoot, bytes32 storageRoot);
    event L1KeyStoreProved(bytes32 l1Slot, address signingKey);

    constructor(address _l1KeystoreAddress, address _stateRootHistoryAddress) {
        L1_KEYSTORE_ADDRESS = _l1KeystoreAddress;
        STATE_ROOT_HISTORY_ADDESS = _stateRootHistoryAddress;
    }

    function proofKeystoreStorageRoot(bytes32 stateRoot, bytes memory accountProof) external {
        (bool searchResult, BlockInfo memory currentBlockInfo) =
            IKnownStateRootWithHistory(STATE_ROOT_HISTORY_ADDESS).stateRootInfo(stateRoot);
        require(searchResult, "unkown root");
        require(stateRootToKeystoreStorageRoot[stateRoot] == bytes32(0), "storage root already proved");
        bytes memory keyStoreAccountDetailsBytes = MerklePatriciaVerifier.getValueFromProof(
            currentBlockInfo.storageRootHash, keccak256(abi.encodePacked(L1_KEYSTORE_ADDRESS)), accountProof
        );
        Rlp.Item[] memory keyStoreDetails = Rlp.toList(Rlp.toItem(keyStoreAccountDetailsBytes));
        bytes32 keyStoreStorageRootHash = Rlp.toBytes32(keyStoreDetails[2]);
        stateRootToKeystoreStorageRoot[stateRoot] = keyStoreStorageRootHash;
        if (currentBlockInfo.blockNumber > lastestProofL1BlockNumber) {
            lastestProofL1BlockNumber = currentBlockInfo.blockNumber;
        }
        emit KeyStoreStorageProved(stateRoot, keyStoreStorageRootHash);
    }

    function proofL1Keystore(bytes32 l1Slot, bytes32 stateRoot, address newSigningKey, bytes memory keyProof)
        external
    {
        (bool searchResult, BlockInfo memory currentBlockInfo) =
            IKnownStateRootWithHistory(STATE_ROOT_HISTORY_ADDESS).stateRootInfo(stateRoot);
        require(searchResult, "unkown stateRoot root");
        bytes32 keyStoreStorageRootHash = stateRootToKeystoreStorageRoot[stateRoot];
        require(keyStoreStorageRootHash != bytes32(0), "storage root not set");

        // when verify merkel patricia proof for storage value, the tree path = keccaka256("l1slot")
        address proofAddress = Rlp.rlpBytesToAddress(
            MerklePatriciaVerifier.getValueFromProof(keyStoreStorageRootHash, keccak256(abi.encode(l1Slot)), keyProof)
        );
        require(proofAddress == newSigningKey, "key not match");
        // store the new proof signing key to slot mapping

        uint256 blockNumber = lastProofBlock[l1Slot];
        require(currentBlockInfo.blockNumber > blockNumber, "needs to proof newer block");

        l1SlotToSigningKey[l1Slot] = newSigningKey;
        lastProofBlock[l1Slot] = currentBlockInfo.blockNumber;
        emit L1KeyStoreProved(l1Slot, newSigningKey);
    }

    function keystoreBySlot(bytes32 l1Slot) external view returns (address signingKey) {
        return (l1SlotToSigningKey[l1Slot]);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

struct BlockInfo {
    bytes32 storageRootHash;
    bytes32 blockHash;
    uint256 blockNumber;
    uint256 blockTimestamp;
}

interface IKnownStateRootWithHistory {
    function isKnownStateRoot(bytes32 _stateRoot) external returns (bool);
    function stateRootInfo(bytes32 _stateRoot) external view returns (bool result, BlockInfo memory info);
}

pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

interface IKeystoreProof {
    function keystoreBySlot(bytes32 l1Slot) external view returns (address signingKey);
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