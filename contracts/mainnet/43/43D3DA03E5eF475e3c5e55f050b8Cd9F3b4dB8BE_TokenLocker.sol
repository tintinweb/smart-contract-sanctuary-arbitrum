/**
 *Submitted for verification at Arbiscan.io on 2023-08-31
*/

pragma solidity ^0.5.16;

contract TokenLocker {
    address public constant ibex = 0x56659245931CB6920e39C189D2a0e7DD0dA2d57b;
    address public recipient = 0xe2E2d2A269CbF9674324F9eBfCACE784dEcb86BB;
    uint public vestingEnd;

    constructor(
        uint vestingEnd_
    ) public {
        require(vestingEnd_ > block.timestamp, 'TokenLocker::constructor: end is too early');
        vestingEnd = vestingEnd_;
    }

    function setRecipient(address recipient_) public {
        require(msg.sender == recipient, 'TokenLocker::setRecipient: unauthorized');
        recipient = recipient_;
    }

    function claim() public {
        require(block.timestamp >= vestingEnd, 'TokenLocker::claim: not time yet');
        require(msg.sender == recipient, 'TokenLocker::claim: unauthorized');
        uint amount = IIbex(ibex).balanceOf(address(this));
        IIbex(ibex).transfer(recipient, amount);
    }
}

interface IIbex {
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
}