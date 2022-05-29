pragma solidity ^0.8.0;

contract Randomizer {

    function getRandoms(string memory _seed, uint256 _size) external view returns (uint256[] memory) {

        uint256[] memory rands = new uint256[](_size); 
        uint256 div = 100;
        uint256 randomKeccak = uint256(keccak256(abi.encodePacked(_seed, block.difficulty, block.timestamp, block.number)));
       
        for(uint i=0;i<_size;i++){
            uint256 rand = randomKeccak % div;
            randomKeccak /= div;
            rands[i]=rand;
        }

        return rands;
    }
}