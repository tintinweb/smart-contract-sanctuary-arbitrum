// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test
{
    mapping(uint256 => uint256) public ArraysRandom;
    uint256 public TotalQuestionContract = 3;
    uint256 public TotalQuestionOnDay = 3;

    function SetTotalQuestionContract(uint256 newTotalQuestionContract) public 
    {
        TotalQuestionContract = newTotalQuestionContract;
    }

    function SetTotalQuestionOnDay(uint256 newTotalQuestionOnDay) public 
    {
        TotalQuestionOnDay = newTotalQuestionOnDay;
    }

    function Test001(address user) public view returns(uint256[] memory results)
    {
        uint256 count = 0;
        results = new uint256[](TotalQuestionOnDay);
        for(uint256 indexQuestion = 0; indexQuestion < TotalQuestionOnDay; indexQuestion++)
        {
            uint256 random = RandomNumber(count, user);
            results[indexQuestion] = random;
            count += 1;
        }
    }

    function RandomNumber(uint256 count, address user) public view returns(uint256)
    {
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, count, user)));
        return randomHash % (TotalQuestionContract + 1);
    }
}