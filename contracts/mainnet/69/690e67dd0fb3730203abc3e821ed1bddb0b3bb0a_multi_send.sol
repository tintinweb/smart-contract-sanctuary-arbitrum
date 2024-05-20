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


    // fonction pour split send d'ether (gas token)
    function split_send_eth(address[] memory recipients) public payable {
        // on va créer les tableaux en splittant les amounts et en renvoyant sur surplus
        uint amount = msg.value;
        uint length = recipients.length;

        require(length > 0, "No recipients provided");

        uint return_amount = amount % length;
        uint split_amount = amount/ length ;

        // on crée un tableau pour la fonction multi send d'ether avec 
        // les amounts et les recipients
        
        uint[] memory   amounts = new uint[](length + 1);
        address[] memory modify_recipients = new address[](length+1);

        modify_recipients[0] = msg.sender;
        amounts[0] = return_amount;

        for (uint i=1; i < amounts.length; i++){
            amounts[i] = split_amount;
            modify_recipients[i] = recipients[i-1];
        }
        multi_send_ether(modify_recipients, amounts);
    }

    // fonction pour multi send d'ether (gas token)
    function multi_send_ether(address[] memory recipients,uint[] memory amounts) public payable {
        // verification 
        require(recipients.length == amounts.length, "Arrays length mismatch");
        uint total_amount = sumArray(amounts);
        require(msg.value == total_amount,"Total amount must equal the sent Ether value");

        // on crée un tableau pour la fonction multi send d'ether avec 
        // les amounts et les recipients

        for (uint i; i < amounts.length; i++){
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            require(success, "Ether transfer failed");
        }
    }
}