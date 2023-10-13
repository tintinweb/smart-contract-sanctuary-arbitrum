// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IDegenMain.sol";
import "./interfaces/IDegenRouter.sol";
import "./interfaces/IDegenPriceManager.sol";
import "./interfaces/IDegenPoolManager.sol";
import "./interfaces/DegenStructs.sol";
import "../../../interfaces/vault/IVault.sol";
import "../../../interfaces/vault/IReader.sol";
import "../../../interfaces/core/ISwap.sol";

/**
 * @title DegenRouter
 * @author balding-ghost
 * @notice The DegenRouter contract is used to route calls to the DegenMain contract. The router contract is used to make sure that the price is fresh enough to be used for execution. If the price is not fresh enough the router will not execute the order/position (and depending on configuration it might fail).
 */
contract DegenRouter is IDegenRouter, ReentrancyGuard {
  uint256 public constant MAX_LIQUIDATIONS = 5;
  IDegenMain public immutable degenMain;
  IDegenPriceManager public immutable priceManager;
  IDegenPoolManager public immutable poolManager;
  IVault public immutable vault;
  IReader public immutable reader;
  bytes32 public immutable pythAssetId;
  IERC20 public immutable targetToken;
  IERC20 public immutable stableToken;
  address public immutable controller;
  uint256 public immutable minimumFreshness = 1; // at least 1 second to prevent same block reverts

  ISwap public swap;

  // if true the router will revert if the price is not fresh enough to be used for execution (so it is not executable)
  bool public failOnFailedExecution;

  // amount of seconds that the price needs to be fresh enough to be used for execution
  uint256 public priceFreshnessThreshold;

  // mapping to store allowed wager assets
  mapping(address => bool) public allowedWagerAssets;

  mapping(uint256 => uint256) public wagerInOpenOrdersUsdc;

  mapping(uint256 => uint256) internal amountWagerForOrder;

  mapping(uint256 => address) internal orderToWagerAsset;

  constructor(
    address _degenMain,
    address _priceManager,
    address _poolManager,
    address _controller,
    address _vault,
    address _reader,
    address _swap
  ) {
    degenMain = IDegenMain(_degenMain);
    priceManager = IDegenPriceManager(_priceManager);
    poolManager = IDegenPoolManager(_poolManager);
    targetToken = IERC20(priceManager.tokenAddress());
    stableToken = IERC20(priceManager.stableTokenAddress());
    pythAssetId = priceManager.pythAssetId();
    controller = _controller;
    vault = IVault(_vault);
    reader = IReader(_reader);
    swap = ISwap(_swap);
  }

  /**
   * @notice submits an order to the degenMain contract, so that it becomes available for execution
   * @dev note that the order is not executed by this function
   * @dev note that if the price is not fresh or executable, this function will not fail
   * @param _positionLeverage leverage of the position (multiplier), not scaled at all so 500x leverage is 500
   * @param _wagerAmount amount of margin/wager to use for the position, this is in the asset of the contract or in usdc
   * @param _minOpenPrice minimum price to open the position, note if set to 0 it means that there is no minimum price
   * @param _maxOpenPrice maximum price to open the position, note if set to 0 it means that there is no maximum price
   * @param _timestampExpired timestamp when the order expires
   * @param _isLong bool true if the user is betting on the price going up, if false the user is betting on the price going down
   * @return orderIndex_ uint256 index of the order in the degenMain contract
   */
  function submitOrderManual(
    uint16 _positionLeverage,
    uint96 _wagerAmount,
    uint96 _minOpenPrice,
    uint96 _maxOpenPrice,
    uint32 _timestampExpired,
    address _marginAsset,
    bool _isLong
  ) external nonReentrant returns (uint256 orderIndex_) {
    orderIndex_ = _submitOrder(
      _positionLeverage,
      _wagerAmount,
      _minOpenPrice,
      _maxOpenPrice,
      _timestampExpired,
      _marginAsset,
      _isLong
    );
  }

  function liquidateLiquidatablePositions(
    bytes calldata _updateData
  ) external nonReentrant returns (uint256 amountOfLiquidations_) {
    bytes32[] memory _liquidatablePositions = degenMain.getAllLiquidatablePositions(
      _getExecutionPrice(_updateData),
      block.timestamp
    );
    uint256 count_;

    (uint256 executionPrice_, bool isExecutable_) = _getExecutionPriceAndExecutableCheck(_updateData);

    for (uint256 i = 0; i < _liquidatablePositions.length; i++) {
      bytes32 _positionKey = _liquidatablePositions[i];
      _liquidatePosition(_positionKey, executionPrice_, isExecutable_);
      count_++;
      if (count_ >= MAX_LIQUIDATIONS) {
        return count_;
      }
    }
    return count_;
  }

  function liquidateLiquidatablePositionsOnChainPrice()
    external
    nonReentrant
    returns (uint256 amountOfLiquidations_)
  {
    (uint256 assetPrice_, uint256 lastUpdateTimestamp_) = priceManager.returnPriceAndUpdate();

    require(
      _checkPriceFreshness(block.timestamp - lastUpdateTimestamp_),
      "DegenRouter: price update too old update first"
    );

    bytes32[] memory _liquidatablePositions = degenMain.getAllLiquidatablePositions(
      assetPrice_,
      block.timestamp
    );

    uint256 count_;

    for (uint256 i = 0; i < _liquidatablePositions.length; i++) {
      bytes32 _positionKey = _liquidatablePositions[i];
      degenMain.liquidatePosition(_positionKey, msg.sender, assetPrice_);
      emit PositionLiquidated(_positionKey, msg.sender, assetPrice_);
      count_++;
      if (count_ >= MAX_LIQUIDATIONS) {
        return count_;
      }
    }
    return count_;
  }

  /**
   * @notice liquidates a single liquidatable position
   * @param _updateData encoded pyth PriceFeed struct with verifiable pyth price information
   * @return positionKey_ bytes32 key of the position that was liquidated
   * @return executionPrice_ the price of the asset as determined by the priceManager
   * @return isSuccessful_ bool indicating if the liquidation was successful
   */
  function liquidateSingleLiquidatablePosition(
    bytes calldata _updateData
  )
    external payable
    nonReentrant
    returns (bytes32 positionKey_, uint256 executionPrice_, bool isSuccessful_)
  {
    bytes32[] memory _liquidatablePositions = degenMain.getAllLiquidatablePositions(
      _getExecutionPrice(_updateData),
      block.timestamp
    );

    if (_liquidatablePositions.length == 0) {
      return (positionKey_, executionPrice_, false);
    }

    positionKey_ = _liquidatablePositions[0];

    bool isExecutable_;
    (executionPrice_, isExecutable_) = _getExecutionPriceAndExecutableCheck(_updateData);
    (isSuccessful_) = _liquidatePosition(positionKey_, executionPrice_, isExecutable_);
  }

  /**
   * @notice cancels an open order
   * @param _orderIndex uint256 index of the order in the degenMain contract
   * @return marginAmount_ uint256 amount of margin that was used for the order
   */
  function cancelOpenOrder(
    uint256 _orderIndex
  ) external nonReentrant returns (uint256 marginAmount_) {
    uint256 wagerInOpenOrdersUsdc_ = wagerInOpenOrdersUsdc[_orderIndex];
    if (wagerInOpenOrdersUsdc_ > 0) {
      stableToken.transfer(msg.sender, wagerInOpenOrdersUsdc_);
      wagerInOpenOrdersUsdc[_orderIndex] = 0;
    } else {
      address wagerAsset_ = orderToWagerAsset[_orderIndex];
      uint256 wagerAmountReturn_ = amountWagerForOrder[_orderIndex];
      IERC20(wagerAsset_).transfer(msg.sender, wagerAmountReturn_);
      unchecked {
        delete amountWagerForOrder[_orderIndex];
        delete orderToWagerAsset[_orderIndex];
      }
    }
    marginAmount_ = degenMain.cancelOrder(_orderIndex, msg.sender);
    emit OpenOrderCancelled(_orderIndex, msg.sender, marginAmount_);
    return marginAmount_;
  }

  function executeOpenOrder(
    bytes calldata _updateData,
    uint256 _orderIndex
  )
    external
    nonReentrant
    returns (bytes32 positionKey_, uint256 executionPrice_, bool _successFull)
  {
    address user_ = degenMain.returnOrderInfo(_orderIndex).player;

    bool isExecutable_;
    (executionPrice_, isExecutable_) = _getExecutionPriceAndExecutableCheck(_updateData);

    (positionKey_, _successFull) = _executeOpenOrder(
      _orderIndex,
      user_,
      executionPrice_,
      isExecutable_
    );
  }

  function executeOpenOrderBatch(
    bytes calldata _updateData,
    uint256[] calldata _orderIndexes
  )
    external
    payable
    nonReentrant
    returns (
      bytes32[] memory positionKeys_,
      uint256[] memory executionPrices_,
      bool[] memory _successFull
    )
  {
    positionKeys_ = new bytes32[](_orderIndexes.length);
    executionPrices_ = new uint256[](_orderIndexes.length);
    _successFull = new bool[](_orderIndexes.length);

    (uint256 executionPrice_, bool isExecutable_) = _getExecutionPriceAndExecutableCheck(
      _updateData
    );

    for (uint256 i = 0; i < _orderIndexes.length; i++) {
      address user_ = degenMain.returnOrderInfo(_orderIndexes[i]).player;
      (positionKeys_[i], _successFull[i]) = _executeOpenOrder(
        _orderIndexes[i],
        user_,
        executionPrice_,
        isExecutable_
      );
      executionPrices_[i] = executionPrice_;
    }
  }

  /**
   * @notice closes an open position
   * @param _updateData encoded pyth PriceFeed struct with verifieable pyth price information
   * @param _positionKey bytes32 key of the position to be closed
   * @return executionPrice_ the price of the asset as determined by the priceManager
   * @return _successFull bool indicating if the close was successful
   */
  function closeOpenPosition(
    bytes calldata _updateData,
    bytes32 _positionKey
  ) external nonReentrant returns (uint256 executionPrice_, bool _successFull) {
    (executionPrice_, _successFull) = _closeOpenPosition(_updateData, _positionKey);
  }

  /**
   * @notice liquidates a position, if the position is profitable the liquidator will receive a portion of the profit
   * @param _updateData encoded pyth PriceFeed struct with verifieable pyth price information
   * @param _positionKey bytes32 key of the position to be liquidated
   * @return executionPrice_ the price of the asset as determined by the priceManager
   * @return _successFull bool indicating if the liquidation was successful
   */
  function liquidatePosition(
    bytes calldata _updateData,
    bytes32 _positionKey
  ) external nonReentrant returns (uint256 executionPrice_, bool _successFull) {
    bool isExecutable_;
    (executionPrice_, isExecutable_) = _getExecutionPriceAndExecutableCheck(_updateData);
    (_successFull) = _liquidatePosition(_positionKey, executionPrice_, isExecutable_);
  }

  // config functions

  function setSwap(address _swap) external {
    require(msg.sender == controller, "DegenRouter: INVALID_SENDER");
    swap = ISwap(_swap);
  }

  function setAllowedWagerAsset(address _asset, bool _allowed, uint256) external {
    require(msg.sender == controller, "DegenRouter: INVALID_SENDER");
    allowedWagerAssets[_asset] = _allowed;
    emit AllowedWagerSet(_asset, _allowed);
  }

  function setFailOnFailedExecution(bool _failOnFailedExecution) external {
    require(msg.sender == controller, "DegenRouter: INVALID_SENDER");
    failOnFailedExecution = _failOnFailedExecution;
    emit FailedOnExecutionSet(_failOnFailedExecution);
  }

  function setPriceFreshnessThreshold(uint256 _priceFreshnessThreshold) external {
    require(msg.sender == controller, "DegenRouter: INVALID_SENDER");
    require(_priceFreshnessThreshold >= minimumFreshness, "DegenRouter: price freshness too low");
    priceFreshnessThreshold = _priceFreshnessThreshold;
    emit PriceFreshnessThresholdSet(_priceFreshnessThreshold);
  }

  // internal functions

  function _checkWagerAsset(address _wagerAsset) internal view {
    require(allowedWagerAssets[_wagerAsset], "DegenRouter: INVALID_WAGER_ASSET");
  }

  /**
   * @notice internal function that submits an order to the degenMain contract
   * @param _positionLeverage amount of leverage to use for the position, not scaled at all so 500x leverage is 500
   * @param _wagerAmount amount of margin/wager to use for the position, this is in the asset of the contract or in usdc depending on margin in stables
   * @param _minOpenPrice minimum price to open the position, note if set to 0 it means that there is no minimum price
   * @param _maxOpenPrice maximum price to open the position, note if set to 0 it means that there is no maximum price
   * @param _timestampExpired timestamp when the order expires
   * @param _isLong bool true if the user is betting on the price going up, if false the user is betting on the price going down
   * @return orderIndex_ uint256 index of the order in the degenMain contract
   */
  function _submitOrder(
    uint16 _positionLeverage,
    uint96 _wagerAmount,
    uint96 _minOpenPrice,
    uint96 _maxOpenPrice,
    uint32 _timestampExpired,
    address _wagerAsset,
    bool _isLong
  ) internal returns (uint256 orderIndex_) {
    _checkWagerAsset(_wagerAsset);

    require(_minOpenPrice <= _maxOpenPrice, "DegenRouter: min price too high");
    require(_timestampExpired > block.timestamp, "DegenRouter: expiry too soon");
    // set _maxOpenPrice that if it is 0, it is set to the max uint96, if it is non-zero it is set to the input
    _maxOpenPrice = (_maxOpenPrice == 0) ? type(uint96).max : _maxOpenPrice;
    OrderInfo memory order_;
    order_.player = msg.sender;
    order_.positionLeverage = _positionLeverage;
    order_.wagerAmount = _wagerAmount;
    order_.minOpenPrice = _minOpenPrice;
    order_.maxOpenPrice = _maxOpenPrice;
    order_.timestampExpired = _timestampExpired;
    order_.marginAsset = _wagerAsset;
    order_.isOpened = false;
    order_.isLong = _isLong;

    orderIndex_ = degenMain.submitOrder(order_);

    if (_wagerAsset == address(stableToken)) {
      // margin is in stablecoins, transfer the stablecoins to the router contract
      // only when the order is executed the stablecoins will be transferred to the poolManager as scrow
      stableToken.transferFrom(msg.sender, address(this), _wagerAmount);
      unchecked {
        // store the amount of usdc in the order (so note this is scaled 1e6)
        wagerInOpenOrdersUsdc[orderIndex_] = _wagerAmount;
      }
    } else {
      IERC20(_wagerAsset).transferFrom(msg.sender, address(this), _wagerAmount);
      // margin is in the asset of the contract, transfer the asset to the router contract
      // only when the order is executed the asset will be swapped to usdc and transferred to the poolManager as escrow
      unchecked {
        orderToWagerAsset[orderIndex_] = _wagerAsset;
        amountWagerForOrder[orderIndex_] = _wagerAmount; // note this can actually be = not += since overriding is not possible since order cannot be changed
      }
    }

    emit OpenOrderSubmitted(orderIndex_, msg.sender, _wagerAmount);

    return orderIndex_;
  }

  /**
   * @notice internal function that executes an open order that is publically executable
   * @param _orderIndex uint256 index of the order in the degenMain contract
   * @param _user address of the user  the order is executed on behalf of
   * @return positionKey_ bytes32 key of the position that was opened
   * @param _executionPrice the price of the asset as determined by the priceManager
   * @return _successFull bool indicating if the execution was successful
   */
  function _executeOpenOrder(
    uint256 _orderIndex,
    address _user,
    uint256 _executionPrice,
    bool _isExecutable
  ) internal returns (bytes32 positionKey_, bool _successFull) {
    if (_isExecutable) {
      uint256 stableAmountForMargin_;
      uint256 feesPaid_;
      stableAmountForMargin_ = wagerInOpenOrdersUsdc[_orderIndex];
      if (stableAmountForMargin_ > 0) {
        // margin is in stablecoins, so we can just use it, we delete it from the mapping so it cannot be used again
        wagerInOpenOrdersUsdc[_orderIndex] = 0;
      } else {
        address wagerAsset_ = orderToWagerAsset[_orderIndex];
        uint256 amountToSwap_ = amountWagerForOrder[_orderIndex];
        // margin is in the asset of the contract, so we need to swap it to stablecoins first with the
        IERC20(wagerAsset_).transfer(address(swap), amountToSwap_);
        (stableAmountForMargin_, feesPaid_) = swap.swapTokens(
          amountToSwap_,
          wagerAsset_,
          address(stableToken),
          address(this)
        );
        unchecked {
          delete amountWagerForOrder[_orderIndex];
          delete orderToWagerAsset[_orderIndex];
        }
      }
      // transfer the stablecoins to the poolManager
      stableToken.transfer(address(poolManager), stableAmountForMargin_);
      // in the executeOrder function in degenMain we call poolManager to register the transferred in margin in stablecoins
      positionKey_ = degenMain.executeOrder(_orderIndex, _executionPrice, stableAmountForMargin_);
      emit OpenOrderExecuted(
        positionKey_,
        _user,
        _executionPrice,
        stableAmountForMargin_,
        feesPaid_
      );
      return (positionKey_, true);
    } else {
      if (failOnFailedExecution) {
        revert("DegenRouter: price update too old");
      }
      _executionPrice = 0;
      emit OpenOrderNotExecuted(positionKey_, _user, _executionPrice);
      return (positionKey_, false);
    }
  }

  /**
   * @notice internal function that closes an open position
   * @param _updateData encoded pyth PriceFeed struct with verifieable pyth price information
   * @param _positionKey bytes32 key of the position to be closed
   * @return executionPrice_ the price of the asset as determined by the priceManager
   * @return _successFull bool indicating if the close was successful
   */
  function _closeOpenPosition(
    bytes calldata _updateData,
    bytes32 _positionKey
  ) internal returns (uint256 executionPrice_, bool _successFull) {
    bool isExecutable_;
    (executionPrice_, isExecutable_) = _getExecutionPriceAndExecutableCheck(_updateData);
    if (isExecutable_) {
      degenMain.closePosition(_positionKey, msg.sender, executionPrice_);
      emit PositionClosed(_positionKey, msg.sender, executionPrice_);
      return (executionPrice_, true);
    } else {
      if (failOnFailedExecution) {
        revert("DegenRouter: price update too old");
      }
      executionPrice_ = 0;
      emit PositionCloseFail(_positionKey, msg.sender, executionPrice_);
      return (executionPrice_, false);
    }
  }

  /**
   * @notice internal function that liquidates a position, if the position is profitable the liquidator will receive a portion of the profit
   * @param _positionKey bytes32 key of the position to be liquidated
   * @param _executionPrice the price of the asset as determined by the priceManager
   * @return _successFull bool indicating if the liquidation was successful
   */
  function _liquidatePosition(
    bytes32 _positionKey,
    uint256 _executionPrice,
    bool _isExecutable
  ) internal returns (bool _successFull) {

    if (_isExecutable) {
      degenMain.liquidatePosition(_positionKey, msg.sender, _executionPrice);
      emit PositionLiquidated(_positionKey, msg.sender, _executionPrice);
      return (true);
    } else {
      if (failOnFailedExecution) {
        revert("DegenRouter: price update too old");
      }
      _executionPrice = 0;
      emit PositionLiquidationFailed(_positionKey, msg.sender, _executionPrice);
      return (false);
    }
  }

  /**
   * @notice internal function that determines if the price update data is recent enough to be used to execute a position/order
   * @param _priceUpdateData bytes sourced from the pyth api feed, that will be used to update the price feed
   * @return executionPrice_ the price of the asset as determined by the priceManager
   * @return isExecutable_ bool indiciating if the executionPrice determined is fresh enough to be used to settle/execute an position/order
   */
  function _getExecutionPriceAndExecutableCheck(
    bytes calldata _priceUpdateData
  ) internal returns (uint256 executionPrice_, bool isExecutable_) {
    uint256 secondsSinceUpdate_;
    (executionPrice_, secondsSinceUpdate_) = priceManager.getLatestAssetPriceAndUpdate(_priceUpdateData);
    isExecutable_ = _checkPriceFreshness(secondsSinceUpdate_);
    return (executionPrice_, isExecutable_);
  }

  function _getExecutionPrice(
    bytes calldata _priceUpdateData
  ) internal returns (uint256 executionPrice_) {
    (executionPrice_, ) = priceManager.getLatestAssetPriceAndUpdate(_priceUpdateData);
  }

  function _checkPriceFreshness(uint256 _ageOfPricePublish) internal view returns (bool isFresh_) {
    isFresh_ = _ageOfPricePublish <= priceFreshnessThreshold;
  }

  // VIEW FUNCTIONS

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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
  ) external view returns (uint256 pnlUsd_, bool isPnlPositive_);

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
    uint256 _pnlUsd,
    address _marginAsset
  ) external returns (ClosedPositionInfo memory closedPosition_);

  function claimLiquidationFees() external;

  function closePosition(
    bytes32 _positionKey,
    PositionInfo memory _position,
    address _caller,
    uint256 _assetPrice,
    uint256 _interestFunding,
    uint256 _pnlUsd,
    bool _isPnlPositive
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
  uint96 totalPayoutUsd;
  uint96 pnlUsd;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

// import "./IVaultUtils.sol";

interface IVault {
  /*==================== Events *====================*/
  event BuyUSDW(
    address account,
    address token,
    uint256 tokenAmount,
    uint256 usdwAmount,
    uint256 feeBasisPoints
  );
  event SellUSDW(
    address account,
    address token,
    uint256 usdwAmount,
    uint256 tokenAmount,
    uint256 feeBasisPoints
  );
  event Swap(
    address account,
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 indexed amountOut,
    uint256 indexed amountOutAfterFees,
    uint256 indexed feeBasisPoints
  );
  event DirectPoolDeposit(address token, uint256 amount);
  error TokenBufferViolation(address tokenAddress);
  error PriceZero();

  event PayinWLP(
    // address of the token sent into the vault
    address tokenInAddress,
    // amount payed in (was in escrow)
    uint256 amountPayin
  );

  event PlayerPayout(
    // address the player receiving the tokens (do we need this? i guess it does not matter to who we send tokens for profit/loss calculations?)
    address recipient,
    // address of the token paid to the player
    address tokenOut,
    // net amount sent to the player (this is NOT the net loss, since it includes the payed in tokens, excludes wagerFee and swapFee!)
    uint256 amountPayoutTotal
  );

  event AmountOutNull();

  event WithdrawAllFees(
    address tokenCollected,
    uint256 swapFeesCollected,
    uint256 wagerFeesCollected,
    uint256 referralFeesCollected
  );

  event RebalancingWithdraw(address tokenWithdrawn, uint256 amountWithdrawn);

  event RebalancingDeposit(address tokenDeposit, uint256 amountDeposit);

  event WagerFeeChanged(uint256 newWagerFee);

  event ReferralDistributionReverted(uint256 registeredTooMuch, uint256 maxVaueAllowed);

  /*==================== Operational Functions *====================*/
  function setPayoutHalted(bool _setting) external;

  function isSwapEnabled() external view returns (bool);

  //   function setVaultUtils(IVaultUtils _vaultUtils) external;

  function setError(uint256 _errorCode, string calldata _error) external;

  function usdw() external view returns (address);

  function feeCollector() external returns (address);

  function hasDynamicFees() external view returns (bool);

  function totalTokenWeights() external view returns (uint256);

  function getTargetUsdwAmount(address _token) external view returns (uint256);

  function inManagerMode() external view returns (bool);

  function isManager(address _account) external view returns (bool);

  function tokenBalances(address _token) external view returns (uint256);

  function setInManagerMode(bool _inManagerMode) external;

  function setManager(address _manager, bool _isManager, bool _isWLPManager) external;

  function setIsSwapEnabled(bool _isSwapEnabled) external;

  function setUsdwAmount(address _token, uint256 _amount) external;

  function setBufferAmount(address _token, uint256 _amount) external;

  function setFees(
    uint256 _taxBasisPoints,
    uint256 _stableTaxBasisPoints,
    uint256 _mintBurnFeeBasisPoints,
    uint256 _swapFeeBasisPoints,
    uint256 _stableSwapFeeBasisPoints,
    uint256 _minimumBurnMintFee,
    bool _hasDynamicFees
  ) external;

  function setTokenConfig(
    address _token,
    uint256 _tokenDecimals,
    uint256 _redemptionBps,
    uint256 _maxUsdwAmount,
    bool _isStable
  ) external;

  function setPriceFeedRouter(address _priceFeed) external;

  function withdrawAllFees(address _token) external returns (uint256, uint256, uint256);

  function directPoolDeposit(address _token) external;

  function deposit(address _tokenIn, address _receiver, bool _swapLess) external returns (uint256);

  function withdraw(address _tokenOut, address _receiverTokenOut) external returns (uint256);

  function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);

  function tokenToUsdMin(
    address _tokenToPrice,
    uint256 _tokenAmount
  ) external view returns (uint256);

  function priceOracleRouter() external view returns (address);

  function taxBasisPoints() external view returns (uint256);

  function stableTaxBasisPoints() external view returns (uint256);

  function mintBurnFeeBasisPoints() external view returns (uint256);

  function swapFeeBasisPoints() external view returns (uint256);

  function stableSwapFeeBasisPoints() external view returns (uint256);

  function minimumBurnMintFee() external view returns (uint256);

  function allWhitelistedTokensLength() external view returns (uint256);

  function allWhitelistedTokens(uint256) external view returns (address);

  function stableTokens(address _token) external view returns (bool);

  function swapFeeReserves(address _token) external view returns (uint256);

  function tokenDecimals(address _token) external view returns (uint256);

  function tokenWeights(address _token) external view returns (uint256);

  function poolAmounts(address _token) external view returns (uint256);

  function bufferAmounts(address _token) external view returns (uint256);

  function usdwAmounts(address _token) external view returns (uint256);

  function maxUsdwAmounts(address _token) external view returns (uint256);

  function getRedemptionAmount(address _token, uint256 _usdwAmount) external view returns (uint256);

  function getMaxPrice(address _token) external view returns (uint256);

  function getMinPrice(address _token) external view returns (uint256);

  function setVaultManagerAddress(address _vaultManagerAddress, bool _setting) external;

  function wagerFeeBasisPoints() external view returns (uint256);

  function setWagerFee(uint256 _wagerFee) external;

  function wagerFeeReserves(address _token) external view returns (uint256);

  function referralReserves(address _token) external view returns (uint256);

  function getReserve() external view returns (uint256);

  function getWlpValue() external view returns (uint256);

  function usdToTokenMin(address _token, uint256 _usdAmount) external view returns (uint256);

  function usdToTokenMax(address _token, uint256 _usdAmount) external view returns (uint256);

  function usdToToken(
    address _token,
    uint256 _usdAmount,
    uint256 _price
  ) external view returns (uint256);

  function returnTotalOutAndIn(
    address token_
  ) external view returns (uint256 totalOutAllTime_, uint256 totalInAllTime_);

  function payout(
    address _wagerToken,
    address _escrowAddress,
    uint256 _escrowAmount,
    address _recipient,
    uint256 _totalAmount
  ) external;

  function payoutNoEscrow(address _wagerAsset, address _recipient, uint256 _totalAmount) external;

  function payin(address _inputToken, address _escrowAddress, uint256 _escrowAmount) external;

  function setAsideReferral(address _token, uint256 _amount) external;

  function payinWagerFee(address _tokenIn) external;

  function payinSwapFee(address _tokenIn) external;

  function payinPoolProfits(address _tokenIn) external;

  function removeAsideReferral(address _token, uint256 _amountRemoveAside) external;

  function setFeeCollector(address _feeCollector) external;

  function upgradeVault(address _newVault, address _token, uint256 _amount, bool _upgrade) external;

  function setCircuitBreakerAmount(address _token, uint256 _amount) external;

  function clearTokenConfig(address _token) external;

  function updateTokenBalance(address _token) external;

  function setCircuitBreakerEnabled(bool _setting) external;

  function setPoolBalance(address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IVault.sol";

// import "../gmx/IVaultPriceFeedGMX.sol";

interface IReader {
  function getFees(
    address _vault,
    address[] memory _tokens
  ) external view returns (uint256[] memory);

  function getWagerFees(
    address _vault,
    address[] memory _tokens
  ) external view returns (uint256[] memory);

  function getSwapFeeBasisPoints(
    IVault _vault,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external view returns (uint256, uint256, uint256);

  function getAmountOut(
    IVault _vault,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external view returns (uint256, uint256);

  function getMaxAmountIn(
    IVault _vault,
    address _tokenIn,
    address _tokenOut
  ) external view returns (uint256);

  //   function getPrices(
  //     IVaultPriceFeedGMX _priceFeed,
  //     address[] memory _tokens
  //   ) external view returns (uint256[] memory);

  function getVaultTokenInfo(
    address _vault,
    address _weth,
    uint256 _usdwAmount,
    address[] memory _tokens
  ) external view returns (uint256[] memory);

  function getFullVaultTokenInfo(
    address _vault,
    address _weth,
    uint256 _usdwAmount,
    address[] memory _tokens
  ) external view returns (uint256[] memory);

  function getFeesForGameSetupFeesUSD(
    address _tokenWager,
    address _tokenWinnings,
    uint256 _amountWager
  ) external view returns (uint256 wagerFeeUsd_, uint256 swapFeeUsd_, uint256 swapFeeBp_);

  function getNetWinningsAmount(
    address _tokenWager,
    address _tokenWinnings,
    uint256 _amountWager,
    uint256 _multiple
  ) external view returns (uint256 amountWon_, uint256 wagerFeeToken_, uint256 swapFeeToken_);

  function getSwapFeePercentageMatrix(
    uint256 _usdValueOfSwapAsset
  ) external view returns (uint256[] memory);

  function adjustForDecimals(
    uint256 _amount,
    address _tokenDiv,
    address _tokenMul
  ) external view returns (uint256 scaledAmount_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISwap {
  function swapTokens(
    uint256 _amountToSwap,
    address _fromAsset,
    address _toAsset,
    address _receiver
  ) external returns (uint256 amountReturned_, uint256 feesPaidInOut_);
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