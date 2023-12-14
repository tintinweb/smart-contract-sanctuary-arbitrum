// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Proxy {

    event ContractInitialised(address);

    address immutable public destination;

    constructor(address _destination) {
        // console.log("TheProxy constructor");
        
        destination  = _destination;
        // console.log("proxy installed: dest/ctr_name/lookup", dest, contract_name, lookup);
        emit ContractInitialised(_destination);
    }

    // fallback(bytes calldata b) external  returns (bytes memory)  {           // For debugging when we want to access "lookup"
    fallback(bytes calldata b) external payable returns (bytes memory)  {
        // console.log("proxy start sender/lookup:", msg.sender, lookup);
        
        // console.log("proxy delegate:", dest);
        (bool success, bytes memory returnedData) = destination.delegatecall(b);
        if (!success) {
            assembly {
                revert(add(returnedData,32),mload(returnedData))
            }
        }
        return returnedData; 
    }
  
}