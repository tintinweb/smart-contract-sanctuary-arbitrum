// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;
pragma abicoder v2;

struct IncreasePositionRequest {
  address account;
  address[] path;
  address indexToken;
  uint256 amountIn;
  uint256 minOut;
  uint256 sizeDelta;
  bool isLong;
  uint256 acceptablePrice;
  uint256 executionFee;
  uint256 blockNumber;
  uint256 blockTime;
  bool hasCollateralInETH;
  address callbackTarget;
}

struct DecreasePositionRequest {
  address account;
  address[] path;
  address indexToken;
  uint256 collateralDelta;
  uint256 sizeDelta;
  bool isLong;
  address receiver;
  uint256 acceptablePrice;
  uint256 minOut;
  uint256 executionFee;
  uint256 blockNumber;
  uint256 blockTime;
  bool withdrawETH;
  address callbackTarget;
}

interface IPositionRouter { 
  function minExecutionFee() external view returns (uint256);
  function minTimeDelayPublic() external view returns (uint256);
  function maxGlobalLongSizes(address) external view returns (uint256);
  function maxGlobalShortSizes(address) external view returns (uint256);
  function createIncreasePosition(
    address[] memory _path,
    address _indexToken,
    uint256 _amountIn,
    uint256 _minOut,
    uint256 _sizeDelta,
    bool _isLong,
    uint256 _acceptablePrice,
    uint256 _executionFee,
    bytes32 _referralCode,
    address _callbackTarget
  ) external payable returns (bytes32);
  function createDecreasePosition(
    address[] memory _path,
    address _indexToken,
    uint256 _collateralDelta,
    uint256 _sizeDelta,
    bool _isLong,
    address _receiver,
    uint256 _acceptablePrice,
    uint256 _minOut,
    uint256 _executionFee,
    bool _withdrawETH,
    address _callbackTarget
  ) external payable returns (bytes32);
  function increasePositionRequests(bytes32) external returns (IncreasePositionRequest calldata);
  function decreasePositionRequests(bytes32) external returns (DecreasePositionRequest calldata);
  function executeIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);
  function executeDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IRouter {
    function addPlugin(address _plugin) external;
    function approvePlugin(address _plugin) external;
    function pluginTransfer(address _token, address _account, address _receiver, uint256 _amount) external;
    function pluginIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function pluginDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IVaultUtils.sol";

interface IVault {
    function isInitialized() external view returns (bool);
    function isSwapEnabled() external view returns (bool);
    function isLeverageEnabled() external view returns (bool);

    function setVaultUtils(IVaultUtils _vaultUtils) external;
    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);
    function usdg() external view returns (address);
    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);
    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function fundingInterval() external view returns (uint256);
    function totalTokenWeights() external view returns (uint256);
    function getTargetUsdgAmount(address _token) external view returns (uint256);

    function inManagerMode() external view returns (bool);
    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(address _account, address _router) external view returns (bool);
    function isLiquidator(address _account) external view returns (bool);
    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(address _token) external view returns (uint256);
    function tokenBalances(address _token) external view returns (uint256);
    function lastFundingTimes(address _token) external view returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;
    function setInManagerMode(bool _inManagerMode) external;
    function setManager(address _manager, bool _isManager) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function setIsLeverageEnabled(bool _isLeverageEnabled) external;
    function setMaxGasPrice(uint256 _maxGasPrice) external;
    function setUsdgAmount(address _token, uint256 _amount) external;
    function setBufferAmount(address _token, uint256 _amount) external;
    function setMaxGlobalShortSize(address _token, uint256 _amount) external;
    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;
    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external;

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

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;
    function withdrawFees(address _token, address _receiver) external returns (uint256);

    function directPoolDeposit(address _token) external;
    function buyUSDG(address _token, address _receiver) external returns (uint256);
    function sellUSDG(address _token, address _receiver) external returns (uint256);
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function liquidatePosition(address _account, address _collateralToken, address _indexToken, bool _isLong, address _feeReceiver) external;
    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

    function priceFeed() external view returns (address);
    function fundingRateFactor() external view returns (uint256);
    function stableFundingRateFactor() external view returns (uint256);
    function cumulativeFundingRates(address _token) external view returns (uint256);
    function getNextFundingRate(address _token) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function swapFeeBasisPoints() external view returns (uint256);
    function stableSwapFeeBasisPoints() external view returns (uint256);
    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256) external view returns (address);
    function whitelistedTokens(address _token) external view returns (bool);
    function stableTokens(address _token) external view returns (bool);
    function shortableTokens(address _token) external view returns (bool);
    function feeReserves(address _token) external view returns (uint256);
    function globalShortSizes(address _token) external view returns (uint256);
    function globalShortAveragePrices(address _token) external view returns (uint256);
    function maxGlobalShortSizes(address _token) external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function tokenWeights(address _token) external view returns (uint256);
    function guaranteedUsd(address _token) external view returns (uint256);
    function poolAmounts(address _token) external view returns (uint256);
    function bufferAmounts(address _token) external view returns (uint256);
    function reservedAmounts(address _token) external view returns (uint256);
    function usdgAmounts(address _token) external view returns (uint256);
    function maxUsdgAmounts(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);

    function getPositionDelta(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (bool, uint256);
    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime) external view returns (bool, uint256);
    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);
    function positions(bytes32 positionKey) external view returns (uint256, uint256, uint256, uint256, uint256, int256, uint256);
    function usdToTokenMax(address _token, uint256 _usdAmount) external view returns (uint256);
    function usdToTokenMin(address _token, uint256 _usdAmount) external view returns (uint256);
    function usdToToken(address _token, uint256 _usdAmount, uint256 _price) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IVaultUtils {
    function updateCumulativeFundingRate(address _collateralToken, address _indexToken) external returns (bool);
    function validateIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external view;
    function validateDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external view;
    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function getEntryFundingRate(address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256);
    function getPositionFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _sizeDelta) external view returns (uint256);
    function getFundingFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _size, uint256 _entryFundingRate) external view returns (uint256);
    function getBuyUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getSellUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _usdgAmount) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

import "../interfaces/gmx/IVault.sol";
import "../interfaces/gmx/IPositionRouter.sol";
import "../interfaces/gmx/IRouter.sol";

/**
 * @notice
 *  This is a GMX perpetual trading strategy contract
 *  inputs: address[3], [hypervisorAddress, indexToken, hedgeTokenAddress]
 *  config: abi.encodePacked(bytes32(referralCode))
 */
contract PerpetualStrategy {
  string public name = "gmx-perp-strategy";
  IVault public gmxVault;
  IPositionRouter public positionRouter;
  IRouter public gmxRouter;
  address public strategist;
  mapping (address => mapping(uint256 => bool)) signal;  // mapping(tradeToken => mapping(lookback => signal));

  modifier onlyStrategist() {
    require(msg.sender == strategist, "!strategist");
    _;
  }

  constructor() {
    gmxVault = IVault(0x489ee077994B6658eAfA855C308275EAd8097C4A);
    gmxRouter = IRouter(0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064);
    positionRouter = IPositionRouter(0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868);
  }

  function setSignal(address _tradeToken, uint256 _lookback, bool _signal) external onlyStrategist {
    signal[_tradeToken][_lookback] = _signal;
  }
  /**
   * @notice
   *  create increase position
   *  we can't interact directly with GMX vault contract because leverage was disabled by default and 
   *   can be set only by TimeLock(governance) and registered contracts. So we need to use their 
   *   peripheral contracts to do perp.
   *  this function doesn't open position actually, just register position information. Actual position
   *   opening/closing is done by a keeper of GMX vault.
   * @param indexToken the address of token to long / short
   * @param collateralToken the address of token to be used as collateral. 
   *  in long position, `collateralToken` should the same as `indexToken`.
   *  in short position, `collateralToken` should be stable coin.
   * @param amountIn: the amount of tokenIn you want to deposit as collateral
   * @param minOut: the min amount of collateralToken to swap for
   * @param sizeDelta: the USD value of the change in position size. decimals is 30
   * @param isLong: if long, true or false
   */
  function createIncreasePosition(
    address indexToken,
    address collateralToken,
    uint256 amountIn,
    uint256 minOut,
    uint256 sizeDelta,
    bool isLong
  ) external payable {
    // if (isLong == true) {
    //   require(indexToken == collateralToken, "invalid collateralToken");
    // }
    // require(msg.value >= positionRouter.minExecutionFee(), "too low execution fee");
    // require(
    //   sizeDelta > gmxVault.tokenToUsdMin(address(hedgeToken), amountIn),
    //   "too low leverage"
    // );
    // require(
    //   sizeDelta.div(gmxVault.tokenToUsdMin(address(hedgeToken), amountIn)) < gmxVault.maxLeverage().div(BASIS_POINTS_DIVISOR),
    //   "exceed max leverage"
    // );
    // // check available amounts to open positions
    // _checkPool(isLong, indexToken, collateralToken, sizeDelta);

    // /* code to check minimum open position amount in the case of first opening */
    
    // address[] memory path;
    // if (address(hedgeToken) == collateralToken) {
    //   path = new address[](1);
    //   path[0] = address(hedgeToken);
    // } else {
    //   path = new address[](2);
    //   path[0] = address(hedgeToken);
    //   path[1] = collateralToken;
    // }
    
    // uint256 priceBasisPoints = isLong ? BASIS_POINTS_DIVISOR + _slippage : BASIS_POINTS_DIVISOR - _slippage;
    // uint256 refPrice = isLong ? gmxVault.getMaxPrice(indexToken) : gmxVault.getMinPrice(indexToken);
    // uint256 acceptablePrice = refPrice.mul(priceBasisPoints).div(BASIS_POINTS_DIVISOR);
    
    // bytes32 requestKey = IPositionRouter(positionRouter).createIncreasePosition{value: msg.value}(
    //   path,
    //   indexToken,
    //   amountIn,
    //   minOut,       // it's better to provide minimum output token amount from a caller rather than calculate here
    //   sizeDelta,    // we can set sizeDelta based on leverage value. need to decide which one is preferred
    //   isLong,
    //   acceptablePrice,   // current ETH mark price, check which is more efficient between minPrice and maxPrice
    //   msg.value,
    //   _referralCode,
    //   address(this)
    // );

  }

  /**
   * @notice
   *  create decrease position
   *  we can't interact directly with GMX vault contract because leverage was disabled by default and 
   *   can be set only by TimeLock(governance) and registered contracts. So we need to use their 
   *   peripheral contracts to do perp.
   *  this function doesn't close position actually, just register position information. Actual position
   *   opening/closing is done by a keeper of GMX vault.
   * @param indexToken the address of token to long / short
   * @param collateralToken the address of token to be used as collateral. 
   *  in long position, `collateralToken` should the same as `indexToken`.
   *  in short position, `collateralToken` should be stable coin.
   * @param collateralDelta: the amount of collateral in USD value to withdraw
   * @param sizeDelta: the USD value of the change in position size. decimals is 30
   * @param isLong: if long, true or false
   * @param minOut: the min output token amount you would receive
   */
  function createDecreasePosition(
    address indexToken,
    address collateralToken,
    uint256 collateralDelta,
    uint256 sizeDelta,
    bool isLong,
    uint256 minOut
  ) public payable {
    // if (isLong == true) {
    //   require(indexToken == collateralToken, "invalid collateralToken");
    // }
    // require(msg.value >= IPositionRouter(positionRouter).minExecutionFee(), "too low execution fee");
    // // require(
    // //   sizeDelta > collateralDelta,
    // //   "too low leverage"
    // // );
    // // require(
    // //   sizeDelta.div(gmxVault.tokenToUsdMin(address(hedgeToken), amountIn)) < gmxVault.maxLeverage().div(BASIS_POINTS_DIVISOR),
    // //   "exceed max leverage"
    // // );

    // address[] memory path;
    // if (address(hedgeToken) == collateralToken) {
    //   path = new address[](1);
    //   path[0] = address(hedgeToken);
    // } else {
    //   path = new address[](2);
    //   path[0] = collateralToken;
    //   path[1] = address(hedgeToken);
    // }
    
    // uint256 priceBasisPoints = isLong ? BASIS_POINTS_DIVISOR - _slippage : BASIS_POINTS_DIVISOR + _slippage;
    // uint256 refPrice = isLong ? gmxVault.getMinPrice(indexToken) : gmxVault.getMaxPrice(indexToken);
    // uint256 acceptablePrice = refPrice.mul(priceBasisPoints).div(BASIS_POINTS_DIVISOR);
    // bytes32 requestKey = IPositionRouter(positionRouter).createDecreasePosition{value: msg.value}(
    //   path,
    //   indexToken,
    //   collateralDelta,
    //   sizeDelta,
    //   isLong,
    //   address(this),
    //   acceptablePrice,
    //   minOut,
    //   msg.value,
    //   false,
    //   address(this)
    // );

  }

  function run(bytes calldata performData) external {
    // Caller caller = Caller(msg.sender);
    // // check if caller has fund in gmx
    // // if yes,
    // bytes32 positionKey = keccak256(abi.encodePacked(
    //   caller.address,
    //   collateralToken,
    //   indexToken,
    //   isLong
    // ));
    // (uint256 size, , , , , , ) = gmxVault.positions(positionKey);
    // createDecreasePosition(indexToken, collateralToken, 0, size, isLong, minOut);
  }

  function getSignal(address _tradeToken, uint256 _lookback) external view returns (bool) {
    return signal[_tradeToken][_lookback];
  }
}