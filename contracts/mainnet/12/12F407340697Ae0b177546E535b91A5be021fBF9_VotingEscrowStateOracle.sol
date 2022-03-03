// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

import {RLPReader} from "RLPReader.sol";
import {StateProofVerifier as Verifier} from "StateProofVerifier.sol";

interface AnyCallProxy {
    function context() external view returns(address, uint256);
}

contract VotingEscrowStateOracle {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    struct Point {
        int128 bias;
        int128 slope;
        uint256 ts;
        uint256 blk;
    }

    /// Address of the voting escrow contract on Ethereum
    address constant VOTING_ESCROW = 0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2;
    /// Hash of the voting escrow contract address
    bytes32 constant VOTING_ESCROW_HASH = keccak256(abi.encodePacked(VOTING_ESCROW));

    /// `VotingEscrow.epoch()` storage slot hash
    bytes32 constant EPOCH_HASH = keccak256(abi.encode(3));

    /// Hash of the block header for the Ethereum genesis block
    bytes32 constant GENESIS_BLOCKHASH = 0xd4e56740f876aef8c010b86a40d5f56745a118d0906a34e69aec8c0db1cb8fa3;
    /// Week in seconds
    uint256 constant WEEK = 1 weeks;

    /// Address of the AnyCallProxy for the chain this contract is deployed on
    address public immutable ANYCALL;

    /// Mapping of Ethereum block number to blockhash
    mapping(uint256 => bytes32) private _eth_blockhash;
    /// Last Ethereum block number which had its blockhash stored
    uint256 public last_eth_block_number;

    /// Owner of the contract with special privileges
    address public owner;
    /// Future owner of the contract
    address public future_owner;

    /// Migrated `VotingEscrow` storage variables
    uint256 public epoch;
    Point[100000000000000000000000000000] public point_history;
    mapping(address => uint256) public user_point_epoch;
    mapping(address => Point[1000000000]) public user_point_history;

    mapping(uint256 => int128) public slope_changes;
    mapping(address => LockedBalance) public locked;
    mapping(bytes32 => bool) public submitted_hashes;

    /// Log a blockhash update
    event SetBlockhash(uint256 _eth_block_number, bytes32 _eth_blockhash);
    /// Log a transfer of ownership
    event TransferOwnership(address _old_owner, address _new_owner);
    /// Log a proof submission
    event SubmittedState(address _user, bytes32 blockhash, bytes32 proofhash);

    constructor(address _anycall) {
        _eth_blockhash[0] = GENESIS_BLOCKHASH;
        emit SetBlockhash(0, GENESIS_BLOCKHASH);

        // Mar-02-2022 07:06:57 PM +UTC
        _eth_blockhash[14309414] = 0xa460e43297d3f7a92ee5dd34ee39a20b941dfc805a7dbfa99e892214d5da026c;
        emit SetBlockhash(14309414, 0xa460e43297d3f7a92ee5dd34ee39a20b941dfc805a7dbfa99e892214d5da026c);
        last_eth_block_number = 14309414;

        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);

        ANYCALL = _anycall;
    }

    function balanceOf(address _user) external view returns(uint256) {
        return balanceOf(_user, block.timestamp);
    }

    function balanceOf(address _user, uint256 _timestamp) public view returns(uint256) {
        uint256 _epoch = user_point_epoch[_user];
        if (_epoch == 0) {
            return 0;
        }
        Point memory last_point = user_point_history[_user][_epoch];
        last_point.bias -= last_point.slope * abi.decode(abi.encode(_timestamp - last_point.ts), (int128));
        if (last_point.bias < 0) {
            return 0;
        }
        return abi.decode(abi.encode(last_point.bias), (uint256));
    }

    function totalSupply() external view returns(uint256) {
        return totalSupply(block.timestamp);
    }

    function totalSupply(uint256 _timestamp) public view returns(uint256) {
        Point memory last_point = point_history[epoch];
        uint256 t_i = (last_point.ts / WEEK) * WEEK;  // value in the past
        for (uint256 i = 0; i < 255; i++) {
            t_i += WEEK;  // + week
            int128 d_slope = 0;
            if (t_i > _timestamp) {
                t_i = _timestamp;
            } else {
                d_slope = slope_changes[t_i];
                if (d_slope == 0) {
                    break;
                }
            }
            last_point.bias -= last_point.slope * abi.decode(abi.encode(t_i - last_point.ts), (int128));
            if (t_i == _timestamp) {
                break;
            }
            last_point.slope += d_slope;
            last_point.ts = t_i;
        }

        if (last_point.bias < 0) {
            return 0;
        }
        return abi.decode(abi.encode(last_point.bias), (uint256));
    }

    function submit_state(address _user, bytes memory _block_header_rlp, bytes memory _proof_rlp) external {
        // verify block header
        Verifier.BlockHeader memory block_header = Verifier.parseBlockHeader(_block_header_rlp);
        require(block_header.hash != bytes32(0)); // dev: invalid blockhash
        require(block_header.hash == _eth_blockhash[block_header.number]); // dev: blockhash mismatch

        // convert _proof_rlp into a list of `RLPItem`s
        RLPReader.RLPItem[] memory proofs = _proof_rlp.toRlpItem().toList();
        require(proofs.length == 21); // dev: invalid number of proofs

        // 0th proof is the account proof for Voting Escrow contract
        Verifier.Account memory ve_account = Verifier.extractAccountFromProof(
            VOTING_ESCROW_HASH, // position of the account is the hash of its address
            block_header.stateRootHash,
            proofs[0].toList()
        );
        require(ve_account.exists); // dev: Voting Escrow account does not exist

        // 1st proof is the `VotingEscrow.epoch()` storage slot proof
        Verifier.SlotValue memory slot_epoch = Verifier.extractSlotValueFromProof(
            EPOCH_HASH,
            ve_account.storageRoot,
            proofs[1].toList()
        );
        require(slot_epoch.exists);

        // 2-5th proof are the `VotingEscrow.point_history(uint256)` slots
        // this is a struct where bias and slope are int128, the position is determined based
        // on the value of `epoch`
        Verifier.SlotValue[4] memory slot_point_history;
        for (uint256 i = 0; i < 4; i++) {
            slot_point_history[i] = Verifier.extractSlotValueFromProof(
                keccak256(abi.encode(uint256(keccak256(abi.encode(uint256(keccak256(abi.encode(4))) + slot_epoch.value))) + i)),
                ve_account.storageRoot,
                proofs[2 + i].toList()
            );
            require(slot_point_history[i].exists); // dev: slot does not exist
        }

        // 6th proof is the `VotingEscrow.user_point_epoch(address)` slot proof
        Verifier.SlotValue memory slot_user_point_epoch = Verifier.extractSlotValueFromProof(
            keccak256(abi.encode(keccak256(abi.encode(6, _user)))),
            ve_account.storageRoot,
            proofs[6].toList()
        );
        require(slot_user_point_epoch.exists); // dev: slot does not exist

        // 7-10th proof are for `VotingEscrow.user_point_history` slots
        // similar to `point_history` this is a struct
        Verifier.SlotValue[4] memory slot_user_point_history;
        for (uint256 i = 0; i < 4; i++) {
            slot_user_point_history[i] = Verifier.extractSlotValueFromProof(
                keccak256(abi.encode(uint256(keccak256(abi.encode(uint256(keccak256(abi.encode(keccak256(abi.encode(5, _user))))) + slot_user_point_epoch.value))) + i)),
                ve_account.storageRoot,
                proofs[7 + i].toList()
            );
            require(slot_user_point_history[i].exists); // dev: slot does not exist
        }

        // 11-12th proof are for `VotingEscrow.locked()` this is a struct with 2 members
        Verifier.SlotValue[2] memory slot_locked;
        for (uint256 i = 0; i < 2; i++) {
            slot_locked[i] = Verifier.extractSlotValueFromProof(
                keccak256(abi.encode(uint256(keccak256(abi.encode(keccak256(abi.encode(2, _user))))) + i)),
                ve_account.storageRoot,
                proofs[11 + i].toList()
            );
            require(slot_locked[i].exists); // dev: slot does not exist
        }

        // Remaining proofs are for 2 months worth of slope changes
        // starting from the week beginning the last global point
        Verifier.SlotValue[8] memory slot_slope_changes;
        uint256 start_time = (slot_point_history[2].value / WEEK) * WEEK + WEEK;
        for (uint256 i = 0; i < 8; i++) {
            slot_slope_changes[i] = Verifier.extractSlotValueFromProof(
                keccak256(abi.encode(keccak256(abi.encode(7, start_time + WEEK * i)))),
                ve_account.storageRoot,
                proofs[13 + i].toList()
            );
            require(slot_slope_changes[i].exists); // dev: slot does not exist
        }

        {
            /// incrememt the epoch storage var only if fresh
            /// also update slope changes too
            if (slot_epoch.value > epoch) {
                epoch = slot_epoch.value;

                for (uint256 i = 0; i < 8; i++) {
                    slope_changes[start_time + WEEK * i] = abi.decode(abi.encode(slot_slope_changes[i].value), (int128));
                }
            }
            /// always set the point_history structs
            point_history[slot_epoch.value] = Point(
                abi.decode(abi.encode(slot_point_history[0].value), (int128)), // bias
                abi.decode(abi.encode(slot_point_history[1].value), (int128)), // slope
                slot_point_history[2].value, // ts
                slot_point_history[3].value // blk
            );

            // update the user point epoch and locked balance if it is newer
            if (slot_user_point_epoch.value > user_point_epoch[_user]) {
                user_point_epoch[_user] = slot_user_point_epoch.value;

                locked[_user] = LockedBalance(
                    abi.decode(abi.encode(slot_locked[0].value), (int128)),
                    slot_locked[1].value
                );
            }
            /// always set the point_history structs
            user_point_history[_user][slot_user_point_epoch.value] = Point(
                abi.decode(abi.encode(slot_user_point_history[0].value), (int128)), // bias
                abi.decode(abi.encode(slot_user_point_history[1].value), (int128)), // slope
                slot_user_point_history[2].value, // ts
                slot_user_point_history[3].value // blk
            );
        }

        emit SubmittedState(_user, block_header.hash, keccak256(_proof_rlp));
    }

    /**
      * @notice Get the Ethereum blockhash for block number `_eth_block_number`
      * @dev Reverts if the blockhash is unavailable, value in storage is `bytes32(0)`
      * @param _eth_block_number The block number to query the blockhash of
      * @return eth_blockhash The blockhash of `_eth_block_number`
      */
    function get_eth_blockhash(uint256 _eth_block_number) external view returns(bytes32 eth_blockhash) {
        eth_blockhash = _eth_blockhash[_eth_block_number];
        require(eth_blockhash != bytes32(0)); // dev: blockhash unavailable
    }

    /**
      * @notice Set the Ethereum blockhash for `_eth_block_number` in storage
      * @param _eth_block_number The block number to set the blockhash of
      * @param __eth_blockhash The blockhash to set in storage
      */
    function set_eth_blockhash(uint256 _eth_block_number, bytes32 __eth_blockhash) external {
        // either a cross-chain call from `self` or `owner` is valid to set the blockhash
        if (msg.sender == ANYCALL) {
           (address sender, uint256 from_chain_id) = AnyCallProxy(msg.sender).context();
           require(sender == address(this) && from_chain_id == 1); // dev: only root self
        } else {
            require(msg.sender == owner); // dev: only owner
        }

        // set the blockhash in storage
        _eth_blockhash[_eth_block_number] = __eth_blockhash;
        emit SetBlockhash(_eth_block_number, __eth_blockhash);

        // update the last block number stored
        if (_eth_block_number > last_eth_block_number) {
            last_eth_block_number = _eth_block_number;
        }

    }

    /**
      * @notice Commit the future owner to storage for later transfer to
      * @param _future_owner The address of the future owner
      */
    function commit_transfer_ownership(address _future_owner) external {
        require(msg.sender == owner); // dev: only owner
        future_owner = _future_owner;
    }

    /**
      * @notice Accept the transfer of ownership
      * @dev Only callable by the future owner
      */
    function accept_transfer_ownership() external {
        require(msg.sender == future_owner); // dev: only future owner
        emit TransferOwnership(owner, msg.sender);
        owner = msg.sender;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
* @author Hamdi Allam [email protected]
* Please reach out with any questions or concerns
*/
pragma solidity >=0.8.12;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START  = 0xb8;
    uint8 constant LIST_SHORT_START   = 0xc0;
    uint8 constant LIST_LONG_START    = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    struct Iterator {
        RLPItem item;   // Item that's being iterated over.
        uint nextPtr;   // Position of the next item in the list.
    }

    /*
    * @dev Returns the next element in the iteration. Reverts if it has not next element.
    * @param self The iterator.
    * @return The next element in the iteration.
    */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint ptr = self.nextPtr;
        uint itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
    * @dev Returns true if the iteration has more elements.
    * @param self The iterator.
    * @return true if the iteration has more elements.
    */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
    * @param item RLP encoded bytes
    */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
    * @dev Create an iterator. Reverts if item is not a list.
    * @param self The RLP item.
    * @return An 'Iterator' over the item.
    */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
    * @param the RLP item.
    */
    function rlpLen(RLPItem memory item) internal pure returns (uint) {
        return item.len;
    }

    /*
     * @param the RLP item.
     * @return (memPtr, len) pair: location of the item's payload in memory.
     */
    function payloadLocation(RLPItem memory item) internal pure returns (uint, uint) {
        uint offset = _payloadOffset(item.memPtr);
        uint memPtr = item.memPtr + offset;
        uint len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
    * @param the RLP item.
    */
    function payloadLen(RLPItem memory item) internal pure returns (uint) {
        (, uint len) = payloadLocation(item);
        return len;
    }

    /*
    * @param the RLP item containing the encoded list.
    */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint memPtr, uint len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte except "0x80" is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        // SEE Github Issue #5.
        // Summary: Most commonly used RLP libraries (i.e Geth) will encode
        // "0" as "0x80" instead of as "0". We handle this edge case explicitly
        // here.
        if (result == 0 || result == STRING_SHORT_START) {
            return false;
        } else {
            return true;
        }
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        require(item.len > 0 && item.len <= 33);

        (uint memPtr, uint len) = payloadLocation(item);

        uint result;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint) {
        // one byte prefix
        require(item.len == 33);

        uint result;
        uint memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        (uint memPtr, uint len) = payloadLocation(item);
        bytes memory result = new bytes(len);

        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(memPtr, destPtr, len);
        return result;
    }

    /*
    * Private Helpers
    */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint) {
        if (item.len == 0) return 0;

        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
           currPtr = currPtr + _itemLength(currPtr); // skip over an item
           count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint memPtr) private pure returns (uint) {
        uint itemLen;
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            itemLen = 1;

        else if (byte0 < STRING_LONG_START)
            itemLen = byte0 - STRING_SHORT_START + 1;

        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        }

        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint memPtr) private pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)  // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /*
    * @param src Pointer to source
    * @param dest Pointer to destination
    * @param len Amount of memory to copy from the source
    */
    function copy(uint src, uint dest, uint len) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len > 0) {
            // left over bytes. Mask is used to remove unwanted bytes from the word
            uint mask = 256 ** (WORD_SIZE - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask)) // zero out src
                let destpart := and(mload(dest), mask) // retrieve the bytes
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.12;

import {RLPReader} from "RLPReader.sol";
import {MerklePatriciaProofVerifier} from "MerklePatriciaProofVerifier.sol";


/**
 * @title A helper library for verification of Merkle Patricia account and state proofs.
 */
library StateProofVerifier {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    uint256 constant HEADER_STATE_ROOT_INDEX = 3;
    uint256 constant HEADER_NUMBER_INDEX = 8;
    uint256 constant HEADER_TIMESTAMP_INDEX = 11;

    struct BlockHeader {
        bytes32 hash;
        bytes32 stateRootHash;
        uint256 number;
        uint256 timestamp;
    }

    struct Account {
        bool exists;
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
    }

    struct SlotValue {
        bool exists;
        uint256 value;
    }


    /**
     * @notice Parses block header and verifies its presence onchain within the latest 256 blocks.
     * @param _headerRlpBytes RLP-encoded block header.
     */
    function verifyBlockHeader(bytes memory _headerRlpBytes)
        internal view returns (BlockHeader memory)
    {
        BlockHeader memory header = parseBlockHeader(_headerRlpBytes);
        // ensure that the block is actually in the blockchain
        require(header.hash == blockhash(header.number), "blockhash mismatch");
        return header;
    }


    /**
     * @notice Parses RLP-encoded block header.
     * @param _headerRlpBytes RLP-encoded block header.
     */
    function parseBlockHeader(bytes memory _headerRlpBytes)
        internal pure returns (BlockHeader memory)
    {
        BlockHeader memory result;
        RLPReader.RLPItem[] memory headerFields = _headerRlpBytes.toRlpItem().toList();

        require(headerFields.length > HEADER_TIMESTAMP_INDEX);

        result.stateRootHash = bytes32(headerFields[HEADER_STATE_ROOT_INDEX].toUint());
        result.number = headerFields[HEADER_NUMBER_INDEX].toUint();
        result.timestamp = headerFields[HEADER_TIMESTAMP_INDEX].toUint();
        result.hash = keccak256(_headerRlpBytes);

        return result;
    }


    /**
     * @notice Verifies Merkle Patricia proof of an account and extracts the account fields.
     *
     * @param _addressHash Keccak256 hash of the address corresponding to the account.
     * @param _stateRootHash MPT root hash of the Ethereum state trie.
     */
    function extractAccountFromProof(
        bytes32 _addressHash, // keccak256(abi.encodePacked(address))
        bytes32 _stateRootHash,
        RLPReader.RLPItem[] memory _proof
    )
        internal pure returns (Account memory)
    {
        bytes memory acctRlpBytes = MerklePatriciaProofVerifier.extractProofValue(
            _stateRootHash,
            abi.encodePacked(_addressHash),
            _proof
        );

        Account memory account;

        if (acctRlpBytes.length == 0) {
            return account;
        }

        RLPReader.RLPItem[] memory acctFields = acctRlpBytes.toRlpItem().toList();
        require(acctFields.length == 4);

        account.exists = true;
        account.nonce = acctFields[0].toUint();
        account.balance = acctFields[1].toUint();
        account.storageRoot = bytes32(acctFields[2].toUint());
        account.codeHash = bytes32(acctFields[3].toUint());

        return account;
    }


    /**
     * @notice Verifies Merkle Patricia proof of a slot and extracts the slot's value.
     *
     * @param _slotHash Keccak256 hash of the slot position.
     * @param _storageRootHash MPT root hash of the account's storage trie.
     */
    function extractSlotValueFromProof(
        bytes32 _slotHash,
        bytes32 _storageRootHash,
        RLPReader.RLPItem[] memory _proof
    )
        internal pure returns (SlotValue memory)
    {
        bytes memory valueRlpBytes = MerklePatriciaProofVerifier.extractProofValue(
            _storageRootHash,
            abi.encodePacked(_slotHash),
            _proof
        );

        SlotValue memory value;

        if (valueRlpBytes.length != 0) {
            value.exists = true;
            value.value = valueRlpBytes.toRlpItem().toUint();
        }

        return value;
    }

}

// SPDX-License-Identifier: MIT

/**
 * Copied from https://github.com/lorenzb/proveth/blob/c74b20e/onchain/ProvethVerifier.sol
 * with minor performance and code style-related modifications.
 */
pragma solidity >=0.8.12;

import {RLPReader} from "RLPReader.sol";


library MerklePatriciaProofVerifier {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    /// @dev Validates a Merkle-Patricia-Trie proof.
    ///      If the proof proves the inclusion of some key-value pair in the
    ///      trie, the value is returned. Otherwise, i.e. if the proof proves
    ///      the exclusion of a key from the trie, an empty byte array is
    ///      returned.
    /// @param rootHash is the Keccak-256 hash of the root node of the MPT.
    /// @param path is the key of the node whose inclusion/exclusion we are
    ///        proving.
    /// @param stack is the stack of MPT nodes (starting with the root) that
    ///        need to be traversed during verification.
    /// @return value whose inclusion is proved or an empty byte array for
    ///         a proof of exclusion
    function extractProofValue(
        bytes32 rootHash,
        bytes memory path,
        RLPReader.RLPItem[] memory stack
    ) internal pure returns (bytes memory value) {
        bytes memory mptKey = _decodeNibbles(path, 0);
        uint256 mptKeyOffset = 0;

        bytes32 nodeHashHash;
        RLPReader.RLPItem[] memory node;

        RLPReader.RLPItem memory rlpValue;

        if (stack.length == 0) {
            // Root hash of empty Merkle-Patricia-Trie
            require(rootHash == 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421);
            return new bytes(0);
        }

        // Traverse stack of nodes starting at root.
        for (uint256 i = 0; i < stack.length; i++) {

            // We use the fact that an rlp encoded list consists of some
            // encoding of its length plus the concatenation of its
            // *rlp-encoded* items.

            // The root node is hashed with Keccak-256 ...
            if (i == 0 && rootHash != stack[i].rlpBytesKeccak256()) {
                revert();
            }
            // ... whereas all other nodes are hashed with the MPT
            // hash function.
            if (i != 0 && nodeHashHash != _mptHashHash(stack[i])) {
                revert();
            }
            // We verified that stack[i] has the correct hash, so we
            // may safely decode it.
            node = stack[i].toList();

            if (node.length == 2) {
                // Extension or Leaf node

                bool isLeaf;
                bytes memory nodeKey;
                (isLeaf, nodeKey) = _merklePatriciaCompactDecode(node[0].toBytes());

                uint256 prefixLength = _sharedPrefixLength(mptKeyOffset, mptKey, nodeKey);
                mptKeyOffset += prefixLength;

                if (prefixLength < nodeKey.length) {
                    // Proof claims divergent extension or leaf. (Only
                    // relevant for proofs of exclusion.)
                    // An Extension/Leaf node is divergent iff it "skips" over
                    // the point at which a Branch node should have been had the
                    // excluded key been included in the trie.
                    // Example: Imagine a proof of exclusion for path [1, 4],
                    // where the current node is a Leaf node with
                    // path [1, 3, 3, 7]. For [1, 4] to be included, there
                    // should have been a Branch node at [1] with a child
                    // at 3 and a child at 4.

                    // Sanity check
                    if (i < stack.length - 1) {
                        // divergent node must come last in proof
                        revert();
                    }

                    return new bytes(0);
                }

                if (isLeaf) {
                    // Sanity check
                    if (i < stack.length - 1) {
                        // leaf node must come last in proof
                        revert();
                    }

                    if (mptKeyOffset < mptKey.length) {
                        return new bytes(0);
                    }

                    rlpValue = node[1];
                    return rlpValue.toBytes();
                } else { // extension
                    // Sanity check
                    if (i == stack.length - 1) {
                        // shouldn't be at last level
                        revert();
                    }

                    if (!node[1].isList()) {
                        // rlp(child) was at least 32 bytes. node[1] contains
                        // Keccak256(rlp(child)).
                        nodeHashHash = node[1].payloadKeccak256();
                    } else {
                        // rlp(child) was less than 32 bytes. node[1] contains
                        // rlp(child).
                        nodeHashHash = node[1].rlpBytesKeccak256();
                    }
                }
            } else if (node.length == 17) {
                // Branch node

                if (mptKeyOffset != mptKey.length) {
                    // we haven't consumed the entire path, so we need to look at a child
                    uint8 nibble = uint8(mptKey[mptKeyOffset]);
                    mptKeyOffset += 1;
                    if (nibble >= 16) {
                        // each element of the path has to be a nibble
                        revert();
                    }

                    if (_isEmptyBytesequence(node[nibble])) {
                        // Sanity
                        if (i != stack.length - 1) {
                            // leaf node should be at last level
                            revert();
                        }

                        return new bytes(0);
                    } else if (!node[nibble].isList()) {
                        nodeHashHash = node[nibble].payloadKeccak256();
                    } else {
                        nodeHashHash = node[nibble].rlpBytesKeccak256();
                    }
                } else {
                    // we have consumed the entire mptKey, so we need to look at what's contained in this node.

                    // Sanity
                    if (i != stack.length - 1) {
                        // should be at last level
                        revert();
                    }

                    return node[16].toBytes();
                }
            }
        }
    }


    /// @dev Computes the hash of the Merkle-Patricia-Trie hash of the RLP item.
    ///      Merkle-Patricia-Tries use a weird "hash function" that outputs
    ///      *variable-length* hashes: If the item is shorter than 32 bytes,
    ///      the MPT hash is the item. Otherwise, the MPT hash is the
    ///      Keccak-256 hash of the item.
    ///      The easiest way to compare variable-length byte sequences is
    ///      to compare their Keccak-256 hashes.
    /// @param item The RLP item to be hashed.
    /// @return Keccak-256(MPT-hash(item))
    function _mptHashHash(RLPReader.RLPItem memory item) private pure returns (bytes32) {
        if (item.len < 32) {
            return item.rlpBytesKeccak256();
        } else {
            return keccak256(abi.encodePacked(item.rlpBytesKeccak256()));
        }
    }

    function _isEmptyBytesequence(RLPReader.RLPItem memory item) private pure returns (bool) {
        if (item.len != 1) {
            return false;
        }
        uint8 b;
        uint256 memPtr = item.memPtr;
        assembly {
            b := byte(0, mload(memPtr))
        }
        return b == 0x80 /* empty byte string */;
    }


    function _merklePatriciaCompactDecode(bytes memory compact) private pure returns (bool isLeaf, bytes memory nibbles) {
        require(compact.length > 0);
        uint256 first_nibble = uint8(compact[0]) >> 4 & 0xF;
        uint256 skipNibbles;
        if (first_nibble == 0) {
            skipNibbles = 2;
            isLeaf = false;
        } else if (first_nibble == 1) {
            skipNibbles = 1;
            isLeaf = false;
        } else if (first_nibble == 2) {
            skipNibbles = 2;
            isLeaf = true;
        } else if (first_nibble == 3) {
            skipNibbles = 1;
            isLeaf = true;
        } else {
            // Not supposed to happen!
            revert();
        }
        return (isLeaf, _decodeNibbles(compact, skipNibbles));
    }


    function _decodeNibbles(bytes memory compact, uint256 skipNibbles) private pure returns (bytes memory nibbles) {
        require(compact.length > 0);

        uint256 length = compact.length * 2;
        require(skipNibbles <= length);
        length -= skipNibbles;

        nibbles = new bytes(length);
        uint256 nibblesLength = 0;

        for (uint256 i = skipNibbles; i < skipNibbles + length; i += 1) {
            if (i % 2 == 0) {
                nibbles[nibblesLength] = bytes1((uint8(compact[i/2]) >> 4) & 0xF);
            } else {
                nibbles[nibblesLength] = bytes1((uint8(compact[i/2]) >> 0) & 0xF);
            }
            nibblesLength += 1;
        }

        assert(nibblesLength == nibbles.length);
    }


    function _sharedPrefixLength(uint256 xsOffset, bytes memory xs, bytes memory ys) private pure returns (uint256) {
        uint256 i;
        for (i = 0; i + xsOffset < xs.length && i < ys.length; i++) {
            if (xs[i + xsOffset] != ys[i]) {
                return i;
            }
        }
        return i;
    }
}