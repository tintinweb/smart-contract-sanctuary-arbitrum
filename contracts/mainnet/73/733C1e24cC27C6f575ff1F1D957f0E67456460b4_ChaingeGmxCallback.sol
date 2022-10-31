/**
 *Submitted for verification at Arbiscan on 2022-10-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


interface IPositionRouterCallbackReceiver {
    function gmxPositionCallback(bytes32 positionKey, bool isExecuted, bool isIncrease) external;
}

contract ChaingeGmxCallback is IPositionRouterCallbackReceiver {
    
    event TestGMXCall(
        bytes32 positionKey, bool isExecuted, bool isIncrease
    );

    function gmxPositionCallback(bytes32 positionKey, bool isExecuted, bool isIncrease) public override {

        emit TestGMXCall(positionKey, isExecuted, isIncrease);

        // if(isExecuted == false && isIncrease == true) {
        //     // uint256 value = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9).balanceOf(address(this));
        //     // address _account = increasePositionRequests[positionKey];
        //     // IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9).transferFrom(_account, owner, value);
        //     emit TestGMXCall(positionKey, isExecuted, isIncrease);
        // }
    }
}