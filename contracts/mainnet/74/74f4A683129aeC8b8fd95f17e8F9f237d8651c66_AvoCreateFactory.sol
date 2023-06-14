// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { CREATE3 } from "solmate/src/utils/CREATE3.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

/// @title  AvoCreateFactory
/// @notice Factory for deploying contracts via CREATE, CREATE2 and CREATE3.
contract AvoCreateFactory {
    /// @notice Deploys a contract using CREATE3. The address where the contract
    /// will be deployed can be known in advance via {computeAddressCREATE3}.
    /// Resulting deterministic address is independent of constructor args.
    /// @param salt The deployer-specific salt for determining the deployed contract's address
    /// @param bytecode The creation code of the contract to deploy
    /// @return deployed The address of the deployed contract
    function deployCREATE3(bytes32 salt, bytes memory bytecode) external payable returns (address deployed) {
        return CREATE3.deploy(salt, bytecode, msg.value);
    }

    /// @notice Predicts the address of a deployed contract via {deployCREATE3}
    /// @param salt The deployer-specific salt for determining the deployed contract's address
    /// @return deployed The address of the contract that will be deployed
    function computeAddressCREATE3(bytes32 salt) external view returns (address deployed) {
        return CREATE3.getDeployed(salt);
    }

    /// @notice Deploys a contract using `CREATE2`. The address where the contract
    /// will be deployed can be known in advance via {computeAddressCREATE2}.
    /// The bytecode for a contract can be obtained from Solidity with
    /// `type(contractName).creationCode`.
    /// Requirements:
    /// - `bytecode` must not be empty.
    /// - `salt` must have not been used for `bytecode` already.
    /// - if `msg.value` is non-zero, `bytecode` must have a `payable` constructor.
    function deployCREATE2(bytes32 salt, bytes memory bytecode) external payable returns (address deployed) {
        return Create2.deploy(msg.value, salt, bytecode);
    }

    /// @notice Returns the address where a contract will be stored if deployed via {deployCREATE2}. Any change in the
    /// `bytecode` or `salt` will result in a new destination address.
    function computeAddressCREATE2(bytes32 salt, bytes memory bytecode) external view returns (address deployed) {
        return Create2.computeAddress(salt, keccak256(abi.encodePacked(bytecode)));
    }

    /// @notice Deploys a contract using `CREATE`. The address where the contract
    /// will be deployed can be known in advance via {computeAddressCREATE}.
    function deployCREATE(bytes memory bytecode) external payable returns (address deployed) {
        uint256 amount_ = msg.value;
        assembly {
            deployed := create(amount_, add(bytecode, 0x20), mload(bytecode))
        }
        require(deployed != address(0), "Create: Failed on deploy");
    }

    /// @notice Returns the address where a contract will be stored if deployed via {deployCREATE}
    function computeAddressCREATE(uint256 nonce_) external view returns (address deployed) {
        // @dev based on https://ethereum.stackexchange.com/a/61413
        bytes memory data;
        if (nonce_ == 0x00) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), address(this), bytes1(0x80));
        } else if (nonce_ <= 0x7f) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), address(this), uint8(nonce_));
        } else if (nonce_ <= 0xff) {
            data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), address(this), bytes1(0x81), uint8(nonce_));
        } else if (nonce_ <= 0xffff) {
            data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), address(this), bytes1(0x82), uint16(nonce_));
        } else if (nonce_ <= 0xffffff) {
            data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), address(this), bytes1(0x83), uint24(nonce_));
        } else {
            data = abi.encodePacked(bytes1(0xda), bytes1(0x94), address(this), bytes1(0x84), uint32(nonce_));
        }

        return address(uint160(uint256(keccak256(data))));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Bytes32AddressLib} from "./Bytes32AddressLib.sol";

/// @notice Deploy to deterministic addresses without an initcode factor.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/CREATE3.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/create3/blob/master/contracts/Create3.sol)
library CREATE3 {
    using Bytes32AddressLib for bytes32;

    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 0 size               //
    // 0x37       |  0x37                 | CALLDATACOPY     |                        //
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x34       |  0x34                 | CALLVALUE        | value 0 size           //
    // 0xf0       |  0xf0                 | CREATE           | newContract            //
    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x67       |  0x67XXXXXXXXXXXXXXXX | PUSH8 bytecode   | bytecode               //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 bytecode             //
    // 0x52       |  0x52                 | MSTORE           |                        //
    // 0x60       |  0x6008               | PUSH1 08         | 8                      //
    // 0x60       |  0x6018               | PUSH1 18         | 24 8                   //
    // 0xf3       |  0xf3                 | RETURN           |                        //
    //--------------------------------------------------------------------------------//
    bytes internal constant PROXY_BYTECODE = hex"67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3";

    bytes32 internal constant PROXY_BYTECODE_HASH = keccak256(PROXY_BYTECODE);

    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        uint256 value
    ) internal returns (address deployed) {
        bytes memory proxyChildBytecode = PROXY_BYTECODE;

        address proxy;
        /// @solidity memory-safe-assembly
        assembly {
            // Deploy a new contract with our pre-made bytecode via CREATE2.
            // We start 32 bytes into the code to avoid copying the byte length.
            proxy := create2(0, add(proxyChildBytecode, 32), mload(proxyChildBytecode), salt)
        }
        require(proxy != address(0), "DEPLOYMENT_FAILED");

        deployed = getDeployed(salt);
        (bool success, ) = proxy.call{value: value}(creationCode);
        require(success && deployed.code.length != 0, "INITIALIZATION_FAILED");
    }

    function getDeployed(bytes32 salt) internal view returns (address) {
        address proxy = keccak256(
            abi.encodePacked(
                // Prefix:
                bytes1(0xFF),
                // Creator:
                address(this),
                // Salt:
                salt,
                // Bytecode hash:
                PROXY_BYTECODE_HASH
            )
        ).fromLast20Bytes();

        return
            keccak256(
                abi.encodePacked(
                    // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01)
                    // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
                    hex"d6_94",
                    proxy,
                    hex"01" // Nonce of the proxy contract (1)
                )
            ).fromLast20Bytes();
    }
}