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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
pragma solidity ^0.8.13;

/*
 * Y   Y   OOO   III  N   N  K   K   !!
 *  Y Y   O   O   I   NN  N  K  K    !! 
 *   Y    O   O   I   N N N  KKK     !! 
 *   Y    O   O   I   N  NN  K  K       
 *   Y     OOO   III  N   N  K   K   !! 
 */

/*
 * @title Yoink!
 * @dev This smart contract facilitates an on-chain PvP (Player versus Player) game called "Yoink". 
 * In this competitive environment, players strive to be the last Yoinker before the timer concludes. 
 * The game operates in perpetual rounds, where each Yoink action post-timer initiates a new round.
 * Players vie for rewards in ETH, which are distributed automatically with the commencement of a new round.
 * The contract handles the game logic, player interactions, and reward distributions.
 *
 * @disclaimer: this game is highly experimental, play at your own cost.
 *
 * Telegram: https://t.me/yoink_official
 * Website/app: https://yoinkit.xyz
 * Twitter: https://twitter.com/Yoink_Game
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Yoink is ReentrancyGuard, Ownable {
    IERC20 public paymentToken;

    address public lastYoinker;
    RoundWinner[] public roundWinners;

    // Totals
    uint256 public totalYoinks;
    uint256 public totalTokensUsed;
    uint256 public totalRewardsWon;

    uint256 public lastYoinkTime;
    uint256 public currentRoundPrizePool;
    uint256 public nextRoundPrizePool;
    uint256 public yoinkCost;
    uint256 public nextRoundYoinkCost;
    uint256 public gameDuration = 120 seconds; // 2 minutes per round initially, will be adjusted throughout if community wants
    uint256 public nextRoundGameDuration;

    mapping(address => uint256) public yoinkCount;
    mapping(address => bool) public isBlacklisted;

    // State
    bool public isActive;

    event Yoinked(address indexed yoinker, uint256 time);
    event PrizeClaimed(address indexed winner, uint256 prizeAmount);
    event RewardsAdded(uint256 amount, address indexed depositor);
    event StuckTokensClaimed(uint256 amount, address indexed owner);
    event GameStarted();
    event GameEnded(address indexed winner, uint256 prizeAmount);

    struct RoundWinner {
        address winner;
        uint256 reward;
    }

    constructor(uint256 _yoinkCost) {
        yoinkCost = _yoinkCost;
        isActive = false;
    }

    modifier gameActive() {
        require(isActive, "Game is not active");
        _;
    }

    modifier notBlacklisted() {
        require(!isBlacklisted[msg.sender], "Address blacklisted");
        _;
    }

    // function to accept ether and update prize pools accordingly
    receive() external payable {
        if (isActive && (lastYoinkTime + gameDuration > block.timestamp)) {
            currentRoundPrizePool += msg.value; // Add to the current round if the game is active
        } else {
            nextRoundPrizePool += msg.value; // Otherwise, add to the next round
        }
        emit RewardsAdded(msg.value, msg.sender);
    }

    /* VIEW */
    // Returns the current prize pool
    function getCurrentPrizePool() external view returns (uint256) {
        return currentRoundPrizePool;
    }

    // Returns the time left for the game to end
    function timeUntilEnd() external view returns (uint256) {
        if (lastYoinkTime == 0) {
            return gameDuration;
        }
        uint256 timeElapsed = block.timestamp - lastYoinkTime;
        return timeElapsed >= gameDuration ? 0 : gameDuration - timeElapsed;
    }

    /* INTERNAL */
    // Internal function to check and update the game status based on the time and active flag
    function _checkGameStatus() internal {
        if (
            lastYoinkTime != 0 &&
            block.timestamp > lastYoinkTime + gameDuration &&
            isActive
        ) {
            uint256 prizeAmount = currentRoundPrizePool; // Use the segregated prize pool
            payable(lastYoinker).transfer(prizeAmount);
            totalRewardsWon += prizeAmount; // Increment the total rewards sent

            emit PrizeClaimed(lastYoinker, prizeAmount);
            emit GameEnded(lastYoinker, prizeAmount);

            // Store the winner of this round and their reward
            roundWinners.push(
                RoundWinner({winner: lastYoinker, reward: prizeAmount})
            );

            // Transfer next round's pool to the current round and reset next round's pool
            currentRoundPrizePool = nextRoundPrizePool;
            nextRoundPrizePool = 0;

            // Update yoinkCost for the next round
            if (nextRoundYoinkCost > 0) {
                yoinkCost = nextRoundYoinkCost;
                nextRoundYoinkCost = 0; // Reset nextRoundYoinkCost
            }

            // Update gameDuration for the next round if nextRoundGameDuration has been set
            if (nextRoundGameDuration > 0) {
                gameDuration = nextRoundGameDuration;
                nextRoundGameDuration = 0; // Reset nextRoundGameDuration
            }

            // Reset game state for the next round
            lastYoinker = address(0);
            lastYoinkTime = 0;
            isActive = true;
        }
    }

    // Handles the transfer and burn of tokens for a Yoink
    function _handleTokenTransferAndBurn() internal {
        require(
            paymentToken.transferFrom(msg.sender, address(this), yoinkCost),
            "Transfer of tokens to contract failed"
        );

        require(
            paymentToken.transfer(
                0x000000000000000000000000000000000000dEaD,
                yoinkCost
            ),
            "Transfer of tokens to dead address failed"
        );
    }

    // Validates the conditions for a Yoink
    function _validateYoinkConditions() internal view {
        require(isActive, "The game is not active");
        require(msg.sender == tx.origin, "Sender cannot be a contract");
        uint256 balance = paymentToken.balanceOf(msg.sender);
        require(balance >= yoinkCost, "Not enough $TOKEN tokens");
        uint256 allowance = paymentToken.allowance(msg.sender, address(this));
        require(
            allowance >= yoinkCost,
            "Contract not approved to spend enough $TOKEN tokens"
        );
    }

    // Updates the game state post a Yoink
    function _updateGameState() internal {
        lastYoinker = msg.sender;
        lastYoinkTime = block.timestamp;
        yoinkCount[msg.sender]++;
        totalYoinks++;
        totalTokensUsed += yoinkCost;
        emit Yoinked(msg.sender, block.timestamp);
    }

    /* EXTERNAL */
    // Sets the payment token for the game
    function setPaymentToken(address _paymentToken) external onlyOwner {
        require(
            address(paymentToken) == address(0),
            "PaymentToken is already set"
        );
        paymentToken = IERC20(_paymentToken);
    }

    // Allows the owner to add funds to the prize pool
    function addFundsToPrizePool() external payable onlyOwner {
        require(msg.value > 0, "Amount should be greater than 0");
        if (isActive && (lastYoinkTime + gameDuration > block.timestamp)) {
            currentRoundPrizePool += msg.value; // Add to the current round if the game is active
        } else {
            nextRoundPrizePool += msg.value; // Otherwise, add to the next round
        }
        emit RewardsAdded(msg.value, msg.sender);
    }

    // Set the cost to yoink, takes effect on the next round
    function setYoinkCost(uint256 _yoinkCost) external onlyOwner {
        nextRoundYoinkCost = _yoinkCost;
    }

    // Set the new game duration in seconds, takes effect on the next round
    function setNextRoundGameDuration(uint256 _gameDuration)
        external
        onlyOwner
    {
        nextRoundGameDuration = _gameDuration;
    }

    // Main function for players to perform a Yoink
    function yoinkIt() external nonReentrant gameActive notBlacklisted {
        _checkGameStatus();
        _validateYoinkConditions();
        _handleTokenTransferAndBurn();
        _updateGameState();
    }

    // Starts the game (should only be called once before the first round)
    function startGame() external onlyOwner {
        require(
            address(paymentToken) != address(0),
            "PaymentToken must be set before starting the game"
        );
        require(!isActive, "Game is already active");
        isActive = true;

        // Transfer nextRoundPrizePool to currentRoundPrizePool at the start of the game
        currentRoundPrizePool += nextRoundPrizePool;
        nextRoundPrizePool = 0;

        emit GameStarted();
    }

    // Stops the game (only use if needed!)
    function stopGame() external onlyOwner {
        require(isActive, "Game is already inactive");
        isActive = false;
    }

    // Function to blacklist an address
    function blacklistBot(address _address) external onlyOwner {
        require(_address != address(0), "Invalid address");
        isBlacklisted[_address] = true;
    }

    // Function to remove an address from the blacklist
    function unblacklistBot(address _address) external onlyOwner {
        require(_address != address(0), "Invalid address");
        isBlacklisted[_address] = false;
    }

    // Allows the owner to withdraw all Ether (only use if needed!)
    function emergencyWithdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    // Allows the owner to claim the remaining tokens (only use if needed!)
    function emergencyWithdrawTokens() external onlyOwner {
        uint256 balance = paymentToken.balanceOf(address(this));
        require(
            paymentToken.transfer(owner(), balance),
            "Transfer of tokens to owner failed"
        );
        emit StuckTokensClaimed(balance, owner());
    }
}