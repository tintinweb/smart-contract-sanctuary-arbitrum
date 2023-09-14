//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract CoinFlip {
    enum CoinSide {
        HEADS,
        TAILS
    }

    enum FlipResult {WIN, LOSE}

    event Result(address indexed player, CoinSide chosenSide, FlipResult result);

    function flipcoin(CoinSide chosenSide) public {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 2;

        CoinSide result = CoinSide(randomNumber);

        FlipResult flipResult = (chosenSide == result) ? FlipResult.WIN : FlipResult.LOSE;

        emit Result(msg.sender, chosenSide, flipResult);
    }
}