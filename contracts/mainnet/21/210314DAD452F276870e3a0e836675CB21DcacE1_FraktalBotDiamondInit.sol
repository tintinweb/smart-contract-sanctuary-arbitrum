// SPDX-License-Identifier: FRAKTAL-PROTOCOl
pragma solidity 0.8.24;

import {IWETH} from '../shared/interfaces/IWETH.sol';


struct AppStore {
  string VERSION;
  IWETH WETH;
}

library LibAppStore {
  
}

// SPDX-License-Identifier: FRAKTAL-PROTOCOL
pragma solidity 0.8.24;


/******************************************************************************\
* Author: Kryptokajun <[email protected]> (https://twitter.com/kryptokajun1)
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../../shared/interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../../shared/interfaces/IDiamondCut.sol";
import { IERC173 } from "../../shared/interfaces/IERC173.sol";
import { IERC165 } from "../../shared/interfaces/IERC165.sol";
import { IWETH } from "../../shared/interfaces/IWETH.sol";
import { AppStore } from "../AppStore.sol";

import {LibAccessControl} from "../../shared/libraries/LibAccessControl.sol";
import {LibMeta} from "../../shared/libraries/LibMeta.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

contract FraktalBotDiamondInit {
    AppStore internal s;
    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init(uint8 decimals_, address _weth, address admin_) external {
        
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        
        // add your own state variables 
        s.WETH = IWETH(_weth);
        // Initialize the RoleManager contract with the specified admin role



        // EIP-2535 specifies that the `diamondCut` function takes two optional 
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface 
    }


}

// SPDX-License-Identifier: FRAKTAL-PROTOCOL
pragma solidity 0.8.24;

/******************************************************************************\
* Author: Kryptokajun <[email protected]> (https://twitter.com/kryptokajun1)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: FRAKTAL-PROTOCOL
pragma solidity 0.8.24;


/******************************************************************************\
* Author: Kryptokajun <[email protected]> (https://twitter.com/kryptokajun1)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: FRAKTAL-PROTOCOL
pragma solidity 0.8.24;


interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: FRAKTAL-PROTOCOL
pragma solidity 0.8.24;


/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IERC20Events {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

}
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20BaseModifiers {
    // modifier onlyMinter() {}
    // modifier onlyBurner() {}
    function _isERC20BaseInitialized() external view returns (bool);
}

interface IERC20Meta {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals () external view returns (uint8);

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { IERC20 } from './IERC20.sol';

interface IWETH is IERC20 {
  function deposit() external payable;
  function transfer(address to, uint256 value) external returns (bool);
  function withdraw(uint256) external;
}

// SPDX-License-Identifier: COPPER-PROTOCOL
pragma solidity ^0.8.0;

import { LibMeta } from "./LibMeta.sol";

struct AccessControlStorage {
    mapping(bytes32 => mapping(address => bool)) roles;
    mapping(address => bytes32[]) memberRoles;
    mapping(bytes32 => address[]) roleMembers;
    mapping(bytes32 => bytes32) roleAdmins;
    address owner;
    bool initialized;
}

library LibAccessControl {

    bytes32 constant STORAGE_POSITION = keccak256("copper-protocol.access_control.storage");

    function diamondStorage() internal pure returns (AccessControlStorage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // function setRoleAdmin(bytes32 roleId, bytes32 adminRoleId) internal {
    //     AccessControlStorage storage acs = diamondStorage();
    //     acs.roleAdmins[roleId] = adminRoleId;
    // }

    function _grantRole (bytes32 roleId, address account) internal {
        AccessControlStorage storage acs = diamondStorage();
       // Grant the role
        acs.roles[roleId][account] = true;
        
        // Update memberRoles and roleMembers mappings
        acs.memberRoles[account].push(roleId);
        acs.roleMembers[roleId].push(account);
        
        // Emit an event to log the role grant
        // emit RoleGranted(roleId, account, LibMeta.msgSender());

    }
    function grantRole(bytes32 roleId, address account) internal {
        AccessControlStorage storage acs = diamondStorage();
        
        // Check if the sender has the necessary permissions to grant roles
        require(hasRole(acs.roleAdmins[roleId], LibMeta.msgSender()), "AccessControl: sender does not have admin role");
        
        // Check if the account already has the role
        require(!hasRole(roleId, account), "AccessControl: account already has the role");
        _grantRole(roleId, account);
    }


    function revokeRole(bytes32 roleId, address account) internal {
        AccessControlStorage storage acs = diamondStorage();
        require(hasRole(roleId, account), "AccessControl: account does not have role");
        delete acs.roles[roleId][account];
        _removeFromRoleMembers(acs.memberRoles[account], roleId);
        _removeFromRoleMembers(acs.roleMembers[roleId], account);
    }

    function addRole(bytes32 roleId, bytes32 adminRoleId) internal {
        AccessControlStorage storage acs = diamondStorage();
        require(adminRoleId != bytes32(0), "AccessControl: invalid admin role");
        require(acs.roleAdmins[roleId] == bytes32(0), "AccessControl: role admin already set");
        acs.roleAdmins[roleId] = adminRoleId;
    }

    function removeRole(bytes32 roleId) internal {
        AccessControlStorage storage acs = diamondStorage();
        require(acs.roleAdmins[roleId] != bytes32(0), "AccessControl: role does not exist");
        delete acs.roleAdmins[roleId];
    }

    function _removeFromRoleMembers(bytes32[] storage members, bytes32 roleId) internal {
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == roleId) {
                if (i != members.length - 1) {
                    members[i] = members[members.length - 1];
                }
                members.pop();
                break;
            }
        }
    }

    function _removeFromRoleMembers(address[] storage members, address member) internal {
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == member) {
                if (i != members.length - 1) {
                    members[i] = members[members.length - 1];
                }
                members.pop();
                break;
            }
        }
    }

    function hasRole(bytes32 roleId, address account) internal view returns (bool) {
        AccessControlStorage storage acs = diamondStorage();
        return acs.roles[roleId][account];
    }

    function getRoleAdmin(bytes32 roleId) internal view returns (bytes32) {
        AccessControlStorage storage acs = diamondStorage();
        return acs.roleAdmins[roleId];
    }

    function getRoleMembers(bytes32 roleId) internal view returns (address[] storage) {
        AccessControlStorage storage acs = diamondStorage();
        return acs.roleMembers[roleId];
    }

    function getMemberRoles(address account) internal view returns (bytes32[] storage) {
        AccessControlStorage storage acs = diamondStorage();
        return acs.memberRoles[account];
    }

    function _checkRole(bytes32 roleId, address account) internal view {
        require(hasRole(roleId, account), "AccessControl: account does not have role");
    }

    function createRole(bytes32 roleId, bytes32 adminRoleId) internal {
        require(!hasRole(roleId, LibMeta.msgSender()), "AccessControl: role already exists");
        addRole(roleId, adminRoleId);
    }

    function setRoleAdmin(bytes32 roleId, bytes32 adminRoleId) internal {
        AccessControlStorage storage acs = diamondStorage();
        require(adminRoleId != bytes32(0), "AccessControl: invalid admin role");
        require(acs.roleAdmins[roleId] == bytes32(0), "AccessControl: role admin already set");
        acs.roleAdmins[roleId] = adminRoleId;
    }
}

// SPDX-License-Identifier: COPPER-PROTOCOL
pragma solidity 0.8.24;


/******************************************************************************\
* Author: Kryptokajun <[email protected]> (https://twitter.com/kryptokajun1)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
// import "hardhat/console.sol";
// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("fraktal-protocol.fraktal-bot..diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        // // console.log(msg.sender, diamondStorage().contractOwner);
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    // // console.logBytes(error);
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: COPPER-PROTOCOL
pragma solidity 0.8.24;

library LibMeta {
    // EIP712 domain type hash
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 salt,address verifyingContract)");

    // /**
    //  * @dev Generates the domain separator for EIP712 signatures.
    //  * @param name The name of the contract.
    //  * @param version The version of the contract.
    //  * @return The generated domain separator.
    //  */
    function domainSeparator(string memory name, string memory version) internal view returns (bytes32 domainSeparator_) {
        // Generate the domain separator hash using EIP712_DOMAIN_TYPEHASH and contract-specific information
        domainSeparator_ = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), getChainID(), address(this))
        );
    }

    // /**
    //  * @dev Gets the current chain ID.
    //  * @return The chain ID.
    //  */
    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    // /**
    //  * @dev Gets the actual sender of the message.
    //  * @return The actual sender of the message.
    //  */
    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}