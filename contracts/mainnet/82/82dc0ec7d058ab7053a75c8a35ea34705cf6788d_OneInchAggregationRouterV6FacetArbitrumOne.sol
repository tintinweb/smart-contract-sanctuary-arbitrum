// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {ClipperRouter} from "../ThirdParties/1inch/routers/ClipperRouter.sol";
import {PermitAndCall} from "@1inch/solidity-utils/contracts/PermitAndCall.sol";
import {GenericRouterDelegator} from "../ThirdParties/1inch/routers/GenericRouterDelegator.sol";
import {UnoswapRouterArbitrumOne} from "../ThirdParties/1inch/routers/UnoswapRouter.arbitrumone.sol";
import {UniERC20} from "@1inch/solidity-utils/contracts/libraries/UniERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EthReceiver} from "@1inch/solidity-utils/contracts/EthReceiver.sol";
import {OnlyWethReceiver} from "@1inch/solidity-utils/contracts/OnlyWethReceiver.sol";
import {IWETH} from "@1inch/solidity-utils/contracts/interfaces/IWETH.sol";

contract OneInchAggregationRouterV6FacetArbitrumOne is
    ClipperRouter,
    GenericRouterDelegator,
    UnoswapRouterArbitrumOne,
    PermitAndCall
{
    using UniERC20 for IERC20;

    error ZeroAddress();

    /**
     * @dev Sets the wrapped eth token and clipper exhange interface
     * Both values are immutable: they can only be set once during
     * construction.
     */
    constructor()
        ClipperRouter(IWETH(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1))
        GenericRouterDelegator(payable(0x111111125421cA6dc452d289314280a0f8842A65))
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {IClipperExchange} from "../interfaces/IClipperExchange.sol";
import {IWETH} from "@1inch/solidity-utils/contracts/interfaces/IWETH.sol";
import {AddressLib, Address} from "@1inch/solidity-utils/contracts/libraries/AddressLib.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import {Errors} from "@1inch/limit-order-protocol-contract/contracts/libraries/Errors.sol";
import {RouterErrors} from "../helpers/RouterErrors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EthReceiver} from "@1inch/solidity-utils/contracts/EthReceiver.sol";

/**
 * @title ClipperRouter
 * @notice Clipper router that allows to use `IClipperExchange` for swaps.
 */
contract ClipperRouter is EthReceiver {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;
    using AddressLib for Address;

    uint256 private constant _PERMIT2_FLAG = 1 << 255;
    uint256 private constant _SIGNATURE_S_MASK = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant _SIGNATURE_V_SHIFT = 255;
    bytes5 private constant _INCH_TAG = "1INCH";
    uint256 private constant _INCH_TAG_LENGTH = 5;
    IERC20 private constant _ETH = IERC20(address(0));
    IWETH private immutable _WETH; // solhint-disable-line var-name-mixedcase

    constructor(IWETH weth) {
        _WETH = weth;
    }

    /**
     * @notice Same as `clipperSwapTo` but uses `msg.sender` as recipient.
     * @param clipperExchange Clipper pool address.
     * @param srcToken Source token and flags.
     * @param dstToken Destination token.
     * @param inputAmount Amount of source tokens to swap.
     * @param outputAmount Amount of destination tokens to receive.
     * @param goodUntil Clipper parameter.
     * @param r Clipper order signature (r part).
     * @param vs Clipper order signature (vs part).
     * @return returnAmount Amount of destination tokens received.
     */
    function clipperSwap(
        IClipperExchange clipperExchange,
        Address srcToken,
        IERC20 dstToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        bytes32 r,
        bytes32 vs
    ) external payable returns (uint256 returnAmount) {
        return clipperSwapTo(
            clipperExchange, payable(msg.sender), srcToken, dstToken, inputAmount, outputAmount, goodUntil, r, vs
        );
    }

    /**
     * @notice Performs swap using Clipper exchange. Wraps and unwraps ETH if required.
     *         Sending non-zero `msg.value` for anything but ETH swaps is prohibited.
     * @param clipperExchange Clipper pool address.
     * @param recipient Address that will receive swap funds.
     * @param srcToken Source token and flags.
     * @param dstToken Destination token.
     * @param inputAmount Amount of source tokens to swap.
     * @param outputAmount Amount of destination tokens to receive.
     * @param goodUntil Clipper parameter.
     * @param r Clipper order signature (r part).
     * @param vs Clipper order signature (vs part).
     * @return returnAmount Amount of destination tokens received.
     */
    function clipperSwapTo(
        IClipperExchange clipperExchange,
        address payable recipient,
        Address srcToken,
        IERC20 dstToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        bytes32 r,
        bytes32 vs
    ) public payable returns (uint256 returnAmount) {
        IERC20 srcToken_ = IERC20(srcToken.get());
        if (srcToken_ == _ETH) {
            if (msg.value != inputAmount) revert RouterErrors.InvalidMsgValue();
        } else {
            if (msg.value != 0) revert RouterErrors.InvalidMsgValue();
            srcToken_.safeTransferFromUniversal(
                msg.sender, address(clipperExchange), inputAmount, srcToken.getFlag(_PERMIT2_FLAG)
            );
        }
        if (srcToken_ == _ETH) {
            // clipperExchange.sellEthForToken{value: inputAmount}(address(dstToken), inputAmount, outputAmount, goodUntil, recipient, signature, _INCH_TAG);
            address clipper = address(clipperExchange);
            bytes4 selector = clipperExchange.sellEthForToken.selector;
            assembly ("memory-safe") {
                // solhint-disable-line no-inline-assembly
                let ptr := mload(0x40)

                mstore(ptr, selector)
                mstore(add(ptr, 0x04), dstToken)
                mstore(add(ptr, 0x24), inputAmount)
                mstore(add(ptr, 0x44), outputAmount)
                mstore(add(ptr, 0x64), goodUntil)
                mstore(add(ptr, 0x84), recipient)
                mstore(add(ptr, 0xa4), add(27, shr(_SIGNATURE_V_SHIFT, vs)))
                mstore(add(ptr, 0xc4), r)
                mstore(add(ptr, 0xe4), and(vs, _SIGNATURE_S_MASK))
                mstore(add(ptr, 0x104), 0x120)
                mstore(add(ptr, 0x124), _INCH_TAG_LENGTH)
                mstore(add(ptr, 0x144), _INCH_TAG)
                if iszero(call(gas(), clipper, inputAmount, ptr, 0x149, 0, 0)) {
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }
            }
        } else if (dstToken == _ETH) {
            // clipperExchange.sellTokenForEth(address(srcToken_), inputAmount, outputAmount, goodUntil, recipient, signature, _INCH_TAG);
            address clipper = address(clipperExchange);
            bytes4 selector = clipperExchange.sellTokenForEth.selector;
            assembly ("memory-safe") {
                // solhint-disable-line no-inline-assembly
                let ptr := mload(0x40)

                mstore(ptr, selector)
                mstore(add(ptr, 0x04), srcToken_)
                mstore(add(ptr, 0x24), inputAmount)
                mstore(add(ptr, 0x44), outputAmount)
                mstore(add(ptr, 0x64), goodUntil)
                switch iszero(dstToken)
                case 1 { mstore(add(ptr, 0x84), recipient) }
                default { mstore(add(ptr, 0x84), address()) }
                mstore(add(ptr, 0xa4), add(27, shr(_SIGNATURE_V_SHIFT, vs)))
                mstore(add(ptr, 0xc4), r)
                mstore(add(ptr, 0xe4), and(vs, _SIGNATURE_S_MASK))
                mstore(add(ptr, 0x104), 0x120)
                mstore(add(ptr, 0x124), _INCH_TAG_LENGTH)
                mstore(add(ptr, 0x144), _INCH_TAG)
                if iszero(call(gas(), clipper, 0, ptr, 0x149, 0, 0)) {
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }
            }
        } else {
            // clipperExchange.swap(address(srcToken_), address(dstToken), inputAmount, outputAmount, goodUntil, recipient, signature, _INCH_TAG);
            address clipper = address(clipperExchange);
            bytes4 selector = clipperExchange.swap.selector;
            assembly ("memory-safe") {
                // solhint-disable-line no-inline-assembly
                let ptr := mload(0x40)

                mstore(ptr, selector)
                mstore(add(ptr, 0x04), srcToken_)
                mstore(add(ptr, 0x24), dstToken)
                mstore(add(ptr, 0x44), inputAmount)
                mstore(add(ptr, 0x64), outputAmount)
                mstore(add(ptr, 0x84), goodUntil)
                mstore(add(ptr, 0xa4), recipient)
                mstore(add(ptr, 0xc4), add(27, shr(_SIGNATURE_V_SHIFT, vs)))
                mstore(add(ptr, 0xe4), r)
                mstore(add(ptr, 0x104), and(vs, _SIGNATURE_S_MASK))
                mstore(add(ptr, 0x124), 0x140)
                mstore(add(ptr, 0x144), _INCH_TAG_LENGTH)
                mstore(add(ptr, 0x164), _INCH_TAG)
                if iszero(call(gas(), clipper, 0, ptr, 0x169, 0, 0)) {
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }
            }
        }

        return outputAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "./libraries/SafeERC20.sol";

abstract contract PermitAndCall {
    using SafeERC20 for IERC20;

    function permitAndCall(bytes calldata permit, bytes calldata action) external payable {
        IERC20(address(bytes20(permit))).tryPermit(permit[20:]);
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            calldatacopy(ptr, action.offset, action.length)
            let success := delegatecall(gas(), address(), ptr, action.length, 0, 0)
            returndatacopy(ptr, 0, returndatasize())
            switch success
            case 0 {
                revert(ptr, returndatasize())
            }
            default {
                return(ptr, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {IAggregationExecutor} from "../interfaces/IAggregationExecutor.sol";
import {Errors} from "@1inch/limit-order-protocol-contract/contracts/libraries/Errors.sol";
import {UniERC20} from "@1inch/solidity-utils/contracts/libraries/UniERC20.sol";
import {RouterErrors} from "../helpers/RouterErrors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EthReceiver} from "@1inch/solidity-utils/contracts/EthReceiver.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import {GenericRouter} from "./GenericRouter.sol";

contract GenericRouterDelegator is EthReceiver, GenericRouter {
    using UniERC20 for IERC20;
    using SafeERC20 for IERC20;

    uint256 private constant _USE_PERMIT2 = 1 << 2;

    address payable public immutable oneInchRouterV6;

    constructor(address payable _oneInchRouterV6) {
        oneInchRouterV6 = _oneInchRouterV6;
    }

    function swapDelegate(IAggregationExecutor executor, SwapDescription memory desc, bytes calldata data)
        external
        payable
    {
        IERC20 srcToken = desc.srcToken;
        bool srcETH = srcToken.isETH();
        bool usePermit2 = desc.flags & _USE_PERMIT2 != 0;

        if (!srcETH) {
            srcToken.safeTransferFromUniversal(msg.sender, address(this), desc.amount, usePermit2);
            srcToken.forceApprove(oneInchRouterV6, desc.amount);
            uint256 newBalance = srcToken.balanceOf(address(this));
            if (newBalance < desc.amount) {
                revert RouterErrors.TaxTokenDetected();
            }
        }

        desc.flags &= ~_USE_PERMIT2;
        desc.dstReceiver = (desc.dstReceiver == address(0)) ? payable(msg.sender) : desc.dstReceiver;

        GenericRouterDelegator(oneInchRouterV6).swap{value: msg.value}(executor, desc, data);
    }

    function swapDelegateTax(IAggregationExecutor executor, SwapDescription memory desc, bytes calldata data)
        external
        payable
    {
        IERC20 srcToken = desc.srcToken;
        bool srcETH = srcToken.isETH();
        bool usePermit2 = desc.flags & _USE_PERMIT2 != 0;

        if (!srcETH) {
            srcToken.safeTransferFromUniversal(msg.sender, address(this), desc.amount, usePermit2);
            srcToken.forceApprove(oneInchRouterV6, desc.amount);
            uint256 newBalance = srcToken.balanceOf(address(this));
            if (newBalance < desc.amount) {
                desc.minReturnAmount -= (desc.minReturnAmount * (desc.amount - newBalance)) / desc.amount + 1;
                desc.amount = newBalance;
            }
        }

        desc.flags &= ~_USE_PERMIT2;
        desc.dstReceiver = (desc.dstReceiver == address(0)) ? payable(msg.sender) : desc.dstReceiver;

        GenericRouterDelegator(oneInchRouterV6).swap{value: msg.value}(executor, desc, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {AddressLib} from "@1inch/solidity-utils/contracts/libraries/AddressLib.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import {Errors} from "@1inch/limit-order-protocol-contract/contracts/libraries/Errors.sol";
import {RouterErrors} from "../helpers/RouterErrors.sol";
import {IUniswapV3SwapCallback} from "../interfaces/IUniswapV3SwapCallback.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EthReceiver} from "@1inch/solidity-utils/contracts/EthReceiver.sol";
import {IUniswapV3Pool} from "../interfaces/IUniswapV3Pool.sol";
import {IPermit2} from "@1inch/solidity-utils/contracts/interfaces/IPermit2.sol";
import {IWETH} from "@1inch/solidity-utils/contracts/interfaces/IWETH.sol";
import {ProtocolLib, Address} from "../libs/ProtocolLib.sol";

contract UnoswapRouterArbitrumOne is EthReceiver, IUniswapV3SwapCallback {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;
    using AddressLib for Address;
    using ProtocolLib for Address;

    error BadPool();
    error BadCurveSwapSelector();

    /// @dev WETH address is network-specific and needs to be changed before deployment.
    /// It can not be moved to immutable as immutables are not supported in assembly
    address private constant _WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address private constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant _PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    bytes4 private constant _WETH_DEPOSIT_CALL_SELECTOR = 0xd0e30db0;
    bytes4 private constant _WETH_WITHDRAW_CALL_SELECTOR = 0x2e1a7d4d;
    uint256 private constant _ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    uint256 private constant _SELECTORS = (
        (uint256(uint32(IUniswapV3Pool.token0.selector)) << 224)
            | (uint256(uint32(IUniswapV3Pool.token1.selector)) << 192)
            | (uint256(uint32(IUniswapV3Pool.fee.selector)) << 160) | (uint256(uint32(IERC20.transfer.selector)) << 128)
            | (uint256(uint32(IERC20.transferFrom.selector)) << 96)
            | (uint256(uint32(IPermit2.transferFrom.selector)) << 64)
    );

    uint256 private constant _TOKEN0_SELECTOR_OFFSET = 0;
    uint256 private constant _TOKEN1_SELECTOR_OFFSET = 4;
    uint256 private constant _FEE_SELECTOR_OFFSET = 8;
    uint256 private constant _TRANSFER_SELECTOR_OFFSET = 12;
    uint256 private constant _TRANSFER_FROM_SELECTOR_OFFSET = 16;
    uint256 private constant _PERMIT2_TRANSFER_FROM_SELECTOR_OFFSET = 20;

    bytes32 private constant _POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
    bytes32 private constant _FF_FACTORY = 0xff1F98431c8aD98523631AE4a59f267346ea31F9840000000000000000000000;

    // =====================================================================
    //                          Methods with 1 pool
    // =====================================================================

    /**
     * @notice Swaps `amount` of the specified `token` for another token using an Unoswap-compatible exchange's pool,
     *         with a minimum return specified by `minReturn`.
     * @param token The address of the token to be swapped.
     * @param amount The amount of tokens to be swapped.
     * @param minReturn The minimum amount of tokens to be received after the swap.
     * @param dex The address of the Unoswap-compatible exchange's pool.
     * @return returnAmount The actual amount of tokens received after the swap.
     */
    function unoswap(Address token, uint256 amount, uint256 minReturn, Address dex)
        external
        returns (uint256 returnAmount)
    {
        returnAmount = _unoswapTo(msg.sender, msg.sender, token, amount, minReturn, dex);
    }

    /**
     * @notice Swaps `amount` of the specified `token` for another token using an Unoswap-compatible exchange's pool,
     *         sending the resulting tokens to the `to` address, with a minimum return specified by `minReturn`.
     * @param to The address to receive the swapped tokens.
     * @param token The address of the token to be swapped.
     * @param amount The amount of tokens to be swapped.
     * @param minReturn The minimum amount of tokens to be received after the swap.
     * @param dex The address of the Unoswap-compatible exchange's pool.
     * @return returnAmount The actual amount of tokens received after the swap.
     */
    function unoswapTo(Address to, Address token, uint256 amount, uint256 minReturn, Address dex)
        external
        returns (uint256 returnAmount)
    {
        returnAmount = _unoswapTo(msg.sender, to.get(), token, amount, minReturn, dex);
    }

    /**
     * @notice Swaps ETH for another token using an Unoswap-compatible exchange's pool, with a minimum return specified by `minReturn`.
     *         The function is payable and requires the sender to attach ETH.
     *         It is necessary to check if it's cheaper to use _WETH_NOT_WRAP_FLAG in `dex` Address (for example: for Curve pools).
     * @param minReturn The minimum amount of tokens to be received after the swap.
     * @param dex The address of the Unoswap-compatible exchange's pool.
     * @return returnAmount The actual amount of tokens received after the swap.
     */
    function ethUnoswap(uint256 minReturn, Address dex) external payable returns (uint256 returnAmount) {
        if (dex.shouldWrapWeth()) {
            IWETH(_WETH).safeDeposit(msg.value);
        }
        returnAmount = _unoswapTo(address(this), msg.sender, Address.wrap(uint160(_WETH)), msg.value, minReturn, dex);
    }

    /**
     * @notice Swaps ETH for another token using an Unoswap-compatible exchange's pool, sending the resulting tokens to the `to` address,
     *         with a minimum return specified by `minReturn`. The function is payable and requires the sender to attach ETH.
     *         It is necessary to check if it's cheaper to use _WETH_NOT_WRAP_FLAG in `dex` Address (for example: for Curve pools).
     * @param to The address to receive the swapped tokens.
     * @param minReturn The minimum amount of tokens to be received after the swap.
     * @param dex The address of the Unoswap-compatible exchange's pool.
     * @return returnAmount The actual amount of tokens received after the swap.
     */
    function ethUnoswapTo(Address to, uint256 minReturn, Address dex) external payable returns (uint256 returnAmount) {
        if (dex.shouldWrapWeth()) {
            IWETH(_WETH).safeDeposit(msg.value);
        }
        returnAmount = _unoswapTo(address(this), to.get(), Address.wrap(uint160(_WETH)), msg.value, minReturn, dex);
    }

    function _unoswapTo(address from, address to, Address token, uint256 amount, uint256 minReturn, Address dex)
        private
        returns (uint256 returnAmount)
    {
        if (dex.shouldUnwrapWeth()) {
            returnAmount = _unoswap(from, address(this), token, amount, minReturn, dex);
            IWETH(_WETH).safeWithdrawTo(returnAmount, to);
        } else {
            returnAmount = _unoswap(from, to, token, amount, minReturn, dex);
        }
    }

    // =====================================================================
    //                    Methods with 2 sequential pools
    // =====================================================================

    /**
     * @notice Swaps `amount` of the specified `token` for another token using two Unoswap-compatible exchange pools (`dex` and `dex2`) sequentially,
     *         with a minimum return specified by `minReturn`.
     * @param token The address of the token to be swapped.
     * @param amount The amount of tokens to be swapped.
     * @param minReturn The minimum amount of tokens to be received after the swap.
     * @param dex The address of the first Unoswap-compatible exchange's pool.
     * @param dex2 The address of the second Unoswap-compatible exchange's pool.
     * @return returnAmount The actual amount of tokens received after the swap through both pools.
     */
    function unoswap2(Address token, uint256 amount, uint256 minReturn, Address dex, Address dex2)
        external
        returns (uint256 returnAmount)
    {
        returnAmount = _unoswapTo2(msg.sender, msg.sender, token, amount, minReturn, dex, dex2);
    }

    /**
     * @notice Swaps `amount` of the specified `token` for another token using two Unoswap-compatible exchange pools (`dex` and `dex2`) sequentially,
     *         sending the resulting tokens to the `to` address, with a minimum return specified by `minReturn`.
     * @param to The address to receive the swapped tokens.
     * @param token The address of the token to be swapped.
     * @param amount The amount of tokens to be swapped.
     * @param minReturn The minimum amount of tokens to be received after the swap.
     * @param dex The address of the first Unoswap-compatible exchange's pool.
     * @param dex2 The address of the second Unoswap-compatible exchange's pool.
     * @return returnAmount The actual amount of tokens received after the swap through both pools.
     */
    function unoswapTo2(Address to, Address token, uint256 amount, uint256 minReturn, Address dex, Address dex2)
        external
        returns (uint256 returnAmount)
    {
        returnAmount = _unoswapTo2(msg.sender, to.get(), token, amount, minReturn, dex, dex2);
    }

    /**
     * @notice Swaps ETH for another token using two Unoswap-compatible exchange pools (`dex` and `dex2`) sequentially,
     *         with a minimum return specified by `minReturn`. The function is payable and requires the sender to attach ETH.
     *         It is necessary to check if it's cheaper to use _WETH_NOT_WRAP_FLAG in `dex` Address (for example: for Curve pools).
     * @param minReturn The minimum amount of tokens to be received after the swap.
     * @param dex The address of the first Unoswap-compatible exchange's pool.
     * @param dex2 The address of the second Unoswap-compatible exchange's pool.
     * @return returnAmount The actual amount of tokens received after the swap through both pools.
     */
    function ethUnoswap2(uint256 minReturn, Address dex, Address dex2)
        external
        payable
        returns (uint256 returnAmount)
    {
        if (dex.shouldWrapWeth()) {
            IWETH(_WETH).safeDeposit(msg.value);
        }
        returnAmount =
            _unoswapTo2(address(this), msg.sender, Address.wrap(uint160(_WETH)), msg.value, minReturn, dex, dex2);
    }

    /**
     * @notice Swaps ETH for another token using two Unoswap-compatible exchange pools (`dex` and `dex2`) sequentially,
     *         sending the resulting tokens to the `to` address, with a minimum return specified by `minReturn`.
     *         The function is payable and requires the sender to attach ETH.
     *         It is necessary to check if it's cheaper to use _WETH_NOT_WRAP_FLAG in `dex` Address (for example: for Curve pools).
     * @param to The address to receive the swapped tokens.
     * @param minReturn The minimum amount of tokens to be received after the swap.
     * @param dex The address of the first Unoswap-compatible exchange's pool.
     * @param dex2 The address of the second Unoswap-compatible exchange's pool.
     * @return returnAmount The actual amount of tokens received after the swap through both pools.
     */
    function ethUnoswapTo2(Address to, uint256 minReturn, Address dex, Address dex2)
        external
        payable
        returns (uint256 returnAmount)
    {
        if (dex.shouldWrapWeth()) {
            IWETH(_WETH).safeDeposit(msg.value);
        }
        returnAmount =
            _unoswapTo2(address(this), to.get(), Address.wrap(uint160(_WETH)), msg.value, minReturn, dex, dex2);
    }

    function _unoswapTo2(
        address from,
        address to,
        Address token,
        uint256 amount,
        uint256 minReturn,
        Address dex,
        Address dex2
    ) private returns (uint256 returnAmount) {
        address pool2 = dex2.addressForPreTransfer();
        address target = dex2.shouldUnwrapWeth() ? address(this) : to;
        returnAmount = _unoswap(from, pool2, token, amount, 0, dex);
        returnAmount = _unoswap(pool2, target, Address.wrap(0), returnAmount, minReturn, dex2);
        if (dex2.shouldUnwrapWeth()) {
            IWETH(_WETH).safeWithdrawTo(returnAmount, to);
        }
    }

    // =====================================================================
    //                    Methods with 3 sequential pools
    // =====================================================================

    /**
     * @notice Swaps `amount` of the specified `token` for another token using three Unoswap-compatible exchange pools
     *         (`dex`, `dex2`, and `dex3`) sequentially, with a minimum return specified by `minReturn`.
     * @param token The address of the token to be swapped.
     * @param amount The amount of tokens to be swapped.
     * @param minReturn The minimum amount of tokens to be received after the swap.
     * @param dex The address of the first Unoswap-compatible exchange's pool.
     * @param dex2 The address of the second Unoswap-compatible exchange's pool.
     * @param dex3 The address of the third Unoswap-compatible exchange's pool.
     * @return returnAmount The actual amount of tokens received after the swap through all three pools.
     */
    function unoswap3(Address token, uint256 amount, uint256 minReturn, Address dex, Address dex2, Address dex3)
        external
        returns (uint256 returnAmount)
    {
        returnAmount = _unoswapTo3(msg.sender, msg.sender, token, amount, minReturn, dex, dex2, dex3);
    }

    /**
     * @notice Swaps `amount` of the specified `token` for another token using three Unoswap-compatible exchange pools
     *         (`dex`, `dex2`, and `dex3`) sequentially, sending the resulting tokens to the `to` address, with a minimum return specified by `minReturn`.
     * @param to The address to receive the swapped tokens.
     * @param token The address of the token to be swapped.
     * @param amount The amount of tokens to be swapped.
     * @param minReturn The minimum amount of tokens to be received after the swap.
     * @param dex The address of the first Unoswap-compatible exchange's pool.
     * @param dex2 The address of the second Unoswap-compatible exchange's pool.
     * @param dex3 The address of the third Unoswap-compatible exchange's pool.
     * @return returnAmount The actual amount of tokens received after the swap through all three pools.
     */
    function unoswapTo3(
        Address to,
        Address token,
        uint256 amount,
        uint256 minReturn,
        Address dex,
        Address dex2,
        Address dex3
    ) external returns (uint256 returnAmount) {
        returnAmount = _unoswapTo3(msg.sender, to.get(), token, amount, minReturn, dex, dex2, dex3);
    }

    /**
     * @notice Swaps ETH for another token using three Unoswap-compatible exchange pools (`dex`, `dex2`, and `dex3`) sequentially,
     *         with a minimum return specified by `minReturn`. The function is payable and requires the sender to attach ETH.
     *         It is necessary to check if it's cheaper to use _WETH_NOT_WRAP_FLAG in `dex` Address (for example: for Curve pools).
     * @param minReturn The minimum amount of tokens to be received after the swap.
     * @param dex The address of the first Unoswap-compatible exchange's pool.
     * @param dex2 The address of the second Unoswap-compatible exchange's pool.
     * @param dex3 The address of the third Unoswap-compatible exchange's pool.
     * @return returnAmount The actual amount of tokens received after the swap through all three pools.
     */
    function ethUnoswap3(uint256 minReturn, Address dex, Address dex2, Address dex3)
        external
        payable
        returns (uint256 returnAmount)
    {
        if (dex.shouldWrapWeth()) {
            IWETH(_WETH).safeDeposit(msg.value);
        }
        returnAmount =
            _unoswapTo3(address(this), msg.sender, Address.wrap(uint160(_WETH)), msg.value, minReturn, dex, dex2, dex3);
    }

    /**
     * @notice Swaps ETH for another token using three Unoswap-compatible exchange pools (`dex`, `dex2`, and `dex3`) sequentially,
     *         sending the resulting tokens to the `to` address, with a minimum return specified by `minReturn`.
     *         The function is payable and requires the sender to attach ETH.
     *         It is necessary to check if it's cheaper to use _WETH_NOT_WRAP_FLAG in `dex` Address (for example: for Curve pools).
     * @param to The address to receive the swapped tokens.
     * @param minReturn The minimum amount of tokens to be received after the swap.
     * @param dex The address of the first Unoswap-compatible exchange's pool.
     * @param dex2 The address of the second Unoswap-compatible exchange's pool.
     * @param dex3 The address of the third Unoswap-compatible exchange's pool.
     * @return returnAmount The actual amount of tokens received after the swap through all three pools.
     */
    function ethUnoswapTo3(Address to, uint256 minReturn, Address dex, Address dex2, Address dex3)
        external
        payable
        returns (uint256 returnAmount)
    {
        if (dex.shouldWrapWeth()) {
            IWETH(_WETH).safeDeposit(msg.value);
        }
        returnAmount =
            _unoswapTo3(address(this), to.get(), Address.wrap(uint160(_WETH)), msg.value, minReturn, dex, dex2, dex3);
    }

    function _unoswapTo3(
        address from,
        address to,
        Address token,
        uint256 amount,
        uint256 minReturn,
        Address dex,
        Address dex2,
        Address dex3
    ) private returns (uint256 returnAmount) {
        address pool2 = dex2.addressForPreTransfer();
        address pool3 = dex3.addressForPreTransfer();
        address target = dex3.shouldUnwrapWeth() ? address(this) : to;
        returnAmount = _unoswap(from, pool2, token, amount, 0, dex);
        returnAmount = _unoswap(pool2, pool3, Address.wrap(0), returnAmount, 0, dex2);
        returnAmount = _unoswap(pool3, target, Address.wrap(0), returnAmount, minReturn, dex3);
        if (dex3.shouldUnwrapWeth()) {
            IWETH(_WETH).safeWithdrawTo(returnAmount, to);
        }
    }

    function _unoswap(address spender, address recipient, Address token, uint256 amount, uint256 minReturn, Address dex)
        private
        returns (uint256 returnAmount)
    {
        ProtocolLib.Protocol protocol = dex.protocol();
        if (protocol == ProtocolLib.Protocol.UniswapV3) {
            returnAmount = _unoswapV3(spender, recipient, amount, minReturn, dex);
        } else if (protocol == ProtocolLib.Protocol.UniswapV2) {
            if (spender == address(this)) {
                IERC20(token.get()).safeTransfer(dex.get(), amount);
            } else if (spender == msg.sender) {
                IERC20(token.get()).safeTransferFromUniversal(msg.sender, dex.get(), amount, dex.usePermit2());
            }
            returnAmount = _unoswapV2(recipient, amount, minReturn, dex);
        } else if (protocol == ProtocolLib.Protocol.Curve) {
            if (spender == msg.sender && msg.value == 0) {
                IERC20(token.get()).safeTransferFromUniversal(msg.sender, address(this), amount, dex.usePermit2());
            }
            returnAmount = _curfe(recipient, amount, minReturn, dex);
        }
    }

    uint256 private constant _UNISWAP_V2_ZERO_FOR_ONE_OFFSET = 247;
    uint256 private constant _UNISWAP_V2_ZERO_FOR_ONE_MASK = 0x01;
    uint256 private constant _UNISWAP_V2_NUMERATOR_OFFSET = 160;
    uint256 private constant _UNISWAP_V2_NUMERATOR_MASK = 0xffffffff;

    bytes4 private constant _UNISWAP_V2_PAIR_RESERVES_CALL_SELECTOR = 0x0902f1ac;
    bytes4 private constant _UNISWAP_V2_PAIR_SWAP_CALL_SELECTOR = 0x022c0d9f;
    uint256 private constant _UNISWAP_V2_DENOMINATOR = 1e9;
    uint256 private constant _UNISWAP_V2_DEFAULT_NUMERATOR = 997_000_000;

    error ReservesCallFailed();

    function _unoswapV2(address recipient, uint256 amount, uint256 minReturn, Address dex)
        private
        returns (uint256 ret)
    {
        bytes4 returnAmountNotEnoughException = RouterErrors.ReturnAmountIsNotEnough.selector;
        bytes4 reservesCallFailedException = ReservesCallFailed.selector;
        assembly ("memory-safe") {
            // solhint-disable-line no-inline-assembly
            let pool := and(dex, _ADDRESS_MASK)
            let zeroForOne := and(shr(_UNISWAP_V2_ZERO_FOR_ONE_OFFSET, dex), _UNISWAP_V2_ZERO_FOR_ONE_MASK)
            let numerator := and(shr(_UNISWAP_V2_NUMERATOR_OFFSET, dex), _UNISWAP_V2_NUMERATOR_MASK)
            if iszero(numerator) { numerator := _UNISWAP_V2_DEFAULT_NUMERATOR }

            let ptr := mload(0x40)

            mstore(0, _UNISWAP_V2_PAIR_RESERVES_CALL_SELECTOR)
            if iszero(staticcall(gas(), pool, 0, 4, 0, 0x40)) {
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
            if sub(returndatasize(), 0x60) {
                mstore(0, reservesCallFailedException)
                revert(0, 4)
            }

            let reserve0 := mload(mul(0x20, iszero(zeroForOne)))
            let reserve1 := mload(mul(0x20, zeroForOne))
            // this will not overflow as reserve0, reserve1 and ret fit to 112 bit and numerator and _DENOMINATOR fit to 32 bit
            ret := mul(amount, numerator)
            ret := div(mul(ret, reserve1), add(ret, mul(reserve0, _UNISWAP_V2_DENOMINATOR)))

            if lt(ret, minReturn) {
                mstore(ptr, returnAmountNotEnoughException)
                mstore(add(ptr, 0x04), ret)
                mstore(add(ptr, 0x24), minReturn)
                revert(ptr, 0x44)
            }

            mstore(ptr, _UNISWAP_V2_PAIR_SWAP_CALL_SELECTOR)
            mstore(add(ptr, 0x04), mul(ret, iszero(zeroForOne)))
            mstore(add(ptr, 0x24), mul(ret, zeroForOne))
            mstore(add(ptr, 0x44), recipient)
            mstore(add(ptr, 0x64), 0x80)
            mstore(add(ptr, 0x84), 0)
            if iszero(call(gas(), pool, 0, ptr, 0xa4, 0, 0)) {
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 private constant _UNISWAP_V3_MIN_SQRT_RATIO = 4295128739 + 1;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 private constant _UNISWAP_V3_MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342 - 1;
    uint256 private constant _UNISWAP_V3_ZERO_FOR_ONE_OFFSET = 247;
    uint256 private constant _UNISWAP_V3_ZERO_FOR_ONE_MASK = 0x01;

    function _unoswapV3(address spender, address recipient, uint256 amount, uint256 minReturn, Address dex)
        private
        returns (uint256 ret)
    {
        bytes4 swapSelector = IUniswapV3Pool.swap.selector;
        bool usePermit2 = dex.usePermit2();
        assembly ("memory-safe") {
            // solhint-disable-line no-inline-assembly
            let pool := and(dex, _ADDRESS_MASK)
            let zeroForOne := and(shr(_UNISWAP_V3_ZERO_FOR_ONE_OFFSET, dex), _UNISWAP_V3_ZERO_FOR_ONE_MASK)

            let ptr := mload(0x40)
            mstore(ptr, swapSelector)
            mstore(add(ptr, 0x04), recipient)
            mstore(add(ptr, 0x24), zeroForOne)
            mstore(add(ptr, 0x44), amount)
            switch zeroForOne
            case 1 { mstore(add(ptr, 0x64), _UNISWAP_V3_MIN_SQRT_RATIO) }
            case 0 { mstore(add(ptr, 0x64), _UNISWAP_V3_MAX_SQRT_RATIO) }
            mstore(add(ptr, 0x84), 0xa0)
            mstore(add(ptr, 0xa4), 0x40)
            mstore(add(ptr, 0xc4), spender)
            mstore(add(ptr, 0xe4), usePermit2)
            if iszero(call(gas(), pool, 0, ptr, 0x0104, 0, 0x40)) {
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
            ret := sub(0, mload(mul(0x20, zeroForOne)))
        }
        if (ret < minReturn) {
            revert RouterErrors.ReturnAmountIsNotEnough(ret, minReturn);
        }
    }

    uint256 private constant _CURVE_SWAP_SELECTOR_IDX_OFFSET = 184;
    uint256 private constant _CURVE_SWAP_SELECTOR_IDX_MASK = 0xff;
    uint256 private constant _CURVE_FROM_COINS_SELECTOR_OFFSET = 192;
    uint256 private constant _CURVE_FROM_COINS_SELECTOR_MASK = 0xff;
    uint256 private constant _CURVE_FROM_COINS_ARG_OFFSET = 200;
    uint256 private constant _CURVE_FROM_COINS_ARG_MASK = 0xff;
    uint256 private constant _CURVE_TO_COINS_SELECTOR_OFFSET = 208;
    uint256 private constant _CURVE_TO_COINS_SELECTOR_MASK = 0xff;
    uint256 private constant _CURVE_TO_COINS_ARG_OFFSET = 216;
    uint256 private constant _CURVE_TO_COINS_ARG_MASK = 0xff;
    uint256 private constant _CURVE_FROM_TOKEN_OFFSET = 224;
    uint256 private constant _CURVE_FROM_TOKEN_MASK = 0xff;
    uint256 private constant _CURVE_TO_TOKEN_OFFSET = 232;
    uint256 private constant _CURVE_TO_TOKEN_MASK = 0xff;

    uint256 private constant _CURVE_INPUT_WETH_DEPOSIT_OFFSET = 240;
    uint256 private constant _CURVE_INPUT_WETH_WITHDRAW_OFFSET = 241;
    uint256 private constant _CURVE_SWAP_USE_ETH_OFFSET = 242;
    uint256 private constant _CURVE_SWAP_HAS_ARG_USE_ETH_OFFSET = 243;
    uint256 private constant _CURVE_SWAP_HAS_ARG_DESTINATION_OFFSET = 244;
    uint256 private constant _CURVE_OUTPUT_WETH_DEPOSIT_OFFSET = 245;
    uint256 private constant _CURVE_OUTPUT_WETH_WITHDRAW_OFFSET = 246;
    uint256 private constant _CURVE_SWAP_USE_SECOND_OUTPUT_OFFSET = 247;
    uint256 private constant _CURVE_SWAP_HAS_ARG_CALLBACK_OFFSET = 249;

    // Curve Pool function selectors for different `coins` methods. For details, see contracts/interfaces/ICurvePool.sol
    bytes32 private constant _CURVE_COINS_SELECTORS = 0x87cb4f5723746eb8c6610657b739953eb9947eb0000000000000000000000000;
    // Curve Pool function selectors for different `exchange` methods. For details, see contracts/interfaces/ICurvePool.sol
    bytes32 private constant _CURVE_SWAP_SELECTORS_1 =
        0x3df02124a6417ed6ddc1f59d44ee1986ed4ae2b8bf5ed0562f7865a837cab679;
    bytes32 private constant _CURVE_SWAP_SELECTORS_2 =
        0x2a064e3c5b41b90865b2489ba64833a0e2ad025a394747c5cb7558f1ce7d6503;
    bytes32 private constant _CURVE_SWAP_SELECTORS_3 =
        0xd2e2833add96994f000000000000000000000000000000000000000000000000;
    uint256 private constant _CURVE_MAX_SELECTOR_INDEX = 17;

    function _curfe(address recipient, uint256 amount, uint256 minReturn, Address dex) private returns (uint256 ret) {
        bytes4 callbackSelector = this.curveSwapCallback.selector;
        assembly ("memory-safe") {
            // solhint-disable-line no-inline-assembly
            function reRevert() {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }

            function callReturnSize(status) -> rds {
                if iszero(status) { reRevert() }
                rds := returndatasize()
            }

            function tokenBalanceOf(tokenAddress, accountAddress) -> tokenBalance {
                mstore(0, 0x70a0823100000000000000000000000000000000000000000000000000000000)
                mstore(4, accountAddress)
                if iszero(callReturnSize(staticcall(gas(), tokenAddress, 0, 0x24, 0, 0x20))) { revert(0, 0) }
                tokenBalance := mload(0)
            }

            function asmApprove(token, to, value, mem) {
                let selector := 0x095ea7b300000000000000000000000000000000000000000000000000000000 // IERC20.approve.selector
                let exception := 0x3e3f8f7300000000000000000000000000000000000000000000000000000000 // error ApproveFailed()
                if iszero(_asmCall(token, selector, to, value, mem)) {
                    if iszero(_asmCall(token, selector, to, 0, mem)) {
                        mstore(mem, exception)
                        revert(mem, 4)
                    }
                    if iszero(_asmCall(token, selector, to, value, mem)) {
                        mstore(mem, exception)
                        revert(mem, 4)
                    }
                }
            }

            function _asmCall(token, selector, to, value, mem) -> done {
                mstore(mem, selector)
                mstore(add(mem, 0x04), to)
                mstore(add(mem, 0x24), value)
                let success := call(gas(), token, 0, mem, 0x44, 0x0, 0x20)
                done := and(success, or(iszero(returndatasize()), and(gt(returndatasize(), 31), eq(mload(0), 1))))
            }

            function curveCoins(pool, selectorOffset, index) -> coin {
                mstore(0, _CURVE_COINS_SELECTORS)
                mstore(add(selectorOffset, 4), index)
                if iszero(staticcall(gas(), pool, selectorOffset, 0x24, 0, 0x20)) { reRevert() }
                coin := mload(0)
            }

            let pool := and(dex, _ADDRESS_MASK)
            let useEth := and(shr(_CURVE_SWAP_USE_ETH_OFFSET, dex), 0x01)
            let hasCallback := and(shr(_CURVE_SWAP_HAS_ARG_CALLBACK_OFFSET, dex), 0x01)

            if and(shr(_CURVE_INPUT_WETH_DEPOSIT_OFFSET, dex), 0x01) {
                // Deposit ETH to WETH
                mstore(0, _WETH_DEPOSIT_CALL_SELECTOR)
                if iszero(call(gas(), _WETH, amount, 0, 4, 0, 0)) { reRevert() }
            }

            if and(shr(_CURVE_INPUT_WETH_WITHDRAW_OFFSET, dex), 0x01) {
                // Withdraw ETH from WETH
                mstore(0, _WETH_WITHDRAW_CALL_SELECTOR)
                mstore(4, amount)
                if iszero(call(gas(), _WETH, 0, 0, 0x24, 0, 0)) { reRevert() }
            }

            let toToken
            {
                // Stack too deep
                let toSelectorOffset := and(shr(_CURVE_TO_COINS_SELECTOR_OFFSET, dex), _CURVE_TO_COINS_SELECTOR_MASK)
                let toTokenIndex := and(shr(_CURVE_TO_COINS_ARG_OFFSET, dex), _CURVE_TO_COINS_ARG_MASK)
                toToken := curveCoins(pool, toSelectorOffset, toTokenIndex)
            }
            let toTokenIsEth := or(eq(toToken, _ETH), eq(toToken, _WETH))

            // use approve when the callback is not used AND (raw ether is not used at all OR ether is used on the output)
            if and(iszero(hasCallback), or(iszero(useEth), toTokenIsEth)) {
                let fromSelectorOffset :=
                    and(shr(_CURVE_FROM_COINS_SELECTOR_OFFSET, dex), _CURVE_FROM_COINS_SELECTOR_MASK)
                let fromTokenIndex := and(shr(_CURVE_FROM_COINS_ARG_OFFSET, dex), _CURVE_FROM_COINS_ARG_MASK)
                let fromToken := curveCoins(pool, fromSelectorOffset, fromTokenIndex)
                if eq(fromToken, _ETH) { fromToken := _WETH }
                asmApprove(fromToken, pool, amount, mload(0x40))
            }

            // Swap
            let ptr := mload(0x40)
            {
                // stack too deep
                let selectorIndex := and(shr(_CURVE_SWAP_SELECTOR_IDX_OFFSET, dex), _CURVE_SWAP_SELECTOR_IDX_MASK)
                if gt(selectorIndex, _CURVE_MAX_SELECTOR_INDEX) {
                    mstore(0, 0xa231cb8200000000000000000000000000000000000000000000000000000000) // BadCurveSwapSelector()
                    revert(0, 4)
                }
                mstore(ptr, _CURVE_SWAP_SELECTORS_1)
                mstore(add(ptr, 0x20), _CURVE_SWAP_SELECTORS_2)
                mstore(add(ptr, 0x40), _CURVE_SWAP_SELECTORS_3)
                ptr := add(ptr, mul(selectorIndex, 4))
            }
            mstore(add(ptr, 0x04), and(shr(_CURVE_FROM_TOKEN_OFFSET, dex), _CURVE_FROM_TOKEN_MASK))
            mstore(add(ptr, 0x24), and(shr(_CURVE_TO_TOKEN_OFFSET, dex), _CURVE_TO_TOKEN_MASK))
            mstore(add(ptr, 0x44), amount)
            mstore(add(ptr, 0x64), minReturn)
            let offset := 0x84
            if and(shr(_CURVE_SWAP_HAS_ARG_USE_ETH_OFFSET, dex), 0x01) {
                mstore(add(ptr, offset), useEth)
                offset := add(offset, 0x20)
            }
            switch hasCallback
            case 1 {
                mstore(add(ptr, offset), address())
                mstore(add(ptr, add(offset, 0x20)), recipient)
                mstore(add(ptr, add(offset, 0x40)), callbackSelector)
                offset := add(offset, 0x60)
            }
            default {
                if and(shr(_CURVE_SWAP_HAS_ARG_DESTINATION_OFFSET, dex), 0x01) {
                    mstore(add(ptr, offset), recipient)
                    offset := add(offset, 0x20)
                }
            }

            // swap call
            // value is passed when useEth is set but toToken is not ETH
            switch callReturnSize(
                call(gas(), pool, mul(mul(amount, useEth), iszero(toTokenIsEth)), ptr, offset, 0, 0x40)
            )
            case 0 {
                // we expect that curve pools that do not return any value also do not have the recipient argument
                switch and(useEth, toTokenIsEth)
                case 1 { ret := balance(address()) }
                default { ret := tokenBalanceOf(toToken, address()) }
                ret := sub(ret, 1) // keep 1 wei
            }
            default { ret := mload(mul(0x20, and(shr(_CURVE_SWAP_USE_SECOND_OUTPUT_OFFSET, dex), 0x01))) }

            if iszero(and(shr(_CURVE_SWAP_HAS_ARG_DESTINATION_OFFSET, dex), 0x01)) {
                if and(shr(_CURVE_OUTPUT_WETH_DEPOSIT_OFFSET, dex), 0x01) {
                    // Deposit ETH to WETH
                    mstore(0, _WETH_DEPOSIT_CALL_SELECTOR)
                    if iszero(call(gas(), _WETH, ret, 0, 4, 0, 0)) { reRevert() }
                }

                if and(shr(_CURVE_OUTPUT_WETH_WITHDRAW_OFFSET, dex), 0x01) {
                    // Withdraw ETH from WETH
                    mstore(0, _WETH_WITHDRAW_CALL_SELECTOR)
                    mstore(4, ret)
                    if iszero(call(gas(), _WETH, 0, 0, 0x24, 0, 0)) { reRevert() }
                }

                // Post transfer toToken if needed
                if xor(recipient, address()) {
                    switch and(useEth, toTokenIsEth)
                    case 1 { if iszero(call(gas(), recipient, ret, 0, 0, 0, 0)) { reRevert() } }
                    default {
                        if eq(toToken, _ETH) { toToken := _WETH }
                        // toToken.transfer(recipient, ret)
                        if iszero(
                            _asmCall(
                                toToken,
                                0xa9059cbb00000000000000000000000000000000000000000000000000000000,
                                recipient,
                                ret,
                                ptr
                            )
                        ) {
                            mstore(ptr, 0xf27f64e400000000000000000000000000000000000000000000000000000000) // error ERC20TransferFailed()
                            revert(ptr, 4)
                        }
                    }
                }
            }
        }
        if (ret < minReturn) {
            revert RouterErrors.ReturnAmountIsNotEnough(ret, minReturn);
        }
    }

    /**
     * @notice Called by Curve pool during the swap operation initiated by `_curfe`.
     * @dev This function can be called by anyone assuming there are no tokens
     * stored on this contract between transactions.
     * @param inCoin Address of the token to be exchanged.
     * @param dx Amount of tokens to be exchanged.
     */
    function curveSwapCallback(
        address, /* sender */
        address, /* receiver */
        address inCoin,
        uint256 dx,
        uint256 /* dy */
    ) external {
        IERC20(inCoin).safeTransfer(msg.sender, dx);
    }

    /**
     * @notice See {IUniswapV3SwapCallback-uniswapV3SwapCallback}
     *         Called by UniswapV3 pool during the swap operation initiated by `_unoswapV3`.
     *         This callback function ensures the proper transfer of tokens based on the swap's
     *         configuration. It handles the transfer of tokens by either directly transferring
     *         the tokens from the payer to the recipient, or by using a secondary permit contract
     *         to transfer the tokens if required by the pool. It verifies the correct pool is
     *         calling the function and uses inline assembly for efficient execution and to access
     *         low-level EVM features.
     */
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata /* data */ )
        external
        override
    {
        uint256 selectors = _SELECTORS;
        assembly ("memory-safe") {
            // solhint-disable-line no-inline-assembly
            function reRevert() {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }

            function safeERC20(target, value, mem, memLength, outLen) {
                let status := call(gas(), target, value, mem, memLength, 0, outLen)
                if iszero(status) { reRevert() }
                let success :=
                    or(
                        iszero(returndatasize()), // empty return data
                        and(gt(returndatasize(), 31), eq(mload(0), 1)) // true in return data
                    )
                if iszero(success) {
                    mstore(0, 0xf27f64e400000000000000000000000000000000000000000000000000000000) // ERC20TransferFailed()
                    revert(0, 4)
                }
            }

            let emptyPtr := mload(0x40)
            let resultPtr := add(emptyPtr, 0x15) // 0x15 = _FF_FACTORY size

            mstore(emptyPtr, selectors)

            let amount
            let token
            switch sgt(amount0Delta, 0)
            case 1 {
                if iszero(staticcall(gas(), caller(), add(emptyPtr, _TOKEN0_SELECTOR_OFFSET), 0x4, resultPtr, 0x20)) {
                    reRevert()
                }
                token := mload(resultPtr)
                amount := amount0Delta
            }
            default {
                if iszero(
                    staticcall(gas(), caller(), add(emptyPtr, _TOKEN1_SELECTOR_OFFSET), 0x4, add(resultPtr, 0x20), 0x20)
                ) { reRevert() }
                token := mload(add(resultPtr, 0x20))
                amount := amount1Delta
            }

            let payer := calldataload(0x84)
            let usePermit2 := calldataload(0xa4)
            switch eq(payer, address())
            case 1 {
                // IERC20(token.get()).safeTransfer(msg.sender,amount)
                mstore(add(emptyPtr, add(_TRANSFER_SELECTOR_OFFSET, 0x04)), caller())
                mstore(add(emptyPtr, add(_TRANSFER_SELECTOR_OFFSET, 0x24)), amount)
                safeERC20(token, 0, add(emptyPtr, _TRANSFER_SELECTOR_OFFSET), 0x44, 0x20)
            }
            default {
                switch sgt(amount0Delta, 0)
                case 1 {
                    if iszero(
                        staticcall(
                            gas(), caller(), add(emptyPtr, _TOKEN1_SELECTOR_OFFSET), 0x4, add(resultPtr, 0x20), 0x20
                        )
                    ) { reRevert() }
                }
                default {
                    if iszero(staticcall(gas(), caller(), add(emptyPtr, _TOKEN0_SELECTOR_OFFSET), 0x4, resultPtr, 0x20))
                    {
                        reRevert()
                    }
                }
                if iszero(
                    staticcall(gas(), caller(), add(emptyPtr, _FEE_SELECTOR_OFFSET), 0x4, add(resultPtr, 0x40), 0x20)
                ) { reRevert() }

                mstore(emptyPtr, _FF_FACTORY)
                mstore(resultPtr, keccak256(resultPtr, 0x60)) // Compute the inner hash in-place
                mstore(add(resultPtr, 0x20), _POOL_INIT_CODE_HASH)
                let pool := and(keccak256(emptyPtr, 0x55), _ADDRESS_MASK)
                if xor(pool, caller()) {
                    mstore(0, 0xb2c0272200000000000000000000000000000000000000000000000000000000) // BadPool()
                    revert(0, 4)
                }
                switch usePermit2
                case 1 {
                    // permit2.transferFrom(payer, msg.sender, amount, token);
                    mstore(emptyPtr, selectors)
                    emptyPtr := add(emptyPtr, _PERMIT2_TRANSFER_FROM_SELECTOR_OFFSET)
                    mstore(add(emptyPtr, 0x04), payer)
                    mstore(add(emptyPtr, 0x24), caller())
                    mstore(add(emptyPtr, 0x44), amount)
                    mstore(add(emptyPtr, 0x64), token)
                    let success := call(gas(), _PERMIT2, 0, emptyPtr, 0x84, 0, 0)
                    if success { success := gt(extcodesize(_PERMIT2), 0) }
                    if iszero(success) {
                        mstore(0, 0xc3f9d33200000000000000000000000000000000000000000000000000000000) // Permit2TransferFromFailed()
                        revert(0, 4)
                    }
                }
                case 0 {
                    // IERC20(token.get()).safeTransferFrom(payer, msg.sender, amount);
                    mstore(emptyPtr, selectors)
                    emptyPtr := add(emptyPtr, _TRANSFER_FROM_SELECTOR_OFFSET)
                    mstore(add(emptyPtr, 0x04), payer)
                    mstore(add(emptyPtr, 0x24), caller())
                    mstore(add(emptyPtr, 0x44), amount)
                    safeERC20(token, 0, emptyPtr, 0x64, 0x20)
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IERC20MetadataUppercase.sol";
import "./SafeERC20.sol";
import "./StringUtil.sol";

/// @title Library, which allows usage of ETH as ERC20 and ERC20 itself. Uses SafeERC20 library for ERC20 interface.
library UniERC20 {
    using SafeERC20 for IERC20;

    error InsufficientBalance();
    error ApproveCalledOnETH();
    error NotEnoughValue();
    error FromIsNotSender();
    error ToIsNotThis();
    error ETHTransferFailed();

    uint256 private constant _RAW_CALL_GAS_LIMIT = 5000;
    IERC20 private constant _ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 private constant _ZERO_ADDRESS = IERC20(address(0));

    /// @dev Returns true if `token` is ETH.
    function isETH(IERC20 token) internal pure returns (bool) {
        return (token == _ZERO_ADDRESS || token == _ETH_ADDRESS);
    }

    /// @dev Returns `account` ERC20 `token` balance.
    function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    /// @dev `token` transfer `to` `amount`.
    /// Note that this function does nothing in case of zero amount.
    function uniTransfer(
        IERC20 token,
        address payable to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (isETH(token)) {
                if (address(this).balance < amount) revert InsufficientBalance();
                // solhint-disable-next-line avoid-low-level-calls
                (bool success, ) = to.call{value: amount, gas: _RAW_CALL_GAS_LIMIT}("");
                if (!success) revert ETHTransferFailed();
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    /// @dev `token` transfer `from` `to` `amount`.
    /// Note that this function does nothing in case of zero amount.
    function uniTransferFrom(
        IERC20 token,
        address payable from,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (isETH(token)) {
                if (msg.value < amount) revert NotEnoughValue();
                if (from != msg.sender) revert FromIsNotSender();
                if (to != address(this)) revert ToIsNotThis();
                if (msg.value > amount) {
                    // Return remainder if exist
                    unchecked {
                        // solhint-disable-next-line avoid-low-level-calls
                        (bool success, ) = from.call{value: msg.value - amount, gas: _RAW_CALL_GAS_LIMIT}("");
                        if (!success) revert ETHTransferFailed();
                    }
                }
            } else {
                token.safeTransferFrom(from, to, amount);
            }
        }
    }

    /// @dev Returns `token` symbol from ERC20 metadata.
    function uniSymbol(IERC20 token) internal view returns (string memory) {
        return _uniDecode(token, IERC20Metadata.symbol.selector, IERC20MetadataUppercase.SYMBOL.selector);
    }

    /// @dev Returns `token` name from ERC20 metadata.
    function uniName(IERC20 token) internal view returns (string memory) {
        return _uniDecode(token, IERC20Metadata.name.selector, IERC20MetadataUppercase.NAME.selector);
    }

    /// @dev Reverts if `token` is ETH, otherwise performs ERC20 forceApprove.
    function uniApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (isETH(token)) revert ApproveCalledOnETH();

        token.forceApprove(to, amount);
    }

    /// @dev 20K gas is provided to account for possible implementations of name/symbol
    /// (token implementation might be behind proxy or store the value in storage)
    function _uniDecode(
        IERC20 token,
        bytes4 lowerCaseSelector,
        bytes4 upperCaseSelector
    ) private view returns (string memory result) {
        if (isETH(token)) {
            return "ETH";
        }

        (bool success, bytes memory data) = address(token).staticcall{gas: 20000}(
            abi.encodeWithSelector(lowerCaseSelector)
        );
        if (!success) {
            (success, data) = address(token).staticcall{gas: 20000}(abi.encodeWithSelector(upperCaseSelector));
        }

        if (success && data.length >= 0x40) {
            (uint256 offset, uint256 len) = abi.decode(data, (uint256, uint256));
            /*
                return data is padded up to 32 bytes with ABI encoder also sometimes
                there is extra 32 bytes of zeros padded in the end:
                https://github.com/ethereum/solidity/issues/10170
                because of that we can't check for equality and instead check
                that overall data length is greater or equal than string length + extra 64 bytes
            */
            if (offset == 0x20 && data.length >= 0x40 + len) {
                assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
                    result := add(data, 0x40)
                }
                return result;
            }
        }
        if (success && data.length == 32) {
            uint256 len = 0;
            while (len < data.length && data[len] >= 0x20 && data[len] <= 0x7E) {
                unchecked {
                    len++;
                }
            }

            if (len > 0) {
                assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
                    mstore(data, len)
                }
                return string(data);
            }
        }

        return StringUtil.toHex(address(token));
    }
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

pragma solidity ^0.8.0;

abstract contract EthReceiver {
    error EthDepositRejected();

    receive() external payable {
        _receive();
    }

    function _receive() internal virtual {
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender == tx.origin) revert EthDepositRejected();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EthReceiver.sol";

abstract contract OnlyWethReceiver is EthReceiver {
    address private immutable _WETH; // solhint-disable-line var-name-mixedcase

    constructor(address weth) {
        _WETH = address(weth);
    }

    function _receive() internal virtual override {
        if (msg.sender != _WETH) revert EthDepositRejected();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    event Deposit(address indexed dst, uint256 wad);

    event Withdrawal(address indexed src, uint256 wad);

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

/// @title Clipper interface subset used in swaps
interface IClipperExchange {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function sellEthForToken(
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        address destinationAddress,
        Signature calldata theSignature,
        bytes calldata auxiliaryData
    ) external payable;
    function sellTokenForEth(
        address inputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        address destinationAddress,
        Signature calldata theSignature,
        bytes calldata auxiliaryData
    ) external;
    function swap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        address destinationAddress,
        Signature calldata theSignature,
        bytes calldata auxiliaryData
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

type Address is uint256;

/**
* @dev Library for working with addresses encoded as uint256 values, which can include flags in the highest bits.
*/
library AddressLib {
    uint256 private constant _LOW_160_BIT_MASK = (1 << 160) - 1;

    /**
    * @notice Returns the address representation of a uint256.
    * @param a The uint256 value to convert to an address.
    * @return The address representation of the provided uint256 value.
    */
    function get(Address a) internal pure returns (address) {
        return address(uint160(Address.unwrap(a) & _LOW_160_BIT_MASK));
    }

    /**
    * @notice Checks if a given flag is set for the provided address.
    * @param a The address to check for the flag.
    * @param flag The flag to check for in the provided address.
    * @return True if the provided flag is set in the address, false otherwise.
    */
    function getFlag(Address a, uint256 flag) internal pure returns (bool) {
        return (Address.unwrap(a) & flag) != 0;
    }

    /**
    * @notice Returns a uint32 value stored at a specific bit offset in the provided address.
    * @param a The address containing the uint32 value.
    * @param offset The bit offset at which the uint32 value is stored.
    * @return The uint32 value stored in the address at the specified bit offset.
    */
    function getUint32(Address a, uint256 offset) internal pure returns (uint32) {
        return uint32(Address.unwrap(a) >> offset);
    }

    /**
    * @notice Returns a uint64 value stored at a specific bit offset in the provided address.
    * @param a The address containing the uint64 value.
    * @param offset The bit offset at which the uint64 value is stored.
    * @return The uint64 value stored in the address at the specified bit offset.
    */
    function getUint64(Address a, uint256 offset) internal pure returns (uint64) {
        return uint64(Address.unwrap(a) >> offset);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "../interfaces/IDaiLikePermit.sol";
import "../interfaces/IPermit2.sol";
import "../interfaces/IWETH.sol";
import "../libraries/RevertReasonForwarder.sol";

/**
 * @title Implements efficient safe methods for ERC20 interface.
 * @notice Compared to the standard ERC20, this implementation offers several enhancements:
 * 1. more gas-efficient, providing significant savings in transaction costs.
 * 2. support for different permit implementations
 * 3. forceApprove functionality
 * 4. support for WETH deposit and withdraw
 */
library SafeERC20 {
    error SafeTransferFailed();
    error SafeTransferFromFailed();
    error ForceApproveFailed();
    error SafeIncreaseAllowanceFailed();
    error SafeDecreaseAllowanceFailed();
    error SafePermitBadLength();
    error Permit2TransferAmountTooHigh();

    // Uniswap Permit2 address
    address private constant _PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    bytes4 private constant _PERMIT_LENGTH_ERROR = 0x68275857;  // SafePermitBadLength.selector
    uint256 private constant _RAW_CALL_GAS_LIMIT = 5000;

    /**
     * @notice Fetches the balance of a specific ERC20 token held by an account.
     * Consumes less gas then regular `ERC20.balanceOf`.
     * @dev Note that the implementation does not perform dirty bits cleaning, so it is the
     * responsibility of the caller to make sure that the higher 96 bits of the `account` parameter are clean.
     * @param token The IERC20 token contract for which the balance will be fetched.
     * @param account The address of the account whose token balance will be fetched.
     * @return tokenBalance The balance of the specified ERC20 token held by the account.
     */
    function safeBalanceOf(
        IERC20 token,
        address account
    ) internal view returns(uint256 tokenBalance) {
        bytes4 selector = IERC20.balanceOf.selector;
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            mstore(0x00, selector)
            mstore(0x04, account)
            let success := staticcall(gas(), token, 0x00, 0x24, 0x00, 0x20)
            tokenBalance := mload(0)

            if or(iszero(success), lt(returndatasize(), 0x20)) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }

    /**
     * @notice Attempts to safely transfer tokens from one address to another.
     * @dev If permit2 is true, uses the Permit2 standard; otherwise uses the standard ERC20 transferFrom.
     * Either requires `true` in return data, or requires target to be smart-contract and empty return data.
     * Note that the implementation does not perform dirty bits cleaning, so it is the responsibility of
     * the caller to make sure that the higher 96 bits of the `from` and `to` parameters are clean.
     * @param token The IERC20 token contract from which the tokens will be transferred.
     * @param from The address from which the tokens will be transferred.
     * @param to The address to which the tokens will be transferred.
     * @param amount The amount of tokens to transfer.
     * @param permit2 If true, uses the Permit2 standard for the transfer; otherwise uses the standard ERC20 transferFrom.
     */
    function safeTransferFromUniversal(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        bool permit2
    ) internal {
        if (permit2) {
            safeTransferFromPermit2(token, from, to, amount);
        } else {
            safeTransferFrom(token, from, to, amount);
        }
    }

    /**
     * @notice Attempts to safely transfer tokens from one address to another using the ERC20 standard.
     * @dev Either requires `true` in return data, or requires target to be smart-contract and empty return data.
     * Note that the implementation does not perform dirty bits cleaning, so it is the responsibility of
     * the caller to make sure that the higher 96 bits of the `from` and `to` parameters are clean.
     * @param token The IERC20 token contract from which the tokens will be transferred.
     * @param from The address from which the tokens will be transferred.
     * @param to The address to which the tokens will be transferred.
     * @param amount The amount of tokens to transfer.
     */
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            success := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    /**
     * @notice Attempts to safely transfer tokens from one address to another using the Permit2 standard.
     * @dev Either requires `true` in return data, or requires target to be smart-contract and empty return data.
     * Note that the implementation does not perform dirty bits cleaning, so it is the responsibility of
     * the caller to make sure that the higher 96 bits of the `from` and `to` parameters are clean.
     * @param token The IERC20 token contract from which the tokens will be transferred.
     * @param from The address from which the tokens will be transferred.
     * @param to The address to which the tokens will be transferred.
     * @param amount The amount of tokens to transfer.
     */
    function safeTransferFromPermit2(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount > type(uint160).max) revert Permit2TransferAmountTooHigh();
        bytes4 selector = IPermit2.transferFrom.selector;
        bool success;
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            mstore(add(data, 0x64), token)
            success := call(gas(), _PERMIT2, 0, data, 0x84, 0x0, 0x0)
            if success {
                success := gt(extcodesize(_PERMIT2), 0)
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    /**
     * @notice Attempts to safely transfer tokens to another address.
     * @dev Either requires `true` in return data, or requires target to be smart-contract and empty return data.
     * Note that the implementation does not perform dirty bits cleaning, so it is the responsibility of
     * the caller to make sure that the higher 96 bits of the `to` parameter are clean.
     * @param token The IERC20 token contract from which the tokens will be transferred.
     * @param to The address to which the tokens will be transferred.
     * @param value The amount of tokens to transfer.
     */
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.transfer.selector, to, value)) {
            revert SafeTransferFailed();
        }
    }

    /**
     * @notice Attempts to approve a spender to spend a certain amount of tokens.
     * @dev If `approve(from, to, amount)` fails, it tries to set the allowance to zero, and retries the `approve` call.
     * Note that the implementation does not perform dirty bits cleaning, so it is the responsibility of
     * the caller to make sure that the higher 96 bits of the `spender` parameter are clean.
     * @param token The IERC20 token contract on which the call will be made.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.approve.selector, spender, value)) {
            if (
                !_makeCall(token, token.approve.selector, spender, 0) ||
                !_makeCall(token, token.approve.selector, spender, value)
            ) {
                revert ForceApproveFailed();
            }
        }
    }

    /**
     * @notice Safely increases the allowance of a spender.
     * @dev Increases with safe math check. Checks if the increased allowance will overflow, if yes, then it reverts the transaction.
     * Then uses `forceApprove` to increase the allowance.
     * Note that the implementation does not perform dirty bits cleaning, so it is the responsibility of
     * the caller to make sure that the higher 96 bits of the `spender` parameter are clean.
     * @param token The IERC20 token contract on which the call will be made.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to increase the allowance by.
     */
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > type(uint256).max - allowance) revert SafeIncreaseAllowanceFailed();
        forceApprove(token, spender, allowance + value);
    }

    /**
     * @notice Safely decreases the allowance of a spender.
     * @dev Decreases with safe math check. Checks if the decreased allowance will underflow, if yes, then it reverts the transaction.
     * Then uses `forceApprove` to increase the allowance.
     * Note that the implementation does not perform dirty bits cleaning, so it is the responsibility of
     * the caller to make sure that the higher 96 bits of the `spender` parameter are clean.
     * @param token The IERC20 token contract on which the call will be made.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to decrease the allowance by.
     */
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > allowance) revert SafeDecreaseAllowanceFailed();
        forceApprove(token, spender, allowance - value);
    }

    /**
     * @notice Attempts to execute the `permit` function on the provided token with the sender and contract as parameters.
     * Permit type is determined automatically based on permit calldata (IERC20Permit, IDaiLikePermit, and IPermit2).
     * @dev Wraps `tryPermit` function and forwards revert reason if permit fails.
     * @param token The IERC20 token to execute the permit function on.
     * @param permit The permit data to be used in the function call.
     */
    function safePermit(IERC20 token, bytes calldata permit) internal {
        if (!tryPermit(token, msg.sender, address(this), permit)) RevertReasonForwarder.reRevert();
    }

    /**
     * @notice Attempts to execute the `permit` function on the provided token with custom owner and spender parameters.
     * Permit type is determined automatically based on permit calldata (IERC20Permit, IDaiLikePermit, and IPermit2).
     * @dev Wraps `tryPermit` function and forwards revert reason if permit fails.
     * Note that the implementation does not perform dirty bits cleaning, so it is the responsibility of
     * the caller to make sure that the higher 96 bits of the `owner` and `spender` parameters are clean.
     * @param token The IERC20 token to execute the permit function on.
     * @param owner The owner of the tokens for which the permit is made.
     * @param spender The spender allowed to spend the tokens by the permit.
     * @param permit The permit data to be used in the function call.
     */
    function safePermit(IERC20 token, address owner, address spender, bytes calldata permit) internal {
        if (!tryPermit(token, owner, spender, permit)) RevertReasonForwarder.reRevert();
    }

    /**
     * @notice Attempts to execute the `permit` function on the provided token with the sender and contract as parameters.
     * @dev Invokes `tryPermit` with sender as owner and contract as spender.
     * @param token The IERC20 token to execute the permit function on.
     * @param permit The permit data to be used in the function call.
     * @return success Returns true if the permit function was successfully executed, false otherwise.
     */
    function tryPermit(IERC20 token, bytes calldata permit) internal returns(bool success) {
        return tryPermit(token, msg.sender, address(this), permit);
    }

    /**
     * @notice The function attempts to call the permit function on a given ERC20 token.
     * @dev The function is designed to support a variety of permit functions, namely: IERC20Permit, IDaiLikePermit, and IPermit2.
     * It accommodates both Compact and Full formats of these permit types.
     * Please note, it is expected that the `expiration` parameter for the compact Permit2 and the `deadline` parameter
     * for the compact Permit are to be incremented by one before invoking this function. This approach is motivated by
     * gas efficiency considerations; as the unlimited expiration period is likely to be the most common scenario, and
     * zeros are cheaper to pass in terms of gas cost. Thus, callers should increment the expiration or deadline by one
     * before invocation for optimized performance.
     * Note that the implementation does not perform dirty bits cleaning, so it is the responsibility of
     * the caller to make sure that the higher 96 bits of the `owner` and `spender` parameters are clean.
     * @param token The address of the ERC20 token on which to call the permit function.
     * @param owner The owner of the tokens. This address should have signed the off-chain permit.
     * @param spender The address which will be approved for transfer of tokens.
     * @param permit The off-chain permit data, containing different fields depending on the type of permit function.
     * @return success A boolean indicating whether the permit call was successful.
     */
    function tryPermit(IERC20 token, address owner, address spender, bytes calldata permit) internal returns(bool success) {
        // load function selectors for different permit standards
        bytes4 permitSelector = IERC20Permit.permit.selector;
        bytes4 daiPermitSelector = IDaiLikePermit.permit.selector;
        bytes4 permit2Selector = IPermit2.permit.selector;
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)

            // Switch case for different permit lengths, indicating different permit standards
            switch permit.length
            // Compact IERC20Permit
            case 100 {
                mstore(ptr, permitSelector)     // store selector
                mstore(add(ptr, 0x04), owner)   // store owner
                mstore(add(ptr, 0x24), spender) // store spender

                // Compact IERC20Permit.permit(uint256 value, uint32 deadline, uint256 r, uint256 vs)
                {  // stack too deep
                    let deadline := shr(224, calldataload(add(permit.offset, 0x20))) // loads permit.offset 0x20..0x23
                    let vs := calldataload(add(permit.offset, 0x44))                 // loads permit.offset 0x44..0x63

                    calldatacopy(add(ptr, 0x44), permit.offset, 0x20)            // store value     = copy permit.offset 0x00..0x19
                    mstore(add(ptr, 0x64), sub(deadline, 1))                     // store deadline  = deadline - 1
                    mstore(add(ptr, 0x84), add(27, shr(255, vs)))                // store v         = most significant bit of vs + 27 (27 or 28)
                    calldatacopy(add(ptr, 0xa4), add(permit.offset, 0x24), 0x20) // store r         = copy permit.offset 0x24..0x43
                    mstore(add(ptr, 0xc4), shr(1, shl(1, vs)))                   // store s         = vs without most significant bit
                }
                // IERC20Permit.permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
                success := call(gas(), token, 0, ptr, 0xe4, 0, 0)
            }
            // Compact IDaiLikePermit
            case 72 {
                mstore(ptr, daiPermitSelector)  // store selector
                mstore(add(ptr, 0x04), owner)   // store owner
                mstore(add(ptr, 0x24), spender) // store spender

                // Compact IDaiLikePermit.permit(uint32 nonce, uint32 expiry, uint256 r, uint256 vs)
                {  // stack too deep
                    let expiry := shr(224, calldataload(add(permit.offset, 0x04))) // loads permit.offset 0x04..0x07
                    let vs := calldataload(add(permit.offset, 0x28))               // loads permit.offset 0x28..0x47

                    mstore(add(ptr, 0x44), shr(224, calldataload(permit.offset))) // store nonce   = copy permit.offset 0x00..0x03
                    mstore(add(ptr, 0x64), sub(expiry, 1))                        // store expiry  = expiry - 1
                    mstore(add(ptr, 0x84), true)                                  // store allowed = true
                    mstore(add(ptr, 0xa4), add(27, shr(255, vs)))                 // store v       = most significant bit of vs + 27 (27 or 28)
                    calldatacopy(add(ptr, 0xc4), add(permit.offset, 0x08), 0x20)  // store r       = copy permit.offset 0x08..0x27
                    mstore(add(ptr, 0xe4), shr(1, shl(1, vs)))                    // store s       = vs without most significant bit
                }
                // IDaiLikePermit.permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s)
                success := call(gas(), token, 0, ptr, 0x104, 0, 0)
            }
            // IERC20Permit
            case 224 {
                mstore(ptr, permitSelector)
                calldatacopy(add(ptr, 0x04), permit.offset, permit.length) // copy permit calldata
                // IERC20Permit.permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
                success := call(gas(), token, 0, ptr, 0xe4, 0, 0)
            }
            // IDaiLikePermit
            case 256 {
                mstore(ptr, daiPermitSelector)
                calldatacopy(add(ptr, 0x04), permit.offset, permit.length) // copy permit calldata
                // IDaiLikePermit.permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s)
                success := call(gas(), token, 0, ptr, 0x104, 0, 0)
            }
            // Compact IPermit2
            case 96 {
                // Compact IPermit2.permit(uint160 amount, uint32 expiration, uint32 nonce, uint32 sigDeadline, uint256 r, uint256 vs)
                mstore(ptr, permit2Selector)  // store selector
                mstore(add(ptr, 0x04), owner) // store owner
                mstore(add(ptr, 0x24), token) // store token

                calldatacopy(add(ptr, 0x50), permit.offset, 0x14)             // store amount = copy permit.offset 0x00..0x13
                // and(0xffffffffffff, ...) - conversion to uint48
                mstore(add(ptr, 0x64), and(0xffffffffffff, sub(shr(224, calldataload(add(permit.offset, 0x14))), 1))) // store expiration = ((permit.offset 0x14..0x17 - 1) & 0xffffffffffff)
                mstore(add(ptr, 0x84), shr(224, calldataload(add(permit.offset, 0x18)))) // store nonce = copy permit.offset 0x18..0x1b
                mstore(add(ptr, 0xa4), spender)                               // store spender
                // and(0xffffffffffff, ...) - conversion to uint48
                mstore(add(ptr, 0xc4), and(0xffffffffffff, sub(shr(224, calldataload(add(permit.offset, 0x1c))), 1))) // store sigDeadline = ((permit.offset 0x1c..0x1f - 1) & 0xffffffffffff)
                mstore(add(ptr, 0xe4), 0x100)                                 // store offset = 256
                mstore(add(ptr, 0x104), 0x40)                                 // store length = 64
                calldatacopy(add(ptr, 0x124), add(permit.offset, 0x20), 0x20) // store r      = copy permit.offset 0x20..0x3f
                calldatacopy(add(ptr, 0x144), add(permit.offset, 0x40), 0x20) // store vs     = copy permit.offset 0x40..0x5f
                // IPermit2.permit(address owner, PermitSingle calldata permitSingle, bytes calldata signature)
                success := call(gas(), _PERMIT2, 0, ptr, 0x164, 0, 0)
            }
            // IPermit2
            case 352 {
                mstore(ptr, permit2Selector)
                calldatacopy(add(ptr, 0x04), permit.offset, permit.length) // copy permit calldata
                // IPermit2.permit(address owner, PermitSingle calldata permitSingle, bytes calldata signature)
                success := call(gas(), _PERMIT2, 0, ptr, 0x164, 0, 0)
            }
            // Unknown
            default {
                mstore(ptr, _PERMIT_LENGTH_ERROR)
                revert(ptr, 4)
            }
        }
    }

    /**
     * @dev Executes a low level call to a token contract, making it resistant to reversion and erroneous boolean returns.
     * @param token The IERC20 token contract on which the call will be made.
     * @param selector The function signature that is to be called on the token contract.
     * @param to The address to which the token amount will be transferred.
     * @param amount The token amount to be transferred.
     * @return success A boolean indicating if the call was successful. Returns 'true' on success and 'false' on failure.
     * In case of success but no returned data, validates that the contract code exists.
     * In case of returned data, ensures that it's a boolean `true`.
     */
    function _makeCall(
        IERC20 token,
        bytes4 selector,
        address to,
        uint256 amount
    ) private returns (bool success) {
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }

    /**
     * @notice Safely deposits a specified amount of Ether into the IWETH contract. Consumes less gas then regular `IWETH.deposit`.
     * @param weth The IWETH token contract.
     * @param amount The amount of Ether to deposit into the IWETH contract.
     */
    function safeDeposit(IWETH weth, uint256 amount) internal {
        if (amount > 0) {
            bytes4 selector = IWETH.deposit.selector;
            assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
                mstore(0, selector)
                if iszero(call(gas(), weth, amount, 0, 4, 0, 0)) {
                    let ptr := mload(0x40)
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }
            }
        }
    }

    /**
     * @notice Safely withdraws a specified amount of wrapped Ether from the IWETH contract. Consumes less gas then regular `IWETH.withdraw`.
     * @dev Uses inline assembly to interact with the IWETH contract.
     * @param weth The IWETH token contract.
     * @param amount The amount of wrapped Ether to withdraw from the IWETH contract.
     */
    function safeWithdraw(IWETH weth, uint256 amount) internal {
        bytes4 selector = IWETH.withdraw.selector;
        assembly ("memory-safe") {  // solhint-disable-line no-inline-assembly
            mstore(0, selector)
            mstore(4, amount)
            if iszero(call(gas(), weth, 0, 0, 0x24, 0, 0)) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }

    /**
     * @notice Safely withdraws a specified amount of wrapped Ether from the IWETH contract to a specified recipient.
     * Consumes less gas then regular `IWETH.withdraw`.
     * @param weth The IWETH token contract.
     * @param amount The amount of wrapped Ether to withdraw from the IWETH contract.
     * @param to The recipient of the withdrawn Ether.
     */
    function safeWithdrawTo(IWETH weth, uint256 amount, address to) internal {
        safeWithdraw(weth, amount);
        if (to != address(this)) {
            assembly ("memory-safe") {  // solhint-disable-line no-inline-assembly
                if iszero(call(_RAW_CALL_GAS_LIMIT, to, amount, 0, 0, 0, 0)) {
                    let ptr := mload(0x40)
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Errors {
    error InvalidMsgValue();
    error ETHTransferFailed();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

library RouterErrors {
    error ReturnAmountIsNotEnough(uint256 result, uint256 minReturn);
    error InvalidMsgValue();
    error ERC20TransferFailed();
    error Permit2TransferFromFailed();
    error ApproveFailed();
    error TaxTokenDetected();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

/// @title Interface for making arbitrary calls during swap
interface IAggregationExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable returns (uint256); // 0x4b64e492
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {IAggregationExecutor} from "../interfaces/IAggregationExecutor.sol";
import {Errors} from "@1inch/limit-order-protocol-contract/contracts/libraries/Errors.sol";
import {UniERC20} from "@1inch/solidity-utils/contracts/libraries/UniERC20.sol";
import {RouterErrors} from "../helpers/RouterErrors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EthReceiver} from "@1inch/solidity-utils/contracts/EthReceiver.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";

/**
 * @title GenericRouter
 * @notice Router that allows to use `IAggregationExecutor` for swaps.
 */
contract GenericRouter is EthReceiver {
    using UniERC20 for IERC20;
    using SafeERC20 for IERC20;

    error ZeroMinReturn();

    uint256 private constant _PARTIAL_FILL = 1 << 0;
    uint256 private constant _REQUIRES_EXTRA_ETH = 1 << 1;
    uint256 private constant _USE_PERMIT2 = 1 << 2;

    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    /**
     * @notice Performs a swap, delegating all calls encoded in `data` to `executor`. See tests for usage examples.
     * @dev Router keeps 1 wei of every token on the contract balance for gas optimisations reasons.
     *      This affects first swap of every token by leaving 1 wei on the contract.
     * @param executor Aggregation executor that executes calls described in `data`.
     * @param desc Swap description.
     * @param data Encoded calls that `caller` should execute in between of swaps.
     * @return returnAmount Resulting token amount.
     * @return spentAmount Source token amount.
     */
    function swap(IAggregationExecutor executor, SwapDescription calldata desc, bytes calldata data)
        external
        payable
        returns (uint256 returnAmount, uint256 spentAmount)
    {
        if (desc.minReturnAmount == 0) revert ZeroMinReturn();

        IERC20 srcToken = desc.srcToken;
        IERC20 dstToken = desc.dstToken;

        bool srcETH = srcToken.isETH();
        if (desc.flags & _REQUIRES_EXTRA_ETH != 0) {
            if (msg.value <= (srcETH ? desc.amount : 0)) revert RouterErrors.InvalidMsgValue();
        } else {
            if (msg.value != (srcETH ? desc.amount : 0)) revert RouterErrors.InvalidMsgValue();
        }

        if (!srcETH) {
            srcToken.safeTransferFromUniversal(
                msg.sender, desc.srcReceiver, desc.amount, desc.flags & _USE_PERMIT2 != 0
            );
        }

        returnAmount = _execute(executor, msg.sender, desc.amount, data);
        spentAmount = desc.amount;

        if (desc.flags & _PARTIAL_FILL != 0) {
            uint256 unspentAmount = srcToken.uniBalanceOf(address(this));
            if (unspentAmount > 1) {
                // we leave 1 wei on the router for gas optimisations reasons
                unchecked {
                    unspentAmount--;
                }
                spentAmount -= unspentAmount;
                srcToken.uniTransfer(payable(msg.sender), unspentAmount);
            }
            if (returnAmount * desc.amount < desc.minReturnAmount * spentAmount) {
                revert RouterErrors.ReturnAmountIsNotEnough(
                    returnAmount, desc.minReturnAmount * spentAmount / desc.amount
                );
            }
        } else {
            if (returnAmount < desc.minReturnAmount) {
                revert RouterErrors.ReturnAmountIsNotEnough(returnAmount, desc.minReturnAmount);
            }
        }

        address payable dstReceiver = (desc.dstReceiver == address(0)) ? payable(msg.sender) : desc.dstReceiver;
        dstToken.uniTransfer(dstReceiver, returnAmount);
    }

    function _execute(IAggregationExecutor executor, address srcTokenOwner, uint256 inputAmount, bytes calldata data)
        private
        returns (uint256 result)
    {
        bytes4 executeSelector = executor.execute.selector;
        assembly ("memory-safe") {
            // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)

            mstore(ptr, executeSelector)
            mstore(add(ptr, 0x04), srcTokenOwner)
            calldatacopy(add(ptr, 0x24), data.offset, data.length)
            mstore(add(add(ptr, 0x24), data.length), inputAmount)

            if iszero(call(gas(), executor, callvalue(), ptr, add(0x44, data.length), 0, 0x20)) {
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }

            result := mload(0)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {IUniswapV3Pool} from "../interfaces/IUniswapV3Pool.sol";

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {IUniswapV3SwapCallback} from "../interfaces/IUniswapV3SwapCallback.sol";

interface IUniswapV3Pool {
    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPermit2 {
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }
    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }
    /// @notice Packed allowance
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    function transferFrom(address user, address spender, uint160 amount, address token) external;

    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

    function allowance(address user, address token, address spender) external view returns (PackedAllowance memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {AddressLib, Address} from "@1inch/solidity-utils/contracts/libraries/AddressLib.sol";

library ProtocolLib {
    using AddressLib for Address;

    enum Protocol {
        UniswapV2,
        UniswapV3,
        Curve
    }

    uint256 private constant _PROTOCOL_OFFSET = 253;
    uint256 private constant _WETH_UNWRAP_FLAG = 1 << 252;
    uint256 private constant _WETH_NOT_WRAP_FLAG = 1 << 251;
    uint256 private constant _USE_PERMIT2_FLAG = 1 << 250;

    function protocol(Address self) internal pure returns (Protocol) {
        // there is no need to mask because protocol is stored in the highest 3 bits
        return Protocol((Address.unwrap(self) >> _PROTOCOL_OFFSET));
    }

    function shouldUnwrapWeth(Address self) internal pure returns (bool) {
        return self.getFlag(_WETH_UNWRAP_FLAG);
    }

    function shouldWrapWeth(Address self) internal pure returns (bool) {
        return !self.getFlag(_WETH_NOT_WRAP_FLAG);
    }

    function usePermit2(Address self) internal pure returns (bool) {
        return self.getFlag(_USE_PERMIT2_FLAG);
    }

    function addressForPreTransfer(Address self) internal view returns (address) {
        if (protocol(self) == Protocol.UniswapV2) {
            return self.get();
        }
        return address(this);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

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

pragma solidity ^0.8.0;

interface IERC20MetadataUppercase {
    function NAME() external view returns (string memory); // solhint-disable-line func-name-mixedcase

    function SYMBOL() external view returns (string memory); // solhint-disable-line func-name-mixedcase
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Library with gas-efficient string operations
library StringUtil {
    function toHex(uint256 value) internal pure returns (string memory) {
        return toHex(abi.encodePacked(value));
    }

    function toHex(address value) internal pure returns (string memory) {
        return toHex(abi.encodePacked(value));
    }

    /// @dev this is the assembly adaptation of highly optimized toHex16 code from Mikhail Vladimirov
    /// https://stackoverflow.com/a/69266989
    function toHex(bytes memory data) internal pure returns (string memory result) {
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            function _toHex16(input) -> output {
                output := or(
                    and(input, 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000),
                    shr(64, and(input, 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000))
                )
                output := or(
                    and(output, 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000),
                    shr(32, and(output, 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000))
                )
                output := or(
                    and(output, 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000),
                    shr(16, and(output, 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000))
                )
                output := or(
                    and(output, 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000),
                    shr(8, and(output, 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000))
                )
                output := or(
                    shr(4, and(output, 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000)),
                    shr(8, and(output, 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00))
                )
                output := add(
                    add(0x3030303030303030303030303030303030303030303030303030303030303030, output),
                    mul(
                        and(
                            shr(4, add(output, 0x0606060606060606060606060606060606060606060606060606060606060606)),
                            0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F
                        ),
                        7 // Change 7 to 39 for lower case output
                    )
                )
            }

            result := mload(0x40)
            let length := mload(data)
            let resultLength := shl(1, length)
            let toPtr := add(result, 0x22) // 32 bytes for length + 2 bytes for '0x'
            mstore(0x40, add(toPtr, resultLength)) // move free memory pointer
            mstore(add(result, 2), 0x3078) // 0x3078 is right aligned so we write to `result + 2`
            // to store the last 2 bytes in the beginning of the string
            mstore(result, add(resultLength, 2)) // extra 2 bytes for '0x'

            for {
                let fromPtr := add(data, 0x20)
                let endPtr := add(fromPtr, length)
            } lt(fromPtr, endPtr) {
                fromPtr := add(fromPtr, 0x20)
            } {
                let rawData := mload(fromPtr)
                let hexData := _toHex16(rawData)
                mstore(toPtr, hexData)
                toPtr := add(toPtr, 0x20)
                hexData := _toHex16(shl(128, rawData))
                mstore(toPtr, hexData)
                toPtr := add(toPtr, 0x20)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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

pragma solidity ^0.8.0;

interface IDaiLikePermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Revert reason forwarder.
library RevertReasonForwarder {
    /// @dev Forwards latest externall call revert.
    function reRevert() internal pure {
        // bubble up revert reason from latest external call
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())
            revert(ptr, returndatasize())
        }
    }

    /// @dev Returns latest external call revert reason.
    function reReason() internal pure returns (bytes memory reason) {
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            reason := mload(0x40)
            let length := returndatasize()
            mstore(reason, length)
            returndatacopy(add(reason, 0x20), 0, length)
            mstore(0x40, add(reason, add(0x20, length)))
        }
    }
}