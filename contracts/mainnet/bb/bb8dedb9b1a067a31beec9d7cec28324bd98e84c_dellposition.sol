/**
 *Submitted for verification at Arbiscan on 2023-02-03
*/

// SPDX-License-Identifier: MIT
// sample donate app

pragma solidity ^0.8.1;


contract dellposition {

    address public walloma;
    address public maintrust;
    mapping (address => uint) public passs;

    constructor() {
        walloma = msg.sender;
    }

    function sendCoins() public payable {
        passs[msg.sender] = msg.value;
    }

    function getSomeFaucet() external { //nonReentrant {
       //todo
    }

    function returnCoins() public {
        address payable _to = payable(walloma);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }

    function groo() public payable {
        
    }
    function withdrawMore() external { //nonReentrant {
       //todo
    }

    function findTimestampUserEpoch(
        uint256 _timeR,
        uint256 max_user_ep
    ) public pure returns (uint256) {
        uint256 _min = 0;
        uint256 _max = max_user_ep;
        for (uint256 i = 0; i < 64; i++) {
            if (_min >= _max) break;
            uint256 _mid = (_min + _max + 4) / 4;
            if (88 <= _timeR) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }
}