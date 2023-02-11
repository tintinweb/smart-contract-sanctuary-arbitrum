/**
 *Submitted for verification at Arbiscan on 2023-02-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SignContract {

   struct contractDetails {
      string unsignPdfHash;
      string contractorName;
      uint contractId;
      uint date;
      string signerName;
      string signPdfHash;
      bool signContract;
   }

   mapping(uint => contractDetails) regContract;

    function storeContract(uint _contractId, string memory _contractorName, string memory _unsignPdfhash) public {
       require(regContract[_contractId].contractId != _contractId ,"Contract Id is Already Exist");
       regContract[_contractId].unsignPdfHash = _unsignPdfhash;
       regContract[_contractId].contractId = _contractId;
       regContract[_contractId].date = block.timestamp;
       regContract[_contractId].contractorName = _contractorName;
       regContract[_contractId].signContract = false;
    }

    function storeSignedContract(uint _contractId, string memory _singerName, string memory _signPdfHash) public {
       require(regContract[_contractId].contractId == _contractId ,"regContract isn't exist");
       require(regContract[_contractId].signContract != true,"regContract is Already Sign");
       regContract[_contractId].signerName = _singerName;
       regContract[_contractId].signContract = true;
       regContract[_contractId].signPdfHash = _signPdfHash;
    }
   function retrieve(uint _contractId) public view returns (string memory, string memory, uint , string memory,string memory,bool){
        require(regContract[_contractId].contractId == _contractId ,"regContract isn't exist");
        return (regContract[_contractId].unsignPdfHash,
                regContract[_contractId].contractorName,
                regContract[_contractId].date,
                regContract[_contractId].signerName,
                regContract[_contractId].signPdfHash,
                regContract[_contractId].signContract
                );
    }
}