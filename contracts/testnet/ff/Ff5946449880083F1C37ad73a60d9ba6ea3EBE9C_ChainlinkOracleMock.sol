pragma solidity 0.8.19;


contract ChainlinkOracleMock
{
    uint256 public latestAnswer;

    uint8 public decimals;

    constructor(uint8 _decimals, uint256 _answer)
    {
        decimals = _decimals;
        latestAnswer = _answer;
    }
}