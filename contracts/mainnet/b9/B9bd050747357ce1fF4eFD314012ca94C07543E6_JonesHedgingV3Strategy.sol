// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {JonesSwappableV3Strategy} from "./JonesSwappableV3Strategy.sol";
import {JonesStrategyV3Base} from "./JonesStrategyV3Base.sol";
import {IGMXRouter} from "../interfaces/IGMXRouter.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IDPXSingleStaking} from "../interfaces/IDPXSingleStaking.sol";
import {GmxLibrary} from "./library/GmxLibrary.sol";
import {SushiRouterWrapper} from "../VaultsV2/library/SushiRouterWrapper.sol";
import {IwETH} from "../interfaces/IwETH.sol";

contract JonesHedgingV3Strategy is JonesSwappableV3Strategy {
    using SushiRouterWrapper for IUniswapV2Router02;
    using SafeERC20 for IERC20;

    /// Farm information used to stake and unstake on Dopex
    struct DopexFarmInfo {
        IDPXSingleStaking farm;
        IERC20 underlyingToken;
        IERC20 stakingToken; // same as `underlyingToken` for single staking
    }

    /**
     * List of farm info for staking and LPing:
     *
     * 0. WETH/DPX
     * farm           : address of WETH/DPX dopex farm
     * underlyingToken: address of DPX token
     * stakingToken   : address of the WETH/DPX sushi lp token
     *
     * 1. WETH/RDPX
     * farm           : address of WETH/RDPX dopex farm
     * underlyingToken: address of RDPX token
     * stakingToken   : address of WETH/RDPX sushi lp token
     *
     * 2. DPX
     * farm           : address of DPX Dopex farm
     * underlyingToken: address of DPX
     * stakingToken   : address of DPX
     */
    DopexFarmInfo[3] public farmInfo;

    /// GMX Router contract
    IGMXRouter public constant GMXRouter =
        IGMXRouter(0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064);

    /// GMX Position Manager used to execute GMX strategies.
    address public constant GMXPositionManager =
        0x87a4088Bd721F83b6c2E5102e2FA47022Cb1c831;

    address public constant GMXOrderBook =
        0x09f77E8A13De9a35a7231028187e9fD5DB8a2ACB;

    constructor(
        bytes32 _name,
        address _asset,
        address _governor,
        address[] memory _tokensToWhitelist
    ) JonesStrategyV3Base(_name, _asset, _governor) {
        GMXRouter.approvePlugin(GMXPositionManager);
        GMXRouter.approvePlugin(GMXOrderBook);
        _setFarmInfo();
        _whitelistTokens(_tokensToWhitelist);
    }

    /* ========== Dopex Farm ========== */

    /**
     * Stakes a specific `_amount` of tokens into the Dopex farm.
     * @param _farmIndex the index value of the Dopex farm info. Enter the index value of `farmInfo` array.
     */
    function stake(uint8 _farmIndex, uint256 _amount)
        public
        virtual
        onlyRole(KEEPER)
    {
        _validateStakeParamIndex(_farmIndex);
        farmInfo[_farmIndex].stakingToken.safeApprove(
            address(farmInfo[_farmIndex].farm),
            _amount
        );
        farmInfo[_farmIndex].farm.stake(_amount);
        farmInfo[_farmIndex].stakingToken.safeApprove(
            address(farmInfo[_farmIndex].farm),
            0
        );
        emit Stake(
            msg.sender,
            address(farmInfo[_farmIndex].farm),
            address(farmInfo[_farmIndex].stakingToken),
            _amount
        );
    }

    /**
     * Claims Dopex farming rewards
     * @param _farmIndex the index value of the Dopex farm info. Enter the index value of `farmInfo` array.
     * @param _rewardsTokenID the rewards token id to claim rewards (from Dopex).
     */
    function claimDopexFarmingRewardTokens(
        uint8 _farmIndex,
        uint256 _rewardsTokenID
    ) public onlyRole(KEEPER) {
        _validateStakeParamIndex(_farmIndex);
        farmInfo[_farmIndex].farm.getReward(_rewardsTokenID);
    }

    /**
     * Unstakes a specific `_amount` of tokens from the Dopex farm.
     * @param _farmIndex the index value of the Dopex farm info. Enter the index value of `farmInfo` array.
     * @param _amount The amount to unstake
     * @param _claimRewards It will try to claim rewards if `true`
     */
    function unstake(
        uint8 _farmIndex,
        uint256 _amount,
        bool _claimRewards
    ) public virtual onlyRole(KEEPER) {
        _validateStakeParamIndex(_farmIndex);

        farmInfo[_farmIndex].farm.withdraw(_amount);

        emit Unstake(
            msg.sender,
            address(farmInfo[_farmIndex].farm),
            address(farmInfo[_farmIndex].stakingToken),
            _amount,
            _claimRewards
        );
    }

    /* ========== GMX Interaction ========== */

    /**
     * Opens or increases position on GMX.
     *
     * @param _tokenIn The address of token to deposit that will be swapped for `_collateralToken`. Enter the same address as `_collateralToken` if token swap isn't necessary.
     * @param _collateralToken the address of the collateral token. For longs, it must be the same as the `_indexToken`
     * @param _indexToken the address of the index token to long or shot
     * @param _amountIn the amount of `_tokenIn` to deposit as collateral
     * @param _minOut the min amount of `_collateralToken` output from swapping `_tokenIn` to `_collateralToken`. Enter 0 if swapping is not necessary
     * @param _sizeDelta: the USD value of the change in position size. Needs to be scaled to 30 decimals.
     * @param _price the USD value of the max (for longs) or min (for shorts) index price accepted when opening the position. Must be multiplied by (10 ** 30).
     * @param _isLong Indicates if position is long. Enter false if short.
     *
     * Note: GMXVault has convenient functions getMinPrice/getMaxPrice that are properly formatted.
     *
     * Returns a boolean to indicate if position was successfully increased.
     */
    function increasePosition(
        address _tokenIn,
        address _collateralToken,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        uint256 _price,
        bool _isLong
    ) public onlyRole(KEEPER) returns (bool) {
        return
            GmxLibrary.increasePosition(
                _tokenIn,
                _collateralToken,
                _indexToken,
                _amountIn,
                _minOut,
                _sizeDelta,
                _price,
                _isLong
            );
    }

    /**
     * Closes or decreases position on GMX.
     *
     * If `_sizeDelta` is the same size as the position, the collateral after adding profits or
     * deducting losses will be sent to the receiver address
     *
     * @param _collateralToken the collateral token used
     * @param _indexToken the index token of the position
     * @param _collateralDelta the amount of collateral in USD value to withdraw. Needs to be scaled to 30 decimals.
     * @param _sizeDelta: the USD value of the change in position size. Needs to be scaled to 30 decimals.
     * @param _price the USD value of the min (for shorts) or max (for longs) index price accepted when decreasing the position. Must be scaled to 30 decimals.
     * @param _isLong Indicate if position is long
     *
     * Note: GMXVault has convenient functions getMinPrice/getMaxPrice that are properly formatted.
     *
     * Returns a boolean to indicate if decreasing long position was successful.
     */
    function decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _price,
        bool _isLong
    ) public onlyRole(KEEPER) returns (bool) {
        return
            GmxLibrary.decreasePosition(
                _collateralToken,
                _indexToken,
                _collateralDelta,
                _sizeDelta,
                _price,
                _isLong,
                address(this)
            );
    }

    /**
     * Creates increase order on GMX.
     *
     * @param _tokenIn ERC20 address to swap **to** `_purchaseToken`. Enter same address as `_purchaseToken` if swap is not necessary.
     * @param _purchaseToken ERC20 address to swap **from** `_tokenIn`. Must be same as `_indexToken` for longs.
     * @param _amountIn The amount of `_tokenIn` to deposit.
     * @param _indexToken The index token to create order.
     * @param _minOut The min amount of `_purchaseToken` to output when swapping `_tokenIn` for `_purchaseToken`.
     * @param _sizeDelta The USD value (in 30 decimals) of the order size.
     * @param _collateralToken The ERC20 token used as collateral to create order. Must be a stablecoin for shorts.
     * @param _isLong Indicate if creating long order.
     * @param _triggerPrice The USD value (in 30 decimals) of triggering price for the `_indexToken`.
     * @param _triggerAboveThreshold Indicate if order should be triggered above threshold.
     *
     * note Make sure to send ETH for execution fee. You can use `GMXOrderBook.minExecutionFee` to calculate the amount required.
     */
    function createGMXIncreaseOrder(
        address _tokenIn,
        address _purchaseToken,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) public payable onlyRole(KEEPER) {
        GmxLibrary.createIncreaseOrder(
            _tokenIn,
            _purchaseToken,
            _amountIn,
            _indexToken,
            _minOut,
            _sizeDelta,
            _collateralToken,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold
        );
    }

    /**
     * Creates decrease order on GMX.
     *
     * @param _indexToken The index token to create order.
     * @param _sizeDelta The USD value (in 30 decimals) of the order size.
     * @param _collateralToken The ERC20 token used as collateral to create order. Must be a stablecoin for shorts.
     * @param _collateralDelta The position collateral delta.
     * @param _isLong Indicate if creating long order.
     * @param _triggerPrice The USD value (in 30 decimals) of triggering price for the `_indexToken`.
     * @param _triggerAboveThreshold Indicate if order should be triggered above threshold.
     *
     * note Make sure to send ETH for execution fee. You can use `GMXOrderBook.minExecutionFee` to calculate the amount required.
     */
    function createGMXDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) public payable onlyRole(KEEPER) {
        GmxLibrary.createDecreaseOrder(
            _indexToken,
            _sizeDelta,
            _collateralToken,
            _collateralDelta,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold
        );
    }

    /**
     * Cancels a created order on GMX.
     *
     * @param _isIncreaseOrder Indicate if cancelling increase order. True if cancelling increase order, false if cancelling decrease order.
     * @param _orderIndex The order index of the order to cancel.
     */
    function cancelGMXOrder(bool _isIncreaseOrder, uint256 _orderIndex)
        public
        onlyRole(KEEPER)
    {
        GmxLibrary.cancelOrder(_isIncreaseOrder, _orderIndex);
    }

    /* ========== Swaping ========== */

    /**
     * Swaps source token to destination token on GMX
     * @param _source source asset
     * @param _destination destination asset
     * @param _amountIn the amount of source asset to swap
     * @param _amountOutMin minimum amount of destination asset that must be received for the transaction not to revert
     *
     * Note: GMX Reader has convenient functions getMaxAmountIn/getAmountOut that could be used pre-compute values `_amountIn` and `_amountOutMin`.
     *
     */
    function swapTokensOnGmx(
        address _source,
        address _destination,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) public onlyRole(KEEPER) {
        _validateSwapParams(_source, _destination);
        GmxLibrary.swapTokens(_source, _destination, _amountIn, _amountOutMin);
    }

    /* ========== Liquidity ========== */
    /**
     * Add liquidity to acquire Dopex LP token
     *
     * @param _farmIndex the index value of the Dopex farm info. Enter the index value of `farmInfo` array.
     * @param _amountEthDesired	The amount of wETH to add as liquidity if the token/wETH price is <= _tokenAmountDesired/_amountEthDesired (wETH depreciates).
     * @param _tokenAmountDesired The amount of tokens (ex DPX or rDPX) to add as liquidity if the LP price is <= _amountEthDesired/_tokenAmountDesired (token depreciates).
     * @param _amountEthMin Bounds the extent to which the token/wETH price can go up before the transaction reverts. Must be <= _amountEthDesired.
     * @param _tokenMin Bounds the extent to which the wETH/token price can go up before the transaction reverts. Must be <= _tokenAmountDesired.
     *
     * @return _amountWETH The amount of wETH sent to the pool.
     * @return _amountTokens The amount of tokens sent to the pool.
     * @return _liquidity The amount of liquidity tokens minted.
     */
    function addETHLiquidityPair(
        uint8 _farmIndex,
        uint256 _amountEthDesired,
        uint256 _tokenAmountDesired,
        uint256 _amountEthMin,
        uint256 _tokenMin
    )
        public
        onlyRole(KEEPER)
        returns (
            uint256 _amountWETH,
            uint256 _amountTokens,
            uint256 _liquidity
        )
    {
        _validateLPParamIndex(_farmIndex);

        IERC20(wETH).safeApprove(address(sushiRouter), _amountEthDesired);

        farmInfo[_farmIndex].underlyingToken.safeApprove(
            address(sushiRouter),
            _tokenAmountDesired
        );

        (_amountWETH, _amountTokens, _liquidity) = sushiRouter.addLiquidity(
            wETH,
            address(farmInfo[_farmIndex].underlyingToken),
            _amountEthDesired,
            _tokenAmountDesired,
            _amountEthMin,
            _tokenMin,
            address(this),
            block.timestamp
        );

        IERC20(wETH).safeApprove(address(sushiRouter), 0);

        farmInfo[_farmIndex].underlyingToken.safeApprove(
            address(sushiRouter),
            0
        );
    }

    /**
     * Remove liquidity from Dopex LP
     *
     * @param _farmIndex the index value of the Dopex farm info. Enter the index value of `farmInfo` array.
     * @param _amountLiquidity	The amount of liquidity tokens to remove.
     * @param _amountEthMin The minimum amount of ETH that must be received for the transaction not to revert.
     * @param _tokensMin The minimum amount of tokens (ex DPX or RDPX) that must be received for the transaction not to revert.
     *
     * @return _amountWETH The amount of wETH received.
     * @return _amountTokens The amount of tokens (ex DPX or rDPX) received.
     */
    function removeETHLiquidityPair(
        uint8 _farmIndex,
        uint256 _amountLiquidity,
        uint256 _amountEthMin,
        uint256 _tokensMin
    )
        public
        onlyRole(KEEPER)
        returns (uint256 _amountWETH, uint256 _amountTokens)
    {
        _validateLPParamIndex(_farmIndex);

        farmInfo[_farmIndex].stakingToken.safeApprove(
            address(sushiRouter),
            _amountLiquidity
        );

        (_amountWETH, _amountTokens) = sushiRouter.removeLiquidity(
            wETH,
            address(farmInfo[_farmIndex].underlyingToken),
            _amountLiquidity,
            _amountEthMin,
            _tokensMin,
            address(this),
            block.timestamp
        );

        farmInfo[_farmIndex].stakingToken.safeApprove(address(sushiRouter), 0);
    }

    /* ========== Internal/Private ========== */

    function _setFarmInfo() private {
        // WETH/DPX Farm
        farmInfo[0] = DopexFarmInfo(
            IDPXSingleStaking(0x96B0d9c85415C69F4b2FAC6ee9e9CE37717335B4), // weth/dpx dopex farm
            IERC20(0x6C2C06790b3E3E3c38e12Ee22F8183b37a13EE55), // dpx
            IERC20(0x0C1Cf6883efA1B496B01f654E247B9b419873054) // weth/dpx sushi lp token
        );

        // WETH/RDPX Farm
        farmInfo[1] = DopexFarmInfo(
            IDPXSingleStaking(0x03ac1Aa1ff470cf376e6b7cD3A3389Ad6D922A74), // weth/rdpx dopex farm
            IERC20(0x32Eb7902D4134bf98A28b963D26de779AF92A212), // rdpx
            IERC20(0x7418F5A2621E13c05d1EFBd71ec922070794b90a) // weth/rdpx sushi lp token
        );

        // DPX Farm
        farmInfo[2] = DopexFarmInfo(
            IDPXSingleStaking(0xc6D714170fE766691670f12c2b45C1f34405AAb6), // dpx dopex farm
            IERC20(0x6C2C06790b3E3E3c38e12Ee22F8183b37a13EE55), // dpx
            IERC20(0x6C2C06790b3E3E3c38e12Ee22F8183b37a13EE55) // dpx
        );
    }

    function _validateStakeParamIndex(uint256 _index) internal view {
        if (_index >= farmInfo.length) {
            revert INVALID_INDEX();
        }
    }

    function _validateLPParamIndex(uint256 _index) internal view {
        if (_index >= farmInfo.length - 1) {
            revert INVALID_INDEX();
        }
    }

    /// @inheritdoc JonesSwappableV3Strategy
    function _afterRemoveWhitelistedToken(address _token) internal override {
        IERC20(_token).safeApprove(address(GMXRouter), 0);
    }

    /* ========== SYSTEM ========== */

    /**
     * Used for GMX interactions - DO NOT USE THIS TO FUND STRATEGY!
     */
    receive() external payable {
        IwETH(wETH).deposit{value: msg.value}();
    }

    /* ========== EVENTS ========== */

    /**
     * Emitted when staking token into Dopex Farm
     *
     * @param _keeper the address of the sender that performed this action
     * @param _farm the address of the Dopex farm
     * @param _token the address of the token that was staked
     * @param _amount the amount of tokens staked into farm
     */
    event Stake(
        address indexed _keeper,
        address indexed _farm,
        address indexed _token,
        uint256 _amount
    );

    /**
     * Emitted when staking into Dopex Farm
     *
     * @param _keeper the address of the sender that performed this action
     * @param _farm the address of the Dopex farm
     * @param _token the address of the token that was unstaked
     * @param _amount the amount of tokens unstaked from farm
     * @param _claimRewards if rewards were claimed
     */
    event Unstake(
        address indexed _keeper,
        address indexed _farm,
        address indexed _token,
        uint256 _amount,
        bool _claimRewards
    );

    /* ========== ERRORS ========== */
    error INVALID_INDEX();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {JonesStrategyV3Base} from "./JonesStrategyV3Base.sol";
import {SushiRouterWrapper} from "../VaultsV2/library/SushiRouterWrapper.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";

abstract contract JonesSwappableV3Strategy is JonesStrategyV3Base {
    using SafeERC20 for IERC20;
    using SushiRouterWrapper for IUniswapV2Router02;

    /// Indicates if whitelist check for token swap should be required.
    bool public requireWhitelist = true;

    /// supported tokens for swapping tokens on GMX and Sushi
    mapping(address => bool) public whitelistedTokens;

    /**
     * Swaps source token to destination token on sushiswap
     * @param _source source asset
     * @param _destination destination asset
     * @param _amountIn the amount of source asset to swap
     * @param _amountOutMin minimum amount of destination asset that must be received for the transaction not to revert
     */
    function swapAssetsOnSushi(
        address _source,
        address _destination,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) public virtual onlyRole(KEEPER) {
        _validateSwapParams(_source, _destination);
        IERC20(_source).safeApprove(address(sushiRouter), _amountIn);
        address[] memory path = _getPathForSushiSwap(_source, _destination);
        sushiRouter.swapTokens(_amountIn, _amountOutMin, path, address(this));
        IERC20(_source).safeApprove(address(sushiRouter), 0);
    }

    /**
     * Whitelists `_token` for swapping.
     */
    function whitelistToken(address _token) public virtual onlyRole(GOVERNOR) {
        _whitelistToken(_token);
    }

    /**
     * Removes `_token` for whitelist.
     */
    function removeWhitelistedToken(address _token)
        public
        virtual
        onlyRole(GOVERNOR)
    {
        if (!whitelistedTokens[_token]) {
            revert TOKEN_NOT_WHITELISTED();
        }
        whitelistedTokens[_token] = false;
        IERC20(_token).safeApprove(address(sushiRouter), 0);
        _afterRemoveWhitelistedToken(_token);
    }

    /**
     * Sets whitelist requirement to `_required`. If set to true, tokens will be checked for whitelist before performing swaps.
     */
    function setRequireWhitelist(bool _required)
        public
        virtual
        onlyRole(GOVERNOR)
    {
        requireWhitelist = _required;
    }

    /**
     * A helper function that whitelists `_tokens`.
     */
    function _whitelistTokens(address[] memory _tokens) internal virtual {
        for (uint256 i = 0; i < _tokens.length; i++) {
            _whitelistToken(_tokens[i]);
        }
    }

    /**
     * A helper function that whitelist a token with address `_token`.
     */
    function _whitelistToken(address _token) internal virtual {
        if (_token == address(0)) {
            revert ADDRESS_CANNOT_BE_ZERO_ADDRESS();
        }

        whitelistedTokens[_token] = true;
    }

    /**
     * Fetches sushi swap path for specified `_source` and `_destination`.
     */
    function _getPathForSushiSwap(address _source, address _destination)
        internal
        virtual
        returns (address[] memory _path)
    {
        if (_source == wETH || _destination == wETH) {
            _path = new address[](2);
            _path[0] = _source;
            _path[1] = _destination;
        } else {
            _path = new address[](3);
            _path[0] = _source;
            _path[1] = wETH;
            _path[2] = _destination;
        }
    }

    /**
     * Performs parameter valudation for swap.
     */
    function _validateSwapParams(address _source, address _destination)
        internal
        virtual
    {
        if (_source == address(0) || _destination == address(0)) {
            revert ADDRESS_CANNOT_BE_ZERO_ADDRESS();
        }

        if (_source == _destination) {
            revert INVALID_INPUT_TOKEN();
        }

        if (!whitelistedTokens[_destination] && requireWhitelist) {
            revert TOKEN_NOT_WHITELISTED();
        }
    }

    /**
     * Hook that is invoked after removing whitelisted `_token`.
     */
    function _afterRemoveWhitelistedToken(address _token) internal virtual {}

    error INVALID_INPUT_TOKEN();
    error TOKEN_NOT_WHITELISTED();
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStrategy} from "./IStrategy.sol";
import {IVault} from "./IVault.sol";
import {IwETH} from "../interfaces/IwETH.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";

abstract contract JonesStrategyV3Base is IStrategy, AccessControl {
    using SafeERC20 for IERC20;

    address internal _vault;
    bytes32 public constant KEEPER = keccak256("KEEPER");
    bytes32 public constant GOVERNOR = keccak256("GOVERNOR");
    address public constant wETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    IUniswapV2Router02 public constant sushiRouter =
        IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    address public immutable asset;
    bytes32 public immutable name;
    bool public isVaultSet;

    /**
     * @dev Sets the values for {name} and {asset}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        bytes32 _name,
        address _asset,
        address _governor
    ) {
        if (_asset == address(0)) {
            revert ADDRESS_CANNOT_BE_ZERO_ADDRESS();
        }

        if (_governor == address(0)) {
            revert ADDRESS_CANNOT_BE_ZERO_ADDRESS();
        }

        name = _name;
        asset = _asset;

        _grantRole(GOVERNOR, _governor);
        _grantRole(KEEPER, _governor);
    }

    // ============================= View functions ================================

    /**
     * @inheritdoc IStrategy
     */
    function getVault() public view virtual returns (address) {
        if (!isVaultSet) {
            revert VAULT_NOT_ATTACHED();
        }
        return address(_vault);
    }

    /**
     * @inheritdoc IStrategy
     */
    function getUnused() public view virtual override returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
    }

    // ============================= Mutative functions ================================

    function grantKeeperRole(address _to) public onlyRole(GOVERNOR) {
        if (_to == address(0)) {
            revert ADDRESS_CANNOT_BE_ZERO_ADDRESS();
        }
        _grantRole(KEEPER, _to);
    }

    function revokeKeeperRole(address _from) public onlyRole(GOVERNOR) {
        _revokeRole(KEEPER, _from);
    }

    /**
     * @inheritdoc IStrategy
     */
    function setVault(address _newVault) public virtual onlyRole(GOVERNOR) {
        if (isVaultSet) {
            revert VAULT_ALREADY_ATTACHED();
        }

        if (_newVault == address(0)) {
            revert ADDRESS_CANNOT_BE_ZERO_ADDRESS();
        }

        _vault = _newVault;
        IERC20(asset).safeApprove(_vault, type(uint256).max);
        isVaultSet = true;
        emit VaultSet(_msgSender(), _vault);
    }

    /**
     * @inheritdoc IStrategy
     */
    function detach() public virtual override onlyRole(GOVERNOR) {
        if (!isVaultSet) {
            revert VAULT_NOT_ATTACHED();
        }
        _repay();
        if (getUnused() > 0) {
            revert STRATEGY_STILL_HAS_ASSET_BALANCE();
        }
        address prevVault = _vault;
        IERC20(asset).safeApprove(_vault, 0);
        _vault = address(0);
        isVaultSet = false;
        emit VaultDetached(msg.sender, prevVault);
    }

    /**
     * @inheritdoc IStrategy
     */
    function borrow(uint256 _amount) public virtual override onlyRole(KEEPER) {
        if (!isVaultSet) {
            revert VAULT_NOT_ATTACHED();
        }
        if (_amount == 0) {
            revert BORROW_AMOUNT_ZERO();
        }
        IVault(_vault).pull(_amount);
        emit Borrow(_msgSender(), _amount, _vault, asset);
    }

    /**
     * @inheritdoc IStrategy
     */
    function repay() public virtual override onlyRole(KEEPER) {
        _repay();
    }

    /**
     * @inheritdoc IStrategy
     */
    function repayFunds(uint256 _amount)
        public
        virtual
        override
        onlyRole(KEEPER)
    {
        _repayFunds(_amount);
    }

    function _repay() internal virtual {
        _repayFunds(getUnused());
    }

    function _repayFunds(uint256 _amount) internal virtual {
        if (!isVaultSet) {
            revert VAULT_NOT_ATTACHED();
        }
        if (_amount == 0 || _amount > getUnused()) {
            revert INVALID_AMOUNT();
        }
        IVault(_vault).depositStrategyFunds(_amount);
        emit Repay(_msgSender(), _amount, _vault, asset);
    }

    function migrateFunds(
        address _to,
        address[] memory _tokens,
        bool _shouldTransferEth,
        bool
    ) public virtual override onlyRole(GOVERNOR) {
        _transferTokens(_to, _tokens, _shouldTransferEth);
        emit FundsMigrated(_to);
    }

    function _transferTokens(
        address _to,
        address[] memory _tokens,
        bool _shouldTransferEth
    ) internal virtual {
        // transfer tokens
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            uint256 assetBalance = token.balanceOf(address(this));
            if (assetBalance > 0) {
                token.safeTransfer(_to, assetBalance);
            }
        }

        // migrate ETH balance
        uint256 balanceGwei = address(this).balance;
        if (balanceGwei > 0 && _shouldTransferEth) {
            payable(_to).transfer(balanceGwei);
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IGMXRouter {
    function setGov(address _gov) external;

    function addPlugin(address _plugin) external;

    function removePlugin(address _plugin) external;

    function approvePlugin(address _plugin) external;

    function denyPlugin(address _plugin) external;

    function pluginTransfer(
        address _token,
        address _account,
        address _receiver,
        uint256 _amount
    ) external;

    function pluginIncreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function pluginDecreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function directPoolDeposit(address _token, uint256 _amount) external;

    function swap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address _receiver
    ) external;

    function swapETHToTokens(
        address[] memory _path,
        uint256 _minOut,
        address _receiver
    ) external payable;

    function swapTokensToETH(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address payable _receiver
    ) external;

    function increasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) external;

    function increasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) external payable;

    function decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) external;

    function decreasePositionETH(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address payable _receiver,
        uint256 _price
    ) external;

    function decreasePositionAndSwap(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price,
        uint256 _minOut
    ) external;

    function decreasePositionAndSwapETH(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address payable _receiver,
        uint256 _price,
        uint256 _minOut
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

interface IDPXSingleStaking {
    function balanceOf(address account) external view returns (uint256);

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward(uint256 rewardsTokenID) external;

    function compound() external;

    function exit() external;

    function earned(address account)
        external
        view
        returns (uint256 DPXEarned, uint256 RDPXEarned);

    function stakingToken() external view returns (address);

    function rewardsTokenDPX() external view returns (address);

    function whitelistedContracts(address) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   ********************* 
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/

pragma solidity ^0.8.10;

// Interfaces
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IGMXRouter} from "../../interfaces/IGMXRouter.sol";
import {IGMXVault} from "../../interfaces/IGMXVault.sol";
import {IGMXOrderBook} from "../../interfaces/IGMXOrderBook.sol";
import {IGMXPositionManager} from "../../interfaces/IGMXPositionManager.sol";

library GmxLibrary {
    using SafeERC20 for IERC20;

    /// GMX Router contract
    IGMXRouter public constant GMXRouter =
        IGMXRouter(0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064);

    /// GMX Vault contract
    IGMXVault public constant GMXVault =
        IGMXVault(0x489ee077994B6658eAfA855C308275EAd8097C4A);

    /// GMX Position Manager used to execute GMX strategies.
    IGMXPositionManager public constant GMXPositionManager =
        IGMXPositionManager(0x87a4088Bd721F83b6c2E5102e2FA47022Cb1c831);

    IGMXOrderBook public constant GMXOrderBook =
        IGMXOrderBook(0x09f77E8A13De9a35a7231028187e9fD5DB8a2ACB);

    address public constant wETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    function swapTokens(
        address _source,
        address _destination,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) external {
        IERC20(_source).safeApprove(address(GMXRouter), _amountIn);
        address[] memory path = new address[](2);
        path[0] = _source;
        path[1] = _destination;
        GMXRouter.swap(path, _amountIn, _amountOutMin, address(this));
        IERC20(_source).safeApprove(address(GMXRouter), 0);
    }

    function increasePosition(
        address _tokenIn,
        address _collateralToken,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        uint256 _price,
        bool _isLong
    ) external returns (bool) {
        if (_isLong && _collateralToken != _indexToken) {
            revert COLLATERAL_TOKEN_NOT_EQUAL_TO_INDEX();
        }

        // approve allowance for router
        IERC20(_tokenIn).safeApprove(address(GMXRouter), _amountIn);

        address[] memory path;
        if (_tokenIn == _collateralToken) {
            path = new address[](1);
            path[0] = _tokenIn;
        } else {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _collateralToken;
        }

        GMXPositionManager.increasePosition(
            path,
            _indexToken, // the address of the token to long
            _amountIn, // the amount of tokenIn to deposit as collateral
            _minOut, // the min amount of collateralToken to swap for
            _sizeDelta, // the USD value of the change in position size
            _isLong, // is long
            _price // the USD value of the index price accepted when opening the position
        );

        IERC20(_tokenIn).safeApprove(address(GMXRouter), 0);

        emit IncreasePosition(
            _tokenIn,
            _collateralToken,
            _indexToken,
            _amountIn,
            _minOut,
            _sizeDelta,
            _isLong,
            _price
        );
        return true;
    }

    function decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _price,
        bool _isLong,
        address _receiver
    ) external returns (bool) {
        if (_isLong && _collateralToken != _indexToken) {
            revert COLLATERAL_TOKEN_NOT_EQUAL_TO_INDEX();
        }

        GMXPositionManager.decreasePosition(
            _collateralToken, // the collateral token used
            _indexToken, //  the index token of the position
            _collateralDelta, // the amount of collateral in USD value to withdraw
            _sizeDelta, // the USD value of the change in position size
            _isLong, // is long
            _receiver, // the address to receive the withdrawn tokens
            _price // the USD value of the max index price accepted when decreasing the position
        );

        emit DecreasePosition(
            _collateralToken,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            _price
        );
        return true;
    }

    function createIncreaseOrder(
        address _tokenIn,
        address _purchaseToken,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external returns (bool) {
        uint256 executionFee = GMXOrderBook.minExecutionFee();
        if (msg.value < executionFee) {
            revert INVALID_EXECUTION_FEE();
        }

        address[] memory path;
        if (_tokenIn == _purchaseToken) {
            path = new address[](1);
            path[0] = _purchaseToken;
        } else {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _purchaseToken;
        }

        IERC20(_tokenIn).safeApprove(address(GMXRouter), _amountIn);

        GMXOrderBook.createIncreaseOrder{value: msg.value}(
            path,
            _amountIn,
            _indexToken,
            _minOut,
            _sizeDelta,
            _collateralToken,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            executionFee,
            false
        );

        IERC20(_tokenIn).safeApprove(address(GMXRouter), 0);

        return true;
    }

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external returns (bool) {
        uint256 executionFee = GMXOrderBook.minExecutionFee();
        if (msg.value <= executionFee) {
            revert INVALID_EXECUTION_FEE();
        }

        GMXOrderBook.createDecreaseOrder{value: msg.value}(
            _indexToken,
            _sizeDelta,
            _collateralToken,
            _collateralDelta,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold
        );

        return true;
    }

    function cancelOrder(bool _isIncreaseOrder, uint256 _orderIndex) external {
        if (_isIncreaseOrder) {
            GMXOrderBook.cancelIncreaseOrder(_orderIndex);
        } else {
            GMXOrderBook.cancelDecreaseOrder(_orderIndex);
        }
    }

    /**
     * Emitted when a GMX position is increased
     *
     * @param _tokenIn The address of token to deposit that will be swapped for `_collateralToken`. Enter the same address as `_collateralToken` if token swap isn't necessary.
     * @param _collateralToken the address of the collateral token. For longs, it must be the same as the `_indexToken`
     * @param _indexToken the address of the token to long
     * @param _amountIn the amount of tokenIn to deposit as collateral
     * @param _minOut the min amount of collateralToken to swap for
     * @param _sizeDelta the USD value of the change in position size
     * @param _isLong is long
     * @param _price the USD value of index price accepted when opening the position
     */
    event IncreasePosition(
        address indexed _tokenIn,
        address indexed _collateralToken,
        address indexed _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    );

    /**
     * Emitted when a GMX position is increased
     *
     * @param _collateralToken the collateral token used
     * @param _indexToken  the index token of the position
     * @param _collateralDelta the amount of collateral in USD value to withdraw
     * @param _isLong indicates if position was long
     * @param _price price in usd (scaled to 30) of the index token to decrease position
     */
    event DecreasePosition(
        address indexed _collateralToken,
        address indexed _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    );

    error COLLATERAL_TOKEN_NOT_EQUAL_TO_INDEX();
    error INVALID_EXECUTION_FEE();
}

// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   ********************* 
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/

pragma solidity ^0.8.10;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "../../interfaces/IUniswapV2Router02.sol";

library SushiRouterWrapper {
    using SafeERC20 for IERC20;

    /**
     * Sells the received tokens for the provided amounts for the last token in the route
     * Temporary solution until we implement accumulation policy.
     * @param self the sushi router used to perform the sale.
     * @param _assetAmounts output amount from selling the tokens.
     * @param _tokens tokens to sell.
     * @param _recepient recepient address.
     * @param _routes routes to sell each token
     */
    function sellTokens(
        IUniswapV2Router02 self,
        uint256[] memory _assetAmounts,
        address[] memory _tokens,
        address _recepient,
        address[][] memory _routes
    ) public {
        uint256 amountsLength = _assetAmounts.length;
        uint256 tokensLength = _tokens.length;
        uint256 routesLength = _routes.length;

        require(amountsLength == tokensLength, "SRE1");
        require(routesLength == tokensLength, "SRE1");

        uint256 deadline = block.timestamp + 120;
        for (uint256 i = 0; i < tokensLength; i++) {
            _sellTokens(
                self,
                IERC20(_tokens[i]),
                _assetAmounts[i],
                _recepient,
                deadline,
                _routes[i]
            );
        }
    }

    /**
     * Sells the received tokens for the provided amounts for ETH
     * Temporary solution until we implement accumulation policy.
     * @param self the sushi router used to perform the sale.
     * @param _assetAmounts output amount from selling the tokens.
     * @param _tokens tokens to sell.
     * @param _recepient recepient address.
     * @param _routes routes to sell each token.
     */
    function sellTokensForEth(
        IUniswapV2Router02 self,
        uint256[] memory _assetAmounts,
        address[] memory _tokens,
        address _recepient,
        address[][] memory _routes
    ) public {
        uint256 amountsLength = _assetAmounts.length;
        uint256 tokensLength = _tokens.length;
        uint256 routesLength = _routes.length;

        require(amountsLength == tokensLength, "SRE1");
        require(routesLength == tokensLength, "SRE1");

        uint256 deadline = block.timestamp + 120;
        for (uint256 i = 0; i < tokensLength; i++) {
            _sellTokensForEth(
                self,
                IERC20(_tokens[i]),
                _assetAmounts[i],
                _recepient,
                deadline,
                _routes[i]
            );
        }
    }

    /**
     * Sells one token for a given amount of another.
     * @param self the Sushi router used to perform the sale.
     * @param _route route to swap the token.
     * @param _assetAmount output amount of the last token in the route from selling the first.
     * @param _recepient recepient address.
     */
    function sellTokensForExactTokens(
        IUniswapV2Router02 self,
        address[] memory _route,
        uint256 _assetAmount,
        address _recepient,
        address _token
    ) public {
        require(_route.length >= 2, "SRE2");
        uint256 balance = IERC20(_route[0]).balanceOf(_recepient);
        if (balance > 0) {
            uint256 deadline = block.timestamp + 120; // Two minutes
            _sellTokens(
                self,
                IERC20(_token),
                _assetAmount,
                _recepient,
                deadline,
                _route
            );
        }
    }

    function _sellTokensForEth(
        IUniswapV2Router02 _sushiRouter,
        IERC20 _token,
        uint256 _assetAmount,
        address _recepient,
        uint256 _deadline,
        address[] memory _route
    ) private {
        uint256 balance = _token.balanceOf(_recepient);
        if (balance > 0) {
            _sushiRouter.swapExactTokensForETH(
                balance,
                _assetAmount,
                _route,
                _recepient,
                _deadline
            );
        }
    }

    function swapTokens(
        IUniswapV2Router02 self,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _recepient
    ) external {
        self.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            _recepient,
            block.timestamp
        );
    }

    function _sellTokens(
        IUniswapV2Router02 _sushiRouter,
        IERC20 _token,
        uint256 _assetAmount,
        address _recepient,
        uint256 _deadline,
        address[] memory _route
    ) private {
        uint256 balance = _token.balanceOf(_recepient);
        if (balance > 0) {
            _sushiRouter.swapExactTokensForTokens(
                balance,
                _assetAmount,
                _route,
                _recepient,
                _deadline
            );
        }
    }

    // ERROR MAPPING:
    // {
    //   "SRE1": "Rewards: token, amount and routes lenght must match",
    //   "SRE2": "Length of route must be at least 2",
    // }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IwETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IStrategy {
    // ============================= View functions ================================

    /**
     * @return strategy name
     */
    function name() external view returns (bytes32);

    /**
     * Returns the base erc20 asset for the strategy.
     * Assumption: For now, strategies only accept one base asset at the time (i.e the same strat cannot invest ETH and DPX ony one or the other).
     * @return the address for the asset
     */
    function asset() external view returns (address);

    /**
     * Returns the current unused assets in the strategy.
     * @return unused amount of assets
     */
    function getUnused() external view returns (uint256);

    /**
     * Returns the vault attached to strategy.
     * Should revert with error if vault is not attached.
     */
    function getVault() external view returns (address);

    // ============================= Mutative functions ================================

    /**
     * Borrow base assets from the vault.
     * This will borrow the required `_amount` in base assets from the vault.
     * @dev SHOULD only be called by the strategists
     * @dev SHOULD call a very specific method on the vault and not do "transferTo"
     * @dev SHOULD emit event Borrow(vault, asset, amount)
     * @param _amount the amount of assets to borrow
     */
    function borrow(uint256 _amount) external;

    /**
     * Returns all funds to the vault.
     * @dev SHOULD only be called by the strategists
     * @dev SHOULD call a very specific method on the vault "depositProfits"
     * @dev SHOULD emit event Repay(vault, asset, amount)
     */
    function repay() external;

    /**
     * Returns specified `_amount` of funds to the vault.
     * @dev SHOULD only be called by the strategists
     * @dev SHOULD call a very specific method on the vault "depositStrategyFunds"
     * @dev SHOULD emit event Repay(vault, asset, amount)
     */
    function repayFunds(uint256 _amount) external;

    /**
     * Migrates funds to specified address `_to`.
     * @dev SHOULD only be called by the GOVERNOR.
     *
     * Emits {FundsMigrated}
     */
    function migrateFunds(
        address _to,
        address[] memory _tokens,
        bool _shouldTransferEth,
        bool _shouldTransferERC721
    ) external;

    /**
     * Detaches the strategy.
     * For some reason we might want to detach the strat from the vault,
     * this function should close all open positions, repay the vault and remove itself from the vault whitelist.
     *
     * Reverts if pending settlements or unable to withdraw every deposit after calling `repay`.
     * This is to ensure that the Strategy only detaches if everything is settled and
     * deposited assets are repaid to vault.
     *
     * Make sure to invoke `removeStrategyFromWhitelist` on previously detached vault after detaching.
     *
     * @dev SHOULD only be called by the `GOVERNOR`. Governor should also have `KEEPER` role in order to detach successfully.
     * @dev This function should raise an error in the case it can't withdrawal all the funds invested from the used contracts
     */
    function detach() external;

    /**
     * @dev Attaches `_vault` to this strategy.
     *
     * Only a strategist can attach vault and can only happen once.
     * This method is used over the constructor to prevent circular dependency.
     * Should revert with error if vault is already attached.
     *
     * Invoke `whitelistStrategy` on vault after calling this to whitelist this
     * strategy for the vault to be able to pull assets and perform other restricted actions.
     *
     * Emits {VaultSet}.
     */
    function setVault(address _vault) external;

    // ============================= Events ================================
    /**
     * Emitted when borrowing assets from the underlying vault.
     */
    event Borrow(
        address indexed strategist,
        uint256 amount,
        address indexed vault,
        address indexed asset
    );

    /**
     * Emitted when closing the strategy.
     */
    event Repay(
        address indexed strategist,
        uint256 amount,
        address indexed vault,
        address indexed asset
    );

    /**
     * Emitted when attaching the vault.
     */
    event VaultSet(address indexed governor, address indexed vault);

    /**
     * Emitted when migrating funds (ex in case of an emergency).
     */
    event FundsMigrated(address indexed governor);

    /**
     * Emitted when detaching the vault.
     */
    event VaultDetached(address indexed governor, address indexed vault);

    // ============================= Errors ================================
    error ADDRESS_CANNOT_BE_ZERO_ADDRESS();
    error VAULT_NOT_ATTACHED();
    error VAULT_ALREADY_ATTACHED();
    error MANAGEMENT_WINDOW_NOT_OPEN();
    error NOT_ENOUGH_AVAILABLE_ASSETS();
    error STRATEGY_STILL_HAS_ASSET_BALANCE();
    error BORROW_AMOUNT_ZERO();
    error MSG_SENDER_DOES_NOT_HAVE_PERMISSION_TO_EMERGENCY_WITHDRAW();
    error INVALID_AMOUNT();
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IVault {
    // ============================= View functions ================================

    /**
     * The amount of `shares` that the Vault would exchange for the amount of `assets` provided, in an ideal scenario where all the conditions are met.
     *
     * Does not show any variations depending on the caller.
     * Does not reflect slippage or other on-chain conditions, when performing the actual exchange.
     * Does not revert unless due to integer overflow caused by an unreasonably large input.
     * This calculation does not reflect the “per-user” price-per-share, and instead reflects the “average-user’s” price-per-share, meaning what the average user can expect to see when exchanging to and from.
     *
     * @param assets Amount of assets to convert.
     * @return shares Amount of shares calculated for the amount of given assets, rounded down towards 0. Does not include any fees that are charged against assets in the Vault.
     */
    function convertToShares(uint256 assets)
        external
        view
        returns (uint256 shares);

    /**
     * The amount of `assets` that the Vault would exchange for the amount of `shares` provided, in an ideal scenario where all the conditions are met.
     *
     * Does not show any variations depending on the caller.
     * Does not reflect slippage or other on-chain conditions, when performing the actual exchange.
     * Does not revert unless due to integer overflow caused by an unreasonably large input.
     * This calculation does not reflect the “per-user” price-per-share, and instead reflects the “average-user’s” price-per-share, meaning what the average user can expect to see when exchanging to and from.
     *
     * @return assets Amount of assets calculated for the given amount of shares, rounded down towards 0. Does not include fees that are charged against assets in the Vault.
     */
    function convertToAssets(uint256 shares)
        external
        view
        returns (uint256 assets);

    /**
     * Maximum amount of the underlying asset that can be deposited into the Vault for the receiver, through a deposit call.
     * Returns the maximum amount of assets deposit would allow to be deposited for receiver and not cause a revert, which should be higher than the actual maximum that would be accepted (it should underestimate if necessary). This assumes that the user has infinite assets, i.e. does not rely on balanceOf of asset.
     *
     * Does not revert.
     * This is akin to `vaultCap` in legacy vaults.
     *
     * The `receiver` parameter is added for ERC-4626 parity and is not relevant to our use case
     * since we are not going to have user specific limits for deposits. Either deposits are limited
     * to everyone or no one.
     *
     * @return maxAssets Max assets that can be deposited for receiver. Returns 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited. Returns 0 if deposits are entirely disabled (even temporarily).
     */
    function maxDeposit(address receiver)
        external
        view
        returns (uint256 maxAssets);

    /**
     * Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given current on-chain conditions.
     *
     * Returns as close to and no more than the exact amount of Vault shares that would be minted in a deposit call in the same transaction. I.e. deposit will return the same or more shares as previewDeposit if called in the same transaction.
     * Does not account for deposit limits like those returned from maxDeposit and always acts as though the deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * Does not revert due to vault specific user/global limits. May revert due to other conditions that would also cause deposit to revert.
     *
     * Any unfavorable discrepancy between convertToShares and previewDeposit will be considered slippage in share price or some other type of condition, meaning the depositor will lose assets by depositing.
     *
     * @return shares exact amount of shares that would be minted in a deposit call. That includes deposit fees. Integrators should be aware of the existence of deposit fees.
     */
    function previewDeposit(uint256 assets)
        external
        view
        returns (uint256 shares);

    /**
     * @return The current vault State
     */
    function state() external view returns (State);

    /**
     * The address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     */
    function asset() external view returns (address);

    /**
     * The address of the underlying shares token used used to represent tokenized vault.
     */
    function share() external view returns (address);

    /**
     * Total amount of the underlying asset that is managed by this vault.
     *
     * This includes any compounding that occurs from yield.
     * It must be inclusive of any fees that are charged against assets in the Vault.
     * Must not revert.
     *
     * @return totalManagedAssets amount of underlying asset managed by vault.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * Maximum amount of shares that can be minted from the Vault for the `receiver`, through a `mint` call.
     *
     * Returns `2 ** 256 - 1` if there is no limit on the maximum amount of shares that may be minted.
     */
    function maxMint(address receiver)
        external
        view
        returns (uint256 maxShares);

    /**
     * Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given current on-chain conditions.
     * MUST NOT revert due to vault specific user/global limits. MAY revert due to other conditions that would also cause mint to revert.
     * note: Any unfavorable discrepancy between `convertToAssets` and `previewMint` should be considered slippage in share price or some other type of condition, meaning the depositor will lose assets by minting.
     *
     * Does not account for mint limits like those returned from maxMint and always acts as though the mint would be accepted, regardless if the user has enough tokens approved, etc.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * Maximum amount of the underlying asset that can be withdrawn from the `owner` balance in the Vault, through a `withdraw` call.
     *
     * Factors in both global and user-specific limits, like if withdrawals are entirely disabled (even temporarily) it must return 0.
     * Does not revert.
     *
     * @return maxAssets The maximum amount of assets that could be transferred from `owner` through `withdraw` and not cause a revert, which must not be higher than the actual maximum that would be accepted (it should underestimate if necessary).
     */
    function maxWithdraw(address owner)
        external
        view
        returns (uint256 maxAssets);

    /**
     * Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions.
     *
     * Does not revert due to vault specific user/global limits. May revert due to other conditions that would also cause withdraw to revert.
     * Any unfavorable discrepancy between convertToShares and previewWithdraw should be considered slippage in share price or some other type of condition, meaning the depositor will lose assets by depositing.
     *
     * @return shares Shares available to withdraw for specified assets. This includes of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     */
    function previewWithdraw(uint256 assets)
        external
        view
        returns (uint256 shares);

    /**
     * Maximum amount of Vault shares that can be redeemed from the `owner` balance in the Vault, through a `redeem` call.
     *
     * @return maxShares Max shares that can be redeemed. Factors in both global and user-specific limits, like if redemption is entirely disabled (even temporarily) it will return 0.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block, given current on-chain conditions.
     * Does not account for redemption limits like those returned from maxRedeem and should always act as though the redemption would be accepted, regardless if the user has enough shares, etc.
     *
     * Does not revert due to vault specific user/global limits. May revert due to other conditions that would also cause redeem to revert.
     *
     * @return assets Amount of assets redeemable for given shares. Includes of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     */
    function previewRedeem(uint256 shares)
        external
        view
        returns (uint256 assets);

    // ============================= User functions ================================

    /**
     * @dev Mints `shares` Vault shares to `receiver` by depositing `amount` of underlying tokens. This should only be called outside the management window.
     *
     * Reverts if all of assets cannot be deposited (ex due to deposit limit, slippage, approvals, etc).
     *
     * Emits a {Deposit} event
     */
    function deposit(uint256 assets, address receiver)
        external
        returns (uint256 shares);

    /**
     * Mints exactly `shares` Vault shares to `receiver` by depositing `amount` of underlying tokens.
     *
     * Reverts if all of shares cannot be minted (ex. due to deposit limit being reached, slippage, etc).
     *
     * Emits a {Deposit} event
     */
    function mint(uint256 shares, address receiver)
        external
        returns (uint256 assets);

    /**
     * Burns `shares` from `owner` and sends exactly `assets` of underlying tokens to `receiver`. Only available outside of management window.
     *
     * Reverts if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner not having enough shares, etc).
     * Any pre-requesting methods before withdrawal should be performed separately.
     *
     * Emits a {Withdraw} event
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * Burns exactly `shares` from `owner` and sends `assets` of underlying tokens to `receiver`. Only available outside of management window.
     *
     * Reverts if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner not having enough shares, etc).
     * Any pre-requesting methods before withdrawal should be performed separately.
     *
     * Emits a {Withdraw} event
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    // ============================= Strategy functions ================================

    /**
     * Sends the required amount of Asset from this vault to the calling strategy.
     * @dev can only be called by whitelisted strategies (KEEPER role)
     * @dev reverts if management window is closed.
     * @param assets the amount of tokens to pull
     */
    function pull(uint256 assets) external;

    /**
     * Deposits funds from Strategy (both profits and principal amounts).
     * @dev can only be called by whitelisted strategies (KEEPER role)
     * @dev reverts if management window is closed.
     * @param assets the amount of Assets being deposited from the strategy.
     */
    function depositStrategyFunds(uint256 assets) external;

    // ============================= Admin functions ================================

    /**
     * Sets the max deposit `amount` for vault. Akin to setting vault cap in v2 vaults.
     * Since we will not be limiting deposits per user there is no need to add `receiver` input
     * in the argument.
     */
    function setVaultCap(uint256 amount) external;

    /**
     * Adds a strategy to the whitelist.
     * @dev can only be called by governor (GOVERNOR role)
     * @param _address of the strategy to whitelist
     */
    function whitelistStrategy(address _address) external;

    /**
     * Removes a strategy from the whitelist.
     * @dev can only be called by governor (GOVERNOR role)
     * @param _address of the strategy to remove from whitelist
     */
    function removeStrategyFromWhitelist(address _address) external;

    /**
     * @notice Adds a contract to the whitelist.
     * @dev By default only EOA cann interact with the vault.
     * @dev Whitelisted contracts will be able to interact with the vault too.
     * @param contractAddress The address of the contract to whitelist.
     */
    function addContractAddressToWhitelist(address contractAddress) external;

    /**
     * @notice Used to check wheter a contract address is whitelisted to use the vault
     * @param _contractAddress The address of the contract to check
     * @return `true` if the contract is whitelisted, `false` otherwise
     */
    function whitelistedContract(address _contractAddress)
        external
        view
        returns (bool);

    /**
     * @notice Removes a contract from the whitelist.
     * @dev Removed contracts wont be able to interact with the vault.
     * @param contractAddress The address of the contract to whitelist.
     */
    function removeContractAddressFromWhitelist(address contractAddress)
        external;

    /**
     * Migrate vault to new vault contract.
     * @dev acts as emergency withdrawal if needed.
     * @dev can only be called by governor (GOVERNOR role)
     * @param _to New vault contract address.
     * @param _tokens Addresses of tokens to be migrated.
     *
     */
    function migrate(address _to, address[] memory _tokens) external;

    /**
     * Deposits and withdrawals close, assets are under vault control.
     * @dev can only be called by governor (GOVERNOR role)
     */
    function openManagementWindow() external;

    /**
     * Open vault for deposits and claims.
     * @dev can only be called by governor (GOVERNOR role)
     */
    function closeManagementWindow() external;

    /**
     * Open vault for deposits and claims, sets the snapshot of assets balance manually
     * @dev can only be called by governor (GOVERNOR role)
     * @dev can only be called on `State.INITIAL`
     * @param _snapshotAssetBalance Overrides the value of the snapshotted asset balance
     * @param _snapshotShareSupply Overrides the value of the snapshotted share supply
     */
    function initialRun(
        uint256 _snapshotAssetBalance,
        uint256 _snapshotShareSupply
    ) external;

    /**
     * Enable/diable charging performance & management fees
     * @dev can only be called by GOVERNOR role
     * @param _status `true` if the vault should charge fees, `false` otherwise
     */
    function setChargeFees(bool _status) external;

    /**
     * Updated the fee distributor address
     * @dev can only be called by GOVERNOR role
     * @param _feeDistributor The address of the new fee distributor
     */
    function setFeeDistributor(address _feeDistributor) external;

    // ============================= Enums =================================

    /**
     * Enum to represent the current state of the vault
     * INITIAL = Right after deployment, can move to `UNMANAGED` by calling `initialRun`
     * UNMANAGED = Users are able to interact with the vault, can move to `MANAGED` by calling `openManagementWindow`
     * MANAGED = Strategies will be able to borrow & repay, can move to `UNMANAGED` by calling `closeManagementWindow`
     */
    enum State {
        INITIAL,
        UNMANAGED,
        MANAGED
    }

    // ============================= Events ================================

    /**
     * `caller` has exchanged `assets` for `shares`, and transferred those `shares` to `owner`.
     * Emitted when tokens are deposited into the Vault via the `mint` and `deposit` methods.
     */
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * `caller` has exchanged `shares`, owned by `owner`, for `assets`, and transferred those `assets` to `receiver`.
     * Will be emitted when shares are withdrawn from the Vault in `ERC4626.redeem` or `ERC4626.withdraw` methods.
     */
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * emitted when vault balance snapshot is taken
     * @param _timestamp snapshot timestamp (indexed)
     * @param _vaultBalance vault balance value
     * @param _jonesAssetSupply jDPX total supply value
     */
    event Snapshot(
        uint256 indexed _timestamp,
        uint256 _vaultBalance,
        uint256 _jonesAssetSupply
    );

    /**
     * emitted when asset management window is opened
     * @param _timestamp snapshot timestamp (indexed)
     * @param _assetBalance new vault balance value
     * @param _shareSupply share token total supply at this time
     */
    event EpochStarted(
        uint256 indexed _timestamp,
        uint256 _assetBalance,
        uint256 _shareSupply
    );

    /** emitted when claim and deposit windows are open
     * @param _timestamp snapshot timestamp (indexed)
     * @param _assetBalance new vault balance value
     * @param _shareSupply share token total supply at this time
     */
    event EpochEnded(
        uint256 indexed _timestamp,
        uint256 _assetBalance,
        uint256 _shareSupply
    );

    // ============================= Errors ================================
    error MSG_SENDER_NOT_WHITELISTED_USER();
    error DEPOSIT_ASSET_AMOUNT_EXCEEDS_MAX_DEPOSIT();
    error MINT_SHARE_AMOUNT_EXCEEDS_MAX_MINT();
    error ZERO_SHARES_AVAILABLE_WHEN_DEPOSITING();
    error INVALID_STATE(State _expected, State _actual);
    error INVALID_ASSETS_AMOUNT();
    error INVALID_SHARES_AMOUNT();
    error CONTRACT_ADDRESS_MAKING_PROHIBITED_FUNCTION_CALL();
    error INVALID_ADDRESS();
    error INVALID_SNAPSHOT_VALUE();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IGMXVault {
    function whitelistedTokens(address) external view returns (bool);

    function stableTokens(address) external view returns (bool);

    function shortableTokens(address) external view returns (bool);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IGMXOrderBook {
    struct IncreaseOrder {
        address account;
        address purchaseToken;
        uint256 purchaseTokenAmount;
        address collateralToken;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
    }

    struct DecreaseOrder {
        address account;
        address collateralToken;
        uint256 collateralDelta;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
    }

    function minExecutionFee() external view returns (uint256);

    function increaseOrdersIndex(address) external view returns (uint256);

    function decreaseOrdersIndex(address) external view returns (uint256);

    function increaseOrders(address, uint256 _orderIndex)
        external
        view
        returns (IncreaseOrder memory);

    function decreaseOrders(address, uint256 _orderIndex)
        external
        view
        returns (DecreaseOrder memory);

    function createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable;

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable;

    function cancelIncreaseOrder(uint256 _orderIndex) external;

    function cancelDecreaseOrder(uint256 _orderIndex) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IGMXPositionManager {
    function increasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) external;

    function decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) external;

    function setPartner(address _account, bool _isActive) external;

    function setOrderKeeper(address _account, bool _isActive) external;

    function executeIncreaseOrder(
        address _account,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external;

    function executeDecreaseOrder(
        address _account,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external;
}