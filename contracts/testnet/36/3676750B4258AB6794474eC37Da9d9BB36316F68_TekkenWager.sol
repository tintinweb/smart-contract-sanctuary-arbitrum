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

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Admin is Ownable {
    address public admin;

    function transferOwnership(address newOwner) public override onlyOwnerOrAdmin {
        _transferOwnership(newOwner);
    }

    function updateAdmin(address newAdmin) public onlyAdmin {
        admin = newAdmin;
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == admin, "Caller is not the owner or admin");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }
}

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Admin.sol";

contract TekkenWager is Admin {
    struct Game {
        address creator;
        address opponent;
        uint256 wagerAmount;
        uint256 startTime;
        bool hasStarted;
    }

    mapping(uint256 => Game) public games;
    mapping(address => bool) public isInGame;
    mapping(address => uint256) public currentGame;

    uint256 private gameIdCounter;
    uint256 private feePercentage;
    bool public isPaused;
    uint256 public minimumDMT;
    uint256 public maximumDMT;
    uint256 public cancelTime = 0;

    IERC20 private DMT;

    event GameCreated(uint256 indexed id, address indexed creator, uint256 wagerAmount);
    event GameJoined(uint256 indexed id, address indexed opponent);
    event GameDecided(uint256 indexed id, address indexed winner, uint256 payout);
    event GameCancelled(uint256 indexed id, address indexed creator, uint256 wagerAmount);

    constructor(uint256 _feePercentage, address _DMT) {
        feePercentage = _feePercentage;
        DMT = IERC20(_DMT);
    }

    function createPendingGame(address _opponent, uint256 _wagerAmount) external isPlayerInGame checkPaused {
        gameIdCounter++;
        require(
            _wagerAmount >= minimumDMT && _wagerAmount <= maximumDMT, "Wager amount is not within the allowed range"
        );

        payWager(_wagerAmount);

        Game storage newGame = games[gameIdCounter];
        newGame.startTime = 0;
        newGame.creator = msg.sender;
        newGame.opponent = _opponent;
        newGame.wagerAmount = _wagerAmount;

        isInGame[msg.sender] = true;
        currentGame[msg.sender] = gameIdCounter;

        emit GameCreated(gameIdCounter, msg.sender, _wagerAmount);
    }

    function joinPendingGame(uint256 _gameId) external isPlayerInGame checkPaused {
        Game storage game = games[_gameId];

        require(_gameId != 0 && game.creator != address(0), "Invalid game ID");
        require(game.opponent == address(0) || game.opponent == msg.sender, "You are not the specified opponent");
        require(game.creator != msg.sender, "You cannot join your own game");

        payWager(game.wagerAmount);

        game.opponent = msg.sender;
        game.startTime = block.timestamp;
        game.hasStarted = true;

        isInGame[msg.sender] = true;
        currentGame[msg.sender] = _gameId;

        emit GameJoined(_gameId, msg.sender);
    }

    function cancelGame() external {
        uint256 _gameId = currentGame[msg.sender];

        require(_gameId != 0, "You are not in a game");
        Game storage game = games[_gameId];
        if (game.hasStarted == false) {
            require(game.creator == msg.sender, "Only the creator can cancel the game");
            require(DMT.transfer(game.creator, game.wagerAmount), "Token transfer failed");
            isInGame[game.creator] = false;
            currentGame[game.creator] = 0;
        } else {
            require(
                block.timestamp > game.startTime + cancelTime, "Game must have been started for at least the cancelTime"
            );
            require(game.creator != address(0) && game.opponent != address(0), "Game is invalid");
            require(DMT.transfer(game.creator, game.wagerAmount), "Token transfer failed");
            require(DMT.transfer(game.opponent, game.wagerAmount), "Token transfer failed");
            isInGame[game.creator] = false;
            isInGame[game.opponent] = false;
            currentGame[game.creator] = 0;
            currentGame[game.opponent] = 0;
        }
        delete games[_gameId];

        emit GameCancelled(_gameId, msg.sender, game.wagerAmount);
    }

    function decideGame(uint256 _gameId, address _winner) external onlyOwner {
        Game storage game = games[_gameId];
        require(_gameId != 0 || game.creator != address(0) || game.opponent != address(0), "Invalid game ID");
        require(game.hasStarted == true, "Game must have started");
        require(
            _winner == game.creator || _winner == game.opponent || _winner == address(0),
            "Winner must be one of the players or address(0)"
        );

        isInGame[game.creator] = false;
        isInGame[game.opponent] = false;
        currentGame[game.creator] = 0;
        currentGame[game.opponent] = 0;

        if (_winner == address(0)) {
            // draw
            require(DMT.transfer(game.creator, game.wagerAmount), "Token transfer failed");
            require(DMT.transfer(game.opponent, game.wagerAmount), "Token transfer failed");
            delete games[_gameId];

            emit GameDecided(_gameId, _winner, 0);
        } else {
            // winner
            uint256 payout = game.wagerAmount * 2;
            if (feePercentage > 0) {
                uint256 fee = (payout * feePercentage) / 100;
                payout -= fee;
                require(DMT.transfer(address(owner()), fee), "Fee transfer failed");
            }

            require(DMT.transfer(_winner, payout), "Payout transfer failed");
            delete games[_gameId];

            emit GameDecided(_gameId, _winner, payout);
        }
    }

    function updateFee(uint256 _feePercentage) external onlyOwner {
        feePercentage = _feePercentage;
    }

    function pause() external onlyOwner {
        isPaused = !isPaused;
    }

    function updateMaxMinDMT(uint256 _minimumDMT, uint256 _maximumDMT) external onlyOwner {
        minimumDMT = _minimumDMT;
        maximumDMT = _maximumDMT;
    }

    function updateCancelTime(uint256 _cancelTime) external onlyOwner {
        cancelTime = _cancelTime;
    }

    function payWager(uint256 _wagerAmount) internal {
        require(DMT.transferFrom(msg.sender, address(this), _wagerAmount), "Token transfer failed");
    }

    modifier isPlayerInGame() {
        require(isInGame[msg.sender] == false, "You are in a game already");
        isInGame[msg.sender] = true;
        _;
    }

    modifier checkPaused() {
        require(isPaused == false, "Contract is paused");
        _;
    }
}