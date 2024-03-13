// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.19;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.19;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

//  _________  ________  ________  ________  ___  ___  _______
// |\___   ___\\   __  \|\   __  \|\   __  \|\  \|\  \|\  ___ \
// \|___ \  \_\ \  \|\  \ \  \|\  \ \  \|\  \ \  \\\  \ \   __/|
//     \ \  \ \ \  \\\  \ \   _  _\ \  \\\  \ \  \\\  \ \  \_|/__
//      \ \  \ \ \  \\\  \ \  \\  \\ \  \\\  \ \  \\\  \ \  \_|\ \
//       \ \__\ \ \_______\ \__\\ _\\ \_____  \ \_______\ \_______\
//        \|__|  \|_______|\|__|\|__|\|___| \__\|_______|\|_______|

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardUtil is ReentrancyGuard, Ownable { 
    using SafeMath for uint256;

    struct RewardConfig {
        uint256 rewardFactor;
        uint256 torquePool;
        uint256 borrowFactor; 
    }

    struct UserRewardConfig {
        uint256 rewardAmount;
        uint256 depositAmount;
        uint256 borrowAmount;
        uint256 lastRewardBlock;
        bool isActive;
    }

    IERC20 public torqToken;
    address public governor;
    bool public claimsPaused = false;

    mapping(address => bool) public isTorqueContract;
    mapping(address => RewardConfig) public rewardConfig;
    mapping(address => mapping(address => UserRewardConfig)) public rewardsClaimed;


    event GovernorTransferred(address indexed oldGovernor, address indexed newGovernor);
    event RewardClaimed(address indexed user, address indexed torqueContract, uint256 amount);
    event RewardFactorUpdated(address indexed torqueContract, uint256 rewardFactor);
    event BorrowFactorUpdated(address indexed torqueContract, uint256 borrowFactor);
    event TorquePoolUpdated(address torqueContract,uint256 _poolAmount);
    event TorqueContractAdded(address torqueContract,uint256 _poolAmount, uint256 rewardFactor, uint256 borrowFactor);

    error NotPermitted(address);
    error InvalidTorqueContract(address);

    constructor(address _torqTokenAddress, address _governor) Ownable(msg.sender) {
        require(_torqTokenAddress != address(0), "Invalid TORQ token address");
        torqToken = IERC20(_torqTokenAddress);
        governor = _governor;
    }

    modifier onlyGovernor() {
        if (msg.sender != governor) revert NotPermitted(msg.sender);
        _;
    }

    function userDepositReward(address _userAddress, uint256 _depositAmount) external {
        require(isTorqueContract[msg.sender], "Unauthorised!");
        updateReward(msg.sender, _userAddress);
        rewardsClaimed[msg.sender][_userAddress].depositAmount = rewardsClaimed[msg.sender][_userAddress].depositAmount.add(_depositAmount);
        rewardsClaimed[msg.sender][_userAddress].lastRewardBlock = block.number;
        rewardsClaimed[msg.sender][_userAddress].isActive = true;
    }

    function userDepositBorrowReward(address _userAddress, uint256 _borrowAmount) external {
        require(isTorqueContract[msg.sender], "Unauthorised!");
        updateReward(msg.sender, _userAddress);
        rewardsClaimed[msg.sender][_userAddress].borrowAmount = rewardsClaimed[msg.sender][_userAddress].borrowAmount.add(_borrowAmount);
        rewardsClaimed[msg.sender][_userAddress].lastRewardBlock = block.number;
        rewardsClaimed[msg.sender][_userAddress].isActive = true;
    }

    function userWithdrawReward(address _userAddress, uint256 _withdrawAmount) external {
        require(isTorqueContract[msg.sender], "Unauthorised!");
        require(_withdrawAmount <= rewardsClaimed[msg.sender][_userAddress].depositAmount, "Cannot withdraw more than deposit!");
        updateReward(msg.sender, _userAddress);
        rewardsClaimed[msg.sender][_userAddress].depositAmount = rewardsClaimed[msg.sender][_userAddress].depositAmount.sub(_withdrawAmount);
        if(rewardsClaimed[msg.sender][_userAddress].depositAmount == 0 && rewardsClaimed[msg.sender][_userAddress].borrowAmount == 0){
            rewardsClaimed[msg.sender][_userAddress].isActive = false;
        }
    }

    function userWithdrawBorrowReward(address _userAddress, uint256 _withdrawBorrowAmount) external {
        require(isTorqueContract[msg.sender], "Unauthorised!");
        require(_withdrawBorrowAmount <= rewardsClaimed[msg.sender][_userAddress].borrowAmount, "Cannot withdraw more than deposit!");
        updateReward(msg.sender, _userAddress);
        rewardsClaimed[msg.sender][_userAddress].borrowAmount = rewardsClaimed[msg.sender][_userAddress].borrowAmount.sub(_withdrawBorrowAmount);
        if(rewardsClaimed[msg.sender][_userAddress].depositAmount == 0 && rewardsClaimed[msg.sender][_userAddress].borrowAmount == 0){
            rewardsClaimed[msg.sender][_userAddress].isActive = false;
        }
    }

    function setrewardFactor(address torqueContract, uint256 _rewardFactor) public onlyGovernor() {
        rewardConfig[torqueContract].rewardFactor = _rewardFactor;
        emit RewardFactorUpdated(torqueContract, _rewardFactor);
    }

    function setTorquePool(address _torqueContract, uint256 _poolAmount) public onlyGovernor() {
        rewardConfig[_torqueContract].torquePool = _poolAmount;
        emit TorquePoolUpdated(_torqueContract, _poolAmount);
    }

    function setBorrowFactor(address _torqueContract, uint256 _borrowFactor) public onlyGovernor() {
        rewardConfig[_torqueContract].borrowFactor = _borrowFactor;
        emit BorrowFactorUpdated(_torqueContract, _borrowFactor);
    }

    function updateReward(address torqueContract, address user) internal nonReentrant {
        _calculateAndUpdateReward(torqueContract, user);
    }

    function updateTorqueToken(address _torqueToken) external onlyGovernor() {
        torqToken = IERC20(_torqueToken);
    }

    function addTorqueContract(address _address, uint256 _rewardPool, uint256 _rewardFactor, uint256 _borrowFactor) public onlyOwner {
        if (_rewardFactor == 0) {
            revert InvalidTorqueContract(_address);
        }
        isTorqueContract[_address] = true;
        rewardConfig[_address].rewardFactor = _rewardFactor;
        rewardConfig[_address].borrowFactor = _borrowFactor;
        rewardConfig[_address].torquePool = _rewardPool;

        emit TorqueContractAdded(_address, _rewardPool, _rewardFactor, _borrowFactor);
    }

    function _calculateAndUpdateBorrowReward(address _torqueContract, address _userAddress) internal {
        uint256 blocks = block.number - rewardsClaimed[_torqueContract][_userAddress].lastRewardBlock;
        uint256 userReward = blocks.mul(rewardsClaimed[_torqueContract][_userAddress].borrowAmount);
        userReward = userReward.mul(rewardConfig[_torqueContract].torquePool);
        userReward = userReward.div(rewardConfig[_torqueContract].borrowFactor);
        rewardsClaimed[_torqueContract][_userAddress].rewardAmount = rewardsClaimed[_torqueContract][_userAddress].rewardAmount.add(userReward);
    }

    function _calculateAndUpdateReward(address _torqueContract, address _userAddress) internal {
        if(!rewardsClaimed[_torqueContract][_userAddress].isActive){
            return;
        }
        uint256 blocks = block.number - rewardsClaimed[_torqueContract][_userAddress].lastRewardBlock;
        uint256 userReward = blocks.mul(rewardsClaimed[_torqueContract][_userAddress].depositAmount);
        userReward = userReward.mul(rewardConfig[_torqueContract].torquePool);
        userReward = userReward.div(rewardConfig[_torqueContract].rewardFactor);
        if(rewardConfig[_torqueContract].borrowFactor > 0 && rewardsClaimed[_torqueContract][_userAddress].borrowAmount > 0){
            _calculateAndUpdateBorrowReward(_torqueContract, _userAddress);
        }
        rewardsClaimed[_torqueContract][_userAddress].lastRewardBlock = block.number;
        rewardsClaimed[_torqueContract][_userAddress].rewardAmount = rewardsClaimed[_torqueContract][_userAddress].rewardAmount.add(userReward);
    }

    function _calculateBorrowReward(address _torqueContract, address _userAddress) internal view returns (uint256) {
        uint256 blocks = block.number - rewardsClaimed[_torqueContract][_userAddress].lastRewardBlock;
        uint256 userReward = blocks.mul(rewardsClaimed[_torqueContract][_userAddress].borrowAmount);
        userReward = userReward.mul(rewardConfig[_torqueContract].torquePool);
        userReward = userReward.div(rewardConfig[_torqueContract].borrowFactor);
        return userReward;
    }

    function _calculateReward(address _torqueContract, address _userAddress) public view returns (uint256) {
        uint256 blocks = block.number - rewardsClaimed[_torqueContract][_userAddress].lastRewardBlock;
        uint256 userReward = blocks.mul(rewardsClaimed[_torqueContract][_userAddress].depositAmount); 
        userReward = userReward.mul(rewardConfig[_torqueContract].torquePool);
        userReward = userReward.div(rewardConfig[_torqueContract].rewardFactor);
        uint256 borrowReward;
        if(rewardConfig[_torqueContract].borrowFactor > 0 && rewardsClaimed[_torqueContract][_userAddress].borrowAmount > 0){
            borrowReward = _calculateBorrowReward(_torqueContract, _userAddress);
        }
        return borrowReward + userReward + rewardsClaimed[_torqueContract][_userAddress].rewardAmount;
    }

    function claimReward(address[] memory _torqueContract) external {
        require(!claimsPaused, "Claims are paused!");
        uint256 rewardAmount = 0;
        for(uint i=0;i<_torqueContract.length;i++){
            updateReward(_torqueContract[i], msg.sender);
            rewardAmount = rewardAmount.add(rewardsClaimed[_torqueContract[i]][msg.sender].rewardAmount);
            rewardsClaimed[_torqueContract[i]][msg.sender].rewardAmount = 0;
        }
        require(torqToken.balanceOf(address(this)) >= rewardAmount, "Insufficient TORQ");
        require(rewardAmount > 0 ,"No rewards found!");
        require(torqToken.transfer(msg.sender, rewardAmount), "Transfer Asset Failed");
    }

    function transferGovernor(address newGovernor) external onlyGovernor {
        address oldGovernor = governor;
        governor = newGovernor;
        emit GovernorTransferred(oldGovernor, newGovernor);
    }

    function pauseClaims(bool _pause) external onlyGovernor {
        claimsPaused = _pause;
    }

    function withdrawTorque(uint256 _amount) external onlyOwner() {
        require(torqToken.transfer(msg.sender, _amount), "Transfer Asset Failed");
    }

    function getRewardConfig(address _torqueContract, address _user) public view returns (UserRewardConfig memory){
        return rewardsClaimed[_torqueContract][_user];
    }
}