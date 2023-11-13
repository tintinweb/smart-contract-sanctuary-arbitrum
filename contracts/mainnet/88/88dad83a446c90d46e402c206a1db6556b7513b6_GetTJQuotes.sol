/**
 *Submitted for verification at Arbiscan.io on 2023-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;



interface LBPair {
    function getActiveId() external view returns (uint24 activeId);
    function getBin(uint24 id) external view returns (uint128 binReserveX, uint128 binReserveY);
    function getPriceFromId(uint24 id) external view returns (uint256 price);
    function getNextNonEmptyBin(bool swapForY, uint24 id) external view returns (uint24 nextId);
}

contract GetTJQuotes {
 

  function getTopOfBook(address _pool) public view returns (uint256[] memory, uint128[] memory, uint128[] memory) {
        // Create an instance of the LBPair interface
        LBPair lbPair = LBPair(_pool);

        uint256[] memory binPrices = new uint256[](3);
        uint128[] memory binReserveXValues = new uint128[](3);
        uint128[] memory binReserveYValues = new uint128[](3);


        uint24 active_id = lbPair.getActiveId();
        (binReserveXValues[1], binReserveYValues[1]) = lbPair.getBin(active_id);
        binPrices[1] = lbPair.getPriceFromId(active_id);

        uint24 id = lbPair.getNextNonEmptyBin(true, active_id);

      // get "bid" - 1 
        (binReserveXValues[0], binReserveYValues[0]) = lbPair.getBin(id);
        binPrices[0] = lbPair.getPriceFromId(id);

        id = lbPair.getNextNonEmptyBin(false, active_id);

      // get "ask" + 1 
        (binReserveXValues[2], binReserveYValues[2]) = lbPair.getBin(id);
        binPrices[2] = lbPair.getPriceFromId(id);

        return(binPrices, binReserveXValues, binReserveYValues);

    }


}