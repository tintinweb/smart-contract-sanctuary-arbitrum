// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "src/adapters/pendle/AbstractPendleAdapter.sol";

import "src/interfaces/penpie/IPendleMarketDepositHelper.sol";
import "src/interfaces/penpie/IMasterPenpie.sol";
import "src/interfaces/penpie/IPendleStaking.sol";
import "src/interfaces/penpie/IPendleRewarder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PenpiePendleAdapter is AbstractPendleAdapter {

    using SafeERC20 for IERC20;

    IPendleMarketDepositHelper public immutable DEPOSIT_HELPER;
    IMasterPenpie              public immutable MASTER_PENPIE;
    IPendleStaking             public immutable PENDLE_STAKING;
    IPendleRewarder            public immutable REWARDER;
    IERC20                     public immutable PENPIE;

    constructor(
        address _balancer,
        address _asset,
        address _market,
        address _router,
        address _depositHelper
    )
    AbstractPendleAdapter(_balancer, _asset, _market, _router)
    {

    }

    function _claimAll(address receiver) internal virtual override {
        address[] memory stakingTokens = new address[](1);
        stakingTokens[0] = address(PENDLE_MARKET);

        PENDLE_STAKING.harvestMarketReward(stakingTokens[0], address(this), 0);
        MASTER_PENPIE.multiclaim(stakingTokens); // claim all rewards

        (address[] memory rewardTokens,) = REWARDER.rewardTokenInfos();

        for (uint i = 0; i < rewardTokens.length; ++i) {
            uint rewardAmount = IERC20(rewardTokens[i]).balanceOf(address(this));
            if (rewardAmount > 0) {
                IERC20(rewardTokens[i]).safeTransfer(receiver, rewardAmount);
            }
        }

        uint pnpAmount = PENPIE.balanceOf(address(this));
        if (pnpAmount > 0) {
            PENPIE.safeTransfer(receiver, pnpAmount);
        }
    }

    function _unstakePendleLp(uint256 lpAmount) internal virtual override {
        uint256 balance = DEPOSIT_HELPER.balance(address(PENDLE_MARKET), address(this));
        if (balance >= lpAmount) {
            DEPOSIT_HELPER.withdrawMarket(address(PENDLE_MARKET), lpAmount);
        }
    }

    function _stakePendleLp() internal virtual override {
        uint256 marketLpAmount = PENDLE_MARKET.balanceOf(address(this));
        if (marketLpAmount > 0) {
            IERC20(PENDLE_MARKET).forceApprove(address(PENDLE_STAKING), marketLpAmount);
            DEPOSIT_HELPER.depositMarket(address(PENDLE_MARKET), marketLpAmount);
        }
    }

    function negotiableTokens()
        public
        virtual
        override
        returns(address[] memory tokens)
    {
        (,address[] memory marketRewardTokens,,) =
        MASTER_PENPIE.allPendingTokens(address(PENDLE_MARKET), address(this));

        tokens = new address[](marketRewardTokens.length + 2);

        for (uint256 i = 0; i < marketRewardTokens.length; i++) {
            tokens[i]  = marketRewardTokens[i];
        }

        tokens[marketRewardTokens.length] = address(PENPIE);
        tokens[marketRewardTokens.length + 1] = address(PENDLE_MARKET);
    }

    function value()
        public
        view
        virtual
        override
        returns (uint estimatedValue, uint lpAmount)
    {
        lpAmount = DEPOSIT_HELPER.balance(address(PENDLE_MARKET), address(this));
        estimatedValue = lpAmount;
    }

    function pendingRewards()
        public
        view
        virtual
        override
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        (address[] memory rewardTokens,) = REWARDER.rewardTokenInfos();

        tokens  = new address[](rewardTokens.length + 1); // with PNP
        amounts = new uint256[](rewardTokens.length + 1); // with PNP

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            tokens[i]  = rewardToken;
            amounts[i] = REWARDER.earned(address(this), rewardToken);
        }

        (uint256 pnpRewardAmount, , ,) = MASTER_PENPIE.allPendingTokens(address(PENDLE_MARKET), address(this));
        tokens[rewardTokens.length] = address(PENPIE);
        amounts[rewardTokens.length] = pnpRewardAmount;
    }

    function description()
        external
        view
        override
        returns (string memory)
    {
        (IStandardizedYield sy, ,) = PENDLE_MARKET.readTokens();
        (,address nativePool,) = sy.assetInfo();

        string memory poolTokens = '[';
        address[] memory tokens = sy.getTokensIn();
        bool comma = false;
        for (uint256 i = 0; i < tokens.length; i++) {
            if(tokens[i] != address(0) && tokens[i] != nativePool) {
                if (comma) {
                    poolTokens = string.concat(poolTokens, ',');
                }
                comma = true;
                poolTokens = string.concat(poolTokens, '"', Strings.toHexString(tokens[i]),'"');
            }
        }
        poolTokens = string.concat(poolTokens, ']');

        address[] memory marketRewardTokens;
        (,marketRewardTokens,,) =
        MASTER_PENPIE.allPendingTokens(address(PENDLE_MARKET), address(this));
        string memory rewardTokens = '[';
        for (uint256 i = 0; i < marketRewardTokens.length; i++) {
            rewardTokens = string.concat(rewardTokens, '"', Strings.toHexString(marketRewardTokens[i]), '",');
        }
        rewardTokens = string.concat(rewardTokens, '"',Strings.toHexString(address(PENPIE)),'"');
        rewardTokens = string.concat(rewardTokens, ']');

        return string.concat(
            '{',
            '"type":"penpieThena",',
            '"poolAddress":"',Strings.toHexString(nativePool),'",',
            '"marketAddress":"',Strings.toHexString(address(PENDLE_MARKET)),'",',
            '"farmingAddress":"',Strings.toHexString(address(DEPOSIT_HELPER)),'",',
            '"poolTokens":',poolTokens,',',
            '"rewardTokens":',rewardTokens,
            '}'
        );
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "src/adapters/BaseAdapter.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "pendle-core/interfaces/IPActionAddRemoveLiqV3.sol";
import "pendle-core/interfaces/IPMarket.sol";

abstract contract AbstractPendleAdapter is BaseAdapter {

    using SafeERC20 for IERC20;

    IERC20 immutable public ASSET;
    IPMarket immutable public PENDLE_MARKET;
    IPActionAddRemoveLiqV3 immutable public ROUTER;

    constructor(
        address _balancer,
        address _asset, 
        address _market, 
        address _router
    ) 
    BaseAdapter(_balancer)
    {

    }

    function _invest() internal virtual override {
        _mintPendleLp();
        _stakePendleLp();
    }
    
    function _redeem(uint256 lpAmount, address to)
        internal
        virtual
        override
        returns (address[] memory tokens, uint256[] memory amounts) 
    {
        uint256 pendleLpAmountAccrued = PENDLE_MARKET.balanceOf(address(this));
        _unstakePendleLp(lpAmount);
        pendleLpAmountAccrued = PENDLE_MARKET.balanceOf(address(this)) - pendleLpAmountAccrued;

        require(pendleLpAmountAccrued == lpAmount, "Pendle: IL");

        uint256 assetAmountAccrued = ASSET.balanceOf(address(this));
        _burnPendleLp(pendleLpAmountAccrued);
        assetAmountAccrued = ASSET.balanceOf(address(this)) - assetAmountAccrued;

        require(assetAmountAccrued > 0, "Pendle: IL");

        tokens = new address[](1);
        amounts = new uint256[](1);

        tokens[0] = address(ASSET);
        amounts[0] = assetAmountAccrued;

        ASSET.safeTransfer(to, assetAmountAccrued);
    }

    function depositTokens() 
        public 
        view 
        virtual 
        override 
    returns (address[] memory tokens) 
    {
        tokens = new address[](1);
        tokens[0] = address(ASSET);
    }

    function ratios() 
        external 
        view 
        virtual 
        override 
    returns(address[] memory tokens, uint256[] memory ratio) {
        tokens = new address[](1);
        tokens[0] = address(ASSET);

        ratio = new uint256[](1);
        ratio[0] = 1e18;
    }

    function _mintPendleLp() internal virtual {
        uint256 assetAmount = ASSET.balanceOf(address(this));
        if (assetAmount > 0) {
            ROUTER.addLiquiditySingleToken(
                address(this),
                address(PENDLE_MARKET),
                0,
                _approxParams(),
                _tokenInput(assetAmount),
                _limitOrderData()
            );
        }
    }

    function _burnPendleLp(uint256 lpAmount) internal virtual {
        if(lpAmount > 0) {
            ROUTER.removeLiquiditySingleToken(
                address(this),
                address(PENDLE_MARKET),
                lpAmount,
                _tokenOutput(),
                _limitOrderData()
            );
        }
    }

    function _tokenInput(uint amountIn) private returns (TokenInput memory) {
        return TokenInput(
            address(ASSET),
            amountIn,
            address(ASSET),
            address(0),
            SwapData(SwapType.NONE, address(0), bytes(""), false)
        );
    }

    function _tokenOutput() private returns (TokenOutput memory) {
        return TokenOutput(
            address(ASSET),
            0,
            address(ASSET),
            address(0),
            SwapData(SwapType.NONE, address(0), bytes(""), false)
        );
    }

    function _approxParams() private returns (ApproxParams memory) {
        return ApproxParams(
            0,
            type(uint256).max,
            0,
            256,
            1e15
        );
    }

    function _limitOrderData() private returns (LimitOrderData memory) {
        return LimitOrderData(
            address(0),
            0,
            new FillOrderParams[](0),
            new FillOrderParams[](0),
            ""
        );
    }

    function _stakePendleLp() internal virtual;
    function _unstakePendleLp(uint256 lpAmount) internal virtual;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPendleMarketDepositHelper {

    function balance(address _market, address _address) external view returns (uint256);
    function depositMarket(address _market, uint256 _amount) external;
    function withdrawMarket(address _market, uint256 _amount) external;
    function masterpenpie() external view returns (address);
    function pendleStaking() external view returns (address);
    function poolInfo(address) external view returns (address rewarder, bool isActive);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMasterPenpie {

    function penpieOFT() external view returns (address);
    function multiclaim(address[] memory _stakingTokens) external;
    function allPendingTokens(address _stakingToken, address _user)
        external
        view
        returns (
            uint256 pendingPenpie,
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
        );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPendleStaking {

    function harvestMarketReward(address _market, address _caller, uint256 _minEthRecive) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPendleRewarder {

    function rewardTokenInfos() external view returns (address[] memory, string[] memory);
    function earned(address account, address rewardToken) external view returns (uint);

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IBalancer.sol";
import "../helpers/SwapExecutor.sol";


abstract contract BaseAdapter is IAdapter {
    using SafeERC20 for IERC20;

    address private immutable BALANCER;
    SwapExecutor public immutable SWAP_EXECUTOR;

    modifier onlyBalancer {
        require(msg.sender == BALANCER);
        _;
    }

    constructor(address balancer_) {
        BALANCER = balancer_;
        SWAP_EXECUTOR = SwapExecutor(IBalancer(balancer_).swapExecutor());
    }

    function invest(address dustReceiver)
        external
        virtual
        override
        onlyBalancer
        returns (uint256 valueBefore, uint256 valueAfter)
    {
        (valueBefore, valueAfter) = _investInternal(dustReceiver);
    }

    function redeem(uint256 lpAmount, address to)
        external
        virtual
        override
        onlyBalancer
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        (tokens, amounts) = _redeem(lpAmount, to);
    }

    function compound(IBalancer.SwapInfo[] calldata swaps)
        external
        virtual
        override
        onlyBalancer
        returns (uint256 valueBefore, uint256 valueAfter)
    {
        (valueBefore,) = value();

        _claimAll(address(this));

        for (uint i = 0; i < swaps.length; ++i) {
            IBalancer.SwapInfo calldata swap = swaps[i];
            IERC20(swap.token).safeTransfer(address(SWAP_EXECUTOR), swap.amount);
        }
        SWAP_EXECUTOR.executeSwaps(swaps);

        (, valueAfter) = _investInternal(address(BALANCER));
    }

    function claim()
        external
        virtual
        override
        onlyBalancer
    {
        _claimAll(BALANCER);
    }

    function claim(address receiver)
        external
        virtual
        override
        onlyBalancer
        returns (address[] memory rewardTokens, uint[] memory rewardsClaimed, uint[] memory rewardBalances)
    {
        (rewardTokens,) = pendingRewards();
        rewardsClaimed = new uint[](rewardTokens.length);
        rewardBalances = new uint[](rewardTokens.length);

        for (uint i = 0; i < rewardTokens.length; ++i) {
            // will be calculated later
            rewardsClaimed[i] = IERC20(rewardTokens[i]).balanceOf(receiver);
        }

        _claimAll(receiver);

        for (uint i = 0; i < rewardTokens.length; ++i) {
            uint rewardBalance = IERC20(rewardTokens[i]).balanceOf(receiver);
            rewardsClaimed[i] = rewardBalance - rewardsClaimed[i];
            rewardBalances[i] = rewardBalance;
        }
    }

    function recoverFunds(IBalancer.TransferInfo calldata transfer, address to) 
        external 
        virtual 
        override 
        onlyBalancer
    {
        address[] memory tokens = negotiableTokens();
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == transfer.token) {
                revert UnsupportedToken(transfer.token);
            }
        }
        IERC20(transfer.token).safeTransfer(to, transfer.amount);
    }

    /// @notice Execute calls by the adapter to reallocate funds to other adapter if external api used in the adapter is changed
    /// @dev Calls must be executed by timelock
    function emergencyCall(CallInfo[] calldata calls)
        external
        virtual
        override
        onlyBalancer
    {
        for (uint i = 0; i < calls.length; i++) {
            CallInfo calldata call = calls[i];
            Address.functionCall(call.callee, call.data);
        }
    }

    function _investInternal(address dustReceiver) internal returns (uint256 valueBefore, uint256 valueAfter) {
        (valueBefore,) = value();
        valueBefore += 1; // round up
        _invest();
        (valueAfter,) = value();
        _returnDust(dustReceiver);
    }

    function _returnDust(address dustReceiver) internal {
        address[] memory tokens = depositTokens();
        uint tokensLength = tokens.length;

        for (uint i = 0; i < tokensLength; ++i) {
            IERC20 token = IERC20(tokens[i]);
            uint256 tokenBalance = token.balanceOf(address(this));

            if (tokenBalance > 0) {
                SafeERC20.safeTransfer(token, dustReceiver, tokenBalance);
            }
        }
    }

    function balancer() external view returns (address) {
        return BALANCER;
    }

    function _invest() internal virtual;
    function _redeem(uint256 lpAmount, address to)
        internal
        virtual
        returns (address[] memory tokens, uint[] memory amounts);
    function _claimAll(address to) internal virtual;
    function negotiableTokens() public virtual returns(address[] memory tokens);
    function depositTokens() public virtual view returns (address[] memory tokens);
    function value() public view virtual returns (uint estimatedValue, uint lpAmount);
    function pendingRewards() public view virtual returns(address[] memory tokens, uint[] memory amounts);
    function ratios() external view virtual returns(address[] memory tokens, uint[] memory ratio);
    function description() external virtual returns (string memory);

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../router/base/MarketApproxLib.sol";
import "./IPAllActionTypeV3.sol";

interface IPActionAddRemoveLiqV3 {
    event AddLiquidityDualSyAndPt(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        uint256 netSyUsed,
        uint256 netPtUsed,
        uint256 netLpOut
    );

    event AddLiquidityDualTokenAndPt(
        address indexed caller,
        address indexed market,
        address indexed tokenIn,
        address receiver,
        uint256 netTokenUsed,
        uint256 netPtUsed,
        uint256 netLpOut,
        uint256 netSyInterm
    );

    event AddLiquiditySinglePt(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        uint256 netPtIn,
        uint256 netLpOut
    );

    event AddLiquiditySingleSy(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        uint256 netSyIn,
        uint256 netLpOut
    );

    event AddLiquiditySingleToken(
        address indexed caller,
        address indexed market,
        address indexed token,
        address receiver,
        uint256 netTokenIn,
        uint256 netLpOut,
        uint256 netSyInterm
    );

    event AddLiquiditySingleSyKeepYt(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        uint256 netSyIn,
        uint256 netSyMintPy,
        uint256 netLpOut,
        uint256 netYtOut
    );

    event AddLiquiditySingleTokenKeepYt(
        address indexed caller,
        address indexed market,
        address indexed token,
        address receiver,
        uint256 netTokenIn,
        uint256 netLpOut,
        uint256 netYtOut,
        uint256 netSyMintPy,
        uint256 netSyInterm
    );

    event RemoveLiquidityDualSyAndPt(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        uint256 netLpToRemove,
        uint256 netPtOut,
        uint256 netSyOut
    );

    event RemoveLiquidityDualTokenAndPt(
        address indexed caller,
        address indexed market,
        address indexed tokenOut,
        address receiver,
        uint256 netLpToRemove,
        uint256 netPtOut,
        uint256 netTokenOut,
        uint256 netSyInterm
    );

    event RemoveLiquiditySinglePt(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        uint256 netLpToRemove,
        uint256 netPtOut
    );

    event RemoveLiquiditySingleSy(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        uint256 netLpToRemove,
        uint256 netSyOut
    );

    event RemoveLiquiditySingleToken(
        address indexed caller,
        address indexed market,
        address indexed token,
        address receiver,
        uint256 netLpToRemove,
        uint256 netTokenOut,
        uint256 netSyInterm
    );

    function addLiquidityDualTokenAndPt(
        address receiver,
        address market,
        TokenInput calldata input,
        uint256 netPtDesired,
        uint256 minLpOut
    ) external payable returns (uint256 netLpOut, uint256 netPtUsed, uint256 netSyInterm);

    function addLiquidityDualSyAndPt(
        address receiver,
        address market,
        uint256 netSyDesired,
        uint256 netPtDesired,
        uint256 minLpOut
    ) external returns (uint256 netLpOut, uint256 netSyUsed, uint256 netPtUsed);

    function addLiquiditySinglePt(
        address receiver,
        address market,
        uint256 netPtIn,
        uint256 minLpOut,
        ApproxParams calldata guessPtSwapToSy,
        LimitOrderData calldata limit
    ) external returns (uint256 netLpOut, uint256 netSyFee);

    function addLiquiditySingleToken(
        address receiver,
        address market,
        uint256 minLpOut,
        ApproxParams calldata guessPtReceivedFromSy,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) external payable returns (uint256 netLpOut, uint256 netSyFee, uint256 netSyInterm);

    function addLiquiditySingleSy(
        address receiver,
        address market,
        uint256 netSyIn,
        uint256 minLpOut,
        ApproxParams calldata guessPtReceivedFromSy,
        LimitOrderData calldata limit
    ) external returns (uint256 netLpOut, uint256 netSyFee);

    function addLiquiditySingleTokenKeepYt(
        address receiver,
        address market,
        uint256 minLpOut,
        uint256 minYtOut,
        TokenInput calldata input
    ) external payable returns (uint256 netLpOut, uint256 netYtOut, uint256 netSyMintPy, uint256 netSyInterm);

    function addLiquiditySingleSyKeepYt(
        address receiver,
        address market,
        uint256 netSyIn,
        uint256 minLpOut,
        uint256 minYtOut
    ) external returns (uint256 netLpOut, uint256 netYtOut, uint256 netSyMintPy);

    function removeLiquidityDualTokenAndPt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        TokenOutput calldata output,
        uint256 minPtOut
    ) external returns (uint256 netTokenOut, uint256 netPtOut, uint256 netSyInterm);

    function removeLiquidityDualSyAndPt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minSyOut,
        uint256 minPtOut
    ) external returns (uint256 netSyOut, uint256 netPtOut);

    function removeLiquiditySinglePt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minPtOut,
        ApproxParams calldata guessPtReceivedFromSy,
        LimitOrderData calldata limit
    ) external returns (uint256 netPtOut, uint256 netSyFee);

    function removeLiquiditySingleToken(
        address receiver,
        address market,
        uint256 netLpToRemove,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) external returns (uint256 netTokenOut, uint256 netSyFee, uint256 netSyInterm);

    function removeLiquiditySingleSy(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minSyOut,
        LimitOrderData calldata limit
    ) external returns (uint256 netSyOut, uint256 netSyFee);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IPPrincipalToken.sol";
import "./IPYieldToken.sol";
import "./IStandardizedYield.sol";
import "./IPGauge.sol";
import "../core/Market/MarketMathCore.sol";

interface IPMarket is IERC20Metadata, IPGauge {
    event Mint(address indexed receiver, uint256 netLpMinted, uint256 netSyUsed, uint256 netPtUsed);

    event Burn(
        address indexed receiverSy,
        address indexed receiverPt,
        uint256 netLpBurned,
        uint256 netSyOut,
        uint256 netPtOut
    );

    event Swap(
        address indexed caller,
        address indexed receiver,
        int256 netPtOut,
        int256 netSyOut,
        uint256 netSyFee,
        uint256 netSyToReserve
    );

    event UpdateImpliedRate(uint256 indexed timestamp, uint256 lnLastImpliedRate);

    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    function mint(
        address receiver,
        uint256 netSyDesired,
        uint256 netPtDesired
    ) external returns (uint256 netLpOut, uint256 netSyUsed, uint256 netPtUsed);

    function burn(
        address receiverSy,
        address receiverPt,
        uint256 netLpToBurn
    ) external returns (uint256 netSyOut, uint256 netPtOut);

    function swapExactPtForSy(
        address receiver,
        uint256 exactPtIn,
        bytes calldata data
    ) external returns (uint256 netSyOut, uint256 netSyFee);

    function swapSyForExactPt(
        address receiver,
        uint256 exactPtOut,
        bytes calldata data
    ) external returns (uint256 netSyIn, uint256 netSyFee);

    function redeemRewards(address user) external returns (uint256[] memory);

    function readState(address router) external view returns (MarketState memory market);

    function observe(uint32[] memory secondsAgos) external view returns (uint216[] memory lnImpliedRateCumulative);

    function increaseObservationsCardinalityNext(uint16 cardinalityNext) external;

    function readTokens() external view returns (IStandardizedYield _SY, IPPrincipalToken _PT, IPYieldToken _YT);

    function getRewardTokens() external view returns (address[] memory);

    function isExpired() external view returns (bool);

    function expiry() external view returns (uint256);

    function observations(
        uint256 index
    ) external view returns (uint32 blockTimestamp, uint216 lnImpliedRateCumulative, bool initialized);

    function _storage()
        external
        view
        returns (
            int128 totalPt,
            int128 totalSy,
            uint96 lastLnImpliedRate,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext
        );
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.20;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev An uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

import {Math} from "./math/Math.sol";
import {SignedMath} from "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
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
        TransferInfo[] calldata transfers,
        address externalBalancer,
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../core/libraries/math/PMath.sol";
import "../../core/Market/MarketMathCore.sol";

struct ApproxParams {
    uint256 guessMin;
    uint256 guessMax;
    uint256 guessOffchain; // pass 0 in to skip this variable
    uint256 maxIteration; // every iteration, the diff between guessMin and guessMax will be divided by 2
    uint256 eps; // the max eps between the returned result & the correct result, base 1e18. Normally this number will be set
    // to 1e15 (1e18/1000 = 0.1%)
}

/// Further explanation of the eps. Take swapExactSyForPt for example. To calc the corresponding amount of Pt to swap out,
/// it's necessary to run an approximation algorithm, because by default there only exists the Pt to Sy formula
/// To approx, the 5 values above will have to be provided, and the approx process will run as follows:
/// mid = (guessMin + guessMax) / 2 // mid here is the current guess of the amount of Pt out
/// netSyNeed = calcSwapSyForExactPt(mid)
/// if (netSyNeed > exactSyIn) guessMax = mid - 1 // since the maximum Sy in can't exceed the exactSyIn
/// else guessMin = mid (1)
/// For the (1), since netSyNeed <= exactSyIn, the result might be usable. If the netSyNeed is within eps of
/// exactSyIn (ex eps=0.1% => we have used 99.9% the amount of Sy specified), mid will be chosen as the final guess result

/// for guessOffchain, this is to provide a shortcut to guessing. The offchain SDK can precalculate the exact result
/// before the tx is sent. When the tx reaches the contract, the guessOffchain will be checked first, and if it satisfies the
/// approximation, it will be used (and save all the guessing). It's expected that this shortcut will be used in most cases
/// except in cases that there is a trade in the same market right before the tx

library MarketApproxPtInLib {
    using MarketMathCore for MarketState;
    using PYIndexLib for PYIndex;
    using PMath for uint256;
    using PMath for int256;
    using LogExpMath for int256;

    /**
     * @dev algorithm:
     *     - Bin search the amount of PT to swap in
     *     - Try swapping & get netSyOut
     *     - Stop when netSyOut greater & approx minSyOut
     *     - guess & approx is for netPtIn
     */
    function approxSwapPtForExactSy(
        MarketState memory market,
        PYIndex index,
        uint256 minSyOut,
        uint256 blockTime,
        ApproxParams memory approx
    ) internal pure returns (uint256, /*netPtIn*/ uint256, /*netSyOut*/ uint256 /*netSyFee*/) {
        MarketPreCompute memory comp = market.getMarketPreCompute(index, blockTime);
        if (approx.guessOffchain == 0) {
            // no limit on min
            approx.guessMax = PMath.min(approx.guessMax, calcMaxPtIn(market, comp));
            validateApprox(approx);
        }

        for (uint256 iter = 0; iter < approx.maxIteration; ++iter) {
            uint256 guess = nextGuess(approx, iter);
            (uint256 netSyOut, uint256 netSyFee, ) = calcSyOut(market, comp, index, guess);

            if (netSyOut >= minSyOut) {
                if (PMath.isAGreaterApproxB(netSyOut, minSyOut, approx.eps)) {
                    return (guess, netSyOut, netSyFee);
                }
                approx.guessMax = guess;
            } else {
                approx.guessMin = guess;
            }
        }
        revert Errors.ApproxFail();
    }

    /**
     * @dev algorithm:
     *     - Bin search the amount of PT to swap in
     *     - Flashswap the corresponding amount of SY out
     *     - Pair those amount with exactSyIn SY to tokenize into PT & YT
     *     - PT to repay the flashswap, YT transferred to user
     *     - Stop when the amount of SY to be pulled to tokenize PT to repay loan approx the exactSyIn
     *     - guess & approx is for netYtOut (also netPtIn)
     */
    function approxSwapExactSyForYt(
        MarketState memory market,
        PYIndex index,
        uint256 exactSyIn,
        uint256 blockTime,
        ApproxParams memory approx
    ) internal pure returns (uint256, /*netYtOut*/ uint256 /*netSyFee*/) {
        MarketPreCompute memory comp = market.getMarketPreCompute(index, blockTime);
        if (approx.guessOffchain == 0) {
            approx.guessMin = PMath.max(approx.guessMin, index.syToAsset(exactSyIn));
            approx.guessMax = PMath.min(approx.guessMax, calcMaxPtIn(market, comp));
            validateApprox(approx);
        }

        // at minimum we will flashswap exactSyIn since we have enough SY to payback the PT loan

        for (uint256 iter = 0; iter < approx.maxIteration; ++iter) {
            uint256 guess = nextGuess(approx, iter);

            (uint256 netSyOut, uint256 netSyFee, ) = calcSyOut(market, comp, index, guess);

            uint256 netSyToTokenizePt = index.assetToSyUp(guess);

            // for sure netSyToTokenizePt >= netSyOut since we are swapping PT to SY
            uint256 netSyToPull = netSyToTokenizePt - netSyOut;

            if (netSyToPull <= exactSyIn) {
                if (PMath.isASmallerApproxB(netSyToPull, exactSyIn, approx.eps)) {
                    return (guess, netSyFee);
                }
                approx.guessMin = guess;
            } else {
                approx.guessMax = guess - 1;
            }
        }
        revert Errors.ApproxFail();
    }

    struct Args5 {
        MarketState market;
        PYIndex index;
        uint256 totalPtIn;
        uint256 netSyHolding;
        uint256 blockTime;
        ApproxParams approx;
    }

    /**
     * @dev algorithm:
     *     - Bin search the amount of PT to swap to SY
     *     - Swap PT to SY
     *     - Pair the remaining PT with the SY to add liquidity
     *     - Stop when the ratio of PT / totalPt & SY / totalSy is approx
     *     - guess & approx is for netPtSwap
     */
    function approxSwapPtToAddLiquidity(
        MarketState memory _market,
        PYIndex _index,
        uint256 _totalPtIn,
        uint256 _netSyHolding,
        uint256 _blockTime,
        ApproxParams memory approx
    ) internal pure returns (uint256, /*netPtSwap*/ uint256, /*netSyFromSwap*/ uint256 /*netSyFee*/) {
        Args5 memory a = Args5(_market, _index, _totalPtIn, _netSyHolding, _blockTime, approx);
        MarketPreCompute memory comp = a.market.getMarketPreCompute(a.index, a.blockTime);
        if (approx.guessOffchain == 0) {
            // no limit on min
            approx.guessMax = PMath.min(approx.guessMax, calcMaxPtIn(a.market, comp));
            approx.guessMax = PMath.min(approx.guessMax, a.totalPtIn);
            validateApprox(approx);
            require(a.market.totalLp != 0, "no existing lp");
        }

        for (uint256 iter = 0; iter < approx.maxIteration; ++iter) {
            uint256 guess = nextGuess(approx, iter);

            (uint256 syNumerator, uint256 ptNumerator, uint256 netSyOut, uint256 netSyFee, ) = calcNumerators(
                a.market,
                a.index,
                a.totalPtIn,
                a.netSyHolding,
                comp,
                guess
            );

            if (PMath.isAApproxB(syNumerator, ptNumerator, approx.eps)) {
                return (guess, netSyOut, netSyFee);
            }

            if (syNumerator <= ptNumerator) {
                // needs more SY --> swap more PT
                approx.guessMin = guess + 1;
            } else {
                // needs less SY --> swap less PT
                approx.guessMax = guess - 1;
            }
        }
        revert Errors.ApproxFail();
    }

    function calcNumerators(
        MarketState memory market,
        PYIndex index,
        uint256 totalPtIn,
        uint256 netSyHolding,
        MarketPreCompute memory comp,
        uint256 guess
    )
        internal
        pure
        returns (uint256 syNumerator, uint256 ptNumerator, uint256 netSyOut, uint256 netSyFee, uint256 netSyToReserve)
    {
        (netSyOut, netSyFee, netSyToReserve) = calcSyOut(market, comp, index, guess);

        uint256 newTotalPt = uint256(market.totalPt) + guess;
        uint256 newTotalSy = (uint256(market.totalSy) - netSyOut - netSyToReserve);

        // it is desired that
        // (netSyOut + netSyHolding) / newTotalSy = netPtRemaining / newTotalPt
        // which is equivalent to
        // (netSyOut + netSyHolding) * newTotalPt = netPtRemaining * newTotalSy

        syNumerator = (netSyOut + netSyHolding) * newTotalPt;
        ptNumerator = (totalPtIn - guess) * newTotalSy;
    }

    /**
     * @dev algorithm:
     *     - Bin search the amount of PT to swap to SY
     *     - Flashswap the corresponding amount of SY out
     *     - Tokenize all the SY into PT + YT
     *     - PT to repay the flashswap, YT transferred to user
     *     - Stop when the additional amount of PT to pull to repay the loan approx the exactPtIn
     *     - guess & approx is for totalPtToSwap
     */
    function approxSwapExactPtForYt(
        MarketState memory market,
        PYIndex index,
        uint256 exactPtIn,
        uint256 blockTime,
        ApproxParams memory approx
    ) internal pure returns (uint256, /*netYtOut*/ uint256, /*totalPtToSwap*/ uint256 /*netSyFee*/) {
        MarketPreCompute memory comp = market.getMarketPreCompute(index, blockTime);
        if (approx.guessOffchain == 0) {
            approx.guessMin = PMath.max(approx.guessMin, exactPtIn);
            approx.guessMax = PMath.min(approx.guessMax, calcMaxPtIn(market, comp));
            validateApprox(approx);
        }

        for (uint256 iter = 0; iter < approx.maxIteration; ++iter) {
            uint256 guess = nextGuess(approx, iter);

            (uint256 netSyOut, uint256 netSyFee, ) = calcSyOut(market, comp, index, guess);

            uint256 netAssetOut = index.syToAsset(netSyOut);

            // guess >= netAssetOut since we are swapping PT to SY
            uint256 netPtToPull = guess - netAssetOut;

            if (netPtToPull <= exactPtIn) {
                if (PMath.isASmallerApproxB(netPtToPull, exactPtIn, approx.eps)) {
                    return (netAssetOut, guess, netSyFee);
                }
                approx.guessMin = guess;
            } else {
                approx.guessMax = guess - 1;
            }
        }
        revert Errors.ApproxFail();
    }

    ////////////////////////////////////////////////////////////////////////////////

    function calcSyOut(
        MarketState memory market,
        MarketPreCompute memory comp,
        PYIndex index,
        uint256 netPtIn
    ) internal pure returns (uint256 netSyOut, uint256 netSyFee, uint256 netSyToReserve) {
        (int256 _netSyOut, int256 _netSyFee, int256 _netSyToReserve) = market.calcTrade(comp, index, -int256(netPtIn));
        netSyOut = uint256(_netSyOut);
        netSyFee = uint256(_netSyFee);
        netSyToReserve = uint256(_netSyToReserve);
    }

    function nextGuess(ApproxParams memory approx, uint256 iter) internal pure returns (uint256) {
        if (iter == 0 && approx.guessOffchain != 0) return approx.guessOffchain;
        if (approx.guessMin <= approx.guessMax) return (approx.guessMin + approx.guessMax) / 2;
        revert Errors.ApproxFail();
    }

    /// INTENDED TO BE CALLED BY WHEN GUESS.OFFCHAIN == 0 ONLY ///

    function validateApprox(ApproxParams memory approx) internal pure {
        if (approx.guessMin > approx.guessMax || approx.eps > PMath.ONE) {
            revert Errors.ApproxParamsInvalid(approx.guessMin, approx.guessMax, approx.eps);
        }
    }

    function calcMaxPtIn(MarketState memory market, MarketPreCompute memory comp) internal pure returns (uint256) {
        uint256 low = 0;
        uint256 hi = uint256(comp.totalAsset) - 1;

        while (low != hi) {
            uint256 mid = (low + hi + 1) / 2;
            if (calcSlope(comp, market.totalPt, int256(mid)) < 0) hi = mid - 1;
            else low = mid;
        }
        return low;
    }

    function calcSlope(MarketPreCompute memory comp, int256 totalPt, int256 ptToMarket) internal pure returns (int256) {
        int256 diffAssetPtToMarket = comp.totalAsset - ptToMarket;
        int256 sumPt = ptToMarket + totalPt;

        require(diffAssetPtToMarket > 0 && sumPt > 0, "invalid ptToMarket");

        int256 part1 = (ptToMarket * (totalPt + comp.totalAsset)).divDown(sumPt * diffAssetPtToMarket);

        int256 part2 = sumPt.divDown(diffAssetPtToMarket).ln();
        int256 part3 = PMath.IONE.divDown(comp.rateScalar);

        return comp.rateAnchor - (part1 - part2).mulDown(part3);
    }
}

library MarketApproxPtOutLib {
    using MarketMathCore for MarketState;
    using PYIndexLib for PYIndex;
    using PMath for uint256;
    using PMath for int256;
    using LogExpMath for int256;

    /**
     * @dev algorithm:
     *     - Bin search the amount of PT to swapExactOut
     *     - Calculate the amount of SY needed
     *     - Stop when the netSyIn is smaller approx exactSyIn
     *     - guess & approx is for netSyIn
     */
    function approxSwapExactSyForPt(
        MarketState memory market,
        PYIndex index,
        uint256 exactSyIn,
        uint256 blockTime,
        ApproxParams memory approx
    ) internal pure returns (uint256, /*netPtOut*/ uint256 /*netSyFee*/) {
        MarketPreCompute memory comp = market.getMarketPreCompute(index, blockTime);
        if (approx.guessOffchain == 0) {
            // no limit on min
            approx.guessMax = PMath.min(approx.guessMax, calcMaxPtOut(comp, market.totalPt));
            validateApprox(approx);
        }

        for (uint256 iter = 0; iter < approx.maxIteration; ++iter) {
            uint256 guess = nextGuess(approx, iter);

            (uint256 netSyIn, uint256 netSyFee, ) = calcSyIn(market, comp, index, guess);

            if (netSyIn <= exactSyIn) {
                if (PMath.isASmallerApproxB(netSyIn, exactSyIn, approx.eps)) {
                    return (guess, netSyFee);
                }
                approx.guessMin = guess;
            } else {
                approx.guessMax = guess - 1;
            }
        }

        revert Errors.ApproxFail();
    }

    /**
     * @dev algorithm:
     *     - Bin search the amount of PT to swapExactOut
     *     - Flashswap that amount of PT & pair with YT to redeem SY
     *     - Use the SY to repay the flashswap debt and the remaining is transferred to user
     *     - Stop when the netSyOut is greater approx the minSyOut
     *     - guess & approx is for netSyOut
     */
    function approxSwapYtForExactSy(
        MarketState memory market,
        PYIndex index,
        uint256 minSyOut,
        uint256 blockTime,
        ApproxParams memory approx
    ) internal pure returns (uint256, /*netYtIn*/ uint256, /*netSyOut*/ uint256 /*netSyFee*/) {
        MarketPreCompute memory comp = market.getMarketPreCompute(index, blockTime);
        if (approx.guessOffchain == 0) {
            // no limit on min
            approx.guessMax = PMath.min(approx.guessMax, calcMaxPtOut(comp, market.totalPt));
            validateApprox(approx);
        }

        for (uint256 iter = 0; iter < approx.maxIteration; ++iter) {
            uint256 guess = nextGuess(approx, iter);

            (uint256 netSyOwed, uint256 netSyFee, ) = calcSyIn(market, comp, index, guess);

            uint256 netAssetToRepay = index.syToAssetUp(netSyOwed);
            uint256 netSyOut = index.assetToSy(guess - netAssetToRepay);

            if (netSyOut >= minSyOut) {
                if (PMath.isAGreaterApproxB(netSyOut, minSyOut, approx.eps)) {
                    return (guess, netSyOut, netSyFee);
                }
                approx.guessMax = guess;
            } else {
                approx.guessMin = guess + 1;
            }
        }
        revert Errors.ApproxFail();
    }

    struct Args6 {
        MarketState market;
        PYIndex index;
        uint256 totalSyIn;
        uint256 netPtHolding;
        uint256 blockTime;
        ApproxParams approx;
    }

    /**
     * @dev algorithm:
     *     - Bin search the amount of PT to swapExactOut
     *     - Swap that amount of PT out
     *     - Pair the remaining PT with the SY to add liquidity
     *     - Stop when the ratio of PT / totalPt & SY / totalSy is approx
     *     - guess & approx is for netPtFromSwap
     */
    function approxSwapSyToAddLiquidity(
        MarketState memory _market,
        PYIndex _index,
        uint256 _totalSyIn,
        uint256 _netPtHolding,
        uint256 _blockTime,
        ApproxParams memory _approx
    ) internal pure returns (uint256, /*netPtFromSwap*/ uint256, /*netSySwap*/ uint256 /*netSyFee*/) {
        Args6 memory a = Args6(_market, _index, _totalSyIn, _netPtHolding, _blockTime, _approx);

        MarketPreCompute memory comp = a.market.getMarketPreCompute(a.index, a.blockTime);
        if (a.approx.guessOffchain == 0) {
            // no limit on min
            a.approx.guessMax = PMath.min(a.approx.guessMax, calcMaxPtOut(comp, a.market.totalPt));
            validateApprox(a.approx);
            require(a.market.totalLp != 0, "no existing lp");
        }

        for (uint256 iter = 0; iter < a.approx.maxIteration; ++iter) {
            uint256 guess = nextGuess(a.approx, iter);

            (uint256 netSyIn, uint256 netSyFee, uint256 netSyToReserve) = calcSyIn(a.market, comp, a.index, guess);

            if (netSyIn > a.totalSyIn) {
                a.approx.guessMax = guess - 1;
                continue;
            }

            uint256 syNumerator;
            uint256 ptNumerator;

            {
                uint256 newTotalPt = uint256(a.market.totalPt) - guess;
                uint256 netTotalSy = uint256(a.market.totalSy) + netSyIn - netSyToReserve;

                // it is desired that
                // (netPtFromSwap + netPtHolding) / newTotalPt = netSyRemaining / netTotalSy
                // which is equivalent to
                // (netPtFromSwap + netPtHolding) * netTotalSy = netSyRemaining * newTotalPt

                ptNumerator = (guess + a.netPtHolding) * netTotalSy;
                syNumerator = (a.totalSyIn - netSyIn) * newTotalPt;
            }

            if (PMath.isAApproxB(ptNumerator, syNumerator, a.approx.eps)) {
                return (guess, netSyIn, netSyFee);
            }

            if (ptNumerator <= syNumerator) {
                // needs more PT
                a.approx.guessMin = guess + 1;
            } else {
                // needs less PT
                a.approx.guessMax = guess - 1;
            }
        }
        revert Errors.ApproxFail();
    }

    /**
     * @dev algorithm:
     *     - Bin search the amount of PT to swapExactOut
     *     - Flashswap that amount of PT out
     *     - Pair all the PT with the YT to redeem SY
     *     - Use the SY to repay the flashswap debt
     *     - Stop when the amount of YT required to pair with PT is approx exactYtIn
     *     - guess & approx is for netPtFromSwap
     */
    function approxSwapExactYtForPt(
        MarketState memory market,
        PYIndex index,
        uint256 exactYtIn,
        uint256 blockTime,
        ApproxParams memory approx
    ) internal pure returns (uint256, /*netPtOut*/ uint256, /*totalPtSwapped*/ uint256 /*netSyFee*/) {
        MarketPreCompute memory comp = market.getMarketPreCompute(index, blockTime);
        if (approx.guessOffchain == 0) {
            approx.guessMin = PMath.max(approx.guessMin, exactYtIn);
            approx.guessMax = PMath.min(approx.guessMax, calcMaxPtOut(comp, market.totalPt));
            validateApprox(approx);
        }

        for (uint256 iter = 0; iter < approx.maxIteration; ++iter) {
            uint256 guess = nextGuess(approx, iter);

            (uint256 netSyOwed, uint256 netSyFee, ) = calcSyIn(market, comp, index, guess);

            uint256 netYtToPull = index.syToAssetUp(netSyOwed);

            if (netYtToPull <= exactYtIn) {
                if (PMath.isASmallerApproxB(netYtToPull, exactYtIn, approx.eps)) {
                    return (guess - netYtToPull, guess, netSyFee);
                }
                approx.guessMin = guess;
            } else {
                approx.guessMax = guess - 1;
            }
        }
        revert Errors.ApproxFail();
    }

    ////////////////////////////////////////////////////////////////////////////////

    function calcSyIn(
        MarketState memory market,
        MarketPreCompute memory comp,
        PYIndex index,
        uint256 netPtOut
    ) internal pure returns (uint256 netSyIn, uint256 netSyFee, uint256 netSyToReserve) {
        (int256 _netSyIn, int256 _netSyFee, int256 _netSyToReserve) = market.calcTrade(comp, index, int256(netPtOut));

        // all safe since totalPt and totalSy is int128
        netSyIn = uint256(-_netSyIn);
        netSyFee = uint256(_netSyFee);
        netSyToReserve = uint256(_netSyToReserve);
    }

    function calcMaxPtOut(MarketPreCompute memory comp, int256 totalPt) internal pure returns (uint256) {
        int256 logitP = (comp.feeRate - comp.rateAnchor).mulDown(comp.rateScalar).exp();
        int256 proportion = logitP.divDown(logitP + PMath.IONE);
        int256 numerator = proportion.mulDown(totalPt + comp.totalAsset);
        int256 maxPtOut = totalPt - numerator;
        // only get 99.9% of the theoretical max to accommodate some precision issues
        return (uint256(maxPtOut) * 999) / 1000;
    }

    function nextGuess(ApproxParams memory approx, uint256 iter) internal pure returns (uint256) {
        if (iter == 0 && approx.guessOffchain != 0) return approx.guessOffchain;
        if (approx.guessMin <= approx.guessMax) return (approx.guessMin + approx.guessMax) / 2;
        revert Errors.ApproxFail();
    }

    function validateApprox(ApproxParams memory approx) internal pure {
        if (approx.guessMin > approx.guessMax || approx.eps > PMath.ONE) {
            revert Errors.ApproxParamsInvalid(approx.guessMin, approx.guessMax, approx.eps);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../router/swap-aggregator/IPSwapAggregator.sol";
import "./IPLimitRouter.sol";

struct TokenInput {
    // Token/Sy data
    address tokenIn;
    uint256 netTokenIn;
    address tokenMintSy;
    // aggregator data
    address pendleSwap;
    SwapData swapData;
}

struct TokenOutput {
    // Token/Sy data
    address tokenOut;
    uint256 minTokenOut;
    address tokenRedeemSy;
    // aggregator data
    address pendleSwap;
    SwapData swapData;
}

struct LimitOrderData {
    address limitRouter;
    uint256 epsSkipMarket; // only used for swap operations, will be ignored otherwise
    FillOrderParams[] normalFills;
    FillOrderParams[] flashFills;
    bytes optData;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IPPrincipalToken is IERC20Metadata {
    function burnByYT(address user, uint256 amount) external;

    function mintByYT(address user, uint256 amount) external;

    function initialize(address _YT) external;

    function SY() external view returns (address);

    function YT() external view returns (address);

    function factory() external view returns (address);

    function expiry() external view returns (uint256);

    function isExpired() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IRewardManager.sol";
import "./IPInterestManagerYT.sol";

interface IPYieldToken is IERC20Metadata, IRewardManager, IPInterestManagerYT {
    event NewInterestIndex(uint256 indexed newIndex);

    event Mint(
        address indexed caller,
        address indexed receiverPT,
        address indexed receiverYT,
        uint256 amountSyToMint,
        uint256 amountPYOut
    );

    event Burn(address indexed caller, address indexed receiver, uint256 amountPYToRedeem, uint256 amountSyOut);

    event RedeemRewards(address indexed user, uint256[] amountRewardsOut);

    event RedeemInterest(address indexed user, uint256 interestOut);

    event CollectRewardFee(address indexed rewardToken, uint256 amountRewardFee);

    function mintPY(address receiverPT, address receiverYT) external returns (uint256 amountPYOut);

    function redeemPY(address receiver) external returns (uint256 amountSyOut);

    function redeemPYMulti(
        address[] calldata receivers,
        uint256[] calldata amountPYToRedeems
    ) external returns (uint256[] memory amountSyOuts);

    function redeemDueInterestAndRewards(
        address user,
        bool redeemInterest,
        bool redeemRewards
    ) external returns (uint256 interestOut, uint256[] memory rewardsOut);

    function rewardIndexesCurrent() external returns (uint256[] memory);

    function pyIndexCurrent() external returns (uint256);

    function pyIndexStored() external view returns (uint256);

    function getRewardTokens() external view returns (address[] memory);

    function SY() external view returns (address);

    function PT() external view returns (address);

    function factory() external view returns (address);

    function expiry() external view returns (uint256);

    function isExpired() external view returns (bool);

    function doCacheIndexSameBlock() external view returns (bool);

    function pyIndexLastUpdatedBlock() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IStandardizedYield is IERC20Metadata {
    /// @dev Emitted when any base tokens is deposited to mint shares
    event Deposit(
        address indexed caller,
        address indexed receiver,
        address indexed tokenIn,
        uint256 amountDeposited,
        uint256 amountSyOut
    );

    /// @dev Emitted when any shares are redeemed for base tokens
    event Redeem(
        address indexed caller,
        address indexed receiver,
        address indexed tokenOut,
        uint256 amountSyToRedeem,
        uint256 amountTokenOut
    );

    /// @dev check `assetInfo()` for more information
    enum AssetType {
        TOKEN,
        LIQUIDITY
    }

    /// @dev Emitted when (`user`) claims their rewards
    event ClaimRewards(address indexed user, address[] rewardTokens, uint256[] rewardAmounts);

    /**
     * @notice mints an amount of shares by depositing a base token.
     * @param receiver shares recipient address
     * @param tokenIn address of the base tokens to mint shares
     * @param amountTokenToDeposit amount of base tokens to be transferred from (`msg.sender`)
     * @param minSharesOut reverts if amount of shares minted is lower than this
     * @return amountSharesOut amount of shares minted
     * @dev Emits a {Deposit} event
     *
     * Requirements:
     * - (`tokenIn`) must be a valid base token.
     */
    function deposit(
        address receiver,
        address tokenIn,
        uint256 amountTokenToDeposit,
        uint256 minSharesOut
    ) external payable returns (uint256 amountSharesOut);

    /**
     * @notice redeems an amount of base tokens by burning some shares
     * @param receiver recipient address
     * @param amountSharesToRedeem amount of shares to be burned
     * @param tokenOut address of the base token to be redeemed
     * @param minTokenOut reverts if amount of base token redeemed is lower than this
     * @param burnFromInternalBalance if true, burns from balance of `address(this)`, otherwise burns from `msg.sender`
     * @return amountTokenOut amount of base tokens redeemed
     * @dev Emits a {Redeem} event
     *
     * Requirements:
     * - (`tokenOut`) must be a valid base token.
     */
    function redeem(
        address receiver,
        uint256 amountSharesToRedeem,
        address tokenOut,
        uint256 minTokenOut,
        bool burnFromInternalBalance
    ) external returns (uint256 amountTokenOut);

    /**
     * @notice exchangeRate * syBalance / 1e18 must return the asset balance of the account
     * @notice vice-versa, if a user uses some amount of tokens equivalent to X asset, the amount of sy
     he can mint must be X * exchangeRate / 1e18
     * @dev SYUtils's assetToSy & syToAsset should be used instead of raw multiplication
     & division
     */
    function exchangeRate() external view returns (uint256 res);

    /**
     * @notice claims reward for (`user`)
     * @param user the user receiving their rewards
     * @return rewardAmounts an array of reward amounts in the same order as `getRewardTokens`
     * @dev
     * Emits a `ClaimRewards` event
     * See {getRewardTokens} for list of reward tokens
     */
    function claimRewards(address user) external returns (uint256[] memory rewardAmounts);

    /**
     * @notice get the amount of unclaimed rewards for (`user`)
     * @param user the user to check for
     * @return rewardAmounts an array of reward amounts in the same order as `getRewardTokens`
     */
    function accruedRewards(address user) external view returns (uint256[] memory rewardAmounts);

    function rewardIndexesCurrent() external returns (uint256[] memory indexes);

    function rewardIndexesStored() external view returns (uint256[] memory indexes);

    /**
     * @notice returns the list of reward token addresses
     */
    function getRewardTokens() external view returns (address[] memory);

    /**
     * @notice returns the address of the underlying yield token
     */
    function yieldToken() external view returns (address);

    /**
     * @notice returns all tokens that can mint this SY
     */
    function getTokensIn() external view returns (address[] memory res);

    /**
     * @notice returns all tokens that can be redeemed by this SY
     */
    function getTokensOut() external view returns (address[] memory res);

    function isValidTokenIn(address token) external view returns (bool);

    function isValidTokenOut(address token) external view returns (bool);

    function previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) external view returns (uint256 amountSharesOut);

    function previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) external view returns (uint256 amountTokenOut);

    /**
     * @notice This function contains information to interpret what the asset is
     * @return assetType the type of the asset (0 for ERC20 tokens, 1 for AMM liquidity tokens,
        2 for bridged yield bearing tokens like wstETH, rETH on Arbi whose the underlying asset doesn't exist on the chain)
     * @return assetAddress the address of the asset
     * @return assetDecimals the decimals of the asset
     */
    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IPGauge {
    function totalActiveSupply() external view returns (uint256);

    function activeBalance(address user) external view returns (uint256);

    // only available for newer factories. please check the verified contracts
    event RedeemRewards(address indexed user, uint256[] rewardsOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../libraries/math/PMath.sol";
import "../libraries/math/LogExpMath.sol";

import "../StandardizedYield/PYIndex.sol";
import "../libraries/MiniHelpers.sol";
import "../libraries/Errors.sol";

struct MarketState {
    int256 totalPt;
    int256 totalSy;
    int256 totalLp;
    address treasury;
    /// immutable variables ///
    int256 scalarRoot;
    uint256 expiry;
    /// fee data ///
    uint256 lnFeeRateRoot;
    uint256 reserveFeePercent; // base 100
    /// last trade data ///
    uint256 lastLnImpliedRate;
}

// params that are expensive to compute, therefore we pre-compute them
struct MarketPreCompute {
    int256 rateScalar;
    int256 totalAsset;
    int256 rateAnchor;
    int256 feeRate;
}

// solhint-disable ordering
library MarketMathCore {
    using PMath for uint256;
    using PMath for int256;
    using LogExpMath for int256;
    using PYIndexLib for PYIndex;

    int256 internal constant MINIMUM_LIQUIDITY = 10 ** 3;
    int256 internal constant PERCENTAGE_DECIMALS = 100;
    uint256 internal constant DAY = 86400;
    uint256 internal constant IMPLIED_RATE_TIME = 365 * DAY;

    int256 internal constant MAX_MARKET_PROPORTION = (1e18 * 96) / 100;

    using PMath for uint256;
    using PMath for int256;

    /*///////////////////////////////////////////////////////////////
                UINT FUNCTIONS TO PROXY TO CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function addLiquidity(
        MarketState memory market,
        uint256 syDesired,
        uint256 ptDesired,
        uint256 blockTime
    ) internal pure returns (uint256 lpToReserve, uint256 lpToAccount, uint256 syUsed, uint256 ptUsed) {
        (int256 _lpToReserve, int256 _lpToAccount, int256 _syUsed, int256 _ptUsed) = addLiquidityCore(
            market,
            syDesired.Int(),
            ptDesired.Int(),
            blockTime
        );

        lpToReserve = _lpToReserve.Uint();
        lpToAccount = _lpToAccount.Uint();
        syUsed = _syUsed.Uint();
        ptUsed = _ptUsed.Uint();
    }

    function removeLiquidity(
        MarketState memory market,
        uint256 lpToRemove
    ) internal pure returns (uint256 netSyToAccount, uint256 netPtToAccount) {
        (int256 _syToAccount, int256 _ptToAccount) = removeLiquidityCore(market, lpToRemove.Int());

        netSyToAccount = _syToAccount.Uint();
        netPtToAccount = _ptToAccount.Uint();
    }

    function swapExactPtForSy(
        MarketState memory market,
        PYIndex index,
        uint256 exactPtToMarket,
        uint256 blockTime
    ) internal pure returns (uint256 netSyToAccount, uint256 netSyFee, uint256 netSyToReserve) {
        (int256 _netSyToAccount, int256 _netSyFee, int256 _netSyToReserve) = executeTradeCore(
            market,
            index,
            exactPtToMarket.neg(),
            blockTime
        );

        netSyToAccount = _netSyToAccount.Uint();
        netSyFee = _netSyFee.Uint();
        netSyToReserve = _netSyToReserve.Uint();
    }

    function swapSyForExactPt(
        MarketState memory market,
        PYIndex index,
        uint256 exactPtToAccount,
        uint256 blockTime
    ) internal pure returns (uint256 netSyToMarket, uint256 netSyFee, uint256 netSyToReserve) {
        (int256 _netSyToAccount, int256 _netSyFee, int256 _netSyToReserve) = executeTradeCore(
            market,
            index,
            exactPtToAccount.Int(),
            blockTime
        );

        netSyToMarket = _netSyToAccount.neg().Uint();
        netSyFee = _netSyFee.Uint();
        netSyToReserve = _netSyToReserve.Uint();
    }

    /*///////////////////////////////////////////////////////////////
                    CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function addLiquidityCore(
        MarketState memory market,
        int256 syDesired,
        int256 ptDesired,
        uint256 blockTime
    ) internal pure returns (int256 lpToReserve, int256 lpToAccount, int256 syUsed, int256 ptUsed) {
        /// ------------------------------------------------------------
        /// CHECKS
        /// ------------------------------------------------------------
        if (syDesired == 0 || ptDesired == 0) revert Errors.MarketZeroAmountsInput();
        if (MiniHelpers.isExpired(market.expiry, blockTime)) revert Errors.MarketExpired();

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------
        if (market.totalLp == 0) {
            lpToAccount = PMath.sqrt((syDesired * ptDesired).Uint()).Int() - MINIMUM_LIQUIDITY;
            lpToReserve = MINIMUM_LIQUIDITY;
            syUsed = syDesired;
            ptUsed = ptDesired;
        } else {
            int256 netLpByPt = (ptDesired * market.totalLp) / market.totalPt;
            int256 netLpBySy = (syDesired * market.totalLp) / market.totalSy;
            if (netLpByPt < netLpBySy) {
                lpToAccount = netLpByPt;
                ptUsed = ptDesired;
                syUsed = (market.totalSy * lpToAccount) / market.totalLp;
            } else {
                lpToAccount = netLpBySy;
                syUsed = syDesired;
                ptUsed = (market.totalPt * lpToAccount) / market.totalLp;
            }
        }

        if (lpToAccount <= 0) revert Errors.MarketZeroAmountsOutput();

        /// ------------------------------------------------------------
        /// WRITE
        /// ------------------------------------------------------------
        market.totalSy += syUsed;
        market.totalPt += ptUsed;
        market.totalLp += lpToAccount + lpToReserve;
    }

    function removeLiquidityCore(
        MarketState memory market,
        int256 lpToRemove
    ) internal pure returns (int256 netSyToAccount, int256 netPtToAccount) {
        /// ------------------------------------------------------------
        /// CHECKS
        /// ------------------------------------------------------------
        if (lpToRemove == 0) revert Errors.MarketZeroAmountsInput();

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------
        netSyToAccount = (lpToRemove * market.totalSy) / market.totalLp;
        netPtToAccount = (lpToRemove * market.totalPt) / market.totalLp;

        if (netSyToAccount == 0 && netPtToAccount == 0) revert Errors.MarketZeroAmountsOutput();

        /// ------------------------------------------------------------
        /// WRITE
        /// ------------------------------------------------------------
        market.totalLp = market.totalLp.subNoNeg(lpToRemove);
        market.totalPt = market.totalPt.subNoNeg(netPtToAccount);
        market.totalSy = market.totalSy.subNoNeg(netSyToAccount);
    }

    function executeTradeCore(
        MarketState memory market,
        PYIndex index,
        int256 netPtToAccount,
        uint256 blockTime
    ) internal pure returns (int256 netSyToAccount, int256 netSyFee, int256 netSyToReserve) {
        /// ------------------------------------------------------------
        /// CHECKS
        /// ------------------------------------------------------------
        if (MiniHelpers.isExpired(market.expiry, blockTime)) revert Errors.MarketExpired();
        if (market.totalPt <= netPtToAccount)
            revert Errors.MarketInsufficientPtForTrade(market.totalPt, netPtToAccount);

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------
        MarketPreCompute memory comp = getMarketPreCompute(market, index, blockTime);

        (netSyToAccount, netSyFee, netSyToReserve) = calcTrade(market, comp, index, netPtToAccount);

        /// ------------------------------------------------------------
        /// WRITE
        /// ------------------------------------------------------------
        _setNewMarketStateTrade(market, comp, index, netPtToAccount, netSyToAccount, netSyToReserve, blockTime);
    }

    function getMarketPreCompute(
        MarketState memory market,
        PYIndex index,
        uint256 blockTime
    ) internal pure returns (MarketPreCompute memory res) {
        if (MiniHelpers.isExpired(market.expiry, blockTime)) revert Errors.MarketExpired();

        uint256 timeToExpiry = market.expiry - blockTime;

        res.rateScalar = _getRateScalar(market, timeToExpiry);
        res.totalAsset = index.syToAsset(market.totalSy);

        if (market.totalPt == 0 || res.totalAsset == 0)
            revert Errors.MarketZeroTotalPtOrTotalAsset(market.totalPt, res.totalAsset);

        res.rateAnchor = _getRateAnchor(
            market.totalPt,
            market.lastLnImpliedRate,
            res.totalAsset,
            res.rateScalar,
            timeToExpiry
        );
        res.feeRate = _getExchangeRateFromImpliedRate(market.lnFeeRateRoot, timeToExpiry);
    }

    function calcTrade(
        MarketState memory market,
        MarketPreCompute memory comp,
        PYIndex index,
        int256 netPtToAccount
    ) internal pure returns (int256 netSyToAccount, int256 netSyFee, int256 netSyToReserve) {
        int256 preFeeExchangeRate = _getExchangeRate(
            market.totalPt,
            comp.totalAsset,
            comp.rateScalar,
            comp.rateAnchor,
            netPtToAccount
        );

        int256 preFeeAssetToAccount = netPtToAccount.divDown(preFeeExchangeRate).neg();
        int256 fee = comp.feeRate;

        if (netPtToAccount > 0) {
            int256 postFeeExchangeRate = preFeeExchangeRate.divDown(fee);
            if (postFeeExchangeRate < PMath.IONE) revert Errors.MarketExchangeRateBelowOne(postFeeExchangeRate);

            fee = preFeeAssetToAccount.mulDown(PMath.IONE - fee);
        } else {
            fee = ((preFeeAssetToAccount * (PMath.IONE - fee)) / fee).neg();
        }

        int256 netAssetToReserve = (fee * market.reserveFeePercent.Int()) / PERCENTAGE_DECIMALS;
        int256 netAssetToAccount = preFeeAssetToAccount - fee;

        netSyToAccount = netAssetToAccount < 0
            ? index.assetToSyUp(netAssetToAccount)
            : index.assetToSy(netAssetToAccount);
        netSyFee = index.assetToSy(fee);
        netSyToReserve = index.assetToSy(netAssetToReserve);
    }

    function _setNewMarketStateTrade(
        MarketState memory market,
        MarketPreCompute memory comp,
        PYIndex index,
        int256 netPtToAccount,
        int256 netSyToAccount,
        int256 netSyToReserve,
        uint256 blockTime
    ) internal pure {
        uint256 timeToExpiry = market.expiry - blockTime;

        market.totalPt = market.totalPt.subNoNeg(netPtToAccount);
        market.totalSy = market.totalSy.subNoNeg(netSyToAccount + netSyToReserve);

        market.lastLnImpliedRate = _getLnImpliedRate(
            market.totalPt,
            index.syToAsset(market.totalSy),
            comp.rateScalar,
            comp.rateAnchor,
            timeToExpiry
        );

        if (market.lastLnImpliedRate == 0) revert Errors.MarketZeroLnImpliedRate();
    }

    function _getRateAnchor(
        int256 totalPt,
        uint256 lastLnImpliedRate,
        int256 totalAsset,
        int256 rateScalar,
        uint256 timeToExpiry
    ) internal pure returns (int256 rateAnchor) {
        int256 newExchangeRate = _getExchangeRateFromImpliedRate(lastLnImpliedRate, timeToExpiry);

        if (newExchangeRate < PMath.IONE) revert Errors.MarketExchangeRateBelowOne(newExchangeRate);

        {
            int256 proportion = totalPt.divDown(totalPt + totalAsset);

            int256 lnProportion = _logProportion(proportion);

            rateAnchor = newExchangeRate - lnProportion.divDown(rateScalar);
        }
    }

    /// @notice Calculates the current market implied rate.
    /// @return lnImpliedRate the implied rate
    function _getLnImpliedRate(
        int256 totalPt,
        int256 totalAsset,
        int256 rateScalar,
        int256 rateAnchor,
        uint256 timeToExpiry
    ) internal pure returns (uint256 lnImpliedRate) {
        // This will check for exchange rates < PMath.IONE
        int256 exchangeRate = _getExchangeRate(totalPt, totalAsset, rateScalar, rateAnchor, 0);

        // exchangeRate >= 1 so its ln >= 0
        uint256 lnRate = exchangeRate.ln().Uint();

        lnImpliedRate = (lnRate * IMPLIED_RATE_TIME) / timeToExpiry;
    }

    /// @notice Converts an implied rate to an exchange rate given a time to expiry. The
    /// formula is E = e^rt
    function _getExchangeRateFromImpliedRate(
        uint256 lnImpliedRate,
        uint256 timeToExpiry
    ) internal pure returns (int256 exchangeRate) {
        uint256 rt = (lnImpliedRate * timeToExpiry) / IMPLIED_RATE_TIME;

        exchangeRate = LogExpMath.exp(rt.Int());
    }

    function _getExchangeRate(
        int256 totalPt,
        int256 totalAsset,
        int256 rateScalar,
        int256 rateAnchor,
        int256 netPtToAccount
    ) internal pure returns (int256 exchangeRate) {
        int256 numerator = totalPt.subNoNeg(netPtToAccount);

        int256 proportion = (numerator.divDown(totalPt + totalAsset));

        if (proportion > MAX_MARKET_PROPORTION)
            revert Errors.MarketProportionTooHigh(proportion, MAX_MARKET_PROPORTION);

        int256 lnProportion = _logProportion(proportion);

        exchangeRate = lnProportion.divDown(rateScalar) + rateAnchor;

        if (exchangeRate < PMath.IONE) revert Errors.MarketExchangeRateBelowOne(exchangeRate);
    }

    function _logProportion(int256 proportion) internal pure returns (int256 res) {
        if (proportion == PMath.IONE) revert Errors.MarketProportionMustNotEqualOne();

        int256 logitP = proportion.divDown(PMath.IONE - proportion);

        res = logitP.ln();
    }

    function _getRateScalar(MarketState memory market, uint256 timeToExpiry) internal pure returns (int256 rateScalar) {
        rateScalar = (market.scalarRoot * IMPLIED_RATE_TIME.Int()) / timeToExpiry.Int();
        if (rateScalar <= 0) revert Errors.MarketRateScalarBelowZero(rateScalar);
    }

    function setInitialLnImpliedRate(
        MarketState memory market,
        PYIndex index,
        int256 initialAnchor,
        uint256 blockTime
    ) internal pure {
        /// ------------------------------------------------------------
        /// CHECKS
        /// ------------------------------------------------------------
        if (MiniHelpers.isExpired(market.expiry, blockTime)) revert Errors.MarketExpired();

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------
        int256 totalAsset = index.syToAsset(market.totalSy);
        uint256 timeToExpiry = market.expiry - blockTime;
        int256 rateScalar = _getRateScalar(market, timeToExpiry);

        /// ------------------------------------------------------------
        /// WRITE
        /// ------------------------------------------------------------
        market.lastLnImpliedRate = _getLnImpliedRate(
            market.totalPt,
            totalAsset,
            rateScalar,
            initialAnchor,
            timeToExpiry
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

/* solhint-disable private-vars-leading-underscore, reason-string */

library PMath {
    uint256 internal constant ONE = 1e18; // 18 decimal places
    int256 internal constant IONE = 1e18; // 18 decimal places

    function subMax0(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return (a >= b ? a - b : 0);
        }
    }

    function subNoNeg(int256 a, int256 b) internal pure returns (int256) {
        require(a >= b, "negative");
        return a - b; // no unchecked since if b is very negative, a - b might overflow
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        unchecked {
            return product / ONE;
        }
    }

    function mulDown(int256 a, int256 b) internal pure returns (int256) {
        int256 product = a * b;
        unchecked {
            return product / IONE;
        }
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 aInflated = a * ONE;
        unchecked {
            return aInflated / b;
        }
    }

    function divDown(int256 a, int256 b) internal pure returns (int256) {
        int256 aInflated = a * IONE;
        unchecked {
            return aInflated / b;
        }
    }

    function rawDivUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }

    // @author Uniswap
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function square(uint256 x) internal pure returns (uint256) {
        return x * x;
    }

    function squareDown(uint256 x) internal pure returns (uint256) {
        return mulDown(x, x);
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x > 0 ? x : -x);
    }

    function neg(int256 x) internal pure returns (int256) {
        return x * (-1);
    }

    function neg(uint256 x) internal pure returns (int256) {
        return Int(x) * (-1);
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x > y ? x : y);
    }

    function max(int256 x, int256 y) internal pure returns (int256) {
        return (x > y ? x : y);
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x < y ? x : y);
    }

    function min(int256 x, int256 y) internal pure returns (int256) {
        return (x < y ? x : y);
    }

    /*///////////////////////////////////////////////////////////////
                               SIGNED CASTS
    //////////////////////////////////////////////////////////////*/

    function Int(uint256 x) internal pure returns (int256) {
        require(x <= uint256(type(int256).max));
        return int256(x);
    }

    function Int128(int256 x) internal pure returns (int128) {
        require(type(int128).min <= x && x <= type(int128).max);
        return int128(x);
    }

    function Int128(uint256 x) internal pure returns (int128) {
        return Int128(Int(x));
    }

    /*///////////////////////////////////////////////////////////////
                               UNSIGNED CASTS
    //////////////////////////////////////////////////////////////*/

    function Uint(int256 x) internal pure returns (uint256) {
        require(x >= 0);
        return uint256(x);
    }

    function Uint32(uint256 x) internal pure returns (uint32) {
        require(x <= type(uint32).max);
        return uint32(x);
    }

    function Uint64(uint256 x) internal pure returns (uint64) {
        require(x <= type(uint64).max);
        return uint64(x);
    }

    function Uint112(uint256 x) internal pure returns (uint112) {
        require(x <= type(uint112).max);
        return uint112(x);
    }

    function Uint96(uint256 x) internal pure returns (uint96) {
        require(x <= type(uint96).max);
        return uint96(x);
    }

    function Uint128(uint256 x) internal pure returns (uint128) {
        require(x <= type(uint128).max);
        return uint128(x);
    }

    function Uint192(uint256 x) internal pure returns (uint192) {
        require(x <= type(uint192).max);
        return uint192(x);
    }

    function isAApproxB(uint256 a, uint256 b, uint256 eps) internal pure returns (bool) {
        return mulDown(b, ONE - eps) <= a && a <= mulDown(b, ONE + eps);
    }

    function isAGreaterApproxB(uint256 a, uint256 b, uint256 eps) internal pure returns (bool) {
        return a >= b && a <= mulDown(b, ONE + eps);
    }

    function isASmallerApproxB(uint256 a, uint256 b, uint256 eps) internal pure returns (bool) {
        return a <= b && a >= mulDown(b, ONE - eps);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

struct SwapData {
    SwapType swapType;
    address extRouter;
    bytes extCalldata;
    bool needScale;
}

enum SwapType {
    NONE,
    KYBERSWAP,
    ONE_INCH,
    // ETH_WETH not used in Aggregator
    ETH_WETH
}

interface IPSwapAggregator {
    function swap(address tokenIn, uint256 amountIn, SwapData calldata swapData) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../core/StandardizedYield/PYIndex.sol";

interface IPLimitOrderType {
    enum OrderType {
        SY_FOR_PT,
        PT_FOR_SY,
        SY_FOR_YT,
        YT_FOR_SY
    }

    // Fixed-size order part with core information
    struct StaticOrder {
        uint256 salt;
        uint256 expiry;
        uint256 nonce;
        OrderType orderType;
        address token;
        address YT;
        address maker;
        address receiver;
        uint256 makingAmount;
        uint256 lnImpliedRate;
        uint256 failSafeRate;
    }

    struct FillResults {
        uint256 totalMaking;
        uint256 totalTaking;
        uint256 totalFee;
        uint256 totalNotionalVolume;
        uint256[] netMakings;
        uint256[] netTakings;
        uint256[] netFees;
        uint256[] notionalVolumes;
    }
}

struct Order {
    uint256 salt;
    uint256 expiry;
    uint256 nonce;
    IPLimitOrderType.OrderType orderType;
    address token;
    address YT;
    address maker;
    address receiver;
    uint256 makingAmount;
    uint256 lnImpliedRate;
    uint256 failSafeRate;
    bytes permit;
}

struct FillOrderParams {
    Order order;
    bytes signature;
    uint256 makingAmount;
}

interface IPLimitRouterCallback is IPLimitOrderType {
    function limitRouterCallback(
        uint256 actualMaking,
        uint256 actualTaking,
        uint256 totalFee,
        bytes memory data
    ) external returns (bytes memory);
}

interface IPLimitRouter is IPLimitOrderType {
    struct OrderStatus {
        uint128 filledAmount;
        uint128 remaining;
    }

    event OrderCanceled(address indexed maker, bytes32 indexed orderHash);

    event OrderFilledV2(
        bytes32 indexed orderHash,
        OrderType indexed orderType,
        address indexed YT,
        address token,
        uint256 netInputFromMaker,
        uint256 netOutputToMaker,
        uint256 feeAmount,
        uint256 notionalVolume,
        address maker,
        address taker
    );

    // @dev actualMaking, actualTaking are in the SY form
    function fill(
        FillOrderParams[] memory params,
        address receiver,
        uint256 maxTaking,
        bytes calldata optData,
        bytes calldata callback
    ) external returns (uint256 actualMaking, uint256 actualTaking, uint256 totalFee, bytes memory callbackReturn);

    function feeRecipient() external view returns (address);

    function hashOrder(Order memory order) external view returns (bytes32);

    function cancelSingle(Order calldata order) external;

    function cancelBatch(Order[] calldata orders) external;

    function orderStatusesRaw(
        bytes32[] memory orderHashes
    ) external view returns (uint256[] memory remainingsRaw, uint256[] memory filledAmounts);

    function orderStatuses(
        bytes32[] memory orderHashes
    ) external view returns (uint256[] memory remainings, uint256[] memory filledAmounts);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function simulate(address target, bytes calldata data) external payable;

    /* --- Deprecated events --- */

    // deprecate on 7/1/2024, prior to official launch
    event OrderFilled(
        bytes32 indexed orderHash,
        OrderType indexed orderType,
        address indexed YT,
        address token,
        uint256 netInputFromMaker,
        uint256 netOutputToMaker,
        uint256 feeAmount,
        uint256 notionalVolume
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IRewardManager {
    function userReward(address token, address user) external view returns (uint128 index, uint128 accrued);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IPInterestManagerYT {
    event CollectInterestFee(uint256 amountInterestFee);

    function userInterest(address user) external view returns (uint128 lastPYIndex, uint128 accruedInterest);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the “Software”), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.8.0;

/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2 ** 254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        unchecked {
            require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, "Invalid exponent");

            if (x < 0) {
                // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
                // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
                // Fixed point division requires multiplying by ONE_18.
                return ((ONE_18 * ONE_18) / exp(-x));
            }

            // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
            // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
            // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
            // decomposition.
            // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
            // decomposition, which will be lower than the smallest x_n.
            // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
            // We mutate x by subtracting x_n, making it the remainder of the decomposition.

            // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
            // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
            // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
            // decomposition.

            // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
            // it and compute the accumulated product.

            int256 firstAN;
            if (x >= x0) {
                x -= x0;
                firstAN = a0;
            } else if (x >= x1) {
                x -= x1;
                firstAN = a1;
            } else {
                firstAN = 1; // One with no decimal places
            }

            // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
            // smaller terms.
            x *= 100;

            // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
            // one. Recall that fixed point multiplication requires dividing by ONE_20.
            int256 product = ONE_20;

            if (x >= x2) {
                x -= x2;
                product = (product * a2) / ONE_20;
            }
            if (x >= x3) {
                x -= x3;
                product = (product * a3) / ONE_20;
            }
            if (x >= x4) {
                x -= x4;
                product = (product * a4) / ONE_20;
            }
            if (x >= x5) {
                x -= x5;
                product = (product * a5) / ONE_20;
            }
            if (x >= x6) {
                x -= x6;
                product = (product * a6) / ONE_20;
            }
            if (x >= x7) {
                x -= x7;
                product = (product * a7) / ONE_20;
            }
            if (x >= x8) {
                x -= x8;
                product = (product * a8) / ONE_20;
            }
            if (x >= x9) {
                x -= x9;
                product = (product * a9) / ONE_20;
            }

            // x10 and x11 are unnecessary here since we have high enough precision already.

            // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
            // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

            int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
            int256 term; // Each term in the sum, where the nth term is (x^n / n!).

            // The first term is simply x.
            term = x;
            seriesSum += term;

            // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
            // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

            term = ((term * x) / ONE_20) / 2;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 3;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 4;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 5;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 6;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 7;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 8;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 9;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 10;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 11;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 12;
            seriesSum += term;

            // 12 Taylor terms are sufficient for 18 decimal precision.

            // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
            // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
            // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
            // and then drop two digits to return an 18 decimal value.

            return (((product * seriesSum) / ONE_20) * firstAN) / 100;
        }
    }

    /**
     * @dev Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function ln(int256 a) internal pure returns (int256) {
        unchecked {
            // The real natural logarithm is not defined for negative numbers or zero.
            require(a > 0, "out of bounds");
            if (LN_36_LOWER_BOUND < a && a < LN_36_UPPER_BOUND) {
                return _ln_36(a) / ONE_18;
            } else {
                return _ln(a);
            }
        }
    }

    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) {
                // We solve the 0^0 indetermination by making it equal one.
                return uint256(ONE_18);
            }

            if (x == 0) {
                return 0;
            }

            // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
            // arrive at that r`esult. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
            // x^y = exp(y * ln(x)).

            // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
            require(x < 2 ** 255, "x out of bounds");
            int256 x_int256 = int256(x);

            // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
            // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

            // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
            require(y < MILD_EXPONENT_BOUND, "y out of bounds");
            int256 y_int256 = int256(y);

            int256 logx_times_y;
            if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
                int256 ln_36_x = _ln_36(x_int256);

                // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
                // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
                // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
                // (downscaled) last 18 decimals.
                logx_times_y = ((ln_36_x / ONE_18) * y_int256 + ((ln_36_x % ONE_18) * y_int256) / ONE_18);
            } else {
                logx_times_y = _ln(x_int256) * y_int256;
            }
            logx_times_y /= ONE_18;

            // Finally, we compute exp(y * ln(x)) to arrive at x^y
            require(
                MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT,
                "product out of bounds"
            );

            return uint256(exp(logx_times_y));
        }
    }

    /**
     * @dev Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function _ln(int256 a) private pure returns (int256) {
        unchecked {
            if (a < ONE_18) {
                // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
                // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
                // Fixed point division requires multiplying by ONE_18.
                return (-_ln((ONE_18 * ONE_18) / a));
            }

            // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
            // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
            // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
            // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
            // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
            // decomposition, which will be lower than the smallest a_n.
            // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
            // We mutate a by subtracting a_n, making it the remainder of the decomposition.

            // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
            // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
            // ONE_18 to convert them to fixed point.
            // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
            // by it and compute the accumulated sum.

            int256 sum = 0;
            if (a >= a0 * ONE_18) {
                a /= a0; // Integer, not fixed point division
                sum += x0;
            }

            if (a >= a1 * ONE_18) {
                a /= a1; // Integer, not fixed point division
                sum += x1;
            }

            // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
            sum *= 100;
            a *= 100;

            // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

            if (a >= a2) {
                a = (a * ONE_20) / a2;
                sum += x2;
            }

            if (a >= a3) {
                a = (a * ONE_20) / a3;
                sum += x3;
            }

            if (a >= a4) {
                a = (a * ONE_20) / a4;
                sum += x4;
            }

            if (a >= a5) {
                a = (a * ONE_20) / a5;
                sum += x5;
            }

            if (a >= a6) {
                a = (a * ONE_20) / a6;
                sum += x6;
            }

            if (a >= a7) {
                a = (a * ONE_20) / a7;
                sum += x7;
            }

            if (a >= a8) {
                a = (a * ONE_20) / a8;
                sum += x8;
            }

            if (a >= a9) {
                a = (a * ONE_20) / a9;
                sum += x9;
            }

            if (a >= a10) {
                a = (a * ONE_20) / a10;
                sum += x10;
            }

            if (a >= a11) {
                a = (a * ONE_20) / a11;
                sum += x11;
            }

            // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
            // that converges rapidly for values of `a` close to one - the same one used in ln_36.
            // Let z = (a - 1) / (a + 1).
            // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
            // division by ONE_20.
            int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
            int256 z_squared = (z * z) / ONE_20;

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            num = (num * z_squared) / ONE_20;
            seriesSum += num / 3;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 5;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 7;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 9;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 11;

            // 6 Taylor terms are sufficient for 36 decimal precision.

            // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
            seriesSum *= 2;

            // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
            // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
            // value.

            return (sum + seriesSum) / 100;
        }
    }

    /**
     * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function _ln_36(int256 x) private pure returns (int256) {
        unchecked {
            // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
            // worthwhile.

            // First, we transform x to a 36 digit fixed point value.
            x *= ONE_18;

            // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
            // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
            // division by ONE_36.
            int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
            int256 z_squared = (z * z) / ONE_36;

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            num = (num * z_squared) / ONE_36;
            seriesSum += num / 3;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 5;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 7;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 9;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 11;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 13;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 15;

            // 8 Taylor terms are sufficient for 36 decimal precision.

            // All that remains is multiplying by 2 (non fixed point).
            return seriesSum * 2;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "../../interfaces/IPYieldToken.sol";
import "../../interfaces/IPPrincipalToken.sol";

import "./SYUtils.sol";
import "../libraries/math/PMath.sol";

type PYIndex is uint256;

library PYIndexLib {
    using PMath for uint256;
    using PMath for int256;

    function newIndex(IPYieldToken YT) internal returns (PYIndex) {
        return PYIndex.wrap(YT.pyIndexCurrent());
    }

    function syToAsset(PYIndex index, uint256 syAmount) internal pure returns (uint256) {
        return SYUtils.syToAsset(PYIndex.unwrap(index), syAmount);
    }

    function assetToSy(PYIndex index, uint256 assetAmount) internal pure returns (uint256) {
        return SYUtils.assetToSy(PYIndex.unwrap(index), assetAmount);
    }

    function assetToSyUp(PYIndex index, uint256 assetAmount) internal pure returns (uint256) {
        return SYUtils.assetToSyUp(PYIndex.unwrap(index), assetAmount);
    }

    function syToAssetUp(PYIndex index, uint256 syAmount) internal pure returns (uint256) {
        uint256 _index = PYIndex.unwrap(index);
        return SYUtils.syToAssetUp(_index, syAmount);
    }

    function syToAsset(PYIndex index, int256 syAmount) internal pure returns (int256) {
        int256 sign = syAmount < 0 ? int256(-1) : int256(1);
        return sign * (SYUtils.syToAsset(PYIndex.unwrap(index), syAmount.abs())).Int();
    }

    function assetToSy(PYIndex index, int256 assetAmount) internal pure returns (int256) {
        int256 sign = assetAmount < 0 ? int256(-1) : int256(1);
        return sign * (SYUtils.assetToSy(PYIndex.unwrap(index), assetAmount.abs())).Int();
    }

    function assetToSyUp(PYIndex index, int256 assetAmount) internal pure returns (int256) {
        int256 sign = assetAmount < 0 ? int256(-1) : int256(1);
        return sign * (SYUtils.assetToSyUp(PYIndex.unwrap(index), assetAmount.abs())).Int();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

library MiniHelpers {
    function isCurrentlyExpired(uint256 expiry) internal view returns (bool) {
        return (expiry <= block.timestamp);
    }

    function isExpired(uint256 expiry, uint256 blockTime) internal pure returns (bool) {
        return (expiry <= blockTime);
    }

    function isTimeInThePast(uint256 timestamp) internal view returns (bool) {
        return (timestamp <= block.timestamp); // same definition as isCurrentlyExpired
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

library Errors {
    // BulkSeller
    error BulkInsufficientSyForTrade(uint256 currentAmount, uint256 requiredAmount);
    error BulkInsufficientTokenForTrade(uint256 currentAmount, uint256 requiredAmount);
    error BulkInSufficientSyOut(uint256 actualSyOut, uint256 requiredSyOut);
    error BulkInSufficientTokenOut(uint256 actualTokenOut, uint256 requiredTokenOut);
    error BulkInsufficientSyReceived(uint256 actualBalance, uint256 requiredBalance);
    error BulkNotMaintainer();
    error BulkNotAdmin();
    error BulkSellerAlreadyExisted(address token, address SY, address bulk);
    error BulkSellerInvalidToken(address token, address SY);
    error BulkBadRateTokenToSy(uint256 actualRate, uint256 currentRate, uint256 eps);
    error BulkBadRateSyToToken(uint256 actualRate, uint256 currentRate, uint256 eps);

    // APPROX
    error ApproxFail();
    error ApproxParamsInvalid(uint256 guessMin, uint256 guessMax, uint256 eps);
    error ApproxBinarySearchInputInvalid(
        uint256 approxGuessMin,
        uint256 approxGuessMax,
        uint256 minGuessMin,
        uint256 maxGuessMax
    );

    // MARKET + MARKET MATH CORE
    error MarketExpired();
    error MarketZeroAmountsInput();
    error MarketZeroAmountsOutput();
    error MarketZeroLnImpliedRate();
    error MarketInsufficientPtForTrade(int256 currentAmount, int256 requiredAmount);
    error MarketInsufficientPtReceived(uint256 actualBalance, uint256 requiredBalance);
    error MarketInsufficientSyReceived(uint256 actualBalance, uint256 requiredBalance);
    error MarketZeroTotalPtOrTotalAsset(int256 totalPt, int256 totalAsset);
    error MarketExchangeRateBelowOne(int256 exchangeRate);
    error MarketProportionMustNotEqualOne();
    error MarketRateScalarBelowZero(int256 rateScalar);
    error MarketScalarRootBelowZero(int256 scalarRoot);
    error MarketProportionTooHigh(int256 proportion, int256 maxProportion);

    error OracleUninitialized();
    error OracleTargetTooOld(uint32 target, uint32 oldest);
    error OracleZeroCardinality();

    error MarketFactoryExpiredPt();
    error MarketFactoryInvalidPt();
    error MarketFactoryMarketExists();

    error MarketFactoryLnFeeRateRootTooHigh(uint80 lnFeeRateRoot, uint256 maxLnFeeRateRoot);
    error MarketFactoryOverriddenFeeTooHigh(uint80 overriddenFee, uint256 marketLnFeeRateRoot);
    error MarketFactoryReserveFeePercentTooHigh(uint8 reserveFeePercent, uint8 maxReserveFeePercent);
    error MarketFactoryZeroTreasury();
    error MarketFactoryInitialAnchorTooLow(int256 initialAnchor, int256 minInitialAnchor);
    error MFNotPendleMarket(address addr);

    // ROUTER
    error RouterInsufficientLpOut(uint256 actualLpOut, uint256 requiredLpOut);
    error RouterInsufficientSyOut(uint256 actualSyOut, uint256 requiredSyOut);
    error RouterInsufficientPtOut(uint256 actualPtOut, uint256 requiredPtOut);
    error RouterInsufficientYtOut(uint256 actualYtOut, uint256 requiredYtOut);
    error RouterInsufficientPYOut(uint256 actualPYOut, uint256 requiredPYOut);
    error RouterInsufficientTokenOut(uint256 actualTokenOut, uint256 requiredTokenOut);
    error RouterInsufficientSyRepay(uint256 actualSyRepay, uint256 requiredSyRepay);
    error RouterInsufficientPtRepay(uint256 actualPtRepay, uint256 requiredPtRepay);
    error RouterNotAllSyUsed(uint256 netSyDesired, uint256 netSyUsed);

    error RouterTimeRangeZero();
    error RouterCallbackNotPendleMarket(address caller);
    error RouterInvalidAction(bytes4 selector);
    error RouterInvalidFacet(address facet);

    error RouterKyberSwapDataZero();

    error SimulationResults(bool success, bytes res);

    // YIELD CONTRACT
    error YCExpired();
    error YCNotExpired();
    error YieldContractInsufficientSy(uint256 actualSy, uint256 requiredSy);
    error YCNothingToRedeem();
    error YCPostExpiryDataNotSet();
    error YCNoFloatingSy();

    // YieldFactory
    error YCFactoryInvalidExpiry();
    error YCFactoryYieldContractExisted();
    error YCFactoryZeroExpiryDivisor();
    error YCFactoryZeroTreasury();
    error YCFactoryInterestFeeRateTooHigh(uint256 interestFeeRate, uint256 maxInterestFeeRate);
    error YCFactoryRewardFeeRateTooHigh(uint256 newRewardFeeRate, uint256 maxRewardFeeRate);

    // SY
    error SYInvalidTokenIn(address token);
    error SYInvalidTokenOut(address token);
    error SYZeroDeposit();
    error SYZeroRedeem();
    error SYInsufficientSharesOut(uint256 actualSharesOut, uint256 requiredSharesOut);
    error SYInsufficientTokenOut(uint256 actualTokenOut, uint256 requiredTokenOut);

    // SY-specific
    error SYQiTokenMintFailed(uint256 errCode);
    error SYQiTokenRedeemFailed(uint256 errCode);
    error SYQiTokenRedeemRewardsFailed(uint256 rewardAccruedType0, uint256 rewardAccruedType1);
    error SYQiTokenBorrowRateTooHigh(uint256 borrowRate, uint256 borrowRateMax);

    error SYCurveInvalidPid();
    error SYCurve3crvPoolNotFound();

    error SYApeDepositAmountTooSmall(uint256 amountDeposited);
    error SYBalancerInvalidPid();
    error SYInvalidRewardToken(address token);

    error SYStargateRedeemCapExceeded(uint256 amountLpDesired, uint256 amountLpRedeemable);

    error SYBalancerReentrancy();

    error NotFromTrustedRemote(uint16 srcChainId, bytes path);

    // Liquidity Mining
    error VCInactivePool(address pool);
    error VCPoolAlreadyActive(address pool);
    error VCZeroVePendle(address user);
    error VCExceededMaxWeight(uint256 totalWeight, uint256 maxWeight);
    error VCEpochNotFinalized(uint256 wTime);
    error VCPoolAlreadyAddAndRemoved(address pool);

    error VEInvalidNewExpiry(uint256 newExpiry);
    error VEExceededMaxLockTime();
    error VEInsufficientLockTime();
    error VENotAllowedReduceExpiry();
    error VEZeroAmountLocked();
    error VEPositionNotExpired();
    error VEZeroPosition();
    error VEZeroSlope(uint128 bias, uint128 slope);
    error VEReceiveOldSupply(uint256 msgTime);

    error GCNotPendleMarket(address caller);
    error GCNotVotingController(address caller);

    error InvalidWTime(uint256 wTime);
    error ExpiryInThePast(uint256 expiry);
    error ChainNotSupported(uint256 chainId);

    error FDTotalAmountFundedNotMatch(uint256 actualTotalAmount, uint256 expectedTotalAmount);
    error FDEpochLengthMismatch();
    error FDInvalidPool(address pool);
    error FDPoolAlreadyExists(address pool);
    error FDInvalidNewFinishedEpoch(uint256 oldFinishedEpoch, uint256 newFinishedEpoch);
    error FDInvalidStartEpoch(uint256 startEpoch);
    error FDInvalidWTimeFund(uint256 lastFunded, uint256 wTime);
    error FDFutureFunding(uint256 lastFunded, uint256 currentWTime);

    error BDInvalidEpoch(uint256 epoch, uint256 startTime);

    // Cross-Chain
    error MsgNotFromSendEndpoint(uint16 srcChainId, bytes path);
    error MsgNotFromReceiveEndpoint(address sender);
    error InsufficientFeeToSendMsg(uint256 currentFee, uint256 requiredFee);
    error ApproxDstExecutionGasNotSet();
    error InvalidRetryData();

    // GENERIC MSG
    error ArrayLengthMismatch();
    error ArrayEmpty();
    error ArrayOutOfBounds();
    error ZeroAddress();
    error FailedToSendEther();
    error InvalidMerkleProof();

    error OnlyLayerZeroEndpoint();
    error OnlyYT();
    error OnlyYCFactory();
    error OnlyWhitelisted();

    // Swap Aggregator
    error SAInsufficientTokenIn(address tokenIn, uint256 amountExpected, uint256 amountActual);
    error UnsupportedSelector(uint256 aggregatorType, bytes4 selector);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

library SYUtils {
    uint256 internal constant ONE = 1e18;

    function syToAsset(uint256 exchangeRate, uint256 syAmount) internal pure returns (uint256) {
        return (syAmount * exchangeRate) / ONE;
    }

    function syToAssetUp(uint256 exchangeRate, uint256 syAmount) internal pure returns (uint256) {
        return (syAmount * exchangeRate + ONE - 1) / ONE;
    }

    function assetToSy(uint256 exchangeRate, uint256 assetAmount) internal pure returns (uint256) {
        return (assetAmount * ONE) / exchangeRate;
    }

    function assetToSyUp(uint256 exchangeRate, uint256 assetAmount) internal pure returns (uint256) {
        return (assetAmount * ONE + exchangeRate - 1) / exchangeRate;
    }
}