// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IDegenMain.sol";
import "./interfaces/IDegenPriceManager.sol";
import "./interfaces/IDegenRouter.sol";
import "./interfaces/IDegenReader.sol";
import "./interfaces/IDegenPoolManager.sol";

/**
 * @title DegenReader
 * @author balding-ghost
 * @notice The DegenReader contract should be used for all reading of the degen game state. It provides functions to read out state correctly. It is technically possible to direclty read data from DegenMain however this is not recommended as it is easy to make mistakes.
 */
contract DegenReader is IDegenReader {
  uint256 internal constant PRICE_PRECISION = 1e18;
  uint256 public constant BASIS_POINTS = 1e6;
  IDegenMain public immutable degenMain;
  IDegenRouter public immutable router;
  IDegenPoolManager public immutable poolManager;
  IERC20 public immutable targetToken;
  bytes32 public immutable pythAssetId;
  IDegenPriceManager public immutable priceManager;

  constructor(address _degenMain, address _targetToken) {
    degenMain = IDegenMain(_degenMain);
    router = IDegenRouter(IDegenBase(_degenMain).router());
    priceManager = IDegenPriceManager(router.priceManager());
    poolManager = IDegenPoolManager(router.poolManager());
    pythAssetId = priceManager.pythAssetId();
    targetToken = IERC20(_targetToken);
  }

  function calculateInterestPosition(
    bytes32 _positionKey,
    uint256 _timestampAt
  ) external view returns (uint256 interestAccruedUsd_) {
    interestAccruedUsd_ = degenMain.calculateInterestPosition(_positionKey, _timestampAt);
  }

  function netPnlOfPositionWithInterest(
    bytes32 _positionKey,
    uint256 _assetPrice,
    uint256 _timestampAt
  ) external view returns (int256 pnlUsd_) {
    (pnlUsd_) = _netPnlOfPosition(_positionKey, _assetPrice, _timestampAt);
  }

  function netPnlOfPositionWithInterestUpdateData(
    bytes32 _positionKey,
    bytes memory _updateData,
    uint256 _timestampAt
  ) external view returns (int256 pnlUsd_) {
    uint256 assetPrice_ = _getPriceFromUpdateData(_updateData);
    (pnlUsd_) = _netPnlOfPosition(_positionKey, assetPrice_, _timestampAt);
  }

  function isPositionLiquidatableByKeyAtTimeUpdateData(
    bytes32 _positionKey,
    bytes memory _updateData,
    uint256 _timestampAt
  ) external view returns (bool isPositionLiquidatable_) {
    uint256 assetPrice_ = _getPriceFromUpdateData(_updateData);
    isPositionLiquidatable_ = _isPositionLiquidatable(_positionKey, assetPrice_, _timestampAt);
  }

  function isPositionLiquidatable(
    bytes32 _positionKey
  ) external view returns (bool isPositionLiquidatable_) {
    (uint256 assetPrice_, ) = priceManager.getLastPriceUnsafe();
    isPositionLiquidatable_ = degenMain.isPositionLiquidatableByKeyAtTime(
      _positionKey,
      assetPrice_,
      block.timestamp
    );
  }

  function _isUserPositionCloseAllowed(
    uint256 _positionOpenTimestamp
  ) internal view returns (bool isAllowed_) {
    unchecked {
      isAllowed_ = block.timestamp >= _positionOpenTimestamp + degenMain.minimumPositionDuration();
    }
  }

  function isPositionLiquidatableUpdateData(
    bytes32 _positionKey,
    bytes memory _updateData
  ) external view returns (bool isPositionLiquidatable_) {
    uint256 assetPrice_ = _getPriceFromUpdateData(_updateData);
    isPositionLiquidatable_ = _isPositionLiquidatable(_positionKey, assetPrice_, block.timestamp);
  }

  function isPositionLiquidatableByKeyAtTime(
    bytes32 _positionKey,
    uint256 _assetPrice,
    uint256 _timestampAt
  ) external view returns (bool isPositionLiquidatable_) {
    isPositionLiquidatable_ = _isPositionLiquidatable(_positionKey, _assetPrice, _timestampAt);
  }

  function returnOrderInfo(
    uint256 _orderIndex
  ) external view returns (OrderInfo memory orderInfo_) {
    orderInfo_ = degenMain.returnOrderInfo(_orderIndex);
  }

  function returnOpenPositionInfo(
    bytes32 _positionKey
  ) external view returns (PositionInfo memory positionInfo_) {
    positionInfo_ = degenMain.returnOpenPositionInfo(_positionKey);
  }

  function returnClosedPositionInfo(
    bytes32 _positionKey
  ) external view returns (ClosedPositionInfo memory closedPositionInfo_) {
    closedPositionInfo_ = degenMain.returnClosedPositionInfo(_positionKey);
  }

  function amountOpenOrders() external view returns (uint256 openOrdersCount_) {
    openOrdersCount_ = degenMain.amountOpenOrders();
  }

  function amountOpenPositions() external view returns (uint256 openPositionsCount_) {
    openPositionsCount_ = degenMain.amountOpenPositions();
  }

  function isOpenPosition(bytes32 _positionKey) external view returns (bool isPositionOpen_) {
    isPositionOpen_ = degenMain.isOpenPosition(_positionKey);
  }

  function isOpenOrder(uint256 _orderIndex) external view returns (bool isOpenOrder_) {
    isOpenOrder_ = degenMain.isOpenOrder(_orderIndex);
  }

  function isClosedPosition(bytes32 _positionKey) external view returns (bool isClosedPosition_) {
    isClosedPosition_ = degenMain.isClosedPosition(_positionKey);
  }

  function getFundingRate(bool _long) external view returns (uint256 fundingRate_) {
    fundingRate_ = degenMain.getFundingRate(_long);
  }

  function getOpenPositionsInfo() external view returns (PositionInfo[] memory _positions) {
    _positions = degenMain.getOpenPositionsInfo();
  }

  function getOpenPositionKeys() external view returns (bytes32[] memory _positionKeys) {
    _positionKeys = degenMain.getOpenPositionKeys();
  }

  function getAllOpenOrdersInfo() external view returns (OrderInfo[] memory _orders) {
    _orders = degenMain.getAllOpenOrdersInfo();
  }

  function getAllClosedPositionsInfo()
    external
    view
    returns (ClosedPositionInfo[] memory _positions)
  {
    _positions = degenMain.getAllClosedPositionsInfo();
  }

  function getAllOpenOrderIndexes() external view returns (uint256[] memory _orderIndexes) {
    _orderIndexes = degenMain.getAllOpenOrderIndexes();
  }

  function getAllLiquidatablePositions(
    uint256 _assetPrice,
    uint256 _timestampAt
  ) external view returns (bytes32[] memory _liquidatablePositions) {
    _liquidatablePositions = degenMain.getAllLiquidatablePositions(_assetPrice, _timestampAt);
  }

  function getAmountOfLiquidatablePoisitions(
    uint256 _assetPrice,
    uint256 _timestampAt
  ) external view returns (uint256 amountOfLiquidatablePositions_) {
    bytes32[] memory liquidatablePositions_ = degenMain.getAllLiquidatablePositions(
      _assetPrice,
      _timestampAt
    );
    amountOfLiquidatablePositions_ = liquidatablePositions_.length;
  }

  function getAllLiquidatablePositionsUpdateData(
    bytes memory _updateData,
    uint256 _timestampAt
  ) external view returns (bytes32[] memory _liquidatablePositions) {
    uint256 assetPrice_ = _getPriceFromUpdateData(_updateData);
    _liquidatablePositions = degenMain.getAllLiquidatablePositions(assetPrice_, _timestampAt);
  }

  function getAmountOfLiquidatablePositionsUpdateData(
    bytes memory _updateData,
    uint256 _timestampAt
  ) external view returns (uint256 amountOfLiquidatablePositions_) {
    uint256 assetPrice_ = _getPriceFromUpdateData(_updateData);
    bytes32[] memory liquidatablePositions_ = degenMain.getAllLiquidatablePositions(
      assetPrice_,
      _timestampAt
    );
    amountOfLiquidatablePositions_ = liquidatablePositions_.length;
  }

  function isPriceUpdateRequired() external view returns (bool isUpdateNeeded_) {
    uint256 secondsSinceUpdate_ = priceManager.returnFreshnessOfOnChainPrice();
    isUpdateNeeded_ = !_checkPriceFreshness(secondsSinceUpdate_);
  }

  function willUpdateDataUpdateThePrice(
    bytes calldata _updateData
  ) external view returns (bool willUpdatePrice_) {
    PythStructs.PriceFeed memory updateInfo_ = abi.decode(_updateData, (PythStructs.PriceFeed));
    uint256 priceOracleUpdateTimestamp_ = priceManager.timestampLatestPricePublishPyth();
    willUpdatePrice_ = (updateInfo_.price.publishTime > priceOracleUpdateTimestamp_);
  }

  function isUpdateDataRecentEnoughForExecution(
    bytes calldata _updateData
  ) external view returns (bool isRecentEnough_) {
    PythStructs.PriceFeed memory updateInfo_ = abi.decode(_updateData, (PythStructs.PriceFeed));
    isRecentEnough_ = _checkPriceFreshness(block.timestamp - updateInfo_.price.publishTime);
  }

  function returnAllOpenPositionsOfUser(
    address _user
  ) external view returns (PositionInfo[] memory _userPositions) {
    PositionInfo[] memory allPositions_ = degenMain.getOpenPositionsInfo();
    for (uint256 i = 0; i < allPositions_.length; i++) {
      if (allPositions_[i].player == _user) {
        _userPositions[i] = allPositions_[i];
      }
    }
  }

  function returnAllOpenOrdersOfUser(
    address _user
  ) external view returns (OrderInfo[] memory _userOrders) {
    OrderInfo[] memory allOrders_ = degenMain.getAllOpenOrdersInfo();
    for (uint256 i = 0; i < allOrders_.length; i++) {
      if (allOrders_[i].player == _user) {
        _userOrders[i] = allOrders_[i];
      }
    }
  }

  function returnAllClosedPositionsOfUser(
    address _user
  ) external view returns (ClosedPositionInfo[] memory _userPositions) {
    ClosedPositionInfo[] memory allPositions_ = degenMain.getAllClosedPositionsInfo();
    for (uint256 i = 0; i < allPositions_.length; i++) {
      if (allPositions_[i].player == _user) {
        _userPositions[i] = allPositions_[i];
      }
    }
  }

  // internal functions
  function _getPriceFromUpdateData(
    bytes memory _updateData
  ) internal view returns (uint256 price_) {
    PythStructs.PriceFeed memory updateInfo_ = abi.decode(_updateData, (PythStructs.PriceFeed));
    // check if price is valid
    require(updateInfo_.id == pythAssetId, "DegenReader: invalid price feed id");
    price_ = _convertPriceToUint(updateInfo_.price);
  }

  function _convertPriceToUint(
    PythStructs.Price memory priceInfo_
  ) internal pure returns (uint256 assetPrice_) {
    uint256 price = uint256(uint64(priceInfo_.price));
    if (priceInfo_.expo >= 0) {
      uint256 exponent = uint256(uint32(priceInfo_.expo));
      assetPrice_ = price * PRICE_PRECISION * (10 ** exponent);
    } else {
      uint256 exponent = uint256(uint32(-priceInfo_.expo));
      assetPrice_ = (price * PRICE_PRECISION) / (10 ** exponent);
    }
    return assetPrice_;
  }

  function _netPnlOfPosition(
    bytes32 _positionKey,
    uint256 _assetPrice,
    uint256 _timestampAt
  ) internal view returns (int256 pnlUsd_) {
    (pnlUsd_) = degenMain.netPnlOfPosition(_positionKey, _assetPrice, _timestampAt);
  }

  function _isPositionLiquidatable(
    bytes32 _positionKey,
    uint256 _assetPrice,
    uint256 _timestampAt
  ) internal view returns (bool isPositionLiquidatable_) {
    isPositionLiquidatable_ = degenMain.isPositionLiquidatableByKeyAtTime(
      _positionKey,
      _assetPrice,
      _timestampAt
    );
  }

  function _checkPriceFreshness(uint256 _ageOfPricePublish) internal view returns (bool isFresh_) {
    isFresh_ = _ageOfPricePublish <= router.priceFreshnessThreshold();
  }

  // helper functions

  function getPositionKey(
    address _account,
    bool _isLong,
    uint256 _posId
  ) external view returns (bytes32 positionKey_) {
    positionKey_ = _getPositionKey(_account, _isLong, _posId);
  }

  function _getPositionKey(
    address _account,
    bool _isLong,
    uint256 _posId
  ) internal view returns (bytes32 positionKey_) {
    unchecked {
      positionKey_ = keccak256(abi.encodePacked(_account, address(targetToken), _isLong, _posId));
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./DegenStructs.sol";
import "./IDegenBase.sol";

interface IDegenMain is IDegenBase {
  function submitOrder(
    OrderInfo memory _order
  ) external returns (uint256 _orderIndex_);

  function cancelOrder(
    uint256 _orderIndex_,
    address _caller
  ) external returns (uint256 marginAmount_);

  function executeOrder(
    uint256 _orderIndex_,
    uint256 _assetPrice,
    uint256 _marginAmountUsdc
  ) external returns (bytes32 positionKey_);

  function closePosition(bytes32 _positionKey, address _caller, uint256 _assetPric) external;

  function liquidatePosition(bytes32 _positionKey, address _caller, uint256 _assetPrice) external;

  // View Functions

  function calculateInterestPosition(
    bytes32 _positionKey,
    uint256 _timestampAt
  ) external view returns (uint256 interestAccruedUsd_);

  function netPnlOfPosition(
    bytes32 _positionKey,
    uint256 _assetPrice,
    uint256 _timestampAt
  ) external view returns (int256 INT_pnlUsd_);

  function isPositionLiquidatableByKeyAtTime(
    bytes32 _positionKey,
    uint256 _assetPrice,
    uint256 _timestampAt
  ) external view returns (bool isPositionLiquidatable_);

  function returnOrderInfo(uint256 _orderIndex) external view returns (OrderInfo memory);

  function returnOpenPositionInfo(bytes32 _positionKey) external view returns (PositionInfo memory);

  function returnClosedPositionInfo(
    bytes32 _positionKey
  ) external view returns (ClosedPositionInfo memory);

  function getAllClosedPositionsInfo()
    external
    view
    returns (ClosedPositionInfo[] memory _positions);

  function getPositionKeyOfOrderIndex(
    uint256 _orderIndex
  ) external view returns (bytes32 positionKey_);

  function amountOpenOrders() external view returns (uint256 openOrdersCount_);

  function amountOpenPositions() external view returns (uint256 openPositionsCount_);

  function isOpenPosition(bytes32 _positionKey) external view returns (bool isPositionOpen_);

  function isOpenOrder(uint256 _orderIndex) external view returns (bool isOpenOrder_);

  function isClosedPosition(bytes32 _positionKey) external view returns (bool isClosedPosition_);

  function getOpenPositionsInfo() external view returns (PositionInfo[] memory _positions);

  function getOpenPositionKeys() external view returns (bytes32[] memory _positionKeys);

  function getAllOpenOrdersInfo() external view returns (OrderInfo[] memory _orders);

  function getAllOpenOrderIndexes() external view returns (uint256[] memory _orderIndexes);

  function getAllLiquidatablePositions(
    uint256 _assetPrice,
    uint256 _timestampAt
  ) external view returns (bytes32[] memory _liquidatablePositions);

  // Events

  event OrderCancelledByPoolManager(uint256 orderIndex, address caller, uint256 marginAmount);
  event OrderCancelled(uint256 indexed orderIndex, OrderInfo orderInfo_);
  event OrderSubmitted(uint256 indexed orderIndex, OrderInfo orderInfo_);
  event OrderExecuted(
    uint256 indexed _orderIndex,
    bytes32 indexed _positionKey,
    PositionInfo _position
  );
  event PositionClosed(bytes32 indexed positionKey, ClosedPositionInfo positionInfo, uint256 marginAssetAmount_, uint256 feesPaid_);
  event PositionLiquidated(bytes32 indexed positionKey, ClosedPositionInfo positionInfo, bool isInterestLiquidation);
  event LiquidationFailed(bytes32 indexed positionKey, address indexed liquidator);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

interface IDegenPriceManager {
  function stableTokenAddress() external view returns (address);

  function stableTokenDecimals() external view returns (uint256);

  function pyth() external view returns (IPyth);

  function pythAssetId() external view returns (bytes32);

  function returnMostRecentPricePyth() external view returns (PythStructs.Price memory);

  function timestampLatestPricePublishPyth() external view returns (uint256);

  function priceOfAssetUint() external view returns (uint256);

  function returnPriceAndUpdate()
    external
    view
    returns (uint256 assetPrice_, uint256 lastUpdateTimestamp_);

  function getLatestAssetPriceAndUpdate(
    bytes calldata _priceUpdateData
  ) external payable returns (uint256 assetPrice_, uint256 secondsSincePublish_);

  function syncPriceWithPyth() external returns (uint256 priceOfAssetUint_, bool isUpdated_);

  function returnFreshnessOfOnChainPrice() external view returns (uint256 secondsSincePublish_);

  function refreshPrice(
    bytes calldata _priceUpdateData
  ) external payable returns (uint256 assetPrice_, uint256 secondsSincePublish_);

  function tokenAddress() external view returns (address);

  function tokenDecimals() external view returns (uint256);

  function getLastPriceUnsafe()
    external
    view
    returns (uint256 priceOfAssetUint_, uint256 secondsSincePublish_);

  function tokenToUsd(address _token, uint256 _tokenAmount) external view returns (uint256);

  function usdToToken(address _token, uint256 _usdAmount) external view returns (uint256);

  // events
  event OnChainPriceUpdated(PythStructs.Price priceInfo);
  event NoOnChainUpdateRequired(PythStructs.Price priceInfo);
  event OraclePriceUpdated(uint256 priceOfAssetUint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDegenPriceManager.sol";
import "./IDegenPoolManager.sol";
import "./IDegenMain.sol";

interface IDegenRouter {
  function degenMain() external view returns (IDegenMain);

  function priceFreshnessThreshold() external view returns (uint256);

  function priceManager() external view returns (IDegenPriceManager);

  function poolManager() external view returns (IDegenPoolManager);

  function submitOrderManual(
    uint16 _positionLeverage,
    uint96 _wagerAmount,
    uint96 _minOpenPrice,
    uint96 _maxOpenPrice,
    uint32 _timestampExpired,
    address _marginAsset,
    bool _isLong
  ) external returns (uint256 orderIndex_);

  function liquidateLiquidatablePositionsOnChainPrice()
    external
    returns (uint256 amountOfLiquidations_);

  function liquidateLiquidatablePositions(
    bytes calldata _updateData
  ) external returns (uint256 amountOfLiquidations_);

  function cancelOpenOrder(uint256 _orderIndex) external returns (uint256 marginAmount_);

  function executeOpenOrder(
    bytes calldata _updateData,
    uint256 _orderIndex
  ) external returns (bytes32 positionKey_, uint256 executionPrice_, bool _successFull);

  function closeOpenPosition(
    bytes calldata _updateData,
    bytes32 _positionKey
  ) external returns (uint256 executionPrice_, bool _successFull);

  function liquidatePosition(
    bytes calldata _updateData,
    bytes32 _positionKey
  ) external returns (uint256 executionPrice_, bool _successFull);

  event OpenOrderCancelled(
    uint256 indexed orderIndex,
    address indexed player,
    uint256 marginAmount
  );

  event PositionLiquidationFailed(
    bytes32 indexed positionKey,
    address indexed liquidator,
    uint256 executionPrice_
  );

  event PositionCloseFail(
    bytes32 indexed positionKey,
    address indexed player,
    uint256 executionPrice
  );

  event OpenOrderExecuted(
    bytes32 indexed positionKey,
    address indexed player,
    uint256 executionPrice,
    uint256 stableCoinMargin,
    uint256 swapFeePaidStableCoin
  );

  event PositionClosed(bytes32 indexed positionKey, address indexed player, uint256 executionPrice);

  event OpenOrderNotExecuted(
    bytes32 indexed positionKey,
    address indexed player,
    uint256 executionPrice
  );

  event PositionLiquidated(
    bytes32 indexed positionKey,
    address indexed liquidator,
    uint256 executionPrice
  );

  event OpenOrderSubmitted(uint256 orderIndex, address indexed player, uint256 marginAmount);

  event AllowedWagerSet(address asset, bool allowed);

  event FailedOnExecutionSet(bool failedOnExecution);

  event PriceFreshnessThresholdSet(uint256 priceFreshnessThreshold);
  
  event AllowedKeeperSet(address _keeper, bool _allowed);

  event ControllerChanged(address _newController);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./DegenStructs.sol";

interface IDegenReader {
  function calculateInterestPosition(
    bytes32 _positionKey,
    uint256 _timestampAt
  ) external view returns (uint256 interestAccruedUsd_);

  function netPnlOfPositionWithInterest(
    bytes32 _positionKey,
    uint256 _assetPrice,
    uint256 _timestampAt
  ) external view returns (int256 pnlUsd_);

  function netPnlOfPositionWithInterestUpdateData(
    bytes32 _positionKey,
    bytes memory _updateData,
    uint256 _timestampAt
  ) external view returns (int256 pnlUsd_);

  function isPositionLiquidatableByKeyAtTimeUpdateData(
    bytes32 _positionKey,
    bytes memory _updateData,
    uint256 _timestampAt
  ) external view returns (bool isPositionLiquidatable_);

  function getFundingRate(bool _long) external view returns (uint256 fundingRate_);

  function getAmountOfLiquidatablePositionsUpdateData(
    bytes memory _updateData,
    uint256 _timestampAt
  ) external view returns (uint256 amountOfLiquidatablePositions_);

  function getAmountOfLiquidatablePoisitions(
    uint256 _assetPrice,
    uint256 _timestampAt
  ) external view returns (uint256 amountOfLiquidatablePositions_);

  function isPositionLiquidatable(
    bytes32 _positionKey
  ) external view returns (bool isPositionLiquidatable_);

  function isPositionLiquidatableUpdateData(
    bytes32 _positionKey,
    bytes memory _updateData
  ) external view returns (bool isPositionLiquidatable_);

  function returnOrderInfo(uint256 _orderIndex) external view returns (OrderInfo memory orderInfo_);

  function returnOpenPositionInfo(
    bytes32 _positionKey
  ) external view returns (PositionInfo memory positionInfo_);

  function returnClosedPositionInfo(
    bytes32 _positionKey
  ) external view returns (ClosedPositionInfo memory closedPositionInfo_);

  function amountOpenOrders() external view returns (uint256 openOrdersCount_);

  function amountOpenPositions() external view returns (uint256 openPositionsCount_);

  function isOpenPosition(bytes32 _positionKey) external view returns (bool isPositionOpen_);

  function isOpenOrder(uint256 _orderIndex) external view returns (bool isOpenOrder_);

  function isClosedPosition(bytes32 _positionKey) external view returns (bool isClosedPosition_);

  function getOpenPositionsInfo() external view returns (PositionInfo[] memory _positions);

  function getOpenPositionKeys() external view returns (bytes32[] memory _positionKeys);

  function getAllOpenOrdersInfo() external view returns (OrderInfo[] memory _orders);

  function getAllOpenOrderIndexes() external view returns (uint256[] memory _orderIndexes);

  function returnAllClosedPositionsOfUser(
    address _user
  ) external view returns (ClosedPositionInfo[] memory _userPositions);

  function returnAllOpenOrdersOfUser(
    address _user
  ) external view returns (OrderInfo[] memory _userOrders);

  function returnAllOpenPositionsOfUser(
    address _user
  ) external view returns (PositionInfo[] memory _userPositions);

  function getAllLiquidatablePositions(
    uint256 _assetPrice,
    uint256 _timestampAt
  ) external view returns (bytes32[] memory _liquidatablePositions);

  function getAllLiquidatablePositionsUpdateData(
    bytes memory _updateData,
    uint256 _timestampAt
  ) external view returns (bytes32[] memory _liquidatablePositions);

  function isPriceUpdateRequired() external view returns (bool isUpdateNeeded_);

  function willUpdateDataUpdateThePrice(
    bytes calldata _updateData
  ) external view returns (bool willUpdatePrice_);

  function isUpdateDataRecentEnoughForExecution(
    bytes calldata _updateData
  ) external view returns (bool isRecentEnough_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IDegenPoolManagerSettings.sol";

interface IDegenPoolManager is IDegenPoolManagerSettings {
  // function totalRealizedProfitsUsd() external view returns (uint256 totalRealizedProfits_);

  // function totalRealizedLossesUsd() external view returns (uint256 totalRealizedLosses_);

  function totalTheoreticalBadDebtUsdPeriod()
    external
    view
    returns (uint256 totalTheoreticalBadDebt_);

  // function totalCloseFeeProtocolPartitionUsdPeriod()
  //   external
  //   view
  //   returns (uint256 totalCloseFeeProtocolPartition_);

  // function totalFundingRatePartitionUsdPeriod()
  //   external
  //   view
  //   returns (uint256 totalFundingRatePartition_);

  function maxLossesAllowedStableTotal() external view returns (uint256 payoutBufferAmount_);

  function totalActiveMarginInUsd() external view returns (uint256 totalEscrowTokens_);

  // function totalLiquidatorFeesUsdPeriod() external view returns (uint256 totalLiquidatorFees_);

  // function getPlayerCreditUsd(address _player) external view returns (uint256 playerCredit_);

  // function returnNetResult() external view returns (uint256 netResult_, bool isPositive_);

  // function returnPayoutBufferLeft() external view returns (uint256 payoutBufferLeft_);

  // function checkPayoutAllowedUsd(uint256 _amountPayout) external view returns (bool isAllowed_);

  // function getPlayerEscrowUsd(address _player) external view returns (uint256 playerEscrow_);

  // function getPlayerCreditAsset(
  //   address _player,
  //   address _asset
  // ) external view returns (uint256 playerCreditAsset_);

  function decrementMaxLossesBuffer(uint256 _maxLossesDecrease) external;

  function processLiquidationClose(
    bytes32 _positionKey,
    address _player,
    address _liquidator,
    uint256 _marginAmount,
    uint256 _interestFunding,
    uint256 _assetPrice,
    int256 _INT_pnlUsd,
    bool _isPositionValueNegative,
    address _marginAsset
  ) external returns (ClosedPositionInfo memory closedPosition_);
 
  function claimLiquidationFees() external;

  function closePosition(
    bytes32 _positionKey,
    PositionInfo memory _position,
    address _caller,
    uint256 _assetPrice,
    uint256 _interestFunding,
    int256 _pnlUsd,
    bool _isPositionValueNegative
  )
    external
    returns (
      ClosedPositionInfo memory closedPosition_,
      uint256 marginAssetAmount_,
      uint256 feesPaid_
    );

  function returnVaultReserveInAsset() external view returns (uint256 vaultReserve_);

  function transferInMarginUsdc(address _player, uint256 _marginAmount) external;

  event PositionClosedInProfit(
    bytes32 positionKey,
    uint256 payOutAmount,
    uint256 closeFeeProtocolUsd
  );

  event DecrementMaxLosses(uint256 _maxLossesDecrease, uint256 _maxLossesAllowedUsd);

  event MaxLossesAllowedBudgetSpent();

  event PositionClosedInLoss(bytes32 positionKey, uint256 marginAmountLeftUsd);

  event SetLiquidationThreshold(uint256 _liquidationThreshold);

  event IncrementMaxLosses(uint256 _incrementedMaxLosses, uint256 _maxLossesAllowed);

  event SetFeeRatioForFeeCollector(uint256 fundingFeeRatioForFeeCollector_);

  event SetDegenProfitForFeeCollector(uint256 degenProfitForFeeCollector_);

  event DegenProfitsAndLossesProcessed(
    uint256 totalRealizedProfits_,
    uint256 totalRealizedLosses_,
    uint256 forVault_,
    uint256 forFeeCollector_,
    uint256 maxLossesAllowedUsd_
  );

  event PositionLiquidated(
    bytes32 positionKey,
    uint256 marginAmount,
    uint256 protocolFee,
    uint256 liquidatorFee,
    uint256 badDebt,
    bool isInterestLiquidation
  );

  event AllTotalsCleared(
    uint256 totalTheoreticalBadDebt_,
    uint256 totalCloseFeeProtocolPartition_,
    uint256 totalFundingRatePartition_
  );

  event SetMaxLiquidationFee(uint256 _maxLiquidationFee);
  event SetMinLiquidationFee(uint256 _minLiquidationFee);
  event ClaimLiquidationFees(uint256 amountClaimed);
  event PlayerCreditClaimed(address indexed player_, uint256 amount_);
  event NoCreditToClaim(address indexed player_);
  event InsufficientBuffer(address indexed player_, uint256 amount_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * NOTE a DEGEN contract is specifically deployed for a single targetMarketToken. So you have a different contract for ETH as for WBTC!
 * @notice struct submitted by the player, contains all the information needed to open a position
 * @param player address of the user opening the position
 * @param timestampCreated timestamp when the order was created
 * @param positionLeverage amount of leverage to use for the position
 * @param wagerAmount amount of margin/wager to use for the position, this is in the asset of the contract or in USDC
 * @param minOpenPrice minimum price to open the position
 * @param maxOpenPrice maximum price to open the position
 * @param timestampExpired timestamp when the order expires
 * @param positionKey key of the position, only populated if the order was executed
 * @param isOpened true if the position is opened, false if it is not
 * @param isLong true if the user is betting on the price going up, if false the user is betting on the price going down
 * @param isCancelled true if the order was cancelled, false if it was not
 */
struct OrderInfo {
  address player;
  address marginAsset;
  uint32 timestampCreated;
  uint16 positionLeverage;
  uint96 wagerAmount; // could be in USDC or the asset depending on marginInStables
  uint96 minOpenPrice;
  uint96 maxOpenPrice;
  uint32 timestampExpired;
  bool isOpened;
  bool isLong;
  bool isCancelled;
}

/**
 * @param isLong true if the user is betting on the price going up, if false the user is betting on the price going down
 * @param isOpen true if the position is opened, false if it is not
 * @param player address of the user opening the position
 * @param orderIndex index of the OrderInfo struct in the orders mapping
 * @param timestampOpened timestamp when the position was opened
 * @param priceOpened price when the position was opened
 * @param fundingRateOpen funding rate when the position was opened
 * @param positionSizeUsd size of the position, this is marginAmount * leverage
 * @param marginAmountOnOpenNet amount of margin used to open the position, this is in the asset of the contract - note probably will be removed
 * @param marginAmountUsd amount of margin used to open the position, this is in USDC
 * @param maxPositionProfitUsd maximum profit of the position set at the time of opening
 */
struct PositionInfo {
  bool isLong;
  bool isOpen;
  address marginAsset;
  address player;
  uint32 timestampOpened;
  uint96 priceOpened;
  uint96 positionSizeUsd; // in the asset (ETH or BTC)
  uint32 fundingRateOpen;
  uint32 orderIndex;
  uint96 marginAmountUsd; // amount of margin in USD
  uint96 maxPositionProfitUsd;
  uint96 positionSizeInTargetAsset;
}

/**
 * @notice struct containing all the information of a position when it is closed
 * @param player address of the user opening the position
 * @param isLiquidated address of the liquidator, 0x0 if the position was not liquidated
 * @param timestampClosed timestamp when the position was closed
 * @param priceClosed price when the position was closed
 * @param totalFundingRatePaidUsd total funding rate paid for the position
 * @param closeFeeProtocolUsd fee paid to close a profitable position
 * @param totalPayoutUsd total payout of the position in USD, this is the marginAmount + pnl, even if the user is paid out in the asset this is denominated in USD
 */
struct ClosedPositionInfo {
  address player;
  address liquidatorAddress;
  address marginAsset;
  bool pnlIsNegative;
  uint32 timestampClosed;
  uint96 priceClosed;
  uint96 totalFundingRatePaidUsd;
  uint96 closeFeeProtocolUsd;
  uint96 liquidationFeePaidUsd;
  uint256 totalPayoutUsd;
  int256 pnlUsd;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IDegenBase {
  function router() external view returns (address);

  function pythAssetId() external view returns (bytes32);

  function targetMarketToken() external view returns (address);

  function maxPercentageOfVault() external view returns (uint256);

  function liquidationThreshold() external view returns (uint256);

  function maxLeverage() external view returns (uint256);

  function minLeverage() external view returns (uint256);

  function fundingRateTimeBuffer() external view returns (uint256);

  function setLiquidationThreshold(uint256 _liquidationThreshold) external;

  function minimumPositionDuration() external view returns (uint256);

  function getFundingRate(bool _isLong) external view returns (uint256 _fundingRate);

  function totalLongExposureInTargetAsset() external view returns (uint256);

  function totalShortExposureInTargetAsset() external view returns (uint256);

  function openPositionAllowed() external view returns (bool);

  function openOrderAllowed() external view returns (bool);

  function closePositionAllowed() external view returns (bool);

  function setOpenOrderAllowed(bool _openOrderAllowed) external;

  function setClosePositionAllowed(bool _closePositionAllowed) external;

  function setOpenPositionAllowed(bool _openPositionAllowed) external;

  // function setMinMarginAmountUsd(uint256 _minPositionSizeUsd) external;

  // Events

  // event SetMinMarginAmountUsd(uint256 minPositionSizeUsd_);

  // event SetMaxPostionSizeUsd(uint256 maxPositionSize_);

  event SetMaxExposureForAsset(uint256 maxExposureForAsset_);

  event SetFundingRateFactor(uint256 fundingRateFactor_);

  event SetMinimumFundingRate(uint256 minimumFundingRate_);
  
  event SetMaxFundingRate(uint256 maxFundingRate_);

  event SetClosePositionAllowed(bool _closePositionAllowed);

  event SetOpenPositionAllowed(bool _openPositionAllowed);

  event SetOpenOrderAllowed(bool _openOrderAllowed);

  event SetRouterAddress(address _routerAddress);

  event SetMinimumPositionDuration(uint256 minimumPositionDuration);

  event SetFundingRateTimeBuffer(uint256 fundingRateTimeBuffer);

  event SetMaxLeverage(uint256 maxLeverage);

  event SetMinLeverage(uint256 minLeverage);

  event SetMaxPercentageOfVault(uint256 maxPercentageOfVault);

  event SetLiquidationThreshold(uint256 liquidationThreshold);

  event SetFundingFeePeriod(uint256 fundingFeePeriod);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
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
pragma solidity 0.8.17;
import "./DegenStructs.sol";

interface IDegenPoolManagerSettings {

  function degenGameContract() external view returns (address);

  function setDegenGameController(
    address _degenGameController,
    bool _isDegenGameController
  ) external;

  function isDegenGameController(address _degenGameController) external view returns (bool);

  event DegenGameContractSet(address indexed degenGameContract);
  event DegenGameControllerSet(address indexed degenGameController, bool isDegenGameController);

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}