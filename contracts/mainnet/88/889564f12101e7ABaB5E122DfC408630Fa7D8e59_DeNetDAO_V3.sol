// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ERC20Unsafe.sol";
import "./PoSAdmin.sol";
import "./interfaces/IStorageToken.sol";
import "./interfaces/IProofOfStorage.sol";
import "./interfaces/IDeNetDAO.sol";

contract DeNetDAO_V3 is ERC20, PoSAdmin, IDeNetDAO {

    using SafeMath for uint256;
    using SafeMath for uint16;

    bytes2 constant DAO_FEELIMIT = 0x0001;
    bytes2 constant DAO_PAYOUTFEE = 0x0002;
    bytes2 constant DAO_PAYINFEE = 0x0003;
    bytes2 constant DAO_MINTPERCENT = 0x0004;
    bytes2 constant DAO_UNBURNPERCENT = 0x0005;
    bytes2 constant DAO_TARGET_PROOF_TIME = 0x0006;
    bytes2 constant DAO_MIN_STORAGE_SIZE = 0x0007;
    bytes2 constant DAO_INFLATION_RATE = 0x0008;
    bytes2 constant DAO_MIN_TIME_TO_INFLATION = 0x0009;

    // Fee Limit Voting Vars
    mapping (address => mapping (bytes2 => uint)) public DAOVote;
    mapping (address => mapping (bytes2 => uint)) public DAOVotePower;

    mapping (bytes2 => uint) public DAOVoteTotal;
    mapping (bytes2 => uint) public DAOVotePowerTotal;

    mapping (address => uint) public TimeFromLastTransfer;
    mapping (address => uint) public TimeBeforeUnlock;

    constructor (address _StorageContractAddress) ERC20("Voting DeNet v3", "veDE") PoSAdmin(_StorageContractAddress) {
        _mint(msg.sender, DECIMALS_18.mul(10));
        _mint(DEFAULT_FEE_COLLECTOR, DECIMALS_18.mul(10));
        
        // set default starting params
        _setTotalVote(DAO_FEELIMIT, DECIMALS_18, 1);
        _setTotalVote(DAO_PAYOUTFEE, START_PAYOUT_FEE, 1);
        _setTotalVote(DAO_PAYINFEE, START_PAYIN_FEE, 1);
        _setTotalVote(DAO_MINTPERCENT, START_MINT_PERCENT, 1);
        _setTotalVote(DAO_UNBURNPERCENT, START_UNBURN_PERCENT, 1);
        _setTotalVote(DAO_TARGET_PROOF_TIME, TIME_1D, 1);
        _setTotalVote(DAO_MIN_STORAGE_SIZE, STORAGE_100GB_IN_MB, 1);
        _setTotalVote(DAO_INFLATION_RATE, 200, 1);
        _setTotalVote(DAO_MIN_TIME_TO_INFLATION, 60*5, 1);
    }

    function deposit(uint amount) public { 
        require(amount > 0, "DeNetDAO.deposit:amount <= 0");
        IERC20 originToken = IERC20(storagePairTokenAddress);
        uint balanceBefore = originToken.balanceOf(address(this));
        originToken.transferFrom(msg.sender, address(this), amount);
        uint balanceAfter = originToken.balanceOf(address(this));
        uint change = balanceAfter.sub(balanceBefore);
        _mint(msg.sender, change);
    }

    function withdraw(uint amount) public {
        uint userBalance = balanceOf(msg.sender);
        if (amount > userBalance) {
            amount = userBalance;
        }
        _burn(msg.sender, amount);

        require(amount > 0, "DeNetDAO.withdraw:amount <= 0");
        IERC20 originToken = IERC20(storagePairTokenAddress);
        originToken.transfer(msg.sender, amount);
    }

    function _setTotalVote(bytes2 _for, uint _vote, uint _votePower) internal {
        DAOVoteTotal[_for] = _vote;
        DAOVotePowerTotal[_for] = _votePower;
    }
    
    function getVotePower(address _voter) public override view returns (uint) {
        if (balanceOf(_voter) == 0) {
            return 0;
        }
        uint _lastMoveTime = block.timestamp.sub(TimeFromLastTransfer[_voter]);

        if (_lastMoveTime < TIME_7D) {
            _lastMoveTime = TIME_7D;
        }
        if (_lastMoveTime > TIME_1Y) {
            _lastMoveTime = TIME_1Y;
        }
        return balanceOf(_voter).div(TIME_1Y).mul(_lastMoveTime).div(1e15);
    }

    /** @dev return time, when user can close voting deposit */
    function getUnlockTime(address _voter) public view returns (uint) {
        if (block.timestamp > TimeBeforeUnlock[_voter]) return 0;
        return TimeBeforeUnlock[_voter].sub(block.timestamp);
    }

    function _updateFeeLimit() internal {
        IStorageToken gasToken = IStorageToken(gasTokenAddress);
        gasToken.changeFeeLimit(DAOVoteTotal[DAO_FEELIMIT].div(DAOVotePowerTotal[DAO_FEELIMIT]));
    }

    function _updatePayoutFee() internal {
        IStorageToken gasToken = IStorageToken(gasTokenAddress);
        gasToken.changePayoutFee(uint16(DAOVoteTotal[DAO_PAYOUTFEE].div(DAOVotePowerTotal[DAO_PAYOUTFEE])));
    }

    function _updatePayinFee() internal {
        IStorageToken gasToken = IStorageToken(gasTokenAddress);
        gasToken.changePayinFee(uint16(DAOVoteTotal[DAO_PAYINFEE].div(DAOVotePowerTotal[DAO_PAYINFEE])));
    }

    function _updateMintPercent() internal {
        IStorageToken gasToken = IStorageToken(gasTokenAddress);
        gasToken.changeMintPercent(uint16(DAOVoteTotal[DAO_MINTPERCENT].div(DAOVotePowerTotal[DAO_MINTPERCENT])));
    }

    function _updateUnburnPercent() internal {
        IStorageToken gasToken = IStorageToken(gasTokenAddress);
        gasToken.changeUnburnPercent(uint16(DAOVoteTotal[DAO_UNBURNPERCENT].div(DAOVotePowerTotal[DAO_UNBURNPERCENT])));
    }

    function _updateTargetProofTime() internal {
        IProofOfStorage PoSContract = IProofOfStorage(proofOfStorageAddress);
        PoSContract.setTargetProofTime(
            DAOVoteTotal[DAO_TARGET_PROOF_TIME].div(
                DAOVotePowerTotal[DAO_TARGET_PROOF_TIME]
            )
        );
    }

    function _updateMinStorageSize() internal {
        IProofOfStorage PoSContract = IProofOfStorage(proofOfStorageAddress);
        PoSContract.setMinStorage(
            DAOVoteTotal[DAO_MIN_STORAGE_SIZE].div(
                DAOVotePowerTotal[DAO_MIN_STORAGE_SIZE]
            )
        );
    }

    function _updateInflationRate() internal {
        IStorageToken gasToken = IStorageToken(gasTokenAddress);
        gasToken.changeInflationRate(uint16(
            DAOVoteTotal[DAO_INFLATION_RATE].div(DAOVotePowerTotal[DAO_INFLATION_RATE])
        ));
    }

    function _updateMinTimeToInflation() internal {
        IStorageToken gasToken = IStorageToken(gasTokenAddress);
        gasToken.changeMinTimeToInflation(uint16(
            DAOVoteTotal[DAO_MIN_TIME_TO_INFLATION].div(DAOVotePowerTotal[DAO_MIN_TIME_TO_INFLATION])
        ));
    }
    
    function voteBack(bytes2 _for) public {
        _voteBack(msg.sender, _for);
    }

    function voteBackAll() public {
        _voteBack(msg.sender, DAO_FEELIMIT);
        _voteBack(msg.sender, DAO_PAYOUTFEE);
        _voteBack(msg.sender, DAO_PAYINFEE);
        _voteBack(msg.sender, DAO_MINTPERCENT);
        _voteBack(msg.sender, DAO_UNBURNPERCENT);
        _voteBack(msg.sender, DAO_TARGET_PROOF_TIME);
        _voteBack(msg.sender, DAO_INFLATION_RATE);
        _voteBack(msg.sender, DAO_MIN_TIME_TO_INFLATION);
    }

    function _voteBack(address _voter, bytes2 _for) internal {
        // get user vote
        uint userVote = DAOVote[_voter][_for];
        uint userVotePower = DAOVotePower[_voter][_for];

        // vote back from total
        DAOVoteTotal[_for] = DAOVoteTotal[_for].sub(userVote);
        DAOVotePowerTotal[_for] = DAOVotePowerTotal[_for].sub(userVotePower);

        // set zero
        DAOVote[_voter][_for] = 0;
        DAOVotePower[_voter][_for] = 0;

        if (_for == DAO_FEELIMIT) {
            _updateFeeLimit();
        }
        if (_for == DAO_PAYOUTFEE) {
            _updatePayoutFee();
        }
        if (_for == DAO_PAYINFEE) {
            _updatePayinFee();
        }
        if (_for == DAO_MINTPERCENT) {
            _updateMintPercent();
        }
        if (_for == DAO_UNBURNPERCENT) {
            _updateUnburnPercent();
        }
        if (_for == DAO_TARGET_PROOF_TIME) {
            _updateTargetProofTime();
        }
        if (_for == DAO_MIN_STORAGE_SIZE) {
            _updateMinStorageSize();
        }
        if (_for == DAO_INFLATION_RATE) {
            _updateInflationRate();
        }
         if (_for == DAO_MIN_TIME_TO_INFLATION) {
            _updateMinTimeToInflation();
        }
    }

    function _setVote(address _voter, bytes2 _for, uint _vote, uint _votePower) internal {
        require(_votePower > 0, "DAO._setVote: vote power = 0");
        
        DAOVote[_voter][_for] = _vote;
        DAOVotePower[_voter][_for] = _votePower;
        DAOVoteTotal[_for] = DAOVoteTotal[_for].add(_vote);
        DAOVotePowerTotal[_for] = DAOVotePowerTotal[_for].add(_votePower);
        TimeBeforeUnlock[_voter] = block.timestamp.add(TIME_7D);

        emit UpdateTotalVote(_for, DAOVoteTotal[_for].div(DAOVotePowerTotal[_for]), DAOVotePowerTotal[_for]);
    }

    /** @dev voting for new fee limit */
    function voteForFeeLimit(uint newLimit) public {
        _voteBack(msg.sender, DAO_FEELIMIT);
        (uint minLimit, uint maxLimit) = getFeeLimitRangeVoting();
        uint UserVotePower = getVotePower(msg.sender);
        uint UserVote = newLimit.mul(UserVotePower);

        require(newLimit >= minLimit && newLimit <= maxLimit, "DAO.voteForFeeLimit:newLimit > maxLimit | newLimit < minLimit");

        _setVote(msg.sender, DAO_FEELIMIT, UserVote, UserVotePower);
        _updateFeeLimit();
    }

    function getFeeLimitRangeVoting() public override view returns (uint, uint) {
        IStorageToken gasToken = IStorageToken(gasTokenAddress);
        uint lastFeeLimit = gasToken.currentFeeLimit();
        return (lastFeeLimit.mul(100).div(200), lastFeeLimit.mul(2));
    }

    /** @dev voting for new payout fee */
    function voteForPayoutFee(uint newFee) public {
        _voteBack(msg.sender, DAO_PAYOUTFEE);
        (uint minLimit, uint maxLimit) = getPayoutFeeRangeVoting();

        uint UserVotePower = getVotePower(msg.sender);
        uint UserVote = newFee.mul(UserVotePower);
        
        require(newFee >= minLimit && newFee <= maxLimit, "DAO.voteForPayoutFee:newFee > maxLimit | newFee < minLimit");
        
        _setVote(msg.sender, DAO_PAYOUTFEE, UserVote, UserVotePower);
        _updatePayoutFee();
    }

    /** @dev voting for new payin fee */
    function voteForPayinFee(uint newFee) public {
        _voteBack(msg.sender, DAO_PAYINFEE);
        (uint minLimit, uint maxLimit) = getPayinFeeRangeVoting();

        uint UserVotePower = getVotePower(msg.sender);
        uint UserVote = newFee.mul(UserVotePower);
        
        require(newFee >= minLimit && newFee <= maxLimit, "DAO.voteForPayinFee:newFee > maxLimit | newFee < minLimit");
        
        _setVote(msg.sender, DAO_PAYINFEE, UserVote, UserVotePower);
        _updatePayinFee();
    }

    /** @dev voting for mint percentage fee */
    function voteForMintPercent(uint newPercent) public {
        _voteBack(msg.sender, DAO_MINTPERCENT);
        (uint minLimit, uint maxLimit) = getMintPercentRangeVoting();

        uint UserVotePower = getVotePower(msg.sender);
        uint UserVote = newPercent.mul(UserVotePower);
        
        require(newPercent >= minLimit && newPercent <= maxLimit, "DAO.voteForMintPercent:newPercent > maxLimit | newPercent < minLimit");

        _setVote(msg.sender, DAO_MINTPERCENT, UserVote, UserVotePower);
        _updateMintPercent();
    }

    /** @dev voting for mint percentage fee */
    function voteForUnburnPercent(uint newPercent) public {
        _voteBack(msg.sender, DAO_UNBURNPERCENT);
        (uint minLimit, uint maxLimit) = getUnburnPercentRangeVoting();

        uint UserVotePower = getVotePower(msg.sender);
        uint UserVote = newPercent.mul(UserVotePower);
        
        require(newPercent >= minLimit && newPercent <= maxLimit, "DAO.voteForUnburnPercent:newPercent > maxLimit | newPercent < minLimit");

        _setVote(msg.sender, DAO_UNBURNPERCENT, UserVote, UserVotePower);
        _updateUnburnPercent();
    }

    function voteForTargetProofUpdate(uint _newProofUpdateTime) public {
        _voteBack(msg.sender, DAO_TARGET_PROOF_TIME);
        (uint minLimit, uint maxLimit) = getTargetProofTimeRangeVoting();
        
        uint UserVotePower = getVotePower(msg.sender);
        uint UserVote = _newProofUpdateTime.mul(UserVotePower);

        require(_newProofUpdateTime >= minLimit && _newProofUpdateTime <= maxLimit,
            "DAO.voteForTargetProofUpdate:_newProofUpdateTime > maxLimit | _newProofUpdateTime < minLimit");
    
        _setVote(msg.sender, DAO_TARGET_PROOF_TIME, UserVote, UserVotePower);
        _updateTargetProofTime();
    }

    function voteForMinStorageSize(uint _newMinStorageSize) public {
        _voteBack(msg.sender, DAO_MIN_STORAGE_SIZE);
        (uint minLimit, uint maxLimit) = getMinStorageRangeVoting();
        
        uint UserVotePower = getVotePower(msg.sender);
        uint UserVote = _newMinStorageSize.mul(UserVotePower);

        require(_newMinStorageSize >= minLimit && _newMinStorageSize <= maxLimit,
            "DAO.voteForMinStorageSize:_newMinStorageSize > maxLimit | _newMinStorageSize < minLimit");
    
        _setVote(msg.sender, DAO_MIN_STORAGE_SIZE, UserVote, UserVotePower);
        _updateMinStorageSize();
    }

    function voteForInflationRate(uint _newRate) public {
        _voteBack(msg.sender, DAO_INFLATION_RATE);
        (uint minRate, uint maxRate) = getInflationRatetRangeVoting();

        uint UserVotePower = getVotePower(msg.sender);
        uint UserVote = _newRate.mul(UserVotePower);

        require(_newRate >= minRate && _newRate <= maxRate,
            "DAO.voteForInflationRate:_newRate > minRate | _newRate < maxRate");
        
        _setVote(msg.sender, DAO_INFLATION_RATE, UserVote, UserVotePower);
        _updateInflationRate();
    }

    function voteForMinTimeToInflation(uint _newRate) public {
        _voteBack(msg.sender, DAO_MIN_TIME_TO_INFLATION);
        (uint minRate, uint maxRate) = getMinTimeToInflationRangeVoting();
        uint UserVotePower = getVotePower(msg.sender);
        uint UserVote = _newRate.mul(UserVotePower);

        require(_newRate >= minRate && _newRate <= maxRate,
            "DAO.voteForMinTimeToInflation:_newRate > minRate | _newRate < maxRate");

        _setVote(msg.sender, DAO_MIN_TIME_TO_INFLATION, UserVote, UserVotePower);
        _updateMinTimeToInflation();
    }
    
    function getInflationRatetRangeVoting() public override pure returns (uint, uint) {
        return (1, 200);
    }

    function getMinTimeToInflationRangeVoting() public override pure returns (uint, uint) {
        return (30, 65534);
    }

    function getMintPercentRangeVoting() public override pure returns (uint, uint) {
        return (1, 9999);
    }

    function getUnburnPercentRangeVoting() public override pure returns (uint, uint) {
        return (1, 9999);
    }

    function getPayoutFeeRangeVoting() public override pure returns (uint, uint) {
        return (1, 3000);
    }

    function getPayinFeeRangeVoting() public override pure returns (uint, uint) {
        return (1, 3000);
    }

    function getTargetProofTimeRangeVoting() public override pure returns (uint, uint) {
        return (600, TIME_1D);
    }

    function getMinStorageRangeVoting() public override pure returns (uint, uint) {
        return (100, STORAGE_1TB_IN_MB);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (from != address(0)) {
            require(to == address(0), "DeNetDAO.transfer:Transfer is not available");
            require(getUnlockTime(from) == 0, "DeNetDAO.transfer:Deposit locked");

            TimeFromLastTransfer[from] = block.timestamp;

            _voteBack(from, DAO_FEELIMIT);
            _voteBack(from, DAO_PAYOUTFEE);
            _voteBack(from, DAO_PAYINFEE);
            _voteBack(from, DAO_MINTPERCENT);
            _voteBack(from, DAO_UNBURNPERCENT);
            _voteBack(from, DAO_TARGET_PROOF_TIME);
            _voteBack(from, DAO_MIN_STORAGE_SIZE);
            _voteBack(from, DAO_INFLATION_RATE);
            _voteBack(from, DAO_MIN_TIME_TO_INFLATION);
        } else {
            TimeFromLastTransfer[to] = block.timestamp;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string public _name;
    string public _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "Exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance < zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "From zero address");
        require(recipient != address(0), "To zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Mint to zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Burn from zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Burn exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Approve from zero address");
        require(spender != address(0), "Approve to zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IContractStorage {

    function stringToContractName(string calldata nameString) external pure returns(bytes32);

    function getContractAddress(bytes32 contractName, uint networkId) external view returns (address);

    function getContractAddressViaName(string calldata contractString, uint networkId) external view returns (address);

    function getContractListOfNetwork(uint networkId) external view returns (string[] memory);

    function getNetworkLists() external view returns (uint[] memory);
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.9;

interface IDeNetDAO {

    /**
    * @dev This event show last vote for `_voteFor`, result of vote and totalVotePower of this.
    */
    event UpdateTotalVote (
        bytes2 _voteFor,
        uint _result,
        uint _totalVotePower
    );

    /**
    *@dev show votePower of Voter, vote power grow with time. 
    *
    *- **1 TBY** - with deposited without moving for less 7 days = 19 Vote Power
    *- **1 TBY** - with deposited without moving for less 30 days = 82 Vote Power
    *- **1 TBY** - with deposited without moving for less 1 year or more = 1000 Vote Power
    *
    *@param _voter - address of voter
    *@return votePower uint - balance(_voter).mul(timeFromLastTransfer).div(1year)
    **/
    function getVotePower(address _voter) external view returns (uint);

    /**
    * @dev get fee limit range for voting (min & max)
    * @return min - min limit
    * @return max - max limit
    */
    function getFeeLimitRangeVoting() external  view returns (uint, uint);
    /**
    * @dev get min storage range voting (min & max)
    * his function update Min Storage Size, it means, if min storage size = 500, but 
    * user store less size of data, user storage size will rounding up to 500 MB.
    * it's need's to make mining profitable for prooving small users, but 
    * reward will more, than tx proof cost for miner.
    * If netowrk would like to make proofs every 1 month for each user
    * it need, to proof reward will more than tx cost, as we know
    * the network gasprice is unstable and need to be some time updating this parametr.
    * for examole, if 1 TB Year price = 10 Matic, we need to be sure, that we can 
    * earn, more, that we spending on proofs
    * 12 proofs for each year for miner will cost 0.05 Matic x 12 = 0.6 Matic
    * Miner need earn more 0.6 Matic for 12 proofs (or more 0.05 for each proof)
    * 0.6 Matic / 10 Matic (tb price) = 0.06 TB - 61.44 GB = ~62914 MB min storage size.  
    * it means, that miner will earn 0, if store user with less than 61.44 GB.
    * and earn something, if user will store more. 
    * To make miners profitable, they need to make this parametr more than 62914.
    * In user case, they have not difference, because to make their FS prooved for one yer
    * user spend 0.06 TB/year from  balance. (0.6 Matic for one year).
    * For user, who store more than 0.06 TB, this parametr doesn't matter, because they will
    * Pay equeal amount such they store.
    * For user it just means, minimal amount of payment for usage per year,  but if store more data, pay more
    * @return min - min - 100 - 100 MB
    * @return max - max - 1048576 - 1 TB
    */
    function getMinStorageRangeVoting() external pure returns (uint, uint);

    /**
    * @dev get target proof time range for voting (min & max)
    * The good parametr depends of Netowrk gas token price, revenue of miner per proof, and
    * stability of prooving user side. For example, if netowrk have 10k users
    * and 100 miners, wee need to make approve for user for each 30 days or less.
    * it's means we need best target time ~ 10k Users / 100 miners = 100 users per miner per month
    * best time is 30 days for miner  / 100 users = 25920s ~ 7.2 Hours.
    * in same case, but if we need to make proof every 14 days, we need:
    * 10k/100 miners = 100 users, 14 days / 100 proofs  =  12096 = ~3.36 Hours.
    * @return min - min - 600 - 10 minutes
    * @return max - max - 86400 = 1 DAY
    */
    function getTargetProofTimeRangeVoting() external pure returns (uint, uint);

    /**
    * @dev get limit of TB inflation rate from 0.01% to 2$
    * @return min - min rate - 0.01%
    * @return max - max rate - 2%
    */
    function getInflationRatetRangeVoting() external pure returns (uint, uint);

    /**
    * @dev get time limit, minimal before Inflation will calculated
    * @return min - min time 30 sec
    * @return max - max time 18 hours 12 minutes
    */
    function getMinTimeToInflationRangeVoting() external pure returns (uint, uint);
    
    /**
    * @dev get fee limit range for voting (min & max)
    * @return min - min fee - 1/10000
    * @return max - max fee - 9999/10000
    */
    function getMintPercentRangeVoting() external pure returns (uint, uint);

    /**
    * @dev get unburn limit range for voting (min & max)
    * @return min - min fee - 1/10000
    * @return max - max fee - 9999/10000
    */
    function getUnburnPercentRangeVoting() external pure returns (uint, uint);

    /**
    * @dev get fee limit range for voting (min & max)
    * @return min - min fee = 1/10000 = 0.1%
    * @return max - max fee = 3000/10000 = 30%
    */
    function getPayoutFeeRangeVoting() external pure returns (uint, uint);

    /**
    * @dev get fee limit range for voting (min & max)
    * @return min - min fee = 1/10000 = 0.1%
    * @return max - max fee = 3000/10000 = 30%
    */
    function getPayinFeeRangeVoting() external pure returns (uint, uint);
}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet
*/

pragma solidity ^0.8.0;

interface IPoSAdmin {
    event ChangePoSAddress(
        address indexed newPoSAddress
    );
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.9;

interface IProofOfStorage {

    event TargetProofTimeUpdate(
        uint256 _newTargetProofTime
    );

    event MinStorageSizeUpdate(
        uint256 _newMinStorageSize
    );

    /*
        @dev Returns info about user reward for ProofOfStorage

        INPUT
            @_user - User Address
            @_user_storage_size - User Storage Size

        OUTPUT
            @_amount - Total Token Amount for PoS
            @_last_rroof_time - Last Proof Time
    */


    function getUserRewardInfo(address _user, uint _user_storage_size)
        external
        view
        returns (
            uint,
            uint
        );
    
    /*
        @dev Returns last user root hash and nonce.

        INPUT
            @_user - User Address
        
        OUTPUT
            @_hash - Last user root hash
            @_nonce - Noce of root hash
    */
    function getUserRootHash(address _user)
        external
        view
        returns (bytes32, uint);
    
    /**
    * @dev this function update Target Proof time, to move difficulty on same size.
    */
    function setTargetProofTime(uint _newTargetProofTime) external;

    /**
    * @dev this function update Min Storage Size, it means, if min storage size = 500, but 
    * user store less size of data, user storage size will rounding up to 500 MB.
    * it's need's to make mining profitable for prooving small users, but 
    * reward will more, than tx proof cost for miner..
    */
    function setMinStorage(uint _size) external;

    function sendProofFrom(
        address _node_address,
        address _user_address,
        uint32 _block_number,
        bytes32 _user_root_hash,
        uint64 _user_storage_size,
        uint64 _user_root_hash_nonce,
        bytes calldata _user_signature,
        bytes calldata _file,
        bytes32[] calldata merkleProof
    ) external;

    // This Function calls from Traffic Manager
    function initTrafficPayment(address _user_address, uint _amount) external;
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IStorageToken {

    // function balanceOf (address _user) external view returns (uint256);
    // function transfer(address recipient, uint256 amount) external returns (bool);
    // function approve(address spender, uint256 amount) external returns (bool);
    
    // useful getters
    function currentFeeLimit() external view returns (uint);
    function currentPayoutFee() external view returns (uint16);
    function currentPayinFee() external view returns (uint16);
    function currentMintPercent() external view returns (uint16);
    function currentUnburnPercent() external view returns (uint16);
    function currentDivFee() external view returns (uint16);
    function currentInflationRate() external view returns (uint16);
    function currentMinTimeToInflation() external view returns (uint16);
    
    // change interface
    function changeFeeLimit(uint _new) external;
    function changePayoutFee(uint16 _new) external;
    function changePayinFee(uint16 _new) external;
    function changeMintPercent(uint16 _new) external;
    function changeUnburnPercent(uint16 _new) external;
    function changeMinTimeToInflation(uint16 _new) external;
    function changeInflationRate(uint16 _new) external;
}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet

    Contract is modifier only
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPoSAdmin.sol";
import "./interfaces/IContractStorage.sol";
import "./utils/StringNumbersConstant.sol";

contract PoSAdmin  is IPoSAdmin, Ownable, StringNumbersConstant {
    address public proofOfStorageAddress = address(0);
    address public storagePairTokenAddress = address(0);
    address public contractStorageAddress;
    address public daoContractAddress;
    address public gasTokenAddress;
    address public gasTokenMined;
    
    constructor (address _contractStorageAddress) {
        contractStorageAddress = _contractStorageAddress;
    }

    modifier onlyPoS() {
        require(msg.sender == proofOfStorageAddress, "PoSAdmin.msg.sender != POS");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == daoContractAddress, "PoSAdmin:msg.sender != DAO");
        _;
    }

    function changePoS(address _newAddress) public onlyOwner {
        proofOfStorageAddress = _newAddress;
        emit ChangePoSAddress(_newAddress);
    }

    function sync() public onlyOwner {
        IContractStorage contractStorage = IContractStorage(contractStorageAddress);
        proofOfStorageAddress = contractStorage.getContractAddressViaName("proofofstorage", NETWORK_ID);
        storagePairTokenAddress = contractStorage.getContractAddressViaName("pairtoken", NETWORK_ID);
        daoContractAddress = contractStorage.getContractAddressViaName("daowallet", NETWORK_ID);
        gasTokenAddress = contractStorage.getContractAddressViaName("gastoken", NETWORK_ID);
        gasTokenMined = contractStorage.getContractAddressViaName("gastoken_mined", NETWORK_ID);
        emit ChangePoSAddress(proofOfStorageAddress);
        _afterSync();
    }

    function _afterSync() internal virtual {}
}

pragma solidity ^0.8.0;

contract StringNumbersConstant {

   // Decimals Numbers
   uint public constant DECIMALS_18 = 1e18;
   uint public constant START_DEPOSIT_LIMIT = DECIMALS_18 * 100; // 100 DAI

   // Date and times
   uint public constant TIME_7D = 60*60*24*7;
   uint public constant TIME_1D = 60*60*24;
   uint public constant TIME_30D = 60*60*24*30;
   uint public constant TIME_1Y = 60*60*24*365;
   
   // Storage Sizes
   uint public constant STORAGE_1TB_IN_MB = 1048576;
   uint public constant STORAGE_10GB_IN_MB = 10240; // 10 GB;
   uint public constant STORAGE_100GB_IN_MB = 102400; // 100 GB;
  
   // nax blocks after proof depends of network, most of them 256 is ok
   uint public constant MAX_BLOCKS_AFTER_PROOF = 256;

   // Polygon Network Settigns
   address public constant PAIR_TOKEN_START_ADDRESS = 0x081Ec4c0e30159C8259BAD8F4887f83010a681DC; // DAI in Polygon
   address public constant DEFAULT_FEE_COLLECTOR = 0x15968404140CFB148365577D669477E1615557C0; // DeNet Labs Polygon Multisig
   uint public constant NETWORK_ID = 2241;

   // StorageToken Default Vars
   uint16 public constant DIV_FEE = 10000;
   uint16 public constant START_PAYOUT_FEE = 500; // 5%
   uint16 public constant START_PAYIN_FEE = 500; // 5%
   uint16 public constant START_MINT_PERCENT = 5000; // 50% from fee will minted
   uint16 public constant START_UNBURN_PERCENT = 5000; // 50% from fee will not burned
}