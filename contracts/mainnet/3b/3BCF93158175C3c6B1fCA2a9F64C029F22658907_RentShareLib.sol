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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRentShare {
    struct RentShareStorage {
        mapping(uint => Pool) pools; // Pool id to Pool details
        uint256 RENT_PRECISION;
        address rentToken; // token in which rent will be distributed, VTRY
        mapping(string propertySymbol => uint poolId) symbolToPoolId; // symbol of Property token -> Pool Id
        mapping(uint256 poolId => mapping(address propertyTokensHolder => PoolStaker propertyHolderDetails)) poolStakers; // Pool Id -> holder/user -> Details
        mapping(uint poolId => bool isRentActive) propertyRentStatus; // pool id => true ? rent is active : rent is paused
        mapping(address propertyTokenHolder => mapping(uint poolId => uint rentMadeSoFar)) userToPoolToRent; // user => Property Pool Id  => property rent made so far
        mapping(uint poolId => mapping(uint epochNumber => uint totalRentAccumulatedRentPerShare)) epochAccumluatedRentPerShare;
        mapping(uint poolId => uint epoch) poolIdToEpoch;
        // uint public epoch;
        mapping(uint poolId => bool isInitialized) isPoolInitialized;
        bool rentWrapperToogle; // true: means harvestRewards should only be called by a wrapper not users, false: means users can call harvestRent directly
        mapping(string propertySymbol => uint rentClaimLockDuration) propertyToRentClaimDuration; // duration in seconds after which rent can be claimed since harvestRent transaction
    }
    // Staking user for a pool
    struct PoolStaker {
        mapping(uint epoch => uint propertyTokenBalance) epochToTokenBalance;
        mapping(uint epoch => uint rentDebt) epochToRentDebt;
        uint lastEpoch;
        // uint256 amount; // Amount of Property tokens a user holds
        // uint256 rentDebt; // The amount relative to accumulatedRentPerShare the user can't get as rent
    }
    struct Pool {
        IERC20 stakeToken; // Property token
        uint256 tokensStaked; // Total tokens staked
        uint256 lastRentedTimestamp; // Last block time the user had their rent calculated
        uint256 accumulatedRentPerShare; // Accumulated rent per share times RENT_PRECISION
        uint256 rentTokensPerSecond; // Number of rent tokens minted per block for this pool
    }

    struct LockNftDetailEvent {
        address caller;
        uint lockNftTokenId;
        string propertySymbol;
        uint amount;
    }

    struct UserEpochsRent {
        uint poolId;
        address user;
        uint fromEpoch;
        uint toEpoch;
    }

    function createPool(
        IERC20 _stakeToken,
        string memory symbol,
        uint256 _poolId
    ) external;

    function deposit(
        string calldata _propertySymbol,
        address _sender,
        uint256 _amount
    ) external;

    function withdraw(
        string calldata _propertySymbol,
        address _sender,
        uint256 _amount
    ) external;

    function isLockNftMature(uint lockNftTokenId) external view returns (bool);

    function harvestRent(
        string[] calldata symbols,
        address receiver
    ) external returns (uint);

    function getSymbolToPropertyAddress(
        string memory symbol
    ) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {IRentShare} from "./../interfaces/rent/IRentShare.sol";

// ERRORS
error InvalidPoolId(uint poolId);

// This contract uses the library to set and retrieve state variables
library RentShareLib {
    /**
     * @notice Harvest user rent from a given pool id
     * @param _poolId id of the pool.
     * @param sender address of the caller.
     */
    function _harvestRent(
        IRentShare.RentShareStorage storage rsStorage,
        uint256 _poolId,
        address sender
    ) external returns (uint) {
        // @todo first claim any unclaimed rent of previous epochs => if poolStaker.currentEpoch != epoch
        uint unclaimedRentFromPreviousEpochs = getUserUnrealizedRentFromPreviousEpochs(
                rsStorage,
                _poolId,
                sender
            );
        // does not maintains the mapping of staker against epoch, e.g rentDebt, because no need to
        rsStorage.userToPoolToRent[sender][
            _poolId
        ] += unclaimedRentFromPreviousEpochs;
        updatePoolRewards(rsStorage, _poolId);
        return _harvestRentHelper(rsStorage, _poolId, sender);
    }

    /// @notice returns unrealized rent for previous + current epoch
    function getUserUnrealizedRentFromPreviousEpochs(
        IRentShare.RentShareStorage storage rsStorage,
        uint poolId,
        address user
    ) public view returns (uint) {
        // Pool storage p = pools[poolId];
        IRentShare.PoolStaker storage staker = rsStorage.poolStakers[poolId][
            user
        ];
        uint epochCounter = staker.lastEpoch;
        uint rent;
        uint stakerBalanceOnLastActiveEpoch = staker.epochToTokenBalance[
            epochCounter
        ];
        uint epoch = rsStorage.poolIdToEpoch[poolId];
        // now getting unrelaized rent if any
        while (epochCounter != epoch) {
            rent +=
                (stakerBalanceOnLastActiveEpoch *
                    rsStorage.epochAccumluatedRentPerShare[poolId][
                        epochCounter
                    ]) /
                rsStorage.RENT_PRECISION -
                staker.epochToRentDebt[epochCounter];
            epochCounter++;
        }
        return rent;
    }

    function getUserUnrealizedRentFromPreviousEpochsDetailed(
        IRentShare.RentShareStorage storage rsStorage,
        IRentShare.UserEpochsRent memory userEpochsRent
    ) public view returns (uint[] memory, uint[] memory) {
        // Pool storage p = pools[poolId];
        IRentShare.PoolStaker storage staker = rsStorage.poolStakers[
            userEpochsRent.poolId
        ][userEpochsRent.user];
        uint epochCounter = userEpochsRent.fromEpoch;
        uint stakerBalanceOnLastActiveEpoch = staker.epochToTokenBalance[
            epochCounter
        ];
        uint epoch = userEpochsRent.toEpoch;
        uint[] memory rentArray = new uint256[](epoch - epochCounter + 1); // saving 0th slot for current epcoh rent
        uint[] memory epochArray = new uint256[](epoch - epochCounter + 1); // saving 0th slot for current epcoh rent
        // now getting unrelaized rent if any
        uint index = 0;
        while (epochCounter != epoch) {
            rentArray[index] = ((stakerBalanceOnLastActiveEpoch *
                rsStorage.epochAccumluatedRentPerShare[userEpochsRent.poolId][
                    epochCounter
                ]) /
                rsStorage.RENT_PRECISION -
                staker.epochToRentDebt[epochCounter]);
            epochArray[index] = epochCounter;
            index++;
            epochCounter++;
        }
        return (rentArray, epochArray);
    }

    function updatePoolRewards(
        IRentShare.RentShareStorage storage rsStorage,
        uint _poolId
    ) public {
        //fetching the pool
        IRentShare.Pool storage pool = rsStorage.pools[_poolId];
        if (address(pool.stakeToken) == address(0)) {
            revert InvalidPoolId(_poolId);
        }
        if (pool.tokensStaked == 0) {
            pool.lastRentedTimestamp = block.timestamp;
            return;
        }
        //accumulatedRewardPerShare += rewards * REWARDS_PRECISION / tokenStaked this was previously done
        pool.accumulatedRentPerShare = _getAccumulatedRentPerShare(
            rsStorage,
            _poolId
        );
        //updated the last rentUpdated timestamp to current timestamp
        pool.lastRentedTimestamp = block.timestamp;
    }

    /// @notice returns rent that has been accrued since last deposit/withdrawal of user
    function _getAccumulatedRentPerShare(
        IRentShare.RentShareStorage storage rsStorage,
        uint _poolId
    ) public view returns (uint accumulatedRentPerShare) {
        IRentShare.Pool memory pool = rsStorage.pools[_poolId];
        //if the total tokenStaked is zero so far then update the lastRewardedTimestamp as the current block.timeStamp
        if (pool.tokensStaked == 0) {
            return 0;
        }
        //calculating the blockSinceLastReward i.e current block.timestamp - LastTimestampRewarded
        uint256 TimeStampSinceLastReward = block.timestamp -
            pool.lastRentedTimestamp;
        //calculating the rewards since last block rewarded.
        uint256 rewards = (TimeStampSinceLastReward *
            pool.rentTokensPerSecond) / 1e12;
        //accumulatedRewardPerShare += rewards * REWARDS_PRECISION / tokenStaked this was previously done
        accumulatedRentPerShare =
            pool.accumulatedRentPerShare +
            ((rewards * rsStorage.RENT_PRECISION) / pool.tokensStaked);
    }

    function _harvestRentHelper(
        IRentShare.RentShareStorage storage rsStorage,
        uint256 _poolId,
        address sender
    ) public returns (uint) {
        // if rent is active
        if (rsStorage.propertyRentStatus[_poolId]) {
            uint epoch = rsStorage.poolIdToEpoch[_poolId];
            IRentShare.Pool storage pool = rsStorage.pools[_poolId];

            IRentShare.PoolStaker storage staker = rsStorage.poolStakers[
                _poolId
            ][sender];
            uint tokensHeldByUser = staker.lastEpoch ==
                rsStorage.poolIdToEpoch[_poolId]
                ? staker.epochToTokenBalance[rsStorage.poolIdToEpoch[_poolId]]
                : staker.epochToTokenBalance[staker.lastEpoch];

            uint rewardsToHarvest = _getRecentAccruedRent(
                rsStorage,
                _poolId,
                sender,
                tokensHeldByUser
            );
            if (rewardsToHarvest == 0) {
                staker.epochToRentDebt[epoch] =
                    (staker.epochToTokenBalance[epoch] *
                        pool.accumulatedRentPerShare) /
                    rsStorage.RENT_PRECISION;
                return 0;
            }
            // means this much amount of rent user has claimed or is not eligible of claiming
            // staker.rentDebt is over-written in deposit and withdraw deliberatley.
            // will not over-write in case of direct harvestRent when claiming rent
            staker.epochToRentDebt[epoch] =
                (staker.epochToTokenBalance[epoch] *
                    pool.accumulatedRentPerShare) /
                rsStorage.RENT_PRECISION;

            // adding current rent
            rsStorage.userToPoolToRent[sender][_poolId] += rewardsToHarvest;
            return rewardsToHarvest;
        } else return 0;
    }

    function _getRecentAccruedRent(
        IRentShare.RentShareStorage storage rsStorage,
        uint _poolId,
        address _propertyTokenHolder,
        uint tokensHeldByUser
    ) public view returns (uint accruedRent) {
        IRentShare.PoolStaker storage staker = rsStorage.poolStakers[_poolId][
            _propertyTokenHolder
        ];
        uint epoch = rsStorage.poolIdToEpoch[_poolId];

        accruedRent = (((tokensHeldByUser *
            _getAccumulatedRentPerShare(rsStorage, _poolId)) /
            rsStorage.RENT_PRECISION) - staker.epochToRentDebt[epoch]);
    }
}