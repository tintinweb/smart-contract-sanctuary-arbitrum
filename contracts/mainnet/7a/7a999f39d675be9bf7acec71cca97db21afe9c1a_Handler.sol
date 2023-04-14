// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;
import "./interfaces/IHandler.sol";
import "./interfaces/IDipxStorage.sol";
import "./interfaces/ILpManager.sol";
import "./interfaces/IPositionManager.sol";
import "./token/interfaces/ILP.sol";
import "./token/interfaces/IMixedLP.sol";
import "./token/interfaces/ISingleLP.sol";
import "./referrals/interfaces/IReferral.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Handler is IHandler,Initializable,OwnableUpgradeable{
  using EnumerableSet for EnumerableSet.Bytes32Set;

  uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
  int256 constant OFFSET19700101 = 2440588;

  IDipxStorage public dipxStorage;
  mapping(address => bool) public plugins;
  // pool => (date => volume)
  mapping(address => mapping(uint256 => PoolVolume)) public dailyPoolVolumes;
  // account => keys
  mapping(address => EnumerableSet.Bytes32Set) private userVolumeKeys;
  mapping(bytes32 => PoolVolume) public userDailyVolumes;

  // pool => (date => liquidity)
  mapping(address => mapping(uint256 => PoolLiquidity)) public dailyPoolLiquidity;

  // date => keys
  mapping(uint256 => EnumerableSet.Bytes32Set) private dailyVolumeKeys;

  modifier onlyPlugin(){
    require(plugins[msg.sender], "Handler: caller is not the plugin");
    _;
  }

  function initialize(address _dipxStorage) public initializer {
    __Ownable_init();
    dipxStorage = IDipxStorage(_dipxStorage);
  }

  function getUserVolume(bytes32 key) public override view returns(PoolVolume memory){
    return userDailyVolumes[key];
  }
  function getPoolVolume(address _pool, uint256 _date) public override view returns(PoolVolume memory){
    return dailyPoolVolumes[_pool][_date];
  }

  function getUserVolumeKeyLength(address account) public view returns(uint256){
    return userVolumeKeys[account].length();
  }
  function getUserVolumeKeyAt(address account, uint256 index) public view returns(bytes32){
    return userVolumeKeys[account].at(index);
  }

  function getDailyVolumeKeyLength(uint256 date) public view returns(uint256){
    return dailyVolumeKeys[date].length();
  }
  function getDailyVolumeKeyAt(uint256 date, uint256 index) public view returns(bytes32){
    return dailyVolumeKeys[date].at(index);
  }
  
  function getUserVolumes(address account,uint256 begin,uint256 end) public view returns(PoolVolume[] memory){
    uint256 len = userVolumeKeys[account].length();
    uint256 size;
    for (uint256 i = 0; i < len; i++) {
      bytes32 key = userVolumeKeys[account].at(i);
      if(begin <= userDailyVolumes[key].date && userDailyVolumes[key].date < end){
        size ++;
      }
    }

    uint256 count;
    PoolVolume[] memory volumes = new PoolVolume[](size);
    for (uint256 i = 0; i < len; i++) {
      bytes32 key = userVolumeKeys[account].at(i);
      if(begin <= userDailyVolumes[key].date && userDailyVolumes[key].date < end){
        volumes[count] = userDailyVolumes[key];
        count ++;
      }
    }

    return volumes;
  }

  function getDailyVolumes(address pool, uint256 date) public view returns(PoolVolume[] memory){
    uint256 len = dailyVolumeKeys[date].length();
    uint256 size;
    for (uint256 i = 0; i < len; i++) {
      bytes32 key = dailyVolumeKeys[date].at(i);
      if(userDailyVolumes[key].pool == pool){
        size ++;
      }
    }

    uint256 count;
    PoolVolume[] memory volumes = new PoolVolume[](size);
    for (uint256 i = 0; i < len; i++) {
      bytes32 key = dailyVolumeKeys[date].at(i);
      if(userDailyVolumes[key].pool == pool){
        volumes[count] = userDailyVolumes[key];
        count ++;
      }
    }

    return volumes;
  }

  function setDipxStorage(address _dipxStorage) external onlyOwner{
    dipxStorage = IDipxStorage(_dipxStorage);
  }

  function setPlugins(address[] memory _plugins, bool _enable) external onlyOwner{
    for (uint256 i = 0; i < _plugins.length; i++) {
      plugins[_plugins[i]] = _enable;
    }
  }

  function timestampToDate(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day) {
    unchecked {
      (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
  }
  function timestampToDateNumber(uint256 timestamp) internal pure returns(uint256 date){
    (uint256 year,uint256 month,uint256 day) = timestampToDate(timestamp);
    return year*10000 + month*100 + day;
  }
  function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
    unchecked {
      int256 __days = int256(_days);

      int256 L = __days + 68569 + OFFSET19700101;
      int256 N = (4 * L) / 146097;
      L = L - (146097 * N + 3) / 4;
      int256 _year = (4000 * (L + 1)) / 1461001;
      L = L - (1461 * _year) / 4 + 31;
      int256 _month = (80 * L) / 2447;
      int256 _day = L - (2447 * _month) / 80;
      L = _month / 11;
      _month = _month + 2 - 12 * L;
      _year = 100 * (N - 49) + _year + L;

      year = uint256(_year);
      month = uint256(_month);
      day = uint256(_day);
    }
  }

  function _increaseVolume(
    address account,
    address indexToken, 
    address collateralToken,
    bool isLong,
    uint256 sizeDelta,
    uint256 fee
  ) private {
    IPositionManager.Position memory position = IPositionManager(dipxStorage.positionManager()).getPosition(account,indexToken,collateralToken,isLong);
    uint256 date = timestampToDateNumber(block.timestamp);
    uint256 poolPrice = ILpManager(dipxStorage.lpManager()).getPoolPrice(collateralToken, true, true, true);

    PoolVolume storage volume = dailyPoolVolumes[collateralToken][date];
    volume.pool = collateralToken;
    volume.date = date;
    volume.value = volume.value + sizeDelta;
    volume.fee = volume.fee + fee;
    volume.valueInUsd = volume.valueInUsd + sizeDelta*poolPrice;
    volume.feeInUsd = volume.feeInUsd + fee*poolPrice;

    PoolVolume storage totalVolume = dailyPoolVolumes[collateralToken][0];
    totalVolume.pool = collateralToken;
    totalVolume.date = 0;
    totalVolume.value = totalVolume.value + sizeDelta;
    totalVolume.valueInUsd = totalVolume.valueInUsd + sizeDelta*poolPrice;
    totalVolume.fee = totalVolume.fee + fee;
    totalVolume.feeInUsd = totalVolume.feeInUsd + fee*poolPrice;

    bytes32 key = keccak256(abi.encodePacked(account,date,collateralToken));
    userVolumeKeys[account].add(key);
    PoolVolume storage userVolume = userDailyVolumes[key];
    userVolume.pool = collateralToken;
    userVolume.date = date;
    userVolume.value = userVolume.value + sizeDelta;
    userVolume.valueInUsd = userVolume.valueInUsd + sizeDelta*poolPrice;
    userVolume.fee = userVolume.fee + fee;
    userVolume.feeInUsd = userVolume.feeInUsd + fee*poolPrice;
    if(block.timestamp - position.lastIncreasedTime >= dipxStorage.minProfitTime()){
      userVolume.realValue = userVolume.realValue + sizeDelta;
      userVolume.realValueInUsd = userVolume.realValueInUsd + sizeDelta*poolPrice;
    }

    dailyVolumeKeys[date].add(key);

    bytes32 userGlobalKey = keccak256(abi.encodePacked(account,uint256(0),collateralToken));
    PoolVolume storage userTotalVolume = userDailyVolumes[userGlobalKey];
    userTotalVolume.pool = collateralToken;
    userTotalVolume.date = 0;
    userTotalVolume.value = userTotalVolume.value + sizeDelta;
    userTotalVolume.valueInUsd = userTotalVolume.valueInUsd + sizeDelta*poolPrice;
    userTotalVolume.fee = userTotalVolume.fee + fee;
    userTotalVolume.feeInUsd = userTotalVolume.feeInUsd + fee*poolPrice;
    if(block.timestamp - position.lastIncreasedTime >= dipxStorage.minProfitTime()){
      userTotalVolume.realValue = userTotalVolume.realValue + sizeDelta;
      userTotalVolume.realValueInUsd = userTotalVolume.realValueInUsd + sizeDelta*poolPrice;
    }
  }

  function _updatePoolLiquidity(address pool) private{
    uint256 date = timestampToDateNumber(block.timestamp);
    PoolLiquidity storage pl = dailyPoolLiquidity[pool][date];
    pl.pool = pool;
    pl.date = date;
    pl.totalSupply = IERC20(pool).totalSupply();
    if(ILP(pool).isMixed()){
      pl.aum = IMixedLP(pool).getAum(true);
      pl.price = IMixedLP(pool).getPrice(true, true, true);
      pl.supplyWithPnl = IMixedLP(pool).getSupplyWithPnl(true,true);
    }else{
      pl.aum = ISingleLP(pool).tokenReserve();
      pl.price = ISingleLP(pool).getPrice(address(dipxStorage), true, true);
    }
  }

  function beforeAddLiquidity(address collateralToken,address targetPool,address to) external override onlyPlugin{

  }

  function afterAddLiquidity(address /*collateralToken*/,address targetPool,address /*to*/) external override onlyPlugin{
    _updatePoolLiquidity(targetPool);
  }

  function beforeRemoveLiquidity(address pool,address receiveToken, address to) external override onlyPlugin{

  }

  function afterRemoveLiquidity(address pool,address /*receiveToken*/, address /*to*/) external override onlyPlugin{
    _updatePoolLiquidity(pool);
  }

  function beforeIncreasePosition(
    address account,
    address indexToken, 
    address collateralToken,
    uint256 sizeDelta,
    uint256 collateralDelta,
    bool isLong
  ) external override onlyPlugin{

  }

  function afterIncreasePosition(
    address account,
    address indexToken, 
    address collateralToken,
    uint256 sizeDelta,
    uint256 /*collateralDelta*/,
    bool isLong,
    uint256 /*price*/,
    uint256 fee
  ) external override onlyPlugin{
    _increaseVolume(account, indexToken, collateralToken,isLong, sizeDelta, fee);
    _updatePoolLiquidity(collateralToken);
  }

  function beforeDecreasePosition(
    address account,
    address indexToken, 
    address collateralToken, 
    uint256 sizeDelta, 
    uint256 collateralDelta, 
    bool isLong, 
    address receiver
  ) external override onlyPlugin{

  }

  function afterDecreasePosition(
    address account,
    address indexToken, 
    address collateralToken, 
    uint256 sizeDelta, 
    uint256 /*collateralDelta*/,
    bool isLong, 
    address /*receiver*/,
    uint256 fee
  ) external override onlyPlugin{
    _increaseVolume(account, indexToken, collateralToken,isLong, sizeDelta, fee);
    _updatePoolLiquidity(collateralToken);
  }

  function beforeLiquidatePosition(
    address account, 
    address indexToken, 
    address collateralToken, 
    bool isLong,
    address feeReceiver
  ) external override onlyPlugin{

  }

  function afterLiquidatePosition(
    address account, 
    address indexToken, 
    address collateralToken, 
    bool isLong,
    address /*feeReceiver*/,
    uint256 size, 
    uint256 /*collateral*/, 
    uint256 /*markPrice*/, 
    uint256 /*liqFee*/,
    uint256 marginFee
  ) external override onlyPlugin{
    _increaseVolume(account, indexToken, collateralToken,isLong, size, marginFee);
    _updatePoolLiquidity(collateralToken);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IHandler{
  struct PoolVolume {
    address pool;
    uint256 date;
    uint256 value;
    uint256 valueInUsd;
    uint256 fee;
    uint256 feeInUsd;
    uint256 realValue;
    uint256 realValueInUsd;
  }
  struct PoolLiquidity {
    address pool;
    uint256 date;
    uint256 totalSupply;
    uint256 aum;
    uint256 price;
    uint256 supplyWithPnl;
  }  

  function getPoolVolume(address pool, uint256 date) external view returns(PoolVolume memory);
  function getUserVolume(bytes32 key) external view returns(PoolVolume memory);

  function beforeAddLiquidity(address collateralToken,address targetPool,address to) external;
  function afterAddLiquidity(address collateralToken,address targetPool,address to) external;
  function beforeRemoveLiquidity(address pool,address receiveToken, address to) external;
  function afterRemoveLiquidity(address pool,address receiveToken, address to) external;

  function beforeIncreasePosition(
    address account,
    address indexToken, 
    address collateralToken,
    uint256 sizeDelta,
    uint256 collateralDelta,
    bool isLong
  ) external;
  function afterIncreasePosition(
    address account,
    address indexToken, 
    address collateralToken,
    uint256 sizeDelta,
    uint256 collateralDelta,
    bool isLong,
    uint256 price,
    uint256 fee
  ) external;
  function beforeDecreasePosition(
    address account,
    address indexToken, 
    address collateralToken, 
    uint256 sizeDelta, 
    uint256 collateralDelta, 
    bool isLong, 
    address receiver
  ) external;
  function afterDecreasePosition(
    address account,
    address indexToken, 
    address collateralToken, 
    uint256 sizeDelta, 
    uint256 collateralDelta, 
    bool isLong, 
    address receiver,
    uint256 fee
  ) external;
  function beforeLiquidatePosition(
    address account, 
    address indexToken, 
    address collateralToken, 
    bool isLong,
    address feeReceiver
  ) external;
  function afterLiquidatePosition(
    address account, 
    address indexToken, 
    address collateralToken, 
    bool isLong,
    address feeReceiver,
    uint256 size, 
    uint256 collateral, 
    uint256 markPrice, 
    uint256 liqFee,
    uint256 marginFee
  ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IDipxStorage{
  struct SkewRule{
    uint256 min;             // BASIS_POINT_DIVISOR = 1
    uint256 max;             // BASIS_POINT_DIVISOR = 1
    uint256 delta;
    int256 light;            // BASIS_POINT_DIVISOR = 1
    uint256 heavy;
  }

  function initConfig(
    address _genesisPass,
    address _feeTo,
    address _vault, 
    address _lpManager, 
    address _positionManager, 
    address _priceFeed,
    address _router,
    address _referral,
    uint256 _positionFeePoints,
    uint256 _lpFeePoints,
    uint256 _fundingRateFactor,
    uint256 _gasFee
  ) external;

  function setContracts(
    address _genesisPass,
    address _feeTo,
    address _vault, 
    address _lpManager, 
    address _positionManager,
    address _priceFeed,
    address _router,
    address _handler,
    address _referral
  ) external;

  function genesisPass() external view returns(address);
  function vault() external view returns(address);
  function lpManager() external view returns(address);
  function positionManager() external view returns(address);
  function priceFeed() external view returns(address);
  function router() external view returns(address);
  function handler() external view returns(address);
  function referral() external view returns(address);

  function setGenesisPass(address _genesisPass,uint256 _gpDiscount) external;
  function setLpManager(address _lpManager) external;
  function setPositionManager(address _positionManager) external;
  function setVault(address _vault) external;
  function setPriceFeed(address _priceFeed) external;
  function setRouter(address _router) external;
  function setHandler(address _handler) external;
  function setReferral(address _referral) external;

  function feeTo() external view returns(address);
  function setFeeTo(address _feeTo) external;

  function setDefaultGasFee(uint256 _gasFee) external;
  function setTokenGasFee(address _collateralToken, bool _requireFee, uint256 _fee) external;
  function getTokenGasFee(address _collateralToken) external view returns(uint256);

  function currentFundingFactor(address _account,address _indexToken, address _collateralToken, bool _isLong) external view returns(int256);
  function cumulativeFundingRates(address indexToken, address collateralToken) external returns(uint256);
  function lastFundingTimes(address indexToken, address collateralToken) external returns(uint256);
  function setFundingInterval(uint256 _fundingInterval) external;
  function setFundingRateFactor(uint256 _fundingRateFactor) external;
  function updateCumulativeFundingRate(address _indexToken,address _collateralToken) external;
  function getFundingFee(
    address _account,
    address _indexToken, 
    address _collateralToken, 
    bool _isLong
  ) external view returns (int256);
  function setDefaultSkewRules(
    SkewRule[] memory _rules
  ) external;
  function setTokenSkewRules(
    address _collateralToken,
    SkewRule[] memory _rules
  ) external;

  function setAccountsFeePoint(
    address[] memory _accounts, 
    bool[] memory _whitelisted, 
    uint256[] memory _feePoints
  ) external;

  function setPositionFeePoints(uint256 _point,uint256 _lpPoint) external;
  function setTokenPositionFeePoints(address[] memory _lpTokens, uint256[] memory _rates) external;

  function getPositionFeePoints(address _collateralToken) external view returns(uint256);
  function getLpPositionFee(address _collateralToken,uint256 totalFee) external view returns(uint256);
  function getPositionFee(address _account,address _indexToken,address _collateralToken, uint256 _tradeAmount) external view returns(uint256);

  function setLpTaxPoints(address _pool, uint256 _buyFeePoints, uint256 _sellFeePoints) external;

  function eth() external view returns(address);
  function nativeCurrencyDecimals() external view returns(uint8);
  function nativeCurrency() external view returns(address);
  function nativeCurrencySymbol() external view returns(string memory);
  function isNativeCurrency(address token) external view returns(bool);
  function getTokenDecimals(address token) external view returns(uint256);

  function BASIS_POINT_DIVISOR() external view returns(uint256);
  function getBuyLpFeePoints(address _pool, address token,uint256 tokenDelta) external view returns(uint256);
  function getSellLpFeePoints(address _pool, address receiveToken,uint256 dlpDelta) external view returns(uint256);

  function greylist(address _account) external view returns(bool);
  function greylistAddress(address _address) external;
  function greylistedTokens(address _token) external view returns(bool);
  function setGreyListTokens(address[] memory _tokens, bool[] memory _disables) external;

  function increasePaused() external view returns(bool);
  function toggleIncrease() external;
  function tokenIncreasePaused(address _token) external view returns(bool);
  function toggleTokenIncrease(address _token) external;

  function decreasePaused() external view returns(bool);
  function toggleDecrease() external;
  function tokenDecreasePaused(address _token) external view returns(bool);
  function toggleTokenDecrease(address _token) external;

  function liquidatePaused() external view returns(bool);
  function toggleLiquidate() external;
  function tokenLiquidatePaused(address _token) external view returns(bool);
  function toggleTokenLiquidate(address _token) external;

  function maxLeverage() external view returns(uint256);
  function setMaxLeverage(uint256) external;
  
  function minProfitTime() external view returns(uint256);
  function minProfitBasisPoints(address) external view returns(uint256);
  function setMinProfit(uint256 _minProfitTime,address[] memory _indexTokens, uint256[] memory _minProfitBps) external;

  function approvedRouters(address,address) external view returns(bool);
  function approveRouter(address _router, bool _enable) external;
  function isLiquidator(address _account) external view returns (bool);
  function setLiquidator(address _liquidator, bool _isActive) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./IStorageSet.sol";

interface ILpManager is IStorageSet{
  function isLpToken(address _lpToken) external view returns(bool);
  function lpEnable(address _lpToken) external view returns(bool);

  function getAccountPoolLength(address _account) external view returns(uint256);
  function getAccountPoolAt(address _account, uint256 _index) external view returns(address);

  function getPoolPrice(address _pool, bool _maximise,bool _includeProfit, bool _includeLoss) external view returns(uint256);
  function lpTokens(address collateralToken) external view returns(address);
  function getSupplyWithPnl(address _lpToken, bool _includeProfit, bool _includeLoss) external view returns(uint256);

  function addLiquidityNative(address _to,address _targetPool) external returns(uint256);
  function addLiquidity(address _collateralToken,address _targetPool,address _to) external returns(uint256);
  function removeLiquidity(address _pool,address _receiveToken, address _to) external returns(uint256);

  function setPoolActive(address _pool, bool _isLp, bool _active) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./IStorageSet.sol";

interface IPositionManager is IStorageSet{
  struct Position {
    uint256 size;
    uint256 collateral;  
    uint256 averagePrice;
    uint256 entryFundingRate;
    int256 fundingFactor;
    uint256 lastIncreasedTime;
    int256 realisedPnl;
    uint256 averagePoolPrice;
    address account;
    address indexToken;
    address collateralToken;
    bool isLong;
  }

  function globalBorrowAmounts(address collateralToken) external view returns(uint256);

  function indexTokenLength() external view returns(uint256);
  function indexTokenAt(uint256 _at) external view returns(address);

  function enableIndexToken(address _indexToken,bool _enable) external;
  function toggleCollateralsAccept(address _indexToken) external;
  function addIndexCollaterals(address _indexToken,address[] memory _collateralTokens) external;
  function removeIndexCollaterals(address _indexToken,address[] memory _collateralTokens) external;

  function getMaxPrice(address _token) external view returns (uint256);
  function getMinPrice(address _token) external view returns (uint256);

  function getPositionLeverage(address _account, address _indexToken, address _collateralToken, bool _isLong) external view returns (uint256);

  function calculateUnrealisedPnl(address _indexToken, address _collateralToken) external view returns(bool, uint256);
  function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external returns (uint256, uint256);
  function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime) external view returns (bool, uint256);

  function getPositionKeyLength(address _account) external view returns(uint256);
  function getPositionKeyAt(address _account, uint256 _index) external view returns(bytes32);

  function getPositionByKey(bytes32 key) external view returns(Position memory);
  function getPosition(
    address account,
    address indexToken, 
    address collateralToken, 
    bool isLong
  ) external view returns(Position memory);

  function increasePosition(
    address account,
    address indexToken, 
    address collateralToken,
    uint256 sizeDelta,
    bool isLong
  ) external payable;

  function decreasePosition(
    address account,
    address indexToken, 
    address collateralToken, 
    uint256 sizeDelta, 
    uint256 collateralDelta, 
    bool isLong, 
    address receiver
  ) external payable returns(uint256);

  function liquidatePosition(
    address account, 
    address indexToken, 
    address collateralToken, 
    bool isLong,
    address feeReceiver
  ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface ILP {
  function isMixed() external view returns(bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "../../interfaces/IMintableERC20.sol";
import "../../interfaces/IWithdrawable.sol";
import "../../interfaces/IStorageSet.sol";
import "./ILP.sol";

interface IMixedLP is ILP,IMintableERC20,IWithdrawable,IStorageSet{
  function isWhitelistedToken(address _token) external view returns (bool);
  function allTokensLength() external view returns(uint256);
  function allTokens(uint256 i) external view returns(address);
  function isTokenPooled(address _token) external view returns(bool);
  function tokenReserves(address _token) external view returns(uint256);

  function setTokenConfigs(address[] memory _tokens, bool[] memory _isWhitelisteds) external;

  function getAum(bool maximise) external view returns (uint256);
  function getSupplyWithPnl(bool _includeProfit, bool _includeLoss) external view returns(uint256);
  function getPrice(bool _maximise,bool _includeProfit, bool _includeLoss) external view returns(uint256);

  function transferIn(address _token, uint256 _amount) external;
  function updateTokenReserves(address _token) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "../../interfaces/IMintableERC20.sol";
import "./ILP.sol";

interface ISingleLP is ILP,IMintableERC20{
    function tokenReserve() external returns(uint256);
    function token() external view returns(address);
    function withdraw(address to, uint256 amount) external;

    function getSupplyWithPnl(address _dipxStorage, bool _includeProfit, bool _includeLoss) external view returns(uint256);
    function getPrice(address _dipxStorage,bool _includeProfit, bool _includeLoss) external view returns(uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IReferral {
    function BASIS_POINTS() external view returns(uint256);
    function setHandler(address _handler, bool _isActive) external;
    function setTier(uint256 _tierId, uint256 _totalRebate, uint256 _discountShare) external;
    function setReferrerTier(address _referrer, uint256 _tierId) external;
    function setTraderReferral(address _account, address _referrer) external;

    function getTraderReferralInfo(address _account) external returns(address, uint256, uint256);

    function calculateRebateAmount(address _account, uint256 _fee) external view returns(uint256);
    function rebate(address _token, address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IStorageSet{
  function setDipxStorage(address _dipxStorage) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IMintableERC20 is IERC20Metadata{
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function isMinter(address account) external returns(bool);
    function setMinter(address _minter, bool _active) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IWithdrawable{
  function withdrawEth(address _to, uint256 _amount) external;
  function withdrawToken(address _token, address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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