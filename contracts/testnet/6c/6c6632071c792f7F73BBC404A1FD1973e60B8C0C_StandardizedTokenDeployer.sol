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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    error InvalidAccount();

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// General interface for upgradable contracts
interface IProxy {
    error InvalidOwner();
    error InvalidImplementation();
    error SetupFailed();
    error NotOwner();
    error AlreadyInitialized();

    function implementation() external view returns (address);

    function setup(bytes calldata setupParams) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IProxy } from '../interfaces/IProxy.sol';

/**
 * @title FixedProxy Contract
 * @notice The FixedProxy is a type of Proxy contract with a fixed implementation that cannot be updated.
 * It implements the IProxy interface. Any function calls to this contract will be forwarded to the implementation contract.
 */
contract FixedProxy is IProxy {
    /**
     * @dev The immutable address of the implementation contract.
     * This address is set in the constructor and cannot be updated after.
     */
    address public immutable implementation;

    /**
     * @dev Constructs a FixedProxy contract with the given implementation address.
     * @param implementationAddress The address of the implementation contract
     */
    constructor(address implementationAddress) {
        implementation = implementationAddress;
    }

    /**
     * @dev Shadows the setup function of the implementation contract so it can't be called directly via the proxy.
     * @param setupParams The setup parameters for the implementation contract.
     */
    function setup(bytes calldata setupParams) external {}

    /**
     * @dev Fallback function that delegates all calls to the implementation contract.
     * If the call fails, it reverts with the returned error data. If it succeeds, it returns the data from the call.
     */
    fallback() external payable virtual {
        address implementation_ = implementation;

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation_, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev Payable fallback function. Can be overridden in derived contracts.
     */
    receive() external payable virtual {}
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDistributable {
    error NotDistributor();

    event DistributorChanged(address distributor);

    /**
     * @notice Get the address of the distributor
     * @return distributor of the distributor
     */
    function distributor() external view returns (address distributor);

    /**
     * @notice Change the distributor of the contract
     * @dev Can only be called by the current distributor
     * @param distributor The address of the new distributor
     */
    function setDistributor(address distributor) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20BurnableMintable is IERC20 {
    /**
     * @notice Function to mint new tokens
     * Can only be called by the distributor address.
     * @param to The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Function to burn tokens
     * Can only be called by the distributor address.
     * @param from The address that will have its tokens burnt
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IInterchainToken is IERC20 {
    /**
     * @notice Implementation of the interchainTransfer method
     * @dev We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
     * A different implementation could have `metadata` that tells this function which function to use or that it is used for anything else as well.
     * @param destinationChain The destination chain identifier.
     * @param recipient The bytes representation of the address of the recipient.
     * @param amount The amount of token to be transfered.
     * @param metadata Either empty, to just facilitate an interchain transfer, or the data can be passed for an interchain contract call with transfer as per semantics defined by the token service.
     */
    function interchainTransfer(
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable;

    /**
     * @notice Implementation of the interchainTransferFrom method
     * @dev We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
     * A different implementation could have `metadata` that tells this function which function to use or that it is used for anything else as well.
     * @param sender the sender of the tokens. They need to have approved `msg.sender` before this is called.
     * @param destinationChain the string representation of the destination chain.
     * @param recipient the bytes representation of the address of the recipient.
     * @param amount the amount of token to be transfered.
     * @param metadata either empty, to just facilitate a cross-chain transfer, or the data to be passed to a cross-chain contract call and transfer.
     */
    function interchainTransferFrom(
        address sender,
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainToken } from './IInterchainToken.sol';
import { IDistributable } from './IDistributable.sol';
import { IERC20BurnableMintable } from './IERC20BurnableMintable.sol';

/**
 * @title StandardizedToken
 * @notice This contract implements a standardized token which extends InterchainToken functionality.
 * This contract also inherits Distributable and Implementation logic.
 */
interface IStandardizedToken is IInterchainToken, IDistributable, IERC20BurnableMintable {
    /**
     * @notice Returns the contract id, which a proxy can check to ensure no false implementation was used.
     */
    function contractId() external view returns (bytes32);

    /**
     * @notice Called by the proxy to setup itself.
     * @dev This should be hidden by the proxy.
     * @param params the data to be used for the initialization.
     */
    function setup(bytes calldata params) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

/**
 * @title IStandardizedTokenDeployer
 * @notice This contract is used to deploy new instances of the StandardizedTokenProxy contract.
 */
interface IStandardizedTokenDeployer {
    error AddressZero();
    error TokenDeploymentFailed();

    /**
     * @notice Getter for the Create3Deployer.
     */
    function deployer() external view returns (Create3Deployer);

    /**
     * @notice Deploys a new instance of the StandardizedTokenProxy contract
     * @param salt The salt used by Create3Deployer
     * @param tokenManager Address of the token manager
     * @param distributor Address of the distributor
     * @param name Name of the token
     * @param symbol Symbol of the token
     * @param decimals Decimals of the token
     * @param mintAmount Amount of tokens to mint initially
     * @param mintTo Address to mint initial tokens to
     */
    function deployStandardizedToken(
        bytes32 salt,
        address tokenManager,
        address distributor,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 mintAmount,
        address mintTo
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title StandardizedTokenProxy
 * @dev Proxy contract for StandardizedToken contracts. Inherits from FixedProxy and implements IStandardizedTokenProxy.
 */
interface IStandardizedTokenProxy {
    /**
     * @notice Returns the contract id, which a proxy can check to ensure no false implementation was used.
     */
    function contractId() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { FixedProxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/FixedProxy.sol';
import { IStandardizedToken } from '../interfaces/IStandardizedToken.sol';
import { IStandardizedTokenProxy } from '../interfaces/IStandardizedTokenProxy.sol';

/**
 * @title StandardizedTokenProxy
 * @dev Proxy contract for StandardizedToken contracts. Inherits from FixedProxy and implements IStandardizedTokenProxy.
 */
contract StandardizedTokenProxy is FixedProxy, IStandardizedTokenProxy {
    bytes32 private constant CONTRACT_ID = keccak256('standardized-token');

    /**
     * @dev Constructs the StandardizedTokenProxy contract.
     * @param implementationAddress Address of the StandardizedToken implementation
     * @param params Initialization parameters for the StandardizedToken contract
     */
    constructor(address implementationAddress, bytes memory params) FixedProxy(implementationAddress) {
        if (IStandardizedToken(implementationAddress).contractId() != CONTRACT_ID) revert InvalidImplementation();

        (bool success, ) = implementationAddress.delegatecall(abi.encodeWithSelector(IStandardizedToken.setup.selector, params));
        if (!success) revert SetupFailed();
    }

    /**
     * @notice Getter for the contract id.
     */
    function contractId() external pure returns (bytes32) {
        return CONTRACT_ID;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

import { IStandardizedTokenDeployer } from '../interfaces/IStandardizedTokenDeployer.sol';

import { StandardizedTokenProxy } from '../proxies/StandardizedTokenProxy.sol';

/**
 * @title StandardizedTokenDeployer
 * @notice This contract is used to deploy new instances of the StandardizedTokenProxy contract.
 */
contract StandardizedTokenDeployer is IStandardizedTokenDeployer {
    Create3Deployer public immutable deployer;
    address public immutable implementationMintBurnAddress;
    address public immutable implementationLockUnlockAddress;

    /**
     * @notice Constructor for the StandardizedTokenDeployer contract
     * @param deployer_ Address of the Create3Deployer contract
     * @param implementationLockUnlockAddress_ Address of the StandardizedTokenLockUnlock contract
     * @param implementationMintBurnAddress_ Address of the StandardizedTokenMintBurn contract
     */
    constructor(address deployer_, address implementationLockUnlockAddress_, address implementationMintBurnAddress_) {
        if (deployer_ == address(0) || implementationLockUnlockAddress_ == address(0) || implementationMintBurnAddress_ == address(0))
            revert AddressZero();
        deployer = Create3Deployer(deployer_);
        implementationLockUnlockAddress = implementationLockUnlockAddress_;
        implementationMintBurnAddress = implementationMintBurnAddress_;
    }

    /**
     * @notice Deploys a new instance of the StandardizedTokenProxy contract
     * @param salt The salt used by Create3Deployer
     * @param tokenManager Address of the token manager
     * @param distributor Address of the distributor
     * @param name Name of the token
     * @param symbol Symbol of the token
     * @param decimals Decimals of the token
     * @param mintAmount Amount of tokens to mint initially
     * @param mintTo Address to mint initial tokens to
     */
    function deployStandardizedToken(
        bytes32 salt,
        address tokenManager,
        address distributor,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 mintAmount,
        address mintTo
    ) external payable {
        bytes memory bytecode;
        address implementationAddress = distributor == tokenManager ? implementationMintBurnAddress : implementationLockUnlockAddress;
        {
            bytes memory params = abi.encode(tokenManager, distributor, name, symbol, decimals, mintAmount, mintTo);
            bytecode = abi.encodePacked(type(StandardizedTokenProxy).creationCode, abi.encode(implementationAddress, params));
        }
        address tokenAddress = deployer.deploy(bytecode, salt);
        if (tokenAddress.code.length == 0) revert TokenDeploymentFailed();
    }
}