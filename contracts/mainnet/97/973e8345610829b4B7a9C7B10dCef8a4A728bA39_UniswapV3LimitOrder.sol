// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967 {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/IERC1967.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967Upgrade is IERC1967 {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title QuoterV2 Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps.
/// @notice For each pool also tells you the number of initialized ticks crossed and the sqrt price of the pool after the swap.
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoterV2 {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactInput(bytes memory path, uint256 amountIn)
        external
        returns (
            uint256 amountOut,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactInputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// amountIn The desired input amount
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
        external
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactOutput(bytes memory path, uint256 amountOut)
        external
        returns (
            uint256 amountIn,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    struct QuoteExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactOutputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// amountOut The desired output amount
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactOutputSingle(QuoteExactOutputSingleParams memory params)
        external
        returns (
            uint256 amountIn,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

/* solhint-disable no-empty-blocks */

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * @title TokenCallbackHandler
 * @author fun.xyz
 * @notice Token callback handler.
 * Handles supported tokens' callbacks, allowing account receiving these tokens.
 */
contract TokenCallbackHandler is IERC777Recipient, IERC721Receiver, IERC1155Receiver {
	/**
	 * @dev This hook is used for ERC-777 tokens
	 */
	function tokensReceived(address, address, address, uint256, bytes calldata, bytes calldata) external pure override {}

	/**
	 * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
	 * by `operator` from `from`, this function is called.
	 *
	 * It must return its Solidity selector to confirm the token transfer.
	 * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
	 *
	 * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
	 *
	 * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` if transfer is allowed
	 */
	function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
		return IERC721Receiver.onERC721Received.selector;
	}

	/**
	 * @dev Handles the receipt of a single ERC1155 token type. This function is
	 * called at the end of a `safeTransferFrom` after the balance has been updated.
	 *
	 * NOTE: To accept the transfer, this must return
	 * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
	 * (i.e. 0xf23a6e61, or its own function selector).
	 *
	 * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
	 */
	function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure override returns (bytes4) {
		return IERC1155Receiver.onERC1155Received.selector;
	}

	/**
	 * @dev Handles the receipt of a multiple ERC1155 token types. This function
	 * is called at the end of a `safeBatchTransferFrom` after the balances have
	 * been updated.
	 *
	 * NOTE: To accept the transfer(s), this must return
	 * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
	 * (i.e. 0xbc197c81, or its own function selector).
	 *
	 * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
	 */
	function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure override returns (bytes4) {
		return IERC1155Receiver.onERC1155BatchReceived.selector;
	}

	/**
	 * @dev Returns true if this contract implements the interface defined by
	 * `interfaceId`. See the corresponding
	 * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
	 * to learn more about how these ids are created.
	 *
	 * This function call must use less than 30 000 gas.
	 *
	 * @return true if interfaceId is supported(IERC721Receiver, IERC1155Receiver, IERC165), false otherwise
	 */
	function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
		return
			interfaceId == type(IERC721Receiver).interfaceId ||
			interfaceId == type(IERC1155Receiver).interfaceId ||
			interfaceId == type(IERC165).interfaceId;
	}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "../wallet/IFunWallet.sol";

interface IFunWalletFactory {
	/**
	 * @notice Deploys a new FunWallet contract and initializes it with the given initializer call data.
	 * @dev If a contract with the given salt already exists, returns the existing contract.
	 * @param initializerCallData The call data for initializing the FunWallet contract.
	 * @param data The social login data struct from IWalletInit. See IWalletInit.sol for more info
	 * @return funWallet The deployed FunWallet contract.
	 */
	function createAccount(bytes calldata initializerCallData, bytes calldata data) external returns (IFunWallet funWallet);

	/**
	 * @dev Calculate the counterfactual address of this account as it would be returned by createAccount()
	 * @param data The social login data struct from IWalletInit. See IWalletInit.sol for more info
	 * @return The computed address of the contract deployment.
	 */
	function getAddress(bytes calldata data, bytes calldata initializerCallData) external view returns (address);

	/**
	 * @return The address of the feeOracle
	 */
	function getFeeOracle() external view returns (address payable);

	/**
	 * @param _feeOracle The address of the feeOracle to use
	 */
	function setFeeOracle(address payable _feeOracle) external;

	/**
	 * Verify the contract was deployed from the Create3Deployer
	 * @param salt Usually the moduleId()
	 * @param sender The sender of the transaction, usually the module
	 */
	function verifyDeployedFrom(bytes32 salt, address sender) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "./UserOperation.sol";

interface IAccount {
	/**
	 * Validate user's signature and nonce
	 * the entryPoint will make the call to the recipient only if this validation call returns successfully.
	 * signature failure should be reported by returning SIG_VALIDATION_FAILED (1).
	 * This allows making a "simulation call" without a valid signature
	 * Other failures (e.g. nonce mismatch, or invalid signature format) should still revert to signal failure.
	 *
	 * @dev Must validate caller is the entryPoint.
	 *      Must validate the signature and nonce
	 * @param userOp the operation that is about to be executed.
	 * @param userOpHash hash of the user's request data. can be used as the basis for signature.
	 * @param missingAccountFunds missing funds on the account's deposit in the entrypoint.
	 *      This is the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
	 *      The excess is left as a deposit in the entrypoint, for future calls.
	 *      can be withdrawn anytime using "entryPoint.withdrawTo()"
	 *      In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
	 * @return validationData packaged ValidationData structure. use `_packValidationData` and `_unpackValidationData` to encode and decode
	 *      <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
	 *         otherwise, an address of an "authorizer" contract.
	 *      <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
	 *      <6-byte> validAfter - first timestamp this operation is valid
	 *      If an account doesn't use time-range, it is enough to return SIG_VALIDATION_FAILED value (1) for signature failure.
	 *      Note that the validation code cannot use block.timestamp (or block.number) directly.
	 */
	function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds) external returns (uint256 validationData);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "./UserOperation.sol";

/**
 * Aggregated Signatures validator.
 */
interface IAggregator {
	/**
	 * validate aggregated signature.
	 * revert if the aggregated signature does not match the given list of operations.
	 */
	function validateSignatures(UserOperation[] calldata userOps, bytes calldata signature) external view;

	/**
	 * validate signature of a single userOp
	 * This method is should be called by bundler after EntryPoint.simulateValidation() returns (reverts) with ValidationResultWithAggregation
	 * First it validates the signature over the userOp. Then it returns data to be used when creating the handleOps.
	 * @param userOp the userOperation received from the user.
	 * @return sigForUserOp the value to put into the signature field of the userOp when calling handleOps.
	 *    (usually empty, unless account and aggregator support some kind of "multisig"
	 */
	function validateUserOpSignature(UserOperation calldata userOp) external view returns (bytes memory sigForUserOp);

	/**
	 * aggregate multiple signatures into a single value.
	 * This method is called off-chain to calculate the signature to pass with handleOps()
	 * bundler MAY use optimized custom code perform this aggregation
	 * @param userOps array of UserOperations to collect the signatures from.
	 * @return aggregatedSignature the aggregated signature
	 */
	function aggregateSignatures(UserOperation[] calldata userOps) external view returns (bytes memory aggregatedSignature);
}

/**
 ** Account-Abstraction (EIP-4337) singleton EntryPoint implementation.
 ** Only one instance required on each chain.
 **/
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "./UserOperation.sol";
import "./IStakeManager.sol";
import "./IAggregator.sol";
import "./INonceManager.sol";

interface IEntryPoint is IStakeManager, INonceManager {
	/***
	 * An event emitted after each successful request
	 * @param userOpHash - unique identifier for the request (hash its entire content, except signature).
	 * @param sender - the account that generates this request.
	 * @param paymaster - if non-null, the paymaster that pays for this request.
	 * @param nonce - the nonce value from the request.
	 * @param success - true if the sender transaction succeeded, false if reverted.
	 * @param actualGasCost - actual amount paid (by account or paymaster) for this UserOperation.
	 * @param actualGasUsed - total gas used by this UserOperation (including preVerification, creation, validation and execution).
	 */
	event UserOperationEvent(
		bytes32 indexed userOpHash,
		address indexed sender,
		address indexed paymaster,
		uint256 nonce,
		bool success,
		uint256 actualGasCost,
		uint256 actualGasUsed
	);

	/**
	 * account "sender" was deployed.
	 * @param userOpHash the userOp that deployed this account. UserOperationEvent will follow.
	 * @param sender the account that is deployed
	 * @param factory the factory used to deploy this account (in the initCode)
	 * @param paymaster the paymaster used by this UserOp
	 */
	event AccountDeployed(bytes32 indexed userOpHash, address indexed sender, address factory, address paymaster);

	/**
	 * An event emitted if the UserOperation "callData" reverted with non-zero length
	 * @param userOpHash the request unique identifier.
	 * @param sender the sender of this request
	 * @param nonce the nonce used in the request
	 * @param revertReason - the return bytes from the (reverted) call to "callData".
	 */
	event UserOperationRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason);

	/**
	 * an event emitted by handleOps(), before starting the execution loop.
	 * any event emitted before this event, is part of the validation.
	 */
	event BeforeExecution();

	/**
	 * signature aggregator used by the following UserOperationEvents within this bundle.
	 */
	event SignatureAggregatorChanged(address indexed aggregator);

	/**
	 * a custom revert error of handleOps, to identify the offending op.
	 *  NOTE: if simulateValidation passes successfully, there should be no reason for handleOps to fail on it.
	 *  @param opIndex - index into the array of ops to the failed one (in simulateValidation, this is always zero)
	 *  @param reason - revert reason
	 *      The string starts with a unique code "AAmn", where "m" is "1" for factory, "2" for account and "3" for paymaster issues,
	 *      so a failure can be attributed to the correct entity.
	 *   Should be caught in off-chain handleOps simulation and not happen on-chain.
	 *   Useful for mitigating DoS attempts against batchers or for troubleshooting of factory/account/paymaster reverts.
	 */
	error FailedOp(uint256 opIndex, string reason);

	/**
	 * error case when a signature aggregator fails to verify the aggregated signature it had created.
	 */
	error SignatureValidationFailed(address aggregator);

	/**
	 * Successful result from simulateValidation.
	 * @param returnInfo gas and time-range returned values
	 * @param senderInfo stake information about the sender
	 * @param factoryInfo stake information about the factory (if any)
	 * @param paymasterInfo stake information about the paymaster (if any)
	 */
	error ValidationResult(ReturnInfo returnInfo, StakeInfo senderInfo, StakeInfo factoryInfo, StakeInfo paymasterInfo);

	/**
	 * Successful result from simulateValidation, if the account returns a signature aggregator
	 * @param returnInfo gas and time-range returned values
	 * @param senderInfo stake information about the sender
	 * @param factoryInfo stake information about the factory (if any)
	 * @param paymasterInfo stake information about the paymaster (if any)
	 * @param aggregatorInfo signature aggregation info (if the account requires signature aggregator)
	 *      bundler MUST use it to verify the signature, or reject the UserOperation
	 */
	error ValidationResultWithAggregation(
		ReturnInfo returnInfo,
		StakeInfo senderInfo,
		StakeInfo factoryInfo,
		StakeInfo paymasterInfo,
		AggregatorStakeInfo aggregatorInfo
	);

	/**
	 * return value of getSenderAddress
	 */
	error SenderAddressResult(address sender);

	/**
	 * return value of simulateHandleOp
	 */
	error ExecutionResult(uint256 preOpGas, uint256 paid, uint48 validAfter, uint48 validUntil, bool targetSuccess, bytes targetResult);

	//UserOps handled, per aggregator
	struct UserOpsPerAggregator {
		UserOperation[] userOps;
		// aggregator address
		IAggregator aggregator;
		// aggregated signature
		bytes signature;
	}

	/**
	 * Execute a batch of UserOperation.
	 * no signature aggregator is used.
	 * if any account requires an aggregator (that is, it returned an aggregator when
	 * performing simulateValidation), then handleAggregatedOps() must be used instead.
	 * @param ops the operations to execute
	 * @param beneficiary the address to receive the fees
	 */
	function handleOps(UserOperation[] calldata ops, address payable beneficiary) external;

	/**
	 * Execute a batch of UserOperation with Aggregators
	 * @param opsPerAggregator the operations to execute, grouped by aggregator (or address(0) for no-aggregator accounts)
	 * @param beneficiary the address to receive the fees
	 */
	function handleAggregatedOps(UserOpsPerAggregator[] calldata opsPerAggregator, address payable beneficiary) external;

	/**
	 * generate a request Id - unique identifier for this request.
	 * the request ID is a hash over the content of the userOp (except the signature), the entrypoint and the chainid.
	 */
	function getUserOpHash(UserOperation calldata userOp) external view returns (bytes32);

	/**
	 * Simulate a call to account.validateUserOp and paymaster.validatePaymasterUserOp.
	 * @dev this method always revert. Successful result is ValidationResult error. other errors are failures.
	 * @dev The node must also verify it doesn't use banned opcodes, and that it doesn't reference storage outside the account's data.
	 * @param userOp the user operation to validate.
	 */
	function simulateValidation(UserOperation calldata userOp) external;

	/**
	 * gas and return values during simulation
	 * @param preOpGas the gas used for validation (including preValidationGas)
	 * @param prefund the required prefund for this operation
	 * @param sigFailed validateUserOp's (or paymaster's) signature check failed
	 * @param validAfter - first timestamp this UserOp is valid (merging account and paymaster time-range)
	 * @param validUntil - last timestamp this UserOp is valid (merging account and paymaster time-range)
	 * @param paymasterContext returned by validatePaymasterUserOp (to be passed into postOp)
	 */
	struct ReturnInfo {
		uint256 preOpGas;
		uint256 prefund;
		bool sigFailed;
		uint48 validAfter;
		uint48 validUntil;
		bytes paymasterContext;
	}

	/**
	 * returned aggregated signature info.
	 * the aggregator returned by the account, and its current stake.
	 */
	struct AggregatorStakeInfo {
		address aggregator;
		StakeInfo stakeInfo;
	}

	/**
	 * Get counterfactual sender address.
	 *  Calculate the sender contract address that will be generated by the initCode and salt in the UserOperation.
	 * this method always revert, and returns the address in SenderAddressResult error
	 * @param initCode the constructor code to be passed into the UserOperation.
	 */
	function getSenderAddress(bytes memory initCode) external;

	/**
	 * simulate full execution of a UserOperation (including both validation and target execution)
	 * this method will always revert with "ExecutionResult".
	 * it performs full validation of the UserOperation, but ignores signature error.
	 * an optional target address is called after the userop succeeds, and its value is returned
	 * (before the entire call is reverted)
	 * Note that in order to collect the the success/failure of the target call, it must be executed
	 * with trace enabled to track the emitted events.
	 * @param op the UserOperation to simulate
	 * @param target if nonzero, a target address to call after userop simulation. If called, the targetSuccess and targetResult
	 *        are set to the return from that call.
	 * @param targetCallData callData to pass to target address
	 */
	function simulateHandleOp(UserOperation calldata op, address target, bytes calldata targetCallData) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface INonceManager {
	/**
	 * Return the next nonce for this sender.
	 * Within a given key, the nonce values are sequenced (starting with zero, and incremented by one on each userop)
	 * But UserOp with different keys can come with arbitrary order.
	 *
	 * @param sender the account address
	 * @param key the high 192 bit of the nonce
	 * @return nonce a full nonce to pass for next UserOp with this sender.
	 */
	function getNonce(address sender, uint192 key) external view returns (uint256 nonce);

	/**
	 * Manually increment the nonce of the sender.
	 * This method is exposed just for completeness..
	 * Account does NOT need to call it, neither during validation, nor elsewhere,
	 * as the EntryPoint will update the nonce regardless.
	 * Possible use-case is call it with various keys to "initialize" their nonces to one, so that future
	 * UserOperations will not pay extra for the first transaction with a given key.
	 */
	function incrementNonce(uint192 key) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

/**
 * manage deposits and stakes.
 * deposit is just a balance used to pay for UserOperations (either by a paymaster or an account)
 * stake is value locked for at least "unstakeDelay" by the staked entity.
 */
interface IStakeManager {
	event Deposited(address indexed account, uint256 totalDeposit);

	event Withdrawn(address indexed account, address withdrawAddress, uint256 amount);

	/// Emitted when stake or unstake delay are modified
	event StakeLocked(address indexed account, uint256 totalStaked, uint256 unstakeDelaySec);

	/// Emitted once a stake is scheduled for withdrawal
	event StakeUnlocked(address indexed account, uint256 withdrawTime);

	event StakeWithdrawn(address indexed account, address withdrawAddress, uint256 amount);

	/**
	 * @param deposit the entity's deposit
	 * @param staked true if this entity is staked.
	 * @param stake actual amount of ether staked for this entity.
	 * @param unstakeDelaySec minimum delay to withdraw the stake.
	 * @param withdrawTime - first block timestamp where 'withdrawStake' will be callable, or zero if already locked
	 * @dev sizes were chosen so that (deposit,staked, stake) fit into one cell (used during handleOps)
	 *    and the rest fit into a 2nd cell.
	 *    112 bit allows for 10^15 eth
	 *    48 bit for full timestamp
	 *    32 bit allows 150 years for unstake delay
	 */
	struct DepositInfo {
		uint112 deposit;
		bool staked;
		uint112 stake;
		uint32 unstakeDelaySec;
		uint48 withdrawTime;
	}

	//API struct used by getStakeInfo and simulateValidation
	struct StakeInfo {
		uint256 stake;
		uint256 unstakeDelaySec;
	}

	/// @return info - full deposit information of given account
	function getDepositInfo(address account) external view returns (DepositInfo memory info);

	/// @return the deposit (for gas payment) of the account
	function balanceOf(address account) external view returns (uint256);

	/**
	 * add to the deposit of the given account
	 */
	function depositTo(address account) external payable;

	/**
	 * add to the account's stake - amount and delay
	 * any pending unstake is first cancelled.
	 * @param _unstakeDelaySec the new lock duration before the deposit can be withdrawn.
	 */
	function addStake(uint32 _unstakeDelaySec) external payable;

	/**
	 * attempt to unlock the stake.
	 * the value can be withdrawn (using withdrawStake) after the unstake delay.
	 */
	function unlockStake() external;

	/**
	 * withdraw from the (unlocked) stake.
	 * must first call unlockStake and wait for the unstakeDelay to pass
	 * @param withdrawAddress the address to send withdrawn value.
	 */
	function withdrawStake(address payable withdrawAddress) external;

	/**
	 * withdraw from the deposit.
	 * @param withdrawAddress the address to send withdrawn value.
	 * @param withdrawAmount the amount to withdraw.
	 */
	function withdrawTo(address payable withdrawAddress, uint256 withdrawAmount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/* solhint-disable no-inline-assembly */

/**
 * User Operation struct
 * @param sender the sender account of this request.
 * @param nonce unique value the sender uses to verify it is not a replay.
 * @param initCode if set, the account contract will be created by this constructor/
 * @param callData the method call to execute on this account.
 * @param callGasLimit the gas limit passed to the callData method call.
 * @param verificationGasLimit gas used for validateUserOp and validatePaymasterUserOp.
 * @param preVerificationGas gas not calculated by the handleOps method, but added to the gas paid. Covers batch overhead.
 * @param maxFeePerGas same as EIP-1559 gas parameter.
 * @param maxPriorityFeePerGas same as EIP-1559 gas parameter.
 * @param paymasterAndData if set, this field holds the paymaster address and paymaster-specific data. the paymaster will pay for the transaction instead of the sender.
 * @param signature sender-verified signature over the entire request, the EntryPoint address and the chain ID.
 */
struct UserOperation {
	address sender;
	uint256 nonce;
	bytes initCode;
	bytes callData;
	uint256 callGasLimit;
	uint256 verificationGasLimit;
	uint256 preVerificationGas;
	uint256 maxFeePerGas;
	uint256 maxPriorityFeePerGas;
	bytes paymasterAndData;
	bytes signature;
}

/**
 * Utility functions helpful when working with UserOperation structs.
 */
library UserOperationLib {
	function getSender(UserOperation calldata userOp) internal pure returns (address) {
		address data;
		//read sender from userOp, which is first userOp member (saves 800 gas...)
		assembly {
			data := calldataload(userOp)
		}
		return address(uint160(data));
	}

	//relayer/block builder might submit the TX with higher priorityFee, but the user should not
	// pay above what he signed for.
	function gasPrice(UserOperation calldata userOp) internal view returns (uint256) {
		unchecked {
			uint256 maxFeePerGas = userOp.maxFeePerGas;
			uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
			if (maxFeePerGas == maxPriorityFeePerGas) {
				//legacy mode (for networks that don't support basefee opcode)
				return maxFeePerGas;
			}
			return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
		}
	}

	function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {
		//lighter signature scheme. must match UserOp.ts#packUserOp
		bytes calldata sig = userOp.signature;
		// copy directly the userOp from calldata up to (but not including) the signature.
		// this encoding depends on the ABI encoding of calldata, but is much lighter to copy
		// than referencing each field separately.
		assembly {
			let ofs := userOp
			let len := sub(sub(sig.offset, ofs), 32)
			ret := mload(0x40)
			mstore(0x40, add(ret, add(len, 32)))
			mstore(ret, len)
			calldatacopy(add(ret, 32), ofs, len)
		}
	}

	function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
		return keccak256(pack(userOp));
	}

	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

interface IWETH9 {
	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	function decimals() external view returns (uint8);

	function balanceOf(address) external view returns (uint);

	function allowance(address, address) external view returns (uint);

	receive() external payable;

	function deposit() external payable;

	function withdraw(uint wad) external;

	function totalSupply() external view returns (uint);

	function approve(address guy, uint wad) external returns (bool);

	function transfer(address dst, uint wad) external returns (bool);

	function transferFrom(address src, address dst, uint wad) external returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

interface IFeePercentOracle {
	/**
	 * @notice Sets the values for {feepercent} and {decimals}.
	 * {_feepercent=4, _decimals=2} -> {4 / 10 ** 2} -> 4%
	 * @dev Must be owner.
	 * @param _feepercent the new percentage number
	 * @param _decimals the new decimal of the percentage
	 */
	function setValues(uint120 _feepercent, uint8 _decimals) external;

	/**
	 * @notice Returns the fee percent and recipient cut for a given amount.
	 * @param amount The amount to calculate the fee for.
	 * @return funCut The fee percent.
	 * @return recipCut The recipient cut.
	 */
	function getFee(uint256 amount) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "../eip-4337/IEntryPoint.sol";

struct UserOperationFee {
	address token;
	address payable recipient;
	uint256 amount;
}

interface IFunWallet {
	/**
	 * @notice deposit to entrypoint to prefund the execution.
	 * @dev This function can only be called by the owner of the contract.
	 * @param amount the amount to deposit.
	 */
	function depositToEntryPoint(uint256 amount) external;

	/**
	 * @notice Get the entry point for this contract
	 * @dev This function returns the contract's entry point interface.
	 * @return The contract's entry point interface.
	 */
	function entryPoint() external view returns (IEntryPoint);

	/**
	 * @notice Update the entry point for this contract
	 * @dev This function can only be called by the current entry point.
	 * @dev The new entry point address cannot be zero.
	 * @param _newEntryPoint The address of the new entry point.
	 */
	function updateEntryPoint(IEntryPoint _newEntryPoint) external;

	/**
	 * @notice withdraw deposit from entrypoint
	 * @dev This function can only be called by the owner of the contract.
	 * @param withdrawAddress the address to withdraw Eth to
	 * @param amount the amount to be withdrawn
	 */
	function withdrawFromEntryPoint(address payable withdrawAddress, uint256 amount) external;

	/**
	 * @notice Transfer ERC20 tokens from the wallet to a destination address.
	 * @param token ERC20 token address
	 * @param dest Destination address
	 * @param amount Amount of tokens to transfer
	 */
	function transferErc20(address token, address dest, uint256 amount) external;

	function isValidAction(address target, uint256 value, bytes memory data, bytes memory signature, bytes32 _hash) external view returns (uint256);

	event EntryPointChanged(address indexed newEntryPoint);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

interface IModule {
	/**
	 * @dev Executes an operation in the context of the module contract.
	 * @param data Arbitrary data to be used by the execute function. Feel free to structure this however you wish
	 */
	function execute(bytes calldata data) external;

	/**
	 * @dev Return the moduleId, make sure this is unique!
	 */
	function moduleId() external view returns (bytes32);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "../eip-4337/UserOperation.sol";

interface IValidation {
	function init(bytes calldata initData) external;

	/**
	 * @notice Validates the UserOperation based on its rules.
	 * @param userOp UserOperation to validate.
	 * @param userOpHash Hash of the UserOperation.
	 * @param helperData Unused
	 * @return sigTimeRange Valid Time Range of the signature.
	 */
	function authenticateUserOp(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		bytes memory helperData
	) external view returns (uint256 sigTimeRange);

	/**
	 * @notice Validates if a user can call: target.call(data) in the FunWallet
	 * @return sigTimeRange Valid Time Range of the signature.
	 */
	function isValidAction(address target, uint256 value, bytes memory data, bytes memory signature, bytes32 _hash) external view returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "./IFunWallet.sol";

interface IWalletFee {
	function execFromEntryPoint(address dest, uint256 value, bytes calldata data) external;

	function execFromEntryPointWithFee(address dest, uint256 value, bytes calldata data, UserOperationFee memory feedata) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

interface IWalletState {
	/**
	 * @dev Returns the current state of the module contract.
	 * @param key The key of the state to return.
	 * @return state The current state of the module contract.
	 */
	function getState(bytes32 key) external view returns (bytes memory);

	/**
	 * Get the stored 32 bytes word of a module
	 * @param key the key a module would like to get
	 */
	function getState32(bytes32 key) external view returns (bytes32 out);

	/**
	 * Set the stored state of a module
	 * @param key the key a module would like to store
	 * @param val the value a module would like to store
	 */
	function setState(bytes32 key, bytes calldata val) external;

	/**
	 * Set the stored 32 bytes word of a module
	 * @param key the key a module would like to store
	 * @param val the value a module would like to store
	 */
	function setState32(bytes32 key, bytes32 val) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "../Module.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "../../interfaces/modules/IWETH9.sol";

/**
 * @title Limit Order Contract using uniswap V3
 * @notice The order executes when validate returns true.
 * @dev This contract implements the `Module` interface
 */
contract UniswapV3LimitOrder is Module {
	using SafeERC20 for IERC20;

	bytes32 public constant moduleId = keccak256(abi.encodePacked("UniswapV3LimitOrderV2"));

	ISwapRouter public immutable router;
	IQuoterV2 public immutable quoter;
	IWETH9 public immutable weth;
	bytes public constant depositCallData = abi.encodeWithSelector(IWETH9.deposit.selector);

	constructor(address _router, address _quoter, address payable _weth) {
		require(_router != address(0), "FW109");
		require(_quoter != address(0), "FW110");
		require(_weth != address(0), "FW111");
		router = ISwapRouter(_router);
		quoter = IQuoterV2(_quoter);
		weth = IWETH9(_weth);
	}

	/**
	 * @dev Fun.xyz will repeatedly check this validate function and call execute when validate returns true
	 */
	function validate(bytes calldata data) public returns (bool) {
		(uint24 poolFee, address tokenIn, address tokenOut, uint256 tokenInAmount, uint256 tokenOutAmount) = abi.decode(
			data,
			(uint24, address, address, uint256, uint256)
		);
		IQuoterV2.QuoteExactInputSingleParams memory params = IQuoterV2.QuoteExactInputSingleParams({
			tokenIn: tokenIn,
			tokenOut: tokenOut,
			amountIn: tokenInAmount,
			fee: poolFee,
			sqrtPriceLimitX96: 0
		});
		if (tokenIn == address(weth)) {
			if (weth.balanceOf(msg.sender) < tokenInAmount && address(msg.sender).balance < tokenInAmount) {
				return false;
			}
		}
		(uint256 amountOut, , , ) = quoter.quoteExactInputSingle(params);
		return amountOut >= tokenOutAmount;
	}

	/**
	 * @dev Executes a swap from USDC to WETH using uniswap v3
	 */
	function execute(bytes calldata data) external override {
		require(validate(data), "FW101");
		(uint24 poolFee, address tokenIn, address tokenOut, uint256 tokenInAmount, uint256 tokenOutAmount) = abi.decode(
			data,
			(uint24, address, address, uint256, uint256)
		);

		if (tokenIn == address(weth) && weth.balanceOf(msg.sender) <= tokenInAmount) {
			_executeFromFunWallet(address(weth), tokenInAmount - weth.balanceOf(msg.sender), depositCallData);
			require(weth.balanceOf(msg.sender) >= tokenInAmount, "FW112");
		}

		bytes memory approveCallData = abi.encodeWithSelector(IERC20(tokenIn).approve.selector, address(router), tokenInAmount);
		bytes memory approveRespose = _executeFromFunWallet(tokenIn, 0, approveCallData);
		require(abi.decode(approveRespose, (bool)), "FW108");

		ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
			tokenIn: tokenIn,
			tokenOut: tokenOut,
			fee: poolFee,
			recipient: msg.sender,
			deadline: block.timestamp,
			amountIn: tokenInAmount,
			amountOutMinimum: 0,
			sqrtPriceLimitX96: 0
		});
		bytes memory swapCalldata = abi.encodeCall(router.exactInputSingle, params);
		_executeFromFunWallet(address(router), 0, swapCalldata);
	}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "../interfaces/wallet/IModule.sol";
import "../wallet/FunWallet.sol";

/**
 * @dev Basic module contract that can be attached to a FunWallet.
 */
abstract contract Module is IModule {
	bytes public constant EMPTY_STATE = bytes("EMPTY_STATE");

	/**
	 * @dev Executes an operation in the context of the module contract.
	 */
	function execute(bytes calldata) external virtual override {
		require(false, "FW100");
	}

	/**
	 * @dev Returns the current state of the module contract.
	 * @param key The key of the state to return.
	 * @return state The current state of the module contract.
	 */
	function getState(bytes32 key) public view returns (bytes memory state) {
		bytes32 moduleKey = HashLib.hash2(key, address(this));
		return FunWallet(payable(msg.sender)).getState(moduleKey);
	}

	function _setState(bytes32 key, bytes memory val) internal {
		FunWallet(payable(msg.sender)).setState(key, val);
	}

	/**
	 * @dev Executes an operation from the context of the FunWallet contract.
	 * @param dest The destination address to execute the operation on.
	 * @param value The value to send with the transaction.
	 * @param data The data to be executed.
	 * @return The return data of the executed operation.
	 */
	function _executeFromFunWallet(address dest, uint256 value, bytes memory data) internal returns (bytes memory) {
		return FunWallet(payable(msg.sender)).execFromModule(dest, value, data);
	}

	function payFee() public virtual {}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

library CallLib {
	/**
	 * invoke the downstream module contract to execute the action
	 * @param dest the destination address to forward the call to
	 * @param value the amount of ether to forward to @dest
	 * @param data the call data
	 * @return result the bytes result returned from the downstream call
	 */
	function exec(address dest, uint256 value, bytes memory data) internal returns (bytes memory) {
		(bool success, bytes memory result) = payable(dest).call{value: value}(data);
		if (success == false) {
			assembly {
				revert(add(result, 32), mload(result))
			}
		}
		return result;
	}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "./HashLib.sol";
import "../interfaces/wallet/IFunWallet.sol";
import "../interfaces/wallet/IWalletFee.sol";

struct ExtraParams {
	bytes32[] targetMerkleProof;
	bytes32[] selectorMerkleProof;
	bytes32[] recipientMerkleProof;
	bytes32[] tokenMerkleProof;
}

struct ValidationData {
	address aggregator;
	uint48 validAfter;
	uint48 validUntil;
}

library DataLib {
	/**
	 * @notice Extracts authType, userId, and signature from UserOperation.signature.
	 * @param signature The UserOperation of the user.
	 * @return authType Attempted authentication method of user.
	 * @return userId Attempted identifier of user.
	 * @return roleId Attempted identifier of user role.
	 * @return ruleId Attempted identifier of user rule.
	 * @return signature Attempted signature of user.
	 * @return simulate Attempted in simulate mode.
	 */
	function getAuthData(bytes memory signature) internal pure returns (uint8, bytes32, bytes32, bytes32, bytes memory, ExtraParams memory) {
		return abi.decode(signature, (uint8, bytes32, bytes32, bytes32, bytes, ExtraParams));
	}

	/**
	 * @notice Extracts the relevant data from the callData parameter.
	 * @param callData The calldata containing the user operation details.
	 * @return to The target address of the call.
	 * @return value The value being transferred in the call.
	 * @return data The data payload of the call.
	 * @return fee The fee details of the user operation (if present).
	 * @return feeExists Boolean indicating whether a fee exists in the user operation.
	 * @dev This function decodes the callData parameter and extracts the target address, value, data, and fee (if present) based on the function selector.
	 * @dev If the function selector matches `execFromEntryPoint`, the to, value, and data are decoded.
	 * @dev If the function selector matches `execFromEntryPointWithFee`, the to, value, data, and fee are decoded, and feeExists is set to true.
	 * @dev If the function selector doesn't match any supported functions, the function reverts with an error message "FW600".
	 */
	function getCallData(
		bytes calldata callData
	) internal pure returns (address to, uint256 value, bytes memory data, UserOperationFee memory fee, bool feeExists) {
		if (bytes4(callData[:4]) == IWalletFee.execFromEntryPoint.selector) {
			(to, value, data) = abi.decode(callData[4:], (address, uint256, bytes));
		} else if (bytes4(callData[:4]) == IWalletFee.execFromEntryPointWithFee.selector) {
			(to, value, data, fee) = abi.decode(callData[4:], (address, uint256, bytes, UserOperationFee));
			feeExists = true;
		} else {
			revert("FW600");
		}
	}

	/**
	 * @notice Validates the Merkle proof provided to verify the existence of a leaf in a Merkle tree. It doesn't validate the proof length or hash the leaf.
	 * @param root The root of the Merkle tree.
	 * @param leaf The leaf which existence in the Merkle tree is being verified.
	 * @param proof An array of bytes32 that represents the Merkle proof.
	 * @return Returns true if the computed hash equals the root, i.e., the leaf exists in the tree.
	 * @dev This function assumes that the leaf passed into it has already been hashed. 
	 		This is a safe assumption as all current invocations of this function adhere to this standard. 
			Future uses of this function should ensure that the leaf input is hashed to maintain safety. Avoid calling in unsafe contexts.
			Otherwise, a user could just pass in a leaf where leaf == merkleRoot and an empty bytes array for the merkle proof to successfully validate any merkle root
	 */
	function validateMerkleRoot(bytes32 root, bytes32 leaf, bytes32[] memory proof) internal pure returns (bool) {
		bytes32 computedHash = leaf;
		for (uint256 i = 0; i < proof.length; ++i) {
			bytes32 proofElement = proof[i];
			if (computedHash < proofElement) {
				computedHash = HashLib.hash2(computedHash, proofElement);
			} else {
				computedHash = HashLib.hash2(proofElement, computedHash);
			}
		}
		return computedHash == root;
	}

	/**
	 * @notice Parses the validation data and returns a ValidationData struct.
	 * @param validationData An unsigned integer from which the validation data is extracted.
	 * @return data Returns a ValidationData struct containing the aggregator address, validAfter, and validUntil timestamps.
	 */
	function parseValidationData(uint validationData) internal pure returns (ValidationData memory data) {
		address aggregator = address(uint160(validationData));
		uint48 validUntil = uint48(validationData >> 160);
		uint48 validAfter = uint48(validationData >> (48 + 160));
		return ValidationData(aggregator, validAfter, validUntil);
	}

	/**
	 * @notice Composes a ValidationData struct into an unsigned integer.
	 * @param data A ValidationData struct containing the aggregator address, validAfter, and validUntil timestamps.
	 * @return validationData Returns an unsigned integer representation of the ValidationData struct.
	 */
	function getValidationData(ValidationData memory data) internal pure returns (uint256 validationData) {
		return uint160(data.aggregator) | (uint256(data.validUntil) << 160) | (uint256(data.validAfter) << (160 + 48));
	}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

library HashLib {
	/**
	 * Keccak256 all parameters together
	 * @param a bytes32
	 */
	function hash1(bytes32 a) internal pure returns (bytes32 _hash) {
		assembly {
			mstore(0x0, a)
			_hash := keccak256(0x00, 0x20)
		}
	}

	function hash1(address a) internal pure returns (bytes32 _hash) {
		assembly {
			mstore(0x0, a)
			_hash := keccak256(0x00, 0x20)
		}
	}

	function hash2(bytes32 a, bytes32 b) internal pure returns (bytes32 _hash) {
		assembly {
			mstore(0x0, a)
			mstore(0x20, b)
			_hash := keccak256(0x00, 0x40)
		}
	}

	function hash2(bytes32 a, address b) internal pure returns (bytes32 _hash) {
		bytes20 _b = bytes20(b);
		assembly {
			mstore(0x0, a)
			mstore(0x20, _b)
			_hash := keccak256(0x00, 0x34)
		}
	}

	function hash2(address a, address b) internal pure returns (bytes32 _hash) {
		bytes20 _a = bytes20(a);
		bytes20 _b = bytes20(b);
		assembly {
			mstore(0x0, _a)
			mstore(0x14, _b)
			_hash := keccak256(0x00, 0x28)
		}
	}

	function hash2(address a, uint8 b) internal pure returns (bytes32 _hash) {
		bytes20 _a = bytes20(a);
		bytes1 _b = bytes1(b);

		assembly {
			mstore(0x0, _b)
			mstore(0x1, _a)
			_hash := keccak256(0x00, 0x15)
		}
	}

	function hash2(bytes32 a, uint8 b) internal pure returns (bytes32 _hash) {
		bytes1 _b = bytes1(b);
		assembly {
			mstore(0x0, _b)
			mstore(0x1, a)
			_hash := keccak256(0x00, 0x21)
		}
	}

	function hash3(address a, address b, uint8 c) internal pure returns (bytes32 _hash) {
		bytes20 _a = bytes20(a);
		bytes20 _b = bytes20(b);
		bytes1 _c = bytes1(c);
		assembly {
			mstore(0x00, _c)
			mstore(0x01, _a)
			mstore(0x15, _b)
			_hash := keccak256(0x00, 0x29)
		}
	}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "../interfaces/eip-4337/IAccount.sol";
import "../interfaces/wallet/IFunWallet.sol";
import "../interfaces/wallet/IModule.sol";
import "../interfaces/deploy/IFunWalletFactory.sol";

import "../callback/TokenCallbackHandler.sol";

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import "./WalletState.sol";
import "./WalletModules.sol";
import "./WalletFee.sol";
import "./WalletValidation.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title FunWallet Contract
 * @dev This contract implements the `IFunWallet` interface, and it is upgradeable using the `UUPSUpgradeable` contract.
 */
contract FunWallet is
	IFunWallet,
	IAccount,
	Initializable,
	UUPSUpgradeable,
	TokenCallbackHandler,
	WalletState,
	WalletFee,
	WalletModules,
	WalletValidation
{
	using SafeERC20 for IERC20;
	/// @dev This constant is used to define the version of this contract.
	uint256 public constant VERSION = 1;

	IFunWalletFactory public factory;
	uint256[50] private __gap;

	constructor() {
		_disableInitializers();
	}

	function initialize(IEntryPoint _newEntryPoint, bytes calldata validationInitData) public initializer {
		require(address(_newEntryPoint) != address(0), "FW500");
		require(msg.sender != address(this), "FW501");
		factory = IFunWalletFactory(msg.sender);
		_entryPoint = _newEntryPoint;
		initValidations(validationInitData);
		emit EntryPointChanged(address(_newEntryPoint));
	}

	/**
	 * @notice Transfer ERC20 tokens from the wallet to a destination address.
	 * @param token ERC20 token address
	 * @param dest Destination address
	 * @param amount Amount of tokens to transfer
	 */
	function transferErc20(address token, address dest, uint256 amount) external {
		_requireFromFunWalletProxy();
		IERC20(token).safeTransfer(dest, amount);
		emit TransferERC20(token, dest, amount);
	}

	/**
	 * @dev Validate user's signature, nonce, and permission.
	 * @param userOp The user operation
	 * @param userOpHash The hash of the user operation
	 * @param missingAccountFunds The amount of missing funds that need to be prefunded to the wallet.
	 * @return sigTimeRange The signature time range for the operation.
	 */
	function validateUserOp(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		uint256 missingAccountFunds
	) external override returns (uint256 sigTimeRange) {
		_requireFromEntryPoint();
		sigTimeRange = _validateUserOp(userOp, userOpHash);
		_payPrefund(missingAccountFunds);
		emit UserOpValidated(userOpHash, userOp, sigTimeRange, missingAccountFunds);
	}

	/**
	 * @notice Validates the user's signature,  and permission for an action.
	 * @param target The address of the contract being called.
	 * @param value The value being transferred in the action.
	 * @param data The calldata for the action.
	 * @param signature The user's signature for the action.
	 * @param _hash The hash of the user operation.
	 * @return out A boolean indicating whether the action is valid.
	 */
	function isValidAction(
		address target,
		uint256 value,
		bytes memory data,
		bytes memory signature,
		bytes32 _hash
	) external view override returns (uint256 out) {
		out = _isValidAction(target, value, data, signature, _hash);
	}

	/**
	 * @notice Update the entry point for this contract
	 * @param _newEntryPoint The address of the new entry point.
	 */
	function updateEntryPoint(IEntryPoint _newEntryPoint) external override {
		_requireFromFunWalletProxy();
		require(address(_newEntryPoint) != address(0), "FW503");
		_entryPoint = _newEntryPoint;
		emit EntryPointChanged(address(_newEntryPoint));
	}

	/**
	 * @notice deposit to entrypoint to prefund the execution.
	 * @dev This function can only be called by the owner of the contract.
	 * @param amount the amount to deposit.
	 */
	function depositToEntryPoint(uint256 amount) external override {
		_requireFromFunWalletProxy();
		require(address(this).balance >= amount, "FW504");
		_entryPoint.depositTo{value: amount}(address(this));
		emit DepositToEntryPoint(amount);
	}

	/**
	 * @notice withdraw deposit from entrypoint
	 * @dev This function can only be called by the owner of the contract.
	 * @param withdrawAddress the address to withdraw Eth to
	 * @param amount the amount to be withdrawn
	 */
	function withdrawFromEntryPoint(address payable withdrawAddress, uint256 amount) external override {
		_requireFromFunWalletProxy();
		_transferEthFromEntrypoint(withdrawAddress, amount);
		emit WithdrawFromEntryPoint(withdrawAddress, amount);
	}

	function _transferEthFromEntrypoint(address payable recipient, uint256 amount) internal override {
		try _entryPoint.withdrawTo(recipient, amount) {} catch Error(string memory revertReason) {
			revert(string.concat("FW505: ", revertReason));
		} catch {
			revert("FW505");
		}
	}

	/**
	 * sends to the entrypoint (msg.sender) the missing funds for this transaction.
	 * subclass MAY override this method for better funds management
	 * (e.g. send to the entryPoint more than the minimum required, so that in future transactions
	 * it will not be required to send again)
	 * @param missingAccountFunds the minimum value this method should send the entrypoint.
	 *  this value MAY be zero, in case there is enough deposit, or the userOp has a paymaster.
	 */
	function _payPrefund(uint256 missingAccountFunds) internal {
		if (missingAccountFunds != 0) {
			(bool success, ) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
			(success);
			//ignore failure (its EntryPoint's job to verify, not account.)
		}
	}

	// Checks if module calling wallet was deployed from the same base create3deployer
	function _requireFromModule() internal override {
		bool storedKey;
		bytes32 senderBytes = bytes32(uint256(uint160(msg.sender)));
		bytes32 moduleWhitelistKey = HashLib.hash1(senderBytes);
		assembly {
			storedKey := sload(moduleWhitelistKey)
		}
		if (storedKey) return;
		bytes32 key = IModule(msg.sender).moduleId();
		require(factory.verifyDeployedFrom(key, msg.sender), "FW506");
		assembly {
			sstore(moduleWhitelistKey, 0x01)
		}
	}

	function setState(bytes32 key, bytes calldata val) public override {
		_requireFromModule();
		_setState(key, val);
	}

	function setState32(bytes32 key, bytes32 val) public override {
		_requireFromModule();
		_setState32(key, val);
	}

	function _requireFromFunWalletProxy() internal view {
		require(msg.sender == address(this), "FW502");
	}

	function _requireFromEntryPoint() internal view override(WalletExec, WalletValidation) {
		require(msg.sender == address(_entryPoint), "FW507");
	}

	function _getOracle() internal view override returns (address payable) {
		return factory.getFeeOracle();
	}

	/**
	 * builtin method to support UUPS upgradability
	 */
	function _authorizeUpgrade(address) internal view override {
		require(msg.sender == address(this), "FW502");
	}

	/**
	 * @notice Get the entry point for this contract
	 * @dev This function returns the contract's entry point interface.
	 * @return The contract's entry point interface.
	 */
	function entryPoint() external view override returns (IEntryPoint) {
		return _entryPoint;
	}

	receive() external payable {}

	event TransferERC20(address indexed token, address indexed dest, uint256 amount);
	event DepositToEntryPoint(uint256 amount);
	event UserOpValidated(bytes32 indexed userOpHash, UserOperation userOp, uint256 sigTimeRange, uint256 missingAccountFunds);
	event WithdrawFromEntryPoint(address indexed withdrawAddress, uint256 amount);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "../utils/CallLib.sol";

abstract contract WalletExec {
	uint256[50] private __gap;

	/**
	 * @notice this method is used by module to perform any external calls from fun wallet
	 * @dev only a known module is allowed to invoke this method.
	 * @param dest the address of the external contract to be called
	 * @param value the amount of ether to forward
	 * @param data the call data to the external contract
	 * @return result the returned result from external contract call
	 */
	function execFromModule(address dest, uint256 value, bytes calldata data) external payable returns (bytes memory) {
		_requireFromModule();
		return CallLib.exec(dest, value, data);
	}

	/**
	 * @notice this method is used to execute the downstream module
	 * @dev only entrypoint or owner is allowed to invoke this method.
	 * @param dest the address of the module to be called
	 * @param value the amount of ether to forward
	 * @param data the call data to the downstream module
	 */
	function execFromEntryPoint(address dest, uint256 value, bytes calldata data) public virtual {
		_requireFromEntryPoint();
		CallLib.exec(dest, value, data);
	}

	/**
	 * @notice Executes batched operations on a collection of downstream modules.
	 * @dev This function can only be invoked by an owner or user with privilege granted.
	 * @dev Giving a user access to this function is the same as giving them owner access 
	 		as no validation checks are being made on the batched calls.
	 * @param dest An array of the addresses for the modules to be called.
	 * @param value An array of ether amounts to forward to each module.
	 * @param data An array of call data to send to each downstream module.
	 */
	function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata data) public virtual {
		require(msg.sender == address(this), "FW502");
		require(dest.length == value.length && dest.length == data.length, "FW524");
		for (uint8 i = 0; i < dest.length; ++i) {
			CallLib.exec(dest[i], value[i], data[i]);
		}
	}

	function _requireFromModule() internal virtual;

	function _requireFromEntryPoint() internal view virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "./WalletExec.sol";

import "../interfaces/wallet/IFunWallet.sol";
import "../interfaces/wallet/IWalletFee.sol";
import "../interfaces/oracles/IFeePercentOracle.sol";

abstract contract WalletFee is WalletExec, IWalletFee {
	uint256[50] private __gap;

	function _transferEth(address payable recipient, uint256 amount) internal {
		if (address(this).balance < amount) {
			_transferEthFromEntrypoint(recipient, amount);
		} else {
			(bool success, ) = payable(recipient).call{value: amount}("");
			require(success, "FW508");
		}
	}

	function _handleFee(UserOperationFee memory feedata) internal {
		address payable funOracle = _getOracle();
		(uint256 funCut, uint256 developerCut) = IFeePercentOracle(funOracle).getFee(feedata.amount);
		if (feedata.token == address(0)) {
			_transferEth(feedata.recipient, developerCut);
			_transferEth(funOracle, funCut);
		} else {
			if (developerCut != 0) {
				try IFunWallet(address(this)).transferErc20(feedata.token, feedata.recipient, developerCut) {} catch {
					revert("FW510");
				}
			}
			if (funCut != 0) {
				try IFunWallet(address(this)).transferErc20(feedata.token, funOracle, funCut) {} catch {
					revert("FW509");
				}
			}
		}
	}

	/**
	 * @notice this method is used to execute the downstream module
	 * @dev only entrypoint or owner is allowed to invoke this method.
	 * @param dest the address of the module to be called
	 * @param value the amount of ether to forward
	 * @param data the call data to the downstream module
	 * @param feedata UserOperationFee struct containing fee data
	 */

	function execFromEntryPointWithFee(address dest, uint256 value, bytes calldata data, UserOperationFee memory feedata) public override {
		execFromEntryPoint(dest, value, data);
		_handleFee(feedata);
	}

	function execFromEntryPoint(address dest, uint256 value, bytes calldata data) public override(IWalletFee, WalletExec) {
		super.execFromEntryPoint(dest, value, data);
	}

	function _getOracle() internal view virtual returns (address payable);

	function _transferEthFromEntrypoint(address payable recipient, uint256 amount) internal virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "../utils/DataLib.sol";
import "../interfaces/wallet/IFunWallet.sol";
import "../interfaces/wallet/IValidation.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract WalletModules {
	using SafeERC20 for IERC20;
	mapping(uint32 => uint224) public permitNonces;
	uint256[50] private __gap;

	bytes32 public constant salt = keccak256("Create3Deployer.deployers()");
	bytes32 public constant EIP712_DOMAIN =
		keccak256(abi.encode("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"));
	string public constant PERMIT_TYPEHASH = "PermitTransferStruct(address token,address to,uint256 amount,uint256 nonce)";

	/**
	 * @notice generates correct hash for signature.
	 * @param token token to transfer.
	 * @param to address to transfer tokens to.
	 * @param amount amount of tokens to transfer.
	 * @param nonce nonce to check against signature data with.
	 * @return _hash hash of permit data.
	 */

	function getPermitHash(address token, address to, uint256 amount, uint256 nonce) public view returns (bytes32) {
		bytes32 DOMAIN_SEPARATOR = keccak256(abi.encode(EIP712_DOMAIN, salt, keccak256("1"), block.chainid, address(this), salt));
		return keccak256(abi.encodePacked(DOMAIN_SEPARATOR, keccak256(abi.encode(PERMIT_TYPEHASH, token, to, amount, nonce))));
	}

	/**
	 * @notice gets nonce for a key.
	 * @param key base of nonce.
	 */
	function getNonce(uint32 key) external view returns (uint256 out) {
		out = (uint256(key) << 224) | permitNonces[key];
	}

	/**
	 * @notice Validates and executes permit based transfer.
	 * @param token token to transfer.
	 * @param to address to transfer tokens to.
	 * @param amount amount of tokens to transfer.
	 * @param nonce nonce to check against signature data with.
	 * @param sig signature of permit hash.
	 * @return true if transfer was successful
	 */
	function permitTransfer(address token, address to, uint256 amount, uint256 nonce, bytes calldata sig) external returns (bool) {
		uint256 sigTimeRange = validatePermit(token, to, amount, nonce, sig);
		ValidationData memory data = DataLib.parseValidationData(sigTimeRange);
		bool validPermitSignature = sigTimeRange == 0 ||
			(uint160(sigTimeRange) == 0 && (block.timestamp <= data.validUntil && block.timestamp >= data.validAfter));
		require(validPermitSignature, "FW523");

		++permitNonces[uint32(nonce >> 224)];
		try IFunWallet(address(this)).transferErc20(token, to, amount) {
			return true;
		} catch Error(string memory out) {
			revert(string.concat("FW701: ", out));
		}
	}

	/**
	 * @notice Validates permit based transfer.
	 * @param token token to transfer.
	 * @param to address to transfer tokens to.
	 * @param amount amount of tokens to transfer.
	 * @param nonce nonce to check against signature data with.
	 * @param sig signature of permit hash.
	 */
	function validatePermit(address token, address to, uint256 amount, uint256 nonce, bytes calldata sig) public view returns (uint256) {
		bytes32 _hash = getPermitHash(token, to, amount, nonce);
		/** 
			since validatePermit and permitTransfer have the same parameters we replace the selector of the call to validate
			to get the calldata for permitTransfer 
		 */
		bytes memory data = msg.data;
		for (uint256 i = 0; i < 4; ++i) {
			data[i] = this.permitTransfer.selector[i];
		}
		require(permitNonces[uint32(nonce >> 224)] == uint224(nonce), "FW700");
		return IValidation(address(this)).isValidAction(address(this), 0, data, sig, _hash);
	}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "../interfaces/eip-4337/IEntryPoint.sol";
import "../interfaces/wallet/IWalletState.sol";
import "../utils/HashLib.sol";

abstract contract WalletState is IWalletState {
	IEntryPoint internal _entryPoint;
	// it is publicly readable but only modifiable by the module contract itself
	mapping(bytes32 => bytes) internal moduleState;
	uint256[50] private __gap;

	/**
	 * Get the stored state of a module
	 * @param key the key a module would like to get
	 */
	function getState(bytes32 key) public view returns (bytes memory) {
		return moduleState[key];
	}

	/**
	 * Set the stored state of a module
	 * @param key the key a module would like to store
	 * @param val the value a module would like to store
	 */
	function _setState(bytes32 key, bytes calldata val) internal {
		key = HashLib.hash2(key, msg.sender);
		moduleState[key] = val;
	}

	/**
	 * Get the stored 32 bytes word of a module
	 * @param key the key a module would like to get
	 */
	function getState32(bytes32 key) public view returns (bytes32 out) {
		assembly {
			out := sload(key)
		}
	}

	/**
	 * Get the stored 32 bytes word of a specific module
	 * @param key the key a module would like to get
	 */
	function getState32WithAddr(bytes32 key, address addr) public view returns (bytes32 out) {
		key = HashLib.hash2(key, addr);
		assembly {
			out := sload(key)
		}
	}

	/**
	 * Set the stored 32 bytes word of a module
	 * @param key the key a module would like to store
	 * @param val the value a module would like to store
	 */
	function _setState32(bytes32 key, bytes32 val) internal {
		key = HashLib.hash2(key, msg.sender);
		assembly {
			sstore(key, val)
		}
	}

	function setState(bytes32, bytes calldata) public virtual {
		revert("MUST OVERRIDE");
	}

	function setState32(bytes32, bytes32) public virtual {
		revert("MUST OVERRIDE");
	}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "../utils/DataLib.sol";
import "../interfaces/wallet/IValidation.sol";

/**
 * @title WalletValidation - Manages FunWallet Validation Contracts
 * @dev Uses a linked list to store the validations because the code generated by the solidity compiler
 *      is more efficient than using a dynamic array. Adapted from Safe Multisig Wallet by Gnosis.
 * @author Caleb Sirak - @csirak1528
 */

contract WalletValidation {
	mapping(address => address) internal validations;
	uint256 private validationCount;
	uint256[50] private __gap;
	address private constant RANGE_LIMITER = address(1);

	/**
	 * @notice Sets the initial storage of the contract.
	 * @param validationData Abi encoded arrays of validation address's and the ambiguous init initCallData.
	 * @dev The validationData is encoded as follows: abi.encode([validationId1, validationId2, ...], [initCallData1, initCallData2, ...])
	 * @dev The validation is an address of a contract that implements IValidation.
	 * @dev The initCallData is ambiguous because it is dependent on the validation scheme of the wallet.
	 */
	function initValidations(bytes calldata validationData) public {
		// require no previous validations
		require(validations[RANGE_LIMITER] == address(0), "FW511");

		// decode parameters
		(address[] memory addrs, bytes[] memory initCallData) = abi.decode(validationData, (address[], bytes[]));

		// validate parameters lengths are the same and there are more than 0 validations
		require(addrs.length == initCallData.length && addrs.length > 0, "FW512");

		address currentAddr = RANGE_LIMITER;
		for (uint8 i = 0; i < initCallData.length; ++i) {
			require(currentAddr != addrs[i], "FW513");
			_requireValidValidation(addrs[i]);
			// link current validation to next validation
			validations[currentAddr] = addrs[i];
			currentAddr = addrs[i];
			IValidation(addrs[i]).init(initCallData[i]);
		}
		// link last validation
		validations[currentAddr] = RANGE_LIMITER;
		validationCount = addrs.length;
	}

	/**
	 * @notice Adds the verification `verification` calls the initalization dataa `initdata`.
	 * @param validation New verification address.
	 * @param initdata Ambiguous initalization data.
	 */
	function addValidation(address validation, bytes calldata initdata) public {
		require(msg.sender == address(this), "FW520");
		_requireValidValidation(validation);
		validations[validation] = validations[RANGE_LIMITER];
		validations[RANGE_LIMITER] = validation;
		++validationCount;

		if (initdata.length > 0) {
			IValidation(validation).init(initdata);
		}
	}

	/**
	 * @notice Removes the validation `validation` from the FunWallet.
	 * @param prevValidation Validation that pointed to the validation to be removed in the linked list
	 * @param validation Validation id to be removed.
	 */
	function removeValidation(address prevValidation, address validation) public {
		require(msg.sender == address(this), "FW521");
		_requireValidValidationFormat(validation, true);
		_requireValidPrevValidation(prevValidation, validation);
		validations[prevValidation] = validations[validation];
		validations[validation] = address(0);
		validationCount--;
	}

	/**
	 * @notice Replaces the validation `oldValidation` in the FunWallet with `newValidation`.
	 * @param prevValidation Validation that pointed to the validation to be replaced in the linked list
	 * @param oldValidation Validation id to be replaced.
	 * @param newValidation New validation id.
	 * @param newValidationInitData New validation ambiguous initialization data.
	 */
	function updateValidation(address prevValidation, address oldValidation, address newValidation, bytes calldata newValidationInitData) public {
		require(msg.sender == address(this), "FW522");
		_requireValidValidation(newValidation);
		_requireValidValidationFormat(oldValidation, true);
		_requireValidPrevValidation(prevValidation, oldValidation);
		validations[newValidation] = validations[oldValidation];
		validations[prevValidation] = newValidation;
		validations[oldValidation] = address(0);
		IValidation(newValidation).init(newValidationInitData);
	}

	/**
	 * @notice Returns the next validation in linked list.
	 * @param validation Validation id.
	 * @return Validation
	 */
	function getNextValidation(address validation) external view returns (address) {
		return validations[validation];
	}

	/**
	 * @notice Returns the validation count.
	 * @return uint256
	 */
	function getValidationCount() public view returns (uint256) {
		return validationCount;
	}

	/**
	 * @notice Returns a list of FunWallet validation contracts.
	 * @return Array of FunWallet validations.
	 */
	function getValidations() public view returns (address[] memory) {
		require(validationCount > 0, "FW525");
		address[] memory out = new address[](validationCount);
		uint256 index = 0;
		address currentValidation = validations[RANGE_LIMITER];
		while (currentValidation != RANGE_LIMITER) {
			out[index] = currentValidation;
			currentValidation = validations[currentValidation];
			++index;
		}
		return out;
	}

	/**
	 * @dev Validates a userop among all validations in the wallet.
	 * @notice If the any of the validations fail the function will return the first failed value.
	 * @param userOp The user operation
	 * @param userOpHash The hash of the user operation
	 * @return sigTimeRange The out of the validation. Expected values are 0 and 1 for pass and fail.
	 */
	function _validateUserOp(UserOperation calldata userOp, bytes32 userOpHash) internal view returns (uint256 sigTimeRange) {
		require(userOp.signature.length > 0, "FW514");
		address[] memory _validations = getValidations();
		sigTimeRange = 0;
		ValidationData memory data;
		data.validUntil = type(uint48).max;
		for (uint8 i = 0; i < _validations.length; ++i) {
			sigTimeRange = IValidation(_validations[i]).authenticateUserOp(userOp, userOpHash, "");
			if (uint160(sigTimeRange) != 0) {
				return sigTimeRange;
			}
			_updateValidationData(data, sigTimeRange);
		}
		if (data.validUntil == type(uint48).max) {
			data.validUntil = 0;
		}
		return DataLib.getValidationData(data);
	}

	/**
	 * @notice Checks if an action is valid based on target, value, data, signature, and hash.
	 * @param target The address of the contract being called.
	 * @param value The value being transferred in the action.
	 * @param data The calldata for the action.
	 * @param signature The user's signature for the action.
	 * @param _hash The hash of the user operation.
	 * @return sigTimeRange A boolean indicating whether the action is valid.

	 */
	function _isValidAction(address target, uint256 value, bytes memory data, bytes memory signature, bytes32 _hash) internal view returns (uint256) {
		address[] memory _validations = getValidations();
		ValidationData memory vdata;
		vdata.validUntil = type(uint48).max;
		for (uint8 i = 0; i < _validations.length; ++i) {
			uint256 sigTimeRange = IValidation(_validations[i]).isValidAction(target, value, data, signature, _hash);
			if (uint160(sigTimeRange) != 0) {
				return sigTimeRange;
			}
			_updateValidationData(vdata, sigTimeRange);
		}
		if (vdata.validUntil == type(uint48).max) {
			vdata.validUntil = 0;
		}
		return DataLib.getValidationData(vdata);
	}

	function _updateValidationData(ValidationData memory vdata, uint256 newData) internal pure {
		if (newData == 0) {
			return;
		}
		ValidationData memory tempdata = DataLib.parseValidationData(newData);
		if (vdata.validUntil > tempdata.validUntil && tempdata.validUntil != 0) {
			vdata.validUntil = tempdata.validUntil;
		}
		if (vdata.validAfter < tempdata.validAfter) {
			vdata.validAfter = tempdata.validAfter;
		}
	}

	/**
	 * @notice Returns true if `validation` is a validation of the FunWallet.
	 * @param validation validation contract address to check
	 * @return Boolean if validation is a validation of the FunWallet.
	 */
	function isValidation(address validation) public view returns (bool) {
		return validations[validation] != address(0) && validation != RANGE_LIMITER;
	}

	/**
	 * @notice Reverts if `validation` is already a validation or if `_requireValidValidation` with the `contractValid` flag set to false reverts.
	 * @param validation validation id to be tested.
	 */
	function _requireValidValidation(address validation) internal view {
		_requireValidValidationFormat(validation, false);
		require(!isValidation(validation), "FW516");
	}

	/**
	 * @notice Reverts if `validation` is equal to an id of zero, the RANGE_LIMITER or potentially the wallet address.
	 * @param validation validation id to be tested.
	 * @param contractValid If set to true then the validation id will not be checked against the wallet Address.
	 */
	function _requireValidValidationFormat(address validation, bool contractValid) internal view {
		require(validation != address(0) && validation != RANGE_LIMITER && (contractValid || validation != address(this)), "FW517");
	}

	/**
	 * @notice Reverts if `prevValidation` is not linked to the validation.
	 * @param prevValidation prevValidation to be tested.
	 * @param validation validation to be tested.
	 */
	function _requireValidPrevValidation(address prevValidation, address validation) internal view {
		require(validations[prevValidation] == validation, "FW518");
	}

	function _requireFromEntryPoint() internal view virtual {}
}