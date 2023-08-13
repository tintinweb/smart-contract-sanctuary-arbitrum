/**
 *Submitted for verification at Arbiscan on 2023-08-09
*/

//SPDX-License-Identifier: Unlicensed
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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

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

library SafeMathInt {
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when multiplying INT256_MIN with -1
        // https://github.com/RequestNetwork/requestNetwork/issues/43
        require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));

        int256 c = a * b;
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing INT256_MIN by -1
        // https://github.com/RequestNetwork/requestNetwork/issues/43
        require(!(a == - 2**255 && b == -1) && (b > 0));

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

        return a - b;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

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

interface IRelation {
    function getInviter(address account) external returns(address);
    function getMyTeam(address account) external returns(address[] memory);
}

interface IStake {
    function grantInterest(address account, uint256 rewardAmount) external;
}

contract Auction is Ownable {
    using SafeMath for uint256;
    using Address for address;

    IERC20 public yfiiiToken;
    IERC20 public arbToken;
    address public nftAddress;
    address public stakeAddress;

    address public managerAddress;
    address public relationAddress;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public intervalTime = 10 minutes;  //days;

    uint256 public startGameRequiredAmount = 10 ** 16; 

    uint256 public winnerRewardAmount = 400 * 10 ** 18;
    uint256 public inviteRewardAmount = 50 * 10 ** 18;
    uint256 public nftRewardAmount = 25 * 10 ** 18;
    uint256 public managerRewardAmount = 25 * 10 ** 18;

    uint256 public periodId = 1;
    struct GAMEINFO {
        uint256 _periodId;
        uint8 _status; //1 start 2 over
        uint256 _value;
        uint256 _startTime;
        uint256 _lastTime;
        uint256 _residue;
        address _winners;
    }

    mapping (uint256 => GAMEINFO) public gameList;

    struct ATTENDINFO {
        uint256 _periodId;
        uint256 _amount;
        uint256 _lastAttTime;
        uint256 _startRewardTime;
        uint256 _times;
        uint256 _status; //1 lottery
        uint256 _isRedeem; // 1 redeem
    }
    mapping (address => mapping (uint256 => ATTENDINFO)) public accountAttendList;
    mapping (address => uint256[]) public accountAttendPeriods;

    mapping (uint256 => uint256[]) internal periodTakeList;
    mapping (uint256 => uint256[]) internal periodTakeTime;

    uint256 public limitLockTimes = 10 minutes; //10 days;
    uint256 preReleaseDeduct = 10; // 10%;
    uint256 rewardRate = 3472222222222; //0.3%
    uint256 deductBurnRate = 60; //60% burn
    uint256 deductFundRate = 40; //40%

    modifier checkGame() {
        GAMEINFO storage gameInfo = gameList[periodId];
        if (gameInfo._status == 1) {
            uint256 curIntvelTime = block.timestamp.sub(gameInfo._lastTime);
            if(gameInfo._residue <= curIntvelTime) {
                //end game
                gameInfo._status = 2;
                gameInfo._residue = 0;
                gameInfo._lastTime = block.timestamp;
                ATTENDINFO storage accAttInfo = accountAttendList[gameInfo._winners][periodId]; 
                accAttInfo._status = 1;
                accAttInfo._amount = accAttInfo._amount.div(2);
                if(gameInfo._winners != address(0)) {
                    lottery(gameInfo._winners);
                }
                periodId++;
                startGame();
            } else {
                gameInfo._residue -= curIntvelTime;
                gameInfo._lastTime = block.timestamp;
            }
        }
        _;
    }

    modifier onlyNFT() {
        require(msg.sender == nftAddress, "no permission");
        _;
    }

    constructor(
        address _yfiiiTokenAddress,
        address _arbTokenAddress,
        address _relationAddress,
        address _managerAddress,
        address _stakeAddress,
        address _nftAddress
    ) {
       yfiiiToken = IERC20(_yfiiiTokenAddress);
       arbToken = IERC20(_arbTokenAddress);
       relationAddress = _relationAddress;
       managerAddress = _managerAddress; 
       stakeAddress = _stakeAddress; 
       nftAddress = _nftAddress;
    }

    function setintervalTime(uint256 _intervalTime) external onlyOwner {
        intervalTime = _intervalTime;
    }

    function setRewardAmount(
        uint256 _managerRewardAmount,
        uint256 _winnerRewardAmount,
        uint256 _inviteRewardAmount,
        uint256 _nftRewardAmount
    ) external onlyOwner {
        managerRewardAmount = _managerRewardAmount;
        winnerRewardAmount = _winnerRewardAmount;
        inviteRewardAmount = _inviteRewardAmount;
        nftRewardAmount = _nftRewardAmount;
    }

    function beginGame() external onlyOwner {
        startGame();
    }

    function interest(address token, address account, uint256 amount) external onlyOwner {
        IERC20(token).approve(address(this), amount);
        IERC20(token).transferFrom(address(this), account, amount);
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }

    function setDeductRate(uint256 _deductBurnRate, uint256 _deductFundRate, uint256 _preReleaseDeduct) external onlyOwner {
        deductFundRate = _deductFundRate;
        deductBurnRate = _deductBurnRate;
        preReleaseDeduct = _preReleaseDeduct;
    }

    function setLimitLockTimes(uint256 _limitLockTimes) external onlyOwner {
        limitLockTimes = _limitLockTimes;
    }

    function setConfigAddress(
        address _yfiiiTokenAddress,
        address _arbTokenAddress,
        address _relationAddress,
        address _stakeAddress,
        address _managerAddress,
        address _nftAddress
    ) external onlyOwner {
        yfiiiToken = IERC20(_yfiiiTokenAddress);
        arbToken = IERC20(_arbTokenAddress);
        relationAddress = _relationAddress;
        managerAddress = _managerAddress; 

        stakeAddress = _stakeAddress; 
        nftAddress = _nftAddress;
    }

    function lottery(address winner) private {
        arbToken.transfer(winner, winnerRewardAmount);
        address inviter = winner;
        uint256 inviteReward = inviteRewardAmount.add(nftRewardAmount);
        for(uint256 i = 0; i < 2; i++) {
            address superior = IRelation(relationAddress).getInviter(inviter);
            if (superior == address(0)) {
                break ;
            }
            if(i == 0) {
                inviteReward -= inviteRewardAmount;
                arbToken.transfer(superior, inviteRewardAmount);
            } else {
                inviteReward -= nftRewardAmount;
                arbToken.transfer(superior, nftRewardAmount);
            }   
            inviter = superior;
        }
        arbToken.transfer(managerAddress, managerRewardAmount.add(inviteReward));
    }

    function attend() public checkGame {
        GAMEINFO storage gameInfo = gameList[periodId];
        if(gameInfo._value <= 0) {
            gameInfo._value = startGameRequiredAmount;
        } else {
            gameInfo._value = gameInfo._value.mul(2);
        }
        gameInfo._lastTime = block.timestamp;
        gameInfo._winners = msg.sender;
        ATTENDINFO storage tmpAtt = accountAttendList[msg.sender][periodId];
        tmpAtt._periodId = periodId;
        if(tmpAtt._amount <= 0) {
            accountAttendPeriods[msg.sender].push(periodId);
        }
        tmpAtt._amount += gameInfo._value;
        tmpAtt._times += 1;
        tmpAtt._lastAttTime = block.timestamp;
        tmpAtt._startRewardTime = gameInfo._startTime.add(intervalTime); 
        periodTakeTime[periodId].push(block.timestamp);
        periodTakeList[periodId].push(gameInfo._value);
        yfiiiToken.transferFrom(msg.sender, address(this), gameInfo._value);
    }

    function startGame() private {
        GAMEINFO storage gameInfo = gameList[periodId];
        if (gameInfo._status <= 0) {
            gameInfo._status = 1;
            gameInfo._periodId = periodId;
            gameInfo._value = 0;
            gameInfo._startTime = block.timestamp;
            gameInfo._lastTime = block.timestamp;
            gameInfo._residue = intervalTime;
        }
    }

    function redeem(uint256 _periodId) public {
        GAMEINFO storage gameInfo = gameList[_periodId];
        require(gameInfo._status == 2, "not finished");
        ATTENDINFO storage attendInfo = accountAttendList[msg.sender][_periodId];
        require(attendInfo._amount > 0 && attendInfo._isRedeem <= 0, "Not participating in the early stage");
        uint256 value;
        if( block.timestamp < attendInfo._lastAttTime.add(limitLockTimes)) {
            uint256 deductAmount = attendInfo._amount.mul(preReleaseDeduct).div(100);
            uint256 burnAmount;
            uint256 fundAmount;
            if (gameInfo._winners == msg.sender) {
                burnAmount = attendInfo._amount.mul(deductBurnRate).div(100);
                yfiiiToken.transfer(deadAddress, burnAmount);
                fundAmount = attendInfo._amount.mul(deductFundRate).div(100);
                yfiiiToken.transfer(managerAddress, fundAmount);
            }

            yfiiiToken.transfer(deadAddress, deductAmount);
            value = attendInfo._amount.sub(deductAmount);
        } else {
             value = attendInfo._amount;
        }
        attendInfo._isRedeem = 1;
        uint256 tmpEarn = attendInfo._amount.mul(rewardRate).mul(block.timestamp.sub(attendInfo._startRewardTime));
        uint256 stakeYfiiiBalance = yfiiiToken.balanceOf(stakeAddress);
        if(tmpEarn > 0 && stakeYfiiiBalance > tmpEarn.div(1e18)) {
            // yfiiiToken.transfer(msg.sender, tmpEarn.div(1e18));
            try IStake(stakeAddress).grantInterest(msg.sender, tmpEarn.div(1e18)) {} catch {}
        }
        yfiiiToken.transfer(msg.sender, value);
    }

    function getReward() public {
        uint256 len = accountAttendPeriods[msg.sender].length;
        uint256 totalEarn;
        for(uint256 i = 0; i <= len; i++) {
           ATTENDINFO memory tmpAtt = accountAttendList[msg.sender][accountAttendPeriods[msg.sender][i]];
           if(tmpAtt._isRedeem > 0) continue ;
           uint256 tmpEarn = tmpAtt._amount.mul(rewardRate).mul(block.timestamp.sub(tmpAtt._startRewardTime)); 
           tmpAtt._startRewardTime = block.timestamp;
           totalEarn +=  tmpEarn;
        }
        if(totalEarn > 0) {
            yfiiiToken.transfer(msg.sender, totalEarn.div(1e18));
        }
    }

    function getRewardByPeridoId(uint256 _periodId) public {
        ATTENDINFO memory accInfo = accountAttendList[msg.sender][_periodId];
        require(accInfo._isRedeem <= 0, "Redemption in this period");
        
        uint256 tmpEarn = accInfo._amount.mul(rewardRate).mul(block.timestamp.sub(accInfo._startRewardTime));
        if(tmpEarn > 0) {
            accInfo._startRewardTime = block.timestamp;
            yfiiiToken.transfer(msg.sender, tmpEarn.div(1e18));
        }
    }

    function grantReward(address account, uint256 amount) external onlyNFT {
        if(amount > 0 && arbToken.balanceOf(address(this)) > amount) {
            arbToken.transfer(account, amount);
        }
    }

    function getAccountAttend(address account) public view returns(ATTENDINFO[] memory) {
        uint256 len = accountAttendPeriods[account].length;
        ATTENDINFO[] memory tmpAttArr = new ATTENDINFO[](len);
        for(uint256 i = 0; i < len; i++) {
           if(accountAttendList[account][accountAttendPeriods[account][i]]._amount <= 0) continue ;  
           tmpAttArr[i] =  accountAttendList[account][accountAttendPeriods[account][i]];
        }
        return tmpAttArr;
    }

    function earnByPeriodId(address account, uint256 _periodId) public view returns(uint256) {
        ATTENDINFO memory accInfo = accountAttendList[account][_periodId];
        if(accInfo._isRedeem > 0) {
            return 0;
        }
        if(block.timestamp < accInfo._startRewardTime) {
            return 0;
        }
        uint256 tmpEarn = accInfo._amount.mul(rewardRate).mul(block.timestamp.sub(accInfo._startRewardTime));
        return tmpEarn.div(1e18);
    }

    function allEarn(address account) public view returns(uint256) {
        uint256 len = accountAttendPeriods[account].length;
        uint256 totalEarn;
        for(uint256 i = 0; i <= len; i++) {
           ATTENDINFO memory tmpAtt = accountAttendList[account][accountAttendPeriods[account][i]];
           if(tmpAtt._isRedeem > 0) continue ;
           uint256 tmpEarn = tmpAtt._amount.mul(rewardRate).mul(block.timestamp.sub(tmpAtt._startRewardTime));  
           totalEarn +=  tmpEarn;
        }
        return totalEarn.div(1e18);
    }

    function getGameListByPeriodId(uint256 _periodId) public view  returns(GAMEINFO memory _gameInfo) {
        return gameList[_periodId];
    }

    function getGameCountDown() public view returns(uint256) {
        GAMEINFO memory game = gameList[periodId];
        uint256 curIntvelTime = block.timestamp.sub(game._lastTime);
        if(game._residue.sub(curIntvelTime) <= 0) {
            return 0;
        } else {
            return game._residue - curIntvelTime;
        } 
    }

    function getPeriodTakeTime(uint256 _periodId) public view returns(uint256[] memory _times) {
        _times = periodTakeTime[_periodId];
    }

    function getPeriodTakeList(uint256 _periodId) public view returns(uint256[] memory _list) {
        _list = periodTakeList[_periodId];
    }
    
}