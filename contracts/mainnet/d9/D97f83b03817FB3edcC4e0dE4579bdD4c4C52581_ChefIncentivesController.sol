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

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
/// @author Gnosis Developers
/// @dev Gas-efficient version of Openzeppelin's SafeERC20 contract.
library GPv2SafeERC20 {
    /// @dev Wrapper around a call to the ERC20 function `transfer` that reverts
    /// also when the token returns `false`.
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        bytes4 selector_ = token.transfer.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(add(freeMemoryPointer, 36), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "GPv2: failed transfer");
    }

    /// @dev Wrapper around a call to the ERC20 function `transferFrom` that
    /// reverts also when the token returns `false`.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transferFrom.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(
                add(freeMemoryPointer, 4),
                and(from, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(
                add(freeMemoryPointer, 36),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(add(freeMemoryPointer, 68), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "GPv2: failed transferFrom");
    }

    /// @dev Verifies that the last return was a successful `transfer*` call.
    /// This is done by checking that the return data is either empty, or
    /// is a valid ABI encoded boolean.
    function getLastTransferResult(
        IERC20 token
    ) private view returns (bool success) {
        // NOTE: Inspecting previous return data requires assembly. Note that
        // we write the return data to memory 0 in the case where the return
        // data size is 32, this is OK since the first 64 bytes of memory are
        // reserved by Solidy as a scratch space that can be used within
        // assembly blocks.
        // <https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            /// @dev Revert with an ABI encoded Solidity error with a message
            /// that fits into 32-bytes.
            ///
            /// An ABI encoded Solidity error has the following memory layout:
            ///
            /// ------------+----------------------------------
            ///  byte range | value
            /// ------------+----------------------------------
            ///  0x00..0x04 |        selector("Error(string)")
            ///  0x04..0x24 |      string offset (always 0x20)
            ///  0x24..0x44 |                    string length
            ///  0x44..0x64 | string value, padded to 32-bytes
            function revertWithMessage(length, message) {
                mstore(0x00, "\x08\xc3\x79\xa0")
                mstore(0x04, 0x20)
                mstore(0x24, length)
                mstore(0x44, message)
                revert(0x00, 0x64)
            }

            switch returndatasize()
            // Non-standard ERC20 transfer without return.
            case 0 {
                // NOTE: When the return data size is 0, verify that there
                // is code at the address. This is done in order to maintain
                // compatibility with Solidity calling conventions.
                // <https://docs.soliditylang.org/en/v0.7.6/control-structures.html#external-function-calls>
                if iszero(extcodesize(token)) {
                    revertWithMessage(20, "GPv2: not a contract")
                }

                success := 1
            }
            // Standard ERC20 transfer returning boolean success value.
            case 32 {
                returndatacopy(0, 0, returndatasize())

                // NOTE: For ABI encoding v1, any non-zero value is accepted
                // as `true` for a boolean. In order to stay compatible with
                // OpenZeppelin's `SafeERC20` library which is known to work
                // with the existing ERC20 implementation we care about,
                // make sure we return success for any non-zero return value
                // from the `transfer*` call.
                success := iszero(iszero(mload(0)))
            }
            default {
                revertWithMessage(31, "GPv2: malformed transfer result")
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library SafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require((z = x + y) >= x);
        }
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require((z = x - y) <= x);
        }
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @param message The error msg
    /// @return z The difference of x and y
    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        unchecked {
            require((z = x - y) <= x, message);
        }
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require(x == 0 || (z = x * y) / x == y);
        }
    }

    /// @notice Returns x / y, reverts if overflows - no specific check, solidity reverts on division by 0
    /// @param x The numerator
    /// @param y The denominator
    /// @return z The product of x and y
    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;
pragma experimental ABIEncoderV2;

import "./IMultiFeeDistribution.sol";

interface IChefIncentivesController {
    /**
     * @notice      Functions as the de facto constructor of the contract,
     *              set up the emission schedule and minting cap of this contract
     * @param       _rewardMinter       The address of MultiFeeDistribution
     * @param       _maxMintable        The max mintable token cap of the contract
     * @param       _startTimeOffset    An array of durations counting from the startTime
     * @param       _rewardsPerSecond   The rewards minted per second based on duration offsets
     */
    function start(
        IMultiFeeDistribution _rewardMinter,
        uint256 _maxMintable,
        uint128[] memory _startTimeOffset,
        uint128[] memory _rewardsPerSecond
    ) external;

    /**
     * @notice      Add a new incentivized pool to the contract
     * @dev         Only callable via Pool Configurator
     * @param       _token      The address of the incentizied asset (MToken, Debt Tokens)
     * @param       _allocPoint The allocated weightage for the incentivized pool
     */
    function addPool(address _token, uint256 _allocPoint) external;

    /**
     * @notice      Update alloc points of incentivized pool in batch
     * @dev         Only callable by pool configurator
     * @param       _tokens         The array of incentivized pools
     * @param       _allocPoints    The array of new alloc points for incentivized pools
     */
    function batchUpdateAllocPoint(
        address[] calldata _tokens,
        uint256[] calldata _allocPoints
    ) external;

    /**
     * @notice      Record OnwardIncentivesController for a specific pool
     * @param       _token                      The address of the pool
     * @param       _onwardIncentivesController The address of the OnwardIncentivesController
     */
    function setOnwardIncentives(
        address _token,
        address _onwardIncentivesController
    ) external;

    /**
     * @notice      Set the claim receiver on behalf of user
     * @dev         Only callable by user itself or the PoolConfigurator
     * @param       _user       The address of the user
     * @param       _receiver   The address of the receiver on behalf of _user
     */
    function setClaimReceiver(address _user, address _receiver) external;

    /**
     * @notice      Claim the rewards accumulated over given incentivized pool
     * @dev         Rewards will be minted by the reward minter
     * @param       _user   The address of the user
     * @param       _tokens The array of the incentivized pool that _user wants to claim their rewards
     */
    function claim(address _user, address[] calldata _tokens) external;

    /****************************************/
    /* View Functions */
    /****************************************/

    /**
     * @notice      Return the number of the incentivized pools
     * @return      Total number of pools
     */
    function poolLength() external view returns (uint256);

    /**
     * @notice      Calculate claimable rewards for specific user over given incentizied pools
     * @param       _user   The address of the user
     * @param       _tokens The array of the incentivized pool that _user wants to calculate their rewards
     * @return      The array of claimable rewards for corresponding pools
     */
    function claimableReward(
        address _user,
        address[] calldata _tokens
    ) external view returns (uint256[] memory);

    /****************************************/
    /* Hooks */
    /****************************************/

    /**
     * @notice      Called by the corresponding asset on any update that affects the rewards distribution
     * @dev         If OnwardIncentivesController is set, it will pass on the updated info to it
     * @param       user        The address of the user
     * @param       userBalance The balance of the user of the asset in the lending pool
     * @param       totalSupply The total supply of the asset in the lending pool
     **/
    function handleAction(
        address user,
        uint256 userBalance,
        uint256 totalSupply
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

/**
 * @title   IMultiFeeDistribution
 * @author  maneki.finance
 * @notice  Interface of MultiFeeDistribution to handle the minting of protocol tokens
 */

interface IMultiFeeDistribution {
    function addReward(address rewardsToken) external;

    function mint(address user, uint256 amount, bool withPenalty) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

/**
 * @title   IOnwardIncentivesController
 * @author  maneki.finance
 * @notice  Interface of OnwardIncentivesController with handleAction hook to record
 *          the status of tokens
 */

interface IOnwardIncentivesController {
    /****************************************/
    /* Hooks */
    /****************************************/

    /**
     * @notice      Function hook called by the previous incentives controller to update the status
     *              of an incentivized pool
     * @dev         Can only be called by previous incentives controller
     * @param       _user        The address of the user
     * @param       _balance     The balance of the user of the asset
     * @param       _totalSupply The total supply of the asset
     **/
    function handleAction(
        address _token,
        address _user,
        uint256 _balance,
        uint256 _totalSupply
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import "../interfaces/IChefIncentivesController.sol";
import "../interfaces/IOnwardIncentivesController.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IMultiFeeDistribution.sol";
import "../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import "../dependencies/openzeppelin/contracts/SafeMath.sol";

/**
 * @title   ChefIncentivesController
 * @author  maneki.finance
 * @notice  Used to track and incentivizes the ownership of MTokens and Debt Tokens
 *          of the protocol. Functions as one of the minters contract on MultiFeeDistribution.
 * @dev     Based on Geist Finance's ChefIncentivesController / SushiSwap's MasterChef
 */
contract ChefIncentivesController is IChefIncentivesController {
    using GPv2SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }
    // Info of each pool.
    struct PoolInfo {
        uint256 totalSupply;
        uint256 allocPoint; // How many allocation points assigned to this pool.
        uint256 lastRewardTime; // Last second that reward distribution occurs.
        uint256 accRewardPerShare; // Accumulated rewards per share, times 1e12. See below.
        IOnwardIncentivesController onwardIncentives;
    }
    // Info about token emissions for a given time period.
    struct EmissionPoint {
        uint128 startTimeOffset;
        uint128 rewardsPerSecond;
    }

    address public poolConfigurator;

    IMultiFeeDistribution public rewardMinter;
    uint256 public rewardsPerSecond;
    uint256 public maxMintableTokens;
    uint256 public mintedTokens;

    // Info of each pool.
    address[] public registeredTokens;
    mapping(address => PoolInfo) public poolInfo;

    // Data about the future reward rates. emissionSchedule stored in reverse chronological order,
    // whenever the number of blocks since the start block exceeds the next block offset a new
    // reward rate is applied.
    EmissionPoint[] public emissionSchedule;
    // token => user => Info of each user that stakes LP tokens.
    mapping(address => mapping(address => UserInfo)) public userInfo;
    // user => base claimable balance
    mapping(address => uint256) public userBaseClaimable;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when reward mining starts.
    uint256 public startTime;

    // account earning rewards => receiver of rewards for this account
    // if receiver is set to address(0), rewards are paid to the earner
    // this is used to aid 3rd party contract integrations
    mapping(address => address) public claimReceiver;

    event BalanceUpdated(
        address indexed token,
        address indexed user,
        uint256 balance,
        uint256 totalSupply
    );

    /**
     * @notice      The constructor of the contract. Initialization parameters
     *              were moved to start() function
     * @param       _poolConfigurator   The address of PoolConfigurator
     */

    constructor(address _poolConfigurator) {
        poolConfigurator = _poolConfigurator;
    }

    /****************************************/
    /* Functions */
    /****************************************/

    /// @inheritdoc IChefIncentivesController
    function start(
        IMultiFeeDistribution _rewardMinter,
        uint256 _maxMintable,
        uint128[] memory _startTimeOffset,
        uint128[] memory _rewardsPerSecond
    ) public {
        require(
            msg.sender == poolConfigurator,
            "ChefIncentivesController: Only PoolConfigurator can start the contract"
        );
        require(
            startTime == 0,
            "ChefIncentivesController: Contract already Started"
        );
        startTime = block.timestamp;
        rewardMinter = _rewardMinter;
        maxMintableTokens = _maxMintable;
        int256 length = int256(_startTimeOffset.length);
        for (int256 i = length - 1; i + 1 != 0; i--) {
            emissionSchedule.push(
                EmissionPoint({
                    startTimeOffset: _startTimeOffset[uint256(i)],
                    rewardsPerSecond: _rewardsPerSecond[uint256(i)]
                })
            );
        }
    }

    /// @inheritdoc IChefIncentivesController
    function addPool(address _token, uint256 _allocPoint) external {
        require(
            msg.sender == poolConfigurator,
            "ChefIncentivesController: Only PoolConfigurator can call add pool"
        );
        require(
            poolInfo[_token].lastRewardTime == 0,
            "ChefIncentivesController: Pool already exists"
        );
        _updateEmissions();
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        registeredTokens.push(_token);
        poolInfo[_token] = PoolInfo({
            totalSupply: 0,
            allocPoint: _allocPoint,
            lastRewardTime: block.timestamp,
            accRewardPerShare: 0,
            onwardIncentives: IOnwardIncentivesController(address(0))
        });
    }

    /// @inheritdoc IChefIncentivesController
    function batchUpdateAllocPoint(
        address[] calldata _tokens,
        uint256[] calldata _allocPoints
    ) external {
        require(
            msg.sender == poolConfigurator,
            "ChefIncentivesController: Only PoolConfigurator can batch update alloc points"
        );
        require(
            _tokens.length == _allocPoints.length,
            "ChefIncentivesController: Invalid parameters length"
        );
        _massUpdatePools();
        uint256 _totalAllocPoint = totalAllocPoint;
        for (uint256 i = 0; i < _tokens.length; i++) {
            PoolInfo storage pool = poolInfo[_tokens[i]];
            require(
                pool.lastRewardTime > 0,
                "ChefIncentivesController: Pool does not exist"
            );
            _totalAllocPoint = _totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoints[i]
            );
            pool.allocPoint = _allocPoints[i];
        }
        totalAllocPoint = _totalAllocPoint;
    }

    /// @inheritdoc IChefIncentivesController
    function setOnwardIncentives(
        address _token,
        address _onwardIncentivesController
    ) external {
        require(
            msg.sender == poolConfigurator,
            "ChefIncentivesController: Only PoolConfigurator can set onward incentives"
        );
        require(
            poolInfo[_token].lastRewardTime != 0,
            "ChefIncentivesController: Pool does not exist"
        );
        poolInfo[_token].onwardIncentives = IOnwardIncentivesController(
            _onwardIncentivesController
        );
    }

    /// @inheritdoc IChefIncentivesController
    function setClaimReceiver(address _user, address _receiver) external {
        require(msg.sender == _user || msg.sender == poolConfigurator);
        claimReceiver[_user] = _receiver;
    }

    /// @inheritdoc IChefIncentivesController
    function claim(address _user, address[] calldata _tokens) external {
        require(
            msg.sender == _user,
            "ChefIncentivesController: User can only claim for themselves"
        );
        _updateEmissions();
        uint256 pending = userBaseClaimable[_user];
        userBaseClaimable[_user] = 0;
        uint256 _totalAllocPoint = totalAllocPoint;
        for (uint i = 0; i < _tokens.length; i++) {
            PoolInfo storage pool = poolInfo[_tokens[i]];
            require(pool.lastRewardTime > 0);
            _updatePool(pool, _totalAllocPoint);
            UserInfo storage user = userInfo[_tokens[i]][_user];
            uint256 rewardDebt = user.amount.mul(pool.accRewardPerShare).div(
                1e12
            );
            pending = pending.add(rewardDebt.sub(user.rewardDebt));
            user.rewardDebt = rewardDebt;
        }
        _mint(_user, pending);
    }

    /****************************************/
    /* View Functions */
    /****************************************/

    /// @inheritdoc IChefIncentivesController
    function poolLength() external view returns (uint256) {
        return registeredTokens.length;
    }

    /// @inheritdoc IChefIncentivesController
    function claimableReward(
        address _user,
        address[] calldata _tokens
    ) external view returns (uint256[] memory) {
        uint256[] memory claimable = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            PoolInfo storage pool = poolInfo[token];
            UserInfo storage user = userInfo[token][_user];
            uint256 accRewardPerShare = pool.accRewardPerShare;
            uint256 lpSupply = pool.totalSupply;
            if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
                uint256 duration = block.timestamp.sub(pool.lastRewardTime);
                uint256 reward = duration
                    .mul(rewardsPerSecond)
                    .mul(pool.allocPoint)
                    .div(totalAllocPoint);
                accRewardPerShare = accRewardPerShare.add(
                    reward.mul(1e12).div(lpSupply)
                );
            }
            claimable[i] = user.amount.mul(accRewardPerShare).div(1e12).sub(
                user.rewardDebt
            );
        }
        return claimable;
    }

    /****************************************/
    /* Internal Functions */
    /****************************************/

    /**
     * @notice      Updates the emission rate of rewards per second according to the predefined emission schedule
     * @dev         This function checks if the current block timestamp has surpassed the startTimeOffset of the
     *              latest EmissionPoint in the emission schedule. If yes, it updates the rewardsPerSecond with
     *              the new rate from the EmissionPoint, pops this point from the schedule, and calls _massUpdatePools
     *              to adjust all pools' rewards accrual to the new rate. This ensures that reward rates are adjusted
     *              dynamically over time as per the planned schedule.
     */
    function _updateEmissions() internal {
        uint256 length = emissionSchedule.length;
        if (startTime > 0 && length > 0) {
            EmissionPoint memory e = emissionSchedule[length - 1];
            if (block.timestamp.sub(startTime) > e.startTimeOffset) {
                _massUpdatePools();
                rewardsPerSecond = uint256(e.rewardsPerSecond);
                emissionSchedule.pop();
            }
        }
    }

    /**
     * @notice      Updates reward variables for all registered pools to be current
     * @dev         Iterates over all the pools registered in `registeredTokens` and updates each one.
     *              This is necessary to ensure that the allocation points and rewards are synchronized
     *              with the current state of each pool, especially before any critical operations like
     *              adding a new pool, updating allocation points, or claiming rewards.
     */
    function _massUpdatePools() internal {
        uint256 totalAP = totalAllocPoint;
        uint256 length = registeredTokens.length;
        for (uint256 i = 0; i < length; ++i) {
            _updatePool(poolInfo[registeredTokens[i]], totalAP);
        }
    }

    /**
     * @notice      Updates reward variables of a specific pool to be current as per the latest timestamp.
     * @param       pool                The storage pointer to the pool's information.
     * @param       _totalAllocPoint    The total allocation points of all pools
     * @dev         If the current time is greater than the pool's lastRewardTime, it calculates the rewards accrued
     *              since lastRewardTime, updates the pool's accRewardPerShare, and sets the lastRewardTime to now.
     *              If the total supply of the pool's tokens is zero, updates lastRewardTime without changing
     *              accRewardPerShare to prevent division by zero errors.
     */
    function _updatePool(
        PoolInfo storage pool,
        uint256 _totalAllocPoint
    ) internal {
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 lpSupply = pool.totalSupply;
        if (lpSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 duration = block.timestamp.sub(pool.lastRewardTime);
        uint256 reward = duration
            .mul(rewardsPerSecond)
            .mul(pool.allocPoint)
            .div(_totalAllocPoint);
        pool.accRewardPerShare = pool.accRewardPerShare.add(
            reward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardTime = block.timestamp;
    }

    /**
     * @notice      Internal function to instruct the reward minter to mint tokens for
     *              specific user
     * @param       _user   The address of the user
     * @param       _amount The amount to be minted
     */
    function _mint(address _user, uint256 _amount) internal {
        uint256 minted = mintedTokens;
        if (minted.add(_amount) > maxMintableTokens) {
            _amount = maxMintableTokens.sub(minted);
        }
        if (_amount > 0) {
            mintedTokens = minted.add(_amount);
            address receiver = claimReceiver[_user];
            if (receiver == address(0)) receiver = _user;
            rewardMinter.mint(receiver, _amount, true);
        }
    }

    /****************************************/
    /* Hooks */
    /****************************************/

    /// @inheritdoc IChefIncentivesController
    function handleAction(
        address _user,
        uint256 _totalSupply,
        uint256 _balance
    ) external {
        PoolInfo storage pool = poolInfo[msg.sender];
        require(pool.lastRewardTime > 0);
        if (startTime != 0) {
            _updateEmissions();
            _updatePool(pool, totalAllocPoint);
        }
        UserInfo storage user = userInfo[msg.sender][_user];
        uint256 amount = user.amount;
        uint256 accRewardPerShare = pool.accRewardPerShare;
        if (amount > 0) {
            uint256 pending = amount.mul(accRewardPerShare).div(1e12).sub(
                user.rewardDebt
            );
            if (pending > 0) {
                userBaseClaimable[_user] = userBaseClaimable[_user].add(
                    pending
                );
            }
        }
        user.amount = _balance;
        user.rewardDebt = _balance.mul(accRewardPerShare).div(1e12);
        pool.totalSupply = _totalSupply;
        if (pool.onwardIncentives != IOnwardIncentivesController(address(0))) {
            pool.onwardIncentives.handleAction(
                msg.sender,
                _user,
                _balance,
                _totalSupply
            );
        }
        emit BalanceUpdated(msg.sender, _user, _balance, _totalSupply);
    }
}