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

contract rektPrediction is Ownable, ReentrancyGuard {
    struct UserData {
        uint256 totalContributed;
        bool isTrue;
    }

    struct ContractData {
        uint64 startTime;
        uint64 endTime;
        uint64 finalTime;
        uint256 totalRektTeamA;
        uint64 totalUsersTeamA;
        uint256 totalRektTeamB;
        uint64 totalUsersTeamB;
        uint8 serviceFee;
        bool isFinalized;
    }

    IERC20 public constant rekt = IERC20(0x1D987200dF3B744CFa9C14f713F5334CB4Bc4D5D);
    uint256 private constant ACC_FACTOR = 10 ** 36;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;

    string public description;
    bool private result;
    bool public isFinalized;

    uint256 private rewardPerContribution;
    uint256 public minContribution = 10**6; //1 rekt token
    uint256 public totalContributedTeamA;
    uint64 public totalUsersA;
    uint256 public totalContributedTeamB;
    uint64 public totalUsersB;

    uint64 public contributionStartTime;
    uint64 public contributionEndTime;
    uint64 public eventEndTime;
    uint8 public serviceFee = 10;

    mapping(address => UserData) public userContribution;

    event UserContribution(address indexed user, uint256 totalContribution, bool isTrue);
    event ClaimReward(address indexed user, uint256 deposit, uint256 reward);
    event SubmitResult(bool isTrue, uint256 time);
    event TimesSet(uint64 startTime, uint64 endTime, uint64 finalTime);
    event DescriptionUpdated(string description);
    event ServiceFeeUpdated(uint8 newFee);
    event MinContributionUpdated(uint256 newMinContributionAmount);

    constructor (
        address _owner,
        string memory _description
    ) {
        _transferOwnership(_owner);
        description = _description;

        emit DescriptionUpdated(_description);
    }

        function setTimes(
            uint64 _contributionStartTime,
            uint64 _contributionEndTime,
            uint64 _eventEndTime
        ) external onlyOwner {
        require(contributionStartTime == 0, "ALREADY SET"); //|| block.timestamp < contributionStartTime

        require(_contributionStartTime > block.timestamp, "START TIME MUST BE IN FUTURE");
        require(_contributionEndTime > _contributionStartTime, "END TIME MUST BE GREATER THAN START TIME");
        require(_eventEndTime > _contributionEndTime, "FINAL TIME MUST BE GREATER THAN END TIME");

        contributionStartTime = _contributionStartTime;
        contributionEndTime = _contributionEndTime;
        eventEndTime = _eventEndTime;

        emit TimesSet(contributionStartTime, contributionEndTime, eventEndTime);
    }

    function contribute(uint256 _amount, bool _isTrue) external nonReentrant {
        UserData memory user = userContribution[_msgSender()];
        require(
            block.timestamp >= contributionStartTime &&
            block.timestamp <= contributionEndTime,
            "OUTSIDE CONTRIBUTION PERIOD"
        );

        uint8 contribution = 1;

        if (user.totalContributed != 0) {
            require(user.isTrue == _isTrue, "CANNOT CONTRIBUTE TO ANOTHER TEAM");
            contribution = 0;
        }

        require(
            user.totalContributed + _amount >= minContribution &&
            _amount > 0,
            "LESS THAN MIN CONTRIBUTION"
        );

        require(rekt.transferFrom(_msgSender(), address(this), _amount), "REKT TRANSFER FAILED");

        user.totalContributed += _amount;
        user.isTrue = _isTrue;

        userContribution[_msgSender()] = user;

        if(_isTrue) {
            totalContributedTeamA += _amount;
            totalUsersA += contribution;
        } else {
            totalContributedTeamB += _amount;
            totalUsersB += contribution;
        }

        emit UserContribution(_msgSender(), user.totalContributed, user.isTrue);
    }

    function finalize(bool isTrue) external nonReentrant onlyOwner {
        require(
            block.timestamp >= eventEndTime &&
            eventEndTime != 0,
            "EVENT TIME NOT ENDED"
        );
        require(!isFinalized, "ALREADY FINALIZED");

        if (isTrue) {
            uint256 fee = totalContributedTeamB * serviceFee / 100;
            if (fee > 0) {
                totalContributedTeamB -= fee;
                require(rekt.transfer(DEAD, fee), "REKT TRANSFER FAILED");
            }
            rewardPerContribution = totalContributedTeamB * ACC_FACTOR / totalContributedTeamA;
        } else {
            uint256 fee = totalContributedTeamA * serviceFee / 100;
            if (fee > 0) {
                totalContributedTeamA -= fee;
                require(rekt.transfer(DEAD, fee), "REKT TRANSFER FAILED");
            }
            rewardPerContribution = totalContributedTeamA * ACC_FACTOR / totalContributedTeamB;
        }

        result = isTrue;
        isFinalized = true;
        emit SubmitResult(isTrue, block.timestamp);
    }

    function claimWin() external nonReentrant {
        require(block.timestamp >= eventEndTime, "EVENT TIME NOT ENDED");
        require(isFinalized, "NOT FINALIZED");

        UserData memory user = userContribution[_msgSender()];

        require(user.totalContributed > 0, "NO CONTRIBUTION");
        require(user.isTrue == checkResult(), "NOT IN WINNING TEAM");

        uint256 userReward = rewardPerContribution * user.totalContributed / ACC_FACTOR;
        uint256 totalReturnAmount = user.totalContributed +  userReward;

        emit ClaimReward(_msgSender(), user.totalContributed, userReward);
        delete userContribution[_msgSender()];

        require(rekt.transfer(_msgSender(), totalReturnAmount), "REKT TRANSFER FAILED");
    }

    function checkResult() public view returns (bool) {
        if (isFinalized) {
            return result;
        }
        revert("RESULT NOT SUBMITTED");
    }

    function changeDescription(string memory newDescription) external onlyOwner {
        require(contributionStartTime == 0, "CANNOT CHANGE AFTER START");
        bytes memory _description = bytes(newDescription);
        require(_description.length > 0, "EMPTY STRING");

        description = newDescription;

        emit DescriptionUpdated(description);
    }

    function changeTax(uint8 newFee) external onlyOwner {
        require(contributionStartTime == 0, "CANNOT CHANGE AFTER START");
        require(newFee <= 10, "MORE THAN 10%");

        serviceFee = newFee;

        emit ServiceFeeUpdated(serviceFee);
    }

    function changeMinContribution(uint256 newMinContribution) external onlyOwner {
        minContribution = newMinContribution;
        emit MinContributionUpdated(minContribution);
    }

    function viewContractData() external view returns (ContractData memory) {
        return(ContractData(
            contributionStartTime,
            contributionEndTime,
            eventEndTime,
            totalContributedTeamA,
            totalUsersA,
            totalContributedTeamB,
            totalUsersB,
            serviceFee,
            isFinalized
        ));
    }
}