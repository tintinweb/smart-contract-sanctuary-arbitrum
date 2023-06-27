/**
 *Submitted for verification at Arbiscan on 2023-06-27
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
    mapping(address => address[]) public referrals; 
    mapping(address => uint256) public totalRewards; 

    struct User {
        uint256 deposit;
        uint256 startMining;
        address referrer;
    }

    uint256 public MIN_DEPOSIT = 10000000; // represents 10 USDT
    uint256 public MAX_DEPOSIT = 300000000; // represents 300 USDT
    uint16 public MINE_RATE = 2; 
    uint256 public MINE_PERIOD = 14 days;
    uint16 public LAYER = 5;
    mapping(address => uint256) public lastMineTime;
    mapping(address => uint256) public minedAmount;

    function updateVal(uint16 a, uint16 b, uint256 c, uint256 d, uint256 e) external onlyOwner {
        MINE_RATE = a;
        LAYER = b;
        MIN_DEPOSIT = c;
        MAX_DEPOSIT = d;
        MINE_PERIOD = e;
    }

    function setUSDT(address _usdt) public onlyOwner {
        usdt = IERC20(_usdt);
    }

    function _addAddressToArray(address[] memory _arr, address _addr) internal pure returns(address[] memory) {
        address[] memory newArray = new address[](_arr.length + 1);
        for (uint i = 0; i < _arr.length; i++) {
            newArray[i] = _arr[i];
        }
        newArray[_arr.length] = _addr;
        return newArray;
    }

    function _mergeArrays(address[] memory _arr1, address[] memory _arr2) internal pure returns(address[] memory) {
        address[] memory newArray = new address[](_arr1.length + _arr2.length);
        uint counter = 0;
        for (uint i = 0; i < _arr1.length; i++) {
            newArray[counter] = _arr1[i];
            counter++;
        }
        for (uint i = 0; i < _arr2.length; i++) {
            newArray[counter] = _arr2[i];
            counter++;
        }
        return newArray;
    }

    function getAllDownlines(address _addr) public view returns(address[] memory) {
        address[] memory result = new address[](0);
        address[] memory level = referrals[_addr];
        for (uint i = 0; i < 5; i++) {
            address[] memory nextLevel = new address[](0);
            for (uint j = 0; j < level.length; j++) {
                result = _addAddressToArray(result, level[j]);
                nextLevel = _mergeArrays(nextLevel, referrals[level[j]]);
            }
            level = nextLevel;
        }
        
        return result;
    }

    function deposit(uint256 amount, address referrer) public {
        require(amount >= MIN_DEPOSIT && amount <= MAX_DEPOSIT, "Deposit amount out of range");
        require(users[msg.sender].deposit == 0, "Already mining");
        require(referrer != msg.sender, "Referrer cannot be yourself");
        // require(bytes(users[msg.sender]).length == 0, "Please use another account");
        usdt.transferFrom(msg.sender, address(this), amount);
        users[msg.sender] = User(amount, block.timestamp, referrer);
        uList.push(msg.sender);
        referrals[referrer].push(msg.sender);
    }

    function withdraw() public {
        require(users[msg.sender].deposit > 0, "Not mining");
        require(block.timestamp >= users[msg.sender].startMining + MINE_PERIOD, "Mining period not over");
        uint256 amount = users[msg.sender].deposit;
        users[msg.sender].deposit = 0;
        usdt.transfer(msg.sender, amount);
    }

    function claimReward() public {
        uint256 totalReward = 0;
        address[] memory AllDownlines = getAllDownlines(msg.sender);
        for(uint i = 0; i < AllDownlines.length; i++) {
            totalReward += rewards[msg.sender][AllDownlines[i]];
            rewards[msg.sender][AllDownlines[i]] = 0;
        }
        totalReward += minedAmount[msg.sender];
        require(totalReward > 0, "No rewards");
        totalRewards[msg.sender] = 0; // Reset the total rewards to 0
        minedAmount[msg.sender] = 0;
        usdt.transfer(msg.sender, totalReward);
    }

    function mine(uint i, User memory user, uint256 reward) internal {
        if (user.referrer != address(0)) {
            rewards[user.referrer][msg.sender] += (6**i * reward) / 10**i;
        }
    }

    function processMining() public {
        address userAddress = msg.sender;
        User memory my = users[userAddress];
        require(block.timestamp >= lastMineTime[msg.sender] + 1 days, "Can only mine once per day");
        require(minedAmount[msg.sender] < my.deposit * MINE_RATE / 100 * MINE_PERIOD, "Maximum mine amount reached");
        uint256 reward = my.deposit * MINE_RATE / 100;
        minedAmount[msg.sender] += reward;
        lastMineTime[msg.sender] = block.timestamp;
        
        for (uint i = 1; i <= LAYER; i++) {
            if (userAddress == address(0)) {
                break;
            }
            User memory user = users[userAddress];
            if (block.timestamp < user.startMining + MINE_PERIOD) {
                mine(i, user, reward);
            }
            userAddress = users[userAddress].referrer;
        }
    }

}