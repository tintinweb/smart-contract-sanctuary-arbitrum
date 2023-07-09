/**
 * Facet for verifying LI.FI related offchain commands
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "src/Types.sol";

contract LIFIValidator {
    struct SwapData {
        address callTo;
        address approveTo;
        address sendingAssetId;
        address receivingAssetId;
        uint256 fromAmount;
        bytes callData;
        bool requiresDeposit;
    }

    // For now simply verify receiver is correct (The msg.sender - i.e the vault)
    function validateLifiswapCalldata(
        OffchainCommandValidation calldata validationData
    ) external view returns (bool isValid) {
        {
            address receiver = extractReceiver(validationData);
            if (receiver == msg.sender) isValid = true;
        }
    }

    function extractReceiver(
        OffchainCommandValidation memory validationData
    ) internal pure returns (address receiver) {
        (, , , receiver) = abi.decode(
            validationData.interpretedArgs,
            (bytes32, string, string, address)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// =================
//     ENUMS
// =================
/**
 * Different types of executionable requests. In order to avoid over
 * flexability of the executors, so that they are not able to input completely arbitrary steps data
 */
enum ExecutionTypes {
    SEED,
    TREE,
    UPROOT
}

/**
 * An enum representing all different types of "triggers" that
 * a strategy can register
 */
enum TriggerTypes {
    AUTOMATION
}

//===============================================//
//                   STRUCTS                     //
//===============================================//
/**
 * Struct representing a registered trigger,
 * including the trigger type, and an arbitrary byte which is it's settings
 */
struct Trigger {
    TriggerTypes triggerType;
    bytes extraData;
}
/**
 * @notice
 * @FunctionCall
 * A struct that defines a function call. Is used as a standard to pass on steps' functions, or
 * functions to be used to retreive some return value, as some sort of a dynamic variable that can be
 * pre-encoded & standardized.
 *
 *
 * ----- // @PARAMETERS // -----
 * @param target_address
 * @address -  The target address the function should be called on.
 *
 * @param args
 * @bytes[] - The arguments for the function call, encoded. Should be wrapped inside getArgValue()
 *
 * @param signature
 * @string - The function sig. Can be either external (When function is a dynamic variable),
 * or a YC Classified function (e.g "func_30(bytes[])")
 *
 * @param is_callback
 * @bool - Specifies whether the function is a callback. Callback means it submits an off-chain request, which
 * should stop the current execution context - Which, in turn, may have itself/another process resumed by the request's
 * fullfill operation.
 *
 * @param is_static
 * @bool - Specifies whether the function can be called with staticcall. If true, can save significant (9000) gas.
 *
 * -----------------------------
 */
struct FunctionCall {
    address target_address;
    bytes[] args; // [FunctionCall("getAmount()", args[0xETHTOKEN, ])]
    string signature; // "addLiquidity(uint256,uint256)"
}

/**
 * @notice
 * @YCStep
 * A struct defining a Yieldchain strategy step. Is used to standardized a classification of each one of a strategy's
 * steps. Defining it's function call, as well as it's underlying protocol's details, and it's tokens flows.
 * While this will be used in the strategy's logic (The function calls), it can also be consumed by frontends
 * (which have access to our ABI).
 * ----- // @PARAMETERS // -----
 * @param step_function
 * @FunctionCall, encoded
 * The function to call on this step.
 *
 * @param protocol_details
 * @ProtocolDetails
 * The details of the protocol the function reaches. Consumed by frontends.
 *
 * @param token_flows
 * @TokenFlow[]
 * An array of TokenFlow structs, consumed by frontends.
 *
 * @param childrenIndices
 * @uint256
 * A uint representing the index within the strategy's containers array of the step's children container.
 *
 * @param mvc
 * @bytes
 * Either an encoded function call or an MVC (Minimal Verifable Calldata) we can match against,
 * only relevent if the step is a callback.
 * -----------------------------
 */
struct YCStep {
    bytes func;
    uint256[] childrenIndices;
    bytes[] conditions;
    bool isCallback;
    bytes mvc;
}

/**
 * @notice
 * A struct representing an operation request item.
 * Action requests (deposits, withdrawals, strategy runs) are not processed immediately, but rather hydrated
 * by an offchain handler, then executed. This is in order to process any offchain computation that may be required beforehand,
 * to avoid any stops mid-run (which can overcomplicate the entire architecutre)
 *
 * @param action - An ExecutionType enum representing the action to complete, handled by a switch case in the router
 * @param initiator - The user address that initiated this queue request
 * @param commandCalldatas - An array specifying hydrated calldatas. If a step is an offchain step, the hydrated calldata would be stored
 * here in the index of it within it's own virtual tree (for instance, a step at index 9 of SEED_STEPS tree, would have it's
 * YC command stored at index 9 here in the commandCalldatas)
 * @param arguments - An arbitrary array of bytes being the arguments, usually would be something like an amount.
 */
struct OperationItem {
    ExecutionTypes action;
    address initiator;
    uint256 gas;
    bytes[] arguments;
    bytes[] commandCalldatas;
    bool executed;
}

struct OffchainActionRequest {
    address initiator;
    uint256 chainId;
    uint256 stepIndex;
    bytes[] cachedOffchainCommands;
    address callTargetAddress;
    string signature;
    bytes args;
}

struct OffchainCommandValidation {
    address targetAddr;
    string sig;
    bytes interpretedArgs;
    FunctionCall originalCommand;
}