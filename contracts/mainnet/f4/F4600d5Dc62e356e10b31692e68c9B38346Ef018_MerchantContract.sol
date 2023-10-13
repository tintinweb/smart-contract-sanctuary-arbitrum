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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.14;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/*
@title MerchantContract
@notice This contract is used to create and manage subscriptions for a merchant.
*/
contract MerchantContract is Initializable, OwnableUpgradeable {
    // STATE
    string public organizationId;

    enum SubscriptionStatus {
        ACTIVE,
        INACTIVE
    }

    struct Subscription {
        uint256 id;
        address subscriber;
        uint256 maxAmount;
        uint256 dueBy;
        uint256 paymentInterval;
        SubscriptionStatus status;
        IERC20Upgradeable paymentToken;
    }

    Subscription[] subscriptions;
    uint256 public subscriptionId;

    mapping(string => bool) invoicePaidMap;

    string baseUrl;

    // EVENTS
    event SubscriptionCreated(
        uint256 indexed subscriptionId,
        address subscriber,
        uint256 paymentAmount,
        uint256 paymentInterval,
        string planId,
        string customerExtId
    );
    event MaxAmountUpdated(uint256 indexed subscriptionId, uint256 maxAmount);
    event SubscriptionCancelled(uint256 indexed subscriptionId);
    event SubsPaymentMade(
        uint256 indexed subscriptionId,
        string paymentId,
        address subscriber,
        uint256[] amounts,
        address[] recipients
    );
    event OnetimePaymentMade(
        string paymentId,
        address from,
        uint256[] amounts,
        address[] recipients
    );

    // INITIALIZATION
    function initialize(string memory _organizationId) public initializer {
        organizationId = _organizationId;
        subscriptionId = 0;

        __Ownable_init();
        transferOwnership(tx.origin);
    }

    function createSubscription(
        address _subscriber,
        uint256 _maxAmount,
        uint256 _dueBy,
        uint256 _paymentInterval,
        IERC20Upgradeable _paymentToken,
        string memory _planId,
        string memory _customerId
    ) external onlyOwner {
        Subscription memory subscription = Subscription(
            subscriptionId,
            _subscriber,
            _maxAmount,
            _dueBy,
            _paymentInterval,
            SubscriptionStatus.ACTIVE,
            _paymentToken
        );

        subscriptions.push(subscription);

        emit SubscriptionCreated(
            subscriptionId,
            _subscriber,
            _maxAmount,
            _paymentInterval,
            _planId,
            _customerId
        );

        subscriptionId++;
    }

    function updateSubsMaxAmount(
        uint256 _subscriptionId,
        uint256 _maxAmount
    ) external onlyOwner {
        Subscription memory subscription = subscriptions[_subscriptionId];

        require(
            subscription.status == SubscriptionStatus.ACTIVE,
            "Subscription not active"
        );

        subscription.maxAmount = _maxAmount;
        subscriptions[_subscriptionId] = subscription;
        emit MaxAmountUpdated(_subscriptionId, _maxAmount);
    }

    function cancelSubscription(uint256 _subscriptionId) external onlyOwner {
        Subscription memory subscription = subscriptions[_subscriptionId];
        require(
            subscription.status == SubscriptionStatus.ACTIVE,
            "Subscription not active"
        );

        subscription.status = SubscriptionStatus.INACTIVE;
        subscriptions[_subscriptionId] = subscription;

        emit SubscriptionCancelled(_subscriptionId);
    }

    function getSubscription(
        uint256 _subscriptionId
    ) external view returns (Subscription memory) {
        Subscription memory subscription = subscriptions[_subscriptionId];
        return subscription;
    }

    function getSubscriptions() external view returns (Subscription[] memory) {
        return subscriptions;
    }

    // SUBSCRIPTION PAYMENTS
    function makeSubsPayments(
        uint256 _subscriptionId,
        string memory _paymentId,
        uint256[] memory _amounts,
        address[] memory _recipients
    ) external onlyOwner {
        _checkMakeSubsPayments(
            _subscriptionId,
            _paymentId,
            _amounts,
            _recipients
        );
    }

    function paySubsWithSwap(
        uint256[][] memory _subsData,
        string memory _paymentId,
        address[] memory _recipients,
        address _swapTarget, // API: "to"
        bytes calldata _swapCallData // API: "data",
    ) external onlyOwner {
        _paySubsWithSwap(
            _subsData,
            _paymentId,
            _recipients,
            _swapTarget,
            _swapCallData
        );
    }

    // ONETIME PAYMENTS
    function makePayments(
        address _from,
        string memory _paymentId,
        uint256[] memory _amounts,
        address[] memory _recipients,
        IERC20Upgradeable _paymentToken
    ) external onlyOwner {
        _checkMakePayments(
            _from,
            _paymentId,
            _amounts,
            _recipients,
            _paymentToken
        );
    }

    function makeSwapPayments(
        address _from,
        string memory _paymentId,
        uint256[][] memory _amounts,
        address[] memory _recipients,
        address _swapTarget, // API: "to"
        bytes calldata _swapCallData, // API: "data",
        IERC20Upgradeable _paymentToken
    ) external onlyOwner {
        _checkMakeSwapPayments(
            _from,
            _paymentId,
            _amounts,
            _recipients,
            _swapTarget,
            _swapCallData,
            _paymentToken
        );
    }

    // INTERNAL FUNCTIONS

    // SUBSCRIPTION PAYMENTS
    function _checkMakeSubsPayments(
        uint256 _subscriptionId,
        string memory _paymentId,
        uint256[] memory _amounts,
        address[] memory _recipients
    ) internal {
        Subscription memory subscription = subscriptions[_subscriptionId];

        // Validate

        // Check that the subscription is active
        require(
            subscription.status == SubscriptionStatus.ACTIVE,
            "Subscription not active"
        );
        // Check that the invoice has not been paid
        require(
            invoicePaidMap[_paymentId] == false,
            "Invoice already processed"
        );
        // Check that the subscription is due
        require(
            subscription.dueBy <= block.timestamp,
            "Subscription payment not due yet"
        );

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }

        require(
            totalAmount <= subscription.maxAmount,
            "Payment req exceeds max amount"
        );

        IERC20Upgradeable token = IERC20Upgradeable(subscription.paymentToken);

        // Check token allowance
        uint256 allowance = token.allowance(
            subscription.subscriber,
            address(this)
        );

        require(allowance > totalAmount, "Token allowance insufficient");

        // Check user token balance
        uint256 balance = token.balanceOf(subscription.subscriber);
        require(balance > totalAmount, "Token balance insufficient");

        _makeSubsPayments(
            subscription.subscriber,
            subscription,
            _amounts,
            _recipients,
            _paymentId
        );
    }

    // _subsData[0] = subscriptionId
    // _subsData[1] = sellAmounts[]
    // _subsData[2] = buyAmounts[]
    function _paySubsWithSwap(
        uint256[][] memory _subsData,
        string memory _paymentId,
        address[] memory _recipients,
        address _swapTarget, // API: "to"
        bytes calldata _swapCallData // API: "data",
    ) private {
        Subscription memory subscription = subscriptions[_subsData[0][0]];

        // Validate
        require(
            subscription.status == SubscriptionStatus.ACTIVE,
            "Subscription not active"
        );
        require(
            invoicePaidMap[_paymentId] == false,
            "Invoice already processed"
        );
        require(
            subscription.dueBy <= block.timestamp,
            "Subscription payment not due yet"
        );

        uint256 totalSellAmount = 0;

        for (uint256 i = 0; i < _subsData[1].length; i++) {
            totalSellAmount += _subsData[1][i];
        }

        require(
            totalSellAmount <= subscription.maxAmount,
            "Payment req exceeds max amount"
        );

        IERC20Upgradeable paymentToken = IERC20Upgradeable(
            subscription.paymentToken
        );

        // Check token allowance
        uint256 allowance = paymentToken.allowance(
            subscription.subscriber,
            address(this)
        );

        require(allowance > totalSellAmount, "Token allowance insufficient");

        // Check user token balance
        uint256 balance = paymentToken.balanceOf(subscription.subscriber);
        require(balance > totalSellAmount, "Token balance insufficient");

        // Transfer tokens to this contract
        paymentToken.transferFrom(
            subscription.subscriber,
            address(this),
            totalSellAmount
        );

        // Perform swap
        (bool success, ) = _swapTarget.call(_swapCallData);
        require(success, "Swap failed");

        // Make payments
        _makeSubsSwapPayments(
            subscription,
            _subsData[2],
            _recipients,
            _paymentId
        );
    }

    function _makeSubsSwapPayments(
        Subscription memory _subscription,
        uint256[] memory _amounts,
        address[] memory _recipients,
        string memory _paymentId
    ) internal {
        _makeSubsPayments(
            address(this),
            _subscription,
            _amounts,
            _recipients,
            _paymentId
        );
    }

    function _makeSubsPayments(
        address from,
        Subscription memory _subscription,
        uint256[] memory _amounts,
        address[] memory _recipients,
        string memory _paymentId
    ) internal {
        IERC20Upgradeable token = IERC20Upgradeable(_subscription.paymentToken);

        // Make subscription payments
        for (uint256 i = 0; i < _amounts.length; i++) {
            token.transferFrom(from, _recipients[i], _amounts[i]);
        }

        // Update payment due time
        _subscription.dueBy = block.timestamp + _subscription.paymentInterval;
        subscriptions[_subscription.id] = _subscription;

        // Update invoice map
        invoicePaidMap[_paymentId] = true;

        emit SubsPaymentMade(
            _subscription.id,
            _paymentId,
            _subscription.subscriber,
            _amounts,
            _recipients
        );
    }

    // ONETIME PAYMENTS
    function _checkMakePayments(
        address _from,
        string memory _paymentId,
        uint256[] memory _amounts,
        address[] memory _recipients,
        IERC20Upgradeable _paymentToken
    ) internal {
        // Validate
        require(
            invoicePaidMap[_paymentId] == false,
            "Invoice already processed"
        );

        IERC20Upgradeable paymentToken = IERC20Upgradeable(_paymentToken);

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }

        // Check token allowance
        uint256 allowance = paymentToken.allowance(_from, address(this));

        require(allowance > totalAmount, "Token allowance insufficient");

        // Check user token balance
        uint256 balance = paymentToken.balanceOf(_from);
        require(balance > totalAmount, "Token balance insufficient");

        _makePayments(_from, _amounts, _recipients, _paymentId, _paymentToken);
    }

    function _checkMakeSwapPayments(
        address _from,
        string memory _paymentId,
        uint256[][] memory _amounts,
        address[] memory _recipients,
        address _swapTarget, // API: "to"
        bytes calldata _swapCallData, // API: "data",
        IERC20Upgradeable _paymentToken
    ) private {
        // Validate
        require(
            invoicePaidMap[_paymentId] == false,
            "Invoice already processed"
        );

        uint256 totalSellAmount = 0;

        for (uint256 i = 0; i < _amounts[0].length; i++) {
            totalSellAmount += _amounts[0][i];
        }

        IERC20Upgradeable paymentToken = IERC20Upgradeable(_paymentToken);

        // Check token allowance
        uint256 allowance = paymentToken.allowance(_from, address(this));

        require(allowance > totalSellAmount, "Token allowance insufficient");

        // Check user token balance
        uint256 balance = paymentToken.balanceOf(_from);
        require(balance > totalSellAmount, "Token balance insufficient");

        // Transfer tokens to this contract
        paymentToken.transferFrom(_from, address(this), totalSellAmount);

        // Perform swap
        (bool success, ) = _swapTarget.call(_swapCallData);
        require(success, "Swap failed");

        // Make payments
        _makeSwapPayments(_amounts[1], _recipients, _paymentId, _paymentToken);
    }

    function _makeSwapPayments(
        uint256[] memory _amounts,
        address[] memory _recipients,
        string memory _paymentId,
        IERC20Upgradeable _paymentToken
    ) internal {
        _makePayments(
            address(this),
            _amounts,
            _recipients,
            _paymentId,
            _paymentToken
        );
    }

    function _makePayments(
        address _from,
        uint256[] memory _amounts,
        address[] memory _recipients,
        string memory _paymentId,
        IERC20Upgradeable _paymentToken
    ) internal {
        IERC20Upgradeable token = IERC20Upgradeable(_paymentToken);

        // Make subscription payments
        for (uint256 i = 0; i < _amounts.length; i++) {
            token.transferFrom(_from, _recipients[i], _amounts[i]);
        }

        // Update invoice map
        invoicePaidMap[_paymentId] = true;

        emit OnetimePaymentMade(_paymentId, _from, _amounts, _recipients);
    }
}