/**
 *Submitted for verification at Arbiscan on 2023-03-09
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface Wargame {
    function canStartMatch(address player) view external returns(bool);
    function getCurrentMatch(address player) view external returns(uint256, uint256, bool, bool);
    function getLastMatch(address player) view external returns(bool[] memory, uint256, uint256, uint256);
    function isMatchReady(address player) view external returns(bool);
    function getAllStats(address player) view external returns(bool[] memory, uint256, uint256, uint256, 
        uint256, uint256, bool);
    function getInterimResults(address player) view external returns(uint256);
    function resetMatch(address player) external;
    function startMatch(address player, uint256 _lixStake, bool _boosted) external;
    function endMatch(address player) external;
}

contract WargameBossClient {

    event bossMatchStarted(address indexed from, uint256 lixStake, bool matchBoosted);
    event bossMatchEnded(address indexed from, uint256 lixStake, uint256 tokensWon, uint256 numberOfWins, 
        bool matchBoosted);

    address public owner;
    uint256 public featureStage;
    Wargame public wargame;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner"); 
        _;
    }

    constructor(address _wargame) {
        owner = msg.sender;
        wargame = Wargame(_wargame);
    }

    function setWargame(address _wargame) public onlyOwner {
        wargame = Wargame(_wargame);
    }

    function setFeatureStage(uint256 stage) public onlyOwner {
        featureStage = stage;
    }

    function canStartMatch(address player) view public returns(bool) {
        return wargame.canStartMatch(player);
    }

    function getCurrentMatch(address player) view public returns(uint256 lixStake, uint256 startTimestamp, 
        bool matchActive, bool matchBoosted) {
        (lixStake, startTimestamp, matchActive, matchBoosted) = wargame.getCurrentMatch(player);
    }

    function getLastMatch(address player) view public returns(bool[] memory matchOutcomes, uint256 tokensWon, 
        uint256 endTimestamp, uint256 numberOfWins) {
        (matchOutcomes, tokensWon, endTimestamp, numberOfWins) = wargame.getLastMatch(player);    
    }

    function getAllStats(address player) view public returns(bool[] memory matchOutcomes, uint256 lixStake, uint256 tokensWon, 
        uint256 startTimestamp, uint256 endTimestamp, uint256 numberOfWins, bool matchBoosted) {
        (matchOutcomes, lixStake, tokensWon, startTimestamp, endTimestamp, numberOfWins, 
            matchBoosted) = wargame.getAllStats(player);
    }

    function getInterimResults(address player) view public returns(uint256) {
        return wargame.getInterimResults(player);
    }

    function isMatchReady(address player) view public returns(bool) {
        return wargame.isMatchReady(player);        
    }

    function resetBossMatch() public {
        wargame.resetMatch(msg.sender);
    }

    function startBossMatch(uint256 lixStake, bool matchBoosted) public {
        wargame.startMatch(msg.sender, lixStake, matchBoosted);
        emit bossMatchStarted(msg.sender, lixStake, matchBoosted);
    }

    function endBossMatch() public {
        wargame.endMatch(msg.sender);
        (,uint256 lixStake, uint256 tokensWon,,, uint256 numberOfWins, bool matchBoosted) = wargame.getAllStats(msg.sender);
        emit bossMatchEnded(msg.sender, lixStake, tokensWon, numberOfWins, matchBoosted);
    }

    function getSelfAddress() public view returns(address) {
        return address(this);
    }

}