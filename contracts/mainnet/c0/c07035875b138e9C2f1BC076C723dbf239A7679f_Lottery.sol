// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IArbSys {
    function arbBlockNumber() external view returns (uint256);

    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interface/IArbSys.sol";

contract Lottery is Ownable {
    using Counters for Counters.Counter;

    IERC20 public FARB = IERC20(0x8907855758bDEE82782599F86B04052C71137D79);
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public devAddress = 0xA09B62ddD79d3bc2E4787d6116571C3d0A232641;

    Counters.Counter private nonceCounter; // 随机数 counter
    Counters.Counter public gameIDCounter; // 游戏ID counter

    uint256 public Lv1GameParticipants = 6; // 初级场参与人数
    uint256 public Lv2GameParticipants = 6; // 中级场参与人数
    uint256 public Lv3GameParticipants = 6; // 高级场参与人数

    uint256 public onePiece = 1_000_000 * 1e18; // 每份金额

    uint256 public Lv1GamePiece = 1; // 初级场投注份数
    uint256 public Lv2GamePiece = 3; // 中级场投注份数
    uint256 public Lv3GamePiece = 10; // 高级场投注份数

    uint256 public winnerRate = 9000; // 中奖占比
    uint256 public burnRate = 700;
    uint256 public devRate = 300;

    bool public paused = false;

    uint256 private seed;

    struct GameStruct {
        uint256 levelID; // 等级id
        uint256 gameID; // 游戏id
        uint256 unitAmount; // 每份金额
        uint256 gamerCount; // 参与人数
        address[] participants; // 参与用户
        address winner; // 中奖者
        uint256 startTime; // 开始时间
        uint256 endTime; // 结束时间
    }

    mapping(uint256 => GameStruct) public _games;

    uint256 public constant Lv1ID = 1;
    uint256 public constant Lv2ID = 2;
    uint256 public constant Lv3ID = 3;

    mapping(uint256 => GameStruct) public currentGames;
    mapping(address => bool)  public _blacklist;

    event gameStart(
        uint256 indexed levelID,
        uint256 indexed gameID,
        uint256 indexed unitAmount,
        uint256 participantNeed
    );
    event gameEnd(
        uint256 indexed levelID,
        uint256 indexed gameID,
        address indexed winner,
        uint256 winnerAmount,
        uint256 gameUsedTime
    );
    event gameJoin(
        uint256 indexed levelID,
        uint256 indexed gameID,
        address indexed participant,
        uint256 participantCount,
        uint256 participantNeed,
        uint256 participantAmount
    );

    constructor (){
        seed = uint256(keccak256(abi.encodePacked(block.timestamp)));
    }

    function setWinnerRate(uint256 rate) external onlyOwner {
        require(rate >= 9000, "invalid rate");
        winnerRate = rate;
    }

    function setGamePiece(uint256 Lv1, uint256 Lv2, uint256 Lv3) external onlyOwner {
        Lv1GamePiece = Lv1;
        Lv2GamePiece = Lv2;
        Lv3GamePiece = Lv3;
    }

    function setGameParticipants(uint256 Lv1, uint256 Lv2, uint256 Lv3) external onlyOwner {
        Lv1GameParticipants = Lv1;
        Lv2GameParticipants = Lv2;
        Lv3GameParticipants = Lv3;
    }

    function createLv1Game() internal {
        if (currentGames[Lv1ID].gameID > 0) {
            return;
        }
        _createNewGame(Lv1ID, Lv1GameParticipants, Lv1GamePiece);
    }

    function createLv2Game() internal {
        if (currentGames[Lv2ID].gameID > 0) {
            return;
        }
        _createNewGame(Lv2ID, Lv2GameParticipants, Lv2GamePiece);
    }

    function createLv3Game() internal {
        if (currentGames[Lv3ID].gameID > 0) {
            return;
        }
        _createNewGame(Lv3ID, Lv3GameParticipants, Lv3GamePiece);
    }

    function checkGame() public {
        createLv1Game();
        createLv2Game();
        createLv3Game();
    }

    function _createNewGame(uint256 LvID, uint256 gamerCount, uint256 pieceCount) internal {
        if (paused) {
            return;
        }
        gameIDCounter.increment();
        GameStruct memory gameStruct = GameStruct({
            levelID: LvID,
            gameID: gameIDCounter.current(),
            unitAmount: pieceCount * onePiece,
            gamerCount: gamerCount,
            participants: new address[](0),
            winner: address(0),
            startTime: block.timestamp,
            endTime: 0
        });
        _games[gameStruct.gameID] = gameStruct;
        currentGames[LvID] = gameStruct;
        emit gameStart(
            LvID,
            gameStruct.gameID,
            gameStruct.unitAmount,
            gameStruct.gamerCount
        );
    }

    function joinGame(uint256 gameID) external {
        require(msg.sender == tx.origin, "only EOA");
        require(gameID <= gameIDCounter.current(), "invalid gameID");
        require(!_blacklist[msg.sender], "blacklist");
        GameStruct storage game = _games[gameID];
        require(game.gameID > 0, "game not exist");
        require(game.winner == address(0), "game is over");
        require(game.endTime == 0, "game is over");
        require(game.participants.length < game.gamerCount, "game is full");
        game.participants.push(msg.sender);
        currentGames[game.levelID] = game;
        require(FARB.transferFrom(msg.sender, address(this), game.unitAmount), "transferFrom failed");
        emit gameJoin(
            game.levelID,
            game.gameID,
            msg.sender,
            game.participants.length,
            game.gamerCount,
            game.unitAmount
        );
        if (game.participants.length == game.gamerCount) {
            delete currentGames[game.levelID];
            execGame(game);
        }
    }

    function execGame(GameStruct storage game) internal {
        require(game.participants.length == game.gamerCount, "game is not full");
        uint256 winnerIndex = calculateHashNumber() % game.gamerCount;
        game.winner = game.participants[winnerIndex];
        game.endTime = block.timestamp;
        uint256 prizePool = game.unitAmount * game.gamerCount;
        uint256 winnerAmount = prizePool * winnerRate / 10000;
        uint256 devAmount = prizePool * devRate / 10000;
        uint256 burnAmount = prizePool - winnerAmount - devAmount;

        require(FARB.transfer(game.winner, winnerAmount));
        require(FARB.transfer(devAddress, devAmount));
        require(FARB.transfer(deadAddress, burnAmount));
        emit gameEnd(
            game.levelID,
            game.gameID,
            game.winner,
            winnerAmount,
            game.endTime - game.startTime
        );

        checkGame();
    }

    function calculateHashNumber() internal returns (uint256) {
        nonceCounter.increment();
        bytes32 lastHash = IArbSys(address(100)).arbBlockHash(IArbSys(address(100)).arbBlockNumber() - 1);
        return uint256(keccak256(abi.encodePacked(
            msg.sender,
            nonceCounter.current(),
            seed,
            block.timestamp,
            lastHash
        )));
    }

    function withdrawToken(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        require(token.transfer(msg.sender, token.balanceOf(address(this))));
    }

    function withdrawETH() external onlyOwner {
        (bool s,) = msg.sender.call{value: address(this).balance}("");
        require(s, "transfer failed");
    }

    function flipPaused() external onlyOwner {
        paused = !paused;
    }

    function flipBlacklist(address _address) external onlyOwner {
        _blacklist[_address] = !_blacklist[_address];
    }

    function setOneGamePiece(uint256 _oneGamePiece) external onlyOwner {
        onePiece = _oneGamePiece;
    }

    function setSeed(uint256 _seed) external onlyOwner {
        seed = _seed;
    }

    function getGameCount() external view returns (uint256) {
        return gameIDCounter.current();
    }

    function getGameByID(uint256 gameID) external view returns (GameStruct memory) {
        return _games[gameID];
    }

    function getGameByLevel(uint256 LvID) external view returns (GameStruct memory) {
        return currentGames[LvID];
    }

    function getCurrentGames() external view returns (GameStruct[] memory) {
        GameStruct[] memory _currentGames = new GameStruct[](3);
        _currentGames[0] = currentGames[Lv1ID];
        _currentGames[1] = currentGames[Lv2ID];
        _currentGames[2] = currentGames[Lv3ID];
        return _currentGames;
    }
}