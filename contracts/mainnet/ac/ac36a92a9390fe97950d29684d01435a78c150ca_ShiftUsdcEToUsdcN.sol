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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
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

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "../interfaces/ILiquidityProvider.sol";
import "../interfaces/aave/IAToken.sol";
import "../interfaces/aaveV3/ATokenInterfaces.sol";

import "./openzeppelin/SafeERC20.sol";

/// @title Liquidity provider using aave V3 pools
contract AaveV3LiquidityProvider is ILiquidityProvider {
    using SafeERC20 for IERC20;

    /// @dev for migrations
    uint256 private version_;

    /// @dev the owner of this pool
    address public owner_;

    /// @dev token being invested
    IERC20 public underlying_;

    PoolAddressesProviderInterface public poolAddresses_;

    IAToken public aToken_;

    /**
     * @notice initialiser function
     *
     * @param _addressProvider address of the aave
     *         LendingPoolAddressesProvider contract
     *
     * @param _aToken address of the aToken
     * @param _owner address of the account that owns this pool
     */
    function init(
        address _addressProvider,
        address _aToken,
        address _owner
    ) external {
        require(version_ == 0, "contract is already initialized");
        require(_owner != address(0), "owner is empty");

        version_ = 1;

        owner_ = _owner;

        poolAddresses_ = PoolAddressesProviderInterface(_addressProvider);

        aToken_ = IAToken(_aToken);

        underlying_ = IERC20(aToken_.UNDERLYING_ASSET_ADDRESS());
    }

    /// @inheritdoc ILiquidityProvider
    function addToPool(uint _amount) external {
        require(msg.sender == owner_, "only the owner can use this");

        PoolInterface pool = PoolInterface(poolAddresses_.getPool());

        underlying_.safeApprove(address(pool), _amount);

        pool.supply(address(underlying_), _amount, address(this), 0);
    }

    /// @inheritdoc ILiquidityProvider
    function takeFromPool(uint _amount) external {
        require(msg.sender == owner_, "only the owner can use this");

        PoolInterface pool = PoolInterface(poolAddresses_.getPool());

        uint realAmount = pool.withdraw(address(underlying_), _amount, address(this));

        require(_amount == realAmount, "aave withdraw weird");

        underlying_.safeTransfer(msg.sender, realAmount);
    }

    /// @inheritdoc ILiquidityProvider
    function totalPoolAmount() external view returns (uint) {
        return aToken_.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

// Adjusted to use our local IERC20 interface instead of OpenZeppelin's

pragma solidity ^0.8.0;

import "../../interfaces/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

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
    using AddressUpgradeable for address;

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
            "approve from non-zero"
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
            require(oldAllowance >= value, "allowance went below 0");
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "erc20 op failed");
        }
    }
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "../interfaces/IEmergencyMode.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC2612.sol";
import "../interfaces/IFluidClient.sol";
import "../interfaces/ILiquidityProvider.sol";
import "../interfaces/IOperatorOwned.sol";
import "../interfaces/IToken.sol";
import "../interfaces/ITransferWithBeneficiary.sol";

import "./openzeppelin/SafeERC20.sol";

uint constant DEFAULT_MAX_UNCHECKED_REWARD = 1000;

/// @dev FEE_DENOM for the fees (ie, 10 is a 1% fee)
uint constant FEE_DENOM = 1000;

/// @title The fluid token ERC20 contract
// solhint-disable-next-line max-states-count
contract Token is
    IFluidClient,
    IERC2612,
    ITransferWithBeneficiary,
    IToken,
    IEmergencyMode,
    IOperatorOwned
{
    using SafeERC20 for IERC20;

    /* ~~~~~~~~~~ ERC20 FEATURES ~~~~~~~~~~ */

    mapping(address => uint256) private balances_;

    mapping(address => mapping(address => uint256)) private allowances_;

    uint8 private decimals_;

    uint256 private totalSupply_;

    string private name_;

    string private symbol_;

    /* ~~~~~~~~~~ HOUSEKEEPING ~~~~~~~~~~ */

    /// @dev if false, emergency mode is active - can be called by either the
    /// @dev operator, worker account or emergency council
    bool private noEmergencyMode_;

    // for migrations
    uint private version_;

    /* ~~~~~~~~~~ LIQUIDITY PROVIDER ~~~~~~~~~~ */

    // @custom:security non-reentrant
    ILiquidityProvider private pool_;

    /* ~~~~~~~~~~ DEPRECATED SLOTS ~~~~~~~~~~ */

    /// @dev deprecated, worker config is now handled externally
    // solhint-disable-next-line var-name-mixedcase
    address private __deprecated_1;

    /* ~~~~~~~~~~ OWNERSHIP ~~~~~~~~~~ */

    /// @dev emergency council that can activate emergency mode
    address private emergencyCouncil_;

    /// @dev account to use that created the contract (multisig account)
    address private operator_;

    /* ~~~~~~~~~~ DEPRECATED SLOTS ~~~~~~~~~~ */

    /// @dev deprecated, we don't track the last rewarded block for manual
    ///      rewards anymore
    // solhint-disable-next-line var-name-mixedcase
    uint private __deprecated_2;

    /// @dev [address] => [[block number] => [has the block been manually
    ///      rewarded by this user?]]
    /// @dev deprecated, we don't do manual rewards anymore
    // solhint-disable-nex-line var-name-mixedcase
    mapping (address => mapping(uint => uint)) private __deprecated_3;

    /// @dev amount a user has manually rewarded, to be removed from their
    ///      batched rewards
    /// @dev [address] => [amount manually rewarded]
    /// @dev deprecated, we don't do manual rewards anymore
    // solhint-disable-nex-line var-name-mixedcase
    mapping (address => uint) private __deprecated_4;

    /* ~~~~~~~~~~ SECURITY FEATURES ~~~~~~~~~~ */

    /// @dev the largest amount a reward can be to not get quarantined
    uint private maxUncheckedReward_;

    /// @dev [address] => [number of tokens the user won that have been quarantined]
    mapping (address => uint) private blockedRewards_;

    /* ~~~~~~~~~~ DEPRECATED SLOTS ~~~~~~~~~~ */

    // slither-disable-start unused-state constable-states naming-convention

    /*
     * These slots were used for the feature "mint limits" which we've
     * since entirely pulled.
     */

    /// @notice deprecated, mint limits no longer exist
    // solhint-disable-next-line var-name-mixedcase
    bool private __deprecated_5;

    /// @notice deprecated, mint limits no longer exist
    // solhint-disable-next-line var-name-mixedcase
    mapping (address => uint) private __deprecated_6;

    /// @notice deprecated, mint limits no longer exist
    // solhint-disable-next-line var-name-mixedcase
    mapping (address => uint) private __deprecated_7;

    /// @notice deprecated, mint limits no longer exist
    // solhint-disable-next-line var-name-mixedcase
    uint private __deprecated_8;

    /// @notice deprecated, mint limits no longer exist
    // solhint-disable-next-line var-name-mixedcase
    uint private __deprecated_9;

    /// @notice deprecated, mint limits no longer exist
    // solhint-disable-next-line var-name-mixedcase
    uint private __deprecated_10;

    // slither-disable-end

    /* ~~~~~~~~~~ ORACLE PAYOUTS ~~~~~~~~~~ */

    /// @dev account that can call the reward function, should be the
    ///      operator contract/
    address private oracle_;

    /* ~~~~~~~~~~ ERC2612 ~~~~~~~~~~ */

    // @dev nonces_ would be used for permit only, but it could be used for
    //      every off-chain sign if needed
    mapping (address => uint256) private nonces_;

    uint256 private initialChainId_;

    bytes32 private initialDomainSeparator_;

    /* ~~~~~~~~~~ FEE TAKING ~~~~~~~~~~ */

    /// @notice burnFee_ that's paid by the user when they burn
    uint256 private burnFee_;

    /// @notice feeRecipient_ that receives the fee paid by a user
    address private feeRecipient_;

    /// @notice burnFee_ that's paid by the user when they mint
    uint256 private mintFee_;

    /* ~~~~~~~~~~ SETUP FUNCTIONS ~~~~~~~~~~ */

    /**
     * @notice computeDomainSeparator that's used for EIP712
     */
    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name_)),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    function _setupEIP2612() internal {
        initialChainId_ = block.chainid;
        initialDomainSeparator_ = computeDomainSeparator();
    }

    /**
     * @notice initialiser function - sets the contract's data
     * @dev we pass in the metadata explicitly instead of sourcing from the
     * @dev underlying token because some underlying tokens don't implement
     * @dev these methods
     *
     * @param _liquidityProvider the `LiquidityProvider` contract
     *        address. Should have this contract as its owner.
     *
     * @param _decimals the fluid token's decimals (should be the same as the underlying token's)
     * @param _name the fluid token's name
     * @param _symbol the fluid token's symbol
     * @param _emergencyCouncil address that can activate emergency mode
     * @param _operator address that can release quarantine payouts and activate emergency mode
     * @param _oracle address that can call the reward function
     */
     function init(
        address _liquidityProvider,
        uint8 _decimals,
        string memory _name,
        string memory _symbol,
        address _emergencyCouncil,
        address _operator,
        address _oracle
    ) public {
        require(version_ == 0, "contract is already initialised");
        require(_operator != address(0), "operator zero");
        require(_oracle != address(0), "oracle zero");

        version_ = 1;

        // remember the operator for signing off on oracle changes, large payouts
        operator_ = _operator;

        oracle_ = _oracle;

        // remember the emergency council for shutting down this token
        emergencyCouncil_ = _emergencyCouncil;

        // remember the liquidity provider to deposit tokens into
        pool_ = ILiquidityProvider(_liquidityProvider);

        // sanity check
        // slither-disable-next-line unused-return
        underlyingToken().totalSupply();

        noEmergencyMode_ = true;

        // erc20 props
        decimals_ = _decimals;
        name_ = _name;
        symbol_ = _symbol;

        // initialise mint limits
        maxUncheckedReward_ = DEFAULT_MAX_UNCHECKED_REWARD;

        _setupEIP2612();
    }

    /**
     * @notice setupEIP2612, made public to support upgrades without a new migration
     */
    function setupEIP2612() public {
        require(msg.sender == operator_, "only operator/Token");

        _setupEIP2612();
    }

    /* ~~~~~~~~~~ INTERNAL FUNCTIONS ~~~~~~~~~~ */

    /// @dev _erc20In has the possibility depending on the underlying LP
    ///      behaviour to not mint the exact amount of tokens, so it returns it
    ///      here (currently won't happen on compound/aave)
    function _erc20In(
        address _spender,
        address _beneficiary,
        uint256 _amount
    ) internal returns (uint256) {
        require(noEmergencyMode_, "emergency mode!");

        // take underlying tokens from the user

        IERC20 underlying = underlyingToken();

        uint originalBalance = underlying.balanceOf(address(this));

        underlying.safeTransferFrom(_spender, address(this), _amount);

        uint finalBalance = underlying.balanceOf(address(this));

        // ensure the token is behaving

        require(finalBalance > originalBalance, "bad token bal");

        uint realAmount = finalBalance - originalBalance;

        // add the tokens to our compound pool

        underlying.safeTransfer(address(pool_), realAmount);

        pool_.addToPool(realAmount);

        // give the user fluid tokens

        // calculate the fee to take
        uint256 feeAmount =
            (mintFee_ != 0 && realAmount > mintFee_)
                ? (realAmount * mintFee_) / FEE_DENOM
                : 0;

        // calculate the amount to give the user
        uint256 mintAmount = realAmount - feeAmount;

        _mint(_beneficiary, mintAmount);

        emit MintFluid(_beneficiary, mintAmount);

        // mint the fee to the fee recipient
        if (feeAmount > 0) _mint(feeRecipient_, feeAmount);

        return realAmount;
    }

    function _erc20Out(
        address _sender,
        address _beneficiary,
        uint256 _amount
    ) internal returns (uint256) {
        // take the user's fluid tokens

         // if the fee amount > 0 and the burn fee is greater than 0, then
         // we take burn fee% of the amount given by the user

        uint256 feeAmount =
            (burnFee_ != 0 && _amount > burnFee_)
                ? (_amount * burnFee_) / FEE_DENOM
                : 0;

        // burn burnAmount

        uint256 burnAmount = _amount - feeAmount;

        // give them erc20, if the user's amount is greater than 100, then we keep 1%

        _burn(_sender, _amount);

        pool_.takeFromPool(burnAmount);

        emit BurnFluid(_sender, _amount);

        // send out the amounts

        underlyingToken().safeTransfer(_beneficiary, burnAmount);

        if (feeAmount > 0) _mint(feeRecipient_, feeAmount);

        return burnAmount;
    }

    /**
     * @dev rewards two users from the reward pool
     * @dev mints tokens and emits the reward event
     *
     * @param firstBlock the first block in the range being rewarded for
     * @param lastBlock the last block in the range being rewarded for
     * @param winner the address being rewarded
     * @param amount the amount being rewarded
     */
    function _rewardFromPool(
        uint256 firstBlock,
        uint256 lastBlock,
        address winner,
        uint256 amount
    ) internal {
        require(noEmergencyMode_, "emergency mode!");

        if (amount > maxUncheckedReward_) {
            // quarantine the reward
            emit BlockedReward(winner, amount, firstBlock, lastBlock);

            blockedRewards_[winner] += amount;

            return;
        }

        _mint(winner, amount);

        emit Reward(winner, amount, firstBlock, lastBlock);
    }


    function _reward(address winner, uint256 amount) internal {
        require(noEmergencyMode_, "emergency mode!");

        // mint some fluid tokens from the interest we've accrued

        _mint(winner, amount);
    }

    /// @dev _transfer is implemented by OpenZeppelin
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        // solhint-disable-next-line reason-string
        require(from != address(0), "ERC20: transfer from the zero address");

        // solhint-disable-next-line reason-string
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = balances_[from];

        // solhint-disable-next-line reason-string
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            balances_[from] = fromBalance - amount;
        }

        balances_[to] += amount;

        emit Transfer(from, to, amount);
    }

    /// @dev _mint is implemented by OpenZeppelin
    function _mint(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "ERC20: mint to the zero address");

        totalSupply_ += _amount;
        balances_[_account] += _amount;
        emit Transfer(address(0), _account, _amount);
    }

    /// @dev _burn is implemented by OpenZeppelin
    function _burn(address _account, uint256 _amount) internal virtual {
        // solhint-disable-next-line reason-string
        require(_account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = balances_[_account];

        // solhint-disable-next-line reason-string
        require(accountBalance >= _amount, "ERC20: burn amount exceeds balance");


        unchecked {
            balances_[_account] = accountBalance - _amount;

        }

        totalSupply_ -= _amount;

        emit Transfer(_account, address(0), _amount);
    }

    /// @dev _approve is implemented by OpenZeppelin
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal virtual {
        require(_owner != address(0), "approve from zero");

        emit Approval(_owner, _spender, _amount);

        // solhint-disable-next-line reason-string
        require(_spender != address(0), "approve to zero");

        allowances_[_owner][_spender] = _amount;
    }

    /// @dev _spendAllowance is implemented by OpenZeppelin
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);

        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "insufficient allowance");

            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /* ~~~~~~~~~~ EXTRA FUNCTIONS ~~~~~~~~~~ */

    function updateOracle(address _newOracle) public {
        require(msg.sender == operator_, "only operator");

        oracle_ = _newOracle;
    }

    /**
     * @notice update the operator account to a new address
     * @param _newOperator the address of the new operator to change to
     */
    function updateOperator(address _newOperator) public {
        require(msg.sender == operator_, "operator only");
        require(_newOperator != address(0), "new operator zero");

        emit NewOperator(operator_, _newOperator);

        operator_ = _newOperator;
    }

    /* ~~~~~~~~~~ IMPLEMENTS IOperatorOwned ~~~~~~~~~~ */

    /// @inheritdoc IOperatorOwned
    function operator() public view returns (address) { return operator_; }

    /* ~~~~~~~~~~ IMPLEMENTS IEmergencyMode ~~~~~~~~~~ */

    /// @inheritdoc IEmergencyMode
    function enableEmergencyMode() public {
        require(
            msg.sender == operator_ ||
            msg.sender == emergencyCouncil_ ||
            msg.sender == oracle_,
            "can't enable emergency mode!"
        );

        noEmergencyMode_ = false;

        emit Emergency(true);
    }

    /// @inheritdoc IEmergencyMode
    function disableEmergencyMode() public {
        require(msg.sender == operator_, "operator only");

        noEmergencyMode_ = true;

        emit Emergency(false);
    }

    function noEmergencyMode() public view returns (bool) {
        return noEmergencyMode_;
    }

    function emergencyCouncil() public view returns (address) {
        return emergencyCouncil_;
    }

    /**
     * @notice updates the emergency council address
     * @notice (operator only)
     * @param newCouncil the new council address
     */
    function updateEmergencyCouncil(address newCouncil) external {
        require(msg.sender == operator_, "operator only");

        emit NewCouncil(emergencyCouncil_, newCouncil);

        emergencyCouncil_ = newCouncil;
    }

    /* ~~~~~~~~~~ IMPLEMENTS IToken ~~~~~~~~~~ */

    /// @inheritdoc IToken
    function oracle() public view returns (address) {
        return oracle_;
    }

    /// @inheritdoc IToken
    function underlyingToken() public view returns (IERC20) {
        return pool_.underlying_();
    }

    /// @inheritdoc IToken
    function underlyingLp() public view returns (ILiquidityProvider) {
        return pool_;
    }

    /// @notice updates the reward quarantine threshold if called by the operator
    function updateRewardQuarantineThreshold(uint _maxUncheckedReward) public {
        require(msg.sender == operator_, "operator only");

        maxUncheckedReward_ = _maxUncheckedReward;

        emit RewardQuarantineThresholdUpdated(_maxUncheckedReward);
    }

    /// @inheritdoc IToken
    function erc20In(uint _amount) public returns (uint) {
        return _erc20In(msg.sender, msg.sender, _amount);
    }

    /// @inheritdoc IToken
    // slither-disable-next-line reentrancy-no-eth
    function erc20InTo(
        address _recipient,
        uint256 _amount
    ) public returns (uint256 amountOut) {
        return _erc20In(msg.sender, _recipient, _amount);
    }

    /// @inheritdoc IToken
    function erc20Out(uint256 _amount) public returns (uint256) {
        return _erc20Out(msg.sender, msg.sender,_amount);
    }

    /// @inheritdoc IToken
    function erc20OutTo(address _recipient, uint256 _amount) public returns (uint256) {
        return _erc20Out(msg.sender, _recipient, _amount);
    }

    /// @inheritdoc IToken
    function burnFluidWithoutWithdrawal(uint256 _amount) public {
        // burns fluid without taking from the liquidity provider
        // this is fine, because the amount in the liquidity provider
        // and the amount of fluid tokens are explicitly allowed to be different
        // using this will essentially add the tokens to the reward pool
        _burn(msg.sender, _amount);
    }

    /// @inheritdoc IToken
    function rewardPoolAmount() public returns (uint) {
        // XXX calling totalPoolAmount before totalSupply is load bearing to the StupidLiquidityProvider
        uint totalAmount = pool_.totalPoolAmount();
        uint totalFluid = totalSupply();
        require(totalAmount >= totalFluid, "bad underlying liq");
        return totalAmount - totalFluid;
    }

    /// @inheritdoc IToken
    function unblockReward(
        bytes32 rewardTx,
        address user,
        uint amount,
        bool payout,
        uint firstBlock,
        uint lastBlock
    ) public {
        require(noEmergencyMode_, "emergency mode!");
        require(msg.sender == operator_, "operator only");

        require(blockedRewards_[user] >= amount, "too much unblock");

        blockedRewards_[user] -= amount;

        if (payout) {
            _reward(user, amount);
            emit UnblockReward(rewardTx, user, amount, firstBlock, lastBlock);
        }
    }

    /// @inheritdoc IToken
    function maxUncheckedReward() public view returns (uint) {
        return maxUncheckedReward_;
    }

    /// @inheritdoc IToken
    function upgradeLiquidityProvider(
        ILiquidityProvider _newPool,
        uint256 _minTokenAfterShift
     ) public returns (uint256) {
      require(noEmergencyMode_, "emergency mode");
      require(msg.sender == operator_, "operator only");

      uint oldPoolAmount = pool_.totalPoolAmount();

      pool_.takeFromPool(oldPoolAmount);

      pool_ = _newPool;

      underlyingToken().safeTransfer(address(pool_), oldPoolAmount);

      pool_.addToPool(oldPoolAmount);

      uint newPoolAmount = pool_.totalPoolAmount();

      require(newPoolAmount > _minTokenAfterShift + 1, "total amount bad");

      return newPoolAmount;
    }

    /// @inheritdoc IToken
    function drainRewardPool(address _recipient, uint256 _amount) public {
        require(noEmergencyMode_, "emergency mode");
        require(msg.sender == operator_, "operator only");

        uint256 rewardPool = rewardPoolAmount();

        require(rewardPool >= _amount, "drain too high");

        _reward(_recipient, _amount);
    }

    /* ~~~~~~~~~~ IMPLEMENTS IFluidClient ~~~~~~~~~~ */

    /// @inheritdoc IFluidClient
    function batchReward(
        Winner[] memory rewards,
        uint firstBlock,
        uint lastBlock
    ) public {
        require(noEmergencyMode_, "emergency mode!");
        require(msg.sender == oracle_, "only oracle");

        uint poolAmount = rewardPoolAmount();

        for (uint i = 0; i < rewards.length; i++) {
            Winner memory winner = rewards[i];

            require(poolAmount >= winner.amount, "empty reward pool");

            poolAmount = poolAmount - winner.amount;

            _rewardFromPool(
                firstBlock,
                lastBlock,
                winner.winner,
                winner.amount
            );
        }
    }

    /// @inheritdoc IFluidClient
    function getUtilityVars() external returns (UtilityVars memory) {
        return UtilityVars({
            poolSizeNative: rewardPoolAmount(),
            tokenDecimalScale: 10**decimals(),
            exchangeRateNum: 1,
            exchangeRateDenom: 1,
            deltaWeightNum: 31536000,
            deltaWeightDenom: 1,
            customCalculationType: DEFAULT_CALCULATION_TYPE
        });
    }

    /* ~~~~~~~~~~ IMPLEMENTS ITransferWithBeneficiary ~~~~~~~~~~ */

    /// @inheritdoc ITransferWithBeneficiary
    function transferWithBeneficiary(
        address _token,
        uint256 _amount,
        address _beneficiary,
        uint64 /* data */
    ) external override returns (bool) {
        bool rc;

        rc = Token(_token).transferFrom(msg.sender, address(this), _amount);

        if (!rc) return false;

        rc = Token(_token).transfer(_beneficiary, _amount);

        return rc;
    }

    /* ~~~~~~~~~~ IMPLEMENTS IERC2612 ~~~~~~~~~~ */

    /// @inheritdoc IERC2612
    function nonces(address _owner) public view returns (uint256) {
        return nonces_[_owner];
    }

    /// @inheritdoc IEIP712
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == initialChainId_
                ? initialDomainSeparator_
                : computeDomainSeparator();
    }

    /// @inheritdoc IERC2612
    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public virtual {
        // solhint-disable-next-line not-rely-on-time
        require(_deadline >= block.timestamp, "permit deadline expired");

        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                EIP721_PERMIT_SELECTOR,
                                _owner,
                                _spender,
                                _value,
                                nonces_[_owner]++,
                                _deadline
                            )
                        )
                    )
                ),
                _v,
                _r,
                _s
            );

            require(recoveredAddress != address(0), "invalid signer");

            require(recoveredAddress == _owner, "invalid signer");

            allowances_[recoveredAddress][_spender] = _value;
        }
    }

    /* ~~~~~~~~~~ IMPLEMENTS IERC20 ~~~~~~~~~~ */

    // remaining functions are taken from OpenZeppelin's ERC20 implementation

    function name() public view returns (string memory) { return name_; }
    function symbol() public view returns (string memory) { return symbol_; }
    function decimals() public view returns (uint8) { return decimals_; }
    function totalSupply() public view returns (uint256) { return totalSupply_; }
    function balanceOf(address account) public view returns (uint256) {
       return balances_[account];
    }

    function transfer(address _to, uint256 _amount) public returns (bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256) {
        return allowances_[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool) {
        _spendAllowance(_from, msg.sender, _amount);
        _transfer(_from, _to, _amount);
        return true;
    }

    // not actually a part of IERC20 but we support it anyway

    function increaseAllowance(
        address _spender,
        uint256 _addedValue
    ) public returns (bool) {
        _approve(
            msg.sender,
            _spender,
            allowances_[msg.sender][_spender] + _addedValue
        );

        return true;
    }

    function decreaseAllowance(
        address _spender,
        uint256 _subtractedValue
    ) public returns (bool) {
        uint256 currentAllowance = allowances_[msg.sender][_spender];

        // solhint-disable-next-line reason-string
        require(
            currentAllowance >= _subtractedValue,
            "ERC20: decreased allowance below zero"
        );

        unchecked {
            _approve(msg.sender, _spender, currentAllowance - _subtractedValue);
        }

        return true;
    }

    /* ~~~~~~~~~~ MISC OPERATOR FUNCTIONS ~~~~~~~~~~ */

    function setFeeDetails(uint256 _mintFee, uint256 _burnFee, address _recipient) public {
        require(msg.sender == operator_, "only operator");

        require(_mintFee < FEE_DENOM, "mint fee too high");
        require(_burnFee < FEE_DENOM, "burn fee too high");

        emit FeeSet(mintFee_, _mintFee, burnFee_, _burnFee);

        feeRecipient_ = _recipient;

        mintFee_ = _mintFee;
        burnFee_ = _burnFee;
    }
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

interface IGMXSwapRouter {
    function swap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address _receiver
    ) external;
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import "../../../interfaces/IRegistry.sol";
import "../../../interfaces/ILiquidityProvider.sol";

import "../../../contracts/AaveV3LiquidityProvider.sol";
import "../../../contracts/Token.sol";

import "./UsdcEToUsdcNShifterLiquidityProvider.sol";

/**
 * ShiftUsdcEToUsdc is intended to be used with call after
 * transferring the ownership of the token given to this
 */
contract ShiftUsdcEToUsdcN {
    struct Args {
        address multisig;
        address aaveV3LiquidityProviderBeacon;
        IRegistry registry;
        Token token;
        uint256 deadline;
    }

    IERC20 constant private usdce_ = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

    IERC20 constant private usdcn_ = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);

    address private authorised_;

    constructor(address _authorised) {
        authorised_ = _authorised;
    }

    function main(Args calldata _args) external {
        require(msg.sender == authorised_, "only authorised");

        // first, deploy the liquidity provider with aave v3 so we can
        // start to shift the liquidity over

        ILiquidityProvider tempLp = new UsdcEToUsdcNShifterLiquidityProvider(
            _args.multisig,
            _args.deadline,
            address(_args.token) // owner
        );

        ILiquidityProvider oldLp = _args.token.underlyingLp();

        uint256 tokenAmount = oldLp.totalPoolAmount();

        require(tokenAmount > 100, "total pool amount too low");

        uint256 minTokenAmount = (tokenAmount * 99) / 100;

        _args.token.upgradeLiquidityProvider(tempLp, minTokenAmount);

        require(tempLp.underlying_() == usdcn_);

        require(tempLp.totalPoolAmount() + 1 > minTokenAmount, "old usdcn amount too low");

        ILiquidityProvider newAaveV3Lp = ILiquidityProvider(address(new BeaconProxy(
            _args.aaveV3LiquidityProviderBeacon,
            abi.encodeWithSelector(
                AaveV3LiquidityProvider.init.selector,
                0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb, // aave address provider
                0x724dc807b04555b71ed48a6896b6F41593b8C637, // aave usdcn atoken
                address(_args.token) // owner
            )
        )));

        _args.token.upgradeLiquidityProvider(newAaveV3Lp, minTokenAmount);

        require(newAaveV3Lp.underlying_() == usdcn_);

        require(newAaveV3Lp.totalPoolAmount() + 1 > minTokenAmount, "new usdcn amount too low");

        // better to be safe than sorry and estimate instead of relying on upstream

        _args.token.updateOperator(_args.multisig);
    }
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "../../openzeppelin/SafeERC20.sol";

import "../../../contracts/Token.sol";

import "../../../interfaces/IERC20.sol";
import "../../../interfaces/ILiquidityProvider.sol";

import "./IGMXSwapRouter.sol";

uint256 constant MAX_UINT256 = type(uint256).max;

/**
 * UsdcEToUsdcNShifterLiquidityProvider takes usdce assets provided with
 * addToPool, uses Uniswap to swap them, then changes the underlying to
 * point to usdc. Intended to be deployed, used and cast aside in one big
 * transaction. Includes a rescue function * JUST IN CASE * something
 * weird happens (this should be set to the gnosis safe).
*/
contract UsdcEToUsdcNShifterLiquidityProvider is ILiquidityProvider {
    using SafeERC20 for IERC20;

    /**
     * @notice rescuer_ that should be used if the contract for some
     *         reason is not able to work properly but executes anyway.
     *         may be used by the caller to transfer ownership after
     */
    address immutable public rescuer_;

    /// @notice deadline_ to enforce that this transaction happens by
    uint256 immutable public deadline_;

    IGMXSwapRouter public swapRouter_ = IGMXSwapRouter(0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064);

    /// @notice owner_ of the liquidityprovider (Token) address
    address immutable public owner_;

    /// @notice usdce_ address to use as the bridged version of USDC
    IERC20 immutable public usdce_ = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

    /// @notice usdcn_ to point to as the version recently deployed by circle
    IERC20 immutable public usdcn_ = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);

    /// @notice hasShifted_ over the asset from usdce to usdc?
    bool private hasShifted_;

    constructor(
        address _rescuer,
        uint256 _deadline,
        address _owner
    ) {
        rescuer_ = _rescuer;
        deadline_ = _deadline;
        owner_ = _owner;
        usdce_.safeApprove(address(swapRouter_), MAX_UINT256);
        usdcn_.safeApprove(address(swapRouter_), MAX_UINT256);
    }

    /// @notice underlying_ quotes a different token depending on whether it
    ///         has transferred usdce to usdc
    function underlying_() public view returns (IERC20) {
        return hasShifted_ ? usdcn_ : usdce_ ;
    }

    function rescue(Token _token) public {
        require(msg.sender == rescuer_, "only rescuer");
        usdce_.safeTransfer(rescuer_, usdce_.balanceOf(address(this)));
        usdcn_.safeTransfer(rescuer_, usdcn_.balanceOf(address(this)));
        _token.updateOperator(rescuer_);
    }

    function addToPool(uint256 _amount) public {
        require(msg.sender == owner_, "only owner");

        address[] memory tokenIn = new address[](2);
        tokenIn[0] =  address(usdce_);
        tokenIn[1] = address(usdcn_);

        swapRouter_.swap(
            tokenIn,
            _amount,
            0,
            address(this)
        );

        hasShifted_ = true;
    }

    function totalPoolAmount() external view returns (uint256) {
        require(hasShifted_, "hasn't shifted");
        return usdcn_.balanceOf(address(this));
    }

    function takeFromPool(uint256 _amount) public {
        require(msg.sender == owner_, "only owner");
        require(hasShifted_, "hasn't shifted");

        usdcn_.safeTransfer(owner_, _amount);
    }
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.16;
pragma abicoder v2;

interface IAToken {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
    function balanceOf(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.16;
pragma abicoder v2;

interface PoolAddressesProviderInterface {
    function getPool() external view returns (address);
}

interface PoolInterface {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external payable;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IEIP712 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

interface IEmergencyMode {
    /// @notice emitted when the contract enters emergency mode!
    event Emergency(bool indexed status);

    /// @notice should be emitted when the emergency council changes
    ///         if this implementation supports that
    event NewCouncil(address indexed oldCouncil, address indexed newCouncil);

    /**
     * @notice enables emergency mode preventing the swapping in of tokens,
     * @notice and setting the rng oracle address to null
     */
    function enableEmergencyMode() external;

    /**
     * @notice disables emergency mode, following presumably a contract upgrade
     * @notice (operator only)
     */
    function disableEmergencyMode() external;

    /**
     * @notice emergency mode status (true if everything is okay)
     */
    function noEmergencyMode() external view returns (bool);

    /**
     * @notice emergencyCouncil address that can trigger emergency functions
     */
    function emergencyCouncil() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.16;

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
     * @dev Returns the number of decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

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

pragma solidity 0.8.16;

import "./IEIP712.sol";

/// @dev EIP721_PERMIT_SELECTOR that's needed for ERC2612
bytes32 constant EIP721_PERMIT_SELECTOR =
  keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

interface IERC2612 is IEIP712 {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint);
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

/// @dev parameter for the batchReward function
struct Winner {
    address winner;
    uint256 amount;
}

/// @dev returned from the getUtilityVars function to calculate distribution amounts
struct UtilityVars {
    uint256 poolSizeNative;
    uint256 tokenDecimalScale;
    uint256 exchangeRateNum;
    uint256 exchangeRateDenom;
    uint256 deltaWeightNum;
    uint256 deltaWeightDenom;
    string customCalculationType;
}

// DEFAULT_CALCULATION_TYPE to use as the value for customCalculationType if
// your utility doesn't have a worker override
string constant DEFAULT_CALCULATION_TYPE = "";

interface IFluidClient {

    /// @notice MUST be emitted when any reward is paid out
    event Reward(
        address indexed winner,
        uint amount,
        uint startBlock,
        uint endBlock
    );

    /**
     * @notice pays out several rewards
     * @notice only usable by the trusted oracle account
     *
     * @param rewards the array of rewards to pay out
     */
    function batchReward(Winner[] memory rewards, uint firstBlock, uint lastBlock) external;

    /**
     * @notice gets stats on the token being distributed
     * @return the variables for the trf
     */
    function getUtilityVars() external returns (UtilityVars memory);
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "./IERC20.sol";

/// @title generic interface around an interest source
interface ILiquidityProvider {
    /**
     * @notice getter for the owner of the pool (account that can deposit and remove from it)
     * @return address of the owning account
     */
    function owner_() external view returns (address);
    /**
     * @notice gets the underlying token (ie, USDt)
     * @return address of the underlying token
     */
    function underlying_() external view returns (IERC20);

    /**
     * @notice adds `amount` of tokens to the pool from the amount in the LiquidityProvider
     * @notice requires that the user approve them first
     * @param amount number of tokens to add, in the units of the underlying token
     */
    function addToPool(uint amount) external;
    /**
     * @notice removes `amount` of tokens from the pool
     * @notice sends the tokens to the owner
     * @param amount number of tokens to remove, in the units of the underlying token
     */
    function takeFromPool(uint amount) external;
    /**
     * @notice returns the total amount in the pool, counting the invested amount and the interest earned
     * @return the amount of tokens in the pool, in the units of the underlying token
     */
    function totalPoolAmount() external returns (uint);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.16;
pragma abicoder v2;

interface IOperatorOwned {
    event NewOperator(address old, address new_);

    function operator() external view returns (address);
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "./IFluidClient.sol";
import "./ITrfVariables.sol";
import "./ITokenOperatorOwned.sol";

interface IRegistry {
    function registerToken(ITokenOperatorOwned) external;
    function registerManyTokens(ITokenOperatorOwned[] calldata) external;

    function registerLiquidityProvider(ILiquidityProvider) external;
    function registerManyLiquidityProviders(ILiquidityProvider[] calldata) external;

    function tokens() external view returns (ITokenOperatorOwned[] memory);

    function getFluidityClient(
        address,
        string memory
    ) external view returns (IFluidClient);

    function updateTrfVariables(address, TrfVariables calldata) external;

    function getTrfVariables(address) external returns (TrfVariables memory);
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "./IFluidClient.sol";
import "./ILiquidityProvider.sol";

import "./IERC20.sol";

interface IToken is IERC20 {
    /// @notice emitted when a reward is quarantined for being too large
    event BlockedReward(
        address indexed winner,
        uint256 amount,
        uint256 startBlock,
        uint256 endBlock
    );

    /// @notice emitted when a blocked reward is released
    event UnblockReward(
        bytes32 indexed originalRewardTx,
        address indexed winner,
        uint256 amount,
        uint256 startBlock,
        uint256 endBlock
    );

    /// @notice emitted when an underlying token is wrapped into a fluid asset
    event MintFluid(address indexed addr, uint256 amount);

    /// @notice emitted when a fluid token is unwrapped to its underlying asset
    event BurnFluid(address indexed addr, uint256 amount);

    /// @notice emitted when restrictions
    event MaxUncheckedRewardLimitChanged(uint256 amount);

    /// @notice updating the reward quarantine before manual signoff
    /// @notice by the multisig (with updateRewardQuarantineThreshold)
    event RewardQuarantineThresholdUpdated(uint256 amount);

    /// @notice emitted when a user is permitted to mint on behalf of another user
    event MintApproval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /// @notice emitted when an operator sets the burn fee (1%)
    event FeeSet(
        uint256 _originalMintFee,
        uint256 _newMintFee,
        uint256 _originalBurnFee,
        uint256 _newBurnFee
    );

    /// @notice emitted when an operator changes the underlying over to a new token
    event NewUnderlyingAsset(IERC20 _old, IERC20 _new);

    /**
     * @notice getter for the RNG oracle provided by `workerConfig_`
     * @return the address of the trusted oracle
     *
     * @dev individual oracles are now recorded in the operator, this
     *      now should return the registry contract
     */
    function oracle() external view returns (address);

    /**
     * @notice underlyingToken that this IToken wraps
     */
    function underlyingToken() external view returns (IERC20);

    /**
     * @notice underlyingLp that's in use for the liquidity provider
     */
    function underlyingLp() external view returns (ILiquidityProvider);

    /// @notice updates the reward quarantine threshold if called by the operator
    function updateRewardQuarantineThreshold(uint256) external;

    /**
     * @notice wraps `amount` of underlying tokens into fluid tokens
     * @notice requires you to have called the ERC20 `approve` method
     * @notice targeting this contract first on the underlying asset
     *
     * @param _amount the number of tokens to wrap
     * @return the number of tokens wrapped
     */
    function erc20In(uint256 _amount) external returns (uint256);

    /**
     * @notice erc20InTo wraps the `amount` given and transfers the tokens to `receiver`
     *
     * @param _recipient of the wrapped assets
     * @param _amount to wrap and send to the recipient
     */
    function erc20InTo(address _recipient, uint256 _amount) external returns (uint256);

    /**
     * @notice unwraps `amount` of fluid tokens back to underlying
     *
     * @param _amount the number of fluid tokens to unwrap
     * @return amountReturned to the sender in the underlying
     */
    function erc20Out(uint256 _amount) external returns (uint256 amountReturned);

   /**
     * @notice unwraps `amount` of fluid tokens with the address as recipient
     *
     * @param _recipient to receive the underlying tokens to
     * @param _amount the number of fluid tokens to unwrap
     * @return amountReturned to the user of the underlying
     */
    function erc20OutTo(address _recipient, uint256 _amount) external returns (
        uint256 amountReturned
    );

   /**
     * @notice burns `amount` of fluid /without/ withdrawing the underlying
     *
     * @param _amount the number of fluid tokens to burn
     */
    function burnFluidWithoutWithdrawal(uint256 _amount) external;

    /**
     * @notice calculates the size of the reward pool (the interest we've earned)
     *
     * @return the number of tokens in the reward pool
     */
    function rewardPoolAmount() external returns (uint256);

    /**
     * @notice admin function, unblocks a reward that was quarantined for being too large
     * @notice allows for paying out or removing the reward, in case of abuse
     *
     * @param _user the address of the user who's reward was quarantined
     *
     * @param _amount the amount of tokens to release (in case
     *        multiple rewards were quarantined)
     *
     * @param _payout should the reward be paid out or removed?
     *
     * @param _firstBlock the first block the rewards include (should
     *        be from the BlockedReward event)
     *
     * @param _lastBlock the last block the rewards include
     */
    function unblockReward(
        bytes32 _rewardTx,
        address _user,
        uint256 _amount,
        bool _payout,
        uint256 _firstBlock,
        uint256 _lastBlock
    )
        external;

    /**
     * @notice return the max unchecked reward that's currently set
     */
    function maxUncheckedReward() external view returns (uint256);

    /**
     * @notice upgrade the underlying ILiquidityProvider to a new source
     * @param _newPool to shift the liquidity into
     * @param _minTokenAfterShift to enforce for the tokens quoted after shifting the assets over
     *
     * @return newPoolAmount returned from the underlying pool when asked with totalPoolAmount
     */
    function upgradeLiquidityProvider(
        ILiquidityProvider _newPool,
        uint256 _minTokenAfterShift
    ) external returns (uint256 newPoolAmount);

    /**
     * @notice drain the reward pool of the amount given without
     *         touching any principal amounts
     *
     * @dev this is intended to only be used to retrieve initial
     *       liquidity provided by the team OR by the DAO to allocate funds
     */
    function drainRewardPool(address _recipient, uint256 _amount) external;

    /**
     * @notice setFeeDetails for any fees that may be taken on mint or burn
     * @param _mintFee numerated so that 10 is 1% taken on minting
     * @param _burnFee numerated so that 30 is 3% taken on burning
     * @param _recipient to send fees earned to using a minting interaction
     *
     * @dev the purpose of the mint fee primarily is to facilitate the
     *      circular liquidity provider (StupidLiquidityProvider) on
     *      self-contained chains
     */
    function setFeeDetails(uint256 _mintFee, uint256 _burnFee, address _recipient) external;
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.16;
pragma abicoder v2;

import "./IToken.sol";
import "./IOperatorOwned.sol";

interface ITokenOperatorOwned is IToken, IOperatorOwned {
    // solhint-disable-empty-line
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Interface for transferWithBeneficiary
interface ITransferWithBeneficiary {
    /**
     * @notice Make a token transfer that the *signer* is paying tokens but
     * benefits are given to the *beneficiary*
     * @param _token The contract address of the transferring token
     * @param _amount The amount of the transfer
     * @param _beneficiary The address that will receive benefits of this transfer
     * @param _data Extra data passed to the contract
     * @return Returns true for a successful transfer.
     */
    function transferWithBeneficiary(
        address _token,
        uint256 _amount,
        address _beneficiary,
        uint64 _data
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

/// @dev TrfVariables that the worker uses in it's configuration
///      (previously in the database)
struct TrfVariables {
    uint256 currentAtxTransactionMargin;
    uint256 defaultTransfersInBlock;
    uint256 spoolerInstantRewardThreshold;
    uint256 spoolerBatchedRewardThreshold;

    uint8 defaultSecondsSinceLastBlock;
    uint8 atxBufferSize;
}