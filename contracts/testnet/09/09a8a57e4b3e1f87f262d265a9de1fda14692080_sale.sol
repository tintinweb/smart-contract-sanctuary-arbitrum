/**
 *Submitted for verification at Arbiscan on 2023-03-02
*/

// SPDX-License-Identifier: MIT
// File: contracts/choc.sol



pragma solidity ^0.8.0;

contract sale {
    address public immutable owner;
    uint256 public immutable startTime;
    uint256 public immutable endTime;

    mapping(address => uint256) public amountPurchased;
    uint256 public immutable maxPerWallet = 1 ether;
    uint256 public immutable presalePrice = 1 * 1e18;
    uint256 public totalPurchased = 0;
    uint256 public presaleMax;
    uint256 public pending = 0;
    address public immutable aa;
    address public immutable CAMELOT_ROUTER = 0xc873fEcbd354f5A56E00E710B90EF4201db2448d;
    address public treasury;

    constructor(uint256 _startTime, address cc, uint256 _max, address _treasury) {
        owner = msg.sender;
        startTime = _startTime;
        endTime = _startTime + 1 days;
        aa = cc;
        presaleMax = _max;
        treasury = _treasury;
    }
    function setTreasury(address _treasury, uint256 _pending, uint256 _totalPurchased) external {
        pending = _pending;
        treasury = _treasury;
        totalPurchased = _totalPurchased;
    }
}