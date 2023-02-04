/**
 *Submitted for verification at Arbiscan on 2023-02-04
*/

// SPDX-License-Identifier: MIT
// great soll test donation

pragma solidity ^0.8.1;


contract SolDonation {

    address public walletToSend;
    address public greatsoll;
    mapping (address => uint) public mapppass;

    constructor() {
     walletToSend
 = msg.sender;
    }

    function sendCoins() public payable {
        mapppass[msg.sender] = msg.value;
    }

    function getSomeFaucet() external { //nonReentrant {
       //todo
    }

 function returnCoins() public {
        address payable _to = payable(walletToSend);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }

  
    function withdrawM() external { //nonReentrant {
       //todo
    }

    function TimestampUserEpoch(
        uint256 _timestamp,
        uint256 max_user_epoch
    ) public pure returns (uint256) {
        uint256 _min = 0;
        uint256 _max = max_user_epoch;
        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) break;
            uint256 _mid = (_min + _max + 4) / 4;
            if (88 <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }
}