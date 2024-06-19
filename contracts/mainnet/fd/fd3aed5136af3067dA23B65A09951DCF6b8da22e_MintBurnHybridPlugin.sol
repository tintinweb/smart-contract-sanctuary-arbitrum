// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/interfaces/SimplePluginConstants.sol";
import "contracts/impl/BasicSimplePlugin.sol";
import "contracts/token/modular/IModularERC20Ops.sol";
import "contracts/token/modular/IModularViciERC20.sol";
import "contracts/token/modular/hybrid/ViciERC20HybridPlugin.sol";

/**
 * @title Mint and Burn plugin
 * @author Josh Davis
 * @notice This plugin adds mint() and burn() functions
 * @notice The validation only allows those functions to be called by a user with the MINTER role
 */

interface IMintBurnHybridPlugin {
    /**
     * @dev Creates `amount` of tokens and assigns them to `toAddress`, by transferring it from address(0).
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - Calling user MUST be owner or have the minter role.
     * - Calling user MUST NOT be banned.
     * - `toAddress` MUST NOT be 0x0.
     * - `toAddress` MUST NOT be banned.
     */
    function mint(
        address toAddress,
        uint256 amount
    ) external returns (bytes memory);

    /**
     * @dev Destroys `amount` of tokens from `fromAddress`, lowering the total supply.
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - Calling user MUST be owner or have the minter role.
     * - Calling user MUST NOT be banned.
     * - Calling user MUST own the token or be authorized by the owner to
     *     transfer the token.
     */
    function burn(
        address fromAddress,
        uint256 amount
    ) external returns (bytes memory);
}

contract MintBurnHybridPlugin is ViciERC20HybridPlugin {
    bytes4 constant MINT = IMintBurnHybridPlugin.mint.selector;
    bytes4 constant BURN = IMintBurnHybridPlugin.burn.selector;

    function validates()
        public
        view
        virtual
        override
        returns (bytes4[] memory funcs)
    {
        funcs = new bytes4[](2);
        funcs[0] = MINT;
        funcs[1] = BURN;
    }

    function _beforeHook(
        Message calldata _msg
    ) internal virtual override returns (bytes memory result) {
        if (_msg.sig == MINT || _msg.sig == BURN) {
            if (_msg.data.length != 68) {
                revert InvalidCallData(_msg.sig);
            }
            enforceOwnerOrRole(msg.sender, MINTER_ROLE_NAME, _msg.sender);
            return TRUE;
        }

        return super._beforeHook(_msg);
    }

    function executes()
        public
        view
        virtual
        override
        returns (bytes4[] memory funcs)
    {
        funcs = new bytes4[](2);
        funcs[0] = MINT;
        funcs[1] = BURN;
    }

    function _execute(
        Message calldata _msg
    ) internal virtual override returns (bytes memory) {
        if (_msg.sig == MINT) {
            (address toAddress, uint256 amount) = abi.decode(
                _msg.data[4:],
                (address, uint256)
            );
            return _doMint(_msg.sender, toAddress, amount);
        }
        if (_msg.sig == BURN) {
            (address fromAddress, uint256 amount) = abi.decode(
                _msg.data[4:],
                (address, uint256)
            );
            return _doBurn(_msg.sender, fromAddress, amount);
        }

        return super._execute(_msg);
    }

    function _doMint(
        address operator,
        address toAddress,
        uint256 amount
    ) internal virtual returns (bytes memory) {
        (ISimplePluginExecutor(msg.sender)).executeFromPlugin(
            abi.encodeWithSelector(
                IModularERC20Ops.mint.selector,
                operator,
                toAddress,
                amount
            )
        );
        return TRUE;
    }

    function _doBurn(
        address operator,
        address fromAddress,
        uint256 amount
    ) internal virtual returns (bytes memory) {
        (ISimplePluginExecutor(msg.sender)).executeFromPlugin(
            abi.encodeWithSelector(
                IModularERC20Ops.burn.selector,
                operator,
                fromAddress,
                amount
            )
        );
        return TRUE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

bytes constant FALSE = abi.encodePacked(uint256(0));
bytes constant TRUE = abi.encodePacked(uint256(1));

bytes constant BEFORE_HOOK_SELECTOR = "0x55cdfb83";
bytes constant AFTER_HOOK_SELECTOR = "0x495b0f93";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/lib/BytesLib.sol";
import "contracts/interfaces/ISimplePluginExecutor.sol";
import "contracts/interfaces/ISimplePlugin.sol";
import "contracts/interfaces/PluginErrorsAndEvents.sol";

/**
 * @title Basic Simple Plugin
 * @author Josh Davis
 * @notice Provides functionlity that any plugin would need.
 */
abstract contract BasicSimplePlugin is ISimplePlugin, PluginErrorsAndEvents {
    using BytesLib for bytes;
    uint256 constant MAX_ARRAY = 0xffffffffffffffff;

    /**
     * @notice For functions that can only be called by a Plugin Executor
     */
    modifier onlyExecutor() {
        validateExecutor(msg.sender);
        _;
    }

    /**
     * @notice Helper function for ensuring that a portion of the call data is a valid abi-encoded array.
     * @dev This won't work for arrays of strings or bytes
     * @param data The call data that contains an array
     * @param startPos The array's start position in the call data
     * @return isValid True if the array is valid
     * @return arrayEnd The position at the end of the array. If the array is the last thing in the call data, then 
     *      this will be equal to the length of the call data
     */
    function validateArray(
        bytes calldata data,
        uint256 startPos
    ) internal pure returns (bool isValid, uint256 arrayEnd) {
        uint256 arraySize = data.toUint256(startPos + 32);
        if (arraySize >= MAX_ARRAY) {
            return (false, MAX_ARRAY);
        }

        uint256 arrayStart = data.toUint256(startPos);
        arrayEnd = (startPos + 64) + 32 * arraySize;
        isValid = (arrayStart == startPos + 32 &&
            data.length >= arrayEnd);
    }

    /**
     * @notice Helper function for ensuring that a portion of the call data is a valid abi-encoded bytes object.
     * @param data The call data that contains an bytes object
     * @param startPos The bytes object's start position in the call data
     * @return isValid True if the bytes object is valid
     * @return arrayEnd The position at the end of the bytes object. If the bytes object is the last thing in the 
     *      call data, then this will be equal to the length of the call data
     */
    function validateBytes(
        bytes calldata data,
        uint256 startPos
    ) internal pure returns (bool isValid, uint256 arrayEnd) {
        uint256 bytesLength = data.toUint256(startPos + 32);
        bytesLength = (bytesLength == 0) ? 1 : bytesLength;
        uint256 wordCount = (bytesLength - 1) / 32 + 1;

        if (wordCount >= MAX_ARRAY) {
            return (false, MAX_ARRAY);
        }

        uint256 arrayStart = data.toUint256(startPos);
        arrayEnd = (startPos + 64) + 32 * wordCount;
        isValid = (arrayStart == startPos + 32 &&
            data.length >= arrayEnd);
    }

    /**
     * @dev reverts with InvalidPluginExecutor if the address is not a contract that implements ISimplePluginExecutor
     * @dev this function SHOULD be overridden by sublcasses with stricter requirements
     * @param maybeExecutor an address that may or may not be an executor
     */
    function validateExecutor(
        address maybeExecutor
    ) internal view virtual returns (bool) {
        try
            ISimplePluginExecutor(maybeExecutor).supportsInterface(
                type(ISimplePluginExecutor).interfaceId
            )
        returns (bool ok) {
            return ok;
        } catch {
            revert InvalidPluginExecutor(maybeExecutor);
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(ISimplePlugin).interfaceId;
    }

    ///@inheritdoc ISimplePlugin
    function onInstall(bytes calldata data) public override onlyExecutor {
        _onInstall(data);
    }
    /**
     * @dev override this function if anything is required on installation
     */
    function _onInstall(bytes calldata data) internal virtual {}

    ///@inheritdoc ISimplePlugin
    function onUninstall(bytes calldata data) public virtual override onlyExecutor {
        _onUninstall(data);
    }
    /**
     * @dev override this function if anything is required on uninstall
     */
    function _onUninstall(bytes calldata data) internal virtual {}

    ///@inheritdoc ISimplePlugin
    function providedInterfaces() public view virtual override returns (bytes4[] memory) {
        return new bytes4[](0);
    }

    ///@inheritdoc ISimplePlugin
    function validates() public view virtual override returns (bytes4[] memory) {
        return new bytes4[](0);
    }

    ///@inheritdoc ISimplePlugin
    function executes() public view virtual override returns (bytes4[] memory) {
        return new bytes4[](0);
    }

    ///@inheritdoc ISimplePlugin
    function postExecs() public view virtual override returns (bytes4[] memory) {
        return new bytes4[](0);
    }

    ///@inheritdoc ISimplePlugin
    function beforeHook(
        Message calldata _msg
    ) public payable override onlyExecutor returns (bytes memory) {
        return _beforeHook(_msg);
    }
    function _beforeHook(
        Message calldata
    ) internal virtual returns (bytes memory) {
        return bytes("");
    }

    ///@inheritdoc ISimplePlugin
    function execute(
        Message calldata _msg
    ) public payable override onlyExecutor returns (bytes memory) {
        return _execute(_msg);
    }
    function _execute(
        Message calldata
    ) internal virtual returns (bytes memory) {
        return bytes("");
    }

    ///@inheritdoc ISimplePlugin
    function afterHook(
        Message calldata _msg
    ) public payable override onlyExecutor returns (bytes memory) {
        return _afterHook(_msg);
    }
    function _afterHook(
        Message calldata
    ) internal virtual returns (bytes memory) {
        return bytes("");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/utils/introspection/IERC165.sol";
import "contracts/interfaces/ISimplePlugin.sol";
import "contracts/interfaces/PluginErrorsAndEvents.sol";

/**
 * @title Plugin Executor Interface
 * @author Josh Davis
 * @notice For contracts that will use plugins
 */
interface ISimplePluginExecutor is PluginErrorsAndEvents, IERC165 {
    /**
     * @notice Installs a new plugin
     * @param plugin the plugin to be installed
     * @param pluginInstallData plugin-specific data required to install and configure
     *
     * Requirements:
     * - The plugin MUST NOT already be installed
     * - The plugin MUST NOT provide an execute selector already provided by an installed plugin
     * - Implementation MUST call plugin.onInstall()
     */
    function installSimplePlugin(
        address plugin,
        bytes calldata pluginInstallData
    ) external;

    /**
     * @notice Removes a plugin
     * @param plugin the plugin to be removed
     * @param pluginUninstallData  plugin-specific data required to clean uninstall
     *
     * Requirements:
     * - The plugin MUST be installed
     * - Implementation MUST call plugin.onUninstall()
     */
    function uninstallSimplePlugin(
        address plugin,
        bytes calldata pluginUninstallData
    ) external;

    /**
     * @notice Removes a plugin without reverting if onUninstall() fails
     * @param plugin the plugin to be removed
     * @param pluginUninstallData  plugin-specific data required to clean uninstall
     *
     * Requirements:
     * - The plugin MUST be installed
     * - Implementation MUST call plugin.onUninstall()
     */
    function forceUninstallSimplePlugin(
        address plugin,
        bytes calldata pluginUninstallData
    ) external;

    /**
     * @notice remove the ability of a plugin to implement interfaces and respond to selectors
     * @param plugin the plugin to be removed
     * @param interfaces interface id support to be removed
     * @param selectors function support to be removed
     */
    function removePluginSelectorsAndInterfaces(
        address plugin,
        bytes4[] calldata interfaces,
        bytes4[] calldata selectors
    ) external;

    /**
     *
     * @param oldPlugin the plugin to be removed
     * @param pluginUninstallData plugin-specific data required to clean uninstall
     * @param newPlugin the plugin to be installed
     * @param pluginInstallData plugin-specific data required to install and configure
     * @param force if true, will not revert if oldPlugin.onUninstall() reverts
     *
     * Requirements
     * - removing oldPlugin MUST meet all requirements for `uninstallSimplePlugin`
     * - installing newPlugin MUST meet all requirements for `installSimplePlugin`
     */
    function replaceSimplePlugin(
        address oldPlugin,
        bytes calldata pluginUninstallData,
        address newPlugin,
        bytes calldata pluginInstallData,
        bool force
    ) external;

    /// @notice Execute a call from a plugin through the parent contract.
    /// @dev Permissions must be granted to the calling plugin for the call to go through.
    /// @param data The calldata to send to the parent contract.
    /// @return The return data from the call.
    function executeFromPlugin(
        bytes calldata data
    ) external payable returns (bytes memory);

    /// @notice Execute a call from a plugin to a non-plugin address.
    /// @dev If the target is a plugin, the call SHOULD revert. Permissions MUST be granted to the calling 
    /// plugin for the call to go through.
    /// @param target The address to be called.
    /// @param value The value to send with the call.
    /// @param data The calldata to send to the target.
    /// @return The return data from the call.
    function executeFromPluginExternal(
        address target,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/utils/introspection/IERC165.sol";

/**
 * @title Simple Plugin Interface
 * @author Josh Davis
 * @dev A plugin has three options for intercepting a function call: validation, execution, and post-validation.
 * @dev If a plugin validates a function, then the provided validation code runs before the function executes.
 * @dev If a plugin post-validates a function, then the provided validation code runs after the function executes.
 * @dev If a plugin executes a function, that means the plugin provides the implementation of the fuction.
 * @dev The selectors for the function calls a plugin will intercept are given by `validates()`, `executes()`, 
 *     and `postExecs()`.
 * @dev A Plugin Executor may have many plugins that validate or post validate a given function, but only one 
 *     that executes a function.
 * @dev Plugins may validate or post-validate functions provided by other plugins.
 * @dev If the function to be validated doesn't call  `beforeHook()` or `postExec()`, then the plugin's 
 *     validation will not run. See AbstractPluginExecutor#pluggable modifier.
 * @dev If a function to be executed is already defined by the Plugin Executor, that verion will run and the 
 *     plugin version will be ignored.
 */

struct Message {
    bytes data; // original ABI-encoded function call
    address sender; // original message sender
    bytes4 sig; // function selector
    uint256 value; // amount of eth/matic sent with the transaction, if any
}

interface ISimplePlugin is IERC165 {
    /**
     * @notice called by the plugin executor when the plugin is installed 
     * @param data implementation-specific data required to install and configure
     *      the plugin
     */
    function onInstall(bytes calldata data) external;

    /**
     * @notice called by the plugin executor when the plugin is uninstalled 
     * @param data implementation-specific data required to cleanly remove the plugin
     */
    function onUninstall(bytes calldata data) external;

    /**
     * @notice Returns the list of interface ids provided by this plugin. 
     */
    function providedInterfaces() external view returns (bytes4[] memory);

    /**
     * @notice Returns the selectors of the functions that this plugin will validate. 
     */
    function validates() external view returns (bytes4[] memory); 

    /**
     * @notice Returns the selectors of the functions that this plugin will execute. 
     */
    function executes() external view returns (bytes4[] memory);

    /**
     * @notice Returns the selectors of the functions that this plugin will post validate. 
     */
    function postExecs() external view returns (bytes4[] memory); 

    /**
     * @notice called by the plugin executor to validate a function
     * @param _msg the original message received by the Plugin Executor
     */
    function beforeHook(
        Message calldata _msg
    ) external payable returns (bytes memory);

    /**
     * @notice called by the plugin executor to execute a function
     * @notice execute functions can only add new functions on the Plugin Executor. They
     *     cannot replace existing functions. If the Plugin Executor has a function with the 
     *     same selector, the plugin version will never be called.
     * @param _msg the original message received by the Plugin Executor
     */
    function execute(
        Message calldata _msg
    ) external payable returns (bytes memory);

    /**
     * @notice called by the plugin executor to post-validate a function
     * @param _msg the original message received by the Plugin Executor
     */
    function afterHook(
        Message calldata _msg
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface PluginErrorsAndEvents {
    event SimplePluginInstalled(address indexed plugin);

    event SimplePluginUninstalled(address indexed plugin);

    event ErrorInPluginUninstall(bytes reason);

    // @notice Revert if a function is called by something other than an ISimplePluginExecutor
    error InvalidPluginExecutor(address notExecutor);

    /// @notice Revert if a function called by something other than an installed plugin
    error CallerIsNotPlugin();

    /// @notice Revert if a function is called by an installed plugin
    error IllegalCallByPlugin();

    /// @notice Revert if a call is to an installed plugin
    error IllegalCallToPlugin();

    /// @notice Revert if fallback can't find the function
    error NoSuchMethodError();

    /// @notice Revert when installing a plugin that executes the same selector as an existing one
    error ExecutePluginAlreadySet(bytes4 func, address plugin);

    /// @notice Revert on install if the plugin has already been installed
    error PluginAlreadyInstalled();

    /// @notice Revert on install if there is a problem with a plugin
    error InvalidPlugin(bytes32 reason);

    /// @notice Revert on uninstall 
    error PluginNotInstalled();

    /// @notice Revert if the calldata passed to onInstall/onUninstall is invalid
    error InvalidInitCode(bytes32 reason);

    /// @notice Revert if validation or execution fails due to bad call data
    error InvalidCallData(bytes4 selector);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/interfaces/ISimplePluginExecutor.sol";
import "contracts/common/IOwnerOperator.sol";
import "contracts/token/modular/IModularViciERC20.sol";

interface IModularERC20Ops is IOwnerOperator {
    /* ################################################################
     * Queries
     * ##############################################################*/

    function parent() external view returns (IModularViciERC20);

    /**
     * @dev Returns the total maximum possible that can be minted.
     */
    function getMaxSupply() external view returns (uint256);

    /**
     * @dev Returns the amount that has been minted so far.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev returns the amount available to be minted.
     * @dev {total available} = {max supply} - {amount minted so far}
     */
    function availableSupply() external view returns (uint256);

    /**
     * @dev see IERC20
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /* ################################################################
     * Minting / Burning / Transferring
     * ##############################################################*/

    /**
     * @dev Safely mints a new token and transfers it to the specified address.
     * @dev Updates available quantities
     *
     * Requirements:
     *
     * - `mintData.operator` MUST be owner or have the required role.
     * - `mintData.operator` MUST NOT be banned.
     * - `mintData.toAddress` MUST NOT be 0x0.
     * - `mintData.toAddress` MUST NOT be banned.
     * - If `mintData.toAddress` refers to a smart contract, it must implement
     *      {IERC20Receiver-onERC20Received}, which is called upon a safe
     *      transfer.
     */
    function mint(address operator, address toAddress, uint256 amount) external;

    /**
     * @dev see IERC20
     */
    function transfer(
        address operator,
        address fromAddress,
        address toAddress,
        uint256 amount
    ) external;

    /**
     * @dev Burns the identified token.
     * @dev Updates available quantities
     *
     * Requirements:
     *
     * - `burnData.operator` MUST be owner or have the required role.
     * - `burnData.operator` MUST NOT be banned.
     * - `burnData.operator` MUST own the token or be authorized by the
     *     owner to transfer the token.
     */
    function burn(
        address operator,
        address fromAddress,
        uint256 amount
    ) external;

    /* ################################################################
     * Approvals / Allowances
     * ##############################################################*/

    /**
     * @dev see IERC20
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(address owner, address spender, uint256 amount) external;

    /**
     * @notice recover assets in banned or sanctioned accounts
     *
     * Requirements
     * - `operator` MUST be the contract owner.
     * - `fromAddress` MUST be banned or OFAC sanctioned
     * - `toAddress` MAY be the zero address, in which case the
     *     assets are burned.
     * - `toAddress` MUST NOT be banned or OFAC sanctioned
     */
    function recoverSanctionedAssets(
        address operator,
        address fromAddress,
        address toAddress
    ) external returns (uint256 amount);

    /* ################################################################
     * Utility Coin Functions
     * ##############################################################*/

    /**
     * @notice Transfers tokens from the caller to a recipient and establishes
     * a vesting schedule.
     * If `transferData.toAddress` already has a locked balance, then
     * - if `transferData.amount` is greater than the airdropThreshold AND `release` is later than the current
     *      lockReleaseDate, the lockReleaseDate will be updated.
     * - if `transferData.amount` is less than the airdropThreshold OR `release` is earlier than the current
     *      lockReleaseDate, the lockReleaseDate will be left unchanged.
     * param transferData describes the token transfer
     * @param release the new lock release date, as a Unix timestamp in seconds
     *
     * Requirements:
     * - caller MUST have the AIRDROPPER role
     * - the transaction MUST meet all requirements for a transfer
     * @dev see IERC20Operations.transfer
     */
    function airdropTimelockedTokens(
        address operator,
        address toAddress,
        address fromAddress,
        uint256 amount,
        uint256 release
    ) external;

    /**
     * @notice Unlocks some or all of `account`'s locked tokens.
     * @param account the user
     * @param unlockAmount the amount to unlock
     *
     * Requirements:
     * - caller MUST be the owner or have the UNLOCK_LOCKED_TOKENS role
     * - `unlockAmount` MAY be greater than the locked balance, in which case
     *     all of the account's locked tokens are unlocked.
     */
    function unlockLockedTokens(
        address operator,
        address account,
        uint256 unlockAmount
    ) external;

    /**
     * @notice Resets the lock period for a batch of addresses
     * @notice This function has no effect on accounts without a locked token balance
     * @param release the new lock release date, as a Unix timestamp in seconds
     * @param addresses the list of addresses to be reset
     *
     * Requirements:
     * - caller MUST be the owner or have the UNLOCK_LOCKED_TOKENS role
     * - `release` MAY be zero or in the past, in which case the users' entire locked balances become unlocked
     * - `addresses` MAY contain accounts without a locked balance, in which case the account is unaffected
     */
    function updateTimelocks(
        address operator,
        uint256 release,
        address[] calldata addresses
    ) external;

    /**
     * @notice Returns the amount of locked tokens for `account`.
     * @param account the user address
     */
    function lockedBalanceOf(address account) external view returns (uint256);

    /**
     * @notice Returns the Unix timestamp when a user's locked tokens will be
     * released.
     * @param account the user address
     */
    function lockReleaseDate(address account) external view returns (uint256);

    /**
     * @notice Returns the difference between `account`'s total balance and its
     * locked balance.
     * @param account the user address
     */
    function unlockedBalanceOf(address account) external view returns (uint256);

    /**
     * @notice recovers tokens from lost wallets
     */
    function recoverMisplacedTokens(
        address operator,
        address fromAddress,
        address toAddress
    ) external returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Owner Operator Interface
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 * 
 * @dev public interface for the Owner Operator contract
 */
interface IOwnerOperator {

    /**
     * @dev revert if the item does not exist
     */
    function enforceItemExists(uint256 thing) external view;

    /* ################################################################
     * Queries
     * ##############################################################*/

    /**
     * @dev Returns whether `thing` exists. Things are created by transferring
     *     from the null address, and things are destroyed by tranferring to
     *     the null address.
     * @dev COINS: returns whether any have been minted and are not all burned.
     *
     * @param thing identifies the thing.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1.
     */
    function exists(uint256 thing) external view returns (bool);

    /**
     * @dev Returns the number of distict owners.
     * @dev use with `ownerAtIndex()` to iterate.
     */
    function ownerCount() external view returns (uint256);

    /**
     * @dev Returns the address of the owner at the index.
     * @dev use with `ownerCount()` to iterate.
     *
     * @param index the index into the list of owners
     *
     * Requirements
     * - `index` MUST be less than the number of owners.
     */
    function ownerAtIndex(uint256 index) external view returns (address);

    /**
     * @dev Returns the number of distict items.
     * @dev use with `itemAtIndex()` to iterate.
     * @dev COINS: returns 1 or 0 depending on whether any tokens exist.
     */
    function itemCount() external view returns (uint256);

    /**
     * @dev Returns the ID of the item at the index.
     * @dev use with `itemCount()` to iterate.
     * @dev COINS: don't use this function. The ID is always 1.
     *
     * @param index the index into the list of items
     *
     * Requirements
     * - `index` MUST be less than the number of items.
     */
    function itemAtIndex(uint256 index) external view returns (uint256);

    /**
     * @dev for a given item, returns the number that exist.
     * @dev NFTS: don't use this function. It returns 1 or 0 depending on
     *     whether the item exists. Use `exists()` instead.
     */
    function itemSupply(uint256 thing) external view returns (uint256);

    /**
     * @dev Returns how much of an item is held by an address.
     * @dev NFTS: Returns 0 or 1 depending on whether the address owns the item.
     *
     * @param owner the owner
     * @param thing identifies the item.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `thing` MUST exist.
     */
    function getBalance(address owner, uint256 thing)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the list of distinct items held by an address.
     * @dev COINS: Don't use this function.
     *
     * @param user the user
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     */
    function userWallet(address user) external view returns (uint256[] memory);

    /**
     * @dev For a given address, returns the number of distinct items.
     * @dev Returns 0 if the address doesn't own anything here.
     * @dev use with `itemOfOwnerByIndex()` to iterate.
     * @dev COINS: don't use this function. It returns 1 or 0 depending on
     *     whether the address has a balance. Use `balance()` instead.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `thing` MUST exist.
     */
    function ownerItemCount(address owner) external view returns (uint256);

    /**
     * @dev For a given address, returns the id of the item at the index.
     * @dev COINS: don't use this function.
     *
     * @param owner the owner.
     * @param index the index in the list of items.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `index` MUST be less than the number of items.
     */
    function itemOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @dev For a given item, returns the number of owners.
     * @dev use with `ownerOfItemAtIndex()` to iterate.
     * @dev COINS: don't use this function. Use `ownerCount()` instead.
     * @dev NFTS: don't use this function. If `thing` exists, the answer is 1.
     *
     * Requirements:
     * - `thing` MUST exist.
     */
    function itemOwnerCount(uint256 thing) external view returns (uint256);

    /**
     * @dev For a given item, returns the owner at the index.
     * @dev use with `itemOwnerCount()` to iterate.
     * @dev COINS: don't use this function. Use `ownerAtIndex()` instead.
     * @dev NFTS: Returns the owner.
     *
     * @param thing identifies the item.
     * @param index the index in the list of owners.
     *
     * Requirements:
     * - `thing` MUST exist.
     * - `index` MUST be less than the number of owners.
     * - NFTS: `index` MUST be 0.
     */
    function ownerOfItemAtIndex(uint256 thing, uint256 index)
        external
        view
        returns (address owner);

    /* ################################################################
     * Minting / Burning / Transferring
     * ##############################################################*/

    /**
     * @dev transfers an amount of thing from one address to another.
     * @dev if `fromAddress` is the null address, `amount` of `thing` is
     *     created.
     * @dev if `toAddress` is the null address, `amount` of `thing` is
     *     destroyed.
     *
     * @param operator the operator
     * @param fromAddress the current owner
     * @param toAddress the current owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     * - `fromAddress` and `toAddress` MUST NOT both be the null address
     * - `amount` MUST be greater than 0
     * - if `fromAddress` is not the null address
     *   - `amount` MUST NOT be greater than the current owner's balance
     *   - `operator` MUST be approved
     */
    function doTransfer(
        address operator,
        address fromAddress,
        address toAddress,
        uint256 thing,
        uint256 amount
    ) external;

    /* ################################################################
     * Allowances / Approvals
     * ##############################################################*/

    /**
     * @dev Reverts if `operator` is allowed to transfer `amount` of `thing` on
     *     behalf of `fromAddress`.
     * @dev Reverts if `fromAddress` is not an owner of at least `amount` of
     *     `thing`.
     *
     * @param operator the operator
     * @param fromAddress the owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     */
    function enforceAccess(
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) external view;

    /**
     * @dev Returns whether `operator` is allowed to transfer `amount` of
     *     `thing` on behalf of `fromAddress`.
     *
     * @param operator the operator
     * @param fromAddress the owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     */
    function isApproved(
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) external view returns (bool);

    /**
     * @dev Returns whether an operator is approved for all items belonging to
     *     an owner.
     *
     * @param fromAddress the owner
     * @param operator the operator
     */
    function isApprovedForAll(address fromAddress, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Toggles whether an operator is approved for all items belonging to
     *     an owner.
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param approved the new approval status
     *
     * Requirements:
     * - `fromUser` MUST NOT be the null address
     * - `operator` MUST NOT be the null address
     * - `operator` MUST NOT be the `fromUser`
     */
    function setApprovalForAll(
        address fromAddress,
        address operator,
        bool approved
    ) external;

    /**
     * @dev returns the approved allowance for an operator.
     * @dev NFTS: Don't use this function. Use `getApprovedForItem()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1
     */
    function allowance(
        address fromAddress,
        address operator,
        uint256 thing
    ) external view returns (uint256);

    /**
     * @dev sets the approval amount for an operator.
     * @dev NFTS: Don't use this function. Use `approveForItem()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     * @param amount the allowance amount.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1
     * - `fromUser` MUST NOT be the null address
     * - `operator` MUST NOT be the null address
     * - `operator` MUST NOT be the `fromUser`
     */
    function approve(
        address fromAddress,
        address operator,
        uint256 thing,
        uint256 amount
    ) external;

    /**
     * @dev Returns the address of the operator who is approved for an item.
     * @dev Returns the null address if there is no approved operator.
     * @dev COINS: Don't use this function.
     *
     * @param fromAddress the owner
     * @param thing identifies the item.
     *
     * Requirements:
     * - `thing` MUST exist
     */
    function getApprovedForItem(address fromAddress, uint256 thing)
        external
        view
        returns (address);

    /**
     * @dev Approves `operator` to transfer `thing` to another account.
     * @dev COINS: Don't use this function. Use `setApprovalForAll()` or
     *     `approve()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     *
     * Requirements:
     * - `fromUser` MUST NOT be the null address
     * - `operator` MAY be the null address
     * - `operator` MUST NOT be the `fromUser`
     * - `fromUser` MUST be an owner of `thing`
     */
    function approveForItem(
        address fromAddress,
        address operator,
        uint256 thing
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "contracts/bridging/IBridgeable.sol";
import "contracts/access/IViciAccess.sol";
import "contracts/interfaces/ISimplePluginExecutor.sol";
import "contracts/token/extensions/IERC677.sol";

interface IModularViciERC20 is
    IERC20Metadata,
    IViciAccess,
    ISimplePluginExecutor,
    IBridgeable,
    IERC677
{
    function isMain() external returns (bool);
    function vault() external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/access/AccessConstants.sol";

struct BridgeArgs {
    address caller;
    address fromAddress;
    address toAddress;
    uint256 remoteChainId;
    uint256 itemId;
    uint256 amount;
}

struct SendParams {
    address fromAddress;
    uint256 dstChainId;
    address toAddress;
    uint256 itemId;
    uint256 amount;
}

/**
 * @title Bridgeable Interface
 * @dev common interface for bridgeable tokens
 */
interface IBridgeable {
    event SentToBridge(
        address indexed fromAddress,
        address indexed toAddress,
        uint256 indexed itemId,
        uint256 amount,
        address caller,
        uint256 dstChainId
    );

    event ReceivedFromBridge(
        address indexed fromAddress,
        address indexed toAddress,
        uint256 indexed itemId,
        uint256 amount,
        address caller,
        uint256 srcChainId
    );

    /**
     * @dev Callback function to notify when tokens have been sent through a bridge.
     * @dev Implementations SHOULD either lock or burn these tokens.
     * @param args.caller the original message sender
     * @param args.fromAddress the owner of the tokens that were sent
     * @param args.toAddress the destination address on the other chain
     * @param args.remoteChainId the chain id for the destination
     * @param args.itemId the token id for ERC721 or ERC1155 tokens. Ignored for ERC20 tokens.
     * @param args.amount the amount of tokens sent for ERC20 and ERC1155 tokens. Ignored for ERC721 tokens.
     */
    function sentToBridge(BridgeArgs calldata args) external payable;

    /**
     * @dev Callback function to notify when tokens have been sent through a bridge.
     * @dev Implementations SHOULD either unlock or mint these tokens and send them to the `toAddress`.
     * @dev IMPORTANT: access to this function MUST be tightly controlled. Otherwise it's an infinite free tokens function.
     * @param args.caller the original message sender
     * @param args.fromAddress the owner of the tokens that were sent
     * @param args.toAddress the destination address on this chain
     * @param args.srcChainId the chain id for the source
     * @param args.itemId the token id for ERC721 or ERC1155 tokens. Ignored for ERC20 tokens.
     * @param args.amount the amount of tokens sent for ERC20 and ERC1155 tokens. Ignored for ERC721 tokens.
     */
    function receivedFromBridge(BridgeArgs calldata args) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

bytes32 constant DEFAULT_ADMIN = 0x00;
bytes32 constant BANNED = "banned";
bytes32 constant MODERATOR = "moderator";
bytes32 constant ANY_ROLE = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
bytes32 constant BRIDGE_CONTRACT = keccak256("BRIDGE_CONTRACT");
bytes32 constant BRIDGE_ROLE_MGR = keccak256("BRIDGE_ROLE_MGR");
bytes32 constant CREATOR_ROLE_NAME = "creator";
bytes32 constant CUSTOMER_SERVICE = "Customer Service";
bytes32 constant MINTER_ROLE_NAME = "minter";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/access/extensions/IAccessControlEnumerable.sol";

/**
 * @title ViciAccess Interface
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 *
 * @dev Interface for ViciAccess.
 * @dev External contracts SHOULD refer to implementers via this interface.
 */
interface IViciAccess is IAccessControlEnumerable {
    /**
     * @dev emitted when the owner changes.
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Revert if the address is on the OFAC sanctions list
     */
    function enforceIsNotSanctioned(address account) external view;

    /**
     * @dev reverts if the account is banned or on the OFAC sanctions list.
     */
    function enforceIsNotBanned(address account) external view;

    /**
     * @dev reverts if the account is not the owner and doesn't have the required role.
     */
    function enforceOwnerOrRole(bytes32 role, address account) external view;

    /**
     * @dev returns true if the account is on the OFAC sanctions list.
     */
    function isSanctioned(address account) external view returns (bool);

    /**
     * @dev returns true if the account is banned.
     */
    function isBanned(address account) external view returns (bool);
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/extensions/IAccessControlEnumerable.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "contracts/access/IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title IERC677 interface
 * @notice ERC677 extends ERC20 by adding the transfer and call function.
 */
interface IERC677 is IERC20Metadata {

    /**
     * @notice transfers `value` to `to` and calls `onTokenTransfer()`.
     * @param to the ERC677 Receiver
     * @param value the amount to transfer
     * @param data the abi encoded call data
     * 
     * Requirements:
     * - `to` MUST implement ERC677ReceiverInterface.
     * - `value` MUST be sufficient to cover the receiving contract's fee.
     * - `data` MUST be the types expected by the receiving contract.
     * - caller MUST be a contract that implements the callback function 
     *     required by the receiving contract.
     * - this contract must represent a token that is accepted by the receiving
     *     contract.
     */
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/access/AccessEventsErrors.sol";
import "contracts/impl/BasicSimplePlugin.sol";
import "contracts/token/modular/IModularViciERC20.sol";
import "contracts/token/modular/ViciERC20RolesErrorsEvents.sol";

abstract contract ViciERC20HybridPlugin is BasicSimplePlugin, ViciERC20RolesErrorsEvents {
    
    function enforceOwnerOnly(
        address parent,
        address account
    ) internal view virtual {
        if (account != IModularViciERC20(parent).owner()) {
            revert AccessEventsErrors.OwnableUnauthorizedAccount(account);
        }
    }

    function enforceOwnerOrRole(
        address parent,
        bytes32 role,
        address account
    ) internal view virtual {
        IModularViciERC20(parent).enforceOwnerOrRole(role, account);
    }

    function enforceIsNotBanned(
        address parent,
        address account
    ) internal view virtual {
        IModularViciERC20(parent).enforceIsNotBanned(account);
    }

    function validateExecutor(
        address maybeExecutor
    ) internal view virtual override returns (bool) {
        try
            IModularViciERC20(maybeExecutor).supportsInterface(
                type(IModularViciERC20).interfaceId
            )
        returns (bool ok) {
            return ok;
        } catch {
            revert InvalidPluginExecutor(maybeExecutor);
        }
    }

    function userBalance(
        IERC20 coin,
        address user
    ) internal view virtual returns (uint256) {
        return coin.balanceOf(user);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.24;

interface AccessEventsErrors {
    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);


    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    error BannedAccount(address account);

    error OFACSanctionedAccount(address account);

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    /**
     * @notice Emitted when a new administrator is added.
     */
    event AdminAddition(address indexed admin);

    /**
     * @notice Emitted when an administrator is removed.
     */
    event AdminRemoval(address indexed admin);

    /**
     * @notice Emitted when a resource is registered.
     */
    event ResourceRegistration(address indexed resource);

    /**
     * @notice Emitted when `newAdminRole` is set globally as ``role``'s admin
     * role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {GlobalRoleAdminChanged} not being emitted signaling this.
     */
    event GlobalRoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @notice Emitted when `account` is granted `role` globally.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event GlobalRoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @notice Emitted when `account` is revoked `role` globally.
     * @notice `account` will still have `role` where it was granted
     * specifically for any resources
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event GlobalRoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/interfaces/draft-IERC6093.sol";

bytes32 constant AIRDROP_ROLE_NAME = "airdrop";
bytes32 constant LOST_WALLET = keccak256("lost wallet");
bytes32 constant UNLOCK_LOCKED_TOKENS = keccak256("UNLOCK_LOCKED_TOKENS");

interface ViciERC20RolesErrorsEvents is IERC20Errors {
    /**
     * @notice revert when using lost wallet recovery on a wallet that is not lost.
     */
    error InvalidLostWallet(address wallet);

    /**
     * @notice revert when using sanctioned asset recovery on a wallet that is not sanctioned.
     */
    error InvalidSanctionedWallet(address wallet);

    /**
     * @notice  revert when trying to mint beyond max supply
     */
    error SoldOut();

    /**
     * @notice  emit when assets are recovered from a sanctioned wallet
     */
    event SanctionedAssetsRecovered(address from, address to, uint256 value);

    /**
     * @notice  emit when assets are recovered from a lost wallet
     */
    event LostTokensRecovered(address from, address to, uint256 value);

    /**
     * @notice  emit when a timelock is updated
     */
    event LockUpdated(
        address indexed account,
        uint256 previousRelease,
        uint256 newRelease
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}