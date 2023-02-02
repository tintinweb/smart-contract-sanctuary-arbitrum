// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/test.sol";


contract QuestionData
{
    mapping(uint256 => QuestInfo) public ListQuestionsContract;
    mapping(address => mapping(uint256 => uint256)) public ListQuestionsUser;

    uint256 public TotalQuestionContract = 100;
    uint256 public TotalQuestionOnDay = 3;

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

    struct Question
    {
        string Question;
        string Answer1;
        string Answer2;
        string Answer3;
        string Answer4;
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
        
        // for(uint256 indexQuestion = 0; indexQuestion < TotalQuestionOnDay; indexQuestion++)
        // {
        //     ListQuestionsUser[user][indexQuestion] = RandomNumber(indexQuestion);
        // }
        
        // test
        ListQuestionsUser[user][0] = 1;
        ListQuestionsUser[user][1] = 2;
        ListQuestionsUser[user][2] = 3;
    }

    function GetQuestion(address user) public view returns(Question[] memory data)
    {
        data = new Question[](TotalQuestionOnDay);
        for(uint256 indexQuestion = 0; indexQuestion < TotalQuestionOnDay; indexQuestion++)
        {
            uint256 questionNumber = ListQuestionsUser[user][indexQuestion];
            data[indexQuestion].Question = ListQuestionsContract[questionNumber].Question;
            data[indexQuestion].Answer1 = ListQuestionsContract[questionNumber].Answer1;
            data[indexQuestion].Answer2 = ListQuestionsContract[questionNumber].Answer2;
            data[indexQuestion].Answer3 = ListQuestionsContract[questionNumber].Answer3;
            data[indexQuestion].Answer4 = ListQuestionsContract[questionNumber].Answer4;
        }
    }

    function RandomNumber(uint256 count) public view returns(uint256)
    {
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, count)));
        return randomHash % (TotalQuestionContract + 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface test
{

}