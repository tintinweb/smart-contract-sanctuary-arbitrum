// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IFeeLP {
    function balanceOf(address account) external view returns (uint256);

    function unlock(
        address user,
        address lockTo,
        uint256 amount,
        bool isIncrease
    ) external;

    function burnLocked(
        address user,
        address lockTo,
        uint256 amount,
        bool isIncrease
    ) external;

    function lock(
        address user,
        address lockTo,
        uint256 amount,
        bool isIncrease
    ) external;

    function locked(
        address user,
        address lockTo,
        bool isIncrease
    ) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function transfer(address recipient, uint256 amount) external;

    function isKeeper(address addr) external view returns (bool);

    function decimals() external pure returns (uint8);

    function mintTo(address user, uint256 amount) external;

    function burn(address user, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../library/utils/math/SafeMath.sol";
import "../library/token/ERC20/IERC20.sol";
import "../library/token/ERC20/utils/SafeERC20.sol";
import "../core/interfaces/IFeeLP.sol";
import "../library/utils/structs/EnumerableSet.sol";

interface ILionDexNFT {
    function genesisMaxTokenId() external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);
}

interface ILionDEXRewardVault {
    function withdrawEth(uint256 amount) external;

    function withdrawToken(IERC20 token, uint256 amount) external;
}

contract BasePools is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 totalAmount; //deposit token's total amount
        uint256[] amount; //deposit token's amount
        uint256[] rewardDebt; //reward token's
        uint256 buff1;
        uint256 buff2;
        uint256 weight;
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 startTime;
        IERC20[] depositTokens;
        IERC20[] rewardTokens;
        uint256[] rewardTokenPerSecond;
        uint256 lastRewardTime;
        uint256[] accRewardTokenPerShare;
        uint256[] staked; //total staked per token
        uint256 totalStaked; //sum deposit token's staked amount
        uint256 totalWeight;
    }

    uint256 public constant BasePoint = 1e4;
    uint256 public constant buffPerNFT = 500;
    uint256 public constant pfpBuffPerNFT = 200;
    uint256 public constant precise = 1e18;
    address public constant WETH =
        address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    PoolInfo[] public poolInfo;
    //poolId=>user=>user info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    ILionDEXRewardVault public rewardVault;
    mapping(address => bool) public rewardKeeperMap;

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        IERC20 depositToken,
        uint256 amount
    );
    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        IERC20 withdrawToken,
        uint256 amount
    );
    event SetRewardKeeper(address sender,address addr,bool active);
    modifier onlyRewardKeeper() {
        require(isRewardKeeper(msg.sender), "StartPools: not keeper");
        _;
    }

    function init(ILionDEXRewardVault _rewardVault) internal {
        rewardVault = _rewardVault;
        rewardKeeperMap[msg.sender] = true;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function addPool(
        uint256 startTime,
        IERC20[] memory depositTokens,
        IERC20[] memory rewardTokens,
        uint256[] memory rewardTokenPerSecond
    ) public onlyOwner {
        require(startTime > block.timestamp, "BasePools: startTime invalid");

        require(
            depositTokens.length > 0 &&
                rewardTokens.length > 0 &&
                rewardTokens.length == rewardTokenPerSecond.length,
            "BasePools: invalid length"
        );
        poolInfo.push(
            PoolInfo(
                startTime,
                depositTokens,
                rewardTokens,
                rewardTokenPerSecond,
                startTime, //lastRewardTime
                new uint256[](rewardTokens.length), //accRewardTokenPerShare
                new uint256[](depositTokens.length), //staked
                0, //totalStaked
                0
            )
        );
    }

    function setRewardTokenPerSecond(
        uint256 _pid,
        uint256[] memory rewardTokenPerSecond
    ) public onlyRewardKeeper {
        PoolInfo storage pi = poolInfo[_pid];
        require(pi.startTime > 0, "BasePools: not exists");
        require(
            pi.rewardTokens.length == rewardTokenPerSecond.length,
            "BasePools: length invalid"
        );
        updatePool(_pid);
        pi.rewardTokenPerSecond = rewardTokenPerSecond;
    }

    function pendingReward(
        uint256 _pid,
        address _user
    ) external view returns (uint256[] memory rewards) {
        require(_pid < poolInfo.length, "BasePools: pid not exists");

        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        if (pool.totalWeight == 0 || user.weight == 0) {
            return rewards;
        }
        uint256 tokenLength = pool.rewardTokens.length;
        rewards = new uint256[](tokenLength);

        for (uint i; i < tokenLength; i++) {
            uint256 multipier = getMultiplier(
                pool.lastRewardTime,
                block.timestamp
            );
            uint256 reward = multipier.mul(pool.rewardTokenPerSecond[i]);
            uint256 accRewardPerShare = pool.accRewardTokenPerShare[i].add(
                reward.mul(precise).div(pool.totalWeight)
            );
            uint256 current = user.weight.mul(accRewardPerShare).div(precise);
            if (current <= user.rewardDebt[i]) {
                continue;
            }
            rewards[i] = current.sub(user.rewardDebt[i]);
        }
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.startTime == 0) {
            return;
        }
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        if (pool.totalWeight == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 tokenLength = pool.rewardTokens.length;
        for (uint i; i < tokenLength; i++) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardTime,
                block.timestamp
            );
            uint256 reward = multiplier.mul(pool.rewardTokenPerSecond[i]);

            pool.accRewardTokenPerShare[i] = pool.accRewardTokenPerShare[i].add(
                reward.mul(precise).div(pool.totalWeight)
            );
        }
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit tokens to specific pool for reward
    function deposit(
        uint256 _pid,
        IERC20 depositToken,
        uint256 _amount
    ) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.startTime > 0, "BasePools: pool not exist");
        require(
            checkPoolToken(_pid, depositToken),
            "BasePools: deposit token invalid"
        );
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount.length == 0) {
            user.amount = new uint256[](pool.depositTokens.length);
        }
        if (user.rewardDebt.length == 0) {
            user.rewardDebt = new uint256[](pool.rewardTokens.length);
        }

        //transfer pending reward
        if (user.weight > 0) {
           transferRewards(pool, user);
        }

        if (_amount > 0) {
            depositToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            for (uint i; i < pool.depositTokens.length; i++) {
                if (pool.depositTokens[i] == depositToken) {
                    user.amount[i] = user.amount[i].add(_amount);
                    pool.staked[i] = pool.staked[i].add(_amount);
                }
            }
            user.totalAmount = user.totalAmount.add(_amount);
            pool.totalStaked = pool.totalStaked.add(_amount);
            //110/100
            uint256 buff = _amount.mul(user.buff1 + user.buff2 + BasePoint).div(
                BasePoint
            );
            user.weight = user.weight.add(buff);

            pool.totalWeight = pool.totalWeight.add(buff);
        }

        updateRewardDebt(pool, user);

        emit Deposit(msg.sender, _pid, depositToken, _amount);
    }

    function withdraw(
        uint256 _pid,
        IERC20 withdrawToken,
        uint256 _amount
    ) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.startTime > 0, "BasePools: pool not exist");
        require(
            checkPoolToken(_pid, withdrawToken),
            "BasePools: withdraw token invalid"
        );
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        //transfer pending reward
        if (user.weight > 0) {
           transferRewards(pool, user);
        }

        if (_amount > 0) {
            for (uint i; i < pool.depositTokens.length; i++) {
                if (pool.depositTokens[i] == withdrawToken) {
                    require(
                        user.amount[i] >= _amount,
                        "BasePools: _amount invalid"
                    );
                    user.amount[i] = user.amount[i].sub(_amount);
                    pool.staked[i] = pool.staked[i].sub(_amount);
                }
            }

            user.totalAmount = user.totalAmount.sub(_amount);
            pool.totalStaked = pool.totalStaked.sub(_amount);
            uint256 buff = _amount.mul(user.buff1 + user.buff2 + BasePoint).div(
                BasePoint
            );
            user.weight = user.weight.sub(buff);
            pool.totalWeight = pool.totalWeight.sub(buff);

            withdrawToken.safeTransfer(address(msg.sender), _amount);
        }

        updateRewardDebt(pool, user);

        emit Withdraw(msg.sender, _pid, withdrawToken, _amount);
    }

    function updateRewardDebt(
        PoolInfo storage pool,
        UserInfo storage user
    ) private {
        for (uint i; i < pool.rewardTokens.length; i++) {
            user.rewardDebt[i] = user
                .weight
                .mul(pool.accRewardTokenPerShare[i])
                .div(precise);
        }
    }

    function transferRewards(
        PoolInfo storage pool,
        UserInfo storage user
    ) private {
        uint256 tokenLength = pool.rewardTokens.length;
        for (uint i; i < tokenLength; i++) {
                uint256 current = user
                    .weight
                    .mul(pool.accRewardTokenPerShare[i])
                    .div(precise);
                if (current <= user.rewardDebt[i]) {
                    continue;
                }
                uint256 pending = current.sub(user.rewardDebt[i]);
                if (pending > 0) {
                    if (address(pool.rewardTokens[i]) == address(0)) {
                        //Reward: ETH
                        rewardVault.withdrawEth(pending);
                        require(
                            payable(msg.sender).send(pending),
                            "BasePools: send eth false"
                        );
                    } else {
                        rewardVault.withdrawToken(
                            pool.rewardTokens[i],
                            pending
                        );
                        pool.rewardTokens[i].safeTransfer(msg.sender, pending);
                    }
                }
        }
    }

    function checkPoolToken(
        uint256 pid,
        IERC20 token
    ) public view returns (bool) {
        uint256 depositTokenLength = poolInfo[pid].depositTokens.length;
        for (uint i; i < depositTokenLength; i++) {
            if (poolInfo[pid].depositTokens[i] == token) {
                return true;
            }
        }
        return false;
    }

    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) public pure returns (uint256) {
        return _to.sub(_from);
    }

    function _addBuff(address user, uint256 newBuff, uint256 buffNum) internal {
        require(buffNum == 0 || buffNum == 1, "BasePools: Wrong Buff Num");
        //judger user buff
        for (uint i; i < poolInfo.length; i++) {
            UserInfo storage ui = userInfo[i][user];
            uint256 userBuffBefore = ui.buff1 + ui.buff2;
            if (buffNum == 0) {
                if (ui.buff1.add(newBuff) < buffPerNFT.mul(2)) {
                    ui.buff1 = ui.buff1.add(newBuff);
                } else {
                    ui.buff1 = buffPerNFT.mul(2);
                }
            } else {
                if (ui.buff2.add(newBuff) < pfpBuffPerNFT.mul(2)) {
                    ui.buff2 = ui.buff2.add(newBuff);
                } else {
                    ui.buff2 = pfpBuffPerNFT.mul(2);
                }
            }
            //judge update
            if (userBuffBefore != (ui.buff1 + ui.buff2) && ui.totalAmount > 0) {
                deposit(i, poolInfo[i].depositTokens[0], 0);
                uint256 weightBefore = ui.weight;
                ui.weight = ui
                    .totalAmount
                    .mul(ui.buff1 + ui.buff2 + BasePoint)
                    .div(BasePoint);
                poolInfo[i].totalWeight = poolInfo[i]
                    .totalWeight
                    .sub(weightBefore)
                    .add(ui.weight);
                updateRewardDebt(poolInfo[i], ui);
            }
        }
    }

    function _updateBuff(
        address user,
        uint256 leftBuff,
        uint256 buffNum
    ) internal {
        require(buffNum == 0 || buffNum == 1, "BasePools:Wrong Buff Num");
        if ((buffNum == 0) && (leftBuff >= buffPerNFT.mul(2))) {
            return;
        }
        if ((buffNum == 1) && (leftBuff >= pfpBuffPerNFT.mul(2))) {
            return;
        }
        for (uint i; i < poolInfo.length; i++) {
            UserInfo storage ui = userInfo[i][user];
            uint256 userBuffBefore = ui.buff1 + ui.buff2;
            if (buffNum == 0) {
                ui.buff1 = leftBuff;
            } else {
                ui.buff2 = leftBuff;
            }

            //judge update
            if (userBuffBefore != (ui.buff1 + ui.buff2) && ui.totalAmount > 0) {
                deposit(i, poolInfo[i].depositTokens[0], 0);
                uint256 weightBefore = ui.weight;
                ui.weight = ui
                    .totalAmount
                    .mul(ui.buff1 + ui.buff2 + BasePoint)
                    .div(BasePoint);
                poolInfo[i].totalWeight = poolInfo[i]
                    .totalWeight
                    .sub(weightBefore)
                    .add(ui.weight);
                updateRewardDebt(poolInfo[i], ui);
            }
        }
    }

    function getPoolInfo(
        uint256 pid
    )
        public
        view
        returns (
            uint256 startTime,
            IERC20[] memory depositTokens,
            IERC20[] memory rewardTokens,
            uint256[] memory rewardTokenPerSecond,
            uint256 lastRewardTime,
            uint256[] memory accRewardTokenPerShare,
            uint256[] memory staked,
            uint256 totalStaked,
            uint256 totalWeight
        )
    {
        require(pid < poolInfo.length, "BasePools: invalid params");
        startTime = poolInfo[pid].startTime;
        depositTokens = poolInfo[pid].depositTokens;
        rewardTokens = poolInfo[pid].rewardTokens;
        rewardTokenPerSecond = poolInfo[pid].rewardTokenPerSecond;
        lastRewardTime = poolInfo[pid].lastRewardTime;
        accRewardTokenPerShare = poolInfo[pid].accRewardTokenPerShare;
        staked = poolInfo[pid].staked; //total staked per token
        totalStaked = poolInfo[pid].totalStaked; //sum deposit token's staked amount
        totalWeight = poolInfo[pid].totalWeight;
    }

    function getUserInfo(
        uint256 pid,
        address user
    )
        public
        view
        returns (
            uint256 totalAmount,
            uint256[] memory amount,
            uint256[] memory rewardDebt,
            uint256 buff1,
            uint256 buff2,
            uint256 weight
        )
    {
        totalAmount = userInfo[pid][user].totalAmount;
        amount = userInfo[pid][user].amount;
        rewardDebt = userInfo[pid][user].rewardDebt;
        buff1 = userInfo[pid][user].buff1;
        buff2 = userInfo[pid][user].buff2;
        weight = userInfo[pid][user].weight;
    }

    function getTotalStakedLP() public view returns (uint256) {
        if (poolInfo.length > 1) {
            return poolInfo[1].totalStaked;
        } else {
            return 0;
        }
    }

    function setLionDEXRewardVault(
        ILionDEXRewardVault _rewardVault
    ) public onlyOwner {
        rewardVault = _rewardVault;
    }

    function setRewardKeeper(address addr, bool active) public onlyOwner {
        rewardKeeperMap[addr] = active;
        emit SetRewardKeeper(msg.sender,addr,active);
    }
    function isRewardKeeper(address addr) public view returns (bool) {
        return rewardKeeperMap[addr];
    }
}

contract FlexiblePools is BasePools {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    IERC20 public LionToken;
    IERC20 public esLionToken;

    ILionDexNFT public lionDexNFT;
    ILionDexNFT public lionPFPNFT;
    IFeeLP public feeLP;
    //feeLP amount per card
    uint256 public feeLPAmountPerNFT = 1500e18;
    //lionDexNFT tokenId=>owner's address
    mapping(uint256 => address) public tokenOfOwner;
    //lionPFPNFT tokenId=>owner's address
    mapping(uint256 => address) public pfpNFTOfOwner;
    //user=>lionDexNFT tokenId set
    mapping(address => EnumerableSet.UintSet) private ownerTokens;
    mapping(address => EnumerableSet.UintSet) private ownerPFPTokens;

    //for release lion,50000 lion per genesis NFT
    uint256 public lionTokenAmountPerNFT = 50000e18;
    uint256 public duration = 180 days;
    struct LionTokenClaim {
        uint256 depositTime;
        uint256 claimed;
    }
    //token id=>lion token claim info
    mapping(uint256 => LionTokenClaim) private lionTokenClaimInfo;

    event DepositNFT(address user, uint256[] tokenIds, uint256 amount);
    event DepositPFPNFT(address user, uint256[] tokenIds);
    event WithdrawNFT(
        address user,
        uint256[] tokenIds,
        uint256 needReturnFeeLP,
        uint256 needReturnLionToken
    );
    event WithdrawPFPNFT(address user, uint256[] tokenIds);
    event ClaimLion(address user, uint256 amount);

    function initialize(
        IERC20 _LionToken,
        IERC20 _esLionToken,
        ILionDEXRewardVault _rewardVault,
        ILionDexNFT _lionDexNFT,
        ILionDexNFT _lionPFPNFT,
        IFeeLP _feeLP
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        init(_rewardVault);

        lionDexNFT = _lionDexNFT;
        lionPFPNFT = _lionPFPNFT;
        feeLP = _feeLP;
        LionToken = _LionToken;
        esLionToken = _esLionToken;
        feeLPAmountPerNFT = 1500e18;
        lionTokenAmountPerNFT = 50000e18;
        duration = 180 days;
    }

    function depositNFT(uint256[] memory tokenIds) public {
        require(tokenIds.length > 0, "FlexiblePools: length invalid");

        for (uint i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            LionTokenClaim storage info = lionTokenClaimInfo[tokenId];
            require(info.depositTime == 0, "FlexiblePools: deposited");
            require(
                lionDexNFT.ownerOf(tokenId) == msg.sender,
                "FlexiblePools: owner invalid"
            );
            require(
                lionDexNFT.getApproved(tokenId) == address(this) ||
                    lionDexNFT.isApprovedForAll(msg.sender, address(this)),
                "FlexiblePools: approved invalid"
            );
            require(
                !ownerTokens[msg.sender].contains(tokenId),
                "FlexiblePools: tokenId invalid"
            );
            lionDexNFT.safeTransferFrom(msg.sender, address(this), tokenId);
            tokenOfOwner[tokenId] = msg.sender;
            ownerTokens[msg.sender].add(tokenId);
            info.depositTime = block.timestamp;
        }

        uint256 needMint = feeLPAmountPerNFT.mul(tokenIds.length);
        feeLP.mintTo(msg.sender, needMint);

        //add buff
        uint256 newBuff = buffPerNFT.mul(tokenIds.length);
        _addBuff(msg.sender, newBuff, 0);

        emit DepositNFT(msg.sender, tokenIds, needMint);
    }

    function depositPFPNFT(uint256[] memory tokenIds) public {
        require(
            ownerPFPTokens[msg.sender].length() + tokenIds.length < 3,
            "FlexiblePools: length invalid"
        );

        for (uint i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                lionPFPNFT.ownerOf(tokenId) == msg.sender,
                "FlexiblePools: owner invalid"
            );
            require(
                lionPFPNFT.getApproved(tokenId) == address(this) ||
                    lionPFPNFT.isApprovedForAll(msg.sender, address(this)),
                "FlexiblePools: approved invalid"
            );
            require(
                !ownerPFPTokens[msg.sender].contains(tokenId),
                "FlexiblePools: tokenId invalid"
            );
            lionPFPNFT.safeTransferFrom(msg.sender, address(this), tokenId);
            pfpNFTOfOwner[tokenId] = msg.sender;
            ownerPFPTokens[msg.sender].add(tokenId);
        }

        //add buff
        uint256 newBuff = pfpBuffPerNFT.mul(tokenIds.length);
        _addBuff(msg.sender, newBuff, 1);

        emit DepositPFPNFT(msg.sender, tokenIds);
    }

    function withdrawNFT(uint256[] memory tokenIds) public {
        require(tokenIds.length > 0, "FlexiblePools: length invalid");
        uint256 needReturnLionToken;
        for (uint i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                tokenOfOwner[tokenId] == msg.sender,
                "FlexiblePools: owner invalid"
            );
            require(
                ownerTokens[msg.sender].contains(tokenId),
                "FlexiblePools: tokenId invalid"
            );
            lionDexNFT.safeTransferFrom(address(this), msg.sender, tokenId);
            ownerTokens[msg.sender].remove(tokenId);
            delete tokenOfOwner[tokenId];

            //for lion token,only return claimed
            needReturnLionToken = needReturnLionToken.add(
                lionTokenClaimInfo[tokenId].claimed
            );
            delete lionTokenClaimInfo[tokenId];
        }

        //for feeLP
        uint256 needReturnFeeLP = feeLPAmountPerNFT.mul(tokenIds.length);
        require(
            feeLP.balanceOf(msg.sender) >= needReturnFeeLP,
            "FlexiblePools: feeLP balance invalid"
        );
        feeLP.burn(msg.sender, needReturnFeeLP);

        //for lionToken
        if (needReturnLionToken > 0) {
            require(
                LionToken.balanceOf(msg.sender) >= needReturnLionToken,
                "FlexiblePools: lion balance invalid"
            );
            require(
                LionToken.allowance(msg.sender, address(this)) >=
                    needReturnLionToken,
                "FlexiblePools: lion approved invalid"
            );

            LionToken.safeTransferFrom(
                msg.sender,
                address(rewardVault),
                needReturnLionToken
            );
        }

        //set to left buff
        uint256 leftBuff = buffPerNFT.mul(ownerTokens[msg.sender].length());
        _updateBuff(msg.sender, leftBuff, 0);

        emit WithdrawNFT(
            msg.sender,
            tokenIds,
            needReturnFeeLP,
            needReturnLionToken
        );
    }

    function withdrawPFPNFT(uint256[] memory tokenIds) public {
        require(tokenIds.length > 0, "FlexiblePools: length invalid");
        for (uint i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                pfpNFTOfOwner[tokenId] == msg.sender,
                "FlexiblePools: owner invalid"
            );
            require(
                ownerPFPTokens[msg.sender].contains(tokenId),
                "FlexiblePools: tokenId invalid"
            );
            lionPFPNFT.safeTransferFrom(address(this), msg.sender, tokenId);
            ownerPFPTokens[msg.sender].remove(tokenId);
            delete pfpNFTOfOwner[tokenId];
        }

        //set to left buff
        uint256 leftBuff = pfpBuffPerNFT.mul(
            ownerPFPTokens[msg.sender].length()
        );
        _updateBuff(msg.sender, leftBuff, 1);

        emit WithdrawPFPNFT(msg.sender, tokenIds);
    }

    function claimLion() public {
        uint256 len = ownerTokens[msg.sender].length();
        uint256 total;
        for (uint i; i < len; i++) {
            uint256 tokenId = ownerTokens[msg.sender].at(i);
            LionTokenClaim storage info = lionTokenClaimInfo[tokenId];
            (uint256 canClaim, ) = getCanClaim(tokenId);
            info.claimed = info.claimed.add(canClaim);
            total = total.add(canClaim);
        }
        if (total > 0) {
            rewardVault.withdrawToken(LionToken, total);
            LionToken.transfer(msg.sender, total);
        }

        emit ClaimLion(msg.sender, total);
    }

    function claimLionIndex(uint256 fromIndex, uint256 toIndex) public {
        require(fromIndex < toIndex, "FlexiblePools: params invalid");

        uint256 len = ownerTokens[msg.sender].length();
        if (toIndex > len) {
            toIndex = len;
        }
        uint256 total;
        for (uint i = fromIndex; i < toIndex; i++) {
            uint256 tokenId = ownerTokens[msg.sender].at(i);
            LionTokenClaim storage info = lionTokenClaimInfo[tokenId];
            (uint256 canClaim, ) = getCanClaim(tokenId);
            info.claimed = info.claimed.add(canClaim);
            total = total.add(canClaim);
        }
        if (total > 0) {
            rewardVault.withdrawToken(LionToken, total);
            LionToken.transfer(msg.sender, total);
        }

        emit ClaimLion(msg.sender, total);
    }

    function getNeedReturn(
        address user,
        uint256[] memory tokenIds
    )
        public
        view
        returns (uint256 needReturnLionToken, uint256 needReturnFeeLP)
    {
        for (uint i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                tokenOfOwner[tokenId] == user,
                "FlexiblePools: owner invalid"
            );
            require(
                ownerTokens[user].contains(tokenId),
                "FlexiblePools: tokenId invalid"
            );

            //for lion token,only return claimed
            needReturnLionToken = needReturnLionToken.add(
                lionTokenClaimInfo[tokenId].claimed
            );
        }

        //for feeLP
        needReturnFeeLP = feeLPAmountPerNFT.mul(tokenIds.length);
    }

    function getCanClaim(
        address user
    ) private view returns (uint256 canClaim, uint256 claimed) {
        uint256 len = ownerTokens[user].length();
        for (uint i; i < len; i++) {
            uint256 tokenId = ownerTokens[user].at(i);
            (uint256 canClaimIn, uint256 claimedIn) = getCanClaim(tokenId);
            canClaim = canClaim.add(canClaimIn);
            claimed = claimed.add(claimedIn);
        }
    }

    function getCanClaim(
        uint256 tokenId
    ) private view returns (uint256, uint256) {
        LionTokenClaim memory info = lionTokenClaimInfo[tokenId];
        uint256 start = info.depositTime;
        uint256 claimed = info.claimed;
        if (block.timestamp <= start) {
            return (0, claimed);
        } else if (block.timestamp >= start.add(duration)) {
            return (lionTokenAmountPerNFT.sub(claimed), claimed);
        } else {
            return (
                lionTokenAmountPerNFT
                    .mul(block.timestamp.sub(start))
                    .div(duration)
                    .sub(claimed),
                claimed
            );
        }
    }

    function getOwnerTokens(
        address user
    ) external view returns (uint256[] memory ret) {
        ret = new uint256[](ownerTokens[user].length());
        for (uint i = 0; i < ownerTokens[user].length(); i++) {
            ret[i] = ownerTokens[user].at(i);
        }
    }

    function getOwnerFeeLP(address user) external view returns (uint256 ret) {
        ret = ownerTokens[user].length().mul(feeLPAmountPerNFT);
    }

    function getOwnerPFPTokens(
        address user
    ) external view returns (uint256[] memory ret) {
        ret = new uint256[](ownerPFPTokens[user].length());
        for (uint i = 0; i < ownerPFPTokens[user].length(); i++) {
            ret[i] = ownerPFPTokens[user].at(i);
        }
    }

    //user's lion token claim info
    function getUserClaimLionInfo(
        address user
    ) external view returns (uint256 total, uint256 canClaim, uint256 claimed) {
        uint256 len = ownerTokens[user].length();
        total = len.mul(lionTokenAmountPerNFT);
        (canClaim, claimed) = getCanClaim(user);
    }

    function getUserApr(
        uint256 pid,
        uint256 LPPrice,
        uint256 esLionPrice,
        uint256 ethPrice,
        address user
    ) public view returns (uint256[3] memory ret) {
        require(pid < 2, "BasePools: pid invalid");
        require(
            LPPrice > 0 && esLionPrice > 0 && ethPrice > 0,
            "BasePools: price invalid"
        );
        // (rewardTokenPerSecond*second per year *reward token usd price)*(1+((Genesis Amount*0.05)+(PFP Amount*0.02))) / (total staked token+buff) usd value
        uint256 genesisAmount = ownerTokens[user].length();
        genesisAmount = genesisAmount > 2 ? 2 : genesisAmount;
        uint256 pfpAmount = ownerPFPTokens[user].length();
        pfpAmount = pfpAmount > 2 ? 2 : pfpAmount;

        PoolInfo memory pool = poolInfo[pid];
        uint256 totalWeight = pool.totalWeight;
        if (totalWeight == 0) {
            return ret;
        }
        uint256 multi = (BasePoint +
            genesisAmount *
            buffPerNFT +
            pfpAmount *
            pfpBuffPerNFT);

        if (pid == 0) {
            //LP
            ret[0] =
                (pool.rewardTokenPerSecond[0] * 365 days * LPPrice * multi) /(totalWeight*esLionPrice * BasePoint * 1e4);
            //esLion
            ret[1] =
                (pool.rewardTokenPerSecond[1] *  365 days * 1e8 * multi) /(totalWeight * BasePoint);
        } else {
            //eth
            ret[0] =
                ((pool.rewardTokenPerSecond[0] * 365 days * ethPrice * 1e12) *
                    1e8 *
                    multi) /
                totalWeight /
                LPPrice /
                BasePoint;
            //LP
            ret[1] =
                ((pool.rewardTokenPerSecond[1] * 365 days) * 1e8 * multi) /
                totalWeight /
                BasePoint;
            //esLion
            ret[2] =
                ((pool.rewardTokenPerSecond[2] *
                    365 days *
                    esLionPrice *
                    1e12) *
                    1e8 *
                    multi) /
                totalWeight /
                LPPrice /
                BasePoint;
        }
    }

    function setDuration(uint256 _duration) external onlyOwner {
        duration = _duration;
    }

    function setPFPNFT(
        ILionDexNFT _lionPFPNFT
    ) external onlyOwner {
        lionPFPNFT = _lionPFPNFT;
    }

    function setFeeLPAmountPerNFT(
        uint256 _feeLPAmountPerNFT
    ) external onlyOwner {
        feeLPAmountPerNFT = _feeLPAmountPerNFT;
    }

    function setLionTokenAmountPerNFT(
        uint256 _lionTokenAmountPerNFT
    ) external onlyOwner {
        lionTokenAmountPerNFT = _lionTokenAmountPerNFT;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}