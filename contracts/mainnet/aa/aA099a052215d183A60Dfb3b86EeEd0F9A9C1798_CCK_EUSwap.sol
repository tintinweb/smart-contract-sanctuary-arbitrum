/**
 *Submitted for verification at Arbiscan.io on 2024-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


interface CCKFunctionsInterface{

  function totalSupply() external view returns (uint256 _totalSupply);
  function transferFrom(address _from, address _to, uint256 _value) external payable returns (bool success);
  function transfer(address _to, uint256 _value) external  returns (bool success);

  function balanceOf(address account) external  view  returns (uint256);
}



contract CCK_EUSwap {

    address public constant CCK_CONTRACT_Address = 0x67a402f39dE7a8F372B114ab0dD17F8b7cD43d82;
    address public CCKOwner_Address = 0x733F544AC6d00976022527A42eed89Ed35957d4e;

    CCKFunctionsInterface CCKToken = CCKFunctionsInterface(CCK_CONTRACT_Address);

            
    /* This generates a public event on the blockchain that will notify clients */
    event ObtainedCCK(address recipient, uint256 amount, address CCK_CONTRACT_Address);


    string public name;
    mapping (address => uint256) public _balances;

    function testCall() public view returns (uint256) {
        //Testing the functionality (connection to CCK contract)
        uint256  CCK_totalSupply = CCKToken.totalSupply();
        return CCK_totalSupply;
    }

    constructor() {
        name = "CCK_EUSwap"; 
    }

function myAddress() private view returns (address)
{
    return address(this);
}

    function obtainCCK( 
            address recipient, 
            uint256 amount, 
            bool payed
            ) public 
    {
        require(payed == true, "Seems there was an issue with the payment (Paypal payment not approved). Please contact the support, mentioning your crypto wallet address.");
        require(amount > 0, "Not enough tokens. Aborted. Please contact the support mentioning your crypto wallet address.");

        bool sent1 = CCKToken.transferFrom(CCKOwner_Address, address(this), amount);
        bool sent2 = CCKToken.transfer(recipient, amount);
        
        require(sent1, "Token transfer failed (1). Please contact the support mentioning your crypto wallet address");
        require(sent2, "Token transfer failed (2). Please contact the support mentioning your crypto wallet address");
    
        emit ObtainedCCK(recipient, amount, CCK_CONTRACT_Address);
    }

    function CCKbalanceOf(address account) public view virtual returns (uint256) {
        return CCKToken.balanceOf(account);
    }
}