// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title HayaStakingContract
 * @dev This contract allows users to stake tokens for a specific period of time and earn rewards based on their staked amount and level.
*/
contract HayaStakingContract is ReentrancyGuard {

    /**
     * @dev Minimum stake time in seconds.
     */
    uint256 public constant MIN_STAKE_TIME = 365 days;

    /**
     * @dev The ERC20 token used for staking.
     */
    IERC20 public immutable stakeToken;

    /**
     * @dev Mapping of addresses to their corresponding stake information.
     */
    mapping(address => Stake) public stakes;

    /**
     * @dev Mapping of levels to their corresponding stake amounts.
     */
    mapping(Level => uint256) public levelAmounts;

    /**
     * @dev Enum representing the different levels of staking.
     * - Agent: Level 0
     * - Partner: Level 1
     * - GlobalPartner: Level 2
     */
    enum Level {
        Agent,
        Partner,
        GlobalPartner
    }

    /**
     * @dev Struct representing a stake made by a user.
     * - stakeTime: The time when the stake was made.
     * - unlockTime: The time when the stake can be unlocked.
     * - level: The level of the stake.
     */
    struct Stake {
        uint256 stakeTime;
        uint256 unlockTime;
        Level level;
    }

    /**
     * @dev Emitted when a user's level is changed.
     * @param user The address of the user whose level was changed.
     * @param oldLevel The old level of the user.
     * @param newLevel The new level of the user.
     */
    event LevelChanged(address indexed user, uint8 oldLevel, uint8 newLevel);

    /**
     * @dev Constructor function for the stakeContract.
     * @param _token The address of the token contract.
     */
    constructor(address _token) {
        stakeToken = IERC20(_token);
        levelAmounts[Level.Partner] = 2_000 ether;
        levelAmounts[Level.GlobalPartner] = 100_000 ether;
    }

    /**
     * @dev Upgrades the level of the stake for the caller.
     * @param _newLevel The new level to upgrade to.
     * Emits a `LevelChanged` event with the updated stake level.
     * Requirements:
     * - The caller must have an existing stake.
     * - The upgrade cost must be transferred from the caller to the contract.
     * - The stake's unlock time is set to the current block timestamp plus the minimum stake time.
     * - The stake's stake time is set to the current block timestamp.
     */
    function upgradeLevel(Level _newLevel) external nonReentrant {
        Stake storage stake = stakes[msg.sender];
        Level oldLevel = stake.level;
        uint256 upgradeCost = calculateUpgradeCost(oldLevel, _newLevel);
        stakeToken.transferFrom(msg.sender, address(this), upgradeCost);

        stake.level = _newLevel;
        stake.unlockTime = block.timestamp + MIN_STAKE_TIME;
        stake.stakeTime = block.timestamp;

        emit LevelChanged(msg.sender, uint8(oldLevel), uint8(_newLevel));
    }

    /**
     * @dev Unstakes the stake of the caller.
     * The stake must exist and be at a level higher than None.
     * The stake must also be unlocked (unlockTime <= block.timestamp).
     * Transfers the corresponding stake token amount to the caller.
     * Deletes the stake from the stakes mapping.
     * Emits a LevelChanged event with the updated stake level.
     */
    function unstake() external nonReentrant {
        Stake memory stake = stakes[msg.sender];
        require(stake.level > Level.Agent, "StakeContract: No stake found");
        require(stake.unlockTime <= block.timestamp, "StakeContract: Stake is still locked");
        Level oldLevel = stake.level;
        stakeToken.transfer(msg.sender, levelAmounts[stake.level]);

        delete stakes[msg.sender];
        emit LevelChanged(msg.sender, uint8(oldLevel), uint8(Level.Agent));
    }

    /**
     * @dev Internal function to calculate the amount of tokens required to upgrade to a higher level.
     * @param currentLevel The current level of the stake.
     * @param newLevel The new level to upgrade to.
     * @return The amount of tokens required to upgrade.
     */
    function calculateUpgradeCost(Level currentLevel, Level newLevel) public view returns (uint256) {
        require(newLevel > currentLevel && newLevel <= Level.GlobalPartner, "StakeContract: Invalid level upgrade");
        uint256 upgradeCost = levelAmounts[Level(newLevel)] - levelAmounts[Level(currentLevel)];
        return upgradeCost;
    }

    /**
     * @dev Fallback function to reject any incoming Ether transfers.
     * Reverts the transaction to prevent accidental transfers to this contract.
     */
    receive() external payable {
        revert();
    }
}