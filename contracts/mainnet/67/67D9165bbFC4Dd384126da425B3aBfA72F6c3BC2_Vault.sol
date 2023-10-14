// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;
pragma abicoder v2;

/*
 Optimization 100000
*/

import "./libs/SwapHelper.sol";
import "./libs/LiquidityHelper.sol";
import "./libs/VaultStructInfo.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import "@uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";
import "./libs/AaveHelper.sol";

contract Vault is IERC721Receiver, Ownable, ReentrancyGuard {
    using AaveHelper for AaveHelper.AaveInfo;
    using LiquidityHelper for LiquidityHelper.PositionMap;
    using VaultStructInfo for VaultStructInfo.BasicInfo;
    using VaultStructInfo for VaultStructInfo.TradingInfo;
    using VaultStructInfo for VaultStructInfo.TokenAllowedInfo;
    using VaultStructInfo for VaultStructInfo.UniInfo;

    LiquidityHelper.PositionMap private positionMap;
    VaultStructInfo.BasicInfo private basicInfo;
    VaultStructInfo.TradingInfo private tradingInfo;
    VaultStructInfo.TokenAllowedInfo private tokenAllowedInfo;
    VaultStructInfo.UniInfo private uniInfo;
    VaultStructInfo.ApproveInfo private approveInfo;
    mapping(uint256 => VaultStructInfo.LpRemoveRecord) private tokenIdLpInfoMap;
    AaveHelper.AaveInfo private aaveInfo;

    function initialize(string memory _vaultName, address _dispatcher, address[] memory allowTokens) external onlyOwner {
        basicInfo.initBasicInfo(_vaultName, _dispatcher, 0x5444bb8A081b527136F44F9c339CD3e515261e66);
        tradingInfo.initTradingInfo();
        uniInfo.initUniInfo();
        aaveInfo.initAaveInfo();
        tokenAllowedInfo.initTokenAllowedInfo(allowTokens);
    }

    function getVaultName() public view returns (string memory) {
        return basicInfo.vaultName;
    }

    function updateVaultName(string memory _newVaultName) external onlyOwner {
        basicInfo.vaultName = _newVaultName;
    }

    function onERC721Received(address /*operator*/, address, uint256 tokenId, bytes calldata) external override returns (bytes4) {
        positionMap.store[tokenId] = LiquidityHelper.Deposit({
            customerId: tokenId,
            token0: address(this),
            token1: address(this)
        });
        positionMap.keys.push(tokenId);
        positionMap.keyExists[tokenId] = true;
        return this.onERC721Received.selector;
    }

    modifier dispatcherCheck() {
        require(basicInfo.dispatcher == msg.sender || owner() == msg.sender, "Permission error: caller is not the dispatcher");
        _;
    }

    modifier onlyDispatcherCheck() {
        require(basicInfo.dispatcher == msg.sender, "Permission error: caller is not the dispatcher");
        _;
    }

    modifier allowListCheck(address tokenAddress) {
        require(tokenAllowedInfo.tokenExists[tokenAddress].allowed, "Token is not in allowlist");
        _;
    }


    /*
    * Swap
    */
    function swapInputETHForToken(address tokenOut, uint24 fee, uint256 amountIn, uint256 amountOutMin) external dispatcherCheck allowListCheck(tokenOut) returns (uint256 amountOut) {
        withdrawFromAaveForTrading(uniInfo.WETH, amountIn);
        amountOut = SwapHelper.swapInputETHForToken(tokenOut, fee, amountIn, amountOutMin, uniInfo.swapRouter, uniInfo.WETH);
        return tradingInfo.collectTradingFee(amountOut, tradingInfo.swapTradingFeeRate, tokenOut, basicInfo.socMainContract);
    }

    function swapInputForErc20Token(address tokenIn, address tokenOut, uint24 fee, uint256 amountIn, uint256 amountOutMin) external dispatcherCheck allowListCheck(tokenOut) returns (uint256 amountOut) {
        withdrawFromAaveForTrading(tokenIn, amountIn);
        amountOut = SwapHelper.swapInputForErc20Token(tokenIn, tokenOut, fee, amountIn, amountOutMin, uniInfo.swapRouter, approveInfo.swapApproveMap);
        return tradingInfo.collectTradingFee(amountOut, tradingInfo.swapTradingFeeRate, tokenOut, basicInfo.socMainContract);
    }

    function swapInputTokenToETH(address tokenIn, uint24 fee, uint256 amountIn, uint256 amountOutMin) external dispatcherCheck returns (uint256 amountOut) {
        withdrawFromAaveForTrading(tokenIn, amountIn);
        amountOut = SwapHelper.swapInputTokenToETH(tokenIn, fee, amountIn, amountOutMin, uniInfo.swapRouter, uniInfo.WETH, approveInfo.swapApproveMap);
        return tradingInfo.collectTradingFeeForETH(amountOut, tradingInfo.swapTradingFeeRate, basicInfo.socMainContract);
    }


    /*
    * Liquidity
    */
    function mintPosition(LiquidityHelper.CreateLpObject memory createLpObject) external dispatcherCheck allowListCheck(createLpObject.token0) allowListCheck(createLpObject.token1) {
        if (createLpObject.token0Amount == 0 || createLpObject.token1Amount == 0) {
            withdrawFromAaveForTrading(createLpObject.token0, createLpObject.token0Amount);
            withdrawFromAaveForTrading(createLpObject.token1, createLpObject.token1Amount);
        } else {
            withdrawAllFromAave(createLpObject.token0);
            withdrawAllFromAave(createLpObject.token1);
        }
        positionMap.mintNewPosition(createLpObject, uniInfo.nonfungiblePositionManager, approveInfo.liquidityApproveMap);
        if (!(createLpObject.token0Amount == 0 || createLpObject.token1Amount == 0)) {
            depositToAave(createLpObject.token0);
            depositToAave(createLpObject.token1);
        }
    }

    function increaseLiquidity(uint256 positionId, uint256 token0Amount, uint256 token1Amount) external dispatcherCheck {
        if (token0Amount == 0 || token1Amount == 0) {
            withdrawFromAaveForTrading(positionMap.store[positionId].token0, token0Amount);
            withdrawFromAaveForTrading(positionMap.store[positionId].token1, token1Amount);
        } else {
            withdrawAllFromAave(positionMap.store[positionId].token0);
            withdrawAllFromAave(positionMap.store[positionId].token1);
        }
        LiquidityHelper.increaseLiquidityCurrentRange(uniInfo.nonfungiblePositionManager, positionId, token0Amount, token1Amount);
        if (!(token0Amount == 0 || token1Amount == 0)) {
            depositToAave(positionMap.store[positionId].token0);
            depositToAave(positionMap.store[positionId].token1);
        }
    }

    function removeAllPositionById(uint256 positionId) external dispatcherCheck {
        (uint256 amount0, uint256 amount1) = LiquidityHelper.removeAllPositionById(positionId, uniInfo.nonfungiblePositionManager);
        (uint256 amount0Fee, uint256 amount1Fee) = collectAllFeesInner(positionId, amount0, amount1);
        tokenIdLpInfoMap[positionId] = VaultStructInfo.LpRemoveRecord({
            token0: positionMap.store[positionId].token0,
            token1: positionMap.store[positionId].token1,
            token0Amount: amount0,
            token1Amount: amount1,
            token0FeeAmount: amount0Fee,
            token1FeeAmount: amount1Fee
        });
        positionMap.deleteDeposit(positionId);
    }

    function removeLpInfoByTokenIds(uint256[] memory tokenIds) external dispatcherCheck {
        for(uint16 i = 0; i < tokenIds.length; i++) {
            delete tokenIdLpInfoMap[tokenIds[i]];
        }
    }

    function collectAllFees(uint256 positionId) external dispatcherCheck {
        collectAllFeesInner(positionId, 0, 0);
    }

    function collectAllFeesInner(uint256 positionId, uint256 amount0, uint256 amount1) internal returns (uint256 amount0Fee, uint256 amount1Fee) {
        (amount0Fee, amount1Fee) = LiquidityHelper.collectAllFees(positionId, uniInfo.nonfungiblePositionManager);
        tradingInfo.collectTradingFee(amount0Fee - amount0, tradingInfo.lpTradingFeeRate, positionMap.store[positionId].token0, basicInfo.socMainContract);
        tradingInfo.collectTradingFee(amount1Fee - amount1, tradingInfo.lpTradingFeeRate, positionMap.store[positionId].token1, basicInfo.socMainContract);
        return (amount0Fee - amount0, amount1Fee - amount1);
    }

    function burnNFT(uint128 tokenId) external dispatcherCheck {
        LiquidityHelper.burn(tokenId, uniInfo.nonfungiblePositionManager);
        positionMap.deleteDeposit(tokenId);
    }


    /*
    * Loan
    */
    function depositAllToAave() external dispatcherCheck {
        aaveInfo.depositAll(tokenAllowedInfo);
    }

    function withdrawAllFromAave() external dispatcherCheck {
        aaveInfo.withdrawAll(tokenAllowedInfo);
    }

    function withdrawFromAaveForTrading(address token, uint256 amountRequired) internal {
        if(aaveInfo.autoStake) {
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance < amountRequired && IERC20(tokenAllowedInfo.tokenExists[token].aTokenAddress).balanceOf(address(this)) > (amountRequired - balance)) {
                aaveInfo.withdraw(token, amountRequired - balance);
            }
        }
    }

    function withdrawAllFromAave(address token) internal {
        if(aaveInfo.autoStake) {
            uint256 balance = IERC20(tokenAllowedInfo.tokenExists[token].aTokenAddress).balanceOf(address(this));
            if (balance > 0) {
                aaveInfo.withdraw(token, type(uint256).max);
            }
        }
    }

    function depositToAave(address token) internal {
        if(aaveInfo.autoStake) {
            uint256 balance = IERC20(token).balanceOf(address(this));
            aaveInfo.deposit(token, balance);
        }
    }


    /*
    * Periphery functions
    */
    function setDispatcher(address _dispatcher) external onlyOwner {
        basicInfo.dispatcher = _dispatcher;
    }

    function setSwapAllowList(VaultStructInfo.AllowTokenObj[] memory _allowList) external onlyOwner {
        tokenAllowedInfo.setSwapAllowList(_allowList);
    }

    function updateTradingFee(uint8 _tradingFee) external onlyDispatcherCheck {
        require(_tradingFee <= 3, "Trading fee invalid");
        tradingInfo.tradingFee = _tradingFee;
    }

    function setAutoStake(bool _autoStake, VaultStructInfo.AllowTokenObj[] memory allowedTokens) external onlyOwner {
        aaveInfo.autoStake = _autoStake;
        tokenAllowedInfo.setSwapAllowList(allowedTokens);
        if (_autoStake) {
            aaveInfo.depositAll(tokenAllowedInfo);
        } else {
            aaveInfo.withdrawAll(tokenAllowedInfo);
        }
    }


    /*
    * View functions
    */
    function getPositionIds() external view returns (uint256[] memory) {
        return positionMap.getAllKeys();
    }

    function getTokenIdByCustomerId(uint256 customerId) public view returns (uint256) {
        return positionMap.getTokenIdByCustomerId(customerId);
    }

    function queryRemovedLpInfo(uint256 tokenId) public view returns(VaultStructInfo.LpRemoveRecord memory) {
        return tokenIdLpInfoMap[tokenId];
    }

    function getAllowTokenList() public view returns (VaultStructInfo.AllowTokenObj[] memory) {
        return tokenAllowedInfo.allowList;
    }

    function balanceOf(bool isNativeToken, address token) public view returns(uint256) {
        if (isNativeToken) {
            return address(this).balance;
        }
        if (aaveInfo.autoStake) {
            return (IERC20(token).balanceOf(address(this)) + IERC20(tokenAllowedInfo.tokenExists[token].aTokenAddress).balanceOf(address(this)));
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    function isAutoStake() public view returns(bool) {
        return aaveInfo.autoStake;
    }


    /*
    * Asset management
    */
    receive() external payable {}

    function withdrawErc721NFT(uint256 tokenId) external onlyOwner {
        uniInfo.nonfungiblePositionManager.safeTransferFrom(address(this), msg.sender, tokenId);
        positionMap.deleteDeposit(tokenId);
    }

    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        withdrawFromAaveForTrading(token, amount);
        TransferHelper.safeTransfer(token, msg.sender, amount);
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        TransferHelper.safeTransferETH(msg.sender, amount);
    }

    function deposit(address depositToken, uint256 amount) external onlyOwner {
        TransferHelper.safeTransferFrom(depositToken, msg.sender, address(this), amount);
        depositToAave(depositToken);
    }

    function depositEthToWeth() external payable onlyOwner {
        IWETH(uniInfo.WETH).deposit{value: msg.value}();
        depositToAave(uniInfo.WETH);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../interfaces/IPool.sol";
import "./VaultStructInfo.sol";

library AaveHelper {

    struct AaveInfo {
        IPool aavePool;
        bool autoStake;
        mapping(address => bool) aaveApproveMap;
    }

    function initAaveInfo(AaveInfo storage aaveInfo) internal {
        aaveInfo.aavePool = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
    }

    function depositAll(AaveInfo storage aaveInfo, VaultStructInfo.TokenAllowedInfo storage tokenAllowedInfo) internal {
        for(uint16 i = 0; i < tokenAllowedInfo.allowList.length; i++) {
            VaultStructInfo.AllowTokenObj memory object = tokenAllowedInfo.allowList[i];
            uint256 balance = IERC20(object.tokenAddress).balanceOf(address(this));
            if (object.allowed && balance > 0) {
                if (!aaveInfo.aaveApproveMap[object.tokenAddress]) {
                    TransferHelper.safeApprove(object.tokenAddress, address(aaveInfo.aavePool), type(uint256).max);
                    aaveInfo.aaveApproveMap[object.tokenAddress] = true;
                }
                aaveInfo.aavePool.supply(object.tokenAddress, balance, address(this), 0);
            }
        }
    }

    function withdrawAll(AaveInfo storage aaveInfo, VaultStructInfo.TokenAllowedInfo storage tokenAllowedInfo) internal {
        for(uint16 i = 0; i < tokenAllowedInfo.allowList.length; i++) {
            VaultStructInfo.AllowTokenObj memory object = tokenAllowedInfo.allowList[i];
            uint256 balance = IERC20(object.aTokenAddress).balanceOf(address(this));
            if (balance > 0) {
                aaveInfo.aavePool.withdraw(object.tokenAddress, type(uint256).max, address(this));
            }
        }
    }

    function withdraw(AaveInfo storage aaveInfo, address token, uint256 amount) internal {
        if (amount > 0) {
            aaveInfo.aavePool.withdraw(token, amount, address(this));
        }
    }

    function deposit(AaveInfo storage aaveInfo, address token, uint256 amount) internal {
        if (amount > 0) {
            if (!aaveInfo.aaveApproveMap[token]) {
                TransferHelper.safeApprove(token, address(aaveInfo.aavePool), type(uint256).max);
                aaveInfo.aaveApproveMap[token] = true;
            }
            aaveInfo.aavePool.supply(token, amount, address(this), 0);
        }
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter is IUniswapV3SwapCallback {
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
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
pragma solidity ^0.8.20;
pragma abicoder v2;

import "./TransferHelper.sol";
import "../interfaces/ISwapRouter02.sol";
import "../interfaces/INonfungiblePositionManager.sol";

library VaultStructInfo {


    /*
        Soc Basic Info
    */
    struct BasicInfo {
        string vaultName;
        address dispatcher;
        address socMainContract;
    }

    function initBasicInfo(BasicInfo storage basicInfo, string memory _vaultName, address _dispatcher, address _socMainContract) internal {
        basicInfo.vaultName = _vaultName;
        basicInfo.dispatcher = _dispatcher;
        basicInfo.socMainContract = _socMainContract;
    }


    /*
        Vault Allowlist Token Mapping
    */
    struct AllowTokenObj {
        address tokenAddress;
        address aTokenAddress;
        bool allowed;
    }

    struct TokenAllowedInfo {
        AllowTokenObj[] allowList;
        mapping(address => AllowTokenObj) tokenExists;
    }

    function initTokenAllowedInfo(TokenAllowedInfo storage tokenAllowedInfo, address[] memory allowTokens) internal {
        for (uint i = 0; i < allowTokens.length; i++) {
            AllowTokenObj memory obj = AllowTokenObj({
                tokenAddress : allowTokens[i],
                aTokenAddress : address(0),
                allowed : true
            });
            tokenAllowedInfo.allowList.push(obj);
            tokenAllowedInfo.tokenExists[allowTokens[i]] = obj;
        }
    }

    function setSwapAllowList(TokenAllowedInfo storage tokenAllowedInfo, AllowTokenObj[] memory _allowList) internal {
        delete tokenAllowedInfo.allowList;
        for (uint i = 0; i < _allowList.length; i++) {
            tokenAllowedInfo.allowList.push(_allowList[i]);
            tokenAllowedInfo.tokenExists[_allowList[i].tokenAddress] = _allowList[i];
        }
    }


    /*
        Uniswap Info
    */
    struct UniInfo {
        address WETH;
        ISwapRouter02 swapRouter;
        INonfungiblePositionManager nonfungiblePositionManager;
    }

    function initUniInfo(UniInfo storage uniInfo) internal {
        uniInfo.WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        uniInfo.nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
        uniInfo.swapRouter = ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    }


    /*
        Trading Fee Info
    */
    struct TradingFeeObj {
        uint256 pendingCollectFee;
        uint16 txCount;
    }

    struct TradingInfo {
        uint8 sendTradingFeeInterval;
        uint8 tradingFee;
        uint16 swapTradingFeeRate;
        uint16 lpTradingFeeRate;
        mapping(address => TradingFeeObj) tradingFeeMap;
    }

    function initTradingInfo(TradingInfo storage tradingInfo) internal {
        tradingInfo.tradingFee = 1;
        tradingInfo.swapTradingFeeRate = 5000;
        tradingInfo.lpTradingFeeRate = 10;
        tradingInfo.sendTradingFeeInterval = 1;
    }

    function collectTradingFee(TradingInfo storage tradingInfo, uint256 amount, uint16 feeRate, address token, address socMainContract) internal returns (uint256) {
        if (amount > 0) {
            uint256 fee = (amount * tradingInfo.tradingFee) / feeRate;
            tradingInfo.tradingFeeMap[token].txCount = tradingInfo.tradingFeeMap[token].txCount + 1;
            tradingInfo.tradingFeeMap[token].pendingCollectFee = tradingInfo.tradingFeeMap[token].pendingCollectFee + fee;
            if (tradingInfo.tradingFeeMap[token].txCount >= tradingInfo.sendTradingFeeInterval && IERC20(token).balanceOf(address(this)) >= tradingInfo.tradingFeeMap[token].pendingCollectFee) {
                TransferHelper.safeTransfer(token, socMainContract, tradingInfo.tradingFeeMap[token].pendingCollectFee);
                tradingInfo.tradingFeeMap[token].txCount = 0;
                tradingInfo.tradingFeeMap[token].pendingCollectFee = 0;
            }
            return amount - fee;
        } else {
            return amount;
        }
    }

    function collectTradingFeeForETH(TradingInfo storage tradingInfo, uint256 amount, uint16 feeRate, address socMainContract) internal returns (uint256) {
        if (amount > 0) {
            uint256 fee = (amount * tradingInfo.tradingFee) / feeRate;
            TransferHelper.safeTransferETH(socMainContract, fee);
            return amount - fee;
        } else {
            return amount;
        }
    }


    /*
        Vault Approve Info
    */
    struct ApproveInfo {
        mapping(address => bool) liquidityApproveMap;
        mapping(address => bool) swapApproveMap;
    }


    /*
        LP Removed Info
    */
    struct LpRemoveRecord {
        address token0;
        address token1;
        uint256 token0Amount;
        uint256 token1Amount;
        uint256 token0FeeAmount;
        uint256 token1FeeAmount;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./TransferHelper.sol";
import "../interfaces/INonfungiblePositionManager.sol";

library LiquidityHelper {

    struct Deposit {
        uint256 customerId;
        address token0;
        address token1;
    }

    struct PositionMap {
        mapping(uint256 => Deposit) store;
        mapping(uint256 => bool) keyExists;
        uint256[] keys;
    }

    struct CreateLpObject {
        uint256 customerId;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 token0Amount;
        uint256 token1Amount;
    }

    function mintNewPosition(PositionMap storage positionMap, CreateLpObject memory createLpObj, INonfungiblePositionManager nonfungiblePositionManager, mapping(address => bool) storage approveMap) internal returns (uint256 tokenId, uint256 amount0, uint256 amount1) {
        if(!approveMap[createLpObj.token0]) {
            TransferHelper.safeApprove(createLpObj.token0, address(nonfungiblePositionManager), type(uint256).max);
            approveMap[createLpObj.token0] = true;
        }
        if(!approveMap[createLpObj.token1]) {
            TransferHelper.safeApprove(createLpObj.token1, address(nonfungiblePositionManager), type(uint256).max);
            approveMap[createLpObj.token1] = true;
        }
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
                token0: createLpObj.token0,
                token1: createLpObj.token1,
                fee: createLpObj.fee,
                tickLower: createLpObj.tickLower,
                tickUpper: createLpObj.tickUpper,
                amount0Desired: createLpObj.token0Amount,
                amount1Desired: createLpObj.token1Amount,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + (15 minutes)
            });
        (tokenId, , amount0, amount1) = nonfungiblePositionManager.mint(params);
        positionMap.store[tokenId] = Deposit({
            customerId: createLpObj.customerId,
            token0: createLpObj.token0,
            token1: createLpObj.token1
        });
        positionMap.keys.push(tokenId);
        positionMap.keyExists[tokenId] = true;
        return (tokenId, amount0, amount1);
    }

    function increaseLiquidityCurrentRange(INonfungiblePositionManager nonfungiblePositionManager, uint256 tokenId, uint256 amountAdd0, uint256 amountAdd1) internal returns (uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.IncreaseLiquidityParams memory params =
                            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: amountAdd0,
                amount1Desired: amountAdd1,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp + (15 minutes)
            });
        (, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity(params);
        return (amount0, amount1);
    }

    function queryLiquidityById(uint256 tokenId, INonfungiblePositionManager nonfungiblePositionManager) internal view returns (uint128 liquidity) {
        INonfungiblePositionManager.Position memory response = nonfungiblePositionManager.positions(tokenId);
        return response.liquidity;
    }

    function getTokenIdByCustomerId(PositionMap storage positionMap, uint256 customerId) internal view returns (uint256) {
        for (uint i = 0; i < positionMap.keys.length; i++) {
            if (positionMap.store[positionMap.keys[i]].customerId == customerId) {
                return positionMap.keys[i];
            }
        }
        return 0;
    }

    function removeAllPositionById(uint256 tokenId, INonfungiblePositionManager nonfungiblePositionManager) internal returns (uint256 amount0, uint256 amount1) {
        return nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams({
            tokenId: tokenId,
            liquidity: queryLiquidityById(tokenId, nonfungiblePositionManager),
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp + (15 minutes)
        }));
    }

    function collectAllFees(uint256 tokenId, INonfungiblePositionManager nonfungiblePositionManager) internal returns (uint256 amount0, uint256 amount1) {
        return nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        }));
    }

    function burn(uint256 tokenId, INonfungiblePositionManager nonfungiblePositionManager) internal {
        nonfungiblePositionManager.burn(tokenId);
    }

    function deleteDeposit(PositionMap storage positionMap, uint256 key) internal {
        if(positionMap.keyExists[key]) {
            delete positionMap.store[key];
            positionMap.keyExists[key] = false;
            for (uint i = 0; i < positionMap.keys.length; i++) {
                if (positionMap.keys[i] == key) {
                    positionMap.keys[i] = positionMap.keys[positionMap.keys.length - 1];
                    positionMap.keys.pop();
                    break;
                }
            }
        }
    }

    function getAllKeys(PositionMap storage positionMap) internal view returns (uint256[] memory)  {
        return positionMap.keys;
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;
pragma abicoder v2;

import "./TransferHelper.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/ISwapRouter02.sol";

library SwapHelper {

    function swapInputETHForToken(address tokenOut, uint24 fee, uint256 amountIn, uint256 amountOutMin, ISwapRouter02 swapRouter, address WETH) internal returns (uint256 amountOut) {
        require(amountIn <= address(this).balance, "Not enough balance");
        IV3SwapRouter.ExactInputSingleParams memory params =
                            IV3SwapRouter.ExactInputSingleParams({
                tokenIn: WETH,
                tokenOut: tokenOut,
                fee: fee,
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });
        return swapRouter.exactInputSingle{value: amountIn}(params);
    }

    function swapInputForErc20Token(address tokenIn, address tokenOut, uint24 fee, uint256 amountIn, uint256 amountOutMin, ISwapRouter02 swapRouter, mapping(address => bool) storage approveMap) internal returns (uint256) {
        if(!approveMap[tokenIn]) {
            TransferHelper.safeApprove(tokenIn, address(swapRouter), type(uint256).max);
            approveMap[tokenIn] = true;
        }
        IV3SwapRouter.ExactInputSingleParams memory params =
                            IV3SwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });
        return swapRouter.exactInputSingle(params);
    }

    function swapInputTokenToETH(address tokenIn, uint24 fee, uint256 amountIn, uint256 amountOutMin, ISwapRouter02 swapRouter, address WETH, mapping(address => bool) storage approveMap) internal returns (uint256 amountOut) {
        if(!approveMap[tokenIn]) {
            TransferHelper.safeApprove(tokenIn, address(swapRouter), type(uint256).max);
            approveMap[tokenIn] = true;
        }
        IV3SwapRouter.ExactInputSingleParams memory params =
                            IV3SwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: WETH,
                fee: fee,
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });
        amountOut = swapRouter.exactInputSingle(params);
        IWETH(WETH).withdraw(amountOut);
        return amountOut;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Importing from @uniswap doesnt work with @openzepplins latest release so this is refactored
// Source: https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/INonfungiblePositionManager.sol

interface INonfungiblePositionManager {

    function approve(address to, uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(
        MintParams calldata params
    )
    external
    payable
    returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    struct Position {
        uint96 nonce;
        address operator;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    function positions(
        uint256 tokenId
    )
    external
    view
    returns (Position memory);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
    external
    payable
    returns (
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(
        CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    function factory() external view returns (address);

    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/ISelfPermit.sol';
import "@uniswap/swap-router-contracts/contracts/interfaces/IV2SwapRouter.sol";
import "@uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";
import "@uniswap/swap-router-contracts/contracts/interfaces/IMulticallExtended.sol";

/// @title Router token swapping functionality
interface ISwapRouter02 is IV2SwapRouter, IV3SwapRouter, IMulticallExtended, ISelfPermit {

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
                            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IWETH {
    // 这些是标准的 ERC-20 函数
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    // WETH 特定的函数
    function deposit() external payable;
    function withdraw(uint value) external;

    // 通常 ERC-20 事件
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.20;

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface IPool {

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;


    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);


    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts of the assets being flash-borrowed
   * @param interestRateModes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
   * @param asset The address of the asset being flash-borrowed
   * @param amount The amount of the asset being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

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
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/IMulticall.sol';

/// @title MulticallExtended interface
/// @notice Enables calling multiple methods in a single call to the contract with optional validation
interface IMulticallExtended is IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param deadline The time by which this function must be called before failing
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(uint256 deadline, bytes[] calldata data) external payable returns (bytes[] memory results);

    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param previousBlockhash The expected parent blockHash
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes32 previousBlockhash, bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V2
interface IV2SwapRouter {
    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param amountIn The amount of token to swap
    /// @param amountOutMin The minimum amount of output that must be received
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountOut The amount of the received token
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut);

    /// @notice Swaps as little as possible of one token for an exact amount of another token
    /// @param amountOut The amount of token to swap for
    /// @param amountInMax The maximum amount of input that the caller will pay
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountIn The amount of token to pay
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
interface ISelfPermit {
    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// Can be used instead of #selfPermit to prevent calls from failing due to a frontrun of a call to #selfPermit
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// Can be used instead of #selfPermitAllowed to prevent calls from failing due to a frontrun of a call to #selfPermitAllowed.
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}