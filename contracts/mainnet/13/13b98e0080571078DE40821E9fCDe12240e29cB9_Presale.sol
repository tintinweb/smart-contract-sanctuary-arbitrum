/**
 *Submitted for verification at Arbiscan.io on 2024-05-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
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
        require(b <= a, 'SafeMath: subtraction overflow');
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
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
        require(b > 0, 'SafeMath: modulo by zero');
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

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

abstract contract Context {
    bytes32 private constant Context_SLOT_0 = 0xbaf61e80095a799ffcb308080e41c7bab80d986bcfb25a03262a5dfa90d6446f;
    // 152D02C7E14AF6800000 = StrToHex("Context constructor");
    bytes32 private constant NAME_HASH = 0x00000000000000000000000000000000000000000000152D02C7E14AF6800000;

    constructor() {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(Context_SLOT_0, NAME_HASH)
        }
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address payable newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface AggregatorV3Interface {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

contract Presale is Ownable {
    using SafeMath for uint;

    struct UserInfo {
        uint ethAmount;
        uint ventAmout;
        uint vntrAmount;
        bool isBuyer;
    }

    mapping(address => UserInfo) public userInfo;

    bool public isFinished;

    // total VENT sold
    uint public totalVentSold;
    uint public totalContributors;

    uint public totalEth;
    uint public totalVntr;

    // VENT token
    IERC20 public vent;
    IERC20 public vntr = IERC20(0xA27aD621bDfb7997daE63D4fa395E2f1a23387de);

    AggregatorV3Interface ethFeed = AggregatorV3Interface(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);
    IUniswapV2Pair vntrEthLP = IUniswapV2Pair(0x2DB2f92701f8acF3a88a44908CEc18CC7F80CF83);

    constructor(address _vent) {
        vent = IERC20(_vent);
    }

    function getEthPrice() public view returns (int) {
        (, int price, , , ) = ethFeed.latestRoundData();
        return price;
    }

    function finishPresale() public onlyOwner {
        isFinished = true;
    }

    function presaleRateEth() public view returns(uint) {
        return uint(getEthPrice()).mul(10);
    }

    function presaleRateVntr() public view returns(uint) {
        (uint reserve0, uint reserve1,) = vntrEthLP.getReserves();
        return reserve0.mul(uint(getEthPrice())).div(reserve1).div(1e8)/9*10;
    }

    function buyWithEth() public payable {
        require(!isFinished, 'Finished');
        UserInfo storage user = userInfo[msg.sender];
        user.ethAmount += msg.value;
        totalEth += msg.value;
        if (!user.isBuyer) {
            user.isBuyer = true;
            totalContributors += 1;
        }
        uint ventBought = msg.value.mul(uint(getEthPrice())).div(1e17);
        user.ventAmout += ventBought;
        totalVentSold += ventBought;
    }

    function buyWithVntr(uint _amount) public {
        require(!isFinished, 'Finished');
        UserInfo storage user = userInfo[msg.sender];
        vntr.transferFrom(msg.sender, address(this), _amount);
        user.vntrAmount += _amount;
        totalVntr += _amount;
        if (!user.isBuyer) {
            user.isBuyer = true;
            totalContributors += 1;
        }
        (uint reserve0, uint reserve1,) = vntrEthLP.getReserves();
        uint ventBought = _amount.mul(reserve0).mul(uint(getEthPrice())).div(reserve1).div(1e17)/9*10;
        user.ventAmout += ventBought;
        totalVentSold += ventBought;
    }

    function claim() public {
        require(isFinished, 'Not Finished');
        UserInfo storage user = userInfo[msg.sender];
        require(user.ventAmout != 0, 'No claimed amount!');
        vent.transfer(msg.sender, user.ventAmout);
        user.ventAmout = 0;
    }

    function emergencyWithdraw() public {
        require(!isFinished, 'Finished');
        UserInfo storage user = userInfo[msg.sender];
        if (user.vntrAmount != 0) {
            uint wAmount = user.vntrAmount;
            if (wAmount > vntr.balanceOf(address(this))) wAmount = vntr.balanceOf(address(this));
            if (wAmount > 0) vntr.transfer(msg.sender, wAmount);
        }
        if (user.ethAmount != 0) {
            uint wEthAmount = user.ethAmount;
            if (wEthAmount > address(this).balance) wEthAmount = address(this).balance;
            if (wEthAmount > 0) payable(msg.sender).transfer(wEthAmount);
        }
        totalEth = totalEth - user.ethAmount;
        totalVntr = totalVntr - user.vntrAmount;
        totalVentSold = totalVentSold - user.ventAmout;
        totalContributors = totalContributors - 1;
        delete userInfo[msg.sender];
    }

    // withdraw ETH for owner
    function withdrawEth(uint _amount, address _recipient) public onlyOwner {
        uint balance = address(this).balance;
        if (balance < _amount) {
            _amount = balance;
        }
        payable(_recipient).transfer(_amount);
    }

    // withdarw VENT and VNTR for owner
    function withdrawToken(address _tokenAddress, uint _amount, address _recipient) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint balance = token.balanceOf(address(this));
        if (balance < _amount) {
            _amount = balance;
        }
        token.transfer(_recipient, _amount);
    }

    receive() external payable {}
}