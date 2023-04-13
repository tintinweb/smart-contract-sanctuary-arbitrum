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

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.8.18;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IAddressBook} from "../interfaces/IAddressBook.sol";
import {IAddressBookGamma} from "../interfaces/IGamma.sol";

/**
 * @author Opyn Team
 * @title AddressBook Module
 */
contract AddressBook is IAddressBook, OwnableUpgradeable {
    mapping(bytes32 => address) private _addresses;
    /// @dev Address of OpynAddressBook to get state of their addressbook
    bytes32 private constant OPYN_ADDRESS_BOOK = keccak256("OPYN_ADDRESS_BOOK");
    /// @dev Address of LP_MANAGER
    bytes32 private constant LP_MANAGER = keccak256("LP_MANAGER");
    /// @dev Address of ORDER_UTIL
    bytes32 private constant ORDER_UTIL = keccak256("ORDER_UTIL");
    /// @dev Address of FEE_COLLECTOR
    bytes32 private constant FEE_COLLECTOR = keccak256("FEE_COLLECTOR");
    /// @dev Address of LENS
    bytes32 private constant LENS = keccak256("LENS");

    /// 3rd party
    /// @dev Address of PERENNIAL_MULTI_INVOKER
    bytes32 private constant PERENNIAL_MULTI_INVOKER =
        keccak256("PERENNIAL_MULTI_INVOKER");
    /// @dev Address of PERENNIAL_LENS
    bytes32 private constant PERENNIAL_LENS = keccak256("PERENNIAL_LENS");

    /**
     *****************************************
     * Mutating Functions
     *****************************************
     */

    /// @notice Perform inherited contracts' initializations
    function __AddressBook_init() external initializer {
        __Ownable_init_unchained();
    }

    /** Opyn Implentation to call out to opyns contract to return values found on their addressbook
     **/
    /**
     * @notice return Otoken implementation address
     * @return Otoken implementation address
     */
    function getOtokenImpl() external view returns (address) {
        return IAddressBookGamma(getAddress(OPYN_ADDRESS_BOOK)).getOtokenImpl();
    }

    /**
     * @notice return oTokenFactory address
     * @return OtokenFactory address
     */
    function getOtokenFactory() external view returns (address) {
        return
            IAddressBookGamma(getAddress(OPYN_ADDRESS_BOOK)).getOtokenFactory();
    }

    /**
     * @notice return Whitelist address
     * @return Whitelist address
     */
    function getWhitelist() external view returns (address) {
        return IAddressBookGamma(getAddress(OPYN_ADDRESS_BOOK)).getWhitelist();
    }

    /**
     * @notice return Controller address
     * @return Controller address
     */
    function getController() external view returns (address) {
        return IAddressBookGamma(getAddress(OPYN_ADDRESS_BOOK)).getController();
    }

    /**
     * @notice return MarginPool address
     * @return MarginPool address
     */
    function getMarginPool() external view returns (address) {
        return IAddressBookGamma(getAddress(OPYN_ADDRESS_BOOK)).getMarginPool();
    }

    /**
     * @notice return MarginCalculator address
     * @return MarginCalculator address
     */
    function getMarginCalculator() external view returns (address) {
        return
            IAddressBookGamma(getAddress(OPYN_ADDRESS_BOOK))
                .getMarginCalculator();
    }

    /**
     * @notice return LiquidationManager address
     * @return LiquidationManager address
     */
    function getLiquidationManager() external view returns (address) {
        return
            IAddressBookGamma(getAddress(OPYN_ADDRESS_BOOK))
                .getLiquidationManager();
    }

    /**
     * @notice return Oracle address
     * @return Oracle address
     */
    function getOracle() external view returns (address) {
        return IAddressBookGamma(getAddress(OPYN_ADDRESS_BOOK)).getOracle();
    }

    /**
     *****************************************
     * Setters for siren implenetation
     *****************************************
     */

    /**
     * @dev Sets an address for an id replacing the address saved in the addresses map
     * IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param opynAddressBook The opynAddressBook to set
     */
    function setOpynAddressBook(address opynAddressBook) external onlyOwner {
        _addresses[OPYN_ADDRESS_BOOK] = opynAddressBook;
        emit OpynAddressBookUpdated(opynAddressBook);
    }

    /**
     * @dev Sets an address for an id replacing the address saved in the addresses map
     * IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param lpManagerAddress LpManager address
     */
    function setLpManager(address lpManagerAddress) external onlyOwner {
        _addresses[LP_MANAGER] = lpManagerAddress;
        emit LpManagerUpdated(lpManagerAddress);
    }

    function setOrderUtil(address orderUtilAddress) external onlyOwner {
        _addresses[ORDER_UTIL] = orderUtilAddress;
        emit OrderUtilUpdated(orderUtilAddress);
    }

    function setFeeCollector(address feeCollectorAddress) external onlyOwner {
        _addresses[FEE_COLLECTOR] = feeCollectorAddress;
        emit FeeCollectorUpdated(feeCollectorAddress);
    }

    function setLens(address lensAddress) external onlyOwner {
        _addresses[LENS] = lensAddress;
        emit LensUpdated(lensAddress);
    }

    function setPerennialMultiInvoker(
        address multiInvokerAddress
    ) external onlyOwner {
        _addresses[PERENNIAL_MULTI_INVOKER] = multiInvokerAddress;
        emit PerennialMultiInvokerUpdated(multiInvokerAddress);
    }

    function setPerennialLens(address lensAddress) external onlyOwner {
        _addresses[PERENNIAL_LENS] = lensAddress;
        emit PerennialLensUpdated(lensAddress);
    }

    /**
     *****************************************
     * Getters for siren implenetation
     *****************************************
     */

    function getOpynAddressBook() external view returns (address) {
        return getAddress(OPYN_ADDRESS_BOOK);
    }

    function getLpManager() external view override returns (address) {
        return getAddress(LP_MANAGER);
    }

    function getOrderUtil() external view returns (address) {
        return getAddress(ORDER_UTIL);
    }

    /// @notice Fee Collector address
    /// @return FeeCollector address
    function getFeeCollector() external view returns (address) {
        return getAddress(FEE_COLLECTOR);
    }

    /// @notice Siren Lens address
    /// @return Lens address
    function getLens() external view returns (address) {
        return getAddress(LENS);
    }

    /// @notice Perennial MultiInvoker address
    /// @return MultiInvoker address
    function getPerennialMultiInvoker() external view returns (address) {
        return getAddress(PERENNIAL_MULTI_INVOKER);
    }

    /// @notice Perennial Lens address
    /// @return PerennialLens address
    function getPerennialLens() external view returns (address) {
        return getAddress(PERENNIAL_LENS);
    }

    /**
     *****************************************
     * General Admin Functions for Address Book
     *****************************************
     */
    /**
     * @dev Sets an address for an id replacing the address saved in the addresses map
     * IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(
        bytes32 id,
        address newAddress
    ) external override onlyOwner {
        _addresses[id] = newAddress;
        emit AddressSet(id, newAddress, false);
    }

    /**
     * @dev Returns an address by id
     * @return The address
     */
    function getAddress(bytes32 id) public view override returns (address) {
        return _addresses[id];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IAddressBookGamma} from "./IGamma.sol";

interface IAddressBook is IAddressBookGamma {
    event OpynAddressBookUpdated(address indexed newAddress);
    event LpManagerUpdated(address indexed newAddress);
    event OrderUtilUpdated(address indexed newAddress);
    event FeeCollectorUpdated(address indexed newAddress);
    event LensUpdated(address indexed newAddress);
    event PerennialMultiInvokerUpdated(address indexed newAddress);
    event PerennialLensUpdated(address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function setAddress(bytes32 id, address newAddress) external;

    function getAddress(bytes32 id) external view returns (address);

    function setOpynAddressBook(address opynAddressBookAddress) external;

    function setLpManager(address lpManagerlAddress) external;

    function setOrderUtil(address orderUtilAddress) external;

    function getOpynAddressBook() external view returns (address);

    function getLpManager() external view returns (address);

    function getOrderUtil() external view returns (address);

    function getFeeCollector() external view returns (address);

    function getLens() external view returns (address);

    function getPerennialMultiInvoker() external view returns (address);

    function getPerennialLens() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

library GammaTypes {
    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        // addresses of oTokens
        address[] oTokens;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of oTokens minted/written for each oToken address
        uint256[] shortAmounts;
        // quantity of oTokens owned and held in the vault for each oToken address
        uint256[] longAmounts;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
        // min strike in the vault
        uint256 minStrike;
        // max strike in the vault
        uint256 maxStrike;
        // min expiry in the vault
        uint256 minExpiry;
        // max expiry in the vault
        uint256 maxExpiry;
    }
}

interface IAddressBookGamma {
    /* Getters */

    function getOtokenImpl() external view returns (address);

    function getOtokenFactory() external view returns (address);

    function getWhitelist() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);

    function getMarginPool() external view returns (address);

    function getMarginCalculator() external view returns (address);

    function getLiquidationManager() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);
}

interface IOtoken {
    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);
}

interface IOtokenFactory {
    function getOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    function createOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external returns (address);

    function getTargetOtokenAddress(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    event OtokenCreated(
        address tokenAddress,
        address creator,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    );
}

interface IController {
    // possible actions that can be performed
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call,
        Liquidate
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // each vault can hold multiple short / long / collateral assets
        // but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    struct RedeemArgs {
        // address to which we pay out the oToken proceeds
        address receiver;
        // oToken that is to be redeemed
        address otoken;
        // amount of oTokens that is to be redeemed
        uint256 amount;
    }

    function getPayout(
        address _otoken,
        uint256 _amount
    ) external view returns (uint256);

    function operate(
        ActionArgs[] calldata _actions
    ) external returns (bool, uint256);

    function getAccountVaultCounter(
        address owner
    ) external view returns (uint256);

    function oracle() external view returns (address);

    function getVault(
        address _owner,
        uint256 _vaultId
    ) external view returns (GammaTypes.Vault memory);

    function getVaultWithDetails(
        address _owner,
        uint256 _vaultId
    ) external view returns (GammaTypes.Vault memory, uint256);

    function getProceed(
        address _owner,
        uint256 _vaultId
    ) external view returns (uint256);

    function isSettlementAllowed(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _expiry
    ) external view returns (bool);

    function hasExpired(address _otoken) external view returns (bool);
}

interface IMarginCalculator {
    function getNakedMarginRequired(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _shortAmount,
        uint256 _strikePrice,
        uint256 _underlyingPrice,
        uint256 _shortExpiryTimestamp,
        uint256 _collateralDecimals,
        bool _isPut
    ) external view returns (uint256);

    function getExcessCollateral(
        GammaTypes.Vault calldata _vault
    ) external view returns (uint256 netValue, bool isExcess);
}

interface IOracle {
    function isLockingPeriodOver(
        address _asset,
        uint256 _expiryTimestamp
    ) external view returns (bool);

    function isDisputePeriodOver(
        address _asset,
        uint256 _expiryTimestamp
    ) external view returns (bool);

    function getExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp
    ) external view returns (uint256, bool);

    function getDisputer() external view returns (address);

    function getPricer(address _asset) external view returns (address);

    function getPrice(address _asset) external view returns (uint256);

    function getPricerLockingPeriod(
        address _pricer
    ) external view returns (uint256);

    function getPricerDisputePeriod(
        address _pricer
    ) external view returns (uint256);

    function getChainlinkRoundData(
        address _asset,
        uint80 _roundId
    ) external view returns (uint256, uint256);

    // Non-view function

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;
}

interface OpynPricerInterface {
    function getPrice() external view returns (uint256);

    function getHistoricalPrice(
        uint80 _roundId
    ) external view returns (uint256, uint256);
}