/**
 *Submitted for verification at Arbiscan on 2023-05-04
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: src/migration.sol



pragma solidity ^0.8.9;
pragma abicoder v2;



// File: data.sol
interface Staking {
    struct UserInfo {
        uint256 vote;
        uint256 amount;
        uint256 rewardDebt;
        uint256 xGNDrewardDebt;
    }

    function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);
    function pendingGND(uint256 _pid, address _user) external view returns (uint256);
    function pendingxGND(uint256 _pid, address _user) external view returns (uint256);
}

contract Data is Ownable {
    Staking public stake;

    constructor(address _stakingAddress) {
        stake = Staking(_stakingAddress);
    }

    function getUserStaked(address _user, uint256 _pid) external view returns (uint256) {
        return stake.userInfo(_pid, _user).amount;
    }

    function updateStake(address _stakingAddress) external onlyOwner {
        stake = Staking(_stakingAddress);
    }
}

// File: migration.sol
contract Migration is Ownable {
    Data public dataContract;
    mapping(uint256 => address) public pidToMigrateToken;
    mapping(address => bool) public hasMigrated;

    IERC20 public GNDToken;
    IERC20 public xGNDToken;
    Staking public stake;

    constructor(Data _dataContract, IERC20 _GNDToken, IERC20 _xGNDToken, Staking _stake) {
        dataContract = _dataContract;
        stake =  _stake;
        GNDToken = _GNDToken;
        xGNDToken = _xGNDToken;
    }

    function getgndpending(address _user, uint256 _pid) external view returns (uint256) {
        return stake.pendingGND(_pid, _user);
    }
    
    function getxgndpending(address _user, uint256 _pid) external view returns (uint256) {
        return stake.pendingxGND(_pid, _user);
    }


    function migrate(uint256[] calldata pids) external {
        require(!hasMigrated[msg.sender], "User has already migrated");

        for (uint256 i = 0; i < pids.length; i++) {
            _migrateSinglePid(msg.sender, pids[i]);
        }

        hasMigrated[msg.sender] = true;
    }

    function migrateSinglePid(uint256 pid) external {
        require(!hasMigrated[msg.sender], "User has already migrated");

        _migrateSinglePid(msg.sender, pid);

        hasMigrated[msg.sender] = true;
    }

    function _migrateSinglePid(address user, uint256 pid) internal {
        require(pid != 0 && pid != 1 && pid != 2 && pid != 4 && pid != 12 && pid != 15, "Invalid pid");
        uint256 pendingGNDAmount;
        uint256 pendingxGNDAmount;
        uint256 stakedAmount = dataContract.getUserStaked(user, pid);
     
        if (pid == 16){
            pendingGNDAmount = stakedAmount*5e18/6605e18;
            pendingGNDAmount = stakedAmount*5e18/6605e18;
        }
        else {
            pendingGNDAmount = stake.pendingGND(pid, user);
            pendingxGNDAmount = stake.pendingxGND(pid, user);
        }
        

        if (stakedAmount > 0) {
            IERC20 token = IERC20(pidToMigrateToken[pid]);
            token.transfer(user, stakedAmount);
        }

        if (pendingGNDAmount > 0) {
            GNDToken.transfer(user, pendingGNDAmount);
        }

        if (pendingxGNDAmount > 0) {
            xGNDToken.transfer(user, pendingxGNDAmount);
        }
    }
    function updateDataContract(Data _dataContract) external onlyOwner {
        dataContract = _dataContract;
    }   
     function updateStakeContract(Staking _stakeContract) external onlyOwner {
        stake = _stakeContract;
    }

    function recoverToken(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to recover");
        token.transfer(msg.sender, balance);
    }
   
}