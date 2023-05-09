/**
 *Submitted for verification at Arbiscan on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Constants {
    address public constant ZERO_ADDRESS = address(0);
    uint8 public constant ORDER_FILLED = 1;
    uint8 public constant ORDER_NOT_FILLED = 0;
    uint8 public constant STAKING_PID_FOR_CHARGE_FEE = 1;
    uint256 public constant BASIS_POINTS_DIVISOR = 100000;
    uint256 public constant DEFAULT_FUNDING_RATE_FACTOR = 100;
    uint256 public constant DEFAULT_MAX_OPEN_INTEREST = 10000000000 * PRICE_PRECISION;
    uint256 public constant DEFAULT_ALP_PRICE = 100000;
    uint256 public constant FUNDING_RATE_PRECISION = 1000000;
    uint256 public constant LIQUIDATE_NONE_EXCEED = 0;
    uint256 public constant LIQUIDATE_FEE_EXCEED = 1;
    uint256 public constant LIQUIDATE_THRESHOLD_EXCEED = 2;
    uint256 public constant MAX_DEPOSIT_FEE = 10000; // 10%
    uint256 public constant MAX_DELTA_TIME = 24 hours;
    uint256 public constant MAX_COOLDOWN_DURATION = 48 hours;
    uint256 public constant MAX_FEE_BASIS_POINTS = 5000; // 5%
    uint256 public constant MAX_FEE_REWARD_BASIS_POINTS = BASIS_POINTS_DIVISOR; // 100%
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 10000; // 1%
    uint256 public constant MAX_FUNDING_RATE_INTERVAL = 48 hours;
    uint256 public constant MAX_LIQUIDATION_FEE_USD = 100 * PRICE_PRECISION; // 100 USD
    uint256 public constant MAX_STAKING_FEE = 10000; // 10%
    uint256 public constant MAX_TOKENFARM_COOLDOWN_DURATION = 4 weeks;
    uint256 public constant MAX_TRIGGER_GAS_FEE = 1e8 gwei;
    uint256 public constant MAX_VESTING_DURATION = 700 days;
    uint256 public constant MIN_FUNDING_RATE_INTERVAL = 1 hours;
    uint256 public constant MIN_LEVERAGE = 10000; // 1x
    uint256 public constant MIN_FEE_REWARD_BASIS_POINTS = 50000; // 50%
    uint256 public constant POSITION_MARKET = 0;
    uint256 public constant POSITION_LIMIT = 1;
    uint256 public constant POSITION_STOP_MARKET = 2;
    uint256 public constant POSITION_STOP_LIMIT = 3;
    uint256 public constant POSITION_TRAILING_STOP = 4;
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant TRAILING_STOP_TYPE_AMOUNT = 0;
    uint256 public constant TRAILING_STOP_TYPE_PERCENT = 1;
    uint256 public constant ALP_DECIMALS = 18;

    function _getPositionKey(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _indexToken, _isLong, _posId));
    }

    function checkSlippage(
        bool isLong,
        uint256 expectedMarketPrice,
        uint256 slippageBasisPoints,
        uint256 actualMarketPrice
    ) internal pure {
        if (isLong) {
            require(
                actualMarketPrice <=
                    (expectedMarketPrice * (BASIS_POINTS_DIVISOR + slippageBasisPoints)) / BASIS_POINTS_DIVISOR,
                "slippage exceeded"
            );
        } else {
            require(
                (expectedMarketPrice * (BASIS_POINTS_DIVISOR - slippageBasisPoints)) / BASIS_POINTS_DIVISOR <=
                    actualMarketPrice,
                "slippage exceeded"
            );
        }
    }
}


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


interface IMintable {
    function burn(address _account, uint256 _amount) external;

    function mint(address _account, uint256 _amount) external;

    function setMinter(address _minter, bool _isActive) external;

    function isMinter(address _account) external returns (bool);
}


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




/**
 * @dev Interface of the VeDxp
 */
interface ITokenFarm {
    function getTier(uint256 _pid, address _account) external view returns (uint256);
}



interface IComplexRewarder {
    function onAnkaaReward(uint256 pid, address user, uint256 newLpAmount) external;

    function pendingTokens(uint256 pid, address user) external view returns (uint256 pending);

    function rewardToken() external view returns (IBoringERC20);

    function poolRewardsPerSec(uint256 pid) external view returns (uint256);
}


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
}


contract TokenFarm is ITokenFarm, Constants, Ownable, ReentrancyGuard {
    using BoringERC20 for IBoringERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 startTimestamp;
    }

    // Info of each pool.
    struct PoolInfo {
        IBoringERC20 lpToken; // Address of LP token contract.
        uint256 totalLp; // Total token in Pool
        IComplexRewarder[] rewarders; // Array of rewarder contract for pools with incentives
        bool enableCooldown;
    }
    // Total locked up rewards
    uint256 public totalLockedUpRewards;
    // The precision factor
    uint256 private immutable ACC_TOKEN_PRECISION = 1e12;
    IBoringERC20 public immutable esToken;
    IBoringERC20 public immutable claimableToken;

    uint256 public cooldownDuration = 1 weeks;
    uint256 public totalLockedVestingAmount;
    uint256 public vestingDuration;
    uint256[] public tierLevels;
    uint256[] public tierPercents;
    // Info of each pool
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(address => uint256) public claimedAmounts;
    mapping(address => uint256) public unlockedVestingAmounts;
    mapping(address => uint256) public lastVestingUpdateTimes;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => uint256) public lockedVestingAmounts;

    modifier validatePoolByPid(uint256 _pid) {
        require(_pid < poolInfo.length, "Pool does not exist");
        _;
    }

    event Add(
        uint256 indexed pid,
        IBoringERC20 indexed lpToken,
        IComplexRewarder[] indexed rewarders,
        bool _enableCooldown
    );
    event FarmDeposit(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousValue, uint256 newValue);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event Set(uint256 indexed pid, IComplexRewarder[] indexed rewarders);
    event UpdateCooldownDuration(uint256 cooldownDuration);
    event UpdateVestingPeriod(uint256 vestingPeriod);
    event UpdateRewardTierInfo(uint256[] levels, uint256[] percents);
    event VestingClaim(address receiver, uint256 amount);
    event VestingDeposit(address account, uint256 amount);
    event VestingTransfer(address indexed from, address indexed to, uint256 value);
    event VestingWithdraw(address account, uint256 claimedAmount, uint256 balance);
    event FarmWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(uint256 _vestingDuration, IBoringERC20 _esToken, IBoringERC20 _claimableToken) {
        //StartBlock always many years later from contract const ruct, will be set later in StartFarming function
        claimableToken = _claimableToken;
        esToken = _esToken;
        vestingDuration = _vestingDuration;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // Can add multiple pool with same lp token without messing up rewards, because each pool's balance is tracked using its own totalLp
    function add(
        IBoringERC20 _lpToken,
        IComplexRewarder[] calldata _rewarders,
        bool _enableCooldown
    ) external onlyOwner {
        require(_rewarders.length <= 10, "add: too many rewarders");
        require(Address.isContract(address(_lpToken)), "add: LP token must be a valid contract");

        for (uint256 rewarderId = 0; rewarderId < _rewarders.length; ++rewarderId) {
            require(Address.isContract(address(_rewarders[rewarderId])), "add: rewarder must be contract");
        }

        poolInfo.push(
            PoolInfo({lpToken: _lpToken, totalLp: 0, rewarders: _rewarders, enableCooldown: _enableCooldown})
        );

        emit Add(poolInfo.length - 1, _lpToken, _rewarders, _enableCooldown);
    }

    // Function to harvest many pools in a single transaction
    function harvestMany(uint256[] calldata _pids) external nonReentrant {
        require(_pids.length <= 30, "harvest many: too many pool ids");
        for (uint256 index = 0; index < _pids.length; ++index) {
            _deposit(_pids[index], 0);
        }
    }

    // Deposit tokens for Ankaa allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        _deposit(_pid, _amount);
    }

    function depositVesting(uint256 _amount) external nonReentrant {
        _depositVesting(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        if (_amount > 0) {
            require(
                !pool.enableCooldown || user.startTimestamp + cooldownDuration <= block.timestamp,
                "didn't pass cooldownDuration"
            );
            pool.lpToken.safeTransfer(msg.sender, _amount);
            pool.totalLp -= _amount;
        }
        user.amount = 0;
        emit EmergencyWithdraw(msg.sender, _amount, _pid);
    }

    // Update the given pool's Ankaa allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, IComplexRewarder[] calldata _rewarders) external onlyOwner validatePoolByPid(_pid) {
        require(_rewarders.length <= 10, "set: too many rewarders");

        for (uint256 rewarderId = 0; rewarderId < _rewarders.length; ++rewarderId) {
            require(Address.isContract(address(_rewarders[rewarderId])), "set: rewarder must be contract");
        }

        poolInfo[_pid].rewarders = _rewarders;

        emit Set(_pid, _rewarders);
    }

    function updateCooldownDuration(uint256 _newCooldownDuration) external onlyOwner {
        require(_newCooldownDuration <= MAX_TOKENFARM_COOLDOWN_DURATION, "cooldown duration exceeds max");
        cooldownDuration = _newCooldownDuration;
        emit UpdateCooldownDuration(_newCooldownDuration);
    }

    function updateRewardTierInfo(uint256[] memory _levels, uint256[] memory _percents) external onlyOwner {
        uint256 totalLength = tierLevels.length;
        require(_levels.length == _percents.length, "the length should the same");
        require(_validateLevels(_levels), "levels not sorted");
        require(_validatePercents(_percents), "percents exceed 100%");
        for (uint256 i = 0; i < totalLength; i++) {
            tierLevels.pop();
            tierPercents.pop();
        }
        for (uint256 j = 0; j < _levels.length; j++) {
            tierLevels.push(_levels[j]);
            tierPercents.push(_percents[j]);
        }
        emit UpdateRewardTierInfo(_levels, _percents);
    }

    function updateVestingDuration(uint256 _vestingDuration) external onlyOwner {
        require(_vestingDuration <= MAX_VESTING_DURATION, "vesting duration exceeds max");
        vestingDuration = _vestingDuration;
        emit UpdateVestingPeriod(_vestingDuration);
    }

    //withdraw tokens
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        //this will make sure that user can only withdraw from his pool
        require(user.amount >= _amount, "withdraw: user amount not enough");

        if (_amount > 0) {
            require(
                !pool.enableCooldown || user.startTimestamp + cooldownDuration < block.timestamp,
                "didn't pass cooldownDuration"
            );
            user.amount -= _amount;
            pool.lpToken.safeTransfer(msg.sender, _amount);
        }

        for (uint256 rewarderId = 0; rewarderId < pool.rewarders.length; ++rewarderId) {
            pool.rewarders[rewarderId].onAnkaaReward(_pid, msg.sender, user.amount);
        }

        if (_amount > 0) {
            pool.totalLp -= _amount;
        }

        emit FarmWithdraw(msg.sender, _pid, _amount);
    }

    function withdrawVesting() external nonReentrant {
        address account = msg.sender;
        address _receiver = account;
        uint256 totalClaimed = _claim(account, _receiver);

        uint256 totalLocked = lockedVestingAmounts[account];
        require(totalLocked + totalClaimed > 0, "Vester: vested amount is zero");

        esToken.safeTransfer(_receiver, totalLocked);
        _decreaseLockedVestingAmount(account, totalLocked);

        delete unlockedVestingAmounts[account];
        delete claimedAmounts[account];
        delete lastVestingUpdateTimes[account];

        emit VestingWithdraw(account, totalClaimed, totalLocked);
    }

    function _claim(address _account, address _receiver) internal returns (uint256) {
        _updateVesting(_account);
        uint256 amount = claimable(_account);
        claimedAmounts[_account] = claimedAmounts[_account] + amount;
        claimableToken.safeTransfer(_receiver, amount);
        emit VestingClaim(_account, amount);
        return amount;
    }

    function _decreaseLockedVestingAmount(address _account, uint256 _amount) internal {
        lockedVestingAmounts[_account] -= _amount;
        totalLockedVestingAmount -= _amount;

        emit VestingTransfer(_account, ZERO_ADDRESS, _amount);
    }

    // Deposit tokens for Ankaa allocation.
    function _deposit(uint256 _pid, uint256 _amount) internal validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (_amount > 0) {
            uint256 beforeDeposit = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 afterDeposit = pool.lpToken.balanceOf(address(this));

            _amount = afterDeposit - beforeDeposit;
            user.amount += _amount;
            user.startTimestamp = block.timestamp;
        }

        for (uint256 rewarderId = 0; rewarderId < pool.rewarders.length; ++rewarderId) {
            pool.rewarders[rewarderId].onAnkaaReward(_pid, msg.sender, user.amount);
        }

        if (_amount > 0) {
            pool.totalLp += _amount;
        }

        emit FarmDeposit(msg.sender, _pid, _amount);
    }

    function _depositVesting(address _account, uint256 _amount) internal {
        require(_amount > 0, "Vester: invalid _amount");
        // note: the check here were moved to `_getNextClaimableAmount`, which is the only place
        //      that reads `lastVestingTimes[_account]`. Now `_getNextClaimableAmount(..)` is safe to call
        //      in any context, because it handles uninitialized `lastVestingTimes[_account]` on it's own.
        _updateVesting(_account);

        esToken.safeTransferFrom(_account, address(this), _amount);

        _increaseLockedVestingAmount(_account, _amount);

        emit VestingDeposit(_account, _amount);
    }

    function _increaseLockedVestingAmount(address _account, uint256 _amount) internal {
        require(_account != ZERO_ADDRESS, "Vester: mint to the zero address");

        totalLockedVestingAmount += _amount;
        lockedVestingAmounts[_account] += _amount;

        emit VestingTransfer(ZERO_ADDRESS, _account, _amount);
    }

    function _updateVesting(address _account) internal {
        uint256 unlockedThisTime = _getNextClaimableAmount(_account);
        lastVestingUpdateTimes[_account] = block.timestamp;

        if (unlockedThisTime == 0) {
            return;
        }

        // transfer claimableAmount from balances to unlocked amounts
        _decreaseLockedVestingAmount(_account, unlockedThisTime);
        unlockedVestingAmounts[_account] += unlockedThisTime;
        IMintable(address(esToken)).burn(address(this), unlockedThisTime);
    }

    function getTier(uint256 _pid, address _account) external view override returns (uint256) {
        UserInfo storage user = userInfo[_pid][_account];
        if (tierLevels.length == 0 || user.amount < tierLevels[0]) {
            return BASIS_POINTS_DIVISOR;
        }
        unchecked {
            for (uint16 i = 1; i != tierLevels.length; ++i) {
                if (user.amount < tierLevels[i]) {
                    return tierPercents[i - 1];
                }
            }
            return tierPercents[tierLevels.length - 1];
        }
    }

    function getTotalVested(address _account) external view returns (uint256) {
        return (lockedVestingAmounts[_account] + unlockedVestingAmounts[_account]);
    }

    // View function to see pending rewards on frontend.
    function pendingTokens(
        uint256 _pid,
        address _user
    )
        external
        view
        validatePoolByPid(_pid)
        returns (
            address[] memory addresses,
            string[] memory symbols,
            uint256[] memory decimals,
            uint256[] memory amounts
        )
    {
        PoolInfo storage pool = poolInfo[_pid];
        addresses = new address[](pool.rewarders.length);
        symbols = new string[](pool.rewarders.length);
        amounts = new uint256[](pool.rewarders.length);
        decimals = new uint256[](pool.rewarders.length);

        for (uint256 rewarderId = 0; rewarderId < pool.rewarders.length; ++rewarderId) {
            addresses[rewarderId] = address(pool.rewarders[rewarderId].rewardToken());

            symbols[rewarderId] = IBoringERC20(pool.rewarders[rewarderId].rewardToken()).safeSymbol();

            decimals[rewarderId] = IBoringERC20(pool.rewarders[rewarderId].rewardToken()).safeDecimals();
            amounts[rewarderId] = pool.rewarders[rewarderId].pendingTokens(_pid, _user);
        }
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // View function to see rewarders for a pool
    function poolRewarders(uint256 _pid) external view validatePoolByPid(_pid) returns (address[] memory rewarders) {
        PoolInfo storage pool = poolInfo[_pid];
        rewarders = new address[](pool.rewarders.length);
        for (uint256 rewarderId = 0; rewarderId < pool.rewarders.length; ++rewarderId) {
            rewarders[rewarderId] = address(pool.rewarders[rewarderId]);
        }
    }

    /// @notice View function to see pool rewards per sec
    function poolRewardsPerSec(
        uint256 _pid
    )
        external
        view
        validatePoolByPid(_pid)
        returns (
            address[] memory addresses,
            string[] memory symbols,
            uint256[] memory decimals,
            uint256[] memory rewardsPerSec
        )
    {
        PoolInfo storage pool = poolInfo[_pid];

        addresses = new address[](pool.rewarders.length);
        symbols = new string[](pool.rewarders.length);
        decimals = new uint256[](pool.rewarders.length);
        rewardsPerSec = new uint256[](pool.rewarders.length);

        for (uint256 rewarderId = 0; rewarderId < pool.rewarders.length; ++rewarderId) {
            addresses[rewarderId] = address(pool.rewarders[rewarderId].rewardToken());

            symbols[rewarderId] = IBoringERC20(pool.rewarders[rewarderId].rewardToken()).safeSymbol();

            decimals[rewarderId] = IBoringERC20(pool.rewarders[rewarderId].rewardToken()).safeDecimals();

            rewardsPerSec[rewarderId] = pool.rewarders[rewarderId].poolRewardsPerSec(_pid);
        }
    }

    function poolTotalLp(uint256 pid) external view returns (uint256) {
        return poolInfo[pid].totalLp;
    }

    function claimable(address _account) public view returns (uint256) {
        uint256 amount = unlockedVestingAmounts[_account] - claimedAmounts[_account];
        uint256 nextClaimable = _getNextClaimableAmount(_account);
        return (amount + nextClaimable);
    }

    function getVestedAmount(address _account) public view returns (uint256) {
        uint256 balance = lockedVestingAmounts[_account];
        uint256 cumulativeClaimAmount = unlockedVestingAmounts[_account];
        return (balance + cumulativeClaimAmount);
    }

    function _getNextClaimableAmount(address _account) private view returns (uint256) {
        uint256 lockedAmount = lockedVestingAmounts[_account];
        if (lockedAmount == 0) {
            return 0;
        }
        uint256 timeDiff = block.timestamp - lastVestingUpdateTimes[_account];
        // `timeDiff == block.timestamp` means `lastVestingTimes[_account]` has not been initialized
        if (timeDiff == 0 || timeDiff == block.timestamp) {
            return 0;
        }

        uint256 vestedAmount = lockedAmount + unlockedVestingAmounts[_account];
        uint256 claimableAmount = (vestedAmount * timeDiff) / vestingDuration;

        if (claimableAmount < lockedAmount) {
            return claimableAmount;
        }

        return lockedAmount;
    }
    function _validateLevels(uint256[] memory _levels) internal pure returns (bool) {
        unchecked {
            for (uint16 i = 1; i != _levels.length; ++i) {
                if (_levels[i-1] >= _levels[i]) {
                    return false;
                }
            }
            return true;
        }
    }

    function _validatePercents(uint256[] memory _percents) internal pure returns (bool) {
        unchecked {
            for (uint16 i = 0; i != _percents.length; ++i) {
                if (_percents[i] > BASIS_POINTS_DIVISOR) {
                    return false;
                }
            }
            return true;
        }
    }
}