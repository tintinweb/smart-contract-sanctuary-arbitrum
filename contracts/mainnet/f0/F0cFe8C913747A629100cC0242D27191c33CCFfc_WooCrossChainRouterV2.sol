// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

// OpenZeppelin Contracts
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Local Contracts
import "./interfaces/IWooCrossChainRouterV2.sol";
import "./interfaces/IWooRouterV2.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/Stargate/IStargateRouter.sol";

import "./libraries/TransferHelper.sol";

/// @title WOOFi cross chain router implementation.
/// @notice Router for stateless execution of cross chain swap against WOOFi private pool.
/// @custom:stargate-contracts https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet
contract WooCrossChainRouterV2 is IWooCrossChainRouterV2, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    /* ----- Constants ----- */

    address public constant ETH_PLACEHOLDER_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /* ----- Variables ----- */

    IWooRouterV2 public wooRouter;
    IStargateRouter public stargateRouter;

    address public override weth;
    uint256 public override bridgeSlippage; // 1 in 10000th: default 1%
    uint256 public override dstGasForSwapCall;
    uint256 public override dstGasForNoSwapCall;

    uint16 public override sglChainId; // Stargate Local ChainId

    mapping(uint16 => address) public override wooCrossChainRouters; // chainId => WooCrossChainRouter address
    // mapping(uint16 => uint256) public quotePoolIds; // chainId => WooPP quote token pool id
    // mapping(uint16 => address) public wooPPQuoteTokens; // chainId => wooPP quote token address
    mapping(uint16 => address) public override sgETHs; // chainId => SGETH token address

    EnumerableSet.AddressSet private directBridgeTokens;

    receive() external payable {}

    constructor(
        address _weth,
        address _wooRouter,
        address _stargateRouter,
        uint16 _sglChainId
    ) {
        wooRouter = IWooRouterV2(_wooRouter);
        stargateRouter = IStargateRouter(_stargateRouter);

        weth = _weth;
        // quoteToken = wooRouter.wooPool().quoteToken();
        bridgeSlippage = 100;
        dstGasForSwapCall = 360000;
        dstGasForNoSwapCall = 80000;

        sglChainId = _sglChainId;

        // _initWooPPQuoteTokens();
        _initSGETHs();
    }

    /* ----- Functions ----- */

    /** 
        Example Params:
        OP(Optimism) -> ETH(Optimism) -> ETH(Arbitrum)
        srcInfos.chainId = 111
        srcInfos.poolId = 13
        srcInfos.fromToken = OP(Optimism)
        srcInfos.bridgeToken = ETH(Optimism)

        dstInfos.chainId = 110
        dstInfos.poolId = 13
        dstInfos.toToken = ETH(Arbitrum)
        dstInfos.bridgeToken = ETH(Arbitrum)
    */
    function crossSwap(
        uint256 refId,
        address payable to,
        SrcInfos memory srcInfos,
        DstInfos memory dstInfos
    ) external payable override {
        require(srcInfos.fromToken != address(0), "WooCrossChainRouterV2: !srcInfos.fromToken");
        require(dstInfos.toToken != address(0), "WooCrossChainRouterV2: !dstInfos.toToken");
        require(to != address(0), "WooCrossChainRouterV2: !to");

        address msgSender = _msgSender();
        uint256 msgValue = msg.value;
        uint256 bridgeAmount;

        {
            // Step 1: transfer
            if (srcInfos.fromToken == ETH_PLACEHOLDER_ADDR) {
                require(srcInfos.fromAmount <= msgValue, "WooCrossChainRouterV2: !srcInfos.fromAmount");
                srcInfos.fromToken = weth;
                IWETH(srcInfos.fromToken).deposit{value: srcInfos.fromAmount}();
                msgValue -= srcInfos.fromAmount;
            } else {
                TransferHelper.safeTransferFrom(srcInfos.fromToken, msg.sender, address(this), srcInfos.fromAmount);
            }

            // Step 2: local swap by WooRouter or not
            // 1.WOO is directBridgeToken, path(always) WOO(Arbitrum) => WOO(BSC)
            // 2.WOO not the directBridgeToken, path(maybe): WOO(Arbitrum) -> ETH(Arbitrum) => ETH(BSC) -> WOO(BSC)
            // 3.Ethereum no WOOFi liquidity, tokens(WOO, ETH, USDC) always will be bridged directly without swap
            if (!directBridgeTokens.contains(srcInfos.fromToken) && srcInfos.fromToken != srcInfos.bridgeToken) {
                TransferHelper.safeApprove(srcInfos.fromToken, address(wooRouter), srcInfos.fromAmount);
                bridgeAmount = wooRouter.swap(
                    srcInfos.fromToken,
                    srcInfos.bridgeToken,
                    srcInfos.fromAmount,
                    srcInfos.minBridgeAmount,
                    payable(address(this)),
                    to
                );
            } else {
                require(
                    srcInfos.fromAmount == srcInfos.minBridgeAmount,
                    "WooCrossChainRouterV2: !srcInfos.minBridgeAmount"
                );
                bridgeAmount = srcInfos.fromAmount;
            }
            require(
                bridgeAmount <= IERC20(srcInfos.bridgeToken).balanceOf(address(this)),
                "WooCrossChainRouterV2: !bridgeAmount"
            );
        }

        {
            // Step 3: cross chain swap by StargateRouter
            bytes memory payload = _encodePayload(refId, to, dstInfos);

            uint256 dstMinBridgeAmount = (bridgeAmount * (10000 - bridgeSlippage)) / 10000;
            bytes memory dstWooCrossChainRouter = abi.encodePacked(wooCrossChainRouters[dstInfos.chainId]);

            IStargateRouter.lzTxObj memory obj = _getLzTxObj(to, dstInfos);

            TransferHelper.safeApprove(srcInfos.bridgeToken, address(stargateRouter), bridgeAmount);
            stargateRouter.swap{value: msgValue}(
                dstInfos.chainId, // dst chain id
                srcInfos.poolId, // bridge token's pool id on src chain
                dstInfos.poolId, // bridge token's pool id on dst chain
                payable(msgSender), // rebate address
                bridgeAmount, // swap amount on src chain
                dstMinBridgeAmount, // min received amount on dst chain
                obj, // config: dstGasForCall, dstAirdropNativeAmount, dstReceiveAirdropNativeTokenAddr
                dstWooCrossChainRouter, // smart contract to call on dst chain
                payload // payload to piggyback
            );
        }

        emit WooCrossSwapOnSrcChain(
            refId,
            msgSender,
            to,
            srcInfos.fromToken,
            srcInfos.fromAmount,
            srcInfos.minBridgeAmount,
            bridgeAmount
        );
    }

    function sgReceive(
        uint16, /*_chainId*/
        bytes memory, /*_srcAddress*/
        uint256, /*_nonce*/
        address bridgedToken,
        uint256 amountLD,
        bytes memory payload
    ) external override {
        require(msg.sender == address(stargateRouter), "WooCrossChainRouterV2: INVALID_CALLER");

        (uint256 refId, address to, address toToken, uint256 minToAmount) = _decodePayload(payload);

        // When bridged by ETH, the bridgedToken will be SGETH ERC20 address and send native token to address(this)
        if (toToken == ETH_PLACEHOLDER_ADDR && bridgedToken == sgETHs[sglChainId]) {
            TransferHelper.safeTransferETH(to, amountLD);
            emit WooCrossSwapOnDstChain(
                refId,
                msg.sender,
                to,
                ETH_PLACEHOLDER_ADDR,
                amountLD,
                toToken,
                ETH_PLACEHOLDER_ADDR,
                minToAmount,
                amountLD
            );
            return;
        }

        if (toToken == bridgedToken) {
            TransferHelper.safeTransfer(bridgedToken, to, amountLD);
            emit WooCrossSwapOnDstChain(
                refId,
                msg.sender,
                to,
                bridgedToken,
                amountLD,
                toToken,
                bridgedToken,
                minToAmount,
                amountLD
            );
            return;
        }

        if (bridgedToken == sgETHs[sglChainId]) {
            // Bridged by ETH, and toToken is not ETH, holding ETH assets, require swap to toToken
            try
                wooRouter.swap{value: amountLD}(ETH_PLACEHOLDER_ADDR, toToken, amountLD, minToAmount, payable(to), to)
            returns (uint256 realToAmount) {
                emit WooCrossSwapOnDstChain(
                    refId,
                    msg.sender,
                    to,
                    ETH_PLACEHOLDER_ADDR,
                    amountLD,
                    toToken,
                    toToken,
                    minToAmount,
                    realToAmount
                );
            } catch {
                TransferHelper.safeTransferETH(to, amountLD);
                emit WooCrossSwapOnDstChain(
                    refId,
                    msg.sender,
                    to,
                    ETH_PLACEHOLDER_ADDR,
                    amountLD,
                    toToken,
                    ETH_PLACEHOLDER_ADDR,
                    minToAmount,
                    amountLD
                );
            }
        } else {
            // Bridged by ERC20 token, holding ERC20 token assets, require swap to toToken(can be ETH)
            // TODO: Discuss this situation: bridgedToken(BUSD), toToken(USDT), not support stable coin swap now on WooRouter
            // Waste gas by code below?
            TransferHelper.safeApprove(bridgedToken, address(wooRouter), amountLD);
            try wooRouter.swap(bridgedToken, toToken, amountLD, minToAmount, payable(to), to) returns (
                uint256 realToAmount
            ) {
                emit WooCrossSwapOnDstChain(
                    refId,
                    msg.sender,
                    to,
                    bridgedToken,
                    amountLD,
                    toToken,
                    toToken,
                    minToAmount,
                    realToAmount
                );
            } catch {
                TransferHelper.safeTransfer(bridgedToken, to, amountLD);
                emit WooCrossSwapOnDstChain(
                    refId,
                    msg.sender,
                    to,
                    bridgedToken,
                    amountLD,
                    toToken,
                    bridgedToken,
                    minToAmount,
                    amountLD
                );
            }
        }
    }

    function quoteLayerZeroFee(
        uint256 refId,
        address to,
        DstInfos memory dstInfos
    ) external view override returns (uint256, uint256) {
        bytes memory payload = _encodePayload(refId, to, dstInfos);

        IStargateRouter.lzTxObj memory obj = _getLzTxObj(to, dstInfos);

        return
            stargateRouter.quoteLayerZeroFee(
                dstInfos.chainId,
                1, // https://stargateprotocol.gitbook.io/stargate/developers/function-types
                obj.dstNativeAddr,
                payload,
                obj
            );
    }

    function allDirectBridgeTokens() external view override returns (address[] memory) {
        uint256 length = directBridgeTokens.length();
        address[] memory tokens = new address[](length);
        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                tokens[i] = directBridgeTokens.at(i);
            }
        }
        return tokens;
    }

    function allDirectBridgeTokensLength() external view override returns (uint256) {
        return directBridgeTokens.length();
    }

    function _initSGETHs() internal {
        sgETHs[101] = 0x72E2F4830b9E45d52F80aC08CB2bEC0FeF72eD9c;
        sgETHs[110] = 0x82CbeCF39bEe528B5476FE6d1550af59a9dB6Fc0;
        sgETHs[111] = 0xb69c8CBCD90A39D8D3d3ccf0a3E968511C3856A0;
    }

    function _getLzTxObj(address to, DstInfos memory dstInfos) internal view returns (IStargateRouter.lzTxObj memory) {
        uint256 dstGasForCall = (dstInfos.toToken == dstInfos.bridgeToken) ? dstGasForNoSwapCall : dstGasForSwapCall;

        return IStargateRouter.lzTxObj(dstGasForCall, dstInfos.airdropNativeAmount, abi.encodePacked(to));
    }

    function _encodePayload(
        uint256 refId,
        address to,
        DstInfos memory dstInfos
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                refId, // reference id
                to, // address for receive tokens
                dstInfos.toToken, // to token on dst chain
                dstInfos.minToAmount // minToAmount on dst chain
            );
    }

    function _decodePayload(bytes memory payload)
        internal
        pure
        returns (
            uint256,
            address,
            address,
            uint256
        )
    {
        return abi.decode(payload, (uint256, address, address, uint256));
    }

    /* ----- Owner & Admin Functions ----- */

    function setWooRouter(address _wooRouter) external onlyOwner {
        require(_wooRouter != address(0), "WooCrossChainRouterV2: !_wooRouter");
        wooRouter = IWooRouterV2(_wooRouter);
    }

    function setStargateRouter(address _stargateRouter) external onlyOwner {
        require(_stargateRouter != address(0), "WooCrossChainRouterV2: !_stargateRouter");
        stargateRouter = IStargateRouter(_stargateRouter);
    }

    function setBridgeSlippage(uint256 _bridgeSlippage) external onlyOwner {
        require(_bridgeSlippage <= 10000, "WooCrossChainRouterV2: !_bridgeSlippage");
        bridgeSlippage = _bridgeSlippage;
    }

    function setDstGasForSwapCall(uint256 _dstGasForSwapCall) external onlyOwner {
        dstGasForSwapCall = _dstGasForSwapCall;
    }

    function setDstGasForNoSwapCall(uint256 _dstGasForNoSwapCall) external onlyOwner {
        dstGasForNoSwapCall = _dstGasForNoSwapCall;
    }

    function setSGLChainId(uint16 _sglChainId) external onlyOwner {
        sglChainId = _sglChainId;
    }

    function setWooCrossChainRouter(uint16 chainId, address wooCrossChainRouter) external onlyOwner {
        require(wooCrossChainRouter != address(0), "WooCrossChainRouterV2: !wooCrossChainRouter");
        wooCrossChainRouters[chainId] = wooCrossChainRouter;
    }

    function setSGETH(uint16 chainId, address token) external onlyOwner {
        sgETHs[chainId] = token;
    }

    function addDirectBridgeToken(address token) external onlyOwner {
        bool success = directBridgeTokens.add(token);
        require(success, "WooCrossChainRouterV2: token exist");
    }

    function removeDirectBridgeToken(address token) external onlyOwner {
        bool success = directBridgeTokens.remove(token);
        require(success, "WooCrossChainRouterV2: token not exist");
    }

    function inCaseTokenGotStuck(address stuckToken) external onlyOwner {
        if (stuckToken == ETH_PLACEHOLDER_ADDR) {
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
        } else {
            uint256 amount = IERC20(stuckToken).balanceOf(address(this));
            TransferHelper.safeTransfer(stuckToken, msg.sender, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/// @title WOOFi cross chain router interface (version 2).
/// @notice functions to interface with WOOFi cross chain swap.
interface IWooCrossChainRouterV2 {
    /* ----- Structs ----- */

    struct SrcInfos {
        uint16 chainId;
        uint256 poolId;
        address fromToken;
        address bridgeToken;
        uint256 fromAmount;
        uint256 minBridgeAmount;
    }

    struct DstInfos {
        uint16 chainId;
        uint256 poolId;
        address toToken;
        address bridgeToken;
        uint256 minToAmount;
        uint256 airdropNativeAmount;
    }

    /* ----- Events ----- */

    event WooCrossSwapOnSrcChain(
        uint256 indexed refId,
        address indexed sender,
        address indexed to,
        address fromToken,
        uint256 fromAmount,
        uint256 minBridgeAmount,
        uint256 realBridgeAmount
    );

    event WooCrossSwapOnDstChain(
        uint256 indexed refId,
        address indexed sender,
        address indexed to,
        address bridgedToken,
        uint256 bridgedAmount,
        address toToken,
        address realToToken,
        uint256 minToAmount,
        uint256 realToAmount
    );

    /* ----- State Variables ----- */

    function weth() external view returns (address);

    function bridgeSlippage() external view returns (uint256);

    function dstGasForSwapCall() external view returns (uint256);

    function dstGasForNoSwapCall() external view returns (uint256);

    function sglChainId() external view returns (uint16);

    function wooCrossChainRouters(uint16 chainId) external view returns (address wooCrossChainRouter);

    function sgETHs(uint16 chainId) external view returns (address sgETH);

    /* ----- Functions ----- */

    function crossSwap(
        uint256 refId,
        address payable to,
        SrcInfos memory srcInfos,
        DstInfos memory dstInfos
    ) external payable;

    function sgReceive(
        uint16 chainId,
        bytes memory srcAddress,
        uint256 nonce,
        address token,
        uint256 amountLD,
        bytes memory payload
    ) external;

    function quoteLayerZeroFee(
        uint256 refId,
        address to,
        DstInfos memory dstInfos
    ) external view returns (uint256 nativeAmount, uint256 zroAmount);

    function allDirectBridgeTokens() external view returns (address[] memory tokens);

    function allDirectBridgeTokensLength() external view returns (uint256 length);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Wrapped ETH.
interface IWETH {
    /// @dev Deposit ETH into WETH
    function deposit() external payable;

    /// @dev Transfer WETH to receiver
    /// @param to address of WETH receiver
    /// @param value amount of WETH to transfer
    /// @return get true when succeed, else false
    function transfer(address to, uint256 value) external returns (bool);

    /// @dev Withdraw WETH to ETH
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import "../interfaces/IWooPPV2.sol";

/// @title Woo router interface (version 2)
/// @notice functions to interface with WooFi swap
interface IWooRouterV2 {
    /* ----- Type declarations ----- */

    enum SwapType {
        WooSwap,
        DodoSwap
    }

    /* ----- Events ----- */

    event WooRouterSwap(
        SwapType swapType,
        address indexed fromToken,
        address indexed toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address from,
        address indexed to,
        address rebateTo
    );

    event WooPoolChanged(address newPool);

    /* ----- Router properties ----- */

    function WETH() external view returns (address);

    function wooPool() external view returns (IWooPPV2);

    /* ----- Main query & swap APIs ----- */

    /// @notice query the amount to swap fromToken -> toToken
    /// @param fromToken the from token
    /// @param toToken the to token
    /// @param fromAmount the amount of fromToken to swap
    /// @return toAmount the predicted amount to receive
    function querySwap(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (uint256 toAmount);

    /// @notice query the amount to swap fromToken -> toToken,
    ///     WITHOUT checking the reserve balance; so it
    ///     always returns the quoted amount (for reference).
    /// @param fromToken the from token
    /// @param toToken the to token
    /// @param fromAmount the amount of fromToken to swap
    /// @return toAmount the predicted amount to receive
    function tryQuerySwap(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (uint256 toAmount);

    /// @notice Swap `fromToken` to `toToken`.
    /// @param fromToken the from token
    /// @param toToken the to token
    /// @param fromAmount the amount of `fromToken` to swap
    /// @param minToAmount the minimum amount of `toToken` to receive
    /// @param to the destination address
    /// @param rebateTo the rebate address (optional, can be 0)
    /// @return realToAmount the amount of toToken to receive
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address payable to,
        address rebateTo
    ) external payable returns (uint256 realToAmount);

    /* ----- 3rd party DEX swap ----- */

    /// @notice swap fromToken -> toToken via an external 3rd swap
    /// @param approveTarget the contract address for token transfer approval
    /// @param swapTarget the contract address for swap
    /// @param fromToken the from token
    /// @param toToken the to token
    /// @param fromAmount the amount of fromToken to swap
    /// @param minToAmount the min amount of swapped toToken
    /// @param to the destination address
    /// @param data call data for external call
    function externalSwap(
        address approveTarget,
        address swapTarget,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address payable to,
        bytes calldata data
    ) external payable returns (uint256 realToAmount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/// @title Woo private pool for swap.
/// @notice Use this contract to directly interfact with woo's synthetic proactive
///         marketing making pool.
/// @author woo.network
interface IWooPPV2 {
    /* ----- Events ----- */

    event Deposit(address indexed token, address indexed sender, uint256 amount);
    event Withdraw(address indexed token, address indexed receiver, uint256 amount);
    event Migrate(address indexed token, address indexed receiver, uint256 amount);
    event AdminUpdated(address indexed addr, bool flag);
    event FeeAddrUpdated(address indexed newFeeAddr);
    event WooracleUpdated(address indexed newWooracle);
    event WooSwap(
        address indexed fromToken,
        address indexed toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address from,
        address indexed to,
        address rebateTo,
        uint256 swapVol,
        uint256 swapFee
    );

    /* ----- External Functions ----- */

    /// @notice The quote token address (immutable).
    /// @return address of quote token
    function quoteToken() external view returns (address);

    /// @notice Gets the pool size of the specified token (swap liquidity).
    /// @param token the token address
    /// @return the pool size
    function poolSize(address token) external view returns (uint256);

    /// @notice Query the amount to swap `fromToken` to `toToken`, without checking the pool reserve balance.
    /// @param fromToken the from token
    /// @param toToken the to token
    /// @param fromAmount the amount of `fromToken` to swap
    /// @return toAmount the swapped amount of `toToken`
    function tryQuery(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (uint256 toAmount);

    /// @notice Query the amount to swap `fromToken` to `toToken`, with checking the pool reserve balance.
    /// @dev tx reverts when 'toToken' balance is insufficient.
    /// @param fromToken the from token
    /// @param toToken the to token
    /// @param fromAmount the amount of `fromToken` to swap
    /// @return toAmount the swapped amount of `toToken`
    function query(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (uint256 toAmount);

    /// @notice Swap `fromToken` to `toToken`.
    /// @param fromToken the from token
    /// @param toToken the to token
    /// @param fromAmount the amount of `fromToken` to swap
    /// @param minToAmount the minimum amount of `toToken` to receive
    /// @param to the destination address
    /// @param rebateTo the rebate address (optional, can be address ZERO)
    /// @return realToAmount the amount of toToken to receive
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address to,
        address rebateTo
    ) external returns (uint256 realToAmount);

    /// @notice Deposit the specified token into the liquidity pool of WooPPV2.
    /// @param token the token to deposit
    /// @param amount the deposit amount
    function deposit(address token, uint256 amount) external;
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