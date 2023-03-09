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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
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
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Unauthorized();
error BadRequest();
error BadAddress();
error BadPayment();
error RecipientNotFound();
error OverAttributed();
error IncorrectAmount();
error ImproperCampaignState();
error PaymentTypeDoesNotExist();

/// @title PayoutVault
/// @author spindl.xyz
/// @notice This is implementation contract for proxies that is used to update campaign funds & proivde ability to fund/withdraw for campaign managers and recipients
contract PayoutVault is Initializable, OwnableUpgradeable {
    address public managerAddress;
    address public workerAddress;
    mapping(address => bool) public paymentTypes;
    mapping(uint32 => Campaign) public campaigns;

    /// @notice we use this for ids & increment. Can also be tracked total # of campaigns / recipients created
    uint32 public campaignCounter;

    struct Campaign {
        uint256 totalBudget;
        CampaignStatus status;
        address paymentType;
        uint256 totalEarned;
        mapping(address => RecipientDetails) recipients;
    }

    enum CampaignStatus {
        NONE,
        CREATED,
        ACTIVE,
        PAUSED,
        COMPLETED
    }

    struct RecipientDetails {
        RecipientStatus status;
        uint256 earned;
        uint256 withdrawn;
    }

    struct RecipientUpdates {
        address addr;
        uint256 earned;
    }

    /// @dev this struct is used to update both campaigns and recipients
    struct UpdateDetails {
        uint32 campaignId;
        RecipientUpdates[] recipients;
    }

    enum RecipientStatus {
        NONE,
        ACTIVE,
        PAUSED
    }

    enum RecipientWithdrawType {
        PUSH,
        PULL
    }

    /// @notice used to initialize contract in place of constructor for security reasons
    function initialize(
        address _owner,
        address _managerAddress,
        address _workerAddress,
        address[] calldata _paymentTypes
    ) public initializer {
        __Ownable_init();

        /// @dev transfering ownership to multisig owner upon init
        _transferOwnership(_owner);

        /// @dev add initial data
        managerAddress = _managerAddress;
        workerAddress = _workerAddress;

        /// @dev this will be used for native currency such as Eth or Matic
        paymentTypes[address(0)] = true;

        /// @dev we don't expect to have more than 5-10 payment options
        for (uint16 i; i < _paymentTypes.length; i++) {
            paymentTypes[_paymentTypes[i]] = true;
        }
    }

    /// @notice Events
    event ManagerAddressUpdated(address indexed oldAddress, address newAddress);
    event WorkerAddressUpdated(address indexed oldAddress, address newAddress);
    event CampaignCreated(uint32 indexed id, address paymentType);
    event RecipientsAdded(uint32 indexed campaignId, address[] addr);
    event RecipientStatusUpdated(uint32 indexed campaignId, address indexed addr, RecipientStatus status);
    event CampaignFunded(uint32 indexed campaignId, uint256 updatedBudget);
    event UpdateCompleted(
        uint32 indexed campaignId,
        address indexed recipientAddress,
        address paymentType,
        uint256 newEarnings
    );
    event CampaignStatusUpdated(uint32 indexed campaignId, CampaignStatus oldState, CampaignStatus newState);
    event WithdrawSuccess(
        uint32 indexed campaignId,
        address indexed recipientAddress,
        address paymentType,
        uint256 amount,
        RecipientWithdrawType withdrawType
    );
    event PaymentAdded(address addr);
    event BalanceWithdrawn(uint32 campaignId, uint256 withdrawAmount, uint256 newTotalBalance);

    /// @notice Modifiers

    modifier onlyOwnerAndWorker() {
        if (msg.sender != owner() && msg.sender != workerAddress) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyInProgressCampaigns(uint32 _campaignId) {
        CampaignStatus campaignStatus = campaigns[_campaignId].status;
        if (campaignStatus == CampaignStatus.ACTIVE || campaignStatus == CampaignStatus.CREATED) {
            _;
        } else {
            revert ImproperCampaignState();
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice in case worker address needs to be updated
    /// @param _newAddress new worker address
    function setWorkerAddress(address _newAddress) external virtual onlyOwner {
        if (_newAddress == workerAddress) {
            revert BadAddress();
        }
        /// @dev allowing owner to set address(0) in case we want to not allow any worker address to update
        emit WorkerAddressUpdated(workerAddress, _newAddress);
        workerAddress = _newAddress;
    }

    /// @notice in case manager address needs to be updated
    /// @param _newAddress new manager address
    function setManagerAddress(address _newAddress) external virtual onlyOwner {
        if (_newAddress == address(0) || _newAddress == managerAddress) {
            revert BadAddress();
        }
        emit ManagerAddressUpdated(managerAddress, _newAddress);

        managerAddress = _newAddress;
    }

    /// @notice create campaign
    /// @param _paymentType payment type for campaign
    /// @param _recipientAddresses array of recipient addresses
    function createCampaign(
        address _paymentType,
        address[] memory _recipientAddresses
    ) external virtual onlyOwnerAndWorker {
        if (!paymentTypes[_paymentType]) {
            revert PaymentTypeDoesNotExist();
        }

        /// @dev using campaignCounter to increment & create campaignId
        uint32 campaignId = campaignCounter + 1;

        /// @dev address(0) is used for native currency such as Eth or Matic
        campaigns[campaignId].paymentType = _paymentType;

        /// @dev default values
        campaigns[campaignId].status = CampaignStatus.CREATED;

        campaignCounter = campaignId;

        emit CampaignCreated(campaignId, _paymentType);

        /// @dev add recipients
        if (_recipientAddresses.length > 0) {
            addRecipients(campaignId, _recipientAddresses);
        }
    }

    /// @notice fund campaign with either erc20 or native currency. if native, we will receive via `msg.value`. if erc20, we use `_amount`
    /// @param _campaignId campaign id
    /// @param _amount amount of erc20 token to fund campaign with
    function fundCampaign(
        uint32 _campaignId,
        uint256 _amount
    ) external payable virtual onlyInProgressCampaigns(_campaignId) {
        if (msg.sender != managerAddress && msg.sender != owner()) {
            revert Unauthorized();
        }

        address paymentType = campaigns[_campaignId].paymentType;
        bool isNativeToken = bool(paymentType == address(0));

        /// @dev address(0) is the native crypto like Eth, Matic, etc.
        if (isNativeToken) {
            // msg.value is the amount of native currency sent with the transaction. should be > 0
            if (msg.value == 0 || _amount > 0) {
                revert BadPayment();
            }

            /// @dev this allows manager to add to budget multiple times
            campaigns[_campaignId].totalBudget += msg.value;
        } else {
            // _amount is the amount of EC20 token sent with the transaction. should be > 0
            if (_amount == 0 || msg.value > 0) {
                revert BadPayment();
            }

            uint256 balanceBefore = IERC20(paymentType).balanceOf(address(this));
            bool success = IERC20(paymentType).transferFrom(msg.sender, address(this), _amount);
            require(success, "ERC20_TRANSFER_FAILED");
            uint256 balanceAfter = IERC20(paymentType).balanceOf(address(this));

            /// @dev we are calculating totalBudget with before/after balance in case we deal with fee on transfer ERC20 tokens
            campaigns[_campaignId].totalBudget += (balanceAfter - balanceBefore);
        }

        emit CampaignFunded(_campaignId, campaigns[_campaignId].totalBudget);
    }

    /// @notice add recipients to campaign
    /// @param _campaignId campaign id
    /// @param _recipientAddresses array of recipient addresses
    function addRecipients(
        uint32 _campaignId,
        address[] memory _recipientAddresses
    ) public virtual onlyOwnerAndWorker onlyInProgressCampaigns(_campaignId) {
        if (_recipientAddresses.length == 0) {
            revert BadAddress();
        }

        for (uint32 i; i < _recipientAddresses.length; i++) {
            address _address = _recipientAddresses[i];
            RecipientDetails storage recipient = campaigns[_campaignId].recipients[_address];

            if (_address == address(0) || _address == managerAddress || !(recipient.status == RecipientStatus.NONE)) {
                revert BadAddress();
            }
            recipient.status = RecipientStatus.ACTIVE;
        }

        emit RecipientsAdded(_campaignId, _recipientAddresses);
    }

    /// @notice get recipient details
    /// @param _campaignId campaign id
    /// @param _recipientAddress recipient address
    /// @return recipient details
    function getRecipient(uint32 _campaignId, address _recipientAddress) public view returns (RecipientDetails memory) {
        RecipientDetails memory recipient = campaigns[_campaignId].recipients[_recipientAddress];
        if (recipient.status == RecipientStatus.NONE) {
            revert RecipientNotFound();
        }
        return recipient;
    }

    /// @notice withdraw recipient available earnings
    /// @param _campaignId campaign id
    /// @param _amount amount to withdraw
    /// @param _to address to send funds to
    function withdrawRecipientEarnings(uint32 _campaignId, uint256 _amount, address _to) external virtual {
        address paymentType = campaigns[_campaignId].paymentType;

        RecipientDetails storage recipient = campaigns[_campaignId].recipients[msg.sender];
        if (!(recipient.status == RecipientStatus.ACTIVE) || _amount == 0) {
            revert BadRequest();
        }

        /// @dev can only withdraw if campaign is active/completed
        if (
            campaigns[_campaignId].status == CampaignStatus.PAUSED ||
            campaigns[_campaignId].status == CampaignStatus.CREATED
        ) {
            revert Unauthorized();
        }

        uint256 recipientAvailableBalance = recipient.earned - recipient.withdrawn;

        /// @dev cannot withdraw more than difference between earned & already withdrawn
        /// @dev also, in `peformUpkeep` we ensure totalEarned cannot exceed totalBalance so we don't have to worry about withdrawing more than total balance in a campaign here
        if (_amount > recipientAvailableBalance) {
            revert IncorrectAmount();
        }
        // update state before sending money
        recipient.withdrawn += _amount;

        /// @dev address(0) is the native crypto like Eth, Matic, etc.
        if (paymentType == address(0)) {
            (bool success, ) = address(_to).call{ value: _amount }("");
            require(success, "TRANSFER_FAILED");

            /// @dev this is for ERC20 payment types
        } else {
            bool success = IERC20(paymentType).transfer(address(_to), _amount);
            require(success, "TRANSFER_FAILED");
        }

        emit WithdrawSuccess(_campaignId, msg.sender, paymentType, _amount, RecipientWithdrawType.PULL);
    }

    /// @notice push withdraw recipient(s) available earnings
    /// @param _campaignId campaign id
    /// @param _recipientAddresses array of recipient addresses
    /// @dev this is for batch push withdraws
    function pushRecipientEarnings(
        uint32 _campaignId,
        address[] memory _recipientAddresses
    ) external virtual onlyOwnerAndWorker {
        /// @dev can only withdraw if campaign is active/completed
        if (
            campaigns[_campaignId].status == CampaignStatus.PAUSED ||
            campaigns[_campaignId].status == CampaignStatus.CREATED
        ) {
            revert Unauthorized();
        }

        address paymentType = campaigns[_campaignId].paymentType;
        for (uint32 i; i < _recipientAddresses.length; i++) {
            address recipientAddress = _recipientAddresses[i];
            RecipientDetails storage recipient = campaigns[_campaignId].recipients[recipientAddress];
            uint256 amount = recipient.earned - recipient.withdrawn;

            /// @dev if amount is 0, don't waste gas trying to transfer funds
            if (amount == 0) {
                continue;
            }

            // update state before sending money
            recipient.withdrawn += amount;

            /// @dev address(0) is the native crypto like Eth, Matic, etc.
            if (paymentType == address(0)) {
                (bool success, ) = address(recipientAddress).call{ value: amount }("");
                require(success, "TRANSFER_FAILED");

                /// @dev this is for ERC20 payment types
            } else {
                bool success = IERC20(paymentType).transfer(address(recipientAddress), amount);
                require(success, "TRANSFER_FAILED");
            }
            emit WithdrawSuccess(_campaignId, recipientAddress, paymentType, amount, RecipientWithdrawType.PUSH);
        }
    }

    /// @notice set recipient status
    /// @param _campaignId campaign id
    /// @param _recipientAddress recipient address
    /// @param _status recipient status
    function setRecipientStatus(
        uint32 _campaignId,
        address _recipientAddress,
        RecipientStatus _status
    ) external virtual onlyOwnerAndWorker {
        RecipientDetails memory recipient = getRecipient(_campaignId, _recipientAddress);
        if (recipient.status == _status || _status == RecipientStatus.NONE) {
            revert BadRequest();
        }

        campaigns[_campaignId].recipients[_recipientAddress].status = _status;
        emit RecipientStatusUpdated(_campaignId, _recipientAddress, _status);
    }

    /// @notice this to update both campaigns and recipients
    /// @param performData encoded data for updating campaigns and recipients
    function updateBalances(bytes calldata performData) external virtual onlyOwnerAndWorker {
        UpdateDetails[] memory updateArray = abi.decode(performData, (UpdateDetails[]));

        /// @dev updates should not have large arrays & should updates should be broken down into smaller chunks if needed
        for (uint32 i = 0; i < updateArray.length; ) {
            UpdateDetails memory updateObj = updateArray[i];

            Campaign storage campaign = campaigns[updateObj.campaignId];

            /// @dev storing as local variable to save gas
            uint256 _campaignTotalEarned = campaign.totalEarned;

            if (campaign.status == CampaignStatus.NONE || campaign.status == CampaignStatus.CREATED) {
                revert ImproperCampaignState();
            }

            RecipientUpdates[] memory recipients = updateObj.recipients;

            for (uint32 k = 0; k < recipients.length; ) {
                RecipientUpdates memory recipientUpdate = recipients[k];
                RecipientDetails storage recipient = campaigns[updateObj.campaignId].recipients[recipientUpdate.addr];

                /// @dev if recipient does not exist, implicitly create it
                if (recipient.status == RecipientStatus.NONE) {
                    recipient.status = RecipientStatus.ACTIVE;
                }

                /// @dev you cannot make earned less than already withdrawn
                if (recipient.withdrawn > recipientUpdate.earned) {
                    revert IncorrectAmount();
                }

                /// @dev we are adding the difference to totalEarned. it should never be negative.
                _campaignTotalEarned = _campaignTotalEarned - recipient.earned + recipientUpdate.earned;

                /// @dev for update recipient
                recipient.earned = recipientUpdate.earned;

                unchecked {
                    k++;
                }

                emit UpdateCompleted(
                    updateObj.campaignId,
                    recipientUpdate.addr,
                    campaign.paymentType,
                    recipient.earned
                );
            }

            /// @dev preventing over-attribution of earnings on the campaign level
            if (_campaignTotalEarned > campaign.totalBudget) {
                revert OverAttributed();
            }

            campaign.totalEarned = _campaignTotalEarned;

            /// @dev for gas saving since we know that there is no way array will be bigger than uint32
            unchecked {
                i++;
            }
        }
    }

    /// @notice set campaign status
    /// @param _campaignId campaign id
    /// @param _status campaign status
    function setCampaignStatus(uint32 _campaignId, CampaignStatus _status) external virtual onlyOwnerAndWorker {
        CampaignStatus currentStatus = campaigns[_campaignId].status;

        /// @dev campaign status cannot be set to NONE or CREATED.
        /// Campaign is set to status CREATED once via `createCampaign` function
        if (
            currentStatus == CampaignStatus.NONE ||
            currentStatus == _status || /// @dev campaign status cannot be set to same status
            _status == CampaignStatus.CREATED || /// @dev campaign status cannot be set to CREATED
            _status == CampaignStatus.NONE /// @dev campaign status cannot be set to NONE
        ) {
            revert BadRequest();
        }
        emit CampaignStatusUpdated(_campaignId, currentStatus, _status);

        campaigns[_campaignId].status = _status;
    }

    /// @notice add new erc20 payment type to be used by campaign mananger
    /// @param _address erc20 token address
    function addERC20Payment(address _address) external virtual onlyOwnerAndWorker {
        /// @dev payment type already exists
        if (paymentTypes[_address] == true) {
            revert BadRequest();
        }
        paymentTypes[_address] = true;
        emit PaymentAdded(_address);
    }

    /// @notice withdraw remaing balance from campaign if not spent
    /// @dev if campaign status is COMPLETED, campaign manager can withdraw the remaining balance that wasn't spent
    /// @param _campaignId campaign id
    /// @param _to address to send the remaining balance
    function withdrawRemainingCampaignBalance(uint32 _campaignId, address _to) external virtual {
        if (msg.sender != managerAddress) {
            revert Unauthorized();
        }

        uint256 totalEarned = campaigns[_campaignId].totalEarned;
        Campaign storage campaign = campaigns[_campaignId];

        if (campaign.status != CampaignStatus.COMPLETED || totalEarned == campaign.totalBudget) {
            revert BadRequest();
        }

        uint256 withdrawAmount = campaign.totalBudget - totalEarned;
        /// @dev update state before transferring funds
        /// @dev we want to make campaign manager cannot withdraw the same remainder twice
        campaign.totalBudget = totalEarned;

        /// @dev address(0) is the native crypto like Eth, Matic, etc.
        if (campaign.paymentType == address(0)) {
            (bool success, ) = address(_to).call{ value: withdrawAmount }("");
            require(success, "TRANSFER_FAILED");

            /// @dev this is for ERC20 payment types
        } else {
            bool success = IERC20(campaign.paymentType).transfer(address(_to), withdrawAmount);
            require(success, "TRANSFER_FAILED");
        }

        /// @dev emit event. this is the new total budget after we withdrew
        emit BalanceWithdrawn(_campaignId, withdrawAmount, campaign.totalBudget);
    }
}