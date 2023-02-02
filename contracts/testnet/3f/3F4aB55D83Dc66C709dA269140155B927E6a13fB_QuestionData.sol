// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/test.sol";


contract QuestionData
{
    using SafeMath for uint256;
    mapping(uint256 => QuestInfo) public ListQuestionsContract;
    mapping(address => mapping(uint256 => uint256)) public ListQuestionsUser;

    uint256 public TotalQuestionContract = 100;
    uint256 public TotalQuestionOnDay = 3;

    struct QuestInfo
    {
        string Question;
        string Answer0;
        string Answer1;
        string Answer2;
        string Answer3;
        uint256 AnswerResult;
    }

    struct Question
    {
        string Question;
        string Answer0;
        string Answer1;
        string Answer2;
        string Answer3;
    }

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
            data[indexQuestion].Answer0 = ListQuestionsContract[questionNumber].Answer0;
            data[indexQuestion].Answer1 = ListQuestionsContract[questionNumber].Answer1;
            data[indexQuestion].Answer2 = ListQuestionsContract[questionNumber].Answer2;
            data[indexQuestion].Answer3 = ListQuestionsContract[questionNumber].Answer3;
        }
    }

    function SubmidQuestions(address user, uint256[] calldata results) public
    {
        uint256 totalNumberCorrect = 0;
        for(uint256 indexQuestion = 0; indexQuestion < TotalQuestionOnDay; indexQuestion++)
        {
            uint256 questionNumber = ListQuestionsUser[user][indexQuestion];
            uint256 resultAnswerQuestionInContract = ListQuestionsContract[questionNumber].AnswerResult;
            uint256 resultAnswerQuestionOfUser = results[indexQuestion];

            if(resultAnswerQuestionOfUser == resultAnswerQuestionInContract)
            {
                totalNumberCorrect = totalNumberCorrect.add(1);
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

interface test
{

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}