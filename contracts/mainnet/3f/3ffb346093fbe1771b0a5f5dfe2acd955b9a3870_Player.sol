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

import "./interfaces/IPlayer.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IERC20BackwardsCompatible.sol";
import "./libraries/Types.sol";

contract Player is IPlayer, Ownable, ReentrancyGuard {
    error OnlyXPSource(address _caller);
    error OnlyAvatarUnlocker(address _caller);
    error OnlyHouse(address _caller);
    error AlreadyInitialized();
    error LevelTooLow(uint256 _level, uint256 _minLevel);
    error UsernameTaken(string _username);
    error InvalidUsername();
    error AvatarLocked(uint256 _avatar);
    error ReferralAlreadySet();

    mapping (address => Types.Player) players;
    mapping (uint256 => uint256) levels;

    mapping (address => uint256) level;
    mapping (address => uint256) xp;
    mapping (address => address) referral;
    mapping (address => bool) xpSources;
    mapping (address => bool) avatarUnlockers;
    mapping (string => bool) usernameTaken;
    mapping (address => mapping (uint256 => bool)) avatarUnlocked; 

    IERC20BackwardsCompatible public immutable usdt;
    IERC20BackwardsCompatible public immutable sarc;
    IERC20BackwardsCompatible public immutable xarc;
    address public house;

    event LevelUp(address indexed _account, uint256 indexed _level, uint256 indexed _timestamp);

    bool private initialized;

    modifier onlyXPSource() {
        if (!xpSources[msg.sender]) {
            revert OnlyXPSource(msg.sender);
        }
        _;
    }

    modifier onlyAvatarUnlocker() {
        if (!avatarUnlockers[msg.sender]) {
            revert OnlyAvatarUnlocker(msg.sender);
        }
        _;
    }

    modifier onlyHouse() {
        if (msg.sender != house) {
            revert OnlyHouse(msg.sender);
        }
        _;
    }

    constructor (address _USDT, address _sARC, address _xARC) {
        usdt = IERC20BackwardsCompatible(_USDT);
        sarc = IERC20BackwardsCompatible(_sARC);
        xarc = IERC20BackwardsCompatible(_xARC);
    }

    function initialize(address _house) external onlyOwner {
        if (initialized) {
            revert AlreadyInitialized();
        }
        uint256 _total = 0;
        for (uint256 _i = 0; _i < 101; _i++) {
            _total += (100 * _i);
            levels[_i] = _total; // defines xp threshold for each level
        }
        house = _house;

        initialized = true;
    }

    function getVIPTier(address _account) external view returns (uint256) {
        uint256 _vip;
        uint256 _sarcBalance = sarc.balanceOf(_account);
        uint256 _xarcBalance = xarc.balanceOf(_account);
        uint256 _level = level[_account];
        if (_sarcBalance >= 2000 ether || _xarcBalance >= 1000 ether || _level >= 45) {
            if (_sarcBalance >= 80000 ether || _xarcBalance >= 40000 ether || _level == 100) {
                _vip = 4;
            } else if (_sarcBalance >= 15000 ether || _xarcBalance >= 7500 ether || _level >= 70) {
                _vip = 3;
            } else if (_sarcBalance >= 6000 ether || _xarcBalance >= 3000 ether || _level >= 50) {
                _vip = 2;
            } else {
                _vip = 1;
            }
        }
        return _vip;
    }

    function _receiveXP(address _account, uint256 _xp) private {
        xp[_account] += _xp;
        if (level[_account] == 100) {
            return;
        }
        for (uint256 _i = level[_account]; _i < 101; _i++) {
            if (xp[_account] >= levels[_i]) {
                if (_i > level[_account]) {
                    _levelUp(_account, _i);
                }
            } else {
                break;
            }
        }
    }

    function _levelUp(address _account, uint256 _level) private {
        /*
        Level 3 - Unlock daily spin
        Level 5 - Unlock weekly spin
        */
        level[_account] = _level;
        emit LevelUp(_account, _level, block.timestamp);
    }

    function setUsername(string memory _username) external nonReentrant {
        if (level[msg.sender] < 3) {
            revert LevelTooLow(level[msg.sender], 3);
        }
        if (usernameTaken[_username]) {
            revert UsernameTaken(_username);
        }
        if (keccak256(abi.encodePacked(_username)) == keccak256(abi.encodePacked(""))) {
            revert InvalidUsername();
        }
        Types.Player storage _player = players[msg.sender];
        usernameTaken[_player.username] = false;
        _player.username = _username;
        usernameTaken[_player.username] = true;
        players[msg.sender] = _player;
    }

    function setAvatar(uint256 _avatar) external nonReentrant {
        if (avatarUnlocked[msg.sender][_avatar]) {
            revert AvatarLocked(_avatar);
        }
        Types.Player storage _player = players[msg.sender];
        _player.avatar = _avatar;
        players[msg.sender] = _player;
    }

    function setReferral(address _account, address _referral) external onlyHouse nonReentrant {
        if (referral[_account] != address(0)) {
            revert ReferralAlreadySet();
        }
        referral[_account] = _referral;
    }

    function unlockAvatar(address _account, uint256 _avatar) external nonReentrant onlyAvatarUnlocker {
        avatarUnlocked[_account][_avatar] = true;
    }

    function giveXP(address _account, uint256 _xp) external nonReentrant onlyXPSource {
        _receiveXP(_account, _xp);
    }

    function addXPSource(address _xpSource) external nonReentrant onlyOwner {
        xpSources[_xpSource] = true;
    }

    function addAvatarUnlocker(address _avatarUnlocker) external nonReentrant onlyOwner {
        avatarUnlockers[_avatarUnlocker] = true;
    }

    function getProfile(address _account) external view returns (Types.Player memory, uint256) {
        return (players[_account], usdt.balanceOf(_account));
    }

    function getLevel(address _account) external view returns (uint256) {
        return level[_account];
    }

    function getXp(address _account) external view returns (uint256) {
        return xp[_account];
    }

    function getReferral(address _account) external view returns (address) {
        return referral[_account];
    }

    receive() external payable {}
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

interface IPlayer {
    function getVIPTier(address _account) external view returns (uint256);
    function getLevel(address _account) external view returns (uint256);
    function giveXP(address _account, uint256 _xp) external;
    function setReferral(address _account, address _referral) external;
    function getReferral(address _account) external view returns (address);
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