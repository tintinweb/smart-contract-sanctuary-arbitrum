/**
 *Submitted for verification at Arbiscan.io on 2024-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.17;

contract BlockATMGateway {

    address public settleAddress;

    address public onwer;

    constructor(address newSettleAddress) {
        settleAddress = newSettleAddress;
        onwer = msg.sender;
    }

    event SetSettleAddress(address settleAddress);

    modifier onlyOwner() {
        require(onwer == msg.sender, "Not the owner");
        _;
    }

    function setSettleAddress(address newSettleAddress) public onlyOwner {
        settleAddress = newSettleAddress;
        emit SetSettleAddress(newSettleAddress);
    }

    function getSettleAddress() public view returns(address)  {
        return settleAddress;
    }

}