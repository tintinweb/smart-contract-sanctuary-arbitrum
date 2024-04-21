/**
 *Submitted for verification at Arbiscan.io on 2024-04-21
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

interface OsmLike {
    function src() external view returns (address);
}

contract OsmRegistry {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth() {
        require(wards[msg.sender] == 1, "OsmRegistry/not-authorized");
        _;
    }

    // map of gem to osm
    mapping(address => address) public osms;

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Add(address indexed gem, address indexed osm);
    event Remove(address indexed gem, address indexed osm);
    event Update(address indexed gem, address indexed oldOsm, address indexed newOsm);

    // Initialize the osm registry
    constructor() {
        wards[msg.sender] = 1;
    }

    function add(address gem, address osm) external auth {
        require(gem != address(0), "OsmRegistry/gem-cannot-be-zero");
        require(osm != address(0), "OsmRegistry/osm-cannot-be-zero");

        osms[gem] = osm;

        emit Add(gem, osm);
    }

    function get(address gem) external view returns (address, address) {
        address osmAddress = osms[gem];
        OsmLike osm = OsmLike(osmAddress);
        return (osmAddress, osm.src());
    }

    function remove(address gem) external auth {
        address osm = osms[gem];
        delete osms[gem];

        emit Remove(gem, osm);
    }

    function update(address gem, address newOsm) external auth {
        address oldOsm = osms[gem];
        osms[gem] = newOsm;

        emit Update(gem, oldOsm, newOsm);
    }
}