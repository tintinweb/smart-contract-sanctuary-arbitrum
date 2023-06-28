// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/// @notice Singleton pattern for Ryze Platform, can run multiple markets on same underlying asset
/// @author https://balance.capital

import {IDiamondCut} from "../interfaces/eip2535/IDiamondCut.sol";
import {IDiamondLoupe} from "../interfaces/eip2535/IDiamondLoupe.sol";
import {IBinaryVaultPluginImpl} from "../interfaces/binary/IBinaryVaultPluginImpl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

library BinaryVaultStorage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
        mapping(bytes4 => address) pluginSelector;
        address[] pluginImpls; // first for delegation, others for rewards
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("balancecapital.ryze.storage.BinaryVault");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

contract BinaryVault is IDiamondCut, IDiamondLoupe, Ownable {
    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external {
        // get facet from function selector
        address facet = BinaryVaultStorage.layout().pluginSelector[msg.sig];
        require(facet != address(0));
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function facets() external view returns (Facet[] memory facets_) {
        BinaryVaultStorage.Layout storage l = BinaryVaultStorage.layout();
        uint256 length = l.pluginImpls.length;
        facets_ = new Facet[](length);
        for (uint256 i; i < length; i++) {
            address plugin = l.pluginImpls[i];
            (bytes4[] memory selectors, ) = IBinaryVaultPluginImpl(plugin)
                .pluginMetadata();
            facets_[i] = Facet(plugin, selectors);
        }
    }

    function facetFunctionSelectors(
        address _facet
    ) external view returns (bytes4[] memory facetFunctionSelectors_) {
        BinaryVaultStorage.Layout storage l = BinaryVaultStorage.layout();
        uint256 length = l.pluginImpls.length;
        for (uint256 i; i < length; i++) {
            if (l.pluginImpls[i] == _facet) {
                (facetFunctionSelectors_, ) = IBinaryVaultPluginImpl(_facet)
                    .pluginMetadata();
                break;
            }
        }
    }

    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_)
    {
        facetAddresses_ = BinaryVaultStorage.layout().pluginImpls;
    }

    function facetAddress(
        bytes4 _functionSelector
    ) external view returns (address facetAddress_) {
        facetAddress_ = BinaryVaultStorage.layout().pluginSelector[
            _functionSelector
        ];
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
    ) external onlyOwner {
        BinaryVaultStorage.Layout storage s = BinaryVaultStorage.layout();

        for (uint256 i = 0; i < _diamondCut.length; i++) {
            FacetCut memory cut = _diamondCut[i];
            address facet = cut.facetAddress;
            (, bytes4 interfaceId) = IBinaryVaultPluginImpl(facet).pluginMetadata();

            require(facet != address(0), "Diamond: Invalid facet address");

            if (cut.action == FacetCutAction.Add) {
                s.pluginImpls.push(facet);
                s.supportedInterfaces[interfaceId] = true; 
                
                for (uint256 j = 0; j < cut.functionSelectors.length; j++) {
                    bytes4 selector = cut.functionSelectors[j];

                    require(
                        s.pluginSelector[selector] == address(0),
                        "Diamond: Function selector already added"
                    );

                    s.pluginSelector[selector] = facet;
                }
            } else if (cut.action == FacetCutAction.Replace) {
                for (uint256 j = 0; j < cut.functionSelectors.length; j++) {
                    bytes4 selector = cut.functionSelectors[j];

                    s.pluginSelector[selector] = facet;
                }
            }
        }

        if (_init != address(0)) {
            (bool success, bytes memory result) = _init.delegatecall(_calldata);

            if (!success) {
                if (result.length == 0) revert('DelegateCallHelper: revert with no reason');
                assembly {
                    let result_len := mload(result)
                    revert(add(32, result), result_len)
                }
            }
        }

        emit DiamondCut(_diamondCut, _init, _calldata);
    }

    function supportsInterface(bytes4 interfaceID) external view returns (bool supported) {
        supported = BinaryVaultStorage.layout().supportedInterfaces[interfaceID];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

interface IBinaryVaultPluginImpl {
    function pluginMetadata() external pure returns (bytes4[] memory selectors, bytes4 interfaceId);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamond {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamond} from "./IDiamond.sol";

interface IDiamondCut is IDiamond {
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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
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