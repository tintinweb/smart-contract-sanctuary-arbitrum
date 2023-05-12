// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../utils/EnumerableValues.sol";
import "./VaultMSData.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IVaultUtils.sol";
import "./interfaces/IVaultPriceFeedV3Fast.sol";


contract VaultUtils is IVaultUtils, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableValues for EnumerableSet.Bytes32Set;
    bool public override inPrivateLiquidationMode = false;
    bool public override onlyRouterSwap = true;

    mapping(address => bool) public override isLiquidator;
    bool public override hasDynamicFees = true; //not used

    //Fees related to swap
    uint256 public override taxBasisPoints = 0; // 0.5%
    uint256 public override stableTaxBasisPoints = 0; // 0.2%
    uint256 public override mintBurnFeeBasisPoints = 0; // 0.3%
    uint256 public override swapFeeBasisPoints = 0; // 0.3%
    uint256 public override stableSwapFeeBasisPoints = 0; // 0.04%
    uint256 public override marginFeeBasisPoints = 10; // 0.1%
    uint256 public constant MAX_FEE_BASIS_POINTS = 500; // 5%   50000
    uint256 public constant MAX_LIQUIDATION_FEE_USD = 100 * VaultMSData.PRICE_PRECISION; // 100 USD
    uint256 public override liquidationFeeUsd = 5 * VaultMSData.PRICE_PRECISION;
    uint256 public override maxLeverage = 100 * VaultMSData.COM_RATE_PRECISION; // 100x

    //Fees related to funding
    uint256 public override fundingRateFactor;
    uint256 public override stableFundingRateFactor;

    //trading limit part
    mapping(address => uint256) public override maxGlobalShortSizes;
    mapping(address => uint256) public override maxGlobalLongSizes;
    mapping(address => VaultMSData.TradingLimit) tradingLimit;
  
    //trading tax part
    uint256 public override taxDuration;
    uint256 public override taxMax;
    mapping(address => VaultMSData.TradingTax) tradingTax; 


    //trading profit limitation part
    uint256 public override maxProfitRatio = 20 * VaultMSData.COM_RATE_PRECISION;

    IVault public vault;
    mapping(uint256 => string) public override errors;

    mapping(address => uint256) public override spreadBasis;
    mapping(address => uint256) public override maxSpreadBasis;// COM_PRECISION
    mapping(address => uint256) public override minSpreadCalUSD;// = 10000 * PRICE_PRECISION;

    uint256 public override premiumBasisPointsPerHour;
    uint256 public override premiumBasisPointsPerSec;
    uint256 public override maxPremiumBasisErrorUSD;

    int256 public override posIndexMaxPointsPerHour;
    int256 public override posIndexMaxPointsPerSec;
    int256 public override negIndexMaxPointsPerHour;
    int256 public override negIndexMaxPointsPerSec;

    modifier onlyVault() {
        require(msg.sender == address(vault), "onlyVault");
        _;
    }

    constructor(IVault _vault) {
        vault = _vault;
    }

    function setMaxProfitRatio(uint256 _setRatio) external onlyOwner{
        require(_setRatio > VaultMSData.COM_RATE_PRECISION, "ratio small");
        maxProfitRatio = _setRatio;
    }

    function setSpreadBasis(address _token, uint256 _spreadBasis, uint256 _maxSpreadBasis, uint256 _minSpreadCalUSD) external onlyOwner{
        require(_spreadBasis <= 10 * VaultMSData.COM_RATE_PRECISION, "ERROR38");
        require(_maxSpreadBasis <= MAX_FEE_BASIS_POINTS, "ERROR38");
        spreadBasis[_token] = _spreadBasis;
        maxSpreadBasis[_token] = _maxSpreadBasis;
        minSpreadCalUSD[_token] = _minSpreadCalUSD;
    }

    function setMaxGlobalSize(address _token, uint256 _amountLong, uint256 _amountShort) external onlyOwner{
        maxGlobalLongSizes[_token] = _amountLong;
        maxGlobalShortSizes[_token] = _amountShort;
    }

    function setTradingLimit(address _token, uint256 _maxShortSize, uint256 _maxLongSize, uint256 _maxSize, uint256 _maxRatio, uint256 _countMinSize) external onlyOwner{
        VaultMSData.TradingLimit storage tLim = tradingLimit[_token];
        // require(_maxRatio > VaultMSData.COM_RATE_PRECISION, "ratio small");
        tLim.maxTradingSize = _maxSize;
        tLim.maxShortSize = _maxShortSize;
        tLim.maxLongSize = _maxLongSize;
        tLim.countMinSize = _countMinSize;
        tLim.maxRatio = _maxRatio;
    }

    function setOnlyRouterSwap(bool _onlyRS) external override onlyOwner {
        onlyRouterSwap = _onlyRS;
    }
    function setLiquidator(address _liquidator, bool _isActive) external override onlyOwner {
        isLiquidator[_liquidator] = _isActive;
    }

    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external override onlyOwner {
        inPrivateLiquidationMode = _inPrivateLiquidationMode;
    }

    function setPremiumRate(uint256 _premiumBasisPoints, int256 _posIndexMaxPoints, int256 _negIndexMaxPoints, uint256 _maxPremiumBasisErrorUSD) external onlyOwner{
        require(negIndexMaxPointsPerSec <= 0, "_negIndexMaxPoints be negative");
        require(_posIndexMaxPoints >= 0, "_posIndexMaxPoints be positive");
        _validate(_premiumBasisPoints <= VaultMSData.COM_RATE_PRECISION, 12);
        premiumBasisPointsPerHour = _premiumBasisPoints;
        premiumBasisPointsPerSec = hRateToSecRate(premiumBasisPointsPerHour);

        negIndexMaxPointsPerHour = _negIndexMaxPoints;
        negIndexMaxPointsPerSec = hRateToSecRateInt(negIndexMaxPointsPerHour);

        posIndexMaxPointsPerHour = _posIndexMaxPoints;
        posIndexMaxPointsPerSec = hRateToSecRateInt(posIndexMaxPointsPerHour);

        maxPremiumBasisErrorUSD = _maxPremiumBasisErrorUSD;
        // vault.updateRate(address(0));
    }

    // function copySetting(address _prevUtils) external onlyOwner {
    //     IVaultUtils pVUtils = IVaultUtils(_prevUtils);

    //     taxBasisPoints = pVUtils.taxBasisPoints(); // 100x
    //     stableTaxBasisPoints = pVUtils.stableTaxBasisPoints(); // 100x
    //     mintBurnFeeBasisPoints = pVUtils.mintBurnFeeBasisPoints(); // 100x
    //     swapFeeBasisPoints = pVUtils.swapFeeBasisPoints(); // 100x
    //     stableSwapFeeBasisPoints = pVUtils.stableSwapFeeBasisPoints(); // 100x
    //     marginFeeBasisPoints = pVUtils.marginFeeBasisPoints(); // 100x
    //     liquidationFeeUsd = pVUtils.liquidationFeeUsd(); // 100x
    //     maxLeverage = pVUtils.maxLeverage(); // 100x
    //     //Fees related to funding
    //     fundingRateFactor = pVUtils.fundingRateFactor();
    //     stableFundingRateFactor = pVUtils.stableFundingRateFactor();


    //     address[] memory traTokenList = vault.tradingTokenList();
    //     address[] memory funTokenList = vault.tradingTokenList();
    //     for (uint i = 0; i < traTokenList.length; i++){
    //         address _token = traTokenList[i];
    //         maxGlobalShortSizes[_token] = pVUtils.maxGlobalShortSizes(_token);
    //         maxGlobalLongSizes[_token] = pVUtils.maxGlobalLongSizes(_token);
    //         spreadBasis[_token] = pVUtils.spreadBasis(_token);
    //         maxSpreadBasis[_token] = pVUtils.maxSpreadBasis(_token);
    //         minSpreadCalUSD[_token] = pVUtils.minSpreadCalUSD(_token);
    //         tradingLimit[_token] = pVUtils.getTradingLimit(_token);
    //         tradingTax[_token] = pVUtils.getTradingTax(_token);
    //     }
    //     for (uint i = 0; i < funTokenList.length; i++){
    //         address _token = funTokenList[i];
    //         maxGlobalShortSizes[_token] = pVUtils.maxGlobalShortSizes(_token);
    //         maxGlobalLongSizes[_token] = pVUtils.maxGlobalLongSizes(_token);
    //         spreadBasis[_token] = pVUtils.spreadBasis(_token);
    //         maxSpreadBasis[_token] = pVUtils.maxSpreadBasis(_token);
    //         minSpreadCalUSD[_token] = pVUtils.minSpreadCalUSD(_token);
    //         tradingLimit[_token] = pVUtils.getTradingLimit(_token);
    //         tradingTax[_token] = pVUtils.getTradingTax(_token);
    //     }
    //     //trading profit limitation part
    //     maxProfitRatio = pVUtils.maxProfitRatio();
    //     taxDuration = pVUtils.taxDuration();
    //     taxMax = pVUtils.taxMax();

    //     premiumBasisPointsPerHour = pVUtils.premiumBasisPointsPerHour();
    //     premiumBasisPointsPerSec = pVUtils.premiumBasisPointsPerSec();
    //     maxPremiumBasisErrorUSD = pVUtils.maxPremiumBasisErrorUSD();

    //     posIndexMaxPointsPerHour = pVUtils.posIndexMaxPointsPerHour();
    //     posIndexMaxPointsPerSec = pVUtils.posIndexMaxPointsPerSec();
    //     negIndexMaxPointsPerHour = pVUtils.negIndexMaxPointsPerHour();
    //     negIndexMaxPointsPerSec = pVUtils.negIndexMaxPointsPerSec();
    // }

    function setFundingRate(
        uint256 _fundingRateFactor,
        uint256 _stableFundingRateFactor
    ) external onlyOwner{
        _validate(_fundingRateFactor <= VaultMSData.COM_RATE_PRECISION, 11);
        _validate(_stableFundingRateFactor <= VaultMSData.COM_RATE_PRECISION, 12);
        fundingRateFactor = _fundingRateFactor;
        stableFundingRateFactor = _stableFundingRateFactor;
        // vault.updateRate(address(0));
    }

    function setMaxLeverage(uint256 _maxLeverage) public override onlyOwner{
        require(_maxLeverage > VaultMSData.COM_RATE_PRECISION, "ERROR2");
        require(_maxLeverage < 220 * VaultMSData.COM_RATE_PRECISION, "Max leverage reached");
        maxLeverage = _maxLeverage;
    }

    function setTaxRate(uint256 _taxMax, uint256 _taxTime) external onlyOwner{
        require(_taxMax <= VaultMSData.PRC_RATE_PRECISION, "TAX MAX reached");
        if (_taxTime > 0){
            taxMax = _taxMax;
            taxDuration = _taxTime;
        }else{
            taxMax = 0;
            taxDuration = 0;
        }
    }

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 ,
        bool _hasDynamicFees
    ) external override onlyOwner {
        require(_taxBasisPoints <= MAX_FEE_BASIS_POINTS, "3");
        require(_stableTaxBasisPoints <= MAX_FEE_BASIS_POINTS, "ERROR4");
        require(_mintBurnFeeBasisPoints <= MAX_FEE_BASIS_POINTS, "ERROR5");
        require(_swapFeeBasisPoints <= MAX_FEE_BASIS_POINTS, "ERROR6");
        require(_stableSwapFeeBasisPoints <= MAX_FEE_BASIS_POINTS, "ERROR7");
        require(_marginFeeBasisPoints <= MAX_FEE_BASIS_POINTS, "ERROR8");
        require(_liquidationFeeUsd <= MAX_LIQUIDATION_FEE_USD, "ERROR9");
        taxBasisPoints = _taxBasisPoints;
        stableTaxBasisPoints = _stableTaxBasisPoints;
        mintBurnFeeBasisPoints = _mintBurnFeeBasisPoints;
        swapFeeBasisPoints = _swapFeeBasisPoints;
        stableSwapFeeBasisPoints = _stableSwapFeeBasisPoints;
        marginFeeBasisPoints = _marginFeeBasisPoints;
        liquidationFeeUsd = _liquidationFeeUsd;
        hasDynamicFees = _hasDynamicFees;
    }

    function getLatestFundingRatePerSec(address _token) public view override returns (uint256){
        VaultMSData.TokenBase memory tB = vault.getTokenBase(_token);
        if (tB.poolAmount == 0) return 0;
        // tradingFee.fundingRatePerHour
        uint256 _fundingUtil = tB.reservedAmount.mul(VaultMSData.PRC_RATE_PRECISION).div(tB.poolAmount);
        return hRateToSecRate(fundingRateFactor.mul(_fundingUtil)).div(VaultMSData.PRC_RATE_PRECISION);
    }

    function hRateToSecRate(uint256 _comRate) public pure  returns (uint256){
        return _comRate.mul(VaultMSData.PRC_RATE_PRECISION).div(VaultMSData.HOUR_RATE_PRECISION).div(3600);
    }
    function hRateToSecRateInt(int256 _comRate) public pure  returns (int256){
        return _comRate * int256(VaultMSData.PRC_RATE_PRECISION) / int256(VaultMSData.HOUR_RATE_PRECISION.mul(3600));
    }

    function getLatestLSRate(address _token) public view override returns (int256, int256){
        VaultMSData.TradingRec memory _traRec = vault.getTradingRec(_token);
        if (premiumBasisPointsPerSec == 0 || maxPremiumBasisErrorUSD == 0) return (0,0);
        // uint256 _maxSize = _traRec.longSize > _traRec.shortSize ? _traRec.longSize : _traRec.shortSize ;
        int256 _longRate = 0;//int256(premiumBasisPointsPerSec);
        int256 _shortRate = 0;// int256(premiumBasisPointsPerSec);
        uint256 totalSize = _traRec.shortSize.add(_traRec.longSize);
        if (totalSize == 0) return (0,0);
        
        uint256 errorSize = _traRec.shortSize > _traRec.longSize ? _traRec.shortSize.sub(_traRec.longSize) : _traRec.longSize.sub(_traRec.shortSize);
        errorSize = errorSize > maxPremiumBasisErrorUSD ? maxPremiumBasisErrorUSD : errorSize;
        int256 largeSizeRate = int256(errorSize.mul(premiumBasisPointsPerSec).div(maxPremiumBasisErrorUSD));
        if (_traRec.longSize > _traRec.shortSize){
            _longRate = largeSizeRate;
            _shortRate = _traRec.shortSize > 0 ? - largeSizeRate * int256(_traRec.longSize) / int256(_traRec.shortSize) : -int256(premiumBasisPointsPerSec);
            _shortRate = _shortRate < negIndexMaxPointsPerSec ? negIndexMaxPointsPerSec : _shortRate;
        }else{//short is larger
            _shortRate = largeSizeRate;
            _longRate = _traRec.longSize > 0 ? - largeSizeRate * int256(_traRec.shortSize) / int256(_traRec.longSize) : -int256(premiumBasisPointsPerSec);
            _longRate = _longRate < negIndexMaxPointsPerSec ? negIndexMaxPointsPerSec : _longRate;
        }
        // if (_longRate > 0 && posIndexMaxPointsPerSec > 0)
        //     _longRate = _longRate > posIndexMaxPointsPerSec ? posIndexMaxPointsPerSec : _longRate;
        // else if ((_longRate < 0 && negIndexMaxPointsPerSec < 0))
        //     _longRate = _longRate < negIndexMaxPointsPerSec ? negIndexMaxPointsPerSec : _longRate;

        // if (_shortRate > 0 && posIndexMaxPointsPerSec > 0)
        //     _shortRate = _shortRate > posIndexMaxPointsPerSec ? posIndexMaxPointsPerSec : _shortRate;
        // else if ((_shortRate < 0 && negIndexMaxPointsPerSec < 0))
        //     _shortRate = _shortRate < negIndexMaxPointsPerSec ? negIndexMaxPointsPerSec : _shortRate;
        return (_longRate, _shortRate);
    }

    function updateRate(address _token) public view override returns (VaultMSData.TradingFee memory) {
        VaultMSData.TradingFee memory _tradingFee = vault.getTradingFee(_token);
       
        uint256 timepastSec =_tradingFee.latestUpdateTime > 0 ? block.timestamp.sub(_tradingFee.latestUpdateTime) : 0;
        _tradingFee.latestUpdateTime = block.timestamp;

        if (timepastSec > 0){
            // accumulative funding rate
            _tradingFee.accumulativefundingRateSec = _tradingFee.accumulativefundingRateSec.add(_tradingFee.fundingRatePerSec.mul(timepastSec));
            //update accumulative lohg/short rate
            _tradingFee.accumulativeLongRateSec += _tradingFee.longRatePerSec * int256(timepastSec);
            _tradingFee.accumulativeShortRateSec += _tradingFee.shortRatePerSec * int256(timepastSec);  
        }
 
        //update funding rate
        _tradingFee.fundingRatePerSec = getLatestFundingRatePerSec(_token);
        (_tradingFee.longRatePerSec, _tradingFee.shortRatePerSec) = getLatestLSRate(_token);
        return _tradingFee;
    }

    function getNextIncreaseTime(uint256 _prev_time, uint256 _prev_size,uint256 _sizeDelta) public view override returns (uint256){
        return _prev_time.mul(_prev_size).add(_sizeDelta.mul(block.timestamp)).div(_sizeDelta.add(_prev_size));
    }         
    
    function validateIncreasePosition(address  _collateralToken, address _indexToken, uint256 _size, uint256 _sizeDelta, bool _isLong) external override view {
        _validate(_size.add(_sizeDelta) > 0, 7);
        //validate tokens.
        require(vault.isFundingToken(_collateralToken), "not funding token");
        require(vault.isTradingToken(_indexToken), "not trading token");
        uint256 baseMode = vault.baseMode();
        require(baseMode > 0 && baseMode < 3, "invalid vault mode");

        VaultMSData.TradingRec memory _tRec = vault.getTradingRec(_indexToken);
        VaultMSData.TokenBase memory tbCol = vault.getTokenBase(_collateralToken);
        VaultMSData.TokenBase memory tbIdx = vault.getTokenBase(_indexToken);
        VaultMSData.TradingLimit storage tLimit = tradingLimit[_indexToken];
        

        //validate trading size
        {
            uint256 _latestLong  = _isLong ? _tRec.longSize.add(_sizeDelta) : _tRec.longSize;
            uint256 _latestShort = _isLong ? _tRec.shortSize : _tRec.shortSize.add(_sizeDelta) ;
            uint256 _sumSize = _latestLong.add(_latestShort);
            if (tLimit.maxLongSize > 0) require(_latestLong < tLimit.maxLongSize, "max token long size reached");
            if (tLimit.maxShortSize > 0) require(_latestShort < tLimit.maxShortSize, "max token short size reached");
            if (tLimit.maxTradingSize > 0) require(_sumSize < tLimit.maxTradingSize, "max trading size reached");
            if (tLimit.countMinSize > 0 && tLimit.maxRatio > 0 && _sumSize > tLimit.countMinSize){
                require( (_latestLong > _latestShort ? _latestLong : _latestShort).mul(VaultMSData.COM_RATE_PRECISION).div(_sumSize) < tLimit.maxRatio, "max long/short ratio reached");
            }
        }


        //validate collateral token based on base mode
        _validate(!tbIdx.isStable, 47);
        if (baseMode == 1){
            if (_isLong) 
                _validate(_collateralToken == _indexToken, 46);
            else 
                _validate(tbCol.isStable, 46);
        }
        else if  (baseMode == 2){
            _validate(tbCol.isStable, 46);
        }
        else{
            _validate(_collateralToken == _indexToken, 42);  
        }

    }

    function validateDecreasePosition(VaultMSData.Position memory _position, uint256 _sizeDelta, uint256 _collateralDelta) external override view {
        // no additional validations
        _validate(_position.size > 0, 31);
        _validate(_position.size >= _sizeDelta, 32);
        _validate(_position.collateral >= _collateralDelta, 33);

        require( vault.isFundingToken(_position.collateralToken), "not funding token");
        require( vault.isTradingToken(_position.indexToken), "not trading token");

    }

    function validateRatioDelta(bytes32 /*_key*/, uint256 _lossRatio, uint256 _profitRatio) public view override returns (bool){
        //step.1 valid size
        //step.2 valid range
        //step.3 valid prev liquidation
        //step.4 valid new liquidation
        require(_profitRatio <= maxProfitRatio, "max taking profit ratio reached");
        require(_lossRatio <= VaultMSData.COM_RATE_PRECISION, "max loss ratio reached");
        return true;
    }
    

    function getReserveDelta(address _collateralToken, uint256 _sizeUSD, uint256 /*_colUSD*/, uint256 /*_takeProfitRatio*/) public view override returns (uint256){
        // uint256 reserveDelta = usdToTokenMax(_collateralToken, _sizeDelta);
        // uint256 reserveDelta = 
        if (vault.baseMode() == 1){
            return vault.usdToTokenMax(_collateralToken, _sizeUSD);
        }
        else if (vault.baseMode() == 2){
            // require(maxProfitRatio > 0 && _takeProfitRatio <= maxProfitRatio, "invalid max profit");
            // uint256 resvUSD = _colUSD.mul(_takeProfitRatio > 0 ? _takeProfitRatio : maxProfitRatio).div(VaultMSData.COM_RATE_PRECISION);         
            return vault.usdToTokenMax(_collateralToken, _sizeUSD);
        }
        else{
            revert("invalid baseMode");
        }
        // return 0;
    }

    function getPositionKey(address _account,address _collateralToken, address _indexToken, bool _isLong, uint256 _keyID) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _collateralToken, _indexToken, _isLong, _keyID) );
    }
    
    function getPositionInfo(address _account, address _collateralToken, address _indexToken, bool _isLong) public view returns (uint256[] memory, int256[] memory ){
        VaultMSData.Position memory _pos = vault.getPositionStruct(_account, _collateralToken, _indexToken, _isLong);
        uint256[] memory _uInfo = new uint256[](9);
        int256[] memory _iInfo = new int256[](2);
        _uInfo[0] = _pos.size;
        _uInfo[1] = _pos.collateral;
        _uInfo[2] = _pos.averagePrice;
        _uInfo[3] = _pos.reserveAmount;
        _uInfo[4] = _pos.lastUpdateTime;
        _uInfo[5] = _pos.aveIncreaseTime;
        _uInfo[6] = _pos.stopLossRatio;
        _uInfo[7] = _pos.takeProfitRatio;
        _uInfo[8] = _pos.entryFundingRateSec;

        _iInfo[0] = _pos.realisedPnl;
        _iInfo[1] = _pos.entryPremiumRateSec;
        return (_uInfo, _iInfo);
    }

    function getLiqPrice(bytes32 _key) public view override returns (int256){
        VaultMSData.Position memory position = vault.getPositionStructByKey(_key);
        if (position.size < 1) return 0;
        
        VaultMSData.TradingFee memory colTF = vault.getTradingFee(position.collateralToken);
        VaultMSData.TradingFee memory idxTF = vault.getTradingFee(position.indexToken);

        uint256 marginFees = getFundingFee(position, colTF).add(getPositionFee(position, 0, idxTF));
        int256 _premiumFee = getPremiumFee(position, idxTF);
    
        uint256 colRemain = position.collateral.sub(marginFees);
        colRemain = _premiumFee >= 0 ?position.collateral.sub(uint256(_premiumFee)) : position.collateral.add(uint256(-_premiumFee)) ;
        // (bool hasProfit, uint256 delta) = getDelta(position.indexToken, position.size, position.averagePrice, position.isLong, position.lastUpdateTime, position.collateral);
        // colRemain = hasProfit ? position.collateral.sub(delta) : position.collateral.add(delta);

        uint256 acceptPriceGap = colRemain.mul(position.averagePrice).div(position.size);
        return position.isLong ? int256(position.averagePrice) - int256(acceptPriceGap) : int256(position.averagePrice.add(acceptPriceGap));
    }

    function getPositionsInfo( uint256 _start, uint256 _end) public view returns ( bytes32[]memory, uint256[]memory,bool[] memory){
        bytes32[] memory allKeys = vault.getKeys(_start, _end);

        uint256[] memory liqPrices = new uint256[](allKeys.length);
        bool[] memory isLongs = new bool[](allKeys.length);
        // for(uint256 i = 0; i < allKeys.length; i++){
        //     liqPrices[i] = getLiqPrice(allKeys[i]);
        //     isLongs[i] = positionsOrig[allKeys[i]].isLong;
        // }
        return (allKeys, liqPrices, isLongs);
    }

    function getNextAveragePrice(uint256 _size, uint256 _averagePrice,  uint256 _nextPrice, uint256 _sizeDelta, bool _isIncrease) public pure override returns (uint256) {
        if (_size == 0) return _nextPrice;
        if (_isIncrease){
            uint256 nextSize = _size.add(_sizeDelta) ;
            return nextSize > 0 ? (_averagePrice.mul(_size)).add(_sizeDelta.mul(_nextPrice)).div(nextSize) : 0;   
        }
        else{
            uint256 _latestSize = _size > _sizeDelta ? _size.sub(_sizeDelta) : 0;
            return _latestSize > 0 ? (_averagePrice.mul(_size).sub(_sizeDelta.mul(_nextPrice))).div(_latestSize): 0;
        }
    }

    function getInitialPosition(address _account, address _collateralToken, address _indexToken, uint256 , bool _isLong, uint256 _price) public override view returns (VaultMSData.Position memory){
        VaultMSData.Position memory position;
        position.account = _account;
        position.averagePrice = _price;
        position.aveIncreaseTime = block.timestamp;
        position.collateralToken = _collateralToken;
        position.indexToken = _indexToken;
        position.isLong = _isLong;
        return position;
    }

    function getPositionNextAveragePrice(uint256 _size, uint256 _averagePrice, uint256 _nextPrice, uint256 _sizeDelta, bool _isIncrease) public override pure returns (uint256) {
        if (_isIncrease)
            return (_size.mul(_averagePrice)).add(_sizeDelta.mul(_nextPrice)).div(_size.add(_sizeDelta));
        else{
            require(_size >= _sizeDelta, "invalid size delta");
            return (_size.mul(_averagePrice)).sub(_sizeDelta.mul(_nextPrice)).div(_size.sub(_sizeDelta));
        }
    }

    function calculateTax(uint256 _profit, uint256 _aveIncreaseTime) public view override returns(uint256){     
        if (taxMax == 0)
            return 0;
        uint256 _positionDuration = block.timestamp.sub(_aveIncreaseTime);
        if (_positionDuration >= taxDuration)
            return 0;
        
        uint256 taxPercent = (taxDuration.sub(_positionDuration)).mul(taxMax).div(taxDuration);
        // taxPercent = taxPercent > taxMax ? taxMax : taxPercent;
        taxPercent = taxPercent > VaultMSData.PRC_RATE_PRECISION ? VaultMSData.PRC_RATE_PRECISION : taxPercent;
        return _profit.mul(taxPercent).div(VaultMSData.PRC_RATE_PRECISION);
    }

    function validateLiquidation(bytes32 _key, bool _raise) public view override returns (uint256, uint256, int256){
        VaultMSData.Position memory position = vault.getPositionStructByKey(_key);
        return _validateLiquidation(position, _raise);
    }

    function validateLiquidationPar(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) public view returns (uint256, uint256, int256) {
        VaultMSData.Position memory position = vault.getPositionStructByKey(getPositionKey( _account, _collateralToken, _indexToken, _isLong, 0));
        return _validateLiquidation(position, _raise);
    }
    
    function _validateLiquidation(VaultMSData.Position memory position, bool _raise) public view returns (uint256, uint256, int256) {
        if (position.size == 0) return (0,1,0);

        VaultMSData.TradingFee memory colTF = vault.getTradingFee(position.collateralToken);
        VaultMSData.TradingFee memory idxTF = vault.getTradingFee(position.indexToken);

        (bool hasProfit, uint256 delta) = getDelta(position.indexToken, position.size, position.averagePrice, position.isLong, position.lastUpdateTime, position.collateral);
        uint256 marginFees = getFundingFee(position, colTF).add( getPositionFee(position, 0, idxTF));

        int256 _premiumFee = getPremiumFee(position, idxTF);
    


        if (!hasProfit && position.collateral < delta) {
            if (_raise) { revert("Vault: losses exceed collateral"); }
            return (1, marginFees,_premiumFee);
        }

        uint256 remainingCollateral = position.collateral;
        if (_premiumFee < 0)
            remainingCollateral = remainingCollateral.add(uint256(-_premiumFee));
        else{
            if (remainingCollateral < uint256(_premiumFee)) {
                if (_raise) { revert("Vault: index fees exceed collateral"); }
                // cap the fees to the remainingCollateral
                return (1, remainingCollateral,_premiumFee);
            }
            remainingCollateral = remainingCollateral.sub(uint256(_premiumFee));
        }

        if (remainingCollateral < marginFees) {
            if (_raise) { revert("Vault: fees exceed collateral"); }
            // cap the fees to the remainingCollateral
            return (1, remainingCollateral,_premiumFee);
        }

        if (!hasProfit) {
            remainingCollateral = position.collateral.sub(delta);
        }

        if (remainingCollateral < marginFees) {
            if (_raise) { revert("Vault: fees exceed collateral"); }
            // cap the fees to the remainingCollateral
            return (1, remainingCollateral,_premiumFee);
        }

        if (remainingCollateral < marginFees.add(liquidationFeeUsd)) {
            if (_raise) { revert("Vault: liquidation fees exceed collateral"); }
            return (1, marginFees,_premiumFee);
        }

        if (remainingCollateral.mul(maxLeverage) < position.size.mul(VaultMSData.COM_RATE_PRECISION)) {
            if (_raise) { revert("Vault: maxLeverage exceeded"); }
            return (2, marginFees, _premiumFee);
        }

        if (vault.baseMode() > 1){
            if (hasProfit && maxProfitRatio > 0){
                if (delta >= remainingCollateral.mul(maxProfitRatio).div(VaultMSData.COM_RATE_PRECISION) ){
                    if (_raise) { revert("Vault: max profit exceeded"); }
                    return (3, marginFees,_premiumFee);
                }
            }

            if (hasProfit && position.takeProfitRatio > 0){
                if (delta >= remainingCollateral.mul(position.takeProfitRatio).div(VaultMSData.COM_RATE_PRECISION) ){
                    if (_raise) { revert("Vault: max profit exceeded"); }
                    return (3, marginFees,_premiumFee);
                }
            }
            // 
            if (!hasProfit && position.stopLossRatio > 0){
                if (delta >= remainingCollateral.mul(position.stopLossRatio).div(VaultMSData.COM_RATE_PRECISION) ){
                    if (_raise) { revert("Vault: stop loss ratio reached"); }
                    return (4, marginFees,_premiumFee);
                }
            }
        }

        return (0, marginFees, _premiumFee);
    }
    

    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 /*_lastIncreasedTime*/, uint256 _colSize) public view override returns (bool, uint256) {
        _validate(_averagePrice > 0, 38);
        uint256 price = _isLong ? vault.getMinPrice(_indexToken) : vault.getMaxPrice(_indexToken);
        uint256 priceDelta = _averagePrice > price ? _averagePrice.sub(price) : price.sub(_averagePrice);
        uint256 delta = _size.mul(priceDelta).div(_averagePrice);
        bool hasProfit;
        if (_isLong) {
            hasProfit = price > _averagePrice;
        } else {
            hasProfit = _averagePrice > price;
        }
        
        
        //todo: add max profit here
        if (hasProfit && maxProfitRatio > 0){
            uint256 _maxProfit = _colSize.mul(maxProfitRatio).div(VaultMSData.COM_RATE_PRECISION);
            delta = delta > _maxProfit ? _maxProfit : delta;
        }

        return (hasProfit, delta);
    }


    function getPositionFee(VaultMSData.Position memory /*_position*/, uint256 _sizeDelta, VaultMSData.TradingFee memory /*_tradingFee*/) public override view returns (uint256) {
        if (_sizeDelta == 0) { return 0; }
        // uint256 bFBP = getPositionImpactRatio(_position.indexToken, _sizeDelta);
        uint256 afterFeeUsd = _sizeDelta.mul(VaultMSData.COM_RATE_PRECISION.sub(marginFeeBasisPoints)).div(VaultMSData.COM_RATE_PRECISION);
        return _sizeDelta.sub(afterFeeUsd);
    }

    function getPositionImpactRatio(address _token, uint256 _size, bool /*_isLong*/) public view returns (uint256) {
        uint256 bFBP = 0;
        if (spreadBasis[_token] == 0 || maxSpreadBasis[_token] == 0) return 0;
        if (_size <= minSpreadCalUSD[_token]) return 0;
        uint256 _impact = IVaultPriceFeedV3Fast(vault.priceFeed()).priceVariancePer1Million(_token);
        if (_impact == 0) return 0;
        bFBP = _impact.mul(_size.sub(minSpreadCalUSD[_token])).mul(spreadBasis[_token]).div(VaultMSData.COM_RATE_PRECISION).div(1000000*VaultMSData.PRICE_PRECISION);
        return bFBP > maxSpreadBasis[_token] ? maxSpreadBasis[_token] : bFBP;
    }

    function getImpactedPrice(address _token, uint256 _sizeDelta, uint256 _price, bool _isLong) public override view returns (uint256) {
        uint256 pIR = getPositionImpactRatio(_token, _sizeDelta, _isLong);
        if (pIR == 0) return _price;
        return _isLong ? _price.mul(VaultMSData.COM_RATE_PRECISION.add(pIR)).div(VaultMSData.COM_RATE_PRECISION)
            :  _price.mul(VaultMSData.COM_RATE_PRECISION.sub(pIR)).div(VaultMSData.COM_RATE_PRECISION);
    }


    function getFundingFee(VaultMSData.Position memory _position, VaultMSData.TradingFee memory _tradingFee) public view override returns (uint256) {
        if (_position.size == 0) { return 0; }
        // VaultMSData.TradingFee memory _tradingFee = vault.getTradingFee(_position.collateralToken);

        uint256 latestAccumFundingRate = _tradingFee.accumulativefundingRateSec.add(_tradingFee.fundingRatePerSec.mul(block.timestamp.sub(_tradingFee.latestUpdateTime)));
        uint256 fundingRate = latestAccumFundingRate.sub(_position.entryFundingRateSec);
        if (fundingRate == 0) { return 0; }
        return _position.size.mul(fundingRate).div(VaultMSData.PRC_RATE_PRECISION);
    }

    // function getPremiumFee(address _indexToken, bool _isLong, uint256 _size, int256 _entryPremiumRate) public view override returns (int256) {
    function getPremiumFee(VaultMSData.Position memory _position, VaultMSData.TradingFee memory _tradingFee) public view override returns (int256) {
        if (_position.size == 0 || _position.lastUpdateTime == 0)
            return 0; 
        // VaultMSData.TradingFee memory _tradingFee = vault.getTradingFee(_position.indexToken);
        int256 _accumPremiumRate = _position.isLong ? _tradingFee.accumulativeLongRateSec : _tradingFee.accumulativeShortRateSec;
        int256 _useFeePerSec  = _position.isLong ? _tradingFee.longRatePerSec : _tradingFee.shortRatePerSec;
        _accumPremiumRate += _useFeePerSec * int256((block.timestamp.sub(_tradingFee.latestUpdateTime)));
        _accumPremiumRate -= _position.entryPremiumRateSec;
        return int256(_position.size) * _accumPremiumRate / int256(VaultMSData.PRC_RATE_PRECISION);
    }

    function getBuyUsdxFeeBasisPoints(address _token, uint256 _usdxAmount) public override view returns (uint256) {
        return getFeeBasisPoints(_token, _usdxAmount, mintBurnFeeBasisPoints, taxBasisPoints, true);
    }

    function getSellUsdxFeeBasisPoints(address _token, uint256 _usdxAmount) public override view returns (uint256) {
        return getFeeBasisPoints(_token, _usdxAmount, mintBurnFeeBasisPoints, taxBasisPoints, false);
    }

    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _usdxAmount) public override view returns (uint256) {
        bool isStableSwap = true;//vault.stableTokens(_tokenIn) && vault.stableTokens(_tokenOut);
        uint256 baseBps = isStableSwap ? stableSwapFeeBasisPoints: swapFeeBasisPoints;
        uint256 taxBps = isStableSwap ? stableTaxBasisPoints : taxBasisPoints;
        uint256 feesBasisPoints0 = getFeeBasisPoints(_tokenIn, _usdxAmount, baseBps, taxBps, true);
        uint256 feesBasisPoints1 = getFeeBasisPoints(_tokenOut, _usdxAmount, baseBps, taxBps, false);
        // use the higher of the two fee basis points
        return feesBasisPoints0 > feesBasisPoints1 ? feesBasisPoints0 : feesBasisPoints1;
    }

    // cases to consider
    // 1. initialAmount is far from targetAmount, action increases balance slightly => high rebate
    // 2. initialAmount is far from targetAmount, action increases balance largely => high rebate
    // 3. initialAmount is close to targetAmount, action increases balance slightly => low rebate
    // 4. initialAmount is far from targetAmount, action reduces balance slightly => high tax
    // 5. initialAmount is far from targetAmount, action reduces balance largely => high tax
    // 6. initialAmount is close to targetAmount, action reduces balance largely => low tax
    // 7. initialAmount is above targetAmount, nextAmount is below targetAmount and vice versa
    // 8. a large swap should have similar fees as the same trade split into multiple smaller swaps
    function getFeeBasisPoints(address _token, uint256 _usdxDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) public override view returns (uint256) {
        if (!hasDynamicFees) { return _feeBasisPoints; }

        uint256 initialAmount = vault.usdxAmounts(_token);
        uint256 nextAmount = initialAmount.add(_usdxDelta);
        if (!_increment) {
            nextAmount = _usdxDelta > initialAmount ? 0 : initialAmount.sub(_usdxDelta);
        }

        uint256 targetAmount = getTargetUsdxAmount(_token);
        if (targetAmount == 0) { return _feeBasisPoints; }

        uint256 initialDiff = initialAmount > targetAmount ? initialAmount.sub(targetAmount) : targetAmount.sub(initialAmount);
        uint256 nextDiff = nextAmount > targetAmount ? nextAmount.sub(targetAmount) : targetAmount.sub(nextAmount);

        // action improves relative asset balance
        if (nextDiff < initialDiff) {
            uint256 rebateBps = _taxBasisPoints.mul(initialDiff).div(targetAmount);
            return rebateBps > _feeBasisPoints ? 0 : _feeBasisPoints.sub(rebateBps);
        }

        uint256 averageDiff = initialDiff.add(nextDiff).div(2);
        if (averageDiff > targetAmount) {
            averageDiff = targetAmount;
        }
        uint256 taxBps = _taxBasisPoints.mul(averageDiff).div(targetAmount);
        return _feeBasisPoints.add(taxBps);
    }


    function setErrorContenct(uint256[] memory _idxR, string[] memory _errorInstru) external onlyOwner{
        for(uint16 i = 0; i < _errorInstru.length; i++)
            errors[_idxR[i]] = _errorInstru[i];
    }

    function _validate(bool _condition, uint256 _errorCode) private view {
        require(_condition, string.concat(Strings.toString(_errorCode), errors[_errorCode]));
    }


    function getTradingTax(address _token) public override view returns (VaultMSData.TradingTax memory){
        return tradingTax[_token];
    }
    function getTradingLimit(address _token) public override view returns (VaultMSData.TradingLimit memory){
        return tradingLimit[_token];
    }

    function tokenUtilization(address _token) public view  override returns (uint256) {
        VaultMSData.TokenBase memory tokenBase = vault.getTokenBase(_token);
        return tokenBase.poolAmount > 0 ? tokenBase.reservedAmount.mul(1000000).div(tokenBase.poolAmount) : 0;
    }
    function getTargetUsdxAmount(address _token) public view override returns (uint256){
        VaultMSData.TokenBase memory tokenBase = vault.getTokenBase(_token);
        uint256 usdxSupply = vault.usdxSupply();

        uint256 weight = tokenBase.weight;
        return usdxSupply > 0 && vault.totalTokenWeights() > 0 ? weight.mul(usdxSupply).div(vault.totalTokenWeights()) : 0;
    }

    function validLiq(address _account) public view override {
        if (inPrivateLiquidationMode) {
            require(isLiquidator[_account], "not liquidator");
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
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
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
    function premiumBasisPointsPerSec() external view returns (uint256);
    function maxPremiumBasisErrorUSD() external view returns (uint256);

    function negIndexMaxPointsPerHour() external view returns (int256);
    function posIndexMaxPointsPerHour() external view returns (int256);
    function posIndexMaxPointsPerSec() external view returns (int256);
    function negIndexMaxPointsPerSec() external view returns (int256);

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

interface IVaultPriceFeedV3Fast {   
    function getPrimaryPrice(address _token) external view  returns (uint256, bool, uint256);
    function setTokenChainlinkConfig(address _token, address _chainlinkContract, bool) external;

    function adjustmentBasisPoints(address _token) external view returns (uint256);
    function isAdjustmentAdditive(address _token) external view returns (bool);
    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external;
    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;
    function getPrice(address _token, bool _maximise,bool,bool) external view returns (uint256);
    function getOrigPrice(address _token) external view returns (uint256);
    
    
    function priceVariancePer1Million(address _token) external view returns (uint256); //100 for 1%
    function getPriceSpreadImpactFactor(address _token) external view returns (uint256, uint256); 
    
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
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
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
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
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
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
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
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

    function rankToDiscount(uint256 _rank) external view returns (uint256, uint256);
}