// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// slither-disable-start timestamp
// solhint-disable max-states-count

import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

import { IPool } from "src/interfaces/pool/IPool.sol";
import { Error } from "src/librairies/Error.sol";

contract Pool is IPool, Initializable {
    using SafeERC20 for IERC20;

    /// @notice The underlying status represents the fundamental status of the pool. This value is set when the pool is
    /// initialized, and may later be updated to 'approved', 'rejected', or 'seeding'. It's important to note that while
    /// this status provides an underlying base for the pool's lifecycle, it does not always reflect the current
    /// operational status of the pool, as the pool's operation can move into locked or unlocked phases over time,
    /// depending on the timestamps related to the seeding and locked periods.
    Status private _underlyingStatus;

    /// @notice The ERC20 token being used for STAKING and REWARDS.
    IERC20 public token;

    /// @notice The treasury address where the rewards are transferred to when pool is rejected.
    address public treasury;
    address public immutable registry;
    address public creator;

    /**
     * @dev StakingInfo struct represents the staking lifecycle. It includes all the timing information about the
     * staking process.
     * This struct is used to reduce the number of state declarations in the contract, due to Solidity limitations on
     * the maximum number of allowed state declarations
     */
    StakingSchedule public stakingSchedule;

    /// @notice The maximum amount of tokens that can be staked in the pool.
    uint256 public maxStakePerPool;

    /**
     * @notice The maximum amount of tokens that can be staked per address.
     * This value should consider the decimals of the token.
     * For example, if the token has 18 decimals and the maximum stake should be 500 tokens,
     * then maxStakePerAddress should be 500 * 1e18.
     */
    uint256 public maxStakePerAddress;

    /// @notice The amount of stakers in the pool.
    uint256 public stakersCount;

    /// @notice The amount of reward tokens distributed during the `locked` period.
    uint256 public rewardAmount;

    /// @notice The fee amount taken by the protocol.
    uint256 public feeAmount;

    /// @notice The amount of protocol fee in basis points (bps) to be paid to the treasury. 1 bps is 0.01%
    uint256 public protocolFeeBps;

    /// @notice The amount of reward tokens distributed per second during the `locked` period.
    uint256 public rewardPerTokenStored;

    /// @notice The total amount of tokens staked in the pool.
    uint256 public totalSupply;

    /// @notice The total amount of tokens locked in the pool.
    uint256 public totalSupplyLocked;

    /// @notice Mapping to store the balances of tokens each account has staked.
    mapping(address => uint256) public balances;

    /// @notice Mapping to store the balances of tokens each account has locked.
    mapping(address => uint256) public balancesLocked;

    /// @notice Mapping to store the reward rate for each user at the time of their latest claimed.
    mapping(address => uint256) public userRewardPerTokenPaid;

    /// @notice The maximum amount the protocol fee can be set to. 10,000 bps is 100%.
    uint256 public constant MAX_PCT = 10_000;

    /*///////////////////////////////////////////////////////////////
                      CONSTRUCTOR / INITIALIZER
    ///////////////////////////////////////////////////////////////*/

    constructor(address _registry) {
        if (_registry == address(0)) revert Error.ZeroAddress();
        registry = _registry;
    }

    modifier onlyRegistry() {
        if (msg.sender != registry) revert Error.Unauthorized();
        _;
    }

    modifier onlyCreator() {
        if (msg.sender != creator) revert Error.Unauthorized();
        _;
    }

    modifier onlyOnCreated() {
        if (_underlyingStatus != Status.Created) revert Error.InvalidStatus();
        _;
    }

    /// @inheritdoc IPool
    function initialize(
        address _creator,
        address _treasury,
        address _token,
        uint256 _seedingPeriod,
        uint256 _lockPeriod,
        uint256 _maxStakePerAddress,
        uint256 _protocolFeeBps,
        uint256 _maxStakePerPool
    ) external initializer {
        if (_creator == address(0)) revert Error.ZeroAddress();
        if (_treasury == address(0)) revert Error.ZeroAddress();
        if (_token == address(0)) revert Error.ZeroAddress();
        if (_seedingPeriod == 0) revert Error.ZeroAmount();
        if (_lockPeriod == 0) revert Error.ZeroAmount();
        if (_maxStakePerAddress == 0) revert Error.ZeroAmount();
        if (_maxStakePerPool <= _maxStakePerAddress) revert StakeLimitMismatch();

        token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));

        stakingSchedule.seedingPeriod = _seedingPeriod;
        stakingSchedule.lockPeriod = _lockPeriod;
        treasury = _treasury;
        creator = _creator;
        _underlyingStatus = Status.Created;
        maxStakePerAddress = _maxStakePerAddress;
        maxStakePerPool = _maxStakePerPool;

        /// No need to check if the protocol fee is too high as it's already been checked in the factory contract.
        protocolFeeBps = _protocolFeeBps;
        /// Since the factory is handling the token transfer, the contract balance is the reward amount.
        /// Passing this value in the params would be pointless.
        feeAmount = (balance * _protocolFeeBps) / MAX_PCT;
        rewardAmount = balance - feeAmount;

        emit PoolInitialized(
            _token,
            _creator,
            _seedingPeriod,
            _lockPeriod,
            balance,
            _protocolFeeBps,
            _maxStakePerAddress,
            _maxStakePerPool
        );
    }

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IPool
     * @dev The status function computes the current operational status of the pool based on the underlying status and
     * the current timestamp in relation to the pool's seeding and locked periods.
     * This function is what external callers should use to understand the current status of the pool.
     */
    function status() public view returns (Status) {
        return _status();
    }

    /// @inheritdoc IPool
    function earned(address account) public view returns (uint256) {
        if (_status() != Status.Locked && _status() != Status.Unlocked) return 0;

        return ((balancesLocked[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18);
    }

    /// @inheritdoc IPool
    function rewardPerToken() public view returns (uint256) {
        // If we haven't been approved yet
        uint256 lastReward = lastTimeRewardApplicable();
        // slither-disable-next-line incorrect-equality
        if (lastReward == 0) {
            return 0;
        }

        // We're still in the seeding phase
        uint256 lockStart = stakingSchedule.lockedStart;
        if (lockStart > lastReward) {
            return 0;
        }

        // No one has deposited yet
        if (totalSupplyLocked == 0) {
            return rewardAmount;
        }

        return (((lastReward - lockStart) * rewardAmount * 1e18) / (stakingSchedule.lockPeriod)) / (totalSupplyLocked);
    }

    /// @inheritdoc IPool
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < stakingSchedule.periodFinish ? block.timestamp : stakingSchedule.periodFinish;
    }

    /*///////////////////////////////////////////////////////////////
    						MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPool
    function approvePool() external onlyRegistry onlyOnCreated {
        _underlyingStatus = Status.Approved;
        emit PoolApproved();
    }

    /// @inheritdoc IPool
    function rejectPool() external onlyRegistry onlyOnCreated {
        _underlyingStatus = Status.Rejected;
        emit PoolRejected();
    }

    /// @inheritdoc IPool
    function retrieveRewardToken() external onlyCreator {
        if (_underlyingStatus != Status.Rejected) revert Error.PoolNotRejected();
        uint256 balance = token.balanceOf(address(this));
        emit RewardsRetrieved(creator, balance);
        rewardAmount = 0;
        feeAmount = 0;
        token.safeTransfer(creator, balance);
    }

    /// @inheritdoc IPool
    function start() external onlyCreator {
        if (_underlyingStatus != Status.Approved) revert Error.PoolNotApproved();

        _underlyingStatus = Status.Seeding;

        // seeding starts now
        stakingSchedule.seedingStart = block.timestamp;
        stakingSchedule.lockedStart = stakingSchedule.seedingStart + stakingSchedule.seedingPeriod;
        stakingSchedule.periodFinish = stakingSchedule.lockedStart + stakingSchedule.lockPeriod;

        _transferProtocolFee();

        emit PoolStarted(stakingSchedule.seedingStart, stakingSchedule.periodFinish);
    }

    /// @inheritdoc IPool
    function stake(uint256 _amount) external {
        _stake(msg.sender, _amount);
    }

    /// @inheritdoc IPool
    function stakeFor(address _staker, uint256 _amount) external {
        if (_staker == address(0)) revert Error.ZeroAddress();
        _stake(_staker, _amount);
    }

    /// @inheritdoc IPool
    function unstakeAll() external {
        if (_status() != Status.Unlocked) revert Error.WithdrawalsDisabled();

        uint256 amount = balances[msg.sender];
        if (amount == 0) revert Error.ZeroAmount();

        totalSupply -= amount;

        balances[msg.sender] -= amount;

        emit Unstaked(msg.sender, amount);
        token.safeTransfer(msg.sender, amount);
    }

    /// @inheritdoc IPool
    function claim() external {
        rewardPerTokenStored = rewardPerToken();

        uint256 reward = earned(msg.sender);
        userRewardPerTokenPaid[msg.sender] = rewardPerTokenStored;

        if (reward > 0) {
            emit RewardPaid(msg.sender, reward);
            token.safeTransfer(msg.sender, reward);
        }
    }

    /*///////////////////////////////////////////////////////////////
    						INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    function _stake(address _staker, uint256 _amount) internal {
        if (_status() != Status.Seeding) revert Error.DepositsDisabled();
        if (_amount == 0) revert Error.ZeroAmount();
        if (balances[_staker] + _amount > maxStakePerAddress) revert Error.MaxStakePerAddressExceeded();
        if (totalSupply + _amount > maxStakePerPool) revert Error.MaxStakePerPoolExceeded();

        if (balances[_staker] == 0) stakersCount++;

        totalSupply += _amount;
        totalSupplyLocked += _amount;
        balances[_staker] += _amount;
        balancesLocked[_staker] += _amount;

        emit Staked(_staker, _amount);
        token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function _status() internal view returns (Status) {
        // The pool is created, rejected or approved but not yet started
        if (
            _underlyingStatus == Status.Created || _underlyingStatus == Status.Rejected
                || _underlyingStatus == Status.Approved
        ) {
            return _underlyingStatus;
        }
        // The pool is in the seeding phase
        else if (_underlyingStatus == Status.Seeding && block.timestamp <= stakingSchedule.lockedStart) {
            return Status.Seeding;
        }
        // The pool is in the locked phase
        else if (
            _underlyingStatus == Status.Seeding && block.timestamp > stakingSchedule.lockedStart
                && block.timestamp <= stakingSchedule.periodFinish
        ) {
            return Status.Locked;
        }
        // The pool is in the unlocked phase
        else if (_underlyingStatus == Status.Seeding && block.timestamp > stakingSchedule.periodFinish) {
            return Status.Unlocked;
        }

        return Status.Uninitialized;
    }

    /**
     * @dev While possible, it is highly improbable for a pool to have zero fees, so we can bypass the gas-consuming
     * check of feeAmount being equal to zero.
     * This optimization is aimed at the majority (> 99%) of scenarios, where an actual fee exists. It enables the
     * caller to save some gas.
     * The rare scenario (< 1%) where no fee is present will still safely execute the transaction, but essentially
     * perform no operation since there's no fee to process.
     */
    function _transferProtocolFee() internal {
        emit ProtocolFeePaid(treasury, feeAmount);
        token.safeTransfer(treasury, feeAmount);
    }
}

// slither-disable-end timestamp

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.19;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
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
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        if (nonceAfter != nonceBefore + 1) {
            revert SafeERC20FailedOperation(address(token));
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.19;

import {Address} from "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev The contract is already initialized.
     */
    error AlreadyInitialized();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        if (!(isTopLevelCall && _initialized < 1) && !(address(this).code.length == 0 && _initialized == 1)) {
            revert AlreadyInitialized();
        }
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        if (_initializing || _initialized >= version) {
            revert AlreadyInitialized();
        }
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        if (!_initializing) {
            revert NotInitializing();
        }
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        if (_initializing) {
            revert AlreadyInitialized();
        }
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IPool {
    /*///////////////////////////////////////////////////////////////
                            STRUCTS/ENUMS
    ///////////////////////////////////////////////////////////////*/

    enum Status {
        Uninitialized,
        Created,
        Approved,
        Rejected,
        Seeding,
        Locked,
        Unlocked
    }

    struct StakingSchedule {
        /// @notice The timestamp when the seeding period starts.
        uint256 seedingStart;
        /// @notice The duration of the seeding period.
        uint256 seedingPeriod;
        /// @notice The timestamp when the locked period starts.
        uint256 lockedStart;
        /// @notice The duration of the lock period, which is also the duration of rewards.
        uint256 lockPeriod;
        /// @notice The timestamp when the rewards period ends.
        uint256 periodFinish;
    }

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    error StakeLimitMismatch();

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/

    event PoolInitialized(
        address indexed token,
        address indexed creator,
        uint256 seedingPeriod,
        uint256 lockPeriod,
        uint256 amount,
        uint256 fee,
        uint256 maxStakePerAddress,
        uint256 maxStakePerPool
    );

    event PoolApproved();

    event PoolRejected();

    event PoolStarted(uint256 seedingStart, uint256 periodFinish);

    event RewardsRetrieved(address indexed creator, uint256 amount);

    event Staked(address indexed account, uint256 amount);

    event Unstaked(address indexed account, uint256 amount);

    event RewardPaid(address indexed account, uint256 amount);

    event ProtocolFeePaid(address indexed treasury, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                            INITIALIZER
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes a new staking pool
     * @param _creator The address of pool creator
     * @param _treasury The address of the treasury where the rewards will be distributed
     * @param _token The address of the token to be staked
     * @param _seedingPeriod The period in seconds during which users are able to stake
     * @param _lockPeriod The period in seconds during which the staked tokens are locked
     * @param _maxStakePerAddress The maximum amount of tokens that can be staked by a single address
     * @param _protocolFeeBps The fee charged by the protocol for each pool in bps
     * @param _maxStakePerPool The maximum amount of tokens that can be staked in the pool
     */
    function initialize(
        address _creator,
        address _treasury,
        address _token,
        uint256 _seedingPeriod,
        uint256 _lockPeriod,
        uint256 _maxStakePerAddress,
        uint256 _protocolFeeBps,
        uint256 _maxStakePerPool
    ) external;

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the registry this pool is setup with
     */
    function registry() external view returns (address);

    /**
     * @notice Returns the current operational status of the pool.
     * @return The current status of the pool.
     */
    function status() external view returns (Status);

    /**
     * @notice Returns the earned rewards of a specific account
     * @param account The address of the account
     * @return The amount of rewards earned by the account
     */
    function earned(address account) external view returns (uint256);

    /**
     * @notice Calculates the rewards per token for the current time.
     * @dev The total amount of rewards available in the system is fixed, and it needs to be distributed among the users
     * based on their token balances and the lock duration.
     * Rewards per token represent the amount of rewards that each token is entitled to receive at the current time.
     * The calculation takes into account the reward rate (rewardAmount / lockPeriod), the time duration since the last
     * update,
     * and the total supply of tokens in the pool.
     * @return The updated rewards per token value for the current block.
     */
    function rewardPerToken() external view returns (uint256);

    /**
     * @notice Get the last time where rewards are applicable.
     * @return The last time where rewards are applicable.
     */
    function lastTimeRewardApplicable() external view returns (uint256);

    /**
     * @notice Get the token used in the pool
     * @return The ERC20 token used in the pool
     */
    function token() external view returns (IERC20);

    /*///////////////////////////////////////////////////////////////
    					MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Approves the pool to start accepting stakes
    function approvePool() external;

    /// @notice Rejects the pool
    function rejectPool() external;

    /// @notice Retrieves the reward tokens from the pool if the pool is rejected
    function retrieveRewardToken() external;

    /// @notice Starts the seeding period for the pool, during which deposits are accepted
    function start() external;

    /**
     * @notice Stakes a certain amount of tokens
     * @param _amount The amount of tokens to stake
     */
    function stake(uint256 _amount) external;

    /**
     * @notice Stakes a certain amount of tokens for a specified address
     * @param _staker The address for which the tokens are being staked
     * @param _amount The amount of tokens to stake
     */
    function stakeFor(address _staker, uint256 _amount) external;

    /**
     * @notice Unstakes all staked tokens
     */
    function unstakeAll() external;

    /**
     * @notice Claims the earned rewards
     */
    function claim() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Error {
    error AlreadyInitialized();
    error ZeroAddress();
    error ZeroAmount();
    error ArrayLengthMismatch();
    error AddFailed();
    error RemoveFailed();
    error Unauthorized();
    error UnknownTemplate();
    error DeployerNotFound();
    error PoolNotRejected();
    error PoolNotApproved();
    error DepositsDisabled();
    error WithdrawalsDisabled();
    error InsufficientBalance();
    error MaxStakePerAddressExceeded();
    error MaxStakePerPoolExceeded();
    error FeeTooHigh();
    error MismatchRegistry();
    error InvalidStatus();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.19;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.19;

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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with a
     * `customRevert` function as a fallback when `target` reverts.
     *
     * Requirements:
     *
     * - `customRevert` must be a reverting function.
     */
    function functionCall(
        address target,
        bytes memory data,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, customRevert);
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
        return functionCallWithValue(target, data, value, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with a `customRevert` function as a fallback revert reason when `target` reverts.
     *
     * Requirements:
     *
     * - `customRevert` must be a reverting function.
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided `customRevert`) in case of unsuccessful call or if target was not a contract.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check if target is a contract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                if (target.code.length == 0) {
                    revert AddressEmptyCode(target);
                }
            }
            return returndata;
        } else {
            _revert(returndata, customRevert);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or with a default revert error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal view returns (bytes memory) {
        return verifyCallResult(success, returndata, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-verifyCallResult-bool-bytes-}[`verifyCallResult`], but with a
     * `customRevert` function as a fallback when `success` is `false`.
     *
     * Requirements:
     *
     * - `customRevert` must be a reverting function.
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, customRevert);
        }
    }

    /**
     * @dev Default reverting function when no `customRevert` is provided in a function call.
     */
    function defaultRevert() internal pure {
        revert FailedInnerCall();
    }

    function _revert(bytes memory returndata, function() internal view customRevert) private view {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            customRevert();
            revert FailedInnerCall();
        }
    }
}