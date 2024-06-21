/**
 *Submitted for verification at Arbiscan.io on 2024-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReceptionContract {
    address public owner;
    uint256 public balanceReceived;

    event FundsReceived(address indexed from, uint256 amount);

    constructor() {
        owner = msg.sender; // Le créateur du contrat devient le propriétaire
    }

    // Cette fonction permet à ce contrat de recevoir des fonds
    receive() external payable {
        balanceReceived += msg.value; // Ajoute le montant reçu au solde du contrat
        emit FundsReceived(msg.sender, msg.value); // Émet un événement pour indiquer la réception de fonds
    }

    // Cette fonction permet au propriétaire de récupérer les fonds reçus
    function withdrawFunds(uint256 amount) external {
        require(msg.sender == owner, "Seul le proprietaire peut effectuer cette operation");
        require(amount <= address(this).balance, "Le solde du contrat est insuffisant");

        payable(owner).transfer(amount); // Transfère les fonds au propriétaire
    }

    // Fonction utilitaire pour retourner le solde du contrat
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}