pragma solidity ^0.5.16;

contract InitHashMaster {     
    constructor() public {}    

    function getInitCodeHash(bytes calldata _creationCode) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_creationCode));
    }
}