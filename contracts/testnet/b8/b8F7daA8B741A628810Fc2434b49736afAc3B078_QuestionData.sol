// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/test.sol";


contract QuestionData
{
    mapping(uint256 => QuestInfo) public ListQuestion;

    struct QuestInfo
    {
        uint256 IndexQuest;
        string Question;
        string Answer1;
        string Answer2;
        string Answer3;
        string Answer4;
    }
    function createQuestion(
        uint256 IndexQuest,
        string memory Question,
        string memory Answer1, string memory Answer2,
        string memory Answer3, string memory Answer4) public
    {
        require(IndexQuest >= 1, "Invalid index quest");
        require(!checkIndexQuestInListQuestion(IndexQuest), "Error c001");
        QuestInfo storage Quest = ListQuestion[IndexQuest];

        Quest.IndexQuest = IndexQuest;
        Quest.Question = Question;
        Quest.Answer1 = Answer1;
        Quest.Answer2 = Answer2;
        Quest.Answer3 = Answer3;
        Quest.Answer4 = Answer4;
    }

    function editQuestion(
        uint256 IndexQuest,
        string memory Question,
        string memory Answer1, string memory Answer2,
        string memory Answer3, string memory Answer4) public
    {
        require(checkIndexQuestInListQuestion(IndexQuest), "Error c002");
        QuestInfo storage Quest = ListQuestion[IndexQuest];

        Quest.Question = Question;
        Quest.Answer1 = Answer1;
        Quest.Answer2 = Answer2;
        Quest.Answer3 = Answer3;
        Quest.Answer4 = Answer4;
    }

    



    function checkIndexQuestInListQuestion(uint256 IndexQuest) public view returns(bool)
    {
        if(ListQuestion[IndexQuest].IndexQuest == IndexQuest) return true;
        return false; 
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface test
{

}