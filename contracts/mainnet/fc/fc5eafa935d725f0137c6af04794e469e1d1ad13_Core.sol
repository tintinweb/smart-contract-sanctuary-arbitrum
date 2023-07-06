// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {ICore} from "./interfaces/ICore.sol";
import {Dispatcher} from "./base/Dispatcher.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {LzBridgeData, TokenData} from "./lib/CoreStructs.sol";
import {IStargateReceiver} from "./interfaces/stargate/IStargateReceiver.sol";
import {IStargateRouter} from "./interfaces/stargate/IStargateRouter.sol";
import {IWrappedToken} from "./interfaces/IWrappedToken.sol";
import {FeeOperator} from "./utils/FeeOperator.sol";

contract Core is ICore, FeeOperator, Dispatcher, IStargateReceiver {
    constructor(
        address _executor,
        address _stargateRouter,
        address _uniswapRouter,
        address _wrappedNative,
        address _sgETH
    ) Dispatcher(_executor, _stargateRouter, _uniswapRouter, _wrappedNative, _sgETH) {}

    /**
     * @dev Swaps currency from the incoming to the outgoing token and executes a transaction with payment.
     * @param target The address of the target contract for the payment transaction.
     * @param paymentOperator The operator address for payment transfers requiring erc20 approvals.
     * @param tokenData The token swap data and payment transaction payload
     */
    function swapAndExecute(address target, address paymentOperator, TokenData calldata tokenData)
        external
        payable
        handleFees(0, tokenData.amountIn, tokenData.tokenIn)
    {
        _receiveErc20(tokenData.amountIn, tokenData.tokenIn);
        _swapAndExecute(msg.sender, target, paymentOperator, block.timestamp, tokenData);
    }

    /**
     * @dev Bridges funds in native or erc20 and a payment transaction payload to the destination chain
     * @param lzBridgeData The configuration for the cross bridge transaction
     * @param tokenData The token swap data and payment transaction payload
     * @param lzTxObj The configuration of gas and dust for post bridge execution
     */
    function bridgeAndExecute(
        LzBridgeData calldata lzBridgeData,
        TokenData calldata tokenData,
        IStargateRouter.lzTxObj calldata lzTxObj
    ) external payable handleFees(lzBridgeData.fee, tokenData.amountIn, tokenData.tokenIn) {
        _receiveErc20(tokenData.amountIn, tokenData.tokenIn);
        address tokenIn = tokenData.tokenIn;
        if (tokenData.tokenIn == address(0)) {
            tokenIn = tokenData.tokenOut == SG_ETH ? SG_ETH : WRAPPED_NATIVE;
            IWrappedToken(tokenIn).deposit{value: tokenData.amountIn}();
        }
        // only swap if we need to
        if (tokenIn != tokenData.tokenOut) {
            _swapExactOutput(
                msg.sender, tokenIn, tokenData.amountIn, tokenData.amountOut, block.timestamp, tokenData.path
            );
        }

        if (tokenIn == tokenData.tokenOut && tokenData.amountOut > tokenData.amountIn) {
            revert BridgeOutputExceedsInput();
        }

        _approveAndBridge(tokenData.tokenOut, tokenData.amountOut, lzBridgeData, lzTxObj, tokenData.payload);
    }

    /*
     * @dev Called by the Stargate Router on the destination chain upon bridging funds.
     * @dev unused @param _srcChainId The remote chainId sending the tokens.
     * @dev unused @param _srcAddress The remote Bridge address.
     * @dev unused @param _nonce The message ordering nonce.
     * @param _token The token contract on the local chain.
     * @param amountLD The qty of local _token contract tokens.
     * @param payload The bytes containing the execution paramaters.
     */
    function sgReceive(
        uint16, // _srcChainid
        bytes memory, // _srcAddress
        uint256, // _nonce
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external override {
        if (msg.sender != address(STARGATE_ROUTER)) {
            revert OnlyStargateRouter();
        }

        (
            address sender,
            address target,
            address _paymentToken,
            address paymentOperator,
            uint256 _amountOutMin,
            bytes memory path,
            bytes memory callData
        ) = abi.decode(payload, (address, address, address, address, uint256, bytes, bytes));

        TokenData memory tokenData = TokenData(amountLD, _amountOutMin, _token, _paymentToken, path, callData);

        _swapAndExecute(sender, target, paymentOperator, block.timestamp, tokenData);

        emit ReceivedOnDestination(_token, amountLD);
    }

    function withdraw(IERC20 token) external onlyOwner {
        SafeERC20.safeTransfer(token, msg.sender, token.balanceOf(address(this)));
    }

    function withdrawEth() external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Could not drain ETH");
    }

    /// @notice To receive ETH from WETH and NFT protocols
    receive() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {LzBridgeData, TokenData} from "../lib/CoreStructs.sol";
import {IStargateRouter} from "../interfaces/stargate/IStargateRouter.sol";

interface ICore {
    /*
     * @dev Only Stargate Router can perform this operation.
     */
    error OnlyStargateRouter();

    /**
     * @dev Swaps currency from the incoming to the outgoing token and executes a transaction with payment.
     * @param target The address of the target contract for the payment transaction.
     * @param paymentOperator The operator address for payment transfers requiring erc20 approvals.
     * @param tokenData The token swap data and payment transaction payload
     */
    function swapAndExecute(address target, address paymentOperator, TokenData calldata tokenData) external payable;

    /**
     * @dev Bridges funds in native or erc20 and a payment transaction payload to the destination chain
     * @param lzBridgeData The configuration for the cross bridge transaction
     * @param tokenData The token swap data and payment transaction payload
     * @param lzTxObj The configuration of gas and dust for post bridge execution
     */
    function bridgeAndExecute(
        LzBridgeData calldata lzBridgeData,
        TokenData calldata tokenData,
        IStargateRouter.lzTxObj calldata lzTxObj
    ) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {BoxImmutables} from "./BoxImmutables.sol";
import {IWrappedToken} from "../interfaces/IWrappedToken.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {LzBridgeData, TokenData} from "../lib/CoreStructs.sol";
import {IStargateRouter} from "../interfaces/stargate/IStargateRouter.sol";
import {IExecutor} from "../interfaces/IExecutor.sol";

contract Dispatcher is BoxImmutables, Ownable {
    constructor(
        address _executor,
        address _stargateRouter,
        address _uniswapRouter,
        address _wrappedNative,
        address _sgEth
    ) BoxImmutables(_executor, _stargateRouter, _uniswapRouter, _wrappedNative, _sgEth) {}

    /**
     * @dev Internal function to handle receiving erc20 tokens for bridging and swapping.
     * @param amountIn The amount of native or erc20 being transferred.
     * @param tokenIn The address of the token being transferred.
     */
    function _receiveErc20(uint256 amountIn, address tokenIn) internal {
        if (tokenIn != address(0)) {
            SafeERC20.safeTransferFrom(IERC20(tokenIn), msg.sender, address(this), amountIn);
        }
    }

    event BridgedExecutionUnsuccessful();

    event RefundUnsuccessful();

    error ExecutionUnsuccessful();

    error SwapOutputExceedsInput();

    error BridgeOutputExceedsInput();

    /**
     * @dev Internal function to approve an erc20 token and perform a cross chain swap using Stargate Router.
     * @param bridgeToken The erc20 which will be approved and transferred.
     * @param amountOut The amount of bridge token being transferred.
     * @param lzBridgeData The configuration for the cross bridge transaction.
     * @param lzTxObj The configuration of gas and dust for post bridge execution.
     * @param payload The bytes containing execution parameters for post bridge execution.
     */
    function _approveAndBridge(
        address bridgeToken,
        uint256 amountOut,
        LzBridgeData calldata lzBridgeData,
        IStargateRouter.lzTxObj calldata lzTxObj,
        bytes calldata payload
    ) internal {
        // approve for bridge
        SafeERC20.safeIncreaseAllowance(IERC20(bridgeToken), STARGATE_ROUTER, amountOut);
        IStargateRouter(STARGATE_ROUTER).swap{value: lzBridgeData.fee}(
            lzBridgeData._dstChainId, // send to LayerZero chainId
            lzBridgeData._srcPoolId, // source pool id
            lzBridgeData._dstPoolId, // dst pool id
            payable(msg.sender), // refund adddress. extra gas (if any) is returned to this address
            amountOut, // quantity to swap
            (amountOut * 994) / 1000, // the min qty you would accept on the destination, fee is 6 bips
            lzTxObj, // additional gasLimit increase, airdrop, at address
            abi.encodePacked(lzBridgeData._bridgeAddress), // the address to send the tokens to on the destination
            payload // bytes param, if you wish to send additional payload you can abi.encode() them here
        );
    }

    /**
     * @dev Internal function to swap tokens for an exact output amount using Uniswap v3 SwapRouter.
     * @param sender The account receiving any refunds, typically the EOA which initiated the transaction.
     * @param tokenIn The input token for the swap, use zero address to convert native to erc20 wrapped native.
     * @param amountInMaximum The maximum amount allocated to swap for the exact amount out.
     * @param amountOut The exact output amount of tokens desired from the swap.
     * @param deadline The deadline for execution of the Uniswap transaction.
     * @param path The encoded sequences of pools and fees required to perform the swap.
     */
    function _swapExactOutput(
        address sender,
        address tokenIn,
        uint256 amountInMaximum,
        uint256 amountOut,
        uint256 deadline,
        bytes memory path
    ) internal returns (bool success) {
        // deposit native into wrapped native if necessary
        if (tokenIn == address(0)) {
            IWrappedToken(WRAPPED_NATIVE).deposit{value: amountInMaximum}();
            tokenIn = WRAPPED_NATIVE;
        }

        // approve router to use our wrapped native
        SafeERC20.safeIncreaseAllowance(IERC20(tokenIn), UNISWAP_ROUTER, amountInMaximum);

        // setup the parameters for multi hop swap
        ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
            path: path,
            recipient: address(this),
            deadline: deadline,
            amountOut: amountOut,
            amountInMaximum: amountInMaximum
        });

        success = true;
        uint256 refund;

        // perform the swap and calculate any excess erc20 funds
        if (msg.sender == STARGATE_ROUTER) {
            try ISwapRouter(UNISWAP_ROUTER).exactOutput(params) returns (uint256 amountIn) {
                refund = amountInMaximum - amountIn;
            } catch {
                refund = amountInMaximum;
                success = false;
            }
        } else {
            uint256 amountIn = ISwapRouter(UNISWAP_ROUTER).exactOutput(params);
            refund = amountInMaximum - amountIn;
        }

        // refund any excess erc20 funds to sender
        if (refund > 0) {
            SafeERC20.safeDecreaseAllowance(IERC20(tokenIn), UNISWAP_ROUTER, refund);
            SafeERC20.safeTransfer(IERC20(tokenIn), sender, refund);
        }
    }

    /**
     * @dev Internal function to swaps currency from the incoming to the outgoing token and execute a transaction with payment.
     * @param sender The account receiving any refunds, typically the EOA which initiated the transaction.
     * @param target The address of the target contract for the payment transaction.
     * @param paymentOperator The operator address for payment transfers requiring erc20 approvals.
     * @param deadline The deadline for execution of the uniswap transaction.
     * @param data The token swap data and post bridge execution payload.
     */
    function _swapAndExecute(
        address sender,
        address target,
        address paymentOperator,
        uint256 deadline,
        TokenData memory data
    ) internal {
        bool success = true;

        // confirm native currency output does not exceed native currency input
        if (data.tokenIn == data.tokenOut && data.amountOut > data.amountIn) {
            if (msg.sender == STARGATE_ROUTER) {
                _refund(sender, data.tokenIn, data.amountIn);
                success = false;
            } else {
                revert SwapOutputExceedsInput();
            }
        }

        // if necessary, swap incoming and outgoing tokens and unwrap native funds
        if (data.tokenIn != data.tokenOut) {
            if (data.tokenIn == WRAPPED_NATIVE && data.tokenOut == address(0)) {
                // unwrap native funds
                IWrappedToken(WRAPPED_NATIVE).withdraw(data.amountOut);
            } else if (data.tokenIn != SG_ETH || data.tokenOut != address(0)) {
                success = _swapExactOutput(sender, data.tokenIn, data.amountIn, data.amountOut, deadline, data.path);

                if (data.tokenOut == address(0)) {
                    IWrappedToken(WRAPPED_NATIVE).withdraw(data.amountOut);
                }
            }
        }

        if (success) {
            if (data.tokenOut == address(0)) {
                // complete payment transaction with native currency
                try IExecutor(EXECUTOR).execute{value: data.amountOut}(target, paymentOperator, data) returns (
                    bool executionSuccess
                ) {
                    success = executionSuccess;
                } catch {
                    success = false;
                }
            } else {
                // complete payment transaction with erc20 using executor
                SafeERC20.safeIncreaseAllowance(IERC20(data.tokenOut), EXECUTOR, data.amountOut);
                try IExecutor(EXECUTOR).execute(target, paymentOperator, data) returns (bool executionSuccess) {
                    success = executionSuccess;
                } catch {
                    success = false;
                }
            }

            if (!success) {
                if (msg.sender == STARGATE_ROUTER) {
                    _refund(sender, data.tokenOut, data.amountOut);
                    emit BridgedExecutionUnsuccessful();
                } else {
                    revert ExecutionUnsuccessful();
                }
            }
        }
    }

    /**
     * @dev Internal function to handle refund transfers of native or erc20 to a recipient.
     * @param to The recipient of the refund transfer.
     * @param token The token being transferred, use zero address for native currency.
     * @param amount The amount of native or erc20 being transferred to the recipient.
     */
    function _refund(address to, address token, uint256 amount) internal {
        if (token == address(0)) {
            (bool success,) = payable(to).call{value: amount}("");
            if (!success) {
                emit RefundUnsuccessful();
            }
        } else {
            SafeERC20.safeTransfer(IERC20(token), to, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/*
 * @dev A parameter object containing data for bridging funds and an  between chains
 */
struct LzBridgeData {
    uint120 _srcPoolId;
    uint120 _dstPoolId;
    uint16 _dstChainId;
    address _bridgeAddress;
    uint96 fee;
}

/*
 * @dev A parameter object containing token swap data and a payment transaction payload
 */
struct TokenData {
    uint256 amountIn;
    uint256 amountOut;
    address tokenIn;
    address tokenOut;
    bytes path;
    bytes payload;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IStargateReceiver {
    event ReceivedOnDestination(address token, uint256 amountLD);

    /*
     * @dev Called by the Stargate Router on the destination chain upon bridging funds
     * @dev unused @param _srcChainId The remote chainId sending the tokens
     * @dev unused @param _srcAddress The remote Bridge address
     * @dev unused @param _nonce The message ordering nonce
     * @param _token The token contract on the local chain
     * @param amountLD The qty of local _token contract tokens
     * @param payload The bytes containing the execution paramaters
     */
    function sgReceive(
        uint16, // _srcChainId
        bytes memory, // _srcAddress
        uint256, // _nonce
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(uint256 _poolId, uint256 _amountLD, address _to) external;

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

    function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLP, address _to) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(uint16 _dstChainId, uint256 _srcPoolId, uint256 _dstPoolId, address payable _refundAddress)
        external
        payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IWrappedToken {
    function withdraw(uint256 wad) external;

    function deposit() external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../interfaces/IFeeManager.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title FeeOperator
 */
abstract contract FeeOperator is Ownable {
    /*
     * @dev The address of the fee manager.
     */
    address public feeManager;

    /*
     * @dev Emitted when the fee manager is updated.
     * @param feeManager The address of the new fee manager.
     */
    event FeeManagerUpdated(address feeManager);

    /*
     * @dev Insufficient funds to complete the transaction and pay fees.
     */
    error InsufficientFees();

    /*
     * @dev Fees were unable to be transferred to the fee manager.
     */
    error FeeTransferFailed();

    /*
     * @dev Excess funds were unable to be refunded to the caller.
     */
    error RefundFailed();

    /**
     * @dev Function modifier to handle transaction fees for bridging and swapping.
     * @param amountIn The amount of native or erc20 being transferred.
     * @param tokenIn The address of the token being transferred, zero address for native currency.
     */
    modifier handleFees(uint256 bridgeFee, uint256 amountIn, address tokenIn) {
        if (feeManager != address(0)) {
            (uint256 fee, uint256 commission) = IFeeManager(feeManager).calculateFees(amountIn, tokenIn);

            uint256 boxFees = fee + commission;
            uint256 amountRequired = tokenIn == address(0) ? amountIn + bridgeFee + boxFees : bridgeFee + boxFees;

            if (msg.value < amountRequired) {
                revert InsufficientFees();
            }

            _transferFees(boxFees);
            _transferRefund(msg.value - amountRequired);
        }

        _;
    }

    /**
     * @dev Updates the address of the fee manager used for calculating and collecting fees.
     * @param _feeManager The address of the new fee manager.
     */
    function setFeeManager(address _feeManager) external onlyOwner {
        feeManager = _feeManager;
        emit FeeManagerUpdated(_feeManager);
    }

    /**
     * @dev Internal function to transfer fees to the fee manager.
     * @param fees The amount of fees being transferred.
     */
    function _transferFees(uint256 fees) internal {
        (bool success,) = payable(feeManager).call{value: fees}("");
        if (!success) {
            revert FeeTransferFailed();
        }
    }

    /**
     * @dev Internal function to transfer excess funds to the caller.
     * @param refund The amount of funds to transfer.
     */
    function _transferRefund(uint256 refund) internal {
        if (refund > 0) {
            (bool success,) = payable(msg.sender).call{value: refund}("");
            if (!success) {
                revert RefundFailed();
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

contract BoxImmutables {
    address internal immutable STARGATE_ROUTER;
    address internal immutable UNISWAP_ROUTER;
    address internal immutable WRAPPED_NATIVE;
    address internal immutable SG_ETH;
    address internal immutable EXECUTOR;

    constructor(
        address _executor,
        address _stargateRouter,
        address _uniswapRouter,
        address _wrappedNative,
        address _sgEth
    ) {
        EXECUTOR = _executor;
        WRAPPED_NATIVE = _wrappedNative;
        SG_ETH = _sgEth;
        STARGATE_ROUTER = _stargateRouter;
        UNISWAP_ROUTER = _uniswapRouter;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {TokenData} from "../lib/CoreStructs.sol";

interface IExecutor {
    error OnlyCoreAuth();

    event CoreUpdated(address newCore);

    /**
     * @dev executes call from dispatcher, creating additional checks on arbitrary calldata
     * @param target The address of the target contract for the payment transaction.
     * @param paymentOperator The operator address for payment transfers requiring erc20 approvals.
     * @param data The token swap data and post bridge execution payload.
     */
    function execute(address target, address paymentOperator, TokenData memory data)
        external
        payable
        returns (bool success);

    /**
     * @dev sets core address
     * @param core core implementation address
     */
    function setCore(address core) external;
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
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IFeeManager {
    error WithdrawFailed();

    function setFees(uint256 _fee, uint256 _commissionBPS) external;

    function calculateFees(uint256 amountIn, address tokenIn) external view returns (uint256 fee, uint256 commission);

    function redeemFees() external;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

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
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}