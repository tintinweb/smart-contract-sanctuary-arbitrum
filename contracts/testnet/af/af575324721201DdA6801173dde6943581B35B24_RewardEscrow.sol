// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IERC20.sol";

abstract contract $IERC20 is IERC20 {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IKwenta.sol";

abstract contract $IKwenta is IKwenta {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IRewardEscrow.sol";

contract $VestingEntries {
    constructor() {}
}

abstract contract $IRewardEscrow is IRewardEscrow {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IStakingRewards.sol";

abstract contract $IStakingRewards is IStakingRewards {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/RewardEscrow.sol";

contract $RewardEscrow is RewardEscrow {
    constructor(address _owner, address _kwenta) RewardEscrow(_owner, _kwenta) {}

    function $_claimableAmount(VestingEntries.VestingEntry calldata _entry) external view returns (uint256, uint256) {
        return super._claimableAmount(_entry);
    }

    function $_earlyVestFee(VestingEntries.VestingEntry calldata _entry) external view returns (uint256) {
        return super._earlyVestFee(_entry);
    }

    function $_isEscrowStaked(address _account) external view returns (bool) {
        return super._isEscrowStaked(_account);
    }

    function $_transferVestedTokens(address _account,uint256 _amount) external {
        return super._transferVestedTokens(_account,_amount);
    }

    function $_reduceAccountEscrowBalances(address _account,uint256 _amount) external {
        return super._reduceAccountEscrowBalances(_account,_amount);
    }

    function $_appendVestingEntry(address account,uint256 quantity,uint256 duration) external {
        return super._appendVestingEntry(account,quantity,duration);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/utils/Owned.sol";

contract $Owned is Owned {
    constructor(address _owner) Owned(_owner) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

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

import "./IERC20.sol";

interface IKwenta is IERC20 {

    function mint(address account, uint amount) external;

    function burn(uint amount) external;

    function setSupplySchedule(address _supplySchedule) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library VestingEntries {
    struct VestingEntry {
        uint64 endTime;
        uint256 escrowAmount;
        uint256 duration;
    }
    struct VestingEntryWithID {
        uint64 endTime;
        uint256 escrowAmount;
        uint256 entryID;
    }
}

interface IRewardEscrow {
    // Views
    function getKwentaAddress() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function numVestingEntries(address account) external view returns (uint256);

    function totalEscrowedAccountBalance(address account)
        external
        view
        returns (uint256);

    function totalVestedAccountBalance(address account)
        external
        view
        returns (uint256);

    function getVestingQuantity(address account, uint256[] calldata entryIDs)
        external
        view
        returns (uint256, uint256);

    function getVestingSchedules(
        address account,
        uint256 index,
        uint256 pageSize
    ) external view returns (VestingEntries.VestingEntryWithID[] memory);

    function getAccountVestingEntryIDs(
        address account,
        uint256 index,
        uint256 pageSize
    ) external view returns (uint256[] memory);

    function getVestingEntryClaimable(address account, uint256 entryID)
        external
        view
        returns (uint256, uint256);

    function getVestingEntry(address account, uint256 entryID)
        external
        view
        returns (
            uint64,
            uint256,
            uint256
        );

    // Mutative functions
    function vest(uint256[] calldata entryIDs) external;

    function createEscrowEntry(
        address beneficiary,
        uint256 deposit,
        uint256 duration
    ) external;

    function appendVestingEntry(
        address account,
        uint256 quantity,
        uint256 duration
    ) external;

    function stakeEscrow(uint256 _amount) external;

    function unstakeEscrow(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingRewards {
    /// VIEWS
    // token state
    function totalSupply() external view returns (uint256);
    // staking state
    function balanceOf(address account) external view returns (uint256);
    function escrowedBalanceOf(address account) external view returns (uint256);
    function nonEscrowedBalanceOf(address account) external view returns (uint256);
    // rewards
    function getRewardForDuration() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function lastTimeRewardApplicable() external view returns (uint256);
    function earned(address account) external view returns (uint256);

    /// MUTATIVE
    // Staking/Unstaking
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function stakeEscrow(address account, uint256 amount) external;
    function unstakeEscrow(address account, uint256 amount) external;
    function exit() external;
    // claim rewards
    function getReward() external;
    // settings
    function notifyRewardAmount(uint256 reward) external;
    function setRewardsDuration(uint256 _rewardsDuration) external;
    // pausable
    function pauseStakingRewards() external;
    function unpauseStakingRewards() external;
    // misc.
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/libraries/safedecimalmath
library SafeDecimalMath {
    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 public constant UNIT = 10**uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 public constant PRECISE_UNIT = 10**uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
        10**uint256(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint256) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return (x * y) / UNIT;
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return (x * UNIT) / y;
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint256 i)
        internal
        pure
        returns (uint256)
    {
        return i * UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR;
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint256 i)
        internal
        pure
        returns (uint256)
    {
        uint256 quotientTimesTen = i /
            (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    // Computes `a - b`, setting the value to 0 if b > a.
    function floorsub(uint256 a, uint256 b) internal pure returns (uint256) {
        return b >= a ? 0 : a - b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// Inheritance
import "./utils/Owned.sol";
import "./interfaces/IRewardEscrow.sol";

// Libraries
import "./libraries/SafeDecimalMath.sol";

// Internal references
import "./interfaces/IKwenta.sol";
import "./interfaces/IStakingRewards.sol";

contract RewardEscrow is Owned, IRewardEscrow {
    using SafeDecimalMath for uint;

    /* ========== CONSTANTS/IMMUTABLES ========== */

    /* Max escrow duration */
    uint public constant MAX_DURATION = 2 * 52 weeks; // Default max 2 years duration

    IKwenta private immutable kwenta;

    /* ========== STATE VARIABLES ========== */

    IStakingRewards public stakingRewards;

    mapping(address => mapping(uint256 => VestingEntries.VestingEntry)) public vestingSchedules;

    mapping(address => uint256[]) public accountVestingEntryIDs;

    // Counter for new vesting entry ids 
    uint256 public nextEntryId;

    // An account's total escrowed KWENTA balance to save recomputing this for fee extraction purposes
    mapping(address => uint256) override public totalEscrowedAccountBalance;

    // An account's total vested reward KWENTA 
    mapping(address => uint256) override public totalVestedAccountBalance;

    // The total remaining escrowed balance, for verifying the actual KWENTA balance of this contract against
    uint256 public totalEscrowedBalance;

    // notice treasury address may change
    address public treasuryDAO;

    /* ========== MODIFIERS ========== */
    modifier onlyStakingRewards() {
        require(msg.sender == address(stakingRewards), "Only the StakingRewards can perform this action");
        _;
    }

    /* ========== EVENTS ========== */
    event Vested(address indexed beneficiary, uint value);
    event VestingEntryCreated(address indexed beneficiary, uint value, uint duration, uint entryID);
    event StakingRewardsSet(address stakingRewards);
    event TreasuryDAOSet(address treasuryDAO);

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner, address _kwenta) Owned(_owner) {
        nextEntryId = 1;

        // set the Kwenta contract address as we need to transfer KWENTA when the user vests
        kwenta = IKwenta(_kwenta);
    }

    /* ========== SETTERS ========== */

    /*
    * @notice Function used to define the StakingRewards to use
    */
    function setStakingRewards(address _stakingRewards) public onlyOwner {
        require(address(stakingRewards) == address(0), "Staking Rewards already set");
        stakingRewards = IStakingRewards(_stakingRewards);
        emit StakingRewardsSet(address(_stakingRewards));
    }

    /// @notice set treasuryDAO address
    /// @dev only owner may change address
    function setTreasuryDAO(address _treasuryDAO) external onlyOwner {
        require(_treasuryDAO != address(0), "RewardEscrow: Zero Address");
        treasuryDAO = _treasuryDAO;
        emit TreasuryDAOSet(treasuryDAO);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice helper function to return kwenta address
     */
    function getKwentaAddress() override external view returns (address) {
        return address(kwenta);
    }

    /**
     * @notice A simple alias to totalEscrowedAccountBalance: provides ERC20 balance integration.
     */
    function balanceOf(address account) override public view returns (uint) {
        return totalEscrowedAccountBalance[account];
    }

    /**
     * @notice The number of vesting dates in an account's schedule.
     */
    function numVestingEntries(address account) override external view returns (uint) {
        return accountVestingEntryIDs[account].length;
    }

    /**
     * @notice Get a particular schedule entry for an account.
     * @return endTime the vesting entry object 
     * @return escrowAmount rate per second emission.
     */
    function getVestingEntry(address account, uint256 entryID) override external view returns (uint64 endTime, uint256 escrowAmount, uint256 duration) {
        endTime = vestingSchedules[account][entryID].endTime;
        escrowAmount = vestingSchedules[account][entryID].escrowAmount;
        duration = vestingSchedules[account][entryID].duration;
    }

    function getVestingSchedules(
        address account,
        uint256 index,
        uint256 pageSize
    ) override external view returns (VestingEntries.VestingEntryWithID[] memory) {
        uint256 endIndex = index + pageSize;

        // If index starts after the endIndex return no results
        if (endIndex <= index) {
            return new VestingEntries.VestingEntryWithID[](0);
        }

        // If the page extends past the end of the accountVestingEntryIDs, truncate it.
        if (endIndex > accountVestingEntryIDs[account].length) {
            endIndex = accountVestingEntryIDs[account].length;
        }

        uint256 n = endIndex - index;
        VestingEntries.VestingEntryWithID[] memory vestingEntries = new VestingEntries.VestingEntryWithID[](n);
        for (uint256 i; i < n; i++) {
            uint256 entryID = accountVestingEntryIDs[account][i + index];

            VestingEntries.VestingEntry memory entry = vestingSchedules[account][entryID];

            vestingEntries[i] = VestingEntries.VestingEntryWithID({
                endTime: uint64(entry.endTime),
                escrowAmount: entry.escrowAmount,
                entryID: entryID
            });
        }
        return vestingEntries;
    }

    function getAccountVestingEntryIDs(
        address account,
        uint256 index,
        uint256 pageSize
    ) override external view returns (uint256[] memory) {
        uint256 endIndex = index + pageSize;

        // If the page extends past the end of the accountVestingEntryIDs, truncate it.
        if (endIndex > accountVestingEntryIDs[account].length) {
            endIndex = accountVestingEntryIDs[account].length;
        }
        if (endIndex <= index) {
            return new uint256[](0);
        }

        uint256 n = endIndex - index;
        uint256[] memory page = new uint256[](n);
        for (uint256 i; i < n; i++) {
            page[i] = accountVestingEntryIDs[account][i + index];
        }
        return page;
    }

    function getVestingQuantity(address account, uint256[] calldata entryIDs) override external view returns (uint total, uint totalFee) {
        for (uint i = 0; i < entryIDs.length; i++) {
            VestingEntries.VestingEntry memory entry = vestingSchedules[account][entryIDs[i]];

            /* Skip entry if escrowAmount == 0 */
            if (entry.escrowAmount != 0) {
                (uint256 quantity, uint256 fee) = _claimableAmount(entry);

                /* add quantity to total */
                total += quantity;
                totalFee += fee;
            }
        }
    }

    function getVestingEntryClaimable(address account, uint256 entryID) override external view returns (uint quantity, uint fee) {
        VestingEntries.VestingEntry memory entry = vestingSchedules[account][entryID];
        (quantity, fee) = _claimableAmount(entry);
    }

    function _claimableAmount(VestingEntries.VestingEntry memory _entry) internal view returns (uint256 quantity, uint256 fee) {
        uint256 escrowAmount = _entry.escrowAmount;

        if (escrowAmount != 0) {
            /* Full escrow amounts claimable if block.timestamp equal to or after entry endTime */
            if (block.timestamp >= _entry.endTime) {
                quantity = escrowAmount;
            } else {
                fee = _earlyVestFee(_entry);
                quantity = escrowAmount - fee;
            }
        }
    }

    function _earlyVestFee(VestingEntries.VestingEntry memory _entry) internal view returns (uint256 earlyVestFee) {
        uint timeUntilVest = _entry.endTime - block.timestamp;
        // Fee starts at 90% and falls linearly
        uint initialFee = _entry.escrowAmount * 9 / 10;
        earlyVestFee = initialFee * timeUntilVest / _entry.duration;
    }

    function _isEscrowStaked(address _account) internal view returns (bool) {
        return stakingRewards.escrowedBalanceOf(_account) > 0;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * Vest escrowed amounts that are claimable
     * Allows users to vest their vesting entries based on msg.sender
     */

    function vest(uint256[] calldata entryIDs) override external {
        uint256 total;
        uint256 totalFee;
        for (uint i = 0; i < entryIDs.length; i++) {
            VestingEntries.VestingEntry storage entry = vestingSchedules[msg.sender][entryIDs[i]];

            /* Skip entry if escrowAmount == 0 already vested */
            if (entry.escrowAmount != 0) {
                (uint256 quantity, uint256 fee) = _claimableAmount(entry);

                /* update entry to remove escrowAmount */
                entry.escrowAmount = 0;

                /* add quantity to total */
                total += quantity;
                totalFee += fee;
            }
        }

        /* Transfer vested tokens. Will revert if total > totalEscrowedAccountBalance */
        if (total != 0) {
            // Withdraw staked escrowed kwenta if needed for reward
            if (_isEscrowStaked(msg.sender)) {
                uint totalWithFee = total + totalFee;
                uint unstakedEscrow = totalEscrowedAccountBalance[msg.sender] - stakingRewards.escrowedBalanceOf(msg.sender);
                if (totalWithFee > unstakedEscrow) {
                    uint amountToUnstake = totalWithFee - unstakedEscrow;
                    unstakeEscrow(amountToUnstake);
                }
            }

            // Send any fee to Treasury
            if (totalFee != 0) {
                _reduceAccountEscrowBalances(msg.sender, totalFee);
                require(
                    IKwenta(address(kwenta))
                        .transfer(treasuryDAO, totalFee), 
                        "RewardEscrow: Token Transfer Failed"
                );
            }

            // Transfer kwenta
            _transferVestedTokens(msg.sender, total);
        }
        
    }

    /**
     * @notice Create an escrow entry to lock KWENTA for a given duration in seconds
     * @dev This call expects that the depositor (msg.sender) has already approved the Reward escrow contract
     * to spend the the amount being escrowed.
     */
    function createEscrowEntry(
        address beneficiary,
        uint256 deposit,
        uint256 duration
    ) override external {
        require(beneficiary != address(0), "Cannot create escrow with address(0)");

        /* Transfer KWENTA from msg.sender */
        require(kwenta.transferFrom(msg.sender, address(this), deposit), "Token transfer failed");

        /* Append vesting entry for the beneficiary address */
        _appendVestingEntry(beneficiary, deposit, duration);
    }

    /**
     * @notice Add a new vesting entry at a given time and quantity to an account's schedule.
     * @dev A call to this should accompany a previous successful call to kwenta.transfer(rewardEscrow, amount),
     * to ensure that when the funds are withdrawn, there is enough balance.
     * @param account The account to append a new vesting entry to.
     * @param quantity The quantity of KWENTA that will be escrowed.
     * @param duration The duration that KWENTA will be emitted.
     */
    function appendVestingEntry(
        address account,
        uint256 quantity,
        uint256 duration
    ) override external onlyStakingRewards {
        _appendVestingEntry(account, quantity, duration);
    }

    /**
     * @notice Stakes escrowed KWENTA.
     * @dev No tokens are transfered during this process, but the StakingRewards escrowed balance is updated.
     * @param _amount The amount of escrowed KWENTA to be staked.
     */
    function stakeEscrow(uint256 _amount) override external {
        require(_amount + stakingRewards.escrowedBalanceOf(msg.sender) <= totalEscrowedAccountBalance[msg.sender], "Insufficient unstaked escrow");
        stakingRewards.stakeEscrow(msg.sender, _amount);
    }

    /**
     * @notice Unstakes escrowed KWENTA.
     * @dev No tokens are transfered during this process, but the StakingRewards escrowed balance is updated.
     * @param _amount The amount of escrowed KWENTA to be unstaked.
     */
    function unstakeEscrow(uint256 _amount) override public {
        stakingRewards.unstakeEscrow(msg.sender, _amount);
    }

    /* Transfer vested tokens and update totalEscrowedAccountBalance, totalVestedAccountBalance */
    function _transferVestedTokens(address _account, uint256 _amount) internal {
        _reduceAccountEscrowBalances(_account, _amount);
        totalVestedAccountBalance[_account] += _amount;
        kwenta.transfer(_account, _amount);
        emit Vested(_account, _amount);
    }

    function _reduceAccountEscrowBalances(address _account, uint256 _amount) internal {
        // Reverts if amount being vested is greater than the account's existing totalEscrowedAccountBalance
        totalEscrowedBalance -= _amount;
        totalEscrowedAccountBalance[_account] -= _amount;
    }

    /* ========== INTERNALS ========== */

    function _appendVestingEntry(
        address account,
        uint256 quantity,
        uint256 duration
    ) internal {
        /* No empty or already-passed vesting entries allowed. */
        require(quantity != 0, "Quantity cannot be zero");
        require(duration > 0 && duration <= MAX_DURATION, "Cannot escrow with 0 duration OR above max_duration");

        /* There must be enough balance in the contract to provide for the vesting entry. */
        totalEscrowedBalance += quantity;

        require(
            totalEscrowedBalance <= kwenta.balanceOf(address(this)),
            "Must be enough balance in the contract to provide for the vesting entry"
        );

        /* Escrow the tokens for duration. */
        uint endTime = block.timestamp + duration;

        /* Add quantity to account's escrowed balance */
        totalEscrowedAccountBalance[account] += quantity;

        uint entryID = nextEntryId;
        vestingSchedules[account][entryID] = VestingEntries.VestingEntry({endTime: uint64(endTime), escrowAmount: quantity, duration: duration});

        accountVestingEntryIDs[account].push(entryID);

        /* Increment the next entry id. */
        nextEntryId++;

        emit VestingEntryCreated(account, quantity, duration, entryID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}