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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IHouse.sol";
import "../interfaces/IERC20BackwardsCompatible.sol";
import "../interfaces/IConsole.sol";
import "../interfaces/IUSDTVault.sol";

contract House is IHouse, Ownable {
    error InvalidGame(uint256 _game, address _impl, bool _live);
    error AlreadyInitialized();
    error NotInitialized();
    error InsufficientVault(uint256 _betSize, uint256 _vaultSize);
    error MaxBetExceeded(uint256 _betSize, uint256 _maxBet);
    error InsufficientUSDBalance(uint256 _betSize, uint256 _balance);
    error InsufficientUSDAllowance(uint256 _betSize, uint256 _allowance);
    error BetCompleted(uint256 betId);

    address public usdtVault;

    uint256 public globalWagers; // Tracks total dollars wagered
    uint256 public globalBets; // Tracks total number of bets

    mapping (uint256 => Types.HouseGame) games; // statistics of games
    mapping (address => Types.Player2) players; // statistics of players

    uint256 public betFee = 100; // 1%

    IERC20BackwardsCompatible public usdtToken;
    IConsole public consoleInst;

    mapping(uint256 => Types.Bet) bets; // An array of every bet

    bool private initialized;

    constructor (address _vault, address _usdt, address _console) {
        usdtVault = _vault;
        usdtToken = IERC20BackwardsCompatible(_usdt);
        consoleInst = IConsole(_console);
    }

    function initialize() external onlyOwner {
        if (initialized) {
            revert AlreadyInitialized();
        }

        initialized = true;
    }

    function calculateBetFee(uint256 _stake) public view returns (uint256) {
        uint256 _feeAmount = _stake * betFee / 10000;
        return _feeAmount;
    }

    function openWager(address _account, uint256 _gameId, uint256 _rolls, uint256 _bet, uint256[50] calldata _data, uint256 _stake, uint256 _maxPayout) external returns (uint256, uint256) {
        if(!initialized) {
            revert NotInitialized();
        }

        {
            Types.Game memory _game = consoleInst.getGame(_gameId);
            if (msg.sender != _game.impl || address(0) == _game.impl || !_game.live) {
                revert InvalidGame(_gameId, _game.impl, _game.live);
            }
        }

        uint256 _betSize = _stake * _rolls;
        uint256 _betSizeWithFee = (_stake + calculateBetFee(_stake)) * _rolls;
        if(_betSizeWithFee > usdtToken.balanceOf(usdtVault)) {
            revert InsufficientVault(_betSize, usdtToken.balanceOf(usdtVault));
        }

        // 2.5% of vault
        {
            uint256 betLimit = (usdtToken.balanceOf(usdtVault) * 25 / 1000);
            uint256 maxBetPrize = 0;
            if (_maxPayout >= PAYOUT_AMPLIFIER) {
                maxBetPrize = _betSize * (_maxPayout - PAYOUT_AMPLIFIER) / PAYOUT_AMPLIFIER;
            }

            if(maxBetPrize > betLimit) {
                revert MaxBetExceeded(maxBetPrize, betLimit);
            }
        }

        {
            uint256 userBalance = usdtToken.balanceOf(_account);
            if(_betSizeWithFee > userBalance) {
                revert InsufficientUSDBalance(_betSizeWithFee, userBalance);
            }
        }

        {
            uint256 userAllowance = usdtToken.allowance(_account, address(this));
            if(_betSizeWithFee > userAllowance) {
                revert InsufficientUSDAllowance(_betSizeWithFee, userAllowance);
            }
        }

        // take bet
        usdtToken.transferFrom(_account, usdtVault, _betSizeWithFee);

        bets[globalBets] = Types.Bet(globalBets, players[_account].info.betCount, _gameId, _rolls, _bet, _stake, 0, false, block.timestamp, 0, _data, _account);

        globalBets += 1;
        globalWagers += _betSize;

        players[_account].info.betCount ++;
        players[_account].info.betIds.push(globalBets);
        players[_account].info.wagers += _betSize;
        games[_gameId].betCount += 1;
        games[_gameId].betIds.push(globalBets);

        return (globalBets - 1, _betSizeWithFee);
    }

    function closeWager(uint256 betId, address _account, uint256 _gameId, uint256 _payout) external returns (bool) {
        // validate game
        Types.Game memory _game = consoleInst.getGame(_gameId);
        if (msg.sender != _game.impl || address(0) == _game.impl) {
            revert InvalidGame(_gameId, _game.impl, _game.live);
        }

        // validate bet
        Types.Bet memory _bet = bets[betId];
        if(_bet.complete) {
            revert BetCompleted(betId);
        }

        // close bet
        _bet.payout = _payout;
        _bet.complete = true;
        _bet.closed = block.timestamp;
        bets[betId] = _bet;

        // pay out winnings & receive losses
        players[_account].games[_gameId].betCount += 1;
        players[_account].games[_gameId].wagers += _bet.stake * _bet.rolls;

        if(_payout > _bet.stake) {
            uint256 _profit = _payout - _bet.stake;

            players[_account].info.profits += _profit;
            players[_account].games[_gameId].profits += _profit;
            players[_account].info.wins += 1;
            players[_account].games[_gameId].wins += 1;
        } else {
            players[_account].info.losses ++;
            players[_account].games[_gameId].losses ++;
        }

        return _payout > _bet.stake;
    }

    function getBetsByGame(uint256 _game, uint256 _from, uint256 _to) external view returns (Types.Bet[] memory) {
        uint256 betCount = games[_game].betCount;

        if (_to >= betCount) _to = betCount;
        if (_from > _to) _from = 0;

        Types.Bet[] memory _Bets;
        uint256 _counter;
        
        for (uint256 _i = _from; _i < _to; _i++) {
            _Bets[_counter] = bets[games[_game].betIds[_i]];
            _counter++;
        }
        return _Bets;
    }
    
    function getBets(uint256 _from, uint256 _to) external view returns (Types.Bet[] memory) {
        if (_to >= globalBets) _to = globalBets;
        if (_from > _to) _from = 0;

        Types.Bet[] memory _Bets;
        uint256 _counter;

        for (uint256 _i = _from; _i < _to; _i++) {
            _Bets[_counter] = bets[_i];
            _counter++;
        }

        return _Bets;
    }

    function getBet(uint256 _betId) external view returns (Types.Bet memory) {
        return bets[_betId];
    }

    function getPlayer(address _user) external view returns (Types.Player memory) {
        return players[_user].info;
    }

    function getPlayerGame(address _user, uint256 _gameId) external view returns (Types.PlayerGame memory) {
        return players[_user].games[_gameId];
    }

    function getGame(uint256 _gameId) external view returns (Types.HouseGame memory) {
        return games[_gameId];
    }

    function setUSDTToken(address _newUSDT) external onlyOwner {
        require(address(usdtToken) != _newUSDT, "Already Set");
        usdtToken = IERC20BackwardsCompatible(_newUSDT);
    }

    function setUSDTVault(address _newVaule) external onlyOwner {
        require(usdtVault != _newVaule, "Already Set");
        usdtVault = _newVaule;
    }

    function setConsoleInst(address _newConsole) external onlyOwner {
        require(address(consoleInst) != _newConsole, "Already Set");
        consoleInst = IConsole(_newConsole);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Types.sol";

interface IConsole {
    function getGame(uint256 _id) external view returns (Types.Game memory);
    function getGameByImpl(address _impl) external view returns (Types.Game memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20BackwardsCompatible {
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
    function transfer(address to, uint256 amount) external;

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
    function approve(address spender, uint256 amount) external;

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
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Types.sol";

interface IHouse {
    function openWager(address _account, uint256 _game, uint256 _rolls, uint256 _bet, uint256[50] calldata _data, uint256 _betSize, uint256 _maxPayout) external returns (uint256, uint256);
    function closeWager(uint256 betId, address _account, uint256 _gameId, uint256 _payout) external returns (bool);
    function getBet(uint256 _id) external view returns (Types.Bet memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUSDTVault {
    function finalizeGame(address _player, uint256 _prize, uint256 _fee) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint256 constant RESOLUTION = 10000;
uint256 constant PAYOUT_AMPLIFIER = 10 ** 24;

library Types {
    struct Bet {
        uint256 globalBetId;
        uint256 playerBetId;
        uint256 gameId;
        uint256 rolls;
        uint256 betNum;
        uint256 stake;
        uint256 payout;
        bool complete;
        uint256 opened;
        uint256 closed;
        uint256[50] data;
        address player;
    }

    struct Game {
        uint256 id;
        bool live;
        uint256 edge;
        uint256 date;
        address impl;
        string name;
    }

    struct HouseGame {
        uint256 betCount;
        uint256[] betIds;
    }

    struct PlayerGame {
        uint256 betCount;
        uint256 wagers;
        uint256 profits;
        uint256 wins;
        uint256 losses;
    }

    struct Player {
        uint256 betCount;
        uint256[] betIds;

        uint256 wagers;
        uint256 profits;

        uint256 wins;
        uint256 losses;
    }

    struct Player2 {
        Player info;
        mapping (uint256 => PlayerGame) games;
    }
}

/*
pragma solidity ^0.8.0;

uint256 constant RESOLUTION = 10000;
uint256 constant PAYOUT_AMPLIFIER = 10 ** 24;

type BETCOUNT is uint32;
type GAMECOUNT is uint16;
type DATAVALUE is uint128;
type ROLLCOUNT is uint16;
type BETNUM is uint32;
type TOKENAMOUNT is uint128;
type TIMESTAMP is uint32;
type EDGEAMOUNT is uint16;

library Types {

    function add(BETCOUNT a, uint256 b) internal pure returns (BETCOUNT) {
        return BETCOUNT.wrap(uint32(uint256(BETCOUNT.unwrap(a)) + b));
    }

    function toUint256(BETCOUNT a) internal pure returns (uint256) {
        return uint256(BETCOUNT.unwrap(a));
    }

    function add(GAMECOUNT a, uint256 b) internal pure returns (GAMECOUNT) {
        return GAMECOUNT.wrap(uint16(uint256(GAMECOUNT.unwrap(a)) + b));
    }

    struct Bet {
        BETCOUNT globalBetId;
        BETCOUNT playerBetId;
        GAMECOUNT gameId;
        ROLLCOUNT rolls;
        BETNUM betNum;
        TOKENAMOUNT stake;
        TOKENAMOUNT payout;
        bool complete;
        TIMESTAMP opened;
        TIMESTAMP closed;
        DATAVALUE[50] data;
        address player;
    }

    struct Game {
        GAMECOUNT id;
        bool live;
        EDGEAMOUNT edge;
        TIMESTAMP date;
        address impl;
        string name;
    }

    struct HouseGame {
        BETCOUNT betCount;
        BETCOUNT[] betIds;
    }

    struct PlayerGame {
        BETCOUNT betCount;
        TOKENAMOUNT wagers;
        TOKENAMOUNT profits;
        BETCOUNT wins;
        BETCOUNT losses;
    }

    struct Player {
        BETCOUNT betCount;
        BETCOUNT[] betIds;

        TOKENAMOUNT wagers;
        TOKENAMOUNT profits;

        BETCOUNT wins;
        BETCOUNT losses;

        mapping (GAMECOUNT => PlayerGame) games;
    }
}
*/