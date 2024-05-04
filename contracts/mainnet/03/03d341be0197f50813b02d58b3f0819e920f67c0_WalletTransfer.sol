/**
 *Submitted for verification at Arbiscan.io on 2024-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WalletTransfer {
    address payable owner;
    
    // Evento que será emitido após a transferência bem sucedida
    event TransferSuccessful(address indexed from, address indexed to, uint256 amount);
    
    // Modificador para garantir que apenas o proprietário possa chamar uma função
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = payable(msg.sender);
    }
    
    // Função para transferir todo o saldo para um endereço específico
    function transferTo(address payable _to) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to transfer");
        
        // Calcula a taxa de gás estimada
        uint256 gasFee = tx.gasprice * 21000; // Gas limit padrão para uma transferência
        
        // Calcula o valor a ser transferido, descontando a taxa de gás
        uint256 amountToSend = balance - gasFee;
        
        // Realiza a transferência
        _to.transfer(amountToSend);
        
        // Emite o evento de transferência bem sucedida
        emit TransferSuccessful(address(this), _to, amountToSend);
    }
    
    // Função para receber pagamentos (opcional)
    receive() external payable {}
    
    // Função para receber pagamentos (opcional)
    fallback() external payable {}
}