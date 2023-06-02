/**
 *Submitted for verification at Arbiscan on 2023-06-02
*/

//Fooyao Pass contract: 0x2d6c9ABB7cF4409063E3A6eaBBC428f3c1FF29f2
//微信 fooyao

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface interfaceMaster {
  function batch_mint(address to, address target, uint8 times) external payable;
}

contract Fooyao_batch_mint {
    interfaceMaster private  fooyao = interfaceMaster(0x0936e1B62916E4582502c81abDE9CF02c44a9959);
    address private immutable owner;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }


    function batch_mint(address target, uint8 times) external payable  {
		fooyao.batch_mint{value: msg.value}(msg.sender, target, times);
	}

    function set_fooyao(address target) external isOwner {
		fooyao = interfaceMaster(target);
	}

}