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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
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

/**
 * https://arcadeum.io
 * https://arcadeum.gitbook.io/arcadeum
 * https://twitter.com/arcadeum_io
 * https://discord.gg/qBbJ2hNPf8
 */

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IERC20BackwardsCompatible.sol";
import "../interfaces/IConsole.sol";
import "../interfaces/IHouse.sol";
import "../interfaces/IRNG.sol";
import "../interfaces/IGame.sol";
import "../interfaces/ICaller.sol";
import "../libraries/Types.sol";

contract Game is IGame, Ownable, ReentrancyGuard {
    error InvalidGas(uint256 _gas);
    error PrepayFailed();
    error BetTooSmall(uint256 _bet);
    error TooManyMultibets(uint256 _rolls, uint256 _maxMultibets);
    error InvalidBet(uint256 _bet);
    error InvalidRange(uint256 _from, uint256 _to);
    error RNGUnauthorized(address _caller);
    error MultibetsNotSupported();
    error InvalidMaxMultibet(uint256 _maxMultibets);

    IERC20BackwardsCompatible public usdt;
    IConsole public console;
    IHouse public house;
    IRNG public rng;
    address public ALP;
    uint256 public id;
    uint256 public numbersPerRoll;
    uint256 public maxMultibets;
    bool public supportsMultibets;

    event GameStart(bytes32 indexed requestId);
    event GameEnd(bytes32 indexed requestId, uint256[] _randomNumbers, uint256[] _rolls, uint256 _stake, uint256 _payout, address indexed _account, uint256 indexed _timestamp);

    modifier onlyRNG() {
        if (msg.sender != address(rng)) {
            revert RNGUnauthorized(msg.sender);
        }
        _;
    }

    constructor (address _USDT, address _console, address _house, address _ALP, address _rng, uint256 _id, uint256 _numbersPerRoll, uint256 _maxMultibets, bool _supportsMultibets) {
        usdt = IERC20BackwardsCompatible(_USDT);
        console = IConsole(_console);
        house = IHouse(_house);
        ALP = _ALP;
        rng = IRNG(_rng);
        id = _id;
        numbersPerRoll = _numbersPerRoll;
        maxMultibets = (_maxMultibets == 0 || _maxMultibets > 100 || !_supportsMultibets) ? 1 : _maxMultibets;
        supportsMultibets = _supportsMultibets;
    }

    function play(uint256 _rolls, uint256 _bet, uint256[50] memory _data, uint256 _stake, address _referral) external payable override nonReentrant returns (bytes32) {
        if (console.getGasPerRoll() != msg.value) {
            revert InvalidGas(msg.value);
        }
        {
            (bool _prepaidFulfillment, ) = payable(address(rng.getSponsorWallet())).call{value: msg.value}("");
            if (!_prepaidFulfillment) {
                revert PrepayFailed();
            }
        }
        if (console.getMinBetSize() > _stake) {
            revert BetTooSmall(_bet);
        }
        _data = validateBet(_bet, _data, _stake);
        if (_rolls == 0 || _rolls > maxMultibets) {
            revert TooManyMultibets(_rolls, maxMultibets);
        }

        bytes32 _requestId = rng.makeRequestUint256Array(_rolls * numbersPerRoll);

        house.openWager(msg.sender, id, _rolls, _bet, _data, _requestId, _stake * _rolls, getMaxPayout(_bet, _data), _referral);
        emit GameStart(_requestId);
        return _requestId;
    }

    function rollFromToInclusive(uint256 _rng, uint256 _from, uint256 _to) public pure returns (uint256) {
        _to++;
        if (_from >= _to) {
            revert InvalidRange(_from, _to);
        }
        return (_rng % _to) + _from;
    }

    function setMaxMultibets(uint256 _maxMultibets) external nonReentrant onlyOwner {
        if (!supportsMultibets) {
            revert MultibetsNotSupported();
        }
        if (_maxMultibets == 0 || _maxMultibets > 100) {
            revert InvalidMaxMultibet(_maxMultibets);
        }
        maxMultibets = _maxMultibets;
    }

    function getMultiBetData() external view returns (bool, uint256, uint256) {
        return (supportsMultibets, maxMultibets, numbersPerRoll);
    }

    function getMaxBet(uint256 _bet, uint256[50] memory _data) external view returns (uint256) {
        return ((usdt.balanceOf(ALP) * getEdge() / 10000) * (10**18)) / getMaxPayout(_bet, _data);
    }

    function getId() external view returns (uint256) {
        return id;
    }

    function getLive() external view returns (bool) {
        Types.Game memory _Game = console.getGame(id);
        return _Game.live;
    }

    function getEdge() public view returns (uint256) {
        Types.Game memory _Game = console.getGame(id);
        return _Game.edge;
    }

    function getName() external view returns (string memory) {
        Types.Game memory _Game = console.getGame(id);
        return _Game.name;
    }

    function getDate() external view returns (uint256) {
        Types.Game memory _Game = console.getGame(id);
        return _Game.date;
    }

    function validateBet(uint256 _bet, uint256[50] memory _data, uint256 _stake) public virtual returns (uint256[50] memory) {}
    function getMaxPayout(uint256 _bet, uint256[50] memory _data) public virtual view returns (uint256) {}

    receive() external payable {}
}

/**
 * https://arcadeum.io
 * https://arcadeum.gitbook.io/arcadeum
 * https://twitter.com/arcadeum_io
 * https://discord.gg/qBbJ2hNPf8
 */

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "./Game.sol";

contract GamePlinko is Game, ICaller {
    constructor (address _USDT, address _console, address _house, address _ALP, address _rng, uint256 _id, uint256 _numbersPerRoll, uint256 _maxMultibets, bool _supportsMultibets) Game(_USDT, _console, _house, _ALP, _rng, _id, _numbersPerRoll, _maxMultibets, _supportsMultibets) {}

    function fulfillRNG(bytes32 _requestId, uint256[] memory _randomNumbers) external nonReentrant onlyRNG {
        Types.Bet memory _Bet = house.getBetByRequestId(_requestId);
        uint256 _stake = _Bet.stake / _Bet.rolls;
        uint256 _payout;
        uint256[] memory _rolls = new uint256[](_Bet.rolls);
        for (uint256 _i = 0; _i < _Bet.rolls; _i++) {
            uint256 _roll = rollFromToInclusive(_randomNumbers[_i], 1, 72089);
            if (_roll == 1 || _roll == 65536) {
                _payout += _stake * 110;
            } else if ((_roll > 1 && _roll <= 17) || (_roll > 65519 && _roll <= 65535)) {
                _payout += _stake * 41;
            } else if ((_roll > 17 && _roll <= 137) || (_roll > 65399 && _roll <= 65519)) {
                _payout += _stake * 10;
            } else if ((_roll > 137 && _roll <= 697) || (_roll > 64839 && _roll <= 65399)) {
                _payout += _stake * 5;
            } else if ((_roll > 697 && _roll <= 2517) || (_roll > 63019 && _roll <= 64839)) {
                _payout += _stake * 3;
            } else if ((_roll > 2517 && _roll <= 6885) || (_roll > 58651 && _roll <= 63019)) {
                _payout += _stake * 15000 / 10000;
            } else if ((_roll > 6885 && _roll <= 14893) || (_roll > 50643 && _roll <= 58651)) {
                _payout += _stake;
            } else if ((_roll > 14893 && _roll <= 26333) || (_roll > 39203 && _roll <= 50643) || (_roll > 65536)) {
                _payout += _stake * 10000 / 20000;
            } else if (_roll > 26333 && _roll <= 39203) {
                _payout += _stake / 10000 * 3000;
            }
            _rolls[_i] = _roll;
        }
        house.closeWager(_Bet.player, id, _requestId, _payout);
        emit GameEnd(_requestId, _randomNumbers, _rolls, _Bet.stake, _payout, _Bet.player, block.timestamp);
    }

    function validateBet(uint256 _bet, uint256[50] memory, uint256) public override pure returns (uint256[50] memory) {
        if (_bet > 0) {
            revert InvalidBet(_bet);
        }
        uint256[50] memory _empty;
        return _empty;
    }

    function getMaxPayout(uint256, uint256[50] memory) public override pure returns (uint256) {
        return 110 * (10**18);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

interface ICaller {
    function fulfillRNG(bytes32 _requestId, uint256[] memory _randomNumbers) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "../libraries/Types.sol";

interface IConsole {
    function getGasPerRoll() external view returns (uint256);
    function getMinBetSize() external view returns (uint256);
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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

interface IGame {
    function play(uint256 _rolls, uint256 _bet, uint256[50] memory _data, uint256 _stake, address _referral) external payable returns (bytes32);
    function getMaxPayout(uint256 _bet, uint256[50] memory _data) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "../libraries/Types.sol";

interface IHouse {
    function openWager(address _account, uint256 _game, uint256 _rolls, uint256 _bet, uint256[50] calldata _data, bytes32 _requestId, uint256 _betSize, uint256 _maxPayout, address _referral) external;
    function closeWager(address _account, uint256 _game, bytes32 _requestId, uint256 _payout) external;
    function getBetByRequestId(bytes32 _requestId) external view returns (Types.Bet memory);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

interface IRNG {
    function getSponsorWallet() external view returns (address);
    function makeRequestUint256() external returns (bytes32);
    function makeRequestUint256Array(uint256 size) external returns (bytes32);
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