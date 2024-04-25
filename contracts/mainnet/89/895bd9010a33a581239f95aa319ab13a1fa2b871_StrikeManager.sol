// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


/// @title Range middleware between ROE lending pool and various ranges
library StrikeManager {
 
  /// @notice Get price strike psacing based on price
  function getStrikeSpacing(uint price) public pure returns (uint) {
    // price is X8 so at that point it makes no much sense anyway, meme tokens like PEPE not supported
    if (price < 500) return 1;
    else if(price >= 500 && price < 1000) return 2;
    else  // price > 1000 (x8)
      return getStrikeSpacing(price / 10) * 10;
  }
  

  /// @notice Get the closest strike strictly above price
  function getStrikeStrictlyAbove(uint price) public pure returns (uint strike) {
    uint strikeSpacing = getStrikeSpacing(price);
    strike = price - price % strikeSpacing + strikeSpacing;
  }
  
  
  /// @notice Get the strike equal or above price
  function getStrikeAbove(uint price) public pure returns (uint strike) {
    uint strikeSpacing = getStrikeSpacing(price);
    strike = (price % strikeSpacing == 0) ? price : price - price % strikeSpacing + strikeSpacing;
  }


  /// @notice Gets strike equal or below 
  function getStrikeBelow(uint price) public pure returns (uint strike){
    uint strikeSpacing = getStrikeSpacing(price);
    strike = price - price % strikeSpacing;
  }
  
  
  /// @notice Get the closest strike strictly below price
  function getStrikeStrictlyBelow(uint price) public pure returns (uint strike) {
    uint strikeSpacing = getStrikeSpacing(price);
    if (price % strikeSpacing == 0) {
      // for the tick below, the tick spacing isnt the same, therefore if price is exactly on the tick, 
      // we need to query a slightly below price to get the proper spacing
      strikeSpacing = getStrikeSpacing(price - 1);
      strike = price - strikeSpacing;
    }
    else strike = price - price % strikeSpacing;
  }
  

  /// @notice Check if strike is valid
  function isValidStrike(uint strike) public pure returns (bool isValid) {
    uint strikeSpacing = getStrikeSpacing(strike);
    return strike > 0 && strike % strikeSpacing == 0;
  }
}