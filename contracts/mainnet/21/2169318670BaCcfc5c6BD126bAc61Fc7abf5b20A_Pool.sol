// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import "./PoolStorage.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IMarket.sol";
import "../interfaces/IInterestLogic.sol";
import "../interfaces/IMarketPriceFeed.sol";

import "../token/ERC20.sol";
import "../libraries/SafeMath.sol";
import "../libraries/SignedSafeMath.sol";
import "../libraries/SafeCast.sol";
import "../libraries/ReentrancyGuard.sol";
import "../libraries/TransferHelper.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IInviteManager.sol";

contract Pool is ERC20, PoolStorage, ReentrancyGuard {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;

    constructor(
        address _manager,
        address _baseAsset,
        address _WETH,
        string memory _lpTokenName,
        string memory _lpTokenSymbol
    )ERC20(_manager){
        vault = IManager(_manager).vault();
        require(
            _baseAsset != address(0)
            && bytes(_lpTokenName).length != 0
            && _WETH != address(0)
            && _manager != address(0)
            && vault != address(0),
            "PC0"
        );

        baseAsset = _baseAsset;
        baseAssetDecimals = IERC20(_baseAsset).decimals();
        name = _lpTokenName;
        symbol = _lpTokenSymbol;
        WETH = _WETH;
    }
    modifier _onlyMarket(){
        require(isMarket[msg.sender], 'PMM');
        _;
    }

    modifier _onlyRouter(){
        require(IManager(manager).checkRouter(msg.sender), 'PMR');
        _;
    }

    modifier _onlyExecutor(){
        require(IManager(manager).checkExecutorRouter(msg.sender), 'PME');
        _;
    }

    modifier whenNotAddPaused() {
        require(!IManager(manager).paused() && !addPaused, "PMW");
        _;
    }

    modifier whenNotRemovePaused() {
        require(!IManager(manager).paused() && !removePaused, "PMWR");
        _;
    }

    function registerMarket(
        address _market
    ) external returns (bool){
        require(msg.sender == manager && !isMarket[_market], "PR0");
        isMarket[_market] = true;
        marketList.push(_market);
        MarketConfig storage args = marketConfigs[_market];
        args.marketType = IMarket(_market).marketType();
        emit RegisterMarket(_market);
        return true;
    }

    /// @notice update pool data when an order with types of open or trigger open is executed
    function openUpdate(IPool.UpdateParams memory params) external _onlyMarket {
        address _market = msg.sender;
        require(!clearAll && canOpen(_market, params.makerMargin), "PO0");
        DataByMarket storage marketData = poolDataByMarkets[_market];
        marketData.takerTotalMargin = marketData.takerTotalMargin.add(params.takerMargin);

        balance = balance.add(params.makerFee.toInt256());
        balanceReal = balanceReal.add(params.makerFee.toInt256());
        marketData.cumulativeFee = marketData.cumulativeFee.add(params.makerFee);
        balance = balance.sub(params.makerMargin.toInt256());
        interestData[params.takerDirection].totalBorrowShare = interestData[params.takerDirection].totalBorrowShare.add(params.deltaDebtShare);
        
        if (params.takerDirection == 1) {
            marketData.longMakerFreeze = marketData.longMakerFreeze.add(params.makerMargin);
            marketData.longAmount = marketData.longAmount.add(params.amount);
            marketData.longOpenTotal = marketData.longOpenTotal.add(params.total);
        } else {
            marketData.shortMakerFreeze = marketData.shortMakerFreeze.add(params.makerMargin);
            marketData.shortAmount = marketData.shortAmount.add(params.amount);
            marketData.shortOpenTotal = marketData.shortOpenTotal.add(params.total);
        }
        _marginToVault(params.marginToVault);
        _feeToExchange(params.feeToExchange);
        _vaultTransfer(params.inviter, params.feeToInviter, baseAsset == WETH);

        GlobalHf memory g = _checkPoolStatus(false);

        emit OpenUpdate(
            params.orderId,
            _market,
            params.taker,
            params.inviter,
            params.feeToExchange,
            params.makerFee,
            params.feeToInviter,
            g.sharePrice,
            marketData.shortOpenTotal,
            marketData.longOpenTotal
        );
    }

    /// @notice update pool data when an order with types of close or trigger close is executed
    function closeUpdate(IPool.UpdateParams memory params) external _onlyMarket {
        DataByMarket storage marketData = poolDataByMarkets[msg.sender];
        marketData.cumulativeFee = marketData.cumulativeFee.add(params.makerFee);
        balance = balance.add(params.makerFee.toInt256());
        balanceReal = balanceReal.add(params.makerFee.toInt256());

        marketData.rlzPNL = marketData.rlzPNL.add(params.makerProfit);
        marketData.interestPayment = marketData.interestPayment.add(params.payInterest);
        {
            int256 tempProfit = params.makerProfit.add(params.makerMargin.toInt256()).add(params.fundingPayment);
            require(tempProfit >= 0, 'PCU0');

            balance = tempProfit.add(balance).add(params.payInterest.toInt256());
            balanceReal = params.makerProfit.add(params.fundingPayment).add(params.payInterest.toInt256()).add(balanceReal);
        }

        require(marketData.takerTotalMargin >= params.takerMargin, 'PCU1');
        marketData.takerTotalMargin = marketData.takerTotalMargin.sub(params.takerMargin);
        interestData[params.takerDirection].totalBorrowShare = interestData[params.takerDirection].totalBorrowShare.sub(params.deltaDebtShare);
        if (params.fundingPayment != 0) marketData.makerFundingPayment = marketData.makerFundingPayment.sub(params.fundingPayment);
        if (params.takerDirection == 1) {
            marketData.longAmount = marketData.longAmount.sub(params.amount);
            marketData.longOpenTotal = marketData.longOpenTotal.sub(params.total);
            marketData.longMakerFreeze = marketData.longMakerFreeze.sub(params.makerMargin);
        } else {
            marketData.shortAmount = marketData.shortAmount.sub(params.amount);
            marketData.shortOpenTotal = marketData.shortOpenTotal.sub(params.total);
            marketData.shortMakerFreeze = marketData.shortMakerFreeze.sub(params.makerMargin);
        }

        GlobalHf memory g;
        if (!params.isClearAll) {
            g = _checkPoolStatus(false);
        }

        _marginToVault(params.marginToVault);
        _feeToExchange(params.feeToExchange);
        _vaultTransfer(params.taker, params.toTaker, params.isOutETH);
        _vaultTransfer(params.inviter, params.feeToInviter, baseAsset == WETH);
        _vaultTransfer(IManager(manager).riskFunding(), params.toRiskFund, false);

        emit CloseUpdate(
            params.orderId,
            msg.sender,
            params.taker,
            params.inviter,
            params.feeToExchange,
            params.makerFee,
            params.feeToInviter,
            params.toRiskFund,
            params.makerProfit.neg256(),
            params.fundingPayment,
            params.payInterest,
            g.sharePrice,
            marketData.shortOpenTotal,
            marketData.longOpenTotal
        );
    }

    function _marginToVault(uint256 _margin) internal {
        if (_margin > 0) IVault(vault).addPoolBalance(_margin);
    }

    function _feeToExchange(uint256 _fee) internal {
        if (_fee > 0) IVault(vault).addExchangeFeeBalance(_fee);
    }

    function _vaultTransfer(address _to, uint256 _amount, bool _isOutETH) internal {
        if (_amount > 0) IVault(vault).transfer(_to, _amount, _isOutETH);
    }

    /// @notice pool update when user increasing or decreasing the position margin
    function takerUpdateMargin(address _market, address taker, int256 _margin, bool isOutETH) external _onlyMarket {
        require(_margin != 0, 'PT0');
        DataByMarket storage marketData = poolDataByMarkets[_market];

        if (_margin > 0) {
            marketData.takerTotalMargin = marketData.takerTotalMargin.add(_margin.toUint256());
            _marginToVault(_margin.toUint256());
        } else {
            marketData.takerTotalMargin = marketData.takerTotalMargin.sub(_margin.neg256().toUint256());
            _vaultTransfer(taker, _margin.neg256().toUint256(), isOutETH);
        }
    }

    // update liquidity order when add liquidity
    function addLiquidity(
        uint256 orderId,
        address sender,
        uint256 amount,
        uint256 leverage
    ) external nonReentrant _onlyExecutor whenNotAddPaused returns (uint256 liquidity){
        require(
            !clearAll
            && amount >= minAddLiquidityAmount
            && leverage >= minLeverage
            && leverage <= maxLeverage,
            "PA0"
        );
        
        GlobalHf memory g = _globalInfo(true);
        IPool.Position storage position;
        if (makerPositionIds[sender] == 0) {
            autoId ++;
            makerPositionIds[sender] = autoId;
            position = makerPositions[autoId];
            position.maker = sender;
        } else {
            position = makerPositions[makerPositionIds[sender]];
        }

        _updateBorrowIG(g.allMarketPos.longMakerFreeze, g.allMarketPos.shortMakerFreeze);
        _checkPoolPnlStatus(g);
        uint256 vol = amount.mul(leverage);
        liquidity = vol.mul(10 ** decimals).mul(PRICE_PRECISION).div(g.sharePrice).div(10 ** baseAssetDecimals);
        _mint(sender, liquidity);

        position.entryValue = position.entryValue.add(vol);
        position.initMargin = position.initMargin.add(amount);
        position.liquidity = position.liquidity.add(liquidity);
        position.lastAddTime = block.timestamp;
        balance = balance.add(vol.toInt256());
        balanceReal = balanceReal.add(amount.toInt256());
        _marginToVault(amount);

        _onLiquidityChanged(g.indexPrices);

        _checkPoolStatus(true);

        emit AddLiquidity(++eventId, orderId, sender, makerPositionIds[sender], amount, liquidity, vol, g.sharePrice, g.poolTotalTmp);
    }

    struct RemoveLiquidityVars {
        uint256 positionId;
        uint256 currentSharePrice;
        uint256 removeRate;
        uint256 settleEntryValue;
        uint256 settleInitMargin;
        uint256 remainLiquidity;
        uint256 outVol;
        uint256 feeToPool;
        int256 pnl;
        int256 outAmount;
        bool positionStatus;
        bool isTP;
        uint256 aType;              // 0: maker remove, 1: TP, 2: SL
    }

    /// @notice pool update when user increasing or decreasing the position margin
    function removeLiquidity(
        uint256 orderId,
        address sender,
        uint256 liquidity,
        bool isETH,
        bool isSystem
    ) external nonReentrant _onlyExecutor whenNotRemovePaused returns (uint256 settleLiquidity){
        require(!clearAll, "PRL0"); 
        RemoveLiquidityVars memory vars;
        vars.positionId = makerPositionIds[sender];
        require(vars.positionId > 0, "PRL1");
        GlobalHf memory g = _globalInfo(false);
        IPool.Position storage position = makerPositions[vars.positionId];
        _updateBorrowIG(g.allMarketPos.longMakerFreeze, g.allMarketPos.shortMakerFreeze);
        _checkPoolPnlStatus(g);
        settleLiquidity = position.liquidity >= liquidity ? liquidity : position.liquidity;
        vars.remainLiquidity = position.liquidity.sub(settleLiquidity);
        if (vars.remainLiquidity <= minRemoveLiquidityAmount) {
            settleLiquidity = position.liquidity;
        }
        
        vars.removeRate = settleLiquidity.mul(1e18).div(position.liquidity);
        require(balanceOf[sender] >= settleLiquidity, "PRL3");
        vars.settleEntryValue = position.entryValue.mul(vars.removeRate).div(1e18);
        vars.settleInitMargin = position.initMargin.mul(vars.removeRate).div(1e18);

        if (isSystem) {
            vars.isTP = position.makerProfitPrice > 0 ? g.sharePrice >= position.makerProfitPrice : false;
            vars.aType = vars.isTP ? 1 : 2;
            require((g.sharePrice <= position.makerStopLossPrice) || vars.isTP, "PRL4");
        } 
        
        vars.outVol = settleLiquidity.mul(g.poolTotalTmp).div(totalSupply);
        require(balance >= vars.outVol.toInt256(), 'PRL6');
        vars.pnl = vars.outVol.toInt256().sub(vars.settleEntryValue.toInt256());
        vars.outAmount = vars.settleInitMargin.toInt256().add(vars.pnl);
        require(vars.outAmount >= 0, "PRL7");

        _burn(sender, settleLiquidity);
        balanceReal = balanceReal.sub(vars.outAmount);
        vars.feeToPool = vars.outAmount.toUint256().mul(removeLiquidityFeeRate).div(RATE_PRECISION);
        vars.outAmount = vars.outAmount.sub(vars.feeToPool.toInt256());
        _vaultTransfer(sender, vars.outAmount.toUint256(), isETH);
        if (vars.feeToPool > 0) {
            IVault(vault).addPoolRmLpFeeBalance(vars.feeToPool);
            cumulateRmLiqFee = cumulateRmLiqFee.add(vars.feeToPool);
        }
        balance = balance.sub(vars.outVol.toInt256());
        position.initMargin = position.initMargin.sub(vars.settleInitMargin);
        position.liquidity = position.liquidity.sub(settleLiquidity);
        position.entryValue = position.entryValue.sub(vars.settleEntryValue);
        
        g = _checkPoolStatus(false);
        // check position status
        (vars.positionStatus, , ) = _hf(position, g.poolTotalTmp);
        require(!vars.positionStatus, "PRL8");

        _onLiquidityChanged(g.indexPrices);
        emit RemoveLiquidity(++eventId, orderId, position.maker, vars.positionId, vars.settleInitMargin, settleLiquidity, vars.settleEntryValue, vars.pnl, vars.outAmount, g.sharePrice, vars.feeToPool, g.poolTotalTmp, vars.aType);
    }

    struct LiquidateVars {
        int256 pnl;
        uint256 outValue;
        uint256 penalty;
        bool positionStatus;
    }

    /// @notice if position state is liquidation, the position will be liquidated
    /// @param positionId liquidity position id
    function liquidate(uint256 positionId) external nonReentrant _onlyExecutor whenNotRemovePaused {
        LiquidateVars memory vars;
        IPool.Position storage position = makerPositions[positionId];
        require(position.liquidity > 0, "PL0");
        GlobalHf memory g = _globalInfo(false);
        _updateBorrowIG(g.allMarketPos.longMakerFreeze, g.allMarketPos.shortMakerFreeze);
        
        if (!clearAll) {
            (vars.positionStatus, vars.pnl, vars.outValue) = _hf(position, g.poolTotalTmp);
            require(vars.positionStatus, "PL1");
            vars.penalty = vars.outValue.mul(penaltyRate).div(RATE_PRECISION);
        } else {
            require(g.allMakerFreeze == 0, "PL2");
            vars.outValue = position.liquidity.mul(g.poolTotalTmp).div(totalSupply);
            vars.pnl = vars.outValue.toInt256().sub(position.entryValue.toInt256());
        }
        int256 remainAmount = position.initMargin.toInt256().add(vars.pnl);
        if (remainAmount > 0) {
            balanceReal = balanceReal.sub(remainAmount);
            if (remainAmount > vars.penalty.toInt256()) {
                remainAmount = remainAmount.sub(vars.penalty.toInt256());
            } else {
                vars.penalty = remainAmount.toUint256();
                remainAmount = 0;
            }
            if (vars.penalty > 0) _vaultTransfer(IManager(manager).riskFunding(), vars.penalty, false);
            if (remainAmount > 0) _vaultTransfer(position.maker, remainAmount.toUint256(), baseAsset == WETH);
        } else {
            // remainAmount < 0, if a liquidation shortfall occurs, the deficit needs to be distributed among all liquidity providers (LPs)
            balance = balance.add(remainAmount);
        }
        balance = balance.sub(vars.outValue.toInt256());

        require(balanceOf[position.maker] >= position.liquidity, "PL3");
        _burn(position.maker, position.liquidity);

        emit Liquidate(++eventId, position.maker, positionId, position.initMargin, position.liquidity, position.entryValue, vars.pnl, remainAmount, vars.penalty, g.sharePrice, g.poolTotalTmp);

        position.liquidity = 0;
        position.initMargin = 0;
        position.entryValue = 0;
        
        if (!clearAll) {
            _checkPoolStatus(false);
        }

        _onLiquidityChanged(g.indexPrices);
    }

    /// @notice update pool data when user increasing or decreasing the position margin
    /// @param positionId liquidity position id
    /// @param addMargin add margin amount
    function addMakerPositionMargin(uint256 positionId, uint256 addMargin) external nonReentrant _onlyRouter whenNotRemovePaused {
        IPool.Position storage position = makerPositions[positionId];
        require(position.liquidity > 0 && addMargin > 0 && !clearAll, "PAM0");
        position.initMargin = position.initMargin.add(addMargin);
        balanceReal = balanceReal.add(addMargin.toInt256());
        _marginToVault(addMargin);
        require(position.entryValue.div(position.initMargin) >= minLeverage, "PAM3");
        emit AddMakerPositionMargin(++eventId, positionId, addMargin);
    }

    /// @notice add liquidity position stop loss and take profit price
    /// @param maker liquidity position maker address
    /// @param positionId liquidity position id
    /// @param tp take profit price
    /// @param sl stop loss price
    function setTPSLPrice(address maker, uint256 positionId, uint256 tp, uint256 sl) external _onlyRouter {
        IPool.Position storage position = makerPositions[positionId];
        require(!clearAll && position.maker == maker && position.liquidity > 0, "PS0");
        position.makerStopLossPrice = sl;
        position.makerProfitPrice = tp;
    }

    /// @notice if the pool is in the state of clear all, the pool will be closed and all positions will be liquidated
    function activateClearAll() external {
        (GlobalHf memory g, bool status) = _globalHf(false);
        require(status, "PAC0");
        IManager(manager).modifySingleInterestStatus(address(this), true);
        for (uint256 i = 0; i < marketList.length; i++) IManager(manager).modifySingleFundingStatus(marketList[i], true);
        clearAll = true;
        emit  ActivatedClearAll(block.timestamp, g.indexPrices);
    }
    
    /// @notice if the pool is in the state of clear all, the position is closed all, can be restarted, 
    /// should be open interest and funding
    function reStart() external _onlyController {
        require((totalSupply == 0) && clearAll, "PSP3");
        clearAll = false;
        emit ReStarted(address(this));
    }
    
    /// @notice update interests global information
    function updateBorrowIG() public {
        (DataByMarket memory allMarketPos,) = _getAllMarketData();
        _updateBorrowIG(allMarketPos.longMakerFreeze, allMarketPos.shortMakerFreeze);
    }

    /// @notice update funding global information
    function updateFundingPayment(address _market, int256 _fundingPayment) external _onlyMarket {
        if (_fundingPayment != 0) {
            DataByMarket storage marketData = poolDataByMarkets[_market];
            marketData.makerFundingPayment = marketData.makerFundingPayment.add(_fundingPayment);
        }
    }

    /// @notice update interests global information
    function setPoolParams(PoolParams memory params) external _onlyController {
        require(
            params._interestLogic != address(0)
            && params._marketPriceFeed != address(0)
            && params._mm <= RATE_PRECISION,
            "PSP0"
        );
        minAddLiquidityAmount = params._minAmount;
        minRemoveLiquidityAmount = params._minLiquidity;
        removeLiquidityFeeRate = params._ratio;
        addPaused = params._add;
        removePaused = params._remove;
        interestLogic = params._interestLogic;
        marketPriceFeed = params._marketPriceFeed;
        mm = params._mm;
        minLeverage = params._minLeverage;
        maxLeverage = params._maxLeverage;
        penaltyRate = params._penaltyRate;
        // modify market premium rate config
        MarketConfig storage args = marketConfigs[params._market];
        if (params._openRate != args.fundUtRateLimit || params._openLimit != args.openLimit || params._reserveRate != reserveRate) {
            uint256[] memory indexPrices = new uint256[](marketList.length);
            for (uint256 i = 0; i < marketList.length; i++) {
                indexPrices[i] = getPriceForPool(marketList[i], false);
            }
            _onLiquidityChanged(indexPrices);
        }
        args.fundUtRateLimit = params._openRate;
        args.openLimit = params._openLimit;
        reserveRate = params._reserveRate;
    }
    
    /// @notice if the pool liquidity is changed, will be update all market premium rate config
    /// @param indexPrices all market index price
    function _onLiquidityChanged(uint256[] memory indexPrices) internal {
        for (uint256 i = 0; i < marketList.length; i++) {
            IMarketPriceFeed(marketPriceFeed).onLiquidityChanged(address(this), marketList[i], indexPrices[i]);
        }
    }
    
    /// @notice get single position health factor 
    /// @param position liquidity position
    /// @param poolTotalTmp pool total value
    /// @return status true: position is unsafe, false: position is safe
    /// @return pnl position unrealized pnl
    /// @return currentValue position current value
    function _hf(IPool.Position memory position, uint256 poolTotalTmp) internal view returns (bool status, int256 pnl, uint256 currentValue){
        if (totalSupply == 0 || position.initMargin == 0) return (false, 0, 0);
        currentValue = position.liquidity.mul(poolTotalTmp).div(totalSupply);
        pnl = currentValue.toInt256().sub(position.entryValue.toInt256());
        status = position.initMargin.toInt256().add(pnl) <= currentValue.toInt256().mul(mm.toInt256()).div(RATE_PRECISION.toInt256());
    }
    
    /// @notice get pool health factor, status true: pool is unsafe, false: pool is safe
    /// @param isAdd true: add liquidity or show tvl, false: rm liquidity
    function _globalHf(bool isAdd) internal view returns (GlobalHf memory g, bool status){
        g = _globalInfo(isAdd);
        int256 tempTotalLockedFund = balanceReal.add(g.allMarketPos.takerTotalMargin.toInt256());
        int256 totalAvailableFund = balanceReal.add(g.poolInterest.toInt256()).add(g.totalUnPNL).add(g.allMarketPos.makerFundingPayment).sub(g.poolTotalTmp.mul(mm).div(RATE_PRECISION).toInt256());
        totalAvailableFund = totalAvailableFund > tempTotalLockedFund? tempTotalLockedFund : totalAvailableFund;
        status = totalAvailableFund < 0;
    }
    
    function _checkPoolStatus(bool isAdd) internal view returns (GlobalHf memory g){
        bool status;
        (g, status) = _globalHf(isAdd);
        require(!status, "PCP0");
    }
    
    function _checkPoolPnlStatus(GlobalHf memory g) internal view{
        if (totalSupply > 0) require((g.totalUnPNL.add(g.allMarketPos.makerFundingPayment).add(g.poolInterest.toInt256()) <= g.allMarketPos.takerTotalMargin.toInt256()) && (g.totalUnPNL.neg256().sub(g.allMarketPos.makerFundingPayment) <= g.allMakerFreeze.toInt256()), 'PCPP0');
    }

    function _globalInfo(bool isAdd) internal view returns (GlobalHf memory g){
        (g.allMarketPos, g.allMakerFreeze) = _getAllMarketData();
        g.poolInterest = _calcPooInterest(g.allMarketPos.longMakerFreeze, g.allMarketPos.shortMakerFreeze);
        (g.totalUnPNL, g.indexPrices) = _makerProfitForLiquidity(isAdd);
        int256 poolTotal = balance.add(g.allMakerFreeze.toInt256()).add(g.totalUnPNL).add(g.allMarketPos.makerFundingPayment).add(g.poolInterest.toInt256());
        g.poolTotalTmp = poolTotal < 0 ? 0 : poolTotal.toUint256();
        g.sharePrice = totalSupply == 0 ? PRICE_PRECISION : g.poolTotalTmp.mul(PRICE_PRECISION).mul(10 ** decimals).div(totalSupply).div(10 ** baseAssetDecimals);
    }
    
    /// @notice  calculate unrealized pnl of positions in all markets caused by price changes
    /// @param isAdd true: add liquidity or show tvl, false: rm liquidity
    function _makerProfitForLiquidity(bool isAdd) internal view returns (int256 unPNL, uint256[] memory indexPrices){
        indexPrices = new uint256[](marketList.length);
        for (uint256 i = 0; i < marketList.length; i++) {
            (int256 singleMarketPnl, uint256 indexPrice) = _makerProfitByMarket(marketList[i], isAdd);
            unPNL = unPNL.add(singleMarketPnl);
            indexPrices[i] = indexPrice;
        }
    }

    /// @notice calculate unrealized pnl of positions in one single market caused by price changes
    /// @param _market market address
    /// @param _isAdd true: add liquidity or show tvl, false: rm liquidity
    function _makerProfitByMarket(address _market, bool _isAdd) internal view returns (int256 unPNL, uint256 _price){
        DataByMarket storage marketData = poolDataByMarkets[_market];
        MarketConfig memory args = marketConfigs[_market];
        _price = getPriceForPool(_market, _isAdd ? marketData.longAmount < marketData.shortAmount : marketData.longAmount >= marketData.shortAmount);

        if (args.marketType == 1) {
            unPNL = marketData.longAmount.toInt256().sub(marketData.shortAmount.toInt256()).mul(PRICE_PRECISION.toInt256()).div(_price.toInt256());
            unPNL = unPNL.add(marketData.shortOpenTotal.toInt256()).sub(marketData.longOpenTotal.toInt256());
        } else {
            unPNL = marketData.shortAmount.toInt256().sub(marketData.longAmount.toInt256()).mul(_price.toInt256()).div(PRICE_PRECISION.toInt256());
            unPNL = unPNL.add(marketData.longOpenTotal.toInt256()).sub(marketData.shortOpenTotal.toInt256());
            if (args.marketType == 2) {
                unPNL = unPNL.mul((IMarket(_market).getMarketConfig().multiplier).toInt256()).div(RATE_PRECISION.toInt256());
            }
        }
        unPNL = unPNL.mul((10 ** baseAssetDecimals).toInt256()).div(AMOUNT_PRECISION.toInt256());
    }

    /// @notice update interest index global
    /// @param _longMakerFreeze sum of pool assets taken by the long positions
    /// @param _shortMakerFreeze sum of pool assets taken by the short positions
    function _updateBorrowIG(uint256 _longMakerFreeze, uint256 _shortMakerFreeze) internal {
        (, interestData[1].borrowIG) = _getCurrentBorrowIG(1, _longMakerFreeze, _shortMakerFreeze);
        (, interestData[- 1].borrowIG) = _getCurrentBorrowIG(- 1, _longMakerFreeze, _shortMakerFreeze);
        interestData[1].lastInterestUpdateTs = block.timestamp;
        interestData[- 1].lastInterestUpdateTs = block.timestamp;
    }
    
    /// @notice calculate the latest interest index global
    /// @param _direction position direction
    /// @param _longMakerFreeze sum of pool assets taken by the long positions
    /// @param _shortMakerFreeze sum of pool assets taken by the short positions
    function _getCurrentBorrowIG(int8 _direction, uint256 _longMakerFreeze, uint256 _shortMakerFreeze) internal view returns (uint256 _borrowRate, uint256 _borrowIG){
        require(_direction == 1 || _direction == - 1, "PGC0");
        IPool.InterestData memory data = interestData[_direction];

        // calc util need usedBalance,totalBalance,reserveRate
        //(DataByMarket memory allMarketPos, uint256 allMakerFreeze) = _getAllMarketData();
        uint256 usedBalance = _direction == 1 ? _longMakerFreeze : _shortMakerFreeze;
        uint256 totalBalance = balance.add(_longMakerFreeze.toInt256()).add(_shortMakerFreeze.toInt256()).toUint256();

        (_borrowRate, _borrowIG) = IInterestLogic(interestLogic).getMarketBorrowIG(address(this), usedBalance, totalBalance, reserveRate, data.lastInterestUpdateTs, data.borrowIG);
    }

    function _getCurrentAmount(int8 _direction, uint256 share, uint256 _longMakerFreeze, uint256 _shortMakerFreeze) internal view returns (uint256){
        (,uint256 ig) = _getCurrentBorrowIG(_direction, _longMakerFreeze, _shortMakerFreeze);
        return IInterestLogic(interestLogic).getBorrowAmount(share, ig).mul(10 ** baseAssetDecimals).div(AMOUNT_PRECISION);
    }

    /// @notice calculate the sum data of all markets
    function _getAllMarketData() internal view returns (DataByMarket memory allMarketPos, uint256 allMakerFreeze){
        for (uint256 i = 0; i < marketList.length; i++) {
            address market = marketList[i];
            DataByMarket memory marketData = poolDataByMarkets[market];

            allMarketPos.rlzPNL = allMarketPos.rlzPNL.add(marketData.rlzPNL);
            allMarketPos.cumulativeFee = allMarketPos.cumulativeFee.add(marketData.cumulativeFee);
            allMarketPos.longMakerFreeze = allMarketPos.longMakerFreeze.add(marketData.longMakerFreeze);
            allMarketPos.shortMakerFreeze = allMarketPos.shortMakerFreeze.add(marketData.shortMakerFreeze);
            allMarketPos.takerTotalMargin = allMarketPos.takerTotalMargin.add(marketData.takerTotalMargin);
            allMarketPos.makerFundingPayment = allMarketPos.makerFundingPayment.add(marketData.makerFundingPayment);
            allMarketPos.longOpenTotal = allMarketPos.longOpenTotal.add(marketData.longOpenTotal);
            allMarketPos.shortOpenTotal = allMarketPos.shortOpenTotal.add(marketData.shortOpenTotal);
        }

        allMakerFreeze = allMarketPos.longMakerFreeze.add(allMarketPos.shortMakerFreeze);
    }

    /// @notice get interest of this pool
    /// @return result the interest principal not included
    function _calcPooInterest(uint256 _longMakerFreeze, uint256 _shortMakerFreeze) internal view returns (uint256){
        uint256 longShare = interestData[1].totalBorrowShare;
        uint256 shortShare = interestData[- 1].totalBorrowShare;
        uint256 longInterest = _getCurrentAmount(1, longShare, _longMakerFreeze, _shortMakerFreeze);
        uint256 shortInterest = _getCurrentAmount(- 1, shortShare, _longMakerFreeze, _shortMakerFreeze);
        longInterest = longInterest <= _longMakerFreeze ? 0 : longInterest.sub(_longMakerFreeze);
        shortInterest = shortInterest <= _shortMakerFreeze ? 0 : shortInterest.sub(_shortMakerFreeze);
        return longInterest.add(shortInterest);
    }

    /// @notice get market open limit
    /// @param _market market address
    /// @return openLimitFunds the max funds used to open
    function _getMarketLimit(address _market, uint256 _allMakerFreeze) internal view returns (uint256 openLimitFunds){
        MarketConfig memory args = marketConfigs[_market];
        uint256 availableAmount = balance.add(_allMakerFreeze.toInt256()).toUint256().mul(RATE_PRECISION.sub(reserveRate)).div(RATE_PRECISION);
        uint256 openLimitByRatio = availableAmount.mul(args.fundUtRateLimit).div(RATE_PRECISION);
        openLimitFunds = openLimitByRatio > args.openLimit ? args.openLimit : openLimitByRatio;
    }
    
    function getCurrentAmount(int8 _direction, uint256 share) public view returns (uint256){
        (DataByMarket memory allMarketPos,) = _getAllMarketData();
        return _getCurrentAmount(_direction, share, allMarketPos.longMakerFreeze, allMarketPos.shortMakerFreeze);
    }

    function getCurrentShare(int8 _direction, uint256 amount) external view returns (uint256){
        (DataByMarket memory allMarketPos,) = _getAllMarketData();
        (,uint256 ig) = _getCurrentBorrowIG(_direction, allMarketPos.longMakerFreeze, allMarketPos.shortMakerFreeze);
        return IInterestLogic(interestLogic).getBorrowShare(amount.mul(AMOUNT_PRECISION).div(10 ** baseAssetDecimals), ig);
    }

    /// @notice get the fund utilization information of a market
    /// @param _market market address
    function getMarketAmount(address _market) external view returns (uint256, uint256, uint256){
        DataByMarket memory marketData = poolDataByMarkets[_market];
        (,uint256 allMakerFreeze) = _getAllMarketData();
        uint256 openLimitFunds = _getMarketLimit(_market, allMakerFreeze);
        return (marketData.longAmount, marketData.shortAmount, openLimitFunds);
    }

    /// @notice get current borrowIG
    /// @param _direction position direction
    function getCurrentBorrowIG(int8 _direction) public view returns (uint256 _borrowRate, uint256 _borrowIG){
        (DataByMarket memory allMarketPos,) = _getAllMarketData();
        return _getCurrentBorrowIG(_direction, allMarketPos.longMakerFreeze, allMarketPos.shortMakerFreeze);
    }

    /// @notice validate whether this open order can be executed
    ///         every market open interest is limited by two params, the open limit and the funding utilization rate limit
    /// @param _market market address
    /// @param _makerMargin margin taken from the pool of this order
    function canOpen(address _market, uint256 _makerMargin) public view returns (bool _can){
        // balance - margin >= (balance + frozen) * reserveRatio
        // => balance >= margin + (balance + frozen) * reserveRatio >= margin
        // when reserve ratio == 0  => balance >= margin

        (,uint256 allMakerFreeze) = _getAllMarketData();
        uint256 reserveAmount = balance.add(allMakerFreeze.toInt256()).toUint256().mul(reserveRate).div(RATE_PRECISION);
        if (balance < reserveAmount.add(_makerMargin).toInt256()) {
            return false;
        }

        uint256 openLimitFunds = _getMarketLimit(_market, allMakerFreeze);
        DataByMarket memory marketData = poolDataByMarkets[_market];
        uint256 marketUsedFunds = marketData.longMakerFreeze.add(marketData.shortMakerFreeze).add(_makerMargin);
        return marketUsedFunds <= openLimitFunds;
    }

    /// @notice get pool total status
    /// @return status true: pool is unsafe, false: pool is safe
    /// @return poolTotalTmp pool total valuation
    /// @return totalUnPNL total unrealized pnl of all positions
    function globalHf() public view returns (bool status, uint256 poolTotalTmp, int256 totalUnPNL){
        GlobalHf memory g;
        (g, status) = _globalHf(false);
        poolTotalTmp = g.poolTotalTmp;
        totalUnPNL = g.totalUnPNL;
    }

    /// @notice get index price to calculate the pool unrealized pnl
    /// @param _market market address
    /// @param _maximise should maximise the price
    function getPriceForPool(address _market, bool _maximise) internal view returns (uint256){
        return IMarketPriceFeed(marketPriceFeed).priceForPool(IMarket(_market).token(), _maximise);
    }
    
    /// @notice get all markets
    function getMarketList() external view returns (address[] memory){
        return marketList;
    }

    /// @notice get asset of pool
    function getBaseAsset() public view returns (address){
        return baseAsset;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

//import "../libraries/PoolDataStructure.sol";
import "../interfaces/IPool.sol";

contract PoolStorage {
    //
    // data for this pool
    //

    // constant
    uint256 constant RATE_PRECISION = 1e6;                     // example rm lp fee rate 1000/1e6=0.001
    uint256 constant PRICE_PRECISION = 1e10;
    uint256 constant AMOUNT_PRECISION = 1e20;

    // contracts addresses used
    address vault;                                              // vault address
    address baseAsset;                                          // base token address
    address marketPriceFeed;                                    // price feed contract address
    uint256 baseAssetDecimals;                                  // base token decimals
    address interestLogic;                                      // interest logic address
    address WETH;                                               // WETH address 

    bool public addPaused = false;                              // flag for adding liquidity
    bool public removePaused = false;                           // flag for remove liquidity
    uint256 public minRemoveLiquidityAmount;                    // minimum amount (lp) for removing liquidity
    uint256 public minAddLiquidityAmount;                       // minimum amount (asset) for add liquidity
    uint256 public removeLiquidityFeeRate = 1000;               // fee ratio for removing liquidity
    uint256 public mm;                                          // maintenance margin ratio
    bool public clearAll;
    uint256 public minLeverage;
    uint256 public maxLeverage;
    uint256 public penaltyRate;

    int256 public balance;                                      // balance that is available to use of this pool
    int256 public balanceReal;
    uint256 public reserveRate;                                 // reserve ratio
    uint256 sharePrice;                                         // net value
    uint256 public cumulateRmLiqFee;                            // cumulative fee collected when removing liquidity
    uint256 public autoId;                                      // liquidity operations order id
    uint256 eventId;                                            // event count

    address[] marketList;                                       // supported markets array
    mapping(address => bool) public isMarket;                   // supported markets mapping
    mapping(address => MarketConfig) public marketConfigs;      // mapping of market configs
    mapping(address => DataByMarket) public poolDataByMarkets;  // mapping of market data
    mapping(int8 => IPool.InterestData) public interestData;    // mapping of interest data for position directions (long or short)
    mapping(uint256 => IPool.Position) public makerPositions;   // mapping of liquidity positions for addresses
    mapping(address => uint256) public makerPositionIds;        // mapping of liquidity positions for addresses

    //structs
    struct MarketConfig {
        uint256 marketType;
        uint256 fundUtRateLimit;                                // fund utilization ratio limit, 0: cant't open; example 200000  r = fundUtRateLimit/RATE_PRECISION=0.2
        uint256 openLimit;                                      // 0: 0 authorized credit limit; > 0 limit is min(openLimit, fundUtRateLimit * balance)
    }

    struct DataByMarket {
        int256 rlzPNL;                                          // realized profit and loss
        uint256 cumulativeFee;                                  // cumulative trade fee for pool
        uint256 longMakerFreeze;                                // user total long margin freeze, that is the pool short margin freeze
        uint256 shortMakerFreeze;                               // user total short margin freeze, that is pool long margin freeze
        uint256 takerTotalMargin;                               // all taker's margin
        int256 makerFundingPayment;                             // pending fundingPayment
        uint256 interestPayment;                                // interestPayment          
        uint256 longAmount;                                     // sum asset for long pos
        uint256 longOpenTotal;                                  // sum value  for long pos
        uint256 shortAmount;                                    // sum asset for short pos
        uint256 shortOpenTotal;                                 // sum value for short pos
    }

    struct PoolParams {
        uint256 _minAmount;
        uint256 _minLiquidity;
        address _market;
        uint256 _openRate;
        uint256 _openLimit;
        uint256 _reserveRate;
        uint256 _ratio;
        bool _add;
        bool _remove;
        address _interestLogic;
        address _marketPriceFeed;
        uint256 _mm;
        uint256 _minLeverage;
        uint256 _maxLeverage;
        uint256 _penaltyRate;
    }

    struct GlobalHf {
        uint256 sharePrice;
        uint256[] indexPrices;
        uint256 allMakerFreeze;
        DataByMarket allMarketPos;
        uint256 poolInterest;
        int256 totalUnPNL;
        uint256 poolTotalTmp;
    }

    event RegisterMarket(address market);
    event AddLiquidity(uint256 id, uint256 orderId, address maker, uint256 positionId, uint256 initMargin, uint256 liquidity, uint256 entryValue, uint256 sharePrice, uint256 totalValue);
    event RemoveLiquidity(uint256 id, uint256 orderId, address maker, uint256 positionId, uint256 rmMargin, uint256 rmLiquidity, uint256 rmValue, int256 pnl, int256 toMaker, uint256 sharePrice, uint256 rmFee, uint256 totalValue, uint256 actionType);
    event Liquidate(uint256 id, address maker,uint256 positionId, uint256 rmMargin, uint256 rmLiquidity, uint256 rmValue, int256 pnl, int256 toMaker,uint256 penalty, uint256 sharePrice, uint256 totalValue);
    event ActivatedClearAll(uint256 ts, uint256[] indexPrices);
    event AddMakerPositionMargin(uint256 id, uint256 positionId, uint256 addMargin);
    event ReStarted(address pool);
    event OpenUpdate(
        uint256 indexed id,
        address indexed market,
        address taker,
        address inviter,
        uint256 feeToExchange,
        uint256 feeToMaker,
        uint256 feeToInviter,
        uint256 sharePrice,
        uint256 shortValue,
        uint256 longValue
    );
    event CloseUpdate(
        uint256 indexed id,
        address indexed market,
        address taker,
        address inviter,
        uint256 feeToExchange,
        uint256 feeToMaker,
        uint256 feeToInviter,
        uint256 riskFunding,
        int256 rlzPnl,
        int256 fundingPayment,
        uint256 interestPayment,
        uint256 sharePrice,
        uint256 shortValue,
        uint256 longValue
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

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

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;


interface IInterestLogic {
    function getMarketBorrowIG(address _pool, uint256 usedAmount, uint256 totalAmount, uint256 reserveRate, uint256 lastUpdateTime, uint256 borrowInterestGrowthGlobal) external view returns (uint256 borrowRate, uint256 borrowIg);

    function getBorrowAmount(uint256 borrowShare, uint256 borrowIg) external view returns (uint256);

    function getBorrowShare(uint256 amount, uint256 borrowIg) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;

interface IInviteManager {
    function setTraderReferralCode(address _account, bytes32 _code) external;

    function getReferrerCodeByTaker(address _taker) external view returns (bytes32, address, uint256, uint256);

    function updateTradeValue(uint8 _marketType, address _taker, address _inviter, uint256 _tradeValue) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

interface IManager {
    function vault() external view returns (address);

    function riskFunding() external view returns (address);

    function checkSuperSigner(address _signer) external view returns (bool);

    function checkSigner(address signer, uint8 sType) external view returns (bool);

    function checkController(address _controller) view external returns (bool);

    function checkRouter(address _router) external view returns (bool);

    function checkExecutorRouter(address _executorRouter) external view returns (bool);

    function checkMarket(address _market) external view returns (bool);

    function checkPool(address _pool) external view returns (bool);

    function checkMarketLogic(address _logic) external view returns (bool);

    function checkMarketPriceFeed(address _feed) external view returns (bool);

    function cancelElapse() external view returns (uint256);

    function triggerOrderDuration() external view returns (uint256);

    function paused() external returns (bool);
    
    function getMakerByMarket(address maker) external view returns (address);

    function getMarketMarginAsset(address) external view returns (address);

    function isFundingPaused(address market) external view returns (bool);

    function isInterestPaused(address pool) external view returns (bool);

    function executeOrderFee() external view returns (uint256);

    function inviteManager() external view returns (address);

    function getAllMarkets() external view returns (address[] memory);

    function getAllPools() external view returns (address[] memory);

    function orderNumLimit() external view returns (uint256);

    function checkTreasurer(address _treasurer) external view returns (bool);

    function checkExecutor(address _executor, uint8 eType) external view returns (bool);
    
    function communityExecuteOrderDelay() external view returns (uint256);

    function modifySingleInterestStatus(address pool, bool _interestPaused) external;

    function modifySingleFundingStatus(address market, bool _fundingPaused) external;
    
    function router() external view returns (address);

    function executorRouter() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "../libraries/MarketDataStructure.sol";

interface IMarket {
    function setMarketConfig(MarketDataStructure.MarketConfig memory _config) external;

    function updateFundingGrowthGlobal() external;

    function getMarketConfig() external view returns (MarketDataStructure.MarketConfig memory);

    function marketType() external view returns (uint8);

    function positionModes(address) external view returns (MarketDataStructure.PositionMode);

    function fundingGrowthGlobalX96() external view returns (int256);

    function lastFrX96Ts() external view returns (uint256);

    function takerOrderTotalValues(address, int8) external view returns (int256);

    function pool() external view returns (address);

    function getPositionId(address _trader, int8 _direction) external view returns (uint256);

    function getPosition(uint256 _id) external view returns (MarketDataStructure.Position memory);

    function getOrderIds(address _trader) external view returns (uint256[] memory);

    function getOrder(uint256 _id) external view returns (MarketDataStructure.Order memory);

    function createOrder(MarketDataStructure.CreateInternalParams memory params) external returns (uint256 id);

    function cancel(uint256 _id) external;

    function executeOrder(uint256 _id) external returns (int256, uint256, bool);

    function updateMargin(uint256 _id, uint256 _updateMargin, bool isIncrease) external;

    function liquidate(uint256 _id, MarketDataStructure.OrderType action, uint256 clearPrice) external returns (uint256);

    function setTPSLPrice(uint256 _id, uint256 _profitPrice, uint256 _stopLossPrice, bool isExecutedByIndexPrice) external;

    function takerOrderNum(address, MarketDataStructure.OrderType) external view returns (uint256);

    function getLogicAddress() external view returns (address);

    function initialize(string memory _indexToken, address _clearAnchor, address _pool, uint8 _marketType) external;

    function switchPositionMode(address _taker, MarketDataStructure.PositionMode _mode) external;

    function orderID() external view returns (uint256);
    
    function triggerOrderID() external view returns (uint256);

    function marketLogic() external view returns (address);

    function token() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./IPriceHelper.sol";

interface IMarketPriceFeed {
    function priceForTrade(address pool, address market, string memory token, int8 takerDirection, uint256 deltaSize, uint256 deltaValue, bool isLiquidation) external returns (uint256 size, uint256 vol, uint256 tradePrice);

    function priceForPool(string memory _token, bool _maximise) external view returns (uint256);

    function priceForLiquidate(string memory _token, bool _maximise) external view returns (uint256);

    function priceForIndex(string memory _token, bool _maximise) external view returns (uint256);

    function getLatestPrimaryPrice(string memory _token) external view returns (uint256);

    function onLiquidityChanged(address pool, address market, uint256 indexPrice) external;

    function getFundingRateX96PerSecond(address market) external view returns(int256 fundingRateX96);

    function modifyMarketTickConfig(address pool, address market, string memory token, IPriceHelper.MarketTickConfig memory cfg) external;

    function getMarketPrice(address market, string memory _token, bool maximise) external view returns (uint256 marketPrice);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "../core/PoolStorage.sol";

interface IPool {
    struct InterestData {
        uint256 totalBorrowShare;
        uint256 lastInterestUpdateTs;
        uint256 borrowIG;
    }
    
    struct UpdateParams {
        uint256 orderId;
        uint256 makerMargin;//reduce maker margin，taker margin，amount，value
        uint256 takerMargin;
        uint256 amount;
        uint256 total;
        int256 makerProfit;
        uint256 makerFee;   //trade fee to maker
        int256 fundingPayment;//settled funding payment
        int8 takerDirection;//old position direction
        uint256 marginToVault;// reduce position size ,order margin should be to record in vault
        uint256 deltaDebtShare;//reduce position debt share
        uint256 payInterest;//settled interest payment
        bool isOutETH;//margin is ETH
        uint256 toRiskFund;
        uint256 toTaker;//balance of reduce position to taker
        address taker;//taker address
        uint256 feeToInviter; //trade fee to inviter
        address inviter;//inviter address
        uint256 feeToExchange;//fee to exchange
        bool isClearAll;
    }

    struct Position{
        address maker;
        uint256 initMargin;
        uint256 liquidity;
        uint256 entryValue;
        uint256 lastAddTime;
        uint256 makerStopLossPrice;
        uint256 makerProfitPrice;
    }
    
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function canOpen(address _market, uint256 _makerMargin) external view returns (bool);

    function getMakerOrderIds(address _maker) external view returns (uint256[] memory);

    function makerPositions(uint256 positionId) external view returns (Position memory);

    function openUpdate(UpdateParams memory params) external;

    function closeUpdate(UpdateParams memory params) external;

    function takerUpdateMargin(address _market, address, int256 _margin, bool isOutETH) external;

    function addLiquidity(uint256 orderId, address sender, uint256 amount, uint256 leverage) external returns(uint256 liquidity);

    function removeLiquidity(uint256 orderId, address sender, uint256 liquidity, bool isETH, bool isSystem) external returns (uint256 settleLiquidity);

    function liquidate(uint256 positionId) external ;

    function registerMarket(address _market) external returns (bool);

    function updateFundingPayment(address _market, int256 _fundingPayment) external;

    function getMarketAmount(address _market) external view returns (uint256, uint256, uint256);

    function getCurrentBorrowIG(int8 _direction) external view returns (uint256 _borrowRate, uint256 _borrowIG);

    function getCurrentAmount(int8 _direction, uint256 share) external view returns (uint256);

    function getCurrentShare(int8 _direction, uint256 amount) external view returns (uint256);

    function updateBorrowIG() external;

    function getBaseAsset() external view returns (address);

    function minRemoveLiquidityAmount() external view returns (uint256);

    function minAddLiquidityAmount() external view returns (uint256);

    function removeLiquidityFeeRate() external view returns (uint256);

    function reserveRate() external view returns (uint256);

    function addPaused() external view returns (bool);

    function removePaused() external view returns (bool);

    function clearAll() external view returns (bool);

    function makerPositionIds(address maker) external view returns (uint256);
    
    function mm()external view returns (uint256);
    
    function globalHf()external view returns (bool status, uint256 poolTotalTmp, int256 totalUnPNL);

    function addMakerPositionMargin(uint256 positionId, uint256 addMargin) external;

    function setTPSLPrice(address maker, uint256 positionId, uint256 tp, uint256 sl) external;
    
    function balance() external view returns (int256);
    
    function balanceReal() external view returns (int256);
    
    function getMarketList() external view returns (address[] memory);

    function poolDataByMarkets(address market) external view returns (int256, uint256, uint256, uint256, uint256, int256, uint256, uint256, uint256, uint256, uint256);
    
    function interestData(int8 direction) external view returns (IPool.InterestData memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;
import "../libraries/Tick.sol";

interface IPriceHelper {
    struct MarketTickConfig {
        bool isLinear;
        uint8 marketType;
        uint8 liquidationIndex;
        uint256 baseAssetDivisor;
        uint256 multiplier; // different precision from rate divisor
        uint256 maxLiquidity;
        Tick.Config[7] tickConfigs;
    }

    struct CalcTradeInfoParams {
        address pool;
        address market;
        uint256 indexPrice;
        bool isTakerLong;
        bool liquidation;
        uint256 deltaSize;
        uint256 deltaValue;
    }

    function calcTradeInfo(CalcTradeInfoParams memory params) external returns(uint256 deltaSize, uint256 volTotal, uint256 tradePrice);
    function onLiquidityChanged(address pool, address market, uint256 indexPrice) external;
    function modifyMarketTickConfig(address pool, address market, MarketTickConfig memory cfg, uint256 indexPrice) external;
    function getMarketPrice(address market, uint256 indexPrice) external view returns (uint256 marketPrice);
    function getFundingRateX96PerSecond(address market) external view returns(int256 fundingRateX96);

    event TickConfigChanged(address market, MarketTickConfig cfg);
    event TickInfoChanged(address market, uint8 index, uint256 size, uint256 premiumX96);
    event Slot0StateChanged(address market, uint256 netSize, uint256 premiumX96, bool isLong, uint8 currentTick);
    event LiquidationBufferSizeChanged(address market, uint8 index, uint256 bufferSize);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;

interface IVault {
    function addPoolBalance(uint256 _balance) external;

    function addPoolRmLpFeeBalance(uint256 _feeAmount) external;

    function transfer(address _to, uint256 _amount, bool isOutETH) external;

    function addExchangeFeeBalance(uint256 _feeAmount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

library Constant {
    uint256 constant Q96 = 1 << 96;
    uint256 constant RATE_DIVISOR = 1e8;
    uint256 constant PRICE_DIVISOR = 1e10;// 1e10
    uint256 constant SIZE_DIVISOR = 1e20;// 1e20 for AMOUNT_PRECISION
    uint256 constant TICK_LENGTH = 7;
    uint256 constant MULTIPLIER_DIVISOR = 1e6;

    int256 constant FundingRate1_10000X96 = int256(Q96) * 1 / 10000;
    int256 constant FundingRate4_10000X96 = int256(Q96) * 4 / 10000;
    int256 constant FundingRate5_10000X96 = int256(Q96) * 5 / 10000;
    int256 constant FundingRate6_10000X96 = int256(Q96) * 6 / 10000;
    int256 constant FundingRateMaxX96 = int256(Q96) * 375 / 100000;
    int256 constant FundingRate8Hours = 8 hours;
    int256 constant FundingRate24Hours = 24 hours;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/// @notice data structure used by Pool

library MarketDataStructure {
    /// @notice enumerate of user trade order status
    enum OrderStatus {
        Open,
        Opened,
        OpenFail,
        Canceled
    }

    /// @notice enumerate of user trade order types
    enum OrderType{
        Open,
        Close,
        TriggerOpen,
        TriggerClose,
        Liquidate,
        TakeProfit,
        UserTakeProfit,
        UserStopLoss,
        ClearAll
    }

    /// @notice position mode, one-way or hedge
    enum PositionMode{
        Hedge,
        OneWay
    }

    enum PositionKey{
        Short,
        Long,
        OneWay
    }

    /// @notice Position data structure
    struct Position {
        uint256 id;                 // position id, generated by counter
        address taker;              // taker address
        address market;             // market address
        int8 direction;             // position direction
        uint16 takerLeverage;       // leverage used by trader
        uint256 amount;             // position amount
        uint256 value;              // position value
        uint256 takerMargin;        // margin of trader
        uint256 makerMargin;        // margin of maker(pool)
        uint256 multiplier;         // multiplier of quanto perpetual contracts
        int256 frLastX96;           // last settled funding global cumulative value
        uint256 stopLossPrice;      // stop loss price of this position set by trader
        uint256 takeProfitPrice;    // take profit price of this position set by trader
        bool useIP;                 // true if the tp/sl is executed by index price
        uint256 lastTPSLTs;         // last timestamp of trading setting the stop loss price or take profit price
        int256 fundingPayment;      // cumulative funding need to pay of this position
        uint256 debtShare;          // borrowed share of interest module
        int256 pnl;                 // cumulative realized pnl of this position
        bool isETH;                 // true if the margin is payed by ETH
        uint256 lastUpdateTs;       // last updated timestamp of this position
    }

    /// @notice data structure of trading orders
    struct Order {
        uint256 id;                             // order id, generated by counter
        address market;                         // market address
        address taker;                          // trader address
        int8 direction;                         // order direction
        uint16 takerLeverage;                   // order leverage
        int8 triggerDirection;                  // price condition if order is trigger order: {0: not available, 1: >=, -1: <= }
        uint256 triggerPrice;                   // trigger price, 0: not available
        bool useIP;                             // true if the order is executed by index price
        uint256 freezeMargin;                   // frozen margin of this order
        uint256 amount;                         // order amount
        uint256 multiplier;                     // multiplier of quanto perpetual contracts
        uint256 takerOpenPriceMin;              // minimum trading price for slippage control
        uint256 takerOpenPriceMax;              // maximum trading price for slippage control

        OrderType orderType;                    // order type
        uint256 riskFunding;                    // risk funding penalty if this is a liquidate order

        uint256 takerFee;                       // taker trade fee
        uint256 feeToInviter;                   // reward of trading fee to the inviter
        uint256 feeToExchange;                  // trading fee charged by protocol
        uint256 feeToMaker;                     // fee reward to the pool
        uint256 feeToDiscount;                  // fee discount
        uint256 executeFee;                     // execution fee
        bytes32 code;                           // invite code

        uint256 tradeTs;                        // trade timestamp
        uint256 tradePrice;                     // trade price
        uint256 tradeIndexPrice;                // index price when executing
        int256 rlzPnl;                          // realized pnl by this order

        int256 fundingPayment;                  // settled funding payment
        int256 frX96;                           // latest cumulative funding growth global
        int256 frLastX96;                       // last cumulative funding growth global
        int256 fundingAmount;                   // funding amount by this order, calculated by amount, frX96 and frLastX96

        uint256 interestPayment;                // settled interest amount
        
        uint256 createTs;                       // create timestamp
        OrderStatus status;                     // order status
        MarketDataStructure.PositionMode mode;  // margin mode, one-way or hedge
        bool isETH;                             // true if the margin is payed by ETH
    }

    /// @notice configuration of markets
    struct MarketConfig {
        uint256 mm;                             // maintenance margin ratio
        uint256 liquidateRate;                  // penalty ratio when position is liquidated, penalty = position.value * liquidateRate
        uint256 tradeFeeRate;                   // trading fee rate
        uint256 makerFeeRate;                   // ratio of trading fee that goes to the pool
        bool createOrderPaused;                 // true if order creation is paused
        bool setTPSLPricePaused;                // true if tpsl price setting is paused
        bool createTriggerOrderPaused;          // true if trigger order creation is paused
        bool updateMarginPaused;                // true if updating margin is paused
        uint256 multiplier;                     // multiplier of quanto perpetual contracts
        uint256 marketAssetPrecision;           // margin asset decimals
        uint256 DUST;                           // dust amount,scaled by AMOUNT_PRECISION (1e20)

        uint256 takerLeverageMin;               // minimum leverage that trader can use
        uint256 takerLeverageMax;               // maximum leverage that trader can use
        uint256 dMMultiplier;                   // used to calculate the initial margin when trading decrease position margin

        uint256 takerMarginMin;                 // minimum margin of a single trader order
        uint256 takerMarginMax;                 // maximum margin of a single trader order
        uint256 takerValueMin;                  // minimum value amount of a single trader order
        uint256 takerValueMax;                  // maximum value amount of a single trader order
        int256 takerValueLimit;                 // maximum position value of a single position
    }

    /// @notice internal parameter data structure when creating an order
    struct CreateInternalParams {
        address _taker;             // trader address
        uint256 id;                 // order id, generated by id counter
        uint256 minPrice;           // slippage: minimum trading price, validated in Router
        uint256 maxPrice;           // slippage: maximum trading price, validated in Router
        uint256 margin;             // order margin
        uint256 amount;             // close order amount, 0 if order is an open order
        uint16 leverage;            // order leverage, validated in MarketLogic
        int8 direction;             // order direction, validated in MarketLogic
        int8 triggerDirection;      // trigger condition, validated in MarketLogic
        uint256 triggerPrice;       // trigger price
        bool useIP;                 // true if the order is executed by index price
        uint8 reduceOnly;           // 0: false, 1: true
        bool isLiquidate;           // is liquidate order, liquidate orders are generated automatically
        bool isETH;                 // true if order margin payed in ETH
    }

    /// @notice returned data structure when an order is executed, used by MarketLogic.sol::trade
    struct TradeResponse {
        uint256 toTaker;            // refund to the taker
        uint256 tradeValue;         // value of the order
        uint256 leftInterestPayment;// interest payment on the remaining portion of the position
        bool isIncreasePosition;    // if the order causes position value increased
        bool isDecreasePosition;    // true if the order causes position value decreased
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

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
contract ReentrancyGuard {
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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

library SafeCast {

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
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
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
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
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
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
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
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
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
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
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
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
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
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
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
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
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
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
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
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
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
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * copy from openzeppelin-contracts
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./SafeCast.sol";

library SignedSafeMath {
    using SafeCast for int256;

    int256 constant private _INT256_MIN = - 2 ** 255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == - 1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == - 1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }


    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? value.toUint256() : neg256(value).toUint256();
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > - 2 ** 255, "PerpMath: inversion overflow");
        return - a;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;
import "./Constant.sol";
import "./SafeMath.sol";

library Tick {
    using SafeMath for uint256;

    struct Info {
        uint256 size;
        uint256 premiumX96;
    }

    struct Config {
        uint32 sizeRate;
        uint32 premium;
    }

    function calcTickInfo(uint32 sizeRate, uint32 premium, bool isLinear, uint256 liquidity, uint256 indexPrice) internal pure returns (uint256 size, uint256 premiumX96){
        if(isLinear) {
            size = liquidity.mul(sizeRate).div(Constant.RATE_DIVISOR);
            size = size.mul(Constant.PRICE_DIVISOR).div(indexPrice);
        } else {
            size = liquidity.mul(sizeRate).div(Constant.RATE_DIVISOR);
            size = size.mul(indexPrice).div(Constant.PRICE_DIVISOR);
        }

        premiumX96 = uint256(premium).mul(Constant.Q96).div(Constant.RATE_DIVISOR);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../interfaces/IERC20.sol";

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // usdt of tron mainnet TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t: 0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c
        /*
        if (token == address(0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c)){
            IERC20(token).transfer(to, value);
            return;
        }
        */

        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../interfaces/IManager.sol";
import '../libraries/SafeMath.sol';

contract ERC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint256 public decimals = 18;
    uint256  public totalSupply;

    address public manager;
    bool public inPrivateTransferMode;
    mapping(address => bool) public isHandler;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event InPrivateTransferModeSettled(bool _inPrivateTransferMode);
    event HandlerSettled(address _handler, bool _isActive);

    constructor(address _manager){
        require(_manager != address(0), "ERC20: invalid manager");
        manager = _manager;
    }

    modifier _onlyController(){
        require(IManager(manager).checkController(msg.sender), 'Pool: only controller');
        _;
    }

    function setInPrivateTransferMode(bool _inPrivateTransferMode) external _onlyController {
        inPrivateTransferMode = _inPrivateTransferMode;
        emit InPrivateTransferModeSettled(_inPrivateTransferMode);
    }

    function setHandler(address _handler, bool _isActive) external _onlyController {
        isHandler[_handler] = _isActive;
        emit HandlerSettled(_handler, _isActive);
    }

    function _mint(address to, uint256 value) internal {
        require(to != address(0), "ERC20: mint to the zero address");
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        require(from != address(0), "ERC20: _burn from the zero address");
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: owner is the zero address");
        require(spender != address(0), "ERC20: spender is the zero address");
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "ERC20: _transfer from the zero address");
        require(to != address(0), "ERC20: _transfer to the zero address");

        if (inPrivateTransferMode) {
            require(isHandler[msg.sender], "ERC20: msg.sender not whitelisted");
        }

        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(from != address(0), "ERC20: transferFrom from the zero address");
        require(to != address(0), "ERC20: transferFrom to the zero address");
        if (isHandler[msg.sender]) {
            _transfer(from, to, value);
            return true;
        }

        if (allowance[from][msg.sender] != uint256(- 1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);

        return true;
    }
}