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
pragma solidity 0.8.17;

interface IAggregationExecutor {
  function callBytes(bytes calldata data) external payable; // 0xd9c45357

  // callbytes per swap sequence
  function swapSingleSequence(bytes calldata data) external;

  function finalTransactionProcessing(
    address tokenIn,
    address tokenOut,
    address to,
    bytes calldata destTokenFeeData
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IExecutorHelper1 {
  struct UniSwap {
    address pool;
    address tokenIn;
    address tokenOut;
    address recipient;
    uint256 collectAmount; // amount that should be transferred to the pool
    uint256 limitReturnAmount;
    uint32 swapFee;
    uint32 feePrecision;
    uint32 tokenWeightInput;
  }

  struct StableSwap {
    address pool;
    address tokenFrom;
    address tokenTo;
    uint8 tokenIndexFrom;
    uint8 tokenIndexTo;
    uint256 dx;
    uint256 minDy;
    uint256 poolLength;
    address poolLp;
    bool isSaddle; // true: saddle, false: stable
  }

  struct CurveSwap {
    address pool;
    address tokenFrom;
    address tokenTo;
    int128 tokenIndexFrom;
    int128 tokenIndexTo;
    uint256 dx;
    uint256 minDy;
    bool usePoolUnderlying;
    bool useTriCrypto;
  }

  struct UniSwapV3ProMM {
    address recipient;
    address pool;
    address tokenIn;
    address tokenOut;
    uint256 swapAmount;
    uint256 limitReturnAmount;
    uint160 sqrtPriceLimitX96;
    bool isUniV3; // true = UniV3, false = ProMM
  }

  struct SwapCallbackData {
    bytes path;
    address payer;
  }

  struct SwapCallbackDataPath {
    address pool;
    address tokenIn;
    address tokenOut;
  }

  struct BalancerV2 {
    address vault;
    bytes32 poolId;
    address assetIn;
    address assetOut;
    uint256 amount;
    uint256 limit;
  }

  struct KyberRFQ {
    address rfq;
    bytes order;
    bytes signature;
    uint256 amount;
    address payable target;
  }

  struct DODO {
    address recipient;
    address pool;
    address tokenFrom;
    address tokenTo;
    uint256 amount;
    uint256 minReceiveQuote;
    address sellHelper;
    bool isSellBase;
    bool isVersion2;
  }

  struct GMX {
    address vault;
    address tokenIn;
    address tokenOut;
    uint256 amount;
    uint256 minOut;
    address receiver;
  }

  struct Synthetix {
    address synthetixProxy;
    address tokenIn;
    address tokenOut;
    bytes32 sourceCurrencyKey;
    uint256 sourceAmount;
    bytes32 destinationCurrencyKey;
    uint256 minAmount;
    bool useAtomicExchange;
  }

  function executeUniSwap(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);

  function executeStableSwap(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);

  function executeCurveSwap(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);

  function executeKyberDMMSwap(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);

  function executeUniV3ProMMSwap(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);

  function executeRfqSwap(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);

  function executeBalV2Swap(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);

  function executeDODOSwap(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);

  function executeVelodromeSwap(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);

  function executeGMXSwap(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);

  function executeSynthetixSwap(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);

  function executeHashflowSwap(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);

  function executeCamelotSwap(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IExecutorHelper2 {
  function executeKyberLimitOrder(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IAggregationExecutor} from './IAggregationExecutor.sol';

interface IMetaAggregationRouter {
  struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address[] srcReceivers;
    uint256[] srcAmounts;
    address dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
  }

  function swap(
    IAggregationExecutor caller,
    SwapDescription calldata desc,
    bytes calldata executorData,
    bytes calldata clientData
  ) external payable returns (uint256, uint256);

  function swapSimpleMode(
    IAggregationExecutor caller,
    SwapDescription calldata desc,
    bytes calldata executorData,
    bytes calldata clientData
  ) external returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IAggregationExecutor} from './IAggregationExecutor.sol';

interface IMetaAggregationRouterV2 {
  struct SwapDescriptionV2 {
    IERC20 srcToken;
    IERC20 dstToken;
    address[] srcReceivers; // transfer src token to these addresses, default
    uint256[] srcAmounts;
    address[] feeReceivers;
    uint256[] feeAmounts;
    address dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
  }

  /// @dev  use for swapGeneric and swap to avoid stack too deep
  struct SwapExecutionParams {
    address callTarget; // call this address
    address approveTarget; // approve this address if _APPROVE_FUND set
    bytes targetData;
    SwapDescriptionV2 desc;
    bytes clientData;
  }

  function swap(SwapExecutionParams calldata execution) external payable returns (uint256, uint256);

  function swapSimpleMode(
    IAggregationExecutor caller,
    SwapDescriptionV2 memory desc,
    bytes calldata executorData,
    bytes calldata clientData
  ) external returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IExecutorHelper1} from './interfaces/kyberswap/IExecutorHelper1.sol';
import {IExecutorHelper2} from './interfaces/kyberswap/IExecutorHelper2.sol';
import {IMetaAggregationRouterV2} from './interfaces/kyberswap/IMetaAggregationRouterV2.sol';
import {IMetaAggregationRouter} from './interfaces/kyberswap/IMetaAggregationRouter.sol';
import {ScaleDataHelper1} from './libraries/kyberswap/ScaleDataHelper1.sol';

contract KyberswapPatcher {
  uint256 private constant _PARTIAL_FILL = 0x01;
  uint256 private constant _REQUIRES_EXTRA_ETH = 0x02;
  uint256 private constant _SHOULD_CLAIM = 0x04;
  uint256 private constant _BURN_FROM_MSG_SENDER = 0x08;
  uint256 private constant _BURN_FROM_TX_ORIGIN = 0x10;
  uint256 private constant _SIMPLE_SWAP = 0x20;

  struct Swap {
    bytes data;
    bytes4 functionSelector;
  }

  struct SimpleSwapData {
    address[] firstPools;
    uint256[] firstSwapAmounts;
    bytes[] swapDatas;
    uint256 deadline;
    bytes destTokenFeeData;
  }

  struct SwapExecutorDescription {
    Swap[][] swapSequences;
    address tokenIn;
    address tokenOut;
    uint256 minTotalAmountOut;
    address to;
    uint256 deadline;
    bytes destTokenFeeData;
  }

  struct Data {
    address router;
    bytes inputData;
    uint256 newAmount;
  }

  error CallFailed(string message, bytes reason);

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    if (value == 0) return;
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'safeTransferFrom: Transfer from fail');
  }

  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    if (value == 0) return;
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'safeApprove: Approve fail');
  }

  function scaleAndSwap(uint256 newAmount, address router, bytes calldata inputData) external payable {
    bytes4 selector = bytes4(inputData[:4]);
    bytes memory dataToDecode = new bytes(inputData.length - 4);
    bytes memory callData;

    for (uint256 i = 0; i < inputData.length - 4; ++i) {
      dataToDecode[i] = inputData[i + 4];
    }

    if (
      selector == IMetaAggregationRouter.swap.selector || selector == IMetaAggregationRouter.swapSimpleMode.selector
    ) {
      (
        address callTarget,
        IMetaAggregationRouter.SwapDescription memory desc,
        bytes memory targetData,
        bytes memory clientData
      ) = abi.decode(dataToDecode, (address, IMetaAggregationRouter.SwapDescription, bytes, bytes));

      (desc, targetData) = _getScaledInputDataV1(
        desc,
        targetData,
        newAmount,
        selector == IMetaAggregationRouter.swapSimpleMode.selector || _flagsChecked(desc.flags, _SIMPLE_SWAP)
      );
      callData = abi.encodeWithSelector(selector, callTarget, desc, targetData, clientData);

      safeTransferFrom(address(desc.srcToken), msg.sender, address(this), newAmount);
      safeApprove(address(desc.srcToken), router, newAmount);
    } else if (selector == IMetaAggregationRouterV2.swap.selector) {
      IMetaAggregationRouterV2.SwapExecutionParams memory params = abi.decode(
        dataToDecode,
        (IMetaAggregationRouterV2.SwapExecutionParams)
      );

      (params.desc, params.targetData) = _getScaledInputDataV2(
        params.desc,
        params.targetData,
        newAmount,
        _flagsChecked(params.desc.flags, _SIMPLE_SWAP)
      );
      callData = abi.encodeWithSelector(selector, params);
      
      safeTransferFrom(address(params.desc.srcToken), msg.sender, address(this), newAmount);
      safeApprove(address(params.desc.srcToken), router, newAmount);
    } else if (selector == IMetaAggregationRouterV2.swapSimpleMode.selector) {
      (
        address callTarget,
        IMetaAggregationRouterV2.SwapDescriptionV2 memory desc,
        bytes memory targetData,
        bytes memory clientData
      ) = abi.decode(dataToDecode, (address, IMetaAggregationRouterV2.SwapDescriptionV2, bytes, bytes));

      (desc, targetData) = _getScaledInputDataV2(desc, targetData, newAmount, true);
      callData = abi.encodeWithSelector(selector, callTarget, desc, targetData, clientData);

      safeTransferFrom(address(desc.srcToken), msg.sender, address(this), newAmount);
      safeApprove(address(desc.srcToken), router, newAmount);
    } else revert('KyberswapPatcher: Invalid selector');

    (bool success, bytes memory data) = router.call(callData);
    if (!success) revert CallFailed('KyberswapPatcher: call failed', data);
  }

  function _getScaledInputDataV1(
    IMetaAggregationRouter.SwapDescription memory desc,
    bytes memory executorData,
    uint256 newAmount,
    bool isSimpleMode
  ) internal pure returns (IMetaAggregationRouter.SwapDescription memory, bytes memory) {
    uint256 oldAmount = desc.amount;
    if (oldAmount == newAmount) {
      return (desc, executorData);
    }

    // simple mode swap
    if (isSimpleMode) {
      return (
        _scaledSwapDescriptionV1(desc, oldAmount, newAmount),
        _scaledSimpleSwapData(executorData, oldAmount, newAmount)
      );
    }

    //normal mode swap
    return (
      _scaledSwapDescriptionV1(desc, oldAmount, newAmount),
      _scaledExecutorCallBytesData(executorData, oldAmount, newAmount)
    );
  }

  function _getScaledInputDataV2(
    IMetaAggregationRouterV2.SwapDescriptionV2 memory desc,
    bytes memory executorData,
    uint256 newAmount,
    bool isSimpleMode
  ) internal pure returns (IMetaAggregationRouterV2.SwapDescriptionV2 memory, bytes memory) {
    uint256 oldAmount = desc.amount;
    if (oldAmount == newAmount) {
      return (desc, executorData);
    }

    // simple mode swap
    if (isSimpleMode) {
      return (
        _scaledSwapDescriptionV2(desc, oldAmount, newAmount),
        _scaledSimpleSwapData(executorData, oldAmount, newAmount)
      );
    }

    //normal mode swap
    return (
      _scaledSwapDescriptionV2(desc, oldAmount, newAmount),
      _scaledExecutorCallBytesData(executorData, oldAmount, newAmount)
    );
  }

  function _scaledSwapDescriptionV1(
    IMetaAggregationRouter.SwapDescription memory desc,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (IMetaAggregationRouter.SwapDescription memory) {
    desc.minReturnAmount = (desc.minReturnAmount * newAmount) / oldAmount;
    if (desc.minReturnAmount == 0) desc.minReturnAmount = 1;
    desc.amount = newAmount;
    for (uint256 i = 0; i < desc.srcReceivers.length; i++) {
      desc.srcAmounts[i] = (desc.srcAmounts[i] * newAmount) / oldAmount;
    }
    return desc;
  }

  function _scaledSwapDescriptionV2(
    IMetaAggregationRouterV2.SwapDescriptionV2 memory desc,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (IMetaAggregationRouterV2.SwapDescriptionV2 memory) {
    desc.minReturnAmount = (desc.minReturnAmount * newAmount) / oldAmount;
    if (desc.minReturnAmount == 0) desc.minReturnAmount = 1;
    desc.amount = newAmount;
    for (uint256 i = 0; i < desc.srcReceivers.length; i++) {
      desc.srcAmounts[i] = (desc.srcAmounts[i] * newAmount) / oldAmount;
    }
    return desc;
  }

  function _scaledSimpleSwapData(
    bytes memory data,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (bytes memory) {
    SimpleSwapData memory swapData = abi.decode(data, (SimpleSwapData));
    for (uint256 i = 0; i < swapData.firstPools.length; i++) {
      swapData.firstSwapAmounts[i] = (swapData.firstSwapAmounts[i] * newAmount) / oldAmount;
    }
    return abi.encode(swapData);
  }

  function _scaledExecutorCallBytesData(
    bytes memory data,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (bytes memory) {
    SwapExecutorDescription memory executorDesc = abi.decode(data, (SwapExecutorDescription));
    executorDesc.minTotalAmountOut = (executorDesc.minTotalAmountOut * newAmount) / oldAmount;
    for (uint256 i = 0; i < executorDesc.swapSequences.length; i++) {
      Swap memory swap = executorDesc.swapSequences[i][0];
      bytes4 functionSelector = swap.functionSelector;

      if (functionSelector == IExecutorHelper1.executeUniSwap.selector) {
        swap.data = ScaleDataHelper1.newUniSwap(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeStableSwap.selector) {
        swap.data = ScaleDataHelper1.newStableSwap(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeCurveSwap.selector) {
        swap.data = ScaleDataHelper1.newCurveSwap(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeKyberDMMSwap.selector) {
        swap.data = ScaleDataHelper1.newKyberDMM(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeUniV3ProMMSwap.selector) {
        swap.data = ScaleDataHelper1.newUniV3ProMM(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeRfqSwap.selector) {
        revert('KyberswapPatcher: Can not scale RFQ swap');
      } else if (functionSelector == IExecutorHelper1.executeBalV2Swap.selector) {
        swap.data = ScaleDataHelper1.newBalancerV2(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeDODOSwap.selector) {
        swap.data = ScaleDataHelper1.newDODO(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeVelodromeSwap.selector) {
        swap.data = ScaleDataHelper1.newVelodrome(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeGMXSwap.selector) {
        swap.data = ScaleDataHelper1.newGMX(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeSynthetixSwap.selector) {
        swap.data = ScaleDataHelper1.newSynthetix(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeHashflowSwap.selector) {
        revert('KyberswapPatcher: Can not scale RFQ swap');
      } else if (functionSelector == IExecutorHelper1.executeCamelotSwap.selector) {
        swap.data = ScaleDataHelper1.newCamelot(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper2.executeKyberLimitOrder.selector) {
        revert('KyberswapPatcher: Can not scale RFQ swap');
      } else revert('AggregationExecutor: Dex type not supported');
    }
    return abi.encode(executorDesc);
  }

  function _flagsChecked(uint256 number, uint256 flag) internal pure returns (bool) {
    return number & flag != 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IExecutorHelper1} from '../../interfaces/kyberswap/IExecutorHelper1.sol';

library ScaleDataHelper1 {
  function newUniSwap(
    bytes memory data,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (bytes memory) {
    IExecutorHelper1.UniSwap memory uniSwap = abi.decode(data, (IExecutorHelper1.UniSwap));
    uniSwap.collectAmount = (uniSwap.collectAmount * newAmount) / oldAmount;
    return abi.encode(uniSwap);
  }

  function newStableSwap(
    bytes memory data,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (bytes memory) {
    IExecutorHelper1.StableSwap memory stableSwap = abi.decode(data, (IExecutorHelper1.StableSwap));
    stableSwap.dx = (stableSwap.dx * newAmount) / oldAmount;
    return abi.encode(stableSwap);
  }

  function newCurveSwap(
    bytes memory data,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (bytes memory) {
    IExecutorHelper1.CurveSwap memory curveSwap = abi.decode(data, (IExecutorHelper1.CurveSwap));
    curveSwap.dx = (curveSwap.dx * newAmount) / oldAmount;
    return abi.encode(curveSwap);
  }

  function newKyberDMM(
    bytes memory data,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (bytes memory) {
    IExecutorHelper1.UniSwap memory kyberDMMSwap = abi.decode(data, (IExecutorHelper1.UniSwap));
    kyberDMMSwap.collectAmount = (kyberDMMSwap.collectAmount * newAmount) / oldAmount;
    return abi.encode(kyberDMMSwap);
  }

  function newUniV3ProMM(
    bytes memory data,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (bytes memory) {
    IExecutorHelper1.UniSwapV3ProMM memory uniSwapV3ProMM = abi.decode(data, (IExecutorHelper1.UniSwapV3ProMM));
    uniSwapV3ProMM.swapAmount = (uniSwapV3ProMM.swapAmount * newAmount) / oldAmount;

    return abi.encode(uniSwapV3ProMM);
  }

  function newBalancerV2(
    bytes memory data,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (bytes memory) {
    IExecutorHelper1.BalancerV2 memory balancerV2 = abi.decode(data, (IExecutorHelper1.BalancerV2));
    balancerV2.amount = (balancerV2.amount * newAmount) / oldAmount;
    return abi.encode(balancerV2);
  }

  function newDODO(
    bytes memory data,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (bytes memory) {
    IExecutorHelper1.DODO memory dodo = abi.decode(data, (IExecutorHelper1.DODO));
    dodo.amount = (dodo.amount * newAmount) / oldAmount;
    return abi.encode(dodo);
  }

  function newVelodrome(
    bytes memory data,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (bytes memory) {
    IExecutorHelper1.UniSwap memory velodrome = abi.decode(data, (IExecutorHelper1.UniSwap));
    velodrome.collectAmount = (velodrome.collectAmount * newAmount) / oldAmount;
    return abi.encode(velodrome);
  }

  function newGMX(
    bytes memory data,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (bytes memory) {
    IExecutorHelper1.GMX memory gmx = abi.decode(data, (IExecutorHelper1.GMX));
    gmx.amount = (gmx.amount * newAmount) / oldAmount;
    return abi.encode(gmx);
  }

  function newSynthetix(
    bytes memory data,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (bytes memory) {
    IExecutorHelper1.Synthetix memory synthetix = abi.decode(data, (IExecutorHelper1.Synthetix));
    synthetix.sourceAmount = (synthetix.sourceAmount * newAmount) / oldAmount;
    return abi.encode(synthetix);
  }

  function newCamelot(
    bytes memory data,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (bytes memory) {
    IExecutorHelper1.UniSwap memory camelot = abi.decode(data, (IExecutorHelper1.UniSwap));
    camelot.collectAmount = (camelot.collectAmount * newAmount) / oldAmount;
    return abi.encode(camelot);
  }
}