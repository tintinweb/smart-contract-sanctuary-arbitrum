// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IQuestionData.sol";

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Quest
{
    // using SafeMath for uint256;
    IQuestionData public QuestionDataContract;
    mapping(address => mapping(uint256 => uint256)) public ListQuestionsUser;

    uint256 public TotalQuestionContract = 100;
    uint256 public TotalQuestionOnDay = 3;

    struct Question
    {
        string Question;
        string Answer0;
        string Answer1;
        string Answer2;
        string Answer3;
    }

    constructor(IQuestionData questionDataContract) 
    {
        QuestionDataContract = questionDataContract;
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

            (data[indexQuestion].Question,
            data[indexQuestion].Answer0,
            data[indexQuestion].Answer1,
            data[indexQuestion].Answer2,
            data[indexQuestion].Answer3, ) = QuestionDataContract.ListQuestionsContract(questionNumber);
        }
    }

    function SubmidQuestions(address user, uint256[] calldata results) public
    {
        uint256 totalNumberCorrect = 0;
        for(uint256 indexQuestion = 0; indexQuestion < TotalQuestionOnDay; indexQuestion++)
        {
            uint256 questionNumber = ListQuestionsUser[user][indexQuestion];
            (,,,,,uint256 resultAnswerQuestionInContract) = QuestionDataContract.ListQuestionsContract(questionNumber);
            uint256 resultAnswerQuestionOfUser = results[indexQuestion];

            if(resultAnswerQuestionOfUser == resultAnswerQuestionInContract)
            {
                totalNumberCorrect = totalNumberCorrect + (1);
            }
        }

        if(totalNumberCorrect > 0) BonusToken(user, totalNumberCorrect);
    }

    function BonusToken(address user, uint256 totalBonus) public returns (uint256) 
    {
        // do something
        return totalBonus;
    }  

    function RandomNumber(uint256 count) public view returns(uint256)
    {
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, count)));
        return randomHash % (TotalQuestionContract + 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuestionData
{
    function ListQuestionsContract(uint256 indexQuest) external pure returns(
        string memory question,
        string memory answer0,
        string memory answer1,
        string memory answer2,
        string memory answer3,
        uint256 answerResult
    );
}