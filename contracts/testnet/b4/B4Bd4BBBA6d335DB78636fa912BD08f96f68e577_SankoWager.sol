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

// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract OwnableOracle is Ownable {
    address public oracle;

    modifier onlyOracle() {
        require(msg.sender == oracle, "Caller is not the oracle");
        _;
    }

    constructor(address _oracle) {
        oracle = _oracle;
    }

    function updateOracle(address _oracle) public onlyOwner {
        oracle = _oracle;
    }
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OwnableOracle} from "./OwnableOracle.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SankoWager is OwnableOracle, Pausable {
    struct SankoWagerGame {
        uint256 wagerAmount;
        address[] players;
    }

    mapping(uint256 gameId => SankoWagerGame game) public games;
    mapping(address player => uint256 gameId) public currentGame;

    uint256 public minimumDMT;
    uint256 public maximumDMT;

    uint256 private gameIdCounter;
    uint256 private feePercentage; // Measured in 1000ths. So 25 => 2.5%, 250 => 25%
    uint256 private maxPlayers;

    IERC20 private DMT;

    event GameStarted(uint256 indexed id, uint256 wagerAmount);
    event GameJoined(uint256 indexed id, address indexed player);
    event GameDecided(uint256 indexed id, address indexed winner, uint256 payout);

    modifier notInGame(address[] calldata _players) {
        for (uint256 i = 0; i < _players.length; i++) {
            require(isInGame(_players[i]) == false, "At least one player is already in a game");
        }
        _;
    }

    modifier validAddresses(address[] calldata _players) {
        for (uint256 i = 0; i < _players.length; i++) {
            require(_players[i] != address(0), "Player cannot be address(0)");
        }
        _;
    }

    constructor(uint256 _feePercentage, IERC20 _DMT, address _oracle, uint256 _maxPlayers) OwnableOracle(_oracle) {
        feePercentage = _feePercentage;
        DMT = _DMT;
        maxPlayers = _maxPlayers;
    }

    function createGame(uint256 _wagerAmount, address[] calldata _players)
        external
        whenNotPaused
        notInGame(_players)
        validAddresses(_players)
        onlyOracle
    {
        uint256 numPlayers = _players.length;
        require(numPlayers >= 2 && numPlayers <= maxPlayers, "Number of players is not within the allowed range");
        require(
            minimumDMT <= _wagerAmount && _wagerAmount <= maximumDMT, "Wager amount is not within the allowed range"
        );

        gameIdCounter++;

        games[gameIdCounter] = SankoWagerGame({players: _players, wagerAmount: _wagerAmount});

        emit GameStarted(gameIdCounter, _wagerAmount);
        for (uint256 i = 0; i < _players.length; i++) {
            address player = _players[i];
            payWager(_wagerAmount, player);
            currentGame[player] = gameIdCounter;
            emit GameJoined(gameIdCounter, player);
        }
    }

    function decideGame(uint256 _gameId, address _winner) external onlyOracle {
        SankoWagerGame memory game = games[_gameId];
        require(_gameId != 0 && game.players.length != 0, "Invalid game ID");
        require(
            gameContainsPlayer(_gameId, _winner) || _winner == address(0),
            "Winner must be one of the players or address(0)"
        );

        if (_winner == address(0)) {
            // draw
            refundPlayers(game);
            emit GameDecided(_gameId, _winner, 0);
        } else {
            // winner
            uint256 payout = game.wagerAmount * game.players.length;
            if (feePercentage > 0) {
                uint256 fee = (payout * feePercentage) / 1000;
                payout -= fee;
                require(DMT.transfer(address(owner()), fee), "Fee transfer failed");
            }

            require(DMT.transfer(_winner, payout), "Payout transfer failed");
            emit GameDecided(_gameId, _winner, payout);
        }
        releasePlayers(game);
        delete games[_gameId];
    }

    function updateFee(uint256 _feePercentage) external onlyOwner {
        feePercentage = _feePercentage;
    }

    function updateMaxMinDMT(uint256 _minimumDMT, uint256 _maximumDMT) external onlyOwner {
        minimumDMT = _minimumDMT;
        maximumDMT = _maximumDMT;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getGamePlayers(uint256 _gameId) external view returns (address[] memory) {
        return games[_gameId].players;
    }

    function isInGame(address _player) public view returns (bool) {
        return currentGame[_player] != 0;
    }

    function payWager(uint256 _wagerAmount, address _player) private {
        require(DMT.transferFrom(_player, address(this), _wagerAmount), "Token transfer failed");
    }

    function refundPlayers(SankoWagerGame memory game) private {
        for (uint256 i = 0; i < game.players.length; i++) {
            require(DMT.transfer(game.players[i], game.wagerAmount), "Token transfer failed");
        }
    }

    function releasePlayers(SankoWagerGame memory game) private {
        for (uint256 i = 0; i < game.players.length; i++) {
            currentGame[game.players[i]] = 0;
        }
    }

    function gameContainsPlayer(uint256 _gameId, address _player) private view returns (bool) {
        return currentGame[_player] == _gameId;
    }
}