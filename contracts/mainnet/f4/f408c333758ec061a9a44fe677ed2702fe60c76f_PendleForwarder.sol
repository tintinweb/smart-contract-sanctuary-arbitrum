// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract PendleForwarder {
    uint256 public fee;
    address payable public feeReceiver;

    event Received(address indexed sender, uint256 amount);
    event PendleSwap(address indexed market, address indexed user);

    constructor(uint256 _fee, address payable _feeReceiver) {
        fee = _fee;
        feeReceiver = _feeReceiver;
    }

    receive() external payable { }

    function forwardCall(address target, bytes calldata data, address market) public payable {
        uint256 swapValue;
        uint256 feeAmount;
        if (fee > 0) {
            feeAmount = msg.value * fee / 1e18;
            swapValue = msg.value - feeAmount;
        } else {
            swapValue = msg.value;
        }

        (bool success,) = target.call{ value: swapValue }(data);
        if (success) {
            emit PendleSwap(market, msg.sender);
            if (feeAmount > 0) {
                feeReceiver.transfer(feeAmount);
            }
        } else {
            revert("Call failed");
        }
    }
}