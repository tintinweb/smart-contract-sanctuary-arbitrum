// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlanetVault is Ownable {

/* MetaX Smart Contracts */
    /* MetaX */
    address public MetaX_Addr;

    IERC20 public MX;

    function setMetaX (address _MetaX_Addr) public onlyOwner {
        MetaX_Addr = _MetaX_Addr;
        MX = IERC20(_MetaX_Addr);
    }

/* Staking */
    /* Planet Vault */
    struct _Vault {
        uint256 stakedAmount;
        uint256[] stakedAmount_Record;
        uint256[] stakedTime_Record;
        uint256 accumStakedAmount;
        uint256 accumUnstakedAmount;
        uint256[] redeemable;
        uint256[] redeemTime;
    }

    mapping (address => _Vault) public Vault;

    uint256 public globalStakedAmount;

    uint256 public accumGlobalStakedAmount;

    uint256 public accumGlobalUnstakedAmount;

    /* Record */
    function getStakedAmount (address user) external view returns (uint256) {
        return Vault[user].stakedAmount;
    }

    function getRecordLength (address user) external view returns (uint256) {
        return Vault[user].stakedAmount_Record.length;
    }

    function getStakedAmount_Record (address user, uint256 batch) external view returns (uint256) {
        return Vault[user].stakedAmount_Record[batch];
    }

    function getStakedAmount_Record_All (address user) external view returns (uint256[] memory) {
        return Vault[user].stakedAmount_Record;
    }

    function getStakedTime_Record (address user, uint256 batch) external view returns (uint256) {
        return Vault[user].stakedTime_Record[batch];
    }

    function getStakedTime_Record_All (address user) external view returns (uint256[] memory) {
        return Vault[user].stakedTime_Record;
    }

    function getAccumStakedAmount (address user) external view returns (uint256) {
        return Vault[user].accumStakedAmount;
    }

    function getAccumUnstakedAmount (address user) external view returns (uint256) {
        return Vault[user].accumUnstakedAmount;
    }

    event stakeRecord (address user, uint256 amount, uint256 time);

    event unstakeRecord (address user, uint256 amount, uint256 time);

    event redeemRecord (address user, uint256 amount, uint256 time);

    /* Stake */
    function Stake (uint256 Amount) public { /* In WEI */
        require(MX.balanceOf(msg.sender) >= Amount, "PlanetVault: You don't have enough $MetaX to stake.");
        MX.transferFrom(msg.sender, address(this), Amount);
        Vault[msg.sender].stakedAmount += Amount;
        Vault[msg.sender].stakedAmount_Record.push(Amount);
        Vault[msg.sender].stakedTime_Record.push(block.timestamp);
        Vault[msg.sender].accumStakedAmount += Amount;
        globalStakedAmount += Amount;
        accumGlobalStakedAmount += Amount;
        emit stakeRecord(msg.sender, Amount, block.timestamp);
    }

    /* Unstake */
    function Unstake (uint256 Amount) public { /* In WEI */
        require(Vault[msg.sender].stakedAmount >= Amount, "PlanetVault: You don't have enough staked $MetaX to unstake.");
        Vault[msg.sender].redeemable.push(Amount);
        Vault[msg.sender].redeemTime.push(block.timestamp + unlockIntervals);
        Vault[msg.sender].stakedAmount -= Amount;

        uint256[] storage record = Vault[msg.sender].stakedAmount_Record;
        uint256 amount = Amount;
        for (uint256 i=0; i<record.length; i++) {
            if (record[i] < amount) {
                amount -= record[i];
                record[i] = 0;
            } else {
                record[i] -= amount;
                break;
            }
        }

        Vault[msg.sender].accumUnstakedAmount += Amount;
        globalStakedAmount -= Amount;
        accumGlobalUnstakedAmount += Amount;
        globalRedeemable += Amount;
        cleanUp_stake();
        emit unstakeRecord(msg.sender, Amount, block.timestamp);
    }

    /* Redeem */
    uint256 public globalRedeemable;

    uint256 public unlockIntervals = 1 minutes;

    function setUnlockIntervals (uint256 newUnlockIntervals) public onlyOwner {
        unlockIntervals = newUnlockIntervals;
    }

    function getRedeemable_All (address user) public view returns (uint256 _redeemable_all) {
        uint256[] storage _redeem = Vault[user].redeemable;
        for (uint256 i=0; i<_redeem.length; i++) {
            _redeemable_all += _redeem[i];
        }
    }

    function getRedeemable (address user) public view returns (uint256 _redeemable) {
        uint256[] storage _redeem = Vault[user].redeemable;
        uint256[] storage _time = Vault[user].redeemTime;
        if (_redeem.length != 0) {
            for (uint256 i=0; i<_redeem.length; i++) {
                if (_time[i] < block.timestamp) {
                    _redeemable += _redeem[i];
                } else {
                    break;
                }
            }
        } else {
            _redeemable = 0;
        }
    }

    function getNextRedeemTime (address user) public view returns (uint256 nextRedeemTime) {
        uint256[] storage _time = Vault[user].redeemTime;
        if (_time.length != 0) {
            for (uint256 i=0; i<_time.length; i++) {
                if (_time[i] < block.timestamp) {
                    continue; 
                } else {
                    nextRedeemTime = _time[i];
                    break;
                }
            }
        } else {
            nextRedeemTime = 0;
        }
    }

    function Redeem () public {
        uint256 _redeemable = getRedeemable(msg.sender);
        require(_redeemable != 0, "PlanetVault: You don't have any redeemable tokens.");
        uint256[] storage record = Vault[msg.sender].redeemable;
        MX.transfer(msg.sender, _redeemable);
        globalRedeemable -= _redeemable;
        uint256 amount = _redeemable;
        for (uint256 i=0; i<record.length; i++) {
            if (record[i] < amount) {
                amount -= record[i];
                record[i] = 0;
            } else {
                record[i] -= amount;
                break;
            }
        }
        cleanUp_redeem();
        emit redeemRecord(msg.sender, _redeemable, block.timestamp);
    }

    /* Clean Up */
    function cleanUp_stake () internal {
        uint256[] storage amount = Vault[msg.sender].stakedAmount_Record;
        uint256[] storage time = Vault[msg.sender].stakedTime_Record;
        uint256 empty;
        for (uint256 i=0; i<amount.length; i++) {
            if (amount[i] == 0) {
                empty++;
            } else {
                break;
            }
        }
        if (empty != 0) {
            for (uint256 j=0; j<amount.length - empty; j++) {
                amount[j] = amount[j + empty];
                time[j] = time[j + empty];
            }
            for (uint256 k=0; k<empty; k++) {
                amount.pop();
                time.pop();
            }
        }
    }

    function cleanUp_redeem () internal {
        uint256[] storage _redeem = Vault[msg.sender].redeemable;
        uint256[] storage _time = Vault[msg.sender].redeemTime;
        uint256 empty;
        for (uint256 i=0; i<_redeem.length; i++) {
            if (_redeem[i] == 0) {
                empty++;
            } else {
                break;
            }
        }
        if (empty != 0) {
            for (uint256 j=0; j<_redeem.length - empty; j++) {
                _redeem[j] = _redeem[j + empty];
                _time[j] = _time[j + empty];
            }
            for (uint256 k=0; k<empty; k++) {
                _redeem.pop();
                _time.pop();
            }
        }
    }

/* Adjustment Factor */
    function Adjustment (address user) public view returns (uint256 adjustment) {
        uint256 stake = Vault[user].stakedAmount;
        uint256 ratio = (stake * 10000) / Vault[user].accumStakedAmount;
        if (ratio == 0) {
            adjustment = 0;
        } else if (ratio < 5000) {
            adjustment = 5000 + ratio;
        } else if (ratio == 5000) {
            adjustment = 10000;
        } else {
            adjustment = 10000 + ratio;
        }
    }

/* Staking Scores */
    function baseScores (address user) public view returns (uint256 baseScores_) {
        uint256[] storage amount = Vault[user].stakedAmount_Record;
        uint256[] storage time = Vault[user].stakedTime_Record;
        if (amount.length == 0) {
            baseScores_ = 0;
        } else {
            for (uint256 i=0; i<amount.length; i++) {
                baseScores_ += ((amount[i] / 1 ether) * ((block.timestamp - time[i]) / 1 days));
            }
        }
    }

    function _baseScores (address user) external view returns (uint256) {
        return baseScores(user);
    }

    function finalScores (address user) external view returns (uint256) {
        return baseScores(user) * Adjustment(user) / 10000;
    }

    function scoresByBatch (address user, uint256 batch) public view returns (uint256 baseScoresByBatch, uint256 finalScoresByBatch) {
        uint256 amount = Vault[user].stakedAmount_Record[batch];
        uint256 time = Vault[user].stakedTime_Record[batch];
        baseScoresByBatch = ((amount / 1 ether) * ((block.timestamp - time) / 1 days));
        finalScoresByBatch = baseScoresByBatch * Adjustment(user) / 10000;
    }

    function _baseScoresByBatch (address user, uint256 batch) external view returns (uint256) {
        (uint256 baseScoresByBatch, ) = PlanetVault.scoresByBatch(user, batch);
        return baseScoresByBatch;
    }

    function _finalScoresByBatch (address user, uint256 batch) external view returns (uint256) {
        ( , uint256 finalScoresByBatch) = PlanetVault.scoresByBatch(user, batch);
        return finalScoresByBatch;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

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