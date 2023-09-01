// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./DegenPoolManagerSettings.sol";
import "./interfaces/IDegenPoolManager.sol";
import "./interfaces/IDegenBase.sol";

// import "forge-std/Test.sol";

/**
 * @title DegenPoolManager
 * @author balding-ghost
 * @notice The DegenPoolManager contract is used to handle the funds (similar the the VaultManager contract).  The contract handles liquidations and position closures. The contract also handles the fees that are paid to the protocol and the liquidators. The contract also handles the payouts of the players. It is generally the contract where most is configured and most payout/liquidation logic is handled.
 */
contract DegenPoolManager is IDegenPoolManager, DegenPoolManagerSettings, ReentrancyGuard {
  // total of the asset that has been credited to players
  uint256 public totalRealizedProfits;

  // total of the asset that has been debited from players
  uint256 public totalRealizedLosses;

  uint256 public maxLossesAllowed;

  // total amount of theoretical bad debt that wlps have endured (not real just metric of bad/inefficient liquidation)
  // this value can be used for seperating wlp profits, bribes, feecollector etc (if we want to)
  // note this can be deleted if we don't want to use it (has no usage outside of analytics/tracking)
  uint256 public totalTheoreticalBadDebt;

  // close fee protocol is the fee that is paid to the protocol when a position is closed in profit
  // close fees are part of the realized profits of the protocol
  // note this can be deleted if we don't want to use it (has no usage outside of analytics/tracking)
  uint256 public totalCloseFeeProtocolPartition;

  // total amount of funding rate that has been paid by positions
  // funding rate is part of the realized profits of the protocol
  // note this can be deleted if we don't want to use it (has no usage outside of analytics/tracking)
  uint256 public totalFundingRatePartition;

  uint256 public totalLiquidatorFees;

  // // percentage of the collected funding fee that is paid to the fee collector
  // uint256 public fundingFeeRatioForFeeCollector;

  // percentage of th net profits that is paid to the fee collector
  uint256 public degenProfitRatioForFeeCollector;

  // total amount of escrowed tokens in the contract (of openPositions)
  uint256 public totalEscrowTokens;

  // liquidation threshold is the threshold at which a position can be liquidated (margin level of the position)
  uint256 public liquidationThreshold;

  // amount of tokens in the payout buffer of the vault, every time a player is credited assets (so is in profit) the payout of the player is deducted from this buffer, if the buffer is empty the player will still be credited for his profits but the payout will be delayed until the buffer is filled again. this is done to airgap the vault and these new contracts. this also means that for this contract to work the vault needs to fund it with tokens (like a debit card).
  // uint256 public payoutBufferDegen; // tldr this is like a debit card

  // amount of tokens escrowed per player (of openOrders and openPositions)
  mapping(address => uint256) public playerEscrow;

  // amount of tokens liquidators can claim as a reward for liquidating positions
  mapping(address => uint256) public liquidatorFees;

  // amount of tokens credited to players (player profits or returned partial margins)
  mapping(address => uint256) public playerCredit;

  mapping(uint256 => uint256) public positionSizeCategory;

  // max percentage of the margin amount that can be paid as a liquidation fee to liquidator, scaled 1e6
  uint256 public maxLiquidationFee;

  // min percentage of the margin amount that can be paid as a liquidation fee to liquidator, scaled 1e6
  uint256 public minLiquidationFee;

  constructor(
    address _vaultAddress,
    address _targetToken,
    bytes32 _pythAssetId,
    address _admin
  ) DegenPoolManagerSettings(_vaultAddress, _targetToken, _pythAssetId, _admin) {}

  function transferInMargin(address _player, uint256 _marginAmount) external onlyRouter {
    unchecked {
      totalEscrowTokens += _marginAmount;
      playerEscrow[_player] += _marginAmount;
    }
  }

  /**
  @notice this function processes the profit and losses of the vault and distributes them to the vault and the feecollector 
  @dev  we 'pay' the feecollector via the vaults mechanism
   */
  function processDegenProfitsAndLosses() external onlyAdmin {
    uint256 _totalRealizedProfits = totalRealizedProfits;
    uint256 _totalRealizedLosses = totalRealizedLosses;
    totalRealizedProfits = 0;
    totalRealizedLosses = 0;
    if (_totalRealizedProfits > _totalRealizedLosses) {
      // the degen contract has made a profit
      uint256 _profit = totalRealizedProfits - totalRealizedLosses;
      // calculate how much of the profit is for the feecollector
      uint256 _forFeeCollector = (_profit * degenProfitRatioForFeeCollector) / BASIS_POINTS;
      // transfer the profit to the vault
      targetMarketToken.transfer(address(vault), _forFeeCollector);
      // pay it in as wager fee, so that it can be collected by the feecollector
      vault.payinWagerFee(address(targetMarketToken));

      // calculate how much of the profit is for the vaults WLPs
      uint256 _forVault = _profit - _forFeeCollector;

      // transfer the profit to the vault
      targetMarketToken.transfer(address(vault), _forVault);
      // pay it in as profit, so that it can be collected by the vault
      vault.payinPoolProfits(address(targetMarketToken));

      emit DegenProfitsAndLossesProcessed(
        _totalRealizedProfits,
        _totalRealizedLosses,
        _forVault,
        _forFeeCollector
      );
    } else {
      // the degen contract has made a loss, nothing to distribute
      emit DegenProfitsAndLossesProcessed(_totalRealizedProfits, _totalRealizedLosses, 0, 0);
    }
  }

  function clearAllTotals() external onlyAdmin {
    emit AllTotalsCleared(
      totalTheoreticalBadDebt,
      totalCloseFeeProtocolPartition,
      totalFundingRatePartition
    );
    totalTheoreticalBadDebt = 0;
    totalCloseFeeProtocolPartition = 0;
    totalFundingRatePartition = 0;
  }

  /**
   * @notice function calculates the percentage fee the protocol charges for closing the position
   * @dev the fee is calculated based on the size of the position, the duration  the position was open and the roi of the position.
   * @param _positionSize the size of the position
   * @param _priceMovePercentage the roi of the position
   * @param _passedTimeInSeconds the duration the position was open
   */
  function percentageCutFromProfit(
    uint256 _positionSize,
    uint256 _priceMovePercentage,
    uint256 _passedTimeInSeconds
  ) public view returns (uint256 closeFeePercentageProtocol_) {
    // Initialize the totalCut_ with the default fee value (1%).
    uint256 totalCut_ = defaultFee;

    // Calculate the duration of the position in minutes.
    uint256 minutes_ = _passedTimeInSeconds / 1 minutes;

    // Define the penalty threshold for the price move percentage.
    uint256 penaltyThreshold_ = 1e8; // 100%

    // Calculate the initial cut based on the position size.
    uint256 initialCut_ = _categorizePositionSize(_positionSize);

    // Calculate the cut equivalent for a 1% change in the position size.
    uint256 cutForPerPercent_ = (initialCut_ * BASIS_POINTS) / 1e8; // BASIS_POINTS is 1e6

    // Calculate the effect of time on the cut.
    uint256 timeEffect_ = cutForPerPercent_ * minutes_;

    // Calculate the effect of the price move on the cut.
    uint256 priceEffect_ = ((cutForPerPercent_) * uint256(_priceMovePercentage)) / BASIS_POINTS;

    // Check conditions to adjust the total cut.
    if (_priceMovePercentage < penaltyThreshold_ && minutes_ < 100) {
      // If both the price move and duration are below certain thresholds, adjust the total cut.
      totalCut_ = initialCut_ - priceEffect_ - timeEffect_;
    }

    // Ensure the total cut is not lower than the default fee.
    return totalCut_ < defaultFee ? defaultFee : totalCut_;
  }

  function _categorizePositionSize(uint256 _positionSize) internal view returns (uint256) {
    for (uint256 i = 0; i < 11; i++) {
      uint256 thr = i * 1000;
      uint256 _thr = thr * BASIS_POINTS;

      if (_positionSize < _thr) {
        return feeThresholds[thr];
      }
    }
    return defaultFee;
  }

  function transferOutMarginCancel(address _player, uint256 _marginAmount) external onlyRouter {
    targetMarketToken.transfer(_player, _marginAmount);
    totalEscrowTokens -= _marginAmount;
    playerEscrow[_player] -= _marginAmount;
  }

  /**
   * @notice this function is called when a position is closed. it calculates the net profit/loss of the position and credits the player with the profit/loss minus the protocol fee.
   * @dev the protocol fee is calculated based on the size of the position, the duration of the position and the roi of the position.
   * @param _positionKey the key of the position
   * @param _caller the caller of the position
   * @param _assetPrice the price of the asset at the time of closing
   * @param _positionSize the size of the position
   * @param _positionDuration the duration of the position
   * @param _marginAmount the margin amount of the position
   * @param _interestFunding the total funding rate paid by the position
   * @param _maxPositionProfit the maximum profit the position could have made
   * @param _pnlWithInterest the pnl of the position including interest paid/due
   * @return closedPosition_ the closed position info
   */
  function closePosition(
    bytes32 _positionKey,
    address _caller,
    uint256 _assetPrice,
    uint256 _positionSize,
    uint256 _positionDuration,
    uint256 _marginAmount,
    uint256 _interestFunding,
    uint256 _maxPositionProfit,
    int256 _pnlWithInterest
  ) external onlyDegenGame returns (ClosedPositionInfo memory closedPosition_) {
    if (_pnlWithInterest > 0) {
      // pnl is positive, position is closed in profit
      closedPosition_ = _closePositionInProfit(
        _positionKey,
        _caller,
        _assetPrice,
        _positionSize,
        _positionDuration,
        _marginAmount,
        _interestFunding,
        _maxPositionProfit,
        _pnlWithInterest
      );
    } else {
      // pnl is negative, position is closed in loss
      closedPosition_ = _closePositionInLoss(
        _positionKey,
        _caller,
        _assetPrice,
        _positionSize,
        _positionDuration,
        _marginAmount,
        _interestFunding,
        _maxPositionProfit,
        _pnlWithInterest
      );
    }

    return closedPosition_;
  }

  /**
   * @notice this function is called when a position is liquidated.
   * @param _positionKey the key of the position
   * @param _player the player of the position
   * @param _liquidator the liquidator of the position
   * @param _positionDuration the duration of the position
   * @param _marginAmount the margin amount of the position
   * @param _interestFunding the total funding rate paid by the position
   * @param _assetPrice the price of the asset at the time of closing
   * @param _pnlWithInterest the pnl of the position including interest paid/due
   * @return closedPosition_ the closed position info
   */
  function processLiquidationClose(
    bytes32 _positionKey,
    address _player,
    address _liquidator,
    uint256 _positionDuration,
    uint256 _marginAmount,
    uint256 _interestFunding,
    uint256 _assetPrice,
    uint256 _pnlWithInterest
  ) external onlyDegenGame returns (ClosedPositionInfo memory closedPosition_) {
    _takeMarginOfPlayer(_player, _marginAmount);

    closedPosition_.player = _player;
    closedPosition_.liquidatorAddress = _liquidator;
    closedPosition_.timestampClosed = uint32(block.timestamp);
    closedPosition_.positionDuration = uint32(_positionDuration);
    closedPosition_.priceClosed = uint96(_assetPrice);
    closedPosition_.totalFundingRatePaid = uint96(_interestFunding);
    closedPosition_.totalPayout = 0;
    closedPosition_.marginAmountLeft = 0;
    closedPosition_.pnlWithInterest = -1 * int256(_pnlWithInterest);

    // calculate the protocol profit and the liquidator fee
    (
      uint256 protocolProfit_,
      uint256 liquidatorFee_,
      uint256 theoreticalBadDebt_
    ) = computeLiquidationReward(_marginAmount, _pnlWithInterest);

    // note uncessary check remove later
    require(protocolProfit_ + liquidatorFee_ == _marginAmount, "DegenPoolManager: invalid fee");

    /**
     * If we want to seperate the bribes and the wagerfee we can do that with harvest functions
     * or i am also fine to do it automatically but i prefer to keep the contracts airgapped initially
     * so that we can control and monitor it better
     */

    closedPosition_.closeFeeProtocol = 0; // closeFee only charged on closing of profitable positio
    closedPosition_.liquidationFeePaid = uint96(liquidatorFee_);

    unchecked {
      totalLiquidatorFees += liquidatorFee_;
      liquidatorFees[_liquidator] += liquidatorFee_;
      totalRealizedProfits += protocolProfit_;
      totalFundingRatePartition += _interestFunding;
      // note theoretical debt isn't real debt, it is the difference between the margin amount and the negative pnl of the position (this only is non zero if the position was liquidated at a point where the margin was worth less as the PNL). it is more an indicator of inefficiency of the liquidation mechanism.
      totalTheoreticalBadDebt += theoreticalBadDebt_;
    }

    emit PositionLiquidated(
      _positionKey,
      _marginAmount,
      protocolProfit_,
      liquidatorFee_,
      theoreticalBadDebt_
    );

    return closedPosition_;
  }

  /**
   * @notice this function is part of the liquidation incentive mechanism.its purpose is to calculate how much the liquidator will receive as a reward for liquidating a position.
   * @dev the reward is calculated as a percentage of the margin amount of the position. the percentage is calculated based on the distance between the liquidation threshold and the effective margin level of the position.
   * @dev the closer the liquidator is to the liquidation threshold, the higher the reward will be.
   * @param _marginAmount amount of margin the position had
   * @param _pnl amount of negative pnl the position had (including interest)
   * @return protocolProfit_ the amount of tokens the protocol will receive as a fee for the position
   * @return liquidatorFee_ the amount of tokens the liquidator will receive as a reward for liquidating the position
   * @return theoreticalBadDebt_ the amount of tokens that on paper have been lost by the protocol. this is the difference between the margin amount and the negative pnl of the position (this only is non zero if the position was liquidated at a point where the margin was worth less as the PNL)
   */
  function computeLiquidationReward(
    uint256 _marginAmount,
    uint256 _pnl
  )
    public
    view
    returns (uint256 protocolProfit_, uint256 liquidatorFee_, uint256 theoreticalBadDebt_)
  {
    // compute the liquidation threshold of the position.
    uint256 liquidationMarginLevel_ = (_marginAmount * liquidationThreshold) / BASIS_POINTS;

    require(
      _pnl >= liquidationMarginLevel_,
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
      uint256 liquidationDistance_ = _pnl - liquidationMarginLevel_;

      uint256 thresHoldDistance_ = _marginAmount - liquidationMarginLevel_;

      if (liquidationDistance_ == 0) {
        // the liquidator has liquiated the position at the liquidation threshold this is the best result (so position was liquidated on the exact cent it became liquitable)
        liquidatorFee_ = (_marginAmount * maxLiquidationFee) / BASIS_POINTS;
        protocolProfit_ = _marginAmount - liquidatorFee_;
        theoreticalBadDebt_ = 0;
      } else if (liquidationDistance_ >= thresHoldDistance_) {
        // the liquidator has liquiated the position at the point where it couldn't have been any more negative
        liquidatorFee_ = (_marginAmount * minLiquidationFee) / BASIS_POINTS;
        protocolProfit_ = _marginAmount - liquidatorFee_;
        theoreticalBadDebt_ = liquidationDistance_ - thresHoldDistance_;
      } else {
        // the liquidator has liquidated the position between the threshold and the point where it couldn't have been any more negative
        // Compute slope of the line scaled by BASIS_POINTS
        uint256 slope_ = ((maxLiquidationFee - minLiquidationFee) * BASIS_POINTS) /
          thresHoldDistance_;
        uint256 rewardPercentage_ = maxLiquidationFee -
          ((slope_ * liquidationDistance_) / BASIS_POINTS); // Remember to scale down after multiplication
        liquidatorFee_ = (_marginAmount * rewardPercentage_) / BASIS_POINTS;
        protocolProfit_ = _marginAmount - liquidatorFee_;
        theoreticalBadDebt_ = 0;
      }
    }
  }

  function claimLiquidationFees() external nonReentrant {
    uint256 liquidatorFee_ = liquidatorFees[msg.sender];
    liquidatorFees[msg.sender] = 0;
    targetMarketToken.transfer(msg.sender, liquidatorFee_);
    emit ClaimLiquidationFees(liquidatorFee_);
  }

  function incrementMaxLossesBuffer(uint256 _maxLossesIncrease) external onlyAdmin {
    maxLossesAllowed += _maxLossesIncrease;
    emit IncrementMaxLosses(_maxLossesIncrease, maxLossesAllowed);
  }

  // function incrementMaxLossesBuffer(uint256 _maxLossesIncrease) external onlyAdmin {
  //   vault.payoutNoEscrow(address(targetMarketToken), address(this), _maxLossesIncrease);
  //   maxLossesAllowed += _maxLossesIncrease;
  //   emit incrementMaxLossesBuffer(_maxLossesIncrease);
  // }

  function setDegenProfitForFeeCollector(
    uint256 _degenProfitRatioForFeeCollector
  ) external onlyAdmin {
    degenProfitRatioForFeeCollector = _degenProfitRatioForFeeCollector;
    emit SetDegenProfitForFeeCollector(_degenProfitRatioForFeeCollector);
  }

  // function setFeeRatioForFeeCollector(
  //   uint256 _fundingFeeRatioForFeeCollector
  // ) external onlyAdmin {
  //   fundingFeeRatioForFesseCollector = _fundingFeeRatioForFeeCollector;
  //   emit SetFeeRatioForFeeCollector(_fundingFeeRatioForFeeCollector);
  // }

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

  function setLiquidationThreshold(uint256 _liquidationThreshold) external onlyAdmin {
    require(_liquidationThreshold <= BASIS_POINTS, "DegenPoolManager: invalid threshold");
    IDegenBase(degenGameContract).setLiquidationThreshold(_liquidationThreshold);
    liquidationThreshold = _liquidationThreshold;
    emit SetLiquidationThreshold(_liquidationThreshold);
  }

  // function returnVaultReserve() external view returns (uint256 vaultReserve_) {
  //   uint256 vaultReserveUsd_ = vault.getReserve();
  //   vaultReserve_ = vault.usdToTokenMin(address(targetMarketToken), vaultReserveUsd_);
  //   require(vaultReserve_ != 0, "DegenPoolManager: vault reserve is 0");
  // }

  function returnVaultReserve() external view returns (uint256 vaultReserve_) {
    vaultReserve_ = vault.getReserve();
    require(vaultReserve_ != 0, "DegenPoolManager: vault reserve is 0");
  }

  // internal functions

  /**
   * @notice this function is called when a position is closed in profit. it calculates the net profit of the position and credits the player with the profit minus the protocol fee.
   * @dev the protocol fee is calculated based on the size of the position, the duration of the position and the roi of the position.
   * @param _positionKey the key of the position
   * @param _player the player of the position
   * @param _assetPrice the price of the asset at the time of closing
   * @param _positionSize the size of the position
   * @param _positionDuration the duration of the position
   * @param _marginAmount the margin amount of the position
   * @param _interestFunding the total funding rate paid by the position
   * @param _maxPositionProfit the maximum profit the position could have made
   * @param _pnlWithInterest the pnl of the position including interest paid/due
   * @return closedPosition_ the closed position info
   */
  function _closePositionInProfit(
    bytes32 _positionKey,
    address _player,
    uint256 _assetPrice,
    uint256 _positionSize,
    uint256 _positionDuration,
    uint256 _marginAmount,
    uint256 _interestFunding,
    uint256 _maxPositionProfit,
    int256 _pnlWithInterest
  ) internal returns (ClosedPositionInfo memory closedPosition_) {
    // credit the player with their margin
    _takeMarginOfPlayer(_player, _marginAmount);

    // calculate the net profit of the position
    (uint256 payOutMinusFeeAmount_, uint256 closeFeeProtocol_) = _calculateNetProfitOfPosition(
      _marginAmount,
      _positionSize,
      _positionDuration,
      _maxPositionProfit,
      _pnlWithInterest,
      _interestFunding
    );

    _creditPayoutToPlayer(_player, payOutMinusFeeAmount_ + _marginAmount);

    unchecked {
      totalRealizedLosses += payOutMinusFeeAmount_;
      totalCloseFeeProtocolPartition += closeFeeProtocol_;
      totalFundingRatePartition += _interestFunding;
    }

    closedPosition_.player = _player;
    closedPosition_.liquidatorAddress = address(0x0);
    closedPosition_.timestampClosed = uint32(block.timestamp);
    closedPosition_.positionDuration = uint32(_positionDuration);
    closedPosition_.priceClosed = uint96(_assetPrice);
    closedPosition_.totalFundingRatePaid = uint96(_interestFunding);
    closedPosition_.closeFeeProtocol = uint96(closeFeeProtocol_);
    closedPosition_.liquidationFeePaid = 0;
    closedPosition_.totalPayout = uint96(payOutMinusFeeAmount_);
    closedPosition_.marginAmountLeft = uint96(_marginAmount);
    closedPosition_.pnlWithInterest = _pnlWithInterest;

    _payoutPlayerCredit(_player);

    emit PositionClosedInProfit(_positionKey, payOutMinusFeeAmount_, closeFeeProtocol_);

    return closedPosition_;
  }

  /**
   * @notice this function calculates the net profit of a position. it takes into account the size of the position, the duration of the position and the roi of the position.
   * @dev the roi is calculated as the pnl of the position divided by the margin amount of the position.
   * @dev the roi is then used to calculate the protocol fee. the protocol fee is calculated based on the size of the position, the duration of the position and the roi of the position.
   * @param _marginAmount the margin amount of the position(wager)
   * @param _positionSize the size of the position
   * @param _positionDuration the duration of the position
   * @param _maxPositionProfit the maximum profit the position could have made
   * @param _pnlWithInterest the pnl of the position including interest paid/due
   * @return payoutAmount_ the amount of tokens the player will receive as a payout
   * @return closeFeeProtocol_ the amount of tokens the protocol will receive as a fee
   */
  function _calculateNetProfitOfPosition(
    uint256 _marginAmount,
    uint256 _positionSize,
    uint256 _positionDuration,
    uint256 _maxPositionProfit,
    int256 _pnlWithInterest,
    uint256 _interestFunding
  ) internal view returns (uint256 payoutAmount_, uint256 closeFeeProtocol_) {
    uint256 pnlWithInterest_ = uint256(_pnlWithInterest);
    if (pnlWithInterest_ > _maxPositionProfit) {
      pnlWithInterest_ = _maxPositionProfit;
    }

    // placeholder code since it underflows!
    payoutAmount_ = (pnlWithInterest_ * 65 * 1e4) / BASIS_POINTS;
    closeFeeProtocol_ = pnlWithInterest_ - payoutAmount_;
    return (payoutAmount_, closeFeeProtocol_);

    // uint256 _priceMove = (uint256(_pnlWithInterest) + _interestFunding) / (_positionSize);

    // uint256 roiPercentage_ = _percentageROI(
    //   _marginAmount,
    //   _positionSize,
    //   _priceMove,
    //   _positionDuration
    // );

    // payoutAmount_ = _marginAmount + ((_marginAmount * roiPercentage_) / BASIS_POINTS);
    // closeFeeProtocol_ = pnlWithInterest_ - payoutAmount_;
  }

  function claimPlayerCredits() external nonReentrant returns (uint256 payoutAmount_) {
    payoutAmount_ = _payoutPlayerCredit(msg.sender);
  }

  function claimForPlayer(address _player) external nonReentrant returns (uint256 payoutAmount_) {
    // todo note everybody can call this function access if we want that (but i see no downside)
    payoutAmount_ = _payoutPlayerCredit(_player);
  }

  function returnNetResult() external view returns (uint256 netResult_, bool isPositive_) {
    if (totalRealizedProfits > totalRealizedLosses) {
      netResult_ = totalRealizedProfits - totalRealizedLosses;
      isPositive_ = true;
    } else {
      netResult_ = totalRealizedLosses - totalRealizedProfits;
      isPositive_ = false;
    }
  }

  function returnPayoutBufferLeft() external view returns (uint256 payoutBufferLeft_) {
    uint256 _totalMaxPayout = totalRealizedProfits + maxLossesAllowed;
    if (totalRealizedLosses > _totalMaxPayout) {
      payoutBufferLeft_ = 0;
    } else {
      payoutBufferLeft_ = _totalMaxPayout - totalRealizedLosses;
    }
  }

  function checkPayoutAllowed(uint256 _amountPayout) external view returns (bool isAllowed_) {
    return _checkPayoutAllowed(_amountPayout);
  }

  function _checkPayoutAllowed(uint256 _amountPayout) internal view returns (bool isAllowed_) {
    uint256 _totalLosses_ = totalRealizedLosses + _amountPayout;
    uint256 _totalMaxPayout = totalRealizedProfits + maxLossesAllowed;
    if (_totalLosses_ > _totalMaxPayout) {
      isAllowed_ = false;
    } else {
      isAllowed_ = true;
    }
  }

  function _payoutPlayerCredit(address _player) internal returns (uint256 payoutAmount_) {
    uint256 playerCredit_ = playerCredit[_player];
    if (!_checkPayoutAllowed(playerCredit_)) {
      emit InsufficientBuffer(_player, playerCredit_);
      // note this is temporary for testing reasons in real deploys this is removed
      revert("DegenPoolManager: insufficient buffer");
      IDegenBase(degenGameContract).setOpenOrderAllowed(false);
      IDegenBase(degenGameContract).setOpenPositionAllowed(false);
      return 0;
    }
    if (playerCredit_ > 0) {
      playerCredit[_player] = 0;
      vault.payoutNoEscrow(address(targetMarketToken), _player, playerCredit_);
      emit PlayerCreditClaimed(_player, playerCredit_);
      return playerCredit_;
    } else {
      emit NoCreditToClaim(_player);
      return 0;
    }
  }

  function getPlayerCredit(address _player) external view returns (uint256 playerCredit_) {
    return playerCredit[_player];
  }

  // function _payoutPlayerCredit(address _player) internal returns (uint256 payoutAmount_) {
  //   uint256 playerCredit_ = playerCredit[_player];
  //   if (maxLossesAllowed < playerCredit_) {
  //     emit InsufficientBuffer(_player, playerCredit_);
  //     IDegenBase(degenGameContract).setOpenOrderAllowed(false);
  //     IDegenBase(degenGameContract).setOpenPositionAllowed(false);
  //     return 0;
  //   }
  //   if (playerCredit_ > 0) {
  //     playerCredit[_player] = 0;
  //     unchecked {
  //       maxLossesAllowed -= playerCredit_;
  //     }
  //     targetMarketToken.transfer(_player, playerCredit_);
  //     emit PlayerCreditClaimed(_player, playerCredit_);
  //     return playerCredit_;
  //   } else {
  //     emit NoCreditToClaim(_player);
  //     return 0;
  //   }
  // }

  /**
   * @notice this function is called when a position is closed in loss. it calculates the net loss of the position and credits the player with the margin amount left.
   * @dev the margin amount left is the amount of margin that is left after the position is closed. if the position is liquidated, the margin amount left is 0.
   * @param _positionKey the key of the position
   * @param _player the player of the position
   * @param _assetPrice the price of the asset at the time of closing
   * @param _positionDuration the duration of the position
   * @param _marginAmount the margin amount of the position
   * @param _interestFunding the total funding rate paid by the position
   * @param _pnlWithInterest the pnl of the position including interest paid/due
   * @return closedPosition_ the closed position info
   */
  function _closePositionInLoss(
    bytes32 _positionKey,
    address _player,
    uint256 _assetPrice,
    uint256,
    uint256 _positionDuration,
    uint256 _marginAmount,
    uint256 _interestFunding,
    uint256,
    int256 _pnlWithInterest
  ) internal returns (ClosedPositionInfo memory closedPosition_) {
    _takeMarginOfPlayer(_player, _marginAmount);
    // pnl is negative so we make it positive so we can calculate with it
    uint256 pnlWithInterest_ = uint256(-1 * _pnlWithInterest);
    uint256 marginLeft_;
    if (pnlWithInterest_ >= _marginAmount) {
      // the position is in liquidated in fact, no margin left, player effectively liquiates himself rekt
      // since it is a self liquidation there is no liquidation threshold, we also pay no fees to the self liquidator
      unchecked {
        totalRealizedProfits += _marginAmount;
        // note we don't add to totalTheoreticalBadDebt here because this is not a real liquidation, so we do not know the value easily
      }
    } else {
      // the position is closed in loss, there is margin left
      unchecked {
        marginLeft_ = _marginAmount - pnlWithInterest_;
        totalRealizedProfits += pnlWithInterest_;
      }
      _creditPayoutToPlayer(_player, marginLeft_);
    }

    unchecked {
      totalFundingRatePartition += _interestFunding;
    }

    closedPosition_.player = _player;
    closedPosition_.liquidatorAddress = address(0x0);
    closedPosition_.timestampClosed = uint32(block.timestamp);
    closedPosition_.positionDuration = uint32(_positionDuration);
    closedPosition_.priceClosed = uint96(_assetPrice);
    closedPosition_.liquidationFeePaid = 0;
    closedPosition_.totalPayout = 0;
    closedPosition_.totalFundingRatePaid = uint96(_interestFunding);
    closedPosition_.closeFeeProtocol = uint96(0);
    closedPosition_.marginAmountLeft = uint96(marginLeft_);
    closedPosition_.pnlWithInterest = _pnlWithInterest;

    _payoutPlayerCredit(_player);

    emit PositionClosedInLoss(_positionKey, marginLeft_);

    return closedPosition_;
  }

  function _creditPayoutToPlayer(address _player, uint256 _payoutAmount) internal {
    unchecked {
      playerCredit[_player] += _payoutAmount;
    }
  }

  // function _returnMarginOfPlayer(address _player, uint256 _marginAmount) internal {
  //   unchecked {
  //     playerCredit[_player] += _marginAmount;
  //   }
  //   // todo consider unchecked for gas savings (but first be sure underflow is impossible)
  //   totalEscrowTokens -= _marginAmount;
  //   playerEscrow[_player] -= _marginAmount;
  // }

  function _takeMarginOfPlayer(address _player, uint256 _marginAmount) internal {
    // todo consider unchecked for gas savings (but first be sure underflow is impossible)
    unchecked {
      totalEscrowTokens -= _marginAmount;
      playerEscrow[_player] -= _marginAmount;
    }
  }

  /**
   * @notice This function calculates the percentage ROI based on the provided inputs.
   * @dev The function takes the margin amount, position size, price move, and passed time as input parameters.
   * @dev The function returns the calculated percentage ROI as an uint256 value.
   */
  function _percentageROI(
    uint256 _marginAmount,
    uint256 _positionSize,
    uint256 _priceMove,
    uint256 _passedTime
  ) internal view returns (uint256) {
    // Calculate the leverage using the provided position size and margin amount.
    uint256 leverage_ = (_positionSize * BASIS_POINTS) / _marginAmount;

    // Calculate the percentage ROI without considering any cut.
    uint256 percentageRoiWithoutCut_ = (leverage_ * _priceMove) / BASIS_POINTS;

    // Calculate profit without applying any cut.
    uint256 profitWithoutCut = (_marginAmount * percentageRoiWithoutCut_) / BASIS_POINTS;

    // Calculate the cut from the profit based on position size, price move, and passed time.
    uint256 cutFromProfit_ = percentageCutFromProfit(_positionSize, _priceMove, _passedTime);

    // Calculate profit with the applied cut.
    uint256 profitWithCut = (profitWithoutCut * (BASIS_POINTS - cutFromProfit_)) / BASIS_POINTS;

    // Calculate the final percentage ROI by scaling the profit with respect to the original margin amount.
    return (profitWithCut * BASIS_POINTS) / _marginAmount;
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

/**
 * @title DegenPoolManagerSettings
 * @author balding-ghost
 * @notice The DegenPoolManagerSettings contract is used to store all the settings for the DegenPoolManager contract.
 */
contract DegenPoolManagerSettings is IDegenPoolManagerSettings, AccessControl, Pausable {
  uint256 public constant BASIS_POINTS = 1e6; // 100%
  bytes32 public constant ADMIN_MAIN = bytes32(keccak256("ADMIN_MAIN"));
  bytes32 public constant ROUTER_ROLE = bytes32(keccak256("ROUTER_ROLE"));
  bytes32 public constant VAULT_ROLE = bytes32(keccak256("VAULT"));

  /// @notice Vault address
  IVault public immutable vault;
  /// @notice Fee collector address
  IFeeCollector public feeCollector;
  /// @notice Token manager address
  ITokenManager public tokenManager;
  /// @notice Referral storage address
  IReferralStorage public referralStorage;
  // @notice LuckyStrikeMaster contract address
  ILuckyStrikeMaster public masterStrike;

  uint256 public defaultFee = 1e4; // 1%

  bytes32 public immutable pythAssetId;

  IERC20 public immutable targetMarketToken;

  address public degenGameContract;

  mapping(address => bool) public degenGameControllers;

  mapping(uint256 => uint256) public sizeCategories;

  mapping(uint256 => uint256) public feeThresholds;

  constructor(address _vault, address _targetToken, bytes32 _pythAssetId, address _admin) {
    pythAssetId = _pythAssetId;
    targetMarketToken = IERC20(_targetToken);
    vault = IVault(_vault);
    degenGameControllers[address(this)] = true;

    sizeCategories[0] = 1e18 / 10; // 0.1 ETH
    sizeCategories[1] = 1e18; // 1 ETH
    sizeCategories[2] = 2 * 1e18; // 2 ETH
    sizeCategories[3] = 3 * 1e18; // 3 ETH
    sizeCategories[4] = 4 * 1e18; // 4 ETH
    sizeCategories[5] = 5 * 1e18; // 5 ETH
    sizeCategories[6] = 6 * 1e18; // 6 ETH
    sizeCategories[7] = 7 * 1e18; // 7 ETH
    sizeCategories[8] = 8 * 1e18; // 8 ETH
    sizeCategories[9] = 9 * 1e18; // 9 ETH

    // categories are based on the size of the position
    feeThresholds[0] = 175000; //  -> 17.5%
    feeThresholds[1] = 275000; //  -> 27.5%
    feeThresholds[2] = 375000; //  -> 37.5%
    feeThresholds[3] = 475000; //  -> 47.5%
    feeThresholds[4] = 575000; //  -> 57.5%
    feeThresholds[5] = 675000; //  -> 67.5%
    feeThresholds[6] = 775000; //  -> 77.5%
    feeThresholds[7] = 825000; //  -> 82.5%
    feeThresholds[8] = 900000; //  -> 90%
    feeThresholds[9] = 975000; // -> 97.5%

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

  function setReferralStorage(IReferralStorage _referralStorage) external onlyAdmin {
    referralStorage = _referralStorage;
  }

  function setFeeCollector(IFeeCollector _feeCollector) external onlyAdmin {
    feeCollector = _feeCollector;
  }

  function setMasterStrike(address _masterStrike) external onlyAdmin {
    masterStrike = ILuckyStrikeMaster(_masterStrike);
  }

  function setTokenManager(ITokenManager _tokenManager) external onlyAdmin {
    tokenManager = _tokenManager;
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

  function updateFeeThreshold(uint256 _threshold, uint256 _fee) external onlyAdmin {
    require(_threshold <= 10000, "DegenPoolManager: invalid threshold (max 10000)");
    require(_threshold > 0, "DegenPoolManager: invalid threshold (min 1)");
    feeThresholds[_threshold] = _fee;
    emit FeeThresholdUpdated(_threshold, _fee);
  }

  function updateDefaultFee(uint256 _defaultFee) external onlyAdmin {
    defaultFee = _defaultFee;
    emit DefaultFeeUpdated(_defaultFee);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IDegenPoolManagerSettings.sol";

interface IDegenPoolManager is IDegenPoolManagerSettings {
  function totalRealizedProfits() external view returns (uint256 totalRealizedProfits_);

  function totalRealizedLosses() external view returns (uint256 totalRealizedLosses_);

  function totalTheoreticalBadDebt() external view returns (uint256 totalTheoreticalBadDebt_);

  function totalCloseFeeProtocolPartition()
    external
    view
    returns (uint256 totalCloseFeeProtocolPartition_);

  function totalFundingRatePartition() external view returns (uint256 totalFundingRatePartition_);

  function maxLossesAllowed() external view returns (uint256 payoutBufferAmount_);

  function totalEscrowTokens() external view returns (uint256 totalEscrowTokens_);

  function totalLiquidatorFees() external view returns (uint256 totalLiquidatorFees_);

  function getPlayerCredit(address _player) external view returns (uint256 playerCredit_);

  function returnNetResult() external view returns (uint256 netResult_, bool isPositive_);

  function returnPayoutBufferLeft() external view returns (uint256 payoutBufferLeft_);

  function checkPayoutAllowed(uint256 _amountPayout) external view returns (bool isAllowed_);

  function processLiquidationClose(
    bytes32 _positionKey,
    address _player,
    address _liquidator,
    uint256 _positionDuration,
    uint256 _marginAmount,
    uint256 _interestFunding,
    uint256 _assetPrice,
    uint256 _pnlWithInterest
  ) external returns (ClosedPositionInfo memory closedPosition_);

  function claimLiquidationFees() external;

  function closePosition(
    bytes32 _positionKey,
    address _caller,
    uint256 _assetPrice,
    uint256 _positionSize,
    uint256 _positionDuration,
    uint256 _marginAmount,
    uint256 _interestFunding,
    uint256 _maxPositionProfit,
    int256 _pnlWithInterest
  ) external returns (ClosedPositionInfo memory closedPosition_);

  function processDegenProfitsAndLosses() external;

  function clearAllTotals() external;

  function returnVaultReserve() external view returns (uint256 vaultReserve_);

  function transferInMargin(address _player, uint256 _marginAmount) external;

  function transferOutMarginCancel(address _player, uint256 _marginAmount) external;

  event PositionClosedInProfit(bytes32 positionKey, uint256 payOutAmount, uint256 closeFeeProtocol);

  event PositionClosedInLoss(bytes32 positionKey, uint256 marginAmountLeft);

  event SetLiquidationThreshold(uint256 _liquidationThreshold);

  event IncrementMaxLosses(uint256 _incrementedMaxLosses, uint256 _maxLossesAllowed);

  event SetFeeRatioForFeeCollector(uint256 fundingFeeRatioForFeeCollector_);

  event SetDegenProfitForFeeCollector(uint256 degenProfitForFeeCollector_);

  event DegenProfitsAndLossesProcessed(
    uint256 totalRealizedProfits_,
    uint256 totalRealizedLosses_,
    uint256 forVault_,
    uint256 forFeeCollector_
  );

  event PositionLiquidated(
    bytes32 positionKey,
    uint256 marginAmount,
    uint256 protocolFee,
    uint256 liquidatorFee,
    uint256 badDebt
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

  // function decimalsToken() external view returns (uint256);

  function maxPercentageOfVault() external view returns (uint256);

  function degenSettingsManager() external view returns (address);

  function liquidationThreshold() external view returns (uint256);

  function maxLeverage() external view returns (uint256);

  function minLeverage() external view returns (uint256);

  function fundingRateTimeBuffer() external view returns (uint256);

  function setLiquidationThreshold(uint256 _liquidationThreshold) external;

  function minimumPositionDuration() external view returns (uint256);

  function getFundingRate(bool _isLong) external view returns (uint256 _fundingRate);

  function totalLongExposure() external view returns (uint256);

  function totalShortExposure() external view returns (uint256);

  function openPositionAllowed() external view returns (bool);

  function openOrderAllowed() external view returns (bool);

  function closePositionAllowed() external view returns (bool);

  function setOpenOrderAllowed(bool _openOrderAllowed) external;

  function setClosePositionAllowed(bool _closePositionAllowed) external;

  function setOpenPositionAllowed(bool _openPositionAllowed) external;

  // Events

  event SetMaxPostionSize(uint256 maxPositionSize_);

  event SetMaxExposureForAsset(uint256 maxExposureForAsset_);

  event SetFundingRateFactor(uint256 fundingRateFactor_);

  event SetMinimumFundingRate(uint256 minimumFundingRate_);

  event SetClosePositionAllowed(bool _closePositionAllowed);

  event SetOpenPositionAllowed(bool _openPositionAllowed);

  event SetOpenOrderAllowed(bool _openOrderAllowed);

  event SetOpenFeeOnMarginRatio(uint256 openFeeRatio);

  event SetRouterAddress(address _routerAddress);

  event SetMinimumPositionDuration(uint256 minimumPositionDuration);

  event SetFundingRateTimeBuffer(uint256 fundingRateTimeBuffer);

  event SetMaxLeverage(uint256 maxLeverage);

  event SetMinLeverage(uint256 minLeverage);

  event SetDegenSettingsManager(address degenSettingsManager);

  event SetMaxPercentageOfVault(uint256 maxPercentageOfVault);

  event SetLiquidationThreshold(uint256 liquidationThreshold);
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
pragma solidity 0.8.17;

interface IVault {
  function getReserve() external view returns (uint256);

  function getWlpValue() external view returns (uint256);

  function payout(
    address _wagerAsset,
    address _escrowAddress,
    uint256 _escrowAmount,
    address _recipient,
    uint256 _totalAmount
  ) external;

  function payoutNoEscrow(address _wagerAsset, address _recipient, uint256 _totalAmount) external;

  function payin(address _inputToken, address _escrowAddress, uint256 _escrowAmount) external;

  function deposit(address _token, address _receiver) external returns (uint256);

  function withdraw(address _token, address _receiver) external;

  function payinWagerFee(address _tokenIn) external;

  function wagerFeeReserves(address _token) external view returns (uint256);

  function allWhitelistedTokensLength() external view returns (uint256);

  function allWhitelistedTokens(uint256) external view returns (address);

  function getMinPrice(address _token) external view returns (uint256);

  function payinPoolProfits(address _tokenIn) external;

  function tokenToUsdMin(
    address _tokenToPrice,
    uint256 _tokenAmount
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./DegenStructs.sol";

interface IDegenPoolManagerSettings {
  function setDegenGameController(
    address _degenGameController,
    bool _isDegenGameController
  ) external;

  function isDegenGameController(address _degenGameController) external view returns (bool);

  event DegenGameContractSet(address indexed degenGameContract);
  event DegenGameControllerSet(address indexed degenGameController, bool isDegenGameController);
  // event PlayerProfitPayout(address indexed player, uint256 profit);
  event FeeThresholdUpdated(uint256 threshold, uint256 fee);
  event DefaultFeeUpdated(uint256 defaultFee);
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
 * @param positionSize size of the position, this is marginAmount * leverage
 * @param marginAmount amount of margin to use for the position, this is in the asset of the contract
 * @param minOpenPrice minimum price to open the position
 * @param maxOpenPrice maximum price to open the position
 * @param timestampExpired timestamp when the order expires
 * @param positionKey key of the position, only populated if the order was executed
 * @param publicExecutable true if the order can be executed by anyone, false if only the player can execute it
 * @param isOpened true if the position is opened, false if it is not
 * @param isLong true if the user is betting on the price going up, if false the user is betting on the price going down
 * @param isCancelled true if the order was cancelled, false if it was not
 */
struct OrderInfo {
  address player;
  uint32 timestampCreated;
  uint96 positionSize;
  uint96 marginAmount;
  uint96 minOpenPrice;
  uint96 maxOpenPrice;
  uint32 timestampExpired;
  bool publicExecutable;
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
 * @param positionSize size of the position, this is marginAmount * leverage
 * @param marginAmountOnOpenNet amount of margin used to open the position, this is in the asset of the contract
 * @param maxPositionProfit maximum profit of the position set at the time of opening
 */
struct PositionInfo {
  bool isLong;
  bool isOpen;
  address player;
  uint32 timestampOpened;
  uint96 priceOpened;
  uint96 positionSize; // in the asset (ETH or BTC)
  uint32 fundingRateOpen;
  uint32 orderIndex;
  uint96 marginAmountOnOpenNet;
  uint96 maxPositionProfit;
}

/**
 * @notice struct containing all the information of a position when it is closed
 * @param player address of the user opening the position
 * @param isLiquidated address of the liquidator, 0x0 if the position was not liquidated
 * @param timestampClosed timestamp when the position was closed
 * @param positionDuration duration of the position in seconds
 * @param priceClosed price when the position was closed
 * @param totalFundingRatePaid total funding rate paid for the position
 * @param closeFeeProtocol fee paid to close a profitable position
 * @param totalPayout total payout of the position
 * @param marginAmountLeft amount of margin left after the position was closed
 */
struct ClosedPositionInfo {
  address player;
  address liquidatorAddress;
  uint32 timestampClosed;
  uint96 priceClosed;
  uint96 totalFundingRatePaid;
  uint32 positionDuration;
  uint96 closeFeeProtocol;
  uint96 liquidationFeePaid;
  uint96 totalPayout;
  uint96 marginAmountLeft;
  int256 pnlWithInterest;
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