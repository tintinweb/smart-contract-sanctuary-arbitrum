// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./ConveyorErrors.sol";
import {IERC20} from "../lib/interfaces/token/IERC20.sol";
import {SafeERC20} from "../lib/libraries/token/SafeERC20.sol";
import {ConveyorMath} from "./lib/ConveyorMath.sol";
import {ConveyorSwapCallbacks} from "./callbacks/ConveyorSwapCallbacks.sol";
import {IConveyorRouterV1} from "./interfaces/IConveyorRouterV1.sol";

interface IConveyorMulticall {
    function executeMulticall(ConveyorRouterV1.SwapAggregatorMulticall calldata genericMulticall) external;
}

/// @title ConveyorRouterV1
/// @author 0xKitsune, 0xOsiris, Conveyor Labs
/// @notice Multicall contract for token Swaps.
contract ConveyorRouterV1 is IConveyorRouterV1 {
    using SafeERC20 for IERC20;

    address public CONVEYOR_MULTICALL;
    address public immutable WETH;

    address owner;
    address tempOwner;

    uint128 internal constant AFFILIATE_PERCENT = 5534023222112865000;
    uint128 internal constant REFERRAL_PERCENT = 5534023222112865000;
    uint128 immutable REFERRAL_INITIALIZATION_FEE;

    /**
     * @notice Event that is emitted when ETH is withdrawn from the contract
     *
     */
    event Withdraw(address indexed receiver, uint256 amount);

    ///@notice Modifier function to only allow the owner of the contract to call specific functions
    ///@dev Functions with onlyOwner: withdraw
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert MsgSenderIsNotOwner();
        }

        _;
    }

    ///@notice Mapping from uint16 to affiliate address.
    mapping(uint16 => address) public affiliates;
    ///@notice Mapping from uint16 to referrer address.
    mapping(uint16 => address) public referrers;

    ///@notice Mapping from affiliate address to affiliate index.
    mapping(address => uint16) public affiliateIndex;
    ///@notice Mapping from referrer address to referrer index.
    mapping(address => uint16) public referrerIndex;

    ///@notice Current Nonce for affiliate addresses.
    uint16 public affiliateNonce;
    ///@notice Current Nonce for referrer addresses.
    uint16 public referrerNonce;

    ///@dev Deploys the ConveyorSwapExecutor contract.
    ///@param _weth Address of Wrapped Native Asset.
    ///@param _referralInitializationFee Fee required to initialize a referral address.
    constructor(address _weth, uint128 _referralInitializationFee) payable {
        require(_weth != address(0), "WETH address is zero");
        require(_referralInitializationFee > 0, "Referral initialization fee is zero");
        REFERRAL_INITIALIZATION_FEE = _referralInitializationFee;
        CONVEYOR_MULTICALL = address(new ConveyorMulticall());
        WETH = _weth;
        owner = tx.origin;
    }

    ///@notice Struct for token to token swap data.
    struct TokenToTokenSwapData {
        address tokenIn;
        address tokenOut;
        uint112 amountIn;
        uint112 amountOutMin;
        uint16 affiliate;
        uint16 referrer;
    }

    ///@notice Struct for token to ETH swap data.
    struct TokenToEthSwapData {
        address tokenIn;
        uint112 amountIn;
        uint112 amountOutMin;
        uint16 affiliate;
        uint16 referrer;
    }

    ///@notice Struct for ETH to token swap data.
    struct EthToTokenSwapData {
        address tokenOut;
        uint112 amountOutMin;
        uint112 protocolFee;
        uint16 affiliate;
        uint16 referrer;
    }

    /// @notice Gas optimized Multicall struct
    struct SwapAggregatorMulticall {
        address tokenInDestination;
        Call[] calls;
    }

    /// @notice Call struct for token Swaps.
    /// @param target Address to call.
    /// @param callData Data to call.
    struct Call {
        address target;
        bytes callData;
    }

    /// @notice Swap tokens for tokens.
    /// @param swapData The swap data for the transaction.
    /// @param genericMulticall Multicall to be executed.
    function swapExactTokenForToken(
        TokenToTokenSwapData calldata swapData,
        SwapAggregatorMulticall calldata genericMulticall
    ) public payable {
        ///@notice Transfer tokenIn from msg.sender to tokenInDestination address.
        IERC20(swapData.tokenIn).transferFrom(msg.sender, genericMulticall.tokenInDestination, swapData.amountIn);

        ///@notice Get tokenOut balance of msg.sender.
        uint256 balanceBefore = IERC20(swapData.tokenOut).balanceOf(msg.sender);
        ///@notice Calculate tokenOut amount required.
        uint256 tokenOutAmountRequired = balanceBefore + swapData.amountOutMin;

        ///@notice Execute Multicall.
        IConveyorMulticall(CONVEYOR_MULTICALL).executeMulticall(genericMulticall);

        uint256 balanceAfter = IERC20(swapData.tokenOut).balanceOf(msg.sender);

        ///@notice Check if tokenOut balance of msg.sender is sufficient.
        if (balanceAfter < tokenOutAmountRequired) {
            revert InsufficientOutputAmount(tokenOutAmountRequired - balanceAfter, swapData.amountOutMin);
        }
        if (swapData.affiliate & 0x1 != 0x0) {
            address affiliate = affiliates[swapData.affiliate >> 0x1];
            if (affiliate == address(0)) {
                revert AffiliateDoesNotExist();
            }
            _safeTransferETH(affiliate, ConveyorMath.mul64U(AFFILIATE_PERCENT, msg.value));
        }
        ///@dev First bit of referrer is used to check if referrer exists
        if (swapData.referrer & 0x1 != 0x0) {
            address referrer = referrers[swapData.referrer >> 0x1];
            if (referrer == address(0)) {
                revert ReferrerDoesNotExist();
            }
            _safeTransferETH(referrer, ConveyorMath.mul64U(REFERRAL_PERCENT, msg.value));
        }
    }

    /// @notice Swap ETH for tokens.
    /// @param swapData The swap data for the transaction.
    /// @param swapAggregatorMulticall Multicall to be executed.
    function swapExactEthForToken(
        EthToTokenSwapData calldata swapData,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) public payable {
        if (swapData.protocolFee > msg.value) {
            revert InsufficientMsgValue();
        }

        ///@notice Cache the amountIn to save gas.
        uint256 amountIn = msg.value - swapData.protocolFee;

        ///@notice Deposit the msg.value-protocolFee into WETH.
        _depositEth(amountIn, WETH);

        ///@notice Transfer WETH from WETH to tokenInDestination address.
        IERC20(WETH).transfer(swapAggregatorMulticall.tokenInDestination, amountIn);

        ///@notice Get tokenOut balance of msg.sender.
        uint256 balanceBefore = IERC20(swapData.tokenOut).balanceOf(msg.sender);

        ///@notice Calculate tokenOut amount required.
        uint256 tokenOutAmountRequired = balanceBefore + swapData.amountOutMin;

        ///@notice Execute Multicall.
        IConveyorMulticall(CONVEYOR_MULTICALL).executeMulticall(swapAggregatorMulticall);

        ///@notice Get tokenOut balance of msg.sender after multicall execution.
        uint256 balanceAfter = IERC20(swapData.tokenOut).balanceOf(msg.sender);

        ///@notice Revert if tokenOut balance of msg.sender is insufficient.
        if (balanceAfter < tokenOutAmountRequired) {
            revert InsufficientOutputAmount(tokenOutAmountRequired - balanceAfter, swapData.amountOutMin);
        }
        if (swapData.affiliate & 0x1 != 0x0) {
            address affiliate = affiliates[swapData.affiliate >> 0x1];
            if (affiliate == address(0)) {
                revert AffiliateDoesNotExist();
            }
            _safeTransferETH(affiliate, ConveyorMath.mul64U(AFFILIATE_PERCENT, swapData.protocolFee));
        }
        ///@dev First bit of referrer is used to check if referrer exists
        if (swapData.referrer & 0x1 != 0x0) {
            address referrer = referrers[swapData.referrer >> 0x1];
            if (referrer == address(0)) {
                revert ReferrerDoesNotExist();
            }
            _safeTransferETH(referrer, ConveyorMath.mul64U(REFERRAL_PERCENT, swapData.protocolFee));
        }
    }

    /// @notice Swap tokens for ETH.
    /// @param swapData The swap data for the transaction.
    /// @param swapAggregatorMulticall Multicall to be executed.
    function swapExactTokenForEth(
        TokenToEthSwapData calldata swapData,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) public payable {
        ///@dev Ignore if the tokenInDestination is address(0).
        if (swapAggregatorMulticall.tokenInDestination != address(0)) {
            ///@notice Transfer tokenIn from msg.sender to tokenInDestination address.
            IERC20(swapData.tokenIn).transferFrom(
                msg.sender, swapAggregatorMulticall.tokenInDestination, swapData.amountIn
            );
        }
        ///@notice Get ETH balance of msg.sender.
        uint256 balanceBefore = msg.sender.balance;

        ///@notice Calculate amountOutRequired.
        uint256 amountOutRequired = balanceBefore + swapData.amountOutMin;

        ///@notice Execute Multicall.
        IConveyorMulticall(CONVEYOR_MULTICALL).executeMulticall(swapAggregatorMulticall);

        ///@notice Get WETH balance of this contract.
        uint256 balanceWeth = IERC20(WETH).balanceOf(address(this));

        ///@notice Withdraw WETH from this contract.
        _withdrawEth(balanceWeth, WETH);

        ///@notice Transfer ETH to msg.sender.
        _safeTransferETH(msg.sender, balanceWeth);

        ///@notice Revert if Eth balance of the caller is insufficient.
        if (msg.sender.balance < amountOutRequired) {
            revert InsufficientOutputAmount(amountOutRequired - msg.sender.balance, swapData.amountOutMin);
        }
        if (swapData.affiliate & 0x1 != 0x0) {
            address affiliate = affiliates[swapData.affiliate >> 0x1];
            if (affiliate == address(0)) {
                revert AffiliateDoesNotExist();
            }
            _safeTransferETH(affiliate, ConveyorMath.mul64U(AFFILIATE_PERCENT, msg.value));
        }
        ///@dev First bit of referrer is used to check if referrer exists
        if (swapData.referrer & 0x1 != 0x0) {
            address referrer = referrers[swapData.referrer >> 0x1];
            if (referrer == address(0)) {
                revert ReferrerDoesNotExist();
            }
            _safeTransferETH(referrer, ConveyorMath.mul64U(REFERRAL_PERCENT, msg.value));
        }
    }

    /// @notice Quotes the amount of gas used for a optimized token to token swap.
    /// @dev This function should be used off chain through a static call.
    function quoteSwapExactTokenForToken(
        TokenToTokenSwapData calldata swapData,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable returns (uint256 gasConsumed) {
        assembly {
            mstore(0x60, gas())
        }
        swapExactTokenForToken(swapData, swapAggregatorMulticall);
        assembly {
            gasConsumed := sub(mload(0x60), gas())
        }
    }

    /// @notice Quotes the amount of gas used for a ETH to token swap.
    /// @dev This function should be used off chain through a static call.
    function quoteSwapExactEthForToken(
        EthToTokenSwapData calldata swapData,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable returns (uint256 gasConsumed) {
        assembly {
            mstore(0x60, gas())
        }
        swapExactEthForToken(swapData, swapAggregatorMulticall);
        assembly {
            gasConsumed := sub(mload(0x60), gas())
        }
    }

    /// @notice Quotes the amount of gas used for a token to ETH swap.
    /// @dev This function should be used off chain through a static call.
    function quoteSwapExactTokenForEth(
        TokenToEthSwapData calldata swapData,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable returns (uint256 gasConsumed) {
        assembly {
            mstore(0x60, gas())
        }
        swapExactTokenForEth(swapData, swapAggregatorMulticall);
        assembly {
            gasConsumed := sub(mload(0x60), gas())
        }
    }

    ///@notice Helper function to transfer ETH.
    function _safeTransferETH(address to, uint256 amount) internal {
        bool success;
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        if (!success) {
            revert ETHTransferFailed();
        }
    }

    /// @notice Helper function to Withdraw ETH from WETH.
    function _withdrawEth(uint256 amount, address weth) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0, shl(224, 0x2e1a7d4d) /* keccak256("withdraw(uint256)") */ )
            mstore(4, amount)
            if iszero(
                call(
                    gas(), /* gas */
                    weth, /* to */
                    0, /* value */
                    0, /* in */
                    68, /* in size */
                    0, /* out */
                    0 /* out size */
                )
            ) { revert("Native Token Withdraw failed", amount) }
        }
    }

    /// @notice Helper function to Deposit ETH into WETH.
    function _depositEth(uint256 amount, address weth) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0, shl(224, 0xd0e30db0)) /* keccak256("deposit()") */
            if iszero(
                call(
                    gas(), /* gas */
                    weth, /* to */
                    amount, /* value */
                    0, /* in */
                    0, /* in size */
                    0, /* out */
                    0 /* out size */
                )
            ) { revert("Native token deposit failed", amount) }
        }
    }

    /// @notice Withdraw ETH from this contract.
    function withdraw() external onlyOwner {
        _safeTransferETH(msg.sender, address(this).balance);
        emit Withdraw(msg.sender, address(this).balance);
    }

    ///@notice Function to confirm ownership transfer of the contract.
    function confirmTransferOwnership() external {
        if (msg.sender != tempOwner) {
            revert UnauthorizedCaller();
        }

        ///@notice Cleanup tempOwner storage.
        tempOwner = address(0);
        owner = msg.sender;
    }

    ///@notice Function to transfer ownership of the contract.
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) {
            revert InvalidAddress();
        }

        tempOwner = newOwner;
    }

    ///@notice Function to upgrade the ConveyorMulticall contract.
    function upgradeMulticall(bytes memory bytecode, bytes32 salt) external payable onlyOwner returns (address) {
        assembly {
            let addr := create2(callvalue(), add(bytecode, 0x20), mload(bytecode), salt)

            if iszero(extcodesize(addr)) { revert(0, 0) }

            sstore(CONVEYOR_MULTICALL.slot, addr)
        }

        return CONVEYOR_MULTICALL;
    }

    ///@notice Function to set affiliate address.
    function initializeAffiliate(address affiliateAddress) external onlyOwner {
        uint16 tempAffiliateNonce = affiliateNonce;
        affiliates[tempAffiliateNonce] = affiliateAddress;
        affiliateIndex[affiliateAddress] = tempAffiliateNonce;
        unchecked {
            tempAffiliateNonce++;
            require(tempAffiliateNonce < type(uint16).max >> 0x1, "Affiliate nonce overflow");
            affiliateNonce = tempAffiliateNonce;
        }
    }

    ///@notice Function to set referrer mapping.
    function initializeReferrer() external payable {
        if (referrerIndex[msg.sender] != 0) {
            revert ReferrerAlreadyInitialized();
        }
        uint16 tempReferrerNonce = referrerNonce;
        ///@dev The msg.value required to set the referral address increases over time to protect against spam.
        if (msg.value < ConveyorMath.mul64U(REFERRAL_INITIALIZATION_FEE, tempReferrerNonce * 1e18)) {
            revert InvalidReferralFee();
        }

        referrers[tempReferrerNonce] = msg.sender;
        referrerIndex[msg.sender] = tempReferrerNonce;

        unchecked {
            tempReferrerNonce++;
            require(tempReferrerNonce < type(uint16).max >> 0x1, "Referrer nonce overflow");
            referrerNonce = tempReferrerNonce;
        }
    }

    ///@dev Calculates the referrer fee.
    function calculateReferralFee() external view returns (uint256 referralFee) {
        referralFee = ConveyorMath.mul64U(REFERRAL_INITIALIZATION_FEE, referrerNonce * 10 ** 18);
    }

    /// @notice Fallback receiver function.
    receive() external payable {}
}

/// @title ConveyorMulticall
/// @author 0xOsiris, 0xKitsune, Conveyor Labs
/// @notice Optimized multicall execution contract.
contract ConveyorMulticall is IConveyorMulticall, ConveyorSwapCallbacks {
    using SafeERC20 for IERC20;

    constructor() {}

    function executeMulticall(ConveyorRouterV1.SwapAggregatorMulticall calldata multicall) external {
        for (uint256 i = 0; i < multicall.calls.length;) {
            address target = multicall.calls[i].target;
            bytes calldata callData = multicall.calls[i].callData;
            /// @solidity memory-safe-assembly
            assembly {
                let freeMemoryPointer := mload(0x40)
                calldatacopy(freeMemoryPointer, callData.offset, callData.length)
                if iszero(call(gas(), target, 0, freeMemoryPointer, callData.length, 0, 0)) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

error InsufficientWalletBalance(address account, uint256 balance, uint256 balanceNeeded);
error OrderDoesNotExist(bytes32 orderId);
error OrderQuantityIsZero();
error InsufficientOrderInputValue();
error IncongruentInputTokenInOrderGroup(address token, address expectedToken);
error TokenInIsTokenOut();
error IncongruentOutputTokenInOrderGroup(address token, address expectedToken);
error InsufficientOutputAmount(uint256 amountOut, uint256 expectedAmountOut);
error InsufficientInputAmount(uint256 amountIn, uint256 expectedAmountIn);
error InsufficientLiquidity();
error InsufficientAllowanceForOrderPlacement(address token, uint256 approvedQuantity, uint256 approvedQuantityNeeded);
error InsufficientAllowanceForOrderUpdate(address token, uint256 approvedQuantity, uint256 approvedQuantityNeeded);
error InvalidOrderGroupSequence();
error IncongruentFeeInInOrderGroup();
error IncongruentFeeOutInOrderGroup();
error IncongruentTaxedTokenInOrderGroup();
error IncongruentStoplossStatusInOrderGroup();
error IncongruentBuySellStatusInOrderGroup();
error NonEOAStoplossExecution();
error MsgSenderIsNotTxOrigin();
error MsgSenderIsNotLimitOrderRouter();
error MsgSenderIsNotLimitOrderExecutor();
error MsgSenderIsNotSandboxRouter();
error MsgSenderIsNotOwner();
error MsgSenderIsNotOrderOwner();
error MsgSenderIsNotOrderBook();
error MsgSenderIsNotLimitOrderBook();
error MsgSenderIsNotTempOwner();
error Reentrancy();
error ETHTransferFailed();
error InvalidAddress();
error UnauthorizedUniswapV3CallbackCaller();
error DuplicateOrderIdsInOrderGroup();
error InvalidCalldata();
error InsufficientMsgValue();
error UnauthorizedCaller();
error AmountInIsZero();
///@notice Returns the index of the call that failed within the SandboxRouter.Call[] array
error SandboxCallFailed(uint256 callIndex);
error InvalidTransferAddressArray();
error AddressIsZero();
error IdenticalTokenAddresses();
error InvalidInputTokenForOrderPlacement();
error SandboxFillAmountNotSatisfied(bytes32 orderId, uint256 amountFilled, uint256 fillAmountRequired);
error OrderNotEligibleForRefresh(bytes32 orderId);
error SandboxAmountOutRequiredNotSatisfied(bytes32 orderId, uint256 amountOut, uint256 amountOutRequired);
error AmountOutRequiredIsZero(bytes32 orderId);
error FillAmountSpecifiedGreaterThanAmountRemaining(
    uint256 fillAmountSpecified, uint256 amountInRemaining, bytes32 orderId
);
error ConveyorFeesNotPaid(uint256 expectedFees, uint256 feesPaid, uint256 unpaidFeesRemaining);
error InsufficientFillAmountSpecified(uint128 fillAmountSpecified, uint128 amountInRemaining);
error InsufficientExecutionCredit(uint256 msgValue, uint256 minExecutionCredit);
error WithdrawAmountExceedsExecutionCredit(uint256 amount, uint256 executionCredit);
error MsgValueIsNotCumulativeExecutionCredit(uint256 msgValue, uint256 cumulativeExecutionCredit);
error ExecutorNotCheckedIn();
error InvalidToAddressBits();
error V2SwapFailed();
error V3SwapFailed();
error CallFailed();
error InvalidReferral();
error InvalidReferralFee();
error AffiliateDoesNotExist();
error ReferrerDoesNotExist();
error ReferrerAlreadyInitialized();

// SPDX-License-Identifier: MIT
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../../interfaces/token/IERC20.sol";
import "../../interfaces/token/draft-IERC20Permit.sol";
import "../../utils/Address.sol";

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../../lib/libraries/Uniswap/FullMath.sol";

library ConveyorMath {
    /// @notice maximum uint128 64.64 fixed point number
    uint128 private constant MAX_64x64 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    uint256 private constant MAX_UINT64 = 0xFFFFFFFFFFFFFFFF;

    /// @notice minimum int128 64.64 fixed point number
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /// @notice maximum uint256 128.128 fixed point number
    uint256 private constant MAX_128x128 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice helper function to transform uint256 number to uint128 64.64 fixed point representation
    /// @param x unsigned 256 bit unsigned integer number
    /// @return unsigned 64.64 unsigned fixed point number
    function fromUInt256(uint256 x) internal pure returns (uint128) {
        unchecked {
            require(x <= MAX_UINT64);
            return uint128(x << 64);
        }
    }

    /// @notice helper function to transform 64.64 fixed point uint128 to uint64 integer number
    /// @param x unsigned 64.64 fixed point number
    /// @return unsigned uint64 integer representation
    function toUInt64(uint128 x) internal pure returns (uint64) {
        unchecked {
            return uint64(x >> 64);
        }
    }

    /// @notice helper function to transform uint128 to 128.128 fixed point representation
    /// @param x uint128 unsigned integer
    /// @return unsigned 128.128 unsigned fixed point number
    function fromUInt128(uint128 x) internal pure returns (uint256) {
        unchecked {
            require(x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            return uint256(x) << 128;
        }
    }

    /// @notice helper to convert 128x128 fixed point number to 64.64 fixed point number
    /// @param x 128.128 unsigned fixed point number
    /// @return unsigned 64.64 unsigned fixed point number
    function from128x128(uint256 x) internal pure returns (uint128) {
        unchecked {
            uint256 answer = x >> 64;
            require(answer >= 0x0 && answer <= MAX_64x64);
            return uint128(answer);
        }
    }

    /// @notice helper to convert 64.64 unsigned fixed point number to 128.128 fixed point number
    /// @param x 64.64 unsigned fixed point number
    /// @return unsigned 128.128 unsignned fixed point number
    function to128x128(uint128 x) internal pure returns (uint256) {
        unchecked {
            return uint256(x) << 64;
        }
    }

    /// @notice helper to add two unsigned 64.64 fixed point numbers
    /// @param x 64.64 unsigned fixed point number
    /// @param y 64.64 unsigned fixed point number
    /// @return unsigned 64.64 unsigned fixed point number
    function add64x64(uint128 x, uint128 y) internal pure returns (uint128) {
        unchecked {
            uint256 answer = uint256(x) + y;
            require(answer <= MAX_64x64);
            return uint128(answer);
        }
    }

    /// @notice helper to add two signed 64.64 fixed point numbers
    /// @param x 64.64 signed fixed point number
    /// @param y 64.64 signed fixed point number
    /// @return signed 64.64 unsigned fixed point number
    function sub(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) - y;
            require(result >= MIN_64x64 && result <= type(int128).max);
            return int128(result);
        }
    }

    /// @notice helper to add two unsigened 128.128 fixed point numbers
    /// @param x 128.128 unsigned fixed point number
    /// @param y 128.128 unsigned fixed point number
    /// @return unsigned 128.128 unsigned fixed point number
    function add128x128(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 answer = x + y;

        return answer;
    }

    /// @notice helper to add unsigned 128.128 fixed point number with unsigned 64.64 fixed point number
    /// @param x 128.128 unsigned fixed point number
    /// @param y 64.64 unsigned fixed point number
    /// @return unsigned 128.128 unsigned fixed point number
    function add128x64(uint256 x, uint128 y) internal pure returns (uint256) {
        uint256 answer = x + (uint256(y) << 64);

        return answer;
    }

    /// @notice helper function to multiply two unsigned 64.64 fixed point numbers
    /// @param x 64.64 unsigned fixed point number
    /// @param y 64.64 unsigned fixed point number
    /// @return unsigned
    function mul64x64(uint128 x, uint128 y) internal pure returns (uint128) {
        unchecked {
            uint256 answer = (uint256(x) * y) >> 64;
            require(answer <= MAX_64x64);
            return uint128(answer);
        }
    }

    /// @notice helper function to multiply a 128.128 fixed point number by a 64.64 fixed point number
    /// @param x 128.128 unsigned fixed point number
    /// @param y 64.64 unsigned fixed point number
    /// @return unsigned
    function mul128x64(uint256 x, uint128 y) internal pure returns (uint256) {
        if (x == 0 || y == 0) {
            return 0;
        }
        uint256 answer = (uint256(y) * x) >> 64;

        return answer;
    }

    /// @notice helper function to multiply unsigned 64.64 fixed point number by a unsigned integer
    /// @param x 64.64 unsigned fixed point number
    /// @param y uint256 unsigned integer
    /// @return unsigned
    function mul64U(uint128 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0 || x == 0) {
                return 0;
            }

            uint256 lo = (uint256(x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
            uint256 hi = uint256(x) * (y >> 128);

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            hi <<= 64;

            require(hi <= MAX_128x128 - lo);
            return hi + lo;
        }
    }

    /// @notice helper function to multiply unsigned 128.128 fixed point number by a unsigned integer
    /// @param x 128.128 unsigned fixed point number
    /// @param y uint256 unsigned integer
    /// @return unsigned
    function mul128U(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 0 || x == 0) {
            return 0;
        }

        return (x * y) >> 128;
    }

    ///@notice helper to get the absolute value of a signed integer.
    ///@param x a signed integer.
    ///@return signed 256 bit integer representing the absolute value of x.
    function abs(int256 x) internal pure returns (int256) {
        unchecked {
            return x < 0 ? -x : x;
        }
    }

    /// @notice helper function to divide two unsigned 64.64 fixed point numbers
    /// @param x 64.64 unsigned fixed point number
    /// @param y 64.64 unsigned fixed point number
    /// @return unsigned uint128 64.64 unsigned integer
    function div64x64(uint128 x, uint128 y) internal pure returns (uint128) {
        unchecked {
            require(y != 0);

            uint256 answer = (uint256(x) << 64) / y;

            require(answer <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint128(answer);
        }
    }

    /// @notice helper function to divide two unsigned 128.128 fixed point numbers
    /// @param x 128.128 unsigned fixed point number
    /// @param y 128.128 unsigned fixed point number
    /// @return unsigned uint128 128.128 unsigned integer
    function div128x128(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            require(y != 0);

            uint256 xDec = x & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            uint256 xInt = x >> 128;

            uint256 hi = xInt * (MAX_128x128 / y);
            uint256 lo = (xDec * (MAX_128x128 / y)) >> 128;

            require(hi <= MAX_128x128 - lo);
            return hi + lo;
        }
    }

    /// @notice helper function to divide two unsigned integers
    /// @param x uint256 unsigned integer number
    /// @param y uint256 unsigned integer number
    /// @return unsigned uint128 64.64 unsigned integer
    function divUU(uint256 x, uint256 y) internal pure returns (uint128) {
        unchecked {
            require(y != 0);
            uint128 answer = divuu(x, y);
            require(answer <= uint128(MAX_64x64), "overflow");

            return answer;
        }
    }

    /// @param x uint256 unsigned integer
    /// @param y uint256 unsigned integer
    /// @return unsigned 64.64 fixed point number
    function divuu(uint256 x, uint256 y) internal pure returns (uint128) {
        unchecked {
            require(y != 0);

            uint256 answer;

            if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {
                answer = (x << 64) / y;
            } else {
                uint256 msb = 192;
                uint256 xc = x >> 192;
                if (xc >= 0x100000000) {
                    xc >>= 32;
                    msb += 32;
                }
                if (xc >= 0x10000) {
                    xc >>= 16;
                    msb += 16;
                }
                if (xc >= 0x100) {
                    xc >>= 8;
                    msb += 8;
                }
                if (xc >= 0x10) {
                    xc >>= 4;
                    msb += 4;
                }
                if (xc >= 0x4) {
                    xc >>= 2;
                    msb += 2;
                }
                if (xc >= 0x2) msb += 1; // No need to shift xc anymore

                answer = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
                require(answer <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "overflow in divuu");

                uint256 hi = answer * (y >> 128);
                uint256 lo = answer * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 xh = x >> 192;
                uint256 xl = x << 64;

                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here
                lo = hi << 128;
                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here

                assert(xh == hi >> 128);

                answer += xl / y;
            }

            require(answer <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "overflow in divuu last");
            return uint128(answer);
        }
    }

    function fromX64ToX16(uint128 x) internal pure returns (uint32) {
        uint16 decimals = uint16(uint64(x & 0xFFFFFFFFFFFFFFFF) >> 48);
        uint16 integers = uint16(uint64(x >> 64) >> 48);
        uint32 result = (uint32(integers) << 16) + decimals;
        return result;
    }

    /// @notice helper to calculate binary exponent of 64.64 unsigned fixed point number
    /// @param x unsigned 64.64 fixed point number
    /// @return unsigend 64.64 fixed point number
    function exp_2(uint128 x) private pure returns (uint128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            uint256 answer = 0x80000000000000000000000000000000;

            if (x & 0x8000000000000000 > 0) {
                answer = (answer * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
            }
            if (x & 0x4000000000000000 > 0) {
                answer = (answer * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
            }
            if (x & 0x2000000000000000 > 0) {
                answer = (answer * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
            }
            if (x & 0x1000000000000000 > 0) {
                answer = (answer * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
            }
            if (x & 0x800000000000000 > 0) {
                answer = (answer * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
            }
            if (x & 0x400000000000000 > 0) {
                answer = (answer * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
            }
            if (x & 0x200000000000000 > 0) {
                answer = (answer * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
            }
            if (x & 0x100000000000000 > 0) {
                answer = (answer * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
            }
            if (x & 0x80000000000000 > 0) {
                answer = (answer * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
            }
            if (x & 0x40000000000000 > 0) {
                answer = (answer * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
            }
            if (x & 0x20000000000000 > 0) {
                answer = (answer * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
            }
            if (x & 0x10000000000000 > 0) {
                answer = (answer * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
            }
            if (x & 0x8000000000000 > 0) {
                answer = (answer * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
            }
            if (x & 0x4000000000000 > 0) {
                answer = (answer * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
            }
            if (x & 0x2000000000000 > 0) {
                answer = (answer * 0x1000162E525EE054754457D5995292026) >> 128;
            }
            if (x & 0x1000000000000 > 0) {
                answer = (answer * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
            }
            if (x & 0x800000000000 > 0) {
                answer = (answer * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
            }
            if (x & 0x400000000000 > 0) {
                answer = (answer * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
            }
            if (x & 0x200000000000 > 0) {
                answer = (answer * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
            }
            if (x & 0x100000000000 > 0) {
                answer = (answer * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
            }
            if (x & 0x80000000000 > 0) {
                answer = (answer * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
            }
            if (x & 0x40000000000 > 0) {
                answer = (answer * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
            }
            if (x & 0x20000000000 > 0) {
                answer = (answer * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
            }
            if (x & 0x10000000000 > 0) {
                answer = (answer * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
            }
            if (x & 0x8000000000 > 0) {
                answer = (answer * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
            }
            if (x & 0x4000000000 > 0) {
                answer = (answer * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
            }
            if (x & 0x2000000000 > 0) {
                answer = (answer * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
            }
            if (x & 0x1000000000 > 0) {
                answer = (answer * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
            }
            if (x & 0x800000000 > 0) {
                answer = (answer * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
            }
            if (x & 0x400000000 > 0) {
                answer = (answer * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
            }
            if (x & 0x200000000 > 0) {
                answer = (answer * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
            }
            if (x & 0x100000000 > 0) {
                answer = (answer * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
            }
            if (x & 0x80000000 > 0) {
                answer = (answer * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
            }
            if (x & 0x40000000 > 0) {
                answer = (answer * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
            }
            if (x & 0x20000000 > 0) {
                answer = (answer * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
            }
            if (x & 0x10000000 > 0) {
                answer = (answer * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
            }
            if (x & 0x8000000 > 0) {
                answer = (answer * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
            }
            if (x & 0x4000000 > 0) {
                answer = (answer * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
            }
            if (x & 0x2000000 > 0) {
                answer = (answer * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
            }
            if (x & 0x1000000 > 0) {
                answer = (answer * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
            }
            if (x & 0x800000 > 0) {
                answer = (answer * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
            }
            if (x & 0x400000 > 0) {
                answer = (answer * 0x100000000002C5C85FDF477B662B26945) >> 128;
            }
            if (x & 0x200000 > 0) {
                answer = (answer * 0x10000000000162E42FEFA3AE53369388C) >> 128;
            }
            if (x & 0x100000 > 0) {
                answer = (answer * 0x100000000000B17217F7D1D351A389D40) >> 128;
            }
            if (x & 0x80000 > 0) {
                answer = (answer * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
            }
            if (x & 0x40000 > 0) {
                answer = (answer * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
            }
            if (x & 0x20000 > 0) {
                answer = (answer * 0x100000000000162E42FEFA39FE95583C2) >> 128;
            }
            if (x & 0x10000 > 0) {
                answer = (answer * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
            }
            if (x & 0x8000 > 0) {
                answer = (answer * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
            }
            if (x & 0x4000 > 0) {
                answer = (answer * 0x10000000000002C5C85FDF473E242EA38) >> 128;
            }
            if (x & 0x2000 > 0) {
                answer = (answer * 0x1000000000000162E42FEFA39F02B772C) >> 128;
            }
            if (x & 0x1000 > 0) {
                answer = (answer * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
            }
            if (x & 0x800 > 0) {
                answer = (answer * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
            }
            if (x & 0x400 > 0) {
                answer = (answer * 0x100000000000002C5C85FDF473DEA871F) >> 128;
            }
            if (x & 0x200 > 0) {
                answer = (answer * 0x10000000000000162E42FEFA39EF44D91) >> 128;
            }
            if (x & 0x100 > 0) {
                answer = (answer * 0x100000000000000B17217F7D1CF79E949) >> 128;
            }
            if (x & 0x80 > 0) {
                answer = (answer * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
            }
            if (x & 0x40 > 0) {
                answer = (answer * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
            }
            if (x & 0x20 > 0) {
                answer = (answer * 0x100000000000000162E42FEFA39EF366F) >> 128;
            }
            if (x & 0x10 > 0) {
                answer = (answer * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
            }
            if (x & 0x8 > 0) {
                answer = (answer * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
            }
            if (x & 0x4 > 0) {
                answer = (answer * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
            }
            if (x & 0x2 > 0) {
                answer = (answer * 0x1000000000000000162E42FEFA39EF358) >> 128;
            }
            if (x & 0x1 > 0) {
                answer = (answer * 0x10000000000000000B17217F7D1CF79AB) >> 128;
            }

            answer >>= uint256(63 - (x >> 64));
            require(answer <= uint256(MAX_64x64));

            return uint128(uint256(answer));
        }
    }

    /// @notice helper to compute the natural exponent of a 64.64 fixed point number
    /// @param x 64.64 fixed point number
    /// @return unsigned 64.64 fixed point number
    function exp(uint128 x) internal pure returns (uint128) {
        unchecked {
            require(x < 0x400000000000000000, "Exponential overflow"); // Overflow

            return exp_2(uint128((uint256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128));
        }
    }

    /// @notice helper to compute the square root of an unsigned uint256 integer
    /// @param x unsigned uint256 integer
    /// @return unsigned 64.64 unsigned fixed point number
    function sqrtu(uint256 x) internal pure returns (uint128) {
        unchecked {
            if (x == 0) {
                return 0;
            } else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) {
                    xx >>= 128;
                    r <<= 64;
                }
                if (xx >= 0x10000000000000000) {
                    xx >>= 64;
                    r <<= 32;
                }
                if (xx >= 0x100000000) {
                    xx >>= 32;
                    r <<= 16;
                }
                if (xx >= 0x10000) {
                    xx >>= 16;
                    r <<= 8;
                }
                if (xx >= 0x100) {
                    xx >>= 8;
                    r <<= 4;
                }
                if (xx >= 0x10) {
                    xx >>= 4;
                    r <<= 2;
                }
                if (xx >= 0x8) {
                    r <<= 1;
                }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return uint128(r < r1 ? r : r1);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {UniswapV3Callback} from "./UniswapV3Callback.sol";
import {AlgebraCallback} from "./AlgebraCallback.sol";
import {UniswapV2Callback} from "./UniswapV2Callback.sol";
import {TraderJoeCallback} from "./TraderJoeCallback.sol";
import {ZyberSwapElasticCallback} from "./ZyberSwapElasticCallback.sol";
import {ZyberSwapCallback} from "./ZyberSwapCallback.sol";
import {ArbDexCallback} from "./ArbDexCallback.sol";
import {ArbSwapCallback} from "./ArbSwapCallback.sol";

contract ConveyorSwapCallbacks is
    UniswapV3Callback,
    AlgebraCallback,
    TraderJoeCallback,
    UniswapV2Callback,
    ZyberSwapElasticCallback,
    ZyberSwapCallback,
    ArbDexCallback,
    ArbSwapCallback
{}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../ConveyorRouterV1.sol";

interface IConveyorRouterV1 {
    function swapExactTokenForToken(
        ConveyorRouterV1.TokenToTokenSwapData calldata swapData,
        ConveyorRouterV1.SwapAggregatorMulticall calldata genericMulticall
    ) external payable;

    function swapExactEthForToken(
        ConveyorRouterV1.EthToTokenSwapData calldata swapData,
        ConveyorRouterV1.SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable;

    function swapExactTokenForEth(
        ConveyorRouterV1.TokenToEthSwapData calldata swapData,
        ConveyorRouterV1.SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable;

    function initializeAffiliate(address affiliateAddress) external;
    function initializeReferrer() external payable;

    function upgradeMulticall(bytes memory bytecode, bytes32 salt) external payable returns (address);

    function quoteSwapExactTokenForToken(
        ConveyorRouterV1.TokenToTokenSwapData calldata swapData,
        ConveyorRouterV1.SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable returns (uint256 gasConsumed);

    function quoteSwapExactTokenForEth(
        ConveyorRouterV1.TokenToEthSwapData calldata swapData,
        ConveyorRouterV1.SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable returns (uint256 gasConsumed);

    function quoteSwapExactEthForToken(
        ConveyorRouterV1.EthToTokenSwapData calldata swapData,
        ConveyorRouterV1.SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable returns (uint256 gasConsumed);

    function withdraw() external;

    function CONVEYOR_MULTICALL() external view returns (address);
    function affiliates(uint16) external view returns (address);
    function referrers(uint16) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "../../lib/interfaces/token/IERC20.sol";

contract UniswapV3Callback {
    ///@notice Uniswap V3 callback function called during a swap on a v3 liqudity pool.
    ///@param amount0Delta - The change in token0 reserves from the swap.
    ///@param amount1Delta - The change in token1 reserves from the swap.
    ///@param data - The data packed into the swap.
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        ///@notice Decode all of the swap data.
        (bool _zeroForOne, address _tokenIn, address _sender) = abi.decode(data, (bool, address, address));

        ///@notice Set amountIn to the amountInDelta depending on boolean zeroForOne.
        uint256 amountIn = _zeroForOne ? uint256(amount0Delta) : uint256(amount1Delta);

        if (!(_sender == address(this))) {
            ///@notice Transfer the amountIn of tokenIn to the liquidity pool from the sender.
            IERC20(_tokenIn).transferFrom(_sender, msg.sender, amountIn);
        } else {
            IERC20(_tokenIn).transfer(msg.sender, amountIn);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "../../lib/interfaces/token/IERC20.sol";

contract AlgebraCallback {
    ///@notice Algebra callback function called during a swap on a algebra liqudity pool.
    ///@param amount0 - The change in token0 reserves from the swap.
    ///@param amount1 - The change in token1 reserves from the swap.
    ///@param data - The data packed into the swap.
    function algebraSwapCallback(int256 amount0, int256 amount1, bytes calldata data) external {
        ///@notice Decode all of the swap data.
        (bool _zeroForOne, address _tokenIn, address _sender) = abi.decode(data, (bool, address, address));

        ///@notice Set amountIn to the amountInDelta depending on boolean zeroForOne.
        uint256 amountIn = _zeroForOne ? uint256(amount0) : uint256(amount1);

        if (!(_sender == address(this))) {
            ///@notice Transfer the amountIn of tokenIn to the liquidity pool from the sender.
            IERC20(_tokenIn).transferFrom(_sender, msg.sender, amountIn);
        } else {
            IERC20(_tokenIn).transfer(msg.sender, amountIn);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "../../lib/interfaces/token/IERC20.sol";
import "../../lib/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import "../lib/OracleLibraryV2.sol";

contract UniswapV2Callback {
    /// @notice Uniswap v2 swap callback
    /// @param amount0 - The change in token0 reserves from the swap.
    /// @param amount1 - The change in token1 reserves from the swap.
    /// @param data - The data packed into the swap.
    function uniswapV2Call(address, uint256 amount0, uint256 amount1, bytes calldata data) external {
        ///@notice Decode all of the swap data.
        (bool _zeroForOne, address _tokenIn, uint24 _swapFee) = abi.decode(data, (bool, address, uint24));

        uint256 amountOut = _zeroForOne ? amount1 : amount0;
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(msg.sender).getReserves();

        uint256 amountIn = OracleLibraryV2.getAmountIn(
            amountOut, _zeroForOne ? reserve0 : reserve1, _zeroForOne ? reserve1 : reserve0, _swapFee
        );
        IERC20(_tokenIn).transfer(msg.sender, amountIn);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "../../lib/interfaces/token/IERC20.sol";
import "../../lib/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import "../lib/OracleLibraryV2.sol";

contract TraderJoeCallback {
    /// @notice TraderJoe swap callback
    /// @param amount0 - The change in token0 reserves from the swap.
    /// @param amount1 - The change in token1 reserves from the swap.
    /// @param data - The data packed into the swap.
    function joeCall(address, uint256 amount0, uint256 amount1, bytes calldata data) external {
        ///@notice Decode all of the swap data.
        (bool _zeroForOne, address _tokenIn, uint24 _swapFee) = abi.decode(data, (bool, address, uint24));

        uint256 amountOut = _zeroForOne ? amount1 : amount0;
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(msg.sender).getReserves();

        uint256 amountIn = OracleLibraryV2.getAmountIn(
            amountOut, _zeroForOne ? reserve0 : reserve1, _zeroForOne ? reserve1 : reserve0, _swapFee
        );
        IERC20(_tokenIn).transfer(msg.sender, amountIn);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "../../lib/interfaces/token/IERC20.sol";

contract ZyberSwapElasticCallback {
    ///@notice ZyberSwap Elastic callback function called during a swap on a v3 liqudity pool.
    ///@param deltaQty0 - The change in token0 reserves from the swap.
    ///@param deltaQty1 - The change in token1 reserves from the swap.
    ///@param data - The data packed into the swap.
    function swapCallback(int256 deltaQty0, int256 deltaQty1, bytes calldata data) external {
        ///@notice Decode all of the swap data.
        (bool _zeroForOne, address _tokenIn, address _sender) = abi.decode(data, (bool, address, address));

        ///@notice Set amountIn to the amountInDelta depending on boolean zeroForOne.
        uint256 amountIn = _zeroForOne ? uint256(deltaQty0) : uint256(deltaQty1);

        if (!(_sender == address(this))) {
            ///@notice Transfer the amountIn of tokenIn to the liquidity pool from the sender.
            IERC20(_tokenIn).transferFrom(_sender, msg.sender, amountIn);
        } else {
            IERC20(_tokenIn).transfer(msg.sender, amountIn);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "../../lib/interfaces/token/IERC20.sol";
import "../../lib/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import "../lib/OracleLibraryV2.sol";

contract ZyberSwapCallback {
    /// @notice Zyber swap callback
    /// @param amount0 - The change in token0 reserves from the swap.
    /// @param amount1 - The change in token1 reserves from the swap.
    /// @param data - The data packed into the swap.
    function ZyberCall(address, uint256 amount0, uint256 amount1, bytes calldata data) external {
        ///@notice Decode all of the swap data.
        (bool _zeroForOne, address _tokenIn, uint24 _swapFee) = abi.decode(data, (bool, address, uint24));

        uint256 amountOut = _zeroForOne ? amount1 : amount0;
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(msg.sender).getReserves();

        uint256 amountIn = OracleLibraryV2.getAmountIn(
            amountOut, _zeroForOne ? reserve0 : reserve1, _zeroForOne ? reserve1 : reserve0, _swapFee
        );
        IERC20(_tokenIn).transfer(msg.sender, amountIn);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "../../lib/interfaces/token/IERC20.sol";
import "../../lib/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import "../lib/OracleLibraryV2.sol";

contract ArbDexCallback {
    /// @notice ArbDex swap callback
    /// @param amount0 - The change in token0 reserves from the swap.
    /// @param amount1 - The change in token1 reserves from the swap.
    /// @param data - The data packed into the swap.
    function arbdexCall(address, uint256 amount0, uint256 amount1, bytes calldata data) external {
        ///@notice Decode all of the swap data.
        (bool _zeroForOne, address _tokenIn, uint24 _swapFee) = abi.decode(data, (bool, address, uint24));

        uint256 amountOut = _zeroForOne ? amount1 : amount0;
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(msg.sender).getReserves();

        uint256 amountIn = OracleLibraryV2.getAmountIn(
            amountOut, _zeroForOne ? reserve0 : reserve1, _zeroForOne ? reserve1 : reserve0, _swapFee
        );
        IERC20(_tokenIn).transfer(msg.sender, amountIn);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "../../lib/interfaces/token/IERC20.sol";
import "../../lib/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import "../lib/OracleLibraryV2.sol";

contract ArbSwapCallback {
    /// @notice Arb swap callback
    /// @param amount0 - The change in token0 reserves from the swap.
    /// @param amount1 - The change in token1 reserves from the swap.
    /// @param data - The data packed into the swap.
    function swapCall(address, uint256 amount0, uint256 amount1, bytes calldata data) external {
        ///@notice Decode all of the swap data.
        (bool _zeroForOne, address _tokenIn, uint24 _swapFee) = abi.decode(data, (bool, address, uint24));

        uint256 amountOut = _zeroForOne ? amount1 : amount0;
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(msg.sender).getReserves();

        uint256 amountIn = OracleLibraryV2.getAmountIn(
            amountOut, _zeroForOne ? reserve0 : reserve1, _zeroForOne ? reserve1 : reserve0, _swapFee
        );
        IERC20(_tokenIn).transfer(msg.sender, amountIn);
    }
}

// SPDX-License-Identifier: PLACEHOLDER
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

library OracleLibraryV2 {
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut, uint24 swapFee)
        internal
        pure
        returns (uint256 amountIn)
    {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 100000;
        uint256 denominator = (reserveOut - amountOut) * (100000 - swapFee);
        amountIn = (numerator / denominator) + 1;
    }
}