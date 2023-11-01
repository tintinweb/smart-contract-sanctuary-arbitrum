/**
 *Submitted for verification at Arbiscan.io on 2023-10-28
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;


contract ShittyRandom {

    uint[] choices;
    event ArrayOfIndices(uint[]);
    event ArrayOfSampledCellCoords(uint8[2][]);


    function requestRandomNumber(uint number) public view returns (uint) {
        bytes memory packedStr = abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            number
        );
        uint randomInt = uint(keccak256(packedStr));
        // console.log("randomHash: ");
        // console.logBytes32(randomHash);
        return randomInt;
    }

    function sampleRandomGridCellCoords(uint _number_of_cells) public returns (uint8[2][] memory) {
        // 9 indices for a 3x3 grid
        uint num_choices= 9;
        uint[] memory draws = _sampleIndicesWithoutReplacement(_number_of_cells, num_choices);
        uint8[2][9] memory gridCells = [
            [0,0],
            [0,1],
            [0,2],
            [1,0],
            [1,1],
            [1,2],
            [2,0],
            [2,1],
            [2,2]
        ];

        uint8[2][] memory sampledCells = new uint8[2][](_number_of_cells);

        for (uint i; i < draws.length; i++) {
            uint drawIndex = draws[i];
            uint8[2] memory cell= gridCells[drawIndex];
            // console.log("cell[0]", cell[0]);
            // console.log("cell[1]", cell[1]);
            sampledCells[i] = cell;
        }

        emit ArrayOfSampledCellCoords(sampledCells);
        return sampledCells;
    }

    function _sampleIndicesWithoutReplacement(
        uint number_of_draws,
        uint number_of_choices
    ) private returns (uint[] memory) {

        require(
            number_of_draws <= number_of_choices,
            "cannot sample more than number_of_choices"
        );

        uint[] memory draws = new uint[](number_of_draws);

        for (uint i = 0; i < number_of_choices; i++) {
            choices.push(i);
        }

        for (uint j = 0; j < number_of_draws; j++) {
            uint randInt = requestRandomNumber(j + block.timestamp) % choices.length;
            // choices array gets smaller each loop (sample with no replacement)
            uint randChoiceIndex = choices[randInt];
            draws[j] = randChoiceIndex;
            // remove that choice from choices array
            _remove_index_from_array(randInt, choices);
        }

        // reset choices
        delete choices;
        emit ArrayOfIndices(draws);

        return draws;
    }

    function _remove_index_from_array(uint _index, uint[] storage _arr) private {
        require(_index < _arr.length, "_index out of bound for _arr");
        // shift every element from [i] onwards 1 place earlier
        for (uint i = _index; i < _arr.length - 1; i++) {
            _arr[i] = _arr[i + 1];
        }
        // then pop the last element; only works with storage arrays
        _arr.pop();
    }

}