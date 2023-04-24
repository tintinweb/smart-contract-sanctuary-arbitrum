/**
 *Submitted for verification at Arbiscan on 2023-04-24
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;





contract ArbitrumAuthAddresses {
    address internal constant ADMIN_VAULT_ADDR = 0xd47D8D97cAd12A866900eEc6Cde1962529F25351;
    address internal constant FACTORY_ADDRESS = 0x5261abC3a94a6475D0A1171daE94A5f84fbaEcD2;
    address internal constant ADMIN_ADDR = 0x6AFEA85cFAB61e3a55Ad2e4537252Ec05796BEfa;
}





contract AuthHelper is ArbitrumAuthAddresses {
}





contract AdminVault is AuthHelper {
    address public owner;
    address public admin;

    error SenderNotAdmin();

    constructor() {
        owner = msg.sender;
        admin = ADMIN_ADDR;
    }

    /// @notice Admin is able to change owner
    /// @param _owner Address of new owner
    function changeOwner(address _owner) public {
        if (admin != msg.sender){
            revert SenderNotAdmin();
        }
        owner = _owner;
    }

    /// @notice Admin is able to set new admin
    /// @param _admin Address of multisig that becomes new admin
    function changeAdmin(address _admin) public {
        if (admin != msg.sender){
            revert SenderNotAdmin();
        }
        admin = _admin;
    }

}





abstract contract IDFSRegistry {
 
    function getAddr(bytes4 _id) public view virtual returns (address);

    function addNewContract(
        bytes32 _id,
        address _contractAddr,
        uint256 _waitPeriod
    ) public virtual;

    function startContractChange(bytes32 _id, address _newContractAddr) public virtual;

    function approveContractChange(bytes32 _id) public virtual;

    function cancelContractChange(bytes32 _id) public virtual;

    function changeWaitPeriod(bytes32 _id, uint256 _newWaitPeriod) public virtual;
}





interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256 digits);
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}





library Address {
    //insufficient balance
    error InsufficientBalance(uint256 available, uint256 required);
    //unable to send value, recipient may have reverted
    error SendingValueFail();
    //insufficient balance for call
    error InsufficientBalanceForCall(uint256 available, uint256 required);
    //call to non-contract
    error NonContractCall();
    
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        uint256 balance = address(this).balance;
        if (balance < amount){
            revert InsufficientBalance(balance, amount);
        }

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        if (!(success)){
            revert SendingValueFail();
        }
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        uint256 balance = address(this).balance;
        if (balance < value){
            revert InsufficientBalanceForCall(balance, value);
        }
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        if (!(isContract(target))){
            revert NonContractCall();
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}




library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}







library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /// @dev Edited so it always first approves 0 and then the value, because of non standard tokens
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}








contract AdminAuth is AuthHelper {
    using SafeERC20 for IERC20;

    AdminVault public constant adminVault = AdminVault(ADMIN_VAULT_ADDR);

    error SenderNotOwner();
    error SenderNotAdmin();

    modifier onlyOwner() {
        if (adminVault.owner() != msg.sender){
            revert SenderNotOwner();
        }
        _;
    }

    modifier onlyAdmin() {
        if (adminVault.admin() != msg.sender){
            revert SenderNotAdmin();
        }
        _;
    }

    /// @notice withdraw stuck funds
    function withdrawStuckFunds(address _token, address _receiver, uint256 _amount) public onlyOwner {
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(_receiver).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    /// @notice Destroy the contract
    function kill() public onlyAdmin {
        selfdestruct(payable(msg.sender));
    }
}




contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}




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




interface IExecutorHelper {
  struct Swap {
    bytes data;
    bytes4 functionSelector;
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

  struct BalancerV2 {
    address vault;
    bytes32 poolId;
    address assetIn;
    address assetOut;
    uint256 amount;
    uint256 limit;
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

  struct Platypus {
    address pool;
    address tokenIn;
    address tokenOut;
    address recipient;
    uint256 collectAmount; // amount that should be transferred to the pool
    uint256 limitReturnAmount;
  }

  struct PSM {
    address router;
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    address recipient;
  }

  struct WSTETH {
    address pool;
    uint256 amount;
    bool isWrapping;
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

  function executePlatypusSwap(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);

  function executeWrappedstETHSwap(
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

  function executePSMSwap(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);

  function executeFraxSwap(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);

  function executeCamelotSwap(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);

  function executeKyberLimitOrder(
    uint256 index,
    bytes memory data,
    uint256 previousAmountOut
  ) external payable returns (uint256);

  function callBytes(bytes calldata data) external payable; // 0xd9c45357
}






contract KyberInputScalingHelper {
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

    /// @dev if selector is 0, we need to decode the selector from the data and copy the rest of the data (L2 network)
    /// @dev if selector is filled, it means data is already split (L1 network)
    function getScaledInputData(
        bytes4 selector,
        bytes memory inputData,
        uint256 newAmount
    ) public pure returns (bytes memory) {
        if (selector == IMetaAggregationRouterV2.swap.selector) {
            IMetaAggregationRouterV2.SwapExecutionParams memory params = abi.decode(
                inputData,
                (IMetaAggregationRouterV2.SwapExecutionParams)
            );

            (params.desc, params.targetData) = _getScaledInputDataV2(
                params.desc,
                params.targetData,
                newAmount,
                _flagsChecked(params.desc.flags, _SIMPLE_SWAP)
            );
            return abi.encodeWithSelector(selector, params);
        } else if (selector == IMetaAggregationRouterV2.swapSimpleMode.selector) {
            (
                address callTarget,
                IMetaAggregationRouterV2.SwapDescriptionV2 memory desc,
                bytes memory targetData,
                bytes memory clientData
            ) = abi.decode(
                    inputData,
                    (address, IMetaAggregationRouterV2.SwapDescriptionV2, bytes, bytes)
                );

            (desc, targetData) = _getScaledInputDataV2(desc, targetData, newAmount, true);
            return abi.encodeWithSelector(selector, callTarget, desc, targetData, clientData);
        } else revert("InputScalingHelper: Invalid selector");
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

    /// @dev Scale the swap description
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

    /// @dev Scale the executorData in case swapSimpleMode
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

    /// @dev Scale the executorData in case normal swap
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

            if (functionSelector == IExecutorHelper.executeUniSwap.selector) {
                swap.data = newUniSwap(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper.executeStableSwap.selector) {
                swap.data = newStableSwap(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper.executeCurveSwap.selector) {
                swap.data = newCurveSwap(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper.executeKyberDMMSwap.selector) {
                swap.data = newKyberDMM(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper.executeUniV3ProMMSwap.selector) {
                swap.data = newUniV3ProMM(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper.executeRfqSwap.selector) {
                revert("InputScalingHelper: Can not scale RFQ swap");
            } else if (functionSelector == IExecutorHelper.executeBalV2Swap.selector) {
                swap.data = newBalancerV2(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper.executeDODOSwap.selector) {
                swap.data = newDODO(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper.executeVelodromeSwap.selector) {
                swap.data = newVelodrome(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper.executeGMXSwap.selector) {
                swap.data = newGMX(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper.executeSynthetixSwap.selector) {
                swap.data = newSynthetix(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper.executeHashflowSwap.selector) {
                revert("InputScalingHelper: Can not scale RFQ swap");
            } else if (functionSelector == IExecutorHelper.executeCamelotSwap.selector) {
                swap.data = newCamelot(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper.executeKyberLimitOrder.selector) {
                revert("InputScalingHelper: Can not scale RFQ swap");
            } else if (functionSelector == IExecutorHelper.executeWrappedstETHSwap.selector) {
                swap.data = newWrappedstETHSwap(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper.executePSMSwap.selector) {
                swap.data = newPSM(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper.executeFraxSwap.selector) {
                swap.data = newFrax(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper.executePlatypusSwap.selector) {
                swap.data = newPlatypus(swap.data, oldAmount, newAmount);
            } else revert("AggregationExecutor: Dex type not supported");
        }
        return abi.encode(executorDesc);
    }

    function newUniSwap(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper.UniSwap memory uniSwap = abi.decode(data, (IExecutorHelper.UniSwap));
        uniSwap.collectAmount = (uniSwap.collectAmount * newAmount) / oldAmount;
        return abi.encode(uniSwap);
    }

    function newStableSwap(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper.StableSwap memory stableSwap = abi.decode(
            data,
            (IExecutorHelper.StableSwap)
        );
        stableSwap.dx = (stableSwap.dx * newAmount) / oldAmount;
        return abi.encode(stableSwap);
    }

    function newCurveSwap(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper.CurveSwap memory curveSwap = abi.decode(data, (IExecutorHelper.CurveSwap));
        curveSwap.dx = (curveSwap.dx * newAmount) / oldAmount;
        return abi.encode(curveSwap);
    }

    function newKyberDMM(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper.UniSwap memory kyberDMMSwap = abi.decode(data, (IExecutorHelper.UniSwap));
        kyberDMMSwap.collectAmount = (kyberDMMSwap.collectAmount * newAmount) / oldAmount;
        return abi.encode(kyberDMMSwap);
    }

    function newUniV3ProMM(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper.UniSwapV3ProMM memory uniSwapV3ProMM = abi.decode(
            data,
            (IExecutorHelper.UniSwapV3ProMM)
        );
        uniSwapV3ProMM.swapAmount = (uniSwapV3ProMM.swapAmount * newAmount) / oldAmount;

        return abi.encode(uniSwapV3ProMM);
    }

    function newBalancerV2(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper.BalancerV2 memory balancerV2 = abi.decode(
            data,
            (IExecutorHelper.BalancerV2)
        );
        balancerV2.amount = (balancerV2.amount * newAmount) / oldAmount;
        return abi.encode(balancerV2);
    }

    function newDODO(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper.DODO memory dodo = abi.decode(data, (IExecutorHelper.DODO));
        dodo.amount = (dodo.amount * newAmount) / oldAmount;
        return abi.encode(dodo);
    }

    function newVelodrome(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper.UniSwap memory velodrome = abi.decode(data, (IExecutorHelper.UniSwap));
        velodrome.collectAmount = (velodrome.collectAmount * newAmount) / oldAmount;
        return abi.encode(velodrome);
    }

    function newGMX(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper.GMX memory gmx = abi.decode(data, (IExecutorHelper.GMX));
        gmx.amount = (gmx.amount * newAmount) / oldAmount;
        return abi.encode(gmx);
    }

    function newSynthetix(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper.Synthetix memory synthetix = abi.decode(data, (IExecutorHelper.Synthetix));
        synthetix.sourceAmount = (synthetix.sourceAmount * newAmount) / oldAmount;
        return abi.encode(synthetix);
    }

    function newCamelot(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper.UniSwap memory camelot = abi.decode(data, (IExecutorHelper.UniSwap));
        camelot.collectAmount = (camelot.collectAmount * newAmount) / oldAmount;
        return abi.encode(camelot);
    }

    function newPlatypus(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper.Platypus memory platypus = abi.decode(data, (IExecutorHelper.Platypus));
        platypus.collectAmount = (platypus.collectAmount * newAmount) / oldAmount;
        return abi.encode(platypus);
    }

    function newWrappedstETHSwap(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper.WSTETH memory wstEthData = abi.decode(data, (IExecutorHelper.WSTETH));
        wstEthData.amount = (wstEthData.amount * newAmount) / oldAmount;
        return abi.encode(wstEthData);
    }

    function newPSM(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper.PSM memory psm = abi.decode(data, (IExecutorHelper.PSM));
        psm.amountIn = (psm.amountIn * newAmount) / oldAmount;
        return abi.encode(psm);
    }

    function newFrax(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper.UniSwap memory frax = abi.decode(data, (IExecutorHelper.UniSwap));
        frax.collectAmount = (frax.collectAmount * newAmount) / oldAmount;
        return abi.encode(frax);
    }

    function _flagsChecked(uint256 number, uint256 flag) internal pure returns (bool) {
        return number & flag != 0;
    }
}




contract DFSExchangeData {

    // first is empty to keep the legacy order in place
    // EMPTY was _, but in >0.8.x using underscore as name is forbidden
    enum ExchangeType { EMPTY, OASIS, KYBER, UNISWAP, ZEROX }

    enum ExchangeActionType { SELL, BUY }

    struct OffchainData {
        address wrapper;
        address exchangeAddr;
        address allowanceTarget;
        uint256 price;
        uint256 protocolFee;
        bytes callData;
    }

    struct ExchangeData {
        address srcAddr;
        address destAddr;
        uint256 srcAmount;
        uint256 destAmount;
        uint256 minPrice;
        uint256 dfsFeeDivider; // service fee divider
        address user; // user to check special fee
        address wrapper;
        bytes wrapperData;
        OffchainData offchainData;
    }

    function packExchangeData(ExchangeData memory _exData) public pure returns(bytes memory) {
        return abi.encode(_exData);
    }

    function unpackExchangeData(bytes memory _data) public pure returns(ExchangeData memory _exData) {
        _exData = abi.decode(_data, (ExchangeData));
    }
}





abstract contract IOffchainWrapper is DFSExchangeData {
    function takeOrder(
        ExchangeData memory _exData,
        ExchangeActionType _type
    ) virtual public payable returns (bool success, uint256);
}





abstract contract IWETH {
    function allowance(address, address) public virtual view returns (uint256);

    function balanceOf(address) public virtual view returns (uint256);

    function approve(address, uint256) public virtual;

    function transfer(address, uint256) public virtual returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) public virtual returns (bool);

    function deposit() public payable virtual;

    function withdraw(uint256) public virtual;
}






library TokenUtils {
    using SafeERC20 for IERC20;

    address public constant WSTETH_ADDR = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant STETH_ADDR = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    address public constant WETH_ADDR = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function approveToken(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) internal {
        if (_tokenAddr == ETH_ADDR) return;

        if (IERC20(_tokenAddr).allowance(address(this), _to) < _amount) {
            IERC20(_tokenAddr).safeApprove(_to, _amount);
        }
    }

    function pullTokensIfNeeded(
        address _token,
        address _from,
        uint256 _amount
    ) internal returns (uint256) {
        // handle max uint amount
        if (_amount == type(uint256).max) {
            _amount = getBalance(_token, _from);
        }

        if (_from != address(0) && _from != address(this) && _token != ETH_ADDR && _amount != 0) {
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        }

        return _amount;
    }

    function withdrawTokens(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (_amount == type(uint256).max) {
            _amount = getBalance(_token, address(this));
        }

        if (_to != address(0) && _to != address(this) && _amount != 0) {
            if (_token != ETH_ADDR) {
                IERC20(_token).safeTransfer(_to, _amount);
            } else {
                (bool success, ) = _to.call{value: _amount}("");
                require(success, "Eth send fail");
            }
        }

        return _amount;
    }

    function depositWeth(uint256 _amount) internal {
        IWETH(WETH_ADDR).deposit{value: _amount}();
    }

    function withdrawWeth(uint256 _amount) internal {
        IWETH(WETH_ADDR).withdraw(_amount);
    }

    function getBalance(address _tokenAddr, address _acc) internal view returns (uint256) {
        if (_tokenAddr == ETH_ADDR) {
            return _acc.balance;
        } else {
            return IERC20(_tokenAddr).balanceOf(_acc);
        }
    }

    function getTokenDecimals(address _token) internal view returns (uint256) {
        if (_token == ETH_ADDR) return 18;

        return IERC20(_token).decimals();
    }
}




contract Discount {
    address public owner;
    mapping(address => CustomServiceFee) public serviceFees;

    uint256 constant MAX_SERVICE_FEE = 400;

    error OnlyOwner();
    error WrongFeeValue();

    struct CustomServiceFee {
        bool active;
        uint256 amount;
    }

    constructor() {
        owner = msg.sender;
    }

    function isCustomFeeSet(address _user) public view returns (bool) {
        return serviceFees[_user].active;
    }

    function getCustomServiceFee(address _user) public view returns (uint256) {
        return serviceFees[_user].amount;
    }

    function setServiceFee(address _user, uint256 _fee) public {
        if (msg.sender != owner){
            revert OnlyOwner();
        }

        if (!(_fee >= MAX_SERVICE_FEE || _fee == 0)){
            revert WrongFeeValue();
        }

        serviceFees[_user] = CustomServiceFee({active: true, amount: _fee});
    }

    function disableServiceFee(address _user) public {
        if (msg.sender != owner){
            revert OnlyOwner();
        }

        serviceFees[_user] = CustomServiceFee({active: false, amount: 0});
    }
}







contract DFSExchangeHelper {
    
    using TokenUtils for address;
    
    error InvalidOffchainData();
    error OutOfRangeSlicingError();

    using SafeERC20 for IERC20;

    function sendLeftover(
        address _srcAddr,
        address _destAddr,
        address payable _to
    ) internal {
        // clean out any eth leftover
        TokenUtils.ETH_ADDR.withdrawTokens(_to, type(uint256).max);

        _srcAddr.withdrawTokens(_to, type(uint256).max);
        _destAddr.withdrawTokens(_to, type(uint256).max);
    }

    function sliceUint(bytes memory bs, uint256 start) internal pure returns (uint256) {
        if (bs.length < start + 32){
            revert OutOfRangeSlicingError();
        }


        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }

        return x;
    }

    function writeUint256(
        bytes memory _b,
        uint256 _index,
        uint256 _input
    ) internal pure {
        if (_b.length < _index + 32) {
            revert InvalidOffchainData();
        }

        bytes32 input = bytes32(_input);

        _index += 32;

        // Read the bytes32 from array memory
        assembly {
            mstore(add(_b, _index), input)
        }
    }
}









contract KyberAggregatorWrapper is IOffchainWrapper, DFSExchangeHelper, AdminAuth, DSMath, KyberInputScalingHelper{

    using TokenUtils for address;

    //Not enough funds
    error InsufficientFunds(uint256 available, uint256 required);

    //Order success but amount 0
    error ZeroTokensSwapped();

    using SafeERC20 for IERC20;

    /// @notice Takes order from Paraswap and returns bool indicating if it is successful
    /// @param _exData Exchange data
    /// @param _type Action type (buy or sell)
    function takeOrder(
        ExchangeData calldata _exData,
        ExchangeActionType _type
    ) override public payable returns (bool success, uint256) {
        // check that contract have enough balance for exchange and protocol fee
        uint256 tokenBalance = _exData.srcAddr.getBalance(address(this));
        if (tokenBalance < _exData.srcAmount){
            revert InsufficientFunds(tokenBalance, _exData.srcAmount);
        }

        /// @dev safeApprove is modified to always first set approval to 0, then to exact amount
        if (_type == ExchangeActionType.SELL) {
            IERC20(_exData.srcAddr).safeApprove(_exData.offchainData.allowanceTarget, _exData.srcAmount);
        } else {
            uint srcAmount = wdiv(_exData.destAmount, _exData.offchainData.price) + 1; // + 1 so we round up
            IERC20(_exData.srcAddr).safeApprove(_exData.offchainData.allowanceTarget, srcAmount);
        }

        bytes memory scaledCalldata = getScaledInputData(bytes4(_exData.offchainData.callData[:4]), _exData.offchainData.callData[4:], _exData.srcAmount);
        
        uint256 tokensBefore = _exData.destAddr.getBalance(address(this));
        (success, ) = _exData.offchainData.exchangeAddr.call(scaledCalldata);

        uint256 tokensSwapped = 0;

        if (success) {
            // get the current balance of the swapped tokens
            tokensSwapped = _exData.destAddr.getBalance(address(this)) - tokensBefore;
            if (tokensSwapped == 0){
                revert ZeroTokensSwapped();
            }
        }

        // returns all funds from src addr, dest addr and eth funds (protocol fee leftovers)
        sendLeftover(_exData.srcAddr, _exData.destAddr, payable(msg.sender));

        return (success, tokensSwapped);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external virtual payable {}
}