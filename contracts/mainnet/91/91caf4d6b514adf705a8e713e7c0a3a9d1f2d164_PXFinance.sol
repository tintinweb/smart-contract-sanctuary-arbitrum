/**
 *Submitted for verification at Arbiscan.io on 2023-11-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
pragma experimental ABIEncoderV2;

/*
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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract PXFinance is Ownable {
    using SafeMath for uint256;

    uint256 public minBuyAmount = 268 * 10**18;
    uint256 public returnRate = 0 * 10**18;

    uint256 public poolRate = 130 * 10**18;
    // 给上级邀请返利的百分比
    uint256 public inviteRate = 25 * 10**18;

    uint256 public userPoolV1Rate = 25 * 10**18;
    uint256 public userPoolV2Rate = 25 * 10**18;
    uint256 public userPoolV3Rate = 15 * 10**18;
    uint256 public userPoolV4Rate = 10 * 10**18;

    uint256 public nodeRate = 25 * 10**18;
    uint256 public shequRate = 8 * 10**18;
    uint256 public huigouRate = 0 * 10**18;
    uint256 public yunyingRate = 5 * 10**18;

    // 用户底池
    address public userPoolAddressV1;
    address public userPoolAddressV2;
    address public userPoolAddressV3;
    address public userPoolAddressV4;

    address public nodeAddress;
    address public shequAddress;
    address public huigouAddress;
    address public yunyingAddress;
    address public poolAddress;

    IERC20 private immutable currency;

    function setinviteRate(uint256 _inviteRate) public onlyOwner {
        inviteRate = _inviteRate;
    }

    function setuserPoolRate(
        uint256 _userPoolV1Rate,
        uint256 _userPoolV2Rate,
        uint256 _userPoolV3Rate,
        uint256 _userPoolV4Rate
    ) public onlyOwner {
        userPoolV1Rate = _userPoolV1Rate;
        userPoolV2Rate = _userPoolV2Rate;
        userPoolV3Rate = _userPoolV3Rate;
        userPoolV4Rate = _userPoolV4Rate;
    }

    function setnodeRate(uint256 _nodeRate) public onlyOwner {
        nodeRate = _nodeRate;
    }

    function setshequRate(uint256 _shequRate) public onlyOwner {
        shequRate = _shequRate;
    }

    function setyunyingRate(uint256 _yunyingRate) public onlyOwner {
        yunyingRate = _yunyingRate;
    }

    function sethuigouRate(uint256 _huigouRate) public onlyOwner {
        huigouRate = _huigouRate;
    }

    function setpoolRate(uint256 _poolRate) public onlyOwner {
        poolRate = _poolRate;
    }

    struct UserInfo {
        bool inited;
        uint256 totalToken; // should have token balance
        uint256 totalBuyUSD;
        uint256 todayBuyToken; // today buy
        uint256 lastBuyDay; // buy time
        bool canInvite; // 是否可以邀请，购买社区和联盟后才可
        address referer; // 邀请者
        uint256 inviteCount; // 邀请数量
        uint256 rewardToken; // 邀请奖励
        uint256 rewardETH; // 邀请奖励BUY
        uint256 buyCount; // 购买次数
    }

    mapping(address => UserInfo) public userPool;

    address[] public buyUsers;

    struct RewardRecord {
        uint256 time;
        uint256 amount;
        address fromAddr;
    }
    struct BuyRecord {
        uint256 time;
        uint256 amount;
    }

    mapping(address => RewardRecord[]) public userRecords;
    mapping(address => BuyRecord[]) public buyRecords;

    event Deposit(address indexed user, address indexed referee, uint256 amount);

    constructor(
        IERC20 _currency,
        address _userPoolAddressV1,
        address _userPoolAddressV2,
        address _userPoolAddressV3,
        address _userPoolAddressV4,
        address _shequAddress,
        address _yunyingAddress,
        address _huigouAddress,
        address _poolAddress,
        address _nodeAddress
    ) {
        currency = _currency;

        userPoolAddressV1 = _userPoolAddressV1;
        userPoolAddressV2 = _userPoolAddressV2;
        userPoolAddressV3 = _userPoolAddressV3;
        userPoolAddressV4 = _userPoolAddressV4;

        shequAddress = _shequAddress;
        yunyingAddress = _yunyingAddress;
        huigouAddress = _huigouAddress;
        poolAddress = _poolAddress;
        nodeAddress = _nodeAddress;
    }

    function swapWithReferer(address _refer) public {
        require(_refer != address(0), "referee is zero");
        require(_refer != tx.origin, "referee is self");
        // require(_amount >= minBuyAmount, "amount is too low");
        uint256 _amount = minBuyAmount;
        UserInfo memory user = userPool[tx.origin];
        if (user.inited && user.referer != address(0)) {
            _refer = user.referer;
        }
        UserInfo memory refereeUser = userPool[_refer];

        if (!refereeUser.inited || !refereeUser.canInvite) {
            // 不返利
            swap();
        } else {
            // 返利
            uint256 usdtCount = _amount;
            require(currency.balanceOf(tx.origin) >= usdtCount, "usdt is not enough");
            require(currency.allowance(tx.origin, address(this)) >= usdtCount, "usdt allowance is not enough");

            // uint256 tokenAmount = usdtCount.mul(returnRate).div(100);
            uint256 tokenAmount = returnRate;
            // 给邀请者分钱
            // uint256 inviteUSD = usdtCount.mul(inviteRate).div(100);
            uint256 inviteUSD = inviteRate;
            

            // 记录返利
            _recordReward(_refer, inviteUSD);

            // 剩下的走正常逻辑
            _swap(tokenAmount, usdtCount, _refer);
            _record(tokenAmount, usdtCount);
            if (user.referer == address(0)) {
                userPool[tx.origin].referer = _refer;
                refereeUser.inviteCount += 1;
                refereeUser.rewardToken = refereeUser.rewardToken.add(inviteUSD);
                userPool[_refer] = refereeUser;
            } else {
                refereeUser.rewardToken = refereeUser.rewardToken.add(inviteUSD);
                userPool[_refer] = refereeUser;
            }
        }
    }

    // 散户交易的方法
    function swap() public {
        uint256 amount = minBuyAmount;
        require(currency.balanceOf(tx.origin) >= amount, "usdt is not enough");
        require(currency.allowance(tx.origin, address(this)) >= amount, "usdt allowance is not enough");
        // uint256 tokenAmount = amount.mul(returnRate).div(100);
        uint256 tokenAmount = returnRate;

        _swap(tokenAmount, amount, address(0));
        _record(tokenAmount, amount);
    }

    function _swap(
        uint256 tokenAmount,
        uint256 usdtCount,
        address _referer
    ) private {
        uint256 firstTokenAmount = tokenAmount;

        // uint256 tokenBalance = token.balanceOf(address(this));

        // 合约地址没有token了，需要充值
        // require(tokenBalance >= firstTokenAmount, "the token is not enough");
        // 本销售类型的token数量已不足
        // require(token.balanceOf(address(this)) >= tokenAmount, "token sold out");

        //  给各地址分成

        // uint256 poolAmount = usdtCount.mul(poolRate).div(100);
        uint256 poolAmount = poolRate;
        currency.transferFrom(tx.origin, poolAddress, poolAmount);

        // uint256 userPoolV1Amount = usdtCount.mul(userPoolV1Rate).div(200);
        uint256 userPoolV1Amount = userPoolV1Rate;
        currency.transferFrom(tx.origin, userPoolAddressV1, userPoolV1Amount);
        // uint256 userPoolV2Amount = usdtCount.mul(userPoolV2Rate).div(200);
        uint256 userPoolV2Amount = userPoolV2Rate;
        currency.transferFrom(tx.origin, userPoolAddressV2, userPoolV2Amount);
        // uint256 userPoolV3Amount = usdtCount.mul(userPoolV3Rate).div(200);
        uint256 userPoolV3Amount = userPoolV3Rate;
        currency.transferFrom(tx.origin, userPoolAddressV3, userPoolV3Amount);
        // uint256 userPoolV4Amount = usdtCount.mul(userPoolV4Rate).div(200);
        uint256 userPoolV4Amount = userPoolV4Rate;
        currency.transferFrom(tx.origin, userPoolAddressV4, userPoolV4Amount);

        // uint256 platformPoolAmount = usdtCount.mul(shequRate).div(200);
        uint256 platformPoolAmount = shequRate;
        currency.transferFrom(tx.origin, shequAddress, platformPoolAmount);

        // uint256 marketAmount = usdtCount.mul(huigouRate).div(200);
        uint256 marketAmount = huigouRate;
        currency.transferFrom(tx.origin, huigouAddress, marketAmount);

        // uint256 yunyingAmount = usdtCount.mul(yunyingRate).div(200);
        uint256 yunyingAmount = yunyingRate;
        currency.transferFrom(tx.origin, yunyingAddress, yunyingAmount);

        uint256 nodeAmount = nodeRate;
        currency.transferFrom(tx.origin, nodeAddress, nodeAmount);

        // uint256 inviteAmount = usdtCount.mul(inviteRate).div(200);
        uint256 inviteAmount = inviteRate;
        if (_referer != address(0)) {
            currency.transferFrom(tx.origin, _referer, inviteAmount);
        } else {
            currency.transferFrom(tx.origin, address(this), inviteAmount);
        }

        // 然后将第一批token转入发起账号
        // if (firstTokenAmount > 0) {
        //     token.transfer(tx.origin, firstTokenAmount);
        // }
    }

    function _record(uint256 tokenAmount, uint256 _usdAmount) private {
        // 记录散户购买记录
        UserInfo memory userInfo = userPool[tx.origin];
        uint256 day = block.timestamp / 60 / 60 / 24;
        if (!userInfo.inited) {
            userInfo.inited = true;
            userInfo.totalToken = tokenAmount;
            userInfo.totalBuyUSD = _usdAmount;
            userInfo.todayBuyToken = tokenAmount;
            userInfo.lastBuyDay = 0;
            userInfo.buyCount = 1;
            userInfo.canInvite = true;
        } else {
            userInfo.totalToken += tokenAmount;
            userInfo.totalBuyUSD += _usdAmount;
            uint256 lastDay = userInfo.lastBuyDay;
            if (day != lastDay) {
                // 新的一天，清空今日奖励
                userInfo.todayBuyToken = 0;
            }
            userInfo.todayBuyToken += tokenAmount;
            userInfo.lastBuyDay = day;
            userInfo.buyCount += 1;
            userInfo.canInvite = true;
        }

        userPool[tx.origin] = userInfo;
        buyUsers.push(tx.origin);
        // 记录购买记录
        BuyRecord memory buyRecord;
        buyRecord.time = block.timestamp;
        buyRecord.amount = tokenAmount;
        buyRecords[tx.origin].push(buyRecord);
    }

    function _recordReward(address _toaddr, uint256 _usdtAmount) private {
        RewardRecord memory record;
        record.time = block.timestamp;
        record.amount = _usdtAmount;
        record.fromAddr = tx.origin;
        userRecords[_toaddr].push(record);
    }

    function getUserRewardLogs(address _addr) public view returns (RewardRecord[] memory) {
        uint256 length = userRecords[_addr].length;
        RewardRecord[] memory _records = new RewardRecord[](length);

        for (uint256 i = 0; i < length; i++) {
            _records[i] = userRecords[_addr][i];
        }
        return _records;
    }

    function getUserBuyLogs(address _addr) public view returns (BuyRecord[] memory) {
        uint256 length = buyRecords[_addr].length;
        BuyRecord[] memory _records = new BuyRecord[](length);

        for (uint256 i = 0; i < length; i++) {
            _records[i] = buyRecords[_addr][i];
        }
        return _records;
    }

    function addUserPool(address _addr) public onlyOwner {
        UserInfo memory userInfo;
        userInfo.inited = true;
        userPool[_addr] = userInfo;
    }

    function setUserInfo(address[] memory addrs, UserInfo[] memory _userPool) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            userPool[addrs[i]] = _userPool[i];
        }
    }

    // 获取用户信息
    function getUserInfo(address _addr) public view returns (UserInfo memory) {
        return userPool[_addr];
    }

    // // 提取所有token到某个地址
    // function withdrawAllToken(address _addr) public onlyOwner {
    //     uint256 balancethis = token.balanceOf(address(this));
    //     if (balancethis > 0) {
    //         token.approve(address(this), balancethis);
    //         token.transferFrom(address(this), _addr, balancethis);
    //     }
    // }

    // function withdrawToken(address _addr, uint256 _amount) public onlyOwner {
    //     uint256 balancethis = token.balanceOf(address(this));
    //     if (balancethis > _amount) {
    //         token.approve(address(this), _amount);
    //         token.transferFrom(address(this), _addr, _amount);
    //     }
    // }

    function withdrawUSDT(address _addr, uint256 _amount) public onlyOwner {
        uint256 balancethis = currency.balanceOf(address(this));
        if (balancethis > _amount) {
            currency.approve(address(this), _amount);
            currency.transferFrom(address(this), _addr, _amount);
        }
    }

    function getAllBuyUsers() public view returns (address[] memory) {
        uint256 length = buyUsers.length;
        address[] memory _addrs = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            _addrs[i] = buyUsers[i];
        }
        return _addrs;
    }
}