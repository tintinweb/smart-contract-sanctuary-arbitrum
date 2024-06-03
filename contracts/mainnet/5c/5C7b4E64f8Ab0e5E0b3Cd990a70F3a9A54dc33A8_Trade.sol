// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

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
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
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
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
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
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
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
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
 * ```
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
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

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// @title DataStore
// @dev DataStore for all general state values
contract DataStore {
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

import "./order/BaseOrderUtils.sol";

interface IExchangeRouter {
    function sendWnt(address receiver, uint256 amount) external payable;
    function sendTokens(address token, address receiver, uint256 amount) external payable;
    function createOrder(BaseOrderUtils.CreateOrderParams calldata params) external payable returns (bytes32);
    function cancelOrder(bytes32 key) external payable;
    function claimFundingFees(
        address[] memory markets,
        address[] memory tokens,
        address receiver
    ) external payable returns (uint256[] memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./market/Market.sol";
import "./data/DataStore.sol";
// @title Reader
// @dev Library for read functions
interface IReader {
    function getMarket(DataStore dataStore, address key) external view returns (Market.Props memory);
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

library Market {
    struct Props {
        address marketToken;
        address indexToken;
        address longToken;
        address shortToken;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Order.sol";

// @title Order
// @dev Library for common order functions used in OrderUtils, IncreaseOrderUtils
// DecreaseOrderUtils, SwapOrderUtils
library BaseOrderUtils {
    // @dev CreateOrderParams struct used in createOrder to avoid stack
    // too deep errors
    //
    // @param addresses address values
    // @param numbers number values
    // @param orderType for order.orderType
    // @param decreasePositionSwapType for order.decreasePositionSwapType
    // @param isLong for order.isLong
    // @param shouldUnwrapNativeToken for order.shouldUnwrapNativeToken
    struct CreateOrderParams {
        CreateOrderParamsAddresses addresses;
        CreateOrderParamsNumbers numbers;
        Order.OrderType orderType;
        Order.DecreasePositionSwapType decreasePositionSwapType;
        bool isLong;
        bool shouldUnwrapNativeToken;
        bytes32 referralCode;
    }

    // @param receiver for order.receiver
    // @param callbackContract for order.callbackContract
    // @param market for order.market
    // @param initialCollateralToken for order.initialCollateralToken
    // @param swapPath for order.swapPath
    struct CreateOrderParamsAddresses {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    // @param sizeDeltaUsd for order.sizeDeltaUsd
    // @param triggerPrice for order.triggerPrice
    // @param acceptablePrice for order.acceptablePrice
    // @param executionFee for order.executionFee
    // @param callbackGasLimit for order.callbackGasLimit
    // @param minOutputAmount for order.minOutputAmount
    struct CreateOrderParamsNumbers {
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

library Order {
    enum OrderType {
        MarketSwap,
        LimitSwap,
        MarketIncrease,
        LimitIncrease,
        MarketDecrease,
        LimitDecrease,
        StopLossDecrease,
        Liquidation
    }

    enum DecreasePositionSwapType {
        NoSwap,
        SwapPnlTokenToCollateralToken,
        SwapCollateralTokenToPnlToken
    }

    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    struct Numbers {
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
        uint256 updatedAtBlock;
    }

    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    struct Flags {
        bool isLong;
        bool shouldUnwrapNativeToken;
        bool isFrozen;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IPriceFeed {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library DataTypes {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62-63: reserved
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused

        uint256 data;
    }

    struct UserConfigurationMap {
        /**
         * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
         * The first bit indicates if an asset is used as collateral by the user, the second whether an
         * asset is borrowed by the user.
         */
        uint256 data;
    }

    struct EModeCategory {
        // each eMode category has a custom ltv and liquidation threshold
        uint16 ltv;
        uint16 liquidationThreshold;
        uint16 liquidationBonus;
        // each eMode category may or may not have a custom oracle to override the individual assets price oracles
        address priceSource;
        string label;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }

    struct ReserveCache {
        uint256 currScaledVariableDebt;
        uint256 nextScaledVariableDebt;
        uint256 currPrincipalStableDebt;
        uint256 currAvgStableBorrowRate;
        uint256 currTotalStableDebt;
        uint256 nextAvgStableBorrowRate;
        uint256 nextTotalStableDebt;
        uint256 currLiquidityIndex;
        uint256 nextLiquidityIndex;
        uint256 currVariableBorrowIndex;
        uint256 nextVariableBorrowIndex;
        uint256 currLiquidityRate;
        uint256 currVariableBorrowRate;
        uint256 reserveFactor;
        ReserveConfigurationMap reserveConfiguration;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        uint40 reserveLastUpdateTimestamp;
        uint40 stableDebtLastUpdateTimestamp;
    }

    struct ExecuteLiquidationCallParams {
        uint256 reservesCount;
        uint256 debtToCover;
        address collateralAsset;
        address debtAsset;
        address user;
        bool receiveAToken;
        address priceOracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteSupplyParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint16 referralCode;
        bool releaseUnderlying;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteRepayParams {
        address asset;
        uint256 amount;
        InterestRateMode interestRateMode;
        address onBehalfOf;
        bool useATokens;
    }

    struct ExecuteWithdrawParams {
        address asset;
        uint256 amount;
        address to;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ExecuteSetUserEModeParams {
        uint256 reservesCount;
        address oracle;
        uint8 categoryId;
    }

    struct FinalizeTransferParams {
        address asset;
        address from;
        address to;
        uint256 amount;
        uint256 balanceFromBefore;
        uint256 balanceToBefore;
        uint256 reservesCount;
        address oracle;
        uint8 fromEModeCategory;
    }

    struct FlashloanParams {
        address receiverAddress;
        address[] assets;
        uint256[] amounts;
        uint256[] interestRateModes;
        address onBehalfOf;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address addressesProvider;
        uint8 userEModeCategory;
        bool isAuthorizedFlashBorrower;
    }

    struct FlashloanSimpleParams {
        address receiverAddress;
        address asset;
        uint256 amount;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
    }

    struct FlashLoanRepaymentParams {
        uint256 amount;
        uint256 totalPremium;
        uint256 flashLoanPremiumToProtocol;
        address asset;
        address receiverAddress;
        uint16 referralCode;
    }

    struct CalculateUserAccountDataParams {
        UserConfigurationMap userConfig;
        uint256 reservesCount;
        address user;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ValidateBorrowParams {
        ReserveCache reserveCache;
        UserConfigurationMap userConfig;
        address asset;
        address userAddress;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint256 maxStableLoanPercent;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
        bool isolationModeActive;
        address isolationModeCollateralAddress;
        uint256 isolationModeDebtCeiling;
    }

    struct ValidateLiquidationCallParams {
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        address priceOracleSentinel;
    }

    struct CalculateInterestRatesParams {
        uint256 unbacked;
        uint256 liquidityAdded;
        uint256 liquidityTaken;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        uint256 averageStableBorrowRate;
        uint256 reserveFactor;
        address reserve;
        address aToken;
    }

    struct InitReserveParams {
        address asset;
        address aTokenAddress;
        address stableDebtAddress;
        address variableDebtAddress;
        address interestRateStrategyAddress;
        uint16 reservesCount;
        uint16 maxNumberReserves;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";
import {DataTypes} from "./DataTypes.sol";

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface IPool {
    /**
     * @dev Emitted on mintUnbacked()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
     * @param amount The amount of supplied assets
     * @param referralCode The referral code used
     **/
    event MintUnbacked(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on backUnbacked()
     * @param reserve The address of the underlying asset of the reserve
     * @param backer The address paying for the backing
     * @param amount The amount added as backing
     * @param fee The amount paid in fees
     **/
    event BackUnbacked(
        address indexed reserve,
        address indexed backer,
        uint256 amount,
        uint256 fee
    );

    /**
     * @dev Emitted on supply()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
     * @param amount The amount supplied
     * @param referralCode The referral code used
     **/
    event Supply(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlying asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to The address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
     * @param referralCode The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 borrowRate,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     * @param useATokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
     **/
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount,
        bool useATokens
    );

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
     **/
    event SwapBorrowRateMode(
        address indexed reserve,
        address indexed user,
        DataTypes.InterestRateMode interestRateMode
    );

    /**
     * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
     * @param asset The address of the underlying asset of the reserve
     * @param totalDebt The total isolation mode debt for the reserve
     */
    event IsolationModeTotalDebtUpdated(
        address indexed asset,
        uint256 totalDebt
    );

    /**
     * @dev Emitted when the user selects a certain asset category for eMode
     * @param user The address of the user
     * @param categoryId The category id
     **/
    event UserEModeSet(address indexed user, uint8 categoryId);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     **/
    event FlashLoan(
        address indexed target,
        address initiator,
        address indexed asset,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 premium,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted when a borrower is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated.
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The next liquidity rate
     * @param stableBorrowRate The next stable borrow rate
     * @param variableBorrowRate The next variable borrow rate
     * @param liquidityIndex The next liquidity index
     * @param variableBorrowIndex The next variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
     * @param reserve The address of the reserve
     * @param amountMinted The amount minted to the treasury
     **/
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);

    /**
     * @dev Mints an `amount` of aTokens to the `onBehalfOf`
     * @param asset The address of the underlying asset to mint
     * @param amount The amount to mint
     * @param onBehalfOf The address that will receive the aTokens
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function mintUnbacked(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Back the current unbacked underlying with `amount` and pay `fee`.
     * @param asset The address of the underlying asset to back
     * @param amount The amount to back
     * @param fee The amount paid in fees
     **/
    function backUnbacked(
        address asset,
        uint256 amount,
        uint256 fee
    ) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Supply with transfer approval of asset to be supplied done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param deadline The deadline timestamp that the permit is valid
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     **/
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @notice Repay with transfer approval of asset to be repaid done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @param deadline The deadline timestamp that the permit is valid
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     * @return The final amount repaid
     **/
    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
     * equivalent debt tokens
     * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
     * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
     * balance is not enough to cover the whole debt
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @return The final amount repaid
     **/
    function repayWithATokens(
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) external returns (uint256);

    /**
     * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
     * @param asset The address of the underlying asset borrowed
     * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
     **/
    function swapBorrowRateMode(address asset, uint256 interestRateMode)
        external;

    /**
     * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
     *        much has been borrowed at a stable rate and suppliers are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
     * @param asset The address of the underlying asset supplied
     * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        external;

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts of the assets being flash-borrowed
     * @param interestRateModes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
     * @param asset The address of the asset being flash-borrowed
     * @param amount The amount of the asset being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    /**
     * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
     * interest rate strategy
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param aTokenAddress The address of the aToken that will be assigned to the reserve
     * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
     * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
     * @param interestRateStrategyAddress The address of the interest rate strategy contract
     **/
    function initReserve(
        address asset,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    /**
     * @notice Drop a reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     **/
    function dropReserve(address asset) external;

    /**
     * @notice Updates the address of the interest rate strategy contract
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param rateStrategyAddress The address of the interest rate strategy contract
     **/
    function setReserveInterestRateStrategyAddress(
        address asset,
        address rateStrategyAddress
    ) external;

    /**
     * @notice Sets the configuration bitmap of the reserve as a whole
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param configuration The new configuration bitmap
     **/
    function setConfiguration(
        address asset,
        DataTypes.ReserveConfigurationMap calldata configuration
    ) external;

    /**
     * @notice Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @notice Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user)
        external
        view
        returns (DataTypes.UserConfigurationMap memory);

    /**
     * @notice Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);

    /**
     * @notice Validates and finalizes an aToken transfer
     * @dev Only callable by the overlying aToken of the `asset`
     * @param asset The address of the underlying asset of the aToken
     * @param from The user from which the aTokens are transferred
     * @param to The user receiving the aTokens
     * @param amount The amount being transferred/withdrawn
     * @param balanceFromBefore The aToken balance of the `from` user before the transfer
     * @param balanceToBefore The aToken balance of the `to` user before the transfer
     */
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;

    /**
     * @notice Returns the list of the underlying assets of all the initialized reserves
     * @dev It does not include dropped reserves
     * @return The addresses of the underlying assets of the initialized reserves
     **/
    function getReservesList() external view returns (address[] memory);

    /**
     * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
     * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
     * @return The address of the reserve associated with id
     **/
    function getReserveAddressById(uint16 id) external view returns (address);

    /**
     * @notice Returns the PoolAddressesProvider connected to this contract
     * @return The address of the PoolAddressesProvider
     **/
    function ADDRESSES_PROVIDER()
        external
        view
        returns (IPoolAddressesProvider);

    /**
     * @notice Updates the protocol fee on the bridging
     * @param bridgeProtocolFee The part of the premium sent to the protocol treasury
     */
    function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external;

    /**
     * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
     * - A part is sent to aToken holders as extra, one time accumulated interest
     * - A part is collected by the protocol treasury
     * @dev The total premium is calculated on the total borrowed amount
     * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
     * @dev Only callable by the PoolConfigurator contract
     * @param flashLoanPremiumTotal The total premium, expressed in bps
     * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
     */
    function updateFlashloanPremiums(
        uint128 flashLoanPremiumTotal,
        uint128 flashLoanPremiumToProtocol
    ) external;

    /**
     * @notice Configures a new category for the eMode.
     * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
     * The category 0 is reserved as it's the default for volatile assets
     * @param id The id of the category
     * @param config The configuration of the category
     */
    function configureEModeCategory(
        uint8 id,
        DataTypes.EModeCategory memory config
    ) external;

    /**
     * @notice Returns the data of an eMode category
     * @param id The id of the category
     * @return The configuration data of the category
     */
    function getEModeCategoryData(uint8 id)
        external
        view
        returns (DataTypes.EModeCategory memory);

    /**
     * @notice Allows a user to use the protocol in eMode
     * @param categoryId The id of the category
     */
    function setUserEMode(uint8 categoryId) external;

    /**
     * @notice Returns the eMode the user is using
     * @param user The address of the user
     * @return The eMode id
     */
    function getUserEMode(address user) external view returns (uint256);

    /**
     * @notice Resets the isolation mode total debt of the given asset to zero
     * @dev It requires the given asset has zero debt ceiling
     * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
     */
    function resetIsolationModeTotalDebt(address asset) external;

    /**
     * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
     * @return The percentage of available liquidity to borrow, expressed in bps
     */
    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT()
        external
        view
        returns (uint256);

    /**
     * @notice Returns the total fee on flash loans
     * @return The total fee on flashloans
     */
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    /**
     * @notice Returns the part of the bridge fees sent to protocol
     * @return The bridge fee sent to the protocol treasury
     */
    function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

    /**
     * @notice Returns the part of the flashloan fees sent to protocol
     * @return The flashloan fee sent to the protocol treasury
     */
    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

    /**
     * @notice Returns the maximum number of reserves supported to be listed in this Pool
     * @return The maximum number of reserves supported
     */
    function MAX_NUMBER_RESERVES() external view returns (uint16);

    /**
     * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
     * @param assets The list of reserves for which the minting needs to be executed
     **/
    function mintToTreasury(address[] calldata assets) external;

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @dev Deprecated: Use the `supply` function instead
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface IPoolAddressesProvider {
    /**
     * @dev Emitted when the market identifier is updated.
     * @param oldMarketId The old id of the market
     * @param newMarketId The new id of the market
     */
    event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

    /**
     * @dev Emitted when the pool is updated.
     * @param oldAddress The old address of the Pool
     * @param newAddress The new address of the Pool
     */
    event PoolUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the pool configurator is updated.
     * @param oldAddress The old address of the PoolConfigurator
     * @param newAddress The new address of the PoolConfigurator
     */
    event PoolConfiguratorUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the price oracle is updated.
     * @param oldAddress The old address of the PriceOracle
     * @param newAddress The new address of the PriceOracle
     */
    event PriceOracleUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the ACL manager is updated.
     * @param oldAddress The old address of the ACLManager
     * @param newAddress The new address of the ACLManager
     */
    event ACLManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the ACL admin is updated.
     * @param oldAddress The old address of the ACLAdmin
     * @param newAddress The new address of the ACLAdmin
     */
    event ACLAdminUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the price oracle sentinel is updated.
     * @param oldAddress The old address of the PriceOracleSentinel
     * @param newAddress The new address of the PriceOracleSentinel
     */
    event PriceOracleSentinelUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the pool data provider is updated.
     * @param oldAddress The old address of the PoolDataProvider
     * @param newAddress The new address of the PoolDataProvider
     */
    event PoolDataProviderUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when a new proxy is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationAddress The address of the implementation contract
     */
    event ProxyCreated(
        bytes32 indexed id,
        address indexed proxyAddress,
        address indexed implementationAddress
    );

    /**
     * @dev Emitted when a new non-proxied contract address is registered.
     * @param id The identifier of the contract
     * @param oldAddress The address of the old contract
     * @param newAddress The address of the new contract
     */
    event AddressSet(
        bytes32 indexed id,
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the implementation of the proxy registered with id is updated
     * @param id The identifier of the contract
     * @param proxyAddress The address of the proxy contract
     * @param oldImplementationAddress The address of the old implementation contract
     * @param newImplementationAddress The address of the new implementation contract
     */
    event AddressSetAsProxy(
        bytes32 indexed id,
        address indexed proxyAddress,
        address oldImplementationAddress,
        address indexed newImplementationAddress
    );

    /**
     * @notice Returns the id of the Aave market to which this contract points to.
     * @return The market id
     **/
    function getMarketId() external view returns (string memory);

    /**
     * @notice Associates an id with a specific PoolAddressesProvider.
     * @dev This can be used to create an onchain registry of PoolAddressesProviders to
     * identify and validate multiple Aave markets.
     * @param newMarketId The market id
     */
    function setMarketId(string calldata newMarketId) external;

    /**
     * @notice Returns an address by its identifier.
     * @dev The returned address might be an EOA or a contract, potentially proxied
     * @dev It returns ZERO if there is no registered address with the given id
     * @param id The id
     * @return The address of the registered for the specified id
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice General function to update the implementation of a proxy registered with
     * certain `id`. If there is no proxy registered, it will instantiate one and
     * set as implementation the `newImplementationAddress`.
     * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
     * setter function, in order to avoid unexpected consequences
     * @param id The id
     * @param newImplementationAddress The address of the new implementation
     */
    function setAddressAsProxy(bytes32 id, address newImplementationAddress)
        external;

    /**
     * @notice Sets an address for an id replacing the address saved in the addresses map.
     * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress) external;

    /**
     * @notice Returns the address of the Pool proxy.
     * @return The Pool proxy address
     **/
    function getPool() external view returns (address);

    /**
     * @notice Updates the implementation of the Pool, or creates a proxy
     * setting the new `pool` implementation when the function is called for the first time.
     * @param newPoolImpl The new Pool implementation
     **/
    function setPoolImpl(address newPoolImpl) external;

    /**
     * @notice Returns the address of the PoolConfigurator proxy.
     * @return The PoolConfigurator proxy address
     **/
    function getPoolConfigurator() external view returns (address);

    /**
     * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
     * setting the new `PoolConfigurator` implementation when the function is called for the first time.
     * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
     **/
    function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

    /**
     * @notice Returns the address of the price oracle.
     * @return The address of the PriceOracle
     */
    function getPriceOracle() external view returns (address);

    /**
     * @notice Updates the address of the price oracle.
     * @param newPriceOracle The address of the new PriceOracle
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @notice Returns the address of the ACL manager.
     * @return The address of the ACLManager
     */
    function getACLManager() external view returns (address);

    /**
     * @notice Updates the address of the ACL manager.
     * @param newAclManager The address of the new ACLManager
     **/
    function setACLManager(address newAclManager) external;

    /**
     * @notice Returns the address of the ACL admin.
     * @return The address of the ACL admin
     */
    function getACLAdmin() external view returns (address);

    /**
     * @notice Updates the address of the ACL admin.
     * @param newAclAdmin The address of the new ACL admin
     */
    function setACLAdmin(address newAclAdmin) external;

    /**
     * @notice Returns the address of the price oracle sentinel.
     * @return The address of the PriceOracleSentinel
     */
    function getPriceOracleSentinel() external view returns (address);

    /**
     * @notice Updates the address of the price oracle sentinel.
     * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
     **/
    function setPriceOracleSentinel(address newPriceOracleSentinel) external;

    /**
     * @notice Returns the address of the data provider.
     * @return The address of the DataProvider
     */
    function getPoolDataProvider() external view returns (address);

    /**
     * @notice Updates the address of the data provider.
     * @param newDataProvider The address of the new DataProvider
     **/
    function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IPoolDataProvider {
    function getUserReserveData(address asset, address user)
        external
        view
        returns (
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    );
  /**
   * @notice Returns the reserve data
   * @param asset The address of the underlying asset of the reserve
   * @return unbacked The amount of unbacked tokens
   * @return accruedToTreasuryScaled The scaled amount of tokens accrued to treasury that is to be minted
   * @return totalAToken The total supply of the aToken
   * @return totalStableDebt The total stable debt of the reserve
   * @return totalVariableDebt The total variable debt of the reserve
   * @return liquidityRate The liquidity rate of the reserve
   * @return variableBorrowRate The variable borrow rate of the reserve
   * @return stableBorrowRate The stable borrow rate of the reserve
   * @return averageStableBorrowRate The average stable borrow rate of the reserve
   * @return liquidityIndex The liquidity index of the reserve
   * @return variableBorrowIndex The variable borrow index of the reserve
   * @return lastUpdateTimestamp The timestamp of the last update of the reserve
   **/
  function getReserveData(address asset)
    external
    view
    returns (
      uint256 unbacked,
      uint256 accruedToTreasuryScaled,
      uint256 totalAToken,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    );

  /**
   * @notice Returns the total supply of aTokens for a given asset
   * @param asset The address of the underlying asset of the reserve
   * @return The total supply of the aToken
   **/
  function getATokenTotalSupply(address asset) external view returns (uint256);

  /**
   * @notice Returns the total debt for a given asset
   * @param asset The address of the underlying asset of the reserve
   * @return The total debt for asset
   **/
  function getTotalDebt(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

enum FundState {
    Closed,
    Opened,
    Blocked
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDelayedExecutor {
    event TxRequested(address indexed _sender, uint256 indexed _id, uint256 date, address indexed _destination, bytes _message);
    event TxExecuted(address indexed _sender, uint256 indexed _id);
    event TxCancelled(address indexed _sender, uint256 indexed _id);

    struct Transaction {
        uint256 date;
        bytes message;
        address destination;
        address sender;
    }

    function transactions(uint256 id) external view returns (uint256 _date, bytes memory _message, address _destination, address _sender);
    function delay() external view returns (uint256);
    function minDelay() external view returns (uint256);
    function setDelay(uint256 _delay) external;
    function requestTx(address _destination, bytes calldata _message) external returns (uint256 _id);
    function executeTx(uint256 _id) external;
    function cancelTx(uint256 _id) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDripOperator {
    struct UpdateManagerRequest {
        address manager;
        uint256 share;
    }
    struct UpdateTrailingStopRequest {
        bool needToApply;
        bool managerStopEnabled;
        uint256 managerStopValue;
        bool globalStopEnabled;
        uint256 globalStopValue;
    }
    event TvlReported(uint256 fundId, uint256 tvl);
    // returns true if a report was finished
    function drip(uint256 fundId, uint256 tradeTvl) external returns (bool);
    function requestUpdateManager(uint256 fundId, address manager, uint256 share, uint256 tradeLock) external;
    function requestUpdateTrailingStop(uint256 fundId, bool managerStopEnabled, uint256 managerStopValue, bool globalStopEnabled, uint256 globalStopValue) external;
    function cancelUpdateManager(uint256 fundId) external;
    function cancelUpdateTrailingStop(uint256 fundId) external;
    function isDripInProgress(uint256 fundId) external view returns (bool);
    function isDripEnabled(uint256 fundId) external view returns (bool);
    function updateManagerRequests(uint256 fundId) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IToken.sol";

uint256 constant MAX_USERS_PER_BATCH = 20;
uint256 constant DRIP_GAS_USAGE = 1530000;
interface IFeeder {

    struct UserPosition {
        uint256 totalDeposit; // USDT
        uint256 totalWithdrawal; // USDT
        uint256 tokenAmount; // USDT
    }

    struct UserAccruals {
        uint256 deposit; // user pending deposit amount (USDT)
        uint256 withdraw; // user pending withdrawals amount (iTOKEN)
        uint256 indentedWithdraw;
    }

    struct FundInfo {
        uint256 lastPeriod;
        IToken itoken;
        address trade;
    }

    struct FundHwmData {
        bool hwm;
        uint256 hwmValue;
    }

    /**
    * Events
    */
    event NewFund(uint256 fundId, address manager);

    event Deposit(uint256 fundId, address depositedFrom, uint256 amount);
    event DepositCancelled(uint256 fundId, address indexed user, uint256 amount);
    event DepositProcessed(uint256 indexed fundId, address indexed user, uint256 amount, uint256 sharesAmount);

    event WithdrawalRequested(uint256 fundId, address indexed user, uint256 amount);
    event Withdrawal(uint256 fundId, address indexed user, uint256 amount);
    event WithdrawalCancelled(uint256 fundId, address indexed user, uint256 amount);

    event FundsTransferredToTrader(uint256 fundId, address trader, uint256 amount);

    event FeesChanged(address newFees);
    /**
    * Public
    */

    function stake(uint256 fundId, address user, uint256 amount) external returns (uint256 stakedAmount);

    function requestWithdrawal(uint256 fundId, address user, uint256 amount, bool indented) external;

    function cancelDeposit(uint256 fundId, address user) external returns (uint256);
    function cancelWithdrawal(uint256 fundId, address user) external returns (uint256);

    /**
    * Auth
    */

    function newFund(uint256 fundId,
        address manager,
        IToken itoken,
        address trade,
        bool hwm
    ) external;

    // returns count of actually processed withdrawals
    function withdrawMultiple(uint256 fundId, uint256 supply, uint256 toWithdraw, uint256 tradeTvl, uint256 maxBatchSize) external returns (uint256);
    // returns count of actually processed deposits and amount of debt left
    function drip(uint256 fundId, uint256 subtracted, uint256 tokenSupply, uint256 tradeTvl, uint256 maxBatchSize) external returns (uint256, uint256);
    // returns count of remaining indented withdrawals
    function moveIndentedWithdrawals(uint256 fundId, uint256 maxBatchSize) external returns (uint256);
    function gatherFees(uint256 fundId, uint256 tradeTvl, uint256 executionFee) external;
    function saveHWM(uint256 fundId, uint256 tradeTvl) external;
    function transferFromTrade(uint256 fundId, uint256 amount) external;

    /**
    * View
    */
    function getFund(uint256 fundId) external view returns (FundInfo memory);
    function userWaitingForWithdrawal(uint256 fundId) external view returns (address[] memory);
    function userWaitingForDeposit(uint256 fundId) external view returns(address[] memory);
    function getPendingOperationsCount(uint256 fundId) external view returns (uint256);

    function tokenRate(uint256 fundId, uint256 tradeTvl) external view returns (uint256);
    function hwmValue(uint256 fundId) external view returns (uint256);
    function pendingTvl(uint256 fundId, uint256 tradeTvl, uint256 gasPrice) external view returns (uint256, uint256, uint256, uint256);
    function calculatePf(uint256 fundId, uint256 tradeTvl) external view returns (uint256);
    function getUserAccrual(uint256 fundId, address user) external view returns (uint256, uint256, uint256);
    function getUserData(uint256 fundId, address user) external view returns (uint256, uint256, uint256, uint256);
    function fundWithdrawals(uint256 fundId) external view returns (uint256);
    function fundDeposits(uint256 fundId) external view returns (uint256);
    function fundTotalWithdrawals(uint256 fundId) external view returns (uint256);
    function hasUnprocessedWithdrawals() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFees {

    struct FundFees {
        uint256 live;
        uint256 sf;
        uint256 pf;
        uint256 mf;
    }


    /**
    * Events
    */
    event NewFund(uint256 fundId, uint256 sf, uint256 pf, uint256 mf);

    event SfCharged(uint256 indexed fundId, uint256 amount);
    event PfCharged(uint256 indexed fundId, uint256 amount);
    event MfCharged(uint256 indexed fundId, uint256 amount);
    event EfCharged(uint256 indexed fundId, uint256 amount);
    event FeeEarned(address indexed receiver, uint256 amount);

    event Withdrawal(address indexed user, address token, uint256 amount);
    event WithdrawalFund(uint256 indexed fundId, address destination, address token, uint256 amount);
    event WithdrawalManager(address indexed user, address destination, address token, uint256 amount);

    event ServiceFeesChanged(uint256 sf, uint256 pf, uint256 mf);
    event ManagerShareChanged(uint256 indexed fundId, uint256 share);
    /**
    * Public
    */

    /**
    * Auth
    */

    function newFund(uint256 fundId, uint256 sf, uint256 pf, uint256 mf, uint256 managerShare) external;
    function managerShare(uint256 fundId) external view returns (uint256);
    function setManagerShare(uint256 fundId, uint256 share) external;
    /**
    * View
    */
    function fundBalance(uint256 fundId) external view returns (uint256);
    function fees(uint256 fundId) external view returns(uint256 sf, uint256 pf, uint256 mf);
    function serviceFees() external view returns(uint256 sf, uint256 pf, uint256 mf);
    function gatheredFees(uint256 fundId) external view returns(uint256 live, uint256 sf, uint256 pf, uint256 mf);
    function managerBalance(address manager) external view returns (uint256);

    function gatherSf(uint256 fundId, uint256 pending, address token) external returns(uint256);

    function gatherPf(uint256 fundId, uint256 pending, address token) external;

    function gatherEf(uint256 fundId, uint256 amount, address token) external;
    function gatherCf(uint256 fundId, address payer, uint256 amount, address token) external;
    function calculatePF(uint256 fundId, uint256 amount) external view returns (uint256);
    function totalFees(uint256[] memory fundIds, address manager) external view returns (uint256);

    function withdraw(address user, uint256 amount) external;
    function withdrawFund(uint256 fundId, address destination, uint256 amount) external;
    function withdrawManager(address destination, uint256 amount) external;
    function withdrawAll(uint256[] memory fundId, address destination) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFees.sol";

interface IFundFactory {

    struct FundInfo {
        uint256 id;
        bool hwm;
        uint256 subscriptionFee;
        uint256 managementFee;
        uint256 performanceFee;
        uint256 investPeriod;
        uint256 indent;
        bytes whitelistMask;
        uint256 serviceMask;
        address manager;
        uint256 managerShare;
        bool isPrivate;
    }

    /// On fund created
    event FundCreated(address indexed manager,
        uint256 id,
        bool hwm,
        uint256 sf,
        uint256 pf,
        uint256 mf,
        uint256 period,
        bytes whitelistMask,
        uint256 serviceMask
    );

    event FeesChanged(address newFees);
    event TriggerChanged(address newTrigger);

    function newFund(FundInfo calldata fundInfo) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IToken.sol";
import "./FundState.sol";

interface IInteraction {

    struct FundInfo {
        address trade;
        uint256 period;
        uint256 nextPeriod;
        IToken itoken;
        bool hwm;
        uint256 indent;
        bool isPrivate;
    }

    struct FundPendingTvlInfo {
        uint256 deposit;
        uint256 withdraw;
        uint256 pf;
        uint256 mustBePaid;
        uint256 totalFees;
        uint256 stakers;
        uint256 totalWithdrawals;
    }

    event NewFund(uint256 indexed fundId, address manager, address itoken);
    event NextPeriod(uint256 indexed fundId, uint256 nextPeriod);
    event Stake(uint256 indexed fundId, address user, uint256 depositAmount, uint256 tokenAmount, uint256 commissionPaid);
    event UnStake(uint256 indexed fundId, address user, uint256 amount, uint256 positionLeft);
    event PrivacyChanged(uint256 indexed fundId, bool isPrivate);

    // available values for investPeriod are
    // - 604800 (weekly)
    // - 2592000 (monthly)
    // - 7776000 (quarterly)
    function newFund(
        uint256 fundId,
        bool hwm,
        uint256 investPeriod,
        address manager,
        IToken itoken,
        address tradeContract,
        uint256 indent,
        bool isPrivate
    ) external;

    function drip(uint256 fundId, uint256 tradeTvl) external;

    function stake(uint256 fundId, uint256 amount) external returns (uint256);
    function unstake(uint256 fundId, uint256 amount) external;

    function cancelWithdraw(uint256 fundId) external;
    function cancelDeposit(uint256 fundId) external;
    function setIsPrivate(uint256 fundId, bool isPrivate) external;
    // VIEWS

    function fundExist(uint256 fundId) external view returns(bool);

    function tokenForFund(uint256 fundId) external view returns (address);

    function stakers(uint256 fundId) external view returns (uint256);
    function estimatedWithdrawAmount(uint256 fundId, uint256 tradeTvl, uint256 amount) external view returns (uint256);
    function fundInfo(uint256 fundId) external view returns (address, uint256, uint256);
    function isPrivate(uint256 fundId) external view returns (bool);
    function tokenRate(uint256 fundId, uint256 tradeTvl) external view returns (uint256);
    function hwmValue(uint256 fundId) external view returns (uint256);
    function userTVL(uint256 fundId, uint256 tradeTvl, address user) external view returns (uint256);
    function tokenSupply(uint256 fundId) external view returns (uint256);
    function userTokensAmount(uint256 fundId, address user) external view returns (uint256);
    function totalFees(uint256 fundId) external view returns (uint256);
    function pendingDepositAndWithdrawals(uint256 fundId, address user) external view returns (uint256, uint256, uint256);
    function pendingTvl(uint256[] calldata _funds, uint256[] calldata _tradeTvls, uint256 gasPrice) external view returns(
        FundPendingTvlInfo[] memory results
    );

    function deposits(uint256 fundId) external view returns (uint256);
    function withdrawals(uint256 fundId) external view returns (uint256);
    function isDripEnabled(uint256 fundId) external view returns (bool);
    function nextPeriod(uint256 fundId) external view returns (uint256);
}

// SPDX-License-Identifier: ISC
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "./IFeeder.sol";
import "./IInteraction.sol";
import "./IDripOperator.sol";
import "./IFees.sol";
import "./IFeeder.sol";
import "./IWhitelist.sol";
import "./IUpgrader.sol";
import "./IFundFactory.sol";
import "./ITradeParamsUpdater.sol";
import "./aave/IPool.sol";
import "./aave/IPoolDataProvider.sol";
import "./ISubaccountRegistry.sol";
import "./ITVLComputer.sol";
import "../integration/oracles/interfaces/IPriceFeed.sol";
import "../integration/gmx-v2/IExchangeRouter.sol";
import "../integration/gmx-v2/IReader.sol";
import "../integration/gmx-v2/data/DataStore.sol";

pragma solidity ^0.8.0;

interface IRegistry {
    function triggerServer() external view returns (address);
    function usdt() external view returns (IERC20MetadataUpgradeable);
    function feeder() external view returns (IFeeder);
    function interaction() external view returns (IInteraction);
    function fees() external view returns (IFees);
    function tradeBeacon() external view returns (address);
    function dripOperator() external view returns (IDripOperator);
    function ethPriceFeed() external view returns (IPriceFeed);
    function whitelist() external view returns (IWhitelist);
    function tradeParamsUpdater() external view returns (ITradeParamsUpdater);
    function upgrader() external view returns (IUpgrader);
    function swapper() external view returns (address);
    function aavePoolDataProvider() external view returns (IPoolDataProvider);
    function aavePool() external view returns (IPool);
    function fundFactory() external view returns (IFundFactory);
    function gmxV2ExchangeRouter() external view returns (IExchangeRouter);
    function gmxV2OrderVault() external view returns (address);
    function gmxV2Router() external view returns (address);
    function gmxV2Reader() external view returns (IReader);
    function gmxV2DataStore() external view returns (DataStore);
    function subaccountRegistry() external view returns (ISubaccountRegistry);
    function tvlComputer() external view returns (ITVLComputer);
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

interface ISubaccountRegistry {
    event AccountEnabled(address indexed owner, address account);
    event AccountDisabled(address indexed owner, address account);

    function accountOwners(address subaccount) external view returns (address);
    function enableAccount(address payable account) external payable;
    function disableAccount(address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IToken is IERC20 {

    function mint(address investor, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;

    function holders() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./FundState.sol";
import "../integration/gmx-v2/order/BaseOrderUtils.sol";

interface ITrade {
    /**
    * Events
    */
    event ManagerChanged(address newManager);
    event StateChanged(FundState newState);
    event OwnershipTransferred(address to);
    event WhitelistMaskUpdated(bytes _newMask);
    event AllowedServicesUpdated(uint256 _newMask);
    event TrailingStopUpdated(bool _managerStopEnabled, uint256 _managerStopValue, bool _globalStopEnabled, uint256 _globalStopValue);
    event ManagerTrailingStopMoved(uint256 _tokenRate);
    event GlobalTrailingStopMoved(uint256 _tokenRate);
    /**
    * Public
    */
    function swap(
        address tokenA,
        address tokenB,
        uint256 amountA,
        bytes memory payload
    ) external returns(uint256);

    function multiSwap(
        bytes[] calldata data
    ) external;

    function gmxV2CreateOrder(BaseOrderUtils.CreateOrderParams calldata params) external payable returns (bytes32);
    function gmxV2CancelOrder(bytes32 key) external payable;
    function gmxV2ClaimFundingFees(address[] memory markets, address[] memory tokens) external payable returns (uint256[] memory);

    function aaveSupply(address _asset, uint256 _amount) external;
    function aaveWithdraw(address _asset, uint256 _amount) external;
    function setTradingScope(bytes memory whitelistMask, uint256 serviceMask) external;
    function setAaveReferralCode(uint16 refCode) external;
    function setGmxRefCode(bytes32 _gmxRefCode) external;
    function setState(FundState newState) external;
    function chargeDebt() external;
    function isManager(address _address) external view returns (bool);
    function isOwner(address _address) external view returns (bool);
    function manager() external view returns (address);
    function owner() external view returns (address);
    function whitelistMask() external view returns (bytes memory);
    function servicesEnabled() external view returns (bool[] memory);
    function isLockedUntil(address manager) external view returns (uint256);
    /**
    * Auth
    */
    function transferToFeeder(uint256 amount) external;
    function transferOwnership(address to) external;
    function setManager(address manager) external;
    function setTrailingStop(bool managerStopEnabled, uint256 managerStopValue, bool globalStopEnabled, uint256 globalStopValue) external;
    function moveTrailingStops(uint256 newTokenRate) external;
    function triggerGlobalTrailingStop() external;
    function triggerManagerTrailingStop() external;
    function lockTrade(address manager, uint256 duringTime) external;
    function initialize(
        address owner,
        address manager,
        bytes calldata _whitelistMask,
        uint256 serviceMask,
        uint256 fundId
    ) external;
    /**
    * View
    */
    function usdtAmount() external view returns(uint256);
    function debt() external view returns(uint256);

    function getAavePositionSizes(address[] calldata _assets) external view
        returns (uint256[] memory assetPositions);

    function getAssetsSizes(address[] calldata assets) external view returns(uint256[] memory);

    function status() external view returns(FundState);

    function fundId() external view returns(uint256);

    function getGmxRefCode() external view returns(bytes32);

    function getAaveRefCode() external view returns(uint16);

    function trailingStop() external view returns (bool, uint256, uint256, bool, uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDelayedExecutor.sol";

interface ITradeParamsUpdater is IDelayedExecutor {
    function lastTxs(address _destination) external view returns (uint256);
    function nearestUpdate(address _destination) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITVLComputer {
    event PriceFeedChanged(address token, address priceFeed);
    event GMXParamsChanged(address gmxReader, address gmxDataStore, address usdc);

    function setPriceFeeds(address[] memory tokens, address[] memory priceFeeds) external;
    function setGMXParams(address gmxReader, address gmxDataStore, address usdc) external;
    function getTVL(address trade) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUpgradeable {
    function upgradeTo(address implementation) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUpgradeable.sol";

interface IUpgrader {
    struct Upgrade {
        IUpgradeable destination;
        address implementation;
    }
    event UpgradeRequested(Upgrade[] _upgrades, uint256 _upgradePeriod);

    function requestUpgrade(Upgrade[] memory _upgrades) external;
    function upgrade() external;
    function cancelUpgrade() external;
    function nextUpgradeDate() external view returns (uint256);
    function setUpgradePeriod(uint256 _upgradePeriod) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWhitelist {
    event TokenAdded(address indexed token, uint256 index);
    event TokenRemoved(address indexed token, uint256 index);

    function tokens(uint256 index) external view returns (address);
    function tokenCount() external view returns (uint256);
    function getTokenIndex(address token) external view returns (uint256, bool);
    function addToken(address token) external;
    function removeToken(address token) external;
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/ITrade.sol";
import "../interfaces/IRegistry.sol";

library AAVE {
    event AaveSupply(address asset, uint256 amount);
    event AaveWithdraw(address asset, uint256 amount);

    // @address:REGISTRY
    IRegistry constant registry = IRegistry(0xe8258b0003CB159c75bfc2bC2D079d12E3774a80);
    
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function supply(
        address _asset,
        uint256 _amount,
        ITrade _trade
    ) external {
        require(_trade.status() == FundState.Opened, "T/FC"); // fund is closed
        require(_trade.servicesEnabled()[1], "T/FS"); // forbidden service
        require(_amount <= IERC20(_asset).balanceOf(address(_trade)), "T/ANA"); // not enough amount for staking in aave
        IERC20Upgradeable(_asset).safeApprove(address(registry.aavePool()), _amount);

        registry.aavePool().supply(
            _asset,
            _amount,
            address(_trade),
            _trade.getAaveRefCode()
        );

        emit AaveSupply(_asset, _amount);
    }

    function withdraw(
        address _asset,
        uint256 _amount,
        ITrade _trade
    ) external {
        require(_trade.isManager(msg.sender) || msg.sender == address(registry.triggerServer()), "T/OM"); // only manager
        registry.aavePool().withdraw(_asset, _amount, address(_trade));

        emit AaveWithdraw(_asset, _amount);
    }

    function getPositionSizes(address[] calldata _assets, ITrade _trade) external view
    returns (uint256[] memory assetPositions)
    {
        assetPositions = new uint256[](_assets.length);
        for (uint256 i; i < _assets.length; i++) {
            (uint256 currentATokenBalance, , , , , , , , ) = registry.aavePoolDataProvider()
                .getUserReserveData(_assets[i], address(_trade));
            assetPositions[i] = currentATokenBalance;
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/IRegistry.sol";
import "../interfaces/ITrade.sol";
import "../utils/WhitelistUtils.sol";

library GMXV2 {
    // @address:REGISTRY
    IRegistry constant registry = IRegistry(0xe8258b0003CB159c75bfc2bC2D079d12E3774a80);
    
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function createOrder(
        BaseOrderUtils.CreateOrderParams calldata _params,
        ITrade _trade
    ) external returns (bytes32) {
        validateOrder(_params, _trade);
        bool isIncrease = _params.orderType == Order.OrderType.MarketIncrease || _params.orderType == Order.OrderType.LimitIncrease;
        address orderVault = registry.gmxV2OrderVault();
        IExchangeRouter exchangeRouter = registry.gmxV2ExchangeRouter();
        exchangeRouter.sendWnt{value: msg.value}(orderVault, msg.value);
        if (isIncrease) {
            IERC20Upgradeable(_params.addresses.initialCollateralToken).safeApprove(
                registry.gmxV2Router(),
                _params.numbers.initialCollateralDeltaAmount
            );
            exchangeRouter.sendTokens(
                _params.addresses.initialCollateralToken,
                orderVault,
                _params.numbers.initialCollateralDeltaAmount
            );
        }
        BaseOrderUtils.CreateOrderParams memory params = _params;
        params.addresses.uiFeeReceiver = address(0);
        params.addresses.receiver = address(_trade);
        Market.Props memory market = getMarket(_params.addresses.market);
        address pnlToken = _params.isLong ? market.longToken : market.shortToken;
        params.decreasePositionSwapType = _params.addresses.initialCollateralToken == pnlToken
            ? Order.DecreasePositionSwapType.NoSwap
            : Order.DecreasePositionSwapType.SwapPnlTokenToCollateralToken;
        params.referralCode = _trade.getGmxRefCode();
        return exchangeRouter.createOrder(params);
    }

    function getReceiveToken(BaseOrderUtils.CreateOrderParams calldata _params) internal returns (address) {
        address receiveToken = _params.addresses.initialCollateralToken;
        for (uint256 i = 0; i < _params.addresses.swapPath.length; i++) {
            Market.Props memory nextMarket = getMarket(_params.addresses.swapPath[i]);
            if (nextMarket.shortToken == receiveToken) {
                receiveToken = nextMarket.longToken;
            } else if (nextMarket.longToken == receiveToken) {
                receiveToken = nextMarket.shortToken;
            } else {
                revert("T/ISP"); // invalid swap path
            }
        }
        return receiveToken;
    }

    function getMarket(address key) internal returns (Market.Props memory) {
        return registry.gmxV2Reader()
            .getMarket(registry.gmxV2DataStore(), key);
    }

    function claimFundingFees(
        address[] memory markets,
        address[] memory tokens,
        address receiver
    ) external returns (uint256[] memory) {
        return registry.gmxV2ExchangeRouter().claimFundingFees(markets, tokens, receiver);
    }
 
    function cancelOrder(bytes32 _key, ITrade _trade) external {
        require(_trade.isManager(msg.sender) || msg.sender == registry.triggerServer(), "T/OM");
        registry.gmxV2ExchangeRouter().cancelOrder{value: msg.value}(_key);
    }

    function validateOrder(BaseOrderUtils.CreateOrderParams calldata _params, ITrade _trade) internal {
        require(_params.orderType != Order.OrderType.MarketSwap && _params.orderType != Order.OrderType.LimitSwap, "T/OTNS");
        bool isIncrease = _params.orderType == Order.OrderType.MarketIncrease || _params.orderType == Order.OrderType.LimitIncrease;
        require(!isIncrease || _trade.servicesEnabled()[0], "T/FS");
        require(!isIncrease || _trade.status() == FundState.Opened, "T/FC");
        address receiveToken = getReceiveToken(_params);
        if (receiveToken != address(registry.usdt())) {
            require(_trade.isLockedUntil(msg.sender) == 0 || _trade.isLockedUntil(msg.sender) < block.timestamp, "T/TL"); // trade locked
        }
        if (_params.orderType == Order.OrderType.MarketDecrease) {
            require(_trade.isManager(msg.sender) || (msg.sender == registry.triggerServer() && receiveToken == address(registry.usdt())), "T/OM");
        } else {
            require(_trade.isManager(msg.sender), "T/OM");
        }
        if (isIncrease) {
            address indexToken = getMarket(_params.addresses.market).indexToken;
            WhitelistUtils.checkTokenAllowance(indexToken, _trade);
        } else {
            if (receiveToken != address(registry.usdt())) {
                WhitelistUtils.checkTokenAllowance(receiveToken, _trade);
                require(_trade.status() == FundState.Opened, "T/FC"); // fund closed
            }
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/ITrade.sol";
import "../utils/WhitelistUtils.sol";
import "../utils/TryCall.sol";

library ZeroX {
    event SwapSuccess(address tokenA, address tokenB, uint256 amountIn, uint256 amountOut);

    // @address:REGISTRY
    IRegistry constant registry = IRegistry(0xe8258b0003CB159c75bfc2bC2D079d12E3774a80);
    
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function swap(
        address tokenA,
        address tokenB,
        uint256 amountA,
        bytes memory payload,
        ITrade trade
    ) external returns(uint256) {
        address usdt = address(registry.usdt());
        if (tokenB != usdt) {
            require(trade.status() == FundState.Opened, "T/FC"); // fund is closed
            WhitelistUtils.checkTokenAllowance(tokenB, trade);
            require(trade.isManager(msg.sender), "T/OM"); // only manager
        } else {
            require(trade.isManager(msg.sender) || msg.sender == address(registry.triggerServer()), "T/OM"); // only manager
        }
        address swapper = registry.swapper();
        IERC20Upgradeable(tokenA).safeApprove(swapper, amountA);
        uint256 balanceStart = IERC20(tokenB).balanceOf(address(trade));
        TryCall.call(swapper, payload);
        IERC20Upgradeable(tokenA).safeApprove(swapper, 0);
        uint256 diff = IERC20(tokenB).balanceOf(address(trade)) - balanceStart;
        require(diff > 0, "T/SF"); // swap failed
        emit SwapSuccess(tokenA, tokenB, amountA, diff);
        return diff;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./../utils/TryCall.sol";
import "../utils/WhitelistUtils.sol";
import "../interfaces/ITrade.sol";
import "../interfaces/FundState.sol";
import "../interfaces/IRegistry.sol";
import "../libs/ZeroX.sol";
import "../libs/AAVE.sol";
import "../libs/GMXV2.sol";

// @address:REGISTRY
IRegistry constant registry = IRegistry(0xe8258b0003CB159c75bfc2bC2D079d12E3774a80);

contract TradeStorage is Initializable {
    mapping(address => bool) public managers; // legacy
    FundState state;
    uint16 public aaveReferralCode;
    bytes32 public gmxRefCode;
    bytes _whitelistMask;
    bool _gmxEnabled;
    bool _aaveEnabled;
    uint256 _fundId;
    uint256 _debt;
    address _manager;
    address _owner;
    mapping(address => uint256) public tradeLock;
    bool _managerTrailingStopEnabled;
    uint256 _managerTrailingStopValue;
    uint256 _managerTrailingStopTokenRate;
    bool _globalTrailingStopEnabled;
    uint256 _globalTrailingStopValue;
    uint256 _globalTrailingStopTokenRate;
    uint256[37] _gap;
}

contract Trade is ITrade, TradeStorage, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    modifier onlyOwner() {
        require(isOwner(msg.sender), "T/OO"); // only owner
        _;
    }

    modifier onlyManager() {
        require(isManager(msg.sender), "T/OM"); // only manager
        _;
    }

    modifier saveDebt() {
        if (msg.sender != registry.triggerServer()) {
            _;
            return;
        }
        uint256 gasLeft = gasleft();
        _;
        gasLeft = gasLeft - gasleft();
        _debt += ethToUsd(gasLeft * tx.gasprice);
    }

    modifier saveDebtPayable() {
        if (msg.sender != registry.triggerServer()) {
            _;
            return;
        }
        _;
        _debt += ethToUsd(msg.value);
    }

    modifier notExceededDebt(address token, uint256 amount) {
        if (token == address(registry.usdt())) {
            require(amount <= usdtAmount() - _debt, "T/DEB"); // debt exceeded balance
        }
        _;
    }

    modifier notTradeLocked(address tokenTo) {
        address account = _getBaseAccount(msg.sender);
        if (tokenTo == address(0) || tokenTo != address(registry.usdt())) {
            require(tradeLock[account] == 0 || tradeLock[account] < block.timestamp, "T/TL"); // trade locked
        }
        _;
    }

    function initialize(
        address owner,
        address manager,
        bytes calldata whitelistMask,
        uint256 serviceMask,
        uint256 fundId
    ) external initializer {
        __ReentrancyGuard_init();
        _fundId = fundId;
        _owner = owner;
        state = FundState.Opened;
        _setWhitelistMask(whitelistMask);
        _setServiceMask(serviceMask);
        this.setManager(manager);
    }

    function setTradingScope(bytes memory whitelistMask, uint256 serviceMask) external {
        require(msg.sender == address(registry.tradeParamsUpdater()), "T/AD"); // access denied
        require(registry.feeder().fundTotalWithdrawals(_fundId) == 0, "T/UW"); // has unprocessed withdrawals
        _setWhitelistMask(whitelistMask);
        _setServiceMask(serviceMask);
    }

    function chargeDebt() external override {
        registry.usdt().safeApprove(address(registry.fees()), _debt);
        registry.fees().gatherEf(_fundId, _debt, address(registry.usdt()));
        _debt = 0;
    }

    function setFundId(uint256 fundId) external {
        require(registry.feeder().getFund(fundId).trade == address(this), "T/WID"); // wrong fund id
        _fundId = fundId;
    }

    function usdtAmount() public view returns(uint256) {
        return registry.usdt().balanceOf(address(this));
    }

    function status() public view returns(FundState) {
        return state;
    }

    function debt() public view returns(uint256) {
        return _debt;
    }

    function transferToFeeder(uint256 amount) external {
        require(msg.sender == address(registry.feeder()), "T/AD"); // access denied
        registry.usdt().safeTransfer(address(registry.feeder()), amount);
    }

    function transferOwnership(address to) external onlyOwner {
        if (managers[to]) {
            managers[to] = false; // for back compatibility
        }
        uint256 collectedFees = registry.fees().fundBalance(_fundId);
        if (collectedFees > 0) {
            registry.fees().withdrawFund(_fundId, _owner, collectedFees);
        }
        _owner = to;
        emit OwnershipTransferred(to);
    }

    function setState(FundState newState) external override {
        require(
            msg.sender == registry.triggerServer() && (state == FundState.Blocked && newState == FundState.Opened)
            || (isOwner(msg.sender) && newState != FundState.Blocked && state != FundState.Blocked),
            "T/AD"
        ); // access denied
        require(state != newState, "T/SS"); // same state
        state = newState;
        emit StateChanged(state);
    }

    function multiSwap(bytes[] calldata data) external override {
        for (uint i; i < data.length; i++) {
            (, address tokenA, address tokenB, uint256 amountA, bytes memory payload) = abi.decode(data[i],
                (address, address, address, uint256, bytes)
            );
            swap(tokenA, tokenB, amountA, payload);
        }
    }

    function swap(
        address tokenA,
        address tokenB,
        uint256 amountA,
        bytes memory payload
    ) public override nonReentrant saveDebt notExceededDebt(tokenA, amountA) notTradeLocked(tokenB) returns(uint256) {
        return ZeroX.swap(tokenA, tokenB, amountA, payload, this);
    }

    function lockTrade(address manager, uint256 duringTime) external override {
        require(
            isOwner(msg.sender)
            || msg.sender == address(registry.dripOperator()),
            "T/AD"
        ); // access denied
        tradeLock[manager] = duringTime;
    }

    function setManager(address manager) external override {
        require(
            msg.sender == address(this)
            || msg.sender == address(registry.dripOperator()),
            "T/AD"
        ); // access denied
        if (managers[manager]) {
            if (_owner == address(0)) {
                _owner = manager;
            }
            managers[manager] = false; // for back compatibility
        }
        _manager = manager;
        emit ManagerChanged(manager);
    }

    function setTrailingStop(bool managerStopEnabled, uint256 managerStopValue, bool globalStopEnabled, uint256 globalStopValue) external {
        require(msg.sender == address(registry.dripOperator()), "T/AD");
        _managerTrailingStopEnabled = managerStopEnabled;
        _managerTrailingStopValue = managerStopValue;
        _globalTrailingStopEnabled = globalStopEnabled;
        _globalTrailingStopValue = globalStopValue;
        emit TrailingStopUpdated(_managerTrailingStopEnabled, _managerTrailingStopValue, _globalTrailingStopEnabled, _globalTrailingStopValue);
    }

    function triggerManagerTrailingStop() external {
        require(msg.sender == registry.triggerServer(), "T/AD");
        require(_managerTrailingStopEnabled, "T/SD");
        _managerTrailingStopEnabled = false;
        _managerTrailingStopValue = 0;
        _managerTrailingStopTokenRate = 0;
        tradeLock[_manager] = registry.interaction().nextPeriod(_fundId);
        emit TrailingStopUpdated(_managerTrailingStopEnabled, _managerTrailingStopValue, _globalTrailingStopEnabled, _globalTrailingStopValue);
        emit ManagerTrailingStopMoved(_managerTrailingStopTokenRate);
    }

    function triggerGlobalTrailingStop() external {
        require(msg.sender == registry.triggerServer(), "T/AD");
        require(_globalTrailingStopEnabled, "T/SD");
        _globalTrailingStopEnabled = false;
        _globalTrailingStopValue = 0;
        _globalTrailingStopTokenRate = 0;
        state = FundState.Blocked;
        emit StateChanged(state);
        emit TrailingStopUpdated(_globalTrailingStopEnabled, _globalTrailingStopValue, _globalTrailingStopEnabled, _globalTrailingStopValue);
        emit GlobalTrailingStopMoved(_globalTrailingStopTokenRate);
    }

    function moveTrailingStops(uint256 newTokenRate) external {
        require(msg.sender == address(registry.dripOperator()), "T/AD");
        if (_managerTrailingStopEnabled) {
            uint256 nextManagerTrailingStop = newTokenRate * (1e18 - _managerTrailingStopValue) / 1e18;
            if (nextManagerTrailingStop > _managerTrailingStopTokenRate) {
                _managerTrailingStopTokenRate = nextManagerTrailingStop;
                emit ManagerTrailingStopMoved(_managerTrailingStopTokenRate);
            }
        }
        if (_globalTrailingStopEnabled) {
            uint256 nextGlobalTrailingStop = newTokenRate * (1e18 - _globalTrailingStopValue) / 1e18;
            if (nextGlobalTrailingStop > _globalTrailingStopTokenRate) {
                _globalTrailingStopTokenRate = nextGlobalTrailingStop;
                emit GlobalTrailingStopMoved(_globalTrailingStopTokenRate);
            }
        }
    }

    function setAaveReferralCode(uint16 refCode) external override onlyOwner {
        aaveReferralCode = refCode;
    }

    function setGmxRefCode(bytes32 _gmxRefCode) external override onlyOwner {
        gmxRefCode = _gmxRefCode;
    }

    function aaveSupply(
        address _asset,
        uint256 _amount
    ) external override onlyManager notExceededDebt(_asset, _amount) notTradeLocked(address(0)) {
        AAVE.supply(_asset, _amount, this);
    }

    function aaveWithdraw(
        address _asset,
        uint256 _amount
    ) external override saveDebt {
        AAVE.withdraw(_asset, _amount, this);
    }

    function getAavePositionSizes(address[] calldata _assets) external view override
    returns (uint256[] memory assetPositions)
    {
        return AAVE.getPositionSizes(_assets, this);
    }

    function getAssetsSizes(address[] calldata assets) external override view returns(uint256[] memory) {
        uint256[] memory sizes = new uint256[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            sizes[i] = IERC20(assets[i]).balanceOf(address(this));
        }

        return sizes;
    }

    function gmxV2CreateOrder(BaseOrderUtils.CreateOrderParams calldata params)
    external payable saveDebt saveDebtPayable nonReentrant
    notExceededDebt(params.addresses.initialCollateralToken, params.numbers.initialCollateralDeltaAmount) returns (bytes32) {
        return GMXV2.createOrder(params, this);
    }

    function gmxV2CancelOrder(bytes32 key) external payable saveDebt nonReentrant {
        return GMXV2.cancelOrder(key, this);
    }

    function gmxV2ClaimFundingFees(address[] memory markets, address[] memory tokens) external payable returns (uint256[] memory) {
        return GMXV2.claimFundingFees(markets, tokens, address(this));
    }

    function _setServiceMask(uint256 _serviceMask) private {
        _gmxEnabled = _serviceMask & 1 == 1;
        _aaveEnabled = _serviceMask & 1 << 1 == 1 << 1;
        emit AllowedServicesUpdated(_serviceMask);
    }

    function _setWhitelistMask(bytes memory whitelistMask) private {
        uint256 tokenCount = registry.whitelist().tokenCount();
        if (tokenCount < whitelistMask.length * 8) {
            // cannot be more than 1 byte longer than maximum capacity
            require(whitelistMask.length * 8 - tokenCount < 8, "T/UT");
            bytes1 lastByte = whitelistMask[0];
            // mask that allows all tokens of the last byte of whitelistMask
            bytes1 allowedTokensMask = bytes1(uint8((1 << tokenCount % 8) - 1));
            require(lastByte | allowedTokensMask == allowedTokensMask, "T/UT");
        }
        _whitelistMask = whitelistMask;
        emit WhitelistMaskUpdated(_whitelistMask);
    }

    function whitelistMask() external view returns (bytes memory) {
        return _whitelistMask;
    }

    function fundId() external view returns (uint256) {
        return _fundId;
    }

    function manager() external view returns (address) {
        return _manager;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function servicesEnabled() external view returns (bool[] memory) {
        bool[] memory result = new bool[](2);
        result[0] = _gmxEnabled;
        result[1] = _aaveEnabled;
        return result;
    }

    function isManager(address _address) public view returns (bool) {
        address account = _getBaseAccount(_address);
        return managers[account] || account == _manager;
    }

    function isOwner(address _address) public view returns (bool) {
        return managers[_address] || _address == _owner;
    }

    function getGmxRefCode() public view returns (bytes32) {
        return gmxRefCode;
    }

    function getAaveRefCode() external view returns(uint16) {
        return aaveReferralCode;
    }

    function isLockedUntil(address manager) external view returns (uint256) {
        return tradeLock[_getBaseAccount(manager)];
	}

    function _getBaseAccount(address _address) private view returns(address) {
        address accountOwner = registry.subaccountRegistry().accountOwners(_address);
        return accountOwner == address(0) ? _address : accountOwner;
    }

    function ethToUsd(uint256 eth) private view returns (uint256) {
        IPriceFeed ethPriceFeed = registry.ethPriceFeed();
        return eth
            / 10**uint256(ethPriceFeed.decimals())
            * 10**(registry.usdt()).decimals()
            * uint256(ethPriceFeed.latestAnswer())
            / 10**18;
    }

    function trailingStop() external view returns (bool, uint256, uint256, bool, uint256, uint256) {
        return (
            _managerTrailingStopEnabled,
            _managerTrailingStopValue,
            _managerTrailingStopTokenRate,
            _globalTrailingStopEnabled,
            _globalTrailingStopValue,
            _globalTrailingStopTokenRate
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TryCall {
    function call(address _destination, bytes memory _message) internal {
        (bool success, bytes memory _returnData) = _destination.call(_message);
        if (success) {
            return;
        }
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) revert('Transaction reverted silently');

        assembly {
        // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        revert(abi.decode(_returnData, (string))); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

import "../interfaces/IRegistry.sol";
import "../interfaces/ITrade.sol";

library WhitelistUtils {
    // @address:REGISTRY
    IRegistry constant registry = IRegistry(0xe8258b0003CB159c75bfc2bC2D079d12E3774a80);

    function checkTokenAllowance(address _token, ITrade _trade) internal view {
        (uint256 index, bool found) = registry.whitelist().getTokenIndex(_token);
        require(found, "T/TF"); // forbidden token
        uint256 maskIndex = index / 8;
        uint8 tokenIndex = uint8(index % 8);
        bytes memory _whitelistMask = _trade.whitelistMask();
        require(uint8(_whitelistMask[_whitelistMask.length - maskIndex - 1]) & (1 << tokenIndex) == (1 << tokenIndex), "T/TF");
    }
}