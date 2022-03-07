/**
 *Submitted for verification at Arbiscan on 2022-03-07
*/

pragma solidity ^0.4.24;

contract test {
    struct Version {
        uint16[3] semanticVersion;
        address contractAddress;
        bytes contentURI;
    }

    mapping (uint256 => Version) versions;

    constructor() public {
        versions[0] = Version([3333,2222,1111], 0xF5Dc67E54FC96F993CD06073f71ca732C1E654B1, abi.encodePacked(372477427428917867612379712741278472148791));
    }

    function getLatest() public view returns (uint16[3] semanticVersion, address contractAddress, bytes contentURI) {
        Version storage version = versions[0];
        return (version.semanticVersion, version.contractAddress, version.contentURI);
    }

}