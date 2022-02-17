/**
 *Submitted for verification at arbiscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract Adoption {

    event PetAdopted(uint returnValue);

    address[16] public adopters = [
        address(0),
        address(0),
        address(0),
        address(0),
        address(0),
        address(0),
        address(0),
        address(0),
        address(0),
        address(0),
        address(0),
        address(0),
        address(0),
        address(0),
        address(0),
        address(0)
    ];

    // Adopting a pet
    function adopt(uint petId) public returns (uint) {
        require(petId >= 0 && petId <= 15);
        adopters[petId] = msg.sender;
        emit PetAdopted(petId);
        return petId;
    }

    // Retrieving the adopters
    function getAdopters() public view returns (address[16] memory) {
        return adopters;
    }
}