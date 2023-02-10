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

interface IFeeTracker {
    function setShare(address shareholder, uint256 amount) external;
    function depositYield(uint256 _source, uint256 _fees) external;
    function addYieldSource(address _yieldSource) external;
    function withdrawYield() external;
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

/**
 * https://arcadeum.io
 * https://arcadeum.gitbook.io/arcadeum
 * https://twitter.com/arcadeum_io
 * https://discord.gg/qBbJ2hNPf8
 */

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "../interfaces/IFeeTracker.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../libraries/Types.sol";
import "../interfaces/IERC20BackwardsCompatible.sol";

contract FeeTracker is IFeeTracker, Ownable, ReentrancyGuard {
    error OnlyTrackedToken(address _caller);
    error OnlyYieldSource(address _caller);

    uint256 public earningsTotal;
    uint256 public earningsClaimed;
    mapping (address => uint256) public earningsClaimedByAccount;

    mapping (address => Types.FeeTrackerShare) public shares;
    mapping (address => bool) public yieldSources;

    uint256 public issuedShares;
    uint256 public earningsPerShare;
    uint256 internal constant earningsPerShareDecimals = 10**36;

    IERC20BackwardsCompatible public immutable usdt;
    address public immutable trackedToken;

    event YieldDeposit(uint256 indexed _source, uint256 indexed _fees, uint256 indexed _timestamp, address _caller);
    event YieldWithdrawal(address indexed _account, uint256 indexed _fees, uint256 indexed _timestamp);

    modifier onlyTrackedToken() {
        if (msg.sender != trackedToken) {
            revert OnlyTrackedToken(msg.sender);
        }
        _;
    }

    modifier onlyYieldSource() {
        if (!yieldSources[msg.sender]) {
            revert OnlyYieldSource(msg.sender);
        }
        _;
    }

    constructor (address _usdt) {
        usdt = IERC20BackwardsCompatible(_usdt);
        trackedToken = msg.sender;
    }

    function setShare(address _account, uint256 _amount) external override nonReentrant onlyTrackedToken { // is overriding even needed?
        if (shares[_account].amount > 0) _withdrawYield(_account);

        issuedShares = issuedShares - shares[_account].amount + _amount;
        shares[_account].amount = _amount;
        shares[_account].totalExcluded = getEarningsTotalByAccount(_account);
    }

    function depositYield(uint256 _source, uint256 _fee) external override nonReentrant onlyYieldSource {
        usdt.transferFrom(msg.sender, address(this), _fee);
        if (issuedShares > 0) { // ! rewards are stuck if there are no stakers yet
            earningsTotal += _fee;
            earningsPerShare += (earningsPerShareDecimals * _fee / issuedShares);
            emit YieldDeposit(_source, _fee, block.timestamp, msg.sender);
        }
    }

    function _withdrawYield(address _account) private {
        if (shares[_account].amount == 0) {
            return;
        }

        uint256 _amount = getEarningsUnclaimedByAccount(_account);
        if (_amount > 0) {
            shares[_account].totalExcluded = getEarningsTotalByAccount(_account);

            earningsClaimed += _amount;
            earningsClaimedByAccount[_account] += _amount;

            usdt.transfer(_account, _amount);
            emit YieldWithdrawal(_account, _amount, block.timestamp);
        }
    }

    function withdrawYield() external nonReentrant {
        _withdrawYield(msg.sender);
    }

    function getEarningsUnclaimedByAccount(address _account) public view returns (uint256) {
        if (shares[_account].amount == 0) {
            return 0;
        }

        uint256 _earningsTotal = getEarningsTotalByAccount(_account);
        uint256 _earningsClaimed = shares[_account].totalExcluded;

        return _earningsTotal > _earningsClaimed ? _earningsTotal - _earningsClaimed : 0;
    }

    function getEarningsTotal() external view returns (uint256) {
        return earningsTotal;
    }

    function getEarningsTotalByAccount(address _account) public view returns (uint256) {
        return shares[_account].amount * earningsPerShare / earningsPerShareDecimals;
    }

    function getEarningsClaimed() external view returns (uint256) {
        return earningsClaimed;
    }

    function getEarningsClaimedByAccount(address _account) external view returns (uint256) {
        return earningsClaimedByAccount[_account];
    }

    function getIssuedShares() external view returns (uint256) {
        return issuedShares;
    }

    function getEarningsPerShare() external view returns (uint256) {
        return earningsPerShare;
    }

    function getTrackedToken() external view returns (address) {
        return trackedToken;
    }

    function addYieldSource(address _yieldSource) external nonReentrant onlyOwner {
        yieldSources[_yieldSource] = true;
    }

    function getYieldSource(address _yieldSource) external view returns (bool) {
        return yieldSources[_yieldSource];
    }

    receive() external payable {}
}