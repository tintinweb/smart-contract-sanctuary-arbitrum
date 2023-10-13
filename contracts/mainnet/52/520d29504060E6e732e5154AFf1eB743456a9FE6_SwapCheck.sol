pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import './SafeMath.sol';
import './Ownable.sol';
import  './Address.sol';

contract SwapCheck is Ownable{


    mapping(address => bool) public addressMapping;


    mapping(uint=>uint256) public rateMapping;

    mapping(address => bool) public checkAddressMapping;

    mapping(uint=> address) public addressIndexMapping;

    constructor (address _address0, address _address1,address _address2)  {
        addressMapping[_address0] = true;
        addressMapping[_address1] = true;
        addressMapping[_address2] = true;

        checkAddressMapping[_address0] = false;
        checkAddressMapping[_address1] = false;
        checkAddressMapping[_address2] = false;

        addressIndexMapping[1] = _address0;
        addressIndexMapping[2] = _address1;
        addressIndexMapping[3] = _address2;
    }

    function checkPermissions(address _userAddress) external view returns (bool) {
         return addressMapping[_userAddress];
    }
   
    function checkRemove() external  returns (bool){
        if(rateMapping[1]>50){
           rateMapping[1] = 0;
           if(checkAddressMapping[addressIndexMapping[1]]){
               checkAddressMapping[addressIndexMapping[1]] = false;
           }
            if(checkAddressMapping[addressIndexMapping[2]]){
               checkAddressMapping[addressIndexMapping[2]] = false;
           }
            if(checkAddressMapping[addressIndexMapping[3]]){
               checkAddressMapping[addressIndexMapping[3]] = false;
           }
           return true; 
        }
        return false;
    }

  
    function UpdateCheckAddress() external  returns (bool) {
       if(rateMapping[2]>50){
           rateMapping[2] = 0;
            if(checkAddressMapping[addressIndexMapping[1]]){
               checkAddressMapping[addressIndexMapping[1]] = false;
           }
            if(checkAddressMapping[addressIndexMapping[2]]){
               checkAddressMapping[addressIndexMapping[2]] = false;
           }
            if(checkAddressMapping[addressIndexMapping[3]]){
               checkAddressMapping[addressIndexMapping[3]] = false;
           }
           return true; 
        }
        return false;
    }

   
    function UpdateWAddress(address _newAddress,uint _index) external{
        require(rateMapping[3]>50,"rate lower");
        require(addressMapping[msg.sender],"not allow");
        addressMapping[msg.sender] = false;
        checkAddressMapping[msg.sender] = false;
        addressMapping[_newAddress] = true;
        checkAddressMapping[_newAddress] = false;
        addressIndexMapping[_index] = _newAddress;
        rateMapping[3] = 0;
    }

    function approve(uint checkType) external {
        require(addressMapping[msg.sender],"not allow");
        require(!checkAddressMapping[msg.sender],"once");
        checkAddressMapping[msg.sender] = true;
        rateMapping[checkType]+=33;
    }


    

}