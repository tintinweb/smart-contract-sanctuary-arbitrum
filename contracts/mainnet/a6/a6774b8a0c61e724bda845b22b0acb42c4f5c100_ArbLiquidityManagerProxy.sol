// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Proxy} from "./Proxy.sol";

contract ArbLiquidityManagerProxy is Proxy {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "../ownership/Ownable.sol";

/**
 * @title Proxy
 * @dev Based on Origin Protocol InitializeGovernedUpgradeabilityProxy
 * https://github.com/OriginProtocol/origin-dollar/blob/master/contracts/contracts/proxies/InitializeGovernedUpgradeabilityProxy.sol
 * @author Origin Protocol Inc
 */
contract Proxy is Ownable {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     * @param implementation Address of the new implementation.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Contract initializer with Owner enforcement
     * @param _logic Address of the initial implementation.
     * @param _initOwner Address of the initial Owner.
     * @param _data Data to send as msg.data to the implementation to initialize
     * the proxied contract.
     * It should include the signature and the parameters of the function to be
     * called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     * This parameter is optional, if no data is given the initialization call
     * to proxied contract will be skipped.
     */
    function initialize(address _logic, address _initOwner, bytes calldata _data) public payable onlyOwner {
        require(_implementation() == address(0));
        assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeTo(_logic);
        if (_data.length > 0) {
            (bool success,) = _logic.delegatecall(_data);
            require(success);
        }
        _setOwner(_initOwner);
    }

    /**
     * @return The address of the proxy admin/it's also the owner.
     */
    function admin() external view returns (address) {
        return _owner();
    }

    /**
     * @return The address of the implementation.
     */
    function implementation() external view returns (address) {
        return _implementation();
    }

    /**
     * @dev Upgrade the backing implementation of the proxy.
     * Only the admin can call this function.
     * @param newImplementation Address of the new implementation.
     */
    function upgradeTo(address newImplementation) external onlyOwner {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the backing implementation of the proxy and call a function
     * on the new implementation.
     * This is useful to initialize the proxied contract.
     * @param newImplementation Address of the new implementation.
     * @param data Data to send as msg.data in the low level call.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable onlyOwner {
        _upgradeTo(newImplementation);
        (bool success,) = newImplementation.delegatecall(data);
        require(success);
    }

    /**
     * @dev Fallback function.
     * Implemented entirely in `_fallback`.
     */
    fallback() external payable {
        _delegate(_implementation());
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * This is a low level function that doesn't return to its internal call site.
     * It will return to the external caller whatever the implementation returns.
     * @param _impl Address to delegate.
     */
    function _delegate(address _impl) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev Returns the current implementation.
     * @return impl Address of the current implementation
     */
    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     * @param newImplementation Address of the new implementation.
     */
    function _upgradeTo(address newImplementation) internal {
        require(newImplementation.code.length > 0, "Cannot set a proxy implementation to a non-contract address");
        bytes32 slot = IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
        emit Upgraded(newImplementation);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract Ownable {
    // keccak256(“eip1967.proxy.admin”) - per EIP 1967
    bytes32 internal constant OWNER_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    event AdminChanged(address previousAdmin, address newAdmin);

    constructor() {
        assert(OWNER_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setOwner(msg.sender);
    }

    function owner() external view returns (address) {
        return _owner();
    }

    function setOwner(address newOwner) external onlyOwner {
        _setOwner(newOwner);
    }

    function _owner() internal view returns (address ownerOut) {
        bytes32 position = OWNER_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ownerOut := sload(position)
        }
    }

    function _setOwner(address newOwner) internal {
        emit AdminChanged(_owner(), newOwner);
        bytes32 position = OWNER_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(position, newOwner)
        }
    }

    function _onlyOwner() internal view {
        require(msg.sender == _owner(), "OSwap: Only owner can call this function.");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
}