// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./DegenPoolManagerSettings.sol";
import "./interfaces/IDegenPoolManager.sol";
import "./interfaces/IDegenBase.sol";
import "../../../interfaces/vault/IReader.sol";
/**
 * @title DegenPoolManager
 * @author balding-ghost
 * @notice The DegenPoolManager contract is used to handle the funds (similar the the VaultManager contract).  The contract handles liquidations and position closures. The contract also handles the fees that are paid to the protocol and the liquidators. The contract also handles the payouts of the players. It is generally the contract where most is configured and most payout/liquidation logic is handled.
 */
contract DegenPoolManager is IDegenPoolManager, DegenPoolManagerSettings, ReentrancyGuard {
  IReader public immutable reader;

  // this configuration sets the max budget for losses before the contract pauses itself partly. it is sort of the credit line the contract has (given by the DAO) that the contract has to stay within. if the contract exceeds this budget it will stop accepting new positions and will only liquidate positions. this is to prevent the contract from going bankrupt suddenly. If the degen game is profitable (and the profits are collected by the vault) the budget will increase. In this way the value set/added to this value act as the 'max amount of losses possible'. The main purpose of this mechanism is to prevent draining of the vault. It is true that degen can still lose incredibly much if the game is profitable for years and suddently all historical profits are lost in a few  hours. To prevetn this the DAO can decrement so that the budget is reset.
  uint256 public maxLossesAllowedUsdTotal;

  // total amount of theoretical bad debt that wlps have endured (not real just metric of bad/inefficient liquidation) in the period
  // this value can be used for seperating wlp profits, bribes, feecollector etc (if we want to)
  uint256 public totalTheoreticalBadDebtUsdPeriod;

  // percentage of th net profits that is paid to the fee collector
  uint256 public degenProfitRatioForFeeCollector;

  // total amount of escrowed tokens in the contract (of openPositions)
  uint256 public totalActiveMarginInUsd;

  // liquidation threshold is the threshold at which a position can be liquidated (margin level of the position)
  uint256 public liquidationThreshold;

  // amount of tokens escrowed per player (of openOrders and openPositions)
  mapping(address => uint256) public playerMarginInUsd;

  // amount of tokens liquidators can claim as a reward for liquidating positions
  mapping(address => uint256) public liquidatorFeesUsd;

  // max percentage of the margin amount that can be paid as a liquidation fee to liquidator, scaled 1e6
  uint256 public maxLiquidationFee;

  // min percentage of the margin amount that can be paid as a liquidation fee to liquidator, scaled 1e6
  uint256 public minLiquidationFee;

  uint256 public interestLiquidationFee;

  constructor(
    address _vaultAddress,
    address _swap,
    address _reader,
    bytes32 _pythAssetId,
    address _admin,
    address _stableCoinAddress,
    uint256 _decimalsStableCoin
  )
    DegenPoolManagerSettings(
      _vaultAddress,
      _swap,
      _pythAssetId,
      _admin,
      _stableCoinAddress,
      _decimalsStableCoin
    )
  {
    reader = IReader(_reader);
  }

  /// @notice lets vault get wager amount from escrowed tokens
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _amount the amount of token
  function getEscrowedTokens(address _token, uint256 _amount) public {
    require(msg.sender == address(vault), "DegenPoolManager: only vault");
    IERC20(_token).transfer(address(vault), _amount);
  }

  function transferInMarginUsdc(address _player, uint256 _marginAmountUsdc) external onlyDegenGame {
    uint256 _marginAmountUsd;
    unchecked {
      _marginAmountUsd = _marginAmountUsdc * VAULT_SCALING_INCREASE_FOR_USD;
      totalActiveMarginInUsd += _marginAmountUsd;
      playerMarginInUsd[_player] += _marginAmountUsd;
    }
  }

  /**
   * @notice this function is called when a position is closed. it calculates the net profit/loss of the position and credits the player with the profit/loss minus the protocol fee.
   * @dev the protocol fee is calculated based on the size of the position, the duration of the position and the roi of the position.
   * @param _positionKey the key of the position
   * @param _position the position info
   * @param _caller the caller of the position
   * @param _interestFunding the total funding rate paid by the position
   * @return closedPosition_ the closed position info
   */
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
    onlyDegenGame
    returns (
      ClosedPositionInfo memory closedPosition_,
      uint256 marginAssetAmount_,
      uint256 feesPaid_
    )
  {
    if (_pnlUsd > 0) {
      // pnl is positive, position is closed in profit
      (closedPosition_, marginAssetAmount_, feesPaid_) = _closePositionInProfit(
        _position,
        _positionKey,
        _caller,
        _assetPrice,
        _interestFunding,
        _pnlUsd
      );
    } else {
      // pnl is negative, position is closed in loss
      (closedPosition_, marginAssetAmount_, feesPaid_) = _closePositionInLoss(
        _positionKey,
        _caller,
        _assetPrice,
        _position.marginAmountUsd,
        _interestFunding,
        _pnlUsd,
        _position.marginAsset, // payout in stables
        _isPositionValueNegative
      );
    }

    return (closedPosition_, marginAssetAmount_, feesPaid_);
  }

  /**
   * @notice this function is called when a position is liquidated.
   * @param _positionKey the key of the position
   * @param _player the player of the position
   * @param _liquidator the liquidator of the position
   * @param _marginAmountUsd the margin amount of the position
   * @param _interestFunding the total funding rate paid by the position
   * @param _assetPrice the price of the asset at the time of closing
   * @param _INT_pnlUsd the pnl of the position including interest paid/due
   * @return closedPosition_ the closed position info
   */
  function _processLiquidationClose(
    bytes32 _positionKey,
    address _player,
    address _liquidator,
    uint256 _marginAmountUsd,
    uint256 _interestFunding,
    uint256 _assetPrice,
    int256 _INT_pnlUsd,
    bool _isPositionValueNegative,
    address _marginAsset
  ) internal returns (ClosedPositionInfo memory closedPosition_, uint256 protocolProfitUsd_) {
    _takeUsdMarginOfPlayer(_player, _marginAmountUsd);

    closedPosition_.player = _player;
    closedPosition_.liquidatorAddress = _liquidator;
    // if payoutInStables is true, the player margined/wagered in stables, so we will pay them out in stables (also  they will get their margin back in stables). If payoutInStables is false, the player margined/wagered in the asset of the contract, so we will pay them out in the asset of the contract (also they will get their margin back in the asset of the contract)
    closedPosition_.marginAsset = _marginAsset;
    closedPosition_.pnlIsNegative = true;
    closedPosition_.timestampClosed = uint32(block.timestamp);
    closedPosition_.priceClosed = uint96(_assetPrice);
    closedPosition_.totalFundingRatePaidUsd = uint96(_interestFunding);
    // note totalPayoutUsd could be denominated in stables or asset, if payout is in stables it is denominated in stables, if payout is in asset it is denominated in asset
    // note margin is always in usd
    closedPosition_.pnlUsd = _INT_pnlUsd;

    uint256 liquidatorFeeUsd_;
    uint256 theoreticalBadDebtUsd_;
    if (_isPositionValueNegative) {
      // the position liquidated from interest funding
      unchecked {
        liquidatorFeeUsd_ = (_marginAmountUsd * interestLiquidationFee) / BASIS_POINTS;
        protocolProfitUsd_ = _marginAmountUsd - liquidatorFeeUsd_;
      }
    } else {
      assert(_INT_pnlUsd < 0); // if liquidated but not isPositionValueNegative, pnl must be negative
      (protocolProfitUsd_, liquidatorFeeUsd_, theoreticalBadDebtUsd_) = computeLiquidationReward(
        _marginAmountUsd - _interestFunding, // this wont revert because the position value is not negative
        uint256(-1 * _INT_pnlUsd)
      );
    }

    closedPosition_.liquidationFeePaidUsd = uint96(liquidatorFeeUsd_);

    // position is liquidated so there is no intereset funding paid, (all margin - liquidator fee) is profit for the protocol
    unchecked {
      // totalLiquidatorFeesUsdPeriod += liquidatorFeeUsd_;
      liquidatorFeesUsd[_liquidator] += liquidatorFeeUsd_;
      // totalRealizedProfitsUsd += protocolProfitUsd_;
      // note theoretical debt isn't real debt, it is the difference between the margin amount and the negative pnl of the position (this only is non zero if the position was liquidated at a point where the margin was worth less as the PNL). it is more an indicator of inefficiency of the liquidation mechanism.
      totalTheoreticalBadDebtUsdPeriod += theoreticalBadDebtUsd_;
    }

    emit PositionLiquidated(
      _positionKey,
      _marginAmountUsd,
      protocolProfitUsd_,
      liquidatorFeeUsd_,
      theoreticalBadDebtUsd_,
      _isPositionValueNegative
    );

    return (closedPosition_, protocolProfitUsd_);
  }

  function processLiquidationClose(
    bytes32 _positionKey,
    address _player,
    address _liquidator,
    uint256 _marginAmountUsd,
    uint256 _interestFunding,
    uint256 _assetPrice,
    int256 _INT_pnlUsd,
    bool _isPositionValueNegative,
    address _marginAsset
  ) external onlyDegenGame returns (ClosedPositionInfo memory) {
    (
      ClosedPositionInfo memory closedPosition_,
      uint256 protocolProfitUsd_
    ) = _processLiquidationClose(
        _positionKey,
        _player,
        _liquidator,
        _marginAmountUsd,
        _interestFunding,
        _assetPrice,
        _INT_pnlUsd,
        _isPositionValueNegative,
        _marginAsset
      );

    uint256 profitAmountInStable_ = (protocolProfitUsd_) / additionalPrecisionComparedToStableCoin;
    // wager asset has already swapped to stable
    _payout(_player, address(stableCoin), 0, profitAmountInStable_);
    return closedPosition_;
  }

  /**
   * @notice this function is part of the liquidation incentive mechanism.its purpose is to calculate how much the liquidator will receive as a reward for liquidating a position.
   * @dev the reward is calculated as a percentage of the margin amount of the position. the percentage is calculated based on the distance between the liquidation threshold and the effective margin level of the position.
   * @dev the closer the liquidator is to the liquidation threshold, the higher the reward will be.
   * @param _marginAmountUsd amount of margin the position had in usd
   * @param _pnlUsd amount of negative pnl the position had (including interest) in usd
   * @return protocolProfitUsd_ the amount of tokens the protocol will receive as a fee for the position
   * @return liquidatorFeeUsd_ the amount of tokens the liquidator will receive as a reward for liquidating the position
   * @return theoreticalBadDebtUsd_ the amount of tokens that on paper have been lost by the protocol. this is the difference between the margin amount and the negative pnl of the position (this only is non zero if the position was liquidated at a point where the margin was worth less as the PNL)
   */
  function computeLiquidationReward(
    uint256 _marginAmountUsd,
    uint256 _pnlUsd
  )
    public
    view
    returns (uint256 protocolProfitUsd_, uint256 liquidatorFeeUsd_, uint256 theoreticalBadDebtUsd_)
  {
    // compute the liquidation threshold of the position.
    uint256 liquidationMarginLevel_ = (_marginAmountUsd * liquidationThreshold) / BASIS_POINTS;

    require(
      _pnlUsd >= liquidationMarginLevel_,
      "DegenPoolManager: margin amount cannot be smaller as the negative pnl in liquidation"
    );

    /**
     * If a user is liquidated the whole margin amount is 'confiscated' by the protocol. The majority of this margin amount will go to the protocols asset pool which took on the risk of the position. A small percentage of the margin amount will go to the liquidator as a reward for liquidating the position.
     *
     * If the liquidator liquidates the position at the liquidation threshold, the liquidator will receive the maximum reward. If the liquidator liquidates the position at a point where it could have been more negative, the liquidator will receive a smaller reward. If the liquidator liquidates the position at a point where it the negative pnl exceeded the margin amount, the liquidator will receive the minimum reward. If the liquidation is in between the threshold and the point where the negative pnl exceeded the margin amount, the liquidator will receive a reward that is between the minimum and maximum reward (linear formula).
     *
     * Example a 1 ETH short position with 500x leverage and a liquidation threshold of 10%. Min liquidation fee is 5% and max liquidation fee is 10%.
     *
     * This means that if the pnl of the position was -0.9 ETH, the position would be liquidated.
     * 1. If the liquidator liquidates the position at PNL of -0.9 ETH, the liquidator will receive 10% of the margin amount as a reward and the protocol(0.1 ETH) the protocl will receive 0.9ETH.
     * 2. If the liquidator liquidates the position at PNL of -0.95 ETH, the liquidator will receive 7.5% of the margin amount as a reward and the protocol(0.075 ETH) the protocl will receive 0.925ETH.
     * 3. If the liquidator liquidates the position at PNL of -1 ETH, the liquidator will receive 5% of the margin amount as a reward and the protocol(0.05 ETH) the protocl will receive 0.95ETH.
     */

    // calculate the liquidation distance, so this is the distance between the liquidation threshold and the effective margin level of the position
    // this cannot underflow otherwise the position wasn't liquidatable in the first place (and it would have failed the require in the liquidate function)

    unchecked {
      uint256 liquidationDistance_ = _pnlUsd - liquidationMarginLevel_;

      uint256 thresHoldDistance_ = _marginAmountUsd - liquidationMarginLevel_;

      if (liquidationDistance_ == 0) {
        // the liquidator has liquiated the position at the liquidation threshold this is the best result (so position was liquidated on the exact cent it became liquitable)
        liquidatorFeeUsd_ = (_marginAmountUsd * maxLiquidationFee) / BASIS_POINTS;
        protocolProfitUsd_ = _marginAmountUsd - liquidatorFeeUsd_;
        theoreticalBadDebtUsd_ = 0;
      } else if (liquidationDistance_ >= thresHoldDistance_) {
        // the liquidator has liquiated the position at the point where it couldn't have been any more negative
        liquidatorFeeUsd_ = (_marginAmountUsd * minLiquidationFee) / BASIS_POINTS;
        protocolProfitUsd_ = _marginAmountUsd - liquidatorFeeUsd_;
        theoreticalBadDebtUsd_ = liquidationDistance_ - thresHoldDistance_;
      } else {
        // the liquidator has liquidated the position between the threshold and the point where it couldn't have been any more negative
        // Compute slope of the line scaled by BASIS_POINTS
        uint256 slope_ = ((maxLiquidationFee - minLiquidationFee) * BASIS_POINTS) /
          thresHoldDistance_;
        uint256 rewardPercentage_ = maxLiquidationFee -
          ((slope_ * liquidationDistance_) / BASIS_POINTS); // Remember to scale down after multiplication
        liquidatorFeeUsd_ = (_marginAmountUsd * rewardPercentage_) / BASIS_POINTS;
        protocolProfitUsd_ = _marginAmountUsd - liquidatorFeeUsd_;
        theoreticalBadDebtUsd_ = 0;
      }
    }
  }

  function claimLiquidationFees() external nonReentrant {
    uint256 liquidatorFeeUsd_ = liquidatorFeesUsd[msg.sender];

    liquidatorFeeUsd_ = liquidatorFeeUsd_ / (PRICE_PRECISION / decimalsStableCoin);
    liquidatorFeesUsd[msg.sender] = 0;
    stableCoin.transfer(msg.sender, liquidatorFeeUsd_);
    emit ClaimLiquidationFees(liquidatorFeeUsd_);
  }

  function incrementMaxLossesBuffer(uint256 _maxLossesIncrease) external onlyAdmin {
    maxLossesAllowedUsdTotal += _maxLossesIncrease;
    emit IncrementMaxLosses(_maxLossesIncrease, maxLossesAllowedUsdTotal);
  }

  function decrementMaxLossesBuffer(uint256 _maxLossesDecrease) external onlyAdmin {
    require(_maxLossesDecrease <= maxLossesAllowedUsdTotal, "DegenPoolManager: invalid decrease");
    maxLossesAllowedUsdTotal -= _maxLossesDecrease;
    emit DecrementMaxLosses(_maxLossesDecrease, maxLossesAllowedUsdTotal);
  }

  function setDegenProfitForFeeCollector(
    uint256 _degenProfitRatioForFeeCollector
  ) external onlyAdmin {
    degenProfitRatioForFeeCollector = _degenProfitRatioForFeeCollector;
    emit SetDegenProfitForFeeCollector(_degenProfitRatioForFeeCollector);
  }

  function setMaxLiquidationFee(uint256 _maxLiquidationFee) external onlyAdmin {
    require(_maxLiquidationFee <= BASIS_POINTS, "DegenPoolManager: invalid fee");
    maxLiquidationFee = _maxLiquidationFee;
    emit SetMaxLiquidationFee(_maxLiquidationFee);
  }

  function setMinLiquidationFee(uint256 _minLiquidationFee) external onlyAdmin {
    require(_minLiquidationFee <= BASIS_POINTS, "DegenPoolManager: invalid fee");
    minLiquidationFee = _minLiquidationFee;
    emit SetMinLiquidationFee(_minLiquidationFee);
  }

  function setInterestLiquidationFee(uint256 _interestLiquidationFee) external onlyAdmin {
    require(_interestLiquidationFee <= BASIS_POINTS, "DegenPoolManager: invalid fee");
    interestLiquidationFee = _interestLiquidationFee;
    emit SetMinLiquidationFee(_interestLiquidationFee);
  }

  function setLiquidationThreshold(uint256 _liquidationThreshold) external onlyAdmin {
    require(_liquidationThreshold <= BASIS_POINTS, "DegenPoolManager: invalid threshold");
    IDegenBase(degenGameContract).setLiquidationThreshold(_liquidationThreshold);
    liquidationThreshold = _liquidationThreshold;
    emit SetLiquidationThreshold(_liquidationThreshold);
  }

  function returnVaultReserveInAsset() external view returns (uint256 vaultReserveUsd_) {
    // fetch the amount of usd reserve in the vault, note this is scaled 1e30, so 1 usd is 1e30
    vaultReserveUsd_ = vault.getReserve() / 1e12; // 1e12 is to scale back 1e30 to 1e18 todo add constant
    require(vaultReserveUsd_ != 0, "DegenPoolManager: vault reserve is 0");
  }

  // internal functions
  /**
   * @notice this function is called when a position is closed in profit. it calculates the net profit of the position and credits the player with the profit minus the protocol fee.
   * @dev the protocol fee is calculated based on the size of the position, the duration of the position and the roi of the position.
   * @param _positionKey the key of the position
   * @param _player the player of the position
   * @param _assetPrice the price of the asset at the time of closing
   * @param _interestFunding the total funding rate paid by the position
   * @param _pnlUsd the pnl of the position including interest paid/due
   * @return closedPosition_ the closed position info
   */
  function _closePositionInProfit(
    PositionInfo memory _position,
    bytes32 _positionKey,
    address _player,
    uint256 _assetPrice,
    uint256 _interestFunding,
    int256 _pnlUsd
  )
    internal
    returns (
      ClosedPositionInfo memory closedPosition_,
      uint256 marginAssetAmount_,
      uint256 feesPaid_
    )
  {
    // credit the player with their margin
    _takeUsdMarginOfPlayer(_player, _position.marginAmountUsd);

    // calculate the net profit of the position in usd (doesn't matter so far if the player is going to be paid out in the asset or not, we will convert it later)
    (uint256 pnlMinusFeeAmountUsd_, uint256 closeFeeProtocolUsd_) = _calculateNetProfitOfPosition(
      _position.positionSizeUsd,
      _position.priceOpened,
      _assetPrice,
      _position.maxPositionProfitUsd,
      _pnlUsd
    );

    uint96 payoutMinusAllFees_ = 0;
    if (_position.marginAmountUsd + uint96(pnlMinusFeeAmountUsd_) > uint96(_interestFunding)) {
      payoutMinusAllFees_ =
        _position.marginAmountUsd +
        uint96(pnlMinusFeeAmountUsd_) -
        uint96(_interestFunding);
    }

    closedPosition_.player = _player;

    closedPosition_.timestampClosed = uint32(block.timestamp);
    closedPosition_.marginAsset = _position.marginAsset;
    closedPosition_.priceClosed = uint96(_assetPrice);

    closedPosition_.totalFundingRatePaidUsd = uint96(_interestFunding);
    closedPosition_.closeFeeProtocolUsd = uint96(closeFeeProtocolUsd_);

    closedPosition_.totalPayoutUsd = uint96(pnlMinusFeeAmountUsd_);
    // note if the player has marginned in the asset, the player will have returned the asset, however we do registered the margin returned in usd
    closedPosition_.pnlUsd = _pnlUsd;

    uint256 payoutAmountInStable_ = (payoutMinusAllFees_) / additionalPrecisionComparedToStableCoin;
    uint256 marginAmountInStable_ = _position.marginAmountUsd /
      additionalPrecisionComparedToStableCoin;


    (marginAssetAmount_, feesPaid_) = _payout(
      _player,
      _position.marginAsset,
      payoutAmountInStable_,
      marginAmountInStable_
    );
    emit PositionClosedInProfit(_positionKey, pnlMinusFeeAmountUsd_, closeFeeProtocolUsd_);

    return (closedPosition_, marginAssetAmount_, feesPaid_);
  }

  function _payout(
    address _player,
    address _marginAsset,
    uint256 payoutAmountInStable_,
    uint256 marginAmountInStable_
  ) internal returns (uint256 marginAssetAmount_, uint256 feesPaid_) {
    // _payout(_player, address(stableCoin), 0, profitAmountInStable_);
    if (payoutAmountInStable_ == 0) {
      vault.payin(address(stableCoin), address(this), marginAmountInStable_);
      return (marginAmountInStable_, 0);
    }
    vault.payout(
      address(stableCoin),
      address(this),
      marginAmountInStable_,
      address(this),
      payoutAmountInStable_
    );
    if (_marginAsset != address(stableCoin)) {
      stableCoin.transfer(address(swap), payoutAmountInStable_);
      (marginAssetAmount_, feesPaid_) = swap.swapTokens(
        payoutAmountInStable_,
        address(stableCoin),
        _marginAsset,
        _player
      );
    } else {
      stableCoin.transfer(_player, payoutAmountInStable_);
      marginAssetAmount_ = payoutAmountInStable_;
      feesPaid_ = 0;
    }
  }

  /**
   * @notice internal function that scales the target asset to usd amount scaled to 1e18
   * @param _amountOfAsset amount of the asset scaled in the assets decimals
   * @param _assetPrice price of the asset scaled in PRICE_PRECISION
   * @return _amountOfUsd amount of usd scaled in PRICE_PRECISION
   */
  function _targetAssetToUsd(
    uint256 _amountOfAsset,
    uint256 _assetPrice,
    address _wagerAsset
  ) internal view returns (uint256 _amountOfUsd) {
    uint256 decimalsToken_ = vault.tokenDecimals(_wagerAsset);
    unchecked {
      _amountOfUsd = (_amountOfAsset * _assetPrice) / (10 ** decimalsToken_);
    }
  }

  /**
   * @notice this function calculates the net profit of a position. it takes into account the size of the position, the duration of the position and the roi of the position.
   * @dev the roi is calculated as the pnl of the position divided by the margin amount of the position.
   * @dev the roi is then used to calculate the protocol fee. the protocol fee is calculated based on the size of the position, the duration of the position and the roi of the position.
   * @param _positionSizeUsd the size of the position
   * @param _openPrice the open price of the position
   * @param _assetPrice the price of the asset at the time of closing
   * @param _maxPositionProfitUsd the maximum profit the position could have made
   * @param INT_pnlUsd the pnl of the position including interest paid/due
   * @return payoutAmount_ the amount of tokens the player will receive as a payout
   * @return closeFeeProtocolUsd_ the amount of tokens the protocol will receive as a fee
   */
  function _calculateNetProfitOfPosition(
    uint256 _positionSizeUsd,
    uint256 _openPrice,
    uint256 _assetPrice,
    uint256 _maxPositionProfitUsd,
    int256 INT_pnlUsd
  ) internal pure returns (uint256 payoutAmount_, uint256 closeFeeProtocolUsd_) {
    // position in profit, pnl is positive
    uint256 _pnlUsd = uint256(INT_pnlUsd);
    if (_pnlUsd > _maxPositionProfitUsd) {
      _pnlUsd = _maxPositionProfitUsd;
    }

    // calculate the price move percentage of the position
    // _positionSizeUsd should be like 100 00000000 = 100$ and will be div by 1e10 in _calculateProfitFee
    // _priceMovePercentage is like 50000 = 0.05 = 5%, 100000 = 0.1 = 10%
    uint256 _priceMovePercentage = _calculatePriceMovePercentage(_openPrice, _assetPrice);

    _checkIfPriceMoveIsSufficientToClose(_priceMovePercentage);

    // calculate the fee percentage of the position
    uint256 pnlFeePercentage_ = _calculateProfitFee(_priceMovePercentage, _positionSizeUsd);

    // calculate the fee of the position
    closeFeeProtocolUsd_ = (_pnlUsd * pnlFeePercentage_) / SCALE;
    // calculate the payout of the position
    payoutAmount_ = _pnlUsd - closeFeeProtocolUsd_;
  }

  /**
   * @notice this function is called when a position is closed in loss. it calculates the net loss of the position and credits the player with the margin amount left.
   * @dev the margin amount left is the amount of margin that is left after the position is closed. if the position is liquidated, the margin amount left is 0.
   * @param _positionKey the key of the position
   * @param _player the player of the position
   * @param _assetPrice the price of the asset at the time of closing
   * @param _marginAmountUsd the margin amount of the position in usd
   * @param _interestFunding the total funding rate paid by the position
   * @param _pnlUsd the pnl of the position including interest paid/due
   * @param _marginAsset the asset the margin was placed in, should be the asset the user should be paid out in (their remaining margin)
   * @return closedPosition_ the closed position info
   */
  function _closePositionInLoss(
    bytes32 _positionKey,
    address _player,
    uint256 _assetPrice,
    uint256 _marginAmountUsd,
    uint256 _interestFunding,
    int256 _pnlUsd,
    address _marginAsset,
    bool _isPositionValueNegative
  )
    internal
    returns (
      ClosedPositionInfo memory closedPosition_,
      uint256 marginAssetAmount_,
      uint256 feesPaid_
    )
  {
    _takeUsdMarginOfPlayer(_player, _marginAmountUsd);
    uint256 marginLeftUsd_;

    if (_isPositionValueNegative) {
      revert("DegenPoolManager: position has liquidated");
    }
    if (_pnlUsd > 0) {
      revert("DegenPoolManager: position has profit");
    }
    unchecked {
      marginLeftUsd_ = uint256(int256(_marginAmountUsd) - int256(_interestFunding) + _pnlUsd);
    }
    if (marginLeftUsd_ > 0) {
      uint256 payoutAmountInStable_ = marginLeftUsd_ / additionalPrecisionComparedToStableCoin;
      uint256 marginAmountInStable_ = _marginAmountUsd / additionalPrecisionComparedToStableCoin;
      (marginAssetAmount_, feesPaid_) = _payout(
        _player,
        _marginAsset,
        payoutAmountInStable_,
        marginAmountInStable_
      );
    }

    closedPosition_.player = _player;

    closedPosition_.timestampClosed = uint32(block.timestamp);
    closedPosition_.marginAsset = _marginAsset;
    closedPosition_.priceClosed = uint96(_assetPrice);

    closedPosition_.pnlIsNegative = true;
    closedPosition_.totalFundingRatePaidUsd = uint96(_interestFunding);

    closedPosition_.pnlUsd = (_pnlUsd);
    closedPosition_.totalPayoutUsd = (marginLeftUsd_);

    emit PositionClosedInLoss(_positionKey, marginLeftUsd_);

    return (closedPosition_, marginAssetAmount_, feesPaid_);
  }

  function _takeUsdMarginOfPlayer(address _player, uint256 _marginAmountUsd) internal {
    unchecked {
      totalActiveMarginInUsd -= _marginAmountUsd;
      playerMarginInUsd[_player] -= _marginAmountUsd;
    }
  }

  function _checkIfPriceMoveIsSufficientToClose(uint256 _priceMovePercentage) internal pure {
    require(
      _priceMovePercentage >= minPriceMove,
      "DegenPoolManager: price move percentage is too low to close"
    );
  }

  /**
   * @notice Function to calculate the price move percentage.
   * @param _openPrice The open price of the position.
   * @param _closePrice The close price of the position.
   */
  function _calculatePriceMovePercentage(
    uint256 _openPrice,
    uint256 _closePrice
  ) internal pure returns (uint256 priceMovePercentage_) {
    int256 diff_;
    unchecked {
      diff_ = int256(_closePrice) - int256(_openPrice);
      // if the diff is negative, make it positive
      diff_ < 0 ? diff_ = diff_ * -1 : diff_;
      priceMovePercentage_ = (uint256(diff_) * SCALE) / _openPrice;
    }
  }

  /**
   * @notice Function to calculate the shift amount based on the position size.
   * @notice The shift amount is used to shift the fee curve based on the position size.
   * @param _positionSize The size of the position for which the shift amount is calculated.
   */
  function _shiftByPositionSize(uint256 _positionSize) internal pure returns (uint256 result) {
    int256 result_;
    // position size * factor is always greater than -factor since position size is positive, so result_ is always positive
    // factor is constant and _position size can not be greater than the maxPositionSize(constant) so the result is limited
    unchecked {
      result_ = (-factor + (int256(_positionSize) * factor)) / int256(10 ** 13);
    }
    return (uint256(result_));
  }

  /**
   * @notice This function calculates the maximum fee for a position.
   *         The max fee is determined based on the size of the position,
   *         with larger positions incurring higher fees.
   * @param _positionSize The size of the position for which the max fee is calculated.
   * @return  maxFee_ The calculated maximum fee for the given position size.
   */
  function _calculateMaxFee(uint256 _positionSize) internal pure returns (uint256 maxFee_) {
    /**
     * Calculate the difference between max fee at max position size (which is 82% default)
     * and max fee at min position size (which is 50% default)
     */

    uint256 diff_ = maxFeeAtMaxPs - maxFeeAtMinPs;
    uint256 diffScaled_ = diff_ * SCALE * SCALE;
    uint256 positionRange_ = maxPositionSize - minPositionSize;

    // Calculate the fee using linear interpolation
    maxFee_ =
      (diffScaled_ * (_positionSize - minPositionSize)) /
      (positionRange_ * SCALE * SCALE) +
      maxFeeAtMinPs;
  }

  function _calculateProfitFee(
    uint256 _priceMove,
    uint256 _positionSize
  ) internal pure returns (uint256) {
    // convert the position size to 1e8 because the pnl fee model the scaling for usd and percentages are both 1e8 (SCALE). The rest of the contract uses 1e18 for usd and 1e6 for percentages
    _positionSize = _positionSize / 1e10;
    // calculate the max fee
    uint256 maxFeeForPositionSize_ = _calculateMaxFee(_positionSize);

    // calculate the shift amount based on the position size
    // shift amount will be add to the result of the fee calculation to shift the fee curve
    uint256 shiftAmount_ = _shiftByPositionSize(_positionSize);

    // Check if the provided price move is within the specified range
    if (maxPriceMove > _priceMove && _priceMove >= minPriceMove) {
      // Calculate the fee using linear interpolation
      return
        shiftAmount_ +
        maxFeeForPositionSize_ -
        ((maxFeeForPositionSize_ - minFee) * (_priceMove - minPriceMove)) /
        (maxPriceMove - minPriceMove);
    } else {
      // If the price move is out of the specified range, return the min fee
      // it means the price move is greater than the max price move, it should return the min fee
      return minFee;
    }
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

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../interfaces/vault/IFeeCollector.sol";
import "../../../interfaces/vault/ITokenManager.sol";
import "../../../interfaces/vault/IReferralStorage.sol";
import "../../../interfaces/core/ILuckyStrikeMaster.sol";
import "../../../interfaces/vault/IVault.sol";
import "./interfaces/IDegenPoolManagerSettings.sol";
import "../../../interfaces/core/ISwap.sol";

/**
 * @title DegenPoolManagerSettings
 * @author balding-ghost
 * @notice The DegenPoolManagerSettings contract is used to store all the settings for the DegenPoolManager contract.
 */
contract DegenPoolManagerSettings is IDegenPoolManagerSettings, AccessControl, Pausable {
  uint256 public constant BASIS_POINTS = 1e6; // 100%
  uint256 public constant SCALE = 1e8;
  uint256 public constant VAULT_SCALING_INCREASE_FOR_USD = 1e12;
  uint256 internal constant PRICE_PRECISION = 1e18;

  bytes32 public constant ADMIN_MAIN = bytes32(keccak256("ADMIN_MAIN"));
  bytes32 public constant ROUTER_ROLE = bytes32(keccak256("ROUTER_ROLE"));
  bytes32 public constant VAULT_ROLE = bytes32(keccak256("VAULT"));

  /// @notice Vault address
  IVault public immutable vault;
  bytes32 public immutable pythAssetId;
  IERC20 public immutable stableCoin;
  uint256 public immutable decimalsStableCoin;
  uint256 public immutable additionalPrecisionComparedToStableCoin;

  ISwap public swap;

  // @notice Fee settings

  // @note for auditor the python fee model we used had scaling for 1 usd of 1e8 and for percentages scaling of 1e8 as well. so the configs here reflect that.

  // @notice The maximum fee at the maximum position size, occurring at a 0.01% price move, is 82% of the profit.
  uint256 public constant maxFeeAtMaxPs = 82000000;
  // @notice The maximum fee at the minimum position size, occurring at a 0.01% price move, is 50% of the profit.
  uint256 public constant maxFeeAtMinPs = 50000000;
  // @notice The maximum position size in dollar value 1m$ * 1e8
  uint256 public constant maxPositionSize = 1000000 * SCALE;
  // @notice The minimum position size in dollar value 1$ * 1e8
  uint256 public constant minPositionSize = 1 * SCALE;
  // @notice The minimum fee percentage 10%
  uint256 public constant minFee = 10000000;
  // @notice The minimum price move percentage
  uint256 public constant minPriceMove = 10000;
  // @notice The maximum price move percentage 10%
  // @notice The pnl fee will be fixed after this price move
  // @notice The pnl fee will be 10% after this price move
  uint256 public constant maxPriceMove = 10000000;

  int256 public constant factor = int256(500001);

  address public degenGameContract;

  mapping(address => bool) public degenGameControllers;

  constructor(
    address _vault,
    address _swap,
    bytes32 _pythAssetId,
    address _admin,
    address _stableCoinAddress,
    uint256 _decimalsStableCoin
  ) {
    pythAssetId = _pythAssetId;
    vault = IVault(_vault);
    swap = ISwap(_swap);
    degenGameControllers[address(this)] = true;

    stableCoin = IERC20(_stableCoinAddress);
    decimalsStableCoin = _decimalsStableCoin;
    additionalPrecisionComparedToStableCoin = 10 ** (18 - _decimalsStableCoin);

    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    _setupRole(ADMIN_MAIN, _admin);
  }

  modifier onlyAdmin() {
    require(hasRole(ADMIN_MAIN, msg.sender), "DegenPoolManager: only admin main");
    _;
  }

  modifier onlyRouter() {
    require(hasRole(ROUTER_ROLE, msg.sender), "DegenPoolManager: only router");
    _;
  }

  modifier onlyDegenGame() {
    require(msg.sender == degenGameContract, "DegenPoolManager: only degen game");
    _;
  }

  // Contract configuration

  function setSwap(address _swap) external onlyAdmin {
    swap = ISwap(_swap);
  }

  function setDegenGameContract(address _degenGameContract) external onlyAdmin {
    require(degenGameContract == address(0), "DegenPoolManager: already set");
    degenGameContract = _degenGameContract;
    emit DegenGameContractSet(_degenGameContract);
  }

  function addRouter(address _router, bool _setting) external onlyAdmin {
    if (_setting) {
      grantRole(ROUTER_ROLE, _router);
    } else {
      revokeRole(ROUTER_ROLE, _router);
    }
  }

  function setDegenGameController(
    address _degenGameController,
    bool _isDegenGameController
  ) external onlyAdmin {
    degenGameControllers[_degenGameController] = _isDegenGameController;
    emit DegenGameControllerSet(_degenGameController, _isDegenGameController);
  }

  function isDegenGameController(
    address _degenGameController
  ) external view returns (bool isController_) {
    isController_ = degenGameControllers[_degenGameController];
  }
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

interface IFeeCollector {
  function calcFee(uint256 _amount) external view returns (uint256);

  function onIncreaseFee(address _token) external;

  function onVolumeIncrease(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITokenManager {
  function mintVestedWINR(address _input, uint256 _amount, address _recipient) external returns (uint256 mintedAmount_);
  function takeVestedWINR(address _from, uint256 _amount) external;
  function burnVestedWINR(uint256 _amount) external;
  function increaseVolume(address _input, uint256 _amount) external;
  function decreaseVolume(address _input, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IReferralStorage {
  function setReward(address _player, address _token, uint256 _amount) external returns (uint256 _reward);
  function removeReward(address _player, address _token, uint256 _amount) external; 
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILuckyStrikeMaster {
  event LuckyStrikePayout(address indexed player, uint256 wonAmount);
  event DeleteTokenFromWhitelist(address indexed token);
  event TokenAddedToWhitelist(address indexed token);
  event SyncTokens();
  event GameRemoved(address indexed game);
  event GameAdded(address indexed game);
  event DeleteAllWhitelistedTokens();
  event LuckyStrike(address indexed player, uint256 wonAmount, bool won);

  function hasLuckyStrike(
    uint256 _randomness,
    uint256 _wagerUSD
  ) external view returns (bool hasWon_);

  function valueOfLuckyStrikeJackpot() external view returns (uint256 valueTotal_);

  function processLuckyStrike(address _player) external returns (uint256 wonAmount_);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}