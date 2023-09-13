// contracts/query/QueryDemo.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "../libraries/external/BytesLib.sol";
import "../interfaces/IWormhole.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./QueryResponse.sol";

/// @dev QueryDemo is a library that implements the parsing and verification of Cross Chain Query (CCQ) responses.
contract QueryDemo is Context, QueryResponse {
    using BytesLib for bytes;

    struct ChainEntry {
        uint16 chainID;
        address contractAddress;
        uint256 counter;
        uint64 blockNum;
        uint64 blockTime;
    }

    address owner;
    address wormhole;
    uint16 myChainID;
    mapping(uint16 => ChainEntry) counters;
    uint16[] foreignChainIDs;

    bytes4 GetMyCounter = bytes4(hex"916d5743");

    constructor(address _owner, address _wormhole, uint16 _myChainID) {
        owner = _owner;
        wormhole = _wormhole;  
        myChainID = _myChainID;
        counters[myChainID] = ChainEntry(myChainID, address(this), 0, 0, 0);
    }

    // updateRegistration should be used to add the other chains and to set / update contract addresses.
    function updateRegistration(uint16 _chainID, address _contractAddress) public onlyOwner {
        if (counters[_chainID].chainID == 0) {
            foreignChainIDs.push(_chainID);
            counters[_chainID].chainID = _chainID;
        }

        counters[_chainID].contractAddress = _contractAddress;
    }

    // getMyCounter (call signature 916d5743) returns the counter value for this chain. It is meant to be used in a cross chain query.
    function getMyCounter() public view returns (uint256) {
        return counters[myChainID].counter;
    }

    // getState() returns this chain's view of all the counters. It is meant to be used in the front end.
    function getState() public view returns (ChainEntry[] memory) {
        ChainEntry[] memory ret = new ChainEntry[](foreignChainIDs.length + 1);
        ret[0] = counters[myChainID];
        for (uint idx=0; idx<foreignChainIDs.length; idx++) {
            ret[idx+1] = counters[foreignChainIDs[idx]];
        }      

        return ret;
    }

    // updateCounters takes the cross chain query response for the two other counters, stores the results for the other chains, and updates the counter for this chain.
    function updateCounters(bytes memory response, IWormhole.Signature[] memory signatures) public {
        ParsedQueryResponse memory r = parseAndVerifyQueryResponse(address(wormhole), response, signatures);
        require(r.responses.length == foreignChainIDs.length, "unexpected number of results");
        for (uint idx=0; idx<r.responses.length; idx++) {
            require(counters[r.responses[idx].chainId].chainID == foreignChainIDs[idx], "unexpected foreign chain ID");
            EthCallQueryResponse memory eqr = parseEthCallQueryResponse(r.responses[idx]);
            require(eqr.blockNum > counters[r.responses[idx].chainId].blockNum, "update is obsolete");
            require(eqr.blockNum == counters[r.responses[idx].chainId].blockNum, "update is redundant");
            require(eqr.blockTime > block.timestamp - 300, "update is stale");
            require(eqr.result.length == 1, "result mismatch");
            require(eqr.result[0].contractAddress == counters[r.responses[idx].chainId].contractAddress, "contract address is wrong");

            // TODO: Is there an easier way to verify that the call data is correct!
            bytes memory callData = eqr.result[0].callData;
            bytes4 result;
            assembly {
                    result := mload(add(callData, 32))
                }
            require(result == GetMyCounter, "unexpected callData");

            require(eqr.result[0].result.length == 32, "result is not a uint256");
            counters[r.responses[idx].chainId].blockNum = eqr.blockNum;
            counters[r.responses[idx].chainId].blockTime = eqr.blockTime;
            counters[r.responses[idx].chainId].counter = abi.decode(eqr.result[0].result, (uint256));
        }

        counters[myChainID].counter += 1;
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "caller is not the owner");
        _;
    }
}

// contracts/query/QueryResponse.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "../libraries/external/BytesLib.sol";
import "../interfaces/IWormhole.sol";

/// @dev QueryResponse is a library that implements the parsing and verification of Cross Chain Query (CCQ) responses.
abstract contract QueryResponse {
    using BytesLib for bytes;
       
    /// @dev ParsedQueryResponse is returned by parseAndVerifyQueryResponse().
    struct ParsedQueryResponse {
        uint8   version;
        uint16  senderChainId;
        bytes   requestId; // 65 byte sig for off-chain, 32 byte vaaHash for on-chain
        uint32  nonce;
        ParsedPerChainQueryResponse [] responses;
    }

    /// @dev ParsedPerChainQueryResponse describes a single per-chain response.
    struct ParsedPerChainQueryResponse {
        uint16 chainId;
        uint8 queryType;
        bytes request;
        bytes response;
    }

    /// @dev EthCallQueryResponse describes an ETH call per-chain query.
    struct EthCallQueryResponse {
        bytes requestBlockId;
        uint64 blockNum;
        bytes32 blockHash;
        uint64 blockTime;
        EthCallData [] result;
    }

    /// @dev EthCallData describes a single ETH call query / response pair.
    struct EthCallData {
        address contractAddress;
        bytes callData;
        bytes result;
    }    

    bytes public constant responsePrefix = bytes("query_response_0000000000000000000|");

    /// @dev getResponseHash computes the hash of the specified query response.
    function getResponseHash(bytes memory response) public pure returns (bytes32) {
        return keccak256(response);
    }

    /// @dev getResponseDigest computes the digest of the specified query response.
    function getResponseDigest(bytes memory response) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(responsePrefix,getResponseHash(response)));
    }
    
    /// @dev parseAndVerifyQueryResponse verifies the query response and returns the parsed response.
    function parseAndVerifyQueryResponse(address wormhole, bytes memory response, IWormhole.Signature[] memory signatures) public view returns (ParsedQueryResponse memory r) {
        verifyQueryResponseSignatures(wormhole, response, signatures);

        uint index = 0;
        
        r.version = response.toUint8(index);
        require(r.version == 1, "invalid response version");
        index += 1;

        r.senderChainId = response.toUint16(index);
        index += 2;

        if (r.senderChainId == 0) {
            r.requestId = response.slice(index, 65);
            index += 65;
        } else {
            r.requestId = response.slice(index, 32);
            index += 32;
        }
        
        uint32 len = response.toUint32(index); // query_request_len
        index += 4;
        uint reqIdx = index;

        require(response.toUint8(reqIdx) == r.version, "version mismatch between request and response");
        reqIdx += 1;

        r.nonce = response.toUint32(reqIdx);
        reqIdx += 4;

        uint8 numPerChainQueries = response.toUint8(reqIdx);
        reqIdx += 1;

        // The response starts after the request.
        uint respIdx = index + len;

        require(response.toUint8(respIdx) == numPerChainQueries, "num_per_chain_responses does not match num_per_chain_queries");
        respIdx += 1;

        r.responses = new ParsedPerChainQueryResponse[](numPerChainQueries);

        // Walk through the requests and responses in lock step.
        for (uint idx = 0; idx < numPerChainQueries; idx++) {
            r.responses[idx].chainId = response.toUint16(reqIdx);
            require(response.toUint16(respIdx) == r.responses[idx].chainId, "reqChainId does not match respChainId");
            reqIdx += 2;
            respIdx += 2;

            r.responses[idx].queryType = response.toUint8(reqIdx);
            require(response.toUint8(respIdx) == r.responses[idx].queryType, "reqQueryType does not match respQueryType");
            reqIdx += 1;
            respIdx += 1;
            
            require(r.responses[idx].queryType == 1, "EthCall is the only supported query type");

            len = response.toUint32(reqIdx);
            reqIdx += 4;
            r.responses[idx].request = response.slice(reqIdx, len);
            reqIdx += len;

            len = response.toUint32(respIdx);
            respIdx += 4;
            r.responses[idx].response = response.slice(respIdx, len);
            respIdx += len;
        }

        return r;
    }

    /// @dev parseEthCallQueryResponse parses a ParsedPerChainQueryResponse for an ETH call per-chain query.
    function parseEthCallQueryResponse(ParsedPerChainQueryResponse memory pcr) public pure returns (EthCallQueryResponse memory r) {
        require(pcr.queryType == 1, "query type must be EthCall");

        uint reqIdx = 0;
        uint respIdx = 0;

        uint32 len = pcr.request.toUint32(reqIdx); // block_id_len
        reqIdx += 4;

        r.requestBlockId = pcr.request.slice(reqIdx, len);
        reqIdx += len;

        uint8 numBatchCallData = pcr.request.toUint8(reqIdx);
        reqIdx += 1;

        r.blockNum = pcr.response.toUint64(respIdx);
        respIdx += 8;

        r.blockHash = pcr.response.toBytes32(respIdx);
        respIdx += 32;

        r.blockTime = pcr.response.toUint64(respIdx);
        respIdx += 8;

        require(pcr.response.toUint8(respIdx) == numBatchCallData, "num results doesn't match num call datas");
        respIdx += 1;

        r.result = new EthCallData[](numBatchCallData);

        // Walk through the call data and results in lock step.
        for (uint idx = 0; idx < numBatchCallData; idx++) {
            r.result[idx].contractAddress = pcr.request.toAddress(reqIdx);
            reqIdx += 20;

            len = pcr.request.toUint32(reqIdx); // call_data_len
            reqIdx += 4;
            r.result[idx].callData = pcr.request.slice(reqIdx, len);
            reqIdx += len;

            len = pcr.response.toUint32(respIdx); // result_len
            respIdx += 4;
            r.result[idx].result = pcr.response.slice(respIdx, len);
            respIdx += len;
        }

        return r;
    }

    /**
     * @dev verifyQueryResponseSignatures serves to 
     * IWormhole.Signature expects the last byte to be bumped by 27 
     * see https://github.com/wormhole-foundation/wormhole/blob/637b1ee657de7de05f783cbb2078dd7d8bfda4d0/ethereum/contracts/Messages.sol#L174
     */
    function verifyQueryResponseSignatures(address _wormhole, bytes memory response, IWormhole.Signature[] memory signatures) public view {
        IWormhole wormhole = IWormhole(_wormhole);
        // TODO: make a verifyCurrentQuorum call on the core bridge so that there is only 1 cross call instead of 4
        uint32 gsi = wormhole.getCurrentGuardianSetIndex();
        IWormhole.GuardianSet memory guardianSet = wormhole.getGuardianSet(gsi);

        bytes32 responseHash = getResponseDigest(response);

       /**
        * @dev Checks whether the guardianSet has zero keys
        * WARNING: This keys check is critical to ensure the guardianSet has keys present AND to ensure
        * that guardianSet key size doesn't fall to zero and negatively impact quorum assessment.  If guardianSet
        * key length is 0 and vm.signatures length is 0, this could compromise the integrity of both vm and
        * signature verification.
        */
        if(guardianSet.keys.length == 0){
            revert("invalid guardian set");
        }

       /**
        * @dev We're using a fixed point number transformation with 1 decimal to deal with rounding.
        *   WARNING: This quorum check is critical to assessing whether we have enough Guardian signatures to validate a VM
        *   if making any changes to this, obtain additional peer review. If guardianSet key length is 0 and
        *   vm.signatures length is 0, this could compromise the integrity of both vm and signature verification.
        */
        if (signatures.length < wormhole.quorum(guardianSet.keys.length)){
            revert("no quorum");
        }

        /// @dev Verify the proposed vm.signatures against the guardianSet
        (bool signaturesValid, string memory invalidReason) = wormhole.verifySignatures(responseHash, signatures, guardianSet);
        if(!signaturesValid){
            revert(invalidReason);
        }

        /// If we are here, we've validated the VM is a valid multi-sig that matches the current guardianSet.
    }
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

// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface IWormhole {
    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;

        uint32 guardianSetIndex;
        Signature[] signatures;

        bytes32 hash;
    }

    struct ContractUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;

        address newContract;
    }

    struct GuardianSetUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;

        GuardianSet newGuardianSet;
        uint32 newGuardianSetIndex;
    }

    struct SetMessageFee {
        bytes32 module;
        uint8 action;
        uint16 chain;

        uint256 messageFee;
    }

    struct TransferFees {
        bytes32 module;
        uint8 action;
        uint16 chain;

        uint256 amount;
        bytes32 recipient;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;

        uint256 evmChainId;
        uint16 newChainId;
    }

    event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);
    event ContractUpgraded(address indexed oldContract, address indexed newContract);
    event GuardianSetAdded(uint32 indexed index);

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function initialize() external;

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (VM memory vm, bool valid, string memory reason);

    function verifyVM(VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(bytes32 hash, Signature[] memory signatures, GuardianSet memory guardianSet) external pure returns (bool valid, string memory reason);

    function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);

    function quorum(uint numGuardians) external pure returns (uint numSignaturesRequiredForQuorum);

    function getGuardianSet(uint32 index) external view returns (GuardianSet memory);

    function getCurrentGuardianSetIndex() external view returns (uint32);

    function getGuardianSetExpiry() external view returns (uint32);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function chainId() external view returns (uint16);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256);

    function evmChainId() external view returns (uint256);

    function nextSequence(address emitter) external view returns (uint64);

    function parseContractUpgrade(bytes memory encodedUpgrade) external pure returns (ContractUpgrade memory cu);

    function parseGuardianSetUpgrade(bytes memory encodedUpgrade) external pure returns (GuardianSetUpgrade memory gsu);

    function parseSetMessageFee(bytes memory encodedSetMessageFee) external pure returns (SetMessageFee memory smf);

    function parseTransferFees(bytes memory encodedTransferFees) external pure returns (TransferFees memory tf);

    function parseRecoverChainId(bytes memory encodedRecoverChainId) external pure returns (RecoverChainId memory rci);

    function submitContractUpgrade(bytes memory _vm) external;

    function submitSetMessageFee(bytes memory _vm) external;

    function submitNewGuardianSet(bytes memory _vm) external;

    function submitTransferFees(bytes memory _vm) external;

    function submitRecoverChainId(bytes memory _vm) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}