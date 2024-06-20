// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.25;

import { BoostedStaker } from "contracts/BoostedStaker.sol";
import { Ownable, Ownable2Step } from "contracts/access/Ownable2Step.sol";

/**
    @notice Boosted Staker Factory
    @author Yearn (with edits by defidotmoney)
 */
contract StakerFactory is Ownable2Step {
    uint256 public immutable EPOCH_DAYS;
    uint256 public immutable STAKE_GROWTH_EPOCHS;
    uint256 public immutable START_TIME;

    mapping(address token => address staker) public boostedStakers;

    bool public isLockingEnabled;

    event BoostedStakerDeployed(address token, address boostedStaker);
    event LocksDisabled();

    constructor(uint256 epochDays, uint256 stakeGrowthEpochs) Ownable(msg.sender) {
        require(stakeGrowthEpochs > 0 && stakeGrowthEpochs < 16, "DFM:BSF STAKE_GROWTH_EPOCHS");

        EPOCH_DAYS = epochDays;
        STAKE_GROWTH_EPOCHS = stakeGrowthEpochs;

        // ensure start time is at 12:00 UTC
        uint256 startTime = (block.timestamp / 1 days) * 1 days;
        if (block.timestamp >= startTime + 12 hours) startTime += 12 hours;
        else startTime -= 12 hours;
        START_TIME = startTime;

        isLockingEnabled = true;
    }

    /**
        @notice Deploy a new `BoostedStaker` contract
        @dev We use CREATE2 to generate deterministic deployments based on `token`
    */
    function deployBoostedStaker(address token, uint maxWeightMultiplier) external onlyOwner returns (address) {
        require(boostedStakers[token] == address(0), "DFM:BSF Already deployed");
        require(maxWeightMultiplier > 1 && maxWeightMultiplier < 256, "DFM:BSF MAX_WEIGHT_MULTIPLIER");

        uint256 salt = uint256(uint160(token));
        bytes memory bytecodeWithArgs = abi.encodePacked(
            type(BoostedStaker).creationCode,
            abi.encode(token, STAKE_GROWTH_EPOCHS, maxWeightMultiplier, START_TIME, EPOCH_DAYS)
        );

        address deployedAddress;
        assembly {
            deployedAddress := create2(0, add(bytecodeWithArgs, 0x20), mload(bytecodeWithArgs), salt)
        }
        require(deployedAddress != address(0), "DFM:BSF Deployment failed");

        boostedStakers[token] = deployedAddress;
        emit BoostedStakerDeployed(token, deployedAddress);
        return deployedAddress;
    }

    /**
        @notice Disable locks in all booster contracts
        @dev Allows immediate withdrawal for all depositors. Used when sunsetting
             the staker system. This action cannot be undone.
     */
    function disableLocksGlobally() external onlyOwner {
        isLockingEnabled = false;
        emit LocksDisabled();
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

import { IERC20, SafeERC20 } from "contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IFactory } from "contracts/interfaces/IFactory.sol";

/**
    @notice Boosted Staker
    @author Yearn (with edits by defidotmoney)
 */
contract BoostedStaker {
    using SafeERC20 for IERC20;

    uint256 private constant MAX_EPOCHS = 65535;
    uint16 private immutable MAX_EPOCH_BIT;
    uint256 public immutable STAKE_GROWTH_EPOCHS;
    uint256 public immutable MAX_WEIGHT_MULTIPLIER;
    uint256 public immutable START_TIME;
    uint256 public immutable EPOCH_LENGTH;
    IERC20 public immutable STAKE_TOKEN;
    IFactory public immutable FACTORY;

    // Account weight tracking state vars.
    mapping(address account => AccountData data) private accountData;
    mapping(address account => uint128[MAX_EPOCHS]) private accountEpochWeights;
    mapping(address account => ToRealize[MAX_EPOCHS] weight) private accountEpochToRealize;

    mapping(address account => mapping(address caller => bool approvalStatus)) public isApprovedUnstaker;

    // Global weight tracking stats vars.
    uint128[MAX_EPOCHS] private globalEpochWeights;
    uint128[MAX_EPOCHS] public globalEpochToRealize;
    uint112 public globalGrowthRate;
    uint16 public globalLastUpdateEpoch;

    uint120 public totalSupply;

    bool private locksEnabled;

    struct AccountData {
        uint112 realizedStake; // Amount of stake that has fully realized weight.
        uint112 pendingStake; // Amount of stake that has not yet fully realized weight.
        uint112 lockedStake; // Amount of stake that has fully realized weight, but cannot be withdrawn.
        uint16 lastUpdateEpoch; // Epoch of last sync.
        // Two byte member to represent epochs in which an account has pending weight changes.
        // A bit is set to true when the account has a non-zero token balance to be realized in
        // the corresponding epoch. We use this as a "map", allowing us to reduce gas consumption
        // by avoiding unnecessary lookups on epochs which an account has zero pending stake.
        //
        // Example: 0100000000000101
        // The least significant bit represents the first epoch of pendingStake.
        // Therefore, we can see that account has stake updates to process only in epochs 1, 3 and 15.
        uint16 updateEpochBitmap;
    }

    struct ToRealize {
        uint128 pending;
        uint128 locked;
    }

    struct AccountView {
        uint256 balance;
        uint256 weight;
        uint256 realizedStake;
        uint256 pendingStake;
        uint256 lockedStake;
    }

    struct FutureRealizedStake {
        uint256 epochsToMaturity;
        uint256 timestampAtMaturity;
        uint256 pendingStake;
        uint256 lockedStake;
    }

    event Staked(address indexed account, uint256 indexed epoch, uint256 amount, uint256 weightAdded, bool isLocked);
    event Unstaked(address indexed account, uint256 indexed epoch, uint256 amount, uint256 weightRemoved);
    event AccountWeightUpdated(address indexed account, uint256 indexed epoch, uint256 timestamp, uint256 newWeight);
    event ApprovedUnstakerSet(address indexed account, address indexed caller, bool isApproved);
    event LocksDisabled();

    /**
        @dev Not intended for direct deployment, use `StakerFactory.deployBoostedStaker`
    */
    constructor(
        IERC20 token,
        uint256 stakeGrowthEpochs,
        uint256 maxWeightMultiplier,
        uint256 startTime,
        uint256 epochDays
    ) {
        FACTORY = IFactory(msg.sender);
        STAKE_TOKEN = token;
        STAKE_GROWTH_EPOCHS = stakeGrowthEpochs;
        MAX_WEIGHT_MULTIPLIER = maxWeightMultiplier;
        MAX_EPOCH_BIT = uint16(1 << STAKE_GROWTH_EPOCHS);
        EPOCH_LENGTH = epochDays * 1 days;
        START_TIME = startTime;

        locksEnabled = true;
    }

    modifier onlyOwner() {
        require(msg.sender == FACTORY.owner(), "DFM:BS Not authorized");
        _;
    }

    /// ----- External view functions -----

    function getEpoch() public view returns (uint256 epoch) {
        unchecked {
            return (block.timestamp - START_TIME) / EPOCH_LENGTH;
        }
    }

    function isLockingEnabled() public view returns (bool) {
        if (!locksEnabled) return false;
        return FACTORY.isLockingEnabled();
    }

    /**
        @notice Returns the balance of underlying staked tokens for an account
        @param _account Account to query balance.
        @return balance of account.
    */
    function balanceOf(address _account) external view returns (uint256) {
        AccountData memory acctData = accountData[_account];
        return (acctData.pendingStake + acctData.realizedStake + acctData.lockedStake);
    }

    /**
        @notice View function to get the current weight for an account
    */
    function getAccountWeight(address account) external view returns (uint256) {
        return getAccountWeightAt(account, getEpoch());
    }

    /**
        @notice Get the weight for an account in a given epoch
    */
    function getAccountWeightAt(address _account, uint256 _epoch) public view returns (uint256) {
        if (_epoch > getEpoch()) return 0;

        AccountData memory acctData = accountData[_account];

        uint16 lastUpdateEpoch = acctData.lastUpdateEpoch;

        if (lastUpdateEpoch >= _epoch) return accountEpochWeights[_account][_epoch];

        uint256 weight = accountEpochWeights[_account][lastUpdateEpoch];

        uint256 pending = uint256(acctData.pendingStake);
        if (pending == 0) return weight;

        uint16 bitmap = acctData.updateEpochBitmap;

        while (lastUpdateEpoch < _epoch) {
            // Populate data for missed epochs
            unchecked {
                lastUpdateEpoch++;
            }
            weight += _getWeightGrowth(pending, 1);

            // Our bitmap is used to determine if epoch has any amount to realize.
            bitmap = bitmap << 1;
            if (bitmap & MAX_EPOCH_BIT == MAX_EPOCH_BIT) {
                // If left-most bit is true, we have something to realize; push pending to realized.
                pending -= accountEpochToRealize[_account][lastUpdateEpoch].pending;
                if (pending == 0) break; // All pending has now been realized, let's exit.
            }
        }

        return weight;
    }

    /**
        @notice Get a detailed view of staked balances and weight for `account`
        @return accountView Detailed information on account weight and balances:
                 * total deposited balance
                 * current weight
                 * realized stake (balance receiving maximum weight)
                 * pending stake (balance where weight is still increasing)
                 * locked stake (max weight, but cannot be withdrawn)
        @return futureRealizedStake Array detailing pending and locked stake balances:
                 * number of epochs remaining until balances convert to realized
                 * timestamp when balances are realized
                 * pending balance to be realized in this epoch
                 * locked balance to be realized in this epoch
     */
    function getAccountFullView(
        address account
    ) external view returns (AccountView memory accountView, FutureRealizedStake[] memory futureRealizedStake) {
        uint256 systemEpoch = getEpoch();

        AccountData storage acctData = accountData[account];
        uint256 lastUpdateEpoch = acctData.lastUpdateEpoch;

        accountView.pendingStake = acctData.pendingStake;
        accountView.lockedStake = acctData.lockedStake;
        accountView.realizedStake = acctData.realizedStake;
        accountView.weight = accountEpochWeights[account][lastUpdateEpoch];
        accountView.balance = acctData.pendingStake + acctData.lockedStake + acctData.realizedStake;

        if (accountView.lockedStake > 0 && !isLockingEnabled()) {
            accountView.realizedStake += accountView.lockedStake;
            accountView.lockedStake = 0;
        }

        if (accountView.pendingStake + accountView.lockedStake > 0) {
            uint16 bitmap = acctData.updateEpochBitmap;
            uint256 targetSyncEpoch = min(systemEpoch, lastUpdateEpoch + STAKE_GROWTH_EPOCHS);

            // Populate data for missed epochs
            while (lastUpdateEpoch < targetSyncEpoch) {
                unchecked {
                    lastUpdateEpoch++;
                }
                accountView.weight += _getWeightGrowth(accountView.pendingStake, 1);

                // Shift left on bitmap as we pass over each epoch.
                bitmap = bitmap << 1;
                if (bitmap & MAX_EPOCH_BIT == MAX_EPOCH_BIT) {
                    // If left-most bit is true, we have something to realize; push pending to realized.
                    // Do any updates needed to realize an amount for an account.
                    ToRealize memory epochRealized = accountEpochToRealize[account][lastUpdateEpoch];
                    accountView.pendingStake -= epochRealized.pending;
                    accountView.realizedStake += epochRealized.pending;

                    if (accountView.lockedStake > 0) {
                        // skip if `locked == 0` to avoid issues after disabling locks
                        accountView.lockedStake -= epochRealized.locked;
                        accountView.realizedStake += epochRealized.locked;
                    }

                    if (accountView.pendingStake == 0 && accountView.lockedStake == 0) break;
                }
            }

            lastUpdateEpoch = systemEpoch;
            futureRealizedStake = new FutureRealizedStake[](STAKE_GROWTH_EPOCHS);
            uint256 length = 0;
            while (bitmap != 0) {
                lastUpdateEpoch++;
                bitmap = bitmap << 1;
                if (bitmap & MAX_EPOCH_BIT == MAX_EPOCH_BIT) {
                    ToRealize memory epochRealized = accountEpochToRealize[account][lastUpdateEpoch];
                    futureRealizedStake[length] = FutureRealizedStake({
                        epochsToMaturity: lastUpdateEpoch - systemEpoch,
                        timestampAtMaturity: START_TIME + (lastUpdateEpoch * EPOCH_LENGTH),
                        pendingStake: epochRealized.pending,
                        lockedStake: epochRealized.locked
                    });
                    length++;
                }
            }
            // reduce length of `futureRealizedStake` prior to returning
            assembly {
                mstore(futureRealizedStake, length)
            }
        }
    }

    /**
        @notice Get the system weight for current epoch.
    */
    function getGlobalWeight() external view returns (uint256) {
        return getGlobalWeightAt(getEpoch());
    }

    /**
        @notice Get the system weight for a specified epoch in the past.
        @dev querying a epoch in the future will always return 0.
        @param epoch the epoch number to query global weight for.
    */
    function getGlobalWeightAt(uint256 epoch) public view returns (uint256) {
        uint256 systemEpoch = getEpoch();
        if (epoch > systemEpoch) return 0;

        // Read these together since they are packed in the same slot.
        uint16 lastUpdateEpoch = globalLastUpdateEpoch;
        uint256 rate = globalGrowthRate;

        if (epoch <= lastUpdateEpoch) return globalEpochWeights[epoch];

        uint256 weight = globalEpochWeights[lastUpdateEpoch];
        if (rate == 0) {
            return weight;
        }

        while (lastUpdateEpoch < epoch) {
            unchecked {
                lastUpdateEpoch++;
            }

            weight += _getWeightGrowth(rate, 1);
            rate -= globalEpochToRealize[lastUpdateEpoch];
        }

        return weight;
    }

    /// ----- Unguarded nonpayable functions -----

    /**
        @notice Allow another address to unstake on behalf of the caller.
                Useful for zaps and other functionality.
        @param _caller Address of the caller to approve or unapprove.
        @param isApproved is `_caller` approved?
    */
    function setApprovedUnstaker(address _caller, bool isApproved) external {
        isApprovedUnstaker[msg.sender][_caller] = isApproved;
        emit ApprovedUnstakerSet(msg.sender, _caller, isApproved);
    }

    /**
        @notice Stake tokens into the staking contract.
        @param _amount Amount of tokens to stake.
    */
    function stake(address _account, uint256 _amount) external {
        _stake(_account, _amount, false);
    }

    /**
        @notice Lock tokens in the staking contract.
        @dev Locked tokens receive maximum boost immediately, but cannot be
             withdrawn until `STAKE_GROWTH_EPOCHS` have passed. The only
             exception is if the contract owner disables locks.
        @param _amount Amount of tokens to lock.
    */
    function lock(address _account, uint256 _amount) external {
        require(isLockingEnabled(), "DFM:BS Locks are disabled");
        _stake(_account, _amount, true);
    }

    /**
        @notice Unstake tokens from the contract.
        @dev In a partial restake, tokens giving the least weight are withdrawn first.
    */
    function unstake(address _account, uint256 _amount, address _receiver) external {
        require(_amount > 0, "DFM:BS Cannot unstake 0");

        if (msg.sender != _account) {
            require(isApprovedUnstaker[_account][msg.sender], "DFM:BS Not approved unstaker");
        }

        // Before going further, let's sync our account and global weights
        uint256 systemEpoch = getEpoch();
        (AccountData memory acctData, ) = _checkpointAccount(_account, systemEpoch);
        _checkpointGlobal(systemEpoch);

        require(acctData.realizedStake + acctData.pendingStake >= _amount, "DFM:BS Insufficient balance");

        // Here we do work to pull from most recent (least weighted) stake first
        uint16 bitmap = acctData.updateEpochBitmap;
        uint256 weightToRemove;

        uint128 amountNeeded = uint128(_amount);
        ToRealize[MAX_EPOCHS] storage epochToRealize = accountEpochToRealize[_account];

        if (bitmap > 0) {
            for (uint128 epochIndex; epochIndex < STAKE_GROWTH_EPOCHS; ) {
                // Move right to left, checking each bit if there's an update for corresponding epoch.
                uint16 mask = uint16(1 << epochIndex);
                if (bitmap & mask == mask) {
                    uint256 epochToCheck = systemEpoch + STAKE_GROWTH_EPOCHS - epochIndex;
                    uint128 pending = epochToRealize[epochToCheck].pending;
                    if (pending > 0) {
                        if (amountNeeded > pending) {
                            weightToRemove += _getWeight(pending, epochIndex);
                            epochToRealize[epochToCheck].pending = 0;
                            globalEpochToRealize[epochToCheck] -= pending;
                            amountNeeded -= pending;
                            if (epochToRealize[epochToCheck].locked == 0) bitmap = bitmap ^ mask;
                        } else {
                            // handle the case where we have more pending than needed
                            weightToRemove += _getWeight(amountNeeded, epochIndex);
                            epochToRealize[epochToCheck].pending = pending - amountNeeded;
                            globalEpochToRealize[epochToCheck] -= amountNeeded;
                            if (amountNeeded == pending && epochToRealize[epochToCheck].locked == 0) {
                                bitmap = bitmap ^ mask;
                            }
                            amountNeeded = 0;
                            break;
                        }
                    }
                }
                unchecked {
                    epochIndex++;
                }
            }
            acctData.updateEpochBitmap = bitmap;
        }

        uint256 pendingRemoved = _amount - amountNeeded;
        if (amountNeeded > 0) {
            weightToRemove += _getWeight(amountNeeded, STAKE_GROWTH_EPOCHS);
            acctData.realizedStake -= uint112(amountNeeded);
            acctData.pendingStake = 0;
        } else {
            acctData.pendingStake -= uint112(pendingRemoved);
        }

        accountData[_account] = acctData;

        uint256 newAccountWeight = accountEpochWeights[_account][systemEpoch];
        if (newAccountWeight < weightToRemove) weightToRemove = newAccountWeight;
        newAccountWeight = newAccountWeight - weightToRemove;
        accountEpochWeights[_account][systemEpoch] = uint128(newAccountWeight);

        globalGrowthRate -= uint112(pendingRemoved);
        globalEpochWeights[systemEpoch] -= uint128(weightToRemove);

        totalSupply -= uint120(_amount);

        emit Unstaked(_account, systemEpoch, _amount, weightToRemove);
        emit AccountWeightUpdated(_account, systemEpoch, block.timestamp, newAccountWeight);

        STAKE_TOKEN.safeTransfer(_receiver, _amount);
    }

    /**
        @notice Checkpoint an account and get the account's current weight
        @dev Prefer to use this function over it's view counterpart for
             contract -> contract interactions.
        @param _account Account to checkpoint.
        @return weight Most current account weight.

    */
    function checkpointAccount(address _account) external returns (uint256 weight) {
        AccountData memory acctData;
        (acctData, weight) = _checkpointAccount(_account, getEpoch());
        accountData[_account] = acctData;
        return weight;
    }

    /**
        @notice Checkpoint an account using a specified epoch limit.
        @dev    To use in the event that significant number of epochs have passed since last
                checkpoint and single call becomes too expensive.
        @param _account Account to checkpoint.
        @param _epoch Epoch which we want to checkpoint to.
        @return weight Account weight at most recently checkpointed epoch.
                       If the account weight was checkpointed more recently than
                       `_epoch` this value will be the current weight, not the
                       weight at _epoch`.
    */
    function checkpointAccountWithLimit(address _account, uint256 _epoch) external returns (uint256 weight) {
        uint256 systemEpoch = getEpoch();
        if (_epoch >= systemEpoch) _epoch = systemEpoch;
        AccountData memory acctData;
        (acctData, weight) = _checkpointAccount(_account, _epoch);
        accountData[_account] = acctData;
        return weight;
    }

    /**
        @notice Checkpoint the total system weight using a specified epoch limit.
        @dev    To use in the event that significant number of epochs have passed since last
                checkpoint and single call becomes too expensive.
        @param _epoch Epoch which we want to checkpoint to.
        @return weight Total system weight at most recently checkpointed epoch.
                       If the system weight was checkpointed more recently than
                       `_epoch` this value will be the current weight, not the
                       weight at _epoch`.
    */
    function checkpointGlobalWithLimit(uint256 _epoch) external returns (uint256 weight) {
        uint256 systemEpoch = getEpoch();
        if (_epoch > systemEpoch) _epoch = systemEpoch;
        return _checkpointGlobal(_epoch);
    }

    /**
        @notice Get the current total system weight
        @dev Also updates local storage values for total weights. Using
             this function over it's `view` counterpart is preferred for
             contract -> contract interactions.
    */
    function checkpointGlobal() external returns (uint256) {
        uint256 systemEpoch = getEpoch();
        return _checkpointGlobal(systemEpoch);
    }

    /// ----- Owner-only nonpayable functions -----

    /**
        @notice Disable locks in this contract
        @dev Allows immediate withdrawal for all depositors. Cannot be undone.
     */
    function disableLocks() external onlyOwner {
        locksEnabled = false;
        emit LocksDisabled();
    }

    function sweep(IERC20 token, address receiver) external onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        if (token == STAKE_TOKEN) {
            amount = amount - totalSupply;
        }
        if (amount > 0) token.safeTransfer(receiver, amount);
    }

    /// ----- Internal functions -----

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /** @dev The increased weight from `amount` after a number of epochs has passed */
    function _getWeightGrowth(uint256 amount, uint256 epochs) internal view returns (uint128 growth) {
        amount *= MAX_WEIGHT_MULTIPLIER - 1;
        // division before multiplication is intentional to ensure consistent rounding loss each epoch
        // otherwise there is a possibility for an underflow when the last user unstakes
        return uint128((amount / STAKE_GROWTH_EPOCHS) * epochs);
    }

    /** @dev The total weight of `amount` after a number of epochs has passed */
    function _getWeight(uint256 amount, uint256 epochs) internal view returns (uint256 weight) {
        uint256 growth = _getWeightGrowth(amount, epochs);
        return amount + growth;
    }

    function _stake(address _account, uint256 _amount, bool isLocked) internal {
        require(_amount > 0, "DFM:BS Cannot stake 0");

        uint256 newTotalSupply = totalSupply + _amount;
        require(newTotalSupply < type(uint112).max, "DFM:BS Amount too large");
        totalSupply = uint120(newTotalSupply);

        // Before going further, let's sync our account and global weights
        uint256 systemEpoch = getEpoch();
        (AccountData memory acctData, uint256 accountWeight) = _checkpointAccount(_account, systemEpoch);
        uint128 globalWeight = uint128(_checkpointGlobal(systemEpoch));

        uint256 realizeEpoch = systemEpoch + STAKE_GROWTH_EPOCHS;

        uint256 weight;
        if (isLocked) {
            weight = _getWeight(_amount, STAKE_GROWTH_EPOCHS);
            acctData.lockedStake += uint112(_amount);

            accountEpochToRealize[_account][realizeEpoch].locked += uint128(_amount);
        } else {
            weight = _amount;
            acctData.pendingStake += uint112(_amount);
            globalGrowthRate += uint112(_amount);

            accountEpochToRealize[_account][realizeEpoch].pending += uint128(_amount);
            globalEpochToRealize[realizeEpoch] += uint128(_amount);
        }

        accountEpochWeights[_account][systemEpoch] = uint128(accountWeight + weight);
        globalEpochWeights[systemEpoch] = uint128(globalWeight + weight);

        acctData.updateEpochBitmap |= 1; // Use bitwise or to ensure bit is flipped at least weighted position.
        accountData[_account] = acctData;

        STAKE_TOKEN.safeTransferFrom(msg.sender, address(this), uint256(_amount));

        emit Staked(_account, systemEpoch, _amount, weight, isLocked);
        emit AccountWeightUpdated(_account, systemEpoch, block.timestamp, accountWeight + weight);
    }

    function _checkpointAccount(
        address _account,
        uint256 _systemEpoch
    ) internal returns (AccountData memory acctData, uint128 weight) {
        acctData = accountData[_account];
        uint256 lastUpdateEpoch = acctData.lastUpdateEpoch;
        uint128[MAX_EPOCHS] storage epochWeights = accountEpochWeights[_account];

        uint256 pending = acctData.pendingStake;
        uint256 locked = acctData.lockedStake;
        uint256 realized = acctData.realizedStake;

        if (locked > 0 && !isLockingEnabled()) {
            realized += locked;
            locked = 0;
            acctData.realizedStake = uint112(realized);
            acctData.lockedStake = 0;
        }

        if (_systemEpoch <= lastUpdateEpoch) {
            return (acctData, epochWeights[lastUpdateEpoch]);
        }

        if (pending == 0 && locked == 0) {
            if (realized != 0) {
                weight = epochWeights[lastUpdateEpoch];
                while (lastUpdateEpoch < _systemEpoch) {
                    unchecked {
                        lastUpdateEpoch++;
                    }
                    // Fill in any missing epochs
                    epochWeights[lastUpdateEpoch] = weight;
                }
            }
            accountData[_account].lastUpdateEpoch = uint16(_systemEpoch);
            acctData.lastUpdateEpoch = uint16(_systemEpoch);
            return (acctData, weight);
        }

        weight = epochWeights[lastUpdateEpoch];
        uint16 bitmap = acctData.updateEpochBitmap;
        uint256 targetSyncEpoch = min(_systemEpoch, lastUpdateEpoch + STAKE_GROWTH_EPOCHS);

        // Populate data for missed epochs
        while (lastUpdateEpoch < targetSyncEpoch) {
            unchecked {
                lastUpdateEpoch++;
            }
            weight += _getWeightGrowth(pending, 1);
            epochWeights[lastUpdateEpoch] = weight;

            // Shift left on bitmap as we pass over each epoch.
            bitmap = bitmap << 1;
            if (bitmap & MAX_EPOCH_BIT == MAX_EPOCH_BIT) {
                // If left-most bit is true, we have something to realize; push pending to realized.
                // Do any updates needed to realize an amount for an account.
                ToRealize memory epochRealized = accountEpochToRealize[_account][lastUpdateEpoch];
                pending -= epochRealized.pending;
                realized += epochRealized.pending;

                if (locked > 0) {
                    // skip if `locked == 0` to avoid issues after disabling locks
                    locked -= epochRealized.locked;
                    realized += epochRealized.locked;
                }

                if (pending == 0 && locked == 0) break; // All pending has been realized. No need to continue.
            }
        }

        // Fill in any missed epochs.
        while (lastUpdateEpoch < _systemEpoch) {
            unchecked {
                lastUpdateEpoch++;
            }
            epochWeights[lastUpdateEpoch] = weight;
        }

        // Write new account data to storage.
        acctData = AccountData({
            updateEpochBitmap: bitmap,
            pendingStake: uint112(pending),
            realizedStake: uint112(realized),
            lockedStake: uint112(locked),
            lastUpdateEpoch: uint16(_systemEpoch)
        });
    }

    function _checkpointGlobal(uint256 systemEpoch) internal returns (uint256) {
        // These two share a storage slot.
        uint16 lastUpdateEpoch = globalLastUpdateEpoch;
        uint256 rate = globalGrowthRate;

        uint128 weight = globalEpochWeights[lastUpdateEpoch];

        if (lastUpdateEpoch >= systemEpoch) return weight;

        if (weight == 0) {
            globalLastUpdateEpoch = uint16(systemEpoch);
            return 0;
        }

        while (lastUpdateEpoch < systemEpoch) {
            unchecked {
                lastUpdateEpoch++;
            }
            weight += _getWeightGrowth(rate, 1);
            globalEpochWeights[lastUpdateEpoch] = weight;
            rate -= globalEpochToRealize[lastUpdateEpoch];
        }

        globalGrowthRate = uint112(rate);
        globalLastUpdateEpoch = uint16(systemEpoch);

        return weight;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "contracts/token/ERC20/extensions/IERC20Permit.sol";
import {Address} from "contracts/utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
    function owner() external view returns (address);

    function isLockingEnabled() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {Ownable} from "contracts/access/Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "contracts/utils/Context.sol";

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