//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./interfaces/IProtocol.sol";
import "./interfaces/ISwap.sol";
import "./interfaces/IBridge.sol";
import "./libraries/Adminable.sol";
import "./libraries/CommonBase.sol";
import "./libraries/SafeNativeAsset.sol";
import "./libraries/SafeERC20.sol";

contract UxuyProtocol is IProtocol, Adminable, CommonBase {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;

    struct TradeState {
        address tokenIn;
        address tokenOut;
        int feeTokenIndex;
        address feeToken;
        uint256 feeAmount;
        uint256 feeShareAmount;
        uint256 extraFeeAmount;
        address nextRecipient;
    }

    // zero address
    address internal constant NULL_ADDRESS = address(0);

    // fee rate denominator
    uint256 private constant FEE_DENOMINATOR = 1e6;

    // maximum allowed fee rate
    uint256 private constant MAX_FEE_RATE = 1e5;

    // maximum allowed extra fee ratio
    uint256 private constant MAX_EXTRA_FEE_RATIO = 2;

    // swap contract
    ISwap private _swapContract;

    // bridge contract
    IBridge private _bridgeContract;

    // total fee rate in 1/FEE_DENOMINATOR
    uint256 private _feeRate;

    // fee share rate in 1/FEE_DENOMINATOR
    uint256 private _feeShareRate;

    // recipient address to receive fee in main tokens
    address private _mainFeeRecipient;

    // recipient address to receive fee in other tokens
    address private _altFeeRecipient;

    // free of charge accounts
    mapping(address => bool) private _focAccounts;

    // main tokens for fee charging
    mapping(address => bool) private _mainFeeTokens;

    // @dev Emitted when relying contract is updated
    event ContractChanged(address swap, address bridge);

    // @dev Emitted when fee recipient is updated
    event FeeRecipientChanged(address main, address alt);

    // @dev Emitted when FOC account is updated
    event FOCAccountChanged(address account, bool foc);

    // @dev Emitted when fee token is updated
    event FeeTokenChanged(address token, bool main);

    // @param swapContract_ the Swap contract address
    // @param bridgeContract_ the Bridge contract address
    // @param feeRate_ the total fee rate
    // @param feeShareRate_ the fee share rate
    // @param mainFeeRecipient_ the account to receive fee in main tokens
    // @param altFeeRecipient_ the account to receive fee in other tokens
    constructor(
        address swapContract_,
        address bridgeContract_,
        uint256 feeRate_,
        uint256 feeShareRate_,
        address mainFeeRecipient_,
        address altFeeRecipient_
    ) {
        _setContract(swapContract_, bridgeContract_);
        _setFeeRate(feeRate_, feeShareRate_);
        _setFeeRecipient(mainFeeRecipient_, altFeeRecipient_);
    }

    function swapContract() external view override returns (address) {
        return address(_swapContract);
    }

    function bridgeContract() external view override returns (address) {
        return address(_bridgeContract);
    }

    function feeDenominator() external pure returns (uint256) {
        return FEE_DENOMINATOR;
    }

    function feeRate() external view returns (uint256) {
        return _feeRate;
    }

    function feeShareRate() external view returns (uint256) {
        return _feeShareRate;
    }

    // @dev check if the account is free of charge
    function isFOCAccount(address account) external view returns (bool) {
        return _focAccounts[account];
    }

    // @dev changes the swap and bridge contract addresses
    function setContract(address swapContract_, address bridgeContract_) external onlyAdmin {
        _setContract(swapContract_, bridgeContract_);
    }

    // @dev changes the fee rate
    function setFeeRate(uint256 feeRate_, uint256 feeShareRate_) external onlyAdmin {
        _setFeeRate(feeRate_, feeShareRate_);
    }

    // @dev changes the fee recipients
    function setFeeRecipient(address main, address alt) external onlyAdmin {
        _setFeeRecipient(main, alt);
    }

    // @dev updates free of charge accounts
    function updateFOCAccounts(address[] calldata accounts, bool foc) external onlyAdmin {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (foc) {
                _focAccounts[accounts[i]] = true;
            } else {
                delete _focAccounts[accounts[i]];
            }
            emit FOCAccountChanged(accounts[i], foc);
        }
    }

    // @dev changes the token accept status
    function updateFeeTokens(address[] calldata tokens, bool main) external onlyAdmin {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (main) {
                _mainFeeTokens[tokens[i]] = true;
            } else {
                delete _mainFeeTokens[tokens[i]];
            }
            emit FeeTokenChanged(tokens[i], main);
        }
    }

    function trade(
        TradeParams calldata params
    )
        external
        payable
        whenNotPaused
        noDelegateCall
        nonReentrant
        checkDeadline(params.deadline)
        returns (uint256 amountOut, uint256 bridgeTxnID)
    {
        TradeState memory state;
        if (params.swaps.length > 0) {
            for (uint256 i = 0; i < params.swaps.length; i++) {
                require(
                    _swapContract.getProvider(params.swaps[i].providerID) != NULL_ADDRESS,
                    "UP: invalid swap provider"
                );
            }
            state.tokenIn = params.swaps[0].path[0];
            state.nextRecipient = _swapContract.getProvider(params.swaps[0].providerID);
            if (params.bridge.providerID != 0) {
                require(
                    _tokenOut(params.swaps[params.swaps.length - 1].path) == params.bridge.tokenIn,
                    "UP: swap and bridge token mismatch"
                );
            }
        } else {
            state.tokenIn = params.bridge.tokenIn;
            state.nextRecipient = _bridgeContract.getProvider(params.bridge.providerID);
        }
        if (params.bridge.providerID == 0) {
            state.tokenOut = _tokenOut(params.swaps[params.swaps.length - 1].path);
        } else {
            require(
                _bridgeContract.getProvider(params.bridge.providerID) != NULL_ADDRESS,
                "UP: invalid bridge provider"
            );
            state.tokenOut = params.bridge.tokenOut;
        }
        if (state.tokenIn.isNativeAsset()) {
            require(msg.value >= params.amountIn, "UP: not enough ETH in transaction");
            amountOut = msg.value;
        } else {
            require(
                IERC20(state.tokenIn).balanceOf(_msgSender()) >= params.amountIn,
                "UP: sender token balance is not enough"
            );
            require(
                IERC20(state.tokenIn).allowance(_msgSender(), address(this)) >= params.amountIn,
                "UP: token allowance is not enough"
            );
            amountOut = params.amountIn;
        }
        if (params.extraFeeAmountIn > 0) {
            require(amountOut >= params.extraFeeAmountIn * MAX_EXTRA_FEE_RATIO, "UP: extra fee exceeds limit");
            state.extraFeeAmount = _payExtraFee(state.tokenIn, params.extraFeeAmountIn, params.extraFeeSwaps);
            amountOut -= params.extraFeeAmountIn;
        }
        state.feeTokenIndex = _findFeeToken(params.swaps);
        state.feeToken = NULL_ADDRESS;
        state.feeAmount = 0;
        state.feeShareAmount = 0;
        if (state.feeTokenIndex == 0) {
            state.feeToken = state.tokenIn;
            (amountOut, state.feeAmount, state.feeShareAmount) = _payFee(
                state.tokenIn.isNativeAsset() ? address(this) : _msgSender(),
                state.feeToken,
                amountOut,
                params.feeShareRecipient
            );
        }
        if (state.tokenIn.isNativeAsset()) {
            state.nextRecipient.safeTransfer(amountOut);
        } else {
            uint256 balanceBefore = IERC20(state.tokenIn).balanceOf(state.nextRecipient);
            IERC20(state.tokenIn).safeTransferFrom(_msgSender(), state.nextRecipient, amountOut);
            amountOut = IERC20(state.tokenIn).balanceOf(state.nextRecipient) - balanceBefore;
        }
        for (uint256 i = 0; i < params.swaps.length; i++) {
            SwapParams calldata swap = params.swaps[i];
            if (i + 1 < params.swaps.length) {
                state.nextRecipient = _swapContract.getProvider(params.swaps[i + 1].providerID);
            } else if (params.bridge.providerID != 0) {
                state.nextRecipient = _bridgeContract.getProvider(params.bridge.providerID);
            } else {
                state.nextRecipient = params.recipient;
            }
            amountOut = _swapContract.swap(
                ISwap.SwapParams({
                    providerID: swap.providerID,
                    path: swap.path,
                    amountIn: amountOut,
                    minAmountOut: swap.minAmountOut,
                    recipient: (state.feeTokenIndex == int(i + 1)) ? address(this) : state.nextRecipient,
                    data: swap.data
                })
            );
            if (state.feeTokenIndex == int(i + 1)) {
                state.feeToken = _tokenOut(swap.path);
                (amountOut, state.feeAmount, state.feeShareAmount) = _payFee(
                    address(this),
                    state.feeToken,
                    amountOut,
                    params.feeShareRecipient
                );
                require(amountOut >= swap.minAmountOut, "UP: amount less than minimum");
                uint256 balanceBefore = 0;
                if (!state.feeToken.isNativeAsset()) {
                    balanceBefore = IERC20(state.feeToken).balanceOf(state.nextRecipient);
                }
                _safeTransfer(address(this), state.feeToken, amountOut, state.nextRecipient);
                if (!state.feeToken.isNativeAsset()) {
                    // handle token with supporting fee on transfer
                    amountOut = IERC20(state.feeToken).balanceOf(state.nextRecipient) - balanceBefore;
                }
            }
        }
        bridgeTxnID = 0;
        if (params.bridge.providerID != 0) {
            BridgeParams calldata bridge = params.bridge;
            (amountOut, bridgeTxnID) = _bridgeContract.bridge(
                IBridge.BridgeParams({
                    providerID: bridge.providerID,
                    tokenIn: bridge.tokenIn,
                    chainIDOut: bridge.chainIDOut,
                    tokenOut: bridge.tokenOut,
                    amountIn: amountOut,
                    minAmountOut: bridge.minAmountOut,
                    recipient: params.recipient,
                    data: bridge.data
                })
            );
        }
        emit Traded(
            _msgSender(),
            params.recipient,
            params.feeShareRecipient,
            state.tokenIn,
            params.amountIn,
            params.bridge.chainIDOut,
            state.tokenOut,
            amountOut,
            bridgeTxnID,
            state.feeToken,
            state.feeAmount,
            state.feeShareAmount,
            state.extraFeeAmount
        );
    }

    function _setContract(address swapContract_, address bridgeContract_) internal {
        require(swapContract_ != NULL_ADDRESS && bridgeContract_ != NULL_ADDRESS, "UP: invalid contract address");
        _swapContract = ISwap(swapContract_);
        _bridgeContract = IBridge(bridgeContract_);
        emit ContractChanged(swapContract_, bridgeContract_);
    }

    function _setFeeRate(uint256 feeRate_, uint256 feeShareRate_) internal {
        require(feeRate_ <= MAX_FEE_RATE, "UP: fee rate exceeds limit");
        require(feeRate_ >= feeShareRate_, "UP: fee share rate is less than total fee rate");
        _feeRate = feeRate_;
        _feeShareRate = feeShareRate_;
        emit FeeRateChanged(_feeRate, _feeShareRate);
    }

    function _setFeeRecipient(address main, address alt) internal {
        require(main != NULL_ADDRESS && alt != NULL_ADDRESS, "UP: fee recipient is null");
        _mainFeeRecipient = main;
        _altFeeRecipient = alt;
        emit FeeRecipientChanged(_mainFeeRecipient, _altFeeRecipient);
    }

    // @dev find token to pay fee.
    // @return feeTokenIndex the index of token to pay fee:
    //         feeTokenIndex < 0: no need to pay fee;
    //         feeTokenIndex == 0: use first input token;
    //         feeTokenIndex > 0: use the output token of the swapList[feeTokenIndex-1].
    function _findFeeToken(SwapParams[] calldata swaps) internal view returns (int) {
        if (!_needPayFee()) {
            return -1;
        }
        if (swaps.length == 0) {
            return 0;
        }
        address tokenIn = swaps[0].path[0];
        if (tokenIn.isNativeAsset() || _mainFeeTokens[tokenIn]) {
            return 0;
        }
        for (uint256 i = 0; i < swaps.length; i++) {
            address tokenOut = swaps[i].path[swaps[i].path.length - 1];
            if (tokenOut.isNativeAsset() || _mainFeeTokens[tokenOut]) {
                return int(i + 1);
            }
        }
        return 0;
    }

    function _payExtraFee(
        address tokenIn,
        uint256 amountIn,
        SwapParams[] calldata swaps
    ) internal returns (uint256 extraFeeAmount) {
        address nextRecipient;
        if (swaps.length == 0) {
            nextRecipient = _msgSender();
        } else {
            nextRecipient = _swapContract.getProvider(swaps[0].providerID);
        }
        if (tokenIn.isNativeAsset()) {
            nextRecipient.safeTransfer(amountIn);
        } else {
            if (nextRecipient != _msgSender()) {
                uint256 balanceBefore = IERC20(tokenIn).balanceOf(nextRecipient);
                IERC20(tokenIn).safeTransferFrom(_msgSender(), nextRecipient, amountIn);
                amountIn = IERC20(tokenIn).balanceOf(nextRecipient) - balanceBefore;
            }
        }
        for (uint256 i = 0; i < swaps.length; i++) {
            SwapParams calldata swap = swaps[i];
            if (i + 1 < swaps.length) {
                nextRecipient = _swapContract.getProvider(swaps[i + 1].providerID);
            } else {
                nextRecipient = _msgSender();
            }
            amountIn = _swapContract.swap(
                ISwap.SwapParams({
                    providerID: swap.providerID,
                    path: swap.path,
                    amountIn: amountIn,
                    minAmountOut: swap.minAmountOut,
                    recipient: nextRecipient,
                    data: swap.data
                })
            );
        }
        return amountIn;
    }

    function _payFee(
        address sender,
        address token,
        uint256 amount,
        address feeShareRecipient
    ) internal returns (uint256 amountLeft, uint256 feeAmount, uint256 feeShareAmount) {
        if (!_needPayFee()) {
            return (amount, 0, 0);
        }
        feeAmount = (amount * _feeRate) / FEE_DENOMINATOR;
        require(feeAmount > 0, "UP: fee amount is 0");
        feeShareAmount = 0;
        uint256 feeLeftAmount = feeAmount;
        if (feeShareRecipient != NULL_ADDRESS) {
            feeShareAmount = (amount * _feeShareRate) / FEE_DENOMINATOR;
            require(feeShareAmount > 0, "UP: fee share amount is 0");
            _safeTransfer(sender, token, feeShareAmount, feeShareRecipient);
            feeLeftAmount -= feeShareAmount;
        }
        address feeRecipient = (token.isNativeAsset() || _mainFeeTokens[token]) ? _mainFeeRecipient : _altFeeRecipient;
        _safeTransfer(sender, token, feeLeftAmount, feeRecipient);
        return (amount - feeAmount, feeAmount, feeShareAmount);
    }

    function _needPayFee() internal view returns (bool) {
        return
            _feeRate > 0 &&
            !_focAccounts[_msgSender()] &&
            _msgSender() != _mainFeeRecipient &&
            _msgSender() != _altFeeRecipient;
    }

    function _safeTransfer(address sender, address token, uint256 amount, address recipient) internal {
        if (token.isNativeAsset()) {
            recipient.safeTransfer(amount);
        } else if (sender == address(this)) {
            _safeTransferERC20(IERC20(token), recipient, amount);
        } else {
            IERC20(token).safeTransferFrom(sender, recipient, amount);
        }
    }

    function _tokenOut(address[] calldata path) internal pure returns (address) {
        return path[path.length - 1];
    }
}

//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

library SafeNativeAsset {
    // native asset address
    address internal constant NATIVE_ASSET = address(0);

    function nativeAsset() internal pure returns (address) {
        return NATIVE_ASSET;
    }

    function isNativeAsset(address addr) internal pure returns (bool) {
        return addr == NATIVE_ASSET;
    }

    function safeTransfer(address recipient, uint256 amount) internal {
        require(recipient != address(0), "SafeNativeAsset: transfer to the zero address");
        (bool success, ) = recipient.call{value: amount}(new bytes(0));
        require(success, "SafeNativeAsset: safe transfer native assets failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)
// Modified by UXUY

pragma solidity ^0.8.0;

import "../interfaces/tokens/IERC20.sol";
import "./Address.sol";

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

    address internal constant TRON_USDT_ADDRESS = address(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C);

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(to != address(0), "SafeERC20: transfer to the zero address");
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferTron(IERC20 token, address to, uint256 value) internal {
        require(to != address(0), "SafeERC20: transfer to the zero address");
        if (address(token) == TRON_USDT_ADDRESS) {
            // For USDT on Tron, transfer method always returns false, so _callOptionalReturn can not be used.
            token.transfer(to, value);
        } else {
            _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
        }
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(to != address(0), "SafeERC20: transfer to the zero address");
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

    function safeApproveToMax(IERC20 token, address spender, uint256 value) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance >= value) {
            return;
        }
        // For ERC-20 that has safe approve check, set approval to 0 before approve to max
        if (allowance > 0) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
        }
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, type(uint256).max));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./Pausable.sol";
import "./CallerControl.sol";
import "./SafeNativeAsset.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract CommonBase is Ownable, Pausable, CallerControl, ReentrancyGuard {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;

    uint256 internal constant TRON_CHAIN_ID = 0x1ebf88508a03865c71d452e25f4d51194196a1d22b6653dc;

    // The original address of this contract
    address private immutable _original;

    // ERC20 safeTransfer function pointer
    function(IERC20, address, uint256) internal _safeTransferERC20;

    // @dev Emitted when native assets (token=address(0)) or tokens are withdrawn by owner.
    event Withdrawn(address indexed token, address indexed to, uint256 amount);

    constructor() {
        _original = address(this);
        if (block.chainid == TRON_CHAIN_ID) {
            _safeTransferERC20 = SafeERC20.safeTransferTron;
        } else {
            _safeTransferERC20 = SafeERC20.safeTransfer;
        }
    }

    // @dev prevents delegatecall into the modified method
    modifier noDelegateCall() {
        _checkNotDelegateCall();
        _;
    }

    // @dev check whether deadline is reached
    modifier checkDeadline(uint256 deadline) {
        require(deadline == 0 || block.timestamp <= deadline, "CommonBase: transaction too old");
        _;
    }

    // @dev fallback function to receive native assets
    receive() external payable {}

    // @dev pause stops contract from doing any swap
    function pause() external onlyOwner {
        _pause();
    }

    // @dev resumes contract to do swap
    function unpause() external onlyOwner {
        _unpause();
    }

    // @dev withdraw eth to recipient
    function withdrawNativeAsset(uint256 amount, address recipient) external onlyOwner {
        recipient.safeTransfer(amount);
        emit Withdrawn(address(0), recipient, amount);
    }

    // @dev withdraw token to owner account
    function withdrawToken(address token, uint256 amount, address recipient) external onlyOwner {
        _safeTransferERC20(IERC20(token), recipient, amount);
        emit Withdrawn(token, recipient, amount);
    }

    // @dev update caller allowed status
    function updateAllowedCaller(address caller, bool allowed) external onlyOwner {
        _updateAllowedCaller(caller, allowed);
    }

    // @dev ensure not a delegatecall
    function _checkNotDelegateCall() private view {
        require(address(this) == _original, "CommonBase: delegate call not allowed");
    }
}

//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./Context.sol";

abstract contract CallerControl is Context {
    mapping(address => bool) private _allowedCallers;

    // @dev Emitted when allowed caller is changed.
    event AllowedCallerChanged(address indexed caller, bool allowed);

    // @dev modifier to check if message sender is allowed caller
    modifier onlyAllowedCaller() {
        require(_allowedCallers[_msgSender()], "CallerControl: msgSender is not allowed to call");
        _;
    }

    function _updateAllowedCaller(address caller, bool allowed) internal {
        if (allowed) {
            _allowedCallers[caller] = true;
        } else {
            delete _allowedCallers[caller];
        }
        emit AllowedCallerChanged(caller, allowed);
    }
}

//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract Adminable is Context {
    address private _admin;

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    /**
     * @dev Initializes the contract setting the deployer as the initial admin.
     */
    constructor() {
        _transferAdmin(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    /**
     * @dev Returns the address of the current admin.
     */
    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Throws if the sender is not the admin.
     */
    function _checkAdmin() internal view virtual {
        require(admin() == _msgSender(), "Adminable: caller is not the admin");
    }

    /**
     * @dev Leaves the contract without admin. It will not be possible to call
     * `onlyAdmin` functions anymore. Can only be called by the current admin.
     *
     * NOTE: Renouncing admin will leave the contract without an admin,
     * thereby removing any functionality that is only available to the admin.
     */
    function renounceAdmin() public virtual onlyAdmin {
        _transferAdmin(address(0));
    }

    /**
     * @dev Transfers admin of the contract to a new account (`newAdmin`).
     * Can only be called by the current admin.
     */
    function transferAdmin(address newAdmin) public virtual onlyAdmin {
        require(newAdmin != address(0), "Adminable: new admin is the zero address");
        _transferAdmin(newAdmin);
    }

    /**
     * @dev Transfers admin of the contract to a new account (`newAdmin`).
     * Internal function without access restriction.
     */
    function _transferAdmin(address newAdmin) internal virtual {
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./IProviderRegistry.sol";

interface ISwap is IProviderRegistry {
    struct SwapParams {
        bytes4 providerID;
        address[] path;
        uint256 amountIn;
        uint256 minAmountOut;
        address recipient;
        bytes data;
    }

    // @dev calculates the minimum tokens needed for the amountOut
    // @return swapData the data to be passed to the swap
    function getAmountIn(
        bytes4 providerID,
        address[] memory path,
        uint256 amountOut
    ) external returns (uint256 amountIn, bytes memory swapData);

    // @dev calculates the maximum tokens can be transferred for the amountIn
    // @return swapData the data to be passed to the swap
    function getAmountOut(
        bytes4 providerID,
        address[] memory path,
        uint256 amountIn
    ) external returns (uint256 amountOut, bytes memory swapData);

    // @dev view only version of getAmountIn
    function getAmountInView(
        bytes4 providerID,
        address[] memory path,
        uint256 amountOut
    ) external view returns (uint256 amountIn, bytes memory swapData);

    // @dev view only version of getAmountOut
    function getAmountOutView(
        bytes4 providerID,
        address[] memory path,
        uint256 amountIn
    ) external view returns (uint256 amountOut, bytes memory swapData);

    // @dev calls swap adapter to fulfill the exchange
    // @return amountOut the amount of tokens transferred out, guarantee amountOut >= params.minAmountOut
    function swap(SwapParams calldata params) external returns (uint256 amountOut);
}

//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

interface IProviderRegistry {
    event ProviderChanged(bytes4 indexed id, address provider);

    function setProvider(bytes4 id, address provider) external;

    function setProviders(bytes4[] calldata ids, address[] calldata providers) external;

    function removeProvider(bytes4 id) external;

    function removeProviders(bytes4[] calldata ids) external;

    function getProvider(bytes4 id) external view returns (address provider);

    function getProviders() external view returns (bytes4[] memory ids, address[] memory providers);
}

//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

interface IProtocol {
    struct SwapParams {
        bytes4 providerID;
        address[] path;
        uint256 minAmountOut;
        bytes data;
    }

    struct BridgeParams {
        bytes4 providerID;
        address tokenIn;
        uint256 chainIDOut;
        address tokenOut;
        uint256 minAmountOut;
        bytes data;
    }

    struct TradeParams {
        uint256 amountIn;
        SwapParams[] swaps;
        BridgeParams bridge;
        address recipient;
        address feeShareRecipient;
        uint256 extraFeeAmountIn; // Extra fee deducted to pay the gas fee
        SwapParams[] extraFeeSwaps;
        uint256 deadline;
    }

    // @dev Emitted when fee rate is updated
    event FeeRateChanged(uint256 feeRate, uint256 feeShareRate);

    // @dev Emitted when trade is executed
    event Traded(
        address indexed sender,
        address indexed recipient,
        address indexed feeShareRecipient,
        address tokenIn,
        uint256 amountIn,
        uint256 chainIDOut,
        address tokenOut,
        uint256 amountOut,
        uint256 bridgeTxnID,
        address feeToken,
        uint256 amountFee,
        uint256 amountFeeShare,
        uint256 amountExtraFee
    );

    // @dev gets the swap contract
    function swapContract() external view returns (address);

    // @dev gets the bridge contract
    function bridgeContract() external view returns (address);

    // @dev gets the fee denominator
    function feeDenominator() external pure returns (uint256);

    // @dev gets the total fee rate
    function feeRate() external view returns (uint256);

    // @dev gets the fee share rate
    function feeShareRate() external view returns (uint256);

    // @dev trade between tokens
    function trade(TradeParams calldata params) external payable returns (uint256 amountOut, uint256 bridgeTxnID);
}

//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./IProviderRegistry.sol";

interface IBridge is IProviderRegistry {
    struct BridgeParams {
        bytes4 providerID;
        address tokenIn;
        uint256 chainIDOut;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        address recipient;
        bytes data;
    }

    // @dev checks if the bridge adapter supports swap between different tokens.
    function supportSwap(bytes4 providerID) external view returns (bool);

    // @dev calls bridge adapter to fulfill the exchange.
    // @return amountOut the amount of tokens transferred out, may be 0.
    // @return txnID the transaction id of the bridge, may be 0.
    function bridge(BridgeParams calldata params) external returns (uint256 amountOut, uint256 txnID);
}