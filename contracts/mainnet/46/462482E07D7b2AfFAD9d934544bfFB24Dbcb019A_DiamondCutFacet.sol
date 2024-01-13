// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../lib/LibDiamond.sol";
contract DiamondCutFacet is IDiamondCut {
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IDiamond {
    struct FacetCut{
        address  facetAddress;
        bytes4[] addSelectors;
        bytes4[] removeSelectors;   
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import { IDiamond } from "./IDiamond.sol";

interface IDiamondCut is IDiamond {    
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes memory _calldata
    ) external;    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import { IDiamond } from "../interfaces/IDiamond.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");
    struct DiamondStorage {
        //facet's function selector
        mapping(address=>bytes4[]) FacetAddressToSelectors;
        //all facets
        address[] facets;
        //selector corresponding facet
        mapping(bytes4=>address)  SelectorsToFacetAddress;
        //
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;


        //Allows access to the database whitelist
        mapping(address=>bool) dBControlWhitelist;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address init, bytes data);
    event SetDBControlWhitelist(address[]  _lists,bool[]  _status);
    function setDBControlWhitelist(address[] memory _lists,bool[] memory _status) internal {
        DiamondStorage storage ds = diamondStorage();
        for(uint256 i;i<_lists.length;i++){
            ds.dBControlWhitelist[_lists[i]]=_status[i];
        }
        emit SetDBControlWhitelist(_lists,_status);
    }

    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
          for(uint256 i=0;i<_diamondCut.length;i++){
              require(_diamondCut[i].facetAddress!=address(0),"facets must be valid address");  
              enforceHasContractCode(_diamondCut[i].facetAddress, "LibDiamondCut: Add facet has no code");
               if(_diamondCut[i].addSelectors.length>0){
                  addFunctions(_diamondCut[i].facetAddress,_diamondCut[i].addSelectors);   
               }

               if(_diamondCut[i].removeSelectors.length>0){
                  removeFunctions(_diamondCut[i].facetAddress,_diamondCut[i].removeSelectors); 
               }
          }
          initializeDiamondCut(_init,_calldata);
          emit DiamondCut(_diamondCut,_init,_calldata);
    }


    function addFunctions(address facetAddress, bytes4[] memory functionSelectors) internal {     
        DiamondStorage storage ds = diamondStorage();
        for(uint256 i=0;i<functionSelectors.length;i++){
              require(ds.SelectorsToFacetAddress[functionSelectors[i]]==address(0),"selector have already added");
              ds.SelectorsToFacetAddress[functionSelectors[i]]=facetAddress;
              ds.FacetAddressToSelectors[facetAddress].push(functionSelectors[i]);
        }

        address[] memory facets=ds.facets;
        bool isExist;
        for(uint256 i=0;i<facets.length;i++){
            if(facets[i]==facetAddress){
                isExist=true;
            }
        }
        if(!isExist){
             ds.facets.push(facetAddress);
        }
    }

    function removeFunctions(address facetAddress, bytes4[] memory functionSelectors) internal {      
        DiamondStorage storage ds = diamondStorage();
        for(uint256 i=0;i<functionSelectors.length;i++){
            require(ds.SelectorsToFacetAddress[functionSelectors[i]]!=address(0),"selector inexistence");
            delete ds.SelectorsToFacetAddress[functionSelectors[i]];
            bytes4[] memory selectors=ds.FacetAddressToSelectors[facetAddress];
            for(uint256 j=0;j<selectors.length;j++){
                 if(selectors[j]==functionSelectors[i]){
                      ds.FacetAddressToSelectors[facetAddress][j]=ds.FacetAddressToSelectors[facetAddress][selectors.length-1];
                      ds.FacetAddressToSelectors[facetAddress].pop();
                 }
            }
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");        
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert("delegatecall fail");
            }
        }        
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize != 0,_errorMessage);  
    }

}