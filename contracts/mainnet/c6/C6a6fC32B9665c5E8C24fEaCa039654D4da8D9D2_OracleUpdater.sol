pragma solidity ^0.8.7;

interface IOracle {
    function update() external;
}

contract OracleUpdater {
    address public owner;
    address public updater;
    address[] public oracles;

    constructor() {
        owner = msg.sender;
    }

    function update() external {
        require(msg.sender == owner || msg.sender == updater);
        for (uint256 i = 0; i < oracles.length; i ++) {
            IOracle(oracles[i]).update();
        }
    }

    function setUpdater(address _address) external {
        require(msg.sender == owner);
        updater = _address;
    }

    function addOracle(address _address) external {
        require(msg.sender == owner);
        oracles.push(_address);
    }
}