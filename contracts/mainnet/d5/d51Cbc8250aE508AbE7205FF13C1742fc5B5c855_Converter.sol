// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IConvertHelper} from "./interfaces/IConvertHelper.sol";

error InsufficientBalance();
error InvalidAddress();
error InvalidAmount();
error InsufficientReward();
error NotDepositor();
error TimeNotPassed();
error CannotDecreaseFee();

/// @title Converter for PortalsV1 and V2 on Arbitrum
/// @author Possum Labs
/// @notice This contract allows users to deposit PSM to be used in the convert arbitrage of Portals
/* Users must deposit PSM in multiples of 100k and determine an exchange token and the desired exchange rate
/* Deposits and exchange conditions are registered in a public mapping to be queried by bots
/* if conditions are met, bots can execute arbitrage with tokens of depositors and receive an execution reward 
*/
contract Converter {
    constructor() {
        enabledTokens[address(USDC)] = true;
        enabledTokens[address(USDCE)] = true;
        enabledTokens[address(WETH)] = true;
        enabledTokens[address(WBTC)] = true;
        enabledTokens[address(ARB)] = true;
        enabledTokens[address(LINK)] = true;

        feeUpdateTime = block.timestamp;
    }

    using SafeERC20 for IERC20;

    ////////////////////////////////
    // Variables
    ////////////////////////////////
    IERC20 public constant PSM = IERC20(0x17A8541B82BF67e10B0874284b4Ae66858cb1fd5);
    IERC20 private constant USDC = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    IERC20 private constant USDCE = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    IERC20 private constant WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    IERC20 private constant WBTC = IERC20(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);
    IERC20 private constant ARB = IERC20(0x912CE59144191C1204E64559FE8253a0e49E6548);
    IERC20 private constant LINK = IERC20(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4);

    address private constant V1_HLP_PORTAL = 0x24b7d3034C711497c81ed5f70BEE2280907Ea1Fa;
    address private constant V2_USDC_PORTAL = 0x9167CFf02D6f55912011d6f498D98454227F4e16;
    address private constant V2_USDCE_PORTAL = 0xE8EfFf304D01aC2D9BA256b602D736dB81f20984;
    address private constant V2_ETH_PORTAL = 0xe771545aaDF6feC3815B982fe2294F7230C9c55b;
    address private constant V2_WBTC_PORTAL = 0x919B37b5f2f1DEd2a1f6230Bf41790e27b016609;
    address private constant V2_ARB_PORTAL = 0x523a93037c47Ba173E9080FE8EBAeae834c24082;
    address private constant V2_LINK_PORTAL = 0x51623b54753E07Ba9B3144Ba8bAB969D427982b6;

    address private constant PSM_TREASURY = 0xAb845D09933f52af5642FC87Dd8FBbf553fd7B33;

    IConvertHelper convertHelper = IConvertHelper(0xa94f0513b41e8C0c6E96B76ceFf2e28cAA3F5ebb);

    uint256 private constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint256 public constant PSM_AMOUNT_FOR_CONVERT = 100000 * 1e18; // 100k PSM to execute convert
    uint256 public constant ORDER_CREATION_FEE_PSM = 1000 * 1e18; // 1k PSM to avoid spam orders
    uint256 public feeUpdateTime; // time of last fee updating
    uint256 private constant SECONDS_PER_YEAR = 31536000; // seconds in a 365 day year
    uint256 public executionRewardPercent = 5;

    struct Order {
        address depositor;
        address tokenRequested;
        uint256 minReceivedPer100kPSM;
        uint256 psmDeposit;
    }

    mapping(uint256 orderID => Order) public orders; // order details for a given ID
    mapping(address => bool) public enabledTokens; // Yield tokens that can be retrieved from Portals

    uint256 public orderIndex; // the ID of the most recent order, i.e. sum of all orders ever generated

    ////////////////////////////////
    // Events
    ////////////////////////////////
    event OrderCreated(address indexed depositor, uint256 indexed orderID);
    event OrderUpdated(uint256 indexed orderID, Order details);
    event ArbitrageExecuted(uint256 indexed orderID, address indexed tokenReceived, uint256 amount);

    ////////////////////////////////
    // depositor functions
    ////////////////////////////////
    /// @notice This function allows users to deposit multiples of 100k PSM to be used in arbitrage
    /// @dev User must specify a requested token address that is part of the allowed tokens mapping
    /// @dev User must set the amount of above specified token expected per exchanged 100k PSM
    /// @dev User must deposit a multiple of 100k PSM to avoid remainders
    /// @dev User must pay 1k PSM to create the order (Spam protection)
    function createOrder(address _tokenRequested, uint256 _minReceivedPer100kPSM, uint256 _amount) external {
        // Input validation
        if (!enabledTokens[_tokenRequested]) revert InvalidAddress();
        if (_minReceivedPer100kPSM == 0) revert InvalidAmount();
        if (_amount == 0 || _amount % PSM_AMOUNT_FOR_CONVERT > 0) revert InvalidAmount();

        address depositor = msg.sender;

        // Create a new Order struct and add to mapping
        Order storage newOrder = orders[orderIndex];
        newOrder.depositor = depositor;
        newOrder.tokenRequested = _tokenRequested;
        newOrder.minReceivedPer100kPSM = _minReceivedPer100kPSM;
        newOrder.psmDeposit = _amount;

        // Increase the Order Index to avoid overwriting old orders
        orderIndex++;

        // Pay the order fee of 1k PSM to the treasury (Spam protection)
        PSM.transferFrom(depositor, PSM_TREASURY, ORDER_CREATION_FEE_PSM);

        // transfer PSM deposit to contract
        PSM.transferFrom(depositor, address(this), _amount);

        // emit events
        emit OrderCreated(msg.sender, orderIndex - 1);
        emit OrderUpdated(orderIndex - 1, newOrder);
    }

    /// @notice This function allows users to increase their PSM deposit on an existing order
    /// @dev User must specify an owned order ID and the amount of PSM to add to the order
    /// @dev User must deposit a multiple of 100k PSM
    function increaseOrder(uint256 _orderID, uint256 _amount) external {
        // input validation - only the depositor can increase the order
        Order storage order = orders[_orderID];
        if (msg.sender != order.depositor) revert NotDepositor();
        if (_amount == 0 || _amount % PSM_AMOUNT_FOR_CONVERT > 0) revert InvalidAmount();

        // Increase Order amount
        order.psmDeposit += _amount;

        // Transfer PSM to top up the order
        PSM.transferFrom(msg.sender, address(this), _amount);

        // emit event that order was updated
        emit OrderUpdated(_orderID, order);
    }

    /// @notice This function allows users to withdraw PSM from an existing order
    /// @dev User must specify an owned order ID and the amount of PSM to withdraw from the order
    /// @dev User must withdraw a multiple of 100k PSM
    function decreaseOrder(uint256 _orderID, uint256 _amount) external {
        // input validation - only the depositor can decrease the order
        Order storage order = orders[_orderID];
        if (msg.sender != order.depositor) revert NotDepositor();
        if (_amount == 0 || _amount % PSM_AMOUNT_FOR_CONVERT > 0) revert InvalidAmount();
        if (_amount > order.psmDeposit) revert InsufficientBalance();

        // Decrease order amount
        order.psmDeposit -= _amount;

        // Transfer withdrawn tokens to depositor
        PSM.transfer(msg.sender, _amount);

        // emit event that the order was updated
        emit OrderUpdated(_orderID, order);
    }

    ////////////////////////////////
    // Bot functions
    ////////////////////////////////
    /// @notice This function checks if the arbitrage conditions for a given order ID are met
    /// @dev Check if the arbitrage can be executed for sufficient rewards
    /// @dev Returns the amount of tokens received
    /// @dev Returns the portal address that this arbitrage order ID will interact with
    function checkArbitrage(uint256 _orderID)
        public
        view
        returns (bool canExecute, address portal, uint256 amountReceived)
    {
        // Check if Order has enough PSM deposited
        Order memory order = orders[_orderID];
        if (order.psmDeposit >= PSM_AMOUNT_FOR_CONVERT) {
            // Calculate the accumulated rewards of the related Portal
            // Get the related Portal address
            if (order.tokenRequested == address(USDC)) {
                amountReceived = convertHelper.V2_getRewards(V2_USDC_PORTAL);
                portal = V2_USDC_PORTAL;
            }
            if (order.tokenRequested == address(USDCE)) {
                uint256 rewardsV1 = convertHelper.V1_getRewardsUSDCE();
                uint256 rewardsV2 = convertHelper.V2_getRewards(V2_USDCE_PORTAL);
                amountReceived = (rewardsV1 > rewardsV2) ? rewardsV1 : rewardsV2;
                portal = (rewardsV1 > rewardsV2) ? V1_HLP_PORTAL : V2_USDCE_PORTAL;
            }
            if (order.tokenRequested == address(WETH)) {
                amountReceived = convertHelper.V2_getRewards(V2_ETH_PORTAL);
                portal = V2_ETH_PORTAL;
            }
            if (order.tokenRequested == address(WBTC)) {
                amountReceived = convertHelper.V2_getRewards(V2_WBTC_PORTAL);
                portal = V2_WBTC_PORTAL;
            }
            if (order.tokenRequested == address(ARB)) {
                amountReceived = convertHelper.V2_getRewards(V2_ARB_PORTAL);
                portal = V2_ARB_PORTAL;
            }
            if (order.tokenRequested == address(LINK)) {
                amountReceived = convertHelper.V2_getRewards(V2_LINK_PORTAL);
                portal = V2_LINK_PORTAL;
            }

            // Check if arbitrage can be executed after accounting for execution reward
            uint256 threshold = (order.minReceivedPer100kPSM * (100 + executionRewardPercent)) / 100;
            if (amountReceived >= threshold) {
                canExecute = true;
            }
        }
    }

    /// @notice This function executes the arbitrage of a certain order ID if conditions are met
    /// @dev Check if the arbitrage can be executed
    /// @dev Get the expected arbitrage token amount and Portal address to interact with
    /// @dev Calculate the reward for the executor
    /// @dev Update the order information, execute the arbitrage and send tokens to executor and depositor
    function executeArbitrage(uint256 _orderID) external {
        // check the arbitrage condition
        (bool canExecute, address portal, uint256 amountReceived) = checkArbitrage(_orderID);
        if (!canExecute) revert InsufficientReward();

        // Load order information
        Order storage order = orders[_orderID];

        // Update the Order information
        order.psmDeposit -= PSM_AMOUNT_FOR_CONVERT;

        // Check which Portal is targeted and execute arbitrage via the convertHelper contract
        if (portal == V1_HLP_PORTAL) convertHelper.V1_convertUSDCE(address(this), amountReceived);
        else convertHelper.V2_convert(portal, address(this), amountReceived);

        // Calculate arbitrage amount for depositor and rewards for executor
        uint256 executorReward = amountReceived - ((amountReceived * 100) / (100 + executionRewardPercent));
        uint256 arbitrageAmount = amountReceived - executorReward;

        // Send tokens to depositor and executor
        IERC20(order.tokenRequested).safeTransfer(msg.sender, executorReward);
        IERC20(order.tokenRequested).safeTransfer(order.depositor, arbitrageAmount);

        // Emit event with updated Order information and execution of arbitrage
        emit OrderUpdated(_orderID, order);
        emit ArbitrageExecuted(_orderID, order.tokenRequested, arbitrageAmount);
    }

    ////////////////////////////////
    // Helper functions
    ////////////////////////////////
    /// @dev Allow spending of PSM by the ConvertHelper contract to execute the arbitrage
    function setApprovals() external {
        PSM.approve(address(convertHelper), MAX_UINT);
    }

    /// @dev Reduce the execution fee by 1% every year until it reaches 1%
    function updateExecutionFee() external {
        uint256 timePassed = block.timestamp - feeUpdateTime;
        if (timePassed < SECONDS_PER_YEAR) revert TimeNotPassed();
        if (executionRewardPercent == 1) revert CannotDecreaseFee();
        executionRewardPercent -= 1;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface IConvertHelper {
    function V1_getRewardsUSDCE() external view returns (uint256 availableReward);
    function V2_getRewards(address _portal) external view returns (uint256 availableReward);

    function V1_convertUSDCE(address _recipient, uint256 _minReceived) external;
    function V2_convert(address _portal, address _recipient, uint256 _minReceived) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.19;

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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.19;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.19;

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