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

import "../interfaces/IPActionStorageV4.sol";
import "./RouterStorage.sol";

contract ActionStorageV4 is RouterStorage, IPActionStorageV4 {
    modifier onlyOwner() {
        require(msg.sender == owner(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _getCoreStorage().owner;
    }

    function pendingOwner() public view returns (address) {
        return _getCoreStorage().pendingOwner;
    }

    function setSelectorToFacets(SelectorsToFacet[] calldata arr) external onlyOwner {
        CoreStorage storage $ = _getCoreStorage();

        for (uint256 i = 0; i < arr.length; i++) {
            SelectorsToFacet memory s = arr[i];
            for (uint256 j = 0; j < s.selectors.length; j++) {
                $.selectorToFacet[s.selectors[j]] = s.facet;
                emit SelectorToFacetSet(s.selectors[j], s.facet);
            }
        }
    }

    function selectorToFacet(bytes4 selector) external view returns (address) {
        CoreStorage storage $ = _getCoreStorage();
        return $.selectorToFacet[selector];
    }

    // Ownable
    function transferOwnership(address newOwner, bool direct, bool renounce) external onlyOwner {
        CoreStorage storage $ = _getCoreStorage();

        if (direct) {
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            emit OwnershipTransferred($.owner, newOwner);
            $.owner = newOwner;
            $.pendingOwner = address(0);
        } else {
            $.pendingOwner = newOwner;
        }
    }

    function claimOwnership() external {
        CoreStorage storage $ = _getCoreStorage();

        address _pendingOwner = $.pendingOwner;

        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        emit OwnershipTransferred($.owner, _pendingOwner);
        $.owner = _pendingOwner;
        $.pendingOwner = address(0);
    }
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