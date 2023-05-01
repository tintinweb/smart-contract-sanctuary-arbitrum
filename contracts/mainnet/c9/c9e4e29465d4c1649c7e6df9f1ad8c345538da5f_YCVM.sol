// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./types.sol";
import "./Interpreters.sol";

contract YCVM is YieldchainTypes, Interpreters {
    // ================
    //    FUNCTIONS
    // ================
    /**
     * @notice
     * The main high-level function used to run encoded FunctionCall's, which are stored on the YCStep's.
     * It uses other internal functions to interpret it and it's arguments, build the calldata & call it accordingly.
     * @param encodedFunctionCall - The encoded FunctionCall struct
     * @return returnVal returned by the low-level function calls
     */
    function _runFunction(
        bytes memory encodedFunctionCall
    ) public returns (bytes memory returnVal) {
        /**
         * Seperate the FunctionCall command body from the typeflags
         */
        (bytes memory commandBody, bytes1 typeflag, ) = _separateCommand(
            encodedFunctionCall
        );

        /**
         * Assert that the typeflag must be either 0x04, 0x05, or 0x06 (The function call flags)
         */
        require(
            typeflag < 0x07 && typeflag > 0x03,
            "ycVM: Invalid Function Typeflag"
        );

        /**
         * Decode the FunctionCall command
         */
        FunctionCall memory decodedFunctionCall = abi.decode(
            commandBody,
            (FunctionCall)
        );

        /**
         * Execute it & assign to the return value
         */
        returnVal = _execFunctionCall(decodedFunctionCall, typeflag);
    }

    /**
     * _execFunctionCall()
     * Accepts a decoded FunctionCall struct, and a typeflag. Builds the calldata,
     * calls the function on the target address, and returns the return value.
     * @param func - The FunctionCall struct which represents the call to make
     * @param typeflag - The typeflag specifying the type of call STATICCALL, CALL, OR DELEGATECALL
     * @return returnVal - The return value of the function call
     */
    function _execFunctionCall(
        FunctionCall memory func,
        bytes1 typeflag
    ) public returns (bytes memory returnVal) {
        /**
         * First, build the calldata for the function & it's args
         */
        bytes memory callData = _buildCalldata(func);

        /**
         * Switch case for the function call type
         */

        // STATICALL
        if (typeflag == STATICCALL_COMMAND_FLAG) {
            (, returnVal) = func.target_address.staticcall(callData);
            return returnVal;
        }
        // CALL
        if (typeflag == CALL_COMMAND_FLAG) {
            (, returnVal) = func.target_address.call(callData);
            return returnVal;
        }
        // DELEGATECALL
        if (typeflag == DELEGATECALL_COMMAND_FLAG) {
            (, returnVal) = func.target_address.delegatecall(callData);
            return returnVal;
        }
    }

    /**
     * _buildCalldata()
     * Builds a complete calldata from a FunctionCall struct
     * @param _func - The FunctionCall struct which represents the function we shall construct a calldata for
     * @return constructedCalldata - A complete constructed calldata which can be used to make the desired call
     */
    function _buildCalldata(
        FunctionCall memory _func
    ) public returns (bytes memory constructedCalldata) {
        /**
         * Get the 4 bytes keccak256 hash selector of the signature (used at the end to concat w the calldata body)
         */
        bytes4 selector = bytes4(keccak256(bytes(_func.signature)));

        /**
         * @notice
         * We call the interpretCommandsAndEncodeChunck() function with the function's array of arguments
         * (which are YC commands), which will:
         *
         * 1) Interpret each argument using the _separateAndGetCommandValue() function
         * 2) Encode all of them as an ABI-compatible chunck, which can be used as the calldata
         *
         * And assign to the constructed calldata the concatinated selector + encoded chunck we recieve
         */
        constructedCalldata = bytes.concat(
            selector,
            interpretCommandsAndEncodeChunck(_func.args)
        );
    }

    /**
     * _separateAndGetCommandValue()
     * Separate & get a command/argument's actual value, by parsing it, and potentially
     * using it's return value (if a function call)
     * @param command - the full encoded command, including typeflags
     * @return interpretedValue - The interpreted underlying value of the argument
     * @return typeflag - The typeflag of the underlying value
     */
    function _separateAndGetCommandValue(
        bytes memory command
    ) public returns (bytes memory interpretedValue, bytes1 typeflag) {
        // First, seperate the command/variable from it's typeflag & return var typeflag
        bytes1 retTypeFlag;
        (interpretedValue, typeflag, retTypeFlag) = _separateCommand(command);

        /**
         * Then, check to see if it's either one of the CALL typeflags, to determine
         * whether it's a function call or not
         */
        if (typeflag >= STATICCALL_COMMAND_FLAG) {
            /*
             * If it is, it means the body is an encoded FunctionCall struct.
             * We call the internal _execFunction() function with our command body & typeflag,
             * in order to execute this function and retreive it's return value - And then use the
             * usual _getCommandValue() function to parse it's primitive value, with the return typeflag.
             * We also assign to the typeflag the command's returnTypeFlag that we got when separating.
             */
            // Decode it first
            FunctionCall memory functionCallCommand = abi.decode(
                interpretedValue,
                (FunctionCall)
            );

            /**
             * To the interpretedValue variable, assign the interpreted result
             * of the return value of the function call. And to the typeflag, assign
             * the returned typeflag (which should be the typeflag of the underlying return value)
             * Note that, to avoid any doubts -
             * The underlying typeflag in this case should always just be the return type flag of the function call,
             * that we input into the function. It's just the uniform API of the function that makes it more efficient
             * to receive it from this call anyway.
             *
             * The additional interpretation is done in order to comply the primitive underlying return value
             * with the rest of the system (i.e chunck/calldata encoder). For example, if the function returns
             * a ref variable - We need to remove it's initial 32-byte offset pointer in order for it to
             * be compliant with the calldata builder.
             */

            return (
                _getCommandValue(
                    _execFunctionCall(functionCallCommand, typeflag),
                    retTypeFlag,
                    retTypeFlag
                )
            );
        }

        /**
         * At this point, if it's not a FunctionCall - It is another command type.
         *
         * We call the _getCommandValue() function with our command body & typeflag,
         * which will interpret it and return the underlying value, along with the underlying typeflag.
         */
        (interpretedValue, typeflag) = _getCommandValue(
            interpretedValue,
            typeflag,
            retTypeFlag
        );
    }

    /**
     * @notice
     * _getCommandValue
     * Accepts a primitive value, a typeflag - and interprets it
     * @param commandVariable - A command variable without the typeflags
     * @param typeFlag - The typeflag
     */

    function _getCommandValue(
        bytes memory commandVariable,
        bytes1 typeflag,
        bytes1 retTypeflag
    ) public returns (bytes memory parsedPrimitiveValue, bytes1 typeFlag) {
        /**
         * We initially set parsed primitive value and typeFlag to the provided ones
         */
        parsedPrimitiveValue = commandVariable;
        typeFlag = typeflag;

        /**
         * If the typeflag is 0x00, it's a value variable and we just return it (simplest case)
         */
        if (typeflag == VALUE_VAR_FLAG) return (parsedPrimitiveValue, typeflag);

        /**
         * If the typeflag is 0x01, it's a ref variable (string, array...), we parse and return it
         */
        if (typeflag == REF_VAR_FLAG) {
            parsedPrimitiveValue = _parseDynamicVar(parsedPrimitiveValue);
            return (parsedPrimitiveValue, typeflag);
        }

        /**
         * If the typeflag equals to the commands array flag, we call the interpretCommandsArray() function,
         * which will iterate over each item, parse it, and in addition, have some more utility parsings
         * depending on it's typeflag (e.g appending/not appending additional length argument, etc).
         *
         * We also return the return typeflag as the typeflag here.
         */
        if (
            typeflag == COMMANDS_LIST_FLAG || typeflag == COMMANDS_REF_ARR_FLAG
        ) {
            return (
                interpretCommandsArr(parsedPrimitiveValue, typeflag),
                retTypeflag
            );
        }
    }

    /**
     * @notice
     * interpretCommandsAndEncodeChunck
     * Accepts an array of YC commands - interprets each one of them, then encodes an ABI-compatible chunck of bytes,
     * corresponding of all of these arguments (account for value & ref variables)
     * @param ycCommands - an array of yc commands to interpret
     * @return interpretedEncodedChunck - A chunck of bytes which is an ABI-compatible encoded version
     * of all of the interpreted commands
     */
    function interpretCommandsAndEncodeChunck(
        bytes[] memory ycCommands
    ) public returns (bytes memory interpretedEncodedChunck) {
        /**
         * We begin by getting the amount of all ref variables,
         * in order to instantiate the array.
         *
         * Note that we are looking at the RETURN typeflag of the command at idx 1,
         * and we're doing it since a command may be flagged as some certain type in order to be parsed correctly,
         * but the end result, the underlaying value we will be getting from the parsing iteration is different.
         * For example, dynamic-length commands arrays (dynamic-length arrays which are made up of YC commands)
         * are flagged as 0x03 in order to be parsed in a certain way, yet at the end we're supposed to get a
         * reguler dynamic flag from the parsing (Since that is what the end contract expects,
         * a dynamic-length argument which is some array).
         * This means that for a ref variable to be flagged correctly, it's return type need to be flagged
         * also as REF_VAR_FLAG (0x01)
         */
        uint256 refVarsAmt = 0;
        for (uint256 i = 0; i < ycCommands.length; i++) {
            if (ycCommands[i][1] == REF_VAR_FLAG) ++refVarsAmt;
        }

        /**
         * Will save the ref variables' body values/data here
         */
        bytes[] memory refVars = new bytes[](refVarsAmt);

        /**
         * The indexes of the ref variables' offset pointers
         */
        uint256[] memory refVarsIndexes = new uint256[](refVarsAmt);

        /**
         * Keep a uint in order to track the current free idx in the array (cannot push to mem arrays in solidity)
         */
        uint256 freeRefVarIndexPtr = 0;

        /**
         * Iterate over each one of the ycCommands,
         * call the _separateAndGetCommandValue() function on them, which returns both the value and their typeflag.
         */
        for (uint256 i = 0; i < ycCommands.length; i++) {
            /**
             * Get the value of the argument and it's underlying typeflag
             */
            (
                bytes memory argumentValue,
                bytes1 typeflag
            ) = _separateAndGetCommandValue(ycCommands[i]);

            /**
             * Assert that the typeflag must either be a value or a ref variable.
             * At this point, the argument should have been interpreted/parsed up until the point where
             * it's either a ref or a value variable.
             */
            require(typeflag < 0x02, "typeflag must < 2 after parsing");

            /**
             * If it's a value variable, we simply concat the existing chunck with it
             */
            if (typeflag == VALUE_VAR_FLAG)
                interpretedEncodedChunck = bytes.concat(
                    interpretedEncodedChunck,
                    argumentValue
                );

                /**
                 * Otherwise, we process it as a ref variable
                 */
            else {
                /**
                 * We save the current chunck length as the index of the 32 byte pointer of this ref variable,
                 * in our array of refVarIndexes
                 */
                refVarsIndexes[freeRefVarIndexPtr] = interpretedEncodedChunck
                    .length;

                /**
                 * We then append an empty 32 byte placeholder at that index on the chunck
                 * ("mocking" what would have been the offset pointer)
                 */
                interpretedEncodedChunck = bytes.concat(
                    interpretedEncodedChunck,
                    new bytes(32)
                );

                /**
                 * We then, at the same index as we saved the chunck pointer's index,
                 * save the parsed value of the ref argument (it was parsed to be just the length + data
                 * by the getCommandValue() function, it does not include the default prepended offset pointer now).
                 */
                refVars[freeRefVarIndexPtr] = argumentValue;

                // Increment the free index pointer of the dynamic variables
                ++freeRefVarIndexPtr;
            }
        }

        /**
         * @notice,
         * at this point we have iterated over each command.
         * The value arguments were concatinated with our chunck,
         * whilst the ref variables have been replaced with an empty 32 byte placeholder at their index,
         * their values & the indexes of their empty placeholders were saved into our arrays.
         *
         * We now perform an additional iteration over these arrays, where we append the
         * ref variables to the end of the encoded chunck, save that new index of where we appended it,
         * go back to the index of the corresponding empty placeholder, and replace it with a pointer to our new index.
         *
         * the EVM, when accepting this chunck as calldata, will expect this memory pointer at the index, which, points
         * to where our variable is located in terms of offset since the beginning of the chunck
         */
        for (uint256 i = 0; i < refVars.length; i++) {
            // Shorthand for the index of our placeholder pointer
            uint256 index = refVarsIndexes[i];

            // The new index/pointer
            uint256 newPtr = interpretedEncodedChunck.length;

            // Go into assembly (much cheaper & more conveient to just mstore the 32 byte word)
            assembly {
                mstore(add(add(interpretedEncodedChunck, 0x20), index), newPtr)
            }

            /**
             * Finally, concat the existing chunck with our ref variable's data
             * (At what would now be stored in the original index as the offset pointer)
             */
            interpretedEncodedChunck = bytes.concat(
                interpretedEncodedChunck,
                refVars[i]
            );
        }
    }

    /**
     * interpretCommandsArr
     * @param ycCommandsArr - An encoded dynamic-length array of YC commands
     * @param typeflag - The typeflag of the array command. This may be COMMANDS_LIST or COMMANDS_REF_ARR,
     * which we act differently upon
     * @return interpretedArray - The interpreted command as a chunck,
     * which should directly be inputted into external calldata.
     */
    function interpretCommandsArr(
        bytes memory ycCommandsArr,
        bytes1 typeflag
    ) public returns (bytes memory interpretedArray) {
        /**
         * We begin by decoding the encoded array into a bytes[]
         */
        bytes[] memory decodedCommandsArray = abi.decode(
            ycCommandsArr,
            (bytes[])
        );

        /**
         * We then call the interpretCommandsAndEncodeChunck() function with our array of YC commands,
         * which will interpret each command, and encode it into a single chunck.
         */
        interpretedArray = interpretCommandsAndEncodeChunck(
            decodedCommandsArray
        );

        /**
         * @notice
         * We check to see our provided typeflag,
         * which is supposed to be the typeflag of this command (the array of commands as a whole).
         *
         * If the typeflag is a COMMANDS_REF_ARR_FLAG,
         * this means we need to concat the length of the array to the chunck (because it's a dynamic-length array).
         * Otherwise, it is either a fixed-length array, or a struct. In which case, we do not append any length.
         *
         * Do note that, in neither cases, we append an offset pointer. The calldata builder expects
         * a "naked" value ((optional length) + data), and manages the offset pointers itself.
         */
        if (typeflag == COMMANDS_REF_ARR_FLAG) {
            interpretedArray = bytes.concat(
                abi.encode(decodedCommandsArray.length),
                interpretedArray
            );
        }
    }
}