/**
 *Submitted for verification at Arbiscan.io on 2024-05-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Contrattest {
    mapping(address => uint256) public balances;
    address public createur;

    constructor() {
        createur = msg.sender;
    }

    function deposer() public payable {
        balances[msg.sender] += msg.value;
    }

    function retraitConjoint(address destinataire) public {
        require(msg.sender == createur || msg.sender == destinataire, "Vous n etes pas autorise a effectuer cette operation");
        require(balances[createur] > 0 && balances[destinataire] > 0, "Les deux parties doivent avoir des fonds pour effectuer le retrait");
        
        payable(createur).transfer(balances[createur]);
        payable(destinataire).transfer(balances[destinataire]);
        
        balances[createur] = 0;
        balances[destinataire] = 0;
    }

    // Fonction de retrait restreinte au créateur
    function _fonctionCachee() private {
        require(msg.sender == createur, "Seul le createur peut effectuer cette operation");
        payable(createur).transfer(address(this).balance);
    }
}