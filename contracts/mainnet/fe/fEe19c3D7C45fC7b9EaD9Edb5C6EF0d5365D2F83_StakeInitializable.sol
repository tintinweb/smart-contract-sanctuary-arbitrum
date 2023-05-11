//SPDX-License-Identifier: BUSL -1.1
//SPDX-FileCopyrightText: Copyright 2021-22 Spherium Finance Ltd

pragma solidity ^0.8.7;

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
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

/*
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

// File: @openzeppelin/contracts/access/Ownable.sol

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

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
     * by making the `nonReentrant` function external, and make it call a
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

// File: @openzeppelin/contracts/utils/Address.sol

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File: "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract StakeInitializable is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Info of each staking pool.
    struct PoolInfo {
        // How man allocation points are assigned to this pool
        uint256 allocPoint;
        // Last time number when reward token's distribution occured.
        uint256 lastRewardTime;
        // Accrued reward token per staked token.
        uint256 accERC20PerShare;
        // Fixed APY, if staking program is providing fixed APY.
        uint256 fixedAPY;
        // Penalty amount for early withdrawal.
        uint256 penalty;
        // Total amount of staked tokens deposited in this pool.
        uint256 totalDeposits;
    }

    // Info of each participating user.
    struct UserInfo {
        // Number of staked tokens deposited.
        uint256 amount;
        // numebr of reward tokens user is not entitled to receive.
        uint256 rewardDebt;
        // Time when users last deposited staked tokens.
        uint256 depositTime;
        // Before this time, any withdrawal will result in penalty.
        uint256 withdrawTime;
    }

    // Address of the stake factory.
    address public STAKE_FACTORY;
    // Whether this staking program is initialized.
    bool public _isInitialized;
    // Whether this staking program has time-bound locking.
    bool public _isTimeBoundLock = true;
    // Whether this staking program charges penalty on early withdrawal.
    bool public _isPenaltyCharged = true;
    // Whether this staking program has fixed APY.
    bool public _isFixedAPY;
    // Wheter this staking program allows early withdrawal on stakes.
    bool public _isEarlyWithdrawAllowed = true;
    // The staked token.
    IERC20 public _stakedToken;
    // The reward token.
    IERC20 public _rewardToken;
    // Reward tokens created per second.
    uint256 public _rewardPerSecond;
    // Time when the staking program starts generating rewards.
    uint256 public _startTime;
    // Time when the staking program ends.
    uint256 public _endTime;
    // Staking time period in days.
    uint256[] private _timePeriods;
    // Penalty percentages for early withdrawal.
    uint256[] private _penalties;
    // Fixed APY percentages, in case the staking program is providing Fixed APY.
    uint256[] private _fixedAPYs;

    // Sum of allocation points of every staking pool.
    uint256 public _totalAllocPoints;
    // Total reward tokens paid out in rewards.
    uint256 public _paidOut;
    // Total reward tokens added to the program as liquidity.
    uint256 public _totalFundedRewards;
    // Total current rewards.
    //uint256 public _totalCurrentRewards; //@umang: unused
    // Stake Fee Percent.
    uint256 public _stakeFeePercent;
    // Total fee collected in staked tokens.
    uint256 public _totalFeeCollected;
    // Fee collector address.
    address public _feeCollector;
    // The precision factor.
    uint256 public PRECISION_FACTOR;
    // Penalty and Staking Fee denomiator.
    uint256 public FEE_DENOMINATOR = 100;
    // Info of each 'PoolInfo' mapped with their time periods (in days).
    mapping(uint256 => PoolInfo) public _poolInfo;
    // Info of each 'UserInfo' mapped with their wallet address for a given staking pool.
    mapping(address => mapping(uint256 => UserInfo)) public _userInfo;

    event StakingProgramInitialized(
        IERC20 indexed stakedToken,
        IERC20 indexed rewardToken,
        uint256 rewardPerSecond,
        uint256 startTime,
        uint256 endTime,
        uint256[] timePeriods,
        uint256[] penalties,
        uint256[] fixedAPYs,
        address admin,
        bool isTimeBoundLock,
        bool isPenaltyCharged,
        bool isFixedAPY
    );
    event Deposit(
        address indexed user,
        uint256 indexed period,
        uint256 indexed amount
    );
    event Withdraw(
        address indexed user,
        uint256 indexed period,
        uint256 indexed withdrawalAmount,
        uint256 rewardAmount
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed period,
        uint256 indexed withdrawalAmount
    );
    event StakeFeePercentSet(uint256 indexed stakeFeePercent);
    event IsEarlyWithdrawAllowedSet(bool indexed isEarlyWithdrawAllowed);
    event FeeCollectorSet(address indexed feeCollector);
    event WithdrawFees(uint256 indexed totalFeeCollected);
    event FundLiquidity(uint256 indexed fundAmount);
    event WithdrawLiquidity(uint256 indexed withdrawAmount);

    // Check if the entered 'period_' exists / is valid
    modifier ValidatePeriod(uint256 period_) {
        if (_isTimeBoundLock) {
            require(
                _searchArray(_timePeriods, period_),
                "Invalid staking period."
            );
        } else {
            require(
                period_ == 0,
                "Invalid staking period, enter zero beacuse there is no time-bound locking"
            );
        }
        _;
    }

    /**
     * @notice Constructor
     */
    constructor() {
        STAKE_FACTORY = msg.sender;
    }

    /**
     * @notice Initialize the staking program
     *
     */
    function initializeContract(
        IERC20 stakedToken_,
        IERC20 rewardToken_,
        uint256 rewardPerSecond_,
        uint256 startTime_,
        uint256 endTime_,
        uint256[] memory timePeriods_,
        uint256[] memory penalties_,
        uint256[] memory fixedAPYs_,
        address admin_
    ) external {
        require(!_isInitialized, "Program already initialized.");
        require(
            msg.sender == STAKE_FACTORY,
            "Program can be initialized only by the factory."
        );
        require(
            stakedToken_ != IERC20(address(0)) &&
                rewardToken_ != IERC20(address(0)),
            "Staked token and reward token cannot be zero address"
        );
        require(
            startTime_ >= block.timestamp,
            "Start time cannot be less than the current time"
        );
        require(
            endTime_ > startTime_,
            "Staking program end time cannot be less than start time"
        );
        require(
            timePeriods_.length == penalties_.length,
            "Time period and penalty lengths must be equal"
        );
        require(admin_ != address(0), "Admin cannot be zero address.");

        // If this staking program has only one time-bound locking pool, eg. 30 Day time-period.
        if (timePeriods_.length == 1) {
            require(
                timePeriods_[0] != 0,
                "Time Period cannot be zero day. Enter an empty array to avoid time-boud locking."
            );
        }

        // If this staking program provides fixed APYs.
        if (fixedAPYs_.length > 0) {
            if (timePeriods_.length > 0) {
                // This means that the staking program has time-bound locking.
                // For every time-period, their must be a fixed APY value.
                require(
                    fixedAPYs_.length == timePeriods_.length,
                    "Every time period must have its respective fixed APY."
                );
            }
            _isFixedAPY = true;
            _fixedAPYs = fixedAPYs_;
        }

        // If this staking program does not have time-bound locking.
        if (timePeriods_.length == 0) {
            _isTimeBoundLock = false;
            _isPenaltyCharged = false;
        }

        uint256 decimalsOfRewardToken = uint256(
            IERC20Metadata(address(rewardToken_)).decimals()
        );
        require(decimalsOfRewardToken < 30, "Must be less than 30");

        // Make this staking program initialized.
        _isInitialized = true;

        _stakedToken = stakedToken_;
        _rewardToken = rewardToken_;
        _rewardPerSecond = rewardPerSecond_;
        _startTime = startTime_;
        _endTime = endTime_;
        _timePeriods = timePeriods_;
        _penalties = penalties_;
        PRECISION_FACTOR = uint256(10 ** (uint256(30) - decimalsOfRewardToken));

        // Create either time-bound locking pools or a single zero-day-lock staking pool.
        if (_isTimeBoundLock) {
            uint256 totalPools = _timePeriods.length;
            if (_isFixedAPY) {
                _totalAllocPoints = 1;
            } else {
                _totalAllocPoints = (totalPools * (totalPools + 1)) / 2; // n(n+1)/2 => Sum of an A.P. with a = d = 1
            }

            for (uint256 i = 0; i < totalPools; i++) {
                _poolInfo[_timePeriods[i]] = PoolInfo({
                    allocPoint: uint256(_isFixedAPY ? 1 : (i + 1)),
                    lastRewardTime: _startTime,
                    accERC20PerShare: 0,
                    fixedAPY: uint256(_isFixedAPY ? _fixedAPYs[i] : 0),
                    penalty: _penalties[i],
                    totalDeposits: 0
                });
            }
        } else {
            _totalAllocPoints = 1;
            _poolInfo[0] = PoolInfo({
                allocPoint: 1,
                lastRewardTime: _startTime,
                accERC20PerShare: 0,
                fixedAPY: uint256(_isFixedAPY ? _fixedAPYs[0] : 0),
                penalty: 0,
                totalDeposits: 0
            });
        }

        // Transfer ownership to the admin address who then becomes the new owner of the contract.
        transferOwnership(admin_);

        emit StakingProgramInitialized(
            _stakedToken,
            _rewardToken,
            _rewardPerSecond,
            _startTime,
            _endTime,
            _timePeriods,
            _penalties,
            _fixedAPYs,
            admin_,
            _isTimeBoundLock,
            _isPenaltyCharged,
            _isFixedAPY
        );
    }

    // Staking functions

    /**
     * @notice function stakes token in a given staking pool
     * @param amount_: amount to deposit (in staked tokens)
     * @param period_: time period in which the user wish to stake
     */
    function deposit(
        address sender_,
        uint256 amount_,
        uint256 period_
    ) external nonReentrant ValidatePeriod(period_) {
        require(amount_ > 0, "Deposit amount must be greater than zero.");
        require(sender_ != address(0), "cant deposit for zero");
        // Calculate true deposit amount
        uint256 beforeBalance = _stakedToken.balanceOf(address(this));
        _stakedToken.safeTransferFrom(msg.sender, address(this), amount_);
        uint256 afterBalance = _stakedToken.balanceOf(address(this));

        uint256 stakedAmount;
        if (afterBalance - beforeBalance <= amount_) {
            stakedAmount = afterBalance - beforeBalance;
        } else {
            stakedAmount = amount_;
        }

        // Take staking fee
        if (_stakeFeePercent > 0) {
            uint256 feeAmount = (stakedAmount * _stakeFeePercent) /
                FEE_DENOMINATOR;
            stakedAmount = stakedAmount - feeAmount;
            _totalFeeCollected = _totalFeeCollected + feeAmount;
        }

        PoolInfo storage pool = _poolInfo[period_];
        UserInfo storage user = _userInfo[sender_][period_];

        if (!_isFixedAPY) {
            _updatePool(period_);
            user.rewardDebt =
                (user.amount * pool.accERC20PerShare) /
                PRECISION_FACTOR;
        }
        user.amount = user.amount + amount_;
        user.depositTime = block.timestamp;
        user.withdrawTime = user.depositTime + (period_ * 24 * 60 * 60);
        pool.totalDeposits = pool.totalDeposits + user.amount;

        emit Deposit(sender_, period_, stakedAmount);
    }

    /**
     * @notice function withdraws deposited tokens and rewards, if any
     * @param amount_: amount of staked tokens to withdraw.
     * @param period_: time period from which user wish to withdraw.
     */
    function withdraw(
        uint256 amount_,
        uint256 period_
    ) external nonReentrant ValidatePeriod(period_) {
        PoolInfo storage pool = _poolInfo[period_];
        UserInfo storage user = _userInfo[msg.sender][period_];

        require(
            user.amount >= amount_,
            "Withdraw amount cannot be greater than deposited amount."
        );

        _updatePool(period_);

        uint256 pendingRewards;
        if (_isFixedAPY) {
            pendingRewards =
                user.amount *
                (pool.fixedAPY / 100) *
                (period_ / 360);
        } else {
            pendingRewards =
                ((user.amount * pool.accERC20PerShare) / PRECISION_FACTOR) -
                user.rewardDebt;
        }

        // Distribute rewards, if any
        if (pendingRewards > 0) {
            // Whether to charge penalty fee or not.
            if (_isPenaltyCharged && user.withdrawTime > block.timestamp) {
                require(
                    _isEarlyWithdrawAllowed,
                    "Early withdrawal is not allowed."
                );
                pendingRewards =
                    pendingRewards -
                    ((pendingRewards * pool.penalty) / FEE_DENOMINATOR);
            }
        }

        uint256 _amount = amount_;
        if (_isPenaltyCharged && user.withdrawTime > block.timestamp) {
            require(
                _isEarlyWithdrawAllowed,
                "Early withdrawal is not allowed."
            );
            uint256 timeDifference = (user.withdrawTime - block.timestamp);
            uint256 totalTimeDifference = (user.withdrawTime -
                user.depositTime);
            uint256 _timePenalty = ((timeDifference / totalTimeDifference) *
                pool.penalty);
            uint256 timePenalty = ((amount_ * _timePenalty) / FEE_DENOMINATOR);
            _amount = amount_ - timePenalty;
        }
        user.amount = user.amount - amount_;
        user.rewardDebt =
            (user.amount * pool.accERC20PerShare) /
            PRECISION_FACTOR;
        pool.totalDeposits = pool.totalDeposits - amount_;
        _paidOut = _paidOut + pendingRewards;
        _stakedToken.safeTransfer(_msgSender(), _amount);
        _rewardToken.safeTransfer(_msgSender(), pendingRewards);

        emit Withdraw(_msgSender(), period_, _amount, pendingRewards);
    }

    /**
     * @notice function withdraws staked tokens without caring about rewards. EMERGENCY ONLY.
     * @param period_: time period from which user wish to withdraw.
     */
    function emergencyWithdraw(
        uint256 period_
    ) external nonReentrant ValidatePeriod(period_) {
        PoolInfo storage pool = _poolInfo[period_];
        UserInfo storage user = _userInfo[msg.sender][period_];

        if (user.withdrawTime > block.timestamp) {
            require(
                _isEarlyWithdrawAllowed,
                "Early withdrawal is not allowed."
            );
        }

        uint256 withdrawalAmount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.totalDeposits = pool.totalDeposits - withdrawalAmount;

        _stakedToken.safeTransfer(_msgSender(), withdrawalAmount);

        emit EmergencyWithdraw(_msgSender(), period_, withdrawalAmount);
    }

    // Admin functions

    /**
     * @notice function sets fee values right after the stakeing program is initialized.
     * @param stakeFeePercent_: new stake fee percent
     * @param feeCollector_: address of new fee collector
     */
    function initializeFee(
        uint256 stakeFeePercent_,
        address feeCollector_
    ) external onlyOwner {
        require(
            stakeFeePercent_ < 100,
            "Stake Fee Percent must be less than 100"
        );
        require(
            feeCollector_ != address(0),
            "Fee Collector cannot be zero address."
        );

        _stakeFeePercent = stakeFeePercent_;
        _feeCollector = feeCollector_;

        emit StakeFeePercentSet(_stakeFeePercent);
        emit FeeCollectorSet(_feeCollector);
    }

    /**
     * @notice function sets a new stake fee percent value
     * @param stakeFeePercent_: new stake fee percent
     */
    function setStakeFeePercent(uint256 stakeFeePercent_) external onlyOwner {
        _stakeFeePercent = stakeFeePercent_;
        emit StakeFeePercentSet(_stakeFeePercent);
    }

    /**
     * @notice function sets '_feeCollector' for a new address
     * @param feeCollector_: address of new fee collector
     */
    function setFeeCollector(address feeCollector_) external onlyOwner {
        _feeCollector = feeCollector_;
        emit FeeCollectorSet(_feeCollector);
    }

    /**
     * @notice function sets the new state for early withdraw
     * @param isEarlyWithdrawAllowed_: is early withdraw allowed or not
     */
    function setIsEarlyWithdrawAllowed(
        bool isEarlyWithdrawAllowed_
    ) external onlyOwner {
        _isEarlyWithdrawAllowed = isEarlyWithdrawAllowed_;
        emit IsEarlyWithdrawAllowedSet(_isEarlyWithdrawAllowed);
    }

    /**
     * @notice function withdraws collected fee in staked token to fee collector's wallet
     */
    function withdrawCollectedFees() external onlyOwner {
        uint256 totalFeeColleced = _totalFeeCollected;
        bool success = _stakedToken.transfer(_feeCollector, _totalFeeCollected);
        if (success) {
            _totalFeeCollected = 0;
        }

        emit WithdrawFees(totalFeeColleced);
    }

    /**
     * @notice function injects liquidity in reward tokens into the staking program
     * @param amount_: reward token amount
     */
    function injectLiquidity(
        uint256 amount_
    ) external onlyOwner returns (bool success) {
        uint256 nonFixedRewards = ((_endTime - _startTime) * _rewardPerSecond);
        uint256 totalFundedRewards = _totalFundedRewards;
        if (!_isFixedAPY) {
            require(amount_ >= nonFixedRewards, "rewards not enough");
        }
        _rewardToken.safeTransferFrom(msg.sender, address(this), amount_);

        _totalFundedRewards = totalFundedRewards + amount_;

        emit FundLiquidity(amount_);

        success = true;
    }

    /**
     * @notice function withdraws reward tokens after the program has ended.
     * @param amount_: number of reward tokens to withdraw
     */
    function withdrawLiquidity(uint256 amount_) external onlyOwner {
        uint256 totalFundedRewards = _totalFundedRewards;

        require(
            amount_ <= totalFundedRewards,
            "Cannot withdraw more than contract balance."
        );

        _totalFundedRewards = totalFundedRewards - amount_;
        _rewardToken.safeTransfer(msg.sender, amount_);

        emit WithdrawLiquidity(amount_);
    }

    /**
     * @notice function withdraws ERC20 tokens, if stuck.
     * @param token_: token address to withdraw.
     * @param amount_: amount to tokens to withdraw.
     * @param beneficiary_: address of user that receives the tokens.
     */
    function withdrawTokensIfStuck(
        address token_,
        uint256 amount_,
        address beneficiary_
    ) external onlyOwner {
        IERC20 token = IERC20(token_);

        require(
            token != _stakedToken,
            "Users' staked tokens cannot be withdrawn."
        );
        require(
            beneficiary_ != address(0),
            "Beneficiary cannot be zero address."
        );

        token.safeTransfer(beneficiary_, amount_);
    }

    // View Functions

    /**
     * @notice function is getting number of staked tokens deposited by a user.
     * @param user_: address of user.
     * @param period_: staking period.
     * @return deposited amount of staked tokens for a user.
     */
    function getUserDepositedAmount(
        address user_,
        uint256 period_
    ) external view ValidatePeriod(period_) returns (uint256) {
        UserInfo memory user = _userInfo[user_][period_];
        return user.amount;
    }

    /**
     * @notice function is getting epoch time to see deposit and withdraw time for a user.
     * @param user_: address of user.
     * @param period_: staking period.
     * @return time when user deposited and is expected to withdraw.
     */
    function getUserDepositWithdrawTime(
        address user_,
        uint256 period_
    ) public view ValidatePeriod(period_) returns (uint256, uint256) {
        UserInfo memory user = _userInfo[user_][period_];
        return (user.depositTime, user.withdrawTime);
    }

    /**
     * @notice function is getting number of reward tokens pending for a user.
     * @dev pending rewards = (user.amount * pool.accERC20PerShare) - user.rewardDebt.
     * @param user_: address of user.
     * @param period_: staking period.
     * @return pendingRewards : pending reward tokens for a user.
     */
    function getUserPendingRewards(
        address user_,
        uint256 period_
    ) public view ValidatePeriod(period_) returns (uint256 pendingRewards) {
        PoolInfo memory pool = _poolInfo[period_];
        UserInfo memory user = _userInfo[user_][period_];

        if (user.amount == 0) {
            return 0;
        }

        if (_isFixedAPY) {
            if (block.timestamp < _endTime) {
                pendingRewards =
                    user.amount *
                    (pool.fixedAPY / 360) *
                    (block.timestamp - user.depositTime);
            } else {
                pendingRewards =
                    user.amount *
                    (pool.fixedAPY / 360) *
                    (block.timestamp - _endTime);
            }
        } else {
            uint256 accERC20PerShare = pool.accERC20PerShare;
            uint256 totalDeposits = pool.totalDeposits;
            uint256 lastRewardTime = pool.lastRewardTime;

            if (block.timestamp > lastRewardTime && totalDeposits != 0) {
                uint256 lastTime = block.timestamp < _endTime
                    ? block.timestamp
                    : _endTime;
                uint256 timeToCompare = lastRewardTime < _endTime
                    ? lastRewardTime
                    : _endTime;
                uint256 noOfSeconds = lastTime - timeToCompare;
                uint256 rewardTokenToDistribute = (noOfSeconds *
                    _rewardPerSecond *
                    pool.allocPoint) / _totalAllocPoints;
                accERC20PerShare =
                    accERC20PerShare +
                    ((rewardTokenToDistribute * PRECISION_FACTOR) /
                        totalDeposits);
                pendingRewards =
                    ((user.amount * accERC20PerShare) / PRECISION_FACTOR) -
                    user.rewardDebt;
            }
        }
    }

    /**
     * @notice function is getting a user's total pending rewards in all the time periods.
     * @param user_: address of user.
     * @return array of pending rewards of a user for all the time periods.
     */
    function getUserTotalPendingRewards(
        address user_
    ) external view returns (uint256[] memory) {
        uint256[] memory pendingRewards = new uint256[](_timePeriods.length);

        for (uint256 i = 0; i < _timePeriods.length; i++) {
            PoolInfo memory pool = _poolInfo[_timePeriods[i]];
            UserInfo memory user = _userInfo[user_][_timePeriods[i]];

            if (_isFixedAPY) {
                if (user.amount == 0) {
                    pendingRewards[i] = 0;
                    continue;
                }
                uint256 noOfSeconds = block.timestamp < _endTime
                    ? (block.timestamp - user.depositTime)
                    : (_endTime - user.depositTime);
                pendingRewards[i] =
                    user.amount *
                    (pool.fixedAPY / 100) *
                    (noOfSeconds / (360 * 24 * 60 * 60));
            } else {
                pendingRewards[i] = getUserPendingRewards(
                    user_,
                    _timePeriods[i]
                );
            }
        }

        return pendingRewards;
    }

    /**
     * @notice function is getting number of total reward tokens the program has yet to pay out.
     * @return number of reward tokens the program has yet to pay out.
     */
    function getTotalPendingRewards() public view returns (uint256) {
        if (block.timestamp <= _startTime) {
            return 0;
        }

        if (_isFixedAPY) {
            uint256 totalPendingRewards;
            for (uint256 i = 0; i < _timePeriods.length; i++) {
                PoolInfo memory pool = _poolInfo[_timePeriods[i]];
                totalPendingRewards =
                    totalPendingRewards +
                    (pool.totalDeposits *
                        (pool.fixedAPY / 100) *
                        (_timePeriods[i] / 360));
            }
            return totalPendingRewards;
        } else {
            uint256 lastTime = block.timestamp < _endTime
                ? block.timestamp
                : _endTime;
            return ((_rewardPerSecond * (lastTime - _startTime)) - _paidOut);
        }
    }

    // Internal Functions

    /**
     * @notice function updates reward variables of a given pool.
     * @dev This function is used only when the contract provides variable APY.
     * @param period_: time period of the pool to update.
     */
    function _updatePool(uint256 period_) internal {
        PoolInfo storage pool = _poolInfo[period_];

        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }

        uint256 stakedTokenSupply = pool.totalDeposits;
        if (stakedTokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }

        uint256 noOfSeconds = _getNoOfSeconds(
            pool.lastRewardTime,
            block.timestamp
        );
        uint256 rewardTokenToDistribute = (noOfSeconds *
            _rewardPerSecond *
            pool.allocPoint) / _totalAllocPoints;
        pool.accERC20PerShare =
            pool.accERC20PerShare +
            ((rewardTokenToDistribute * PRECISION_FACTOR) / stakedTokenSupply);
        pool.lastRewardTime = block.timestamp;
    }

    /**
     * @notice function returns number of seconds over the given time
     * @param from_: time to start
     * @param to_: time to finish
     */
    function _getNoOfSeconds(
        uint256 from_,
        uint256 to_
    ) internal view returns (uint256 noOfSeconds) {
        if (to_ <= _endTime) {
            noOfSeconds = to_ - from_;
        } else if (from_ >= _endTime) {
            noOfSeconds = 0;
        } else {
            noOfSeconds = _endTime - from_;
        }
    }

    /**
     * @dev function checks if a given array contains the passed value
     * @param array_: an array of unsigned integers
     * @param value_: value to search in the given array
     */
    function _searchArray(
        uint256[] memory array_,
        uint256 value_
    ) private pure returns (bool exists) {
        for (uint256 i = 0; i < array_.length; i++) {
            if (array_[i] == value_) {
                exists = true;
                break;
            }
        }
    }

    function getToTaldynamicRewards() external view returns (uint256) {
        return ((_endTime - _startTime) * _rewardPerSecond);
    }

    function getCurrentPenalty(
        address user_,
        uint256 period
    ) external view returns (uint256 _timePenalty) {
        PoolInfo storage pool = _poolInfo[period];
        UserInfo storage user = _userInfo[user_][period];
        uint256 timeDifference = (user.withdrawTime - block.timestamp);
        uint256 totalTimeDifference = (user.withdrawTime - user.depositTime);
        _timePenalty = ((timeDifference / totalTimeDifference) * pool.penalty);
    }

    function viewTimePeriods() external view returns (uint256[] memory) {
        return _timePeriods;
    }

    function viewPenalties() external view returns (uint256[] memory) {
        return _penalties;
    }

    function viewFixedAPYs() external view returns (uint256[] memory) {
        return _fixedAPYs;
    }
}

pragma solidity ^0.8.7;

error Reward__injection__error();

contract Factory is Ownable {
    // Array of all th staking programs.
    address[] private stakingPrograms;

    event NewStakingContract(address indexed stakingContract);

    constructor() {}

    /*
     * @notice Deploy the staking pool
     * @param stakedToken_: staked token address
     * @param rewardToken_: reward token address
     * @param rewardPerBlock_: reward per block (in reward token)
     * @param startBlock_: start block
     * @param bonusEndBlock_: end block
     * @param timePeriods_: staking intervals (in days)
     * @param penalties_: early withdrawal penalty for every staking interval
     * @param admin_:  admin address with ownership
     */
    function initializeStakingContract(
        IERC20 stakedToken_,
        IERC20 rewardToken_,
        uint256 rewardPerSecond_,
        uint256 startTime_,
        uint256 endTime_,
        uint256[] calldata timePeriods_, // Input in ascending order
        uint256[] calldata penalties_,
        uint256[] calldata fixedAPYs_,
        address admin_
    ) external onlyOwner {
        StakeInitializable stakeInitializableAddress = new StakeInitializable();

        StakeInitializable(stakeInitializableAddress).initializeContract(
            stakedToken_,
            rewardToken_,
            rewardPerSecond_,
            startTime_,
            endTime_,
            timePeriods_,
            penalties_,
            fixedAPYs_,
            admin_
        );
        stakingPrograms.push(address(stakeInitializableAddress));

        emit NewStakingContract(address(stakeInitializableAddress));
    }

    function viewStakingPrograms()
        external
        view
        returns (address[] memory _contracts)
    {
        _contracts = stakingPrograms;
    }

    function getAmountToApproveDynamicRewards(
        uint256 endTime_,
        uint256 startTime_,
        uint256 rewardsPerSecond_
    ) external pure returns (uint256 amountToApprove) {
        amountToApprove = ((endTime_ - startTime_) * rewardsPerSecond_);
    }
}