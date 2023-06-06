// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
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
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
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
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
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
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

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
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

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
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

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
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
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
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@strategy/IStrategy.sol";
import "@vault/FeeOracle.sol";

contract AddressRegistry is OwnableUpgradeable {
    /// FeeOracle
    FeeOracle public feeOracle;
    /// Router
    address public router;
    /// Mapping for coin and its support strategy
    mapping(address => IStrategy[]) public coinToStrategy;
    /// Mapping for strategy and its whitelisted status indicated by timestamp
    mapping(IStrategy => uint256) public strategyWhitelist;
    /// Mapping for rebalancer and its whitelisted status indicated by timestamp
    mapping(address => uint256) public rebalancerWhitelist;
    /// Array of supported coins
    address[] public supportedCoinAddresses;

    event SetRouter(address indexed router);
    event AddStrategy(IStrategy indexed strategy, address[] indexed coins);
    event AddRebalancer(address indexed rebalancer);
    event RemoveStrategy(IStrategy indexed strategy);
    event RemoveRebalancer(address indexed rebalancer);
    event Initialized(address indexed feeOracle, address indexed router);

    constructor() {
        _disableInitializers();
    }

    function init(FeeOracle _feeOracle, address _router) external initializer {
        require(
            address(_feeOracle) != address(0),
            "_feeOracle address can't be zero"
        );
        require(_router != address(0), "_router address can't be zero");

        __Ownable_init();
        feeOracle = _feeOracle;
        router = _router;
        emit Initialized(address(_feeOracle), _router);
    }

    function getSupportedCoinAddresses()
        external
        view
        returns (address[] memory)
    {
        return supportedCoinAddresses;
    }

    /// @notice Set router
    /// @param _router address of router
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "_router address can't be zero");
        router = _router;

        emit SetRouter(_router);
    }

    /// @notice Add strategy for given coins
    /// @param strategy address of strategy
    /// @param coins array of coins that strategy supports
    function addStrategy(
        IStrategy strategy,
        address[] calldata coins
    ) external onlyOwner {
        require(
            strategyWhitelist[strategy] == 0,
            "Strategy already whitelisted"
        );
        for (uint256 i; i < coins.length; ) {
            uint256 j;
            /// add strategy
            coinToStrategy[coins[i]].push(strategy);

            uint256 supportedCoinLength = supportedCoinAddresses.length;
            for (j = 0; j < supportedCoinLength; j++) {
                if (supportedCoinAddresses[j] == coins[i]) {
                    break;
                }
            }
            if (j == supportedCoinLength) {
                supportedCoinAddresses.push(coins[i]);
            }

            unchecked {
                i++;
            }
        }
        strategyWhitelist[strategy] = block.timestamp + 1 days;

        emit AddStrategy(strategy, coins);
    }

    /// @notice Add rebalancer
    /// @param rebalancer address of rebalancer
    function addRebalancer(address rebalancer) external onlyOwner {
        require(
            rebalancerWhitelist[rebalancer] == 0,
            "Rebalancer already whitelisted"
        );
        rebalancerWhitelist[rebalancer] = block.timestamp + 1 days;

        emit AddRebalancer(rebalancer);
    }

    /// @notice Remove strategy and remove all coins that supported by removed strategy
    /// @param strategy address of strategy
    function removeStrategy(IStrategy strategy) external onlyOwner {
        require(strategyWhitelist[strategy] != 0, "Strategy not whitelisted");
        strategyWhitelist[strategy] = 0;

        address[] memory coins = supportedCoinAddresses;
        uint256 coinLength = coins.length;
        uint256 emptyCoinCount;
        for (uint8 i; i < coinLength; i++) {
            IStrategy[] storage _strategies = coinToStrategy[coins[i]];
            uint256 strategyLength = _strategies.length;
            uint8 j;
            for (; j < strategyLength; j++) {
                if (_strategies[j] == strategy) {
                    uint256 lastElementIndex = _strategies.length - 1;
                    IStrategy lastElement = _strategies[lastElementIndex];
                    _strategies[j] = lastElement;
                    _strategies.pop();
                    break;
                }
            }

            /// Count support coin address when there is no strategy available
            if (j != strategyLength && strategyLength == 1) {
                emptyCoinCount += 1;
            }
        }
        if (emptyCoinCount != 0) {
            address[] memory newCoins = new address[](
                coinLength - emptyCoinCount
            );
            uint256 newCoinIndex = 0;

            for (uint8 i; i < coinLength; i++) {
                IStrategy[] memory _strategies = coinToStrategy[coins[i]];
                if (_strategies.length != 0) {
                    newCoins[newCoinIndex] = coins[i];
                    newCoinIndex++;
                }
            }

            supportedCoinAddresses = newCoins;
        }

        emit RemoveStrategy(strategy);
    }

    /// @notice Remove rebalancer
    /// @param rebalancer address of rebalancer to be removed
    function removeRebalancer(address rebalancer) external onlyOwner {
        require(
            rebalancerWhitelist[rebalancer] != 0,
            "Rebalancer not whitelisted"
        );
        rebalancerWhitelist[rebalancer] = 0;

        emit RemoveRebalancer(rebalancer);
    }

    /// @notice Get all supported strategies for given coin address
    /// @param coin address of coin
    function getCoinToStrategy(
        address coin
    ) external view returns (IStrategy[] memory strategies) {
        uint256 activeStrategies = 0;
        uint256 strategyLengthForCoin = coinToStrategy[coin].length;
        IStrategy[] memory strategiesForCoin = coinToStrategy[coin];
        // count active strategies
        for (uint256 i; i < strategyLengthForCoin; i++) {
            if (
                strategyWhitelist[strategiesForCoin[i]] < block.timestamp &&
                strategyWhitelist[strategiesForCoin[i]] != 0
            ) {
                activeStrategies++;
            }
        }
        // create array of active strategies
        uint j = 0;
        strategies = new IStrategy[](activeStrategies);
        for (uint256 i; i < strategyLengthForCoin; i++) {
            if (
                strategyWhitelist[strategiesForCoin[i]] < block.timestamp &&
                strategyWhitelist[strategiesForCoin[i]] != 0
            ) {
                strategies[j] = strategiesForCoin[i];
                j++;
            }
        }
    }

    /// @notice Get whitelisted status of given strategy
    /// @param strategy address of strategy
    function isWhitelistedStrategy(
        IStrategy strategy
    ) external view returns (bool) {
        return
            block.timestamp >= strategyWhitelist[strategy] &&
            strategyWhitelist[strategy] != 0;
    }

    /// @notice Get whitelisted status of given rebalancer
    /// @param rebalancer address of rebalancer
    function isWhitelistedRebalancer(
        address rebalancer
    ) external view returns (bool) {
        return
            block.timestamp >= rebalancerWhitelist[rebalancer] &&
            rebalancerWhitelist[rebalancer] != 0;
    }
}

pragma solidity 0.8.17;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "@vault/Vault.sol";
import "@/AddressRegistry.sol";
import "@/Rebalancer.sol";
import "@/TProxy.sol";

contract FactoryArbitrove is Ownable {
    address public addressRegistryAddress;
    address public vaultAddress;
    address public feeOracleAddress;
    address public rebalancerAddress;

    constructor() {
        AddressRegistry ar = new AddressRegistry();
        Vault v = new Vault();
        FeeOracle fO = new FeeOracle();
        addressRegistryAddress = address(ar);
        vaultAddress = address(v);
        feeOracleAddress = address(fO);
    }
    function upgradeImplementation(
        TProxy proxy,
        address newImplementation
    ) external onlyOwner {
        proxy.upgradeTo(newImplementation);
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./vault/IVault.sol";

interface IWETH {
    function deposit() external payable;

    function depositTo(address to) external payable;

    function transfer(address to, uint value) external returns (bool);

    function balanceOf(address) external returns (uint256);

    function withdraw(uint) external;
}

contract Rebalancer is OwnableUpgradeable {
    using SafeERC20 for IERC20;
    IVault public vault;
    IWETH public weth;

    event Initialized(address indexed vault, address indexed weth);
    event SetVault(address indexed vault);
    event SetWeth(address indexed weth);
    event Rebalance(uint256 indexed amount);
    event WithdrawToken(address indexed token, uint256 indexed amount);

    constructor() {
        _disableInitializers();
    }

    receive() external payable {
        require(
            msg.sender == address(vault),
            "Eth deposit's only available for vault."
        );
        _rebalance(msg.value);
    }

    /// @notice Initialization
    /// @param _vault vault address
    /// @param _weth weth address
    function init(IVault _vault, IWETH _weth) external initializer {
        require(address(_vault) != address(0), "Invalid vault address");
        require(address(_weth) != address(0), "Invalid weth address");

        __Ownable_init();
        vault = _vault;
        weth = _weth;
        emit Initialized(address(vault), address(weth));
    }

    /// @notice Set vault
    /// @param _vault vault address
    function setVault(IVault _vault) external onlyOwner {
        require(address(_vault) != address(0), "Invalid vault address");

        vault = _vault;
        emit SetVault(address(vault));
    }

    /// @notice Set weth
    /// @param _weth weth address
    function setWeth(IWETH _weth) external onlyOwner {
        require(address(_weth) != address(0), "Invalid weth address");

        weth = _weth;
        emit SetWeth(address(weth));
    }

    /// @notice withdraw token for emergency
    /// @param token token address to withdraw
    function withdrawToken(address token) external onlyOwner {
        if (token == address(0)) {
            uint256 amount = address(this).balance;
            (bool success, ) = _msgSender().call{value: amount}("");
            require(success, "eth withdraw failed");
            emit WithdrawToken(token, amount);
        } else {
            uint256 amount = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransfer(_msgSender(), amount);
            emit WithdrawToken(token, amount);
        }
    }

    /// @notice Deposit amount of weth and send back to vault
    /// @param amount amount of weth to deposit
    function _rebalance(uint256 amount) internal {
        uint256 beforeBalance = weth.balanceOf(address(this));
        weth.deposit{value: amount}();
        uint256 afterBalance = weth.balanceOf(address(this));
        require(
            afterBalance - beforeBalance == amount,
            "WETH deposit amount error"
        );
        IERC20(address(weth)).safeTransfer(address(vault), amount);
        emit Rebalance(amount);
    }
}

pragma solidity 0.8.17;
import "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract TProxy is TransparentUpgradeableProxy {
    constructor(
        address i,
        address a,
        bytes memory c
    ) TransparentUpgradeableProxy(i, a, c) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// Strategy Interface
interface IStrategy {
    function getComponentAmount(address coin) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@vault/IVault.sol";
import "@structs/structs.sol";

/// Fee oracle contract that provides deposit and withdrawal fees to be used by vault contract
/// Find the formulas here: https://docs.google.com/spreadsheets/d/1K-x2kDNVfSKCEjaOtOS_gbQu5PcrkRccioJP1UBuLhs/edit#gid=0
/// The fees are based on the current weight of a coin in the vault compared to its target
contract FeeOracle is OwnableUpgradeable {
    /// targets
    CoinWeight[50] public targets;
    /// length of coin weight targets
    uint256 public targetsLength;
    /// max fee
    uint256 public maxFee;
    /// max bonus
    uint256 constant maxBonus = 0;
    /// weight denominator for weight calculation
    uint256 constant weightDenominator = 1e18;

    event SetTargets(CoinWeight[] indexed coinWeights);
    event SetMaxFee(uint256 indexed maxFee);
    event Initialized(uint256 indexed maxFee);

    constructor() {
        _disableInitializers();
    }

    function init(uint256 _maxFee) external initializer {
        require(_maxFee <= 0.5e18, "_maxFee can't be greater than 0.5e18");

        __Ownable_init();
        maxFee = _maxFee;

        emit Initialized(_maxFee);
    }

    function setMaxFee(uint256 _maxFee) external onlyOwner {
        require(_maxFee <= 0.5e18, "_maxFee can't be greater than 0.5e18");
        maxFee = _maxFee;
        emit SetMaxFee(_maxFee);
    }

    /// @notice Set target coin weights
    /// @param weights Coin weights to set
    function setTargets(CoinWeight[] memory weights) external onlyOwner {
        targetsLength = weights.length;
        require(weights.length <= 50, "too many weights");
        for (uint8 i; i < weights.length; ) {
            targets[i] = weights[i];
            unchecked {
                ++i;
            }
        }
        isNormalizedWeightArray(weights);
        emit SetTargets(weights);
    }

    function isInTarget(address coin) external view returns (bool) {
        uint256 _targetsLength = targetsLength;
        for (uint8 i; i < _targetsLength; ) {
            if (targets[i].coin == coin) return true;
            unchecked {
                ++i;
            }
        }
        return false;
    }

    /// @notice Get deposit fee
    /// @param params Deposit fee params
    /// @return fee Deposit fee
    /// @return weights Latest coin weights for vault before deposit
    /// @return tvlUSD1e18X Latest tvl for vault before deposit
    function getDepositFee(
        FeeParams memory params
    )
        external
        view
        returns (int256 fee, CoinWeight[] memory weights, uint256 tvlUSD1e18X)
    {
        CoinWeightsParams memory coinWeightParams = CoinWeightsParams({
            cpu: params.cpu,
            vault: params.vault,
            expireTimestamp: params.expireTimestamp
        });
        (weights, tvlUSD1e18X) = getCoinWeights(coinWeightParams);
        CoinWeight memory target = targets[params.position];
        CoinWeight memory currentCoinWeight = weights[params.position];
        uint256 __decimals = target.coin == address(0)
            ? 18
            : IERC20Metadata(target.coin).decimals();

        /// new weight calc
        /// formula: depositValue = depositAmount * depositPrice / 10**decimals
        uint256 depositValueUSD1e18X = (params.amount *
            params.cpu[params.position].price) / 10 ** __decimals;

        /// formula: currentCoinValue = currentCoinWeight * tvl / weightDenominator
        uint256 currentCoinValue = (currentCoinWeight.weight * tvlUSD1e18X) /
            weightDenominator;

        /// formula: newWeight = (currentCoinValue + depositValue) * weightDenominator / (tvl + depositValue)
        uint256 newWeight = ((currentCoinValue + depositValueUSD1e18X) *
            weightDenominator) / (tvlUSD1e18X + depositValueUSD1e18X);

        /// calculate distance
        /// calculate original distance
        /// formula: originalDistance = abs(currentWeight - targetWeight) / targetWeight
        uint256 originalDistance = getDistance(
            target.weight,
            currentCoinWeight.weight,
            false
        );
        /// calculate new distance
        /// formula: newDistance = abs(newWeight - targetWeight) / targetWeight
        uint256 newDistance = getDistance(target.weight, newWeight, false);
        require(newDistance < weightDenominator, "Too far away from target");
        if (originalDistance > newDistance) {
            // bonus
            uint256 improvement = originalDistance - newDistance;
            fee =
                (int256(improvement * maxBonus) * -1) /
                int256(weightDenominator);
        } else {
            // penalty
            uint256 deterioration = newDistance - originalDistance;
            fee = int256(deterioration * maxFee) / int256(weightDenominator);
        }
    }

    /// @notice Get withdrawal fee
    /// @param params Withdrawal fee params
    /// @return fee Withdrawal fee
    /// @return weights Latest coin weight for vault before withdraw
    /// @return tvlUSD1e18X Latest tvl for vault before withdraw
    function getWithdrawalFee(
        FeeParams memory params
    )
        external
        view
        returns (int256 fee, CoinWeight[] memory weights, uint256 tvlUSD1e18X)
    {
        CoinWeightsParams memory coinWeightParams = CoinWeightsParams({
            cpu: params.cpu,
            vault: params.vault,
            expireTimestamp: params.expireTimestamp
        });
        (weights, tvlUSD1e18X) = getCoinWeights(coinWeightParams);
        CoinWeight memory target = targets[params.position];
        CoinWeight memory currentCoinWeight = weights[params.position];
        uint256 __decimals = target.coin == address(0)
            ? 18
            : IERC20Metadata(target.coin).decimals();

        /// new weight calc
        /// formula: withdrawalValue = withdrawalAmount * withdrawalPrice / 10**decimals
        uint256 withdrawalValueUSD1e18X = (params.amount *
            params.cpu[params.position].price) / 10 ** __decimals;

        /// formula: currentCoinValue = currentCoinWeight * tvl / weightDenominator
        uint256 currentCoinValue = (currentCoinWeight.weight * tvlUSD1e18X) /
            weightDenominator;

        /// formula: newWeight = (currentCoinValue - withdrawalValue) * weightDenominator / (tvl - withdrawalValue)
        uint256 newWeight = ((currentCoinValue - withdrawalValueUSD1e18X) *
            weightDenominator) / (tvlUSD1e18X - withdrawalValueUSD1e18X);

        // calculate distance
        /// calculate original distance
        /// formula: originalDistance = abs(currentWeight - targetWeight) / targetWeight
        uint256 originalDistance = getDistance(
            target.weight,
            currentCoinWeight.weight,
            true
        );
        /// calculate new distance
        /// formula: newDistance = abs(newWeight - targetWeight) / targetWeight
        uint256 newDistance = getDistance(target.weight, newWeight, true);
        require(newDistance < weightDenominator, "Too far away from target");
        if (originalDistance > newDistance) {
            // bonus
            uint256 improvement = originalDistance - newDistance;
            fee = int256(improvement * maxBonus) / int256(weightDenominator);
        } else {
            // penalty
            uint256 deterioration = newDistance - originalDistance;
            fee =
                (int256(deterioration * maxFee) * -1) /
                int256(weightDenominator);
        }
    }

    /// @notice Get targets
    /// @return targets coin weights
    function getTargets() external view returns (CoinWeight[] memory) {
        uint256 _targetsLength = targetsLength;
        CoinWeight[] memory _targets = new CoinWeight[](_targetsLength);
        for (uint8 i; i < _targetsLength; ) {
            _targets[i] = targets[i];
            unchecked {
                ++i;
            }
        }
        return _targets;
    }

    /// @notice Get current coin weights and tvl for given params
    /// @param params CoinWeightsPrams for get coin weights
    /// @return weights Current coin weights for given params
    /// @return tvlUSD1e18X TVL for given vault
    function getCoinWeights(
        CoinWeightsParams memory params
    ) public view returns (CoinWeight[] memory weights, uint256 tvlUSD1e18X) {
        require(
            block.timestamp < params.expireTimestamp,
            "Execution window passed"
        );
        uint256 _targetsLength = targetsLength;
        weights = new CoinWeight[](_targetsLength);
        require(params.cpu.length == _targetsLength, "Oracle length error");
        CoinWeight[50] memory _targets = targets;
        for (uint8 i; i < _targetsLength; ) {
            require(
                params.cpu[i].coin == _targets[i].coin,
                "Oracle order error"
            );
            /// Get available amount of coin for the vault per every coin
            /// formula: coinVaultAmount + coinStrategiesAmount - coinDebtAmount
            uint256 amount = params.vault.getAmountAcrossStrategies(
                _targets[i].coin
            ) - params.vault.debt(_targets[i].coin);
            /// Initialize coinWeight with available amount of coin
            weights[i] = CoinWeight(params.cpu[i].coin, amount);
            unchecked {
                i++;
            }
        }

        /// Calc tvl
        uint8[] memory __decimals = new uint8[](_targetsLength);
        for (uint8 i; i < _targetsLength; ) {
            __decimals[i] = _targets[i].coin == address(0)
                ? 18
                : IERC20Metadata(_targets[i].coin).decimals();
            /// Calculate tvl over the coin weights
            /// Set weight with every coin value
            /// formula: coinValue = coinAmount * coinPriceUSD / 10**coinDecimal
            weights[i].weight =
                (weights[i].weight * params.cpu[i].price) /
                10 ** __decimals[i];
            /// formula: tvl += coinValue
            tvlUSD1e18X += weights[i].weight;
            unchecked {
                i++;
            }
        }

        /// Normalize
        for (uint8 i; i < _targetsLength; ) {
            /// Normalize coin weights
            /// formula: weight = coinValue * weightDenominator / tvl
            weights[i].weight =
                (weights[i].weight * weightDenominator) /
                tvlUSD1e18X;
            unchecked {
                i++;
            }
        }
        isNormalizedWeightArray(weights);
    }

    /// @notice Check if weights array is normalized or not
    /// @param weights Coin weight array that needs to be checked
    function isNormalizedWeightArray(
        CoinWeight[] memory weights
    ) internal pure {
        uint256 totalWeight = 0;
        for (uint8 i; i < weights.length; ) {
            totalWeight += weights[i].weight;
            unchecked {
                i++;
            }
        }
        // compensate for rounding errors
        require(
            totalWeight >= weightDenominator - weights.length,
            "Weight error"
        );
        require(totalWeight <= weightDenominator, "Weight error 2");
    }

    /// @notice Get distance between two weights. The "distance" is calculated as a percentage change of the new weight compared to the target weight.
    /// @param targetWeight Standard weight that calculate distance
    /// @param comparedWeight Compared weight that calculate distance
    /// @param method deposit or withdraw
    /// @return distance
    function getDistance(
        uint256 targetWeight,
        uint256 comparedWeight,
        bool method
    ) internal pure returns (uint256) {
        /// formula: distance = abs(targetWeight - comparedWeight) * weightDenominator / targetWeight
        if (targetWeight == 0) return method ? 0 : weightDenominator;
        return
            targetWeight >= comparedWeight
                ? ((targetWeight - comparedWeight) * weightDenominator) /
                    targetWeight
                : ((comparedWeight - targetWeight) * weightDenominator) /
                    targetWeight;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// Vault Interface
interface IVault {
    function getAmountAcrossStrategies(
        address coin
    ) external view returns (uint256 value);

    function debt(address coin) external view returns (uint256 value);

    function rebalance(
        address destination,
        address coin,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@vault/IVault.sol";
import "@strategy/IStrategy.sol";
import "@/AddressRegistry.sol";
import "@structs/structs.sol";

/// The Vault contract provides a secure and flexible platform for depositing and withdrawing coins, as well as approving and depositing ETH to strategies.
contract Vault is OwnableUpgradeable, IVault, ERC20Upgradeable {
    using SafeERC20 for IERC20;
    struct DepositWithrawalParams {
        /// Deposit coin position in cpu array
        uint256 coinPositionInCPU;
        /// Deposit amount
        uint256 _amount;
        /// Vault's Coin price usd array
        CoinPriceUSD[] cpu;
        /// Expire time stamp
        uint256 expireTimestamp;
    }

    AddressRegistry public addressRegistry;
    /// USD price cap for coin
    /// only process certain amount of USD per coin
    mapping(address => uint256) public coinCap;
    /// block cap USD for block number
    mapping(uint256 => uint256) public blockCapCounter;
    /// only process certain amount of tx in USD per block
    uint256 public blockCapUSD;
    /// claimable debt amount for routers
    mapping(address => uint256) public debt;
    /// pool ratio denominator for pool ratio calculation
    uint256 constant poolRatioDenominator = 1e18;

    int256 constant weightDenominator = 1e18;

    event SetAddressRegistry(AddressRegistry indexed addressRegistry);
    event SetCoinCap(address indexed coin, uint256 indexed cap);
    event SetBlockCap(uint256 indexed cap);
    event DepositEthToStrategy(
        address indexed strategy,
        uint256 indexed amount
    );
    event Rebalance(
        address indexed destination,
        address indexed coin,
        uint256 indexed amount
    );

    constructor() {
        _disableInitializers();
    }

    receive() external payable {}

    modifier onlyRouter() {
        require(
            msg.sender == addressRegistry.router(),
            "only router has permitted"
        );
        _;
    }

    function init829(
        AddressRegistry _addressRegistry
    ) external payable initializer {
        require(
            address(_addressRegistry) != address(0),
            "_addressRegistry address can't be zero"
        );
        require(msg.value >= 1e15);

        __Ownable_init();
        __ERC20_init("ALP", "ALP");
        addressRegistry = _addressRegistry;
        _mint(msg.sender, msg.value);
        emit SetAddressRegistry(_addressRegistry);
    }

    /// @notice Set addressRegistry
    /// @param _addressRegistry Address registry contract
    function setAddressRegistry(
        AddressRegistry _addressRegistry
    ) external onlyOwner {
        require(
            address(_addressRegistry) != address(0),
            "_addressRegistry address can't be zero"
        );

        addressRegistry = _addressRegistry;

        emit SetAddressRegistry(_addressRegistry);
    }

    /// @notice Set coin cap usd
    /// @param coin Address of coin to set cap
    /// @param cap Amount of cap to set
    function setCoinCapUSD(address coin, uint256 cap) external onlyOwner {
        require(coin != address(0), "invalid coin address");
        coinCap[coin] = cap;
        emit SetCoinCap(coin, cap);
    }

    /// @notice Set block cap for vault
    /// @param cap Amount of cap to set
    function setBlockCap(uint256 cap) external onlyOwner {
        blockCapUSD = cap;
        emit SetBlockCap(cap);
    }

    /// @notice Deposit. Note that the deposit amount is transferred to the vault from the router after checking the amount of ALP minted. If the amount of ALP minted is not correct, the call will revert and the router will refund.
    /// @param params Deposit params
    function deposit(DepositWithrawalParams memory params) external onlyRouter {
        FeeParams memory feeParams = FeeParams({
            cpu: params.cpu,
            vault: this,
            expireTimestamp: params.expireTimestamp,
            position: params.coinPositionInCPU,
            amount: params._amount
        });
        address coin = params.cpu[params.coinPositionInCPU].coin;
        uint256 __decimals = IERC20Metadata(coin).decimals();
        uint256 coinCapValue = ((getAmountAcrossStrategies(coin) +
            params._amount) * params.cpu[params.coinPositionInCPU].price) /
            10 ** __decimals;
        require(coinCapValue < coinCap[coin], "Coin cap reached");

        /// calculate deposit value
        /// formula: depositValue = coinPriceUSD * coinDepositAmount / 10**coinDecimal
        uint256 depositValue = (params.cpu[params.coinPositionInCPU].price *
            params._amount) / 10 ** __decimals;
        require(
            depositValue + blockCapCounter[block.number] < blockCapUSD,
            "Block cap reached"
        );

        /// update blockCapCounter with depositValue
        blockCapCounter[block.number] += depositValue;

        /// Get deposit fee and tvl before deposit
        (int256 fee, , uint256 tvlUSD1e18X) = addressRegistry
            .feeOracle()
            .getDepositFee(feeParams);

        /// vault token mint
        /// poolRatio = depositValue * poolRatioDenominator / tvl
        uint256 poolRatio = (depositValue * poolRatioDenominator) / tvlUSD1e18X;
        /// mintAmountBeforeFee = poolRatio * totalSupply / poolRatioDenominator
        uint256 mintAmountBeforeFee = (poolRatio * totalSupply()) /
            poolRatioDenominator;
        /// mintAmount = mintAmountBeforeFee * (feeDenominator - fee) / feeDenominator
        uint256 mintAmount = (mintAmountBeforeFee *
            uint256(weightDenominator - fee)) / uint256(weightDenominator);
        _mint(msg.sender, mintAmount);
    }

    /// @notice Withdraw. Note that the amount of ALP burned is checked before the router calls `claimDebt` subsequently to claim the token. If the amount of ALP burned is not correct, the call will revert and the router will refund.
    /// @param params Withdraw params
    function withdraw(
        DepositWithrawalParams memory params
    ) external onlyRouter {
        FeeParams memory feeParams = FeeParams({
            cpu: params.cpu,
            vault: this,
            expireTimestamp: params.expireTimestamp,
            position: params.coinPositionInCPU,
            amount: params._amount
        });
        address coin = params.cpu[params.coinPositionInCPU].coin;
        uint256 __decimals = IERC20Metadata(coin).decimals();

        /// calculate withdrawal value
        /// formula: withdrawalValue = coinPriceUSD * withdrawalCoinAmount / 10**coinDecimal
        uint256 withdrawalValue = (params.cpu[params.coinPositionInCPU].price *
            params._amount) / 10 ** __decimals;
        require(
            withdrawalValue + blockCapCounter[block.number] < blockCapUSD,
            "Block cap reached"
        );
        blockCapCounter[block.number] += withdrawalValue;
        // no coin cap check for withdrawal

        /// Get withdrawal fee and tvl before withdraw
        (int256 fee, , uint256 tvlUSD1e18X) = addressRegistry
            .feeOracle()
            .getWithdrawalFee(feeParams);

        /// burn vault token
        /// poolRatio = withdrawalValue * poolRatioDenominator / tvl
        uint256 poolRatio = (withdrawalValue * poolRatioDenominator) /
            tvlUSD1e18X;
        /// burnAmountBeforeFee = poolRatio * totalSupply / poolRatioDenominator
        uint256 burnAmountBeforeFee = (poolRatio * totalSupply()) /
            poolRatioDenominator;
        /// burnAmount = burnAmountBeforeFee * (feeDenominator - fee) / feeDenominator
        uint256 burnAmount = (burnAmountBeforeFee *
            uint256(weightDenominator - fee)) / uint256(weightDenominator);

        _burn(msg.sender, burnAmount);

        /// increase claimable debt amount for withdrawing amount of coin later
        debt[coin] += params._amount;
    }

    /// @notice Claim `amount` debt from vault
    /// @param coin Address of coin to claim
    /// @param amount Amount of debt to claim
    function claimDebt(address coin, uint256 amount) external onlyRouter {
        require(debt[coin] >= amount, "insufficient debt amount for coin");
        debt[coin] -= amount;
        IERC20(coin).safeTransfer(msg.sender, amount);
    }

    /// @notice Approve `amount` of coin for strategy to use
    /// @param strategy Address of Strategy
    /// @param coin Address of coin
    /// @param amount Amount of coin to approve
    function approveStrategy(
        IStrategy strategy,
        address coin,
        uint256 amount
    ) external onlyOwner {
        require(address(strategy) != address(0), "invalid strategy address");
        require(
            addressRegistry.isWhitelistedStrategy(strategy),
            "strategy is not whitelisted"
        );

        /// verify coin is part of the strategy
        IStrategy[] memory strategies = addressRegistry.getCoinToStrategy(coin);
        uint256 i;
        for (; i < strategies.length; i++) {
            if (address(strategies[i]) == address(strategy)) break;
        }
        require(
            i != strategies.length,
            "provided coin is not the part of strategy"
        );

        /// approve coin for strategy
        IERC20(coin).safeApprove(address(strategy), amount);
    }

    /// @notice Deposit `amount` of ETH to strategy because ETH can't be approved. Note that this feature will not likely to be used. Trove mostly will be WETH based.
    /// @param strategy Address of Strategy
    /// @param amount Amount of ETH to deposit
    function depositETHToStrategy(
        IStrategy strategy,
        uint256 amount
    ) external onlyOwner {
        require(
            addressRegistry.isWhitelistedStrategy(strategy),
            "strategy is not whitelisted"
        );
        (bool depositSuccess, ) = address(strategy).call{value: amount}("");
        require(depositSuccess, "Deposit failed");
        emit DepositEthToStrategy(address(strategy), amount);
    }

    /// @notice Rebalance `amount` of coin from vault
    ///         The rebalance contract will be whitelisted by governance and effective after timelock on a case-by-case basis
    ///         typically, there will be 2 types of rebalance contract
    ///             1. on-chain rebalance. use of dexes like uniswap and camelot
    ///             2. otc rebalance. use of cexes or our partnership relationship with projects to acquire tokens
    /// @param destination Address of rebalance contract
    /// @param coin Address of coin
    /// @param amount Amount of coin to withdraw
    function rebalance(
        address destination,
        address coin,
        uint256 amount
    ) external onlyOwner {
        require(destination != address(0), "invalid destination");
        require(
            addressRegistry.isWhitelistedRebalancer(destination),
            "destination is not whitelisted"
        );
        if (coin == address(0)) {
            (bool success, ) = payable(destination).call{value: amount}("");
            require(success, "deposit to destination failed");
        } else {
            IERC20(coin).safeTransfer(destination, amount);
        }
        emit Rebalance(destination, coin, amount);
    }

    /// @notice Get aggregated amount of coin for vault and strategies
    /// @param coin Address of coin
    /// @return value Aggregated amount of coin
    function getAmountAcrossStrategies(
        address coin
    ) public view returns (uint256 value) {
        if (coin == address(0)) {
            value += address(this).balance;
        } else {
            value += IERC20(coin).balanceOf(address(this));
        }
        IStrategy[] memory strategies = addressRegistry.getCoinToStrategy(coin);
        for (uint256 i; i < strategies.length; ) {
            value += strategies[i].getComponentAmount(coin);
            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@vault/IVault.sol";

enum PairType {
    USDC,
    WETH
}

struct CoinPriceUSD {
    address coin;
    uint256 price;
}

struct CoinWeight {
    address coin;
    uint256 weight;
}

struct CoinValue {
    address coin;
    uint256 value;
}

struct CoinWeightsParams {
    CoinPriceUSD[] cpu;
    IVault vault;
    uint256 expireTimestamp;
}

struct FeeParams {
    CoinPriceUSD[] cpu;
    IVault vault;
    uint256 expireTimestamp;
    uint256 position;
    uint256 amount;
}