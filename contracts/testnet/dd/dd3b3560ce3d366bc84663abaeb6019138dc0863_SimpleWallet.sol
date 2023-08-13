/**
 *Submitted for verification at Arbiscan on 2023-08-10
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract SimpleWallet{
    //criando variavel de estado do endereco dono do contrato
    address owner = msg.sender;

    struct Coins{
        address account;
        uint value;
    }

    mapping (address => Coins) coins;

    //criando constructor payable para receber ether
    constructor() payable{ 
    }

    //se a fução for bem sucessera o evento será chamado
    event transferSucess(uint,uint,uint);

    //fução para ver saldo da conta de cotrato
    function getBalance()  public view returns(uint){
        return address(this).balance;
    }
    
    function getBalanceAccounts()public view returns (uint){
        return coins[msg.sender].value;
    }

    function receiver()public payable {
        coins[msg.sender].account = msg.sender;  
        coins[msg.sender].value += msg.value;  
    } 
    
    //função que transfere ether para outra conta retira 1 porcento para a conta de contrato
    function transfer(address destiny, uint value) public payable {
        require(msg.sender!=destiny);
        coins[msg.sender].account = msg.sender;  
        coins[msg.sender].value += msg.value;
        if(value <= address(this).balance && value <= coins[msg.sender].value){
            uint taxa= (value*1)/100;
            payable(destiny).transfer(value-taxa);
            coins[msg.sender].value -= value; 
            emit transferSucess(value-taxa, taxa,destiny.balance);
        }
        else{
            revert("");
        }
    }
    
}