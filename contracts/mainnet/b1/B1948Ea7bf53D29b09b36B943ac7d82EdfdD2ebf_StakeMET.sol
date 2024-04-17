// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

//  _____ ______   _______  _________  ___  ________  ___  ___  ___       ________  ___  ___  ________      
// |\   _ \  _   \|\  ___ \|\___   ___\\  \|\   ____\|\  \|\  \|\  \     |\   __  \|\  \|\  \|\   ____\     
// \ \  \\\__\ \  \ \   __/\|___ \  \_\ \  \ \  \___|\ \  \\\  \ \  \    \ \  \|\  \ \  \\\  \ \  \___|_    
//  \ \  \\|__| \  \ \  \_|/__  \ \  \ \ \  \ \  \    \ \  \\\  \ \  \    \ \  \\\  \ \  \\\  \ \_____  \   
//   \ \  \    \ \  \ \  \_|\ \  \ \  \ \ \  \ \  \____\ \  \\\  \ \  \____\ \  \\\  \ \  \\\  \|____|\  \  
//    \ \__\    \ \__\ \_______\  \ \__\ \ \__\ \_______\ \_______\ \_______\ \_______\ \_______\____\_\  \ 
//     \|__|     \|__|\|_______|   \|__|  \|__|\|_______|\|_______|\|_______|\|_______|\|_______|\_________\
//

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IMetPlus {
    function burn(uint256 _amount) external;
    function mint(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IMeticulous {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract StakeMET is Ownable, ReentrancyGuard {

    event Stake(uint256 amount, address owner, uint256 period, uint256 id);
    event UnStake(uint256 amount, address owner, uint256 id);

    IMeticulous public METaddress;
    IMetPlus public METPlusAddress;
    address public treasuryAddress = 0x696c2fEc3da1859f1675F638401a46ae4Ae12ae3;

    uint256 public defaultFee = 250;
    uint256 public totalMetStaked = 0;
    uint256 public totalInterestPaid = 0;
    uint256 public totalDefaultFee = 0;

    uint256 public day30Reward = 12;
    uint256 public day180Reward = 150;
    uint256 public day360Reward = 400;
    uint256 public day540Reward = 750;

    struct Locker {
        uint256 id;
        address owner;
        uint256 amount;
        uint256 timestamp;
        uint256 lockPeriod;
        bool isLocked;
    }

    uint256 private stakeId = 1;

    mapping(address => uint256[]) public getLockerList;
    mapping(uint256 => Locker) public getLocker;

    constructor(address metToken, address metPlusToken) Ownable(msg.sender) {
        METaddress = IMeticulous(metToken);
        METPlusAddress = IMetPlus(metPlusToken);
    }

    function stake(uint256 _amount, uint256 _period) external nonReentrant {
        require(_period == 30 days || _period == 180 days || _period == 360 days || _period == 540 days, "Invalid Time Period");
        require(METaddress.transferFrom(msg.sender, address(this), _amount));
        uint256 currentStakeId = stakeId;
        stakeId += 1;
        Locker memory locker = Locker(currentStakeId,msg.sender,_amount,block.timestamp, _period, true);
        getLocker[currentStakeId] = locker;
        getLockerList[msg.sender].push(currentStakeId);
        require(METPlusAddress.mint(msg.sender,_amount), "MET+ Mint Failed!");
        totalMetStaked += _amount;
        emit Stake(_amount, msg.sender, _period, currentStakeId);
    }

    function unStake(uint256 _stakeId) external nonReentrant {
        Locker memory locker = getLocker[_stakeId];
        require(locker.isLocked, "Tokens not staked");
        require(locker.owner == msg.sender, "You are not the owner");
        
        require(METPlusAddress.transferFrom(msg.sender, address(this), locker.amount), "Transfer of MET+ Failed");
        METPlusAddress.burn(locker.amount);
        
        locker.isLocked = false;
        getLocker[_stakeId] = locker;
        
        if(locker.lockPeriod + locker.timestamp <= block.timestamp) {
            uint256 interestAmount = calculateInterest(locker.amount, locker.lockPeriod);
            uint256 totalAmount = locker.amount + interestAmount;
            totalInterestPaid += interestAmount;
            require(METaddress.transfer(msg.sender, totalAmount), "Unstaking Failed!");
        }
        else {
            uint256 deductedAmount = locker.amount*(1000 - defaultFee)/1000;
            totalDefaultFee += locker.amount*defaultFee/1000;
            require(METaddress.transfer(treasuryAddress, locker.amount*defaultFee/1000), "Default fee to treasury failed!");
            require(METaddress.transfer(msg.sender, deductedAmount), "Unstaking Failed!");
        }
        totalMetStaked -= locker.amount;
        emit UnStake(locker.amount, msg.sender, locker.id);
    }

    function calculateInterest(uint256 _amount, uint256 _period) public view returns(uint256){
        if(_period == 30 days){
            return _amount*day30Reward/1000;
        }
        else if(_period == 180 days){
            return _amount*day180Reward/1000;
        }
        else if(_period == 360 days){
            return _amount*day360Reward/1000;
        }
        else if(_period == 540 days){
            return _amount*day540Reward/1000;
        }
        return 0;
    }

    function updateRewards(uint256 _day30, uint256 _day180, uint256 _day360, uint256 _day540) external onlyOwner {
        day30Reward = _day30;
        day180Reward = _day180;
        day360Reward = _day360;
        day540Reward = _day540;
    }

    function updateDefaultFee(uint256 _defaultFee) external onlyOwner {
        defaultFee = _defaultFee;
    }

    function isLockPeriodOver(uint256 _stakeId) public view returns (bool) {
        Locker memory locker = getLocker[_stakeId];
        if(locker.lockPeriod + locker.timestamp <= block.timestamp) {
            return true;
        }
        return false;
    }

    function updateTreasuryAddress(address _treasury) external onlyOwner {
        treasuryAddress = _treasury;
    }

}