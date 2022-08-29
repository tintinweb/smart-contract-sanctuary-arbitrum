/**
 *Submitted for verification at Arbiscan on 2022-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract MyDontPushTheRedButtonContract {


    struct RedButtonPush {
        address userWhoPushedTheRedButton;
    }

    RedButtonPush[] public buttonPushes;

    uint256 public howManyTimesTheRedButtonHasBeenPushed = 0;

    mapping(address => uint256) public userRedButtonPushesCount;

    event TheRedButtonWasPushed(address user);

    constructor() {

    }

    function dontPushTheredButton() external {

        RedButtonPush memory currentButtonPush = RedButtonPush({
            userWhoPushedTheRedButton: address(msg.sender)
        });

        buttonPushes.push(currentButtonPush);

        howManyTimesTheRedButtonHasBeenPushed++;
        userRedButtonPushesCount[msg.sender]++;

        emit TheRedButtonWasPushed(msg.sender);
    }
}