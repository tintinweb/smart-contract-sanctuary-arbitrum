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
import "../libraries/PoolDataStructure.sol";
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
        string memory _lpTokenName, // usdc pool 1
        string memory _lpTokenSymbol//usdc1
    )ERC20(_manager){
        require(_baseAsset != address(0), "Pool: invalid clearAnchor");
        require(bytes(_lpTokenName).length != 0, "Pool: invalid lp token name");
        require(bytes(_lpTokenSymbol).length != 0, "Pool: invalid lp token symbol");
        require(_WETH != address(0) && _manager!= address(0), "Pool: invalid address");
        baseAsset = _baseAsset;
        baseAssetDecimals = IERC20(_baseAsset).decimals();
        name = _lpTokenName;
        symbol = _lpTokenSymbol;
        WETH = _WETH;
        vault = IManager(_manager).vault();
        sharePrice = PRICE_PRECISION;
        require(vault != address(0), "Pool: invalid vault in manager");
    }
    modifier _onlyMarket(){
        require(isMarket[msg.sender], 'Pool: not official market');
        _;
    }

    modifier _onlyRouter(){
        require(IManager(manager).checkRouter(msg.sender), 'Pool: only router');
        _;
    }

    modifier whenNotAddPaused() {
        require(!IManager(manager).paused() && !addPaused, "Pool: adding liquidity paused");
        _;
    }

    modifier whenNotRemovePaused() {
        require(!IManager(manager).paused() && !removePaused, "Pool: removing liquidity paused");
        _;
    }

    function registerMarket(
        address _market
    ) external returns (bool){
        require(msg.sender == manager, "Pool: only manage");
        require(!isMarket[_market], "Pool: already registered");
        isMarket[_market] = true;
        marketList.push(_market);
        MarketConfig storage args = marketConfigs[_market];
        args.marketType = IMarket(_market).marketType();
        emit RegisterMarket(_market);
        return true;
    }

    function getOrder(uint256 _id) external view returns (PoolDataStructure.MakerOrder memory){
        return makerOrders[_id];
    }

    /// @notice update pool data when an order with types of open or trigger open is executed
    function openUpdate(IPool.OpenUpdateInternalParams memory params) external _onlyMarket returns (bool){
        address _market = msg.sender;
        require(canOpen(_market, params._makerMargin), "Pool: insufficient pool available balance");
        DataByMarket storage marketData = poolDataByMarkets[_market];
        marketData.takerTotalMargin = marketData.takerTotalMargin.add(params._takerMargin);

        balance = balance.add(params.makerFee);
        marketData.cumulativeFee = marketData.cumulativeFee.add(params.makerFee);
        balance = balance.sub(params._makerMargin);
        interestData[params._takerDirection].totalBorrowShare = interestData[params._takerDirection].totalBorrowShare.add(params.deltaDebtShare);
        if (params._takerDirection == 1) {
            marketData.longMakerFreeze = marketData.longMakerFreeze.add(params._makerMargin);
            marketData.longAmount = marketData.longAmount.add(params._amount);
            marketData.longOpenTotal = marketData.longOpenTotal.add(params._total);
        } else {
            marketData.shortMakerFreeze = marketData.shortMakerFreeze.add(params._makerMargin);
            marketData.shortAmount = marketData.shortAmount.add(params._amount);
            marketData.shortOpenTotal = marketData.shortOpenTotal.add(params._total);
        }

        _marginToVault(params.marginToVault);
        _feeToExchange(params.feeToExchange);
        _transfer(params.inviter, params.feeToInviter, baseAsset == WETH);

        (uint256 _sharePrice,) = getSharePrice();
        emit OpenUpdate(
            params.orderId,
            _market,
            params.taker,
            params.inviter,
            params.feeToExchange,
            params.makerFee,
            params.feeToInviter,
            _sharePrice,
            marketData.shortOpenTotal,
            marketData.longOpenTotal
        );
        return true;
    }

    /// @notice update pool data when an order with types of close or trigger close is executed
    function closeUpdate(IPool.CloseUpdateInternalParams memory params) external _onlyMarket returns (bool){
        address _market = msg.sender;
        DataByMarket storage marketData = poolDataByMarkets[_market];
        marketData.cumulativeFee = marketData.cumulativeFee.add(params.makerFee);
        balance = balance.add(params.makerFee);

        marketData.rlzPNL = marketData.rlzPNL.add(params._makerProfit);
        {
            int256 tempProfit = params._makerProfit.add(params._makerMargin.toInt256()).add(params.fundingPayment);
            require(tempProfit >= 0, 'Pool: tempProfit is invalid');

            balance = tempProfit.add(balance.toInt256()).toUint256().add(params.payInterest);
        }

        require(marketData.takerTotalMargin >= params._takerMargin, 'Pool: takerMargin is invalid');
        marketData.takerTotalMargin = marketData.takerTotalMargin.sub(params._takerMargin);
        interestData[params._takerDirection].totalBorrowShare = interestData[params._takerDirection].totalBorrowShare.sub(params.deltaDebtShare);
        if (params.fundingPayment != 0) marketData.makerFundingPayment = marketData.makerFundingPayment.sub(params.fundingPayment);
        if (params._takerDirection == 1) {
            marketData.longAmount = marketData.longAmount.sub(params._amount);
            marketData.longOpenTotal = marketData.longOpenTotal.sub(params._total);
            marketData.longMakerFreeze = marketData.longMakerFreeze.sub(params._makerMargin);
        } else {
            marketData.shortAmount = marketData.shortAmount.sub(params._amount);
            marketData.shortOpenTotal = marketData.shortOpenTotal.sub(params._total);
            marketData.shortMakerFreeze = marketData.shortMakerFreeze.sub(params._makerMargin);
        }

        _marginToVault(params.marginToVault);
        _feeToExchange(params.feeToExchange);
        _transfer(params.taker, params.toTaker, params.isOutETH);
        _transfer(params.inviter, params.feeToInviter, baseAsset == WETH);
        _transfer(IManager(manager).riskFunding(), params.toRiskFund, false);

        (uint256 _sharePrice,) = getSharePrice();
        emit CloseUpdate(
            params.orderId,
            _market,
            params.taker,
            params.inviter,
            params.feeToExchange,
            params.makerFee,
            params.feeToInviter,
            params.toRiskFund,
            params._makerProfit.neg256(),
            params.fundingPayment,
            params.payInterest,
            _sharePrice,
            marketData.shortOpenTotal,
            marketData.longOpenTotal
        );
        return true;
    }

    function _marginToVault(uint256 _margin) internal {
        if (_margin > 0) IVault(vault).addPoolBalance(_margin);
    }

    function _feeToExchange(uint256 _fee) internal {
        if (_fee > 0) IVault(vault).addExchangeFeeBalance(_fee);
    }

    function _transfer(address _to, uint256 _amount, bool _isOutETH) internal {
        if (_amount > 0) IVault(vault).transfer(_to, _amount, _isOutETH);
    }

    /// @notice pool update when user increasing or decreasing the position margin
    function takerUpdateMargin(address _market, address taker, int256 _margin, bool isOutETH) external _onlyMarket returns (bool){
        require(_margin != 0, 'Pool: delta margin is 0');
        DataByMarket storage marketData = poolDataByMarkets[_market];

        if (_margin > 0) {
            marketData.takerTotalMargin = marketData.takerTotalMargin.add(_margin.toUint256());
            _marginToVault(_margin.toUint256());
        } else {
            marketData.takerTotalMargin = marketData.takerTotalMargin.sub(_margin.neg256().toUint256());
            _transfer(taker, _margin.neg256().toUint256(), isOutETH);
        }
        return true;
    }

    // update liquidity order when add liquidity
    function addLiquidity(
        address sender,
        uint256 amount
    ) external nonReentrant _onlyRouter whenNotAddPaused returns (
        uint256 _id
    ){
        require(sender != address(0), "Pool: sender is address(0)");
        require(amount >= minAddLiquidityAmount, 'Pool: amount < min amount');
        require(block.timestamp > lastOperationTime[sender], "Pool: operate too frequency");
        lastOperationTime[sender] = block.timestamp;

        makerOrders[autoId] = PoolDataStructure.MakerOrder(
            autoId,
            sender,
            block.timestamp,
            amount,
            0,
            0,
            sharePrice,
            0,
            0,
            PoolDataStructure.PoolAction.Deposit,
            PoolDataStructure.PoolActionStatus.Submit
        );
        _id = makerOrders[autoId].id;
        makerOrderIds[sender].push(autoId);
        autoId = autoId.add(1);
    }

    /// @notice execute add liquidity order, update order data, pnl, fundingFee, trader fee, sharePrice, liquidity totalSupply
    /// @param id order id
    function executeAddLiquidityOrder(
        uint256 id
    ) external nonReentrant _onlyRouter returns (uint256 liquidity){
        PoolDataStructure.MakerOrder storage order = makerOrders[id];
        order.status = PoolDataStructure.PoolActionStatus.Success;

        (DataByMarket memory allMarketPos, uint256 allMakerFreeze) = getAllMarketData();
        _updateBorrowIG(allMarketPos.longMakerFreeze, allMarketPos.shortMakerFreeze);
        uint256 poolInterest = getPooInterest(allMarketPos.longMakerFreeze, allMarketPos.shortMakerFreeze);

        int256 totalUnPNL;
        uint256 poolTotalTmp;
        if (balance.add(allMakerFreeze) > 0 && totalSupply > 0) {
            (totalUnPNL) = makerProfitForLiquidity(true);
            require((totalUnPNL.add(allMarketPos.makerFundingPayment).add(poolInterest.toInt256()) <= allMarketPos.takerTotalMargin.toInt256()) && (totalUnPNL.neg256().sub(allMarketPos.makerFundingPayment) <= allMakerFreeze.toInt256()), 'Pool: taker or maker is broken');
            
            poolTotalTmp = calcPoolTotal(balance, allMakerFreeze, totalUnPNL, allMarketPos.makerFundingPayment, poolInterest);
            liquidity = order.amount.mul(totalSupply).div(poolTotalTmp);
        } else {
            liquidity = order.amount.mul(10 ** decimals).div(10 ** baseAssetDecimals);
        }
        _mint(order.maker, liquidity);
        balance = balance.add(order.amount);
        poolTotalTmp = poolTotalTmp.add(order.amount);
        order.poolTotal = poolTotalTmp.toInt256();
        sharePrice = totalSupply > 0 ? calcSharePrice(poolTotalTmp) : PRICE_PRECISION;
        order.profit = allMarketPos.rlzPNL.add(allMarketPos.cumulativeFee.toInt256()).add(totalUnPNL).add(allMarketPos.makerFundingPayment).add(poolInterest.toInt256());
        order.liquidity = liquidity;
        order.sharePrice = sharePrice;

        _marginToVault(order.amount);
        //uint256 orderId, address maker, uint256 amount, uint256 share, uint256 sharePrice
        emit  ExecuteAddLiquidityOrder(id, order.maker, order.amount, liquidity, order.sharePrice);
    }

    function removeLiquidity(
        address sender,
        uint256 liquidity
    ) external nonReentrant _onlyRouter whenNotRemovePaused returns (
        uint256 _id,
        uint256 _liquidity
    ){
        require(sender != address(0), "Pool:removeLiquidity sender is zero address");
        require(liquidity >= minRemoveLiquidityAmount, "Pool: liquidity is less than the minimum limit");

        liquidity = balanceOf[sender] >= liquidity ? liquidity : balanceOf[sender];

        require(block.timestamp > lastOperationTime[sender], "Pool: operate too frequency");
        lastOperationTime[sender] = block.timestamp;

        balanceOf[sender] = balanceOf[sender].sub(liquidity);
        freezeBalanceOf[sender] = freezeBalanceOf[sender].add(liquidity);
        makerOrders[autoId] = PoolDataStructure.MakerOrder(
            autoId,
            sender,
            block.timestamp,
            0,
            liquidity,
            0,
            sharePrice,
            0,
            0,
            PoolDataStructure.PoolAction.Withdraw,
            PoolDataStructure.PoolActionStatus.Submit
        );
        _id = makerOrders[autoId].id;
        _liquidity = makerOrders[autoId].liquidity;
        makerOrderIds[sender].push(autoId);
        autoId = autoId.add(1);
    }

    /// @notice execute remove liquidity order
    /// @param id order id
    function executeRmLiquidityOrder(
        uint256 id,
        bool isETH
    ) external nonReentrant _onlyRouter returns (uint256 amount){
        PoolDataStructure.MakerOrder storage order = makerOrders[id];
        order.status = PoolDataStructure.PoolActionStatus.Success;
        (DataByMarket memory allMarketPos, uint256 allMakerFreeze) = getAllMarketData();
        _updateBorrowIG(allMarketPos.longMakerFreeze, allMarketPos.shortMakerFreeze);
        uint256 poolInterest = getPooInterest(allMarketPos.longMakerFreeze, allMarketPos.shortMakerFreeze);
        int256 totalUnPNL = makerProfitForLiquidity(false);
        require((totalUnPNL.add(allMarketPos.makerFundingPayment).add(poolInterest.toInt256()) <= allMarketPos.takerTotalMargin.toInt256()) && (totalUnPNL.neg256().sub(allMarketPos.makerFundingPayment) <= allMakerFreeze.toInt256()), 'Pool: taker or maker is broken');
        
        uint256 poolTotalTmp = calcPoolTotal(balance, allMakerFreeze, totalUnPNL, allMarketPos.makerFundingPayment, poolInterest);
        amount = order.liquidity.mul(poolTotalTmp).div(totalSupply);

        require(amount > 0, 'Pool: amount error');
        require(balance >= amount, 'Pool: Insufficient balance when remove liquidity');
        balance = balance.sub(amount);
        balanceOf[order.maker] = balanceOf[order.maker].add(order.liquidity);
        freezeBalanceOf[order.maker] = freezeBalanceOf[order.maker].sub(order.liquidity);
        _burn(order.maker, order.liquidity);

        order.amount = amount.mul(RATE_PRECISION.sub(removeLiquidityFeeRate)).div(RATE_PRECISION);
        require(order.amount > 0, 'Pool: amount error');
        order.feeToPool = amount.sub(order.amount);

        if (order.feeToPool > 0) {
            IVault(vault).addPoolRmLpFeeBalance(order.feeToPool);
            cumulateRmLiqFee = cumulateRmLiqFee.add(order.feeToPool);
        }
        poolTotalTmp = poolTotalTmp.sub(amount);
        order.poolTotal = poolTotalTmp.toInt256();
        if (totalSupply > 0) {
            sharePrice = calcSharePrice(poolTotalTmp);
        } else {
            sharePrice = PRICE_PRECISION;
        }
        order.profit = allMarketPos.rlzPNL.add(allMarketPos.cumulativeFee.toInt256()).add(totalUnPNL).add(allMarketPos.makerFundingPayment).add(poolInterest.toInt256());
        order.sharePrice = sharePrice;

        _transfer(order.maker, order.amount, isETH);
        
        emit  ExecuteRmLiquidityOrder(id, order.maker, order.amount, order.liquidity, order.sharePrice, order.feeToPool);
    }

    /// @notice  calculate unrealized pnl of positions in all markets caused by price changes
    /// @param isAdd true: add liquidity or show tvl, false: rm liquidity
    function makerProfitForLiquidity(bool isAdd) public view returns (int256 unPNL){
        for (uint256 i = 0; i < marketList.length; i++) {
            unPNL = unPNL.add(_makerProfitByMarket(marketList[i], isAdd));
        }
    }

    /// @notice calculate unrealized pnl of positions in one single market caused by price changes
    /// @param _market market address
    /// @param _isAdd true: add liquidity or show tvl, false: rm liquidity
    function _makerProfitByMarket(address _market, bool _isAdd) internal view returns (int256 unPNL){
        DataByMarket storage marketData = poolDataByMarkets[_market];
        MarketConfig memory args = marketConfigs[_market];

        int256 shortUnPNL = 0;
        int256 longUnPNL = 0;
        uint256 _price;

        if (_isAdd) {
            _price = getPriceForPool(_market, marketData.longAmount < marketData.shortAmount);
        } else {
            _price = getPriceForPool(_market, marketData.longAmount >= marketData.shortAmount);
        }

        if (args.marketType == 1) {
            int256 closeLongTotal = marketData.longAmount.mul(PRICE_PRECISION).div(_price).toInt256();
            int256 openLongTotal = marketData.longOpenTotal.toInt256();
            longUnPNL = closeLongTotal.sub(openLongTotal);

            int256 closeShortTotal = marketData.shortAmount.mul(PRICE_PRECISION).div(_price).toInt256();
            int256 openShortTotal = marketData.shortOpenTotal.toInt256();
            shortUnPNL = openShortTotal.sub(closeShortTotal);

            unPNL = shortUnPNL.add(longUnPNL);
        } else {
            int256 closeLongTotal = marketData.longAmount.mul(_price).div(PRICE_PRECISION).toInt256();
            int256 openLongTotal = marketData.longOpenTotal.toInt256();
            longUnPNL = openLongTotal.sub(closeLongTotal);

            int256 closeShortTotal = marketData.shortAmount.mul(_price).div(PRICE_PRECISION).toInt256();
            int256 openShortTotal = marketData.shortOpenTotal.toInt256();
            shortUnPNL = closeShortTotal.sub(openShortTotal);

            unPNL = shortUnPNL.add(longUnPNL);
            if (args.marketType == 2) {
                unPNL = unPNL.mul((IMarket(_market).getMarketConfig().multiplier).toInt256()).div(RATE_PRECISION.toInt256());
            }
        }

        unPNL = unPNL.mul((10 ** baseAssetDecimals).toInt256()).div(AMOUNT_PRECISION.toInt256());
    }

    /// @notice calculate and return the share price of a pool
    function getSharePrice() public view returns (
        uint256 _price,
        uint256 _balance
    ){
        (DataByMarket memory allMarketPos, uint256 allMakerFreeze) = getAllMarketData();
        uint256 poolInterest = getPooInterest(allMarketPos.longMakerFreeze, allMarketPos.shortMakerFreeze);
        int totalUnPNL = makerProfitForLiquidity(true);
        if (totalSupply > 0) {
            uint256 poolTotalTmp = calcPoolTotal(balance, allMakerFreeze, totalUnPNL, allMarketPos.makerFundingPayment, poolInterest);
            _price = calcSharePrice(poolTotalTmp);
        } else {
            _price = PRICE_PRECISION;
        }
        _balance = balance;
    }

    /// @notice set minimum amount of base asset to add liquidity
    /// @param _minAmount minimum amount
    function setMinAddLiquidityAmount(uint256 _minAmount) external _onlyController returns (bool){
        minAddLiquidityAmount = _minAmount;
        emit SetMinAddLiquidityAmount(_minAmount);
        return true;
    }

    /// @notice set minimum amount of lp to remove liquidity
    /// @param _minAmount minimum amount
    function setMinRemoveLiquidity(uint256 _minAmount) external _onlyController returns (bool){
        minRemoveLiquidityAmount = _minAmount;
        emit SetMinRemoveLiquidity(_minAmount);
        return true;
    }

    /// @notice set fund utilization limit for markets supported by this pool.
    /// @param _market market address
    /// @param _openRate rate
    /// @param _openLimit limit amount for base asset
    function setOpenRateAndLimit(address _market, uint256 _openRate, uint256 _openLimit) external _onlyController returns (bool){
        MarketConfig storage args = marketConfigs[_market];
        args.fundUtRateLimit = _openRate;
        args.openLimit = _openLimit;
        emit SetOpenRateAndLimit(_market, _openRate, _openLimit);
        return true;
    }

    /// @notice set fund reserve rate for pool
    /// @param _reserveRate reserve rate
    function setReserveRate(uint256 _reserveRate) external _onlyController returns (bool){
        reserveRate = _reserveRate;
        emit SetReserveRate(_reserveRate);
        return true;
    }

    /// @notice set remove lp fee Rate rate
    /// @param _ratio fee _ratio
    function setRemoveLiquidityFeeRatio(uint256 _ratio) external _onlyController returns (bool){
        removeLiquidityFeeRate = _ratio;
        emit SetRemoveLiquidityFeeRatio(_ratio);
        return true;
    }

    /// @notice set paused flags for adding and remove liquidity
    /// @param _add flag for adding liquidity
    /// @param _remove flag for remove liquidity
    function setPaused(bool _add, bool _remove) external _onlyController {
        addPaused = _add;
        removePaused = _remove;
        emit SetPaused(_add, _remove);
    }

    /// @notice set interest logic contract address
    /// @param _interestLogic contract address
    function setInterestLogic(address _interestLogic) external _onlyController {
        require(_interestLogic != address(0), "Pool: invalid interestLogic");
        interestLogic = _interestLogic;
        emit SetInterestLogic(_interestLogic);
    }

    /// @notice set market price feed contract address
    /// @param _marketPriceFeed contract address
    function setMarketPriceFeed(address _marketPriceFeed) external _onlyController {
        require(_marketPriceFeed != address(0), "Pool: invalid marketPriceFeed");
        marketPriceFeed = _marketPriceFeed;
        emit SetMarketPriceFeed(_marketPriceFeed);
    }

    /// @notice get adding or removing liquidity order id list
    /// @param _maker address
    function getMakerOrderIds(address _maker) external view returns (uint256[] memory){
        return makerOrderIds[_maker];
    }

    /// @notice validate whether this open order can be executed
    ///         every market open interest is limited by two params, the open limit and the funding utilization rate limit
    /// @param _market market address
    /// @param _makerMargin margin taken from the pool of this order
    function canOpen(address _market, uint256 _makerMargin) public view returns (bool _can){
        // balance - margin >= (balance + frozen) * reserveRatio
        // => balance >= margin + (balance + frozen) * reserveRatio >= margin
        // when reserve ratio == 0  => balance >= margin

        (,uint256 allMakerFreeze) = getAllMarketData();
        uint256 reserveAmount = balance.add(allMakerFreeze).mul(reserveRate).div(RATE_PRECISION);
        if (balance < reserveAmount.add(_makerMargin)) {
            return false;
        }

        uint256 openLimitFunds = getMarketLimit(_market, allMakerFreeze);
        DataByMarket memory marketData = poolDataByMarkets[_market];
        uint256 marketUsedFunds = marketData.longMakerFreeze.add(marketData.shortMakerFreeze).add(_makerMargin);
        return marketUsedFunds <= openLimitFunds;
    }

    function getLpBalanceOf(address _maker) external view returns (uint256 _balance, uint256 _totalSupply){
        _balance = balanceOf[_maker];
        _totalSupply = totalSupply;
    }

    function updateFundingPayment(address _market, int256 _fundingPayment) external _onlyMarket {
        if (_fundingPayment != 0) {
            DataByMarket storage marketData = poolDataByMarkets[_market];
            marketData.makerFundingPayment = marketData.makerFundingPayment.add(_fundingPayment);
        }
    }

    /// notice update interests global information
    function updateBorrowIG() public {
        (DataByMarket memory allMarketPos,) = getAllMarketData();
        _updateBorrowIG(allMarketPos.longMakerFreeze, allMarketPos.shortMakerFreeze);
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

    /// @notice get current borrowIG
    /// @param _direction position direction
    function getCurrentBorrowIG(int8 _direction) public view returns (uint256 _borrowRate, uint256 _borrowIG){
        (DataByMarket memory allMarketPos,) = getAllMarketData();
        return _getCurrentBorrowIG(_direction, allMarketPos.longMakerFreeze, allMarketPos.shortMakerFreeze);
    }

    /// @notice calculate the latest interest index global
    /// @param _direction position direction
    /// @param _longMakerFreeze sum of pool assets taken by the long positions
    /// @param _shortMakerFreeze sum of pool assets taken by the short positions
    function _getCurrentBorrowIG(int8 _direction, uint256 _longMakerFreeze, uint256 _shortMakerFreeze) internal view returns (uint256 _borrowRate, uint256 _borrowIG){
        require(_direction == 1 || _direction == - 1, "invalid direction");
        IPool.InterestData memory data = interestData[_direction];

        // calc util need usedBalance,totalBalance,reserveRate
        //(DataByMarket memory allMarketPos, uint256 allMakerFreeze) = getAllMarketData();
        uint256 usedBalance = _direction == 1 ? _longMakerFreeze : _shortMakerFreeze;
        uint256 totalBalance = balance.add(_longMakerFreeze).add(_shortMakerFreeze);

        (_borrowRate, _borrowIG) = IInterestLogic(interestLogic).getMarketBorrowIG(address(this), usedBalance, totalBalance, reserveRate, data.lastInterestUpdateTs, data.borrowIG);
    }

    function getCurrentAmount(int8 _direction, uint256 share) public view returns (uint256){
        (DataByMarket memory allMarketPos,) = getAllMarketData();
        return _getCurrentAmount(_direction, share, allMarketPos.longMakerFreeze, allMarketPos.shortMakerFreeze);
    }

    function _getCurrentAmount(int8 _direction, uint256 share, uint256 _longMakerFreeze, uint256 _shortMakerFreeze) internal view returns (uint256){
        (,uint256 ig) = _getCurrentBorrowIG(_direction, _longMakerFreeze, _shortMakerFreeze);
        return IInterestLogic(interestLogic).getBorrowAmount(share, ig).mul(10 ** baseAssetDecimals).div(AMOUNT_PRECISION);
    }

    function getCurrentShare(int8 _direction, uint256 amount) external view returns (uint256){
        (DataByMarket memory allMarketPos,) = getAllMarketData();
        (,uint256 ig) = _getCurrentBorrowIG(_direction, allMarketPos.longMakerFreeze, allMarketPos.shortMakerFreeze);
        return IInterestLogic(interestLogic).getBorrowShare(amount.mul(AMOUNT_PRECISION).div(10 ** baseAssetDecimals), ig);
    }

    /// @notice get the fund utilization information of a market
    /// @param _market market address
    function getMarketAmount(address _market) external view returns (uint256, uint256, uint256){
        DataByMarket memory marketData = poolDataByMarkets[_market];
        (,uint256 allMakerFreeze) = getAllMarketData();
        uint256 openLimitFunds = getMarketLimit(_market, allMakerFreeze);
        return (marketData.longMakerFreeze, marketData.shortMakerFreeze, openLimitFunds);
    }

    /// @notice calculate the sum data of all markets
    function getAllMarketData() public view returns (DataByMarket memory allMarketPos, uint256 allMakerFreeze){
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

    /// @notice get all assets of this pool including fund available to borrow and taken by positions
    function getAssetAmount() public view returns (uint256 amount){
        (, uint256 allMakerFreeze) = getAllMarketData();
        return balance.add(allMakerFreeze);
    }

    /// @notice get asset of pool
    function getBaseAsset() public view returns (address){
        return baseAsset;
    }

    /// @notice get interest of this pool
    /// @return result the interest principal not included
    function getPooInterest(uint256 _longMakerFreeze, uint256 _shortMakerFreeze) internal view returns (uint256){
        //(DataByMarket memory allMarketPos,) = getAllMarketData();
        uint256 longShare = interestData[1].totalBorrowShare;
        uint256 shortShare = interestData[- 1].totalBorrowShare;
        uint256 longInterest = _getCurrentAmount(1, longShare, _longMakerFreeze, _shortMakerFreeze).sub(_longMakerFreeze);
        uint256 shortInterest = _getCurrentAmount(- 1, shortShare, _longMakerFreeze, _shortMakerFreeze).sub(_shortMakerFreeze);
        return longInterest.add(shortInterest);
    }

    /// @notice get market open limit
    /// @param _market market address
    /// @return openLimitFunds the max funds used to open
    function getMarketLimit(address _market, uint256 _allMakerFreeze) internal view returns (uint256 openLimitFunds){
        MarketConfig memory args = marketConfigs[_market];
        uint256 availableAmount = balance.add(_allMakerFreeze).mul(RATE_PRECISION.sub(reserveRate)).div(RATE_PRECISION);
        uint256 openLimitByRatio = availableAmount.mul(args.fundUtRateLimit).div(RATE_PRECISION);
        openLimitFunds = openLimitByRatio > args.openLimit ? args.openLimit : openLimitByRatio;
    }

    /// @notice get index price to calculate the pool unrealized pnl
    /// @param _market market address
    /// @param _maximise should maximise the price
    function getPriceForPool(address _market, bool _maximise) internal view returns (uint256){
        return IMarketPriceFeed(marketPriceFeed).priceForPool(IMarket(_market).token(), _maximise);
    }

    /// @notice calc pool total valuation including available balance, margin taken by positions, unPNL, funding and interests
    /// @param _balance balance
    /// @param _allMakerFreeze total margin taken by positions
    /// @param _totalUnPNL total unrealized pnl of all positions
    /// @param _makerFundingPayment total funding payment
    /// @param _poolInterest total interests
    function calcPoolTotal(uint256 _balance, uint256 _allMakerFreeze, int256 _totalUnPNL, int256 _makerFundingPayment, uint256 _poolInterest) internal view returns (uint256){
        return _balance.toInt256()
        .add(_allMakerFreeze.toInt256())
        .add(_totalUnPNL)
        .add(_makerFundingPayment)
        .add(_poolInterest.toInt256())
        .toUint256();
    }

    /// @notice calc share price of lp
    /// @param _totalBalance total valuation of this pool
    function calcSharePrice(uint256 _totalBalance) internal view returns (uint256){
        return _totalBalance
        .mul(10 ** decimals)
        .div(totalSupply)
        .mul(PRICE_PRECISION)
        .div(10 ** baseAssetDecimals);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import "../libraries/PoolDataStructure.sol";
import "../interfaces/IPool.sol";

contract PoolStorage {
    //
    // data for this pool
    //

    // constant
    uint256  constant RATE_PRECISION = 1e6;                     // example rm lp fee rate 1000/1e6=0.001
    uint256  constant PRICE_PRECISION = 1e10;
    uint256  constant AMOUNT_PRECISION = 1e20;

    // contracts addresses used
    address public vault;                                       // vault address
    address baseAsset;                                          // base token address
    address marketPriceFeed;                                    // price feed contract address
    uint256 public baseAssetDecimals;                           // base token decimals
    address public interestLogic;                               // interest logic address
    address public WETH;                                        // WETH address 

    bool public addPaused = false;                              // flag for adding liquidity
    bool public removePaused = false;                           // flag for remove liquidity
    uint256 public minRemoveLiquidityAmount;                    // minimum amount (lp) for removing liquidity
    uint256 public minAddLiquidityAmount;                       // minimum amount (asset) for add liquidity
    uint256 public removeLiquidityFeeRate = 1000;               // fee ratio for removing liquidity

    uint256 public balance;                                     // balance that is available to use of this pool
    uint256 public reserveRate;                                 // reserve ratio
    uint256 public sharePrice;                                  // net value
    uint256 public cumulateRmLiqFee;                            // cumulative fee collected when removing liquidity
    uint256 public autoId = 1;                                  // liquidity operations order id
    mapping(address => uint256) lastOperationTime;              // mapping of last operation timestamp for addresses

    address[] public marketList;                                // supported markets array
    mapping(address => bool) public isMarket;                   // supported markets mapping
    mapping(uint256 => PoolDataStructure.MakerOrder) makerOrders;           // liquidity orders
    mapping(address => uint256[]) public makerOrderIds;         // mapping of liquidity orders for addresses
    mapping(address => uint256) public freezeBalanceOf;         // frozen liquidity amount when removing
    mapping(address => MarketConfig) public marketConfigs;      // mapping of market configs
    mapping(address => DataByMarket) public poolDataByMarkets;  // mapping of market data
    mapping(int8 => IPool.InterestData) public interestData;    // mapping of interest data for position directions (long or short)

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
        uint256 longAmount;                                     // sum asset for long pos
        uint256 longOpenTotal;                                  // sum value  for long pos
        uint256 shortAmount;                                    // sum asset for short pos
        uint256 shortOpenTotal;                                 // sum value for short pos
    }

    event RegisterMarket(address market);
    event SetMinAddLiquidityAmount(uint256 minAmount);
    event SetMinRemoveLiquidity(uint256 minLp);
    event SetOpenRateAndLimit(address market, uint256 openRate, uint256 openLimit);
    event SetReserveRate(uint256 reserveRate);
    event SetRemoveLiquidityFeeRatio(uint256 feeRate);
    event SetPaused(bool addPaused, bool removePaused);
    event SetInterestLogic(address interestLogic);
    event SetMarketPriceFeed(address marketPriceFeed);
    event ExecuteAddLiquidityOrder(uint256 orderId, address maker, uint256 amount, uint256 share, uint256 sharePrice);
    event ExecuteRmLiquidityOrder(uint256 orderId, address maker, uint256 rmAmount, uint256 rmShare, uint256 sharePrice, uint256 rmFee);
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

// SPDX-License-Identifier: GPL-2.0-or-later
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

    function checkSigner(address _signer) external view returns (bool);

    function checkController(address _controller) view external returns (bool);

    function checkRouter(address _router) external view returns (bool);

    function checkMarket(address _market) external view returns (bool);

    function checkPool(address _pool) external view returns (bool);

    function cancelElapse() external view returns (uint256);

    function triggerOrderDuration() external view returns (uint256);

    function paused() external returns (bool);
    
    function getMakerByMarket(address maker) external view returns (address);

    function getMarketMarginAsset(address) external view returns (address);

    function isFundingPaused() external view returns (bool);

    function isInterestPaused() external view returns (bool);

    function executeOrderFee() external view returns (uint256);

    function inviteManager() external view returns (address);

    function getAllMarkets() external view returns (address[] memory);

    function getAllPools() external view returns (address[] memory);

    function orderNumLimit() external view returns (uint256);

    function checkTreasurer(address _treasurer) external view returns (bool);

    function checkLiquidator(address _liquidator) external view returns (bool);
    
    function communityExecuteOrderDelay() external view returns (uint256);
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

    function executeOrder(uint256 _id) external returns (int256, uint256);

    function updateMargin(uint256 _id, uint256 _updateMargin, bool isIncrease) external;

    function liquidate(uint256 _id, MarketDataStructure.OrderType action) external returns (uint256);

    function setTPSLPrice(uint256 _id, uint256 _profitPrice, uint256 _stopLossPrice) external;

    function takerOrderNum(address, MarketDataStructure.OrderType) external view returns (uint256);

    function getLogicAddress() external view returns (address);

    function initialize(string memory _indexToken, address _clearAnchor, address _pool, uint8 _marketType) external;

    function switchPositionMode(address _taker, MarketDataStructure.PositionMode _mode) external;

    function orderID() external view returns (uint256);

    function lastExecutedOrderId() external view returns (uint256);

    function triggerOrderID() external view returns (uint256);

    function marketLogic() external view returns (address);

    function token() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;

interface IMarketPriceFeed {
    function priceForTrade(string memory _token, uint256 value, uint256 maxValue, bool _maximise) external view returns (uint256);

    function priceForPool(string memory _token, bool _maximise) external view returns (uint256);

    function priceForLiquidate(string memory _token, bool _maximise) external view returns (uint256);

    function priceForIndex(string memory _token, bool _maximise) external view returns (uint256);

    function getLatestPrimaryPrice(string memory _token) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "../libraries/PoolDataStructure.sol";
import "../core/PoolStorage.sol";

interface IPool {
    struct InterestData {
        uint256 totalBorrowShare;
        uint256 lastInterestUpdateTs;
        uint256 borrowIG;
    }

    /// @notice the following tow structs are parameters used to update pool data when an order is executed.
    ///         We differ the affect of the executed order by result as open or close,
    ///         which represents increase or decrease the position.
    ///         Normally, there's one type of pool update operation during one order execution,
    ///         excepts in the one-way position model, when an order causing the position reversal, both opening and
    ///         closing process will be executed respectively.

    struct OpenUpdateInternalParams {
        uint256 orderId;
        uint256 _makerMargin;   // pool balance taken by this order
        uint256 _takerMargin;   // taker margin for this order
        uint256 _amount;        // order amount
        uint256 _total;         // order value
        uint256 makerFee;       // fees distributed to the pool, specially when an order causes the position reversal, the fee to maker will be updated in the closing process
        int8 _takerDirection;   // order direction
        uint256 marginToVault;  // margin should transferred to the vault
        address taker;          // taker address
        uint256 feeToInviter;   // fees distributed to the inviter, specially when an order causes the position reversal, the fee to maker will be updated in the closing process
        address inviter;        // inviter address
        uint256 deltaDebtShare; //add position debt share
        uint256 feeToExchange;  // fee distributed to the protocol, specially when an order causes the position reversal, the fee to maker will be updated in the closing process
    }

    struct CloseUpdateInternalParams {
        uint256 orderId;
        uint256 _makerMargin;//reduce maker margin，taker margin，amount，value
        uint256 _takerMargin;
        uint256 _amount;
        uint256 _total;
        int256 _makerProfit;
        uint256 makerFee;   //trade fee to maker
        int256 fundingPayment;//settled funding payment
        int8 _takerDirection;//old position direction
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

    function setMinAddLiquidityAmount(uint256 _minAmount) external returns (bool);

    function setMinRemoveLiquidity(uint256 _minLiquidity) external returns (bool);

    function setOpenRate(address _market, uint256 _openRate, uint256 _openLimit) external returns (bool);

    //function setRemoveLiquidityFeeRatio(uint256 _rate) external returns (bool);

    function canOpen(address _market, uint256 _makerMargin) external view returns (bool);

    function getMakerOrderIds(address _maker) external view returns (uint256[] memory);

    function getOrder(uint256 _no) external view returns (PoolDataStructure.MakerOrder memory);

    function openUpdate(OpenUpdateInternalParams memory params) external returns (bool);

    function closeUpdate(CloseUpdateInternalParams memory params) external returns (bool);

    function takerUpdateMargin(address _market, address, int256 _margin, bool isOutETH) external returns (bool);

    function addLiquidity(address sender, uint256 amount) external returns (uint256 _id);

    function executeAddLiquidityOrder(uint256 id) external returns (uint256 liquidity);

    function removeLiquidity(address sender, uint256 liquidity) external returns (uint256 _id, uint256 _liquidity);

    function executeRmLiquidityOrder(uint256 id, bool isETH) external returns (uint256 amount);

    function getLpBalanceOf(address _maker) external view returns (uint256 _balance, uint256 _totalSupply);

    function registerMarket(address _market) external returns (bool);

    function getSharePrice() external view returns (
        uint256 _price,
        uint256 _balance
    );

    function updateFundingPayment(address _market, int256 _fundingPayment) external;

    function getMarketAmount(address _market) external view returns (uint256, uint256, uint256);

    function getCurrentBorrowIG(int8 _direction) external view returns (uint256 _borrowRate, uint256 _borrowIG);

    function getCurrentAmount(int8 _direction, uint256 share) external view returns (uint256);

    function getCurrentShare(int8 _direction, uint256 amount) external view returns (uint256);

    function updateBorrowIG() external;

    function getAllMarketData() external view returns (PoolStorage.DataByMarket memory allMarketPos, uint256 allMakerFreeze);

    function getAssetAmount() external view returns (uint256 amount);

    function getBaseAsset() external view returns (address);

    function getAutoId() external view returns (uint256);

//    function updateLiquidatorFee(address _liquidator) external;

    function minRemoveLiquidityAmount() external view returns (uint256);

    function minAddLiquidityAmount() external view returns (uint256);

    function removeLiquidityFeeRate() external view returns (uint256);

    function reserveRate() external view returns (uint256);

    function addPaused() external view returns (bool);

    function removePaused() external view returns (bool);

    function makerProfitForLiquidity(bool isAdd) external view returns (int256 unPNL);
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
        UserStopLoss
    }

    /// @notice position mode, one-way or hedge
    enum PositionMode{
        OneWay,
        Hedge
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
        
        uint256 createTs;                         // create timestamp
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
library PoolDataStructure {
    enum PoolAction {
        Deposit,
        Withdraw
    }

    enum PoolActionStatus {
        Submit,
        Success,
        Fail,
        Cancel
    }

    /// @notice data structure of adding or removing liquidity order
    struct MakerOrder {
        uint256 id;                     // liquidity order id, generated by counter
        address maker;                  // user address
        uint256 submitBlockTimestamp;   // timestamp when order submitted
        uint256 amount;                 // base asset amount
        uint256 liquidity;              // liquidity
        uint256 feeToPool;              // fee charged when remove liquidity
        uint256 sharePrice;             // pool share price when order is executed
        int256 poolTotal;               // pool total valuation when order is executed
        int256 profit;                  // pool profit when order is executed, pnl + funding earns + interest earns
        PoolAction action;              // order action type
        PoolActionStatus status;        // order status
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
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

// SPDX-License-Identifier: GPL-2.0-or-later
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

// SPDX-License-Identifier: GPL-2.0-or-later
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

// SPDX-License-Identifier: GPL-2.0-or-later
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

// SPDX-License-Identifier: GPL-2.0-or-later
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