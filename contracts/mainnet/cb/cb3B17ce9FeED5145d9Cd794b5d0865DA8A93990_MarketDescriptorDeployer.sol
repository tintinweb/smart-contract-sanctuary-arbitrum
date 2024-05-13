// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Create2.sol)

pragma solidity ^0.8.20;

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
     * @dev Not enough balance for performing a CREATE2 deploy.
     */
    error Create2InsufficientBalance(uint256 balance, uint256 needed);

    /**
     * @dev There's no code to deploy.
     */
    error Create2EmptyBytecode();

    /**
     * @dev The deployment failed.
     */
    error Create2FailedDeployment();

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
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address addr) {
        if (address(this).balance < amount) {
            revert Create2InsufficientBalance(address(this).balance, amount);
        }
        if (bytecode.length == 0) {
            revert Create2EmptyBytecode();
        }
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        if (addr == address(0)) {
            revert Create2FailedDeployment();
        }
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
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address addr) {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IMarketDescriptor {
    /// @notice Error thrown when the symbol is already initialized
    error SymbolAlreadyInitialized();

    /// @notice Get the name of the market
    function name() external view returns (string memory);

    /// @notice Get the symbol of the market
    function symbol() external view returns (string memory);

    /// @notice Get the size decimals of the market
    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.23;

import "./interfaces/IMarketDescriptor.sol";

/// @title Market Descriptor
/// @notice This contract is used to describe a market
contract MarketDescriptor is IMarketDescriptor {
    /// @inheritdoc IMarketDescriptor
    string public override symbol;

    function initialize(string memory _symbol) external {
        if (bytes(symbol).length != 0) revert SymbolAlreadyInitialized();

        symbol = _symbol;
    }

    /// @inheritdoc IMarketDescriptor
    function name() external view override returns (string memory) {
        return string.concat("Equation Market V2 - ", symbol);
    }

    /// @inheritdoc IMarketDescriptor
    function decimals() external pure override returns (uint8) {
        return 18;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.23;

import "./MarketDescriptor.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

/// @title Market Descriptor Deployer
/// @notice This contract is used to deploy market descriptors with deterministic addresses.
/// It can also save gas when deploying descriptors.
contract MarketDescriptorDeployer {
    /// @notice Mapping of market symbol to their descriptors
    mapping(string symbol => MarketDescriptor) public descriptors;

    /// @notice Emiited when a market descriptor is deployed
    /// @param symbol The symbol of the market
    /// @param descriptor The address of the deployed market descriptor
    event MarketDescriptorDeployed(string indexed symbol, MarketDescriptor indexed descriptor);

    /// @notice Error thrown when the symbol is empty
    error SymbolMustNotBeEmpty();
    /// @notice Error thrown when the market descriptor is already deployed
    error MarketDescriptorAlreadyDeployed(string symbol);

    /// @notice Deploy a market descriptor
    /// @dev The address of the deployed market descriptor is deterministic based on the symbol.
    /// This function will revert if the descriptor is already deployed.
    /// @param _symbol The symbol of the market
    function deploy(string calldata _symbol) external {
        if (bytes(_symbol).length == 0) revert SymbolMustNotBeEmpty();

        if (address(descriptors[_symbol]) != address(0)) revert MarketDescriptorAlreadyDeployed(_symbol);

        address addr = Create2.deploy(0, keccak256(abi.encodePacked(_symbol)), type(MarketDescriptor).creationCode);
        MarketDescriptor descriptor = MarketDescriptor(addr);
        descriptor.initialize(_symbol);

        descriptors[_symbol] = descriptor;

        emit MarketDescriptorDeployed(_symbol, descriptor);
    }
}