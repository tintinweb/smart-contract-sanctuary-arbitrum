// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract QuestionData
{
    // using SafeMath for uint256;
    mapping(uint256 => QuestInfo) public ListQuestionsContract;
    // mapping(address => mapping(uint256 => uint256)) public ListQuestionsUser;

    // uint256 public TotalQuestionContract = 100;
    // uint256 public TotalQuestionOnDay = 3;

    struct QuestInfo
    {
        string Question;
        string Answer0;
        string Answer1;
        string Answer2;
        string Answer3;
        uint256 AnswerResult;
    }

    // struct Question
    // {
    //     string Question;
    //     string Answer0;
    //     string Answer1;
    //     string Answer2;
    //     string Answer3;
    // }

    // only admin
    function CreateQuestion(
        uint256 indexQuest,
        string memory question,
        string memory answer0, string memory answer1,
        string memory answer2, string memory answer3) public
    {
        // require(IndexQuest >= 1, "Invalid index quest");
        // require(!checkIndexQuestInListQuestion(IndexQuest), "Error c001");
        QuestInfo storage Quest = ListQuestionsContract[indexQuest];

        Quest.Question = question;
        Quest.Answer0 = answer0;
        Quest.Answer1 = answer1;
        Quest.Answer2 = answer2;
        Quest.Answer3 = answer3;
    }

    // function ToDoQuestOnDay(address user) public
    // {
        
    //     // for(uint256 indexQuestion = 0; indexQuestion < TotalQuestionOnDay; indexQuestion++)
    //     // {
    //     //     ListQuestionsUser[user][indexQuestion] = RandomNumber(indexQuestion);
    //     // }

    //     // test
    //     ListQuestionsUser[user][0] = 1;
    //     ListQuestionsUser[user][1] = 2;
    //     ListQuestionsUser[user][2] = 3;
    // }

    // function GetQuestion(address user) public view returns(Question[] memory data)
    // {
    //     data = new Question[](TotalQuestionOnDay);
    //     for(uint256 indexQuestion = 0; indexQuestion < TotalQuestionOnDay; indexQuestion++)
    //     {
    //         uint256 questionNumber = ListQuestionsUser[user][indexQuestion];
    //         data[indexQuestion].Question = ListQuestionsContract[questionNumber].Question;
    //         data[indexQuestion].Answer0 = ListQuestionsContract[questionNumber].Answer0;
    //         data[indexQuestion].Answer1 = ListQuestionsContract[questionNumber].Answer1;
    //         data[indexQuestion].Answer2 = ListQuestionsContract[questionNumber].Answer2;
    //         data[indexQuestion].Answer3 = ListQuestionsContract[questionNumber].Answer3;
    //     }
    // }

    // function SubmidQuestions(address user, uint256[] calldata results) public
    // {
    //     uint256 totalNumberCorrect = 0;
    //     for(uint256 indexQuestion = 0; indexQuestion < TotalQuestionOnDay; indexQuestion++)
    //     {
    //         uint256 questionNumber = ListQuestionsUser[user][indexQuestion];
    //         uint256 resultAnswerQuestionInContract = ListQuestionsContract[questionNumber].AnswerResult;
    //         uint256 resultAnswerQuestionOfUser = results[indexQuestion];

    //         if(resultAnswerQuestionOfUser == resultAnswerQuestionInContract)
    //         {
    //             totalNumberCorrect = totalNumberCorrect.add(1);
    //         }
    //     }

    //     if(totalNumberCorrect > 0) BonusToken(user, totalNumberCorrect);
    // }

    // function BonusToken(address user, uint256 totalBonus) public returns (uint256) 
    // {
    //     // do something
    //     return totalBonus;
    // }   

    // function RandomNumber(uint256 count) public view returns(uint256)
    // {
    //     uint256 randomHash = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, count)));
    //     return randomHash % (TotalQuestionContract + 1);
    // }
}