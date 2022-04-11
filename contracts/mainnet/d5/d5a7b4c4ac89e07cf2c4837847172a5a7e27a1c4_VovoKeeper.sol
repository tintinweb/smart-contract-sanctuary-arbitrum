/**
 *Submitted for verification at Arbiscan on 2022-04-11
*/

pragma solidity ^0.7.6;

interface IVovoVault {

    function earn() external;

    function poke() external;

}


contract VovoKeeper {

    address owner;
    address keeper;
    address[] public vaults;
    mapping (address => uint256) public arrayIndexes;

    function addVault(address _vault) public {
        uint id = vaults.length;
        arrayIndexes[_vault] = id;
        vaults.push(_vault);
    }

    function removeVault(address _vault) public {
        uint id = arrayIndexes[_vault];
        delete vaults[id];
    }

    constructor(address[] memory _vaults) {
        vaults = _vaults;
        owner = msg.sender;
    }

    function earn() external {
        require(msg.sender == owner || msg.sender == keeper, "!owner");
        for (uint256 i = 0; i < vaults.length; i++) {
            if (vaults[i] != address(0)) {
                IVovoVault(vaults[i]).earn();
            }
        }
    }

    function poke() external {
        require(msg.sender == owner || msg.sender == keeper, "!owner");
        for (uint256 i = 0; i < vaults.length; i++) {
            if (vaults[i] != address(0)) {
                IVovoVault(vaults[i]).poke();
            }
        }
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "!owner");
        owner = _owner;
    }

    function setKeeper(address _keeper) external {
        require(msg.sender == owner, "!owner");
        keeper = _keeper;
    }

}