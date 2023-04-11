// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IGameController.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./interfaces/IRobot.sol";

contract Learning is Ownable, IERC721Receiver, Pausable
{
    using SafeMath for uint256;
    IGameController public GameCotrollerContract;
    IRobot public Robot;          // NFT learn
    IERC20 public TokenReward;     // Reward

    // stores the LearnData of each user.
    mapping(address => LearnData) public DataUserLearn;

    //stores the block number of the pending level upgrade for each robot NFT.
    mapping(uint256 => uint256) public PendingBlockUpgradeLevelRobotNFT;

    // config

    //stores the price to upgrade each level of robot NFT.
    mapping(uint256 => uint256) public PriceUpgradeLevelRobotNFT; 

    // stores the number of blocks needed to upgrade each level of robot NFT.
    mapping(uint256 => uint256) public BlockUpgradeLevelRobotNFT; 

    //stores the reward for each block of learning based on the robot NFT level.
    mapping(uint256 => uint256) public RewardPerBlockOfLevel;

    // the maximum level of robot NFT that can join the game.
    uint256 public MaxLevelOfRobotNFTInGame;

    //the number of blocks a user has to wait before they can start learning again.
    uint256 public DelayBlockLearnNextTime;

    //the total number of blocks a user needs to learn to earn rewards.
    uint256 public TotalBlockLearnEachTime;

    // Event action
    event OnUpgradeLevelRobot(address user, uint256 tokenId, uint256 level);
    event OnStartLearn(address user, uint256 tokenId, uint256 level, uint256 startBlockLearn, uint256 pendingBlockLearn);
    event OnStopLearn(address user, uint256 tokenId, uint256 level, uint256 totalBlockLearnEachTime, uint256 stopBlockLearn);
    event OnBonusReward(address user, uint256 AmountTokenReward);

    struct LearnData
    {
        bool Learning; //a boolean that indicates whether the user is currently in a learning session             
        uint256 StartBlockLearn; //the block at which the user started the current learning session
        uint256 StopBlockLearn; //the block at which the user stopped the current learning session
        uint256 PendingBlockLearn; //the number of blocks remaining until the current learning session is complete
    }

    constructor(
        IRobot robot,
        IERC20 tokenReward)
    {
        Robot = robot;
        TokenReward = tokenReward;
        
        // Test
        TotalBlockLearnEachTime = 30;       
        DelayBlockLearnNextTime = 10;

        PriceUpgradeLevelRobotNFT[0] = 0;
        PriceUpgradeLevelRobotNFT[1] = 100e18;
        PriceUpgradeLevelRobotNFT[2] = 200e18;
        PriceUpgradeLevelRobotNFT[3] = 300e18;

        BlockUpgradeLevelRobotNFT[0] = 0;
        BlockUpgradeLevelRobotNFT[1] = 100;
        BlockUpgradeLevelRobotNFT[2] = 200;
        BlockUpgradeLevelRobotNFT[3] = 300;

        RewardPerBlockOfLevel[0] = 5e17;
        RewardPerBlockOfLevel[1] = 1e18;
        RewardPerBlockOfLevel[2] = 2e18;
        RewardPerBlockOfLevel[3] = 3e18;

        MaxLevelOfRobotNFTInGame = 3;
    }

    modifier isHeroNFTJoinGame()
    {
        address user = _msgSender();
        require(GameCotrollerContract.HeroNFTJoinGameOfUser(user) != 0, "Error: Invaid HeroNFT join game.");
        _;
    }

    modifier isNotUpgradeRobot()
    {
        address user = _msgSender();
        (,uint256 robotId) = GameCotrollerContract.RobotNFTJoinGameOfUser(user);
        require(block.number > PendingBlockUpgradeLevelRobotNFT[robotId], "Error: Robot upgraded.");
        _;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) 
    {
        return this.onERC721Received.selector;
    }

    // owner acction
    function PauseSystem() public onlyOwner 
    {
        _pause();
    }

    function UnpauseSystem() public onlyOwner
    {
        _unpause();
    }

    function SetGameCotrollerContract(IGameController gameCotrollerContract) public onlyOwner 
    {
        GameCotrollerContract = gameCotrollerContract;
    }

    function SetRobot(IRobot robot)public onlyOwner 
    {
        Robot = robot;
    }

    function SetTokenReward(IERC20 tokenReward) public onlyOwner
    {
        TokenReward = tokenReward;
    }

    function SetMaxLevelOfRobotNFTinGame(uint256 maxLevelOfRobotNFTinGame) public onlyOwner 
    {
        MaxLevelOfRobotNFTInGame = maxLevelOfRobotNFTinGame;
    }

    function SetTotalBlockLearnEachTime(uint256 totalBlockLearnEachTime) public onlyOwner
    {
        TotalBlockLearnEachTime = totalBlockLearnEachTime;
    }

    function SetRewardPerBlockOfLevel(uint256 level, uint256 value) public onlyOwner 
    {
        require(level <= MaxLevelOfRobotNFTInGame, "Invalid max level");
        RewardPerBlockOfLevel[level] = value;
    }

    function SetPriceUpgradeLevelRobotNFT(uint256 level, uint256 price) public onlyOwner
    {
        require(level <= MaxLevelOfRobotNFTInGame,  "Error SetPriceUpgradeLevelRobotNFT: Invalid level");
        PriceUpgradeLevelRobotNFT[level] = price;
    }

    function SetBlockUpgradeLevelRobotNFT(uint256 level, uint256 quantityBlock) public onlyOwner
    {
        require(level <= MaxLevelOfRobotNFTInGame,  "Error SetBlockUpgradeLevelRobotNFT: Invalid level");
        BlockUpgradeLevelRobotNFT[level] = quantityBlock;
    }

    //user action
    function UpgradeLevelRobot() public whenNotPaused isHeroNFTJoinGame isNotUpgradeRobot
    {
        address user = msg.sender;
        (,uint256 tokenId) = GameCotrollerContract.RobotNFTJoinGameOfUser(user);
        require(tokenId != 0, "Error UpgradeLevelRobot: Invalid tokenId");

        uint256 level = Robot.Level(tokenId);
        require(level < MaxLevelOfRobotNFTInGame, "Error UpgradeLevelRobot: Invalid level");
        require(TokenReward.balanceOf(user) >= PriceUpgradeLevelRobotNFT[level.add(1)], "Error UpgradeLevelRobot: Invalid balance");
        LearnData memory data = DataUserLearn[user];
        require(data.Learning == false, "Error UpgradeLevelRobot: Learning");
        TokenReward.transferFrom(user, address(this), PriceUpgradeLevelRobotNFT[level.add(1)]);

        PendingBlockUpgradeLevelRobotNFT[tokenId] = block.number.add(BlockUpgradeLevelRobotNFT[level.add(1)]);
        Robot.UpgradeLevel(tokenId);
        emit OnUpgradeLevelRobot(user, tokenId, level);
    }

    function ForRobotNFTToLearn() public whenNotPaused isHeroNFTJoinGame isNotUpgradeRobot
    {
        address user = msg.sender;
        (,uint256 tokenId) = GameCotrollerContract.RobotNFTJoinGameOfUser(user);
        require(tokenId != 0, "Error StartLearning: Invalid tokenId");
        require(Robot.Level(tokenId) > 0, "Error: Robot Level is 0");

        LearnData storage data = DataUserLearn[user]; 
        require(data.StartBlockLearn < block.number, "Error StartLearning: Time out");
        require(data.Learning == false, "Error StartLearning: Learning");

        if(data.PendingBlockLearn == 0)
        {
            data.PendingBlockLearn = TotalBlockLearnEachTime;
        }

        data.StartBlockLearn = block.number;
        data.Learning = true;

        emit OnStartLearn(user, tokenId, Robot.Level(tokenId), data.StartBlockLearn, data.PendingBlockLearn);
    }

    function ForRobotNFTStopLearn() public whenNotPaused isHeroNFTJoinGame isNotUpgradeRobot
    {
        address user = msg.sender;

        LearnData storage data = DataUserLearn[user]; 
        require(data.Learning == true, "Error StopLearning: Not learning");

        uint256 totalBlockLearnedOfUser = block.number.sub(data.StartBlockLearn);
        if(totalBlockLearnedOfUser >= data.PendingBlockLearn)
        {
            totalBlockLearnedOfUser = data.PendingBlockLearn;

            data.StartBlockLearn = block.number.add(DelayBlockLearnNextTime);
            data.PendingBlockLearn = 0;
        }
        else
        {
            data.PendingBlockLearn = data.PendingBlockLearn.sub(totalBlockLearnedOfUser);
        }
        data.Learning = false;
        data.StopBlockLearn = block.number;

        DoBonusToken(user, totalBlockLearnedOfUser);
    }

    function GetData(address user) public view returns(
        uint256 cyberCreditBalance,
        uint256 tokenId,
        uint256 levelRobotJoinGameOfUser,
        uint256 blockNumber,
        bool learning,
        uint256 startBlockLearn,
        uint256 stopBlockLearn,
        uint256 pendingBlockLearn,
        uint256 rewardPerDay,
        uint256 pendingBlockUpgradeLevelRobotNFT
    )
    {
        cyberCreditBalance = TokenReward.balanceOf(user);
        (,tokenId) = GameCotrollerContract.RobotNFTJoinGameOfUser(user);
        
        levelRobotJoinGameOfUser = Robot.Level(tokenId);
        blockNumber = block.number;

        LearnData memory data = DataUserLearn[user];
        learning = data.Learning;
        startBlockLearn = data.StartBlockLearn;
        pendingBlockLearn = data.PendingBlockLearn;
        stopBlockLearn = data.StopBlockLearn;

        if(pendingBlockLearn != 0) 
        {
            uint256 totalBlockLearned = TotalBlockLearnEachTime.sub(pendingBlockLearn);
            uint256 totalBlockLearnEachTimeing = blockNumber.sub(startBlockLearn);

            rewardPerDay = (startBlockLearn < stopBlockLearn) ?
                totalBlockLearned.mul(RewardPerBlockOfLevel[levelRobotJoinGameOfUser]) :
                    ((totalBlockLearned.add(totalBlockLearnEachTimeing))
                        .mul(RewardPerBlockOfLevel[levelRobotJoinGameOfUser]) <
                        TotalBlockLearnEachTime.mul(RewardPerBlockOfLevel[levelRobotJoinGameOfUser])) ? 
                            (totalBlockLearned.add(totalBlockLearnEachTimeing))
                            .mul(RewardPerBlockOfLevel[levelRobotJoinGameOfUser]) :
                                TotalBlockLearnEachTime.mul(RewardPerBlockOfLevel[levelRobotJoinGameOfUser]);
        }

        pendingBlockUpgradeLevelRobotNFT  = PendingBlockUpgradeLevelRobotNFT[tokenId];
        
    }

    function GetConfigSystem() public view returns(
        uint256 maxLevelOfRobotNFTinGame,
        uint256[] memory priceUpgradeLevelRobotNFTLevel,
        uint256 totalBlockLearnEachTime,
        uint256[] memory rewardPerBlockOfLevel,
        uint256[] memory blockUpgradeLevelRobotNFT
    )
    {
        maxLevelOfRobotNFTinGame = MaxLevelOfRobotNFTInGame;

        priceUpgradeLevelRobotNFTLevel = new uint256[](maxLevelOfRobotNFTinGame.add(1));
        for(uint level = 1; level <= maxLevelOfRobotNFTinGame; level++)
        {
            priceUpgradeLevelRobotNFTLevel[level] = PriceUpgradeLevelRobotNFT[level]; 
        }

        totalBlockLearnEachTime = TotalBlockLearnEachTime;

        rewardPerBlockOfLevel = new uint256[](maxLevelOfRobotNFTinGame.add(1));
        for(uint level = 0; level <= maxLevelOfRobotNFTinGame; level++)
        {
            rewardPerBlockOfLevel[level] = RewardPerBlockOfLevel[level];
        }

        blockUpgradeLevelRobotNFT = new uint256[](maxLevelOfRobotNFTinGame.add(1));
        for(uint level = 0; level <= maxLevelOfRobotNFTinGame; level++)
        {
            blockUpgradeLevelRobotNFT[level] = BlockUpgradeLevelRobotNFT[level];
        }
    }

    function DoBonusToken(address user, uint256 totalBlockLearned) private
    {
        (,uint256 tokenId) = GameCotrollerContract.RobotNFTJoinGameOfUser(user);
        uint256 level = Robot.Level(tokenId);
        uint256 rewardPerBlock = RewardPerBlockOfLevel[level];
        if(TokenReward.balanceOf(address(this)) >= totalBlockLearned.mul(rewardPerBlock))
        {
            TokenReward.transfer(user, totalBlockLearned.mul(rewardPerBlock));

            emit OnBonusReward(user, totalBlockLearned.mul(rewardPerBlock));
        }
        else
        {
            TokenReward.transfer(user, TokenReward.balanceOf(address(this)));

            emit OnBonusReward(user, TokenReward.balanceOf(address(this)));
        }
    }  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IRobot is IERC721
{

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function Level(uint256 tokenId) external view returns (uint256);

    function Mint(address to) external returns (uint256);

    function Burn(uint256 tokenId) external;

    function tokenURI(uint256 tokenId) external view returns(string memory);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns(uint256);

    function UpgradeLevel(uint256 tokenId) external;

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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