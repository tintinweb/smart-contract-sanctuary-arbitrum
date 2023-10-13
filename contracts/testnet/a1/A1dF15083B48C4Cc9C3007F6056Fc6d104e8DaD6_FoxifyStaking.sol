// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FoxifyStaking {
    using SafeERC20 for IERC20;

    enum PoolType {
        CLASSIC,
        VESTING,
        LOCKUP
    }

    struct PoolInfo {
        IERC20 token;
        uint256 totalAmount;
        uint256 allocPoint;
        uint256 lastRewardTime;
        bool isStarted;
        bool depositClosed;
        PoolType poolType;
        uint256 period;
    }

    uint256 public constant DIVIDER = 1e18;

    IERC20[] private _rewardToken;

    uint256 public totalAllocPoint;
    address public operator;
    uint256 public poolStartTime;
    uint256 public poolEndTime;
    uint256 public nextDistributionTime;
    uint256 public distributionInterval;
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => uint256)) public accRewardSharePerShare;
    mapping(address => uint256) public totalPendingShare;
    mapping(address => uint256) public sharesPerSecond;
    mapping(uint256 => mapping(address => uint256)) public userInfoAmount;
    mapping(uint256 => mapping(address => uint256)) public userInfoVestedAmount;
    mapping(uint256 => mapping(address => mapping(address => uint256))) public userInfoRewardDebt;

    function poolsCount() external view returns (uint256) {
        return poolInfo.length;
    }

    function rewardTokenCount() external view returns (uint256) {
        return _rewardToken.length;
    }

    function rewardToken(uint256 index) external view returns (IERC20) {
        return _rewardToken[index];
    }

    function availableToWithdraw(uint256 _pid, address _user) public view returns (uint256 availableAmount) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 userAmount = userInfoAmount[_pid][_user];
        if (pool.poolType == PoolType.LOCKUP) {
            if (block.timestamp >= poolStartTime + pool.period) availableAmount = userAmount;
        } else if (pool.poolType == PoolType.VESTING) {
            uint256 vestedAmount = userInfoVestedAmount[_pid][_user];
            if (block.timestamp <= poolStartTime) availableAmount = 0;
            else {
                uint256 periodAmount = (vestedAmount * (block.timestamp - poolStartTime)) / pool.period;
                if (periodAmount > vestedAmount) periodAmount = vestedAmount;
                availableAmount = periodAmount - (vestedAmount - userAmount);
            }
        } else availableAmount = userAmount;
    }

    function pendingShare(address _token, uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 accRewardSharePerShare_ = accRewardSharePerShare[_pid][_token];
        if (block.timestamp > pool.lastRewardTime && pool.totalAmount != 0) {
            uint256 _generatedReward = getGeneratedReward(_token, pool.lastRewardTime, block.timestamp);
            uint256 _reward = (_generatedReward * pool.allocPoint) / totalAllocPoint;
            accRewardSharePerShare_ += ((_reward * DIVIDER) / pool.totalAmount);
        }
        return
            ((userInfoAmount[_pid][_user] * accRewardSharePerShare_) / DIVIDER) -
            userInfoRewardDebt[_pid][_user][_token];
    }

    function getGeneratedReward(address _token, uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return (poolEndTime - poolStartTime) * sharesPerSecond[_token];
            return (poolEndTime - _fromTime) * sharesPerSecond[_token];
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return (_toTime - poolStartTime) * sharesPerSecond[_token];
            return (_toTime - _fromTime) * sharesPerSecond[_token];
        }
    }

    event Deposit(address indexed caller, address indexed recipient, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, IERC20 token, uint256 amount);
    event DepositedFunds(address indexed caller, IERC20 token, uint256 amount, uint256 newSharesPerSecond);

    error CallerNotOperator();
    error RewardTokenZero();
    error StartTimeLTECurrent();
    error EndTimeLTEStart();
    error GovernanceRecoverUnsupportedInvalidToken(IERC20 token);
    error SetOperatorOperatorZero();
    error SetPoolEndTimeInvalidTime(uint256 end);
    error WithdrawAmountOverflow(uint256 amount, uint256 userBalance);
    error AddInvalidPool(PoolType poolType, uint256 period);
    error DepositClosed(uint256 pid);
    error EmergencyWithdrawInvalidPoolType(PoolType poolType);
    error UpdateDistributionParamsLengthError(uint256 length, uint256 target);
    error UpdateDistributionAmountZero(uint256[] amounts);
    error UpdateDistributionIntervalZero();
    error IncorrectPoolEndTime(uint256 end, uint256 current, uint256 start);

    constructor(address[] memory _rewards, uint256 _poolStartTime, uint256 _poolEndTime, uint256 _interval) {
        for (uint256 i = 0; i < _rewards.length; i++) {
            if (_rewards[i] == address(0)) revert RewardTokenZero();
            _rewardToken.push(IERC20(_rewards[i]));
        }
        if (_poolStartTime <= block.timestamp) revert StartTimeLTECurrent();
        if (_poolEndTime <= _poolStartTime) revert EndTimeLTEStart();
        poolStartTime = _poolStartTime;
        poolEndTime = _poolEndTime;
        operator = msg.sender;
        nextDistributionTime = _poolStartTime;
        _updateDistributionInterval(_interval);
    }

    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate,
        uint256 _lastRewardTime,
        bool depositClosed_,
        PoolType _poolType,
        uint256 _period
    ) external onlyOperator {
        if (_withUpdate) massUpdatePools();
        if (block.timestamp < poolStartTime) {
            if (_lastRewardTime == 0) _lastRewardTime = poolStartTime;
            else if (_lastRewardTime < poolStartTime) _lastRewardTime = poolStartTime;
        } else {
            if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) _lastRewardTime = block.timestamp;
        }
        if ((_poolType == PoolType.VESTING || _poolType == PoolType.LOCKUP) && _period == 0)
            revert AddInvalidPool(_poolType, _period);
        bool _isStarted = (_lastRewardTime <= poolStartTime) || (_lastRewardTime <= block.timestamp);
        poolInfo.push(
            PoolInfo({
                token: _token,
                totalAmount: 0,
                allocPoint: _allocPoint,
                lastRewardTime: _lastRewardTime,
                isStarted: _isStarted,
                depositClosed: depositClosed_,
                poolType: _poolType,
                period: _period
            })
        );
        if (_isStarted) totalAllocPoint += _allocPoint;
    }

    function deposit(uint256 _pid, uint256 _amount, address _recipient) external {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.depositClosed && msg.sender != operator) revert DepositClosed(_pid);
        updatePool(_pid);
        uint256 userAmount = userInfoAmount[_pid][_recipient];
        if (userAmount > 0) {
            for (uint256 i = 0; i < _rewardToken.length; i++) {
                IERC20 token = _rewardToken[i];
                address tokenAddress = address(token);
                uint256 _pending = ((userAmount * accRewardSharePerShare[_pid][tokenAddress]) / DIVIDER) -
                    userInfoRewardDebt[_pid][_recipient][tokenAddress];
                if (_pending > 0) {
                    totalPendingShare[tokenAddress] -= _pending;
                    token.safeTransfer(_recipient, _pending);
                    emit RewardPaid(_recipient, token, _pending);
                }
            }
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(msg.sender, address(this), _amount);
            pool.totalAmount += _amount;
            userInfoAmount[_pid][_recipient] += _amount;
            if (pool.poolType == PoolType.VESTING) userInfoVestedAmount[_pid][_recipient] += _amount;
        }
        for (uint256 i = 0; i < _rewardToken.length; i++) {
            address tokenAddress = address(_rewardToken[i]);
            userInfoRewardDebt[_pid][_recipient][tokenAddress] =
                (userInfoAmount[_pid][_recipient] * accRewardSharePerShare[_pid][tokenAddress]) /
                DIVIDER;
        }
        emit Deposit(msg.sender, _recipient, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) external {
        if (poolInfo[_pid].poolType != PoolType.CLASSIC)
            revert EmergencyWithdrawInvalidPoolType(poolInfo[_pid].poolType);
        uint256 _amount = userInfoAmount[_pid][msg.sender];
        userInfoAmount[_pid][msg.sender] = 0;
        for (uint256 i = 0; i < _rewardToken.length; i++)
            userInfoRewardDebt[_pid][msg.sender][address(_rewardToken[i])] = 0;
        poolInfo[_pid].token.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    function governanceRecover(IERC20 _token, uint256 amount, address to) external onlyOperator returns (bool) {
        massUpdatePools();
        _token.safeTransfer(to, amount);
        return true;
    }

    function set(uint256 _pid, uint256 _allocPoint) external onlyOperator {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) totalAllocPoint = totalAllocPoint - pool.allocPoint + _allocPoint;
        pool.allocPoint = _allocPoint;
    }

    function switchDepositStatus(uint256 _pid) external onlyOperator {
        poolInfo[_pid].depositClosed = !poolInfo[_pid].depositClosed;
    }

    function setOperator(address _operator) external onlyOperator {
        if (_operator == address(0)) revert SetOperatorOperatorZero();
        operator = _operator;
    }

    function updateDistributionInterval(uint256 interval) external onlyOperator returns (bool) {
        return _updateDistributionInterval(interval);
    }

    function _updateDistributionInterval(uint256 interval) private returns (bool) {
        if (interval == 0) revert UpdateDistributionIntervalZero();
        distributionInterval = interval;
        return true;
    }

    function updateDistribution(uint256[] memory amounts) external onlyOperator {
        massUpdatePools();
        if (amounts.length != _rewardToken.length)
            revert UpdateDistributionParamsLengthError(amounts.length, _rewardToken.length);
        uint256 distributionTime;
        for (uint256 i = 0; i < _rewardToken.length; i++) {
            IERC20 token = _rewardToken[i];
            address tokenAddress = address(token);
            if (amounts[i] == 0) revert UpdateDistributionAmountZero(amounts);
            token.safeTransferFrom(msg.sender, address(this), amounts[i]);
            uint256 previousSharesPerSecond = sharesPerSecond[tokenAddress];
            uint256 timeDiff;
            uint256 amountDiff;
            uint256 amountToDistribute;
            uint256 newSharesPerSecond;
            if (block.timestamp >= nextDistributionTime) {
                timeDiff = block.timestamp - nextDistributionTime;
                amountDiff = timeDiff * previousSharesPerSecond;
                amountToDistribute = amounts[i] - amountDiff;
                distributionTime =
                    ((block.timestamp + distributionInterval) / distributionInterval) *
                    distributionInterval;
                newSharesPerSecond = amountToDistribute / (distributionTime - block.timestamp);
            } else {
                timeDiff = nextDistributionTime - block.timestamp;
                amountDiff = timeDiff * previousSharesPerSecond;
                amountToDistribute = amounts[i] + amountDiff;
                distributionTime =
                    ((block.timestamp + (2 * distributionInterval)) / distributionInterval) *
                    distributionInterval;
                newSharesPerSecond = amountToDistribute / (distributionTime - block.timestamp);
            }
            sharesPerSecond[tokenAddress] = newSharesPerSecond;
            emit DepositedFunds(msg.sender, token, amounts[i], newSharesPerSecond);
        }
        nextDistributionTime = distributionTime;
    }

    function setSharesPerSecond(address token, uint256 perSecond) external onlyOperator {
        sharesPerSecond[token] = perSecond;
    }

    function setPoolEndTime(uint256 _poolEndTime) external onlyOperator {
        if (_poolEndTime < block.timestamp || _poolEndTime < poolStartTime)
            revert IncorrectPoolEndTime(_poolEndTime, block.timestamp, poolStartTime);
        poolEndTime = _poolEndTime;
    }

    function withdraw(uint256 _pid, uint256 _amount) external {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        uint256 userAmount = userInfoAmount[_pid][_sender];
        if (availableToWithdraw(_pid, _sender) < _amount)
            revert WithdrawAmountOverflow(_amount, availableToWithdraw(_pid, _sender));
        updatePool(_pid);
        for (uint256 i = 0; i < _rewardToken.length; i++) {
            IERC20 token = _rewardToken[i];
            address tokenAddress = address(token);
            uint256 _pending = ((userAmount * accRewardSharePerShare[_pid][tokenAddress]) / DIVIDER) -
                userInfoRewardDebt[_pid][_sender][tokenAddress];
            if (_pending > 0) {
                totalPendingShare[tokenAddress] -= _pending;
                token.safeTransfer(_sender, _pending);
                emit RewardPaid(_sender, token, _pending);
            }
        }
        if (_amount > 0) {
            userInfoAmount[_pid][_sender] -= _amount;
            pool.token.safeTransfer(_sender, _amount);
        }
        for (uint256 i = 0; i < _rewardToken.length; i++) {
            address tokenAddress = address(_rewardToken[i]);
            userInfoRewardDebt[_pid][_sender][tokenAddress] =
                (userInfoAmount[_pid][_sender] * accRewardSharePerShare[_pid][tokenAddress]) /
                DIVIDER;
        }
        emit Withdraw(_sender, _pid, _amount);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) updatePool(pid);
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) return;
        if (pool.totalAmount == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint + pool.allocPoint;
        }
        if (totalAllocPoint > 0) {
            for (uint256 i = 0; i < _rewardToken.length; i++) {
                address token = address(_rewardToken[i]);
                uint256 _generatedReward = getGeneratedReward(token, pool.lastRewardTime, block.timestamp);
                uint256 _reward = (_generatedReward * pool.allocPoint) / totalAllocPoint;
                totalPendingShare[token] += _reward;
                accRewardSharePerShare[_pid][token] += ((_reward * DIVIDER) / pool.totalAmount);
            }
        }
        pool.lastRewardTime = block.timestamp;
    }

    modifier onlyOperator() {
        if (operator != msg.sender) revert CallerNotOperator();
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

// EIP-2612 is Final as of 2022-11-01. This file is deprecated.

import "./IERC20Permit.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

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