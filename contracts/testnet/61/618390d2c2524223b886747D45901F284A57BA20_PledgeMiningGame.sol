/**
 *Submitted for verification at Arbiscan on 2023-06-25
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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

    function getUserInfo(address userAddress) external view returns (uint256, uint256,uint256, uint256);
    function changePro(address userAddress, uint256 amount, bool increase) external returns (uint256, uint256);
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


// File contracts/PledgeMiningGame.sol


pragma solidity ^0.8.0;


contract PledgeMiningGame is Ownable {
    IERC20 public usdt;
    mapping(address => User) public users;
    mapping(address => mapping(address => uint256)) public rewards;
    address[] public uList;

    struct User {
        uint256 deposit;
        uint256 startMining;
        address referrer;
    }

    uint256 public MIN_DEPOSIT = 10000000; // represents 50 USDT
    uint256 public MAX_DEPOSIT = 300000000; // represents 300 USDT
    uint256 constant MINE_RATE = 2; // represents 2%
    uint256 constant MINE_PERIOD = 14 days;
    mapping(address => uint256) public lastMineTime;
    mapping(address => uint256) public minedAmount;

    function setMinDeposit(uint256 _minDeposit, uint256 _maxDeposit) public onlyOwner {
        MIN_DEPOSIT = _minDeposit;
        MAX_DEPOSIT = _maxDeposit;

    }
    
    function setUSDT(address _usdt) public onlyOwner {
        usdt = IERC20(_usdt);
    }

    function deposit(uint256 amount, address referrer) public {
        require(amount >= MIN_DEPOSIT && amount <= MAX_DEPOSIT, "Deposit amount out of range");
        require(users[msg.sender].deposit == 0, "Already mining");
        require(referrer != msg.sender, "Referrer cannot be yourself");
        // require(bytes(users[msg.sender]).length == 0, "Please use another account");
        usdt.transferFrom(msg.sender, address(this), amount);
        users[msg.sender] = User(amount, block.timestamp, referrer);
        uList.push(msg.sender);
    }

    function withdraw() public {
        require(users[msg.sender].deposit > 0, "Not mining");
        require(block.timestamp >= users[msg.sender].startMining + MINE_PERIOD, "Mining period not over");

        uint256 amount = users[msg.sender].deposit;
        users[msg.sender].deposit = 0;

        usdt.transfer(msg.sender, amount);
    }

    function claimReward() public {
        uint256 reward = rewards[msg.sender][users[msg.sender].referrer];
        require(reward > 0, "No rewards");

        rewards[msg.sender][users[msg.sender].referrer] = 0;

        usdt.transfer(msg.sender, reward);
    }

    function mine(User memory user) internal {
        require(block.timestamp >= lastMineTime[msg.sender] + 1 days, "Can only mine once per day");
        require(minedAmount[msg.sender] < user.deposit * MINE_RATE / 100 * MINE_PERIOD, "Maximum mine amount reached");
        uint256 reward = user.deposit * MINE_RATE / 100;
        minedAmount[msg.sender] += reward;
        lastMineTime[msg.sender] = block.timestamp;

        rewards[user.referrer][msg.sender] += reward;

        address referrer = users[user.referrer].referrer;
        if (referrer != address(0)) {
            rewards[referrer][user.referrer] += reward * 6 / 10;
        }
    }

    function processMining() public {
        for (address userAddress = msg.sender; userAddress != address(0); userAddress = users[userAddress].referrer) {
            User memory user = users[userAddress];
            if (block.timestamp < user.startMining + MINE_PERIOD) {
                mine(user);
            }
        }
    }
}