/**
 *Submitted for verification at Arbiscan on 2022-11-22
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

//1000000000000000000

contract LotteryOne {
    address public owner;

    uint256 public maxBet = 10 * 1e18; /*0.001*/ //2 finney
    uint256 decimals = 3;
    uint256 decimalsMultiplier = 10**decimals;

    uint256 public houseWinRate = 0; //0%-100% => 0..100000 /3 decimals
    uint256 public playerWinRate = 50 * decimalsMultiplier; //0%-100% => 0..100000 /3 decimals
    uint256 public playerWinMultiplier = 2 * decimalsMultiplier;
    uint256 public randomCounter = 0;

    constructor() payable {
        owner = msg.sender;
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function setMaxBet(uint256 _max) public {
        require(msg.sender == owner);
        maxBet = _max;
    }

    function setHouseWinRate(uint256 _rate) public {
        require(msg.sender == owner);
        houseWinRate = _rate;
    }

    function setPlayerWinRate(uint256 _rate) public {
        require(msg.sender == owner);
        playerWinRate = _rate;
    }

    function setPlayerWinMultiplier(uint256 _rate) public {
        require(msg.sender == owner);
        playerWinMultiplier = _rate;
    }

    function bet() public payable returns (bool) {
        require(msg.value <= maxBet, "Bet too high");
        require(
            msg.value <= balance(),
            "Bet higher than available balance for win"
        );

        uint256 randomValue = (random() % 100) * decimalsMultiplier;
        // console.log("rand=", randomValue);
        // console.log("winrt=", playerWinRate - houseWinRate);

        //uint256 canwin = (msg.value * playerWinMultiplier) / decimalsMultiplier;
        // console.log("v:", msg.value, "mult:", playerWinMultiplier);
        // console.log("Dec:", decimalsMultiplier, "canwin=", canwin);

        if (randomValue < playerWinRate - houseWinRate) {
            //console.log("win");
            //https://solidity-by-example.org/sending-ether/
            uint256 won = (msg.value * playerWinMultiplier) / decimalsMultiplier;
            //console.log("bet:", msg.value, "won:", won);
            //payable(msg.sender).transfer(won);
            //return payable(msg.sender).send(won);
            (bool sent, ) = payable(msg.sender).call{value: won}("");
            require(sent);
            return true;
        } else {
            //console.log("loose");
            return false;
        }
    }

    function withdraw() public {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }

    function random() private returns (uint256) {
        //console.log(block.difficulty);
        //console.log(block.timestamp);

        uint256 randValue = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    //now,
                    randomCounter
                )
            )
        );

        //generate next random counter by current random value
        randomCounter += randValue % 100;
        return randValue;
    }
}