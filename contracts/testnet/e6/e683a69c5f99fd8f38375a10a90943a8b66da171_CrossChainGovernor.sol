// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "solidity-merkle-trees/trie/Bytes.sol";

import "../interfaces/IIsmpModule.sol";
import "../interfaces/IIsmpHost.sol";
import "../interfaces/StateMachine.sol";

struct GovernorParams {
    address admin;
    address host;
    uint256 paraId;
}

contract CrossChainGovernor is IIsmpModule {
    using Bytes for bytes;

    GovernorParams private _params;

    modifier onlyIsmpHost() {
        require(msg.sender == _params.host, "CrossChainGovernor: Invalid caller");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == _params.admin, "CrossChainGovernor: Invalid caller");
        _;
    }

    constructor(GovernorParams memory params) {
        _params = params;
    }

    // This function can only be called once by the admin to set the IsmpHost.
    // This exists to seal the cyclic dependency between this contract & the ismp host.
    function setIsmpHost(address host) public onlyAdmin {
        _params.host = host;
        _params.admin = address(0);
    }

    function onAccept(PostRequest memory request) external onlyIsmpHost {
        require(request.source.equals(StateMachine.polkadot(_params.paraId)), "Unauthorized request");
        (
            address admin,
            address consensus,
            address handler,
            uint256 challengePeriod,
            uint256 unstakingPeriod,
            uint256 defaultTimeout
        ) = abi.decode(request.body, (address, address, address, uint256, uint256, uint256));

        BridgeParams memory params =
            BridgeParams(admin, consensus, handler, challengePeriod, unstakingPeriod, defaultTimeout);

        IIsmpHost(_params.host).setBridgeParams(params);
    }

    function onPostResponse(PostResponse memory response) external pure {
        revert("Module doesn't emit requests");
    }

    function onGetResponse(GetResponse memory response) external pure {
        revert("Module doesn't emit requests");
    }

    function onPostTimeout(PostRequest memory request) external pure {
        revert("Module doesn't emit requests");
    }

    function onGetTimeout(GetRequest memory request) external pure {
        revert("Module doesn't emit requests");
    }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: Apache2

import {Memory} from "./Memory.sol";

struct ByteSlice {
    bytes data;
    uint256 offset;
}

library Bytes {
    uint256 internal constant BYTES_HEADER_SIZE = 32;

    // Checks if two `bytes memory` variables are equal. This is done using hashing,
    // which is much more gas efficient then comparing each byte individually.
    // Equality means that:
    //  - 'self.length == other.length'
    //  - For 'n' in '[0, self.length)', 'self[n] == other[n]'
    function equals(bytes memory self, bytes memory other) internal pure returns (bool equal) {
        if (self.length != other.length) {
            return false;
        }
        uint256 addr;
        uint256 addr2;
        assembly {
            addr := add(self, /*BYTES_HEADER_SIZE*/ 32)
            addr2 := add(other, /*BYTES_HEADER_SIZE*/ 32)
        }
        equal = Memory.equals(addr, addr2, self.length);
    }

    function readByte(ByteSlice memory self) internal pure returns (uint8) {
        if (self.offset + 1 > self.data.length) {
            revert("Out of range");
        }

        uint8 b = uint8(self.data[self.offset]);
        self.offset += 1;

        return b;
    }

    // Copies 'len' bytes from 'self' into a new array, starting at the provided 'startIndex'.
    // Returns the new copy.
    // Requires that:
    //  - 'startIndex + len <= self.length'
    // The length of the substring is: 'len'
    function read(ByteSlice memory self, uint256 len) internal pure returns (bytes memory) {
        require(self.offset + len <= self.data.length);
        if (len == 0) {
            return "";
        }
        uint256 addr = Memory.dataPtr(self.data);
        bytes memory slice = Memory.toBytes(addr + self.offset, len);
        self.offset += len;
        return slice;
    }

    // Copies a section of 'self' into a new array, starting at the provided 'startIndex'.
    // Returns the new copy.
    // Requires that 'startIndex <= self.length'
    // The length of the substring is: 'self.length - startIndex'
    function substr(bytes memory self, uint256 startIndex) internal pure returns (bytes memory) {
        require(startIndex <= self.length);
        uint256 len = self.length - startIndex;
        uint256 addr = Memory.dataPtr(self);
        return Memory.toBytes(addr + startIndex, len);
    }

    // Copies 'len' bytes from 'self' into a new array, starting at the provided 'startIndex'.
    // Returns the new copy.
    // Requires that:
    //  - 'startIndex + len <= self.length'
    // The length of the substring is: 'len'
    function substr(bytes memory self, uint256 startIndex, uint256 len) internal pure returns (bytes memory) {
        require(startIndex + len <= self.length);
        if (len == 0) {
            return "";
        }
        uint256 addr = Memory.dataPtr(self);
        return Memory.toBytes(addr + startIndex, len);
    }

    // Combines 'self' and 'other' into a single array.
    // Returns the concatenated arrays:
    //  [self[0], self[1], ... , self[self.length - 1], other[0], other[1], ... , other[other.length - 1]]
    // The length of the new array is 'self.length + other.length'
    function concat(bytes memory self, bytes memory other) internal pure returns (bytes memory) {
        bytes memory ret = new bytes(self.length + other.length);
        uint256 src;
        uint256 srcLen;
        (src, srcLen) = Memory.fromBytes(self);
        uint256 src2;
        uint256 src2Len;
        (src2, src2Len) = Memory.fromBytes(other);
        uint256 dest;
        (dest,) = Memory.fromBytes(ret);
        uint256 dest2 = dest + srcLen;
        Memory.copy(src, dest, srcLen);
        Memory.copy(src2, dest2, src2Len);
        return ret;
    }

    function toBytes32(bytes memory self) internal pure returns (bytes32 out) {
        require(self.length >= 32, "Bytes:: toBytes32: data is to short.");
        assembly {
            out := mload(add(self, 32))
        }
    }

    function toBytes16(bytes memory self, uint256 offset) internal pure returns (bytes16 out) {
        for (uint256 i = 0; i < 16; i++) {
            out |= bytes16(bytes1(self[offset + i]) & 0xFF) >> (i * 8);
        }
    }

    function toBytes8(bytes memory self, uint256 offset) internal pure returns (bytes8 out) {
        for (uint256 i = 0; i < 8; i++) {
            out |= bytes8(bytes1(self[offset + i]) & 0xFF) >> (i * 8);
        }
    }

    function toBytes4(bytes memory self, uint256 offset) internal pure returns (bytes4) {
        bytes4 out;

        for (uint256 i = 0; i < 4; i++) {
            out |= bytes4(self[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function toBytes2(bytes memory self, uint256 offset) internal pure returns (bytes2) {
        bytes2 out;

        for (uint256 i = 0; i < 2; i++) {
            out |= bytes2(self[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function removeLeadingZero(bytes memory data) internal pure returns (bytes memory) {
        uint256 length = data.length;

        uint256 startIndex = 0;
        for (uint256 i = 0; i < length; i++) {
            if (data[i] != 0) {
                startIndex = i;
                break;
            }
        }

        return substr(data, startIndex);
    }

    function removeEndingZero(bytes memory data) internal pure returns (bytes memory) {
        uint256 length = data.length;

        uint256 endIndex = 0;
        for (uint256 i = length - 1; i >= 0; i--) {
            if (data[i] != 0) {
                endIndex = i;
                break;
            }
        }

        return substr(data, 0, endIndex + 1);
    }

    function reverse(bytes memory inbytes) internal pure returns (bytes memory) {
        uint256 inlength = inbytes.length;
        bytes memory outbytes = new bytes(inlength);

        for (uint256 i = 0; i <= inlength - 1; i++) {
            outbytes[i] = inbytes[inlength - i - 1];
        }

        return outbytes;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./IIsmpDispatcher.sol";

interface IIsmpModule {
    /**
     * @dev Called by the local ISMP router on a module, to notify module of a new request the module may choose to respond immediately, or in a later block
     * @param request post request
     */
    function onAccept(PostRequest memory request) external;

    /**
     * @dev Called by the router on a module, to notify module of a post response to a previously sent out request
     * @param response post response
     */
    function onPostResponse(PostResponse memory response) external;

    /**
     * @dev Called by the router on a module, to notify module of a get response to a previously sent out request
     * @param response get response
     */
    function onGetResponse(GetResponse memory response) external;

    /**
     * @dev Called by the router on a module, to notify module of post requests that were previously sent but have now timed-out
     * @param request post request
     */
    function onPostTimeout(PostRequest memory request) external;

    /**
     * @dev Called by the router on a module, to notify module of get requests that were previously sent but have now timed-out
     * @param request get request
     */
    function onGetTimeout(GetRequest memory request) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {StateCommitment, StateMachineHeight} from "./IConsensusClient.sol";
import {IIsmpDispatcher, PostRequest, PostResponse, GetResponse, PostTimeout, GetRequest} from "./IIsmpDispatcher.sol";

struct BridgeParams {
    address admin;
    address consensus;
    address handler;
    uint256 challengePeriod;
    uint256 unstakingPeriod;
    uint256 defaultTimeout;
}

interface IIsmpHost is IIsmpDispatcher {
    /**
     * @return the host admin
     */
    function admin() external returns (address);

    /**
     * @return the host state machine id
     */
    function host() external returns (bytes memory);

    /**
     * @return the host timestamp
     */
    function timestamp() external returns (uint256);

    /**
     * @return the `frozen` status
     */
    function frozen() external returns (bool);

    /**
     * @param height - state machine height
     * @return the state commitment at `height`
     */
    function stateMachineCommitment(StateMachineHeight memory height) external returns (StateCommitment memory);

    /**
     * @param height - state machine height
     * @return the state machine commitment update time at `height`
     */
    function stateMachineCommitmentUpdateTime(StateMachineHeight memory height) external returns (uint256);

    /**
     * @dev Should return a handle to the consensus client based on the id
     * @return the consensus client contract
     */
    function consensusClient() external returns (address);

    /**
     * @return the last updated time of the consensus client
     */
    function consensusUpdateTime() external returns (uint256);

    /**
     * @return the latest state machine height
     */
    function latestStateMachineHeight() external returns (uint256);

    /**
     * @return the state of the consensus client
     */
    function consensusState() external returns (bytes memory);

    /**
     * @param commitment - commitment to the request
     * @return existence status of an incoming request commitment
     */
    function requestReceipts(bytes32 commitment) external returns (bool);

    /**
     * @param commitment - commitment to the response
     * @return existence status of an incoming response commitment
     */
    function responseReceipts(bytes32 commitment) external returns (bool);

    /**
     * @param commitment - commitment to the request
     * @return existence status of an outgoing request commitment
     */
    function requestCommitments(bytes32 commitment) external returns (bool);

    /**
     * @param commitment - commitment to the response
     * @return existence status of an outgoing response commitment
     */
    function responseCommitments(bytes32 commitment) external returns (bool);

    /**
     * @return the challenge period
     */
    function challengePeriod() external returns (uint256);

    /**
     * @return the unstaking period
     */
    function unStakingPeriod() external returns (uint256);

    /**
     * @dev Store an encoded consensus state
     * @param state new consensus state
     */
    function storeConsensusState(bytes memory state) external;

    /**
     * @dev Updates bridge params
     * @param params new bridge params
     */
    function setBridgeParams(BridgeParams memory params) external;

    /**
     * @dev Store the timestamp when the consensus client was updated
     * @param timestamp - new timestamp
     */
    function storeConsensusUpdateTime(uint256 timestamp) external;

    /**
     * @dev Store the latest state machine height
     * @param height State Machine Height
     */
    function storeLatestStateMachineHeight(uint256 height) external;

    /**
     * @dev Store the commitment at `state height`
     * @param height state machine height
     * @param commitment state commitment
     */
    function storeStateMachineCommitment(StateMachineHeight memory height, StateCommitment memory commitment)
        external;

    /**
     * @dev Store the timestamp when the state machine was updated
     * @param height state machine height
     * @param timestamp new timestamp
     */
    function storeStateMachineCommitmentUpdateTime(StateMachineHeight memory height, uint256 timestamp) external;

    /**
     * @dev Dispatch an incoming request to destination module
     * @param request - post request
     */
    function dispatchIncoming(PostRequest memory request) external;

    /**
     * @dev Dispatch an incoming post response to source module
     * @param response - post response
     */
    function dispatchIncoming(PostResponse memory response) external;

    /**
     * @dev Dispatch an incoming get response to source module
     * @param response - get response
     */
    function dispatchIncoming(GetResponse memory response) external;

    /**
     * @dev Dispatch an incoming get timeout to source module
     * @param timeout - get timeout
     */
    function dispatchIncoming(GetRequest memory timeout) external;

    /**
     * @dev Dispatch an incoming post timeout to source module
     * @param timeout - post timeout
     */
    function dispatchIncoming(PostTimeout memory timeout) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "openzeppelin/utils/Strings.sol";

library StateMachine {
    /// The identifier for the relay chain.
    uint256 public constant RELAY_CHAIN = 0;

    // Address a state machine on the polkadot relay chain
    function polkadot(uint256 id) public pure returns (bytes memory) {
        return bytes(string.concat("POLKADOT-", Strings.toString(id)));
    }

    // Address a state machine on the kusama relay chain
    function kusama(uint256 id) public pure returns (bytes memory) {
        return bytes(string.concat("KUSAMA-", Strings.toString(id)));
    }

    // Address the ethereum "execution layer"
    function ethereum() public pure returns (bytes memory) {
        return bytes("ETHE");
    }

    // Address the Arbitrum state machine
    function arbitrum() public pure returns (bytes memory) {
        return bytes("ARBI");
    }

    // Address the Optimism state machine
    function optimism() public pure returns (bytes memory) {
        return bytes("OPTI");
    }

    // Address the Base state machine
    function base() public pure returns (bytes memory) {
        return bytes("BASE");
    }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: Apache2

library Memory {
    uint256 internal constant WORD_SIZE = 32;

    // Compares the 'len' bytes starting at address 'addr' in memory with the 'len'
    // bytes starting at 'addr2'.
    // Returns 'true' if the bytes are the same, otherwise 'false'.
    function equals(uint256 addr, uint256 addr2, uint256 len) internal pure returns (bool equal) {
        assembly {
            equal := eq(keccak256(addr, len), keccak256(addr2, len))
        }
    }

    // Compares the 'len' bytes starting at address 'addr' in memory with the bytes stored in
    // 'bts'. It is allowed to set 'len' to a lower value then 'bts.length', in which case only
    // the first 'len' bytes will be compared.
    // Requires that 'bts.length >= len'

    function equals(uint256 addr, uint256 len, bytes memory bts) internal pure returns (bool equal) {
        require(bts.length >= len);
        uint256 addr2;
        assembly {
            addr2 := add(bts, /*BYTES_HEADER_SIZE*/ 32)
        }
        return equals(addr, addr2, len);
    }
    // Returns a memory pointer to the data portion of the provided bytes array.

    function dataPtr(bytes memory bts) internal pure returns (uint256 addr) {
        assembly {
            addr := add(bts, /*BYTES_HEADER_SIZE*/ 32)
        }
    }

    // Creates a 'bytes memory' variable from the memory address 'addr', with the
    // length 'len'. The function will allocate new memory for the bytes array, and
    // the 'len bytes starting at 'addr' will be copied into that new memory.
    function toBytes(uint256 addr, uint256 len) internal pure returns (bytes memory bts) {
        bts = new bytes(len);
        uint256 btsptr;
        assembly {
            btsptr := add(bts, /*BYTES_HEADER_SIZE*/ 32)
        }
        copy(addr, btsptr, len);
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'
    // The returned bytes will be of length '32'.
    function toBytes(bytes32 self) internal pure returns (bytes memory bts) {
        bts = new bytes(32);
        assembly {
            mstore(add(bts, /*BYTES_HEADER_SIZE*/ 32), self)
        }
    }

    // Copy 'len' bytes from memory address 'src', to address 'dest'.
    // This function does not check the or destination, it only copies
    // the bytes.
    function copy(uint256 src, uint256 dest, uint256 len) internal pure {
        // Copy word-length chunks while possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += WORD_SIZE;
            src += WORD_SIZE;
        }

        // Copy remaining bytes
        uint256 mask =
            len == 0 ? 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff : 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    // This function does the same as 'dataPtr(bytes memory)', but will also return the
    // length of the provided bytes array.
    function fromBytes(bytes memory bts) internal pure returns (uint256 addr, uint256 len) {
        len = bts.length;
        assembly {
            addr := add(bts, /*BYTES_HEADER_SIZE*/ 32)
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "solidity-merkle-trees/MerklePatricia.sol";

import {StateMachineHeight} from "./IConsensusClient.sol";

struct PostRequest {
    // the source state machine of this request
    bytes source;
    // the destination state machine of this request
    bytes dest;
    // request nonce
    uint64 nonce;
    // Module Id of this request origin
    bytes from;
    // destination module id
    bytes to;
    // timestamp by which this request times out.
    uint64 timeoutTimestamp;
    // request body
    bytes body;
    // gas limit for executing this request on destination & its response (if any) on the source.
    uint64 gaslimit;
}

struct GetRequest {
    // the source state machine of this request
    bytes source;
    // the destination state machine of this request
    bytes dest;
    // request nonce
    uint64 nonce;
    // Module Id of this request origin
    bytes from;
    // timestamp by which this request times out.
    uint64 timeoutTimestamp;
    // Storage keys to read.
    bytes[] keys;
    // height at which to read destination state machine
    uint64 height;
    // gas limit for executing this request on destination & its response (if any) on the source.
    uint64 gaslimit;
}

struct GetResponse {
    // The request that initiated this response
    GetRequest request;
    // storage values for get response
    StorageValue[] values;
}

struct PostResponse {
    // The request that initiated this response
    PostRequest request;
    // bytes for post response
    bytes response;
}

// A post request as a leaf in a merkle tree
struct PostRequestLeaf {
    // The request
    PostRequest request;
    // It's index in the mmr leaves
    uint256 index;
    // it's k-index
    uint256 kIndex;
}

// A post response as a leaf in a merkle tree
struct PostResponseLeaf {
    // The response
    PostResponse response;
    // It's index in the mmr leaves
    uint256 index;
    // it's k-index
    uint256 kIndex;
}

// A merkle mountain range proof.
struct Proof {
    // height of the state machine
    StateMachineHeight height;
    // the multi-proof
    bytes32[] multiproof;
    // The total number of leaves in the mmr for this proof.
    uint256 leafCount;
}

// A message for handling incoming requests
struct PostRequestMessage {
    // proof for the requests
    Proof proof;
    // the requests, contained in a merkle tree leaf
    PostRequestLeaf[] requests;
}

// A message for handling incoming GET responses
struct GetResponseMessage {
    // the state (merkle-patricia) proof of the get request keys
    bytes[] proof;
    // the height of the state machine proof
    StateMachineHeight height;
    // The requests that initiated this response
    GetRequest[] requests;
}

struct GetTimeoutMessage {
    // requests which have timed-out
    GetRequest[] timeouts;
}

struct PostTimeout {
    PostRequest request;
}

struct PostTimeoutMessage {
    // requests which have timed-out
    PostRequest[] timeouts;
    // the height of the state machine proof
    StateMachineHeight height;
    // non-membership proof of the requests
    bytes[] proof;
}

// A message for handling incoming responses
struct PostResponseMessage {
    // proof for the responses
    Proof proof;
    // the responses, contained in a merkle tree leaf
    PostResponseLeaf[] responses;
}

// An object for dispatching post requests to the IsmpDispatcher
struct DispatchPost {
    // bytes representation of the destination chain
    bytes dest;
    // the destination module
    bytes to;
    // the request body
    bytes body;
    // timeout for this request in seconds
    uint64 timeout;
    // gas limit for executing this request on destination & its response (if any) on the source.
    uint64 gaslimit;
}

// An object for dispatching get requests to the IsmpDispatcher
struct DispatchGet {
    // bytes representation of the destination chain
    bytes dest;
    // height at which to read the state machine
    uint64 height;
    // Storage keys to read
    bytes[] keys;
    // timeout for this request in seconds
    uint64 timeout;
    // gas limit for executing this request on destination & its response (if any) on the source.
    uint64 gaslimit;
}

interface IIsmpDispatcher {
    /**
     * @dev Dispatch a post request to the ISMP router.
     * @param request - post request
     */
    function dispatch(DispatchPost memory request) external;

    /**
     * @dev Dispatch a get request to the ISMP router.
     * @param request - get request
     */
    function dispatch(DispatchGet memory request) external;

    /**
     * @dev Provide a response to a previously received request.
     * @param response - post response
     */
    function dispatch(PostResponse memory response) external;
}

library Message {
    function hash(PostResponse memory res) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                res.request.source,
                res.request.dest,
                res.request.nonce,
                res.request.timeoutTimestamp,
                res.request.body,
                res.request.from,
                res.request.to,
                res.response
            )
        );
    }

    function hash(PostRequest memory req) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                req.source, req.dest, req.nonce, req.timeoutTimestamp, req.from, req.to, req.body, req.gaslimit
            )
        );
    }

    function hash(GetRequest memory req) internal pure returns (bytes32) {
        bytes memory keysEncoding = bytes("");
        uint256 len = req.keys.length;
        for (uint256 i = 0; i < len; i++) {
            keysEncoding = bytes.concat(keysEncoding, req.keys[i]);
        }

        return keccak256(
            abi.encodePacked(
                req.source, req.dest, req.nonce, req.height, req.timeoutTimestamp, req.from, keysEncoding, req.gaslimit
            )
        );
    }

    function hash(GetResponse memory res) internal pure returns (bytes32) {
        bytes memory keysEncoding = abi.encode(res.request.keys);
        bytes memory preimage = abi.encodePacked(
            res.request.source,
            res.request.dest,
            res.request.nonce,
            res.request.height,
            res.request.timeoutTimestamp,
            res.request.from,
            keysEncoding,
            res.request.gaslimit
        );
        uint256 len = res.values.length;
        for (uint256 i = 0; i < len; i++) {
            StorageValue memory entry = res.values[i];
            preimage = bytes.concat(preimage, abi.encodePacked(entry.key, entry.value));
        }

        return keccak256(preimage);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "solidity-merkle-trees/MerklePatricia.sol";

// The state commiment identifies a commiment to some intermediate state in the state machine.
// This contains some metadata about the state machine like it's own timestamp at the time of this commitment.
struct StateCommitment {
    // This timestamp is useful for handling request timeouts.
    uint256 timestamp;
    // merkle mountain range commitment to all ismp requests & response.
    bytes32 overlayRoot;
    // state root for processing timeouts.
    bytes32 stateRoot;
}

// Identifies some state machine height. We allow for a state machine identifier here
// as some consensus clients may track multiple, concurrent state machines.
struct StateMachineHeight {
    // the state machine identifier
    uint256 stateMachineId;
    // height of this state machine
    uint256 height;
}

struct IntermediateState {
    // the state machine identifier
    uint256 stateMachineId;
    // height of this state machine
    uint256 height;
    // state commitment
    StateCommitment commitment;
}

interface IConsensusClient {
    /// Verify the consensus proof and return the new trusted consensus state and any intermediate states finalized
    /// by this consensus proof.
    function verifyConsensus(bytes memory trustedState, bytes memory proof)
        external
        returns (bytes memory, IntermediateState memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

pragma solidity ^0.8.17;

import "./trie/Node.sol";
import "./trie/Option.sol";
import "./trie/NibbleSlice.sol";
import "./trie/TrieDB.sol";

import "./trie/substrate/SubstrateTrieDB.sol";
import "./trie/ethereum/EthereumTrieDB.sol";

// SPDX-License-Identifier: Apache2

// Outcome of a successfully verified merkle-patricia proof
struct StorageValue {
    // the storage key
    bytes key;
    // the encoded value
    bytes value;
}

/**
 * @title A Merkle Patricia library
 * @author Polytope Labs
 * @dev Use this library to verify merkle patricia proofs
 * @dev refer to research for more info. https://research.polytope.technology/state-(machine)-proofs
 */
library MerklePatricia {
    /// @notice libraries in solidity can only have constant variables
    /// @dev MAX_TRIE_DEPTH, we don't explore deeply nested trie keys.
    uint256 internal constant MAX_TRIE_DEPTH = 50;

    /**
     * @notice Verifies substrate specific merkle patricia proofs.
     * @param root hash of the merkle patricia trie
     * @param proof a list of proof nodes
     * @param keys a list of keys to verify
     * @return bytes[] a list of values corresponding to the supplied keys.
     */
    function VerifySubstrateProof(bytes32 root, bytes[] memory proof, bytes[] memory keys)
        public
        pure
        returns (StorageValue[] memory)
    {
        StorageValue[] memory values = new StorageValue[](keys.length);
        TrieNode[] memory nodes = new TrieNode[](proof.length);

        for (uint256 i = 0; i < proof.length; i++) {
            nodes[i] = TrieNode(keccak256(proof[i]), proof[i]);
        }

        for (uint256 i = 0; i < keys.length; i++) {
            values[i].key = keys[i];
            NibbleSlice memory keyNibbles = NibbleSlice(keys[i], 0);
            NodeKind memory node = SubstrateTrieDB.decodeNodeKind(TrieDB.get(nodes, root));

            // worst case scenario, so we avoid unbounded loops
            for (uint256 j = 0; j < MAX_TRIE_DEPTH; j++) {
                NodeHandle memory nextNode;

                if (TrieDB.isLeaf(node)) {
                    Leaf memory leaf = SubstrateTrieDB.decodeLeaf(node);
                    if (NibbleSliceOps.eq(leaf.key, keyNibbles)) {
                        values[i].value = TrieDB.load(nodes, leaf.value);
                    }
                    break;
                } else if (TrieDB.isNibbledBranch(node)) {
                    NibbledBranch memory nibbled = SubstrateTrieDB.decodeNibbledBranch(node);
                    uint256 nibbledBranchKeyLength = NibbleSliceOps.len(nibbled.key);
                    if (!NibbleSliceOps.startsWith(keyNibbles, nibbled.key)) {
                        break;
                    }

                    if (NibbleSliceOps.len(keyNibbles) == nibbledBranchKeyLength) {
                        if (Option.isSome(nibbled.value)) {
                            values[i].value = TrieDB.load(nodes, nibbled.value.value);
                        }
                        break;
                    } else {
                        uint256 index = NibbleSliceOps.at(keyNibbles, nibbledBranchKeyLength);
                        NodeHandleOption memory handle = nibbled.children[index];
                        if (Option.isSome(handle)) {
                            keyNibbles = NibbleSliceOps.mid(keyNibbles, nibbledBranchKeyLength + 1);
                            nextNode = handle.value;
                        } else {
                            break;
                        }
                    }
                } else if (TrieDB.isEmpty(node)) {
                    break;
                }

                node = SubstrateTrieDB.decodeNodeKind(TrieDB.load(nodes, nextNode));
            }
        }

        return values;
    }

    /**
     * @notice Verify child trie keys
     * @dev substrate specific method in order to verify keys in the child trie.
     * @param root hash of the merkle root
     * @param proof a list of proof nodes
     * @param keys a list of keys to verify
     * @param childInfo data that can be used to compute the root of the child trie
     * @return bytes[], a list of values corresponding to the supplied keys.
     */
    function ReadChildProofCheck(bytes32 root, bytes[] memory proof, bytes[] memory keys, bytes memory childInfo)
        public
        pure
        returns (StorageValue[] memory)
    {
        // fetch the child trie root hash;
        bytes memory prefix = bytes(":child_storage:default:");
        bytes memory key = bytes.concat(prefix, childInfo);
        bytes[] memory _keys = new bytes[](1);
        _keys[0] = key;
        StorageValue[] memory values = VerifySubstrateProof(root, proof, _keys);

        bytes32 childRoot = bytes32(values[0].value);
        require(childRoot != bytes32(0), "Invalid child trie proof");

        return VerifySubstrateProof(childRoot, proof, keys);
    }

    /**
     * @notice Verifies ethereum specific merkle patricia proofs as described by EIP-1188.
     * @param root hash of the merkle patricia trie
     * @param proof a list of proof nodes
     * @param keys a list of keys to verify
     * @return bytes[] a list of values corresponding to the supplied keys.
     */
    function VerifyEthereumProof(bytes32 root, bytes[] memory proof, bytes[] memory keys)
        public
        pure
        returns (StorageValue[] memory)
    {
        StorageValue[] memory values = new StorageValue[](keys.length);
        TrieNode[] memory nodes = new TrieNode[](proof.length);

        for (uint256 i = 0; i < proof.length; i++) {
            nodes[i] = TrieNode(keccak256(proof[i]), proof[i]);
        }

        for (uint256 i = 0; i < keys.length; i++) {
            values[i].key = keys[i];
            NibbleSlice memory keyNibbles = NibbleSlice(keys[i], 0);
            NodeKind memory node = EthereumTrieDB.decodeNodeKind(TrieDB.get(nodes, root));

            // worst case scenario, so we avoid unbounded loops
            for (uint256 j = 0; j < MAX_TRIE_DEPTH; j++) {
                NodeHandle memory nextNode;

                if (TrieDB.isLeaf(node)) {
                    Leaf memory leaf = EthereumTrieDB.decodeLeaf(node);
                    // Let's retrieve the offset to be used
                    uint256 offset = keyNibbles.offset % 2 == 0 ? keyNibbles.offset / 2 : keyNibbles.offset / 2 + 1;
                    // Let's cut the key passed as input
                    keyNibbles = NibbleSlice(NibbleSliceOps.bytesSlice(keyNibbles.data, offset), 0);
                    if (NibbleSliceOps.eq(leaf.key, keyNibbles)) {
                        values[i].value = TrieDB.load(nodes, leaf.value);
                    }
                    break;
                } else if (TrieDB.isExtension(node)) {
                    Extension memory extension = EthereumTrieDB.decodeExtension(node);
                    if (NibbleSliceOps.startsWith(keyNibbles, extension.key)) {
                        // Let's cut the key passed as input
                        keyNibbles = NibbleSlice(
                            NibbleSliceOps.bytesSlice(keyNibbles.data, NibbleSliceOps.len(extension.key)), 0
                        );
                        nextNode = extension.node;
                    } else {
                        break;
                    }
                } else if (TrieDB.isBranch(node)) {
                    Branch memory branch = EthereumTrieDB.decodeBranch(node);
                    if (NibbleSliceOps.isEmpty(keyNibbles)) {
                        if (Option.isSome(branch.value)) {
                            values[i].value = TrieDB.load(nodes, branch.value.value);
                        }
                        break;
                    } else {
                        NodeHandleOption memory handle = branch.children[NibbleSliceOps.at(keyNibbles, 0)];
                        if (Option.isSome(handle)) {
                            keyNibbles = NibbleSliceOps.mid(keyNibbles, 1);
                            nextNode = handle.value;
                        } else {
                            break;
                        }
                    }
                } else if (TrieDB.isEmpty(node)) {
                    break;
                }

                node = EthereumTrieDB.decodeNodeKind(TrieDB.load(nodes, nextNode));
            }
        }

        return values;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: Apache2

import "./NibbleSlice.sol";
import "./Bytes.sol";

/// This is an enum for the different node types.
struct NodeKind {
    bool isEmpty;
    bool isLeaf;
    bool isHashedLeaf;
    bool isNibbledValueBranch;
    bool isNibbledHashedValueBranch;
    bool isNibbledBranch;
    bool isExtension;
    bool isBranch;
    uint256 nibbleSize;
    ByteSlice data;
}

struct NodeHandle {
    bool isHash;
    bytes32 hash;
    bool isInline;
    bytes inLine;
}

struct Extension {
    NibbleSlice key;
    NodeHandle node;
}

struct Branch {
    NodeHandleOption value;
    NodeHandleOption[16] children;
}

struct NibbledBranch {
    NibbleSlice key;
    NodeHandleOption value;
    NodeHandleOption[16] children;
}

struct ValueOption {
    bool isSome;
    bytes value;
}

struct NodeHandleOption {
    bool isSome;
    NodeHandle value;
}

struct Leaf {
    NibbleSlice key;
    NodeHandle value;
}

struct TrieNode {
    bytes32 hash;
    bytes node;
}

pragma solidity ^0.8.17;

import "./Node.sol";

// SPDX-License-Identifier: Apache2

library Option {
    function isSome(ValueOption memory val) internal pure returns (bool) {
        return val.isSome == true;
    }

    function isSome(NodeHandleOption memory val) internal pure returns (bool) {
        return val.isSome == true;
    }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: Apache2

struct NibbleSlice {
    bytes data;
    uint256 offset;
}

library NibbleSliceOps {
    uint256 internal constant NIBBLE_PER_BYTE = 2;
    uint256 internal constant BITS_PER_NIBBLE = 4;

    function len(NibbleSlice memory nibble) internal pure returns (uint256) {
        return nibble.data.length * NIBBLE_PER_BYTE - nibble.offset;
    }

    function mid(NibbleSlice memory self, uint256 i) internal pure returns (NibbleSlice memory) {
        return NibbleSlice(self.data, self.offset + i);
    }

    function isEmpty(NibbleSlice memory self) internal pure returns (bool) {
        return len(self) == 0;
    }

    function eq(NibbleSlice memory self, NibbleSlice memory other) internal pure returns (bool) {
        return len(self) == len(other) && startsWith(self, other);
    }

    function at(NibbleSlice memory self, uint256 i) internal pure returns (uint256) {
        uint256 ix = (self.offset + i) / NIBBLE_PER_BYTE;
        uint256 pad = (self.offset + i) % NIBBLE_PER_BYTE;
        uint8 data = uint8(self.data[ix]);
        return (pad == 1) ? data & 0x0F : data >> BITS_PER_NIBBLE;
    }

    function startsWith(NibbleSlice memory self, NibbleSlice memory other) internal pure returns (bool) {
        return commonPrefix(self, other) == len(other);
    }

    function commonPrefix(NibbleSlice memory self, NibbleSlice memory other) internal pure returns (uint256) {
        uint256 self_align = self.offset % NIBBLE_PER_BYTE;
        uint256 other_align = other.offset % NIBBLE_PER_BYTE;

        if (self_align == other_align) {
            uint256 self_start = self.offset / NIBBLE_PER_BYTE;
            uint256 other_start = other.offset / NIBBLE_PER_BYTE;
            uint256 first = 0;

            if (self_align != 0) {
                if ((self.data[self_start] & 0x0F) != (other.data[other_start] & 0x0F)) {
                    return 0;
                }
                ++self_start;
                ++other_start;
                ++first;
            }
            bytes memory selfSlice = bytesSlice(self.data, self_start);
            bytes memory otherSlice = bytesSlice(other.data, other_start);
            return biggestDepth(selfSlice, otherSlice) + first;
        } else {
            uint256 s = min(len(self), len(other));
            uint256 i = 0;
            while (i < s) {
                if (at(self, i) != at(other, i)) {
                    break;
                }
                ++i;
            }
            return i;
        }
    }

    function biggestDepth(bytes memory a, bytes memory b) internal pure returns (uint256) {
        uint256 upperBound = min(a.length, b.length);
        uint256 i = 0;
        while (i < upperBound) {
            if (a[i] != b[i]) {
                return i * NIBBLE_PER_BYTE + leftCommon(a[i], b[i]);
            }
            ++i;
        }
        return i * NIBBLE_PER_BYTE;
    }

    function leftCommon(bytes1 a, bytes1 b) internal pure returns (uint256) {
        if (a == b) {
            return 2;
        } else if (uint8(a) & 0xF0 == uint8(b) & 0xF0) {
            return 1;
        } else {
            return 0;
        }
    }

    function bytesSlice(bytes memory _bytes, uint256 _start) internal pure returns (bytes memory) {
        uint256 bytesLength = _bytes.length;
        uint256 _length = bytesLength - _start;
        require(bytesLength >= _start, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                tempBytes := mload(0x40) // load free memory pointer
                let lengthmod := and(_length, 31)

                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for { let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start) } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } { mstore(mc, mload(cc)) }

                mstore(tempBytes, _length)

                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }
        return tempBytes;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a < b) ? a : b;
    }
}

// SPDX-License-Identifier: Apache2
pragma solidity ^0.8.17;

import "./Node.sol";

library TrieDB {
    function get(TrieNode[] memory nodes, bytes32 hash) internal pure returns (bytes memory) {
        for (uint256 i = 0; i < nodes.length; i++) {
            if (nodes[i].hash == hash) {
                return nodes[i].node;
            }
        }
        revert("Incomplete Proof!");
    }

    function load(TrieNode[] memory nodes, NodeHandle memory node) internal pure returns (bytes memory) {
        if (node.isInline) {
            return node.inLine;
        } else if (node.isHash) {
            return get(nodes, node.hash);
        }

        return bytes("");
    }

    function isNibbledBranch(NodeKind memory node) internal pure returns (bool) {
        return (node.isNibbledBranch || node.isNibbledHashedValueBranch || node.isNibbledValueBranch);
    }

    function isExtension(NodeKind memory node) internal pure returns (bool) {
        return node.isExtension;
    }

    function isBranch(NodeKind memory node) internal pure returns (bool) {
        return node.isBranch;
    }

    function isLeaf(NodeKind memory node) internal pure returns (bool) {
        return (node.isLeaf || node.isHashedLeaf);
    }

    function isEmpty(NodeKind memory node) internal pure returns (bool) {
        return node.isEmpty;
    }

    function isHash(NodeHandle memory node) internal pure returns (bool) {
        return node.isHash;
    }

    function isInline(NodeHandle memory node) internal pure returns (bool) {
        return node.isInline;
    }
}

pragma solidity ^0.8.17;

import "../Node.sol";
import "../Bytes.sol";
import {NibbleSliceOps} from "../NibbleSlice.sol";

import {ScaleCodec} from "./ScaleCodec.sol";
import "openzeppelin/utils/Strings.sol";

// SPDX-License-Identifier: Apache2

library SubstrateTrieDB {
    uint8 public constant FIRST_PREFIX = 0x00 << 6;
    uint8 public constant PADDING_BITMASK = 0x0F;
    uint8 public constant EMPTY_TRIE = FIRST_PREFIX | (0x00 << 4);
    uint8 public constant LEAF_PREFIX_MASK = 0x01 << 6;
    uint8 public constant BRANCH_WITH_MASK = 0x03 << 6;
    uint8 public constant BRANCH_WITHOUT_MASK = 0x02 << 6;
    uint8 public constant ALT_HASHING_LEAF_PREFIX_MASK = FIRST_PREFIX | (0x01 << 5);
    uint8 public constant ALT_HASHING_BRANCH_WITH_MASK = FIRST_PREFIX | (0x01 << 4);
    uint8 public constant NIBBLE_PER_BYTE = 2;
    uint256 public constant NIBBLE_SIZE_BOUND = uint256(type(uint16).max);
    uint256 public constant BITMAP_LENGTH = 2;
    uint256 public constant HASH_lENGTH = 32;

    function decodeNodeKind(bytes memory encoded) internal pure returns (NodeKind memory) {
        NodeKind memory node;
        ByteSlice memory input = ByteSlice(encoded, 0);
        uint8 i = Bytes.readByte(input);

        if (i == EMPTY_TRIE) {
            node.isEmpty = true;
            return node;
        }

        uint8 mask = i & (0x03 << 6);

        if (mask == LEAF_PREFIX_MASK) {
            node.nibbleSize = decodeSize(i, input, 2);
            node.isLeaf = true;
        } else if (mask == BRANCH_WITH_MASK) {
            node.nibbleSize = decodeSize(i, input, 2);
            node.isNibbledValueBranch = true;
        } else if (mask == BRANCH_WITHOUT_MASK) {
            node.nibbleSize = decodeSize(i, input, 2);
            node.isNibbledBranch = true;
        } else if (mask == EMPTY_TRIE) {
            if (i & (0x07 << 5) == ALT_HASHING_LEAF_PREFIX_MASK) {
                node.nibbleSize = decodeSize(i, input, 3);
                node.isHashedLeaf = true;
            } else if (i & (0x0F << 4) == ALT_HASHING_BRANCH_WITH_MASK) {
                node.nibbleSize = decodeSize(i, input, 4);
                node.isNibbledHashedValueBranch = true;
            } else {
                // do not allow any special encoding
                revert("Unallowed encoding");
            }
        }
        node.data = input;

        return node;
    }

    function decodeNibbledBranch(NodeKind memory node) internal pure returns (NibbledBranch memory) {
        NibbledBranch memory nibbledBranch;
        ByteSlice memory input = node.data;

        bool padding = node.nibbleSize % NIBBLE_PER_BYTE != 0;
        if (padding && (padLeft(uint8(input.data[input.offset])) != 0)) {
            revert("Bad Format!");
        }
        uint256 nibbleLen = ((node.nibbleSize + (NibbleSliceOps.NIBBLE_PER_BYTE - 1)) / NibbleSliceOps.NIBBLE_PER_BYTE);
        nibbledBranch.key = NibbleSlice(Bytes.read(input, nibbleLen), node.nibbleSize % NIBBLE_PER_BYTE);

        bytes memory bitmapBytes = Bytes.read(input, BITMAP_LENGTH);
        uint16 bitmap = uint16(ScaleCodec.decodeUint256(bitmapBytes));

        NodeHandleOption memory valueHandle;
        if (node.isNibbledHashedValueBranch) {
            valueHandle.isSome = true;
            valueHandle.value.isHash = true;
            valueHandle.value.hash = Bytes.toBytes32(Bytes.read(input, HASH_lENGTH));
        } else if (node.isNibbledValueBranch) {
            uint256 len = ScaleCodec.decodeUintCompact(input);
            valueHandle.isSome = true;
            valueHandle.value.isInline = true;
            valueHandle.value.inLine = Bytes.read(input, len);
        }
        nibbledBranch.value = valueHandle;

        for (uint256 i = 0; i < 16; i++) {
            NodeHandleOption memory childHandle;
            if (valueAt(bitmap, i)) {
                childHandle.isSome = true;
                uint256 len = ScaleCodec.decodeUintCompact(input);
                //                revert(string.concat("node index: ", Strings.toString(len)));
                if (len == HASH_lENGTH) {
                    childHandle.value.isHash = true;
                    childHandle.value.hash = Bytes.toBytes32(Bytes.read(input, HASH_lENGTH));
                } else {
                    childHandle.value.isInline = true;
                    childHandle.value.inLine = Bytes.read(input, len);
                }
            }
            nibbledBranch.children[i] = childHandle;
        }

        return nibbledBranch;
    }

    function decodeLeaf(NodeKind memory node) internal pure returns (Leaf memory) {
        Leaf memory leaf;
        ByteSlice memory input = node.data;

        bool padding = node.nibbleSize % NIBBLE_PER_BYTE != 0;
        if (padding && padLeft(uint8(input.data[input.offset])) != 0) {
            revert("Bad Format!");
        }
        uint256 nibbleLen = (node.nibbleSize + (NibbleSliceOps.NIBBLE_PER_BYTE - 1)) / NibbleSliceOps.NIBBLE_PER_BYTE;
        bytes memory nibbleBytes = Bytes.read(input, nibbleLen);
        leaf.key = NibbleSlice(nibbleBytes, node.nibbleSize % NIBBLE_PER_BYTE);

        NodeHandle memory handle;
        if (node.isHashedLeaf) {
            handle.isHash = true;
            handle.hash = Bytes.toBytes32(Bytes.read(input, HASH_lENGTH));
        } else {
            uint256 len = ScaleCodec.decodeUintCompact(input);
            handle.isInline = true;
            handle.inLine = Bytes.read(input, len);
        }
        leaf.value = handle;

        return leaf;
    }

    function decodeSize(uint8 first, ByteSlice memory encoded, uint8 prefixMask) internal pure returns (uint256) {
        uint8 maxValue = uint8(255 >> prefixMask);
        uint256 result = uint256(first & maxValue);

        if (result < maxValue) {
            return result;
        }

        result -= 1;

        while (result <= NIBBLE_SIZE_BOUND) {
            uint256 n = uint256(Bytes.readByte(encoded));
            if (n < 255) {
                return result + n + 1;
            }
            result += 255;
        }

        return NIBBLE_SIZE_BOUND;
    }

    function padLeft(uint8 b) internal pure returns (uint8) {
        return b & ~PADDING_BITMASK;
    }

    function valueAt(uint16 bitmap, uint256 i) internal pure returns (bool) {
        return bitmap & (uint16(1) << uint16(i)) != 0;
    }
}

pragma solidity ^0.8.17;

import "../Node.sol";
import "../Bytes.sol";
import {NibbleSliceOps} from "../NibbleSlice.sol";
import "./RLPReader.sol";

// SPDX-License-Identifier: Apache2

library EthereumTrieDB {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;

    bytes constant HASHED_NULL_NODE = hex"56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421";

    function decodeNodeKind(bytes memory encoded) external pure returns (NodeKind memory) {
        NodeKind memory node;
        ByteSlice memory input = ByteSlice(encoded, 0);
        if (Bytes.equals(encoded, HASHED_NULL_NODE)) {
            node.isEmpty = true;
            return node;
        }
        RLPReader.RLPItem[] memory itemList = encoded.toRlpItem().toList();
        uint256 numItems = itemList.length;
        if (numItems == 0) {
            node.isEmpty = true;
            return node;
        } else if (numItems == 2) {
            //It may be a leaf or extension
            bytes memory key = itemList[0].toBytes();
            uint256 prefix;
            assembly {
                let first := shr(248, mload(add(key, 32)))
                prefix := shr(4, first)
            }
            if (prefix == 2 || prefix == 3) {
                node.isLeaf = true;
            } else {
                node.isExtension = true;
            }
        } else if (numItems == 17) {
            node.isBranch = true;
        } else {
            revert("Invalid data");
        }
        node.data = input;
        return node;
    }

    function decodeLeaf(NodeKind memory node) external pure returns (Leaf memory) {
        Leaf memory leaf;
        RLPReader.RLPItem[] memory decoded = node.data.data.toRlpItem().toList();
        bytes memory data = decoded[1].toBytes();
        //Remove the first byte, which is the prefix and not present in the user provided key
        leaf.key = NibbleSlice(Bytes.substr(decoded[0].toBytes(), 1), 0);
        leaf.value = NodeHandle(false, bytes32(0), true, data);

        return leaf;
    }

    function decodeExtension(NodeKind memory node) external pure returns (Extension memory) {
        Extension memory extension;
        RLPReader.RLPItem[] memory decoded = node.data.data.toRlpItem().toList();
        bytes memory data = decoded[1].toBytes();
        //Remove the first byte, which is the prefix and not present in the user provided key
        extension.key = NibbleSlice(Bytes.substr(decoded[0].toBytes(), 1), 0);
        extension.node = NodeHandle(true, Bytes.toBytes32(data), false, new bytes(0));
        return extension;
    }

    function decodeBranch(NodeKind memory node) external pure returns (Branch memory) {
        Branch memory branch;
        RLPReader.RLPItem[] memory decoded = node.data.data.toRlpItem().toList();

        NodeHandleOption[16] memory childrens;

        for (uint256 i = 0; i < 16; i++) {
            bytes memory dataAsBytes = decoded[i].toBytes();
            if (dataAsBytes.length != 32) {
                childrens[i] = NodeHandleOption(false, NodeHandle(false, bytes32(0), false, new bytes(0)));
            } else {
                bytes32 data = Bytes.toBytes32(dataAsBytes);
                childrens[i] = NodeHandleOption(true, NodeHandle(true, data, false, new bytes(0)));
            }
        }
        if (isEmpty(decoded[16].toBytes())) {
            branch.value = NodeHandleOption(false, NodeHandle(false, bytes32(0), false, new bytes(0)));
        } else {
            branch.value = NodeHandleOption(true, NodeHandle(false, bytes32(0), true, decoded[16].toBytes()));
        }
        branch.children = childrens;

        return branch;
    }

    function isEmpty(bytes memory item) internal pure returns (bool) {
        return item.length > 0 && (item[0] == 0xc0 || item[0] == 0x80);
    }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: Apache2

import {Bytes, ByteSlice} from "../Bytes.sol";

library ScaleCodec {
    // Decodes a SCALE encoded uint256 by converting bytes (bid endian) to little endian format
    function decodeUint256(bytes memory data) internal pure returns (uint256) {
        uint256 number;
        for (uint256 i = data.length; i > 0; i--) {
            number = number + uint256(uint8(data[i - 1])) * (2 ** (8 * (i - 1)));
        }
        return number;
    }

    // Decodes a SCALE encoded compact unsigned integer
    function decodeUintCompact(ByteSlice memory data) internal pure returns (uint256 v) {
        uint8 b = Bytes.readByte(data); // read the first byte
        uint8 mode = b % 4; // bitwise operation

        uint256 value;
        if (mode == 0) {
            // [0, 63]
            value = b >> 2; // right shift to remove mode bits
        } else if (mode == 1) {
            // [64, 16383]
            uint8 bb = Bytes.readByte(data); // read the second byte
            uint64 r = bb; // convert to uint64
            r <<= 6; // multiply by * 2^6
            r += b >> 2; // right shift to remove mode bits
            value = r;
        } else if (mode == 2) {
            // [16384, 1073741823]
            uint8 b2 = Bytes.readByte(data); // read the next 3 bytes
            uint8 b3 = Bytes.readByte(data);
            uint8 b4 = Bytes.readByte(data);

            uint32 x1 = uint32(b) | (uint32(b2) << 8); // convert to little endian
            uint32 x2 = x1 | (uint32(b3) << 16);
            uint32 x3 = x2 | (uint32(b4) << 24);

            x3 >>= 2; // remove the last 2 mode bits
            value = uint256(x3);
        } else if (mode == 3) {
            // [1073741824, 4503599627370496]
            uint8 l = (b >> 2) + 4; // remove mode bits
            require(l <= 8, "unexpected prefix decoding Compact<Uint>");
            return decodeUint256(Bytes.read(data, l));
        } else {
            revert("Code should be unreachable");
        }
        return value;
    }

    // Decodes a SCALE encoded compact unsigned integer
    function decodeUintCompact(bytes memory data) internal pure returns (uint256 v, uint8 m) {
        uint8 b = readByteAtIndex(data, 0); // read the first byte
        uint8 mode = b & 3; // bitwise operation

        uint256 value;
        if (mode == 0) {
            // [0, 63]
            value = b >> 2; // right shift to remove mode bits
        } else if (mode == 1) {
            // [64, 16383]
            uint8 bb = readByteAtIndex(data, 1); // read the second byte
            uint64 r = bb; // convert to uint64
            r <<= 6; // multiply by * 2^6
            r += b >> 2; // right shift to remove mode bits
            value = r;
        } else if (mode == 2) {
            // [16384, 1073741823]
            uint8 b2 = readByteAtIndex(data, 1); // read the next 3 bytes
            uint8 b3 = readByteAtIndex(data, 2);
            uint8 b4 = readByteAtIndex(data, 3);

            uint32 x1 = uint32(b) | (uint32(b2) << 8); // convert to little endian
            uint32 x2 = x1 | (uint32(b3) << 16);
            uint32 x3 = x2 | (uint32(b4) << 24);

            x3 >>= 2; // remove the last 2 mode bits
            value = uint256(x3);
        } else if (mode == 3) {
            // [1073741824, 4503599627370496]
            uint8 l = b >> 2; // remove mode bits
            require(l > 32, "Not supported: number cannot be greater than 32 bytes");
        } else {
            revert("Code should be unreachable");
        }
        return (value, mode);
    }

    // The biggest compact supported uint is 2 ** 536 - 1.
    // But the biggest value supported by this method is 2 ** 256 - 1(max of uint256)
    function encodeUintCompact(uint256 v) internal pure returns (bytes memory) {
        if (v < 64) {
            return abi.encodePacked(uint8(v << 2));
        } else if (v < 2 ** 14) {
            return abi.encodePacked(reverse16(uint16(((v << 2) + 1))));
        } else if (v < 2 ** 30) {
            return abi.encodePacked(reverse32(uint32(((v << 2) + 2))));
        } else {
            bytes memory valueBytes = Bytes.removeEndingZero(abi.encodePacked(reverse256(v)));

            uint256 length = valueBytes.length;
            uint8 prefix = uint8(((length - 4) << 2) + 3);

            return abi.encodePacked(prefix, valueBytes);
        }
    }

    // Read a byte at a specific index and return it as type uint8
    function readByteAtIndex(bytes memory data, uint8 index) internal pure returns (uint8) {
        return uint8(data[index]);
    }

    // Sources:
    //   * https://ethereum.stackexchange.com/questions/15350/how-to-convert-an-bytes-to-address-in-solidity/50528
    //   * https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel

    function reverse256(uint256 input) internal pure returns (uint256 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8)
            | ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16)
            | ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32)
            | ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64)
            | ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    function reverse128(uint128 input) internal pure returns (uint128 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00) >> 8) | ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000) >> 16) | ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000) >> 32) | ((v & 0x00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = (v >> 64) | (v << 64);
    }

    function reverse64(uint64 input) internal pure returns (uint64 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00) >> 8) | ((v & 0x00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000) >> 16) | ((v & 0x0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = (v >> 32) | (v << 32);
    }

    function reverse32(uint32 input) internal pure returns (uint32 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00) >> 8) | ((v & 0x00FF00FF) << 8);

        // swap 2-byte long pairs
        v = (v >> 16) | (v << 16);
    }

    function reverse16(uint16 input) internal pure returns (uint16 v) {
        v = input;

        // swap bytes
        v = (v >> 8) | (v << 8);
    }

    function encode256(uint256 input) internal pure returns (bytes32) {
        return bytes32(reverse256(input));
    }

    function encode128(uint128 input) internal pure returns (bytes16) {
        return bytes16(reverse128(input));
    }

    function encode64(uint64 input) internal pure returns (bytes8) {
        return bytes8(reverse64(input));
    }

    function encode32(uint32 input) internal pure returns (bytes4) {
        return bytes4(reverse32(input));
    }

    function encode16(uint16 input) internal pure returns (bytes2) {
        return bytes2(reverse16(input));
    }

    function encodeBytes(bytes memory input) internal pure returns (bytes memory) {
        return abi.encodePacked(encodeUintCompact(input.length), input);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */
pragma solidity >=0.5.10 <0.9.0;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    struct Iterator {
        RLPItem item; // Item that's being iterated over.
        uint256 nextPtr; // Position of the next item in the list.
    }

    /*
     * @dev Returns the next element in the iteration. Reverts if it has not next element.
     * @param self The iterator.
     * @return The next element in the iteration.
     */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint256 ptr = self.nextPtr;
        uint256 itemLength = _itemLength(ptr);
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
        uint256 memPtr;
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

        uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
     * @param the RLP item.
     */
    function rlpLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len;
    }

    /*
     * @param the RLP item.
     * @return (memPtr, len) pair: location of the item's payload in memory.
     */
    function payloadLocation(RLPItem memory item) internal pure returns (uint256, uint256) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 memPtr = item.memPtr + offset;
        uint256 len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
     * @param the RLP item.
     */
    function payloadLen(RLPItem memory item) internal pure returns (uint256) {
        (, uint256 len) = payloadLocation(item);
        return len;
    }

    /*
     * @param the RLP item containing the encoded list.
     */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint256 items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
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
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) return false;
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
        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /**
     * RLPItem conversions into data types *
     */

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte except "0x80" is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint256 result;
        uint256 memPtr = item.memPtr;
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

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33);

        (uint256 memPtr, uint256 len) = payloadLocation(item);

        uint256 result;
        assembly {
            result := mload(memPtr)

            // shift to the correct location if neccesary
            if lt(len, 32) { result := div(result, exp(256, sub(32, len))) }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
        // one byte prefix
        require(item.len == 33);

        uint256 result;
        uint256 memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes memory result = new bytes(len);

        uint256 destPtr;
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
    function numItems(RLPItem memory item) private pure returns (uint256) {
        if (item.len == 0) return 0;

        uint256 count = 0;
        uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint256 memPtr) private pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            itemLen = 1;
        } else if (byte0 < STRING_LONG_START) {
            itemLen = byte0 - STRING_SHORT_START + 1;
        } else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
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
    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            return 0;
        } else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) {
            return 1;
        } else if (byte0 < LIST_SHORT_START) {
            // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        } else {
            return byte0 - (LIST_LONG_START - 1) + 1;
        }
    }

    /*
     * @param src Pointer to source
     * @param dest Pointer to destination
     * @param len Amount of memory to copy from the source
     */
    function copy(uint256 src, uint256 dest, uint256 len) private pure {
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
            uint256 mask = 256 ** (WORD_SIZE - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask)) // zero out src
                let destpart := and(mload(dest), mask) // retrieve the bytes
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}