/**
 *Submitted for verification at Arbiscan on 2023-05-04
*/

// SPDX-License-Identifier: MIT

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


/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
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



/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
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


abstract contract Adminable {
    address public admin;
    address public candidate;

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event AdminCandidateRegistered(address indexed admin, address indexed candidate);

    constructor(address _admin) {
        require(_admin != address(0), "admin is the zero address");
        admin = _admin;
        emit AdminChanged(address(0), _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return account == admin;
    }

    function registerAdminCandidate(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "new admin is the zero address");
        candidate = _newAdmin;
        emit AdminCandidateRegistered(admin, _newAdmin);
    }

    function confirmAdmin() external {
        require(msg.sender == candidate, "only candidate");
        emit AdminChanged(admin, candidate);
        admin = candidate;
        candidate = address(0);
    }
}



abstract contract OperatorAdminable is Adminable {
    mapping(address => bool) private _operators;

    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);

    modifier onlyAdminOrOperator() {
        require(isAdmin(msg.sender) || isOperator(msg.sender), "OperatorAdminable: caller is not admin or operator");
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return _operators[account];
    }

    function addOperator(address account) external onlyAdmin {
        require(account != address(0), "OperatorAdminable: operator is the zero address");
        require(!_operators[account], "OperatorAdminable: operator already added");
        _operators[account] = true;
        emit OperatorAdded(account);
    }

    function removeOperator(address account) external onlyAdmin {
        require(_operators[account], "OperatorAdminable: operator not found");
        _operators[account] = false;
        emit OperatorRemoved(account);
    }
}


abstract contract Pausable is OperatorAdminable {
    bool public paused;

    event Paused();
    event Resumed();

    constructor(address _admin) Adminable(_admin) {}

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    function pause() external onlyAdmin {
        paused = true;
        emit Paused();
    }

    function resume() external onlyAdmin {
        paused = false;
        emit Resumed();
    }
}


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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}


contract ConfigUser {
    address public immutable config;

    constructor(address _config) {
        require(_config != address(0), "ConfigUser: config is the zero address");
        config = _config;
    }
}


interface IConfig {
    function MIN_DELAY_TIME() external pure returns (uint256);
    function upgradeDelayTime() external view returns (uint256);
    function setUpgradeDelayTime(uint256 time) external;
    function getUpgradeableAt() external view returns (uint256);
}


interface IRewardRouter {
    function gmx() external view returns (address);
    function esGmx() external view returns (address);
    function glp() external view returns (address);
    function weth() external view returns (address);
    function bnGmx() external view returns (address);

    function stakedGmxTracker() external view returns (address);
    function bonusGmxTracker() external view returns (address);
    function feeGmxTracker() external view returns (address);
    function stakedGlpTracker() external view returns (address);
    function feeGlpTracker() external view returns (address);
    function gmxVester() external view returns (address);
    function glpVester() external view returns (address);

    function stakeEsGmx(uint256 _amount) external;
    
    function signalTransfer(address _receiver) external;
    function acceptTransfer(address _sender) external;

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);
    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    function unstakeAndRedeemGlpETH(uint256 _glpAmount, uint256 _minOut, address payable _receiver) external returns (uint256);

    function claim() external;
    function pendingReceivers(address _account) external view returns (address);
}


interface IConverter {
    function gmx() external view returns (address);
    function esGmx() external view returns (address);
    function bnGmx() external view returns (address);
    function rewardRouter() external view returns (IRewardRouter);
    function stakedGmxTracker() external view returns (address);
    function feeGmxTracker() external view returns (address);
    function stakedGlp() external view returns (address);
    function GMXkey() external view returns (address);
    function esGMXkey() external view returns (address);
    function MPkey() external view returns (address);
    function rewards() external view returns (address);
    function treasury() external view returns (address);
    function operator() external view returns (address);
    function transferReceiver() external view returns (address);
    function feeCalculator() external view returns (address);
    function receivers(address _account) external view returns (address);
    function minGmxAmount() external view returns (uint128);
    function qualifiedRatio() external view returns (uint32);
    function isForMpKey(address sender) external view returns (bool);
    function registeredReceivers(uint256 index) external view returns (address);
    function registeredReceiversLength() external view returns (uint256);
    function isValidReceiver(address _receiver) external view returns (bool);
    function convertedAmount(address accountn, address token) external view returns (uint256);
    function feeCalculatorReserved() external view returns (address, uint256);
    function setQualification(uint128 _minGmxAmount, uint32 _qualifiedRatio) external;
    function createTransferReceiver() external;
    function approveMpKeyConversion(address _receiver, bool _approved) external;
    function completeConversion() external;
    function completeConversionToMpKey(address sender) external;
    event ReceiverRegistered(address indexed receiver, uint256 activeAt);
    event ReceiverCreated(address indexed account, address indexed receiver);
    event ConvertCompleted(address indexed account, address indexed receiver, uint256 gmxAmount, uint256 esGmxAmount, uint256 mpAmount);
    event ConvertForMpCompleted(address indexed account, address indexed receiver, uint256 amount);
    event ConvertingFeeCalculatorReserved(address to, uint256 at);

}


interface IConvertingFeeCalculator {
    function calculateConvertingFee(
        address account,
        uint256 amount,
        address token
    ) external view returns (uint256);
}


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool); //
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); //
    function balanceOf(address account) external view returns (uint256); //
    function mint(address account, uint256 amount) external returns (bool); //
    function approve(address spender, uint256 amount) external returns (bool); //
    function allowance(address owner, address spender) external view returns (uint256); //
}



interface IRewardTracker {
    function unstake(address _depositToken, uint256 _amount) external;
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function stakedAmounts(address account) external view returns (uint256);
    function depositBalances(address account, address depositToken) external view returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function glp() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
}


interface IReserved {

    struct Reserved {
        address to;
        uint256 at;
    }

}


interface ITransferReceiver is IReserved {
    function initialize(
        address _admin,
        address _config,
        address _converter,
        IRewardRouter _rewardRouter,
        address _stakedGlp,
        address _rewards
    ) external;
    function rewardRouter() external view returns (IRewardRouter);
    function stakedGlpTracker() external view returns (address);
    function weth() external view returns (address);
    function esGmx() external view returns (address);
    function stakedGlp() external view returns (address);
    function converter() external view returns (address);
    function rewards() external view returns (address);
    function transferSender() external view returns (address);
    function transferSenderReserved() external view returns (address to, uint256 at);
    function newTransferReceiverReserved() external view returns (address to, uint256 at);
    function accepted() external view returns (bool);
    function isForMpKey() external view returns (bool);
    function reserveTransferSender(address _transferSender, uint256 _at) external;
    function setTransferSender() external;
    function reserveNewTransferReceiver(address _newTransferReceiver, uint256 _at) external;
    function claimAndUpdateReward(address feeTo) external;
    function signalTransfer(address to) external;
    function acceptTransfer(address sender, bool _isForMpKey) external;
    function version() external view returns (uint256);
    event TransferAccepted(address indexed sender);
    event SignalTransfer(address indexed from, address indexed to);
    event TokenWithdrawn(address token, address to, uint256 balance);
    event TransferSenderReserved(address transferSender, uint256 at);
    event NewTransferReceiverReserved(address indexed to, uint256 at);
}


/**
 * @title Converter
 * @author Key Finance
 * @notice 
 * 
 * The main purpose of this contract is to liquidate GMX, esGMX, and the corresponding Multiplier Points (hereinafter referred to as MP) that are staked in the GMX protocol. 
 * This is also called as 'Convert', and when it is completed, GMX tokens (GMX, esGMX) are converted to GMXkey, and MP is converted to MPkey.
 * 
 * The method of liquidating GMX, esGMX, and MP using this contract is as follows:
 * 
 * Prerequisite: There should be no tokens deposited in both the GMX vesting vault and GLP vesting vault on the GMX protocol.
 * 
 * 1. From the account that wants to liquidate GMX, esGMX, and MP, call createTransferReceiver() to deploy an ITransferReceiver(receiver) contract that can receive GMX, esGMX, and MP.
 * 2. From the account that wants to liquidate GMX, esGMX, and MP, call the signalTransfer(receiver) function in the GMX RewardRouter contract.
 * 3. From the account that wants to liquidate GMX, esGMX, and MP, call the completeConversion function to liquidate GMX, esGMX, and MP. 
 *    At this time, the acceptTransfer(sender) function of the RewardRouter is called. Consequently, the received tokens, GMX and esGMX, are liquidated to GMXkey, and MP is liquidated to MPkey.
 * 
 * This contract contains the necessary functions for the above process.
 * Additionally, it provides an admin function for creating MPkey from GMX/esGMX, which is necessary for setting up the DEX pool initially.
 */
contract Converter is IConverter, IReserved, ConfigUser, ReentrancyGuard, Pausable {

    // constants
    uint16 public constant TEN_THOUSANDS = 10000;

    // external contracts
    address public immutable gmx;
    address public immutable esGmx;
    address public immutable bnGmx;
    IRewardRouter public immutable rewardRouter;
    address public immutable stakedGmxTracker;
    address public immutable feeGmxTracker;
    address public immutable stakedGlp;

    // key protocol contracts & addresses
    address public immutable GMXkey;
    address public immutable esGMXkey;
    address public immutable MPkey;
    address public immutable rewards;
    address public treasury;
    address public operator;
    address public transferReceiver;
    address public feeCalculator;

    // state variables
    mapping(address => address) public receivers;
    uint128 public minGmxAmount;
    uint32 public qualifiedRatio; // 0.01% = 1 & can be over 100%
    mapping(address => bool) public isForMpKey;
    address[] public registeredReceivers;
    mapping(address => bool) public isValidReceiver;
    mapping(address => mapping(address => uint256)) public convertedAmount;
    Reserved public feeCalculatorReserved;

    constructor(
        address _admin,
        address _config,
        address _GMXkey,
        address _esGMXkey,
        address _MPkey,
        IRewardRouter _rewardRouter,
        address _stakedGlp,
        address _rewards,
        address _treasury,
        address _transferReceiver,
        address _feeCalculator
    ) Pausable(_admin) ConfigUser(_config) {
        require(_GMXkey != address(0), "Converter: GMXkey is the zero address");
        require(_esGMXkey != address(0), "Converter: esGMXkey is the zero address");
        require(_MPkey != address(0), "Converter: MPkey is the zero address");
        require(address(_rewardRouter) != address(0), "Converter: rewardRouter is the zero address");
        require(_stakedGlp != address(0), "Converter: stakedGlp is the zero address");
        require(_rewards != address(0), "Converter: rewards is the zero address");
        require(_treasury != address(0), "Converter: treasury is the zero address");
        require(_transferReceiver != address(0), "Converter: transferReceiver is the zero address");
        require(_feeCalculator != address(0), "Converter: feeCalculator is the zero address");
        GMXkey = _GMXkey;
        esGMXkey = _esGMXkey;
        MPkey = _MPkey;
        gmx = _rewardRouter.gmx();
        esGmx = _rewardRouter.esGmx();
        bnGmx = _rewardRouter.bnGmx();
        require(esGmx != address(0), "Converter: esGmx is the zero address");
        rewardRouter = _rewardRouter;
        stakedGmxTracker = _rewardRouter.stakedGmxTracker();
        require(stakedGmxTracker != address(0), "Converter: stakedGmxTracker is the zero address");
        feeGmxTracker = _rewardRouter.feeGmxTracker();
        require(feeGmxTracker != address(0), "Converter: feeGmxTracker is the zero address");
        stakedGlp = _stakedGlp;
        rewards = _rewards;
        treasury = _treasury;
        transferReceiver = _transferReceiver;
        feeCalculator = _feeCalculator;
        operator = _admin;
    }

    // - config functions - //

    // Sets treasury address
    function setTreasury(address _treasury) external onlyAdmin {
        require(_treasury != address(0), "Converter: treasury is the zero address");
        treasury = _treasury;
    }

    // Sets operator address
    function setOperator(address _operator) external onlyAdmin {
        require(_operator != address(0), "Converter: operator is the zero address");
        operator = _operator;
    }

    // Sets transferReceiver address
    function setTransferReceiver(address _transferReceiver) external onlyAdmin {
        require(_transferReceiver != address(0), "Converter: transferReceiver is the zero address");
        transferReceiver = _transferReceiver;
    }

    /**
     * @notice Reserves to set feeCalculator contract.
     * @param _feeCalculator contract address
     * @param _at _feeCalculator can be set after this time
     *
     */
    function reserveFeeCalculator(address _feeCalculator, uint256 _at) external onlyAdmin {
        require(_feeCalculator != address(0), "Converter: feeCalculator is the zero address");
        require(_at >= IConfig(config).getUpgradeableAt(), "Converter: at should be later");
        feeCalculatorReserved = Reserved(_feeCalculator, _at);
        emit ConvertingFeeCalculatorReserved(_feeCalculator, _at);
    }

    // Sets reserved FeeCalculator contract.
    function setFeeCalculator() external onlyAdmin {
        require(feeCalculatorReserved.at != 0 && feeCalculatorReserved.at <= block.timestamp, "Converter: feeCalculator is not yet available");
        feeCalculator = feeCalculatorReserved.to;
    }

    /**
     * @notice Sets whether an account attempting to Convert can do so when the ratio of MP (Multiplier Points) to the staked GMX+esGMX amount in the GMX protocol is above a certain level.
     * If there are esGMX already staked in the vesting vault, they are included when comparing with this threshold value.
     * @param _minGmxAmount An account must have staked at least this argument's worth of GMX+esGMX in order to Convert.
     * @param _qualifiedRatio As a result, the account can Convert only if the ratio of MP to the staked GMX+esGMX amount is greater than or equal to the value received by this argument. It is set in units of 0.01%. 10,000 = 100%
     */
    function setQualification(uint128 _minGmxAmount, uint32 _qualifiedRatio) external onlyAdmin {
        minGmxAmount = _minGmxAmount;
        qualifiedRatio = _qualifiedRatio;
    }

    // - external state-changing functions - //

    /**
     * @notice From the account that wants to liquidate GMX, esGMX, and MP, this function deploys an ITransferReceiver(receiver) contract that can receive GMX, esGMX, and MP.
     * An account that has already called this function once cannot deploy it again through this function. 
     * If you want to Convert tokens held in an account that has already gone through the process once, you can create another account, 
     * transfer the tokens there first, and then call this function to proceed with the Convert.
     */
    function createTransferReceiver() external nonReentrant whenNotPaused {
        require(receivers[msg.sender] == address(0), "Converter: receiver already created");

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(transferReceiver),
            abi.encodeWithSelector(ITransferReceiver(transferReceiver).initialize.selector,
                operator,
                config,
                address(this),
                rewardRouter,
                stakedGlp,
                rewards
            )
        );

        receivers[msg.sender] = address(proxy);
        emit ReceiverCreated(msg.sender, address(proxy));
    }

    /**
     * @notice Approves the admin to use the msg.sender's staked tokens, which are to be converted as MPkey only
     * @param _receiver address of the receiver contract
     * @param approved boolean value to approve or disapprove
     */
    function approveMpKeyConversion(address _receiver, bool approved) external onlyAdmin {
        isForMpKey[_receiver] = approved;
    }

    /**
     * @notice Liquidates the received GMX, esGMX, and MP into GMXkey, esGMXkey and MPkey, respectively, by calling the acceptTransfer function of the RewardRouter thru TransferReceiver.
     * At this time, fee is collected at the specified rate and sent to the treasury.
     */
    function completeConversion() external nonReentrant whenNotPaused {
        // At the time of calling this function, the sender's vesting tokens must be zero; 
        // otherwise, the rewardRouter.acceptTransfer function call will fail.

        require(!isForMpKey[msg.sender], "Converter: approved to mint MPkey");

        // Make the receiver contract call the RewardRouter.acceptTransfer function and handle the side-effects related to esGMX/GLP.
        address _receiver = receivers[msg.sender];
        require(_receiver != address(0), "Converter: receiver is not created yet");
        
        _addToRegisteredReceivers(_receiver);
        
        ITransferReceiver(_receiver).acceptTransfer(msg.sender, false);

        // Mint GMXkey and MPkey in amounts corresponding to the received GMX & esGMX and MP, respectively.
        uint256 gmxAmountReceived = IRewardTracker(stakedGmxTracker).depositBalances(_receiver, gmx);
        uint256 esGmxAmountReceived = IRewardTracker(stakedGmxTracker).depositBalances(_receiver, esGmx);
        uint256 mpAmountReceived = IRewardTracker(feeGmxTracker).depositBalances(_receiver, bnGmx);

        require(gmxAmountReceived + esGmxAmountReceived >= minGmxAmount, "Converter: not enough GMX staked to convert");

        // Check the ratio of pan-GMX tokens & Multiplier Point is higher than standard
        require(mpAmountReceived * TEN_THOUSANDS / (gmxAmountReceived + esGmxAmountReceived) >= qualifiedRatio,
            "Converter: gmx/mp ratio is not qualified");

        _mintAndTransferFee(msg.sender, GMXkey, gmxAmountReceived);
        _mintAndTransferFee(msg.sender, esGMXkey, esGmxAmountReceived);
        _mintAndTransferFee(msg.sender, MPkey, mpAmountReceived);

        convertedAmount[msg.sender][GMXkey] = gmxAmountReceived;
        convertedAmount[msg.sender][esGMXkey] = esGmxAmountReceived;
        convertedAmount[msg.sender][MPkey] = mpAmountReceived;

        emit ConvertCompleted(msg.sender, _receiver, gmxAmountReceived, esGmxAmountReceived, mpAmountReceived);
    }

    /**
     * @notice This function is designed to mint and provide some MPkey to the DEX pool.
     * It is acceptable to mint MPkey by locking up GMX, as it is inferior to GMXkey, which is minted by locking up GMX.
     * @param sender The account that wants to mint MPkey
     */
    function completeConversionToMpKey(address sender) external nonReentrant onlyAdmin {
        // At the time of calling this function, the sender's vesting tokens must be zero; 
        // otherwise, the rewardRouter.acceptTransfer function call will fail.

        require(isForMpKey[sender], "Converter: not approved to mint MPkey");

        // Make the receiver contract call the RewardRouter.acceptTransfer function and handle the side-effects related to esGMX/GLP.
        address _receiver = receivers[sender];
        require(_receiver != address(0), "Converter: receiver is not created yet");
        
        _addToRegisteredReceivers(_receiver);
        
        ITransferReceiver(_receiver).acceptTransfer(sender, true);

        // Mint MPkey in amounts corresponding to the received GMX, esGMX and MP.
        uint256 amountReceived = IRewardTracker(feeGmxTracker).stakedAmounts(_receiver);
        _mintAndTransferFee(sender, MPkey, amountReceived);


        emit ConvertForMpCompleted(sender, _receiver, amountReceived);
    }

    // - external view functions - //

    function registeredReceiversLength() external view returns (uint256) {
        return registeredReceivers.length;
    }

    // - no external functions called by other key protocol contracts - //

    // - internal functions - //

    /**
     * Mints tokens in the requested amount and charge a fee
     * @param to the account to receive the minted tokens.
     * @param _token the target token for minting and charging fees.
     * @param amountReceived the amount of the target token for minting and charging fees.
     */
    function _mintAndTransferFee(address to, address _token, uint256 amountReceived) internal {
        // Mint _token as much as the amount of the corresponding token received.
        uint256 fee = IConvertingFeeCalculator(feeCalculator).calculateConvertingFee(to, amountReceived, _token);
        IERC20(_token).mint(to, amountReceived - fee);
        // Transfer a portion of it to the treasury.
        IERC20(_token).mint(treasury, fee);
    }

    function _addToRegisteredReceivers(address _receiver) internal {
        registeredReceivers.push(_receiver);
        isValidReceiver[_receiver] = true;
    }
}