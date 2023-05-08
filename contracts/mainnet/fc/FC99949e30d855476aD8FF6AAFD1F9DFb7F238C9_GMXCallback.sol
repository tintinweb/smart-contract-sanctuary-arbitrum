pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

interface IPositionRouterCallbackReceiver {
  function gmxPositionCallback(bytes32 positionKey, bool isExecuted, bool isIncrease) external;
}

contract GMXCallback is IPositionRouterCallbackReceiver {
    event callback(bytes32 positionKey, bool isExecuted, bool isIncrease);
    function gmxPositionCallback(bytes32 positionKey, bool isExecuted, bool isIncrease) public override{
      emit callback(positionKey, isExecuted, isIncrease);
    }

}