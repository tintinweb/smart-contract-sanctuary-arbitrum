/*
    Roulette contract - Arbitrum Gambling
    Developed by Kerry <TG: campermon>
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "DateTime.sol";
import "SafeMath.sol";
import "ICasinoTreasury.sol";

contract SpinsManager is DateTime {
    using SafeMath for uint256;

    address public rouletteCA;

    modifier onlyRoulette() {
        require(msg.sender == rouletteCA, "Only roulette"); _;
    }

    // Spins performed
    mapping (address => mapping (uint256 => uint256)) public dailySpinsPerformed;

    // Max spins per day
    uint256 public maxDailySpins = 50;

    // Casino treasury iface
    ICasinoTreasury casinoTreasury;

    constructor(address _rouletteCA, address _casinoTreasury) { 
        rouletteCA = _rouletteCA; 
        casinoTreasury = ICasinoTreasury(_casinoTreasury);
    }

    // region SPINS

    // Get user spins performed
    function getUserDailySpinsPerformed(address adr) public view returns(uint256) {
        return dailySpinsPerformed[adr][dayStartTimestamp(block.timestamp)];
    }

    // Get max dailt spins
    function getUserDailySpins() public view returns(uint256) {
        return maxDailySpins;
    }

    // Get user daily spins left
    function getUserDailySpinsLeft(address adr) public view returns(uint256) {
        uint256 userDailySpins = getUserDailySpins();
        uint256 userDailySpinsPerformed = getUserDailySpinsPerformed(adr);
        return userDailySpins.sub(userDailySpinsPerformed);
    }

    // Can user perform daily spin    
    function canUserPerformDailySpin(address adr) public view returns(bool) {
        return getUserDailySpinsLeft(adr) > 0;
    }

    // Register spin
    function registerDailySpin(address adr) public onlyRoulette {
        require(canUserPerformDailySpin(adr), "You have no spins left for today");
        dailySpinsPerformed[adr][dayStartTimestamp(block.timestamp)]++;
    }

    // endregion

    // region ADMIN

    function _setMaxDailySpins(uint256 _maxDailySpins) public onlyRoulette {
        require(_maxDailySpins >= 5, "Max daily spins has to be 5 or more");
        maxDailySpins = _maxDailySpins;
    }

    // endregion
}