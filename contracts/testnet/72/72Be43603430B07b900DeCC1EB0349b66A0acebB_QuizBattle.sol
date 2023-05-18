// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IGameController.sol";
import "./interfaces/IBattleSession.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract QuizBattle is Ownable
{
    using SafeMath for uint256;

    IGameController public GameControllerContract;
    IBattleSession public BattleSessionContract;
    IERC20 public TokenReward;

    uint256 public BattleTime;  // seconds
    uint256 public BattleEndTime;  // timestamp

    uint256 public TotalQuestionContract;
    uint256 public TotalQuestionOnBattle;
    uint256 public AmountTokenAnswerCorrect;

    mapping(uint256 => Question) public QuestionList;

    mapping(address => UserBattleData) public UserBattle;
    mapping(address => uint256) public BlockReturnDoQuestion;

    mapping(uint256 => address) public AddressToCheckTheAnswer;
    mapping(address => mapping(bytes32 => bool)) public CheckedSignature;

    /*example:
        0 => nomal
        1 => 15: x2 reward
        2 => 40: x1.5 reward
        3 => 120: x1.2 reward
        4 => 1440 (end): x1 reward
    */
    mapping(uint256 => CoefficientBonusData) public CoefficientBonus; 

    event OnStartQuizBattle(
        address user, 
        uint256 indexQuestion0, 
        uint256 indexQuestion1, 
        uint256 indexQuestion2);

    event OnSubmitQuestion(
        address user,
        uint256 totalCorrectAnswer,
        uint256 amountTokenReward
    );

    struct Question
    {
        string Question;
        string Answer0;
        string Answer1;
        string Answer2;
        string Answer3;
    }

    struct UserBattleData
    {
        mapping(uint256 => uint256) questionListForBattle;
        bool checkSubmit;
        uint256 timestampStart;
        uint256 timestampEnd;
    }

    struct CoefficientBonusData
    {
        uint256 effectiveTime;
        uint256 coefficient;
    }

    constructor() 
    {
        // config
        BattleTime = 1440;      // 1 hour
        TotalQuestionContract =  10;
        TotalQuestionOnBattle = 3;
        AmountTokenAnswerCorrect = 5461e18;

        CoefficientBonusData storage coefficientBonus0 = CoefficientBonus[1];
        coefficientBonus0.effectiveTime = 15;
        coefficientBonus0.coefficient = 2000;

        CoefficientBonusData storage coefficientBonus1 = CoefficientBonus[2];
        coefficientBonus1.effectiveTime = 40;
        coefficientBonus1.coefficient = 1500;

        CoefficientBonusData storage coefficientBonus2 = CoefficientBonus[3];
        coefficientBonus2.effectiveTime = 120;
        coefficientBonus2.coefficient = 1200;

        CoefficientBonusData storage coefficientBonus3 = CoefficientBonus[4];
        coefficientBonus3.effectiveTime = 1440;
        coefficientBonus3.coefficient = 1000;
    }

    modifier isHeroNFTJoinGame()
    {
        address user = _msgSender();
        require(GameControllerContract.HeroNFTJoinGameOfUser(user) != 0, "Error: Invaid HeroNFT join game");
        _;
    }

    function SetGameControllerContract(IGameController addressGameControllerContract) public onlyOwner 
    {
        GameControllerContract = addressGameControllerContract;
    }

    function SetBattleSessionContract(IBattleSession addressBattleSessionContract) public onlyOwner
    {
        BattleSessionContract = addressBattleSessionContract;
    }

    function SetTokenReward(IERC20 addressTokenReward) public onlyOwner
    {
        TokenReward = addressTokenReward;
    }

    function SetBattleTime(uint256 numberSeconds) public onlyOwner
    {
        BattleTime = numberSeconds;
    }

    function SetTotalQuestionContract(uint256 totalNumberOfQuestions) public onlyOwner
    {
        TotalQuestionContract = totalNumberOfQuestions;
    }
    
    function SetTotalQuestionOnBattle(uint256 totalNumberOfQuestions) public onlyOwner
    {
        TotalQuestionOnBattle = totalNumberOfQuestions;
    }

    function SetAddressToCheckTheAnswer(uint256 indexQuestion, address addressToCheckTheAnswer) public onlyOwner
    {
        AddressToCheckTheAnswer[indexQuestion] = addressToCheckTheAnswer;
    }

    /*
        0s => 15s ==> x2 reward: set indexTime = 1, effectiveTime = 15, coefficient = 2000 (2 * 1000);
        15s => 40s ==> x1.5 reward: set indexTime = 2, effectiveTime = 40, coefficient = 1500 (1.5 * 1000);
        ...
        120s => 1440 ==> x1 reward: set indexTime = 4, effectiveTime = 1440, coefficient = 1000 (1 * 1000);
    */
    function SetCoefficientBonus(uint256 indexTime, uint256 effectiveTime, uint256 coefficient) public onlyOwner 
    {
        CoefficientBonusData storage coefficientBonus = CoefficientBonus[indexTime];
        coefficientBonus.effectiveTime = effectiveTime;
        coefficientBonus.coefficient = coefficient;
    }

    function CreateQuestion(
        uint256 indexQuestion,
        string memory question, 
        string memory answer0, 
        string memory answer1, 
        string memory answer2, 
        string memory answer3) public onlyOwner
    {
        Question storage questionInfo = QuestionList[indexQuestion];

        questionInfo.Question = question;
        questionInfo.Answer0 = answer0;
        questionInfo.Answer1 = answer1;
        questionInfo.Answer2 = answer2;
        questionInfo.Answer3 = answer3;
    }

    function OpenBattle() public onlyOwner
    {
        BattleEndTime = block.timestamp.add(BattleTime);
    }   

    function StartQuizBattle() public isHeroNFTJoinGame
    {
        require(block.timestamp <= BattleEndTime, "Error StartQuizBattle: The battle is ending");

        address user = msg.sender;
        UserBattleData storage battleDataOfUser = UserBattle[user];

        require(block.timestamp > battleDataOfUser.timestampEnd, "Error StartQuizBattle: It's not time to ask question");

        battleDataOfUser.timestampStart = block.timestamp;
        battleDataOfUser.timestampEnd = BattleEndTime;
        battleDataOfUser.checkSubmit = false;

        uint256 from1 = 0;
        uint256 to1 = TotalQuestionContract.div(TotalQuestionOnBattle).sub(1);

        uint256 from2 = to1.add(1);
        uint256 to2 = from2.add(TotalQuestionContract.div(TotalQuestionOnBattle).sub(1));

        uint256 from3 = to2.add(1);
        uint256 to3 = TotalQuestionContract.sub(1);

        battleDataOfUser.questionListForBattle[0] = RandomNumber(0, user, from1, to1);
        battleDataOfUser.questionListForBattle[1] = RandomNumber(1, user, from2, to2);
        battleDataOfUser.questionListForBattle[2] = RandomNumber(2, user, from3, to3);

        BlockReturnDoQuestion[user] = block.number;

        emit OnStartQuizBattle(
            user, 
            battleDataOfUser.questionListForBattle[0], 
            battleDataOfUser.questionListForBattle[1], 
            battleDataOfUser.questionListForBattle[2]);
    }

    function SubmitQuestion(
        bytes32[] memory hashedMessages, 
        uint8[] memory v, 
        bytes32[] memory r, 
        bytes32[] memory s)
    public isHeroNFTJoinGame returns(uint256 totalCorrectAnswer, uint256 amountTokenReward)
    {
        address user = _msgSender();
        UserBattleData storage battleDataOfUser = UserBattle[user];

        require(block.number <= battleDataOfUser.timestampEnd, "Error SubmitQuestion: submission timeout");

        require(battleDataOfUser.checkSubmit == false, "Error SubmitQuestion: submited");
        battleDataOfUser.checkSubmit = true;

        totalCorrectAnswer = 0;

        for(uint256 index = 0; index < TotalQuestionOnBattle; index++)
        {
            if(CheckedSignature[user][hashedMessages[index]] == false &&
                VerifySignature(
                AddressToCheckTheAnswer[index], 
                hashedMessages[index], 
                v[index], 
                r[index], 
                s[index]) == true)
            {
                CheckedSignature[user][hashedMessages[index]] == true;
                totalCorrectAnswer = totalCorrectAnswer.add(1);
            } 
        }

        if(totalCorrectAnswer > 0)
        {
            // transfer reward
            uint256 CoefficientBonusReward = GetCoefficientBonusReward(block.timestamp.sub(battleDataOfUser.timestampStart));
            amountTokenReward = totalCorrectAnswer.mul(AmountTokenAnswerCorrect).mul(CoefficientBonusReward).div(1000);
            TokenReward.transfer(user, amountTokenReward);

            // save score to battle session
            BattleSessionContract.AddScoreUserBattleSession(user, amountTokenReward);
        }

        emit OnSubmitQuestion(user, totalCorrectAnswer, amountTokenReward);
    }

    function VerifySignature(
        address addressToCheckTheAnswer, 
        bytes32 _hashedMessage, 
        uint8 _v, 
        bytes32 _r, 
        bytes32 _s) 
    internal pure returns (bool) 
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);

        if (signer == addressToCheckTheAnswer) {
            return true;
        }
        return false;
    }

    function RandomNumber(uint256 count, address user, uint256 from, uint256 to) public view returns (uint256)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit)));
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, count, seed, user)));
        return randomHash % (to - from + 1) + from;
    }

    function GetCoefficientBonusReward(uint256 totalTimeComplete) public view returns (uint256)
    {
        uint256 index = 1;
        uint256 coefficient = 0;
        bool isOk = false;
        uint256 minTimeComplete = 0;
        uint256 maxTimeComplete = 0;

        while(!isOk) {
            CoefficientBonusData memory coefficientBonus = CoefficientBonus[index];
            minTimeComplete = maxTimeComplete;
            maxTimeComplete = coefficientBonus.effectiveTime;
            if(minTimeComplete <= totalTimeComplete && totalTimeComplete < maxTimeComplete) {
                isOk = true;
                coefficient = coefficientBonus.coefficient;
            } 
            index = index.add(1);
        }
        return coefficient;
    }

    function WithdrawTokenReward() public onlyOwner
    {
        address to = owner();
        TokenReward.transfer(to, TokenReward.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGameController
{
    function HeroNFTJoinGameOfUser(address user) external view returns(uint256);
    
    function RobotNFTJoinGameOfUser(address user) external pure returns (
        uint256 BlockJoin, // the block at which the NFT robot was added to the game
        uint256 RobotId // the ID of the NFT robot
    );


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBattleSession
{
    function AddScoreUserBattleSession(address user, uint256 score) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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