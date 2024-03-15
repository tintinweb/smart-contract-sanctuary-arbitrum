// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {ERC165, IERC165} from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {Pointer, LibPointer} from "rain.solmem/lib/LibPointer.sol";
import {LibStackPointer} from "rain.solmem/lib/LibStackPointer.sol";
import {LibDataContract, DataContractMemoryContainer} from "rain.datacontract/lib/LibDataContract.sol";
import {IERC1820_REGISTRY} from "rain.erc1820/lib/LibIERC1820.sol";
import {LibUint256Array} from "rain.solmem/lib/LibUint256Array.sol";
import {IParserV2} from "rain.interpreter.interface/interface/unstable/IParserV2.sol";

import {
    UnexpectedConstructionMetaHash,
    UnexpectedInterpreterBytecodeHash,
    UnexpectedStoreBytecodeHash,
    UnexpectedParserBytecodeHash,
    UnexpectedPointers
} from "../error/ErrDeploy.sol";
import {
    IExpressionDeployerV3,
    IERC1820_NAME_IEXPRESSION_DEPLOYER_V3
} from "rain.interpreter.interface/interface/IExpressionDeployerV3.sol";
import {IParserV1} from "rain.interpreter.interface/interface/IParserV1.sol";
import {IInterpreterV2} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {IInterpreterStoreV2} from "rain.interpreter.interface/interface/IInterpreterStoreV2.sol";

import {LibIntegrityCheckNP} from "../lib/integrity/LibIntegrityCheckNP.sol";
import {LibInterpreterStateDataContractNP} from "../lib/state/LibInterpreterStateDataContractNP.sol";
import {LibAllStandardOpsNP} from "../lib/op/LibAllStandardOpsNP.sol";
import {LibParse, LibParseMeta} from "../lib/parse/LibParse.sol";
import {RainterpreterNPE2, INTERPRETER_BYTECODE_HASH} from "./RainterpreterNPE2.sol";
import {PARSER_BYTECODE_HASH} from "./RainterpreterParserNPE2.sol";
import {STORE_BYTECODE_HASH} from "./RainterpreterStoreNPE2.sol";

/// @dev The function pointers for the integrity check fns.
bytes constant INTEGRITY_FUNCTION_POINTERS =
    hex"0ca50d230d880f020f0c0f0c0f160f1f0f3a0fe00fe0103c10b610c30f0c0f160f0c0f0c0f160f020f020f020f020f0210cd10f2110c0f0c10cd0f0c0f0c10c30f160f0c0f0c10c310c30f0c0f1611160f160f160f160f160f0c0f160f160f160f160f1611160f0c0f0c0f0c0f160f160f0c0f160f160f0c0f16111611161116111611161116111611161116111611161116111611160f16110c";

/// @dev Hash of the known construction meta.
bytes32 constant CONSTRUCTION_META_HASH = bytes32(0xc37d63d859e8ee0f20308854945274926324ed2871ac1522dc8365befd4c6c5e);

/// All config required to construct a `RainterpreterNPE2`.
/// @param interpreter The `IInterpreterV2` to use for evaluation. MUST match
/// known bytecode.
/// @param store The `IInterpreterStoreV2`. MUST match known bytecode.
/// @param meta Contract meta for tooling.
struct RainterpreterExpressionDeployerNPE2ConstructionConfig {
    address interpreter;
    address store;
    address parser;
    bytes meta;
}

/// @title RainterpreterExpressionDeployerNPE2
contract RainterpreterExpressionDeployerNPE2 is IExpressionDeployerV3, IParserV2, ERC165 {
    using LibPointer for Pointer;
    using LibStackPointer for Pointer;
    using LibUint256Array for uint256[];

    /// The interpreter with known bytecode that this deployer is constructed
    /// for.
    IInterpreterV2 public immutable iInterpreter;
    /// The store with known bytecode that this deployer is constructed for.
    IInterpreterStoreV2 public immutable iStore;
    IParserV1 public immutable iParser;

    constructor(RainterpreterExpressionDeployerNPE2ConstructionConfig memory config) {
        // Set the immutables.
        IInterpreterV2 interpreter = IInterpreterV2(config.interpreter);
        IInterpreterStoreV2 store = IInterpreterStoreV2(config.store);
        IParserV1 parser = IParserV1(config.parser);

        iInterpreter = interpreter;
        iStore = store;
        iParser = parser;

        /// This IS a security check. This prevents someone making an exact
        /// bytecode copy of the interpreter and shipping different meta for
        /// the copy to lie about what each op does in the interpreter.
        bytes32 constructionMetaHash = keccak256(config.meta);
        if (constructionMetaHash != expectedConstructionMetaHash()) {
            revert UnexpectedConstructionMetaHash(expectedConstructionMetaHash(), constructionMetaHash);
        }

        // Guard against an interpreter with unknown bytecode.
        bytes32 interpreterHash;
        assembly ("memory-safe") {
            interpreterHash := extcodehash(interpreter)
        }
        if (interpreterHash != expectedInterpreterBytecodeHash()) {
            revert UnexpectedInterpreterBytecodeHash(expectedInterpreterBytecodeHash(), interpreterHash);
        }

        // Guard against an store with unknown bytecode.
        bytes32 storeHash;
        assembly ("memory-safe") {
            storeHash := extcodehash(store)
        }
        if (storeHash != expectedStoreBytecodeHash()) {
            revert UnexpectedStoreBytecodeHash(expectedStoreBytecodeHash(), storeHash);
        }

        // Guard against a parser with unknown bytecode.
        bytes32 parserHash;
        assembly ("memory-safe") {
            parserHash := extcodehash(parser)
        }
        if (parserHash != expectedParserBytecodeHash()) {
            revert UnexpectedParserBytecodeHash(expectedParserBytecodeHash(), parserHash);
        }

        // Emit the DISPair.
        // The parser is this contract as it implements both
        // `IExpressionDeployerV3` and `IParserV1`.
        emit DISPair(msg.sender, address(interpreter), address(store), address(parser), config.meta);

        // Register the interface for the deployer.
        // We have to check that the 1820 registry has bytecode at the address
        // before we can register the interface. We can't assume that the chain
        // we are deploying to has 1820 deployed.
        if (address(IERC1820_REGISTRY).code.length > 0) {
            IERC1820_REGISTRY.setInterfaceImplementer(
                address(this), IERC1820_REGISTRY.interfaceHash(IERC1820_NAME_IEXPRESSION_DEPLOYER_V3), address(this)
            );
        }
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IExpressionDeployerV3).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /// @inheritdoc IExpressionDeployerV3
    function deployExpression2(bytes memory bytecode, uint256[] memory constants)
        external
        virtual
        returns (IInterpreterV2, IInterpreterStoreV2, address, bytes memory)
    {
        bytes memory io = LibIntegrityCheckNP.integrityCheck2(INTEGRITY_FUNCTION_POINTERS, bytecode, constants);

        emit NewExpression(msg.sender, bytecode, constants);

        (DataContractMemoryContainer container, Pointer pointer) =
            LibDataContract.newContainer(LibInterpreterStateDataContractNP.serializeSizeNP(bytecode, constants));

        // Serialize the state config into bytes that can be deserialized later
        // by the interpreter.
        LibInterpreterStateDataContractNP.unsafeSerializeNP(pointer, bytecode, constants);

        // Deploy the serialized expression onchain.
        address expression = LibDataContract.write(container);

        // Emit and return the address of the deployed expression.
        emit DeployedExpression(msg.sender, iInterpreter, iStore, expression, io);

        return (iInterpreter, iStore, expression, io);
    }

    /// @inheritdoc IParserV2
    function parse2(bytes memory data) external view virtual override returns (bytes memory) {
        (bytes memory bytecode, uint256[] memory constants) = iParser.parse(data);

        uint256 size = LibInterpreterStateDataContractNP.serializeSizeNP(bytecode, constants);
        bytes memory serialized;
        Pointer cursor;
        assembly ("memory-safe") {
            serialized := mload(0x40)
            mstore(0x40, add(serialized, add(0x20, size)))
            mstore(serialized, size)
            cursor := add(serialized, 0x20)
        }
        LibInterpreterStateDataContractNP.unsafeSerializeNP(cursor, bytecode, constants);

        bytes memory io = LibIntegrityCheckNP.integrityCheck2(INTEGRITY_FUNCTION_POINTERS, bytecode, constants);
        // Nothing is done with IO in IParserV2.
        (io);

        return serialized;
    }

    /// Defines all the function pointers to integrity checks. This is the
    /// expression deployer's equivalent of the opcode function pointers and
    /// follows a near identical dispatch process. These are never compiled into
    /// source and are instead indexed into directly by the integrity check. The
    /// indexing into integrity pointers (which has an out of bounds check) is a
    /// proxy for enforcing that all opcode pointers exist at runtime, so the
    /// length of the integrity pointers MUST match the length of opcode function
    /// pointers. This function is `virtual` so that it can be overridden
    /// pairwise with overrides to `functionPointers` on `Rainterpreter`.
    /// @return The list of integrity function pointers.
    function integrityFunctionPointers() external view virtual returns (bytes memory) {
        return LibAllStandardOpsNP.integrityFunctionPointers();
    }

    /// Virtual function to return the expected construction meta hash.
    /// Public so that external tooling can read it, although this should be
    /// considered deprecated. The intended workflow is that tooling uses a real
    /// evm to deploy the full dispair and reads the hashes from errors using a
    /// trail/error approach until a full dispair is deployed.
    function expectedConstructionMetaHash() public pure virtual returns (bytes32) {
        return CONSTRUCTION_META_HASH;
    }

    /// Virtual function to return the expected interpreter bytecode hash.
    function expectedInterpreterBytecodeHash() internal pure virtual returns (bytes32) {
        return INTERPRETER_BYTECODE_HASH;
    }

    /// Virtual function to return the expected store bytecode hash.
    function expectedStoreBytecodeHash() internal pure virtual returns (bytes32) {
        return STORE_BYTECODE_HASH;
    }

    /// Virtual function to return the expected parser bytecode hash.
    function expectedParserBytecodeHash() internal pure virtual returns (bytes32) {
        return PARSER_BYTECODE_HASH;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// A pointer to a location in memory. This is a `uint256` to save gas on low
/// level operations on the evm stack. These same low level operations typically
/// WILL NOT check for overflow or underflow, so all pointer logic MUST ensure
/// that reads, writes and movements are not out of bounds.
type Pointer is uint256;

/// @title LibPointer
/// Ergonomic wrappers around common pointer movements, reading and writing. As
/// wrappers on such low level operations often introduce too much jump gas
/// overhead, these functions MAY find themselves used in reference
/// implementations that more optimised code can be fuzzed against. MAY also be
/// situationally useful on cooler performance paths.
library LibPointer {
    /// Cast a `Pointer` to `bytes` without modification or any safety checks.
    /// The caller MUST ensure the pointer is to a valid region of memory for
    /// some `bytes`.
    /// @param pointer The pointer to cast to `bytes`.
    /// @return data The cast `bytes`.
    function unsafeAsBytes(Pointer pointer) internal pure returns (bytes memory data) {
        assembly ("memory-safe") {
            data := pointer
        }
    }

    /// Increase some pointer by a number of bytes.
    ///
    /// This is UNSAFE because it can silently overflow or point beyond some
    /// data structure. The caller MUST ensure that this is a safe operation.
    ///
    /// Note that moving a pointer by some bytes offset is likely to unalign it
    /// with the 32 byte increments of the Solidity allocator.
    ///
    /// @param pointer The pointer to increase by `length`.
    /// @param length The number of bytes to increase the pointer by.
    /// @return The increased pointer.
    function unsafeAddBytes(Pointer pointer, uint256 length) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            pointer := add(pointer, length)
        }
        return pointer;
    }

    /// Increase some pointer by a single 32 byte word.
    ///
    /// This is UNSAFE because it can silently overflow or point beyond some
    /// data structure. The caller MUST ensure that this is a safe operation.
    ///
    /// If the original pointer is aligned to the Solidity allocator it will be
    /// aligned after the movement.
    ///
    /// @param pointer The pointer to increase by a single word.
    /// @return The increased pointer.
    function unsafeAddWord(Pointer pointer) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            pointer := add(pointer, 0x20)
        }
        return pointer;
    }

    /// Increase some pointer by multiple 32 byte words.
    ///
    /// This is UNSAFE because it can silently overflow or point beyond some
    /// data structure. The caller MUST ensure that this is a safe operation.
    ///
    /// If the original pointer is aligned to the Solidity allocator it will be
    /// aligned after the movement.
    ///
    /// @param pointer The pointer to increase.
    /// @param words The number of words to increase the pointer by.
    /// @return The increased pointer.
    function unsafeAddWords(Pointer pointer, uint256 words) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            pointer := add(pointer, mul(0x20, words))
        }
        return pointer;
    }

    /// Decrease some pointer by a single 32 byte word.
    ///
    /// This is UNSAFE because it can silently underflow or point below some
    /// data structure. The caller MUST ensure that this is a safe operation.
    ///
    /// If the original pointer is aligned to the Solidity allocator it will be
    /// aligned after the movement.
    ///
    /// @param pointer The pointer to decrease by a single word.
    /// @return The decreased pointer.
    function unsafeSubWord(Pointer pointer) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            pointer := sub(pointer, 0x20)
        }
        return pointer;
    }

    /// Decrease some pointer by multiple 32 byte words.
    ///
    /// This is UNSAFE because it can silently underflow or point below some
    /// data structure. The caller MUST ensure that this is a safe operation.
    ///
    /// If the original pointer is aligned to the Solidity allocator it will be
    /// aligned after the movement.
    ///
    /// @param pointer The pointer to decrease.
    /// @param words The number of words to decrease the pointer by.
    /// @return The decreased pointer.
    function unsafeSubWords(Pointer pointer, uint256 words) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            pointer := sub(pointer, mul(0x20, words))
        }
        return pointer;
    }

    /// Read the word at the pointer.
    ///
    /// This is UNSAFE because it can read outside any particular data stucture
    /// or even beyond allocated memory. The caller MUST ensure that this is a
    /// safe operation.
    ///
    /// @param pointer Pointer to read the word at.
    /// @return word The word read from the pointer.
    function unsafeReadWord(Pointer pointer) internal pure returns (uint256 word) {
        assembly ("memory-safe") {
            word := mload(pointer)
        }
    }

    /// Write a word at the pointer.
    ///
    /// This is UNSAFE because it can write outside any particular data stucture
    /// or even beyond allocated memory. The caller MUST ensure that this is a
    /// safe operation.
    ///
    /// @param pointer Pointer to write the word at.
    /// @param word The word to write.
    function unsafeWriteWord(Pointer pointer, uint256 word) internal pure {
        assembly ("memory-safe") {
            mstore(pointer, word)
        }
    }

    /// Get the pointer to the end of all allocated memory.
    /// As per Solidity docs, there is no guarantee that the region of memory
    /// beyond this pointer is zeroed out, as assembly MAY write beyond allocated
    /// memory for temporary use if the scratch space is insufficient.
    /// @return pointer The pointer to the end of all allocated memory.
    function allocatedMemoryPointer() internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := mload(0x40)
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./LibUint256Array.sol";
import "./LibMemory.sol";
import "./LibMemCpy.sol";

/// Throws if a stack pointer is not aligned to 32 bytes.
error UnalignedStackPointer(Pointer pointer);

/// @title LibStackPointer
/// @notice A stack `Pointer` is still just a pointer to some memory, but we are
/// going to treat it like it is pointing to a stack data structure. That means
/// it can move "up" and "down" (increment and decrement) by `uint256` (32 bytes)
/// increments. Structurally a stack is a `uint256[]` but we can save a lot of
/// gas vs. default Solidity handling of array indexes by using assembly to
/// bypass runtime bounds checks on every read and write. Of course, this means
/// the caller is responsible for ensuring the stack reads and write are not out
/// of bounds.
///
/// The pointer to the bottom of a stack points at the 0th item, NOT the length
/// of the implied `uint256[]` and the top of a stack points AFTER the last item.
/// e.g. consider a `uint256[]` in memory with values `3 A B C` and assume this
/// starts at position `0` in memory, i.e. `0` points to value `3` for the
/// array length. In this case the stack bottom would be `Pointer.wrap(0x20)`
/// (32 bytes above 0, past the length) and the stack top would be
/// `StackPointer.wrap(0x80)` (96 bytes above the stack bottom).
///
/// Most of the functions in this library are equivalent to each other via
/// composition, i.e. everything could be achieved with just `up`, `down`,
/// `pop`, `push`, `peek`. The reason there is so much overloaded/duplicated
/// logic is that the Solidity compiler seems to fail at inlining equivalent
/// logic quite a lot. Perhaps once the IR compilation of Solidity is better
/// supported by tooling etc. we could remove a lot of this duplication as the
/// compiler itself would handle the optimisations.
library LibStackPointer {
    using LibStackPointer for Pointer;
    using LibStackPointer for uint256[];
    using LibStackPointer for bytes;
    using LibUint256Array for uint256[];
    using LibMemory for uint256;

    /// Read the word immediately below the given stack pointer.
    ///
    /// Treats the given pointer as a pointer to the top of the stack, so `peek`
    /// reads the word below the pointer.
    ///
    /// https://en.wikipedia.org/wiki/Peek_(data_type_operation)
    ///
    /// The caller MUST ensure this read is not out of bounds, e.g. a `peek` to
    /// `0` will underflow (and exhaust gas attempting to read).
    ///
    /// @param pointer Pointer to the top of the stack to read below.
    /// @return word The word that was read.
    function unsafePeek(Pointer pointer) internal pure returns (uint256 word) {
        assembly ("memory-safe") {
            word := mload(sub(pointer, 0x20))
        }
    }

    /// Peeks 2 words from the top of the stack.
    ///
    /// Same as `unsafePeek` but returns 2 words instead of 1.
    ///
    /// @param pointer The stack top to peek below.
    /// @return lower The lower of the two words read.
    /// @return upper The upper of the two words read.
    function unsafePeek2(Pointer pointer) internal pure returns (uint256 lower, uint256 upper) {
        assembly ("memory-safe") {
            lower := mload(sub(pointer, 0x40))
            upper := mload(sub(pointer, 0x20))
        }
    }

    /// Pops the word from the top of the stack.
    ///
    /// Treats the given pointer as a pointer to the top of the stack, so `pop`
    /// reads the word below the pointer. The popped pointer is returned
    /// alongside the read word.
    ///
    /// https://en.wikipedia.org/wiki/Stack_(abstract_data_type)
    ///
    /// The caller MUST ensure the pop will not result in an out of bounds read.
    ///
    /// @param pointer Pointer to the top of the stack to read below.
    /// @return pointerAfter Pointer after the pop.
    /// @return word The word that was read.
    function unsafePop(Pointer pointer) internal pure returns (Pointer pointerAfter, uint256 word) {
        assembly ("memory-safe") {
            pointerAfter := sub(pointer, 0x20)
            word := mload(pointerAfter)
        }
    }

    /// Pushes a word to the top of the stack.
    ///
    /// Treats the given pointer as a pointer to the top of the stack, so `push`
    /// writes a word at the pointer. The pushed pointer is returned.
    ///
    /// https://en.wikipedia.org/wiki/Stack_(abstract_data_type)
    ///
    /// The caller MUST ensure the push will not result in an out of bounds
    /// write.
    ///
    /// @param pointer The stack pointer to write at.
    /// @param word The value to write.
    /// @return The stack pointer above where `word` was written to.
    function unsafePush(Pointer pointer, uint256 word) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            mstore(pointer, word)
            pointer := add(pointer, 0x20)
        }
        return pointer;
    }

    /// Returns `length` values from the stack as an array without allocating
    /// new memory. As arrays always start with their length, this requires
    /// writing the length value to the stack below the array values. The value
    /// that is overwritten in the process is also returned so that data is not
    /// lost. For example, imagine a stack `[ A B C D ]` and we list 2 values.
    /// This will write the stack to look like `[ A 2 C D ]` and return both `B`
    /// and a pointer to `2` represented as a `uint256[]`.
    /// The returned array is ONLY valid for as long as the stack DOES NOT move
    /// back into its memory. As soon as the stack moves up again and writes into
    /// the array it will be corrupt. The caller MUST ensure that it does not
    /// read from the returned array after it has been corrupted by subsequent
    /// stack writes.
    /// @param pointer The stack pointer to read the values below into an
    /// array.
    /// @param length The number of values to include in the returned array.
    /// @return head The value that was overwritten with the length.
    /// @return tail The array constructed from the stack memory.
    function unsafeList(Pointer pointer, uint256 length) internal pure returns (uint256 head, uint256[] memory tail) {
        assembly ("memory-safe") {
            tail := sub(pointer, add(0x20, mul(length, 0x20)))
            head := mload(tail)
            mstore(tail, length)
        }
    }

    /// Convert two stack pointer values to a single stack index. A stack index
    /// is the distance in 32 byte increments between two stack pointers. The
    /// calculations require the two stack pointers are aligned. If the pointers
    /// are not aligned, the function will revert.
    ///
    /// @param lower The lower of the two values.
    /// @param upper The higher of the two values.
    /// @return The stack index as 32 byte words distance between the top and
    /// bottom. Negative if `lower` is above `upper`.
    function toIndexSigned(Pointer lower, Pointer upper) internal pure returns (int256) {
        unchecked {
            if (Pointer.unwrap(lower) % 0x20 != 0) {
                revert UnalignedStackPointer(lower);
            }
            if (Pointer.unwrap(upper) % 0x20 != 0) {
                revert UnalignedStackPointer(upper);
            }
            // Dividing by 0x20 before casting to a signed int avoids the case
            // where the difference between the two pointers is greater than
            // `type(int256).max` and would overflow the signed int.
            return int256(Pointer.unwrap(upper) / 0x20) - int256(Pointer.unwrap(lower) / 0x20);
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "rain.solmem/lib/LibPointer.sol";

/// Thrown if writing the data by creating the contract fails somehow.
error WriteError();

/// Thrown if reading a zero length address.
error ReadError();

/// @dev SSTORE2 Verbatim reference
/// https://github.com/0xsequence/sstore2/blob/master/contracts/utils/Bytecode.sol#L15
///
/// 0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
/// 0x01    0x80         0x80        DUP1                size size
/// 0x02    0x60         0x600e      PUSH1 14            14 size size
/// 0x03    0x60         0x6000      PUSH1 00            0 14 size size
/// 0x04    0x39         0x39        CODECOPY            size
/// 0x05    0x60         0x6000      PUSH1 00            0 size
/// 0x06    0xf3         0xf3        RETURN
/// <CODE>
///
/// However note that 00 is also prepended (although docs say append) so there's
/// an additional byte that isn't described above.
/// https://github.com/0xsequence/sstore2/blob/master/contracts/SSTORE2.sol#L25
///
/// Note also typo 0x63XXXXXX which indicates 3 bytes but instead 4 are used as
/// 0x64XXXXXXXX.
///
/// Note also that we don't need 4 bytes to represent the size of a contract as
/// 24kb is the max PUSH2 (0x61) can be used instead of PUSH4 for code length.
/// This also changes the 0x600e to 0x600c as we've reduced prefix size by 2
/// relative to reference implementation.
/// https://github.com/0xsequence/sstore2/pull/5/files
uint256 constant BASE_PREFIX = 0x61_0000_80_600C_6000_39_6000_F3_00_00000000000000000000000000000000000000;

/// @dev Length of the prefix that converts in memory data to a deployable
/// contract.
uint256 constant PREFIX_BYTES_LENGTH = 13;

/// A container is a region of memory that is directly deployable with `create`,
/// without length prefixes or other Solidity type trappings. Where the length is
/// needed, such as in `write` it can be read as bytes `[1,2]` from the prefix.
/// This is just a pointer but given a new type to help avoid mistakes.
type DataContractMemoryContainer is uint256;

/// @title DataContract
///
/// DataContract is a simplified reimplementation of
/// https://github.com/0xsequence/sstore2
///
/// - Doesn't force additonal internal allocations with ABI encoding calls
/// - Optimised for the case where the data to read/write and contract are 1:1
/// - Assembly optimisations for less gas usage
/// - Not shipped with other unrelated code to reduce dependency bloat
/// - Fuzzed with foundry
///
/// It is a little more low level in that it doesn't work on `bytes` from
/// Solidity but instead requires the caller to copy memory directy by pointer.
/// https://github.com/rainprotocol/sol.lib.bytes can help with that.
library LibDataContract {
    /// Prepares a container ready to write exactly `length_` bytes at the
    /// returned `pointer_`. The caller MUST write exactly the number of bytes
    /// that it asks for at the pointer otherwise memory WILL be corrupted.
    /// @param length_ Caller specifies the number of bytes to allocate for the
    /// data it wants to write. The actual size of the container in memory will
    /// be larger than this due to the contract creation prefix and the padding
    /// potentially required to align the memory allocation.
    /// @return container_ The pointer to the start of the container that can be
    /// deployed as an onchain contract. Caller can pass this back to `write` to
    /// have the data contract deployed
    /// (after it copies its data to the pointer).
    /// @return pointer_ The caller can copy its data at the pointer without any
    /// additional allocations or Solidity type wrangling.
    function newContainer(uint256 length_)
        internal
        pure
        returns (DataContractMemoryContainer container_, Pointer pointer_)
    {
        unchecked {
            uint256 prefixBytesLength_ = PREFIX_BYTES_LENGTH;
            uint256 basePrefix_ = BASE_PREFIX;
            assembly ("memory-safe") {
                // allocate output byte array - this could also be done without assembly
                // by using container_ = new bytes(size)
                container_ := mload(0x40)
                // new "memory end" including padding
                mstore(0x40, add(container_, and(add(add(length_, prefixBytesLength_), 0x1f), not(0x1f))))
                // pointer is where the caller will write data to
                pointer_ := add(container_, prefixBytesLength_)

                // copy length into the 2 bytes gap in the base prefix
                let prefix_ :=
                    or(
                        basePrefix_,
                        shl(
                            // length sits 29 bytes from the right
                            232,
                            and(
                                // mask the length to 2 bytes
                                0xFFFF,
                                add(length_, 1)
                            )
                        )
                    )
                mstore(container_, prefix_)
            }
        }
    }

    /// Given a container prepared by `newContainer` and populated with bytes by
    /// the caller, deploy to a new onchain contract and return the contract
    /// address.
    /// @param container_ The container full of data to deploy as an onchain data
    /// contract.
    /// @return The newly deployed contract containing the data in the container.
    function write(DataContractMemoryContainer container_) internal returns (address) {
        address pointer_;
        uint256 prefixLength_ = PREFIX_BYTES_LENGTH;
        assembly ("memory-safe") {
            pointer_ :=
                create(
                    0,
                    container_,
                    add(
                        prefixLength_,
                        // Read length out of prefix.
                        and(0xFFFF, shr(232, mload(container_)))
                    )
                )
        }
        // Zero address means create failed.
        if (pointer_ == address(0)) revert WriteError();
        return pointer_;
    }

    /// Reads data back from a previously deployed container.
    /// Almost verbatim Solidity docs.
    /// https://docs.soliditylang.org/en/v0.8.17/assembly.html#example
    /// Notable difference is that we skip the first byte when we read as it is
    /// a `0x00` prefix injected by containers on deploy.
    /// @param pointer_ The address of the data contract to read from. MUST have
    /// a leading byte that can be safely ignored.
    /// @return data_ The data read from the data contract. First byte is skipped
    /// and contract is read completely to the end.
    function read(address pointer_) internal view returns (bytes memory data_) {
        uint256 size_;
        assembly ("memory-safe") {
            // Retrieve the size of the code, this needs assembly.
            size_ := extcodesize(pointer_)
        }
        if (size_ == 0) revert ReadError();
        assembly ("memory-safe") {
            // Skip the first byte.
            size_ := sub(size_, 1)
            // Allocate output byte array - this could also be done without
            // assembly by using data_ = new bytes(size)
            data_ := mload(0x40)
            // New "memory end" including padding.
            // Compiler will optimise away the double constant addition.
            mstore(0x40, add(data_, and(add(add(size_, 0x20), 0x1f), not(0x1f))))
            // Store length in memory.
            mstore(data_, size_)
            // actually retrieve the code, this needs assembly
            // skip the first byte
            extcodecopy(pointer_, add(data_, 0x20), 1, size_)
        }
    }

    /// Hybrid of address-only read, SSTORE2 read and Solidity docs.
    /// Unlike SSTORE2, reading past the end of the data contract WILL REVERT.
    /// @param pointer_ As per `read`.
    /// @param start_ Starting offset for reads from the data contract.
    /// @param length_ Number of bytes to read.
    function readSlice(address pointer_, uint16 start_, uint16 length_) internal view returns (bytes memory data_) {
        uint256 size_;
        // uint256 offset and end avoids overflow issues from uint16.
        uint256 offset_;
        uint256 end_;
        assembly ("memory-safe") {
            // Skip the first byte.
            offset_ := add(start_, 1)
            end_ := add(offset_, length_)
            // Retrieve the size of the code, this needs assembly.
            size_ := extcodesize(pointer_)
        }
        if (size_ < end_) revert ReadError();
        assembly ("memory-safe") {
            // Allocate output byte array - this could also be done without
            // assembly by using data_ = new bytes(size)
            data_ := mload(0x40)
            // New "memory end" including padding.
            // Compiler will optimise away the double constant addition.
            mstore(0x40, add(data_, and(add(add(length_, 0x20), 0x1f), not(0x1f))))
            // Store length in memory.
            mstore(data_, length_)
            // actually retrieve the code, this needs assembly
            extcodecopy(pointer_, add(data_, 0x20), offset_, length_)
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "../interface/IERC1820Registry.sol";

/// @dev https://eips.ethereum.org/EIPS/eip-1820#single-use-registry-deployment-account
IERC1820Registry constant IERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Pointer} from "./LibPointer.sol";
import {LibMemCpy} from "./LibMemCpy.sol";
import {OutOfBoundsTruncate} from "../error/ErrUint256Array.sol";

/// @title Uint256Array
/// @notice Things we want to do carefully and efficiently with uint256 arrays
/// that Solidity doesn't give us native tools for.
library LibUint256Array {
    using LibUint256Array for uint256[];

    /// Pointer to the start (length prefix) of a `uint256[]`.
    /// @param array The array to get the start pointer of.
    /// @return pointer The pointer to the start of `array`.
    function startPointer(uint256[] memory array) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := array
        }
    }

    /// Pointer to the data of a `uint256[]` NOT the length prefix.
    /// @param array The array to get the data pointer of.
    /// @return pointer The pointer to the data of `array`.
    function dataPointer(uint256[] memory array) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(array, 0x20)
        }
    }

    /// Pointer to the end of the allocated memory of an array.
    /// @param array The array to get the end pointer of.
    /// @return pointer The pointer to the end of `array`.
    function endPointer(uint256[] memory array) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(array, add(0x20, mul(0x20, mload(array))))
        }
    }

    /// Cast a `Pointer` to `uint256[]` without modification or safety checks.
    /// The caller MUST ensure the pointer is to a valid region of memory for
    /// some `uint256[]`.
    /// @param pointer The pointer to cast to `uint256[]`.
    /// @return array The cast `uint256[]`.
    function unsafeAsUint256Array(Pointer pointer) internal pure returns (uint256[] memory array) {
        assembly ("memory-safe") {
            array := pointer
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a A single integer to build an array around.
    /// @return array The newly allocated array including `a` as a single item.
    function arrayFrom(uint256 a) internal pure returns (uint256[] memory array) {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 1)
            mstore(add(array, 0x20), a)
            mstore(0x40, add(array, 0x40))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first integer to build an array around.
    /// @param b The second integer to build an array around.
    /// @return array The newly allocated array including `a` and `b` as the only
    /// items.
    function arrayFrom(uint256 a, uint256 b) internal pure returns (uint256[] memory array) {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 2)
            mstore(add(array, 0x20), a)
            mstore(add(array, 0x40), b)
            mstore(0x40, add(array, 0x60))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first integer to build an array around.
    /// @param b The second integer to build an array around.
    /// @param c The third integer to build an array around.
    /// @return array The newly allocated array including `a`, `b` and `c` as the
    /// only items.
    function arrayFrom(uint256 a, uint256 b, uint256 c) internal pure returns (uint256[] memory array) {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 3)
            mstore(add(array, 0x20), a)
            mstore(add(array, 0x40), b)
            mstore(add(array, 0x60), c)
            mstore(0x40, add(array, 0x80))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first integer to build an array around.
    /// @param b The second integer to build an array around.
    /// @param c The third integer to build an array around.
    /// @param d The fourth integer to build an array around.
    /// @return array The newly allocated array including `a`, `b`, `c` and `d` as the
    /// only items.
    function arrayFrom(uint256 a, uint256 b, uint256 c, uint256 d) internal pure returns (uint256[] memory array) {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 4)
            mstore(add(array, 0x20), a)
            mstore(add(array, 0x40), b)
            mstore(add(array, 0x60), c)
            mstore(add(array, 0x80), d)
            mstore(0x40, add(array, 0xA0))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first integer to build an array around.
    /// @param b The second integer to build an array around.
    /// @param c The third integer to build an array around.
    /// @param d The fourth integer to build an array around.
    /// @param e The fifth integer to build an array around.
    /// @return array The newly allocated array including `a`, `b`, `c`, `d` and
    /// `e` as the only items.
    function arrayFrom(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e)
        internal
        pure
        returns (uint256[] memory array)
    {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 5)
            mstore(add(array, 0x20), a)
            mstore(add(array, 0x40), b)
            mstore(add(array, 0x60), c)
            mstore(add(array, 0x80), d)
            mstore(add(array, 0xA0), e)
            mstore(0x40, add(array, 0xC0))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first integer to build an array around.
    /// @param b The second integer to build an array around.
    /// @param c The third integer to build an array around.
    /// @param d The fourth integer to build an array around.
    /// @param e The fifth integer to build an array around.
    /// @param f The sixth integer to build an array around.
    /// @return array The newly allocated array including `a`, `b`, `c`, `d`, `e`
    /// and `f` as the only items.
    function arrayFrom(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e, uint256 f)
        internal
        pure
        returns (uint256[] memory array)
    {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 6)
            mstore(add(array, 0x20), a)
            mstore(add(array, 0x40), b)
            mstore(add(array, 0x60), c)
            mstore(add(array, 0x80), d)
            mstore(add(array, 0xA0), e)
            mstore(add(array, 0xC0), f)
            mstore(0x40, add(array, 0xE0))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The head of the new array.
    /// @param tail The tail of the new array.
    /// @return array The new array.
    function arrayFrom(uint256 a, uint256[] memory tail) internal pure returns (uint256[] memory array) {
        assembly ("memory-safe") {
            let length := add(mload(tail), 1)
            let outputCursor := mload(0x40)
            array := outputCursor
            let outputEnd := add(outputCursor, add(0x20, mul(length, 0x20)))
            mstore(0x40, outputEnd)

            mstore(outputCursor, length)
            mstore(add(outputCursor, 0x20), a)

            for {
                outputCursor := add(outputCursor, 0x40)
                let inputCursor := add(tail, 0x20)
            } lt(outputCursor, outputEnd) {
                outputCursor := add(outputCursor, 0x20)
                inputCursor := add(inputCursor, 0x20)
            } { mstore(outputCursor, mload(inputCursor)) }
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first item of the new array.
    /// @param b The second item of the new array.
    /// @param tail The tail of the new array.
    /// @return array The new array.
    function arrayFrom(uint256 a, uint256 b, uint256[] memory tail) internal pure returns (uint256[] memory array) {
        assembly ("memory-safe") {
            let length := add(mload(tail), 2)
            let outputCursor := mload(0x40)
            array := outputCursor
            let outputEnd := add(outputCursor, add(0x20, mul(length, 0x20)))
            mstore(0x40, outputEnd)

            mstore(outputCursor, length)
            mstore(add(outputCursor, 0x20), a)
            mstore(add(outputCursor, 0x40), b)

            for {
                outputCursor := add(outputCursor, 0x60)
                let inputCursor := add(tail, 0x20)
            } lt(outputCursor, outputEnd) {
                outputCursor := add(outputCursor, 0x20)
                inputCursor := add(inputCursor, 0x20)
            } { mstore(outputCursor, mload(inputCursor)) }
        }
    }

    /// Solidity provides no way to change the length of in-memory arrays but
    /// it also does not deallocate memory ever. It is always safe to shrink an
    /// array that has already been allocated, with the caveat that the
    /// truncated items will effectively become inaccessible regions of memory.
    /// That is to say, we deliberately "leak" the truncated items, but that is
    /// no worse than Solidity's native behaviour of leaking everything always.
    /// The array is MUTATED in place so there is no return value and there is
    /// no new allocation or copying of data either.
    /// @param array The array to truncate.
    /// @param newLength The new length of the array after truncation.
    function truncate(uint256[] memory array, uint256 newLength) internal pure {
        if (newLength > array.length) {
            revert OutOfBoundsTruncate(array.length, newLength);
        }
        assembly ("memory-safe") {
            mstore(array, newLength)
        }
    }

    /// Extends `base_` with `extend_` by allocating only an additional
    /// `extend_.length` words onto `base_` and copying only `extend_` if
    /// possible. If `base_` is large this MAY be significantly more efficient
    /// than allocating `base_.length + extend_.length` for an entirely new array
    /// and copying both `base_` and `extend_` into the new array one item at a
    /// time in Solidity.
    ///
    /// The efficient version of extension is only possible if the free memory
    /// pointer sits at the end of the base array at the moment of extension. If
    /// there is allocated memory after the end of base then extension will
    /// require copying both the base and extend arays to a new region of memory.
    /// The caller is responsible for optimising code paths to avoid additional
    /// allocations.
    ///
    /// This function is UNSAFE because the base array IS MUTATED DIRECTLY by
    /// some code paths AND THE FINAL RETURN ARRAY MAY POINT TO THE SAME REGION
    /// OF MEMORY. It is NOT POSSIBLE to reliably see this behaviour from the
    /// caller in all cases as the Solidity compiler optimisations may switch the
    /// caller between the allocating and non-allocating logic due to subtle
    /// optimisation reasons. To use this function safely THE CALLER MUST NOT USE
    /// THE BASE ARRAY AND MUST USE THE RETURNED ARRAY ONLY. It is safe to use
    /// the extend array after calling this function as it is never mutated, it
    /// is only copied from.
    ///
    /// @param b The base integer array that will be extended by `e`.
    /// @param e The extend integer array that extends `b`.
    /// @return extended The extended array of `b` extended by `e`.
    function unsafeExtend(uint256[] memory b, uint256[] memory e) internal pure returns (uint256[] memory extended) {
        assembly ("memory-safe") {
            // Slither doesn't recognise assembly function names as mixed case
            // even if they are.
            // https://github.com/crytic/slither/issues/1815
            //slither-disable-next-line naming-convention
            function extendInline(base, extend) -> baseAfter {
                let outputCursor := mload(0x40)
                let baseLength := mload(base)
                let baseEnd := add(base, add(0x20, mul(baseLength, 0x20)))

                // If base is NOT the last thing in allocated memory, allocate,
                // copy and recurse.
                switch eq(outputCursor, baseEnd)
                case 0 {
                    let newBase := outputCursor
                    let newBaseEnd := add(newBase, sub(baseEnd, base))
                    mstore(0x40, newBaseEnd)
                    for { let inputCursor := base } lt(outputCursor, newBaseEnd) {
                        inputCursor := add(inputCursor, 0x20)
                        outputCursor := add(outputCursor, 0x20)
                    } { mstore(outputCursor, mload(inputCursor)) }

                    baseAfter := extendInline(newBase, extend)
                }
                case 1 {
                    let totalLength_ := add(baseLength, mload(extend))
                    let outputEnd_ := add(base, add(0x20, mul(totalLength_, 0x20)))
                    mstore(base, totalLength_)
                    mstore(0x40, outputEnd_)
                    for { let inputCursor := add(extend, 0x20) } lt(outputCursor, outputEnd_) {
                        inputCursor := add(inputCursor, 0x20)
                        outputCursor := add(outputCursor, 0x20)
                    } { mstore(outputCursor, mload(inputCursor)) }

                    baseAfter := base
                }
            }

            extended := extendInline(b, e)
        }
    }

    /// Reverse an array in place. This is a destructive operation that MUTATES
    /// the array in place. There is no return value.
    /// @param array The array to reverse.
    function reverse(uint256[] memory array) internal pure {
        assembly ("memory-safe") {
            for {
                let left := add(array, 0x20)
                // Right points at the last item in the array. Which is the
                // length number of items from the length.
                let right := add(array, mul(mload(array), 0x20))
            } lt(left, right) {
                left := add(left, 0x20)
                right := sub(right, 0x20)
            } {
                let leftValue := mload(left)
                mstore(left, mload(right))
                mstore(right, leftValue)
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

interface IParserV2 {
    function parse2(bytes calldata data) external view returns (bytes calldata bytecode);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

/// @dev Workaround for https://github.com/foundry-rs/foundry/issues/6572
contract ErrDeploy {}

/// @dev Thrown when the pointers known to the expression deployer DO NOT match
/// the interpreter it is constructed for. This WILL cause undefined expression
/// behaviour so MUST REVERT.
/// @param actualPointers The actual function pointers found at the interpreter
/// address upon construction.
error UnexpectedPointers(bytes actualPointers);

/// Thrown when the `RainterpreterExpressionDeployerNPE2` is constructed with
/// unknown interpreter bytecode.
/// @param expectedBytecodeHash The bytecode hash that was expected at the
/// interpreter address upon construction.
/// @param actualBytecodeHash The bytecode hash that was found at the interpreter
/// address upon construction.
error UnexpectedInterpreterBytecodeHash(bytes32 expectedBytecodeHash, bytes32 actualBytecodeHash);

/// Thrown when the `RainterpreterNPE2` is constructed with unknown store bytecode.
/// @param expectedBytecodeHash The bytecode hash that was expected at the store
/// address upon construction.
/// @param actualBytecodeHash The bytecode hash that was found at the store
/// address upon construction.
error UnexpectedStoreBytecodeHash(bytes32 expectedBytecodeHash, bytes32 actualBytecodeHash);

/// Thrown when the `RainterpreterNPE2` is constructed with unknown parser
/// bytecode.
/// @param expectedBytecodeHash The bytecode hash that was expected at the parser
/// address upon construction.
/// @param actualBytecodeHash The bytecode hash that was found at the parser
/// address upon construction.
error UnexpectedParserBytecodeHash(bytes32 expectedBytecodeHash, bytes32 actualBytecodeHash);

/// Thrown when the `RainterpreterNPE2` is constructed with unknown meta.
/// @param expectedConstructionMetaHash The meta hash that was expected upon
/// construction.
/// @param actualConstructionMetaHash The meta hash that was found upon
/// construction.
error UnexpectedConstructionMetaHash(bytes32 expectedConstructionMetaHash, bytes32 actualConstructionMetaHash);

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {IInterpreterStoreV2} from "./IInterpreterStoreV2.sol";
import {IInterpreterV2} from "./IInterpreterV2.sol";

string constant IERC1820_NAME_IEXPRESSION_DEPLOYER_V3 = "IExpressionDeployerV3";

/// @title IExpressionDeployerV3
/// @notice Companion to `IInterpreterV2` responsible for onchain static code
/// analysis and deploying expressions. Each `IExpressionDeployerV3` is tightly
/// coupled at the bytecode level to some interpreter that it knows how to
/// analyse and deploy expressions for. The expression deployer can perform an
/// integrity check "dry run" of candidate source code for the intepreter. The
/// critical analysis/transformation includes:
///
/// - Enforcement of no out of bounds memory reads/writes
/// - Calculation of memory required to eval the stack with a single allocation
/// - Replacing index based opcodes with absolute interpreter function pointers
/// - Enforcement that all opcodes and operands used exist and are valid
///
/// This analysis is highly sensitive to the specific implementation and position
/// of all opcodes and function pointers as compiled into the interpreter. This
/// is what makes the coupling between an interpreter and expression deployer
/// so tight. Ideally all responsibilities would be handled by a single contract
/// but this introduces code size issues quickly by roughly doubling the compiled
/// logic of each opcode (half for the integrity check and half for evaluation).
///
/// Interpreters MUST assume that expression deployers are malicious and fail
/// gracefully if the integrity check is corrupt/bypassed and/or function
/// pointers are incorrect, etc. i.e. the interpreter MUST always return a stack
/// from `eval` in a read only way or error. I.e. it is the expression deployer's
/// responsibility to do everything it can to prevent undefined behaviour in the
/// interpreter, and the interpreter's responsibility to handle the expression
/// deployer completely failing to do so.
interface IExpressionDeployerV3 {
    /// The config of the deployed expression including uncompiled sources. MUST
    /// be emitted after the config passes the integrity check.
    /// @param sender The caller of `deployExpression2`.
    /// @param bytecode As per `IExpressionDeployerV3.deployExpression2` inputs.
    /// @param constants As per `IExpressionDeployerV3.deployExpression2` inputs.
    event NewExpression(address sender, bytes bytecode, uint256[] constants);

    /// The address of the deployed expression. MUST be emitted once the
    /// expression can be loaded and deserialized into an evaluable interpreter
    /// state.
    /// @param sender The caller of `deployExpression2`.
    /// @param interpreter As per `IExpressionDeployerV3.deployExpression2` return.
    /// @param store As per `IExpressionDeployerV3.deployExpression2` return.
    /// @param expression As per `IExpressionDeployerV3.deployExpression2` return.
    /// @param io As per `IExpressionDeployerV3.deployExpression2` return.
    event DeployedExpression(
        address sender, IInterpreterV2 interpreter, IInterpreterStoreV2 store, address expression, bytes io
    );

    /// This is the literal InterpreterOpMeta bytes to be used offchain to make
    /// sense of the opcodes in this interpreter deployment, as a human. For
    /// formats like json that make heavy use of boilerplate, repetition and
    /// whitespace, some kind of compression is recommended.
    /// The DISPair is a pairing of:
    /// - Deployer (this contract)
    /// - Interpreter
    /// - Store
    /// - Parser
    ///
    /// @param sender The `msg.sender` providing the op meta.
    /// @param interpreter The interpreter the deployer believes it is qualified
    /// to perform integrity checks on behalf of.
    /// @param store The interpreter store the deployer believes is compatible
    /// with the interpreter.
    /// @param parser The parser the deployer believes is compatible with the
    /// interpreter.
    /// @param meta The raw binary data of the construction meta. Maybe
    /// compressed data etc. and is intended for offchain consumption.
    event DISPair(address sender, address interpreter, address store, address parser, bytes meta);

    /// Expressions are expected to be deployed onchain as immutable contract
    /// code with a first class address like any other contract or account.
    /// Technically this is optional in the sense that all the tools required to
    /// eval some expression and define all its opcodes are available as
    /// libraries.
    ///
    /// In practise there are enough advantages to deploying the sources directly
    /// onchain as contract data and loading them from the interpreter at eval:
    ///
    /// - Loading and storing binary data is gas efficient as immutable contract
    ///   data
    /// - Expressions need to be immutable between their deploy time integrity
    ///   check and runtime evaluation
    /// - Passing the address of an expression through calldata to an interpreter
    ///   is cheaper than passing an entire expression through calldata
    /// - Conceptually a very simple approach, even if implementations like
    ///   SSTORE2 are subtle under the hood
    ///
    /// The expression deployer MUST perform an integrity check of the source
    /// code before it puts the expression onchain at a known address. The
    /// integrity check MUST at a minimum (it is free to do additional static
    /// analysis) calculate the memory required to be allocated for the stack in
    /// total, and that no out of bounds memory reads/writes occur within this
    /// stack. A simple example of an invalid source would be one that pushes one
    /// value to the stack then attempts to pops two values, clearly we cannot
    /// remove more values than we added. The `IExpressionDeployerV3` MUST revert
    /// in the case of any integrity failure, all integrity checks MUST pass in
    /// order for the deployment to complete.
    ///
    /// Once the integrity check is complete the `IExpressionDeployerV3` MUST do
    /// any additional processing required by its paired interpreter.
    /// For example, the `IExpressionDeployerV3` MAY NEED to replace the indexed
    /// opcodes in the `ExpressionConfig` sources with real function pointers
    /// from the corresponding interpreter.
    ///
    /// The caller MUST check the `io` returned by this function to determine
    /// the number of inputs and outputs for each source are within the bounds
    /// of the caller's expectations.
    ///
    /// @param bytecode Bytecode verbatim. Exactly how the bytecode is structured
    /// is up to the deployer and interpreter. The deployer MUST NOT modify the
    /// bytecode in any way. The interpreter MUST NOT assume anything about the
    /// bytecode other than that it is valid according to the interpreter's
    /// integrity checks. It is assumed that the bytecode will be produced from
    /// a human friendly string via. `IParserV1.parse` but this is not required
    /// if the caller has some other means to prooduce valid bytecode.
    /// @param constants Constants verbatim. Constants are provided alongside
    /// sources rather than inline as it allows us to avoid variable length
    /// opcodes and can be more memory efficient if the same constant is
    /// referenced several times from the sources.
    /// @return interpreter The interpreter the deployer believes it is qualified
    /// to perform integrity checks on behalf of.
    /// @return store The interpreter store the deployer believes is compatible
    /// with the interpreter.
    /// @return expression The address of the deployed onchain expression. MUST
    /// be valid according to all integrity checks the deployer is aware of.
    /// @return io Binary data where each 2 bytes input and output counts for
    /// each source of the bytecode. MAY simply be copied verbatim from the
    /// relevant bytes in the bytecode if they exist and integrity checks
    /// guarantee that the bytecode is valid.
    function deployExpression2(bytes calldata bytecode, uint256[] calldata constants)
        external
        returns (IInterpreterV2 interpreter, IInterpreterStoreV2 store, address expression, bytes calldata io);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

struct AuthoringMeta {
    // `word` is referenced directly in assembly so don't move the field.
    bytes32 word;
    uint8 operandParserOffset;
    string description;
}

/// Identical to AuthoringMeta but without operandParserOffset.
struct AuthoringMetaV2 {
    // `word` is referenced directly in assembly so don't move the field. It MUST
    // be the first item.
    bytes32 word;
    string description;
}

interface IParserV1 {
    /// Parses a Rainlang string into an evaluable expression. MUST be
    /// deterministic and MUST NOT have side effects. The only inputs are the
    /// Rainlang string and the parse meta. MAY revert if the Rainlang string
    /// is invalid. This function takes `bytes` instead of `string` to allow
    /// for definitions of "string" other than UTF-8.
    /// @param data The Rainlang bytes to parse.
    /// @return bytecode The expressions that can be evaluated.
    /// @return constants The constants that can be referenced by sources.
    function parse(bytes calldata data) external pure returns (bytes calldata bytecode, uint256[] calldata constants);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {EncodedDispatch, StateNamespace, Operand, DEFAULT_STATE_NAMESPACE} from "./deprecated/IInterpreterV1.sol";
import {FullyQualifiedNamespace, IInterpreterStoreV2} from "./IInterpreterStoreV2.sol";

/// @dev For maximum compatibility with external contracts, the `IInterpreterV2`
/// should implement an opcode that reads from the stack by index as opcode `0`.
uint256 constant OPCODE_STACK = 0;

/// @dev For maximum compatibility with external contracts, the `IInterpreterV2`
/// should implement an opcode that reads constants by index as opcode `1`.
uint256 constant OPCODE_CONSTANT = 1;

/// @dev For maximum compatibility with external contracts, the `IInterpreterV2`
/// should implement an opcode that calls externs by index as opcode `2`.
uint256 constant OPCODE_EXTERN = 2;

/// @dev For maximum compatibility with external contracts, the `IInterpreterV2`
/// should implement an opcode that reads from the context grid as <column row>
/// as opcode `3`.
uint256 constant OPCODE_CONTEXT = 3;

/// @dev For maximum compatibility with opcode lists, the `IInterpreterV2`
/// should implement the opcode for locally unknown words that need sub parsing
/// as opcode `255`.
uint256 constant OPCODE_UNKNOWN = 0xFF;

/// @dev The index of a source within a deployed expression that can be evaluated
/// by an `IInterpreterV2`. MAY be an entrypoint or the index of a source called
/// internally such as by the `call` opcode.
type SourceIndexV2 is uint256;

/// @title IInterpreterV2
/// Interface into a standard interpreter that supports:
///
/// - evaluating `view` logic deployed onchain by an `IExpressionDeployerV1`
/// - receiving arbitrary `uint256[][]` supporting context to be made available
///   to the evaluated logic
/// - handling subsequent state changes in bulk in response to evaluated logic
/// - namespacing state changes according to the caller's preferences to avoid
///   unwanted key collisions
/// - exposing its internal function pointers to support external precompilation
///   of logic for more gas efficient runtime evaluation by the interpreter
///
/// The interface is designed to be stable across many versions and
/// implementations of an interpreter, balancing minimalism with features
/// required for a general purpose onchain interpreted compute environment.
///
/// The security model of an interpreter is that it MUST be resilient to
/// malicious expressions even if they dispatch arbitrary internal function
/// pointers during an eval. The interpreter MAY return garbage or exhibit
/// undefined behaviour or error during an eval, _provided that no state changes
/// are persisted_ e.g. in storage, such that only the caller that specifies the
/// malicious expression can be negatively impacted by the result. In turn, the
/// caller must guard itself against arbitrarily corrupt/malicious reverts and
/// return values from any interpreter that it requests an expression from. And
/// so on and so forth up to the externally owned account (EOA) who signs the
/// transaction and agrees to a specific combination of contracts, expressions
/// and interpreters, who can presumably make an informed decision about which
/// ones to trust to get the job done.
///
/// The state changes for an interpreter are expected to be produced by an
/// `eval2` and passed to the `IInterpreterStoreV1` returned by the eval, as-is
/// by the caller, after the caller has had an opportunity to apply their own
/// intermediate logic such as reentrancy defenses against malicious
/// interpreters. The interpreter is free to structure the state changes however
/// it wants but MUST guard against the calling contract corrupting the changes
/// between `eval2` and `set`. For example a store could sandbox storage writes
/// per-caller so that a malicious caller can only damage their own state
/// changes, while honest callers respect, benefit from and are protected by the
/// interpreter store's state change handling.
///
/// The two step eval-state model allows evaluation to be read-only which
/// provides security guarantees for the caller such as no stateful reentrancy,
/// either from the interpreter or some contract interface used by some word,
/// while still allowing for storage writes. As the storage writes happen on the
/// interpreter rather than the caller (c.f. delegate call) the caller DOES NOT
/// need to trust the interpreter, which allows for permissionless selection of
/// interpreters by end users. Delegate call always implies an admin key on the
/// caller because the delegatee contract can write arbitrarily to the state of
/// the delegator, which severely limits the generality of contract composition.
interface IInterpreterV2 {
    /// Exposes the function pointers as `uint16` values packed into a single
    /// `bytes` in the same order as they would be indexed into by opcodes. For
    /// example, if opcode `2` should dispatch function at position `0x1234` then
    /// the start of the returned bytes would be `0xXXXXXXXX1234` where `X` is
    /// a placeholder for the function pointers of opcodes `0` and `1`.
    ///
    /// `IExpressionDeployerV3` contracts use these function pointers to
    /// "compile" the expression into something that an interpreter can dispatch
    /// directly without paying gas to lookup the same at runtime. As the
    /// validity of any integrity check and subsequent dispatch is highly
    /// sensitive to both the function pointers and overall bytecode of the
    /// interpreter, `IExpressionDeployerV3` contracts SHOULD implement guards
    /// against accidentally being deployed onchain paired against an unknown
    /// interpreter. It is very easy for an apparent compatible pairing to be
    /// subtly and critically incompatible due to addition/removal/reordering of
    /// opcodes and compiler optimisations on the interpreter bytecode.
    ///
    /// This MAY return different values during construction vs. all other times
    /// after the interpreter has been successfully deployed onchain. DO NOT rely
    /// on function pointers reported during contract construction.
    function functionPointers() external view returns (bytes calldata);

    /// The raison d'etre for an interpreter. Given some expression and per-call
    /// additional contextual data, produce a stack of results and a set of state
    /// changes that the caller MAY OPTIONALLY pass back to be persisted by a
    /// call to `IInterpreterStoreV1.set`.
    ///
    /// There are two key differences between `eval` and `eval2`:
    /// - `eval` was ambiguous about whether the top value of the final stack is
    /// the first or last item of the array. `eval2` is unambiguous in that the
    /// top of the stack MUST be the first item in the array.
    /// - `eval2` allows the caller to specify inputs to the entrypoint stack of
    /// the expression. This allows the `eval` and `offchainDebugEval` functions
    /// to be merged into a single function that can be used for both onchain and
    /// offchain evaluation. For example, the caller can simulate "internal"
    /// calls by specifying the inputs to the entrypoint stack of the expression
    /// as the outputs of some other expression. Legacy behaviour can be achieved
    /// by passing an empty array for `inputs`.
    ///
    /// @param store The storage contract that the returned key/value pairs
    /// MUST be passed to IF the calling contract is in a non-static calling
    /// context. Static calling contexts MUST pass `address(0)`.
    /// @param namespace The fully qualified namespace that will be used by the
    /// interpreter at runtime in order to perform gets on the underlying store.
    /// @param dispatch All the information required for the interpreter to load
    /// an expression, select an entrypoint and return the values expected by the
    /// caller. The interpreter MAY encode dispatches differently to
    /// `LibEncodedDispatch` but this WILL negatively impact compatibility for
    /// calling contracts that hardcode the encoding logic.
    /// @param context A 2-dimensional array of data that can be indexed into at
    /// runtime by the interpreter. The calling contract is responsible for
    /// ensuring the authenticity and completeness of context data. The
    /// interpreter MUST revert at runtime if an expression attempts to index
    /// into some context value that is not provided by the caller. This implies
    /// that context reads cannot be checked for out of bounds reads at deploy
    /// time, as the runtime context MAY be provided in a different shape to what
    /// the expression is expecting.
    /// @param inputs The inputs to the entrypoint stack of the expression. MAY
    /// be empty if the caller prefers to specify all inputs via. context.
    /// @return stack The list of values produced by evaluating the expression.
    /// MUST NOT be longer than the maximum length specified by `dispatch`, if
    /// applicable. MUST be ordered such that the top of the stack is the FIRST
    /// item in the array.
    /// @return writes A list of values to be processed by a store. Most likely
    /// will be pairwise key/value items but this is not strictly required if
    /// some store expects some other format.
    function eval2(
        IInterpreterStoreV2 store,
        FullyQualifiedNamespace namespace,
        EncodedDispatch dispatch,
        uint256[][] calldata context,
        uint256[] calldata inputs
    ) external view returns (uint256[] calldata stack, uint256[] calldata writes);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {StateNamespace, FullyQualifiedNamespace, NO_STORE} from "./deprecated/IInterpreterStoreV1.sol";

/// @title IInterpreterStoreV2
/// @notice Tracks state changes on behalf of an interpreter. A single store can
/// handle state changes for many calling contracts, many interpreters and many
/// expressions. The store is responsible for ensuring that applying these state
/// changes is safe from key collisions with calls to `set` from different
/// `msg.sender` callers. I.e. it MUST NOT be possible for a caller to modify the
/// state changes associated with some other caller.
///
/// The store defines the shape of its own state changes, which is opaque to the
/// calling contract. For example, some store may treat the list of state changes
/// as a pairwise key/value set, and some other store may treat it as a literal
/// list to be stored as-is.
///
/// Each interpreter decides for itself which store to use based on the
/// compatibility of its own opcodes.
///
/// The store MUST assume the state changes have been corrupted by the calling
/// contract due to bugs or malicious intent, and enforce state isolation between
/// callers despite arbitrarily invalid state changes. The store MUST revert if
/// it can detect invalid state changes, such as a key/value list having an odd
/// number of items, but this MAY NOT be possible if the corruption is
/// undetectable.
interface IInterpreterStoreV2 {
    /// MUST be emitted by the store on `set` to its internal storage.
    /// @param namespace The fully qualified namespace that the store is setting.
    /// @param key The key that the store is setting.
    /// @param value The value that the store is setting.
    event Set(FullyQualifiedNamespace namespace, uint256 key, uint256 value);

    /// Mutates the interpreter store in bulk. The bulk values are provided in
    /// the form of a `uint256[]` which can be treated e.g. as pairwise keys and
    /// values to be stored in a Solidity mapping. The `IInterpreterStoreV2`
    /// defines the meaning of the `uint256[]` for its own storage logic.
    ///
    /// @param namespace The unqualified namespace for the set that MUST be
    /// fully qualified by the `IInterpreterStoreV2` to prevent key collisions
    /// between callers. The fully qualified namespace forms a compound key with
    /// the keys for each value to set.
    /// @param kvs The list of changes to apply to the store's internal state.
    function set(StateNamespace namespace, uint256[] calldata kvs) external;

    /// Given a fully qualified namespace and key, return the associated value.
    /// Ostensibly the interpreter can use this to implement opcodes that read
    /// previously set values. The interpreter MUST apply the same qualification
    /// logic as the store that it uses to guarantee consistent round tripping of
    /// data and prevent malicious behaviours. Technically also allows onchain
    /// reads of any set value from any contract, not just interpreters, but in
    /// this case readers MUST be aware and handle inconsistencies between get
    /// and set while the state changes are still in memory in the calling
    /// context and haven't yet been persisted to the store.
    ///
    /// `IInterpreterStoreV2` uses the same fallback behaviour for unset keys as
    /// Solidity. Specifically, any UNSET VALUES SILENTLY FALLBACK TO `0`.
    /// @param namespace The fully qualified namespace to get a single value for.
    /// @param key The key to get the value for within the namespace.
    /// @return The value OR ZERO IF NOT SET.
    function get(FullyQualifiedNamespace namespace, uint256 key) external view returns (uint256);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {Pointer} from "rain.solmem/lib/LibPointer.sol";

import {
    StackAllocationMismatch,
    StackOutputsMismatch,
    StackUnderflow,
    StackUnderflowHighwater,
    BadOpInputsLength,
    BadOpOutputsLength
} from "../../error/ErrIntegrity.sol";
import {IInterpreterV2, SourceIndexV2} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {LibBytecode} from "rain.interpreter.interface/lib/bytecode/LibBytecode.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {IInterpreterStoreV2, StateNamespace} from "rain.interpreter.interface/interface/IInterpreterStoreV2.sol";
import {BadOpInputsLength} from "../../lib/integrity/LibIntegrityCheckNP.sol";

struct IntegrityCheckStateNP {
    uint256 stackIndex;
    uint256 stackMaxIndex;
    uint256 readHighwater;
    uint256[] constants;
    uint256 opIndex;
    bytes bytecode;
}

library LibIntegrityCheckNP {
    using LibIntegrityCheckNP for IntegrityCheckStateNP;

    function newState(bytes memory bytecode, uint256 stackIndex, uint256[] memory constants)
        internal
        pure
        returns (IntegrityCheckStateNP memory)
    {
        return IntegrityCheckStateNP(
            // stackIndex
            stackIndex,
            // stackMaxIndex
            stackIndex,
            // highwater (source inputs are always immutable)
            stackIndex,
            // constants
            constants,
            // opIndex
            0,
            // bytecode
            bytecode
        );
    }

    function integrityCheck2(bytes memory fPointers, bytes memory bytecode, uint256[] memory constants)
        internal
        view
        returns (bytes memory io)
    {
        unchecked {
            uint256 sourceCount = LibBytecode.sourceCount(bytecode);

            uint256 fPointersStart;
            assembly ("memory-safe") {
                fPointersStart := add(fPointers, 0x20)
            }

            // Ensure that the bytecode has no out of bounds pointers BEFORE we
            // start attempting to iterate over opcodes. This ensures the
            // integrity of the source count, relative offset pointers,
            // ops count per source, and that there is no garbage bytes at the
            // end or between these things. Basically everything structural about
            // the bytecode is confirmed here.
            LibBytecode.checkNoOOBPointers(bytecode);

            io = new bytes(sourceCount * 2);
            uint256 ioCursor;
            assembly ("memory-safe") {
                ioCursor := add(io, 0x20)
            }

            // Run the integrity check over each source. This needs to ensure
            // the integrity of each source's inputs, outputs, and stack
            // allocation, as well as the integrity of the bytecode itself on
            // a per-opcode basis, according to each opcode's implementation.
            for (uint256 i = 0; i < sourceCount; i++) {
                (uint256 inputsLength, uint256 outputsLength) = LibBytecode.sourceInputsOutputsLength(bytecode, i);
                // Inputs and outputs are 1 byte each. This is enforced by the
                // structure of the bytecode itself.
                assembly ("memory-safe") {
                    mstore8(ioCursor, inputsLength)
                    mstore8(add(ioCursor, 1), outputsLength)
                    ioCursor := add(ioCursor, 2)
                }

                IntegrityCheckStateNP memory state = LibIntegrityCheckNP.newState(bytecode, inputsLength, constants);

                // Have low 4 bytes of cursor overlap the first op, skipping the
                // prefix.
                uint256 cursor = Pointer.unwrap(LibBytecode.sourcePointer(bytecode, i)) - 0x18;
                uint256 end = cursor + LibBytecode.sourceOpsCount(bytecode, i) * 4;

                while (cursor < end) {
                    Operand operand;
                    uint256 bytecodeOpInputs;
                    uint256 bytecodeOpOutputs;
                    function(IntegrityCheckStateNP memory, Operand)
                    view
                    returns (uint256, uint256) f;
                    assembly ("memory-safe") {
                        let word := mload(cursor)
                        f := shr(0xf0, mload(add(fPointersStart, mul(byte(28, word), 2))))
                        // 3 bytes mask.
                        operand := and(word, 0xFFFFFF)
                        let ioByte := byte(29, word)
                        bytecodeOpInputs := and(ioByte, 0x0F)
                        bytecodeOpOutputs := shr(4, ioByte)
                    }
                    (uint256 calcOpInputs, uint256 calcOpOutputs) = f(state, operand);
                    if (calcOpInputs != bytecodeOpInputs) {
                        revert BadOpInputsLength(state.opIndex, calcOpInputs, bytecodeOpInputs);
                    }
                    if (calcOpOutputs != bytecodeOpOutputs) {
                        revert BadOpOutputsLength(state.opIndex, calcOpOutputs, bytecodeOpOutputs);
                    }

                    if (calcOpInputs > state.stackIndex) {
                        revert StackUnderflow(state.opIndex, state.stackIndex, calcOpInputs);
                    }
                    state.stackIndex -= calcOpInputs;

                    // The stack index can't move below the highwater.
                    if (state.stackIndex < state.readHighwater) {
                        revert StackUnderflowHighwater(state.opIndex, state.stackIndex, state.readHighwater);
                    }

                    // Let's assume that sane opcode implementations don't
                    // overflow uint256 due to their outputs.
                    state.stackIndex += calcOpOutputs;

                    // Ensure the max stack index is updated if needed.
                    if (state.stackIndex > state.stackMaxIndex) {
                        state.stackMaxIndex = state.stackIndex;
                    }

                    // If there are multiple outputs the highwater MUST move.
                    if (calcOpOutputs > 1) {
                        state.readHighwater = state.stackIndex;
                    }

                    state.opIndex++;
                    cursor += 4;
                }

                // The final stack max index MUST match the bytecode allocation.
                if (state.stackMaxIndex != LibBytecode.sourceStackAllocation(bytecode, i)) {
                    revert StackAllocationMismatch(state.stackMaxIndex, LibBytecode.sourceStackAllocation(bytecode, i));
                }

                // The final stack index MUST match the bytecode source outputs.
                if (state.stackIndex != outputsLength) {
                    revert StackOutputsMismatch(state.stackIndex, outputsLength);
                }
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {MemoryKV} from "rain.lib.memkv/lib/LibMemoryKV.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {LibMemCpy} from "rain.solmem/lib/LibMemCpy.sol";
import {LibBytes} from "rain.solmem/lib/LibBytes.sol";
import {FullyQualifiedNamespace} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {IInterpreterStoreV2} from "rain.interpreter.interface/interface/IInterpreterStoreV2.sol";

import {InterpreterStateNP} from "./LibInterpreterStateNP.sol";

library LibInterpreterStateDataContractNP {
    using LibBytes for bytes;

    function serializeSizeNP(bytes memory bytecode, uint256[] memory constants) internal pure returns (uint256 size) {
        unchecked {
            // bytecode length + constants length * 0x20 + 0x40 for both the bytecode and constants length words.
            size = bytecode.length + constants.length * 0x20 + 0x40;
        }
    }

    function unsafeSerializeNP(Pointer cursor, bytes memory bytecode, uint256[] memory constants) internal pure {
        unchecked {
            // Copy constants into place with length.
            assembly ("memory-safe") {
                for {
                    let constantsCursor := constants
                    let constantsEnd := add(constantsCursor, mul(0x20, add(mload(constants), 1)))
                } lt(constantsCursor, constantsEnd) {
                    constantsCursor := add(constantsCursor, 0x20)
                    cursor := add(cursor, 0x20)
                } { mstore(cursor, mload(constantsCursor)) }
            }
            // Copy the bytecode into place with length.
            LibMemCpy.unsafeCopyBytesTo(bytecode.startPointer(), cursor, bytecode.length + 0x20);
        }
    }

    function unsafeDeserializeNP(
        bytes memory serialized,
        uint256 sourceIndex,
        FullyQualifiedNamespace namespace,
        IInterpreterStoreV2 store,
        uint256[][] memory context,
        bytes memory fs
    ) internal pure returns (InterpreterStateNP memory) {
        unchecked {
            Pointer cursor;
            assembly ("memory-safe") {
                cursor := add(serialized, 0x20)
            }

            // Reference the constants array as-is and move cursor past it.
            uint256[] memory constants;
            assembly ("memory-safe") {
                constants := cursor
                cursor := add(cursor, mul(0x20, add(mload(cursor), 1)))
            }

            // Reference the bytecode array as-is.
            bytes memory bytecode;
            assembly ("memory-safe") {
                bytecode := cursor
            }

            // Build all the stacks.
            Pointer[] memory stackBottoms;
            assembly ("memory-safe") {
                cursor := add(cursor, 0x20)
                let stacksLength := byte(0, mload(cursor))
                cursor := add(cursor, 1)
                let sourcesStart := add(cursor, mul(stacksLength, 2))

                // Allocate the memory for stackBottoms.
                // We don't need to zero this because we're about to write to it.
                stackBottoms := mload(0x40)
                mstore(stackBottoms, stacksLength)
                mstore(0x40, add(stackBottoms, mul(add(stacksLength, 1), 0x20)))

                // Allocate each stack and point to it.
                let stacksCursor := add(stackBottoms, 0x20)
                for { let i := 0 } lt(i, stacksLength) {
                    i := add(i, 1)
                    // Move over the 2 byte source pointer.
                    cursor := add(cursor, 2)
                    // Move the stacks cursor forward.
                    stacksCursor := add(stacksCursor, 0x20)
                } {
                    // The stack size is in the prefix of the source data, which
                    // is behind a relative pointer in the bytecode prefix.
                    let sourcePointer := add(sourcesStart, shr(0xf0, mload(cursor)))
                    // Stack size is the second byte of the source prefix.
                    let stackSize := byte(1, mload(sourcePointer))

                    // Allocate the stack.
                    // We don't need to zero the stack because the interpreter
                    // assumes values above the stack top are dirty anyway.
                    let stack := mload(0x40)
                    mstore(stack, stackSize)
                    let stackBottom := add(stack, mul(add(stackSize, 1), 0x20))
                    mstore(0x40, stackBottom)

                    // Point to the stack bottom
                    mstore(stacksCursor, stackBottom)
                }
            }

            return InterpreterStateNP(
                stackBottoms, constants, sourceIndex, MemoryKV.wrap(0), namespace, store, context, bytecode, fs
            );
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {BadDynamicLength} from "../../error/ErrOpList.sol";
import {LibConvert} from "rain.lib.typecast/LibConvert.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {AuthoringMetaV2} from "rain.interpreter.interface/interface/IParserV1.sol";
import {LibIntegrityCheckNP, IntegrityCheckStateNP} from "../integrity/LibIntegrityCheckNP.sol";
import {LibInterpreterStateNP, InterpreterStateNP} from "../state/LibInterpreterStateNP.sol";
import {LibParseOperand} from "../parse/LibParseOperand.sol";
import {LibUint256Array} from "rain.solmem/lib/LibUint256Array.sol";
import {LibOpStackNP} from "./00/LibOpStackNP.sol";
import {LibOpConstantNP} from "./00/LibOpConstantNP.sol";
import {LibOpExternNP} from "./00/LibOpExternNP.sol";

import {LibOpBitwiseAndNP} from "./bitwise/LibOpBitwiseAndNP.sol";
import {LibOpBitwiseOrNP} from "./bitwise/LibOpBitwiseOrNP.sol";
import {LibOpCtPopNP} from "./bitwise/LibOpCtPopNP.sol";
import {LibOpDecodeBitsNP} from "./bitwise/LibOpDecodeBitsNP.sol";
import {LibOpEncodeBitsNP} from "./bitwise/LibOpEncodeBitsNP.sol";
import {LibOpShiftBitsLeftNP} from "./bitwise/LibOpShiftBitsLeftNP.sol";
import {LibOpShiftBitsRightNP} from "./bitwise/LibOpShiftBitsRightNP.sol";

import {LibOpCallNP} from "./call/LibOpCallNP.sol";

import {LibOpContextNP} from "./context/LibOpContextNP.sol";

import {LibOpHashNP} from "./crypto/LibOpHashNP.sol";

import {LibOpERC20AllowanceNP} from "./erc20/LibOpERC20AllowanceNP.sol";
import {LibOpERC20BalanceOfNP} from "./erc20/LibOpERC20BalanceOfNP.sol";
import {LibOpERC20TotalSupplyNP} from "./erc20/LibOpERC20TotalSupplyNP.sol";

import {LibOpERC721BalanceOfNP} from "./erc721/LibOpERC721BalanceOfNP.sol";
import {LibOpERC721OwnerOfNP} from "./erc721/LibOpERC721OwnerOfNP.sol";

import {LibOpERC5313OwnerNP} from "./erc5313/LibOpERC5313OwnerNP.sol";

import {LibOpBlockNumberNP} from "./evm/LibOpBlockNumberNP.sol";
import {LibOpChainIdNP} from "./evm/LibOpChainIdNP.sol";
import {LibOpMaxUint256NP} from "./evm/LibOpMaxUint256NP.sol";
import {LibOpTimestampNP} from "./evm/LibOpTimestampNP.sol";

import {LibOpAnyNP} from "./logic/LibOpAnyNP.sol";
import {LibOpConditionsNP} from "./logic/LibOpConditionsNP.sol";
import {LibOpEnsureNP} from "./logic/LibOpEnsureNP.sol";
import {LibOpEqualToNP} from "./logic/LibOpEqualToNP.sol";
import {LibOpEveryNP} from "./logic/LibOpEveryNP.sol";
import {LibOpGreaterThanNP} from "./logic/LibOpGreaterThanNP.sol";
import {LibOpGreaterThanOrEqualToNP} from "./logic/LibOpGreaterThanOrEqualToNP.sol";
import {LibOpIfNP} from "./logic/LibOpIfNP.sol";
import {LibOpIsZeroNP} from "./logic/LibOpIsZeroNP.sol";
import {LibOpLessThanNP} from "./logic/LibOpLessThanNP.sol";
import {LibOpLessThanOrEqualToNP} from "./logic/LibOpLessThanOrEqualToNP.sol";

import {LibOpDecimal18ExponentialGrowthNP} from "./math/decimal18/growth/LibOpDecimal18ExponentialGrowthNP.sol";
import {LibOpDecimal18LinearGrowthNP} from "./math/decimal18/growth/LibOpDecimal18LinearGrowthNP.sol";
import {LibOpDecimal18AvgNP} from "./math/decimal18/LibOpDecimal18AvgNP.sol";
import {LibOpDecimal18CeilNP} from "./math/decimal18/LibOpDecimal18CeilNP.sol";
import {LibOpDecimal18MulNP} from "./math/decimal18/LibOpDecimal18MulNP.sol";
import {LibOpDecimal18DivNP} from "./math/decimal18/LibOpDecimal18DivNP.sol";
import {LibOpDecimal18ExpNP} from "./math/decimal18/LibOpDecimal18ExpNP.sol";
import {LibOpDecimal18Exp2NP} from "./math/decimal18/LibOpDecimal18Exp2NP.sol";
import {LibOpDecimal18FloorNP} from "./math/decimal18/LibOpDecimal18FloorNP.sol";
import {LibOpDecimal18FracNP} from "./math/decimal18/LibOpDecimal18FracNP.sol";
import {LibOpDecimal18GmNP} from "./math/decimal18/LibOpDecimal18GmNP.sol";
import {LibOpDecimal18HeadroomNP} from "./math/decimal18/LibOpDecimal18HeadroomNP.sol";
import {LibOpDecimal18InvNP} from "./math/decimal18/LibOpDecimal18InvNP.sol";
import {LibOpDecimal18LnNP} from "./math/decimal18/LibOpDecimal18LnNP.sol";
import {LibOpDecimal18Log10NP} from "./math/decimal18/LibOpDecimal18Log10NP.sol";
import {LibOpDecimal18Log2NP} from "./math/decimal18/LibOpDecimal18Log2NP.sol";
import {LibOpDecimal18PowNP} from "./math/decimal18/LibOpDecimal18PowNP.sol";
import {LibOpDecimal18PowUNP} from "./math/decimal18/LibOpDecimal18PowUNP.sol";
import {LibOpDecimal18Scale18DynamicNP} from "./math/decimal18/LibOpDecimal18Scale18DynamicNP.sol";
import {LibOpDecimal18Scale18NP} from "./math/decimal18/LibOpDecimal18Scale18NP.sol";
import {LibOpDecimal18ScaleNDynamicNP} from "./math/decimal18/LibOpDecimal18ScaleNDynamicNP.sol";
import {LibOpDecimal18ScaleNNP} from "./math/decimal18/LibOpDecimal18ScaleNNP.sol";
import {LibOpDecimal18SnapToUnitNP} from "./math/decimal18/LibOpDecimal18SnapToUnitNP.sol";
import {LibOpDecimal18SqrtNP} from "./math/decimal18/LibOpDecimal18SqrtNP.sol";

import {LibOpIntAddNP} from "./math/int/LibOpIntAddNP.sol";
import {LibOpIntDivNP} from "./math/int/LibOpIntDivNP.sol";
import {LibOpIntExpNP} from "./math/int/LibOpIntExpNP.sol";
import {LibOpIntMaxNP} from "./math/int/LibOpIntMaxNP.sol";
import {LibOpIntMinNP} from "./math/int/LibOpIntMinNP.sol";
import {LibOpIntModNP} from "./math/int/LibOpIntModNP.sol";
import {LibOpIntMulNP} from "./math/int/LibOpIntMulNP.sol";
import {LibOpIntSubNP} from "./math/int/LibOpIntSubNP.sol";

import {LibOpGetNP} from "./store/LibOpGetNP.sol";
import {LibOpSetNP} from "./store/LibOpSetNP.sol";

import {LibParseLiteral, ParseState, LITERAL_PARSERS_LENGTH} from "../parse/literal/LibParseLiteral.sol";
import {LibParseLiteralString} from "../parse/literal/LibParseLiteralString.sol";
import {LibParseLiteralDecimal} from "../parse/literal/LibParseLiteralDecimal.sol";
import {LibParseLiteralHex} from "../parse/literal/LibParseLiteralHex.sol";
import {LibParseLiteralSubParseable} from "../parse/literal/LibParseLiteralSubParseable.sol";

/// @dev Number of ops currently provided by `AllStandardOpsNP`.
uint256 constant ALL_STANDARD_OPS_LENGTH = 77;

/// @title LibAllStandardOpsNP
/// @notice Every opcode available from the core repository laid out as a single
/// array to easily build function pointers for `IInterpreterV2`.
library LibAllStandardOpsNP {
    function authoringMetaV2() internal pure returns (bytes memory) {
        AuthoringMetaV2 memory lengthPlaceholder;
        AuthoringMetaV2[ALL_STANDARD_OPS_LENGTH + 1] memory wordsFixed = [
            lengthPlaceholder,
            // Stack, constant and extern MUST be in this order for parsing to work.
            AuthoringMetaV2("stack", "Copies an existing value from the stack."),
            AuthoringMetaV2("constant", "Copies a constant value onto the stack."),
            AuthoringMetaV2(
                "extern",
                "Calls an external contract. The operand is the index of the encoded dispatch in the constants array. The outputs are inferred from the number of LHS items."
            ),
            AuthoringMetaV2(
                "context",
                "Copies a value from the context. The first operand is the context column and second is the context row."
            ),
            // These are all ordered according to how they appear in the file system.
            AuthoringMetaV2("bitwise-and", "Bitwise AND the top two items on the stack."),
            AuthoringMetaV2("bitwise-or", "Bitwise OR the top two items on the stack."),
            AuthoringMetaV2("bitwise-count-ones", "Counts the number of binary bits set to 1 in the input."),
            AuthoringMetaV2(
                "bitwise-decode",
                "Decodes a value from a 256 bit value that was encoded with bitwise-encode. The first operand is the start bit and the second is the length."
            ),
            AuthoringMetaV2(
                "bitwise-encode",
                "Encodes a value into a 256 bit value. The first operand is the start bit and the second is the length."
            ),
            AuthoringMetaV2("bitwise-shift-left", "Shifts the input left by the number of bits specified in the operand."),
            AuthoringMetaV2("bitwise-shift-right", "Shifts the input right by the number of bits specified in the operand."),
            AuthoringMetaV2(
                "call",
                "Calls a source by index in the same Rain bytecode. The inputs to call are copied to the top of the called stack and the outputs are copied back to the calling stack according to the LHS items. The first operand is the source index."
            ),
            AuthoringMetaV2("hash", "Hashes all inputs into a single 32 byte value using keccak256."),
            AuthoringMetaV2(
                "erc20-allowance",
                "Gets the allowance of an erc20 token for an account. The first input is the token address, the second is the owner address, and the third is the spender address."
            ),
            AuthoringMetaV2(
                "erc20-balance-of",
                "Gets the balance of an erc20 token for an account. The first input is the token address and the second is the account address."
            ),
            AuthoringMetaV2(
                "erc20-total-supply", "Gets the total supply of an erc20 token. The input is the token address."
            ),
            AuthoringMetaV2(
                "erc721-balance-of",
                "Gets the balance of an erc721 token for an account. The first input is the token address and the second is the account address."
            ),
            AuthoringMetaV2(
                "erc721-owner-of",
                "Gets the owner of an erc721 token. The first input is the token address and the second is the token id."
            ),
            AuthoringMetaV2(
                "erc5313-owner",
                "Gets the owner of an erc5313 compatible contract. Note that erc5313 specifically DOES NOT do any onchain compatibility checks, so the expression author is responsible for ensuring the contract is compatible. The input is the contract address to get the owner of."
            ),
            AuthoringMetaV2("block-number", "The current block number."),
            AuthoringMetaV2("chain-id", "The current chain id."),
            AuthoringMetaV2("max-int-value", "The maximum possible non-negative integer value. 2^256 - 1."),
            AuthoringMetaV2("max-decimal18-value", "The maximum possible 18 decimal fixed point value. roughly 1.15e77."),
            AuthoringMetaV2("block-timestamp", "The current block timestamp."),
            AuthoringMetaV2("any", "The first non-zero value out of all inputs, or 0 if every input is 0."),
            AuthoringMetaV2(
                "conditions",
                "Treats inputs as pairwise condition/value pairs. The first nonzero condition's value is used. If no conditions are nonzero, the expression reverts. Provide a constant nonzero value to define a fallback case. If the number of inputs is odd, the final value is used as an error string in the case that no conditions match."
            ),
            AuthoringMetaV2(
                "ensure",
                "Reverts if the first input is 0. The second input is a string that is used as the revert reason if the first input is 0. Has 0 outputs."
            ),
            AuthoringMetaV2("equal-to", "1 if all inputs are equal, 0 otherwise."),
            AuthoringMetaV2("every", "The last nonzero value out of all inputs, or 0 if any input is 0."),
            AuthoringMetaV2("greater-than", "1 if the first input is greater than the second input, 0 otherwise."),
            AuthoringMetaV2(
                "greater-than-or-equal-to",
                "1 if the first input is greater than or equal to the second input, 0 otherwise."
            ),
            AuthoringMetaV2(
                "if",
                "If the first input is nonzero, the second input is used. Otherwise, the third input is used. If is eagerly evaluated."
            ),
            AuthoringMetaV2("is-zero", "1 if the input is 0, 0 otherwise."),
            AuthoringMetaV2("less-than", "1 if the first input is less than the second input, 0 otherwise."),
            AuthoringMetaV2(
                "less-than-or-equal-to", "1 if the first input is less than or equal to the second input, 0 otherwise."
            ),
            AuthoringMetaV2(
                "decimal18-exponential-growth",
                "Calculates an exponential growth curve as `base(1 + rate)^t` where `base` is the initial value, `rate` is the rate of growth and `t` is units of time. Inputs in order are `base`, `rate`, and `t` respectively as decimal 18 values."
            ),
            AuthoringMetaV2(
                "decimal18-linear-growth",
                "Calculates a linear growth curve as `base + (rate * t)` where `base` is the initial value, `rate` is the rate of growth and `t` is units of time. Inputs in order are `base`, `rate`, and `t` respectively as decimal 18 values."
            ),
            AuthoringMetaV2("decimal18-avg", "18 decimal fixed point arithmetic average of two numbers."),
            AuthoringMetaV2("decimal18-ceil", "18 decimal fixed point ceiling of a number."),
            AuthoringMetaV2(
                "decimal18-div",
                "Divides the first input by all other inputs as fixed point 18 decimal numbers (i.e. 'one' is 1e18). Errors if any divisor is zero."
            ),
            AuthoringMetaV2(
                "decimal18-exp",
                "Calculates the natural exponential e^x where x is the input as a fixed point 18 decimal number (i.e. 'one' is 1e18). Errors if the exponentiation would exceed the maximum value (roughly 1.15e77)."
            ),
            AuthoringMetaV2(
                "decimal18-exp2",
                "Calculates the binary exponential 2^x where x is the input as a fixed point 18 decimal number (i.e. 'one' is 1e18). Errors if the exponentiation would exceed the maximum value (roughly 1.15e77)."
            ),
            AuthoringMetaV2("decimal18-floor", "18 decimal fixed point floor of a number."),
            AuthoringMetaV2("decimal18-frac", "18 decimal fixed point fractional part of a number."),
            AuthoringMetaV2(
                "decimal18-gm",
                "Calculates the geometric mean of all inputs as fixed point 18 decimal numbers (i.e. 'one' is 1e18). Errors if any input is zero."
            ),
            AuthoringMetaV2(
                "decimal18-headroom",
                "18 decimal fixed point headroom of a number. I.e. the distance to the next whole number (1e18 - frac(x)). The headroom at any whole decimal 18 number is 1e18 (not 0)."
            ),
            AuthoringMetaV2(
                "decimal18-inv",
                "Calculates the inverse 1 / x of the input as a fixed point 18 decimal number (i.e. 'one' is 1e18). Errors if the input is zero."
            ),
            AuthoringMetaV2(
                "decimal18-ln",
                "Calculates the natural logarithm ln(x) where x is the input as a fixed point 18 decimal number (i.e. 'one' is 1e18). Errors if the input is zero."
            ),
            AuthoringMetaV2(
                "decimal18-log10",
                "Calculates the base 10 logarithm log10(x) where x is the input as a fixed point 18 decimal number (i.e. 'one' is 1e18). Errors if the input is zero."
            ),
            AuthoringMetaV2(
                "decimal18-log2",
                "Calculates the base 2 logarithm log2(x) where x is the input as a fixed point 18 decimal number (i.e. 'one' is 1e18). Errors if the input is zero."
            ),
            AuthoringMetaV2(
                "decimal18-mul",
                "Multiplies all inputs together as fixed point 18 decimal numbers (i.e. 'one' is 1e18). Errors if the multiplication exceeds the maximum value (roughly 1.15e77)."
            ),
            AuthoringMetaV2(
                "decimal18-power",
                "Raises the first input as a fixed point 18 decimal value to the power of the second input as a fixed point 18 decimal value. Errors if the exponentiation would exceed the maximum value (roughly 1.15e77)."
            ),
            AuthoringMetaV2(
                "decimal18-power-int",
                "Raises the first input as a fixed point 18 decimal value to the power of the second input as an integer."
            ),
            AuthoringMetaV2(
                "decimal18-scale-18-dynamic",
                "Scales a value from some fixed point decimal scale to 18 decimal fixed point. The first input is the scale to scale from and the second is the value to scale. The two optional operands control rounding and saturation respectively as per `decimal18-scale-18`."
            ),
            AuthoringMetaV2(
                "decimal18-scale-18",
                "Scales an input value from some fixed point decimal scale to 18 decimal fixed point. The first operand is the scale to scale from. The second (optional) operand controls rounding where 0 (default) rounds down and 1 rounds up. The third (optional) operand controls saturation where 0 (default) errors on overflow and 1 saturates at max-decimal-value."
            ),
            AuthoringMetaV2(
                "int-to-decimal18",
                "Scales an integer value to 18 decimal fixed point, E.g. 1 becomes 1e18 and 10 becomes 1e19. Identical to `decimal18-scale-18` with an input scale of 0, but perhaps more legible. Does NOT support saturation."
            ),
            AuthoringMetaV2(
                "decimal18-scale-n-dynamic",
                "Scales an input value from 18 decimal fixed point to some other fixed point scale N. The first input is the scale to scale to and the second is the value to scale. The two optional operand controls rounding and saturation respectively as per `decimal18-scale-n`."
            ),
            AuthoringMetaV2(
                "decimal18-scale-n",
                "Scales an input value from 18 decimal fixed point to some other fixed point scale N. The first operand is the scale to scale to. The second (optional) operand controls rounding where 0 (default) rounds down and 1 rounds up. The third (optional) operand controls saturation where 0 (default) errors on overflow and 1 saturates at max-decimal-value."
            ),
            AuthoringMetaV2(
                "decimal18-to-int",
                "Scales a fixed point 18 decimal number (i.e. 'one' is 1e18) to a non-negative integer. Always floors/rounds down any fractional part to the nearest whole integer. Identical to `decimal18-scale-n` with an input scale of 0, but perhaps more legible."
            ),
            AuthoringMetaV2(
                "decimal18-snap-to-unit",
                "Rounds a fixed point 18 decimal number (i.e. 'one' is 1e18) to the nearest whole number if it is within the threshold distance from that whole number. The first input is the threshold as an 18 decimal fixed point number and the second is the value to snap to the nearest unit."
            ),
            AuthoringMetaV2(
                "decimal18-sqrt",
                "Calculates the square root of the input as a fixed point 18 decimal number (i.e. 'one' is 1e18). Errors if the input is negative."
            ),
            // int and decimal18 add have identical implementations and point to
            // the same function pointer. This is intentional.
            AuthoringMetaV2(
                "int-add",
                "Adds all inputs together as non-negative integers. Errors if the addition exceeds the maximum value (roughly 1.15e77)."
            ),
            AuthoringMetaV2(
                "decimal18-add",
                "Adds all inputs together as fixed point 18 decimal numbers (i.e. 'one' is 1e18). Errors if the addition exceeds the maximum value (roughly 1.15e77)."
            ),
            AuthoringMetaV2(
                "int-div",
                "Divides the first input by all other inputs as non-negative integers. Errors if any divisor is zero."
            ),
            AuthoringMetaV2(
                "int-exp",
                "Raises the first input to the power of all other inputs as non-negative integers. Errors if the exponentiation would exceed the maximum value (roughly 1.15e77)."
            ),
            // int and decimal18 max have identical implementations and point to
            // the same function pointer. This is intentional.
            AuthoringMetaV2("int-max", "Finds the maximum value from all inputs as non-negative integers."),
            AuthoringMetaV2(
                "decimal18-max",
                "Finds the maximum value from all inputs as fixed point 18 decimal numbers (i.e. 'one' is 1e18)."
            ),
            // int and decimal18 min have identical implementations and point to
            // the same function pointer. This is intentional.
            AuthoringMetaV2("int-min", "Finds the minimum value from all inputs as non-negative integers."),
            AuthoringMetaV2(
                "decimal18-min",
                "Finds the minimum value from all inputs as fixed point 18 decimal numbers (i.e. 'one' is 1e18)."
            ),
            AuthoringMetaV2(
                "int-mod",
                "Modulos the first input by all other inputs as non-negative integers. Errors if any divisor is zero."
            ),
            AuthoringMetaV2(
                "int-mul",
                "Multiplies all inputs together as non-negative integers. Errors if the multiplication exceeds the maximum value (roughly 1.15e77)."
            ),
            // int and decimal18 sub have identical implementations and point to
            // the same function pointer. This is intentional.
            AuthoringMetaV2(
                "int-sub",
                "Subtracts all inputs from the first input as non-negative integers. The optional operand controls whether subtraction will saturate at 0. The default behaviour, and what will happen if the operand is 0, is that the word will revert if the subtraction would result in a negative value. If the operand is 1, the word will saturate at 0 (e.g. 1-2=0)."
            ),
            AuthoringMetaV2(
                "int-saturating-sub",
                "Subtracts all inputs from the first input as non-negative integers. Saturates at 0 (e.g. 1-2=0)."
            ),
            AuthoringMetaV2(
                "decimal18-sub",
                "Subtracts all inputs from the first input as fixed point 18 decimal numbers (i.e. 'one' is 1e18). The optional operand controls whether subtraction will saturate at 0. The default behaviour, and what will happen if the operand is 0, is that the word will revert if the subtraction would result in a negative value. If the operand is 1, the word will saturate at 0 (e.g. 1e18-2e18=0)."
            ),
            AuthoringMetaV2(
                "decimal18-saturating-sub",
                "Subtracts all inputs from the first input as fixed point 18 decimal numbers (i.e. 'one' is 1e18). Saturates at 0 (e.g. 1e18-2e18=0)."
            ),
            AuthoringMetaV2("get", "Gets a value from storage. The first operand is the key to lookup."),
            AuthoringMetaV2(
                "set",
                "Sets a value in storage. The first operand is the key to set and the second operand is the value to set."
            )
        ];
        AuthoringMetaV2[] memory wordsDynamic;
        uint256 length = ALL_STANDARD_OPS_LENGTH;
        assembly ("memory-safe") {
            wordsDynamic := wordsFixed
            mstore(wordsDynamic, length)
        }
        return abi.encode(wordsDynamic);
    }

    function literalParserFunctionPointers() internal pure returns (bytes memory) {
        unchecked {
            function (ParseState memory, uint256, uint256) pure returns (uint256, uint256) lengthPointer;
            uint256 length = LITERAL_PARSERS_LENGTH;
            assembly ("memory-safe") {
                lengthPointer := length
            }
            function (ParseState memory, uint256, uint256) pure returns (uint256, uint256)[LITERAL_PARSERS_LENGTH + 1]
                memory pointersFixed = [
                    lengthPointer,
                    LibParseLiteralHex.parseHex,
                    LibParseLiteralDecimal.parseDecimal,
                    LibParseLiteralString.parseString,
                    LibParseLiteralSubParseable.parseSubParseable
                ];
            uint256[] memory pointersDynamic;
            assembly ("memory-safe") {
                pointersDynamic := pointersFixed
            }
            // Sanity check that the dynamic length is correct. Should be an
            // unreachable error.
            if (pointersDynamic.length != LITERAL_PARSERS_LENGTH) {
                revert BadDynamicLength(pointersDynamic.length, length);
            }
            return LibConvert.unsafeTo16BitBytes(pointersDynamic);
        }
    }

    function operandHandlerFunctionPointers() internal pure returns (bytes memory) {
        unchecked {
            function (uint256[] memory) internal pure returns (Operand) lengthPointer;
            uint256 length = ALL_STANDARD_OPS_LENGTH;
            assembly ("memory-safe") {
                lengthPointer := length
            }
            function (uint256[] memory) internal pure returns (Operand)[ALL_STANDARD_OPS_LENGTH + 1] memory
                pointersFixed = [
                    lengthPointer,
                    // Stack
                    LibParseOperand.handleOperandSingleFull,
                    // Constant
                    LibParseOperand.handleOperandSingleFull,
                    // Extern
                    LibParseOperand.handleOperandSingleFull,
                    // Context
                    LibParseOperand.handleOperandDoublePerByteNoDefault,
                    // Bitwise and
                    LibParseOperand.handleOperandDisallowed,
                    // Bitwise or
                    LibParseOperand.handleOperandDisallowed,
                    // Bitwise count ones
                    LibParseOperand.handleOperandDisallowed,
                    // Bitwise decode
                    LibParseOperand.handleOperandDoublePerByteNoDefault,
                    // Bitwise encode
                    LibParseOperand.handleOperandDoublePerByteNoDefault,
                    // Bitwise shift left
                    LibParseOperand.handleOperandSingleFull,
                    // Bitwise shift right
                    LibParseOperand.handleOperandSingleFull,
                    // Call
                    LibParseOperand.handleOperandSingleFull,
                    // Hash
                    LibParseOperand.handleOperandDisallowed,
                    // ERC20 allowance
                    LibParseOperand.handleOperandDisallowed,
                    // ERC20 balance of
                    LibParseOperand.handleOperandDisallowed,
                    // ERC20 total supply
                    LibParseOperand.handleOperandDisallowed,
                    // ERC721 balance of
                    LibParseOperand.handleOperandDisallowed,
                    // ERC721 owner of
                    LibParseOperand.handleOperandDisallowed,
                    // ERC5313 owner
                    LibParseOperand.handleOperandDisallowed,
                    // Block number
                    LibParseOperand.handleOperandDisallowed,
                    // Chain id
                    LibParseOperand.handleOperandDisallowed,
                    // Max int value
                    LibParseOperand.handleOperandDisallowed,
                    // Max decimal18 value
                    LibParseOperand.handleOperandDisallowed,
                    // Block timestamp
                    LibParseOperand.handleOperandDisallowed,
                    // Any
                    LibParseOperand.handleOperandDisallowed,
                    // Conditions
                    LibParseOperand.handleOperandDisallowed,
                    // Ensure
                    LibParseOperand.handleOperandDisallowed,
                    // Equal to
                    LibParseOperand.handleOperandDisallowed,
                    // Every
                    LibParseOperand.handleOperandDisallowed,
                    // Greater than
                    LibParseOperand.handleOperandDisallowed,
                    // Greater than or equal to
                    LibParseOperand.handleOperandDisallowed,
                    // If
                    LibParseOperand.handleOperandDisallowed,
                    // Is zero
                    LibParseOperand.handleOperandDisallowed,
                    // Less than
                    LibParseOperand.handleOperandDisallowed,
                    // Less than or equal to
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 exponential growth
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 linear growth
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 avg
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 ceil
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 div
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 exp
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 exp2
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 floor
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 frac
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 gm
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 headroom
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 inv
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 ln
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 log10
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 log2
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 mul
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 power
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 power int
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 scale18 dynamic
                    LibParseOperand.handleOperandM1M1,
                    // Decimal18 scale18
                    LibParseOperand.handleOperand8M1M1,
                    // Int to decimal18
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 scale n dynamic
                    LibParseOperand.handleOperandM1M1,
                    // Decimal18 scale n
                    LibParseOperand.handleOperand8M1M1,
                    // Decimal18 to int
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 snap to unit
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 sqrt
                    LibParseOperand.handleOperandDisallowed,
                    // Int add
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 add
                    LibParseOperand.handleOperandDisallowed,
                    // Int div
                    LibParseOperand.handleOperandDisallowed,
                    // Int exp
                    LibParseOperand.handleOperandDisallowed,
                    // Int max
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 max
                    LibParseOperand.handleOperandDisallowed,
                    // Int min
                    LibParseOperand.handleOperandDisallowed,
                    // Decimal18 min
                    LibParseOperand.handleOperandDisallowed,
                    // Int mod
                    LibParseOperand.handleOperandDisallowed,
                    // Int mul
                    LibParseOperand.handleOperandDisallowed,
                    // Int sub
                    LibParseOperand.handleOperandSingleFull,
                    // Int saturating sub
                    LibParseOperand.handleOperandDisallowedAlwaysOne,
                    // Decimal18 sub
                    LibParseOperand.handleOperandSingleFull,
                    // Decimal18 saturating sub
                    LibParseOperand.handleOperandDisallowedAlwaysOne,
                    // Get
                    LibParseOperand.handleOperandDisallowed,
                    // Set
                    LibParseOperand.handleOperandDisallowed
                ];
            uint256[] memory pointersDynamic;
            assembly ("memory-safe") {
                pointersDynamic := pointersFixed
            }
            // Sanity check that the dynamic length is correct. Should be an
            // unreachable error.
            if (pointersDynamic.length != ALL_STANDARD_OPS_LENGTH) {
                revert BadDynamicLength(pointersDynamic.length, length);
            }
            return LibConvert.unsafeTo16BitBytes(pointersDynamic);
        }
    }

    function integrityFunctionPointers() internal pure returns (bytes memory) {
        unchecked {
            function(IntegrityCheckStateNP memory, Operand)
                view
                returns (uint256, uint256) lengthPointer;
            uint256 length = ALL_STANDARD_OPS_LENGTH;
            assembly ("memory-safe") {
                lengthPointer := length
            }
            function(IntegrityCheckStateNP memory, Operand)
                view
                returns (uint256, uint256)[ALL_STANDARD_OPS_LENGTH + 1] memory pointersFixed = [
                    lengthPointer,
                    // The first ops are out of lexical ordering so that they
                    // can sit at stable well known indexes.
                    LibOpStackNP.integrity,
                    LibOpConstantNP.integrity,
                    LibOpExternNP.integrity,
                    LibOpContextNP.integrity,
                    // Everything else is alphabetical, including folders.
                    LibOpBitwiseAndNP.integrity,
                    LibOpBitwiseOrNP.integrity,
                    LibOpCtPopNP.integrity,
                    LibOpDecodeBitsNP.integrity,
                    LibOpEncodeBitsNP.integrity,
                    LibOpShiftBitsLeftNP.integrity,
                    LibOpShiftBitsRightNP.integrity,
                    LibOpCallNP.integrity,
                    LibOpHashNP.integrity,
                    LibOpERC20AllowanceNP.integrity,
                    LibOpERC20BalanceOfNP.integrity,
                    LibOpERC20TotalSupplyNP.integrity,
                    LibOpERC721BalanceOfNP.integrity,
                    LibOpERC721OwnerOfNP.integrity,
                    LibOpERC5313OwnerNP.integrity,
                    LibOpBlockNumberNP.integrity,
                    LibOpChainIdNP.integrity,
                    // int and decimal18 max have identical implementations and
                    // point to the same function pointer. This is intentional.
                    LibOpMaxUint256NP.integrity,
                    // decimal18 max.
                    LibOpMaxUint256NP.integrity,
                    LibOpTimestampNP.integrity,
                    LibOpAnyNP.integrity,
                    LibOpConditionsNP.integrity,
                    LibOpEnsureNP.integrity,
                    LibOpEqualToNP.integrity,
                    LibOpEveryNP.integrity,
                    LibOpGreaterThanNP.integrity,
                    LibOpGreaterThanOrEqualToNP.integrity,
                    LibOpIfNP.integrity,
                    LibOpIsZeroNP.integrity,
                    LibOpLessThanNP.integrity,
                    LibOpLessThanOrEqualToNP.integrity,
                    LibOpDecimal18ExponentialGrowthNP.integrity,
                    LibOpDecimal18LinearGrowthNP.integrity,
                    LibOpDecimal18AvgNP.integrity,
                    LibOpDecimal18CeilNP.integrity,
                    LibOpDecimal18DivNP.integrity,
                    LibOpDecimal18ExpNP.integrity,
                    LibOpDecimal18Exp2NP.integrity,
                    LibOpDecimal18FloorNP.integrity,
                    LibOpDecimal18FracNP.integrity,
                    LibOpDecimal18GmNP.integrity,
                    LibOpDecimal18HeadroomNP.integrity,
                    LibOpDecimal18InvNP.integrity,
                    LibOpDecimal18LnNP.integrity,
                    LibOpDecimal18Log10NP.integrity,
                    LibOpDecimal18Log2NP.integrity,
                    LibOpDecimal18MulNP.integrity,
                    LibOpDecimal18PowNP.integrity,
                    LibOpDecimal18PowUNP.integrity,
                    LibOpDecimal18Scale18DynamicNP.integrity,
                    LibOpDecimal18Scale18NP.integrity,
                    // Int to decimal18 is a repeat of decimal18 scale18.
                    LibOpDecimal18Scale18NP.integrity,
                    LibOpDecimal18ScaleNDynamicNP.integrity,
                    LibOpDecimal18ScaleNNP.integrity,
                    // Decimal18 to int is a repeat of decimal18 scaleN.
                    LibOpDecimal18ScaleNNP.integrity,
                    LibOpDecimal18SnapToUnitNP.integrity,
                    LibOpDecimal18SqrtNP.integrity,
                    // int and decimal18 add have identical implementations and
                    // point to the same function pointer. This is intentional.
                    LibOpIntAddNP.integrity,
                    // decimal18 add.
                    LibOpIntAddNP.integrity,
                    LibOpIntDivNP.integrity,
                    LibOpIntExpNP.integrity,
                    // int and decimal18 max have identical implementations and
                    // point to the same function pointer. This is intentional.
                    LibOpIntMaxNP.integrity,
                    // decimal18 max.
                    LibOpIntMaxNP.integrity,
                    // int and decimal18 min have identical implementations and
                    // point to the same function pointer. This is intentional.
                    LibOpIntMinNP.integrity,
                    // decimal18 min.
                    LibOpIntMinNP.integrity,
                    LibOpIntModNP.integrity,
                    LibOpIntMulNP.integrity,
                    // int and decimal18 sub have identical implementations and
                    // point to the same function pointer. This is intentional.
                    LibOpIntSubNP.integrity,
                    // int saturating sub.
                    LibOpIntSubNP.integrity,
                    // decimal18 sub.
                    LibOpIntSubNP.integrity,
                    // decimal18 saturating sub.
                    LibOpIntSubNP.integrity,
                    LibOpGetNP.integrity,
                    LibOpSetNP.integrity
                ];
            uint256[] memory pointersDynamic;
            assembly ("memory-safe") {
                pointersDynamic := pointersFixed
            }
            // Sanity check that the dynamic length is correct. Should be an
            // unreachable error.
            if (pointersDynamic.length != ALL_STANDARD_OPS_LENGTH) {
                revert BadDynamicLength(pointersDynamic.length, length);
            }
            return LibConvert.unsafeTo16BitBytes(pointersDynamic);
        }
    }

    /// All function pointers for the standard opcodes. Intended to be used to
    /// build a `IInterpreterV2` instance, specifically the `functionPointers`
    /// method can just be a thin wrapper around this function.
    function opcodeFunctionPointers() internal pure returns (bytes memory) {
        unchecked {
            function(InterpreterStateNP memory, Operand, Pointer)
                view
                returns (Pointer) lengthPointer;
            uint256 length = ALL_STANDARD_OPS_LENGTH;
            assembly ("memory-safe") {
                lengthPointer := length
            }
            function(InterpreterStateNP memory, Operand, Pointer)
                view
                returns (Pointer)[ALL_STANDARD_OPS_LENGTH + 1] memory pointersFixed = [
                    lengthPointer,
                    // The first ops are out of lexical ordering so that they
                    // can sit at stable well known indexes.
                    LibOpStackNP.run,
                    LibOpConstantNP.run,
                    LibOpExternNP.run,
                    LibOpContextNP.run,
                    // Everything else is alphabetical, including folders.
                    LibOpBitwiseAndNP.run,
                    LibOpBitwiseOrNP.run,
                    LibOpCtPopNP.run,
                    LibOpDecodeBitsNP.run,
                    LibOpEncodeBitsNP.run,
                    LibOpShiftBitsLeftNP.run,
                    LibOpShiftBitsRightNP.run,
                    LibOpCallNP.run,
                    LibOpHashNP.run,
                    LibOpERC20AllowanceNP.run,
                    LibOpERC20BalanceOfNP.run,
                    LibOpERC20TotalSupplyNP.run,
                    LibOpERC721BalanceOfNP.run,
                    LibOpERC721OwnerOfNP.run,
                    LibOpERC5313OwnerNP.run,
                    LibOpBlockNumberNP.run,
                    LibOpChainIdNP.run,
                    // int and decimal18 max have identical implementations and
                    // point to the same function pointer. This is intentional.
                    LibOpMaxUint256NP.run,
                    // decimal18 max.
                    LibOpMaxUint256NP.run,
                    LibOpTimestampNP.run,
                    LibOpAnyNP.run,
                    LibOpConditionsNP.run,
                    LibOpEnsureNP.run,
                    LibOpEqualToNP.run,
                    LibOpEveryNP.run,
                    LibOpGreaterThanNP.run,
                    LibOpGreaterThanOrEqualToNP.run,
                    LibOpIfNP.run,
                    LibOpIsZeroNP.run,
                    LibOpLessThanNP.run,
                    LibOpLessThanOrEqualToNP.run,
                    LibOpDecimal18ExponentialGrowthNP.run,
                    LibOpDecimal18LinearGrowthNP.run,
                    LibOpDecimal18AvgNP.run,
                    LibOpDecimal18CeilNP.run,
                    LibOpDecimal18DivNP.run,
                    LibOpDecimal18ExpNP.run,
                    LibOpDecimal18Exp2NP.run,
                    LibOpDecimal18FloorNP.run,
                    LibOpDecimal18FracNP.run,
                    LibOpDecimal18GmNP.run,
                    LibOpDecimal18HeadroomNP.run,
                    LibOpDecimal18InvNP.run,
                    LibOpDecimal18LnNP.run,
                    LibOpDecimal18Log10NP.run,
                    LibOpDecimal18Log2NP.run,
                    LibOpDecimal18MulNP.run,
                    LibOpDecimal18PowNP.run,
                    LibOpDecimal18PowUNP.run,
                    LibOpDecimal18Scale18DynamicNP.run,
                    LibOpDecimal18Scale18NP.run,
                    // Int to decimal18 is a repeat of decimal18 scale18.
                    LibOpDecimal18Scale18NP.run,
                    LibOpDecimal18ScaleNDynamicNP.run,
                    LibOpDecimal18ScaleNNP.run,
                    // Decimal18 to int is a repeat of decimal18 scaleN.
                    LibOpDecimal18ScaleNNP.run,
                    LibOpDecimal18SnapToUnitNP.run,
                    LibOpDecimal18SqrtNP.run,
                    // int and decimal18 add have identical implementations and
                    // point to the same function pointer. This is intentional.
                    LibOpIntAddNP.run,
                    // decimal18 add.
                    LibOpIntAddNP.run,
                    LibOpIntDivNP.run,
                    LibOpIntExpNP.run,
                    // int and decimal18 max have identical implementations and
                    // point to the same function pointer. This is intentional.
                    LibOpIntMaxNP.run,
                    // decimal18 max.
                    LibOpIntMaxNP.run,
                    // int and decimal18 min have identical implementations and
                    // point to the same function pointer. This is intentional.
                    LibOpIntMinNP.run,
                    // decimal18 min.
                    LibOpIntMinNP.run,
                    LibOpIntModNP.run,
                    LibOpIntMulNP.run,
                    // int and decimal18 sub have identical implementations and
                    // point to the same function pointer. This is intentional.
                    LibOpIntSubNP.run,
                    // int saturating sub.
                    LibOpIntSubNP.run,
                    // decimal18 sub.
                    LibOpIntSubNP.run,
                    // decimal18 saturating sub.
                    LibOpIntSubNP.run,
                    LibOpGetNP.run,
                    LibOpSetNP.run
                ];
            uint256[] memory pointersDynamic;
            assembly ("memory-safe") {
                pointersDynamic := pointersFixed
            }
            // Sanity check that the dynamic length is correct. Should be an
            // unreachable error.
            if (pointersDynamic.length != ALL_STANDARD_OPS_LENGTH) {
                revert BadDynamicLength(pointersDynamic.length, length);
            }
            return LibConvert.unsafeTo16BitBytes(pointersDynamic);
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {LibPointer, Pointer} from "rain.solmem/lib/LibPointer.sol";
import {LibMemCpy} from "rain.solmem/lib/LibMemCpy.sol";
import {
    CMASK_COMMENT_HEAD,
    CMASK_EOS,
    CMASK_EOL,
    CMASK_LITERAL_HEAD,
    CMASK_WHITESPACE,
    CMASK_RIGHT_PAREN,
    CMASK_LEFT_PAREN,
    CMASK_RHS_WORD_TAIL,
    CMASK_RHS_WORD_HEAD,
    CMASK_LHS_RHS_DELIMITER,
    CMASK_LHS_STACK_TAIL,
    CMASK_LHS_STACK_HEAD,
    COMMENT_START_SEQUENCE,
    COMMENT_END_SEQUENCE,
    CMASK_IDENTIFIER_HEAD
} from "./LibParseCMask.sol";
import {LibCtPop} from "../bitwise/LibCtPop.sol";
import {LibParseMeta} from "./LibParseMeta.sol";
import {LibParseLiteral} from "./literal/LibParseLiteral.sol";
import {LibParseOperand} from "./LibParseOperand.sol";
import {Operand, OPCODE_STACK, OPCODE_UNKNOWN} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {LibParseStackName} from "./LibParseStackName.sol";
import {
    ExcessLHSItems,
    ExcessRHSItems,
    NotAcceptingInputs,
    ParseStackUnderflow,
    ParseStackOverflow,
    UnexpectedRHSChar,
    UnexpectedRightParen,
    WordSize,
    DuplicateLHSItem,
    ParserOutOfBounds,
    ExpectedLeftParen,
    UnexpectedLHSChar,
    DanglingSource,
    MaxSources,
    UnclosedLeftParen,
    MissingFinalSemi,
    UnexpectedComment,
    ParenOverflow,
    UnknownWord,
    MalformedCommentStart
} from "../../error/ErrParse.sol";
import {
    LibParseState,
    ParseState,
    FSM_YANG_MASK,
    FSM_DEFAULT,
    FSM_ACTIVE_SOURCE_MASK,
    FSM_WORD_END_MASK
} from "./LibParseState.sol";
import {LibParsePragma} from "./LibParsePragma.sol";
import {LibParseInterstitial} from "./LibParseInterstitial.sol";
import {LibParseError} from "./LibParseError.sol";
import {LibSubParse} from "./LibSubParse.sol";
import {LibBytes} from "rain.solmem/lib/LibBytes.sol";
import {LibUint256Array} from "rain.solmem/lib/LibUint256Array.sol";

uint256 constant NOT_LOW_16_BIT_MASK = ~uint256(0xFFFF);
uint256 constant ACTIVE_SOURCE_MASK = NOT_LOW_16_BIT_MASK;
uint256 constant SUB_PARSER_BYTECODE_HEADER_SIZE = 5;

library LibParse {
    using LibPointer for Pointer;
    using LibParseStackName for ParseState;
    using LibParseState for ParseState;
    using LibParseInterstitial for ParseState;
    using LibParseError for ParseState;
    using LibParseMeta for ParseState;
    using LibParsePragma for ParseState;
    using LibParse for ParseState;
    using LibParseOperand for ParseState;
    using LibSubParse for ParseState;
    using LibBytes for bytes;
    using LibUint256Array for uint256[];

    /// Parses a word that matches a tail mask between cursor and end. The caller
    /// has several responsibilities while safely using this word.
    /// - The caller MUST ensure that the word is not zero length.
    ///   I.e. `end - cursor > 0`.
    /// - The caller MUST ensure the head of the word (the first character) is
    ///   valid according to some head mask. Generally it is expected that the
    ///   valid chars for a head and tail may be different.
    /// This function will extract every other character from the word, starting
    /// with the second character, and check that it is valid according to the
    /// tail mask. If any invalid characters are found, the parsing will stop
    /// looping as it is assumed the remaining data is valid as something else,
    /// just not a word.
    function parseWord(uint256 cursor, uint256 end, uint256 mask) internal pure returns (uint256, bytes32) {
        unchecked {
            bytes32 word;
            uint256 i = 1;
            uint256 iEnd;
            {
                uint256 remaining = end - cursor;
                iEnd = remaining > 0x20 ? 0x20 : remaining;
            }
            assembly ("memory-safe") {
                // word is head + tail
                word := mload(cursor)
                // loop over the tail
                //slither-disable-next-line incorrect-shift
                for {} and(lt(i, iEnd), iszero(and(shl(byte(i, word), 1), not(mask)))) { i := add(i, 1) } {}

                // zero out the rightmost part of the mload that is not the word.
                let scrub := mul(sub(0x20, i), 8)
                word := shl(scrub, shr(scrub, word))
                cursor := add(cursor, i)
            }
            if (i == 0x20) {
                revert WordSize(string(abi.encodePacked(word)));
            }
            return (cursor, word);
        }
    }

    /// Skip an unlimited number of chars until we find one that is not in the
    /// mask.
    function skipMask(uint256 cursor, uint256 end, uint256 mask) internal pure returns (uint256) {
        assembly ("memory-safe") {
            //slither-disable-next-line incorrect-shift
            for {} and(lt(cursor, end), gt(and(shl(byte(0, mload(cursor)), 1), mask), 0)) { cursor := add(cursor, 1) } {}
        }
        return cursor;
    }

    function parseLHS(ParseState memory state, uint256 cursor, uint256 end) internal pure returns (uint256) {
        unchecked {
            while (cursor < end) {
                bytes32 word;
                uint256 char;
                assembly ("memory-safe") {
                    //slither-disable-next-line incorrect-shift
                    char := shl(byte(0, mload(cursor)), 1)
                }

                if (char & CMASK_LHS_STACK_HEAD > 0) {
                    // if yang we can't start new stack item
                    if (state.fsm & FSM_YANG_MASK > 0) {
                        revert UnexpectedLHSChar(state.parseErrorOffset(cursor));
                    }

                    // Named stack item.
                    if (char & CMASK_IDENTIFIER_HEAD > 0) {
                        (cursor, word) = parseWord(cursor, end, CMASK_LHS_STACK_TAIL);
                        (bool exists, uint256 index) = state.pushStackName(word);
                        (index);
                        // If the stack name already exists, then we
                        // revert as shadowing is not allowed.
                        if (exists) {
                            revert DuplicateLHSItem(state.parseErrorOffset(cursor));
                        }
                    }
                    // Anon stack item.
                    else {
                        cursor = skipMask(cursor + 1, end, CMASK_LHS_STACK_TAIL);
                    }
                    // Bump the index regardless of whether the stack
                    // item is named or not.
                    state.topLevel1++;
                    state.lineTracker++;

                    // Set yang as we are now building a stack item.
                    state.fsm |= FSM_YANG_MASK | FSM_ACTIVE_SOURCE_MASK;
                } else if (char & CMASK_WHITESPACE != 0) {
                    cursor = skipMask(cursor + 1, end, CMASK_WHITESPACE);
                    // Set ying as we now open to possibilities.
                    state.fsm &= ~FSM_YANG_MASK;
                } else if (char & CMASK_LHS_RHS_DELIMITER != 0) {
                    // Set RHS and yin.
                    state.fsm = (state.fsm | FSM_ACTIVE_SOURCE_MASK) & ~FSM_YANG_MASK;
                    cursor++;
                    break;
                } else {
                    if (char & CMASK_COMMENT_HEAD != 0) {
                        revert UnexpectedComment(state.parseErrorOffset(cursor));
                    } else {
                        revert UnexpectedLHSChar(state.parseErrorOffset(cursor));
                    }
                }
            }
            return cursor;
        }
    }

    //slither-disable-next-line cyclomatic-complexity
    function parseRHS(ParseState memory state, uint256 cursor, uint256 end) internal pure returns (uint256) {
        unchecked {
            while (cursor < end) {
                bytes32 word;
                uint256 char;
                assembly ("memory-safe") {
                    //slither-disable-next-line incorrect-shift
                    char := shl(byte(0, mload(cursor)), 1)
                }

                if (char & CMASK_RHS_WORD_HEAD > 0) {
                    // If yang we can't start a new word.
                    if (state.fsm & FSM_YANG_MASK > 0) {
                        revert UnexpectedRHSChar(state.parseErrorOffset(cursor));
                    }

                    // If the word is unknown we need the cursor at the start
                    // so that we can copy it into the subparser bytecode.
                    uint256 cursorForUnknownWord = cursor;
                    (cursor, word) = parseWord(cursor, end, CMASK_RHS_WORD_TAIL);

                    // First check if this word is in meta.
                    (bool exists, uint256 opcodeIndex) = state.lookupWord(word);
                    if (exists) {
                        cursor = state.parseOperand(cursor, end);
                        Operand operand = state.handleOperand(opcodeIndex);
                        state.pushOpToSource(opcodeIndex, operand);
                        // This is a real word so we expect to see parens
                        // after it.
                        state.fsm |= FSM_WORD_END_MASK;
                    }
                    // Fallback to LHS items.
                    else {
                        (exists, opcodeIndex) = state.stackNameIndex(word);
                        if (exists) {
                            state.pushOpToSource(OPCODE_STACK, Operand.wrap(opcodeIndex));
                            // Need to process highwater here because we
                            // don't have any parens to open or close.
                            state.highwater();
                        }
                        // Fallback to sub parsing.
                        else {
                            Operand operand;
                            bytes memory subParserBytecode;

                            {
                                // Need to capture the word length up here before
                                // we move the cursor past the operand that might
                                // exist.
                                uint256 wordLength = cursor - cursorForUnknownWord;
                                uint256 subParserBytecodeLength = SUB_PARSER_BYTECODE_HEADER_SIZE + wordLength;
                                // We store the final parsed values in the sub parser
                                // bytecode so they can be handled as operand values,
                                // rather than needing to be parsed as literals.
                                // We have to move the cursor to keep the main parser
                                // moving, but the sub parser bytecode will be
                                // populated with the values in the state array.
                                cursor = state.parseOperand(cursor, end);
                                // The operand values length is only known after
                                // parsing the operand.
                                subParserBytecodeLength += state.operandValues.length * 0x20 + 0x20;

                                // Build the bytecode that we will be sending to the
                                // subparser. We can't yet build the byte header but
                                // we can allocate the memory for it and move the string
                                // tail and operand values into place.
                                uint256 subParserBytecodeBytesLengthOffset = SUB_PARSER_BYTECODE_HEADER_SIZE;
                                assembly ("memory-safe") {
                                    subParserBytecode := mload(0x40)
                                    // Move allocated memory past the bytes and their
                                    // length. This is NOT an aligned allocation.
                                    mstore(0x40, add(subParserBytecode, add(subParserBytecodeLength, 0x20)))
                                    // Need to record the length of the unparsed
                                    // bytes or the structure will be ambiguous to
                                    // the sub parser.
                                    mstore(add(subParserBytecode, subParserBytecodeBytesLengthOffset), wordLength)
                                    mstore(subParserBytecode, subParserBytecodeLength)
                                    // The operand of an unknown word is a pointer to
                                    // the bytecode that needs to be sub parsed.
                                    operand := subParserBytecode
                                }
                                // Copy the unknown word into the subparser bytecode
                                // after the header bytes.
                                LibMemCpy.unsafeCopyBytesTo(
                                    Pointer.wrap(cursorForUnknownWord),
                                    Pointer.wrap(
                                        Pointer.unwrap(subParserBytecode.dataPointer())
                                            + SUB_PARSER_BYTECODE_HEADER_SIZE
                                    ),
                                    wordLength
                                );
                            }
                            // Copy the operand values into place for sub
                            // parsing.
                            {
                                uint256 wordsToCopy = state.operandValues.length + 1;
                                LibMemCpy.unsafeCopyWordsTo(
                                    state.operandValues.startPointer(),
                                    subParserBytecode.endDataPointer().unsafeSubWords(wordsToCopy),
                                    wordsToCopy
                                );
                            }

                            state.pushOpToSource(OPCODE_UNKNOWN, operand);
                            // We only support words with parens for unknown words
                            // that are sent off to the sub parsers.
                            state.fsm |= FSM_WORD_END_MASK;
                        }
                    }

                    state.fsm |= FSM_YANG_MASK;
                }
                // If this is the end of a word we MUST start a paren.
                else if (state.fsm & FSM_WORD_END_MASK > 0) {
                    if (char & CMASK_LEFT_PAREN == 0) {
                        revert ExpectedLeftParen(state.parseErrorOffset(cursor));
                    }
                    // Increase the paren depth by 1.
                    // i.e. move the byte offset by 3
                    // There MAY be garbage at this new offset due to
                    // a previous paren group being deallocated. The
                    // deallocation process writes the input counter
                    // to zero but leaves a garbage word in place, with
                    // the expectation that it will be overwritten by
                    // the next paren group.
                    uint256 newParenOffset;
                    assembly ("memory-safe") {
                        newParenOffset := add(byte(0, mload(add(state, 0x60))), 3)
                        mstore8(add(state, 0x60), newParenOffset)
                    }
                    // first 2 bytes are reserved, then remaining 62
                    // bytes are for paren groups, so the offset MUST NOT
                    // imply writing to the 63rd byte.
                    if (newParenOffset > 59) {
                        revert ParenOverflow();
                    }
                    cursor++;

                    // We've moved past the paren, so we are no longer at
                    // the end of a word and are yin.
                    state.fsm &= ~(FSM_WORD_END_MASK | FSM_YANG_MASK);
                } else if (char & CMASK_RIGHT_PAREN > 0) {
                    uint256 parenOffset;
                    assembly ("memory-safe") {
                        parenOffset := byte(0, mload(add(state, 0x60)))
                    }
                    if (parenOffset == 0) {
                        revert UnexpectedRightParen(state.parseErrorOffset(cursor));
                    }
                    // Decrease the paren depth by 1.
                    // i.e. move the byte offset by -3.
                    // This effectively deallocates the paren group, so
                    // write the input counter out to the operand pointed
                    // to by the pointer we deallocated.
                    assembly ("memory-safe") {
                        // State field offset.
                        let stateOffset := add(state, 0x60)
                        parenOffset := sub(parenOffset, 3)
                        mstore8(stateOffset, parenOffset)
                        mstore8(
                            // Add 2 for the reserved bytes to the offset
                            // then read top 16 bits from the pointer.
                            // Add 1 to sandwitch the inputs byte between
                            // the opcode index byte and the operand low
                            // bytes.
                            add(1, shr(0xf0, mload(add(add(stateOffset, 2), parenOffset)))),
                            // Store the input counter, which is 2 bytes
                            // after the operand write pointer.
                            byte(0, mload(add(add(stateOffset, 4), parenOffset)))
                        )
                    }
                    state.highwater();
                    cursor++;
                } else if (char & CMASK_WHITESPACE > 0) {
                    cursor = skipMask(cursor + 1, end, CMASK_WHITESPACE);
                    // Set yin as we now open to possibilities.
                    state.fsm &= ~FSM_YANG_MASK;
                }
                // Handle all literals.
                else if (char & CMASK_LITERAL_HEAD > 0) {
                    cursor = state.pushLiteral(cursor, end);
                    state.highwater();
                    // We are yang now. Need the next char to release to
                    // yin.
                    state.fsm |= FSM_YANG_MASK;
                } else if (char & CMASK_EOL > 0) {
                    state.endLine(cursor);
                    cursor++;
                    break;
                }
                // End of source.
                else if (char & CMASK_EOS > 0) {
                    state.endLine(cursor);
                    state.endSource();
                    cursor++;

                    state.fsm = FSM_DEFAULT;
                    break;
                }
                // Comments aren't allowed in the RHS but we can give a
                // nicer error message than the default.
                else if (char & CMASK_COMMENT_HEAD != 0) {
                    revert UnexpectedComment(state.parseErrorOffset(cursor));
                } else {
                    revert UnexpectedRHSChar(state.parseErrorOffset(cursor));
                }
            }
            return cursor;
        }
    }

    function parse(ParseState memory state) internal pure returns (bytes memory bytecode, uint256[] memory) {
        unchecked {
            if (state.data.length > 0) {
                uint256 cursor;
                uint256 end;
                {
                    bytes memory data = state.data;
                    assembly ("memory-safe") {
                        cursor := add(data, 0x20)
                        end := add(cursor, mload(data))
                    }
                }
                cursor = state.parseInterstitial(cursor, end);
                cursor = state.parsePragma(cursor, end);
                while (cursor < end) {
                    cursor = state.parseInterstitial(cursor, end);
                    cursor = state.parseLHS(cursor, end);
                    cursor = state.parseRHS(cursor, end);
                }
                if (cursor != end) {
                    revert ParserOutOfBounds();
                }
                if (state.fsm & FSM_ACTIVE_SOURCE_MASK != 0) {
                    revert MissingFinalSemi(state.parseErrorOffset(cursor));
                }
            }
            //slither-disable-next-line unused-return
            return state.subParseWords(state.buildBytecode());
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {ERC165} from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {LibPointer, Pointer} from "rain.solmem/lib/LibPointer.sol";
import {LibStackPointer} from "rain.solmem/lib/LibStackPointer.sol";
import {LibUint256Array} from "rain.solmem/lib/LibUint256Array.sol";
import {LibMemoryKV, MemoryKV} from "rain.lib.memkv/lib/LibMemoryKV.sol";
import {LibCast} from "rain.lib.typecast/LibCast.sol";
import {LibDataContract} from "rain.datacontract/lib/LibDataContract.sol";

import {LibEvalNP} from "../lib/eval/LibEvalNP.sol";
import {LibInterpreterStateDataContractNP} from "../lib/state/LibInterpreterStateDataContractNP.sol";
import {LibEncodedDispatch} from "rain.interpreter.interface/lib/caller/LibEncodedDispatch.sol";
import {InterpreterStateNP} from "../lib/state/LibInterpreterStateNP.sol";
import {LibAllStandardOpsNP} from "../lib/op/LibAllStandardOpsNP.sol";
import {
    SourceIndexV2,
    IInterpreterV2,
    StateNamespace,
    EncodedDispatch,
    FullyQualifiedNamespace,
    IInterpreterStoreV2
} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {IInterpreterV3} from "rain.interpreter.interface/interface/unstable/IInterpreterV3.sol";

/// @dev Hash of the known interpreter bytecode.
bytes32 constant INTERPRETER_BYTECODE_HASH = bytes32(0xa1800a933bfbd35dc240c332da3c4770f290260673872fb013e86c8478b12fd7);

/// @dev The function pointers known to the interpreter for dynamic dispatch.
/// By setting these as a constant they can be inlined into the interpreter
/// and loaded at eval time for very low gas (~100) due to the compiler
/// optimising it to a single `codecopy` to build the in memory bytes array.
bytes constant OPCODE_FUNCTION_POINTERS =
    hex"0df30e440e8610521139114b115d117611b8120a121b122c12ce130b13c9147913c914fd159f161716461675167516c416f31758182c187f189318ec19001915192f193a194e1963199b19c219da19e81a681a761a841a9f1ab41acc1ae51af31b011b0f1b1d1b6b1b831b9b1bb51bb51bcc1be91be91c001c551c631c631cb11cff1d4d1d4d1d9b1d9b1de91e371e851e851e851e851f292010";

/// @title RainterpreterNPE2
/// @notice Implementation of a Rainlang interpreter that is compatible with
/// native onchain Rainlang parsing.
contract RainterpreterNPE2 is IInterpreterV2, IInterpreterV3, ERC165 {
    using LibEvalNP for InterpreterStateNP;
    using LibInterpreterStateDataContractNP for bytes;

    /// There are MANY ways that eval can be forced into undefined/corrupt
    /// behaviour by passing in invalid data. This is a deliberate design
    /// decision to allow for the interpreter to be as gas efficient as
    /// possible. The interpreter is provably read only, it contains no state
    /// changing evm opcodes reachable on any logic path. This means that
    /// the caller can only harm themselves by passing in invalid data and
    /// either reverting, exhausting gas or getting back some garbage data.
    /// The caller can trivially protect themselves from these OOB issues by
    /// ensuring the integrity check has successfully run over the bytecode
    /// before calling eval. Any smart contract caller can do this by using a
    /// trusted and appropriate deployer contract to deploy the bytecode, which
    /// will automatically run the integrity check during deployment, then
    /// keeping a registry of trusted expression addresses for itself in storage.
    ///
    /// This appears first in the contract in the hope that the compiler will
    /// put it in the most efficient internal dispatch location to save a few
    /// gas per eval call.
    ///
    /// @inheritdoc IInterpreterV2
    function eval2(
        IInterpreterStoreV2 store,
        FullyQualifiedNamespace namespace,
        EncodedDispatch dispatch,
        uint256[][] memory context,
        uint256[] memory inputs
    ) external view virtual returns (uint256[] memory, uint256[] memory) {
        // Decode the dispatch.
        (address expression, SourceIndexV2 sourceIndex, uint256 maxOutputs) = LibEncodedDispatch.decode2(dispatch);
        bytes memory expressionData = LibDataContract.read(expression);

        InterpreterStateNP memory state = expressionData.unsafeDeserializeNP(
            SourceIndexV2.unwrap(sourceIndex), namespace, store, context, OPCODE_FUNCTION_POINTERS
        );
        // We use the return by returning it. Slither false positive.
        //slither-disable-next-line unused-return
        return state.eval2(inputs, maxOutputs);
    }

    /// @inheritdoc IInterpreterV3
    function eval3(
        IInterpreterStoreV2 store,
        FullyQualifiedNamespace namespace,
        bytes calldata bytecode,
        SourceIndexV2 sourceIndex,
        uint256[][] calldata context,
        uint256[] calldata inputs
    ) external view virtual override returns (uint256[] memory, uint256[] memory) {
        InterpreterStateNP memory state = bytecode.unsafeDeserializeNP(
            SourceIndexV2.unwrap(sourceIndex), namespace, store, context, OPCODE_FUNCTION_POINTERS
        );
        // We use the return by returning it. Slither false positive.
        //slither-disable-next-line unused-return
        return state.eval2(inputs, type(uint256).max);
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IInterpreterV2).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IInterpreterV2
    function functionPointers() external view virtual override(IInterpreterV2, IInterpreterV3) returns (bytes memory) {
        return LibAllStandardOpsNP.opcodeFunctionPointers();
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {IERC165, ERC165} from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

import {LibParse} from "../lib/parse/LibParse.sol";
import {IParserV1} from "rain.interpreter.interface/interface/IParserV1.sol";
import {LibParseState, ParseState} from "../lib/parse/LibParseState.sol";
import {LibParseLiteral} from "../lib/parse/literal/LibParseLiteral.sol";
import {LibAllStandardOpsNP} from "../lib/op/LibAllStandardOpsNP.sol";

/// @dev The known hash of the parser bytecode. This is used by the deployer to
/// check that it is deploying a parser that is compatible with the interpreter.
bytes32 constant PARSER_BYTECODE_HASH = bytes32(0xb1d7ca190b7226f62fac331b3ddad377132529d8005d2c52a5285af484823b49);

/// @dev Encodes the parser meta that is used to lookup word definitions.
/// The structure of the parser meta is:
/// - 1 byte: The depth of the bloom filters
/// - 1 byte: The hashing seed
/// - The bloom filters, each is 32 bytes long, one for each build depth.
/// - All the items for each word, each is 4 bytes long. Each item's first byte
///   is its opcode index, the remaining 3 bytes are the word fingerprint.
/// To do a lookup, the word is hashed with the seed, then the first byte of the
/// hash is compared against the bloom filter. If there is a hit then we count
/// the number of 1 bits in the bloom filter up to this item's 1 bit. We then
/// treat this a the index of the item in the items array. We then compare the
/// word fingerprint against the fingerprint of the item at this index. If the
/// fingerprints equal then we have a match, else we increment the seed and try
/// again with the next bloom filter, offsetting all the indexes by the total
/// bit count of the previous bloom filter. If we reach the end of the bloom
/// filters then we have a miss.
bytes constant PARSE_META =
    hex"02588423482a0a64a4805a093a0046408a2000483db0020941044cd10693108128940000000000000000000800000000100000000000000000100000000000000000001f49c6a348b005fd0c1dc53744b46c3a1a6b5d512cc697651ba56d9d416380a84768119145bf1f411c9320384025b20727767586017788743d54ad3411facaed0bf793d92a5dd6b80ac51f7f13de413210b7896422844b300fd8f7982b7c1ad31611585907980f123846207d420085742d567a1d4ab12847126e57172f75b953212a4b6e332c3f7f31f3a7222e87d7c63e201236435fbbfc32e281ae25b491eb3f7af18839b31297302973c128b94d704b1ec042237d449e18a0265d3c2223f20482963a035436e60205c2140075eca1152558bb061fa22149a5e8dd144329870d6598183bbd10093462c9701ee60c073664e22009880be535267cb3269879ba1d7d424b4654aa05197e9c533ae38ebd372dd7b205e7bf522908ea4b202f3f5e0e52726c08783df917448fdb248cf8244c9232f7";

/// @dev The build depth of the parser meta.
uint8 constant PARSE_META_BUILD_DEPTH = 2;

/// @dev Every two bytes is a function pointer for an operand handler. These
/// positional indexes all map to the same indexes looked up in the parse meta.
bytes constant OPERAND_HANDLER_FUNCTION_POINTERS =
    hex"10f410f410f41189122a122a122a1189118910f410f410f4122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a122a126f1303122a126f1303122a122a122a122a122a122a122a122a122a122a122a122a122a10f413f910f413f9122a122a";

/// @dev Every two bytes is a function pointer for a literal parser. Literal
/// dispatches are determined by the first byte(s) of the literal rather than a
/// full word lookup, and are done with simple conditional jumps as the
/// possibilities are limited compared to the number of words we have.
bytes constant LITERAL_PARSER_FUNCTION_POINTERS = hex"08860b4e0e4b0f03";

/// @title RainterpreterParserNPE2
/// @dev The parser implementation.
contract RainterpreterParserNPE2 is IParserV1, ERC165 {
    using LibParse for ParseState;

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IParserV1).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IParserV1
    function parse(bytes memory data) external pure virtual override returns (bytes memory, uint256[] memory) {
        // The return is used by returning it, so this is a false positive.
        //slither-disable-next-line unused-return
        return LibParseState.newState(
            data, parseMeta(), operandHandlerFunctionPointers(), literalParserFunctionPointers()
        ).parse();
    }

    /// Virtual function to return the parse meta.
    function parseMeta() internal pure virtual returns (bytes memory) {
        return PARSE_META;
    }

    /// Virtual function to return the operand handler function pointers.
    function operandHandlerFunctionPointers() internal pure virtual returns (bytes memory) {
        return OPERAND_HANDLER_FUNCTION_POINTERS;
    }

    /// Virtual function to return the literal parser function pointers.
    function literalParserFunctionPointers() internal pure virtual returns (bytes memory) {
        return LITERAL_PARSER_FUNCTION_POINTERS;
    }

    /// External function to build the operand handler function pointers.
    function buildOperandHandlerFunctionPointers() external pure returns (bytes memory) {
        return LibAllStandardOpsNP.operandHandlerFunctionPointers();
    }

    /// External function to build the literal parser function pointers.
    function buildLiteralParserFunctionPointers() external pure returns (bytes memory) {
        return LibAllStandardOpsNP.literalParserFunctionPointers();
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

import "rain.interpreter.interface/interface/IInterpreterStoreV2.sol";
import "rain.interpreter.interface/lib/ns/LibNamespace.sol";

/// Thrown when a `set` call is made with an odd number of arguments.
error OddSetLength(uint256 length);

/// @dev Hash of the known store bytecode.
bytes32 constant STORE_BYTECODE_HASH = bytes32(0x2a4559222e2f3600b2d393715de8af57620439684463f745059c653bbfe3727f);

/// @title RainterpreterStore
/// @notice Simplest possible `IInterpreterStoreV2` that could work.
/// Takes key/value pairings from the input array and stores each in an internal
/// mapping. `StateNamespace` is fully qualified only by `msg.sender` on set and
/// doesn't attempt to do any deduping etc. if the same key appears twice it will
/// be set twice.
contract RainterpreterStoreNPE2 is IInterpreterStoreV2, ERC165 {
    using LibNamespace for StateNamespace;

    /// Store is several tiers of sandbox.
    ///
    /// 0. Address hashed into `FullyQualifiedNamespace` is `msg.sender` so that
    ///    callers cannot attack each other
    /// 1. StateNamespace is caller-provided namespace so that expressions cannot
    ///    attack each other
    /// 2. `uint256` is expression-provided key
    /// 3. `uint256` is expression-provided value
    ///
    /// tiers 0 and 1 are both embodied in the `FullyQualifiedNamespace`.
    // Slither doesn't like the leading underscore.
    //solhint-disable-next-line private-vars-leading-underscore
    mapping(FullyQualifiedNamespace fullyQualifiedNamespace => mapping(uint256 key => uint256 value)) internal sStore;

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IInterpreterStoreV2).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IInterpreterStoreV2
    function set(StateNamespace namespace, uint256[] calldata kvs) external virtual {
        /// This would be picked up by an out of bounds index below, but it's
        /// nice to have a more specific error message.
        if (kvs.length % 2 != 0) {
            revert OddSetLength(kvs.length);
        }
        unchecked {
            FullyQualifiedNamespace fullyQualifiedNamespace = namespace.qualifyNamespace(msg.sender);
            for (uint256 i = 0; i < kvs.length; i += 2) {
                uint256 key = kvs[i];
                uint256 value = kvs[i + 1];
                emit Set(fullyQualifiedNamespace, key, value);
                sStore[fullyQualifiedNamespace][key] = value;
            }
        }
    }

    /// @inheritdoc IInterpreterStoreV2
    function get(FullyQualifiedNamespace namespace, uint256 key) external view virtual returns (uint256) {
        return sStore[namespace][key];
    }
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

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

library LibMemory {
    /// Returns true if the free memory pointer is pointing at a multiple of 32
    /// bytes, false otherwise. If all memory allocations are handled by Solidity
    /// then this will always be true, but assembly blocks can violate this, so
    /// this is a useful tool to test compliance of a custom assembly block with
    /// the solidity allocator.
    /// @return isAligned true if the memory is currently aligned to 32 bytes.
    function memoryIsAligned() internal pure returns (bool isAligned) {
        assembly ("memory-safe") {
            isAligned := iszero(mod(mload(0x40), 0x20))
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./LibPointer.sol";

library LibMemCpy {
    /// Copy an arbitrary number of bytes from one location in memory to another.
    /// As we can only read/write bytes in 32 byte chunks we first have to loop
    /// over 32 byte values to copy then handle any unaligned remaining data. The
    /// remaining data will be appropriately masked with the existing data in the
    /// final chunk so as to not write past the desired length. Note that the
    /// final unaligned write will be more gas intensive than the prior aligned
    /// writes. The writes are completely unsafe, the caller MUST ensure that
    /// sufficient memory is allocated and reading/writing the requested number
    /// of bytes from/to the requested locations WILL NOT corrupt memory in the
    /// opinion of solidity or other subsequent read/write operations.
    /// @param sourceCursor The starting pointer to read from.
    /// @param targetCursor The starting pointer to write to.
    /// @param length The number of bytes to read/write.
    function unsafeCopyBytesTo(Pointer sourceCursor, Pointer targetCursor, uint256 length) internal pure {
        assembly ("memory-safe") {
            // Precalculating the end here, rather than tracking the remaining
            // length each iteration uses relatively more gas for less data, but
            // scales better for more data. Copying 1-2 words is ~30 gas more
            // expensive but copying 3+ words favours a precalculated end point
            // increasingly for more data.
            let m := mod(length, 0x20)
            let end := add(sourceCursor, sub(length, m))
            for {} lt(sourceCursor, end) {
                sourceCursor := add(sourceCursor, 0x20)
                targetCursor := add(targetCursor, 0x20)
            } { mstore(targetCursor, mload(sourceCursor)) }

            if iszero(iszero(m)) {
                //slither-disable-next-line incorrect-shift
                let mask_ := shr(mul(m, 8), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                // preserve existing bytes
                mstore(
                    targetCursor,
                    or(
                        // input
                        and(mload(sourceCursor), not(mask_)),
                        and(mload(targetCursor), mask_)
                    )
                )
            }
        }
    }

    /// Copies `length` `uint256` values starting from `source` to `target`
    /// with NO attempt to check that this is safe to do so. The caller MUST
    /// ensure that there exists allocated memory at `target` in which it is
    /// safe and appropriate to copy `length * 32` bytes to. Anything that was
    /// already written to memory at `[target:target+(length * 32 bytes)]`
    /// will be overwritten.
    /// There is no return value as memory is modified directly.
    /// @param source The starting position in memory that data will be copied
    /// from.
    /// @param target The starting position in memory that data will be copied
    /// to.
    /// @param length The number of 32 byte (i.e. `uint256`) words that will
    /// be copied.
    function unsafeCopyWordsTo(Pointer source, Pointer target, uint256 length) internal pure {
        assembly ("memory-safe") {
            for { let end_ := add(source, mul(0x20, length)) } lt(source, end_) {
                source := add(source, 0x20)
                target := add(target, 0x20)
            } { mstore(target, mload(source)) }
        }
    }
}

// SPDX-License-Identifier: MIT
// Copied from (under MIT license):
// OpenZeppelin Contracts (last updated v4.9.0) (utils/introspection/IERC1820Registry.sol)

/// This was MODIFIED from the original to bump the minimum Solidity version from
/// ^0.8.0 to ^0.8.18, inline with slither recommendations.
pragma solidity ^0.8.18;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(address account, bytes32 _interfaceHash, address implementer) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using or updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// Thrown if a truncated length is longer than the array being truncated. It is
/// not possible to truncate something and increase its length as the memory
/// region after the array MAY be allocated for something else already.
error OutOfBoundsTruncate(uint256 arrayLength, uint256 truncatedLength);

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {IInterpreterStoreV1} from "./IInterpreterStoreV1.sol";

/// @dev The index of a source within a deployed expression that can be evaluated
/// by an `IInterpreterV1`. MAY be an entrypoint or the index of a source called
/// internally such as by the `call` opcode.
type SourceIndex is uint16;

/// @dev Encoded information about a specific evaluation including the expression
/// address onchain, entrypoint and expected return values.
type EncodedDispatch is uint256;

/// @dev The namespace for state changes as requested by the calling contract.
/// The interpreter MUST apply this namespace IN ADDITION to namespacing by
/// caller etc.
type StateNamespace is uint256;

/// @dev Additional bytes that can be used to configure a single opcode dispatch.
/// Commonly used to specify the number of inputs to a variadic function such
/// as addition or multiplication.
type Operand is uint256;

/// @dev The default state namespace MUST be used when a calling contract has no
/// particular opinion on or need for dynamic namespaces.
StateNamespace constant DEFAULT_STATE_NAMESPACE = StateNamespace.wrap(0);

/// @title IInterpreterV1
/// Interface into a standard interpreter that supports:
///
/// - evaluating `view` logic deployed onchain by an `IExpressionDeployerV1`
/// - receiving arbitrary `uint256[][]` supporting context to be made available
///   to the evaluated logic
/// - handling subsequent state changes in bulk in response to evaluated logic
/// - namespacing state changes according to the caller's preferences to avoid
///   unwanted key collisions
/// - exposing its internal function pointers to support external precompilation
///   of logic for more gas efficient runtime evaluation by the interpreter
///
/// The interface is designed to be stable across many versions and
/// implementations of an interpreter, balancing minimalism with features
/// required for a general purpose onchain interpreted compute environment.
///
/// The security model of an interpreter is that it MUST be resilient to
/// malicious expressions even if they dispatch arbitrary internal function
/// pointers during an eval. The interpreter MAY return garbage or exhibit
/// undefined behaviour or error during an eval, _provided that no state changes
/// are persisted_ e.g. in storage, such that only the caller that specifies the
/// malicious expression can be negatively impacted by the result. In turn, the
/// caller must guard itself against arbitrarily corrupt/malicious reverts and
/// return values from any interpreter that it requests an expression from. And
/// so on and so forth up to the externally owned account (EOA) who signs the
/// transaction and agrees to a specific combination of contracts, expressions
/// and interpreters, who can presumably make an informed decision about which
/// ones to trust to get the job done.
///
/// The state changes for an interpreter are expected to be produces by an `eval`
/// and passed to the `IInterpreterStoreV1` returned by the eval, as-is by the
/// caller, after the caller has had an opportunity to apply their own
/// intermediate logic such as reentrancy defenses against malicious
/// interpreters. The interpreter is free to structure the state changes however
/// it wants but MUST guard against the calling contract corrupting the changes
/// between `eval` and `set`. For example a store could sandbox storage writes
/// per-caller so that a malicious caller can only damage their own state
/// changes, while honest callers respect, benefit from and are protected by the
/// interpreter store's state change handling.
///
/// The two step eval-state model allows eval to be read-only which provides
/// security guarantees for the caller such as no stateful reentrancy, either
/// from the interpreter or some contract interface used by some word, while
/// still allowing for storage writes. As the storage writes happen on the
/// interpreter rather than the caller (c.f. delegate call) the caller DOES NOT
/// need to trust the interpreter, which allows for permissionless selection of
/// interpreters by end users. Delegate call always implies an admin key on the
/// caller because the delegatee contract can write arbitrarily to the state of
/// the delegator, which severely limits the generality of contract composition.
interface IInterpreterV1 {
    /// Exposes the function pointers as `uint16` values packed into a single
    /// `bytes` in the same order as they would be indexed into by opcodes. For
    /// example, if opcode `2` should dispatch function at position `0x1234` then
    /// the start of the returned bytes would be `0xXXXXXXXX1234` where `X` is
    /// a placeholder for the function pointers of opcodes `0` and `1`.
    ///
    /// `IExpressionDeployerV1` contracts use these function pointers to
    /// "compile" the expression into something that an interpreter can dispatch
    /// directly without paying gas to lookup the same at runtime. As the
    /// validity of any integrity check and subsequent dispatch is highly
    /// sensitive to both the function pointers and overall bytecode of the
    /// interpreter, `IExpressionDeployerV1` contracts SHOULD implement guards
    /// against accidentally being deployed onchain paired against an unknown
    /// interpreter. It is very easy for an apparent compatible pairing to be
    /// subtly and critically incompatible due to addition/removal/reordering of
    /// opcodes and compiler optimisations on the interpreter bytecode.
    ///
    /// This MAY return different values during construction vs. all other times
    /// after the interpreter has been successfully deployed onchain. DO NOT rely
    /// on function pointers reported during contract construction.
    function functionPointers() external view returns (bytes memory);

    /// The raison d'etre for an interpreter. Given some expression and per-call
    /// additional contextual data, produce a stack of results and a set of state
    /// changes that the caller MAY OPTIONALLY pass back to be persisted by a
    /// call to `IInterpreterStoreV1.set`.
    /// @param store The storage contract that the returned key/value pairs
    /// MUST be passed to IF the calling contract is in a non-static calling
    /// context. Static calling contexts MUST pass `address(0)`.
    /// @param namespace The state namespace that will be fully qualified by the
    /// interpreter at runtime in order to perform gets on the underlying store.
    /// MUST be the same namespace passed to the store by the calling contract
    /// when sending the resulting key/value items to storage.
    /// @param dispatch All the information required for the interpreter to load
    /// an expression, select an entrypoint and return the values expected by the
    /// caller. The interpreter MAY encode dispatches differently to
    /// `LibEncodedDispatch` but this WILL negatively impact compatibility for
    /// calling contracts that hardcode the encoding logic.
    /// @param context A 2-dimensional array of data that can be indexed into at
    /// runtime by the interpreter. The calling contract is responsible for
    /// ensuring the authenticity and completeness of context data. The
    /// interpreter MUST revert at runtime if an expression attempts to index
    /// into some context value that is not provided by the caller. This implies
    /// that context reads cannot be checked for out of bounds reads at deploy
    /// time, as the runtime context MAY be provided in a different shape to what
    /// the expression is expecting.
    /// Same as `eval` but allowing the caller to specify a namespace under which
    /// the state changes will be applied. The interpeter MUST ensure that keys
    /// will never collide across namespaces, even if, for example:
    ///
    /// - The calling contract is malicious and attempts to craft a collision
    ///   with state changes from another contract
    /// - The expression is malicious and attempts to craft a collision with
    ///   other expressions evaluated by the same calling contract
    ///
    /// A malicious entity MAY have access to significant offchain resources to
    /// attempt to precompute key collisions through brute force. The collision
    /// resistance of namespaces should be comparable or equivalent to the
    /// collision resistance of the hashing algorithms employed by the blockchain
    /// itself, such as the design of `mapping` in Solidity that hashes each
    /// nested key to produce a collision resistant compound key.
    /// @return stack The list of values produced by evaluating the expression.
    /// MUST NOT be longer than the maximum length specified by `dispatch`, if
    /// applicable.
    /// @return kvs A list of pairwise key/value items to be saved in the store.
    function eval(
        IInterpreterStoreV1 store,
        StateNamespace namespace,
        EncodedDispatch dispatch,
        uint256[][] calldata context
    ) external view returns (uint256[] memory stack, uint256[] memory kvs);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {StateNamespace} from "./IInterpreterV1.sol";

/// A fully qualified namespace includes the interpreter's own namespacing logic
/// IN ADDITION to the calling contract's requested `StateNamespace`. Typically
/// this involves hashing the `msg.sender` into the `StateNamespace` so that each
/// caller operates within its own disjoint state universe. Intepreters MUST NOT
/// allow either the caller nor any expression/word to modify this directly on
/// pain of potential key collisions on writes to the interpreter's own storage.
type FullyQualifiedNamespace is uint256;

IInterpreterStoreV1 constant NO_STORE = IInterpreterStoreV1(address(0));

/// @title IInterpreterStoreV1
/// @notice Tracks state changes on behalf of an interpreter. A single store can
/// handle state changes for many calling contracts, many interpreters and many
/// expressions. The store is responsible for ensuring that applying these state
/// changes is safe from key collisions with calls to `set` from different
/// `msg.sender` callers. I.e. it MUST NOT be possible for a caller to modify the
/// state changes associated with some other caller.
///
/// The store defines the shape of its own state changes, which is opaque to the
/// calling contract. For example, some store may treat the list of state changes
/// as a pairwise key/value set, and some other store may treat it as a literal
/// list to be stored as-is.
///
/// Each interpreter decides for itself which store to use based on the
/// compatibility of its own opcodes.
///
/// The store MUST assume the state changes have been corrupted by the calling
/// contract due to bugs or malicious intent, and enforce state isolation between
/// callers despite arbitrarily invalid state changes. The store MUST revert if
/// it can detect invalid state changes, such as a key/value list having an odd
/// number of items, but this MAY NOT be possible if the corruption is
/// undetectable.
interface IInterpreterStoreV1 {
    /// Mutates the interpreter store in bulk. The bulk values are provided in
    /// the form of a `uint256[]` which can be treated e.g. as pairwise keys and
    /// values to be stored in a Solidity mapping. The `IInterpreterStoreV1`
    /// defines the meaning of the `uint256[]` for its own storage logic.
    ///
    /// @param namespace The unqualified namespace for the set that MUST be
    /// fully qualified by the `IInterpreterStoreV1` to prevent key collisions
    /// between callers. The fully qualified namespace forms a compound key with
    /// the keys for each value to set.
    /// @param kvs The list of changes to apply to the store's internal state.
    function set(StateNamespace namespace, uint256[] calldata kvs) external;

    /// Given a fully qualified namespace and key, return the associated value.
    /// Ostensibly the interpreter can use this to implement opcodes that read
    /// previously set values. The interpreter MUST apply the same qualification
    /// logic as the store that it uses to guarantee consistent round tripping of
    /// data and prevent malicious behaviours. Technically also allows onchain
    /// reads of any set value from any contract, not just interpreters, but in
    /// this case readers MUST be aware and handle inconsistencies between get
    /// and set while the state changes are still in memory in the calling
    /// context and haven't yet been persisted to the store.
    ///
    /// `IInterpreterStoreV1` uses the same fallback behaviour for unset keys as
    /// Solidity. Specifically, any UNSET VALUES SILENTLY FALLBACK TO `0`.
    /// @param namespace The fully qualified namespace to get a single value for.
    /// @param key The key to get the value for within the namespace.
    /// @return The value OR ZERO IF NOT SET.
    function get(FullyQualifiedNamespace namespace, uint256 key) external view returns (uint256);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

/// @dev There are more entrypoints defined by the minimum stack outputs than
/// there are provided sources. This means the calling contract WILL attempt to
/// eval a dangling reference to a non-existent source at some point, so this
/// MUST REVERT.
error EntrypointMissing(uint256 expectedEntrypoints, uint256 actualEntrypoints);

/// Thrown when some entrypoint has non-zero inputs. This is not allowed as
/// only internal dispatches can have source level inputs.
error EntrypointNonZeroInput(uint256 entrypointIndex, uint256 inputsLength);

/// The bytecode and integrity function disagree on number of inputs.
error BadOpInputsLength(uint256 opIndex, uint256 calculatedInputs, uint256 bytecodeInputs);

/// The bytecode and integrity function disagree on number of outputs.
error BadOpOutputsLength(uint256 opIndex, uint256 calculatedOutputs, uint256 bytecodeOutputs);

/// The stack underflowed during integrity check.
error StackUnderflow(uint256 opIndex, uint256 stackIndex, uint256 calculatedInputs);

/// The stack underflowed the highwater during integrity check.
error StackUnderflowHighwater(uint256 opIndex, uint256 stackIndex, uint256 stackHighwater);

/// The bytecode stack allocation does not match the allocation calculated by
/// the integrity check.
error StackAllocationMismatch(uint256 stackMaxIndex, uint256 bytecodeAllocation);

/// The final stack index does not match the bytecode outputs.
error StackOutputsMismatch(uint256 stackIndex, uint256 bytecodeOutputs);

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {LibPointer, Pointer} from "rain.solmem/lib/LibPointer.sol";
import {LibBytes} from "rain.solmem/lib/LibBytes.sol";
import {LibMemCpy} from "rain.solmem/lib/LibMemCpy.sol";
import {
    StackSizingsNotMonotonic,
    TruncatedSource,
    UnexpectedTrailingOffsetBytes,
    TruncatedHeader,
    TruncatedHeaderOffsets,
    UnexpectedSources,
    SourceIndexOutOfBounds
} from "../../error/ErrBytecode.sol";

/// @title LibBytecode
/// @notice A library for inspecting the bytecode of an expression. Largely
/// focused on reading the source headers rather than the opcodes themselves.
/// Designed to be efficient enough to be used in the interpreter directly.
/// As such, it is not particularly safe, notably it always assumes that the
/// headers are not lying about the structure and runtime behaviour of the
/// bytecode. This is by design as it allows much more simple, efficient and
/// decoupled implementation of authoring/parsing logic, which makes the author
/// of an expression responsible for producing well formed bytecode, such as
/// balanced LHS/RHS stacks. The deployment integrity checks are responsible for
/// checking that the headers match the structure and behaviour of the bytecode.
library LibBytecode {
    using LibPointer for Pointer;
    using LibBytes for bytes;
    using LibMemCpy for Pointer;

    /// The number of sources in the bytecode.
    /// If the bytecode is empty, returns 0.
    /// Otherwise, returns the first byte of the bytecode, which is the number
    /// of sources.
    /// Implies that 0x and 0x00 are equivalent, both having 0 sources. For this
    /// reason, contracts that handle bytecode MUST NOT rely on simple data
    /// length checks to determine if the bytecode is empty or not.
    /// DOES NOT check the integrity or even existence of the sources.
    /// @param bytecode The bytecode to inspect.
    /// @return count The number of sources in the bytecode.
    function sourceCount(bytes memory bytecode) internal pure returns (uint256 count) {
        if (bytecode.length == 0) {
            return 0;
        }
        assembly ("memory-safe") {
            // The first byte of rain bytecode is the count of how many sources
            // there are.
            count := byte(0, mload(add(bytecode, 0x20)))
        }
    }

    /// Checks the structural integrity of the bytecode from the perspective of
    /// potential out of bounds reads. Will revert if the bytecode is not
    /// well-formed. This check MUST be done BEFORE any attempts at per-opcode
    /// integrity checks, as the per-opcode checks assume that the headers define
    /// valid regions in memory to iterate over.
    ///
    /// Checks:
    /// - The offsets are populated according to the source count.
    /// - The offsets point to positions within the bytecode `bytes`.
    /// - There exists at least the 4 byte header for each source at the offset,
    ///   within the bounds of the bytecode `bytes`.
    /// - The number of opcodes specified in the header of each source locates
    ///   the end of the source exactly at either the offset of the next source
    ///   or the end of the bytecode `bytes`.
    function checkNoOOBPointers(bytes memory bytecode) internal pure {
        unchecked {
            uint256 count = sourceCount(bytecode);
            // The common case is that there are more than 0 sources.
            if (count > 0) {
                uint256 sourcesRelativeStart = 1 + count * 2;
                if (sourcesRelativeStart > bytecode.length) {
                    revert TruncatedHeaderOffsets(bytecode);
                }
                uint256 sourcesStart;
                assembly ("memory-safe") {
                    sourcesStart := add(bytecode, add(0x20, sourcesRelativeStart))
                }

                // Start at the end of the bytecode and work backwards. Find the
                // last unchecked relative offset, follow it, read the opcode
                // count from the header, and check that ends at the end cursor.
                // Set the end cursor to the relative offset then repeat until
                // there are no more unchecked relative offsets. The endCursor
                // as a relative offset must be 0 at the end of this process
                // (i.e. the first relative offset is always 0).
                uint256 endCursor;
                assembly ("memory-safe") {
                    endCursor := add(bytecode, add(0x20, mload(bytecode)))
                }
                // This cursor points at the 2 byte relative offset that we need
                // to check next.
                uint256 uncheckedOffsetCursor;
                uint256 end;
                assembly ("memory-safe") {
                    uncheckedOffsetCursor := add(bytecode, add(0x21, mul(sub(count, 1), 2)))
                    end := add(bytecode, 0x21)
                }

                while (uncheckedOffsetCursor >= end) {
                    // Read the relative offset from the bytecode.
                    uint256 relativeOffset;
                    assembly ("memory-safe") {
                        relativeOffset := shr(0xF0, mload(uncheckedOffsetCursor))
                    }
                    uint256 absoluteOffset = sourcesStart + relativeOffset;

                    // Check that the 4 byte header is within the upper bound
                    // established by the end cursor before attempting to read
                    // from it.
                    uint256 headerEnd = absoluteOffset + 4;
                    if (headerEnd > endCursor) {
                        revert TruncatedHeader(bytecode);
                    }

                    // The ops count is the first byte of the header.
                    uint256 opsCount;
                    {
                        // The stack allocation, inputs, and outputs are the next
                        // 3 bytes of the header. We can't know exactly what they
                        // need to be according to the opcodes without checking
                        // every opcode implementation, but we can check that
                        // they satisfy the invariant
                        // `inputs <= outputs <= stackAllocation`.
                        // Note that the outputs may include the inputs, as the
                        // outputs is merely the final stack size.
                        uint256 stackAllocation;
                        uint256 inputs;
                        uint256 outputs;
                        assembly ("memory-safe") {
                            let data := mload(absoluteOffset)
                            opsCount := byte(0, data)
                            stackAllocation := byte(1, data)
                            inputs := byte(2, data)
                            outputs := byte(3, data)
                        }

                        if (inputs > outputs || outputs > stackAllocation) {
                            revert StackSizingsNotMonotonic(bytecode, relativeOffset);
                        }
                    }

                    // The ops count is the number of 4 byte opcodes in the
                    // source. Check that the end of the source is at the end
                    // cursor.
                    uint256 sourceEnd = headerEnd + opsCount * 4;
                    if (sourceEnd != endCursor) {
                        revert TruncatedSource(bytecode);
                    }

                    // Move the end cursor to the start of the header.
                    endCursor = absoluteOffset;
                    // Move the unchecked offset cursor to the previous offset.
                    uncheckedOffsetCursor -= 2;
                }

                // If the end cursor is not pointing at the absolute start of the
                // sources, then somehow the bytecode has malformed data between
                // the offsets and the sources.
                if (endCursor != sourcesStart) {
                    revert UnexpectedTrailingOffsetBytes(bytecode);
                }
            } else {
                // If there are no sources the bytecode is either 0 length or a
                // single 0 byte, which we already implicity checked by reaching
                // this code path. Ensure the bytecode has no trailing bytes.
                if (bytecode.length > 1) {
                    revert UnexpectedSources(bytecode);
                }
            }
        }
    }

    /// The relative byte offset of a source in the bytecode.
    /// This is the offset from the start of the first source header, which is
    /// after the source count byte and the source offsets.
    /// This function DOES NOT check that the relative offset is within the
    /// bounds of the bytecode. Callers MUST `checkNoOOBPointers` BEFORE
    /// attempting to traverse the bytecode, otherwise the relative offset MAY
    /// point to memory outside the bytecode `bytes`.
    /// @param bytecode The bytecode to inspect.
    /// @param sourceIndex The index of the source to inspect.
    /// @return offset The relative byte offset of the source in the bytecode.
    function sourceRelativeOffset(bytes memory bytecode, uint256 sourceIndex) internal pure returns (uint256 offset) {
        // If the source index requested is out of bounds, revert.
        if (sourceIndex >= sourceCount(bytecode)) {
            revert SourceIndexOutOfBounds(bytecode, sourceIndex);
        }
        assembly ("memory-safe") {
            // After the first byte, all the relative offset pointers are
            // stored sequentially as 16 bit values.
            offset := and(mload(add(add(bytecode, 3), mul(sourceIndex, 2))), 0xFFFF)
        }
    }

    /// The absolute byte pointer of a source in the bytecode. Points to the
    /// header of the source, NOT the first opcode.
    /// This function DOES NOT check that the source index is within the bounds
    /// of the bytecode. Callers MUST `checkNoOOBPointers` BEFORE attempting to
    /// traverse the bytecode, otherwise the relative offset MAY point to memory
    /// outside the bytecode `bytes`.
    /// @param bytecode The bytecode to inspect.
    /// @param sourceIndex The index of the source to inspect.
    /// @return pointer The absolute byte pointer of the source in the bytecode.
    function sourcePointer(bytes memory bytecode, uint256 sourceIndex) internal pure returns (Pointer pointer) {
        unchecked {
            uint256 sourcesStartOffset = 1 + sourceCount(bytecode) * 2;
            uint256 offset = sourceRelativeOffset(bytecode, sourceIndex);
            assembly ("memory-safe") {
                pointer := add(add(add(bytecode, 0x20), sourcesStartOffset), offset)
            }
        }
    }

    /// The number of opcodes in a source.
    /// This function DOES NOT check that the source index is within the bounds
    /// of the bytecode. Callers MUST `checkNoOOBPointers` BEFORE attempting to
    /// traverse the bytecode, otherwise the relative offset MAY point to memory
    /// outside the bytecode `bytes`.
    /// @param bytecode The bytecode to inspect.
    /// @param sourceIndex The index of the source to inspect.
    /// @return opsCount The number of opcodes in the source.
    function sourceOpsCount(bytes memory bytecode, uint256 sourceIndex) internal pure returns (uint256 opsCount) {
        unchecked {
            Pointer pointer = sourcePointer(bytecode, sourceIndex);
            assembly ("memory-safe") {
                opsCount := byte(0, mload(pointer))
            }
        }
    }

    /// The number of stack slots allocated by a source. This is the number of
    /// 32 byte words that MUST be allocated for the stack for the given source
    /// index to avoid memory corruption when executing the source.
    /// This function DOES NOT check that the source index is within the bounds
    /// of the bytecode. Callers MUST `checkNoOOBPointers` BEFORE attempting to
    /// traverse the bytecode, otherwise the relative offset MAY point to memory
    /// outside the bytecode `bytes`.
    /// @param bytecode The bytecode to inspect.
    /// @param sourceIndex The index of the source to inspect.
    /// @return allocation The number of stack slots allocated by the source.
    function sourceStackAllocation(bytes memory bytecode, uint256 sourceIndex)
        internal
        pure
        returns (uint256 allocation)
    {
        unchecked {
            Pointer pointer = sourcePointer(bytecode, sourceIndex);
            assembly ("memory-safe") {
                allocation := byte(1, mload(pointer))
            }
        }
    }

    /// The number of inputs and outputs of a source.
    /// This function DOES NOT check that the source index is within the bounds
    /// of the bytecode. Callers MUST `checkNoOOBPointers` BEFORE attempting to
    /// traverse the bytecode, otherwise the relative offset MAY point to memory
    /// outside the bytecode `bytes`.
    /// Note that both the inputs and outputs are always returned togther, this
    /// is because the caller SHOULD be checking both together whenever using
    /// some bytecode. Returning two values is more efficient than two separate
    /// function calls.
    /// @param bytecode The bytecode to inspect.
    /// @param sourceIndex The index of the source to inspect.
    /// @return inputs The number of inputs of the source.
    /// @return outputs The number of outputs of the source.
    function sourceInputsOutputsLength(bytes memory bytecode, uint256 sourceIndex)
        internal
        pure
        returns (uint256 inputs, uint256 outputs)
    {
        unchecked {
            Pointer pointer = sourcePointer(bytecode, sourceIndex);
            assembly ("memory-safe") {
                let data := mload(pointer)
                inputs := byte(2, data)
                outputs := byte(3, data)
            }
        }
    }

    /// Backwards compatibility with the old way of representing sources.
    /// Requires allocation and copying so it isn't particularly efficient, but
    /// allows us to use the new bytecode format with old interpreter code. Not
    /// recommended for production code but useful for testing.
    function bytecodeToSources(bytes memory bytecode) internal pure returns (bytes[] memory) {
        unchecked {
            uint256 count = sourceCount(bytecode);
            bytes[] memory sources = new bytes[](count);
            for (uint256 i = 0; i < count; i++) {
                // Skip over the prefix 4 bytes.
                Pointer pointer = sourcePointer(bytecode, i).unsafeAddBytes(4);
                uint256 length = sourceOpsCount(bytecode, i) * 4;
                bytes memory source = new bytes(length);
                pointer.unsafeCopyBytesTo(source.dataPointer(), length);
                // Move the opcode index one byte for each opcode, into the input
                // position, as legacly sources did not have input bytes.
                assembly ("memory-safe") {
                    for {
                        let cursor := add(source, 0x20)
                        let end := add(cursor, length)
                    } lt(cursor, end) { cursor := add(cursor, 4) } {
                        mstore8(add(cursor, 1), byte(0, mload(cursor)))
                        mstore8(cursor, 0)
                    }
                }
                sources[i] = source;
            }
            return sources;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// Entrypoint into the key/value store. Is a mutable pointer to the head of the
/// linked list. Initially points to `0` for an empty list. The total word count
/// of all inserts is also encoded alongside the pointer to allow efficient O(1)
/// memory allocation for a `uint256[]` in the case of a final snapshot/export.
type MemoryKV is uint256;

/// The key associated with the value for each item in the store.
type MemoryKVKey is uint256;

/// The value associated with the key for each item in the store.
type MemoryKVVal is uint256;

/// @title LibMemoryKV
library LibMemoryKV {
    /// Gets the value associated with a given key.
    /// The value returned will be `0` if the key exists and was set to zero OR
    /// the key DOES NOT exist, i.e. was never set.
    ///
    /// The caller MUST check the `exists` flag to disambiguate between zero
    /// values and unset keys.
    ///
    /// @param kv The entrypoint to the key/value store.
    /// @param key The key to lookup a `value` for.
    /// @return exists `0` if the key was not found. The `value` MUST NOT be
    /// used if the `key` does not exist.
    /// @return value The value for the `key`, if it exists, else `0`. MAY BE `0`
    /// even if the `key` exists. It is possible to set any key to a `0` value.
    function get(MemoryKV kv, MemoryKVKey key) internal pure returns (uint256 exists, MemoryKVVal value) {
        assembly ("memory-safe") {
            // Hash to find the internal linked list to walk.
            // Hash logic MUST match set.
            mstore(0, key)
            let bitOffset := mul(mod(keccak256(0, 0x20), 15), 0x10)

            // Loop until k found or give up if pointer is zero.
            for { let pointer := and(shr(bitOffset, kv), 0xFFFF) } iszero(iszero(pointer)) {
                pointer := mload(add(pointer, 0x40))
            } {
                if eq(key, mload(pointer)) {
                    exists := 1
                    value := mload(add(pointer, 0x20))
                    break
                }
            }
        }
    }

    /// Upserts a value in the set by its key. I.e. if the key exists then the
    /// associated value will be mutated in place, else a new key/value pair will
    /// be inserted. The key/value store pointer will be mutated and returned as
    /// it MAY point to a new list item in memory.
    /// @param kv The key/value store pointer to modify.
    /// @param key The key to upsert against.
    /// @param value The value to associate with the upserted key.
    /// @return The final value of `kv` as it MAY be modified if the upsert
    /// resulted in an insert operation.
    function set(MemoryKV kv, MemoryKVKey key, MemoryKVVal value) internal pure returns (MemoryKV) {
        assembly ("memory-safe") {
            // Hash to spread inserts across internal lists.
            // This MUST remain in sync with `get` logic.
            mstore(0, key)
            let bitOffset := mul(mod(keccak256(0, 0x20), 15), 0x10)

            // Set aside the starting pointer as we'll need to include it in any
            // newly inserted linked list items.
            let startPointer := and(shr(bitOffset, kv), 0xFFFF)

            // Find a key match then break so that we populate a nonzero pointer.
            let pointer := startPointer
            for {} iszero(iszero(pointer)) { pointer := mload(add(pointer, 0x40)) } {
                if eq(key, mload(pointer)) { break }
            }

            // If the pointer is nonzero we have to update the associated value
            // directly, otherwise this is an insert operation.
            switch iszero(pointer)
            // Update.
            case 0 { mstore(add(pointer, 0x20), value) }
            // Insert.
            default {
                // Allocate 3 words of memory.
                pointer := mload(0x40)
                mstore(0x40, add(pointer, 0x60))

                // Write key/value/pointer.
                mstore(pointer, key)
                mstore(add(pointer, 0x20), value)
                mstore(add(pointer, 0x40), startPointer)

                // Update total stored word count.
                let length := add(shr(0xf0, kv), 2)

                //slither-disable-next-line incorrect-shift
                kv := or(shl(0xf0, length), and(kv, not(shl(0xf0, 0xFFFF))))

                // kv must point to new insertion.
                //slither-disable-next-line incorrect-shift
                kv :=
                    or(
                        shl(bitOffset, pointer),
                        // Mask out the old pointer
                        and(kv, not(shl(bitOffset, 0xFFFF)))
                    )
            }
        }
        return kv;
    }

    /// Export/snapshot the underlying linked list of the key/value store into
    /// a standard `uint256[]`. Reads the total length to preallocate the
    /// `uint256[]` then bisects the bits of the `kv` to find non-zero pointers
    /// to linked lists, walking each found list to the end to extract all
    /// values. As a single `kv` has 15 slots for pointers to linked lists it is
    /// likely for smallish structures that many slots can simply be skipped, so
    /// the bisect approach can save ~1-1.5k gas vs. a naive linear loop over
    /// all 15 slots for every export.
    ///
    /// Note this is a one time export, if the key/value store is subsequently
    /// mutated the built array will not reflect these mutations.
    ///
    /// @param kv The entrypoint into the key/value store.
    /// @return array All the keys and values copied pairwise into a `uint256[]`.
    /// Slither is not wrong about the cyclomatic complexity but I don't know
    /// another way to implement the bisect and keep the gas savings.
    //slither-disable-next-line cyclomatic-complexity
    function toUint256Array(MemoryKV kv) internal pure returns (uint256[] memory array) {
        uint256 mask16 = type(uint16).max;
        uint256 mask32 = type(uint32).max;
        uint256 mask64 = type(uint64).max;
        uint256 mask128 = type(uint128).max;
        assembly ("memory-safe") {
            // Manually create an `uint256[]`.
            // No need to zero out memory as we're about to write to it.
            array := mload(0x40)
            let length := shr(0xf0, kv)
            mstore(0x40, add(array, add(0x20, mul(length, 0x20))))
            mstore(array, length)

            // Known false positives in slither
            // https://github.com/crytic/slither/issues/1815
            //slither-disable-next-line naming-convention
            function copyFromPtr(cursor, pointer) -> end {
                for {} iszero(iszero(pointer)) {
                    pointer := mload(add(pointer, 0x40))
                    cursor := add(cursor, 0x40)
                } {
                    mstore(cursor, mload(pointer))
                    mstore(add(cursor, 0x20), mload(add(pointer, 0x20)))
                }
                end := cursor
            }

            // Bisect.
            // This crazy tree saves ~1-1.5k gas vs. a simple loop with larger
            // relative savings for small-medium sized structures.
            // The internal scoping blocks are to provide some safety against
            // typos causing the incorrect symbol to be referenced by enforcing
            // each symbol is as tightly scoped as it can be.
            let cursor := add(array, 0x20)
            {
                // Remove the length from kv before iffing to save ~100 gas.
                let p0 := shr(0x90, shl(0x10, kv))
                if iszero(iszero(p0)) {
                    {
                        let p00 := shr(0x40, p0)
                        if iszero(iszero(p00)) {
                            {
                                // This branch is a special case because we
                                // already zeroed out the high bits which are
                                // used by the length and are NOT a pointer.
                                // We can skip processing where the pointer would
                                // have been if it were not the length, and do
                                // not need to scrub the high bits to move from
                                // `p00` to `p0001`.
                                let p0001 := shr(0x20, p00)
                                if iszero(iszero(p0001)) { cursor := copyFromPtr(cursor, p0001) }
                            }
                            let p001 := and(mask32, p00)
                            if iszero(iszero(p001)) {
                                {
                                    let p0010 := shr(0x10, p001)
                                    if iszero(iszero(p0010)) { cursor := copyFromPtr(cursor, p0010) }
                                }
                                let p0011 := and(mask16, p001)
                                if iszero(iszero(p0011)) { cursor := copyFromPtr(cursor, p0011) }
                            }
                        }
                    }
                    let p01 := and(mask64, p0)
                    if iszero(iszero(p01)) {
                        {
                            let p010 := shr(0x20, p01)
                            if iszero(iszero(p010)) {
                                {
                                    let p0100 := shr(0x10, p010)
                                    if iszero(iszero(p0100)) { cursor := copyFromPtr(cursor, p0100) }
                                }
                                let p0101 := and(mask16, p010)
                                if iszero(iszero(p0101)) { cursor := copyFromPtr(cursor, p0101) }
                            }
                        }

                        let p011 := and(mask32, p01)
                        if iszero(iszero(p011)) {
                            {
                                let p0110 := shr(0x10, p011)
                                if iszero(iszero(p0110)) { cursor := copyFromPtr(cursor, p0110) }
                            }

                            let p0111 := and(mask16, p011)
                            if iszero(iszero(p0111)) { cursor := copyFromPtr(cursor, p0111) }
                        }
                    }
                }
            }

            {
                let p1 := and(mask128, kv)
                if iszero(iszero(p1)) {
                    {
                        let p10 := shr(0x40, p1)
                        if iszero(iszero(p10)) {
                            {
                                let p100 := shr(0x20, p10)
                                if iszero(iszero(p100)) {
                                    {
                                        let p1000 := shr(0x10, p100)
                                        if iszero(iszero(p1000)) { cursor := copyFromPtr(cursor, p1000) }
                                    }
                                    let p1001 := and(mask16, p100)
                                    if iszero(iszero(p1001)) { cursor := copyFromPtr(cursor, p1001) }
                                }
                            }
                            let p101 := and(mask32, p10)
                            if iszero(iszero(p101)) {
                                {
                                    let p1010 := shr(0x10, p101)
                                    if iszero(iszero(p1010)) { cursor := copyFromPtr(cursor, p1010) }
                                }
                                let p1011 := and(mask16, p101)
                                if iszero(iszero(p1011)) { cursor := copyFromPtr(cursor, p1011) }
                            }
                        }
                    }
                    let p11 := and(mask64, p1)
                    if iszero(iszero(p11)) {
                        {
                            let p110 := shr(0x20, p11)
                            if iszero(iszero(p110)) {
                                {
                                    let p1100 := shr(0x10, p110)
                                    if iszero(iszero(p1100)) { cursor := copyFromPtr(cursor, p1100) }
                                }
                                let p1101 := and(mask16, p110)
                                if iszero(iszero(p1101)) { cursor := copyFromPtr(cursor, p1101) }
                            }
                        }

                        let p111 := and(mask32, p11)
                        if iszero(iszero(p111)) {
                            {
                                let p1110 := shr(0x10, p111)
                                if iszero(iszero(p1110)) { cursor := copyFromPtr(cursor, p1110) }
                            }

                            let p1111 := and(mask16, p111)
                            if iszero(iszero(p1111)) { cursor := copyFromPtr(cursor, p1111) }
                        }
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./LibPointer.sol";

/// Thrown when asked to truncate data to a longer length.
/// @param length Actual bytes length.
/// @param truncate Attempted truncation length.
error TruncateError(uint256 length, uint256 truncate);

/// @title LibBytes
/// @notice Tools for working directly with memory in a Solidity compatible way.
library LibBytes {
    /// Truncates bytes of data by mutating its length directly.
    /// Any excess bytes are leaked
    function truncate(bytes memory data, uint256 length) internal pure {
        if (data.length < length) {
            revert TruncateError(data.length, length);
        }
        assembly ("memory-safe") {
            mstore(data, length)
        }
    }

    /// Pointer to the data of a bytes array NOT the length prefix.
    /// @param data Bytes to get the data pointer for.
    /// @return pointer Pointer to the data of the bytes in memory.
    function dataPointer(bytes memory data) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(data, 0x20)
        }
    }

    /// Pointer to the start of a bytes array (the length prefix).
    /// @param data Bytes to get the pointer to.
    /// @return pointer Pointer to the start of the bytes data structure.
    function startPointer(bytes memory data) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := data
        }
    }

    /// Pointer to the end of some bytes.
    ///
    /// Note that this pointer MAY NOT BE ALIGNED, i.e. it MAY NOT point to the
    /// start of a multiple of 32, UNLIKE the free memory pointer at 0x40.
    ///
    /// @param data Bytes to get the pointer to the end of.
    /// @return pointer Pointer to the end of the bytes data structure.
    function endDataPointer(bytes memory data) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(data, add(0x20, mload(data)))
        }
    }

    /// Pointer to the end of the memory allocated for bytes.
    ///
    /// The allocator is ALWAYS aligned to whole words, i.e. 32 byte multiples,
    /// for data structures allocated by Solidity. This includes `bytes` which
    /// means that any time the length of some `bytes` is NOT a multiple of 32
    /// the alloation will point past the end of the `bytes` data.
    ///
    /// There is no guarantee that the memory region between `endDataPointer`
    /// and `endAllocatedPointer` is zeroed out. It is best to think of that
    /// space as leaked garbage.
    ///
    /// Almost always, e.g. for the purpose of copying data between regions, you
    /// will want `endDataPointer` rather than this function.
    /// @param data Bytes to get the end of the allocated data region for.
    /// @return pointer Pointer to the end of the allocated data region.
    function endAllocatedPointer(bytes memory data) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(data, and(add(add(mload(data), 0x20), 0x1f), not(0x1f)))
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {MemoryKV} from "rain.lib.memkv/lib/LibMemoryKV.sol";
import {
    FullyQualifiedNamespace, IInterpreterStoreV2
} from "rain.interpreter.interface/interface/IInterpreterStoreV2.sol";

address constant STACK_TRACER = address(uint160(uint256(keccak256("rain.interpreter.stack-tracer.0"))));

struct InterpreterStateNP {
    Pointer[] stackBottoms;
    uint256[] constants;
    uint256 sourceIndex;
    MemoryKV stateKV;
    FullyQualifiedNamespace namespace;
    IInterpreterStoreV2 store;
    uint256[][] context;
    bytes bytecode;
    bytes fs;
}

library LibInterpreterStateNP {
    function fingerprint(InterpreterStateNP memory state) internal pure returns (bytes32) {
        return keccak256(abi.encode(state));
    }

    function stackBottoms(uint256[][] memory stacks) internal pure returns (Pointer[] memory) {
        Pointer[] memory bottoms = new Pointer[](stacks.length);
        assembly ("memory-safe") {
            for {
                let cursor := add(stacks, 0x20)
                let end := add(cursor, mul(mload(stacks), 0x20))
                let bottomsCursor := add(bottoms, 0x20)
            } lt(cursor, end) {
                cursor := add(cursor, 0x20)
                bottomsCursor := add(bottomsCursor, 0x20)
            } {
                let stack := mload(cursor)
                let stackBottom := add(stack, mul(0x20, add(mload(stack), 1)))
                mstore(bottomsCursor, stackBottom)
            }
        }
        return bottoms;
    }

    /// Does something that a full node can easily track in its traces that isn't
    /// an event. Specifically, it calls the tracer contract with the memory
    /// region between `stackTop` and `stackBottom` as an argument. The source
    /// index is used literally as a 4 byte prefix to the memory region, so that
    /// it will be interpreted as a function selector by most tooling that is
    /// expecting ABI encoded data.
    ///
    /// The tracer contract doesn't exist, the whole point is that the call will
    /// be a no-op, but it will be visible in traces and unambiguous as no other
    /// call will be made to the tracer contract for any reason other than
    /// tracing stacks.
    ///
    /// Note that the trace is a literal memory region, no ABI encoding or other
    /// processing is done. The structure is 4 bytes of the source index, then
    /// 32 byte items for each stack item, in order from top to bottom.
    ///
    /// There are several reasons we do this instead of emitting an event:
    /// - It's cheaper. Way cheaper in the case of large stacks. There is a one
    ///   time 2600 gas cost to warm the tracer, then all subsequent calls are
    ///   just 100 gas + memory expansion cost. Using an empty contract means
    ///   there's no execution cost.
    ///   (vs. e.g. a solidity contract that would at least attempt a dispatch)
    ///   Meanwhile, emitting an event costs 375 gas plus 8 gas per byte, plus
    ///   the cost of the memory expansion.
    ///   Let's say we have 50 stack items spread over 5 calls:
    ///   - Using the tracer:
    ///     ( 2600 + 100 * 4 ) + (51 ** 2) / 512 + (3 * 51)
    ///     = 3000 + 2601 / 665
    ///     = 3000 + 4 ~= 3000
    ///   - Using an event (assuming same memory expansion cost):
    ///     (375 * 5) + (8 * 50 * 32) + 4
    ///     = 1875 + 12800 + 4
    ///     = 14679 (nearly 5x the cost!)
    /// - Events cannot be emitted from view functions, so we would have to
    ///   either abandon our view eval (security risk) or return every internal
    ///   stack back to the caller, to have it handle the event emission. This
    ///   would be both complex and onerous for caller implementations, and make
    ///   it much harder for tooling/consumers to reliably find all the data, as
    ///   it would be spread across callers in potentially inconsistent events.
    function stackTrace(uint256 parentSourceIndex, uint256 sourceIndex, Pointer stackTop, Pointer stackBottom)
        internal
        view
    {
        address tracer = STACK_TRACER;
        assembly ("memory-safe") {
            // We are mutating memory in place to avoid allocation, copying, etc.
            let beforePtr := sub(stackTop, 0x20)
            // We need to save the value at the pointer before we overwrite it.
            let before := mload(beforePtr)
            mstore(beforePtr, or(shl(0x10, parentSourceIndex), sourceIndex))
            // We don't care about success, we just want to call the tracer.
            let success := staticcall(gas(), tracer, sub(stackTop, 4), add(sub(stackBottom, stackTop), 4), 0, 0)
            // Restore the value at the pointer that we mutated above.
            mstore(beforePtr, before)
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

/// @dev Workaround for https://github.com/foundry-rs/foundry/issues/6572
contract ErrOpList {}

/// Thrown when a dynamic length array is NOT 1 more than a fixed length array.
/// Should never happen outside a major breaking change to memory layouts.
error BadDynamicLength(uint256 dynamicLength, uint256 standardOpsLength);

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @title LibConvert
/// @notice Type conversions that require additional structural changes to
/// complete safely. These are NOT mere type casts and involve additional
/// reads and writes to complete, such as recalculating the length of an array.
/// The convention "toX" is adopted from Rust to imply the additional costs and
/// consumption of the source to produce the target.
library LibConvert {
    /// Convert an array of integers to `bytes` data. This requires modifying
    /// the length in situ as the integer array length is measured in 32 byte
    /// increments while the length of `bytes` is the literal number of bytes.
    ///
    /// It is unsafe for the caller to use `us_` after it has been converted to
    /// bytes because there is now two pointers to the same mutable data
    /// structure AND the length prefix for the `uint256[]` version is corrupt.
    ///
    /// @param us_ The integer array to convert to `bytes`.
    /// @return bytes_ The integer array converted to `bytes` data.
    function unsafeToBytes(uint256[] memory us_) internal pure returns (bytes memory bytes_) {
        assembly ("memory-safe") {
            bytes_ := us_
            // Length in bytes is 32x the length in uint256
            mstore(bytes_, mul(0x20, mload(bytes_)))
        }
    }

    /// Truncate `uint256[]` values down to `uint16[]` then pack this to `bytes`
    /// without padding or length prefix. Unsafe because the starting `uint256`
    /// values are not checked for overflow due to the truncation. The caller
    /// MUST ensure that all values fit in `type(uint16).max` or that silent
    /// overflow is safe.
    /// @param us_ The `uint256[]` to truncate and concatenate to 16 bit `bytes`.
    /// @return The concatenated 2-byte chunks.
    function unsafeTo16BitBytes(uint256[] memory us_) internal pure returns (bytes memory) {
        unchecked {
            // We will keep 2 bytes (16 bits) from each integer.
            bytes memory bytes_ = new bytes(us_.length * 2);
            assembly ("memory-safe") {
                let replaceMask_ := 0xFFFF
                let preserveMask_ := not(replaceMask_)
                for {
                    let cursor_ := add(us_, 0x20)
                    let end_ := add(cursor_, mul(mload(us_), 0x20))
                    let bytesCursor_ := add(bytes_, 0x02)
                } lt(cursor_, end_) {
                    cursor_ := add(cursor_, 0x20)
                    bytesCursor_ := add(bytesCursor_, 0x02)
                } {
                    let data_ := mload(bytesCursor_)
                    mstore(bytesCursor_, or(and(preserveMask_, data_), and(replaceMask_, mload(cursor_))))
                }
            }
            return bytes_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {
    ExpectedOperand,
    UnclosedOperand,
    OperandOverflow,
    OperandValuesOverflow,
    UnexpectedOperand,
    UnexpectedOperandValue
} from "../../error/ErrParse.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {LibParse} from "./LibParse.sol";
import {LibParseLiteral} from "./literal/LibParseLiteral.sol";
import {CMASK_OPERAND_END, CMASK_WHITESPACE, CMASK_OPERAND_START} from "./LibParseCMask.sol";
import {ParseState, OPERAND_VALUES_LENGTH, FSM_YANG_MASK} from "./LibParseState.sol";
import {LibParseError} from "./LibParseError.sol";
import {LibParseInterstitial} from "./LibParseInterstitial.sol";

library LibParseOperand {
    using LibParseError for ParseState;
    using LibParseLiteral for ParseState;
    using LibParseOperand for ParseState;
    using LibParseInterstitial for ParseState;

    function parseOperand(ParseState memory state, uint256 cursor, uint256 end) internal pure returns (uint256) {
        uint256 char;
        assembly ("memory-safe") {
            //slither-disable-next-line incorrect-shift
            char := shl(byte(0, mload(cursor)), 1)
        }

        // Reset operand values to length 0 to avoid any previous values bleeding
        // into processing this operand.
        uint256[] memory operandValues = state.operandValues;
        assembly ("memory-safe") {
            mstore(operandValues, 0)
        }

        // There may not be an operand. Only process if there is.
        if (char == CMASK_OPERAND_START) {
            // Move past the opening character.
            ++cursor;
            // Let the state be yin so we can parse literals.
            state.fsm &= ~FSM_YANG_MASK;

            // Load the next char.
            assembly ("memory-safe") {
                //slither-disable-next-line incorrect-shift
                char := shl(byte(0, mload(cursor)), 1)
            }
            uint256 i = 0;
            bool success = false;
            while (cursor < end) {
                // Load the next char.
                assembly ("memory-safe") {
                    //slither-disable-next-line incorrect-shift
                    char := shl(byte(0, mload(cursor)), 1)
                }

                // Handle any whitespace.
                // We DO NOT currently support full interstitial parsing here.
                if (char & CMASK_WHITESPACE != 0) {
                    // Move past the whitespace.
                    cursor = state.skipWhitespace(cursor, end);
                }
                // If the operand has ended break.
                else if (char & CMASK_OPERAND_END != 0) {
                    // Move past the operand end.
                    ++cursor;
                    success = true;
                    break;
                }
                // Attempt to parse literals if we're not yang.
                else if (state.fsm & FSM_YANG_MASK == 0) {
                    // We can't exceed the initial length of the operand values
                    // that was allocated when the parse state was created.
                    if (i == OPERAND_VALUES_LENGTH) {
                        revert OperandValuesOverflow(state.parseErrorOffset(cursor));
                    }
                    uint256 value;
                    (cursor, value) = state.parseLiteral(cursor, end);
                    // We manipulate the operand values array directly in
                    // assembly because if we used the Solidity indexing syntax
                    // it would bounds check against the _current_ length of the
                    // operand values array, not the length it was when the
                    // parse state was created. The current length is just
                    // whatever it happened to be for the last operand that was
                    // parsed, so it's not useful for us here.
                    assembly ("memory-safe") {
                        mstore(add(operandValues, add(0x20, mul(i, 0x20))), value)
                    }
                    // Set yang so we don't attempt to parse a literal straight
                    // off the back of this literal without some whitespace.
                    state.fsm |= FSM_YANG_MASK;
                    ++i;
                }
                // Something failed here so let's say the author forgot to close
                // the operand, which is a little arbitrary but at least it's
                // a consistent error.
                else {
                    revert UnclosedOperand(state.parseErrorOffset(cursor));
                }
            }
            if (!success) {
                revert UnclosedOperand(state.parseErrorOffset(cursor));
            }
            assembly ("memory-safe") {
                mstore(operandValues, i)
            }
        }

        return cursor;
    }

    /// Standard dispatch for handling an operand after it is parsed, using the
    /// encoded function pointers on the current parse state. Requires that the
    /// word index has been looked up by the parser, exists, and the literal
    /// values have all been parsed out of the operand string. In the case of
    /// the main parser this will all be done inline, but in the case of a sub
    /// parser the literal extraction will be done first, then the word lookup
    /// will have to be done by the sub parser, alongside the values provided
    /// by the main parser.
    function handleOperand(ParseState memory state, uint256 wordIndex) internal pure returns (Operand) {
        function (uint256[] memory) internal pure returns (Operand) handler;
        bytes memory handlers = state.operandHandlers;
        assembly ("memory-safe") {
            // There is no bounds check here because the indexes are calcualted
            // by the parser itself, NOT provided by the user. Therefore the
            // scope of corrupt data is limited to a bug in the parser itself,
            // which can and should have direct test coverage.
            handler := and(mload(add(handlers, add(2, mul(wordIndex, 2)))), 0xFFFF)
        }
        return handler(state.operandValues);
    }

    function handleOperandDisallowed(uint256[] memory values) internal pure returns (Operand) {
        if (values.length != 0) {
            revert UnexpectedOperand();
        }
        return Operand.wrap(0);
    }

    function handleOperandDisallowedAlwaysOne(uint256[] memory values) internal pure returns (Operand) {
        if (values.length != 0) {
            revert UnexpectedOperand();
        }
        return Operand.wrap(1);
    }

    /// There must be one or zero values. The fallback is 0 if nothing is
    /// provided, else the provided value MUST fit in two bytes and is used as
    /// is.
    function handleOperandSingleFull(uint256[] memory values) internal pure returns (Operand operand) {
        // Happy path at the top for efficiency.
        if (values.length == 1) {
            assembly ("memory-safe") {
                operand := mload(add(values, 0x20))
            }
            if (Operand.unwrap(operand) > uint256(type(uint16).max)) {
                revert OperandOverflow();
            }
        } else if (values.length == 0) {
            operand = Operand.wrap(0);
        } else {
            revert UnexpectedOperandValue();
        }
    }

    /// There must be exactly one value. There is no default fallback.
    function handleOperandSingleFullNoDefault(uint256[] memory values) internal pure returns (Operand operand) {
        // Happy path at the top for efficiency.
        if (values.length == 1) {
            assembly ("memory-safe") {
                operand := mload(add(values, 0x20))
            }
            if (Operand.unwrap(operand) > uint256(type(uint16).max)) {
                revert OperandOverflow();
            }
        } else if (values.length == 0) {
            revert ExpectedOperand();
        } else {
            revert UnexpectedOperandValue();
        }
    }

    /// There must be exactly two values. There is no default fallback. Each
    /// value MUST fit in one byte and is used as is.
    function handleOperandDoublePerByteNoDefault(uint256[] memory values) internal pure returns (Operand operand) {
        // Happy path at the top for efficiency.
        if (values.length == 2) {
            uint256 a;
            uint256 b;
            assembly ("memory-safe") {
                a := mload(add(values, 0x20))
                b := mload(add(values, 0x40))
            }
            if (a > type(uint8).max || b > type(uint8).max) {
                revert OperandOverflow();
            }
            operand = Operand.wrap(a | (b << 8));
        } else if (values.length < 2) {
            revert ExpectedOperand();
        } else {
            revert UnexpectedOperandValue();
        }
    }

    /// 8 bit value then maybe 1 bit flag then maybe 1 bit flag. Fallback to 0
    /// for both flags if not provided.
    function handleOperand8M1M1(uint256[] memory values) internal pure returns (Operand operand) {
        // Happy path at the top for efficiency.
        uint256 length = values.length;
        if (length >= 1 && length <= 3) {
            uint256 a;
            uint256 b;
            uint256 c;
            assembly ("memory-safe") {
                a := mload(add(values, 0x20))
            }

            if (length >= 2) {
                assembly ("memory-safe") {
                    b := mload(add(values, 0x40))
                }
            } else {
                b = 0;
            }

            if (length == 3) {
                assembly ("memory-safe") {
                    c := mload(add(values, 0x60))
                }
            } else {
                c = 0;
            }

            if (a > type(uint8).max || b > 1 || c > 1) {
                revert OperandOverflow();
            }

            operand = Operand.wrap(a | (b << 8) | (c << 9));
        } else if (length == 0) {
            revert ExpectedOperand();
        } else {
            revert UnexpectedOperandValue();
        }
    }

    /// 2x maybe 1 bit flags. Fallback to 0 for both flags if not provided.
    function handleOperandM1M1(uint256[] memory values) internal pure returns (Operand operand) {
        // Happy path at the top for efficiency.
        uint256 length = values.length;
        if (length < 3) {
            uint256 a;
            uint256 b;

            if (length >= 1) {
                assembly ("memory-safe") {
                    a := mload(add(values, 0x20))
                }
            } else {
                a = 0;
            }

            if (length == 2) {
                assembly ("memory-safe") {
                    b := mload(add(values, 0x40))
                }
            } else {
                b = 0;
            }

            if (a > 1 || b > 1) {
                revert OperandOverflow();
            }

            operand = Operand.wrap(a | (b << 1));
        } else {
            revert UnexpectedOperandValue();
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";

/// Thrown when a stack read index is outside the current stack top.
error OutOfBoundsStackRead(uint256 opIndex, uint256 stackTopIndex, uint256 stackRead);

/// @title LibOpStackNP
/// Implementation of copying a stack item from the stack to the stack.
/// Integrated deeply into LibParse, which requires this opcode or a variant
/// to be present at a known opcode index.
library LibOpStackNP {
    function integrity(IntegrityCheckStateNP memory state, Operand operand) internal pure returns (uint256, uint256) {
        uint256 readIndex = Operand.unwrap(operand) & 0xFFFF;
        // Operand is the index so ensure it doesn't exceed the stack index.
        if (readIndex >= state.stackIndex) {
            revert OutOfBoundsStackRead(state.opIndex, state.stackIndex, readIndex);
        }

        // Move the read highwater if needed.
        if (readIndex > state.readHighwater) {
            state.readHighwater = readIndex;
        }

        return (0, 1);
    }

    function run(InterpreterStateNP memory state, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 sourceIndex = state.sourceIndex;
        assembly ("memory-safe") {
            let stackBottom := mload(add(mload(state), mul(0x20, add(sourceIndex, 1))))
            let stackValue := mload(sub(stackBottom, mul(0x20, add(and(operand, 0xFFFF), 1))))
            stackTop := sub(stackTop, 0x20)
            mstore(stackTop, stackValue)
        }
        return stackTop;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";

/// Thrown when a constant read index is outside the constants array.
error OutOfBoundsConstantRead(uint256 opIndex, uint256 constantsLength, uint256 constantRead);

/// @title LibOpConstantNP
/// Implementation of copying a constant from the constants array to the stack.
/// Integrated deeply into LibParse, which requires this opcode or a variant
/// to be present at a known opcode index.
library LibOpConstantNP {
    function integrity(IntegrityCheckStateNP memory state, Operand operand) internal pure returns (uint256, uint256) {
        // Operand is the index so ensure it doesn't exceed the constants length.
        uint256 constantIndex = Operand.unwrap(operand) & 0xFFFF;
        if (constantIndex >= state.constants.length) {
            revert OutOfBoundsConstantRead(state.opIndex, state.constants.length, constantIndex);
        }
        // As inputs MUST always be 0, we don't have to check the high byte of
        // the operand here, the integrity check will do that for us.
        return (0, 1);
    }

    function run(InterpreterStateNP memory state, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256[] memory constants = state.constants;
        // Skip index OOB check and rely on integrity check for that.
        assembly ("memory-safe") {
            let value := mload(add(constants, mul(add(and(operand, 0xFFFF), 1), 0x20)))
            stackTop := sub(stackTop, 0x20)
            mstore(stackTop, value)
        }
        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory state, Operand operand, uint256[] memory)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        uint256 index = Operand.unwrap(operand) & 0xFFFF;
        outputs = new uint256[](1);
        outputs[0] = state.constants[index];
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {NotAnExternContract} from "../../../error/ErrExtern.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {
    IInterpreterExternV3,
    ExternDispatch,
    EncodedExternDispatch
} from "rain.interpreter.interface/interface/IInterpreterExternV3.sol";
import {LibExtern} from "../../extern/LibExtern.sol";
import {LibMemCpy} from "rain.solmem/lib/LibMemCpy.sol";
import {LibUint256Array} from "rain.solmem/lib/LibUint256Array.sol";
import {ERC165Checker} from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";

/// Thrown when a constant read index is outside the constants array.
error OutOfBoundsConstantRead(uint256 opIndex, uint256 constantsLength, uint256 constantRead);

/// Thrown when the outputs length is not equal to the expected length.
error BadOutputsLength(uint256 expectedLength, uint256 actualLength);

/// @title LibOpExternNP
/// @notice Implementation of calling an external contract.
library LibOpExternNP {
    using LibUint256Array for uint256[];

    function integrity(IntegrityCheckStateNP memory state, Operand operand) internal view returns (uint256, uint256) {
        uint256 encodedExternDispatchIndex = Operand.unwrap(operand) & 0xFFFF;

        EncodedExternDispatch encodedExternDispatch =
            EncodedExternDispatch.wrap(state.constants[encodedExternDispatchIndex]);
        (IInterpreterExternV3 extern, ExternDispatch dispatch) = LibExtern.decodeExternCall(encodedExternDispatch);
        if (!ERC165Checker.supportsInterface(address(extern), type(IInterpreterExternV3).interfaceId)) {
            revert NotAnExternContract(address(extern));
        }
        uint256 expectedInputsLength = (Operand.unwrap(operand) >> 0x10) & 0x0F;
        uint256 expectedOutputsLength = (Operand.unwrap(operand) >> 0x14) & 0x0F;
        //slither-disable-next-line unused-return
        return extern.externIntegrity(dispatch, expectedInputsLength, expectedOutputsLength);
    }

    function run(InterpreterStateNP memory state, Operand operand, Pointer stackTop) internal view returns (Pointer) {
        uint256 encodedExternDispatchIndex = Operand.unwrap(operand) & 0xFFFF;
        uint256 inputsLength = (Operand.unwrap(operand) >> 0x10) & 0x0F;
        uint256 outputsLength = (Operand.unwrap(operand) >> 0x14) & 0x0F;

        uint256 encodedExternDispatch = state.constants[encodedExternDispatchIndex];
        (IInterpreterExternV3 extern, ExternDispatch dispatch) =
            LibExtern.decodeExternCall(EncodedExternDispatch.wrap(encodedExternDispatch));
        uint256[] memory inputs;
        uint256 head;
        assembly ("memory-safe") {
            // Mutate the word before the current stack top to be the length of
            // the inputs array so we can treat it as an inputs array. This will
            // either mutate memory allocated to the stack that is not currently
            // in use, or the length of the stack array itself, which will need
            // to be repaired after the call. We store the original value of the
            // word before the stack top so we can restore it after the call,
            // just in case it is the latter scenario.
            inputs := sub(stackTop, 0x20)
            head := mload(inputs)
            mstore(inputs, inputsLength)
        }
        uint256[] memory outputs = extern.extern(dispatch, inputs);
        if (outputsLength != outputs.length) {
            revert BadOutputsLength(outputsLength, outputs.length);
        }

        assembly ("memory-safe") {
            // Restore whatever was in memory before we built our inputs array.
            // Inputs is no longer safe to use after this point.
            mstore(inputs, head)
            stackTop := add(stackTop, mul(inputsLength, 0x20))
            // Copy outputs out.
            let sourceCursor := add(outputs, 0x20)
            let end := add(sourceCursor, mul(outputsLength, 0x20))
            // We loop this backwards so that the 0th output is _lowest_ on the
            // stack, which visually maps to:
            // `a b: extern<x 2>(a b);`
            // If the extern implementation is an identity function and has both
            // inputs and outputs as `[a, b]`.
            for {} lt(sourceCursor, end) { sourceCursor := add(sourceCursor, 0x20) } {
                stackTop := sub(stackTop, 0x20)
                mstore(stackTop, mload(sourceCursor))
            }
        }
        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory state, Operand operand, uint256[] memory inputs)
        internal
        view
        returns (uint256[] memory outputs)
    {
        uint256 encodedExternDispatchIndex = Operand.unwrap(operand) & 0xFFFF;
        uint256 outputsLength = (Operand.unwrap(operand) >> 0x14) & 0x0F;

        uint256 encodedExternDispatch = state.constants[encodedExternDispatchIndex];
        (IInterpreterExternV3 extern, ExternDispatch dispatch) =
            LibExtern.decodeExternCall(EncodedExternDispatch.wrap(encodedExternDispatch));
        outputs = extern.extern(dispatch, inputs);
        if (outputs.length != outputsLength) {
            revert BadOutputsLength(outputsLength, outputs.length);
        }
        // The stack is built backwards, so we need to reverse the outputs.
        LibUint256Array.reverse(outputs);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";

/// @title LibOpBitwiseAndNP
/// @notice Opcode for computing bitwise AND from the top two items on the stack.
library LibOpBitwiseAndNP {
    /// The operand does nothing. Always 2 inputs and 1 output.
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // Always 2 inputs and 1 output.
        return (2, 1);
    }

    /// Bitwise AND the top two items on the stack.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        Pointer stackTopAfter;
        assembly ("memory-safe") {
            stackTopAfter := add(stackTop, 0x20)
            mstore(stackTopAfter, and(mload(stackTop), mload(stackTopAfter)))
        }
        return stackTopAfter;
    }

    /// Reference implementation for bitwise AND.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = inputs[0] & inputs[1];
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";

/// @title LibOpBitwiseOrNP
/// @notice Opcode for computing bitwise OR from the top two items on the stack.
library LibOpBitwiseOrNP {
    /// The operand does nothing. Always 2 inputs and 1 output.
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // Always 2 inputs and 1 output.
        return (2, 1);
    }

    /// Bitwise OR the top two items on the stack.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        Pointer stackTopAfter;
        assembly ("memory-safe") {
            stackTopAfter := add(stackTop, 0x20)
            mstore(stackTopAfter, or(mload(stackTop), mload(stackTopAfter)))
        }
        return stackTopAfter;
    }

    /// Reference implementation for bitwise OR.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = inputs[0] | inputs[1];
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {LibCtPop} from "../../bitwise/LibCtPop.sol";

/// @title LibOpCtPopNP
/// @notice An opcode that counts the number of bits set in a word. This is
/// called ctpop because that's the name of this kind of thing elsewhere, but
/// the more common name is "population count" or "Hamming weight". The word
/// in the standard ops lib is called `bitwise-count-ones`, which follows the
/// Rust naming convention.
/// There is no evm opcode for this, so we have to implement it ourselves.
library LibOpCtPopNP {
    /// ctpop unconditionally takes one value and returns one value.
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        return (1, 1);
    }

    /// Output is the number of bits set to one in the input. Thin wrapper around
    /// `LibCtPop.ctpop`.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 value;
        assembly ("memory-safe") {
            value := mload(stackTop)
        }
        value = LibCtPop.ctpop(value);
        assembly ("memory-safe") {
            mstore(stackTop, value)
        }
        return stackTop;
    }

    /// The reference implementation of ctpop.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        inputs[0] = LibCtPop.ctpopSlow(inputs[0]);
        return inputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {LibOpEncodeBitsNP} from "./LibOpEncodeBitsNP.sol";

/// @title LibOpDecodeBitsNP
/// @notice Opcode for decoding binary data from a 256 bit value that was encoded
/// with LibOpEncodeBitsNP.
library LibOpDecodeBitsNP {
    /// Decode takes a single value and returns the decoded value.
    function integrity(IntegrityCheckStateNP memory state, Operand operand) internal pure returns (uint256, uint256) {
        // Use exact same integrity check as encode other than the return values.
        // All we're interested in is the errors that might be thrown.
        //slither-disable-next-line unused-return
        LibOpEncodeBitsNP.integrity(state, operand);

        return (1, 1);
    }

    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        unchecked {
            uint256 value;
            assembly ("memory-safe") {
                value := mload(stackTop)
            }

            // We decode as a start and length of bits. This avoids mistakes such as
            // inclusive/exclusive ranges, and makes it easier to reason about the
            // encoding.
            uint256 startBit = Operand.unwrap(operand) & 0xFF;
            uint256 length = (Operand.unwrap(operand) >> 8) & 0xFF;

            // Build a bitmask of desired length. Max length is uint8 max which
            // is 255. A 256 length doesn't really make sense as that isn't an
            // encoding anyway, it's just the value verbatim.
            //slither-disable-next-line incorrect-shift
            uint256 mask = (1 << length) - 1;
            value = (value >> startBit) & mask;

            assembly ("memory-safe") {
                mstore(stackTop, value)
            }
            return stackTop;
        }
    }

    function referenceFn(InterpreterStateNP memory, Operand operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        // We decode as a start and length of bits. This avoids mistakes such as
        // inclusive/exclusive ranges, and makes it easier to reason about the
        // encoding.
        uint256 startBit = Operand.unwrap(operand) & 0xFF;
        uint256 length = (Operand.unwrap(operand) >> 8) & 0xFF;

        // Build a bitmask of desired length. Max length is uint8 max which
        // is 255. A 256 length doesn't really make sense as that isn't an
        // encoding anyway, it's just the value verbatim.
        uint256 mask = (2 ** length) - 1;
        outputs = new uint256[](1);
        outputs[0] = (inputs[0] >> startBit) & mask;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {ZeroLengthBitwiseEncoding, TruncatedBitwiseEncoding} from "../../../error/ErrBitwise.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";

/// @title LibOpEncodeBitsNP
/// @notice Opcode for encoding binary data into a 256 bit value.
library LibOpEncodeBitsNP {
    /// Encode takes two values and returns one value. The first value is the
    /// source, the second value is the target.
    function integrity(IntegrityCheckStateNP memory, Operand operand) internal pure returns (uint256, uint256) {
        uint256 startBit = Operand.unwrap(operand) & 0xFF;
        uint256 length = (Operand.unwrap(operand) >> 8) & 0xFF;

        if (length == 0) {
            revert ZeroLengthBitwiseEncoding();
        }
        if (startBit + length > 256) {
            revert TruncatedBitwiseEncoding(startBit, length);
        }
        return (2, 1);
    }

    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        unchecked {
            uint256 source;
            uint256 target;
            assembly ("memory-safe") {
                source := mload(stackTop)
                stackTop := add(stackTop, 0x20)
                target := mload(stackTop)
            }

            // We encode as a start and length of bits. This avoids mistakes such as
            // inclusive/exclusive ranges, and makes it easier to reason about the
            // encoding.
            uint256 startBit = Operand.unwrap(operand) & 0xFF;
            uint256 length = (Operand.unwrap(operand) >> 8) & 0xFF;

            // Build a bitmask of desired length. Max length is uint8 max which
            // is 255. A 256 length doesn't really make sense as that isn't an
            // encoding anyway, it's just the source verbatim.
            uint256 mask = (2 ** length - 1);

            // Punch a mask sized hole in target.
            target &= ~(mask << startBit);

            // Fill the hole with masked bytes from source.
            target |= (source & mask) << startBit;

            assembly ("memory-safe") {
                mstore(stackTop, target)
            }
            return stackTop;
        }
    }

    function referenceFn(InterpreterStateNP memory, Operand operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        uint256 source = inputs[0];
        uint256 target = inputs[1];

        // We encode as a start and length of bits. This avoids mistakes such as
        // inclusive/exclusive ranges, and makes it easier to reason about the
        // encoding.
        uint256 startBit = Operand.unwrap(operand) & 0xFF;
        uint256 length = (Operand.unwrap(operand) >> 8) & 0xFF;

        // Build a bitmask of desired length. Max length is uint8 max which
        // is 255. A 256 length doesn't really make sense as that isn't an
        // encoding anyway, it's just the source verbatim.
        uint256 mask = (2 ** length - 1);

        // Punch a mask sized hole in target.
        target &= ~(mask << startBit);

        // Fill the hole with masked bytes from source.
        target |= (source & mask) << startBit;

        outputs = new uint256[](1);
        outputs[0] = target;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {UnsupportedBitwiseShiftAmount} from "../../../error/ErrBitwise.sol";

/// @title LibOpShiftBitsLeftNP
/// @notice Opcode for shifting bits left. The shift amount is taken from the
/// operand so it is compile time constant.
library LibOpShiftBitsLeftNP {
    /// Shift bits left by the amount specified in the operand.
    function integrity(IntegrityCheckStateNP memory, Operand operand) internal pure returns (uint256, uint256) {
        uint256 shiftAmount = Operand.unwrap(operand) & 0xFFFF;

        if (
            // Shift amount must not result in the output always being 0.
            shiftAmount > uint256(type(uint8).max)
            // Shift amount must not result in a noop.
            || shiftAmount == 0
        ) {
            revert UnsupportedBitwiseShiftAmount(shiftAmount);
        }

        // Always 1 input and 1 output.
        return (1, 1);
    }

    /// Shift bits left by the amount specified in the operand.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            mstore(stackTop, shl(and(operand, 0xFF), mload(stackTop)))
        }
        return stackTop;
    }

    /// Reference implementation for shifting bits left.
    function referenceFn(InterpreterStateNP memory, Operand operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 shiftAmount = Operand.unwrap(operand) & 0xFFFF;
        inputs[0] = inputs[0] << shiftAmount;
        return inputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {UnsupportedBitwiseShiftAmount} from "../../../error/ErrBitwise.sol";

/// @title LibOpShiftBitsRightNP
/// @notice Opcode for shifting bits right. The shift amount is taken from the
/// operand so it is compile time constant.
library LibOpShiftBitsRightNP {
    /// Shift bits right by the amount specified in the operand.
    function integrity(IntegrityCheckStateNP memory, Operand operand) internal pure returns (uint256, uint256) {
        uint256 shiftAmount = Operand.unwrap(operand) & 0xFFFF;

        if (
            // Shift amount must not result in the output always being 0.
            shiftAmount > type(uint8).max
            // Shift amount must not result in a noop.
            || shiftAmount == 0
        ) {
            revert UnsupportedBitwiseShiftAmount(shiftAmount);
        }

        // Always 1 input and 1 output.
        return (1, 1);
    }

    /// Shift bits right by the amount specified in the operand.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            mstore(stackTop, shr(and(operand, 0xFF), mload(stackTop)))
        }
        return stackTop;
    }

    /// Reference implementation for shifting bits right.
    function referenceFn(InterpreterStateNP memory, Operand operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 shiftAmount = Operand.unwrap(operand) & 0xFFFF;
        inputs[0] = inputs[0] >> shiftAmount;
        return inputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {LibInterpreterStateNP, InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {LibIntegrityCheckNP, IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Pointer, LibPointer} from "rain.solmem/lib/LibPointer.sol";
import {LibBytecode} from "rain.interpreter.interface/lib/bytecode/LibBytecode.sol";
import {LibEvalNP} from "../../eval/LibEvalNP.sol";

/// Thrown when the outputs requested by the operand exceed the outputs
/// available from the source.
/// @param sourceOutputs The number of outputs available from the source.
/// @param outputs The number of outputs requested by the operand.
error CallOutputsExceedSource(uint256 sourceOutputs, uint256 outputs);

/// @title LibOpCallNP
/// @notice Contains the call operation. This allows sources to be treated in a
/// function-like manner. Primarily intended as a way for expression authors to
/// create reusable logic inline with their expression, in a way that mimics how
/// words and stack consumption works at the Solidity level.
///
/// Similarities between `call` and a traditional function:
/// - The source is called with a set of 0+ inputs.
/// - The source returns a set of 0+ outputs.
/// - The source has a fixed number of inputs and outputs.
/// - When the source executes it has its own stack/scope.
/// - Sources use lexical scoping rules for named LHS items.
/// - The source can be called from multiple places.
/// - The source can `call` other sources.
/// - The source is stateless across calls
///   (although it can use words like get/set to read/write external state).
/// - The caller and callee have to agree on the number of inputs
///   (but not outputs, see below).
/// - Generally speaking, the behaviour of a source can be reasoned about
///   without needing to know the context in which it is called. Which is the
///   basic requirement for reusability.
///
/// Differences between `call` and a traditional function:
/// - The caller defines the number of outputs to be returned, NOT the callee.
///   This is because the caller is responsible for allocating space on the
///   stack for the outputs, and the callee is responsible for providing the
///   outputs. The only limitation is that the caller cannot request more
///   outputs than the callee has available. This means that two calls to the
///   same source can return different numbers of outputs in different contexts.
/// - The inputs to a source are considered to be the top of the callee's stack
///   from the perspective of the caller. This means that the inputs are eligible
///   to be read as outputs, if the caller chooses to do so.
/// - The sources are not named, they are identified by their index in the
///   bytecode. Tooling can provide sugar over this but the underlying
///   representation is just an index.
/// - Sources are not "first class" like functions often are, i.e. they cannot
///   be passed as arguments to other sources or otherwise be treated as values.
/// - Recursion is not supported. This is because currently there is no laziness
///   in the interpreter, so a recursive call would result in an infinite loop
///   unconditionally (even when wrapped in an `if`). This may change in the
///   future.
/// - The memory allocation for a source must be known at compile time.
/// - There's no way to return early from a source.
///
/// The order of inputs and outputs is designed so that the visual representation
/// of a source call matches the visual representation of a function call. This
/// requires some reversals of order "under the hood" while copying data around
/// but it makes the behaviour of `call` more intuitive.
///
/// Illustrative example:
/// ```
/// /* Final result */
/// /* a = 2 */
/// /* b = 9 */
/// a b: call<1 2>(10 5); ten five:, a b: int-div(ten five) 9;
/// ```
library LibOpCallNP {
    using LibPointer for Pointer;

    function integrity(IntegrityCheckStateNP memory state, Operand operand) internal pure returns (uint256, uint256) {
        uint256 sourceIndex = Operand.unwrap(operand) & 0xFFFF;
        uint256 outputs = Operand.unwrap(operand) >> 0x14;

        (uint256 sourceInputs, uint256 sourceOutputs) =
            LibBytecode.sourceInputsOutputsLength(state.bytecode, sourceIndex);

        if (sourceOutputs < outputs) {
            revert CallOutputsExceedSource(sourceOutputs, outputs);
        }

        return (sourceInputs, outputs);
    }

    /// The `call` word is conceptually very simple. It takes a source index, a
    /// number of outputs, and a number of inputs. It then runs the standard
    /// eval loop for the source, with a starting stack pointer above the inputs,
    /// and then copies the outputs to the calling stack.
    function run(InterpreterStateNP memory state, Operand operand, Pointer stackTop) internal view returns (Pointer) {
        // Extract config from the operand.
        uint256 sourceIndex = Operand.unwrap(operand) & 0xFFFF;
        uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
        uint256 outputs = Operand.unwrap(operand) >> 0x14;

        // Copy inputs in. The inputs have to be copied in reverse order so that
        // the top of the stack from the perspective of `call`, i.e. the first
        // input to call, is the bottom of the stack from the perspective of the
        // callee.
        Pointer[] memory stackBottoms = state.stackBottoms;
        Pointer evalStackBottom;
        Pointer evalStackTop;
        assembly ("memory-safe") {
            evalStackBottom := mload(add(stackBottoms, mul(add(sourceIndex, 1), 0x20)))
            evalStackTop := evalStackBottom
            let end := add(stackTop, mul(inputs, 0x20))
            for {} lt(stackTop, end) { stackTop := add(stackTop, 0x20) } {
                evalStackTop := sub(evalStackTop, 0x20)
                mstore(evalStackTop, mload(stackTop))
            }
        }

        // Keep a copy of the current source index so that we can restore it
        // after the call.
        uint256 currentSourceIndex = state.sourceIndex;

        // Set the state to the source we are calling.
        state.sourceIndex = sourceIndex;

        // Run the eval loop.
        evalStackTop = LibEvalNP.evalLoopNP(state, currentSourceIndex, evalStackTop, evalStackBottom);

        // Restore the source index in the state.
        state.sourceIndex = currentSourceIndex;

        // Copy outputs out.
        assembly ("memory-safe") {
            stackTop := sub(stackTop, mul(outputs, 0x20))
            let end := add(evalStackTop, mul(outputs, 0x20))
            let cursor := stackTop
            for {} lt(evalStackTop, end) {
                cursor := add(cursor, 0x20)
                evalStackTop := add(evalStackTop, 0x20)
            } { mstore(cursor, mload(evalStackTop)) }
        }

        return stackTop;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";

library LibOpContextNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // Context doesn't have any inputs. The operand defines the reads.
        // Unfortunately we don't know the shape of the context that we will
        // receive at runtime, so we can't check the reads at integrity time.
        return (0, 1);
    }

    function run(InterpreterStateNP memory state, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 i = Operand.unwrap(operand) & 0xFF;
        uint256 j = (Operand.unwrap(operand) >> 8) & 0xFF;
        // We want these indexes to be checked at runtime for OOB accesses
        // because we don't know the shape of the context at compile time.
        // Solidity handles that for us as long as we don't invoke yul for the
        // reads.
        if (Pointer.unwrap(stackTop) < 0x20) {
            revert("stack underflow");
        }
        uint256 v = state.context[i][j];
        assembly ("memory-safe") {
            stackTop := sub(stackTop, 0x20)
            mstore(stackTop, v)
        }
        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory state, Operand operand, uint256[] memory)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        uint256 i = Operand.unwrap(operand) & 0xFF;
        uint256 j = (Operand.unwrap(operand) >> 8) & 0xFF;
        // We want these indexes to be checked at runtime for OOB accesses
        // because we don't know the shape of the context at compile time.
        // Solidity handles that for us as long as we don't invoke yul for the
        // reads.
        uint256 v = state.context[i][j];
        outputs = new uint256[](1);
        outputs[0] = v;
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpHashNP
/// Implementation of keccak256 hashing as a standard Rainlang opcode.
library LibOpHashNP {
    function integrity(IntegrityCheckStateNP memory, Operand operand) internal pure returns (uint256, uint256) {
        // Any number of inputs are valid.
        // 0 inputs will be the hash of empty (0 length) bytes.
        uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
        return (inputs, 1);
    }

    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            let length := mul(and(shr(0x10, operand), 0x0F), 0x20)
            let value := keccak256(stackTop, length)
            stackTop := sub(add(stackTop, length), 0x20)
            mstore(stackTop, value)
        }
        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        outputs = new uint256[](1);
        outputs[0] = uint256(keccak256(abi.encodePacked(inputs)));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";

/// @title OpERC20AllowanceNP
/// @notice Opcode for getting the current erc20 allowance of an account.
library LibOpERC20AllowanceNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // Always 3 inputs, the token, the owner and the spender.
        // Always 1 output, the allowance.
        return (3, 1);
    }

    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal view returns (Pointer) {
        uint256 token;
        uint256 owner;
        uint256 spender;
        assembly ("memory-safe") {
            token := mload(stackTop)
            owner := mload(add(stackTop, 0x20))
            stackTop := add(stackTop, 0x40)
            spender := mload(stackTop)
        }
        uint256 tokenAllowance =
            IERC20(address(uint160(token))).allowance(address(uint160(owner)), address(uint160(spender)));
        assembly ("memory-safe") {
            mstore(stackTop, tokenAllowance)
        }
        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 token = inputs[0];
        uint256 owner = inputs[1];
        uint256 spender = inputs[2];
        uint256 tokenAllowance =
            IERC20(address(uint160(token))).allowance(address(uint160(owner)), address(uint160(spender)));
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = tokenAllowance;
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";

/// @title OpERC20BalanceOfNP
/// @notice Opcode for getting the current erc20 balance of an account.
library LibOpERC20BalanceOfNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // Always 2 inputs, the token and the account.
        // Always 1 output, the balance.
        return (2, 1);
    }

    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal view returns (Pointer) {
        uint256 token;
        uint256 account;
        assembly ("memory-safe") {
            token := mload(stackTop)
            stackTop := add(stackTop, 0x20)
            account := mload(stackTop)
        }
        uint256 tokenBalance = IERC20(address(uint160(token))).balanceOf(address(uint160(account)));
        assembly ("memory-safe") {
            mstore(stackTop, tokenBalance)
        }
        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 token = inputs[0];
        uint256 account = inputs[1];
        uint256 tokenBalance = IERC20(address(uint160(token))).balanceOf(address(uint160(account)));
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = tokenBalance;
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";

/// @title LibOpERC20TotalSupplyNP
/// @notice Opcode for ERC20 `totalSupply`.
library LibOpERC20TotalSupplyNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // Always 1 input, the contract.
        // Always 1 output, the total supply.
        return (1, 1);
    }

    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal view returns (Pointer) {
        uint256 account;
        assembly {
            account := mload(stackTop)
        }
        uint256 totalSupply = IERC20(address(uint160(account))).totalSupply();
        assembly {
            mstore(stackTop, totalSupply)
        }
        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 account = inputs[0];
        uint256 totalSupply = IERC20(address(uint160(account))).totalSupply();
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = totalSupply;
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";

/// @title OpERC721BalanceOfNP
/// @notice Opcode for getting the current erc721 balance of an account.
library LibOpERC721BalanceOfNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // Always 2 inputs, the token and the account.
        // Always 1 output, the balance.
        return (2, 1);
    }

    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal view returns (Pointer) {
        uint256 token;
        uint256 account;
        assembly ("memory-safe") {
            token := mload(stackTop)
            stackTop := add(stackTop, 0x20)
            account := mload(stackTop)
        }
        uint256 tokenBalance = IERC721(address(uint160(token))).balanceOf(address(uint160(account)));
        assembly ("memory-safe") {
            mstore(stackTop, tokenBalance)
        }
        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 token = inputs[0];
        uint256 account = inputs[1];
        uint256 tokenBalance = IERC721(address(uint160(token))).balanceOf(address(uint160(account)));
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = tokenBalance;
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";

/// @title LibOpERC721OwnerOfNP
/// @notice Opcode for getting the current owner of an erc721 token.
library LibOpERC721OwnerOfNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // Always 2 inputs, the token and the tokenId.
        // Always 1 output, the owner.
        return (2, 1);
    }

    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal view returns (Pointer) {
        uint256 token;
        uint256 tokenId;
        assembly ("memory-safe") {
            token := mload(stackTop)
            stackTop := add(stackTop, 0x20)
            tokenId := mload(stackTop)
        }
        address tokenOwner = IERC721(address(uint160(token))).ownerOf(tokenId);
        assembly ("memory-safe") {
            mstore(stackTop, tokenOwner)
        }
        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 token = inputs[0];
        uint256 tokenId = inputs[1];
        address tokenOwner = IERC721(address(uint160(token))).ownerOf(tokenId);
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = uint256(uint160(tokenOwner));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {IERC5313} from "openzeppelin-contracts/contracts/interfaces/IERC5313.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";

/// @title LibOpERC5313OwnerNP
/// @notice Opcode for ERC5313 `owner`.
library LibOpERC5313OwnerNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // Always 1 input, the contract.
        // Always 1 output, the owner.
        return (1, 1);
    }

    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal view returns (Pointer) {
        uint256 account;
        assembly {
            account := mload(stackTop)
        }
        address owner = IERC5313(address(uint160(account))).owner();
        assembly {
            mstore(stackTop, owner)
        }
        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 account = inputs[0];
        address owner = IERC5313(address(uint160(account))).owner();
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = uint256(uint160(owner));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpBlockNumberNP
/// Implementation of the EVM `BLOCKNUMBER` opcode as a standard Rainlang opcode.
library LibOpBlockNumberNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        return (0, 1);
    }

    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal view returns (Pointer) {
        assembly ("memory-safe") {
            stackTop := sub(stackTop, 0x20)
            mstore(stackTop, number())
        }
        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = block.number;
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpChainIdNP
/// Implementation of the EVM `CHAINID` opcode as a standard Rainlang opcode.
library LibOpChainIdNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        return (0, 1);
    }

    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal view returns (Pointer) {
        assembly ("memory-safe") {
            stackTop := sub(stackTop, 0x20)
            mstore(stackTop, chainid())
        }
        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = block.chainid;
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";

/// @title LibOpMaxUint256NP
/// Exposes `type(uint256).max` as a Rainlang opcode.
library LibOpMaxUint256NP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        return (0, 1);
    }

    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 value = type(uint256).max;
        assembly ("memory-safe") {
            stackTop := sub(stackTop, 0x20)
            mstore(stackTop, value)
        }
        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = type(uint256).max;
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP, LibInterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";

/// @title LibOpTimestampNP
/// Implementation of the EVM `TIMESTAMP` opcode as a standard Rainlang opcode.
library LibOpTimestampNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        return (0, 1);
    }

    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal view returns (Pointer) {
        assembly ("memory-safe") {
            stackTop := sub(stackTop, 0x20)
            mstore(stackTop, timestamp())
        }
        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = block.timestamp;
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";

/// @title LibOpAnyNP
/// @notice Opcode to return the first nonzero item on the stack up to the inputs
/// limit.
library LibOpAnyNP {
    function integrity(IntegrityCheckStateNP memory, Operand operand) internal pure returns (uint256, uint256) {
        // There must be at least one input.
        uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
        inputs = inputs > 0 ? inputs : 1;
        return (inputs, 1);
    }

    /// ANY
    /// ANY is the first nonzero item, else 0.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            let length := mul(and(shr(0x10, operand), 0x0F), 0x20)
            let cursor := stackTop
            stackTop := sub(add(stackTop, length), 0x20)
            for { let end := add(cursor, length) } lt(cursor, end) { cursor := add(cursor, 0x20) } {
                let item := mload(cursor)
                if gt(item, 0) {
                    mstore(stackTop, item)
                    break
                }
            }
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of ANY for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        // Zero length inputs is not supported so this 0 will always be written
        // over.
        uint256 value = 0;
        for (uint256 i = 0; i < inputs.length; i++) {
            value = inputs[i];
            if (value != 0) {
                break;
            }
        }
        outputs = new uint256[](1);
        outputs[0] = value;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {LibIntOrAString, IntOrAString} from "rain.intorastring/src/lib/LibIntOrAString.sol";

/// @title LibOpConditionsNP
/// @notice Opcode to return the first nonzero item on the stack up to the inputs
/// limit.
library LibOpConditionsNP {
    using LibIntOrAString for IntOrAString;

    function integrity(IntegrityCheckStateNP memory, Operand operand) internal pure returns (uint256, uint256) {
        // There must be at least two inputs.
        uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
        inputs = inputs > 2 ? inputs : 2;
        return (inputs, 1);
    }

    /// `conditions`
    /// Pairwise list of conditions and values. The first nonzero condition
    /// evaluated puts its corresponding value on the stack. `conditions` is
    /// eagerly evaluated. If no condition is nonzero, the expression will
    /// revert. The number of inputs must be even. The number of outputs is 1.
    /// If an author wants to provide some default value, they can set the last
    /// condition to some nonzero constant value such as 1.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 condition;
        IntOrAString reason = IntOrAString.wrap(0);
        assembly ("memory-safe") {
            let inputs := and(shr(0x10, operand), 0x0F)
            let oddInputs := mod(inputs, 2)

            let cursor := stackTop
            for {
                let end := add(cursor, mul(sub(inputs, oddInputs), 0x20))
                stackTop := sub(end, mul(iszero(oddInputs), 0x20))
                if oddInputs { reason := mload(end) }
            } lt(cursor, end) { cursor := add(cursor, 0x40) } {
                condition := mload(cursor)
                if condition {
                    mstore(stackTop, mload(add(cursor, 0x20)))
                    break
                }
            }
        }
        require(condition > 0, reason.toString());
        return stackTop;
    }

    /// Gas intensive reference implementation of `condition` for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        // Unchecked so that any overflow errors come from the real
        // implementation.
        unchecked {
            uint256 length = inputs.length;
            outputs = new uint256[](1);
            for (uint256 i = 0; i < length; i += 2) {
                if (inputs[i] != 0) {
                    outputs[0] = inputs[i + 1];
                    return outputs;
                }
            }
            if (inputs.length % 2 != 0) {
                IntOrAString reason = IntOrAString.wrap(inputs[length - 1]);
                require(false, reason.toString());
            } else {
                require(false, "");
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {LibIntOrAString, IntOrAString} from "rain.intorastring/src/lib/LibIntOrAString.sol";

/// @title LibOpEnsureNP
/// @notice Opcode to revert if the condition is zero.
library LibOpEnsureNP {
    using LibIntOrAString for IntOrAString;

    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be exactly 2 inputs.
        return (2, 0);
    }

    /// `ensure`
    /// If the condition is zero, the expression will revert with the given
    /// string.
    /// All conditions are eagerly evaluated and there are no outputs.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 condition;
        IntOrAString reason;
        assembly ("memory-safe") {
            condition := mload(stackTop)
            reason := mload(add(stackTop, 0x20))
            stackTop := add(stackTop, 0x40)
        }

        require(condition > 0, reason.toString());
        return stackTop;
    }

    /// Gas intensive reference implementation of `ensure` for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        require(inputs[0] > 0, IntOrAString.wrap(inputs[1]).toString());
        outputs = new uint256[](0);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpEqualToNP
/// @notice Opcode to return 1 if the first item on the stack is equal to
/// the second item on the stack, else 0.
library LibOpEqualToNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        return (2, 1);
    }

    /// EQ
    /// EQ is 1 if the first item is equal to the second item, else 0.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            let a := mload(stackTop)
            stackTop := add(stackTop, 0x20)
            mstore(stackTop, eq(a, mload(stackTop)))
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of EQ for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        outputs = new uint256[](1);
        outputs[0] = inputs[0] == inputs[1] ? 1 : 0;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpEveryNP
/// @notice Opcode to return the last item out of N items if they are all true,
/// else 0.
library LibOpEveryNP {
    function integrity(IntegrityCheckStateNP memory, Operand operand) internal pure returns (uint256, uint256) {
        // There must be at least one input.
        uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
        inputs = inputs > 0 ? inputs : 1;
        return (inputs, 1);
    }

    /// EVERY is the last nonzero item, else 0.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            let length := mul(and(shr(0x10, operand), 0x0F), 0x20)
            let cursor := stackTop
            stackTop := sub(add(stackTop, length), 0x20)
            for { let end := add(cursor, length) } lt(cursor, end) { cursor := add(cursor, 0x20) } {
                let item := mload(cursor)
                if iszero(item) {
                    mstore(stackTop, item)
                    break
                }
            }
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of EVERY for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        // Zero length inputs is not supported so this 0 will always be written
        // over.
        uint256 value = 0;
        for (uint256 i = 0; i < inputs.length; i++) {
            value = inputs[i];
            if (value == 0) {
                break;
            }
        }
        outputs = new uint256[](1);
        outputs[0] = value;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpGreaterThanNP
/// @notice Opcode to return 1 if the first item on the stack is greater than
/// the second item on the stack, else 0.
library LibOpGreaterThanNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        return (2, 1);
    }

    /// GT
    /// GT is 1 if the first item is greater than the second item, else 0.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            let a := mload(stackTop)
            stackTop := add(stackTop, 0x20)
            mstore(stackTop, gt(a, mload(stackTop)))
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of GT for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        outputs = new uint256[](1);
        outputs[0] = inputs[0] > inputs[1] ? 1 : 0;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpGreaterThanOrEqualToNP
/// @notice Opcode to return 1 if the first item on the stack is greater than or
/// equal to the second item on the stack, else 0.
library LibOpGreaterThanOrEqualToNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        return (2, 1);
    }

    /// GTE
    /// GTE is 1 if the first item is greater than or equal to the second item,
    /// else 0.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            let a := mload(stackTop)
            stackTop := add(stackTop, 0x20)
            mstore(stackTop, iszero(lt(a, mload(stackTop))))
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of GTE for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        outputs = new uint256[](1);
        outputs[0] = inputs[0] >= inputs[1] ? 1 : 0;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpIfNP
/// @notice Opcode to choose between two values based on a condition. If is
/// eager, meaning both values are evaluated before the condition is checked.
library LibOpIfNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        return (3, 1);
    }

    /// IF
    /// IF is a conditional. If the first item on the stack is nonero, the second
    /// item is returned, else the third item is returned.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            let condition := mload(stackTop)
            stackTop := add(stackTop, 0x40)
            mstore(stackTop, mload(sub(stackTop, mul(0x20, iszero(iszero(condition))))))
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of IF for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        outputs = new uint256[](1);
        outputs[0] = inputs[0] > 0 ? inputs[1] : inputs[2];
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpIsZeroNP
/// @notice Opcode to return 1 if the top item on the stack is zero, else 0.
library LibOpIsZeroNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        return (1, 1);
    }

    /// ISZERO
    /// ISZERO is 1 if the top item is zero, else 0.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            mstore(stackTop, iszero(mload(stackTop)))
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of ISZERO for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        outputs = new uint256[](1);
        outputs[0] = inputs[0] == 0 ? 1 : 0;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";

/// @title LibOpLessThanNP
/// @notice Opcode to return 1 if the first item on the stack is less than
/// the second item on the stack, else 0.
library LibOpLessThanNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        return (2, 1);
    }

    /// LT
    /// LT is 1 if the first item is less than the second item, else 0.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            let a := mload(stackTop)
            stackTop := add(stackTop, 0x20)
            mstore(stackTop, lt(a, mload(stackTop)))
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of LT for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        outputs = new uint256[](1);
        outputs[0] = inputs[0] < inputs[1] ? 1 : 0;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";

/// @title LibOpLessThanOrEqualToNP
/// @notice Opcode to return 1 if the first item on the stack is less than or
/// equal to the second item on the stack, else 0.
library LibOpLessThanOrEqualToNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        return (2, 1);
    }

    /// LTE
    /// LTE is 1 if the first item is less than or equal to the second item,
    /// else 0.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            let a := mload(stackTop)
            stackTop := add(stackTop, 0x20)
            mstore(stackTop, iszero(gt(a, mload(stackTop))))
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of LTE for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        outputs = new uint256[](1);
        outputs[0] = inputs[0] <= inputs[1] ? 1 : 0;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {UD60x18, mul, pow} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpDecimal18ExponentialGrowthNP
/// @notice Exponential growth is base(1 + rate)^t where base is the initial
/// value, rate is the growth rate, and t is time.
library LibOpDecimal18ExponentialGrowthNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be three inputs and one output.
        return (3, 1);
    }

    /// decimal18-exponential-growth
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 base;
        uint256 rate;
        uint256 t;
        assembly ("memory-safe") {
            base := mload(stackTop)
            rate := mload(add(stackTop, 0x20))
            stackTop := add(stackTop, 0x40)
            t := mload(stackTop)
        }
        base = UD60x18.unwrap(mul(UD60x18.wrap(base), pow(UD60x18.wrap(1e18 + rate), UD60x18.wrap(t))));

        assembly ("memory-safe") {
            mstore(stackTop, base)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] =
            UD60x18.unwrap(mul(UD60x18.wrap(inputs[0]), pow(UD60x18.wrap(1e18 + inputs[1]), UD60x18.wrap(inputs[2]))));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {UD60x18, mul, add} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpDecimal18LinearGrowthNP
/// @notice Linear growth is base + rate * t where a is the initial value, r is
/// the growth rate, and t is time.
library LibOpDecimal18LinearGrowthNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be three inputs and one output.
        return (3, 1);
    }

    /// decimal18-linear-growth
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 base;
        uint256 rate;
        uint256 t;
        assembly ("memory-safe") {
            base := mload(stackTop)
            rate := mload(add(stackTop, 0x20))
            stackTop := add(stackTop, 0x40)
            t := mload(stackTop)
        }
        base = UD60x18.unwrap(add(UD60x18.wrap(base), mul(UD60x18.wrap(rate), UD60x18.wrap(t))));

        assembly ("memory-safe") {
            mstore(stackTop, base)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = UD60x18.unwrap(add(UD60x18.wrap(inputs[0]), mul(UD60x18.wrap(inputs[1]), UD60x18.wrap(inputs[2]))));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {UD60x18, avg} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpDecimal18AvgNP
/// @notice Opcode for the average of two decimal 18 fixed point numbers.
library LibOpDecimal18AvgNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be two inputs and one output.
        return (2, 1);
    }

    /// decimal18-avg
    /// 18 decimal fixed point average of two numbers.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        uint256 b;
        assembly ("memory-safe") {
            a := mload(stackTop)
            stackTop := add(stackTop, 0x20)
            b := mload(stackTop)
        }
        a = UD60x18.unwrap(avg(UD60x18.wrap(a), UD60x18.wrap(b)));

        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of avg for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = UD60x18.unwrap(avg(UD60x18.wrap(inputs[0]), UD60x18.wrap(inputs[1])));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {UD60x18, ceil} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpDecimal18CeilNP
/// @notice Opcode for the ceiling of an decimal 18 fixed point number.
library LibOpDecimal18CeilNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be one inputs and one output.
        return (1, 1);
    }

    /// decimal18-ceil
    /// 18 decimal fixed point ceiling of a number.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        assembly ("memory-safe") {
            a := mload(stackTop)
        }
        a = UD60x18.unwrap(ceil(UD60x18.wrap(a)));

        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of ceil for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = UD60x18.unwrap(ceil(UD60x18.wrap(inputs[0])));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// Used for reference implementation so that we have two independent
/// upstreams to compare against.
import {Math as OZMath} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {UD60x18, mul} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";
import {LibWillOverflow} from "rain.math.fixedpoint/lib/LibWillOverflow.sol";

/// @title LibOpDecimal18MulNP
/// @notice Opcode to mul N 18 decimal fixed point values. Errors on overflow.
library LibOpDecimal18MulNP {
    function integrity(IntegrityCheckStateNP memory, Operand operand) internal pure returns (uint256, uint256) {
        // There must be at least two inputs.
        uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
        inputs = inputs > 1 ? inputs : 2;
        return (inputs, 1);
    }

    /// decimal18-mul
    /// 18 decimal fixed point multiplication with implied overflow checks from
    /// PRB Math.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        uint256 b;
        assembly ("memory-safe") {
            a := mload(stackTop)
            b := mload(add(stackTop, 0x20))
            stackTop := add(stackTop, 0x40)
        }
        a = UD60x18.unwrap(mul(UD60x18.wrap(a), UD60x18.wrap(b)));

        {
            uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
            uint256 i = 2;
            while (i < inputs) {
                assembly ("memory-safe") {
                    b := mload(stackTop)
                    stackTop := add(stackTop, 0x20)
                }
                a = UD60x18.unwrap(mul(UD60x18.wrap(a), UD60x18.wrap(b)));
                unchecked {
                    i++;
                }
            }
        }
        assembly ("memory-safe") {
            stackTop := sub(stackTop, 0x20)
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of multiplication for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        // Unchecked so that when we assert that an overflow error is thrown, we
        // see the revert from the real function and not the reference function.
        unchecked {
            uint256 a = inputs[0];
            for (uint256 i = 1; i < inputs.length; i++) {
                uint256 b = inputs[i];
                if (LibWillOverflow.mulDivWillOverflow(a, b, 1e18)) {
                    a = uint256(keccak256(abi.encodePacked("overflow sentinel")));
                    break;
                }
                a = OZMath.mulDiv(a, b, 1e18);
            }
            outputs = new uint256[](1);
            outputs[0] = a;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// Used for reference implementation so that we have two independent
/// upstreams to compare against.
import {Math as OZMath} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {LibWillOverflow} from "rain.math.fixedpoint/lib/LibWillOverflow.sol";
import {UD60x18, div} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpDecimal18DivNP
/// @notice Opcode to div N 18 decimal fixed point values. Errors on overflow.
library LibOpDecimal18DivNP {
    function integrity(IntegrityCheckStateNP memory, Operand operand) internal pure returns (uint256, uint256) {
        // There must be at least two inputs.
        uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
        inputs = inputs > 1 ? inputs : 2;
        return (inputs, 1);
    }

    /// decimal18-div
    /// 18 decimal fixed point division with implied overflow checks from PRB
    /// Math.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        uint256 b;
        assembly ("memory-safe") {
            a := mload(stackTop)
            b := mload(add(stackTop, 0x20))
            stackTop := add(stackTop, 0x40)
        }
        a = UD60x18.unwrap(div(UD60x18.wrap(a), UD60x18.wrap(b)));

        {
            uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
            uint256 i = 2;
            while (i < inputs) {
                assembly ("memory-safe") {
                    b := mload(stackTop)
                    stackTop := add(stackTop, 0x20)
                }
                a = UD60x18.unwrap(div(UD60x18.wrap(a), UD60x18.wrap(b)));
                unchecked {
                    i++;
                }
            }
        }
        assembly ("memory-safe") {
            stackTop := sub(stackTop, 0x20)
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of division for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        // Unchecked so that when we assert that an overflow error is thrown, we
        // see the revert from the real function and not the reference function.
        unchecked {
            uint256 a = inputs[0];
            for (uint256 i = 1; i < inputs.length; i++) {
                uint256 b = inputs[i];
                // Just bail out with a = some sentinel value if we're going to
                // overflow or divide by zero. This gives the real implementation
                // space to throw its own error that the test harness is expecting.
                // We don't want the real implementation to fail to throw the
                // error and also produce the same result, so a needs to have
                // some collision resistant value.
                if (b == 0 || LibWillOverflow.mulDivWillOverflow(a, 1e18, b)) {
                    a = uint256(keccak256(abi.encodePacked("overflow sentinel")));
                    break;
                }
                a = OZMath.mulDiv(a, 1e18, b);
            }
            outputs = new uint256[](1);
            outputs[0] = a;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {UD60x18, exp} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpDecimal18ExpNP
/// @notice Opcode for the natural exponential e^x as decimal 18 fixed point.
library LibOpDecimal18ExpNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be one inputs and one output.
        return (1, 1);
    }

    /// decimal18-exp
    /// 18 decimal fixed point natural exponent of a number.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        assembly ("memory-safe") {
            a := mload(stackTop)
        }
        a = UD60x18.unwrap(exp(UD60x18.wrap(a)));

        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of exp for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = UD60x18.unwrap(exp(UD60x18.wrap(inputs[0])));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {UD60x18, exp2} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpDecimal18Exp2NP
/// @notice Opcode for the binary exponential 2^x as decimal 18 fixed point.
library LibOpDecimal18Exp2NP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be one inputs and one output.
        return (1, 1);
    }

    /// decimal18-exp2
    /// 18 decimal fixed point binary exponent of a number.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        assembly ("memory-safe") {
            a := mload(stackTop)
        }
        a = UD60x18.unwrap(exp2(UD60x18.wrap(a)));

        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of exp for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = UD60x18.unwrap(exp2(UD60x18.wrap(inputs[0])));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {UD60x18, floor} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpDecimal18FloorNP
/// @notice Opcode for the floor of an decimal 18 fixed point number.
library LibOpDecimal18FloorNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be one input and one output.
        return (1, 1);
    }

    /// decimal18-floor
    /// 18 decimal fixed point floor of a number.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        assembly ("memory-safe") {
            a := mload(stackTop)
        }
        a = UD60x18.unwrap(floor(UD60x18.wrap(a)));

        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of floor for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = UD60x18.unwrap(floor(UD60x18.wrap(inputs[0])));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {UD60x18, frac} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpDecimal18FracNP
/// @notice Opcode for the frac of an decimal 18 fixed point number.
library LibOpDecimal18FracNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be one input and one output.
        return (1, 1);
    }

    /// decimal18-frac
    /// 18 decimal fixed point frac of a number.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        assembly ("memory-safe") {
            a := mload(stackTop)
        }
        a = UD60x18.unwrap(frac(UD60x18.wrap(a)));

        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of frac for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = UD60x18.unwrap(frac(UD60x18.wrap(inputs[0])));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {UD60x18, gm} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpDecimal18GmNP
/// @notice Opcode for the geometric average of two decimal 18 fixed point
/// numbers.
library LibOpDecimal18GmNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be two inputs and one output.
        return (2, 1);
    }

    /// decimal18-gm
    /// 18 decimal fixed point geometric average of two numbers.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        uint256 b;
        assembly ("memory-safe") {
            a := mload(stackTop)
            stackTop := add(stackTop, 0x20)
            b := mload(stackTop)
        }
        a = UD60x18.unwrap(gm(UD60x18.wrap(a), UD60x18.wrap(b)));

        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of gm for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = UD60x18.unwrap(gm(UD60x18.wrap(inputs[0]), UD60x18.wrap(inputs[1])));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {UD60x18, frac} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpDecimal18HeadroomNP
/// @notice Opcode for the headroom (distance to ceil) of an decimal 18 fixed
/// point number.
library LibOpDecimal18HeadroomNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be one input and one output.
        return (1, 1);
    }

    /// decimal18-headroom
    /// 18 decimal fixed point headroom of a number.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        assembly ("memory-safe") {
            a := mload(stackTop)
        }
        // Can't underflow as frac is always less than 1e18.
        unchecked {
            a = 1e18 - UD60x18.unwrap(frac(UD60x18.wrap(a)));
        }

        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of headroom for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = 1e18 - UD60x18.unwrap(frac(UD60x18.wrap(inputs[0])));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {UD60x18, inv} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpDecimal18InvNP
/// @notice Opcode for the inverse 1 / x of an decimal 18 fixed point number.
library LibOpDecimal18InvNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be one inputs and one output.
        return (1, 1);
    }

    /// decimal18-inv
    /// 18 decimal fixed point inverse of a number.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        assembly ("memory-safe") {
            a := mload(stackTop)
        }
        a = UD60x18.unwrap(inv(UD60x18.wrap(a)));

        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of inv for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = UD60x18.unwrap(inv(UD60x18.wrap(inputs[0])));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {UD60x18, ln} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpDecimal18LnNP
/// @notice Opcode for the natural logarithm of an decimal 18 fixed point number.
library LibOpDecimal18LnNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be one inputs and one output.
        return (1, 1);
    }

    /// decimal18-ln
    /// 18 decimal fixed point natural logarithm of a number.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        assembly ("memory-safe") {
            a := mload(stackTop)
        }
        a = UD60x18.unwrap(ln(UD60x18.wrap(a)));

        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of ln for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = UD60x18.unwrap(ln(UD60x18.wrap(inputs[0])));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {UD60x18, log10} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpDecimal18Log10NP
/// @notice Opcode for the common logarithm of an decimal 18 fixed point number.
library LibOpDecimal18Log10NP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be one inputs and one output.
        return (1, 1);
    }

    /// decimal18-log10
    /// 18 decimal fixed point common logarithm of a number.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        assembly ("memory-safe") {
            a := mload(stackTop)
        }
        a = UD60x18.unwrap(log10(UD60x18.wrap(a)));

        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of log10 for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = UD60x18.unwrap(log10(UD60x18.wrap(inputs[0])));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {UD60x18, log2} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpDecimal18Log2NP
/// @notice Opcode for the binary logarithm of an decimal 18 fixed point number.
library LibOpDecimal18Log2NP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be one inputs and one output.
        return (1, 1);
    }

    /// decimal18-log2
    /// 18 decimal fixed point binary logarithm of a number.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        assembly ("memory-safe") {
            a := mload(stackTop)
        }
        a = UD60x18.unwrap(log2(UD60x18.wrap(a)));

        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of log2 for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = UD60x18.unwrap(log2(UD60x18.wrap(inputs[0])));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {UD60x18, pow} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpDecimal18PowNP
/// @notice Opcode to pow N 18 decimal fixed point values to an 18 decimal power.
library LibOpDecimal18PowNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be two inputs and one output.
        return (2, 1);
    }

    /// decimal18-pow
    /// 18 decimal fixed point exponentiation with implied overflow checks from
    /// PRB Math.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        uint256 b;
        assembly ("memory-safe") {
            a := mload(stackTop)
            stackTop := add(stackTop, 0x20)
            b := mload(stackTop)
        }
        a = UD60x18.unwrap(pow(UD60x18.wrap(a), UD60x18.wrap(b)));

        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of pow for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = UD60x18.unwrap(pow(UD60x18.wrap(inputs[0]), UD60x18.wrap(inputs[1])));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {UD60x18, powu} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpDecimal18PowUNP
/// @notice Opcode to pow N 18 decimal fixed point values to a uint256 power.
library LibOpDecimal18PowUNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be two inputs and one output.
        return (2, 1);
    }

    /// decimal18-pow-u
    /// 18 decimal fixed point exponentiation with implied overflow checks from
    /// PRB Math.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        uint256 b;
        assembly ("memory-safe") {
            a := mload(stackTop)
            stackTop := add(stackTop, 0x20)
            b := mload(stackTop)
        }
        a = UD60x18.unwrap(powu(UD60x18.wrap(a), b));

        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of powu for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = UD60x18.unwrap(powu(UD60x18.wrap(inputs[0]), inputs[1]));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {LibFixedPointDecimalScale} from "rain.math.fixedpoint/lib/LibFixedPointDecimalScale.sol";
import {MASK_2BIT} from "sol.lib.binmaskflag/Binary.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";

/// @title LibOpDecimal18Scale18DynamicNP
/// @notice Opcode for scaling a number to 18 decimal fixed point based on
/// runtime scale input.
library LibOpDecimal18Scale18DynamicNP {
    using LibFixedPointDecimalScale for uint256;

    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        return (2, 1);
    }

    /// decimal18-scale-18-dynamic
    /// 18 decimal fixed point scaling from runtime value.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        uint256 scale;
        assembly ("memory-safe") {
            scale := mload(stackTop)
            stackTop := add(stackTop, 0x20)
            a := mload(stackTop)
        }
        a = a.scale18(scale, Operand.unwrap(operand));
        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory, Operand operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        outputs = new uint256[](1);
        outputs[0] = inputs[1].scale18(inputs[0], Operand.unwrap(operand) & MASK_2BIT);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {LibFixedPointDecimalScale} from "rain.math.fixedpoint/lib/LibFixedPointDecimalScale.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";

/// @title LibOpDecimal18Scale18NP
/// @notice Opcode for scaling a number to 18 decimal fixed point.
library LibOpDecimal18Scale18NP {
    using LibFixedPointDecimalScale for uint256;

    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        return (1, 1);
    }

    /// decimal18-scale-18
    /// 18 decimal fixed point scaling.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        assembly ("memory-safe") {
            a := mload(stackTop)
        }
        a = a.scale18(Operand.unwrap(operand) & 0xFF, Operand.unwrap(operand) >> 8);
        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory, Operand operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        outputs = new uint256[](1);
        outputs[0] = inputs[0].scale18(Operand.unwrap(operand) & 0xFF, Operand.unwrap(operand) >> 8);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {LibFixedPointDecimalScale} from "rain.math.fixedpoint/lib/LibFixedPointDecimalScale.sol";
import {MASK_2BIT} from "sol.lib.binmaskflag/Binary.sol";

/// @title LibOpDecimal18ScaleNDynamicNP
/// @notice Opcode for scaling a number from 18 decimal fixed point based on
/// runtime scale input.
library LibOpDecimal18ScaleNDynamicNP {
    using LibFixedPointDecimalScale for uint256;

    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        return (2, 1);
    }

    /// decimal18-scaleN-dynamic
    /// 18 decimal fixed point scaling from runtime value.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        uint256 scale;
        assembly ("memory-safe") {
            scale := mload(stackTop)
            stackTop := add(stackTop, 0x20)
            a := mload(stackTop)
        }
        a = a.scaleN(scale, Operand.unwrap(operand) & MASK_2BIT);
        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory, Operand operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        outputs = new uint256[](1);
        outputs[0] = inputs[1].scaleN(inputs[0], Operand.unwrap(operand) & MASK_2BIT);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {LibFixedPointDecimalScale} from "rain.math.fixedpoint/lib/LibFixedPointDecimalScale.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";

/// @title LibOpDecimal18ScaleNNP
/// @notice Opcode for scaling a decimal18 number to some other scale N.
library LibOpDecimal18ScaleNNP {
    using LibFixedPointDecimalScale for uint256;

    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        return (1, 1);
    }

    /// decimal18-scale-n
    /// Scale from 18 decimal to n decimal.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        assembly ("memory-safe") {
            a := mload(stackTop)
        }
        a = a.scaleN(Operand.unwrap(operand) & 0xFF, Operand.unwrap(operand) >> 8);
        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory, Operand operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        outputs = new uint256[](1);
        outputs[0] = inputs[0].scaleN(Operand.unwrap(operand) & 0xFF, Operand.unwrap(operand) >> 8);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {UD60x18, frac, ceil, floor} from "prb-math/UD60x18.sol";

/// @title LibOpDecimal18SnapToUnitNP
/// @notice Opcode for the snap to unit of an decimal 18 fixed point number.
library LibOpDecimal18SnapToUnitNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be two inputs and one output.
        return (2, 1);
    }

    /// decimal18-snap-to-unit
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        unchecked {
            uint256 threshold;
            uint256 value;
            assembly ("memory-safe") {
                threshold := mload(stackTop)
                stackTop := add(stackTop, 0x20)
                value := mload(stackTop)
            }
            uint256 valueFrac = UD60x18.unwrap(frac(UD60x18.wrap(value)));
            if (valueFrac <= threshold) {
                value = UD60x18.unwrap(floor(UD60x18.wrap(value)));
                assembly ("memory-safe") {
                    mstore(stackTop, value)
                }
            }
            // Frac cannot be more than 1e18, so we can safely subtract it from 1e18
            // as unchecked.
            else if ((1e18 - valueFrac) <= threshold) {
                value = UD60x18.unwrap(ceil(UD60x18.wrap(value)));
                assembly ("memory-safe") {
                    mstore(stackTop, value)
                }
            }
            return stackTop;
        }
    }

    /// Gas intensive reference implementation of snap-to-unit for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        uint256 threshold = inputs[0];
        uint256 value = inputs[1];
        uint256 valueFrac = UD60x18.unwrap(frac(UD60x18.wrap(value)));
        if (valueFrac <= threshold) {
            value = UD60x18.unwrap(floor(UD60x18.wrap(value)));
            outputs[0] = value;
        } else if ((1e18 - valueFrac) <= threshold) {
            value = UD60x18.unwrap(ceil(UD60x18.wrap(value)));
            outputs[0] = value;
        } else {
            outputs[0] = value;
        }
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {UD60x18, sqrt} from "prb-math/UD60x18.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpDecimal18SqrtNP
/// @notice Opcode for the square root of an decimal 18 fixed point number.
library LibOpDecimal18SqrtNP {
    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // There must be one inputs and one output.
        return (1, 1);
    }

    /// decimal18-sqrt
    /// 18 decimal fixed point square root of a number.
    function run(InterpreterStateNP memory, Operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        assembly ("memory-safe") {
            a := mload(stackTop)
        }
        a = UD60x18.unwrap(sqrt(UD60x18.wrap(a)));

        assembly ("memory-safe") {
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of sqrt for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory outputs = new uint256[](1);
        outputs[0] = UD60x18.unwrap(sqrt(UD60x18.wrap(inputs[0])));
        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpIntAddNP
/// @notice Opcode to add N integers. Errors on overflow.
library LibOpIntAddNP {
    function integrity(IntegrityCheckStateNP memory, Operand operand) internal pure returns (uint256, uint256) {
        // There must be at least two inputs.
        uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
        inputs = inputs > 1 ? inputs : 2;
        return (inputs, 1);
    }

    /// int-add
    /// Addition with implied overflow checks from the Solidity 0.8.x compiler.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        uint256 b;
        assembly ("memory-safe") {
            a := mload(stackTop)
            b := mload(add(stackTop, 0x20))
            stackTop := add(stackTop, 0x40)
        }
        a += b;

        {
            uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
            uint256 i = 2;
            while (i < inputs) {
                assembly ("memory-safe") {
                    b := mload(stackTop)
                    stackTop := add(stackTop, 0x20)
                }
                a += b;
                unchecked {
                    i++;
                }
            }
        }

        assembly ("memory-safe") {
            stackTop := sub(stackTop, 0x20)
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of addition for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        // Unchecked so that when we assert that an overflow error is thrown, we
        // see the revert from the real function and not the reference function.
        unchecked {
            uint256 acc = inputs[0];
            for (uint256 i = 1; i < inputs.length; i++) {
                acc += inputs[i];
            }
            outputs = new uint256[](1);
            outputs[0] = acc;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";

/// @title LibOpIntDivNP
/// @notice Opcode to divide N integers. Errors on divide by zero. Truncates
/// towards zero.
library LibOpIntDivNP {
    function integrity(IntegrityCheckStateNP memory, Operand operand) internal pure returns (uint256, uint256) {
        // There must be at least two inputs.
        uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
        inputs = inputs > 1 ? inputs : 2;
        return (inputs, 1);
    }

    /// int-div
    /// Division with implied checks from the Solidity 0.8.x compiler.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        uint256 b;
        assembly ("memory-safe") {
            a := mload(stackTop)
            b := mload(add(stackTop, 0x20))
            stackTop := add(stackTop, 0x40)
        }
        a /= b;

        {
            uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
            uint256 i = 2;
            while (i < inputs) {
                assembly ("memory-safe") {
                    b := mload(stackTop)
                    stackTop := add(stackTop, 0x20)
                }
                a /= b;
                unchecked {
                    i++;
                }
            }
        }

        assembly ("memory-safe") {
            stackTop := sub(stackTop, 0x20)
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of division for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        // Unchecked so that when we assert that an overflow error is thrown, we
        // see the revert from the real function and not the reference function.
        unchecked {
            uint256 acc = inputs[0];
            for (uint256 i = 1; i < inputs.length; i++) {
                acc /= inputs[i];
            }
            outputs = new uint256[](1);
            outputs[0] = acc;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpIntExpNP
/// @notice Opcode to raise x successively to N integers. Errors on overflow.
library LibOpIntExpNP {
    function integrity(IntegrityCheckStateNP memory, Operand operand) internal pure returns (uint256, uint256) {
        // There must be at least two inputs.
        uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
        inputs = inputs > 1 ? inputs : 2;
        return (inputs, 1);
    }

    /// int-exp
    /// Exponentiation with implied overflow checks from the Solidity 0.8.x
    /// compiler.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        uint256 b;
        assembly ("memory-safe") {
            a := mload(stackTop)
            b := mload(add(stackTop, 0x20))
            stackTop := add(stackTop, 0x40)
        }
        a = a ** b;

        {
            uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
            uint256 i = 2;
            while (i < inputs) {
                assembly ("memory-safe") {
                    b := mload(stackTop)
                    stackTop := add(stackTop, 0x20)
                }
                a = a ** b;
                unchecked {
                    i++;
                }
            }
        }
        assembly ("memory-safe") {
            stackTop := sub(stackTop, 0x20)
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of exponentiation for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        // Unchecked so that when we assert that an overflow error is thrown, we
        // see the revert from the real function and not the reference function.
        unchecked {
            uint256 acc = inputs[0];
            for (uint256 i = 1; i < inputs.length; i++) {
                acc = acc ** inputs[i];
            }
            outputs = new uint256[](1);
            outputs[0] = acc;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpIntMaxNP
/// @notice Opcode to find the max from N integers.
library LibOpIntMaxNP {
    function integrity(IntegrityCheckStateNP memory, Operand operand) internal pure returns (uint256, uint256) {
        // There must be at least two inputs.
        uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
        inputs = inputs > 1 ? inputs : 2;
        return (inputs, 1);
    }

    /// int-max
    /// Finds the maximum value from N integers.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        uint256 b;
        assembly ("memory-safe") {
            a := mload(stackTop)
            b := mload(add(stackTop, 0x20))
            stackTop := add(stackTop, 0x40)
        }
        if (a < b) {
            a = b;
        }

        {
            uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
            uint256 i = 2;
            while (i < inputs) {
                assembly ("memory-safe") {
                    b := mload(stackTop)
                    stackTop := add(stackTop, 0x20)
                }
                if (a < b) {
                    a = b;
                }
                unchecked {
                    i++;
                }
            }
        }

        assembly ("memory-safe") {
            stackTop := sub(stackTop, 0x20)
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of maximum for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        // Unchecked so that when we assert that an overflow error is thrown, we
        // see the revert from the real function and not the reference function.
        unchecked {
            uint256 acc = inputs[0];
            for (uint256 i = 1; i < inputs.length; i++) {
                acc = acc < inputs[i] ? inputs[i] : acc;
            }
            outputs = new uint256[](1);
            outputs[0] = acc;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpIntMinNP
/// @notice Opcode to find the min from N integers.
library LibOpIntMinNP {
    function integrity(IntegrityCheckStateNP memory, Operand operand) internal pure returns (uint256, uint256) {
        // There must be at least two inputs.
        uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
        inputs = inputs > 1 ? inputs : 2;
        return (inputs, 1);
    }

    /// int-min
    /// Finds the minimum value from N integers.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        uint256 b;
        assembly ("memory-safe") {
            a := mload(stackTop)
            b := mload(add(stackTop, 0x20))
            stackTop := add(stackTop, 0x40)
        }
        if (a > b) {
            a = b;
        }

        {
            uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
            uint256 i = 2;
            while (i < inputs) {
                assembly ("memory-safe") {
                    b := mload(stackTop)
                    stackTop := add(stackTop, 0x20)
                }
                if (a > b) {
                    a = b;
                }
                unchecked {
                    i++;
                }
            }
        }

        assembly ("memory-safe") {
            stackTop := sub(stackTop, 0x20)
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of minimum for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        // Unchecked so that when we assert that an overflow error is thrown, we
        // see the revert from the real function and not the reference function.
        unchecked {
            uint256 acc = inputs[0];
            for (uint256 i = 1; i < inputs.length; i++) {
                acc = acc > inputs[i] ? inputs[i] : acc;
            }
            outputs = new uint256[](1);
            outputs[0] = acc;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer, LibPointer} from "rain.solmem/lib/LibPointer.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";

/// @title LibOpIntModNP
/// @notice Opcode to modulo N integers. Errors on modulo by zero.
library LibOpIntModNP {
    using LibPointer for Pointer;

    function integrity(IntegrityCheckStateNP memory, Operand operand) internal pure returns (uint256, uint256) {
        // There must be at least two inputs.
        uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
        inputs = inputs > 1 ? inputs : 2;
        return (inputs, 1);
    }

    /// int-mod
    /// Modulo with implied checks from the Solidity 0.8.x compiler.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        uint256 b;
        assembly ("memory-safe") {
            a := mload(stackTop)
            b := mload(add(stackTop, 0x20))
            stackTop := add(stackTop, 0x40)
        }
        a %= b;

        {
            uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
            uint256 i = 2;
            while (i < inputs) {
                assembly ("memory-safe") {
                    b := mload(stackTop)
                    stackTop := add(stackTop, 0x20)
                }
                a %= b;
                unchecked {
                    i++;
                }
            }
        }

        assembly ("memory-safe") {
            stackTop := sub(stackTop, 0x20)
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of modulo for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        // Unchecked so that when we assert that an overflow error is thrown, we
        // see the revert from the real function and not the reference function.
        unchecked {
            uint256 acc = inputs[0];
            for (uint256 i = 1; i < inputs.length; i++) {
                acc %= inputs[i];
            }
            outputs = new uint256[](1);
            outputs[0] = acc;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";

/// @title LibOpIntMulNP
/// @notice Opcode to mul N integers. Errors on overflow.
library LibOpIntMulNP {
    function integrity(IntegrityCheckStateNP memory, Operand operand) internal pure returns (uint256, uint256) {
        // There must be at least two inputs.
        uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
        inputs = inputs > 1 ? inputs : 2;
        return (inputs, 1);
    }

    /// int-mul
    /// Multiplication with implied overflow checks from the Solidity 0.8.x
    /// compiler.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        uint256 b;
        assembly ("memory-safe") {
            a := mload(stackTop)
            b := mload(add(stackTop, 0x20))
            stackTop := add(stackTop, 0x40)
        }
        a *= b;

        {
            uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
            uint256 i = 2;
            while (i < inputs) {
                assembly ("memory-safe") {
                    b := mload(stackTop)
                    stackTop := add(stackTop, 0x20)
                }
                a *= b;
                unchecked {
                    i++;
                }
            }
        }
        assembly ("memory-safe") {
            stackTop := sub(stackTop, 0x20)
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of multiplication for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        // Unchecked so that when we assert that an overflow error is thrown, we
        // see the revert from the real function and not the reference function.
        unchecked {
            uint256 acc = inputs[0];
            for (uint256 i = 1; i < inputs.length; i++) {
                acc *= inputs[i];
            }
            outputs = new uint256[](1);
            outputs[0] = acc;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {IntegrityCheckStateNP} from "../../../integrity/LibIntegrityCheckNP.sol";
import {InterpreterStateNP} from "../../../state/LibInterpreterStateNP.sol";
import {SaturatingMath} from "rain.math.saturating/SaturatingMath.sol";

/// @title LibOpIntSubNP
/// @notice Opcode to subtract N integers.
library LibOpIntSubNP {
    function integrity(IntegrityCheckStateNP memory, Operand operand) internal pure returns (uint256, uint256) {
        // There must be at least two inputs.
        uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
        inputs = inputs > 1 ? inputs : 2;
        return (inputs, 1);
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /// int-sub
    /// Subtraction with implied overflow checks from the Solidity 0.8.x compiler.
    function run(InterpreterStateNP memory, Operand operand, Pointer stackTop) internal pure returns (Pointer) {
        uint256 a;
        uint256 b;
        uint256 saturate;
        assembly ("memory-safe") {
            a := mload(stackTop)
            b := mload(add(stackTop, 0x20))
            stackTop := add(stackTop, 0x40)
            saturate := and(operand, 1)
        }
        function (uint256, uint256) internal pure returns (uint256) f =
            saturate > 0 ? SaturatingMath.saturatingSub : sub;
        a = f(a, b);

        {
            uint256 inputs = (Operand.unwrap(operand) >> 0x10) & 0x0F;
            uint256 i = 2;
            while (i < inputs) {
                assembly ("memory-safe") {
                    b := mload(stackTop)
                    stackTop := add(stackTop, 0x20)
                }
                a = f(a, b);
                unchecked {
                    i++;
                }
            }
        }

        assembly ("memory-safe") {
            stackTop := sub(stackTop, 0x20)
            mstore(stackTop, a)
        }
        return stackTop;
    }

    /// Gas intensive reference implementation of subtraction for testing.
    function referenceFn(InterpreterStateNP memory, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory outputs)
    {
        // Unchecked so that when we assert that an overflow error is thrown, we
        // see the revert from the real function and not the reference function.
        unchecked {
            uint256 acc = inputs[0];
            for (uint256 i = 1; i < inputs.length; i++) {
                acc -= inputs[i];
            }
            outputs = new uint256[](1);
            outputs[0] = acc;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {MemoryKVKey, MemoryKVVal, MemoryKV, LibMemoryKV} from "rain.lib.memkv/lib/LibMemoryKV.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";

/// @title LibOpGetNP
/// @notice Opcode for reading from storage.
library LibOpGetNP {
    using LibMemoryKV for MemoryKV;

    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // Always 1 input. The key. `hash()` is recommended to build compound
        // keys.
        return (1, 1);
    }

    /// Implements runtime behaviour of the `get` opcode. Attempts to lookup the
    /// key in the memory key/value store then falls back to the interpreter's
    /// storage interface as an external call. If the key is not found in either,
    /// the value will fallback to `0` as per default Solidity/EVM behaviour.
    /// @param state The interpreter state of the current eval.
    /// @param stackTop Pointer to the current stack top.
    function run(InterpreterStateNP memory state, Operand, Pointer stackTop) internal view returns (Pointer) {
        uint256 key;
        assembly ("memory-safe") {
            key := mload(stackTop)
        }
        (uint256 exists, MemoryKVVal value) = state.stateKV.get(MemoryKVKey.wrap(key));

        // Cache MISS, get from external store.
        if (exists == 0) {
            uint256 storeValue = state.store.get(state.namespace, key);

            // Push fetched value to memory to make subsequent lookups on the
            // same key find a cache HIT.
            state.stateKV = state.stateKV.set(MemoryKVKey.wrap(key), MemoryKVVal.wrap(storeValue));

            assembly ("memory-safe") {
                mstore(stackTop, storeValue)
            }
        }
        // Cache HIT.
        else {
            assembly ("memory-safe") {
                mstore(stackTop, value)
            }
        }

        return stackTop;
    }

    function referenceFn(InterpreterStateNP memory state, Operand, uint256[] memory inputs)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 key = inputs[0];
        (uint256 exists, MemoryKVVal value) = state.stateKV.get(MemoryKVKey.wrap(key));
        uint256[] memory outputs = new uint256[](1);
        // Cache MISS, get from external store.
        if (exists == 0) {
            uint256 storeValue = state.store.get(state.namespace, key);

            // Push fetched value to memory to make subsequent lookups on the
            // same key find a cache HIT.
            state.stateKV = state.stateKV.set(MemoryKVKey.wrap(key), MemoryKVVal.wrap(storeValue));

            outputs[0] = storeValue;
        }
        // Cache HIT.
        else {
            outputs[0] = MemoryKVVal.unwrap(value);
        }

        return outputs;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {MemoryKV, MemoryKVKey, MemoryKVVal, LibMemoryKV} from "rain.lib.memkv/lib/LibMemoryKV.sol";
import {IntegrityCheckStateNP} from "../../integrity/LibIntegrityCheckNP.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {InterpreterStateNP} from "../../state/LibInterpreterStateNP.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";

/// @title LibOpSetNP
/// @notice Opcode for recording k/v state changes to be set in storage.
library LibOpSetNP {
    using LibMemoryKV for MemoryKV;

    function integrity(IntegrityCheckStateNP memory, Operand) internal pure returns (uint256, uint256) {
        // Always 2 inputs. The key and the value. `hash()` is recommended to
        // build compound keys.
        return (2, 0);
    }

    function run(InterpreterStateNP memory state, Operand, Pointer stackTop) internal pure returns (Pointer) {
        unchecked {
            uint256 key;
            uint256 value;
            assembly ("memory-safe") {
                key := mload(stackTop)
                value := mload(add(stackTop, 0x20))
                stackTop := add(stackTop, 0x40)
            }

            state.stateKV = state.stateKV.set(MemoryKVKey.wrap(key), MemoryKVVal.wrap(value));
            return stackTop;
        }
    }

    function referenceFn(InterpreterStateNP memory state, Operand, uint256[] memory inputs)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 key = inputs[0];
        uint256 value = inputs[1];
        state.stateKV = state.stateKV.set(MemoryKVKey.wrap(key), MemoryKVVal.wrap(value));
        return new uint256[](0);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {
    CMASK_E_NOTATION,
    CMASK_HEX,
    CMASK_LOWER_ALPHA_A_F,
    CMASK_NUMERIC_0_9,
    CMASK_STRING_LITERAL_HEAD,
    CMASK_UPPER_ALPHA_A_F,
    CMASK_LITERAL_HEX_DISPATCH,
    CMASK_NUMERIC_LITERAL_HEAD,
    CMASK_SUB_PARSEABLE_LITERAL_HEAD,
    CMASK_SUB_PARSEABLE_LITERAL_END,
    CMASK_WHITESPACE
} from "../LibParseCMask.sol";
import {LibParse} from "../LibParse.sol";

import {
    DecimalLiteralOverflow,
    HexLiteralOverflow,
    MalformedExponentDigits,
    MalformedHexLiteral,
    OddLengthHexLiteral,
    ZeroLengthDecimal,
    ZeroLengthHexLiteral,
    UnsupportedLiteralType,
    UnclosedSubParseableLiteral
} from "../../../error/ErrParse.sol";
import {ParseState} from "../LibParseState.sol";
import {LibParseError} from "../LibParseError.sol";
import {LibParseInterstitial} from "../LibParseInterstitial.sol";
import {LibSubParse} from "../LibSubParse.sol";

uint256 constant LITERAL_PARSERS_LENGTH = 4;

uint256 constant LITERAL_PARSER_INDEX_HEX = 0;
uint256 constant LITERAL_PARSER_INDEX_DECIMAL = 1;
uint256 constant LITERAL_PARSER_INDEX_STRING = 2;
uint256 constant LITERAL_PARSER_INDEX_SUB_PARSE = 3;

library LibParseLiteral {
    using LibParseLiteral for ParseState;
    using LibParseError for ParseState;
    using LibParseLiteral for ParseState;
    using LibParseInterstitial for ParseState;
    using LibSubParse for ParseState;

    function selectLiteralParserByIndex(ParseState memory state, uint256 index)
        internal
        pure
        returns (function(ParseState memory, uint256, uint256) pure returns (uint256, uint256))
    {
        bytes memory literalParsers = state.literalParsers;
        function(ParseState memory, uint256, uint256) pure returns (uint256, uint256) parser;
        // This is NOT bounds checked because the indexes are all expected to
        // be provided by the parser itself and not user input.
        assembly ("memory-safe") {
            parser := and(mload(add(literalParsers, add(2, mul(index, 2)))), 0xFFFF)
        }
        return parser;
    }

    function parseLiteral(ParseState memory state, uint256 cursor, uint256 end)
        internal
        pure
        returns (uint256, uint256)
    {
        (bool success, uint256 newCursor, uint256 value) = tryParseLiteral(state, cursor, end);
        if (success) {
            return (newCursor, value);
        } else {
            revert UnsupportedLiteralType(state.parseErrorOffset(cursor));
        }
    }

    function tryParseLiteral(ParseState memory state, uint256 cursor, uint256 end)
        internal
        pure
        returns (bool, uint256, uint256)
    {
        uint256 index;
        {
            uint256 word;
            uint256 head;
            assembly ("memory-safe") {
                word := mload(cursor)
                //slither-disable-next-line incorrect-shift
                head := shl(byte(0, word), 1)
            }

            // Figure out the literal type and dispatch to the correct parser.
            // Probably a numeric, most things are.
            if ((head & CMASK_NUMERIC_LITERAL_HEAD) != 0) {
                uint256 disambiguate;
                assembly ("memory-safe") {
                    //slither-disable-next-line incorrect-shift
                    disambiguate := shl(byte(1, word), 1)
                }
                // Hexadecimal literal dispatch is 0x. We can't accidentally
                // match x0 because we already checked that the head is 0-9.
                if ((head | disambiguate) == CMASK_LITERAL_HEX_DISPATCH) {
                    index = LITERAL_PARSER_INDEX_HEX;
                } else {
                    index = LITERAL_PARSER_INDEX_DECIMAL;
                }
            }
            // Could be a lil' string.
            else if ((head & CMASK_STRING_LITERAL_HEAD) != 0) {
                index = LITERAL_PARSER_INDEX_STRING;
            }
            // Or a sub parseable something.
            else if ((head & CMASK_SUB_PARSEABLE_LITERAL_HEAD) != 0) {
                index = LITERAL_PARSER_INDEX_SUB_PARSE;
            }
            // We don't know what this is.
            else {
                return (false, cursor, 0);
            }
        }
        uint256 value;
        (cursor, value) = state.selectLiteralParserByIndex(index)(state, cursor, end);
        return (true, cursor, value);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {ParseState} from "../LibParseState.sol";
import {IntOrAString, LibIntOrAString} from "rain.intorastring/src/lib/LibIntOrAString.sol";
import {UnclosedStringLiteral, StringTooLong} from "../../../error/ErrParse.sol";
import {CMASK_STRING_LITERAL_END, CMASK_STRING_LITERAL_TAIL} from "../LibParseCMask.sol";
import {LibParseError} from "../LibParseError.sol";

/// @title LibParseLiteralString
/// @notice A library for parsing string literals.
library LibParseLiteralString {
    using LibParseError for ParseState;
    using LibParseLiteralString for ParseState;

    /// Find the bounds for some string literal at the cursor. The caller is
    /// responsible for checking that the cursor is at the start of a string
    /// literal. Bounds are as per `boundLiteral`.
    function boundString(ParseState memory state, uint256 cursor, uint256 end)
        internal
        pure
        returns (uint256, uint256, uint256)
    {
        unchecked {
            uint256 innerStart = cursor + 1;
            uint256 innerEnd;
            uint256 outerEnd;
            {
                uint256 stringCharMask = CMASK_STRING_LITERAL_TAIL;
                uint256 stringData;
                uint256 i = 0;
                assembly ("memory-safe") {
                    let distanceFromEnd := sub(end, innerStart)
                    let max := 0x20
                    if lt(distanceFromEnd, 0x20) { max := distanceFromEnd }

                    // Only up to 31 bytes of string data can be stored in a
                    // single word, so strings can't be longer than 31 bytes.
                    // The 32nd byte is the length of the string.
                    stringData := mload(innerStart)
                    //slither-disable-next-line incorrect-shift
                    for {} and(lt(i, max), iszero(iszero(and(shl(byte(i, stringData), 1), stringCharMask)))) {} {
                        i := add(i, 1)
                    }
                }
                if (i == 0x20) {
                    revert StringTooLong(state.parseErrorOffset(cursor));
                }
                innerEnd = innerStart + i;
                uint256 finalChar;
                assembly ("memory-safe") {
                    finalChar := byte(0, mload(innerEnd))
                }

                // End can't equal inner end, because then we would move past the
                // end of the data considering the final " character.
                //slither-disable-next-line incorrect-shift
                if (1 << finalChar & CMASK_STRING_LITERAL_END == 0 || end == innerEnd) {
                    revert UnclosedStringLiteral(state.parseErrorOffset(innerEnd));
                }
                // Outer end is after the final `"`.
                outerEnd = innerEnd + 1;
            }

            return (innerStart, innerEnd, outerEnd);
        }
    }

    /// Algorithm for parsing string literals:
    /// - Get the inner length of the string
    /// - Mutate memory in place to add a length prefix, record the original data
    /// - Use this solidity string to build an `IntOrAString`
    /// - Restore the original data that the length prefix overwrote
    /// - Return the `IntOrAString`
    function parseString(ParseState memory state, uint256 cursor, uint256 end)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 stringStart;
        uint256 stringEnd;
        (stringStart, stringEnd, cursor) = state.boundString(cursor, end);
        IntOrAString intOrAString;

        uint256 memSnapshot;
        string memory str;
        assembly ("memory-safe") {
            let length := sub(stringEnd, stringStart)
            str := sub(stringStart, 0x20)
            memSnapshot := mload(str)
            mstore(str, length)
        }
        intOrAString = LibIntOrAString.fromString(str);
        assembly ("memory-safe") {
            mstore(str, memSnapshot)
        }
        return (cursor, IntOrAString.unwrap(intOrAString));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {ParseState} from "../LibParseState.sol";
import {DecimalLiteralOverflow, ZeroLengthDecimal, MalformedExponentDigits} from "../../../error/ErrParse.sol";
import {CMASK_E_NOTATION, CMASK_NUMERIC_0_9} from "../LibParseCMask.sol";
import {LibParseError} from "../LibParseError.sol";

library LibParseLiteralDecimal {
    using LibParseError for ParseState;
    using LibParseLiteralDecimal for ParseState;

    function boundDecimal(ParseState memory state, uint256 cursor, uint256 end)
        internal
        pure
        returns (uint256, uint256, uint256)
    {
        uint256 innerStart = cursor;
        uint256 innerEnd = innerStart;
        uint256 ePosition = 0;
        uint256 eExists = 0;

        {
            uint256 decimalCharMask = CMASK_NUMERIC_0_9;
            uint256 eMask = CMASK_E_NOTATION;
            assembly ("memory-safe") {
                //slither-disable-next-line incorrect-shift
                for {} and(iszero(iszero(and(shl(byte(0, mload(innerEnd)), 1), decimalCharMask))), lt(innerEnd, end)) {}
                {
                    innerEnd := add(innerEnd, 1)
                }

                // If we're now pointing at an e notation, then we need
                // to move past it. Negative exponents are not supported.
                //slither-disable-next-line incorrect-shift
                if and(iszero(iszero(and(shl(byte(0, mload(innerEnd)), 1), eMask))), lt(innerEnd, end)) {
                    ePosition := innerEnd
                    innerEnd := add(innerEnd, 1)
                    eExists := 1

                    // Move past the exponent digits.
                    //slither-disable-next-line incorrect-shift
                    for {} and(
                        iszero(iszero(and(shl(byte(0, mload(innerEnd)), 1), decimalCharMask))), lt(innerEnd, end)
                    ) {} { innerEnd := add(innerEnd, 1) }
                }
            }
        }
        if (
            (ePosition != 0 && (innerEnd > ePosition + 3 || innerEnd == ePosition + 1))
            // if e is found at the start of the literal, with no digits before
            // it that is malformed.
            || (ePosition == innerStart && eExists == 1)
        ) {
            revert MalformedExponentDigits(state.parseErrorOffset(ePosition));
        }

        return (innerStart, innerEnd, innerEnd);
    }

    /// Algorithm for parsing decimal literals:
    /// - start at the end of the literal
    /// - for each digit:
    ///   - multiply the digit by 10^digit position
    ///   - add the result to the total
    /// - return the total
    ///
    /// This algorithm is ONLY safe if the caller has already checked that the
    /// start/end span a non-zero length of valid decimal chars. The caller
    /// can most easily do this by using the `boundLiteral` function.
    ///
    /// Unsafe behavior is undefined and can easily result in out of bounds
    /// reads as there are no checks that start/end are within `data`.
    function parseDecimal(ParseState memory state, uint256 cursor, uint256 end)
        internal
        pure
        returns (uint256, uint256)
    {
        unchecked {
            uint256 value;
            // The ASCII byte can be translated to a numeric digit by subtracting
            // the digit offset.
            uint256 digitOffset = uint256(uint8(bytes1("0")));
            // Tracks the exponent of the current digit. Can start above 0 if
            // the literal is in e notation.
            uint256 exponent;
            (uint256 decimalStart, uint256 decimalEnd, uint256 outerEnd) = state.boundDecimal(cursor, end);
            {
                uint256 word;
                //slither-disable-next-line similar-names
                uint256 decimalCharByte;
                uint256 decimalLength = decimalEnd - decimalStart;
                assembly ("memory-safe") {
                    word := mload(sub(decimalEnd, 3))
                    decimalCharByte := byte(0, word)
                }
                // If the last 3 bytes are e notation, then we need to parse
                // the exponent as a 2 digit number.
                //slither-disable-next-line incorrect-shift
                if (decimalLength > 3 && ((1 << decimalCharByte) & CMASK_E_NOTATION) != 0) {
                    cursor = decimalEnd - 4;
                    assembly ("memory-safe") {
                        exponent := add(sub(byte(2, word), digitOffset), mul(sub(byte(1, word), digitOffset), 10))
                    }
                } else {
                    assembly ("memory-safe") {
                        decimalCharByte := byte(1, word)
                    }
                    // If the last 2 bytes are e notation, then we need to parse
                    // the exponent as a 1 digit number.
                    //slither-disable-next-line incorrect-shift
                    if (decimalLength > 2 && ((1 << decimalCharByte) & CMASK_E_NOTATION) != 0) {
                        cursor = decimalEnd - 3;
                        assembly ("memory-safe") {
                            exponent := sub(byte(2, word), digitOffset)
                        }
                    }
                    // Otherwise, we're not in e notation and we can start at the
                    // decimalEnd of the literal with 0 starting exponent.
                    else if (decimalLength > 0) {
                        cursor = decimalEnd - 1;
                        exponent = 0;
                    } else {
                        revert ZeroLengthDecimal(state.parseErrorOffset(decimalStart));
                    }
                }
            }

            // Anything under 10^77 is safe to raise to its power of 10 without
            // overflowing a uint256.
            while (cursor >= decimalStart && exponent < 77) {
                // We don't need to check the bounds of the byte because
                // we know it is a decimal literal as long as the bounds
                // are correct (calculated in `boundLiteral`).
                assembly ("memory-safe") {
                    value := add(value, mul(sub(byte(0, mload(cursor)), digitOffset), exp(10, exponent)))
                }
                exponent++;
                cursor--;
            }

            // If we didn't consume the entire literal, then we have
            // to check if the remaining digit is safe to multiply
            // by 10 without overflowing a uint256.
            if (cursor >= decimalStart) {
                {
                    uint256 digit;
                    assembly ("memory-safe") {
                        digit := sub(byte(0, mload(cursor)), digitOffset)
                    }
                    // If the digit is greater than 1, then we know that
                    // multiplying it by 10^77 will overflow a uint256.
                    if (digit > 1) {
                        revert DecimalLiteralOverflow(state.parseErrorOffset(cursor));
                    } else {
                        uint256 scaled = digit * (10 ** exponent);
                        if (value + scaled < value) {
                            revert DecimalLiteralOverflow(state.parseErrorOffset(cursor));
                        }
                        value += scaled;
                    }
                    cursor--;
                }

                {
                    // If we didn't consume the entire literal, then only
                    // leading zeros are allowed.
                    while (cursor >= decimalStart) {
                        //slither-disable-next-line similar-names
                        uint256 decimalCharByte;
                        assembly ("memory-safe") {
                            decimalCharByte := byte(0, mload(cursor))
                        }
                        if (decimalCharByte != uint256(uint8(bytes1("0")))) {
                            revert DecimalLiteralOverflow(state.parseErrorOffset(cursor));
                        }
                        cursor--;
                    }
                }
            }
            return (outerEnd, value);
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {ParseState} from "../LibParseState.sol";
import {
    MalformedHexLiteral,
    OddLengthHexLiteral,
    ZeroLengthHexLiteral,
    HexLiteralOverflow
} from "../../../error/ErrParse.sol";
import {CMASK_UPPER_ALPHA_A_F, CMASK_LOWER_ALPHA_A_F, CMASK_NUMERIC_0_9, CMASK_HEX} from "../LibParseCMask.sol";
import {LibParseError} from "../LibParseError.sol";

library LibParseLiteralHex {
    using LibParseLiteralHex for ParseState;
    using LibParseError for ParseState;

    function boundHex(ParseState memory, uint256 cursor, uint256 end)
        internal
        pure
        returns (uint256, uint256, uint256)
    {
        uint256 innerStart = cursor + 2;
        uint256 innerEnd = innerStart;
        {
            uint256 hexCharMask = CMASK_HEX;
            assembly ("memory-safe") {
                //slither-disable-next-line incorrect-shift
                for {} and(iszero(iszero(and(shl(byte(0, mload(innerEnd)), 1), hexCharMask))), lt(innerEnd, end)) {} {
                    innerEnd := add(innerEnd, 1)
                }
            }
        }

        return (innerStart, innerEnd, innerEnd);
    }

    /// Algorithm for parsing hexadecimal literals:
    /// - start at the end of the literal
    /// - for each character:
    ///   - convert the character to a nybble
    ///   - shift the nybble into the total at the correct position
    ///     (4 bits per nybble)
    /// - return the total
    function parseHex(ParseState memory state, uint256 cursor, uint256 end) internal pure returns (uint256, uint256) {
        unchecked {
            uint256 value;
            uint256 hexStart;
            uint256 hexEnd;
            (hexStart, hexEnd, cursor) = state.boundHex(cursor, end);

            uint256 hexLength = hexEnd - hexStart;
            if (hexLength > 0x40) {
                revert HexLiteralOverflow(state.parseErrorOffset(hexStart));
            } else if (hexLength == 0) {
                revert ZeroLengthHexLiteral(state.parseErrorOffset(hexStart));
            } else if (hexLength % 2 == 1) {
                revert OddLengthHexLiteral(state.parseErrorOffset(hexStart));
            } else {
                // Loop the cursor backwards over the hex string, we'll return
                // the hex end instead.
                cursor = hexEnd - 1;
                uint256 valueOffset = 0;
                while (cursor >= hexStart) {
                    uint256 hexCharByte;
                    assembly ("memory-safe") {
                        hexCharByte := byte(0, mload(cursor))
                    }
                    //slither-disable-next-line incorrect-shift
                    uint256 hexChar = 1 << hexCharByte;

                    uint256 nybble;
                    // 0-9
                    if (hexChar & CMASK_NUMERIC_0_9 != 0) {
                        nybble = hexCharByte - uint256(uint8(bytes1("0")));
                    }
                    // a-f
                    else if (hexChar & CMASK_LOWER_ALPHA_A_F != 0) {
                        nybble = hexCharByte - uint256(uint8(bytes1("a"))) + 10;
                    }
                    // A-F
                    else if (hexChar & CMASK_UPPER_ALPHA_A_F != 0) {
                        nybble = hexCharByte - uint256(uint8(bytes1("A"))) + 10;
                    } else {
                        revert MalformedHexLiteral(state.parseErrorOffset(cursor));
                    }

                    value |= nybble << valueOffset;
                    valueOffset += 4;
                    cursor--;
                }
            }

            return (hexEnd, value);
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {ParseState} from "../LibParseState.sol";
import {LibParse} from "../LibParse.sol";
import {UnclosedSubParseableLiteral, SubParseableMissingDispatch} from "../../../error/ErrParse.sol";
import {
    CMASK_WHITESPACE, CMASK_SUB_PARSEABLE_LITERAL_HEAD, CMASK_SUB_PARSEABLE_LITERAL_END
} from "../LibParseCMask.sol";
import {LibParseInterstitial} from "../LibParseInterstitial.sol";
import {LibParseError} from "../LibParseError.sol";
import {LibSubParse} from "../LibSubParse.sol";

library LibParseLiteralSubParseable {
    using LibParse for ParseState;
    using LibParseInterstitial for ParseState;
    using LibParseError for ParseState;
    using LibSubParse for ParseState;

    /// Parse a sub parseable literal. All sub parseable literals are bounded by
    /// square brackets, and contain a dispatch and a body. The dispatch is the
    /// string immediately following the opening bracket, and the body is the
    /// string immediately following the dispatch, up to the closing bracket.
    /// The dispatch and body MUST be separated by at least one whitespace char.
    /// This implies that the dispatch MAY NOT contain any whitespace chars, and
    /// the body MAY contain any chars except for the closing bracket.
    /// Leading and trailing whitespace before/after the dispatch/body is NOT
    /// supported. The former will error and the latter will be treated as part
    /// of the body.
    function parseSubParseable(ParseState memory state, uint256 cursor, uint256 end)
        internal
        pure
        returns (uint256, uint256)
    {
        unchecked {
            // Move cursor past opening bracket.
            // Caller is responsible for checking that the cursor is pointing
            // at a sub parseable literal.
            ++cursor;

            uint256 dispatchStart = cursor;

            // Skip all non-whitespace and non-bracket characters.
            cursor = LibParse.skipMask(cursor, end, ~(CMASK_WHITESPACE | CMASK_SUB_PARSEABLE_LITERAL_END));
            uint256 dispatchEnd = cursor;

            if (dispatchEnd == dispatchStart) {
                revert SubParseableMissingDispatch(state.parseErrorOffset(cursor));
            }

            // Skip any whitespace.
            cursor = state.skipWhitespace(cursor, end);

            uint256 bodyStart = cursor;

            // Skip all chars til the close.
            // Note that as multibyte is not supported, and the mask is 128 bits,
            // non-ascii chars MAY either fail to be skipped or will be treated
            // as a closing bracket.
            cursor = LibParse.skipMask(cursor, end, ~CMASK_SUB_PARSEABLE_LITERAL_END);
            uint256 bodyEnd = cursor;

            {
                uint256 finalChar;
                assembly ("memory-safe") {
                    //slither-disable-next-line incorrect-shift
                    finalChar := shl(byte(0, mload(cursor)), 1)
                }
                if ((finalChar & CMASK_SUB_PARSEABLE_LITERAL_END) == 0) {
                    revert UnclosedSubParseableLiteral(state.parseErrorOffset(cursor));
                }
            }

            // Move cursor past closing bracket.
            ++cursor;

            return (cursor, state.subParseLiteral(dispatchStart, dispatchEnd, bodyStart, bodyEnd));
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @dev Workaround for https://github.com/foundry-rs/foundry/issues/6572
contract LibParseCMask {}

/// @dev ASCII null
uint128 constant CMASK_NULL = uint128(1) << uint128(uint8(bytes1("\x00")));

/// @dev ASCII start of heading
uint128 constant CMASK_START_OF_HEADING = uint128(1) << uint128(uint8(bytes1("\x01")));

/// @dev ASCII start of text
uint128 constant CMASK_START_OF_TEXT = uint128(1) << uint128(uint8(bytes1("\x02")));

/// @dev ASCII end of text
uint128 constant CMASK_END_OF_TEXT = uint128(1) << uint128(uint8(bytes1("\x03")));

/// @dev ASCII end of transmission
uint128 constant CMASK_END_OF_TRANSMISSION = uint128(1) << uint128(uint8(bytes1("\x04")));

/// @dev ASCII enquiry
uint128 constant CMASK_ENQUIRY = uint128(1) << uint128(uint8(bytes1("\x05")));

/// @dev ASCII acknowledge
uint128 constant CMASK_ACKNOWLEDGE = uint128(1) << uint128(uint8(bytes1("\x06")));

/// @dev ASCII bell
uint128 constant CMASK_BELL = uint128(1) << uint128(uint8(bytes1("\x07")));

/// @dev ASCII backspace
uint128 constant CMASK_BACKSPACE = uint128(1) << uint128(uint8(bytes1("\x08")));

/// @dev ASCII horizontal tab
uint128 constant CMASK_HORIZONTAL_TAB = uint128(1) << uint128(uint8(bytes1("\t")));

/// @dev ASCII line feed
uint128 constant CMASK_LINE_FEED = uint128(1) << uint128(uint8(bytes1("\n")));

/// @dev ASCII vertical tab
uint128 constant CMASK_VERTICAL_TAB = uint128(1) << uint128(uint8(bytes1("\x0B")));

/// @dev ASCII form feed
uint128 constant CMASK_FORM_FEED = uint128(1) << uint128(uint8(bytes1("\x0C")));

/// @dev ASCII carriage return
uint128 constant CMASK_CARRIAGE_RETURN = uint128(1) << uint128(uint8(bytes1("\r")));

/// @dev ASCII shift out
uint128 constant CMASK_SHIFT_OUT = uint128(1) << uint128(uint8(bytes1("\x0E")));

/// @dev ASCII shift in
uint128 constant CMASK_SHIFT_IN = uint128(1) << uint128(uint8(bytes1("\x0F")));

/// @dev ASCII data link escape
uint128 constant CMASK_DATA_LINK_ESCAPE = uint128(1) << uint128(uint8(bytes1("\x10")));

/// @dev ASCII device control 1
uint128 constant CMASK_DEVICE_CONTROL_1 = uint128(1) << uint128(uint8(bytes1("\x11")));

/// @dev ASCII device control 2
uint128 constant CMASK_DEVICE_CONTROL_2 = uint128(1) << uint128(uint8(bytes1("\x12")));

/// @dev ASCII device control 3
uint128 constant CMASK_DEVICE_CONTROL_3 = uint128(1) << uint128(uint8(bytes1("\x13")));

/// @dev ASCII device control 4
uint128 constant CMASK_DEVICE_CONTROL_4 = uint128(1) << uint128(uint8(bytes1("\x14")));

/// @dev ASCII negative acknowledge
uint128 constant CMASK_NEGATIVE_ACKNOWLEDGE = uint128(1) << uint128(uint8(bytes1("\x15")));

/// @dev ASCII synchronous idle
uint128 constant CMASK_SYNCHRONOUS_IDLE = uint128(1) << uint128(uint8(bytes1("\x16")));

/// @dev ASCII end of transmission block
uint128 constant CMASK_END_OF_TRANSMISSION_BLOCK = uint128(1) << uint128(uint8(bytes1("\x17")));

/// @dev ASCII cancel
uint128 constant CMASK_CANCEL = uint128(1) << uint128(uint8(bytes1("\x18")));

/// @dev ASCII end of medium
uint128 constant CMASK_END_OF_MEDIUM = uint128(1) << uint128(uint8(bytes1("\x19")));

/// @dev ASCII substitute
uint128 constant CMASK_SUBSTITUTE = uint128(1) << uint128(uint8(bytes1("\x1A")));

/// @dev ASCII escape
uint128 constant CMASK_ESCAPE = uint128(1) << uint128(uint8(bytes1("\x1B")));

/// @dev ASCII file separator
uint128 constant CMASK_FILE_SEPARATOR = uint128(1) << uint128(uint8(bytes1("\x1C")));

/// @dev ASCII group separator
uint128 constant CMASK_GROUP_SEPARATOR = uint128(1) << uint128(uint8(bytes1("\x1D")));

/// @dev ASCII record separator
uint128 constant CMASK_RECORD_SEPARATOR = uint128(1) << uint128(uint8(bytes1("\x1E")));

/// @dev ASCII unit separator
uint128 constant CMASK_UNIT_SEPARATOR = uint128(1) << uint128(uint8(bytes1("\x1F")));

/// @dev ASCII space
uint128 constant CMASK_SPACE = uint128(1) << uint128(uint8(bytes1(" ")));

/// @dev ASCII !
uint128 constant CMASK_EXCLAMATION_MARK = uint128(1) << uint128(uint8(bytes1("!")));

/// @dev ASCII "
uint128 constant CMASK_QUOTATION_MARK = uint128(1) << uint128(uint8(bytes1("\"")));

/// @dev ASCII #
uint128 constant CMASK_NUMBER_SIGN = uint128(1) << uint128(uint8(bytes1("#")));

/// @dev ASCII $
uint128 constant CMASK_DOLLAR_SIGN = uint128(1) << uint128(uint8(bytes1("$")));

/// @dev ASCII %
uint128 constant CMASK_PERCENT_SIGN = uint128(1) << uint128(uint8(bytes1("%")));

/// @dev ASCII &
uint128 constant CMASK_AMPERSAND = uint128(1) << uint128(uint8(bytes1("&")));

/// @dev ASCII '
uint128 constant CMASK_APOSTROPHE = uint128(1) << uint128(uint8(bytes1("'")));

/// @dev ASCII (
uint128 constant CMASK_LEFT_PAREN = uint128(1) << uint128(uint8(bytes1("(")));

/// @dev ASCII )
uint128 constant CMASK_RIGHT_PAREN = uint128(1) << uint128(uint8(bytes1(")")));

/// @dev ASCII *
uint128 constant CMASK_ASTERISK = uint128(1) << uint128(uint8(bytes1("*")));

/// @dev ASCII +
uint128 constant CMASK_PLUS_SIGN = uint128(1) << uint128(uint8(bytes1("+")));

/// @dev ASCII ,
uint128 constant CMASK_COMMA = uint128(1) << uint128(uint8(bytes1(",")));

/// @dev ASCII -
uint128 constant CMASK_DASH = uint128(1) << uint128(uint8(bytes1("-")));

/// @dev ASCII .
uint128 constant CMASK_FULL_STOP = uint128(1) << uint128(uint8(bytes1(".")));

/// @dev ASCII /
uint128 constant CMASK_SLASH = uint128(1) << uint128(uint8(bytes1("/")));

/// @dev ASCII 0
uint128 constant CMASK_ZERO = uint128(1) << uint128(uint8(bytes1("0")));

/// @dev ASCII 1
uint128 constant CMASK_ONE = uint128(1) << uint128(uint8(bytes1("1")));

/// @dev ASCII 2
uint128 constant CMASK_TWO = uint128(1) << uint128(uint8(bytes1("2")));

/// @dev ASCII 3
uint128 constant CMASK_THREE = uint128(1) << uint128(uint8(bytes1("3")));

/// @dev ASCII 4
uint128 constant CMASK_FOUR = uint128(1) << uint128(uint8(bytes1("4")));

/// @dev ASCII 5
uint128 constant CMASK_FIVE = uint128(1) << uint128(uint8(bytes1("5")));

/// @dev ASCII 6
uint128 constant CMASK_SIX = uint128(1) << uint128(uint8(bytes1("6")));

/// @dev ASCII 7
uint128 constant CMASK_SEVEN = uint128(1) << uint128(uint8(bytes1("7")));

/// @dev ASCII 8
uint128 constant CMASK_EIGHT = uint128(1) << uint128(uint8(bytes1("8")));

/// @dev ASCII 9
uint128 constant CMASK_NINE = uint128(1) << uint128(uint8(bytes1("9")));

/// @dev ASCII :
uint128 constant CMASK_COLON = uint128(1) << uint128(uint8(bytes1(":")));

/// @dev ASCII ;
uint128 constant CMASK_SEMICOLON = uint128(1) << uint128(uint8(bytes1(";")));

/// @dev ASCII <
uint128 constant CMASK_LESS_THAN_SIGN = uint128(1) << uint128(uint8(bytes1("<")));

/// @dev ASCII =
uint128 constant CMASK_EQUALS_SIGN = uint128(1) << uint128(uint8(bytes1("=")));

/// @dev ASCII >
uint128 constant CMASK_GREATER_THAN_SIGN = uint128(1) << uint128(uint8(bytes1(">")));

/// @dev ASCII ?
uint128 constant CMASK_QUESTION_MARK = uint128(1) << uint128(uint8(bytes1("?")));

/// @dev ASCII @
uint128 constant CMASK_AT_SIGN = uint128(1) << uint128(uint8(bytes1("@")));

/// @dev ASCII A
uint128 constant CMASK_UPPER_A = uint128(1) << uint128(uint8(bytes1("A")));

/// @dev ASCII B
uint128 constant CMASK_UPPER_B = uint128(1) << uint128(uint8(bytes1("B")));

/// @dev ASCII C
uint128 constant CMASK_UPPER_C = uint128(1) << uint128(uint8(bytes1("C")));

/// @dev ASCII D
uint128 constant CMASK_UPPER_D = uint128(1) << uint128(uint8(bytes1("D")));

/// @dev ASCII E
uint128 constant CMASK_UPPER_E = uint128(1) << uint128(uint8(bytes1("E")));

/// @dev ASCII F
uint128 constant CMASK_UPPER_F = uint128(1) << uint128(uint8(bytes1("F")));

/// @dev ASCII G
uint128 constant CMASK_UPPER_G = uint128(1) << uint128(uint8(bytes1("G")));

/// @dev ASCII H
uint128 constant CMASK_UPPER_H = uint128(1) << uint128(uint8(bytes1("H")));

/// @dev ASCII I
uint128 constant CMASK_UPPER_I = uint128(1) << uint128(uint8(bytes1("I")));

/// @dev ASCII J
uint128 constant CMASK_UPPER_J = uint128(1) << uint128(uint8(bytes1("J")));

/// @dev ASCII K
uint128 constant CMASK_UPPER_K = uint128(1) << uint128(uint8(bytes1("K")));

/// @dev ASCII L
uint128 constant CMASK_UPPER_L = uint128(1) << uint128(uint8(bytes1("L")));

/// @dev ASCII M
uint128 constant CMASK_UPPER_M = uint128(1) << uint128(uint8(bytes1("M")));

/// @dev ASCII N
uint128 constant CMASK_UPPER_N = uint128(1) << uint128(uint8(bytes1("N")));

/// @dev ASCII O
uint128 constant CMASK_UPPER_O = uint128(1) << uint128(uint8(bytes1("O")));

/// @dev ASCII P
uint128 constant CMASK_UPPER_P = uint128(1) << uint128(uint8(bytes1("P")));

/// @dev ASCII Q
uint128 constant CMASK_UPPER_Q = uint128(1) << uint128(uint8(bytes1("Q")));

/// @dev ASCII R
uint128 constant CMASK_UPPER_R = uint128(1) << uint128(uint8(bytes1("R")));

/// @dev ASCII S
uint128 constant CMASK_UPPER_S = uint128(1) << uint128(uint8(bytes1("S")));

/// @dev ASCII T
uint128 constant CMASK_UPPER_T = uint128(1) << uint128(uint8(bytes1("T")));

/// @dev ASCII U
uint128 constant CMASK_UPPER_U = uint128(1) << uint128(uint8(bytes1("U")));

/// @dev ASCII V
uint128 constant CMASK_UPPER_V = uint128(1) << uint128(uint8(bytes1("V")));

/// @dev ASCII W
uint128 constant CMASK_UPPER_W = uint128(1) << uint128(uint8(bytes1("W")));

/// @dev ASCII X
uint128 constant CMASK_UPPER_X = uint128(1) << uint128(uint8(bytes1("X")));

/// @dev ASCII Y
uint128 constant CMASK_UPPER_Y = uint128(1) << uint128(uint8(bytes1("Y")));

/// @dev ASCII Z
uint128 constant CMASK_UPPER_Z = uint128(1) << uint128(uint8(bytes1("Z")));

/// @dev ASCII [
uint128 constant CMASK_LEFT_SQUARE_BRACKET = uint128(1) << uint128(uint8(bytes1("[")));

/// @dev ASCII \
uint128 constant CMASK_BACKSLASH = uint128(1) << uint128(uint8(bytes1("\\")));

/// @dev ASCII ]
uint128 constant CMASK_RIGHT_SQUARE_BRACKET = uint128(1) << uint128(uint8(bytes1("]")));

/// @dev ASCII ^
uint128 constant CMASK_CIRCUMFLEX_ACCENT = uint128(1) << uint128(uint8(bytes1("^")));

/// @dev ASCII _
uint128 constant CMASK_UNDERSCORE = uint128(1) << uint128(uint8(bytes1("_")));

/// @dev ASCII `
uint128 constant CMASK_GRAVE_ACCENT = uint128(1) << uint128(uint8(bytes1("`")));

/// @dev ASCII a
uint128 constant CMASK_LOWER_A = uint128(1) << uint128(uint8(bytes1("a")));

/// @dev ASCII b
uint128 constant CMASK_LOWER_B = uint128(1) << uint128(uint8(bytes1("b")));

/// @dev ASCII c
uint128 constant CMASK_LOWER_C = uint128(1) << uint128(uint8(bytes1("c")));

/// @dev ASCII d
uint128 constant CMASK_LOWER_D = uint128(1) << uint128(uint8(bytes1("d")));

/// @dev ASCII e
uint128 constant CMASK_LOWER_E = uint128(1) << uint128(uint8(bytes1("e")));

/// @dev ASCII f
uint128 constant CMASK_LOWER_F = uint128(1) << uint128(uint8(bytes1("f")));

/// @dev ASCII g
uint128 constant CMASK_LOWER_G = uint128(1) << uint128(uint8(bytes1("g")));

/// @dev ASCII h
uint128 constant CMASK_LOWER_H = uint128(1) << uint128(uint8(bytes1("h")));

/// @dev ASCII i
uint128 constant CMASK_LOWER_I = uint128(1) << uint128(uint8(bytes1("i")));

/// @dev ASCII j
uint128 constant CMASK_LOWER_J = uint128(1) << uint128(uint8(bytes1("j")));

/// @dev ASCII k
uint128 constant CMASK_LOWER_K = uint128(1) << uint128(uint8(bytes1("k")));

/// @dev ASCII l
uint128 constant CMASK_LOWER_L = uint128(1) << uint128(uint8(bytes1("l")));

/// @dev ASCII m
uint128 constant CMASK_LOWER_M = uint128(1) << uint128(uint8(bytes1("m")));

/// @dev ASCII n
uint128 constant CMASK_LOWER_N = uint128(1) << uint128(uint8(bytes1("n")));

/// @dev ASCII o
uint128 constant CMASK_LOWER_O = uint128(1) << uint128(uint8(bytes1("o")));

/// @dev ASCII p
uint128 constant CMASK_LOWER_P = uint128(1) << uint128(uint8(bytes1("p")));

/// @dev ASCII q
uint128 constant CMASK_LOWER_Q = uint128(1) << uint128(uint8(bytes1("q")));

/// @dev ASCII r
uint128 constant CMASK_LOWER_R = uint128(1) << uint128(uint8(bytes1("r")));

/// @dev ASCII s
uint128 constant CMASK_LOWER_S = uint128(1) << uint128(uint8(bytes1("s")));

/// @dev ASCII t
uint128 constant CMASK_LOWER_T = uint128(1) << uint128(uint8(bytes1("t")));

/// @dev ASCII u
uint128 constant CMASK_LOWER_U = uint128(1) << uint128(uint8(bytes1("u")));

/// @dev ASCII v
uint128 constant CMASK_LOWER_V = uint128(1) << uint128(uint8(bytes1("v")));

/// @dev ASCII w
uint128 constant CMASK_LOWER_W = uint128(1) << uint128(uint8(bytes1("w")));

/// @dev ASCII x
uint128 constant CMASK_LOWER_X = uint128(1) << uint128(uint8(bytes1("x")));

/// @dev ASCII y
uint128 constant CMASK_LOWER_Y = uint128(1) << uint128(uint8(bytes1("y")));

/// @dev ASCII z
uint128 constant CMASK_LOWER_Z = uint128(1) << uint128(uint8(bytes1("z")));

/// @dev ASCII {
uint128 constant CMASK_LEFT_CURLY_BRACKET = uint128(1) << uint128(uint8(bytes1("{")));

/// @dev ASCII |
uint128 constant CMASK_VERTICAL_BAR = uint128(1) << uint128(uint8(bytes1("|")));

/// @dev ASCII }
uint128 constant CMASK_RIGHT_CURLY_BRACKET = uint128(1) << uint128(uint8(bytes1("}")));

/// @dev ASCII ~
uint128 constant CMASK_TILDE = uint128(1) << uint128(uint8(bytes1("~")));

/// @dev ASCII delete
uint128 constant CMASK_DELETE = uint128(1) << uint128(uint8(bytes1("\x7F")));

/// @dev ASCII printable characters is everything 0x20 and above, except 0x7F
uint128 constant CMASK_PRINTABLE = ~(
    CMASK_NULL | CMASK_START_OF_HEADING | CMASK_START_OF_TEXT | CMASK_END_OF_TEXT | CMASK_END_OF_TRANSMISSION
        | CMASK_ENQUIRY | CMASK_ACKNOWLEDGE | CMASK_BELL | CMASK_BACKSPACE | CMASK_HORIZONTAL_TAB | CMASK_LINE_FEED
        | CMASK_VERTICAL_TAB | CMASK_FORM_FEED | CMASK_CARRIAGE_RETURN | CMASK_SHIFT_OUT | CMASK_SHIFT_IN
        | CMASK_DATA_LINK_ESCAPE | CMASK_DEVICE_CONTROL_1 | CMASK_DEVICE_CONTROL_2 | CMASK_DEVICE_CONTROL_3
        | CMASK_DEVICE_CONTROL_4 | CMASK_NEGATIVE_ACKNOWLEDGE | CMASK_SYNCHRONOUS_IDLE | CMASK_END_OF_TRANSMISSION_BLOCK
        | CMASK_CANCEL | CMASK_END_OF_MEDIUM | CMASK_SUBSTITUTE | CMASK_ESCAPE | CMASK_FILE_SEPARATOR
        | CMASK_GROUP_SEPARATOR | CMASK_RECORD_SEPARATOR | CMASK_UNIT_SEPARATOR | CMASK_DELETE
);

/// @dev numeric 0-9
uint128 constant CMASK_NUMERIC_0_9 = CMASK_ZERO | CMASK_ONE | CMASK_TWO | CMASK_THREE | CMASK_FOUR | CMASK_FIVE
    | CMASK_SIX | CMASK_SEVEN | CMASK_EIGHT | CMASK_NINE;

/// @dev e notation eE
uint128 constant CMASK_E_NOTATION = CMASK_LOWER_E | CMASK_UPPER_E;

/// @dev lower alpha a-z
uint128 constant CMASK_LOWER_ALPHA_A_Z = CMASK_LOWER_A | CMASK_LOWER_B | CMASK_LOWER_C | CMASK_LOWER_D | CMASK_LOWER_E
    | CMASK_LOWER_F | CMASK_LOWER_G | CMASK_LOWER_H | CMASK_LOWER_I | CMASK_LOWER_J | CMASK_LOWER_K | CMASK_LOWER_L
    | CMASK_LOWER_M | CMASK_LOWER_N | CMASK_LOWER_O | CMASK_LOWER_P | CMASK_LOWER_Q | CMASK_LOWER_R | CMASK_LOWER_S
    | CMASK_LOWER_T | CMASK_LOWER_U | CMASK_LOWER_V | CMASK_LOWER_W | CMASK_LOWER_X | CMASK_LOWER_Y | CMASK_LOWER_Z;

/// @dev upper alpha A-Z
uint128 constant CMASK_UPPER_ALPHA_A_Z = CMASK_UPPER_A | CMASK_UPPER_B | CMASK_UPPER_C | CMASK_UPPER_D | CMASK_UPPER_E
    | CMASK_UPPER_F | CMASK_UPPER_G | CMASK_UPPER_H | CMASK_UPPER_I | CMASK_UPPER_J | CMASK_UPPER_K | CMASK_UPPER_L
    | CMASK_UPPER_M | CMASK_UPPER_N | CMASK_UPPER_O | CMASK_UPPER_P | CMASK_UPPER_Q | CMASK_UPPER_R | CMASK_UPPER_S
    | CMASK_UPPER_T | CMASK_UPPER_U | CMASK_UPPER_V | CMASK_UPPER_W | CMASK_UPPER_X | CMASK_UPPER_Y | CMASK_UPPER_Z;

/// @dev lower alpha a-f (hex)
uint128 constant CMASK_LOWER_ALPHA_A_F =
    CMASK_LOWER_A | CMASK_LOWER_B | CMASK_LOWER_C | CMASK_LOWER_D | CMASK_LOWER_E | CMASK_LOWER_F;

/// @dev upper alpha A-F (hex)
uint128 constant CMASK_UPPER_ALPHA_A_F =
    CMASK_UPPER_A | CMASK_UPPER_B | CMASK_UPPER_C | CMASK_UPPER_D | CMASK_UPPER_E | CMASK_UPPER_F;

/// @dev hex 0-9 a-f A-F
uint128 constant CMASK_HEX = CMASK_NUMERIC_0_9 | CMASK_LOWER_ALPHA_A_F | CMASK_UPPER_ALPHA_A_F;

/// @dev Rainlang end of line is ,
uint128 constant CMASK_EOL = CMASK_COMMA;

/// @dev Rainlang LHS/RHS delimiter is :
uint128 constant CMASK_LHS_RHS_DELIMITER = CMASK_COLON;

/// @dev Rainlang end of source is ;
uint128 constant CMASK_EOS = CMASK_SEMICOLON;

/// @dev Rainlang stack head is lower alpha and underscore a-z _
uint128 constant CMASK_LHS_STACK_HEAD = CMASK_LOWER_ALPHA_A_Z | CMASK_UNDERSCORE;

/// @dev Rainlang identifier head is lower alpha a-z
uint128 constant CMASK_IDENTIFIER_HEAD = CMASK_LOWER_ALPHA_A_Z;
uint128 constant CMASK_RHS_WORD_HEAD = CMASK_IDENTIFIER_HEAD;

/// @dev Rainlang stack/identifier tail is lower alphanumeric kebab a-z 0-9 -
uint128 constant CMASK_IDENTIFIER_TAIL = CMASK_IDENTIFIER_HEAD | CMASK_NUMERIC_0_9 | CMASK_DASH;
uint128 constant CMASK_LHS_STACK_TAIL = CMASK_IDENTIFIER_TAIL;
uint128 constant CMASK_RHS_WORD_TAIL = CMASK_IDENTIFIER_TAIL;

/// @dev Rainlang operand start is <
uint128 constant CMASK_OPERAND_START = CMASK_LESS_THAN_SIGN;

/// @dev Rainlang operand end is >
uint128 constant CMASK_OPERAND_END = CMASK_GREATER_THAN_SIGN;

/// @dev NOT lower alphanumeric kebab
uint128 constant CMASK_NOT_IDENTIFIER_TAIL = ~CMASK_IDENTIFIER_TAIL;

/// @dev Rainlang whitespace is \n \r \t space
uint128 constant CMASK_WHITESPACE = CMASK_LINE_FEED | CMASK_CARRIAGE_RETURN | CMASK_HORIZONTAL_TAB | CMASK_SPACE;

/// @dev Rainlang stack item delimiter is whitespace
uint128 constant CMASK_LHS_STACK_DELIMITER = CMASK_WHITESPACE;

/// @dev Rainlang supports numeric literals as anything starting with 0-9
uint128 constant CMASK_NUMERIC_LITERAL_HEAD = CMASK_NUMERIC_0_9;

/// @dev Rainlang supports string literals as anything starting with "
uint128 constant CMASK_STRING_LITERAL_HEAD = CMASK_QUOTATION_MARK;

/// @dev Rainlang supports sub parseable literals as anything starting with [
uint128 constant CMASK_SUB_PARSEABLE_LITERAL_HEAD = CMASK_LEFT_SQUARE_BRACKET;

/// @dev Rainlang ends a sub parseable literal with ]
uint128 constant CMASK_SUB_PARSEABLE_LITERAL_END = CMASK_RIGHT_SQUARE_BRACKET;

/// @dev Rainlang string end is "
uint128 constant CMASK_STRING_LITERAL_END = CMASK_QUOTATION_MARK;

/// @dev Rainlang string tail is any printable ASCII except " which ends it.
uint128 constant CMASK_STRING_LITERAL_TAIL = ~CMASK_STRING_LITERAL_END & CMASK_PRINTABLE;

/// @dev Rainlang literal head
uint128 constant CMASK_LITERAL_HEAD =
    CMASK_NUMERIC_LITERAL_HEAD | CMASK_STRING_LITERAL_HEAD | CMASK_SUB_PARSEABLE_LITERAL_HEAD;

/// @dev Rainlang comment head is /
uint128 constant CMASK_COMMENT_HEAD = CMASK_SLASH;

/// @dev Rainlang interstitial head could be some whitespace or a comment head.
uint128 constant CMASK_INTERSTITIAL_HEAD = CMASK_WHITESPACE | CMASK_COMMENT_HEAD;

/// @dev Rainlang comment starting sequence is /*
uint256 constant COMMENT_START_SEQUENCE = uint256(uint16(bytes2("/*")));

/// @dev Rainlang comment ending sequence is */
uint256 constant COMMENT_END_SEQUENCE = uint256(uint16(bytes2("*/")));

/// @dev Rainlang comment end sequence end byte is / */
uint256 constant CMASK_COMMENT_END_SEQUENCE_END = COMMENT_END_SEQUENCE & 0xFF;

/// @dev Rainlang literal hexadecimal dispatch is 0x
/// We compare the head and dispatch together to avoid a second comparison.
/// This is safe because the head is prefiltered to be 0-9 due to the numeric
/// literal head, therefore the only possible match is 0x (not x0).
uint128 constant CMASK_LITERAL_HEX_DISPATCH = CMASK_ZERO | CMASK_LOWER_X;

/// @dev We may want to match the exact start of a hex literal.
uint256 constant CMASK_LITERAL_HEX_DISPATCH_START = uint256(uint16(bytes2("0x")));

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @dev 010101... for ctpop
uint256 constant CTPOP_M1 = 0x5555555555555555555555555555555555555555555555555555555555555555;
/// @dev 00110011.. for ctpop
uint256 constant CTPOP_M2 = 0x3333333333333333333333333333333333333333333333333333333333333333;
/// @dev 4 bits alternating for ctpop
uint256 constant CTPOP_M4 = 0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F;
/// @dev 8 bits alternating for ctpop
uint256 constant CTPOP_M8 = 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF;
/// @dev 16 bits alternating for ctpop
uint256 constant CTPOP_M16 = 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF;
/// @dev 32 bits alternating for ctpop
uint256 constant CTPOP_M32 = 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF;
/// @dev 64 bits alternating for ctpop
uint256 constant CTPOP_M64 = 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF;
/// @dev 128 bits alternating for ctpop
uint256 constant CTPOP_M128 = 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
/// @dev 1 bytes for ctpop
uint256 constant CTPOP_H01 = 0x0101010101010101010101010101010101010101010101010101010101010101;

library LibCtPop {
    /// Optimised version of ctpop.
    /// https://en.wikipedia.org/wiki/Hamming_weight
    function ctpop(uint256 x) internal pure returns (uint256) {
        // This edge case is not handled by the algorithm below.
        if (x == type(uint256).max) {
            return 256;
        }
        unchecked {
            x -= (x >> 1) & CTPOP_M1;
            x = (x & CTPOP_M2) + ((x >> 2) & CTPOP_M2);
            x = (x + (x >> 4)) & CTPOP_M4;
            x = (x * CTPOP_H01) >> 248;
        }
        return x;
    }

    /// This is the slowest possible implementation of ctpop. It is used to
    /// verify the correctness of the optimized implementation in LibCtPop.
    /// It should be obviously correct by visual inspection, referencing the
    /// wikipedia article.
    /// https://en.wikipedia.org/wiki/Hamming_weight
    function ctpopSlow(uint256 x) internal pure returns (uint256) {
        unchecked {
            x = (x & CTPOP_M1) + ((x >> 1) & CTPOP_M1);
            x = (x & CTPOP_M2) + ((x >> 2) & CTPOP_M2);
            x = (x & CTPOP_M4) + ((x >> 4) & CTPOP_M4);
            x = (x & CTPOP_M8) + ((x >> 8) & CTPOP_M8);
            x = (x & CTPOP_M16) + ((x >> 16) & CTPOP_M16);
            x = (x & CTPOP_M32) + ((x >> 32) & CTPOP_M32);
            x = (x & CTPOP_M64) + ((x >> 64) & CTPOP_M64);
            x = (x & CTPOP_M128) + ((x >> 128) & CTPOP_M128);
        }
        return x;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {LibCtPop} from "../bitwise/LibCtPop.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {LibParseOperand} from "./LibParseOperand.sol";
import {ParseState} from "./LibParseState.sol";
import {AuthoringMetaV2} from "rain.interpreter.interface/interface/IParserV1.sol";

/// @dev For metadata builder.
error DuplicateFingerprint();

/// @dev Words and io fn pointers aren't the same length.
error WordIOFnPointerMismatch(uint256 wordsLength, uint256 ioFnPointersLength);

/// @dev 0xFFFFFF = 3 byte fingerprint
/// The fingerprint is 3 bytes because we're targetting the same collision
/// resistance on words as solidity functions. As we already use a fully byte to
/// map words across the expander, we only need 3 bytes for the fingerprint to
/// achieve 4 bytes of collision resistance, which is the same as a solidity
/// selector. This assumes that the byte selected to expand is uncorrelated with
/// the fingerprint bytes, which is a reasonable assumption as long as we use
/// different bytes from a keccak256 hash for each.
/// This assumes a single expander, if there are multiple expanders, then the
/// collision resistance only improves, so this is still safe.
uint256 constant FINGERPRINT_MASK = 0xFFFFFF;
/// @dev 4 = 1 byte opcode index + 3 byte fingerprint
uint256 constant META_ITEM_SIZE = 4;
uint256 constant META_ITEM_MASK = (1 << META_ITEM_SIZE) - 1;
/// @dev 33 = 32 bytes for expansion + 1 byte for seed
uint256 constant META_EXPANSION_SIZE = 0x21;
/// @dev 1 = 1 byte for depth
uint256 constant META_PREFIX_SIZE = 1;

library LibParseMeta {
    function wordBitmapped(uint256 seed, bytes32 word) internal pure returns (uint256 bitmap, uint256 hashed) {
        assembly ("memory-safe") {
            mstore(0, word)
            mstore8(0x20, seed)
            hashed := keccak256(0, 0x21)
            // We have to be careful here to avoid using the same byte for both
            // the expansion and the fingerprint. This is because we are relying
            // on the combined effect of both for collision resistance. We do
            // this by using the high byte of the hash for the bitmap, and the
            // low 3 bytes for the fingerprint.
            //slither-disable-next-line incorrect-shift
            bitmap := shl(byte(0, hashed), 1)
        }
    }

    function copyWordsFromAuthoringMeta(AuthoringMetaV2[] memory authoringMeta)
        internal
        pure
        returns (bytes32[] memory)
    {
        bytes32[] memory words = new bytes32[](authoringMeta.length);
        for (uint256 i = 0; i < authoringMeta.length; i++) {
            words[i] = authoringMeta[i].word;
        }
        return words;
    }

    function findBestExpander(AuthoringMetaV2[] memory metas)
        internal
        pure
        returns (uint8 bestSeed, uint256 bestExpansion, AuthoringMetaV2[] memory remaining)
    {
        unchecked {
            {
                uint256 bestCt = 0;
                for (uint256 seed = 0; seed < type(uint8).max; seed++) {
                    uint256 expansion = 0;
                    for (uint256 i = 0; i < metas.length; i++) {
                        (uint256 shifted, uint256 hashed) = wordBitmapped(seed, metas[i].word);
                        (hashed);
                        expansion = shifted | expansion;
                    }
                    uint256 ct = LibCtPop.ctpop(expansion);
                    if (ct > bestCt) {
                        bestCt = ct;
                        bestSeed = uint8(seed);
                        bestExpansion = expansion;
                    }
                    // perfect expansion.
                    if (ct == metas.length) {
                        break;
                    }
                }

                uint256 remainingLength = metas.length - bestCt;
                assembly ("memory-safe") {
                    remaining := mload(0x40)
                    mstore(remaining, remainingLength)
                    mstore(0x40, add(remaining, mul(0x20, add(1, remainingLength))))
                }
            }
            uint256 usedExpansion = 0;
            uint256 j = 0;
            for (uint256 i = 0; i < metas.length; i++) {
                (uint256 shifted, uint256 hashed) = wordBitmapped(bestSeed, metas[i].word);
                (hashed);
                if ((shifted & usedExpansion) == 0) {
                    usedExpansion = shifted | usedExpansion;
                } else {
                    remaining[j] = metas[i];
                    j++;
                }
            }
        }
    }

    function buildParseMetaV2(AuthoringMetaV2[] memory authoringMeta, uint8 maxDepth)
        internal
        pure
        returns (bytes memory parseMeta)
    {
        unchecked {
            // Write out expansions.
            uint8[] memory seeds;
            uint256[] memory expansions;
            uint256 dataStart;
            {
                uint256 depth = 0;
                seeds = new uint8[](maxDepth);
                expansions = new uint256[](maxDepth);
                {
                    AuthoringMetaV2[] memory remainingAuthoringMeta = authoringMeta;
                    while (remainingAuthoringMeta.length > 0) {
                        uint8 seed;
                        uint256 expansion;
                        (seed, expansion, remainingAuthoringMeta) = findBestExpander(remainingAuthoringMeta);
                        seeds[depth] = seed;
                        expansions[depth] = expansion;
                        depth++;
                    }
                }

                uint256 parseMetaLength =
                    META_PREFIX_SIZE + depth * META_EXPANSION_SIZE + authoringMeta.length * META_ITEM_SIZE;
                parseMeta = new bytes(parseMetaLength);
                assembly ("memory-safe") {
                    mstore8(add(parseMeta, 0x20), depth)
                }
                for (uint256 j = 0; j < depth; j++) {
                    assembly ("memory-safe") {
                        // Write each seed immediately before its expansion.
                        let seedWriteAt := add(add(parseMeta, 0x21), mul(0x21, j))
                        mstore8(seedWriteAt, mload(add(seeds, add(0x20, mul(0x20, j)))))
                        mstore(add(seedWriteAt, 1), mload(add(expansions, add(0x20, mul(0x20, j)))))
                    }
                }

                {
                    uint256 dataOffset = META_PREFIX_SIZE + META_ITEM_SIZE + depth * META_EXPANSION_SIZE;
                    assembly ("memory-safe") {
                        dataStart := add(parseMeta, dataOffset)
                    }
                }
            }

            // Write words.
            for (uint256 k = 0; k < authoringMeta.length; k++) {
                uint256 s = 0;
                uint256 cumulativePos = 0;
                while (true) {
                    uint256 toWrite;
                    uint256 writeAt;

                    // Need some careful scoping here to avoid stack too deep.
                    {
                        uint256 expansion = expansions[s];

                        uint256 hashed;
                        {
                            uint256 shifted;
                            (shifted, hashed) = wordBitmapped(seeds[s], authoringMeta[k].word);

                            uint256 metaItemSize = META_ITEM_SIZE;
                            uint256 pos = LibCtPop.ctpop(expansion & (shifted - 1)) + cumulativePos;
                            assembly ("memory-safe") {
                                writeAt := add(dataStart, mul(pos, metaItemSize))
                            }
                        }

                        {
                            uint256 wordFingerprint = hashed & FINGERPRINT_MASK;
                            uint256 posFingerprint;
                            assembly ("memory-safe") {
                                posFingerprint := mload(writeAt)
                            }
                            posFingerprint &= FINGERPRINT_MASK;
                            if (posFingerprint != 0) {
                                if (posFingerprint == wordFingerprint) {
                                    revert DuplicateFingerprint();
                                }
                                // Collision, try next expansion.
                                s++;
                                cumulativePos = cumulativePos + LibCtPop.ctpop(expansion);
                                continue;
                            }
                            // Not collision, prepare the write with the
                            // fingerprint and index.
                            toWrite = wordFingerprint | (k << 0x18);
                        }
                    }

                    uint256 mask = ~META_ITEM_MASK;
                    assembly ("memory-safe") {
                        mstore(writeAt, or(and(mload(writeAt), mask), toWrite))
                    }
                    // We're done with this word.
                    break;
                }
            }
        }
    }

    /// Given the parse meta and a word, return the index and io fn pointer for
    /// the word. If the word is not found, then `exists` will be false. The
    /// caller MUST check `exists` before using the other return values.
    /// @param state The parser state.
    /// @param word The word to lookup.
    /// @return True if the word exists in the parse meta.
    /// @return The index of the word in the parse meta.
    function lookupWord(ParseState memory state, bytes32 word) internal pure returns (bool, uint256) {
        unchecked {
            uint256 dataStart;
            uint256 cursor;
            uint256 end;
            {
                uint256 metaExpansionSize = META_EXPANSION_SIZE;
                uint256 metaItemSize = META_ITEM_SIZE;
                bytes memory meta = state.meta;
                assembly ("memory-safe") {
                    // Read depth from first meta byte.
                    cursor := add(meta, 1)
                    let depth := and(mload(cursor), 0xFF)
                    // 33 bytes per depth
                    end := add(cursor, mul(depth, metaExpansionSize))
                    dataStart := add(end, metaItemSize)
                }
            }

            uint256 cumulativeCt = 0;
            while (cursor < end) {
                uint256 expansion;
                uint256 posData;
                uint256 wordFingerprint;
                // Lookup the data at pos.
                {
                    uint256 seed;
                    assembly ("memory-safe") {
                        cursor := add(cursor, 1)
                        seed := and(mload(cursor), 0xFF)
                        cursor := add(cursor, 0x20)
                        expansion := mload(cursor)
                    }

                    (uint256 shifted, uint256 hashed) = wordBitmapped(seed, word);
                    uint256 pos = LibCtPop.ctpop(expansion & (shifted - 1)) + cumulativeCt;
                    wordFingerprint = hashed & FINGERPRINT_MASK;
                    uint256 metaItemSize = META_ITEM_SIZE;
                    assembly ("memory-safe") {
                        posData := mload(add(dataStart, mul(pos, metaItemSize)))
                    }
                }

                // Match
                if (wordFingerprint == posData & FINGERPRINT_MASK) {
                    uint256 index;
                    assembly ("memory-safe") {
                        index := byte(28, posData)
                    }
                    return (true, index);
                } else {
                    cumulativeCt += LibCtPop.ctpop(expansion);
                }
            }
            return (false, 0);
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {ParseState} from "./LibParseState.sol";

library LibParseStackName {
    /// Push a word onto the stack name stack.
    /// @return exists Whether the word already existed.
    /// @return index The new index after the word was pushed. Will be unchanged
    /// if the word already existed.
    function pushStackName(ParseState memory state, bytes32 word) internal pure returns (bool exists, uint256 index) {
        unchecked {
            (exists, index) = stackNameIndex(state, word);
            if (!exists) {
                uint256 fingerprint;
                uint256 ptr;
                uint256 oldStackNames = state.stackNames;
                assembly ("memory-safe") {
                    ptr := mload(0x40)
                    mstore(ptr, word)
                    fingerprint := and(keccak256(ptr, 0x20), not(0xFFFFFFFF))
                    mstore(ptr, oldStackNames)
                    mstore(0x40, add(ptr, 0x20))
                }
                // Add the start of line height to the LHS line parse count.
                uint256 stackLHSIndex = state.topLevel1 & 0xFF;
                state.stackNames = fingerprint | (stackLHSIndex << 0x10) | ptr;
                index = stackLHSIndex + 1;
            }
        }
    }

    /// Retrieve the index of a previously pushed stack name.
    function stackNameIndex(ParseState memory state, bytes32 word) internal pure returns (bool exists, uint256 index) {
        uint256 fingerprint;
        uint256 stackNames = state.stackNames;
        uint256 stackNameBloom = state.stackNameBloom;
        uint256 bloom;
        assembly ("memory-safe") {
            mstore(0, word)
            fingerprint := shr(0x20, keccak256(0, 0x20))
            //slither-disable-next-line incorrect-shift
            bloom := shl(and(fingerprint, 0xFF), 1)

            // If the bloom matches then maybe the stack name is in the stack.
            if and(bloom, stackNameBloom) {
                for { let ptr := and(stackNames, 0xFFFF) } iszero(iszero(ptr)) {
                    stackNames := mload(ptr)
                    ptr := and(stackNames, 0xFFFF)
                } {
                    if eq(fingerprint, shr(0x20, stackNames)) {
                        exists := true
                        index := and(shr(0x10, stackNames), 0xFFFF)
                        break
                    }
                }
            }
        }
        state.stackNameBloom = bloom | stackNameBloom;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @dev Workaround for https://github.com/foundry-rs/foundry/issues/6572
contract ErrParse {}

/// Thrown when parsing a source string and an operand opening `<` paren is found
/// somewhere that we don't expect it or can't handle it.
error UnexpectedOperand();

/// Thrown when there are more operand values in the operand than the handler
/// is expecting.
error UnexpectedOperandValue();

/// Thrown when parsing an operand and some required component of the operand is
/// not found in the source string.
error ExpectedOperand();

/// Thrown when parsing an operand and the literal in the source string is too
/// large to fit in the bits allocated for it in the operand.
error OperandOverflow();

/// Thrown when the number of values encountered in a single operand parsing is
/// longer than the memory allocated to hold them.
/// @param offset The offset in the source string where the error occurred.
error OperandValuesOverflow(uint256 offset);

/// Thrown when parsing an operand and the closing `>` paren is not found.
/// @param offset The offset in the source string where the error occurred.
error UnclosedOperand(uint256 offset);

/// The parser tried to bound an unsupported literal that we have no type for.
error UnsupportedLiteralType(uint256 offset);

/// Encountered a string literal that is larger than supported.
error StringTooLong(uint256 offset);

/// Encountered a string that does not have a valid end, e.g. we found some char
/// that was not printable ASCII and had to stop.
error UnclosedStringLiteral(uint256 offset);

/// Encountered a literal that is larger than supported.
error HexLiteralOverflow(uint256 offset);

/// Encountered a zero length hex literal.
error ZeroLengthHexLiteral(uint256 offset);

/// Encountered an odd sized hex literal.
error OddLengthHexLiteral(uint256 offset);

/// Encountered a hex literal with an invalid character.
error MalformedHexLiteral(uint256 offset);

/// Encountered a decimal literal that is larger than supported.
error DecimalLiteralOverflow(uint256 offset);

/// Encountered a decimal literal with an exponent that has too many or no
/// digits.
error MalformedExponentDigits(uint256 offset);

/// Encountered a zero length decimal literal.
error ZeroLengthDecimal(uint256 offset);

/// The expression does not finish with a semicolon (EOF).
error MissingFinalSemi(uint256 offset);

/// Enountered an unexpected character on the LHS.
error UnexpectedLHSChar(uint256 offset);

/// Encountered an unexpected character on the RHS.
error UnexpectedRHSChar(uint256 offset);

/// More specific version of UnexpectedRHSChar where we specifically expected
/// a left paren but got some other char.
error ExpectedLeftParen(uint256 offset);

/// Encountered a right paren without a matching left paren.
error UnexpectedRightParen(uint256 offset);

/// Encountered an unclosed left paren.
error UnclosedLeftParen(uint256 offset);

/// Encountered a comment outside the interstitial space between lines.
error UnexpectedComment(uint256 offset);

/// Encountered a comment that never ends.
error UnclosedComment(uint256 offset);

/// Encountered a comment start sequence that is malformed.
error MalformedCommentStart(uint256 offset);

/// @dev Thrown when a stack name is duplicated. Shadowing in all forms is
/// disallowed in Rainlang.
error DuplicateLHSItem(uint256 errorOffset);

/// Encountered too many LHS items.
error ExcessLHSItems(uint256 offset);

/// Encountered inputs where they can't be handled.
error NotAcceptingInputs(uint256 offset);

/// Encountered too many RHS items.
error ExcessRHSItems(uint256 offset);

/// Encountered a word that is longer than 32 bytes.
error WordSize(string word);

/// Parsed a word that is not in the meta.
error UnknownWord();

/// The parser exceeded the maximum number of sources that it can build.
error MaxSources();

/// The parser encountered a dangling source. This is a bug in the parser.
error DanglingSource();

/// The parser moved past the end of the data.
error ParserOutOfBounds();

/// The parser encountered a stack deeper than it can process in the memory
/// region allocated for stack names.
error ParseStackOverflow();

/// The parser encountered a stack underflow.
error ParseStackUnderflow();

/// The parser encountered a paren group deeper than it can process in the
/// memory region allocated for paren tracking.
error ParenOverflow();

/// The parser did not find any whitespace after the pragma keyword.
error NoWhitespaceAfterUsingWordsFrom(uint256 offset);

/// The parser encountered a literal that it cannot use as a sub parser.
error InvalidSubParser(uint256 offset);

/// The parser encountered an unclosed sub parsed literal.
error UnclosedSubParseableLiteral(uint256 offset);

/// The parser encountered a sub parseable literal with a missing dispatch.
error SubParseableMissingDispatch(uint256 offset);

/// The sub parser returned some bytecode that the main parser could not
/// understand.
error BadSubParserResult(bytes bytecode);

/// Thrown when there are more than 16 inputs or outputs for a given opcode.
error OpcodeIOOverflow(uint256 offset);

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Operand, OPCODE_CONSTANT} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {LibParseStackTracker, ParseStackTracker} from "./LibParseStackTracker.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {LibMemCpy} from "rain.solmem/lib/LibMemCpy.sol";
import {
    DanglingSource,
    MaxSources,
    ParseStackOverflow,
    UnclosedLeftParen,
    ExcessRHSItems,
    ExcessLHSItems,
    NotAcceptingInputs,
    UnsupportedLiteralType,
    InvalidSubParser,
    OpcodeIOOverflow
} from "../../error/ErrParse.sol";
import {LibParseLiteral} from "./literal/LibParseLiteral.sol";
import {LibParse} from "./LibParse.sol";
import {LibParseOperand} from "./LibParseOperand.sol";
import {LibParseError} from "./LibParseError.sol";

/// @dev Initial state of an active source is just the starting offset which is
/// 0x20.
uint256 constant EMPTY_ACTIVE_SOURCE = 0x20;

uint256 constant FSM_YANG_MASK = 1;
uint256 constant FSM_WORD_END_MASK = 1 << 1;
uint256 constant FSM_ACCEPTING_INPUTS_MASK = 1 << 2;

/// @dev If a source is active we cannot finish parsing without a semi to trigger
/// finalisation.
uint256 constant FSM_ACTIVE_SOURCE_MASK = 1 << 3;

/// @dev fsm default state is:
/// - yin
/// - not word end
/// - accepting inputs
uint256 constant FSM_DEFAULT = FSM_ACCEPTING_INPUTS_MASK;

/// @dev The operand values array is 4 words long. In the future we could have
/// some kind of logic that reallocates and expands this if we discover that
/// we need more than 4 operands for a single opcode. Currently there are no
/// opcodes in the main parser that require more than 4 operands. Of course some
/// sub parser could implement something that expects more than 4, in which case
/// we will have to revisit this, but it won't be a breaking change. Consider
/// that operands in the output are only 2 bytes, so a 4 value operand array is
/// already only allowing for 4 bits per value on average, which is pretty tight
/// for anything other than bit flags.
uint256 constant OPERAND_VALUES_LENGTH = 4;

/// The parser is stateful. This struct keeps track of the entire state.
/// @param activeSourcePtr The pointer to the current source being built.
/// The active source being pointed to is:
/// - low 16 bits: bitwise offset into the source for the next word to be
///   written. Starts at 0x20. Once a source is no longer the active source, i.e.
///   it is full and a member of the LL tail, the offset is replaced with a
///   pointer to the next source (towards the head) to build a doubly linked
///   list.
/// - mid 16 bits: pointer to the previous active source (towards the tail). This
///   is a linked list of sources that are built RTL and then reversed to LTR to
///   eval.
/// - high bits: 4 byte opcodes and operand pairs.
/// @param sourcesBuilder A builder for the sources array. This is a 256 bit
/// integer where each 16 bits is a literal memory pointer to a source.
/// @param fsm The finite state machine representation of the parser.
/// - bit 0: LHS/RHS => 0 = LHS, 1 = RHS
/// - bit 1: yang/yin => 0 = yin, 1 = yang
/// - bit 2: word end => 0 = not end, 1 = end
/// - bit 3: accepting inputs => 0 = not accepting, 1 = accepting
/// - bit 4: interstitial => 0 = not interstitial, 1 = interstitial
/// @param topLevel0 Memory region for stack word counters. The first byte is a
/// counter/offset into the region, which increments for every top level item
/// parsed on the RHS. The remaining 31 bytes are the word counters for each
/// stack item, which are incremented for every op pushed to the source. This is
/// reset to 0 for every new source.
/// @param topLevel1 31 additional bytes of stack words, allowing for 62 top
/// level stack items total per source. The final byte is used to count the
/// stack height according to the LHS for the current source. This is reset to 0
/// for every new source.
/// @param parenTracker0 Memory region for tracking pointers to words in the
/// source, and counters for the number of words in each paren group. The first
/// byte is a counter/offset into the region. The second byte is a phantom
/// counter for the root level, the remaining 30 bytes are the paren group words.
/// @param parenTracker1 32 additional bytes of paren group words.
/// @param lineTracker A 32 byte memory region for tracking the current line.
/// Will be partially reset for each line when `endLine` is called. Fully
/// reset when a new source is started.
/// Bytes from low to high:
/// - byte 0: Lowest byte is the number of LHS items parsed. This is the low
/// byte so that a simple ++ is a valid operation on the line tracker while
/// parsing the LHS. This is reset to 0 for each new line.
/// - byte 1: A snapshot of the first high byte of `topLevel0`, i.e. the offset
/// of top level items as at the beginning of the line. This is reset to the high
/// byte of `topLevel0` on each new line.
/// - bytes 2+: A sequence of 2 byte pointers to before the start of each top
/// level item, which is implictly after the end of the previous top level item.
/// Allows us to quickly find the start of the RHS source for each top level
/// item.
/// @param stackNames A linked list of stack names. As the parser encounters
/// named stack items it pushes them onto this linked list. The linked list is
/// in FILO order, so the first item on the stack is the last item in the list.
/// This makes it more efficient to reference more recent stack names on the RHS.
/// @param literalBloom A bloom filter of all the literals that have been
/// encountered so far. This is used to quickly dedupe literals.
/// @param constantsBuilder A builder for the constants array.
/// - low 16 bits: the height (length) of the constants array.
/// - high 240 bits: a linked list of constant values. Each constant value is
///   stored as a 256 bit key/value pair. The key is the fingerprint of the
///   constant value, and the value is the constant value itself.
/// @param literalParsers A 256 bit integer where each 16 bits is a function
/// pointer to a literal parser.
struct ParseState {
    /// @dev START things that are referenced directly in assembly by hardcoded
    /// offsets. E.g.
    /// - `pushOpToSource`
    /// - `snapshotSourceHeadToLineTracker`
    /// - `newSource`
    uint256 activeSourcePtr;
    uint256 topLevel0;
    uint256 topLevel1;
    uint256 parenTracker0;
    uint256 parenTracker1;
    uint256 lineTracker;
    /// - `pushSubParser`
    uint256 subParsers;
    /// @dev END things that are referenced directly in assembly by hardcoded
    /// offsets.
    uint256 sourcesBuilder;
    uint256 fsm;
    uint256 stackNames;
    uint256 stackNameBloom;
    uint256 constantsBuilder;
    uint256 constantsBloom;
    bytes literalParsers;
    bytes operandHandlers;
    uint256[] operandValues;
    ParseStackTracker stackTracker;
    bytes data;
    bytes meta;
}

library LibParseState {
    using LibParseState for ParseState;
    using LibParseStackTracker for ParseStackTracker;
    using LibParseError for ParseState;
    using LibParseLiteral for ParseState;

    function newActiveSourcePointer(uint256 oldActiveSourcePointer) internal pure returns (uint256) {
        uint256 activeSourcePtr;
        uint256 emptyActiveSource = EMPTY_ACTIVE_SOURCE;
        assembly ("memory-safe") {
            // The active source pointer MUST be aligned to 32 bytes because we
            // rely on alignment to know when we have filled a source and need
            // to create a new one, or need to jump through the linked list.
            activeSourcePtr := and(add(mload(0x40), 0x1F), not(0x1F))
            mstore(activeSourcePtr, or(emptyActiveSource, shl(0x10, oldActiveSourcePointer)))
            mstore(0x40, add(activeSourcePtr, 0x20))

            // The old tail head must now point back to the new tail head.
            mstore(oldActiveSourcePointer, or(and(mload(oldActiveSourcePointer), not(0xFFFF)), activeSourcePtr))
        }
        return activeSourcePtr;
    }

    function resetSource(ParseState memory state) internal pure {
        state.activeSourcePtr = newActiveSourcePointer(0);
        state.topLevel0 = 0;
        state.topLevel1 = 0;
        state.parenTracker0 = 0;
        state.parenTracker1 = 0;
        state.lineTracker = 0;

        // We don't reset sub parsers because they are global and immutable to
        // the parsing process.

        state.stackNames = 0;
        state.stackNameBloom = 0;
        state.stackTracker = ParseStackTracker.wrap(0);
    }

    function newState(bytes memory data, bytes memory meta, bytes memory operandHandlers, bytes memory literalParsers)
        internal
        pure
        returns (ParseState memory)
    {
        ParseState memory state = ParseState(
            // activeSource
            // (will be built in `newActiveSource`)
            0,
            // topLevel0
            0,
            // topLevel1
            0,
            // parenTracker0
            0,
            // parenTracker1
            0,
            // lineTracker
            // (will be built in `resetSource`)
            0,
            // sub parsers
            0,
            // sourcesBuilder
            0,
            // fsm
            FSM_DEFAULT,
            // stackNames
            0,
            // stackNameBloom
            0,
            // literalBloom
            0,
            // constantsBuilder
            0,
            // literalParsers
            literalParsers,
            // operandHandlers
            operandHandlers,
            // operandValues
            new uint256[](OPERAND_VALUES_LENGTH),
            // stackTracker
            ParseStackTracker.wrap(0),
            // data bytes
            data,
            // meta bytes
            meta
        );
        state.resetSource();
        return state;
    }

    function pushSubParser(ParseState memory state, uint256 cursor, uint256 subParser) internal pure {
        if (subParser > uint256(type(uint160).max)) {
            revert InvalidSubParser(state.parseErrorOffset(cursor));
        }

        uint256 tail = state.subParsers;
        // Move the tail off to a new allocation.
        uint256 tailPointer;
        assembly ("memory-safe") {
            tailPointer := mload(0x40)
            mstore(0x40, add(tailPointer, 0x20))
            mstore(tailPointer, tail)
        }
        // Put the tail pointer in the high bits of the new head.
        state.subParsers = subParser | tailPointer << 0xF0;
    }

    // Find the pointer to the first opcode in the source LL. Put it in the line
    // tracker at the appropriate offset.
    function snapshotSourceHeadToLineTracker(ParseState memory state) internal pure {
        uint256 activeSourcePtr = state.activeSourcePtr;
        assembly ("memory-safe") {
            let topLevel0Pointer := add(state, 0x20)
            let totalRHSTopLevel := byte(0, mload(topLevel0Pointer))
            // Only do stuff if the current word counter is zero.
            if iszero(byte(0, mload(add(topLevel0Pointer, add(totalRHSTopLevel, 1))))) {
                let byteOffset := div(and(mload(activeSourcePtr), 0xFFFF), 8)
                let sourceHead := add(activeSourcePtr, sub(0x20, byteOffset))

                let lineTracker := mload(add(state, 0xa0))
                let lineRHSTopLevel := sub(totalRHSTopLevel, byte(30, lineTracker))
                let offset := mul(0x10, add(lineRHSTopLevel, 1))
                lineTracker := or(lineTracker, shl(offset, sourceHead))
                mstore(add(state, 0xa0), lineTracker)
            }
        }
    }

    //slither-disable-next-line cyclomatic-complexity
    function endLine(ParseState memory state, uint256 cursor) internal pure {
        unchecked {
            {
                uint256 parenOffset;
                assembly ("memory-safe") {
                    parenOffset := byte(0, mload(add(state, 0x60)))
                }
                if (parenOffset > 0) {
                    revert UnclosedLeftParen(state.parseErrorOffset(cursor));
                }
            }

            // This will snapshot the current head of the source, which will be
            // the start of where we want to read for the final line RHS item,
            // if it exists.
            state.snapshotSourceHeadToLineTracker();

            // Preserve the accepting inputs flag but set
            // everything else back to defaults. Also set that
            // there is an active source.
            state.fsm = (FSM_DEFAULT & ~FSM_ACCEPTING_INPUTS_MASK) | (state.fsm & FSM_ACCEPTING_INPUTS_MASK)
                | FSM_ACTIVE_SOURCE_MASK;

            uint256 lineLHSItems = state.lineTracker & 0xFF;
            // Total number of RHS at top level is the top byte of topLevel0.
            uint256 totalRHSTopLevel = state.topLevel0 >> 0xf8;
            // Snapshot for RHS from start of line is second low byte of
            // lineTracker.
            uint256 lineRHSTopLevel = totalRHSTopLevel - ((state.lineTracker >> 8) & 0xFF);

            // If:
            // - we are accepting inputs
            // - the RHS on this line is empty
            // Then we treat the LHS items as inputs to the source. This means that
            // we need to move the RHS offset to the end of the LHS items. There MAY
            // be 0 LHS items, e.g. if the entire source is empty. This can only
            // happen at the start of the source, as any RHS item immediately flips
            // the FSM to not accepting inputs.
            if (lineRHSTopLevel == 0) {
                if (state.fsm & FSM_ACCEPTING_INPUTS_MASK == 0) {
                    revert NotAcceptingInputs(state.parseErrorOffset(cursor));
                } else {
                    // As there are no RHS opcodes yet we can simply set topLevel0 directly.
                    // This is the only case where we defer to the LHS to tell
                    // us how many top level items there are.
                    totalRHSTopLevel += lineLHSItems;
                    state.topLevel0 = totalRHSTopLevel << 0xf8;

                    // Push the inputs onto the stack tracker.
                    state.stackTracker = state.stackTracker.pushInputs(lineLHSItems);
                }
            }
            // If:
            // - there are multiple RHS items on this line
            // Then there must be the same number of LHS items. Multi or zero output
            // RHS top level items are NOT supported unless they are the only RHS
            // item on that line.
            else if (lineRHSTopLevel > 1) {
                if (lineLHSItems < lineRHSTopLevel) {
                    revert ExcessRHSItems(state.parseErrorOffset(cursor));
                } else if (lineLHSItems > lineRHSTopLevel) {
                    revert ExcessLHSItems(state.parseErrorOffset(cursor));
                }
            }

            // Follow pointers to the start of the RHS item.
            uint256 topLevelOffset = 1 + totalRHSTopLevel - lineRHSTopLevel;
            uint256 end = (0x10 * lineRHSTopLevel) + 0x20;
            for (uint256 offset = 0x20; offset < end; offset += 0x10) {
                uint256 itemSourceHead = (state.lineTracker >> offset) & 0xFFFF;
                uint256 opsDepth;
                assembly ("memory-safe") {
                    opsDepth := byte(0, mload(add(state, add(0x20, topLevelOffset))))
                }
                for (uint256 i = 1; i <= opsDepth; i++) {
                    {
                        // We've hit the end of a LL item so have to jump towards the
                        // tail to keep going. This makes the assumption that
                        // the relevant pointers are aligned to 32 bytes, which
                        // is handled on allocation in `newActiveSourcePointer`.
                        if (itemSourceHead % 0x20 == 0x1c) {
                            assembly ("memory-safe") {
                                itemSourceHead := shr(0xf0, mload(itemSourceHead))
                            }
                        }
                        uint256 opInputs;
                        assembly ("memory-safe") {
                            opInputs := byte(1, mload(itemSourceHead))
                        }
                        state.stackTracker = state.stackTracker.pop(opInputs);
                        // Nested multi or zero output RHS items are NOT
                        // supported. If the top level RHS item is the ONLY RHS
                        // item on the line then it MAY have multiple or zero
                        // outputs. In this case we defer to the LHS to tell us
                        // how many outputs there are. If the LHS is wrong then
                        // later integrity checks will need to flag it.
                        uint256 opOutputs = i == opsDepth && lineRHSTopLevel == 1 ? lineLHSItems : 1;
                        state.stackTracker = state.stackTracker.push(opOutputs);

                        // Merge the op outputs and inputs into a single byte.
                        if (opOutputs > 0x0F || opInputs > 0x0F) {
                            revert OpcodeIOOverflow(state.parseErrorOffset(cursor));
                        }
                        assembly ("memory-safe") {
                            mstore8(add(itemSourceHead, 1), or(shl(4, opOutputs), opInputs))
                        }
                    }
                    itemSourceHead += 4;
                }
                topLevelOffset++;
            }

            state.lineTracker = totalRHSTopLevel << 8;
        }
    }

    /// We potentially just closed out some group of arbitrarily nested parens
    /// OR a lone literal value at the top level. IF we are at the top level we
    /// move the immutable stack highwater mark forward 1 item, which moves the
    /// RHS offset forward 1 byte to start a new word counter.
    function highwater(ParseState memory state) internal pure {
        uint256 parenOffset;
        assembly ("memory-safe") {
            parenOffset := byte(0, mload(add(state, 0x60)))
        }
        if (parenOffset == 0) {
            uint256 newStackRHSOffset;
            assembly ("memory-safe") {
                let stackRHSOffsetPtr := add(state, 0x20)
                newStackRHSOffset := add(byte(0, mload(stackRHSOffsetPtr)), 1)
                mstore8(stackRHSOffsetPtr, newStackRHSOffset)
            }
            if (newStackRHSOffset == 0x3f) {
                revert ParseStackOverflow();
            }
        }
    }

    function constantValueBloom(uint256 value) internal pure returns (uint256 bloom) {
        return uint256(1) << (value % 256);
    }

    /// Includes a constant value in the constants linked list so that it will
    /// appear in the final constants array.
    function pushConstantValue(ParseState memory state, uint256 value) internal pure {
        unchecked {
            uint256 headPtr;
            uint256 tailPtr = state.constantsBuilder >> 0x10;
            assembly ("memory-safe") {
                // Allocate two words.
                headPtr := mload(0x40)
                mstore(0x40, add(headPtr, 0x40))

                // First word is the pointer to the tail of the LL.
                mstore(headPtr, tailPtr)
                // Second word is the value.
                mstore(add(headPtr, 0x20), value)
            }

            // Inc the constants height by 1 and set the new head pointer.
            state.constantsBuilder = ((state.constantsBuilder & 0xFFFF) + 1) | (headPtr << 0x10);

            // Merge in the value bloom.
            state.constantsBloom |= constantValueBloom(value);
        }
    }

    function pushLiteral(ParseState memory state, uint256 cursor, uint256 end) internal pure returns (uint256) {
        unchecked {
            uint256 constantValue;
            bool success;
            (success, cursor, constantValue) = state.tryParseLiteral(cursor, end);
            // Don't continue trying to push something that we can't parse.
            if (!success) {
                revert UnsupportedLiteralType(state.parseErrorOffset(cursor));
            }

            // Whether the constant is a duplicate.
            bool exists = false;

            // The index of the constant in the constants builder LL. This is
            // starting from the top of the linked list, so the final index is
            // the height of the linked list minus this value.
            uint256 t = 0;

            // If the constant is in the bloom filter, then it MAY be a
            // duplicate. Try to find the constant value in the linked list of
            // constants.
            //
            // If the constant is NOT in the bloom filter, then it is definitely
            // NOT a duplicate, so avoid traversing the linked list.
            //
            // Worst case is a false positive in the bloom filter, which means
            // we traverse the linked list and find no match. This is O(1) for
            // the bloom filter and O(n) for the linked list traversal.
            if (state.constantsBloom & constantValueBloom(constantValue) != 0) {
                uint256 tailPtr = state.constantsBuilder >> 0x10;
                while (tailPtr != 0 && !exists) {
                    ++t;
                    uint256 tailValue;
                    assembly ("memory-safe") {
                        tailValue := mload(add(tailPtr, 0x20))
                        tailPtr := mload(tailPtr)
                    }
                    exists = constantValue == tailValue;
                }
            }

            // Push the constant opcode to the source.
            // The index is either the height of the constants, if the constant
            // is NOT a duplicate, or the height minus the index of the
            // duplicate. This is because the final constants array is built
            // 0 indexed from the bottom of the linked list to the top.
            {
                uint256 constantsHeight = state.constantsBuilder & 0xFFFF;
                state.pushOpToSource(OPCODE_CONSTANT, Operand.wrap(exists ? constantsHeight - t : constantsHeight));
            }

            // If the literal is not a duplicate, then we need to add it to the
            // linked list of literals so that `t` can point to it, and we can
            // build the constants array from the values in the linked list
            // later.
            if (!exists) {
                state.pushConstantValue(constantValue);
            }

            return cursor;
        }
    }

    function pushOpToSource(ParseState memory state, uint256 opcode, Operand operand) internal pure {
        unchecked {
            // This might be a top level item so try to snapshot its pointer to
            // the line tracker before writing the stack counter.
            state.snapshotSourceHeadToLineTracker();

            // As soon as we push an op to source we can no longer accept inputs.
            state.fsm &= ~FSM_ACCEPTING_INPUTS_MASK;
            // We also have an active source;
            state.fsm |= FSM_ACTIVE_SOURCE_MASK;

            // Increment the top level stack counter for the current top level
            // word. MAY be setting 0 to 1 if this is the top level.
            assembly ("memory-safe") {
                // Hardcoded offset into the state struct.
                let counterOffset := add(state, 0x20)
                let counterPointer := add(counterOffset, add(byte(0, mload(counterOffset)), 1))
                // Increment the counter.
                mstore8(counterPointer, add(byte(0, mload(counterPointer)), 1))
            }

            uint256 activeSource;
            uint256 offset;
            uint256 activeSourcePointer = state.activeSourcePtr;
            assembly ("memory-safe") {
                activeSource := mload(activeSourcePointer)
                // The low 16 bits of the active source is the current offset.
                offset := and(activeSource, 0xFFFF)

                // The offset is in bits so for a byte pointer we need to divide
                // by 8, then add 4 to move to the operand low byte.
                let inputsBytePointer := sub(add(activeSourcePointer, 0x20), add(div(offset, 8), 4))

                // Increment the paren input counter. The input counter is for the paren
                // group that is currently being built. This means the counter is for
                // the paren group that is one level above the current paren offset.
                // Assumes that every word has exactly 1 output, therefore the input
                // counter always increases by 1.
                // Hardcoded offset into the state struct.
                let inputCounterPos := add(state, 0x60)
                inputCounterPos :=
                    add(
                        add(
                            inputCounterPos,
                            // the offset
                            byte(0, mload(inputCounterPos))
                        ),
                        // +2 for the reserved bytes -1 to move back to the counter
                        // for the previous paren group.
                        1
                    )
                // Increment the parent counter.
                mstore8(inputCounterPos, add(byte(0, mload(inputCounterPos)), 1))
                // Zero out the current counter.
                mstore8(add(inputCounterPos, 3), 0)

                // Write the operand low byte pointer into the paren tracker.
                // Move 3 bytes after the input counter pos, then shift down 32
                // bytes to accomodate the full mload.
                let parenTrackerPointer := sub(inputCounterPos, 29)
                mstore(parenTrackerPointer, or(and(mload(parenTrackerPointer), not(0xFFFF)), inputsBytePointer))
            }

            // We write sources RTL so they can run LTR.
            activeSource =
            // increment offset. We have 16 bits allocated to the offset and stop
            // processing at 0x100 so this never overflows into the actual source
            // data.
            activeSource + 0x20
            // include the operand. The operand is assumed to be 16 bits, so we shift
            // it into the correct position.
            | Operand.unwrap(operand) << offset
            // include new op. The opcode is assumed to be 8 bits, so we shift it
            // into the correct position, beyond the operand.
            | opcode << (offset + 0x18);
            assembly ("memory-safe") {
                mstore(activeSourcePointer, activeSource)
            }

            // We have filled the current source slot. Need to create a new active
            // source and fulfill the doubly linked list.
            if (offset == 0xe0) {
                state.activeSourcePtr = newActiveSourcePointer(activeSourcePointer);
            }
        }
    }

    function endSource(ParseState memory state) internal pure {
        uint256 sourcesBuilder = state.sourcesBuilder;
        uint256 offset = sourcesBuilder >> 0xf0;

        // End is the number of top level words in the source, which is the
        // byte offset index + 1.
        uint256 end;
        assembly ("memory-safe") {
            end := add(byte(0, mload(add(state, 0x20))), 1)
        }

        if (offset == 0xf0) {
            revert MaxSources();
        }
        // Follow the word counters to build the source with the correct
        // combination of LTR and RTL words. The stack needs to be built
        // LTR at the top level, so that as the evaluation proceeds LTR it
        // can reference previous items in subsequent items. However, the
        // stack is built RTL within each item, so that nested parens are
        // evaluated correctly similar to reverse polish notation.
        else {
            uint256 source;
            ParseStackTracker stackTracker = state.stackTracker;
            uint256 cursor = state.activeSourcePtr;
            assembly ("memory-safe") {
                // find the end of the LL tail.
                let tailPointer := and(shr(0x10, mload(cursor)), 0xFFFF)
                for {} iszero(iszero(tailPointer)) {} {
                    cursor := tailPointer
                    tailPointer := and(shr(0x10, mload(cursor)), 0xFFFF)
                }

                // Move cursor to the end of the end of the LL tail item.
                // This is 4 bytes from the end of the EVM word, to compensate
                // for the offset and pointer positions.
                tailPointer := cursor
                cursor := add(cursor, 0x1C)
                // leave space for the source prefix in the bytecode output.
                let length := 4
                source := mload(0x40)
                // Move over the source 32 byte length and the 4 byte prefix.
                let writeCursor := add(source, 0x20)
                writeCursor := add(writeCursor, 4)

                let counterCursor := add(state, 0x21)
                for {
                    let i := 0
                    let wordsTotal := byte(0, mload(counterCursor))
                    let wordsRemaining := wordsTotal
                } lt(i, end) {
                    i := add(i, 1)
                    counterCursor := add(counterCursor, 1)
                    wordsTotal := byte(0, mload(counterCursor))
                    wordsRemaining := wordsTotal
                } {
                    length := add(length, mul(wordsTotal, 4))
                    {
                        // 4 bytes per source word.
                        let tailItemWordsRemaining := div(sub(cursor, tailPointer), 4)
                        // loop to the tail item that contains the start of the words
                        // that we need to copy.
                        for {} gt(wordsRemaining, tailItemWordsRemaining) {} {
                            wordsRemaining := sub(wordsRemaining, tailItemWordsRemaining)
                            tailPointer := and(mload(tailPointer), 0xFFFF)
                            tailItemWordsRemaining := 7
                            cursor := add(tailPointer, 0x1C)
                        }
                    }

                    // Now the words remaining is lte the words remaining in the
                    // tail item. Move the cursor back to the start of the words
                    // and copy the passed over bytes to the write cursor.
                    {
                        let forwardTailPointer := tailPointer
                        let size := mul(wordsRemaining, 4)
                        cursor := sub(cursor, size)
                        mstore(writeCursor, mload(cursor))
                        writeCursor := add(writeCursor, size)

                        // Redefine wordsRemaining to be the number of words
                        // left to copy.
                        wordsRemaining := sub(wordsTotal, wordsRemaining)
                        // Move over whole tail items.
                        for {} gt(wordsRemaining, 7) {} {
                            wordsRemaining := sub(wordsRemaining, 7)
                            // Follow the forward tail pointer.
                            forwardTailPointer := and(shr(0x10, mload(forwardTailPointer)), 0xFFFF)
                            mstore(writeCursor, mload(forwardTailPointer))
                            writeCursor := add(writeCursor, 0x1c)
                        }
                        // Move over the remaining words in the tail item.
                        if gt(wordsRemaining, 0) {
                            forwardTailPointer := and(shr(0x10, mload(forwardTailPointer)), 0xFFFF)
                            mstore(writeCursor, mload(forwardTailPointer))
                            writeCursor := add(writeCursor, mul(wordsRemaining, 4))
                        }
                    }
                }
                // Store the bytes length in the source.
                mstore(source, length)
                // Store the opcodes length and stack tracker in the source
                // prefix.
                let prefixWritePointer := add(source, 4)
                mstore(
                    prefixWritePointer,
                    or(
                        and(mload(prefixWritePointer), not(0xFFFFFFFF)),
                        or(shl(0x18, sub(div(length, 4), 1)), stackTracker)
                    )
                )

                // Round up to the nearest 32 bytes to realign memory.
                mstore(0x40, and(add(writeCursor, 0x1f), not(0x1f)))
            }

            //slither-disable-next-line incorrect-shift
            state.sourcesBuilder =
                ((offset + 0x10) << 0xf0) | (source << offset) | (sourcesBuilder & ((1 << offset) - 1));

            // Reset source as we're done with this one.
            state.fsm &= ~FSM_ACTIVE_SOURCE_MASK;
            state.resetSource();
        }
    }

    function buildBytecode(ParseState memory state) internal pure returns (bytes memory bytecode) {
        unchecked {
            uint256 sourcesBuilder = state.sourcesBuilder;
            uint256 offsetEnd = (sourcesBuilder >> 0xf0);

            // Somehow the parser state for the active source was not reset
            // correctly, or the finalised offset is dangling. This implies that
            // we are building the overall sources array while still trying to
            // build one of the individual sources. This is a bug in the parser.
            uint256 activeSource;
            {
                uint256 activeSourcePointer = state.activeSourcePtr;
                assembly ("memory-safe") {
                    activeSource := mload(activeSourcePointer)
                }
            }

            if (activeSource != EMPTY_ACTIVE_SOURCE) {
                revert DanglingSource();
            }

            uint256 cursor;
            uint256 sourcesCount;
            uint256 sourcesStart;
            assembly ("memory-safe") {
                cursor := mload(0x40)
                bytecode := cursor
                // Move past the bytecode length, we will write this at the end.
                cursor := add(cursor, 0x20)

                // First byte is the number of sources.
                sourcesCount := div(offsetEnd, 0x10)
                mstore8(cursor, sourcesCount)
                cursor := add(cursor, 1)

                let pointersCursor := cursor

                // Skip past the pointer space. We'll back fill it.
                // Divide offsetEnd to convert from a bit to a byte shift.
                cursor := add(cursor, div(offsetEnd, 8))
                sourcesStart := cursor

                // Write total bytes length into bytecode. We do ths and handle
                // the allocation in this same assembly block for memory safety
                // for the compiler optimiser.
                let sourcesLength := 0
                let sourcePointers := 0
                for { let offset := 0 } lt(offset, offsetEnd) { offset := add(offset, 0x10) } {
                    let currentSourcePointer := and(shr(offset, sourcesBuilder), 0xFFFF)
                    // add 4 byte prefix to the length of the sources, all as
                    // bytes.
                    sourcePointers := or(sourcePointers, shl(sub(0xf0, offset), sourcesLength))
                    let currentSourceLength := mload(currentSourcePointer)

                    // Put the reference source pointer and length into the
                    // prefix so that we can use them to copy the actual data
                    // into the bytecode.
                    let tmpPrefix := shl(0xe0, or(shl(0x10, currentSourcePointer), currentSourceLength))
                    mstore(add(sourcesStart, sourcesLength), tmpPrefix)
                    sourcesLength := add(sourcesLength, currentSourceLength)
                }
                mstore(pointersCursor, or(mload(pointersCursor), sourcePointers))
                mstore(bytecode, add(sourcesLength, sub(sub(sourcesStart, 0x20), bytecode)))

                // Round up to the nearest 32 bytes past cursor to realign and
                // allocate memory.
                mstore(0x40, and(add(add(add(0x20, mload(bytecode)), bytecode), 0x1f), not(0x1f)))
            }

            // Loop over the sources and write them into the bytecode. Perhaps
            // there is a more efficient way to do this in the future that won't
            // cause each source to be written twice in memory.
            for (uint256 i = 0; i < sourcesCount; i++) {
                Pointer sourcePointer;
                uint256 length;
                Pointer targetPointer;
                assembly ("memory-safe") {
                    let relativePointer := and(mload(add(bytecode, add(3, mul(i, 2)))), 0xFFFF)
                    targetPointer := add(sourcesStart, relativePointer)
                    let tmpPrefix := mload(targetPointer)
                    sourcePointer := add(0x20, shr(0xf0, tmpPrefix))
                    length := and(shr(0xe0, tmpPrefix), 0xFFFF)
                }
                LibMemCpy.unsafeCopyBytesTo(sourcePointer, targetPointer, length);
            }
        }
    }

    function buildConstants(ParseState memory state) internal pure returns (uint256[] memory constants) {
        uint256 constantsHeight = state.constantsBuilder & 0xFFFF;
        uint256 tailPtr = state.constantsBuilder >> 0x10;

        assembly ("memory-safe") {
            let cursor := mload(0x40)
            constants := cursor
            mstore(cursor, constantsHeight)
            let end := cursor
            // Move the cursor to the end of the array. Write in reverse order
            // of the linked list traversal so that the constants are built
            // according to the stable indexes in the source from the linked
            // list base.
            cursor := add(cursor, mul(constantsHeight, 0x20))
            // Allocate one word past the cursor. This will be just after the
            // length if the constants array is empty. Otherwise it will be
            // just after the last constant.
            mstore(0x40, add(cursor, 0x20))
            // It MUST be equivalent to say that the cursor is above the end,
            // and that we are following tail pointers until they point to 0,
            // and that the cursor is moving as far as the constants height.
            // This is ensured by the fact that the constants height is only
            // incremented when a new constant is added to the linked list.
            for {} gt(cursor, end) {
                // Next item in the linked list.
                cursor := sub(cursor, 0x20)
                // tail pointer in tail keys is the low 16 bits under the
                // fingerprint, which is different from the tail pointer in
                // the constants builder, where it sits above the constants
                // height.
                tailPtr := and(mload(tailPtr), 0xFFFF)
            } {
                // Store the values not the keys.
                mstore(cursor, mload(add(tailPtr, 0x20)))
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {LibParseState, ParseState} from "./LibParseState.sol";
import {CMASK_WHITESPACE, CMASK_LITERAL_HEX_DISPATCH_START} from "./LibParseCMask.sol";
import {NoWhitespaceAfterUsingWordsFrom} from "../../error/ErrParse.sol";
import {LibParseError} from "./LibParseError.sol";
import {LibParseInterstitial} from "./LibParseInterstitial.sol";
import {LibParseLiteral} from "./literal/LibParseLiteral.sol";

bytes constant PRAGMA_KEYWORD_BYTES = bytes("using-words-from");
bytes32 constant PRAGMA_KEYWORD_BYTES32 = bytes32(PRAGMA_KEYWORD_BYTES);
uint256 constant PRAGMA_KEYWORD_BYTES_LENGTH = 16;
bytes32 constant PRAGMA_KEYWORD_MASK = bytes32(~((1 << (32 - PRAGMA_KEYWORD_BYTES_LENGTH) * 8) - 1));

library LibParsePragma {
    using LibParseError for ParseState;
    using LibParseInterstitial for ParseState;
    using LibParseLiteral for ParseState;
    using LibParseState for ParseState;

    function parsePragma(ParseState memory state, uint256 cursor, uint256 end) internal pure returns (uint256) {
        unchecked {
            // Not-pragma guard.
            {
                // There is a pragma if the cursor is pointing exactly at the bytes of
                // the pragma.
                bytes32 maybePragma;
                assembly ("memory-safe") {
                    maybePragma := mload(cursor)
                }
                // Bail without modifying the cursor if there's no pragma.
                if (maybePragma & PRAGMA_KEYWORD_MASK != PRAGMA_KEYWORD_BYTES32) {
                    return cursor;
                }
            }

            {
                // Move past the pragma keyword.
                cursor += PRAGMA_KEYWORD_BYTES_LENGTH;

                // Need at least one whitespace char after the pragma keyword.
                uint256 char;
                assembly ("memory-safe") {
                    //slither-disable-next-line incorrect-shift
                    char := shl(byte(0, mload(cursor)), 1)
                }
                if (char & CMASK_WHITESPACE == 0) {
                    revert NoWhitespaceAfterUsingWordsFrom(state.parseErrorOffset(cursor));
                }
                ++cursor;
            }

            while (cursor < end) {
                // It's fine to add comments for each pragma address.
                // This also has the effect of moving past the interstitial after
                // the last address as we don't break til just below.
                cursor = state.parseInterstitial(cursor, end);

                // Try to parse a literal and treat it as an address.
                bool success;
                uint256 value;
                (success, cursor, value) = state.tryParseLiteral(cursor, end);
                // If we didn't parse a literal, we're done with the pragma.
                if (!success) {
                    break;
                } else {
                    state.pushSubParser(cursor, value);
                }
            }

            return cursor;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {FSM_YANG_MASK, ParseState} from "./LibParseState.sol";
import {
    CMASK_COMMENT_HEAD,
    CMASK_WHITESPACE,
    COMMENT_END_SEQUENCE,
    COMMENT_START_SEQUENCE,
    CMASK_COMMENT_END_SEQUENCE_END
} from "./LibParseCMask.sol";
import {ParserOutOfBounds, MalformedCommentStart, UnclosedComment} from "../../error/ErrParse.sol";
import {LibParseError} from "./LibParseError.sol";
import {LibParse} from "./LibParse.sol";

library LibParseInterstitial {
    using LibParse for ParseState;
    using LibParseError for ParseState;
    using LibParseInterstitial for ParseState;

    /// The cursor currently points at the head of a comment. We need to skip
    /// over all data until we find the end of the comment. This MAY REVERT if
    /// the comment is malformed, e.g. if the comment doesn't start with `/*`.
    /// @param state The parser state.
    /// @param cursor The current cursor position.
    /// @return The new cursor position.
    function skipComment(ParseState memory state, uint256 cursor, uint256 end) internal pure returns (uint256) {
        // Set yang for comments to force a little breathing room between
        // comments and the next item.
        state.fsm |= FSM_YANG_MASK;

        // We're going to ignore overflow here because if either cursor or
        // end is anywhere near uint256 max something went very wrong
        // elsewhere already.
        unchecked {
            // It's an error if we can't fit the comment sequences in the
            // remaining data to parse.
            if (cursor + 4 > end) {
                revert UnclosedComment(state.parseErrorOffset(cursor));
            }

            // First check the comment opening sequence is not malformed.
            uint256 startSequence;
            assembly ("memory-safe") {
                startSequence := shr(0xf0, mload(cursor))
            }
            if (startSequence != COMMENT_START_SEQUENCE) {
                revert MalformedCommentStart(state.parseErrorOffset(cursor));
            }

            // Move past the start sequence.
            // The 3rd character can never be the end of the comment.
            // Consider the string /*/ which is not a valid comment.
            cursor += 3;

            bool foundEnd = false;
            while (cursor < end) {
                uint256 charByte;
                assembly ("memory-safe") {
                    charByte := byte(0, mload(cursor))
                }
                if (charByte == CMASK_COMMENT_END_SEQUENCE_END) {
                    // Maybe this is the end of the comment.
                    // Check the sequence.
                    uint256 endSequence;
                    assembly ("memory-safe") {
                        endSequence := shr(0xf0, mload(sub(cursor, 1)))
                    }
                    if (endSequence == COMMENT_END_SEQUENCE) {
                        // We found the end of the comment.
                        // Move past the end sequence and stop looping.
                        ++cursor;
                        foundEnd = true;
                        break;
                    }
                }
                ++cursor;
            }

            // If we didn't find the end of the comment, it's an error.
            if (!foundEnd) {
                revert UnclosedComment(state.parseErrorOffset(cursor));
            }

            return cursor;
        }
    }

    function skipWhitespace(ParseState memory state, uint256 cursor, uint256 end) internal pure returns (uint256) {
        unchecked {
            // Set ying as we now open to possibilities.
            state.fsm &= ~FSM_YANG_MASK;
            return LibParse.skipMask(cursor, end, CMASK_WHITESPACE);
        }
    }

    function parseInterstitial(ParseState memory state, uint256 cursor, uint256 end) internal pure returns (uint256) {
        while (cursor < end) {
            uint256 char;
            assembly ("memory-safe") {
                //slither-disable-next-line incorrect-shift
                char := shl(byte(0, mload(cursor)), 1)
            }
            if (char & CMASK_WHITESPACE > 0) {
                cursor = state.skipWhitespace(cursor, end);
            } else if (char & CMASK_COMMENT_HEAD > 0) {
                cursor = state.skipComment(cursor, end);
            } else {
                break;
            }
        }
        return cursor;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {ParseState} from "./LibParseState.sol";

library LibParseError {
    function parseErrorOffset(ParseState memory state, uint256 cursor) internal pure returns (uint256 offset) {
        bytes memory data = state.data;
        assembly ("memory-safe") {
            offset := sub(cursor, add(data, 0x20))
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {LibParseState, ParseState} from "./LibParseState.sol";
import {
    OPCODE_UNKNOWN,
    OPCODE_EXTERN,
    OPCODE_CONSTANT,
    OPCODE_CONTEXT,
    Operand
} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {LibBytecode, Pointer} from "rain.interpreter.interface/lib/bytecode/LibBytecode.sol";
import {ISubParserV2, COMPATIBLITY_V3} from "rain.interpreter.interface/interface/ISubParserV2.sol";
import {BadSubParserResult, UnknownWord, UnsupportedLiteralType} from "../../error/ErrParse.sol";
import {LibExtern, EncodedExternDispatch} from "../extern/LibExtern.sol";
import {IInterpreterExternV3} from "rain.interpreter.interface/interface/IInterpreterExternV3.sol";
import {ExternDispatchConstantsHeightOverflow} from "../../error/ErrSubParse.sol";
import {LibMemCpy} from "rain.solmem/lib/LibMemCpy.sol";
import {LibParseError} from "./LibParseError.sol";

library LibSubParse {
    using LibParseState for ParseState;
    using LibParseError for ParseState;

    /// Sub parse a word into a context grid position.
    function subParserContext(uint256 column, uint256 row)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        bytes memory bytecode;
        uint256 opIndex = OPCODE_CONTEXT;
        assembly ("memory-safe") {
            // Allocate the bytecode.
            // This is an UNALIGNED allocation.
            bytecode := mload(0x40)
            mstore(0x40, add(bytecode, 0x24))

            // The caller is responsible for ensuring the column and row are
            // within `uint8`.
            mstore8(add(bytecode, 0x23), column)
            mstore8(add(bytecode, 0x22), row)

            // 0 inputs 1 output.
            mstore8(add(bytecode, 0x21), 0x10)

            mstore8(add(bytecode, 0x20), opIndex)

            // Write the length of the bytes.
            mstore(bytecode, 4)
        }

        uint256[] memory constants;
        assembly ("memory-safe") {
            constants := mload(0x40)
            mstore(0x40, add(constants, 0x20))
            mstore(constants, 0)
        }

        return (true, bytecode, constants);
    }

    /// Sub parse a value into the bytecode that will run on the interpreter to
    /// push the given value onto the stack, using the constant opcode at eval.
    function subParserConstant(uint256 constantsHeight, uint256 value)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        // Build a constant opcode that the interpreter will run itself.
        bytes memory bytecode;
        uint256 opIndex = OPCODE_CONSTANT;
        assembly ("memory-safe") {
            // Allocate the bytecode.
            // This is an UNALIGNED allocation.
            bytecode := mload(0x40)
            mstore(0x40, add(bytecode, 0x24))

            // It's most efficient to store the constants height first, as it
            // is in theory multibyte (although it's not expected to be).
            // This also has the effect of zeroing out the inputs, which is what
            // we want, as long as the main parser respects the constants height
            // never being more than 2 bytes.
            mstore(add(bytecode, 4), constantsHeight)

            // 0 inputs 1 output.
            mstore8(add(bytecode, 0x21), 0x10)

            // Main opcode is constant.
            mstore8(add(bytecode, 0x20), opIndex)

            // Write the length of the bytes.
            mstore(bytecode, 4)
        }

        uint256[] memory constants;
        assembly ("memory-safe") {
            constants := mload(0x40)
            mstore(0x40, add(constants, 0x40))
            mstore(constants, 1)
            mstore(add(constants, 0x20), value)
        }

        return (true, bytecode, constants);
    }

    /// Sub parse a known extern opcode index into the bytecode that will run
    /// on the interpreter to call the given extern contract. This requires the
    /// parsing has already matched a word to the extern opcode index, so it
    /// implies the parse meta has been traversed and the parse index has been
    /// mapped to an extern opcode index somehow.
    function subParserExtern(
        IInterpreterExternV3 extern,
        uint256 constantsHeight,
        uint256 ioByte,
        Operand operand,
        uint256 opcodeIndex
    ) internal pure returns (bool, bytes memory, uint256[] memory) {
        // The constants height is an error check because the main parser can
        // provide two bytes for it. Everything else is expected to be more
        // directly controlled by the subparser itself.
        if (constantsHeight > 0xFFFF) {
            revert ExternDispatchConstantsHeightOverflow(constantsHeight);
        }
        // Build an extern call that dials back into the current contract at eval
        // time with the current opcode index.
        bytes memory bytecode;
        uint256 opIndex = OPCODE_EXTERN;
        assembly ("memory-safe") {
            // Allocate the bytecode.
            // This is an UNALIGNED allocation.
            bytecode := mload(0x40)
            mstore(0x40, add(bytecode, 0x24))
            mstore(add(bytecode, 4), constantsHeight)
            // The IO byte is inputs merged with outputs.
            mstore8(add(bytecode, 0x21), ioByte)
            // Main opcode is extern, to call back into current contract.
            mstore8(add(bytecode, 0x20), opIndex)
            // The bytes length is 4.
            mstore(bytecode, 4)
        }

        uint256 externDispatch = EncodedExternDispatch.unwrap(
            LibExtern.encodeExternCall(extern, LibExtern.encodeExternDispatch(opcodeIndex, operand))
        );

        uint256[] memory constants;
        assembly ("memory-safe") {
            constants := mload(0x40)
            mstore(0x40, add(constants, 0x40))
            mstore(constants, 1)
            mstore(add(constants, 0x20), externDispatch)
        }

        return (true, bytecode, constants);
    }

    function subParseWordSlice(ParseState memory state, uint256 cursor, uint256 end) internal pure {
        unchecked {
            for (; cursor < end; cursor += 4) {
                uint256 memoryAtCursor;
                assembly ("memory-safe") {
                    memoryAtCursor := mload(cursor)
                }
                if (memoryAtCursor >> 0xf8 == OPCODE_UNKNOWN) {
                    uint256 deref = state.subParsers;
                    while (deref != 0) {
                        ISubParserV2 subParser = ISubParserV2(address(uint160(deref)));
                        assembly ("memory-safe") {
                            deref := mload(shr(0xf0, deref))
                        }

                        // Subparse data is a fixed length header that provides the
                        // subparser some minimal additional contextual information
                        // then the rest of the data is the original string that the
                        // main parser could not understand.
                        // The header is:
                        // - 2 bytes: The current constant builder height. MAY be
                        //   used by the subparser to calculate indexes for the
                        //   constants it pushes.
                        // - 1 byte: The IO byte from the unknown op. MAY be used
                        //   by the subparser to calculate the IO byte for the op
                        //   it builds.
                        bytes memory data;
                        // The operand of the unknown opcode directly points at the
                        // data that we need to subparse.
                        assembly ("memory-safe") {
                            data := and(shr(0xe0, memoryAtCursor), 0xFFFF)
                        }
                        // We just need to fill in the header.
                        {
                            uint256 constantsBuilder = state.constantsBuilder;
                            assembly ("memory-safe") {
                                let header :=
                                    shl(
                                        0xe8,
                                        or(
                                            // IO byte is the second byte of the unknown op.
                                            byte(1, memoryAtCursor),
                                            // Constants builder height is the low 16 bits.
                                            shl(8, and(constantsBuilder, 0xFFFF))
                                        )
                                    )

                                let headerPtr := add(data, 0x20)
                                mstore(headerPtr, or(header, and(mload(headerPtr), not(shl(0xe8, 0xFFFFFF)))))
                            }
                        }

                        (bool success, bytes memory subBytecode, uint256[] memory subConstants) =
                            subParser.subParseWord(COMPATIBLITY_V3, data);
                        if (success) {
                            // The sub bytecode must be exactly 4 bytes to
                            // represent an op.
                            if (subBytecode.length != 4) {
                                revert BadSubParserResult(subBytecode);
                            }

                            {
                                // Copy the sub bytecode over the unknown op.
                                uint256 mask = 0xFFFFFFFF << 0xe0;
                                assembly ("memory-safe") {
                                    mstore(
                                        cursor,
                                        or(and(memoryAtCursor, not(mask)), and(mload(add(subBytecode, 0x20)), mask))
                                    )
                                }
                            }

                            for (uint256 i; i < subConstants.length; ++i) {
                                state.pushConstantValue(subConstants[i]);
                            }

                            // Stop looping over sub parsers now.
                            break;
                        }
                    }
                }

                // If the op was not replaced, then we need to error because we have
                // no idea what it is.
                assembly ("memory-safe") {
                    memoryAtCursor := mload(cursor)
                }
                if (memoryAtCursor >> 0xf8 == OPCODE_UNKNOWN) {
                    revert UnknownWord();
                }
            }
        }
    }

    function subParseWords(ParseState memory state, bytes memory bytecode)
        internal
        pure
        returns (bytes memory, uint256[] memory)
    {
        unchecked {
            uint256 sourceCount = LibBytecode.sourceCount(bytecode);
            for (uint256 sourceIndex; sourceIndex < sourceCount; ++sourceIndex) {
                // Start cursor at the pointer to the source.
                uint256 cursor = Pointer.unwrap(LibBytecode.sourcePointer(bytecode, sourceIndex)) + 4;
                uint256 end = cursor + (LibBytecode.sourceOpsCount(bytecode, sourceIndex) * 4);
                subParseWordSlice(state, cursor, end);
            }
            return (bytecode, state.buildConstants());
        }
    }

    function subParseLiteral(
        ParseState memory state,
        uint256 dispatchStart,
        uint256 dispatchEnd,
        uint256 bodyStart,
        uint256 bodyEnd
    ) internal pure returns (uint256) {
        unchecked {
            // Build the data for the subparser.
            bytes memory data;
            {
                uint256 copyPointer;
                uint256 dispatchLength = dispatchEnd - dispatchStart;
                uint256 bodyLength = bodyEnd - bodyStart;
                {
                    uint256 dataLength = 2 + dispatchLength + bodyLength;
                    assembly ("memory-safe") {
                        data := mload(0x40)
                        mstore(0x40, add(data, add(dataLength, 0x20)))
                        mstore(add(data, 2), dispatchLength)
                        mstore(data, dataLength)
                        copyPointer := add(data, 0x22)
                    }
                }
                LibMemCpy.unsafeCopyBytesTo(Pointer.wrap(dispatchStart), Pointer.wrap(copyPointer), dispatchLength);
                LibMemCpy.unsafeCopyBytesTo(
                    Pointer.wrap(bodyStart), Pointer.wrap(copyPointer + dispatchLength), bodyLength
                );
            }

            uint256 deref = state.subParsers;
            while (deref != 0) {
                ISubParserV2 subParser = ISubParserV2(address(uint160(deref)));
                assembly ("memory-safe") {
                    deref := mload(shr(0xf0, deref))
                }

                (bool success, uint256 value) = subParser.subParseLiteral(COMPATIBLITY_V3, data);
                if (success) {
                    return value;
                }
            }

            revert UnsupportedLiteralType(state.parseErrorOffset(dispatchStart));
        }
    }

    function consumeSubParseWordInputData(bytes memory data, bytes memory meta, bytes memory operandHandlers)
        internal
        pure
        returns (uint256 constantsHeight, uint256 ioByte, ParseState memory state)
    {
        uint256[] memory operandValues;
        assembly ("memory-safe") {
            // Pull the header out into EVM stack items.
            constantsHeight := and(mload(add(data, 2)), 0xFFFF)
            ioByte := and(mload(add(data, 3)), 0xFF)

            // Mutate the data to no longer have a header.
            let newLength := and(mload(add(data, 5)), 0xFFFF)
            data := add(data, 5)
            mstore(data, newLength)
            operandValues := add(data, add(newLength, 0x20))
        }
        // Literal parsers are empty for the sub parser as the main parser should
        // be handling all literals in operands. The sub parser handles literal
        // parsing as a dedicated interface seperately.
        state = LibParseState.newState(data, meta, operandHandlers, "");
        state.operandValues = operandValues;
    }

    function consumeSubParseLiteralInputData(bytes memory data)
        internal
        pure
        returns (uint256 dispatchStart, uint256 bodyStart, uint256 bodyEnd)
    {
        assembly ("memory-safe") {
            let dispatchLength := and(mload(add(data, 2)), 0xFFFF)
            dispatchStart := add(data, 0x22)
            bodyStart := add(dispatchStart, dispatchLength)
            bodyEnd := add(data, add(0x20, mload(data)))
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @title LibCast
/// @notice Additional type casting logic that the Solidity compiler doesn't
/// give us by default. A type cast (vs. conversion) is considered one where the
/// structure is unchanged by the cast. The cast does NOT (can't) check that the
/// input is a valid output, for example any integer MAY be cast to a function
/// pointer but almost all integers are NOT valid function pointers. It is the
/// calling context that MUST ensure the validity of the data, the cast will
/// merely retype the data in place, generally without additional checks.
/// As most structures in solidity have the same memory structure as a `uint256`
/// or fixed/dynamic array of `uint256` there are many conversions that can be
/// done with near zero or minimal overhead.
library LibCast {
    /// Retype an array of `uint256[]` to `address[]`.
    /// @param us_ The array of integers to cast to addresses.
    /// @return addresses_ The array of addresses cast from each integer.
    function asAddressesArray(uint256[] memory us_) internal pure returns (address[] memory addresses_) {
        assembly ("memory-safe") {
            addresses_ := us_
        }
    }

    function asUint256Array(address[] memory addresses_) internal pure returns (uint256[] memory us_) {
        assembly ("memory-safe") {
            us_ := addresses_
        }
    }

    /// Retype an array of `uint256[]` to `bytes32[]`.
    /// @param us_ The array of integers to cast to 32 byte words.
    /// @return b32s_ The array of 32 byte words.
    function asBytes32Array(uint256[] memory us_) internal pure returns (bytes32[] memory b32s_) {
        assembly ("memory-safe") {
            b32s_ := us_
        }
    }

    function asUint256Array(bytes32[] memory b32s_) internal pure returns (uint256[] memory us_) {
        assembly ("memory-safe") {
            us_ := b32s_
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {LibInterpreterStateNP, InterpreterStateNP} from "../state/LibInterpreterStateNP.sol";

import {LibMemCpy} from "rain.solmem/lib/LibMemCpy.sol";
import {LibMemoryKV, MemoryKV} from "rain.lib.memkv/lib/LibMemoryKV.sol";
import {LibBytecode} from "rain.interpreter.interface/lib/bytecode/LibBytecode.sol";
import {Pointer} from "rain.solmem/lib/LibPointer.sol";
import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";

/// Thrown when the inputs length does not match the expected inputs length.
/// @param expected The expected number of inputs.
/// @param actual The actual number of inputs.
error InputsLengthMismatch(uint256 expected, uint256 actual);

library LibEvalNP {
    using LibMemoryKV for MemoryKV;

    function evalLoopNP(
        InterpreterStateNP memory state,
        uint256 parentSourceIndex,
        Pointer stackTop,
        Pointer stackBottom
    ) internal view returns (Pointer) {
        uint256 sourceIndex = state.sourceIndex;
        uint256 cursor;
        uint256 end;
        uint256 m;
        uint256 fPointersStart;
        // We mod the indexes with the fsCount for each lookup to ensure that
        // the indexes are in bounds. A mod is cheaper than a bounds check.
        uint256 fsCount = state.fs.length / 2;
        {
            bytes memory bytecode = state.bytecode;
            bytes memory fPointers = state.fs;
            assembly ("memory-safe") {
                // SourceIndex is a uint16 so needs cleaning.
                sourceIndex := and(sourceIndex, 0xFFFF)
                // Cursor starts at the beginning of the source.
                cursor := add(bytecode, 0x20)
                let sourcesLength := byte(0, mload(cursor))
                cursor := add(cursor, 1)
                // Find start of sources.
                let sourcesStart := add(cursor, mul(sourcesLength, 2))
                // Find relative pointer to source.
                let sourcesPointer := shr(0xf0, mload(add(cursor, mul(sourceIndex, 2))))
                // Move cursor to start of source.
                cursor := add(sourcesStart, sourcesPointer)
                // Calculate the end.
                let opsLength := byte(0, mload(cursor))
                // Move cursor past 4 byte source prefix.
                cursor := add(cursor, 4)

                // Calculate the mod `m` which is the portion of the source
                // that can't be copied in 32 byte chunks.
                m := mod(opsLength, 8)

                // Each op is 4 bytes, and there's a 4 byte prefix for the
                // source. The initial end is only what can be processed in
                // 32 byte chunks.
                end := add(cursor, mul(sub(opsLength, m), 4))

                fPointersStart := add(fPointers, 0x20)
            }
        }

        function(InterpreterStateNP memory, Operand, Pointer)
                    internal
                    view
                    returns (Pointer) f;
        Operand operand;
        uint256 word;
        while (cursor < end) {
            assembly ("memory-safe") {
                word := mload(cursor)
            }

            // Process high bytes [28, 31]
            // f needs to be looked up from the fn pointers table.
            // operand is 3 bytes.
            assembly ("memory-safe") {
                f := shr(0xf0, mload(add(fPointersStart, mul(mod(byte(0, word), fsCount), 2))))
                operand := and(shr(0xe0, word), 0xFFFFFF)
            }
            stackTop = f(state, operand, stackTop);

            // Bytes [24, 27].
            assembly ("memory-safe") {
                f := shr(0xf0, mload(add(fPointersStart, mul(mod(byte(4, word), fsCount), 2))))
                operand := and(shr(0xc0, word), 0xFFFFFF)
            }
            stackTop = f(state, operand, stackTop);

            // Bytes [20, 23].
            assembly ("memory-safe") {
                f := shr(0xf0, mload(add(fPointersStart, mul(mod(byte(8, word), fsCount), 2))))
                operand := and(shr(0xa0, word), 0xFFFFFF)
            }
            stackTop = f(state, operand, stackTop);

            // Bytes [16, 19].
            assembly ("memory-safe") {
                f := shr(0xf0, mload(add(fPointersStart, mul(mod(byte(12, word), fsCount), 2))))
                operand := and(shr(0x80, word), 0xFFFFFF)
            }
            stackTop = f(state, operand, stackTop);

            // Bytes [12, 15].
            assembly ("memory-safe") {
                f := shr(0xf0, mload(add(fPointersStart, mul(mod(byte(16, word), fsCount), 2))))
                operand := and(shr(0x60, word), 0xFFFFFF)
            }
            stackTop = f(state, operand, stackTop);

            // Bytes [8, 11].
            assembly ("memory-safe") {
                f := shr(0xf0, mload(add(fPointersStart, mul(mod(byte(20, word), fsCount), 2))))
                operand := and(shr(0x40, word), 0xFFFFFF)
            }
            stackTop = f(state, operand, stackTop);

            // Bytes [4, 7].
            assembly ("memory-safe") {
                f := shr(0xf0, mload(add(fPointersStart, mul(mod(byte(24, word), fsCount), 2))))
                operand := and(shr(0x20, word), 0xFFFFFF)
            }
            stackTop = f(state, operand, stackTop);

            // Bytes [0, 3].
            assembly ("memory-safe") {
                f := shr(0xf0, mload(add(fPointersStart, mul(mod(byte(28, word), fsCount), 2))))
                operand := and(word, 0xFFFFFF)
            }
            stackTop = f(state, operand, stackTop);

            cursor += 0x20;
        }

        // Loop over the remainder.
        // Need to shift the cursor back 28 bytes so that we're reading from
        // its 4 low bits rather than high bits, to make the loop logic more
        // efficient.
        cursor -= 0x1c;
        end = cursor + m * 4;
        while (cursor < end) {
            assembly ("memory-safe") {
                word := mload(cursor)
                f := shr(0xf0, mload(add(fPointersStart, mul(mod(byte(28, word), fsCount), 2))))
                // 3 bytes mask.
                operand := and(word, 0xFFFFFF)
            }
            stackTop = f(state, operand, stackTop);
            cursor += 4;
        }

        LibInterpreterStateNP.stackTrace(parentSourceIndex, sourceIndex, stackTop, stackBottom);

        return stackTop;
    }

    function eval2(InterpreterStateNP memory state, uint256[] memory inputs, uint256 maxOutputs)
        internal
        view
        returns (uint256[] memory, uint256[] memory)
    {
        unchecked {
            // Use the bytecode's own definition of its IO. Clear example of
            // how the bytecode could accidentally or maliciously force OOB reads
            // if the integrity check is not run.
            (uint256 sourceInputs, uint256 sourceOutputs) =
                LibBytecode.sourceInputsOutputsLength(state.bytecode, state.sourceIndex);

            Pointer stackBottom;
            Pointer stackTop;
            {
                stackBottom = state.stackBottoms[state.sourceIndex];
                stackTop = stackBottom;
                // Copy inputs into place if needed.
                if (inputs.length > 0) {
                    // Inline some logic to avoid jumping due to function calls
                    // on hot path.
                    Pointer inputsDataPointer;
                    assembly ("memory-safe") {
                        // Move stack top by the number of inputs.
                        stackTop := sub(stackTop, mul(mload(inputs), 0x20))
                        inputsDataPointer := add(inputs, 0x20)
                    }
                    LibMemCpy.unsafeCopyWordsTo(inputsDataPointer, stackTop, inputs.length);
                } else if (inputs.length != sourceInputs) {
                    revert InputsLengthMismatch(sourceInputs, inputs.length);
                }
            }

            // Run the loop.
            // Parent source index and child are the same at the root eval.
            stackTop = evalLoopNP(state, state.sourceIndex, stackTop, stackBottom);

            // Convert the stack top pointer to an array with the correct length.
            // If the stack top is pointing to the base of Solidity's understanding
            // of the stack array, then this will simply write the same length over
            // the length the stack was initialized with, otherwise a shorter array
            // will be built within the bounds of the stack. After this point `tail`
            // and the original stack MUST be immutable as they're both pointing to
            // the same memory region.
            uint256 outputs = maxOutputs < sourceOutputs ? maxOutputs : sourceOutputs;
            uint256[] memory stack;
            assembly ("memory-safe") {
                stack := sub(stackTop, 0x20)
                mstore(stack, outputs)
            }

            return (stack, state.stateKV.toUint256Array());
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {SourceIndexV2, EncodedDispatch} from "../../interface/IInterpreterV2.sol";

/// @title LibEncodedDispatch
/// @notice Establishes and implements a convention for encoding an interpreter
/// dispatch. Handles encoding of several things required for efficient dispatch.
library LibEncodedDispatch {
    /// Builds an `EncodedDispatch` from its constituent parts.
    /// @param expression The onchain address of the expression to run.
    /// @param sourceIndex The index of the source to run within the expression
    /// as an entrypoint.
    /// @param maxOutputs The maximum outputs the caller can meaningfully use.
    /// If the interpreter returns a larger stack than this it is merely wasting
    /// gas across the external call boundary.
    /// @return The encoded dispatch.
    function encode2(address expression, SourceIndexV2 sourceIndex, uint256 maxOutputs)
        internal
        pure
        returns (EncodedDispatch)
    {
        // Both source index and max outputs are expected to be compile time
        // constants, or at least significantly less than type(uint16).max.
        // Generally a real world implementation would hit gas limits long before
        // either of these values overflowed. Rather than add the gas of
        // conditionals and errors to check for overflow, we simply truncate the
        // values to uint16.
        return EncodedDispatch.wrap(
            (uint256(uint160(expression)) << 0x20) | (uint256(uint16(SourceIndexV2.unwrap(sourceIndex))) << 0x10)
                | uint256(uint16(maxOutputs))
        );
    }

    function decode2(EncodedDispatch dispatch) internal pure returns (address, SourceIndexV2, uint256) {
        return (
            address(uint160(EncodedDispatch.unwrap(dispatch) >> 0x20)),
            SourceIndexV2.wrap(uint256(uint16(EncodedDispatch.unwrap(dispatch) >> 0x10))),
            uint256(uint16(EncodedDispatch.unwrap(dispatch)))
        );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {IInterpreterStoreV2, FullyQualifiedNamespace, SourceIndexV2} from "../IInterpreterV2.sol";

interface IInterpreterV3 {
    function functionPointers() external view returns (bytes calldata);

    function eval3(
        IInterpreterStoreV2 store,
        FullyQualifiedNamespace namespace,
        bytes calldata bytecode,
        SourceIndexV2 sourceIndex,
        uint256[][] calldata context,
        uint256[] calldata inputs
    ) external view returns (uint256[] calldata stack, uint256[] calldata writes);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {StateNamespace, FullyQualifiedNamespace} from "../../interface/IInterpreterV2.sol";

library LibNamespace {
    /// Standard way to elevate a caller-provided state namespace to a universal
    /// namespace that is disjoint from all other caller-provided namespaces.
    /// Essentially just hashes the `msg.sender` into the state namespace as-is.
    ///
    /// This is deterministic such that the same combination of state namespace
    /// and caller will produce the same fully qualified namespace, even across
    /// multiple transactions/blocks.
    ///
    /// @param stateNamespace The state namespace as specified by the caller.
    /// @param sender The caller this namespace is bound to.
    /// @return qualifiedNamespace A fully qualified namespace that cannot
    /// collide with any other state namespace specified by any other caller.
    function qualifyNamespace(StateNamespace stateNamespace, address sender)
        internal
        pure
        returns (FullyQualifiedNamespace qualifiedNamespace)
    {
        assembly ("memory-safe") {
            mstore(0, stateNamespace)
            mstore(0x20, sender)
            qualifiedNamespace := keccak256(0, 0x40)
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

/// @dev Workaround for https://github.com/foundry-rs/foundry/issues/6572
contract ErrBytecode {}

/// Thrown when a bytecode source index is out of bounds.
/// @param bytecode The bytecode that was inspected.
/// @param sourceIndex The source index that was out of bounds.
error SourceIndexOutOfBounds(bytes bytecode, uint256 sourceIndex);

/// Thrown when a bytecode reports itself as 0 sources but has more than 1 byte.
/// @param bytecode The bytecode that was inspected.
error UnexpectedSources(bytes bytecode);

/// Thrown when bytes are discovered between the offsets and the sources.
/// @param bytecode The bytecode that was inspected.
error UnexpectedTrailingOffsetBytes(bytes bytecode);

/// Thrown when the end of a source as self reported by its header doesnt match
/// the start of the next source or the end of the bytecode.
/// @param bytecode The bytecode that was inspected.
error TruncatedSource(bytes bytecode);

/// Thrown when the offset to a source points to a location that cannot fit a
/// header before the start of the next source or the end of the bytecode.
/// @param bytecode The bytecode that was inspected.
error TruncatedHeader(bytes bytecode);

/// Thrown when the bytecode is truncated before the end of the header offsets.
/// @param bytecode The bytecode that was inspected.
error TruncatedHeaderOffsets(bytes bytecode);

/// Thrown when the stack sizings, allocation, inputs and outputs, are not
/// monotonically increasing.
/// @param bytecode The bytecode that was inspected.
/// @param relativeOffset The relative offset of the source that was inspected.
error StackSizingsNotMonotonic(bytes bytecode, uint256 relativeOffset);

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @dev Workaround for https://github.com/foundry-rs/foundry/issues/6572
contract ErrExtern {}

/// Thrown when the extern interface is not supported.
error NotAnExternContract(address extern);

/// Thrown by the extern contract at runtime when the inputs don't match the
/// expected inputs.
/// @param expected The expected number of inputs.
/// @param actual The actual number of inputs.
error BadInputs(uint256 expected, uint256 actual);

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {EncodedExternDispatch, ExternDispatch} from "./deprecated/IInterpreterExternV2.sol";

/// @title IInterpreterExternV3
/// Handle a single dispatch from some calling contract with an array of
/// inputs and array of outputs. Ostensibly useful to build "word packs" for
/// `IInterpreterV2` so that less frequently used words can be provided in
/// a less efficient format, but without bloating the base interpreter in
/// terms of code size. Effectively allows unlimited words to exist as externs
/// alongside interpreters.
///
/// The difference between V2 and V3 is that V3 integrates with integrity checks.
interface IInterpreterExternV3 {
    /// Checks the integrity of some extern call.
    /// @param dispatch Encoded information about the extern to dispatch.
    /// Analogous to the opcode/operand in the interpreter.
    /// @param expectedInputs The number of inputs expected for the dispatched
    /// logic.
    /// @param expectedOutputs The number of outputs expected for the dispatched
    /// logic.
    /// @return actualInputs The actual number of inputs for the dispatched
    /// logic.
    /// @return actualOutputs The actual number of outputs for the dispatched
    /// logic.
    function externIntegrity(ExternDispatch dispatch, uint256 expectedInputs, uint256 expectedOutputs)
        external
        view
        returns (uint256 actualInputs, uint256 actualOutputs);

    /// Handles a single dispatch.
    /// @param dispatch Encoded information about the extern to dispatch.
    /// Analogous to the opcode/operand in the interpreter.
    /// @param inputs The array of inputs for the dispatched logic.
    /// @return outputs The result of the dispatched logic.
    function extern(ExternDispatch dispatch, uint256[] calldata inputs)
        external
        view
        returns (uint256[] calldata outputs);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {IInterpreterV2, Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {
    IInterpreterExternV3,
    ExternDispatch,
    EncodedExternDispatch
} from "rain.interpreter.interface/interface/IInterpreterExternV3.sol";

/// @title LibExtern
/// Defines and implements an encoding and decoding scheme for the data that
/// controls the behaviour of externs.
library LibExtern {
    /// Converts an opcode and operand pair into a single 32-byte word.
    /// The encoding scheme is:
    /// - bits [0,16): the operand
    /// - bits [16,32): the opcode
    /// IMPORTANT: The encoding process does not check that either the opcode or
    /// operand fit within 16 bits. This is the responsibility of the caller.
    function encodeExternDispatch(uint256 opcode, Operand operand) internal pure returns (ExternDispatch) {
        return ExternDispatch.wrap(opcode << 0x10 | Operand.unwrap(operand));
    }

    /// Inverse of `encodeExternDispatch`.
    function decodeExternDispatch(ExternDispatch dispatch) internal pure returns (uint256, Operand) {
        return (ExternDispatch.unwrap(dispatch) >> 0x10, Operand.wrap(uint16(ExternDispatch.unwrap(dispatch))));
    }

    /// Encodes an extern address and dispatch pair into a single 32-byte word.
    /// This is the full data required to actually call an extern contract.
    /// The encoding scheme is:
    /// - bits [0,160): the address of the extern contract
    /// - bits [160,176): the dispatch operand
    /// - bits [176,192): the dispatch opcode
    /// Note that the high bits are implied by a correctly encoded
    /// `ExternDispatch`. Use `encodeExternDispatch` to ensure this.
    /// IMPORTANT: The encoding process does not check that any of the values
    /// fit within their respective bit ranges. This is the responsibility of
    /// the caller.
    function encodeExternCall(IInterpreterExternV3 extern, ExternDispatch dispatch)
        internal
        pure
        returns (EncodedExternDispatch)
    {
        return EncodedExternDispatch.wrap(uint256(uint160(address(extern))) | ExternDispatch.unwrap(dispatch) << 160);
    }

    /// Inverse of `encodeExternCall`.
    function decodeExternCall(EncodedExternDispatch dispatch)
        internal
        pure
        returns (IInterpreterExternV3, ExternDispatch)
    {
        return (
            IInterpreterExternV3(address(uint160(EncodedExternDispatch.unwrap(dispatch)))),
            ExternDispatch.wrap(EncodedExternDispatch.unwrap(dispatch) >> 160)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @dev Workaround for https://github.com/foundry-rs/foundry/issues/6572
contract ErrBitwise {}

/// Thrown during integrity check when a bitwise shift operation is attempted
/// with a shift amount greater than 255 or 0. As the shift amount is taken from
/// the operand, this is a compile time error so there's no need to support
/// behaviour that would always evaluate to 0 or be a noop.
error UnsupportedBitwiseShiftAmount(uint256 shiftAmount);

/// Thrown during integrity check when bitwise (en|de)coding would be truncated
/// due to the end bit position being beyond 256.
/// @param startBit The start of the OOB encoding.
/// @param length The length of the OOB encoding.
error TruncatedBitwiseEncoding(uint256 startBit, uint256 length);

/// Thrown during integrity check when the length of a bitwise (en|de)coding
/// would be 0.
error ZeroLengthBitwiseEncoding();

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5313.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the Light Contract Ownership Standard.
 *
 * A standardized minimal interface required to identify an account that controls a contract
 *
 * _Available since v4.9._
 */
interface IERC5313 {
    /**
     * @dev Gets the address of the owner.
     */
    function owner() external view returns (address);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

/// @dev This masks out the top 3 bits of a uint256, leaving the lower 253 bits
/// intact. This ensures the length never exceeds 31 bytes when converting to
/// and from strings.
uint256 constant INT_OR_A_STRING_MASK = ~(uint256(7) << 253);

/// Represents string data as an unsigned 32 byte integer. The highest 3 bits are
/// ignored when interpreting the integer as a string length, naturally limiting
/// the length of the string to 31 bytes. The lowest 31 bytes are the string
/// data, with the leftmost byte being the first byte of the string.
///
/// If lengths greater than 31 bytes are attempted to be stored, the string
/// conversion will exhibit the "weird" behaviour of truncating the output to
/// modulo 32 of the length. If the caller wishes to avoid this behaviour, they
/// should check and error on lengths greater than 31 bytes.
type IntOrAString is uint256;

/// @title LibIntOrAString
/// @notice A library for converting between `IntOrAString` and `string`.
/// Note that unlike analogous libraries such as Open Zepplin's `ShortStrings`,
/// there is no intention to provide fallbacks for strings longer than 31 bytes.
/// The expectation is that `IntOrAString` will be used in contexts where there
/// really is no sensible fallback, because there is ONLY 32 bytes of space
/// available, such as a single storage slot or a single evm word on the stack or
/// in memory. By not supporting fallbacks, we can provide a simpler and more
/// efficient library, at the expense of requiring all strings to be shorter than
/// 32 bytes. If strings are longer than 31 bytes, the library will truncate the
/// output to modulo 32 of the length, which is probably not what you want, so
/// you should try to avoid ever working with longer strings, e.g. by checking
/// the length and erroring if it is too long, or otherwise providing the same
/// guarantee.
library LibIntOrAString {
    /// Converts an `IntOrAString` to a `string`, truncating the length to modulo
    /// 32 of the leftmost byte. Much in the same way as converting `bytes` to
    /// a string, there are NO checks or guarantees that the string is valid
    /// according to some encoding such as UTF-8 or ASCII. If the `intOrAString`
    /// contains garbage bytes beyond its string length, these will be copied
    /// into the output string, also beyond its string length. For most use cases
    /// this is fine, as strings aren't typically read beyond their length, but
    /// it is something to be aware of if those garbage bytes are sensitive
    /// somehow. The `fromString` function will always zero out these bytes
    /// beyond the string length, so if the `intOrAString` was created from a
    /// string using this library, there won't be any non-zero bytes beyond the
    /// length.
    function toString(IntOrAString intOrAString) internal pure returns (string memory) {
        string memory s;
        uint256 mask = INT_OR_A_STRING_MASK;
        assembly ("memory-safe") {
            // Point s to the free memory region.
            s := mload(0x40)
            // Allocate 64 bytes for the string, including the length field. As
            // the input data is 32 bytes always, this is always enough.
            mstore(0x40, add(s, 0x40))
            // Zero out the region allocated for the string so no garbage data
            // pre-allocation is present in the final string.
            mstore(s, 0)
            mstore(add(s, 0x20), 0)
            // Copy the input data to the string. As the length is masked to 5
            // bits, this is always safe in that the length of the output string
            // won't exceed the length of the original input data.
            mstore(add(s, 0x1F), and(intOrAString, mask))
        }
        return s;
    }

    /// Converts a `string` to an `IntOrAString`, truncating the length to modulo
    /// 32 in the process. Any bytes beyond the length of the string will be
    /// zeroed out, to ensure that no potentially sensitive data in memory is
    /// copied into the `IntOrAString`.
    function fromString(string memory s) internal pure returns (IntOrAString) {
        IntOrAString intOrAString;
        uint256 mask = INT_OR_A_STRING_MASK;
        assembly ("memory-safe") {
            intOrAString := and(mload(add(s, 0x1F)), mask)
            let garbageLength := sub(0x1F, byte(0, intOrAString))
            //slither-disable-next-line incorrect-shift
            let garbageMask := not(sub(shl(mul(garbageLength, 8), 1), 1))
            intOrAString := and(intOrAString, garbageMask)
        }
        return intOrAString;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

/*

██████╗ ██████╗ ██████╗ ███╗   ███╗ █████╗ ████████╗██╗  ██╗
██╔══██╗██╔══██╗██╔══██╗████╗ ████║██╔══██╗╚══██╔══╝██║  ██║
██████╔╝██████╔╝██████╔╝██╔████╔██║███████║   ██║   ███████║
██╔═══╝ ██╔══██╗██╔══██╗██║╚██╔╝██║██╔══██║   ██║   ██╔══██║
██║     ██║  ██║██████╔╝██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║
╚═╝     ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝

██╗   ██╗██████╗  ██████╗  ██████╗ ██╗  ██╗ ██╗ █████╗
██║   ██║██╔══██╗██╔════╝ ██╔═████╗╚██╗██╔╝███║██╔══██╗
██║   ██║██║  ██║███████╗ ██║██╔██║ ╚███╔╝ ╚██║╚█████╔╝
██║   ██║██║  ██║██╔═══██╗████╔╝██║ ██╔██╗  ██║██╔══██╗
╚██████╔╝██████╔╝╚██████╔╝╚██████╔╝██╔╝ ██╗ ██║╚█████╔╝
 ╚═════╝ ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═╝ ╚════╝

*/

import "./ud60x18/Casting.sol";
import "./ud60x18/Constants.sol";
import "./ud60x18/Conversions.sol";
import "./ud60x18/Errors.sol";
import "./ud60x18/Helpers.sol";
import "./ud60x18/Math.sol";
import "./ud60x18/ValueType.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./FixedPointDecimalConstants.sol";

/// @title LibWillOverflow
/// @notice Often we want to know if some calculation is expected to overflow.
/// Notably this is important for fuzzing as we have to be able to set
/// expectations for arbitrary inputs over as broad a range of values as
/// possible.
library LibWillOverflow {
    /// Relevant logic taken direct from Open Zeppelin.
    /// @param x As per Open Zeppelin.
    /// @param y As per Open Zeppelin.
    /// @param denominator As per Open Zeppelin.
    /// @return True if mulDiv will overflow.
    function mulDivWillOverflow(uint256 x, uint256 y, uint256 denominator) internal pure returns (bool) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly ("memory-safe") {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }
        return !(denominator > prod1);
    }

    /// True if `scaleUp` will overflow.
    /// @param a The number to scale up.
    /// @param scaleBy The number of orders of magnitude to scale up by.
    /// @return True if `scaleUp` will overflow.
    function scaleUpWillOverflow(uint256 a, uint256 scaleBy) internal pure returns (bool) {
        unchecked {
            if (a == 0) {
                return false;
            }
            if (scaleBy >= OVERFLOW_RESCALE_OOMS) {
                return true;
            }
            uint256 b = 10 ** scaleBy;
            uint256 c = a * b;
            return c / b != a;
        }
    }

    /// True if `scaleDown` will round.
    /// @param a The number to scale down.
    /// @param scaleDownBy The number of orders of magnitude to scale down by.
    /// @return True if `scaleDown` will round.
    function scaleDownWillRound(uint256 a, uint256 scaleDownBy) internal pure returns (bool) {
        if (scaleDownBy >= OVERFLOW_RESCALE_OOMS) {
            return a != 0;
        }
        uint256 b = 10 ** scaleDownBy;
        uint256 c = a / b;
        // Discovering precision loss is the whole point of this check so the
        // thing slither is complaining about is exactly what we're measuring.
        //slither-disable-next-line divide-before-multiply
        return c * b != a;
    }

    /// True if `scale18` will overflow.
    /// @param a The number to scale.
    /// @param decimals The current number of decimals of `a`.
    /// @param flags The flags to use.
    /// @return True if `scale18` will overflow.
    function scale18WillOverflow(uint256 a, uint256 decimals, uint256 flags) internal pure returns (bool) {
        if (decimals < FIXED_POINT_DECIMALS && (FLAG_SATURATE & flags == 0)) {
            return scaleUpWillOverflow(a, FIXED_POINT_DECIMALS - decimals);
        } else {
            return false;
        }
    }

    /// True if `scaleN` will overflow.
    /// @param a The number to scale.
    /// @param decimals The current number of decimals of `a`.
    /// @param flags The flags to use.
    /// @return True if `scaleN` will overflow.
    function scaleNWillOverflow(uint256 a, uint256 decimals, uint256 flags) internal pure returns (bool) {
        if (decimals > FIXED_POINT_DECIMALS && (FLAG_SATURATE & flags == 0)) {
            return scaleUpWillOverflow(a, decimals - FIXED_POINT_DECIMALS);
        } else {
            return false;
        }
    }

    /// True if `scaleBy` will overflow.
    /// @param a The number to scale.
    /// @param scaleBy The number of orders of magnitude to scale by.
    /// @param flags The flags to use.
    /// @return True if `scaleBy` will overflow.
    function scaleByWillOverflow(uint256 a, int8 scaleBy, uint256 flags) internal pure returns (bool) {
        // If we're scaling up and not saturating check the overflow.
        if (scaleBy > 0 && (FLAG_SATURATE & flags == 0)) {
            return scaleUpWillOverflow(a, uint8(scaleBy));
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./FixedPointDecimalConstants.sol";

/// @title FixedPointDecimalScale
/// @notice Tools to scale unsigned values to/from 18 decimal fixed point
/// representation.
///
/// Overflows error and underflows are rounded up or down explicitly.
///
/// The max uint256 as decimal is roughly 1e77 so scaling values comparable to
/// 1e18 is unlikely to ever overflow in most contexts. For a typical use case
/// involving tokens, the entire supply of a token rescaled up a full 18 decimals
/// would still put it "only" in the region of ~1e40 which has a full 30 orders
/// of magnitude buffer before running into saturation issues. However, there's
/// no theoretical reason that a token or any other use case couldn't use large
/// numbers or extremely precise decimals that would push this library to
/// overflow point, so it MUST be treated with caution around the edge cases.
///
/// Scaling down ANY fixed point decimal also reduces the precision which can
/// lead to  dust or in the worst case trapped funds if subsequent subtraction
/// overflows a rounded-down number. Consider using saturating subtraction for
/// safety against previously downscaled values, and whether trapped dust is a
/// significant issue. If you need to retain full/arbitrary precision in the case
/// of downscaling DO NOT use this library.
///
/// All rescaling and/or division operations in this library require a rounding
/// flag. This allows and forces the caller to specify where dust sits due to
/// rounding. For example the caller could round up when taking tokens from
/// `msg.sender` and round down when returning them, ensuring that any dust in
/// the round trip accumulates in the contract rather than opening an exploit or
/// reverting and trapping all funds. This is exactly how the ERC4626 vault spec
/// handles dust and is a good reference point in general. Typically the contract
/// holding tokens and non-interactive participants should be favoured by
/// rounding calculations rather than active participants. This is because we
/// assume that an active participant, e.g. `msg.sender`, knowns something we
/// don't and is carefully crafting an attack, so we are most conservative and
/// suspicious of their inputs and actions.
library LibFixedPointDecimalScale {
    /// Scales `a` up by a specified number of decimals.
    /// @param a The number to scale up.
    /// @param scaleUpBy Number of orders of magnitude to scale `b_` up by.
    /// Errors if overflows.
    /// @return b `a` scaled up by `scaleUpBy`.
    function scaleUp(uint256 a, uint256 scaleUpBy) internal pure returns (uint256 b) {
        // Checked power is expensive so don't do that.
        unchecked {
            b = 10 ** scaleUpBy;
        }
        b = a * b;

        // We know exactly when 10 ** X overflows so replay the checked version
        // to get the standard Solidity overflow behaviour. The branching logic
        // here is still ~230 gas cheaper than unconditionally running the
        // overflow checks. We're optimising for standardisation rather than gas
        // in the unhappy revert case.
        if (scaleUpBy >= OVERFLOW_RESCALE_OOMS) {
            b = a == 0 ? 0 : 10 ** scaleUpBy;
        }
    }

    /// Identical to `scaleUp` but saturates instead of reverting on overflow.
    /// @param a As per `scaleUp`.
    /// @param scaleUpBy As per `scaleUp`.
    /// @return c As per `scaleUp` but saturates as `type(uint256).max` on
    /// overflow.
    function scaleUpSaturating(uint256 a, uint256 scaleUpBy) internal pure returns (uint256 c) {
        unchecked {
            if (scaleUpBy >= OVERFLOW_RESCALE_OOMS) {
                c = a == 0 ? 0 : type(uint256).max;
            } else {
                // Adapted from saturatingMath.
                // Inlining everything here saves ~250-300+ gas relative to slow.
                uint256 b_ = 10 ** scaleUpBy;
                c = a * b_;
                // Checking b_ here allows us to skip an "is zero" check because even
                // 10 ** 0 = 1, so we have a positive lower bound on b_.
                c = c / b_ == a ? c : type(uint256).max;
            }
        }
    }

    /// Scales `a` down by a specified number of decimals, rounding down.
    /// Used internally by several other functions in this lib.
    /// @param a The number to scale down.
    /// @param scaleDownBy Number of orders of magnitude to scale `a` down by.
    /// Overflows if greater than 77.
    /// @return c `a` scaled down by `scaleDownBy` and rounded down.
    function scaleDown(uint256 a, uint256 scaleDownBy) internal pure returns (uint256) {
        unchecked {
            return scaleDownBy >= OVERFLOW_RESCALE_OOMS ? 0 : a / (10 ** scaleDownBy);
        }
    }

    /// Scales `a` down by a specified number of decimals, rounding up.
    /// Used internally by several other functions in this lib.
    /// @param a The number to scale down.
    /// @param scaleDownBy Number of orders of magnitude to scale `a` down by.
    /// Overflows if greater than 77.
    /// @return c `a` scaled down by `scaleDownBy` and rounded up.
    function scaleDownRoundUp(uint256 a, uint256 scaleDownBy) internal pure returns (uint256 c) {
        unchecked {
            if (scaleDownBy >= OVERFLOW_RESCALE_OOMS) {
                c = a == 0 ? 0 : 1;
            } else {
                uint256 b = 10 ** scaleDownBy;
                c = a / b;

                // Intentionally doing a divide before multiply here to detect
                // the need to round up.
                //slither-disable-next-line divide-before-multiply
                if (a != c * b) {
                    c += 1;
                }
            }
        }
    }

    /// Scale a fixed point decimal of some scale factor to 18 decimals.
    /// @param a Some fixed point decimal value.
    /// @param decimals The number of fixed decimals of `a`.
    /// @param flags Controls rounding and saturation.
    /// @return `a` scaled to 18 decimals.
    function scale18(uint256 a, uint256 decimals, uint256 flags) internal pure returns (uint256) {
        unchecked {
            if (FIXED_POINT_DECIMALS > decimals) {
                uint256 scaleUpBy = FIXED_POINT_DECIMALS - decimals;
                if (flags & FLAG_SATURATE > 0) {
                    return scaleUpSaturating(a, scaleUpBy);
                } else {
                    return scaleUp(a, scaleUpBy);
                }
            } else if (decimals > FIXED_POINT_DECIMALS) {
                uint256 scaleDownBy = decimals - FIXED_POINT_DECIMALS;
                if (flags & FLAG_ROUND_UP > 0) {
                    return scaleDownRoundUp(a, scaleDownBy);
                } else {
                    return scaleDown(a, scaleDownBy);
                }
            } else {
                return a;
            }
        }
    }

    /// Scale an 18 decimal fixed point value to some other scale.
    /// Exactly the inverse behaviour of `scale18`. Where `scale18` would scale
    /// up, `scaleN` scales down, and vice versa.
    /// @param a An 18 decimal fixed point number.
    /// @param targetDecimals The new scale of `a`.
    /// @param flags Controls rounding and saturation.
    /// @return `a` rescaled from 18 to `targetDecimals`.
    function scaleN(uint256 a, uint256 targetDecimals, uint256 flags) internal pure returns (uint256) {
        unchecked {
            if (FIXED_POINT_DECIMALS > targetDecimals) {
                uint256 scaleDownBy = FIXED_POINT_DECIMALS - targetDecimals;
                if (flags & FLAG_ROUND_UP > 0) {
                    return scaleDownRoundUp(a, scaleDownBy);
                } else {
                    return scaleDown(a, scaleDownBy);
                }
            } else if (targetDecimals > FIXED_POINT_DECIMALS) {
                uint256 scaleUpBy = targetDecimals - FIXED_POINT_DECIMALS;
                if (flags & FLAG_SATURATE > 0) {
                    return scaleUpSaturating(a, scaleUpBy);
                } else {
                    return scaleUp(a, scaleUpBy);
                }
            } else {
                return a;
            }
        }
    }

    /// Scale a fixed point up or down by `ooms` orders of magnitude.
    /// Notably `scaleBy` is a SIGNED integer so scaling down by negative OOMS
    /// IS supported.
    /// @param a Some integer of any scale.
    /// @param ooms OOMs to scale `a` up or down by. This is a SIGNED int8
    /// which means it can be negative, and also means that sign extension MUST
    /// be considered if changing it to another type.
    /// @param flags Controls rounding and saturating.
    /// @return `a` rescaled according to `ooms`.
    function scaleBy(uint256 a, int8 ooms, uint256 flags) internal pure returns (uint256) {
        unchecked {
            if (ooms > 0) {
                if (flags & FLAG_SATURATE > 0) {
                    return scaleUpSaturating(a, uint8(ooms));
                } else {
                    return scaleUp(a, uint8(ooms));
                }
            } else if (ooms < 0) {
                // We know that ooms is negative here, so we can convert it
                // to an absolute value with bitwise NOT + 1.
                // This is slightly less gas than multiplying by negative 1 and
                // casting it, and handles the case of -128 without overflow.
                uint8 scaleDownBy = uint8(~ooms) + 1;
                if (flags & FLAG_ROUND_UP > 0) {
                    return scaleDownRoundUp(a, scaleDownBy);
                } else {
                    return scaleDown(a, scaleDownBy);
                }
            } else {
                return a;
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @dev Binary 1.
uint256 constant B_1 = 2 ** 1 - 1;
/// @dev Binary 11.
uint256 constant B_11 = 2 ** 2 - 1;
/// @dev Binary 111.
uint256 constant B_111 = 2 ** 3 - 1;
/// @dev Binary 1111.
uint256 constant B_1111 = 2 ** 4 - 1;
/// @dev Binary 11111.
uint256 constant B_11111 = 2 ** 5 - 1;
/// @dev Binary 111111.
uint256 constant B_111111 = 2 ** 6 - 1;
/// @dev Binary 1111111.
uint256 constant B_1111111 = 2 ** 7 - 1;
/// @dev Binary 11111111.
uint256 constant B_11111111 = 2 ** 8 - 1;
/// @dev Binary 111111111.
uint256 constant B_111111111 = 2 ** 9 - 1;
/// @dev Binary 1111111111.
uint256 constant B_1111111111 = 2 ** 10 - 1;
/// @dev Binary 11111111111.
uint256 constant B_11111111111 = 2 ** 11 - 1;
/// @dev Binary 111111111111.
uint256 constant B_111111111111 = 2 ** 12 - 1;
/// @dev Binary 1111111111111.
uint256 constant B_1111111111111 = 2 ** 13 - 1;
/// @dev Binary 11111111111111.
uint256 constant B_11111111111111 = 2 ** 14 - 1;
/// @dev Binary 111111111111111.
uint256 constant B_111111111111111 = 2 ** 15 - 1;
/// @dev Binary 1111111111111111.
uint256 constant B_1111111111111111 = 2 ** 16 - 1;

/// @dev Bitmask for 1 bit.
uint256 constant MASK_1BIT = B_1;
/// @dev Bitmask for 2 bits.
uint256 constant MASK_2BIT = B_11;
/// @dev Bitmask for 3 bits.
uint256 constant MASK_3BIT = B_111;
/// @dev Bitmask for 4 bits.
uint256 constant MASK_4BIT = B_1111;
/// @dev Bitmask for 5 bits.
uint256 constant MASK_5BIT = B_11111;
/// @dev Bitmask for 6 bits.
uint256 constant MASK_6BIT = B_111111;
/// @dev Bitmask for 7 bits.
uint256 constant MASK_7BIT = B_1111111;
/// @dev Bitmask for 8 bits.
uint256 constant MASK_8BIT = B_11111111;
/// @dev Bitmask for 9 bits.
uint256 constant MASK_9BIT = B_111111111;
/// @dev Bitmask for 10 bits.
uint256 constant MASK_10BIT = B_1111111111;
/// @dev Bitmask for 11 bits.
uint256 constant MASK_11BIT = B_11111111111;
/// @dev Bitmask for 12 bits.
uint256 constant MASK_12BIT = B_111111111111;
/// @dev Bitmask for 13 bits.
uint256 constant MASK_13BIT = B_1111111111111;
/// @dev Bitmask for 14 bits.
uint256 constant MASK_14BIT = B_11111111111111;
/// @dev Bitmask for 15 bits.
uint256 constant MASK_15BIT = B_111111111111111;
/// @dev Bitmask for 16 bits.
uint256 constant MASK_16BIT = B_1111111111111111;

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @title SaturatingMath
/// @notice Sometimes we neither want math operations to error nor wrap around
/// on an overflow or underflow. In the case of transferring assets an error
/// may cause assets to be locked in an irretrievable state within the erroring
/// contract, e.g. due to a tiny rounding/calculation error. We also can't have
/// assets underflowing and attempting to approve/transfer "infinity" when we
/// wanted "almost or exactly zero" but some calculation bug underflowed zero.
/// Ideally there are no calculation mistakes, but in guarding against bugs it
/// may be safer pragmatically to saturate arithmatic at the numeric bounds.
/// Note that saturating div is not supported because 0/0 is undefined.
library SaturatingMath {
    /// Saturating addition.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return Minimum of a_ + b_ and max uint256.
    function saturatingAdd(uint256 a_, uint256 b_) internal pure returns (uint256) {
        unchecked {
            uint256 c_ = a_ + b_;
            return c_ < a_ ? type(uint256).max : c_;
        }
    }

    /// Saturating subtraction.
    /// @param a_ Minuend.
    /// @param b_ Subtrahend.
    /// @return Maximum of a_ - b_ and 0.
    function saturatingSub(uint256 a_, uint256 b_) internal pure returns (uint256) {
        unchecked {
            return a_ > b_ ? a_ - b_ : 0;
        }
    }

    /// Saturating multiplication.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return Minimum of a_ * b_ and max uint256.
    function saturatingMul(uint256 a_, uint256 b_) internal pure returns (uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being
            // zero, but the benefit is lost if 'b' is also tested.
            // https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a_ == 0) return 0;
            uint256 c_ = a_ * b_;
            return c_ / a_ != b_ ? type(uint256).max : c_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {ParseStackUnderflow} from "../../error/ErrParse.sol";

type ParseStackTracker is uint256;

library LibParseStackTracker {
    using LibParseStackTracker for ParseStackTracker;

    /// Pushing inputs requires special handling as the inputs need to be tallied
    /// separately and in addition to the regular stack pushes.
    function pushInputs(ParseStackTracker tracker, uint256 n) internal pure returns (ParseStackTracker) {
        unchecked {
            tracker = tracker.push(n);
            uint256 inputs = (ParseStackTracker.unwrap(tracker) >> 8) & 0xFF;
            inputs += n;
            return ParseStackTracker.wrap((ParseStackTracker.unwrap(tracker) & ~uint256(0xFF00)) | (inputs << 8));
        }
    }

    function push(ParseStackTracker tracker, uint256 n) internal pure returns (ParseStackTracker) {
        unchecked {
            uint256 current = ParseStackTracker.unwrap(tracker) & 0xFF;
            uint256 inputs = (ParseStackTracker.unwrap(tracker) >> 8) & 0xFF;
            uint256 max = ParseStackTracker.unwrap(tracker) >> 0x10;
            current += n;
            if (current > max) {
                max = current;
            }
            return ParseStackTracker.wrap(current | (inputs << 8) | (max << 0x10));
        }
    }

    function pop(ParseStackTracker tracker, uint256 n) internal pure returns (ParseStackTracker) {
        unchecked {
            uint256 current = ParseStackTracker.unwrap(tracker) & 0xFF;
            if (current < n) {
                revert ParseStackUnderflow();
            }
            return ParseStackTracker.wrap(ParseStackTracker.unwrap(tracker) - n);
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

// Reexports for implementations to use.
import {AuthoringMetaV2} from "./IParserV1.sol";
import {Operand} from "./IInterpreterV2.sol";

/// @dev A compatibility version for the subparser interface.
///
/// ## Literal parsing
///
/// The structure of data for this version is:
/// - bytes [0,1]: The length of the dispatch data as 2 bytes.
/// - bytes [2,N-1+2]: The dispatch data, where N is the length of the dispatch
///   data as defined by the first 2 bytes. This is used by the sub parser to
///   decide which literal parser to use. If there are no matches the sub parser
///   MUST return false and MUST NOT revert.
/// - bytes [N+2,...]: The literal data that the sub parser is being asked to
///   parse. The sub parser MUST revert if it cannot parse the literal, once it
///   has determined that it is the correct sub parser to handle the literal.
///
/// ## Word parsing
///
/// The structure of data for this version is:
/// - bytes [0,1]: The current height of the constants array on the main parser.
/// - bytes [2,2]: The IO byte, that at the time of writing represents the
///   number of inputs to the word.
/// - bytes [3,4]; Two bytes that encodes N where N is the length in bytes of the
///   rainlang word that could not be parsed in bytes.
/// - bytes [5, N+5]: A string slice that the parser could not parse. For well
///   formed rainlang it will be a word WITHOUT any associated operands. The
///   parsing of operands is handled by the main parser, and the subparser is
///   only expected to parse the word itself and handle the pre-parsed operand
///   values.
/// - bytes [N+5,...]: The operands that the main parser has already parsed as
///   a standard `uint256[]` array. The subparser is expected to handle these
///   operands as-is, and return bytecode that is compatible with the operand
///   values. The first word of the array is the array length.
bytes32 constant COMPATIBLITY_V2 = keccak256("2023.12.28 Rainlang ISubParserV2");

/// @dev A compatibility version for the subparser interface.
///
/// Identical to COMPATIBLITY_V2, except the IO byte in word parsing now encodes
/// both the inputs and outputs. The IO byte is [2,2] in the word parsing data.
/// The high/leftmost 4 bits of the IO byte encode the number of outputs, and the
/// low/rightmost 4 bits of the IO byte encode the number of inputs. This implies
/// that the number of inputs and outputs must each be less than 16.
bytes32 constant COMPATIBLITY_V3 = keccak256("2024.02.15 Rainlang ISubParserV3");

interface ISubParserV2 {
    /// The sub parser is being asked to attempt to parse a literal that the main
    /// parser has failed to parse. The sub parser MUST ONLY attempt to parse a
    /// literal that matches both the compatibility version and that the data
    /// represents a literal that the sub parser is capable of parsing. It is
    /// expected that the main parser will attempt multiple sub parsers in order
    /// to parse a literal, so the sub parser MUST NOT revert if it does not know
    /// how to parse the literal, as some other sub parser may be able to parse
    /// it. The sub parser MUST return false if it does not know how to parse the
    /// literal, and MUST return true if it does know how to parse the literal,
    /// as well as the value of the literal.
    /// If the sub parser knows how to parse some literal, but the data is
    /// malformed, the sub parser MUST revert.
    /// If the compatibility version is not supported, the sub parser MUST
    /// revert.
    ///
    /// Literal parsing is the process of taking a sequence of bytes and
    /// converting it into a value that is known at compile time.
    ///
    /// @param compatibility The compatibility version of the parser that the
    /// sub parser must support in order to parse the literal.
    /// @param data The data that represents the literal. The structure of this
    /// is defined by the conventions for the compatibility version.
    /// @return success Whether the sub parser knows how to parse the literal.
    /// If the sub parser does know how to handle the literal but cannot due to
    /// malformed data, or some other reason, it MUST revert.
    /// @return value The value of the literal.
    function subParseLiteral(bytes32 compatibility, bytes calldata data)
        external
        pure
        returns (bool success, uint256 value);

    /// The sub parser is being asked to attempt to parse a word that the main
    /// parser has failed to parse. The sub parser MUST ONLY attempt to parse a
    /// word that matches both the compatibility version and that the data
    /// represents a word that the sub parser is capable of parsing. It is
    /// expected that the main parser will attempt multiple sub parsers in order
    /// to parse a word, so the sub parser MUST NOT revert if it does not know
    /// how to parse the word, as some other sub parser may be able to parse
    /// it. The sub parser MUST return false if it does not know how to parse the
    /// word, and MUST return true if it does know how to parse the word,
    /// as well as the bytecode and constants of the word.
    /// If the sub parser knows how to parse some word, but the data is
    /// malformed, the sub parser MUST revert.
    ///
    /// Word parsing is the process of taking a sequence of bytes and
    /// converting it into a sequence of bytecode and constants that is known at
    /// compile time, and will be executed at runtime. As the bytecode executes
    /// on the interpreter, not the (sub)parser, the sub parser relies on
    /// convention to ensure that it is producing valid bytecode and constants.
    /// These conventions are defined by the compatibility versions.
    ///
    /// @param compatibility The compatibility version of the parser that the
    /// sub parser must support in order to parse the word.
    /// @param data The data that represents the word.
    /// @return success Whether the sub parser knows how to parse the word.
    /// If the sub parser does know how to handle the word but cannot due to
    /// malformed data, or some other reason, it MUST revert.
    /// @return bytecode The bytecode of the word.
    /// @return constants The constants of the word. This MAY be empty if the
    /// bytecode does not require any new constants. These constants will be
    /// merged into the constants of the main parser.
    function subParseWord(bytes32 compatibility, bytes calldata data)
        external
        pure
        returns (bool success, bytes memory bytecode, uint256[] memory constants);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @dev When a subparser is not compatible with the main parser it MUST error
/// on `subParse` calls rather than simply return false.
error IncompatibleSubParser();

/// @dev Thrown when a subparser is asked to build an extern dispatch when the
/// constants height is outside the range a single byte can represent.
error ExternDispatchConstantsHeightOverflow(uint256 constantsHeight);

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {EncodedExternDispatch, ExternDispatch} from "./IInterpreterExternV1.sol";

/// @title IInterpreterExternV2
/// Handle a single dispatch from some calling contract with an array of
/// inputs and array of outputs. Ostensibly useful to build "word packs" for
/// `IInterpreterV1` so that less frequently used words can be provided in
/// a less efficient format, but without bloating the base interpreter in
/// terms of code size. Effectively allows unlimited words to exist as externs
/// alongside interpreters.
///
/// The only difference between V2 and V1 is that V2 allows for the inputs and
/// outputs to be in calldata rather than memory.
interface IInterpreterExternV2 {
    /// Handles a single dispatch.
    /// @param dispatch Encoded information about the extern to dispatch.
    /// Analogous to the opcode/operand in the interpreter.
    /// @param inputs The array of inputs for the dispatched logic.
    /// @return outputs The result of the dispatched logic.
    function extern(ExternDispatch dispatch, uint256[] calldata inputs)
        external
        view
        returns (uint256[] calldata outputs);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Errors.sol" as CastingErrors;
import { MAX_UINT128, MAX_UINT40 } from "../Common.sol";
import { uMAX_SD1x18 } from "../sd1x18/Constants.sol";
import { SD1x18 } from "../sd1x18/ValueType.sol";
import { uMAX_SD59x18 } from "../sd59x18/Constants.sol";
import { SD59x18 } from "../sd59x18/ValueType.sol";
import { uMAX_UD2x18 } from "../ud2x18/Constants.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "./ValueType.sol";

/// @notice Casts a UD60x18 number into SD1x18.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_SD1x18`.
function intoSD1x18(UD60x18 x) pure returns (SD1x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > uint256(int256(uMAX_SD1x18))) {
        revert CastingErrors.PRBMath_UD60x18_IntoSD1x18_Overflow(x);
    }
    result = SD1x18.wrap(int64(uint64(xUint)));
}

/// @notice Casts a UD60x18 number into UD2x18.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_UD2x18`.
function intoUD2x18(UD60x18 x) pure returns (UD2x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > uMAX_UD2x18) {
        revert CastingErrors.PRBMath_UD60x18_IntoUD2x18_Overflow(x);
    }
    result = UD2x18.wrap(uint64(xUint));
}

/// @notice Casts a UD60x18 number into SD59x18.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_SD59x18`.
function intoSD59x18(UD60x18 x) pure returns (SD59x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > uint256(uMAX_SD59x18)) {
        revert CastingErrors.PRBMath_UD60x18_IntoSD59x18_Overflow(x);
    }
    result = SD59x18.wrap(int256(xUint));
}

/// @notice Casts a UD60x18 number into uint128.
/// @dev This is basically an alias for {unwrap}.
function intoUint256(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x);
}

/// @notice Casts a UD60x18 number into uint128.
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UINT128`.
function intoUint128(UD60x18 x) pure returns (uint128 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > MAX_UINT128) {
        revert CastingErrors.PRBMath_UD60x18_IntoUint128_Overflow(x);
    }
    result = uint128(xUint);
}

/// @notice Casts a UD60x18 number into uint40.
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(UD60x18 x) pure returns (uint40 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > MAX_UINT40) {
        revert CastingErrors.PRBMath_UD60x18_IntoUint40_Overflow(x);
    }
    result = uint40(xUint);
}

/// @notice Alias for {wrap}.
function ud(uint256 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(x);
}

/// @notice Alias for {wrap}.
function ud60x18(uint256 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(x);
}

/// @notice Unwraps a UD60x18 number into uint256.
function unwrap(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x);
}

/// @notice Wraps a uint256 number into the UD60x18 value type.
function wrap(uint256 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { UD60x18 } from "./ValueType.sol";

// NOTICE: the "u" prefix stands for "unwrapped".

/// @dev Euler's number as a UD60x18 number.
UD60x18 constant E = UD60x18.wrap(2_718281828459045235);

/// @dev The maximum input permitted in {exp}.
uint256 constant uEXP_MAX_INPUT = 133_084258667509499440;
UD60x18 constant EXP_MAX_INPUT = UD60x18.wrap(uEXP_MAX_INPUT);

/// @dev The maximum input permitted in {exp2}.
uint256 constant uEXP2_MAX_INPUT = 192e18 - 1;
UD60x18 constant EXP2_MAX_INPUT = UD60x18.wrap(uEXP2_MAX_INPUT);

/// @dev Half the UNIT number.
uint256 constant uHALF_UNIT = 0.5e18;
UD60x18 constant HALF_UNIT = UD60x18.wrap(uHALF_UNIT);

/// @dev $log_2(10)$ as a UD60x18 number.
uint256 constant uLOG2_10 = 3_321928094887362347;
UD60x18 constant LOG2_10 = UD60x18.wrap(uLOG2_10);

/// @dev $log_2(e)$ as a UD60x18 number.
uint256 constant uLOG2_E = 1_442695040888963407;
UD60x18 constant LOG2_E = UD60x18.wrap(uLOG2_E);

/// @dev The maximum value a UD60x18 number can have.
uint256 constant uMAX_UD60x18 = 115792089237316195423570985008687907853269984665640564039457_584007913129639935;
UD60x18 constant MAX_UD60x18 = UD60x18.wrap(uMAX_UD60x18);

/// @dev The maximum whole value a UD60x18 number can have.
uint256 constant uMAX_WHOLE_UD60x18 = 115792089237316195423570985008687907853269984665640564039457_000000000000000000;
UD60x18 constant MAX_WHOLE_UD60x18 = UD60x18.wrap(uMAX_WHOLE_UD60x18);

/// @dev PI as a UD60x18 number.
UD60x18 constant PI = UD60x18.wrap(3_141592653589793238);

/// @dev The unit number, which gives the decimal precision of UD60x18.
uint256 constant uUNIT = 1e18;
UD60x18 constant UNIT = UD60x18.wrap(uUNIT);

/// @dev The unit number squared.
uint256 constant uUNIT_SQUARED = 1e36;
UD60x18 constant UNIT_SQUARED = UD60x18.wrap(uUNIT_SQUARED);

/// @dev Zero as a UD60x18 number.
UD60x18 constant ZERO = UD60x18.wrap(0);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { uMAX_UD60x18, uUNIT } from "./Constants.sol";
import { PRBMath_UD60x18_Convert_Overflow } from "./Errors.sol";
import { UD60x18 } from "./ValueType.sol";

/// @notice Converts a UD60x18 number to a simple integer by dividing it by `UNIT`.
/// @dev The result is rounded toward zero.
/// @param x The UD60x18 number to convert.
/// @return result The same number in basic integer form.
function convert(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x) / uUNIT;
}

/// @notice Converts a simple integer to UD60x18 by multiplying it by `UNIT`.
///
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UD60x18 / UNIT`.
///
/// @param x The basic integer to convert.
/// @param result The same number converted to UD60x18.
function convert(uint256 x) pure returns (UD60x18 result) {
    if (x > uMAX_UD60x18 / uUNIT) {
        revert PRBMath_UD60x18_Convert_Overflow(x);
    }
    unchecked {
        result = UD60x18.wrap(x * uUNIT);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { UD60x18 } from "./ValueType.sol";

/// @notice Thrown when ceiling a number overflows UD60x18.
error PRBMath_UD60x18_Ceil_Overflow(UD60x18 x);

/// @notice Thrown when converting a basic integer to the fixed-point format overflows UD60x18.
error PRBMath_UD60x18_Convert_Overflow(uint256 x);

/// @notice Thrown when taking the natural exponent of a base greater than 133_084258667509499441.
error PRBMath_UD60x18_Exp_InputTooBig(UD60x18 x);

/// @notice Thrown when taking the binary exponent of a base greater than 192e18.
error PRBMath_UD60x18_Exp2_InputTooBig(UD60x18 x);

/// @notice Thrown when taking the geometric mean of two numbers and multiplying them overflows UD60x18.
error PRBMath_UD60x18_Gm_Overflow(UD60x18 x, UD60x18 y);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in SD1x18.
error PRBMath_UD60x18_IntoSD1x18_Overflow(UD60x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in SD59x18.
error PRBMath_UD60x18_IntoSD59x18_Overflow(UD60x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in UD2x18.
error PRBMath_UD60x18_IntoUD2x18_Overflow(UD60x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint128.
error PRBMath_UD60x18_IntoUint128_Overflow(UD60x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint40.
error PRBMath_UD60x18_IntoUint40_Overflow(UD60x18 x);

/// @notice Thrown when taking the logarithm of a number less than 1.
error PRBMath_UD60x18_Log_InputTooSmall(UD60x18 x);

/// @notice Thrown when calculating the square root overflows UD60x18.
error PRBMath_UD60x18_Sqrt_Overflow(UD60x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { wrap } from "./Casting.sol";
import { UD60x18 } from "./ValueType.sol";

/// @notice Implements the checked addition operation (+) in the UD60x18 type.
function add(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() + y.unwrap());
}

/// @notice Implements the AND (&) bitwise operation in the UD60x18 type.
function and(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() & bits);
}

/// @notice Implements the AND (&) bitwise operation in the UD60x18 type.
function and2(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() & y.unwrap());
}

/// @notice Implements the equal operation (==) in the UD60x18 type.
function eq(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() == y.unwrap();
}

/// @notice Implements the greater than operation (>) in the UD60x18 type.
function gt(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() > y.unwrap();
}

/// @notice Implements the greater than or equal to operation (>=) in the UD60x18 type.
function gte(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() >= y.unwrap();
}

/// @notice Implements a zero comparison check function in the UD60x18 type.
function isZero(UD60x18 x) pure returns (bool result) {
    // This wouldn't work if x could be negative.
    result = x.unwrap() == 0;
}

/// @notice Implements the left shift operation (<<) in the UD60x18 type.
function lshift(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() << bits);
}

/// @notice Implements the lower than operation (<) in the UD60x18 type.
function lt(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() < y.unwrap();
}

/// @notice Implements the lower than or equal to operation (<=) in the UD60x18 type.
function lte(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() <= y.unwrap();
}

/// @notice Implements the checked modulo operation (%) in the UD60x18 type.
function mod(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() % y.unwrap());
}

/// @notice Implements the not equal operation (!=) in the UD60x18 type.
function neq(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() != y.unwrap();
}

/// @notice Implements the NOT (~) bitwise operation in the UD60x18 type.
function not(UD60x18 x) pure returns (UD60x18 result) {
    result = wrap(~x.unwrap());
}

/// @notice Implements the OR (|) bitwise operation in the UD60x18 type.
function or(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() | y.unwrap());
}

/// @notice Implements the right shift operation (>>) in the UD60x18 type.
function rshift(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() >> bits);
}

/// @notice Implements the checked subtraction operation (-) in the UD60x18 type.
function sub(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() - y.unwrap());
}

/// @notice Implements the unchecked addition operation (+) in the UD60x18 type.
function uncheckedAdd(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(x.unwrap() + y.unwrap());
    }
}

/// @notice Implements the unchecked subtraction operation (-) in the UD60x18 type.
function uncheckedSub(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(x.unwrap() - y.unwrap());
    }
}

/// @notice Implements the XOR (^) bitwise operation in the UD60x18 type.
function xor(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() ^ y.unwrap());
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "../Common.sol" as Common;
import "./Errors.sol" as Errors;
import { wrap } from "./Casting.sol";
import {
    uEXP_MAX_INPUT,
    uEXP2_MAX_INPUT,
    uHALF_UNIT,
    uLOG2_10,
    uLOG2_E,
    uMAX_UD60x18,
    uMAX_WHOLE_UD60x18,
    UNIT,
    uUNIT,
    uUNIT_SQUARED,
    ZERO
} from "./Constants.sol";
import { UD60x18 } from "./ValueType.sol";

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Calculates the arithmetic average of x and y using the following formula:
///
/// $$
/// avg(x, y) = (x & y) + ((xUint ^ yUint) / 2)
/// $$
//
/// In English, this is what this formula does:
///
/// 1. AND x and y.
/// 2. Calculate half of XOR x and y.
/// 3. Add the two results together.
///
/// This technique is known as SWAR, which stands for "SIMD within a register". You can read more about it here:
/// https://devblogs.microsoft.com/oldnewthing/20220207-00/?p=106223
///
/// @dev Notes:
/// - The result is rounded toward zero.
///
/// @param x The first operand as a UD60x18 number.
/// @param y The second operand as a UD60x18 number.
/// @return result The arithmetic average as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function avg(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    uint256 yUint = y.unwrap();
    unchecked {
        result = wrap((xUint & yUint) + ((xUint ^ yUint) >> 1));
    }
}

/// @notice Yields the smallest whole number greater than or equal to x.
///
/// @dev This is optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional
/// counterparts. See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be less than or equal to `MAX_WHOLE_UD60x18`.
///
/// @param x The UD60x18 number to ceil.
/// @param result The smallest whole number greater than or equal to x, as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function ceil(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    if (xUint > uMAX_WHOLE_UD60x18) {
        revert Errors.PRBMath_UD60x18_Ceil_Overflow(x);
    }

    assembly ("memory-safe") {
        // Equivalent to `x % UNIT`.
        let remainder := mod(x, uUNIT)

        // Equivalent to `UNIT - remainder`.
        let delta := sub(uUNIT, remainder)

        // Equivalent to `x + remainder > 0 ? delta : 0`.
        result := add(x, mul(delta, gt(remainder, 0)))
    }
}

/// @notice Divides two UD60x18 numbers, returning a new UD60x18 number.
///
/// @dev Uses {Common.mulDiv} to enable overflow-safe multiplication and division.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
///
/// @param x The numerator as a UD60x18 number.
/// @param y The denominator as a UD60x18 number.
/// @param result The quotient as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function div(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(Common.mulDiv(x.unwrap(), uUNIT, y.unwrap()));
}

/// @notice Calculates the natural exponent of x using the following formula:
///
/// $$
/// e^x = 2^{x * log_2{e}}
/// $$
///
/// @dev Requirements:
/// - x must be less than 133_084258667509499441.
///
/// @param x The exponent as a UD60x18 number.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function exp(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();

    // This check prevents values greater than 192e18 from being passed to {exp2}.
    if (xUint > uEXP_MAX_INPUT) {
        revert Errors.PRBMath_UD60x18_Exp_InputTooBig(x);
    }

    unchecked {
        // Inline the fixed-point multiplication to save gas.
        uint256 doubleUnitProduct = xUint * uLOG2_E;
        result = exp2(wrap(doubleUnitProduct / uUNIT));
    }
}

/// @notice Calculates the binary exponent of x using the binary fraction method.
///
/// @dev See https://ethereum.stackexchange.com/q/79903/24693
///
/// Requirements:
/// - x must be less than 192e18.
/// - The result must fit in UD60x18.
///
/// @param x The exponent as a UD60x18 number.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function exp2(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();

    // Numbers greater than or equal to 192e18 don't fit in the 192.64-bit format.
    if (xUint > uEXP2_MAX_INPUT) {
        revert Errors.PRBMath_UD60x18_Exp2_InputTooBig(x);
    }

    // Convert x to the 192.64-bit fixed-point format.
    uint256 x_192x64 = (xUint << 64) / uUNIT;

    // Pass x to the {Common.exp2} function, which uses the 192.64-bit fixed-point number representation.
    result = wrap(Common.exp2(x_192x64));
}

/// @notice Yields the greatest whole number less than or equal to x.
/// @dev Optimized for fractional value inputs, because every whole value has (1e18 - 1) fractional counterparts.
/// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
/// @param x The UD60x18 number to floor.
/// @param result The greatest whole number less than or equal to x, as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function floor(UD60x18 x) pure returns (UD60x18 result) {
    assembly ("memory-safe") {
        // Equivalent to `x % UNIT`.
        let remainder := mod(x, uUNIT)

        // Equivalent to `x - remainder > 0 ? remainder : 0)`.
        result := sub(x, mul(remainder, gt(remainder, 0)))
    }
}

/// @notice Yields the excess beyond the floor of x using the odd function definition.
/// @dev See https://en.wikipedia.org/wiki/Fractional_part.
/// @param x The UD60x18 number to get the fractional part of.
/// @param result The fractional part of x as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function frac(UD60x18 x) pure returns (UD60x18 result) {
    assembly ("memory-safe") {
        result := mod(x, uUNIT)
    }
}

/// @notice Calculates the geometric mean of x and y, i.e. $\sqrt{x * y}$, rounding down.
///
/// @dev Requirements:
/// - x * y must fit in UD60x18.
///
/// @param x The first operand as a UD60x18 number.
/// @param y The second operand as a UD60x18 number.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function gm(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    uint256 yUint = y.unwrap();
    if (xUint == 0 || yUint == 0) {
        return ZERO;
    }

    unchecked {
        // Checking for overflow this way is faster than letting Solidity do it.
        uint256 xyUint = xUint * yUint;
        if (xyUint / xUint != yUint) {
            revert Errors.PRBMath_UD60x18_Gm_Overflow(x, y);
        }

        // We don't need to multiply the result by `UNIT` here because the x*y product picked up a factor of `UNIT`
        // during multiplication. See the comments in {Common.sqrt}.
        result = wrap(Common.sqrt(xyUint));
    }
}

/// @notice Calculates the inverse of x.
///
/// @dev Notes:
/// - The result is rounded toward zero.
///
/// Requirements:
/// - x must not be zero.
///
/// @param x The UD60x18 number for which to calculate the inverse.
/// @return result The inverse as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function inv(UD60x18 x) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(uUNIT_SQUARED / x.unwrap());
    }
}

/// @notice Calculates the natural logarithm of x using the following formula:
///
/// $$
/// ln{x} = log_2{x} / log_2{e}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {log2}.
/// - The precision isn't sufficiently fine-grained to return exactly `UNIT` when the input is `E`.
///
/// Requirements:
/// - Refer to the requirements in {log2}.
///
/// @param x The UD60x18 number for which to calculate the natural logarithm.
/// @return result The natural logarithm as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function ln(UD60x18 x) pure returns (UD60x18 result) {
    unchecked {
        // Inline the fixed-point multiplication to save gas. This is overflow-safe because the maximum value that
        // {log2} can return is ~196_205294292027477728.
        result = wrap(log2(x).unwrap() * uUNIT / uLOG2_E);
    }
}

/// @notice Calculates the common logarithm of x using the following formula:
///
/// $$
/// log_{10}{x} = log_2{x} / log_2{10}
/// $$
///
/// However, if x is an exact power of ten, a hard coded value is returned.
///
/// @dev Notes:
/// - Refer to the notes in {log2}.
///
/// Requirements:
/// - Refer to the requirements in {log2}.
///
/// @param x The UD60x18 number for which to calculate the common logarithm.
/// @return result The common logarithm as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function log10(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    if (xUint < uUNIT) {
        revert Errors.PRBMath_UD60x18_Log_InputTooSmall(x);
    }

    // Note that the `mul` in this assembly block is the standard multiplication operation, not {UD60x18.mul}.
    // prettier-ignore
    assembly ("memory-safe") {
        switch x
        case 1 { result := mul(uUNIT, sub(0, 18)) }
        case 10 { result := mul(uUNIT, sub(1, 18)) }
        case 100 { result := mul(uUNIT, sub(2, 18)) }
        case 1000 { result := mul(uUNIT, sub(3, 18)) }
        case 10000 { result := mul(uUNIT, sub(4, 18)) }
        case 100000 { result := mul(uUNIT, sub(5, 18)) }
        case 1000000 { result := mul(uUNIT, sub(6, 18)) }
        case 10000000 { result := mul(uUNIT, sub(7, 18)) }
        case 100000000 { result := mul(uUNIT, sub(8, 18)) }
        case 1000000000 { result := mul(uUNIT, sub(9, 18)) }
        case 10000000000 { result := mul(uUNIT, sub(10, 18)) }
        case 100000000000 { result := mul(uUNIT, sub(11, 18)) }
        case 1000000000000 { result := mul(uUNIT, sub(12, 18)) }
        case 10000000000000 { result := mul(uUNIT, sub(13, 18)) }
        case 100000000000000 { result := mul(uUNIT, sub(14, 18)) }
        case 1000000000000000 { result := mul(uUNIT, sub(15, 18)) }
        case 10000000000000000 { result := mul(uUNIT, sub(16, 18)) }
        case 100000000000000000 { result := mul(uUNIT, sub(17, 18)) }
        case 1000000000000000000 { result := 0 }
        case 10000000000000000000 { result := uUNIT }
        case 100000000000000000000 { result := mul(uUNIT, 2) }
        case 1000000000000000000000 { result := mul(uUNIT, 3) }
        case 10000000000000000000000 { result := mul(uUNIT, 4) }
        case 100000000000000000000000 { result := mul(uUNIT, 5) }
        case 1000000000000000000000000 { result := mul(uUNIT, 6) }
        case 10000000000000000000000000 { result := mul(uUNIT, 7) }
        case 100000000000000000000000000 { result := mul(uUNIT, 8) }
        case 1000000000000000000000000000 { result := mul(uUNIT, 9) }
        case 10000000000000000000000000000 { result := mul(uUNIT, 10) }
        case 100000000000000000000000000000 { result := mul(uUNIT, 11) }
        case 1000000000000000000000000000000 { result := mul(uUNIT, 12) }
        case 10000000000000000000000000000000 { result := mul(uUNIT, 13) }
        case 100000000000000000000000000000000 { result := mul(uUNIT, 14) }
        case 1000000000000000000000000000000000 { result := mul(uUNIT, 15) }
        case 10000000000000000000000000000000000 { result := mul(uUNIT, 16) }
        case 100000000000000000000000000000000000 { result := mul(uUNIT, 17) }
        case 1000000000000000000000000000000000000 { result := mul(uUNIT, 18) }
        case 10000000000000000000000000000000000000 { result := mul(uUNIT, 19) }
        case 100000000000000000000000000000000000000 { result := mul(uUNIT, 20) }
        case 1000000000000000000000000000000000000000 { result := mul(uUNIT, 21) }
        case 10000000000000000000000000000000000000000 { result := mul(uUNIT, 22) }
        case 100000000000000000000000000000000000000000 { result := mul(uUNIT, 23) }
        case 1000000000000000000000000000000000000000000 { result := mul(uUNIT, 24) }
        case 10000000000000000000000000000000000000000000 { result := mul(uUNIT, 25) }
        case 100000000000000000000000000000000000000000000 { result := mul(uUNIT, 26) }
        case 1000000000000000000000000000000000000000000000 { result := mul(uUNIT, 27) }
        case 10000000000000000000000000000000000000000000000 { result := mul(uUNIT, 28) }
        case 100000000000000000000000000000000000000000000000 { result := mul(uUNIT, 29) }
        case 1000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 30) }
        case 10000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 31) }
        case 100000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 32) }
        case 1000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 33) }
        case 10000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 34) }
        case 100000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 35) }
        case 1000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 36) }
        case 10000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 37) }
        case 100000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 38) }
        case 1000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 39) }
        case 10000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 40) }
        case 100000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 41) }
        case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 42) }
        case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 43) }
        case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 44) }
        case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 45) }
        case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 46) }
        case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 47) }
        case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 48) }
        case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 49) }
        case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 50) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 51) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 52) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 53) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 54) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 55) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 56) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 57) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 58) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 59) }
        default { result := uMAX_UD60x18 }
    }

    if (result.unwrap() == uMAX_UD60x18) {
        unchecked {
            // Inline the fixed-point division to save gas.
            result = wrap(log2(x).unwrap() * uUNIT / uLOG2_10);
        }
    }
}

/// @notice Calculates the binary logarithm of x using the iterative approximation algorithm:
///
/// $$
/// log_2{x} = n + log_2{y}, \text{ where } y = x*2^{-n}, \ y \in [1, 2)
/// $$
///
/// For $0 \leq x \lt 1$, the input is inverted:
///
/// $$
/// log_2{x} = -log_2{\frac{1}{x}}
/// $$
///
/// @dev See https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
///
/// Notes:
/// - Due to the lossy precision of the iterative approximation, the results are not perfectly accurate to the last decimal.
///
/// Requirements:
/// - x must be greater than zero.
///
/// @param x The UD60x18 number for which to calculate the binary logarithm.
/// @return result The binary logarithm as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function log2(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();

    if (xUint < uUNIT) {
        revert Errors.PRBMath_UD60x18_Log_InputTooSmall(x);
    }

    unchecked {
        // Calculate the integer part of the logarithm.
        uint256 n = Common.msb(xUint / uUNIT);

        // This is the integer part of the logarithm as a UD60x18 number. The operation can't overflow because n
        // n is at most 255 and UNIT is 1e18.
        uint256 resultUint = n * uUNIT;

        // Calculate $y = x * 2^{-n}$.
        uint256 y = xUint >> n;

        // If y is the unit number, the fractional part is zero.
        if (y == uUNIT) {
            return wrap(resultUint);
        }

        // Calculate the fractional part via the iterative approximation.
        // The `delta >>= 1` part is equivalent to `delta /= 2`, but shifting bits is more gas efficient.
        uint256 DOUBLE_UNIT = 2e18;
        for (uint256 delta = uHALF_UNIT; delta > 0; delta >>= 1) {
            y = (y * y) / uUNIT;

            // Is y^2 >= 2e18 and so in the range [2e18, 4e18)?
            if (y >= DOUBLE_UNIT) {
                // Add the 2^{-m} factor to the logarithm.
                resultUint += delta;

                // Halve y, which corresponds to z/2 in the Wikipedia article.
                y >>= 1;
            }
        }
        result = wrap(resultUint);
    }
}

/// @notice Multiplies two UD60x18 numbers together, returning a new UD60x18 number.
///
/// @dev Uses {Common.mulDiv} to enable overflow-safe multiplication and division.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
///
/// @dev See the documentation in {Common.mulDiv18}.
/// @param x The multiplicand as a UD60x18 number.
/// @param y The multiplier as a UD60x18 number.
/// @return result The product as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function mul(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(Common.mulDiv18(x.unwrap(), y.unwrap()));
}

/// @notice Raises x to the power of y.
///
/// For $1 \leq x \leq \infty$, the following standard formula is used:
///
/// $$
/// x^y = 2^{log_2{x} * y}
/// $$
///
/// For $0 \leq x \lt 1$, since the unsigned {log2} is undefined, an equivalent formula is used:
///
/// $$
/// i = \frac{1}{x}
/// w = 2^{log_2{i} * y}
/// x^y = \frac{1}{w}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {log2} and {mul}.
/// - Returns `UNIT` for 0^0.
/// - It may not perform well with very small values of x. Consider using SD59x18 as an alternative.
///
/// Requirements:
/// - Refer to the requirements in {exp2}, {log2}, and {mul}.
///
/// @param x The base as a UD60x18 number.
/// @param y The exponent as a UD60x18 number.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function pow(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    uint256 yUint = y.unwrap();

    // If both x and y are zero, the result is `UNIT`. If just x is zero, the result is always zero.
    if (xUint == 0) {
        return yUint == 0 ? UNIT : ZERO;
    }
    // If x is `UNIT`, the result is always `UNIT`.
    else if (xUint == uUNIT) {
        return UNIT;
    }

    // If y is zero, the result is always `UNIT`.
    if (yUint == 0) {
        return UNIT;
    }
    // If y is `UNIT`, the result is always x.
    else if (yUint == uUNIT) {
        return x;
    }

    // If x is greater than `UNIT`, use the standard formula.
    if (xUint > uUNIT) {
        result = exp2(mul(log2(x), y));
    }
    // Conversely, if x is less than `UNIT`, use the equivalent formula.
    else {
        UD60x18 i = wrap(uUNIT_SQUARED / xUint);
        UD60x18 w = exp2(mul(log2(i), y));
        result = wrap(uUNIT_SQUARED / w.unwrap());
    }
}

/// @notice Raises x (a UD60x18 number) to the power y (an unsigned basic integer) using the well-known
/// algorithm "exponentiation by squaring".
///
/// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv18}.
/// - Returns `UNIT` for 0^0.
///
/// Requirements:
/// - The result must fit in UD60x18.
///
/// @param x The base as a UD60x18 number.
/// @param y The exponent as a uint256.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function powu(UD60x18 x, uint256 y) pure returns (UD60x18 result) {
    // Calculate the first iteration of the loop in advance.
    uint256 xUint = x.unwrap();
    uint256 resultUint = y & 1 > 0 ? xUint : uUNIT;

    // Equivalent to `for(y /= 2; y > 0; y /= 2)`.
    for (y >>= 1; y > 0; y >>= 1) {
        xUint = Common.mulDiv18(xUint, xUint);

        // Equivalent to `y % 2 == 1`.
        if (y & 1 > 0) {
            resultUint = Common.mulDiv18(resultUint, xUint);
        }
    }
    result = wrap(resultUint);
}

/// @notice Calculates the square root of x using the Babylonian method.
///
/// @dev See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
///
/// Notes:
/// - The result is rounded toward zero.
///
/// Requirements:
/// - x must be less than `MAX_UD60x18 / UNIT`.
///
/// @param x The UD60x18 number for which to calculate the square root.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function sqrt(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();

    unchecked {
        if (xUint > uMAX_UD60x18 / uUNIT) {
            revert Errors.PRBMath_UD60x18_Sqrt_Overflow(x);
        }
        // Multiply x by `UNIT` to account for the factor of `UNIT` picked up when multiplying two UD60x18 numbers.
        // In this case, the two numbers are both the square root.
        result = wrap(Common.sqrt(xUint * uUNIT));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Casting.sol" as Casting;
import "./Helpers.sol" as Helpers;
import "./Math.sol" as Math;

/// @notice The unsigned 60.18-decimal fixed-point number representation, which can have up to 60 digits and up to 18
/// decimals. The values of this are bound by the minimum and the maximum values permitted by the Solidity type uint256.
/// @dev The value type is defined here so it can be imported in all other files.
type UD60x18 is uint256;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using {
    Casting.intoSD1x18,
    Casting.intoUD2x18,
    Casting.intoSD59x18,
    Casting.intoUint128,
    Casting.intoUint256,
    Casting.intoUint40,
    Casting.unwrap
} for UD60x18 global;

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

// The global "using for" directive makes the functions in this library callable on the UD60x18 type.
using {
    Math.avg,
    Math.ceil,
    Math.div,
    Math.exp,
    Math.exp2,
    Math.floor,
    Math.frac,
    Math.gm,
    Math.inv,
    Math.ln,
    Math.log10,
    Math.log2,
    Math.mul,
    Math.pow,
    Math.powu,
    Math.sqrt
} for UD60x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

// The global "using for" directive makes the functions in this library callable on the UD60x18 type.
using {
    Helpers.add,
    Helpers.and,
    Helpers.eq,
    Helpers.gt,
    Helpers.gte,
    Helpers.isZero,
    Helpers.lshift,
    Helpers.lt,
    Helpers.lte,
    Helpers.mod,
    Helpers.neq,
    Helpers.not,
    Helpers.or,
    Helpers.rshift,
    Helpers.sub,
    Helpers.uncheckedAdd,
    Helpers.uncheckedSub,
    Helpers.xor
} for UD60x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                    OPERATORS
//////////////////////////////////////////////////////////////////////////*/

// The global "using for" directive makes it possible to use these operators on the UD60x18 type.
using {
    Helpers.add as +,
    Helpers.and2 as &,
    Math.div as /,
    Helpers.eq as ==,
    Helpers.gt as >,
    Helpers.gte as >=,
    Helpers.lt as <,
    Helpers.lte as <=,
    Helpers.or as |,
    Helpers.mod as %,
    Math.mul as *,
    Helpers.neq as !=,
    Helpers.not as ~,
    Helpers.sub as -,
    Helpers.xor as ^
} for UD60x18 global;

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @dev The scale of all fixed point math. This is adopting the conventions of
/// both ETH (wei) and most ERC20 tokens, so is hopefully uncontroversial.
uint256 constant FIXED_POINT_DECIMALS = 18;

/// @dev Value of "one" for fixed point math.
uint256 constant FIXED_POINT_ONE = 1e18;

/// @dev Calculations MUST round up.
uint256 constant FLAG_ROUND_UP = 1;

/// @dev Calculations MUST saturate NOT overflow.
uint256 constant FLAG_SATURATE = 1 << 1;

/// @dev Flags MUST NOT exceed this value.
uint256 constant FLAG_MAX_INT = FLAG_SATURATE | FLAG_ROUND_UP;

/// @dev Can't represent this many OOMs of decimals in `uint256`.
uint256 constant OVERFLOW_RESCALE_OOMS = 78;

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

type EncodedExternDispatch is uint256;

type ExternDispatch is uint256;

/// @title IInterpreterExternV1
/// Handle a single dispatch from some calling contract with an array of
/// inputs and array of outputs. Ostensibly useful to build "word packs" for
/// `IInterpreterV1` so that less frequently used words can be provided in
/// a less efficient format, but without bloating the base interpreter in
/// terms of code size. Effectively allows unlimited words to exist as externs
/// alongside interpreters.
interface IInterpreterExternV1 {
    /// Handles a single dispatch.
    /// @param dispatch Encoded information about the extern to dispatch.
    /// Analogous to the opcode/operand in the interpreter.
    /// @param inputs The array of inputs for the dispatched logic.
    /// @return outputs The result of the dispatched logic.
    function extern(ExternDispatch dispatch, uint256[] memory inputs)
        external
        view
        returns (uint256[] memory outputs);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

// Common.sol
//
// Common mathematical functions needed by both SD59x18 and UD60x18. Note that these global functions do not
// always operate with SD59x18 and UD60x18 numbers.

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Thrown when the resultant value in {mulDiv} overflows uint256.
error PRBMath_MulDiv_Overflow(uint256 x, uint256 y, uint256 denominator);

/// @notice Thrown when the resultant value in {mulDiv18} overflows uint256.
error PRBMath_MulDiv18_Overflow(uint256 x, uint256 y);

/// @notice Thrown when one of the inputs passed to {mulDivSigned} is `type(int256).min`.
error PRBMath_MulDivSigned_InputTooSmall();

/// @notice Thrown when the resultant value in {mulDivSigned} overflows int256.
error PRBMath_MulDivSigned_Overflow(int256 x, int256 y);

/*//////////////////////////////////////////////////////////////////////////
                                    CONSTANTS
//////////////////////////////////////////////////////////////////////////*/

/// @dev The maximum value a uint128 number can have.
uint128 constant MAX_UINT128 = type(uint128).max;

/// @dev The maximum value a uint40 number can have.
uint40 constant MAX_UINT40 = type(uint40).max;

/// @dev The unit number, which the decimal precision of the fixed-point types.
uint256 constant UNIT = 1e18;

/// @dev The unit number inverted mod 2^256.
uint256 constant UNIT_INVERSE = 78156646155174841979727994598816262306175212592076161876661_508869554232690281;

/// @dev The the largest power of two that divides the decimal value of `UNIT`. The logarithm of this value is the least significant
/// bit in the binary representation of `UNIT`.
uint256 constant UNIT_LPOTD = 262144;

/*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Calculates the binary exponent of x using the binary fraction method.
/// @dev Has to use 192.64-bit fixed-point numbers. See https://ethereum.stackexchange.com/a/96594/24693.
/// @param x The exponent as an unsigned 192.64-bit fixed-point number.
/// @return result The result as an unsigned 60.18-decimal fixed-point number.
/// @custom:smtchecker abstract-function-nondet
function exp2(uint256 x) pure returns (uint256 result) {
    unchecked {
        // Start from 0.5 in the 192.64-bit fixed-point format.
        result = 0x800000000000000000000000000000000000000000000000;

        // The following logic multiplies the result by $\sqrt{2^{-i}}$ when the bit at position i is 1. Key points:
        //
        // 1. Intermediate results will not overflow, as the starting point is 2^191 and all magic factors are under 2^65.
        // 2. The rationale for organizing the if statements into groups of 8 is gas savings. If the result of performing
        // a bitwise AND operation between x and any value in the array [0x80; 0x40; 0x20; 0x10; 0x08; 0x04; 0x02; 0x01] is 1,
        // we know that `x & 0xFF` is also 1.
        if (x & 0xFF00000000000000 > 0) {
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
        }

        if (x & 0xFF000000000000 > 0) {
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
        }

        if (x & 0xFF0000000000 > 0) {
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
        }

        if (x & 0xFF00000000 > 0) {
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
        }

        if (x & 0xFF000000 > 0) {
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
        }

        if (x & 0xFF0000 > 0) {
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
        }

        if (x & 0xFF00 > 0) {
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
        }

        if (x & 0xFF > 0) {
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
        }

        // In the code snippet below, two operations are executed simultaneously:
        //
        // 1. The result is multiplied by $(2^n + 1)$, where $2^n$ represents the integer part, and the additional 1
        // accounts for the initial guess of 0.5. This is achieved by subtracting from 191 instead of 192.
        // 2. The result is then converted to an unsigned 60.18-decimal fixed-point format.
        //
        // The underlying logic is based on the relationship $2^{191-ip} = 2^{ip} / 2^{191}$, where $ip$ denotes the,
        // integer part, $2^n$.
        result *= UNIT;
        result >>= (191 - (x >> 64));
    }
}

/// @notice Finds the zero-based index of the first 1 in the binary representation of x.
///
/// @dev See the note on "msb" in this Wikipedia article: https://en.wikipedia.org/wiki/Find_first_set
///
/// Each step in this implementation is equivalent to this high-level code:
///
/// ```solidity
/// if (x >= 2 ** 128) {
///     x >>= 128;
///     result += 128;
/// }
/// ```
///
/// Where 128 is replaced with each respective power of two factor. See the full high-level implementation here:
/// https://gist.github.com/PaulRBerg/f932f8693f2733e30c4d479e8e980948
///
/// The Yul instructions used below are:
///
/// - "gt" is "greater than"
/// - "or" is the OR bitwise operator
/// - "shl" is "shift left"
/// - "shr" is "shift right"
///
/// @param x The uint256 number for which to find the index of the most significant bit.
/// @return result The index of the most significant bit as a uint256.
/// @custom:smtchecker abstract-function-nondet
function msb(uint256 x) pure returns (uint256 result) {
    // 2^128
    assembly ("memory-safe") {
        let factor := shl(7, gt(x, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^64
    assembly ("memory-safe") {
        let factor := shl(6, gt(x, 0xFFFFFFFFFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^32
    assembly ("memory-safe") {
        let factor := shl(5, gt(x, 0xFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^16
    assembly ("memory-safe") {
        let factor := shl(4, gt(x, 0xFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^8
    assembly ("memory-safe") {
        let factor := shl(3, gt(x, 0xFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^4
    assembly ("memory-safe") {
        let factor := shl(2, gt(x, 0xF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^2
    assembly ("memory-safe") {
        let factor := shl(1, gt(x, 0x3))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^1
    // No need to shift x any more.
    assembly ("memory-safe") {
        let factor := gt(x, 0x1)
        result := or(result, factor)
    }
}

/// @notice Calculates x*y÷denominator with 512-bit precision.
///
/// @dev Credits to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
///
/// Notes:
/// - The result is rounded toward zero.
///
/// Requirements:
/// - The denominator must not be zero.
/// - The result must fit in uint256.
///
/// @param x The multiplicand as a uint256.
/// @param y The multiplier as a uint256.
/// @param denominator The divisor as a uint256.
/// @return result The result as a uint256.
/// @custom:smtchecker abstract-function-nondet
function mulDiv(uint256 x, uint256 y, uint256 denominator) pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
    // use the Chinese Remainder Theorem to reconstruct the 512-bit result. The result is stored in two 256
    // variables such that product = prod1 * 2^256 + prod0.
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly ("memory-safe") {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division.
    if (prod1 == 0) {
        unchecked {
            return prod0 / denominator;
        }
    }

    // Make sure the result is less than 2^256. Also prevents denominator == 0.
    if (prod1 >= denominator) {
        revert PRBMath_MulDiv_Overflow(x, y, denominator);
    }

    ////////////////////////////////////////////////////////////////////////////
    // 512 by 256 division
    ////////////////////////////////////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0].
    uint256 remainder;
    assembly ("memory-safe") {
        // Compute remainder using the mulmod Yul instruction.
        remainder := mulmod(x, y, denominator)

        // Subtract 256 bit number from 512-bit number.
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
    }

    unchecked {
        // Calculate the largest power of two divisor of the denominator using the unary operator ~. This operation cannot overflow
        // because the denominator cannot be zero at this point in the function execution. The result is always >= 1.
        // For more detail, see https://cs.stackexchange.com/q/138556/92363.
        uint256 lpotdod = denominator & (~denominator + 1);
        uint256 flippedLpotdod;

        assembly ("memory-safe") {
            // Factor powers of two out of denominator.
            denominator := div(denominator, lpotdod)

            // Divide [prod1 prod0] by lpotdod.
            prod0 := div(prod0, lpotdod)

            // Get the flipped value `2^256 / lpotdod`. If the `lpotdod` is zero, the flipped value is one.
            // `sub(0, lpotdod)` produces the two's complement version of `lpotdod`, which is equivalent to flipping all the bits.
            // However, `div` interprets this value as an unsigned value: https://ethereum.stackexchange.com/q/147168/24693
            flippedLpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
        }

        // Shift in bits from prod1 into prod0.
        prod0 |= prod1 * flippedLpotdod;

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
    }
}

/// @notice Calculates x*y÷1e18 with 512-bit precision.
///
/// @dev A variant of {mulDiv} with constant folding, i.e. in which the denominator is hard coded to 1e18.
///
/// Notes:
/// - The body is purposely left uncommented; to understand how this works, see the documentation in {mulDiv}.
/// - The result is rounded toward zero.
/// - We take as an axiom that the result cannot be `MAX_UINT256` when x and y solve the following system of equations:
///
/// $$
/// \begin{cases}
///     x * y = MAX\_UINT256 * UNIT \\
///     (x * y) \% UNIT \geq \frac{UNIT}{2}
/// \end{cases}
/// $$
///
/// Requirements:
/// - Refer to the requirements in {mulDiv}.
/// - The result must fit in uint256.
///
/// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
/// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
/// @return result The result as an unsigned 60.18-decimal fixed-point number.
/// @custom:smtchecker abstract-function-nondet
function mulDiv18(uint256 x, uint256 y) pure returns (uint256 result) {
    uint256 prod0;
    uint256 prod1;
    assembly ("memory-safe") {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    if (prod1 == 0) {
        unchecked {
            return prod0 / UNIT;
        }
    }

    if (prod1 >= UNIT) {
        revert PRBMath_MulDiv18_Overflow(x, y);
    }

    uint256 remainder;
    assembly ("memory-safe") {
        remainder := mulmod(x, y, UNIT)
        result :=
            mul(
                or(
                    div(sub(prod0, remainder), UNIT_LPOTD),
                    mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, UNIT_LPOTD), UNIT_LPOTD), 1))
                ),
                UNIT_INVERSE
            )
    }
}

/// @notice Calculates x*y÷denominator with 512-bit precision.
///
/// @dev This is an extension of {mulDiv} for signed numbers, which works by computing the signs and the absolute values separately.
///
/// Notes:
/// - The result is rounded toward zero.
///
/// Requirements:
/// - Refer to the requirements in {mulDiv}.
/// - None of the inputs can be `type(int256).min`.
/// - The result must fit in int256.
///
/// @param x The multiplicand as an int256.
/// @param y The multiplier as an int256.
/// @param denominator The divisor as an int256.
/// @return result The result as an int256.
/// @custom:smtchecker abstract-function-nondet
function mulDivSigned(int256 x, int256 y, int256 denominator) pure returns (int256 result) {
    if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
        revert PRBMath_MulDivSigned_InputTooSmall();
    }

    // Get hold of the absolute values of x, y and the denominator.
    uint256 xAbs;
    uint256 yAbs;
    uint256 dAbs;
    unchecked {
        xAbs = x < 0 ? uint256(-x) : uint256(x);
        yAbs = y < 0 ? uint256(-y) : uint256(y);
        dAbs = denominator < 0 ? uint256(-denominator) : uint256(denominator);
    }

    // Compute the absolute value of x*y÷denominator. The result must fit in int256.
    uint256 resultAbs = mulDiv(xAbs, yAbs, dAbs);
    if (resultAbs > uint256(type(int256).max)) {
        revert PRBMath_MulDivSigned_Overflow(x, y);
    }

    // Get the signs of x, y and the denominator.
    uint256 sx;
    uint256 sy;
    uint256 sd;
    assembly ("memory-safe") {
        // "sgt" is the "signed greater than" assembly instruction and "sub(0,1)" is -1 in two's complement.
        sx := sgt(x, sub(0, 1))
        sy := sgt(y, sub(0, 1))
        sd := sgt(denominator, sub(0, 1))
    }

    // XOR over sx, sy and sd. What this does is to check whether there are 1 or 3 negative signs in the inputs.
    // If there are, the result should be negative. Otherwise, it should be positive.
    unchecked {
        result = sx ^ sy ^ sd == 0 ? -int256(resultAbs) : int256(resultAbs);
    }
}

/// @notice Calculates the square root of x using the Babylonian method.
///
/// @dev See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
///
/// Notes:
/// - If x is not a perfect square, the result is rounded down.
/// - Credits to OpenZeppelin for the explanations in comments below.
///
/// @param x The uint256 number for which to calculate the square root.
/// @return result The result as a uint256.
/// @custom:smtchecker abstract-function-nondet
function sqrt(uint256 x) pure returns (uint256 result) {
    if (x == 0) {
        return 0;
    }

    // For our first guess, we calculate the biggest power of 2 which is smaller than the square root of x.
    //
    // We know that the "msb" (most significant bit) of x is a power of 2 such that we have:
    //
    // $$
    // msb(x) <= x <= 2*msb(x)$
    // $$
    //
    // We write $msb(x)$ as $2^k$, and we get:
    //
    // $$
    // k = log_2(x)
    // $$
    //
    // Thus, we can write the initial inequality as:
    //
    // $$
    // 2^{log_2(x)} <= x <= 2*2^{log_2(x)+1} \\
    // sqrt(2^k) <= sqrt(x) < sqrt(2^{k+1}) \\
    // 2^{k/2} <= sqrt(x) < 2^{(k+1)/2} <= 2^{(k/2)+1}
    // $$
    //
    // Consequently, $2^{log_2(x) /2} is a good first approximation of sqrt(x) with at least one correct bit.
    uint256 xAux = uint256(x);
    result = 1;
    if (xAux >= 2 ** 128) {
        xAux >>= 128;
        result <<= 64;
    }
    if (xAux >= 2 ** 64) {
        xAux >>= 64;
        result <<= 32;
    }
    if (xAux >= 2 ** 32) {
        xAux >>= 32;
        result <<= 16;
    }
    if (xAux >= 2 ** 16) {
        xAux >>= 16;
        result <<= 8;
    }
    if (xAux >= 2 ** 8) {
        xAux >>= 8;
        result <<= 4;
    }
    if (xAux >= 2 ** 4) {
        xAux >>= 4;
        result <<= 2;
    }
    if (xAux >= 2 ** 2) {
        result <<= 1;
    }

    // At this point, `result` is an estimation with at least one bit of precision. We know the true value has at
    // most 128 bits, since it is the square root of a uint256. Newton's method converges quadratically (precision
    // doubles at every iteration). We thus need at most 7 iteration to turn our partial result with one bit of
    // precision into the expected uint128 result.
    unchecked {
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;

        // If x is not a perfect square, round the result toward zero.
        uint256 roundedResult = x / result;
        if (result >= roundedResult) {
            result = roundedResult;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { SD1x18 } from "./ValueType.sol";

/// @dev Euler's number as an SD1x18 number.
SD1x18 constant E = SD1x18.wrap(2_718281828459045235);

/// @dev The maximum value an SD1x18 number can have.
int64 constant uMAX_SD1x18 = 9_223372036854775807;
SD1x18 constant MAX_SD1x18 = SD1x18.wrap(uMAX_SD1x18);

/// @dev The maximum value an SD1x18 number can have.
int64 constant uMIN_SD1x18 = -9_223372036854775808;
SD1x18 constant MIN_SD1x18 = SD1x18.wrap(uMIN_SD1x18);

/// @dev PI as an SD1x18 number.
SD1x18 constant PI = SD1x18.wrap(3_141592653589793238);

/// @dev The unit number, which gives the decimal precision of SD1x18.
SD1x18 constant UNIT = SD1x18.wrap(1e18);
int256 constant uUNIT = 1e18;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Casting.sol" as Casting;

/// @notice The signed 1.18-decimal fixed-point number representation, which can have up to 1 digit and up to 18
/// decimals. The values of this are bound by the minimum and the maximum values permitted by the underlying Solidity
/// type int64. This is useful when end users want to use int64 to save gas, e.g. with tight variable packing in contract
/// storage.
type SD1x18 is int64;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using {
    Casting.intoSD59x18,
    Casting.intoUD2x18,
    Casting.intoUD60x18,
    Casting.intoUint256,
    Casting.intoUint128,
    Casting.intoUint40,
    Casting.unwrap
} for SD1x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { SD59x18 } from "./ValueType.sol";

// NOTICE: the "u" prefix stands for "unwrapped".

/// @dev Euler's number as an SD59x18 number.
SD59x18 constant E = SD59x18.wrap(2_718281828459045235);

/// @dev The maximum input permitted in {exp}.
int256 constant uEXP_MAX_INPUT = 133_084258667509499440;
SD59x18 constant EXP_MAX_INPUT = SD59x18.wrap(uEXP_MAX_INPUT);

/// @dev The maximum input permitted in {exp2}.
int256 constant uEXP2_MAX_INPUT = 192e18 - 1;
SD59x18 constant EXP2_MAX_INPUT = SD59x18.wrap(uEXP2_MAX_INPUT);

/// @dev Half the UNIT number.
int256 constant uHALF_UNIT = 0.5e18;
SD59x18 constant HALF_UNIT = SD59x18.wrap(uHALF_UNIT);

/// @dev $log_2(10)$ as an SD59x18 number.
int256 constant uLOG2_10 = 3_321928094887362347;
SD59x18 constant LOG2_10 = SD59x18.wrap(uLOG2_10);

/// @dev $log_2(e)$ as an SD59x18 number.
int256 constant uLOG2_E = 1_442695040888963407;
SD59x18 constant LOG2_E = SD59x18.wrap(uLOG2_E);

/// @dev The maximum value an SD59x18 number can have.
int256 constant uMAX_SD59x18 = 57896044618658097711785492504343953926634992332820282019728_792003956564819967;
SD59x18 constant MAX_SD59x18 = SD59x18.wrap(uMAX_SD59x18);

/// @dev The maximum whole value an SD59x18 number can have.
int256 constant uMAX_WHOLE_SD59x18 = 57896044618658097711785492504343953926634992332820282019728_000000000000000000;
SD59x18 constant MAX_WHOLE_SD59x18 = SD59x18.wrap(uMAX_WHOLE_SD59x18);

/// @dev The minimum value an SD59x18 number can have.
int256 constant uMIN_SD59x18 = -57896044618658097711785492504343953926634992332820282019728_792003956564819968;
SD59x18 constant MIN_SD59x18 = SD59x18.wrap(uMIN_SD59x18);

/// @dev The minimum whole value an SD59x18 number can have.
int256 constant uMIN_WHOLE_SD59x18 = -57896044618658097711785492504343953926634992332820282019728_000000000000000000;
SD59x18 constant MIN_WHOLE_SD59x18 = SD59x18.wrap(uMIN_WHOLE_SD59x18);

/// @dev PI as an SD59x18 number.
SD59x18 constant PI = SD59x18.wrap(3_141592653589793238);

/// @dev The unit number, which gives the decimal precision of SD59x18.
int256 constant uUNIT = 1e18;
SD59x18 constant UNIT = SD59x18.wrap(1e18);

/// @dev The unit number squared.
int256 constant uUNIT_SQUARED = 1e36;
SD59x18 constant UNIT_SQUARED = SD59x18.wrap(uUNIT_SQUARED);

/// @dev Zero as an SD59x18 number.
SD59x18 constant ZERO = SD59x18.wrap(0);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Casting.sol" as Casting;
import "./Helpers.sol" as Helpers;
import "./Math.sol" as Math;

/// @notice The signed 59.18-decimal fixed-point number representation, which can have up to 59 digits and up to 18
/// decimals. The values of this are bound by the minimum and the maximum values permitted by the underlying Solidity
/// type int256.
type SD59x18 is int256;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using {
    Casting.intoInt256,
    Casting.intoSD1x18,
    Casting.intoUD2x18,
    Casting.intoUD60x18,
    Casting.intoUint256,
    Casting.intoUint128,
    Casting.intoUint40,
    Casting.unwrap
} for SD59x18 global;

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    Math.abs,
    Math.avg,
    Math.ceil,
    Math.div,
    Math.exp,
    Math.exp2,
    Math.floor,
    Math.frac,
    Math.gm,
    Math.inv,
    Math.log10,
    Math.log2,
    Math.ln,
    Math.mul,
    Math.pow,
    Math.powu,
    Math.sqrt
} for SD59x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    Helpers.add,
    Helpers.and,
    Helpers.eq,
    Helpers.gt,
    Helpers.gte,
    Helpers.isZero,
    Helpers.lshift,
    Helpers.lt,
    Helpers.lte,
    Helpers.mod,
    Helpers.neq,
    Helpers.not,
    Helpers.or,
    Helpers.rshift,
    Helpers.sub,
    Helpers.uncheckedAdd,
    Helpers.uncheckedSub,
    Helpers.uncheckedUnary,
    Helpers.xor
} for SD59x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                    OPERATORS
//////////////////////////////////////////////////////////////////////////*/

// The global "using for" directive makes it possible to use these operators on the SD59x18 type.
using {
    Helpers.add as +,
    Helpers.and2 as &,
    Math.div as /,
    Helpers.eq as ==,
    Helpers.gt as >,
    Helpers.gte as >=,
    Helpers.lt as <,
    Helpers.lte as <=,
    Helpers.mod as %,
    Math.mul as *,
    Helpers.neq as !=,
    Helpers.not as ~,
    Helpers.or as |,
    Helpers.sub as -,
    Helpers.unary as -,
    Helpers.xor as ^
} for SD59x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { UD2x18 } from "./ValueType.sol";

/// @dev Euler's number as a UD2x18 number.
UD2x18 constant E = UD2x18.wrap(2_718281828459045235);

/// @dev The maximum value a UD2x18 number can have.
uint64 constant uMAX_UD2x18 = 18_446744073709551615;
UD2x18 constant MAX_UD2x18 = UD2x18.wrap(uMAX_UD2x18);

/// @dev PI as a UD2x18 number.
UD2x18 constant PI = UD2x18.wrap(3_141592653589793238);

/// @dev The unit number, which gives the decimal precision of UD2x18.
uint256 constant uUNIT = 1e18;
UD2x18 constant UNIT = UD2x18.wrap(1e18);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Casting.sol" as Casting;

/// @notice The unsigned 2.18-decimal fixed-point number representation, which can have up to 2 digits and up to 18
/// decimals. The values of this are bound by the minimum and the maximum values permitted by the underlying Solidity
/// type uint64. This is useful when end users want to use uint64 to save gas, e.g. with tight variable packing in contract
/// storage.
type UD2x18 is uint64;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using {
    Casting.intoSD1x18,
    Casting.intoSD59x18,
    Casting.intoUD60x18,
    Casting.intoUint256,
    Casting.intoUint128,
    Casting.intoUint40,
    Casting.unwrap
} for UD2x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "../Common.sol" as Common;
import "./Errors.sol" as CastingErrors;
import { SD59x18 } from "../sd59x18/ValueType.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "../ud60x18/ValueType.sol";
import { SD1x18 } from "./ValueType.sol";

/// @notice Casts an SD1x18 number into SD59x18.
/// @dev There is no overflow check because the domain of SD1x18 is a subset of SD59x18.
function intoSD59x18(SD1x18 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(int256(SD1x18.unwrap(x)));
}

/// @notice Casts an SD1x18 number into UD2x18.
/// - x must be positive.
function intoUD2x18(SD1x18 x) pure returns (UD2x18 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUD2x18_Underflow(x);
    }
    result = UD2x18.wrap(uint64(xInt));
}

/// @notice Casts an SD1x18 number into UD60x18.
/// @dev Requirements:
/// - x must be positive.
function intoUD60x18(SD1x18 x) pure returns (UD60x18 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUD60x18_Underflow(x);
    }
    result = UD60x18.wrap(uint64(xInt));
}

/// @notice Casts an SD1x18 number into uint256.
/// @dev Requirements:
/// - x must be positive.
function intoUint256(SD1x18 x) pure returns (uint256 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUint256_Underflow(x);
    }
    result = uint256(uint64(xInt));
}

/// @notice Casts an SD1x18 number into uint128.
/// @dev Requirements:
/// - x must be positive.
function intoUint128(SD1x18 x) pure returns (uint128 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUint128_Underflow(x);
    }
    result = uint128(uint64(xInt));
}

/// @notice Casts an SD1x18 number into uint40.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(SD1x18 x) pure returns (uint40 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUint40_Underflow(x);
    }
    if (xInt > int64(uint64(Common.MAX_UINT40))) {
        revert CastingErrors.PRBMath_SD1x18_ToUint40_Overflow(x);
    }
    result = uint40(uint64(xInt));
}

/// @notice Alias for {wrap}.
function sd1x18(int64 x) pure returns (SD1x18 result) {
    result = SD1x18.wrap(x);
}

/// @notice Unwraps an SD1x18 number into int64.
function unwrap(SD1x18 x) pure returns (int64 result) {
    result = SD1x18.unwrap(x);
}

/// @notice Wraps an int64 number into SD1x18.
function wrap(int64 x) pure returns (SD1x18 result) {
    result = SD1x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Errors.sol" as CastingErrors;
import { MAX_UINT128, MAX_UINT40 } from "../Common.sol";
import { uMAX_SD1x18, uMIN_SD1x18 } from "../sd1x18/Constants.sol";
import { SD1x18 } from "../sd1x18/ValueType.sol";
import { uMAX_UD2x18 } from "../ud2x18/Constants.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "../ud60x18/ValueType.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Casts an SD59x18 number into int256.
/// @dev This is basically a functional alias for {unwrap}.
function intoInt256(SD59x18 x) pure returns (int256 result) {
    result = SD59x18.unwrap(x);
}

/// @notice Casts an SD59x18 number into SD1x18.
/// @dev Requirements:
/// - x must be greater than or equal to `uMIN_SD1x18`.
/// - x must be less than or equal to `uMAX_SD1x18`.
function intoSD1x18(SD59x18 x) pure returns (SD1x18 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < uMIN_SD1x18) {
        revert CastingErrors.PRBMath_SD59x18_IntoSD1x18_Underflow(x);
    }
    if (xInt > uMAX_SD1x18) {
        revert CastingErrors.PRBMath_SD59x18_IntoSD1x18_Overflow(x);
    }
    result = SD1x18.wrap(int64(xInt));
}

/// @notice Casts an SD59x18 number into UD2x18.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `uMAX_UD2x18`.
function intoUD2x18(SD59x18 x) pure returns (UD2x18 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUD2x18_Underflow(x);
    }
    if (xInt > int256(uint256(uMAX_UD2x18))) {
        revert CastingErrors.PRBMath_SD59x18_IntoUD2x18_Overflow(x);
    }
    result = UD2x18.wrap(uint64(uint256(xInt)));
}

/// @notice Casts an SD59x18 number into UD60x18.
/// @dev Requirements:
/// - x must be positive.
function intoUD60x18(SD59x18 x) pure returns (UD60x18 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUD60x18_Underflow(x);
    }
    result = UD60x18.wrap(uint256(xInt));
}

/// @notice Casts an SD59x18 number into uint256.
/// @dev Requirements:
/// - x must be positive.
function intoUint256(SD59x18 x) pure returns (uint256 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint256_Underflow(x);
    }
    result = uint256(xInt);
}

/// @notice Casts an SD59x18 number into uint128.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `uMAX_UINT128`.
function intoUint128(SD59x18 x) pure returns (uint128 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint128_Underflow(x);
    }
    if (xInt > int256(uint256(MAX_UINT128))) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint128_Overflow(x);
    }
    result = uint128(uint256(xInt));
}

/// @notice Casts an SD59x18 number into uint40.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(SD59x18 x) pure returns (uint40 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint40_Underflow(x);
    }
    if (xInt > int256(uint256(MAX_UINT40))) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint40_Overflow(x);
    }
    result = uint40(uint256(xInt));
}

/// @notice Alias for {wrap}.
function sd(int256 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(x);
}

/// @notice Alias for {wrap}.
function sd59x18(int256 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(x);
}

/// @notice Unwraps an SD59x18 number into int256.
function unwrap(SD59x18 x) pure returns (int256 result) {
    result = SD59x18.unwrap(x);
}

/// @notice Wraps an int256 number into SD59x18.
function wrap(int256 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { wrap } from "./Casting.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Implements the checked addition operation (+) in the SD59x18 type.
function add(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    return wrap(x.unwrap() + y.unwrap());
}

/// @notice Implements the AND (&) bitwise operation in the SD59x18 type.
function and(SD59x18 x, int256 bits) pure returns (SD59x18 result) {
    return wrap(x.unwrap() & bits);
}

/// @notice Implements the AND (&) bitwise operation in the SD59x18 type.
function and2(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    return wrap(x.unwrap() & y.unwrap());
}

/// @notice Implements the equal (=) operation in the SD59x18 type.
function eq(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() == y.unwrap();
}

/// @notice Implements the greater than operation (>) in the SD59x18 type.
function gt(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() > y.unwrap();
}

/// @notice Implements the greater than or equal to operation (>=) in the SD59x18 type.
function gte(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() >= y.unwrap();
}

/// @notice Implements a zero comparison check function in the SD59x18 type.
function isZero(SD59x18 x) pure returns (bool result) {
    result = x.unwrap() == 0;
}

/// @notice Implements the left shift operation (<<) in the SD59x18 type.
function lshift(SD59x18 x, uint256 bits) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() << bits);
}

/// @notice Implements the lower than operation (<) in the SD59x18 type.
function lt(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() < y.unwrap();
}

/// @notice Implements the lower than or equal to operation (<=) in the SD59x18 type.
function lte(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() <= y.unwrap();
}

/// @notice Implements the unchecked modulo operation (%) in the SD59x18 type.
function mod(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() % y.unwrap());
}

/// @notice Implements the not equal operation (!=) in the SD59x18 type.
function neq(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() != y.unwrap();
}

/// @notice Implements the NOT (~) bitwise operation in the SD59x18 type.
function not(SD59x18 x) pure returns (SD59x18 result) {
    result = wrap(~x.unwrap());
}

/// @notice Implements the OR (|) bitwise operation in the SD59x18 type.
function or(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() | y.unwrap());
}

/// @notice Implements the right shift operation (>>) in the SD59x18 type.
function rshift(SD59x18 x, uint256 bits) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() >> bits);
}

/// @notice Implements the checked subtraction operation (-) in the SD59x18 type.
function sub(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() - y.unwrap());
}

/// @notice Implements the checked unary minus operation (-) in the SD59x18 type.
function unary(SD59x18 x) pure returns (SD59x18 result) {
    result = wrap(-x.unwrap());
}

/// @notice Implements the unchecked addition operation (+) in the SD59x18 type.
function uncheckedAdd(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    unchecked {
        result = wrap(x.unwrap() + y.unwrap());
    }
}

/// @notice Implements the unchecked subtraction operation (-) in the SD59x18 type.
function uncheckedSub(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    unchecked {
        result = wrap(x.unwrap() - y.unwrap());
    }
}

/// @notice Implements the unchecked unary minus operation (-) in the SD59x18 type.
function uncheckedUnary(SD59x18 x) pure returns (SD59x18 result) {
    unchecked {
        result = wrap(-x.unwrap());
    }
}

/// @notice Implements the XOR (^) bitwise operation in the SD59x18 type.
function xor(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() ^ y.unwrap());
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "../Common.sol" as Common;
import "./Errors.sol" as Errors;
import {
    uEXP_MAX_INPUT,
    uEXP2_MAX_INPUT,
    uHALF_UNIT,
    uLOG2_10,
    uLOG2_E,
    uMAX_SD59x18,
    uMAX_WHOLE_SD59x18,
    uMIN_SD59x18,
    uMIN_WHOLE_SD59x18,
    UNIT,
    uUNIT,
    uUNIT_SQUARED,
    ZERO
} from "./Constants.sol";
import { wrap } from "./Helpers.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Calculates the absolute value of x.
///
/// @dev Requirements:
/// - x must be greater than `MIN_SD59x18`.
///
/// @param x The SD59x18 number for which to calculate the absolute value.
/// @param result The absolute value of x as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function abs(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt == uMIN_SD59x18) {
        revert Errors.PRBMath_SD59x18_Abs_MinSD59x18();
    }
    result = xInt < 0 ? wrap(-xInt) : x;
}

/// @notice Calculates the arithmetic average of x and y.
///
/// @dev Notes:
/// - The result is rounded toward zero.
///
/// @param x The first operand as an SD59x18 number.
/// @param y The second operand as an SD59x18 number.
/// @return result The arithmetic average as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function avg(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();

    unchecked {
        // This operation is equivalent to `x / 2 +  y / 2`, and it can never overflow.
        int256 sum = (xInt >> 1) + (yInt >> 1);

        if (sum < 0) {
            // If at least one of x and y is odd, add 1 to the result, because shifting negative numbers to the right
            // rounds toward negative infinity. The right part is equivalent to `sum + (x % 2 == 1 || y % 2 == 1)`.
            assembly ("memory-safe") {
                result := add(sum, and(or(xInt, yInt), 1))
            }
        } else {
            // Add 1 if both x and y are odd to account for the double 0.5 remainder truncated after shifting.
            result = wrap(sum + (xInt & yInt & 1));
        }
    }
}

/// @notice Yields the smallest whole number greater than or equal to x.
///
/// @dev Optimized for fractional value inputs, because every whole value has (1e18 - 1) fractional counterparts.
/// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be less than or equal to `MAX_WHOLE_SD59x18`.
///
/// @param x The SD59x18 number to ceil.
/// @param result The smallest whole number greater than or equal to x, as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function ceil(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt > uMAX_WHOLE_SD59x18) {
        revert Errors.PRBMath_SD59x18_Ceil_Overflow(x);
    }

    int256 remainder = xInt % uUNIT;
    if (remainder == 0) {
        result = x;
    } else {
        unchecked {
            // Solidity uses C fmod style, which returns a modulus with the same sign as x.
            int256 resultInt = xInt - remainder;
            if (xInt > 0) {
                resultInt += uUNIT;
            }
            result = wrap(resultInt);
        }
    }
}

/// @notice Divides two SD59x18 numbers, returning a new SD59x18 number.
///
/// @dev This is an extension of {Common.mulDiv} for signed numbers, which works by computing the signs and the absolute
/// values separately.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
/// - The result is rounded toward zero.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
/// - None of the inputs can be `MIN_SD59x18`.
/// - The denominator must not be zero.
/// - The result must fit in SD59x18.
///
/// @param x The numerator as an SD59x18 number.
/// @param y The denominator as an SD59x18 number.
/// @param result The quotient as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function div(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();
    if (xInt == uMIN_SD59x18 || yInt == uMIN_SD59x18) {
        revert Errors.PRBMath_SD59x18_Div_InputTooSmall();
    }

    // Get hold of the absolute values of x and y.
    uint256 xAbs;
    uint256 yAbs;
    unchecked {
        xAbs = xInt < 0 ? uint256(-xInt) : uint256(xInt);
        yAbs = yInt < 0 ? uint256(-yInt) : uint256(yInt);
    }

    // Compute the absolute value (x*UNIT÷y). The resulting value must fit in SD59x18.
    uint256 resultAbs = Common.mulDiv(xAbs, uint256(uUNIT), yAbs);
    if (resultAbs > uint256(uMAX_SD59x18)) {
        revert Errors.PRBMath_SD59x18_Div_Overflow(x, y);
    }

    // Check if x and y have the same sign using two's complement representation. The left-most bit represents the sign (1 for
    // negative, 0 for positive or zero).
    bool sameSign = (xInt ^ yInt) > -1;

    // If the inputs have the same sign, the result should be positive. Otherwise, it should be negative.
    unchecked {
        result = wrap(sameSign ? int256(resultAbs) : -int256(resultAbs));
    }
}

/// @notice Calculates the natural exponent of x using the following formula:
///
/// $$
/// e^x = 2^{x * log_2{e}}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {exp2}.
///
/// Requirements:
/// - Refer to the requirements in {exp2}.
/// - x must be less than 133_084258667509499441.
///
/// @param x The exponent as an SD59x18 number.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function exp(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();

    // This check prevents values greater than 192e18 from being passed to {exp2}.
    if (xInt > uEXP_MAX_INPUT) {
        revert Errors.PRBMath_SD59x18_Exp_InputTooBig(x);
    }

    unchecked {
        // Inline the fixed-point multiplication to save gas.
        int256 doubleUnitProduct = xInt * uLOG2_E;
        result = exp2(wrap(doubleUnitProduct / uUNIT));
    }
}

/// @notice Calculates the binary exponent of x using the binary fraction method using the following formula:
///
/// $$
/// 2^{-x} = \frac{1}{2^x}
/// $$
///
/// @dev See https://ethereum.stackexchange.com/q/79903/24693.
///
/// Notes:
/// - If x is less than -59_794705707972522261, the result is zero.
///
/// Requirements:
/// - x must be less than 192e18.
/// - The result must fit in SD59x18.
///
/// @param x The exponent as an SD59x18 number.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function exp2(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt < 0) {
        // The inverse of any number less than this is truncated to zero.
        if (xInt < -59_794705707972522261) {
            return ZERO;
        }

        unchecked {
            // Inline the fixed-point inversion to save gas.
            result = wrap(uUNIT_SQUARED / exp2(wrap(-xInt)).unwrap());
        }
    } else {
        // Numbers greater than or equal to 192e18 don't fit in the 192.64-bit format.
        if (xInt > uEXP2_MAX_INPUT) {
            revert Errors.PRBMath_SD59x18_Exp2_InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x_192x64 = uint256((xInt << 64) / uUNIT);

            // It is safe to cast the result to int256 due to the checks above.
            result = wrap(int256(Common.exp2(x_192x64)));
        }
    }
}

/// @notice Yields the greatest whole number less than or equal to x.
///
/// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional
/// counterparts. See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be greater than or equal to `MIN_WHOLE_SD59x18`.
///
/// @param x The SD59x18 number to floor.
/// @param result The greatest whole number less than or equal to x, as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function floor(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt < uMIN_WHOLE_SD59x18) {
        revert Errors.PRBMath_SD59x18_Floor_Underflow(x);
    }

    int256 remainder = xInt % uUNIT;
    if (remainder == 0) {
        result = x;
    } else {
        unchecked {
            // Solidity uses C fmod style, which returns a modulus with the same sign as x.
            int256 resultInt = xInt - remainder;
            if (xInt < 0) {
                resultInt -= uUNIT;
            }
            result = wrap(resultInt);
        }
    }
}

/// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right.
/// of the radix point for negative numbers.
/// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
/// @param x The SD59x18 number to get the fractional part of.
/// @param result The fractional part of x as an SD59x18 number.
function frac(SD59x18 x) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() % uUNIT);
}

/// @notice Calculates the geometric mean of x and y, i.e. $\sqrt{x * y}$.
///
/// @dev Notes:
/// - The result is rounded toward zero.
///
/// Requirements:
/// - x * y must fit in SD59x18.
/// - x * y must not be negative, since complex numbers are not supported.
///
/// @param x The first operand as an SD59x18 number.
/// @param y The second operand as an SD59x18 number.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function gm(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();
    if (xInt == 0 || yInt == 0) {
        return ZERO;
    }

    unchecked {
        // Equivalent to `xy / x != y`. Checking for overflow this way is faster than letting Solidity do it.
        int256 xyInt = xInt * yInt;
        if (xyInt / xInt != yInt) {
            revert Errors.PRBMath_SD59x18_Gm_Overflow(x, y);
        }

        // The product must not be negative, since complex numbers are not supported.
        if (xyInt < 0) {
            revert Errors.PRBMath_SD59x18_Gm_NegativeProduct(x, y);
        }

        // We don't need to multiply the result by `UNIT` here because the x*y product picked up a factor of `UNIT`
        // during multiplication. See the comments in {Common.sqrt}.
        uint256 resultUint = Common.sqrt(uint256(xyInt));
        result = wrap(int256(resultUint));
    }
}

/// @notice Calculates the inverse of x.
///
/// @dev Notes:
/// - The result is rounded toward zero.
///
/// Requirements:
/// - x must not be zero.
///
/// @param x The SD59x18 number for which to calculate the inverse.
/// @return result The inverse as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function inv(SD59x18 x) pure returns (SD59x18 result) {
    result = wrap(uUNIT_SQUARED / x.unwrap());
}

/// @notice Calculates the natural logarithm of x using the following formula:
///
/// $$
/// ln{x} = log_2{x} / log_2{e}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {log2}.
/// - The precision isn't sufficiently fine-grained to return exactly `UNIT` when the input is `E`.
///
/// Requirements:
/// - Refer to the requirements in {log2}.
///
/// @param x The SD59x18 number for which to calculate the natural logarithm.
/// @return result The natural logarithm as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function ln(SD59x18 x) pure returns (SD59x18 result) {
    // Inline the fixed-point multiplication to save gas. This is overflow-safe because the maximum value that
    // {log2} can return is ~195_205294292027477728.
    result = wrap(log2(x).unwrap() * uUNIT / uLOG2_E);
}

/// @notice Calculates the common logarithm of x using the following formula:
///
/// $$
/// log_{10}{x} = log_2{x} / log_2{10}
/// $$
///
/// However, if x is an exact power of ten, a hard coded value is returned.
///
/// @dev Notes:
/// - Refer to the notes in {log2}.
///
/// Requirements:
/// - Refer to the requirements in {log2}.
///
/// @param x The SD59x18 number for which to calculate the common logarithm.
/// @return result The common logarithm as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function log10(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt < 0) {
        revert Errors.PRBMath_SD59x18_Log_InputTooSmall(x);
    }

    // Note that the `mul` in this block is the standard multiplication operation, not {SD59x18.mul}.
    // prettier-ignore
    assembly ("memory-safe") {
        switch x
        case 1 { result := mul(uUNIT, sub(0, 18)) }
        case 10 { result := mul(uUNIT, sub(1, 18)) }
        case 100 { result := mul(uUNIT, sub(2, 18)) }
        case 1000 { result := mul(uUNIT, sub(3, 18)) }
        case 10000 { result := mul(uUNIT, sub(4, 18)) }
        case 100000 { result := mul(uUNIT, sub(5, 18)) }
        case 1000000 { result := mul(uUNIT, sub(6, 18)) }
        case 10000000 { result := mul(uUNIT, sub(7, 18)) }
        case 100000000 { result := mul(uUNIT, sub(8, 18)) }
        case 1000000000 { result := mul(uUNIT, sub(9, 18)) }
        case 10000000000 { result := mul(uUNIT, sub(10, 18)) }
        case 100000000000 { result := mul(uUNIT, sub(11, 18)) }
        case 1000000000000 { result := mul(uUNIT, sub(12, 18)) }
        case 10000000000000 { result := mul(uUNIT, sub(13, 18)) }
        case 100000000000000 { result := mul(uUNIT, sub(14, 18)) }
        case 1000000000000000 { result := mul(uUNIT, sub(15, 18)) }
        case 10000000000000000 { result := mul(uUNIT, sub(16, 18)) }
        case 100000000000000000 { result := mul(uUNIT, sub(17, 18)) }
        case 1000000000000000000 { result := 0 }
        case 10000000000000000000 { result := uUNIT }
        case 100000000000000000000 { result := mul(uUNIT, 2) }
        case 1000000000000000000000 { result := mul(uUNIT, 3) }
        case 10000000000000000000000 { result := mul(uUNIT, 4) }
        case 100000000000000000000000 { result := mul(uUNIT, 5) }
        case 1000000000000000000000000 { result := mul(uUNIT, 6) }
        case 10000000000000000000000000 { result := mul(uUNIT, 7) }
        case 100000000000000000000000000 { result := mul(uUNIT, 8) }
        case 1000000000000000000000000000 { result := mul(uUNIT, 9) }
        case 10000000000000000000000000000 { result := mul(uUNIT, 10) }
        case 100000000000000000000000000000 { result := mul(uUNIT, 11) }
        case 1000000000000000000000000000000 { result := mul(uUNIT, 12) }
        case 10000000000000000000000000000000 { result := mul(uUNIT, 13) }
        case 100000000000000000000000000000000 { result := mul(uUNIT, 14) }
        case 1000000000000000000000000000000000 { result := mul(uUNIT, 15) }
        case 10000000000000000000000000000000000 { result := mul(uUNIT, 16) }
        case 100000000000000000000000000000000000 { result := mul(uUNIT, 17) }
        case 1000000000000000000000000000000000000 { result := mul(uUNIT, 18) }
        case 10000000000000000000000000000000000000 { result := mul(uUNIT, 19) }
        case 100000000000000000000000000000000000000 { result := mul(uUNIT, 20) }
        case 1000000000000000000000000000000000000000 { result := mul(uUNIT, 21) }
        case 10000000000000000000000000000000000000000 { result := mul(uUNIT, 22) }
        case 100000000000000000000000000000000000000000 { result := mul(uUNIT, 23) }
        case 1000000000000000000000000000000000000000000 { result := mul(uUNIT, 24) }
        case 10000000000000000000000000000000000000000000 { result := mul(uUNIT, 25) }
        case 100000000000000000000000000000000000000000000 { result := mul(uUNIT, 26) }
        case 1000000000000000000000000000000000000000000000 { result := mul(uUNIT, 27) }
        case 10000000000000000000000000000000000000000000000 { result := mul(uUNIT, 28) }
        case 100000000000000000000000000000000000000000000000 { result := mul(uUNIT, 29) }
        case 1000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 30) }
        case 10000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 31) }
        case 100000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 32) }
        case 1000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 33) }
        case 10000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 34) }
        case 100000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 35) }
        case 1000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 36) }
        case 10000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 37) }
        case 100000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 38) }
        case 1000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 39) }
        case 10000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 40) }
        case 100000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 41) }
        case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 42) }
        case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 43) }
        case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 44) }
        case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 45) }
        case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 46) }
        case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 47) }
        case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 48) }
        case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 49) }
        case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 50) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 51) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 52) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 53) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 54) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 55) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 56) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 57) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 58) }
        default { result := uMAX_SD59x18 }
    }

    if (result.unwrap() == uMAX_SD59x18) {
        unchecked {
            // Inline the fixed-point division to save gas.
            result = wrap(log2(x).unwrap() * uUNIT / uLOG2_10);
        }
    }
}

/// @notice Calculates the binary logarithm of x using the iterative approximation algorithm:
///
/// $$
/// log_2{x} = n + log_2{y}, \text{ where } y = x*2^{-n}, \ y \in [1, 2)
/// $$
///
/// For $0 \leq x \lt 1$, the input is inverted:
///
/// $$
/// log_2{x} = -log_2{\frac{1}{x}}
/// $$
///
/// @dev See https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation.
///
/// Notes:
/// - Due to the lossy precision of the iterative approximation, the results are not perfectly accurate to the last decimal.
///
/// Requirements:
/// - x must be greater than zero.
///
/// @param x The SD59x18 number for which to calculate the binary logarithm.
/// @return result The binary logarithm as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function log2(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt <= 0) {
        revert Errors.PRBMath_SD59x18_Log_InputTooSmall(x);
    }

    unchecked {
        int256 sign;
        if (xInt >= uUNIT) {
            sign = 1;
        } else {
            sign = -1;
            // Inline the fixed-point inversion to save gas.
            xInt = uUNIT_SQUARED / xInt;
        }

        // Calculate the integer part of the logarithm.
        uint256 n = Common.msb(uint256(xInt / uUNIT));

        // This is the integer part of the logarithm as an SD59x18 number. The operation can't overflow
        // because n is at most 255, `UNIT` is 1e18, and the sign is either 1 or -1.
        int256 resultInt = int256(n) * uUNIT;

        // Calculate $y = x * 2^{-n}$.
        int256 y = xInt >> n;

        // If y is the unit number, the fractional part is zero.
        if (y == uUNIT) {
            return wrap(resultInt * sign);
        }

        // Calculate the fractional part via the iterative approximation.
        // The `delta >>= 1` part is equivalent to `delta /= 2`, but shifting bits is more gas efficient.
        int256 DOUBLE_UNIT = 2e18;
        for (int256 delta = uHALF_UNIT; delta > 0; delta >>= 1) {
            y = (y * y) / uUNIT;

            // Is y^2 >= 2e18 and so in the range [2e18, 4e18)?
            if (y >= DOUBLE_UNIT) {
                // Add the 2^{-m} factor to the logarithm.
                resultInt = resultInt + delta;

                // Halve y, which corresponds to z/2 in the Wikipedia article.
                y >>= 1;
            }
        }
        resultInt *= sign;
        result = wrap(resultInt);
    }
}

/// @notice Multiplies two SD59x18 numbers together, returning a new SD59x18 number.
///
/// @dev Notes:
/// - Refer to the notes in {Common.mulDiv18}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv18}.
/// - None of the inputs can be `MIN_SD59x18`.
/// - The result must fit in SD59x18.
///
/// @param x The multiplicand as an SD59x18 number.
/// @param y The multiplier as an SD59x18 number.
/// @return result The product as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function mul(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();
    if (xInt == uMIN_SD59x18 || yInt == uMIN_SD59x18) {
        revert Errors.PRBMath_SD59x18_Mul_InputTooSmall();
    }

    // Get hold of the absolute values of x and y.
    uint256 xAbs;
    uint256 yAbs;
    unchecked {
        xAbs = xInt < 0 ? uint256(-xInt) : uint256(xInt);
        yAbs = yInt < 0 ? uint256(-yInt) : uint256(yInt);
    }

    // Compute the absolute value (x*y÷UNIT). The resulting value must fit in SD59x18.
    uint256 resultAbs = Common.mulDiv18(xAbs, yAbs);
    if (resultAbs > uint256(uMAX_SD59x18)) {
        revert Errors.PRBMath_SD59x18_Mul_Overflow(x, y);
    }

    // Check if x and y have the same sign using two's complement representation. The left-most bit represents the sign (1 for
    // negative, 0 for positive or zero).
    bool sameSign = (xInt ^ yInt) > -1;

    // If the inputs have the same sign, the result should be positive. Otherwise, it should be negative.
    unchecked {
        result = wrap(sameSign ? int256(resultAbs) : -int256(resultAbs));
    }
}

/// @notice Raises x to the power of y using the following formula:
///
/// $$
/// x^y = 2^{log_2{x} * y}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {exp2}, {log2}, and {mul}.
/// - Returns `UNIT` for 0^0.
///
/// Requirements:
/// - Refer to the requirements in {exp2}, {log2}, and {mul}.
///
/// @param x The base as an SD59x18 number.
/// @param y Exponent to raise x to, as an SD59x18 number
/// @return result x raised to power y, as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function pow(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();

    // If both x and y are zero, the result is `UNIT`. If just x is zero, the result is always zero.
    if (xInt == 0) {
        return yInt == 0 ? UNIT : ZERO;
    }
    // If x is `UNIT`, the result is always `UNIT`.
    else if (xInt == uUNIT) {
        return UNIT;
    }

    // If y is zero, the result is always `UNIT`.
    if (yInt == 0) {
        return UNIT;
    }
    // If y is `UNIT`, the result is always x.
    else if (yInt == uUNIT) {
        return x;
    }

    // Calculate the result using the formula.
    result = exp2(mul(log2(x), y));
}

/// @notice Raises x (an SD59x18 number) to the power y (an unsigned basic integer) using the well-known
/// algorithm "exponentiation by squaring".
///
/// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv18}.
/// - Returns `UNIT` for 0^0.
///
/// Requirements:
/// - Refer to the requirements in {abs} and {Common.mulDiv18}.
/// - The result must fit in SD59x18.
///
/// @param x The base as an SD59x18 number.
/// @param y The exponent as a uint256.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function powu(SD59x18 x, uint256 y) pure returns (SD59x18 result) {
    uint256 xAbs = uint256(abs(x).unwrap());

    // Calculate the first iteration of the loop in advance.
    uint256 resultAbs = y & 1 > 0 ? xAbs : uint256(uUNIT);

    // Equivalent to `for(y /= 2; y > 0; y /= 2)`.
    uint256 yAux = y;
    for (yAux >>= 1; yAux > 0; yAux >>= 1) {
        xAbs = Common.mulDiv18(xAbs, xAbs);

        // Equivalent to `y % 2 == 1`.
        if (yAux & 1 > 0) {
            resultAbs = Common.mulDiv18(resultAbs, xAbs);
        }
    }

    // The result must fit in SD59x18.
    if (resultAbs > uint256(uMAX_SD59x18)) {
        revert Errors.PRBMath_SD59x18_Powu_Overflow(x, y);
    }

    unchecked {
        // Is the base negative and the exponent odd? If yes, the result should be negative.
        int256 resultInt = int256(resultAbs);
        bool isNegative = x.unwrap() < 0 && y & 1 == 1;
        if (isNegative) {
            resultInt = -resultInt;
        }
        result = wrap(resultInt);
    }
}

/// @notice Calculates the square root of x using the Babylonian method.
///
/// @dev See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
///
/// Notes:
/// - Only the positive root is returned.
/// - The result is rounded toward zero.
///
/// Requirements:
/// - x cannot be negative, since complex numbers are not supported.
/// - x must be less than `MAX_SD59x18 / UNIT`.
///
/// @param x The SD59x18 number for which to calculate the square root.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function sqrt(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt < 0) {
        revert Errors.PRBMath_SD59x18_Sqrt_NegativeInput(x);
    }
    if (xInt > uMAX_SD59x18 / uUNIT) {
        revert Errors.PRBMath_SD59x18_Sqrt_Overflow(x);
    }

    unchecked {
        // Multiply x by `UNIT` to account for the factor of `UNIT` picked up when multiplying two SD59x18 numbers.
        // In this case, the two numbers are both the square root.
        uint256 resultUint = Common.sqrt(uint256(xInt * uUNIT));
        result = wrap(int256(resultUint));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "../Common.sol" as Common;
import "./Errors.sol" as Errors;
import { uMAX_SD1x18 } from "../sd1x18/Constants.sol";
import { SD1x18 } from "../sd1x18/ValueType.sol";
import { SD59x18 } from "../sd59x18/ValueType.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "../ud60x18/ValueType.sol";
import { UD2x18 } from "./ValueType.sol";

/// @notice Casts a UD2x18 number into SD1x18.
/// - x must be less than or equal to `uMAX_SD1x18`.
function intoSD1x18(UD2x18 x) pure returns (SD1x18 result) {
    uint64 xUint = UD2x18.unwrap(x);
    if (xUint > uint64(uMAX_SD1x18)) {
        revert Errors.PRBMath_UD2x18_IntoSD1x18_Overflow(x);
    }
    result = SD1x18.wrap(int64(xUint));
}

/// @notice Casts a UD2x18 number into SD59x18.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of SD59x18.
function intoSD59x18(UD2x18 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(int256(uint256(UD2x18.unwrap(x))));
}

/// @notice Casts a UD2x18 number into UD60x18.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of UD60x18.
function intoUD60x18(UD2x18 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(UD2x18.unwrap(x));
}

/// @notice Casts a UD2x18 number into uint128.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of uint128.
function intoUint128(UD2x18 x) pure returns (uint128 result) {
    result = uint128(UD2x18.unwrap(x));
}

/// @notice Casts a UD2x18 number into uint256.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of uint256.
function intoUint256(UD2x18 x) pure returns (uint256 result) {
    result = uint256(UD2x18.unwrap(x));
}

/// @notice Casts a UD2x18 number into uint40.
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(UD2x18 x) pure returns (uint40 result) {
    uint64 xUint = UD2x18.unwrap(x);
    if (xUint > uint64(Common.MAX_UINT40)) {
        revert Errors.PRBMath_UD2x18_IntoUint40_Overflow(x);
    }
    result = uint40(xUint);
}

/// @notice Alias for {wrap}.
function ud2x18(uint64 x) pure returns (UD2x18 result) {
    result = UD2x18.wrap(x);
}

/// @notice Unwrap a UD2x18 number into uint64.
function unwrap(UD2x18 x) pure returns (uint64 result) {
    result = UD2x18.unwrap(x);
}

/// @notice Wraps a uint64 number into UD2x18.
function wrap(uint64 x) pure returns (UD2x18 result) {
    result = UD2x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { SD1x18 } from "./ValueType.sol";

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in UD2x18.
error PRBMath_SD1x18_ToUD2x18_Underflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in UD60x18.
error PRBMath_SD1x18_ToUD60x18_Underflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in uint128.
error PRBMath_SD1x18_ToUint128_Underflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in uint256.
error PRBMath_SD1x18_ToUint256_Underflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in uint40.
error PRBMath_SD1x18_ToUint40_Overflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in uint40.
error PRBMath_SD1x18_ToUint40_Underflow(SD1x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { SD59x18 } from "./ValueType.sol";

/// @notice Thrown when taking the absolute value of `MIN_SD59x18`.
error PRBMath_SD59x18_Abs_MinSD59x18();

/// @notice Thrown when ceiling a number overflows SD59x18.
error PRBMath_SD59x18_Ceil_Overflow(SD59x18 x);

/// @notice Thrown when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMath_SD59x18_Convert_Overflow(int256 x);

/// @notice Thrown when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMath_SD59x18_Convert_Underflow(int256 x);

/// @notice Thrown when dividing two numbers and one of them is `MIN_SD59x18`.
error PRBMath_SD59x18_Div_InputTooSmall();

/// @notice Thrown when dividing two numbers and one of the intermediary unsigned results overflows SD59x18.
error PRBMath_SD59x18_Div_Overflow(SD59x18 x, SD59x18 y);

/// @notice Thrown when taking the natural exponent of a base greater than 133_084258667509499441.
error PRBMath_SD59x18_Exp_InputTooBig(SD59x18 x);

/// @notice Thrown when taking the binary exponent of a base greater than 192e18.
error PRBMath_SD59x18_Exp2_InputTooBig(SD59x18 x);

/// @notice Thrown when flooring a number underflows SD59x18.
error PRBMath_SD59x18_Floor_Underflow(SD59x18 x);

/// @notice Thrown when taking the geometric mean of two numbers and their product is negative.
error PRBMath_SD59x18_Gm_NegativeProduct(SD59x18 x, SD59x18 y);

/// @notice Thrown when taking the geometric mean of two numbers and multiplying them overflows SD59x18.
error PRBMath_SD59x18_Gm_Overflow(SD59x18 x, SD59x18 y);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in SD1x18.
error PRBMath_SD59x18_IntoSD1x18_Overflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in SD1x18.
error PRBMath_SD59x18_IntoSD1x18_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in UD2x18.
error PRBMath_SD59x18_IntoUD2x18_Overflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in UD2x18.
error PRBMath_SD59x18_IntoUD2x18_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in UD60x18.
error PRBMath_SD59x18_IntoUD60x18_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint128.
error PRBMath_SD59x18_IntoUint128_Overflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint128.
error PRBMath_SD59x18_IntoUint128_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint256.
error PRBMath_SD59x18_IntoUint256_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint40.
error PRBMath_SD59x18_IntoUint40_Overflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint40.
error PRBMath_SD59x18_IntoUint40_Underflow(SD59x18 x);

/// @notice Thrown when taking the logarithm of a number less than or equal to zero.
error PRBMath_SD59x18_Log_InputTooSmall(SD59x18 x);

/// @notice Thrown when multiplying two numbers and one of the inputs is `MIN_SD59x18`.
error PRBMath_SD59x18_Mul_InputTooSmall();

/// @notice Thrown when multiplying two numbers and the intermediary absolute result overflows SD59x18.
error PRBMath_SD59x18_Mul_Overflow(SD59x18 x, SD59x18 y);

/// @notice Thrown when raising a number to a power and hte intermediary absolute result overflows SD59x18.
error PRBMath_SD59x18_Powu_Overflow(SD59x18 x, uint256 y);

/// @notice Thrown when taking the square root of a negative number.
error PRBMath_SD59x18_Sqrt_NegativeInput(SD59x18 x);

/// @notice Thrown when the calculating the square root overflows SD59x18.
error PRBMath_SD59x18_Sqrt_Overflow(SD59x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { UD2x18 } from "./ValueType.sol";

/// @notice Thrown when trying to cast a UD2x18 number that doesn't fit in SD1x18.
error PRBMath_UD2x18_IntoSD1x18_Overflow(UD2x18 x);

/// @notice Thrown when trying to cast a UD2x18 number that doesn't fit in uint40.
error PRBMath_UD2x18_IntoUint40_Overflow(UD2x18 x);