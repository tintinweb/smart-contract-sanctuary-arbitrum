/**
 *Submitted for verification at Arbiscan on 2022-11-24
*/

// SPDX-License-Identifier: MIXED

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/IERC5018.sol

// License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC5018 {
    // Large storage methods
    function write(bytes memory name, bytes memory data) external payable;

    function read(bytes memory name) external view returns (bytes memory, bool);

    // return (size, # of chunks)
    function size(bytes memory name) external view returns (uint256, uint256);

    function remove(bytes memory name) external returns (uint256);

    function countChunks(bytes memory name) external view returns (uint256);

    // Chunk-based large storage methods
    function writeChunk(
        bytes memory name,
        uint256 chunkId,
        bytes memory data
    ) external payable;

    function readChunk(bytes memory name, uint256 chunkId) external view returns (bytes memory, bool);

    function chunkSize(bytes memory name, uint256 chunkId) external view returns (uint256, bool);

    function removeChunk(bytes memory name, uint256 chunkId) external returns (bool);

    function truncate(bytes memory name, uint256 chunkId) external returns (uint256);

    function refund() external;

    function destruct() external;

    function getChunkHash(bytes memory name, uint256 chunkId) external view returns (bytes32);
}


// File contracts/optimize/SlotHelper.sol

// License-Identifier: MIT
pragma solidity ^0.8.0;

library SlotHelper {
    uint256 internal constant SLOTDATA_RIGHT_SHIFT = 32;
    uint256 internal constant LEN_OFFSET = 224;
    uint256 internal constant FIRST_SLOT_DATA_SIZE = 28;

    function putRaw(mapping(uint256 => bytes32) storage slots, bytes memory datas) internal returns (bytes32 mdata) {
        uint256 len = datas.length;
        mdata = encodeMetadata(datas);
        if (len > FIRST_SLOT_DATA_SIZE) {
            bytes32 value;
            uint256 ptr;
            assembly {
                ptr := add(datas, add(0x20, FIRST_SLOT_DATA_SIZE))
            }
            for (uint256 i = 0; i < (len - FIRST_SLOT_DATA_SIZE + 32 - 1) / 32; i++) {
                assembly {
                    value := mload(ptr)
                }
                ptr = ptr + 32;
                slots[i] = value;
            }
        }
    }

    function encodeMetadata(bytes memory data) internal pure returns (bytes32 medata) {
        uint256 datLen = data.length;
        uint256 value;
        assembly {
            value := mload(add(data, 0x20))
        }

        datLen = datLen << LEN_OFFSET;
        value = value >> SLOTDATA_RIGHT_SHIFT;

        medata = bytes32(value | datLen);
    }

    function decodeMetadata(bytes32 mdata) internal pure returns (uint256 len, bytes32 data) {
        len = decodeLen(mdata);
        data = mdata << SLOTDATA_RIGHT_SHIFT;
    }

    function decodeMetadataToData(bytes32 mdata) internal pure returns (uint256 len, bytes memory data) {
        len = decodeLen(mdata);
        mdata = mdata << SLOTDATA_RIGHT_SHIFT;
        data = new bytes(len);
        assembly {
            mstore(add(data, 0x20), mdata)
        }
    }

    function getRaw(mapping(uint256 => bytes32) storage slots, bytes32 mdata)
        internal
        view
        returns (bytes memory data)
    {
        uint256 datalen;
        (datalen, data) = decodeMetadataToData(mdata);

        if (datalen > FIRST_SLOT_DATA_SIZE) {
            uint256 ptr = 0;
            bytes32 value = 0;
            assembly {
                ptr := add(data, add(0x20, FIRST_SLOT_DATA_SIZE))
            }
            for (uint256 i = 0; i < (datalen - FIRST_SLOT_DATA_SIZE + 32 - 1) / 32; i++) {
                value = slots[i];
                assembly {
                    mstore(ptr, value)
                }
                ptr = ptr + 32;
            }
        }
    }

    function getRawAt(
        mapping(uint256 => bytes32) storage slots,
        bytes32 mdata,
        uint256 memoryPtr
    ) internal view returns (uint256 datalen, bool found) {
        bytes32 datapart;
        (datalen, datapart) = decodeMetadata(mdata);

        // memoryPtr:memoryPtr+32 is allocated for the data
        uint256 dataPtr = memoryPtr;
        assembly {
            mstore(dataPtr, datapart)
        }

        if (datalen > FIRST_SLOT_DATA_SIZE) {
            uint256 ptr = 0;
            bytes32 value = 0;

            assembly {
                ptr := add(dataPtr, FIRST_SLOT_DATA_SIZE)
            }
            for (uint256 i = 0; i < (datalen - FIRST_SLOT_DATA_SIZE + 32 - 1) / 32; i++) {
                value = slots[i];
                assembly {
                    mstore(ptr, value)
                }
                ptr = ptr + 32;
            }
        }

        found = true;
    }

    function isInSlot(bytes32 mdata) internal pure returns (bool succeed) {
        return decodeLen(mdata) > 0;
    }

    function encodeLen(uint256 datalen) internal pure returns (bytes32 res) {
        res = bytes32(datalen << LEN_OFFSET);
    }

    function decodeLen(bytes32 mdata) internal pure returns (uint256 res) {
        res = uint256(mdata) >> LEN_OFFSET;
    }

    function addrToBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function bytes32ToAddr(bytes32 bt) internal pure returns (address) {
        return address(uint160(uint256(bt)));
    }
}


// File contracts/Memory.sol

// License-Identifier: MIT

pragma solidity ^0.8.0;

library Memory {
    // Size of a word, in bytes.
    uint256 internal constant WORD_SIZE = 32;
    // Size of the header of a 'bytes' array.
    uint256 internal constant BYTES_HEADER_SIZE = 32;
    // Address of the free memory pointer.
    uint256 internal constant FREE_MEM_PTR = 0x40;

    // Compares the 'len' bytes starting at address 'addr' in memory with the 'len'
    // bytes starting at 'addr2'.
    // Returns 'true' if the bytes are the same, otherwise 'false'.
    function equals(
        uint256 addr,
        uint256 addr2,
        uint256 len
    ) internal pure returns (bool equal) {
        assembly {
            equal := eq(keccak256(addr, len), keccak256(addr2, len))
        }
    }

    // Compares the 'len' bytes starting at address 'addr' in memory with the bytes stored in
    // 'bts'. It is allowed to set 'len' to a lower value then 'bts.length', in which case only
    // the first 'len' bytes will be compared.
    // Requires that 'bts.length >= len'
    function equals(
        uint256 addr,
        uint256 len,
        bytes memory bts
    ) internal pure returns (bool equal) {
        require(bts.length >= len);
        uint256 addr2;
        assembly {
            addr2 := add(
                bts,
                /*BYTES_HEADER_SIZE*/
                32
            )
        }
        return equals(addr, addr2, len);
    }

    // Allocates 'numBytes' bytes in memory. This will prevent the Solidity compiler
    // from using this area of memory. It will also initialize the area by setting
    // each byte to '0'.
    function allocate(uint256 numBytes) internal pure returns (uint256 addr) {
        // Take the current value of the free memory pointer, and update.
        assembly {
            addr := mload(
                /*FREE_MEM_PTR*/
                0x40
            )
            mstore(
                /*FREE_MEM_PTR*/
                0x40,
                add(addr, numBytes)
            )
        }
        uint256 words = (numBytes + WORD_SIZE - 1) / WORD_SIZE;
        for (uint256 i = 0; i < words; i++) {
            assembly {
                mstore(
                    add(
                        addr,
                        mul(
                            i,
                            /*WORD_SIZE*/
                            32
                        )
                    ),
                    0
                )
            }
        }
    }

    // Copy 'len' bytes from memory address 'src', to address 'dest'.
    // This function does not check the or destination, it only copies
    // the bytes.
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) internal pure {
        // Copy word-length chunks while possible
        // Reverse copy to prevent out of memory bound error
        src = src + len;
        dest = dest + len;
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            dest -= WORD_SIZE;
            src -= WORD_SIZE;

            assembly {
                mstore(dest, mload(src))
            }
        }

        if (len == 0) {
            return;
        }

        // Copy remaining bytes
        src = src - len;
        dest = dest - len;
        assembly {
            mstore(dest, mload(src))
        }
    }

    // Returns a memory pointer to the provided bytes array.
    function ptr(bytes memory bts) internal pure returns (uint256 addr) {
        assembly {
            addr := bts
        }
    }

    // Returns a memory pointer to the data portion of the provided bytes array.
    function dataPtr(bytes memory bts) internal pure returns (uint256 addr) {
        assembly {
            addr := add(
                bts,
                /*BYTES_HEADER_SIZE*/
                32
            )
        }
    }

    // This function does the same as 'dataPtr(bytes memory)', but will also return the
    // length of the provided bytes array.
    function fromBytes(bytes memory bts) internal pure returns (uint256 addr, uint256 len) {
        len = bts.length;
        assembly {
            addr := add(
                bts,
                /*BYTES_HEADER_SIZE*/
                32
            )
        }
    }

    // Creates a 'bytes memory' variable from the memory address 'addr', with the
    // length 'len'. The function will allocate new memory for the bytes array, and
    // the 'len bytes starting at 'addr' will be copied into that new memory.
    function toBytes(uint256 addr, uint256 len) internal pure returns (bytes memory bts) {
        bts = new bytes(len);
        uint256 btsptr;
        assembly {
            btsptr := add(
                bts,
                /*BYTES_HEADER_SIZE*/
                32
            )
        }
        copy(addr, btsptr, len);
    }

    // Get the word stored at memory address 'addr' as a 'uint'.
    function toUint(uint256 addr) internal pure returns (uint256 n) {
        assembly {
            n := mload(addr)
        }
    }

    // Get the word stored at memory address 'addr' as a 'bytes32'.
    function toBytes32(uint256 addr) internal pure returns (bytes32 bts) {
        assembly {
            bts := mload(addr)
        }
    }

    /*
    // Get the byte stored at memory address 'addr' as a 'byte'.
    function toByte(uint addr, uint8 index) internal pure returns (byte b) {
        require(index < WORD_SIZE);
        uint8 n;
        assembly {
            n := byte(index, mload(addr))
        }
        b = byte(n);
    }
    */
}


// File contracts/StorageSlotFactory.sol

// License-Identifier: MIT
pragma solidity ^0.8.0;

// Create a storage slot by appending data to the end
contract StorageSlotFromContract {
    constructor(address contractAddr, bytes memory data) payable {
        uint256 codeSize;
        assembly {
            // retrieve the size of the code, this needs assembly
            codeSize := extcodesize(contractAddr)
        }

        uint256 totalSize = codeSize + data.length + 32;
        bytes memory deployCode = new bytes(totalSize);

        // Copy contract code
        assembly {
            // actually retrieve the code, this needs assembly
            extcodecopy(contractAddr, add(deployCode, 0x20), 0, codeSize)
        }

        // Copy data
        uint256 off = Memory.dataPtr(deployCode) + codeSize;
        Memory.copy(Memory.dataPtr(data), off, data.length);

        off += data.length;
        uint256 len = data.length;
        // Set data size
        assembly {
            mstore(off, len)
        }

        // Return the contract manually
        assembly {
            return(add(deployCode, 0x20), totalSize)
        }
    }
}

// Create a storage slot
contract StorageSlotFactoryFromInput {
    constructor(bytes memory codeAndData) payable {
        uint256 size = codeAndData.length;
        // Return the contract manually
        assembly {
            return(add(codeAndData, 0x20), size)
        }
    }
}


// File contracts/StorageHelper.sol

// License-Identifier: MIT
pragma solidity ^0.8.0;


library StorageHelper {
    // StorageSlotSelfDestructable compiled via solc 0.8.7 optimized 200
    bytes internal constant STORAGE_SLOT_CODE =
        hex"6080604052348015600f57600080fd5b506004361060325760003560e01c80632b68b9c61460375780638da5cb5b14603f575b600080fd5b603d6081565b005b60657f000000000000000000000000000000000000000000000000000000000000000081565b6040516001600160a01b03909116815260200160405180910390f35b336001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000161460ed5760405162461bcd60e51b815260206004820152600e60248201526d3737ba10333937b69037bbb732b960911b604482015260640160405180910390fd5b33fffea2646970667358221220fc66c9afb7cb2f6209ae28167cf26c6c06f86a82cbe3c56de99027979389a1be64736f6c63430008070033";
    uint256 internal constant ADDR_OFF0 = 67;
    uint256 internal constant ADDR_OFF1 = 140;

    // StorageSlotFactoryFromInput compiled via solc 0.8.7 optimized 200 + STORAGE_SLOT_CODE
    bytes internal constant FACTORY_CODE =
        hex"60806040526040516101113803806101118339810160408190526100229161002b565b80518060208301f35b6000602080838503121561003e57600080fd5b82516001600160401b038082111561005557600080fd5b818501915085601f83011261006957600080fd5b81518181111561007b5761007b6100fa565b604051601f8201601f19908116603f011681019083821181831017156100a3576100a36100fa565b8160405282815288868487010111156100bb57600080fd5b600093505b828410156100dd57848401860151818501870152928501926100c0565b828411156100ee5760008684830101525b98975050505050505050565b634e487b7160e01b600052604160045260246000fdfe000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000006080604052348015600f57600080fd5b506004361060325760003560e01c80632b68b9c61460375780638da5cb5b14603f575b600080fd5b603d6081565b005b60657f000000000000000000000000000000000000000000000000000000000000000081565b6040516001600160a01b03909116815260200160405180910390f35b336001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000161460ed5760405162461bcd60e51b815260206004820152600e60248201526d3737ba10333937b69037bbb732b960911b604482015260640160405180910390fd5b33fffea2646970667358221220fc66c9afb7cb2f6209ae28167cf26c6c06f86a82cbe3c56de99027979389a1be64736f6c63430008070033";
    uint256 internal constant FACTORY_SIZE_OFF = 305;
    uint256 internal constant FACTORY_ADDR_OFF0 = 305 + 32 + ADDR_OFF0;
    uint256 internal constant FACTORY_ADDR_OFF1 = 305 + 32 + ADDR_OFF1;

    function putRawFromCalldata(bytes calldata data, uint256 value) internal returns (address) {
        bytes memory bytecode = bytes.concat(STORAGE_SLOT_CODE, data);
        {
            // revise the owner to the contract (so that it is destructable)
            uint256 off = ADDR_OFF0 + 0x20;
            assembly {
                mstore(add(bytecode, off), address())
            }
            off = ADDR_OFF1 + 0x20;
            assembly {
                mstore(add(bytecode, off), address())
            }
        }

        StorageSlotFactoryFromInput c = new StorageSlotFactoryFromInput{value: value}(bytecode);
        return address(c);
    }

    function putRaw(bytes memory data, uint256 value) internal returns (address) {
        // create the new contract code with the data
        bytes memory bytecode = STORAGE_SLOT_CODE;
        uint256 bytecodeLen = bytecode.length;
        uint256 newSize = bytecode.length + data.length;
        assembly {
            // in-place resize of bytecode bytes
            // note that this must be done when bytecode is the last allocated object by solidity.
            mstore(bytecode, newSize)
            // notify solidity about the memory size increase, must be 32-bytes aligned
            mstore(0x40, add(bytecode, and(add(add(newSize, 0x20), 0x1f), not(0x1f))))
        }
        // append data to self-destruct byte code
        Memory.copy(Memory.dataPtr(data), Memory.dataPtr(bytecode) + bytecodeLen, data.length);
        {
            // revise the owner to the contract (so that it is destructable)
            uint256 off = ADDR_OFF0 + 0x20;
            assembly {
                mstore(add(bytecode, off), address())
            }
            off = ADDR_OFF1 + 0x20;
            assembly {
                mstore(add(bytecode, off), address())
            }
        }

        StorageSlotFactoryFromInput c = new StorageSlotFactoryFromInput{value: value}(bytecode);
        return address(c);
    }

    function putRaw2(
        bytes32 key,
        bytes memory data,
        uint256 value
    ) internal returns (address) {
        // create the new contract code with the data
        bytes memory bytecode = FACTORY_CODE;
        uint256 bytecodeLen = bytecode.length;
        uint256 newSize = bytecode.length + data.length;
        assembly {
            // in-place resize of bytecode bytes
            // note that this must be done when bytecode is the last allocated object by solidity.
            mstore(bytecode, newSize)
            // notify solidity about the memory size increase, must be 32-bytes aligned
            mstore(0x40, add(bytecode, and(add(add(newSize, 0x20), 0x1f), not(0x1f))))
        }
        // append data to self-destruct byte code
        Memory.copy(Memory.dataPtr(data), Memory.dataPtr(bytecode) + bytecodeLen, data.length);
        {
            // revise the size of calldata
            uint256 calldataSize = STORAGE_SLOT_CODE.length + data.length;
            uint256 off = FACTORY_SIZE_OFF + 0x20;
            assembly {
                mstore(add(bytecode, off), calldataSize)
            }
        }
        {
            // revise the owner to the contract (so that it is destructable)
            uint256 off = FACTORY_ADDR_OFF0 + 0x20;
            assembly {
                mstore(add(bytecode, off), address())
            }
            off = FACTORY_ADDR_OFF1 + 0x20;
            assembly {
                mstore(add(bytecode, off), address())
            }
        }

        address addr;
        assembly {
            addr := create2(
                value,
                add(bytecode, 0x20), // data offset
                mload(bytecode), // size
                key
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        return addr;
    }

    function sizeRaw(address addr) internal view returns (uint256, bool) {
        if (addr == address(0x0)) {
            return (0, false);
        }
        uint256 codeSize;
        uint256 off = STORAGE_SLOT_CODE.length;
        assembly {
            codeSize := extcodesize(addr)
        }
        if (codeSize < off) {
            return (0, false);
        }

        return (codeSize - off, true);
    }

    function getRaw(address addr) internal view returns (bytes memory, bool) {
        (uint256 dataSize, bool found) = sizeRaw(addr);

        if (!found) {
            return (new bytes(0), false);
        }

        // copy the data without the "code"
        bytes memory data = new bytes(dataSize);
        uint256 off = STORAGE_SLOT_CODE.length;
        assembly {
            // retrieve data size
            extcodecopy(addr, add(data, 0x20), off, dataSize)
        }
        return (data, true);
    }

    function getRawAt(address addr, uint256 memoryPtr) internal view returns (uint256, bool) {
        (uint256 dataSize, bool found) = sizeRaw(addr);

        if (!found) {
            return (0, false);
        }

        uint256 off = STORAGE_SLOT_CODE.length;
        assembly {
            // retrieve data size
            extcodecopy(addr, memoryPtr, off, dataSize)
        }
        return (dataSize, true);
    }

    function returnBytesInplace(bytes memory content) internal pure {
        // equal to return abi.encode(content)
        uint256 size = content.length + 0x40; // pointer + size
        size = (size + 0x20 + 0x1f) & ~uint256(0x1f);
        assembly {
            // (DATA CORRUPTION): the caller method must be "external returns (bytes)", cannot be public!
            mstore(sub(content, 0x20), 0x20)
            return(sub(content, 0x20), size)
        }
    }

    function calculateValueForData(
        uint256 datalen,
        uint256 chunkSize,
        uint256 codeStakingPerChunk
    ) internal pure returns (uint256) {
        return ((datalen + STORAGE_SLOT_CODE.length - 1) / chunkSize) * codeStakingPerChunk;
    }

    function storageSlotCodeLength() internal pure returns (uint256) {
        return STORAGE_SLOT_CODE.length;
    }
}


// File contracts/StorageSlotSelfDestructable.sol

// License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorageSlotSelfDestructable {
    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function destruct() public {
        require(msg.sender == owner, "not from owner");
        selfdestruct(payable(msg.sender));
    }
}


// File contracts/LargeStorageManager.sol

// License-Identifier: MIT
pragma solidity ^0.8.0;



// Large storage manager to support arbitrarily-sized data with multiple chunk
contract LargeStorageManager {
    using SlotHelper for bytes32;
    using SlotHelper for address;

    uint8 internal immutable SLOT_LIMIT;

    mapping(bytes32 => mapping(uint256 => bytes32)) internal keyToMetadata;
    mapping(bytes32 => mapping(uint256 => mapping(uint256 => bytes32))) internal keyToSlots;

    constructor(uint8 slotLimit) {
        SLOT_LIMIT = slotLimit;
    }

    function isOptimize() public view returns (bool) {
        return SLOT_LIMIT > 0;
    }

    function _preparePut(bytes32 key, uint256 chunkId) private {
        bytes32 metadata = keyToMetadata[key][chunkId];

        if (metadata == bytes32(0)) {
            require(chunkId == 0 || keyToMetadata[key][chunkId - 1] != bytes32(0x0), "must replace or append");
        }

        if (!metadata.isInSlot()) {
            address addr = metadata.bytes32ToAddr();
            if (addr != address(0x0)) {
                // remove the KV first if it exists
                StorageSlotSelfDestructable(addr).destruct();
            }
        }
    }

    function _putChunkFromCalldata(
        bytes32 key,
        uint256 chunkId,
        bytes calldata data,
        uint256 value
    ) internal {
        _preparePut(key, chunkId);

        // store data and rewrite metadata
        if (data.length > SLOT_LIMIT) {
            keyToMetadata[key][chunkId] = StorageHelper.putRawFromCalldata(data, value).addrToBytes32();
        } else {
            keyToMetadata[key][chunkId] = SlotHelper.putRaw(keyToSlots[key][chunkId], data);
        }
    }

    function _putChunk(
        bytes32 key,
        uint256 chunkId,
        bytes memory data,
        uint256 value
    ) internal {
        _preparePut(key, chunkId);

        // store data and rewrite metadata
        if (data.length > SLOT_LIMIT) {
            keyToMetadata[key][chunkId] = StorageHelper.putRaw(data, value).addrToBytes32();
        } else {
            keyToMetadata[key][chunkId] = SlotHelper.putRaw(keyToSlots[key][chunkId], data);
        }
    }

    function _getChunk(bytes32 key, uint256 chunkId) internal view returns (bytes memory, bool) {
        bytes32 metadata = keyToMetadata[key][chunkId];

        if (metadata.isInSlot()) {
            bytes memory res = SlotHelper.getRaw(keyToSlots[key][chunkId], metadata);
            return (res, true);
        } else {
            address addr = metadata.bytes32ToAddr();
            return StorageHelper.getRaw(addr);
        }
    }

    function _chunkSize(bytes32 key, uint256 chunkId) internal view returns (uint256, bool) {
        bytes32 metadata = keyToMetadata[key][chunkId];

        if (metadata == bytes32(0)) {
            return (0, false);
        } else if (metadata.isInSlot()) {
            uint256 len = metadata.decodeLen();
            return (len, true);
        } else {
            address addr = metadata.bytes32ToAddr();
            return StorageHelper.sizeRaw(addr);
        }
    }

    function _countChunks(bytes32 key) internal view returns (uint256) {
        uint256 chunkId = 0;

        while (true) {
            bytes32 metadata = keyToMetadata[key][chunkId];
            if (metadata == bytes32(0x0)) {
                break;
            }

            chunkId++;
        }

        return chunkId;
    }

    // Returns (size, # of chunks).
    function _size(bytes32 key) internal view returns (uint256, uint256) {
        uint256 size = 0;
        uint256 chunkId = 0;

        while (true) {
            (uint256 chunkSize, bool found) = _chunkSize(key, chunkId);
            if (!found) {
                break;
            }

            size += chunkSize;
            chunkId++;
        }

        return (size, chunkId);
    }

    function _get(bytes32 key) internal view returns (bytes memory, bool) {
        (uint256 size, uint256 chunkNum) = _size(key);
        if (chunkNum == 0) {
            return (new bytes(0), false);
        }

        bytes memory data = new bytes(size); // solidity should auto-align the memory-size to 32
        uint256 dataPtr;
        assembly {
            dataPtr := add(data, 0x20)
        }
        for (uint256 chunkId = 0; chunkId < chunkNum; chunkId++) {
            bytes32 metadata = keyToMetadata[key][chunkId];

            uint256 chunkSize = 0;
            if (metadata.isInSlot()) {
                chunkSize = metadata.decodeLen();
                SlotHelper.getRawAt(keyToSlots[key][chunkId], metadata, dataPtr);
            } else {
                address addr = metadata.bytes32ToAddr();
                (chunkSize, ) = StorageHelper.sizeRaw(addr);
                StorageHelper.getRawAt(addr, dataPtr);
            }

            dataPtr += chunkSize;
        }

        return (data, true);
    }

    // Returns # of chunks deleted
    function _remove(bytes32 key, uint256 chunkId) internal returns (uint256) {
        while (true) {
            bytes32 metadata = keyToMetadata[key][chunkId];
            if (metadata == bytes32(0x0)) {
                break;
            }

            if (!metadata.isInSlot()) {
                address addr = metadata.bytes32ToAddr();
                // remove new contract
                StorageSlotSelfDestructable(addr).destruct();
            }

            keyToMetadata[key][chunkId] = bytes32(0x0);

            chunkId++;
        }

        return chunkId;
    }

    function _removeChunk(bytes32 key, uint256 chunkId) internal returns (bool) {
        bytes32 metadata = keyToMetadata[key][chunkId];
        if (metadata == bytes32(0x0)) {
            return false;
        }

        if (keyToMetadata[key][chunkId + 1] != bytes32(0x0)) {
            // only the last chunk can be removed
            return false;
        }

        if (!metadata.isInSlot()) {
            address addr = metadata.bytes32ToAddr();
            // remove new contract
            StorageSlotSelfDestructable(addr).destruct();
        }

        keyToMetadata[key][chunkId] = bytes32(0x0);

        return true;
    }
}


// File contracts/ERC5018.sol

// License-Identifier: MIT
pragma solidity ^0.8.0;


contract ERC5018 is IERC5018, LargeStorageManager {
    address public owner;

    constructor(uint8 slotLimit) LargeStorageManager(slotLimit) {
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public {
        require(msg.sender == owner, "must from owner");
        owner = newOwner;
    }

    // Large storage methods
    function write(bytes memory name, bytes calldata data) public payable virtual override {
        require(msg.sender == owner, "must from owner");
        // TODO: support multiple chunks
        return _putChunkFromCalldata(keccak256(name), 0, data, msg.value);
    }

    function read(bytes memory name) public view virtual override returns (bytes memory, bool) {
        return _get(keccak256(name));
    }

    function size(bytes memory name) public view virtual override returns (uint256, uint256) {
        return _size(keccak256(name));
    }

    function remove(bytes memory name) public virtual override returns (uint256) {
        require(msg.sender == owner, "must from owner");
        return _remove(keccak256(name), 0);
    }

    function countChunks(bytes memory name) public view virtual override returns (uint256) {
        return _countChunks(keccak256(name));
    }

    // Chunk-based large storage methods
    function writeChunk(
        bytes memory name,
        uint256 chunkId,
        bytes calldata data
    ) public payable virtual override {
        require(msg.sender == owner, "must from owner");
        return _putChunkFromCalldata(keccak256(name), chunkId, data, msg.value);
    }

    function readChunk(bytes memory name, uint256 chunkId) public view virtual override returns (bytes memory, bool) {
        return _getChunk(keccak256(name), chunkId);
    }

    function chunkSize(bytes memory name, uint256 chunkId) public view virtual override returns (uint256, bool) {
        return _chunkSize(keccak256(name), chunkId);
    }

    function removeChunk(bytes memory name, uint256 chunkId) public virtual override returns (bool) {
        require(msg.sender == owner, "must from owner");
        return _removeChunk(keccak256(name), chunkId);
    }

    function truncate(bytes memory name, uint256 chunkId) public virtual override returns (uint256) {
        require(msg.sender == owner, "must from owner");
        return _remove(keccak256(name), chunkId);
    }

    function refund() public override {
        require(msg.sender == owner, "must from owner");
        payable(owner).transfer(address(this).balance);
    }

    function destruct() public override {
        require(msg.sender == owner, "must from owner");
        selfdestruct(payable(owner));
    }

    function getChunkHash(bytes memory name, uint256 chunkId) public override view returns (bytes32) {
        (bytes memory localData,) = readChunk(name, chunkId);
        return keccak256(localData);
    }
}


// File contracts/StorageManager.sol

// License-Identifier: MIT
pragma solidity ^0.8.0;



contract StorageManager {
    using SlotHelper for bytes32;
    using SlotHelper for address;

    uint8 internal constant NO_EXIST = 0;
    uint8 internal constant IN_SLOT = 1;
    uint8 internal constant IN_CONTRACT_CODE = 2;
    uint8 internal constant WHERE_STORE_ERROR = 255;

    uint8 internal immutable SLOT_LIMIT;

    mapping(bytes32 => bytes32) public keyToMetadata;
    mapping(bytes32 => mapping(uint256 => bytes32)) public keyToSlots;

    constructor(uint8 slotLimit) {
        SLOT_LIMIT = slotLimit;
    }

    function _put(
        bytes32 key,
        bytes memory data,
        uint256 value
    ) internal {
        bytes32 metadata = keyToMetadata[key];

        if (!metadata.isInSlot()) {
            address addr = metadata.bytes32ToAddr();
            // Notify: No need to delete metadata here, because it will be rewritten later
            if (addr != address(0x0)) {
                // remove the KV first if it exists
                StorageSlotSelfDestructable(addr).destruct();
            }
        }

        if (data.length > SLOT_LIMIT) {
            // store in new contract
            keyToMetadata[key] = StorageHelper.putRaw(data, value).addrToBytes32();
        } else {
            // store in slot
            keyToMetadata[key] = SlotHelper.putRaw(keyToSlots[key], data);
        }
    }

    function _put2(
        bytes32 key,
        bytes memory data,
        uint256 value
    ) internal {
        bytes32 metadata = keyToMetadata[key];
        address addr = metadata.bytes32ToAddr();
        if (addr != address(0x0)) {
            // remove the KV first if it exists
            StorageSlotSelfDestructable(addr).destruct();
        }

        if (data.length > SLOT_LIMIT) {
            // store in new contract
            keyToMetadata[key] = StorageHelper.putRaw2(key, data, value).addrToBytes32();
        } else {
            // store in slot
            keyToMetadata[key] = SlotHelper.putRaw(keyToSlots[key], data);
        }
    }

    function _get(bytes32 key) internal view returns (bytes memory, bool) {
        bytes32 metadata = keyToMetadata[key];

        if (metadata.isInSlot()) {
            bytes memory res = SlotHelper.getRaw(keyToSlots[key], metadata);
            return (res, true);
        } else {
            address addr = metadata.bytes32ToAddr();
            return StorageHelper.getRaw(addr);
        }
    }

    function _size(bytes32 key) internal view returns (uint256) {
        bytes32 metadata = keyToMetadata[key];

        if (metadata == bytes32(0)) {
            return 0;
        } else if (metadata.isInSlot()) {
            return metadata.decodeLen();
        } else {
            address addr = metadata.bytes32ToAddr();
            (uint256 size, ) = StorageHelper.sizeRaw(addr);
            return size;
        }
    }

    function _location(bytes32 key) internal view returns (uint256) {
        bytes32 metadata = keyToMetadata[key];

        if (metadata == bytes32(0)) {
            return NO_EXIST;
        } else if (metadata.isInSlot()) {
            return IN_SLOT;
        } else {
            address addr = metadata.bytes32ToAddr();
            (, bool found) = StorageHelper.sizeRaw(addr);
            if (found) {
                return IN_CONTRACT_CODE;
            } else {
                // happen error
                return WHERE_STORE_ERROR;
            }
        }
    }

    function _remove(bytes32 key) internal returns (bool) {
        bytes32 metadata = keyToMetadata[key];

        if (metadata == bytes32(0)) {
            return false;
        }

        if (!metadata.isInSlot()) {
            address addr = metadata.bytes32ToAddr();
            if (addr != address(0x0)) {
                StorageSlotSelfDestructable(addr).destruct();
            }
        }

        // cover slot case
        keyToMetadata[key] = 0;
        return true;
    }
}


// File contracts/StorageManagerTest.sol

// License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorageManagerTest is StorageManager {
    constructor(uint8 slotLimit) StorageManager(slotLimit) {}

    function get(bytes32 key) public view returns (bytes memory) {
        (bytes memory data, ) = _get(key);
        return data;
    }

    // for gas metering
    function getWithoutView(bytes32 key) public returns (bytes memory) {
        (bytes memory data, ) = _get(key);
        return data;
    }

    function put(bytes32 key, bytes memory data) public {
        _put(key, data, 0);
    }

    function put2(bytes32 key, bytes memory data) public {
        _put2(key, data, 0);
    }

    function filesize(bytes32 key) public view returns (uint256) {
        return _size(key);
    }

    function whereStore(bytes32 key) public view returns (uint256) {
        return _location(key);
    }

    function remove(bytes32 key) public {
        _remove(key);
    }
}


// File contracts/examples/FlatDirectory.sol

// License-Identifier: MIT

pragma solidity ^0.8.0;

contract FlatDirectory is ERC5018 {
    bytes public defaultFile = "";

    constructor(uint8 slotLimit) ERC5018(slotLimit) {}

    function resolveMode() external pure virtual returns (bytes32) {
        return "manual";
    }

    fallback(bytes calldata pathinfo) external returns (bytes memory)  {
        bytes memory content;
        if (pathinfo.length == 0) {
            // TODO: redirect to "/"?
            return bytes("");
        } else if (pathinfo[0] != 0x2f) {
            // Should not happen since manual mode will have prefix "/" like "/....."
            return bytes("incorrect path");
        }

        if (pathinfo[pathinfo.length - 1] == 0x2f) {
            (content, ) = read(bytes.concat(pathinfo[1:], defaultFile));
        } else {
            (content, ) = read(pathinfo[1:]);
        }

        StorageHelper.returnBytesInplace(content);
    }

    function setDefault(bytes memory _defaultFile) public virtual {
        require(msg.sender == owner, "must from owner");
        defaultFile = _defaultFile;
    }
}


// File contracts/examples/FlatDirectoryFactory.sol

// License-Identifier: MIT

pragma solidity ^0.8.0;

contract FlatDirectoryFactory {
    event FlatDirectoryCreated(address);

    function create() public returns (address) {
        FlatDirectory fd = new FlatDirectory(0);
        fd.changeOwner(msg.sender);
        emit FlatDirectoryCreated(address(fd));
        return address(fd);
    }

    function createOptimized() public returns (address) {
        FlatDirectory fd = new FlatDirectory(220);
        fd.changeOwner(msg.sender);
        emit FlatDirectoryCreated(address(fd));
        return address(fd);
    }
}


// File contracts/examples/FlatDirectoryTest.sol

// License-Identifier: MIT

pragma solidity ^0.8.0;

contract FlatDirectoryTest is FlatDirectory {
    constructor(uint8 slotLimit) FlatDirectory(slotLimit) {}

    function readNonView(bytes memory name) public returns (bytes memory, bool) {
        return _get(keccak256(name));
    }

    function readManual(bytes memory name) external returns (bytes memory) {
        (bytes memory content, ) = _get(keccak256(name));
        StorageHelper.returnBytesInplace(content);
    }
}


// File contracts/examples/IncentivizedFlatDirectory.sol

// License-Identifier: MIT
pragma solidity ^0.8.0;

contract IncentivizedFlatDirectory is FlatDirectory {
    address public operator;

    uint256 public constant PER_CHUNK_SIZE = 24 * 1024;
    uint256 public constant CODE_STAKING_PER_CHUNK = 10**18;

    constructor(uint8 _slotLimit) payable FlatDirectory(_slotLimit) {}

    modifier onlyOperatorOrOwner() {
        require(operator == msg.sender || owner == msg.sender, "must from owner or operator");
        _;
    }

    receive() external payable {
        if (msg.value > 0) {
            require(msg.sender == owner, "only owner transfer token into contract");
        }
    }

    function changeOperator(address _operator) public virtual onlyOperatorOrOwner {
        operator = _operator;
    }

    function setDefault(bytes memory _defaultFile) public virtual override onlyOperatorOrOwner {
        defaultFile = _defaultFile;
    }

    function write(bytes memory name, bytes calldata data) public payable override onlyOperatorOrOwner {
        require(msg.value == 0, "msg.value must be 0");
        return
            _putChunkFromCalldata(
                keccak256(name),
                0,
                data,
                StorageHelper.calculateValueForData(data.length, PER_CHUNK_SIZE, CODE_STAKING_PER_CHUNK)
            );
    }

    function remove(bytes memory name) public override onlyOperatorOrOwner returns (uint256) {
        return _remove(keccak256(name), 0);
    }

    function truncate(bytes memory name, uint256 chunkId) public override onlyOperatorOrOwner returns (uint256) {
        return _remove(keccak256(name), chunkId);
    }

    function writeChunk(
        bytes memory name,
        uint256 chunkId,
        bytes calldata data
    ) public payable override onlyOperatorOrOwner {
        require(msg.value == 0, "msg.value must be 0");
        return
            _putChunkFromCalldata(
                keccak256(name),
                chunkId,
                data,
                StorageHelper.calculateValueForData(data.length, PER_CHUNK_SIZE, CODE_STAKING_PER_CHUNK)
            );
    }

    function removeChunk(bytes memory name, uint256 chunkId) public override onlyOperatorOrOwner returns (bool) {
        return _removeChunk(keccak256(name), chunkId);
    }

    function calculateValueForData(uint256 datalen) public pure returns (uint256) {
        return StorageHelper.calculateValueForData(datalen, PER_CHUNK_SIZE, CODE_STAKING_PER_CHUNK);
    }

    function storageSlotCodeLength() public pure returns (uint256) {
        return StorageHelper.storageSlotCodeLength();
    }
}


// File contracts/examples/SimpleFlatDirectory.sol

// License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleFlatDirectory is StorageManager {
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    bytes public defaultFile = "";
    address public owner;

    constructor(uint8 slotLimit) StorageManager(slotLimit) {
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function resolveMode() external pure virtual returns (bytes32) {
        return "auto";
    }

    fallback() external virtual {
        // looks like return data does not work, use assembly
        bytes memory data = files(defaultFile);
        bytes memory returnData = abi.encode(data);

        assembly {
            return(add(returnData, 0x20), mload(returnData))
        }
    }

    function setDefault(bytes memory _defaultFile) public {
        require(msg.sender == owner, "must from owner");
        defaultFile = _defaultFile;
    }

    function bytesToBytes32(bytes memory data) internal pure returns (bytes32) {
        bytes32 b32;
        assembly {
            b32 := mload(add(data, 0x20))
        }
        return b32;
    }

    function files(bytes memory filename) public view returns (bytes memory) {
        bytes32 b32 = bytesToBytes32(filename);
        (bytes memory data, ) = _get(b32);
        return data;
    }

    function write(bytes memory filename, bytes memory data) public payable {
        require(msg.sender == owner, "must from owner");
        bytes32 b32 = bytesToBytes32(filename);
        _put(b32, data, msg.value);
    }

    function remove(bytes memory filename) public returns (bool) {
        require(msg.sender == owner, "must from owner");
        bytes32 b32 = bytesToBytes32(filename);
        return _remove(b32);
    }

    function refund() public {
        require(msg.sender == owner, "must from owner");
        payable(owner).transfer(address(this).balance);
    }

    function destruct() public {
        require(msg.sender == owner, "must from owner");
        selfdestruct(payable(owner));
    }
}


// File contracts/examples/SimpleComment.sol

// License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleComment is SimpleFlatDirectory {

    constructor() SimpleFlatDirectory(0) {}

    function uintToBytes(uint v) internal pure returns (bytes memory) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        return s;
    }

    function uintToString(uint v) internal pure returns (string memory) {
        return string(uintToBytes(v));
    }

    function addressToBytes(address a) internal pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(
            add(m, 20),
            xor(0x140000000000000000000000000000000000000000, a)
            )
            mstore(0x40, add(m, 52))
            b := m
        }
    }

    function bytesToAddress(bytes memory bys) internal pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function writeComment(uint256 id, bytes memory content) public payable {
        write(abi.encodePacked(string(uintToString(id)), "comment"), content);
    }

    function writeOwner(uint256 id, address owner) public payable {
        write(abi.encodePacked(string(uintToString(id)), "owner"), addressToBytes(owner));
    }

    function writeTimestamp(uint256 id, uint256 timestamp) public payable {
        write(abi.encodePacked(string(uintToString(id)), "timestamp"), uintToBytes(timestamp));
    }

    function getComment(uint256 id) public view returns (bytes memory) {
        return files(abi.encodePacked(string(uintToString(id)), "comment"));
    }

    function getOwner(uint256 id) public view returns (address) {
        bytes memory content = files(abi.encodePacked(string(uintToString(id)), "owner"));
        return bytesToAddress(content);
    }

    function getTimestamp(uint256 id) public view returns (bytes memory) {
        return files(abi.encodePacked(string(uintToString(id)), "timestamp"));
    }

    function deleteComment(uint256 removeId, uint256 replaceId) public {
        bytes memory ownerId = abi.encodePacked(string(uintToString(replaceId)), "owner");
        bytes memory timestampId = abi.encodePacked(string(uintToString(replaceId)), "timestamp");
        bytes memory commentId = abi.encodePacked(string(uintToString(replaceId)), "comment");

        if (removeId != replaceId) {
            bytes memory owner = files(ownerId);
            write(abi.encodePacked(string(uintToString(removeId)), "owner"), owner);
            bytes memory timestamp = files(timestampId);
            write(abi.encodePacked(string(uintToString(removeId)), "timestamp"), timestamp);
            bytes memory comment = files(commentId);
            write(abi.encodePacked(string(uintToString(removeId)), "comment"), comment);
        }

        remove(ownerId);
        remove(timestampId);
        remove(commentId);
    }
}


// File contracts/examples/SimpleBlog.sol

// License-Identifier: MIT
pragma solidity ^0.8.0;



contract SimpleBlog is SimpleFlatDirectory {
    struct Blog {
        bytes title;
        uint256 timestamp; // 0 means deleted
    }

    struct CommentsInfo {
        address contractAddress;
        uint256 commentSize;
    }

    Blog[] public blogs;
    uint256 public blogLength;

    mapping(uint256 => CommentsInfo) public commentsList;

    address public assets;

    constructor() SimpleFlatDirectory(0) {
        FlatDirectory flat = new FlatDirectory(0);
        flat.changeOwner(msg.sender);
        assets = address(flat);
    }

    function writeBlog(bytes memory title, bytes memory content)
        public
        payable
    {
        uint256 idx = blogs.length;
        blogs.push(Blog(title, block.timestamp)); // solhint-disable-line not-rely-on-time
        blogLength++;
        write(abi.encodePacked(idx), content);

        // pre comment
        CommentsInfo storage info = commentsList[idx];
        SimpleComment comment = new SimpleComment();
        info.contractAddress = address(comment);
    }

    function editBlog(
        uint256 idx,
        bytes memory newTitle,
        bytes memory newContent
    ) public payable {
        Blog storage blog = blogs[idx];
        require(blog.timestamp != 0, "non-existent");
        blog.title = newTitle;
        blog.timestamp = block.timestamp; // solhint-disable-line not-rely-on-time
        write(abi.encodePacked(idx), newContent);
    }

    function deleteBlog(uint256 idx) public {
        blogs[idx].timestamp = 0;
        blogLength--;
        remove(abi.encodePacked(idx));
    }

    function listBlogs()
        public
        view
        returns (
            bytes[] memory titles,
            uint256[] memory timestamps,
            uint256[] memory idxList
        )
    {
        // TODO: pagination
        titles = new bytes[](blogLength);
        timestamps = new uint256[](blogLength);
        idxList = new uint256[](blogLength);
        uint256 pt = 0;

        for (uint256 i = 0; i < blogs.length; i++) {
            Blog memory b = blogs[i];
            if (b.timestamp != 0) {
                titles[pt] = b.title;
                timestamps[pt] = b.timestamp;
                idxList[pt] = i;
                pt++;
            }
        }
        return (titles, timestamps, idxList);
    }

    function getBlog(uint256 idx)
        public
        view
        returns (
            bytes memory title,
            uint256 timestamp,
            bytes memory content
        )
    {
        Blog memory blog = blogs[idx];
        content = files(abi.encodePacked(idx));
        return (blog.title, blog.timestamp, content);
    }

    function nextPost(uint256 idx) public view returns (uint256, bool) {
        while (idx < blogs.length - 1) {
            if (blogs[++idx].timestamp != 0) return (idx, true);
        }
        return (0, false);
    }

    function prevPost(uint256 idx) public view returns (uint256, bool) {
        while (idx != 0) {
            if (blogs[--idx].timestamp != 0) return (idx, true);
        }
        return (0, false);
    }


    function writeComment(uint256 idx, bytes memory content) public payable {
        CommentsInfo storage info = commentsList[idx];
        address contractAddress = info.contractAddress;
        require(contractAddress != address(0), "blog not exist");

        SimpleComment com = SimpleComment(contractAddress);
        com.writeComment(info.commentSize, content);
        com.writeOwner(info.commentSize, msg.sender);
        com.writeTimestamp(info.commentSize, block.timestamp);
        info.commentSize++;
    }

    function deleteComment(uint256 idx, uint256 commentId) public {
        CommentsInfo storage info = commentsList[idx];
        address contractAddress = info.contractAddress;
        require(contractAddress != address(0), "blog not exist");

        SimpleComment comment = SimpleComment(contractAddress);
        address owner = comment.getOwner(commentId);
        require(owner == msg.sender, "Only owner can delete");

        comment.deleteComment(commentId, info.commentSize);
        info.commentSize--;
    }

    function getComments(uint256 idx)
        public
        view
        returns (
            address[] memory users,
            bytes[] memory timestamps,
            bytes[] memory contents
        )
    {
        CommentsInfo storage info = commentsList[idx];
        address contractAddress = info.contractAddress;
        if (contractAddress == address(0)) {
            return (new address[](0), new bytes[](0), new bytes[](0));
        }

        uint256 commentSize = info.commentSize;
        users = new address[](commentSize);
        timestamps = new bytes[](commentSize);
        contents = new bytes[](commentSize);

        SimpleComment comment = SimpleComment(contractAddress);
        for (uint256 i = 0; i < commentSize; i++) {
            timestamps[i] = comment.getTimestamp(i);
            users[i] = comment.getOwner(i);
            contents[i] = comment.getComment(i);
        }
        return (users, timestamps, contents);
    }
}


// File contracts/examples/SimpleFlatDirectoryWithManualResolver.sol

// License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleFlatDirectoryWithManualResolver is SimpleFlatDirectory {
    constructor(uint8 slotLimit) SimpleFlatDirectory(slotLimit) {}

    function resolveMode() external pure override returns (bytes32) {
        return "manual";
    }

    fallback(bytes calldata cdata) external override returns (bytes memory) {
        bytes memory content;
        if (cdata.length == 0) {
            // TODO: redirect to "/"?
            return bytes("");
        } else if (cdata[0] != 0x2f) {
            // Should not happen since manual mode will have prefix "/" like "/....."
            return bytes("incorrect path");
        }

        if (cdata.length == 1) {
            content = files(defaultFile);
        } else {
            content = files(cdata[1:]);
        }

        bytes memory returnData = abi.encode(content);
        return returnData;
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// File contracts/examples/SimpleW3box.sol

// License-Identifier: MIT

pragma solidity ^0.8.0;


contract SimpleW3box {
    using Strings for uint256;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    struct File {
        uint256 time;
        bytes name;
        bytes fileType;
    }

    struct FilesInfo {
        File[] files;
        mapping(bytes32 => uint256) fileIds;
    }

    FlatDirectory public fileFD;

    address public owner;
    string public gateway;

    mapping(address => FilesInfo) fileInfos;

    constructor(string memory _gateway) {
        owner = msg.sender;
        gateway = _gateway;
        fileFD = new FlatDirectory(0);
    }

    receive() external payable {
    }

    function setGateway(string calldata _gateway) public isOwner {
        gateway = _gateway;
    }

    function write(bytes memory name, bytes memory fileType, bytes calldata data) public payable {
        writeChunk(name, fileType, 0, data);
    }

    function writeChunk(bytes memory name, bytes memory fileType, uint256 chunkId, bytes calldata data) public payable {
        bytes32 nameHash = keccak256(name);
        FilesInfo storage info = fileInfos[msg.sender];
        if (info.fileIds[nameHash] == 0) {
            // first add file
            info.files.push(File(block.timestamp, name, fileType));
            info.fileIds[nameHash] = info.files.length;
        }

        fileFD.writeChunk{value: msg.value}(getNewName(msg.sender, name), chunkId, data);
    }

    function remove(bytes memory name) public returns (uint256) {
        bytes32 nameHash = keccak256(name);
        FilesInfo storage info = fileInfos[msg.sender];
        require(info.fileIds[nameHash] != 0, "File does not exist");

        uint256 lastIndex = info.files.length - 1;
        uint256 removeIndex = info.fileIds[nameHash] - 1;
        if (lastIndex != removeIndex) {
            File storage lastFile = info.files[lastIndex];
            info.files[removeIndex] = lastFile;
            info.fileIds[keccak256(lastFile.name)] = removeIndex + 1;
        }
        info.files.pop();
        delete info.fileIds[nameHash];

        uint256 id = fileFD.remove(getNewName(msg.sender, name));
        fileFD.refund();
        payable(msg.sender).transfer(address(this).balance);
        return id;
    }

    function getChunkHash(bytes memory name, uint256 chunkId) public view returns (bytes32) {
        return fileFD.getChunkHash(getNewName(msg.sender, name), chunkId);
    }

    function countChunks(bytes memory name) public view returns (uint256) {
        return fileFD.countChunks(getNewName(msg.sender, name));
    }

    function getNewName(address author,bytes memory name) public pure returns (bytes memory) {
        return abi.encodePacked(
            Strings.toHexString(uint256(uint160(author)), 20),
            '/',
            name
        );
    }

    function getUrl(bytes memory name) public view returns (string memory) {
        return string(abi.encodePacked(
                gateway,
                'file.w3q/',
                name
            ));
    }

    function getAuthorFiles(address author)
        public view
        returns (
            uint256[] memory times,
            bytes[] memory names,
            bytes[] memory types,
            string[] memory urls
        )
    {
        uint256 length = fileInfos[author].files.length;
        times = new uint256[](length);
        names = new bytes[](length);
        types = new bytes[](length);
        urls = new string[](length);

        for (uint256 i; i < length; i++) {
            times[i] = fileInfos[author].files[i].time;
            names[i] = fileInfos[author].files[i].name;
            types[i] = fileInfos[author].files[i].fileType;
            urls[i] = getUrl(getNewName(author, names[i]));
        }
    }
}


// File contracts/optimize/SlotHelperTest.sol

// License-Identifier: MIT
pragma solidity ^0.8.0;

contract SlotHelperTest {
    mapping(bytes32 => bytes32) public metadatas;
    mapping(bytes32 => mapping(uint256 => bytes32)) public slots;

    function put(bytes32 key, bytes memory data) public {
        metadatas[key] = SlotHelper.putRaw(slots[key], data);
    }

    function get(bytes32 key) public view returns (bytes memory res) {
        bytes32 md = metadatas[key];
        res = SlotHelper.getRaw(slots[key], md);
    }

    function encodeMetadata(bytes memory data) public pure returns (bytes32) {
        return SlotHelper.encodeMetadata(data);
    }

    function decodeMetadata(bytes32 mdata) public pure returns (uint256, bytes32) {
        return SlotHelper.decodeMetadata(mdata);
    }

    function decodeMetadata1(bytes32 mdata) public pure returns (uint256, bytes memory) {
        return SlotHelper.decodeMetadataToData(mdata);
    }

    function encodeLen(uint256 datalen) public pure returns (bytes32) {
        return SlotHelper.encodeLen(datalen);
    }

    function decodeLen(bytes32 mdata) public pure returns (uint256 res) {
        res = SlotHelper.decodeLen(mdata);
    }

    function getLen(bytes32 key) public view returns (uint256 resLen) {
        bytes32 mdata = metadatas[key];
        resLen = SlotHelper.decodeLen(mdata);
    }
}


// File contracts/StorageManagerLocalTest.sol

// License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorageManagerLocalTest {
    mapping(bytes32 => bytes) localMap;

    // for gas metering
    function getWithoutView(bytes32 key) public returns (bytes memory) {
        return localMap[key];
    }

    function put(bytes32 key, bytes memory data) public {
        localMap[key] = data;
    }
}


// File contracts/examples/SimpleNameService.sol

// License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleNameService {
    mapping(bytes32 => address) public owners;
    mapping(bytes32 => address) public pointers;

    function bytesToBytes32(bytes memory data) public pure returns (bytes32) {
        bytes32 b32;
        assembly {
            b32 := mload(add(data, 0x20))
        }
        return b32;
    }

    function claim(bytes32 node) public {
        require(owners[node] == address(0x0), "already claimed");
        owners[node] = msg.sender;
    }

    function claimBy(bytes memory name) public {
        claim(bytesToBytes32(name));
    }

    function pointerOf(bytes memory name) public view returns (address) {
        return pointers[bytesToBytes32(name)];
    }

    function setPointer(bytes32 node, address addr) public {
        require(owners[node] == msg.sender, "must be owner");
        pointers[node] = addr;
    }
}