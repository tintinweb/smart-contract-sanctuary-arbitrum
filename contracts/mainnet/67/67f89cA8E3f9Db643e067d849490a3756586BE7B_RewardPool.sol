// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/Bank/IHandleComponent.sol";
import "../interfaces/Bank/IHandle.sol";
import "../interfaces/rewards/IRewardPool.sol";
import "../Bank/Roles.sol";
import "../governance/GovernanceLock.sol";
import "./StakedErc20.sol";

/** @dev Provides scalable pools mapped by protocol reward category IDs.
 *       Categories are dynamic and may have weights adjusted as individual
 *       pools.
 *       Rewards are given in ERC20 (FOREX) and go into each category
 *       proportionally to their weights for the category users to claim.
 *       Alternatively, a specific pool may have FOREX deposited into it
 *       directly, "bypassing" the weights and automatic distribution.
 *       Pools may accept staking of:
 *         [1]: A virtual number (no underlying asset), which relies
 *              on a "staker whitelist". This is used for internal
 *              reward tracking and the stakers are other protocol
 *              contracts which stake for the users.
 *         [2]: An ERC20. Users stake an ERC20 and receive StakedErc20
 *              as a receipt/LP token representing their stake.
 *         [3]: An NFT. Not yet implemented.
 *       Pool weights may be adjusted by an external DAO voting contract
 *       that has the OPERATOR_ROLE role.
 */
contract RewardPool is
    IRewardPool,
    IHandleComponent,
    Initializable,
    UUPSUpgradeable,
    Roles,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    /** @dev The Handle contract interface */
    IHandle private handle;
    /** @dev The canonical FOREX token to be used for reward claiming.
     *       The contract assumes it always has sufficient balance to
     *       execute reward claims.
     */
    IERC20 public override forex;
    /** @dev Pool mapping from pool ID to Pool struct */
    mapping(uint256 => Pool) private pools;
    /** @dev Hash alias to pool pool ID */
    mapping(bytes32 => uint256) private poolAliases;
    /** @dev Array of enabled pools */
    uint256[] public enabledPools;
    /** @dev FOREX distribution rate per second */
    uint256 public forexDistributionRate;
    /** @dev Date at which the last distribution of FOREX happened */
    uint256 public lastDistributionDate;
    /** @dev Number of pools created */
    uint256 public poolCount;
    /** @dev The GovernanceLock contract */
    GovernanceLock governanceLock;

    /** @dev Proxy initialisation function */
    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(OPERATOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    }

    /**
     * @dev Setter for Handle contract reference
     * @param _handle The Handle contract address
     */
    function setHandleContract(address _handle) public override onlyAdmin {
        handle = IHandle(_handle);
        forex = IERC20(handle.forex());
    }

    /**
     * @dev Setter for the GovernanceLock contract reference
     * @param _governanceLock The GovernanceLock contract address
     */
    function setGovernanceLock(address _governanceLock) external onlyAdmin {
        governanceLock = GovernanceLock(_governanceLock);
    }

    /** @dev Getter for Handle contract address */
    function handleAddress() public view override returns (address) {
        return address(handle);
    }

    /**
     * @dev Stakes account into pool to start accruing rewards for pool.
     * @param account The account to stake with.
     * @param value The value to be staked.
     * @param poolId The pool ID to stake into.
     */
    function stake(
        address account,
        uint256 value,
        uint256 poolId
    ) external override nonReentrant returns (uint256 errorCode) {
        Pool storage pool = pools[poolId];
        // Check for staking permission.
        require(_canStake(account, pool), "RewardPool: unauthorised");
        require(
            pool.assetType == AssetType.None ||
                pool.assetType == AssetType.ERC20,
            "RewardPool: not yet supported"
        );
        // Try to claim before rewriting user deposit.
        _claimForAccount(account);
        // Load user deposit.
        Deposit storage deposit = pool.deposits[account];
        // Update user deposit.
        _updateDeposit(account, deposit.amount + value, poolId);
        // Mint any receipt tokens after staking as needed.
        _handleAssetsAfterStake(account, value, pool, deposit);
        emit Stake(account, poolId, value);
        return 0;
    }

    /**
     * @dev Returns the boosted stake value for an account and pool.
     * @param value The provided stake value.
     * @param totalRealDeposits The liquidity to calculate the boosted value for.
     * @param boostWeight The account's boost weight for the calculation.
     *        This is equal to the user's gFOREX balance.
     */
    function getUserBoostedStake(
        uint256 value,
        uint256 totalRealDeposits,
        uint256 boostWeight
    ) public view override returns (uint256) {
        // Return base value if the gFOREX data can't be fetched.
        if (address(governanceLock) == address(0) || value == 0) return value;
        uint256 totalSupply = governanceLock.totalSupply();
        // Prevent division by zero if total supply is zero.
        if (totalSupply == 0) return value;
        // The boost deposit amount is an amount of assets
        // deposited into this pool that the user will receive rewards for
        // even though they did not necessarily deposit these assets.
        // That is, if the user staked 100 WETH and their boost is 2.5x then
        // the boost deposit amount is 150 WETH (the user receives an extra reward
        // equivalent to if they had staked an extra 150 WETH).
        // In that example, the (boosted) user deposit is 100 + 150 WETH.
        // The boost deposit amount is calculated as 1.5x of the product of the
        // gFOREX market share of the user and the
        // total (unboosted) deposits in the reward pool.
        // So, as an example, if the user has 50% of all gFOREX supply,
        // the boost deposit amount will be 75% of the total deposits
        // of the reward pool.
        uint256 boostDepositAmount =
            (totalRealDeposits * boostWeight * 15) / (totalSupply * 10);
        // The boost value is added to the unboosted deposit.
        uint256 total = value + boostDepositAmount;
        // Limit the deposit boost to 2.5x.
        uint256 max = (value * 25) / 10;
        // Return the minimum between the boosted total and the value provided.
        return total > max ? max : total;
    }

    /**
     * @dev Unstakes account from a pool to stop accruing rewards.
     * @param account The account to unstake with.
     * @param value The value to be unstaked.
     * @param poolId The poolId ID to unstake from.
     */
    function unstake(
        address account,
        uint256 value,
        uint256 poolId
    ) external override nonReentrant returns (uint256 errorCode) {
        Pool storage pool = pools[poolId];
        // Check for unstaking permission.
        require(_canStake(account, pool), "RewardPool: unauthorised");
        Deposit storage deposit = pool.deposits[account];
        // Return early if the account has nothing staked.
        if (deposit.amount == 0) return 1;
        // Try to claim before modifying deposit value due to unstaking.
        _claimForAccount(account);
        uint256 stakeAmount = deposit.amount;
        // Limit value instead of reverting.
        if (value > stakeAmount) value = stakeAmount;
        uint256 newAmount = stakeAmount - value;
        _updateDeposit(account, newAmount, poolId);
        // Burn any receipt tokens after unstaking as needed,
        // and also return funds.
        _handleAssetsAfterUnstake(account, value, pool, deposit);
        emit Unstake(account, poolId, value);
        return 0;
    }

    /**
     * @dev Updates a deposit amount and the S value.
     * @param account The account to update the deposit for.
     * @param amount The new deposit amount.
     * @param poolId The pool ID.
     */
    function _updateDeposit(
        address account,
        uint256 amount,
        uint256 poolId
    ) private {
        Pool storage pool = pools[poolId];
        Deposit storage deposit = pool.deposits[account];
        // Current boosted deposit amount.
        uint256 currentDeposit =
            getUserBoostedStake(
                deposit.amount,
                pool.totalRealDeposits,
                deposit.boostWeight
            );
        // Update boostWeight with user's gFOREX balance if available.
        uint256 newBoostWeight =
            address(governanceLock) != address(0)
                ? governanceLock.balanceOf(account)
                : 0;
        deposit.boostWeight = newBoostWeight;
        // New boosted deposit amount, only used for the totalDeposits variable.
        if (amount == 0) {
            pool.totalDeposits = pool.totalDeposits - currentDeposit;
            pool.totalRealDeposits = pool.totalRealDeposits - deposit.amount;
            delete pool.deposits[account];
            return;
        }
        deposit.S = pool.S;
        pool.totalRealDeposits = deposit.amount > amount // Unstaking.
            ? pool.totalRealDeposits - (deposit.amount - amount) // Staking.
            : pool.totalRealDeposits + (amount - deposit.amount);
        uint256 newDeposit =
            getUserBoostedStake(amount, pool.totalRealDeposits, newBoostWeight);
        pool.totalDeposits = currentDeposit > newDeposit // Unstaking.
            ? pool.totalDeposits - (currentDeposit - newDeposit) // Staking.
            : pool.totalDeposits + (newDeposit - currentDeposit);
        deposit.amount = amount;
    }

    /**
     * @dev Recalculates and applies the current boost for an account.
     *      Ideally this would be execute for all account deposits
     *      at every block, but this is not feasible.
     *      This function allows external actors to make sure
     *      all boosts are fair and sufficiently up to date.
     * @param account The account to update the boost for.
     * @param poolIds An array of pool IDs to update the boost for.
     */
    function updateAccountBoost(address account, uint256[] memory poolIds)
        external
    {
        uint256 length = poolIds.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 poolId = poolIds[i];
            Pool storage pool = pools[poolId];
            require(pool.totalDeposits > 0, "Pool not initialised");
            uint256 currentDepositAmount = pool.deposits[account].amount;
            require(currentDepositAmount > 0, "Account has not deposited");
            // Runs updateDeposit with the current deposit amount,
            // which triggers a recalculation of the boost value
            // using the current block timestamp.
            _updateDeposit(account, currentDepositAmount, poolId);
        }
    }

    /**
     * @dev Claims FOREX rewards for caller.
     */
    function claim() external override nonReentrant {
        _claimForAccount(msg.sender);
    }

    /**
     * @dev Claims FOREX rewards for account.
     */
    function _claimForAccount(address account) private {
        // Update distribution as required before claiming.
        distribute();
        assert(lastDistributionDate == block.timestamp);
        uint256 enabledCount = enabledPools.length;
        uint256[] memory amounts = new uint256[](enabledCount);
        uint256 totalAmount;
        for (uint256 i = 0; i < enabledCount; i++) {
            uint256 poolId = enabledPools[i];
            Pool storage pool = pools[poolId];
            Deposit storage deposit = pool.deposits[account];
            // Cache deposit S value before updating the deposit
            // with the current pool S value.
            // The difference between the pre-update S value
            // and the current pool S value is the delta S
            // used to calculate the claimable balance.
            uint256 depositS = deposit.S;
            // Cache pool S value.
            // This is up to date since this function calls distribute().
            uint256 poolS = pool.S;
            // Cache the gFOREX balance before claiming.
            uint256 boostWeightBeforeClaim = deposit.boostWeight;
            // Refresh boost value & totalDeposits if needed, and update
            // deposit's S value to the current pool's S value, which
            // resets the claimable balance to zero.
            _updateDeposit(account, deposit.amount, poolId);
            // Continue to next iteration if there is nothing to claim.
            if (depositS >= poolS) continue;
            uint256 boostedAmount =
                getUserBoostedStake(
                    deposit.amount,
                    pool.totalRealDeposits,
                    boostWeightBeforeClaim
                );
            // The difference of the current pool S
            // and the pre-update deposit S
            // is used to calculate the claimable amount for the user.
            uint256 deltaS = poolS - depositS;
            uint256 amount = (boostedAmount * deltaS) / (1 ether);
            // Update event variables.
            amounts[i] = amount;
            totalAmount += amount;
        }
        // Return early if there is nothing to claim.
        if (totalAmount == 0) return;
        // Transfer total reward to user.
        forex.safeTransfer(account, totalAmount);
        emit Claim(account, totalAmount, enabledPools, amounts);
    }

    /**
     * @dev Creates a new pool.
     * @param weight The pool weight.
     * @param assetType The asset type for the pool.
     * @param assetAddress The asset address for the pool, or zero if none.
     * @param poolIds The array of pools to keep enabled and configure.
     * @param weights The weight array relative to the pools array.
     */
    function createPool(
        uint256 weight,
        AssetType assetType,
        address assetAddress,
        uint256[] memory poolIds,
        uint256[] memory weights
    ) external override onlyOperatorOrAdmin {
        _setPools(poolIds, weights);
        // Create new pool.
        uint256 newPoolId = poolCount++;
        Pool storage pool = pools[newPoolId];
        _initialisePool(pool, assetType, assetAddress, weight, newPoolId);
        // Add to enabled pools only if the weight is not zero.
        if (weight > 0) _addToEnabledPools(newPoolId);
    }

    /**
     * @dev Allows for setting up multiple pools at once after deployment.
     * @param assetTypes The asset type array for each pool.
     * @param assetAddresses The asset addresses array for each pool.
     * @param weights The weight array relative to the pools array.
     * @param aliases The aliases for the pools.
     */
    function setupPools(
        AssetType[] memory assetTypes,
        address[] memory assetAddresses,
        uint256[] memory weights,
        bytes32[] memory aliases
    ) external override onlyOperatorOrAdmin {
        require(poolCount == 0, "Pools already initialised");
        uint256 count = assetTypes.length;
        assert(count == assetAddresses.length && count == weights.length);
        uint256[] memory poolIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            Pool storage pool = pools[i];
            poolIds[i] = i;
            _initialisePool(
                pool,
                assetTypes[i],
                assetAddresses[i],
                weights[i],
                i
            );
            setPoolAlias(aliases[i], i);
        }
        enabledPools = poolIds;
        poolCount = count;
    }

    function _initialisePool(
        Pool storage pool,
        AssetType assetType,
        address assetAddress,
        uint256 weight,
        uint256 poolId
    ) private {
        _validatePoolAssetTypeAndAddress(assetType, assetAddress);
        pool.assetType = assetType;
        pool.assetAddress = assetAddress;
        pool.weight = weight;
        if (assetAddress != address(0))
            _setWhitelistedStaker(assetAddress, poolId, true);
        emit CreatePool(poolId, assetType, assetAddress, weight);
    }

    /**
     * @dev Used to enable and disable pools.
     *      To disable, a weight must be set to zero.
     *      Will emit events accordingly.
     * @param poolIds] The array of poolIds] to configure.
     * @param weights The array of weights to configure.
     */
    function setPools(uint256[] memory poolIds, uint256[] memory weights)
        public
        override
        onlyOperatorOrAdmin
    {
        _setPools(poolIds, weights);
    }

    /**
     * @dev Used to enable and disable pools.
     *      All enabled pools must be within the poolIds and weights arrays,
     *      and they should have a weight greater than zero.
     *      Any pools not in poolIds will have their weights set to zero.
     *      Will emit events accordingly.
     * @param poolIds The array of pool IDs to configure.
     * @param weights The array of weights to configure.
     */
    function _setPools(uint256[] memory poolIds, uint256[] memory weights)
        private
    {
        uint256 argumentLength = poolIds.length;
        require(
            argumentLength == weights.length,
            "RewardPool: args length mismatch"
        );
        // Cache storage read.
        uint256 count = poolCount;
        // Set pool weights as required.
        for (uint256 i = 0; i < count; i++) {
            // Find whether this pool has been passed in the poolIds argument.
            bool inArgument = false;
            uint256 argumentIndex;
            for (uint256 j = 0; j < argumentLength; j++) {
                if (i != poolIds[j]) continue;
                inArgument = true;
                argumentIndex = j;
                break;
            }
            Pool storage pool = pools[i];
            if (!inArgument) {
                // If the pool was not passed in the argument,
                // set its weight to zero.
                pool.weight = 0;
                continue;
            }
            uint256 weight = weights[argumentIndex];
            require(weight > 0, "RewardPool: set zero-weight pool");
            // Set pool weight to the argument value.
            pool.weight = weight;
        }
        enabledPools = poolIds;
        emit SetPoolWeights(poolIds, weights);
    }

    /**
     * @dev Checks whether the sender has the permission to stake or unstake.
     * @param account The account to stake/unstake for.
     * @param pool The pool reference.
     */
    function _canStake(address account, Pool storage pool)
        private
        view
        returns (bool)
    {
        bool isErc20Pool = pool.assetType == AssetType.ERC20;
        bool isWhitelistedStaker = pool.stakerWhitelist[msg.sender];
        // Whether the sender can stake for the user.
        // They must either be whitelisted, or staking for themselves.
        bool isAuthorised = isWhitelistedStaker || msg.sender == account;
        // If staking in an ERC20 pool, users can stake for themselves.
        // Otherwise, the staker must be whitelisted.
        return isAuthorised && (isErc20Pool || isWhitelistedStaker);
    }

    /**
     * @dev Set the FOREX distribution rate per second.
     * @param rate The FOREX rate per second to distribute across pools.
     */
    function setForexDistributionRate(uint256 rate)
        external
        override
        onlyOperatorOrAdmin
    {
        // Return early if rates are the same.
        if (rate == forexDistributionRate) return;
        // Distribute outstanding FOREX before updating the rate.
        if (lastDistributionDate != block.timestamp) {
            distribute();
            assert(lastDistributionDate == block.timestamp);
        }
        forexDistributionRate = rate;
        emit SetForexDistributionRate(rate);
    }

    /**
     * @dev Distributes outstanding FOREX across pools.
     *      Updates the lastDistributionDate to the current block timestamp
     *      if successful.
     */
    function distribute() public override {
        // Return early after running once this block.
        if (block.timestamp == lastDistributionDate) return;
        (, uint256[] memory amounts, uint256[] memory deltaS, ) =
            getEnabledPoolsData();
        // Calculate seconds passed since last distribution.
        uint256 duration = block.timestamp - lastDistributionDate;
        // Update the last distribution date.
        lastDistributionDate = block.timestamp;
        // Return early if there are no amounts to distribute.
        if (amounts.length == 0) return;
        assert(amounts.length == deltaS.length);
        uint256 totalAmount = 0;
        // Cache storage read.
        uint256 count = enabledPools.length;
        for (uint256 i = 0; i < count; i++) {
            Pool storage pool = pools[enabledPools[i]];
            // Continue if there are no amounts or pool is disabled.
            if (amounts[i] == 0 || pool.weight == 0) continue;
            pool.S += deltaS[i];
            totalAmount += amounts[i];
        }
        emit ForexDistributed(
            duration,
            forexDistributionRate,
            totalAmount,
            enabledPools,
            amounts
        );
    }

    function distributeDirectlyForPool(uint256 poolId, uint256 amount)
        external
        override
        onlyOperatorOrAdmin
    {
        Pool storage pool = pools[poolId];
        require(pool.totalDeposits > 0, "RewardPool: pool is empty");
        // Add delta S value based on distribution amount.
        pool.S += (amount * (1 ether)) / pool.totalDeposits;
        emit ForexDistributedDirectly(poolId, amount);
    }

    /**
     * @dev Sets or unsets a staking address as whitelisted from a pool.
     *      The whitelist is only used if the pool's asset type is None.
     */
    function setWhitelistedStaker(
        address staker,
        uint256 poolId,
        bool isWhitelisted
    ) external override onlyOperatorOrAdmin {
        _setWhitelistedStaker(staker, poolId, isWhitelisted);
    }

    /**
     * @dev Sets or unsets a staking address as whitelisted from a pool.
     *      The whitelist is only used if the pool's asset type is None.
     */
    function _setWhitelistedStaker(
        address staker,
        uint256 poolId,
        bool isWhitelisted
    ) private {
        require(
            pools[poolId].stakerWhitelist[staker] != isWhitelisted,
            "RewardPool: already set"
        );
        pools[poolId].stakerWhitelist[staker] = isWhitelisted;
        emit WhitelistChanged(staker, poolId, isWhitelisted);
    }

    /** @dev Sets a pool hash alias. These are used to fetch similar pools
     *       of pools without relying on the ID directly, e.g. all minting
     *       rewards pool for the protocol fxTokens. The ID for those may be
     *       obtained by e.g. getPoolIdByAlias(keccak256("minting" + tokenAddress))
     */
    function setPoolAlias(bytes32 hash, uint256 poolId)
        public
        override
        onlyOperatorOrAdmin
    {
        // The poolId gets added by 1 so that a value of zero can revert
        // to identify aliases that have not been set (see getPoolIdByAlias).
        poolAliases[hash] = poolId + 1;
        emit PoolAliasChanged(poolId, hash);
    }

    /**
     * @dev Adds an item to the enabledPools array
     * @param poolId The poolId ID to push to the array.
     */
    function _addToEnabledPools(uint256 poolId) private {
        uint256 count = enabledPools.length;
        for (uint256 i = 0; i < count; i++) {
            if (enabledPools[i] != poolId) continue;
            revert("RewardPool: pushing duplicate pool ID");
        }
        enabledPools.push(poolId);
    }

    /**
     * @dev Calculates pool parameters for all enabled pools from the
     *      current block.
     *      Also returns an array of the enabled pool IDs.
     */
    function getEnabledPoolsData()
        public
        view
        override
        returns (
            uint256[] memory poolRatios,
            uint256[] memory accruedAmounts,
            uint256[] memory deltaS,
            uint256[] memory poolIds
        )
    {
        uint256 enabledCount = enabledPools.length;
        poolRatios = new uint256[](enabledCount);
        accruedAmounts = new uint256[](enabledCount);
        deltaS = new uint256[](enabledCount);
        poolIds = new uint256[](enabledCount);
        // Return early if there no pools enabled as all arrays are empty.
        if (enabledCount == 0)
            return (poolRatios, accruedAmounts, deltaS, poolIds);
        // Get total pools weight to calculate ratios.
        uint256 totalWeight = _getTotalWeight();
        // Initialise poolIds and ratios array.
        for (uint256 i = 0; i < enabledCount; i++) {
            // Set poolIds for this index.
            poolIds[i] = enabledPools[i];
            // Load pool from storage and set poolRatios for this index.
            Pool storage pool = pools[poolIds[i]];
            if (totalWeight == 0 || pool.weight == 0) continue;
            poolRatios[i] = (pool.weight * (1 ether)) / totalWeight;
        }
        // Check whether the function should return before the
        // reward accrual calculations.
        bool shouldReturnEarly =
            // Return early after running once this block, as
            // that means all the accrued and delta values are zero.
            block.timestamp == lastDistributionDate ||
                // Return early if rate is zero, for the same reason above.
                // Whenever the rate changes, a re-distribution occurs.
                // So if the rate is zero, the amount below would also be.
                forexDistributionRate == 0;
        if (shouldReturnEarly)
            return (poolRatios, accruedAmounts, deltaS, poolIds);
        uint256 rate = forexDistributionRate;
        uint256 duration = block.timestamp - lastDistributionDate;
        uint256 amount = duration * rate;
        for (uint256 i = 0; i < enabledCount; i++) {
            // Load pool from storage.
            Pool storage pool = pools[poolIds[i]];
            if (pool.weight == 0 || pool.totalDeposits == 0) continue;
            accruedAmounts[i] = (amount * poolRatios[i]) / (1 ether);
            deltaS[i] = (accruedAmounts[i] * (1 ether)) / pool.totalDeposits;
        }
    }

    /**
     * @dev Calculates delta S value for a single pool.
     */
    function _getPoolDeltaS(Pool storage pool) private view returns (uint256) {
        uint256 totalWeight = _getTotalWeight();
        uint256 totalDeposits = pool.totalDeposits;
        if (totalWeight == 0 || totalDeposits == 0) return 0;
        uint256 rate = forexDistributionRate;
        uint256 duration = block.timestamp - lastDistributionDate;
        // Amount accrued across all pools
        uint256 globalAmount = duration * rate;
        uint256 poolRatio = (pool.weight * (1 ether)) / totalWeight;
        uint256 poolAccruedAmount = (globalAmount * poolRatio) / (1 ether);
        return (poolAccruedAmount * (1 ether)) / totalDeposits;
    }

    /**
     * @dev Returns a reward pool alias for the fxToken and pool category.
     * @param token The fxToken address to get the pool for.
     * @param category The reward category number.
     */
    function getFxTokenPoolAlias(address token, uint256 category)
        external
        pure
        override
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(token, category));
    }

    /** @dev Returns a pool hash alias or reverts if not defined */
    function getPoolIdByAlias(bytes32 hash)
        public
        view
        override
        returns (bool found, uint256 poolId)
    {
        uint256 result = poolAliases[hash];
        if (result == 0) return (false, 0);
        return (true, result - 1);
    }

    /**
     * @dev Get pool data.
     * @param poolId The ID of the pool to view.
     */
    function getPool(uint256 poolId)
        external
        view
        override
        returns (
            uint256 weight,
            AssetType assetType,
            address assetAddress,
            uint256 totalDeposits,
            uint256 S,
            uint256 totalRealDeposits
        )
    {
        Pool storage pool = pools[poolId];
        return (
            pool.weight,
            pool.assetType,
            pool.assetAddress,
            pool.totalDeposits,
            pool.S,
            pool.totalRealDeposits
        );
    }

    /**
     * @dev Get deposit for address.
     * @param account The account to view.
     * @param poolId The ID of the pool to view.
     */
    function getDeposit(address account, uint256 poolId)
        external
        view
        override
        returns (Deposit memory)
    {
        return pools[poolId].deposits[account];
    }

    /**
     * @dev Returns the reward balance for an address.
     * @param account The address to fetch balance for.
     */
    function balanceOf(address account)
        public
        view
        override
        returns (uint256 balance)
    {
        (, , uint256[] memory deltaS, ) = getEnabledPoolsData();
        uint256 count = enabledPools.length;
        for (uint256 i = 0; i < count; i++) {
            uint256 poolId = enabledPools[i];
            Pool storage pool = pools[poolId];
            Deposit storage deposit = pool.deposits[account];
            uint256 poolS = pool.S + deltaS[i];
            balance += _calculateClaimBalance(
                poolS,
                pool.totalRealDeposits,
                deposit
            );
        }
    }

    /**
     * @dev Returns the reward balance for an address on a specific pool.
     * @param account The address to fetch balance for.
     * @param poolId The pool ID to fetch the balance for.
     */
    function poolBalanceOf(address account, uint256 poolId)
        external
        view
        override
        returns (uint256 balance)
    {
        Pool storage pool = pools[poolId];
        Deposit storage deposit = pool.deposits[account];
        // Get pool S including accrual not yet distributed.
        uint256 poolS = pool.S + _getPoolDeltaS(pool);
        return _calculateClaimBalance(poolS, pool.totalRealDeposits, deposit);
    }

    /**
     * @dev Returns the (boosted) reward balance on a specific pool.
     * @param poolS The pool S value to use for the calculation.
     * @param poolTotalRealDeposits The (non-boosted) pool deposits.
     * @param deposit The reference deposit struct for the account.
     */
    function _calculateClaimBalance(
        uint256 poolS,
        uint256 poolTotalRealDeposits,
        Deposit storage deposit
    ) private view returns (uint256) {
        uint256 depositS = deposit.S;
        // Get boosted deposit amount.
        uint256 depositAmount =
            getUserBoostedStake(
                deposit.amount,
                poolTotalRealDeposits,
                deposit.boostWeight
            );
        // Deposit S should never be greater than pool S,
        // but it could be equal.
        if (depositAmount == 0 || depositS >= poolS) return 0;
        uint256 deltaS = poolS - depositS;
        return (depositAmount * deltaS) / (1 ether);
    }

    /**
     * @dev View to return the length of the enabledPools array,
     *      because Solidity is a special snowflake.
     */
    function enabledPoolsLength() external view returns (uint256) {
        return enabledPools.length;
    }

    /**
     * @dev Returns the total weight for all enabled pools.
     */
    function _getTotalWeight() private view returns (uint256 totalWeight) {
        uint256 enabledCount = enabledPools.length;
        for (uint256 i = 0; i < enabledCount; i++) {
            totalWeight += pools[enabledPools[i]].weight;
        }
    }

    /**
     * @dev Sets totalRealDeposits to totalDeposits for all pools.
     *      Only works if totalRealDeposits is zero and totalDeposits is not.
     *      Should only be called before boosts are active due to the
     *      totalRealDeposits variable being added to the code as a fix.
     */
    function syncTotalRealDeposits() external onlyAdmin {
        uint256 count = poolCount;
        for (uint256 i = 0; i < count; i++) {
            Pool storage pool = pools[i];
            if (pool.totalDeposits == 0) continue;
            pool.totalRealDeposits = pool.totalDeposits;
        }
    }

    /**
     * @dev Behaviour to execute after user deposit is updated when
     *      staking into a pool.
     *      This triggers the collection of an ERC20 asset if the
     *      pool requires ERC20 staking, and mints receipt tokens.
     * @param account The address of the user staking.
     * @param amount The amount being staked.
     * @param pool The reward pool struct reference.
     * @param deposit The deposit struct reference for the user.
     */
    function _handleAssetsAfterStake(
        address account,
        uint256 amount,
        Pool storage pool,
        Deposit storage deposit
    ) private {
        if (pool.assetType != AssetType.ERC20) return;
        _depositErc20(amount, pool);
        _mintStakedErc20(account, amount, pool, deposit);
    }

    /**
     * @dev Behaviour to execute after user deposit is updated when
     *      unstaking from a pool.
     *      This triggers the return of an ERC20 asset if the
     *      pool requires ERC20 staking, and burns receipt tokens.
     * @param account The address of the user unstaking.
     * @param amount The amount being unstaked.
     * @param pool The reward pool struct reference.
     * @param deposit The deposit struct reference for the user.
     */
    function _handleAssetsAfterUnstake(
        address account,
        uint256 amount,
        Pool storage pool,
        Deposit storage deposit
    ) private {
        if (pool.assetType != AssetType.ERC20) return;
        _withdrawErc20(amount, pool);
        _burnStakedErc20(account, amount, pool, deposit);
    }

    /**
     * @dev Transfers in the deposit of ERC20 tokens from the sender.
     * @param amount The amount being staked.
     * @param pool The reward pool struct reference.
     */
    function _depositErc20(uint256 amount, Pool storage pool) private {
        assert(pool.assetAddress != address(0));
        StakedErc20 stakedErc20 = StakedErc20(pool.assetAddress);
        IERC20 depositToken = IERC20(stakedErc20.depositToken());
        depositToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev Transfers out the deposit of ERC20 tokens to the sender.
     * @param amount The amount being unstaked.
     * @param pool The reward pool struct reference.
     */
    function _withdrawErc20(uint256 amount, Pool storage pool) private {
        assert(pool.assetAddress != address(0));
        StakedErc20 stakedErc20 = StakedErc20(pool.assetAddress);
        IERC20 depositToken = IERC20(stakedErc20.depositToken());
        depositToken.safeTransfer(msg.sender, amount);
    }

    /**
     * @dev Mints receipt ERC20 tokens to the user, ensuring their
     *      token balance is the same as their deposit amount.
     * @param account The address of the user staking.
     * @param amount The amount being staked.
     * @param pool The reward pool struct reference.
     * @param deposit The deposit struct reference for the user.
     */
    function _mintStakedErc20(
        address account,
        uint256 amount,
        Pool storage pool,
        Deposit storage deposit
    ) private {
        // The user's receipt token balance must be equal to
        // the user's deposit in the pool.
        StakedErc20 token = StakedErc20(pool.assetAddress);
        token.mint(account, amount);
        // This check is made in StakedErc20 prior to mint,
        // and also replicated here after mint.
        assert(deposit.amount == token.balanceOf(account));
    }

    /**
     * @dev Burns receipt ERC20 tokens to the user, ensuring their
     *      token balance is the same as their deposit amount.
     * @param account The address of the user unstaking.
     * @param amount The amount being unstaked.
     * @param pool The reward pool struct reference.
     * @param deposit The deposit struct reference for the user.
     */
    function _burnStakedErc20(
        address account,
        uint256 amount,
        Pool storage pool,
        Deposit storage deposit
    ) private {
        StakedErc20 token = StakedErc20(pool.assetAddress);
        token.burn(account, amount);
        // This check is made in StakedErc20 prior to burn,
        // and also replicated here after burn.
        assert(deposit.amount == token.balanceOf(account));
    }

    /**
     * @dev Validates that the asset type and address are correct.
     *      If the asset type is None, then the address must be zero.
     *      If it is not none, then the address must not be zero.
     * @param assetType The asset type.
     * @param assetAddress The asset address.
     */
    function _validatePoolAssetTypeAndAddress(
        AssetType assetType,
        address assetAddress
    ) private pure {
        // If the asset type is None, then the address must be zero.
        bool isValidNoAsset =
            (assetType == AssetType.None && assetAddress == address(0));
        // If the asset type is not None, then the address must not be zero.
        bool isValidAsset =
            (assetType != AssetType.None && assetAddress != address(0));
        require(
            isValidNoAsset || isValidAsset,
            "RewardPool: invalid type/address"
        );
    }

    /** @dev Protected UUPS upgrade authorization function */
    function _authorizeUpgrade(address) internal override onlyAdmin {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IHandleComponent {
    function setHandleContract(address hanlde) external;

    function handleAddress() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

pragma abicoder v2;

interface IHandle {
    struct Vault {
        // Collateral token address => balance
        mapping(address => uint256) collateralBalance;
        uint256 debt;
        // Collateral token address => R0
        mapping(address => uint256) R0;
    }

    struct CollateralData {
        uint256 mintCR;
        uint256 liquidationFee;
        uint256 interestRate;
    }

    event UpdateDebt(address indexed account, address indexed fxToken);

    event UpdateCollateral(
        address indexed account,
        address indexed fxToken,
        address indexed collateralToken
    );

    event ConfigureCollateralToken(address indexed collateralToken);

    event ConfigureFxToken(address indexed fxToken, bool removed);

    function setCollateralUpperBoundPCT(uint256 ratio) external;

    function setPaused(bool value) external;

    function setFxToken(address token) external;

    function removeFxToken(address token) external;

    function setCollateralToken(
        address token,
        uint256 mintCR,
        uint256 liquidationFee,
        uint256 interestRatePerMille
    ) external;

    function removeCollateralToken(address token) external;

    function getAllCollateralTypes()
        external
        view
        returns (address[] memory collateral);

    function getCollateralDetails(address collateral)
        external
        view
        returns (CollateralData memory);

    function WETH() external view returns (address);

    function treasury() external view returns (address payable);

    function comptroller() external view returns (address);

    function vaultLibrary() external view returns (address);

    function fxKeeperPool() external view returns (address);

    function pct() external view returns (address);

    function liquidator() external view returns (address);

    function interest() external view returns (address);

    function referral() external view returns (address);

    function forex() external view returns (address);

    function rewards() external view returns (address);

    function pctCollateralUpperBound() external view returns (uint256);

    function isFxTokenValid(address fxToken) external view returns (bool);

    function isCollateralValid(address collateral) external view returns (bool);

    function setComponents(address[] memory components) external;

    function updateDebtPosition(
        address account,
        uint256 amount,
        address fxToken,
        bool increase
    ) external;

    function updateCollateralBalance(
        address account,
        uint256 amount,
        address fxToken,
        address collateralToken,
        bool increase
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFees(
        uint256 withdrawFeePerMille,
        uint256 depositFeePerMille,
        uint256 mintFeePerMille,
        uint256 burnFeePerMille
    ) external;

    function getCollateralBalance(
        address account,
        address collateralType,
        address fxToken
    ) external view returns (uint256 balance);

    function getBalance(address account, address fxToken)
        external
        view
        returns (address[] memory collateral, uint256[] memory balances);

    function getDebt(address owner, address fxToken)
        external
        view
        returns (uint256 _debt);

    function getPrincipalDebt(address owner, address fxToken)
        external
        view
        returns (uint256 _debt);

    function getCollateralR0(
        address account,
        address fxToken,
        address collateral
    ) external view returns (uint256 R0);

    function getTokenPrice(address token) external view returns (uint256 quote);

    function setOracle(address fxToken, address oracle) external;

    function FeeRecipient() external view returns (address);

    function mintFeePerMille() external view returns (uint256);

    function burnFeePerMille() external view returns (uint256);

    function withdrawFeePerMille() external view returns (uint256);

    function depositFeePerMille() external view returns (uint256);

    function isPaused() external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Established pool categories to be used internally by the
 * protocol for the users.
 * This enum is used to get the correct pool ID from the pool alias
 * which consists of an fxToken address and a category number.
 */
enum RewardPoolCategory {Mint, Deposit, Keeper}

interface IRewardPool {
    /** Reward category e.g. Keepers or Liquidity Providers */
    struct Pool {
        // Pool reward weight. The amount of FOREX allocated to this
        // category is given by the ratio of this weight to the sum of all
        // weights for enabled pools.
        // A category is enabled if the weight is not zero.
        uint256 weight;
        // Asset is used for pools that require token staking,
        // such as LP tokens. Could be e.g. None, ERC20 or ERC721.
        AssetType assetType;
        // The address of the StakedErc20 for this pool.
        // This is the receipt token, not the deposit/underlying asset.
        // For pools with no token (AssetType.None), this is the zero address.
        address assetAddress;
        // If AssetType == None, whitelist with this map from staker address.
        mapping(address => bool) stakerWhitelist;
        // Account -> Deposit
        mapping(address => Deposit) deposits;
        // Total amount deposited, which may be boosted.
        uint256 totalDeposits;
        // Current pool reward ratio over total deposits.
        uint256 S;
        // Total real value deposited (excluding boosts).
        uint256 totalRealDeposits;
    }

    /** Reward pool deposit for tracking user contributions */
    struct Deposit {
        // Amount contributed.
        // e.g. for Keepers, the total amount staked.
        //      for minters, the total amount minted.
        //      for LPs, the total liquidity provided.
        uint256 amount;
        // Reward ratio over total deposits during deposit.
        uint256 S;
        // The weight (gFOREX balance) by which the boost is
        // calculated from during claim.
        uint256 boostWeight;
    }

    enum AssetType {None, ERC20, ERC721}

    event Stake(address indexed account, uint256 poolId, uint256 amount);

    event Unstake(address indexed account, uint256 poolId, uint256 amount);

    event CreatePool(
        uint256 id,
        AssetType assetType,
        address asset,
        uint256 weight
    );

    event SetPoolWeights(uint256[] poolIds, uint256[] weights);

    event SetFxTokenWeights(address[] fxTokens, uint256[] weights);

    event ForexDistributed(
        uint256 duration,
        uint256 rate,
        uint256 totalAmount,
        uint256[] poolIds,
        uint256[] amounts
    );

    event ForexDistributedDirectly(uint256 poolId, uint256 amount);

    event SetForexDistributionRate(uint256 ratePerSecond);

    event Claim(
        address indexed acount,
        uint256 amount,
        uint256[] poolIds,
        uint256[] amounts
    );

    event WhitelistChanged(address staker, uint256 poolId, bool whitelisted);

    event PoolAliasChanged(uint256 poolId, bytes32 aliasHash);

    function stake(
        address account,
        uint256 value,
        uint256 poolId
    ) external returns (uint256 errorCode);

    function unstake(
        address account,
        uint256 value,
        uint256 poolId
    ) external returns (uint256 errorCode);

    function claim() external;

    function distribute() external;

    function distributeDirectlyForPool(uint256 poolId, uint256 amount) external;

    function createPool(
        uint256 weight,
        AssetType assetType,
        address assetAddress,
        uint256[] memory poolIds,
        uint256[] memory weights
    ) external;

    function setupPools(
        AssetType[] memory assetTypes,
        address[] memory assetAddresses,
        uint256[] memory weights,
        bytes32[] memory aliases
    ) external;

    // Used to enable and disable pools.
    // To disable, a weight must be set to zero.
    // Will emit events accordingly.
    function setPools(uint256[] memory poolIds, uint256[] memory weights)
        external;

    function setWhitelistedStaker(
        address staker,
        uint256 poolId,
        bool isWhitelisted
    ) external;

    function setForexDistributionRate(uint256 rate) external;

    function setPoolAlias(bytes32 hash, uint256 poolId) external;

    function getEnabledPoolsData()
        external
        view
        returns (
            uint256[] memory poolRatios,
            uint256[] memory accruedAmounts,
            uint256[] memory deltaS,
            uint256[] memory poolIds
        );

    function getPoolIdByAlias(bytes32 hash)
        external
        view
        returns (bool found, uint256 poolId);

    function getFxTokenPoolAlias(address token, uint256 category)
        external
        pure
        returns (bytes32);

    // Return allowed parameters only (no mappings)
    // because Solidity is a Special Snowflake (tm)
    function getPool(uint256 poolId)
        external
        view
        returns (
            uint256 weight,
            AssetType assetType,
            address assetAddress,
            uint256 totalDeposits,
            uint256 S,
            uint256 totalRealDeposits
        );

    function getDeposit(address account, uint256 poolId)
        external
        view
        returns (Deposit memory);

    function balanceOf(address account) external view returns (uint256 balance);

    function poolBalanceOf(address account, uint256 poolId)
        external
        view
        returns (uint256 balance);

    function getUserBoostedStake(
        uint256 value,
        uint256 poolId,
        uint256 boostWeight
    ) external view returns (uint256);

    function forex() external view returns (IERC20);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract Roles is AccessControlUpgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "NO");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "NA");
        _;
    }

    modifier onlyOperatorOrAdmin() {
        require(
            hasRole(OPERATOR_ROLE, msg.sender) ||
                hasRole(ADMIN_ROLE, msg.sender),
            "NW"
        );
        _;
    }

    modifier onlyAddressOrOperatorExcludeAdmin(address addressAllowed) {
        // Protect user deposits from abuse
        require(
            msg.sender == addressAllowed ||
                (hasRole(OPERATOR_ROLE, msg.sender) &&
                    !hasRole(ADMIN_ROLE, msg.sender)),
            "NW"
        );
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/rewards/IRewardPool.sol";

struct Point {
    int128 bias;
    int128 slope;
    uint256 ts;
    uint256 blk; // block
}

struct LockedBalance {
    int128 amount;
    uint256 end;
}

/**
 * @dev Allows FOREX holders to lock tokens for gFOREX and gain Handle DAO voting power.
 *      FOREX may be locked for up to 4 years.
 *      gFOREX balance decays linearly during the locked period until FOREX is fully unlocked.
 *      A locked position may be added to or have its duration extended at any time for an
 *      increase in gFOREX voting power.
 */
contract GovernanceLock is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    int128 public constant MAX_TIME = 4 * 365 * 86400; // 4 years
    bytes32 public constant REWARD_POOL_ALIAS = keccak256("governancelock");

    /** @dev The token to be locked. e.g. FOREX */
    address public token;
    /** @dev The supply of token's locked */
    uint256 public supply;
    /** @dev Mapping from account address to locked balance position */
    mapping(address => LockedBalance) public locked;
    /** @dev The current system epoch */
    uint256 public epoch;
    /** @dev Mapping from epoch to point history */
    mapping(uint256 => Point) public pointHistory;
    /** @dev Mapping from account address to epoch to point history */
    mapping(address => mapping(uint256 => Point)) public userPointHistory;
    /** @dev Mapping from account address to current user epoch */
    mapping(address => uint256) public userPointEpoch;
    /** @dev Mapping from slope changes @ "week time" to slope value */
    mapping(uint256 => int128) public slopeChanges;
    /** @dev Mapping from contract address to its whitelisted status */
    mapping(address => bool) public whitelistedContracts;
    /** @dev Whether the whitelist is enabled for contract access */
    bool public isWhitelistEnabled;
    /** @dev The Handle reward pool for rewarding locking */
    IRewardPool public rewardPool;

    uint256 public constant WEEK = 7 * 86400;
    uint256 public constant MULTIPLIER = 1 ether;

    /** @dev Whether the contract has been retired and token refunds are on */
    bool public retiredContract;

    enum DepositType {
        DepositFor,
        CreateLock,
        IncreaseLockAmount,
        IncreaseUnlockTime
    }

    event Deposit(
        address indexed depositor,
        uint256 value,
        uint256 indexed locktime,
        DepositType depositType,
        uint256 ts
    );
    event Withdraw(address indexed depositor, uint256 value, uint256 ts);
    event Supply(uint256 previousSupply, uint256 supply);

    /**
     * @dev Reverts the tranasction if the sender is a contract and not
     *      whitelisted.
     */
    modifier onlyAllowedLocker() {
        require(
            !isWhitelistEnabled ||
                !isContract(msg.sender) ||
                whitelistedContracts[msg.sender],
            "Contract not allowed"
        );
        _;
    }

    /** @dev Proxy initialisation function */
    function initialize(address tokenAddress, address rewardPoolAddress)
        public
        initializer
        onlyProxy
    {
        __UUPSUpgradeable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        token = tokenAddress;
        rewardPool = IRewardPool(rewardPoolAddress);
        isWhitelistEnabled = true;
        pointHistory[0].blk = block.number;
        pointHistory[0].ts = block.timestamp;
    }

    /**
     * @dev "Retires" the contract by allowing refunds and preventing new deposits.
     * @param isRetired Whether to retire the contract.
     */
    function retireContract(bool isRetired) external onlyOwner {
        retiredContract = isRetired;
    }

    /**
     * @dev Adds or removes a contract access from the whitelist.
     */
    function setContractWhitelist(address contractAddress, bool isWhitelisted)
        external
        onlyOwner
    {
        whitelistedContracts[contractAddress] = isWhitelisted;
    }

    /**
     * @dev Enables or disables the contract access whitelist.
     */
    function setWhitelistEnabled(bool isEnabled) external onlyOwner {
        isWhitelistEnabled = isEnabled;
    }

    /**
     * @dev Returns user slope at last user epoch.
     */
    function getLastUserSlope(address account) external view returns (int128) {
        uint256 userEpoch = userPointEpoch[account];
        return userPointHistory[account][userEpoch].slope;
    }

    /**
     * @dev Getter for user point history at point idx
     */
    function userPointHistoryTs(address account, uint256 idx)
        external
        view
        returns (uint256)
    {
        return userPointHistory[account][idx].ts;
    }

    /**
     * @dev Getter for account's locked position end time.
     */
    function lockedEnd(address account) external view returns (uint256) {
        return locked[account].end;
    }

    /**
     * @dev Updates the system state and optionally for a given account.
     */
    function _checkpoint(
        address account,
        LockedBalance memory oldLocked,
        LockedBalance memory newLocked
    ) private {
        Point memory uOld = EMPTY_POINT_FACTORY();
        Point memory uNew = EMPTY_POINT_FACTORY();
        int128 oldDslope;
        int128 newDslope;
        uint256 _epoch = epoch;

        if (account != address(0)) {
            // Calculate slopes and biases
            // kept at zero when they have to
            if (oldLocked.end > block.timestamp && oldLocked.amount > 0) {
                uOld.slope = oldLocked.amount / MAX_TIME;
                uOld.bias =
                    uOld.slope *
                    int128(int256(oldLocked.end) - int256(block.timestamp));
            }
            if (newLocked.end > block.timestamp && newLocked.amount > 0) {
                uNew.slope = newLocked.amount / MAX_TIME;
                uNew.bias =
                    uNew.slope *
                    int128(int256(newLocked.end) - int256(block.timestamp));
            }
            // Read values of schedules changes in the slope
            // oldLocked.end can be in the past and in the future
            // newLocked.end can ONLY be in the FUTURE unless everything
            // expired: then zeros
            oldDslope = slopeChanges[oldLocked.end];
            if (newLocked.end != 0) {
                if (newLocked.end == oldLocked.end) {
                    newDslope = oldDslope;
                } else {
                    newDslope = slopeChanges[newLocked.end];
                }
            }
        }

        Point memory lastPoint =
            Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number});

        if (epoch > 0) lastPoint = pointHistory[_epoch];
        uint256 lastCheckpoint = lastPoint.ts;

        // Used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as it cannot be figured out exactly from inside the contract
        Point memory initialLastPoint = lastPoint;
        uint256 blockSlope;
        if (block.timestamp > lastPoint.ts)
            blockSlope =
                (MULTIPLIER * (block.number - lastPoint.blk)) /
                (block.timestamp - lastPoint.ts);

        // Round to nearest week.
        // Go over weeks to fill history and calculate what the current point
        // is.
        {
            uint256 t_i = (lastCheckpoint / WEEK) * WEEK;
            for (uint256 i = 0; i < 255; i++) {
                // If this does not get used in 5 years, users will be able to
                // withdraw but vote weight will be broken.
                t_i += WEEK;
                int128 dSlope;
                if (t_i > block.timestamp) {
                    t_i = block.timestamp;
                } else {
                    dSlope = slopeChanges[t_i];
                }
                lastPoint.bias -=
                    lastPoint.slope *
                    int128(int256(t_i) - int256(lastCheckpoint));
                lastPoint.slope += dSlope;
                // This can happen.
                if (lastPoint.bias < 0) {
                    lastPoint.bias = 0;
                }
                // In theory this cannot happen.
                if (lastPoint.slope < 0) {
                    lastPoint.slope = 0;
                }
                lastCheckpoint = t_i;
                lastPoint.ts = t_i;
                lastPoint.blk =
                    initialLastPoint.blk +
                    (blockSlope * (t_i - initialLastPoint.ts)) /
                    MULTIPLIER;
                _epoch += 1;
                if (t_i == block.timestamp) {
                    lastPoint.blk = block.number;
                    break;
                } else {
                    pointHistory[_epoch] = lastPoint;
                }
            }
        }
        epoch = _epoch;
        // pointHistory is now up to date with current block
        if (account != address(0)) {
            lastPoint.slope += (uNew.slope - uOld.slope);
            lastPoint.bias += (uNew.bias - uOld.bias);
            if (lastPoint.slope < 0) lastPoint.slope = 0;
            if (lastPoint.bias < 0) lastPoint.bias = 0;
        }
        // Record the changed point into history
        pointHistory[_epoch] = lastPoint;
        if (account != address(0)) {
            // Schedule the slope changes (slope is going down)
            // Subtract new slope from [newLocked.end]
            // Add old slope to [oldLocked.epoch]
            if (oldLocked.end > block.timestamp) {
                oldDslope += uOld.slope;
                if (newLocked.end == oldLocked.end) oldDslope -= uNew.slope; // new deposit, not extension
                slopeChanges[oldLocked.end] = oldDslope;
            }
            if (newLocked.end > block.timestamp) {
                if (newLocked.end > oldLocked.end) {
                    newDslope -= uNew.slope;
                    slopeChanges[newLocked.end] = newDslope;
                }
                // else: has already been recorded in oldDslope
            }
            // Handle user history
            uint256 userEpoch = userPointEpoch[account] + 1;
            userPointEpoch[account] = userEpoch;
            uNew.ts = block.timestamp;
            uNew.blk = block.number;
            userPointHistory[account][userEpoch] = Point({
                bias: uNew.bias,
                slope: uNew.slope,
                ts: block.timestamp,
                blk: block.number
            });
        }
    }

    /**
     * @dev Internal function to handle FOREX deposits and/or locktime increase.
     */
    function _depositFor(
        address account,
        uint256 value,
        uint256 unlockTime,
        LockedBalance memory lockedBalance,
        DepositType depositType
    ) private {
        require(!retiredContract, "Contract retired");
        LockedBalance memory _locked = lockedBalance;
        uint256 supplyBefore = supply;
        supply = supplyBefore + value;
        LockedBalance memory oldLocked =
            LockedBalance({amount: _locked.amount, end: _locked.end});
        // Adding to existing lock, or if expired create a new one
        _locked.amount += int128(int256(value));
        if (unlockTime != 0) _locked.end = unlockTime;
        locked[account] = _locked;
        // Possibilities:
        // both oldLocked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(account, oldLocked, _locked);
        if (value != 0)
            IERC20(token).safeTransferFrom(account, address(this), value);
        // Stake into reward pool.
        uint256 stakeAmount =
            _locked.amount > 0 ? uint256(uint128(_locked.amount)) : 0;
        setUserRewardStakeAmount(account, stakeAmount);
        emit Deposit(account, value, _locked.end, depositType, block.timestamp);
        emit Supply(supplyBefore, supplyBefore + value);
    }

    /**
     * @dev Sets the staked value in the gFOREX reward pool for an account.
     */
    function setUserRewardStakeAmount(address account, uint256 value) private {
        if (retiredContract) return;
        (bool foundRewardPool, uint256 rewardPoolId) =
            rewardPool.getPoolIdByAlias(REWARD_POOL_ALIAS);
        if (!foundRewardPool) return;
        // Unstake current amount from pool.
        // TODO: check that the error return value is nonzero.
        rewardPool.unstake(account, 2**256 - 1, rewardPoolId);
        if (value > 0) {
            // Stake value.
            // TODO: check that the error return value is nonzero.
            rewardPool.stake(account, value, rewardPoolId);
        }
    }

    /**
     * @dev Updates the system state without affecting any
     *      specific account directly.
     */
    function checkpoint() external {
        LockedBalance memory empty;
        _checkpoint(
            address(0),
            EMPTY_LOCKED_BALANCE_FACTORY(),
            EMPTY_LOCKED_BALANCE_FACTORY()
        );
    }

    /**
     * @dev Increases the locked FOREX amount for an account by depositing more.
     */
    function depositFor(address account, uint256 value) external {
        LockedBalance storage _locked = locked[account];
        assert(value > 0);
        assert(_locked.amount > 0);
        assert(_locked.end > block.timestamp);
        _depositFor(account, value, 0, locked[account], DepositType.DepositFor);
    }

    /**
     * @dev Opens a new locked FOREX position for the message sender.
     */
    function createLock(uint256 value, uint256 unlockTime)
        external
        onlyAllowedLocker
    {
        // Round unlockTime to weeks.
        unlockTime = (unlockTime / WEEK) * WEEK;
        LockedBalance memory _locked = locked[msg.sender];
        assert(value > 0);
        require(_locked.amount == 0, "Withdraw old tokens first");
        require(unlockTime > block.timestamp, "Must unlock in the future");
        require(
            unlockTime <= block.timestamp + uint256(uint128(MAX_TIME)),
            "Lock must not be > 4 years"
        );
        _depositFor(
            msg.sender,
            value,
            unlockTime,
            _locked,
            DepositType.CreateLock
        );
    }

    /**
     * @dev Increases FOREX lock amount.
     */
    function increaseAmount(uint256 value) external onlyAllowedLocker {
        LockedBalance storage _locked = locked[msg.sender];
        assert(value > 0);
        require(_locked.amount > 0, "No existing lock");
        require(_locked.end > block.timestamp, "Lock has expired");
        _depositFor(
            msg.sender,
            value,
            0,
            _locked,
            DepositType.IncreaseLockAmount
        );
    }

    /**
     * @dev Increases FOREX lock time.
     */
    function increaseUnlockTime(uint256 unlockTime) external onlyAllowedLocker {
        LockedBalance storage _locked = locked[msg.sender];
        // Round unlockTime to weeks.
        unlockTime = (unlockTime / WEEK) * WEEK;
        require(_locked.end > block.timestamp, "Lock has expired");
        require(_locked.amount > 0, "Nothing is locked");
        require(unlockTime > _locked.end, "Can only increase lock duration");
        require(
            unlockTime <= block.timestamp + uint256(uint128(MAX_TIME)),
            "Lock must not be > 4 years"
        );
        _depositFor(
            msg.sender,
            0,
            unlockTime,
            _locked,
            DepositType.IncreaseUnlockTime
        );
    }

    /**
     * @dev Withdraws fully unlocked FOREX from contract as well as rewards.
     */
    function withdraw() external {
        LockedBalance storage _locked = locked[msg.sender];
        require(
            retiredContract || block.timestamp >= _locked.end,
            "The lock didn't expire"
        );
        require(_locked.amount > 0, "Nothing to withdraw");
        uint256 value = uint256(uint128(_locked.amount));
        LockedBalance memory oldLocked =
            LockedBalance({amount: _locked.amount, end: _locked.end});
        _locked.end = 0;
        _locked.amount = 0;
        uint256 supplyBefore = supply;
        supply = supplyBefore - value;
        if (!retiredContract) _checkpoint(msg.sender, oldLocked, _locked);
        IERC20(token).safeTransfer(msg.sender, value);
        // Unstake from reward pool.
        setUserRewardStakeAmount(msg.sender, 0);
        emit Withdraw(msg.sender, value, block.timestamp);
        emit Supply(supplyBefore, supplyBefore - value);
    }

    /**
     * @dev Finds epoch from block number and max epoch search range.
     */
    function findBlockEpoch(uint256 blockNumber, uint256 maxEpoch)
        private
        view
        returns (uint256 minEpoch)
    {
        minEpoch = 0;
        // Binary search for 128 bit value
        for (uint256 i = 0; i < 128; i++) {
            if (minEpoch >= maxEpoch) break;
            uint256 midEpoch = (minEpoch + maxEpoch + 1) / 2;
            if (pointHistory[midEpoch].blk <= blockNumber) {
                minEpoch = midEpoch;
            } else {
                maxEpoch = midEpoch - 1;
            }
        }
    }

    /**
     * @dev Returns an account's gFOREX balance.
     */
    function balanceOf(address account) public view returns (uint256) {
        uint256 epoch = userPointEpoch[account];
        if (epoch == 0) return 0;
        Point memory lastPoint = userPointHistory[account][epoch];
        lastPoint.bias -=
            lastPoint.slope *
            int128(int256(block.timestamp - lastPoint.ts));
        if (lastPoint.bias < 0) lastPoint.bias = 0;
        return uint256(uint128(lastPoint.bias));
    }

    /**
     * @dev Returns the gFOREX supply at time t.
     */
    function supplyAt(Point memory point, uint256 t)
        private
        view
        returns (uint256)
    {
        uint256 t_i = (point.ts / WEEK) * WEEK;
        for (uint256 i = 0; i < 255; i++) {
            t_i += WEEK;
            int128 dSlope;
            if (t_i > t) {
                t_i = t;
            } else {
                dSlope = slopeChanges[t_i];
            }
            point.bias -= point.slope * int128(int256(t_i) - int256(point.ts));
            if (t_i == t) break;
            point.slope += dSlope;
            point.ts = t_i;
        }
        if (point.bias < 0) point.bias = 0;
        return uint256(uint128(point.bias));
    }

    /**
     * @dev Returns the total gFOREX supply.
     */
    function totalSupply() external view returns (uint256) {
        uint256 _epoch = epoch;
        Point memory lastPoint = pointHistory[epoch];
        return supplyAt(lastPoint, block.timestamp);
    }

    /**
     * @dev Returns the total gFOREX supply at a block.
     * @param blockNumber The block to calculate the supply at.
     */
    function totalSupplyAt(uint256 blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber <= block.number);
        uint256 _epoch = epoch;
        uint256 targetEpoch = findBlockEpoch(blockNumber, _epoch);

        Point memory point = pointHistory[targetEpoch];
        uint256 dt = 0;

        if (targetEpoch < _epoch) {
            Point memory pointNext = pointHistory[targetEpoch + 1];
            if (point.blk != pointNext.blk) {
                dt =
                    ((blockNumber - point.blk) * (pointNext.ts - point.ts)) /
                    (pointNext.blk - point.blk);
            }
        } else if (point.blk != block.number) {
            dt =
                ((blockNumber - point.blk) * (block.timestamp - point.ts)) /
                (block.number - point.blk);
        }

        // Now, dt contains info on how far the current block is beyond "point".
        return supplyAt(point, point.ts + dt);
    }

    /**
     * @dev Measure balance of `account` at block height `blockNumber`
     * @param account Account to check balance from
     * @param blockNumber Block to calculate the balance at
     */
    function balanceOfAt(address account, uint256 blockNumber)
        external
        view
        returns (uint256)
    {
        // Copying and pasting totalSupply code because Vyper cannot pass by
        // reference yet
        require(blockNumber <= block.number);

        // Binary search
        uint256 _min = 0;
        uint256 _max = userPointEpoch[account];

        // Will be always enough for 128-bit numbers
        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (userPointHistory[account][_mid].blk <= blockNumber) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        Point memory upoint = userPointHistory[account][_min];
        uint256 max_epoch = epoch;
        uint256 _epoch = findBlockEpoch(blockNumber, max_epoch);
        Point memory point_0 = pointHistory[_epoch];
        uint256 d_block = 0;
        uint256 d_t = 0;

        if (_epoch < max_epoch) {
            Point memory point_1 = pointHistory[_epoch + 1];
            d_block = point_1.blk - point_0.blk;
            d_t = point_1.ts - point_0.ts;
        } else {
            d_block = block.number - point_0.blk;
            d_t = block.timestamp - point_0.ts;
        }

        uint256 block_time = point_0.ts;
        if (d_block != 0) {
            block_time += (d_t * (blockNumber - point_0.blk)) / d_block;
        }
        upoint.bias -=
            upoint.slope *
            (int128(uint128(block_time)) - int128(uint128(upoint.ts)));

        return upoint.bias >= 0 ? uint256(int256(upoint.bias)) : 0;
    }

    /**
     * @dev Returns whether addr is a contract (except for constructor).
     */
    function isContract(address addr) private returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function EMPTY_POINT_FACTORY() private view returns (Point memory) {
        return Point({bias: 0, slope: 0, ts: 0, blk: 0});
    }

    function EMPTY_LOCKED_BALANCE_FACTORY()
        private
        view
        returns (LockedBalance memory)
    {
        return LockedBalance({amount: 0, end: 0});
    }

    /** @dev Protected UUPS upgrade authorization fuction */
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/rewards/IRewardPool.sol";

/*                                                *\
 *                ,.-"""-.,                       *
 *               /   ===   \                      *
 *              /  =======  \                     *
 *           __|  (o)   (0)  |__                  *
 *          / _|    .---.    |_ \                 *
 *         | /.----/ O O \----.\ |                *
 *          \/     |     |     \/                 *
 *          |                   |                 *
 *          |                   |                 *
 *          |                   |                 *
 *          _\   -.,_____,.-   /_                 *
 *      ,.-"  "-.,_________,.-"  "-.,             *
 *     /          |       |  ╭-╮     \            *
 *    |           l.     .l  ┃ ┃      |           *
 *    |            |     |   ┃ ╰━━╮   |           *
 *    l.           |     |   ┃ ╭╮ ┃  .l           *
 *     |           l.   .l   ┃ ┃┃ ┃  | \,         *
 *     l.           |   |    ╰-╯╰-╯ .l   \,       *
 *      |           |   |           |      \,     *
 *      l.          |   |          .l        |    *
 *       |          |   |          |         |    *
 *       |          |---|          |         |    *
 *       |          |   |          |         |    *
 *       /"-.,__,.-"\   /"-.,__,.-"\"-.,_,.-"\    *
 *      |            \ /            |         |   *
 *      |             |             |         |   *
 *       \__|__|__|__/ \__|__|__|__/ \_|__|__/    *
\*                                                 */

/// @notice A receipt token for an ERC20 stake in the RewardPool.
contract StakedErc20 is ERC20, ReentrancyGuard {
    using SafeERC20 for ERC20;

    ERC20 public immutable depositToken;
    IRewardPool public immutable rewardPool;
    bytes32 public immutable rewardPoolAlias;

    modifier onlyRewardPool() {
        require(msg.sender == address(rewardPool), "StakedErc20: unauthorised");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address depositToken_,
        address rewardPool_,
        bytes32 rewardPoolAlias_
    ) ERC20(name_, symbol_) {
        require(
            depositToken_ != address(0) && rewardPool_ != address(0),
            "StakedErc20: invalid address"
        );
        require(depositToken_ != rewardPool_);
        require(depositToken_ != address(this));
        depositToken = ERC20(depositToken_);
        rewardPool = IRewardPool(rewardPool_);
        rewardPoolAlias = rewardPoolAlias_;
    }

    function decimals() public view override returns (uint8) {
        return depositToken.decimals();
    }

    /**
     * @dev Allows the RewardPool contract to mint tokens for stakers.
     * @param account The address to mint to.
     * @param amount The token amount to mint.
     */
    function mint(address account, uint256 amount) external onlyRewardPool {
        _validateMint(account, amount);
        _mint(account, amount);
    }

    /**
     * @dev Allows the RewardPool contract to burn tokens for stakers.
     * @param account The address to burn from.
     * @param amount The token amount to burn.
     */
    function burn(address account, uint256 amount) external onlyRewardPool {
        _validateBurn(account, amount);
        _burn(account, amount);
    }

    /**
     * @dev Overrides the _transfer function, unstaking the underlying
     *      assets from the sender and staking for the recipient.
     *      This ensures that all holders have a balance equal to
     *      their stake amount of the RewardPool contract.
     *      Rather than transferring, tokens are burned from the sender
     *      and minted to the receiver via the RewardPool.
     * @param sender The address of the token sender.
     * @param recipient The address of the token recipient.
     * @param amount The token amount being transferred.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override nonReentrant {
        uint256 poolId = _getRewardPoolId();
        // Unstake for the sender. The underlying token is
        // transferred into this contract.
        uint256 unstakeError = rewardPool.unstake(sender, amount, poolId);
        require(unstakeError == 0, "StakedErc20: failed to unstake sender");
        // Approve RewardPool to spend the underlying token.
        depositToken.safeApprove(address(rewardPool), amount);
        // Stake the underlying token for the receiver.
        uint256 stakeError = rewardPool.stake(recipient, amount, poolId);
        require(stakeError == 0, "StakedErc20: failed to stake receiver");
    }

    /**
     * @dev Validates the mint by checking that the resulting token
     *      balance for the user matches their deposit in RewardPool.
     * @param account The address to mint to.
     * @param amount The token amount to mint.
     */
    function _validateMint(address account, uint256 amount) private view {
        uint256 deposit = _getDepositAmount(account);
        uint256 futureBalance = balanceOf(account) + amount;
        require(deposit == futureBalance, "StakedErc20: mint is invalid");
    }

    /**
     * @dev Validates the burn by checking that the resulting token
     *      balance for the user matches their deposit in RewardPool.
     * @param account The address to burn from.
     * @param amount The token amount to burn.
     */
    function _validateBurn(address account, uint256 amount) private view {
        uint256 deposit = _getDepositAmount(account);
        uint256 futureBalance = balanceOf(account) - amount;
        require(deposit == futureBalance, "StakedErc20: burn is invalid");
    }

    /**
     * @dev Gets the deposit amount from the specified RewardPool.
     * @param account The user address to get the deposit for.
     */
    function _getDepositAmount(address account) private view returns (uint256) {
        uint256 poolId = _getRewardPoolId();
        return rewardPool.getDeposit(account, poolId).amount;
    }

    /**
     * @dev Gets the reward pool ID from the alias.
     */
    function _getRewardPoolId() private view returns (uint256) {
        (bool found, uint256 poolId) =
            rewardPool.getPoolIdByAlias(rewardPoolAlias);
        require(found, "StakedErc20: reward pool not found");
        return poolId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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