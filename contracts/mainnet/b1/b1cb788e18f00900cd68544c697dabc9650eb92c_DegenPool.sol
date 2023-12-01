// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "../../../interfaces/vault/IVault.sol";
import "../../../interfaces/vault/IReferralStorage.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./IDegenPool.sol";
import "./PriceFeed/ISecondaryPriceFeed.sol";

contract DegenPool is IDegenPool, AccessControlEnumerable {
  using ECDSA for bytes;
  using SafeERC20 for IERC20;

  IPyth public immutable pyth;
  IVault public immutable vault; /// @notice Vault address
  IERC20 public immutable asset;
  bytes32 public immutable pythAssetId;

  ISecondaryPriceFeed public secondaryPriceFeed;

  uint96 public constant SCALE = 1e6;
  uint96 public constant minFee = 100000; /// @notice The minimum fee percentage 10%
  uint96 public constant minPriceMove = 100; /// @notice The minimum price move percentage
  uint96 public constant maxPriceMove = 100000; /// @notice The maximum price move percentage 10%, The pnl fee will be fixed after this price move, also 10% after this price move
  uint96 public constant maxFeeAtMaxPs = 820000; /// @notice The maximum fee at the maximum position size, occurring at a 0.01% price move, is 82% of the profit.
  uint96 public constant maxFeeAtMinPs = 500000; /// @notice The maximum fee at the minimum position size, occurring at a 0.01% price move, is 50% of the profit.
  uint96 public immutable maxPositionSize;

  // Exposure config
  uint8 public freshness = 15;
  uint96 public maxProfit;
  uint96 public maxExposure;
  uint96 public totalLongExposure;
  uint96 public totalShortExposure;
  uint96 public liquidatorFee = 4e4;
  uint256 public budget; // this configuration sets the max budget for losses before the contract pauses itself partly. it is sort of the credit line the contract has (given by the DAO) that the contract has to stay within. if the contract exceeds this budget it will stop accepting new positions and will only liquidate positions. this is to prevent the contract from going bankrupt suddenly. If the degen game is profitable (and the profits are collected by the vault) the budget will increase. In this way the value set/added to this value act as the 'max amount of losses possible'. The main purpose of this mechanism is to prevent draining of the vault. It is true that degen can still lose incredibly much if the game is profitable for years and suddently all historical profits are lost in a few  hours. To prevetn this the DAO can decrement so that the budget is reset.

  uint96 public bribeRate = 1e4;
  /// @notice Referral storage address
  uint96 public pendingBribe;

  /// @notice Referral storage address
  IReferralStorage public refStore;

  mapping(bytes32 => Position) public positions;
  mapping(address => uint96) public liquidatorFees; /// @notice amount of tokens liquidators can claim as a reward for liquidating positions
  mapping(address => bool) public swapAllowed;
  FundFeeConfig public fundFeeConfig = FundFeeConfig(25, 180, 60);

  uint96 public minPositionSize = 1 * SCALE; /// @notice The minimum position size in dollar value 1$ * 1e6
  uint32 public pythUpdateFee = 1;
  uint16 public minPositionDuration = 60; /// @notice The minimum position duration in seconds
  uint16 public minLeverage = 100; /// @notice The minimum leverage
  uint16 public maxLeverage = 1000; /// @notice The maximum leverage
  uint96 public minWager = 98e4; /// @notice The minimum wager amount 0,98$

  uint64 pairIndex;
  bool public isSecondaryEnabled;

  // Roles
  bytes32 public constant OPERATOR = bytes32(keccak256("OPERATOR"));
  bytes32 public constant KEEPER = bytes32(keccak256("KEEPER"));
  bytes32 public constant CONTROLLER = bytes32(keccak256("CONTROLLER"));

  modifier onlyPosOwnerAndNotClosed(bytes32 id, bool isSwap) {
    // Check if it's a swap or a regular close
    if (isSwap) {
      // Require that the sender has the OPERATOR role for swaps
      require(hasRole(OPERATOR, msg.sender), "only swap");
    } else {
      // Require that the sender is the owner of the position
      require(msg.sender == positions[id].player, "Invalid position owner");
    }

    // Require that the position is not already closed
    require(!positions[id].close, "Position already closed");

    // Continue with the execution of the function
    _;
  }

  constructor(
    IPyth pyth_,
    IReferralStorage refStore_,
    bytes32 pythAssetId_,
    address asset_,
    address controller_,
    address vault_,
    uint64 pairIndex_,
    uint96 maxPositionSize_,
    uint96 budget_,
    uint96 maxExposure_
  ) {
    pyth = pyth_;
    refStore = refStore_;
    pythAssetId = pythAssetId_;
    asset = IERC20(asset_);
    vault = IVault(vault_);
    pairIndex = pairIndex_;
    maxPositionSize = maxPositionSize_;
    budget = budget_;
    maxExposure = maxExposure_;
    _grantRole(DEFAULT_ADMIN_ROLE, controller_);
    _grantRole(CONTROLLER, controller_);
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(CONTROLLER, msg.sender);
  }

  function setExpoConf(uint96 maxExpo) external onlyRole(CONTROLLER) {
    // Set the maximum exposure limit
    maxExposure = maxExpo;

    // Emit an event to log the configuration change
    emit SetExpoConfig(maxExpo);
  }

  function setSecondaryPriceFeed(
    ISecondaryPriceFeed secondaryPriceFeed_
  ) external onlyRole(CONTROLLER) {
    // Set the secondary price feed contract address
    secondaryPriceFeed = secondaryPriceFeed_;

    // Emit an event to log the change of the secondary price feed contract
    emit SetSecondaryPriceFeed(address(secondaryPriceFeed_));
  }

  function updateBudget(uint96 newBudget) external onlyRole(CONTROLLER) {
    // Update the budget with the new value
    budget = newBudget;

    // Emit an event to log the budget update
    emit UpdateBudget(newBudget);
  }

  function updateMaxProfit(uint96 newMaxProfit) external onlyRole(CONTROLLER) {
    // Update the maximum profit limit with the new value
    maxProfit = newMaxProfit;

    // Emit an event to log the update of the maximum profit limit
    emit UpdateMaxProfit(newMaxProfit);
  }

  function updateBribeRate(uint96 newBribeRate) external onlyRole(CONTROLLER) {
    // Update the bribe rate with the new value
    bribeRate = newBribeRate;

    // Emit an event to log the update of the bribe rate
    emit UpdateBribeRate(newBribeRate);
  }

  function updateFreshness(uint8 newFreshness) external onlyRole(CONTROLLER) {
    // Update the freshness value with the new value
    freshness = newFreshness;

    // Emit an event to log the update of the freshness value
    emit UpdateFreshness(newFreshness);
  }

  function updateLiquidatorFee(uint96 newLiquidatorFee) external onlyRole(CONTROLLER) {
    // Update the liquidator fee with the new value
    liquidatorFee = newLiquidatorFee;

    // Emit an event to log the update of the liquidator fee
    emit UpdateLiquidatorFee(newLiquidatorFee);
  }

  function updatePythUpdateFee(uint32 newPythUpdateFee) external onlyRole(CONTROLLER) {
    // Update the Pyth update fee with the new value
    pythUpdateFee = newPythUpdateFee;

    // Emit an event to log the update of the Pyth update fee
    emit UpdatePythUpdateFee(newPythUpdateFee);
  }

  function updatePairIndex(uint64 newPairIndex) external onlyRole(CONTROLLER) {
    // Update the pair index with the new value
    pairIndex = newPairIndex;

    // Emit an event to log the update of the pair index
    emit UpdatePairIndex(newPairIndex);
  }

  function updateFundFeeConfig(
    uint16 rate,
    uint16 buffer,
    uint16 period
  ) external onlyRole(CONTROLLER) {
    // Check if the rate is within a valid range
    require(rate <= SCALE, "Invalid rate");

    // Check if the period is a positive value
    require(period > 0, "Invalid period");

    // Create a new FundFeeConfig struct with the provided values
    fundFeeConfig = FundFeeConfig(rate, buffer, period);

    // Emit an event to log the update of the fund fee configuration
    emit UpdateFundFeeConfig(fundFeeConfig);
  }

  function updateMinPositionDuration(uint16 newMinPositionDuration) external onlyRole(CONTROLLER) {
    // Update the minimum position duration with the new value
    minPositionDuration = newMinPositionDuration;

    // Emit an event to log the update of the minimum position duration
    emit UpdateMinPosDuration(newMinPositionDuration);
  }

  function updateMinMaxLeverage(
    uint16 newMinLeverage,
    uint16 newMaxLeverage
  ) external onlyRole(CONTROLLER) {
    // Check if the new minimum leverage is less than or equal to the new maximum leverage
    require(newMinLeverage <= newMaxLeverage, "Invalid leverage");

    // Check if the new minimum leverage is greater than 1
    require(newMinLeverage > 1, "Invalid leverage");

    // Update the minimum and maximum leverage values with the new values
    minLeverage = newMinLeverage;
    maxLeverage = newMaxLeverage;

    // Emit an event to log the update of the minimum and maximum leverage values
    emit UpdateMinMaxLeverage(newMinLeverage, newMaxLeverage);
  }

  function updateMinWager(uint96 newMinWager) external onlyRole(CONTROLLER) {
    // Check if the new minimum wager is greater than 500000 (0,5$)
    require(newMinWager > 50e4, "Invalid wager");

    // Update the minimum wager with the new value
    minWager = newMinWager;

    // Emit an event to log the update of the minimum wager
    emit UpdateMinWager(newMinWager);
  }

  function setSwapAllowed(address user, bool allowed) external {
    // Check if the sender is the same as the user whose swap permission is being modified
    require(msg.sender == user, "Invalid user");

    // Set the swap permission for the specified user
    swapAllowed[user] = allowed;

    // Emit an event to log the change in swap permission for the user
    emit SwapAllowed(user, allowed);
  }

  function setSecondaryEnabled(bool isEnabled) external onlyRole(CONTROLLER) {
    // Set the secondary functionality's enabled state
    isSecondaryEnabled = isEnabled;

    // Emit an event to log the change in the secondary functionality's enabled state
    emit SecondaryEnabled(isEnabled);
  }

  function getPosition(bytes32 id) public view returns (Position memory) {
    // Retrieve and return the Position struct associated with the provided ID
    return positions[id];
  }

  function hashOrder(Order calldata order) public view returns (bytes32) {
    // Check if the order's validUntil timestamp is in the future
    require(order.validUntil > block.timestamp, "ValidUntil too early");

    // Hash the order's data using keccak256 and return the resulting bytes32 value
    return keccak256(abi.encode(order));
  }

  function verify(Order calldata order, bytes calldata signature_) public view returns (bool) {
    // Check if the order has not expired
    require(order.validUntil > block.timestamp, "Order is expired");

    // Calculate the Ethereum signed message hash of the order and then recover the signer's address
    address signer = ECDSA.recover(
      ECDSA.toEthSignedMessageHash(keccak256(abi.encode(order))),
      signature_
    );

    // Compare the recovered signer's address with the order's player address to verify the signature
    return signer == order.player;
  }

  function updatePrice(bytes[] calldata priceUpdateData) internal returns (uint64) {
    // Update the price feeds with the provided data and send the specified value as an Ether transfer
    pyth.updatePriceFeeds{value: pythUpdateFee}(priceUpdateData);

    // Retrieve the latest price data from the Pyth contract with a freshness constraint
    PythStructs.Price memory price = pyth.getPriceNoOlderThan(pythAssetId, freshness);

    require(price.price > 0, "Price should not below 0");

    uint256 PRICE_PRECISION = 1e8;
    uint256 priceScaled;
    if (price.expo >= 0) {
      uint256 exponent = uint256(uint32(price.expo));
      priceScaled = uint256(uint64(price.price)) * PRICE_PRECISION * (10 ** exponent);
    } else {
      uint256 exponent = uint256(uint32(-price.expo));
      priceScaled = (uint256(uint64(price.price)) * PRICE_PRECISION) / (10 ** exponent);
    }

    if (priceScaled > type(uint64).max) {
      revert("Price out of range");
    }
    // Return the updated price as a uint64 value
    return uint64(priceScaled);
  }

  function getPriceFromSecondary() internal returns (uint64) {
    // Retrieve the price for the specified pair index from the secondary price feed
    uint256 price = secondaryPriceFeed.getPrice(pairIndex);
    if (price > type(uint64).max) {
      revert("Price out of range");
    }
    return uint64(price);
  }

  /// @notice Allows the vault to retrieve escrowed tokens.
  /// @param token The address of one of the whitelisted tokens collected in settings.
  /// @param amount The amount of tokens to be retrieved.
  function getEscrowedTokens(address token, uint256 amount) public {
    // Ensure that only the vault is allowed to call this function
    address vaultAddress = address(vault);
    require(msg.sender == vaultAddress, "DegenPoolManager: Only vault can call this");

    // Transfer the specified amount of tokens to the vault
    IERC20(token).safeTransfer(vaultAddress, amount);
  }

  function _decreaseExposure(bool long, uint96 size) internal {
    unchecked {
      if (long) {
        // decrease the total long exposure
        totalLongExposure -= size;
      } else {
        // decrease the total short exposure
        totalShortExposure -= size;
      }
    }
  }

  function _increaseExposure(bool long, uint96 size) internal {
    unchecked {
      if (long) {
        // increase the total long exposure
        totalLongExposure += size;
        require(totalLongExposure <= maxExposure, "Degen: max exposure reached");
      } else {
        // increase the total short exposure
        totalShortExposure += size;
        require(totalShortExposure <= maxExposure, "Degen: max exposure reached");
      }
    }
  }

  function setRefReward(address player, uint96 amount) internal returns (uint96 reward) {
    // Check if the provided amount is greater than zero
    if (amount > 0) {
      // Calculate the reward by dividing the amount by 100 and then multiplying it by 100
      reward = uint96(refStore.setReward(player, address(asset), uint256(amount / 1e2))) * 1e2;
    }
  }

  function execute(
    bytes[] calldata priceData,
    Order calldata order,
    bytes calldata sig
  ) external onlyRole(KEEPER) {
    // Verify the order's signature
    require(verify(order, sig), "Order is not verified");

    // Calculate a unique ID for the position
    bytes32 id = keccak256(sig);

    // Check if a position with the same ID already exists
    require(positions[id].player == address(0), "Position already created");
    // Update the price based on the provided price data
    uint64 price = updatePrice(priceData);

    uint64 maxPrice = (order.maxPrice == 0) ? type(uint64).max : order.maxPrice;

    require(price >= order.minPrice, "Price outside of min limits");
    require(price <= maxPrice, "Price outside of max limits");

    // Calculate the position size
    uint96 size = (order.col * order.lev);

    // Check if the position size exceeds the maximum allowed
    require(size <= maxPositionSize, "Position size too high");

    // Check if the collateral amount in the order is greater than or equal to the minimum wager
    require(order.col >= minWager, "Wager too low");

    // Check if the leverage in the order is greater than or equal to the minimum leverage
    require(order.lev >= minLeverage, "Leverage too low");

    // Check if the leverage in the order is within the maximum allowed range
    require(order.lev <= maxLeverage, "Leverage too high");

    // Transfer USDC.e collateral from the player to this contract
    IERC20(asset).safeTransferFrom(order.player, address(this), order.col);

    // Calculate the bust price and margin
    uint64 bustPrice = price;
    uint64 margin = price / order.lev;
    margin -= margin / 10;

    // Adjust the bust price based on the order's direction (long or short)
    order.long ? bustPrice -= margin : bustPrice += margin;

    // Decrease the exposure based on the order's direction and size
    _increaseExposure(order.long, size);

    // Create a new Position struct
    Position memory pos = Position(
      price,
      bustPrice,
      order.col,
      uint32(block.timestamp),
      order.lev,
      order.player,
      order.long,
      false
    );

    // Store the position using the unique ID
    positions[id] = pos;

    // Emit an event to log the execution of the position
    emit PositionExecuted(id, pos);
  }

  function _calcPnl(
    uint96 size,
    uint64 openPrice,
    uint64 price,
    bool long
  ) internal pure returns (int96 pnl) {
    // Calculate the position's notional amount
    uint96 amount = (size * SCALE) / openPrice;
    // Calculate the price difference between the current price and the opening price
    int96 diff = int64(price) - int64(openPrice);

    // Calculate pnl based on the position's direction (long or short)
    if (long) {
      pnl = (int96(amount) * diff) / int96(SCALE);
    } else {
      pnl = (int96(amount) * -1 * diff) / int96(SCALE);
    }
  }

  /**
   * @notice internal view returns the amount of funding rate accured
   * @param openTime timestamp when the position was opened
   * @param size size of the position
   */
  function _calcFundingFee(uint32 openTime, uint96 size) internal view returns (uint96 fee) {
    // Get the current timestamp
    uint32 curTime = uint32(block.timestamp);

    // Retrieve the fund fee configuration from storage
    FundFeeConfig memory conf = fundFeeConfig;

    // Check if the current time is greater than or equal to the open time plus the buffer period
    if (curTime >= openTime + conf.buffer) {
      // Calculate the percentage of the fee based on the rate and time elapsed
      uint32 percent = conf.rate * ((curTime - openTime) / conf.period);

      // Ensure that the percentage does not exceed the maximum value (SCALE)
      if (percent > SCALE) {
        percent = uint32(SCALE);
      }

      // Calculate the funding fee based on the position size and the calculated percentage
      fee = (size * percent) / SCALE;
    }
  }

  function _calcProfitFee(uint96 priceMove, uint96 size) internal view returns (uint96) {
    // Check if the provided price move is within the specified range
    if (maxPriceMove > priceMove && priceMove >= minPriceMove) {
      // calculate the max fee
      uint96 diff = (maxFeeAtMaxPs - maxFeeAtMinPs) * SCALE;

      uint96 positionRange = (maxPositionSize - minPositionSize) * SCALE;
      // calculate the fee using linear interpolation
      uint96 maxFee = (diff * (size - minPositionSize)) / (positionRange) + maxFeeAtMinPs;
      // calculate the shift amount based on the position size
      // shift amount will be add to the result of the fee calculation to shift the fee curve
      int96 shift = (-500001 + (int96(size) * 500001)) / int96(10 ** 13);
      // Calculate the fee using linear interpolation

      return
        uint96(shift) +
        maxFee -
        ((maxFee - minFee) * (priceMove - minPriceMove)) /
        (maxPriceMove - minPriceMove);
    }

    // If the price move is out of the specified range, return the min fee
    // it means the price move is greater than the max price move, it should return the min fee
    return minFee;
  }

  /**
   * @notice Function to calculate the price move percentage.
   * @param openPrice The open price of the position.
   * @param closePrice The close price of the position.
   */
  function _calcPriceMovePerc(
    uint96 openPrice,
    uint96 closePrice
  ) internal pure returns (uint96 pm_) {
    int96 diff = int96(closePrice) - int96(openPrice);
    // if the diff is negative, make it positive
    diff < 0 ? diff = diff * -1 : diff;
    return (uint96(diff) * SCALE) / openPrice;
  }

  function _share(uint96 amount, address player) internal returns (uint96) {
    // Calculate the bribe amount based on the specified amount and bribe rate
    uint96 bribe = (amount * bribeRate) / SCALE;

    // Calculate the reward for the player and set it using the setRefReward function
    uint96 reward = setRefReward(player, bribe);

    // Update the pending bribe by subtracting the reward
    pendingBribe += bribe - reward;

    // Return the difference between the bribe and the reward as the shared amount
    return bribe - reward;
  }

  function calcProfit(
    uint96 col,
    uint96 size,
    uint64 openPrice,
    uint64 price,
    uint32 openTime,
    bool long
  ) public view returns (uint96, uint96, uint96) {
    // Calculate the profit for the position using the _calcPnl function
    int96 profit = _calcPnl(size, openPrice, price, long);
    // Ensure that the profit is greater than zero
    require(profit > 0, "not in profit");
    // Calculate the percentage price move using the _calcPriceMovePerc function
    uint96 pm = _calcPriceMovePerc(openPrice, price);

    // Calculate the profit fee based on the profit and percentage price move
    uint96 pf = (uint96(profit) * _calcProfitFee(pm, size)) / SCALE;

    // Calculate the funding fee based on the open time and position size
    uint96 ff = _calcFundingFee(openTime, size);

    // Calculate the excluded profit, limited by the maximum profit
    uint96 excluded = uint96(profit) - pf;

    // Limit the excluded profit by the maximum profit value
    if (excluded > maxProfit) {
      excluded = maxProfit;
    }

    // Calculate the payout and reduce it by the funding fee if it's greater than the payout
    uint96 payout = excluded + col;
    payout = ff > payout ? 0 : payout - ff;

    // Reduce the excluded profit by the funding fee if it's greater than the excluded profit
    excluded = ff > excluded ? 0 : excluded - ff;

    return (payout, excluded, pm);
  }

  function _liquidate(bytes32 id, Position memory pos, uint64 price) internal {
    // Ensure that the position is not already closed
    require(!pos.close, "Position is closed");

    // Calculate the liquidator fee based on the position's collateral and the liquidator fee rate
    uint96 liqFee = (pos.col * liquidatorFee) / SCALE;

    // Share a portion of the collateral with the position's player and calculate the remaining pay-in amount
    uint96 shared = _share(pos.col, pos.player);
    uint96 payin = pos.col - liqFee - shared;

    // Increment the liquidator's fees with the liquidation fee
    liquidatorFees[msg.sender] += liqFee;

    // Increase the budget with the pay-in amount
    budget += payin;

    // Transfer the pay-in amount to the vault
    vault.payin(address(asset), address(this), payin);

    // Emit an event to log the liquidation of the position
    emit PositionLiquidated(id, price, pos);
  }

  function _close(address player, address to, uint96 col, uint96 payout) internal {
    // Calculate the pay-in amount by subtracting the payout from the collateral
    uint96 payin = col - payout;

    // Share a portion of the pay-in amount with the player and calculate the remaining shared amount
    uint96 shared = _share(payin, player);

    // Increase the budget with the pay-in amount reduced by the shared amount
    budget += payin - shared;

    // Transfer the remaining shared amount and the payout to the specified recipient
    vault.payout(address(asset), address(this), col - shared, to, payout);
  }

  function _closeInLoss(
    bytes32 id,
    Position memory pos,
    uint64 price,
    uint96 size,
    bool isSwap
  ) internal onlyPosOwnerAndNotClosed(id, isSwap) {
    require(pos.openTime + minPositionDuration <= block.timestamp, "too early to close");
    // Calculate the loss by negating the profit calculated by _calcPnl
    uint96 loss = uint96(_calcPnl(size, pos.openPrice, price, pos.long) * -1);

    // Calculate the funding fee for the position
    uint96 fundFee = _calcFundingFee(pos.openTime, size);

    // Add the funding fee to the loss if it's greater than zero
    if (fundFee > 0) {
      loss += fundFee;
    }

    // Calculate the payout by subtracting the loss from the collateral
    uint96 payout = loss > pos.col ? 0 : pos.col - loss;

    // If the payout is zero, revert the transaction with a specific error
    if (payout == 0) {
      revert LiquidatedByFees();
    }

    // Close the position by paying out the player
    _close(pos.player, pos.player, pos.col, payout);

    // Emit an event to log the closure of the position
    emit PositionClosed(id, price, pos);
  }

  function _closeInProfit(
    bytes32 id,
    Position memory pos,
    uint64 price,
    uint96 size,
    bool isSwap
  ) internal onlyPosOwnerAndNotClosed(id, isSwap) returns (uint96) {
    require(pos.openTime + minPositionDuration <= block.timestamp, "too early to close");
    // Calculate the payout, profit, and percentage price move using calcProfit
    (uint96 payout, uint96 profit, ) = calcProfit(
      pos.col,
      size,
      pos.openPrice,
      price,
      pos.openTime,
      pos.long
    );

    // Check if the profit is greater than the budget and revert if true
    if (profit > budget) {
      revert Halted();
    }

    if (payout > 0 && profit == 0) {
      // Close the position by paying out the player
      _close(pos.player, msg.sender, pos.col, payout);
    } else if (payout == 0 && profit == 0) {
      // Revert the transaction with a specific error if both payout and profit are zero
      revert LiquidatedByFees();
    } else {
      // Deduct the profit from the budget and transfer the payout to the player
      budget -= profit;
      vault.payout(address(asset), address(this), pos.col, msg.sender, payout);
    }

    // Emit an event to log the closure of the position
    emit PositionClosed(id, price, pos);

    return payout;
  }

  function closePosition(bytes[] calldata priceData, bytes32 id) external {
    // Update the price using the provided price data
    uint64 price = updatePrice(priceData);

    // Retrieve the position from the positions mapping
    Position memory pos = positions[id];

    // Ensure that the position exists (player is not the zero address)
    require(pos.player != address(0), "Position not found");

    // Calculate the position size
    uint96 size = pos.col * pos.lev;

    if (pos.long) {
      if (price <= pos.bustPrice) {
        // Liquidate the position if the price is at or below the bust price
        _liquidate(id, pos, price);
      } else if (price <= pos.openPrice) {
        // Close the position in loss if the price is at or below the open price
        _closeInLoss(id, pos, price, size, false);
      } else {
        // Close the position in profit if none of the previous conditions are met
        _closeInProfit(id, pos, price, size, false);
      }
    } else {
      if (price >= pos.bustPrice) {
        // Liquidate the position if the price is at or above the bust price
        _liquidate(id, pos, price);
      } else if (price >= pos.openPrice) {
        // Close the position in loss if the price is at or above the open price
        _closeInLoss(id, pos, price, size, false);
      } else {
        // Close the position in profit if none of the previous conditions are met
        _closeInProfit(id, pos, price, size, false);
      }
    }

    // Mark the position as closed
    positions[id].close = true;

    // Increase the exposure based on the position's direction and size
    _decreaseExposure(pos.long, size);
  }

  function closePositionSwap(
    bytes[] calldata priceData,
    bytes32 id
  ) external onlyRole(OPERATOR) returns (uint96) {
    // Update the price using the provided price data
    uint64 price = updatePrice(priceData);

    // Retrieve the position from the positions mapping
    Position memory pos = positions[id];

    // Ensure that the position exists (player is not the zero address)
    require(pos.player != address(0), "Position not found");

    // Calculate the position size
    uint96 size = pos.col * pos.lev;

    uint96 payout;

    if (pos.long) {
      // Check if the position is not liquidable and is not in loss
      if (price > pos.openPrice) {
        // Close the position in profit and record the payout
        payout = _closeInProfit(id, pos, price, size, true);
      } else {
        // Revert with a specific error if the position cannot be closed
        revert CanNotCloseSwap();
      }
    } else {
      // Check if the position is not liquidable and is not in loss
      if (price < pos.openPrice) {
        // Close the position in profit and record the payout
        payout = _closeInProfit(id, pos, price, size, true);
      } else {
        // Revert with a specific error if the position cannot be closed
        revert CanNotCloseSwap();
      }
    }

    // Mark the position as closed
    positions[id].close = true;

    // Increase the exposure based on the position's direction and size
    _decreaseExposure(pos.long, size);

    return payout;
  }

  function liquidateByFee(bytes[] calldata priceData, bytes32 id) external {
    // Update the price using the provided price data
    uint64 price = updatePrice(priceData);

    // Retrieve the position from the positions mapping
    Position memory pos = positions[id];

    // Calculate the position size
    uint96 size = pos.col * pos.lev;

    // Initialize the payout as the full collateral amount
    uint96 payout = pos.col;

    // Check if the position is in a loss
    if ((pos.long && price <= pos.openPrice) || (!pos.long && price >= pos.openPrice)) {
      // Calculate the loss and funding fee
      uint96 loss = uint96(_calcPnl(size, pos.openPrice, price, pos.long) * -1);
      uint96 ff = _calcFundingFee(pos.openTime, size);

      // Deduct the loss from the payout, if the loss is not greater than the payout
      payout = loss > payout ? 0 : payout - loss;

      // Deduct the funding fee from the payout, if the funding fee is not greater than the payout
      payout = ff > payout ? 0 : payout - ff;
    } else {
      // Calculate the payout based on profit and other factors using the calcProfit function
      (payout, , ) = calcProfit(pos.col, size, pos.openPrice, price, pos.openTime, pos.long);
    }

    // If the payout is greater than zero, revert the transaction with a specific error
    if (payout > 0) {
      revert NotLiquidableByFees();
    }

    // Mark the position as closed
    positions[id].close = true;

    // Increase the total exposure based on the position's direction and size
    _decreaseExposure(pos.long, size);

    // Liquidate the position based on fee-related conditions
    _liquidate(id, pos, price);
  }

  function liquidateBySecondary(bytes32 id) external onlyRole(KEEPER) {
    // Check if the secondary price feed is enabled
    require(isSecondaryEnabled, "Secondary price feed is not enabled");

    // Get the price from the secondary price feed
    uint64 price = getPriceFromSecondary();

    // Retrieve the position from the positions mapping
    Position memory pos = positions[id];

    if (pos.long) {
      require(price <= pos.bustPrice, "Price is not below bust price");
    } else {
      require(price >= pos.bustPrice, "Price is not above bust price");
    }

    // Mark the position as closed
    positions[id].close = true;

    // Increase the total exposure based on the position's direction and size
    uint96 size = pos.col * pos.lev;
    _decreaseExposure(pos.long, size);

    // Liquidate the position using the secondary price and related functions
    _liquidate(id, pos, price);
  }

  function emergencyClose(
    bytes[] calldata priceUpdateData,
    bytes32 id
  ) external onlyPosOwnerAndNotClosed(id, false) {
    // Update the price using the provided price update data
    uint64 price = updatePrice(priceUpdateData);

    // Retrieve the position from the positions mapping
    Position memory pos = positions[id];

    // Calculate the position size
    uint96 size = pos.col * pos.lev;

    // Calculate profit using the calcProfit function
    (, uint96 profit_, ) = calcProfit(pos.col, size, pos.openPrice, price, pos.openTime, pos.long);

    // Check if the profit is less than the budget, and revert if true
    if (profit_ < budget) {
      revert NotHalted();
    }

    // Mark the position as closed
    positions[id].close = true;

    // Transfer the position's collateral back to the player
    asset.safeTransfer(address(pos.player), pos.col);

    // Increase the exposure based on the position's direction and size
    _decreaseExposure(pos.long, size);

    // Emit an event to log the emergency closure of the position
    emit PositionClosedEmergency(id, pos);
  }

  function claimLiquidatorFees() external {
    // Retrieve the amount of liquidator fees assigned to the sender
    uint96 amount = liquidatorFees[msg.sender];

    // Check if there are fees to claim, and revert if the amount is zero
    require(amount > 0, "No fees to claim");

    // Set the liquidator fees for the sender to zero
    liquidatorFees[msg.sender] = 0;

    // Transfer the claimed fees to the sender's address
    asset.safeTransfer(msg.sender, amount);

    // Emit an event to log the collection of liquidator fees
    emit LiquidatorFeesCollected(msg.sender, amount, false);
  }

  function claimLiquidatorFeesSwap(
    address liquidator
  ) external override onlyRole(OPERATOR) returns (uint96 amount_) {
    // Check if the provided liquidator address is allowed for swap
    require(swapAllowed[liquidator], "Swap not allowed");

    // Retrieve the amount of liquidator fees assigned to the liquidator address
    uint96 amount = liquidatorFees[liquidator];

    // Check if there are fees to claim, and revert if the amount is zero
    require(amount > 0, "No fees to claim");

    // Set the liquidator fees for the liquidator address to zero
    liquidatorFees[liquidator] = 0;

    // Transfer the claimed fees to the operator's address (msg.sender)
    asset.safeTransfer(msg.sender, amount);

    // Emit an event to log the collection of liquidator fees in a swap context
    emit LiquidatorFeesCollected(liquidator, amount, true);

    return amount;
  }

  function transferBribe() external {
    // Retrieve the amount of pending bribe
    uint96 amount = pendingBribe;

    // Check if there is a bribe to claim, and revert if the amount is zero
    require(amount > 0, "No bribe to claim");

    // Set the pending bribe to zero
    pendingBribe = 0;

    // Transfer the bribe to the vault's address
    asset.safeTransfer(address(vault), amount);

    // Pay in the wager fee to the vault
    vault.payinWagerFee(address(asset));

    // Emit an event to log the transfer of the bribe
    emit BribeTransferred(amount);
  }

  // function that allows to deposit eth to the contract
  receive() external payable {}

  // function that allows the admin to withdraw eth from the contract
  function withdrawEth(address payable _to, uint256 _amount) external onlyRole(CONTROLLER) {
    _to.transfer(_amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
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

interface IReferralStorage {
  /*==================================================== EVENTS ===========================================================*/

  event Reward(address referrer, address player, address token, uint256 amount);
  event RewardRemoved(address referrer, address player, address token, uint256 amount);

  function setReward(address _player, address _token, uint256 _amount) external returns (uint256 _reward);
  function removeReward(address _player, address _token, uint256 _amount) external; 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IDegenPool {
  // Structs
  struct Order {
    uint64 minPrice;
    uint64 maxPrice;
    uint48 col;
    uint32 validUntil;
    uint16 lev;
    bool long;
    address player;
  }

  struct Position {
    uint64 openPrice;
    uint64 bustPrice;
    uint48 col;
    uint32 openTime;
    uint16 lev;
    address player;
    bool long;
    bool close;
  }

  struct FundFeeConfig {
    uint16 rate;
    uint16 buffer;
    uint16 period;
  }

  // Errors
  error PriceOutRange();
  error MaxExposureReached(bool long);
  error Halted();
  error NotHalted();
  error LiquidatedByFees();
  error NotLiquidableByFees();
  error CanNotCloseSwap();

  // Events
  event PositionExecuted(bytes32 indexed sig, Position position);

  event PositionLiquidated(bytes32 indexed sig, uint64 price, Position position);

  event PositionClosed(bytes32 indexed sig, uint64 price, Position position);

  event PositionClosedEmergency(bytes32 indexed sig, Position position);

  event LiquidatorFeesCollected(address indexed liquidator, uint96 amount, bool swap);

  event SetExpoConfig(uint96 maxExpo);

  event UpdateBudget(uint96 budget);

  event UpdateMaxProfit(uint96 maxProfit);

  event UpdateBribeRate(uint96 bribeRate);

  event UpdateFreshness(uint8 freshness);

  event UpdateLiquidatorFee(uint96 liquidatorFee);

  event UpdateFundFeeConfig(FundFeeConfig fundFeeConfig);

  event UpdateMinPosDuration(uint32 minPosDuration);

  event UpdateMinMaxLeverage(uint16 minLeverage, uint16 maxLeverage);

  event SwapAllowed(address user, bool allowed);

  event SetSecondaryPriceFeed(address secondaryPriceFeed);

  event BribeTransferred(uint96 amount);

  event SecondaryEnabled(bool enabled);

  event UpdateMinWager(uint96 minWager);

  event UpdatePythUpdateFee(uint32 newPythUpdateFee);

  event UpdatePairIndex(uint64 newPairIndex);

  // Functions
  function claimLiquidatorFeesSwap(address liquidator) external returns (uint96 amount_);

  function closePositionSwap(bytes[] calldata priceData, bytes32 id) external returns (uint96);

  function getPosition(bytes32 id) external view returns (Position memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISecondaryPriceFeed {
  function getPrice(uint64 _pairIndex) external returns (uint256 price);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
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