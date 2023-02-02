// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/test.sol";


contract QuestionData
{
    mapping(uint256 => QuestInfo) public ListQuestionsContract;
    mapping(address => QuestionsUser) public ListQuestionsUSer;

    uint256 public TotalQuestionOnDay;

    struct QuestInfo
    {
        // uint256 IndexQuest;
        string Question;
        string Answer1;
        string Answer2;
        string Answer3;
        string Answer4;
        uint256 AnswerResult;
    }

    struct QuestionsUser
    {
        uint256 Question1;
        uint256 Question2;
        uint256 Question3;
    }

    // only admin
    function CreateQuestion(
        uint256 IndexQuest,
        string memory Question,
        string memory Answer1, string memory Answer2,
        string memory Answer3, string memory Answer4) public
    {
        // require(IndexQuest >= 1, "Invalid index quest");
        // require(!checkIndexQuestInListQuestion(IndexQuest), "Error c001");
        QuestInfo storage Quest = ListQuestionsContract[IndexQuest];

        Quest.Question = Question;
        Quest.Answer1 = Answer1;
        Quest.Answer2 = Answer2;
        Quest.Answer3 = Answer3;
        Quest.Answer4 = Answer4;
    }

    function ToDoQuestOnDay(address user) public
    {

    }

    function GetQuestion(address user) public view returns(QuestInfo[] memory data)
    {

    }

    function RandomNumber() public view returns(uint256)
    {
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return randomHash % TotalQuestionOnDay;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface test
{

}