// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

library FeeLibrary {
  // Represents 100%
  uint256 public constant TOTAL_WEIGHT = 10_000;

  /**
   * @notice The function calculates streaming fees for an intervall in seconds proportionally to a calendar year
   * @return tokensToMint Returns the amount of idx tokens to be minted to represent the fee
   */
  function calculateStreamingFee(
    uint256 _totalSupply,
    uint256 _vaultBalance,
    uint256 _lastCharged,
    uint256 _fee
  ) public view returns (uint256 tokensToMint) {
    if (_lastCharged >= block.timestamp) {
      return tokensToMint;
    }
    uint256 feeForIntervall = (_vaultBalance * (_fee) * (block.timestamp - _lastCharged)) / (365 days) / (TOTAL_WEIGHT);

    tokensToMint = (feeForIntervall * _totalSupply) / (_vaultBalance - feeForIntervall);

    return tokensToMint;
  }

  /**
   * @notice The function calculates performance fee based on the current market compared to the high watermark
   *         Fees are only being minted if the current price is higher than the high watermark (performance)
   *         Total supply * increased token price represents the wealth created, fees are being charged on that amount
   * @return tokensToMint Returns the amount of idx tokens to be minted to represent the fee
   * * @return currentPrice Returns the current idx token price
   */
  function calculatePerformanceFee(
    uint256 _totalSupply,
    uint256 _vaultBalance,
    uint256 _highWaterMark,
    uint256 _fee
  ) public pure returns (uint256 tokensToMint, uint256 currentPrice) {
    currentPrice = (_vaultBalance * (10 ** 18)) / (_totalSupply);
    uint256 feeForIntervall;

    if (currentPrice > _highWaterMark) {
      feeForIntervall = ((currentPrice - _highWaterMark) * (_totalSupply) * (_fee) ) / (TOTAL_WEIGHT) /(10 ** 18);
    } else {
      return (0, currentPrice);
    }

    tokensToMint = (feeForIntervall * _totalSupply) / (_vaultBalance - feeForIntervall);
  }

  /**
   * @notice This function calculates entry and exit fee based on the investment/withdrawal amount
   */
  function calculateEntryAndExitFee(uint256 _fee, uint256 _tokenAmount) public pure returns (uint256) {
    return (_tokenAmount * _fee) / TOTAL_WEIGHT;
  }

  /**
   * @notice This function calculates a cut of management fees that's going to our protocol, e.g. we're taking a 25% cut of the management fees as protocol fees
   */
  function feeSplitter(
    uint256 _fee,
    uint256 _protocolFee
  ) public pure returns (uint256 protocolFee, uint256 assetManagerFee) {
    if (_fee == 0) {
      return (0, 0);
    }
    // we take a percentage as protocol fee, e.g. 25%
    protocolFee = (_fee * _protocolFee) / 10_000;
    assetManagerFee = _fee - protocolFee;
  }
}