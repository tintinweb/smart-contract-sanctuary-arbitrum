// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract QuestionData is Ownable
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
        string memory answer2, string memory answer3,
        uint256 answerResult) public onlyOwner
    {
        // require(IndexQuest >= 1, "Invalid index quest");
        // require(!checkIndexQuestInListQuestion(IndexQuest), "Error c001");
        QuestInfo storage Quest = ListQuestionsContract[indexQuest];

        Quest.Question = question;
        Quest.Answer0 = answer0;
        Quest.Answer1 = answer1;
        Quest.Answer2 = answer2;
        Quest.Answer3 = answer3;
        Quest.AnswerResult = answerResult;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}