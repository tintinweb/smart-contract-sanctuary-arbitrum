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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRandomizer {
    function request(uint256 callbackGasLimit) external returns (uint256);
    function request(uint256 callbackGasLimit, uint256 confirmations) external returns (uint256);
    function clientWithdrawTo(address _to, uint256 _amount) external;
    function estimateFee(uint256 callbackGasLimit) external view returns (uint256);
    function estimateFee(uint256 callbackGasLimit, uint256 confirmations) external returns (uint256);
}

// Coinflip contract
contract CoinFlipTestV2 is Ownable, ReentrancyGuard {
    struct UserInfo {
        address user;
        uint256 userBet;
        uint256 time;
        bool isTail;
    }

    // Arbitrum goerli
    IRandomizer public randomizer = IRandomizer(0x923096Da90a3b60eb7E12723fA2E1547BA9236Bc);

    IERC20 public token; //immutable

    // Stores each game to the player
    mapping(uint256 => UserInfo) public flipToAddress;
    mapping(address => uint256) public addressToFlip;

    uint256 public callbackGasLimit = 500000;
    uint256 public minBet = 1 * 1e6;
    uint256 public rewardPool;
    uint256 public rewardPoolDenominator = 1000; //0.1% from reward pool supply
    uint256 public refundDelay = 10;
    uint256 public tempStorage; //private
    uint8 public edge = 50; //private

    // Events
    event Win(address indexed winner, uint256 amount, uint256 gameId);
    event Lose(address indexed loser, uint256 amount, uint256 gameId);
    event Cancel(address indexed user, uint256 amount, uint256 gameId);
    event CallbackGasLimitUpdated(uint256 oldValue, uint256 newValue);
    event SettingsUpdated(uint256 newDenominator, uint256 newDelay);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function maxBet() public view returns (uint256) {
        return rewardPool / rewardPoolDenominator;
    }

    function addToRewardPool(uint256 amount) external onlyOwner {
        require(token.transferFrom(msg.sender, address(this), amount), "TOKEN TRANSFER FAILED");
        rewardPool += amount;
    }

    // The coin flip containing the random request
    function flip(uint256 userBet, bool isTail) external payable returns (uint256) {
        require(addressToFlip[msg.sender] == 0, "user have pending game");
        uint256 fee = randomizer.estimateFee(callbackGasLimit);
        require(msg.value >= fee, "INSUFFICIENT ETH AMOUNT PROVIDED");
        require(minBet <= userBet && userBet <= maxBet(), "WRONG BET");
        require(token.transferFrom(msg.sender, address(this), userBet), "TOKEN TRANSFER FAILED");

        uint256 id = randomizer.request(callbackGasLimit);
        flipToAddress[id] = UserInfo(msg.sender, userBet, block.timestamp, isTail);

        tempStorage += userBet;
        rewardPool -= userBet;

        uint256 refund = msg.value - fee;
        (bool success, ) = payable(msg.sender).call{ value: refund }("");
        require(success, "Can't send ETH");

        return id;
    }

    // Callback function called by the randomizer contract when the random value is generated
    function randomizerCallback(uint256 _id, bytes32 _value) external {
        //Callback can only be called by randomizer
        require(msg.sender == address(randomizer), "Caller not Randomizer");

        // Get the player data from the flip ID
        UserInfo storage player = flipToAddress[_id];

        // Convert the random bytes to a number between 0 and 99
        uint256 random = uint256(_value) % 99;

        bool result = (random < edge);
        if (player.isTail == result) {
            tempStorage -= player.userBet;
            token.transfer(player.user, player.userBet*2);
            emit Win(player.user, player.userBet*2, _id);
        } else {
            tempStorage -= player.userBet;
            rewardPool += player.userBet*2;
            emit Lose(player.user, player.userBet, _id);
        }

        delete addressToFlip[player.user];
        delete flipToAddress[_id];
    }

    function getRefund() external nonReentrant {
        uint256 id = addressToFlip[msg.sender];
        require(id != 0, "no pending games");

        UserInfo storage player = flipToAddress[id];
        require(block.timestamp >= player.time + refundDelay);

        token.transfer(player.user, player.userBet);
        tempStorage -= player.userBet;
        rewardPool += player.userBet;

        emit Cancel(player.user, player.userBet, id);

        delete flipToAddress[id];
        delete addressToFlip[msg.sender];
    }

    function changeCallbackGasLimit(uint256 newLimit) external onlyOwner {
        uint256 oldValue = callbackGasLimit;
        callbackGasLimit = newLimit;
        emit CallbackGasLimitUpdated(oldValue, newLimit);
    }

    // Allows the owner to withdraw their deposited randomizer funds
    function randomizerWithdraw(uint256 amount) external onlyOwner {
        require(amount > 0, "invalid amount");
        randomizer.clientWithdrawTo(msg.sender, amount);
    }

    function changeSettings(uint256 newDenominator, uint256 newDelay, uint8 fee) external onlyOwner {
        require(newDenominator > 0, "invalid new denomintaor");
        require(newDelay > 0, "invalid new delsay");
        rewardPoolDenominator = newDenominator;
        refundDelay = newDelay;
        edge = fee;
        emit SettingsUpdated(newDenominator, newDelay);
    }

    function withdraw(address _token, uint256 _amount) external onlyOwner {
        if (_token != address(0)) {
            if (_token == address(token)) {
                require(_amount <= rewardPool, "amount exceeded remain reward pool");
                rewardPool -= _amount;
            }
			IERC20(_token).transfer(msg.sender, _amount);
		} else {
			(bool success, ) = payable(msg.sender).call{ value: _amount }("");
			require(success, "Can't send ETH");
		}
	}

    function getFee() public view returns (uint256) {
        return randomizer.estimateFee(callbackGasLimit);
    }
}