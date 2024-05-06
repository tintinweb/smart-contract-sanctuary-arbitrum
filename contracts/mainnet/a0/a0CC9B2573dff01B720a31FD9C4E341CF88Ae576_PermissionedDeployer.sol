// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

/**
 * @notice Contains all errors used throughout the Definitive contracts
 * @dev This file should only be used as an internal library.
 * @dev When adding a new error, add alphabetically
 */

error AccountMissingRole(address _account, bytes32 _role);
error AccountNotAdmin(address);
error AccountNotWhitelisted(address);
error AddLiquidityFailed();
error AlreadyDeployed();
error AlreadyInitialized();
error BytecodeEmpty();
error DeadlineExceeded();
error DeployInitFailed();
error DeployFailed();
error BorrowFailed(uint256 errorCode);
error DecollateralizeFailed(uint256 errorCode);
error DepositMoreThanMax();
error EmptyBytecode();
error EnterAllFailed();
error EnforcedSafeLTV(uint256 invalidLTV);
error ExceededMaxDelta();
error ExceededMaxLTV();
error ExceededShareToAssetRatioDeltaThreshold();
error ExitAllFailed();
error ExitOneCoinFailed();
error GlobalStopGuardianEnabled();
error InitializeMarketsFailed();
error InputGreaterThanStaked();
error InsufficientBalance();
error InsufficientSwapTokenBalance();
error InvalidAddress();
error InvalidAmount();
error InvalidAmounts();
error InvalidCalldata();
error InvalidDestinationSwapper();
error InvalidERC20Address();
error InvalidExecutedOutputAmount();
error InvalidFeePercent();
error InvalidHandler();
error InvalidInputs();
error InvalidMsgValue();
error InvalidSingleHopSwap();
error InvalidMultiHopSwap();
error InvalidOutputToken();
error InvalidRedemptionRecipient(); // Used in cross-chain redeptions
error InvalidReportedOutputAmount();
error InvalidRewardsClaim();
error InvalidSignature();
error InvalidSignatureLength();
error InvalidSwapHandler();
error InvalidSwapInputAmount();
error InvalidSwapOutputToken();
error InvalidSwapPath();
error InvalidSwapPayload();
error InvalidSwapToken();
error MintMoreThanMax();
error MismatchedChainId();
error NativeAssetWrapFailed(bool wrappingToNative);
error NoSignatureVerificationSignerSet();
error RedeemMoreThanMax();
error RemoveLiquidityFailed();
error RepayDebtFailed();
error SafeHarborModeEnabled();
error SafeHarborRedemptionDisabled();
error SlippageExceeded(uint256 _outputAmount, uint256 _outputAmountMin);
error StakeFailed();
error SupplyFailed();
error StopGuardianEnabled();
error TradingDisabled();
error SwapDeadlineExceeded();
error SwapLimitExceeded();
error SwapTokenIsOutputToken();
error TransfersLimitExceeded();
error UnstakeFailed();
error UnauthenticatedFlashloan();
error UntrustedFlashLoanSender(address);
error WithdrawMoreThanMax();
error WithdrawalsDisabled();
error ZeroShares();

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { InvalidSignature, InvalidSignatureLength } from "./DefinitiveErrors.sol";

library SignatureVerifier {
    function verifySignature(
        mapping(address => bool) storage validSigners,
        bytes32 messageHash,
        bytes memory signature
    ) internal view {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        address signer = recoverSigner(ethSignedMessageHash, signature);

        if (!validSigners[signer]) {
            revert InvalidSignature();
        }
    }

    /* cSpell:disable */
    function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32) {
        /*
            Signature is produced by signing a keccak256 hash with the following format:
            "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    /* cSpell:enable */

    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature) private pure returns (address signer) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    // https://solidity-by-example.org/signature
    function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        if (sig.length != 65) {
            revert InvalidSignatureLength();
        }

        // solhint-disable-next-line no-inline-assembly
        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { SignatureLogic, DeploymentParams } from "../SignatureLogic.sol";
import { DeployFailed, EmptyBytecode, DeployInitFailed } from "../../../core/libraries/DefinitiveErrors.sol";
import { SafeNativeTransfer } from "../libs/SafeNativeTransfer.sol";

abstract contract Create2Deployer is SignatureLogic {
    using SafeNativeTransfer for address;

    event Deployed(bytes32 indexed bytecodeHash, bytes32 indexed salt, address indexed deployedAddress);

    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {deployedAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already by the same `msg.sender`.
     */
    function deployCreate2(
        DeploymentParams calldata deployParams,
        bytes memory authorizedDeploySignature
    ) external payable returns (address deployedAddress_) {
        _verifyDeploymentParams(deployParams, authorizedDeploySignature);

        if (msg.value > 0) {
            // slither-disable-next-line unused-return
            deployedAddress_.safeNativeTransfer(msg.value);
        }
        deployedAddress_ = _deployCreate2(deployParams.bytecode, deployParams.deploySalt);
    }

    /**
     * @dev Deploys a contract using `CREATE2` and initialize it. The address where the contract
     * will be deployed can be known in advance via {deployedAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already by the same `msg.sender`.
     * - `init` is used to initialize the deployed contract
     *    as an option to not have the constructor args affect the address derived by `CREATE2`.
     */
    function deployCreate2AndInit(
        DeploymentParams calldata deployParams,
        bytes memory authorizedDeploySignature,
        bytes calldata init
    ) external returns (address deployedAddress_) {
        _verifyDeploymentParams(deployParams, authorizedDeploySignature);

        deployedAddress_ = _deployCreate2(deployParams.bytecode, deployParams.deploySalt);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = deployedAddress_.call(init);
        if (!success) revert DeployInitFailed();
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} or {deployAndInit} by `sender`.
     * Any change in the `bytecode`, `sender`, or `salt` will result in a new destination address.
     */
    function deployedCreate2Address(
        bytes calldata bytecode,
        bytes32 salt
    ) external view returns (address deployedAddress_) {
        deployedAddress_ = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            address(this),
                            salt,
                            keccak256(bytecode) // init code hash
                        )
                    )
                )
            )
        );
    }

    function _deployCreate2(bytes memory bytecode, bytes32 salt) internal returns (address deployedAddress_) {
        if (bytecode.length == 0) revert EmptyBytecode();

        // solhint-disable-next-line no-inline-assembly
        assembly {
            deployedAddress_ := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        if (deployedAddress_ == address(0)) revert DeployFailed();

        emit Deployed(keccak256(bytecode), salt, deployedAddress_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { ContractAddress } from "../libs/ContractAddress.sol";
import { CreateDeploy } from "./CreateDeploy.sol";
import { Create3Address } from "./Create3Address.sol";

import { EmptyBytecode, AlreadyDeployed, DeployFailed } from "../../../core/libraries/DefinitiveErrors.sol";

/**
 * @title Create3 contract
 * @notice This contract can be used to deploy a contract with a deterministic address that depends only on
 * the deployer address and deployment salt, not the contract bytecode and constructor parameters.
 */
abstract contract Create3 is Create3Address {
    using ContractAddress for address;

    /**
     * @notice Deploys a new contract using the `CREATE3` method.
     * @dev This function first deploys the CreateDeploy contract using
     * the `CREATE2` opcode and then utilizes the CreateDeploy to deploy the
     * new contract with the `CREATE` opcode.
     * @param bytecode The bytecode of the contract to be deployed
     * @param deploySalt A salt to influence the contract address
     * @return deployed The address of the deployed contract
     */
    function _create3(bytes memory bytecode, bytes32 deploySalt) internal returns (address deployed) {
        deployed = _create3Address(deploySalt);

        if (bytecode.length == 0) revert EmptyBytecode();
        if (deployed.isContract()) revert AlreadyDeployed();

        // Deploy using create2
        CreateDeploy create = new CreateDeploy{ salt: deploySalt }();

        if (address(create) == address(0)) revert DeployFailed();

        // Deploy using create
        create.deploy(bytecode);
    }
}

// SPDX-License-Identifier: MIT

import { CreateDeploy } from "./CreateDeploy.sol";

pragma solidity ^0.8.4;

/**
 * @title Create3Address contract
 * @notice This contract can be used to predict the deterministic
 * deployment address of a contract deployed with the `CREATE3` technique.
 */
abstract contract Create3Address {
    /// @dev bytecode hash of the CreateDeploy helper contract
    /* immutable-vars-naming */
    bytes32 internal immutable createDeployBytecodeHash;

    constructor() {
        createDeployBytecodeHash = keccak256(type(CreateDeploy).creationCode);
    }

    /**
     * @notice Compute the deployed address that will result from the `CREATE3` method.
     * @param deploySalt A salt to influence the contract address
     * @return deployed The deterministic contract address if it was deployed
     */
    function _create3Address(bytes32 deploySalt) internal view returns (address deployed) {
        address deployer = address(
            uint160(uint256(keccak256(abi.encodePacked(hex"ff", address(this), deploySalt, createDeployBytecodeHash))))
        );

        deployed = address(uint160(uint256(keccak256(abi.encodePacked(hex"d6_94", deployer, hex"01")))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title CreateDeploy Contract
 * @notice This contract deploys new contracts using the `CREATE` opcode and is used as part of
 * the `CREATE3` deployment method.
 */
contract CreateDeploy {
    /**
     * @dev Deploys a new contract with the specified bytecode using the `CREATE` opcode.
     * @param bytecode The bytecode of the contract to be deployed
     */
    // slither-disable-next-line locked-ether
    function deploy(bytes memory bytecode) external payable {
        assembly {
            if iszero(create(0, add(bytecode, 32), mload(bytecode))) {
                revert(0, 0)
            }
        }

        /// @dev If we want to redeploy to the same contract we must self destruct this intermediate contract
        // slither-disable-next-line suicidal
        selfdestruct(payable(address(0)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { SafeNativeTransfer } from "../libs/SafeNativeTransfer.sol";
import { DeploymentParams, SignatureLogic } from "../SignatureLogic.sol";
import { DeployInitFailed } from "../../../core/libraries/DefinitiveErrors.sol";

/**
 * @title Deployer Contract
 * @notice This contract is responsible for deploying and initializing new contracts using
 * a deployment method, such as `CREATE2` or `CREATE3`.
 */
abstract contract Deployer is SignatureLogic {
    using SafeNativeTransfer for address;

    /**
     * @notice Deploys a contract using a deployment method defined by derived contracts.
     * @dev The address where the contract will be deployed can be known in
     * advance via {deployedAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already by the same `msg.sender`.
     *
     * @param deployParams Deployment parameters
     * @param authorizedDeploySignature valid signature authorizing the deploy
     */
    // slither-disable-next-line locked-ether
    function deploy(
        DeploymentParams calldata deployParams,
        bytes memory authorizedDeploySignature
    ) public payable returns (address deployedAddress_) {
        _verifyDeploymentParams(deployParams, authorizedDeploySignature);

        deployedAddress_ = _deployedAddress(deployParams.bytecode, deployParams.deploySalt);

        if (msg.value > 0) {
            // slither-disable-next-line unused-return
            deployedAddress_.safeNativeTransfer(msg.value);
        }

        deployedAddress_ = _deploy(deployParams.bytecode, deployParams.deploySalt);
    }

    /**
     * @notice Deploys a contract using a deployment method defined by derived contracts and initializes it.
     * @dev The address where the contract will be deployed can be known in advance
     * via {deployedAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already by the same `msg.sender`.
     * - `init` is used to initialize the deployed contract as an option to not have the
     *    constructor args affect the address derived by `CREATE2`.
     *
     * @param deployParams Deployment parameters
     * @param authorizedDeploySignature valid signature authorizing the deploy
     * @param init Init data used to initialize the deployed contract
     * @return deployedAddress_ The address of the deployed contract
     */
    // slither-disable-next-line locked-ether
    function deployAndInit(
        DeploymentParams calldata deployParams,
        bytes memory authorizedDeploySignature,
        bytes calldata init
    ) external payable returns (address deployedAddress_) {
        _verifyDeploymentParams(deployParams, authorizedDeploySignature);

        deployedAddress_ = _deployedAddress(deployParams.bytecode, deployParams.deploySalt);

        if (msg.value > 0) {
            // slither-disable-next-line unused-return
            deployedAddress_.safeNativeTransfer(msg.value);
        }

        deployedAddress_ = _deploy(deployParams.bytecode, deployParams.deploySalt);

        (bool success, ) = deployedAddress_.call(init);
        if (!success) revert DeployInitFailed();
    }

    /**
     *
     * @notice Returns the address where a contract will be stored
     * if deployed via {deploy} or {deployAndInit} by `sender`.
     * @dev Any change in the `bytecode` (except for `CREATE3`), `sender`,
     * or `salt` will result in a new deployed address.
     * @param bytecode The bytecode of the contract to be deployed
     * @param salt The salt that will be used to influence the contract address
     * @return deployedAddress_ The address that the contract will be deployed to
     */
    function deployedAddress(bytes memory bytecode, bytes32 salt) public view returns (address) {
        return _deployedAddress(bytecode, salt);
    }

    function _deploy(bytes memory bytecode, bytes32 deploySalt) internal virtual returns (address);

    function _deployedAddress(bytes memory bytecode, bytes32 deploySalt) internal view virtual returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { Deployer } from "./Deployer.sol";
import { Create3 } from "./Create3.sol";
import { Create2Deployer } from "./Create2Deployer.sol";

/**
 * @title PermissionedDeployer Contract
 * @notice This contract is responsible for deploying and initializing new contracts using the `CREATE3` method
 * which computes the deployed contract address based on the deployer address and deployment salt.
 */
contract PermissionedDeployer is Create3, Create2Deployer, Deployer {
    function _deploy(bytes memory bytecode, bytes32 deploySalt) internal override returns (address deployedAddress_) {
        deployedAddress_ = _create3(bytecode, deploySalt);

        emit Deployed(keccak256(bytecode), deploySalt, deployedAddress_);
    }

    function _deployedAddress(
        bytes memory /* bytecode */,
        bytes32 deploySalt
    ) internal view override returns (address) {
        return _create3Address(deploySalt);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library ContractAddress {
    function isContract(address contractAddress) internal view returns (bool) {
        bytes32 existingCodeHash = contractAddress.codehash;

        // https://eips.ethereum.org/EIPS/eip-1052
        // keccak256('') == 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
        return
            existingCodeHash != bytes32(0) &&
            existingCodeHash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

error NativeTransferFailed();

/*
 * @title SafeNativeTransfer
 * @dev This library is used for performing safe native value transfers in Solidity by utilizing inline assembly.
 */
library SafeNativeTransfer {
    /*
     * @notice Perform a native transfer to a given address.
     * @param receiver The recipient address to which the amount will be sent.
     * @param amount The amount of native value to send.
     * @throws NativeTransferFailed error if transfer is not successful.
     */
    function safeNativeTransfer(address receiver, uint256 amount) internal {
        bool success;

        /* solhint-disable no-inline-assembly */
        assembly {
            success := call(gas(), receiver, amount, 0, 0, 0, 0)
        }

        if (!success) revert NativeTransferFailed();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { SignatureVerifier } from "../../core/libraries/SignatureVerifier.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {
    AlreadyInitialized,
    DeadlineExceeded,
    BytecodeEmpty,
    MismatchedChainId,
    InvalidAddress
} from "../../core/libraries/DefinitiveErrors.sol";

struct DeploymentParams {
    uint256 chainId;
    uint256 deadline;
    bytes bytecode;
    bytes32 deploySalt;
}

contract SignatureLogic is Ownable {
    event SignatureVerifierAdded(address signatureVerifier);
    event SignatureVerifierRemoved(address signatureVerifier);

    bool isInitialized;

    mapping(address => bool) public isSignatureVerifier;

    constructor() Ownable(msg.sender) {}

    function initialize(address _owner, address[] calldata _initialVerifiers) external onlyOwner {
        if (isInitialized) {
            revert AlreadyInitialized();
        }
        isInitialized = true;

        transferOwnership(_owner);

        uint256 length = _initialVerifiers.length;
        for (uint256 i = 0; i < length; ) {
            _addSignatureVerifier(_initialVerifiers[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addSignatureVerifier(address _signatureVerifier) public onlyOwner {
        _addSignatureVerifier(_signatureVerifier);
    }

    function removeSignatureVerifier(address _signatureVerifier) public onlyOwner {
        _removeSignatureVerifier(_signatureVerifier);
    }

    function encodeDepositParams(DeploymentParams calldata deploymentParameters) public pure returns (bytes32) {
        return keccak256(abi.encode(deploymentParameters));
    }

    function _verifyDeploymentParams(
        DeploymentParams calldata deployParams,
        bytes memory authorizedDeploySignature
    ) internal view {
        SignatureVerifier.verifySignature(
            isSignatureVerifier,
            keccak256(abi.encode(deployParams)),
            authorizedDeploySignature
        );

        if (deployParams.bytecode.length == 0) {
            revert BytecodeEmpty();
        }

        if (deployParams.deadline < block.timestamp) {
            revert DeadlineExceeded();
        }

        if (deployParams.chainId != block.chainid) {
            revert MismatchedChainId();
        }
    }

    function _addSignatureVerifier(address _signatureVerifier) private {
        if (_signatureVerifier == address(0)) {
            revert InvalidAddress();
        }
        isSignatureVerifier[_signatureVerifier] = true;
        emit SignatureVerifierAdded(_signatureVerifier);
    }

    function _removeSignatureVerifier(address _signatureVerifier) private {
        if (_signatureVerifier == address(0)) {
            revert InvalidAddress();
        }
        isSignatureVerifier[_signatureVerifier] = false;
        emit SignatureVerifierRemoved(_signatureVerifier);
    }
}