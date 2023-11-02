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
pragma solidity ^0.8.0; // optimization enabled, 1000 runs, evm: petersburg

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Immutable Create2 Contract Factory
 * @author 0age
 * @notice This contract provides a safeCreate2 function that takes a salt value
 * and a block of initialization code as arguments and passes them into inline
 * assembly. The contract prevents redeploys by maintaining a mapping of all
 * contracts that have already been deployed. There is also a view function that
 * computes the address of the contract that will be created when submitting a
 * given salt or nonce along with a given block of initialization code.
 * @dev This contract has not yet been fully tested or audited - proceed with
 * caution and please share any exploits or optimizations you discover.
 */
contract Create2Factory {
    event ContractDeployed(address indexed deploymentAddress);
    // mapping to track which addresses have already been deployed.
    mapping(address => bool) public _deployed;

    /**
     * @dev Create a contract using CREATE2 by submitting a given salt or nonce
   * along with the initialization code for the contract. Note that the first 20
   * bytes of the salt must match those of the calling address, which prevents
   * contract creation events from being submitted by unintended parties.
   * @param salt bytes32 The nonce that will be passed into the CREATE2 call.
   * @param initializationCode bytes The initialization code that will be passed
   * into the CREATE2 call.
   * @return deploymentAddress address of the contract that will be created, or the null address
   * if a contract already exists at that address.
   */
    function safeCreate2(
        bytes32 salt,
        bytes calldata initializationCode
    ) external payable returns (address deploymentAddress) {
        // move the initialization code from calldata to memory.
        bytes memory initCode = initializationCode;

        // determine the target address for contract deployment.
        address targetDeploymentAddress = address(
            uint160(                    // downcast to match the address type.
                uint256(                  // convert to uint to truncate upper digits.
                    keccak256(              // compute the CREATE2 hash using 4 inputs.
                        abi.encodePacked(     // pack all inputs to the hash together.
                            hex"ff",            // start with 0xff to distinguish from RLP.
                            address(this),      // this contract will be the caller.
                            salt,               // pass in the supplied salt value.
                            keccak256(          // pass in the hash of initialization code.
                                abi.encodePacked(
                                    initCode
                                )
                            )
                        )
                    )
                )
            )
        );

        // ensure that a contract hasn't been previously deployed to target address.
        require(
            !_deployed[targetDeploymentAddress],
            "Invalid contract creation - contract has already been deployed."
        );

        // using inline assembly: load data and length of data, then call CREATE2.
        assembly {                                // solhint-disable-line
            let encoded_data := add(0x20, initCode) // load initialization code.
            let encoded_size := mload(initCode)     // load the init code's length.
            deploymentAddress := create2(           // call CREATE2 with 4 arguments.
                callvalue(),                            // forward any attached value.
                encoded_data,                         // pass in initialization code.
                encoded_size,                         // pass in init code's length.
                salt                                  // pass in the salt value.
            )
        }

        // check address against target to ensure that deployment was successful.
        require(
            deploymentAddress == targetDeploymentAddress,
            "Failed to deploy contract using provided salt and initialization code."
        );

        // record the deployment of the contract to prevent redeploys.
        _deployed[deploymentAddress] = true;
        emit ContractDeployed(deploymentAddress);
    }

    /**
     * @dev Compute the address of the contract that will be created when
   * submitting a given salt or nonce to the contract along with the contract's
   * initialization code. The CREATE2 address is computed in accordance with
   * EIP-1014, and adheres to the formula therein of
   * `keccak256( 0xff ++ address ++ salt ++ keccak256(init_code)))[12:]` when
   * performing the computation. The computed address is then checked for any
   * existing contract code - if so, the null address will be returned instead.
   * @param salt bytes32 The nonce passed into the CREATE2 address calculation.
   * @param initCode bytes The contract initialization code to be used.
   * that will be passed into the CREATE2 address calculation.
   * @return deploymentAddress address The contract that will be created, or the null address
   * if a contract has already been deployed to that address.
   */
    function findCreate2Address(
        bytes32 salt,
        bytes calldata initCode
    ) external view returns (address deploymentAddress) {
        // determine the address where the contract will be deployed.
        deploymentAddress = address(
            uint160(                      // downcast to match the address type.
                uint256(                    // convert to uint to truncate upper digits.
                    keccak256(                // compute the CREATE2 hash using 4 inputs.
                        abi.encodePacked(       // pack all inputs to the hash together.
                            hex"ff",              // start with 0xff to distinguish from RLP.
                            address(this),        // this contract will be the caller.
                            salt,                 // pass in the supplied salt value.
                            keccak256(            // pass in the hash of initialization code.
                                abi.encodePacked(
                                    initCode
                                )
                            )
                        )
                    )
                )
            )
        );

        // return null address to signify failure if contract has been deployed.
        if (_deployed[deploymentAddress]) {
            return address(0);
        }
    }

    /**
     * @dev Compute the address of the contract that will be created when
   * submitting a given salt or nonce to the contract along with the keccak256
   * hash of the contract's initialization code. The CREATE2 address is computed
   * in accordance with EIP-1014, and adheres to the formula therein of
   * `keccak256( 0xff ++ address ++ salt ++ keccak256(init_code)))[12:]` when
   * performing the computation. The computed address is then checked for any
   * existing contract code - if so, the null address will be returned instead.
   * @param salt bytes32 The nonce passed into the CREATE2 address calculation.
   * @param initCodeHash bytes32 The keccak256 hash of the initialization code
   * that will be passed into the CREATE2 address calculation.
   * @return deploymentAddress address the contract that will be created, or the null address
   * if a contract has already been deployed to that address.
   */
    function findCreate2AddressViaHash(
        bytes32 salt,
        bytes32 initCodeHash
    ) external view returns (address deploymentAddress) {
        // determine the address where the contract will be deployed.
        deploymentAddress = address(
            uint160(                      // downcast to match the address type.
                uint256(                    // convert to uint to truncate upper digits.
                    keccak256(                // compute the CREATE2 hash using 4 inputs.
                        abi.encodePacked(       // pack all inputs to the hash together.
                            hex"ff",              // start with 0xff to distinguish from RLP.
                            address(this),        // this contract will be the caller.
                            salt,                 // pass in the supplied salt value.
                            initCodeHash          // pass in the hash of initialization code.
                        )
                    )
                )
            )
        );

        // return null address to signify failure if contract has been deployed.
        if (_deployed[deploymentAddress]) {
            return address(0);
        }
    }

    /**
     * @dev Determine if a contract has already been deployed by the factory to a
   * given address.
   * @param deploymentAddress address The contract address to check.
   * @return True if the contract has been deployed, false otherwise.
   */
    function hasBeenDeployed(
        address deploymentAddress
    ) external view returns (bool) {
        // determine if a contract has been deployed to the provided address.
        return _deployed[deploymentAddress];
    }
}