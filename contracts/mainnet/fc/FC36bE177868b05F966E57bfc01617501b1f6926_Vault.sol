// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../utils/EnumerableValues.sol";
import "./VaultMSData.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IVaultUtils.sol";
import "./interfaces/IVaultPriceFeedV2.sol";
import "./interfaces/IVaultStorage.sol";
import "../DID/interfaces/IESBT.sol";

contract Vault is ReentrancyGuard, IVault, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableValues for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableValues for EnumerableSet.AddressSet;

    uint8 public override baseMode;
    bool public override isSwapEnabled = true;

    IESBT public eSBT;
    IVaultUtils public vaultUtils;
    IVaultStorage public vaultStorage;
    address public override priceFeed;
    address public override usdx;

    mapping(address => bool) public override isManager;
    mapping(address => bool) public override approvedRouters;

    uint256 public override totalTokenWeights;
    uint256 public override usdxSupply;
    EnumerableSet.AddressSet tradingTokens;
    EnumerableSet.AddressSet fundingTokens;
    mapping(address => VaultMSData.TokenBase) tokenBase;
    mapping(address => uint256) public override usdxAmounts;     // usdxAmounts tracks the amount of USDX debt for each whitelisted token
    mapping(address => uint256) public override guaranteedUsd;

    // feeReserves tracks the amount of fees per token
    mapping(address => uint256) public override feeReserves;
    mapping(address => uint256) public override feeSold;
    mapping(uint256 => uint256) public override feeReservesRecord;  //recorded by timestamp/24hours
    uint256 public override feeReservesUSD;
    uint256 public override feeReservesDiscountedUSD;
    uint256 public override feeClaimedUSD;

    mapping(address => VaultMSData.TradingFee) tradingFee;
    mapping(bytes32 => VaultMSData.Position) positions;

    mapping(address => VaultMSData.TradingRec) tradingRec;
    uint256 public override globalShortSize;
    uint256 public override globalLongSize;


    modifier onlyManager() {
        _validate(isManager[msg.sender], 4);
        _;
    }

    event Swap(address account, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, uint256 amountOutAfterFees, uint256 feeBasisPoints);
    event IncreasePosition(bytes32 key, address account, address collateralToken, address indexToken, uint256 collateralDelta, uint256 sizeDelta,bool isLong, uint256 price, int256 fee);
    // event DecreasePosition(bytes32 key, address account, address collateralToken, address indexToken, uint256 collateralDelta, uint256 sizeDelta, bool isLong, uint256 price, int256 fee, uint256 usdOut, uint256 latestCollatral, uint256 prevCollateral);
    event DecreasePosition(bytes32 key, VaultMSData.Position position, uint256 collateralDelta, uint256 sizeDelta, uint256 price, int256 fee, uint256 usdOut, uint256 latestCollatral, uint256 prevCollateral);
    event DecreasePositionTransOut( bytes32 key,uint256 transOut);
    event LiquidatePosition(bytes32 key, address account, address collateralToken, address indexToken, bool isLong, uint256 size, uint256 collateral, uint256 reserveAmount, int256 realisedPnl, uint256 markPrice);
    event UpdatePosition(bytes32 key, address account, uint256 size,  uint256 collateral, uint256 averagePrice, uint256 entryFundingRate, uint256 reserveAmount, int256 realisedPnl, uint256 markPrice);
    event ClosePosition(bytes32 key, address account, uint256 size, uint256 collateral, uint256 averagePrice, uint256 entryFundingRate, uint256 reserveAmount, int256 realisedPnl);
    event UpdateFundingRate(address token, uint256 fundingRate);
    event UpdatePnl(bytes32 key, bool hasProfit, uint256 delta, uint256 currentSize, uint256 currentCollateral, uint256 usdOut, uint256 usdOutAfterFee);
    event CollectSwapFees(address token, uint256 feeUsd, uint256 feeTokens);
    event CollectMarginFees(address token, uint256 feeUsd, uint256 feeTokens);
    event DirectPoolDeposit(address token, uint256 amount);
    event IncreasePoolAmount(address token, uint256 amount);
    event DecreasePoolAmount(address token, uint256 amount);
    event IncreaseReservedAmount(address token, uint256 amount);
    event DecreaseReservedAmount(address token, uint256 amount);
    event IncreaseGuaranteedUsd(address token, uint256 amount);
    event DecreaseGuaranteedUsd(address token, uint256 amount);

    event PayTax(address _account, bytes32 _key, uint256 profit, uint256 usdTax);
    // event UpdateGlobalSize(address _indexToken, uint256 tokenSize, uint256 globalSize, uint256 averagePrice, bool _increase, bool _isLong );
    event CollectPremiumFee(address account,uint256 _size, int256 _entryPremiumRate, int256 _premiumFeeUSD);

    function initialize(
        address _usdx,
        address _priceFeed,
        uint8 _baseMode
    ) external onlyOwner{
        require(baseMode==0, "i0");
        usdx = _usdx;
        priceFeed = _priceFeed;
        require(_baseMode > 0 && _baseMode < 3, "I1");
        baseMode = _baseMode;
        tokenBase[usdx].decimal = 18;
    }
    // ---------- owner setting part ----------
    function setVaultUtils(address _vaultUtils) external override onlyOwner{
        vaultUtils = IVaultUtils(_vaultUtils);
    }
    function setVaultStorage(address _vaultStorage) external override onlyOwner{
        vaultStorage = IVaultStorage(_vaultStorage);
    }
    function setESBT(address _eSBT) external override onlyOwner{
        eSBT = IESBT(_eSBT);
    }
    function setManager(address _manager, bool _isManager) external override onlyOwner{
        isManager[_manager] = _isManager;
    }
    function setIsSwapEnabled(bool _isSwapEnabled) external override onlyOwner{
        isSwapEnabled = _isSwapEnabled;
    }
    function setPriceFeed(address _priceFeed) external override onlyOwner{
        priceFeed = _priceFeed;
    }
    function setRouter(address _router, bool _status) external override onlyOwner{
        approvedRouters[_router] = _status;
    }
    function setUsdxAmount(address _token, uint256 _amount, bool _increase) external override onlyOwner{
        if (_increase)
            _increaseUsdxAmount(_token, _amount);
        else
            _decreaseUsdxAmount(_token, _amount);
    }

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _tokenWeight,
        uint256 _maxUSDAmount,
        bool _isStable,
        bool _isFundingToken,
        bool _isTradingToken
    ) external override onlyOwner{
        if (_isTradingToken && !tradingTokens.contains(_token)) {
            tradingTokens.add(_token);
        }
        if (_isFundingToken && !fundingTokens.contains(_token)) {
            fundingTokens.add(_token);
        }        
        VaultMSData.TokenBase storage tBase = tokenBase[_token];
        totalTokenWeights = totalTokenWeights.add(_tokenWeight).sub(tBase.weight);
        tBase.weight = _tokenWeight;
        tBase.isStable = _isStable;
        tBase.isFundable = _isFundingToken;
        require(_tokenDecimals > 0, "invalid decimal");
        tBase.decimal = _tokenDecimals;
        tBase.maxUSDAmounts = _maxUSDAmount;
        getMaxPrice(_token);// validate price feed
    }

    function clearTokenConfig(address _token) external override onlyOwner{
        if (tradingTokens.contains(_token)) {
            tradingTokens.remove(_token);
        }
        if (fundingTokens.contains(_token)) {
            totalTokenWeights = totalTokenWeights.sub(tokenBase[_token].weight);
            fundingTokens.remove(_token);
        }  
    }
    // the governance controlling this function should have a timelock
    function upgradeVault(address _newVault, address _token, uint256 _amount) external onlyOwner{
        IERC20(_token).safeTransfer(_newVault, _amount);
    }
    //---------- END OF owner setting part ----------



    //---------- FUNCTIONS FOR MANAGER ----------
    function buyUSDX(address _token, address _receiver) external override nonReentrant onlyManager returns (uint256) {
        _validate(fundingTokens.contains(_token), 16);
        uint256 tokenAmount = _transferIn(_token);
        _validate(tokenAmount > 0, 17);
        updateRate(_token);
        uint256 price = getMinPrice(_token);
        uint256 usdxAmount = tokenAmount.mul(price).div(VaultMSData.PRICE_PRECISION);
        usdxAmount = adjustForDecimals(usdxAmount, _token, usdx);
        _validate(usdxAmount > 0, 18);
        usdxAmounts[msg.sender] = usdxAmounts[msg.sender].add(usdxAmount);
        uint256 feeBasisPoints = vaultUtils.getBuyUsdxFeeBasisPoints(_token, usdxAmount);
        uint256 amountAfterFees = _collectSwapFees(_token, tokenAmount, feeBasisPoints);
        uint256 mintAmount = amountAfterFees.mul(price).div(VaultMSData.PRICE_PRECISION);
        mintAmount = adjustForDecimals(mintAmount, _token, usdx);
        _increaseUsdxAmount(_token, mintAmount);
        _increasePoolAmount(_token, amountAfterFees);
        usdxSupply = usdxSupply.add(mintAmount);
        _increaseUsdxAmount(_receiver, mintAmount);
        updateRate(_token);

        return mintAmount;
    }

    function sellUSDX(address _token, address _receiver,  uint256 _usdxAmount) external override nonReentrant onlyManager returns (uint256) {
        _validate(fundingTokens.contains(_token), 19);
        _validate(usdxAmounts[msg.sender] > _usdxAmount, 2);
        uint256 usdxAmount = _usdxAmount; // _transferIn(usdx);
        _validate(usdxAmount > 0, 20);
        updateRate(_token);
        uint256 redemptionAmount = getRedemptionAmount(_token, usdxAmount);
        _validate(redemptionAmount > 0, 21);
        _decreaseUsdxAmount(_token, usdxAmount);
        _decreasePoolAmount(_token, redemptionAmount);
        usdxSupply = usdxSupply > usdxAmount ? usdxSupply.sub(usdxAmount) : 0;
        usdxAmounts[msg.sender] = usdxAmounts[msg.sender].sub(_usdxAmount);
        uint256 feeBasisPoints = vaultUtils.getSellUsdxFeeBasisPoints(_token, usdxAmount);
        uint256 amountOut = _collectSwapFees(_token, redemptionAmount, feeBasisPoints);
        _validate(amountOut > 0, 22);
        _transferOut(_token, amountOut, _receiver);
        updateRate(_token);
        return amountOut;
    }

    function claimFeeToken(address _token) external override nonReentrant onlyManager returns (uint256) {
        if (!fundingTokens.contains(_token)) {
            return 0;
        }
        require(feeReserves[_token] >= feeSold[_token], "insufficient Fee");
        uint256 _amount = feeReserves[_token].sub(feeSold[_token]);
        feeSold[_token] = feeReserves[_token];
        if (_amount > 0) {
            _transferOut(_token, _amount, msg.sender);
        }
        return _amount;
    }

    function claimFeeReserves() external override onlyManager returns (uint256) {
        uint256 feeToClaim = feeReservesUSD.sub(feeReservesDiscountedUSD).sub(feeClaimedUSD);
        feeClaimedUSD = feeReservesUSD.sub(feeReservesDiscountedUSD);
        return feeToClaim;
    }


    //---------------------------------------- TRADING FUNCTIONS --------------------------------------------------
    function swap(address _tokenIn,  address _tokenOut, address _receiver ) external override nonReentrant returns (uint256) {
        _validate(isSwapEnabled, 23);
        return _swap(_tokenIn, _tokenOut, _receiver );
    }

    /// ATTENTION : Not open in current version
    // function editRatio(bytes32 _key, uint256 _lossRatio, uint256 _profitRatio) public nonReentrant{
    //     _validate(approvedRouters[msg.sender], 5);
    //     VaultMSData.Position storage position = positions[_key];
    //     vaultUtils.validateRatioDelta(_key, _lossRatio, _profitRatio);
    //     position.stopLossRatio = _lossRatio;
    //     position.takeProfitRatio = _profitRatio;
    // }

    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external override nonReentrant {
        _validate(approvedRouters[msg.sender], 41);
        
        //update cumulative funding rate
        updateRate(_collateralToken);
        if (_indexToken!= _collateralToken) updateRate(_indexToken);

        bytes32 key = vaultUtils.getPositionKey( _account, _collateralToken, _indexToken, _isLong, 0);
        VaultMSData.Position storage position = positions[key];
        vaultUtils.validateIncreasePosition(_collateralToken, _indexToken, position.size, _sizeDelta ,_isLong);

        uint256 price = _isLong ? getMaxPrice(_indexToken) : getMinPrice(_indexToken);
        price = vaultUtils.getImpactedPrice(_indexToken, _sizeDelta, price, _isLong);
        if (position.size == 0) {
            position.account = _account;
            position.averagePrice = price;
            position.aveIncreaseTime = block.timestamp;
            position.collateralToken = _collateralToken;
            position.indexToken = _indexToken;
            position.isLong = _isLong;       
        }
        else if (position.size > 0 && _sizeDelta > 0) {
            position.aveIncreaseTime = vaultUtils.getNextIncreaseTime(position.aveIncreaseTime, position.size, _sizeDelta); 
            position.averagePrice = vaultUtils.getPositionNextAveragePrice(position.size, position.averagePrice, price, _sizeDelta, true);
        }
        uint256 collateralDelta = _transferIn(_collateralToken);
        uint256 collateralDeltaUsd = tokenToUsdMin(_collateralToken, collateralDelta);
        position.collateral = position.collateral.add(collateralDeltaUsd);
        position.accCollateral = position.accCollateral.add(collateralDeltaUsd);
        _increaseGuaranteedUsd(_collateralToken, collateralDeltaUsd);
        _increasePoolAmount(_collateralToken,  collateralDelta);//aum = pool + aveProfit - guaranteedUsd
        
        //call updateRate before collect Margin Fees
        int256 fee = _collectMarginFees(key, _sizeDelta); //increase collateral before collectMarginFees
        position.lastUpdateTime = block.timestamp;//attention: after _collectMarginFees
        
        // run after collectMarginFees
        position.entryFundingRateSec = tradingFee[_collateralToken].accumulativefundingRateSec;
        position.entryPremiumRateSec = _isLong ? tradingFee[_indexToken].accumulativeLongRateSec : tradingFee[_indexToken].accumulativeShortRateSec;

        position.size = position.size.add(_sizeDelta);
        _validate(position.size > 0, 30);
        _validatePosition(position.size, position.collateral);

        vaultUtils.validateLiquidation(key, true);

        // reserve tokens to pay profits on the position
        {
            uint256 reserveDelta = vaultUtils.getReserveDelta(position.collateralToken, position.size, position.collateral, position.takeProfitRatio);
            if (position.reserveAmount > 0)
                _decreaseReservedAmount(_collateralToken, position.reserveAmount);
            _increaseReservedAmount(_collateralToken, reserveDelta);
            position.reserveAmount = reserveDelta;//position.reserveAmount.add(reserveDelta);
        }
       
        _updateGlobalSize(_isLong, _indexToken, _sizeDelta, price, true);
    
        //update rates according to latest positions and token utilizations
        updateRate(_collateralToken);
        if (_indexToken!= _collateralToken) updateRate(_indexToken);            
        
        vaultStorage.addKey(_account,key);
        emit IncreasePosition(key, _account, _collateralToken, _indexToken, collateralDeltaUsd,
            _sizeDelta, _isLong, price, fee);
        emit UpdatePosition( key, _account, position.size, position.collateral, position.averagePrice,
            position.entryFundingRateSec.mul(3600).div(1000000), position.reserveAmount, position.realisedPnl, price );
    }

    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver
        ) external override nonReentrant returns (uint256) {
        _validate(approvedRouters[msg.sender] || _account == msg.sender, 41);
        bytes32 key = vaultUtils.getPositionKey(_account, _collateralToken, _indexToken, _isLong, 0);
        return _decreasePosition(key, _collateralDelta, _sizeDelta, _receiver);
    }

    function _decreasePosition(bytes32 key, uint256 _collateralDelta, uint256 _sizeDelta, address _receiver) private returns (uint256) {
        // bytes32 key = vaultUtils.getPositionKey(_account, _collateralToken, _indexToken, _isLong, 0);
        VaultMSData.Position storage position = positions[key];
        vaultUtils.validateDecreasePosition(position,_sizeDelta, _collateralDelta);
        _updateGlobalSize(position.isLong, position.indexToken, _sizeDelta, position.averagePrice, false);
        uint256 collateral = position.collateral;
        // scrop variables to avoid stack too deep errors
        {
            uint256 reserveDelta = vaultUtils.getReserveDelta(position.collateralToken, position.size.sub(_sizeDelta), position.collateral.sub(_collateralDelta), position.takeProfitRatio);
            // uint256 reserveDelta = position.reserveAmount.mul(_sizeDelta).div(position.size);
            _decreaseReservedAmount(position.collateralToken, position.reserveAmount);
            if (reserveDelta > 0) _increaseReservedAmount(position.collateralToken, reserveDelta);
            position.reserveAmount = reserveDelta;//position.reserveAmount.sub(reserveDelta);
        }
        updateRate(position.collateralToken);
        if (position.indexToken!= position.collateralToken) updateRate(position.indexToken); 
        
        uint256 price = position.isLong ? getMinPrice(position.indexToken) : getMaxPrice(position.indexToken);

        // _collectMarginFees runs inside _reduceCollateral
        (uint256 usdOut, uint256 usdOutAfterFee) = _reduceCollateral(key, _collateralDelta, _sizeDelta, price);
        
    
        // update position entry rate
        position.lastUpdateTime = block.timestamp;  //attention: MUST run after _collectMarginFees (_reduceCollateral)
        position.entryFundingRateSec = tradingFee[position.collateralToken].accumulativefundingRateSec;
        position.entryPremiumRateSec = position.isLong ? tradingFee[position.indexToken].accumulativeLongRateSec : tradingFee[position.indexToken].accumulativeShortRateSec;
        bool _del = false;
        // scrop variables to avoid stack too deep errors
        {
            //do not add spread price impact in decrease position
            emit DecreasePosition( key, position, _collateralDelta, _sizeDelta, price, int256(usdOut) - int256(usdOutAfterFee), usdOut, position.collateral, collateral);
            if (position.size != _sizeDelta) {
                // position.entryFundingRateSec = tradingFee[_collateralToken].accumulativefundingRateSec;
                position.size = position.size.sub(_sizeDelta);
                _validatePosition(position.size, position.collateral);
                vaultUtils.validateLiquidation(key,true);
                emit UpdatePosition(key, position.account, position.size, position.collateral, position.averagePrice, position.entryFundingRateSec,
                    position.reserveAmount, position.realisedPnl, price);
            } else {
                emit ClosePosition(key, position.account,
                    position.size, position.collateral,position.averagePrice, position.entryFundingRateSec.mul(3600).div(1000000), position.reserveAmount, position.realisedPnl);
                position.size = 0;
                _del = true;
            }
        }
        // update global trading size and average prie
        // _updateGlobalSize(position.isLong, position.indexToken, position.size, position.averagePrice, true);

        updateRate(position.collateralToken);
        if (position.indexToken!= position.collateralToken) updateRate(position.indexToken);

        if (usdOutAfterFee > 0) {
            uint256 tkOutAfterFee = 0;
            tkOutAfterFee = usdToTokenMin(position.collateralToken, usdOutAfterFee);
            emit DecreasePositionTransOut(key, tkOutAfterFee);
            _transferOut(position.collateralToken, tkOutAfterFee, _receiver);
            usdOutAfterFee = tkOutAfterFee;
        }
        if (_del) _delPosition(position.account, key);
        return usdOutAfterFee;
    }



    function liquidatePosition(address _account, address _collateralToken, address _indexToken, bool _isLong, address _feeReceiver) external override nonReentrant {
        vaultUtils.validLiq(msg.sender);
        // updateRate(_collateralToken);
        // if (_indexToken!= _collateralToken) updateRate(_indexToken);
        bytes32 key = vaultUtils.getPositionKey(_account, _collateralToken, _indexToken, _isLong, 0);

        VaultMSData.Position memory position = positions[key];
        _validate(position.size > 0, 35);

        (uint256 liquidationState, uint256 marginFees, int256 idxFee) = vaultUtils.validateLiquidation(key, false);
        _validate(liquidationState != 0, 36);
        if (liquidationState > 1) {
            // max leverage exceeded or max takingProfitLine reached
            _decreasePosition(key, 0, position.size, position.account);
            return;
        }

        {
            uint256 liqMarginFee = position.collateral;
            if (idxFee >= 0){
                liqMarginFee = liqMarginFee.add(uint256(idxFee));
            }else{
                liqMarginFee = liqMarginFee > uint256(-idxFee) ? liqMarginFee.sub(uint256(-idxFee)) : 0;
            }
            
            liqMarginFee = liqMarginFee > marginFees ? marginFees : 0;
            _collectFeeResv(_account, _collateralToken, liqMarginFee, usdToTokenMin(_collateralToken, liqMarginFee));
        }

        uint256 markPrice = _isLong ? getMinPrice(_indexToken)  : getMaxPrice(_indexToken);
        emit LiquidatePosition(key, _account,_collateralToken,_indexToken,_isLong,
            position.size, position.collateral, position.reserveAmount, position.realisedPnl, markPrice);

        // if (!_isLong && marginFees < position.collateral) {
        // if ( marginFees < position.collateral) {
        //     uint256 remainingCollateral = position.collateral.sub(marginFees);
        //     remainingCollateral = usdToTokenMin(_collateralToken, remainingCollateral);
        //     _increasePoolAmount(_collateralToken,  remainingCollateral);
        // }

        _decreaseReservedAmount(_collateralToken, position.reserveAmount);
        _updateGlobalSize(_isLong, _indexToken, position.size, position.averagePrice, false);
        _decreaseGuaranteedUsd(_collateralToken, position.collateral);
        _decreasePoolAmount(_collateralToken, usdToTokenMin(_collateralToken, vaultUtils.liquidationFeeUsd()));
        _transferOut(_collateralToken, usdToTokenMin(_collateralToken, vaultUtils.liquidationFeeUsd()), _feeReceiver);

        _delPosition(_account, key);

        updateRate(_collateralToken);
        if (_indexToken!= _collateralToken) updateRate(_indexToken);
        
    }
    
    //---------- PUBLIC FUNCTIONS ----------
    // deposit into the pool without minting USDX tokens
    // useful in allowing the pool to become over-collaterised
    function directPoolDeposit(address _token) external override nonReentrant {
        _validate(fundingTokens.contains(_token), 14);
        uint256 tokenAmount = _transferIn(_token);
        _validate(tokenAmount > 0, 15);
        _increasePoolAmount(_token, tokenAmount);
        emit DirectPoolDeposit(_token, tokenAmount);
    }
    function tradingTokenList() external view override returns (address[] memory) {
        return tradingTokens.valuesAt(0, tradingTokens.length());
    }
    function fundingTokenList() external view override returns (address[] memory) {
        return fundingTokens.valuesAt(0, fundingTokens.length());
    }
    function claimableFeeReserves() external view override returns (uint256) {
        return feeReservesUSD.sub(feeReservesDiscountedUSD).sub(feeClaimedUSD);
    }
    function getMaxPrice(address _token) public view override returns (uint256) {
        return IVaultPriceFeedV2(priceFeed).getPrice(_token, true, false, false);
    }
    function getMinPrice(address _token) public view override returns (uint256) {
        return IVaultPriceFeedV2(priceFeed).getPrice(_token, false, false, false);
    }
    function getRedemptionAmount(address _token, uint256 _usdxAmount) public view override returns (uint256) {
        uint256 price = getMaxPrice(_token);
        uint256 redemptionAmount = _usdxAmount.mul(VaultMSData.PRICE_PRECISION).div(price);
        return adjustForDecimals(redemptionAmount, usdx, _token);
    }
    function getRedemptionCollateral(address _token) public view returns (uint256) {
        if (tokenBase[_token].isStable) {
            return tokenBase[_token].poolAmount;
        }
        uint256 collateral = usdToTokenMin(_token, guaranteedUsd[_token]);
        return collateral.add(tokenBase[_token].poolAmount).sub(tokenBase[_token].reservedAmount);
    }
    function getRedemptionCollateralUsd(address _token) public view returns (uint256) {
        return tokenToUsdMin(_token, getRedemptionCollateral(_token));
    }
    function adjustForDecimals(uint256 _amount, address _tokenDiv, address _tokenMul ) public view returns (uint256) {
        require(tokenBase[_tokenMul].decimal > 0 && tokenBase[_tokenDiv].decimal > 0, "invalid decimal");
        return _amount.mul(10**tokenBase[_tokenMul].decimal).div(10**tokenBase[_tokenDiv].decimal);
    }
    function tokenToUsdMin(address _token, uint256 _tokenAmount) public view override returns (uint256) {
        // if (_tokenAmount == 0)  return 0;
        uint256 price = getMinPrice(_token);
        uint256 decimals = tokenBase[_token].decimal;
        require(decimals > 0, "invalid decimal");
        return _tokenAmount.mul(price).div(10**decimals);
    }
    function usdToTokenMax(address _token, uint256 _usdAmount) public override view returns (uint256) {
        return _usdAmount > 0 ? usdToToken(_token, _usdAmount, getMinPrice(_token)) : 0;
    }
    function usdToTokenMin(address _token, uint256 _usdAmount) public override view returns (uint256) {
        return _usdAmount > 0 ? usdToToken(_token, _usdAmount, getMaxPrice(_token)) : 0;
    }
    function usdToToken( address _token, uint256 _usdAmount, uint256 _price ) public view returns (uint256) {
        // if (_usdAmount == 0)  return 0;
        uint256 decimals = tokenBase[_token].decimal;
        require(decimals > 0, "invalid decimal");
        return _usdAmount.mul(10**decimals).div(_price);
    }
    function tokenDecimals(address _token) public override view returns (uint256){
        return tokenBase[_token].decimal;
    }
    function getPositionStructByKey(bytes32 _key) public override view returns (VaultMSData.Position memory){
        return positions[_key];
    }
    function getPositionStruct(address _account, address _collateralToken, address _indexToken, bool _isLong) public override view returns (VaultMSData.Position memory){
        return positions[vaultUtils.getPositionKey(_account, _collateralToken, _indexToken, _isLong, 0)];
    }
    function getTokenBase(address _token) public override view returns (VaultMSData.TokenBase memory){
        return tokenBase[_token];
    }
    function getTradingRec(address _token) public override view returns (VaultMSData.TradingRec memory){
        return tradingRec[_token];
    }
    function isFundingToken(address _token) public view override returns(bool){
        return fundingTokens.contains(_token);
    }
    function isTradingToken(address _token) public view override returns(bool){
        return tradingTokens.contains(_token);
    }
    function getTradingFee(address _token) public override view returns (VaultMSData.TradingFee memory){
        return tradingFee[_token];
    }
    function getUserKeys(address _account, uint256 _start, uint256 _end) external override view returns (bytes32[] memory){
        return vaultStorage.getUserKeys(_account, _start, _end);
    }
    function getKeys(uint256 _start, uint256 _end) external override view returns (bytes32[] memory){
        return vaultStorage.getKeys(_start, _end);
    }
    //---------- END OF PUBLIC VIEWS ----------




    //---------------------------------------- PRIVATE Functions --------------------------------------------------
    function updateRate(address _token) public override {
        _validate(tradingTokens.contains(_token) || fundingTokens.contains(_token), 7);
        tradingFee[_token] = vaultUtils.updateRate(_token);
    }

    function _swap(address _tokenIn,  address _tokenOut, address _receiver ) private returns (uint256) {
        _validate(fundingTokens.contains(_tokenIn), 24);
        _validate(fundingTokens.contains(_tokenOut), 25);
        _validate(_tokenIn != _tokenOut, 26);
        updateRate(_tokenIn);
        updateRate(_tokenOut);
        uint256 amountIn = _transferIn(_tokenIn);
        _validate(amountIn > 0, 27);
        uint256 priceIn = getMinPrice(_tokenIn);
        uint256 priceOut = getMaxPrice(_tokenOut);
        uint256 amountOut = amountIn.mul(priceIn).div(priceOut);
        amountOut = adjustForDecimals(amountOut, _tokenIn, _tokenOut);
        // adjust usdxAmounts by the same usdxAmount as debt is shifted between the assets
        uint256 usdxAmount = amountIn.mul(priceIn).div(VaultMSData.PRICE_PRECISION);
        usdxAmount = adjustForDecimals(usdxAmount, _tokenIn, usdx);
        uint256 feeBasisPoints = vaultUtils.getSwapFeeBasisPoints(_tokenIn, _tokenOut, usdxAmount);
        uint256 amountOutAfterFees = _collectSwapFees(_tokenOut, amountOut, feeBasisPoints);
        _increaseUsdxAmount(_tokenIn, usdxAmount);
        _decreaseUsdxAmount(_tokenOut, usdxAmount);
        _increasePoolAmount(_tokenIn, amountIn);
        _decreasePoolAmount(_tokenOut, amountOut);
        _validateBufferAmount(_tokenOut);
        _transferOut(_tokenOut, amountOutAfterFees, _receiver);
        updateRate(_tokenIn);
        updateRate(_tokenOut);
        emit Swap( _receiver, _tokenIn, _tokenOut, amountIn, amountOut, amountOutAfterFees, feeBasisPoints);
        return amountOutAfterFees;
    }


    function _reduceCollateral(bytes32 _key, uint256 _collateralDelta, uint256 _sizeDelta, uint256 _price) private returns (uint256, uint256) {
        VaultMSData.Position storage position = positions[_key];

        int256 fee = _collectMarginFees(_key, _sizeDelta);//collateral size updated in _collectMarginFees
        
        // scope variables to avoid stack too deep errors
        bool hasProfit;
        uint256 adjustedDelta;
        {
            (bool _hasProfit, uint256 delta) = vaultUtils.getDelta(position.indexToken, position.size, position.averagePrice, position.isLong, position.aveIncreaseTime, position.collateral);
            hasProfit = _hasProfit;
            adjustedDelta = _sizeDelta.mul(delta).div(position.size);// get the proportional change in pnl
        }

        //update Profit
        uint256 profitUsdOut = 0;
        // transfer profits out
        if (hasProfit && adjustedDelta > 0) {
            profitUsdOut = adjustedDelta;
            position.realisedPnl = position.realisedPnl + int256(adjustedDelta);
            
            uint256 usdTax = vaultUtils.calculateTax(profitUsdOut, position.aveIncreaseTime);
            // pay out realised profits from the pool amount for short positions
            emit PayTax(position.account, _key, profitUsdOut, usdTax);
            profitUsdOut = profitUsdOut.sub(usdTax); 

            uint256 tokenAmount = usdToTokenMin(position.collateralToken, profitUsdOut);
            _decreasePoolAmount(position.collateralToken, tokenAmount);
            // _decreaseGuaranteedUsd(position.collateralToken, profitUsdOut);
        }
        else if (!hasProfit && adjustedDelta > 0) {
            position.collateral = position.collateral.sub(adjustedDelta);
            // uint256 tokenAmount = usdToTokenMin(position.collateralToken, adjustedDelta);
            // _increasePoolAmount(position.collateralToken, tokenAmount);
            _decreaseGuaranteedUsd(position.collateralToken, adjustedDelta);//decreaseGU = taking position profit by pool
            position.realisedPnl = position.realisedPnl - int256(adjustedDelta);
        }

        uint256 usdOutAfterFee = profitUsdOut;
        // reduce the position's collateral by _collateralDelta
        // transfer _collateralDelta out
        if (_collateralDelta > 0) {
            usdOutAfterFee = usdOutAfterFee.add(_collateralDelta);
            _validate(position.collateral >= _collateralDelta, 33);
            position.collateral = position.collateral.sub(_collateralDelta);
            _decreasePoolAmount(position.collateralToken, usdToTokenMin(position.collateralToken, _collateralDelta));
            _decreaseGuaranteedUsd(position.collateralToken, profitUsdOut); 
        }

        // if the position will be closed, then transfer the remaining collateral out
        if (position.size == _sizeDelta) {
            usdOutAfterFee = usdOutAfterFee.add(position.collateral);
            _decreasePoolAmount(position.collateralToken, usdToTokenMin(position.collateralToken, position.collateral));
            _decreaseGuaranteedUsd(position.collateralToken, position.collateral); 
            position.collateral = 0;
        }

        uint256 usdOut = fee > 0 ? usdOutAfterFee.add(uint256(fee)) :  usdOutAfterFee.sub(uint256(-fee));
        emit UpdatePnl(_key, hasProfit, adjustedDelta, position.size, position.collateral, usdOut, usdOutAfterFee);
        return (usdOut, usdOutAfterFee);
    }

    function _validatePosition(uint256 _size, uint256 _collateral) private view {
        if (_size == 0) {
            _validate(_collateral == 0, 39);
            return;
        }
        _validate(_size >= _collateral, 40);
    }
    
    function _collectSwapFees(address _token, uint256 _amount, uint256 _feeBasisPoints) private returns (uint256) {
        uint256 afterFeeAmount = _amount
            .mul(VaultMSData.COM_RATE_PRECISION.sub(_feeBasisPoints))
            .div(VaultMSData.COM_RATE_PRECISION);
        uint256 feeAmount = _amount.sub(afterFeeAmount);
        feeReserves[_token] = feeReserves[_token].add(feeAmount);
        uint256 _feeUSD = tokenToUsdMin(_token, feeAmount);
        feeReservesUSD = feeReservesUSD.add(_feeUSD);
        uint256 _tIndex = block.timestamp.div(24 hours);
        feeReservesRecord[_tIndex] = feeReservesRecord[_tIndex].add(_feeUSD);
        emit CollectSwapFees(_token, _feeUSD, feeAmount);
        return afterFeeAmount;
    }

    // function _collectMarginFees(address _account, address _collateralToken, address _indexToken,bool _isLong, uint256 _sizeDelta, uint256 _size, uint256 _entryFundingRate 
    function _collectMarginFees(bytes32 _key, uint256 _sizeDelta) private returns (int256) {
        VaultMSData.Position storage _position = positions[_key];
        int256 _premiumFee = vaultUtils.getPremiumFee(_position, tradingFee[_position.indexToken]);
        _position.accPremiumFee += _premiumFee;
        if (_premiumFee > 0){
            // uint256 tokenAmount = usdToTokenMin(_position.collateralToken, uint256(_premiumFee));
            // _increasePoolAmount(_position.collateralToken, tokenAmount);
            //for poolAmount: decrease & increase
            _validate(_position.collateral >= uint256(_premiumFee), 29);
            _decreaseGuaranteedUsd(_position.collateralToken, uint256(_premiumFee));
            _position.collateral = _position.collateral.sub(uint256(_premiumFee));
        }else if (_premiumFee <0){
            // uint256 tokenAmount = usdToTokenMin(_position.collateralToken, uint256(-_premiumFee));
            // _decreasePoolAmount(_position.collateralToken, tokenAmount);
            _increaseGuaranteedUsd(_position.collateralToken, uint256(-_premiumFee));
            _position.collateral = _position.collateral.add(uint256(-_premiumFee));
        }

        emit CollectPremiumFee(_position.account, _position.size, _position.entryPremiumRateSec, _premiumFee);

        uint256 feeUsd = vaultUtils.getPositionFee(_position, _sizeDelta,tradingFee[_position.indexToken]);
        _position.accPositionFee = _position.accPositionFee.add(feeUsd);
        uint256 fuFee = vaultUtils.getFundingFee(_position, tradingFee[_position.collateralToken]);
        _position.accFundingFee = _position.accFundingFee.add(fuFee);
        feeUsd = feeUsd.add(fuFee);
        uint256 feeTokens = usdToTokenMin(_position.collateralToken, feeUsd);
        _validate(_position.collateral >= feeUsd, 29);
        _decreaseGuaranteedUsd(_position.collateralToken, feeUsd);
        _position.collateral = _position.collateral.sub(feeUsd);
        _decreasePoolAmount(_position.collateralToken, feeTokens);

        _collectFeeResv(_position.account, _position.collateralToken, feeUsd, feeTokens);

        emit CollectMarginFees(_position.collateralToken, feeUsd, feeTokens);


        return _premiumFee + int256(feeUsd);
    }

    function _collectFeeResv(address _account, address _collateralToken, uint256 _marginFees, uint256 _feeTokens) private{
        feeReserves[_collateralToken] = feeReserves[_collateralToken].add(_feeTokens);
        feeReservesUSD = feeReservesUSD.add(_marginFees);
        uint256 _discFee = eSBT.updateFee(_account, _marginFees);
        feeReservesDiscountedUSD = feeReservesDiscountedUSD.add(_discFee);
        uint256 _tIndex = block.timestamp.div(24 hours);
        feeReservesRecord[_tIndex] = feeReservesRecord[_tIndex].add(_marginFees.sub(_discFee));
        emit CollectMarginFees(_collateralToken, _marginFees, _feeTokens);
    }


    function _transferIn(address _token) private returns (uint256) {
        uint256 prevBalance = tokenBase[_token].balance;
        uint256 nextBalance = IERC20(_token).balanceOf(address(this));
        tokenBase[_token].balance = nextBalance;
        return nextBalance.sub(prevBalance);
    }

    function _transferOut( address _token, uint256 _amount, address _receiver ) private {
        IERC20(_token).safeTransfer(_receiver, _amount);
        tokenBase[_token].balance = IERC20(_token).balanceOf(address(this));
    }

    function _increasePoolAmount(address _token, uint256 _amount) private {
        tokenBase[_token].poolAmount = tokenBase[_token].poolAmount.add(_amount);
        uint256 balance = IERC20(_token).balanceOf(address(this));
        _validate(tokenBase[_token].poolAmount <= balance, 49);
        emit IncreasePoolAmount(_token, _amount);
    }

    function _decreasePoolAmount(address _token, uint256 _amount) private {
        tokenBase[_token].poolAmount = tokenBase[_token].poolAmount.sub(_amount, "PoolAmount exceeded");
        _validate(tokenBase[_token].reservedAmount <= tokenBase[_token].poolAmount, 50);
        emit DecreasePoolAmount(_token, _amount);
    }

    function _validateBufferAmount(address _token) private view {
        require(tokenBase[_token].poolAmount >= tokenBase[_token].bufferAmount, "pool less than buffer");
    }

    function _increaseUsdxAmount(address _token, uint256 _amount) private {
        // _validate(fundingTokens.contains(_token), 6);
        usdxAmounts[_token] = usdxAmounts[_token].add(_amount);
        uint256 maxUsdxAmount = tokenBase[_token].maxUSDAmounts;
        if (maxUsdxAmount != 0) {
            _validate(usdxAmounts[_token] <= maxUsdxAmount, 51);
        }
    }

    function _decreaseUsdxAmount(address _token, uint256 _amount) private {
        _validate(fundingTokens.contains(_token), 4);
        uint256 value = usdxAmounts[_token];
        if (value <= _amount) {
            usdxAmounts[_token] = 0;
            return;
        }
        usdxAmounts[_token] = value.sub(_amount);
    }

    function _increaseReservedAmount(address _token, uint256 _amount) private {
        _validate(_amount > 0, 53);
        tokenBase[_token].reservedAmount = tokenBase[_token].reservedAmount.add(_amount);
        _validate(tokenBase[_token].reservedAmount <= tokenBase[_token].poolAmount, 52);
        emit IncreaseReservedAmount(_token, _amount);
    }

    function _decreaseReservedAmount(address _token, uint256 _amount) private {
        tokenBase[_token].reservedAmount = tokenBase[_token].reservedAmount.sub( _amount, "Vault: insufficient reserve" );
        emit DecreaseReservedAmount(_token, _amount);
    }

    function _validate(bool _condition, uint256 _errorCode) private view {
        require(_condition, vaultUtils.errors(_errorCode));
    }

    function _updateGlobalSize(bool _isLong, address _indexToken, uint256 _sizeDelta, uint256 _price, bool _increase) private {
        VaultMSData.TradingRec storage ttREC = tradingRec[_indexToken];
        if (_isLong) {
            ttREC.longAveragePrice = vaultUtils.getNextAveragePrice(ttREC.longSize,  ttREC.longAveragePrice, _price, _sizeDelta, _increase);
            if (_increase){
                ttREC.longSize = ttREC.longSize.add(_sizeDelta);
                globalLongSize = globalLongSize.add(_sizeDelta);
            }else{
                ttREC.longSize = ttREC.longSize.sub(_sizeDelta);
                globalLongSize = globalLongSize.sub(_sizeDelta);
            }
            // emit UpdateGlobalSize(_indexToken, ttREC.longSize, globalLongSize,ttREC.longAveragePrice, _increase, _isLong );
        } else {
            ttREC.shortAveragePrice = vaultUtils.getNextAveragePrice(ttREC.shortSize,  ttREC.shortAveragePrice, _price, _sizeDelta, _increase);  
            if (_increase){
                ttREC.shortSize = ttREC.shortSize.add(_sizeDelta);
                globalShortSize = globalShortSize.add(_sizeDelta);
            }else{
                ttREC.shortSize = ttREC.shortSize.sub(_sizeDelta);
                globalShortSize = globalShortSize.sub(_sizeDelta);    
            }
            // emit UpdateGlobalSize(_indexToken, ttREC.shortSize, globalShortSize,ttREC.shortAveragePrice, _increase, _isLong );
        }
    }

    function _delPosition(address _account, bytes32 _key) private {
        delete positions[_key];
        vaultStorage.delKey(_account, _key);
    }

    function _increaseGuaranteedUsd(address _token, uint256 _usdAmount) private {
        guaranteedUsd[_token] = guaranteedUsd[_token].add(_usdAmount);
        emit IncreaseGuaranteedUsd(_token, _usdAmount);
    }

    function _decreaseGuaranteedUsd(address _token, uint256 _usdAmount)  private {
        guaranteedUsd[_token] = guaranteedUsd[_token] > _usdAmount ?guaranteedUsd[_token].sub(_usdAmount) : 0;
        emit DecreaseGuaranteedUsd(_token, _usdAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library EnumerableValues {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    function valuesAt(EnumerableSet.Bytes32Set storage set, uint256 start, uint256 end) internal view returns (bytes32[] memory) {
        uint256 max = set.length();
        if (end > max) { end = max; }

        bytes32[] memory items = new bytes32[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }


    function valuesAt(EnumerableSet.AddressSet storage set, uint256 start, uint256 end) internal view returns (address[] memory) {
        uint256 max = set.length();
        if (end > max) { end = max; }

        address[] memory items = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }


    function valuesAt(EnumerableSet.UintSet storage set, uint256 start, uint256 end) internal view returns (uint256[] memory) {
        uint256 max = set.length();
        if (end > max) { end = max; }

        uint256[] memory items = new uint256[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../utils/EnumerableValues.sol";

library VaultMSData {
    // bytes32 public constant opeProtectIdx = keccak256("opeProtectIdx");
    // using EnumerableSet for EnumerableSet.UintSet;
    // using EnumerableValues for EnumerableSet.UintSet;

    uint256 constant COM_RATE_PRECISION = 10**4; //for common rate(leverage, etc.) and hourly rate
    uint256 constant HOUR_RATE_PRECISION = 10**6; //for common rate(leverage, etc.) and hourly rate
    uint256 constant PRC_RATE_PRECISION = 10**10;   //for precise rate  secondly rate
    uint256 constant PRICE_PRECISION = 10**30;

    struct Position {
        address account;
        address collateralToken;
        address indexToken;
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 reserveAmount;
        uint256 lastUpdateTime;
        uint256 aveIncreaseTime;


        uint256 entryFundingRateSec;
        int256 entryPremiumRateSec;

        int256 realisedPnl;

        uint256 stopLossRatio;
        uint256 takeProfitRatio;

        bool isLong;

        int256 accPremiumFee;
        uint256 accFundingFee;
        uint256 accPositionFee;
        uint256 accCollateral;
    }


    struct TokenBase {
        //Setable parts
        bool isFundable;
        bool isStable;
        uint256 decimal;
        uint256 weight;  //tokenWeights allows customisation of index composition
        uint256 maxUSDAmounts;  // maxUSDAmounts allows setting a max amount of USDX debt for a token

        //Record only
        uint256 balance;        // tokenBalances is used only to determine _transferIn values
        uint256 poolAmount;     // poolAmounts tracks the number of received tokens that can be used for leverage
                                // this is tracked separately from tokenBalances to exclude funds that are deposited as margin collateral
        uint256 reservedAmount; // reservedAmounts tracks the number of tokens reserved for open leverage positions
        uint256 bufferAmount;   // bufferAmounts allows specification of an amount to exclude from swaps
                                // this can be used to ensure a certain amount of liquidity is available for leverage positions
    }


    struct TradingFee {
        uint256 fundingRatePerSec; //borrow fee & token util

        uint256 accumulativefundingRateSec;

        int256 longRatePerSec;  //according to position
        int256 shortRatePerSec; //according to position
        int256 accumulativeLongRateSec;
        int256 accumulativeShortRateSec;

        uint256 latestUpdateTime;
        // uint256 lastFundingTimes;     // lastFundingTimes tracks the last time funding was updated for a token
        // uint256 cumulativeFundingRates;// cumulativeFundingRates tracks the funding rates based on utilization
        // uint256 cumulativeLongFundingRates;
        // uint256 cumulativeShortFundingRates;
    }

    struct TradingTax {
        uint256 taxMax;
        uint256 taxDuration;
        uint256 k;
    }

    struct TradingLimit {
        uint256 maxShortSize;
        uint256 maxLongSize;
        uint256 maxTradingSize;

        uint256 maxRatio;
        uint256 countMinSize;
        //Price Impact
    }


    struct TradingRec {
        uint256 shortSize;
        uint256 shortCollateral;
        uint256 shortAveragePrice;
        uint256 longSize;
        uint256 longCollateral;
        uint256 longAveragePrice;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../DID/interfaces/IESBT.sol";
import "../VaultMSData.sol";

interface IVault {
    function isSwapEnabled() external view returns (bool);
    
    function priceFeed() external view returns (address);
    function usdx() external view returns (address);
    function totalTokenWeights() external view returns (uint256);
    function usdxSupply() external view returns (uint256);
    function usdxAmounts(address _token) external view returns (uint256);
    function guaranteedUsd(address _token) external view returns (uint256);
    function baseMode() external view returns (uint8);

    function approvedRouters(address _router) external view returns (bool);
    function isManager(address _account) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);
    function feeSold (address _token)  external view returns (uint256);
    function feeReservesUSD() external view returns (uint256);
    function feeReservesDiscountedUSD() external view returns (uint256);
    function feeReservesRecord(uint256 _day) external view returns (uint256);
    function feeClaimedUSD() external view returns (uint256);
    // function keyOwner(bytes32 _key) external view returns (address);
    // function shortSizes(address _token) external view returns (uint256);
    // function shortCollateral(address _token) external view returns (uint256);
    // function shortAveragePrices(address _token) external view returns (uint256);
    // function longSizes(address _token) external view returns (uint256);
    // function longCollateral(address _token) external view returns (uint256);
    // function longAveragePrices(address _token) external view returns (uint256);
    function globalShortSize( ) external view returns (uint256);
    function globalLongSize( ) external view returns (uint256);


    //---------------------------------------- owner FUNCTIONS --------------------------------------------------
    function setESBT(address _eSBT) external;
    function setVaultStorage(address _vaultStorage) external;
    function setVaultUtils(address _vaultUtils) external;
    function setManager(address _manager, bool _isManager) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function setPriceFeed(address _priceFeed) external;
    function setRouter(address _router, bool _status) external;
    function setUsdxAmount(address _token, uint256 _amount, bool _increase) external;
    function setTokenConfig(address _token, uint256 _tokenDecimals, uint256 _tokenWeight, uint256 _maxUSDAmount,
        bool _isStable,  bool _isFundingToken, bool _isTradingToken ) external;
    function clearTokenConfig(address _token) external;
    function updateRate(address _token) external;

    //-------------------------------------------------- FUNCTIONS FOR MANAGER --------------------------------------------------
    function buyUSDX(address _token, address _receiver) external returns (uint256);
    function sellUSDX(address _token, address _receiver, uint256 _usdxAmount) external returns (uint256);
    function claimFeeToken(address _token) external returns (uint256);
    function claimFeeReserves( ) external returns (uint256) ;


    //---------------------------------------- TRADING FUNCTIONS --------------------------------------------------
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function liquidatePosition(address _account, address _collateralToken, address _indexToken, bool _isLong, address _feeReceiver) external;


    //-------------------------------------------------- PUBLIC FUNCTIONS --------------------------------------------------
    function directPoolDeposit(address _token) external;
    function tradingTokenList() external view returns (address[] memory);
    function fundingTokenList() external view returns (address[] memory);
    function claimableFeeReserves( )  external view returns (uint256);
    // function whitelistedTokenCount() external view returns (uint256);
    //fee functions
    // function tokenBalances(address _token) external view returns (uint256);
    // function lastFundingTimes(address _token) external view returns (uint256);
    // function setInManagerMode(bool _inManagerMode) external;
    // function setBufferAmount(address _token, uint256 _amount) external;
    // function setMaxGlobalShortSize(address _token, uint256 _amount) external;
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _usdxAmount) external view returns (uint256);
    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);
    function usdToTokenMax(address _token, uint256 _usdAmount) external view returns (uint256);
    function usdToTokenMin(address _token, uint256 _usdAmount) external view returns (uint256);
    // function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256, uint256, uint256, int256, uint256, uint256, bool, uint256);
    // function getPositionByKey(bytes32 _key) external view returns (uint256, uint256, uint256, int256, uint256, uint256, bool, uint256);
    // function getNextFundingRate(address _token) external view returns (uint256);
    function isFundingToken(address _token) external view returns(bool);
    function isTradingToken(address _token) external view returns(bool);
    function tokenDecimals(address _token) external view returns (uint256);
    function getPositionStructByKey(bytes32 _key) external view returns (VaultMSData.Position memory);
    function getPositionStruct(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (VaultMSData.Position memory);
    function getTokenBase(address _token) external view returns (VaultMSData.TokenBase memory);
    function getTradingFee(address _token) external view returns (VaultMSData.TradingFee memory);
    function getTradingRec(address _token) external view returns (VaultMSData.TradingRec memory);
    function getUserKeys(address _account, uint256 _start, uint256 _end) external view returns (bytes32[] memory);
    function getKeys(uint256 _start, uint256 _end) external view returns (bytes32[] memory);

    // function fundingRateFactor() external view returns (uint256);
    // function stableFundingRateFactor() external view returns (uint256);
    // function cumulativeFundingRates(address _token) external view returns (uint256);
    // // function getFeeBasisPoints(address _token, uint256 _usdxDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);


    // function allWhitelistedTokensLength() external view returns (uint256);
    // function allWhitelistedTokens(uint256) external view returns (address);
    // function whitelistedTokens(address _token) external view returns (bool);
    // function stableTokens(address _token) external view returns (bool);
    // function shortableTokens(address _token) external view returns (bool);
    
    // function globalShortSizes(address _token) external view returns (uint256);
    // function globalShortAveragePrices(address _token) external view returns (uint256);
    // function maxGlobalShortSizes(address _token) external view returns (uint256);
    // function tokenDecimals(address _token) external view returns (uint256);
    // function tokenWeights(address _token) external view returns (uint256);
    // function guaranteedUsd(address _token) external view returns (uint256);
    // function poolAmounts(address _token) external view returns (uint256);
    // function bufferAmounts(address _token) external view returns (uint256);
    // function reservedAmounts(address _token) external view returns (uint256);
    // function maxUSDAmounts(address _token) external view returns (uint256);



}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../VaultMSData.sol";

interface IVaultUtils {

    // function validateTokens(uint256 _baseMode, address _collateralToken, address _indexToken, bool _isLong) external view returns (bool);
    function isLiquidator(address _account) external view returns (bool);
    
    function setLiquidator(address _liquidator, bool _isActive) external;

    function validateRatioDelta(bytes32 _key, uint256 _lossRatio, uint256 _profitRatio) external view returns (bool);   

    function validateIncreasePosition(address _collateralToken, address _indexToken, uint256 _size, uint256 _sizeDelta, bool _isLong) external view;
    function validateDecreasePosition(VaultMSData.Position memory _position, uint256 _sizeDelta, uint256 _collateralDelta) external view;
    // function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function validateLiquidation(bytes32 _key, bool _raise) external view returns (uint256, uint256, int256);
    function getImpactedPrice(address _token, uint256 _sizeDelta, uint256 _price, bool _isLong) external view returns (uint256);

    function getReserveDelta(address _collateralToken, uint256 _sizeUSD, uint256 _colUSD, uint256 _takeProfitRatio) external view returns (uint256);
    function getInitialPosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong, uint256 _price) external view returns (VaultMSData.Position memory);
    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime, uint256 _colSize) external view returns (bool, uint256);
    function updateRate(address _token) external view returns (VaultMSData.TradingFee memory);
    function getPremiumFee(VaultMSData.Position memory _position, VaultMSData.TradingFee memory _tradingFee) external view returns (int256);
    // function getPremiumFee(address _indexToken, bool _isLong, uint256 _size, int256 _entryPremiumRate) external view returns (int256);
    function getLiqPrice(bytes32 _posKey) external view returns (int256);
    function getPositionFee(VaultMSData.Position memory _position, uint256 _sizeDelta, VaultMSData.TradingFee memory _tradingFee) external view returns (uint256);
    function getFundingFee(VaultMSData.Position memory _position, VaultMSData.TradingFee memory _tradingFee) external view returns (uint256);
    function getBuyUsdxFeeBasisPoints(address _token, uint256 _usdxAmount) external view returns (uint256);
    function getSellUsdxFeeBasisPoints(address _token, uint256 _usdxAmount) external view returns (uint256);
    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _usdxAmount) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdxDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
    function getPositionKey(address _account,address _collateralToken, address _indexToken, bool _isLong, uint256 _keyID) external view returns (bytes32);

    function getLatestFundingRatePerSec(address _token) external view returns (uint256);
    function getLatestLSRate(address _token) external view returns (int256, int256);

    // function addPosition(bytes32 _key,address _account, address _collateralToken, address _indexToken, bool _isLong) external;
    // function removePosition(bytes32 _key) external;
    // function getDiscountedFee(address _account, uint256 _origFee, address _token) external view returns (uint256);
    // function getSwapDiscountedFee(address _user, uint256 _origFee, address _token) external view returns (uint256);
    // function uploadFeeRecord(address _user, uint256 _feeOrig, uint256 _feeDiscounted, address _token) external;

    function MAX_FEE_BASIS_POINTS() external view returns (uint256);
    function MAX_LIQUIDATION_FEE_USD() external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function swapFeeBasisPoints() external view returns (uint256);
    function stableSwapFeeBasisPoints() external view returns (uint256);
    function marginFeeBasisPoints() external view returns (uint256);

    function hasDynamicFees() external view returns (bool);
    function maxLeverage() external view returns (uint256);
    function setMaxLeverage(uint256 _maxLeverage) external;

    function errors(uint256) external view returns (string memory);

    function spreadBasis(address) external view returns (uint256);
    function maxSpreadBasis(address) external view returns (uint256);
    function minSpreadCalUSD(address) external view returns (uint256);
    function premiumBasisPointsPerHour() external view returns (uint256);
    function negIndexMaxPointsPerHour() external view returns (int256);
    function posIndexMaxPointsPerHour() external view returns (int256);

    function maxGlobalShortSizes(address) external view returns (uint256);
    function maxGlobalLongSizes(address) external view returns (uint256);

    // function getNextAveragePrice(bytes32 _key, address _indexToken, uint256 _size, uint256 _averagePrice,
        // bool _isLong, uint256 _nextPrice, uint256 _sizeDelta, uint256 _lastIncreasedTime ) external view returns (uint256);
    // function getNextAveragePrice(bytes32 _key, bool _isLong, uint256 _price,uint256 _sizeDelta) external view returns (uint256);           
    function getNextIncreaseTime(uint256 _prev, uint256 _prev_size,uint256 _sizeDelta) external view returns (uint256);          
    // function getPositionDelta(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (bool, uint256);
    function calculateTax(uint256 _profit, uint256 _aveIncreaseTime) external view returns(uint256);    
    function getPositionNextAveragePrice(uint256 _size, uint256 _averagePrice, uint256 _nextPrice, uint256 _sizeDelta, bool _isIncrease) external pure returns (uint256);

    function getNextAveragePrice(uint256 _size, uint256 _averagePrice,  uint256 _nextPrice, uint256 _sizeDelta, bool _isIncrease) external pure returns (uint256);
    // function getDecreaseNextAveragePrice(uint256 _size, uint256 _averagePrice,  uint256 _nextPrice, uint256 _sizeDelta ) external pure returns (uint256);
    // function getPositionNextAveragePrice(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _nextPrice, uint256 _sizeDelta, uint256 _lastIncreasedTime) external pure returns (uint256);
    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;
    
    function getTradingTax(address _token) external view returns (VaultMSData.TradingTax memory);
    function getTradingLimit(address _token) external view returns (VaultMSData.TradingLimit memory);
    function tokenUtilization(address _token) external view returns (uint256);
    function getTargetUsdxAmount(address _token) external view returns (uint256);
    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;
    function inPrivateLiquidationMode() external view returns (bool);
    function validLiq(address _account) external view;
    function setOnlyRouterSwap(bool _onlyRS) external;
    function onlyRouterSwap() external view returns (bool);


    function fundingRateFactor() external view returns (uint256);
    function stableFundingRateFactor() external view returns (uint256);
    function maxProfitRatio() external view returns (uint256);

    function taxDuration() external view returns (uint256);
    function taxMax() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVaultPriceFeedV2 {
    function adjustmentBasisPoints(address _token) external view returns (uint256);
    function isAdjustmentAdditive(address _token) external view returns (bool);
    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external;
    function setUseV2Pricing(bool _useV2Pricing) external;
    function setIsAmmEnabled(bool _isEnabled) external;
    function setIsSecondaryPriceEnabled(bool _isEnabled) external;
    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;
    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external;
    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;
    function setPriceSampleSpace(uint256 _priceSampleSpace) external;
    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external;
    function getPrice(address _token, bool _maximise,bool,bool) external view returns (uint256);
    function getOrigPrice(address _token) external view returns (uint256);
    
    function getLatestPrimaryPrice(address _token) external view returns (uint256);
    function getPrimaryPrice(address _token, bool _maximise) external view returns (uint256, bool);
    function setTokenChainlink( address _token, address _chainlinkContract) external;
    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external;

    function priceVariancePer1Million(address _token) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../VaultMSData.sol";

interface IVaultStorage {
   
    // ---------- owner setting part ----------
    function setVault(address _vault) external;
    function delKey(address _account, bytes32 _key) external;
    function addKey(address _account, bytes32 _key) external;
    function userKeysLength(address _account) external view returns (uint256);
    function getUserKeys(address _account, uint256 _start, uint256 _end) external view returns (bytes32[] memory);
    function getKeys(uint256 _start, uint256 _end) external view returns (bytes32[] memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IESBT {
    // function updateIncreaseLogForAccount(address _account, address _collateralToken, 
            // uint256 _collateralSize,uint256 _positionSize, bool /*_isLong*/ ) external returns (bool);

    function scorePara(uint256 _paraId) external view returns (uint256);
    function createTime(address _account) external view returns (uint256);
    // function tradingKey(address _account, bytes32 key) external view returns (bytes32);
    function nickName(address _account) external view returns (string memory);


    function getReferralForAccount(address _account) external view returns (address[] memory , address[] memory);
    function userSizeSum(address _account) external view returns (uint256);
    // function updateFeeDiscount(address _account, uint256 _discount, uint256 _rebate) external;
    function updateFee(address _account, uint256 _origFee) external returns (uint256);
    // function calFeeDiscount(address _account, uint256 _amount) external view returns (uint256);

    function getESBTAddMpUintetRoles(address _mpaddress, bytes32 _key) external view returns (uint256[] memory);
    function updateClaimVal(address _account) external ;
    function userClaimable(address _account) external view returns (uint256, uint256);

    // function updateScoreForAccount(address _account, uint256 _USDamount, uint16 _opeType) external;
    function updateScoreForAccount(address _account, address /*_vault*/, uint256 _amount, uint256 _reasonCode) external;
    function updateTradingScoreForAccount(address _account, address _vault, uint256 _amount, uint256 _refCode) external;
    function updateSwapScoreForAccount(address _account, address _vault, uint256 _amount) external;
    function updateAddLiqScoreForAccount(address _account, address _vault, uint256 _amount, uint256 _refCode) external;
    // function updateStakeEDEScoreForAccount(address _account, uint256 _amount) external ;
    function getScore(address _account) external view returns (uint256);
    function getRefCode(address _account) external view returns (string memory);
    function accountToDisReb(address _account) external view returns (uint256, uint256);
    function rank(address _account) external view returns (uint256);
    function addressToTokenID(address _account) external view returns (uint256);
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