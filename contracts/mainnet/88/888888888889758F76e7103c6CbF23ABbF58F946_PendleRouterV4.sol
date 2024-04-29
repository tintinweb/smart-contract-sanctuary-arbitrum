// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IPActionStorageV4 {
    struct SelectorsToFacet {
        address facet;
        bytes4[] selectors;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event SelectorToFacetSet(bytes4 indexed selector, address indexed facet);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function transferOwnership(address newOwner, bool direct, bool renounce) external;

    function claimOwnership() external;

    function setSelectorToFacets(SelectorsToFacet[] calldata arr) external;

    function selectorToFacet(bytes4 selector) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "../interfaces/IPActionStorageV4.sol";
import "./RouterStorage.sol";

contract PendleRouterV4 is Proxy, RouterStorage {
    constructor(address _owner, address actionStorage) {
        RouterStorage.CoreStorage storage $ = _getCoreStorage();
        $.owner = _owner;
        $.selectorToFacet[IPActionStorageV4.setSelectorToFacets.selector] = actionStorage;
    }

    function _implementation() internal view override returns (address) {
        RouterStorage.CoreStorage storage $ = _getCoreStorage();
        address facet = $.selectorToFacet[msg.sig];
        require(facet != address(0), "INVALID_SELECTOR");
        return facet;
    }

    receive() external payable override {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

abstract contract RouterStorage {
    struct CoreStorage {
        address owner;
        address pendingOwner;
        mapping(bytes4 => address) selectorToFacet;
    }

    // keccak256(abi.encode(uint256(keccak256("pendle.routerv4.Core")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CORE_STORAGE_LOCATION = 0xf168c5b0cb4aca9a68f931815c18a144c61ad01d6dd7ca15bd6741672a0ab800;

    function _getCoreStorage() internal pure returns (CoreStorage storage $) {
        assembly {
            $.slot := CORE_STORAGE_LOCATION
        }
    }
}