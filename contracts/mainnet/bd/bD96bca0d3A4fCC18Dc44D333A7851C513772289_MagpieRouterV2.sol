// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Ownable2Step} from "openzeppelin-solidity/contracts/access/Ownable2Step.sol";
import {Pausable} from "openzeppelin-solidity/contracts/security/Pausable.sol";
import {Multicall} from "openzeppelin-solidity/contracts/utils/Multicall.sol";
import {IMagpieRouterV2} from "./interfaces/IMagpieRouterV2.sol";
import {LibAsset} from "./libraries/LibAsset.sol";
import {AppStorage, LibMagpieRouterV2} from "./libraries/LibMagpieRouterV2.sol";
import {LibSwap, SwapData} from "./libraries/LibSwap.sol";
import {LibCommand, CommandAction, CommandData} from "./router/LibCommand.sol";
import {LibUniswapV3} from "./router/LibUniswapV3.sol";

error ExpiredTransaction();
error InsufficientAmountOut();
error InvalidCall();
error InvalidCommand();
error InvalidTransferFromCall();

contract MagpieRouterV2 is IMagpieRouterV2, Ownable2Step, Multicall, Pausable {
    using LibAsset for address;

    /// @dev See {IMagpieRouterV2-router}
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev See {IMagpieRouterV2-unpause}
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev See {IMagpieRouterV2-updateSelector}
    function updateSelector(uint16 commandType, bytes4 selector) external onlyOwner {
        AppStorage storage s = LibMagpieRouterV2.getStorage();

        s.selectors[commandType] = selector;
    }

    /// @dev See {IMagpieRouterV2-getSelector}
    function getSelector(uint16 commandType) external view returns (bytes4) {
        AppStorage storage s = LibMagpieRouterV2.getStorage();

        return s.selectors[commandType];
    }

    /// @dev Enforces time constraints on certain operations within a smart contract.
    /// @param deadline The timestamp in epochs beyond which the transaction will get expired.
    function enforceDeadline(uint256 deadline) private view {
        if (deadline < block.timestamp) {
            revert ExpiredTransaction();
        }
    }

    /// @dev Handle uniswapV3SwapCallback requests from any protocol that is based on UniswapV3. We dont check for factory since this contract is not supposed to store tokens. We protect the user by handling amountOutMin check at the end of execution by comparing starting and final balance at the destination address.
    fallback() external {
        int256 amount0Delta;
        int256 amount1Delta;
        address assetIn;
        uint256 callDataSize;
        assembly {
            amount0Delta := calldataload(4)
            amount1Delta := calldataload(36)
            assetIn := shr(96, calldataload(132))
            callDataSize := calldatasize()
        }

        if (callDataSize != 164) {
            revert InvalidCall();
        }

        LibUniswapV3.uniswapV3SwapCallback(amount0Delta, amount1Delta, assetIn);
    }

    /// @dev Determinines whether a specific command action within a swap sequence involves moving tokens.
    function isTokenMovement(CommandAction commandAction) private pure returns (bool) {
        return
            commandAction == CommandAction.Approval ||
            commandAction == CommandAction.TransferFrom ||
            commandAction == CommandAction.Transfer ||
            commandAction == CommandAction.Wrap ||
            commandAction == CommandAction.Unwrap;
    }

    /// @dev See {IMagpieRouterV2-estimateSwapGas}
    function estimateSwapGas(bytes calldata) external payable returns (uint256 amountOut, uint256 gasUsed) {
        (amountOut, gasUsed) = execute(true);
    }

    /// @dev See {IMagpieRouterV2-swap}
    function swap(bytes calldata) external payable whenNotPaused returns (uint256 amountOut) {
        (amountOut, ) = execute(true);
    }

    /// @dev See {IMagpieRouterV2-silentSwap}
    function silentSwap(bytes calldata) external payable whenNotPaused returns (uint256 amountOut) {
        (amountOut, ) = execute(false);
    }

    /// @dev Handles the execution of a sequence of commands for the swap operation.
    /// @param triggerEvent An indicator if the function needs to trigger the swap event.
    /// @return amountOut The amount received after swapping.
    /// @return gasUsed The gas utilised during swapping.
    function execute(bool triggerEvent) private returns (uint256 amountOut, uint256 gasUsed) {
        SwapData memory swapData = LibSwap.getData(LibSwap.SWAP_ARGS_OFFSET);

        enforceDeadline(swapData.deadline);

        amountOut = swapData.toAssetAddress.getBalanceOf(swapData.toAddress);

        bytes memory commandOutput = new bytes(swapData.outputsLength);
        uint16 i;
        CommandData memory commandData;
        uint256 nativeAmount;
        uint256 tmpAmount;
        bytes memory input;

        uint256 commandOutputOffset;
        assembly {
            commandOutputOffset := add(commandOutput, 32)
        }

        for (i = swapData.commandsOffset; i < swapData.commandsOffsetEnd; ) {
            commandData = LibCommand.getData(i);

            (nativeAmount, input) = LibCommand.getInput(commandOutput, commandData);

            if (commandData.commandAction == CommandAction.Call) {
                bytes4 selector;

                assembly {
                    selector := mload(add(input, 32))
                }

                if (selector == 0x23b872dd || selector == 0) {
                    // Blacklist transferFrom in custom calls
                    revert InvalidTransferFromCall();
                }

                assembly {
                    let outputLength := mload(add(commandData, 64))
                    if iszero(
                        call(
                            gas(),
                            mload(add(commandData, 160)),
                            nativeAmount,
                            add(input, 32),
                            mload(input),
                            commandOutputOffset,
                            outputLength
                        )
                    ) {
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                    commandOutputOffset := add(commandOutputOffset, outputLength)
                }
            } else if (commandData.commandAction == CommandAction.Approval) {
                LibCommand.approve(input);
            } else if (commandData.commandAction == CommandAction.TransferFrom) {
                LibCommand.transferFrom(input);
            } else if (commandData.commandAction == CommandAction.Transfer) {
                LibCommand.transfer(input);
            } else if (commandData.commandAction == CommandAction.Wrap) {
                LibCommand.wrap(input);
            } else if (commandData.commandAction == CommandAction.Unwrap) {
                LibCommand.unwrap(input);
            } else if (commandData.commandAction == CommandAction.Balance) {
                tmpAmount = LibCommand.balance(input);
                assembly {
                    mstore(commandOutputOffset, tmpAmount)
                    commandOutputOffset := add(commandOutputOffset, 32)
                }
            } else if (commandData.commandAction == CommandAction.Math) {
                tmpAmount = LibCommand.math(input);
                assembly {
                    mstore(commandOutputOffset, tmpAmount)
                    commandOutputOffset := add(commandOutputOffset, 32)
                }
            } else if (commandData.commandAction == CommandAction.Comparison) {
                tmpAmount = LibCommand.comparison(input);
                assembly {
                    mstore(commandOutputOffset, tmpAmount)
                    commandOutputOffset := add(commandOutputOffset, 32)
                }
            } else if (commandData.commandAction == CommandAction.EstimateGasStart) {
                gasUsed = gasleft();
            } else if (commandData.commandAction == CommandAction.EstimateGasEnd) {
                gasUsed -= gasleft();
            } else {
                revert InvalidCommand();
            }

            assembly {
                if gt(commandOutputOffset, add(add(commandOutput, 32), mload(commandOutput))) {
                    revert(0, 0)
                }
            }

            unchecked {
                i += 11;
            }
        }

        amountOut = swapData.toAssetAddress.getBalanceOf(swapData.toAddress) - amountOut;

        if (amountOut < swapData.amountOutMin) {
            revert InsufficientAmountOut();
        }

        if (triggerEvent) {
            emit Swap(
                msg.sender,
                swapData.toAddress,
                swapData.fromAssetAddress,
                swapData.toAssetAddress,
                swapData.amountIn,
                amountOut
            );
        }
    }

    /// @dev Used to receive ethers
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IMagpieRouterV2 {
    /// @dev Allows the owner to pause the contract.
    function pause() external;

    /// @dev Allows the owner to unpause the contract.
    function unpause() external;

    /// @dev Allows the owner to update the mapping of command types to function selectors.
    /// @param commandType Identifier for each command. We have one selector / command.
    /// @param selector The function selector for each of these commands.
    function updateSelector(uint16 commandType, bytes4 selector) external;

    /// @dev Gets the selector at the specific commandType.
    /// @param commandType Identifier for each command. We have one selector / command.
    /// @return selector The function selector for the specified command.
    function getSelector(uint16 commandType) external view returns (bytes4);

    event Swap(
        address indexed fromAddress,
        address indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @dev Provides an external interface to estimate the gas cost of the last hop in a route.
    /// @return amountOut The amount received after swapping.
    /// @return gasUsed The cost of gas while performing the swap.
    function estimateSwapGas(bytes calldata swapArgs) external payable returns (uint256 amountOut, uint256 gasUsed);

    /// @dev Performs token swap.
    /// @return amountOut The amount received after swapping.
    function swap(bytes calldata swapArgs) external payable returns (uint256 amountOut);

    /// @dev Performs token swap without triggering event.
    /// @return amountOut The amount received after swapping.
    function silentSwap(bytes calldata swapArgs) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWETH.sol";

error AssetNotReceived();
error ApprovalFailed();
error TransferFromFailed();
error TransferFailed();

library LibAsset {
    using LibAsset for address;

    address constant NATIVE_ASSETID = address(0);

    /// @dev Checks if the given address (self) represents a native asset (Ether).
    /// @param self The asset that will be checked for a native token.
    /// @return Flag to identify if the asset is native or not.
    function isNative(address self) internal pure returns (bool) {
        return self == NATIVE_ASSETID;
    }

    /// @dev Retrieves the balance of the current contract for a given asset (self).
    /// @param self Asset whose balance needs to be found.
    /// @return Balance of the specific asset.
    function getBalance(address self) internal view returns (uint256) {
        return self.isNative() ? address(this).balance : IERC20(self).balanceOf(address(this));
    }

    /// @dev Retrieves the balance of the target address for a given asset (self).
    /// @param self Asset whose balance needs to be found.
    /// @param targetAddress The address where the balance is checked from.
    /// @return Balance of the specific asset.
    function getBalanceOf(address self, address targetAddress) internal view returns (uint256) {
        return self.isNative() ? targetAddress.balance : IERC20(self).balanceOf(targetAddress);
    }

    /// @dev Performs a safe transferFrom operation for a given asset (self) from one address (from) to another address (to).
    /// @param self Asset that will be transferred.
    /// @param from Address that will send the asset.
    /// @param to Address that will receive the asset.
    /// @param amount Transferred amount.
    function transferFrom(address self, address from, address to, uint256 amount) internal {
        IERC20 token = IERC20(self);

        bool success = execute(self, abi.encodeWithSelector(token.transferFrom.selector, from, to, amount));

        if (!success) revert TransferFromFailed();
    }

    /// @dev Transfers a given amount of an asset (self) to a recipient address (recipient).
    /// @param self Asset that will be transferred.
    /// @param recipient Address that will receive the transferred asset.
    /// @param amount Transferred amount.
    function transfer(address self, address recipient, uint256 amount) internal {
        IERC20 token = IERC20(self);
        bool success;

        if (self.isNative()) {
            (success, ) = payable(recipient).call{value: amount}("");
        } else {
            success = execute(self, abi.encodeWithSelector(token.transfer.selector, recipient, amount));
        }

        if (!success) {
            revert TransferFailed();
        }
    }

    /// @dev Approves a spender address (spender) to spend a specified amount of an asset (self).
    /// @param self The asset that will be approved.
    /// @param spender Address of a contract that will spend the owners asset.
    /// @param amount Asset amount that can be spent.
    function approve(address self, address spender, uint256 amount) internal {
        IERC20 token = IERC20(self);

        if (!execute(self, abi.encodeWithSelector(token.approve.selector, spender, amount))) {
            if (
                !execute(self, abi.encodeWithSelector(token.approve.selector, spender, 0)) ||
                !(execute(self, abi.encodeWithSelector(token.approve.selector, spender, amount)))
            ) {
                revert ApprovalFailed();
            }
        }
    }

    /// @dev Determines if a call was successful.
    /// @param target Address of the target contract.
    /// @param success To check if the call to the contract was successful or not.
    /// @param data The data was sent while calling the target contract.
    /// @return result The success of the call.
    function isSuccessful(address target, bool success, bytes memory data) private view returns (bool result) {
        if (success) {
            if (data.length == 0) {
                // isContract
                if (target.code.length > 0) {
                    result = true;
                }
            } else {
                assembly {
                    result := mload(add(data, 32))
                }
            }
        }
    }

    /// @dev Executes a low level call.
    /// @param self The address of the contract to which the call is being made.
    /// @param params The parameters or data to be sent in the call.
    /// @return result The success of the call.
    function execute(address self, bytes memory params) private returns (bool) {
        (bool success, bytes memory data) = self.call(params);

        return isSuccessful(self, success, data);
    }

    /// @dev Deposit of a specified amount of an asset (self).
    /// @param self Address of the asset that will be deposited.
    /// @param weth Address of the Wrapped Ether (WETH) contract.
    /// @param amount Amount that needs to be deposited.
    function deposit(address self, address weth, uint256 amount) internal {
        if (self.isNative()) {
            if (msg.value < amount) {
                revert AssetNotReceived();
            }
            IWETH(weth).deposit{value: amount}();
        } else {
            self.transferFrom(msg.sender, address(this), amount);
        }
    }

    /// @dev Withdrawal of a specified amount of an asset (self) to a designated address (to).
    /// @param self The asset that will be withdrawn.
    /// @param weth Address of the Wrapped Ether (WETH) contract.
    /// @param to Address that will receive withdrawn token.
    /// @param amount Amount that needs to be withdrawn
    function withdraw(address self, address weth, address to, uint256 amount) internal {
        if (self.isNative()) {
            IWETH(weth).withdraw(amount);
        }
        self.transfer(payable(to), amount);
    }

    /// @dev Retrieves the decimal precision of an ERC20 token.
    /// @param self The asset address whose decimals we are retrieving.
    /// @return tokenDecimals The decimals of the asset.
    function getDecimals(address self) internal view returns (uint8 tokenDecimals) {
        tokenDecimals = 18;

        if (!self.isNative()) {
            (, bytes memory queriedDecimals) = self.staticcall(abi.encodeWithSignature("decimals()"));
            tokenDecimals = abi.decode(queriedDecimals, (uint8));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct AppStorage {
    mapping(uint16 => bytes4) selectors; // Mapping of command to its corresponding function selector.
}

library LibMagpieRouterV2 {
    function getStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {LibAsset} from "../libraries/LibAsset.sol";

struct SwapData {
    uint16 amountsOffset; // Represents the offset for the amounts section in the transaction calldata
    uint16 dataOffset; // Represents the offset for reusable data section in the calldata.
    uint16 commandsOffset; // Represents the starting point of the commands section in the calldata.
    uint16 commandsOffsetEnd; // Represents the end of the commands section in the calldata.
    uint16 outputsLength; // Represents the length of all of the commands
    uint256 amountIn; // Representing the amount of the asset being provided in the swap.
    address toAddress; // This is the address to which the output of the swap (the swapped asset) will be sent.
    address fromAssetAddress; // The address of the source asset being swapped from.
    address toAssetAddress; // The address of the final asset being swapped to.
    uint256 deadline; // Represents the deadline by which the swap must be completed.
    uint256 amountOutMin; // The minimum amount of the output asset that must be received for the swap to be considered successful.
}

library LibSwap {
    using LibAsset for address;

    uint16 constant SWAP_ARGS_OFFSET = 68;

    /// @dev Extracts and sums up the amounts of the source asset.
    /// @param startOffset Relative starting position.
    /// @param endOffset Ending position.
    /// @param positionOffset Absolute starting position.
    /// @return amountIn Sum of amounts.
    function getAmountIn(
        uint16 startOffset,
        uint16 endOffset,
        uint16 positionOffset
    ) internal pure returns (uint256 amountIn) {
        for (uint16 i = startOffset; i < endOffset; ) {
            uint256 currentAmountIn;
            assembly {
                let p := shr(240, calldataload(i))
                currentAmountIn := calldataload(add(p, positionOffset))
            }
            amountIn += currentAmountIn;

            unchecked {
                i += 2;
            }
        }
    }

    /// @dev Extract the first amount.
    /// @param swapArgsOffset Starting position of swapArgs in calldata.
    /// @return amountIn First amount in.
    function getFirstAmountIn(uint16 swapArgsOffset) internal pure returns (uint256 amountIn) {
        uint16 position = swapArgsOffset + 4;
        assembly {
            amountIn := calldataload(position)
        }
    }

    /// @dev Extracts SwapData from calldata.
    /// @param swapArgsOffset Starting position of swapArgs in calldata.
    /// @return swapData Essential data for the swap.
    function getData(uint16 swapArgsOffset) internal pure returns (SwapData memory swapData) {
        uint16 dataLength;
        uint16 amountsLength;
        uint16 dataOffset;
        uint16 swapArgsLength;
        assembly {
            dataLength := shr(240, calldataload(swapArgsOffset))
            amountsLength := shr(240, calldataload(add(swapArgsOffset, 2)))
            swapArgsLength := calldataload(sub(swapArgsOffset, 32))
        }
        dataOffset = swapArgsOffset + 4;
        swapData.dataOffset = dataOffset;
        swapData.amountsOffset = swapData.dataOffset + dataLength;
        swapData.commandsOffset = swapData.amountsOffset + amountsLength;
        swapData.commandsOffsetEnd = swapArgsLength + swapArgsOffset;
        // Depends on the context we have shift the position addSelector
        // By default the position is adjusted to the router's offset
        uint256 amountIn = getAmountIn(
            swapData.amountsOffset,
            swapData.commandsOffset,
            swapArgsOffset - SWAP_ARGS_OFFSET
        );

        assembly {
            mstore(add(swapData, 128), shr(240, calldataload(add(dataOffset, 32))))
            mstore(add(swapData, 160), amountIn)
            mstore(add(swapData, 192), shr(96, calldataload(add(dataOffset, 34))))
            mstore(add(swapData, 224), shr(96, calldataload(add(dataOffset, 54))))
            mstore(add(swapData, 256), shr(96, calldataload(add(dataOffset, 74))))
            mstore(add(swapData, 288), calldataload(add(dataOffset, 94)))
            mstore(add(swapData, 320), calldataload(add(dataOffset, 126)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IWETH.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {AppStorage, LibMagpieRouterV2} from "../libraries/LibMagpieRouterV2.sol";
import {LibSwap, SwapData} from "../libraries/LibSwap.sol";

enum MathOperator {
    None,
    Add,
    Sub,
    Mul,
    Div,
    Pow,
    Abs128,
    Abs256,
    Shr,
    Shl
}

enum ComparisonOperator {
    None,
    Lt,
    Lte,
    Gt,
    Gte,
    Eq,
    Ne
}

enum CommandAction {
    Call, // Represents a generic call to a function within a contract.
    Approval, // Represents an approval operation.
    TransferFrom, // Indicates a transfer-from operation.
    Transfer, // Represents a direct transfer operation.
    Wrap, // This action is used for wrapping native tokens.
    Unwrap, // This action is used for unwrapping native tokens.
    Balance, // Checks the balance of an account or contract for a specific asset.
    Math,
    Comparison,
    EstimateGasStart,
    EstimateGasEnd
}

enum SequenceType {
    NativeAmount,
    Selector,
    Address,
    Amount,
    Data, // Parameter represented in bytes.
    CommandOutput, // Parameter using the output of an other command.
    RouterAddress, // The address of this contract.
    SenderAddress // The address of the caller.
}

struct CommandData {
    CommandAction commandAction;
    uint16 inputLength; // Specifies the length of the input data for this command.
    uint16 outputLength; // Specifies the length of the output data for this command.
    uint16 sequencesPosition; // Specifies the starting position of a sequence of data related to this command.
    uint16 sequencesPositionEnd; // Marks the end position of the sequence of data.
    address targetAddress; // The address of the contract that is the target of this command.
}

error CommandFailed(bytes data);
error InvalidAmountOut();
error InvalidSequenceType();
error InvalidSelector();
error InvalidSelectorPosition();
error InvalidSequencesLength();
error InvalidTransferFrom();

library LibCommand {
    using LibAsset for address;

    /// @dev Extracts and assembles a CommandData structure from transaction calldata.
    /// @param i The starting position in the calldata from where data extraction should begin.
    /// @return commandData Describes the specific command.
    function getData(uint16 i) internal pure returns (CommandData memory commandData) {
        assembly {
            mstore(commandData, shr(248, calldataload(i)))
            mstore(add(commandData, 32), shr(240, calldataload(add(i, 1))))
            mstore(add(commandData, 64), shr(240, calldataload(add(i, 3))))
            mstore(add(commandData, 96), shr(240, calldataload(add(i, 5))))
            mstore(add(commandData, 128), shr(240, calldataload(add(i, 7))))
            let targetPosition := shr(240, calldataload(add(i, 9)))
            mstore(add(commandData, 160), shr(96, calldataload(targetPosition)))
        }
    }

    /// @dev Extracts data that is required for the next command's execution.
    /// @param commandOutput Summarized byte code received / calculated after each command execution.
    /// @param commandData Describes the specific command.
    /// @return nativeAmount Amount in native tokens.
    /// @return input The calldata that has to be executed by the next command.
    function getInput(
        bytes memory commandOutput,
        CommandData memory commandData
    ) internal view returns (uint256 nativeAmount, bytes memory input) {
        AppStorage storage s = LibMagpieRouterV2.getStorage();
        input = new bytes(commandData.inputLength);

        SequenceType sequenceType;
        uint16 p;
        uint16 l;
        uint16 inputOffset = 32;
        bytes4 selector;
        for (uint16 i = commandData.sequencesPosition; i < commandData.sequencesPositionEnd; ) {
            assembly {
                sequenceType := shr(248, calldataload(i))
            }

            if (sequenceType == SequenceType.NativeAmount) {
                assembly {
                    p := shr(240, calldataload(add(i, 1)))
                    l := shr(240, calldataload(add(i, 3)))
                    switch l
                    case 1 {
                        nativeAmount := mload(add(add(commandOutput, 32), p))
                    }
                    default {
                        nativeAmount := calldataload(p)
                    }
                }
                unchecked {
                    i += 5;
                }
            } else if (sequenceType == SequenceType.Selector) {
                assembly {
                    p := shr(240, calldataload(add(i, 1)))
                }
                if (inputOffset != 32) {
                    revert InvalidSelectorPosition();
                }
                selector = s.selectors[p];
                assembly {
                    mstore(add(input, inputOffset), selector)
                }
                inputOffset += 4;
                unchecked {
                    i += 3;
                }
            } else if (sequenceType == SequenceType.Address) {
                assembly {
                    p := shr(240, calldataload(add(i, 1)))
                    mstore(add(input, inputOffset), shr(96, calldataload(p)))
                }
                inputOffset += 32;
                unchecked {
                    i += 3;
                }
            } else if (sequenceType == SequenceType.Amount) {
                assembly {
                    p := shr(240, calldataload(add(i, 1)))
                    mstore(add(input, inputOffset), calldataload(p))
                }
                inputOffset += 32;
                unchecked {
                    i += 3;
                }
            } else if (sequenceType == SequenceType.Data) {
                assembly {
                    p := shr(240, calldataload(add(i, 1)))
                    l := shr(240, calldataload(add(i, 3)))
                    calldatacopy(add(input, inputOffset), p, l)
                }
                inputOffset += l;
                unchecked {
                    i += 5;
                }
            } else if (sequenceType == SequenceType.CommandOutput) {
                assembly {
                    p := shr(240, calldataload(add(i, 1)))
                    mstore(add(input, inputOffset), mload(add(add(commandOutput, 32), p)))
                }
                inputOffset += 32;
                unchecked {
                    i += 3;
                }
            } else if (sequenceType == SequenceType.RouterAddress) {
                assembly {
                    mstore(add(input, inputOffset), address())
                }
                inputOffset += 32;
                unchecked {
                    i += 1;
                }
            } else if (sequenceType == SequenceType.SenderAddress) {
                assembly {
                    mstore(add(input, inputOffset), caller())
                }
                inputOffset += 32;
                unchecked {
                    i += 1;
                }
            } else {
                revert InvalidSequenceType();
            }
        }

        if (inputOffset - 32 != commandData.inputLength) {
            revert InvalidSequencesLength();
        }

        if (commandData.commandAction == CommandAction.Call) {
            if (selector == 0) {
                revert InvalidSelector();
            }
        }
    }

    /// @dev Math operations.
    function math(bytes memory input) internal pure returns (uint256) {
        uint256[] memory localOutputs = new uint256[](10);
        bytes32 amount0;
        bytes32 amount1;
        MathOperator operator;

        for (uint8 i = 0; i <= 9; ) {
            assembly {
                let pos := add(add(input, 32), mul(i, 3))
                let amount0Index := shr(248, mload(add(pos, 1)))
                if lt(amount0Index, 10) {
                    amount0 := mload(add(add(localOutputs, 32), mul(amount0Index, 32)))
                }
                if gt(amount0Index, 9) {
                    amount0Index := sub(amount0Index, 10)
                    amount0 := mload(add(add(input, 64), mul(amount0Index, 32)))
                }
                let amount1Index := shr(248, mload(add(pos, 2)))
                if lt(amount1Index, 10) {
                    amount1 := mload(add(add(localOutputs, 32), mul(amount1Index, 32)))
                }
                if gt(amount1Index, 9) {
                    amount1Index := sub(amount1Index, 10)
                    amount1 := mload(add(add(input, 64), mul(amount1Index, 32)))
                }
                operator := shr(248, mload(pos))
            }

            if (operator == MathOperator.None) {
                return localOutputs[i - 1];
            } else if (operator == MathOperator.Add) {
                localOutputs[i] = uint256(amount0) + uint256(amount1);
            } else if (operator == MathOperator.Sub) {
                localOutputs[i] = uint256(amount0) - uint256(amount1);
            } else if (operator == MathOperator.Mul) {
                localOutputs[i] = uint256(amount0) * uint256(amount1);
            } else if (operator == MathOperator.Div) {
                localOutputs[i] = uint256(amount0) / uint256(amount1);
            } else if (operator == MathOperator.Pow) {
                localOutputs[i] = uint256(amount0) ** uint256(amount1);
            } else if (operator == MathOperator.Abs128) {
                int128 amount;
                assembly {
                    amount := amount0
                }

                if (amount < 0) {
                    localOutputs[i] = uint256(uint128(-(amount)));
                } else {
                    localOutputs[i] = uint256(uint128(amount));
                }
            } else if (operator == MathOperator.Abs256) {
                int256 amount;
                assembly {
                    amount := amount0
                }

                if (amount < 0) {
                    localOutputs[i] = uint256(-(amount));
                } else {
                    localOutputs[i] = uint256(amount);
                }
            } else if (operator == MathOperator.Shr) {
                assembly {
                    mstore(add(add(localOutputs, 32), mul(i, 32)), shr(amount0, amount1))
                }
            } else if (operator == MathOperator.Shl) {
                assembly {
                    mstore(add(add(localOutputs, 32), mul(i, 32)), shl(amount0, amount1))
                }
            }

            unchecked {
                i++;
            }
        }

        return localOutputs[9];
    }

    /// @dev Comparison operations.
    function comparison(bytes memory input) internal pure returns (uint256) {
        uint256[] memory localOutputs = new uint256[](6);
        bytes32 amount0;
        bytes32 amount1;
        bytes32 amount2;
        bytes32 amount3;
        ComparisonOperator operator;

        for (uint8 i = 0; i <= 5; ) {
            assembly {
                let pos := add(add(input, 32), mul(i, 5))
                let amount0Index := shr(248, mload(add(pos, 1)))
                if lt(amount0Index, 6) {
                    amount0 := mload(add(add(localOutputs, 32), mul(amount0Index, 32)))
                }
                if gt(amount0Index, 5) {
                    amount0Index := sub(amount0Index, 6)
                    amount0 := mload(add(add(input, 64), mul(amount0Index, 32)))
                }
                let amount1Index := shr(248, mload(add(pos, 2)))
                if lt(amount1Index, 6) {
                    amount1 := mload(add(add(localOutputs, 32), mul(amount1Index, 32)))
                }
                if gt(amount1Index, 5) {
                    amount1Index := sub(amount1Index, 6)
                    amount1 := mload(add(add(input, 64), mul(amount1Index, 32)))
                }
                let amount2Index := shr(248, mload(add(pos, 3)))
                if lt(amount2Index, 6) {
                    amount2 := mload(add(add(localOutputs, 32), mul(amount2Index, 32)))
                }
                if gt(amount2Index, 5) {
                    amount2Index := sub(amount2Index, 6)
                    amount2 := mload(add(add(input, 64), mul(amount2Index, 32)))
                }
                let amount3Index := shr(248, mload(add(pos, 4)))
                if lt(amount3Index, 6) {
                    amount3 := mload(add(add(localOutputs, 32), mul(amount3Index, 32)))
                }
                if gt(amount3Index, 5) {
                    amount3Index := sub(amount3Index, 6)
                    amount3 := mload(add(add(input, 64), mul(amount3Index, 32)))
                }
                operator := shr(248, mload(pos))
            }

            if (operator == ComparisonOperator.None) {
                return localOutputs[i - 1];
            } else if (operator == ComparisonOperator.Lt) {
                localOutputs[i] = uint256(amount0) < uint256(amount1) ? uint256(amount2) : uint256(amount3);
            } else if (operator == ComparisonOperator.Lte) {
                localOutputs[i] = uint256(amount0) <= uint256(amount1) ? uint256(amount2) : uint256(amount3);
            } else if (operator == ComparisonOperator.Gt) {
                localOutputs[i] = uint256(amount0) > uint256(amount1) ? uint256(amount2) : uint256(amount3);
            } else if (operator == ComparisonOperator.Gte) {
                localOutputs[i] = uint256(amount0) >= uint256(amount1) ? uint256(amount2) : uint256(amount3);
            } else if (operator == ComparisonOperator.Eq) {
                localOutputs[i] = uint256(amount0) == uint256(amount1) ? uint256(amount2) : uint256(amount3);
            } else if (operator == ComparisonOperator.Ne) {
                localOutputs[i] = uint256(amount0) != uint256(amount1) ? uint256(amount2) : uint256(amount3);
            }

            unchecked {
                i++;
            }
        }

        return localOutputs[5];
    }

    /// @dev Perform an ERC-20 token approval operation.
    /// @param input Parameters required by approve.
    function approve(bytes memory input) internal {
        address assetAddress;
        address spenderAddress;
        uint256 amount;
        assembly {
            assetAddress := mload(add(input, 32))
            spenderAddress := mload(add(input, 64))
            amount := mload(add(input, 96))
        }

        if (amount == 0) {
            return;
        }

        assetAddress.approve(spenderAddress, amount);
    }

    /// @dev Perform an ERC-20 token transfer from one address to another.
    /// @param input Parameters required by transferFrom.
    function transferFrom(bytes memory input) internal {
        address assetAddress;
        address fromAddress;
        address toAddress;
        uint256 amount;
        assembly {
            assetAddress := mload(add(input, 32))
            fromAddress := mload(add(input, 64))
            toAddress := mload(add(input, 96))
            amount := mload(add(input, 128))
        }

        if (fromAddress != msg.sender) {
            revert InvalidTransferFrom();
        }

        if (amount == 0) {
            return;
        }

        assetAddress.transferFrom(fromAddress, toAddress, amount);
    }

    /// @dev Perform an ERC-20 token transfer to a specified address.
    /// @param input Parameters required by transfer.
    function transfer(bytes memory input) internal {
        address assetAddress;
        address toAddress;
        uint256 amount;
        assembly {
            assetAddress := mload(add(input, 32))
            toAddress := mload(add(input, 64))
            amount := mload(add(input, 96))
        }

        if (amount == 0) {
            return;
        }

        assetAddress.transfer(toAddress, amount);
    }

    /// @dev Convert native token into wrapped native token.
    /// @param input Parameters required by wrap.
    function wrap(bytes memory input) internal {
        address assetAddress;
        uint256 amount;
        assembly {
            assetAddress := mload(add(input, 32))
            amount := mload(add(input, 64))
        }

        IWETH(assetAddress).deposit{value: amount}();
    }

    /// @dev Convert wrapped native token into native token.
    /// @param input Parameters required by unwrap.
    function unwrap(bytes memory input) internal {
        address assetAddress;
        uint256 amount;
        assembly {
            assetAddress := mload(add(input, 32))
            amount := mload(add(input, 64))
        }

        IWETH(assetAddress).withdraw(amount);
    }

    /// @dev Query the balance of a specific asset.
    /// @param input Parameters required by balance.
    /// @return Balance of the specific asset
    function balance(bytes memory input) internal view returns (uint256) {
        address assetAddress;
        assembly {
            assetAddress := mload(add(input, 32))
        }

        return assetAddress.getBalanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {LibAsset} from "../libraries/LibAsset.sol";

error UniswapV3InvalidAmount();

library LibUniswapV3 {
    using LibAsset for address;

    /// @dev Callback function used in Uniswap V3 swaps, typically called by the Uniswap V3 pool contract during a swap operation.
    /// @param amount0Delta Changes in the amount of the first token involved in the swap.
    /// @param amount1Delta Changes in the amount of the second token involved in the swap.
    /// @param assetIn Asset that has to be transfered to the UniswapV3 pool.
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, address assetIn) internal {
        if (amount0Delta <= 0 && amount1Delta <= 0) {
            revert UniswapV3InvalidAmount();
        }

        assetIn.transfer(msg.sender, amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}