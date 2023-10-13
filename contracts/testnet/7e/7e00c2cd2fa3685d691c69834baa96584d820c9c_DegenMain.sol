// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IDegenMain.sol";
import "./interfaces/DegenStructs.sol";
import "./DegenBase.sol";

/**
 * @title DegenMain
 * @author balding-ghost
 * @notice Main contract for the Degen game. It is the core contract that handles all the open orders, active/open positions and closed positions. It is the contract all other contracts interact with. The contract is designed to be called (and itself calls) only trusted contracts. Users can call the contract directly, but none of the functions writing to storage or state are available for non trusted entities. It is the idea that users call the contract via the router contract or the reader contract.
 */
contract DegenMain is IDegenMain, DegenBase {
  using EnumerableSet for EnumerableSet.Bytes32Set;
  using EnumerableSet for EnumerableSet.UintSet;

  // incrementing order index
  uint256 internal orderCount;

  /**
   * DegenMain contract - storage layout
   *
   * Data storage of the DegenMain contract
   * EnumerableSet mappings contain the keys or indexes of trades in that particular state
   * openOrdersIndexes_: indexes of all open orders (not yet executed trades)
   * openPositionsKeys_: keys of all open positions (executed trades, in the market)
   * closedPositionsKeys_: keys of all closed positions (executed trades, not in the market)
   * NOTE: A trade can only be in 1 of the 3 states at a time
   *
   * Regular mappings contain the data of a trade
   * orders(orderIndex): data of all open orders
   * positions(positionKey): data of all open positions
   * closedPositions(positionKey): data of all closed positions
   * A single trade will have data in all 3 mappings at some point in time, if a trade goes to a different state the data in these mappings is not deleted. This is done to keep a history of all trades.
   *
   * Main LifeCycle of a user positon (open, exeute, close/liquidate)
   * -> user submits a trade configuration, this data is stored in the OrderInfo struct.
   * -> as the trade is not yet executed in the market it is an 'openOrder' and it is stored in the openOrdersIndexes_ mapping
   * -> if a user executes the order, the order is removed from the openOrdersIndexes_ mapping and the position is added to the openPositionsKeys_ mapping
   * -> the position is now an 'openPosition' and the positionKey is stored in the openPositionsKeys_ mapping
   * -> the data of the position is stored in the PositionInfo struct
   * -> if a user closes the position, the position is removed from the openPositionsKeys_ mapping and added to the closedPositionsKeys_ mapping
   * -> the position is now a 'closedPosition' and the positionKey is stored in the closedPositionsKeys_ mapping
   * -> the data of the position is stored in the ClosedPositionInfo struct
   * -> end of the cycle for this scenario
   *
   * Alternative LifeCycle of a user position (open, cancel)
   * -> user submits a trade configuration, this data is stored in the OrderInfo struct.
   * -> as the trade is not yet executed in the market it is an 'openOrder' and it is stored in the openOrdersIndexes_ mapping
   * -> if a user cancels the order, the order is removed from the openOrdersIndexes_ mapping
   */

  // array/mapping with indexes of all open orders
  EnumerableSet.UintSet internal openOrdersIndexes_;

  // array/mapping with keys of all open positions
  EnumerableSet.Bytes32Set internal openPositionsKeys_;

  // array/mapping with keys of all closed positions
  EnumerableSet.Bytes32Set internal closedPositionsKeys_;

  // positionKey => PositionInfo
  mapping(bytes32 => PositionInfo) public positions;

  // positionKey => ClosedPositionInfo
  mapping(bytes32 => ClosedPositionInfo) public closedPositions;

  // orderIndex => OrderInfo
  mapping(uint256 => OrderInfo) public orders;

  constructor(
    address _targetToken,
    uint256 _decimals,
    address _poolManager,
    bytes32 _pythAssetId,
    address _stableAddress,
    uint256 _stableDecimals
  )
    DegenBase(_targetToken, _decimals, _poolManager, _pythAssetId, _stableAddress, _stableDecimals)
  {}

  /**
   * @notice external function that submits an order by a user
   * @dev a order submission alone will not execute the order, it will only make them executable by the user or a keeper.
   * @param _order order info submitted by the user
   * @return _orderIndex_ index of the order that is submitted
   */
  function submitOrder(OrderInfo memory _order) external onlyRouter returns (uint256 _orderIndex_) {
    _orderIndex_ = _submitOrder(_order);
  }

  /**
   * @notice external function that cancels an order
   * @dev advised that this function is called via the router
   * @dev an order can only be cancelled if it is not active or not already cancelled
   * @param _orderIndex_ index of the active order
   * @param _caller address that is requesting the cancel (only the owner can cancel)
   * @return wagerReturned_ amount of margin that is returned to the user
   */
  function cancelOrder(
    uint256 _orderIndex_,
    address _caller
  ) external onlyRouter returns (uint256 wagerReturned_) {
    wagerReturned_ = _cancelOrder(_orderIndex_, _caller);
  }

  function cancelOrderPoolManager(
    uint256 _orderIndex_,
    address _caller
  ) external onlyPoolManagerController returns (uint256 wagerReturned_) {
    wagerReturned_ = _cancelOrder(_orderIndex_, _caller);
  }

  /**
   * @notice internal function that executes an order
   * @dev advised that this function is called via the router
   * @dev an order can only be executed if it is active and not already opened
   * @param _orderIndex_ index of the order
   * @param _assetPrice price of the asset at the time of execution
   * @param _marginAmountUsdc position size of the open position in usdc
   * @return positionKey_ key of the position that was opened
   */
  function executeOrder(
    uint256 _orderIndex_,
    uint256 _assetPrice,
    uint256 _marginAmountUsdc
  ) external onlyRouter returns (bytes32 positionKey_) {
    positionKey_ = _executeOrder(_orderIndex_, _assetPrice, _marginAmountUsdc);
  }

  /**
   * @notice internal function that liquidates a position
   * @dev advised that this function is called via the router
   * @dev a position can only be liquidated if it is active and not already closed
   * @param _positionKey key of the position
   * @param _caller address that is requesting the liquidation (only the owner can liquidate)
   * @param _assetPrice price of the asset at the time of liquidation
   */
  function liquidatePosition(
    bytes32 _positionKey,
    address _caller,
    uint256 _assetPrice
  ) external onlyRouter {
    require(openPositionsKeys_.contains(_positionKey), "Degen: position not found");
    PositionInfo memory position_ = positions[_positionKey];
    require(position_.player != _caller, "Degen: cannot liquidate own position");
    require(position_.isOpen, "Degen: position already closed");

    (
      int256 INT_pnlUsd_,
      bool isPositionValueNegative_,
      uint256 interestAccruedUsd_
    ) = _calculatePnlAndInterestUsd(
        position_.marginAmountUsd,
        position_.positionSizeUsd,
        position_.priceOpened,
        _assetPrice,
        position_.fundingRateOpen,
        position_.timestampOpened,
        block.timestamp,
        fundingRateTimeBuffer,
        position_.isLong
      );

    bool isRegularLiquidation = (INT_pnlUsd_ < 0) &&
      uint256(-1 * INT_pnlUsd_) >= _calculateEffectiveMargin(position_.marginAmountUsd);

    if (isRegularLiquidation || isPositionValueNegative_) {
      // position is liquidatable the negative pnl is larger or equal to the effective margin
      require(!closedPositionsKeys_.contains(_positionKey), "Degen: position already closed");
      ClosedPositionInfo memory closedPosition_ = poolManager.processLiquidationClose(
        _positionKey,
        position_.player,
        _caller, // is the liquidator
        position_.marginAmountUsd,
        interestAccruedUsd_,
        _assetPrice,
        INT_pnlUsd_,
        isPositionValueNegative_,
        position_.marginAsset
      );
      _decreaseOpenInterest(position_.isLong, position_.positionSizeInTargetAsset);
      positions[_positionKey].isOpen = false;
      closedPositions[_positionKey] = closedPosition_;
      openPositionsKeys_.remove(_positionKey);
      closedPositionsKeys_.add(_positionKey);

      // 3rd field is true if the position was liquidated by funding interest
      emit PositionLiquidated(_positionKey, closedPosition_, isPositionValueNegative_);
    } else {
      revert("Degen: position not liquidatable - threshold not reached");
    }
  }

  /**
   * @notice internal function that closes a position
   * @dev advised that this function is called via the router
   * @dev a position can only be closed if the position is open
   * @param _positionKey key of the position
   * @param _caller address that is requesting the close (only the owner can close)
   * @param _assetPrice price of the asset at the time of closing
   */
  function closePosition(
    bytes32 _positionKey,
    address _caller,
    uint256 _assetPrice
  ) external onlyRouter {
    require(openPositionsKeys_.contains(_positionKey), "Degen: position not found");
    PositionInfo memory position_ = positions[_positionKey];
    require(position_.player == _caller, "Degen: not position owner");
    require(position_.isOpen, "Degen: position already closed");
    position_.isOpen = false;

    // manual close is only allowed if the position has been open for the minimum time configured
    if (!_isUserPositionCloseAllowed(position_.timestampOpened)) {
      revert("Degen: position close not allowed too early");
    }

    require(!closedPositionsKeys_.contains(_positionKey), "Degen: position already closed");

    (
      int256 INT_pnlUsd_,
      bool _isPositionValueNegative,
      uint256 interestAccruedUsd_
    ) = _calculatePnlAndInterestUsd(
        position_.marginAmountUsd,
        position_.positionSizeUsd,
        position_.priceOpened,
        _assetPrice,
        position_.fundingRateOpen,
        position_.timestampOpened,
        block.timestamp,
        fundingRateTimeBuffer,
        position_.isLong
      );

    _decreaseOpenInterest(position_.isLong, position_.positionSizeInTargetAsset);

    (
      ClosedPositionInfo memory closedPosition_,
      uint256 marginAssetAmount_,
      uint256 feesPaid_
    ) = poolManager.closePosition(
        _positionKey,
        position_,
        _caller,
        _assetPrice,
        interestAccruedUsd_,
        INT_pnlUsd_,
        _isPositionValueNegative
      );

    closedPositions[_positionKey] = closedPosition_;
    positions[_positionKey] = position_;
    openPositionsKeys_.remove(_positionKey);
    closedPositionsKeys_.add(_positionKey);

    emit PositionClosed(_positionKey, closedPosition_, marginAssetAmount_, feesPaid_);
  }

  // View Functions

  /**
   * @notice view function that calculates the amount of funding rate interest that has accrued
   * @dev advised that this function is called via the router
   * @param _positionKey key of the position to check funding interest amount for
   * @param _timestampAt timestamp to check funding interest amount for
   */
  function calculateInterestPosition(
    bytes32 _positionKey,
    uint256 _timestampAt
  ) public view returns (uint256 interestAccruedUsd_) {
    PositionInfo memory position_ = positions[_positionKey];
    interestAccruedUsd_ = _calculateAmountOfFundingRateInterestUsd(
      position_.timestampOpened,
      _timestampAt,
      position_.fundingRateOpen,
      position_.positionSizeUsd,
      fundingRateTimeBuffer
    );
  }

  /**
   * @notice view function taht returns the P/L of a position (including interest)
   * @dev advised that this function is called via the router
   * @param _positionKey key of the position
   * @param _assetPrice asset price to calculate the P/L against
   * @param _timestampAt timestamp to calculate the P/L against
   * @return INT_pnlUsd_ P/L of the position in the asset, this is always a positive number, if pnl is negative isPnlPositive_ will be false
   */
  function netPnlOfPosition(
    bytes32 _positionKey,
    uint256 _assetPrice,
    uint256 _timestampAt
  ) external view returns (int256 INT_pnlUsd_) {
    // check if position exists
    require(openPositionsKeys_.contains(_positionKey), "Degen: position not found");
    PositionInfo memory position_ = positions[_positionKey];
    // calculate pnl
    (INT_pnlUsd_, , ) = _calculatePnlAndInterestUsd(
      position_.marginAmountUsd,
      position_.positionSizeUsd,
      position_.priceOpened,
      _assetPrice,
      position_.fundingRateOpen,
      position_.timestampOpened,
      _timestampAt,
      fundingRateTimeBuffer,
      position_.isLong
    );
  }

  /**
   * @notice view function that returns if a position is liquidatable at a certain time and asset price
   * @dev advised that this function is called via the router
   * @param _positionKey key of the position to check if liquidatable
   * @param _assetPrice asset price to check if liquidatable at
   * @param _timestampAt timestamp to check if liquidatable at
   */
  function isPositionLiquidatableByKeyAtTime(
    bytes32 _positionKey,
    uint256 _assetPrice,
    uint256 _timestampAt
  ) external view returns (bool isPositionLiquidatable_) {
    // check if position exists
    require(openPositionsKeys_.contains(_positionKey), "Degen: position not found");
    isPositionLiquidatable_ = _isPositionLiquidatableByKey(_positionKey, _assetPrice, _timestampAt);
  }

  /**
   * @notice view function that returns the info of an open order
   * @dev note that an order is a non-market executed trade configuration
   * @param _orderIndex index of the order
   */
  function returnOrderInfo(
    uint256 _orderIndex
  ) external view returns (OrderInfo memory orderInfo_) {
    orderInfo_ = orders[_orderIndex];
    require(orderInfo_.player != address(0), "Degen: order not found");
    return orderInfo_;
  }

  /**
   * @notice view function that returns the info of an open position
   * @dev note that a position is a market executed trade
   * @param _positionKey key of the position
   */
  function returnOpenPositionInfo(
    bytes32 _positionKey
  ) external view returns (PositionInfo memory positionInfo_) {
    require(openPositionsKeys_.contains(_positionKey), "Degen: position not found");
    positionInfo_ = positions[_positionKey];
  }

  /**
   * @notice view function that returns the info of a closed position
   * @dev note that a closed position is a market executed trade that was closed (either by user or liquidated)
   * @param _positionKey key of the position
   */
  function returnClosedPositionInfo(
    bytes32 _positionKey
  ) external view returns (ClosedPositionInfo memory closedPositionInfo_) {
    require(closedPositionsKeys_.contains(_positionKey), "Degen: position not found");
    closedPositionInfo_ = closedPositions[_positionKey];
  }

  /**
   * @notice view function that returns the amount of open orders (unexecuted configured trades)
   */
  function amountOpenOrders() external view returns (uint256 openOrdersCount_) {
    openOrdersCount_ = openOrdersIndexes_.length();
  }

  /**
   * @notice view function that returns the amount of open positions (executed trades)
   */
  function amountOpenPositions() external view returns (uint256 openPositionsCount_) {
    openPositionsCount_ = openPositionsKeys_.length();
  }

  /**
   * @notice view function that returns if a position is open
   * @param _positionKey key of the position
   */
  function isOpenPosition(bytes32 _positionKey) external view returns (bool isPositionOpen_) {
    isPositionOpen_ = openPositionsKeys_.contains(_positionKey);
  }

  /**
   * @notice view function that returns if an order is open
   * @param _orderIndex index of the order
   */
  function isOpenOrder(uint256 _orderIndex) external view returns (bool isOpenOrder_) {
    isOpenOrder_ = openOrdersIndexes_.contains(_orderIndex);
  }

  /**
   * @notice function returns if a position is closed
   * @param _positionKey key of the position
   */
  function isClosedPosition(bytes32 _positionKey) external view returns (bool isClosedPosition_) {
    // check if the position was ever open to begin with
    require(positions[_positionKey].player != address(0), "Degen: position never opened");
    isClosedPosition_ = closedPositionsKeys_.contains(_positionKey);
  }

  function getOpenPositionsInfo() external view returns (PositionInfo[] memory _positions) {
    _positions = new PositionInfo[](openPositionsKeys_.length());
    for (uint256 i = 0; i < openPositionsKeys_.length(); i++) {
      _positions[i] = positions[openPositionsKeys_.at(i)];
    }
  }

  function getOpenPositionKeys() external view returns (bytes32[] memory _positionKeys) {
    _positionKeys = new bytes32[](openPositionsKeys_.length());
    for (uint256 i = 0; i < openPositionsKeys_.length(); i++) {
      _positionKeys[i] = openPositionsKeys_.at(i);
    }
  }

  function getAllOpenOrdersInfo() external view returns (OrderInfo[] memory _orders) {
    _orders = new OrderInfo[](openOrdersIndexes_.length());
    for (uint256 i = 0; i < openOrdersIndexes_.length(); i++) {
      _orders[i] = orders[openOrdersIndexes_.at(i)];
    }
  }

  function getAllOpenOrderIndexes() external view returns (uint256[] memory _orderIndexes) {
    _orderIndexes = new uint256[](openOrdersIndexes_.length());
    for (uint256 i = 0; i < openOrdersIndexes_.length(); i++) {
      _orderIndexes[i] = openOrdersIndexes_.at(i);
    }
  }

  // function that returns all the closed positions
  function getAllClosedPositionsInfo()
    external
    view
    returns (ClosedPositionInfo[] memory _positions)
  {
    _positions = new ClosedPositionInfo[](closedPositionsKeys_.length());
    for (uint256 i = 0; i < closedPositionsKeys_.length(); i++) {
      _positions[i] = closedPositions[closedPositionsKeys_.at(i)];
    }
  }

  function getPositionKeyOfOrderIndex(
    uint256 _orderIndex
  ) external view returns (bytes32 positionKey_) {
    OrderInfo memory order_ = orders[_orderIndex];
    require(order_.player != address(0), "Degen: order not found");
    positionKey_ = _getPositionKey(order_.player, order_.isLong, _orderIndex);
  }

  /**
   * @notice function returns all the position keys of positions that are liquidatable
   * @dev it is advised that this function is called by the router
   * @param _assetPrice the price to check liquidatable positions against
   * @param _timestampAt the time to check liquidatable positions against
   */
  function getAllLiquidatablePositions(
    uint256 _assetPrice,
    uint256 _timestampAt
  ) external view returns (bytes32[] memory _liquidatablePositions) {
    bytes32[] memory tempPositions_ = new bytes32[](openPositionsKeys_.length());
    uint256 count_ = 0;
    for (uint256 i = 0; i < openPositionsKeys_.length(); i++) {
      bytes32 positionKey_ = openPositionsKeys_.at(i);
      bool isLiquidatable_ = _isPositionLiquidatableByKey(positionKey_, _assetPrice, _timestampAt);
      if (isLiquidatable_) {
        tempPositions_[count_] = positionKey_;
        count_++;
      }
    }

    // Create a new array with the correct size
    _liquidatablePositions = new bytes32[](count_);
    for (uint256 i = 0; i < count_; i++) {
      _liquidatablePositions[i] = tempPositions_[i];
    }
    return _liquidatablePositions;
  }

  // Internal functions
  function _getPositionKey(
    address _account,
    bool _isLong,
    uint256 _posId
  ) internal view returns (bytes32 positionKey_) {
    unchecked {
      positionKey_ = keccak256(
        abi.encodePacked(_account, address(targetMarketToken), _isLong, _posId)
      );
    }
  }

  /**
   * @notice internal view returns the amount of funding rate accured
   * @param _timeStampOpened timestamp when the position was opened
   * @param _currentTimeStamp current timestamp
   * @param _fundingRate funding rate of the position
   * @param _positionSizeUsd size of the position
   */
  function _calculateAmountOfFundingRateInterestUsd(
    uint256 _timeStampOpened,
    uint256 _currentTimeStamp,
    uint256 _fundingRate,
    uint256 _positionSizeUsd,
    uint256 _fundingRateTimeBuffer
  ) internal view returns (uint256 interestAccruedUsd_) {
    if (_currentTimeStamp >= _timeStampOpened + _fundingRateTimeBuffer) {
      uint256 feeApplicableCount_ = (_currentTimeStamp - _timeStampOpened) / fundingFeePeriod;
      uint256 fundingFeePercent_ = (_fundingRate * feeApplicableCount_) / fundingFeePeriod;
      if (fundingFeePercent_ > BASIS_POINTS) {
        fundingFeePercent_ = BASIS_POINTS;
      }
      interestAccruedUsd_ = (_positionSizeUsd * fundingFeePercent_) / BASIS_POINTS;
    } else {
      interestAccruedUsd_ = 0;
    }
  }

  function _isPositionLiquidatableByKey(
    bytes32 _positionKey,
    uint256 _assetPrice,
    uint256 _timestampAt
  ) internal view returns (bool isPositionLiquidatable_) {
    PositionInfo memory position_ = positions[_positionKey];
    isPositionLiquidatable_ = _isPositionLiquidable(
      position_.marginAmountUsd,
      position_.positionSizeUsd,
      position_.priceOpened,
      _assetPrice,
      position_.fundingRateOpen,
      position_.timestampOpened,
      _timestampAt,
      fundingRateTimeBuffer,
      position_.isLong
    );
  }

  /**
   * @notice internal view returns true if the position is liquidatable, false if it is not
   * @param _marginAmount margin amount when the position was opened in usd, scaled 1e18
   * @param _positionSizeUsd size of the position scaled 1e18
   * @param _positionPriceOnOpen price when the position was opened scaled 1e18
   * @param _priceCurrently current price scaled 1e18
   * @param _fundingRate funding rate of the position
   * @param _timeOpened timestamp when the position was opened
   * @param _timeCurrently current timestamp
   * @param _fundingRateTimeBuffer time buffer for the funding rate
   * @param _isLong true if the user is betting on the price going up, if false the user is betting on the price going down
   * @return isLiquidatble_ true if the position is liquidatable, false if it is not
   */
  function _isPositionLiquidable(
    uint256 _marginAmount,
    uint256 _positionSizeUsd,
    uint256 _positionPriceOnOpen,
    uint256 _priceCurrently,
    uint256 _fundingRate,
    uint256 _timeOpened,
    uint256 _timeCurrently,
    uint256 _fundingRateTimeBuffer,
    bool _isLong
  ) internal view returns (bool isLiquidatble_) {
    (int256 INT_pnlUsd_, bool _isPositionValueNegative, ) = _calculatePnlAndInterestUsd(
      _marginAmount,
      _positionSizeUsd,
      _positionPriceOnOpen,
      _priceCurrently,
      _fundingRate,
      _timeOpened,
      _timeCurrently,
      _fundingRateTimeBuffer,
      _isLong
    );

    bool isRegularLiquidation_ = (INT_pnlUsd_ < 0) &&
      uint256(-1 * INT_pnlUsd_) >= _calculateEffectiveMargin(_marginAmount);

    if (isRegularLiquidation_) {
      return true;
    }
    if (_isPositionValueNegative) {
      return true;
    }
  }

  function _calculateEffectiveMargin(
    uint256 _marginAmount
  ) internal view returns (uint256 effectiveMargin_) {
    unchecked {
      effectiveMargin_ = (_marginAmount * liquidationThreshold) / BASIS_POINTS;
    }
  }

  /**
   * @notice internal function that calculates the PnL and Interest
   * @param _positionSizeUsd size of the position
   * @param _positionPriceOnOpen price when the position was opened
   * @param _priceCurrently price at which  the P/L is calculated
   * @param _fundingRate funding rate the P/L is calculated with
   * @param _timeOpened timestamp the P/L is calculated from
   * @param _timeCurrently timestamp to use as current time
   * @param _fundingRateTimeBuffer time buffer for the funding rate
   * @param _isLong true if the user is betting on the price going up, if false the user is betting on the price going down
   * @return INT_pnlUsd_ P/L of the position in the asset, this could be a positive or negative number
   * @return _isPositionValueNegative true if the position is liquidated, false if it is not
   * @return interestAccruedUsd_ accrued interest on the position

   */
  function _calculatePnlAndInterestUsd(
    uint256 _marginAmount,
    uint256 _positionSizeUsd,
    uint256 _positionPriceOnOpen,
    uint256 _priceCurrently,
    uint256 _fundingRate,
    uint256 _timeOpened,
    uint256 _timeCurrently,
    uint256 _fundingRateTimeBuffer,
    bool _isLong
  )
    internal
    view
    returns (int256 INT_pnlUsd_, bool _isPositionValueNegative, uint256 interestAccruedUsd_)
  {
    interestAccruedUsd_ = _calculateAmountOfFundingRateInterestUsd(
      _timeOpened,
      _timeCurrently,
      _fundingRate,
      _positionSizeUsd,
      _fundingRateTimeBuffer
    );

    INT_pnlUsd_ = _calculatePnl(_positionSizeUsd, _positionPriceOnOpen, _priceCurrently, _isLong);

    // Calculate result margin amount
    if (int256(_marginAmount) + INT_pnlUsd_ <= int256(interestAccruedUsd_)) {
      // Margin + pnl is smaller than interest, so the margin becomes 0 or negative, so the net position value becomes negative
      _isPositionValueNegative = true;
    }
  }

  /**
   * @notice internal view returns the P/L of a position
   * @param _positionSizeUsd size of the position scaled 1e18
   * @param _positionPriceOnOpen price when the position was opened in usd, scaled 1e18
   * @param _priceCurrently current price scaled 1e18
   * @param _isLong true if the user is betting on the price going up, if false the user is betting on the price going down
   * @return INT_pnlUsd_ P/L of the position in the asset, this could be a positive or negative number, scaled 1e18 so pnl +$90 is 90 * 1e18
   */
  function _calculatePnl(
    uint256 _positionSizeUsd,
    uint256 _positionPriceOnOpen,
    uint256 _priceCurrently,
    bool _isLong // true if the user is betting on the price going up, if false the user is betting on the price going down (short)§
  ) internal pure returns (int256 INT_pnlUsd_) {
    uint256 _amountOfAssets = (_positionSizeUsd * PRICE_PRECISION) / _positionPriceOnOpen;
    int256 priceDiff = int256(_priceCurrently) - int256(_positionPriceOnOpen);
    if (_isLong) {
      INT_pnlUsd_ = (int256(_amountOfAssets) * priceDiff) / int256(PRICE_PRECISION);
    } else {
      INT_pnlUsd_ = (int256(_amountOfAssets) * -1 * priceDiff) / int256(PRICE_PRECISION);
    }
  }

  /**
   * @notice internal function that submits an order
   * @dev a submitted order is not yet active, it needs to be executed
   * @param _order order to be submitted
   * @return _orderIndex_ index of the order that is submitted
   */
  function _submitOrder(OrderInfo memory _order) internal returns (uint256 _orderIndex_) {
    _checkOpenOrderAllowed();
    // check if leverage is within bounds
    require(_order.positionLeverage >= minLeverage, "Degen: leverage too low");
    require(_order.positionLeverage <= maxLeverage, "Degen: leverage too high");

    uint256 orderIndex_ = orderCount;
    _order.timestampCreated = uint32(block.timestamp);
    orders[orderIndex_] = _order;
    openOrdersIndexes_.add(orderIndex_);
    unchecked {
      orderCount++;
    }
    emit OrderSubmitted(orderIndex_, _order);
    return orderIndex_;
  }

  /**
   * @notice internal function that cancels an unopened order
   * @dev canceling is only possible if the order is not active or not already cancelled
   * @param _orderIndex_ index of the active order
   * @param _caller address that is requesting the cancel (only the owner can cancel)
   * @return wagerReturned_ amount of margin that is returned to the user (could be usd or asset)
   */
  function _cancelOrder(
    uint256 _orderIndex_,
    address _caller
  ) internal returns (uint256 wagerReturned_) {
    OrderInfo memory order_ = orders[_orderIndex_];
    require(order_.player == _caller, "Degen: only owner or admin can cancel order");
    require(!order_.isOpened, "Degen: can't cancel active order");
    require(openOrdersIndexes_.contains(_orderIndex_), "Degen: order not found");
    // check if the order is already cancelled
    require(!order_.isCancelled, "Degen: order already cancelled");
    wagerReturned_ = order_.wagerAmount;
    order_.isCancelled = true;
    orders[_orderIndex_] = order_;
    openOrdersIndexes_.remove(_orderIndex_);
    emit OrderCancelled(_orderIndex_, order_);
    return wagerReturned_;
  }

  function _executeOrder(
    uint256 _orderIndex_,
    uint256 _assetPrice,
    uint256 _marginAmountUsdc
  ) internal returns (bytes32 positionKey_) {
    // check if executing orders is enabled
    _checkOpenPositionAllowed();
    // fetch order data
    OrderInfo memory order_ = orders[_orderIndex_];
    poolManager.transferInMarginUsdc(order_.player, _marginAmountUsdc);

    uint256 positionSizeUsd_;
    uint256 marginValueUsd_;

    (positionSizeUsd_, marginValueUsd_) = _checkPositionSizeWagerInUsdc(
      order_.positionLeverage,
      _marginAmountUsdc
    );

    // check order size and if it is not expired
    require(order_.timestampExpired >= block.timestamp, "Degen: position expired");
    // check if the order is open
    require(openOrdersIndexes_.contains(_orderIndex_), "Degen: order not found");
    openOrdersIndexes_.remove(_orderIndex_);
    require(!order_.isOpened, "Degen: position already opened");
    require(_assetPrice >= order_.minOpenPrice, "Degen: price outside of min limits");
    require(_assetPrice <= order_.maxOpenPrice, "Degen: price outside of max limits");

    orders[_orderIndex_].isOpened = true;

    // compute position key
    positionKey_ = _getPositionKey(order_.player, order_.isLong, _orderIndex_);
    require(!openPositionsKeys_.contains(positionKey_), "Degen: position already opened");

    uint256 positionSizeInTargetAsset_ = (positionSizeUsd_ * 10 ** decimalsToken) / _assetPrice;
    openPositionsKeys_.add(positionKey_);

    PositionInfo memory position_;
    position_.isLong = order_.isLong;
    position_.player = order_.player;
    position_.marginAsset = order_.marginAsset;
    position_.orderIndex = uint32(_orderIndex_);
    position_.timestampOpened = uint32(block.timestamp);
    position_.priceOpened = uint96(_assetPrice);
    position_.positionSizeUsd = uint96(positionSizeUsd_);
    position_.marginAmountUsd = uint96(marginValueUsd_);
    _increaseOpenInterest(order_.isLong, positionSizeInTargetAsset_);
    position_.positionSizeInTargetAsset = uint96(positionSizeInTargetAsset_);
    position_.fundingRateOpen = uint32(_updateFundingRate(order_.isLong));
    position_.maxPositionProfitUsd = uint96(_maxPositionProfitUsd());
    position_.isOpen = true;
    positions[positionKey_] = position_;

    emit OrderExecuted(_orderIndex_, positionKey_, position_);
    return positionKey_;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
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
 * ```solidity
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

import "./interfaces/IDegenBase.sol";
import "./interfaces/IDegenPoolManager.sol";
import "./interfaces/DegenStructs.sol";

/**
 * @title DegenBase
 * @author balding-ghost
 * @notice The base contract for the Degen game containing all the configuration and internal functions that are used by the DegenMain contract.
 */
contract DegenBase is IDegenBase {
  uint256 public constant VAULT_SCALING_INCREASE_FOR_USD = 1e12;
  uint256 internal constant PRICE_PRECISION = 1e18;
  uint256 public constant BASIS_POINTS = 1e6;

  // immutable configurations
  // pyth id of the targetMarketToken
  bytes32 public immutable pythAssetId;

  // address of the target market token, so the token that is used to open positions against, echt contract only tracks one asset
  address public immutable targetMarketToken;

  // address of usdc/stablecooin
  address public immutable stableTokenAddress;

  // decimals of the stable token
  uint256 public immutable stableTokenDecimals;

  // pool manager contract, handles position closing and payouts/payins
  IDegenPoolManager public immutable poolManager;

  uint256 public immutable decimalsToken;

  address public router;

  // max percentage of the vault the player is allowed to win (scaled by 1e6)
  uint256 public maxPercentageOfVault;

  // liquidation threshold is the threshold at which a position can be liquidated (margin level of the position), if this value is 90 * 1e4 (so 90%) the position can be liquidated when the margin level is below 90%. So with $100 margin, liquidation will start with a pnl of -$90
  uint256 public liquidationThreshold;

  // maximum allowed leverage, this is unscaled so 100x = 100
  uint256 public maxLeverage;

  // minimum allowed leverage, this is unscaled so 100x = 100
  uint256 public minLeverage;

  // funding rate buffer, this is the amount of seconds a position doesn't have to pay funding rate after it is opened
  uint256 public fundingRateTimeBuffer;

  // amount of seconds a position at the minimum needs to be open before it can be closed by a user
  uint256 public minimumPositionDuration;

  // max position size in usd (so the total amount of usd that can be used for a position) this is leverage * margin amount
  uint256 public constant maxPositionSizeUsd = 1e6 * 1e18; // 1m usd

  // min amount of margin in usd that the user needs to have to open a position
  uint256 public constant minMarginAmountUsd = 1e18; // 1 usd

  // percentage that is added to the funding rate (so the bottom/minium) regardless how skewed the open interest is this percentage will be added
  uint256 public minimumFundingRate;

  uint256 public maxFundingRate;

  // configurable value that determines how much the funding rate is affected by the open interest
  uint256 public fundingRateFactor;

  // max exposure for the asset, this is the total amount of long and short positions that can be open at the same time
  uint256 public maxExposureForAsset;

  uint256 public fundingFeePeriod = 60; // 1 minute defualt

  // if opening/executing new positions is allowed
  bool public openPositionAllowed;

  // if opening new orders is allowed
  bool public openOrderAllowed;

  // if closing positions is allowed
  bool public closePositionAllowed;

  // total amount of long positions open (so total long exposure)
  uint256 public totalLongExposureInTargetAsset;

  // total amount of short positions open (so total short exposure)
  uint256 public totalShortExposureInTargetAsset;

  constructor(
    address _targetToken,
    uint256 _decimals,
    address _poolManager,
    bytes32 _pythAssetId,
    address _stableToken,
    uint256 _stableDecimals
  ) {
    poolManager = IDegenPoolManager(_poolManager);
    decimalsToken = _decimals;
    stableTokenAddress = _stableToken;
    stableTokenDecimals = _stableDecimals;
    pythAssetId = _pythAssetId;
    targetMarketToken = _targetToken;
  }

  modifier onlyPoolManagerController() {
    require(poolManager.isDegenGameController(msg.sender), "Degen: not controller");
    _;
  }

  modifier onlyRouter() {
    require(msg.sender == router, "Degen: not router");
    _;
  }

  // configuration functions

  function setRouterAddress(address _routerAddress) external onlyPoolManagerController {
    router = _routerAddress;
    emit SetRouterAddress(_routerAddress);
  }

  function setFundingFeePeriod(uint256 _fundingFeePeriod) external onlyPoolManagerController {
    require(_fundingFeePeriod > 0, "Degen: funding fee period too low");
    fundingFeePeriod = _fundingFeePeriod;
    emit SetFundingFeePeriod(_fundingFeePeriod);
  }

  /**
   * @notice set the max percentage of the vault the player is allowed to win (scaled by 1e6)
   * @param _maxPercentageOfVault the max percentage of the vault the player is allowed to win (scaled by 1e6)
   */
  function setMaxPercentageOfVaultReserves(
    uint256 _maxPercentageOfVault
  ) external onlyPoolManagerController {
    maxPercentageOfVault = _maxPercentageOfVault;
    emit SetMaxPercentageOfVault(_maxPercentageOfVault);
  }

  /**
   * @notice set the minimum amount of time a position needs to be open before it can be closed
   * @param _minimumPositionDuration amount of seconds a position at the minimum needs to be open before it can be closed by a user
   */
  function setMinimumPositionDuration(
    uint256 _minimumPositionDuration
  ) external onlyPoolManagerController {
    minimumPositionDuration = _minimumPositionDuration;
    emit SetMinimumPositionDuration(_minimumPositionDuration);
  }

  /**
   * @notice set the funding rate time buffer, the amount of seconds a position doesn't have to pay funding rate after it is opened
   * @param _fundingRateTimeBuffer the new funding rate time buffer
   */
  function setFundingRateTimeBuffer(
    uint256 _fundingRateTimeBuffer
  ) external onlyPoolManagerController {
    fundingRateTimeBuffer = _fundingRateTimeBuffer;
    emit SetFundingRateTimeBuffer(_fundingRateTimeBuffer);
  }

  /**
   * @notice set the max leverage
   * @dev no scaling is needed, max 2x leverage is 2 etc
   * @param _maxLeverage the new max leverage
   */
  function setMaxLeverage(uint256 _maxLeverage) external onlyPoolManagerController {
    maxLeverage = _maxLeverage;
    emit SetMaxLeverage(_maxLeverage);
  }

  /**
   * @notice set the minimum leverage
   * @dev no scaling is needed, min 2x leverage is 2 etc
   * @param _minLeverage the new minimum leverage
   */
  function setMinLeverage(uint256 _minLeverage) external onlyPoolManagerController {
    minLeverage = _minLeverage;
    emit SetMinLeverage(_minLeverage);
  }

  /**
   * @notice set the liquidation threshold, scaled 1e6
   * @param _liquidationThreshold the new liquidation threshold, scaled 1e6
   */
  function setLiquidationThreshold(uint256 _liquidationThreshold) external {
    require(msg.sender == address(poolManager), "Degen: only pool manager");
    liquidationThreshold = _liquidationThreshold;
    emit SetLiquidationThreshold(_liquidationThreshold);
  }

  /**
   * @notice set whether opening positions is allowed
   * @param _openPositionAllowed boolean value indicating whether opening positions is allowed
   */
  function setOpenPositionAllowed(bool _openPositionAllowed) external onlyPoolManagerController {
    openPositionAllowed = _openPositionAllowed;
    emit SetOpenPositionAllowed(_openPositionAllowed);
  }

  /**
   * @notice set whether opening orders is allowed
   * @param _openOrderAllowed boolean value indicating whether opening orders is allowed
   */
  function setOpenOrderAllowed(bool _openOrderAllowed) external onlyPoolManagerController {
    openOrderAllowed = _openOrderAllowed;
    emit SetOpenOrderAllowed(_openOrderAllowed);
  }

  /**
   * @notice set whether closing positions is allowed
   * @param _closePositionAllowed boolean value indicating whether closing positions is allowed
   */
  function setClosePositionAllowed(bool _closePositionAllowed) external onlyPoolManagerController {
    closePositionAllowed = _closePositionAllowed;
    emit SetClosePositionAllowed(_closePositionAllowed);
  }

  /**
   * @notice set the funding rate factor
   * @param _fundingRateFactor the new funding rate factor
   */
  function setFundingRateFactor(uint256 _fundingRateFactor) external onlyPoolManagerController {
    fundingRateFactor = _fundingRateFactor;
    emit SetFundingRateFactor(_fundingRateFactor);
  }

  /**
   * @notice set the minimum funding rate
   * @param _minimumFundingRate the new minimum funding rate, scaled 1e6
   */
  function setMinimumFundingRate(uint256 _minimumFundingRate) external onlyPoolManagerController {
    require(_minimumFundingRate <= BASIS_POINTS, "Degen: funding rate too high");
    minimumFundingRate = _minimumFundingRate;
    emit SetMinimumFundingRate(_minimumFundingRate);
  }
  /**
   * @notice set the max funding rate
   * @param _maxFundingRate the new max funding rate, scaled 1e6
   */
  function setMaxFundingRate(uint256 _maxFundingRate) external onlyPoolManagerController {
    require(_maxFundingRate <= BASIS_POINTS, "Degen: max funding rate too high");
    maxFundingRate = _maxFundingRate;
    emit SetMaxFundingRate(_maxFundingRate);
  }
  /**
   * @notice set the max exposure for the asset
   * @param _maxExposureForAsset the new max exposure for the asset
   */
  function setMaxExposureForAsset(uint256 _maxExposureForAsset) external onlyPoolManagerController {
    maxExposureForAsset = _maxExposureForAsset;
    emit SetMaxExposureForAsset(_maxExposureForAsset);
  }

  function getFundingRate(bool _isLong) external view returns (uint256 _fundingRate) {
    _fundingRate = _updateFundingRate(_isLong);
  }

  // internal functions

  function _checkOpenOrderAllowed() internal view {
    require(openOrderAllowed, "Degen: open order not allowed");
  }

  function _checkOpenPositionAllowed() internal view {
    require(openPositionAllowed, "Degen: open position not allowed");
  }

  function _checkClosePositionAllowed() internal view {
    require(closePositionAllowed, "Degen: close position not allowed");
  }

  /**
   * @notice check if the position size is allowed
   * @param _leverage  amount of leverage to use for the position
   * @param _marginAmountAsset the wager amount held in the router in the asset of the contract
   * @param _currentPriceAsset the current price of the asset scaled 1e18
   */
  function _checkPositionSizeAsset(
    uint16 _leverage,
    uint256 _marginAmountAsset,
    uint256 _currentPriceAsset
  ) internal view returns (uint256 positionSizeUsd_, uint256 valueMarginUsd_) {
    unchecked {
      valueMarginUsd_ = (_marginAmountAsset * _currentPriceAsset) / (10 ** decimalsToken);
      positionSizeUsd_ = (valueMarginUsd_ * _leverage);
      require(positionSizeUsd_ <= maxPositionSizeUsd, "Degen: position size too high asset");
      require(valueMarginUsd_ >= minMarginAmountUsd, "Degen: position size too low asset");
    }
    return (positionSizeUsd_, valueMarginUsd_);
  }

  /**
   * @notice check if the position size is within bounds
   * @param _leverage  amount of leverage to use for the position
   * @param _wagerAmountUsdc the wager amount in USDC held in the router
   */
  function _checkPositionSizeWagerInUsdc(
    uint16 _leverage,
    uint256 _wagerAmountUsdc
  ) internal pure returns (uint256 positionSizeUsd_, uint256 marginValueUsd_) {

    unchecked {
      // convert the usdc wager (1e6) to usd value scaled 1e18
      marginValueUsd_ = _wagerAmountUsdc * VAULT_SCALING_INCREASE_FOR_USD;
      positionSizeUsd_ = (marginValueUsd_ * _leverage);
      require((positionSizeUsd_) <= maxPositionSizeUsd, "Degen: position size too high usd");
      require((marginValueUsd_) >= minMarginAmountUsd, "Degen: position size too low usd");
    }
    return (positionSizeUsd_, marginValueUsd_);
  }

  /**
   * @notice internal function that calculates the max position profit in the usd for a new position
   */
  function _maxPositionProfitUsd() internal view returns (uint256 _maxPositionProfitInAsset) {
    unchecked {
      _maxPositionProfitInAsset =
        (poolManager.returnVaultReserveInAsset() * maxPercentageOfVault) /
        BASIS_POINTS;
    }
  }

  /**
   * @notice interal function that checks if the position size is allowed
   * @param _positionOpenTimestamp the timestamp the position is being opened in
   * @return isAllowed_ boolean indicating if closing any position is allowed
   */
  function _isUserPositionCloseAllowed(
    uint256 _positionOpenTimestamp
  ) internal view returns (bool isAllowed_) {
    // check if the position is open long enough
    unchecked {
      isAllowed_ = block.timestamp >= (_positionOpenTimestamp + minimumPositionDuration);
    }
  }

  /**
   * @notice internal function that increases the open interest (for when a new position is opened)
   * @param _isLong if the new position is long
   * @param _positionSizeInTargetAsset the position size in target asset(ETH)
   */
  function _increaseOpenInterest(bool _isLong, uint256 _positionSizeInTargetAsset) internal {
    unchecked {
      if (_isLong) {
        // increase the total long exposure
        totalLongExposureInTargetAsset += _positionSizeInTargetAsset;
        require(totalLongExposureInTargetAsset <= maxExposureForAsset, "Degen: max exposure reached");
      } else {
        // increase the total short exposure
        totalShortExposureInTargetAsset += _positionSizeInTargetAsset;
        require(totalShortExposureInTargetAsset <= maxExposureForAsset, "Degen: max exposure reached");
      }
    }
  }

  /**
   * @notice internal function that decreases the open interest (for when a position is closed)
   * @param _isLong if the  position that is being closed is long or short
   * @param _positionSizeInTargetAsset the position size in target asset that is being closed
   */
  function _decreaseOpenInterest(bool _isLong, uint256 _positionSizeInTargetAsset) internal {
    unchecked {
      if (_isLong) {
        // decrease the total long exposure
        totalLongExposureInTargetAsset -= _positionSizeInTargetAsset;
      } else {
        // decrease the total short exposure
        totalShortExposureInTargetAsset -= _positionSizeInTargetAsset;
      }
    }
  }

  /**
   * open interest storage and configuration
   * The funding rate is the rate that is paid by the longs to the shorts (or vice versa) every second. The funding rate is calculated based on the open interest of the contract. If the open interest is skewed to the longs, the funding rate will be lower for the long and higher for the shorts.
   * Unlike other perpetual contracts, the Degen contract does not have funding rates that can go negative. Meaning that the funding rate is always positive.
   */
  function _updateFundingRate(bool _isLong) internal view returns (uint256 _fundingRate) {
    // calculate the skweness, if the skewness is positive the contract is long, if the skewness is negative the shorts is short
    int256 totalShort_ = int256(totalShortExposureInTargetAsset);
    int256 totalLong_ = int256(totalLongExposureInTargetAsset);
    int256 skewness_;
    unchecked {
      skewness_ = ((totalLong_ - totalShort_) * 1e6) / (totalLong_ + totalShort_);
    }

    if (_isLong) {
      // the user is opening a long position
      if (skewness_ < 0) {
        // skweness is negative, so the contract is short, this means that the funding rate is the minimum because the new position helps to balance the short exposure
        _fundingRate = minimumFundingRate;
      } else {
        // skewness is positive, so the contract is long, this means that the funding rate is the minimum plus the skewness with a factor, since the position is making the contract more long
        unchecked {
          _fundingRate =
            minimumFundingRate +
            ((uint256(skewness_) * fundingRateFactor) / BASIS_POINTS);
        }
      }
    } else {
      // the user is opening a short position
      if (skewness_ > 0) {
        // skweness is positive, so the contract is long, this means that the funding rate is the minimum because the new position helps to balance the long exposure
        _fundingRate = minimumFundingRate;
      } else {
        // skewness is negative, so the contract is short, this means that the funding rate is the minimum plus the skewness with a factor, since the position is making the contract more short
        unchecked {
          _fundingRate =
            minimumFundingRate +
            ((uint256(-skewness_) * fundingRateFactor) / BASIS_POINTS);
        }
      }
    }

    if(_fundingRate > maxFundingRate) {
      _fundingRate = maxFundingRate;
    }

    if(_fundingRate < minimumFundingRate) {
      _fundingRate = minimumFundingRate;
    }
  }
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

  function maxLossesAllowedUsdTotal() external view returns (uint256 payoutBufferAmount_);

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