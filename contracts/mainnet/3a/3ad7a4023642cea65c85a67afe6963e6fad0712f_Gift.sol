// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Gift {
    address public receiver = 0xD95F14B01b3167144F64e04DCAe8a40A2D5ca952;

    event Claimed();

    function claimGift() public {
        require(msg.sender == receiver, "You are not the beneficiary of this gift");
        emit Claimed();
        selfdestruct(payable(receiver));
    }

    fallback() external payable {}
}