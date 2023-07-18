// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ContractAddress } from '../utils/ContractAddress.sol';

error AlreadyDeployed();
error EmptyBytecode();
error DeployFailed();

/**
 * @title CreateDeployer Contract
 * @notice This contract deploys new contracts using the `CREATE` opcode and is used as part of
 * the `Create3` deployment method.
 */
contract CreateDeployer {
    /**
     * @dev Deploys a new contract with the specified bytecode using the CREATE opcode.
     * @param bytecode The bytecode of the contract to be deployed
     */
    function deploy(bytes memory bytecode) external {
        address deployed;

        assembly {
            deployed := create(0, add(bytecode, 32), mload(bytecode))
            if iszero(deployed) {
                revert(0, 0)
            }
        }
    }
}

/**
 * @title Create3 Library
 * @notice This library can be used to deploy a contract with a deterministic address that only
 * depends on the sender and salt, not the contract bytecode.
 */
library Create3 {
    using ContractAddress for address;

    bytes32 internal constant DEPLOYER_BYTECODE_HASH = keccak256(type(CreateDeployer).creationCode);

    /**
     * @dev Deploys a new contract using the CREATE3 method. This function first deploys the
     * CreateDeployer contract using the CREATE2 opcode and then utilizes the CreateDeployer
     * to deploy the new contract with the CREATE opcode.
     * @param salt A salt to further randomize the contract address
     * @param bytecode The bytecode of the contract to be deployed
     * @return deployed The address of the deployed contract
     */
    function deploy(bytes32 salt, bytes memory bytecode) internal returns (address deployed) {
        deployed = deployedAddress(address(this), salt);

        if (deployed.isContract()) revert AlreadyDeployed();
        if (bytecode.length == 0) revert EmptyBytecode();

        // Deploy using create2
        CreateDeployer deployer = new CreateDeployer{ salt: salt }();

        if (address(deployer) == address(0)) revert DeployFailed();

        deployer.deploy(bytecode);
    }

    /**
     * @dev Compute the deployed address that will result from the CREATE3 method.
     * @param salt A salt to further randomize the contract address
     * @param sender The sender address which would deploy the contract
     * @return deployed The deterministic contract address if it was deployed
     */
    function deployedAddress(address sender, bytes32 salt) internal pure returns (address deployed) {
        address deployer = address(
            uint160(uint256(keccak256(abi.encodePacked(hex'ff', sender, salt, DEPLOYER_BYTECODE_HASH))))
        );

        deployed = address(uint160(uint256(keccak256(abi.encodePacked(hex'd6_94', deployer, hex'01')))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Create3 } from './Create3.sol';

/**
 * @title Create3Deployer Contract
 * @notice This contract is responsible for deploying and initializing new contracts using the CREATE3 technique
 * which ensures that only the sender address and salt influence the deployed address, not the contract bytecode.
 */
contract Create3Deployer {
    error FailedInit();

    event Deployed(bytes32 indexed bytecodeHash, bytes32 indexed salt, address indexed deployedAddress);

    /**
     * @dev Deploys a contract using `CREATE3`. The address where the contract
     * will be deployed can be known in advance via {deployedAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must not have been used already by the same `msg.sender`.
     */
    function deploy(bytes calldata bytecode, bytes32 salt) external returns (address deployedAddress_) {
        bytes32 deploySalt = keccak256(abi.encode(msg.sender, salt));
        deployedAddress_ = Create3.deploy(deploySalt, bytecode);

        emit Deployed(keccak256(bytecode), salt, deployedAddress_);
    }

    /**
     * @dev Deploys a contract using `CREATE3` and initialize it. The address where the contract
     * will be deployed can be known in advance via {deployedAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must not have been used already by the same `msg.sender`.
     * - `init` is used to initialize the deployed contract
     */
    function deployAndInit(
        bytes memory bytecode,
        bytes32 salt,
        bytes calldata init
    ) external returns (address deployedAddress_) {
        bytes32 deploySalt = keccak256(abi.encode(msg.sender, salt));
        deployedAddress_ = Create3.deploy(deploySalt, bytecode);

        (bool success, ) = deployedAddress_.call(init);
        if (!success) revert FailedInit();

        emit Deployed(keccak256(bytecode), salt, deployedAddress_);
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} or {deployAndInit} by `sender`.
     * Any change in `sender` or `salt` will result in a new destination address.
     */
    function deployedAddress(address sender, bytes32 salt) external view returns (address) {
        bytes32 deploySalt = keccak256(abi.encode(sender, salt));
        return Create3.deployedAddress(address(this), deploySalt);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ContractAddress {
    function isContract(address _address) internal view returns (bool) {
        bytes32 existingCodeHash = _address.codehash;

        // https://eips.ethereum.org/EIPS/eip-1052
        // keccak256('') == 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
        return
            existingCodeHash != bytes32(0) &&
            existingCodeHash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    }
}