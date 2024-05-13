/**
 *Submitted for verification at Arbiscan.io on 2024-05-11
*/

// SPDX-License-Identifier: GPL 0.8.0
pragma solidity ^0.8.0;

contract AutorisationRetrait {
    address public createur;
    mapping(address => bool) public autorisations;

    event AutorisationDonnee(address utilisateur);
    event AutorisationRevoquee(address utilisateur);
    event RetraitEffectue(address destinataire, uint montant);
    event RetraitCreateur(uint montant);

    constructor() {
        createur = msg.sender;
    }

    modifier onlyCreateur() {
       require(msg.sender == createur, "Seul le createur peut effectuer cette action");
    _;
}
    modifier autorise() {
        require(autorisations[msg.sender] || msg.sender == createur, "Vous n etes pas autorise a effectuer cette action");
        _;
    }

    function accorderAutorisation(address utilisateur) public onlyCreateur {
        autorisations[utilisateur] = true;
        emit AutorisationDonnee(utilisateur);
    }

    function estAutorise(address utilisateur) public view returns (bool) {
        return autorisations[utilisateur];
    }

    function retirerFonds(address payable destinataire, uint montant) public autorise {
        require(address(this).balance >= montant, "Solde insuffisant dans le contrat");
        destinataire.transfer(montant);
        emit RetraitEffectue(destinataire, montant);
    }

    function retirerAutorisation(address utilisateur) public onlyCreateur {
        autorisations[utilisateur] = false;
        emit AutorisationRevoquee(utilisateur);
    }

    function retirerVersCreateur(uint montant) public onlyCreateur {
        require(address(this).balance >= montant, "Solde insuffisant dans le contrat");
        payable(createur).transfer(montant);
        emit RetraitCreateur(montant);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}