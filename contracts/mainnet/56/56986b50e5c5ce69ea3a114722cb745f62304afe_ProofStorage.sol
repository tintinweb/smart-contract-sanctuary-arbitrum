/**
 *Submitted for verification at Arbiscan on 2022-12-11
*/

pragma solidity ^0.5.0;

contract ProofStorage {
    
    struct  data
    {
        address creator;
        address client;
        string hash;
    }

    mapping (address => data) result;  

    function setDataForClient(address client, string memory hash) public {
        address owner = msg.sender;

        data storage d = result[client];
        d.creator = owner;
        d.client = client;
        d.hash = hash;
    }

    function getDataOfClient(address client) public view returns (string memory hash) {
        return result[client].hash;
    }
}