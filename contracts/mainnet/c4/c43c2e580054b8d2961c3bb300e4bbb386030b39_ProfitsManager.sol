/*
    Roulette contract - Arbitrum Gambling
    Developed by Kerry <TG: campermon>
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "DateTime.sol";
import "SafeMath.sol";

contract ProfitsManager is DateTime {
    using SafeMath for uint256;

    address public rouletteCA;

    modifier onlyRoulette() {
        require(msg.sender == rouletteCA, "Only roulette"); _;
    }

    // Daily profit
    mapping (address => mapping (uint256 => uint256)) public dailyProfit;
    // Daily losses
    mapping (address => mapping (uint256 => uint256)) public dailyLosses;
    // Weekly profit
    mapping (address => mapping (uint256 => uint256)) public weeklyProfit;
    // Weekly losses
    mapping (address => mapping (uint256 => uint256)) public weeklyLosses;

    // Max daily profit $ // Does not apply to free spins
    uint256 public maxDailyProfit = 50;
    // Max weekly profit $ // Does not apply to free spins   
    uint256 public maxWeeklyProfit = 300;

    constructor (address _rouletteCA) { rouletteCA = _rouletteCA; }

    //region VIEWS
    function getUserDailyProfit(address adr) public view returns(uint256) {
        return dailyProfit[adr][dayStartTimestamp(block.timestamp)];
    }

    function getUserWeeklyProfit(address adr) public view returns(uint256) {
        return weeklyProfit[adr][weekStartTimestamp(block.timestamp)];
    }

    function getUserDailyLosses(address adr) public view returns(uint256) {
        return dailyLosses[adr][dayStartTimestamp(block.timestamp)];
    }

    function getUserWeeklyLosses(address adr) public view returns(uint256) {
        return weeklyLosses[adr][weekStartTimestamp(block.timestamp)];
    }

    function amountLeftForDailyMaxProfit(address adr) public view returns(uint256) {
        uint256 _dailyProfit = getUserDailyProfit(adr);
        uint256 _dailyLosses = getUserDailyLosses(adr);

        if(_dailyProfit >= _dailyLosses) {
            uint256 _diff = _dailyProfit.sub(_dailyLosses);
            if(_diff >= maxDailyProfit) {
                return 0;
            } else {
                return maxDailyProfit.sub(_diff);
            }
        } else {
            return _dailyLosses.sub(_dailyProfit).add(maxDailyProfit);
        }
    }

    function amountLeftForWeeklyMaxProfit(address adr) public view returns(uint256) {
        uint256 _dailyProfit = getUserWeeklyProfit(adr);
        uint256 _dailyLosses = getUserWeeklyLosses(adr);

        if(_dailyProfit >= _dailyLosses) {
            uint256 _diff = _dailyProfit.sub(_dailyLosses);
            if(_diff >= maxWeeklyProfit) {
                return 0;
            } else {
                return maxWeeklyProfit.sub(_diff);
            }
        } else {
            return _dailyLosses.sub(_dailyProfit).add(maxWeeklyProfit);
        }
    }

    function maxDailyProfitReached(address adr) public view returns(bool) {
        uint256 _dailyProfit = getUserDailyProfit(adr);
        uint256 _dailyLosses = getUserDailyLosses(adr);

        return _dailyProfit > _dailyLosses.add(maxDailyProfit);
    }

    function maxWeeklyProfitReached(address adr) public view returns(bool) {
        uint256 _weeklyProfit = getUserWeeklyProfit(adr);
        uint256 _weeklyLosses = getUserWeeklyLosses(adr);

        return _weeklyProfit > _weeklyLosses.add(maxWeeklyProfit);
    }
    //endregion

    // Register profits
    function registerProfits(address adr, uint256 profitDollars) public onlyRoulette {
        dailyProfit[adr][dayStartTimestamp(block.timestamp)] += profitDollars;
        weeklyProfit[adr][weekStartTimestamp(block.timestamp)] += profitDollars;
    }

    // Register losses
    function registerLosses(address adr, uint256 lossesDollars) public onlyRoulette {
        dailyLosses[adr][dayStartTimestamp(block.timestamp)] += lossesDollars;
        weeklyLosses[adr][weekStartTimestamp(block.timestamp)] += lossesDollars;
    }

    // Admin
    function _setMaxDailyWeeklyProfit(uint256 _maxDailyProfit, uint256 _maxWeeklyProfit) public onlyRoulette {
        require(_maxDailyProfit >= 25, "Can not be lower than 25");
        require(_maxWeeklyProfit >= 100, "Can not be lower than 100");
        maxDailyProfit = _maxDailyProfit;
        maxWeeklyProfit = _maxWeeklyProfit;
    }
}