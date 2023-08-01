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
pragma solidity ^0.8.15;

import { IProxyAdapter } from "../interfaces/IProxyAdapter.sol";
import { IProxyUpdater } from "../interfaces/IProxyUpdater.sol";
import { Proxy } from "@eth-optimism/contracts-bedrock/contracts/universal/Proxy.sol";

/**
 * @title DefaultAdapter
 * @notice Adapter for the default EIP-1967 proxy used by Sphinx.
 */
contract DefaultAdapter is IProxyAdapter {
    /**
     * @notice Address of the ProxyUpdater contract that will be set as the proxy's implementation
    during the deployment.
     */
    address public immutable proxyUpdater;

    /**
     * @param _proxyUpdater Address of the ProxyUpdater contract.
     */
    constructor(address _proxyUpdater) {
        require(_proxyUpdater != address(0), "DefaultAdapter: updater cannot be address(0)");
        proxyUpdater = _proxyUpdater;
    }

    /**
     * @inheritdoc IProxyAdapter
     */
    function initiateUpgrade(address payable _proxy) external {
        Proxy(_proxy).upgradeTo(proxyUpdater);
    }

    /**
     * @inheritdoc IProxyAdapter
     */
    function finalizeUpgrade(address payable _proxy, address _implementation) external {
        Proxy(_proxy).upgradeTo(_implementation);
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
        IProxyUpdater(_proxy).setStorage(_key, _offset, _value);
    }

    /**
     * @inheritdoc IProxyAdapter
     */
    function changeProxyAdmin(address payable _proxy, address _newAdmin) external {
        Proxy(_proxy).changeAdmin(_newAdmin);
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