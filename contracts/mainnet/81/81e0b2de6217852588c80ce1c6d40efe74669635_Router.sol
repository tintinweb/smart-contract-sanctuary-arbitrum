// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IBalancer.sol";
import "./interfaces/IAdapter.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IRouter.sol";
import "./helpers/SwapExecutor.sol";

contract Router is IRouter {

    address constant ETH_IDENTIFIER = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address public immutable weth;
    SwapExecutor public immutable swapExecutor;

    constructor(address _weth, address _swapExecutor) {
        weth = _weth;
        swapExecutor = SwapExecutor(_swapExecutor);
    }

    modifier _deadline(uint32 deadline) {
        if (deadline < block.timestamp) {
            revert Expired(deadline);
        }
        _;
    }

    modifier _minAmounts(TokenAmount[] memory minAmounts, address receiver) {
        for (uint i = 0; i < minAmounts.length; i++) {
            TokenAmount memory ta = minAmounts[i];
            ta.amount += IERC20(ta.token).balanceOf(receiver);
        }

        _;

        for (uint i = 0; i < minAmounts.length; i++) {
            TokenAmount memory ta = minAmounts[i];
            uint balance = IERC20(ta.token).balanceOf(receiver);
            if (balance < ta.amount) revert InsufficientTokenRedeemed(ta.token, balance, ta.amount);
        }
    }

    function dustEstimatingInvest(
        address adapter,
        address balancer,
        address tokenIn,
        uint256 amountIn,
        uint256 minShareAmount,
        IBalancer.SwapInfo[] calldata swaps,
        uint32 deadline
    ) external payable returns (uint sharesAdded, address[] memory dustTokens, uint[] memory dustAmounts) {
        dustTokens = IAdapter(adapter).depositTokens();
        dustAmounts = new uint[](dustTokens.length);
        for (uint i = 0; i < dustTokens.length; i++) {
            dustAmounts[i] = IERC20(dustTokens[i]).balanceOf(msg.sender);
        }
        sharesAdded = invest(adapter, balancer, tokenIn, amountIn, minShareAmount, swaps, deadline);
        for (uint i = 0; i < dustTokens.length; i++) {
            if (dustTokens[i] == tokenIn) dustAmounts[i] = dustAmounts[i] - amountIn;
            dustAmounts[i] = IERC20(dustTokens[i]).balanceOf(msg.sender) - dustAmounts[i];
        }
    }

    function invest(
        address adapter,
        address balancer,
        address tokenIn,
        uint256 amountIn,
        uint256 minShareAmount,
        IBalancer.SwapInfo[] calldata swaps,
        uint32 deadline
    ) public payable override _deadline(deadline) returns (uint sharesAdded) {
        if (tokenIn == ETH_IDENTIFIER) {
            if (amountIn != msg.value) {
                revert IncorrectDepositAmount(msg.value, amountIn);
            }
            IWETH(weth).deposit{value: msg.value}();
            tokenIn = weth;
        } else {
            SafeERC20.safeTransferFrom(
                IERC20(tokenIn),
                msg.sender,
                address(this),
                amountIn
            );
        }

        uint256 totalSwapAmount = 0;
        for (uint i = 0; i < swaps.length; i++) {
            IBalancer.SwapInfo memory swap = swaps[i];
            if (swap.token != tokenIn) {
                revert IncorrectSwapToken(tokenIn, swap.token);
            }
            totalSwapAmount += swap.amount;
        }

        if (totalSwapAmount > amountIn) {
            revert SwapAmountExceedsBalance(amountIn, totalSwapAmount);
        }

        SafeERC20.safeTransfer(IERC20(tokenIn), address(swapExecutor), totalSwapAmount);
        swapExecutor.executeSwaps(swaps);

        SafeERC20.safeTransfer(IERC20(tokenIn), adapter, amountIn - totalSwapAmount);

        sharesAdded = IBalancer(balancer).invest(adapter, msg.sender);

        if (sharesAdded < minShareAmount) {
            revert InsufficientSharesMinted(sharesAdded, minShareAmount);
        }
    }

    function redeem(
        address balancer,
        uint shares, 
        IAdapter targetAdapter, 
        address receiver,
        TokenAmount[] memory minAmounts,
        uint32 deadline
    ) external override _deadline(deadline) _minAmounts(minAmounts, receiver) returns (address[] memory tokens, uint[] memory amounts) 
    {
        SafeERC20.safeTransferFrom(IERC20(balancer), msg.sender, address(this), shares);
        (tokens, amounts) = IBalancer(balancer).redeem(shares, targetAdapter, receiver);
    }

    function redeemableShares(
        address balancer
    ) external view returns (address[] memory adapters, uint[] memory amounts) {
        uint totalValue;
        (totalValue, adapters, amounts) = _adapterValues(IBalancer(balancer));
        (uint nav,) = IBalancer(balancer).totalNAV();
        uint totalSupply = IERC20(balancer).totalSupply();
        for(uint i; i < adapters.length; i++) {
            amounts[i] = _divRoundUp(amounts[i] * totalSupply,  nav);
        }
    }

    function redeemFromSeveralAdapters(
        address balancer,
        IAdapter[] memory targetAdapters,
        uint[] memory shares,
        address receiver,
        TokenAmount[] memory minAmounts,
        uint32 deadline
    )
        external _deadline(deadline) _minAmounts(minAmounts, receiver)
        returns (
            address[] memory tokens,
            uint[] memory amounts
        )
    {
        SafeERC20.safeTransferFrom(
            IERC20(balancer),
            msg.sender,
            address(this),
            _sum(shares)
        );

        for (uint i; i < targetAdapters.length; i++) {
            (address[] memory _tokens, uint[] memory _amounts) = IBalancer(
                balancer
            ).redeem(shares[i], targetAdapters[i], receiver);
            (tokens, amounts) = _merge(tokens, amounts, _tokens, _amounts);
        }
    }

    function _divRoundUp(uint numerator, uint denumerator) internal pure returns (uint) {
        return (numerator + denumerator - 1) / denumerator;
    }

    function _sum(uint[] memory elements) private pure returns (uint total) {
        for(uint i; i < elements.length; i++) {
            total += elements[i];
        }
    }

    function _merge(
        address[] memory addressesA,
        uint[] memory amountsA,
        address[] memory addressesB,
        uint[] memory amountsB
    ) private pure returns (address[] memory, uint[] memory) {
        if (addressesA.length == 0) return (addressesB, amountsB);
        if (addressesB.length == 0) return (addressesA, amountsA);
        for (uint i; i < addressesB.length; i++) {
            uint indexInA = addressesA.length;
            for (uint j; j < addressesA.length; j++) {
                if (addressesA[j] == addressesB[i]) {
                    indexInA = j;
                    break;
                }
            }
            if (indexInA == addressesA.length) {
                address[] memory _addresses = new address[](indexInA + 1);
                uint[] memory _amounts = new uint[](indexInA + 1);
                for (uint j; j < addressesA.length; j++) {
                    _addresses[j] = addressesA[j];
                    _amounts[j] = amountsA[j];
                }
                addressesA = _addresses;
                amountsA = _amounts;
                addressesA[indexInA] = addressesB[i];
            }
            amountsA[indexInA] += amountsB[i];
        }
        return (addressesA, amountsA);
    }

    function _adapterValues(
        IBalancer balancer
    )
        private
        view
        returns (
            uint totalValue,
            address[] memory adapters,
            uint[] memory values
        )
    {
        adapters = balancer.chargedAdapters();
        values = new uint[](adapters.length);

        for (uint i = 0; i < adapters.length; i++) {
            IAdapter adapter = IAdapter(adapters[i]);
            (uint v, ) = adapter.value();
            totalValue += v;
            values[i] = v;
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
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

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
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
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./IAdapter.sol";

interface IBalancer {

    struct SwapInfo {
        address callee; // 1inch callee
        bytes data; // 1inch swap data
        uint256 amount; // amount to swap
        address token; // token to swap
    }

    struct TransferInfo {
        uint256 amount; // amount to transfer
        address token; // token to transfer
    }

    struct AdapterCache {
        uint value;    // equivalent value
        uint lpAmount; // amount of controlled underlying LP tokens
    }

    event Invest(address indexed adapter, address from, uint totalValueBefore, uint valueAdded, uint sharesWithFee, uint sharesMinted);
    event Redeem(address indexed adapter, address to, uint shares, uint totalValueBefore, uint valueSubtracted);
    event Rebalance(address indexed fromAdapter, address indexed toAdapter, uint amount);
    event FeeLocked(uint valueBefore, uint feeLocked, uint lockedUntil);
    event AdapterActivityChanged(address adapter, bool active);
    event AdapterAdded(address adapter);
    event AdapterRemoved(address adapter);
    event FeeReceiverChanged(address oldFeeReceiver, address newFeeReceiver);
    event Compound(address adapter, uint totalValueBefore, uint valueAdded, uint tokensBought, uint fee);
    event RewardLocked(uint256 reward, uint lockedUntil);
    event TakePerformanceFee(uint112 feeValue, uint totalValue);
    event Harvest(address indexed user, uint256 reward);
    event SwapPoolAddressAdded(address);
    event SwapPoolAddressRemoved(address);
    event Donated(address donor, uint amount);

    error InsufficientFunds(uint has, uint wants);
    error AdapterRedeemExceeds(uint adapterValue, uint redeemValue);
    error EmptyRedeem(uint shares, uint redeemValue, address adapter, uint adapterValue, uint adapterLpAmount);
    error SharesInflationError(uint valueAdded, uint valuePrior);
    error InvalidAdapter(address adapter);
    error ValueLost(uint diff);
    error MinRebalanceSlippageExceeds(uint minRebalancedValue, uint actualValueAfter);
    error Cooldown(uint until);
    error AdapterNotEmpty(address adapter);
    error DeactivationFailed(address adapter);
    error InvalidPerformanceFee(uint performanceFee);
    error HugePerformanceFee(uint performanceFee, uint totalValue);
    error Expired(uint deadline);
    error UpgradeAdaptersDontMatch(address sourceAdapter, address targetAdatper);
    error ArrayIndexOutOfBounds();

    function invest(address targetAdapter, address receiver) external returns (uint sharesAdded);
    function invest(address targetAdapter, address receiver, address dustReceiver) external returns (uint sharesAdded);
    function redeem(uint shares, IAdapter targetAdapter, address receiver)
        external
        returns (
            address[] memory tokens,
            uint[] memory amounts
        );
    function totalNAV() external view returns (uint nav, uint112 lockedFee);
    function totalValue() external view returns (uint value);
    function adapters() external view returns (address[] memory);
    function chargedAdapters() external view returns (address[] memory);
    function swapExecutor() external view returns(address);

    //╔═══════════════════════════════════════════ ADMINISTRATIVE FUNCTIONS ═══════════════════════════════════════════╗
    function rebalance(
        IAdapter fromAdapter,
        IAdapter toAdapter,
        uint amount,
        SwapInfo[] calldata swaps,
        TransferInfo[] calldata transfers,
        uint minRebalancedValue,
        uint32 deadline
    ) external;
    function compound(
        address adapter, 
        uint performanceFee, 
        SwapInfo[] calldata swaps,
        uint256 minTokensBought, 
        uint32 deadline
    ) external returns (uint tokensBought, uint liquidityMinted);
    function compoundToExternalBalancer(
        address adapter, 
        uint performanceFee, 
        SwapInfo[] calldata swaps,
        address balancerOrFromToken,
        address externalAdapter,
        uint256 minTokensBought,
        uint32 deadline
    ) external  returns (uint tokensBought, uint liquidityMinted);

    function addAdapter(address adapterAddress) external returns (bool);
    function removeAdapter(address adapterAddress) external returns (bool);
    function activateAdapter(address adapterAddress) external returns (bool);
    function deactivateAdapter(address adapterAddress) external;
    function upgradeAdapter(IAdapter sourceAdapter, IAdapter targetAdapter, uint32 deadline)  external;
    function setFeeReceiver(address feeReceiver_) external;
    function takePerformanceFee(uint112 feeValue, uint256 minTokensBought, uint32 deadline) external;
    function recoverFunds(address adapter, TransferInfo calldata transfer, address to) external;
    function addSwapPoolAddress(address swapPool) external;
    function removeSwapPoolAddress(uint index) external;

    //╔═══════════════════════════════════════════ GAUGE FUNCTIONS ═══════════════════════════════════════════╗
    function lastTimeRewardApplicable() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function getReward() external;
    function getSwapPoolsReward() external returns (uint reward);
    function donate(uint amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./IBalancer.sol";

interface IAdapter {

    struct CallInfo {
        address callee;
        bytes data;
    }

    error UnsolvableRatio(uint balance0, uint balance1, uint r0, uint r1);
    error UnsupportedToken(address token);
    error ZeroReserveBalance(uint reserve0, uint reserve1);

    function invest(address dustReceiver) external returns (uint valueBefore, uint valueAfter);
    function redeem(uint lpAmount, address receiver)
        external
        returns (
            address[] memory tokens,
            uint[] memory amounts
        );
    function compound(IBalancer.SwapInfo[] calldata swaps) external returns (uint leqBefore,uint leqAfter);
    function claim() external;
    function claim(address receiver)
        external
        returns (address[] memory rewardTokens, uint[] memory rewardsClaimed, uint[] memory rewardBalances);
    function recoverFunds(IBalancer.TransferInfo calldata transfer, address to) external;
    function negotiableTokens() external returns(address[] memory tokens);
    function pendingRewards() external view returns(address[] memory tokens, uint[] memory amounts);
    function depositTokens() external view returns (address[] memory tokens);
    function value()  external view returns (uint estimatedValue, uint lpAmount);
    function ratios() external view returns(address[] memory tokens, uint[] memory ratio);
    function description() external returns (string memory);
    function balancer() external view returns(address balancer);
    function emergencyCall(CallInfo[] calldata calls) external;

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {

    function deposit() external payable;
    function withdraw(uint256 amount) external;

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./IBalancer.sol";

interface IRouter {

    struct TokenAmount {
        address token;
        uint256 amount;
    }

    error InsufficientSharesMinted(uint minted, uint minAmount);
    error InsufficientTokenRedeemed(address token, uint balance, uint expectedBalance);
    error SwapAmountExceedsBalance(uint amountIn, uint totalSwapAmount);
    error IncorrectDepositAmount(uint has, uint wants);
    error IncorrectSwapToken(address tokenIn, address swapToken);
    error Expired(uint deadline);

    function invest(
        address adapter,
        address balancer,
        address tokenIn,
        uint256 amountIn,
        uint256 minShareAmount,
        IBalancer.SwapInfo[] calldata swaps,
        uint32 deadline
    ) external payable returns (uint sharesAdded);

    function redeem(
        address balancer,
        uint shares, 
        IAdapter targetAdapter, 
        address receiver,
        TokenAmount[] memory minAmounts,
        uint32 deadline
    ) external returns (address[] memory tokens, uint[] memory amounts);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IBalancer.sol";
import "../interfaces/uniswap/IV3SwapRouter.sol";

contract SwapExecutor {
    using SafeERC20 for IERC20;
    IV3SwapRouter public immutable UNISWAP_ROUTER;
    uint24 public immutable UNISWAP_POOL_FEE;

    constructor(uint24 _uniswapPoolFee, address _uniswapRouter) {
        UNISWAP_POOL_FEE = _uniswapPoolFee;
        UNISWAP_ROUTER = IV3SwapRouter(_uniswapRouter);
    }

    function executeSwaps(IBalancer.SwapInfo[] calldata swaps) public {
        for (uint i = 0; i < swaps.length; i++) {
            IBalancer.SwapInfo calldata swap = swaps[i];
            IERC20(swap.token).forceApprove(swap.callee, swap.amount);
            Address.functionCall(swap.callee, swap.data);
        }
    }

    function defaultSwap(
        address fromToken,
        address toToken,
        uint256 amountOutMinimum
    ) external virtual returns (uint256 toAmount) {
        uint256 fromAmount = IERC20(fromToken).balanceOf(address(this));
        IERC20(fromToken).forceApprove(address(UNISWAP_ROUTER), fromAmount);

        toAmount = UNISWAP_ROUTER.exactInputSingle(
            IV3SwapRouter.ExactInputSingleParams(
                fromToken,
                toToken,
                UNISWAP_POOL_FEE,
                msg.sender,
                fromAmount,
                amountOutMinimum,
                0
            )
        );
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

interface IV3SwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}