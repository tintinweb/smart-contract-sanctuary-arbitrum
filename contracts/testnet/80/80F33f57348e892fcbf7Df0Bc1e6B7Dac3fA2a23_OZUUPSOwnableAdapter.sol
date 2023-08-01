// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title Proxy
/// @notice Proxy is a transparent proxy that passes through the call if the caller is the owner or
///         if the caller is address(0), meaning that the call originated from an off-chain
///         simulation.
contract Proxy {
    /// @notice The storage slot that holds the address of the implementation.
    ///         bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant IMPLEMENTATION_KEY =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @notice The storage slot that holds the address of the owner.
    ///         bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    bytes32 internal constant OWNER_KEY =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /// @notice An event that is emitted each time the implementation is changed. This event is part
    ///         of the EIP-1967 specification.
    /// @param implementation The address of the implementation contract
    event Upgraded(address indexed implementation);

    /// @notice An event that is emitted each time the owner is upgraded. This event is part of the
    ///         EIP-1967 specification.
    /// @param previousAdmin The previous owner of the contract
    /// @param newAdmin      The new owner of the contract
    event AdminChanged(address previousAdmin, address newAdmin);

    /// @notice A modifier that reverts if not called by the owner or by address(0) to allow
    ///         eth_call to interact with this proxy without needing to use low-level storage
    ///         inspection. We assume that nobody is able to trigger calls from address(0) during
    ///         normal EVM execution.
    modifier proxyCallIfNotAdmin() {
        if (msg.sender == _getAdmin() || msg.sender == address(0)) {
            _;
        } else {
            // This WILL halt the call frame on completion.
            _doProxyCall();
        }
    }

    /// @notice Sets the initial admin during contract deployment. Admin address is stored at the
    ///         EIP-1967 admin storage slot so that accidental storage collision with the
    ///         implementation is not possible.
    /// @param _admin Address of the initial contract admin. Admin as the ability to access the
    ///               transparent proxy interface.
    constructor(address _admin) {
        _changeAdmin(_admin);
    }

    // slither-disable-next-line locked-ether
    receive() external payable {
        // Proxy call by default.
        _doProxyCall();
    }

    // slither-disable-next-line locked-ether
    fallback() external payable {
        // Proxy call by default.
        _doProxyCall();
    }

    /// @notice Set the implementation contract address. The code at the given address will execute
    ///         when this contract is called.
    /// @param _implementation Address of the implementation contract.
    function upgradeTo(address _implementation) public virtual proxyCallIfNotAdmin {
        _setImplementation(_implementation);
    }

    /// @notice Set the implementation and call a function in a single transaction. Useful to ensure
    ///         atomic execution of initialization-based upgrades.
    /// @param _implementation Address of the implementation contract.
    /// @param _data           Calldata to delegatecall the new implementation with.
    function upgradeToAndCall(address _implementation, bytes calldata _data)
        public
        payable
        virtual
        proxyCallIfNotAdmin
        returns (bytes memory)
    {
        _setImplementation(_implementation);
        (bool success, bytes memory returndata) = _implementation.delegatecall(_data);
        require(success, "Proxy: delegatecall to new implementation contract failed");
        return returndata;
    }

    /// @notice Changes the owner of the proxy contract. Only callable by the owner.
    /// @param _admin New owner of the proxy contract.
    function changeAdmin(address _admin) public virtual proxyCallIfNotAdmin {
        _changeAdmin(_admin);
    }

    /// @notice Gets the owner of the proxy contract.
    /// @return Owner address.
    function admin() public virtual proxyCallIfNotAdmin returns (address) {
        return _getAdmin();
    }

    //// @notice Queries the implementation address.
    /// @return Implementation address.
    function implementation() public virtual proxyCallIfNotAdmin returns (address) {
        return _getImplementation();
    }

    /// @notice Sets the implementation address.
    /// @param _implementation New implementation address.
    function _setImplementation(address _implementation) internal {
        assembly {
            sstore(IMPLEMENTATION_KEY, _implementation)
        }
        emit Upgraded(_implementation);
    }

    /// @notice Changes the owner of the proxy contract.
    /// @param _admin New owner of the proxy contract.
    function _changeAdmin(address _admin) internal {
        address previous = _getAdmin();
        assembly {
            sstore(OWNER_KEY, _admin)
        }
        emit AdminChanged(previous, _admin);
    }

    /// @notice Performs the proxy call via a delegatecall.
    function _doProxyCall() internal {
        address impl = _getImplementation();
        require(impl != address(0), "Proxy: implementation not initialized");

        assembly {
            // Copy calldata into memory at 0x0....calldatasize.
            calldatacopy(0x0, 0x0, calldatasize())

            // Perform the delegatecall, make sure to pass all available gas.
            let success := delegatecall(gas(), impl, 0x0, calldatasize(), 0x0, 0x0)

            // Copy returndata into memory at 0x0....returndatasize. Note that this *will*
            // overwrite the calldata that we just copied into memory but that doesn't really
            // matter because we'll be returning in a second anyway.
            returndatacopy(0x0, 0x0, returndatasize())

            // Success == 0 means a revert. We'll revert too and pass the data up.
            if iszero(success) {
                revert(0x0, returndatasize())
            }

            // Otherwise we'll just return and pass the data up.
            return(0x0, returndatasize())
        }
    }

    /// @notice Queries the implementation address.
    /// @return Implementation address.
    function _getImplementation() internal view returns (address) {
        address impl;
        assembly {
            impl := sload(IMPLEMENTATION_KEY)
        }
        return impl;
    }

    /// @notice Queries the owner of the proxy contract.
    /// @return Owner address.
    function _getAdmin() internal view returns (address) {
        address owner;
        assembly {
            owner := sload(OWNER_KEY)
        }
        return owner;
    }
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
pragma solidity ^0.8.15;

import { IProxyAdapter } from "../interfaces/IProxyAdapter.sol";
import { OZUUPSUpdater } from "../updaters/OZUUPSUpdater.sol";
import { Proxy } from "@eth-optimism/contracts-bedrock/contracts/universal/Proxy.sol";

/**
 * @title OZUUPSBaseAdapter
 * @notice An abstract proxy adapter for OpenZeppelin UUPS Upgradeable proxies. Child contracts must
           implement their own access control mechanism for the `changeProxyAdmin` function since
           UUPS proxies do not have a standard access control mechanism like Transparent proxies.
 */
abstract contract OZUUPSBaseAdapter is IProxyAdapter {
    /**
     * @notice Address of the ProxyUpdater contract that will be set as the OpenZeppelin UUPS
       proxy's implementation during the deployment.
     */
    address public immutable proxyUpdater;

    /**
     * @param _proxyUpdater Address of the ProxyUpdater contract.
     */
    constructor(address _proxyUpdater) {
        require(_proxyUpdater != address(0), "OZUUPSBaseAdapter: updater cannot be address(0)");
        proxyUpdater = _proxyUpdater;
    }

    /**
     * @inheritdoc IProxyAdapter
     */
    function initiateUpgrade(address payable _proxy) external {
        OZUUPSUpdater(_proxy).upgradeTo(proxyUpdater);
        OZUUPSUpdater(_proxy).initiate();
    }

    /**
     * @inheritdoc IProxyAdapter
     */
    function finalizeUpgrade(address payable _proxy, address _implementation) external {
        OZUUPSUpdater(_proxy).complete(_implementation);
    }

    /**
     * @inheritdoc IProxyAdapter
     */
    function setStorage(
        address payable _proxy,
        bytes32 _key,
        uint8 _offset,
        bytes memory _value
    ) external {
        OZUUPSUpdater(_proxy).setStorage(_key, _offset, _value);
    }

    /**
        Must be overridden in child contracts in order to transfer ownership using the UUPS proxy's
        current acccess control mechanism (e.g. `Ownable.transferOwnership`).
     * @inheritdoc IProxyAdapter
     */
    function changeProxyAdmin(address payable _proxy, address _newAdmin) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { OZUUPSBaseAdapter } from "./OZUUPSBaseAdapter.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IProxyAdapter } from "../interfaces/IProxyAdapter.sol";

/**
 * @title OZUUPSOwnableAdapter
 * @notice Proxy adapter for an OpenZeppelin UUPS proxy that uses OwnableUpgradeable
    for access control.
 */
contract OZUUPSOwnableAdapter is OZUUPSBaseAdapter {
    /**
     * @param _proxyUpdater Address of the ProxyUpdater contract.
     */
    constructor(address _proxyUpdater) OZUUPSBaseAdapter(_proxyUpdater) {}

    /**
     * Transfers ownership of the proxy using the Ownable access control mechanism.
     * @inheritdoc IProxyAdapter
     */
    function changeProxyAdmin(address payable _proxy, address _newAdmin) external override {
        Ownable(_proxy).transferOwnership(_newAdmin);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title IProxyAdapter
 * @notice Interface that must be inherited by each proxy adapter. Proxy adapters allow other
   contracts to delegatecall into proxies of different types (e.g. Transparent, UUPS, etc.) through
   a standard interface.
 */
interface IProxyAdapter {
    /**
     * @notice Initiate a deployment or upgrade of a proxy.
     *
     * @param _proxy Address of the proxy.
     */
    function initiateUpgrade(address payable _proxy) external;

    /**
     * @notice Complete a deployment or upgrade of a proxy.
     *
     * @param _proxy          Address of the proxy.
     * @param _implementation Address of the proxy's final implementation.
     */
    function finalizeUpgrade(address payable _proxy, address _implementation) external;

    /**
     * @notice Sets a proxy's storage slot value at a given storage slot key and offset.
     *
     * @param _proxy  Address of the proxy to modify.
     * @param _key     Storage slot key to modify.
     * @param _offset  Bytes offset of the new storage slot value from the right side of the storage
       slot. An offset of 0 means the new value will start at the right-most byte of the storage
       slot.
     * @param _value New value of the storage slot at the given key and offset. The length of the
                     value is in the range [1, 32] (inclusive).
     */
    function setStorage(
        address payable _proxy,
        bytes32 _key,
        uint8 _offset,
        bytes memory _value
    ) external;

    /**
     * @notice Changes the admin of the proxy. Note that this function is not triggered during a
               deployment. Instead, it's only triggered if transferring ownership of the UUPS proxy
               away from the SphinxManager, which occurs outside of the deployment process.
     *
     * @param _proxy    Address of the proxy.
     * @param _newAdmin Address of the new admin.
     */
    function changeProxyAdmin(address payable _proxy, address _newAdmin) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title IProxyUpdater
 * @notice Interface that must be inherited by each proxy updater. Contracts that
           inherit from this interface are meant to be set as the implementation of a proxy during
           an upgrade, then delegatecalled by the proxy's owner to change the value of a storage
           slot within the proxy.
 */
interface IProxyUpdater {
    /**
     * @notice Sets a proxy's storage slot value at a given storage slot key and offset.
     *
     * @param _key     Storage slot key to modify.
     * @param _offset  Bytes offset of the new storage slot value from the right side of the storage
       slot. An offset of 0 means the new value will start at the right-most byte of the storage
       slot.
     * @param _value New value of the storage slot at the given key and offset. The length of the
                     value is in the range [1, 32] (inclusive).
     */
    function setStorage(bytes32 _key, uint8 _offset, bytes memory _value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ProxyUpdater } from "./ProxyUpdater.sol";

/**
 * @title OZUUPSUdater
 * @notice Proxy updater that works with OpenZeppelin UUPS proxies. This contract uses a special
    storage slot key called the `SPHINX_ADMIN_KEY` which stores the owner address for the
    duration of the upgrade. This is a convenient way to keep track of the admin during the upgrade
    because OpenZeppelin UUPS proxies do not have a standard ownership mechanism. When the upgrade
    is finished, this key is set back to address(0).
 */
contract OZUUPSUpdater is ProxyUpdater {
    /**
     * @notice The storage slot that holds the address of the implementation.
     *         bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
     */
    bytes32 internal constant IMPLEMENTATION_KEY =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @notice The storage slot that holds the address of the Sphinx admin.
     *         bytes32(uint256(keccak256('sphinx.proxy.admin')) - 1)
     */
    bytes32 internal constant SPHINX_ADMIN_KEY =
        0xadf644ee9e2068b2c186f6b9a2f688d3450c4110b8018da281fbbd8aa6c34995;

    /**
     * @notice Address of this contract. This must be an immutable variable so that it remains
       consistent when delegate called from a proxy.
     */
    address internal immutable THIS_ADDRESS = address(this);

    /**
     * @notice An event that is emitted each time the implementation is changed. This event is part
     *         of the EIP-1967 specification.
     *
     * @param implementation The address of the implementation contract
     */
    event Upgraded(address indexed implementation);

    /**
     * @notice A modifier that reverts if not called by the Sphinx admin or by address(0) to
       allow
     *         eth_call to interact with this proxy without needing to use low-level storage
     *         inspection. We assume that nobody is able to trigger calls from address(0) during
     *         normal EVM execution.
     */
    modifier ifSphinxAdmin() {
        require(
            msg.sender == _getSphinxAdmin() || msg.sender == address(0),
            "OZUUPSUpdater: caller is not admin"
        );
        _;
    }

    /**
     * @notice Check that the execution is not being performed through a delegate call. This allows
       a function to be
     * callable on the implementation contract but not through a proxy.
     */
    modifier notDelegated() {
        require(
            address(this) == THIS_ADDRESS,
            "OZUUPSUpdater: must not be called through delegatecall"
        );
        _;
    }

    /**
     * @notice Set the implementation contract address. Only callable by the Sphinx admin.
     *
     * @param _implementation Address of the implementation contract.
     */
    function upgradeTo(address _implementation) external ifSphinxAdmin {
        _setImplementation(_implementation);
    }

    /**
     * @notice Initiates an upgrade by setting the Sphinx admin to the caller's address.
     */
    function initiate() external {
        if (_getSphinxAdmin() != msg.sender) {
            _setSphinxAdmin(msg.sender);
        }
    }

    /**
     * @notice Completes an upgrade by setting the Sphinx admin to address(0) and setting the
       proxy's implementation to a new address. Only callable by the Sphinx admin.
     *
     * @param _implementation Address of the implementation contract.
     */
    function complete(address _implementation) external ifSphinxAdmin {
        _setSphinxAdmin(address(0));
        _setImplementation(_implementation);
    }

    /**
     * @notice Implementation of the ERC1822 `proxiableUUID` function. This returns the storage slot
       used by the implementation. It is used to validate the implementation's compatibility when
       performing an upgrade. Since this function is only meant to be available on an implementation
       contract, it must revert if invoked through a proxy. This is guaranteed by the `notDelegated`
       modifier.

       @return The storage slot of the implementation.
     */
    function proxiableUUID() external view notDelegated returns (bytes32) {
        return IMPLEMENTATION_KEY;
    }

    /**
     * Only callable by the Sphinx admin.
     * @inheritdoc ProxyUpdater
     */
    function setStorage(
        bytes32 _key,
        uint8 _offset,
        bytes memory _value
    ) public override ifSphinxAdmin {
        super.setStorage(_key, _offset, _value);
    }

    /**
     * @notice Sets the implementation address.
     *
     * @param _implementation New implementation address.
     */
    function _setImplementation(address _implementation) internal {
        assembly {
            sstore(IMPLEMENTATION_KEY, _implementation)
        }
        emit Upgraded(_implementation);
    }

    /**
     * @notice Sets the Sphinx admin to a new address.
     *
     * @param _newAdmin New admin address.
     */
    function _setSphinxAdmin(address _newAdmin) internal {
        assembly {
            sstore(SPHINX_ADMIN_KEY, _newAdmin)
        }
    }

    /**
     * @notice Gets the Sphinx admin's address.
     *
     * @return Sphinx admin address.
     */
    function _getSphinxAdmin() internal view returns (address) {
        address sphinxAdmin;
        assembly {
            sphinxAdmin := sload(SPHINX_ADMIN_KEY)
        }
        return sphinxAdmin;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IProxyUpdater } from "../interfaces/IProxyUpdater.sol";

/**
 * @title ProxyUpdater
 * @notice An abstract contract for setting storage slot values within a proxy at a given storage
        slot key and offset.
 */
abstract contract ProxyUpdater is IProxyUpdater {
    /**
     * @notice Sets a proxy's storage slot value at a given storage slot key and offset. Note that
       this will thrown an error if the length of the storage slot value plus the offset (both in
       bytes) is greater than 32.
     *
     *         To illustrate how this function works, consider the following example. Say we call
     *         this function on some storage slot key with the input parameters:
     *         `_offset = 2`
     *         `_value = 0x22222222`
     *
     *         Say the storage slot value prior to calling this function is:
     *         0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
     *
     *         This function works by creating a bit mask at the location of the value, which in
     *         this case is at an `offset` of 2 and is 4 bytes long (extending left from the
     *         offset). The bit mask would be:
     *         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFF
     *
     *         Applying this bit mask to the existing slot value, we get:
     *         0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC00000000CCCC
     *
     *         Then, we offset the new value to the correct location in the storage slot:
     *         0x0000000000000000000000000000000000000000000000000000222222220000
     *
     *         Lastly, add these two values together to get the new storage slot value:
     *         0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC22222222CCCC
     *
     * @param _key     Storage slot key to modify.
     * @param _offset  Bytes offset of the new storage slot value from the right side of the storage
       slot. An offset of 0 means the new value will start at the right-most byte of the storage
       slot.
     * @param _value New value of the storage slot at the given key and offset. The length of the
                     value is in the range [1, 32] bytes (inclusive).
     */
    function setStorage(bytes32 _key, uint8 _offset, bytes memory _value) public virtual {
        require(_value.length <= 32, "ProxyUpdater: value is too large");

        bytes32 valueBytes32 = bytes32(_value);

        // If the length of the new value equals the size of the storage slot, we can just replace
        // the entire slot value.
        if (_value.length == 32) {
            assembly {
                sstore(_key, valueBytes32)
            }
        } else {
            // Load the existing storage slot value.
            bytes32 currVal;
            assembly {
                currVal := sload(_key)
            }

            // Convert lengths from bytes to bits. Makes calculations easier to read.
            uint256 valueLengthBits = _value.length * 8;
            uint256 offsetBits = _offset * 8;

            // Create a bit mask that will set the values of the existing storage slot to 0 at the
            // location of the new value. It's worth noting that the expresion:
            // `(2 ** (valueLengthBits) - 1)` would revert if `valueLengthBits = 256`. However,
            // this will never happen because values of length 32 are set directly in the
            // if-statement above.
            uint256 mask = ~((2 ** (valueLengthBits) - 1) << offsetBits);

            // Apply the bit mask to the existing storage slot value.
            bytes32 maskedCurrVal = bytes32(mask) & currVal;

            // Calculate the offset of the value from the left side of the storage slot.
            // Denominated in bits for consistency.
            uint256 leftOffsetBits = 256 - offsetBits - valueLengthBits;

            // Shift the value right so that it's aligned with the bitmasked location.
            bytes32 rightShiftedValue = (valueBytes32 >> leftOffsetBits);

            // Create the new storage slot value by adding the bit masked slot value to the new
            // value.
            uint256 newVal = uint256(maskedCurrVal) + uint256(rightShiftedValue);

            // Set the new value of the storage slot.
            assembly {
                sstore(_key, newVal)
            }
        }
    }
}