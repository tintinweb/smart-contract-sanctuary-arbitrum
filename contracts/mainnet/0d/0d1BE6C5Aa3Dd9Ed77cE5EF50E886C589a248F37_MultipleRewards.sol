/**
 *Submitted for verification at Arbiscan on 2023-02-10
*/

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/farm/libraries/IBoringERC20.sol


pragma solidity 0.8.16;

interface IBoringERC20 {
    function mint(address to, uint256 amount) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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


// File contracts/farm/libraries/BoringERC20.sol


pragma solidity 0.8.16;

// solhint-disable avoid-low-level-calls
library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data)
        internal
        pure
        returns (string memory)
    {
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
    function safeSymbol(IBoringERC20 token)
        internal
        view
        returns (string memory)
    {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_SYMBOL)
        );
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IBoringERC20 token)
        internal
        view
        returns (string memory)
    {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_NAME)
        );
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IBoringERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_DECIMALS)
        );
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IBoringERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(SIG_TRANSFER, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "BoringERC20: Transfer failed"
        );
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IBoringERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "BoringERC20: TransferFrom failed"
        );
    }
}


// File contracts/farm/rewarders/IMultipleRewards.sol


pragma solidity 0.8.16;
interface IMultipleRewards {
    function onZyberReward(
        uint256 pid,
        address user,
        uint256 newLpAmount
    ) external;

    function pendingTokens(
        uint256 pid,
        address user
    ) external view returns (uint256 pending);

    function rewardToken() external view returns (IBoringERC20);

    function poolRewardsPerSec(uint256 pid) external view returns (uint256);
}


// File @openzeppelin/contracts/security/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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


// File contracts/farm/IZyberPair.sol


pragma solidity 0.8.16;

interface IZyberPair {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function initialize(address, address) external;
}


// File contracts/farm/ZyberChef.sol


pragma solidity 0.8.16;
contract ZyberChef is Ownable, ReentrancyGuard {
    using BoringERC20 for IBoringERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardLockedUp; // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
    }

    // Info of each pool.
    struct PoolInfo {
        IBoringERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Zyber to distribute per block.
        uint256 lastRewardTimestamp; // Last block number that Zyber distribution occurs.
        uint256 accZyberPerShare; // Accumulated Zyber per share, times 1e18. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
        uint256 harvestInterval; // Harvest interval in seconds
        uint256 totalLp; // Total token in Pool
        IMultipleRewards[] rewarders; // Array of rewarder contract for pools with incentives
    }

    IBoringERC20 public zyber;

    // Zyber tokens created per second
    uint256 public zyberPerSec;

    // Max harvest interval: 14 days
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;

    // Maximum deposit fee rate: 10%
    uint16 public constant MAXIMUM_DEPOSIT_FEE_RATE = 1000;

    // Info of each pool
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    // The timestamp when Zyber mining starts.
    uint256 public startTimestamp;

    // Total locked up rewards
    uint256 public totalLockedUpRewards;

    // Total Zyber in Zyber Pools (can be multiple pools)
    uint256 public totalZyberInPools;

    // marketing address.
    address public marketingAddress;

    // deposit fee address if needed
    address public feeAddress;

    // Percentage of pool rewards that goto the marketing.
    uint256 public marketingPercent = 45; // 4.5%

    // Percentage of pool rewards that goto the marketing.
    uint256 public teamPercent = 90; // 9%

    address public teamAddress;

    // The precision factor
    uint256 private constant ACC_TOKEN_PRECISION = 1e12;

    modifier validatePoolByPid(uint256 _pid) {
        require(_pid < poolInfo.length, "Pool does not exist");
        _;
    }

    event Add(
        uint256 indexed pid,
        uint256 allocPoint,
        IBoringERC20 indexed lpToken,
        uint16 depositFeeBP,
        uint256 harvestInterval,
        IMultipleRewards[] indexed rewarders
    );

    event Set(
        uint256 indexed pid,
        uint256 allocPoint,
        uint16 depositFeeBP,
        uint256 harvestInterval,
        IMultipleRewards[] indexed rewarders
    );

    event UpdatePool(
        uint256 indexed pid,
        uint256 lastRewardTimestamp,
        uint256 lpSupply,
        uint256 accZyberPerShare
    );

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event EmissionRateUpdated(
        address indexed caller,
        uint256 previousValue,
        uint256 newValue
    );

    event RewardLockedUp(
        address indexed user,
        uint256 indexed pid,
        uint256 amountLockedUp
    );

    event AllocPointsUpdated(
        address indexed caller,
        uint256 previousAmount,
        uint256 newAmount
    );

    event SetmarketingAddress(
        address indexed oldAddress,
        address indexed newAddress
    );

    event SetTeamAddress(
        address indexed oldAddress,
        address indexed newAddress
    );

    event SetFeeAddress(address indexed oldAddress, address indexed newAddress);

    event SetInvestorAddress(
        address indexed oldAddress,
        address indexed newAddress
    );

    event SetmarketingPercent(uint256 oldPercent, uint256 newPercent);

    event SetTeamPercent(uint256 oldPercent, uint256 newPercent);

    constructor(
        IBoringERC20 _zyber,
        uint256 _zyberPerSec,
        address _marketingAddress,
        uint256 _marketingPercent,
        address _teamAddress,
        uint256 _teamPercent,
        address _feeAddress
    ) {
        require(
            _marketingPercent <= 1000,
            "constructor: invalid marketing percent value"
        );

        startTimestamp = block.timestamp + (60 * 60 * 24 * 365);

        zyber = _zyber;
        zyberPerSec = _zyberPerSec;
        marketingAddress = _marketingAddress;
        teamAddress = _teamAddress;
        feeAddress = _feeAddress;
        teamPercent = _teamPercent;
    }

    // Set farming start
    function startFarming() public onlyOwner {
        require(block.timestamp < startTimestamp, "farm already started");

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardTimestamp = block.timestamp;
        }

        startTimestamp = block.timestamp;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // Can add multiple pool with same lp token without messing up rewards, because each pool's balance is tracked using its own totalLp
    function add(
        uint256 _allocPoint,
        IBoringERC20 _lpToken,
        uint16 _depositFeeBP,
        uint256 _harvestInterval,
        IMultipleRewards[] calldata _rewarders
    ) public onlyOwner {
        require(_rewarders.length <= 10, "add: too many rewarders");
        require(
            _depositFeeBP <= MAXIMUM_DEPOSIT_FEE_RATE,
            "add: deposit fee too high"
        );
        require(
            _harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
            "add: invalid harvest interval"
        );
        for (
            uint256 rewarderId = 0;
            rewarderId < _rewarders.length;
            ++rewarderId
        ) {
            require(
                Address.isContract(address(_rewarders[rewarderId])),
                "add: rewarder must be contract"
            );
        }

        _massUpdatePools();

        uint256 lastRewardTimestamp = block.timestamp > startTimestamp
            ? block.timestamp
            : startTimestamp;

        totalAllocPoint += _allocPoint;

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardTimestamp: lastRewardTimestamp,
                accZyberPerShare: 0,
                depositFeeBP: _depositFeeBP,
                harvestInterval: _harvestInterval,
                totalLp: 0,
                rewarders: _rewarders
            })
        );

        emit Add(
            poolInfo.length - 1,
            _allocPoint,
            _lpToken,
            _depositFeeBP,
            _harvestInterval,
            _rewarders
        );
    }

    // Update the given pool's Zyber allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        uint256 _harvestInterval,
        IMultipleRewards[] calldata _rewarders
    ) public onlyOwner validatePoolByPid(_pid) {
        require(_rewarders.length <= 10, "set: too many rewarders");

        require(
            _depositFeeBP <= MAXIMUM_DEPOSIT_FEE_RATE,
            "set: deposit fee too high"
        );
        require(
            _harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
            "set: invalid harvest interval"
        );

        for (
            uint256 rewarderId = 0;
            rewarderId < _rewarders.length;
            ++rewarderId
        ) {
            require(
                Address.isContract(address(_rewarders[rewarderId])),
                "set: rewarder must be contract"
            );
        }

        _massUpdatePools();

        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;

        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;
        poolInfo[_pid].rewarders = _rewarders;

        emit Set(
            _pid,
            _allocPoint,
            _depositFeeBP,
            _harvestInterval,
            _rewarders
        );
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
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accZyberPerShare = pool.accZyberPerShare;
        uint256 lpSupply = pool.totalLp;

        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 multiplier = block.timestamp - pool.lastRewardTimestamp;
            uint256 total = 1000;
            uint256 lpPercent = total - marketingPercent;

            uint256 zyberReward = (multiplier *
                zyberPerSec *
                pool.allocPoint *
                lpPercent) /
                totalAllocPoint /
                total;

            accZyberPerShare += (
                ((zyberReward * ACC_TOKEN_PRECISION) / lpSupply)
            );
        }

        uint256 pendingZyber = (((user.amount * accZyberPerShare) /
            ACC_TOKEN_PRECISION) - user.rewardDebt) + user.rewardLockedUp;

        addresses = new address[](pool.rewarders.length + 1);
        symbols = new string[](pool.rewarders.length + 1);
        amounts = new uint256[](pool.rewarders.length + 1);
        decimals = new uint256[](pool.rewarders.length + 1);

        addresses[0] = address(zyber);
        symbols[0] = IBoringERC20(zyber).safeSymbol();
        decimals[0] = IBoringERC20(zyber).safeDecimals();
        amounts[0] = pendingZyber;

        for (
            uint256 rewarderId = 0;
            rewarderId < pool.rewarders.length;
            ++rewarderId
        ) {
            addresses[rewarderId + 1] = address(
                pool.rewarders[rewarderId].rewardToken()
            );

            symbols[rewarderId + 1] = IBoringERC20(
                pool.rewarders[rewarderId].rewardToken()
            ).safeSymbol();

            decimals[rewarderId + 1] = IBoringERC20(
                pool.rewarders[rewarderId].rewardToken()
            ).safeDecimals();

            amounts[rewarderId + 1] = pool.rewarders[rewarderId].pendingTokens(
                _pid,
                _user
            );
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

        addresses = new address[](pool.rewarders.length + 1);
        symbols = new string[](pool.rewarders.length + 1);
        decimals = new uint256[](pool.rewarders.length + 1);
        rewardsPerSec = new uint256[](pool.rewarders.length + 1);

        addresses[0] = address(zyber);
        symbols[0] = IBoringERC20(zyber).safeSymbol();
        decimals[0] = IBoringERC20(zyber).safeDecimals();

        uint256 total = 1000;
        uint256 lpPercent = total - marketingPercent;

        rewardsPerSec[0] =
            (pool.allocPoint * zyberPerSec * lpPercent) /
            totalAllocPoint /
            total;

        for (
            uint256 rewarderId = 0;
            rewarderId < pool.rewarders.length;
            ++rewarderId
        ) {
            addresses[rewarderId + 1] = address(
                pool.rewarders[rewarderId].rewardToken()
            );

            symbols[rewarderId + 1] = IBoringERC20(
                pool.rewarders[rewarderId].rewardToken()
            ).safeSymbol();

            decimals[rewarderId + 1] = IBoringERC20(
                pool.rewarders[rewarderId].rewardToken()
            ).safeDecimals();

            rewardsPerSec[rewarderId + 1] = pool
                .rewarders[rewarderId]
                .poolRewardsPerSec(_pid);
        }
    }

    // View function to see rewarders for a pool
    function poolRewarders(
        uint256 _pid
    )
        external
        view
        validatePoolByPid(_pid)
        returns (address[] memory rewarders)
    {
        PoolInfo storage pool = poolInfo[_pid];
        rewarders = new address[](pool.rewarders.length);
        for (
            uint256 rewarderId = 0;
            rewarderId < pool.rewarders.length;
            ++rewarderId
        ) {
            rewarders[rewarderId] = address(pool.rewarders[rewarderId]);
        }
    }

    // View function to see if user can harvest Zyber.
    function canHarvest(
        uint256 _pid,
        address _user
    ) public view validatePoolByPid(_pid) returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return
            block.timestamp >= startTimestamp &&
            block.timestamp >= user.nextHarvestUntil;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() external nonReentrant {
        _massUpdatePools();
    }

    // Internal method for massUpdatePools
    function _massUpdatePools() internal {
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            _updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) external nonReentrant {
        _updatePool(_pid);
    }

    function _updatePool(uint256 _pid) internal validatePoolByPid(_pid) {
        // Internal method for _updatePool

        PoolInfo storage pool = poolInfo[_pid];

        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }

        uint256 lpSupply = pool.totalLp;

        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }

        uint256 multiplier = block.timestamp - pool.lastRewardTimestamp;

        uint256 zyberReward = ((multiplier * zyberPerSec) * pool.allocPoint) /
            totalAllocPoint;

        uint256 total = 1000;
        uint256 lpPercent = total - marketingPercent - teamPercent;

        if (marketingPercent > 0) {
            zyber.mint(
                marketingAddress,
                (zyberReward * marketingPercent) / total
            );
        }

        if (teamPercent > 0) {
            zyber.mint(teamAddress, (zyberReward * teamPercent) / total);
        }

        zyber.mint(address(this), (zyberReward * lpPercent) / total);

        pool.accZyberPerShare +=
            (zyberReward * ACC_TOKEN_PRECISION * lpPercent) /
            pool.totalLp /
            total;

        pool.lastRewardTimestamp = block.timestamp;

        emit UpdatePool(
            _pid,
            pool.lastRewardTimestamp,
            lpSupply,
            pool.accZyberPerShare
        );
    }

    function depositWithPermit(
        uint256 pid,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public nonReentrant validatePoolByPid(pid) {
        PoolInfo storage pool = poolInfo[pid];
        IZyberPair pair = IZyberPair(address(pool.lpToken));
        pair.permit(msg.sender, address(this), amount, deadline, v, r, s);
        _deposit(pid, amount);
    }

    // Deposit tokens for Zyber allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        _deposit(_pid, _amount);
    }

    // Deposit tokens for Zyber allocation.
    function _deposit(
        uint256 _pid,
        uint256 _amount
    ) internal validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        _updatePool(_pid);

        payOrLockupPendingZyber(_pid);

        if (_amount > 0) {
            uint256 beforeDeposit = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 afterDeposit = pool.lpToken.balanceOf(address(this));

            _amount = afterDeposit - beforeDeposit;

            if (pool.depositFeeBP > 0) {
                uint256 depositFee = (_amount * pool.depositFeeBP) / 10000;
                pool.lpToken.safeTransfer(feeAddress, depositFee);

                _amount = _amount - depositFee;
            }

            user.amount += _amount;

            if (address(pool.lpToken) == address(zyber)) {
                totalZyberInPools += _amount;
            }
        }
        user.rewardDebt =
            (user.amount * pool.accZyberPerShare) /
            ACC_TOKEN_PRECISION;

        for (
            uint256 rewarderId = 0;
            rewarderId < pool.rewarders.length;
            ++rewarderId
        ) {
            pool.rewarders[rewarderId].onZyberReward(
                _pid,
                msg.sender,
                user.amount
            );
        }

        if (_amount > 0) {
            pool.totalLp += _amount;
        }

        emit Deposit(msg.sender, _pid, _amount);
    }

    //withdraw tokens
    function withdraw(
        uint256 _pid,
        uint256 _amount
    ) public nonReentrant validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        //this will make sure that user can only withdraw from his pool
        require(user.amount >= _amount, "withdraw: user amount not enough");

        //cannot withdraw more than pool's balance
        require(pool.totalLp >= _amount, "withdraw: pool total not enough");

        _updatePool(_pid);

        payOrLockupPendingZyber(_pid);

        if (_amount > 0) {
            user.amount -= _amount;
            if (address(pool.lpToken) == address(zyber)) {
                totalZyberInPools -= _amount;
            }
            pool.lpToken.safeTransfer(msg.sender, _amount);
        }

        user.rewardDebt =
            (user.amount * pool.accZyberPerShare) /
            ACC_TOKEN_PRECISION;

        for (
            uint256 rewarderId = 0;
            rewarderId < pool.rewarders.length;
            ++rewarderId
        ) {
            pool.rewarders[rewarderId].onZyberReward(
                _pid,
                msg.sender,
                user.amount
            );
        }

        if (_amount > 0) {
            pool.totalLp -= _amount;
        }

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;

        //Cannot withdraw more than pool's balance
        require(
            pool.totalLp >= amount,
            "emergency withdraw: pool total not enough"
        );

        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        pool.totalLp -= amount;

        for (
            uint256 rewarderId = 0;
            rewarderId < pool.rewarders.length;
            ++rewarderId
        ) {
            pool.rewarders[rewarderId].onZyberReward(_pid, msg.sender, 0);
        }

        if (address(pool.lpToken) == address(zyber)) {
            totalZyberInPools -= amount;
        }

        pool.lpToken.safeTransfer(msg.sender, amount);

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay or lockup pending Zyber.
    function payOrLockupPendingZyber(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0 && block.timestamp >= startTimestamp) {
            user.nextHarvestUntil = block.timestamp + pool.harvestInterval;
        }

        if (user.nextHarvestUntil != 0 && pool.harvestInterval == 0) {
            user.nextHarvestUntil = 0;
        }

        uint256 pending = ((user.amount * pool.accZyberPerShare) /
            ACC_TOKEN_PRECISION) - user.rewardDebt;

        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 pendingRewards = pending + user.rewardLockedUp;

                // reset lockup
                totalLockedUpRewards -= user.rewardLockedUp;
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp + pool.harvestInterval;
                safeZyberTransfer(msg.sender, pendingRewards);
            }
        } else if (pending > 0) {
            totalLockedUpRewards += pending;
            user.rewardLockedUp += pending;
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    function safeZyberTransfer(address _to, uint256 _amount) internal {
        if (zyber.balanceOf(address(this)) > totalZyberInPools) {
            uint256 zyberBal = zyber.balanceOf(address(this)) -
                totalZyberInPools;
            if (_amount >= zyberBal) {
                zyber.safeTransfer(_to, zyberBal);
            } else if (_amount > 0) {
                zyber.safeTransfer(_to, _amount);
            }
        }
    }

    function updateAllocPoint(
        uint256 _pid,
        uint256 _allocPoint
    ) public onlyOwner {
        _massUpdatePools();

        emit AllocPointsUpdated(
            msg.sender,
            poolInfo[_pid].allocPoint,
            _allocPoint
        );

        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function updateEmissionRate(uint256 _zyberPerSec) public onlyOwner {
        _massUpdatePools();

        emit EmissionRateUpdated(msg.sender, zyberPerSec, _zyberPerSec);

        zyberPerSec = _zyberPerSec;
    }

    function poolTotalLp(uint256 pid) external view returns (uint256) {
        return poolInfo[pid].totalLp;
    }

    // Function to harvest many pools in a single transaction
    function harvestMany(uint256[] calldata _pids) public nonReentrant {
        require(_pids.length <= 30, "harvest many: too many pool ids");
        for (uint256 index = 0; index < _pids.length; ++index) {
            _deposit(_pids[index], 0);
        }
    }

    function setMarketingAddress(address _marketingAddress) public onlyOwner {
        require(
            _marketingAddress != address(0),
            "invalid new marketing address"
        );
        marketingAddress = _marketingAddress;
        emit SetmarketingAddress(_marketingAddress, marketingAddress);
    }

    function setTeamAddress(address _teamAddress) public onlyOwner {
        require(_teamAddress != address(0), "invalid new team address");
        teamAddress = _teamAddress;
        emit SetTeamAddress(_teamAddress, teamAddress);
    }

    function setMarketingPercent(
        uint256 _newmarketingPercent
    ) public onlyOwner {
        require(_newmarketingPercent <= 2000, "invalid percent value");
        emit SetmarketingPercent(marketingPercent, _newmarketingPercent);
        marketingPercent = _newmarketingPercent;
    }

    function setTeamPercent(uint256 _newTeamPercent) public onlyOwner {
        require(_newTeamPercent <= 2000, "invalid percent value");
        emit SetTeamPercent(teamPercent, _newTeamPercent);
        teamPercent = _newTeamPercent;
    }

    function setFeeAddress(address _feeAddress) public onlyOwner {
        require(_feeAddress != address(0), "wrong address");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    function getZyberPerSec() public view returns (uint256) {
        return zyberPerSec;
    }
}


// File contracts/farm/rewarders/MultipleRewards.sol


pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;
contract MultipleRewards is IMultipleRewards, Ownable, ReentrancyGuard {
    using BoringERC20 for IBoringERC20;

    IBoringERC20 public immutable override rewardToken;
    ZyberChef public immutable distributorV2;
    bool public immutable isNative;
    mapping(address => bool) public operators;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint256 accTokenPerShare;
        uint256 startTimestamp;
        uint256 lastRewardTimestamp;
        uint256 allocPoint;
        uint256 totalRewards;
    }

    struct RewardInfo {
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 rewardPerSec;
    }

    /// @notice Info of each pool.
    mapping(uint256 => PoolInfo) public poolInfo;

    /// @dev this is mostly used for extending reward period
    /// @notice Reward info is a set of {endTimestamp, rewardPerSec}
    /// indexed by pool id
    mapping(uint256 => RewardInfo[]) public poolRewardInfo;

    uint256[] public poolIds;

    /// @notice Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    /// @notice limit length of reward info
    /// how many phases are allowed
    uint256 public immutable rewardInfoLimit = 30;

    // The precision factor
    uint256 private immutable ACC_TOKEN_PRECISION;

    event OnReward(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 oldRate, uint256 newRate);
    event AddPool(uint256 indexed pid, uint256 allocPoint);
    event SetPool(uint256 indexed pid, uint256 allocPoint);
    event UpdatePool(
        uint256 indexed pid,
        uint256 lastRewardTimestamp,
        uint256 lpSupply,
        uint256 accTokenPerShare
    );

    event AddRewardInfo(
        uint256 indexed pid,
        uint256 indexed phase,
        uint256 endTimestamp,
        uint256 rewardPerSec
    );

    modifier onlyOperator() {
        require(operators[msg.sender], "not operator");
        _;
    }

    modifier onlyDistributorV2() {
        require(
            msg.sender == address(distributorV2),
            "onlyDistributorV2: only ZyberChef can call this function"
        );
        _;
    }

    constructor(
        IBoringERC20 _rewardToken,
        ZyberChef _distributorV2,
        bool _isNative
    ) {
        require(
            Address.isContract(address(_rewardToken)),
            "constructor: reward token must be a valid contract"
        );
        require(
            Address.isContract(address(_distributorV2)),
            "constructor: ZyberChef must be a valid contract"
        );
        rewardToken = _rewardToken;
        distributorV2 = _distributorV2;
        isNative = _isNative;

        uint256 decimalsRewardToken = uint256(
            _isNative ? 18 : _rewardToken.safeDecimals()
        );
        require(
            decimalsRewardToken < 30,
            "constructor: reward token decimals must be inferior to 30"
        );

        ACC_TOKEN_PRECISION = uint256(
            10 ** (uint256(30) - (decimalsRewardToken))
        );
        operators[msg.sender] = true;
    }

    /// @notice Add a new pool. Can only be called by the owner.
    /// @param _pid pool id on DistributorV2
    /// @param _allocPoint allocation of the new pool.
    function add(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _startTimestamp
    ) public onlyOperator {
        require(poolInfo[_pid].lastRewardTimestamp == 0, "pool already exists");
        totalAllocPoint += _allocPoint;

        poolInfo[_pid] = PoolInfo({
            allocPoint: _allocPoint,
            startTimestamp: _startTimestamp,
            lastRewardTimestamp: _startTimestamp,
            accTokenPerShare: 0,
            totalRewards: 0
        });

        poolIds.push(_pid);
        emit AddPool(_pid, _allocPoint);
    }

    /// @notice if the new reward info is added, the reward & its end timestamp will be extended by the newly pushed reward info.
    function addRewardInfo(
        uint256 _pid,
        uint256 _endTimestamp,
        uint256 _rewardPerSec
    ) external payable onlyOperator {
        RewardInfo[] storage rewardInfo = poolRewardInfo[_pid];
        PoolInfo storage pool = poolInfo[_pid];
        require(
            rewardInfo.length < rewardInfoLimit,
            "add reward info: reward info length exceeds the limit"
        );
        require(
            rewardInfo.length == 0 ||
                rewardInfo[rewardInfo.length - 1].endTimestamp >=
                block.timestamp,
            "add reward info: reward period ended"
        );
        require(
            rewardInfo.length == 0 ||
                rewardInfo[rewardInfo.length - 1].endTimestamp < _endTimestamp,
            "add reward info: bad new endTimestamp"
        );

        uint256 startTimestamp = rewardInfo.length == 0
            ? pool.startTimestamp
            : rewardInfo[rewardInfo.length - 1].endTimestamp;

        uint256 timeRange = _endTimestamp - startTimestamp;
        uint256 totalRewards = timeRange * _rewardPerSec;

        if (!isNative) {
            rewardToken.safeTransferFrom(
                msg.sender,
                address(this),
                totalRewards
            );
        } else {
            require(
                msg.value == totalRewards,
                "add reward info: not enough funds to transfer"
            );
        }

        pool.totalRewards += totalRewards;

        rewardInfo.push(
            RewardInfo({
                startTimestamp: startTimestamp,
                endTimestamp: _endTimestamp,
                rewardPerSec: _rewardPerSec
            })
        );

        emit AddRewardInfo(
            _pid,
            rewardInfo.length - 1,
            _endTimestamp,
            _rewardPerSec
        );
    }

    function _endTimestampOf(
        uint256 _pid,
        uint256 _timestamp
    ) internal view returns (uint256) {
        RewardInfo[] memory rewardInfo = poolRewardInfo[_pid];
        uint256 len = rewardInfo.length;
        if (len == 0) {
            return 0;
        }
        for (uint256 i = 0; i < len; ++i) {
            if (_timestamp <= rewardInfo[i].endTimestamp)
                return rewardInfo[i].endTimestamp;
        }

        /// @dev when couldn't find any reward info, it means that _timestamp exceed endTimestamp
        /// so return the latest reward info.
        return rewardInfo[len - 1].endTimestamp;
    }

    /// @notice this will return end timestamp based on the current block timestamp.
    function currentEndTimestamp(uint256 _pid) external view returns (uint256) {
        return _endTimestampOf(_pid, block.timestamp);
    }

    /// @notice Return reward multiplier over the given _from to _to timestamp.
    function _getTimeElapsed(
        uint256 _from,
        uint256 _to,
        uint256 _endTimestamp
    ) public pure returns (uint256) {
        if ((_from >= _endTimestamp) || (_from > _to)) {
            return 0;
        }
        if (_to <= _endTimestamp) {
            return _to - _from;
        }
        return _endTimestamp - _from;
    }

    /// @notice Update reward variables of the given pool.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(
        uint256 _pid
    ) external nonReentrant returns (PoolInfo memory pool) {
        return _updatePool(_pid);
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function _updatePool(uint256 pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[pid];
        RewardInfo[] memory rewardInfo = poolRewardInfo[pid];

        if (block.timestamp <= pool.lastRewardTimestamp) {
            return pool;
        }

        uint256 lpSupply = distributorV2.poolTotalLp(pid);

        if (lpSupply == 0) {
            // if there is no total supply, return and use the pool's start timestamp as the last reward timestamp
            // so that ALL reward will be distributed.
            // however, if the first deposit is out of reward period, last reward timestamp will be its timestamp
            // in order to keep the multiplier = 0
            if (block.timestamp > _endTimestampOf(pid, block.timestamp)) {
                pool.lastRewardTimestamp = block.timestamp;
                emit UpdatePool(
                    pid,
                    pool.lastRewardTimestamp,
                    lpSupply,
                    pool.accTokenPerShare
                );
            }

            return pool;
        }

        /// @dev for each reward info
        for (uint256 i = 0; i < rewardInfo.length; ++i) {
            // @dev get multiplier based on current timestamp and rewardInfo's end timestamp
            // multiplier will be a range of either (current timestamp - pool.timestamp)
            // or (reward info's endtimestamp - pool.timestamp) or 0
            uint256 timeElapsed = _getTimeElapsed(
                pool.lastRewardTimestamp,
                block.timestamp,
                rewardInfo[i].endTimestamp
            );
            if (timeElapsed == 0) continue;

            // @dev if currentTimestamp exceed end timestamp, use end timestamp as the last reward timestamp
            // so that for the next iteration, previous endTimestamp will be used as the last reward timestamp
            if (block.timestamp > rewardInfo[i].endTimestamp) {
                pool.lastRewardTimestamp = rewardInfo[i].endTimestamp;
            } else {
                pool.lastRewardTimestamp = block.timestamp;
            }

            uint256 tokenReward = (timeElapsed *
                rewardInfo[i].rewardPerSec *
                pool.allocPoint) / totalAllocPoint;

            pool.accTokenPerShare += ((tokenReward * ACC_TOKEN_PRECISION) /
                lpSupply);
        }

        poolInfo[pid] = pool;

        emit UpdatePool(
            pid,
            pool.lastRewardTimestamp,
            lpSupply,
            pool.accTokenPerShare
        );

        return pool;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public nonReentrant {
        _massUpdatePools();
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function _massUpdatePools() internal {
        uint256 length = poolIds.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(poolIds[pid]);
        }
    }

    /// @notice Function called by ZyberChef whenever staker claims ZYBER harvest. Allows staker to also receive a 2nd reward token.
    /// @param _user Address of user
    /// @param _amount Number of LP tokens the user has
    function onZyberReward(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) external override onlyDistributorV2 nonReentrant {
        PoolInfo memory pool = _updatePool(_pid);
        UserInfo storage user = userInfo[_pid][_user];

        uint256 pending = 0;
        uint256 rewardBalance = 0;

        if (isNative) {
            rewardBalance = address(this).balance;
        } else {
            rewardBalance = rewardToken.balanceOf(address(this));
        }

        if (user.amount > 0) {
            pending = (((user.amount * pool.accTokenPerShare) /
                ACC_TOKEN_PRECISION) - user.rewardDebt);

            if (pending > 0) {
                if (isNative) {
                    if (pending > rewardBalance) {
                        (bool success, ) = _user.call{value: rewardBalance}("");
                        require(success, "Transfer failed");
                    } else {
                        (bool success, ) = _user.call{value: pending}("");
                        require(success, "Transfer failed");
                    }
                } else {
                    if (pending > rewardBalance) {
                        rewardToken.safeTransfer(_user, rewardBalance);
                    } else {
                        rewardToken.safeTransfer(_user, pending);
                    }
                }
            }
        }

        user.amount = _amount;

        user.rewardDebt =
            (user.amount * pool.accTokenPerShare) /
            ACC_TOKEN_PRECISION;

        emit OnReward(_user, pending);
    }

    /// @notice View function to see pending Reward on frontend.
    function pendingTokens(
        uint256 _pid,
        address _user
    ) external view override returns (uint256) {
        return
            _pendingTokens(
                _pid,
                userInfo[_pid][_user].amount,
                userInfo[_pid][_user].rewardDebt
            );
    }

    function _pendingTokens(
        uint256 _pid,
        uint256 _amount,
        uint256 _rewardDebt
    ) internal view returns (uint256 pending) {
        PoolInfo memory pool = poolInfo[_pid];
        RewardInfo[] memory rewardInfo = poolRewardInfo[_pid];

        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = distributorV2.poolTotalLp(_pid);

        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 cursor = pool.lastRewardTimestamp;

            for (uint256 i = 0; i < rewardInfo.length; ++i) {
                uint256 timeElapsed = _getTimeElapsed(
                    cursor,
                    block.timestamp,
                    rewardInfo[i].endTimestamp
                );
                if (timeElapsed == 0) continue;
                cursor = rewardInfo[i].endTimestamp;

                uint256 tokenReward = (timeElapsed *
                    rewardInfo[i].rewardPerSec *
                    pool.allocPoint) / totalAllocPoint;

                accTokenPerShare +=
                    (tokenReward * ACC_TOKEN_PRECISION) /
                    lpSupply;
            }
        }

        pending = (((_amount * accTokenPerShare) / ACC_TOKEN_PRECISION) -
            _rewardDebt);
    }

    function _rewardPerSecOf(
        uint256 _pid,
        uint256 _blockTimestamp
    ) internal view returns (uint256) {
        RewardInfo[] memory rewardInfo = poolRewardInfo[_pid];
        PoolInfo storage pool = poolInfo[_pid];
        uint256 len = rewardInfo.length;
        if (len == 0) {
            return 0;
        }
        for (uint256 i = 0; i < len; ++i) {
            if (_blockTimestamp <= rewardInfo[i].endTimestamp)
                return
                    (rewardInfo[i].rewardPerSec * pool.allocPoint) /
                    totalAllocPoint;
        }
        /// @dev when couldn't find any reward info, it means that timestamp exceed endblock
        /// so return 0
        return 0;
    }

    /// @notice View function to see pool rewards per sec
    function poolRewardsPerSec(
        uint256 _pid
    ) external view override returns (uint256) {
        return _rewardPerSecOf(_pid, block.timestamp);
    }

    /// @notice Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(
        uint256 _pid,
        uint256 _amount,
        address _beneficiary
    ) external onlyOperator nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lpSupply = distributorV2.poolTotalLp(_pid);

        uint256 currentStakingPendingReward = _pendingTokens(_pid, lpSupply, 0);

        require(
            currentStakingPendingReward + _amount <= pool.totalRewards,
            "emergency reward withdraw: not enough reward token"
        );
        pool.totalRewards -= _amount;

        if (!isNative) {
            rewardToken.safeTransfer(_beneficiary, _amount);
        } else {
            (bool sent, ) = _beneficiary.call{value: _amount}("");
            require(sent, "emergency reward withdraw: failed to send");
        }
    }

    function setOperator(address _operator) external onlyOperator {
        operators[_operator] = true;
    }

    function cancelOperator(address _operator) external onlyOperator {
        operators[_operator] = false;
    }
}