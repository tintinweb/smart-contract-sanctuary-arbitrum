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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "../interfaces/IHouse.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IERC20BackwardsCompatible.sol";
import "../interfaces/IConsole.sol";
import "../interfaces/ITLP.sol";
import "../libraries/Types.sol";
import "../interfaces/IFeeTracker.sol";
import "../interfaces/IVolumeRewards.sol";

contract House is IHouse, Ownable, ReentrancyGuard {
    error InvalidGame(uint256 _game, address _impl, bool _live);
    error InsufficientTLPLiquidity(uint256 _betSize, uint256 _liquidity);
    error MaxBetExceeded(uint256 _betSize, uint256 _maxBet);
    error InsufficientUSDBalance(uint256 _betSize, uint256 _balance);
    error InsufficientUSDAllowance(uint256 _betSize, uint256 _allowance);
    error BetCompleted(bytes32 _requestId);
    error InvalidPayout(uint256 _stake, uint256 _payout);
    error AlreadyInitialized();
    error NotInitialized();
    error InvalidBetFee(uint256 _betFee);

    mapping(address => uint256[]) betsByPlayer; // An array of every bet ID by player
    mapping(uint256 => uint256[]) betsByGame; // An array of every bet ID by game
    mapping(bytes32 => uint256) requests; // Tracks indexes in bets array by request ID
    mapping(address => uint256) playerBets; // Tracks number of bets made by each player
    mapping(address => uint256) playerWagers; // Tracks dollars wagered by each player
    mapping(address => uint256) playerProfits; // Tracks dollars won by each player
    mapping(address => uint256) playerWins; // Tracks wins by each player
    mapping(address => uint256) playerLosses; // Tracks losses by each player
    mapping(address => mapping(uint256 => uint256)) playerWagersPerEpoch; // Tracks dollars wagered by each player each epoch
    mapping(address => mapping(uint256 => uint256)) playerGameBets; // Tracks number of bets by each player in each game
    mapping(address => mapping(uint256 => uint256)) playerGameWagers; // Tracks dollars wagered by each player in each game
    mapping(address => mapping(uint256 => uint256)) playerGameProfits; // Tracks dollars won by each player in each game
    mapping(address => mapping(uint256 => uint256)) playerGameWins; // Tracks wins by each player in each game
    mapping(address => mapping(uint256 => uint256)) playerGameLosses; // Tracks losses by each player in each game
    mapping(uint256 => uint256) gameBets; // Tracks number of bets made in each game
    mapping(uint256 => uint256) globalWagersEpoch; // Tracks dollars wagered per epoch
    uint256 public globalBets; // Tracks total number of bets
    uint256 public globalWagers; // Tracks total dollars wagered
    uint256 public betFee = 100;

    IERC20BackwardsCompatible public immutable usdt;
    IConsole public immutable console;
    ITLP public immutable TLP;
    IFeeTracker public immutable sTKUFees;
    IFeeTracker public immutable xTKUFees;
    IVolumeRewards public immutable volumeRewards;

    Types.Bet[] public bets; // An array of every bet

    bool private initialized;

    constructor(
        address _USDT,
        address _console,
        address _TLP,
        address _sTKUFees,
        address _xTKUFees,
        address _volumeRewards
    ) {
        usdt = IERC20BackwardsCompatible(_USDT);
        console = IConsole(_console);
        TLP = ITLP(_TLP);
        sTKUFees = IFeeTracker(_sTKUFees);
        xTKUFees = IFeeTracker(_xTKUFees);
        volumeRewards = IVolumeRewards(_volumeRewards);
    }

    function initialize() external onlyOwner {
        if (initialized) {
            revert AlreadyInitialized();
        }
        usdt.approve(address(TLP), type(uint256).max);
        usdt.approve(address(sTKUFees), type(uint256).max);
        usdt.approve(address(xTKUFees), type(uint256).max);

        initialized = true;
    }

    function openWager(
        address _account,
        uint256 _game,
        uint256 _rolls,
        uint256 _bet,
        uint256[50] calldata _data,
        bytes32 _requestId,
        uint256 _betSize,
        uint256 _maxPayout
    ) external nonReentrant {
        if (!initialized) {
            revert NotInitialized();
        }

        // validate game
        Types.Game memory _Game = console.getGame(_game);
        if (
            msg.sender != _Game.impl || address(0) == _Game.impl || !_Game.live
        ) {
            revert InvalidGame(_game, _Game.impl, _Game.live);
        }

        // calculate bet fee
        uint256 _betSizeWithFee = _betSize + ((_betSize * betFee) / 10000);

        // validate bet size
        if (_betSize > usdt.balanceOf(address(TLP))) {
            revert InsufficientTLPLiquidity(
                _betSize,
                usdt.balanceOf(address(TLP))
            );
        }
        if (
            _betSize >
            (((usdt.balanceOf(address(TLP)) * _Game.edge) / 10000) *
                (10 ** 18)) /
                _maxPayout
        ) {
            revert MaxBetExceeded(
                _betSize,
                (((usdt.balanceOf(address(TLP)) * _Game.edge) / 10000) *
                    (10 ** 18)) / _maxPayout
            );
        }
        if (_betSizeWithFee > usdt.balanceOf(_account)) {
            revert InsufficientUSDBalance(
                _betSizeWithFee,
                usdt.balanceOf(_account)
            );
        }
        if (_betSizeWithFee > usdt.allowance(_account, address(this))) {
            revert InsufficientUSDAllowance(
                _betSizeWithFee,
                usdt.allowance(_account, address(this))
            );
        }

        // take bet, distribute fee
        usdt.transferFrom(_account, address(this), _betSizeWithFee);
        _payYield(_betSizeWithFee - _betSize);
        bets.push(
            Types.Bet(
                globalBets,
                playerBets[_account],
                _requestId,
                _game,
                _account,
                _rolls,
                _bet,
                _data,
                _betSize,
                0,
                false,
                block.timestamp,
                0
            )
        );

        // stack too deep
        requests[_requestId] = globalBets;
        betsByPlayer[_account].push(globalBets);
        betsByGame[_game].push(globalBets);

        // update bet stats
        globalBets++;
        playerBets[_account]++;
        gameBets[_game]++;

        // update wager stats
        globalWagers += _betSize;
        playerWagers[_account] += _betSize;

        // update wager stats for rewards epoch
        uint256 epoch = volumeRewards.currentEpoch();
        playerWagersPerEpoch[_account][epoch] += _betSize;
        globalWagersEpoch[epoch] += _betSize;
    }

    function closeWager(
        address _account,
        uint256 _game,
        bytes32 _requestId,
        uint256 _payout
    ) external nonReentrant {
        // validate game
        Types.Game memory _Game = console.getGame(_game);
        if (msg.sender != _Game.impl || address(0) == _Game.impl) {
            revert InvalidGame(_game, _Game.impl, _Game.live);
        }

        // validate bet
        Types.Bet storage _Bet = bets[requests[_requestId]];
        if (_Bet.complete) {
            revert BetCompleted(_requestId);
        }

        // close bet
        _Bet.payout = _payout;
        _Bet.complete = true;
        _Bet.closed = block.timestamp;
        bets[requests[_requestId]] = _Bet;

        // pay out winnnings & receive losses
        playerGameBets[_account][_game]++;
        playerGameWagers[_account][_game] += _Bet.stake;
        if (_payout > _Bet.stake) {
            usdt.transfer(_account, _Bet.stake);
            uint256 _profit = _payout - _Bet.stake;
            TLP.payWin(_account, _game, _requestId, _profit);
            playerProfits[_account] += _profit;
            playerGameProfits[_account][_game] += _profit;
            playerWins[_account]++;
            playerGameWins[_account][_game]++;
        } else {
            usdt.transfer(_account, _payout);
            TLP.receiveLoss(_account, _game, _requestId, _Bet.stake - _payout);
            playerProfits[_account] += _payout;
            playerGameProfits[_account][_game] += _payout;
            playerLosses[_account]++;
            playerGameLosses[_account][_game]++;
        }
    }

    function _payYield(uint256 _fee) private {
        uint256 _fee80Pct = (_fee * 8000) / 10000;
        xTKUFees.depositYield(2, _fee80Pct);
        sTKUFees.depositYield(2, _fee - _fee80Pct);
    }

    function setBetFee(uint256 _betFee) external nonReentrant onlyOwner {
        betFee = _betFee;
    }

    function getBetFee() external view returns (uint256) {
        return betFee;
    }

    function getBetsByPlayer(
        address _account,
        uint256 _from,
        uint256 _to
    ) external view returns (Types.Bet[] memory) {
        if (_to >= playerBets[_account]) _to = playerBets[_account];
        if (_from > _to) _from = 0;
        Types.Bet[] memory _Bets;
        uint256 _counter;
        for (uint256 _i = _from; _i < _to; _i++) {
            _Bets[_counter] = bets[betsByPlayer[_account][_i]];
            _counter++;
        }
        return _Bets;
    }

    function getBetsByGame(
        uint256 _game,
        uint256 _from,
        uint256 _to
    ) external view returns (Types.Bet[] memory) {
        if (_to >= gameBets[_game]) _to = gameBets[_game];
        if (_from > _to) _from = 0;
        Types.Bet[] memory _Bets;
        uint256 _counter;
        for (uint256 _i = _from; _i < _to; _i++) {
            _Bets[_counter] = bets[betsByGame[_game][_i]];
            _counter++;
        }
        return _Bets;
    }

    function getBets(
        uint256 _from,
        uint256 _to
    ) external view returns (Types.Bet[] memory) {
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

    function getBetByRequestId(
        bytes32 _requestId
    ) external view returns (Types.Bet memory) {
        return bets[requests[_requestId]];
    }

    function getBet(uint256 _id) external view returns (Types.Bet memory) {
        return bets[_id];
    }

    function getPlayerStats(
        address _account
    ) external view returns (uint256, uint256, uint256, uint256, uint256) {
        return (
            playerBets[_account],
            playerWagers[_account],
            playerProfits[_account],
            playerWins[_account],
            playerLosses[_account]
        );
    }

    function getGameBets(uint256 _game) external view returns (uint256) {
        return gameBets[_game];
    }

    function getGlobalBets() external view returns (uint256) {
        return globalBets;
    }

    function getGlobalWagers() external view returns (uint256) {
        return globalWagers;
    }

    function getPlayerVolumeForEpoch(
        address account,
        uint256 epoch
    ) external view returns (uint256) {
        return playerWagersPerEpoch[account][epoch];
    }

    function getGlobalVolumeForEpoch(
        uint256 epoch
    ) external view returns (uint256) {
        return globalWagersEpoch[epoch];
    }

    function getPlayerGameStats(
        address _account,
        uint256 _game
    ) external view returns (uint256, uint256, uint256, uint256, uint256) {
        return (
            playerGameBets[_account][_game],
            playerGameWagers[_account][_game],
            playerGameProfits[_account][_game],
            playerGameWins[_account][_game],
            playerGameLosses[_account][_game]
        );
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "../libraries/Types.sol";

interface IConsole {
    function getGasPerRoll() external view returns (uint256);

    function getMinBetSize() external view returns (uint256);

    function getGame(uint256 _id) external view returns (Types.Game memory);

    function getGameByImpl(address _impl)
        external
        view
        returns (Types.Game memory);
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

interface IFeeTracker {
    function setShare(address shareholder, uint256 amount) external;

    function depositYield(uint256 _source, uint256 _fees) external;

    function addYieldSource(address _yieldSource) external;

    function withdrawYield() external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "../libraries/Types.sol";

interface IHouse {
    function openWager(
        address _account,
        uint256 _game,
        uint256 _rolls,
        uint256 _bet,
        uint256[50] calldata _data,
        bytes32 _requestId,
        uint256 _betSize,
        uint256 _maxPayout
    ) external;

    function closeWager(
        address _account,
        uint256 _game,
        bytes32 _requestId,
        uint256 _payout
    ) external;

    function getBetByRequestId(
        bytes32 _requestId
    ) external view returns (Types.Bet memory);

    function getPlayerVolumeForEpoch(
        address account,
        uint256 epoch
    ) external view returns (uint256);

    function getGlobalVolumeForEpoch(
        uint256 epoch
    ) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

interface ITLP {
    function payWin(
        address _account,
        uint256 _game,
        bytes32 _requestId,
        uint256 _amount
    ) external;

    function receiveLoss(
        address _account,
        uint256 _game,
        bytes32 _requestId,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;

interface IVolumeRewards {
    function currentEpoch() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

library Types {
    struct Player {
        address id;
        uint256 avatar;
        address affiliate;
        string username;
    }

    struct Bet {
        uint256 globalId;
        uint256 playerId;
        bytes32 requestId;
        uint256 gameId;
        address player;
        uint256 rolls;
        uint256 bet;
        uint256[50] data;
        uint256 stake;
        uint256 payout;
        bool complete;
        uint256 opened;
        uint256 closed;
    }

    struct Game {
        uint256 id;
        bool live;
        string name;
        uint256 edge;
        uint256 date;
        address impl;
    }

    struct FeeTrackerShare {
        uint256 amount;
        uint256 totalExcluded;
    }

    /*
    struct RouletteRoll {
        uint256 id;
        uint256 requestId;
        bool fulfilled;
        uint256[50] bets;
        uint256 amount;
        uint256 result;
        address player;
        uint256 dateStart;
        uint256 dateEnd;
    }
*/
}