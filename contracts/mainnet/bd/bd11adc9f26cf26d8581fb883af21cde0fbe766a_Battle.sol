/**
 *Submitted for verification at Arbiscan on 2022-12-09
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/** 
 *  GM Adventurer!
 *  The town is filled with monsters and we need your help! 
 *  Battle and slay them and we'll pay you a hefty sum of gold and silver!
 */

contract Battle {

    struct Hero {
        string name;
        int health;
        int strength;
        int agility;
        int wisdom;
    }

    struct Spawn {
        int health;
        int strength;
        int agility;
        int wisdom;
    }

    struct Round {
        uint roundNo;
        uint totalAttacks;
        uint firstAttackIndex;
        uint lastAttackIndex;
        bool result;
        uint coinsWon;
        string playerName;
        address playerAddress;
    }

    struct Attack {
        uint roundIndex;
        uint attackIndex;
        int heroHealth;
        int heroDamageDealt;
        int spawnHealth;
        int spawnDamageDealt;
    }

    Hero[] players;
    Spawn[] spawns;
    Round[] rounds;
    Attack[] attacks;
    uint gameCounter;

    int[] attributesArray = [1,2,3,4,5,6,7,8,9,10];

    function addHero(string memory _name, int _health, int _strength, int _agility, int _wisdom) private {
        Hero memory newHero = Hero(_name, _health, _strength, _agility, _wisdom);
        players.push(newHero);
    }

    function addSpawn(int _health, int _strength, int _agility, int _wisdom) private {
        Spawn memory newSpawn = Spawn(_health, _strength, _agility, _wisdom);
        spawns.push(newSpawn);
    }

    function addRound(uint _roundNo, uint _totalAttacks, uint _firstAttackIndex, uint _lastAttackIndex, bool _result, uint _score, string memory _name, address _address) private {
        Round memory newRound = Round(_roundNo, _totalAttacks, _firstAttackIndex, _lastAttackIndex, _result, _score, _name, _address);
        rounds.push(newRound);
    }

    function addAttack(uint _roundIndex, uint _attackIndex, int _heroHealth, int _heroDamageDealt, int _spawnHealth, int _spawnDamageDealt) private {
        Attack memory newAttack = Attack(_roundIndex, _attackIndex, _heroHealth, _heroDamageDealt, _spawnHealth, _spawnDamageDealt);
        attacks.push(newAttack);
    }

    // Generate pseudo-random nos for attributes
    // Inspired by Loot contract - MIT license
    // https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7#code
    function getStrength(uint256 _index, string memory _name) internal view returns (int) {
        return pluck(_index, "STRENGTH", attributesArray, _name);
    }
    
    function getAgility(uint256 _index, string memory _name) internal view returns (int) {
        return pluck(_index, "AGILITY", attributesArray, _name);
    }
    
    function getWisdom(uint256 _index, string memory _name) internal view returns (int) {
        return pluck(_index, "WISDOM", attributesArray, _name);
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function pluck(uint256 _index, string memory keyPrefix, int[] memory sourceArray, string memory _name) internal pure returns (int) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(_index), _name)));
        int output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function getHero(uint _index) public view returns (string memory, int, int, int, int) {
        Hero memory heroToReturn = players[_index];
        return (heroToReturn.name, heroToReturn.health, heroToReturn.strength, heroToReturn.agility, heroToReturn.wisdom);
    }

    function getSpawn(uint _index) public view returns (int, int, int, int) {
        Spawn memory spawnToReturn = spawns[_index];
        return (spawnToReturn.health, spawnToReturn.strength, spawnToReturn.agility, spawnToReturn.wisdom);
    }

    function roundDetails(uint _index) public view returns (uint, uint, uint, uint, bool, uint, string memory, address) {
        Round memory roundToReturn = rounds[_index];
        return (roundToReturn.roundNo, roundToReturn.totalAttacks, roundToReturn.firstAttackIndex, roundToReturn.lastAttackIndex, roundToReturn.result, roundToReturn.coinsWon, roundToReturn.playerName, roundToReturn.playerAddress);
    }

    function attackDetails(uint _index) public view returns (uint, uint, int, int, int, int) {
        Attack memory attackToReturn = attacks[_index];
        return (attackToReturn.roundIndex, attackToReturn.attackIndex, attackToReturn.heroHealth, attackToReturn.heroDamageDealt, attackToReturn.spawnHealth, attackToReturn.spawnDamageDealt);
    }

    function lastGameIndex() public view returns (uint) {
        return rounds.length-1;
    }

    function mapPlayer(string memory _name, uint _counter) internal returns (uint) {
        addHero(_name, 100, getStrength(_counter*100, _name), getAgility(_counter*101, _name), getWisdom(_counter*102, _name));
        return players.length-1; // return index of newly mapped player // return value unused
    }
    
/** 
 *  A spawn with randomized attributes is generated every battle.
 *  - STR: Determines attack damage
 *  - AGI: Determines defence armour (reduces attack damage received)
 *  - WIS: Add bonus damage if player WIS is higher than spawn WIS
 *  - Player passive skill: Pray()
 *  - Spawn passive skill: Harden()
 */

    function battle(string memory _name) public returns (uint) {
        // increment counter
        gameCounter++;
        // initialize player
        mapPlayer(_name, gameCounter);
        uint256 currentIndex = players.length-1;
        // initialize spawn
        addSpawn(100, getStrength(currentIndex*201, _name), getAgility(currentIndex*202, _name), getWisdom(currentIndex*203, _name));
        // initialize variables used for entire battle (round)
        uint attackCounter = 0;
        uint startAttackIndex = 0 + attacks.length;
        // spawn has passive skill harden(): if player has unfair advantage, spawn gets a boost in attributes
        int playerTotalStats = players[currentIndex].strength + players[currentIndex].agility + players[currentIndex].wisdom;
        int spawnTotalStats = spawns[currentIndex].strength + spawns[currentIndex].agility + spawns[currentIndex].wisdom;
        if (playerTotalStats > spawnTotalStats + 5){
            spawns[currentIndex].strength += 2;
            spawns[currentIndex].agility += 2;
            spawns[currentIndex].wisdom += 1;
        } else if (playerTotalStats > spawnTotalStats + 10){
            spawns[currentIndex].strength += 4;
            spawns[currentIndex].agility += 4;
            spawns[currentIndex].wisdom += 2;
        } else if (playerTotalStats > spawnTotalStats + 15){
            spawns[currentIndex].strength += 6;
            spawns[currentIndex].agility += 6;
            spawns[currentIndex].wisdom += 3;
        }
        // start battle
        while (players[currentIndex].health > 0 && spawns[currentIndex].health > 0){
            // initialize variables only used in 1 attack
            int heroDamageDealt = 0;
            int spawnDamageDealt = 0;
            int bonusDamage = 0;
            int bonusDefence = 0;
            // player has passive skill pray() that triggers when low HP
            if (players[currentIndex].health < 25){
                players[currentIndex].health += 2; // add 2 HP before every attack
                bonusDamage = 2; // attack with 2 additional damage
                bonusDefence = 1; // take 1 less damage from spawn
            }
            // player attacks
            heroDamageDealt = 5 + players[currentIndex].strength - spawns[currentIndex].agility/2 + players[currentIndex].wisdom/spawns[currentIndex].wisdom + bonusDamage;
            spawns[currentIndex].health -= heroDamageDealt;
            // spawn attacks
            spawnDamageDealt = 5 + spawns[currentIndex].strength - players[currentIndex].agility/2 + spawns[currentIndex].wisdom/players[currentIndex].wisdom - bonusDefence;
            players[currentIndex].health -= spawnDamageDealt;
            // log attack
            addAttack(currentIndex, attackCounter, players[currentIndex].health, heroDamageDealt, spawns[currentIndex].health, spawnDamageDealt);
            // increment attack counter
            attackCounter++;
        }
        // check winner
        if (players[currentIndex].health <= 0 && spawns[currentIndex].health <= 0){
            addRound(currentIndex, attackCounter, startAttackIndex, attacks.length-1, false, 5, players[players.length-1].name, msg.sender);
        } else if (players[currentIndex].health > 0 && spawns[currentIndex].health <= 0){
            addRound(currentIndex, attackCounter, startAttackIndex, attacks.length-1, true, 20, players[players.length-1].name, msg.sender);
        } else if (players[currentIndex].health <= 0 && spawns[currentIndex].health > 0){
            addRound(currentIndex, attackCounter, startAttackIndex, attacks.length-1, false, 0, players[players.length-1].name, msg.sender);
        }
        // end game
        return rounds.length-1; // return index of this battle
    }
}