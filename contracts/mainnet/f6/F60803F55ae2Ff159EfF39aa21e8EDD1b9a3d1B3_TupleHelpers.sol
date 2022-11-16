// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library CommandBuilder {
    uint256 constant IDX_VARIABLE_LENGTH = 0x80;
    uint256 constant IDX_VALUE_MASK = 0x7f;
    uint256 constant IDX_END_OF_ARGS = 0xff;
    uint256 constant IDX_USE_STATE = 0xfe;
    uint256 constant IDX_ARRAY_START = 0xfd;
    uint256 constant IDX_TUPLE_START = 0xfc;
    uint256 constant IDX_DYNAMIC_END = 0xfb;

    function buildInputs(
        bytes[] memory state,
        bytes4 selector,
        bytes32 indices
    ) internal view returns (bytes memory ret) {
        uint256 idx; // The current command index
        uint256 offsetIdx; // The index of the current free offset

        uint256 count; // Number of bytes in whole ABI encoded message
        uint256 free; // Pointer to first free byte in tail part of message
        uint256[] memory offsets = new uint256[](10); // Optionally store the length of all dynamic types (a command cannot fit more than 10 dynamic types)

        bytes memory stateData; // Optionally encode the current state if the call requires it

        uint256 indicesLength; // Number of indices

        // Determine the length of the encoded data
        for (uint256 i; i < 32; ) {
            idx = uint8(indices[i]);
            if (idx == IDX_END_OF_ARGS) {
                indicesLength = i;
                break;
            }
            if (idx & IDX_VARIABLE_LENGTH != 0) {
                if (idx == IDX_USE_STATE) {
                    if (stateData.length == 0) {
                        stateData = abi.encode(state);
                    }
                    unchecked {
                        count += stateData.length;
                    }
                } else if (idx == IDX_ARRAY_START) {
                    (offsets, offsetIdx, count, i) = setupDynamicArray(state, indices, offsets, offsetIdx, count, i);
                } else if (idx == IDX_TUPLE_START) {
                    (offsets, offsetIdx, count, i) = setupDynamicTuple(state, indices, offsets, offsetIdx, count, i);
                } else {
                    count = setupDynamicVariable(state, count, idx);
                }
            } else {
                count = setupStaticVariable(state, count, idx);
            }
            unchecked {
                free += 32;
                ++i;
            }
        }

        // Encode it
        ret = new bytes(count + 4);
        assembly {
            mstore(add(ret, 32), selector)
        }
        count = 0;
        offsetIdx = 0;
        for (uint256 i; i < indicesLength; ) {
            idx = uint8(indices[i]);
            if (idx & IDX_VARIABLE_LENGTH != 0) {
                if (idx == IDX_USE_STATE) {
                    assembly {
                        mstore(add(add(ret, 36), count), free)
                    }
                    memcpy(stateData, 32, ret, free + 4, stateData.length - 32);
                    unchecked {
                        free += stateData.length - 32;
                        count += 32;
                    }
                } else if (idx == IDX_ARRAY_START) {
                    // Start of dynamic type, put pointer in current slot
                    assembly {
                        mstore(add(add(ret, 36), count), free)
                    }
                    (offsetIdx, free, , i) = encodeDynamicArray(ret, state, indices, offsets, offsetIdx, free, i);
                    unchecked {
                        count += 32;
                    }
                } else if (idx == IDX_TUPLE_START) {
                    // Start of dynamic type, put pointer in current slot
                    assembly {
                        mstore(add(add(ret, 36), count), free)
                    }
                    (offsetIdx, free, , i) = encodeDynamicTuple(ret, state, indices, offsets, offsetIdx, free, i);
                    unchecked {
                        count += 32;
                    }
                } else {
                    // Variable length data
                    uint256 argLen = state[idx & IDX_VALUE_MASK].length;
                    // Put a pointer in the current slot and write the data to first free slot
                    assembly {
                        mstore(add(add(ret, 36), count), free)
                    }
                    memcpy(
                        state[idx & IDX_VALUE_MASK],
                        0,
                        ret,
                        free + 4,
                        argLen
                    );
                    unchecked {
                        free += argLen;
                        count += 32;
                    }
                }
            } else {
                // Fixed length data
                bytes memory stateVar = state[idx & IDX_VALUE_MASK];
                // Write the data to current slot
                assembly {
                    mstore(add(add(ret, 36), count), mload(add(stateVar, 32)))
                }
                unchecked {
                    count += 32;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function setupStaticVariable(
        bytes[] memory state,
        uint256 count,
        uint256 idx
    ) internal pure returns (uint256) {
        require(
            state[idx & IDX_VALUE_MASK].length == 32,
            "Static state variables must be 32 bytes"
        );
        unchecked {
            count += 32;
        }
        return count;
    }

    function setupDynamicVariable(
        bytes[] memory state,
        uint256 count,
        uint256 idx
    ) internal pure returns (uint256) {
        // Add the length of the value, rounded up to the next word boundary, plus space for pointer and length
        uint256 argLen = state[idx & IDX_VALUE_MASK].length;
        require(
            argLen % 32 == 0,
            "Dynamic state variables must be a multiple of 32 bytes"
        );
        unchecked {
            count += argLen + 32;
        }
        return count;
    }

    function setupDynamicArray(
        bytes[] memory state,
        bytes32 indices,
        uint256[] memory offsets,
        uint256 offsetIdx,
        uint256 count,
        uint256 i
    ) internal view returns (uint256[] memory, uint256, uint256, uint256) {
        // Current idx is IDX_ARRAY_START, next idx will contain the array length
        unchecked {
            ++i;
            count += 32;
        }
        uint256 idx = uint8(indices[i]);
        require(
            state[idx & IDX_VALUE_MASK].length == 32,
            "Array length must be 32 bytes"
        );
        return setupDynamicTuple(state, indices, offsets, offsetIdx, count, i);
    }

    function setupDynamicTuple(
        bytes[] memory state,
        bytes32 indices,
        uint256[] memory offsets,
        uint256 offsetIdx,
        uint256 count,
        uint256 i
    ) internal view returns (uint256[] memory, uint256, uint256, uint256) {
        uint256 idx;
        uint256 offset;
        uint256 nextOffsetIdx;
        // Progress to first index of the data and progress the next offset idx
        unchecked {
            ++i;
            nextOffsetIdx = offsetIdx + 1;
            count += 32;
        }
        while (i < 32) {
            idx = uint8(indices[i]);
            if (idx & IDX_VARIABLE_LENGTH != 0) {
                if (idx == IDX_DYNAMIC_END) {
                    offsets[offsetIdx] = offset;
                    // Return
                    return (offsets, nextOffsetIdx, count, i);
                } else if (idx == IDX_ARRAY_START) {
                    (offsets, nextOffsetIdx, count, i) = setupDynamicArray(state, indices, offsets, nextOffsetIdx, count, i);
                } else if (idx == IDX_TUPLE_START) {
                    (offsets, nextOffsetIdx, count, i) = setupDynamicTuple(state, indices, offsets, nextOffsetIdx, count, i);
                } else {
                    count = setupDynamicVariable(state, count, idx);
                }
            } else {
                count = setupStaticVariable(state, count, idx);
            }
            unchecked {
                offset += 32;
                ++i;
            }
        }
        return (offsets, nextOffsetIdx, count, i);
    }

    function encodeDynamicArray(
        bytes memory ret,
        bytes[] memory state,
        bytes32 indices,
        uint256[] memory offsets,
        uint256 offsetIdx,
        uint256 free,
        uint256 i
    ) internal view returns (uint256, uint256, uint256, uint256) {
        // Progress to array length metadata
        unchecked {
            ++i;
        }
        // Encode array length
        uint256 idx = uint8(indices[i]);
        bytes memory stateVar = state[idx & IDX_VALUE_MASK];
        assembly {
            mstore(add(add(ret, 36), free), mload(add(stateVar, 32)))
        }
        unchecked {
            free += 32;
        }
        uint256 length;
        (offsetIdx, free, length, i) = encodeDynamicTuple(ret, state, indices, offsets, offsetIdx, free, i);
        unchecked {
            length += 32; // Increase length to account for array length metadata
        }
        return (offsetIdx, free, length, i);
    }

    function encodeDynamicTuple(
        bytes memory ret,
        bytes[] memory state,
        bytes32 indices,
        uint256[] memory offsets,
        uint256 offsetIdx,
        uint256 free,
        uint256 i
    ) internal view returns (uint256, uint256, uint256, uint256) {
        uint256 idx;
        uint256 length; // The number of bytes in this tuple
        uint256 offset = offsets[offsetIdx]; // The current offset location
        uint256 pointer = offset; // The current pointer for dynamic types
        unchecked {
            offset += free; // Update the offset location
            ++offsetIdx; // Progress to next offsetIdx
            ++i; // Progress to first index of the data
        }
        while (i < 32) {
            idx = uint8(indices[i]);
            if (idx & IDX_VARIABLE_LENGTH != 0) {
                if (idx == IDX_DYNAMIC_END) {
                    return (offsetIdx, offset, length, i);
                } else if (idx == IDX_ARRAY_START) {
                    // Start of dynamic type, put pointer in current slot
                    assembly {
                        mstore(add(add(ret, 36), free), pointer)
                    }
                    uint256 argLen;
                    (offsetIdx, offset, argLen, i) = encodeDynamicArray(ret, state, indices, offsets, offsetIdx, offset, i);
                    unchecked {
                        pointer += argLen;
                        length += (argLen + 32); // data + pointer
                        free += 32;
                    }
                } else if (idx == IDX_TUPLE_START) {
                    // Start of dynamic type, put pointer in current slot
                    assembly {
                        mstore(add(add(ret, 36), free), pointer)
                    }
                    uint256 argLen;
                    (offsetIdx, offset, argLen, i) = encodeDynamicTuple(ret, state, indices, offsets, offsetIdx, offset, i);
                    unchecked {
                        pointer += argLen;
                        length += (argLen + 32); // data + pointer
                        free += 32;
                    }
                } else  {
                    // Variable length data
                    uint256 argLen = state[idx & IDX_VALUE_MASK].length;
                    // Put a pointer in the first free slot and write the data to the offset free slot
                    assembly {
                        mstore(add(add(ret, 36), free), pointer)
                    }
                    memcpy(
                        state[idx & IDX_VALUE_MASK],
                        0,
                        ret,
                        offset + 4,
                        argLen
                    );
                    unchecked {
                        offset += argLen;
                        pointer += argLen;
                        length += (argLen + 32); // data + pointer
                        free += 32;
                    }
                }
            } else {
                // Fixed length data
                bytes memory stateVar = state[idx & IDX_VALUE_MASK];
                // Write to first free slot
                assembly {
                    mstore(add(add(ret, 36), free), mload(add(stateVar, 32)))
                }
                unchecked {
                    length += 32;
                    free += 32;
                }
            }
            unchecked {
                ++i;
            }
        }
        return (offsetIdx, offset, length, i);
    }

    function writeOutputs(
        bytes[] memory state,
        bytes1 index,
        bytes memory output
    ) internal pure returns (bytes[] memory) {
        uint256 idx = uint8(index);
        if (idx == IDX_END_OF_ARGS) return state;

        if (idx & IDX_VARIABLE_LENGTH != 0) {
            if (idx == IDX_USE_STATE) {
                state = abi.decode(output, (bytes[]));
            } else {
                // Check the first field is 0x20 (because we have only a single return value)
                uint256 argPtr;
                assembly {
                    argPtr := mload(add(output, 32))
                }
                require(
                    argPtr == 32,
                    "Only one return value permitted (variable)"
                );

                assembly {
                    // Overwrite the first word of the return data with the length - 32
                    mstore(add(output, 32), sub(mload(output), 32))
                    // Insert a pointer to the return data, starting at the second word, into state
                    mstore(
                        add(add(state, 32), mul(and(idx, IDX_VALUE_MASK), 32)),
                        add(output, 32)
                    )
                }
            }
        } else {
            // Single word
            require(
                output.length == 32,
                "Only one return value permitted (static)"
            );

            state[idx & IDX_VALUE_MASK] = output;
        }

        return state;
    }

    function writeTuple(
        bytes[] memory state,
        bytes1 index,
        bytes memory output
    ) internal view {
        uint256 idx = uint8(index);
        if (idx == IDX_END_OF_ARGS) return;

        bytes memory entry = state[idx] = new bytes(output.length + 32);
        memcpy(output, 0, entry, 32, output.length);
        assembly {
            let l := mload(output)
            mstore(add(entry, 32), l)
        }
    }

    function memcpy(
        bytes memory src,
        uint256 srcIdx,
        bytes memory dest,
        uint256 destIdx,
        uint256 len
    ) internal view {
        assembly {
            pop(
                staticcall(
                    gas(),
                    4,
                    add(add(src, 32), srcIdx),
                    len,
                    add(add(dest, 32), destIdx),
                    len
                )
            )
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./CommandBuilder.sol";

abstract contract VM {
    using CommandBuilder for bytes[];

    uint256 constant FLAG_CT_DELEGATECALL = 0x00;
    uint256 constant FLAG_CT_CALL = 0x01;
    uint256 constant FLAG_CT_STATICCALL = 0x02;
    uint256 constant FLAG_CT_VALUECALL = 0x03;
    uint256 constant FLAG_CT_MASK = 0x03;
    uint256 constant FLAG_DATA = 0x20;
    uint256 constant FLAG_EXTENDED_COMMAND = 0x40;
    uint256 constant FLAG_TUPLE_RETURN = 0x80;

    uint256 constant SHORT_COMMAND_FILL =
        0x000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    error ExecutionFailed(
        uint256 command_index,
        address target,
        string message
    );

    function _execute(bytes32[] calldata commands, bytes[] memory state)
        internal
        returns (bytes[] memory)
    {
        bytes32 command;
        uint256 flags;
        bytes32 indices;

        bool success;
        bytes memory outData;

        uint256 commandsLength = commands.length;
        for (uint256 i; i < commandsLength; i = _uncheckedIncrement(i)) {
            command = commands[i];
            flags = uint256(uint8(bytes1(command << 32)));

            if (flags & FLAG_EXTENDED_COMMAND != 0) {
                i = _uncheckedIncrement(i);
                indices = commands[i];
            } else {
                indices = bytes32(uint256(command << 40) | SHORT_COMMAND_FILL);
            }

            if (flags & FLAG_CT_MASK == FLAG_CT_DELEGATECALL) {
                (success, outData) = address(uint160(uint256(command))) // target
                    .delegatecall(
                        // inputs
                        flags & FLAG_DATA == 0
                            ? state.buildInputs(
                                bytes4(command), // selector
                                indices
                            )
                            : state[
                                uint8(bytes1(indices)) &
                                CommandBuilder.IDX_VALUE_MASK
                            ]
                    );
            } else if (flags & FLAG_CT_MASK == FLAG_CT_CALL) {
                (success, outData) = address(uint160(uint256(command))).call( // target
                    // inputs
                    flags & FLAG_DATA == 0
                        ? state.buildInputs(
                            bytes4(command), // selector
                            indices
                        )
                        : state[
                            uint8(bytes1(indices)) &
                            CommandBuilder.IDX_VALUE_MASK
                        ]
                );
            } else if (flags & FLAG_CT_MASK == FLAG_CT_STATICCALL) {
                (success, outData) = address(uint160(uint256(command))) // target
                    .staticcall(
                        // inputs
                        flags & FLAG_DATA == 0
                            ? state.buildInputs(
                                bytes4(command), // selector
                                indices
                            )
                            : state[
                                uint8(bytes1(indices)) &
                                CommandBuilder.IDX_VALUE_MASK
                            ]
                    );
            } else if (flags & FLAG_CT_MASK == FLAG_CT_VALUECALL) {
                uint256 callEth;
                bytes memory v = state[uint8(bytes1(indices))];
                assembly {
                    callEth := mload(add(v, 0x20))
                }
                (success, outData) = address(uint160(uint256(command))).call{ // target
                    value: callEth
                }(
                    // inputs
                    flags & FLAG_DATA == 0
                        ? state.buildInputs(
                            bytes4(command), // selector
                            indices << 8 // skip value input
                        )
                        : state[
                            uint8(
                                bytes1(indices << 8) // first byte after value input
                            ) & CommandBuilder.IDX_VALUE_MASK
                        ]
                );
            } else {
                revert("Invalid calltype");
            }

            if (!success) {
                if (outData.length > 0) {
                    assembly {
                        outData := add(outData, 68)
                    }
                }
                revert ExecutionFailed({
                    command_index: flags & FLAG_EXTENDED_COMMAND == 0
                        ? i
                        : i - 1,
                    target: address(uint160(uint256(command))),
                    message: outData.length > 0 ? string(outData) : "Unknown"
                });
            }

            if (flags & FLAG_TUPLE_RETURN != 0) {
                state.writeTuple(bytes1(command << 88), outData);
            } else {
                state = state.writeOutputs(bytes1(command << 88), outData);
            }
        }
        return state;
    }

    function _uncheckedIncrement(uint256 i) private pure returns (uint256) {
        unchecked {
            ++i;
        }
        return i;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {VM} from "@ensofinance/weiroll/contracts/VM.sol";

contract EnsoWallet is VM {
    address public caller;
    bool public initialized;

    // Already initialized
    error AlreadyInit();
    // Not caller
    error NotCaller();
    // Invalid address
    error InvalidAddress();

    function initialize(
        address caller_,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) external payable {
        if (initialized) revert AlreadyInit();
        caller = caller_;
        if (commands.length != 0) {
            _execute(commands, state);
        }
    }

    function execute(bytes32[] calldata commands, bytes[] calldata state)
        external
        payable
        returns (bytes[] memory returnData)
    {
        if (msg.sender != caller) revert NotCaller();
        returnData = _execute(commands, state);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./EnsoWallet.sol";
import {Clones} from "./Libraries/Clones.sol";

contract EnsoWalletFactory {
    using Clones for address;

    address public immutable ensoWallet;

    event Deployed(EnsoWallet instance);

    constructor(address EnsoWallet_) {
        ensoWallet = EnsoWallet_;
    }

    function deploy(bytes32[] calldata commands, bytes[] calldata state) public payable returns (EnsoWallet instance) {
        instance = EnsoWallet(payable(ensoWallet.cloneDeterministic(msg.sender)));
        instance.initialize{value: msg.value}(msg.sender, commands, state);

        emit Deployed(instance);
    }

    function getAddress() public view returns (address payable) {
        return payable(ensoWallet.predictDeterministicAddress(msg.sender, address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @dev SignedMathHelpers contract is recommended to use only in Shortcuts passed to EnsoWallet.
 *
 * This contract functions allow to dynamically get the data during Shortcut transaction execution
 * that usually would be read between transactions
 */
contract EnsoShortcutsHelpers {
    uint256 public constant VERSION = 2;

    /**
     * @dev Returns the ether balance of given `balanceAdderess`.
     */
    function getBalance(address balanceAddress) external view returns (uint256 balance) {
        return address(balanceAddress).balance;
    }

    /**
     * @dev Returns the current block timestamp.
     */
    function getBlockTimestamp() external view returns (uint256 timestamp) {
        return block.timestamp;
    }

    /**
     * @dev Returns a value depending on a truth condition
     */
    function toggle(bool condition, uint256 a, uint256 b) external pure returns (uint256) {
        if (condition) {
            return a;
        } else {
            return b;
        }
    }

    /**
     * @dev Returns the inverse bool
     */
    function not(bool condition) external pure returns (bool) {
        return !condition;
    }

    /**
     * @dev Returns bool for a == b
     */
    function isEqual(uint256 a, uint256 b) external pure returns (bool) {
        return a == b;
    }

    /**
     * @dev Returns bool for a < b
     */
    function isLessThan(uint256 a, uint256 b) external pure returns (bool) {
        return a < b;
    }

    /**
     * @dev Returns bool for a <= b
     */
    function isEqualOrLessThan(uint256 a, uint256 b) external pure returns (bool) {
        return a <= b;
    }

    /**
     * @dev Returns bool for a > b
     */
    function isGreaterThan(uint256 a, uint256 b) external pure returns (bool) {
        return a > b;
    }

    /**
     * @dev Returns bool for a >= b
     */
    function isEqualOrGreaterThan(uint256 a, uint256 b) external pure returns (bool) {
        return a >= b;
    }

    /**
     * @dev Returns bool for a == b
     */
    function isAddressEqual(address a, address b) external pure returns (bool) {
        return a == b;
    }

    /**
     * @dev Returns `input` bytes as string.
     */
    function bytesToString(bytes calldata input) external pure returns (string memory) {
        return string(abi.encodePacked(input));
    }

    /**
     * @dev Returns `input` bytes32 as uint256.
     */
    function bytes32ToUint256(bytes32 input) external pure returns (uint256) {
        return uint256(input);
    }

    /**
     * @dev Returns `input` bytes32 as address.
     */
    function bytes32ToAddress(bytes32 input) external pure returns (address) {
        return address(uint160(uint256(input)));
    }

    /**
     * @dev Returns uint256 `value` as int256.
     */
    function uint256ToInt256(uint256 value) public pure returns (int256) {
        require(value <= uint256(type(int256).max), "Value does not fit in an int256");
        return int256(value);
    }

    /**
     * @dev Returns int256 `value` as uint256.
     */
    function int256ToUint256(int256 value) public pure returns (uint256) {
        require(value >= 0, "Value must be positive");
        return uint256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @dev MathHelpers contract is recommended to use only in Shortcuts passed to EnsoWallet
 *
 * Based on OpenZepplin Contracts v4.7.3:
 * - utils/math/Math.sol (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol)
 * - utils/math/SafeMath.sol (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol)
 */
contract MathHelpers {
    uint256 public constant VERSION = 1;

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) external pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) external pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) external pure returns (uint256) {
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) external pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) external pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) external pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) external pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the results a math operation if a condition is met. Otherwise returns the 'a' value without any modification.
     */
    function conditional(bool condition, bytes4 method, uint256 a, uint256 b) external view returns (uint256) {
        if (condition) {
            (bool success, bytes memory n) = address(this).staticcall(abi.encodeWithSelector(method, a, b));
            if (success) return abi.decode(n, (uint256));
        }
        return a;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @dev SignedMathHelpers contract is recommended to use only in Shortcuts passed to EnsoWallet
 *
 * Based on OpenZepplin Contracts 4.7.3:
 * - utils/math/SignedMath.sol (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SignedMath.sol)
 * - utils/math/SignedSafeMath.sol (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SignedSafeMath.sol)
 */
contract SignedMathHelpers {
    uint256 public constant VERSION = 1;

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) external pure returns (int256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * underflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) external pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) external pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) external pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) external pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) external pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) external pure returns (int256) {
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) external pure returns (uint256) {
        unchecked {
            return uint256(n >= 0 ? n : -n);
        }
    }

    /**
     * @dev Returns the results a math operation if a condition is met. Otherwise returns the 'a' value without any modification.
     */
    function conditional(bool condition, bytes4 method, int256 a, int256 b) external view returns (int256) {
        if (condition) {
          (bool success, bytes memory n) = address(this).staticcall(abi.encodeWithSelector(method, a, b));
          if (success) return abi.decode(n, (int256));
        }
        return a;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
  * @notice Helper contract to extract a variety of types from a tuple within the context of a weiroll script
  */
contract TupleHelpers {

    /**
      * @notice Extract a bytes32 encoded static type from a tuple
      * @dev Use with .rawValue() in the weiroll planner
      * @param tuple The bytes encoded tuple
      * @param index The index of the value to be extracted
      */
    function extractElement(bytes memory tuple, uint256 index) public pure returns (bytes32) {
        assembly {
            // let offset := mul(add(index, 1), 32)
            // return(add(tuple, offset), 32)
            return(add(tuple, mul(add(index, 1), 32)), 32)
        }
    }

    /**
      * @notice Extract a bytes encoded dynamic type from a tuple
      * @dev Use with .rawValue() in the weiroll planner
      * @param tuple The bytes encoded tuple
      * @param index The index of the string or bytes to be extracted
      */
    function extractDynamicElement(bytes memory tuple, uint256 index) public pure returns (bytes32) {
        assembly {
            let offset := add(mload(add(tuple, mul(add(index, 1), 32))), 32)
            let length := mload(add(tuple, offset))
            if gt(mod(length, 32), 0) {
              length := mul(add(div(length, 32), 1), 32)
            }
            return(add(tuple, add(offset, 32)), length)
        }
    }

    /**
      * @notice Extract a bytes encoded tuple from another tuple
      * @dev Use with .rawValue() in the weiroll planner
      * @param tuple The bytes encoded parent tuple
      * @param index The index of the tuple to be extracted
      * @param isDynamicTypeFormat Boolean to define whether the child tuple is dynamically sized. If the child tuple contains bytes or string variables, set to "true"
      */
    function extractTuple(
        bytes memory tuple,
        uint256 index,
        bool[] memory isDynamicTypeFormat
    ) public pure returns (bytes32) {
        uint256 offset;
        uint256 length;
        assembly {
            offset := add(mload(add(tuple, mul(add(index, 1), 32))), 32)
        }
        for (uint256 i = 0; i < isDynamicTypeFormat.length; i++) {
            length += 32;
            if (isDynamicTypeFormat[i]) {
                assembly {
                    let paramOffset := add(offset, mload(add(tuple, add(offset, mul(i, 32)))))
                    let paramLength := add(mload(add(tuple, paramOffset)), 32)
                    if gt(mod(paramLength, 32), 0) {
                      paramLength := mul(add(div(paramLength, 32), 1), 32)
                    }
                    length := add(length, paramLength)
                }
            }
        }
        assembly {
            return(add(tuple, add(mload(add(tuple, mul(add(index, 1), 32))), 32)), length)
        }
    }

    /**
      * @notice Extract a bytes encoded static array from a tuple
      * @dev Use with .rawValue() in the weiroll planner
      * @param tuple The bytes encoded array
      * @param index The index of the array to be extracted
      */
    function extractArray(bytes memory tuple, uint256 index) public pure returns (bytes32) {
        assembly {
            // let offset := add(mload(add(tuple, mul(add(index, 1), 32))), 32)
            // let numberOfElements := mload(add(tuple, offset))
            // return(add(tuple, add(offset, 32)), mul(numberOfElements, 32))
            return(add(tuple, add(add(mload(add(tuple, mul(add(index, 1), 32))), 32), 32)), mul(mload(add(tuple, add(mload(add(tuple, mul(add(index, 1), 32))), 32))), 32))
        }
    }

    /**
      * @notice Extract a bytes encoded dynamic array from a tuple
      * @dev Use with .rawValue() in the weiroll planner
      * @param tuple The bytes encoded tuple
      * @param index The index of the dynamic array to be extracted
      */
    function extractDynamicArray(bytes memory tuple, uint256 index) public pure returns (bytes32) {
        uint256 numberOfElements;
        uint256 offset;
        assembly {
            offset := add(mload(add(tuple, mul(add(index, 1), 32))), 32)
            numberOfElements := mload(add(tuple, offset))
            //numberOfElements := mload(add(tuple, add(mload(add(tuple, mul(add(index, 1), 32))), 32)))
        }

        uint256 length;
        for (uint256 i = 1; i <= numberOfElements; i++) {
            assembly {
                let paramOffset := add(offset, mul(add(i, 1), 32))
                let paramLength := mload(add(tuple, paramOffset))
                if gt(mod(paramLength, 32), 0) {
                  paramLength := mul(add(div(paramLength, 32), 1), 32)
                }
                length := add(length, paramLength)
                //length := add(length, mload(add(tuple, add(add(mload(add(tuple, mul(add(index, 1), 32))), 32), mul(add(i, 1), 32)))))
            }
        }
        assembly {
            // return(add(tuple, add(offset, 32)), add(length, 32))
            return(add(tuple, add(add(mload(add(tuple, mul(add(index, 1), 32))), 32), 32)), add(length, 32))
        }
    }

    /**
      * @notice Extract a bytes encoded array of tuples from a tuple
      * @dev Use with .rawValue() in the weiroll planner
      * @param tuple The bytes encoded tuple
      * @param index The index of the tuple array to be extracted
      * @param isDynamicTypeFormat Boolean to define whether the tuples in the array are dynamically sized. If the array tuple contains bytes or string variables, set to "true"
      */
    function extractTupleArray(
        bytes memory tuple,
        uint256 index,
        bool[] memory isDynamicTypeFormat
    ) public pure returns (bytes32) {
        uint256 numberOfElements;
        assembly {
            // let offset := add(mload(add(tuple, mul(add(index, 1), 32))), 32)
            // numberOfElements := mload(add(tuple, offset))
            numberOfElements := mload(add(tuple, add(mload(add(tuple, mul(add(index, 1), 32))), 32)))
        }
        uint256 length = numberOfElements * 32;
        for (uint256 i = 1; i <= numberOfElements; i++) {
            for (uint256 j = 0; j < isDynamicTypeFormat.length; j++) {
                length += 32;
                if (isDynamicTypeFormat[j]) {
                    assembly {
                        // let tupleOffset := add(offset,mload(add(tuple, add(offset, mul(i, 32)))))
                        // let paramOffset := add(tupleOffset, mload(add(tuple, add(tupleOffset, mul(add(j,1), 32)))))
                        // let paramLength := add(mload(add(tuple, paramOffset)),32)
                        // length := add(length, paramLength)
                        length := add(length, add(mload(add(tuple, add(add(add(mload(add(tuple, mul(add(index, 1), 32))), 32),mload(add(tuple, add(add(mload(add(tuple, mul(add(index, 1), 32))), 32), mul(i, 32))))), mload(add(tuple, add(add(add(mload(add(tuple, mul(add(index, 1), 32))), 32),mload(add(tuple, add(add(mload(add(tuple, mul(add(index, 1), 32))), 32), mul(i, 32))))), mul(add(j,1), 32))))))),32))
                    }
                }
            }
        }
        assembly {
            // return(add(tuple, add(offset,32)), length)
            return(add(tuple, add(add(mload(add(tuple, mul(add(index, 1), 32))), 32),32)), length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IVM {
    function execute(bytes32[] calldata commands, bytes[] calldata state) external payable returns (bytes[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)
// Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Clones.sol

pragma solidity ^0.8.16;

library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, address salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        address salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract Destroyer {
    function kill() public returns (bytes[] memory data) {
        selfdestruct(payable(msg.sender));
        return data;
    }
}

contract DestructEnsoWallet {
    address public caller;
    bool public init;

    event DelegateCallReturn(bool success, bytes ret);

    error AlreadyInit();
    error NotCaller();

    function initialize(
        address caller_,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) external payable {
        if (init) revert AlreadyInit();
        caller = caller_;
        init = true;
        if (commands.length != 0) {
            execute(commands, state);
        }
    }

    function execute(bytes32[] calldata commands, bytes[] calldata state) public returns (bytes[] memory data) {
        if (msg.sender != caller) revert NotCaller();
        Destroyer destroyer = new Destroyer();
        (bool success, bytes memory ret) = address(destroyer).delegatecall(
            abi.encodeWithSelector(destroyer.kill.selector, commands, state)
        );
        emit DelegateCallReturn(success, ret);
        return data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract DumbEnsoWallet {
    address public caller;

    event VMData(bytes32[] commands, bytes[] state);
    event SenderData(address sender, uint256 value);

    // Already initialized
    error AlreadyInit();
    // Not caller
    error NotCaller();
    // Invalid address
    error InvalidAddress();

    function initialize(
        address caller_,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) external payable {
        if (caller != address(0)) revert AlreadyInit();
        caller = caller_;
        if (commands.length != 0) {
            execute(commands, state);
        }
    }

    function execute(bytes32[] calldata commands, bytes[] calldata state) public payable returns (bytes[] memory) {
        return _execute(commands, state);
    }

    function _execute(bytes32[] calldata commands, bytes[] memory state) internal returns (bytes[] memory) {
        emit VMData(commands, state);
        emit SenderData(msg.sender, msg.value);
        // TODO: foundry bug?
        //      comparing to address(this) / msg.sender doesn't return the address alone
        //           ie.
        //           val: EnsoWalletFactoryTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84])
        //           val: 0xb42486fb2979f5f97072f2f4af6673782f846963)
        // if (msg.sender != caller) revert NotCaller();
        return state;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Events {
    event LogBytes(bytes message);
    event LogString(string message);
    event LogBytes32(bytes32 message);
    event LogUint(uint256 message);

    function logBytes(bytes calldata message) external {
        emit LogBytes(message);
    }

    function logString(string calldata message) external {
        emit LogString(message);
    }

    function logBytes32(bytes32 message) external {
        emit LogBytes32(message);
    }

    function logUint(uint256 message) external {
        emit LogUint(message);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract PayableEvents {
    event LogBytes(bytes message);
    event LogString(string message);
    event LogBytes32(bytes32 message);
    event LogUint(uint256 message);

    function logBytes(bytes calldata message) external payable {
        emit LogBytes(message);
    }

    function logString(string calldata message) external payable {
        emit LogString(message);
    }

    function logBytes32(bytes32 message) external payable {
        emit LogBytes32(message);
    }

    function logUint(uint256 message) external payable {
        emit LogUint(message);
    }

    function logValue() external payable {
        emit LogUint(msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

struct Example {
    uint256 a;
    string b;
}

contract TupleFactory {
    uint256 exampleInt1 = 0xcafe;
    uint256 exampleInt2 = 0xdead;
    uint256 exampleInt3 = 0xbeef;
    string exampleString = "Hello World!Hello World!Hello World!Hello World!Hello World!"; // 5x "Hello World!"
    Example exampleStruct = Example(exampleInt1, exampleString);

    string[] exampleStringArray;
    uint256[] exampleIntArray;
    Example[] exampleStructArray;
    bytes10 exampleBytes;

    constructor() {
        exampleStringArray.push(exampleString);
        exampleStringArray.push(exampleString);

        exampleIntArray.push(exampleInt1);
        exampleIntArray.push(exampleInt2);
        exampleIntArray.push(exampleInt3);

        exampleStructArray.push(Example(exampleInt1, exampleString));
        exampleStructArray.push(Example(exampleInt2, exampleString));
        exampleStructArray.push(Example(exampleInt3, exampleString));

        assembly {
            sstore(exampleBytes.slot, sload(exampleString.slot))
        }
    }

    function allTypesTuple()
        public
        view
        returns (
            uint256,
            string memory,
            uint256[] memory,
            string[] memory,
            Example memory,
            Example[] memory
        )
    {
        return (exampleInt1, exampleString, exampleIntArray, exampleStringArray, exampleStruct, exampleStructArray);
    }
}