/**
 *Submitted for verification at Arbiscan on 2022-09-02
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

interface IParaSwapAugustus {
  function getTokenTransferProxy() external view returns (address);
}

contract decoder {
    function buyOnParaSwap(bytes memory paraswapData) public returns (bytes memory) {
        (bytes memory buyCalldata, IParaSwapAugustus augustus) = abi.decode(
            paraswapData, 
            (bytes, IParaSwapAugustus)
        );
        return buyCalldata;
    }
}