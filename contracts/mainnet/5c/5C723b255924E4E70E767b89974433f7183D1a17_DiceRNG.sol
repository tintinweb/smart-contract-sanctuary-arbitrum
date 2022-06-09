// SPDX-License-Identifier: MIT
// Creator: base64.tech
pragma solidity ^0.8.13;

contract DiceRNG {
    
    function rollSingleDice(uint256 _numberOfSides, bytes memory _entropy) public view returns (uint256){
        bytes memory value = abi.encode(
            _entropy,
            tx.gasprice,
            block.number,
            block.timestamp,
            block.difficulty,
            blockhash(block.number - 1)
        );

        return uint256(keccak256(value)) % _numberOfSides + 1;
    }
}