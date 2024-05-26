// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingContract is Ownable {
    enum AssetType { BTC, USDT, USDC }
    
    struct Stake {
        AssetType assetType;
        uint256 amount;
        uint256 timestamp;
        bool withdrawn; 
        uint256 withdraw_timestamp;
    }
    
    mapping(address => Stake[]) private stakes;
    mapping(AssetType => uint256) public totalStaked;
    IERC20 private usdtToken;
    IERC20 private usdcToken;

    bool public isStakingActive = false;
    bool public isDeadlineSetted = false;
    bool public isStakingEnded = false;
    uint256 public deadline;

    // Events
    event Staked(address indexed user, AssetType assetType, uint256 amount);
    event Withdrawn(address indexed user, AssetType assetType, uint256 amount);
    event StakingActivityChanged(bool newStatus);
    event DeadlineSet(uint256 time);

    constructor(address _usdtTokenAddress,address _usdcTokenAddress, address _owner) Ownable(_owner) {
        usdtToken = IERC20(_usdtTokenAddress);
        usdcToken = IERC20(_usdcTokenAddress);
    }

    function setStakingActive(bool _isActive) external onlyOwner {
        isStakingActive = _isActive;
        emit StakingActivityChanged(_isActive);
    }
 
    function setDeadline(uint256 _time) external onlyOwner {
        require(!isDeadlineSetted,"Stake Deadline is setted already, can not set again.");
        deadline = _time;
        isDeadlineSetted = true;
        emit DeadlineSet(_time);
    }

    function stakeBTC() external payable {
        require(isStakingActive, "Staking is not active");
        require(msg.value > 0, "You need to stake some BTC");
        require(block.timestamp <= deadline, "Staking period has ended");

        totalStaked[AssetType.BTC] += msg.value;
        
        stakes[msg.sender].push(Stake({
            assetType: AssetType.BTC,
            amount: msg.value,
            timestamp: block.timestamp,
            withdrawn: false,
            withdraw_timestamp: 0
        }));
        
        updateEndCountdown();
        emit Staked(msg.sender, AssetType.BTC, msg.value);
    }

    function stakeUSDT(uint256 _amount) external {
        require(isStakingActive, "Staking is not active");
        require(_amount > 0, "You need to stake some USDT");
        require(block.timestamp <= deadline, "Staking period has ended");

        totalStaked[AssetType.USDT] += _amount;
        
        stakes[msg.sender].push(Stake({
            assetType: AssetType.USDT,
            amount: _amount,
            timestamp: block.timestamp,
            withdrawn: false,
            withdraw_timestamp: 0
        }));
        
        require(usdtToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        updateEndCountdown();
        emit Staked(msg.sender, AssetType.USDT, _amount);
    }
    
    function stakeUSDC(uint256 _amount) external {
        require(isStakingActive, "Staking is not active");
        require(_amount > 0, "You need to stake some USDT");
        require(block.timestamp <= deadline, "Staking period has ended");

        totalStaked[AssetType.USDT] += _amount;
        
        stakes[msg.sender].push(Stake({
            assetType: AssetType.USDC,
            amount: _amount,
            timestamp: block.timestamp,
            withdrawn: false,
            withdraw_timestamp: 0
        }));
        
        require(usdtToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        updateEndCountdown();
        emit Staked(msg.sender, AssetType.USDC, _amount);
    }

    function withdrawAllStakes(AssetType _assetType) external {
         require(isStakingEnded == true, "Staking is not end yet.");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < stakes[msg.sender].length; i++) {
            Stake storage stake = stakes[msg.sender][i];
            if(stake.assetType == _assetType && !stake.withdrawn){
                totalAmount += stake.amount;
                stake.withdrawn = true; 
                stake.withdraw_timestamp = block.timestamp;
            }
        }

        require(totalAmount > 0, "No assets to withdraw");
        totalStaked[_assetType] -= totalAmount;

        if(_assetType == AssetType.BTC) {
            payable(msg.sender).transfer(totalAmount);
        } 
        else if(_assetType == AssetType.USDT) {
            require(usdtToken.transfer(msg.sender, totalAmount), "Transfer failed");
        }
        else if(_assetType == AssetType.USDC) {
            require(usdcToken.transfer(msg.sender, totalAmount), "Transfer failed");
        }

        emit Withdrawn(msg.sender, _assetType, totalAmount);
    }

    function getUserTotalStaked(address _user) external view returns (uint256 totalBTC, uint256 totalUSDT, uint256 totalUSDC) {
        uint256 btcTotal = 0;
        uint256 usdtTotal = 0;
        uint256 usdcTotal = 0;

         for (uint256 i = 0; i < stakes[_user].length; i++) {
            Stake memory stake = stakes[_user][i];
            if (!stake.withdrawn) { 
                if (stake.assetType == AssetType.BTC) {
                    btcTotal += stake.amount;
                } else if (stake.assetType == AssetType.USDT) {
                    usdtTotal += stake.amount;
                } else if (stake.assetType == AssetType.USDC) {
                    usdcTotal += stake.amount;
                }
            }
        }

        return (btcTotal, usdtTotal, usdtTotal);
    }
    

    function viewStakes(address _user) external view returns (Stake[] memory) {
        return stakes[_user];
    }

    function viewTotalStaked() external view returns (uint256 btcTotal, uint256 usdtTotal, uint256 usdcTotal) {
        return (totalStaked[AssetType.BTC], totalStaked[AssetType.USDT], totalStaked[AssetType.USDC]);
    }

    function getDeadline() external view returns (uint256) {
        return deadline;
    }

    function updateEndCountdown() private {
        if (block.timestamp > deadline) {
            isStakingActive = false;
            isStakingEnded = true;
        }
    }
}

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