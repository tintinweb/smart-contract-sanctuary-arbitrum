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

import "./interfaces/IConsole.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Console is IConsole, Ownable {
    error GameNotFound(uint256 _id);

    mapping (uint256 => Types.Game) public games;
    mapping (address => uint256) public impls;
    uint256 public id;

    constructor () {}

    function addGame(bool _live, string memory _name, uint256 _edge, address _impl) external onlyOwner {
        Types.Game memory _game = Types.Game({
            id: id,
            live: _live,
            name: _name,
            edge: _edge,
            date: block.timestamp,
            impl: _impl
        });

        games[id] = _game;
        impls[_impl] = id;
        id ++;
    }

    function editGame(uint256 _id, bool _live, string memory _name, uint256 _edge, address _impl) external onlyOwner {
        if(games[_id].date == 0) {
            revert GameNotFound(_id);
        }

        Types.Game memory _game = Types.Game({
            id: games[_id].id,
            live: _live,
            name: _name,
            edge: _edge,
            date: block.timestamp,
            impl: _impl
        });
        games[_id] = _game;
        impls[_impl] = _id;
    }

    function getId() external view returns (uint256) {
        return id;
    }

    function getGame(uint256 _id) external view returns (Types.Game memory) {
        return games[_id];
    }

    function getGameByImpl(address _impl) external view returns (Types.Game memory) {
        return games[impls[_impl]];
    }

    function getLiveGames() external view returns (Types.Game[] memory) {
        Types.Game[] memory _games;
        uint256 _j = 0;
        for (uint256 _i = 0; _i < id; _i++) {
            Types.Game memory _game = games[_i];
            if (_game.live) {
                _games[_j] = _game;
                _j++;
            }
        }
        return _games;
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