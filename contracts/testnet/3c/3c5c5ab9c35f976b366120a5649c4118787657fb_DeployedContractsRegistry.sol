// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract DeployedContractsRegistry {
    string public blockchain;
    address public owner;

    constructor(
        string memory _slug
    ) {
        blockchain  = _slug;
        owner = msg.sender;
    }

    modifier onlyDeployer() {
        require(
            msg.sender == owner,
            "onlyOwner"
        );
        _;
    }

    mapping(string => address) public deployedMapping;
    uint public increment;

    function setContract(string memory _slug, address _contract) public onlyDeployer {
        require(
            deployedMapping[_slug] == address(0x0),
            "Only one deployment attempt per deployedcontracts"
        );
        deployedMapping[_slug] = _contract;
        increment += 1;
    }

    function returnAddress(string memory _slug) public view returns(address) {
        address _address = deployedMapping[_slug];
        require(
            _address != address(0x0),
            "Contract not deployed"
        );
        return _address;
    }

    function returnIncrement() public view returns(uint) {
        return increment;
    }
}