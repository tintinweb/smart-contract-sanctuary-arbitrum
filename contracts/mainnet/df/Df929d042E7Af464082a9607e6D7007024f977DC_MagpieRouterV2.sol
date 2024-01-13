// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable2Step} from "openzeppelin-solidity/contracts/access/Ownable2Step.sol";
import {Multicall} from "openzeppelin-solidity/contracts/utils/Multicall.sol";
import {IMagpieRouterV2} from "./interfaces/IMagpieRouterV2.sol";
import {LibAssetV2} from "./libraries/LibAssetV2.sol";
import {AppStorage, LibMagpieRouterV2} from "./libraries/LibMagpieRouterV2.sol";
import {LibSwap, SwapData, SwapState} from "./libraries/LibSwap.sol";
import {LibCommand, CommandAction, CommandData} from "./router/LibCommand.sol";
import {LibUniswapV3} from "./router/LibUniswapV3.sol";

error ExpiredTransaction();
error InsufficientAmountOut();

contract MagpieRouterV2 is IMagpieRouterV2, Ownable2Step, Multicall {
    using LibAssetV2 for address;

    function updateSelector(uint16 commandType, bytes4 selector) external onlyOwner {
        AppStorage storage s = LibMagpieRouterV2.getStorage();

        s.selectors[commandType] = selector;
    }

    function enforceDeadline(uint256 deadline) private view {
        if (deadline < block.timestamp) {
            revert ExpiredTransaction();
        }
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        LibUniswapV3.uniswapV3SwapCallback(amount0Delta, amount1Delta, data);
    }

    function algebraSwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        LibUniswapV3.uniswapV3SwapCallback(amount0Delta, amount1Delta, data);
    }

    function solidlyV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        LibUniswapV3.uniswapV3SwapCallback(amount0Delta, amount1Delta, data);
    }

    function isTokenMovement(CommandAction commandAction) private pure returns (bool) {
        return
            commandAction == CommandAction.Approval ||
            commandAction == CommandAction.TransferFrom ||
            commandAction == CommandAction.Transfer ||
            commandAction == CommandAction.Wrap ||
            commandAction == CommandAction.Unwrap;
    }

    function estimateSwapGas(bytes calldata) external payable returns (uint256 amountOut, uint256 gasUsed) {
        (amountOut, gasUsed) = execute(true, true);
    }

    function swap(bytes calldata) external payable returns (uint256 amountOut) {
        (amountOut, ) = execute(false, true);
    }

    function silentSwap(bytes calldata) external payable returns (uint256 amountOut) {
        (amountOut, ) = execute(false, false);
    }

    function execute(bool estimateGas, bool triggerEvent) private returns (uint256 amountOut, uint256 gasUsed) {
        SwapData memory swapData = LibSwap.getData(LibSwap.SWAP_ARGS_OFFSET);
        SwapState memory swapState = LibSwap.getState(swapData);

        enforceDeadline(swapData.deadline);

        uint16 i;
        CommandData memory commandData;
        uint256 nativeAmount;
        bytes4 selector;
        bytes memory input;
        bool isLastIteration;

        for (i = swapData.commandsOffset; i < swapData.commandsOffsetEnd; ) {
            commandData = LibCommand.getData(i);

            (nativeAmount, selector, input) = LibCommand.getInput(swapState.lastAmountOut, commandData);

            if (estimateGas) {
                isLastIteration = i + 10 >= swapData.commandsOffsetEnd;
                if (nativeAmount != 0 || i == swapData.commandsOffset) {
                    // For native token there is no token movement / so start it from here
                    // Or set an initial value
                    gasUsed = gasleft();
                } else if (isLastIteration && isTokenMovement(commandData.commandAction)) {
                    // The last command is token movement so close before it executes
                    gasUsed -= gasleft();
                }
            }

            uint256 hopAmountOut = LibCommand.execute(commandData, nativeAmount, selector, input);

            if (hopAmountOut != 0) {
                swapState.lastAmountOut = hopAmountOut;
            }

            unchecked {
                i += 10;
            }

            if (estimateGas) {
                if (!isLastIteration && isTokenMovement(commandData.commandAction)) {
                    // Start the calculation from the last token movement
                    gasUsed = gasleft();
                } else if (isLastIteration && !isTokenMovement(commandData.commandAction)) {
                    // It is not a token movement so we can close here
                    gasUsed -= gasleft();
                }
            }
        }

        amountOut = swapData.toAssetAddress.getBalanceOf(swapData.toAddress) - swapState.balance;

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

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMagpieRouterV2 {
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;

    function solidlyV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;

    function algebraSwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;

    function updateSelector(uint16 commandId, bytes4 selector) external;

    event Swap(
        address indexed fromAddress,
        address indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut
    );

    function estimateSwapGas(bytes calldata swapArgs) external payable returns (uint256 amountOut, uint256 gasUsed);

    function swap(bytes calldata swapArgs) external payable returns (uint256 amountOut);

    function silentSwap(bytes calldata swapArgs) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICrocSwapDex {
    function swap(
        address base,
        address quote,
        uint256 poolIdx,
        bool isBuy,
        bool inBaseQty,
        uint128 qty,
        uint16 tip,
        uint128 limitPrice,
        uint128 minOut,
        uint8 settleFlags
    ) external payable returns (int128 baseFlow, int128 quoteFlow);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IKSPool {
    function getTradeInfo()
        external
        view
        returns (uint112 _vReserve0, uint112 _vReserve1, uint112 reserve0, uint112 reserve1, uint256 feeInPrecision);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

    function getAmountOut(uint, address) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface ILBPair {
    function getTokenY() external view returns (IERC20 tokenY);

    function swap(bool swapForY, address to) external returns (bytes32 amountsOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUniswapV3Pool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

library LibAssetV2 {
    using LibAssetV2 for address;

    address constant NATIVE_ASSETID = address(0);

    function isNative(address self) internal pure returns (bool) {
        return self == NATIVE_ASSETID;
    }

    function getBalanceOf(address self, address targetAddress) internal view returns (uint256) {
        return self.isNative() ? targetAddress.balance : IERC20(self).balanceOf(targetAddress);
    }

    function approve(address self, address spender, uint256 amount) internal {
        SafeERC20.forceApprove(IERC20(self), spender, amount);
    }

    function transferFrom(address self, address from, address to, uint256 amount) internal {
        SafeERC20.safeTransferFrom(IERC20(self), from, to, amount);
    }

    function transfer(address self, address recipient, uint256 amount) internal {
        if (self.isNative()) {
            Address.sendValue(payable(recipient), amount);
        } else {
            SafeERC20.safeTransfer(IERC20(self), recipient, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct AppStorage {
    mapping(uint16 => bytes4) selectors;
}

library LibMagpieRouterV2 {
    function getStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LibAssetV2} from "../libraries/LibAssetV2.sol";

struct SwapData {
    uint16 amountsOffset;
    uint16 dataOffset;
    uint16 commandsOffset;
    uint16 commandsOffsetEnd;
    uint256 amountIn;
    address toAddress;
    address fromAssetAddress;
    address toAssetAddress;
    uint256 deadline;
    uint256 amountOutMin;
}

struct SwapState {
    uint256 lastAmountOut;
    uint256 balance;
}

library LibSwap {
    using LibAssetV2 for address;

    uint16 constant SWAP_ARGS_OFFSET = 68;

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

    function getFirstAmountIn(uint16 swapArgsOffset) internal pure returns (uint256 amountIn) {
        uint16 position = swapArgsOffset + 4;
        assembly {
            amountIn := calldataload(position)
        }
    }

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
            mstore(add(swapData, 128), amountIn)
            mstore(add(swapData, 160), shr(96, calldataload(add(dataOffset, 32))))
            mstore(add(swapData, 192), shr(96, calldataload(add(dataOffset, 52))))
            mstore(add(swapData, 224), shr(96, calldataload(add(dataOffset, 72))))
            mstore(add(swapData, 256), calldataload(add(dataOffset, 92)))
            mstore(add(swapData, 288), calldataload(add(dataOffset, 124)))
        }
    }

    function getState(SwapData memory swapData) internal view returns (SwapState memory sws) {
        sws.balance = swapData.toAssetAddress.getBalanceOf(swapData.toAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ICrocSwapDex} from "../interfaces/ambient/ICrocSwapDex.sol";

library LibAmbient {
    // Currently Ambient only has one pool type index initialized and it is 420.
    // https://docs.ambient.finance/developers/type-conventions#pool-type-index

    function swapAmbient(bytes memory input) internal returns (uint256 amountOut) {
        uint256 amountIn;
        address poolAddress;
        address assetIn;
        address assetOut;
        uint256 limitPrice;

        assembly {
            amountIn := mload(add(input, 32))
            poolAddress := mload(add(input, 64))
            assetIn := mload(add(input, 96))
            assetOut := mload(add(input, 128))
            limitPrice := mload(add(input, 160))
        }

        (, int128 quoteFlow) = ICrocSwapDex(poolAddress).swap(
            assetIn,
            assetOut,
            420,
            true,
            true,
            uint128(amountIn),
            0,
            uint128(limitPrice),
            0,
            0
        );
        amountOut = uint256(uint128(-(quoteFlow)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IWETH.sol";
import {LibAssetV2} from "../libraries/LibAssetV2.sol";
import {AppStorage, LibMagpieRouterV2} from "../libraries/LibMagpieRouterV2.sol";
import {LibSwap, SwapData, SwapState} from "../libraries/LibSwap.sol";
import {LibUniswapV2} from "./LibUniswapV2.sol";
import {LibUniswapV3} from "./LibUniswapV3.sol";
import {LibTraderJoeV2_1} from "./LibTraderJoeV2_1.sol";
import {LibSolidly} from "./LibSolidly.sol";
import {LibKyberSwapClassic} from "./LibKyberSwapClassic.sol";
import {LibAmbient} from "./LibAmbient.sol";

enum CommandAction {
    Call,
    Approval,
    TransferFrom,
    Transfer,
    Wrap,
    Unwrap,
    Balance,
    UniswapV2,
    UniswapV3,
    TraderJoeV2_1,
    Solidly,
    KyberSwapClassic,
    Ambient
}

enum SequenceType {
    NativeAmount,
    Selector,
    Address,
    Amount,
    Data,
    LastAmountOut,
    RouterAddress,
    SenderAddress
}

struct CommandData {
    CommandAction commandAction;
    uint8 outputType;
    uint16 inputLength;
    uint16 sequencesPosition;
    uint16 sequencesPositionEnd;
    address targetAddress;
}

error CommandFailed(bytes data);
error InvalidAmountOut();
error InvalidSequenceType();
error InvalidCommand();
error InvalidSelector();
error InvalidSequencesLength();
error InvalidTransferFrom();

library LibCommand {
    using LibAssetV2 for address;

    function getData(uint16 i) internal pure returns (CommandData memory commandData) {
        assembly {
            mstore(commandData, shr(248, calldataload(i)))
            mstore(add(commandData, 32), shr(248, calldataload(add(i, 1))))
            mstore(add(commandData, 64), shr(240, calldataload(add(i, 2))))
            mstore(add(commandData, 96), shr(240, calldataload(add(i, 4))))
            mstore(add(commandData, 128), shr(240, calldataload(add(i, 6))))
            let targetPosition := shr(240, calldataload(add(i, 8)))
            mstore(add(commandData, 160), shr(96, calldataload(targetPosition)))
        }
    }

    function getInput(
        uint256 lastAmountOut,
        CommandData memory commandData
    ) internal view returns (uint256 nativeAmount, bytes4 selector, bytes memory input) {
        AppStorage storage s = LibMagpieRouterV2.getStorage();
        input = new bytes(commandData.inputLength);

        SequenceType sequenceType;
        uint16 p;
        uint16 l;
        uint16 inputOffset = 32;
        for (uint16 i = commandData.sequencesPosition; i < commandData.sequencesPositionEnd; ) {
            assembly {
                sequenceType := shr(248, calldataload(i))
            }

            if (sequenceType == SequenceType.NativeAmount) {
                assembly {
                    p := shr(240, calldataload(add(i, 1)))
                    switch p
                    case 0 {
                        nativeAmount := calldataload(p)
                    }
                    default {
                        nativeAmount := lastAmountOut
                    }
                }
                unchecked {
                    i += 3;
                }
            } else if (sequenceType == SequenceType.Selector) {
                assembly {
                    p := shr(240, calldataload(add(i, 1)))
                }
                selector = s.selectors[p];
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
            } else if (sequenceType == SequenceType.LastAmountOut) {
                assembly {
                    mstore(add(input, inputOffset), lastAmountOut)
                }
                inputOffset += 32;
                unchecked {
                    i += 1;
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
            } else if (selector == 0x23b872dd) {
                // Blacklist transferFrom in custom calls
                revert InvalidTransferFrom();
            }
        }
    }

    function approve(bytes memory input) private {
        address assetAddress;
        address spenderAddress;
        uint256 amount;
        assembly {
            assetAddress := mload(add(input, 32))
            spenderAddress := mload(add(input, 64))
            amount := mload(add(input, 96))
        }
        assetAddress.approve(spenderAddress, amount);
    }

    function transferFrom(bytes memory input) private {
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

        assetAddress.transferFrom(fromAddress, toAddress, amount);
    }

    function transfer(bytes memory input) private {
        address assetAddress;
        address toAddress;
        uint256 amount;
        assembly {
            assetAddress := mload(add(input, 32))
            toAddress := mload(add(input, 64))
            amount := mload(add(input, 96))
        }

        assetAddress.transfer(toAddress, amount);
    }

    function wrap(bytes memory input) private returns (uint256 amount) {
        address assetAddress;
        assembly {
            assetAddress := mload(add(input, 32))
            amount := mload(add(input, 64))
        }
        IWETH(assetAddress).deposit{value: amount}();
    }

    function unwrap(bytes memory input) private returns (uint256 amount) {
        address assetAddress;
        assembly {
            assetAddress := mload(add(input, 32))
            amount := mload(add(input, 64))
        }
        IWETH(assetAddress).withdraw(amount);
    }

    function balance(bytes memory input) private view returns (uint256) {
        address assetAddress;
        assembly {
            assetAddress := mload(add(input, 32))
        }

        return assetAddress.getBalanceOf(address(this));
    }

    function execute(
        CommandData memory commandData,
        uint256 nativeAmount,
        bytes4 selector,
        bytes memory input
    ) internal returns (uint256 amountOut) {
        if (commandData.commandAction == CommandAction.Call) {
            (bool success, bytes memory data) = commandData.targetAddress.call{value: nativeAmount}(
                abi.encodePacked(selector, input)
            );
            if (!success) {
                revert CommandFailed(data);
            }
            if (commandData.outputType == 1) {
                assembly {
                    amountOut := mload(add(data, 32))
                }
                if (amountOut == 0) {
                    revert InvalidAmountOut();
                }
            }
        } else if (commandData.commandAction == CommandAction.Approval) {
            approve(input);
        } else if (commandData.commandAction == CommandAction.TransferFrom) {
            transferFrom(input);
        } else if (commandData.commandAction == CommandAction.Transfer) {
            transfer(input);
        } else if (commandData.commandAction == CommandAction.Wrap) {
            amountOut = wrap(input);
        } else if (commandData.commandAction == CommandAction.Unwrap) {
            amountOut = unwrap(input);
        } else if (commandData.commandAction == CommandAction.Balance) {
            amountOut = balance(input);
        } else if (commandData.commandAction == CommandAction.UniswapV2) {
            amountOut = LibUniswapV2.swapUniswapV2(input);
        } else if (commandData.commandAction == CommandAction.UniswapV3) {
            amountOut = LibUniswapV3.swapUniswapV3(input);
        } else if (commandData.commandAction == CommandAction.TraderJoeV2_1) {
            amountOut = LibTraderJoeV2_1.swapTraderJoeV2_1(input);
        } else if (commandData.commandAction == CommandAction.Solidly) {
            amountOut = LibSolidly.swapSolidly(input);
        } else if (commandData.commandAction == CommandAction.KyberSwapClassic) {
            amountOut = LibKyberSwapClassic.swapKyberClassic(input);
        } else if (commandData.commandAction == CommandAction.Ambient) {
            amountOut = LibAmbient.swapAmbient(input);
        } else {
            revert InvalidCommand();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IKSPool} from "../interfaces/kyber-swap/IKSPool.sol";
import {LibUniswapV2} from "./LibUniswapV2.sol";

library LibKyberSwapClassic {
    function getAmountOut(
        uint256 amountIn,
        uint256 vReserveIn,
        uint256 vReserveOut,
        uint256 feeInPrecision
    ) private pure returns (uint amountOut) {
        uint256 amountInWithFee = (amountIn * (1e18 - feeInPrecision)) / 1e18;
        uint256 numerator = amountInWithFee * vReserveOut;
        uint256 denominator = vReserveIn + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function swapKyberClassic(bytes memory input) internal returns (uint256 amountOut) {
        uint256 amountIn;
        address recipient;
        address poolAddress;
        address assetIn;
        address assetOut;

        assembly {
            amountIn := mload(add(input, 32))
            recipient := mload(add(input, 64))
            poolAddress := mload(add(input, 96))
            assetIn := mload(add(input, 128))
            assetOut := mload(add(input, 160))
        }

        address token0 = assetIn < assetOut ? assetIn : assetOut;
        (, , uint256 vReserve0, uint256 vReserve1, uint256 feeInPrecision) = IKSPool(poolAddress).getTradeInfo();
        (uint256 vReserveIn, uint256 vReserveOut) = assetIn == token0 ? (vReserve0, vReserve1) : (vReserve1, vReserve0);
        amountOut = getAmountOut(amountIn, vReserveIn, vReserveOut, feeInPrecision);
        LibUniswapV2.swap(amountOut, recipient, poolAddress, assetIn, assetOut);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IPair} from "../interfaces/solidly/IPair.sol";
import {LibUniswapV2} from "./LibUniswapV2.sol";

library LibSolidly {
    function swapSolidly(bytes memory input) internal returns (uint256 amountOut) {
        uint256 amountIn;
        address recipient;
        address poolAddress;
        address assetIn;
        address assetOut;

        assembly {
            amountIn := mload(add(input, 32))
            recipient := mload(add(input, 64))
            poolAddress := mload(add(input, 96))
            assetIn := mload(add(input, 128))
            assetOut := mload(add(input, 160))
        }

        amountOut = IPair(poolAddress).getAmountOut(amountIn, assetIn);
        LibUniswapV2.swap(amountOut, recipient, poolAddress, assetIn, assetOut);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import {ILBPair} from "../interfaces/traderJoe-v2-1/ILBPair.sol";

library LibTraderJoeV2_1 {
    function swapTraderJoeV2_1(bytes memory input) internal returns (uint256 amountOut) {
        uint256 amountIn;
        address recipient;
        address poolAddress;
        address assetOut;

        assembly {
            amountIn := mload(add(input, 32))
            recipient := mload(add(input, 64))
            poolAddress := mload(add(input, 96))
            assetOut := mload(add(input, 128))
        }

        bool swapForY = IERC20(assetOut) == ILBPair(poolAddress).getTokenY();
        uint256 amountXOut;
        uint256 amountYOut;
        bytes32 amountsOut = ILBPair(poolAddress).swap(swapForY, recipient);
        assembly {
            amountXOut := and(amountsOut, 0xffffffffffffffffffffffffffffffff)
            amountYOut := shr(128, amountsOut)
        }
        amountOut = swapForY ? amountYOut : amountXOut;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IUniswapV2Pair} from "../interfaces/uniswap-v2/IUniswapV2Pair.sol";

library LibUniswapV2 {
    function getAmountOut(
        uint256 amountIn,
        uint16 swapFee,
        uint16 swapFeeBase,
        uint256 reserveIn,
        uint256 reserveOut
    ) private pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * swapFee;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * swapFeeBase + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function getReserveInOut(
        address assetIn,
        address assetOut,
        uint256 reserve0,
        uint256 reserve1
    ) internal pure returns (uint256 reserveIn, uint256 reserveOut) {
        address token0 = assetIn < assetOut ? assetIn : assetOut;

        (reserveIn, reserveOut) = assetIn == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function swap(
        uint256 amountOut,
        address recipient,
        address poolAddress,
        address assetIn,
        address assetOut
    ) internal {
        address token0 = assetIn < assetOut ? assetIn : assetOut;
        (uint256 amount0Out, uint256 amount1Out) = assetIn == token0
            ? (uint256(0), amountOut)
            : (amountOut, uint256(0));
        IUniswapV2Pair(poolAddress).swap(amount0Out, amount1Out, recipient, new bytes(0));
    }

    function swapUniswapV2(bytes memory input) internal returns (uint256 amountOut) {
        uint256 amountIn;
        address recipient;
        address poolAddress;
        address assetIn;
        address assetOut;
        uint16 swapFee;
        uint16 swapFeeBase;

        assembly {
            amountIn := mload(add(input, 32))
            recipient := mload(add(input, 64))
            poolAddress := mload(add(input, 96))
            assetIn := mload(add(input, 128))
            assetOut := mload(add(input, 160))
            swapFee := shr(240, mload(add(input, 192)))
            swapFeeBase := shr(240, mload(add(input, 194)))
        }

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(poolAddress).getReserves();
        (uint256 reserveIn, uint256 reserveOut) = getReserveInOut(assetIn, assetOut, reserve0, reserve1);
        amountOut = getAmountOut(amountIn, swapFee, swapFeeBase, reserveIn, reserveOut);
        swap(amountOut, recipient, poolAddress, assetIn, assetOut);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IUniswapV3Pool} from "../interfaces/uniswap-v3/IUniswapV3Pool.sol";
import {LibAssetV2} from "../libraries/LibAssetV2.sol";

error UniswapV3InvalidAmount();

library LibUniswapV3 {
    using LibAssetV2 for address;

    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    function swapUniswapV3(bytes memory input) internal returns (uint256 amountOut) {
        bytes memory data = new bytes(20);
        uint256 amountIn;
        address recipient;
        address poolAddress;
        address assetIn;
        address assetOut;
        uint24 fee;

        assembly {
            amountIn := mload(add(input, 32))
            recipient := mload(add(input, 64))
            poolAddress := mload(add(input, 96))
            assetIn := mload(add(input, 128))
            assetOut := mload(add(input, 160))
            fee := shr(232, mload(add(input, 192)))

            mstore(add(data, 32), shl(96, assetIn))
        }

        bool zeroForOne = assetIn < assetOut;
        (int256 amount0, int256 amount1) = IUniswapV3Pool(poolAddress).swap(
            recipient,
            zeroForOne,
            int256(amountIn),
            (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1),
            data
        );

        amountOut = uint256(-(zeroForOne ? amount1 : amount0));
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes memory data) internal {
        if (amount0Delta <= 0 && amount1Delta <= 0) {
            revert UniswapV3InvalidAmount();
        }

        address assetIn;

        assembly {
            assetIn := shr(96, mload(add(data, 32)))
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

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
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
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