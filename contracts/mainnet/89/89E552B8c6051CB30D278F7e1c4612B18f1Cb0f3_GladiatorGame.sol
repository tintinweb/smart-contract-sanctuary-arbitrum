// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract GladiatorGame {
    struct Gladiator {
        string name;
        uint power;
        bool alive;
    }

    Gladiator[] public gladiators;

    function createGladiator(string memory _name, uint _power) public {
        gladiators.push(Gladiator(_name, _power, true));
    }

    function battle(uint gladiator1Id, uint gladiator2Id) public {
        Gladiator storage gladiator1 = gladiators[gladiator1Id];
        Gladiator storage gladiator2 = gladiators[gladiator2Id];

        require(gladiator1.alive, "Gladiator 1 is already dead");
        require(gladiator2.alive, "Gladiator 2 is already dead");

        if(gladiator1.power > gladiator2.power) {
            gladiator2.alive = false;
        } else if(gladiator2.power > gladiator1.power) {
            gladiator1.alive = false;
        }
    }
}