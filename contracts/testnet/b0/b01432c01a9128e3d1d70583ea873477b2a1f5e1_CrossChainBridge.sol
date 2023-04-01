// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

//     ███████    █████       █████ █████ ██████   ██████ ███████████  █████  █████  █████████
//   ███░░░░░███ ░░███       ░░███ ░░███ ░░██████ ██████ ░░███░░░░░███░░███  ░░███  ███░░░░░███
//  ███     ░░███ ░███        ░░███ ███   ░███░█████░███  ░███    ░███ ░███   ░███ ░███    ░░░
// ░███      ░███ ░███         ░░█████    ░███░░███ ░███  ░██████████  ░███   ░███ ░░█████████
// ░███      ░███ ░███          ░░███     ░███ ░░░  ░███  ░███░░░░░░   ░███   ░███  ░░░░░░░░███
// ░░███     ███  ░███      █    ░███     ░███      ░███  ░███         ░███   ░███  ███    ░███
//  ░░░███████░   ███████████    █████    █████     █████ █████        ░░████████  ░░█████████
//    ░░░░░░░    ░░░░░░░░░░░    ░░░░░    ░░░░░     ░░░░░ ░░░░░          ░░░░░░░░    ░░░░░░░░░

//============================================================================================//
//                                        GLOBAL TYPES                                        //
//============================================================================================//

/// @notice Actions to trigger state changes in the kernel. Passed by the executor
enum Actions {
    InstallModule,
    UpgradeModule,
    ActivatePolicy,
    DeactivatePolicy,
    ChangeExecutor,
    MigrateKernel
}

/// @notice Used by executor to select an action and a target contract for a kernel action
struct Instruction {
    Actions action;
    address target;
}

/// @notice Used to define which module functions a policy needs access to
struct Permissions {
    Keycode keycode;
    bytes4 funcSelector;
}

type Keycode is bytes5;

//============================================================================================//
//                                       UTIL FUNCTIONS                                       //
//============================================================================================//

error TargetNotAContract(address target_);
error InvalidKeycode(Keycode keycode_);

// solhint-disable-next-line func-visibility
function toKeycode(bytes5 keycode_) pure returns (Keycode) {
    return Keycode.wrap(keycode_);
}

// solhint-disable-next-line func-visibility
function fromKeycode(Keycode keycode_) pure returns (bytes5) {
    return Keycode.unwrap(keycode_);
}

// solhint-disable-next-line func-visibility
function ensureContract(address target_) view {
    if (target_.code.length == 0) revert TargetNotAContract(target_);
}

// solhint-disable-next-line func-visibility
function ensureValidKeycode(Keycode keycode_) pure {
    bytes5 unwrapped = Keycode.unwrap(keycode_);
    for (uint256 i = 0; i < 5; ) {
        bytes1 char = unwrapped[i];
        if (char < 0x41 || char > 0x5A) revert InvalidKeycode(keycode_); // A-Z only
        unchecked {
            i++;
        }
    }
}

//============================================================================================//
//                                        COMPONENTS                                          //
//============================================================================================//

/// @notice Generic adapter interface for kernel access in modules and policies.
abstract contract KernelAdapter {
    error KernelAdapter_OnlyKernel(address caller_);

    Kernel public kernel;

    constructor(Kernel kernel_) {
        kernel = kernel_;
    }

    /// @notice Modifier to restrict functions to be called only by kernel.
    modifier onlyKernel() {
        if (msg.sender != address(kernel)) revert KernelAdapter_OnlyKernel(msg.sender);
        _;
    }

    /// @notice Function used by kernel when migrating to a new kernel.
    function changeKernel(Kernel newKernel_) external onlyKernel {
        kernel = newKernel_;
    }
}

/// @notice Base level extension of the kernel. Modules act as independent state components to be
///         interacted with and mutated through policies.
/// @dev    Modules are installed and uninstalled via the executor.
abstract contract Module is KernelAdapter {
    error Module_PolicyNotPermitted(address policy_);

    constructor(Kernel kernel_) KernelAdapter(kernel_) {}

    /// @notice Modifier to restrict which policies have access to module functions.
    modifier permissioned() {
        if (
            msg.sender == address(kernel) ||
            !kernel.modulePermissions(KEYCODE(), Policy(msg.sender), msg.sig)
        ) revert Module_PolicyNotPermitted(msg.sender);
        _;
    }

    /// @notice 5 byte identifier for a module.
    function KEYCODE() public pure virtual returns (Keycode) {}

    /// @notice Returns which semantic version of a module is being implemented.
    /// @return major - Major version upgrade indicates breaking change to the interface.
    /// @return minor - Minor version change retains backward-compatible interface.
    function VERSION() external pure virtual returns (uint8 major, uint8 minor) {}

    /// @notice Initialization function for the module
    /// @dev    This function is called when the module is installed or upgraded by the kernel.
    /// @dev    MUST BE GATED BY onlyKernel. Used to encompass any initialization or upgrade logic.
    function INIT() external virtual onlyKernel {}
}

/// @notice Policies are application logic and external interface for the kernel and installed modules.
/// @dev    Policies are activated and deactivated in the kernel by the executor.
/// @dev    Module dependencies and function permissions must be defined in appropriate functions.
abstract contract Policy is KernelAdapter {
    error Policy_ModuleDoesNotExist(Keycode keycode_);

    constructor(Kernel kernel_) KernelAdapter(kernel_) {}

    /// @notice Easily accessible indicator for if a policy is activated or not.
    function isActive() external view returns (bool) {
        return kernel.isPolicyActive(this);
    }

    /// @notice Function to grab module address from a given keycode.
    function getModuleAddress(Keycode keycode_) internal view returns (address) {
        address moduleForKeycode = address(kernel.getModuleForKeycode(keycode_));
        if (moduleForKeycode == address(0)) revert Policy_ModuleDoesNotExist(keycode_);
        return moduleForKeycode;
    }

    /// @notice Define module dependencies for this policy.
    /// @return dependencies - Keycode array of module dependencies.
    function configureDependencies() external virtual returns (Keycode[] memory dependencies) {}

    /// @notice Function called by kernel to set module function permissions.
    /// @return requests - Array of keycodes and function selectors for requested permissions.
    function requestPermissions() external view virtual returns (Permissions[] memory requests) {}
}

/// @notice Main contract that acts as a central component registry for the protocol.
/// @dev    The kernel manages modules and policies. The kernel is mutated via predefined Actions,
/// @dev    which are input from any address assigned as the executor. The executor can be changed as needed.
contract Kernel {
    // =========  EVENTS ========= //

    event PermissionsUpdated(
        Keycode indexed keycode_,
        Policy indexed policy_,
        bytes4 funcSelector_,
        bool granted_
    );
    event ActionExecuted(Actions indexed action_, address indexed target_);

    // =========  ERRORS ========= //

    error Kernel_OnlyExecutor(address caller_);
    error Kernel_ModuleAlreadyInstalled(Keycode module_);
    error Kernel_InvalidModuleUpgrade(Keycode module_);
    error Kernel_PolicyAlreadyActivated(address policy_);
    error Kernel_PolicyNotActivated(address policy_);

    // =========  PRIVILEGED ADDRESSES ========= //

    /// @notice Address that is able to initiate Actions in the kernel. Can be assigned to a multisig or governance contract.
    address public executor;

    // =========  MODULE MANAGEMENT ========= //

    /// @notice Array of all modules currently installed.
    Keycode[] public allKeycodes;

    /// @notice Mapping of module address to keycode.
    mapping(Keycode => Module) public getModuleForKeycode;

    /// @notice Mapping of keycode to module address.
    mapping(Module => Keycode) public getKeycodeForModule;

    /// @notice Mapping of a keycode to all of its policy dependents. Used to efficiently reconfigure policy dependencies.
    mapping(Keycode => Policy[]) public moduleDependents;

    /// @notice Helper for module dependent arrays. Prevents the need to loop through array.
    mapping(Keycode => mapping(Policy => uint256)) public getDependentIndex;

    /// @notice Module <> Policy Permissions.
    /// @dev    Keycode -> Policy -> Function Selector -> bool for permission
    mapping(Keycode => mapping(Policy => mapping(bytes4 => bool))) public modulePermissions;

    // =========  POLICY MANAGEMENT ========= //

    /// @notice List of all active policies
    Policy[] public activePolicies;

    /// @notice Helper to get active policy quickly. Prevents need to loop through array.
    mapping(Policy => uint256) public getPolicyIndex;

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    constructor() {
        executor = msg.sender;
    }

    /// @notice Modifier to check if caller is the executor.
    modifier onlyExecutor() {
        if (msg.sender != executor) revert Kernel_OnlyExecutor(msg.sender);
        _;
    }

    function isPolicyActive(Policy policy_) public view returns (bool) {
        return activePolicies.length > 0 && activePolicies[getPolicyIndex[policy_]] == policy_;
    }

    /// @notice Main kernel function. Initiates state changes to kernel depending on Action passed in.
    function executeAction(Actions action_, address target_) external onlyExecutor {
        if (action_ == Actions.InstallModule) {
            ensureContract(target_);
            ensureValidKeycode(Module(target_).KEYCODE());
            _installModule(Module(target_));
        } else if (action_ == Actions.UpgradeModule) {
            ensureContract(target_);
            ensureValidKeycode(Module(target_).KEYCODE());
            _upgradeModule(Module(target_));
        } else if (action_ == Actions.ActivatePolicy) {
            ensureContract(target_);
            _activatePolicy(Policy(target_));
        } else if (action_ == Actions.DeactivatePolicy) {
            ensureContract(target_);
            _deactivatePolicy(Policy(target_));
        } else if (action_ == Actions.ChangeExecutor) {
            executor = target_;
        } else if (action_ == Actions.MigrateKernel) {
            ensureContract(target_);
            _migrateKernel(Kernel(target_));
        }

        emit ActionExecuted(action_, target_);
    }

    function _installModule(Module newModule_) internal {
        Keycode keycode = newModule_.KEYCODE();

        if (address(getModuleForKeycode[keycode]) != address(0))
            revert Kernel_ModuleAlreadyInstalled(keycode);

        getModuleForKeycode[keycode] = newModule_;
        getKeycodeForModule[newModule_] = keycode;
        allKeycodes.push(keycode);

        newModule_.INIT();
    }

    function _upgradeModule(Module newModule_) internal {
        Keycode keycode = newModule_.KEYCODE();
        Module oldModule = getModuleForKeycode[keycode];

        if (address(oldModule) == address(0) || oldModule == newModule_)
            revert Kernel_InvalidModuleUpgrade(keycode);

        getKeycodeForModule[oldModule] = Keycode.wrap(bytes5(0));
        getKeycodeForModule[newModule_] = keycode;
        getModuleForKeycode[keycode] = newModule_;

        newModule_.INIT();

        _reconfigurePolicies(keycode);
    }

    function _activatePolicy(Policy policy_) internal {
        if (isPolicyActive(policy_)) revert Kernel_PolicyAlreadyActivated(address(policy_));

        // Add policy to list of active policies
        activePolicies.push(policy_);
        getPolicyIndex[policy_] = activePolicies.length - 1;

        // Record module dependencies
        Keycode[] memory dependencies = policy_.configureDependencies();
        uint256 depLength = dependencies.length;

        for (uint256 i; i < depLength; ) {
            Keycode keycode = dependencies[i];

            moduleDependents[keycode].push(policy_);
            getDependentIndex[keycode][policy_] = moduleDependents[keycode].length - 1;

            unchecked {
                ++i;
            }
        }

        // Grant permissions for policy to access restricted module functions
        Permissions[] memory requests = policy_.requestPermissions();
        _setPolicyPermissions(policy_, requests, true);
    }

    function _deactivatePolicy(Policy policy_) internal {
        if (!isPolicyActive(policy_)) revert Kernel_PolicyNotActivated(address(policy_));

        // Revoke permissions
        Permissions[] memory requests = policy_.requestPermissions();
        _setPolicyPermissions(policy_, requests, false);

        // Remove policy from all policy data structures
        uint256 idx = getPolicyIndex[policy_];
        Policy lastPolicy = activePolicies[activePolicies.length - 1];

        activePolicies[idx] = lastPolicy;
        activePolicies.pop();
        getPolicyIndex[lastPolicy] = idx;
        delete getPolicyIndex[policy_];

        // Remove policy from module dependents
        _pruneFromDependents(policy_);
    }

    /// @notice All functionality will move to the new kernel. WARNING: ACTION WILL BRICK THIS KERNEL.
    /// @dev    New kernel must add in all of the modules and policies via executeAction.
    /// @dev    NOTE: Data does not get cleared from this kernel.
    function _migrateKernel(Kernel newKernel_) internal {
        uint256 keycodeLen = allKeycodes.length;
        for (uint256 i; i < keycodeLen; ) {
            Module module = Module(getModuleForKeycode[allKeycodes[i]]);
            module.changeKernel(newKernel_);
            unchecked {
                ++i;
            }
        }

        uint256 policiesLen = activePolicies.length;
        for (uint256 j; j < policiesLen; ) {
            Policy policy = activePolicies[j];

            // Deactivate before changing kernel
            policy.changeKernel(newKernel_);
            unchecked {
                ++j;
            }
        }
    }

    function _reconfigurePolicies(Keycode keycode_) internal {
        Policy[] memory dependents = moduleDependents[keycode_];
        uint256 depLength = dependents.length;

        for (uint256 i; i < depLength; ) {
            dependents[i].configureDependencies();

            unchecked {
                ++i;
            }
        }
    }

    function _setPolicyPermissions(
        Policy policy_,
        Permissions[] memory requests_,
        bool grant_
    ) internal {
        uint256 reqLength = requests_.length;
        for (uint256 i = 0; i < reqLength; ) {
            Permissions memory request = requests_[i];
            modulePermissions[request.keycode][policy_][request.funcSelector] = grant_;

            emit PermissionsUpdated(request.keycode, policy_, request.funcSelector, grant_);

            unchecked {
                ++i;
            }
        }
    }

    function _pruneFromDependents(Policy policy_) internal {
        Keycode[] memory dependencies = policy_.configureDependencies();
        uint256 depcLength = dependencies.length;

        for (uint256 i; i < depcLength; ) {
            Keycode keycode = dependencies[i];
            Policy[] storage dependents = moduleDependents[keycode];

            uint256 origIndex = getDependentIndex[keycode][policy_];
            Policy lastPolicy = dependents[dependents.length - 1];

            // Swap with last and pop
            dependents[origIndex] = lastPolicy;
            dependents.pop();

            // Record new index and delete deactivated policy index
            getDependentIndex[keycode][lastPolicy] = origIndex;
            delete getDependentIndex[keycode][policy_];

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

/// @notice Olympus OHM token
/// @dev This contract is the legacy v2 OHM token. Included in the repo for completeness,
///      since it is not being changed and is imported in some contracts.

interface IOlympusAuthority {
    // =========  EVENTS ========= //

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    // =========  VIEW ========= //

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}

// File: types/OlympusAccessControlled.sol

abstract contract OlympusAccessControlled {
    // =========  EVENTS ========= //

    event AuthorityUpdated(IOlympusAuthority indexed authority);

    string internal UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    // =========  STATE VARIABLES ========= //

    IOlympusAuthority public authority;

    // =========  Constructor ========= //

    constructor(IOlympusAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    // =========  MODIFIERS ========= //

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPermitted() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    // =========  GOV ONLY ========= //

    function setAuthority(IOlympusAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// File: cryptography/ECDSA.sol

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address, RecoverError)
    {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// File: cryptography/EIP712.sol

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = chainID;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        if (chainID == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        return keccak256(abi.encode(typeHash, nameHash, versionHash, chainID, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// File: interfaces/IERC20Permit.sol

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as th xe allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: interfaces/IERC20.sol

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: interfaces/IOHM.sol

interface IOHM is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}

// File: libraries/SafeMath.sol

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + (a % b)); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// File: libraries/Counters.sol

library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// File: types/ERC20.sol

abstract contract ERC20 is IERC20 {
    using SafeMath for uint256;

    // TODO comment actual hash value.
    bytes32 private constant ERC20TOKEN_ERC1820_INTERFACE_ID = keccak256("ERC20Token");

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;

    string internal _symbol;

    uint8 internal immutable _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {}
}

// File: types/ERC20Permit.sol

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline)
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// File: OlympusERC20.sol

contract OlympusERC20Token is ERC20Permit, IOHM, OlympusAccessControlled {
    using SafeMath for uint256;

    constructor(address _authority)
        ERC20("Olympus", "OHM", 9)
        ERC20Permit("Olympus")
        OlympusAccessControlled(IOlympusAuthority(_authority))
    {}

    function mint(address account_, uint256 amount_) external override onlyVault {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) external override {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal {
        uint256 decreasedAllowance_ = allowance(account_, msg.sender).sub(
            amount_,
            "ERC20: burn amount exceeds allowance"
        );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import {OlympusERC20Token as OHM} from "src/external/OlympusERC20.sol";
import "src/Kernel.sol";

/// @notice Wrapper for minting and burning functions of OHM token.
abstract contract MINTRv1 is Module {
    // =========  EVENTS ========= //

    event IncreaseMintApproval(address indexed policy_, uint256 newAmount_);
    event DecreaseMintApproval(address indexed policy_, uint256 newAmount_);
    event Mint(address indexed policy_, address indexed to_, uint256 amount_);
    event Burn(address indexed policy_, address indexed from_, uint256 amount_);

    // ========= ERRORS ========= //

    error MINTR_NotApproved();
    error MINTR_ZeroAmount();
    error MINTR_NotActive();

    // =========  STATE ========= //

    OHM public ohm;

    /// @notice Status of the minter. If false, minting and burning OHM is disabled.
    bool public active;

    /// @notice Mapping of who is approved for minting.
    /// @dev    minter -> amount. Infinite approval is max(uint256).
    mapping(address => uint256) public mintApproval;

    // =========  FUNCTIONS ========= //

    modifier onlyWhileActive() {
        if (!active) revert MINTR_NotActive();
        _;
    }

    /// @notice Mint OHM to an address.
    function mintOhm(address to_, uint256 amount_) external virtual;

    /// @notice Burn OHM from an address. Must have approval.
    function burnOhm(address from_, uint256 amount_) external virtual;

    /// @notice Increase approval for specific withdrawer addresses
    /// @dev    Policies must explicity request how much they want approved before withdrawing.
    function increaseMintApproval(address policy_, uint256 amount_) external virtual;

    /// @notice Decrease approval for specific withdrawer addresses
    function decreaseMintApproval(address policy_, uint256 amount_) external virtual;

    /// @notice Emergency shutdown of minting and burning.
    function deactivate() external virtual;

    /// @notice Re-activate minting and burning after shutdown.
    function activate() external virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import {ROLESv1} from "src/modules/ROLES/ROLES.v1.sol";
import "src/Kernel.sol";

/// @notice Abstract contract to have the `onlyRole` modifier
/// @dev    Inheriting this automatically makes ROLES module a dependency
abstract contract RolesConsumer {
    ROLESv1 public ROLES;

    modifier onlyRole(bytes32 role_) {
        ROLES.requireRole(role_, msg.sender);
        _;
    }
}

/// @notice Module that holds multisig roles needed by various policies.
contract OlympusRoles is ROLESv1 {
    //============================================================================================//
    //                                        MODULE SETUP                                        //
    //============================================================================================//

    constructor(Kernel kernel_) Module(kernel_) {}

    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Keycode) {
        return toKeycode("ROLES");
    }

    /// @inheritdoc Module
    function VERSION() external pure override returns (uint8 major, uint8 minor) {
        major = 1;
        minor = 0;
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc ROLESv1
    function saveRole(bytes32 role_, address addr_) external override permissioned {
        if (hasRole[addr_][role_]) revert ROLES_AddressAlreadyHasRole(addr_, role_);

        ensureValidRole(role_);

        // Grant role to the address
        hasRole[addr_][role_] = true;

        emit RoleGranted(role_, addr_);
    }

    /// @inheritdoc ROLESv1
    function removeRole(bytes32 role_, address addr_) external override permissioned {
        if (!hasRole[addr_][role_]) revert ROLES_AddressDoesNotHaveRole(addr_, role_);

        hasRole[addr_][role_] = false;

        emit RoleRevoked(role_, addr_);
    }

    //============================================================================================//
    //                                       VIEW FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc ROLESv1
    function requireRole(bytes32 role_, address caller_) external view override {
        if (!hasRole[caller_][role_]) revert ROLES_RequireRole(role_);
    }

    /// @inheritdoc ROLESv1
    function ensureValidRole(bytes32 role_) public pure override {
        for (uint256 i = 0; i < 32; ) {
            bytes1 char = role_[i];
            if ((char < 0x61 || char > 0x7A) && char != 0x5f && char != 0x00) {
                revert ROLES_InvalidRole(role_); // a-z only
            }
            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import "src/Kernel.sol";

abstract contract ROLESv1 is Module {
    // =========  EVENTS ========= //

    event RoleGranted(bytes32 indexed role_, address indexed addr_);
    event RoleRevoked(bytes32 indexed role_, address indexed addr_);

    // =========  ERRORS ========= //

    error ROLES_InvalidRole(bytes32 role_);
    error ROLES_RequireRole(bytes32 role_);
    error ROLES_AddressAlreadyHasRole(address addr_, bytes32 role_);
    error ROLES_AddressDoesNotHaveRole(address addr_, bytes32 role_);
    error ROLES_RoleDoesNotExist(bytes32 role_);

    // =========  STATE ========= //

    /// @notice Mapping for if an address has a policy-defined role.
    mapping(address => mapping(bytes32 => bool)) public hasRole;

    // =========  FUNCTIONS ========= //

    /// @notice Function to grant policy-defined roles to some address. Can only be called by admin.
    function saveRole(bytes32 role_, address addr_) external virtual;

    /// @notice Function to revoke policy-defined roles from some address. Can only be called by admin.
    function removeRole(bytes32 role_, address addr_) external virtual;

    /// @notice "Modifier" to restrict policy function access to certain addresses with a role.
    /// @dev    Roles are defined in the policy and granted by the ROLES admin.
    function requireRole(bytes32 role_, address caller_) external virtual;

    /// @notice Function that checks if role is valid (all lower case)
    function ensureValidRole(bytes32 role_) external pure virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {ILayerZeroUserApplicationConfig} from "layer-zero/interfaces/ILayerZeroUserApplicationConfig.sol";
import {ILayerZeroEndpoint} from "layer-zero/interfaces/ILayerZeroEndpoint.sol";
import {ILayerZeroReceiver} from "layer-zero/interfaces/ILayerZeroReceiver.sol";
import {BytesLib} from "layer-zero/util/BytesLib.sol";

import {RolesConsumer} from "modules/ROLES/OlympusRoles.sol";
import {ROLESv1} from "modules/ROLES/ROLES.v1.sol";
import {MINTRv1} from "modules/MINTR/MINTR.v1.sol";

import "src/Kernel.sol";

/// @notice Message bridge for cross-chain OHM transfers.
/// @dev Uses LayerZero as communication protocol.
/// @dev Each chain needs to `setTrustedRemoteAddress` for each remote address
///      it intends to receive from.
contract CrossChainBridge is
    Policy,
    RolesConsumer,
    ILayerZeroReceiver,
    ILayerZeroUserApplicationConfig
{
    using BytesLib for bytes;

    // Bridge errors
    error Bridge_InsufficientAmount();
    error Bridge_InvalidCaller();
    error Bridge_InvalidMessageSource();
    error Bridge_NoStoredMessage();
    error Bridge_InvalidPayload();
    error Bridge_DestinationNotTrusted();
    error Bridge_NoTrustedPath();
    error Bridge_Deactivated();
    error Bridge_TrustedRemoteUninitialized();

    // Bridge-specific events
    event BridgeTransferred(address sender_, uint256 amount_, uint16 dstChain_);
    event BridgeReceived(address receiver_, uint256 amount_, uint16 srcChain_);

    // LZ app events
    event MessageFailed(
        uint16 srcChainId_,
        bytes srcAddress_,
        uint64 nonce_,
        bytes payload_,
        bytes reason_
    );
    event RetryMessageSuccess(
        uint16 srcChainId_,
        bytes srcAddress_,
        uint64 nonce_,
        bytes32 payloadHash_
    );
    event SetPrecrime(address precrime_);
    event SetTrustedRemote(uint16 remoteChainId_, bytes path_);
    event SetTrustedRemoteAddress(uint16 remoteChainId_, bytes remoteAddress_);
    event SetMinDstGas(uint16 dstChainId_, uint16 type_, uint256 _minDstGas);
    event BridgeStatusSet(bool isActive_);

    // Modules
    MINTRv1 public MINTR;

    ILayerZeroEndpoint public immutable lzEndpoint;
    ERC20 ohm;

    /// @notice Flag to determine if bridge is allowed to send messages or not
    bool public bridgeActive;

    // LZ app state

    /// @notice Storage for failed messages on receive.
    /// @notice chainID => source address => endpoint nonce
    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    /// @notice Trusted remote paths. Must be set by admin.
    mapping(uint16 => bytes) public trustedRemoteLookup;

    /// @notice LZ precrime address. Currently unused.
    address public precrime;

    //============================================================================================//
    //                                        POLICY SETUP                                        //
    //============================================================================================//

    constructor(Kernel kernel_, address endpoint_) Policy(kernel_) {
        lzEndpoint = ILayerZeroEndpoint(endpoint_);
        bridgeActive = true;
    }

    /// @inheritdoc Policy
    function configureDependencies() external override returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](2);
        dependencies[0] = toKeycode("MINTR");
        dependencies[1] = toKeycode("ROLES");

        MINTR = MINTRv1(getModuleAddress(dependencies[0]));
        ROLES = ROLESv1(getModuleAddress(dependencies[1]));

        ohm = ERC20(address(MINTR.ohm()));
    }

    /// @inheritdoc Policy
    function requestPermissions()
        external
        view
        override
        returns (Permissions[] memory permissions)
    {
        Keycode MINTR_KEYCODE = MINTR.KEYCODE();

        permissions = new Permissions[](3);
        permissions[0] = Permissions(MINTR_KEYCODE, MINTR.mintOhm.selector);
        permissions[1] = Permissions(MINTR_KEYCODE, MINTR.burnOhm.selector);
        permissions[2] = Permissions(MINTR_KEYCODE, MINTR.increaseMintApproval.selector);
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    /// @notice Send OHM to an eligible chain
    function sendOhm(
        uint16 dstChainId_,
        address to_,
        uint256 amount_
    ) external payable {
        if (!bridgeActive) revert Bridge_Deactivated();
        if (ohm.balanceOf(msg.sender) < amount_) revert Bridge_InsufficientAmount();

        bytes memory payload = abi.encode(to_, amount_);

        MINTR.burnOhm(msg.sender, amount_);
        _sendMessage(dstChainId_, payload, payable(msg.sender), address(0x0), bytes(""), msg.value);

        emit BridgeTransferred(msg.sender, amount_, dstChainId_);
    }

    /// @notice Implementation of receiving an LZ message
    /// @dev    Function must be public to be called by low-level call in lzReceive
    function _receiveMessage(
        uint16 srcChainId_,
        bytes memory,
        uint64,
        bytes memory payload_
    ) internal {
        (address to, uint256 amount) = abi.decode(payload_, (address, uint256));

        MINTR.increaseMintApproval(address(this), amount);
        MINTR.mintOhm(to, amount);

        emit BridgeReceived(to, amount, srcChainId_);
    }

    // ========= LZ Receive Functions ========= //

    /// @inheritdoc ILayerZeroReceiver
    function lzReceive(
        uint16 srcChainId_,
        bytes calldata srcAddress_,
        uint64 nonce_,
        bytes calldata payload_
    ) public virtual override {
        // lzReceive must be called by the endpoint for security
        if (msg.sender != address(lzEndpoint)) revert Bridge_InvalidCaller();

        // Will still block the message pathway from (srcChainId, srcAddress).
        // Should not receive messages from untrusted remote.
        bytes memory trustedRemote = trustedRemoteLookup[srcChainId_];
        if (
            trustedRemote.length == 0 ||
            srcAddress_.length != trustedRemote.length ||
            keccak256(srcAddress_) != keccak256(trustedRemote)
        ) revert Bridge_InvalidMessageSource();

        // NOTE: Use low-level call to handle any errors. We trust the underlying receive
        // implementation, so we are doing a regular call vs using ExcessivelySafeCall
        (bool success, bytes memory reason) = address(this).call(
            abi.encodeWithSelector(
                this.receiveMessage.selector,
                srcChainId_,
                srcAddress_,
                nonce_,
                payload_
            )
        );

        // If message fails, store message for retry
        if (!success) {
            failedMessages[srcChainId_][srcAddress_][nonce_] = keccak256(payload_);
            emit MessageFailed(srcChainId_, srcAddress_, nonce_, payload_, reason);
        }
    }

    /// @notice Implementation of receiving an LZ message
    /// @dev    Function must be public to be called by low-level call in lzReceive
    function receiveMessage(
        uint16 srcChainId_,
        bytes memory srcAddress_,
        uint64 nonce_,
        bytes memory payload_
    ) public {
        // Needed to restrict access to low-level call from lzReceive
        if (msg.sender != address(this)) revert Bridge_InvalidCaller();
        _receiveMessage(srcChainId_, srcAddress_, nonce_, payload_);
    }

    /// @notice Retry a failed receive message
    function retryMessage(
        uint16 srcChainId_,
        bytes calldata srcAddress_,
        uint64 nonce_,
        bytes calldata payload_
    ) public payable virtual {
        // Assert there is message to retry
        bytes32 payloadHash = failedMessages[srcChainId_][srcAddress_][nonce_];
        if (payloadHash == bytes32(0)) revert Bridge_NoStoredMessage();
        if (keccak256(payload_) != payloadHash) revert Bridge_InvalidPayload();

        // Clear the stored message
        failedMessages[srcChainId_][srcAddress_][nonce_] = bytes32(0);

        // Execute the message. revert if it fails again
        _receiveMessage(srcChainId_, srcAddress_, nonce_, payload_);

        emit RetryMessageSuccess(srcChainId_, srcAddress_, nonce_, payloadHash);
    }

    // ========= LZ Send Functions ========= //

    /// @notice Internal function for sending a message across chains.
    /// @dev    Params defined in ILayerZeroEndpoint `send` function.
    function _sendMessage(
        uint16 dstChainId_,
        bytes memory payload_,
        address payable refundAddress_,
        address zroPaymentAddress_,
        bytes memory adapterParams_,
        uint256 nativeFee_
    ) internal {
        bytes memory trustedRemote = trustedRemoteLookup[dstChainId_];
        if (trustedRemote.length == 0) revert Bridge_DestinationNotTrusted();

        lzEndpoint.send{value: nativeFee_}(
            dstChainId_,
            trustedRemote,
            payload_,
            refundAddress_,
            zroPaymentAddress_,
            adapterParams_
        );
    }

    /// @notice Function to estimate how much gas is needed to send OHM
    /// @dev    Should be called by frontend before making sendOhm call.
    /// @return nativeFee - Native token amount to send to sendOhm
    /// @return zroFee - Fee paid in ZRO token. Unused.
    function estimateSendFee(
        uint16 dstChainId_,
        address to_,
        uint256 amount_,
        bytes calldata adapterParams_
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        // Mock the payload for sendOhm()
        bytes memory payload = abi.encode(to_, amount_);
        return lzEndpoint.estimateFees(dstChainId_, address(this), payload, false, adapterParams_);
    }

    // ========= LZ UserApplication & Admin config ========= //

    /// @notice Generic config for LayerZero User Application
    function setConfig(
        uint16 version_,
        uint16 chainId_,
        uint256 configType_,
        bytes calldata config_
    ) external override onlyRole("bridge_admin") {
        lzEndpoint.setConfig(version_, chainId_, configType_, config_);
    }

    /// @notice Set send version of endpoint to be used by LayerZero User Application
    function setSendVersion(uint16 version_) external override onlyRole("bridge_admin") {
        lzEndpoint.setSendVersion(version_);
    }

    /// @notice Set receive version of endpoint to be used by LayerZero User Application
    function setReceiveVersion(uint16 version_) external override onlyRole("bridge_admin") {
        lzEndpoint.setReceiveVersion(version_);
    }

    /// @notice Retries a received message. Used as last resort if retryPayload fails.
    /// @dev    Unblocks queue and DESTROYS transaction forever. USE WITH CAUTION.
    function forceResumeReceive(uint16 srcChainId_, bytes calldata srcAddress_)
        external
        override
        onlyRole("bridge_admin")
    {
        lzEndpoint.forceResumeReceive(srcChainId_, srcAddress_);
    }

    /// @notice Sets the trusted path for the cross-chain communication
    /// @dev    path_ = abi.encodePacked(remoteAddress, localAddress)
    function setTrustedRemote(uint16 srcChainId_, bytes calldata path_)
        external
        onlyRole("bridge_admin")
    {
        trustedRemoteLookup[srcChainId_] = path_;
        emit SetTrustedRemote(srcChainId_, path_);
    }

    /// @notice Convenience function for setting trusted paths between EVM addresses
    function setTrustedRemoteAddress(uint16 remoteChainId_, bytes calldata remoteAddress_)
        external
        onlyRole("bridge_admin")
    {
        trustedRemoteLookup[remoteChainId_] = abi.encodePacked(remoteAddress_, address(this));
        emit SetTrustedRemoteAddress(remoteChainId_, remoteAddress_);
    }

    /// @notice Sets precrime address
    function setPrecrime(address precrime_) external onlyRole("bridge_admin") {
        precrime = precrime_;
        emit SetPrecrime(precrime_);
    }

    /// @notice Activate or deactivate the bridge
    function setBridgeStatus(bool isActive_) external onlyRole("bridge_admin") {
        bridgeActive = isActive_;
        emit BridgeStatusSet(isActive_);
    }

    // ========= View Functions ========= //

    /// @notice Gets endpoint config for this contract
    function getConfig(
        uint16 version_,
        uint16 chainId_,
        address,
        uint256 configType_
    ) external view returns (bytes memory) {
        return lzEndpoint.getConfig(version_, chainId_, address(this), configType_);
    }

    /// @notice Get trusted remote for the given chain as an
    function getTrustedRemoteAddress(uint16 remoteChainId_) external view returns (bytes memory) {
        bytes memory path = trustedRemoteLookup[remoteChainId_];
        if (path.length == 0) revert Bridge_NoTrustedPath();

        // The last 20 bytes should be address(this)
        return path.slice(0, path.length - 20);
    }

    function isTrustedRemote(uint16 srcChainId_, bytes calldata srcAddress_)
        external
        view
        returns (bool)
    {
        bytes memory trustedSource = trustedRemoteLookup[srcChainId_];
        if (srcAddress_.length == 0 || trustedSource.length == 0)
            revert Bridge_TrustedRemoteUninitialized();
        return (srcAddress_.length == trustedSource.length &&
            keccak256(srcAddress_) == keccak256(trustedSource));
    }
}