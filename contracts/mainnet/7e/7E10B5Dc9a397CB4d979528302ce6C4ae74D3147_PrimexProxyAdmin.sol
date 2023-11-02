// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";
import "../../access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(ITransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(ITransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(ITransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(ITransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        ITransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev Interface for {TransparentUpgradeableProxy}. In order to implement transparency, {TransparentUpgradeableProxy}
 * does not implement this interface directly, and some of its functions are implemented by an internal dispatch
 * mechanism. The compiler is unaware that these functions are implemented by {TransparentUpgradeableProxy} and will not
 * include them in the ABI so this interface must be used to interact with it.
 */
interface ITransparentUpgradeableProxy is IERC1967 {
    function admin() external view returns (address);

    function implementation() external view returns (address);

    function changeAdmin(address) external;

    function upgradeTo(address) external;

    function upgradeToAndCall(address, bytes memory) external payable;
}

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 *
 * NOTE: The real interface of this proxy is that defined in `ITransparentUpgradeableProxy`. This contract does not
 * inherit from that interface, and instead the admin functions are implicitly implemented using a custom dispatch
 * mechanism in `_fallback`. Consequently, the compiler will not produce an ABI for this contract. This is necessary to
 * fully implement transparency without decoding reverts caused by selector clashes between the proxy and the
 * implementation.
 *
 * WARNING: It is not recommended to extend this contract to add additional external functions. If you do so, the compiler
 * will not check that there are no selector conflicts, due to the note above. A selector clash between any new function
 * and the functions declared in {ITransparentUpgradeableProxy} will be resolved in favor of the new one. This could
 * render the admin operations inaccessible, which could prevent upgradeability. Transparency may also be compromised.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     *
     * CAUTION: This modifier is deprecated, as it could cause issues if the modified function has arguments, and the
     * implementation provides a function with the same selector.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev If caller is the admin process the call internally, otherwise transparently fallback to the proxy behavior
     */
    function _fallback() internal virtual override {
        if (msg.sender == _getAdmin()) {
            bytes memory ret;
            bytes4 selector = msg.sig;
            if (selector == ITransparentUpgradeableProxy.upgradeTo.selector) {
                ret = _dispatchUpgradeTo();
            } else if (selector == ITransparentUpgradeableProxy.upgradeToAndCall.selector) {
                ret = _dispatchUpgradeToAndCall();
            } else if (selector == ITransparentUpgradeableProxy.changeAdmin.selector) {
                ret = _dispatchChangeAdmin();
            } else if (selector == ITransparentUpgradeableProxy.admin.selector) {
                ret = _dispatchAdmin();
            } else if (selector == ITransparentUpgradeableProxy.implementation.selector) {
                ret = _dispatchImplementation();
            } else {
                revert("TransparentUpgradeableProxy: admin cannot fallback to proxy target");
            }
            assembly {
                return(add(ret, 0x20), mload(ret))
            }
        } else {
            super._fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function _dispatchAdmin() private returns (bytes memory) {
        _requireZeroValue();

        address admin = _getAdmin();
        return abi.encode(admin);
    }

    /**
     * @dev Returns the current implementation.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function _dispatchImplementation() private returns (bytes memory) {
        _requireZeroValue();

        address implementation = _implementation();
        return abi.encode(implementation);
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _dispatchChangeAdmin() private returns (bytes memory) {
        _requireZeroValue();

        address newAdmin = abi.decode(msg.data[4:], (address));
        _changeAdmin(newAdmin);

        return "";
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     */
    function _dispatchUpgradeTo() private returns (bytes memory) {
        _requireZeroValue();

        address newImplementation = abi.decode(msg.data[4:], (address));
        _upgradeToAndCall(newImplementation, bytes(""), false);

        return "";
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     */
    function _dispatchUpgradeToAndCall() private returns (bytes memory) {
        (address newImplementation, bytes memory data) = abi.decode(msg.data[4:], (address, bytes));
        _upgradeToAndCall(newImplementation, data, true);

        return "";
    }

    /**
     * @dev Returns the current admin.
     *
     * CAUTION: This function is deprecated. Use {ERC1967Upgrade-_getAdmin} instead.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev To keep this contract fully transparent, all `ifAdmin` functions must be payable. This helper is here to
     * emulate some proxy functions being non-payable while still allowing value to pass through.
     */
    function _requireZeroValue() private {
        require(msg.value == 0);
    }
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

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

// admin roles
bytes32 constant BIG_TIMELOCK_ADMIN = 0x00; // It's primary admin.
bytes32 constant MEDIUM_TIMELOCK_ADMIN = keccak256("MEDIUM_TIMELOCK_ADMIN");
bytes32 constant SMALL_TIMELOCK_ADMIN = keccak256("SMALL_TIMELOCK_ADMIN");
bytes32 constant EMERGENCY_ADMIN = keccak256("EMERGENCY_ADMIN");
bytes32 constant GUARDIAN_ADMIN = keccak256("GUARDIAN_ADMIN");
bytes32 constant NFT_MINTER = keccak256("NFT_MINTER");
bytes32 constant TRUSTED_TOLERABLE_LIMIT_ROLE = keccak256("TRUSTED_TOLERABLE_LIMIT_ROLE");

// inter-contract interactions roles
bytes32 constant NO_FEE_ROLE = keccak256("NO_FEE_ROLE");
bytes32 constant VAULT_ACCESS_ROLE = keccak256("VAULT_ACCESS_ROLE");
bytes32 constant PM_ROLE = keccak256("PM_ROLE");
bytes32 constant LOM_ROLE = keccak256("LOM_ROLE");
bytes32 constant BATCH_MANAGER_ROLE = keccak256("BATCH_MANAGER_ROLE");

// token constants
address constant NATIVE_CURRENCY = address(uint160(bytes20(keccak256("NATIVE_CURRENCY"))));
address constant USD = 0x0000000000000000000000000000000000000348;
uint256 constant USD_MULTIPLIER = 10 ** (18 - 8); // usd decimals in chainlink is 8
uint8 constant MAX_ASSET_DECIMALS = 18;

// time constants
uint256 constant SECONDS_PER_YEAR = 365 days;
uint256 constant SECONDS_PER_DAY = 1 days;
uint256 constant HOUR = 1 hours;
uint256 constant TEN_WAD = 10 ether;

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

interface IPrimexProxyAdmin {
    function upgradeBeacon(UpgradeableBeacon beacon, address implementation) external;

    function changeBeaconProxyAdmin(UpgradeableBeacon beacon, address newAdmin) external;
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

// solhint-disable-next-line func-visibility
function _require(bool condition, bytes4 selector) pure {
    if (!condition) _revert(selector);
}

// solhint-disable-next-line func-visibility
function _revert(bytes4 selector) pure {
    // solhint-disable-next-line no-inline-assembly
    assembly ("memory-safe") {
        let free_mem_ptr := mload(64)
        mstore(free_mem_ptr, selector)
        revert(free_mem_ptr, 4)
    }
}

library Errors {
    event Log(bytes4 error);

    //common
    error ADDRESS_NOT_SUPPORTED();
    error FORBIDDEN();
    error AMOUNT_IS_0();
    error CALLER_IS_NOT_TRADER();
    error CONDITION_INDEX_IS_OUT_OF_BOUNDS();
    error INVALID_PERCENT_NUMBER();
    error INVALID_SECURITY_BUFFER();
    error INVALID_MAINTENANCE_BUFFER();
    error TOKEN_ADDRESS_IS_ZERO();
    error IDENTICAL_TOKEN_ADDRESSES();
    error ASSET_DECIMALS_EXCEEDS_MAX_VALUE();
    error CAN_NOT_ADD_WITH_ZERO_ADDRESS();
    error SHOULD_BE_DIFFERENT_ASSETS_IN_SPOT();
    error TOKEN_NOT_SUPPORTED();
    error INSUFFICIENT_DEPOSIT();
    error DEPOSIT_IN_THIRD_ASSET_SHARES_ON_DEX_LENGTH_SHOULD_BE_0();
    error SHOULD_NOT_HAVE_DUPLICATES();
    error DEPOSITED_TO_BORROWED_SHARES_ON_DEX_LENGTH_SHOULD_BE_0();
    error DEPOSIT_TO_BORROWED_SHARES_ON_DEX_LENGTH_SHOULD_BE_0();
    // error LIMIT_PRICE_IS_ZERO();
    error BUCKET_IS_NOT_ACTIVE();
    error DIFFERENT_DATA_LENGTH();
    error RECIPIENT_OR_SENDER_MUST_BE_ON_WHITE_LIST();
    error SLIPPAGE_TOLERANCE_EXCEEDED();
    error OPERATION_NOT_SUPPORTED();
    error SENDER_IS_BLACKLISTED();
    error NATIVE_CURRENCY_CANNOT_BE_ASSET();
    error DISABLED_TRANSFER_NATIVE_CURRENCY();
    error INVALID_AMOUNT();

    // bonus executor
    error CALLER_IS_NOT_NFT();
    error BONUS_FOR_BUCKET_ALREADY_ACTIVATED();
    error WRONG_LENGTH();
    error BONUS_DOES_NOT_EXIST();
    error CALLER_IS_NOT_DEBT_TOKEN();
    error CALLER_IS_NOT_P_TOKEN();
    error MAX_BONUS_COUNT_EXCEEDED();
    error TIER_IS_NOT_ACTIVE();
    error BONUS_PERCENT_IS_ZERO();

    // bucket
    error INCORRECT_LIQUIDITY_MINING_PARAMS();
    error PAIR_PRICE_DROP_IS_NOT_CORRECT();
    error ASSET_IS_NOT_SUPPORTED();
    error BUCKET_OUTSIDE_PRIMEX_PROTOCOL();
    error DEADLINE_IS_PASSED();
    error DEADLINE_IS_NOT_PASSED();
    error BUCKET_IS_NOT_LAUNCHED();
    error BURN_AMOUNT_EXCEEDS_PROTOCOL_DEBT();
    error LIQUIDITY_INDEX_OVERFLOW();
    error BORROW_INDEX_OVERFLOW();
    error BAR_OVERFLOW();
    error LAR_OVERFLOW();
    error UR_IS_MORE_THAN_1();
    error ASSET_ALREADY_SUPPORTED();
    error DEPOSIT_IS_MORE_AMOUNT_PER_USER();
    error DEPOSIT_EXCEEDS_MAX_TOTAL_DEPOSIT();
    error MINING_AMOUNT_WITHDRAW_IS_LOCKED_ON_STABILIZATION_PERIOD();
    error WITHDRAW_RATE_IS_MORE_10_PERCENT();
    error INVALID_FEE_BUFFER();
    error RESERVE_RATE_SHOULD_BE_LESS_THAN_1();
    error MAX_TOTAL_DEPOSIT_IS_ZERO();
    error AMOUNT_SCALED_SHOULD_BE_GREATER_THAN_ZERO();
    error NOT_ENOUGH_LIQUIDITY_IN_THE_BUCKET();

    // p/debt token, PMXToken
    error BUCKET_IS_IMMUTABLE();
    error INVALID_MINT_AMOUNT();
    error INVALID_BURN_AMOUNT();
    error TRANSFER_NOT_SUPPORTED();
    error APPROVE_NOT_SUPPORTED();
    error CALLER_IS_NOT_BUCKET();
    error CALLER_IS_NOT_A_BUCKET_FACTORY();
    error CALLER_IS_NOT_P_TOKEN_RECEIVER();
    error DURATION_MUST_BE_MORE_THAN_0();
    error INCORRECT_ID();
    error THERE_ARE_NO_LOCK_DEPOSITS();
    error LOCK_TIME_IS_NOT_EXPIRED();
    error TRANSFER_AMOUNT_EXCEED_ALLOWANCE();
    error CALLER_IS_NOT_A_MINTER();
    error ACTION_ONLY_WITH_AVAILABLE_BALANCE();
    error FEE_DECREASER_CALL_FAILED();
    error TRADER_REWARD_DISTRIBUTOR_CALL_FAILED();
    error INTEREST_INCREASER_CALL_FAILED();
    error LENDER_REWARD_DISTRIBUTOR_CALL_FAILED();
    error DEPOSIT_DOES_NOT_EXIST();
    error RECIPIENT_IS_BLACKLISTED();

    //LOM
    error ORDER_CAN_NOT_BE_FILLED();
    error ORDER_DOES_NOT_EXIST();
    error ORDER_IS_NOT_SPOT();
    error LEVERAGE_MUST_BE_MORE_THAN_1();
    error CANNOT_CHANGE_SPOT_ORDER_TO_MARGIN();
    error SHOULD_HAVE_OPEN_CONDITIONS();
    error INCORRECT_LEVERAGE();
    error INCORRECT_DEADLINE();
    error LEVERAGE_SHOULD_BE_1();
    error LEVERAGE_EXCEEDS_MAX_LEVERAGE();
    error SHOULD_OPEN_POSITION();
    error IS_SPOT_ORDER();
    error SHOULD_NOT_HAVE_CLOSE_CONDITIONS();
    error ORDER_HAS_EXPIRED();

    // LiquidityMiningRewardDistributor
    error BUCKET_IS_NOT_STABLE();
    error ATTEMPT_TO_WITHDRAW_MORE_THAN_DEPOSITED();
    error WITHDRAW_PMX_BY_ADMIN_FORBIDDEN();

    // nft
    error TOKEN_IS_BLOCKED();
    error ONLY_MINTERS();
    error PROGRAM_IS_NOT_ACTIVE();
    error CALLER_IS_NOT_OWNER();
    error TOKEN_IS_ALREADY_ACTIVATED();
    error WRONG_NETWORK();
    error ID_DOES_NOT_EXIST();
    error WRONG_URIS_LENGTH();

    // PM
    error ASSET_ADDRESS_NOT_SUPPORTED();
    error IDENTICAL_ASSET_ADDRESSES();
    error POSITION_DOES_NOT_EXIST();
    error AMOUNT_IS_MORE_THAN_POSITION_AMOUNT();
    error BORROWED_AMOUNT_IS_ZERO();
    error IS_SPOT_POSITION();
    error AMOUNT_IS_MORE_THAN_DEPOSIT();
    error DECREASE_AMOUNT_IS_ZERO();
    error INSUFFICIENT_DEPOSIT_SIZE();
    error IS_NOT_RISKY_OR_CANNOT_BE_CLOSED();
    error BUCKET_SHOULD_BE_UNDEFINED();
    error DEPOSIT_IN_THIRD_ASSET_ROUTES_LENGTH_SHOULD_BE_0();
    error POSITION_CANNOT_BE_CLOSED_FOR_THIS_REASON();
    error ADDRESS_IS_ZERO();
    error WRONG_TRUSTED_MULTIPLIER();
    error POSITION_SIZE_EXCEEDED();
    error POSITION_BUCKET_IS_INCORRECT();
    error THERE_MUST_BE_AT_LEAST_ONE_POSITION();
    error NOTHING_TO_CLOSE();

    // BatchManager
    error PARAMS_LENGTH_MISMATCH();
    error BATCH_CANNOT_BE_CLOSED_FOR_THIS_REASON();
    error CLOSE_CONDITION_IS_NOT_CORRECT();
    error SOLD_ASSET_IS_INCORRECT();

    // Price Oracle
    error ZERO_EXCHANGE_RATE();
    error NO_PRICEFEED_FOUND();
    error NO_PRICE_DROP_FEED_FOUND();

    //DNS
    error INCORRECT_FEE_RATE();
    error BUCKET_ALREADY_FROZEN();
    error BUCKET_IS_ALREADY_ADDED();
    error DEX_IS_ALREADY_ACTIVATED();
    error DEX_IS_ALREADY_FROZEN();
    error DEX_IS_ALREADY_ADDED();
    error BUCKET_NOT_ADDED();
    error DEX_NOT_ACTIVE();
    error BUCKET_ALREADY_ACTIVATED();
    error DEX_NOT_ADDED();
    error BUCKET_IS_INACTIVE();
    error WITHDRAWAL_NOT_ALLOWED();
    error BUCKET_IS_ALREADY_DEPRECATED();

    // Primex upkeep
    error NUMBER_IS_0();

    //referral program, WhiteBlackList
    error CALLER_ALREADY_REGISTERED();
    error MISMATCH();
    error PARENT_NOT_WHITELISTED();
    error ADDRESS_ALREADY_WHITELISTED();
    error ADDRESS_ALREADY_BLACKLISTED();
    error ADDRESS_NOT_BLACKLISTED();
    error ADDRESS_NOT_WHITELISTED();
    error ADDRESS_NOT_UNLISTED();
    error ADDRESS_IS_WHITELISTED();
    error ADDRESS_IS_NOT_CONTRACT();

    //Reserve
    error BURN_AMOUNT_IS_ZERO();
    error CALLER_IS_NOT_EXECUTOR();
    error ADDRESS_NOT_PRIMEX_BUCKET();
    error NOT_SUFFICIENT_RESERVE_BALANCE();
    error INCORRECT_TRANSFER_RESTRICTIONS();

    //Vault
    error AMOUNT_EXCEEDS_AVAILABLE_BALANCE();
    error INSUFFICIENT_FREE_ASSETS();
    error CALLER_IS_NOT_SPENDER();

    //Pricing Library
    error IDENTICAL_ASSETS();
    error SUM_OF_SHARES_SHOULD_BE_GREATER_THAN_ZERO();
    error DIFFERENT_PRICE_DEX_AND_ORACLE();
    error TAKE_PROFIT_IS_LTE_LIMIT_PRICE();
    error STOP_LOSS_IS_GTE_LIMIT_PRICE();
    error STOP_LOSS_IS_LTE_LIQUIDATION_PRICE();
    error INSUFFICIENT_POSITION_SIZE();
    error INCORRECT_PATH();
    error DEPOSITED_TO_BORROWED_ROUTES_LENGTH_SHOULD_BE_0();
    error INCORRECT_CM_TYPE();

    // Token transfers
    error TOKEN_TRANSFER_IN_FAILED();
    error TOKEN_TRANSFER_IN_OVERFLOW();
    error TOKEN_TRANSFER_OUT_FAILED();
    error NATIVE_TOKEN_TRANSFER_FAILED();

    // Conditional Managers
    error LOW_PRICE_ROUND_IS_LESS_HIGH_PRICE_ROUND();
    error TRAILING_DELTA_IS_INCORRECT();
    error DATA_FOR_ROUND_DOES_NOT_EXIST();
    error HIGH_PRICE_TIMESTAMP_IS_INCORRECT();
    error NO_PRICE_FEED_INTERSECTION();
    error SHOULD_BE_CCM();
    error SHOULD_BE_COM();

    //Lens
    error DEPOSITED_AMOUNT_IS_0();
    error SPOT_DEPOSITED_ASSET_SHOULD_BE_EQUAL_BORROWED_ASSET();
    error ZERO_ASSET_ADDRESS();
    error ASSETS_SHOULD_BE_DIFFERENT();
    error ZERO_SHARES();
    error SHARES_AMOUNT_IS_GREATER_THAN_AMOUNT_TO_SELL();
    error NO_ACTIVE_DEXES();

    //Bots
    error WRONG_BALANCES();
    error INVALID_INDEX();
    error INVALID_DIVIDER();
    error ARRAYS_LENGTHS_IS_NOT_EQUAL();
    error DENOMINATOR_IS_0();

    //DexAdapter
    error ZERO_AMOUNT_IN();
    error ZERO_AMOUNT();
    error UNKNOWN_DEX_TYPE();
    error REVERTED_WITHOUT_A_STRING_TRY_TO_CHECK_THE_ANCILLARY_DATA();
    error DELTA_OF_TOKEN_OUT_HAS_POSITIVE_VALUE();
    error DELTA_OF_TOKEN_IN_HAS_NEGATIVE_VALUE();
    error QUOTER_IS_NOT_PROVIDED();
    error DEX_ROUTER_NOT_SUPPORTED();
    error QUOTER_NOT_SUPPORTED();
    error SWAP_DEADLINE_PASSED();

    //SpotTradingRewardDistributor
    error PERIOD_DURATION_IS_ZERO();
    error REWARD_AMOUNT_IS_ZERO();
    error REWARD_PER_PERIOD_IS_NOT_CORRECT();

    //ActivityRewardDistributor
    error TOTAL_REWARD_AMOUNT_IS_ZERO();
    error REWARD_PER_DAY_IS_NOT_CORRECT();
    error ZERO_BUCKET_ADDRESS();
    //KeeperRewardDistributor
    error INCORRECT_PART_IN_REWARD();

    //Treasury
    error TRANSFER_RESTRICTIONS_NOT_MET();
    error INSUFFICIENT_NATIVE_TOKEN_BALANCE();
    error INSUFFICIENT_TOKEN_BALANCE();
    error EXCEEDED_MAX_AMOUNT_DURING_TIMEFRAME();
    error EXCEEDED_MAX_SPENDING_LIMITS();
    error SPENDING_LIMITS_ARE_INCORRECT();
    error SPENDER_IS_NOT_EXIST();
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {ProxyAdmin, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./libraries/Errors.sol";
import {BIG_TIMELOCK_ADMIN} from "./Constants.sol";
import {IPrimexProxyAdmin} from "./interfaces/IPrimexProxyAdmin.sol";

/**
 * @dev This is openzeppelin proxy admin with AccessControl access.
 * Also, there remains the functionality of the Ownable contract
 * for compatibility with the hardhat-deploy plugin,
 * but it does not give privileged access
 */
contract PrimexProxyAdmin is ProxyAdmin, IPrimexProxyAdmin {
    address public immutable registry;

    modifier onlyRole(bytes32 _role) {
        _require(IAccessControl(registry).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    constructor(address _registry) {
        _transferOwnership(address(this));
        _require(
            IERC165(_registry).supportsInterface(type(IAccessControl).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        registry = _registry;
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(
        ITransparentUpgradeableProxy proxy,
        address newAdmin
    ) public override onlyRole(BIG_TIMELOCK_ADMIN) {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Changes the admin of the `beacon` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeBeaconProxyAdmin(
        UpgradeableBeacon beacon,
        address newAdmin
    ) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        beacon.transferOwnership(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(
        ITransparentUpgradeableProxy proxy,
        address implementation
    ) public override onlyRole(BIG_TIMELOCK_ADMIN) {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        ITransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable override onlyRole(BIG_TIMELOCK_ADMIN) {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }

    /**
     * @dev Upgrades the beacon to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     * - implementation must be a contract.
     */

    function upgradeBeacon(
        UpgradeableBeacon beacon,
        address implementation
    ) public override onlyRole(BIG_TIMELOCK_ADMIN) {
        beacon.upgradeTo(implementation);
    }
}