// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

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
pragma solidity 0.8.17;

interface GNSStakingInterfaceV6_4_1 {
    // Structs
    struct Staker {
        uint128 stakedGns; // 1e18
        uint128 debtDai; // 1e18
    }

    struct UnlockSchedule {
        uint128 totalGns; // 1e18
        uint128 claimedGns; // 1e18
        uint128 debtDai; // 1e18
        uint48 start; // block.timestamp (seconds)
        uint48 duration; // in seconds
        bool revocable;
        UnlockType unlockType;
        uint16 __placeholder;
    }

    struct UnlockScheduleInput {
        uint128 totalGns; // 1e18
        uint48 start; // block.timestamp (seconds)
        uint48 duration; // in seconds
        bool revocable;
        UnlockType unlockType;
    }

    enum UnlockType {
        LINEAR,
        CLIFF
    }

    function owner() external view returns (address);

    function distributeRewardDai(uint _amountDai) external;

    function createUnlockSchedule(UnlockScheduleInput calldata _schedule, address _staker) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface TokenInterfaceV5 {
    function burn(address, uint256) external;

    function mint(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function hasRole(bytes32, address) external view returns (bool);

    function approve(address, uint256) external returns (bool);

    function allowance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "../interfaces/GNSStakingInterfaceV6_4_1.sol";
import "../interfaces/TokenInterfaceV5.sol";

contract GNSStakingV6_4_1 is Initializable, Ownable2StepUpgradeable, GNSStakingInterfaceV6_4_1 {
    // Constants
    uint48 private constant MAX_UNLOCK_DURATION = 730 days; // 2 years in seconds
    uint128 private constant MIN_UNLOCK_GNS_AMOUNT = 1e18;

    // Contracts & Addresses
    TokenInterfaceV5 public gns; // GNS
    TokenInterfaceV5 public dai;

    // Pool state
    uint128 public accDaiPerToken;
    uint128 public gnsBalance;

    // Mappings
    mapping(address => Staker) public stakers;
    mapping(address => UnlockSchedule[]) private unlockSchedules;
    mapping(address => bool) public unlockManagers; // addresses allowed to create unlock schedules for others

    // Events
    event UnlockManagerUpdated(address indexed manager, bool authorized);

    event DaiDistributed(uint amountDai);
    event DaiHarvested(address indexed staker, uint128 amountDai);
    event DaiHarvestedFromUnlock(address indexed staker, uint[] ids, uint128 amountDai);

    event GnsStaked(address indexed staker, uint128 amountGns);
    event GnsUnstaked(address indexed staker, uint128 amountGns);
    event GnsClaimed(address indexed staker, uint[] ids, uint128 amountGns);

    event UnlockScheduled(address indexed staker, uint indexed index, UnlockSchedule schedule);
    event UnlockScheduleRevoked(address indexed staker, uint indexed index);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, TokenInterfaceV5 _gns, TokenInterfaceV5 _dai) external initializer {
        require(
            address(_owner) != address(0) && address(_gns) != address(0) && address(_dai) != address(0),
            "WRONG_PARAMS"
        );

        _transferOwnership(_owner);
        gns = _gns;
        dai = _dai;
    }

    //
    // Modifiers
    //

    modifier onlyAuthorizedUnlockManager(address _staker, bool _revocable) {
        require(
            (_staker == msg.sender && !_revocable) || msg.sender == owner() || unlockManagers[msg.sender],
            "NO_AUTH"
        );
        _;
    }

    //
    // Management functions
    //

    function setUnlockManager(address _manager, bool _authorized) external onlyOwner {
        unlockManagers[_manager] = _authorized;

        emit UnlockManagerUpdated(_manager, _authorized);
    }

    //
    // Internal view functions
    //

    function _currentDebtDai(uint128 _staked) private view returns (uint128) {
        return uint128((uint(_staked) * accDaiPerToken) / 1e18);
    }

    function _pendingDai(uint128 _staked, uint128 _debtDai) private view returns (uint128) {
        return _currentDebtDai(_staked) - _debtDai;
    }

    function _pendingDai(UnlockSchedule memory _schedule) private view returns (uint128) {
        return _currentDebtDai(_schedule.totalGns - _schedule.claimedGns) - _schedule.debtDai;
    }

    //
    // Public view functions
    //

    function unlockedGns(UnlockSchedule memory _schedule, uint48 _timestamp) public pure returns (uint128) {
        // if unlock schedule has ended return totalGns
        if (_timestamp >= _schedule.start + _schedule.duration) return _schedule.totalGns;

        // if unlock hasn't started or it's a cliff unlock return 0
        if (_timestamp < _schedule.start || _schedule.unlockType == UnlockType.CLIFF) return 0;

        return uint128((uint(_schedule.totalGns) * (_timestamp - _schedule.start)) / _schedule.duration);
    }

    function releasableGns(UnlockSchedule memory _schedule, uint48 _timestamp) public pure returns (uint128) {
        return unlockedGns(_schedule, _timestamp) - _schedule.claimedGns;
    }

    function owner() public view override(GNSStakingInterfaceV6_4_1, OwnableUpgradeable) returns (address) {
        return super.owner();
    }

    //
    // Internal state-modifying functions
    //

    function _harvestDaiFromUnlock(address _staker, uint[] memory _ids) private {
        require(_staker != address(0), "USER_EMPTY");
        require(_ids.length > 0, "IDS_EMPTY");

        uint128 pendingDai;

        for (uint i; i < _ids.length; ) {
            UnlockSchedule storage schedule = unlockSchedules[_staker][_ids[i]];

            uint128 newDebtDai = _currentDebtDai(schedule.totalGns - schedule.claimedGns);
            uint128 newRewardsDai = newDebtDai - schedule.debtDai;

            pendingDai += newRewardsDai;
            schedule.debtDai = newDebtDai;

            unchecked {
                ++i;
            }
        }

        dai.transfer(_staker, uint(pendingDai));

        emit DaiHarvestedFromUnlock(_staker, _ids, pendingDai);
    }

    function _claimUnlockedGns(address _staker, uint48 _timestamp, uint[] memory _ids) private {
        uint128 claimedGns;

        _harvestDaiFromUnlock(_staker, _ids);

        for (uint i; i < _ids.length; ) {
            UnlockSchedule storage schedule = unlockSchedules[_staker][_ids[i]];
            uint128 amountGns = releasableGns(schedule, _timestamp);

            schedule.claimedGns += amountGns;
            assert(schedule.claimedGns <= schedule.totalGns);
            schedule.debtDai = _currentDebtDai(schedule.totalGns - schedule.claimedGns);

            claimedGns += amountGns;

            unchecked {
                ++i;
            }
        }

        gnsBalance -= claimedGns;
        gns.transfer(_staker, uint(claimedGns));

        emit GnsClaimed(_staker, _ids, claimedGns);
    }

    //
    // Public/External interaction functions
    //

    function distributeRewardDai(uint _amountDai) external override {
        require(gnsBalance > 0, "NO_GNS_STAKED");

        dai.transferFrom(msg.sender, address(this), _amountDai);
        accDaiPerToken += uint128((_amountDai * 1e18) / gnsBalance);

        emit DaiDistributed(_amountDai);
    }

    function harvestDai() public {
        Staker storage staker = stakers[msg.sender];

        uint128 newDebtDai = _currentDebtDai(staker.stakedGns);
        uint128 pendingDai = newDebtDai - staker.debtDai;

        staker.debtDai = newDebtDai;
        dai.transfer(msg.sender, uint(pendingDai));

        emit DaiHarvested(msg.sender, pendingDai);
    }

    function harvestDaiFromUnlock(uint[] calldata _ids) external {
        _harvestDaiFromUnlock(msg.sender, _ids);
    }

    function harvestDaiAll(uint[] calldata _ids) external {
        harvestDai();
        _harvestDaiFromUnlock(msg.sender, _ids);
    }

    function stakeGns(uint128 _amountGns) external {
        require(_amountGns > 0, "AMOUNT_ZERO");

        gns.transferFrom(msg.sender, address(this), uint(_amountGns));

        harvestDai();

        Staker storage staker = stakers[msg.sender];
        staker.stakedGns += _amountGns;
        staker.debtDai = _currentDebtDai(staker.stakedGns);

        gnsBalance += _amountGns;

        emit GnsStaked(msg.sender, _amountGns);
    }

    function unstakeGns(uint128 _amountGns) external {
        require(_amountGns > 0, "AMOUNT_ZERO");

        harvestDai();

        Staker storage staker = stakers[msg.sender];
        staker.stakedGns -= _amountGns;
        staker.debtDai = _currentDebtDai(staker.stakedGns);

        gnsBalance -= _amountGns;

        gns.transfer(msg.sender, uint(_amountGns));

        emit GnsUnstaked(msg.sender, _amountGns);
    }

    function claimUnlockedGns(uint[] memory _ids) external {
        _claimUnlockedGns(msg.sender, uint48(block.timestamp), _ids);
    }

    function createUnlockSchedule(
        UnlockScheduleInput calldata _schedule,
        address _staker
    ) external override onlyAuthorizedUnlockManager(_staker, _schedule.revocable) {
        uint48 timestamp = uint48(block.timestamp);

        require(_schedule.start < timestamp + MAX_UNLOCK_DURATION, "TOO_FAR_IN_FUTURE");
        require(_schedule.duration > 0 && _schedule.duration <= MAX_UNLOCK_DURATION, "INCORRECT_DURATION");
        require(_schedule.totalGns >= MIN_UNLOCK_GNS_AMOUNT, "INCORRECT_AMOUNT");
        require(_staker != address(0), "ADDRESS_0");

        uint128 totalGns = _schedule.totalGns;

        // Requester has to pay the gns amount
        gns.transferFrom(msg.sender, address(this), uint(totalGns));

        UnlockSchedule memory schedule = UnlockSchedule({
            totalGns: totalGns,
            claimedGns: 0,
            debtDai: _currentDebtDai(totalGns),
            start: _schedule.start >= timestamp ? _schedule.start : timestamp, // accept time in the future
            duration: _schedule.duration,
            unlockType: _schedule.unlockType,
            revocable: _schedule.revocable,
            __placeholder: 0
        });

        unlockSchedules[_staker].push(schedule);
        gnsBalance += totalGns;

        emit UnlockScheduled(_staker, unlockSchedules[_staker].length - 1, schedule);
    }

    function revokeUnlockSchedule(address _staker, uint _id) external onlyOwner {
        UnlockSchedule storage schedule = unlockSchedules[_staker][_id];
        require(schedule.revocable, "NOT_REVOCABLE");

        uint[] memory ids = new uint[](1);
        ids[0] = _id;

        // claims unlocked gns and harvests pending rewards
        _claimUnlockedGns(_staker, uint48(block.timestamp), ids);

        uint128 lockedAmountGns = schedule.totalGns - schedule.claimedGns;

        // resets unlockSchedule so no more claims or harvests are possible
        schedule.totalGns = schedule.claimedGns;
        schedule.duration = 0;
        schedule.start = 0;
        schedule.debtDai = 0;

        gnsBalance -= lockedAmountGns;

        gns.transfer(owner(), uint(lockedAmountGns));

        emit UnlockScheduleRevoked(_staker, _id);
    }

    //
    // External view functions
    //

    function pendingRewardDai(address _staker) external view returns (uint128) {
        Staker memory staker = stakers[_staker];

        return _pendingDai(staker.stakedGns, staker.debtDai);
    }

    function pendingRewardDaiFromUnlocks(address _staker) external view returns (uint128 pending) {
        UnlockSchedule[] memory stakerUnlocks = unlockSchedules[_staker];

        for (uint i; i < stakerUnlocks.length; ) {
            pending += _pendingDai(stakerUnlocks[i]);

            unchecked {
                ++i;
            }
        }
    }

    function pendingRewardDaiFromUnlocks(
        address _staker,
        uint[] calldata _ids
    ) external view returns (uint128 pending) {
        for (uint i; i < _ids.length; ) {
            pending += _pendingDai(unlockSchedules[_staker][_ids[i]]);

            unchecked {
                ++i;
            }
        }
    }

    function totalGnsStaked(address _staker) external view returns (uint128) {
        uint128 totalGns = stakers[_staker].stakedGns;
        UnlockSchedule[] memory stakerUnlocks = unlockSchedules[_staker];

        for (uint i; i < stakerUnlocks.length; ) {
            UnlockSchedule memory schedule = stakerUnlocks[i];
            totalGns += schedule.totalGns - schedule.claimedGns;

            unchecked {
                ++i;
            }
        }

        return totalGns;
    }

    function getUnlockSchedules(address _staker) external view returns (UnlockSchedule[] memory) {
        return unlockSchedules[_staker];
    }

    function getUnlockSchedules(address _staker, uint _index) external view returns (UnlockSchedule memory) {
        return unlockSchedules[_staker][_index];
    }
}