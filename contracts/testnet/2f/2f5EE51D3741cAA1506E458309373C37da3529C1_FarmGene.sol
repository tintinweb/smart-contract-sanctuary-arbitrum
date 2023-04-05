// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Basic {
    address public immutable owner;
    mapping(address => bool) private isMod;
    bool public isPause = false;
    modifier onlyOwner() {
        require(msg.sender == owner, "Must be owner");
        _;
    }
    modifier onlyMod() {
        require(isMod[msg.sender] || msg.sender == owner, "Must be mod");
        _;
    }

    modifier notPause() {
        require(!isPause, "Must be not pause");
        _;
    }

    function addMod(address _mod) public onlyOwner {
        if (_mod != address(0x0)) {
            isMod[_mod] = true;
        }
    }

    function removeMod(address _mod) public onlyOwner {
        isMod[_mod] = false;
    }

    function changePause(uint256 _change) public onlyOwner {
        isPause = _change == 1;
    }

    constructor() {
        owner = msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./BasicAuth.sol";

contract FarmGene is Basic {
    struct Gene {
        uint256 types; //1:seed 2:tree
        uint256 quality; //1: normal 2: good 3: very good
        uint256 performance; // percent performance
        uint256 status; //1 available 2 in use 10 dead
    }
    mapping(uint256 => Gene) public plants;
    event PlantUpdate(
        uint256 id,
        uint256 types,
        uint256 quality,
        uint256 performance,
        uint256 status
    );

    function change(uint256 _id, uint256[4] memory _stats) public onlyMod {
        Gene storage plant = plants[_id];
        if (_stats[0] != 0) plant.types = _stats[0];
        if (_stats[1] != 0) plant.quality = _stats[1];
        if (_stats[2] != 0) {
            if (_stats[2] > 200) {
                plant.performance = _stats[2];
            } else {
                plant.performance = 200;
            }
        }
        if (_stats[3] != 0) plant.status = _stats[3];
        emit PlantUpdate(
            _id,
            plant.types,
            plant.quality,
            plant.performance,
            plant.status
        );
    }

    function getStatus(uint256 _id) public view returns (uint256) {
        return plants[_id].status;
    }
}