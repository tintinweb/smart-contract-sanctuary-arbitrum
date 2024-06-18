// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IPaydefi {
    enum SwapType {
        SEll,
        BUY
    }

    struct PaymentArgs {
        string orderId;
        address payInToken;
        address payOutToken;
        uint256 payInAmount;
        uint256 payOutAmount;
        address merchant;
        SwapType swapType;
    }

    struct SwapArgs {
        uint256 value;
        address provider;
        address approveProxy;
        bool shouldApprove;
        bytes callData;
    }

    function completePayment(
        string calldata orderId,
        address payToken,
        uint256 payInAmount,
        uint256 payOutAmount,
        address merchant
    ) external payable;

    function completePaymentWithSwap(
        PaymentArgs calldata paymentArgs,
        SwapArgs calldata swapArgs
    ) external payable;

    function claimProtocolFee(address token, address receiver) external;

    function addWhitelistedSwapProvider(address swapProvider) external;

    function removeWhitelistedSwapProvider(address swapProvider) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ERC20Utils
/// @notice Optimized functions for ERC20 tokens
library ERC20Utils {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error IncorrectEthAmount();
    error PermitFailed();
    error TransferFromFailed();
    error TransferFailed();
    error ApprovalFailed();

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    IERC20 internal constant ETH = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /*//////////////////////////////////////////////////////////////
                                APPROVE
    //////////////////////////////////////////////////////////////*/

    /// @dev Vendored from Solady by @vectorized - SafeTransferLib.approveWithRetry
    /// https://github.com/Vectorized/solady/src/utils/SafeTransferLib.sol#L325
    /// Instead of approving a specific amount, this function approves for uint256(-1) (type(uint256).max).
    function approve(IERC20 token, address to) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) // Store the `amount`
        // argument (type(uint256).max).
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
        // Perform the approval, retrying upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x34, 0) // Store 0 for the `amount`.
                mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
                pop(call(gas(), token, 0, 0x10, 0x44, codesize(), 0x00)) // Reset the approval.
                mstore(0x34, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) // Store
            // type(uint256).max for the `amount`.
            // Retry the approval, reverting upon failure.
                if iszero(
                    and(
                        or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                        call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                    )
                ) {
                    mstore(0, 0x8164f84200000000000000000000000000000000000000000000000000000000)
                // store the selector (error ApprovalFailed())
                    revert(0, 4) // revert with error selector
                }
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /*//////////////////////////////////////////////////////////////
                                PERMIT
    //////////////////////////////////////////////////////////////*/

    /// @dev Executes an ERC20 permit and reverts if invalid length is provided
    function permit(IERC20 token, bytes calldata data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
        // check the permit length
            switch data.length
            // 32 * 7 = 224 EIP2612 Permit
            case 224 {
                let x := mload(64) // get the free memory pointer
                mstore(x, 0xd505accf00000000000000000000000000000000000000000000000000000000) // store the selector
            // function permit(address owner, address spender, uint256
            // amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
                calldatacopy(add(x, 4), data.offset, 224) // store the args
                pop(call(gas(), token, 0, x, 228, 0, 32)) // call ERC20 permit, skip checking return data
            }
            // 32 * 8 = 256 DAI-Style Permit
            case 256 {
                let x := mload(64) // get the free memory pointer
                mstore(x, 0x8fcbaf0c00000000000000000000000000000000000000000000000000000000) // store the selector
            // function permit(address holder, address spender, uint256
            // nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s)
                calldatacopy(add(x, 4), data.offset, 256) // store the args
                pop(call(gas(), token, 0, x, 260, 0, 32)) // call ERC20 permit, skip checking return data
            }
            default {
                mstore(0, 0xb78cb0dd00000000000000000000000000000000000000000000000000000000) // store the selector
            // (error PermitFailed())
                revert(0, 4)
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 ETH
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns 1 if the token is ETH, 0 if not ETH
    function isETH(IERC20 token, uint256 amount) internal view returns (uint256 fromETH) {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
        // If token is ETH
            if eq(token, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            // if msg.value is not equal to fromAmount, then revert
                if xor(amount, callvalue()) {
                    mstore(0, 0x8b6ebb4d00000000000000000000000000000000000000000000000000000000) // store the selector
                // (error IncorrectEthAmount())
                    revert(0, 4) // revert with error selector
                }
            // return 1 if ETH
                fromETH := 1
            }
        // If token is not ETH
            if xor(token, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            // if msg.value is not equal to 0, then revert
                if gt(callvalue(), 0) {
                    mstore(0, 0x8b6ebb4d00000000000000000000000000000000000000000000000000000000) // store the selector
                // (error IncorrectEthAmount())
                    revert(0, 4) // revert with error selector
                }
            }
        }
        // return 0 if not ETH
    }

    /*//////////////////////////////////////////////////////////////
                                TRANSFER
    //////////////////////////////////////////////////////////////*/

    /// @dev Executes transfer and reverts if it fails, works for both ETH and ERC20 transfers
    function safeTransfer(IERC20 token, address recipient, uint256 amount) internal returns (bool success) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            switch eq(token, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            // ETH
            case 1 {
            // transfer ETH
            // Cap gas at 10000 to avoid reentrancy
                success := call(10000, recipient, amount, 0, 0, 0, 0)
            }
            // ERC20
            default {
                let x := mload(64) // get the free memory pointer
                mstore(x, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // store the selector
            // (function transfer(address recipient, uint256 amount))
                mstore(add(x, 4), recipient) // store the recipient
                mstore(add(x, 36), amount) // store the amount
                success := call(gas(), token, 0, x, 68, 0, 32) // call transfer
                if success {
                    switch returndatasize()
                    // check the return data size
                    case 0 { success := gt(extcodesize(token), 0) }
                    default { success := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
                }
            }
            if iszero(success) {
                mstore(0, 0x90b8ec1800000000000000000000000000000000000000000000000000000000) // store the selector
            // (error TransferFailed())
                revert(0, 4) // revert with error selector
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                             TRANSFER FROM
    //////////////////////////////////////////////////////////////*/

    /// @dev Executes transferFrom and reverts if it fails
    function safeTransferFrom(
        IERC20 srcToken,
        address sender,
        address recipient,
        uint256 amount
    )
    internal
    returns (bool success)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let x := mload(64) // get the free memory pointer
            mstore(x, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // store the selector
        // (function transferFrom(address sender, address recipient,
        // uint256 amount))
            mstore(add(x, 4), sender) // store the sender
            mstore(add(x, 36), recipient) // store the recipient
            mstore(add(x, 68), amount) // store the amount
            success := call(gas(), srcToken, 0, x, 100, 0, 32) // call transferFrom
            if success {
                switch returndatasize()
                // check the return data size
                case 0 { success := gt(extcodesize(srcToken), 0) }
                default { success := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
            }
            if iszero(success) {
                mstore(x, 0x7939f42400000000000000000000000000000000000000000000000000000000) // store the selector
            // (error TransferFromFailed())
                revert(x, 4) // revert with error selector
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                                BALANCE
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the balance of an account, works for both ETH and ERC20 tokens
    function getBalance(IERC20 token, address account) internal view returns (uint256 balanceOf) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            switch eq(token, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            // ETH
            case 1 { balanceOf := balance(account) }
            // ERC20
            default {
                let x := mload(64) // get the free memory pointer
                mstore(x, 0x70a0823100000000000000000000000000000000000000000000000000000000) // store the selector
            // (function balanceOf(address account))
                mstore(add(x, 4), account) // store the account
                let success := staticcall(gas(), token, x, 36, x, 32) // call balanceOf
                if success { balanceOf := mload(x) } // load the balance
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library PaymentErrors {
    error IncorrectNativeTokenAmount();
    error SwapProviderNotWhitelisted();
    error FeeRateOutOfRange();
    error ZeroClaimAddress();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IPaydefi.sol";
import "./libraries/PaymentErrors.sol";
import "./libraries/ERC20Utils.sol";

contract Paydefi is IPaydefi, Ownable {
    using ERC20Utils for IERC20;

    mapping(address => bool) public whitelistedSwapProviders;

    event Payment(
        string orderId,
        address payInToken,
        address payOutToken,
        uint256 payInAmount,
        uint256 payOutAmount,
        uint256 protocolFeeAmount,
        address merchant
    );

    constructor(address _initialOwner, address[] memory swapProviders) Ownable(_initialOwner) {
        for (uint256 i = 0; i < swapProviders.length; i++) {
            whitelistedSwapProviders[swapProviders[i]] = true;
        }
    }

    /**
     * @param payToken token address which user sends
     * @param payInAmount amount of payToken for user to pay
     * @param payOutAmount amount of payToken for merchant to receive
     * @param merchant address of merchant
     */
    function completePayment(
        string calldata orderId,
        address payToken,
        uint256 payInAmount,
        uint256 payOutAmount,
        address merchant
    ) external payable {
        if (IERC20(payToken).isETH(payInAmount) == 0) {
            IERC20(payToken).safeTransferFrom(msg.sender, address(this), payInAmount);
        }

        uint256 feeCollected = payInAmount - payOutAmount;

        IERC20(payToken).safeTransfer(merchant, payOutAmount);

        emit Payment(orderId, payToken, payToken, payInAmount, payOutAmount, feeCollected, merchant);
    }

    /**
     * @param paymentArgs payment arguments
     * @param swapArgs swap arguments
     */
    function completePaymentWithSwap(PaymentArgs calldata paymentArgs, SwapArgs calldata swapArgs) external payable {
        if (!whitelistedSwapProviders[swapArgs.provider]) {
            revert PaymentErrors.SwapProviderNotWhitelisted();
        }

        (uint256 actualPayInAmount, uint256 receivedPayOutAmount) = executeSwap(paymentArgs, swapArgs);

        uint256 feeCollected = receivedPayOutAmount - paymentArgs.payOutAmount;

        // transfer payOutToken to merchant
        IERC20(paymentArgs.payOutToken).safeTransfer(paymentArgs.merchant, paymentArgs.payOutAmount);

        // if swap is a BUY, return unused payInAmount to user
        if (paymentArgs.swapType == SwapType.BUY) {
            uint256 unusedPayInAmount = paymentArgs.payInAmount - actualPayInAmount;

            if (unusedPayInAmount > 0) {
                IERC20(paymentArgs.payInToken).safeTransfer(msg.sender, unusedPayInAmount);
            }
        }

        emit Payment(
            paymentArgs.orderId,
            paymentArgs.payInToken,
            paymentArgs.payOutToken,
            actualPayInAmount,
            paymentArgs.payOutAmount,
            feeCollected,
            paymentArgs.merchant
        );
    }

    /**
     * @notice add address of the swap provider
     * @param swapProvider swap provider address
     */
    function addWhitelistedSwapProvider(address swapProvider) external onlyOwner {
        whitelistedSwapProviders[swapProvider] = true;
    }

    /**
     * @notice Remove address of the swap provider
     * @param swapProvider swap provider address
     */
    function removeWhitelistedSwapProvider(address swapProvider) external onlyOwner {
        whitelistedSwapProviders[swapProvider] = false;
    }

    /**
     * @notice Returns amount of protocol fees collected for the token
     */
    function protocolFee(address token) public view returns (uint256) {
        return IERC20(token).getBalance(address(this));
    }

    /**
     * @notice claim protocol fee
     */
    function claimProtocolFee(address token, address receiver) external onlyOwner {
        if (receiver == address(0)) {
            revert PaymentErrors.ZeroClaimAddress();
        }

        uint256 protocolFeeAmount = protocolFee(token);
        IERC20(token).safeTransfer(receiver, protocolFeeAmount);
    }

    function executeSwap(
        PaymentArgs calldata paymentArgs,
        SwapArgs calldata swapArgs
    ) internal returns (uint256 spent, uint256 received) {
        if (IERC20(paymentArgs.payInToken).isETH(paymentArgs.payInAmount) == 0) {
            IERC20(paymentArgs.payInToken).safeTransferFrom(msg.sender, address(this), paymentArgs.payInAmount);
            if (swapArgs.shouldApprove) {
                IERC20(paymentArgs.payInToken).approve(swapArgs.approveProxy);
            }
        }

        uint256 payInBeforeSwap = IERC20(paymentArgs.payInToken).getBalance(address(this));
        uint256 payOutBeforeSwap = IERC20(paymentArgs.payOutToken).getBalance(address(this));

        (bool success, ) = swapArgs.provider.call{ value: swapArgs.value }(swapArgs.callData);

        /** @dev assembly allows to get tx failure reason here*/
        if (success == false) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }

        uint256 payInAfterSwap = IERC20(paymentArgs.payInToken).getBalance(address(this));
        uint256 payOutAfterSwap = IERC20(paymentArgs.payOutToken).getBalance(address(this));

        spent = payInBeforeSwap - payInAfterSwap;
        received = payOutAfterSwap - payOutBeforeSwap;
    }
}