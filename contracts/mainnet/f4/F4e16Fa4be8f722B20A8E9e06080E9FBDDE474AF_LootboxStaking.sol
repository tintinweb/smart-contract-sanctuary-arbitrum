// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "../interfaces/IEmergencyMode.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ILootboxStaking.sol";
import "../interfaces/IOperatorOwned.sol";
import "../interfaces/IToken.sol";

import "../interfaces/ICamelotRouter.sol";
import "../interfaces/ICamelotPair.sol";

import "../interfaces/ISushiswapPool.sol";
import "../interfaces/ISushiswapBentoBox.sol";

import "./openzeppelin/SafeERC20.sol";

/*
 * Network(s): Ethereum & Arbitrum
 *
 * * Supported LP Tokens for assets:
 * - fUSDC/ETH
 * - fUSDC/USDC
 *
 * * In the following protocols:
 * - Camelot
 * - SushiSwap
 *
 * Divided 50/50
*/

uint256 constant MAX_UINT256 = type(uint256).max;

uint256 constant MIN_LOCKUP_TIME = 31 days;

uint256 constant MAX_LOCKUP_TIME = 365 days;

uint256 constant MAX_SLIPPAGE = 100;

contract LootboxStaking is ILootboxStaking, IOperatorOwned, IEmergencyMode {
    using SafeERC20 for IERC20;

    uint8 private version_;

    address private operator_;

    address private emergencyCouncil_;

    bool private noEmergencyMode_;

    IERC20 public fusdc_;

    IERC20 public weth_;

    IERC20 public usdc_;

    ICamelotRouter public camelotRouter_;

    ISushiswapBentoBox public sushiswapBentoBox_;

    // we don't use a sushiswap router since it doesn't do much aside from
    // check amounts

    ISushiswapPool private sushiswapFusdcUsdcPool_;

    ISushiswapPool private sushiswapFusdcWethPool_;

    ICamelotPair private camelotFusdcUsdcPair_;

    ICamelotPair private camelotFusdcWethPair_;

    mapping (address => Deposit[]) private deposits_;

    // lp tokens provided by users that we don't touch

    uint256 private camelotFusdcUsdcDepositedLpTokens_;

    uint256 private camelotFusdcWethDepositedLpTokens_;

    uint256 private sushiswapFusdcUsdcDepositedLpTokens_;

    uint256 private sushiswapFusdcWethDepositedLpTokens_;

    /// @dev fusdcMinLiquidity_ of fusdc, is one decimal unit
    uint256 private fusdcMinLiquidity_;

    /// @dev usdcMinLiquidity_ of usdc, is one decimal unit
    uint256 private usdcMinLiquidity_;

    /// @dev wethMinLiquidity_ of weth, is one decimal unit
    uint256 private wethMinLiquidity_;

    function init(
        address _operator,
        address _emergencyCouncil,
        IERC20 _fusdc,
        IERC20 _usdc,
        IERC20 _weth,
        ICamelotRouter _camelotRouter,
        ISushiswapBentoBox _sushiswapBentoBox,
        ICamelotPair _camelotFusdcUsdcPair,
        ICamelotPair _camelotFusdcWethPair,
        ISushiswapPool _sushiswapFusdcUsdcPool,
        ISushiswapPool _sushiswapFusdcWethPool
    ) public {
        require(version_ == 0, "already initialised");

        version_ = 1;

        operator_ = _operator;
        emergencyCouncil_ = _emergencyCouncil;

        noEmergencyMode_ = true;

        fusdc_ = _fusdc;
        usdc_ = _usdc;
        weth_ = _weth;

        camelotRouter_ = _camelotRouter;

        sushiswapBentoBox_ = _sushiswapBentoBox;

        camelotFusdcUsdcPair_ = _camelotFusdcUsdcPair;

        camelotFusdcWethPair_ = _camelotFusdcWethPair;

        sushiswapFusdcUsdcPool_ = _sushiswapFusdcUsdcPool;

        sushiswapFusdcWethPool_ = _sushiswapFusdcWethPool;

        fusdcMinLiquidity_ = fusdc_.decimals();

        usdcMinLiquidity_ = usdc_.decimals();

        wethMinLiquidity_ = weth_.decimals();

        require(fusdcMinLiquidity_ == usdcMinLiquidity_, "fusdc&usdc must be same dec");

        // assumes that weth > usdc and fusdc

        _enableApprovals();
    }

    /**
     * @notice migrateV2 sets the approvals back up
     */
    function migrateV2() public {
        require(msg.sender == operator_, "only operator");
        require(version_ == 1, "already init");

        version_ = 2;

        _disableApprovals();
        _enableApprovals();
    }

    /* ~~~~~~~~~~ INTERNAL DEPOSIT FUNCTIONS ~~~~~~~~~~ */

    function _depositToCamelotRouter(
        ICamelotRouter _router,
        address _tokenA,
        address _tokenB,
        uint256 _tokenAAmount,
        uint256 _tokenBAmount,
        uint256 _tokenAAmountMin,
        uint256 _tokenBAmountMin
    ) internal returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
     ) {
        return _router.addLiquidity(
            _tokenA,
            _tokenB,
            _tokenAAmount,
            _tokenBAmount,
            _tokenAAmountMin,
            _tokenBAmountMin,
            address(this),
            block.timestamp
        );
    }

    function _depositToSushiswapPool(
        ISushiswapPool _pool,
        IERC20 _tokenA,
        IERC20 _tokenB,
        uint256 _tokenAAmount,
        uint256 _tokenBAmount
    ) internal returns (uint256 liquidity) {
        // we don't track the liquidity from the bentobox since it's transferred
        // to the pool which then returns it's liquidity

        sushiswapBentoBox_.deposit(
            _tokenA,
            address(this),
            address(_pool),
            _tokenAAmount,
            0
        );

        sushiswapBentoBox_.deposit(
            _tokenB,
            address(this),
            address(_pool),
            _tokenBAmount,
            0
        );

        liquidity = _pool.mint(abi.encode(address(this)));

        return liquidity;
    }

    function _calculateWeights(
        uint256 _tokenAAmount,
        uint256 _tokenBAmount
    ) internal pure returns (
        uint256 camelotTokenA,
        uint256 sushiTokenA,

        uint256 camelotTokenB,
        uint256 sushiTokenB
    ) {
        camelotTokenA = _tokenAAmount / 2;
        camelotTokenB = _tokenBAmount / 2;

        // we take from the original amount so we don't end up with dust

        return (
            camelotTokenA,
            _tokenAAmount - camelotTokenA, // sushiswap

            camelotTokenB,
            _tokenBAmount - camelotTokenB // sushiswap
        );
    }

    function _calculateSlippage(
        uint256 _x,
        uint256 _slippage
    ) internal pure returns (uint256) {
        return ((_x * _slippage) / 100);
    }

    function _hasEnoughWethLiquidity(
        uint256 _fusdcAmount,
        uint256 _wethAmount
    ) internal view returns (bool) {
        return _fusdcAmount + 1 > fusdcMinLiquidity_ && _wethAmount + 1 > wethMinLiquidity_;
    }

    function _depositTokens(
        IERC20 _tokenA,
        IERC20 _tokenB,
        ISushiswapPool _sushiswapPool,
        uint256 _tokenAAmount,
        uint256 _tokenBAmount,
        uint256 _slippage
    ) internal returns (Deposit memory dep) {
        (
            uint256 camelotTokenA,
            uint256 sushiTokenA,

            uint256 camelotTokenB,
            uint256 sushiTokenB
        ) = _calculateWeights(_tokenAAmount, _tokenBAmount);

        // deposit on camelot

        uint256 camelotTokenAMin =
            camelotTokenA - _calculateSlippage(camelotTokenA, _slippage);

        uint256 camelotTokenBMin =
            camelotTokenB - _calculateSlippage(camelotTokenB, _slippage);

        (
            dep.camelotTokenA,
            dep.camelotTokenB,
            dep.camelotLpMinted
        ) = _depositToCamelotRouter(
            camelotRouter_,
            address(_tokenA),
            address(_tokenB),
            camelotTokenA,
            camelotTokenB,
            camelotTokenAMin,
            camelotTokenBMin
        );

        // deposit it on sushiswap

        dep.sushiswapLpMinted = _depositToSushiswapPool(
            _sushiswapPool,
            _tokenA,
            _tokenB,
            sushiTokenA,
            sushiTokenB
        );

        dep.sushiswapTokenA = sushiTokenA;
        dep.sushiswapTokenB = sushiTokenB;

        return dep;
    }

    function _deposit(
        uint256 _lockupLength,
        uint256 _fusdcAmount,
        uint256 _tokenBAmount,
        uint256 _slippage,
        address _sender,
        IERC20 _tokenB,
        bool _fusdcUsdcPair
    ) internal returns (
        uint256 tokenADeposited,
        uint256 tokenBDeposited
    ) {
        require(noEmergencyMode_, "emergency mode!");

        uint256 tokenABefore = fusdc_.balanceOf(address(this));

        uint256 tokenBBefore = _tokenB.balanceOf(address(this));

	require(
	    fusdc_.allowance(_sender, address(this)) >= _fusdcAmount,
	    "allowance needed"
	);

	require(
	    _tokenB.allowance(_sender, address(this)) >=
	    _tokenBAmount, "allowance needed"
	);

        fusdc_.transferFrom(_sender, address(this), _fusdcAmount);

        _tokenB.transferFrom(_sender, address(this), _tokenBAmount);

        Deposit memory dep = _depositTokens(
            fusdc_,
            _fusdcUsdcPair ? usdc_ : weth_,
            _fusdcUsdcPair ? sushiswapFusdcUsdcPool_ : sushiswapFusdcWethPool_,
            _fusdcAmount,
            _tokenBAmount,
            _slippage
        );

        dep.redeemTimestamp = _lockupLength + block.timestamp;
        dep.depositTimestamp = block.timestamp;

        uint256 tokenAMin = _calculateSlippage(_fusdcAmount, _slippage);
        uint256 tokenBMin = _calculateSlippage(_tokenBAmount, _slippage);

        dep.fusdcUsdcPair = _fusdcUsdcPair;

        uint256 tokenAAfter = fusdc_.balanceOf(address(this));

        uint256 tokenBAfter = _tokenB.balanceOf(address(this));

        deposits_[_sender].push(dep);

        uint256 tokenARemaining = tokenAAfter - tokenABefore;

        uint256 tokenBRemaining = tokenBAfter - tokenBBefore;

        // revert if the minimum was not consumed

        require(tokenAMin + 1 > tokenARemaining, "fusdc minimum not consumed");

        require(tokenBMin + 1 > tokenBRemaining, "token b minimum not consumed");

        // refund the user any amounts not used

        if (tokenARemaining > 0) fusdc_.transfer(_sender, tokenARemaining);

        if (tokenBRemaining > 0) _tokenB.transfer(_sender, tokenBRemaining);

        // return the amount that we deposited

        tokenADeposited = dep.camelotTokenA + dep.sushiswapTokenA;

        tokenBDeposited = dep.camelotTokenB + dep.sushiswapTokenB;

        if (_fusdcUsdcPair) {
            camelotFusdcUsdcDepositedLpTokens_ += dep.camelotLpMinted;
            sushiswapFusdcUsdcDepositedLpTokens_ += dep.sushiswapLpMinted;
        } else {
            camelotFusdcWethDepositedLpTokens_ += dep.camelotLpMinted;
            sushiswapFusdcWethDepositedLpTokens_ += dep.sushiswapLpMinted;
        }

        return (tokenADeposited, tokenBDeposited);
    }

    /* ~~~~~~~~~~ INTERNAL REDEEM FUNCTIONS ~~~~~~~~~~ */

    function _redeemFromCamelotRouter(
        ICamelotRouter _router,
        IERC20 _tokenB,
        uint256 _lpTokens,
        address _recipient
    ) internal returns (
        uint256 tokenARedeemed,
        uint256 tokenBRedeemed
    ) {
        return _router.removeLiquidity(
            address(fusdc_),
            address(_tokenB),
            _lpTokens,
            0,
            0,
            _recipient,
            block.timestamp
        );
    }

    function _redeemFromSushiswapPool(
        ISushiswapPool _pool,
        uint256 _lpTokens,
        address _recipient
    ) internal {
        _pool.transfer(address(_pool), _lpTokens);

        // unwrap the bento (the true) so we get the funds back to the user
        _pool.burn(abi.encode(_recipient, true));
    }

    function _deleteDeposit(address _sender, uint _depositId) internal {
        deposits_[_sender][_depositId] =
            deposits_[_sender][deposits_[_sender].length - 1];

        deposits_[_sender].pop();
    }

    function _redeemCamelotSushiswap(
        Deposit memory dep,
        bool _fusdcUsdcPair,
        address _recipient
    ) internal {
        _redeemFromCamelotRouter(
            camelotRouter_,
            _fusdcUsdcPair ? usdc_ : weth_,
            dep.camelotLpMinted,
            _recipient
        );

        _redeemFromSushiswapPool(
            _fusdcUsdcPair ? sushiswapFusdcUsdcPool_ : sushiswapFusdcWethPool_,
            dep.sushiswapLpMinted,
            _recipient
        );
    }

    /* ~~~~~~~~~~ EXTERNAL FUNCTIONS ~~~~~~~~~~ */

    /// @inheritdoc ILootboxStaking
    function deposit(
        uint256 _lockupLength,
        uint256 _fusdcAmount,
        uint256 _usdcAmount,
        uint256 _wethAmount,
        uint256 _slippage,
        uint256 _maxTimestamp
    ) external returns (
        uint256 fusdcDeposited,
        uint256 usdcDeposited,
        uint256 wethDeposited
    ) {
        require(noEmergencyMode_, "emergency mode");

        if (_maxTimestamp == 0) _maxTimestamp = block.timestamp;

        require(block.timestamp <= _maxTimestamp + 1, "exceeded time");

        require(_lockupLength + 1 > MIN_LOCKUP_TIME, "lockup length too low");
        require(_lockupLength < MAX_LOCKUP_TIME + 1, "lockup length too high");

        require(_slippage < MAX_SLIPPAGE + 1, "slippage too high");

        // the ui should restrict the deposits to more than 1e18

        bool fusdcUsdcPair =
            _fusdcAmount + 1 > fusdcMinLiquidity_ && _usdcAmount + 1 > usdcMinLiquidity_;

        // take the amounts given, and allocate half to camelot and half to
        // sushiswap

        require(
            fusdcUsdcPair || _hasEnoughWethLiquidity(_fusdcAmount, _wethAmount),
            "not enough liquidity"
        );

        uint256 tokenBAmount = fusdcUsdcPair ? _usdcAmount : _wethAmount;

        IERC20 tokenB = fusdcUsdcPair ? usdc_ : weth_;

        (uint256 tokenASpent, uint256 tokenBSpent) = _deposit(
            _lockupLength,
            _fusdcAmount,
            tokenBAmount,
            _slippage,
            msg.sender,
            tokenB,
            fusdcUsdcPair
        );

        require(tokenASpent > 0, "0 of token A was consumed");
        require(tokenBSpent > 0, "0 of token B was consumed");

        if (fusdcUsdcPair) usdcDeposited = tokenBSpent;

        else wethDeposited = tokenBSpent;

        emit Deposited(
            msg.sender,
            _lockupLength,
            block.timestamp,
            tokenASpent,
            usdcDeposited,
            wethDeposited
        );

        return (tokenASpent, usdcDeposited, wethDeposited);
    }

    /// @inheritdoc ILootboxStaking
    function redeem(
        uint256 _maxTimestamp,
        uint256 _fusdcMinimum,
        uint256 _usdcMinimum,
        uint256 _wethMinimum
    ) public returns (
        uint256 fusdcRedeemed,
        uint256 usdcRedeemed,
        uint256 wethRedeemed
    ) {
        require(noEmergencyMode_, "emergency mode");

        if (_maxTimestamp == 0) _maxTimestamp = block.timestamp;

        require(block.timestamp <= _maxTimestamp + 1, "exceeded time");

        Deposit memory dep;

        for (uint i = deposits_[msg.sender].length; i > 0;) {
            --i;

            dep = deposits_[msg.sender][i];

            // if the deposit we're looking at isn't finished then short circuit

            if (dep.redeemTimestamp + 1 > block.timestamp)
                continue;

            bool fusdcUsdcPair = dep.fusdcUsdcPair;

            uint256 fusdcBefore = fusdc_.balanceOf(msg.sender);

            uint256 usdcBefore = usdc_. balanceOf(msg.sender);

            uint256 wethBefore = weth_.balanceOf(msg.sender);

            _redeemCamelotSushiswap(dep, fusdcUsdcPair, msg.sender);

            // assumes that the user will always receive some amount from the pools
            uint256 tokenARedeemed = fusdc_.balanceOf(msg.sender) - fusdcBefore;

            uint256 tokenBRedeemed = 0;

            if (fusdcUsdcPair) tokenBRedeemed = usdc_.balanceOf(msg.sender) - usdcBefore;

            else tokenBRedeemed = weth_.balanceOf(msg.sender) - wethBefore;

            if (fusdcUsdcPair) {
                camelotFusdcUsdcDepositedLpTokens_ -= dep.camelotLpMinted;
                sushiswapFusdcUsdcDepositedLpTokens_ -= dep.sushiswapLpMinted;
            } else {
                camelotFusdcWethDepositedLpTokens_ -= dep.camelotLpMinted;
                sushiswapFusdcWethDepositedLpTokens_ -= dep.sushiswapLpMinted;
            }

            fusdcRedeemed += tokenARedeemed;

            if (fusdcUsdcPair) usdcRedeemed += tokenBRedeemed;

            else wethRedeemed += tokenBRedeemed;

            // iterating in reverse, then deleting the deposit will let us remove
            // unneeded deposits in memory

            emit Redeemed(
                msg.sender,
                dep.redeemTimestamp,
                block.timestamp,
                tokenARedeemed,
                fusdcUsdcPair ? tokenBRedeemed : 0,
                fusdcUsdcPair ? 0 : tokenBRedeemed
            );

            _deleteDeposit(msg.sender, i);
        }

        require(fusdcRedeemed + 1 > _fusdcMinimum, "fusdc redeemed too low");

        require(usdcRedeemed + 1 > _usdcMinimum, "usdc redeemed too low");

        require(wethRedeemed + 1 > _wethMinimum, "weth redeemed too low");

        return (fusdcRedeemed, usdcRedeemed, wethRedeemed);
    }

    /// @inheritdoc ILootboxStaking
    function deposits(address _spender) public view returns (Deposit[] memory) {
        return deposits_[_spender];
    }

    /// @inheritdoc ILootboxStaking
    function ratios() public view returns (
        uint256 fusdcUsdcRatio,
        uint256 fusdcWethRatio,
        uint256 fusdcUsdcSpread,
        uint256 fusdcWethSpread,
        uint256 fusdcUsdcLiq,
        uint256 fusdcWethLiq
    ) {
        (
            uint256 camelotFusdcUsdcRatio,
            uint256 camelotFusdcWethRatio,
            uint256 camelotFusdcUsdcLiq,
            uint256 camelotFusdcWethLiq
        ) =  _camelotRatios();

        (
            uint256 sushiswapFusdcUsdcRatio,
            uint256 sushiswapFusdcWethRatio,
            uint256 sushiswapFusdcUsdcLiq,
            uint256 sushiswapFusdcWethLiq
        ) = _sushiswapRatios();

        fusdcUsdcRatio =  (camelotFusdcUsdcRatio + sushiswapFusdcUsdcRatio) / 2;

        fusdcWethRatio = (camelotFusdcWethRatio + sushiswapFusdcWethRatio) / 2;

        if (camelotFusdcUsdcRatio > sushiswapFusdcUsdcRatio)
            fusdcUsdcSpread = camelotFusdcUsdcRatio - sushiswapFusdcUsdcRatio;
        else
            fusdcUsdcSpread = sushiswapFusdcUsdcRatio - camelotFusdcUsdcRatio;

        if (camelotFusdcWethRatio > sushiswapFusdcWethRatio)
            fusdcWethSpread = camelotFusdcWethRatio - sushiswapFusdcWethRatio;
        else
            fusdcWethSpread = sushiswapFusdcWethRatio - camelotFusdcWethRatio;

        fusdcUsdcLiq = camelotFusdcUsdcLiq + sushiswapFusdcUsdcLiq;

        fusdcWethLiq = camelotFusdcWethLiq + sushiswapFusdcWethLiq;

        return (
            fusdcUsdcRatio,
            fusdcWethRatio,
            fusdcUsdcSpread,
            fusdcWethSpread,
            fusdcUsdcLiq,
            fusdcWethLiq
        );
    }

    /* ~~~~~~~~~~ INTERNAL APPROVAL FUNCTIONS ~~~~~~~~~~ */

    function _enableApprovals() internal {
        fusdc_.safeApprove(address(camelotRouter_), MAX_UINT256);
        usdc_.safeApprove(address(camelotRouter_), MAX_UINT256);
        weth_.safeApprove(address(camelotRouter_), MAX_UINT256);

        // can't use safe approve for the pairs

        camelotFusdcUsdcPair_.approve(address(camelotRouter_), MAX_UINT256);
        camelotFusdcWethPair_.approve(address(camelotRouter_), MAX_UINT256);

        fusdc_.safeApprove(address(sushiswapBentoBox_), MAX_UINT256);
        usdc_.safeApprove(address(sushiswapBentoBox_), MAX_UINT256);
        weth_.safeApprove(address(sushiswapBentoBox_), MAX_UINT256);
    }

    function _disableApprovals() internal {
        fusdc_.safeApprove(address(camelotRouter_), 0);
        usdc_.safeApprove(address(camelotRouter_), 0);
        weth_.safeApprove(address(camelotRouter_), 0);

        camelotFusdcUsdcPair_.approve(address(camelotRouter_), 0);
        camelotFusdcWethPair_.approve(address(camelotRouter_), 0);

        fusdc_.safeApprove(address(sushiswapBentoBox_), 0);
        usdc_.safeApprove(address(sushiswapBentoBox_), 0);
        weth_.safeApprove(address(sushiswapBentoBox_), 0);
    }

    /* ~~~~~~~~~~ INTERNAL MISC FUNCTIONS ~~~~~~~~~~ */

    function _camelotPairReserves(
        ICamelotPair _pair,
        IERC20 _tokenB
    ) internal view returns (
        uint256 reserveA,
        uint256 reserveB
    ) {
        (uint112 reserve0_, uint112 reserve1_,,) = _pair.getReserves();

        uint256 reserve0 = uint256(reserve0_);

        uint256 reserve1 = uint256(reserve1_);

        (reserveA, reserveB) =
          address(fusdc_) < address(_tokenB)
              ? (reserve0, reserve1)
              : (reserve1, reserve0);

        return (reserveA, reserveB);
    }

    function _sushiswapPoolReserves(
        ISushiswapPool _pool,
        IERC20 _tokenB
    ) internal view returns (
        uint256 reserveA,
        uint256 reserveB
    ) {
        (uint256 reserve0, uint256 reserve1) = _pool.getNativeReserves();

        (reserveA, reserveB) =
          address(fusdc_) < address(_tokenB)
              ? (reserve0, reserve1)
              : (reserve1, reserve0);

        return (reserveA, reserveB);
    }

    function _camelotRatios() internal view returns (
        uint256 fusdcUsdcRatio,
        uint256 fusdcWethRatio,
        uint256 fusdcUsdcLiq,
        uint256 fusdcWethLiq
    ) {
        (uint256 camelotFusdcUsdcReserveA, uint256 camelotFusdcUsdcReserveB) =
            _camelotPairReserves(
                camelotFusdcUsdcPair_,
                usdc_
            );

        camelotFusdcUsdcReserveA *= 10 ** (wethMinLiquidity_ - fusdcMinLiquidity_);
        camelotFusdcUsdcReserveB *= 10 ** (wethMinLiquidity_ - fusdcMinLiquidity_);

        fusdcUsdcLiq = camelotFusdcUsdcReserveA + camelotFusdcUsdcReserveB;

        // if the information here is empty, then we provide a hardcoded ratio suggestion

        if (fusdcUsdcLiq != 0)
            fusdcUsdcRatio = 1e12 * camelotFusdcUsdcReserveA / fusdcUsdcLiq;

        else
            fusdcUsdcRatio = 500000000000; // 50 * 1e10


        (uint256 camelotFusdcWethReserveA, uint256 camelotFusdcWethReserveB) =
            _camelotPairReserves(
                camelotFusdcWethPair_,
                weth_
            );

        // exponentiate fudsc by the difference between it's decimals and
        // weth's for an equal calculation to get an accurate ratio

        camelotFusdcWethReserveA *= 10 ** (wethMinLiquidity_ - fusdcMinLiquidity_);

        fusdcWethLiq = camelotFusdcWethReserveA + camelotFusdcWethReserveB;

        if (fusdcWethLiq != 0)
            fusdcWethRatio = 1e12 * camelotFusdcWethReserveA / fusdcWethLiq;

        else
            fusdcWethRatio = 500000000000; // 50 * 1e10

        return (
            fusdcUsdcRatio,
            fusdcWethRatio,
            fusdcUsdcLiq,
            fusdcWethLiq
        );
    }

    function _sushiswapRatios() internal view returns (
        uint256 fusdcUsdcRatio,
        uint256 fusdcWethRatio,
        uint256 fusdcUsdcLiq,
        uint256 fusdcWethLiq
    ) {
        (uint256 sushiswapFusdcUsdcReserveA, uint256 sushiswapFusdcUsdcReserveB) =
            _sushiswapPoolReserves(
                sushiswapFusdcUsdcPool_,
                usdc_
            );

        sushiswapFusdcUsdcReserveA *= 10 ** (wethMinLiquidity_ - fusdcMinLiquidity_);
        sushiswapFusdcUsdcReserveB *= 10 ** (wethMinLiquidity_ - fusdcMinLiquidity_);

        fusdcUsdcLiq = sushiswapFusdcUsdcReserveA + sushiswapFusdcUsdcReserveB;

        if (fusdcUsdcLiq != 0)
            fusdcUsdcRatio = 1e12 * sushiswapFusdcUsdcReserveA / fusdcUsdcLiq;

        else
            fusdcUsdcRatio = 500000000000; // 50 * 1e10

        (uint256 sushiswapFusdcWethReserveA, uint256 sushiswapFusdcWethReserveB) =
            _sushiswapPoolReserves(
                sushiswapFusdcWethPool_,
                weth_
            );

        sushiswapFusdcWethReserveA *= 10 ** (wethMinLiquidity_ - fusdcMinLiquidity_);

        fusdcWethLiq = sushiswapFusdcWethReserveA + sushiswapFusdcWethReserveB;

        // if the liquidity in the pool is empty, then we provide a default suggestion

        if (fusdcWethLiq != 0)
            fusdcWethRatio = 1e12 * sushiswapFusdcWethReserveA / fusdcWethLiq;

        else
            fusdcWethRatio = 500000000000; // 50 * 1e10

        return (
            fusdcUsdcRatio,
            fusdcWethRatio,
            fusdcUsdcLiq,
            fusdcWethLiq
        );
    }

    /* ~~~~~~~~~~ EMERGENCY MODE ~~~~~~~~~~ */

    function disableEmergencyMode() public {
        require(msg.sender == operator_, "only operator");

        _enableApprovals();

        emit Emergency(false);

        noEmergencyMode_ = true;
    }

    function noEmergencyMode() public view returns (bool) {
        return noEmergencyMode_;
    }

    function emergencyCouncil() public view returns (address) {
        return emergencyCouncil_;
    }

    function enableEmergencyMode() public {
        require(
            msg.sender == operator_ ||
            msg.sender == emergencyCouncil_,
            "emergency only"
        );

        _disableApprovals();

        emit Emergency(true);

        noEmergencyMode_ = false;
    }

    function updateEmergencyCouncil(address _emergencyCouncil) public {
        require(msg.sender == operator_, "only operator");
        emergencyCouncil_ = _emergencyCouncil;
    }

    /* ~~~~~~~~~~ OPERATOR ~~~~~~~~~~ */

    function operator() public view returns (address) {
        return operator_;
    }

    function updateOperator(address _newOperator) public {
        require(msg.sender == operator_, "only operator");
        operator_ = _newOperator;
    }
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

interface IEmergencyMode {
    /// @notice emitted when the contract enters emergency mode!
    event Emergency(bool indexed status);

    /// @notice should be emitted when the emergency council changes
    ///         if this implementation supports that
    event NewCouncil(address indexed oldCouncil, address indexed newCouncil);

    /**
     * @notice enables emergency mode preventing the swapping in of tokens,
     * @notice and setting the rng oracle address to null
     */
    function enableEmergencyMode() external;

    /**
     * @notice disables emergency mode, following presumably a contract upgrade
     * @notice (operator only)
     */
    function disableEmergencyMode() external;

    /**
     * @notice emergency mode status (true if everything is okay)
     */
    function noEmergencyMode() external view returns (bool);

    /**
     * @notice emergencyCouncil address that can trigger emergency functions
     */
    function emergencyCouncil() external view returns (address);
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

interface ILootboxStaking {
    /**
     * @notice Deposit made by a user that's tracked internally
     * @dev tokenA is always fusdc in this code
     */
    struct Deposit {
        uint256 redeemTimestamp;

        uint256 camelotLpMinted;
        uint256 camelotTokenA;
        uint256 camelotTokenB;

        uint256 sushiswapLpMinted;
        uint256 sushiswapTokenA;
        uint256 sushiswapTokenB;

        bool fusdcUsdcPair;

        uint256 depositTimestamp;
    }

    event Deposited(
        address indexed spender,
        uint256 lockupLength,
        uint256 lockedTimestamp,
        uint256 fusdcAmount,
        uint256 usdcAmount,
        uint256 wethAmount
    );

    event Redeemed(
        address indexed spender,
        uint256 lockupLength,
        uint256 lockedTimestamp,
        uint256 fusdcAmount,
        uint256 usdcAmount,
        uint256 wethAmount
    );

    /**
     * @notice deposit a token pair (only usdc or weth)
     * @param _lockupLength to use as the amount of time until redemption is possible
     * @param _fusdcAmount to use as the amount of fusdc to deposit
     * @param _usdcAmount to use as the amount of usdc to deposit
     * @param _wethAmount to use as the amount of weth to deposit
     * @param _slippage to use to reduce the minimum deposit per platform
     * @param _maxTimestamp as the max amount of time in a timestamp
     */
    function deposit(
        uint256 _lockupLength,
        uint256 _fusdcAmount,
        uint256 _usdcAmount,
        uint256 _wethAmount,
        uint256 _slippage,
        uint256 _maxTimestamp
    ) external returns (
        uint256 fusdcDeposited,
        uint256 usdcDeposited,
        uint256 wethDeposited
    );

    /**
     * @notice redeem as many deposits as possible that are ready
     * @param _maxTimestamp to cancel this execution by if passed
     * @param _fusdcMinimum to revert with if fusdc is less than this
     * @param _usdcMinimum to revert with if usdc is less than this
     * @param _wethMinimum to revert with if weth is less
     */
    function redeem(
        uint256 _maxTimestamp,
        uint256 _fusdcMinimum,
        uint256 _usdcMinimum,
        uint256 _wethMinimum
    ) external returns (
        uint256 fusdcRedeemed,
        uint256 usdcRedeemed,
        uint256 wethRedeemed
    );

    /**
     * @notice deposits made by a specific address
     * @param _spender address to check
     */
    function deposits(address _spender) external view returns (Deposit[] memory);

    /**
     * @notice ratios available in the underlying pools - to find the
     *         ratio of the base asset subtract by 1e12
     */
    function ratios() external view returns (
        uint256 fusdcUsdcRatio,
        uint256 fusdcWethRatio,
        uint256 fusdcUsdcSpread,
        uint256 fusdcWethSpread,
        uint256 fusdcUsdcLiq,
        uint256 fusdcWethLiq
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.16;

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
     * @dev Returns the number of decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

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

// SPDX-License-Identifier: GPL

pragma solidity 0.8.16;
pragma abicoder v2;

interface IOperatorOwned {
    event NewOperator(address old, address new_);

    function operator() external view returns (address);
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "./IFluidClient.sol";
import "./ILiquidityProvider.sol";

import "./IERC20.sol";

interface IToken is IERC20 {
    /// @notice emitted when a reward is quarantined for being too large
    event BlockedReward(
        address indexed winner,
        uint256 amount,
        uint256 startBlock,
        uint256 endBlock
    );

    /// @notice emitted when a blocked reward is released
    event UnblockReward(
        bytes32 indexed originalRewardTx,
        address indexed winner,
        uint256 amount,
        uint256 startBlock,
        uint256 endBlock
    );

    /// @notice emitted when an underlying token is wrapped into a fluid asset
    event MintFluid(address indexed addr, uint256 amount);

    /// @notice emitted when a fluid token is unwrapped to its underlying asset
    event BurnFluid(address indexed addr, uint256 amount);

    /// @notice emitted when restrictions
    event MaxUncheckedRewardLimitChanged(uint256 amount);

    /// @notice updating the reward quarantine before manual signoff
    /// @notice by the multisig (with updateRewardQuarantineThreshold)
    event RewardQuarantineThresholdUpdated(uint256 amount);

    /// @notice emitted when a user is permitted to mint on behalf of another user
    event MintApproval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /// @notice emitted when an operator sets the burn fee (1%)
    event FeeSet(
        uint256 _originalMintFee,
        uint256 _newMintFee,
        uint256 _originalBurnFee,
        uint256 _newBurnFee
    );

    /**
     * @notice getter for the RNG oracle provided by `workerConfig_`
     * @return the address of the trusted oracle
     *
     * @dev individual oracles are now recorded in the operator, this
     *      now should return the registry contract
     */
    function oracle() external view returns (address);

    /**
     * @notice underlyingToken that this IToken wraps
     */
    function underlyingToken() external view returns (IERC20);

    /**
     * @notice underlyingLp that's in use for the liquidity provider
     */
    function underlyingLp() external view returns (ILiquidityProvider);

    /// @notice updates the reward quarantine threshold if called by the operator
    function updateRewardQuarantineThreshold(uint256) external;

    /**
     * @notice wraps `amount` of underlying tokens into fluid tokens
     * @notice requires you to have called the ERC20 `approve` method
     * @notice targeting this contract first on the underlying asset
     *
     * @param _amount the number of tokens to wrap
     * @return the number of tokens wrapped
     */
    function erc20In(uint256 _amount) external returns (uint256);

    /**
     * @notice erc20InTo wraps the `amount` given and transfers the tokens to `receiver`
     *
     * @param _recipient of the wrapped assets
     * @param _amount to wrap and send to the recipient
     */
    function erc20InTo(address _recipient, uint256 _amount) external returns (uint256);

    /**
     * @notice unwraps `amount` of fluid tokens back to underlying
     *
     * @param _amount the number of fluid tokens to unwrap
     */
    function erc20Out(uint256 _amount) external;

   /**
     * @notice unwraps `amount` of fluid tokens with the address as recipient
     *
     * @param _recipient to receive the underlying tokens to
     * @param _amount the number of fluid tokens to unwrap
     */
    function erc20OutTo(address _recipient, uint256 _amount) external;

   /**
     * @notice burns `amount` of fluid /without/ withdrawing the underlying
     *
     * @param _amount the number of fluid tokens to burn
     */
    function burnFluidWithoutWithdrawal(uint256 _amount) external;

    /**
     * @notice calculates the size of the reward pool (the interest we've earned)
     *
     * @return the number of tokens in the reward pool
     */
    function rewardPoolAmount() external returns (uint256);

    /**
     * @notice admin function, unblocks a reward that was quarantined for being too large
     * @notice allows for paying out or removing the reward, in case of abuse
     *
     * @param _user the address of the user who's reward was quarantined
     *
     * @param _amount the amount of tokens to release (in case
     *        multiple rewards were quarantined)
     *
     * @param _payout should the reward be paid out or removed?
     *
     * @param _firstBlock the first block the rewards include (should
     *        be from the BlockedReward event)
     *
     * @param _lastBlock the last block the rewards include
     */
    function unblockReward(
        bytes32 _rewardTx,
        address _user,
        uint256 _amount,
        bool _payout,
        uint256 _firstBlock,
        uint256 _lastBlock
    )
        external;

    /**
     * @notice return the max unchecked reward that's currently set
     */
    function maxUncheckedReward() external view returns (uint256);

    /// @notice upgrade the underlying ILiquidityProvider to a new source
    function upgradeLiquidityProvider(ILiquidityProvider newPool) external;

    /**
     * @notice drain the reward pool of the amount given without
     *         touching any principal amounts
     *
     * @dev this is intended to only be used to retrieve initial
     *       liquidity provided by the team OR by the DAO to allocate funds
     */
    function drainRewardPool(address _recipient, uint256 _amount) external;

    function setFeeDetails(uint256 _mintFee, uint256 _burnFee, address _recipient) external;
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

interface ICamelotRouter {
    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint _amountADesired,
        uint _amountBDesired,
        uint _amountAMin,
        uint _amountBMin,
        address _to,
        uint _deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint _deadline
    ) external returns (uint amountA, uint amountB);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint _amountIn,
        uint _amountOutMin,
        address[] calldata _path,
        address _to,
        address _referrer,
        uint _deadline
    ) external;
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "./IERC20.sol";

interface ICamelotPair is IERC20 {
    function getReserves() external view returns (
        uint112 reserve0,
        uint112 reserve1,
        uint16 token0FeePercent,
        uint16 token1
    );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;
pragma abicoder v2;

import "./IERC20.sol";

struct TokenAmount {
    address token;
    uint256 amount;
}

interface ISushiswapPool is IERC20 {
    function mint(bytes calldata _data) external returns (uint256 liquidity);

    function burn(bytes calldata _data) external returns (
        TokenAmount[] memory withdrawnAmounts
    );

    function swap(bytes calldata _data) external returns (uint256 amountOut);

    function getNativeReserves() external view returns (
        uint256 reserve0,
        uint256 reserve1
    );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;
pragma abicoder v2;

import "./IERC20.sol";

interface ISushiswapBentoBox {
    function deposit(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function withdraw(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function transfer(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _share
    ) external;

    function balanceOf(
        IERC20 _token,
        address _spender
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

// Adjusted to use our local IERC20 interface instead of OpenZeppelin's

pragma solidity ^0.8.0;

import "../../interfaces/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

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
    using AddressUpgradeable for address;

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
            "approve from non-zero"
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
            require(oldAllowance >= value, "allowance went below 0");
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
            require(abi.decode(returndata, (bool)), "erc20 op failed");
        }
    }
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

/// @dev parameter for the batchReward function
struct Winner {
    address winner;
    uint256 amount;
}

/// @dev returned from the getUtilityVars function to calculate distribution amounts
struct UtilityVars {
    uint256 poolSizeNative;
    uint256 tokenDecimalScale;
    uint256 exchangeRateNum;
    uint256 exchangeRateDenom;
    uint256 deltaWeightNum;
    uint256 deltaWeightDenom;
    string customCalculationType;
}

// DEFAULT_CALCULATION_TYPE to use as the value for customCalculationType if
// your utility doesn't have a worker override
string constant DEFAULT_CALCULATION_TYPE = "";

interface IFluidClient {

    /// @notice MUST be emitted when any reward is paid out
    event Reward(
        address indexed winner,
        uint amount,
        uint startBlock,
        uint endBlock
    );

    /**
     * @notice pays out several rewards
     * @notice only usable by the trusted oracle account
     *
     * @param rewards the array of rewards to pay out
     */
    function batchReward(Winner[] memory rewards, uint firstBlock, uint lastBlock) external;

    /**
     * @notice gets stats on the token being distributed
     * @return the variables for the trf
     */
    function getUtilityVars() external returns (UtilityVars memory);
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "./IERC20.sol";

/// @title generic interface around an interest source
interface ILiquidityProvider {
    /**
     * @notice getter for the owner of the pool (account that can deposit and remove from it)
     * @return address of the owning account
     */
    function owner_() external view returns (address);
    /**
     * @notice gets the underlying token (ie, USDt)
     * @return address of the underlying token
     */
    function underlying_() external view returns (IERC20);

    /**
     * @notice adds `amount` of tokens to the pool from the amount in the LiquidityProvider
     * @notice requires that the user approve them first
     * @param amount number of tokens to add, in the units of the underlying token
     */
    function addToPool(uint amount) external;
    /**
     * @notice removes `amount` of tokens from the pool
     * @notice sends the tokens to the owner
     * @param amount number of tokens to remove, in the units of the underlying token
     */
    function takeFromPool(uint amount) external;
    /**
     * @notice returns the total amount in the pool, counting the invested amount and the interest earned
     * @return the amount of tokens in the pool, in the units of the underlying token
     */
    function totalPoolAmount() external returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
}