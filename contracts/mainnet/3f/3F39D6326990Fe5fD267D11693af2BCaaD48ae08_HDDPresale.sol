// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HDDPresale is Ownable, ReentrancyGuard {
    IERC20 public HDDToken;
    IERC20 public buyingToken;

    uint8 public constant HDD_DECIMAL = 18;
    uint8 public constant BUYING_TOKEN_DECIMAL = 6;
    uint8 public constant PRICE_DECIMAL = 10;

    uint256 public constant HARD_CAP = 500_000 * 10**HDD_DECIMAL; // hardcap 500,000 HDD

    uint256 public priceToken = 5; // 0.5 USDC
    uint256 public minDepositAmount = 50 * 10**BUYING_TOKEN_DECIMAL; // min: 50 USDC
    uint256 public maxDepositAmount = 2000 * 10**BUYING_TOKEN_DECIMAL; // max: 2,000 USDC
    uint256 public startTime = 1678975200;
    uint256 public endTime = 1679234400;

    // Total HDD token user will receive
    mapping(address => uint256) public userReceive;
    // Total USDC token user deposit
    mapping(address => uint256) public userDeposited;
    // Total HDD token user claimed
    mapping(address => uint256) public userClaimed;
    // Total HDD sold
    uint256 public totalTokenSold = 0;

    // Claim token
    uint256[] public claimableTimestamp;
    mapping(uint256 => uint256) public claimablePercents;
    mapping(address => uint256) public claimCounts;

    event TokenBuy(address user, uint256 tokens);
    event TokenClaim(address user, uint256 tokens);

    constructor(address _HDDToken, address _buyingToken) {
        HDDToken = IERC20(_HDDToken);
        buyingToken = IERC20(_buyingToken);
    }

    function buy(uint256 _amount) public nonReentrant {
        require(block.timestamp >= startTime, "The presale has not started");
        require(block.timestamp <= endTime, "The presale has ended");

        require(
            userDeposited[_msgSender()] + _amount >= minDepositAmount,
            "Below minimum amount"
        );
        require(
            userDeposited[_msgSender()] + _amount <= maxDepositAmount,
            "You have reached maximum deposit amount per user"
        );

        uint256 tokenQuantity = ((_amount / priceToken) * PRICE_DECIMAL) *
            10**(HDD_DECIMAL - BUYING_TOKEN_DECIMAL);
        require(
            totalTokenSold + tokenQuantity <= HARD_CAP,
            "Hard Cap is reached"
        );

        buyingToken.transferFrom(_msgSender(), address(this), _amount);

        userReceive[_msgSender()] += tokenQuantity;
        userDeposited[_msgSender()] += _amount;
        totalTokenSold += tokenQuantity;

        emit TokenBuy(_msgSender(), tokenQuantity);
    }

    function claim() external nonReentrant {
        uint256 userReceiveAmount = userReceive[_msgSender()];
        require(userReceiveAmount > 0, "Nothing to claim");
        require(claimableTimestamp.length > 0, "Can not claim at this time");
        require(
            block.timestamp >= claimableTimestamp[0],
            "Can not claim at this time"
        );

        uint256 startIndex = claimCounts[_msgSender()];
        require(
            startIndex < claimableTimestamp.length,
            "You have claimed all token"
        );

        uint256 tokenQuantity = 0;
        for (
            uint256 index = startIndex;
            index < claimableTimestamp.length;
            index++
        ) {
            uint256 timestamp = claimableTimestamp[index];
            if (block.timestamp >= timestamp) {
                tokenQuantity +=
                    (userReceiveAmount * claimablePercents[timestamp]) /
                    100;
                claimCounts[_msgSender()]++;
            } else {
                break;
            }
        }

        require(tokenQuantity > 0, "Token quantity is not enough to claim");
        require(
            HDDToken.transfer(_msgSender(), tokenQuantity),
            "Cannot transfer HDD token"
        );

        userClaimed[_msgSender()] += tokenQuantity;

        emit TokenClaim(_msgSender(), tokenQuantity);
    }

    function getTokenClaimable(address _buyer) public view returns (uint256) {
        uint256 userReceiveAmount = userReceive[_buyer];
        uint256 startIndex = claimCounts[_buyer];
        uint256 tokenQuantity = 0;
        for (
            uint256 index = startIndex;
            index < claimableTimestamp.length;
            index++
        ) {
            uint256 timestamp = claimableTimestamp[index];
            if (block.timestamp >= timestamp) {
                tokenQuantity +=
                    (userReceiveAmount * claimablePercents[timestamp]) /
                    100;
            } else {
                break;
            }
        }
        return tokenQuantity;
    }

    function getTokenReceive(address _buyer) public view returns (uint256) {
        require(_buyer != address(0), "Zero address");
        return userReceive[_buyer];
    }

    function getTokenDeposited(address _buyer) public view returns (uint256) {
        require(_buyer != address(0), "Zero address");
        return userDeposited[_buyer];
    }

    function setSaleInfo(
        uint256 _price,
        uint256 _minDepositAmount,
        uint256 _maxDepositAmount,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        require(
            _minDepositAmount < _maxDepositAmount,
            "Deposit amount is invalid"
        );
        require(_startTime < _endTime, "Time invalid");

        priceToken = _price;
        minDepositAmount = _minDepositAmount;
        maxDepositAmount = _maxDepositAmount;
        startTime = _startTime;
        endTime = _endTime;
    }

    function setSaleTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(_startTime < _endTime, "Time invalid");
        startTime = _startTime;
        endTime = _endTime;
    }

    function getSaleInfo()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            priceToken,
            minDepositAmount,
            maxDepositAmount,
            startTime,
            endTime
        );
    }

    function setClaimableTimes(uint256[] memory _timestamp) external onlyOwner {
        require(_timestamp.length > 0, "Empty input");
        claimableTimestamp = _timestamp;
    }

    function setClaimablePercents(
        uint256[] memory _timestamps,
        uint256[] memory _percents
    ) external onlyOwner {
        require(_timestamps.length > 0, "Empty input");
        require(_timestamps.length == _percents.length, "Empty input");
        for (uint256 index = 0; index < _timestamps.length; index++) {
            claimablePercents[_timestamps[index]] = _percents[index];
        }
    }

    function setBuyingToken(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Zero address");
        buyingToken = IERC20(_newAddress);
    }

    function setHDDToken(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Zero address");
        HDDToken = IERC20(_newAddress);
    }

    function withdrawFunds() external onlyOwner {
        buyingToken.transfer(
            _msgSender(),
            buyingToken.balanceOf(address(this))
        );
    }

    function withdrawUnsold() external onlyOwner {
        uint256 amount = HDDToken.balanceOf(address(this)) - totalTokenSold;
        HDDToken.transfer(_msgSender(), amount);
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