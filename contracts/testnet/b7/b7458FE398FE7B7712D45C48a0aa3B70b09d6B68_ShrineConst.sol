// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ShrineConst {
    uint private get1TotalSupply;
    uint private pancakeSupply;
    uint256 public nonce;
    constructor()  {
       get1TotalSupply = 510;
       pancakeSupply = 18;
       nonce=1;
    }

    function random(uint8 from, uint256 to) private returns (uint8) {
        uint256 randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % to;
        randomnumber = from + randomnumber;
        nonce++;
        return uint8(randomnumber);
    }


    function revealNumber(uint8 from, uint256 to) external returns(uint256){
        uint num =  random(from,to);
        return num;
    }

    function revealSuccessNumber() external returns(uint256){
        uint num =  random(1,1000);
        return num;
    }

    function revealGen1NftId() external returns(uint256){
        uint num = random(1,get1TotalSupply);
        return num;
    }

    function revealPancakeIdNftId() external returns(uint256){
        uint num = random(1,pancakeSupply);
        return num;
    }
}