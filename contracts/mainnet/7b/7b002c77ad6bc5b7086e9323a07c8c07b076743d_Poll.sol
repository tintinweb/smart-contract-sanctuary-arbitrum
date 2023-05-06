/**
 *Submitted for verification at Arbiscan on 2023-05-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/AccessControl.sol";

interface IPesale {
    function amountPurchased(address contributer) external returns(uint256);
}
contract Poll {
   
   event voted(address contributor, bool refund, uint256 shares);
   address public presale;


    mapping(address => bool) public votes;

    // amount of shares a voter has
    mapping(address => uint256) public shares;

    uint256 public refund;
    uint256 public launch;

    
    constructor(address _presale) {
        presale = _presale;
    }

    // designed to be updateable incase more contribution amount is set, true indicates vote for refund
    function vote(bool _refund) public {
        uint256 contribAmount = IPesale(presale).amountPurchased(msg.sender);
        require(contribAmount > 0,"must be a contributor to vote");

        // if shares > 0, user voted before.
        uint256 previousVoteShares = shares[msg.sender];
        if (previousVoteShares > 0) {
            if(votes[msg.sender]) {
                refund -= previousVoteShares;
            } else {
                launch -= previousVoteShares;
            }
        }

    
        if (_refund) {
            refund += contribAmount; 
        } else {
            launch += contribAmount;
        }

        shares[msg.sender] = contribAmount;
        votes[msg.sender] = _refund;
    
        emit voted(msg.sender, _refund, contribAmount);
    }
}