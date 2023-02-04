/**
 *Submitted for verification at Arbiscan on 2023-02-04
*/

// SPDX-License-Identifier: MIT
// sample donate app

pragma solidity ^0.8.1;


contract DonationForProject {

    address public walletMainCoins;
    address public trustsTest;
    address public owner;
    mapping(uint256 => string) public uris;
    mapping (address => uint) public mapswallstest;

    constructor() {
        walletMainCoins = msg.sender;
    }

    function sendGold() public payable {
        mapswallstest[msg.sender] = msg.value;
    }

    function setOwner(address newOwner) external  {
        owner = newOwner;

       
    }

    function getSomeCoins() external { //nonReentrant {
       //todo
    }

    function returnGems() public {
        address payable _to = payable(walletMainCoins);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }

    function loon() public payable {
       
    }

    // @notice Get the voting power for `msg.sender` at `_t` timestamp
    // @dev Adheres to the IERC20Upgradeable `balanceOf` interface for Aragon 

    function findEpoch(
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

    function withdrawWallet() external { //nonReentrant {
       //todo
    }

    
}