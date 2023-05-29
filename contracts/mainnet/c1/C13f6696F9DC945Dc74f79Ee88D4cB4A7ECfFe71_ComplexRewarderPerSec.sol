// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

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
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
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
        require(_initializing, "Initializable: contract is not initializing");
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOperators {
    function getOperatorLevel(address op) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IComplexRewarder.sol";
import "./interfaces/IFarmDistributor.sol";
import "../core/interfaces/IOperators.sol";
import "./libraries/BoringERC20.sol";

contract ComplexRewarderPerSec is IComplexRewarder, Initializable, ReentrancyGuardUpgradeable {
    using BoringERC20 for IBoringERC20;

    IBoringERC20 public override rewardToken;
    IFarmDistributor public distributor;
    IOperators public operators;

    struct UserInfo {
        uint256 amount; /// `amount` LP token amount the user has provided.
        uint256 rewardDebt; /// `rewardDebt` The amount of REWARD entitled to the user.
    }

    struct PoolInfo {
        uint256 accTokenPerShare; /// `accTokenPerShare` Amount of REWARD each LP token is worth.
        uint256 startTimestamp; /// `startTimestamp` The start timestamp of rewards.
        uint256 lastRewardTimestamp; /// `lastRewardTimestamp` The last timestamp REWARD was rewarded to the poolInfo.
        uint256 totalRewards; /// `totalRewards` The amount of rewards added to the pool.
    }

    struct RewardInfo {
        uint256 startTimestamp; /// `startTimestamp` The start timestamp of rewards
        uint256 endTimestamp; /// `endTimestamp` The end timestamp of rewards
        uint256 rewardPerSec; /// `rewardPerSec` The amount of rewards per second
    }

    uint256[] public poolIds;
    uint256 public rewardInfoLimit;
    uint256 private ACC_TOKEN_PRECISION; // The precision factor

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => PoolInfo) public poolInfo;
    mapping(uint256 => RewardInfo[]) public poolRewardInfo;

    event AddPool(uint256 indexed pid);
    event AddRewardInfo(uint256 indexed pid, uint256 indexed phase, uint256 endTimestamp, uint256 rewardPerSec);
    event OnReward(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 oldRate, uint256 newRate);
    event UpdatePool(uint256 indexed pid, uint256 lastRewardTimestamp, uint256 lpSupply, uint256 accTokenPerShare);

    modifier onlyDistributor() {
        require(msg.sender == address(distributor), "onlyDistributor: only Distributor can call this function");
        _;
    }

    modifier onlyOperator(uint256 level) {
        require(operators.getOperatorLevel(msg.sender) >= level, "invalid operator");
        _;
    }

    function initialize(
        IBoringERC20 _rewardToken,
        IFarmDistributor _distributor,
        address _operators
    ) public initializer {
        __ReentrancyGuard_init();
        require(
            AddressUpgradeable.isContract(address(_rewardToken)),
            "constructor: reward token must be a valid contract"
        );
        require(
            AddressUpgradeable.isContract(address(_distributor)),
            "constructor: FarmDistributor must be a valid contract"
        );
        require(AddressUpgradeable.isContract(_operators), "operators invalid");
        operators = IOperators(_operators);
        rewardToken = _rewardToken;
        distributor = _distributor;

        uint256 decimalsRewardToken = _rewardToken.safeDecimals();
        require(decimalsRewardToken < 30, "constructor: reward token decimals must be inferior to 30");

        ACC_TOKEN_PRECISION = uint256(10 ** (uint256(30) - (decimalsRewardToken)));
        rewardInfoLimit = 52; //1y /// how many phases are allowed
    }

    /// @notice Add a new pool. Can only be called by the operator.
    /// @param _pid pool id on DistributorV2
    function add(uint256 _pid, uint256 _startTimestamp) public onlyOperator(1) {
        require(poolInfo[_pid].lastRewardTimestamp == 0, "pool already exists");

        poolInfo[_pid] = PoolInfo({
            startTimestamp: _startTimestamp,
            lastRewardTimestamp: _startTimestamp,
            accTokenPerShare: 0,
            totalRewards: 0
        });

        poolIds.push(_pid);
        emit AddPool(_pid);
    }

    /// @notice if the new reward info is added, the reward & its end timestamp will be extended by the newly pushed reward info.
    function addRewardInfo(
        uint256 _pid,
        uint256 _endTimestamp,
        uint256 _rewardPerSec
    ) external payable onlyOperator(3) {
        RewardInfo[] storage rewardInfo = poolRewardInfo[_pid];
        PoolInfo storage pool = poolInfo[_pid];
        require(rewardInfo.length < rewardInfoLimit, "add reward info: reward info length exceeds the limit");
        require(
            rewardInfo.length == 0 || rewardInfo[rewardInfo.length - 1].endTimestamp >= block.timestamp,
            "add reward info: reward period ended"
        );
        require(
            rewardInfo.length == 0 || rewardInfo[rewardInfo.length - 1].endTimestamp < _endTimestamp,
            "add reward info: bad new endTimestamp"
        );

        uint256 startTimestamp = rewardInfo.length == 0
            ? pool.startTimestamp
            : rewardInfo[rewardInfo.length - 1].endTimestamp;

        uint256 timeRange = _endTimestamp - startTimestamp;
        uint256 totalRewards = timeRange * _rewardPerSec;
        rewardToken.safeTransferFrom(msg.sender, address(this), totalRewards);

        pool.totalRewards += totalRewards;

        rewardInfo.push(
            RewardInfo({startTimestamp: startTimestamp, endTimestamp: _endTimestamp, rewardPerSec: _rewardPerSec})
        );

        emit AddRewardInfo(_pid, rewardInfo.length - 1, _endTimestamp, _rewardPerSec);
    }

    /// @notice Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(
        uint256 _pid,
        uint256 _amount,
        address _beneficiary
    ) external nonReentrant onlyOperator(3) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lpSupply = distributor.poolTotalLp(_pid);

        uint256 currentStakingPendingReward = _pendingTokens(_pid, lpSupply, 0);

        require(
            currentStakingPendingReward + _amount <= pool.totalRewards,
            "emergency reward withdraw: not enough reward token"
        );
        pool.totalRewards -= _amount;

        rewardToken.safeTransfer(_beneficiary, _amount);
    }

    /// @notice Withdraw reward. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _amount, address _beneficiary) external nonReentrant onlyOperator(3) {
        rewardToken.safeTransfer(_beneficiary, _amount);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() external nonReentrant {
        _massUpdatePools();
    }

    /// @notice Function called by FarmDistributor whenever staker claims VELA harvest. Allows staker to also receive a 2nd reward token.
    /// @param _user Address of user
    /// @param _amount Number of LP tokens the user has
    function onVelaReward(uint256 _pid, address _user, uint256 _amount) external override onlyDistributor {
        PoolInfo memory pool = _updatePool(_pid);
        UserInfo storage user = userInfo[_pid][_user];

        uint256 pending = 0;
        uint256 rewardBalance = 0;

        rewardBalance = rewardToken.balanceOf(address(this));

        if (user.amount > 0) {
            pending = (((user.amount * pool.accTokenPerShare) / ACC_TOKEN_PRECISION) - user.rewardDebt);

            if (pending > 0) {
                if (pending > rewardBalance) {
                    rewardToken.safeTransfer(_user, rewardBalance);
                } else {
                    rewardToken.safeTransfer(_user, pending);
                }
            }
        }

        user.amount = _amount;

        user.rewardDebt = (user.amount * pool.accTokenPerShare) / ACC_TOKEN_PRECISION;

        emit OnReward(_user, pending);
    }

    /// @notice Update reward variables of the given pool.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint256 _pid) external nonReentrant returns (PoolInfo memory pool) {
        return _updatePool(_pid);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function _massUpdatePools() internal {
        uint256 length = poolIds.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(poolIds[pid]);
        }
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function _updatePool(uint256 pid) internal returns (PoolInfo memory pool) {
        pool = poolInfo[pid];
        RewardInfo[] memory rewardInfo = poolRewardInfo[pid];
        if (block.timestamp <= pool.lastRewardTimestamp) {
            return pool;
        }

        uint256 lpSupply = distributor.poolTotalLp(pid);

        if (lpSupply == 0) {
            // if there is no total supply, return and use the pool's start timestamp as the last reward timestamp
            // so that ALL reward will be distributed.
            // however, if the first deposit is out of reward period, last reward timestamp will be its timestamp
            // in order to keep the multiplier = 0
            if (block.timestamp > _endTimestampOf(pid, block.timestamp)) {
                pool.lastRewardTimestamp = block.timestamp;
                emit UpdatePool(pid, pool.lastRewardTimestamp, lpSupply, pool.accTokenPerShare);
            }

            return pool;
        }

        /// @dev for each reward info
        for (uint256 i = 0; i < rewardInfo.length; ++i) {
            // @dev get multiplier based on current timestamp and rewardInfo's end timestamp
            // multiplier will be a range of either (current timestamp - pool.timestamp)
            // or (reward info's endtimestamp - pool.timestamp) or 0
            uint256 timeElapsed = getTimeElapsed(pool.lastRewardTimestamp, block.timestamp, rewardInfo[i].endTimestamp);
            if (timeElapsed == 0) continue;

            // @dev if currentTimestamp exceed end timestamp, use end timestamp as the last reward timestamp
            // so that for the next iteration, previous endTimestamp will be used as the last reward timestamp
            if (block.timestamp > rewardInfo[i].endTimestamp) {
                pool.lastRewardTimestamp = rewardInfo[i].endTimestamp;
            } else {
                pool.lastRewardTimestamp = block.timestamp;
            }

            uint256 tokenReward = (timeElapsed * rewardInfo[i].rewardPerSec);

            pool.accTokenPerShare += ((tokenReward * ACC_TOKEN_PRECISION) / lpSupply);
        }

        poolInfo[pid] = pool;

        emit UpdatePool(pid, pool.lastRewardTimestamp, lpSupply, pool.accTokenPerShare);

        return pool;
    }

    /// @notice this will return end timestamp based on the current block timestamp.
    function currentEndTimestamp(uint256 _pid) external view returns (uint256) {
        return _endTimestampOf(_pid, block.timestamp);
    }

    /// @notice View function to see pending Reward on frontend.
    function pendingTokens(uint256 _pid, address _user) external view override returns (uint256) {
        return _pendingTokens(_pid, userInfo[_pid][_user].amount, userInfo[_pid][_user].rewardDebt);
    }

    /// @notice View function to see pool rewards per sec
    function poolRewardsPerSec(uint256 _pid) external view override returns (uint256) {
        return _rewardPerSecOf(_pid, block.timestamp);
    }

    /// @notice Return reward multiplier over the given _from to _to timestamp.
    function getTimeElapsed(uint256 _from, uint256 _to, uint256 _endTimestamp) public pure returns (uint256) {
        if ((_from >= _endTimestamp) || (_from > _to)) {
            return 0;
        }
        if (_to <= _endTimestamp) {
            return _to - _from;
        }
        return _endTimestamp - _from;
    }

    function _endTimestampOf(uint256 _pid, uint256 _timestamp) internal view returns (uint256) {
        RewardInfo[] memory rewardInfo = poolRewardInfo[_pid];
        uint256 len = rewardInfo.length;
        if (len == 0) {
            return 0;
        }
        for (uint256 i = 0; i < len; ++i) {
            if (_timestamp <= rewardInfo[i].endTimestamp) return rewardInfo[i].endTimestamp;
        }

        /// @dev when couldn't find any reward info, it means that _timestamp exceed endTimestamp
        /// so return the latest reward info.
        return rewardInfo[len - 1].endTimestamp;
    }

    function _pendingTokens(
        uint256 _pid,
        uint256 _amount,
        uint256 _rewardDebt
    ) internal view returns (uint256 pending) {
        PoolInfo memory pool = poolInfo[_pid];
        RewardInfo[] memory rewardInfo = poolRewardInfo[_pid];

        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = distributor.poolTotalLp(_pid);

        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 cursor = pool.lastRewardTimestamp;

            for (uint256 i = 0; i < rewardInfo.length; ++i) {
                uint256 timeElapsed = getTimeElapsed(cursor, block.timestamp, rewardInfo[i].endTimestamp);
                if (timeElapsed == 0) continue;
                cursor = rewardInfo[i].endTimestamp;

                uint256 tokenReward = (timeElapsed * rewardInfo[i].rewardPerSec);

                accTokenPerShare += (tokenReward * ACC_TOKEN_PRECISION) / lpSupply;
            }
        }

        pending = (((_amount * accTokenPerShare) / ACC_TOKEN_PRECISION) - _rewardDebt);
    }

    function _rewardPerSecOf(uint256 _pid, uint256 _blockTimestamp) internal view returns (uint256) {
        RewardInfo[] memory rewardInfo = poolRewardInfo[_pid];
        PoolInfo storage pool = poolInfo[_pid];
        uint256 len = rewardInfo.length;
        if (len == 0) {
            return 0;
        }
        if (pool.startTimestamp > _blockTimestamp) {
            return 0;
        }
        for (uint256 i = 0; i < len; ++i) {
            if (_blockTimestamp <= rewardInfo[i].endTimestamp) return rewardInfo[i].rewardPerSec;
        }
        /// @dev when couldn't find any reward info, it means that timestamp exceed endblock
        /// so return 0
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IBoringERC20 {
    function mint(address to, uint256 amount) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IBoringERC20.sol";

interface IComplexRewarder {
    function onVelaReward(uint256 pid, address user, uint256 newLpAmount) external;

    function pendingTokens(uint256 pid, address user) external view returns (uint256 pending);

    function rewardToken() external view returns (IBoringERC20);

    function poolRewardsPerSec(uint256 pid) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IFarmDistributor {
    function deposit(uint256 _pid, uint256 _amount) external;

    function poolLength() external view returns (uint256);

    function poolTotalLp(uint256 pid) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/IBoringERC20.sol";

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IBoringERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IBoringERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IBoringERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(IBoringERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(IBoringERC20 token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}