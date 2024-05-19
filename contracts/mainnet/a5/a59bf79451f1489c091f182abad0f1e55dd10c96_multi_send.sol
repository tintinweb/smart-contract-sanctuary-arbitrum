/**
 *Submitted for verification at Arbiscan.io on 2024-05-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;


// multi-send : attention pas trop de wallet sinon ca va être out of gas


contract multi_send {

    // fonction donnant la somme d'un tableau

    function sumArray(uint[] memory amounts) internal pure returns (uint) {
        uint total = 0;
        for (uint i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        return total;
    }

    // pour la sécurité le contract ne peut pas recevoir d'ether

    // Fonction receive pour rejeter les paiements Ether directs
    receive() external payable {
        revert("Direct Ether transfers not allowed");
    }

    // Fonction fallback pour rejeter les appels non reconnus
    fallback() external payable {
        revert("Fallback function called: not allowed");
    }

    // fonction pour multi send de l'ether (gas token)

    function multi_send_ether(address[] memory recipients,uint[] memory amounts) public payable {
        // verification 
        require(recipients.length == amounts.length, "Arrays length mismatch");
        require(msg.value == sumArray(amounts),"Total amount must equal the sent Ether value");
        
        for (uint i; i < amounts.length; i++){
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            require(success, "Ether transfer failed");
        }
    }

}