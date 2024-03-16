// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {
    LibParseOperand,
    BaseRainterpreterSubParserNPE2,
    Operand
} from "rain.interpreter/abstract/BaseRainterpreterSubParserNPE2.sol";
import {LibConvert} from "rain.lib.typecast/LibConvert.sol";
import {BadDynamicLength} from "rain.interpreter/error/ErrOpList.sol";
import {LibExternOpContextSenderNPE2} from "rain.interpreter/lib/extern/reference/op/LibExternOpContextSenderNPE2.sol";
import {LibExternOpContextCallingContractNPE2} from
    "rain.interpreter/lib/extern/reference/op/LibExternOpContextCallingContractNPE2.sol";
import {LibUint256Matrix} from "rain.solmem/lib/LibUint256Matrix.sol";

import {LibOrderBookSubParser, SUB_PARSER_WORD_PARSERS_LENGTH} from "../../lib/LibOrderBookSubParser.sol";
import {
    CONTEXT_COLUMNS,
    CONTEXT_BASE_ROWS,
    CONTEXT_BASE_ROW_SENDER,
    CONTEXT_BASE_ROW_CALLING_CONTRACT,
    CONTEXT_BASE_COLUMN,
    CONTEXT_VAULT_OUTPUTS_COLUMN,
    CONTEXT_VAULT_INPUTS_COLUMN,
    CONTEXT_CALCULATIONS_COLUMN,
    CONTEXT_VAULT_IO_BALANCE_DIFF,
    CONTEXT_VAULT_IO_BALANCE_BEFORE,
    CONTEXT_VAULT_IO_VAULT_ID,
    CONTEXT_VAULT_IO_TOKEN_DECIMALS,
    CONTEXT_VAULT_IO_TOKEN,
    CONTEXT_VAULT_IO_ROWS,
    CONTEXT_CALCULATIONS_ROW_IO_RATIO,
    CONTEXT_CALCULATIONS_ROW_MAX_OUTPUT,
    CONTEXT_CALCULATIONS_ROWS,
    CONTEXT_CALLING_CONTEXT_ROW_ORDER_COUNTERPARTY,
    CONTEXT_CALLING_CONTEXT_ROW_ORDER_OWNER,
    CONTEXT_CALLING_CONTEXT_ROW_ORDER_HASH,
    CONTEXT_CALLING_CONTEXT_ROWS,
    CONTEXT_CALLING_CONTEXT_COLUMN,
    CONTEXT_SIGNED_CONTEXT_START_COLUMN,
    CONTEXT_SIGNED_CONTEXT_START_ROW,
    CONTEXT_SIGNED_CONTEXT_START_ROWS,
    CONTEXT_SIGNED_CONTEXT_SIGNERS_COLUMN,
    CONTEXT_SIGNED_CONTEXT_SIGNERS_ROW,
    CONTEXT_SIGNED_CONTEXT_SIGNERS_ROWS
} from "../../lib/LibOrderBook.sol";

bytes constant SUB_PARSER_PARSE_META =
    hex"01004800040040020200110000000000001006102008000020040000000100000090088de69a0b015d8302c9be1f116682f50584c8d406bbcde60fb5f425102ce8cf1283156f0109ac300398cd200ab1aeaf0ea9bcef075e0bc300d3b4e80de78f2e0c9fc5d509a7e6560427db4a";
bytes constant SUB_PARSER_WORD_PARSERS =
    hex"0fc70fe60ff7100810181029103a104b105c106d107e108e109f10b010c110d210e310f31103";
bytes constant SUB_PARSER_OPERAND_HANDLERS =
    hex"12481248124812481248124812481248124812481248124812481248124812481248128d134c";

contract OrderBookSubParser is BaseRainterpreterSubParserNPE2 {
    using LibUint256Matrix for uint256[][];

    function subParserParseMeta() internal pure virtual override returns (bytes memory) {
        return SUB_PARSER_PARSE_META;
    }

    function subParserWordParsers() internal pure virtual override returns (bytes memory) {
        return SUB_PARSER_WORD_PARSERS;
    }

    function subParserOperandHandlers() internal pure virtual override returns (bytes memory) {
        return SUB_PARSER_OPERAND_HANDLERS;
    }

    function buildSubParserOperandHandlers() external pure returns (bytes memory) {
        // Add 2 columns for signers and signed context start.
        function(uint256[] memory) internal pure returns (Operand)[][] memory handlers =
            new function(uint256[] memory) internal pure returns (Operand)[][](CONTEXT_COLUMNS + 2);

        function(uint256[] memory) internal pure returns (Operand)[] memory contextBaseHandlers =
            new function(uint256[] memory) internal pure returns (Operand)[](CONTEXT_BASE_ROWS);
        contextBaseHandlers[CONTEXT_BASE_ROW_SENDER] = LibParseOperand.handleOperandDisallowed;
        contextBaseHandlers[CONTEXT_BASE_ROW_CALLING_CONTRACT] = LibParseOperand.handleOperandDisallowed;

        function(uint256[] memory) internal pure returns (Operand)[] memory contextCallingContextHandlers =
            new function(uint256[] memory) internal pure returns (Operand)[](CONTEXT_CALLING_CONTEXT_ROWS);
        contextCallingContextHandlers[CONTEXT_CALLING_CONTEXT_ROW_ORDER_HASH] = LibParseOperand.handleOperandDisallowed;
        contextCallingContextHandlers[CONTEXT_CALLING_CONTEXT_ROW_ORDER_OWNER] = LibParseOperand.handleOperandDisallowed;
        contextCallingContextHandlers[CONTEXT_CALLING_CONTEXT_ROW_ORDER_COUNTERPARTY] =
            LibParseOperand.handleOperandDisallowed;

        function(uint256[] memory) internal pure returns (Operand)[] memory contextCalculationsHandlers =
            new function(uint256[] memory) internal pure returns (Operand)[](CONTEXT_CALCULATIONS_ROWS);
        contextCalculationsHandlers[CONTEXT_CALCULATIONS_ROW_MAX_OUTPUT] = LibParseOperand.handleOperandDisallowed;
        contextCalculationsHandlers[CONTEXT_CALCULATIONS_ROW_IO_RATIO] = LibParseOperand.handleOperandDisallowed;

        function(uint256[] memory) internal pure returns (Operand)[] memory contextVaultInputsHandlers =
            new function(uint256[] memory) internal pure returns (Operand)[](CONTEXT_VAULT_IO_ROWS);
        contextVaultInputsHandlers[CONTEXT_VAULT_IO_TOKEN] = LibParseOperand.handleOperandDisallowed;
        contextVaultInputsHandlers[CONTEXT_VAULT_IO_TOKEN_DECIMALS] = LibParseOperand.handleOperandDisallowed;
        contextVaultInputsHandlers[CONTEXT_VAULT_IO_VAULT_ID] = LibParseOperand.handleOperandDisallowed;
        contextVaultInputsHandlers[CONTEXT_VAULT_IO_BALANCE_BEFORE] = LibParseOperand.handleOperandDisallowed;
        contextVaultInputsHandlers[CONTEXT_VAULT_IO_BALANCE_DIFF] = LibParseOperand.handleOperandDisallowed;

        function(uint256[] memory) internal pure returns (Operand)[] memory contextVaultOutputsHandlers =
            new function(uint256[] memory) internal pure returns (Operand)[](CONTEXT_VAULT_IO_ROWS);
        contextVaultOutputsHandlers[CONTEXT_VAULT_IO_TOKEN] = LibParseOperand.handleOperandDisallowed;
        contextVaultOutputsHandlers[CONTEXT_VAULT_IO_TOKEN_DECIMALS] = LibParseOperand.handleOperandDisallowed;
        contextVaultOutputsHandlers[CONTEXT_VAULT_IO_VAULT_ID] = LibParseOperand.handleOperandDisallowed;
        contextVaultOutputsHandlers[CONTEXT_VAULT_IO_BALANCE_BEFORE] = LibParseOperand.handleOperandDisallowed;
        contextVaultOutputsHandlers[CONTEXT_VAULT_IO_BALANCE_DIFF] = LibParseOperand.handleOperandDisallowed;

        function(uint256[] memory) internal pure returns (Operand)[] memory contextSignersHandlers =
            new function(uint256[] memory) internal pure returns (Operand)[](CONTEXT_SIGNED_CONTEXT_SIGNERS_ROWS);
        contextSignersHandlers[CONTEXT_SIGNED_CONTEXT_SIGNERS_ROW] = LibParseOperand.handleOperandSingleFullNoDefault;

        function(uint256[] memory) internal pure returns (Operand)[] memory contextSignedContextHandlers =
            new function(uint256[] memory) internal pure returns (Operand)[](CONTEXT_SIGNED_CONTEXT_START_ROWS);
        contextSignedContextHandlers[CONTEXT_SIGNED_CONTEXT_START_ROW] =
            LibParseOperand.handleOperandDoublePerByteNoDefault;

        handlers[CONTEXT_BASE_COLUMN] = contextBaseHandlers;
        handlers[CONTEXT_CALLING_CONTEXT_COLUMN] = contextCallingContextHandlers;
        handlers[CONTEXT_CALCULATIONS_COLUMN] = contextCalculationsHandlers;
        handlers[CONTEXT_VAULT_INPUTS_COLUMN] = contextVaultInputsHandlers;
        handlers[CONTEXT_VAULT_OUTPUTS_COLUMN] = contextVaultOutputsHandlers;
        handlers[CONTEXT_SIGNED_CONTEXT_SIGNERS_COLUMN] = contextSignersHandlers;
        handlers[CONTEXT_SIGNED_CONTEXT_START_COLUMN] = contextSignedContextHandlers;

        uint256[][] memory handlersUint256;
        assembly ("memory-safe") {
            handlersUint256 := handlers
        }

        return LibConvert.unsafeTo16BitBytes(handlersUint256.flatten());
    }

    function buildSubParserWordParsers() external pure returns (bytes memory) {
        // Add 2 columns for signers and signed context start.
        function(uint256, uint256, Operand) internal view returns (bool, bytes memory, uint256[] memory)[][] memory
            parsers = new function(uint256, uint256, Operand) internal view returns (bool, bytes memory, uint256[] memory)[][](
                CONTEXT_COLUMNS + 2
            );

        function(uint256, uint256, Operand) internal view returns (bool, bytes memory, uint256[] memory)[] memory
            contextBaseParsers = new function(uint256, uint256, Operand) internal view returns (bool, bytes memory, uint256[] memory)[](
                CONTEXT_BASE_ROWS
            );
        contextBaseParsers[CONTEXT_BASE_ROW_SENDER] = LibOrderBookSubParser.subParserSender;
        contextBaseParsers[CONTEXT_BASE_ROW_CALLING_CONTRACT] = LibOrderBookSubParser.subParserCallingContract;

        function(uint256, uint256, Operand) internal view returns (bool, bytes memory, uint256[] memory)[] memory
            contextCallingContextParsers = new function(uint256, uint256, Operand) internal view returns (bool, bytes memory, uint256[] memory)[](
                CONTEXT_CALLING_CONTEXT_ROWS
            );
        contextCallingContextParsers[CONTEXT_CALLING_CONTEXT_ROW_ORDER_HASH] = LibOrderBookSubParser.subParserOrderHash;
        contextCallingContextParsers[CONTEXT_CALLING_CONTEXT_ROW_ORDER_OWNER] =
            LibOrderBookSubParser.subParserOrderOwner;
        contextCallingContextParsers[CONTEXT_CALLING_CONTEXT_ROW_ORDER_COUNTERPARTY] =
            LibOrderBookSubParser.subParserOrderCounterparty;

        function(uint256, uint256, Operand) internal view returns (bool, bytes memory, uint256[] memory)[] memory
            contextCalculationsParsers = new function(uint256, uint256, Operand) internal view returns (bool, bytes memory, uint256[] memory)[](
                CONTEXT_CALCULATIONS_ROWS
            );
        contextCalculationsParsers[CONTEXT_CALCULATIONS_ROW_MAX_OUTPUT] = LibOrderBookSubParser.subParserMaxOutput;
        contextCalculationsParsers[CONTEXT_CALCULATIONS_ROW_IO_RATIO] = LibOrderBookSubParser.subParserIORatio;

        function(uint256, uint256, Operand) internal view returns (bool, bytes memory, uint256[] memory)[] memory
            contextVaultInputsParsers = new function(uint256, uint256, Operand) internal view returns (bool, bytes memory, uint256[] memory)[](
                CONTEXT_VAULT_IO_ROWS
            );
        contextVaultInputsParsers[CONTEXT_VAULT_IO_TOKEN] = LibOrderBookSubParser.subParserInputToken;
        contextVaultInputsParsers[CONTEXT_VAULT_IO_TOKEN_DECIMALS] = LibOrderBookSubParser.subParserInputTokenDecimals;
        contextVaultInputsParsers[CONTEXT_VAULT_IO_VAULT_ID] = LibOrderBookSubParser.subParserInputVaultId;
        contextVaultInputsParsers[CONTEXT_VAULT_IO_BALANCE_BEFORE] = LibOrderBookSubParser.subParserInputBalanceBefore;
        contextVaultInputsParsers[CONTEXT_VAULT_IO_BALANCE_DIFF] = LibOrderBookSubParser.subParserInputBalanceDiff;

        function(uint256, uint256, Operand) internal view returns (bool, bytes memory, uint256[] memory)[] memory
            contextVaultOutputsParsers = new function(uint256, uint256, Operand) internal view returns (bool, bytes memory, uint256[] memory)[](
                CONTEXT_VAULT_IO_ROWS
            );
        contextVaultOutputsParsers[CONTEXT_VAULT_IO_TOKEN] = LibOrderBookSubParser.subParserOutputToken;
        contextVaultOutputsParsers[CONTEXT_VAULT_IO_TOKEN_DECIMALS] = LibOrderBookSubParser.subParserOutputTokenDecimals;
        contextVaultOutputsParsers[CONTEXT_VAULT_IO_VAULT_ID] = LibOrderBookSubParser.subParserOutputVaultId;
        contextVaultOutputsParsers[CONTEXT_VAULT_IO_BALANCE_BEFORE] = LibOrderBookSubParser.subParserOutputBalanceBefore;
        contextVaultOutputsParsers[CONTEXT_VAULT_IO_BALANCE_DIFF] = LibOrderBookSubParser.subParserOutputBalanceDiff;

        function(uint256, uint256, Operand) internal view returns (bool, bytes memory, uint256[] memory)[] memory
            contextSignersParsers = new function(uint256, uint256, Operand) internal view returns (bool, bytes memory, uint256[] memory)[](
                CONTEXT_SIGNED_CONTEXT_SIGNERS_ROWS
            );
        contextSignersParsers[CONTEXT_SIGNED_CONTEXT_SIGNERS_ROW] = LibOrderBookSubParser.subParserSigners;

        function(uint256, uint256, Operand) internal view returns (bool, bytes memory, uint256[] memory)[] memory
            contextSignedContextParsers = new function(uint256, uint256, Operand) internal view returns (bool, bytes memory, uint256[] memory)[](
                CONTEXT_SIGNED_CONTEXT_START_ROWS
            );
        contextSignedContextParsers[CONTEXT_SIGNED_CONTEXT_START_ROW] = LibOrderBookSubParser.subParserSignedContext;

        parsers[CONTEXT_BASE_COLUMN] = contextBaseParsers;
        parsers[CONTEXT_CALLING_CONTEXT_COLUMN] = contextCallingContextParsers;
        parsers[CONTEXT_CALCULATIONS_COLUMN] = contextCalculationsParsers;
        parsers[CONTEXT_VAULT_INPUTS_COLUMN] = contextVaultInputsParsers;
        parsers[CONTEXT_VAULT_OUTPUTS_COLUMN] = contextVaultOutputsParsers;
        parsers[CONTEXT_SIGNED_CONTEXT_SIGNERS_COLUMN] = contextSignersParsers;
        parsers[CONTEXT_SIGNED_CONTEXT_START_COLUMN] = contextSignedContextParsers;

        uint256[][] memory parsersUint256;
        assembly ("memory-safe") {
            parsersUint256 := parsers
        }

        return LibConvert.unsafeTo16BitBytes(parsersUint256.flatten());
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {ERC165} from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {LibBytes, Pointer} from "rain.solmem/lib/LibBytes.sol";

import {ISubParserV2, COMPATIBLITY_V3} from "rain.interpreter.interface/interface/ISubParserV2.sol";
import {IncompatibleSubParser} from "../error/ErrSubParse.sol";
import {LibSubParse, ParseState} from "../lib/parse/LibSubParse.sol";
import {CMASK_RHS_WORD_TAIL} from "../lib/parse/LibParseCMask.sol";
import {LibParse, Operand} from "../lib/parse/LibParse.sol";
import {LibParseMeta} from "../lib/parse/LibParseMeta.sol";
import {LibParseOperand} from "../lib/parse/LibParseOperand.sol";

/// @dev This is a placeholder for the subparser function pointers.
/// The subparser function pointers are a list of 16 bit function pointers,
/// where each subparser function is responsible for parsing a particular
/// word into a an opcode that will be used by the main parser to build the
/// final bytecode.
bytes constant SUB_PARSER_WORD_PARSERS = hex"";

/// @dev This is a placeholder for the subparser meta bytes.
/// The subparser meta bytes are the same structure as the main parser meta
/// bytes. The exact same process of hashing, blooming, fingeprinting and index
/// lookup applies to the subparser meta bytes as the main parser meta bytes.
bytes constant SUB_PARSER_PARSE_META = hex"";

/// @dev This is a placeholder for the int that encodes pointers to operand
/// parsers.
bytes constant SUB_PARSER_OPERAND_HANDLERS = hex"";

/// @dev This is a placeholder for the int that encodes pointers to literal
/// parsers.
bytes constant SUB_PARSER_LITERAL_PARSERS = hex"";

/// Base implementation of `ISubParserV2`. Inherit from this contract and
/// override the virtual functions to align all the relevant pointers and
/// metadata bytes so that it can actually run.
/// The basic workflow for subparsing via this contract is:
/// - The main parser will call `subParse` with the subparser's compatibility
///   version and the data to parse.
/// - The subparser will check the compatibility is an exact match and revert if
///   not. This is the simplest and most conservative approach, if there's a new
///   compatibility version, a new version of the subparser will need to be
///   deployed even if the upstream changes are backwards compatible.
/// - The subparser will then parse the data, using the `subParserParseMeta`
///   function to get the metadata bytes, which must be overridden by the child
///   contract in order to be useful. The sub parser meta bytes are constructed
///   exactly the same as the main parser meta bytes, so the same types and libs
///   can be used to build them. The key difference is that the index of each
///   word in the authoring meta maps to a _parser_ function pointer, rather
///   than a _handler_ function pointer. What this means is that the function
///   at index N of `subParserFunctionPointers` is responsible for parsing
///   whatever data the main parser has passed to `subParse` into whatever the
///   final output of the subparser is. For example, the 5th parser function
///   might convert some word string `"foo"` into the bytecode that represents
///   an extern call on the main interpreter into the contract that provides
///   that extern logic. This decoupling allows any subparser function to
///   generate any runtime behaviour at all, provided it knows how to construct
///   the opcode for it.
/// - Currently the subparse handles literals and operands in the same way as
///   the main parser, but this may change in future. Likely that there will be
///   dedicated "sub literal" and "sub word" concepts, that should be more
///   composable than the current approach.
/// - The final result of the subparser is returned as a tuple of success,
///   bytecode and constants. The success flag is used to indicate whether the
///   subparser was able to parse the data, and the bytecode and constants are
///   the same as the main parser, and are used to construct the final bytecode
///   of the main parser. The expectation on failure is that there may be some
///   other subparser that can parse the data, so the main parser will handle
///   fallback logic.
abstract contract BaseRainterpreterSubParserNPE2 is ERC165, ISubParserV2 {
    using LibBytes for bytes;
    using LibParse for ParseState;
    using LibParseMeta for ParseState;
    using LibParseOperand for ParseState;

    /// Overrideable function to allow implementations to define their parse
    /// meta bytes.
    //slither-disable-next-line dead-code
    function subParserParseMeta() internal pure virtual returns (bytes memory) {
        return SUB_PARSER_PARSE_META;
    }

    /// Overrideable function to allow implementations to define their function
    /// pointers to each sub parser.
    //slither-disable-next-line dead-code
    function subParserWordParsers() internal pure virtual returns (bytes memory) {
        return SUB_PARSER_WORD_PARSERS;
    }

    /// Overrideable function to allow implementations to define their operand
    /// handlers.
    //slither-disable-next-line dead-code
    function subParserOperandHandlers() internal pure virtual returns (bytes memory) {
        return SUB_PARSER_OPERAND_HANDLERS;
    }

    /// Overrideable function to allow implementations to define their literal
    /// parsers.
    //slither-disable-next-line dead-code
    function subParserLiteralParsers() internal pure virtual returns (bytes memory) {
        return SUB_PARSER_LITERAL_PARSERS;
    }

    /// Overrideable function to allow implementations to define their
    /// compatibility version. Most implementations should leave this as the
    /// default as it matches the main parser's compatibility version as at the
    /// same commit the abstract sub parser is pulled from.
    //slither-disable-next-line dead-code
    function subParserCompatibility() internal pure virtual returns (bytes32) {
        return COMPATIBLITY_V3;
    }

    /// Overrideable function to allow implementations to define their
    /// literal dispatch matching. This is optional, and if not overridden
    /// simply won't attempt to parse any literals. This is usually what you
    /// want, as the main parser will handle common literals and the subparser
    /// can focus on words, which is the more common case.
    /// @param cursor The cursor to the memory location of the start of the
    /// dispatch data.
    /// @param end The cursor to the memory location of the end of the dispatch
    /// data.
    /// @return success Whether the dispatch was successfully matched. If the
    /// sub parser does not recognise the dispatch data, it should return false.
    /// The main parser MAY fallback to other sub parsers, so this is not
    /// necessarily a failure condition.
    /// @return index The index of the sub parser literal parser to use. If
    /// success is true, this MUST match the position of the function pointer in
    /// the bytes returned by `subParserLiteralParsers`.
    /// @return value The value of the dispatch data, which is passed to the
    /// sub parser literal parser. This MAY be zero if the sub parser does not
    /// need to use the dispatch data. The interpretation of this value is
    /// entirely up to the sub parser.
    //slither-disable-next-line dead-code
    function matchSubParseLiteralDispatch(uint256 cursor, uint256 end)
        internal
        pure
        virtual
        returns (bool success, uint256 index, uint256 value)
    {
        (cursor, end);
        success = false;
        index = 0;
        value = 0;
    }

    modifier onlyCompatible(bytes32 compatibility) {
        if (compatibility != subParserCompatibility()) {
            revert IncompatibleSubParser();
        }
        _;
    }

    /// A basic implementation of sub parsing literals that uses encoded
    /// function pointers to dispatch everything necessary in O(1) and allows
    /// for the child contract to override all relevant functions with some
    /// modest boilerplate.
    /// This is virtual but the expectation is that it generally DOES NOT need
    /// to be overridden, as the function pointers and metadata bytes are all
    /// that need to be changed to implement a new subparser.
    /// @inheritdoc ISubParserV2
    function subParseLiteral(bytes32 compatibility, bytes memory data)
        external
        pure
        virtual
        onlyCompatible(compatibility)
        returns (bool, uint256)
    {
        (uint256 dispatchStart, uint256 bodyStart, uint256 bodyEnd) = LibSubParse.consumeSubParseLiteralInputData(data);

        (bool success, uint256 index, uint256 dispatchValue) = matchSubParseLiteralDispatch(dispatchStart, bodyStart);

        if (success) {
            function (uint256, uint256, uint256) internal pure returns (uint256) subParser;
            bytes memory localSubParserLiteralParsers = subParserLiteralParsers();
            assembly ("memory-safe") {
                subParser := and(mload(add(localSubParserLiteralParsers, mul(add(index, 1), 2))), 0xFFFF)
            }
            return (true, subParser(dispatchValue, bodyStart, bodyEnd));
        } else {
            return (false, 0);
        }
    }

    /// A basic implementation of sub parsing words that uses encoded function
    /// pointers to dispatch everything necessary in O(1) and allows for the
    /// child contract to override all relevant functions with some modest
    /// boilerplate.
    /// This is virtual but the expectation is that it generally DOES NOT need
    /// to be overridden, as the function pointers and metadata bytes are all
    /// that need to be changed to implement a new subparser.
    /// @inheritdoc ISubParserV2
    function subParseWord(bytes32 compatibility, bytes memory data)
        external
        pure
        virtual
        onlyCompatible(compatibility)
        returns (bool, bytes memory, uint256[] memory)
    {
        (uint256 constantsHeight, uint256 ioByte, ParseState memory state) =
            LibSubParse.consumeSubParseWordInputData(data, subParserParseMeta(), subParserOperandHandlers());
        uint256 cursor = Pointer.unwrap(state.data.dataPointer());
        uint256 end = cursor + state.data.length;

        bytes32 word;
        (cursor, word) = LibParse.parseWord(cursor, end, CMASK_RHS_WORD_TAIL);
        (bool exists, uint256 index) = state.lookupWord(word);
        if (exists) {
            Operand operand = state.handleOperand(index);
            function (uint256, uint256, Operand) internal pure returns (bool, bytes memory, uint256[] memory) subParser;
            bytes memory localSubParserWordParsers = subParserWordParsers();
            assembly ("memory-safe") {
                subParser := and(mload(add(localSubParserWordParsers, mul(add(index, 1), 2))), 0xFFFF)
            }
            return subParser(constantsHeight, ioByte, operand);
        } else {
            return (false, "", new uint256[](0));
        }
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ISubParserV2).interfaceId || super.supportsInterface(interfaceId);
    }
}

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
pragma solidity ^0.8.19;

/// @dev Workaround for https://github.com/foundry-rs/foundry/issues/6572
contract ErrOpList {}

/// Thrown when a dynamic length array is NOT 1 more than a fixed length array.
/// Should never happen outside a major breaking change to memory layouts.
error BadDynamicLength(uint256 dynamicLength, uint256 standardOpsLength);

// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {LibSubParse} from "../../../parse/LibSubParse.sol";
import {IInterpreterExternV3} from "rain.interpreter.interface/interface/IInterpreterExternV3.sol";
import {CONTEXT_BASE_COLUMN, CONTEXT_BASE_ROW_SENDER} from "rain.interpreter.interface/lib/caller/LibContext.sol";

/// @title LibExternOpContextSenderNPE2
/// This op is a simple reference to the sender of the transaction that called
/// the interpreter. It is used to demonstrate how to implement context
/// references.
library LibExternOpContextSenderNPE2 {
    /// The sub parser for the extern increment opcode. It has no special logic
    /// so uses the default sub parser from `LibSubParse`.
    //slither-disable-next-line dead-code
    function subParser(uint256, uint256, Operand) internal pure returns (bool, bytes memory, uint256[] memory) {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_BASE_COLUMN, CONTEXT_BASE_ROW_SENDER);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {Operand} from "rain.interpreter.interface/interface/IInterpreterV2.sol";
import {LibSubParse} from "../../../parse/LibSubParse.sol";
import {IInterpreterExternV3} from "rain.interpreter.interface/interface/IInterpreterExternV3.sol";
import {
    CONTEXT_BASE_COLUMN,
    CONTEXT_BASE_ROW_CALLING_CONTRACT
} from "rain.interpreter.interface/lib/caller/LibContext.sol";

/// @title LibExternOpContextCallingContractNPE2
/// This op is a simple reference to the contract that called the interpreter.
/// It is used to demonstrate how to implement context references.
library LibExternOpContextCallingContractNPE2 {
    /// The sub parser for the extern increment opcode. It has no special logic
    /// so uses the default sub parser from `LibSubParse`.
    //slither-disable-next-line dead-code
    function subParser(uint256, uint256, Operand) internal pure returns (bool, bytes memory, uint256[] memory) {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_BASE_COLUMN, CONTEXT_BASE_ROW_CALLING_CONTRACT);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./LibPointer.sol";

library LibUint256Matrix {
    /// Pointer to the start (length prefix) of a `uint256[][]`.
    /// @param matrix The matrix to get the start pointer of.
    /// @return pointer The pointer to the start of `matrix`.
    function startPointer(uint256[][] memory matrix) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := matrix
        }
    }

    /// Pointer to the data of a `uint256[][]` NOT the length prefix.
    /// Note that the data of a `uint256[][]` is _references_ to the `uint256[]`
    /// start pointers and does NOT include the arrays themselves.
    /// @param matrix The matrix to get the data pointer of.
    /// @return pointer The pointer to the data of `matrix`.
    function dataPointer(uint256[][] memory matrix) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(matrix, 0x20)
        }
    }

    /// Pointer to the end of the allocated memory of a matrix.
    /// Note that the data of a `uint256[][]` is _references_ to the `uint256[]`
    /// start pointers and does NOT include the arrays themselves.
    /// @param matrix The matrix to get the end pointer of.
    /// @return pointer The pointer to the end of `matrix`.
    function endPointer(uint256[][] memory matrix) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(matrix, add(0x20, mul(0x20, mload(matrix))))
        }
    }

    /// Cast a `Pointer` to `uint256[][]` without modification or safety checks.
    /// The caller MUST ensure the pointer is to a valid region of memory for
    /// some `uint256[][]`.
    /// @param pointer The pointer to cast to `uint256[][]`.
    /// @return matrix The cast `uint256[][]`.
    function unsafeAsUint256Matrix(Pointer pointer) internal pure returns (uint256[][] memory matrix) {
        assembly ("memory-safe") {
            matrix := pointer
        }
    }

    /// 2-dimensional analogue of `arrayFrom`. Takes a 1-dimensional array and
    /// coerces it to a 2-dimensional matrix where the first and only item in the
    /// matrix is the 1-dimensional array.
    /// @param a The 1-dimensional array to include in the matrix.
    /// @return matrix The 2-dimensional matrix containing `a`.
    function matrixFrom(uint256[] memory a) internal pure returns (uint256[][] memory matrix) {
        assembly ("memory-safe") {
            matrix := mload(0x40)
            mstore(matrix, 1)
            mstore(add(matrix, 0x20), a)
            mstore(0x40, add(matrix, 0x40))
        }
    }

    /// 2-dimensional analogue of `arrayFrom`. Takes 1-dimensional arrays and
    /// coerces them to a 2-dimensional matrix where items in the matrix are the
    /// 1-dimensional arrays.
    /// @param a The 1-dimensional array to include in the matrix.
    /// @param b Second 1-dimensional array to include in the matrix.
    /// @return matrix The 2-dimensional matrix containing `a` and `b`.
    function matrixFrom(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[][] memory matrix) {
        assembly ("memory-safe") {
            matrix := mload(0x40)
            mstore(matrix, 2)
            mstore(add(matrix, 0x20), a)
            mstore(add(matrix, 0x40), b)
            mstore(0x40, add(matrix, 0x60))
        }
    }

    /// 2-dimensional analogue of `arrayFrom`. Takes 1-dimensional arrays and
    /// coerces them to a 2-dimensional matrix where items in the matrix are the
    /// 1-dimensional arrays.
    /// @param a The 1-dimensional array to include in the matrix.
    /// @param b Second 1-dimensional array to include in the matrix.
    /// @param c Third 1-dimensional array to include in the matrix.
    /// @return matrix The 2-dimensional matrix containing `a`, `b` and `c`.
    function matrixFrom(uint256[] memory a, uint256[] memory b, uint256[] memory c)
        internal
        pure
        returns (uint256[][] memory matrix)
    {
        assembly ("memory-safe") {
            matrix := mload(0x40)
            mstore(matrix, 3)
            mstore(add(matrix, 0x20), a)
            mstore(add(matrix, 0x40), b)
            mstore(add(matrix, 0x60), c)
            mstore(0x40, add(matrix, 0x80))
        }
    }

    /// Counts the total number of items in the matrix across all internal
    /// arrays. Normally `matrix.length` only returns the number of internal
    /// arrays, not the total number of items in the matrix.
    function itemCount(uint256[][] memory matrix) internal pure returns (uint256 count) {
        assembly ("memory-safe") {
            let cursor := add(matrix, 0x20)
            let end := add(cursor, mul(mload(matrix), 0x20))

            for {} lt(cursor, end) {} {
                count := add(count, mload(mload(cursor)))
                cursor := add(cursor, 0x20)
            }
        }
    }

    /// Allocates and builds a new `uint256[]` from a `uint256[][]`. This is
    /// potentially memory intensive and expensive, but there's no way around
    /// the allocation if a flat array is needed. This is because 2-dimensional
    /// arrays are stored as a length-prefixed array of pointers to 1-dimensional
    /// arrays, not as a contiguous block of memory.
    /// @param matrix The matrix to flatten.
    /// @return array The flattened array.
    function flatten(uint256[][] memory matrix) internal pure returns (uint256[] memory) {
        uint256 length = itemCount(matrix);
        uint256[] memory array;
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(0x40, add(array, add(0x20, mul(length, 0x20))))
            mstore(array, length)

            let cursor := add(matrix, 0x20)
            let end := add(cursor, mul(mload(matrix), 0x20))

            let arrayCursor := add(array, 0x20)
            for {} lt(cursor, end) {} {
                let itemCursor := add(mload(cursor), 0x20)
                let itemEnd := add(itemCursor, mul(mload(mload(cursor)), 0x20))
                for {} lt(itemCursor, itemEnd) {} {
                    mstore(arrayCursor, mload(itemCursor))
                    arrayCursor := add(arrayCursor, 0x20)
                    itemCursor := add(itemCursor, 0x20)
                }
                cursor := add(cursor, 0x20)
            }
        }
        return array;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {AuthoringMetaV2, Operand} from "rain.interpreter.interface/interface/ISubParserV2.sol";
import {LibUint256Matrix} from "rain.solmem/lib/LibUint256Matrix.sol";
import {LibSubParse} from "rain.interpreter/lib/parse/LibSubParse.sol";
import {
    CONTEXT_BASE_COLUMN,
    CONTEXT_BASE_ROW_SENDER,
    CONTEXT_BASE_ROW_CALLING_CONTRACT,
    CONTEXT_BASE_ROWS,
    CONTEXT_COLUMNS,
    CONTEXT_VAULT_OUTPUTS_COLUMN,
    CONTEXT_VAULT_INPUTS_COLUMN,
    CONTEXT_CALCULATIONS_COLUMN,
    CONTEXT_CALLING_CONTEXT_COLUMN,
    CONTEXT_VAULT_IO_BALANCE_DIFF,
    CONTEXT_VAULT_IO_BALANCE_BEFORE,
    CONTEXT_VAULT_IO_VAULT_ID,
    CONTEXT_VAULT_IO_TOKEN_DECIMALS,
    CONTEXT_VAULT_IO_TOKEN,
    CONTEXT_VAULT_IO_ROWS,
    CONTEXT_CALCULATIONS_ROW_IO_RATIO,
    CONTEXT_CALCULATIONS_ROW_MAX_OUTPUT,
    CONTEXT_CALCULATIONS_ROWS,
    CONTEXT_CALLING_CONTEXT_ROW_ORDER_COUNTERPARTY,
    CONTEXT_CALLING_CONTEXT_ROW_ORDER_OWNER,
    CONTEXT_CALLING_CONTEXT_ROW_ORDER_HASH,
    CONTEXT_CALLING_CONTEXT_ROWS,
    CONTEXT_SIGNED_CONTEXT_SIGNERS_COLUMN,
    CONTEXT_SIGNED_CONTEXT_SIGNERS_ROW,
    CONTEXT_SIGNED_CONTEXT_SIGNERS_ROWS,
    CONTEXT_SIGNED_CONTEXT_START_COLUMN,
    CONTEXT_SIGNED_CONTEXT_START_ROW,
    CONTEXT_SIGNED_CONTEXT_START_ROWS
} from "./LibOrderBook.sol";

uint256 constant SUB_PARSER_WORD_PARSERS_LENGTH = 2;

bytes constant WORD_ORDER_CLEARER = "order-clearer";
bytes constant WORD_ORDERBOOK = "orderbook";
bytes constant WORD_ORDER_HASH = "order-hash";
bytes constant WORD_ORDER_OWNER = "order-owner";
bytes constant WORD_ORDER_COUNTERPARTY = "order-counterparty";
bytes constant WORD_CALCULATED_MAX_OUTPUT = "calculated-max-output";
bytes constant WORD_CALCULATED_IO_RATIO = "calculated-io-ratio";
bytes constant WORD_INPUT_TOKEN = "input-token";
bytes constant WORD_INPUT_TOKEN_DECIMALS = "input-token-decimals";
bytes constant WORD_INPUT_VAULT_ID = "input-vault-id";
bytes constant WORD_INPUT_VAULT_BALANCE_BEFORE = "input-vault-balance-before";
bytes constant WORD_INPUT_VAULT_BALANCE_INCREASE = "input-vault-balance-increase";
bytes constant WORD_OUTPUT_TOKEN = "output-token";
bytes constant WORD_OUTPUT_TOKEN_DECIMALS = "output-token-decimals";
bytes constant WORD_OUTPUT_VAULT_ID = "output-vault-id";
bytes constant WORD_OUTPUT_VAULT_BALANCE_BEFORE = "output-vault-balance-before";
bytes constant WORD_OUTPUT_VAULT_BALANCE_DECREASE = "output-vault-balance-decrease";

/// @title LibOrderBookSubParser
library LibOrderBookSubParser {
    using LibUint256Matrix for uint256[][];

    function subParserSender(uint256, uint256, Operand) internal pure returns (bool, bytes memory, uint256[] memory) {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_BASE_COLUMN, CONTEXT_BASE_ROW_SENDER);
    }

    function subParserCallingContract(uint256, uint256, Operand)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_BASE_COLUMN, CONTEXT_BASE_ROW_CALLING_CONTRACT);
    }

    function subParserOrderHash(uint256, uint256, Operand)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_CALLING_CONTEXT_COLUMN, CONTEXT_CALLING_CONTEXT_ROW_ORDER_HASH);
    }

    function subParserOrderOwner(uint256, uint256, Operand)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_CALLING_CONTEXT_COLUMN, CONTEXT_CALLING_CONTEXT_ROW_ORDER_OWNER);
    }

    function subParserOrderCounterparty(uint256, uint256, Operand)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        //slither-disable-next-line unused-return
        return
            LibSubParse.subParserContext(CONTEXT_CALLING_CONTEXT_COLUMN, CONTEXT_CALLING_CONTEXT_ROW_ORDER_COUNTERPARTY);
    }

    function subParserMaxOutput(uint256, uint256, Operand)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_CALCULATIONS_COLUMN, CONTEXT_CALCULATIONS_ROW_MAX_OUTPUT);
    }

    function subParserIORatio(uint256, uint256, Operand) internal pure returns (bool, bytes memory, uint256[] memory) {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_CALCULATIONS_COLUMN, CONTEXT_CALCULATIONS_ROW_IO_RATIO);
    }

    function subParserInputToken(uint256, uint256, Operand)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_VAULT_INPUTS_COLUMN, CONTEXT_VAULT_IO_TOKEN);
    }

    function subParserInputTokenDecimals(uint256, uint256, Operand)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_VAULT_INPUTS_COLUMN, CONTEXT_VAULT_IO_TOKEN_DECIMALS);
    }

    function subParserInputVaultId(uint256, uint256, Operand)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_VAULT_INPUTS_COLUMN, CONTEXT_VAULT_IO_VAULT_ID);
    }

    function subParserInputBalanceBefore(uint256, uint256, Operand)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_VAULT_INPUTS_COLUMN, CONTEXT_VAULT_IO_BALANCE_BEFORE);
    }

    function subParserInputBalanceDiff(uint256, uint256, Operand)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_VAULT_INPUTS_COLUMN, CONTEXT_VAULT_IO_BALANCE_DIFF);
    }

    function subParserOutputToken(uint256, uint256, Operand)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_VAULT_OUTPUTS_COLUMN, CONTEXT_VAULT_IO_TOKEN);
    }

    function subParserOutputTokenDecimals(uint256, uint256, Operand)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_VAULT_OUTPUTS_COLUMN, CONTEXT_VAULT_IO_TOKEN_DECIMALS);
    }

    function subParserOutputVaultId(uint256, uint256, Operand)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_VAULT_OUTPUTS_COLUMN, CONTEXT_VAULT_IO_VAULT_ID);
    }

    function subParserOutputBalanceBefore(uint256, uint256, Operand)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_VAULT_OUTPUTS_COLUMN, CONTEXT_VAULT_IO_BALANCE_BEFORE);
    }

    function subParserOutputBalanceDiff(uint256, uint256, Operand)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_VAULT_OUTPUTS_COLUMN, CONTEXT_VAULT_IO_BALANCE_DIFF);
    }

    function subParserSigners(uint256, uint256, Operand operand)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_SIGNED_CONTEXT_SIGNERS_COLUMN, Operand.unwrap(operand));
    }

    function subParserSignedContext(uint256, uint256, Operand operand)
        internal
        pure
        returns (bool, bytes memory, uint256[] memory)
    {
        uint256 column = Operand.unwrap(operand) & 0xFF;
        uint256 row = (Operand.unwrap(operand) >> 8) & 0xFF;
        //slither-disable-next-line unused-return
        return LibSubParse.subParserContext(CONTEXT_SIGNED_CONTEXT_START_COLUMN + column, row);
    }

    //slither-disable-next-line dead-code
    function authoringMetaV2() internal pure returns (bytes memory) {
        // Add 2 for the signed context signers and signed context start columns.
        AuthoringMetaV2[][] memory meta = new AuthoringMetaV2[][](CONTEXT_COLUMNS + 2);

        AuthoringMetaV2[] memory contextBaseMeta = new AuthoringMetaV2[](CONTEXT_BASE_ROWS);
        contextBaseMeta[CONTEXT_BASE_ROW_SENDER] = AuthoringMetaV2(
            bytes32(WORD_ORDER_CLEARER),
            "The order clearer is the address that submitted the transaction that is causing the order to execute. This MAY be the counterparty, e.g. when an order is being taken directly, but it MAY NOT be the counterparty if a third party is clearing two orders against each other."
        );
        contextBaseMeta[CONTEXT_BASE_ROW_CALLING_CONTRACT] =
            AuthoringMetaV2(bytes32(WORD_ORDERBOOK), "The address of the orderbook that the order is being run on.");

        AuthoringMetaV2[] memory contextCallingContextMeta = new AuthoringMetaV2[](CONTEXT_CALLING_CONTEXT_ROWS);
        contextCallingContextMeta[CONTEXT_CALLING_CONTEXT_ROW_ORDER_HASH] =
            AuthoringMetaV2(bytes32(WORD_ORDER_HASH), "The hash of the order that is being cleared.");
        contextCallingContextMeta[CONTEXT_CALLING_CONTEXT_ROW_ORDER_OWNER] =
            AuthoringMetaV2(bytes32(WORD_ORDER_OWNER), "The address of the order owner.");
        contextCallingContextMeta[CONTEXT_CALLING_CONTEXT_ROW_ORDER_COUNTERPARTY] = AuthoringMetaV2(
            bytes32(WORD_ORDER_COUNTERPARTY),
            "The address of the owner of the counterparty order. Will be the order taker if there is no counterparty order."
        );

        AuthoringMetaV2[] memory contextCalculationsMeta = new AuthoringMetaV2[](CONTEXT_CALCULATIONS_ROWS);
        contextCalculationsMeta[CONTEXT_CALCULATIONS_ROW_MAX_OUTPUT] = AuthoringMetaV2(
            bytes32(WORD_CALCULATED_MAX_OUTPUT),
            "The maximum output of the order, i.e. the maximum amount of the output token that the order will send. This is normalized to 18 decimal fixed point regardless of the decimals of the underlying token. This is 0 before calculations have been run."
        );
        contextCalculationsMeta[CONTEXT_CALCULATIONS_ROW_IO_RATIO] = AuthoringMetaV2(
            bytes32(WORD_CALCULATED_IO_RATIO),
            "The ratio of the input to output token, i.e. the amount of the input token that the order will receive for each unit of the output token that it sends. This is normalized to 18 decimal fixed point regardless of the decimals of the underlying tokens. This is 0 before calculations have been run."
        );

        AuthoringMetaV2[] memory contextVaultInputsMeta = new AuthoringMetaV2[](CONTEXT_VAULT_IO_ROWS);
        contextVaultInputsMeta[CONTEXT_VAULT_IO_TOKEN] =
            AuthoringMetaV2(bytes32(WORD_INPUT_TOKEN), "The address of the input token for the vault input.");
        contextVaultInputsMeta[CONTEXT_VAULT_IO_TOKEN_DECIMALS] =
            AuthoringMetaV2(bytes32(WORD_INPUT_TOKEN_DECIMALS), "The decimals of the input token for the vault input.");
        contextVaultInputsMeta[CONTEXT_VAULT_IO_VAULT_ID] = AuthoringMetaV2(
            bytes32(WORD_INPUT_VAULT_ID), "The ID of the input vault that incoming tokens are received into."
        );
        contextVaultInputsMeta[CONTEXT_VAULT_IO_BALANCE_BEFORE] = AuthoringMetaV2(
            bytes32(WORD_INPUT_VAULT_BALANCE_BEFORE), "The balance of the input vault before the order is cleared."
        );
        contextVaultInputsMeta[CONTEXT_VAULT_IO_BALANCE_DIFF] = AuthoringMetaV2(
            bytes32(WORD_INPUT_VAULT_BALANCE_INCREASE),
            "The difference in the balance of the input vault after the order is cleared. This is always positive so it must be added to the input balance before to get the final vault balance. This is 0 before calculations have been run."
        );

        AuthoringMetaV2[] memory contextVaultOutputsMeta = new AuthoringMetaV2[](CONTEXT_VAULT_IO_ROWS);
        contextVaultOutputsMeta[CONTEXT_VAULT_IO_TOKEN] =
            AuthoringMetaV2(bytes32(WORD_OUTPUT_TOKEN), "The address of the output token for the vault output.");
        contextVaultOutputsMeta[CONTEXT_VAULT_IO_TOKEN_DECIMALS] = AuthoringMetaV2(
            bytes32(WORD_OUTPUT_TOKEN_DECIMALS), "The decimals of the output token for the vault output."
        );
        contextVaultOutputsMeta[CONTEXT_VAULT_IO_VAULT_ID] = AuthoringMetaV2(
            bytes32(WORD_OUTPUT_VAULT_ID), "The ID of the output vault that outgoing tokens are sent from."
        );
        contextVaultOutputsMeta[CONTEXT_VAULT_IO_BALANCE_BEFORE] = AuthoringMetaV2(
            bytes32(WORD_OUTPUT_VAULT_BALANCE_BEFORE), "The balance of the output vault before the order is cleared."
        );
        contextVaultOutputsMeta[CONTEXT_VAULT_IO_BALANCE_DIFF] = AuthoringMetaV2(
            bytes32(WORD_OUTPUT_VAULT_BALANCE_DECREASE),
            "The difference in the balance of the output vault after the order is cleared. This is always positive so it must be subtracted from the output balance before to get the final vault balance. This is 0 before calculations have been run."
        );

        AuthoringMetaV2[] memory contextSignersMeta = new AuthoringMetaV2[](CONTEXT_SIGNED_CONTEXT_SIGNERS_ROWS);
        contextSignersMeta[CONTEXT_SIGNED_CONTEXT_SIGNERS_ROW] = AuthoringMetaV2(
            bytes32("signer"),
            "The addresses of the signers of the signed context. The indexes of the signers matches the column they signed in the signed context grid."
        );

        AuthoringMetaV2[] memory contextSignedMeta = new AuthoringMetaV2[](CONTEXT_SIGNED_CONTEXT_START_ROWS);
        contextSignedMeta[CONTEXT_SIGNED_CONTEXT_START_ROW] = AuthoringMetaV2(
            bytes32("signed-context"),
            "Signed context is provided by the order clearer/taker and can be signed by anyone. Orderbook will check the signature, but the expression author much authorize the signer's public key."
        );

        meta[CONTEXT_BASE_COLUMN] = contextBaseMeta;
        meta[CONTEXT_CALLING_CONTEXT_COLUMN] = contextCallingContextMeta;
        meta[CONTEXT_CALCULATIONS_COLUMN] = contextCalculationsMeta;
        meta[CONTEXT_VAULT_INPUTS_COLUMN] = contextVaultInputsMeta;
        meta[CONTEXT_VAULT_OUTPUTS_COLUMN] = contextVaultOutputsMeta;
        meta[CONTEXT_SIGNED_CONTEXT_SIGNERS_COLUMN] = contextSignersMeta;
        meta[CONTEXT_SIGNED_CONTEXT_START_COLUMN] = contextSignedMeta;

        uint256[][] memory metaUint256;
        assembly {
            metaUint256 := meta
        }
        uint256[] memory metaUint256Flattened = metaUint256.flatten();
        AuthoringMetaV2[] memory metaFlattened;
        assembly {
            metaFlattened := metaUint256Flattened
        }

        return abi.encode(metaFlattened);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {
    CONTEXT_BASE_ROWS,
    CONTEXT_BASE_ROW_SENDER,
    CONTEXT_BASE_ROW_CALLING_CONTRACT,
    CONTEXT_BASE_COLUMN
} from "rain.interpreter.interface/lib/caller/LibContext.sol";

/// @dev Orderbook context is actually fairly complex. The calling context column
/// is populated before calculate order, but the remaining columns are only
/// available to handle IO as they depend on the full evaluation of calculuate
/// order, and cross referencing against the same from the counterparty, as well
/// as accounting limits such as current vault balances, etc.
/// The token address and decimals for vault inputs and outputs IS available to
/// the calculate order entrypoint, but not the final vault balances/diff.
uint256 constant CALLING_CONTEXT_COLUMNS = 4;

uint256 constant CONTEXT_COLUMNS = CALLING_CONTEXT_COLUMNS + 1;

/// @dev Contextual data available to both calculate order and handle IO. The
/// order hash, order owner and order counterparty. IMPORTANT NOTE that the
/// typical base context of an order with the caller will often be an unrelated
/// clearer of the order rather than the owner or counterparty.
uint256 constant CONTEXT_CALLING_CONTEXT_COLUMN = 1;
uint256 constant CONTEXT_CALLING_CONTEXT_ROWS = 3;

uint256 constant CONTEXT_CALLING_CONTEXT_ROW_ORDER_HASH = 0;
uint256 constant CONTEXT_CALLING_CONTEXT_ROW_ORDER_OWNER = 1;
uint256 constant CONTEXT_CALLING_CONTEXT_ROW_ORDER_COUNTERPARTY = 2;

/// @dev Calculations column contains the DECIMAL RESCALED calculations but
/// otherwise provided as-is according to calculate order entrypoint
uint256 constant CONTEXT_CALCULATIONS_COLUMN = 2;
uint256 constant CONTEXT_CALCULATIONS_ROWS = 2;

uint256 constant CONTEXT_CALCULATIONS_ROW_MAX_OUTPUT = 0;
uint256 constant CONTEXT_CALCULATIONS_ROW_IO_RATIO = 1;

/// @dev Vault inputs are the literal token amounts and vault balances before and
/// after for the input token from the perspective of the order. MAY be
/// significantly different to the calculated amount due to insufficient vault
/// balances from either the owner or counterparty, etc.
uint256 constant CONTEXT_VAULT_INPUTS_COLUMN = 3;
/// @dev Vault outputs are the same as vault inputs but for the output token from
/// the perspective of the order.
uint256 constant CONTEXT_VAULT_OUTPUTS_COLUMN = 4;

/// @dev Row of the token address for vault inputs and outputs columns.
uint256 constant CONTEXT_VAULT_IO_TOKEN = 0;
/// @dev Row of the token decimals for vault inputs and outputs columns.
uint256 constant CONTEXT_VAULT_IO_TOKEN_DECIMALS = 1;
/// @dev Row of the vault ID for vault inputs and outputs columns.
uint256 constant CONTEXT_VAULT_IO_VAULT_ID = 2;
/// @dev Row of the vault balance before the order was cleared for vault inputs
/// and outputs columns.
uint256 constant CONTEXT_VAULT_IO_BALANCE_BEFORE = 3;
/// @dev Row of the vault balance difference after the order was cleared for
/// vault inputs and outputs columns. The diff is ALWAYS POSITIVE as it is a
/// `uint256` so it must be added to input balances and subtraced from output
/// balances.
uint256 constant CONTEXT_VAULT_IO_BALANCE_DIFF = 4;
/// @dev Length of a vault IO column.
uint256 constant CONTEXT_VAULT_IO_ROWS = 5;

uint256 constant CONTEXT_SIGNED_CONTEXT_SIGNERS_COLUMN = 5;
uint256 constant CONTEXT_SIGNED_CONTEXT_SIGNERS_ROWS = 1;
uint256 constant CONTEXT_SIGNED_CONTEXT_SIGNERS_ROW = 0;

uint256 constant CONTEXT_SIGNED_CONTEXT_START_COLUMN = 6;
uint256 constant CONTEXT_SIGNED_CONTEXT_START_ROWS = 1;
uint256 constant CONTEXT_SIGNED_CONTEXT_START_ROW = 0;

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

import {LibUint256Array} from "rain.solmem/lib/LibUint256Array.sol";
import {LibHashNoAlloc, HASH_NIL} from "rain.lib.hash/LibHashNoAlloc.sol";

import {SignatureChecker} from "openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import {
    IInterpreterCallerV2,
    SignedContextV1,
    SIGNED_CONTEXT_SIGNER_OFFSET,
    SIGNED_CONTEXT_SIGNATURE_OFFSET,
    SIGNED_CONTEXT_CONTEXT_OFFSET
} from "../../interface/IInterpreterCallerV2.sol";

/// Thrown when the ith signature from a list of signed contexts is invalid.
error InvalidSignature(uint256 i);

uint256 constant CONTEXT_BASE_COLUMN = 0;
uint256 constant CONTEXT_BASE_ROWS = 2;

uint256 constant CONTEXT_BASE_ROW_SENDER = 0;
uint256 constant CONTEXT_BASE_ROW_CALLING_CONTRACT = 1;

/// @title LibContext
/// @notice Conventions for working with context as a calling contract. All of
/// this functionality is OPTIONAL but probably useful for the majority of use
/// cases. By building and authenticating onchain, caller provided and signed
/// contexts all in a standard way the overall usability of context is greatly
/// improved for expression authors and readers. Any calling contract that can
/// match the context expectations of an existing expression is one large step
/// closer to compatibility and portability, inheriting network effects of what
/// has already been authored elsewhere.
library LibContext {
    using LibUint256Array for uint256[];

    /// The base context is the `msg.sender` and address of the calling contract.
    /// As the interpreter itself is called via an external interface and may be
    /// statically calling itself, it MAY NOT have any ability to inspect either
    /// of these values. Even if this were not the case the calling contract
    /// cannot assume the existence of some opcode(s) in the interpreter that
    /// inspect the caller, so providing these two values as context is
    /// sufficient to decouple the calling contract from the interpreter. It is
    /// STRONGLY RECOMMENDED that even if the calling contract has "no context"
    /// that it still provides this base to every `eval`.
    ///
    /// Calling contracts DO NOT need to call this directly. It is built and
    /// merged automatically into the standard context built by `build`.
    ///
    /// @return The `msg.sender` and address of the calling contract using this
    /// library, as a context-compatible array.
    function base() internal view returns (uint256[] memory) {
        return LibUint256Array.arrayFrom(uint256(uint160(msg.sender)), uint256(uint160(address(this))));
    }

    /// Standard hashing process over a single `SignedContextV1`. Notably used
    /// to hash a list as `SignedContextV1[]` but could also be used to hash a
    /// single `SignedContextV1` in isolation. Avoids allocating memory by
    /// hashing each struct field in sequence within the memory scratch space.
    /// @param signedContext The signed context to hash.
    /// @param hashed The hashed signed context.
    function hash(SignedContextV1 memory signedContext) internal pure returns (bytes32 hashed) {
        uint256 signerOffset = SIGNED_CONTEXT_SIGNER_OFFSET;
        uint256 contextOffset = SIGNED_CONTEXT_CONTEXT_OFFSET;
        uint256 signatureOffset = SIGNED_CONTEXT_SIGNATURE_OFFSET;

        assembly ("memory-safe") {
            mstore(0, keccak256(add(signedContext, signerOffset), 0x20))

            let context_ := mload(add(signedContext, contextOffset))
            mstore(0x20, keccak256(add(context_, 0x20), mul(mload(context_), 0x20)))

            mstore(0, keccak256(0, 0x40))

            let signature_ := mload(add(signedContext, signatureOffset))
            mstore(0x20, keccak256(add(signature_, 0x20), mload(signature_)))

            hashed := keccak256(0, 0x40)
        }
    }

    /// Standard hashing process over a list of signed contexts. Situationally
    /// useful if the calling contract wants to record that it has seen a set of
    /// signed data then later compare it against some input (e.g. to ensure that
    /// many calls of some function all share the same input values). Note that
    /// unlike the internals of `build`, this hashes over the signer and the
    /// signature, to ensure that some data cannot be re-signed and used under
    /// a different provenance later.
    /// @param signedContexts The list of signed contexts to hash over.
    /// @return hashed The hash of the signed contexts.
    function hash(SignedContextV1[] memory signedContexts) internal pure returns (bytes32 hashed) {
        uint256 cursor;
        uint256 end;
        bytes32 hashNil = HASH_NIL;
        assembly ("memory-safe") {
            cursor := add(signedContexts, 0x20)
            end := add(cursor, mul(mload(signedContexts), 0x20))
            mstore(0, hashNil)
        }

        SignedContextV1 memory signedContext;
        bytes32 mem0;
        while (cursor < end) {
            assembly ("memory-safe") {
                signedContext := mload(cursor)
                // Subhash will write to 0 for its own hashing so keep a copy
                // before it gets overwritten.
                mem0 := mload(0)
            }
            bytes32 subHash = hash(signedContext);
            assembly ("memory-safe") {
                mstore(0, mem0)
                mstore(0x20, subHash)
                mstore(0, keccak256(0, 0x40))
                cursor := add(cursor, 0x20)
            }
        }
        assembly ("memory-safe") {
            hashed := mload(0)
        }
    }

    /// Builds a standard 2-dimensional context array from base, calling and
    /// signed contexts. Note that "columns" of a context array refer to each
    /// `uint256[]` and each item within a `uint256[]` is a "row".
    ///
    /// @param baseContext Anything the calling contract can provide which MAY
    /// include input from the `msg.sender` of the calling contract. The default
    /// base context from `LibContext.base()` DOES NOT need to be provided by the
    /// caller, this matrix MAY be empty and will be simply merged into the final
    /// context. The base context matrix MUST contain a consistent number of
    /// columns from the calling contract so that the expression can always
    /// predict how many unsigned columns there will be when it runs.
    /// @param signedContexts Signed contexts are provided by the `msg.sender`
    /// but signed by a third party. The expression (author) defines _who_ may
    /// sign and the calling contract authenticates the signature over the
    /// signed data. Technically `build` handles all the authentication inline
    /// for the calling contract so if some context builds it can be treated as
    /// authentic. The builder WILL REVERT if any of the signatures are invalid.
    /// Note two things about the structure of the final built context re: signed
    /// contexts:
    /// - The first column is a list of the signers in order of what they signed
    /// - The `msg.sender` can provide an arbitrary number of signed contexts so
    ///   expressions DO NOT know exactly how many columns there are.
    /// The expression is responsible for defining e.g. a domain separator in a
    /// position that would force signed context to be provided in the "correct"
    /// order, rather than relying on the `msg.sender` to honestly present data
    /// in any particular structure/order.
    function build(uint256[][] memory baseContext, SignedContextV1[] memory signedContexts)
        internal
        view
        returns (uint256[][] memory)
    {
        unchecked {
            uint256[] memory signers = new uint256[](signedContexts.length);

            // - LibContext.base() + whatever we are provided.
            // - signed contexts + signers if they exist else nothing.
            uint256 contextLength = 1 + baseContext.length + (signedContexts.length > 0 ? signedContexts.length + 1 : 0);

            uint256[][] memory context = new uint256[][](contextLength);
            uint256 offset = 0;
            context[offset] = LibContext.base();

            for (uint256 i = 0; i < baseContext.length; i++) {
                offset++;
                context[offset] = baseContext[i];
            }

            if (signedContexts.length > 0) {
                offset++;
                context[offset] = signers;

                for (uint256 i = 0; i < signedContexts.length; i++) {
                    if (
                        // Unlike `LibContext.hash` we can only hash over
                        // the context as it's impossible for a signature
                        // to sign itself.
                        // Note the use of encodePacked here over a
                        // single array, not including the length. This
                        // would be a security issue if multiple dynamic
                        // length values were hashed over together as
                        // then many possible inputs could collide with
                        // a single encoded output.
                        !SignatureChecker.isValidSignatureNow(
                            signedContexts[i].signer,
                            ECDSA.toEthSignedMessageHash(LibHashNoAlloc.hashWords(signedContexts[i].context)),
                            signedContexts[i].signature
                        )
                    ) {
                        revert InvalidSignature(i);
                    }

                    signers[i] = uint256(uint160(signedContexts[i].signer));
                    offset++;
                    context[offset] = signedContexts[i].context;
                }
            }

            return context;
        }
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

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

bytes32 constant HASH_NIL = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

/// @title LibHashNoAlloc
/// @notice When producing hashes of just about anything that isn't already bytes
/// the common suggestions look something like `keccak256(abi.encode(...))` or
/// `keccak256(abi.encodePacked(...))` with the main differentiation being
/// whether dynamic data types are being hashed. If they are then there is a hash
/// collision risk in the packed case as `"abc" + "def"` and `"ab" + "cdef"` will
/// pack and therefore hash to the same values, the suggested fix commonly being
/// to use abi.encode, which includes the lengths disambiguating dynamic data.
/// Something like `3"abc" + 3"def"` with the length prefixes won't collide with
/// `2"ab" + 4"cdef"` but note that ABI provides neither a strong guarantee to
/// be collision resitant on inputs (as far as I know, it's a coincidence that
/// this works), nor an efficient solution.
///
/// - Abi encoding is a complex algorithm that is easily 1k+ gas for simple
///   structs with just one or two dynamic typed fields.
/// - Abi encoding requires allocating and copying all the data plus a header to
///   a new region of memory, which gives it non-linearly increasing costs due to
///   memory expansion.
/// - Abi encoding can't easily be reproduced offchain without specialised tools,
///   it's not simply a matter of length prefixing some byte string and hashing
///   with keccak256, the heads and tails all need to be produced recursively
///   https://docs.soliditylang.org/en/develop/abi-spec.html#formal-specification-of-the-encoding
///
/// Consider that `hash(hash("abc") + hash("def"))` won't collide with
/// `hash(hash("ab") + hash("cdef"))`. It should be easier to convince ourselves
/// this is true for all possible pairs of byte strings than it is to convince
/// ourselves that the ABI serialization is never ambigious. Inductively we can
/// scale this to all possible data structures that are ordered compositions of
/// byte strings. Even better, the native behaviour of `keccak256` in the EVM
/// requires no additional allocation of memory. Worst case scenario is that we
/// want to hash several hashes together like `hash(hash0, hash1, ...)`, in which
/// case we can write the words after the free memory pointer, hash them, but
/// leave the pointer. This way we pay for memory expansion but can re-use that
/// region of memory for subsequent logic, which may effectively make the
/// expansion free as we would have needed to pay for it anyway. Given that hash
/// checks often occur early in real world logic due to
/// checks-effects-interactions, this is not an unreasonable assumption to call
/// this kind of expansion "no alloc".
///
/// One problem is that the gas saving for trivial abi encoding,
/// e.g. ~1-3 uint256 values, can be lost by the overhead of jumps and stack
/// manipulation due to function calls.
///
/// ```
/// struct Foo {
///   uint256 a;
///   address b;
///   uint32 c;
/// }
/// ```
/// The simplest way to hash `Foo` is to just hash it (crazy, i know!).
///
/// ```
/// assembly ("memory-safe") {
///   hash_ := keccak256(foo_, 0x60)
/// }
/// ```
/// Every struct field is 0x20 bytes in memory so 3 fields = 0x60 bytes to hash
/// always, with the exception of dynamic types. This costs about 70 gas vs.
/// about 350 gas for an abi encoding based approach.
library LibHashNoAlloc {
    function hashBytes(bytes memory data_) internal pure returns (bytes32 hash_) {
        assembly ("memory-safe") {
            hash_ := keccak256(add(data_, 0x20), mload(data_))
        }
    }

    function hashWords(bytes32[] memory words_) internal pure returns (bytes32 hash_) {
        assembly ("memory-safe") {
            hash_ := keccak256(add(words_, 0x20), mul(mload(words_), 0x20))
        }
    }

    function hashWords(uint256[] memory words_) internal pure returns (bytes32 hash_) {
        assembly ("memory-safe") {
            hash_ := keccak256(add(words_, 0x20), mul(mload(words_), 0x20))
        }
    }

    function combineHashes(bytes32 a_, bytes32 b_) internal pure returns (bytes32 hash_) {
        assembly ("memory-safe") {
            mstore(0, a_)
            mstore(0x20, b_)
            hash_ := keccak256(0, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        return
            (error == ECDSA.RecoverError.NoError && recovered == signer) ||
            isValidERC1271SignatureNow(signer, hash, signature);
    }

    /**
     * @dev Checks if a signature is valid for a given signer and data hash. The signature is validated
     * against the signer smart contract using ERC1271.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
        InvalidSignatureV // Deprecated in v4.8
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
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {IExpressionDeployerV3} from "./IExpressionDeployerV3.sol";
import {IInterpreterStoreV2} from "./IInterpreterStoreV2.sol";
import {IInterpreterV2} from "./IInterpreterV2.sol";

/// Standard struct that can be embedded in ABIs in a consistent format for
/// tooling to read/write. MAY be useful to bundle up the data required to call
/// `IExpressionDeployerV3` but is NOT mandatory.
/// @param deployer Will deploy the expression from sources and constants.
/// @param bytecode Will be deployed to an expression address for use in
/// `Evaluable`.
/// @param constants Will be available to the expression at runtime.
struct EvaluableConfigV3 {
    IExpressionDeployerV3 deployer;
    bytes bytecode;
    uint256[] constants;
}

/// Struct over the return of `IExpressionDeployerV3.deployExpression2`
/// which MAY be more convenient to work with than raw addresses.
/// @param interpreter Will evaluate the expression.
/// @param store Will store state changes due to evaluation of the expression.
/// @param expression Will be evaluated by the interpreter.
struct EvaluableV2 {
    IInterpreterV2 interpreter;
    IInterpreterStoreV2 store;
    address expression;
}

/// Typed embodiment of some context data with associated signer and signature.
/// The signature MUST be over the packed encoded bytes of the context array,
/// i.e. the context array concatenated as bytes without the length prefix, then
/// hashed, then handled as per EIP-191 to produce a final hash to be signed.
///
/// The calling contract (likely with the help of `LibContext`) is responsible
/// for ensuring the authenticity of the signature, but not authorizing _who_ can
/// sign. IN ADDITION to authorisation of the signer to known-good entities the
/// expression is also responsible for:
///
/// - Enforcing the context is the expected data (e.g. with a domain separator)
/// - Tracking and enforcing nonces if signed contexts are only usable one time
/// - Tracking and enforcing uniqueness of signed data if relevant
/// - Checking and enforcing expiry times if present and relevant in the context
/// - Many other potential constraints that expressions may want to enforce
///
/// EIP-1271 smart contract signatures are supported in addition to EOA
/// signatures via. the Open Zeppelin `SignatureChecker` library, which is
/// wrapped by `LibContext.build`. As smart contract signatures are checked
/// onchain they CAN BE REVOKED AT ANY MOMENT as the smart contract can simply
/// return `false` when it previously returned `true`.
///
/// @param signer The account that produced the signature for `context`. The
/// calling contract MUST authenticate that the signer produced the signature.
/// @param context The signed data in a format that can be merged into a
/// 2-dimensional context matrix as-is.
/// @param signature The cryptographic signature for `context`. The calling
/// contract MUST authenticate that the signature is valid for the `signer` and
/// `context`.
struct SignedContextV1 {
    // The ordering of these fields is important and used in assembly offset
    // calculations and hashing.
    address signer;
    uint256[] context;
    bytes signature;
}

uint256 constant SIGNED_CONTEXT_SIGNER_OFFSET = 0;
uint256 constant SIGNED_CONTEXT_CONTEXT_OFFSET = 0x20;
uint256 constant SIGNED_CONTEXT_SIGNATURE_OFFSET = 0x40;

/// @title IInterpreterCallerV2
/// @notice A contract that calls an `IInterpreterV1` via. `eval`. There are near
/// zero requirements on a caller other than:
///
/// - Emit some meta about itself upon construction so humans know what the
///   contract does
/// - Provide the context, which can be built in a standard way by `LibContext`
/// - Handle the stack array returned from `eval`
/// - OPTIONALLY emit the `Context` event
/// - OPTIONALLY set state on the `IInterpreterStoreV1` returned from eval.
interface IInterpreterCallerV2 {
    /// Calling contracts SHOULD emit `Context` before calling `eval` if they
    /// are able. Notably `eval` MAY be called within a static call which means
    /// that events cannot be emitted, in which case this does not apply. It MAY
    /// NOT be useful to emit this multiple times for several eval calls if they
    /// all share a common context, in which case a single emit is sufficient.
    /// @param sender `msg.sender` building the context.
    /// @param context The context that was built.
    event Context(address sender, uint256[][] context);
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

/// Thrown if a truncated length is longer than the array being truncated. It is
/// not possible to truncate something and increase its length as the memory
/// region after the array MAY be allocated for something else already.
error OutOfBoundsTruncate(uint256 arrayLength, uint256 truncatedLength);

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

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