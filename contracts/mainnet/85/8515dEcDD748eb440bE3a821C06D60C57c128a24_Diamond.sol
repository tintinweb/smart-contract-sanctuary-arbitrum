// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
* 
* Implementation of a diamond.
/******************************************************************************/

import "./LibDiamond.sol";
import "./LibDiamondOwnership.sol";
import "./LibERC20.sol";
import "./IDiamondLoupe.sol";
import "./IDiamondCut.sol";
import "./IERC173.sol";
import "./IERC165.sol";
import "./IERC20.sol";

contract Diamond {

    struct DiamondArgs {
		address contractOwner;
		string  name_;
		string  symbol_;
		uint8   decimal_;
		uint256 capSupply_;
		uint256 preMint;
		address preMintOwner;
    }
	
	constructor(
        IDiamondCut.FacetCut[] memory _diamondCut,
		DiamondArgs memory _args
    ) payable {
		
        LibDiamond.diamondCut(_diamondCut, address(0), new bytes(0));
		LibDiamondOwnership.setContractOwner(_args.contractOwner);
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        // adding ERC165 data
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
		ds.supportedInterfaces[type(IERC173).interfaceId] = true;
		ds.supportedInterfaces[type(IERC20).interfaceId] = true;
		ds._name = _args.name_;
		ds._symbol = _args.symbol_;
		ds._decimal = _args.decimal_;
		ds._capSupply = _args.capSupply_ * 10 **_args.decimal_;
		LibERC20._mint(_args.preMintOwner, _args.preMint * 10 ** _args.decimal_);
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamondStorage.DiamondStorage storage ds;
        bytes32 position = LibDiamondStorage.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}