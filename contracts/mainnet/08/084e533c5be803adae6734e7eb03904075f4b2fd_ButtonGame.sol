/**
 *Submitted for verification at Arbiscan on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ButtonGame {
    event RoundStarted(uint256 roundID, uint256 startedAt);
    event Played(uint256 indexed roundID, address player, uint256 playedAt);
    event RoundEnded(uint256 roundID, uint256 endedAt);

    uint256 public immutable depositAmount;
    uint256 public immutable roundDuration;

    uint256 public roundID = 0;
    uint256 public roundEndsAt;
    bool public isRoundActive = false;
    uint256 public prizePool = 0;
    address public currentKing = address(0);

    constructor() {
        roundDuration = 2 hours;
        depositAmount = 0.0005 ether;
    }

    function startRound() public payable {
        require(!isRoundActive, "ROUND_ACTIVE");
        require(msg.value == depositAmount, "DEPOSIT_MISMATCH");

        roundID++;
        isRoundActive = true;
        _play();

        emit RoundStarted(roundID, block.timestamp);
    }

    function play() public payable {
        require(isRoundActive, "ROUND_INACTIVE");
        require(msg.value == depositAmount, "DEPOSIT_MISMATCH");
    
        _play();
    }

    function endRound() public {
        require(isRoundActive, "ROUND_INACTIVE");
        require(block.timestamp >= roundEndsAt, "TIMER_HAS_NOT_EXPIRED");
        uint256 prize = prizePool;

        address winner = currentKing;

        isRoundActive = false;
        currentKing = address(0);
        roundEndsAt = 0;
        prizePool = 0;

        payable(winner).transfer(prize);

        emit RoundEnded(roundID, block.timestamp);
    }

    function _play() internal {
        roundEndsAt = block.timestamp + roundDuration;
        currentKing = msg.sender;
        prizePool += msg.value;

        emit Played(roundID, msg.sender, block.timestamp);
    }
}