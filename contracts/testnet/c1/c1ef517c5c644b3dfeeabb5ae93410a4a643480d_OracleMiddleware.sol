// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

abstract contract Owned {
  error Owned_NotOwner();
  error Owned_NotPendingOwner();

  address public owner;
  address public pendingOwner;

  event OwnershipTransferred(
    address indexed _previousOwner,
    address indexed _newOwner
  );

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  modifier onlyOwner() {
    if (msg.sender != owner) revert Owned_NotOwner();
    _;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    // Move _newOwner to pendingOwner
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external {
    // Check
    if (msg.sender != pendingOwner) revert Owned_NotPendingOwner();

    // Log
    emit OwnershipTransferred(owner, pendingOwner);

    // Effect
    owner = pendingOwner;
    delete pendingOwner;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { Owned } from "@hmx/base/Owned.sol";
import { IOracleAdapter } from "./interfaces/IOracleAdapter.sol";
import { IOracleMiddleware } from "./interfaces/IOracleMiddleware.sol";

contract OracleMiddleware is Owned, IOracleMiddleware {
  /**
   * Structs
   */
  struct AssetPriceConfig {
    /// @dev Acceptable price age in second.
    uint32 trustPriceAge;
    /// @dev The acceptable threshold confidence ratio. ex. _confidenceRatio = 0.01 ether means 1%
    uint32 confidenceThresholdE6;
  }

  /**
   * Events
   */
  event LogSetMarketStatus(bytes32 indexed _assetId, uint8 _status);
  event LogSetUpdater(address indexed _account, bool _isActive);
  event LogSetAssetPriceConfig(
    bytes32 indexed _assetId,
    uint32 _oldConfidenceThresholdE6,
    uint32 _newConfidenceThresholdE6,
    uint256 _oldTrustPriceAge,
    uint256 _newTrustPriceAge
  );
  event LogSetPythAdapter(address oldPythAdapter, address newPythAdapter);

  /**
   * States
   */
  IOracleAdapter public pythAdapter;

  // whitelist mapping of market status updater
  mapping(address => bool) public isUpdater;
  mapping(bytes32 => AssetPriceConfig) public assetPriceConfigs;

  // states
  // MarketStatus
  // Note from Pyth doc: Only prices with a value of status=trading should be used. If the status is not trading but is
  // Unknown, Halted or Auction the Pyth price can be an arbitrary value.
  // https://docs.pyth.network/design-overview/account-structure
  //
  // 0 = Undefined, default state since contract init
  // 1 = Inactive, equivalent to `unknown`, `halted`, `auction`, `ignored` from Pyth
  // 2 = Active, equivalent to `trading` from Pyth
  // assetId => marketStatus
  mapping(bytes32 => uint8) public marketStatus;

  constructor(IOracleAdapter _pythAdapter) {
    pythAdapter = _pythAdapter;
  }

  /**
   * Modifiers
   */

  modifier onlyUpdater() {
    if (!isUpdater[msg.sender]) {
      revert IOracleMiddleware_OnlyUpdater();
    }
    _;
  }

  /// @notice Return the latest price and last update of the given asset id.
  /// @dev It is expected that the downstream contract should return the price in USD with 30 decimals.
  /// @dev The currency of the price that will be quoted with depends on asset id. For example, we can have two BTC price but quoted differently.
  ///      In that case, we can define two different asset ids as BTC/USD, BTC/EUR.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  function getLatestPrice(bytes32 _assetId, bool _isMax) external view returns (uint256 _price, uint256 _lastUpdate) {
    (_price, , _lastUpdate) = _getLatestPrice(_assetId, _isMax);

    return (_price, _lastUpdate);
  }

  /// @notice Return the latest price and last update of the given asset id.
  /// @dev Same as getLatestPrice(), but unsafe function has no check price age
  /// @dev It is expected that the downstream contract should return the price in USD with 30 decimals.
  /// @dev The currency of the price that will be quoted with depends on asset id. For example, we can have two BTC price but quoted differently.
  ///      In that case, we can define two different asset ids as BTC/USD, BTC/EUR.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  function unsafeGetLatestPrice(
    bytes32 _assetId,
    bool _isMax
  ) external view returns (uint256 _price, int32 _exponent, uint256 _lastUpdate) {
    (_price, _exponent, _lastUpdate) = _unsafeGetLatestPrice(_assetId, _isMax);

    return (_price, _exponent, _lastUpdate);
  }

  /// @notice Return the latest price of asset, last update of the given asset id, along with market status.
  /// @dev Same as getLatestPrice(), but with market status. Revert if status is 0 (Undefined) which means we never utilize this assetId.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  function getLatestPriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax
  ) external view returns (uint256 _price, uint256 _lastUpdate, uint8 _status) {
    _status = marketStatus[_assetId];
    if (_status == 0) revert IOracleMiddleware_MarketStatusUndefined();

    (_price, , _lastUpdate) = _getLatestPrice(_assetId, _isMax);

    return (_price, _lastUpdate, _status);
  }

  /// @notice Return the latest price of asset, last update of the given asset id, along with market status.
  /// @dev Same as unsafeGetLatestPrice(), but with market status. Revert if status is 0 (Undefined) which means we never utilize this assetId.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  function unsafeGetLatestPriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax
  ) external view returns (uint256 _price, uint256 _lastUpdate, uint8 _status) {
    _status = marketStatus[_assetId];
    if (_status == 0) revert IOracleMiddleware_MarketStatusUndefined();

    (_price, , _lastUpdate) = _unsafeGetLatestPrice(_assetId, _isMax);

    return (_price, _lastUpdate, _status);
  }

  /// @notice Return the latest adaptive rice of asset, last update of the given asset id
  /// @dev Adaptive price is the price that is applied with premium or discount based on the market skew.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  /// @param _marketSkew market skew quoted in asset (NOT USD)
  /// @param _sizeDelta The size delta of this operation. It will determine the new market skew to be used for calculation.
  /// @param _maxSkewScaleUSD The config of maxSkewScaleUSD
  function getLatestAdaptivePrice(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate) {
    (_adaptivePrice, , _lastUpdate) = _getLatestAdaptivePrice(
      _assetId,
      _isMax,
      _marketSkew,
      _sizeDelta,
      _maxSkewScaleUSD,
      true
    );
    return (_adaptivePrice, _lastUpdate);
  }

  /// @notice Return the unsafe latest adaptive rice of asset, last update of the given asset id
  /// @dev Adaptive price is the price that is applied with premium or discount based on the market skew.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  /// @param _marketSkew market skew quoted in asset (NOT USD)
  /// @param _sizeDelta The size delta of this operation. It will determine the new market skew to be used for calculation.
  /// @param _maxSkewScaleUSD The config of maxSkewScaleUSD
  function unsafeGetLatestAdaptivePrice(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate) {
    (_adaptivePrice, , _lastUpdate) = _getLatestAdaptivePrice(
      _assetId,
      _isMax,
      _marketSkew,
      _sizeDelta,
      _maxSkewScaleUSD,
      false
    );
    return (_adaptivePrice, _lastUpdate);
  }

  /// @notice Return the latest adaptive rice of asset, last update of the given asset id, along with market status.
  /// @dev Adaptive price is the price that is applied with premium or discount based on the market skew.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  /// @param _marketSkew market skew quoted in asset (NOT USD)
  /// @param _sizeDelta The size delta of this operation. It will determine the new market skew to be used for calculation.
  /// @param _maxSkewScaleUSD The config of maxSkewScaleUSD
  function getLatestAdaptivePriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD
  ) external view returns (uint256 _adaptivePrice, int32 _exponent, uint256 _lastUpdate, uint8 _status) {
    _status = marketStatus[_assetId];
    if (_status == 0) revert IOracleMiddleware_MarketStatusUndefined();

    (_adaptivePrice, _exponent, _lastUpdate) = _getLatestAdaptivePrice(
      _assetId,
      _isMax,
      _marketSkew,
      _sizeDelta,
      _maxSkewScaleUSD,
      true
    );
    return (_adaptivePrice, _exponent, _lastUpdate, _status);
  }

  /// @notice Return the latest adaptive rice of asset, last update of the given asset id, along with market status.
  /// @dev Adaptive price is the price that is applied with premium or discount based on the market skew.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  /// @param _marketSkew market skew quoted in asset (NOT USD)
  /// @param _sizeDelta The size delta of this operation. It will determine the new market skew to be used for calculation.
  /// @param _maxSkewScaleUSD The config of maxSkewScaleUSD
  function unsafeGetLatestAdaptivePriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate, uint8 _status) {
    _status = marketStatus[_assetId];
    if (_status == 0) revert IOracleMiddleware_MarketStatusUndefined();

    (_adaptivePrice, , _lastUpdate) = _getLatestAdaptivePrice(
      _assetId,
      _isMax,
      _marketSkew,
      _sizeDelta,
      _maxSkewScaleUSD,
      false
    );
    return (_adaptivePrice, _lastUpdate, _status);
  }

  function _getLatestPrice(
    bytes32 _assetId,
    bool _isMax
  ) private view returns (uint256 _price, int32 _exponent, uint256 _lastUpdate) {
    AssetPriceConfig memory _assetConfig = assetPriceConfigs[_assetId];

    // 1. get price from Pyth
    (_price, _exponent, _lastUpdate) = pythAdapter.getLatestPrice(_assetId, _isMax, _assetConfig.confidenceThresholdE6);

    // check price age
    if (block.timestamp - _lastUpdate > _assetConfig.trustPriceAge) revert IOracleMiddleware_PythPriceStale();

    // 2. Return the price and last update
    return (_price, _exponent, _lastUpdate);
  }

  function _unsafeGetLatestPrice(
    bytes32 _assetId,
    bool _isMax
  ) private view returns (uint256 _price, int32 _exponent, uint256 _lastUpdate) {
    AssetPriceConfig memory _assetConfig = assetPriceConfigs[_assetId];

    // 1. get price from Pyth
    (_price, _exponent, _lastUpdate) = pythAdapter.getLatestPrice(_assetId, _isMax, _assetConfig.confidenceThresholdE6);

    // 2. Return the price and last update
    return (_price, _exponent, _lastUpdate);
  }

  function _getLatestAdaptivePrice(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD,
    bool isSafe
  ) private view returns (uint256 _adaptivePrice, int32 _exponent, uint256 _lastUpdate) {
    // Get price from Pyth
    uint256 _price;
    (_price, _exponent, _lastUpdate) = isSafe
      ? _getLatestPrice(_assetId, _isMax)
      : _unsafeGetLatestPrice(_assetId, _isMax);

    // Apply premium/discount
    _adaptivePrice = _calculateAdaptivePrice(_marketSkew, _sizeDelta, _price, _maxSkewScaleUSD);

    // Return the price and last update
    return (_adaptivePrice, _exponent, _lastUpdate);
  }

  /// @notice Calcuatate adaptive base on Market skew by position size
  /// @param _marketSkew Long position size - Short position size
  /// @param _sizeDelta Position size delta
  /// @param _price Oracle price
  /// @param _maxSkewScaleUSD Config from Market config
  /// @return _adaptivePrice
  function _calculateAdaptivePrice(
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _price,
    uint256 _maxSkewScaleUSD
  ) internal pure returns (uint256 _adaptivePrice) {
    // couldn't calculate adaptive price because max skew scale config is used to calcualte premium with market skew
    // then just return oracle price
    if (_maxSkewScaleUSD == 0) return _price;

    // Given
    //    Max skew scale = 300,000,000 USD
    //    Current Price  =       1,500 USD
    //    Given:
    //      Long Position size   = 1,000,000 USD
    //      Short Position size  =   700,000 USD
    //      then Market skew     = Long - Short = 300,000 USD
    //
    //    If Trader manipulatate by Decrease Long position for 150,000 USD
    //    Then:
    //      Premium (before) = 300,000 / 300,000,000 = 0.001
    int256 _premium = (_marketSkew * 1e30) / int256(_maxSkewScaleUSD);

    //      Premium (after)  = (300,000 - 150,000) / 300,000,000 = 0.0005
    //      ** + When user increase Long position ot Decrease Short position
    //      ** - When user increase Short position ot Decrease Long position
    int256 _premiumAfter = ((_marketSkew + _sizeDelta) * 1e30) / int256(_maxSkewScaleUSD);

    //      Adaptive price = Price * (1 + Median of Before and After)
    //                     = 1,500 * (1 + (0.001 + 0.0005 / 2))
    //                     = 1,500 * (1 + 0.00125) = 1,501.875
    int256 _premiumMedian = (_premium + _premiumAfter) / 2;
    return (_price * uint256(1e30 + _premiumMedian)) / 1e30;
  }

  /// @notice Set asset price configs
  /// @param _assetId Asset's to set price config
  /// @param _confidenceThresholdE6 New price confidence threshold
  /// @param _trustPriceAge valid price age
  function setAssetPriceConfig(
    bytes32 _assetId,
    uint32 _confidenceThresholdE6,
    uint32 _trustPriceAge
  ) external onlyOwner {
    AssetPriceConfig memory _config = assetPriceConfigs[_assetId];

    emit LogSetAssetPriceConfig(
      _assetId,
      _config.confidenceThresholdE6,
      _confidenceThresholdE6,
      _config.trustPriceAge,
      _trustPriceAge
    );
    _config.confidenceThresholdE6 = _confidenceThresholdE6;
    _config.trustPriceAge = _trustPriceAge;

    assetPriceConfigs[_assetId] = _config;
  }

  /// @notice Set market status for the given asset.
  /// @param _assetId The asset address to set.
  /// @param _status Status enum, see `marketStatus` comment section.
  function setMarketStatus(bytes32 _assetId, uint8 _status) external onlyUpdater {
    if (_status > 2) revert IOracleMiddleware_InvalidMarketStatus();

    marketStatus[_assetId] = _status;
    emit LogSetMarketStatus(_assetId, _status);
  }

  /// @notice A function for setting updater who is able to setMarketStatus
  function setUpdater(address _account, bool _isActive) external onlyOwner {
    isUpdater[_account] = _isActive;
    emit LogSetUpdater(_account, _isActive);
  }

  /**
   * Setter
   */
  /// @notice Set new PythAdapter contract address.
  /// @param _newPythAdapter New PythAdapter contract address.
  function setPythAdapter(address _newPythAdapter) external onlyOwner {
    pythAdapter = IOracleAdapter(_newPythAdapter);

    emit LogSetPythAdapter(address(pythAdapter), _newPythAdapter);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IOracleAdapter {
  function getLatestPrice(
    bytes32 _assetId,
    bool _isMax,
    uint32 _confidenceThreshold
  ) external view returns (uint256, int32, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IOracleMiddleware {
  // errors
  error IOracleMiddleware_PythPriceStale();
  error IOracleMiddleware_MarketStatusUndefined();
  error IOracleMiddleware_OnlyUpdater();
  error IOracleMiddleware_InvalidMarketStatus();

  function isUpdater(address _updater) external returns (bool);

  function assetPriceConfigs(bytes32 _assetId) external returns (uint32, uint32);

  function marketStatus(bytes32 _assetId) external returns (uint8);

  function getLatestPrice(bytes32 _assetId, bool _isMax) external view returns (uint256 _price, uint256 _lastUpdated);

  function getLatestPriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax
  ) external view returns (uint256 _price, uint256 _lastUpdated, uint8 _status);

  function getLatestAdaptivePrice(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate);

  function unsafeGetLatestAdaptivePrice(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate);

  function getLatestAdaptivePriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD
  ) external view returns (uint256 _adaptivePrice, int32 _exponent, uint256 _lastUpdate, uint8 _status);

  function unsafeGetLatestAdaptivePriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate, uint8 _status);

  // =========================================
  // | ---------- Setter ------------------- |
  // =========================================

  function unsafeGetLatestPrice(
    bytes32 _assetId,
    bool _isMax
  ) external view returns (uint256 _price, int32 _exponent, uint256 _lastUpdated);

  function unsafeGetLatestPriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax
  ) external view returns (uint256 _price, uint256 _lastUpdated, uint8 _status);

  function setMarketStatus(bytes32 _assetId, uint8 _status) external;

  function setUpdater(address _updater, bool _isActive) external;

  function setAssetPriceConfig(bytes32 _assetId, uint32 _confidenceThresholdE6, uint32 _trustPriceAge) external;
}